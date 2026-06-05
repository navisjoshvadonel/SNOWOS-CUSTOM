#!/usr/bin/env fish

argparse -n 'install.fish' -X 0 \
    'h/help' \
    'noconfirm' \
    'spotify' \
    'vscode=?!contains -- "$_flag_value" codium code' \
    'discord' \
    'zen' \
    'aur-helper=!contains -- "$_flag_value" yay paru' \
    -- $argv
or exit

# Print help
if set -q _flag_h
    echo 'usage: ./install.sh [-h] [--noconfirm] [--spotify] [--vscode] [--discord] [--aur-helper]'
    echo
    echo 'options:'
    echo '  -h, --help                  show this help message and exit'
    echo '  --noconfirm                 do not confirm package installation'
    echo '  --spotify                   install Spotify (Spicetify)'
    echo '  --vscode=[codium|code]      install VSCodium (or VSCode)'
    echo '  --discord                   install Discord (OpenAsar + Equicord)'
    echo '  --zen                       install Zen browser'
    echo '  --aur-helper=[yay|paru]     the AUR helper to use'
    echo
    echo 'note: Arch package installation is automatic. On Ubuntu and other'
    echo '      non-Arch systems, package installs are skipped so the script'
    echo '      can safely apply the compatible dark config files.'

    exit
end


# Helper funcs
function _out -a colour text
    set_color $colour
    # Pass arguments other than text to echo
    echo $argv[3..] -- ":: $text"
    set_color normal
end

function log -a text
    _out cyan $text $argv[2..]
end

function input -a text
    _out blue $text $argv[2..]
end

function sh-read
    sh -c 'read a && echo -n "$a"' || exit 1
end

function has-cmd -a name
    command -sq $name
end

function confirm-overwrite -a path
    if test -e $path -o -L $path
        # No prompt if noconfirm
        if set -q noconfirm
            input "$path already exists. Overwrite? [Y/n]"
            log 'Removing...'
            rm -rf $path
        else
            # Prompt user
            input "$path already exists. Overwrite? [Y/n] " -n
            set -l confirm (sh-read)

            if test "$confirm" = 'n' -o "$confirm" = 'N'
                log 'Skipping...'
                return 1
            else
                log 'Removing...'
                rm -rf $path
            end
        end
    end

    return 0
end


# Variables
set -q _flag_noconfirm && set noconfirm '--noconfirm'
set -q _flag_aur_helper && set -l aur_helper $_flag_aur_helper || set -l aur_helper paru
set -q XDG_CONFIG_HOME && set -l config $XDG_CONFIG_HOME || set -l config $HOME/.config
set -q XDG_STATE_HOME && set -l state $XDG_STATE_HOME || set -l state $HOME/.local/state
set -l install_dir (path dirname (path resolve (status filename)))

# Startup prompt
set_color magenta
echo '╭─────────────────────────────────────────────────╮'
echo '│      ______           __          __  _         │'
echo '│     / ____/___ ____  / /__  _____/ /_(_)___ _   │'
echo '│    / /   / __ `/ _ \/ / _ \/ ___/ __/ / __ `/   │'
echo '│   / /___/ /_/ /  __/ /  __(__  ) /_/ / /_/ /    │'
echo '│   \____/\__,_/\___/_/\___/____/\__/_/\__,_/     │'
echo '│                                                 │'
echo '╰─────────────────────────────────────────────────╯'
set_color normal
log 'Welcome to the Snowy glassmorphism installer!'
log 'Before continuing, please ensure you have made a backup of your config directory.'
if ! has-cmd pacman
    log 'pacman was not found, so package installation will be skipped.'
    log 'The script will still install compatible config links and keep things dark-themed.'
end

# Prompt for backup
if ! set -q _flag_noconfirm
    log '[1] Two steps ahead of you!  [2] Make one for me please!'
    input '=> ' -n
    set -l choice (sh-read)

    if contains -- "$choice" 1 2
        if test $choice = 2
            log "Backing up $config..."

            if test -e $config.bak -o -L $config.bak
                input 'Backup already exists. Overwrite? [Y/n] ' -n
                set -l overwrite (sh-read)

                if test "$overwrite" = 'n' -o "$overwrite" = 'N'
                    log 'Skipping...'
                else
                    rm -rf $config.bak
                    cp -r $config $config.bak
                end
            else
                cp -r $config $config.bak
            end
        end
    else
        log 'No choice selected. Exiting...'
        exit 1
    end
end


cd $install_dir || exit 1

if has-cmd pacman
    # Install AUR helper if not already installed
    if ! pacman -Q $aur_helper &> /dev/null
        log "$aur_helper not installed. Installing..."

        # Install
        sudo pacman -S --needed git base-devel $noconfirm
        cd /tmp
        git clone https://aur.archlinux.org/$aur_helper.git
        cd $aur_helper
        makepkg -si
        cd ..
        rm -rf $aur_helper

        # Setup
        if test $aur_helper = yay
            $aur_helper -Y --gendb
            $aur_helper -Y --devel --save
        else
            $aur_helper --gendb
        end
    end

    # Install metapackage for deps
    log 'Installing metapackage...'

    if test $aur_helper = yay
        $aur_helper -Bi . $noconfirm
    else
        $aur_helper -Ui $noconfirm
    end
    fish -c 'rm -f caelestia-meta-*.pkg.tar.zst' 2> /dev/null
else
    log 'Skipping Arch metapackage installation because pacman is unavailable.'
end

# Install hypr* configs
if confirm-overwrite $config/hypr
    log 'Installing hypr* configs...'
    ln -s (realpath hypr) $config/hypr
    chmod u+x $config/hypr/scripts/wsaction.fish
    if has-cmd hyprctl
        hyprctl reload
    end
end

# Starship
if confirm-overwrite $config/starship.toml
    log 'Installing starship config...'
    ln -s (realpath starship.toml) $config/starship.toml
end

# Foot
if confirm-overwrite $config/foot
    log 'Installing foot config...'
    ln -s (realpath foot) $config/foot
end

# Fish
if confirm-overwrite $config/fish
    log 'Installing fish config...'
    ln -s (realpath fish) $config/fish
end

# Fastfetch
if confirm-overwrite $config/fastfetch
    log 'Installing fastfetch config...'
    ln -s (realpath fastfetch) $config/fastfetch
end

# Uwsm
if confirm-overwrite $config/uwsm
    log 'Installing uwsm config...'
    ln -s (realpath uwsm) $config/uwsm
end

# Btop
if confirm-overwrite $config/btop
    log 'Installing btop config...'
    ln -s (realpath btop) $config/btop
end

# Zed
if confirm-overwrite $config/zed
    log 'Installing zed config...'
    ln -s (realpath zed) $config/zed
end

# Micro
if confirm-overwrite $config/micro
    log 'Installing micro config...'
    ln -s (realpath micro) $config/micro
end

# Thunar
if confirm-overwrite $config/Thunar
    log 'Installing thunar config...'
    ln -s (realpath thunar) $config/Thunar
end

# GTK settings
if confirm-overwrite $config/gtk-3.0
    log 'Installing gtk-3.0 settings...'
    ln -s (realpath gtk-3.0) $config/gtk-3.0
end

if confirm-overwrite $config/gtk-4.0
    log 'Installing gtk-4.0 settings...'
    ln -s (realpath gtk-4.0) $config/gtk-4.0
end

# Install spicetify
if set -q _flag_spotify
    log 'Installing snowy spotify (spicetify)...'

    set -l has_spicetify ''
    if has-cmd pacman
        set has_spicetify (pacman -Q spicetify-cli 2> /dev/null)
        $aur_helper -S --needed spotify spicetify-cli spicetify-marketplace-bin $noconfirm
    end

    # Set permissions and init if new install
    if test -z "$has_spicetify"
        if has-cmd spicetify
            sudo chmod a+wr /opt/spotify
            sudo chmod -R a+wr /opt/spotify/Apps
            spicetify backup apply
        end
    end

    # Install configs
    if confirm-overwrite $config/spicetify
        log 'Installing spicetify config...'
        ln -s (realpath spicetify) $config/spicetify

        # Set spicetify configs
        if has-cmd spicetify
            spicetify config current_theme snowy color_scheme snowy custom_apps marketplace 2> /dev/null
            spicetify apply
        end
    end
end

# Install vscode
if set -q _flag_vscode
    if test "$_flag_vscode" = 'code'
        set -l prog 'code'
        set -l packages 'code'
        set -l folder 'Code'
    else
        set -l prog 'codium'
        set -l packages 'vscodium-bin' 'vscodium-bin-marketplace'
        set -l folder 'VSCodium'
    end
    set -l folder $config/$folder/User

    log "Installing snowy vs$prog..."
    if has-cmd pacman
        $aur_helper -S --needed $packages $noconfirm
    end

    # Install configs
    if confirm-overwrite $folder/settings.json && confirm-overwrite $folder/keybindings.json && confirm-overwrite $config/$prog-flags.conf
        log "Installing vs$prog config..."
        ln -s (realpath vscode/settings.json) $folder/settings.json
        ln -s (realpath vscode/keybindings.json) $folder/keybindings.json
        ln -s (realpath vscode/flags.conf) $config/$prog-flags.conf

        # Install extension
        if has-cmd $prog
            $prog --install-extension vscode/caelestia-vscode-integration/caelestia-vscode-integration-*.vsix
        end
    end
end

# Install discord
if set -q _flag_discord
    log 'Installing snowy discord...'
    if has-cmd pacman
        $aur_helper -S --needed discord equicord-installer-bin $noconfirm

        # Install OpenAsar and Equicord
        sudo Equilotl -install -location /opt/discord
        sudo Equilotl -install-openasar -location /opt/discord

        # Remove installer
        $aur_helper -Rns equicord-installer-bin $noconfirm
    else
        log 'Skipping Discord install because the Arch package workflow is unavailable.'
    end
end

# Install zen
if set -q _flag_zen
    log 'Installing snowy zen...'
    if has-cmd pacman
        $aur_helper -S --needed zen-browser-bin $noconfirm
    end

    # Install userChrome css
    if test -d $HOME/.zen
        for chrome in (find $HOME/.zen -type d -path '*/chrome' 2> /dev/null)
            if confirm-overwrite $chrome/userChrome.css
                log 'Installing zen userChrome...'
                ln -s (realpath zen/userChrome.css) $chrome/userChrome.css
            end
        end
    end

    # Install native app
    set -l hosts $HOME/.mozilla/native-messaging-hosts
    set -l lib $HOME/.local/lib/caelestia

    if confirm-overwrite $hosts/caelestiafox.json
        log 'Installing zen native app manifest...'
        mkdir -p $hosts
        cp zen/native_app/manifest.json $hosts/caelestiafox.json
        sed -i "s|{{ \$lib }}|$lib|g" $hosts/caelestiafox.json
    end

    if confirm-overwrite $lib/caelestiafox
        log 'Installing zen native app...'
        mkdir -p $lib
        ln -s (realpath zen/native_app/app.fish) $lib/caelestiafox
    end

    # Prompt user to install extension
    log 'Please install the CaelestiaFox extension from https://addons.mozilla.org/en-US/firefox/addon/caelestiafox if you have not already done so.'
end

# Stock Firefox userChrome
if test -d $HOME/.mozilla/firefox
    for chrome_dir in (find $HOME/.mozilla/firefox -type d -path '*/chrome' 2> /dev/null)
        if confirm-overwrite $chrome_dir/userChrome.css
            log 'Installing firefox userChrome...'
            mkdir -p $chrome_dir
            ln -s (realpath firefox/userChrome.css) $chrome_dir/userChrome.css
        end
    end
end

# Generate scheme stuff if needed
if has-cmd caelestia
    if ! test -f $state/caelestia/scheme.json
        caelestia scheme set -n snowy
        sleep .5
        if has-cmd hyprctl
            hyprctl reload
        end
    end
end

# Start the shell
if has-cmd caelestia
    caelestia shell -d > /dev/null
end

log 'Done!'
