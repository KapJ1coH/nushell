# env.nu
#
# Installed by:
# version = "0.106.1"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.
#
# This file is generated for backwards compatibility for now.
# It is loaded before config.nu and login.nu
#
# See https://www.nushell.sh/book/configuration.html
#
# Also see `help config env` for more options.
#
# You can remove these comments if you want or leave
# them for future reference.
$env.PATH ++= ["~/.cargo/bin/", "/usr/local/cuda-13.0/bin",
"/home/kapj1coh/.rustup/toolchains/esp/xtensa-esp-elf/esp-15.2.0_20250920/xtensa-esp-elf/bin",
"/opt/bricsys/bricscad/v26",
"/home/kapj1coh/crack-of-doom/projects/coding/oss/prog-rs/target/release/"
]

$env.EDITOR = "nvim"

$env.XDG_DATA_HOME = $env.HOME + /.local/share

# end of the file
zoxide init nushell | save -f ~/.zoxide.nu

# rust esp stuff
# $env.LIBCLANG_PATH = "/home/kapj1coh/.rustup/toolchains/esp/xtensa-esp32-elf-clang/esp-20.1.1_20250829/esp-clang/lib"

# Linux compilation
$env.LIBCLANG_PATH = "/usr/lib64/llvm21/lib64"
