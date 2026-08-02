# API Reference

> **Verified against FlexLib 4.2.20.41343.** Signatures on this page were
> read from the 4.2.20 source.

Quick reference for **FlexLib API 4.2.20.41343** classes and members. For the
complete generated class reference, build it locally from your own copy of
the source: see [Generating the full API reference](Generating-API-Docs.md).

> **Regenerated against 4.2.20.** The previous edition of this file documented
> 4.1.5 and carried a number of members that do not exist in the shipping
> library. See [Corrections from the 4.1.5 edition](#corrections-from-the-415-edition)
> before reusing any code written against the old reference.

## Table of Contents

- [Corrections from the 4.1.5 edition](#corrections-from-the-415-edition)
- [Core Classes](#core-classes)
- [Audio Streaming](#audio-streaming)
- [Visual Display](#visual-display)
- [Control Features](#control-features)
- [USB Cables](#usb-cables)
- [Enumerations](#enumerations)

---

## Corrections from the 4.1.5 edition

These are not 4.1.5-to-4.2.20 API changes. They are places where the previous
edition of these guides did not match the library. Code copied from the old
reference will fail to compile or will silently target the wrong member.

| Old reference said | Actually is | Impact |
| --- | --- | --- |
| `Slice.Mode` (string) | `Slice.DemodMode` (string), valid values in `Slice.ModeList` | Does not compile |
| `Slice.InUse` | Absent | Does not compile |
| `Slice.AGCMode` is a `string` (`"off"`, `"slow"`, `"med"`, `"fast"`) | `AGCMode` enum (`None`, `Off`, `Slow`, `Medium`, `Fast`) | Does not compile |
| `Radio.MeterList` | Absent. Use `Radio.FindMeterByName(string)` | Does not compile |
| `radio.MeterAdded` event | Absent on `Radio`. Exists on `Slice`, `Amplifier`, and `Tuner` | Does not compile |
| `Meter.Value` property | Absent. Values arrive via the `DataReady` event | Does not compile |
| `Meter.Units` is a `string` | `MeterUnits` enum | Does not compile |
| `Radio.RemoveSlice(slice)` | `slice.Close()` | Does not compile |
| `Radio.RequestPanadapter()` | `Radio.RequestPanafall()` | Does not compile |
| `Radio.WaterfallList`, `EQList`, `XvtrList` | Absent. Use the `Find*` / `Create*` methods | Does not compile |
| Collections are `ObservableCollection<T>` | `List<T>` | Compiles, breaks binding assumptions |
| `Panadapter.MinDBM` / `MaxDBM` (int) | `LowDbm` / `HighDbm` (double) | Does not compile |
| `Panadapter.DataReady` delivers `float[]` dBm | Delivers `ushort[]` | Wrong data handling |
| Meter names `FWD`, `REF`, `TEMP`, `VOLTAGE` | `FWDPWR`, `REFPWR`, `PATEMP`, `+13.8A` | Lookup silently returns null |
| `Tuner.StartTune()` / `Tuner.Enabled` / `Tuner.Bypass` | `Tuner` is the **external network tuner**. The radio's built-in ATU is `Radio.ATUTuneStart()` / `ATUTuneBypass()` | Wrong object entirely |
| `Equalizer.SetLevel(band, level)` / `Enabled` / `Mode` | `level_32Hz` … `level_8000Hz`, `EQ_enabled`, `EQ_select` | Does not compile |
| `Memory.Apply()`, `Group` (int) | `Memory.Select()`, `Group` (string) | Does not compile |
| `TNF.Width` (int), `Depth` (int) | `Bandwidth` (double), `Depth` (uint) | Does not compile |
| `Amplifier.Handle` (int), `Enable` | `Handle` (string); no `Enable` | Does not compile |
| `Xvtr.MaxPower` (int) | `MaxPower` (double) | Does not compile |
| The Migration Guide said the HAAPI fault handler signature was unchanged from 4.1.5, only renamed | 4.1.5 `AmplifierFaultEventHandler(string reason)` takes one parameter; 4.2.x `HaapiFaultEventHandler(string noun, string reason)` takes two | Does not compile |
| The Migration Guide listed `RadioPlatform.DragonFire`, the FLEX-8x00 / ML-9600 / AU-5x0 models, `TlsCommandCommunication`, and five `Radio` properties as new in 4.2.x | All present in 4.1.5.39794 already. Only `Radio.IsSystemModel` and `Radio.TurfRegion` are new | Wasted migration work |
| The Migration Guide said the `DAXMICAudioStream.RXGain` dB curve changed in 4.2.x | Identical in both versions: 0-100 maps linearly to -10 dB to +10 dB | Needless re-tuning of audio levels |

The most consequential of these for telemetry work: **there is no
`Radio.MeterList` and no `Radio.MeterAdded`**, and **`Meter` has no `Value`
property**. See [Telemetry](#telemetry-meter-events) for the supported route.

---

## Core Classes

### API Class

Central initialization and radio discovery management. Static throughout.

#### Static Methods

```csharp
void Init()
```

Initialize FlexLib and start radio discovery. Must be called before using any
radio functionality.

```csharp
void CloseSession()
```

Cleanup and close all connections. Call when the application exits.

#### Static Properties

```csharp
string ProgramName { get; set; }     // Your application name. Set before Init()
bool IsGUI { get; set; } = false;    // true for GUI clients, false for headless
List<Radio> RadioList { get; }       // Discovered radios (computed each access)
```

`IsGUI` defaults to `false`. A non-GUI client does not own slices or
panadapters; it observes and controls those created by a GUI client.

#### Static Events

```csharp
event RadioAddedEventHandler RadioAdded
event RadioRemovedEventHandler RadioRemoved
event RadioChangedIpEventHandler RadioChangedIp
event WanListReceivedEventHandler WanListReceived
```

---

### Radio Class

Represents a single FlexRadio device.

#### Connection

```csharp
bool Connect(string gui_client_id = null)
```

Connect to the radio. Returns `true` on success. The optional `gui_client_id`
binds this session to a specific GUI client.

```csharp
void Disconnect()
void DisconnectAllGuiClients()
void DisconnectClientByHandle(string handle)
```

#### Client binding

```csharp
string BoundClientID { get; set; }   // Setting this calls BindGUIClient()
void BindGUIClient(string client_id)
uint ClientHandle { get; }
```

Binding matters for non-GUI clients: it establishes which GUI client's context
(notably the active slice) this session follows.

#### Properties

##### Connection status

```csharp
bool Connected { get; }              // Is connected
string ConnectedState { get; set; }  // "Available", "In Use", "Update", ...
string Status { get; }               // Current status text
bool IsWan { get; }                  // SmartLink (WAN) session
```

##### Radio information

```csharp
string Nickname { get; }             // User-defined name
string Model { get; }                // e.g. "FLEX-6600"
string Serial { get; }               // Serial number
IPAddress IP { get; }                // Network address
ulong Version { get; set; }          // Firmware version
```

##### Collections

These are `List<T>`, not `ObservableCollection<T>`. Use the `*Added` /
`*Removed` events to track changes.

```csharp
List<Slice> SliceList { get; }
List<Panadapter> PanadapterList { get; }
List<Memory> MemoryList { get; }
List<TNF> TNFList { get; }
List<Amplifier> AmplifierList { get; }
```

There is no `MeterList`, `WaterfallList`, `EQList`, or `XvtrList`. Use the
lookup methods below.

##### Lookups and factories

```csharp
Meter FindMeterByName(string s)
Waterfall FindWaterfallByParentStreamID(uint stream_id)
Waterfall FindWaterfallByDAXIQChannel(int daxIQChannel)
Equalizer CreateEqualizer(EqualizerSelect eq_select)
Equalizer FindEqualizerByEQSelect(EqualizerSelect eq_select)
Xvtr CreateXvtr()
Xvtr FindXvtrByIndex(int index)
```

##### Transmit state

```csharp
InterlockState InterlockState { get; }    // TX/RX state
InterlockReason InterlockReason { get; }  // Reason for that state
PTTSource PTTSource { get; }              // PTT input source
bool Mox { get; set; }                    // Master TX control (PTT)
int RFPower { get; set; }                 // TX power, watts, clamped 0-100
int TunePower { get; set; }               // Tune power, watts, clamped 0-100
bool TXReqRCAEnabled { get; set; }
```

`RFPower` and `TunePower` clamp out-of-range values in the setter rather than
throwing, and emit `transmit set rfpower=N` / `transmit set tunepower=N`.

##### Built-in antenna tuner (ATU)

```csharp
bool ATUPresent { get; }
bool ATUEnabled { get; }
bool ATUMemoriesEnabled { get; set; }
bool ATUUsingMemory { get; }
void ATUTuneStart()
void ATUTuneBypass()
```

This is the radio's internal ATU. The separate [`Tuner`](#tuner-class) class is
an external networked tuner and is unrelated.

#### Slice management

```csharp
void RequestSlice()
void RequestSlice(Panadapter pan, string demod_mode = "", double freq = 0.0,
                  string rx_ant = "", bool load_persistence = false)
Slice RequestSliceBlocking(Panadapter pan, double freq = 0.0, string rxant = "",
                           string mode = "", bool load_persistence = false)
```

The non-blocking forms return immediately; handle the new slice in the
`SliceAdded` event. `RequestSliceBlocking` returns the `Slice` directly.

To remove a slice, call `slice.Close()`. There is no `Radio.RemoveSlice`.

#### Panadapter management

```csharp
void RequestPanafall()
```

Creates a panadapter and its child waterfall as a pair. Handle the result in
`PanadapterAdded`, whose delegate delivers **both** objects. To remove, call
`pan.Close()`.

#### Audio stream creation

Streams are created asynchronously. Subscribe to the corresponding `*Added`
event **before** calling the `Request*` method.

```csharp
void RequestDAXRXAudioStream(int channel)
void RequestDAXTXAudioStream()
void RequestDAXIQStream(int channel)
void RequestRXRemoteAudioStream()
void RequestRXRemoteAudioStream(bool isCompressed)
TXRemoteAudioStream CreateOpusStream()   // returns directly, not via event
```

#### Telemetry (meter events)

`Radio` matches incoming meters by name internally and re-publishes the common
ones as typed events. This is the supported route: it avoids depending on meter
name strings, which are not stable or guessable.

```csharp
public delegate void MeterDataReadyEventHandler(float data);

event MeterDataReadyEventHandler ForwardPowerDataReady;    // watts
event MeterDataReadyEventHandler ReflectedPowerDataReady;  // watts
event MeterDataReadyEventHandler SWRDataReady;             // ratio
event MeterDataReadyEventHandler PATempDataReady;          // degrees C
event MeterDataReadyEventHandler VoltsDataReady;           // volts
event MeterDataReadyEventHandler MicDataReady;
event MeterDataReadyEventHandler MicPeakDataReady;
event MeterDataReadyEventHandler CompPeakDataReady;
event MeterDataReadyEventHandler HWAlcDataReady;
event MeterDataReadyEventHandler PAEffDataReady;
```

The underlying meter names are listed under [Meter Class](#meter-class). Note
that supply voltage is reported by a meter named `+13.8A`, not `VOLTAGE`.

#### Events

```csharp
public delegate void SliceAddedEventHandler(Slice slc);
public delegate void SliceRemovedEventHandler(Slice slc);
public delegate void PanadapterAddedEventHandler(Panadapter pan, Waterfall fall);
public delegate void WaterfallAddedEventHandler(Waterfall wf);
public delegate void DAXRXAudioStreamAddedEventHandler(DAXRXAudioStream s);
public delegate void DAXIQStreamAddedEventHandler(DAXIQStream iq_stream);
```

```csharp
event SliceAddedEventHandler SliceAdded
event SliceRemovedEventHandler SliceRemoved
event SlicePanReferenceChangeEventHandler SlicePanReferenceChange
event PanadapterAddedEventHandler PanadapterAdded
event PanadapterRemovedEventHandler PanadapterRemoved
event WaterfallAddedEventHandler WaterfallAdded
event WaterfallRemovedEventHandler WaterfallRemoved
event DAXRXAudioStreamAddedEventHandler DAXRXAudioStreamAdded
event DAXRXAudioStreamRemovedEventHandler DAXRXAudioStreamRemoved
event DAXTXAudioStreamAddedEventHandler DAXTXAudioStreamAdded
event DAXTXAudioStreamRemovedEventHandler DAXTXAudioStreamRemoved
event DAXMICAudioStreamAddedEventHandler DAXMICAudioStreamAdded
event TXRemoteAudioStreamAddedEventHandler TXRemoteAudioStreamAdded
event RXRemoteAudioStreamAddedEventHandler RXRemoteAudioStreamAdded
event TNFAddedEventHandler TNFAdded
event TNFRemovedEventHandler TNFRemoved
event SpotAddedEventHandler SpotAdded
event SpotRemovedEventHandler SpotRemoved
event SpotTriggeredEventHandler SpotTriggered
event SpotTriggeredWithPanEventHandler SpotTriggeredWithPan
event UsbCableAddedEventHandler UsbCableAdded
event UsbCableRemovedEventHandler UsbCableRemoved
event DisplayMarkerAddedEventHandler DisplayMarkerAdded
event TxBandSettingsAddedEventHandler TxBandSettingsAdded
event MessageReceivedEventHandler MessageReceived
event PropertyChangedEventHandler PropertyChanged
```

---

### Slice Class

Represents a receiver channel, optionally the transmit channel.

#### Identity

```csharp
int Index { get; }                   // Slice index
string Letter { get; }               // Slice letter (A-H)
string Owner { get; }                // Owning client
uint ClientHandle { get; }
Radio Radio { get; }
bool Active { get; set; }            // Active slice
Panadapter Panadapter { get; }
uint PanadapterStreamID { get; }
void Close()                         // Remove this slice
```

There is no `InUse` property.

#### Frequency control

```csharp
double Freq { get; set; }            // Frequency in MHz
int TuneStep { get; set; }           // Tuning step in Hz
int[] TuneStepList { get; }          // Valid steps, reported by the radio
bool Lock { get; set; }              // Frequency lock
bool AutoPan { get; set; }
```

#### Mode and filter

```csharp
string DemodMode { get; set; }       // Operating mode
List<string> ModeList { get; }       // Valid modes, reported by the radio
int FilterLow { get; set; }          // Low filter cutoff (Hz)
int FilterHigh { get; set; }         // High filter cutoff (Hz)
bool Wide { get; set; }
```

The property is `DemodMode`, not `Mode`. Prefer enumerating `ModeList` over
hardcoding strings; typical values are `LSB`, `USB`, `AM`, `SAM`, `CW`, `FM`,
`NFM`, `DFM`, `DIGL`, `DIGU`, `RTTY`.

#### Antenna and RF gain

```csharp
string RXAnt { get; set; }           // Current RX antenna
string[] RXAntList { get; }          // Valid RX antennas, from the radio
string TXAnt { get; set; }           // Current TX antenna
string[] TXAntList { get; }          // Valid TX antennas, from the radio
int RFGain { get; set; }             // Slice RF gain
```

Enumerate `RXAntList` / `TXAntList` rather than hardcoding; the valid set is
model and configuration dependent. Note that `Panadapter` also exposes an
`RFGain`, with the range metadata attached; see
[Panadapter Class](#panadapter-class).

#### Audio

```csharp
int AudioGain { get; set; }          // Audio gain
int AudioPan { get; set; }           // Audio pan
bool Mute { get; set; }
int DAXChannel { get; set; }         // DAX channel assignment
bool RecordOn { get; set; }
bool PlayOn { get; set; }
```

#### AGC and noise processing

```csharp
AGCMode AGCMode { get; set; }        // Enum, not a string
int AGCThreshold { get; set; }
int AGCOffLevel { get; set; }
bool ANFOn { get; set; }             int ANFLevel { get; set; }
bool APFOn { get; set; }             int APFLevel { get; set; }
bool NBOn { get; set; }              int NBLevel { get; set; }
bool WNBOn { get; set; }             int WNBLevel { get; set; }
bool NROn { get; set; }              int NRLevel { get; set; }
bool NRLOn { get; set; }             int NRL_Level { get; set; }
bool ANFLOn { get; set; }            int ANFL_Level { get; set; }
bool NRSOn { get; set; }             int NRSLevel { get; set; }
bool NRFOn { get; set; }             int NRFLevel { get; set; }
bool RNNOn { get; set; }
bool ANFTOn { get; set; }
```

#### Diversity

```csharp
bool DiversityOn { get; set; }
bool DiversityChild { get; }
int DiversityIndex { get; }
Slice DiversitySlicePartner { get; }
```

Availability is model dependent; see `ModelInfo.IsDiversityAllowed`.

#### Transmit and offsets

```csharp
bool IsTransmitSlice { get; set; }   // Designates the TX slice
bool QSK { get; set; }
bool RITOn { get; set; }             int RITFreq { get; set; }
bool XITOn { get; set; }             int XITFreq { get; set; }
int RTTYMark { get; set; }           int RTTYShift { get; set; }
int DIGLOffset { get; set; }         int DIGUOffset { get; set; }
bool LoopA { get; set; }             bool LoopB { get; set; }
bool EqCompBypass { get; set; }
```

> **PTT control**: use `radio.Mox` on the `Radio` object to key and unkey.
> `IsTransmitSlice` designates *which* slice drives the transmitter; it does
> not trigger PTT.

#### Events

```csharp
public delegate void MeterAddedEventHandler(Slice slc, Meter m);
event MeterAddedEventHandler MeterAdded
```

Per-slice meters arrive here. The slice-level signal meter is named `LEVEL`,
not `SIGNAL`; there is no meter named `SIGNAL`. Radio-wide meters do not
arrive here.

---

### Meter Class

Real-time telemetry. A `Meter` carries its own metadata and raises `DataReady`;
it does **not** expose a current-value property.

#### Properties

```csharp
int Index { get; }                   // Meter index
string Name { get; }                 // Meter name (see table below)
string Description { get; }
string Source { get; }               // SOURCE_SLICE / SOURCE_AMPLIFIER / ...
int SourceIndex { get; }
MeterUnits Units { get; }            // Enum, not a string
double Low { get; }                  // Range minimum
double High { get; }                 // Range maximum
int FPS { get; }                     // Update rate, frames per second
bool Peak { get; }
```

```csharp
public const string SOURCE_SLICE     = "SLC";
public const string SOURCE_AMPLIFIER = "AMP";
public const string SOURCE_HA_API    = "HAAPI";
```

`FPS` is the meter's own reported update rate, which is the right input when
sizing a display throttle.

#### Events

```csharp
public delegate void DataReadyEventHandler(Meter meter, float data);
event DataReadyEventHandler DataReady
```

This is the only way to read a meter value. There is no `Meter.Value`.

#### Common meter names

Names as they appear on the radio. Most callers should prefer the typed
`Radio` events in [Telemetry](#telemetry-meter-events) over matching these
strings.

| Name | Description | Units |
| --- | --- | --- |
| `FWDPWR` | Forward power | Watts |
| `REFPWR` | Reflected power | Watts |
| `SWR` | Standing wave ratio | SWR |
| `PATEMP` | PA temperature | DegreesC |
| `+13.8A` | Supply voltage, before the fuse | Volts |
| `PAEFF` | PA efficiency | |
| `HWALC` | Hardware ALC | Volts |
| `MIC` | Microphone level | Db |
| `MICPEAK` | Microphone peak | Db |
| `COMPPEAK` | Compressor peak | Db |

---

## Audio Streaming

### RXAudioStream (base class)

Base for `DAXRXAudioStream` and `DAXIQStream`. The data event lives here.

```csharp
uint StreamID { get; }
uint ClientHandle { get; }
bool RadioAck { get; }
int BytesPerSecFromRadio { get; }
int ErrorCount { get; }
int TotalCount { get; }
```

```csharp
public delegate void DataReadyEventHandler(RXAudioStream rxAudioStream,
                                           float[] rxData);
event DataReadyEventHandler DataReady
event OpusPacketReceivedEventHandler OpusPacketReceived
```

---

### DAXRXAudioStream Class

Receive audio. Created via `radio.RequestDAXRXAudioStream(channel)`; handle it
in `radio.DAXRXAudioStreamAdded`.

```csharp
int DAXChannel { get; }
Slice Slice { get; }
int RXGain { get; set; }
int Gain { get; set; }
void Close()
```

**Sample format**: 32-bit float, mono, -1.0 to 1.0.

---

### DAXTXAudioStream Class

Transmit audio. Created via `radio.RequestDAXTXAudioStream()`; handle it in
`radio.DAXTXAudioStreamAdded`.

```csharp
uint TXStreamID { get; }
uint ClientHandle { get; }
bool Transmit { get; set; }
bool RadioAck { get; }
int TXGain { get; set; }
int Gain { get; set; }
void RequestTX(bool tx)
void AddTXData(float[] tx_data_stereo, bool sendReducedBW = false)
void Close()
```

Samples passed to `AddTXData` are stereo-interleaved 32-bit float.

---

### DAXIQStream Class

IQ streaming. Created via `radio.RequestDAXIQStream(channel)`; handle it in
`radio.DAXIQStreamAdded`.

```csharp
int DAXIQChannel { get; }
Panadapter Pan { get; }
int SampleRate { get; set; }
bool IsActive { get; }
void Close()
```

Data arrives on the inherited `DataReady` event with samples interleaved
`[I, Q, I, Q, ...]`.

---

## Visual Display

### Panadapter Class

Spectrum display control.

#### Properties

```csharp
uint StreamID { get; }
uint ClientHandle { get; }
uint ChildWaterfallStreamID { get; }
double CenterFreq { get; set; }      // MHz
double Bandwidth { get; set; }       // MHz
double MinBandwidth { get; }
double MaxBandwidth { get; }
double LowDbm { get; set; }          // Display floor  (double, not int)
double HighDbm { get; set; }         // Display ceiling (double, not int)
string Band { get; set; }            // Band label
int Width { get; set; }
int Height { get; set; }
int FPS { get; set; }
int Average { get; set; }
bool AutoCenter { get; set; }
int NoiseFloorPosition { get; set; }
bool NoiseFloorPositionEnable { get; set; }
bool WNBOn { get; set; }
int WNBLevel { get; set; }
bool IsBandZoomOn { get; set; }
bool IsSegmentZoomOn { get; set; }
int DAXIQChannel { get; set; }
string RXAnt { get; set; }
string[] RXAntennaList { get; }
void Close()
```

#### RF gain

```csharp
int RFGain { get; set; }
int RFGainLow { get; }               // Radio-reported minimum
int RFGainHigh { get; }              // Radio-reported maximum
int RFGainStep { get; }              // Radio-reported step
int[] RFGainMarkers { get; }
void GetRFGainInfo()                 // Populates the four members above
```

`GetRFGainInfo()` issues `display pan rfgain_info 0x<streamID>`; the values
arrive asynchronously and raise `PropertyChanged`. Because the range is
reported by the radio, callers should never hardcode a per-model gain table.

#### Events

```csharp
public delegate void DataReadyEventHandler(Panadapter pan, ushort[] data);
event DataReadyEventHandler DataReady
```

Spectrum data arrives as `ushort[]`, not `float[]`.

---

### Waterfall Class

Waterfall display control. Created alongside a panadapter by
`Radio.RequestPanafall()`.

```csharp
uint StreamID { get; }
uint ClientHandle { get; }
uint ParentPanadapterStreamID { get; }
double CenterFreq { get; set; }
double Bandwidth { get; set; }
double LowDbm { get; set; }
double HighDbm { get; set; }
string Band { get; set; }
string RXAnt { get; set; }
int RFGain { get; set; }
int RFGainLow { get; }
int RFGainHigh { get; }
int RFGainStep { get; }
int[] RFGainMarkers { get; }
int DAXIQChannel { get; set; }
int Width { get; set; }
int Height { get; set; }
int FPS { get; set; }
int Average { get; set; }
bool AutoCenter { get; set; }
```

```csharp
public delegate void DataReadyEventHandler(Waterfall fall, WaterfallTile tile);
event DataReadyEventHandler DataReady
```

---

## Control Features

### Equalizer Class

Audio equalizer. Obtain via `radio.CreateEqualizer(EqualizerSelect)` or
`radio.FindEqualizerByEQSelect(EqualizerSelect)`.

```csharp
EqualizerSelect EQ_select { get; }
bool EQ_enabled { get; set; }
bool RadioAck { get; }
void RequestEqualizerInfo()
```

Band levels are individual properties, not a `SetLevel` call:

```csharp
int level_32Hz   { get; set; }
int level_63Hz   { get; set; }
int level_125Hz  { get; set; }
int level_250Hz  { get; set; }
int level_500Hz  { get; set; }
int level_1000Hz { get; set; }
int level_2000Hz { get; set; }
int level_4000Hz { get; set; }
int level_8000Hz { get; set; }
```

---

### TNF Class

Tracking Notch Filter.

```csharp
uint ID { get; }
double Frequency { get; set; }       // MHz
uint Depth { get; set; }             // uint, not int
double Bandwidth { get; set; }       // Not "Width"
bool Permanent { get; set; }
void Close()
void Remove()
```

---

### Memory Class

Station memories.

```csharp
int Index { get; }
string Owner { get; }
string Group { get; set; }           // string, not int
string Name { get; set; }
double Freq { get; set; }
int Step { get; set; }
double RepeaterOffset { get; set; }
FMToneMode ToneMode { get; set; }
bool SquelchOn { get; set; }
int SquelchLevel { get; set; }
int RXFilterHigh { get; set; }
int RTTYMark { get; set; }
int RTTYShift { get; set; }
int DIGLOffset { get; set; }
int DIGUOffset { get; set; }
void Select()                        // Apply this memory. Not "Apply()"
void Remove()
```

---

### Tuner Class

An **external networked antenna tuner** (for example a TGXL). This is not the
radio's built-in ATU; for that see
[Built-in antenna tuner](#built-in-antenna-tuner-atu).

```csharp
string Handle { get; }
string SerialNumber { get; }
string Version { get; }
string Nickname { get; set; }
bool OneByThree { get; }
bool Dhcp { get; set; }
IPAddress IP { get; }
IPAddress Netmask { get; }
IPAddress Gateway { get; }
string PortAAnt { get; set; }
string PortBAnt { get; set; }
TunerState State { get; }
bool IsOperate { get; }
bool IsBypass { get; }
bool IsTuning { get; }
int RelayL { get; set; }
bool PttA { get; }
```

---

### Amplifier Class

External amplifier control.

```csharp
string Handle { get; }               // string, not int
IPAddress IP { get; }
int Port { get; }
string Model { get; }
string SerialNumber { get; }
string Ant { get; set; }
AmplifierState State { get; }
bool IsOperate { get; }
```

```csharp
public delegate void MeterAddedEventHandler(Amplifier amp, Meter m);
event MeterAddedEventHandler MeterAdded
event MeterRemovedEventHandler MeterRemoved
```

---

### Xvtr Class

Transverter management. Obtain via `radio.CreateXvtr()` or
`radio.FindXvtrByIndex(int)`.

```csharp
int Index { get; }
int Order { get; set; }
string Name { get; set; }
double RFFreq { get; set; }
double IFFreq { get; set; }
double LOError { get; set; }
double RXGain { get; set; }
bool RXOnly { get; set; }
double MaxPower { get; set; }        // double, not int
bool Valid { get; }
void Remove()
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

Concrete types: `UsbCatCable` (CAT control), `UsbBcdCable` (BCD band output),
`UsbLdpaCable` (linear driver / PA control), `UsbBitCable` (digital I/O).
Related enums live in `UsbCable.cs` and `UsbCatCable.cs`: `UsbCableType`,
`BcdCableType`, `LdpaBand`, `UsbCableFreqSource`, `SerialDataBits`,
`SerialSpeed`, `SerialParity`, `SerialFlowControl`, `SerialStopBits`.

---

## Enumerations

### InterlockState

```csharp
enum InterlockState
{
    None, Receive, Ready, NotReady, PTTRequested,
    Transmitting, TXFault, Timeout, StuckInput, UnkeyRequested
}
```

### InterlockReason

```csharp
enum InterlockReason
{
    None, RCA_TXREQ, ACC_TXREQ, BAD_MODE, TUNED_TOO_FAR,
    OUT_OF_BAND, PA_RANGE, CLIENT_TX_INHIBIT, XVTR_RX_ONLY,
    NO_TX_ASSIGNED, TGXL
}
```

### PTTSource

```csharp
enum PTTSource
{
    None,
    SW,      // Software (SmartSDR, CAT, etc.)
    Mic,
    ACC,
    RCA,
    TUNE
}
```

### AGCMode

```csharp
enum AGCMode { None, Off, Slow, Medium, Fast }
```

### MeterUnits

```csharp
enum MeterUnits
{
    None, Volts, Amps, Db, Dbfs, Dbm, RPM,
    DegreesF, DegreesC, SWR, Watts, ...
}
```

### EqualizerSelect

```csharp
enum EqualizerSelect { None, TX, RX }
```

### TunerState

```csharp
enum TunerState { PowerUp, SelfCheck, Standby, Operate, Bypass, Fault, ... }
```

### AmplifierState

```csharp
enum AmplifierState
{
    PowerUp, SelfCheck, Standby, Idle, TransmitA, TransmitB, ...
}
```

Other enums of note: `RadioPlatform`, `ModemSupport` and
`ModemConfigurationType` (`ModelInfo.cs`), `FMToneMode` and
`FMTXOffsetDirection` (`Memory.cs`), `ScreensaverMode` (`Radio.cs`),
`FilterPresetModeGroup` (`Filter.cs`), `FeatureStatusReason`
(`FeatureLicense.cs`), `SsdrErrors` (`SsdrErrors.cs`).

---

## Usage Examples

### Basic connection

```csharp
API.ProgramName = "MyApp";
API.IsGUI = false;
API.Init();
await Task.Delay(2000);

var radio = API.RadioList.FirstOrDefault();
radio?.Connect();
```

### Create and tune a slice

```csharp
radio.RequestSlice();
await Task.Delay(500);

var slice = radio.SliceList.FirstOrDefault();
if (slice != null)
{
    slice.Freq = 14.200;
    slice.DemodMode = "USB";   // DemodMode, not Mode
}
```

### Monitor telemetry

Preferred: subscribe the typed `Radio` events. No meter names involved.

```csharp
radio.SWRDataReady    += swr   => Console.WriteLine($"SWR: {swr:F2}:1");
radio.ForwardPowerDataReady += fwd => Console.WriteLine($"Fwd: {fwd:F0} W");
radio.VoltsDataReady  += volts => Console.WriteLine($"Volts: {volts:F1} V");
radio.PATempDataReady += temp  => Console.WriteLine($"PA: {temp:F0} C");
```

If a meter without a typed event is needed, look it up by name after connect:

```csharp
var meter = radio.FindMeterByName("PAEFF");
if (meter != null)
    meter.DataReady += (m, value) => Console.WriteLine($"{m.Name}: {value}");
```

Note there is no `radio.MeterList` to enumerate and no `radio.MeterAdded`
event; per-object meters surface on `Slice.MeterAdded` and
`Amplifier.MeterAdded`.

### Audio streaming

```csharp
radio.DAXRXAudioStreamAdded += audioStream =>
{
    audioStream.DataReady += (stream, rx_data) =>
    {
        // rx_data: float[] mono PCM, -1.0 to 1.0
    };
};
radio.RequestDAXRXAudioStream(1);
```

### RF gain against the radio's own range

```csharp
pan.GetRFGainInfo();                       // async; wait for PropertyChanged
int next = pan.RFGain + pan.RFGainStep;
pan.RFGain = Math.Clamp(next, pan.RFGainLow, pan.RFGainHigh);
```

### PTT control

```csharp
radio.Mox = true;    // Key
// ... transmit ...
radio.Mox = false;   // Unkey
```

---

## Notes

- All events fire on background threads. Marshal to the UI thread before
  touching UI state.
- Property changes are synchronized with the radio automatically.
- Call `API.Init()` before any radio functionality and `API.CloseSession()` on
  exit.
- Check `radio.Connected` before sending commands.
- Prefer radio-reported lists (`Slice.ModeList`, `Slice.RXAntList`,
  `Slice.TuneStepList`, `Panadapter.RXAntennaList`, the `RFGain*` range
  members) over hardcoded tables. They are model and configuration dependent.
- Objects are removed with `Close()` or `Remove()` on the object itself, not
  through a method on `Radio`.

---

## Additional Resources

- **[Getting Started Guide](Getting-Started.md)** - Detailed tutorials
- **[Examples](Examples.md)** - Complete code examples
- **[Architecture](Architecture.md)** - System design details
- **[Migration Guide](Migration-Guide.md)** - Version-to-version changes

**For the complete class-by-class reference**, generate it locally from your
own copy of the FlexLib source. See
[Generating the full API reference](Generating-API-Docs.md).
