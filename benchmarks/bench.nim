import times
import nim_http/kernel/di
import nim_http/kernel/module

type LeafService = ref object of SingletonObj

let leaf = newModuleDescriptor(
  name = "BenchmarkLeafModule",
  providers = [LeafService],
  exports = [LeafService]
)
let root = newModuleDescriptor(
  name = "BenchmarkRootModule",
  imports = [leaf]
)

var registry = newModuleRegistry()
registry.registerModule(leaf)
registry.registerModule(root)

let startedAt = cpuTime()
for _ in 0 .. 500:
  discard validateGraph(registry, [root])
let durationMs = (cpuTime() - startedAt) * 1000

echo "module_graph_iterations=501"
stdout.writeLine "module_graph_duration_ms=" & $durationMs
