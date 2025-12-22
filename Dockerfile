FROM golang:1.21-alpine AS builder

WORKDIR /build

# Install build dependencies
RUN apk add --no-cache git ca-certificates

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY main.go ./

# Build static binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -a \
    -installsuffix cgo \
    -ldflags '-extldflags "-static" -w -s' \
    -o mongo-telegraf-query \
    .

# Final stage - based on official Telegraf image
FROM telegraf:1.29-alpine

# Copy binary from builder
COPY --from=builder /build/mongo-telegraf-query /usr/local/bin/mongo-telegraf-query

# Ensure binary is executable
RUN chmod +x /usr/local/bin/mongo-telegraf-query

# Create directory for query configurations
RUN mkdir -p /etc/telegraf/queries

# Verify binary exists and is executable
RUN ls -l /usr/local/bin/mongo-telegraf-query

# Use default telegraf entrypoint
# ENTRYPOINT ["/entrypoint.sh"]
# CMD ["telegraf"]
