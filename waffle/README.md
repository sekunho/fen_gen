# 🧇 waffle

Livebook configured for what `waffle` needs.

## (WIP) Setup

```bash
# In project root directory
git submodule init
git submodule update

# In `waffle` root directory
cd livebook
mix deps.get --only prod
MIX_ENV=prod mix escript.build

./livebook server --root-path ../notebook
# [Livebook] Application running at http://localhost:8080/?token=<TOKEN>
```

Open the link as it will authenticate your session.