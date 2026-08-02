# FlexLib API Documentation

Community-maintained documentation for **FlexLib 4.2.x**, the C# API for
FlexRadio Systems software-defined radios.

> **Unofficial and unaffiliated.** This documentation is not produced,
> endorsed, or reviewed by FlexRadio Systems. FlexLib itself is
> FlexRadio's proprietary software, licensed separately by them, and is
> not distributed here. For official support, contact FlexRadio at
> <https://community.flexradio.com>.

## What is FlexLib?

FlexLib is a powerful C# library that provides complete control over FlexRadio devices. Whether you're building a simple radio controller or a sophisticated SDR application, FlexLib offers the tools you need.

## 📚 Documentation Sections

### [Getting Started](Getting-Started.md)

New to FlexLib? Start here! This guide walks you through:

- Setting up your development environment
- Your first FlexLib application
- Basic radio control concepts
- Common patterns and practices

### [API Reference](API-Reference.md)

Hand-written quick reference for the classes you use most:

- **API** - initialize and discover radios
- **Radio** - control radio operations
- **Slice** - manage receiver and transmitter slices
- **Audio streams** - handle DAX audio data

It opens with a corrections table listing members that earlier editions
of this documentation got wrong, and what the library actually does.

For the complete class-by-class reference, generate it locally from your
own copy of the FlexLib source. See
[Generating the full API reference](Generating-API-Docs.md).

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
| Discover radios | [Getting Started - Discovery](Getting-Started.md#discovering-radios) |
| Connect to a radio | [Getting Started - Connection](Getting-Started.md#connecting-to-a-radio) |
| Create a slice, set frequency | [Getting Started - Working with Slices](Getting-Started.md#working-with-slices) |
| Stream audio | [Getting Started - Audio](Getting-Started.md#audio-streaming), [Examples - Audio](Examples.md#audio-streaming) |
| Read meters | [Getting Started - Monitoring Meters](Getting-Started.md#monitoring-meters) |
| Transmit control | [Getting Started - PTT Control](Getting-Started.md#ptt-control) |
| Drive multiple radios | [Examples - Multi-Radio Manager](Examples.md#multi-radio-manager) |
| Digital modes | [Examples - Digital Mode Interface](Examples.md#digital-mode-interface) |
| Build the full class reference | [Generating API Docs](Generating-API-Docs.md) |

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

FlexLib pulls in these NuGet packages:

- AsyncAwaitBestPractices
- DotNetZip
- Newtonsoft.Json
- System.Collections.Immutable

Pinned versions vary by FlexLib build. Check the `.csproj` files in your
own distribution rather than relying on a version list here.

## 🆘 Need Help?

- **Search this documentation** - Use the search box above
- **Check examples** - Most questions are answered with code examples
- **Community forum** - <https://community.flexradio.com>
- **Technical support** - <mailto:support@flexradio.com>

Note that FlexRadio supports FlexLib itself. They did not write this
documentation and cannot answer questions about it. Report problems with
these pages on the repository issue tracker.

## 📖 About This Documentation

These pages are written by hand and checked against the FlexLib source.
They are not generated from it. The complete generated class reference is
built locally from your own copy of the source; see
[Generating the full API reference](Generating-API-Docs.md).

### Conventions Used

- `Code` - Inline code, class names, method names
- **Bold** - Important terms and emphasis
- *Italic* - Notes and additional information
- > Blockquote - Tips and warnings

### Code Examples

Examples are written in C# against FlexLib 4.2.x, targeting .NET Framework
4.6.2 as well as .NET 8 so they compile on either. Each page states which
FlexLib build its claims were verified against; check that line before
depending on a signature.

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

**Documents**: FlexLib 4.2.x
**Target frameworks**: .NET Framework 4.6.2, .NET 8.0
**Per-page verification**: see the status line under each page's title

The [API Reference](API-Reference.md) is verified against
4.2.20.41343. The remaining pages were written against 4.1.5 and
corrected in targeted passes; they are marked accordingly.

---

**Ready to get started?** Head over to the [Getting Started Guide](Getting-Started.md)!
