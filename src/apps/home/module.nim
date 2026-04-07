import ../../nim_http/kernel/module
import ./main               # Load controller registration side effects
import ./services/provider  # Load provider registration side effects
import ./services/log
import ./services/user

let HomeModule* = newModuleDescriptor(
  name = "HomeModule",
  providers = [LogService, UserService],
  exports = [UserService],
  controllers = [Home]
)

proc registerHomeModule*(registry: var ModuleRegistry) =
  registry.registerModule(HomeModule)
