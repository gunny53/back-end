## Helper Utilities Module
## Common utility functions for the framework

import times, strutils, json, tables, md5, base64, random

# =================== String Utilities ===================

proc slugify*(text: string): string =
  ## Converts text to URL-friendly slug
  result = text.toLowerAscii()
    .replace(" ", "-")
    .replace("_", "-")
  var cleaned = ""
  for ch in result:
    if ch in {'a'..'z', '0'..'9', '-'}:
      cleaned.add(ch)
  result = cleaned

proc truncate*(text: string, maxLen: int, suffix: string = "..."): string =
  ## Truncates text to maximum length with suffix
  if text.len <= maxLen:
    return text
  return text[0..<(maxLen - suffix.len)] & suffix

proc pascalCase*(text: string): string =
  ## Converts text to PascalCase
  let parts = text.split({'_', '-', ' '})
  result = ""
  for part in parts:
    if part.len > 0:
      result.add(part[0].toUpperAscii())
      if part.len > 1:
        result.add(part[1..^1])

proc camelCase*(text: string): string =
  ## Converts text to camelCase
  result = pascalCase(text)
  if result.len > 0:
    result[0] = result[0].toLowerAscii()

proc snakeCase*(text: string): string =
  ## Converts text to snake_case
  result = ""
  for i, ch in text:
    if ch.isUpperAscii() and i > 0:
      result.add('_')
      result.add(ch.toLowerAscii())
    else:
      result.add(ch.toLowerAscii())

# =================== Hash & Crypto Utilities ===================

proc hashMD5*(text: string): string =
  ## Generates MD5 hash of text
  return getMD5(text)

proc base64Encode*(text: string): string =
  ## Base64 encodes text
  return encode(text)

proc base64Decode*(encoded: string): string =
  ## Base64 decodes text
  return decode(encoded)

# =================== JSON Utilities ===================

proc safeParseJson*(text: string, default: JsonNode = newJNull()): JsonNode =
  ## Safely parses JSON with default fallback
  try:
    return parseJson(text)
  except JsonParsingError:
    return default

proc getOrNull*(node: JsonNode, key: string): JsonNode =
  ## Gets JSON value or null if not found
  if node.hasKey(key):
    return node[key]
  return newJNull()

proc getString*(node: JsonNode, key: string, default: string = ""): string =
  ## Gets string from JSON with default
  if node.hasKey(key) and node[key].kind == JString:
    return node[key].getStr()
  return default

proc getInt*(node: JsonNode, key: string, default: int = 0): int =
  ## Gets int from JSON with default
  if node.hasKey(key) and node[key].kind == JInt:
    return node[key].getInt()
  return default

proc getBool*(node: JsonNode, key: string, default: bool = false): bool =
  ## Gets bool from JSON with default
  if node.hasKey(key) and node[key].kind == JBool:
    return node[key].getBool()
  return default

proc getFloat*(node: JsonNode, key: string, default: float = 0.0): float =
  ## Gets float from JSON with default
  if node.hasKey(key):
    case node[key].kind:
    of JFloat:
      return node[key].getFloat()
    of JInt:
      return node[key].getInt().float
    else:
      discard
  return default

# =================== Time Utilities ===================

proc unixTimestamp*(): int64 =
  ## Gets current Unix timestamp in seconds
  return getTime().toUnix()

proc unixTimestampMs*(): int64 =
  ## Gets current Unix timestamp in milliseconds
  let t = getTime()
  return t.toUnix() * 1000 + (t.nanosecond div 1_000_000)

proc formatDateTime*(dt: DateTime, format: string = "yyyy-MM-dd HH:mm:ss"): string =
  ## Formats DateTime to string
  return dt.format(format)

proc formatTimeISO*(dt: DateTime): string =
  ## Formats DateTime to ISO8601 format
  return dt.format("yyyy-MM-dd'T'HH:mm:ss'Z'")

# =================== Collection Utilities ===================

proc distinct*[T](items: seq[T]): seq[T] =
  ## Returns distinct elements from sequence
  var seen = initTable[T, bool]()
  result = @[]
  for item in items:
    if not seen.hasKey(item):
      seen[item] = true
      result.add(item)

proc chunk*[T](items: seq[T], size: int): seq[seq[T]] =
  ## Splits sequence into chunks of specified size
  result = @[]
  var current: seq[T] = @[]
  
  for item in items:
    current.add(item)
    if current.len >= size:
      result.add(current)
      current = @[]
  
  if current.len > 0:
    result.add(current)

# =================== Validation Utilities ===================

proc isEmail*(email: string): bool =
  ## Validates email format (basic check)
  let atCount = email.count('@')
  if atCount != 1:
    return false
  
  let parts = email.split('@')
  if parts.len != 2:
    return false
  
  let localPart = parts[0]
  let domain = parts[1]
  
  return localPart.len > 0 and domain.len > 0 and domain.contains('.')

proc isURL*(url: string): bool =
  ## Validates URL format (basic check)
  return url.startsWith("http://") or url.startsWith("https://")

proc isNumeric*(text: string): bool =
  ## Checks if string is numeric
  if text.len == 0:
    return false
  
  for ch in text:
    if not ch.isDigit():
      return false
  
  return true

proc isAlphanumeric*(text: string): bool =
  ## Checks if string is alphanumeric
  if text.len == 0:
    return false
  
  for ch in text:
    if not (ch.isAlphaAscii() or ch.isDigit()):
      return false
  
  return true

# =================== Random Utilities ===================

proc randomString*(length: int, chars: string = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"): string =
  ## Generates random string of specified length
  randomize()
  result = ""
  for i in 0..<length:
    result.add(chars[rand(chars.len - 1)])

proc randomInt*(min: int, max: int): int =
  ## Generates random integer in range [min, max]
  randomize()
  return rand(max - min) + min

proc generateUUID*(): string =
  ## Generates a simple UUID-like string
  randomize()
  let hex = "0123456789abcdef"
  result = ""
  
  for i in 0..<32:
    if i in [8, 12, 16, 20]:
      result.add('-')
    result.add(hex[rand(15)])
  
  return result

# =================== Performance Utilities ===================

template benchmark*(name: string, code: untyped): untyped =
  ## Benchmarks code execution time
  let startTime = cpuTime()
  code
  let duration = (cpuTime() - startTime) * 1000
  echo "[BENCHMARK] ", name, ": ", duration, "ms"
