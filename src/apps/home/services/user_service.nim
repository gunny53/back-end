import ../../../nim_http/core/di

type UserService* = ref object of BaseSingleton
  name*: string = "hieuht"

Injectable(UserService)