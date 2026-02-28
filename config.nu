# config.nu
#
# Installed by:
# version = "0.106.1"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings, 
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R

source "/home/kapj1coh/.config/nushell/env.nu"



$env.PATH = ($env.PATH | split row (char esep) | where { $in != "/home/kapj1coh/.config/carapace/bin" } | prepend "/home/kapj1coh/.config/carapace/bin")

def --env get-env [name] { $env | get $name }
def --env set-env [name, value] { load-env { $name: $value } }
def --env unset-env [name] { hide-env $name }

let carapace_completer = {|spans|
  load-env {
        CARAPACE_SHELL_BUILTINS: (help commands | where category != "" | get name | each { split row " " | first } | uniq  | str join "\n")
        CARAPACE_SHELL_FUNCTIONS: (help commands | where category == "" | get name | each { split row " " | first } | uniq  | str join "\n")
  }

  # if the current command is an alias, get it's expansion
  let expanded_alias = (scope aliases | where name == $spans.0 | $in.0?.expansion?)

  # overwrite
  let spans = (if $expanded_alias != null  {
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


$env.config.completions.algorithm = "fuzzy"

$env.config.color_config.hints = "yellow"


$env.config.buffer_editor = "nvim"
$env.config.show_banner = false

def --env yy [...args] {
	let tmp = (mktemp -t "yazi-cwd.XXXXXX")
	yazi ...$args --cwd-file $tmp
	let cwd = (open $tmp)
	if $cwd != "" and $cwd != $env.PWD {
		cd $cwd
	}
	rm -fp $tmp
}

# Switching between kernel LLVM and esp32 LLVM as they're different version.
def --env kernel-env [] {
    $env.LIBCLANG_PATH = "/usr/lib64/llvm21/lib64"
    print "Switched to Kernel LLVM (v21)"
}
def --env esp-env [] {
    $env.LIBCLANG_PATH = "/home/kapj1coh/.rustup/toolchains/esp/xtensa-esp32-elf-clang/esp-20.1.1_20250829/esp-clang/lib"
    print "Switched to ESP32 LLVM"
}

mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")


source ~/.zoxide.nu
alias cd = z

# Gephi specific command to make it actually launch and show graps. 
alias gephi = with-env {
  XDG_CURRENT_DESKTOP: "GNOME"
  GDK_BACKEND: "x11"
  _JAVA_AWT_WM_NONREPARENTING: "1"
  _JAVA_OPTIONS: "-Dsun.java2d.opengl=false"
} { /home/kapj1coh/Applications/rpms/gephi-0.10.1/bin/gephi }


fastfetch

prog-rs list
