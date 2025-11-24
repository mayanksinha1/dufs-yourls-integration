# Build stage - use Rust to build dufs from source
FROM rust:alpine AS builder

# Install build dependencies
RUN apk add --no-cache musl-dev openssl-dev openssl-libs-static git

# Set working directory
WORKDIR /app

# Clone dufs repository (using specific version tag for reproducibility)
RUN git clone --depth 1 --branch v0.45.0 https://github.com/sigoden/dufs.git .

# Build dufs in release mode
RUN cargo build --release --target x86_64-unknown-linux-musl

# Runtime stage - use the hardened Alpine image
FROM artifactory.dev.adskengineer.net/container-hardening/alpine-hardened-min:latest AS amd64
USER root

# Install runtime dependencies if needed
RUN apk update && apk upgrade && \
    apk add --no-cache libgcc

# Copy the built binary from builder stage
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/dufs /usr/local/bin/dufs

# Make binary executable
RUN chmod +x /usr/local/bin/dufs

# Create data directory and set ownership for ctr-user
RUN mkdir -p /data && \
    chown -R ctr-user:ctr-user /data && \
    chmod 755 /data

# Expose port 5000 (dufs default port)
EXPOSE 5000

# Switch to non-root user
USER ctr-user

# Set working directory
WORKDIR /data

# Run dufs on port 5000, serving the /data directory
CMD ["/usr/local/bin/dufs", "/data", "--port", "5000", "--allow-all"]
#EOF
