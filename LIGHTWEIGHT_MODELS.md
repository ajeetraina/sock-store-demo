# 🤖 Lightweight Model Guide

No powerful GPU? No problem! This guide shows you how to run the Docker MCP Gateway Interceptor Demo with ultra-lightweight models that work on almost any system.

## 🚀 One-Click Setup (Recommended)

```bash
git checkout interceptor-demo
chmod +x quick-fix.sh
./quick-fix.sh
```

The script automatically detects your system and chooses the best option!

## 🎯 Model Options by System Requirements

### 💰 Option 1: OpenAI API (Best Choice)
**Requirements:** Internet connection + API key  
**VRAM needed:** 0MB  
**Setup:**
```bash
export OPENAI_API_KEY=sk-your-key-here
echo $OPENAI_API_KEY > secret.openai-api-key
docker compose up --build -d
```
**Pros:** Best performance, no local resources needed  
**Cons:** Small cost (~$0.50-2.00 per session)

### 🔬 Option 2: TinyLlama (Ultra-Lightweight)
**Requirements:** 700MB VRAM or works on CPU  
**Download:** 700MB  
**Setup:**
```bash
docker compose -f compose.yaml -f compose.tinyllama.yaml up --build -d
```
**Pros:** Works on almost any system, completely free  
**Cons:** Basic performance, slower responses

### ⚡ Option 3: Phi3-Mini (Good Balance)
**Requirements:** 2GB VRAM  
**Download:** 2.3GB  
**Setup:**
```bash
docker compose -f compose.yaml -f compose.local-model.yaml up --build -d
```
**Pros:** Good performance, reasonable resource usage  
**Cons:** Needs moderate VRAM

### 🎛️ Option 4: Custom Selection
**Requirements:** Varies by model  
**Setup:**
```bash
./select-model.sh  # Interactive selection
# Or edit compose.lightweight-models.yaml manually
docker compose -f compose.yaml -f compose.lightweight-models.yaml up --build -d
```

## 📊 Detailed Model Comparison

| Model | Download | VRAM | Performance | Response Speed | Best For |
|-------|----------|------|-------------|----------------|----------|
| **OpenAI API** | 0MB | 0MB | ⭐⭐⭐⭐⭐ | ⚡⚡⚡⚡⚡ | **Production** |
| TinyLlama 1.1B | 700MB | 700MB | ⭐⭐☆☆☆ | ⚡⚡☆☆☆ | Old laptops |
| Gemma 2B | 1.6GB | 1.5GB | ⭐⭐⭐☆☆ | ⚡⚡⚡☆☆ | Basic systems |
| Phi3-mini 3.8B | 2.3GB | 2GB | ⭐⭐⭐⭐☆ | ⚡⚡⚡⚡☆ | Most laptops |
| Llama 3.2 3B | 2.0GB | 2GB | ⭐⭐⭐⭐☆ | ⚡⚡⚡⚡☆ | Balanced choice |
| Mistral 7B | 4.1GB | 4GB | ⭐⭐⭐⭐⭐ | ⚡⚡⚡⚡☆ | Gaming laptops |

## 🔧 Quick Commands Reference

### Check what you currently have:
```bash
# Check VRAM (NVIDIA)
nvidia-smi

# Check system memory
free -h  # Linux
vm_stat  # macOS

# Check Docker resources
docker system df
```

### Start with different models:
```bash
# TinyLlama (smallest)
docker compose -f compose.yaml -f compose.tinyllama.yaml up -d

# Phi3-mini (recommended)
docker compose -f compose.yaml -f compose.local-model.yaml up -d

# OpenAI API (best)
echo "sk-your-key" > secret.openai-api-key
docker compose up -d

# Custom model
./select-model.sh
```

### Switch models:
```bash
# Stop current
docker compose down

# Start with different model
docker compose -f compose.yaml -f compose.tinyllama.yaml up -d
```

## 🎯 System-Specific Recommendations

### 💻 MacBook Air/Pro (8GB RAM)
**Recommended:** OpenAI API or TinyLlama
```bash
# Option A: OpenAI (best)
export OPENAI_API_KEY=sk-your-key
./quick-fix.sh

# Option B: TinyLlama (free)
docker compose -f compose.yaml -f compose.tinyllama.yaml up -d
```

### 🖥️ Gaming Laptop (16GB+ RAM, dedicated GPU)
**Recommended:** Phi3-mini or Mistral 7B
```bash
# Good performance
docker compose -f compose.yaml -f compose.local-model.yaml up -d

# Or edit compose.lightweight-models.yaml for Mistral 7B
```

### 🏢 Enterprise Workstation
**Recommended:** OpenAI API for consistency
```bash
export OPENAI_API_KEY=sk-your-key
docker compose up -d
```

### 📱 Raspberry Pi / Low-power systems
**Recommended:** OpenAI API only
```bash
# Local models won't work well on very low-power systems
export OPENAI_API_KEY=sk-your-key
docker compose up -d
```

## 🚨 Troubleshooting Model Issues

### "Model too big" error?
```bash
# Try smaller model
docker compose down
docker compose -f compose.yaml -f compose.tinyllama.yaml up -d
```

### Model downloading very slowly?
```bash
# Check available space
docker system df

# Clean up if needed
docker system prune -a
```

### Model responses are too slow?
```bash
# Switch to OpenAI API
docker compose down
echo "sk-your-key" > secret.openai-api-key
docker compose up -d
```

### Out of memory errors?
```bash
# Use TinyLlama or OpenAI API
docker compose down
docker compose -f compose.yaml -f compose.tinyllama.yaml up -d
```

## 🎓 Understanding the Models

### TinyLlama (1.1B parameters)
- **Best for:** Proof of concept, learning, very limited hardware
- **Capabilities:** Basic text generation, simple reasoning
- **Limitations:** May struggle with complex instructions

### Phi3-mini (3.8B parameters)  
- **Best for:** Most practical applications on laptops
- **Capabilities:** Good reasoning, follows instructions well
- **Limitations:** Slower than cloud APIs

### OpenAI API (GPT-4o-mini)
- **Best for:** Production use, consistent performance
- **Capabilities:** Excellent reasoning, fast responses
- **Limitations:** Requires internet and API costs

## 🔗 Next Steps

1. **Choose your model** using the guide above
2. **Start the demo:** `./quick-fix.sh` or manual setup
3. **Test interceptors:** `./demo-interceptors.sh`
4. **Access the app:** http://localhost:3000

## 💡 Pro Tips

- **For demos/presentations:** Use OpenAI API for reliability
- **For learning/development:** TinyLlama is perfect and free
- **For production:** Always use OpenAI API or larger cloud models
- **Mixed usage:** Start with TinyLlama, upgrade to API as needed

The interceptors work identically regardless of which model you choose - the security, monitoring, and business logic features are all model-agnostic! 🛡️
