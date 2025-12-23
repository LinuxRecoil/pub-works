# =============================================================================
# Functions
# =============================================================================

# https://zenn.dev/inovue/articles/gh-ghq-fzf-repository-management
# Repository management with ghq and fzf
repo() {
    local action="${1:-list}"
    
    case "$action" in
        "list"|"l")
            # List all repositories with fzf selection
            local selected_repo
            selected_repo=$(ghq list | fzf --height=50% --border --preview="echo {}" --preview-window=down:3:wrap)
            if [[ -n "$selected_repo" ]]; then
                echo "Selected: $selected_repo"
                echo "Path: $(ghq root)/$selected_repo"
            fi
            ;;
        "cd"|"c")
            # Change directory to selected repository
            local selected_repo
            selected_repo=$(ghq list | fzf --height=50% --border --preview="echo {}" --preview-window=down:3:wrap)
            if [[ -n "$selected_repo" ]]; then
                cd "$(ghq root)/$selected_repo" || return 1
            fi
            ;;
        "remove"|"rm"|"r")
            # Remove selected repository
            local selected_repo
            selected_repo=$(ghq list | fzf --height=50% --border --preview="echo {}" --preview-window=down:3:wrap --prompt="Select repository to remove: ")
            if [[ -n "$selected_repo" ]]; then
                echo "Are you sure you want to remove $selected_repo? [y/N]"
                read -r confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    rm -rf "$(ghq root)/$selected_repo"
                    echo "Removed: $selected_repo"
                else
                    echo "Cancelled"
                fi
            fi
            ;;
        "get"|"g")
            # Clone/get a new repository
            local use_ssh=false
            local url_arg=""
            
            # Parse options
            shift  # Remove 'get' or 'g' from arguments
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    -p|--ssh)
                        use_ssh=true
                        shift
                        ;;
                    *)
                        url_arg="$1"
                        shift
                        ;;
                esac
            done
            
            if [[ -z "$url_arg" ]]; then
                # Interactive mode: show remote repositories via gh + fzf
                local selected_repo
                selected_repo=$(gh repo list --limit 100 --json nameWithOwner --jq '.[].nameWithOwner' | fzf --height=50% --border --preview="gh repo view {} --json description,url,pushedAt --template '{{.description}}\n{{.url}}\nLast updated: {{.pushedAt}}'" --preview-window=down:5:wrap --prompt="Select repository to clone: ")
                if [[ -n "$selected_repo" ]]; then
                    if [[ "$use_ssh" == true ]]; then
                        ghq get -p "git@github.com:${selected_repo}.git"
                    else
                        ghq get "github.com/$selected_repo"
                    fi
                fi
            else
                if [[ "$use_ssh" == true ]]; then
                    # Convert URL to SSH format if needed
                    if [[ "$url_arg" =~ ^github\.com/(.+)$ ]]; then
                        local repo_path="${BASH_REMATCH[1]}"
                        ghq get -p "git@github.com:${repo_path}.git"
                    elif [[ "$url_arg" =~ ^gitlab\.com/(.+)$ ]]; then
                        local repo_path="${BASH_REMATCH[1]}"
                        ghq get -p "git@gitlab.com:${repo_path}.git"
                    elif [[ "$url_arg" =~ ^([^/]+)/(.+)$ ]]; then
                        local host="${BASH_REMATCH[1]}"
                        local repo_path="${BASH_REMATCH[2]}"
                        ghq get -p "git@${host}:${repo_path}.git"
                    else
                        ghq get -p "$url_arg"
                    fi
                else
                    ghq get "$url_arg"
                fi
            fi
            ;;
        "create"|"new"|"n")
            # Create a new repository directory
            if [[ -z "$2" ]]; then
                echo "Usage: repo create <repository_path>"
                echo "Example: repo create github.com/user/new-repo"
                return 1
            fi
            local repo_path="$(ghq root)/$2"
            mkdir -p "$repo_path"
            cd "$repo_path" || return 1
            git init
            echo "Created and initialized: $2"
            ;;
        "open"|"o")
            # Open repository in editor (default: code)
            local editor="${2:-code}"
            local selected_repo
            selected_repo=$(ghq list | fzf --height=50% --border --preview="echo {}" --preview-window=down:3:wrap)
            if [[ -n "$selected_repo" ]]; then
                local repo_path="$(ghq root)/$selected_repo"
                if command -v "$editor" > /dev/null; then
                    "$editor" "$repo_path"
                else
                    echo "Editor '$editor' not found. Trying fallback editors..."
                    if command -v code > /dev/null; then
                        code "$repo_path"
                    elif command -v vim > /dev/null; then
                        vim "$repo_path"
                    else
                        echo "No suitable editor found (code, vim)"
                    fi
                fi
            fi
            ;;
        "help"|"h"|*)
            # Show help
            cat << 'EOF'
Repository management with ghq and fzf

Usage: repo <command> [args]
Commands:
  list, l         List repositories
  cd, c           Change directory
  remove, rm, r   Remove repository
  get, g          Clone repository
  create, new, n  Create new repository
  open, o         Open in editor
  help, h         Show help
EOF
            ;;
    esac
}