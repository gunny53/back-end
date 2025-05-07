import delegate, ../controller/base

# Lưu thông tin của 1 route
type RouteRegister*[T: BaseController] = ref object
  path*:     string                # Đường dẫn của route
  delegate*: ControllerDelegate[T] # Delegate cho route (controller + handler)