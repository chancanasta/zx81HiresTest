;
; To assembly this, either use the zxasm.bat file:
;
; zxasm hires
;
; or... assemble with the following options:
;
; tasm -80 -b -s hires.asm hires.p
;
;==============================================
; ZX81 assembler 'Hires' test
;==============================================
;

;defs
#include "zx81defs.asm"
;EQUs for ROM routines
#include "zx81rom.asm"
;ZX81 char codes/how to survive without ASCII
#include "charcodes.asm"
;system variables
#include "zx81sys.asm"

;the standard REM statement that will contain our 'hex' code
#include "line1.asm"


;------------------------------------------------------------
; code starts, gets added to the end of the rem
;------------------------------------------------------------

;exciting EQUS for this app
#include "equs.asm"

;set everything up
	call initvars
	call instruct
	call hires
mainlp	
	
;wait for a vsync...
	ld b,VSYNCLP
pauselp	
	call vsync
	djnz pauselp
	
	call waitkpress
	
	call lores
;see if we've finished
	ld a,(alldone)
	cp $fe
	jp nz,done1
	ld a,$ff
	ld (alldone),a
	jp mainlp
done1	
	cp $ff
	jp nz,mainlp
	ret
	
	

;subroutines

;switch to high res
hires	
;wait for an interrupt
	halt 	
;wait for a vsync
	ld a,(FRAMES)
	ld c,a
sync1	
	ld a,(FRAMES)		
	cp c
	jr z,sync1
;replace the render routine		
;set the index to somewhere useful in the ROM
	ld a,$12
	ld i,a
	ld ix,hresgen
	ret
		
;switch back to low res
lores	
;wait for an interrupt
	halt 
;wait for a vsync
	ld a,(FRAMES)
	ld c,a
sync2	
	ld a,(FRAMES)
	cp c
	jr z,sync2
;reset the I register to the ROM default		
	ld a,$1e
	ld i,a
;put back the normal display routine		
	ld ix,DISPROUT
	ret

;actual high res routine
hresgen	
;slightly odd address - but it's basically 'back one line' from the start of the screen memory
;with bit 15 of the address set
	ld hl,(HDISPLAY - $21) + $8000		
;set the line width
	ld de,$21
;disable interrupts
	di
;the ULA port address		
	ld c,$fe
;delay to sync with tv
	ld a,HIRES_IDX
	ld i,a
	ld b,5	
sync3	
	djnz sync3
;the number of lines - 192
	ld b,$c0
;keep the ULA thinking it's on the first line of a character		
genline	
	in a,(c)
	out ($ff),a
	add hl,de
	call ulaout
	dec b
	jp nz,genline
;sneakily jump into a couple of  ROM routines
	call DISPLAY_3
	call SLOWORFAST + $19
	ld ix,hresgen
;jump back into the ROM
	jp (DISPLAY_3 + $12)
;jump directly into the display file - it will hit a ret...		
ulaout	
	jp (hl)	
	


;that was all pretty exciting
;but here's so far less exciting routines...

;print things on screen
dispstring
;write directly to the screen
	ld hl,(D_FILE)
	add hl,bc	
loop2
	ld a,(de)
	cp $ff
	jp z,loop2End
	ld (hl),a
	inc hl
	inc de
	jp loop2
loop2End	
	ret


clearstring
	ld hl,(D_FILE)
	add hl,bc	
cloop2
	ld a,(de)
	cp $ff
	jp z,cloop2End
	ld (hl),__
	inc hl
	inc de
	jp cloop2
cloop2End	
	ret
	
	
;read keys
readkeys
;a bit lazy - call the ROM routine to get the zone values into HL
	call KSCAN
;lazy test for zones...	
;bit 3 will give us left half of the keys on the top row of the keyboard
	bit 3,l	
	jr nz,nokey1
	ret
	
nokey1
;bit 4 will give us right half of the keys on the top row of the keyboard
	bit 4,l
	jr nz,pastnokey1
	ret
	
pastnokey1		
	ret
	
	
;check for video sync
vsync	
	ld a,(FRAMES)
	ld c,a
sync
	ld a,(FRAMES)
	cp c
	jr z,sync
	ret
	

initvars
;setup init pos
	ret
;show some rubbish instructions	
instruct
	ld bc,(DISPLEN*7)+10
	ld de,instruct1
	call dispstring
	ld bc,(DISPLEN*10)+6
	ld de,instruct2
	call dispstring
	
waitkpress
	call KSCAN
	ld a,l
	cp $ff
	jp z,waitkpress

	ld bc,(DISPLEN*7)+10
	ld de,instruct1
	call clearstring
	ld bc,(DISPLEN*10)+6
	ld de,instruct2
	call clearstring

	ret

;vars for this app
#include "vars.asm"
	
		
; ===========================================================
; code ends
; ===========================================================
;end the REM line and put in the RAND USR line to call our 'hex code'
#include "line2.asm"

                
;display file defintion - lores and hires
#include "screen.asm"               
									

;close out the basic program
#include "endbasic.asm"

#END
