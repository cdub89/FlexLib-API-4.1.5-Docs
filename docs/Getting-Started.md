# Getting Started with FlexLib

> **Verified against FlexLib 4.2.20.41343** (2026-08-02). Every API member
> referenced on this page was checked against the 4.2.20 source: the member
> exists and is declared on the type used here. Prose describing behavior and
> semantics has not been re-read against the source, and the examples have
> not been compiled.

This guide will walk you through creating your first FlexLib application, from setup to basic radio control.

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
dotnet add reference ../FlexLib_API_v4.2.20.41343/FlexLib/FlexLib.csproj
```

### Option 2: Create a WPF Application

```bash
# Create a new WPF app
dotnet new wpf -n MyFlexRadioWpfApp
cd MyFlexRadioWpfApp

# Add reference to FlexLib project
dotnet add reference ../FlexLib_API_v4.2.20.41343/FlexLib/FlexLib.csproj
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
    <ProjectReference Include="..\FlexLib_API_v4.2.20.41343\FlexLib\FlexLib.csproj" />
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
using Flex.Smoothlake.FlexLib;
using System;
using System.Threading.Tasks;

namespace MyFlexRadioApp
{
    class Program
    {
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
    }
}
```

### Getting Radio Information

```csharp
using Flex.Smoothlake.FlexLib;
using System;
using System.Linq;
using System.Net;
using System.Threading.Tasks;

namespace MyFlexRadioApp
{
    class Program
    {
        static async Task Main(string[] args)
        {
            API.ProgramName = "MyFlexRadioApp";
            API.IsGUI = false;
            API.Init();
            
            Console.WriteLine("Waiting for radios...");
            await Task.Delay(3000);
            
            Radio? radio = API.RadioList.FirstOrDefault();
            if (radio != null)
            {
                // Radio properties (available before connection)
                string nickname = radio.Nickname;      // User-defined name
                string model = radio.Model;            // e.g., "FLEX-6600"
                string serial = radio.Serial;          // Serial number
                IPAddress ip = radio.IP;               // IP address
                ulong  version = radio.Version;        // Firmware version
                string connectedState = radio.ConnectedState;  // Connection state (e.g., "Available", "In Use")
                string status = radio.Status;          // Current status
                
                Console.WriteLine($"Radio Found:");
                Console.WriteLine($"  Nickname: {nickname}");
                Console.WriteLine($"  Model: {model}");
                Console.WriteLine($"  Serial: {serial}");
                Console.WriteLine($"  IP: {ip}");
                Console.WriteLine($"  Version: {version}");
                Console.WriteLine($"  Connected State: {connectedState}");
                Console.WriteLine($"  Status: {status}");
            }
            else
            {
                Console.WriteLine("No radios found!");
            }
        }
    }
}
```

---

## Connecting to a Radio

Once a radio is discovered, you can connect to it to gain full control.

### Basic Connection

```csharp
using Flex.Smoothlake.FlexLib;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace MyFlexRadioApp
{
    class Program
    {
        static async Task Main(string[] args)
        {
            API.ProgramName = "MyFlexRadioApp";
            API.IsGUI = false;
            API.Init();
            
            await ConnectToFirstRadio();
            
            Console.WriteLine("Press any key to exit...");
            Console.ReadKey();
        }

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
    }
}
```

### Connection with Error Handling

```csharp
using Flex.Smoothlake.FlexLib;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace MyFlexRadioApp
{
    class Program
    {
        static async Task Main(string[] args)
        {
            API.ProgramName = "MyFlexRadioApp";
            API.IsGUI = false;
            API.Init();
            
            Console.WriteLine("Waiting for radios...");
            await Task.Delay(3000);
            
            Radio? radio = API.RadioList.FirstOrDefault();
            if (radio == null)
            {
                Console.WriteLine("No radios found!");
                return;
            }
            
            bool connected = await ConnectWithRetry(radio);
            if (connected)
            {
                Console.WriteLine("Successfully connected!");
            }
            else
            {
                Console.WriteLine("Failed to connect after all retries.");
            }
            
            Console.WriteLine("Press any key to exit...");
            Console.ReadKey();
        }

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
    }
}
```

### Understanding Radio States

A Radio can be in several states:

| State | How to detect | Description |
|-------|---------------|-------------|
| Discovered | `ConnectedState == "Available"` | Radio found on network, ready to connect |
| Connecting | `Connected == false` | Connection in progress |
| Connected | `Connected == true` | Full control available |
| In Use | `ConnectedState == "In Use"` | Controlled by another client |

---

## Working with Slices

A **Slice** represents a receiver or transmitter channel. You can have multiple slices to monitor different frequencies simultaneously.

### Creating a Slice

```csharp
using Flex.Smoothlake.FlexLib;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace MyFlexRadioApp
{
    class Program
    {
        static async Task Main(string[] args)
        {
            API.ProgramName = "MyFlexRadioApp";
            API.IsGUI = false;
            API.Init();
            
            Console.WriteLine("Waiting for radios...");
            await Task.Delay(3000);
            
            Radio? radio = API.RadioList.FirstOrDefault();
            if (radio == null)
            {
                Console.WriteLine("No radios found!");
                return;
            }
            
            Console.WriteLine($"Connecting to {radio.Nickname}...");
            radio.Connect();
            await Task.Delay(2000);
            
            if (radio.Connected)
            {
                await CreateAndConfigureSlice(radio);
            }
            
            Console.WriteLine("Press any key to exit...");
            Console.ReadKey();
        }

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
            radio.RequestSlice();
            
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
    }
}
```

### Tuning a Slice

```csharp
using Flex.Smoothlake.FlexLib;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace MyFlexRadioApp
{
    class Program
    {
        static async Task Main(string[] args)
        {
            API.ProgramName = "MyFlexRadioApp";
            API.IsGUI = false;
            API.Init();
            
            Console.WriteLine("Waiting for radios...");
            await Task.Delay(3000);
            
            Radio? radio = API.RadioList.FirstOrDefault();
            if (radio == null)
            {
                Console.WriteLine("No radios found!");
                return;
            }
            
            Console.WriteLine($"Connecting to {radio.Nickname}...");
            radio.Connect();
            await Task.Delay(2000);
            
            if (radio.Connected)
            {
                radio.RequestSlice();
                await Task.Delay(500);
                
                Slice? slice = radio.SliceList.FirstOrDefault();
                if (slice != null)
                {
                    TuneSlice(slice);
                }
            }
            
            Console.WriteLine("Press any key to exit...");
            Console.ReadKey();
        }

        static void TuneSlice(Slice slice)
        {
            // Set frequency (in MHz)
            slice.Freq = 14.200;  // 14.200 MHz (20m band)
            
            // Set operating mode
            slice.DemodMode = "USB";   // Options: "LSB", "USB", "AM", "CW", "DIGL", "DIGU", "FM", "NFM"
            
            // Set filter bandwidth
            slice.FilterLow = 200;    // Low cut (Hz)
            slice.FilterHigh = 2800;  // High cut (Hz)
            
            // Set antennas
            slice.RXAnt = "ANT1";     // Receive antenna
            slice.TXAnt = "ANT1";     // Transmit antenna
            
            // Set other properties
            slice.Active = true;      // Activate the slice
            slice.AudioGain = 50;     // Audio gain (0-100)
            slice.AGCMode = AGCMode.Medium;    // AGC: "off", "slow", "med", "fast"
            
            Console.WriteLine($"Tuned to {slice.Freq:F3} MHz, Mode: {slice.DemodMode}");
        }
    }
}
```

### Monitoring Slice Changes

```csharp
using Flex.Smoothlake.FlexLib;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace MyFlexRadioApp
{
    class Program
    {
        static async Task Main(string[] args)
        {
            API.ProgramName = "MyFlexRadioApp";
            API.IsGUI = false;
            API.Init();
            
            Console.WriteLine("Waiting for radios...");
            await Task.Delay(3000);
            
            Radio? radio = API.RadioList.FirstOrDefault();
            if (radio == null)
            {
                Console.WriteLine("No radios found!");
                return;
            }
            
            Console.WriteLine($"Connecting to {radio.Nickname}...");
            radio.Connect();
            await Task.Delay(2000);
            
            if (radio.Connected)
            {
                radio.RequestSlice();
                await Task.Delay(500);
                
                Slice? slice = radio.SliceList.FirstOrDefault();
                if (slice != null)
                {
                    MonitorSlice(slice);
                    
                    // Make some changes to trigger events
                    slice.Freq = 14.200;
                    await Task.Delay(1000);
                    slice.DemodMode = "USB";
                    await Task.Delay(1000);
                    slice.Active = true;
                }
            }
            
            Console.WriteLine("Press any key to exit...");
            Console.ReadKey();
        }

        static void MonitorSlice(Slice slice)
        {
            slice.PropertyChanged += (sender, e) =>
            {
                var s = sender as Slice;
                
                switch (e.PropertyName)
                {
                    case "Freq":
                        Console.WriteLine($"Frequency changed: {s?.Freq:F6} MHz");
                        break;
                        
                    case "DemodMode":
                        Console.WriteLine($"Mode changed: {s?.DemodMode}");
                        break;
                        
                    case "Active":
                        Console.WriteLine($"Slice {(s?.Active == true ? "activated" : "deactivated")}");
                        break;
                        
                    case "IsTransmitSlice":
                        Console.WriteLine($"Slice {(s?.IsTransmitSlice == true ? "is now" : "is no longer")} the TX slice");
                        break;
                }
            };
        }
    }
}
```

### Complete Slice Example

```csharp
using Flex.Smoothlake.FlexLib;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace MyFlexRadioApp
{
    class Program
    {
        static async Task Main(string[] args)
        {
            API.ProgramName = "MyFlexRadioApp";
            API.IsGUI = false;
            API.Init();
            
            Console.WriteLine("Waiting for radios...");
            await Task.Delay(3000);
            
            Radio? radio = API.RadioList.FirstOrDefault();
            if (radio == null)
            {
                Console.WriteLine("No radios found!");
                return;
            }
            
            Console.WriteLine($"Connecting to {radio.Nickname}...");
            radio.Connect();
            await Task.Delay(2000);
            
            if (radio.Connected)
            {
                await SliceDemo(radio);
            }
            
            Console.WriteLine("Press any key to exit...");
            Console.ReadKey();
        }

        static async Task SliceDemo(Radio radio)
        {
            Console.WriteLine("\n=== Slice Demo ===\n");
            
            // Create a slice
            radio.RequestSlice();
            await Task.Delay(500);
            
            var slice = radio.SliceList.FirstOrDefault();
            if (slice == null) return;
            
            // Monitor changes
            MonitorSlice(slice);
            
            // Tune to 20m band, USB
            Console.WriteLine("Tuning to 20m USB...");
            slice.Freq = 14.200;
            slice.DemodMode = "USB";
            slice.FilterLow = 200;
            slice.FilterHigh = 2800;
            
            await Task.Delay(2000);
            
            // Tune to 40m band, LSB
            Console.WriteLine("Tuning to 40m LSB...");
            slice.Freq = 7.200;
            slice.DemodMode = "LSB";
            
            await Task.Delay(2000);
            
            // Tune to 2m band, FM
            Console.WriteLine("Tuning to 2m FM...");
            slice.Freq = 146.520;
            slice.DemodMode = "FM";
            
            await Task.Delay(2000);
        }

        static void MonitorSlice(Slice slice)
        {
            slice.PropertyChanged += (sender, e) =>
            {
                var s = sender as Slice;
                
                switch (e.PropertyName)
                {
                    case "Freq":
                        Console.WriteLine($"  Frequency changed: {s?.Freq:F6} MHz");
                        break;
                        
                    case "DemodMode":
                        Console.WriteLine($"  Mode changed: {s?.DemodMode}");
                        break;
                        
                    case "Active":
                        Console.WriteLine($"  Slice {(s?.Active == true ? "activated" : "deactivated")}");
                        break;
                }
            };
        }
    }
}
```

---

## Monitoring Meters

Meters provide real-time telemetry data like signal strength, power output, SWR, and more.

### Basic Meter Monitoring

```csharp
using Flex.Smoothlake.FlexLib;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace MyFlexRadioApp
{
    class Program
    {
        static async Task Main(string[] args)
        {
            API.ProgramName = "MyFlexRadioApp";
            API.IsGUI = false;
            API.Init();
            
            Console.WriteLine("Waiting for radios...");
            await Task.Delay(3000);
            
            Radio? radio = API.RadioList.FirstOrDefault();
            if (radio == null)
            {
                Console.WriteLine("No radios found!");
                return;
            }
            
            Console.WriteLine($"Connecting to {radio.Nickname}...");
            radio.Connect();
            await Task.Delay(2000);
            
            if (radio.Connected)
            {
                // Meters only exist after the radio is connected and has
                // reported its meter list. Looking them up before Connect
                // finds nothing, silently.
                SetupMeters(radio);

                Console.WriteLine("Monitoring meters... Press any key to exit.");
                Console.ReadKey();
            }
        }

        static void SetupMeters(Radio radio)
        {
            // Radio has no MeterAdded event and no MeterList. Look each
            // meter up by its exact name, after the radio is connected.
            string[] wanted = { "MICPEAK", "SWR", "FWDPWR", "+13.8A", "PATEMP" };

            foreach (string name in wanted)
            {
                Meter meter = radio.FindMeterByName(name);
                if (meter == null)
                {
                    // Returns null for a name this radio does not report.
                    Console.WriteLine($"Meter not available: {name}");
                    continue;
                }

                Console.WriteLine($"Meter available: {meter.Name}");

                // Subscribe to meter data updates
                // DataReadyEventHandler signature: (Meter meter, float data)
                meter.DataReady += (m, value) =>
                {
                    HandleMeterData(m.Name, value);
                };
            }
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
                    
                case "FWDPWR":
                    // Forward power (watts)
                    Console.WriteLine($"Forward Power: {value:F0} W");
                    break;
                    
                case "+13.8A":
                    // Power supply voltage
                    Console.WriteLine($"Voltage: {value:F1} V");
                    break;
                    
                case "PATEMP":
                    // PA temperature
                    Console.WriteLine($"PA Temp: {value:F0} °C");
                    break;
            }
        }
    }
}
```

### Monitoring Specific Meters

```csharp
using Flex.Smoothlake.FlexLib;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace MyFlexRadioApp
{
    class Program
    {
        static async Task Main(string[] args)
        {
            API.ProgramName = "MyFlexRadioApp";
            API.IsGUI = false;
            API.Init();
            
            Console.WriteLine("Waiting for radios...");
            await Task.Delay(3000);
            
            Radio? radio = API.RadioList.FirstOrDefault();
            if (radio == null)
            {
                Console.WriteLine("No radios found!");
                return;
            }
            
            Console.WriteLine($"Connecting to {radio.Nickname}...");
            radio.Connect();
            await Task.Delay(2000);
            
            if (radio.Connected)
            {
                MonitorTransmitMeters(radio);
                Console.WriteLine("Monitoring transmit meters... Press any key to exit.");
                Console.ReadKey();
            }
        }

        static void MonitorTransmitMeters(Radio radio)
        {
            foreach (string name in new[] { "SWR", "FWDPWR", "REFPWR", "PATEMP" })
            {
                Meter meter = radio.FindMeterByName(name);
                if (meter == null) continue;

                meter.DataReady += (m, value) =>
                {
                    Console.WriteLine($"{m.Name}: {value:F2}");
                };
            }
        }
    }
}
```

### Common Meter Names

These are exact strings the radio reports. A lookup with a name the radio
does not report returns `null` rather than throwing, so a typo fails
silently.

| Meter Name | Description | Unit |
|------------|-------------|------|
| `MICPEAK` | Mic audio peak level | dB |
| `MIC` | Mic level | dB |
| `COMPPEAK` | Compressor peak | dB |
| `HWALC` | Hardware ALC | dB |
| `LEVEL` | Audio level | dB |
| `SWR` | Standing wave ratio | ratio |
| `FWDPWR` | Forward power | watts |
| `REFPWR` | Reflected power | watts |
| `PAEFF` | PA efficiency | percent |
| `PATEMP` | PA temperature | °C |
| `+13.8A` | Power supply voltage | volts |

Earlier editions of this guide listed `FWD`, `REF`, `VOLTAGE`, `TEMP`,
and `SIGNAL`. None of those are meter names the library matches on; a
lookup using them returns `null`.

---

## Audio Streaming

FlexLib supports multiple types of audio streams for receiving and transmitting audio data.

### DAX RX Audio Stream

```csharp
using Flex.Smoothlake.FlexLib;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace MyFlexRadioApp
{
    class Program
    {
        static async Task Main(string[] args)
        {
            API.ProgramName = "MyFlexRadioApp";
            API.IsGUI = false;
            API.Init();
            
            Console.WriteLine("Waiting for radios...");
            await Task.Delay(3000);
            
            Radio? radio = API.RadioList.FirstOrDefault();
            if (radio == null)
            {
                Console.WriteLine("No radios found!");
                return;
            }
            
            Console.WriteLine($"Connecting to {radio.Nickname}...");
            radio.Connect();
            await Task.Delay(2000);
            
            if (radio.Connected)
            {
                SetupRxAudioStream(radio);
                Console.WriteLine("Audio streaming... Press any key to exit.");
                Console.ReadKey();
            }
        }

        static void SetupRxAudioStream(Radio radio)
        {
            // Subscribe to the stream added event BEFORE requesting the stream
            // DataReadyEventHandler signature: (RXAudioStream stream, float[] rx_data)
            radio.DAXRXAudioStreamAdded += (audioStream) =>
            {
                Console.WriteLine("DAX RX audio stream created");
                
                audioStream.DataReady += (stream, rx_data) =>
                {
                    // rx_data contains float[] mono PCM samples, -1.0 to 1.0
                    ProcessAudioSamples(rx_data);
                };
            };
            
            // Request DAX channel 1 — stream arrives via DAXRXAudioStreamAdded
            radio.RequestDAXRXAudioStream(1);
        }

        static void ProcessAudioSamples(float[] samples)
        {
            // Your audio processing code here
            // - Write to file
            // - Play to audio device
            // - Process for digital modes
            // - etc.
            Console.WriteLine($"Received {samples.Length} audio samples");
        }
    }
}
```

### Remote RX Audio

```csharp
using Flex.Smoothlake.FlexLib;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace MyFlexRadioApp
{
    class Program
    {
        static async Task Main(string[] args)
        {
            API.ProgramName = "MyFlexRadioApp";
            API.IsGUI = false;
            API.Init();
            
            Console.WriteLine("Waiting for radios...");
            await Task.Delay(3000);
            
            Radio? radio = API.RadioList.FirstOrDefault();
            if (radio == null)
            {
                Console.WriteLine("No radios found!");
                return;
            }
            
            Console.WriteLine($"Connecting to {radio.Nickname}...");
            radio.Connect();
            await Task.Delay(2000);
            
            if (radio.Connected)
            {
                SetupRemoteAudio(radio);
                Console.WriteLine("Remote audio streaming... Press any key to exit.");
                Console.ReadKey();
            }
        }

        static void SetupRemoteAudio(Radio radio)
        {
            // Subscribe to the stream added event BEFORE requesting the stream
            // DataReadyEventHandler signature: (RXAudioStream stream, float[] rx_data)
            radio.RXRemoteAudioStreamAdded += (remoteStream) =>
            {
                Console.WriteLine("Remote RX audio stream created");
                
                remoteStream.DataReady += (stream, rx_data) =>
                {
                    // Opus-decoded PCM audio over WAN
                    Console.WriteLine($"Received {rx_data.Length} remote audio samples");
                };
            };
            
            // Request the stream — arrives via RXRemoteAudioStreamAdded
            radio.RequestRXRemoteAudioStream();
        }
    }
}
```

---

## PTT Control

Control transmit/receive switching programmatically.

### Software PTT

```csharp
using Flex.Smoothlake.FlexLib;
using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace MyFlexRadioApp
{
    class Program
    {
        static async Task Main(string[] args)
        {
            API.ProgramName = "MyFlexRadioApp";
            API.IsGUI = false;
            API.Init();
            
            Console.WriteLine("Waiting for radios...");
            await Task.Delay(3000);
            
            Radio? radio = API.RadioList.FirstOrDefault();
            if (radio == null)
            {
                Console.WriteLine("No radios found!");
                return;
            }
            
            Console.WriteLine($"Connecting to {radio.Nickname}...");
            radio.Connect();
            await Task.Delay(2000);
            
            if (radio.Connected)
            {
                radio.RequestSlice();
                await Task.Delay(500);
                
                Slice? slice = radio.SliceList.FirstOrDefault();
                if (slice != null)
                {
                    slice.Freq = 14.200;
                    slice.DemodMode = "USB";
                    TransmitExample(radio, slice);
                }
            }
            
            Console.WriteLine("Press any key to exit...");
            Console.ReadKey();
        }

        static void TransmitExample(Radio radio, Slice slice)
        {
            Console.WriteLine("Starting transmission...");
            
            // Mark this slice as the active TX slice, then key the transmitter via Mox
            slice.IsTransmitSlice = true;
            radio.Mox = true;
            
            // Wait for transmit to start
            Thread.Sleep(500);
            
            Console.WriteLine("Transmitting...");
            
            // Transmit for 3 seconds
            Thread.Sleep(3000);
            
            // Unkey the transmitter
            radio.Mox = false;
            
            Console.WriteLine("Transmission complete");
        }
    }
}
```

### Monitoring Interlock State

```csharp
using Flex.Smoothlake.FlexLib;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace MyFlexRadioApp
{
    class Program
    {
        static async Task Main(string[] args)
        {
            API.ProgramName = "MyFlexRadioApp";
            API.IsGUI = false;
            API.Init();
            
            Console.WriteLine("Waiting for radios...");
            await Task.Delay(3000);
            
            Radio? radio = API.RadioList.FirstOrDefault();
            if (radio == null)
            {
                Console.WriteLine("No radios found!");
                return;
            }
            
            Console.WriteLine($"Connecting to {radio.Nickname}...");
            radio.Connect();
            await Task.Delay(2000);
            
            if (radio.Connected)
            {
                MonitorInterlock(radio);
                Console.WriteLine("Monitoring interlock state... Press any key to exit.");
                Console.ReadKey();
            }
        }

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
    }
}
```

---

## Cleanup and Disposal

Always clean up resources when your application exits.

### Proper Cleanup

```csharp
using Flex.Smoothlake.FlexLib;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace MyFlexRadioApp
{
    class Program
    {
        static async Task Main(string[] args)
        {
            try
            {
                API.ProgramName = "MyFlexRadioApp";
                API.IsGUI = false;
                API.Init();
                
                // Your application code here
                Console.WriteLine("FlexLib initialized");
                await Task.Delay(3000);
                
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
    }
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

1. Verify radio is available (`radio.ConnectedState == "Available"`)
2. Close other applications connected to the radio
3. Check network connectivity with ping
4. Verify firewall allows TCP port 4992
5. Try rebooting the radio

### Slice Not Created

**Problem**: `radio.RequestSlice()` doesn't create a slice.

**Solutions**:

1. Verify radio is connected
2. Check if maximum slices already created
3. Wait longer (500-1000ms)
4. Check radio firmware version compatibility

### No Meter Data

**Problem**: Meter events not firing.

**Solutions**:

1. Look meters up with `radio.FindMeterByName` after the radio is
   connected, not before. `Radio` has no `MeterAdded` event and no
   `MeterList`
2. Check the name against the table above. `FindMeterByName` returns
   `null` for an unknown name rather than throwing, so a typo looks
   like a radio that is not reporting
3. Read values from the `DataReady` event. `Meter` has no `Value`
   property to poll
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

1. **Explore the [API Reference](API-Reference.md)** - the classes and members you use most, with a corrections table for claims earlier editions got wrong
2. **Generate the [full class reference](Generating-API-Docs.md)** - every type and member, built locally from your own copy of the FlexLib source
3. **Study [Examples](Examples.md)** - See real-world application patterns
4. **Read [Architecture](Architecture.md)** - Understand FlexLib's design
5. **Build something!** - Start your own FlexRadio application

---

**Need more help?** Visit the [FlexRadio Community Forum](https://community.flexradio.com) or contact technical support.

Happy coding! 📻
