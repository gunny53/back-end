import log, user
import ../../../nim_http/kernel/di
import ../../../nim_http/kernel/module

Injectable:
  LogService
  UserService

proc homeProviderTokens*(): seq[ProviderToken] =
  @[LogService, UserService]

proc homeExportTokens*(): seq[ProviderToken] =
  @[UserService]
