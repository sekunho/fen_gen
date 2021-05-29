FROM docker.io/nixos/nix:2.3 AS builder

WORKDIR /opt/app

# TODO: This doesn't work yet
ENV LANG=C.UTF-8

## Cache nix derivations

COPY nix nix
RUN apk --no-cache --update add git && \
    nix-shell nix/packages.nix --run exit

## Build mix release

COPY assets assets
COPY mix.* .
COPY lib lib
COPY priv priv
COPY default.nix .
COPY config config

RUN nix-build default.nix && \
    mkdir /tmp/nix-store-closure
  
RUN echo "Output references (Runtime dependencies):" $(nix-store -qR result/)
RUN cp -R $(nix-store -qR result/) /tmp/nix-store-closure

ENTRYPOINT [ "/bin/sh" ]

FROM docker.io/alpine

EXPOSE 8080

# TODO: This doesn't work yet
ENV LANG=C.UTF-8
WORKDIR /opt/app

COPY --from=builder /tmp/nix-store-closure /nix/store
COPY --from=builder /opt/app/result /opt/app

CMD ["prod/rel/fen_gen/bin/fen_gen", "start"]
