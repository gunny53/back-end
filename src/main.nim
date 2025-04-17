import nim_http/core/app
import apps/home/routes

let settings = NimHttpApplicationSettings()
settings.host = "127.0.0.1"
settings.port = 8888
NimHttpApplication(settings: settings).listen