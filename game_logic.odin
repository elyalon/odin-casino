package casino

import "core:math/rand"

Face :: enum (byte) {
	Seven,
	Bell,
	Lemon,
	Grape,
	Cherry,
	Melon,
}

Outcome :: enum (byte) {
	Nothing,
	ThreeFruit,
	SameFruit,
	Bells,
	Sevens,
}

FACE_ICON_MAP := [Face]string {
	.Seven  = "'7",
	.Bell   = "🔔",
	.Lemon  = "🍋",
	.Grape  = "🍇",
	.Cherry = "🍒",
	.Melon  = "🍉",
}

OUTCOME_MULT_MAP := [Outcome]int {
	.Nothing    = 0,
	.ThreeFruit = 2,
	.SameFruit  = 10,
	.Bells      = 25,
	.Sevens     = 100,
}

POSSIBLE_BETS := [11]int{1, 5, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000}

// Game state
cash := 300
historyRing: [9]Maybe(int)
historyIdx := 0
betIdx: int = 1
lastWin: int
lastRoll := [3]Face{.Grape, .Lemon, .Seven} // Starting position
lastOutcome: Outcome
gameState: enum {
	Playing,
	Win,
	Lose,
} = .Playing
bigWin := false

roll :: proc() -> [3]Face {
	return [3]Face{rand.choice_enum(Face), rand.choice_enum(Face), rand.choice_enum(Face)}
}

roll_get_outcome :: proc(roll: [3]Face) -> Outcome {

	face_is_fruit :: proc(face: Face) -> bool {
		#partial switch face {
		case .Lemon, .Grape, .Cherry, .Melon:
			return true
		}

		return false
	}

	first := roll[0]
	all_the_same := true
	for face in roll {
		if face != first {
			all_the_same = false
		}
	}

	if all_the_same {
		same_face := roll[0]
		switch same_face {
		case .Seven:
			return .Sevens
		case .Bell:
			return .Bells
		case .Melon, .Cherry, .Grape, .Lemon:
			return .SameFruit
		}
	}

	all_fruit := true
	for face in roll {
		if !face_is_fruit(face) {
			all_fruit = false
			break
		}
	}
	if all_fruit {return .ThreeFruit}

	return .Nothing
}

roll_with_logic :: proc() {
	if cash < POSSIBLE_BETS[betIdx] do return

	cash -= POSSIBLE_BETS[betIdx]
	history_push(-POSSIBLE_BETS[betIdx])

	r := roll()
	lastRoll = r
	ro := roll_get_outcome(r)
	lastOutcome = ro
	bigWin = ro == .Bells || lastOutcome == .Sevens
	win := OUTCOME_MULT_MAP[ro] * POSSIBLE_BETS[betIdx]
	lastWin = win
	cash += win
	if win != 0 do history_push(win)

	if cash == 0 {
		gameState = .Lose
	} else if cash >= 1_000_000 {
		gameState = .Win
	}

}

history_push :: proc(entry: int) {
	historyRing[historyIdx] = entry
	historyIdx = (historyIdx + 1) % len(historyRing)
}

increase_bet :: proc() {
	max_idx := len(POSSIBLE_BETS) - 1
	betIdx = min(betIdx + 1, max_idx)
}

decrease_bet :: proc() {
	betIdx = max(betIdx - 1, 0)
}
