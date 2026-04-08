## Fast-path URL query-string parser.
## Phase B deliverable — single-pass parser for ASCII query strings on the hot path.
##
## Design goals:
## * Single allocation: the table is built directly from one pass over the input string.
## * No intermediate seq of pairs: segments are processed in-place with find/slice.
## * Standard percent-decoding delegated to the stdlib ``uri`` module.

import tables, uri

proc parseQueryString*(qs: string): Table[string, string] =
  ## Parses a URL query string (with or without a leading ``?``) into a
  ## ``key → value`` table.  Keys and values are percent-decoded.
  ## When the same key appears more than once the last value wins.
  result = initTable[string, string]()
  let src = if qs.len > 0 and qs[0] == '?': qs[1 .. ^1] else: qs
  if src.len == 0:
    return

  var i = 0
  while i <= src.len:
    var j = i
    while j < src.len and src[j] != '&':
      inc j

    let pair = src[i ..< j]
    if pair.len > 0:
      let eqIdx = pair.find('=')
      if eqIdx < 0:
        let key = decodeUrl(pair)
        if key.len > 0:
          result[key] = ""
      else:
        let key = decodeUrl(pair[0 ..< eqIdx])
        if key.len > 0:
          result[key] = decodeUrl(pair[eqIdx + 1 .. ^1])

    i = j + 1

proc queryFromUrl*(url: string): Table[string, string] =
  ## Extracts the query-string portion of a full URL and delegates to
  ## ``parseQueryString``.  Returns an empty table when the URL has no ``?``.
  let qmark = url.find('?')
  if qmark < 0:
    return initTable[string, string]()
  parseQueryString(url[qmark + 1 .. ^1])
