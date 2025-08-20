{
  config,
  lib,
  pkgs,
  ...
}: {
  # GitHub automation setup script - makes repo automation available system-wide
  home.packages = [
    (pkgs.writeShellScriptBin "setup-repo-automation" ''
      #!/bin/bash
      # Setup GitHub automation for a repository
      
      set -e
      
      REPO_PATH="''${1:-.}"
      TEMPLATES_DIR="${./../../templates}"
      
      # Colors for output
      RED='\033[0;31m'
      GREEN='\033[0;32m' 
      YELLOW='\033[1;33m'
      NC='\033[0m' # No Color
      
      echo "🤖 Setting up GitHub automation for repository..."
      
      # Navigate to repo
      cd "$REPO_PATH"
      
      # Check if we're in a git repo
      if ! git rev-parse --git-dir > /dev/null 2>&1; then
          echo -e "''${RED}Error: Not in a git repository''${NC}"
          exit 1
      fi
      
      REPO_NAME=$(basename $(git rev-parse --show-toplevel))
      echo -e "''${GREEN}Repository: ''${REPO_NAME}''${NC}"
      
      # Create .github/workflows directory if it doesn't exist
      mkdir -p .github/workflows
      
      # Copy lead notifications workflow
      cp "''${TEMPLATES_DIR}/lead-notifications.yml" .github/workflows/
      echo -e "''${GREEN}✓ Added lead-notifications.yml workflow''${NC}"
      
      # Show status
      echo -e "''${YELLOW}GitHub Actions workflows installed:''${NC}"
      ls -la .github/workflows/
      
      echo -e "''${GREEN}🎉 GitHub automation setup complete!''${NC}"
      echo -e "''${YELLOW}Commit the .github/workflows/ directory to enable automation.''${NC}"
    '')
  ];
  
  # Create templates directory structure in Nix store
  home.file = {
    ".config/github-automation/templates/lead-notifications.yml" = {
      text = ''
        name: Lead Notifications
        
        on:
          issues:
            types: [opened, closed, reopened, assigned, unassigned]
          pull_request:
            types: [opened, closed, reopened, review_requested, ready_for_review, merged]
          pull_request_review:
            types: [submitted]
          issue_comment:
            types: [created]
          pull_request_review_comment:
            types: [created]
          push:
            branches: [main]
        
        jobs:
          notify-lead:
            runs-on: ubuntu-latest
            if: github.actor != 'github-actions[bot]'  # Don't notify about bot actions
            
            steps:
              - name: Generate Summary
                id: summary
                run: |
                  # Determine event description
                  case "''${{ github.event_name }}" in
                    "issues")
                      DESCRIPTION="Issue #''${{ github.event.issue.number }}: ''${{ github.event.action }}"
                      URL="''${{ github.event.issue.html_url }}"
                      ;;
                    "pull_request")
                      DESCRIPTION="PR #''${{ github.event.pull_request.number }}: ''${{ github.event.action }}"
                      URL="''${{ github.event.pull_request.html_url }}"
                      ;;
                    "pull_request_review")
                      DESCRIPTION="PR #''${{ github.event.pull_request.number }}: review ''${{ github.event.review.state }}"
                      URL="''${{ github.event.review.html_url }}"
                      ;;
                    "issue_comment" | "pull_request_review_comment")
                      if [ "''${{ github.event.issue.pull_request }}" != "" ]; then
                        DESCRIPTION="PR #''${{ github.event.issue.number }}: new comment"
                        URL="''${{ github.event.comment.html_url }}"
                      else
                        DESCRIPTION="Issue #''${{ github.event.issue.number }}: new comment"  
                        URL="''${{ github.event.comment.html_url }}"
                      fi
                      ;;
                    "push")
                      DESCRIPTION="Push to main: ''${{ github.event.head_commit.message }}"
                      URL="''${{ github.event.compare }}"
                      ;;
                    *)
                      DESCRIPTION="Repository activity: ''${{ github.event_name }}"
                      URL="''${{ github.event.repository.html_url }}"
                      ;;
                  esac
                  
                  echo "description=''${DESCRIPTION}" >> $GITHUB_OUTPUT
                  echo "url=''${URL}" >> $GITHUB_OUTPUT
              
              - name: Create Issue Comment
                uses: actions/github-script@v7
                with:
                  github-token: ''${{ secrets.GITHUB_TOKEN }}
                  script: |
                    const { description, url } = process.env;
                    
                    // Find or create a daily tracking issue
                    const today = new Date().toISOString().split('T')[0];
                    const issueTitle = `🤖 Lead Activity Summary - ''${today}`;
                    
                    // Search for existing daily issue
                    const issues = await github.rest.issues.listForRepo({
                      owner: context.repo.owner,
                      repo: context.repo.repo,
                      state: 'open',
                      labels: 'daily-summary',
                      sort: 'created',
                      direction: 'desc'
                    });
                    
                    let dailyIssue = issues.data.find(issue => issue.title === issueTitle);
                    
                    if (!dailyIssue) {
                      // Create new daily tracking issue
                      const newIssue = await github.rest.issues.create({
                        owner: context.repo.owner,
                        repo: context.repo.repo,
                        title: issueTitle,
                        labels: ['daily-summary'],
                        body: `## Daily Activity Summary for ''${today}
                    
                    This issue tracks all repository activity for today. Updates are posted automatically.
                    
                    ### Activity Log:
                    `
                      });
                      dailyIssue = newIssue.data;
                    }
                    
                    // Add comment to daily issue
                    const timestamp = new Date().toLocaleTimeString();
                    const commentBody = `**''${timestamp}**: [''${description}](''${url})`;
                    
                    await github.rest.issues.createComment({
                      owner: context.repo.owner,
                      repo: context.repo.repo,
                      issue_number: dailyIssue.number,
                      body: commentBody
                    });
                env:
                  description: ''${{ steps.summary.outputs.description }}
                  url: ''${{ steps.summary.outputs.url }}
      '';
    };
  };
}