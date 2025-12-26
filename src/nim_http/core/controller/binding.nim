import macros, asyncdispatch, asynchttpserver, macrocache, tables, sequtils, strutils, ../utils, uri, json, options, ../exception

func parseParamStmt*(
  identName:    NimNode,
  identNameStr: string,
  identType:    NimNode
): NimNode =
  let identTypeStr = $identType
  let body         = newStmtList()
  case identTypeStr
  of $int, $int32, $int64:
    body.add quote do: parseInt(this.params[`identNameStr`])
  of $float, $float32, $float64:
    body.add quote do: parseFloat(this.params[`identNameStr`])
  of $bool:
    body.add quote do: parseBool(this.params[`identNameStr`])
  else:
    body.add quote do: this.params[`identNameStr`]
  result = quote do:
    let `identName` = try: `body` 
    except Exception as e:
      discard this.request.respond(HttpCode(400), e.msg)
      raise BAD_REQUEST(e.msg)

# Hàm parse query
func parseQueryStmt*(
  identName:    NimNode,
  identNameStr: string,
  identType:    NimNode,
  defaultVal:   NimNode
): NimNode =
  result = quote do:
    let `identName`: `identType` = this.request.url.query
      .split("&")
      .mapIt(it.split("=", maxsplit = 1))
      .filterIt(it.len == 2 and it[0] == `identNameStr`)
      .mapIt(decodeUrl(it[1]))
      .headOption()
      .flatMap(parseOrNone[`identType`]).getOrElse(`defaultVal`)

# Hàm parse raw body to Dto class
func parseBodyStmt*(
  identName:    NimNode,
  identNameStr: string,
  identType:    NimNode
): NimNode =
  result = quote do:
    let `identName`: `identType` = 
      try: to(parseJson(this.request.body), `identType`) 
      except Exception as e: raise BAD_REQUEST(e.msg)