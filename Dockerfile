FROM docker.io/nixos/nix:2.3 AS builder

RUN nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
RUN nix-channel --update

WORKDIR /opt/app

# TODO: This doesn't work yet
ENV LANG=C.UTF-8

RUN apk --no-cache --update add git

## Cache packages

COPY nix/packages.nix nix/packages.nix
RUN nix-shell nix/packages.nix --run exit

## Build mix release

COPY assets assets/
COPY mix.* ./
COPY lib lib/
COPY priv priv/
COPY default.nix ./
COPY nix/runtime.nix nix/runtime.nix
COPY config config/

RUN nix-build default.nix

FROM docker.io/nixos/nix:2.3

EXPOSE 8080

# TODO: This doesn't work yet
ENV LANG=C.UTF-8
ENV APP_PORT=8080

WORKDIR /opt/app

RUN apk --no-cache --update add git

COPY --from=builder /opt/app/result /opt/app/
COPY --from=builder /opt/app/nix/runtime.nix /opt/app/nix/runtime.nix

RUN nix-env --install --file nix/runtime.nix && \
    nix-collect-garbage

CMD ["prod/rel/fen_gen/bin/fen_gen", "start"]
