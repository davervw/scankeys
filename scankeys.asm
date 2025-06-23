; scankeys.asm - Commodore 64 test/demo keyboard scan
; Copyright (c) 2023, 2024, 2025 by David Van Wagner ALL RIGHTS RESERVED
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
keycounter=$ff
curkey=$cb
shiftstate=$28d

*=$c000
	jsr getkbdmatrix
	lda #<title
	ldx #>title
	jsr strout
	sei
	ldx #$ff
	stx CIDDRA ; set port A as 8 outputs
	inx
	stx CIDDRB ; set port B as 8 inputs

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
	lsr
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
	sta videoram+446
	lda scancode
	jsr div10
	ora #$B0 ; convert to inverse digit
	sta videoram+448
	txa
	ora #$B0 ; convert to inverse digit
	sta videoram+447
	ldy color
	sty colorram+446
	sty colorram+447
	sty colorram+448
	jmp ---
lookupkey:
	stx savex
	ldx keycounter
kbdmatrix=*+1
	lda $eb81, x
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
	!text 18,"SCANKEYS (C) 2025     GITHUB.COM/DAVERVW"
	!text 157,157,17,18,32,157,148,32,157,145,145,13,17
	!text 18,"BY DAVID R. VAN WAGNER       DAVEVW.COM"
	!byte 0