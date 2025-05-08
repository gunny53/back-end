import ../../../nim_http/core/di

singleton UserService of SingletonObj:
  func name*(this: UserService): string = return "hi8eu"
    