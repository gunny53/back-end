import asynchttpserver, asyncdispatch, tables, sequtils, strutils

type ApplicationFactory* = object
  controllers: seq[string]

proc registerModule*(app: var ApplicationFactory, moduleName: string) =
  app.controllers.add(moduleName)

proc start*(app: ApplicationFactory, port: Port) =
  echo "[INFO] Available Controllers:", app.controllers