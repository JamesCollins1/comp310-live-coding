    .inesprg 1
    .ineschr 1
    .inesmap 0
    .inesmir 1

; ---------------------------------------------------------------------------

PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
OAMADDR   = $2003
OAMDATA   = $2004
PPUSCROLL = $2005
PPUADDR   = $2006
PPUDATA   = $2007
OAMDMA    = $4014
JOYPAD1   = $4016
JOYPAD2   = $4017

BUTTON_A      = %10000000
BUTTON_B      = %01000000
BUTTON_SELECT = %00100000
BUTTON_START  = %00010000
BUTTON_UP     = %00001000
BUTTON_DOWN   = %00000100
BUTTON_LEFT   = %00000010
BUTTON_RIGHT  = %00000001

NUM_PLAYERSPRITES = 4



BULLET_HITBOX_X      = 2 ; Relative to sprite top left corner
BULLET_HITBOX_Y      = 2
BULLET_HITBOX_WIDTH  = 2
BULLET_HITBOX_HEIGHT = 6

    .rsset $0000
joypad1_state      .rs 1
joypad2_state      .rs 1
bullet_active      .rs 1
bullet2_active     .rs 1
temp_x             .rs 1
temp_y             .rs 1
foam1_hasMoved     .rs 1    ;A flag to see whether the foam moved last turn to slow down movement. If 0 they have
foam2_hasMoved     .rs 1
foam3_hasMoved     .rs 1
foam4_hasMoved     .rs 1

    .rsset $0200
sprite_player1     .rs 4  ;4 sprites make up 1 player
sprite_player12    .rs 4
sprite_player13    .rs 4
sprite_player14    .rs 4
sprite_player2     .rs 4  ;4 sprites make up 1 player
sprite_player22    .rs 4
sprite_player23    .rs 4
sprite_player24    .rs 4
sprite_bullet      .rs 4
sprite_bullet1     .rs 4
sprite_foam1       .rs 4
sprite_foam2       .rs 4
sprite_foam3       .rs 4
sprite_foam4       .rs 4
sprite_smallIsland .rs 4 ; 1 sprite = 1 island
sprite_smallIsland2 .rs 4 ; 1 sprite = 1 island
sprite_smallIsland3 .rs 4 ; 1 sprite = 1 island
sprite_largeIsland1 .rs 4 ; 4 sprites make up one Large island
sprite_largeIsland2 .rs 4
sprite_largeIsland3 .rs 4
sprite_largeIsland4 .rs 4

    .rsset $0000
SPRITE_Y           .rs 1
SPRITE_TILE        .rs 1
SPRITE_ATTRIB      .rs 1
SPRITE_X           .rs 1

    .bank 0
    .org $C000

; Initialisation code based on https://wiki.nesdev.com/w/index.php/Init_code
RESET:
    SEI        ; ignore IRQs
    CLD        ; disable decimal mode
    LDX #$40
    STX $4017  ; disable APU frame IRQ
    LDX #$ff
    TXS        ; Set up stack
    INX        ; now X = 0
    STX PPUCTRL  ; disable NMI
    STX PPUMASK  ; disable rendering
    STX $4010  ; disable DMC IRQs

    ; Optional (omitted):
    ; Set up mapper and jmp to further init code here.

    ; If the user presses Reset during vblank, the PPU may reset
    ; with the vblank flag still true.  This has about a 1 in 13
    ; chance of happening on NTSC or 2 in 9 on PAL.  Clear the
    ; flag now so the vblankwait1 loop sees an actual vblank.
    BIT PPUSTATUS

    ; First of two waits for vertical blank to make sure that the
    ; PPU has stabilized
vblankwait1:  
    BIT PPUSTATUS
    BPL vblankwait1

    ; We now have about 30,000 cycles to burn before the PPU stabilizes.
    ; One thing we can do with this time is put RAM in a known state.
    ; Here we fill it with $00, which matches what (say) a C compiler
    ; expects for BSS.  Conveniently, X is still 0.
    TXA
clrmem:
    LDA #0
    STA $000,x
    STA $100,x
    STA $300,x
    STA $400,x
    STA $500,x
    STA $600,x
    STA $700,x  ; Remove this if you're storing reset-persistent data

    ; We skipped $200,x on purpose.  Usually, RAM page 2 is used for the
    ; display list to be copied to OAM.  OAM needs to be initialized to
    ; $EF-$FF, not 0, or you'll get a bunch of garbage sprites at (0, 0).

    LDA #$FF
    STA $200,x

    INX
    BNE clrmem

    ; Other things you can do between vblank waits are set up audio
    ; or set up other mapper registers.
   
vblankwait2:
    BIT PPUSTATUS
    BPL vblankwait2

    ; End of initialisation code
    

    JSR InitialiseGame

    LDA #%10000000 ; Enable NMI
    STA PPUCTRL

    LDA #%00010000 ; Enable sprites
    STA PPUMASK

    ; Enter an infinite loop
forever:
    JMP forever

; ---------------------------------------------------------------------------

InitialiseGame: ; Begin subroutine
    ; Reset the PPU high/low latch
    LDA PPUSTATUS

    ; Write address $3F10 (background colour) to the PPU
    LDA #$3F
    STA PPUADDR
    LDA #$10
    STA PPUADDR

    ; Write the background colour
    LDA #$11
    STA PPUDATA

    ; Write the palette colours
    LDA #$17
    STA PPUDATA
    LDA #$3D
    STA PPUDATA
    LDA #$07
    STA PPUDATA

;Secondary Palette
    LDA #$11
    STA PPUDATA
    LDA #$30
    STA PPUDATA
    LDA #$11
    STA PPUDATA
    LDA #$39
    STA PPUDATA

;Island Palette
    LDA #$11
    STA PPUDATA
    LDA #$27
    STA PPUDATA
    LDA #$07
    STA PPUDATA
    LDA #$19
    STA PPUDATA


    ; Write sprite data for Player 1
    LDA #120    ; Y position
    STA sprite_player1 + SPRITE_Y
    LDA #0      ; Tile number
    STA sprite_player1 + SPRITE_TILE
    LDA #0      ; Attributes
    STA sprite_player1 + SPRITE_ATTRIB
    LDA #30    ; X position
    STA sprite_player1 + SPRITE_X

    LDA #120    ; Y position
    STA sprite_player12 + SPRITE_Y
    LDA #1      ; Tile number
    STA sprite_player12 + SPRITE_TILE
    LDA #0      ; Attributes
    STA sprite_player12 + SPRITE_ATTRIB
    LDA #38    ; X position
    STA sprite_player12 + SPRITE_X

    LDA #128    ; Y position
    STA sprite_player13 + SPRITE_Y
    LDA #$10      ; Tile number
    STA sprite_player13 + SPRITE_TILE
    LDA #0      ; Attributes
    STA sprite_player13 + SPRITE_ATTRIB
    LDA #30    ; X position
    STA sprite_player13 + SPRITE_X

    LDA #128    ; Y position
    STA sprite_player14 + SPRITE_Y
    LDA #$11      ; Tile number
    STA sprite_player14 + SPRITE_TILE
    LDA #0      ; Attributes
    STA sprite_player14 + SPRITE_ATTRIB
    LDA #38    ; X position
    STA sprite_player14 + SPRITE_X


; Write sprite data for Player 2
    LDA #120    ; Y position
    STA sprite_player2 + SPRITE_Y
    LDA #0      ; Tile number
    STA sprite_player2 + SPRITE_TILE
    LDA #0      ; Attributes
    STA sprite_player2 + SPRITE_ATTRIB
    LDA #210    ; X position
    STA sprite_player2 + SPRITE_X

    LDA #120    ; Y position
    STA sprite_player22 + SPRITE_Y
    LDA #1      ; Tile number
    STA sprite_player22 + SPRITE_TILE
    LDA #0      ; Attributes
    STA sprite_player22 + SPRITE_ATTRIB
    LDA #218   ; X position
    STA sprite_player22 + SPRITE_X

    LDA #128    ; Y position
    STA sprite_player23 + SPRITE_Y
    LDA #$10    ; Tile number
    STA sprite_player23 + SPRITE_TILE
    LDA #0      ; Attributes
    STA sprite_player23 + SPRITE_ATTRIB
    LDA #210    ; X position
    STA sprite_player23 + SPRITE_X

    LDA #128    ; Y position
    STA sprite_player24 + SPRITE_Y
    LDA #$11      ; Tile number
    STA sprite_player24 + SPRITE_TILE
    LDA #0      ; Attributes
    STA sprite_player24 + SPRITE_ATTRIB
    LDA #218   ; X position
    STA sprite_player24 + SPRITE_X

; Initialise the waves
    LDA #115  ; Y Position
    STA sprite_foam1 + SPRITE_Y
    LDA #$03  ; Tile Number
    STA sprite_foam1 + SPRITE_TILE
    LDA #1   ; Attributes
    STA sprite_foam1 + SPRITE_ATTRIB
    LDA #140  ; X Position
    STA sprite_foam1 + SPRITE_X

    LDA #20  ; Y Position
    STA sprite_foam2 + SPRITE_Y
    LDA #$03  ; Tile Number
    STA sprite_foam2 + SPRITE_TILE
    LDA #1   ; Attributes
    STA sprite_foam2 + SPRITE_ATTRIB
    LDA #200  ; X Position
    STA sprite_foam2 + SPRITE_X

    LDA #60  ; Y Position
    STA sprite_foam3 + SPRITE_Y
    LDA #$03  ; Tile Number
    STA sprite_foam3 + SPRITE_TILE
    LDA #1   ; Attributes
    STA sprite_foam3 + SPRITE_ATTRIB
    LDA #75  ; X Position
    STA sprite_foam3 + SPRITE_X

    LDA #200  ; Y Position
    STA sprite_foam4 + SPRITE_Y
    LDA #$03  ; Tile Number
    STA sprite_foam4 + SPRITE_TILE
    LDA #1   ; Attributes
    STA sprite_foam4 + SPRITE_ATTRIB
    LDA #20  ; X Position
    STA sprite_foam4 + SPRITE_X

; Initialising the islands

    LDA #120
    STA sprite_smallIsland + SPRITE_Y
    LDA #$04
    STA sprite_smallIsland + SPRITE_TILE
    LDA #2
    STA sprite_smallIsland + SPRITE_ATTRIB
    LDA #50
    STA sprite_smallIsland + SPRITE_X

    LDA #120
    STA sprite_smallIsland2 + SPRITE_Y
    LDA #$04
    STA sprite_smallIsland2 + SPRITE_TILE
    LDA #2
    STA sprite_smallIsland2 + SPRITE_ATTRIB
    LDA #66
    STA sprite_smallIsland2 + SPRITE_X

    LDA #112
    STA sprite_smallIsland3 + SPRITE_Y
    LDA #$04
    STA sprite_smallIsland3 + SPRITE_TILE
    LDA #2
    STA sprite_smallIsland3 + SPRITE_ATTRIB
    LDA #58
    STA sprite_smallIsland3 + SPRITE_X

    ;Large island

    LDA #90
    STA sprite_largeIsland1 + SPRITE_Y
    LDA #$05
    STA sprite_largeIsland1 + SPRITE_TILE
    LDA #2
    STA sprite_largeIsland1 + SPRITE_ATTRIB
    LDA #180
    STA sprite_largeIsland1 + SPRITE_X

    LDA #90
    STA sprite_largeIsland2 + SPRITE_Y
    LDA #$06
    STA sprite_largeIsland2 + SPRITE_TILE
    LDA #2
    STA sprite_largeIsland2 + SPRITE_ATTRIB
    LDA #188
    STA sprite_largeIsland2 + SPRITE_X

    LDA #98
    STA sprite_largeIsland3 + SPRITE_Y
    LDA #$15
    STA sprite_largeIsland3 + SPRITE_TILE
    LDA #2
    STA sprite_largeIsland3 + SPRITE_ATTRIB
    LDA #180
    STA sprite_largeIsland3 + SPRITE_X

    LDA #98
    STA sprite_largeIsland4 + SPRITE_Y
    LDA #$16
    STA sprite_largeIsland4 + SPRITE_TILE
    LDA #2
    STA sprite_largeIsland4 + SPRITE_ATTRIB
    LDA #188
    STA sprite_largeIsland4 + SPRITE_X
    

    RTS ; End subroutine

; ---------------------------------------------------------------------------

; NMI is called on every frame
NMI:
    ; Initialise controller 1
    LDA #1
    STA JOYPAD1
    LDA #0
    STA JOYPAD1

    ;Initialise controller 2
    LDA #1
    STA JOYPAD2
    LDA #0
    STA JOYPAD2

    ; Read joypad1 state
    LDX #0
    STX joypad1_state
ReadController1:
    LDA JOYPAD1
    LSR A
    ROL joypad1_state
    INX
    CPX #8
    BNE ReadController1

    ; Read joypad2 state
    LDX #0
    STX joypad2_state
ReadController2:
    LDA JOYPAD2
    LSR A
    ROL joypad2_state
    INX
    CPX #8
    BNE ReadController2

    ; Player 1 react to Down button
    LDA joypad1_state
    AND #BUTTON_DOWN
    BEQ Joypad1ReadDown_Done
  ; if ((JOYPAD1 & 1) != 0) {
; Move the player Down
    LDA sprite_player1 + SPRITE_Y
    CLC
    ADC #1
    STA sprite_player1 + SPRITE_Y

    LDA sprite_player12 + SPRITE_Y
    CLC
    ADC #1
    STA sprite_player12 + SPRITE_Y

    LDA sprite_player13 + SPRITE_Y
    CLC
    ADC #1
    STA sprite_player13 + SPRITE_Y

    LDA sprite_player14 + SPRITE_Y
    CLC
    ADC #1
    STA sprite_player14 + SPRITE_Y
Joypad1ReadDown_Done:         ; }

    ; Player 1 react to Up button
    LDA joypad1_state
    AND #BUTTON_UP
    BEQ Joypad1ReadUp_Done  
    ; if ((JOYPAD1 & 1) != 0) {
    ; Move the player up
    LDA sprite_player1 + SPRITE_Y
    SEC
    SBC #1
    STA sprite_player1 + SPRITE_Y

    LDA sprite_player12 + SPRITE_Y
    SEC
    SBC #1
    STA sprite_player12 + SPRITE_Y

    LDA sprite_player13 + SPRITE_Y
    SEC
    SBC #1
    STA sprite_player13 + SPRITE_Y

    LDA sprite_player14 + SPRITE_Y
    SEC
    SBC #1
    STA sprite_player14 + SPRITE_Y
Joypad1ReadUp_Done:         ; }

    ;Player 2 react to down button
    LDA joypad2_state
    AND #BUTTON_DOWN
    BEQ Joypad2ReadDown_Done
    ; if ((JOYPAD2 & 1) != 0) {
    ; Move the player Down
    LDA sprite_player2 + SPRITE_Y
    CLC
    ADC #1
    STA sprite_player2 + SPRITE_Y

    LDA sprite_player22 + SPRITE_Y
    CLC
    ADC #1
    STA sprite_player22 + SPRITE_Y

    LDA sprite_player23 + SPRITE_Y
    CLC
    ADC #1
    STA sprite_player23 + SPRITE_Y

    LDA sprite_player24 + SPRITE_Y
    CLC
    ADC #1
    STA sprite_player24 + SPRITE_Y
Joypad2ReadDown_Done:
    ;}

    ;Player 2 react to up button
    LDA joypad2_state
    AND #BUTTON_UP
    BEQ Joypad2ReadUp_Done
    ; if ((JOYPAD2 & 1) != 0) {
    ; Move the player up
        LDA sprite_player2 + SPRITE_Y
        SEC
        SBC #1
        STA sprite_player2 + SPRITE_Y

        LDA sprite_player22 + SPRITE_Y
        SEC
        SBC #1
        STA sprite_player22 + SPRITE_Y

        LDA sprite_player23+ SPRITE_Y
        SEC
        SBC #1
        STA sprite_player23 + SPRITE_Y

        LDA sprite_player24 + SPRITE_Y
        SEC
        SBC #1
        STA sprite_player24 + SPRITE_Y
Joypad2ReadUp_Done:
    ;}


    ; Player 1 react to A button
    LDA joypad1_state
    AND #BUTTON_A
    BEQ ReadPlayer1A_Done
    ; Spawn a bullet if one is not active
    LDA bullet_active
    BNE ReadPlayer1A_Done
    ; No bullet active, so spawn one
    LDA #1
    STA bullet_active
    LDA sprite_player1 + SPRITE_Y    ; Y position
    STA sprite_bullet + SPRITE_Y
    LDA #2      ; Tile number
    STA sprite_bullet + SPRITE_TILE
    LDA #0      ; Attributes
    STA sprite_bullet + SPRITE_ATTRIB
    LDA sprite_player1 + SPRITE_X    ; X position
    STA sprite_bullet + SPRITE_X
ReadPlayer1A_Done:

    ; Update the bullet
    LDA bullet_active
    BEQ UpdateBullet_Done
    LDA sprite_bullet + SPRITE_X
    CLC 
    ADC #2
    STA sprite_bullet + SPRITE_X
    BCC UpdateBullet_Done
    ; If carry flag is clear, bullet has left the top of the screen -- destroy it
    LDA #0
    STA bullet_active
UpdateBullet_Done:

        ; Check for collision
        LDA sprite_player2 + SPRITE_X
        SEC
        SBC #17
        CMP sprite_bullet + SPRITE_X
        BCS UpdatePlayer2_NoCollision
        CLC
        ADC #33
        CMP sprite_bullet + SPRITE_X 
        BCC UpdatePlayer2_NoCollision
        LDA sprite_player2 + SPRITE_Y
        SEC
        SBC #17
        CMP sprite_bullet + SPRITE_Y
        BCS UpdatePlayer2_NoCollision
        BCS UpdatePlayer2_NoCollision
        CLC
        ADC #33
        CMP sprite_bullet + SPRITE_Y
        BCC UpdatePlayer2_NoCollision
        ;Handle Collision
        LDA #0
        STA bullet_active
        LDA #$FF
        STA sprite_bullet + SPRITE_X
        LDA #$FF
        STA sprite_player2 + SPRITE_X
        LDA #$FF
        STA sprite_player22 + SPRITE_X
        LDA #$FF
        STA sprite_player23 + SPRITE_X
        LDA #$FF
        STA sprite_player24 + SPRITE_X
UpdatePlayer2_NoCollision:




    ;Player 2 react to A button
    LDA joypad2_state
    AND #BUTTON_A
    BEQ ReadPlayer2A_Done
    ; Spawn the bullet
    LDa bullet2_active
    BNE ReadPlayer2A_Done
    ; No bullet active so spawn one
    LDA #1
    STA bullet2_active
    LDA sprite_player2 + SPRITE_Y
    STA sprite_bullet1 + SPRITE_Y
    LDA #2
    STA sprite_bullet1 + SPRITE_TILE
    LDA #0
    STA sprite_bullet1 + SPRITE_ATTRIB
    LDA sprite_player2 + SPRITE_X
    STA sprite_bullet1 + SPRITE_X
ReadPlayer2A_Done:

    ;Update the bullet
    LDA bullet2_active
    BEQ UpdateBullet2_Done
    LDA sprite_bullet1 + SPRITE_X
    SEC
    SBC #2
    STA sprite_bullet1 + SPRITE_X
    BCS UpdateBullet2_Done
    ; If carry flag is clear
    LDA #0
    STA bullet2_active
UpdateBullet2_Done:

        ;Check for Collision
        LDA sprite_player1 + SPRITE_X
        SEC
        SBC #17
        CMP sprite_bullet1 + SPRITE_X
        BCS UpdatePlayer1_NoCollision
        CLC
        ADC #33
        CMP sprite_bullet1 + SPRITE_X 
        BCC UpdatePlayer1_NoCollision
        LDA sprite_player1 + SPRITE_Y
        SEC
        SBC #17
        CMP sprite_bullet1 + SPRITE_Y
        BCS UpdatePlayer1_NoCollision
        CLC
        ADC #33
        CMP sprite_bullet1 + SPRITE_Y
        BCC UpdatePlayer1_NoCollision
        ;Handle Collision
        LDA #0
        STA bullet2_active
        LDA #$FF
        STA sprite_bullet1 + SPRITE_X
        LDA #$FF
        STA sprite_player1 + SPRITE_X
        LDA #$FF
        STA sprite_player12 + SPRITE_X
        LDA #$FF
        STA sprite_player13 + SPRITE_X
        LDA #$FF
        STA sprite_player14 + SPRITE_X
UpdatePlayer1_NoCollision:

;Macro that handles all the waves movement
;                             \1            \2      \3         \4
MoveWave .macro ; parameters: FoamHasMoved, Sprite, SkipLabel, FinishLabel

    LDA \1
    BEQ \3
    LDA \2
    SEC
    SBC #1
    STA \2
    LDA #0
    STA \1
    JMP \4
    .endm

;Calling the macro for all waves
MoveWave foam1_hasMoved, sprite_foam1 + SPRITE_Y, Movement1, MovementDone1

Movement1:
    LDA #1
    STA foam1_hasMoved
MovementDone1:
    MoveWave foam2_hasMoved, sprite_foam2 + SPRITE_Y, Movement2, MovementDone2

Movement2:
    LDA #1
    STA foam2_hasMoved
MovementDone2:
    MoveWave foam3_hasMoved, sprite_foam3 + SPRITE_Y, Movement3, MovementDone3

Movement3:
    LDA #1
    STA foam3_hasMoved
MovementDone3:
    MoveWave foam4_hasMoved, sprite_foam4 + SPRITE_Y, Movement4, MovementDone4

Movement4:
    LDA #1
    STA foam4_hasMoved
MovementDone4:

    ; Copy sprite data to the PPU
    LDA #0
    STA OAMADDR
    LDA #$02
    STA OAMDMA

    RTI         ; Return from interrupt

; ---------------------------------------------------------------------------

    .bank 1
    .org $FFFA
    .dw NMI
    .dw RESET
    .dw 0

; ---------------------------------------------------------------------------

    .bank 2
    .org $0000
    .incbin "PirateShip.chr"
