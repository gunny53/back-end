import nim_http/core/app
import libs/error/handle
import apps/home/routes

let settings         = NimHttpApplicationSettings()
settings.host        = "127.0.0.1"
settings.port        = 8888
settings.errorHandle = HttpErrorHandle()
NimHttpApplication(settings: settings).listen