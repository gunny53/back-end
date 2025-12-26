import strutils

type RoutePattern* = ref object
  raw*:           string      # Đường dẫn gốc của route
  paramSegments*: seq[string] # Các tham số động trong đường dẫn

func parseRoutePattern*(pattern: string): RoutePattern =
  var paramSegments: seq[string] = @[]
  let parts = pattern.strip(chars = {'/'}).split("/")
  for part in parts:
    if part.startsWith(":"):
      let name = part[1..^1]
      paramSegments.add(name)
  result = RoutePattern(raw: pattern, paramSegments: paramSegments)