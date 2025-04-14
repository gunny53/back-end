import ../../../nim_http/core/di

type LogService* = ref object of BaseSingleton
  name*: string = "logger"

RegisterSingletons(LogService)