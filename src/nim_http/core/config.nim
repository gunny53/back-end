## Configuration Module
## Provides environment-based configuration management

import tables, os, strutils

type
  ConfigurationError* = object of CatchableError

  ConfigService* = ref object
    values: TableRef[string, string]

var globalConfigService {.threadvar.}: ConfigService

proc newConfigService*(): ConfigService =
  ## Creates a new configuration service instance
  result = ConfigService(
    values: newTable[string, string]()
  )

proc loadFromEnv*(config: ConfigService) =
  ## Loads configuration from environment variables
  for key, val in envPairs():
    config.values[key] = val

proc loadFromFile*(config: ConfigService, filepath: string) =
  ## Loads configuration from a .env file
  if not fileExists(filepath):
    return
  
  let content = readFile(filepath)
  for line in content.splitLines():
    let trimmed = line.strip()
    if trimmed.len == 0 or trimmed.startsWith("#"):
      continue
    
    let parts = trimmed.split('=', maxsplit=1)
    if parts.len == 2:
      let key = parts[0].strip()
      let val = parts[1].strip()
      # Only set if not already in environment
      if not config.values.hasKey(key):
        config.values[key] = val

proc get*(config: ConfigService, key: string): string =
  ## Gets a configuration value by key
  ## Raises ConfigurationError if key doesn't exist
  if not config.values.hasKey(key):
    raise newException(ConfigurationError, "Configuration key '" & key & "' not found")
  result = config.values[key]

proc get*(config: ConfigService, key: string, default: string): string =
  ## Gets a configuration value by key with default fallback
  if config.values.hasKey(key):
    return config.values[key]
  return default

proc getInt*(config: ConfigService, key: string, default: int = 0): int =
  ## Gets a configuration value as integer
  let val = config.get(key, $default)
  try:
    return parseInt(val)
  except ValueError:
    return default

proc getBool*(config: ConfigService, key: string, default: bool = false): bool =
  ## Gets a configuration value as boolean
  let val = config.get(key, $default).toLowerAscii()
  return val in ["true", "1", "yes", "on"]

proc getFloat*(config: ConfigService, key: string, default: float = 0.0): float =
  ## Gets a configuration value as float
  let val = config.get(key, $default)
  try:
    return parseFloat(val)
  except ValueError:
    return default

proc set*(config: ConfigService, key: string, value: string) =
  ## Sets a configuration value
  config.values[key] = value

proc has*(config: ConfigService, key: string): bool =
  ## Checks if a configuration key exists
  return config.values.hasKey(key)

proc initGlobalConfig*() =
  ## Initializes the global configuration service
  if globalConfigService.isNil:
    globalConfigService = newConfigService()
    
    # Load from .env file if exists
    globalConfigService.loadFromFile(".env")
    
    # Override with environment variables
    globalConfigService.loadFromEnv()

proc getConfig*(): ConfigService =
  ## Gets the global configuration service instance
  if globalConfigService.isNil:
    initGlobalConfig()
  return globalConfigService
