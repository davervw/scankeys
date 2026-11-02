; scankeys.asm - Commodore 64 test/demo keyboard scan
; Copyright (c) 2026 by David Van Wagner ALL RIGHTS RESERVED
; MIT LICENSE
; github.com/davervw
; www.davevw.com

CIAPRA=$dc00 ; CIA#1 Data Port Register A
CIAPRB=$dc01 ; CIA#1 Data Port Register B
CIDDRA=$dc02 ; CIA#1 Data Direction Register A (controls port A lines whether in[0]/out[1])
CIDDRB=$dc03 ; CIA#1 Data Direction Register B (controls port B lines whether in[0]/out[1])

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

	; draw column/row headings (reverse DC01 across, reverse DC00 down)
	lda #'D'-64+128 ; to screen code, and reverse
	ldy color
	sta videoram+4
	sty colorram+4
	sta videoram+160
	sty colorram+160
	lda #'C'-64+128
	sta videoram+5
	sty colorram+5
	sta videoram+200
	sty colorram+200
	lda #'0'+128
	sta videoram+6
	sty colorram+6
	sta videoram+240
	sty colorram+240
	sta videoram+280
	sty colorram+280
	lda #'1'+128
	sta videoram+7
	sty colorram+7

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
	stx videoram+81
	sty colorram+81
	inx
	stx videoram+121
	sty colorram+121
	inx
	stx videoram+161
	sty colorram+161
	inx
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

	ldx #'I'-64
	stx videoram+451
	sty colorram+451
	ldx #'N'-64
	stx videoram+452
	sty colorram+452
	ldx #'D'-64
	stx videoram+453
	sty colorram+453
	ldx #'E'-64
	stx videoram+454
	sty colorram+454
	ldx #'X'-64
	stx videoram+455
	sty colorram+455

	ldx #'K'-64
	stx videoram+531
	sty colorram+531
	ldx #'E'-64
	stx videoram+532
	sty colorram+532
	ldx #'Y'-64
	stx videoram+533
	sty colorram+533

	ldx #'S'-64
	stx videoram+611
	sty colorram+611
	ldx #'H'-64
	stx videoram+612
	sty colorram+612
	ldx #'I'-64
	stx videoram+613
	sty colorram+613
	ldx #'F'-64
	stx videoram+614
	sty colorram+614
	ldx #'T'-64
	stx videoram+615
	sty colorram+615

--- lda #<(videoram+82)
	sta zvideo
	sta zcolor
	lda #>(videoram+82)
	sta zvideo+1
	lda #>(colorram+82)
	sta zcolor+1

	; initialize scancode variables
	lda #63
	sta keycounter ; count for scan codes
	sta found
	lda #64
	sta scancode
	sta shiftscancode
	lda #0
	sta computedshift

	lda #$7F ; start with bit 7 grounded
--	ldy #0 ; count number of scanlines
	sta CIAPRA ; output keyboard scanline
	ldx CIAPRB ; read keys pressed
	pha ; save scanline
	txa
-	asl ; shift keys into carry one by one
	pha ; save keys
	lda #' ' ; not pressed
	bcs +
	; bit found
	; bmi alreadyfound
	lda keycounter
	jsr checkifshift
	beq +
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
	pla ; restore scanline
	sec
	ror ; inject bit while shifting
	cmp #$ff ; check for all bits set
	beq ++ ; branch if done
	pha ; save scanline
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
+	pla ; restore scanline
	jmp --

++	lda scancode
	cmp #64
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
+   sta videoram+443
	lda color	
	sta colorram+442
	sta colorram+443
	sta colorram+444
	lda #'$'
	sta videoram+442
	lda scancode
	and #$0F
	ora #$B0
	cmp #$BA
	bcc +
	adc #$C6
+	sta videoram+444
	lda #'#'
	sta videoram+447
	lda scancode
	jsr div10
	ora #$B0 ; convert to inverse digit
	sta videoram+449
	txa
	ora #$B0 ; convert to inverse digit
	sta videoram+448
	ldy color
	sty colorram+447
	sty colorram+448
	sty colorram+449

	jsr lookupascii
	pha
	lsr
	lsr
	lsr
	lsr
	ora #$B0 ; reverse zero
	cmp #$BA ; out of bounds for numeric?
	bcc + ; branch if okay
	adc #$C6 ; convert to A..F
+   sta videoram+523
	lda color	
	sta colorram+522
	sta colorram+523
	sta colorram+524
	lda #'$'
	sta videoram+522
	pla
	and #$0F
	ora #$B0
	cmp #$BA
	bcc +
	adc #$C6
+	sta videoram+524
	lda #'#'
	sta videoram+526
	jsr lookupascii
	jsr div10
	ora #$B0 ; convert to inverse digit
	sta videoram+529
	txa
	jsr div10
	ora #$B0 ; convert to inverse digit
	sta videoram+528
	txa
	ora #$B0 ; convert to inverse digit
	sta videoram+527
	ldy color
	sty colorram+526
	sty colorram+527
	sty colorram+528
	sty colorram+529

	lda computedshift
	lsr
	pha
	lda #$00
	adc #$B0 ; convert C to inverse digit
	sta videoram+605
	pla
	lsr
	pha
	lda #$00
	adc #$B0 ; convert C to inverse digit
	sta videoram+604
	pla
	lsr
	lda #$00
	adc #$B0 ; convert C to inverse digit
	sta videoram+603
	lda #'%'
    sta videoram+602
	sty colorram+602
	sty colorram+603
	sty colorram+604
	sty colorram+605

	lda computedshift
	jsr div10
	ora #$B0 ; convert to inverse digit
	sta videoram+609
	sty colorram+609
	lda #'#'
	sta videoram+608
	sty colorram+608

	jmp ---
	
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
    ldx scancode
kbdmatrix=*+1
	lda keymap, x
	rts

lookupkey:
	stx savex
	jsr lookupascii
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
	lda #$40
	sta curkey
	jsr getmap
	ldx $f5
	ldy $f6
	stx kbdmatrix
	sty kbdmatrix+1
	pla
	sta curkey
	pla
	sta shiftstate
	cli
	rts

getmap:
	jmp ($028f)

title: 
	!byte 147
	!byte 17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17,17
	!text 18,"SCANKEYS (C) 2026     GITHUB.COM/DAVERVW"
	!text 157,157,17,18,32,157,148,32,157,145,145,13,17
	!text 18,"BY DAVID R. VAN WAGNER       DAVEVW.COM"
	!byte 0

pressakey:
	!text "PRESS A KEY", 0