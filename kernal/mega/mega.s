.macro bcc_16 addr
	bcc addr
.endmacro

.macro bcs_16 addr
	bcs addr
.endmacro

.macro beq_16 addr
	beq addr
.endmacro

.macro bne_16 addr
	bne addr
.endmacro

.macro phx_trash_a
	txa
	pla
.endmacro

.macro plx_trash_a
	pla
	tax
.endmacro

.macro phy_trash_a
	tya
	pla
.endmacro

.macro ply_trash_a
	pla
	tay
.endmacro

.macro skip_2_bytes_trash_nvz
	.byte $2c
.endmacro


.include ",stubs/e6b6.advance_cursor.s"
.include ",stubs/e96c.insert_line_at_top.s"
.include ",stubs/f3f6.unknown.s"
.include ",stubs/f646.iec_close.s"
.include ",stubs/e701.previous_line.s"
.include ",stubs/e716.chrout_screen.s"
.include ",stubs/fd90.unknown.s"
.include "init/fffc.vector_reset.s"
.include "init/cint_screen_keyboard.s"
.include "init/ff5b.cint.s"
.include "init/e518.cint_legacy.s"
.include "init/fce2.hw_entry_reset.s"
.include "memory/vector_real.s"
.include "memory/fe25.memtop.s"
.include "memory/membot.s"
.include "memory/fd15.restor.s"
.include "rom_revision/ff80.kernal_revision.s"
.include "errors.s"
.include "print/print_kernal_message.s"
.include "print/print_space.s"
.include "print/print_return.s"
.include "time/settim.s"
.include "time/rdtim.s"
.include "time/udtim.s"
.include "iostack/f4a5.load.s"
.include "iostack/f291.close.s"
.include "iostack/setnam.s"
.include "iostack/getin_real.s"
.include "iostack/f13e.getin.s"
.include "iostack/setmsg.s"
.include "iostack/f157.chrin.s"
.include "iostack/f5ed.save.s"
.include "iostack/clall_real.s"
.include "iostack/f5dd.save_prep.s"
.include "iostack/load_save_common.s"
.include "iostack/chkinout.s"
.include "iostack/f333.clrchn.s"
.include "iostack/findfls.s"
.include "iostack/f49e.load_prep.s"
.include "iostack/f250.ckout.s"
.include "iostack/f1ca.chrout.s"
.include "iostack/f32f.clall.jmp.s"
.include "iostack/settmo.s"
.include "iostack/readst.s"
.include "iostack/f20e.chkin.s"
.include "iostack/setfls.s"
.include "iostack/f34a.open.s"
.include "interrupts/hw_entry_nmi.s"
.include "interrupts/fe47.default_nmi_handler.s"
.include "interrupts/ea7e.ack_cia1_return_from_interrupt.s"
.include "interrupts/ea31.default_irq_handler.s"
.include "interrupts/ea81.return_from_interrupt.s"
.include "interrupts/fffa.vector_nmi.s"
.include "interrupts/fe66.default_brk_handler.s"
.include "interrupts/fffe.vector_irq.s"
.include "interrupts/hw_entry_irq.s"
.include "screen/chrout_screen_shift_onoff.s"
.include "screen/chrout_screen_gfxtxt.s"
.include "screen/e9ff.screen_clear_line.s"
.include "screen/screen_get_logical_line_end_ptr.s"
.include "screen/screen_calculate_pnt_user.s"
.include "screen/e544.clear_screen.s"
.include "screen/screen_calculate_pntr_lnmx.s"
.include "screen/chrout_screen_ins.s"
.include "screen/screen_get_cliped_pntr.s"
.include "screen/chrout_screen_jumptable_codes.s"
.include "screen/cursor_enable.s"
.include "screen/cursor.s"
.include "screen/chrout_screen_return.s"
.include "screen/chrout_screen_home.s"
.include "screen/screen_check_space_ends_line.s"
.include "screen/screen_advance_to_next_line.s"
.include "screen/chrout_screen_rvs.s"
.include "screen/chrout_screen_del.s"
.include "screen/screen_preserve_sal_eal.s"
.include "screen/cursor_show.s"
.include "screen/chrout_screen_clr.s"
.include "screen/chrout_screen.s"
.include "screen/chrout_screen_tab.s"
.include "screen/screen.s"
.include "screen/e566.cursor_home.s"
.include "screen/e56c.screen_calculate_pointers.s"
.include "screen/e8ea.screen_scroll_up.s"
.include "screen/chrout_screen_control.s"
.include "screen/chrout_screen_quote.s"
.include "screen/screen_code_to_petscii.s"
.include "screen/chrout_screen_crsr.s"
.include "screen/screen_restore_sal_eal.s"
.include "screen/e50a.plot.s"
.include "screen/screen_grow_logical_line.s"
.include "screen/chrout_screen_stop.s"
.include "assets/kernal_messages.s"
.include "assets/e8da.colour_codes.s"
.include "assets/fd30.vector_defaults.s"
.include "jumptable/ffc0.jopen.s"
.include "jumptable/ffbd.jsetnam.s"
.include "jumptable/ffa5.jacptr.s"
.include "jumptable/ffc9.jckout.s"
.include "jumptable/ffe1.jstop.s"
.include "jumptable/ffea.judtim.s"
.include "jumptable/ffba.jsetfls.s"
.include "jumptable/ffd2.jchrout.s"
.include "jumptable/ff9c.jmembot.s"
.include "jumptable/ff8a.jrestor.s"
.include "jumptable/ffe7.jclall.s"
.include "jumptable/ffb1.jlisten.s"
.include "jumptable/ffb4.jtalk.s"
.include "jumptable/ffcc.jclrchn.s"
.include "jumptable/ffb7.jreadst.s"
.include "jumptable/ffa8.jciout.s"
.include "jumptable/ff8d.jvector.s"
.include "jumptable/ff99.jmemtop.s"
.include "jumptable/ffae.junlsn.s"
.include "jumptable/ffa2.jsettmo.s"
.include "jumptable/ffd8.jsave.s"
.include "jumptable/fff3.jiobase.s"
.include "jumptable/ffdb.jsettim.s"
.include "jumptable/ff90.jsetmsg.s"
.include "jumptable/ffed.jscreen.s"
.include "jumptable/ffc6.jchkin.s"
.include "jumptable/ffcf.jchrin.s"
.include "jumptable/ffd5.jload.s"
.include "jumptable/fff0.jplot.s"
.include "jumptable/ff84.jioinit.s"
.include "jumptable/ff81.jcint.s"
.include "jumptable/ffab.juntlk.s"
.include "jumptable/ffde.jrdtim.s"
.include "jumptable/ff96.jtksa.s"
.include "jumptable/ffe4.jgetin.s"
.include "jumptable/ff87.jramtas.s"
.include "jumptable/ffc3.jclose.s"
.include "jumptable/ff9f.jscnkey.s"
.include "jumptable/ff93.jsecond.s"
.include "keyboard/f142.getin_keyboard.s"
.include "keyboard/pop_keyboard_buffer.s"
.include "keyboard/f6ed.stop.s"
.include "keyboard/chrin_keyboard.s"

