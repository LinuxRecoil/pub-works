# =============================================================================
# Exports - Environment Variables & Paths
# =============================================================================

# PATHの重複を自動的に排除する
typeset -U path PATH

# PATHの定義 (配列で記述すると見やすいです)
path=(
    "/usr/local/bin/git"
    "${ASDF_DATA_DIR:-$HOME/.asdf}/shims"
    "$HOME/.pub-cache/bin"
    "/opt/homebrew/opt/ruby/bin"
    $path
)

export PATH

# エディタ設定
export EDITOR="code -w"
export LANG=ja_JP.UTF-8