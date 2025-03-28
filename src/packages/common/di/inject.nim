import macros, asynchttpserver, asyncdispatch, tables, strutils, jsony

var singletonContainer* {.threadvar.}: Table[string, NimNode] = initTable[string, NimNode]()

macro Inject*(T: typed, providers: varargs[typed]): untyped =
  var providerMap = initTable[string, NimNode]()

  for provider in providers:
    if provider.kind == nnkCall:
      let providerName = $provider[0]
      providerMap[providerName] = provider
    else:
      error("Invalid provider: " & repr(provider))

  proc resolveDependency(depType: string): NimNode =
    if providerMap.hasKey(depType):
      let provider = providerMap[depType]

      if singletonContainer.hasKey(depType):
        return singletonContainer[depType]  # Trả về instance đã được lưu

      var args: seq[NimNode] = @[]

      # Xử lý danh sách tham số thủ công thay vì dùng `map`
      if provider.len > 2:
        for param in provider[2..^1]:
          let paramType = $param.getType
          if paramType.len > 0:
            args.add(resolveDependency(paramType))
          else:
            error("Cannot determine type for parameter: " & repr(param))

      let instance = newCall(provider[0], args)

      # Lưu vào singletonContainer
      singletonContainer[depType] = instance
      return instance
    else:
      error("Cannot resolve dependency: " & depType)

  result = resolveDependency($T)
