import re

# Lưu thông tin meta của route dưới dạng regex pattern
type RoutePattern* = ref object
  raw*:           string      # Đường dẫn gốc của route
  regex*:         Regex       # Biểu thức chính quy dùng để so khớp URL
  paramSegments*: seq[string] # Các tham số động trong đường dẫn