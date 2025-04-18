package casino

import "core:encoding/ansi"
import "core:fmt"
import "core:log"
import "core:strings"

render_vert_line :: proc(x, y1, y2: int) {
	if y1 == y2 {
		term_cursor_to(x, y1)
		term_print("|")
		return
	}

	yh := y1 if y1 > y2 else y2
	yl := y1 if y1 < y2 else y2

	term_cursor_to(x, yl)
	for _ in yl ..= yh {
		term_print("|")
		term_cursor_down()
		term_cursor_left()
	}
}

render_horiz_line :: proc(y, x1, x2: int) {
	xh := x1 if x1 > x2 else x2
	xl := x1 if x1 < x2 else x2

	term_cursor_to(xl, y)
	for _ in xl ..= xh {
		term_print("-")
	}
}

render_str_at :: proc(x, y: int, str: string) {
	term_cursor_to(x, y)
	term_print(str)
}

render_str_right_aligned :: proc(str: string) {
	term_cursor_left(len(str) - 1)
	term_print(str)
}

render_str_middle_aligned :: proc(str: string) {
	term_cursor_left(len(str) / 2)
	term_print(str)
}

render_machine :: proc() {
	mid := termWidth / 2 + 1

	// Stand
	term_set(ansi.FG_BRIGHT_BLACK, ansi.BOLD)
	render_vert_line(mid - 3, termHeight, termHeight - 1)
	render_vert_line(mid + 3, termHeight, termHeight - 1)
	term_reset()

	// Body
	term_set(ansi.FG_GREEN)
	render_horiz_line(termHeight - 2, mid - 10, mid + 10)
	render_str_at(mid - 11, termHeight - 2, "'")
	render_str_at(mid + 11, termHeight - 2, "'")
	render_vert_line(mid - 11, termHeight - 3, termHeight - 12)
	render_vert_line(mid + 11, termHeight - 3, termHeight - 12)
	render_str_at(mid - 11, termHeight - 13, ".")
	render_str_at(mid + 11, termHeight - 13, ".")
	render_horiz_line(termHeight - 13, mid - 10, mid + 10)
	term_reset()

	// Handle
	term_set(ansi.FG_BRIGHT_BLACK)
	render_str_at(mid + 12, termHeight - 5, "/")
	render_str_at(mid + 13, termHeight - 6, "/")
	render_vert_line(mid + 14, termHeight - 7, termHeight - 9)
	term_set(ansi.FG_RED)
	render_str_at(mid + 14, termHeight - 10, "O")
	term_reset()

	// Upper part
	term_set(ansi.FG_GREEN)
	render_str_at(mid - 9, termHeight - 14, "/")
	render_str_at(mid + 9, termHeight - 14, "\\")
	render_str_at(mid - 8, termHeight - 15, ".")
	render_str_at(mid + 8, termHeight - 15, ".")
	render_horiz_line(termHeight - 15, mid - 7, mid + 7)
	if lastWin != 0 {
		term_set(ansi.FG_BRIGHT_YELLOW)
		if lastOutcome == .Sevens {
			render_str_at(mid - 6, termHeight - 14, "JACKPOT!")
		} else {
			render_str_at(mid - 6, termHeight - 14, "WIN!")
		}
		term_reset()


		sb := strings.builder_make()
		defer strings.builder_destroy(&sb)
		win_num_sb := strings.builder_make()
		defer strings.builder_destroy(&win_num_sb)
		win_num_str := localize_int(&win_num_sb, lastWin)
		strings.write_string(&sb, win_num_str)
		strings.write_byte(&sb, '$')
		str := strings.to_string(sb)
		term_set(ansi.FG_GREEN, ansi.BOLD)
		term_cursor_to(mid + 6, termHeight - 14)
		render_str_right_aligned(str)
	}
	term_reset()

	// Slots box
	term_set(ansi.FG_GREEN)
	render_horiz_line(termHeight - 11, mid - 7, mid + 7)
	render_str_at(mid - 8, termHeight - 11, ".")
	render_str_at(mid + 7, termHeight - 11, ".")
	render_str_at(mid - 8, termHeight - 10, "|")
	render_str_at(mid + 7, termHeight - 10, "|")
	render_str_at(mid - 8, termHeight - 9, "'")
	render_str_at(mid + 7, termHeight - 9, "'")
	render_horiz_line(termHeight - 9, mid - 7, mid + 6)
	term_reset()
	term_cursor_to(mid - 5, termHeight - 10)
	for face in lastRoll {
		if face == .Seven {
			term_set(ansi.FG_RED, ansi.BOLD, ansi.ITALIC)
			term_print(FACE_ICON_MAP[face])
			term_reset()
		} else {
			term_print(FACE_ICON_MAP[face])
		}
		term_cursor_right(2)
	}
	term_reset()

	// Bottom interface
	term_set(ansi.FG_BRIGHT_BLACK, ansi.FAINT)
	term_cursor_to(mid, termHeight - 5)
	render_str_middle_aligned("SELECT AMOUNT")
	term_reset()
	term_cursor_to(mid, termHeight - 3)
	render_str_middle_aligned("[SPACE]")
	term_cursor_to(mid - 8, termHeight - 4)
	term_print("[-]")
	term_cursor_to(mid + 8, termHeight - 4)
	render_str_right_aligned("[+]")
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	bet_str := fmt.tprint(POSSIBLE_BETS[betIdx])
	strings.write_string(&sb, bet_str)
	free_all(context.temp_allocator)
	strings.write_byte(&sb, '$')
	bet_text := strings.to_string(sb)
	term_set(ansi.FG_BRIGHT_YELLOW)
	term_cursor_to(mid, termHeight - 4)
	render_str_middle_aligned(bet_text)
	term_reset()
}

render_info :: proc() {
	mid := termWidth / 2 + 1
	left_wall := mid + 20

	term_reset()

	render_str_at(left_wall, termHeight - 13, "3 FRUIT: ")
	term_set(ansi.FG_BRIGHT_YELLOW)
	term_print("2x")
	term_reset()
	render_str_at(left_wall, termHeight - 12, "🍋  🍇  🍒")

	render_str_at(left_wall, termHeight - 10, "SAME FRUIT: ")
	term_set(ansi.FG_BRIGHT_YELLOW)
	term_print("10x")
	term_reset()
	render_str_at(left_wall, termHeight - 9, "🍇  🍇  🍇")

	render_str_at(left_wall, termHeight - 7, "3 BELLS: ")
	term_set(ansi.FG_BRIGHT_YELLOW)
	term_print("25x")
	term_reset()
	render_str_at(left_wall, termHeight - 6, "🔔  🔔  🔔")

	render_str_at(left_wall, termHeight - 4, "3 SEVENS: ")
	term_set(ansi.FG_BRIGHT_YELLOW)
	term_print("100x")
	term_reset()
	term_set(ansi.FG_RED, ansi.BOLD, ansi.ITALIC)
	render_str_at(left_wall, termHeight - 3, "'7  '7  '7")
	term_reset()
}

render_cash_part :: proc() {
	mid := termWidth / 2 + 1
	right_wall := mid - 19

	term_reset()

	render_str_at(mid - 35, termHeight - 13, "CASH:")
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	localize_int(&sb, cash)
	strings.write_byte(&sb, '$')
	cash_text := strings.to_string(sb)
	term_set(ansi.FG_GREEN, ansi.BOLD)
	term_cursor_to(right_wall, termHeight - 13)
	render_str_right_aligned(cash_text)
	term_reset()

	for i := 0; i < len(historyRing); i += 1 {
		idx := (historyIdx - 1 - i) %% len(historyRing)
		entry := historyRing[idx].? or_continue
		hsb := strings.builder_make()
		defer strings.builder_destroy(&hsb)
		negative := entry < 0
		if !negative do strings.write_byte(&hsb, '+')
		localize_int(&hsb, entry)
		strings.write_byte(&hsb, '$')
		hstr := strings.to_string(hsb)
		term_set(ansi.FG_RED if negative else ansi.FG_GREEN, ansi.BOLD)
		term_cursor_to(right_wall, termHeight - 11 + i)
		render_str_right_aligned(hstr)
		term_reset()
	}
}

render_ui :: proc() {
	term_reset()
	render_str_at(1, termHeight, "[q]")
	term_set(ansi.FG_BRIGHT_BLACK)
	term_print("uit")
	term_reset()

	mid := termWidth / 2 + 1
	term_set(ansi.FG_BRIGHT_BLACK, ansi.UNDERLINE)
	term_cursor_to(mid, 2)
	render_str_middle_aligned("REACH 1,000,000$ TO WIN")
	term_reset()
}

render :: proc() {
	term_clear()
	term_reset()

	render_machine()
	render_info()
	render_cash_part()
	render_ui()
}
