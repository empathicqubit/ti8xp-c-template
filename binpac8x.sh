#! /bin/bash
function make_little { 
    printf "%04x" "$1" | fold -w2 | tac | tr -d "\n"
}

function bytesum {
    {
        echo 'echo $(('
        xxd -i | tr , +
        echo '))'
    } | source /dev/stdin
}

INPUT_FILE="$1"

NAME="$(printf "%.8s" "${2:-${INPUT_FILE}}")"
NAME="${NAME^^}"
NAME_HEX="$(printf "%-16s" "$(echo -ne "$NAME" | xxd -ps)" | tr ' ' 0)"

COMMENT="MakePack (c)2022 EmpathicQubit            "
COMMENT_HEX=$(echo -ne "$COMMENT" | xxd -ps)

BINSIZE=$(cat "$INPUT_FILE" | wc --bytes)
BINSIZE_LITTLE=$(make_little $BINSIZE)

BINSIZE2=$((BINSIZE+2))
BINSIZE2_LITTLE=$(make_little $BINSIZE2)

BINSIZE19=$((BINSIZE2+17))
BINSIZE19_LITTLE=$(make_little $BINSIZE19)

FILE_SUM=$({ echo -ne "$BINSIZE_LITTLE" | xxd -r -ps ; cat "$INPUT_FILE" ; } | bytesum)
NAME_SUM=$(echo -ne "$NAME" | bytesum)

BINSIZE2_LO=$((BINSIZE2 & 0xff))
BINSIZE2_HI=$((BINSIZE2 >> 8))

HEADER_SUM=$((2*BINSIZE2_LO + 2*BINSIZE2_HI + 6 + 0 + 0 + 13 + 0))

SUM=$(((HEADER_SUM + NAME_SUM + FILE_SUM) % 65536))
SUM_LITTLE=$(make_little $SUM)

cat <<HERE | xxd -r -ps
2A 2A 54 49 38 33 46 2A
1A 0A 00
$COMMENT_HEX
$BINSIZE19_LITTLE
0D 00
$BINSIZE2_LITTLE
06
$NAME_HEX
00 00
$BINSIZE2_LITTLE
$BINSIZE_LITTLE
$(cat "$INPUT_FILE" | xxd -ps)
$SUM_LITTLE
HERE