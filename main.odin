package casino

import "base:runtime"
import "core:encoding/ansi"
import "core:fmt"
import "core:io"
import "core:log"
import "core:os"
import "core:time"

my_assertion_failure_proc: runtime.Assertion_Failure_Proc : proc(
	prefix, message: string,
	loc: runtime.Source_Code_Location,
) -> ! {
	term_deinit()
	runtime.default_assertion_failure_proc(prefix, message, loc)
}

main :: proc() {
	context.assertion_failure_proc = my_assertion_failure_proc

	when ODIN_DEBUG {
		log_file, err := os.open(
			#directory + "/game.log",
			os.O_WRONLY | os.O_CREATE | os.O_TRUNC,
			0o644,
		)
		if err != nil {
			fmt.panicf("Couldn't open `game.log`: %s\n", err)
		}

		context.logger = log.create_file_logger(log_file, .Debug)
	}

	sw: time.Stopwatch
	time.stopwatch_start(&sw)

	{
		term_init()
		defer term_deinit()

		stdin_reader := io.to_reader(os.stream_from_handle(os.stdin))

		for {
			render()
			if bigWin {
				time.sleep(time.Second)
				term_flush_input()
				bigWin = false
			}

			b, err := io.read_byte(stdin_reader)
			if err != nil {
				fmt.panicf("Error while reading from stdin: %s\n", err)
			}

			switch b {
			case 'q':
				return
			case ' ':
				roll_with_logic()
			case '+', '=':
				increase_bet()
			case '-', '_':
				decrease_bet()
			}

			if gameState != .Playing do break
		}
	}


	if gameState == .Lose {
		term_set(ansi.FG_RED, ansi.BOLD)
		term_print("\r|\n| YOU LOSE\n|\n")
		term_reset()
	} else if gameState == .Win {
		dur := time.stopwatch_duration(sw)
		term_set(ansi.FG_GREEN, ansi.BOLD)
		term_print("\r|\n| YOU WIN!\n")

		buf: [32]u8
		time_text := time.duration_to_string_hms(dur, buf[:])
		term_printf("| %s\n|\n", time_text)
		term_reset()
	}
}
