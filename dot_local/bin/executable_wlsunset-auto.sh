#!/bin/sh
set -eu

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}"
cache_file="$cache_dir/wlsunset.loc"
mkdir -p "$cache_dir"

# fallback if no cache exists yet (munich)
default_lat="48.137"
default_lon="11.575"

# optional mode:
#   --update-only  updates cache and exits
#   (default)      runs wlsunset using best available coords
mode="${1:-run}"

get_ip_loc() {
  # short timeouts so this never blocks your session startup
  curl -fsS --max-time 1 https://ipinfo.io/loc 2>/dev/null || true
}

valid_loc() {
  echo "$1" | grep -Eq '^-?[0-9]+(\.[0-9]+)?,-?[0-9]+(\.[0-9]+)?$'
}

old_loc=""
if [ -f "$cache_file" ]; then
  old_loc="$(cat "$cache_file" 2>/dev/null || true)"
fi

new_loc="$(get_ip_loc)"

if [ -n "$new_loc" ] && valid_loc "$new_loc"; then
  loc="$new_loc"
  echo "$loc" >"$cache_file"
elif [ -n "$old_loc" ] && valid_loc "$old_loc"; then
  loc="$old_loc"
else
  loc="$default_lat,$default_lon"
  echo "$loc" >"$cache_file"
fi

# in update-only mode: restart wlsunset only if cache changed and wlsunset is running
if [ "$mode" = "--update-only" ]; then
  if [ -n "${old_loc:-}" ] && [ "$old_loc" != "$loc" ]; then
    if pgrep -x wlsunset >/dev/null 2>&1; then
      systemctl --user restart wlsunset.service || true
    fi
  fi
  exit 0
fi

lat="${loc%%,*}"
lon="${loc##*,}"

exec wlsunset -t 5000 -l "$lat" -L "$lon"
