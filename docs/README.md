# FlexLib Documentation

Welcome to the FlexLib API 4.1.5 documentation!

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
2. Check **[CHANGELOG](../CHANGELOG.md)** for version changes
3. Update code following migration steps

## 📖 Generating Full API Documentation

FlexLib includes XML documentation comments throughout the codebase. Generate complete HTML documentation using DocFX:

### Install DocFX

```bash
# Install as global tool
dotnet tool install -g docfx

# Or install locally
dotnet tool install docfx
```

### Generate Documentation

```bash
# Navigate to docs folder
cd docs

# Generate documentation
docfx docfx.json

# Serve documentation locally
docfx serve _site
```

Then open your browser to `http://localhost:8080` to view the complete API documentation.

### Build Output

The generated documentation will be in `docs/_site/`:
- Full API reference for all classes
- Method signatures and parameters
- Property documentation
- Code examples from XML comments
- Searchable interface

## 📂 Documentation Structure

```
docs/
├── README.md                 # This file
├── Getting-Started.md        # Tutorial for beginners
├── API-Reference.md          # Quick API reference
├── Examples.md               # Code examples
├── Architecture.md           # System design
├── Migration-Guide.md        # Version upgrade guide
├── docfx.json               # DocFX configuration
├── index.md                 # DocFX home page
├── toc.yml                  # Table of contents
└── _site/                   # Generated HTML (after build)
```

## 🔍 Finding Information

### By Topic

| What You Want | Where to Look |
|---------------|---------------|
| Getting started | [Getting Started Guide](Getting-Started.md) |
| Code examples | [Examples](Examples.md) |
| Class reference | [API Reference](API-Reference.md) or generated docs |
| System design | [Architecture](Architecture.md) |
| Upgrading versions | [Migration Guide](Migration-Guide.md) |
| Contributing | [CONTRIBUTING.md](../CONTRIBUTING.md) |
| Version history | [CHANGELOG.md](../CHANGELOG.md) |

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

1. **Use the search**: Generated docs have full-text search
2. **Check XML comments**: IntelliSense shows documentation in Visual Studio
3. **Read source**: FlexLib source code is well-commented
4. **Contribute**: Improve docs via pull requests

### For Contributors

1. **Update XML comments**: All public APIs need documentation
2. **Add examples**: Include code examples in XML `<example>` tags
3. **Update guides**: Keep markdown docs synchronized
4. **Test DocFX**: Regenerate docs to verify changes

## 🛠️ Documentation Standards

### XML Documentation

All public classes, methods, properties, and events must have:

```csharp
/// <summary>
/// Brief one-line description.
/// </summary>
/// <remarks>
/// Detailed description with multiple paragraphs if needed.
/// Explain behavior, constraints, and important notes.
/// </remarks>
/// <param name="paramName">Parameter description</param>
/// <returns>Return value description</returns>
/// <exception cref="ExceptionType">When this is thrown</exception>
/// <example>
/// <code>
/// // Example usage
/// var result = SomeMethod(param);
/// </code>
/// </example>
/// <seealso cref="RelatedClass"/>
public ReturnType SomeMethod(ParamType paramName)
{
    // Implementation
}
```

### Markdown Style

- Use ATX headers (`#`, `##`, `###`)
- Include code blocks with language tags
- Add examples for complex topics
- Link between documents with relative paths
- Use tables for structured information

## 🔄 Keeping Documentation Updated

### When to Update

Update documentation when:
- Adding new public APIs
- Changing existing behavior
- Fixing bugs that affect usage
- Adding new features
- Deprecating functionality

### What to Update

1. **XML Comments**: Update in source code
2. **API Reference**: If major API changes
3. **Examples**: Add examples for new features
4. **Getting Started**: For workflow changes
5. **Migration Guide**: For breaking changes
6. **CHANGELOG**: For all notable changes

## 🆘 Getting Help

### Documentation Issues

If you find documentation problems:

1. **Typos/errors**: Submit a pull request with fix
2. **Unclear sections**: Open an issue with suggestions
3. **Missing topics**: Request in GitHub issues
4. **Outdated content**: Report with version information

### Using FlexLib

For help using FlexLib:

1. **Search documentation**: Use search in generated docs
2. **Check examples**: Most questions answered with examples
3. **Community forum**: https://community.flexradio.com
4. **GitHub issues**: For bug reports
5. **Technical support**: support@flexradio.com

## 📝 License

Documentation is part of the FlexLib project and follows the same license.

Copyright © 2018-2024 FlexRadio Systems. All rights reserved.

## 🤝 Contributing

We welcome documentation improvements! See [CONTRIBUTING.md](../CONTRIBUTING.md) for:
- Documentation standards
- Submission process
- Code of conduct

---

**Ready to get started?** Head to the [Getting Started Guide](Getting-Started.md)!

**Need something specific?** Check the [API Reference](API-Reference.md)!

**Want to see it in action?** Browse the [Examples](Examples.md)!
