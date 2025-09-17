# GitHub Repository Manager

A shell script that allows you to list and delete repositories from your GitHub account with an interactive interface.

## Features

- 🔍 **List all repositories** - View all your GitHub repositories with details
- 🗑️ **Selective deletion** - Choose specific repositories to delete
- ⚠️ **Safety confirmations** - Multiple confirmation prompts to prevent accidental deletions
- 🎨 **Colored output** - Easy-to-read interface with color-coded messages
- 🔒 **Secure authentication** - Uses GitHub Personal Access Tokens
- 📊 **Deletion summary** - Shows success/failure statistics

## Prerequisites

Before using this script, you need to install the following dependencies:

### macOS (using Homebrew)
```bash
brew install curl jq
```

### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install curl jq
```

### CentOS/RHEL
```bash
sudo yum install curl jq
```

## Setup

### 1. Create a GitHub Personal Access Token

1. Go to [GitHub Settings > Personal Access Tokens](https://github.com/settings/tokens)
2. Click "Generate new token" → "Generate new token (classic)"
3. Give it a descriptive name (e.g., "Repository Manager")
4. Select the following scopes:
   - `repo` (for private repositories) OR `public_repo` (for public repositories only)
   - `delete_repo` (for repository deletion)
5. Click "Generate token"
6. **Important**: Copy the token immediately - you won't be able to see it again!

### 2. Set up your environment

You can provide your GitHub token in two ways:

#### Option A: Environment Variable (Recommended)
```bash
export GITHUB_TOKEN="your_personal_access_token_here"
```

#### Option B: Enter when prompted
The script will ask for your token if it's not found in the environment.

## Usage

### Basic Usage
```bash
./github_repo_manager.sh
```

### With environment variable
```bash
GITHUB_TOKEN="your_token_here" ./github_repo_manager.sh
```

## How it works

1. **Start the script** - The script will check dependencies and ask for your GitHub credentials
2. **Test connection** - It verifies your token and username
3. **Main menu** - Choose from the following options:
   - **Option 1**: List all repositories
   - **Option 2**: Delete repositories (includes listing and selection)
   - **Option 3**: Exit

### Repository Deletion Process

When you choose to delete repositories:

1. **List repositories** - Shows all your repositories with IDs, names, privacy status, and last updated date
2. **Select repositories** - Enter repository IDs separated by commas, or type:
   - `all` - to select all repositories
   - `none` - to cancel the operation
3. **Confirm deletion** - Review the list of repositories to be deleted
4. **Final confirmation** - Type `yes` to proceed with deletion
5. **Deletion summary** - Shows how many repositories were successfully deleted

## Example Output

```
=== Your GitHub Repositories ===
123456789 | my-awesome-project | Public | 2024-01-15 14:30
987654321 | private-repo | Private | 2024-01-14 09:15
456789123 | test-repo | Public | 2024-01-13 16:45
================================

Select repositories to delete:
Enter repository IDs separated by commas (e.g., 1,3,5)
Or enter 'all' to select all repositories
Or enter 'none' to cancel
Selection: 123456789,456789123

=== REPOSITORIES TO BE DELETED ===
  - yourusername/my-awesome-project
  - yourusername/test-repo
===================================

⚠️  WARNING: This action cannot be undone!
These repositories will be permanently deleted from GitHub.
Are you sure you want to proceed? (yes/no): yes

Starting deletion process...
Deleting: yourusername/my-awesome-project...
✓ Successfully deleted: yourusername/my-awesome-project
Deleting: yourusername/test-repo...
✓ Successfully deleted: yourusername/test-repo

=== Deletion Summary ===
Successfully deleted: 2 repositories
```

## Safety Features

- **Multiple confirmations** - You must confirm deletion twice
- **Clear warnings** - The script warns you that deletion is irreversible
- **Repository validation** - Only valid repository IDs are processed
- **Error handling** - Failed deletions are reported separately
- **Rate limiting** - Small delays between deletions to avoid API limits

## Troubleshooting

### Common Issues

1. **"Missing required dependencies"**
   - Install `curl` and `jq` using the commands in the Prerequisites section

2. **"Invalid token" or "HTTP 401"**
   - Check that your GitHub token is correct
   - Ensure the token has the required scopes (`repo` or `public_repo`, and `delete_repo`)

3. **"HTTP 403" (Forbidden)**
   - Your token might not have sufficient permissions
   - Make sure you have `delete_repo` scope enabled

4. **"Repository not found"**
   - The repository might have been deleted already
   - Check that you're using the correct repository ID

### Getting Help

If you encounter issues:
1. Check that your GitHub token has the correct permissions
2. Verify that the repositories you're trying to delete actually exist
3. Make sure you have the required dependencies installed
4. Check your internet connection

## Security Notes

- **Never share your GitHub token** - It provides full access to your repositories
- **Use environment variables** - Don't hardcode tokens in scripts
- **Revoke unused tokens** - Delete tokens you no longer need
- **Review permissions** - Only grant the minimum required scopes

## License

This script is provided as-is for educational and personal use. Use at your own risk.

## Disclaimer

**⚠️ WARNING**: This script permanently deletes repositories from GitHub. This action cannot be undone. Always double-check your selections and ensure you have backups of important code before proceeding.
