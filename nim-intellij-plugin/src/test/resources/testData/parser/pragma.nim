proc fastHash(s: string): int {.inline, noSideEffect.} =
  result = s.len
