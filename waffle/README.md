# 🧇 waffle

Livebook configured for what `waffle` needs. This assumes that you are in a Debian-based system, specifically Ubuntu.

## (WIP) Checklist

You'll need to install NVIDIA drivers with CUDA on your machine. Nix tries to take care of as much dependencies as possible. If you're unable to use Nix, try to check the dependencies required in `shell.nix`, which can be found at the root directory of this project.

- [ ] NVIDIA drivers
- [ ] [`libnvidia-container`](https://github.com/NVIDIA/libnvidia-container)
- [ ] [`nvidia-docker`](https://github.com/NVIDIA/nvidia-docker)
- [ ] [For podman](https://gist.github.com/bernardomig/315534407585d5912f5616c35c7fe374)

## (WIP) Setup

```bash
# Prepare Livebook for `waffle`
podman build waffle -t livebook:latest

# Run Livebook
podman run -p 8080:8080 -v ./waffle/notebook:/data --privileged localhost/livebook
```

Check console, and it should provide a link with the token needed to authenticate the session.