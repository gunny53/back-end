# Stage 1: Build
FROM alpine:latest AS builder

# Cài đặt các gói cần thiết cho biên dịch
RUN apk add --no-cache nim nimble musl-dev git build-base libgcc libstdc++ musl pcre

# Tạo thư mục làm việc
WORKDIR /app

# Copy source code vào container
COPY src/ .

# Build app bằng musl để tương thích Alpine
RUN nim c \
    --define:release \
    --threads:on \
    --outdir:"." \
    main.nim

# Stage 2: Final (runtime only)
FROM alpine:latest

RUN apk add --no-cache libgcc libstdc++ pcre

# Tạo thư mục app
WORKDIR /app

# Copy binary từ stage build
COPY --from=builder /app/main .

# Gán quyền thực thi (cẩn thận nếu host copy sang mà mất chmod)
RUN chmod +x ./main

# Chạy ứng dụng
CMD ["./main"]