#!/bin/bash
#
# flash script for Picobrew Zymatic/KegSmarts
# -- Daniel Quinlan <dq@chaosengine.net>
#
# See the Picobrew website for firmware updates
# http://picobrew.com/members/software/zymatic/Installation.cshtml
# http://picobrew.com/members/software/kegsmarts/Installation.cshtml

# -=# EDIT DEFAULTS HERE #=-
BIN_PATH=
CONF_PATH=
DEVICE=
DRY_RUN=

# auto-detect arduino tools if possible
if [ -e /etc/debian_version ]; then # Debian/Ubuntu et al
  if dpkg -s arduino | grep -q 'Status: install ok installed'; then
    BIN_PATH=/usr/bin/avrdude
    CONF_PATH=/usr/share/arduino/hardware/tools/avrdude.conf
  else
    echo install Arduino tools >&2
    echo sudo apt-get install arduino >&2
    echo >&2
    echo or specify -a and -c >&2
    echo >&2
  fi
fi

function find_picobrew_device() {
  [ -d /sys/bus/usb/devices ] || return
  # both Zymatic and Kegsmarts have the same model ID
  PICOBREW_VENDOR_ID=20a0
  PICOBREW_MODEL_ID=421e

  if type udevadm > /dev/null ; then
    for sysdevpath in $(find /sys/bus/usb/devices/usb*/ -name dev); do
        (
            syspath="${sysdevpath%/dev}"
            devname="$(udevadm info -q name -p $syspath)"
            [ "$devname" == "bus/"* ] && continue
            eval "$(udevadm info -q property --export -p $syspath)"
            [ "$ID_BUS" = "usb" -a "$SUBSYSTEM" = "tty" ] || continue
            [ "$ID_VENDOR_ID" = "$PICOBREW_VENDOR_ID" ] || continue
            case "$ID_MODEL_ID" in
              $PICOBREW_MODEL_ID)
                echo "/dev/$devname"
                ;;
              *)
                echo "Unknown Picobrew device found at /dev/$devname" >&2
                exit 1
                ;;
            esac
        )
    done
  fi
}
DEVICE=$(find_picobrew_device)

# keep usage below auto-detect code to make defaults in help work
function usage() {
  cat <<EOF >&2
Usage: `basename -- $0` [options] <file>

Options:
  -a|--avrdude avrdude binary      [$BIN_PATH]
  -c|--config  avrdude config file [$CONF_PATH]
  -d|--device  TTY device          [$DEVICE]
  -n|--dry-run no write: disables actually writing data to the Picobrew device
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

FILE="$1" ; shift
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
  echo "ERROR: avrdude binary not specified, use -a" >&2
  echo >&2
  usage
fi
if [ -z "$CONF_PATH" ]; then
  echo "ERROR: avrdude config file not specified, use -c" >&2
  echo >&2
  usage
fi
if [ -z "$DEVICE" ]; then
  echo "ERROR: TTY device not specified, use -d" >&2
  echo >&2
  usage
fi
if [ ! -w "$DEVICE" ]; then
  echo "ERROR: $DEVICE not writable. use sudo or fix permissions" >&2
  echo >&2
  usage
fi

"$BIN_PATH" $DRY_RUN -C "$CONF_PATH" -c arduino -p atmega1284p -U flash:w:"$FILE" -P "$DEVICE" "$@"

