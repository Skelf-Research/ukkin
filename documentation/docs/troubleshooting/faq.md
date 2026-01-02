# Frequently Asked Questions

Common questions about Ukkin and their answers.

## General Questions

### What is Ukkin?

Ukkin is an AI-powered mobile automation platform that creates personal agents to automate tasks on your phone. Agents can monitor apps, extract information, and perform actions on your behalf.

### How is Ukkin different from other automation apps?

Ukkin uses natural language understanding to create automations. Instead of building complex flows manually, you simply describe what you want in plain English, and Ukkin creates the automation for you.

### Does Ukkin require an internet connection?

No. All AI processing happens on your device. Ukkin works fully offline. Internet is only needed if your agents interact with online content (like checking prices on websites).

### Is Ukkin free?

Ukkin is free to use with all features included. There are no subscriptions, premium tiers, or in-app purchases.

## Privacy & Security

### Does Ukkin send my data to the cloud?

No. All data stays on your device. There are no servers collecting your information. The AI model runs entirely locally.

### Can Ukkin access my passwords?

No. While the accessibility service can technically see screen content, Ukkin never extracts, stores, or transmits passwords. Password fields are automatically detected and excluded.

### Is my data encrypted?

Yes. All sensitive data is encrypted using AES-256 with keys stored in your device's secure hardware keystore.

### What happens to my data if I uninstall?

All Ukkin data is deleted when you uninstall the app. Nothing remains on your device or anywhere else.

## Agents

### How many agents can I create?

There's no hard limit. Create as many agents as you need. However, having many active agents may impact battery life.

### Can agents run when my phone is locked?

Yes, if you've granted the necessary permissions and disabled battery optimization for Ukkin.

### Why did my agent fail?

Common reasons:
- App interface changed
- Element not found
- Network timeout
- Permission revoked

Check the agent's execution history for specific error details.

### Can agents interact with any app?

Most apps work with Ukkin. Some apps with special security (banking apps, some games) may not be accessible. You can also manually block apps.

## Technical Questions

### What AI model does Ukkin use?

Ukkin uses StableLM 2 Zephyr 1.6B by default, a compact but capable language model that runs efficiently on mobile devices.

### How much storage does Ukkin need?

The app itself is about 100MB. The AI model requires approximately 1.5GB. Total: about 2GB, plus space for your data.

### Does Ukkin drain battery?

Battery usage depends on:
- Number of active agents
- How often they run
- What actions they perform

With typical usage (3-5 agents running daily), battery impact is minimal.

### Can I use my own AI model?

Yes. Ukkin supports custom GGUF models compatible with llama.cpp. Import them in Settings > Models.

## Troubleshooting

### Ukkin is slow to respond

Try:
- Reduce context length in model settings
- Close other apps
- Restart Ukkin
- Use Quick Response mode

### My agent keeps failing

1. Check execution logs for error details
2. Verify permissions are granted
3. Update the app if interface changed
4. Add longer wait times between steps

### I'm not getting notifications

1. Check system notification settings
2. Verify Ukkin has notification permission
3. Ensure Do Not Disturb is off
4. Check quiet hours settings in Ukkin

### The accessibility service keeps turning off

Some Android devices aggressively manage background services. Try:
- Disable battery optimization for Ukkin
- Lock Ukkin in recent apps
- Enable auto-start permission if available

## Features

### Can Ukkin type in apps?

Yes. Agents can type text into any text field, including search boxes, message inputs, and form fields.

### Can Ukkin take screenshots?

Yes. Agents can capture screenshots which are stored locally and can be exported.

### Can agents send messages for me?

Yes, with appropriate permissions. You can create agents that compose and send messages in apps like WhatsApp or email.

### Does Ukkin support voice commands?

Currently, Ukkin is text-based. Voice input is on the roadmap for future releases.

## Compatibility

### What Android version do I need?

Android 8.0 (Oreo) or higher.

### What iPhone models are supported?

iPhone 6s or newer running iOS 11.0+.

### Does Ukkin work on tablets?

Yes, Ukkin works on Android tablets and iPads.

### Is there a desktop version?

Not currently. Ukkin is designed for mobile devices. A desktop version may be considered in the future.

## Getting Help

### Where can I report bugs?

Report issues on our GitHub repository:
https://github.com/ukkin/ukkin/issues

### How do I request features?

Submit feature requests on GitHub:
https://github.com/ukkin/ukkin/issues

### Is there a community forum?

Join discussions on GitHub Discussions:
https://github.com/ukkin/ukkin/discussions

### How can I contribute?

Ukkin is open source. Contributions are welcome:
1. Fork the repository
2. Make your changes
3. Submit a pull request

## Still Have Questions?

If your question isn't answered here:

1. Check the [Common Issues](common-issues.md) page
2. Search the documentation
3. Open an issue on GitHub
