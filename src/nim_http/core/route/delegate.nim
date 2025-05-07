import asyncdispatch, ../guard

type ControllerDelegate*[T] = ref object
  instance*: T                                                # Instance của controller
  handler*:  proc (this: T): Future[void] {.gcsafe, closure.} # Hàm xử lý request
  guards*:   seq[Guard]                                       # Các guards áp dụng cho phương thức
