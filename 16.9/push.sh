  docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -t mlorber/public:pgquarrel-compare-0_7_0-pg16.9 \
    --push \
    .