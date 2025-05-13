import asynchttpserver, tables, json

type RequestContext* = object
  raw*:        Request
  attributes*: TableRef[string, JsonNode]

proc new*(this: Request): RequestContext =
  RequestContext(raw: this, attributes: newTable[string, JsonNode]())

# Add attribute
proc setAttr*(this: RequestContext, key: string, val: JsonNode) =
  this.attributes[key] = val