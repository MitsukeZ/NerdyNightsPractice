  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring
  

;;;;;;;;;;;;;;;

    
  .bank 0
  .org $C000 
RESET:
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs

vblankwait1:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait1

clrmem:
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0300, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0200, x    ;move all sprites off screen
  INX
  BNE clrmem
   
vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2

loadPalettes:
  LDA $2002    ; read PPU status to reset the high/low latch to high
  LDA #$3F
  STA $2006    ; write the high byte of $3F10 address
  LDA #$00
  STA $2006    ; write the low byte of $3F10 address
  LDX #$00
paletteLoop:
  LDA palette, x
  STA $2007
  INX
  CPX #$20
  BNE paletteLoop


;Enable NMI 
  LDA #%10000000   ; enable NMI, sprites from Pattern Table 0
  STA $2000

;Enable Sprites
  LDA #%00010000   ; no intensify (black background), enable sprites
  STA $2001

;Sprite Data
; $0200 - Y Pos
; $0201 - Tile Number
; $0202 - Attributes (check nerdy nights)
; $0203 - X Pos

 

loadGoombaPart:
  ;YPos
  LDA #$80
  STA $0200
  STA $0204
  LDA #$88
  STA $0208
  STA $020C
       
  ;xPos
  LDA #$08
  STA $0203
  STA $020B
  LDA #$10
  STA $0207
  STA $020F 
  ;Tile Number
  LDA #$70
  STA $0201
  LDA #$71
  STA $0205
  LDA #$72
  STA $0209
  LDA #$73
  STA $020D 
  ;Attributes
  LDA #%00000010
  STA $0202
  STA $0206
  STA $020A
  STA $020E


Forever:
  LDX #$00
  JSR moveGoomba
  JSR vblankwait
  JMP Forever     ;jump back to Forever, infinite loop
  
vblankwait:      ; wait for vblank
  BIT $2002
  BPL vblankwait
  RTS

moveGoomba:
  ;Move Goomba
  CLC
  LDA $0203, x
  ADC #$02
  STA $0203, x
  ;Check if all sprites have been moved
  CLC
  TXA
  ADC #$04
  TAX
  CPX #$10
  BNE moveGoomba
  RTS
  

NMI:
  LDA #$00
  STA $2003  ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014  ; set the high byte (02) of the RAM address, start the transfer
  RTI        ; return from interrupt
 
;;;;;;;;;;;;;;  
  
  	
  .bank 1
  .org $E000
palette:
  .db $0F,$0F,$0F,$0F, $0F,$0F,$0F,$0F, $0F,$0F,$0F,$0F, $0F,$0F,$0F,$0F ;bg palette
  .db $0f,$00,$10,$30, $0f,$01,$21,$31, $0f,$06,$26,$16, $0f,$02,$22,$12 ;sprite palette
    

  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the 
                   ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used in this tutorial
  
  
;;;;;;;;;;;;;;  
  
  
  .bank 2
  .org $0000
  .incbin "mario.chr"   ;includes 8KB graphics file from SMB1