import ../../nim_http/kernel/module
import ./main  # Load controller registration side effects

let HealthModule* = newModuleDescriptor(
  name = "HealthModule",
  controllers = ["HealthCheck"]
)

proc registerHealthModule*(registry: var ModuleRegistry) =
  registry.registerModule(HealthModule)
