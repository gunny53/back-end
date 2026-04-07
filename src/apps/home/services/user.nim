import ../../../nim_http/kernel/di, log

class UserService*(*name: string, *log: LogService) of SingletonObj
