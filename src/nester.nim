import asyncdispatch, asynchttpserver, jsony
import packages/common/decorators/core/controller

type User = object
  id:   int
  name: string

type
  Database* = ref object
    name: string

  Repository* = ref object
    db: Database

proc newDatabase*(): Database =
  Database(name: "PostgreSQL")

proc newRepository*(db: Database): Repository =
  Repository(db: db)

Controller(""):
  Get("/admins"):
    proc getAdmins(req: Request) {.async.} =
      echo "controller getAdmins processing request"
      await req.Bad(newRepository(newDatabase()))

  Get("/"):
    proc index(req: Request) {.async.} =
      echo "controller getAdmins processing request"
      await req.Ok($Http413)

  Get("/a"):
    proc index2(req: Request) {.async.} =
      echo "controller getAdmins processing request"
      await req.Ok(nil)

  Post("/products"):
    proc getProducts(req: Request) {.async.} =
      let user = User(id: 1, name: "Alice")
      echo "controller products processing request"
      await req.Ok(user)