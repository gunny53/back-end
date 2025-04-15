import main as ctl
import asynchttpserver
import ../../nim_http/core/router

route(HttpGet, "/",      HomeController, ctl.index)
route(HttpGet, "/about", HomeController, ctl.about)