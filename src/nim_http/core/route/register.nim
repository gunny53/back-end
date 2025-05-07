import delegate

# Lưu thông tin của 1 route
type RouteRegister*[T] = ref object
  path*:     string                # Đường dẫn của route
  delegate*: ControllerDelegate[T] # Delegate cho route (controller + handler)