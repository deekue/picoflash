#!/bin/sh
#
# QaD flash script for the Picobrew Zymatic
# -- Daniel Quinlan <dq@chaosengine.net>
#
# See the Picobrew website for firmware updates
# http://picobrew.com/members/software/zymatic/Installation.cshtml

# Platform defaults
if [ -e /etc/debian_version ]; then # Debian/Ubuntu et al
  if dpkg -s arduino | grep -q 'Status: install ok installed'; then
    BIN_PATH=/usr/bin/avrdude
    CONF_PATH=/usr/share/arduino/hardware/tools/avrdude.conf
    DEVICE=
  else
    echo install Arduino tools or specify -a and -c
    echo sudo apt-get install arduino
  fi
else
  # -=# EDIT DEFAULTS HERE #=-
  BIN_PATH=
  CONF_PATH=
  DEVICE=
  DRY_RUN=
fi

function usage() {
  cat <<EOF >&2
Usage: `basename -- $0` [options] <file>

Options:
  -a|--avrdude avrdude binary      [$BIN_PATH]
  -c|--config  avrdude config file [$CONF_PATH]
  -d|--device  TTY device          [$DEVICE]
  -n|--dry-run no write: disables actually writing data to the Zymatic
  --help|-h    Help: show this help message

EOF
  exit 1
}

if [ -x "`which getopt`" ]; then
  RAW_ARGS=`getopt -o h,n,a:,c:,d: \
            --long help,dry-run,avrdude:,config:,device: \
            -n "$(basename -- $0)" -- "$@"`
  [ $? != 0 ] && usage
  eval set -- "$RAW_ARGS"

  while true ; do
    case "$1" in
      -a|--avrdude) BIN_PATH=$2 ; shift 2;;
      -c|--config) CONF_PATH=$2 ; shift 2;;
      -d|--device) DEVICE=$2 ; shift 2;;
      -n|--dry-run) DRY_RUN=-n ; shift ;;
      -h|--help) usage ;;
      --) shift ; break ;;
      *) echo "unknown option ($1)" ; usage ;;
    esac
  done
fi

FILE="$1"
if [ -z "$FILE" ]; then
  echo "ERROR: no firmware file specified" >&2
  echo >&2
  usage
fi
if [ ! -r "$FILE" ]; then
  echo "ERROR: file $FILE not found or not readable" >&2
  echo >&2
fi
if [ -z "$BIN_PATH" ]; then
  echo "ERROR: avrdude binary not specified" >&2
  echo >&2
  usage
fi
if [ -z "$CONF_PATH" ]; then
  echo "ERROR: avrdude config file not specified" >&2
  echo >&2
  usage
fi
if [ -z "$DEVICE" ]; then
  echo "ERROR: TTY device not specified" >&2
  echo >&2
  usage
fi

"$BIN_PATH" $DRY_RUN -C "$CONF_PATH" -c arduino -p atmega1284p -U flash:w:"$FILE" -P "$DEVICE" "$@"

