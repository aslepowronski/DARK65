.setcpu "6502"

; Adresy ACIA
ACIA_DATA    = $4000
ACIA_STATUS  = $4001
ACIA_COMMAND = $4002
ACIA_CONTROL = $4003

; Zmienne w bezpiecznym miejscu Zero Page
TEMP   = $FD
ADDR_L = $FE
ADDR_H = $FF

.segment "CODE"

RESET:
    ldx #$ff
    txs

    ; Inicjalizacja ACIA
    sta ACIA_STATUS 
    lda #$1e        ; 9600 baud
    sta ACIA_CONTROL
    lda #$0b        ; Tx/Rx on
    sta ACIA_COMMAND

MAIN_LOOP:
    jsr GET_CHAR    ; Czekaj na komendę
    
    cmp #$72        ; 'r' (read)
    beq DO_READ
    
    cmp #$77        ; 'w' (write)
    beq DO_WRITE

    cmp #$70        ; 'p' (print)
    beq DO_PRINT
    
    jmp MAIN_LOOP

; --- KOMENDA p: Nieskończone drukowanie ---
DO_PRINT:
    ldx #0
@next_char:
    lda msg_hello, x
    beq @delay       ; Koniec napisu, idź do opóźnienia
    jsr SEND_CHAR
    inx
    jmp @next_char

@delay:
    ; Krótkie opóźnienie (odstęp czasowy), by terminal nadążył
    ldy #$00
@inner:
    dey
    bne @inner
    ; Brak znaku nowej linii - po prostu wracamy na początek napisu
    jmp DO_PRINT

; --- ODCZYT (r[aaaa]) ---
DO_READ:
    jsr GET_HEX_ADDR
    lda #$3a        ; ':'
    jsr SEND_CHAR
    ldy #0
    lda (ADDR_L), y 
    jsr PRINT_HEX_BYTE
    jsr PRINT_CRLF
    jmp MAIN_LOOP

; --- ZAPIS (w[aaaa]:[vv]) ---
DO_WRITE:
    jsr GET_HEX_ADDR
    jsr GET_CHAR     ; Czekaj na ':'
    cmp #$3a
    bne ABORT_WRITE
    jsr GET_HEX_BYTE
    ldy #0
    sta (ADDR_L), y 
    lda #$21         ; '!'
    jsr SEND_CHAR
    jsr PRINT_CRLF
    jmp MAIN_LOOP

ABORT_WRITE:
    lda #$3f         ; '?'
    jsr SEND_CHAR
    jsr PRINT_CRLF
    jmp MAIN_LOOP

; --- PODPROGRAMY I DANE ---

msg_hello: .byte "Hello 6502 ", 0

GET_HEX_ADDR:
    jsr GET_HEX_BYTE
    sta ADDR_H
    jsr GET_HEX_BYTE
    sta ADDR_L
    rts

GET_HEX_BYTE:
    jsr GET_CHAR    
    jsr HEX_TO_BIN
    asl
    asl
    asl
    asl
    sta TEMP
    jsr GET_CHAR    
    jsr HEX_TO_BIN
    ora TEMP        
    rts

HEX_TO_BIN:
    cmp #$3a
    bcc @is_num
    sbc #$27
    and #$0f
    rts
@is_num:
    and #$0f
    rts

PRINT_HEX_BYTE:
    pha
    lsr
    lsr
    lsr
    lsr
    jsr @p_dig
    pla
    and #$0f
@p_dig:
    cmp #$0a
    bcc @n
    adc #$06
@n:
    adc #$30
    jsr SEND_CHAR
    rts

PRINT_CRLF:
    lda #$0d
    jsr SEND_CHAR
    lda #$0a
    jmp SEND_CHAR

GET_CHAR:
    lda ACIA_STATUS
    and #$08        
    beq GET_CHAR
    lda ACIA_DATA   
    jsr SEND_CHAR   ; Echo
    rts

SEND_CHAR:
    pha
@w: lda ACIA_STATUS
    and #$10        
    beq @w
    pla
    sta ACIA_DATA
    rts

.segment "VECTORS"
    .word $0000
    .word RESET
    .word $0000