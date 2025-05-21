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


alias la = ls -a
alias bat = bat -n 
alias "git log" = git log --graph --pretty=format:'%C(auto)%h%d (%cr) %cn:%G? <%ce> %s'

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
			let piped_data = $in 
				| rename item idx
				| each { |i| $i.item }
				| reverse 
				| reduce { |acc, i| $"($acc)\r\n($i)" }

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
	--res: int (-r) = 0,
	--dis (-d),
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

	if ($dis) {
		yt-dlp -S $res -f "b" $uri -o - | ffplay - -nodisp -autoexit -loglevel quiet
	} else {
		yt-dlp -S $res -f "b" $uri -o - | ffplay - -autoexit -loglevel quiet
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
