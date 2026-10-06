# Minespace Unofficial — mod manifest

Target platform: **Minecraft 1.12.2 + Forge 14.23.5.2859**

Installed jars live in `mods/`; this file records where each one came from so the set can
be rebuilt from scratch if the folder is ever lost.

This instance serves as the **test runtime for the Minespace addon**
(`..\Minespace-unofficial`), which targets GTCEu and Galacticraft.

## Mods

| File | Mod id | Version | Role | Required? |
| --- | --- | --- | --- | --- |
| `gregtech-1.12.2-2.8.10-beta.jar` | `gregtech` | 2.8.10-beta | GregTech CE: Unofficial — main addon target | yes |
| `CodeChickenLib-1.12.2-3.2.3.358-universal.jar` | `codechickenlib` | 3.2.3.358 | hard dependency of GTCEu | yes |
| `Galacticraft-1.12.2-4.0.7.jar` | `galacticraftcore`, `galacticraftplanets`, `micdoodlecore` | 4.0.7 | Galacticraft — second addon target | yes for GC work |
| `KubeJS-forge-1.12.2-1.1.0.65.jar` | `kubejs` | 1.1.0.65 | recipe tweaks without recompiling | optional |
| `minespace-0.2.0.jar` | `minespace` | 0.2.0 | **this project's addon** | — |

The GTCEu jar name carries a dash (`gregtech-1.12.2-2.8.10-beta.jar`) but `Galacticraft`'s
does not, which is the upstream naming, not a typo.

## Dependency notes, verified against the jars themselves

- **GTCEu requires CodeChickenLib.** Its `mcmod.info` declares
  `"dependencies": ["codechickenlib"]`, and removing CCL prevents loading.
- **Galacticraft bundles its own coremod.** The jar declares
  `FMLCorePlugin: micdoodle8.mods.miccore.MicdoodlePlugin` with
  `FMLCorePluginContainsFMLMod: true`, so there is **no** separate MicdoodleCore jar on
  1.12.2 — but FML still requires the `micdoodlecore` mod id to be *registered*, which
  only happens when the jar loads through normal mod discovery. This is why the addon's
  `installMods` task copies jars into `run/mods` rather than putting them on the launch
  classpath; see `..\Minespace-unofficial\DEV-NOTES.md`, section 3.
- **GTCEu is a coremod** (`FMLCorePlugin: gregtech.asm.GregTechLoadingPlugin`) and must
  stay in `mods/`.
- **KubeJS 1.12.2 has no mod dependencies.** Its `mcmod.info` declares
  `"dependencies": []`. The Architectury/Rhino pair described in the modern KubeJS
  documentation applies to KubeJS 6 (1.16+), **not** to this 1.12.2 build — do not add
  them.
- **Load order:** the addon declares
  `required-after:codechickenlib; required-after:gregtech; after:galacticraftcore`, so it
  initialises after GTCEu (needed for material registration) but still loads when
  Galacticraft is absent.

## Download sources

CurseForge has no public direct-download API without a key, but the file CDN is
addressable. The URL is built from the numeric file id: take the first four digits as
one path segment and the remaining digits as another.

```
https://edge.forgecdn.net/files/<id[0:4]>/<id[4:]>/<filename>
```

| Mod | CurseForge project id | File id |
| --- | --- | --- |
| GregTech CE: Unofficial | 557242 | 5519022 |
| Galacticraft Legacy | 564236 | 6364107 |
| CodeChicken Lib 1.8.+ | 242818 | 2779848 |
| KubeJS | 238086 | 3052392 |

The same artifacts are addressable through CurseMaven, which is what the development
workspace uses in `build.gradle`:

```
curse.maven:gregtech-ce-unofficial-557242:5519022
curse.maven:galacticraft-legacy-564236:6364107
curse.maven:codechicken-lib-1-8-242818:2779848
```

`tools\fetch-mods.ps1` in the repository root re-downloads the original jars from the CDN
and prints their metadata, so this table does not have to be trusted blindly.

## Known interactions between these mods

Both GregTech and Galacticraft introduce their own oil/fluid and material registries, and
both generate ores. Overlaps are expected in the following areas:

- **Fluids** — both define oil-like fluids. If you see a duplicate fluid id, check
  `config/gregtech/` and Galacticraft's config.
- **Ores** — both generate tin, copper and aluminium. Disable one side's generation, or
  accept the duplicates. Ore dictionary unification is the usual fix.
- **Recipe overlap** — GregTech overrides many vanilla recipes. Use the addon or KubeJS to
  remove a specific recipe.

Configs are at defaults; the instance boots clean. Adjust `config/` once you decide how
the two should share materials.

## Version policy

- Forge: pinned to **14.23.5.2859**, the *Recommended* build for 1.12.2 and the version
  the development workspace targets. Newer 1.12.2 builds exist (up to 14.23.5.2864,
  released 2025-12-03) but mods are generally tested against the recommended build.
- GTCEu: **2.8.10-beta**, the latest 1.12.2 release (2024-07-10).
- Galacticraft Legacy: **4.0.7**, the latest 1.12.2 release.
- KubeJS: **1.1.0.65**, the latest 1.12.2 release.
