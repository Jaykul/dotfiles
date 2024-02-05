# My dotfiles

These are my personal configuration files, and are not meant to be prescriptive, nor are they meant to really be used --as is-- by anyone other than me.

Apart from that, there are two more caveats:

1. I'm a Windows user. I'm trying to keep this cross-platform so I can sync into Azure Cloud Shell and WSL, but these are Windows-first.
2. I use [BoxStarter](/Jaykul/BoxStarter-Boxes) to bootstrap my computers, so there are a few things which I'm just _assuming_ will be present.

I don't sync all my configuration through Chezmoi, but what's here is:

1. My PowerShell Profile (and install scripts for the modules I depend on)/
2. My VS Code configuration (but not the setup)
3. My git config
4. My Windows [Terminal](https://github.com/Microsoft/Terminal) settings.
    - I also have my [WezTerm](https://wezfurlong.org/wezterm/) config here. It's cross-platform, and has remote multiplexing and ssh support that makes Windows Terminal jealous, plus all kinds off graphics (Kitty, Sixel, iTerm2 imgcat, etc)
    - I do not have a [Contour](http://contour-terminal.org/) config yet, but I'm jealous of it's VT320 statusline support, and it has sixel graphics.
