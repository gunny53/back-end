import ../../nim_http/http/controller
import ../../nim_http/platform/config
import ../../nim_http/platform/health

Controller Health("health"):

  [GET("live")]
  proc live() =
    let appName = getConfig().get("APP_NAME", "NimHTTP Framework")
    Http200 livenessProbe(appName)

  [GET("ready")]
  proc ready() =
    let appName = getConfig().get("APP_NAME", "NimHTTP Framework")
    Http200 readinessProbe(appName)
