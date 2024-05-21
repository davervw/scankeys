; scankeys.asm - Commodore 64 test/demo keyboard scan
; Copyright (c) 2023, 2024 by David Van Wagner ALL RIGHTS RESERVED
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

*=$c000
	lda #clearscreen
	jsr CHROUT
	sei
	ldx #$ff
	stx CIDDRA ; set port A as 8 outputs
	inx
	stx CIDDRB ; set port B as 8 inputs
	ldy #1 ; first screen row, second column for heading
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
	stx videoram+40
	sty colorram+40
	inx
	stx videoram+80
	sty colorram+80
	inx
	stx videoram+120
	sty colorram+120
	inx
	stx videoram+160
	sty colorram+160
	inx
	stx videoram+200
	sty colorram+200
	inx
	stx videoram+240
	sty colorram+240
	inx
	stx videoram+280
	sty colorram+280
	inx
	stx videoram+320
	sty colorram+320
--- lda #<(videoram+41)
	sta zvideo
	sta zcolor
	lda #>(videoram+41)
	sta zvideo+1
	lda #>(colorram+41)
	sta zcolor+1
	lda #$fe ; start with bit 1 grounded
--	ldy #$00 ; counter
	sta CIAPRA ; output keyboard scanline
	ldx CIAPRB ; read keys pressed
	pha ; save scanline
	txa
-	asl ; shift keys into carry one by one
	pha ; save keys
	lda #'*' ; pressed
	bcc +
	lda #' ' ; not pressed
+	sta (zvideo),y ; videoram pointer for key
	lda color
	sta (zcolor),y ; colorram pointer for key
	pla ; restore keys
	iny
	cpy #8 ; completed the row?
	bne - ; branch if more on row
	pla ; restore scanline
	sec 
	rol ; inject bit while shifting
	cmp #$ff ; check for all bits set
	beq --- ; if done, restart scanning
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
