# env.nu -- cross-platform (Linux + macOS)
#
# version = "0.106.1"
#
# Loaded before config.nu and login.nu.
# See https://www.nushell.sh/book/configuration.html

# ---------------------------------------------------------------------------
# Platform detection
# ---------------------------------------------------------------------------
let OS       = $nu.os-info.name          # "linux" | "macos" | "windows"
let ARCH     = $nu.os-info.arch          # "x86_64" | "aarch64"
let IS_MAC   = ($OS == "macos")
let IS_LINUX = ($OS == "linux")
let HOME     = $nu.home-dir

# Homebrew prefix: Apple Silicon / Intel / Linuxbrew. Resolved by looking for
# the actual brew binary rather than assuming based on arch.
let brew_candidates = (
    ["/opt/homebrew" "/usr/local" "/home/linuxbrew/.linuxbrew"]
    | where {|p| ($p | path join "bin" "brew" | path exists) }
)
let BREW_PREFIX = (
    if ($brew_candidates | is-empty) { "/opt/homebrew" } else { $brew_candidates | first }
)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
let PROJECTS_ROOT = ($HOME | path join "crack-of-doom" "projects")

# Linux-only toolchains: kernel LLVM, ESP32 embedded, CUDA, BricsCAD.
let LINUX_TOOLCHAINS = {
    cuda_bin:        "/usr/local/cuda-13.0/bin"
    bricscad:        "/opt/bricsys/bricscad/v26"
    esp_gcc_bin:     ($HOME | path join ".rustup" "toolchains" "esp" "xtensa-esp-elf" "esp-15.2.0_20250920" "xtensa-esp-elf" "bin")
    kernel_libclang: "/usr/lib64/llvm21/lib64"
}

# Release binaries from your own projects that you want on PATH.
let PROJECT_BINS = [
    ($PROJECTS_ROOT | path join "coding" "oss" "prog-rs" "target" "release")
    ($PROJECTS_ROOT | path join "coding" "tools" "amex_budget_clean" "target" "release")
]

let COMMON_PATHS = ([
    ($HOME | path join ".cargo" "bin")
    ($HOME | path join ".local" "bin")
    ($HOME | path join "go" "bin")
    ($HOME | path join ".npm-global" "bin")
    ($HOME | path join ".spicetify")
] ++ $PROJECT_BINS)

# Paths that go at the FRONT of PATH (so they shadow system tools).
let OS_PATHS_PREPEND = if $IS_MAC {
    [
        # macOS GUI apps don't run path_helper for nushell, so Homebrew has to
        # be added explicitly or `nu` won't see brew-installed tools.
        ($BREW_PREFIX | path join "bin")
        ($BREW_PREFIX | path join "sbin")
    ]
} else {
    []
}

let OS_PATHS_APPEND = if $IS_LINUX {
    [
        $LINUX_TOOLCHAINS.cuda_bin
        $LINUX_TOOLCHAINS.bricscad
        $LINUX_TOOLCHAINS.esp_gcc_bin
    ]
} else {
    []
}

# ---------------------------------------------------------------------------
# PATH assembly
# ---------------------------------------------------------------------------
# Normalize: depending on how nu was launched, $env.PATH may already be a list
# or still be a delimited string.
let base_path = (
    if ($env.PATH | describe | str starts-with "list") {
        $env.PATH
    } else {
        $env.PATH | split row (char esep)
    }
)

# Only add directories that actually exist -- keeps PATH clean when the same
# config is used on a machine that lacks a given toolchain.
$env.PATH = (
    $base_path
    | prepend ($OS_PATHS_PREPEND | where {|p| $p | path exists })
    | append  ($COMMON_PATHS     | where {|p| $p | path exists })
    | append  ($OS_PATHS_APPEND  | where {|p| $p | path exists })
    | uniq
)

# ---------------------------------------------------------------------------
# Environment variables
# ---------------------------------------------------------------------------
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"

if $IS_MAC {
    let onepw_sock = ($nu.home-path | path join "Library" "Group Containers" "2BUA8C4S2C.com.1password" "t" "agent.sock")
    if ($onepw_sock | path exists) {
        $env.SSH_AUTH_SOCK = $onepw_sock
    } else {
        print "1Password SSH agent socket not found -- is the SSH agent enabled in 1Password?"
    }
}

$env.CODEX_CLI_PATH = ($HOME | path join ".local" "bin" "codex")

# Keep XDG data under ~/.local/share on both platforms so caches/state land in
# the same place. NOTE: $nu.data-dir is resolved at startup, before env.nu
# runs, so this does NOT relocate nushell's own vendor/autoload directory.
$env.XDG_DATA_HOME = ($HOME | path join ".local" "share")

# Default LIBCLANG_PATH. On Linux this is the kernel LLVM; use `esp-env` /
# `kernel-env` (defined in config.nu) to switch at runtime.
if $IS_LINUX {
    if ($LINUX_TOOLCHAINS.kernel_libclang | path exists) {
        $env.LIBCLANG_PATH = $LINUX_TOOLCHAINS.kernel_libclang
    }
} else if $IS_MAC {
    # Only if you've installed LLVM via Homebrew; harmless when absent.
    let mac_libclang = ($BREW_PREFIX | path join "opt" "llvm" "lib")
    if ($mac_libclang | path exists) {
        $env.LIBCLANG_PATH = $mac_libclang
    }
}

# ---------------------------------------------------------------------------
# Generated init files
# ---------------------------------------------------------------------------
# config.nu does `source ~/.zoxide.nu`, which is parse-time -- the file must
# exist or the whole config fails to load. Write a stub if zoxide is missing.
let zoxide_init = ($HOME | path join ".zoxide.nu")
if (which zoxide | is-not-empty) {
    zoxide init nushell | save -f $zoxide_init
} else if not ($zoxide_init | path exists) {
    "" | save -f $zoxide_init
}

# end of the file

