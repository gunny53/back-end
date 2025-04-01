import options

type
  Id* = distinct int

  EntityModel*[T] = object of RootObj
    id*:    Option[Id]
    value*: T

  EmbeddedId*[T] = object of EntityModel[T]
  WithNoId*[T]   = object of EntityModel[T]

type User* = object
  id*: Option[Id]
  name*: string

# ✅ Constructor helper
proc EntityEmbeddedId*[T](id: auto, value: T): EmbeddedId[T] =
  EntityModel[T](id: some(Id id), value: value).toEmbeddedId()

proc EntityWithNoId*[T](value: T): WithNoId[T] =
  EntityModel[T](id: none(Id), value: value).toWithNoId()

proc toEmbeddedId*[T](self: EntityModel[T]): EmbeddedId[T] =
  EmbeddedId[T](id: self.id, value: self.value)

proc toWithNoId*[T](self: EntityModel[T]): WithNoId[T] =
  WithNoId[T](id: none(Id), value: self.value)

# Kiểm thử
let user1 = EntityEmbeddedId(123456, User(name: "hieuht"))  # ID là string
let user3 = EntityWithNoId("No ID")  # Không có ID

echo  user1.value.name
echo typeOf user3