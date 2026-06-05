function fish_greeting
    echo -ne '\x1b[38;5;153m'
    echo '     _____                     __              '
    echo '    / ___/______  ______  ____/ /__  _____     '
    echo '    \__ \/ ___/ / / / __ \/ __  / _ \/ ___/     '
    echo '   ___/ / /__/ /_/ / / / / /_/ /  __/ /        '
    echo '  /____/\___/\__,_/_/ /_/\__,_/\___/_/         '
    set_color normal
    fastfetch --key-padding-left 5
end
