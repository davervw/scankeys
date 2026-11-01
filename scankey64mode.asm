; scankey128on64.asm - Commodore 64 test/demo keyboard scan
; Copyright (c) 2026 by David Van Wagner ALL RIGHTS RESERVED
; MIT LICENSE
; github.com/davervw
; www.davevw.com

CIAPRA=$dc00 ; CIA#1 Data Port Register A
CIAPRB=$dc01 ; CIA#1 Data Port Register B
CIDDRA=$dc02 ; CIA#1 Data Direction Register A (controls port A lines whether in[0]/out[1])
CIDDRB=$dc03 ; CIA#1 Data Direction Register B (controls port B lines whether in[0]/out[1])
EXTKEY=$d02f ; bits 0..2 C128 keyboard control register

CHROUT=$ffd2 ; KERNAL character out

videoram=$0400
colorram=$d800
color=$286 ; 646 decimal
zvideo=$fb
zcolor=$fd
clearscreen=147
scancode=$26
found=$27
savex=$28
computedshift=$29
savescancode=$2a
shiftscancode=$2b
keycounter=$ff
curkey=$cb
shiftstate=$28d
kbdline = $02
keymap = $0000
keydecode = $028f
mapptr = $f5 ; low, and $f6 high

*=$c000
	lda #<pressakey
	ldx #>pressakey
	jsr strout
-	jsr getkbdmatrix
	lda kbdmatrix+1
	beq - ; repeat until matrix retrieved (not $00xx)
	lda #<title
	ldx #>title
	jsr strout

	; initialize I/O
	sei ; set interrupt disable and leave disabled (diallow IRQs such as scanning keyboard, but NMI [RESTORE] still works)
	ldx #$ff
	stx CIDDRA ; set port A as 8 outputs
	inx
	stx CIDDRB ; set port B as 8 inputs
	lda $00
	and #$BF ; bit 6 cleared - input for reading bit 6 of $01 (caps lock)
	sta $00
	lda #$BF ; all bits set except bit 6 (64-mode), including set bit 7 (DISP 40/80 key as input)
	sta $D505

	; draw column/row headings (reverse DC01 across, reverse DC00 down)
	lda #'D'-64+128 ; to screen code, and reverse
	ldy color
	sta videoram+4
	sty colorram+4
	sta videoram+280
	sty colorram+280
	eor #$80
	sta videoram+40
	sty colorram+40
	lda #'C'-64+128
	sta videoram+5
	sty colorram+5
	sta videoram+320
	sty colorram+320
	lda #'0'+128
	sta videoram+6
	sty colorram+6
	sta videoram+360
	sty colorram+360
	sta videoram+400
	sty colorram+400
	eor #$80
	sta videoram+80
	sty colorram+80
	lda #'1'+128
	sta videoram+7
	sty colorram+7
	lda #'2'
	sta videoram+120
	sty colorram+120
	lda #'F'-64
	sta videoram+160
	sty colorram+160

	; draw bit numbers 7..0 across, 0..7 down
	ldy #42 ; second screen row, third column for heading
	lda #'7'
-	sta videoram,y
	pha
	lda color
	sta colorram,y
	iny
	pla
	sec
	sbc #1
	cmp #'0'-1 ; out of digits?
	bne - ; branch if more digits
	ldx #'0' ; row heading
	ldy color
	stx videoram+201
	sty colorram+201
	inx
	stx videoram+241
	sty colorram+241
	inx
	stx videoram+281
	sty colorram+281
	inx
	stx videoram+321
	sty colorram+321
	inx
	stx videoram+361
	sty colorram+361
	inx
	stx videoram+401
	sty colorram+401
	inx
	stx videoram+441
	sty colorram+441
	inx
	stx videoram+481
	sty colorram+481
	ldx #'0'+128
	stx videoram+81
	sty colorram+81
	inx
	stx videoram+121
	sty colorram+121
	inx
	stx videoram+161
	sty colorram+161

	ldx #'I'-64
	stx videoram+571
	sty colorram+571
	ldx #'N'-64
	stx videoram+572
	sty colorram+572
	ldx #'D'-64
	stx videoram+573
	sty colorram+573
	ldx #'E'-64
	stx videoram+574
	sty colorram+574
	ldx #'X'-64
	stx videoram+575
	sty colorram+575

	ldx #'K'-64
	stx videoram+651
	sty colorram+651
	ldx #'E'-64
	stx videoram+652
	sty colorram+652
	ldx #'Y'-64
	stx videoram+653
	sty colorram+653

	ldx #'S'-64
	stx videoram+731
	sty colorram+731
	ldx #'H'-64
	stx videoram+732
	sty colorram+732
	ldx #'I'-64
	stx videoram+733
	sty colorram+733
	ldx #'F'-64
	stx videoram+734
	sty colorram+734
	ldx #'T'-64
	stx videoram+735
	sty colorram+735

--- lda #<(videoram+82)
	sta zvideo
	sta zcolor
	lda #>(videoram+82)
	sta zvideo+1
	lda #>(colorram+82)
	sta zcolor+1

	; initialize scancode variables
	lda #87
	sta keycounter ; count for scan codes
	sta found
	lda #88
	sta scancode
	sta shiftscancode
	lda #0
	bit $01
	bvs +
	lda #16
+   sta computedshift

	ldx #0
	stx kbdline
--	ldx kbdline
	lda scanline1, x
	sta CIAPRA ; output keyboard scanline
	lda scanline2, x
	sta EXTKEY
	ldx CIAPRB ; read keys pressed
	txa ; code expects in both A and X
	ldy #0 ; count number of columns
-	asl ; shift keys into carry one by one
	pha ; save keys
	lda #' ' ; not pressed
	bcs +
	lda keycounter
	jsr checkifshift
	beq +
    sta scancode
	sec
	ror found ; mark found
alreadyfound:	
	jsr lookupkey
+   sta (zvideo),y ; videoram pointer for key
	lda color
	sta (zcolor),y ; colorram pointer for key
	pla ; restore keys
	dec keycounter
	iny
	cpy #8 ; completed the row?
	bne - ; branch if more on row

	inc kbdline
	lda kbdline
	cmp #11
	bcs ++ ; branch if done

	clc
	lda zvideo
	adc #40 ; columns on screen, advance to next line
	sta zvideo
	bcc +
	inc zvideo+1
+	clc
	lda zcolor
	adc #40 ; columns on screen, advance to next line
	sta zcolor
	bcc +
	inc zcolor+1
+	jmp --
++	lda scancode
	cmp #88
	bne +
	lda shiftscancode
	sta scancode ; want to display a scan code even if just shift pressed, overwrite with the last shift scan code
+   lsr
	lsr
	lsr
	lsr
	ora #$B0 ; reverse zero
	cmp #$BA ; out of bounds for numeric?
	bcc + ; branch if okay
	adc #$C6 ; convert to A..F
+   sta videoram+563
	lda color	
	sta colorram+562
	sta colorram+563
	sta colorram+564
	lda #'$'
	sta videoram+562
	lda scancode
	and #$0F
	ora #$B0
	cmp #$BA
	bcc +
	adc #$C6
+	sta videoram+564
	lda #'#'
	sta videoram+567
	lda scancode
	jsr div10
	ora #$B0 ; convert to inverse digit
	sta videoram+569
	txa
	ora #$B0 ; convert to inverse digit
	sta videoram+568
	ldy color
	sty colorram+567
	sty colorram+568
	sty colorram+569

	jsr lookupascii
	lsr
	lsr
	lsr
	lsr
	ora #$B0 ; reverse zero
	cmp #$BA ; out of bounds for numeric?
	bcc + ; branch if okay
	adc #$C6 ; convert to A..F
+   sta videoram+643
	lda color	
	sta colorram+642
	sta colorram+643
	sta colorram+644
	lda #'$'
	sta videoram+642
	jsr lookupascii
	and #$0F
	ora #$B0
	cmp #$BA
	bcc +
	adc #$C6
+	sta videoram+644
	lda #'#'
	sta videoram+646
	jsr lookupascii
	jsr div10
	ora #$B0 ; convert to inverse digit
	sta videoram+649
	txa
	jsr div10
	ora #$B0 ; convert to inverse digit
	sta videoram+648
	txa
	ora #$B0 ; convert to inverse digit
	sta videoram+647
	ldy color
	sty colorram+646
	sty colorram+647
	sty colorram+648
	sty colorram+649

	lda computedshift
	lsr
	pha
	lda #$00
	adc #$B0 ; convert C to inverse digit
	sta videoram+725
	pla
	lsr
	pha
	lda #$00
	adc #$B0 ; convert C to inverse digit
	sta videoram+724
	pla
	lsr
	pha
	lda #$00
	adc #$B0 ; convert C to inverse digit
	sta videoram+723
	pla
	lsr
	pha
	lda #$00
	adc #$B0 ; convert C to inverse digit
	sta videoram+722
	pla
	lsr
	lda #$00
	adc #$B0 ; convert C to inverse digit
	sta videoram+721
	lda #'%'
    sta videoram+720
	sty colorram+720
	sty colorram+721
	sty colorram+722
	sty colorram+723
	sty colorram+724
	sty colorram+725

	lda computedshift
	jsr div10
	ora #$B0 ; convert to inverse digit
	sta videoram+729
	sty colorram+729
	txa
	ora #$B0 ; convert to inverse digit
	sta videoram+728
	sty colorram+728
	lda #'#'
	sta videoram+727
	sty colorram+727

	bit $01
	bvs +
	lda #'0'+128
	sta videoram + 15
	sty colorram + 15
	sta videoram + 16
	sty colorram + 16
	sta videoram + 17
	sty colorram + 17
	lda #'1'+128
	sta videoram + 18
	sty colorram + 18
	lda #':'
	sta videoram + 19
	sty colorram + 19
	lda #'6'
	sta videoram + 20
	sty colorram + 20
	lda #'C'-64
    sta videoram + 22
	sty colorram + 22
	lda #'A'-64
	sta videoram + 23
	sty colorram + 23
	lda #'P'-64
	sta videoram + 24
	sty colorram + 24
	lda #'S'-64
	sta videoram + 25
	sty colorram + 25
	jmp ++
+	lda #' '
	sta videoram + 22
	sty colorram + 22
	sta videoram + 23
	sty colorram + 23
	sta videoram + 24
	sty colorram + 24
    sta videoram + 25
	sty colorram + 25
++	jmp ---

checkifshift:
    stx savex
	ldx scancode
	stx savescancode
	sta scancode
	jsr lookupascii
	cmp #1
	beq +
	cmp #2
	beq +
	cmp #4
	beq +
	cmp #8
	beq +
	cmp #16
	bne ++
+	php ; save Z set
	ora computedshift
    sta computedshift
	lda scancode
	sta shiftscancode
	jsr lookupkey
	jmp +++
++  php ; save Z clear
    lda keycounter
+++	ldx savescancode
	stx scancode
    ldx savex
	plp ; restore Z
	rts

lookupascii:
	lda scancode
	sec
	sbc #64
	bcc +
	tax
	lda extrakeys, x
	jmp ++
+   ldx scancode
kbdmatrix=*+1
	lda keymap, x
++  rts

lookupkey:
	stx savex
	jsr lookupascii
++  cmp #$20
	bcs +
	cmp #1
	bne +
	lda #$9E ; Reverse up arrow
	bne ++
+	cmp #2
	bne +
	lda #'='+128
	bne ++
+	cmp #4
	bne +
	lda #$5F ; upper right triangle shape
	bne ++
+	cmp #$20
	bne +
	lda #$A0
	bne ++
+	bcs +
	ora #$80
	bne ++
+	cmp #$80
	bcc +
	ora #$40
	bne ++
+	cmp #$40
	bcc ++
	eor #$40	
++	ldx savex
	rts
div10: ; take A and divide by 10, remainder in A, answer in X
	ldx #0
-	cmp #10
	bcc +
	sbc #10
	inx
	bne -
+	rts
strout:
	sta $fb
	stx $fc
	ldy #0
-	lda ($fb),y
	beq +
	jsr CHROUT
	iny
	bne -
+	rts
getkbdmatrix:
	sei
	lda shiftstate
	pha
	lda curkey
	pha
	lda #0
	sta shiftstate
	lda #88
	sta curkey
	jsr getmap
	ldx mapptr
	ldy mapptr+1
	stx kbdmatrix
	sty kbdmatrix+1
	pla
	sta curkey
	pla
	sta shiftstate
	cli
	rts
getmap:
	jmp (keydecode)

scanline1: !byte $ff, $ff, $ff, $7f, $bf, $df, $ef, $f7, $fb, $fd, $fe
scanline2: !byte $fb, $fd, $fe, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff

title: 
	!byte 147
	!byte 17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17
	!text 18,"SCANKEY 64 MODE   (C) 2026    DAVEVW.COM"
	!text 18,"BY DAVID R VAN WAGNER GITHUB.COM/DAVERVW"
	!text 145,145,145,13,157,148,32
	!byte 0

extrakeys: ; scan codes 64 to 88
	                                             ; bit 01234567
	!byte 132, '8', '5',   9, '2', '4', '7', '1' ; 0:  H85I2471
	!byte  27, '+', '-',  10,  13, '6', '9', '3' ; 1:  [+-JM693
	!byte   8, '0', '.', 145,  17, 157,  29, 255 ; 2:  A0.UDLRS
	!byte 255

pressakey:
	!text "PRESS A KEY", 0