#!/bin/sh -x
export ACME=${USERPROFILE}/Downloads/acme0.97win/acme
export VICE=${USERPROFILE}/Downloads/GTK3VICE-3.10-win64/bin
export D64=scankeys
export PROG64=scankey64
export PROG128=scankey128
export PROG64MODE=scankey64mode
export PROGTED=scankeyted
${ACME}/acme -f cbm -o ${PROG64}.prg -l ${PROG64}.lbl -r ${PROG64}.lst ${PROG64}.asm \
&& ${VICE}/c1541 -attach ${D64}.d64 8 -delete "$scankeys 49152" -delete "${PROG64} 49152" -write ${PROG64}.prg "${PROG64} 49152" \
&& ${ACME}/acme -f cbm -o ${PROG128}.prg -l ${PROG128}.lbl -r ${PROG128}.lst ${PROG128}.asm \
&& ${VICE}/c1541 -attach ${D64}.d64 8 -delete "${PROG128} 1700" -write ${PROG128}.prg "${PROG128} 1700" \
&& ${ACME}/acme -f cbm -o ${PROG64MODE}.prg -l ${PROG64MODE}.lbl -r ${PROG64MODE}.lst ${PROG64MODE}.asm\
&& ${VICE}/c1541 -attach ${D64}.d64 8 -delete "${PROG64MODE}" -write ${PROG64MODE}.prg ${PROG64MODE} \
&& ${ACME}/acme -f cbm -o ${PROGTED}.prg -l ${PROGTED}.lbl -r ${PROGTED}.lst ${PROGTED}.asm \
&& ${VICE}/c1541 -attach ${D64}.d64 8 -delete "${PROGTED} 1202" -write ${PROGTED}.prg "${PROGTED} 1202" \
&& ${VICE}/xplus4 -moncommands ${PROG64MODE}.lbl ${D64}.d64 >/dev/null 2>&1 &
#&& ${VICE}/x64sc -moncommands ${PROG64}.lbl ${D64}.d64 >/dev/null 2>&1 &
#&& ${VICE}/x128 -moncommands ${PROG64MODE}.lbl ${D64}.d64 >/dev/null 2>&1 &
