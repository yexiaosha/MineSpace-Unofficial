# MineSpace Unofficial

A Minecraft **1.12.2** addon for **GregTech CE: Unofficial** and **Galacticraft**, plus
the playable instance used to test it.

## Repository layout

One repository, two projects:

```
MineSpace-Unofficial/
├─ Minespace-unofficial/        the addon (Gradle project, Java source)
│  ├─ src/main/java/com/minespace/unofficial/
│  ├─ HANDOFF.md                ★ start here: current state, next steps
│  ├─ DEV-NOTES.md              ★ API contracts and hard-won gotchas
│  ├─ README.md                 workspace overview and commands
│  └─ tools/                    local toolchain + setup scripts
│
└─ Minespace-unofficial-dev/    the playable instance (test runtime)
   ├─ mods/                     GTCEu, Galacticraft, CodeChickenLib, KubeJS, the addon
   ├─ kubejs/                   recipe scripts (optional companion)
   ├─ README.md                 instance usage
   └─ MOD-MANIFEST.md           mod versions, CurseForge ids, dependencies
```

## Getting started

The repository deliberately does **not** contain the toolchain, Minecraft, assets or mod
jars -- that is roughly 1 GB of regenerable, machine-specific data. Set it up once:

```powershell
# 1. Toolchain: JDK 8 + Gradle 4.10.3 + Git, downloaded into Minespace-unofficial/tools/
cd Minespace-unofficial
.\tools\bootstrap.ps1

# 2. Build the addon and deploy it into the instance
.\tools\gradle.ps1 deployToInstance

# 3. Play
cd ..\Minespace-unofficial-dev
.\Play-Minespace.bat
```

If the instance is missing its Minecraft/Forge/assets (fresh clone), run this first:

```powershell
Minespace-unofficial\tools\install-pack.ps1
```

It fills in the Java runtime, the 1.12.2 client, libraries, assets and Forge, verifying
every download by checksum. It is safe to re-run and skips whatever already exists.

## Daily commands

```powershell
.\tools\gradle.ps1 build                    # compile + reobfuscate
.\tools\gradle.ps1 deployToInstance         # build + copy the jar into the instance
.\tools\gradle.ps1 clean deployToInstance   # clean reproduce

# bisect a mod loading failure
.\tools\gradle.ps1 installMods -PskipMods=gregtech
```

> **`runClient` does not work here.** The ForgeGradle 3 userdev client crashes while
> loading GTCEu / Galacticraft (a `NullPointerException` inside FML's `NetworkRegistry`).
> Use `deployToInstance` and the instance launcher instead. Full analysis in
> [Minespace-unofficial/DEV-NOTES.md](Minespace-unofficial/DEV-NOTES.md), section 3.

## The addon in one minute

It registers GregTech materials and bridges GregTech's EU to Galacticraft's gJ:

- `gtceu/MinespaceMaterials.java` -- creates the GTCEu material registry and defines
  `desh_steel` and `meteoric_iron`. GTCEu then generates their items and recipes.
- `galacticraft/MinespaceGalacticraft.java` -- Galacticraft registry helpers plus
  `GcEnergyBridge`, an `IEnergyStorageGC` adapter that lets Galacticraft machines draw
  power from a GregTech EU buffer.

Verified running, from `Minespace-unofficial-dev/logs/latest.log`:

```
[minespace]: Registered 2 GregTech materials in registry 'minespace': desh_steel, meteoric_iron
[minespace]: GTCEu material check: desh_steel ingot -> minespace.material.desh_steel Ingot
[KubeJS]: Loaded 5/5 scripts in 0.342s
Forge Mod Loader has successfully loaded 11 mods
```

## What is not in git, and why

| Excluded | Size | How to restore |
| --- | --- | --- |
| `tools/` toolchain (JDK, Gradle, Git) | ~700 MB | `tools\bootstrap.ps1` |
| `Minespace-unofficial-dev/runtime`, `assets`, `libraries`, `versions` | ~360 MB | `tools\install-pack.ps1` |
| Mod jars in `libs/` and the instance's `mods/` | ~30 MB | `tools\fetch-mods.ps1`, or CurseMaven via Gradle |
| Gradle build output, logs, saves | -- | produced by building / playing |

Versions and CurseForge ids for every mod are recorded in
[MOD-MANIFEST.md](Minespace-unofficial-dev/MOD-MANIFEST.md), so the set can always be
rebuilt exactly.

## Requirements

- Windows (the scripts are PowerShell; the installers assume Windows paths)
- ~1.5 GB free disk after setup
- Network access to CurseForge, Forge, Mojang/BMCLAPI mirrors. Note that `github.com` and
  `services.gradle.org` are unreachable from some networks in mainland China; the setup
  scripts are written to prefer mirrors (Tsinghua, Tencent Cloud, BMCLAPI) and fall back
  to the official hosts.
