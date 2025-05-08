import ../../../nim_http/core/di

type LogService* = ref object of SingletonObj
  name*: string = "logger"

Injectable(LogService)