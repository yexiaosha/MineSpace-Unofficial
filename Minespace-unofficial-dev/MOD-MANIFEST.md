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
| `jei_1.12.2-4.16.5.1030.jar` | `jei` | 4.16.5.1030 | recipe/uses viewer; also enables GTCEu's `jei_integration` | optional |
| `theoneprobe-1.12-1.4.28.jar` | `theoneprobe` | 1.12-1.4.28 | block/entity tooltip overlay; enables GTCEu's `top_integration` | optional |
| `xaerolib-forge-1.12.2-1.7.3.jar` | `xaerolib` | 1.7.3 | **required by both Xaero map mods** — shared library | yes (for the maps) |
| `xaerominimap-forge-1.12.2-26.6.0.jar` | `xaerominimap` | 26.6.0 | minimap | optional |
| `xaeroworldmap-forge-1.12.2-1.47.0.jar` | `xaeroworldmap` | 1.47.0 | full-screen world map (companion of the minimap) | optional |
| `CraftTweaker2-1.12-4.1.20.698.jar` | `crafttweaker` (+ `crafttweakerjei`) | 1.12-4.1.20.698 | GT **machine** recipe scripting; enables GTCEu's `ct_integration` | optional |
| `!mixinbooter-11.17.jar` | `mixinbooter` | 11.17 | mixin loader for 1.8–1.12.2; **required by Galaxy Space 2.2.0**. The leading `!` in the file name is how MixinBooter forces itself to load first — keep it. | yes (for Galaxy Space) |
| `GalaxySpace-1.12.2-2.2.0.jar` | `galaxyspace` | 2.2.0 | Galaxy Space — the big Galacticraft planet addon (many planets/moons, its own machines and materials) | yes |
| `AsmodeusCore-1.12.2-1.0.5.jar` | `asmodeuscore` | 1.0.5 (mcmod.info inside says 1.0.2 — the author's field is stale) | library for Vi[Told]'s Galacticraft addons; required by Galaxy Space and Interstellar: Exoplanets | yes (by both) |
| `Interstellar-Exoplanets-1.12.2-0.1.3.0.jar` | `exoplanets` | 0.1.3.0 | Interstellar: Exoplanets — another Galacticraft planet addon | yes |
| `PlanetProgression-1.12.2-0.4.8.jar` | `planetprogression` | 1.12.2-0.4.8 | Planet Progression — gates planets behind research | yes |
| `MJRLegendsLib-1.12.2-1.2.1.jar` | `mjrlegendslib` | 1.12.2-1.2.1 | **required by Planet Progression** (`mjrlegendslib@[1.12.2-1.1.6,)`) | yes (for Planet Progression) |

The UI mods (JEI, The One Probe, XaeroLib, Xaero's Minimap + World Map) come from
**Modrinth**, not CurseForge — the API is key-free, so they are not listed by numeric file id
below. Re-download with:

```
https://api.modrinth.com/v2/project/<slug>/version?loaders=["forge"]&game_versions=["1.12.2"]
```

slugs: `jei`, `the-one-probe`, `xaerolib`, `xaeros-minimap`, `xaeros-world-map`,
`crafttweaker` (pick the
newest `release`-typed version, then its `primary` file).

## Recipe scripting: what goes where

The "get gregged" port of the Galacticraft scripts lives entirely in `scripts/`; the KubeJS
attempt was dropped because KubeJS 1.12.2 cannot post the events those scripts need.

| Script | Does |
| --- | --- |
| `scripts/minespace_machines.zs` | recipes for the machines this addon registers itself (currently the GregTech Oxygen Compressor, `gregtech:machine:32000`) |
| `scripts/gc_gregify_removals.zs` | takes Galacticraft's own industry away: its material processing machines, its power blocks and its duplicate materials, with GregTech recipes standing in for each |
| `scripts/gc_gregify_crafting.zs` | crafting-table removals and re-additions (launch pad, oxygen chain, air lock, solar-dust bridge) |
| `scripts/gc_gregify_machines.zs` | GregTech **machine** recipes that existed per-machine in the source: canner (canned food), bender (canisters), assembler (glowstone torch) |
| `scripts/gc_gregify_processing.zs` | the ore-to-metal chain (macerator for desh / meteoric iron / titanium, implosion compressor for Galacticraft's compressed plates, blast furnace for titanium) plus the fluid bridges that replace its Refinery and Oxygen Collector (distillery: crude oil → rocket fuel, gas collector: air → oxygen) |

The replacement of Galacticraft's machines, machine by machine - what is done, what is still
missing and what each remaining one needs - is tracked in `GC-GREGFICATION-PLAN.md`.

KubeJS 1.12.2 only integrates with the vanilla crafting table and furnace (plus IC2's
machines and GameStages/PackMode) — it has no GregTech RecipeMap support at all, so machine
recipes must go through CraftTweaker, which is what GTCEu's `ct_integration` module targets.
GTCEu exposes its machines to CraftTweaker through the `<recipemap:…>` bracket handler, e.g.
`<recipemap:assembler>.recipeBuilder().inputs(…).outputs(…).duration(…).EUt(…).buildAndRegister();`.
CraftTweaker writes its own log to `crafttweaker.log` in this folder, which is the first place
to look when a script's item or ore-dictionary name is wrong.

Three CraftTweaker/GTCEu details cost a debugging round each and are worth knowing before
editing these scripts:

- **Outputs cannot be ore dictionary entries.** `inputs(…)` takes `IIngredient`, `outputs(…)`
  takes `IItemStack`, so a GregTech output has to be a concrete stack. The processing script
  pulls those out of the ore dictionary (`oreDict.get("dustDesh").firstItem`).
- **`IOreDictEntry` members are properties**, not the Java getters: `firstItem`, `items`,
  `empty`. `getFirstItem()` fails with "No such member".
- **GTCEu's circuit ore dictionary names are voltage tiers** (`circuitLv` … `circuitUhv`),
  and GT5's `circuitBasic` exists as a name whose entry is *empty*, which silently yields a
  recipe with a blank slot. Check with `empty`, not `contains`.

Note the one real dependency in the set: **both Xaero mods declare XaeroLib as a *required*
dependency** — it is not in their `mcmod.info` (which lists `"dependencies": []`), only in the
Modrinth version metadata, so dropping in the two map jars alone produces a "missing
dependency" error at launch. GTCEu's `jei_integration` / `top_integration` modules switch
themselves on once JEI / The One Probe are present.

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

The galactic planet addons come from two different places, and one of them had to be found
the hard way (`curseforge.com` itself answers 403 on this network, and its API wants a key, so
`api.cfwidget.com/minecraft/mc-mods/<slug>` was used to read the file ids):

| Mod | Source | Identifier |
| --- | --- | --- |
| Galaxy Space 2.2.0 | Modrinth `galaxy-space` | `https://cdn.modrinth.com/data/76JhFPpa/versions/2z7O6IGy/GalaxySpace-1.12.2-2.2.0.jar` |
| AsmodeusCore 1.0.5 | Modrinth `asmodeuscore` | `https://cdn.modrinth.com/data/QMiSyFG6/versions/LBte0JqH/AsmodeusCore-1.12.2-1.0.5.jar` |
| MixinBooter 11.17 | Modrinth `mixinbooter` | `https://cdn.modrinth.com/data/G1ckZuWK/versions/6jJK1B2d/%21mixinbooter-11.17.jar` (`%21` is the leading `!`) |
| Interstellar: Exoplanets 0.1.3.0 | Modrinth `interstellar-exoplanets` | `https://cdn.modrinth.com/data/xVzIiQ35/versions/iMRGd06Y/Interstellar-Exoplanets-1.12.2-0.1.3.0.jar` |
| Planet Progression 0.4.8 | CurseForge file `4000252` | `PlanetProgression-1.12.2-0.4.8.jar` |
| MJRLegendsLib 1.2.1 | CurseForge file `3344068` | `MJRLegendsLib-1.12.2-1.2.1.jar` |

Modrinth is key-free, so those four can be re-fetched with
`https://api.modrinth.com/v2/project/<slug>/version?game_versions=["1.12.2"]&loaders=["forge"]`
followed by the `files[0].url` it returns. The two CurseForge rows are also listed in
`..\Minespace-unofficial\tools\fetch-mods.ps1`.

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
