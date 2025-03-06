FROM nimlang/nim:2.2.0-alpine-regular as nim
LABEL maintainer="setenforce@protonmail.com"
RUN apk --no-cache add libsass-dev pcre
WORKDIR /src/nitter
COPY nitter.nimble .
RUN nimble install -y --depsOnly
COPY . .
RUN nimble build -d:danger -d:lto -d:strip --mm:refc \
    && nimble scss \
    && nimble md

FROM alpine:latest
WORKDIR /src/
RUN apk --no-cache add pcre ca-certificates

# Copy Nitter files from build stage
COPY --from=nim /src/nitter/nitter ./
COPY --from=nim /src/nitter/public ./public

# Copy your custom nitter.conf instead of the example one
COPY nitter.conf ./nitter.conf

# Create a start script that will generate the sessions file from env var
RUN echo '#!/bin/sh' > start.sh && \
    echo 'echo "$SESSIONS_CONTENT" > /src/sessions.jsonl' >> start.sh && \
    echo 'echo "Created sessions.jsonl file from environment variable"' >> start.sh && \
    echo 'exec ./nitter' >> start.sh && \
    chmod +x start.sh

EXPOSE 8080

# Add the nitter user and set permissions
RUN adduser -h /src/ -D -s /bin/sh nitter && \
    chown -R nitter:nitter /src/

USER nitter
CMD ["./start.sh"]
