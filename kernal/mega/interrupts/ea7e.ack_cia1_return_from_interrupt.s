; #LAYOUT# STD *        #TAKE
; #LAYOUT# *   KERNAL_0 #TAKE
; #LAYOUT# *   *        #IGNORE


; https:;csdb.dk/forums/index.php?roomid=11&topicid=5776
; Clear the CIA1 interrupt flag, and then fall through to
; the return from interrupt routine

clear_cia1_interrupt_flag_and_return_from_interrupt:

	jsr irq_ack

	; FALL THROUGH to $EA81

.assert * = return_from_interrupt, error, "clear_cia1_interrupt_flag_and_return_from_interrupt must fall through to return_from_interrupt"


