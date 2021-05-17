# ♟️ FENGEN

An attempt at implementing a multi-class classification neural network for generating FEN strings.

![board](board.jpeg)

## Structure

| Codebase         |                            Description                            |
| :--------------- | :---------------------------------------------------------------: |
| [waffle](waffle) | Contains the notebook, and livebook for model creation & training |
| [pho](pho)       |                            Web server                             |

If you need a guide in setting up each project, then check their READMEs.

## Dependencies

You'll need to setup `asdf` and its plugins: `asdf-elixir`, `asdf-erlang`, and `asdf-bazel`.
Although for `asdf-erlang`, you'll need to refer to [this](https://github.com/asdf-vm/asdf-erlang) to 
make sure you have all of `erlang` dependencies first.

```bash
# In project root directory

asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
asdf plugin-add bazel https://github.com/rajatvig/asdf-bazel.git

# Installs `elixir`, `erlang`, and `bazel`.
asdf install

# Activates a nix shell environment.
nix-shell
```

If you would like to use your own package manager(s), then feel free to take a peek at `.tool-versions`, and `shell.nix` to get the dependencies and their versions.

## TODO

Ideally, I'd like to nixify the entire process from preparing the dev environment to producting artifacts. But I have a lot of things to explore with `nix` before I can use it effectively.

- [ ] Elixir & Erlang - Elixir 1.12 has not been released yet, as such, it does not exist in `nix`. In the meantime, a temporary measure would be to use `asdf-vm` to grab the release candidate. When it happens, `nix` can handle Elixir, and Erlang.
- [ ] Bazel -Bazel is a pain to handle since `waffle` requires a specific version, 3.1.0, and currently I haven't read that much about specifying a specific version of a package with `nix`.

## Credits

- Pavel Koryakin for the dataset https://www.kaggle.com/koryakinp/chess-positions
