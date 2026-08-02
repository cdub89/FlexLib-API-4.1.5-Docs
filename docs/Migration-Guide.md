# Migration Guide

> **Verified against FlexLib 4.2.20.41343** (2026-08-02), with
> **4.1.5.39794** as the baseline. The 4.1.5 to 4.2.x section below was
> checked in both directions: each member was confirmed to exist in the
> 4.2.20 source, and each "new" or "changed" claim was confirmed against
> the 4.1.5 source rather than assumed. The 4.x to 4.1.5 section's "Old
> version" column predates both trees and is unverified. Some differences
> you hit when upgrading were this documentation being wrong rather than
> the API changing; see the
> [corrections table](API-Reference.md#corrections-from-the-415-edition).

This guide covers upgrading between FlexLib versions.

## Table of Contents

- [Version 4.1.5 to 4.2.x](#version-415-to-42x)
- [Version 4.x to 4.1.5](#version-4x-to-415)
- [Version 3.x to 4.x](#version-3x-to-4x)

---

## Version 4.1.5 to 4.2.x

FlexLib 4.2.x adds the NAVTEX subsystem, substantially expands HAAPI, and makes a small number of breaking API changes. Most 4.1.5 programs will compile with only one or two targeted changes.

The scope is narrower than it looks. Radio model support, the `RadioPlatform` enum, `TlsCommandCommunication`, and most of the properties an upgrading reader might expect to be new were already present in 4.1.5.39794 and need no action.

### Required firmware

The minimum compatible firmware version is **3.3.32.8203**, unchanged from 4.1.5 (`FirmwareRequiredVersion.cs:18` in both trees). Upgrading FlexLib does not by itself require a firmware update.

---

### Breaking changes

#### 1. HAAPI fault event renamed and its handler signature changed

The fault event on the `HAAPI` class was renamed, and the delegate gained a
second parameter. Renaming alone is not enough: your handler must also take
the new `noun` argument, or it will no longer bind to the event.

| 4.1.5 | 4.2.x |
|-------|--------|
| `event AmplifierFaultEventHandler AmplifierFault` | `event HaapiFaultEventHandler HaapiFault` |
| `delegate void AmplifierFaultEventHandler(string reason)` | `delegate void HaapiFaultEventHandler(string noun, string reason)` |

**Old**:

```csharp
radio.HAAPI.AmplifierFault += OnAmplifierFault;

void OnAmplifierFault(string reason)
{
    Console.WriteLine($"Fault: {reason}");
}
```

**New**:

```csharp
radio.HAAPI.HaapiFault += OnHaapiFault;

void OnHaapiFault(string noun, string reason)
{
    Console.WriteLine($"Fault [{noun}]: {reason}");
}
```

`noun` names the subsystem that reported the fault. A handler carried over
unchanged from 4.1.5 takes one parameter and will not compile against the
two-parameter delegate.

> Earlier editions of this guide said the handler signature was unchanged and
> showed a two-parameter 4.1.5 handler that never existed. If you migrated by
> renaming only, that is why your build failed.

---

#### 2. HAAPI.AmpIsSelected removed

The `AmpIsSelected` property has been removed from `HAAPI` with no direct replacement. If your code read this property, remove the reference. Use `AmpMode` to track the amplifier's operating state instead.

```csharp
// Old (no longer compiles)
if (radio.HAAPI.AmpIsSelected) { ... }

// Alternative: check operating mode
if (radio.HAAPI.AmpMode == AmplifierMode.OPERATE) { ... }
```

---

### Deprecated APIs

These properties still compile but emit `[Obsolete]` warnings. They were
already marked obsolete in 4.1.5 (`Radio.cs:897` and `Radio.cs:912` in that
tree), so this is not a 4.2.x change. It is listed here because it is worth
clearing while you are already touching the code, before a future version
removes them.

| Deprecated | Replacement |
|-----------|-------------|
| `Radio.InUseIP` | `Radio.GuiClientIPs` |
| `Radio.InUseHost` | `Radio.GuiClientHosts` |

```csharp
// Deprecated (still works, but warns)
string ip = radio.InUseIP;
string host = radio.InUseHost;

// Correct
string ip = radio.GuiClientIPs;
string host = radio.GuiClientHosts;
```

---

### New features

#### 1. NAVTEX waveform support

NAVTEX (Narrow-band direct-printing) is now fully supported for FLEX-9x00 series radios. Access it via `radio.NAVTEX`.

```csharp
// Toggle NAVTEX mode on/off
radio.NAVTEX.TryToggleNAVTEX();

// Or specify the broadcast frequency (default is international 518 kHz)
radio.NAVTEX.TryToggleNAVTEX(NAVTEX.LOCAL_BROADCAST_FREQ_HZ); // 490 kHz

// Monitor status
radio.NAVTEX.PropertyChanged += (s, e) =>
{
    if (e.PropertyName == nameof(NAVTEX.Status))
        Console.WriteLine($"NAVTEX status: {radio.NAVTEX.Status}");
};

// Send a NAVTEX message
var msg = new NAVTEXMsg(
    dateTime: null,
    idx: null,
    serial: null,
    txIdent: 'A',
    subjInd: 'B',
    msgStr: "NAVTEX TEST MESSAGE",
    status: NAVTEXMsgStatus.Pending
);
radio.NAVTEX.Send(msg);
```

**NAVTEXStatus values**: `Inactive`, `Active`, `Transmitting`, `QueueFull`, `Unlicensed`, `Error`

**NAVTEXMsgStatus values**: `Pending`, `Queued`, `Sent`, `Error`

**Broadcast frequency constants**:

```csharp
NAVTEX.INTERNATIONAL_BROADCAST_FREQ_HZ           // 518,000 Hz
NAVTEX.LOCAL_BROADCAST_FREQ_HZ                   // 490,000 Hz
NAVTEX.MARINE_SAFETY_INFORMATION_BROADCAST_FREQ_HZ // 4,209,500 Hz
```

---

#### 2. HAAPI warning events and mode control

In addition to the renamed fault event, `HAAPI` now exposes warning events and an explicit mode-change method.

**New events**:

```csharp
// Warning raised (state becomes WARNING)
radio.HAAPI.HaapiWarning += (noun, reason) =>
{
    Console.WriteLine($"Warning [{noun}]: {reason}");
};

// Warning cleared (state returns to OK)
radio.HAAPI.HaapiWarningCleared += (noun) =>
{
    Console.WriteLine($"Warning cleared: {noun}");
};
```

**New method, change amplifier mode**:

```csharp
// Request mode change (result confirmed via AmpMode PropertyChanged)
radio.HAAPI.HaapiChangeMode(AmplifierMode.OPERATE);
radio.HAAPI.HaapiChangeMode(AmplifierMode.STANDBY);
```

**New metering events** (subscribe to live data from the Overlord PA):

```csharp
radio.HAAPI.HaapiFwdPwrDataReady  += (data) => { /* forward power, watts */ };
radio.HAAPI.HaapiVswrDataReady    += (data) => { /* SWR */ };
radio.HAAPI.HaapiHVDataReady      += (data) => { /* HV supply voltage */ };
radio.HAAPI.HaapiCurrentDataReady += (data) => { /* HV supply current */ };
radio.HAAPI.HaapiTempPsuDataReady += (data) => { /* PSU temperature */ };
radio.HAAPI.HaapiTempPa0DataReady += (data) => { /* PA module 0 temperature */ };
radio.HAAPI.HaapiTempPa1DataReady += (data) => { /* PA module 1 temperature */ };
radio.HAAPI.HaapiTempDrvADataReady+= (data) => { /* Driver A temperature */ };
radio.HAAPI.HaapiTempDrvBDataReady+= (data) => { /* Driver B temperature */ };
radio.HAAPI.HaapiTempCombDataReady+= (data) => { /* Combiner temperature */ };
radio.HAAPI.HaapiTempHpfDataReady += (data) => { /* HPF load temperature */ };
```

All eleven use the same delegate, `HAAPI.MeterDataReadyEventHandler(float data)`.

---

#### 3. New Radio properties

| Property | Type | Description |
|----------|------|-------------|
| `IsSystemModel` | `bool` | Read/write; identifies system and government model variants |
| `TurfRegion` | `string` | Read/write; turf and region string from the radio |

Both are new in 4.2.x (`Radio.cs:683` and `Radio.cs:698`). Nothing else on
`Radio` needs attention when upgrading.

---

### Dependency changes

The package references in `FlexLib.csproj` moved:

| Package | 4.1.5 | 4.2.20 |
|---------|-------|--------|
| AsyncAwaitBestPractices | 9.0.0 | 10.0.0 |
| System.Threading.Tasks.Dataflow | not referenced | 10.0.1 |

`DotNetZip` (1.16.0), `Newtonsoft.Json` (13.0.3), and
`System.Collections.Immutable` (9.0.0) are unchanged. If you reference
FlexLib as a project rather than a package, restore after upgrading so the
new Dataflow reference resolves.

---

### DAX audio API changes

The DAX internals were significantly rewritten in 4.2.x. The public surface is mostly backward-compatible, but there are behavioral changes and one new method that multiFLEX applications must adopt.

#### DAXTXAudioStream: RequestTX for multiFLEX ownership

A new `RequestTX(bool tx)` method lets a client explicitly claim or yield DAX TX ownership when another client currently holds it. This is required in multiFLEX scenarios. In 4.1.5, there was no programmatic way to take back TX; you had to rely on the radio's automatic arbitration.

```csharp
// Request TX ownership (e.g. your client wants to transmit)
txStream.RequestTX(true);

// Yield TX ownership (e.g. allow another client to transmit)
txStream.RequestTX(false);

// Watch Transmit property to see if the radio granted ownership
txStream.PropertyChanged += (s, e) =>
{
    if (e.PropertyName == "Transmit")
        Console.WriteLine($"TX state: {txStream.Transmit}");
};
```

The `Transmit` property still reflects the radio's actual grant; setting `RequestTX` does not immediately set `Transmit`.

---

#### DAXTXAudioStream: AddTXData performance rewrite

The `AddTXData(float[] tx_data_stereo, bool sendReducedBW = false)` signature is unchanged, but the implementation was completely rewritten with pre-allocated packet buffers. There are no per-call heap allocations in 4.2.x.

**Action required**: none, no code changes needed. Applications that call `AddTXData` at high rates will see lower GC pressure and reduced latency jitter.

Packet size is still fixed at 128 stereo float pairs (256 floats total). Passing a buffer of any other length will be ignored with a debug warning, same as before.

---

#### DAXMICAudioStream: gain curve unchanged

`RXGain` takes 0 to 100 and maps it linearly onto -10 dB to +10 dB, so 50 is
exactly unity gain. This is identical in both versions (the mapping in
`DAXMICAudioStream.cs` is unchanged between the two trees). No re-tuning is
needed.

---

#### DAXRXAudioStream: slice binding race condition fixed

In 4.1.5, the `Slice` property could be resolved before the client handle was
known, causing the lookup to fail and leaving `Slice` null. In 4.2.x, slice
resolution is deferred until every status key in an update has been parsed,
and the stream's gain is re-applied once the slice reference is established.

**Action required**: none, this is a bug fix. Code that worked around a null
`Slice` by polling or subscribing to `PropertyChanged` continues to work, and
will now also see `Slice` set correctly on the first status update.

---

#### Stream request API: unchanged

The stream creation and teardown methods on `Radio` are unchanged:

```csharp
// Create streams (same as 4.1.5)
radio.RequestDAXRXAudioStream(int channel);
radio.RequestDAXTXAudioStream();
radio.RequestDAXMICAudioStream();
radio.RequestDAXIQStream(int channel);
radio.RequestRXRemoteAudioStream();
radio.RequestRXRemoteAudioStream(bool isCompressed);
radio.RequestRemoteAudioTXStream();

// Remove streams (same as 4.1.5)
radio.RemoveAudioStream(uint stream_id);
radio.RemoveDAXTXAudioStream(uint stream_id);
radio.RemoveDAXMICAudioStream(uint stream_id);
radio.RemoveDAXIQStream(uint stream_id);
radio.RemoveRXRemoteAudioStream(uint stream_id);
radio.RemoveTXRemoteAudioStream(uint stream_id);

// Events (same as 4.1.5)
radio.DAXRXAudioStreamAdded   += ...;
radio.DAXRXAudioStreamRemoved += ...;
radio.DAXTXAudioStreamAdded   += ...;
radio.DAXTXAudioStreamRemoved += ...;
radio.DAXMICAudioStreamAdded  += ...;
radio.DAXMICAudioStreamRemoved+= ...;
radio.DAXIQStreamAdded        += ...;
radio.DAXIQStreamRemoved      += ...;
```

---

### Migration checklist (4.1.5 to 4.2.x)

- [ ] Rename `HAAPI.AmplifierFault` subscriptions to `HAAPI.HaapiFault`
- [ ] Add the `string noun` parameter to every fault handler, and rename
  `AmplifierFaultEventHandler` to `HaapiFaultEventHandler`
- [ ] Remove any references to `HAAPI.AmpIsSelected`
- [ ] Restore packages so the new `System.Threading.Tasks.Dataflow` reference resolves
- [ ] Optional: replace the already-obsolete `Radio.InUseIP` and `Radio.InUseHost`
  with `Radio.GuiClientIPs` and `Radio.GuiClientHosts`
- [ ] **DAX**: Add `RequestTX(bool tx)` calls where multiFLEX TX ownership handoff is needed
- [ ] **DAX**: Remove any workarounds for null `DAXRXAudioStream.Slice` on first status update

---

## Version 4.x to 4.1.5

### Summary

Primarily a maintenance release: .NET 8.0 multi-targeting, dependency updates, no breaking API changes.

### Target Framework Changes

**Previous**:

- .NET Framework 4.6.2

**Current**:

- .NET Framework 4.6.2
- .NET 8.0 (new)

### Multi-Targeting Support

```xml
<!-- Recommended: target .NET 8.0 -->
<PropertyGroup>
  <TargetFramework>net8.0-windows</TargetFramework>
</PropertyGroup>

<!-- Or continue using .NET Framework 4.6.2 -->
<PropertyGroup>
  <TargetFramework>net462</TargetFramework>
</PropertyGroup>
```

### Dependency Updates

| Package | Old Version | New Version |
|---------|-------------|-------------|
| AsyncAwaitBestPractices | 7.x | 9.0.0 |
| System.Collections.Immutable | 6.x | 9.0.0 |
| Newtonsoft.Json | 13.0.1 | 13.0.3 |

```bash
dotnet add package AsyncAwaitBestPractices --version 9.0.0
dotnet add package System.Collections.Immutable --version 9.0.0
```

---

## Version 3.x to 4.x

FlexLib 3.x predates every source tree available for verification, so the
old-name columns below are historical record rather than checked fact. The
replacement columns were confirmed against 4.2.20.41343. The 4.x namespace is
`Flex.Smoothlake.FlexLib`.

If you are still on 3.x, work from [Getting Started](Getting-Started.md)
rather than trying to patch a 3.x program forward. The API was restructured
around discovery events and `Request*` calls, and a rewrite is less work than
a translation.

### Renamed properties

| Old (v3.x) | New (v4.x) |
|-----------|-----------|
| `Radio.IsConnected` | `Radio.Connected` |
| `Slice.Frequency` | `Slice.Freq` |
| `Slice.RxAntenna` | `Slice.RXAnt` |
| `Slice.TxAntenna` | `Slice.TXAnt` |

### Removed APIs

| Removed | Use instead |
|---------|------------|
| `Radio.CreateSlice()` | `radio.RequestSlice()` |
| `Discovery.Start()` | `API.Init()` |
| `Discovery.Stop()` | `API.CloseSession()` |

---

## Common Migration Issues

### "Type or namespace 'FlexLib' could not be found"

Update using statements: `using Flex.Smoothlake.FlexLib;`

### Radio connection fails immediately

Remove the IP address argument: `radio.Connect();`

### Slice is null after creation

Subscribe to `radio.SliceAdded` before calling `radio.RequestSlice()`.

### Events not firing

Subscribe to events **before** calling `API.Init()` so you do not miss radios discovered immediately on startup.

### UI freezing with events

Events fire on background threads. Dispatch UI updates:

```csharp
radio.PropertyChanged += (s, e) =>
    Dispatcher.Invoke(() => { /* update UI */ });
```

---

## Version History

| Version | Notable changes |
|---------|----------------|
| 4.2.x | NAVTEX support, HAAPI warning and metering events, `HaapiChangeMode`, DAX TX ownership via `RequestTX` |
| 4.1.5 | .NET 8.0 multi-targeting, dependency updates |
| 4.1.0 | Bug fixes, performance improvements |
| 4.0.0 | Major refactor, new API design |
| 3.x | Original FlexLib implementation |

---

**Questions?** See [Getting Started](Getting-Started.md) or contact <support@flexradio.com>.
