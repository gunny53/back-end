import main
import ../../nim_http/core/[controller, router]
import asynchttpserver, tables

Get  "/"                        -> HomeController / index
Post "/:id"                     -> HomeController / index
Get  "/agent/:id/avatar/:aid"   -> HomeController / index
Get  "/about"                   -> HomeController / about
Get  "/test"                    -> HomeController / about
Get  "/a"                       -> HomeController / about
Get  "/b"                       -> HomeController / about
Get  "/c"                       -> HomeController / about
Get  "/d"                       -> HomeController / about