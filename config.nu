# config.nu -- cross-platform (Linux + macOS)
#
# version = "0.106.1"
#
# Loaded after env.nu. See https://www.nushell.sh/book/configuration.html
#
# Pretty-print the docs for all config options with:
#     config nu --doc | nu-highlight | less -R

# ---------------------------------------------------------------------------
# Platform detection
# ---------------------------------------------------------------------------
let OS       = $nu.os-info.name
let IS_MAC   = ($OS == "macos")
let IS_LINUX = ($OS == "linux")
let HOME     = $nu.home-dir

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
# Carapace stores its bridge shims under the platform config dir, which differs
# between Linux (XDG) and macOS (Application Support).
let CARAPACE_BIN_DIRS = [
    ($HOME | path join ".config" "carapace" "bin")
    ($HOME | path join "Library" "Application Support" "carapace" "bin")
]

# ---------------------------------------------------------------------------
# PATH additions
# ---------------------------------------------------------------------------
# NOTE: the original config re-sourced env.nu here. That's unnecessary --
# nushell loads env.nu automatically before config.nu -- and it caused the
# zoxide init to run twice per startup. Removed.

let carapace_bin = ($CARAPACE_BIN_DIRS | where {|p| $p | path exists })
if ($carapace_bin | is-not-empty) {
    $env.PATH = ($env.PATH | where {|p| $p not-in $carapace_bin } | prepend $carapace_bin)
}

# ---------------------------------------------------------------------------
# Small env helpers
# ---------------------------------------------------------------------------
def --env get-env [name] { $env | get $name }
def --env set-env [name, value] { load-env { $name: $value } }
def --env unset-env [name] { hide-env $name }

# ---------------------------------------------------------------------------
# Completions (carapace)
# ---------------------------------------------------------------------------
let carapace_completer = {|spans|
    load-env {
        CARAPACE_SHELL_BUILTINS: (help commands | where category != "" | get name | each { split row " " | first } | uniq | str join "\n")
        CARAPACE_SHELL_FUNCTIONS: (help commands | where category == "" | get name | each { split row " " | first } | uniq | str join "\n")
    }

    # if the current command is an alias, get its expansion
    let expanded_alias = (scope aliases | where name == $spans.0 | $in.0?.expansion?)

    let spans = (if $expanded_alias != null {
        # put the first word of the expanded alias first in the span
        $spans | skip 1 | prepend ($expanded_alias | split row " " | take 1)
    } else {
        $spans | skip 1 | prepend ($spans.0)
    })

    carapace $spans.0 nushell ...$spans
    | from json
}

mut current = (($env | default {} config).config | default {} completions)
$current.completions = ($current.completions | default {} external)
$current.completions.external = ($current.completions.external
| default true enable
# backwards compatible workaround for default, see nushell #15654
| upsert completer { if $in == null { $carapace_completer } else { $in } })
$env.config = $current

# ---------------------------------------------------------------------------
# Shell settings
# ---------------------------------------------------------------------------
$env.config.completions.algorithm = "fuzzy"
$env.config.color_config.hints = "yellow"
$env.config.buffer_editor = "nvim"
$env.config.show_banner = false

# ---------------------------------------------------------------------------
# yazi: cd to the directory you quit in
# ---------------------------------------------------------------------------
def --env yy [...args] {
    # Portable temp file: GNU and BSD `mktemp -t` disagree on how templates are
    # handled, so pass a full template path instead.
    let tmp = (mktemp -p $nu.temp-dir "yazi-cwd.XXXXXX" )
    yazi ...$args --cwd-file $tmp
    let cwd = (open $tmp)
    if $cwd != "" and $cwd != $env.PWD {
        cd $cwd
    }
    rm -fp $tmp
}

# ---------------------------------------------------------------------------
# Toolchain switching (Linux only)
# ---------------------------------------------------------------------------
# Kernel LLVM and ESP32 LLVM are different versions, so LIBCLANG_PATH has to be
# swapped depending on what you're building. Both of these are Linux-only --
# defined unconditionally (nushell `def` is parse-time, so it can't be wrapped
# in an `if`) but they refuse to run elsewhere.

def --env kernel-env [] {
    if $nu.os-info.name != "linux" {
        print $"kernel-env is Linux-only \(current platform: ($nu.os-info.name)\)"
        return
    }
    $env.LIBCLANG_PATH = "/usr/lib64/llvm22/lib64"
    print "Switched to Kernel LLVM (v22)"
}

def --env esp-env [] {
    if $nu.os-info.name != "linux" {
        print $"esp-env is Linux-only \(current platform: ($nu.os-info.name)\)"
        return
    }
    $env.LIBCLANG_PATH = ($nu.home-dir | path join ".rustup" "toolchains" "esp" "xtensa-esp32-elf-clang" "esp-20.1.1_20250829" "esp-clang" "lib")
    print "Switched to ESP32 LLVM"
}

# ---------------------------------------------------------------------------
# Prompt / autoload
# ---------------------------------------------------------------------------
mkdir ($nu.data-dir | path join "vendor" "autoload")
if (which starship | is-not-empty) {
    starship init nu | save -f ($nu.data-dir | path join "vendor" "autoload" "starship.nu")
}

# ---------------------------------------------------------------------------
# zoxide
# ---------------------------------------------------------------------------
# env.nu regenerates (or stubs) this file before config.nu is parsed.
source ~/.zoxide.nu
alias cd = z

alias gg = lazygit

