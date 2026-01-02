# Model Settings

Ukkin uses an on-device AI model for natural language understanding and agent creation. These settings control how the model behaves.

## Overview

The AI model runs entirely on your device, ensuring:

- Complete privacy (no data leaves your phone)
- Works offline
- Fast response times
- No subscription required

## Model Configuration

### Model Selection

**Setting:** Model Path

Choose which AI model to use:

| Model | Size | Speed | Quality |
|-------|------|-------|---------|
| StableLM 2 Zephyr 1.6B | 1.6GB | Fast | Good |
| Custom | Varies | Varies | Varies |

Default: `stablelm-2-zephyr-1_6b`

### Context Length

**Setting:** Context Window

How much conversation history the model remembers:

| Setting | Tokens | Use Case |
|---------|--------|----------|
| Small | 1024 | Quick responses, less memory |
| Medium | 2048 | Balanced (default) |
| Large | 4096 | Complex conversations |

!!! note
    Larger context uses more memory and may slow responses.

### Response Length

**Setting:** Max Tokens

Maximum length of AI responses:

| Setting | Tokens | Characters (approx) |
|---------|--------|---------------------|
| Short | 256 | ~1000 |
| Medium | 512 | ~2000 (default) |
| Long | 1024 | ~4000 |

### Temperature

**Setting:** Creativity Level

Controls response randomness:

| Value | Effect |
|-------|--------|
| 0.3 | Conservative, predictable |
| 0.5 | Balanced |
| 0.7 | Creative (default) |
| 0.9 | Very creative, varied |

Lower values are better for:
- Precise commands
- Consistent behavior
- Technical tasks

Higher values are better for:
- Creative suggestions
- Varied responses
- Brainstorming

## Hardware Settings

### Processing Unit

**Setting:** Compute Device

Choose where to run the model:

| Option | Speed | Battery |
|--------|-------|---------|
| GPU | Fastest | Higher drain |
| CPU | Slower | Lower drain |
| Auto | Adaptive | Balanced |

**Auto** switches based on:
- Battery level
- Current workload
- Temperature

### Thread Count

**Setting:** CPU Threads

For CPU processing, set thread count:

- **Auto** - System decides (recommended)
- **2-8** - Manual setting

More threads = faster, but uses more battery and may heat device.

## Performance Tuning

### Low-Memory Mode

For devices with limited RAM:

1. Enable **Low Memory Mode**
2. Uses smaller model chunks
3. Trades speed for stability

### Battery Saver

When enabled:

- Uses CPU instead of GPU
- Limits context size
- Reduces thread count
- Processes during charging

### Quality vs Speed

**Quick Response Mode:**
- Shorter context
- Lower quality threshold
- Faster responses

**Quality Mode:**
- Full context
- Higher quality threshold
- Slower but better responses

## Model Management

### Download Models

Additional models can be downloaded:

1. Go to **Settings** > **Models** > **Available**
2. Browse compatible models
3. Tap to download
4. Set as active

### Delete Models

Free up storage:

1. Go to **Settings** > **Models** > **Downloaded**
2. Select model to remove
3. Tap **Delete**

!!! warning
    Keep at least one model to use Ukkin.

### Model Updates

When updates are available:

1. Notification appears
2. Review changes
3. Download when ready
4. Old model removed automatically

## Custom Models

### Import Custom Model

Use your own compatible models:

1. **Settings** > **Models** > **Import**
2. Select model file (GGUF format)
3. Configure parameters
4. Test with sample queries

### Model Requirements

Custom models must be:

- GGUF format
- Compatible with llama.cpp
- Under device memory limits

## Troubleshooting

### Slow Responses

Try:
- Reduce context length
- Enable Quick Response Mode
- Use CPU if GPU is overheating
- Close other apps

### Model Errors

If model fails to load:

1. Check available storage (need 2GB free)
2. Restart the app
3. Re-download model if corrupted

### Out of Memory

If you see memory errors:

1. Enable Low Memory Mode
2. Reduce context length
3. Close background apps
4. Use a smaller model

## Recommended Settings

### For Speed

```
Context: 1024
Max Tokens: 256
Temperature: 0.5
Device: GPU
Threads: Auto
```

### For Quality

```
Context: 4096
Max Tokens: 1024
Temperature: 0.7
Device: GPU
Threads: Auto
```

### For Battery Life

```
Context: 1024
Max Tokens: 512
Temperature: 0.7
Device: CPU
Threads: 2
Battery Saver: On
```

### For Low-End Devices

```
Context: 1024
Max Tokens: 256
Temperature: 0.5
Device: CPU
Threads: 2
Low Memory Mode: On
```

## Advanced Settings

### Sampling Parameters

For advanced users:

- **Top P** - Nucleus sampling threshold
- **Top K** - Token selection limit
- **Repeat Penalty** - Reduce repetition

### Prompt Templates

Customize how prompts are formatted:

- System prompt prefix
- User message format
- Assistant response format

## Next Steps

- [Automation Settings](automation.md) - Control agent execution
- [Settings Overview](settings.md) - All configuration options
- [Privacy Settings](../security/overview.md) - Data protection
