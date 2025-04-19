import main
import ../../nim_http/core/[controller, router, guard]
import asynchttpserver, tables

Get    "/"                      -> HomeController / index
Post   "/:id"                   -> HomeController / index
Get    "/agent/:id/avatar/:aid" -> HomeController / index
Get    "/about"                 -> HomeController / about
Get    "/b"                     -> HomeController / about
Put    "/c"                     -> HomeController / about
Delete "/d"                     -> HomeController / about