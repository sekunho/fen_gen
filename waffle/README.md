# 🧇 waffle

Livebook configured for what `waffle` needs. This assumes that you are in a Debian-based system, specifically Ubuntu.

## (WIP) Setup

```bash
sudo apt install erlang-dev build-essential

# In `waffle` root directory
cd livebook
mix deps.get --only prod
MIX_ENV=prod mix escript.build

./livebook server --root-path ../notebook
# [Livebook] Application running at http://localhost:8080/?token=oiyxnk4z7cus2ncltpxnb56ml3osqkhy
```

Open the link as it will authenticate your session.