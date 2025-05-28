
# 🧠 Using `kubectl-ai` with Ollama + Gemma on Windows

This guide walks through setting up and running `kubectl-ai` with an LLM (Large Language Model) locally on Windows using [Ollama](https://ollama.com) and the `gemma3:12b-it-qat` model.

---

## ✅ Prerequisites

- Windows 10/11 system
- Admin access or permission to modify `PATH`
- [kubectl](https://kubernetes.io/docs/tasks/tools/) CLI
- A valid `kubeconfig.yaml`
- [Ollama](https://ollama.com) installed
- Internet connection to download model and tools

---

## ⚙️ Step-by-Step Setup

### 1. Install `kubectl`

1. Download the `kubectl.exe` binary from the [official Kubernetes site](https://kubernetes.io/docs/tasks/tools/).
2. Add the folder containing `kubectl.exe` to your system `PATH`.
3. Open a terminal and verify:

   ```powershell
   kubectl version --client
   ```

---

### 2. Install `kubectl-ai`

1. Visit the [`kubectl-ai` GitHub Releases page](https://github.com/sozercan/kubectl-ai/releases).
2. Download the latest `kubectl-ai-windows-amd64.exe` binary.
3. Rename the file to `kubectl-ai.exe` for easier usage.
4. Move the file to a folder included in your system `PATH` (e.g., `C:\Tools`).
5. Open a new terminal and test it:

   ```powershell
   kubectl-ai --help
   ```

---

### 3. Set Up Your Kubeconfig

1. Download your `kubeconfig.yaml` file.
2. Set the `KUBECONFIG` environment variable:

   ```powershell
   $env:KUBECONFIG="C:\Users\Pranay\Downloads\tools\mykubeconfig.yaml"
   ```

3. Test connectivity:

   ```powershell
   kubectl cluster-info
   ```

---

### 4. Install Ollama and Pull Model

1. Download and install Ollama from [https://ollama.com/download](https://ollama.com/download).
2. Pull the desired model:

   ```powershell
   ollama pull gemma3:12b-it-qat
   ```

3. Run the model:

   ```powershell
   ollama run gemma3:12b-it-qat
   ```

4. (Optional) Test model API locally:

   ```powershell
   Invoke-RestMethod -Uri http://localhost:11434/api/generate `
     -Method Post `
     -Body '{"model": "gemma3:12b-it-qat", "prompt": "What is Kubernetes?", "stream": false}' `
     -ContentType "application/json"
   ```

---

### 5. Run `kubectl-ai` with Ollama

Once everything is running:

```powershell
kubectl-ai --llm-provider ollama --model gemma3:12b-it-qat --enable-tool-use-shim
```

---

## 🧪 Example Prompt

Interact with your Kubernetes cluster using natural language:

```
List all pods in the default namespace.
```

---

## 🔍 Notes

- Make sure `ollama run` is active before starting `kubectl-ai`.
- You can experiment with other models supported by Ollama.
- System performance may vary based on available RAM and GPU.

---

## 🛠 Troubleshooting

| Issue                        | Solution                                                                 |
|-----------------------------|--------------------------------------------------------------------------|
| `kubectl` not recognized    | Ensure `kubectl.exe` is in your system `PATH`.                           |
| `kubectl-ai` not recognized | Ensure the binary is renamed to `kubectl-ai.exe` and added to `PATH`.    |
| Ollama not responding       | Ensure the model is pulled and `ollama run` is actively serving.         |
| Kubernetes error            | Verify the correct `KUBECONFIG` path and access to the cluster.          |

---

## 📚 Resources

- [kubectl-ai GitHub](https://github.com/sozercan/kubectl-ai)
- [Ollama Documentation](https://ollama.com/library)
- [Kubernetes Official Docs](https://kubernetes.io/docs/)
