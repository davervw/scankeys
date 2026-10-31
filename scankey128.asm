; scankeys.asm - Commodore 64 test/demo keyboard scan
; Copyright (c) 2023, 2024, 2025 by David Van Wagner ALL RIGHTS RESERVED
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
color=$f1 ; 241 decimal
kbdline=$61 ; 0..10 ($0..$a)
scancode=$fa
zvideo=$fb
zcolor=$fd
clearscreen=147
found=$ac
savex=$ae
keycounter=$ff
curkey=$d0
shiftstate=$d1
keydecode=$033c
keymap=$d000

*=$1300
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
	; bit found
	; bmi alreadyfound
	lda keycounter
	sta scancode
	sec
	ror found ; mark found
alreadyfound:	
	jsr lookupkey
+	sta (zvideo),y ; videoram pointer for key
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
	lsr
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
	sta videoram+566
	lda scancode
	jsr div10
	ora #$B0 ; convert to inverse digit
	sta videoram+568
	txa
	ora #$B0 ; convert to inverse digit
	sta videoram+567
	ldy color
	sty colorram+566
	sty colorram+567
	sty colorram+568

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
++	bit $d505
	bmi +
	lda #'D'-64+128
	sta videoram + 55
	sty colorram + 55
	lda #'5'+128
	sta videoram + 56
	sty colorram + 56
	lda #'0'+128
	sta videoram + 57
	sty colorram + 57
	lda #'5'+128
	sta videoram + 58
	sty colorram + 58
	lda #':'
	sta videoram + 59
	sty colorram + 59
	lda #'7'
	sta videoram + 60
	sty colorram + 60
	lda #'D'-64
    sta videoram + 62
	sty colorram + 62
	lda #'I'-64
	sta videoram + 63
	sty colorram + 63
	lda #'S'-64
	sta videoram + 64
	sty colorram + 64
	lda #'P'-64
	sta videoram + 65
	sty colorram + 65
	jmp ++
+	lda #' '
    sta videoram + 62
	sty colorram + 62
	sta videoram + 63
	sty colorram + 63
	sta videoram + 64
	sty colorram + 64
	sta videoram + 65
	sty colorram + 65
++	jmp ---

lookupkey:
	stx savex
	ldx keycounter
kbdmatrix=*+1
	lda keymap, x
	cmp #$20
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
	ldx $cc
	ldy $cd
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
	!text 18,"SCANKEY128 (C) 2026   GITHUB.COM/DAVERVW"
	!text 145,13
	!text 18,"BY DAVID R. VAN WAGNER       DAVEVW.COM"
	!text 157,157,157,157,157,157,157,157,157,157,148,32
	!byte 0

pressakey:
	!text "PRESS A KEY", 0