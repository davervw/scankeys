#!/bin/sh -x
export ACME=${USERPROFILE}/Downloads/acme0.97win/acme
export VICE=${USERPROFILE}/Downloads/GTK3VICE-3.10-win64/bin
export D64=scankeys
export PROG64=scankey64
export PROG128=scankey128
${ACME}/acme -f cbm -o ${PROG64}.prg -l ${PROG64}.lbl -r ${PROG64}.lst ${PROG64}.asm \
&& ${VICE}/c1541 -attach ${D64}.d64 8 -delete "$scankeys 49152" -delete "${PROG64} 49152" -write ${PROG64}.prg "${PROG64} 49152" \
&& ${ACME}/acme -f cbm -o ${PROG128}.prg -l ${PROG128}.lbl -r ${PROG128}.lst ${PROG128}.asm \
&& ${VICE}/c1541 -attach ${D64}.d64 8 -delete "${PROG128} 1300" -write ${PROG128}.prg "${PROG128} 1300" \
&& ${VICE}/x128 -moncommands ${PROG128}.lbl ${D64}.d64 >/dev/null 2>&1 &
#&& ${VICE}/x64sc -moncommands ${PROG64}.lbl ${D64}.d64 >/dev/null 2>&1 &
