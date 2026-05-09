  docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -t mlorber/public:pgquarrel-compare-80637e4-pg18.0 \
    --push \
    .