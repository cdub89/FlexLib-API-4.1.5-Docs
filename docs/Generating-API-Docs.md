# Generating the full API reference

> **No API claims on this page.** These are tooling instructions for DocFX
> and the .NET SDK, not documentation of FlexLib members, so there is
> nothing here to verify against a FlexLib build. The source layout it
> assumes matches the 4.2.20.41343 distribution.

The hand-written guides in this repository cover the API you will
actually use day to day. For the complete class-by-class reference,
every type and member with FlexRadio's own documentation comments, you
generate it locally from the FlexLib source you already have.

## Why it is not published here

The generated reference is extracted directly from FlexLib's source. It
reproduces FlexRadio's code structure and their authored documentation
comments verbatim, and FlexLib's license does not permit republishing
that material. So this repository ships the configuration to build it,
not the output.

You lose nothing practical. Anyone entitled to read the generated
reference already has the source it is generated from, and building it
takes about a minute.

## What you need

- A licensed copy of the FlexLib source distribution, unpacked. It
  contains the `FlexLib`, `Vita`, `Util`, and `UiWpfFramework` projects.
- The .NET SDK.
- DocFX:

  ```bash
  dotnet tool install -g docfx
  ```

## Layout

`docfx.json` extracts metadata from the projects **one directory above**
itself. Copy this repository's `docs/` folder into the root of the
unpacked FlexLib source so the layout is:

```text
FlexLib_API_v4.2.x.xxxxx/
├── FlexLib/
│   └── FlexLib.csproj
├── Vita/
├── Util/
├── UiWpfFramework/
└── docs/            <- this repository's docs folder
    ├── docfx.json
    ├── toc.yml
    └── *.md
```

If your source tree is arranged differently, edit the `metadata.src.src`
path in `docfx.json` to point at the directory containing the four
projects.

## Build

From inside `docs/`:

```bash
docfx docfx.json
```

Or build and serve with live reload:

```bash
docfx docfx.json --serve
```

DocFX writes extracted metadata to `docs/api/` and the rendered site to
`docs/_site/`. Both are generated output, both are listed in
`docs/.gitignore`, and neither should be committed. With `--serve` the
site is at <http://localhost:8080>.

### If it fails

- **Errors about missing assemblies**: build the library first, then
  regenerate.

  ```bash
  dotnet build FlexLib/FlexLib.csproj -c Release
  docfx docfx.json
  ```

- **"Unable to find project"**: `docfx.json` resolves the projects
  relative to itself, so run it from inside `docs/`, with the four
  project folders one level up.
- **Port 8080 already in use**: `docfx docfx.json --serve --port 8081`.

## Notes

- **Windows only in practice.** The `UiWpfFramework` project targets WPF,
  so metadata extraction expects a Windows toolchain. The projects also
  target `net8.0-windows`, which `docfx.json` sets explicitly.
- **Resolution warnings are normal.** Extraction emits assembly
  resolution warnings for the WPF references. They do not prevent the
  site from building.
- **The generated pages are FlexRadio's content.** Treat the output as
  you would the source itself: local reference, not something to
  republish.
- **When the two disagree**, the generated reference wins over these
  hand-written pages, because it comes straight out of the build you
  compiled against. Please open an issue so the guide gets corrected,
  and include the build number and source file.
