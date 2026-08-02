<#
.SYNOPSIS
    Compiles the C# code blocks in docs/*.md against a real FlexLib source tree.

.DESCRIPTION
    The value of this repository is that a reader can copy a sample and have it
    compile. Reviewing for that is unreliable: an adversarial review on
    2026-08-02 found three compile-breaking errors that a source-grep pass had
    missed, because "does this member exist" and "does this code compile" are
    different questions. This script asks the second one.

    It extracts every ```csharp block, classifies it, compiles what can be
    compiled, and maps each diagnostic back to the documentation file and line
    using #line directives, so failures read as docs/Examples.md(856) rather
    than as some generated path.

    Windows only. FlexLib targets net8.0-windows and pulls in WPF, so metadata
    and compilation need a Windows toolchain.

.PARAMETER FlexLibPath
    Root of an unpacked FlexLib source distribution (the folder containing
    FlexLib/, Util/, Vita/, UiWpfFramework/). Defaults to the newest sibling
    directory matching FlexLib_API_v*.

.PARAMETER DocsPath
    Folder holding the markdown. Defaults to ../docs relative to this script.

.PARAMETER ListOnly
    Print the block inventory and classification, then exit without building.

.PARAMETER IncludeFragments
    Treat fragment failures as gate failures too. Off by default: fragments are
    partial snippets, so some failures are missing-context noise rather than
    real API errors. See the notes on diagnostic triage below.

.PARAMETER KeepArtifacts
    Leave the generated projects on disk for inspection.

.EXAMPLE
    .\tools\Test-DocExamples.ps1
    .\tools\Test-DocExamples.ps1 -ListOnly
    .\tools\Test-DocExamples.ps1 -FlexLibPath C:\src\FlexLib_API_v4.2.20.41343 -IncludeFragments

.NOTES
    Exit code 0 when every gating block compiles, 1 otherwise, so this can run
    as a blocking gate. See CLAUDE.md "Doc Quality".
#>
[CmdletBinding()]
param(
    [string] $FlexLibPath,
    [string] $DocsPath,
    [switch] $ListOnly,
    [switch] $IncludeFragments,
    [switch] $KeepArtifacts
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot   = Split-Path -Parent $scriptRoot
if (-not $DocsPath) { $DocsPath = Join-Path $repoRoot 'docs' }

# ---------------------------------------------------------------- FlexLib tree

if (-not $FlexLibPath) {
    $candidates = Get-ChildItem -Path (Split-Path -Parent $repoRoot) -Directory -Filter 'FlexLib_API_v*' -ErrorAction SilentlyContinue |
                  Sort-Object Name -Descending
    if ($candidates) { $FlexLibPath = $candidates[0].FullName }
}

if (-not $FlexLibPath -or -not (Test-Path $FlexLibPath)) {
    Write-Error @"
No FlexLib source tree found. Pass -FlexLibPath pointing at an unpacked
distribution (the folder containing FlexLib/, Util/, Vita/, UiWpfFramework/).

FlexLib is proprietary to FlexRadio Systems and is not included in this
repository. Use your own licensed copy, and keep it outside any git repo.
"@
    exit 1
}

$flexLibCsproj = Join-Path $FlexLibPath 'FlexLib\FlexLib.csproj'
if (-not (Test-Path $flexLibCsproj)) {
    Write-Error "Found '$FlexLibPath' but no FlexLib\FlexLib.csproj inside it. Is that the distribution root?"
    exit 1
}

Write-Host "FlexLib source : $FlexLibPath"
Write-Host "Docs           : $DocsPath"

# ------------------------------------------------------------ block extraction

class DocBlock {
    [string] $File       # doc file name
    [string] $Path       # doc file full path
    [int]    $Line       # 1-based line of the block's first content line
    [string] $Body
    [string] $Kind
    [string] $SkipReason
}

function Get-DocBlocks {
    param([string] $Folder)

    $blocks = [System.Collections.Generic.List[DocBlock]]::new()

    foreach ($file in Get-ChildItem -Path $Folder -Filter '*.md' | Sort-Object Name) {
        $lines = Get-Content -LiteralPath $file.FullName
        $i = 0
        while ($i -lt $lines.Count) {
            if ($lines[$i] -match '^\s*```(\w+)?\s*$') {
                $lang  = if ($Matches[1]) { $Matches[1].ToLower() } else { '' }
                $start = $i + 1                     # 0-based index of first body line
                $body  = [System.Collections.Generic.List[string]]::new()
                $i++
                while ($i -lt $lines.Count -and $lines[$i] -notmatch '^\s*```\s*$') {
                    $body.Add($lines[$i]); $i++
                }
                if ($lang -eq 'csharp') {
                    # Look back for a "Before (v3.x)" / "Old (v3.x)" heading or caption.
                    $ctxFrom = [Math]::Max(0, $start - 13)
                    $ctx     = ($lines[$ctxFrom..([Math]::Max($ctxFrom, $start - 1))] -join "`n").ToLower()
                    $bodyTxt = ($body -join "`n")
                    $legacy  = ($ctx -match '(before|old)\s*\(?v?3\.x') -or
                               ($bodyTxt.ToLower() -match '//\s*(old|before)\s*\(?v?3')

                    $b = [DocBlock]::new()
                    $b.File = $file.Name
                    $b.Path = $file.FullName
                    $b.Line = $start + 1            # 1-based
                    $b.Body = $bodyTxt
                    $b.Kind = if ($legacy) { 'skip-legacy' } else { '' }
                    if ($legacy) { $b.SkipReason = 'intentionally shows a superseded v3.x API' }
                    $blocks.Add($b)
                }
            }
            $i++
        }
    }
    return $blocks
}

function Set-BlockKind {
    param([DocBlock] $Block)

    if ($Block.Kind -eq 'skip-legacy') { return }

    $content = $Block.Body -split "`n" |
               Where-Object { $_.Trim() -and -not $_.Trim().StartsWith('//') }

    if (-not $content) {
        $Block.Kind = 'skip-empty'; $Block.SkipReason = 'no code'; return
    }

    # A signature listing is reference material, not code: member signatures with
    # no bodies and no executable statements. 54 of 135 blocks are this shape,
    # concentrated in API-Reference.md, and none of them can compile standalone.
    $hasStatement = $false
    $hasControl   = $false
    foreach ($line in $content) {
        if ($line -match ';\s*(//.*)?$' -and $line -notmatch '\{\s*get;') { $hasStatement = $true }
        if ($line -match '^\s*(if|for|foreach|while|switch|return|await|try|using\s*\(|var\s|Console\.)') { $hasControl = $true }
    }
    if (-not $hasStatement -and -not $hasControl) {
        $Block.Kind = 'skip-signature-listing'
        $Block.SkipReason = 'API signature listing, not compilable code'
        return
    }

    if ($Block.Body -match '(?m)\bstatic\s+(async\s+)?[\w<>\[\]]+\s+Main\s*\(') { $Block.Kind = 'program'; return }
    if ($Block.Body -match '(?m)^\s*(public\s+)?(class|struct)\s+\w+')          { $Block.Kind = 'type';    return }
    $Block.Kind = 'fragment'
}

$blocks = Get-DocBlocks -Folder $DocsPath
foreach ($b in $blocks) { Set-BlockKind -Block $b }

$programs  = @($blocks | Where-Object Kind -eq 'program')
$types     = @($blocks | Where-Object Kind -eq 'type')
$fragments = @($blocks | Where-Object Kind -eq 'fragment')
$skipped   = @($blocks | Where-Object { $_.Kind -like 'skip-*' })

Write-Host ""
Write-Host "Blocks found   : $($blocks.Count)"
Write-Host "  programs     : $($programs.Count)   (compiled individually, gating)"
Write-Host "  types        : $($types.Count)   (compiled together, gating)"
Write-Host "  fragments    : $($fragments.Count)   (compiled together, $(if ($IncludeFragments) { 'gating' } else { 'advisory' }))"
Write-Host "  skipped      : $($skipped.Count)"
foreach ($grp in $skipped | Group-Object Kind) {
    Write-Host "      $($grp.Name): $($grp.Count)"
}

if ($ListOnly) {
    Write-Host ""
    $blocks | ForEach-Object { "{0,-26} {1,5}  {2}" -f $_.File, $_.Line, $_.Kind } | Write-Host
    exit 0
}

# --------------------------------------------------------------- project setup

$workRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("docexamples-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $workRoot -Force | Out-Null

$csprojTemplate = @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Library</OutputType>
    <TargetFramework>net8.0-windows</TargetFramework>
    <UseWPF>true</UseWPF>
    <Nullable>enable</Nullable>
    <TreatWarningsAsErrors>false</TreatWarningsAsErrors>
    <NoWarn>CS1591;CS0168;CS0219;CS1998;CS0067</NoWarn>
    <EnableDefaultCompileItems>true</EnableDefaultCompileItems>
    <AssemblyName>DocExamples</AssemblyName>
    <RootNamespace>DocExamples</RootNamespace>
  </PropertyGroup>
  <ItemGroup>
    <ProjectReference Include="$flexLibCsproj" />
  </ItemGroup>
</Project>
"@

# Usings every generated unit gets. Kept broad so a snippet is judged on its
# FlexLib usage rather than on whether the author wrote the right using.
$commonUsings = @'
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Flex.Smoothlake.FlexLib;
using Flex.Util;
'@

function New-ProjectDir {
    param([string] $Name)
    $dir = Join-Path $workRoot $Name
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $dir 'Project.csproj') -Value $csprojTemplate -Encoding UTF8
    return $dir
}

# #line makes the compiler report the ORIGINAL doc file and line, so diagnostics
# need no offset arithmetic and stay correct as the docs move around.
function Get-LineDirective {
    param([DocBlock] $Block)
    $rel = (Resolve-Path -LiteralPath $Block.Path).Path
    return "#line $($Block.Line) `"$rel`""
}

# --------------------------------------------------------------- build helpers

function Invoke-Build {
    param([string] $Dir, [string] $Label)

    Write-Host "  building $Label ..." -NoNewline
    $out = & dotnet build (Join-Path $Dir 'Project.csproj') -c Debug --nologo -v quiet 2>&1
    $code = $LASTEXITCODE
    if ($code -eq 0) { Write-Host " ok" } else { Write-Host " FAILED" }
    return [pscustomobject]@{ ExitCode = $code; Output = ($out -join "`n") }
}

# Diagnostics that mean "the documented API is wrong". These are the ones worth
# gating on. CS0103/CS0246 usually mean the snippet referenced a variable or
# type the harness did not declare, which is a limitation of wrapping a
# fragment, not a documentation defect.
$realErrorCodes = @(
    'CS0117', # type does not contain a definition
    'CS1061', # no such member / no extension method  <- Slice.Mode class of bug
    'CS1501', # no overload takes N arguments
    'CS1503', # argument type mismatch                <- float[] vs ushort[]
    'CS7036', # required parameter has no argument
    'CS0029', # cannot implicitly convert             <- string to AGCMode enum
    'CS0266', # explicit conversion required
    'CS0123', # delegate signature mismatch           <- DataReady handlers
    'CS0072', # event override mismatch
    'CS0019', # operator cannot be applied
    'CS1593', # delegate does not take N arguments
    'CS0154', # property lacks a get accessor
    'CS0200'  # property cannot be assigned, read-only
)
$contextErrorCodes = @('CS0103', 'CS0246', 'CS0234')

function Split-Diagnostics {
    param([string] $Output)

    $real = [System.Collections.Generic.List[string]]::new()
    $ctx  = [System.Collections.Generic.List[string]]::new()
    $other= [System.Collections.Generic.List[string]]::new()

    foreach ($line in ($Output -split "`n")) {
        if ($line -notmatch 'error\s+(CS\d+)') { continue }
        $code = $Matches[1]
        $text = $line.Trim()
        if     ($realErrorCodes    -contains $code) { $real.Add($text) }
        elseif ($contextErrorCodes -contains $code) { $ctx.Add($text) }
        else                                        { $other.Add($text) }
    }
    return [pscustomobject]@{ Real = $real; Context = $ctx; Other = $other }
}

# ------------------------------------------------------- build the FlexLib dep

Write-Host ""
Write-Host "Building FlexLib once so per-block builds are incremental ..."
& dotnet build $flexLibCsproj -c Debug --nologo -v quiet | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "FlexLib itself failed to build. Fix that before judging the docs."
    exit 1
}

# ------------------------------------------------------------ compile programs

$failures = [System.Collections.Generic.List[object]]::new()

Write-Host ""
Write-Host "Compiling $($programs.Count) full programs (each in its own project) ..."
$n = 0
foreach ($b in $programs) {
    $n++
    $dir = New-ProjectDir -Name ("program-$n")
    # Full programs declare their own namespace/class/Main. Strip Main's entry
    # point role by compiling as a library; the code still has to be valid.
    $src = @"
$commonUsings

$(Get-LineDirective -Block $b)
$($b.Body)
#line default
"@
    Set-Content -LiteralPath (Join-Path $dir 'Block.cs') -Value $src -Encoding UTF8
    $r = Invoke-Build -Dir $dir -Label "$($b.File):$($b.Line)"
    if ($r.ExitCode -ne 0) {
        $d = Split-Diagnostics -Output $r.Output
        $failures.Add([pscustomobject]@{
            Block = $b; Kind = 'program'; Diagnostics = $d; Gating = $true
        })
    }
}

# --------------------------------------------- compile types + fragments as one

function Build-Batch {
    param([object[]] $Blocks, [string] $Label, [bool] $Gating, [bool] $WrapInMethod)

    if (-not $Blocks -or $Blocks.Count -eq 0) { return }

    Write-Host ""
    Write-Host "Compiling $($Blocks.Count) $Label in a single project ..."
    $dir = New-ProjectDir -Name $Label

    $i = 0
    foreach ($b in $Blocks) {
        $i++
        $safe = ($b.File -replace '[^A-Za-z0-9]', '_') + "_$($b.Line)"
        if ($WrapInMethod) {
            # Fragments are statements without context. Wrap each in its own
            # async method inside its own class so names cannot collide, and
            # declare the receivers the samples conventionally use.
            $src = @"
$commonUsings

namespace DocExamples.Generated
{
    internal class Frag_$safe
    {
        private Radio? radio, _radio;
        private Slice? slice, _slice;
        private Panadapter? pan, panadapter, _panadapter;
        private Meter? meter, _meter, _signalMeter;
        private Waterfall? waterfall;
        private TNF? tnf;
        private Memory? memory;
        private Amplifier? amp, amplifier;
        private Xvtr? xvtr;
        private Equalizer? eq, equalizer;
        private Tuner? tuner;
        private Spot? spot;
        private CWX? cwx;
        private DAXRXAudioStream? audioStream, stream;
        private DAXTXAudioStream? txStream;
        private DAXIQStream? iqStream;

        internal async Task Run()
        {
            await Task.Yield();
$(Get-LineDirective -Block $b)
$($b.Body)
#line default
        }
    }
}
"@
        } else {
            $src = @"
$commonUsings

namespace DocExamples.Generated.N$safe
{
$(Get-LineDirective -Block $b)
$($b.Body)
#line default
}
"@
        }
        Set-Content -LiteralPath (Join-Path $dir "$safe.cs") -Value $src -Encoding UTF8
    }

    $r = Invoke-Build -Dir $dir -Label $Label
    if ($r.ExitCode -ne 0) {
        $d = Split-Diagnostics -Output $r.Output
        $script:failures.Add([pscustomobject]@{
            Block = $null; Kind = $Label; Diagnostics = $d; Gating = $Gating
        })
    }
}

Build-Batch -Blocks $types     -Label 'types'     -Gating $true              -WrapInMethod $false
Build-Batch -Blocks $fragments -Label 'fragments' -Gating $IncludeFragments  -WrapInMethod $true

# ---------------------------------------------------------------------- report

Write-Host ""
Write-Host "======================================================================"
Write-Host " RESULTS"
Write-Host "======================================================================"

$gatingFailures = @($failures | Where-Object { $_.Gating -and $_.Diagnostics.Real.Count + $_.Diagnostics.Other.Count -gt 0 })
$realCount = 0

foreach ($f in $failures) {
    $where = if ($f.Block) { "$($f.Block.File):$($f.Block.Line)" } else { $f.Kind }
    if ($f.Diagnostics.Real.Count -gt 0) {
        Write-Host ""
        Write-Host "API ERRORS  [$where]" -ForegroundColor Red
        $f.Diagnostics.Real | ForEach-Object { Write-Host "   $_" }
        $realCount += $f.Diagnostics.Real.Count
    }
    if ($f.Diagnostics.Other.Count -gt 0) {
        Write-Host ""
        Write-Host "OTHER ERRORS  [$where]" -ForegroundColor Yellow
        $f.Diagnostics.Other | ForEach-Object { Write-Host "   $_" }
    }
    if ($f.Diagnostics.Context.Count -gt 0) {
        Write-Host ""
        Write-Host "CONTEXT-ONLY (snippet needs setup the harness did not supply) [$where]" -ForegroundColor DarkGray
        $f.Diagnostics.Context | Select-Object -First 10 | ForEach-Object { Write-Host "   $_" }
        if ($f.Diagnostics.Context.Count -gt 10) {
            Write-Host "   ... and $($f.Diagnostics.Context.Count - 10) more"
        }
    }
}

Write-Host ""
Write-Host "Blocks: $($blocks.Count) total, $($programs.Count + $types.Count + $fragments.Count) compiled, $($skipped.Count) skipped."
Write-Host "Skipped blocks are listed with -ListOnly. None are silently dropped."
Write-Host "API-level errors: $realCount"

if (-not $KeepArtifacts) {
    Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "Artifacts kept at: $workRoot"
}

if ($gatingFailures.Count -gt 0) {
    Write-Host ""
    Write-Host "GATE FAILED" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "GATE PASSED" -ForegroundColor Green
exit 0
