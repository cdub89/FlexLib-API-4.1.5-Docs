# Migration Guide

This guide helps you upgrade from previous versions of FlexLib to the current version (4.1.5.39794).

## Table of Contents

- [Version 4.x to 4.1.5](#version-4x-to-415)
- [Version 3.x to 4.x](#version-3x-to-4x)
- [Breaking Changes](#breaking-changes)
- [New Features](#new-features)
- [Deprecated APIs](#deprecated-apis)
- [Common Migration Issues](#common-migration-issues)

---

## Version 4.x to 4.1.5

### Summary

This is primarily a maintenance release with framework updates and bug fixes.

### Target Framework Changes

**Previous**:
- .NET Framework 4.6.2

**Current**:
- .NET Framework 4.6.2
- .NET 8.0 (new)

### Multi-Targeting Support

FlexLib now supports both .NET Framework 4.6.2 and .NET 8.0.

**Migration Steps**:

1. Update your project to target .NET 8.0 (recommended):

```xml
<PropertyGroup>
  <TargetFramework>net8.0-windows</TargetFramework>
</PropertyGroup>
```

2. Or continue using .NET Framework 4.6.2:

```xml
<PropertyGroup>
  <TargetFramework>net462</TargetFramework>
</PropertyGroup>
```

### Dependency Updates

**Updated NuGet Packages**:

| Package | Old Version | New Version |
|---------|-------------|-------------|
| AsyncAwaitBestPractices | 7.x | 9.0.0 |
| System.Collections.Immutable | 6.x | 9.0.0 |
| Newtonsoft.Json | 13.0.1 | 13.0.3 |

**Action Required**: Update your application's dependencies if you reference these packages directly.

```bash
dotnet add package AsyncAwaitBestPractices --version 9.0.0
dotnet add package System.Collections.Immutable --version 9.0.0
```

### C# Language Version

**Current**: Uses default C# language version (C# 12 for .NET 8.0).

**Features Now Available** (if targeting .NET 8.0):
- Primary constructors
- Collection expressions
- `ref readonly` parameters
- Lambda default parameters

**Example using new C# 12 features**:

```csharp
// Primary constructor (now used in RadioInfo struct)
private readonly struct RadioInfo(Radio radio)
{
    public Radio Radio { get; } = radio;
    public Stopwatch Timer { get; } = Stopwatch.StartNew();
}
```

### API Changes

**No Breaking API Changes**: All existing APIs remain compatible.

**Minor Changes**:
- Internal optimizations to use immutable collections
- Improved thread safety in discovery
- Better resource cleanup

---

## Version 3.x to 4.x

This was a major version update with significant changes.

### Breaking Changes

#### 1. Namespace Changes

**Old**:
```csharp
using FlexLib;
```

**New**:
```csharp
using Flex.Smoothlake.FlexLib;
```

**Migration**: Update all using statements in your code.

```bash
# Find and replace in your project
Old: "using FlexLib;"
New: "using Flex.Smoothlake.FlexLib;"
```

---

#### 2. Radio Discovery Changes

**Old (v3.x)**:
```csharp
// Discovery was manual
Discovery.Start();
Discovery.RadioDiscovered += OnRadioDiscovered;

void OnRadioDiscovered(Radio radio)
{
    // Handle radio
}
```

**New (v4.x)**:
```csharp
// Use API class for discovery
API.Init(); // Starts discovery automatically

API.RadioAdded += (radio) =>
{
    // Handle radio
};
```

**Migration Steps**:

1. Replace `Discovery.Start()` with `API.Init()`
2. Change event subscription from `Discovery.RadioDiscovered` to `API.RadioAdded`
3. Access radios via `API.RadioList` instead of maintaining your own list

---

#### 3. Connection Method Changes

**Old (v3.x)**:
```csharp
radio.Connect("192.168.1.100");
```

**New (v4.x)**:
```csharp
// Connection uses existing discovery information
radio.Connect(); // No IP parameter needed
```

**Migration**: Remove IP address parameters from `Connect()` calls.

---

#### 4. Slice Management

**Old (v3.x)**:
```csharp
Slice slice = radio.CreateSlice();
```

**New (v4.x)**:
```csharp
// Request slice from radio
radio.RequestSliceFromRadio();

// Wait for slice to be created
// Subscribe to SliceAdded event or check SliceList
```

**Migration Example**:

```csharp
// Old way
Slice slice = radio.CreateSlice();
slice.Freq = 14.200;

// New way
radio.SliceAdded += (slice) =>
{
    slice.Freq = 14.200;
};
radio.RequestSliceFromRadio();

// Or wait and check
radio.RequestSliceFromRadio();
await Task.Delay(500);
var slice = radio.SliceList.FirstOrDefault();
```

---

#### 5. Audio Stream Changes

**Old (v3.x)**:
```csharp
AudioStream stream = new AudioStream(radio, 1);
stream.DataAvailable += OnAudioData;
```

**New (v4.x)**:
```csharp
DAXRXAudioStream stream = radio.CreateDAXRXAudioStream(1);
stream.DataReady += OnAudioData;
stream.Start();
```

**Migration**:
- Use factory methods on Radio class
- Rename event from `DataAvailable` to `DataReady`
- Call `Start()` explicitly

---

#### 6. Property Name Changes

Some properties were renamed for clarity:

| Old Name (v3.x) | New Name (v4.x) |
|-----------------|-----------------|
| `Radio.IsConnected` | `Radio.Connected` |
| `Slice.Frequency` | `Slice.Freq` |
| `Slice.RxAntenna` | `Slice.RXAnt` |
| `Slice.TxAntenna` | `Slice.TXAnt` |

**Migration**: Update property references.

```csharp
// Old
if (radio.IsConnected)
    slice.Frequency = 14.200;

// New
if (radio.Connected)
    slice.Freq = 14.200;
```

---

### New Features in 4.x

#### 1. WAN Server Support

Remote radio access over internet:

```csharp
// Enable WAN connection
WanServer.Connect("your-wan-server-url");

// Access remote radios
foreach (var radio in API.RadioList)
{
    if (radio.IsWan)
    {
        // This is a remote radio
    }
}
```

#### 2. Enhanced Meter System

More meters and better data:

```csharp
radio.MeterAdded += (meter) =>
{
    Console.WriteLine($"New meter: {meter.Name}");
    
    meter.DataReady += (data) =>
    {
        // New: More detailed meter data
        Console.WriteLine($"{meter.Name}: {data.Value} (units: {meter.Units})");
    };
};
```

#### 3. Multiple Panadapter Support

```csharp
// Create multiple panadapters
radio.RequestPanadapter();
radio.RequestPanadapter();

// Access all panadapters
foreach (var pan in radio.PanadapterList)
{
    pan.CenterFreq = 14.200;
}
```

#### 4. ALE Support

Automatic Link Establishment:

```csharp
// ALE 2G, 3G, 4G support
var ale = radio.ALE2GList.FirstOrDefault();
if (ale != null)
{
    // Configure ALE
}
```

#### 5. USB Cable Control

New cable control interfaces:

```csharp
// USB cable support
var catCable = radio.UsbCatCableList.FirstOrDefault();
var bcdCable = radio.UsbBcdCableList.FirstOrDefault();
var ldpaCable = radio.UsbLdpaCableList.FirstOrDefault();
```

#### 6. Improved Equalizer

Enhanced audio EQ:

```csharp
var eq = radio.EQList.FirstOrDefault();
if (eq != null)
{
    eq.Mode = "rx";
    eq.SetLevel(0, -5); // Band 0, -5 dB
}
```

---

## Breaking Changes Summary

### Immediate Action Required

1. **Update namespaces**: `FlexLib` → `Flex.Smoothlake.FlexLib`
2. **Update discovery**: Use `API.Init()` instead of `Discovery.Start()`
3. **Update connections**: Remove IP parameters from `Connect()`
4. **Update slice creation**: Use `RequestSliceFromRadio()` instead of `CreateSlice()`
5. **Update property names**: See table above

### Code Changes Example

**Before (v3.x)**:
```csharp
using FlexLib;

class Program
{
    static void Main()
    {
        Discovery.Start();
        Discovery.RadioDiscovered += (radio) =>
        {
            radio.Connect("192.168.1.100");
            
            if (radio.IsConnected)
            {
                Slice slice = radio.CreateSlice();
                slice.Frequency = 14.200;
            }
        };
    }
}
```

**After (v4.x)**:
```csharp
using Flex.Smoothlake.FlexLib;

class Program
{
    static async Task Main()
    {
        API.ProgramName = "MyApp";
        API.Init();
        
        API.RadioAdded += async (radio) =>
        {
            radio.Connect();
            
            // Wait for connection
            for (int i = 0; i < 50 && !radio.Connected; i++)
                await Task.Delay(100);
            
            if (radio.Connected)
            {
                radio.RequestSliceFromRadio();
                await Task.Delay(500);
                
                var slice = radio.SliceList.FirstOrDefault();
                if (slice != null)
                    slice.Freq = 14.200;
            }
        };
        
        await Task.Delay(-1);
    }
}
```

---

## Deprecated APIs

### Removed in 4.x

These APIs were removed and have no direct replacement:

- `Radio.CreateSlice()` - Use `RequestSliceFromRadio()`
- `Discovery.Start()` - Use `API.Init()`
- `Discovery.Stop()` - Use `API.CloseSession()`

### Deprecated (Still Available)

These APIs still work but are discouraged:

- Direct property modification without events
- Manual radio list management
- Direct socket access

**Recommended Alternatives**:
- Use events for all updates
- Use `API.RadioList`
- Use high-level API methods

---

## Common Migration Issues

### Issue 1: "Type or namespace 'FlexLib' could not be found"

**Cause**: Namespace changed in v4.x

**Solution**: Update using statements:
```csharp
using Flex.Smoothlake.FlexLib;
```

---

### Issue 2: Radio connection fails immediately

**Cause**: Old connection pattern used.

**Solution**: Don't pass IP address:
```csharp
// Wrong
radio.Connect("192.168.1.100");

// Correct
radio.Connect();
```

---

### Issue 3: Slice is null after creation

**Cause**: Not waiting for asynchronous slice creation.

**Solution**: Wait for slice or use event:
```csharp
radio.SliceAdded += (slice) =>
{
    // Use slice here
};
radio.RequestSliceFromRadio();
```

---

### Issue 4: Events not firing

**Cause**: Events must be subscribed before operation.

**Solution**: Subscribe to events first:
```csharp
// Wrong order
API.Init();
API.RadioAdded += OnRadioAdded; // May miss radios

// Correct order
API.RadioAdded += OnRadioAdded;
API.Init();
```

---

### Issue 5: UI freezing with events

**Cause**: Events fire on background threads.

**Solution**: Use Dispatcher for UI updates:
```csharp
radio.PropertyChanged += (s, e) =>
{
    Dispatcher.Invoke(() =>
    {
        // Update UI here
    });
};
```

---

### Issue 6: Property changes not syncing

**Cause**: Properties changed before connection established.

**Solution**: Wait for connection:
```csharp
radio.Connect();

// Wait for connection
for (int i = 0; i < 50 && !radio.Connected; i++)
    await Task.Delay(100);

// Now safe to modify
if (radio.Connected)
{
    slice.Freq = 14.200;
}
```

---

## Testing Your Migration

### Checklist

- [ ] All namespaces updated
- [ ] Discovery uses `API.Init()`
- [ ] No IP addresses in `Connect()` calls
- [ ] Slice creation uses `RequestSliceFromRadio()`
- [ ] Property names updated
- [ ] Event subscriptions before operations
- [ ] UI updates use Dispatcher
- [ ] Proper async/await patterns
- [ ] Resource cleanup with `API.CloseSession()`

### Test Plan

1. **Discovery Test**: Verify radios are found
2. **Connection Test**: Connect to radio successfully
3. **Slice Test**: Create and tune slices
4. **Audio Test**: Start audio streams
5. **PTT Test**: Transmit control works
6. **Meter Test**: Receive meter data
7. **Cleanup Test**: Proper disconnection

---

## Getting Help

If you encounter migration issues:

1. **Check this guide** - Most issues covered here
2. **Review examples** - See [Examples.md](Examples.md)
3. **Check API reference** - Full documentation available
4. **Community forum** - https://community.flexradio.com
5. **Technical support** - support@flexradio.com

---

## Migration Tools

### Find and Replace Script

PowerShell script to help with common replacements:

```powershell
# migrate-flexlib.ps1

$replacements = @{
    'using FlexLib;' = 'using Flex.Smoothlake.FlexLib;'
    'Discovery.Start()' = 'API.Init()'
    'radio.IsConnected' = 'radio.Connected'
    'slice.Frequency' = 'slice.Freq'
    'slice.RxAntenna' = 'slice.RXAnt'
    'slice.TxAntenna' = 'slice.TXAnt'
}

Get-ChildItem -Path . -Filter *.cs -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $modified = $false
    
    foreach ($old in $replacements.Keys) {
        if ($content -match [regex]::Escape($old)) {
            $content = $content -replace [regex]::Escape($old), $replacements[$old]
            $modified = $true
        }
    }
    
    if ($modified) {
        Set-Content -Path $_.FullName -Value $content
        Write-Host "Updated: $($_.FullName)"
    }
}
```

---

## Version History

| Version | Release Date | Major Changes |
|---------|--------------|---------------|
| 4.1.5 | 2024 | .NET 8.0 support, dependency updates |
| 4.1.0 | 2023 | Bug fixes, performance improvements |
| 4.0.0 | 2021 | Major refactor, new API design |
| 3.x | 2018-2020 | Original FlexLib implementation |

---

## Summary

Migrating to FlexLib 4.x requires code changes but provides:

✅ **Better API design**: More intuitive and consistent  
✅ **Improved performance**: Better threading and resource management  
✅ **More features**: WAN, ALE, USB cables, enhanced meters  
✅ **Modern .NET**: .NET 8.0 support  
✅ **Better documentation**: Comprehensive guides and examples  

Most migrations can be completed in a few hours with careful testing.

---

**Questions?** See [Getting Started](Getting-Started.md) or contact support.
