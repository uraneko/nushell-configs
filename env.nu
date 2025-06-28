# env.nu
#
# Installed by:
# version = "0.104.0"
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

$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.config.buffer_editor = "nvim"

const fg = {
	r: "\e[31m",
	g: "\e[32m",
	y: "\e[33m",
	b: "\e[34m",
	m: "\e[35m",
	c: "\e[36m",
	w: "\e[37m",
}

const bg = {
	r: "\e[41m",
	g: "\e[42m",
	y: "\e[43m",
	b: "\e[44m",
	m: "\e[45m",
	c: "\e[46m",
	w: "\e[47m",
}

const reset = "\e[0m"
const bold = "\e[1m"

def prompt_senpai [] {
	# get last command status 
	let last_good = $env.LAST_EXIT_CODE == 0
	# get count of background jobs 
	let jobs_clr = $fg.c + $bold
    let jobs = $"($jobs_clr)(job list | length | into string)($reset)"
	# set dir color
	let dir_clr = do {
		if ($last_good) {
			$fg.g + $bold 
		} else {
			$fg.r + $bold
		} 
	}
	# get current working directory
    let dir = do {
		let cwd = pwd
		let home = $env.HOME
		if ($cwd | str contains $home) {
			# str replace -a <- all flag not needed anymore since only dir basename is now displayed
			let dir = $cwd | str replace -a $home "~" | path basename
			$"($dir_clr)($dir)($reset)"
		} else {
			let dir = do { 
				if ($cwd == "/") {
					$cwd
				} else {
					$cwd | path basename
				}
			}
			$"($dir_clr)($dir)"
		}
	}
	# check if dir is a git repo 
	let is_git = (do -i { git rev-parse --is-inside-work-tree err> /dev/null | into bool }) == true

	let git = do {
		if ($is_git) {
			let has_branch = (git branch | length) != 0
			# set git branch color
			let branch_clr = "\e[1;38;2;251;13;123m"
			# get git branch, if any
			let branch = do {
				if ($has_branch) {
					$"($branch_clr) ("" + (git branch --show-current err> /dev/null))($reset)"
				} else { $"($branch_clr) !($reset)" }
			}

			['A' 'D' 'M' '?']
			| each { |s| 
				let count = git_status_count $s
				{ 's': $s, 'c': $count } 
			} 
			| where { |s| ($s | get c | into int) > 0} 
			| reduce --fold $branch { |s, acc|  
				let s = git_status_fmt ($s | get s) ($s | get c | into int)

				$acc + " " + $s 
			}
		} else { "" }
	}

	$jobs + " " + $dir +  $git + $" \e[38;2;223;173;133m⣷($reset) "
}

def git_status_count [
	status: string,
] {
	let pat = match $status {
		'A' | 'D' | 'M' => $' ($status) .*',
		'?' => '\?\? .*',
	}

	git status --porcelain | rg $pat | wc -l
}

def git_status_fmt [
	status: string,
	count: number,
] {
	let fmt = match $status {
		'A' => [$fg.g, '+'],
		'D' => [$fg.r, '-'],
		'M' => [$fg.y, '✻'],
		'?' => [$fg.b, '?'],
	}

	$"($fmt | get 0)($bold)([($fmt | get 1), $count] | str join)($reset)"
}

$env.PROMPT_INDICATOR = ''
$env.PROMPT_INDICATOR_VI_NORMAL = ''
$env.PROMPT_INDICATOR_VI_INSERT = ''
$env.PROMPT_COMMAND =  ''
$env.PROMPT_COMMAND_RIGHT =  ''
$env.PROMPT_MULTILINE_INDICATOR = ''
$env.PROMPT_COMMAND = { prompt_senpai }

### set path variable 
$env.path = [
	"/home/brownbread/.local/share/pnpm",
	"/home/brownbread/.cabal/bin",
	"/home/brownbread/.ghcup/bin",
	"/home/brownbread/.opam/default/bin",
	"/home/brownbread/.deno/bin",
	"/home/brownbread/.zig/lsp/zls/zig-out/bin",
	"/home/brownbread/.zig/bin/outfieldr/bin",
	"/home/brownbread/.zig/compiler-prebuild/zig-lang",
	"/opt/cuda/bin",
	"/home/brownbread/go/bin",
	"/home/brownbread/.zig",
	"/home/brownbread/.cargo/bin",
	"/home/brownbread/.elixir/compiler/elixir/bin",
	"/usr/local/sbin",
	"/usr/local/bin",
	"/usr/bin",
]

$env.email1 = $"($env.HTUA)/hard_emails.csv"
$env.email2 = $"($env.HTUA)/burner_emails.csv"
