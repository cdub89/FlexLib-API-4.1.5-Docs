# FlexLib Documentation

Index of the community-maintained FlexLib 4.2.x documentation. Start at
[index.md](index.md) for the overview and the unaffiliated-project
disclaimer.

## 📚 Available Documentation

### User Guides

- **[Getting Started](Getting-Started.md)** - Complete tutorial for new users
  - Setup instructions
  - Your first FlexLib application
  - Basic concepts and patterns
  
- **[API Reference](API-Reference.md)** - Quick reference for all major classes
  - Core classes and methods
  - Properties and events
  - Usage examples

- **[Examples](Examples.md)** - Real-world code examples
  - Basic radio control
  - Audio streaming
  - Advanced features
  - Complete applications

- **[Architecture](Architecture.md)** - System design documentation
  - Component overview
  - Design patterns
  - Threading model
  - Network protocol details

- **[Migration Guide](Migration-Guide.md)** - Version upgrade instructions
  - Breaking changes
  - New features
  - Migration strategies

- **[Generating API Docs](Generating-API-Docs.md)** - Build the complete
  class reference locally
  - Why it is not published here
  - Layout and build commands

## 🚀 Quick Start

### For New Users

1. Start with **[Getting Started](Getting-Started.md)**
2. Try the examples in **[Examples](Examples.md)**
3. Reference **[API Reference](API-Reference.md)** as needed

### For Experienced Developers

1. Check **[API Reference](API-Reference.md)** for quick lookups
2. Browse **[Examples](Examples.md)** for specific patterns
3. Read **[Architecture](Architecture.md)** for deep understanding

### For Upgraders

1. Read **[Migration Guide](Migration-Guide.md)** first
2. Check the corrections table in
   **[API Reference](API-Reference.md#corrections-from-the-415-edition)**;
   some of what changed was this documentation being wrong, not the API
3. Update code following migration steps

```text
docs/
├── README.md                 # This file
├── index.md                  # Documentation home page
├── Getting-Started.md        # Tutorial for beginners
├── API-Reference.md          # Quick API reference
├── Examples.md               # Code examples
├── Architecture.md           # System design
├── Migration-Guide.md        # Version upgrade guide
├── Generating-API-Docs.md    # Building the full reference locally
├── docfx.json                # DocFX configuration
└── toc.yml                   # Table of contents
```

## 🔍 Finding Information

### By Topic

| What You Want | Where to Look |
|---------------|---------------|
| Getting started | [Getting Started Guide](Getting-Started.md) |
| Code examples | [Examples](Examples.md) |
| Class reference | [API Reference](API-Reference.md) |
| Full generated reference | [Generating API Docs](Generating-API-Docs.md) |
| System design | [Architecture](Architecture.md) |
| Upgrading versions | [Migration Guide](Migration-Guide.md) |
| Contributing | [Repository README](../README.md#contributing) |

### By Feature

| Feature | Documentation |
|---------|---------------|
| Radio discovery | [Getting Started - Discovery](Getting-Started.md#discovering-radios) |
| Connection | [Getting Started - Connection](Getting-Started.md#connecting-to-a-radio) |
| Frequency control | [Getting Started - Slices](Getting-Started.md#working-with-slices) |
| Audio streaming | [Getting Started - Audio](Getting-Started.md#audio-streaming), [Examples - Audio](Examples.md#audio-streaming) |
| PTT control | [Getting Started - PTT](Getting-Started.md#ptt-control) |
| Meters | [Getting Started - Meters](Getting-Started.md#monitoring-meters) |
| Multi-radio | [Examples - Multi-Radio](Examples.md#multi-radio-manager) |
| Digital modes | [Examples - Digital Mode](Examples.md#digital-mode-interface) |

## 💡 Documentation Tips

### For Beginners

1. **Read sequentially**: Start with Getting Started, work through examples
2. **Try the code**: Copy examples and run them
3. **Experiment**: Modify examples to understand behavior
4. **Ask questions**: Use community forum or GitHub issues

### For Advanced Users

1. **Build the full reference**: see
   [Generating API Docs](Generating-API-Docs.md) for the class-by-class
   documentation, generated from your own copy of the source
2. **Check IntelliSense**: FlexLib ships XML comments, so Visual Studio
   shows the authoritative description inline
3. **Read the source**: it is the ground truth, and these pages defer to
   it wherever they disagree

### For Contributors

This repository documents an API it does not own. Corrections are
welcome; unverifiable claims are not.

1. **Trace every claim to the source**: name the FlexLib build you
   checked (e.g. `4.2.20.41343`) and the source file and line
2. **Do not infer**: a signature that follows the naming pattern, or that
   another page here already states, is a lead and not evidence. Most of
   this repository's history is correcting exactly those
3. **Keep samples compilable on the reader's floor**: .NET Framework
   4.6.2 as well as .NET 8
4. **Do not submit generated output**: FlexLib source, DocFX YAML, or
   rendered site files cannot be accepted (see
   [Generating API Docs](Generating-API-Docs.md))

### Markdown style

- ATX headings (`#`, `##`, `###`), sentence case
- Language tag on every fenced block
- Relative links between documents; verify anchors after editing headings
- Tables for structured comparisons
- No em dashes in prose

## 🆘 Getting Help

### Documentation issues

Problems with these pages belong on this repository's issue tracker, not
with FlexRadio:

1. **Wrong signature or sample**: open an issue or pull request, and
   include the FlexLib build and the source file that shows the correct
   form
2. **Unclear sections**: open an issue with suggestions
3. **Missing topics**: request in the issue tracker

### Using FlexLib

For help with the library itself:

1. **Check examples**: most questions are answered with code examples
2. **Community forum**: <https://community.flexradio.com>
3. **Technical support**: <mailto:support@flexradio.com>

FlexRadio supports FlexLib. They did not write this documentation and
cannot answer questions about it.

## 📝 License

These documentation pages are licensed
[CC BY 4.0](../LICENSE) and are not affiliated with FlexRadio Systems.
The license covers this repository's prose, tables, and code samples
only, and makes no claim over FlexLib or any other FlexRadio property.

## 🤝 Contributing

Documentation improvements are welcome. See
[For Contributors](#for-contributors) above for what a correction needs
to carry, and the [repository README](../README.md#contributing) for the
submission process.

---

**Ready to get started?** Head to the [Getting Started Guide](Getting-Started.md)!

**Need something specific?** Check the [API Reference](API-Reference.md)!

**Want to see it in action?** Browse the [Examples](Examples.md)!
