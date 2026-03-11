function music() {

    if [[ `hostname` == "hackintosh" ]]; then
        if [[ "$1" == "--enable" ]]; then

            if ! ssh -q -O check gate-infn; then
                echo "INFO: setting up proxy..."
                ssh -fN gate-infn
            fi

            if ! ps aux | grep sshfs | grep -q /home/gipert/music; then
                echo "INFO: mounting remote music library..."
                sshfs gipert@localhost:/data/pertoldi/music ~/music -p 9093 -o idmap=user,ro
            fi

            if ! ps aux | grep -q ' [m]pd'; then
                echo "INFO: starting MPD server..."
                mpd
            fi

            if ! ps aux | grep polybar | grep -q music; then
                echo "INFO: enabling music bar..."
                bspc config -m eDP1 bottom_padding 29 && \
                polybar music &> ~/.config/polybar/music.log & disown && \
                echo $! > ~/.config/polybar/polybar.pid
            fi

        elif [[ "$1" == "--disable" ]]; then
            echo "INFO: killing the MPD server..."
            mpd --kill
            echo "INFO: removing the music bar..."
            kill -s TERM `cat ~/.config/polybar/polybar.pid`
            bspc config bottom_padding -7
            rm -f ~/.config/polybar/polybar.pid
            echo "INFO: unmounting music library..."
            fusermount3 -u ~/music
        else
            echo "ERROR: unsupported option '$1'"
        fi
    else
        echo "ERROR: works only on 'hackintosh'"
    fi
}

function cdrip() {
    #
    #  CDRIP
    # =======
    #
    # Rip Audio CD with cdparanoia, FLAC-encode it and auto tag it with beets
    #
    # Usage: cdrip [cdparanoia options]
    #
    # Prerequisites:
    #  - cd-discid             -> http://linukz.org/cd-discid.shtml
    #  - cdparanoia            -> https://xiph.org/paranoia
    #  - flac                  -> https://xiph.org/flac
    #  - python-musicbrainzngs -> https://pypi.org/project/musicbrainzngs
    #  - python-discid         -> https://pypi.org/project/discid
    #  - beets                 -> https://beets.io
    #
    #  On Arch Linux install: cd-discid cdparanoia flac python-musicbrainzngs python-discid beets

    setopt pipe_fail
    setopt local_options

    local offset=0
    local cdparanoia_opts=()

    local options='v'
    local longoptions='offset:,disable-paranoia'
    parsed=$(getopt --name `basename $0` --options $options --longoptions $longoptions -- "$@")
    [ $? -eq 0 ] || exit 1
    eval set -- "$parsed"
    while true; do
        case "$1" in
            -v)
                set -xv
                shift
                ;;
            --offset)
                offset=$2
                shift 2
                ;;
            --disable-paranoia)
                cdparanoia_opts+=($1)
                shift
                ;;
            --)
                shift
                break
                ;;
            *)
              echo "ERROR: bad configuration"
              ;;
        esac
    done

    local output="$HOME/ripped"
    mkdir -p "$output"

    # quit if CD not inserted
    if ! cdparanoia --search-for-drive --query; then
       echo "cdrip> CD-ROM might be still loading, retrying in 10 seconds..."
       sleep 10
       cdparanoia --search-for-drive --query || return 1
    fi

    local cddbinfo=($(cd-discid))
    local ntracks=$cddbinfo[2]
    local logfile="$output/info.log"

    # rip CD with cdparanoia and encode to FLAC
    # in one go (all hail Unix pipes)
    for tr in $(seq -w 1 $ntracks); do
        cdparanoia \
            --search-for-drive \
            --log-summary="$logfile" \
            --abort-on-skip \
            "${cdparanoia_opts[@]}" \
            -- "$tr" - \
        | flac - \
            --output-name "$output/track-$((tr+offset)).flac" \
            --tag track=$((tr+offset)) \
            --warnings-as-errors \
            --silent \
            --force \
            --best \
        || return 1
    done

    # calculate MusicBrainz release [1] with disc ID [2]
    # note: CD must be in!
    # note: needs "pip install discid musicbrainzngs"
    #
    # [1] https://musicbrainz.org/doc/Disc_ID
    # [2] https://musicbrainz.org/doc/Release
    local pycode='
from sys import exit
import discid
import musicbrainzngs

musicbrainzngs.set_useragent("cdrip", "v0.1", "gipert@pm.me")

disc = discid.read()
data = None
try:
  data = musicbrainzngs.get_releases_by_discid(disc.id)
except musicbrainzngs.musicbrainz.ResponseError as e:
  print("ERROR: could not find the disc ID in the musicbrainz database, please submit it through the following URL:")
  print(">>>", disc.submission_url)
  exit(1)
else:
  print(":".join([r["id"] for r in data["disc"]["release-list"]]))
'
    local musicbrainz_releases=$(python -c "$pycode") || return 1
    echo "MusicBrainz releases found: $musicbrainz_releases" | tee "$logfile"

    # now we can safely eject the CD
    eject

    # import and autotag music with beets
    # further customization in ~/.config/beets/config.yaml
    beet \
        --directory "$HOME/music" \
        --plugins fetchart,musicbrainz \
        import \
        --move \
        --search-id "$musicbrainz_releases" \
        -- "$output" || return 1

    # finally remove temporary directory if empty
    rm "$logfile"
    [ "$(ls -A $output)" ] || rm -r "$output"
}
