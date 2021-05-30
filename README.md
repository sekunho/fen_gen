# FENGEN

![demo](https://user-images.githubusercontent.com/20364796/119956571-bfdc1700-bf90-11eb-8701-15fdf3847394.gif)

Generate FEN strings given a chess board image.

## About

### Web server

FENGEN handles the image uploads, FEN-to-board state translation, and communication with the process running [predict.py](priv/scripts/predict.py).

### Prediction

The `predict.py` script is ran by a GenServer worker/process, which is "replicated", and managed by `poolboy`. So task distribution is handled by it. The results are flushed to `stdout`, which notifies the port that there's a prediction that has been made.

## Deploy to DO

[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/imsekun/fen_gen/tree/main)

## Dev Setup

Ensure you have the `nix` package manager. If you're using NixOS then you can skip this.

```bash
curl -L https://nixos.org/nix/install | sh
```

Activate the nix environment to fetch necessary dependencies. This also automatically pulls a Postgres 13 image.

```bash
nix-shell --pure
```

If you want to open your IDE/text editor within the environment, you can do so within it.

```bash
# If you're using VSCode. Unfortunately, you'll need more 
# configuration if you've installed it through Flatpak.
code .
```

Setup the remaining things.

```bash
mix setup
```

Run the server

```bash
mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## License

[FENGEN](https://github.com/imsekun/fen_gen)'s code is licensed under [MIT](LICENSE).

## Credits

- Pavel Koryakin for the dataset https://www.kaggle.com/koryakinp/chess-positions
- Colin M.L. Burnett for the chess set assets. (LICENSED UNDER GPLv2+)
