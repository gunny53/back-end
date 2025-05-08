import asyncdispatch, ../guard, macros, ../controller/base, tables

type ControllerDelegate* = ref object
  instance*: BaseController                                                # Instance của controller
  handler*:  proc (this: BaseController): Future[void] {.gcsafe, closure.} # Hàm xử lý request
  guards*:   seq[Guard]                                                    # Các guards áp dụng cho phương thức

# Lưu thông tin function handler cho request, bao gồm controller instance, guards, handler function
macro collect*[T: BaseController](ctlClass: typedesc[T], handler: untyped): ControllerDelegate =
  let className  = $ctlClass 
  let methodName = $handler
  result         = quote do:
    # Ép kiểu về kiểu gốc
    let hand = proc (this: BaseController): Future[void] {.gcsafe, closure.} =
      let ctrl = cast[`ctlClass`](this)
      `handler`(ctrl)
    # Phát hiện các guards và lưu vào bộ nhớ quản lý guards của instance controller
    let controllerInst = controllerRegistry[`className`]
    let guards         = controllerInst.getGuards(`methodName`)
    ControllerDelegate(
      instance: cast[`ctlClass`](controllerInst),
      handler:  hand,
      guards:   guards
    )