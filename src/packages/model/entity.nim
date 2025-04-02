import options, strutils

type
  Id*            = distinct int
  EntityModelBase[T] = object of RootObj
    id*:    Option[Id] = none(Id)
    value*: T
  EmbeddedId[T] = object of EntityModelBase[T]
  WithNoId  [T] = object of EntityModelBase[T]

type User* = object
  id*:   Option[Id]
  name*: string

# ✅ Constructor helper
proc EntityEmbeddedId*[T](id: auto, value: T): EmbeddedId[T] = EntityModelBase[T](id: some(Id id), value: value).toEmbeddedId()
proc EntityWithNoId*  [T](          value: T):   WithNoId[T] = EntityModelBase[T](                 value: value).toWithNoId()

# Proc convert EntityModelBase
proc toEmbeddedId[T](self: EntityModelBase[T]): EmbeddedId[T] = EmbeddedId[T](id: self.id,  value: self.value)
proc   toWithNoId[T](self: EntityModelBase[T]):   WithNoId[T] =   WithNoId[T](id: none(Id), value: self.value)

proc EntityModel*[T](id: Option[Id] = none(Id), value: T): auto =
  if id.isNone():
    WithNoId[T](id: none(Id), value: `value`)
  else:
    EmbeddedId[T](id: `id`, value: `value`)

# Kiểm thử
let user1 = EntityEmbeddedId(123456, User(name: "hieuht"))  # ID là string
let user3 = EntityWithNoId("No ID")  # Không có ID
let user4 = EntityModel[string](value = "dm")
let user5 = EntityModel[string](some(Id 123456), value = "dm")

echo  user1.value.name
echo typeOf user3
echo typeOf user4
echo intToStr(int user5.id.get)