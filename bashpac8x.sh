#! /bin/bash
set -e

function make_little {
    printf "%04x" "$1" | fold -w2 | tac | tr -d "\n"
}

function make_hex {
    printf "%02x" "$1"
}

function bytesum {
    {
        echo 'echo $(('
        xxd -i | tr ',' '+'
        echo '))'
    } | source /dev/stdin
}

if [[ "$1" == "--help" ]] ; then
    >&2 echo "Syntax: $0 <program file path> [--variable] [--archive] [CALCNAME]"
    >&2 echo "    --variable: Save as an appvar instead of a program"
    >&2 echo "    --archive: Save as an *archive file"
    >&2 echo "    --hex: Output hex instead of binary"
    exit 0
fi

TYPE=6
VERSION=0
ARCHIVE=0
OUTPUT_HEX=0

while [[ "$1" =~ -- ]] ; do
    if [[ "$1" == "--variable" ]] ; then
        >&2 echo "VARIABLING"
        TYPE=21
    fi
    if [[ "$1" == "--archive" ]] ; then
        >&2 echo "ARCHIVING"
        ARCHIVE=128
    fi
    if [[ "$1" == "--hex" ]] ; then
        >&2 echo "OUTPUT HEX"
        OUTPUT_HEX=1
    fi
    shift
done

INPUT_FILE="$1"
if [[ ! -e "$INPUT_FILE" ]] ; then
    >&2 echo "File doesn't exist: $INPUT_FILE"
    exit 1
fi

INPUT_FILENAME="$(basename "${INPUT_FILE%.*}")"

BINDATA="$(cat "$INPUT_FILE" | xxd -ps | tr -d '\n')"

BINSIZE=$(($(echo -ne "$BINDATA" | wc --bytes) / 2))
BINSIZE_LITTLE=$(make_little $BINSIZE)

NAME="$(printf "%.8s" "${2:-${INPUT_FILENAME}}")"
NAME="${NAME^^}"
NAME_HEX="$(printf "%-16s" "$(echo -ne "$NAME" | xxd -ps)" | tr ' ' 0)"

COMMENT="github.com/empathicqubit/ti8xp-c-template "
COMMENT_HEX=$(echo -ne "$COMMENT" | xxd -ps)

VARDATA="$BINSIZE_LITTLE $BINDATA"
VARSIZE=$((BINSIZE+2))

VARSIZE_LITTLE=$(make_little $VARSIZE)

VARRECORD_SIZE=$((VARSIZE+17))
if ((VARRECORD_SIZE > 0xffff)) ; then
    >&2 echo "Variable record is $((VARRECORD_SIZE - 0xffff)) greater than $((0xffff)) bytes: $VARRECORD_SIZE"
fi

VARRECORD_SIZE_LITTLE=$(make_little $VARRECORD_SIZE)

VARDATA_SUM=$(echo -ne "$VARDATA" | bytesum)
NAME_SUM=$(echo -ne "$NAME" | bytesum)

VARHEADER_SIZE=13
VARHEADER_SIZE_LITTLE=$(make_little $VARHEADER_SIZE)
VARHEADER_SIZE_LO=$((VARHEADER_SIZE & 0xff))
VARHEADER_SIZE_HI=$((VARHEADER_SIZE >> 8))

VARSIZE_LO=$((VARSIZE & 0xff))
VARSIZE_HI=$((VARSIZE >> 8))

TYPE_BYTE=$(make_hex $TYPE)
VERSION_BYTE=$(make_hex $VERSION)
ARCHIVE_BYTE=$(make_hex $ARCHIVE)

HEADER_SUM=$((2*VARSIZE_LO + 2*VARSIZE_HI + TYPE + VERSION + ARCHIVE + VARHEADER_SIZE_LO + VARHEADER_SIZE_HI))

SUM=$(((HEADER_SUM + NAME_SUM + VARDATA_SUM) % 65536))
SUM_LITTLE=$(make_little $SUM)

FILE_HEADER="$(echo -ne "**TI83F*" | xxd -ps)"

function output_pipe {
    xxd -r -ps
}

if ((OUTPUT_HEX)) ; then
    function output_pipe {
        cat
    }
fi

cat <<HERE | output_pipe
$FILE_HEADER
1A 0A 00
$COMMENT_HEX
$VARRECORD_SIZE_LITTLE
    $VARHEADER_SIZE_LITTLE
        $VARSIZE_LITTLE
        $TYPE_BYTE
        $NAME_HEX
        $VERSION_BYTE
        $ARCHIVE_BYTE
        $VARSIZE_LITTLE
    $VARDATA

$SUM_LITTLE
HERE

if [[ "$NAME" =~ ^[0-9] ]] ; then
    >&2 echo
    >&2 echo "PROGRAMS BEGINNING WITH A NUMBER ARE COMPLETELY INVISIBLE TO TIOS.
YOU PROBABLY DON'T WANT THIS UNLESS YOU HAVE A CUSTOM SHELL!!!"
fi
