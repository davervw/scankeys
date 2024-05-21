.C:c000  78          SEI
.C:c001  A2 FF       LDX #$FF
.C:c003  8E 02 DC    STX $DC02
.C:c006  E8          INX
.C:c007  8E 03 DC    STX $DC03
.C:c00a  A0 01       LDY #$01
.C:c00c  A9 37       LDA #$37
.C:c00e  99 00 04    STA $0400,Y
.C:c011  48          PHA
.C:c012  A9 0E       LDA #$0E
.C:c014  99 00 D8    STA $D800,Y
.C:c017  C8          INY
.C:c018  68          PLA
.C:c019  38          SEC
.C:c01a  E9 01       SBC #$01
.C:c01c  C9 2F       CMP #$2F
.C:c01e  D0 EE       BNE $C00E
.C:c020  A2 30       LDX #$30
.C:c022  A0 0E       LDY #$0E
.C:c024  8E 28 04    STX $0428
.C:c027  8C 28 D8    STY $D828
.C:c02a  E8          INX
.C:c02b  8E 50 04    STX $0450
.C:c02e  8C 50 D8    STY $D850
.C:c031  E8          INX
.C:c032  8E 78 04    STX $0478
.C:c035  8C 78 D8    STY $D878
.C:c038  E8          INX
.C:c039  8E A0 04    STX $04A0
.C:c03c  8C A0 D8    STY $D8A0
.C:c03f  E8          INX
.C:c040  8E C8 04    STX $04C8
.C:c043  8C C8 D8    STY $D8C8
.C:c046  E8          INX
.C:c047  8E F0 04    STX $04F0
.C:c04a  8C F0 D8    STY $D8F0
.C:c04d  E8          INX
.C:c04e  8E 18 05    STX $0518
.C:c051  8C 18 D9    STY $D918
.C:c054  E8          INX
.C:c055  8E 40 05    STX $0540
.C:c058  8C 40 D9    STY $D940
.C:c05b  A9 29       LDA #$29
.C:c05d  85 FB       STA $FB
.C:c05f  85 FD       STA $FD
.C:c061  A9 04       LDA #$04
.C:c063  85 FC       STA $FC
.C:c065  A9 D8       LDA #$D8
.C:c067  85 FE       STA $FE
.C:c069  A9 FE       LDA #$FE
.C:c06b  A0 00       LDY #$00
.C:c06d  8D 00 DC    STA $DC00
.C:c070  AE 01 DC    LDX $DC01
.C:c073  48          PHA
.C:c074  8A          TXA
.C:c075  0A          ASL A
.C:c076  48          PHA
.C:c077  A9 2A       LDA #$2A
.C:c079  90 02       BCC $C07D
.C:c07b  A9 20       LDA #$20
.C:c07d  91 FB       STA ($FB),Y
.C:c07f  A9 0E       LDA #$0E
.C:c081  91 FD       STA ($FD),Y
.C:c083  68          PLA
.C:c084  C8          INY
.C:c085  C0 08       CPY #$08
.C:c087  D0 EC       BNE $C075
.C:c089  68          PLA
.C:c08a  38          SEC
.C:c08b  2A          ROL A
.C:c08c  C9 FF       CMP #$FF
.C:c08e  F0 CB       BEQ $C05B
.C:c090  48          PHA
.C:c091  18          CLC
.C:c092  A5 FB       LDA $FB
.C:c094  69 28       ADC #$28
.C:c096  85 FB       STA $FB
.C:c098  90 02       BCC $C09C
.C:c09a  E6 FC       INC $FC
.C:c09c  18          CLC
.C:c09d  A5 FD       LDA $FD
.C:c09f  69 28       ADC #$28
.C:c0a1  85 FD       STA $FD
.C:c0a3  90 02       BCC $C0A7
.C:c0a5  E6 FE       INC $FE
.C:c0a7  68          PLA
.C:c0a8  4C 6B C0    JMP $C06B
