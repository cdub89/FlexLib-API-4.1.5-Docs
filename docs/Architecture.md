# FlexLib Architecture

This document provides a comprehensive overview of FlexLib's 4.1.5 architecture, design patterns, and internal workings.

## Table of Contents

- [System Overview](#system-overview)
- [Core Components](#core-components)
- [Design Patterns](#design-patterns)
- [Threading Model](#threading-model)
- [Network Protocol](#network-protocol)
- [Data Flow](#data-flow)
- [Best Practices](#best-practices)

---

## System Overview

FlexLib is a client library that communicates with FlexRadio software-defined radios over TCP/IP networks. It provides a high-level C# API for radio control, audio streaming, and telemetry monitoring.

### High-Level Architecture

```
┌─────────────────────────────────────────────────┐
│           Your Application                      │
│    (Console, WPF, WinForms, Service)            │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│              FlexLib API                        │
│  ┌─────────┬──────────┬────────────┬─────────┐ │
│  │   API   │  Radio   │   Slice    │  Meter  │ │
│  │  Class  │  Class   │   Class    │  Class  │ │
│  └─────────┴──────────┴────────────┴─────────┘ │
│  ┌─────────────────────────────────────────┐   │
│  │    Discovery & Communication Layer      │   │
│  └─────────────────────────────────────────┘   │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│           Network Layer                         │
│  ┌──────────┬────────────┬──────────────────┐  │
│  │   UDP    │    TCP     │   VITA-49        │  │
│  │Discovery │  Commands  │   Streaming      │  │
│  └──────────┴────────────┴──────────────────┘  │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│           FlexRadio Device                      │
│      (FLEX-6300, 6400, 6600, etc.)              │
└─────────────────────────────────────────────────┘
```

### Key Layers

1. **Application Layer**: Your code using FlexLib
2. **API Layer**: High-level classes (Radio, Slice, Meter, etc.)
3. **Communication Layer**: Network protocol handling
4. **Transport Layer**: UDP/TCP/VITA-49 protocols
5. **Hardware Layer**: FlexRadio SDR device

---

## Core Components

### API Class

**Purpose**: Central initialization and radio management.

**Responsibilities**:
- Initialize discovery system
- Maintain list of discovered radios
- Manage radio lifecycle
- Provide static access to radios

**Key Members**:
```csharp
public static void Init()
public static List<Radio> RadioList
public static void CloseSession()
public static event RadioAddedEventHandler RadioAdded
public static event RadioRemovedEventHandler RadioRemoved
```

**Usage Pattern**:
```csharp
API.Init();                    // Start discovery
var radios = API.RadioList;    // Get discovered radios
API.CloseSession();            // Cleanup
```

---

### Radio Class

**Purpose**: Represents a single FlexRadio device.

**Responsibilities**:
- Manage connection to radio
- Handle command/response protocol
- Maintain radio state
- Manage child objects (Slices, Panadapters, etc.)
- Process status updates
- Handle audio/data streams

**Key Collections**:
```csharp
public ObservableCollection<Slice> SliceList
public ObservableCollection<Panadapter> PanadapterList
public ObservableCollection<Waterfall> WaterfallList
public ObservableCollection<Meter> MeterList
public ObservableCollection<Memory> MemoryList
```

**State Properties**:
```csharp
public bool Connected          // Connection status
public string Nickname         // User-defined name
public string Model            // Radio model
public string Serial           // Serial number
public IPAddress IP            // Network address
public string Version          // Firmware version
```

**Design**: Implements `INotifyPropertyChanged` for real-time updates.

---

### Slice Class

**Purpose**: Represents a receiver/transmitter channel.

**Responsibilities**:
- Frequency control
- Mode selection
- Filter configuration
- Audio routing
- PTT control
- Antenna selection

**Key Properties**:
```csharp
public double Freq             // Frequency in MHz
public string Mode             // Operating mode
public int FilterLow           // Low-pass filter Hz
public int FilterHigh          // High-pass filter Hz
public bool Active             // Slice active state
public bool Transmit           // PTT state
public string RXAnt            // RX antenna
public string TXAnt            // TX antenna
```

**Lifecycle**:
1. Created by `Radio.RequestSliceFromRadio()`
2. Configured via property setters
3. Monitored via `PropertyChanged` events
4. Removed by `Radio.RemoveSlice(slice)`

---

### Discovery Class

**Purpose**: Discover FlexRadio devices on the network.

**Mechanism**:
- Opens UDP socket on port 4992
- Sends discovery packets periodically
- Listens for radio announcements
- Parses discovery information
- Notifies API class of new radios

**Protocol**:
```
Radio → UDP Broadcast → Port 4992
Format: Key=Value pairs
Example: "model=FLEX-6600 serial=1234-5678-9012-3456 ..."
```

**Discovery Packet Fields**:
- `discovery_protocol_version`
- `model`
- `serial`
- `version`
- `nickname`
- `ip`
- `port`
- `status`

---

### Audio Streaming Classes

#### DAXRXAudioStream

**Purpose**: Receive audio from radio for playback or processing.

**Characteristics**:
- Mono audio stream
- 24kHz, 48kHz, or 96kHz sample rate
- 32-bit float samples
- VITA-49 packet protocol

**Usage**:
```csharp
var stream = radio.CreateDAXRXAudioStream(1); // DAX channel 1
stream.DataReady += (samples) => ProcessAudio(samples);
stream.Start();
```

#### DAXTXAudioStream

**Purpose**: Send audio to radio for transmission.

**Usage**: Provide audio samples for transmission.

#### DAXIQStream

**Purpose**: IQ data streaming for digital modes.

**Characteristics**:
- Interleaved I/Q samples
- High sample rate (up to 192kHz)
- Used for SDR applications

---

### Meter Class

**Purpose**: Real-time telemetry monitoring.

**Types of Meters**:
- **Signal meters**: SIGNAL, MICPEAK, COMPPEAK
- **Power meters**: FWD, REF, SWR
- **System meters**: VOLTAGE, TEMP
- **Audio meters**: LEVELPEAK, LEVELAVG

**Usage Pattern**:
```csharp
radio.MeterAdded += (meter) =>
{
    meter.DataReady += (data) =>
    {
        Console.WriteLine($"{meter.Name}: {data.Value}");
    };
};
```

---

## Design Patterns

### Observer Pattern

**Usage**: Extensive use of C# events for state changes.

**Implementation**:
```csharp
// INotifyPropertyChanged for object property changes
public event PropertyChangedEventHandler PropertyChanged;

// Custom events for object lifecycle
public event SliceAddedEventHandler SliceAdded;
public event SliceRemovedEventHandler SliceRemoved;

// Data events for streaming
public event DataReadyEventHandler DataReady;
```

**Benefits**:
- Decoupled architecture
- Real-time updates
- Event-driven programming model
- Natural fit for UI applications

---

### Command Pattern

**Usage**: Radio command/response protocol.

**Implementation**:
```csharp
// Internal command structure
class RadioCommand
{
    public string Command { get; set; }
    public int SequenceNumber { get; set; }
    public TaskCompletionSource<string> Response { get; set; }
}

// Example usage internally:
SendCommand("slice tune " + index + " " + freq);
```

**Protocol Format**:
```
Client → Radio: "C<seq>|<command> <args>"
Radio → Client: "R<seq>|<result>"
```

**Example**:
```
Client: "C1|slice create"
Radio: "R1|0|slice 0"
```

---

### Factory Pattern

**Usage**: Creating streaming objects and connections.

**Examples**:
```csharp
// Factory methods on Radio class
public DAXRXAudioStream CreateDAXRXAudioStream(int daxChannel);
public DAXIQStream CreateDAXIQStream(int daxChannel);
public RXRemoteAudioStream CreateRXRemoteAudioStream();
```

**Benefits**:
- Centralized object creation
- Proper initialization
- Resource management

---

### MVVM Pattern Support

**Integration**: FlexLib supports MVVM via `ObservableObject` base class.

**Provided by**: UiWpfFramework

**Usage**:
```csharp
// Radio, Slice, and other classes inherit from ObservableObject
public class Slice : ObservableObject
{
    private double _freq;
    
    public double Freq
    {
        get { return _freq; }
        set
        {
            if (_freq != value)
            {
                _freq = value;
                RaisePropertyChanged("Freq");
            }
        }
    }
}
```

**Benefits for WPF/UI**:
- Data binding support
- Automatic UI updates
- Reduced boilerplate code

---

## Threading Model

### Main Threads

1. **UI Thread**: Your application's main thread
2. **Discovery Thread**: UDP discovery listener
3. **Command Thread**: TCP command socket reader
4. **VITA Thread(s)**: Audio/IQ packet processors
5. **Meter Thread**: Meter data processing

### Thread Safety

**Event Callbacks**: FlexLib events fire on **background threads**, not the UI thread.

**Important**: For WPF/UI updates, use `Dispatcher.Invoke()`:

```csharp
radio.PropertyChanged += (sender, e) =>
{
    // This runs on a background thread!
    
    Application.Current.Dispatcher.Invoke(() =>
    {
        // Now safe to update UI
        statusLabel.Content = radio.Status;
    });
};
```

### Synchronization

FlexLib uses:
- `lock` statements for critical sections
- `ConcurrentDictionary` for thread-safe collections
- `ImmutableList` for read-only collections
- `ObservableCollection` with proper locking

---

## Network Protocol

### Discovery Protocol (UDP)

**Port**: 4992  
**Type**: UDP Broadcast  
**Direction**: Radio → Client

**Packet Format**:
```
discovery_protocol_version=3.0.0.2
model=FLEX-6600
serial=1234-5678-9012-3456
version=3.2.39
nickname=K5DTO Station
ip=192.168.1.100
port=4992
status=Available
...
```

**Timing**: Radios broadcast every 5-10 seconds.

---

### Command Protocol (TCP)

**Port**: 4992  
**Type**: TCP  
**Format**: ASCII text, newline-terminated

**Command Format**:
```
C<sequence>|<command> <args>
```

**Response Format**:
```
R<sequence>|<result_code>|<data>
```

**Status Updates** (unsolicited):
```
S<hex_handle>|<object_type> <properties>
```

**Examples**:

```
# Create a slice
Client: C1|slice create
Radio:  R1|0|slice 0

# Tune slice
Client: C2|slice tune 0 14.200
Radio:  R2|0

# Status update
Radio:  S12345678|slice 0 freq=14.200000 mode=USB
```

**Result Codes**:
- `0`: Success
- Non-zero: Error (with error message)

---

### VITA-49 Protocol (UDP)

**Purpose**: High-performance audio/IQ streaming.

**Characteristics**:
- UDP packets
- Binary format
- Header + payload structure
- Sequence numbers for packet loss detection
- Timestamps for synchronization

**Packet Structure**:
```
┌────────────────┐
│  VITA Header   │ 28 bytes
├────────────────┤
│  Audio/IQ Data │ Variable
└────────────────┘
```

**Stream Types**:
- **Audio**: 32-bit float PCM
- **IQ**: Interleaved I/Q samples
- **DAX**: Multiple channels possible

---

## Data Flow

### Connection Flow

```
1. Application calls API.Init()
   ↓
2. Discovery starts, sends UDP broadcasts
   ↓
3. Radio responds with discovery packet
   ↓
4. Radio object created, added to RadioList
   ↓
5. RadioAdded event fired
   ↓
6. Application calls radio.Connect()
   ↓
7. TCP connection established
   ↓
8. Initial status updates received
   ↓
9. Connected property set to true
   ↓
10. Application can now control radio
```

### Slice Creation Flow

```
1. Application calls radio.RequestSliceFromRadio()
   ↓
2. Command sent: "C<seq>|slice create"
   ↓
3. Radio responds: "R<seq>|0|slice 0"
   ↓
4. Radio sends status: "S...|slice 0 freq=14.200 ..."
   ↓
5. Slice object created
   ↓
6. SliceAdded event fired
   ↓
7. Slice appears in radio.SliceList
```

### Property Change Flow

```
1. Application sets: slice.Freq = 14.200
   ↓
2. Property setter checks if value changed
   ↓
3. Command sent: "C<seq>|slice tune 0 14.200"
   ↓
4. Radio responds: "R<seq>|0"
   ↓
5. Radio applies change
   ↓
6. Radio sends status: "S...|slice 0 freq=14.200000"
   ↓
7. Status parser updates local property
   ↓
8. PropertyChanged event fired
   ↓
9. UI/application updates
```

---

## Best Practices

### Initialization

✅ **Do**:
```csharp
// Initialize once at startup
API.ProgramName = "MyApp";
API.Init();

// Subscribe to events before Init()
API.RadioAdded += OnRadioAdded;
API.Init();
```

❌ **Don't**:
```csharp
// Don't call Init() multiple times
API.Init();
API.Init(); // BAD!

// Don't forget to set ProgramName
API.Init(); // Missing ProgramName
```

---

### Connection Management

✅ **Do**:
```csharp
// Check availability before connecting
if (radio.Available && !radio.Connected)
{
    radio.Connect();
}

// Wait for connection with timeout
for (int i = 0; i < 50 && !radio.Connected; i++)
    await Task.Delay(100);
```

❌ **Don't**:
```csharp
// Don't assume immediate connection
radio.Connect();
var slice = radio.SliceList.First(); // May fail!

// Don't connect without checking
radio.Connect(); // Maybe already connected or unavailable
```

---

### Property Updates

✅ **Do**:
```csharp
// Use PropertyChanged for updates
slice.PropertyChanged += (s, e) =>
{
    if (e.PropertyName == "Freq")
        Console.WriteLine($"Frequency: {slice.Freq}");
};

// Batch related changes
slice.Freq = 14.200;
slice.Mode = "USB";
slice.FilterLow = 200;
slice.FilterHigh = 2800;
```

❌ **Don't**:
```csharp
// Don't poll properties
while (true)
{
    Console.WriteLine(slice.Freq); // Inefficient!
    Thread.Sleep(100);
}
```

---

### Threading

✅ **Do**:
```csharp
// Use Dispatcher for UI updates
radio.PropertyChanged += (s, e) =>
{
    Dispatcher.Invoke(() =>
    {
        statusLabel.Content = radio.Status;
    });
};

// Use async/await properly
await Task.Run(() => LongRunningOperation());
```

❌ **Don't**:
```csharp
// Don't update UI from events directly
radio.PropertyChanged += (s, e) =>
{
    statusLabel.Content = radio.Status; // Cross-thread!
};
```

---

### Resource Cleanup

✅ **Do**:
```csharp
try
{
    API.Init();
    // Your code...
}
finally
{
    // Always cleanup
    foreach (var radio in API.RadioList)
        radio.Disconnect();
    
    API.CloseSession();
}
```

❌ **Don't**:
```csharp
// Don't forget cleanup
API.Init();
// ... code ...
return; // Leaked resources!
```

---

### Error Handling

✅ **Do**:
```csharp
try
{
    radio.Connect();
}
catch (Exception ex)
{
    Console.WriteLine($"Connection failed: {ex.Message}");
    // Handle gracefully
}

// Check results
if (radio.Connected)
{
    // Proceed
}
else
{
    // Handle failure
}
```

❌ **Don't**:
```csharp
// Don't ignore errors
radio.Connect(); // May throw or fail silently

// Don't swallow exceptions
try { radio.Connect(); }
catch { } // Lost error information!
```

---

## Performance Considerations

### Discovery Performance

- Discovery takes 2-5 seconds typically
- Wait adequate time before assuming no radios
- Don't call `API.Init()` repeatedly

### Command Latency

- TCP commands: ~10-50ms round trip
- Status updates: Asynchronous, varies
- Don't send commands too rapidly

### Audio Streaming

- VITA-49 uses UDP: Some packet loss expected
- Buffer audio to handle jitter
- Use appropriate sample rates for your needs

### Memory Usage

- Each radio: ~10-50 MB depending on configuration
- Audio streams: Additional buffers
- Monitor memory if managing many radios

---

## Debugging Tips

### Enable Logging

FlexLib can enable debug logging:

```
Create file:
%APPDATA%\FlexRadio Systems\log_discovery.txt
%APPDATA%\FlexRadio Systems\log_disconnect.txt
```

### Network Monitoring

Use Wireshark to monitor:
- UDP port 4992 (discovery)
- TCP port 4992 (commands)
- UDP streaming ports (audio/IQ)

### Common Issues

1. **No radios discovered**: Check network, firewall
2. **Connection fails**: Radio may be in use
3. **Commands ignored**: Check radio connection
4. **No audio**: Verify DAX configuration
5. **UI freezes**: Use Dispatcher for events

---

## Summary

FlexLib provides a powerful, event-driven API for FlexRadio control:

- **Clean architecture**: Layered design with clear separation
- **Flexible**: Supports console, GUI, and service applications
- **Real-time**: Event-driven for responsive applications
- **Comprehensive**: Full radio control and streaming
- **Well-tested**: Used in SmartSDR and many applications

Understanding this architecture will help you build robust, efficient FlexRadio applications!
