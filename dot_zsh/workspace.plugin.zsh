get_connected_monitors() {
    xrandr --query | grep '\bconnected\b' | awk '{print $1}' | grep -v '${builtin_s}'
}

is_monitor_connected() {
    for mon in "$@"; do
        if ! xrandr --query | grep ${mon} | grep ' connected ' &> /dev/null; then
            echo "ERROR: monitor ${mon} is not connected"
            return 1;
        fi
    done
}

monitor_setup() {

    local popts="--quiet"

    # FIXME: bspc monitor -r does not work!

    local scale=1
    if [[ "$1" == "--scale" ]]; then
        scale=$2
        shift 2
    fi

    local builtin_s='eDP1'
    local external_s=${2:-HDMI1}

    # don't do anything if the built-in monitor is not connected
    is_monitor_connected ${builtin_s} || return 1

    # kill all bars
    polybar-msg cmd quit &> /dev/null

    case "$1" in

        office)
            local main_s='DP2' # DP2 | DVI-I-2-2
            local vert_s='HDMI1'

            # turn on built-in and kill all the others
            xrandr --output ${builtin_s} --auto
            MONITOR=${builtin_s} polybar ${popts} thinkpad & disown
            bspc monitor ${builtin_s} -d external

            if is_monitor_connected ${main_s}; then
                xrandr --output ${main_s} --auto --mode 3840x2160 --right-of ${builtin_s}
                MONITOR=${main_s} polybar ${popts} thinkpad & disown
                bspc monitor ${main_s} -d I II III IV V VI VII VIII IX X XI XII
            fi

            if is_monitor_connected ${vert_s}; then
                # FIXME: this xrandr call does not always work somehow...
                xrandr --output ${vert_s} --auto --scale 1.5 --rotate left --right-of ${main_s}
                MONITOR=${vert_s} polybar ${popts} vertical & disown
                bspc monitor ${vert_s} -d vertical
            fi

            xbacklight -set 80
            setxkbmap us
            # xset r rate 300 40
            ;;

        external)
            is_monitor_connected ${external_s} || return 1

            xrandr --output ${builtin_s} --auto
            MONITOR=${builtin_s} polybar ${popts} thinkpad & disown
            bspc monitor ${builtin_s} -d external

            xrandr --output ${external_s} --auto --scale $scale --right-of ${builtin_s}
            MONITOR=${external_s} polybar ${popts} thinkpad & disown
            bspc monitor ${external_s} -d I II III IV V VI VII VIII IX X XI XII
            ;;

        mirror)
            is_monitor_connected ${external_s} || return 1

            xrandr --output ${builtin_s} --auto
            xrandr --output ${external_s} --auto --scale $scale --same-as ${builtin_s}

            MONITOR=${builtin_s} polybar ${popts} thinkpad & disown
            bspc monitor ${builtin_s} -d I II III IV V VI VII VIII IX X XI XII
            ;;

        movie)
            is_monitor_connected ${external_s} || return 1

            # NOTE: this confuses bspwm, it lists only eDP1 as active monitor afterwards
            xrandr --auto --output ${external_s} --auto --scale $scale || return 1
            MONITOR=${external_s} polybar ${popts} thinkpad & disown
            bspc monitor ${external_s} -d I II III IV V VI VII VIII IX X XI XII || return 1

            # xrandr --output ${builtin_s} --off
            ;;

        home)
            monitor_setup --scale 2 movie

            def=4
            for s in $(pacmd list-sinks | grep index); do def=$s; done
            pacmd set-default-sink $def
            setxkbmap us
            # xset r rate 300 40
            ;;

        default | *)

            # shut all monitors off
            while IFS= read -r m; do
                # do not switch off builtin
                [[ "$m" == "${builtin_s}" ]] && continue

                echo "INFO: shutting off $m"
                bspc monitor $m -r
                xrandr --output $m --off
            done <<< "$(get_connected_monitors)"

            # switch on bar on builtin display
            MONITOR=${builtin_s} polybar ${popts} thinkpad & disown

            # and assign desktops
            bspc monitor ${builtin_s} -d I II III IV V VI VII VIII IX X XI XII

            # adopt all orphan nodes
            bspc wm -o

            setxkbmap de
            # xset r rate 300 40
            ;;
    esac

    # restart dunst
    killall -SIGUSR1 dunst && killall -SIGUSR2 dunst

    rand_wallpaper
}

rand_wallpaper() {
    if command -v feh > /dev/null && [ -d ~/pictures/wallpapers ]; then
        # NOTE: would --random-source=/dev/urandom improve the quality of random numbers?
        # they are definitely not good atm
        local all_img=$(find ~/pictures/wallpapers/photos/desktop -regextype egrep -iregex '.*.(png|jpe?g|heic)')
        local img=$(echo "$all_img" | sort -R | tail -n 1)
        feh --bg-center --bg-fill "$img"
    fi
}
