import asyncdispatch, asynchttpserver,
  packages/common/decorators/core/controller,
  packages/common/di/inject,
  jsony

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

let repo1 = Inject(Repository, newDatabase)

Controller(""):
  Get("/admins"):
    proc getAdmins(req: Request) {.async.} =
      echo "controller getAdmins processing request"
      await req.respond(Http200, repo1.db)

  Post("/products"):
    proc getProducts(req: Request) {.async.} =
      let user = User(id: 1, name: "Alice")
      echo "controller products processing request"
      await req.json(Http200, user)