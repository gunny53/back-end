import ../../nim_http/kernel/module
import ./main
import ./services/provider

let HomeModule* = newModuleDescriptor(
  name = "HomeModule",
  providers = ["LogService", "UserService"],
  exports = ["UserService"],
  controllers = ["Home"]
)
