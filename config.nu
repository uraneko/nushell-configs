# config.nu
#
# Installed by:
# version = "0.104.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# This file is loaded after env.nu and before login.nu
#
# You can open this file in your default editor using:
# config nu
#
# See `help config nu` for more options
#
# You can remove these comments if you want or leave
# them for future reference.

$env.config.show_banner = false

def banner [] {
	print ($"nushell (nu --version) \\ \(•◡•) / " | ansi gradient --fgend 0xEDDD53 --fgstart 0x57C785)
	print (date now | format date "%a %b %d %H:%M:%S" | str downcase | ansi gradient --fgend 0xEDDD53 --fgstart 0x57C785)
	# print (which nu | get path | get 0 | ansi gradient --fgend 0xEDDD53 --fgstart 0x57C785)
	# print ($"env ($nu.env-path)" | ansi gradient --fgend 0xEDDD53 --fgstart 0x57C785)
	# print ($"conf ($nu.config-path)" | ansi gradient --fgend 0xEDDD53 --fgstart 0x57C785)
}

banner

$env.config.keybindings = [{
	name: hot-relaod,
	modifier: none,
	keycode: f5,
	mode: [emacs vi_normal vi_insert],
	event: { 
		send: executehostcommand, 
		cmd: $"source ($nu.env-path); source ($nu.config-path); notify-send 'hot reloaded *env.nu *config.nu'"
	}
}]

alias la = ls -a
alias bat = bat -n 
alias "git log" = git log --graph --pretty=format:'%C(auto)%h%d (%cr) %cn:%G? <%ce> %s'
alias mat = mdcat

## reload config/env files
# def nu-reload [break: bool = true] {
# 	if (!$break) {
# 		source $nu.env-path
# 		source $nu.config-path
# 	}
#     sourcing config.nu would be self calling -> an infinite recursion
# }

def license [
	--mit (-m)
] {
	if ($mit) {
		bat ~/forge/.licenses/MIT.txt | save LICENSE

		return
	}

	print "you need to choose a license"
	print "run license --list/-l for a list of possible licenses"
}

### access my emails and passwords
def auth [
	--copy (-C),
	--query (-Q): list<string>,
	--max (-m): int = 1,
	--table (-t): int = 1,
	--email (-e),
	--password (-p),
	--print (-P),
] {
	# if ((not $email) and (not $password)) {
	# 	print "must provide at least email or password"
	# 	return 
	# }

	let tbl = do {
		if ($table == 1) {
			bat $"($env.email1)"
		} else if ($table == 2) {
			bat $"($env.email2)"
		} else {
			print "--table flag can only take one of `1` or `2` int values"
			return
		}
	} 
	let tbl = $tbl | from csv

	if ((not $email) and (not $password)) {
		print $tbl

		return
	}


	mut val = $tbl | where { |r| $query | all { |pat| $r.email_address | str contains $pat } }
	let len = $val | length
	if ($len > $max) {
		$val = ($val | drop ($len - $max))
	}

	if ($print) {
		print ($val)
	}

	if ($email and $password) {
		$val = $val | select "email_address" "password"	
			| each { |r| $"($r.email_address)\n($r.password)" } 
			| reduce { |acc, r| $acc + "\n" + $r } 
	} else if ($email) {
		$val = $val | get "email_address"
			| reduce { |acc, r| $acc + $"\n($r)" }
	} else if ($password) {
		$val = $val | get "password"
			| reduce { |acc, r| $acc + $"\n($r)" }
	}

	if ($copy) {
		$val | wl-copy
	}
}

### open issues in nu: 
### job control => job take <id> / <pid>
### def reload pass false by defult to break after one time 
### copying table with wl-copy break the ui 
### inconsistent up/down history 

### bat --language=l sugar
def bal [
	...args: string
] {
	match ($args | length) {
		0 => {
			print -e "at least 2 args are needed ( or 1 + piped data)"

			return 
		}
		1 =>  {
			### BUG this is broken in most cases 
			let piped_data = do { if ($in | describe | str starts-with "table") {
					$in 
						| rename item idx
						| each { |i| $i.item }
						| reverse 
						| reduce { |acc, i| $"($acc)\r\n($i)" }
				} else { $in }
			}

			$piped_data | bat  -n --language ($args | get 0)
		}
		2 =>  {
			bat ($args | get 0) -n --language ($args | get 1)
		}
	}

}

### github login 2fa generator 
def gh2fa [] {
	let s = bat $env.gh2fas
	oathtool -b --totp $s | wl-copy
}

### open some program's config dir in a separate window or cd to it 
def --env config-extra [
	--move (-m),
	path
] {
	if ($move) {
		### BUG this doesnt work
		cd $"~/.config/($path)"
	} else {
		tmux new-window -c ~/.config/($path) "nvim -c Explore"
	}
}

### random password generator 
### copies to clipboard
def rpg [] {
	python3 $"($env.py_scripts)/psw.py" | wl-copy
}

### play youtube videos from the terminal using ytp-dlp && ffplay a
def yt [
	--res: int (-r) = 360
	--headless (-H) = true,
	--loop (-l) = 0,
	uri: string
] {	
	let res = do {
		if ($res != 0) {
			match ($res) {
				144 | 240 | 360 | 480 | 720 | 1080 => $"+height:($res)"
				_ => { 
					print -e 
					$"\e[1;31mbad resolution ($res) passed; valid values are: 144 | 240 | 360 | 480 | 720 | 1080"

					return 
				}
			}
		} else {
			"+height:360"
		}
	}

	let id = job spawn --tag "ongoing" { 
		match [$headless, $loop] {
			[false, 0] => (yt-dlp -S $res -f "b" $uri -o - | ffplay - -autoexit -loglevel quiet)
			[false, _] => {
				(yt-dlp -S $res -f "b" $uri -o - | ffplay - -autoexit -loglevel quiet)
				for _ in 0..($loop - 1) {
					let video = job recv 
					$video | ffplay - -autoexit -loglevel quiet -loop $loop
				}
			}
			[true, 0] => (yt-dlp -S $res -f "b" $uri -o - | ffplay - -nodisp -autoexit -loglevel quiet)
			[true, _] => {
				(yt-dlp -S $res -f "b" $uri -o - | ffplay - -nodisp -autoexit -loglevel quiet)
				let video = job recv 
				for _ in 0..($loop - 1) {
					$video | ffplay - -nodisp -autoexit -loglevel quiet 
				}
			}
		}
	}

	let id1 = job spawn --tag "ongoing" { 
		let video = yt-dlp -S $res -f "b" $uri -o -
		$video | job send $id 
	}
} 

const themes_dir = "alacritty/alacritty-theme/themes/"
### alacritty themes completion
def atc [] { 
	 ls ~/.config/alacritty/alacritty-theme/themes/
	| get name
	| each { |n| $n 
	| str replace -r $"($env.home)/.config/($themes_dir)\(.*\).toml" "$1" }
}

### parses out the alacritty theme name from the alacritty.toml config file
def atp [] {
	### WARN this is dependant upon the line position of the theme import not changing 
	bat $"($env.home)/.config/alacritty/alacritty.toml" 
		| head -2
		| tail -1
		| str replace -r "general.import = \\[\"alacritty-theme\/themes\/\(.*\).toml\"\\]" "$1"
}

def at [
	--print (-p),
	--copy (-c),
	--list (-l),
	--set: string@atc (-s),
] {
	if ($print) {
		atp	
	} else if ($copy) {
		atp | wl-copy
	} else if ($list) {
		atc 
	} else {
		let curr = atp
		bat $"($env.home)/.config/alacritty/alacritty.toml" 
			| str replace $curr $set
			| save $"($env.home)/.config/alacritty/alacritty.toml" -f
	}
}
