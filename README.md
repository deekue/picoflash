# picoflash
shell script wrapper for upgrading the firmware on a [Picobrew Zymatic](http://picobrew.com)

Tested on Ubuntu.  Should work on most Unix-like systems.

Will auto-detect Arduino tools on Ubuntu/Debian
Will auto-detect TTY device on Linux

```
Usage: picoflash.sh [options] <file>

Options:
  -a|--avrdude avrdude binary      [/usr/bin/avrdude]
  -c|--config  avrdude config file [/usr/share/arduino/hardware/tools/avrdude.conf]
  -d|--device  TTY device          []
  -n|--dry-run no write: disables actually writing data to the Zymatic
  --help|-h    Help: show this help message
```
