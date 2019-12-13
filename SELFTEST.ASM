; "Self-test", Atari XL/XE Intro 256B
; music by Modest Mussorgsky, the piano suite Pictures at an Exhibition
; transcripted for the piano by Harold Bauer
; code by tr1x
; requirements: original Atari XL/XE 64KB PAL
; version: 1.0
; release date: 2019-12-07

	org $068e	; it is set so "play" address is $..b5 

rtclok	equ $0012
memaddr	equ $0057	; we do believe that the initial value < "ststart"
duratio	equ $00cd
vdslst	equ $0200
color4	equ $02c8
ststart	equ $5000	; Self-test, first page
stinien	equ $5059	; Self-test, the end of initialization
text	equ $51f5	; Audio-Visual Test, text "RESET OR HELP TO EXIT"
dlist	equ $5231	; Audio-Visual Test, display list
pause	equ $53b5	; Audio-Visual Test, pause
delay	equ $53b7	; Audio-Visual Test, delay
mute	equ $5510	; Audio-Visual Test, mute
auvitst	equ $5557	; Audio-Visual Test, memory address
pausjsr	equ $564f	; Audio-Visual Test, "jsr pause"
colpf0	equ $d016
colpf2	equ $d018
audf1	equ $d200
audc1	equ $d201
audf2	equ $d202
audc2	equ $d203
audf3	equ $d204
audc3	equ $d205
portb	equ $d301
vcount	equ $d40b
nmien	equ $d40e

	; copy Self-test from ROM to RAM
	;ldy #$00	; not needed, since (memaddr) < "ststart"
loop1	ldx #$7d	; Self-test ROM on
	stx portb
	lda (memaddr),y
	ldx #$fd	; Self-test ROM off	
	stx portb
	sta (memaddr),y
	dey
	bne loop1
	inc memaddr+1
	lda memaddr+1
	cmp #$60	; normally it should be #$58
	bne loop1	

	; inject "rts" in place of "lda $d01f"
	;lda #$60	; "rts" opcode; not needed, since "cmp" has #$60
	sta stinien

	; Self-test initialization
	jsr ststart

	; inject "jsr play" in place of "jsr $53b5"
	;lda #$20	; injection of "jsr" opcode is not needed,
	;sta pausjsr	; ..since "jsr" is already there
	;lda <play	; injection of low byte is not needed,
	;sta pausjsr+1	; ..since "org" is set so "play" address is $..b5
	lda >play
	sta pausjsr+2

	; Audio-Visual Test
	jmp auvitst

	; copy greetings
play	ldy #greetze-greetz-1
loop2	lda greetz,y
	sta text+4,y
	dey
	bpl loop2

	; set DLI routine
	lsr nmien	; disable DLI
	lda #<dlirout
	sta vdslst
	lda #>dlirout
	sta vdslst+1
	rol nmien	; enable DLI

	; modify display list to enable DLIs
	lda #$f0
	sta dlist+$03
	sta dlist+$0a
	lda #$c6
	sta dlist+$04

	lda #$8b
	ldy #$22
loop3	sta dlist+$0e,y
	dey
	bpl loop3

	; play music
	ldy #notese-notes-1
loop4	lda notes,y
	cmp #$20+1	; set duration, if a value < #$21
	bcs notdura
	sta duratio
	bvc skip	; 1 byte less than "jmp skip"
notdura	bpl single	; is a single note?
chord	and #$7f	; a chord
	pha		; push the first note in a chord into stack
	dey
	lda notes,y
	sta audf2
	lda #$a3
	sta audc2
	sta audc3
	dey
	lda notes,y
	sta audf3
	pla		; pop the first note in a chord from stack
single	sta audf1	; a single note
	lda #$a8
	sta audc1
	tya
	pha
	ldx duratio	; a note duration
	jsr delay
	jsr mute
	pla
	tay
skip	dey
	bpl loop4
	jsr pause	; the instruction that was replaced with "jsr play"
	rts

	; display list interrupt routine
dlirout	pha
	lda vcount	; rainbow
	adc rtclok+2
	sta colpf0
	lda #$30	; background of greetings
	sta colpf2
	pla
	rti

	; 4th bar
            ;  A4   C4   F3
notes	.byte $90, $79, $5b|$80
	    ;  G4   C4   G3
	.byte $a2, $79, $51|$80
	    ;  E3   G3   C3
	.byte $60, $51, $3c|$80
	    ;  D3   G3  Bb3
	.byte $6c, $51, $44|$80
	    ;  F3  Bb3   D2      duration
	.byte $5b, $44, $35|$80, $20
	    ;  C4   A3   F2
	.byte $79, $48, $2d|$80
	    ;  C4   A3   C3      duration
	.byte $79, $48, $3c|$80, $10

	; 3rd bar
	    ;  F3   A3   D2      duration
	.byte $5b, $48, $35|$80, $20
	    ;  C4   A3   F2
	.byte $79, $48, $2d|$80
	    ;  C4   A3   C3      duration
	.byte $79, $48, $3c|$80, $10
	    ; Bb4   D3  Bb3
	.byte $88, $6c, $44|$80
	    ;  A4   C4   F3
	.byte $90, $79, $5b|$80
	    ; Bb4   D3   G3
	.byte $88, $6c, $51|$80

	; 2nd bar
	    ;  F3   G3   C3  Bb3   D2  duration
	.byte $5b, $51, $3c, $44, $35, $20
	    ;  F2   C3  duration
	.byte $2d, $3c, $10	; <<< the entry point
notese

greetz	.byte "Greetz to all Atari fans!"
greetze
