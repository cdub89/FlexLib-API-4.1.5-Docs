# API Reference

Quick reference guide for FlexLib API 4.1.5 classes and methods. For complete XML documentation, use DocFX to generate full API docs.

## Table of Contents

- [Core Classes](#core-classes)
- [Audio Streaming](#audio-streaming)
- [Visual Display](#visual-display)
- [Control Features](#control-features)
- [USB Cables](#usb-cables)
- [Enumerations](#enumerations)

---

## Core Classes

### API Class

Central initialization and radio discovery management.

#### Static Methods

```csharp
void Init()
```
Initialize FlexLib and start radio discovery. Must be called before using any radio functionality.

```csharp
void CloseSession()
```
Cleanup and close all connections. Call when application exits.

#### Static Properties

```csharp
string ProgramName { get; set; }
```
Name of your application. Required before calling `Init()`.

```csharp
bool IsGUI { get; set; }
```
Set to `true` if application has a GUI, `false` for console/headless apps.

```csharp
List<Radio> RadioList { get; }
```
List of all discovered radios on the network.

#### Static Events

```csharp
event RadioAddedEventHandler RadioAdded
```
Fired when a new radio is discovered.

```csharp
event RadioRemovedEventHandler RadioRemoved
```
Fired when a radio is no longer available.

---

### Radio Class

Represents a single FlexRadio device.

#### Connection Methods

```csharp
void Connect()
```
Connect to the radio. Check `Connected` property afterward.

```csharp
void Disconnect()
```
Disconnect from the radio.

#### Properties

##### Connection Status
```csharp
bool Connected { get; }              // Is connected
bool Available { get; }              // Can connect
string Status { get; }               // Current status text
```

##### Radio Information
```csharp
string Nickname { get; }             // User-defined name
string Model { get; }                // e.g., "FLEX-6600"
string Serial { get; }               // Serial number
IPAddress IP { get; }                // Network IP address
string Version { get; }              // Firmware version
```

##### Collections
```csharp
ObservableCollection<Slice> SliceList { get; }
ObservableCollection<Panadapter> PanadapterList { get; }
ObservableCollection<Waterfall> WaterfallList { get; }
ObservableCollection<Meter> MeterList { get; }
ObservableCollection<Memory> MemoryList { get; }
ObservableCollection<Equalizer> EQList { get; }
ObservableCollection<TNF> TNFList { get; }
ObservableCollection<Xvtr> XvtrList { get; }
```

##### Transmit State
```csharp
InterlockState InterlockState { get; }    // TX/RX state
InterlockReason InterlockReason { get; }  // Reason for state
PTTSource PTTSource { get; }              // PTT input source
bool Mox { get; set; }                    // Master TX control
```

#### Slice Management

```csharp
void RequestSliceFromRadio()
```
Request creation of a new slice. Listen for `SliceAdded` event.

```csharp
void RemoveSlice(Slice slice)
```
Remove an existing slice.

#### Audio Stream Creation

```csharp
DAXRXAudioStream CreateDAXRXAudioStream(int daxChannel)
```
Create a DAX receive audio stream.

```csharp
DAXTXAudioStream CreateDAXTXAudioStream(int daxChannel)
```
Create a DAX transmit audio stream.

```csharp
DAXIQStream CreateDAXIQStream(int daxChannel)
```
Create a DAX IQ data stream.

```csharp
RXRemoteAudioStream CreateRXRemoteAudioStream()
```
Create a remote RX audio stream (for WAN).

```csharp
TXRemoteAudioStream CreateTXRemoteAudioStream()
```
Create a remote TX audio stream (for WAN).

#### Panadapter Management

```csharp
void RequestPanadapter()
```
Request creation of a new panadapter. Listen for `PanadapterAdded` event.

#### Events

```csharp
event SliceAddedEventHandler SliceAdded
event SliceRemovedEventHandler SliceRemoved
event PanadapterAddedEventHandler PanadapterAdded
event WaterfallAddedEventHandler WaterfallAdded
event MeterAddedEventHandler MeterAdded
event PropertyChangedEventHandler PropertyChanged
```

---

### Slice Class

Represents a receiver/transmitter channel.

#### Frequency Control

```csharp
double Freq { get; set; }            // Frequency in MHz
double FreqStep { get; set; }        // Tuning step in MHz
bool Lock { get; set; }              // Frequency lock
```

#### Mode and Filter

```csharp
string Mode { get; set; }            // Operating mode (USB, LSB, CW, etc.)
int FilterLow { get; set; }          // Low filter cutoff (Hz)
int FilterHigh { get; set; }         // High filter cutoff (Hz)
```

**Supported Modes**: `"LSB"`, `"USB"`, `"AM"`, `"SAM"`, `"CW"`, `"FM"`, `"NFM"`, `"DFM"`, `"DIGL"`, `"DIGU"`, `"RTTY"`

#### Audio Control

```csharp
int AudioGain { get; set; }          // Audio gain 0-100
int AudioPan { get; set; }           // Audio pan -100 to 100
bool AudioMute { get; set; }         // Mute audio
int DAXChannel { get; set; }         // DAX channel assignment
```

#### AGC and Processing

```csharp
string AGCMode { get; set; }         // AGC mode
int AGCThreshold { get; set; }       // AGC threshold (dBm)
bool ANFEnabled { get; set; }        // Auto Notch Filter
bool APFEnabled { get; set; }        // Audio Peak Filter
bool NBEnabled { get; set; }         // Noise Blanker
int NR { get; set; }                 // Noise Reduction level
```

**AGC Modes**: `"off"`, `"slow"`, `"med"`, `"fast"`

#### Antenna Selection

```csharp
string RXAnt { get; set; }           // RX antenna (ANT1, ANT2, XVTR, RX_A, RX_B)
string TXAnt { get; set; }           // TX antenna (ANT1, ANT2, XVTR)
```

#### Transmit Control

```csharp
bool Transmit { get; set; }          // PTT state
bool Active { get; set; }            // Slice active state
bool TX { get; set; }                // TX assigned
```

#### Properties

```csharp
int Index { get; }                   // Slice index (0-7)
string Letter { get; }               // Slice letter (A-H)
bool InUse { get; }                  // Slice in use
Panadapter Panadapter { get; }       // Associated panadapter
```

---

### Meter Class

Real-time telemetry monitoring.

#### Properties

```csharp
string Name { get; }                 // Meter name
string Units { get; }                // Unit of measurement
string Source { get; }               // Data source
float Value { get; }                 // Current value
```

#### Events

```csharp
event DataReadyEventHandler DataReady
```
Fired when new meter data is available. Provides meter value.

#### Common Meter Names

| Name | Description | Unit |
|------|-------------|------|
| `MICPEAK` | Microphone peak level | dB |
| `MICAVG` | Microphone average level | dB |
| `COMPPEAK` | Compressor peak level | dB |
| `POSTFILT` | Post-filter audio level | dB |
| `SWR` | Standing wave ratio | ratio |
| `FWD` | Forward power | watts |
| `REF` | Reflected power | watts |
| `VOLTAGE` | Power supply voltage | volts |
| `TEMP` | PA temperature | °C |
| `SIGNAL` | Signal strength | dBm |

---

## Audio Streaming

### DAXRXAudioStream Class

Receive audio from the radio.

#### Methods

```csharp
void Start()
```
Start audio streaming.

```csharp
void Stop()
```
Stop audio streaming.

#### Properties

```csharp
int DAXChannel { get; }              // DAX channel number
int SampleRate { get; }              // Sample rate (Hz)
bool Streaming { get; }              // Is streaming active
```

#### Events

```csharp
event DataReadyEventHandler<float[]> DataReady
```
Fired when audio samples are available. Provides `float[]` array of samples.

**Sample Format**: 32-bit float, mono, -1.0 to 1.0 range.

---

### DAXTXAudioStream Class

Transmit audio to the radio.

#### Methods

```csharp
void Start()
void Stop()
void AddTXData(float[] samples)
```
Add audio samples to transmit buffer.

---

### DAXIQStream Class

IQ data streaming for digital modes.

#### Events

```csharp
event DataReadyEventHandler<float[]> DataReady
```
IQ samples arrive interleaved: `[I, Q, I, Q, I, Q, ...]`

**Usage**: Split into separate I and Q arrays for processing.

---

## Visual Display

### Panadapter Class

Spectrum display control.

#### Properties

```csharp
double CenterFreq { get; set; }      // Center frequency (MHz)
double Bandwidth { get; set; }       // Displayed bandwidth (MHz)
int MinDBM { get; set; }             // Minimum display level
int MaxDBM { get; set; }             // Maximum display level
int RFGain { get; set; }             // RF gain
uint StreamID { get; }               // Stream identifier
```

#### Events

```csharp
event DataReadyEventHandler<float[]> DataReady
```
Spectrum data ready. Array contains dBm values across bandwidth.

---

### Waterfall Class

Waterfall display control.

#### Properties

```csharp
double CenterFreq { get; }           // Center frequency (MHz)
double Bandwidth { get; }            // Bandwidth (MHz)
int MinDBM { get; set; }             // Minimum level
int MaxDBM { get; set; }             // Maximum level
```

---

## Control Features

### Equalizer Class

Audio equalizer control.

#### Methods

```csharp
void SetLevel(int band, int level)
```
Set EQ level for band. Band: 0-9, Level: -10 to +10 dB.

#### Properties

```csharp
bool Enabled { get; set; }           // EQ enabled
string Mode { get; set; }            // "rx" or "tx"
```

---

### TNF Class

Tracking Notch Filter for interference removal.

#### Properties

```csharp
double Freq { get; set; }            // Notch frequency
int Depth { get; set; }              // Notch depth (dB)
int Width { get; set; }              // Notch width (Hz)
bool Permanent { get; set; }         // Permanent or auto-track
```

---

### Memory Class

Station memory management.

#### Properties

```csharp
string Name { get; set; }            // Memory name
double Freq { get; set; }            // Frequency
string Mode { get; set; }            // Operating mode
int Group { get; set; }              // Memory group
```

#### Methods

```csharp
void Apply()
```
Apply memory settings to a slice.

---

### Tuner Class

Automatic antenna tuner.

#### Methods

```csharp
void StartTune()
```
Start automatic tuning.

#### Properties

```csharp
bool Enabled { get; set; }           // Tuner enabled
bool Bypass { get; set; }            // Bypass tuner
```

---

### Amplifier Class

External amplifier control.

#### Properties

```csharp
string Model { get; }                // Amplifier model
bool Enable { get; set; }            // Amplifier control enabled
int Handle { get; }                  // Amplifier handle
```

---

### Xvtr Class

Transverter management.

#### Properties

```csharp
string Name { get; set; }            // Transverter name
double RFFreq { get; set; }          // RF frequency
double IFFreq { get; set; }          // IF frequency
int MaxPower { get; set; }           // Max power (watts)
```

---

## USB Cables

### IUsbCable Interface

Base interface for USB cable control.

```csharp
void Enable()
void Disable()
bool Enabled { get; set; }
string Name { get; }
```

### UsbCatCable Class

CAT (Computer Aided Transceiver) control cable.

### UsbBcdCable Class

BCD (Binary Coded Decimal) band output cable.

### UsbLdpaCable Class

Linear Driver/PA control cable.

### UsbBitCable Class

Digital I/O bit cable.

---

## Enumerations

### InterlockState

```csharp
enum InterlockState
{
    None,
    Receive,
    Ready,
    NotReady,
    PTTRequested,
    Transmitting,
    TXFault,
    Timeout,
    StuckInput,
    UnkeyRequested
}
```

### InterlockReason

```csharp
enum InterlockReason
{
    None,
    RCA_TXREQ,
    ACC_TXREQ,
    BAD_MODE,
    TUNED_TOO_FAR,
    OUT_OF_BAND,
    PA_RANGE,
    CLIENT_TX_INHIBIT,
    XVTR_RX_ONLY,
    // ... more reasons
}
```

### PTTSource

```csharp
enum PTTSource
{
    None,
    SW,      // Software (SmartSDR, CAT, etc.)
    Mic,     // Microphone
    ACC,     // Accessory port
    RCA,     // RCA connector
    TUNE     // Tune button
}
```

---

## Usage Examples

### Basic Connection

```csharp
API.Init();
await Task.Delay(2000);

var radio = API.RadioList.FirstOrDefault();
radio?.Connect();
```

### Create and Tune Slice

```csharp
radio.RequestSliceFromRadio();
await Task.Delay(500);

var slice = radio.SliceList.FirstOrDefault();
if (slice != null)
{
    slice.Freq = 14.200;
    slice.Mode = "USB";
}
```

### Monitor Meters

```csharp
radio.MeterAdded += (meter) =>
{
    if (meter.Name == "SWR")
    {
        meter.DataReady += (data) =>
        {
            Console.WriteLine($"SWR: {data.Value:F2}:1");
        };
    }
};
```

### Audio Streaming

```csharp
var stream = radio.CreateDAXRXAudioStream(1);
stream.DataReady += (samples) =>
{
    // Process audio samples
};
stream.Start();
```

---

## Additional Resources

- **[Getting Started Guide](Getting-Started.md)** - Detailed tutorials
- **[Examples](Examples.md)** - Complete code examples
- **[Architecture](Architecture.md)** - System design details
- **DocFX Generated Docs** - Full API documentation with all methods

---

## Notes

- All events fire on background threads - use `Dispatcher` for UI updates
- Property changes are synchronized with the radio automatically
- Always call `API.Init()` before using any radio functionality
- Always call `API.CloseSession()` when exiting
- Check `radio.Connected` before sending commands
- Wait for async operations (slice creation, etc.) to complete

---

**For complete API documentation**, generate HTML docs using DocFX:

```bash
docfx docs/docfx.json
docfx serve docs/_site
```
