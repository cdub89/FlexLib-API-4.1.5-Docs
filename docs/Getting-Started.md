# Getting Started with FlexLib

This guide will walk you through creating your first FlexLib 4.1.5 application, from setup to basic radio control.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Setting Up Your Project](#setting-up-your-project)
3. [Initializing FlexLib](#initializing-flexlib)
4. [Discovering Radios](#discovering-radios)
5. [Connecting to a Radio](#connecting-to-a-radio)
6. [Working with Slices](#working-with-slices)
7. [Monitoring Meters](#monitoring-meters)
8. [Audio Streaming](#audio-streaming)
9. [PTT Control](#ptt-control)
10. [Cleanup and Disposal](#cleanup-and-disposal)
11. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before you begin, ensure you have:

### Software Requirements
- **Visual Studio 2022** or later
- **.NET 8.0 SDK** or **.NET Framework 4.6.2** Developer Pack
- **FlexLib source code** or compiled DLL

### Hardware Requirements
- **FlexRadio device** (6000 series or compatible)
- **Network connection** to the radio (same subnet recommended)
- **Windows PC** (Windows 10/11)

### Knowledge Prerequisites
- Basic C# programming
- Understanding of async/await patterns
- Familiarity with event-driven programming

---

## Setting Up Your Project

### Option 1: Create a Console Application

```bash
# Create a new console app
dotnet new console -n MyFlexRadioApp
cd MyFlexRadioApp

# Add reference to FlexLib project
dotnet add reference ../FlexLib_API_v4.1.5.39794/FlexLib/FlexLib.csproj
```

### Option 2: Create a WPF Application

```bash
# Create a new WPF app
dotnet new wpf -n MyFlexRadioWpfApp
cd MyFlexRadioWpfApp

# Add reference to FlexLib project
dotnet add reference ../FlexLib_API_v4.1.5.39794/FlexLib/FlexLib.csproj
```

### Project Configuration

Update your `.csproj` file to target the correct framework:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net8.0-windows</TargetFramework>
    <Nullable>enable</Nullable>
  </PropertyGroup>

  <ItemGroup>
    <ProjectReference Include="..\FlexLib_API_v4.1.5.39794\FlexLib\FlexLib.csproj" />
  </ItemGroup>
</Project>
```

---

## Initializing FlexLib

The first step in any FlexLib application is initialization. This starts the radio discovery process.

### Basic Initialization

```csharp
using Flex.Smoothlake.FlexLib;
using System;
using System.Threading.Tasks;

namespace MyFlexRadioApp
{
    class Program
    {
        static async Task Main(string[] args)
        {
            // Set your application name (required)
            API.ProgramName = "MyFlexRadioApp";
            
            // Set whether this is a GUI application
            API.IsGUI = false; // true for WPF/WinForms apps
            
            // Initialize the API (starts UDP discovery)
            API.Init();
            
            Console.WriteLine("FlexLib initialized. Searching for radios...");
            
            // Keep application running
            await Task.Delay(-1);
        }
    }
}
```

### Understanding Initialization

When you call `API.Init()`:
1. UDP discovery socket is opened on port 4992
2. Discovery packets are sent on the network
3. A cleanup timer starts to remove stale radios
4. Event handlers are registered for radio discovery

**Important**: Call `API.Init()` only once in your application lifecycle.

---

## Discovering Radios

FlexLib automatically discovers radios on your network. Use events to be notified when radios are found.

### Listening for Radio Discovery

```csharp
static async Task Main(string[] args)
{
    API.ProgramName = "MyFlexRadioApp";
    API.IsGUI = false;
    
    // Subscribe to radio events BEFORE calling Init()
    API.RadioAdded += OnRadioAdded;
    API.RadioRemoved += OnRadioRemoved;
    
    API.Init();
    
    Console.WriteLine("Waiting for radios...");
    await Task.Delay(5000); // Wait 5 seconds for discovery
    
    // List all discovered radios
    Console.WriteLine($"\nFound {API.RadioList.Count} radio(s):");
    foreach (var radio in API.RadioList)
    {
        Console.WriteLine($"  - {radio.Nickname} ({radio.Model}) - {radio.IP}");
    }
    
    await Task.Delay(-1);
}

static void OnRadioAdded(Radio radio)
{
    Console.WriteLine($"✓ Radio discovered: {radio.Nickname}");
    Console.WriteLine($"  Model: {radio.Model}");
    Console.WriteLine($"  Serial: {radio.Serial}");
    Console.WriteLine($"  IP: {radio.IP}");
    Console.WriteLine($"  Version: {radio.Version}");
}

static void OnRadioRemoved(Radio radio)
{
    Console.WriteLine($"✗ Radio removed: {radio.Nickname}");
}
```

### Getting Radio Information

```csharp
Radio radio = API.RadioList.FirstOrDefault();
if (radio != null)
{
    // Radio properties (available before connection)
    string nickname = radio.Nickname;      // User-defined name
    string model = radio.Model;            // e.g., "FLEX-6600"
    string serial = radio.Serial;          // Serial number
    IPAddress ip = radio.IP;               // IP address
    string version = radio.Version;        // Firmware version
    bool isAvailable = radio.Available;    // Can connect?
    string status = radio.Status;          // Current status
}
```

---

## Connecting to a Radio

Once a radio is discovered, you can connect to it to gain full control.

### Basic Connection

```csharp
static async Task ConnectToFirstRadio()
{
    // Wait for radios to be discovered
    await Task.Delay(2000);
    
    Radio? radio = API.RadioList.FirstOrDefault();
    if (radio == null)
    {
        Console.WriteLine("No radios found!");
        return;
    }
    
    Console.WriteLine($"Connecting to {radio.Nickname}...");
    
    // Subscribe to connection events
    radio.PropertyChanged += (sender, e) =>
    {
        if (e.PropertyName == "Connected")
        {
            var r = sender as Radio;
            if (r?.Connected == true)
            {
                Console.WriteLine("✓ Connected successfully!");
            }
        }
    };
    
    // Connect to the radio
    radio.Connect();
    
    // Wait for connection to complete
    int timeout = 0;
    while (!radio.Connected && timeout < 100)
    {
        await Task.Delay(100);
        timeout++;
    }
    
    if (radio.Connected)
    {
        Console.WriteLine($"Radio ready! Version: {radio.Version}");
    }
    else
    {
        Console.WriteLine("Connection timeout!");
    }
}
```

### Connection with Error Handling

```csharp
public static async Task<bool> ConnectWithRetry(Radio radio, int maxRetries = 3)
{
    for (int attempt = 1; attempt <= maxRetries; attempt++)
    {
        Console.WriteLine($"Connection attempt {attempt}/{maxRetries}...");
        
        try
        {
            radio.Connect();
            
            // Wait for connection with timeout
            for (int i = 0; i < 50; i++) // 5 second timeout
            {
                if (radio.Connected)
                    return true;
                    
                await Task.Delay(100);
            }
            
            Console.WriteLine("Connection timeout");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Connection error: {ex.Message}");
        }
        
        if (attempt < maxRetries)
        {
            Console.WriteLine("Retrying...");
            await Task.Delay(2000);
        }
    }
    
    return false;
}
```

### Understanding Radio States

A Radio can be in several states:

| State | Property | Description |
|-------|----------|-------------|
| Discovered | `Available = true` | Radio found on network |
| Connecting | `Connected = false` | Connection in progress |
| Connected | `Connected = true` | Full control available |
| In Use | `Available = false` | Connected by another client |

---

## Working with Slices

A **Slice** represents a receiver or transmitter channel. You can have multiple slices to monitor different frequencies simultaneously.

### Creating a Slice

```csharp
static async Task CreateAndConfigureSlice(Radio radio)
{
    if (!radio.Connected)
    {
        Console.WriteLine("Radio not connected!");
        return;
    }
    
    // Subscribe to slice events
    radio.SliceAdded += (slice) =>
    {
        Console.WriteLine($"Slice created: Index {slice.Index}");
    };
    
    // Request a new slice
    radio.RequestSliceFromRadio();
    
    // Wait for slice to be created
    await Task.Delay(500);
    
    // Get the slice
    Slice? slice = radio.SliceList.FirstOrDefault();
    if (slice == null)
    {
        Console.WriteLine("Failed to create slice!");
        return;
    }
    
    Console.WriteLine($"Slice {slice.Index} created successfully");
}
```

### Tuning a Slice

```csharp
static void TuneSlice(Slice slice)
{
    // Set frequency (in MHz)
    slice.Freq = 14.200;  // 14.200 MHz (20m band)
    
    // Set operating mode
    slice.Mode = "USB";   // Options: "LSB", "USB", "AM", "CW", "DIGL", "DIGU", "FM", "NFM"
    
    // Set filter bandwidth
    slice.FilterLow = 200;    // Low cut (Hz)
    slice.FilterHigh = 2800;  // High cut (Hz)
    
    // Set antennas
    slice.RXAnt = "ANT1";     // Receive antenna
    slice.TXAnt = "ANT1";     // Transmit antenna
    
    // Set other properties
    slice.Active = true;      // Activate the slice
    slice.AudioGain = 50;     // Audio gain (0-100)
    slice.AGCMode = "med";    // AGC: "off", "slow", "med", "fast"
    
    Console.WriteLine($"Tuned to {slice.Freq:F3} MHz, Mode: {slice.Mode}");
}
```

### Monitoring Slice Changes

```csharp
static void MonitorSlice(Slice slice)
{
    slice.PropertyChanged += (sender, e) =>
    {
        var s = sender as Slice;
        
        switch (e.PropertyName)
        {
            case "Freq":
                Console.WriteLine($"Frequency changed: {s.Freq:F6} MHz");
                break;
                
            case "Mode":
                Console.WriteLine($"Mode changed: {s.Mode}");
                break;
                
            case "Active":
                Console.WriteLine($"Slice {(s.Active ? "activated" : "deactivated")}");
                break;
                
            case "Transmit":
                Console.WriteLine($"PTT: {(s.Transmit ? "TX" : "RX")}");
                break;
        }
    };
}
```

### Complete Slice Example

```csharp
static async Task SliceDemo(Radio radio)
{
    Console.WriteLine("\n=== Slice Demo ===\n");
    
    // Create a slice
    radio.RequestSliceFromRadio();
    await Task.Delay(500);
    
    var slice = radio.SliceList.FirstOrDefault();
    if (slice == null) return;
    
    // Monitor changes
    MonitorSlice(slice);
    
    // Tune to 20m band, USB
    Console.WriteLine("Tuning to 20m USB...");
    slice.Freq = 14.200;
    slice.Mode = "USB";
    slice.FilterLow = 200;
    slice.FilterHigh = 2800;
    
    await Task.Delay(2000);
    
    // Tune to 40m band, LSB
    Console.WriteLine("Tuning to 40m LSB...");
    slice.Freq = 7.200;
    slice.Mode = "LSB";
    
    await Task.Delay(2000);
    
    // Tune to 2m band, FM
    Console.WriteLine("Tuning to 2m FM...");
    slice.Freq = 146.520;
    slice.Mode = "FM";
    
    await Task.Delay(2000);
}
```

---

## Monitoring Meters

Meters provide real-time telemetry data like signal strength, power output, SWR, and more.

### Basic Meter Monitoring

```csharp
static void SetupMeters(Radio radio)
{
    radio.MeterAdded += (meter) =>
    {
        Console.WriteLine($"Meter available: {meter.Name}");
        
        // Subscribe to meter data updates
        meter.DataReady += (data) =>
        {
            HandleMeterData(meter.Name, data.Value);
        };
    };
}

static void HandleMeterData(string meterName, float value)
{
    switch (meterName)
    {
        case "MICPEAK":
            // Microphone audio level (dB)
            Console.WriteLine($"Mic Level: {value:F1} dB");
            break;
            
        case "SWR":
            // Standing Wave Ratio
            Console.WriteLine($"SWR: {value:F2}:1");
            break;
            
        case "FWD":
            // Forward power (watts)
            Console.WriteLine($"Forward Power: {value:F0} W");
            break;
            
        case "VOLTAGE":
            // Power supply voltage
            Console.WriteLine($"Voltage: {value:F1} V");
            break;
            
        case "TEMP":
            // PA temperature
            Console.WriteLine($"PA Temp: {value:F0} °C");
            break;
    }
}
```

### Monitoring Specific Meters

```csharp
static void MonitorTransmitMeters(Radio radio)
{
    foreach (var meter in radio.MeterList)
    {
        if (meter.Name == "SWR" || meter.Name == "FWD" || meter.Name == "TEMP")
        {
            meter.DataReady += (data) =>
            {
                Console.WriteLine($"{meter.Name}: {data.Value:F2}");
            };
        }
    }
}
```

### Common Meter Names

| Meter Name | Description | Unit |
|------------|-------------|------|
| `MICPEAK` | Mic audio peak level | dB |
| `SWR` | Standing wave ratio | ratio |
| `FWD` | Forward power | watts |
| `REF` | Reflected power | watts |
| `VOLTAGE` | Power supply voltage | volts |
| `TEMP` | PA temperature | °C |
| `SIGNAL` | Signal strength | dBm |
| `COMPPEAK` | Compressor peak | dB |

---

## Audio Streaming

FlexLib supports multiple types of audio streams for receiving and transmitting audio data.

### DAX RX Audio Stream

```csharp
static void SetupRxAudioStream(Radio radio)
{
    // Create DAX RX audio stream
    DAXRXAudioStream daxStream = radio.CreateDAXRXAudioStream(1); // DAX channel 1
    
    if (daxStream != null)
    {
        Console.WriteLine("DAX RX audio stream created");
        
        // Subscribe to audio data
        daxStream.DataReady += (data) =>
        {
            // Process audio samples
            // data contains float[] audio samples
            ProcessAudioSamples(data);
        };
        
        // Start streaming
        daxStream.Start();
    }
}

static void ProcessAudioSamples(float[] samples)
{
    // Your audio processing code here
    // - Write to file
    // - Play to audio device
    // - Process for digital modes
    // - etc.
}
```

### Remote RX Audio

```csharp
static void SetupRemoteAudio(Radio radio)
{
    // Enable remote RX audio
    var remoteStream = radio.CreateRXRemoteAudioStream();
    
    if (remoteStream != null)
    {
        Console.WriteLine("Remote RX audio stream created");
        
        remoteStream.DataReady += (audioData) =>
        {
            // Process remote audio samples
            // Compressed audio over network
        };
    }
}
```

---

## PTT Control

Control transmit/receive switching programmatically.

### Software PTT

```csharp
static void TransmitExample(Slice slice)
{
    Console.WriteLine("Starting transmission...");
    
    // Key the transmitter
    slice.Transmit = true;
    
    // Wait for transmit to start
    Thread.Sleep(500);
    
    Console.WriteLine("Transmitting...");
    
    // Transmit for 3 seconds
    Thread.Sleep(3000);
    
    // Unkey the transmitter
    slice.Transmit = false;
    
    Console.WriteLine("Transmission complete");
}
```

### Monitoring Interlock State

```csharp
static void MonitorInterlock(Radio radio)
{
    radio.PropertyChanged += (sender, e) =>
    {
        if (e.PropertyName == "InterlockState")
        {
            Console.WriteLine($"Interlock State: {radio.InterlockState}");
            
            switch (radio.InterlockState)
            {
                case InterlockState.Receive:
                    Console.WriteLine("In receive mode");
                    break;
                    
                case InterlockState.Ready:
                    Console.WriteLine("Ready to transmit");
                    break;
                    
                case InterlockState.Transmitting:
                    Console.WriteLine("Transmitting!");
                    break;
                    
                case InterlockState.NotReady:
                    Console.WriteLine($"Not ready: {radio.InterlockReason}");
                    break;
                    
                case InterlockState.TXFault:
                    Console.WriteLine("TX FAULT!");
                    break;
            }
        }
    };
}
```

---

## Cleanup and Disposal

Always clean up resources when your application exits.

### Proper Cleanup

```csharp
static async Task Main(string[] args)
{
    try
    {
        API.ProgramName = "MyFlexRadioApp";
        API.Init();
        
        // Your application code here
        
        // Wait for Ctrl+C
        var exitEvent = new ManualResetEvent(false);
        Console.CancelKeyPress += (sender, e) =>
        {
            e.Cancel = true;
            exitEvent.Set();
        };
        
        Console.WriteLine("Press Ctrl+C to exit...");
        exitEvent.WaitOne();
    }
    finally
    {
        // Cleanup
        Cleanup();
    }
}

static void Cleanup()
{
    Console.WriteLine("\nCleaning up...");
    
    // Disconnect all radios
    foreach (var radio in API.RadioList)
    {
        if (radio.Connected)
        {
            Console.WriteLine($"Disconnecting from {radio.Nickname}...");
            radio.Disconnect();
        }
    }
    
    // Close API session
    API.CloseSession();
    
    Console.WriteLine("Cleanup complete");
}
```

---

## Troubleshooting

### No Radios Discovered

**Problem**: `API.RadioList` is empty after calling `API.Init()`.

**Solutions**:
1. Verify radio is powered on and connected to network
2. Check PC and radio are on same subnet
3. Disable VPN if active
4. Check Windows Firewall allows UDP port 4992
5. Wait longer (try 5-10 seconds)
6. Check radio IP with FlexRadio SmartSDR

### Connection Fails

**Problem**: `radio.Connect()` doesn't result in `Connected = true`.

**Solutions**:
1. Verify radio is available (`radio.Available = true`)
2. Close other applications connected to the radio
3. Check network connectivity with ping
4. Verify firewall allows TCP port 4992
5. Try rebooting the radio

### Slice Not Created

**Problem**: `radio.RequestSliceFromRadio()` doesn't create a slice.

**Solutions**:
1. Verify radio is connected
2. Check if maximum slices already created
3. Wait longer (500-1000ms)
4. Check radio firmware version compatibility

### No Meter Data

**Problem**: Meter events not firing.

**Solutions**:
1. Subscribe to `MeterAdded` before connecting
2. Verify meters exist in `radio.MeterList`
3. Check meter subscription settings
4. Ensure radio is transmitting (for TX meters)

### Audio Stream Issues

**Problem**: No audio data received.

**Solutions**:
1. Verify DAX channel is configured in SmartSDR
2. Check audio stream is started
3. Verify slice has audio source
4. Check DAX audio settings in radio

---

## Next Steps

Now that you've mastered the basics:

1. **Explore the [API Reference](api/index.md)** - Deep dive into all classes and methods
2. **Study [Examples](Examples.md)** - See real-world application patterns
3. **Read [Architecture](Architecture.md)** - Understand FlexLib's design
4. **Build something!** - Start your own FlexRadio application

---

**Need more help?** Visit the [FlexRadio Community Forum](https://community.flexradio.com) or contact technical support.

Happy coding! 📻
