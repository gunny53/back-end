import ../../../nim_http/core/di

type LogService* {.singleton.} = ref object of BaseSingleton
  name*: string = "logger"

Injectable(LogService)