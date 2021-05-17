FROM livebook/livebook

ENV BAZEL_URL=https://github.com/bazelbuild/bazel/releases/download/3.1.0/bazel-3.1.0-linux-x86_64

RUN apk update && apk upgrade && \
    apk add --no-cache --update \
    build-base curl gcc erlang-dev && \
    curl -sLO ${BAZEL_URL} && \
    mv bazel-3.1.0-linux-x86_64 /usr/local/bin/bazel && \
    chmod +x /usr/local/bin/bazel
