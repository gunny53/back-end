import ../nim_http/kernel/module
import ./home/module as homeModule

let ApplicationModule* = newModuleDescriptor(
  name = "ApplicationModule",
  imports = ["HomeModule"]
)

registerModule(ApplicationModule)

export homeModule
