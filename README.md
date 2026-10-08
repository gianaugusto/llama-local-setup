# Run a local Qwen3 model on Windows

This repository contains a PowerShell script that downloads the latest llamafile release, downloads a Qwen3 Thinking GGUF model, and starts its local HTTP server.

The default model is `MaziyarPanahi/Qwen3-4B-Thinking-2507-GGUF`, using its `Qwen3-4B-Thinking-2507.Q4_K_M.gguf` quantization. This is an accessible 4B-parameter starting point; other model sizes and quantizations can be substituted with the script parameters. Check the model card for its license and requirements before using another model.

## Requirements

- 64-bit Windows 10 or Windows 11
- PowerShell 5.1 or newer
- Internet access for the initial downloads
- Several GB of free disk space and enough RAM for the chosen model

The default model is a multi-gigabyte download. In llamafile 0.10.x, Windows GPU acceleration may not be available, so plan to run on CPU.

## Run

Open PowerShell in this folder and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\setup-llama.ps1
```

The script stores the executable as `llamafile.exe` and the model under `models/`. It then starts the server at:

```text
http://127.0.0.1:8080
```

Keep the PowerShell window open while using the server. Press `Ctrl+C` to stop it. The server binds to localhost only, so it is not exposed to other devices on your network.

To download or update llamafile and the model without starting the server:

```powershell
.\setup-llama.ps1 -DownloadOnly
```

To choose a different GGUF model, provide the Hugging Face repository and the exact filename in that repository:

```powershell
.\setup-llama.ps1 `
  -ModelRepo "owner/model-GGUF" `
  -ModelFile "model.Q4_K_M.gguf"
```

To change the server port or context size:

```powershell
.\setup-llama.ps1 -Port 8081 -ContextSize 4096
```

## Downloads and references

- [llamafile releases](https://github.com/mozilla-ai/llamafile/releases)
- [Trending GGUF models on Hugging Face](https://huggingface.co/models?library=gguf&sort=trending)
- [Default Qwen3 Thinking GGUF model](https://huggingface.co/MaziyarPanahi/Qwen3-4B-Thinking-2507-GGUF)

The script checks GitHub's latest-release API each time and updates the executable when a newer release is available. The currently published release at the time this guide was written is `0.10.6`; the script does not pin that version.