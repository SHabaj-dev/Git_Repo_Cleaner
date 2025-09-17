#!/bin/bash

# GitHub Repository Manager
# This script allows you to list and delete repositories from your GitHub account

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GITHUB_API_BASE="https://api.github.com"
TEMP_DIR="/tmp/github_repo_manager"
REPO_LIST_FILE="$TEMP_DIR/repos.json"

# Create temp directory
mkdir -p "$TEMP_DIR"

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if required tools are installed
check_dependencies() {
    local missing_deps=()
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_color $RED "Error: Missing required dependencies: ${missing_deps[*]}"
        print_color $YELLOW "Please install them using:"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                "curl")
                    print_color $YELLOW "  brew install curl"
                    ;;
                "jq")
                    print_color $YELLOW "  brew install jq"
                    ;;
            esac
        done
        exit 1
    fi
}

# Function to get GitHub token
get_github_token() {
    if [ -z "$GITHUB_TOKEN" ]; then
        print_color $YELLOW "GitHub Personal Access Token not found in environment variables."
        print_color $BLUE "Please enter your GitHub Personal Access Token:"
        print_color $YELLOW "You can create one at: https://github.com/settings/tokens"
        print_color $YELLOW "Required scopes: repo (for private repos) or public_repo (for public repos only)"
        echo -n "Token: "
        read -s GITHUB_TOKEN
        echo
    fi
    
    if [ -z "$GITHUB_TOKEN" ]; then
        print_color $RED "Error: GitHub token is required"
        exit 1
    fi
}

# Function to get GitHub username
get_github_username() {
    if [ -z "$GITHUB_USERNAME" ]; then
        print_color $BLUE "Please enter your GitHub username:"
        read GITHUB_USERNAME
    fi
    
    if [ -z "$GITHUB_USERNAME" ]; then
        print_color $RED "Error: GitHub username is required"
        exit 1
    fi
}

# Function to test GitHub API connection
test_github_connection() {
    print_color $BLUE "Testing GitHub API connection..."
    
    local response=$(curl -s -w "%{http_code}" -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "$GITHUB_API_BASE/user")
    
    local http_code="${response: -3}"
    local body="${response%???}"
    
    if [ "$http_code" -eq 200 ]; then
        local username=$(echo "$body" | jq -r '.login')
        print_color $GREEN "✓ Connected to GitHub as: $username"
        GITHUB_USERNAME="$username"
    else
        print_color $RED "✗ Failed to connect to GitHub API (HTTP $http_code)"
        if [ "$http_code" -eq 401 ]; then
            print_color $RED "Invalid token. Please check your GitHub Personal Access Token."
        fi
        exit 1
    fi
}

# Function to fetch all repositories
fetch_repositories() {
    print_color $BLUE "Fetching your repositories..."
    
    local page=1
    local all_repos="[]"
    
    while true; do
        local response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github.v3+json" \
            "$GITHUB_API_BASE/user/repos?page=$page&per_page=100&sort=updated")
        
        local repos_count=$(echo "$response" | jq '. | length')
        
        if [ "$repos_count" -eq 0 ]; then
            break
        fi
        
        all_repos=$(echo "$all_repos $response" | jq -s '.[0] + .[1]')
        page=$((page + 1))
    done
    
    echo "$all_repos" > "$REPO_LIST_FILE"
    local total_repos=$(echo "$all_repos" | jq '. | length')
    print_color $GREEN "✓ Found $total_repos repositories"
}

# Function to display repositories
display_repositories() {
    if [ ! -f "$REPO_LIST_FILE" ]; then
        print_color $RED "Error: Repository list not found. Please fetch repositories first."
        return 1
    fi
    
    local repos=$(cat "$REPO_LIST_FILE")
    local count=$(echo "$repos" | jq '. | length')
    
    if [ "$count" -eq 0 ]; then
        print_color $YELLOW "No repositories found."
        return 0
    fi
    
    print_color $BLUE "\n=== Your GitHub Repositories ==="
    echo "$repos" | jq -r '.[] | "\(.id) | \(.name) | \(.private // false | if . then "Private" else "Public" end) | \(.updated_at | strptime("%Y-%m-%dT%H:%M:%SZ") | strftime("%Y-%m-%d %H:%M"))"'
    print_color $BLUE "================================\n"
}

# Function to select repositories for deletion
select_repositories() {
    if [ ! -f "$REPO_LIST_FILE" ]; then
        print_color $RED "Error: Repository list not found. Please fetch repositories first."
        return 1
    fi
    
    local repos=$(cat "$REPO_LIST_FILE")
    local count=$(echo "$repos" | jq '. | length')
    
    if [ "$count" -eq 0 ]; then
        print_color $YELLOW "No repositories found."
        return 0
    fi
    
    print_color $YELLOW "Select repositories to delete:"
    print_color $BLUE "Enter repository IDs separated by commas (e.g., 1,3,5)"
    print_color $BLUE "Or enter 'all' to select all repositories"
    print_color $BLUE "Or enter 'none' to cancel"
    echo -n "Selection: "
    read selection
    
    if [ "$selection" = "none" ]; then
        print_color $YELLOW "Operation cancelled."
        return 1
    fi
    
    if [ "$selection" = "all" ]; then
        SELECTED_REPOS=$(echo "$repos" | jq -r '.[].id')
    else
        SELECTED_REPOS=$(echo "$selection" | tr ',' '\n' | tr -d ' ')
    fi
    
    # Validate selected repository IDs
    local valid_repos=""
    for repo_id in $SELECTED_REPOS; do
        if echo "$repos" | jq -e ".[] | select(.id == $repo_id)" > /dev/null; then
            valid_repos="$valid_repos $repo_id"
        else
            print_color $RED "Warning: Repository ID $repo_id not found"
        fi
    done
    
    SELECTED_REPOS="$valid_repos"
    
    if [ -z "$SELECTED_REPOS" ]; then
        print_color $RED "No valid repositories selected."
        return 1
    fi
    
    return 0
}

# Function to confirm deletion
confirm_deletion() {
    local repos=$(cat "$REPO_LIST_FILE")
    
    print_color $RED "\n=== REPOSITORIES TO BE DELETED ==="
    for repo_id in $SELECTED_REPOS; do
        local repo_name=$(echo "$repos" | jq -r ".[] | select(.id == $repo_id) | .name")
        local repo_owner=$(echo "$repos" | jq -r ".[] | select(.id == $repo_id) | .owner.login")
        print_color $RED "  - $repo_owner/$repo_name"
    done
    print_color $RED "==================================="
    
    print_color $YELLOW "\n⚠️  WARNING: This action cannot be undone!"
    print_color $YELLOW "These repositories will be permanently deleted from GitHub."
    echo -n "Are you sure you want to proceed? (yes/no): "
    read confirmation
    
    if [ "$confirmation" = "yes" ]; then
        return 0
    else
        print_color $YELLOW "Deletion cancelled."
        return 1
    fi
}

# Function to delete repositories
delete_repositories() {
    local repos=$(cat "$REPO_LIST_FILE")
    local deleted_count=0
    local failed_count=0
    
    print_color $BLUE "\nStarting deletion process..."
    
    for repo_id in $SELECTED_REPOS; do
        local repo_name=$(echo "$repos" | jq -r ".[] | select(.id == $repo_id) | .name")
        local repo_owner=$(echo "$repos" | jq -r ".[] | select(.id == $repo_id) | .owner.login")
        
        print_color $BLUE "Deleting: $repo_owner/$repo_name..."
        
        local response=$(curl -s -w "%{http_code}" -X DELETE \
            -H "Authorization: token $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github.v3+json" \
            "$GITHUB_API_BASE/repos/$repo_owner/$repo_name")
        
        local http_code="${response: -3}"
        
        if [ "$http_code" -eq 204 ]; then
            print_color $GREEN "✓ Successfully deleted: $repo_owner/$repo_name"
            deleted_count=$((deleted_count + 1))
        else
            print_color $RED "✗ Failed to delete: $repo_owner/$repo_name (HTTP $http_code)"
            failed_count=$((failed_count + 1))
        fi
        
        # Add a small delay to avoid rate limiting
        sleep 1
    done
    
    print_color $GREEN "\n=== Deletion Summary ==="
    print_color $GREEN "Successfully deleted: $deleted_count repositories"
    if [ $failed_count -gt 0 ]; then
        print_color $RED "Failed to delete: $failed_count repositories"
    fi
}

# Function to show main menu
show_menu() {
    print_color $BLUE "\n=== GitHub Repository Manager ==="
    echo "1. List all repositories"
    echo "2. Delete repositories"
    echo "3. Exit"
    print_color $BLUE "================================"
    echo -n "Choose an option (1-3): "
}

# Main function
main() {
    print_color $GREEN "GitHub Repository Manager"
    print_color $YELLOW "This script will help you manage your GitHub repositories"
    
    # Check dependencies
    check_dependencies
    
    # Get GitHub credentials
    get_github_token
    get_github_username
    
    # Test connection
    test_github_connection
    
    # Main loop
    while true; do
        show_menu
        read choice
        
        case $choice in
            1)
                fetch_repositories
                display_repositories
                ;;
            2)
                fetch_repositories
                display_repositories
                if select_repositories; then
                    if confirm_deletion; then
                        delete_repositories
                    fi
                fi
                ;;
            3)
                print_color $GREEN "Goodbye!"
                break
                ;;
            *)
                print_color $RED "Invalid option. Please choose 1, 2, or 3."
                ;;
        esac
    done
    
    # Cleanup
    rm -rf "$TEMP_DIR"
}

# Run main function
main "$@"
