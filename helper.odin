package casino

import "base:runtime"
import "core:c"
import "core:c/libc"
import "core:fmt"
import "core:strings"

localize_int :: proc(sb: ^strings.Builder, n: int) -> string {
	str := fmt.tprint(abs(n))
	if n < 0 do strings.write_byte(sb, '-')

	for c, i in transmute([]u8)str {
		if i != 0 && (len(str) - i) % 3 == 0 {
			strings.write_byte(sb, ',')
		}
		strings.write_byte(sb, c)
	}

	free_all(context.temp_allocator)

	return strings.to_string(sb^)
}
