package casino

import "base:runtime"
import "core:c"
import "core:c/libc"
import "core:encoding/ansi"
import "core:fmt"
import "core:log"
import "core:os"
import "core:strings"
import "core:sys/posix"

when ODIN_OS == .Windows {
	foreign import libc_ "system:libucrt.lib"
} else when ODIN_OS == .Darwin {
	foreign import libc_ "system:System.framework"
} else {
	foreign import libc_ "system:c"
}

foreign libc_ {
	ioctl :: proc(fd: c.int, request: c.ulong, arg: rawptr) -> c.int ---
}

termWidth: int
termHeight: int

originalTermios: posix.termios
rawTermios: posix.termios
tty: posix.FD

ANSI_HIDE_CURSOR :: ansi.CSI + "?25l"
ANSI_SHOW_CURSOR :: ansi.CSI + "?25h"
ANSI_SAVE_CURSOR :: ansi.CSI + "s"
ANSI_RESTORE_CURSOR :: ansi.CSI + "u"
ANSI_SAVE_SCREEN :: ansi.CSI + "?47h"
ANSI_RESTORE_SCREEN :: ansi.CSI + "?47l"
ANSI_ENTER_ALT_BUFFER :: ansi.CSI + "?1049h"
ANSI_LEAVE_ALT_BUFFER :: ansi.CSI + "?1049l"
ANSI_ENABLE_AUTOWRAP :: ansi.CSI + "?7h"
ANSI_DISABLE_AUTOWRAP :: ansi.CSI + "?7l"

term_init :: proc() {

	handle_winch :: proc "c" (sig: i32) {
		context = runtime.default_context()
		term_sync_size()
		render()
	}

	signal_SIGWINCH :: 28

	term_sync_size()

	posix.tcgetattr(tty, &originalTermios)
	rawTermios = originalTermios
	rawTermios.c_lflag &= ~{.ECHO, .ICANON, .ISIG, .IEXTEN}
	rawTermios.c_iflag &= ~{.IXON, .ICRNL, .BRKINT, .INPCK, .ISTRIP}
	rawTermios.c_oflag &= ~{.OPOST}
	rawTermios.c_cflag |= {.CS8}
	rawTermios.c_cc[.VTIME] = 0
	rawTermios.c_cc[.VMIN] = 1
	posix.tcsetattr(tty, .TCSAFLUSH, &rawTermios)

	term_print(ANSI_HIDE_CURSOR)
	term_print(ANSI_SAVE_CURSOR)
	term_print(ANSI_SAVE_SCREEN)
	term_print(ANSI_ENTER_ALT_BUFFER)
	term_print(ANSI_DISABLE_AUTOWRAP)
	term_clear()

	libc.signal(signal_SIGWINCH, handle_winch)
	tty = posix.open("/dev/tty", {.RDWR})
}

term_deinit :: proc() {
	term_clear()
	term_print(ANSI_LEAVE_ALT_BUFFER)
	term_print(ANSI_SHOW_CURSOR)
	term_print(ANSI_ENABLE_AUTOWRAP)
	term_reset()

	posix.tcsetattr(tty, .TCSAFLUSH, &originalTermios)
}

term_sync_size :: proc() {
	termios_winsize :: struct {
		ws_row:    c.ushort,
		ws_col:    c.ushort,
		ws_xpixel: c.ushort,
		ws_ypixel: c.ushort,
	}

	termios_TIOCGWINSZ :: 0x5413

	w: termios_winsize

	ioctl(c.int(tty), termios_TIOCGWINSZ, &w)
	termHeight = int(w.ws_row)
	termWidth = int(w.ws_col)
}

term_flush_input :: proc() {
	posix.tcsetattr(tty, .TCSAFLUSH, &rawTermios)
}

term_print :: proc(args: ..any, sep := " ", flush := true) -> int {
	return fmt.fprint(os.Handle(tty), ..args, sep = sep, flush = flush)
}

term_printf :: proc(fmt_: string, args: ..any, flush := true) -> int {
	return fmt.fprintf(os.Handle(tty), fmt_, ..args, flush = flush)
}

term_clear :: proc() {
	term_print(ansi.CSI + "2" + ansi.ED)
}

term_cursor_to :: proc(x, y: int) {
	term_printf(ansi.CSI + "%d;%d" + ansi.CUP, y, x)
}

term_cursor_up :: proc(n: int = 1) {
	term_printf(ansi.CSI + "%d" + ansi.CUU, n)
}

term_cursor_down :: proc(n: int = 1) {
	term_printf(ansi.CSI + "%d" + ansi.CUD, n)
}

term_cursor_right :: proc(n: int = 1) {
	term_printf(ansi.CSI + "%d" + ansi.CUF, n)
}

term_cursor_left :: proc(n: int = 1) {
	term_printf(ansi.CSI + "%d" + ansi.CUB, n)
}

term_set :: proc(modes: ..any) {
	assert(len(modes) >= 1)
	rep := strings.repeat(";%s", len(modes), context.temp_allocator)[1:]
	fmt_ := strings.concatenate(
		[]string{ansi.CSI, rep, ansi.SGR},
		allocator = context.temp_allocator,
	)

	term_printf(fmt_, ..modes)
	free_all(context.temp_allocator)
}

term_reset :: proc() {
	term_set(ansi.RESET)
}
