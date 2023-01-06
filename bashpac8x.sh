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
        xxd -i | tr , +
        echo '))'
    } | source /dev/stdin
}

if [[ "$1" == "--help" ]] ; then
    >&2 echo "Syntax: $0 <program file path> [--variable] [--archive] [CALCNAME]"
    >&2 echo "    --variable: Save as an appvar instead of a program"
    >&2 echo "    --archive: Save as an *archive file"
    exit 0
fi

TYPE=6
VERSION=0
ARCHIVE=0

while [[ "$1" =~ -- ]] ; do
    if [[ "$1" == "--variable" ]] ; then
        >&2 echo "VARIABLING"
        TYPE=21
    fi
    if [[ "$1" == "--archive" ]] ; then
        >&2 echo "ARCHIVING"
        ARCHIVE=128
    fi
    shift
done

TYPE_BYTE=$(make_hex $TYPE)
VERSION_BYTE=$(make_hex $VERSION)
ARCHIVE_BYTE=$(make_hex $ARCHIVE)

INPUT_FILE="$1"
if [[ ! -e "$INPUT_FILE" ]] ; then
    >&2 echo "File doesn't exist: $INPUT_FILE"
    exit 1
fi

INPUT_FILENAME="$(basename "${INPUT_FILE%.*}")"

NAME="$(printf "%.8s" "${2:-${INPUT_FILENAME}}")"
NAME="${NAME^^}"
NAME_HEX="$(printf "%-16s" "$(echo -ne "$NAME" | xxd -ps)" | tr ' ' 0)"

COMMENT="BashPack (c)2022 EmpathicQubit            "
COMMENT_HEX=$(echo -ne "$COMMENT" | xxd -ps)

BINSIZE=$(cat "$INPUT_FILE" | wc --bytes)
BINSIZE_LITTLE=$(make_little $BINSIZE)

if ((TYPE == 23)) ; then
    VARDATA="$(cat "$INPUT_FILE" | xxd -ps)"
    VARSIZE=$((BINSIZE))
else
    VARDATA="$BINSIZE_LITTLE $(cat "$INPUT_FILE" | xxd -ps)"
    VARSIZE=$((BINSIZE+2))
fi

VARSIZE_LITTLE=$(make_little $VARSIZE)

VARRECORD_SIZE=$((VARSIZE+17))
VARRECORD_SIZE_LITTLE=$(make_little $VARRECORD_SIZE)

FILE_SUM=$({ echo -ne "$BINSIZE_LITTLE" | xxd -r -ps ; cat "$INPUT_FILE" ; } | bytesum)
NAME_SUM=$(echo -ne "$NAME" | bytesum)

VARHEADER_SIZE=13
VARHEADER_SIZE_LITTLE=$(make_little $VARHEADER_SIZE)
VARHEADER_SIZE_LO=$((VARHEADER_SIZE & 0xff))
VARHEADER_SIZE_HI=$((VARHEADER_SIZE >> 8))

VARSIZE_LO=$((VARSIZE & 0xff))
VARSIZE_HI=$((VARSIZE >> 8))

HEADER_SUM=$((2*VARSIZE_LO + 2*VARSIZE_HI + TYPE + VERSION + ARCHIVE + VARHEADER_SIZE_LO + VARHEADER_SIZE_HI))

SUM=$(((HEADER_SUM + NAME_SUM + FILE_SUM) % 65536))
SUM_LITTLE=$(make_little $SUM)

FILE_HEADER="$(echo -ne "**TI83F*" | xxd -ps)"

cat <<HERE | xxd -r -ps
$FILE_HEADER
1A 0A 00
$COMMENT_HEX
$VARRECORD_SIZE_LITTLE

$VARHEADER_SIZE_LITTLE
$VARSIZE_LITTLE
$TYPE_BYTE
$NAME_HEX
$VERSION_BYTE $ARCHIVE_BYTE
$VARSIZE_LITTLE
$VARDATA
$SUM_LITTLE
HERE

if [[ "$NAME" =~ ^[0-9] ]] ; then
    >&2 echo
    >&2 echo "PROGRAMS BEGINNING WITH A NUMBER ARE COMPLETELY INVISIBLE TO TIOS.
YOU PROBABLY DON'T WANT THIS UNLESS YOU HAVE A CUSTOM SHELL!!!"
fi
