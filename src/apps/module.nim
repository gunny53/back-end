import ../nim_http/kernel/module
import ./home/module as homeModule

let ApplicationModule* = newModuleDescriptor(
  name = "ApplicationModule",
  imports = ["HomeModule"]
)

proc configureApplicationModules*(registry: var ModuleRegistry) =
  registry.registerHomeModule()
  registry.registerModule(ApplicationModule)

export homeModule
