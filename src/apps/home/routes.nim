import main as ctl
import asynchttpserver
import ../../nim_http/core/[controller, router]

Route(HttpGet, "/",      ctl.index)    
Route(HttpGet, "/about", ctl.about)

routes:
  path("/", component = ctl.index):
    path("about", component = ctl.about)
