# FlexLib Code Examples

This page provides practical, real-world examples for common FlexLib 4.1.5 programming tasks.

## Table of Contents

- [Basic Examples](#basic-examples)
  - [Simple Radio Controller](#simple-radio-controller)
  - [Frequency Scanner](#frequency-scanner)
  - [Multi-Radio Manager](#multi-radio-manager)
- [Advanced Examples](#advanced-examples)
  - [Audio Streaming](#audio-streaming)
  - [Panadapter Display](#panadapter-display)
  - [Digital Mode Interface](#digital-mode-interface)
  - [Remote Station Controller](#remote-station-controller)
- [Utility Examples](#utility-examples)
  - [Radio Monitor](#radio-monitor)
  - [Band Hopper](#band-hopper)
  - [Memory Manager](#memory-manager)
  - [Amplifier Controller](#amplifier-controller)

---

## Basic Examples

### Simple Radio Controller

A minimal console application that connects to a radio and allows frequency control.

```csharp
using Flex.Smoothlake.FlexLib;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace SimpleRadioController
{
    class Program
    {
        private static Radio? _radio;
        private static Slice? _slice;

        static async Task Main(string[] args)
        {
            Console.WriteLine("=== Simple FlexRadio Controller ===\n");

            // Initialize API
            API.ProgramName = "SimpleController";
            API.IsGUI = false;
            
            API.RadioAdded += OnRadioAdded;
            API.Init();

            Console.WriteLine("Searching for radios...");
            await Task.Delay(3000);

            // Connect to first radio
            _radio = API.RadioList.FirstOrDefault();
            if (_radio == null)
            {
                Console.WriteLine("No radios found!");
                return;
            }

            await ConnectAndSetup();
            await CommandLoop();
        }

        static async Task ConnectAndSetup()
        {
            Console.WriteLine($"\nConnecting to {_radio!.Nickname}...");
            _radio.Connect();

            // Wait for connection
            for (int i = 0; i < 50 && !_radio.Connected; i++)
                await Task.Delay(100);

            if (!_radio.Connected)
            {
                Console.WriteLine("Connection failed!");
                return;
            }

            Console.WriteLine("✓ Connected");

            // Create a slice
            _radio.RequestSliceFromRadio();
            await Task.Delay(500);

            _slice = _radio.SliceList.FirstOrDefault();
            if (_slice != null)
            {
                Console.WriteLine($"✓ Slice created: {_slice.Freq:F3} MHz, {_slice.Mode}");
            }
        }

        static async Task CommandLoop()
        {
            Console.WriteLine("\nCommands:");
            Console.WriteLine("  f <freq>  - Set frequency in MHz (e.g., f 14.200)");
            Console.WriteLine("  m <mode>  - Set mode (USB, LSB, CW, etc.)");
            Console.WriteLine("  i         - Show info");
            Console.WriteLine("  q         - Quit");

            while (true)
            {
                Console.Write("\n> ");
                string? input = Console.ReadLine();
                if (string.IsNullOrWhiteSpace(input)) continue;

                string[] parts = input.Split(' ', StringSplitOptions.RemoveEmptyEntries);
                if (parts.Length == 0) continue;

                string command = parts[0].ToLower();

                switch (command)
                {
                    case "f":
                        if (parts.Length > 1 && double.TryParse(parts[1], out double freq))
                        {
                            _slice!.Freq = freq;
                            Console.WriteLine($"Tuned to {freq:F3} MHz");
                        }
                        break;

                    case "m":
                        if (parts.Length > 1)
                        {
                            _slice!.Mode = parts[1].ToUpper();
                            Console.WriteLine($"Mode set to {parts[1].ToUpper()}");
                        }
                        break;

                    case "i":
                        ShowInfo();
                        break;

                    case "q":
                        Cleanup();
                        return;
                }
            }
        }

        static void ShowInfo()
        {
            Console.WriteLine($"\n--- Radio Info ---");
            Console.WriteLine($"Model: {_radio!.Model}");
            Console.WriteLine($"Serial: {_radio.Serial}");
            Console.WriteLine($"Version: {_radio.Version}");
            Console.WriteLine($"IP: {_radio.IP}");
            
            if (_slice != null)
            {
                Console.WriteLine($"\n--- Slice Info ---");
                Console.WriteLine($"Frequency: {_slice.Freq:F6} MHz");
                Console.WriteLine($"Mode: {_slice.Mode}");
                Console.WriteLine($"Filter: {_slice.FilterLow}-{_slice.FilterHigh} Hz");
                Console.WriteLine($"RX Ant: {_slice.RXAnt}");
            }
        }

        static void OnRadioAdded(Radio radio)
        {
            Console.WriteLine($"Found: {radio.Nickname} ({radio.Model})");
        }

        static void Cleanup()
        {
            Console.WriteLine("\nDisconnecting...");
            _radio?.Disconnect();
            API.CloseSession();
        }
    }
}
```

---

### Frequency Scanner

Scans a frequency range and reports signal levels.

```csharp
using Flex.Smoothlake.FlexLib;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace FrequencyScanner
{
    public class Scanner
    {
        private Radio? _radio;
        private Slice? _slice;
        private Meter? _signalMeter;
        private double _currentSignalLevel;

        public async Task<List<ScanResult>> ScanRange(
            double startMHz,
            double endMHz,
            double stepKHz,
            string mode = "USB")
        {
            var results = new List<ScanResult>();

            // Initialize
            if (!await Initialize())
                return results;

            // Setup signal meter monitoring
            SetupMeterMonitoring();

            // Configure slice
            _slice!.Mode = mode;
            _slice.FilterLow = 200;
            _slice.FilterHigh = 2800;

            Console.WriteLine($"\nScanning {startMHz:F3} - {endMHz:F3} MHz");
            Console.WriteLine($"Step: {stepKHz} kHz, Mode: {mode}\n");

            double freq = startMHz;
            int stepCount = 0;

            while (freq <= endMHz)
            {
                // Tune to frequency
                _slice.Freq = freq;
                
                // Wait for signal measurement
                await Task.Delay(200);

                // Record result
                var result = new ScanResult
                {
                    Frequency = freq,
                    SignalLevel = _currentSignalLevel,
                    Mode = mode,
                    Timestamp = DateTime.UtcNow
                };
                results.Add(result);

                // Display progress
                stepCount++;
                if (stepCount % 10 == 0)
                {
                    Console.WriteLine($"Scanned: {freq:F3} MHz - Signal: {_currentSignalLevel:F1} dB");
                }

                // Move to next frequency
                freq += (stepKHz / 1000.0);
            }

            Console.WriteLine($"\nScan complete. {results.Count} frequencies scanned.");

            // Show top signals
            var topSignals = results
                .OrderByDescending(r => r.SignalLevel)
                .Take(10)
                .ToList();

            Console.WriteLine("\nTop 10 Signals:");
            foreach (var signal in topSignals)
            {
                Console.WriteLine($"  {signal.Frequency:F3} MHz: {signal.SignalLevel:F1} dB");
            }

            Cleanup();
            return results;
        }

        private async Task<bool> Initialize()
        {
            API.ProgramName = "FrequencyScanner";
            API.IsGUI = false;
            API.Init();

            await Task.Delay(2000);

            _radio = API.RadioList.FirstOrDefault();
            if (_radio == null)
            {
                Console.WriteLine("No radio found!");
                return false;
            }

            _radio.Connect();
            for (int i = 0; i < 50 && !_radio.Connected; i++)
                await Task.Delay(100);

            if (!_radio.Connected)
            {
                Console.WriteLine("Connection failed!");
                return false;
            }

            _radio.RequestSliceFromRadio();
            await Task.Delay(500);

            _slice = _radio.SliceList.FirstOrDefault();
            if (_slice == null)
            {
                Console.WriteLine("Failed to create slice!");
                return false;
            }

            return true;
        }

        private void SetupMeterMonitoring()
        {
            _radio!.MeterAdded += (meter) =>
            {
                if (meter.Name == "SIGNAL" || meter.Name.Contains("SIGNAL"))
                {
                    _signalMeter = meter;
                    meter.DataReady += (data) =>
                    {
                        _currentSignalLevel = data.Value;
                    };
                }
            };
        }

        private void Cleanup()
        {
            _radio?.Disconnect();
            API.CloseSession();
        }
    }

    public class ScanResult
    {
        public double Frequency { get; set; }
        public double SignalLevel { get; set; }
        public string Mode { get; set; } = "";
        public DateTime Timestamp { get; set; }
    }

    class Program
    {
        static async Task Main(string[] args)
        {
            var scanner = new Scanner();
            
            // Scan 20m band
            var results = await scanner.ScanRange(
                startMHz: 14.000,
                endMHz: 14.350,
                stepKHz: 5,
                mode: "USB"
            );

            // Export results
            ExportToCSV(results, "scan_results.csv");
        }

        static void ExportToCSV(List<ScanResult> results, string filename)
        {
            using var writer = new System.IO.StreamWriter(filename);
            writer.WriteLine("Frequency_MHz,Signal_dB,Mode,Timestamp");
            
            foreach (var result in results)
            {
                writer.WriteLine($"{result.Frequency:F6},{result.SignalLevel:F2},{result.Mode},{result.Timestamp:O}");
            }
            
            Console.WriteLine($"\nResults exported to {filename}");
        }
    }
}
```

---

### Multi-Radio Manager

Manages multiple radios simultaneously.

```csharp
using Flex.Smoothlake.FlexLib;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace MultiRadioManager
{
    public class RadioManager
    {
        private Dictionary<string, Radio> _radios = new();
        private Dictionary<string, bool> _radioStatus = new();

        public async Task Initialize()
        {
            Console.WriteLine("=== Multi-Radio Manager ===\n");

            API.ProgramName = "MultiRadioManager";
            API.IsGUI = false;

            API.RadioAdded += OnRadioAdded;
            API.RadioRemoved += OnRadioRemoved;

            API.Init();

            Console.WriteLine("Discovering radios...");
            await Task.Delay(5000);

            Console.WriteLine($"\nFound {API.RadioList.Count} radio(s)");
            ListRadios();
        }

        private void OnRadioAdded(Radio radio)
        {
            Console.WriteLine($"✓ Discovered: {radio.Nickname} ({radio.Serial})");
            _radios[radio.Serial] = radio;
            _radioStatus[radio.Serial] = false;

            // Monitor radio connection status
            radio.PropertyChanged += (sender, e) =>
            {
                if (e.PropertyName == "Connected")
                {
                    var r = sender as Radio;
                    _radioStatus[r!.Serial] = r.Connected;
                    Console.WriteLine($"  {r.Nickname}: {(r.Connected ? "CONNECTED" : "DISCONNECTED")}");
                }
            };
        }

        private void OnRadioRemoved(Radio radio)
        {
            Console.WriteLine($"✗ Lost: {radio.Nickname}");
            _radios.Remove(radio.Serial);
            _radioStatus.Remove(radio.Serial);
        }

        public void ConnectAll()
        {
            Console.WriteLine("\nConnecting to all radios...");
            
            foreach (var radio in _radios.Values)
            {
                if (!radio.Connected)
                {
                    Console.WriteLine($"  Connecting to {radio.Nickname}...");
                    radio.Connect();
                }
            }
        }

        public void DisconnectAll()
        {
            Console.WriteLine("\nDisconnecting from all radios...");
            
            foreach (var radio in _radios.Values)
            {
                if (radio.Connected)
                {
                    Console.WriteLine($"  Disconnecting from {radio.Nickname}...");
                    radio.Disconnect();
                }
            }
        }

        public void ListRadios()
        {
            Console.WriteLine("\n--- Available Radios ---");
            
            foreach (var radio in _radios.Values)
            {
                string status = _radioStatus[radio.Serial] ? "CONNECTED" : "AVAILABLE";
                Console.WriteLine($"  [{status}] {radio.Nickname}");
                Console.WriteLine($"    Model: {radio.Model}");
                Console.WriteLine($"    Serial: {radio.Serial}");
                Console.WriteLine($"    IP: {radio.IP}");
                Console.WriteLine($"    Version: {radio.Version}");
                Console.WriteLine();
            }
        }

        public Radio? GetRadioByName(string nickname)
        {
            return _radios.Values.FirstOrDefault(r => 
                r.Nickname.Equals(nickname, StringComparison.OrdinalIgnoreCase));
        }

        public void SetAllRadiosToFrequency(double freqMHz, string mode)
        {
            Console.WriteLine($"\nTuning all radios to {freqMHz:F3} MHz, {mode}");
            
            foreach (var radio in _radios.Values.Where(r => r.Connected))
            {
                var slice = radio.SliceList.FirstOrDefault();
                if (slice == null)
                {
                    radio.RequestSliceFromRadio();
                    Task.Delay(500).Wait();
                    slice = radio.SliceList.FirstOrDefault();
                }

                if (slice != null)
                {
                    slice.Freq = freqMHz;
                    slice.Mode = mode;
                    Console.WriteLine($"  {radio.Nickname}: Tuned");
                }
            }
        }

        public void ShowAllStatus()
        {
            Console.WriteLine("\n=== Radio Status ===");
            
            foreach (var radio in _radios.Values)
            {
                Console.WriteLine($"\n{radio.Nickname} ({radio.Serial}):");
                Console.WriteLine($"  Connected: {radio.Connected}");
                
                if (radio.Connected)
                {
                    Console.WriteLine($"  Slices: {radio.SliceList.Count}");
                    Console.WriteLine($"  Panadapters: {radio.PanadapterList.Count}");
                    
                    foreach (var slice in radio.SliceList)
                    {
                        Console.WriteLine($"    Slice {slice.Index}: {slice.Freq:F3} MHz, {slice.Mode}");
                    }
                }
            }
        }

        public void Cleanup()
        {
            Console.WriteLine("\nCleaning up...");
            DisconnectAll();
            API.CloseSession();
        }
    }

    class Program
    {
        static async Task Main(string[] args)
        {
            var manager = new RadioManager();
            await manager.Initialize();

            // Interactive command loop
            await CommandLoop(manager);
        }

        static async Task CommandLoop(RadioManager manager)
        {
            Console.WriteLine("\nCommands:");
            Console.WriteLine("  connect          - Connect to all radios");
            Console.WriteLine("  disconnect       - Disconnect from all radios");
            Console.WriteLine("  list             - List all radios");
            Console.WriteLine("  status           - Show status of all radios");
            Console.WriteLine("  tune <freq> <mode> - Tune all radios");
            Console.WriteLine("  quit             - Exit");

            while (true)
            {
                Console.Write("\n> ");
                string? input = Console.ReadLine();
                if (string.IsNullOrWhiteSpace(input)) continue;

                string[] parts = input.Split(' ', StringSplitOptions.RemoveEmptyEntries);
                string command = parts[0].ToLower();

                switch (command)
                {
                    case "connect":
                        manager.ConnectAll();
                        await Task.Delay(2000);
                        break;

                    case "disconnect":
                        manager.DisconnectAll();
                        break;

                    case "list":
                        manager.ListRadios();
                        break;

                    case "status":
                        manager.ShowAllStatus();
                        break;

                    case "tune":
                        if (parts.Length >= 3 && double.TryParse(parts[1], out double freq))
                        {
                            manager.SetAllRadiosToFrequency(freq, parts[2].ToUpper());
                        }
                        break;

                    case "quit":
                    case "exit":
                        manager.Cleanup();
                        return;
                }
            }
        }
    }
}
```

---

## Advanced Examples

### Audio Streaming

Capture and process audio from a FlexRadio.

```csharp
using Flex.Smoothlake.FlexLib;
using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace AudioStreamExample
{
    public class AudioRecorder
    {
        private Radio? _radio;
        private Slice? _slice;
        private DAXRXAudioStream? _audioStream;
        private FileStream? _waveFile;
        private BinaryWriter? _waveWriter;
        private long _sampleCount = 0;

        public async Task<bool> Initialize()
        {
            API.ProgramName = "AudioRecorder";
            API.IsGUI = false;
            API.Init();

            await Task.Delay(2000);

            _radio = API.RadioList.FirstOrDefault();
            if (_radio == null) return false;

            _radio.Connect();
            for (int i = 0; i < 50 && !_radio.Connected; i++)
                await Task.Delay(100);

            if (!_radio.Connected) return false;

            _radio.RequestSliceFromRadio();
            await Task.Delay(500);

            _slice = _radio.SliceList.FirstOrDefault();
            if (_slice == null) return false;

            return true;
        }

        public void StartRecording(string filename, int daxChannel = 1)
        {
            Console.WriteLine($"Starting recording to {filename}...");

            // Create DAX audio stream
            _audioStream = _radio!.CreateDAXRXAudioStream(daxChannel);
            
            if (_audioStream == null)
            {
                Console.WriteLine("Failed to create audio stream!");
                return;
            }

            // Setup wave file
            _waveFile = new FileStream(filename, FileMode.Create);
            _waveWriter = new BinaryWriter(_waveFile);
            WriteWaveHeader(_waveWriter, _audioStream.SampleRate);

            // Subscribe to audio data
            _audioStream.DataReady += OnAudioData;

            // Start streaming
            _audioStream.Start();

            Console.WriteLine($"✓ Recording at {_audioStream.SampleRate} Hz");
        }

        private void OnAudioData(float[] audioData)
        {
            if (_waveWriter == null) return;

            // Convert float samples to 16-bit PCM
            foreach (float sample in audioData)
            {
                short pcmSample = (short)(sample * 32767f);
                _waveWriter.Write(pcmSample);
                _sampleCount++;
            }

            // Progress indicator
            if (_sampleCount % 48000 == 0) // Every second
            {
                Console.Write(".");
            }
        }

        public void StopRecording()
        {
            Console.WriteLine("\nStopping recording...");

            _audioStream?.Stop();

            if (_waveWriter != null && _waveFile != null)
            {
                // Update wave file header with actual size
                UpdateWaveHeader(_waveWriter, _sampleCount);
                _waveWriter.Close();
                _waveFile.Close();
            }

            Console.WriteLine($"✓ Recorded {_sampleCount} samples");
            
            _radio?.Disconnect();
            API.CloseSession();
        }

        private void WriteWaveHeader(BinaryWriter writer, int sampleRate)
        {
            // RIFF header
            writer.Write(new char[] { 'R', 'I', 'F', 'F' });
            writer.Write(0); // File size (to be updated later)
            writer.Write(new char[] { 'W', 'A', 'V', 'E' });

            // fmt chunk
            writer.Write(new char[] { 'f', 'm', 't', ' ' });
            writer.Write(16); // fmt chunk size
            writer.Write((short)1); // PCM format
            writer.Write((short)1); // Mono
            writer.Write(sampleRate); // Sample rate
            writer.Write(sampleRate * 2); // Byte rate
            writer.Write((short)2); // Block align
            writer.Write((short)16); // Bits per sample

            // data chunk
            writer.Write(new char[] { 'd', 'a', 't', 'a' });
            writer.Write(0); // Data size (to be updated later)
        }

        private void UpdateWaveHeader(BinaryWriter writer, long sampleCount)
        {
            long dataSize = sampleCount * 2; // 2 bytes per sample
            long fileSize = dataSize + 36;

            writer.Seek(4, SeekOrigin.Begin);
            writer.Write((int)fileSize);

            writer.Seek(40, SeekOrigin.Begin);
            writer.Write((int)dataSize);
        }
    }

    class Program
    {
        static async Task Main(string[] args)
        {
            var recorder = new AudioRecorder();

            if (!await recorder.Initialize())
            {
                Console.WriteLine("Initialization failed!");
                return;
            }

            // Start recording
            recorder.StartRecording("recording.wav");

            // Record for 30 seconds
            Console.WriteLine("\nRecording for 30 seconds...");
            await Task.Delay(30000);

            // Stop recording
            recorder.StopRecording();

            Console.WriteLine("\nDone! Check recording.wav");
        }
    }
}
```

---

### Panadapter Display

Monitor panadapter data for spectrum display.

```csharp
using Flex.Smoothlake.FlexLib;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace PanadapterExample
{
    public class PanadapterMonitor
    {
        private Radio? _radio;
        private Panadapter? _panadapter;
        private int _updateCount = 0;

        public async Task<bool> Initialize()
        {
            API.ProgramName = "PanadapterMonitor";
            API.IsGUI = false;
            API.Init();

            await Task.Delay(2000);

            _radio = API.RadioList.FirstOrDefault();
            if (_radio == null) return false;

            // Subscribe to panadapter events
            _radio.PanadapterAdded += OnPanadapterAdded;

            _radio.Connect();
            for (int i = 0; i < 50 && !_radio.Connected; i++)
                await Task.Delay(100);

            if (!_radio.Connected) return false;

            // Request a panadapter
            _radio.RequestPanadapter();
            await Task.Delay(500);

            _panadapter = _radio.PanadapterList.FirstOrDefault();
            if (_panadapter == null)
            {
                Console.WriteLine("Failed to create panadapter!");
                return false;
            }

            return true;
        }

        private void OnPanadapterAdded(Panadapter pan, Waterfall fall)
        {
            Console.WriteLine($"\nPanadapter created:");
            Console.WriteLine($"  StreamID: {pan.StreamID}");
            Console.WriteLine($"  Center Frequency: {pan.CenterFreq:F3} MHz");
            Console.WriteLine($"  Bandwidth: {pan.Bandwidth:F3} MHz");
            Console.WriteLine($"  MinDBM: {pan.MinDBM}, MaxDBM: {pan.MaxDBM}");

            // Subscribe to panadapter data
            pan.DataReady += OnPanadapterData;
        }

        private void OnPanadapterData(float[] data)
        {
            _updateCount++;

            // Display update rate
            if (_updateCount % 10 == 0)
            {
                Console.WriteLine($"Panadapter updates: {_updateCount}");
                DisplaySpectrum(data);
            }
        }

        private void DisplaySpectrum(float[] data)
        {
            if (data.Length == 0) return;

            // Find peak
            float max = data.Max();
            int maxIndex = Array.IndexOf(data, max);

            // Calculate frequency of peak
            double freqStep = _panadapter!.Bandwidth / data.Length;
            double startFreq = _panadapter.CenterFreq - (_panadapter.Bandwidth / 2.0);
            double peakFreq = startFreq + (maxIndex * freqStep);

            Console.WriteLine($"  Peak: {max:F1} dBm at {peakFreq:F6} MHz");

            // Simple ASCII spectrum display (every 10th point)
            Console.Write("  ");
            for (int i = 0; i < data.Length; i += data.Length / 50)
            {
                int height = (int)((data[i] - _panadapter.MinDBM) / 
                                   (_panadapter.MaxDBM - _panadapter.MinDBM) * 8);
                height = Math.Max(0, Math.Min(8, height));
                
                Console.Write("▁▂▃▄▅▆▇█"[height]);
            }
            Console.WriteLine();
        }

        public void ConfigurePanadapter(double centerMHz, double bandwidthMHz)
        {
            if (_panadapter == null) return;

            Console.WriteLine($"\nConfiguring panadapter:");
            Console.WriteLine($"  Center: {centerMHz:F3} MHz");
            Console.WriteLine($"  Bandwidth: {bandwidthMHz:F3} MHz");

            _panadapter.CenterFreq = centerMHz;
            _panadapter.Bandwidth = bandwidthMHz;
        }

        public void Cleanup()
        {
            _radio?.Disconnect();
            API.CloseSession();
        }
    }

    class Program
    {
        static async Task Main(string[] args)
        {
            var monitor = new PanadapterMonitor();

            if (!await monitor.Initialize())
            {
                Console.WriteLine("Initialization failed!");
                return;
            }

            // Configure for 20m band
            monitor.ConfigurePanadapter(centerMHz: 14.175, bandwidthMHz: 0.350);

            Console.WriteLine("\nMonitoring panadapter... (Press Ctrl+C to exit)");

            // Monitor for 30 seconds
            await Task.Delay(30000);

            monitor.Cleanup();
        }
    }
}
```

---

### Digital Mode Interface

Interface for digital mode software (PSK31, FT8, etc.).

```csharp
using Flex.Smoothlake.FlexLib;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace DigitalModeInterface
{
    public class DigitalInterface
    {
        private Radio? _radio;
        private Slice? _slice;
        private DAXIQStream? _iqStream;
        private bool _isTransmitting = false;

        // IQ buffer for digital mode processing
        private float[] _iBuffer = new float[2048];
        private float[] _qBuffer = new float[2048];
        private int _bufferIndex = 0;

        public async Task<bool> Initialize(string mode = "DIGU")
        {
            API.ProgramName = "DigitalInterface";
            API.IsGUI = false;
            API.Init();

            await Task.Delay(2000);

            _radio = API.RadioList.FirstOrDefault();
            if (_radio == null) return false;

            _radio.Connect();
            for (int i = 0; i < 50 && !_radio.Connected; i++)
                await Task.Delay(100);

            if (!_radio.Connected) return false;

            // Create slice for digital modes
            _radio.RequestSliceFromRadio();
            await Task.Delay(500);

            _slice = _radio.SliceList.FirstOrDefault();
            if (_slice == null) return false;

            // Configure slice for digital modes
            _slice.Mode = mode; // DIGU or DIGL
            _slice.FilterLow = 0;
            _slice.FilterHigh = 3000;
            _slice.AGCMode = "off"; // Digital modes prefer no AGC

            Console.WriteLine($"✓ Digital interface ready");
            Console.WriteLine($"  Mode: {_slice.Mode}");
            Console.WriteLine($"  Frequency: {_slice.Freq:F3} MHz");

            return true;
        }

        public void StartIQStream(int daxChannel = 1)
        {
            // Create DAX IQ stream for digital mode processing
            _iqStream = _radio!.CreateDAXIQStream(daxChannel);
            
            if (_iqStream == null)
            {
                Console.WriteLine("Failed to create IQ stream!");
                return;
            }

            // Subscribe to IQ data
            _iqStream.DataReady += OnIQData;
            _iqStream.Start();

            Console.WriteLine($"✓ IQ stream started at {_iqStream.SampleRate} Hz");
        }

        private void OnIQData(float[] data)
        {
            // IQ data arrives interleaved: I, Q, I, Q, I, Q...
            for (int i = 0; i < data.Length; i += 2)
            {
                _iBuffer[_bufferIndex] = data[i];     // I sample
                _qBuffer[_bufferIndex] = data[i + 1]; // Q sample
                _bufferIndex++;

                if (_bufferIndex >= _iBuffer.Length)
                {
                    // Buffer full, process it
                    ProcessIQBuffer(_iBuffer, _qBuffer);
                    _bufferIndex = 0;
                }
            }
        }

        private void ProcessIQBuffer(float[] iSamples, float[] qSamples)
        {
            // This is where you'd implement digital mode decoding
            // For example: PSK31, RTTY, FT8 demodulation
            
            // Calculate average power for simple monitoring
            double power = 0;
            for (int i = 0; i < iSamples.Length; i++)
            {
                power += iSamples[i] * iSamples[i] + qSamples[i] * qSamples[i];
            }
            power = Math.Sqrt(power / iSamples.Length);

            if (power > 0.01) // Threshold for signal detection
            {
                Console.WriteLine($"Signal detected: {20 * Math.Log10(power):F1} dB");
            }
        }

        public void TuneToFrequency(double freqMHz, int offsetHz = 0)
        {
            if (_slice == null) return;

            // For digital modes, often use a carrier offset
            _slice.Freq = freqMHz + (offsetHz / 1_000_000.0);
            
            Console.WriteLine($"Tuned to {freqMHz:F6} MHz");
            if (offsetHz != 0)
                Console.WriteLine($"  Offset: {offsetHz} Hz");
        }

        public void StartTransmit()
        {
            if (_slice == null || _isTransmitting) return;

            Console.WriteLine("Starting transmission...");
            _slice.Transmit = true;
            _isTransmitting = true;

            // Monitor transmit meters
            MonitorTransmitMeters();
        }

        public void StopTransmit()
        {
            if (_slice == null || !_isTransmitting) return;

            Console.WriteLine("Stopping transmission...");
            _slice.Transmit = false;
            _isTransmitting = false;
        }

        private void MonitorTransmitMeters()
        {
            foreach (var meter in _radio!.MeterList)
            {
                if (meter.Name == "FWD" || meter.Name == "SWR" || meter.Name == "ALC")
                {
                    meter.DataReady += (data) =>
                    {
                        if (_isTransmitting)
                        {
                            Console.WriteLine($"  {meter.Name}: {data.Value:F1}");
                        }
                    };
                }
            }
        }

        public void Cleanup()
        {
            _iqStream?.Stop();
            _radio?.Disconnect();
            API.CloseSession();
        }
    }

    class Program
    {
        static async Task Main(string[] args)
        {
            var digitalInterface = new DigitalInterface();

            if (!await digitalInterface.Initialize("DIGU"))
            {
                Console.WriteLine("Initialization failed!");
                return;
            }

            // Tune to FT8 frequency on 20m
            digitalInterface.TuneToFrequency(14.074, offsetHz: 1500);

            // Start IQ streaming for decoding
            digitalInterface.StartIQStream();

            Console.WriteLine("\nMonitoring for digital signals...");
            Console.WriteLine("Press any key to exit.");

            Console.ReadKey();

            digitalInterface.Cleanup();
        }
    }
}
```

---

## Utility Examples

### Radio Monitor

Monitor radio status and telemetry.

```csharp
using Flex.Smoothlake.FlexLib;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace RadioMonitor
{
    public class Monitor
    {
        private Radio? _radio;

        public async Task Run()
        {
            if (!await Initialize())
                return;

            SetupMonitoring();

            Console.WriteLine("\n=== Radio Monitor Active ===");
            Console.WriteLine("Press Ctrl+C to exit\n");

            await Task.Delay(-1);
        }

        private async Task<bool> Initialize()
        {
            API.ProgramName = "RadioMonitor";
            API.Init();

            await Task.Delay(2000);

            _radio = API.RadioList.FirstOrDefault();
            if (_radio == null)
            {
                Console.WriteLine("No radio found!");
                return false;
            }

            _radio.Connect();
            for (int i = 0; i < 50 && !_radio.Connected; i++)
                await Task.Delay(100);

            return _radio.Connected;
        }

        private void SetupMonitoring()
        {
            // Monitor slices
            _radio!.SliceAdded += (slice) =>
            {
                Console.WriteLine($"[{DateTime.Now:HH:mm:ss}] Slice {slice.Index} ADDED");
                MonitorSlice(slice);
            };

            _radio.SliceRemoved += (slice) =>
            {
                Console.WriteLine($"[{DateTime.Now:HH:mm:ss}] Slice {slice.Index} REMOVED");
            };

            // Monitor meters
            foreach (var meter in _radio.MeterList)
            {
                if (meter.Name == "VOLTAGE" || meter.Name == "TEMP" || 
                    meter.Name == "FWD" || meter.Name == "SWR")
                {
                    meter.DataReady += (data) =>
                    {
                        LogMeter(meter.Name, data.Value);
                    };
                }
            }

            // Monitor interlock
            _radio.PropertyChanged += (sender, e) =>
            {
                if (e.PropertyName == "InterlockState")
                {
                    Console.WriteLine($"[{DateTime.Now:HH:mm:ss}] Interlock: {_radio.InterlockState}");
                }
            };
        }

        private void MonitorSlice(Slice slice)
        {
            slice.PropertyChanged += (sender, e) =>
            {
                if (e.PropertyName == "Freq" || e.PropertyName == "Mode")
                {
                    Console.WriteLine($"[{DateTime.Now:HH:mm:ss}] Slice {slice.Index}: {slice.Freq:F3} MHz, {slice.Mode}");
                }
                else if (e.PropertyName == "Transmit")
                {
                    string status = slice.Transmit ? "TX" : "RX";
                    Console.WriteLine($"[{DateTime.Now:HH:mm:ss}] Slice {slice.Index}: {status}");
                }
            };
        }

        private void LogMeter(string name, float value)
        {
            string formatted = name switch
            {
                "VOLTAGE" => $"{value:F1} V",
                "TEMP" => $"{value:F0} °C",
                "FWD" => $"{value:F0} W",
                "SWR" => $"{value:F2}:1",
                _ => $"{value:F2}"
            };

            Console.WriteLine($"[{DateTime.Now:HH:mm:ss}] {name}: {formatted}");
        }
    }

    class Program
    {
        static async Task Main(string[] args)
        {
            var monitor = new Monitor();
            await monitor.Run();
        }
    }
}
```

---

## More Examples

For more examples and patterns, check out:
- **ComPortPTT** project in this repository - COM port PTT control
- **FlexRadio Community Forum** - User-contributed examples
- **API Reference** - Method documentation with usage examples

---

## Tips and Best Practices

1. **Always initialize before use**: Call `API.Init()` first
2. **Wait for discovery**: Give time for radios to be discovered (2-5 seconds)
3. **Check connection status**: Verify `radio.Connected` before operations
4. **Use events**: Subscribe to PropertyChanged for real-time updates
5. **Handle cleanup**: Always disconnect and call `API.CloseSession()`
6. **Async patterns**: Use async/await for responsive applications
7. **Error handling**: Wrap operations in try-catch blocks
8. **Threading**: FlexLib events fire on background threads - use Dispatcher for UI updates

Happy coding! 📻
