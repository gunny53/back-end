import asynchttpserver, tables, json

type RequestContext* = object
  raw*:        Request
  attributes*: TableRef[string, JsonNode]

func new*(this: Request): RequestContext =
  RequestContext(raw: this, attributes: newTable[string, JsonNode]())

# Add attribute
func attr*(this: RequestContext, key: string, val: JsonNode): void =
  this.attributes[key] = val

func attr*(this: RequestContext, key: string): JsonNode =
  if this.attributes.hasKey(key):
    return this.attributes[key]
  return newJNull()