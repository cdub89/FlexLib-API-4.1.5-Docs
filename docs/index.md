# FlexLib API Documentation

Welcome to the **FlexLib API 4.1.5 Documentation** - your comprehensive guide to developing applications for FlexRadio Systems software-defined radios.

## What is FlexLib?

FlexLib is a powerful C# library that provides complete control over FlexRadio devices. Whether you're building a simple radio controller or a sophisticated SDR application, FlexLib offers the tools you need.

## 📚 Documentation Sections

### [Getting Started](Getting-Started.md)
New to FlexLib? Start here! This guide walks you through:
- Setting up your development environment
- Your first FlexLib application
- Basic radio control concepts
- Common patterns and practices

### [API Reference](api/index.md)
Detailed documentation for every class, method, and property in FlexLib:
- **[API Class](api/Flex.Smoothlake.FlexLib.API.yml)** - Initialize and discover radios
- **[Radio Class](api/Flex.Smoothlake.FlexLib.Radio.yml)** - Control radio operations
- **[Slice Class](api/Flex.Smoothlake.FlexLib.Slice.yml)** - Manage receiver/transmitter slices
- **[Audio Streams](api/Flex.Smoothlake.FlexLib.DAXRXAudioStream.yml)** - Handle audio data
- And much more...

### [Examples](Examples.md)
Real-world code examples showing:
- Radio discovery and connection
- Frequency control and mode selection
- Audio streaming
- Meter monitoring
- Multi-radio applications

### [Architecture](Architecture.md)
Deep dive into FlexLib's design:
- System architecture overview
- Component relationships
- Threading model
- Network protocol details
- Best practices

### [Migration Guide](Migration-Guide.md)
Upgrading from a previous version? Find:
- Breaking changes
- New features
- Deprecated APIs
- Migration strategies

## 🚀 Quick Links

| Task | Link |
|------|------|
| Connect to a radio | [Getting Started - Connection](Getting-Started.md#connecting-to-a-radio) |
| Create a slice | [API Reference - Radio.RequestSliceFromRadio](api/Flex.Smoothlake.FlexLib.Radio.yml) |
| Stream audio | [Examples - Audio Streaming](Examples.md#audio-streaming) |
| Handle meters | [Examples - Meter Monitoring](Examples.md#meter-monitoring) |
| Transmit control | [Getting Started - PTT Control](Getting-Started.md#ptt-control) |

## 💡 Key Concepts

### Radio Discovery
FlexLib automatically discovers FlexRadio devices on your network using UDP broadcasting. Simply call `API.Init()` and listen for discovered radios.

### Event-Driven Architecture
FlexLib uses C# events extensively. Subscribe to events like `RadioAdded`, `SliceAdded`, `PropertyChanged` to respond to radio state changes.

### Command-Response Protocol
Communication with the radio uses a text-based command protocol. FlexLib handles this automatically, but understanding it helps with debugging.

### VITA-49 Streaming
Audio and IQ data use the VITA-49 packet protocol for high-performance streaming. FlexLib abstracts this complexity while providing low-level access when needed.

## 🎯 Common Use Cases

### Desktop Applications
Build full-featured radio control applications with:
- Multiple panadapter displays
- Slice management
- Audio routing
- Logging and spotting

### Headless Controllers
Create server-based applications for:
- Remote operation
- Automated monitoring
- Digital mode gateways
- Contest logging servers

### Integration Projects
Integrate FlexRadio with:
- Station automation systems
- Rotator controllers
- Amplifier interfaces
- Custom hardware

## 🔧 System Requirements

- **.NET Framework 4.6.2** or **.NET 8.0**
- **Windows 10/11** (x86, x64, ARM64)
- **FlexRadio device** on the same network
- **Visual Studio 2022** (for development)

## 📦 Dependencies

FlexLib requires these NuGet packages:
- AsyncAwaitBestPractices (v9.0.0)
- DotNetZip (v1.16.0)
- Newtonsoft.Json (v13.0.3)
- System.Collections.Immutable (v9.0.0)

## 🆘 Need Help?

- **Search this documentation** - Use the search box above
- **Check examples** - Most questions are answered with code examples
- **Community forum** - https://community.flexradio.com
- **Technical support** - support@flexradio.com

## 📖 About This Documentation

This documentation is generated from XML comments in the FlexLib source code using [DocFX](https://dotnet.github.io/docfx/). 

### Conventions Used

- `Code` - Inline code, class names, method names
- **Bold** - Important terms and emphasis
- *Italic* - Notes and additional information
- > Blockquote - Tips and warnings

### Code Examples

All code examples are written in C# and tested with the latest FlexLib version. Copy and paste them directly into your projects.

```csharp
// Example: Connect to first discovered radio
API.Init();
await Task.Delay(2000);
var radio = API.RadioList.FirstOrDefault();
if (radio != null)
{
    radio.Connect();
}
```

## 📝 Version Information

**Current Version**: 4.1.5.39794  
**Last Updated**: January 2026  
**Target Frameworks**: .NET Framework 4.6.2, .NET 8.0

---

**Ready to get started?** Head over to the [Getting Started Guide](Getting-Started.md)!
