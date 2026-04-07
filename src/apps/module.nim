import ../nim_http/kernel/module
import ./home/module as homeModule
import ./health/module as healthModule

let ApplicationModule* = newModuleDescriptor(
  name = "ApplicationModule",
  imports = ["HomeModule", "HealthModule"]
)

proc configureApplicationModules*(registry: var ModuleRegistry) =
  registry.registerHealthModule()
  registry.registerHomeModule()
  registry.registerModule(ApplicationModule)

export homeModule, healthModule
