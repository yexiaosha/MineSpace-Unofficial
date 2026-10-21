# Minespace Unofficial 鈥?mod manifest

Target platform: **Minecraft 1.12.2 + Forge 14.23.5.2859**

Installed jars live in `mods/`; this file records where each one came from so the set can
be rebuilt from scratch if the folder is ever lost.

This instance serves as the **test runtime for the Minespace addon**
(`..\Minespace-unofficial`), which targets **GregTech CE: TJ Edition** and Galacticraft.
See the "Migrated to the GTCE-TJ stack" note below the table for the 2026-10-11 switch.

## Mods

| File | Mod id | Version | Role | Required? |
| --- | --- | --- | --- | --- |
| `gregtech_tj_fork-1.18.3.jar` | `gregtech` | 1.18.3 | **GregTech CE: TJ Edition** 鈥?main addon target | yes |
| `gregicality_tj_fork-0.26.3.jar` | `gtadditions` | 0.26.3 | Gregicality TJ Fork 鈥?UHV+ content, multiblocks, chemistry | yes |
| `appliedenergistics2-rv6-stable-7-extended_life-v0.55.6.jar` | `appliedenergistics2` | v0.55.6 | **hard dependency of GTCE-TJ** (`MetaTool` references it) 鈥?pinned, see below | yes |
| `CodeChickenLib-1.12.2-3.2.3.358-universal.jar` | `codechickenlib` | 3.2.3.358 | hard dependency of GTCE-TJ | yes |
| `Galacticraft-1.12.2-4.0.7.jar` | `galacticraftcore`, `galacticraftplanets`, `micdoodlecore` | 4.0.7 | Galacticraft 鈥?second addon target | yes for GC work |
| `KubeJS-forge-1.12.2-1.1.0.65.jar` | `kubejs` | 1.1.0.65 | recipe tweaks without recompiling | optional |
| `minespace-0.2.0.jar` | `minespace` | 0.2.0 | **this project's addon** | 鈥?|
| `RTG-1.12.2-6.1.0.0-snapshot.1.jar` | `rtg` | 6.1.0.0-snapshot.1 | Realistic Terrain Generation - realistic overworld terrain; select the RTG world type for new worlds | optional |
| `jei_1.12.2-4.16.1.302.jar` | `jei` | 4.16.1.302 | recipe/uses viewer; also enables GT's `jei_integration` | optional |
| `theoneprobe-1.12-1.4.28.jar` | `theoneprobe` | 1.12-1.4.28 | block/entity tooltip overlay; enables GT's `top_integration` | optional |
| `xaerolib-forge-1.12.2-1.7.3.jar` | `xaerolib` | 1.7.3 | **required by both Xaero map mods** 鈥?shared library | yes (for the maps) |
| `xaerominimap-forge-1.12.2-26.6.0.jar` | `xaerominimap` | 26.6.0 | minimap | optional |
| `xaeroworldmap-forge-1.12.2-1.47.0.jar` | `xaeroworldmap` | 1.47.0 | full-screen world map (companion of the minimap) | optional |
| `CraftTweaker2-1.12-4.1.20.698.jar` | `crafttweaker` (+ `crafttweakerjei`) | 1.12-4.1.20.698 | GT **machine** recipe scripting; enables GT's `ct_integration` | optional |
| `!mixinbooter-11.17.jar` | `mixinbooter` | 11.17 | mixin loader for 1.8鈥?.12.2; **required by Galaxy Space 2.2.0**. The leading `!` in the file name is how MixinBooter forces itself to load first 鈥?keep it. | yes (for Galaxy Space) |
| `GalaxySpace-1.12.2-2.2.0.jar` | `galaxyspace` | 2.2.0 | Galaxy Space 鈥?the big Galacticraft planet addon (many planets/moons, its own machines and materials) | yes |
| `AsmodeusCore-1.12.2-1.0.5.jar` | `asmodeuscore` | 1.0.5 (mcmod.info inside says 1.0.2 鈥?the author's field is stale) | library for Vi[Told]'s Galacticraft addons; required by Galaxy Space | yes (for Galaxy Space) |
| `PlanetProgression-1.12.2-0.4.8.jar` | `planetprogression` | 1.12.2-0.4.8 | Planet Progression 鈥?gates planets behind research | yes |
| `MJRLegendsLib-1.12.2-1.2.1.jar` | `mjrlegendslib` | 1.12.2-1.2.1 | **required by Planet Progression** (`mjrlegendslib@[1.12.2-1.1.6,)`) | yes (for Planet Progression) |
| `forestry_1.12.2-5.8.2.427.jar` | `forestry` | 5.8.2.427 | Forestry - bees / trees / its own machine line; gregged by `scripts/integration.zs` | optional |
| `EnderIO-1.12.2-5.3.72.jar` | `enderio` | 5.3.72 | Ender IO - conduits, alloys, machines | optional |
| `EnderCore-1.12.2-0.5.78.jar` | `endercore` | 0.5.78 | **required by Ender IO** | yes (for Ender IO) |
| `StorageDrawers-1.12.2-5.5.3.jar` | `storagedrawers` | 5.5.3 | Storage Drawers - drawers, controllers, upgrades | optional |
| `Chameleon-1.12-4.1.3.jar` | `chameleon` | 1.12-4.1.3 | **required by Storage Drawers** - must be the CurseForge file, see below | yes (for Storage Drawers) |
| `ironchest-1.12.2-7.0.72.847.jar` | `ironchest` | 7.0.72.847 | Iron Chests - the tiered chest line | optional |
| `modtweaker-4.0.20.11.jar` | `modtweaker` | 4.0.20.11 | CraftTweaker addon: recipe access for Forestry's machines (carpenter, centrifuge, squeezer, fermenter, still, moistener, thermionic fabricator) and several mods this pack does not install | optional |
| `MTLib-3.0.7.jar` | `mtlib` | 3.0.7 | **required by ModTweaker** (`MissingModsException` without it) | yes (for ModTweaker) |

**The Chameleon jar has to come from CurseForge, not Modrinth.** The file Modrinth publishes as
`Chameleon-1.12.2-4.1.3.jar` is the *unreobfuscated developer* build: the whole jar contains zero
SRG names (`func_*` / `field_*`) while every other 1.12.2 mod in this folder has thousands, and
loading it makes Storage Drawers die in `init` with
`NoSuchMethodError: net.minecraft.item.Item.getByNameOrId` (whose SRG name is `func_179117_c`).
The CurseForge file (`chameleon` file 2450900) is the reobfuscated release. A quick sanity check
for any future jar: `rg -c 'func_[0-9]+_'` inside it should be non-zero.

All six were added 2026-10-11; sources:

| Mod | Source | File |
| --- | --- | --- |
| Forestry 5.8.2.427 | Modrinth | `forestry_1.12.2-5.8.2.427.jar` |
| Ender IO 5.3.72 | Modrinth | `EnderIO-1.12.2-5.3.72.jar` |
| EnderCore 0.5.78 | Modrinth | `EnderCore-1.12.2-0.5.78.jar` |
| Storage Drawers 5.5.3 | CurseForge project 223852 | file 5981297 |
| Chameleon 1.12-4.1.3 | CurseForge project 230497 | file 2450900 |
| Iron Chests 7.0.72.847 | CurseForge project 228756 | file 2747935 |

**Migrated to the GTCE-TJ stack 2026-10-11.** The GTCEu 2.8.10-beta stack (GTCEu, GCYM 1.2.11,
GTFO, SussyPatches, ConfigAnytime) is parked at
`%TEMP%\minespace-removed\2026-10-11-gtceu-stack\` and replaced by GTCE: TJ Edition. Exact
sources, all 1.12.2:

| Mod | CF project | File id |
| --- | --- | --- |
| GTCE: TJ Edition 1.18.3 | 597032 | 8942273 |
| Gregicality TJ Fork 0.26.3 | 607023 | 8942284 |
| AE2 Unofficial Extended Life **v0.55.6** | 570458 | 4402048 |

AE2UEL is pinned to **v0.55.6 on purpose**: GT's AE2 integration recipes reference
`appeng` items/classes that v0.56.7 renames, so on 0.56.7 every GT AE2 recipe fails to build
(`Application recipe ... Item not found`) while 0.55.6 runs them. AE2 is not optional for this
stack - `gregtech.api.unification.meta.MetaTool` hard-references it.

**TJ Additions is excluded on purpose** (versions 2.9.0 and 2.10.0 both collide with
Gregicality TJ on machine id 4205 in every pairing available on CurseForge).

**Worldgen: stone types must be registered inside GT's preInit - this was the crash that the
"switch to TJ" run surfaced.** GTCE-TJ bakes its ore blocks from
`StoneType.STONE_TYPE_REGISTRY` inside `GregTechMod.preInit` (`MetaBlocks.init()`), 16 stone type
ids per ore block, i.e. *before* any `RegistryEvent.Register<Block>` listener can run. A stone
type registered later is in the registry but in no ore block, and
`FillerConfigUtils$OreFilterEntry.apply` is a bare `blockStateMap.get(...)` with no null guard, so
the vein filler hands `null` to `World.setBlockState` and dies with a NullPointerException
(`Chunk.func_177436_a:542`, reported by Galacticraft as "Error in another mod's worldgen").
Measured on this instance: 147 NPEs in the overworld, every one of them a vein hitting air that
had been resolved to a stone type. The addon now creates its 21 stone types from
`MinespaceMaterials.onMaterialsInit()` - the window between `Material.runMaterialHandlers()` and
`MetaBlocks.init()` - and resolves every block-shaped part of them lazily by registry name
(Forge answers an unknown block name with `minecraft:air`, which is what turned a missing Galaxy
Space lookup into "match every air block").

Verified after the fix, fresh world, dedicated server:

```
[FML]: Forge Mod Loader has successfully loaded 28 mods
[DedicatedServer]: Done (7.889s)!
NullPointerException count in latest.log: 0
[minespace]: All 17 Galaxy Space rock blocks resolved - the stone types are live
```

**Addendum, 2026-10-15 (TJ-MIGRATION-PLAN.md 6cj).** The block above is the *GTCEu-era* check; the
current numbers are 47 mods and `Done` in four to seven seconds. The same pass measured the
material-id question that section 7 of the plan had left open: GTCE's `Material.MATERIAL_REGISTRY` is
a `GTControlledRegistry` with a capacity of 1000, Gregicality occupies the top of that range
(`luv_superconductor_base` at 972), and `MinespaceMaterials` allocates from the lowest free slot
upwards instead of reserving a block. A probe iterated the finished registry and asked every
material's id to resolve back to itself - the failure mode of a taken id is a *silent* re-point, not
an error - and found **794 materials, highest id 999, 0 mismatches**; this addon's six landed on
desh 0, meteoric iron 136, desh steel 147, solar 160, onyx 178, dolomite 289. The full id map is
parked in `%TEMP%\minespace-cleanup-2026-10-12\logs-archive\material_ids_all.txt.*`.

**Planet vein sets: ported 2026-10-11** (`tools\port-worldgen-veins.ps1`, re-runnable). The
GTCEu-era per-body sets were rewritten into the GTCE format - GTCEu's `layered` generator became
`ellipsoid` (same radius pair, GTCE-TJ's `EllipsoidGenerator` takes exactly that) and its
`layered` filler became `simple`+`weight_random`, with the structural primary/secondary/
between/sporadic keys mapped onto decaying weights and duplicate materials merged. The
`minespace:` material namespace was dropped (GTCE material names are global) and
`ore:plutonium`, which GTCE-TJ has no ore for, became `ore:enriched_naquadric_compound` (the
rare ore GT's own end naquadah vein uses). 49 files land in `config\gregtech\worldgen\<body>\`:
moon 9, mars 14, venus 13, asteroids 11, ceres 1, barnarda 1. The old overworld/nether/end
files stay parked - GTCE-TJ already ships its own set for those dimensions.

Two more things had to be fixed before a single planet vein could reach the world:

* **GT's overworld veins were also being applied to planets.** Their files carry no
  `dimension_filter`, so they fall back to `is_surface_world` - and in 1.12.2 that reads
  `WorldProvider.getDimensionType()`, whose default is `OVERWORLD`, which Galacticraft's planet
  providers inherit. Beyond generating the overworld set (coal, oil/gas spheres, granite/marble)
  on every planet, that made GregTech evaluate the overworld oil/gas definitions'
  `biome_dictionary` modifier against the planet biome, and `BiomeDictionary` throws
  `Cannot add types to unregistered biome` for Galacticraft's biomes - which aborted the whole
  dimension's vein pass. `tools\fix-worldgen-overworld-scope.ps1` pins all 44 overworld files to
  `dimension_id:0`.
* **Galaxy Space's own config crashes planet chunk generation.** `config\GalaxySpace\world.conf`
  had an empty line inside `S:oreGenSettings < ... >`, i.e. a ""-element that
  `GSEventHandler.onPlanetDecorated` feeds straight into `Integer.parseInt` - a
  `NumberFormatException` every time a planet chunk is decorated. The line is removed (the list
  is now genuinely empty).
* **GregTech's vein grid had no terrain heights on planets** (addon change, not config):
  `CachedGridEntry` only measures the terrain when no chunk of its 3x3 cell is generated yet;
  in a Galacticraft dimension the chunk already counts as generated, so GregTech keeps the
  chunk capability's default `0/0` heights, and `doGenerateVein` computes
  `maxHeight = min(0, limit) = 0 < minHeight` and skips every vein. `MinespacePlanetOreGen` now
  primes those heights from `getPrecipitationHeight`/`getTopSolidOrLiquidBlock` in
  `PopulateChunkEvent.Pre` for the whole generated 3x3 cell.

Verified on a dedicated server, fresh world, 64 chunks per dimension, counting
`gregtech:ore_*` blocks through GregTech's own vein APIs:

| Dimension | GT ore blocks | distinct ores |
| --- | --- | --- |
| Overworld (0) | 11489 | 82 |
| Moon (-28) | 1574 | 8 |
| Mars (-29) | 1532 | 9 |
| Asteroids (-31) | 1379 | 6 |
| Ceres (-1007) | 1521 | 11 |

The Ceres sample even shows our own stone type in use: `gregtech:ore_brown_limonite_1@ceres_stone`.

**Per-body ore textures: done too** (2026-10-11, later the same day). Until this fix the
Moon/Mars/Venus ores were placed as GT's own `stone` variant, because `BlockBasicMoon`,
`BlockBasicMars` and `BlockBasicVenus` override `isReplaceableOreGen` and *ignore* the predicate
GT passes in - so `StoneType.computeStoneType` returned the first registered stone type (GT's
`stone`, id 0) before our `moon_stone`/`mars_stone`/`venus_stone` were ever consulted. The addon
now ships three Mixins (`src/main/java/.../mixin/MixinBlockBasic*.java`, listed in
`mixins.minespace.json`, discovered through the `MixinConfigs` manifest attribute exactly like
AsmodeusCore and Galaxy Space) that inject at the head of `isReplaceableOreGen` and only turn a
"yes" into a "no": Galacticraft's own variant list is preserved, the stone type's predicate is
now also required. They compile against the Mixin that MixinBooter ships (`compileOnly`), so no
second Mixin is bundled.

Measured on a dedicated server, reading the placed blocks back out of the world:

```
dim=-28 (Moon)      ore_chalcopyrite_1@moon_stone  ore_tin_1@moon_stone  ore_pitchblende_1@moon_stone
dim=-29 (Mars)      ore_sulfur_1@mars_stone  ore_pyrite_1@mars_stone  ore_magnetite_1@mars_stone
dim=-31 (Asteroids) ore_redstone_1@venus_stone  ore_ruby_1@venus_stone   (the pack's "venus" set)
dim=-1007 (Ceres)   ore_brown_limonite_1@ceres_stone  ore_banded_iron_1@ceres_stone
dim=0    (Overworld) unchanged: @stone, @granite, @diorite, @andesite, @bedrock
```

One more gap turned up while verifying: **GC's Venus provider fires no `PopulateChunkEvent`**, so
neither the height priming nor the generator call ever happened there. `MinespacePlanetOreGen`
now queues chunks from `ChunkEvent.Load` and, two seconds later, drives GregTech's generator
directly for dimensions that never registered a populate hook (Venus, and Galaxy Space's bodies
when their provider skips the events). The overworld is untouched.

## Vanilla worldgen: what is switched off now (2026-10-11)

Measured on a fresh world, 144 overworld chunks, y 鈮?90, before the change:

| What | Before | After |
| --- | --- | --- |
| `minecraft:coal_ore` | 22370 | **0** |
| `minecraft:iron_ore` | 13581 | **0** |
| `minecraft:redstone_ore` | 3596 | **0** |
| `minecraft:gold_ore` / `diamond_ore` / `lapis_ore` | 1234 / 402 / 484 | **0** |
| vanilla stone variants (granite/diorite/andesite) | ~78000-97000 | **~2200** |
| GregTech ore blocks (control) | 30k-35k | **unchanged** |

The overworld's own vein set is GregTech's (the GTCE-TJ assets, the 44 files under
`config/gregtech/worldgen/overworld/`, pinned to `dimension_id:0`); the pack's older GTCEu-era
overworld set (copper_tin, garnet_tin, mineral_sand, lubricant, raw_oil_sphere, ...) is still
parked and is not loaded. Measured in the *player's* own save (a copy of `saves/鏂扮殑涓栫晫`,
289 chunks around spawn, y 鈮?120): **83827 GregTech ore blocks, 147 ore variants, 27 of 36 vein
cells populated, 84 surface-vein rock markers** - spread as y 0-20: 12153, 20-40: 19026,
40-60: 39991, 60-80: 12657, and nothing above 80, because GregTech caps a vein at the local
terrain height. In other words: the overworld does have veins, they are simply all underground
(and the vanilla ores that used to be near the surface are now gone on purpose).

* **The vanilla ores** are GregTech's own documented switch:
  `config/gregtech.cfg` -> `B:disableVanillaOres=true`.

* **The other mods' ores** (2026-10-13, TJ-MIGRATION-PLAN.md 6bl): Galaxy Space's
  `config/GalaxySpace/world.conf` has `enableOresGeneration=false` / `enableOverworldOres=false` /
  `enableMarsNewOres=false`; Galacticraft's `core.cfg` disables copper / tin / aluminium / silicon on
  the overworld and cheese / tin / copper / sapphire on the Moon, and `planets.cfg` disables every Mars
  (iron, copper, tin, desh), Asteroids (iron, aluminium, ilmenite) and Venus (aluminium, copper, galena,
  quartz, silicon, tin, solar) list. Forestry's `common.cfg` had `copper=true` and `tin=true` - the last
  duplicate copper and tin ore in the world, next to GregTech's own - and both are switched off now
  (all three were duplicate ore next to GregTech's own veins, and the apatite switch was the one that
  needed GregTech's vein proved first - see TJ-MIGRATION-PLAN.md 6bn: `overworld\apatite_vein.json` is
  in the registry at weight 60 and its `ore:apatite` filler resolves through
  `OreConfigUtils.getOreStateMap` -> `getOreForMaterial` -> `MetaBlocks.ORES`, i.e.
  `gregtech:ore_apatite_*` and never the ore dictionary, and the certus quartz vein covers the Moon,
  Mars, Venus and the fourteen Galaxy Space bodies the same way). Measured after the change: a nine-chunk spawn census of a fresh overworld holds
  no Forestry and no vanilla ore, only an AE2 meteorite's quartz ore and one Galacticraft oil spring,
  both kept on purpose.
* **The granite/diorite/andesite patches are not an ore-gen switch at all.** For this Forge build
  nothing in the mapped Minecraft/Forge jar references `OreGenEvent.GenerateMinable` (a temporary
  listener received exactly zero events while the blobs were being placed), and Gregicality's
  `StoneGenEvents` only rewrites the *lava-meets-water* stone (`FluidPlaceBlockEvent`), which it
  did 8 times in a whole run. The blobs come from `BiomeDecorator.graniteGen`/`dioriteGen`/
  `andesiteGen`, read by `BiomeDecorator.generateOres` - and patching the *registered* biomes is
  not enough, because a world decorates with its `BiomeProvider`'s biome instances. The addon now
  replaces those three generators with a no-op at `DecorateBiomeEvent.Pre`, for every biome the
  chunk's provider reports, plus at init, at world load and on Forge's `CreateDecorator`. The
  lava-to-variant flavour is put back to plain cobblestone (vanilla's outcome) at
  `EventPriority.LOWEST`.
* `config/minespace.cfg` -> `S:disabledVanillaGenerators` lists what is switched off (default
  `GRANITE, DIORITE, ANDESITE`). `DIRT`, `GRAVEL` and the overworld ores can be added there too;
  emerald and silverfish do not own a `BiomeDecorator` field in 1.12.2, so they are not offered.
  The ~2200 straight-stone-variant blocks that survive are the first decoration of biomes whose
  instance the provider builds after the patch - 0.1% of the stone in the sample, and no ore.

Side effect worth knowing: because GT bakes one `BlockOre` per 16 stone type ids, each ore
material now has 3 ore blocks instead of 1, so the creative search tab / JEI lists up to 35 stone
variants per ore (GT's own 14 plus our 21). That is GTCE's normal multi-variant layout, only
bigger.

**Removed 2026-10-09: Interstellar: Exoplanets (`exoplanets`, `Interstellar-Exoplanets-1.12.2-0.1.3.0.jar`).**
Its ores register their own furnace recipes, which collide with GTCEu's - the log fills with
`Tried to register duplicate Furnace Recipe` for every `exoplanets:*` ore - and nothing else in
the set depends on it. Its config folder and the `planets.txt` dump it wrote are gone with it.
To bring it back: Modrinth `interstellar-exoplanets`, file
`https://cdn.modrinth.com/data/xVzIiQ35/versions/iMRGd06Y/Interstellar-Exoplanets-1.12.2-0.1.3.0.jar`
(needs AsmodeusCore, which is still installed for Galaxy Space).

**Added 2026-10-09: Gregicality Multiblocks (`gcym`) and GregTech Food Option
(`gregtechfoodoption`).** Both are the newest 1.12.2 releases, and the chain is version-locked to
the installed GTCEu: GCYM 1.2.11 wants `required-after:gregtech@[2.8.10-beta,)` (exactly this
build) plus CodeChickenLib, GTFO 1.12.8 wants `@[2.8.0-beta,)` plus MixinBooter. Verified by
launching the dedicated server: `Forge Mod Loader has successfully loaded 28 mods`,
`Done (5.404s)!`, with `[gcym] Registering blocks/Items/recipes` and GTFO's early+late mixins and
recipe registrations in the log.

**Epimorphism Core (`epimorphism`) was installed with them and removed again the same day: it
does not run on GTCEu 2.8.10-beta.** `EPMaterialPropertyAddition.init` calls
`Materials.Iodine.setProperty(PropertyKey.FLUID, new FluidProperty())`, an *empty* fluid property
that 2.8.10-beta's `FluidProperty.verifyProperty` rejects - `IllegalStateException: FluidProperty
cannot be empty`, thrown out of GTCEu's `MaterialEvent` dispatch (which is why the crash report
reads `Caught exception from GregTech (gregtech)`). Its mixins are *not* the problem: they apply
cleanly and their GTCEu targets exist. Sharpened 2026-10-11: **no public GTCEu release can run
it.** It also calls the 2.8.9+ material/fluid API (against 2.8.8-beta it is missing 16 classes -
`FluidTypes`, `FluidType`, `MetaFluids`, `Recipe$ChanceEntry`, ...), while 2.8.9/2.8.10 reject its
empty `FluidProperty`. It was written against the Epimorphism pack's own GTCEu build, not a
release; treat it as unusable outside that pack. Parked rather than deleted - the jar is in
`%TEMP%\minespace-removed\2026-10-09-epimorphism\`.

**Investigated and rejected 2026-10-09: Gregicality Science (`gcys`).** It exists, but only as one
2022 prototype: `GregTechCEu/gregicality-science` is archived (last commit 2022-09-29) and its
single release, v0.0.1-alpha (2022-08-12), ships three jars - the mod, a patched GCYM 1.1.4, and
**its own forked GTCEu** (`gregtech-1.12.2-2.4.0-gcys-alpha.jar`). Its `@Mod` string asks for
`required-after:gregtech@[2.4.0-gcys-alpha,)`, and 6 of the GTCEu classes it compiles against no
longer exist in 2.8.10-beta (`FluidTypes`, `GregTechAPI$MaterialEvent`, `IntCircuitRecipeBuilder`,
`GTSounds`, `MetaTileEntityAdjustableTransformer`), so it cannot load here - a config cannot fix
removed API. It is not on Modrinth and has no CurseForge project; github.com is unreachable from
this network, so the jar was pulled through `release-assets.githubusercontent.com`.
Its niche (post-UV tiers, optical/spintronic circuits, pressure/vacuum systems, advanced
chemistry) is partly served by GCYM + GTFO. **Serendustry** (`serendustry` 0.0.4, 2024-02-02,
Modrinth) is the closest live 1.12.2 addon for that endgame content and is class-compatible with
2.8.10-beta (0 of 92 GTCEu references missing) - see the Serendustry note below, its own page
calls it unstable.

**Tried and parked 2026-10-11: Serendustry (`serendustry` 0.0.4, 2024-02-02).** Installed, and it
hit the same wall - `SerendustryMaterials$Companion.registerMaterials(SerendustryMaterials.kt:290)`
sets an empty `FluidProperty`, which 2.8.10-beta rejects. The GTCEu versions were then bisected:
`FluidProperty.verifyProperty` is a no-op in 2.8.6/2.8.7/2.8.8-beta and only throws from
**2.8.9-beta** onwards. That one fact explains this whole family - Serendustry, Epimorphism Core
and GCYS were all written before the check and need GTCEu <= 2.8.8.
Against 2.8.8-beta the rest of the set survives intact (GTFO 1.12.8, this addon's 0.2.0 jar and
Serendustry itself all have 0 missing GTCEu classes), but GCYM has to drop to **1.2.7**: its 1.2.9
release is literally "Compat for GTCEu 2.8.9" (the dynamic DT-hatch API) and its bound is
`[2.8.9-beta,)`, 1.2.11's is `[2.8.10-beta,)`. GCYM gregtech bounds by version, read out of the
jars: 1.2.1-1.2.2 -> 2.6.0, 1.2.3 -> 2.6.2, 1.2.4-1.2.5 -> 2.7.0, 1.2.6-1.2.7 -> 2.8.0,
1.2.9-1.2.10 -> 2.8.9, 1.2.11 -> 2.8.10 (1.2.8 exists only on CurseForge, not Modrinth).
So the "GTCEu 2.8.8-beta + GCYM 1.2.7 + GTFO 1.12.8 + Serendustry" combination is the one that
would work if that content is ever wanted; it costs GTCEu's 2.8.9/2.8.10 fixes and GCYM
1.2.8-1.2.11. Parked at `%TEMP%\minespace-removed\2026-10-11-serendustry\`; the pack was
re-verified after the revert (`successfully loaded 28 mods`, `Done (1.317s)!`).

**Chosen 2026-10-11: keep GTCEu 2.8.10-beta and add SussyPatches 1.1.0 instead of taking the
Serendustry downgrade.** The 2.8.8 route above does work, but its only payoff is an alpha addon,
so the "stable builds only" rule settles it: SussyPatches is the one 1.12.2 GTCEu addon that
ships `release`-typed builds, its bound is exactly `required-after:gregtech@[2.8.10-beta,)` and it
has 0 missing GTCEu classes - a stable addon that needs no GTCEu/GCYM change at all. Verified on
the dedicated server: 30 mods load, 23 of its mixins apply, and one tweak fails -
`tweak/mixins.prospectorheight` (the GT terminal prospector map's height) reports
`@Shadow field texture was not located in WidgetProspectingMap`; the config is optional, so that
is a warning and the tweak is skipped. 21 further mixins are client-only and only load with the
client.
One real side effect, worth knowing before the next launch: its
`bugfix/mixins.invalidregistration` mixin (`registerPipeBlocksOnlyWhenNeeded`) stops GTCEu from
registering pipe/cable/wire blocks for pipe types with no enabled materials, so a save written
before the fix reports those entries as missing - FML prints `There are 50 missing entries in this
save ... the missing entries will get removed`, writes a world backup and waits for
`/fml confirm`. A/B tested: without SussyPatches the prompt does not appear. The 50 entries are
all `minespace:*` pipe/cable/wire block+item registrations, i.e. exactly the empty ones the fix
exists to drop.
ConfigAnytime 3.0 rides along because SussyPatches logs `ConfigAnytime not found! Configurations
may not work!` without it (5 KB coremod library, no dependencies, release-typed).

The UI mods (JEI, The One Probe, XaeroLib, Xaero's Minimap + World Map) come from
**Modrinth**, not CurseForge 鈥?the API is key-free, so they are not listed by numeric file id
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

Load order is stated in the files, not spelled with file names: every script opens with a `#priority`
line and CraftTweaker runs the **higher number first** (`oredict.zs` 900, the Galacticraft / Galaxy
Space removals 850-845, the pack's own passes 800-793 and 700-696, the AE2 / high-tech / PlanetProgression
passes 600-596). Before this the order was carried by rows of `z` prefixes in the names - the same order,
unreadable. See TJ-MIGRATION-PLAN.md 6ay.

| Script | Does |
| --- | --- |
| `scripts/own_machines.zs` | recipes for the machines this addon registers itself (the GregTech Oxygen Compressor `gregtech:machine:32000` and the Rocket Fuel Loader `:32001`). Their `ModularUI` screens live in the same addon classes (`MetaTileEntityOxygenCompressor` / `MetaTileEntityRocketFuelLoader`): title, one slot, one tank, player inventory - and, since 2026-10-14, GregTech's own `INDICATOR_NO_ENERGY` plate as the energy feedback, because this fork ships no proportional energy bar (TJ-MIGRATION-PLAN.md 6cg) |
| `scripts/oredict.zs` | must load FIRST: the ore dictionary unification. It (1) takes Galacticraft's compressed plates and Galaxy Space's cobalt / nickel plates out of the plain `plateX` names, so `plateCopper` etc. mean the GregTech plate - before this a two-plate compressed plate and a single plain one were interchangeable; (2) drops the mods' *unobtainable* leftovers (their metal blocks, Galacticraft's titanium dust) from the shared names; (3) unifies every `ingot*` / `dust*` name that held both a GregTech item and another mod's item on the GregTech item - Forestry's copper / tin / bronze ingots, Ender IO's and AE2's powders and dusts, Galacticraft's and Galaxy Space's remaining ingots and dusts (2972 names GregTech-only, 0 still sharing); and (4) closes the last spelling gap: Galacticraft's American `plateAluminum` / `blockAluminum` / `dustAluminum` now hold the GregTech items, so both spellings of each name answer with the same item, while its compressed plate stays reachable under its own `compressedAluminum`. `plateCoal` / `plateMagnesium` were deliberately left until 2026-10-14 and are now emptied as well (TJ-MIGRATION-PLAN.md 6cd): GregTech has no coal plate and no magnesium plate at all, so unlike the fourteen plates above those two names simply end up empty - Galaxy Space's compressed coal / magnesium plate is reachable by item id only - and the three recipes that read them are handled in the same commit (the two Galaxy Space decorative blocks are rebuilt by item id in `gs_removals.zs`, and Ender IO's powdered coal, whose `<ore:plateCoal>` recipe was an accidental pairing with Galaxy Space's compressed plate, is replaced by a one-to-one bridge from GregTech's coal dust; note that CraftTweaker's `recipes.remove(output, ingredient)` does not filter by ingredient, so that one line removes every powdered-coal recipe and the bridge is what re-establishes a source); and (5) discards the silicon that Galacticraft, Ender IO and AE2 each ship under the shared name `itemSilicon` - the three foreign items come out, GregTech's silicon ingot goes in, the items are hidden from JEI, AE2's smelting recipe for its own silicon is deleted, and Ender IO's sand-to-silicon SAG mill recipe is switched off in `config/enderio/recipes/user/user_recipes.xml` (the three SAG mill recipes whose *main* output is something else now yield GregTech's silicon as a byproduct). See TJ-MIGRATION-PLAN.md 6i, 6j, 6l and 6y. Since 2026-10-12 it also puts the charged and the pure grown certus crystal back into `crystalCertusQuartz`, and since 2026-10-13 GregTech's own certus quartz gem as well (appended, so AE2's plain crystal stays the first entry) - GregTech's certus quartz has its own vein (TJ-MIGRATION-PLAN.md 6bn) and produced a gem nothing in AE2 would take (6bo): AE2's own recipes reference an item tag that holds all three crystals while only the plain one carried the ore name, and the rewritten storage components and ME cores address certus quartz by that name, so a player whose only certus crystal came out of the growth chamber could not have made them (TJ-MIGRATION-PLAN.md 6y). Since 2026-10-13 it also hands GregTech the **gear** names: `gearCopper` / `gearTin` / `gearBronze` answered with Forestry's gear and `gearWood` with AE2's (then Ender IO's), which left GregTech's own gear items with no producer at all while the extruder / alloy smelter / fluid solidifier lanes were making the mod's copies, so the three gears and both wooden ones come out of the names and five entries in `MinespaceMaterialRepoint.sharedNames()` move every recipe that produced or ate them onto GregTech's (TJ-MIGRATION-PLAN.md 6bk). Since 2026-10-13 it does the same for **ores and the mods' storage blocks** (TJ-MIGRATION-PLAN.md 6bl): 33 ore blocks (the Galacticraft and Galaxy Space ones, whose own ore generation is switched off in their configs, plus Forestry's copper and tin ore) and four Forestry blocks (copper / tin / bronze / charcoal storage) leave their names, on the rule that an **unobtainable** mod copy is handed over while an obtainable copy of the same material (Forestry's apatite, AE2's meteorite quartz ore) stays. GregTech's own ore processing is untouched by it: its macerator / chemical bath / forge hammer lanes take an ore-name ingredient listing every entry of the name. The dead furnace lanes that went with them (`ore block -> one ingot`) are removed by `MinespaceMaterialRepoint.pruneDeadSmelting`, a new pass beside `repointSmelting` that deletes any furnace entry whose input this table has handed over - 44 recipes on its latest run, 0 on the second. The last four names went over in the same day's follow-up (TJ-MIGRATION-PLAN.md 6bn): `oreApatite` / `gemApatite` / `blockApatite` and `oreCertusQuartz`, once a probe had proved GregTech's own apatite and certus quartz veins place GregTech's own ore blocks - the shared-name sweep now reports **`other-first=0`**, i.e. every name GregTech and another mod both fill answers with GregTech's item, except `oreChargedCertusQuartz` which only AE2 fills. AE2's quartz ore is deliberately not in the re-point table: its meteorite ore is still obtainable, so the furnace pruner must not be pointed at it |
| `scripts/gs_removals.zs` | the same treatment for Galaxy Space: its generators, its Modern Energy Cluster, the six machines that duplicate a GregTech one, its own cobalt / magnesium / nickel ingot-block-nugget set, and - at the end - the 23 machines whose grids used a shared `plateX` ore dictionary name and are rebuilt against the compressed plate they always meant (machine frames, liquid extractor, hydroponic base, modification table, jetpack, space-suit parts, advanced / modern battery, rocket modules, decorative blocks, gs_basic parts), plus the matching JEI hides. The 2026-10-12 pass rebuilt Galaxy Space's Heavy Duty Plates: disassembling the 2.2.0 jar shows its five NASA-workbench part recipes run `for (i = 0; i <= 3; i++)` and build the part from `new ItemStack(HDP, 1, i)`, so `hdp:3` was a real blocker for the fourth rocket and is now made in the LV-MV assembler from the previous tier, desh, GT stainless steel and dolomite; `hdp:4..7`, which Galaxy Space never defined a recipe for, are filled in as this pack's own escalating ladder (HV / EV / IV / LuV) and can be deleted without breaking a mod recipe (TJ-MIGRATION-PLAN.md 6aa) |
| `config/enderio/recipes/user/user_recipes.xml` | the Ender IO recipes that *cannot* be reached from a script, because Ender IO registers its XML recipes after CraftTweaker has run - the only lever is `<recipe name="..." disabled="true"/>` with the name attribute from `assets/enderio/config/recipes/*.xml`. Carries (a) the twelve alloy-smelter entries behind Ender IO's own ten alloys, superseded by the GregTech alloy smelter / mixer; (b) the SAG Mill's sand-to-`itemSilicon` recipe, deleted with the three mods' silicon items; (c) the four five-stick `GEAR_WOOD` recipes, which resolve to AE2's wooden gear and would bypass the saw-and-file recipe; (d) since 2026-10-12 all 203 ore recipes from `sagmill_ores.xml`, because the SAG Mill turned any `ore*` entry straight into finished powder while GregTech's chain for that ore is macerator -> ore washer -> thermal centrifuge -> smelting, and 87 more from the second pass - thirteen ore recipes the first pass missed (the eight `Poor X Ore` recipes live in `integration_railcraft_recipes.xml`, five gem ores in `sagmill_silentgems.xml`, and AE2's block and vanilla's nether quartz ore are addressed by item id rather than by an ore name), plus every ingot / block / gem recipe whose input a temporary probe proved is already an input of GregTech's macerator, forge hammer, centrifuge, extractor, compressor, mixer, alloy smelter, chemical bath or lathe (that probe dumped 28,674 recipes into `gtmap_probe.txt` and is deleted again); and (e) since 2026-10-13 the Ender IO machines and recipes that were handing out a pack material - the sixteen `alloying_modded.xml` entries that smelt GregTech's own steel / electrum / invar / bronze / constantan / signalum / lumium / enderium (and the four dust+sand "blends", and Manyullyn) in the mod's alloy smelter, the twenty SAG recipes that ground the pack's alloy ingots and storage blocks into GregTech dusts (`sagmill_metals.xml` and the four Thermal-Foundation entries in `sagmill_modded.xml`), and the two lapis recipes whose names carry no `Sagmill: ` prefix. The file is at **364 entries** now (326 before this pass; an earlier duplicate `Sagmill: Enderium Ingot` is what made Ender IO refuse to start until it was removed). Verified from Ender IO's own log with its debug output promoted: the pack's file accounts for one `Skipping XML recipe ... (disabled=true)` line per entry, none missing, alongside the 316 of Ender IO's own for recipes whose target mod is not installed. Kept on purpose: Ender IO's own alloys and crystals (no GregTech material to move them to), Forestry's apatite (Forestry is the exception), the mill's glowstone and nether-quartz-gem recipes (GregTech's macerator does not accept those inputs, so removing them would strand the powder), and the few vanilla items GregTech's maps do not accept (TJ-MIGRATION-PLAN.md 6l, 6y, 6ab, 6ac and 6az). Note: an XML comment may not contain a run of `--`, which is how the first version of this file was rejected by the XML parser |
| `scripts/assembler_2.zs` | the second half of the "an advanced machine comes out of a GregTech machine" rule, for the mods the first pass did not reach: **Galaxy Space** (hydroponic farm, energy pad, planet shield, oxygen storage module, gravitation module, machine frame), **PlanetProgression** (telescope, satellite module / launcher / controller / builder, advanced launch pad), **Galacticraft Planets** (Mars machine, beam reflector, short telepad, heavy nose cone) and **Galacticraft core** (rocket engine in both of its recipe forms, two cargo loaders, dish base, buggy material, sensor and frequency module, telemetry unit, battery) lose their crafting-table recipe and are made in the GT **assembler** - same materials, no count lowered, plus an integrated circuit, at LV 30 for Galacticraft core and MV 120 for the rest. It also restores **Galacticraft's Heavy-Duty Plate** (`galacticraftcore:heavy_plating`), which nothing in the pack produced any more: disassembling GC's own `RecipeManagerGC` shows it was a compressor recipe (2x compressed steel + 2x compressed aluminium + 2x compressed bronze -> 2 plates) and GC's compressor is deleted, so every rocket part that needs a plate was uncraftable; it is an assembler recipe now (TJ-MIGRATION-PLAN.md 6ad). It also carries Ender IO's liquid and item conduits (two tiers plus the core) and the second capacitor tier, which the owner asked to have look high-tech: assembler work now, MV 120, while the ME conduits stay as they are because one of their three recipes accepts any of the seventeen coloured AE2 cables in a slot the recipe dump prints truncated (TJ-MIGRATION-PLAN.md 6ae). The ingredient lists were read out of the live registry by a temporary probe, not guessed |
| `scripts/eio_materials.zs` | Ender IO's own materials as GregTech materials, and the crafting-table conversions that had to go with them. The addon registers eighteen metals - the ten alloys (`dark_steel`, `electrical_steel`, `energetic_alloy`, `vibrant_alloy`, `redstone_alloy`, `conductive_iron`, `pulsating_iron`, `soularium`, `end_steel`, `construction_alloy`), the seven "endergy" alloys (`crude_steel`, `crystalline_alloy`, `melodic_alloy`, `stellar_alloy`, `crystalline_pink_slime`, `energetic_silver`, `vivid_alloy`) and Enderium Base (`enderium_base`) - as GregTech `IngotMaterial`s with only `SMELT_INTO_FLUID` set, which gives an ingot, a nugget, a block, a dust and a molten fluid and nothing else. `oredict.zs` hands the `ingotX` / `nuggetX` / `blockX` names to GregTech's items and `MinespaceMaterialRepoint` re-points the machine outputs, machine inputs and crafting inputs that used to hand out or eat the mod's copies. What this script owns is the one thing Java cannot reach - a crafting-table **output**, because `IRecipe#getRecipeOutput()` is computed rather than stored. Ender IO auto-generated three conversions per alloy (`9 ingots -> block`, `block -> 9 ingots`, `9 nuggets -> 1 ingot`); all three are the compressor's or the decompressor's job, so they are **removed rather than rebuilt** - which is what makes the crafting table stop compressing at all (TJ-MIGRATION-PLAN.md 6bc). The `1 ingot -> 9 nuggets` conversion used to stay, on the theory that the mod casts its grinding balls from its own nuggets, but 6bh retracts that: the ball recipes the mod actually ships are the crafting-table ones, five ingots into twenty-four balls, so the nugget producers are removed as well and the items are hidden. Enderium Base's own production recipe is ported to GregTech's mixer in `integration.zs`, and no recipe is written here for the ingot -> dust step - Gregicality already generates it (see 6ba). History: 6ae and 6az built this file as a set of block / nugget *rebuilds*; 6ba added the endergy seven and Enderium Base; 6bc turned the rebuilds into removals once the machine routes existed (TJ-MIGRATION-PLAN.md 6ae, 6az, 6ba, 6bb and 6bc). It also carries the seven endergy **grinding balls**: their recipes are the Endergy addon's (`endergy_balls.xml`), five ingots in a cross on the crafting table into 24 balls - the same shape the ten alloys use - because the addon's casting forms want Tinkers Construct, which this pack does not have (TJ-MIGRATION-PLAN.md 6bd) |
| `scripts/eio_upgrades.zs` | Ender IO's dark steel upgrades. The **blank** upgrade was made in Ender IO's own alloy smelter (its `<alloying>` entry "Dark Steel Upgrade": dark iron bars + clay + 4 string) - that entry is switched off by name in `config/enderio/recipes/user/user_recipes.xml` and rebuilt in the GT assembler, which is also the machine that fits, since three inputs is over the alloy smelter's two-input limit. The **45 variants** (blank + one or two parts -> an upgrade carrying an NBT tag) were crafting-table recipes and are assembler recipes now, the tag written with `.withTag({ "enderio:dsu": "..." })`. Since 2026-10-13 the **four Solar upgrades** are deliberately absent: each one is built from an Ender IO solar panel, which `integration.zs` removes and hides as a generator, so all four recipes were dead; their NBT variants are hidden next to the panels instead (TJ-MIGRATION-PLAN.md 6bj). Both the tag values and the ingredient lists come from Ender IO's own `darksteel_upgrades*.xml`, joined to the live registry by EIO's slugified recipe names. Alternative lists are written back as the ore name they came from (`GEAR_WOOD` -> `<ore:gearWood>`, chests -> `<ore:chestWood>`), never as the first member. Verified with the temporary worklist probe: zero `dark_steel_upgrade` crafting recipes left, and the no-GT worklist down to 1024 (TJ-MIGRATION-PLAN.md 6af) |
| `scripts/gc_tools.zs` | Galacticraft's heavy-duty steel tools and armour - axe (both shapes), sword, pickaxe, shovel, hoe, helmet, chestplate, leggings, boots, the steel pole, the standard wrench, the advanced landing pad and the two buggy wheels. Each keeps its own shape and its output, and two things change: Galacticraft's compressed steel plate (`basic_item:9`) becomes GregTech's **dense steel plate** (nine steel plates against the compressed one's two, so strictly dearer - never easier), and the empty grid slots take the GregTech tools the object needs (file + hard hammer for blades, hard hammer for armour plates, saw for the pole, wrench/screwdriver for the machine parts). Galacticraft's *machines* that use the same plate are deliberately left alone: that plate is GregTech-made already, and nine dense plates per slot for a machine housing is a different balance call (TJ-MIGRATION-PLAN.md 6ag) |
| `scripts/gcp_tools.zs` | Galacticraft-Planets' titanium and desh tools and armour - titanium axe (both shapes), sword, pickaxe, shovel, hoe, helmet, chestplate, leggings, boots, and the same nine in desh. Titanium moves from Galacticraft's compressed titanium plate to GregTech's **dense titanium plate** (nine titanium plates against the compressed one's two, so strictly dearer); desh's three plain GregTech ingots become GregTech **desh plates**, one ingot each but off a bending machine; and both families take a file + hard hammer (or a hard hammer alone for armour) in the grid slots the pattern already leaves empty. Shapes and counts are Galacticraft-Planets' own. Verified: shaped-add count 211 -> 233, exactly the twenty-two recipes (TJ-MIGRATION-PLAN.md 6ah) |
| `scripts/forestry_wood.zs` | Forestry's whole wood family - planks, fences, slabs, stairs and its wood doors plus the six vanilla doors it adds - 315 recipes that each gain a GregTech **saw** in a slot the pattern already leaves empty, the GTNH way of cutting wood. Wildcard ingredients were written back as the ore name they came from (`plankWood`, `logWood`), never as the first member of the list. Generated from the live registry; two generator bugs (a nested `-notmatch` clobbering PowerShell's `$matches` so the ingredient list came back empty, and one-element tool lists being unwrapped to a string) were both caught by reading the generated script before running it (TJ-MIGRATION-PLAN.md 6ai) |
| `scripts/forestry_items.zs` | Forestry is no longer the pack's exception. The workbench items that belong to the machines and the apiary - grafter (file + hard hammer), scoop (saw), pulsating mesh (GregTech steel screw + screwdriver), worktable and the tree / bee / butterfly chests (screwdriver), habitat locator (screwdriver + LV circuit) and the four apiarist armour pieces (hard hammer) - keep their recipes, shapes and outputs and gain GregTech items. Left alone: the beekeeper bags, the frames and the genetic filter (full grids), the greenhouse/climatiser deconstruction and the farm-block flips. The *machine* half is covered by the addon itself: `MinespaceForestryTubes` (Java, permanent) rewrites every Thermionic Fabricator electron-tube recipe through Forestry's own `FabricatorRecipeManager`, putting a GregTech **fine wire** (matched to the tube's metal, copper where GT does not know it) and an **iron screw** into the two cells the 3x3 pattern already leaves empty - nothing dropped, no count lowered. ModTweaker could not do it: its fabricator API matches on the recipe's plan, and a probe of the live registry shows every tube recipe's plan is empty. The same probe (`MinespaceForestryProbe`, deleted again) dumped the machine recipe lists - 101 fabricator casts, 209 carpenter recipes, 25 centrifuge recipes. The Carpenter's own machine parts are covered too by `MinespaceForestryCarpenter` (Java, permanent): the four **chipsets** get a GregTech **plate** in place of their metal ingot and a **steel screw** in place of one of their eight redstone (their grids are full, so nothing can be added; a redstone is nearly free, so this only makes them dearer), and the **scented paneling** gains a steel screw in one of its two empty cells. Note the trap: rebuilding the recipe through `ShapedRecipeCustom` fails three different ways in Forge's `CraftingHelper.parseShaped`, so the class edits the recipe's own ingredient list in place instead. Two more things the 2026-10-13 machine audit settled (TJ-MIGRATION-PLAN.md 6bq): the cell it writes is a `NonNullList<ItemStack>` inside Forestry's own `ShapedRecipeCustom.input` - the list the Carpenter's `checkMatch` actually reads - so writing a Forge `Ingredient` there leaves a cell of the wrong type, and the rewrite now writes the stack itself; and it replaces the **cell object** instead of clearing it, because Forestry shares cell objects between recipes (the four chipsets share their redstone cells) and an in-place edit changes every recipe using that cell. A third pass, `removeLavaSqueezing`, removes the Squeezer's four phosphor-plus-sand lava recipes (TJ-MIGRATION-PLAN.md 6br): 1,600-2,000 mB of lava for two phosphor and a stone block is free EU once a GregTech lava generator is attached, which is the 6m line for RF applied to lava. Everything else the Squeezer does - juice, seed oil, honey, ice, biomass - stays. The same class also carries `repointRetiredItems`, which re-points Carpenter recipes that hand out, or live on, an item this pack has given to GregTech - the crate pairs for tin / copper / bronze / apatite / ash and two "broken tool into ingots" recipes, nine in all - at GregTech's item, so a crate of tin is filled and opened with GregTech's tin and the retired copies are produced by nothing again. The Centrifuge (25 recipes) is deliberately left alone - its outputs are bee products separated from a comb, not manufactured (TJ-MIGRATION-PLAN.md 6ai, 6aj and 6ak) |
| `scripts/jei_dupes.zs` | the other half of "all materials come from GregTech": when the pack hands a shared ore name to GregTech's item it empties the mod's copy and deletes its production, but until now only the three silicons were hidden - so JEI showed the same material twice with only GregTech's copy craftable. This hides the items that both (a) were removed from a shared ore name by `oredict.zs` and (b) are produced by nothing in a full audit of the crafting registry, every GregTech recipe map and vanilla smelting: Ender IO's ten alloy ingots and seven powders, Forestry's copper/tin/bronze ingots, Galacticraft's four metal blocks, four ingots and meteoric iron, Galacticraft Planets' titanium/desh/lead blocks and titanium ingot and dust, Galaxy Space's three ingots, and the silicons - 39 of them, then **twenty-five more since 2026-10-13**: Ender IO's seven "endergy" ingots and its Enderium Base ingot, which lost their only producer when those metals became GregTech materials, and its seventeen alloy **blocks**, which left `blockX` the same day so that those names answer with GregTech's compressed block (85 hidden items in all - TJ-MIGRATION-PLAN.md 6ba, 6bb, 6bc, 6bh), the last four found by the reachability audit. Four more on 2026-10-13: Forestry's copper / tin / bronze gear and AE2's wooden gear, whose names went to GregTech and whose recipes now make GregTech's gears instead (Ender IO's wooden gear, the same item as AE2's, was already hidden here) - TJ-MIGRATION-PLAN.md 6bk. Then 39 more blocks the same day (TJ-MIGRATION-PLAN.md 6bl): the Galacticraft and Galaxy Space ore blocks and Forestry's copper / tin ore whose names went to GregTech, and Forestry's four storage blocks whose only producer was the compressor lane that now makes GregTech's compressed block. CraftTweaker reported no "Could not find any matching ingredients" line for any of them, so each was a real JEI entry. Three more the same evening (6bn): Forestry's apatite ore, gem and block, which lost their producer when GregTech's own apatite vein became the source and the gem lanes were re-pointed at GregTech's apatite. AE2's quartz ore stays visible - it still comes out of its meteorites. Kept visible on purpose: Ender IO's grinding balls, which the mod's own crafting recipes make from ingots. The items remain usable, they simply stop cluttering JEI (TJ-MIGRATION-PLAN.md 6al) | Ten more were added on 2026-10-14 by the display-name sweep (TJ-MIGRATION-PLAN.md 6ce) where the rule is the same shape but the producer is the neutral round trip instead of nothing: Galaxy Space's cobalt / nickel / magnesium blocks and nuggets, the empty state of its Ultimate Battery, Galacticraft-Planets' lead ingot, Galacticraft-IC2-Compat's aluminium dust, and Galacticraft's own Oxygen Compressor (its recipe is gone, this pack's GregTech-powered machine of the same name replaces it).
| `scripts/power.zs` | power balance, and the last script to load: removes the crafting recipes of the Gregicality `convert_forge` (**FE to EU**) converters **from EV upward** - 35 blocks, ids `gregtech:machine:2933..4104`, the *second* member of each (tier, amperage) pair - and hides them from JEI, while **ULV / LV / MV / HV keep theirs** and the **EU-to-FE** family is untouched at every tier. The ceiling is the point: RF can run the early and middle tiers, a little easier than building GregTech's own generation, but from EV on the pack is GregTech-generated power only. The family labels were corrected on 2026-10-15 (TJ-MIGRATION-PLAN.md 6cl): the names are written from the *input* side, so the machine called "GTEU Energy Converter" is the **EU-to-FE** one (its own tooltip reads "Converts GTEU to FE") and "Forge Energy Converter" is the **FE-to-EU** one - the first version of this file had the ceiling on the GTEU family, which removed the safe direction above HV and left the arbitrage one craftable at every tier, and stopped at id 4099 so the UXV pair (4101..4104) was never in it either. Which ids carry a recipe was measured against the crafting registry on 2026-10-13 (6bp), and which id belongs to which family on 2026-10-15 (6cl). The same probe confirmed every Gregicality multiblock controller is craftable, including the EBF (`machine:2534`), the Vacuum Freezer (`2535`) and the Implosion Compressor (`2536`). The machines themselves were left as Gregicality prices them - each is its own tier's machine hull plus eight tier cables plus that tier's circuit - so the ceiling, not a re-cost, is what balances it - that is GregTech power being spent on Forestry / Ender IO / Galacticraft / Galaxy Space / AE2 machines. Paired with `config/gtadditions.cfg`, where "Disable GregTech EU to FE Energy Converters?" was switched from true to false (the safe direction was the one switched off and the arbitrage direction was the one on - the booleans gate whether a converter works, not whether it is registered) and "EU/FE Ratio" stays 4.0, deliberately not punitive (GTNH publishes 1 EU = 3.6 RF). See TJ-MIGRATION-PLAN.md 6m / 6cl |

| `scripts/top_tier_completion.zs` | the top end, completed. **The UXV tier**: 56 recipes (46 single-block UXV machines, the 8 sized UXV energy hatches, the 2 UXV converters) need `gregtech:machine:3243`, the UXV Machine Hull, and that hull had no recipe anywhere because Gregicality's own hull registration (`ga_hull_ulv` .. `ga_hull_umv`) stops one tier short. The owner's call on 2026-10-15 was that UXV and MAX must both be playable, so this file writes it - `plateNeutronium` x3 over `cableGtQuadrupleNeutronium / ga_machine_casing:4 / cableGtQuadrupleNeutronium`, the mod's own hull shape with the tier's own circuit, cable and casing (measured from the UXV machine recipes) - **and the casing that recipe asks for, which is the second thing Gregicality left out of the tier**: `ga_machine_casing:0` (UHV) and `:3` (UMV) each have a table recipe (that tier's plate, eight around a hammer) while `:4` (UXV) has none, so the pack would otherwise have shipped a hull nobody could build. Every other part of the chain was followed to its producer in the finished registries: plate by hammer / bender / assembler, cables by assembler and by table doubling, the UXV circuit in the Assembly Line, the reinforced glass in the fluid solidifier. Only the two table forms are mirrored, not the assembler variants the lower tiers also have. The tier's two base energy hatches are written here as well: they were the last items above UV that JEI offered with no recipe at all. And the top tiers' routes are settled here (6cr): the hull and casing above UV are **assembler** recipes and nothing else - the four Gregicality hulls (3239..3242), the four tier casings, the fusion casing and `ga_armor:8` lost their crafting-table recipes, and this file's own UXV hull and casing are assembler recipes in the tiers' own shapes (two tier cables over the tier casing; eight tier plates plus a programmed circuit), all at EUt 16 / 50 ticks, measured table=0 machine=1. **The UHV..UXV battery buffers and chargers** (25 machines, TJ-MIGRATION-PLAN.md 6cp): Gregicality registers four buffer sizes and one charger per tier for UHV..UXV and nothing produced any of them, so this file writes all 25 in GT's own shape (`battery_buffer_max_1x1`: cable / chestWood / cable over cable / hull / cable, the charger adding a row of that tier's circuits), with the tier's own material - UHV TungstenTitaniumCarbide, UEV Pikyonium, UIV Cinobite, UMV NaquadariaticTaranium, UXV Neutronium - and that tier's converter circuit. Verified by 25 `Adding shaped recipe` lines and zero CraftTweaker errors, which is also the check that every ore dictionary name resolved. Nothing above UV is producer-less any more. MAX itself is settled in 6cq: there is no MAX voltage tier in this stack (the table ends at UXV, tier 13, and GT's "MAX"-labelled machines run at tier 9), so the top tier's processing machines are Gregicality's UXV set - all obtainable now - and a MAX-named parallel set was tried and dropped as a duplicate of it. |

The **config side** of the same balance thread was audited on 2026-10-15 (TJ-MIGRATION-PLAN.md 6ck),
switch by switch, against the parked GTCEu `config/gregtech/gregtech.cfg` and - where a switch no
longer exists in this fork - against GTCEu's own bytecode. Every GTCEu-era decision is now either the
same switch with the same value (no vanilla ores, `energyUsageMultiplier=100`, the iron/paper/bucket
crafting rules, GTCE-style overclocking, dungeon loot), a rule this fork bakes in, a rule the pack's
scripts reproduce, or a written-down divergence (high-tier solar off, which is the owner's later power
rule; the wood saw pass; this fork's vein density). One was rebuilt from scratch:
`removeSmeltingForEBFMetals` is GTCEu's "remove the vanilla-furnace lane for ingots that need the
electric blast furnace", this fork has no switch for it, and the lanes were still there - so
`MinespaceMaterialRepoint.pruneEbfMetalSmelting` removes them, five in all (steel, tungsten, osmium,
damascus steel, black steel: the metals this fork gates). The other 238 dust-to-ingot lanes belong to
materials it deliberately does not gate and stay. Two stale config files from mods this stack no
longer has (`gcym.cfg`, `sussypatches.cfg`) were moved to
`%TEMP%\minespace-removed\2026-10-15-stale-configs\`.
| `scripts/integration.zs` | the four mods added on top of the stack - Forestry, Ender IO, Storage Drawers and Iron Chests - rebuilt from GregTech plates / screws / circuits; Ender IO's generators removed, its conduits moved to the GT assembler, and its ten alloys added to the GT alloy smelter / mixer (the pack's own translations of `assets/enderio/config/recipes/alloying.xml`; the mod's originals are switched off in `config/enderio/recipes/user/user_recipes.xml`). Enderium Base was added on 2026-10-13 - the mod's `alloying_modded.xml` entry, 3 lead + platinum + 4 ender pearls into four ingots, ported to the **mixer** because three inputs is over the alloy smelter's two-input limit - once `MinespaceMaterials` had registered the metal (TJ-MIGRATION-PLAN.md 6ba). On 2026-10-13 the seven **endergy** alloys followed: their recipes are not in Ender IO at all, they are in the separate Ender IO - Endergy addon (`assets/enderio/config/recipes/endergy.xml`, read out of the addon jar), and six of them are ported here with the addon's own inputs and counts - Crystalline Alloy, Melodic Alloy and Vivid Alloy to the **alloy smelter** (two inputs), Crude Steel, Stellar Alloy and Energetic Silver to the **mixer** (three inputs). The addon's Crystalline Pink Slime needs Industrial Foregoing's pink slime ingot and its Combustive Metal is the addon's own item, so neither is ported (TJ-MIGRATION-PLAN.md 6bd). Since 2026-10-12 the advanced half of the two storage mods is *not* shaped here any more - the five Iron Chests tiers above iron and their upgrades, the five upper shulker-box tiers of all sixteen colours and the six higher storage upgrades and the four drawer machines all moved to `assembler_1.zs`, and the grids that used to sit here were deleted rather than removed later (CraftTweaker applies removals before additions, so a later `recipes.remove` cannot undo an add). Must stay BOM-free: ZenScript drops a whole file that starts with a UTF-8 BOM |
| `scripts/ae2_base.zs` | Applied Energistics 2 in three layers: the inscriber chain (printed logic / engineering circuits cost GregTech gold / diamond plates, press duplication a GregTech steel block - through AE2's own `mods.appliedenergistics2.Inscriber`, which plain `recipes.remove` cannot see); quartz glass, the storage housing and the three entry-level cells rebuilt with GregTech iron / glass plates; and the **sixteen ME machines plus the eight higher-capacity cells moved off the crafting table into the GregTech assembler** (LV / MV / HV by tier), so an assembler is a hard prerequisite for them. Since 2026-10-12 AE2's own silicon item is discarded and its printed-silicon inscriber recipe is rewritten against GregTech's silicon ingot. Nothing was made cheaper - see TJ-MIGRATION-PLAN.md 6g and 6l | Since 2026-10-12 AE2's **grinder** is gone as a machine of its own: `MinespaceGrinderToMacerator` (Java) moves the grinder recipes GregTech's macerator does not already cover into the GT macerator - same input, outputs and chances, AE2's `turns` as the duration - and empties the grinder through AE2's own `IGrinderRegistry.removeRecipe` (its `getRecipes()` view is unmodifiable). 443 recipes cleared, 10 unique ones converted, and those then get GregTech's dusts as outputs thanks to the material re-point (TJ-MIGRATION-PLAN.md 6t). The Inscriber was audited through AE2's own registry on 2026-10-13 (TJ-MIGRATION-PLAN.md 6bq): its 13 recipes make the three processors from the matching *printed circuit* plus the press (`material:17/18/20` cost a GregTech diamond plate, gold plate and silicon ingot respectively) and the presses themselves from a **GregTech steel block**, so the AE2 line starts in GregTech's metal and silicon - no recipe hands out a GregTech item, none is dead, and the grinder holds 0 recipes (6t). The 2026-10-12 batch 4 finishes AE2: the two ME cores, the quantum link chamber, the crystal growth accelerator (its iron is now four GT iron plates) and the semi-dark monitor move off the crafting table into the GT assembler, the fluid storage components 1k / 4k / 16k get the same GT-screw treatment the 64k part got, and the stairs, slabs, quartz blocks, sky stone chests and the hand grindstone's gear and crank keep their recipes and gain GT saw / hard hammer / file / screwdriver. The shapes were read out of AE2's own recipe JSONs rather than the probe, because the probe cannot tell a 2x1 recipe from a 1x2 one and AE2 has one of each (`chiseled_quartz_block` is "aa", `quartz_pillar` is "a","a"). Ender IO's four five-stick `GEAR_WOOD` recipes - which resolve to this same AE2 wooden gear and are registered after CraftTweaker runs - are switched off by name in `config/enderio/recipes/user/user_recipes.xml` (TJ-MIGRATION-PLAN.md 6y). Batch 5 finishes AE2: the four cable families (fluix glass, smart, dense covered, dense smart) are the last plain recipes, and they could not be removed by output because each shares its output with a "wash the colour off" recipe. `recipes.removeShapeless(output, ingredients)` matches one specific shapeless recipe - CraftTweaker 1.12 handles AE2's `ShapelessOreRecipe` - and it logs one `Removing 1 Shapeless recipes.` per call, which is how the four rewrites were verified; a glass cable is cut with a GT wire cutter and the two smart cables also take an LV circuit (TJ-MIGRATION-PLAN.md 6z). Since 2026-10-13 the hand grindstone's wooden gear recipe (four sticks, a saw and a file) outputs **GregTech's** wooden gear instead of AE2's: `gearWood` belongs to GregTech now, and GregTech itself ships no recipe for its wooden gear because its gear generator only writes the machine lanes for an `IngotMaterial` and there is no wooden double plate for the crafting lane (TJ-MIGRATION-PLAN.md 6bk).
| `scripts/assembler_1.zs` | The "advanced items must come out of a GregTech machine" pass. Ender IO's 57 machine blocks, Forestry's 26 machines, 23 AE2 items and AE2's bus / panel / emitter, card and wireless families lose their crafting-table recipe entirely and are made in the GT **assembler** instead (LV / MV / HV / EV by the mod's own tier or by AE2 capacity), with an integrated circuit added and every original material and count preserved - 115 outputs and 168 assembler recipes in this file (185 across it and `ae2_base.zs`; TJ-MIGRATION-PLAN.md 6h). The 2026-10-12 second half covers Iron Chests and Storage Drawers: a further 105 outputs (the chest tiers and upgrades above iron, the five upper tiers of all sixteen shulker boxes, the six higher shulker upgrades, and the compacting drawer, controller, slave, framing table and the 2x-16x storage upgrades) and 153 further recipes - LV / MV / HV by metal and tier (TJ-MIGRATION-PLAN.md 6k). The three Forestry engines - the pack's last non-GregTech generators - were re-costed here too: MV 128 EU/t out of GregTech steel plates for the two fuelled ones and HV 480 for the fuel-free clockwork engine, where all three used to be LV 30 (TJ-MIGRATION-PLAN.md 6m). Loads last so its `recipes.remove` runs after the other scripts - but note that CraftTweaker applies removals before additions, so the crafted versions had to be deleted from `integration.zs` / `ae2_base.zs` rather than removed here. A top-level CraftTweaker `val` is **file-local**, so this file carries no aliases from the integration script; use literal ingredients. Added 2026-10-13: Ender IO's four **gears** (`item_material:11/12/13/73` - the Infinity, Energized, Vibrant and Dark bimetal gears) leave the crafting table and become assembler recipes at the same materials and counts, one tier up each rung with an integrated circuit, because they are machine components and every EIO machine block in this file is built from them. The stone compound gear (`item_material:10`) stays on the table: cobblestone, sticks and a wooden gear is LV work. Ender IO's gears stay Ender IO's - GregTech has no counterpart for a bimetal gear and no gear at all for the alloys they are coated in (TJ-MIGRATION-PLAN.md 6bk) |
| `scripts/gc_removals.zs` | takes Galacticraft's own industry away: its material processing machines, its power blocks and its duplicate materials (ingots, compressed plates, storage blocks, and since 2026-10-14 its wafers, which are now engraved out of GregTech's own wafers in GregTech's laser engraver - and, since 2026-10-12, its aluminium / silicon blocks and its desh / titanium / lead ingots), with GregTech recipes standing in for each Since 2026-10-13 it also removes the smelting lane GregTech's own shard handler had written against Galacticraft's Iron Shard (`shardIron` is filled only by `galacticraftplanets:item_basic_asteroids:3`, which asteroid rock drops), so iron can no longer be smelted out of a mod item, and both shards are hidden from JEI - the smelting recipe was the only consumer either of them had. The titanium call is written too although it removes nothing today (CraftTweaker: "1 recipes removed for: `<minecraft:iron_ingot>`", "0 recipes removed for: `<ore:ingotTitanium>`"), so a mod update cannot put the lane back (TJ-MIGRATION-PLAN.md 6bj) |
| `scripts/gc_crafting.zs` | crafting-table removals and re-additions (launch pad, oxygen chain, air lock, solar-dust bridge) | Since 2026-10-12 **all four** Galacticraft aluminium wire recipes are GT **assembler** recipes at LV and none are left on the crafting table: `wire:0` = 3 GregTech **fine aluminium wire** + 6 wool (x6 out), `wire:1` = GT aluminium ingot + `wire:0` + wool, `wire:2` = `wire:0` + repeater, `wire:3` = `wire:1` + repeater. The item itself stays, because 19 Galacticraft recipes use the wire as a material for the life-support and logistics machines this pack keeps, and Galaxy Space has no wires of its own (TJ-MIGRATION-PLAN.md 6n).
| `scripts/gc_machines.zs` | GregTech **machine** recipes that existed per-machine in the source: canner (canned food), bender (canisters), assembler (glowstone torch) |
| `scripts/gc_processing.zs` | the ore-to-metal chain (macerator for desh / meteoric iron / titanium, implosion compressor for Galacticraft's compressed plates, blast furnace for titanium) plus the fluid bridges that replace its Refinery and Oxygen Collector (distillery: crude oil 鈫?rocket fuel, gas collector: air 鈫?oxygen) | Since 2026-10-12 the Gregicality-generated "free" producers of Galacticraft's compressed plates (69 recipes: 67 across metal_bender / alloy_smelter / forge_hammer / extruder / cutting_saw / fluid_solidifier - a bender turning one steel ingot into a compressed steel plate, a cutting saw turning one steel block into nine - plus 2 in vanilla smelting, where a magnetic steel / iron plate turned into the compressed plate, a registry that is not one of GregTech's recipe maps and is what JEI shows in its own Smelting tab). The `implosion_compressor` and `electric_implosion` maps are deliberately kept: the first holds the pack's own plateX x2 + TNT route, the second is the Electric Implosion Compressor, a UV multiblock built in GregTech's Assembly Line (491,520 EU/t over 48,000 ticks) whose no-TNT two-plates-per-plate recipes are its whole purpose - Gregicality registers those "reverse engineered" multiblock recipes after CraftTweaker (config `gtadditions.cfg`: "Reverse recipes after CT"=true), which is why no script can see them (TJ-MIGRATION-PLAN.md 6o) are **re-pointed at GregTech's own plain plate** by `src/main/java/com/minespace/unofficial/gtceu/MinespaceCompressedPlateGuard.java` (87 recipes and 2 smelting entries since 2026-10-13: 67 of them are GT's own plate recipes that OreDictUnifier had mis-pointed at the mod's compressed item, and deleting them had left `plateCopper`, `plateTin`, `plateSteel`, `plateBronze`, `plateIron`, `plateDesh`, `plateTitanium`, `plateCobalt` and `plateNickel` with no source at all - see TJ-MIGRATION-PLAN.md 6bj), called from the addon's postInit (and again at FMLLoadCompleteEvent). Anything the guard cannot re-point is deleted, so the implosion compressor stays the only route to a compressed plate, and Galaxy Space's cobalt / nickel plate stay the pack's own two-ingot compressor recipes (`KEPT_RECIPES` in the guard). The crafting-table half of the same hijack is `scripts/plate_bridge.zs`, because those recipes are mod-registered Forge recipes. Java rather than a script because CraftTweaker exposes no removal method for a GregTech machine map and Gregicality registers those late (TJ-MIGRATION-PLAN.md 6o, 6bj).

| `scripts/gear_bridge.zs` | the crafting-table half of the gear hijack (TJ-MIGRATION-PLAN.md 6bk). `gearCopper` / `gearTin` / `gearBronze` answered with **Forestry's** gear and `gearWood` with **AE2's**, because Gregicality writes its gear recipes through `OreDictUnifier.get(OrePrefix.gear, material)`, so GregTech's own four gear items had no producer at all (a live probe counted 0 against 4 for `gearIron`) and the extruder / alloy smelter / fluid solidifier lanes were making the mod's copies. `oredict.zs` hands the names to GregTech, `MinespaceMaterialRepoint` re-points the lanes, and this file writes GregTech's own crafting shape back for copper, tin and bronze - four sticks at the corners, four plates at the edges and a wrench in the middle, copied from the surviving `gtadditions:gear_iron`. The wooden gear needs no line here: GregTech itself ships no recipe for `gearWood` (its gear generator only writes the machine lanes for an `IngotMaterial`, and the crafting lane wants double plates, of which there is no wooden one), so `ae2_base.zs`'s saw-and-file recipe now outputs GregTech's wooden gear instead of AE2's. |
| `scripts/plate_bridge.zs` | the crafting-table half of the plate hijack behind TJ-MIGRATION-PLAN.md 6bj. Galacticraft / Galaxy Space register their compressed plates under GregTech's plain `plateX` names, and Gregicality's generator wrote both the ingredient and the *output* of its plate recipes through `OreDictUnifier.get(OrePrefix.plate, material)`, which answered with the mod's item - so the crafting table's own plate recipe (`plate_x` / `flatten_plate_x`, a hard hammer over two ingots) handed out the two-plate compressed tier for two ingots and a hammer, and the machine half of the same recipes was what `MinespaceCompressedPlateGuard` had been deleting, leaving nine GregTech plates unbuildable. This file (a) removes the nine compressed plates from the crafting table - all of them, so the implosion compressor is the only route - and (b) writes GregTech's own plate shape back for each of the nine (`<ore:craftingToolHardHammer>` over two GregTech ingots in a column, the same shape and cost `gtadditions:plate_aluminium` uses for a metal that was never hijacked). The nine are copper, tin, steel, bronze, iron, desh, titanium, cobalt and nickel; measured afterwards each has its ten machine-plus-crafting producers. |
| `scripts/gaps.zs` | the chains that lost an ingredient to this pack's machine removals, loading last so its `recipes.add*` survives every removal script. Carries: the compressed meteoric iron the Air Lock Frame needs (implosion compressor, two plates plus TNT, the same shape as the other compressed plates); the one-to-one desh and lead ingot bridges that keep Galacticraft's own desh armour, arc lamp, atmospheric valve, Mars machine block and atomic battery buildable once the mod's ingots leave the crafting grid; and the one-to-one **certus quartz bridge** added 2026-10-13 (TJ-MIGRATION-PLAN.md 6bo) - GT gem <-> AE2 certus quartz crystal, both directions - because AE2's crystal is its own form of the material that its charger, its inscriber and this pack's AE2 assembler recipes address by item id, while GregTech's certus quartz now comes out of GregTech's own vein; the Astro Miner Base (MV circuit in place of the removed Energy Storage Module); Galaxy Space's Rocket Assembly (HV circuits and the compressed titanium plate in place of the three removed machines); and - added 2026-10-13, both read out of the mods' own source - Galaxy Space's **Modern Wafer** (`gs_basic:5`, Galaxy Space's third rung of Galacticraft's wafer ladder, which lived in the Circuit Fabricator this pack clears, as `2x ingotSilicon + 4x circuitAdvanced` in the assembler, and since 2026-10-14 they are instead engraved in GregTech's **laser engraver** out of GregTech's own wafers with GregTech's own gem lenses - the top rung of the rebuilt wafer ladder `gc_removals.zs` writes for Galacticraft's (see TJ-MIGRATION-PLAN.md 6cb)) the two **magnesium decorative blocks** (`galaxyspace:decoblocks:1` and `:5`, rebuilt 2026-10-14 against the compressed magnesium plate by item id, next to their cobalt / nickel / copper siblings), and Galacticraft's **Mars Heavy-Duty Plate** (`item_basic_mars:3`, `1x heavy_plating + 1x compressed meteoric iron`, which Galacticraft's `RecipeManagerMars` made in its Compressor - in the assembler rather than the compressor, because GTCE-TJ's compressor map takes exactly one item input). See TJ-MIGRATION-PLAN.md 6bj. |

The replacement of Galacticraft's machines, machine by machine - what is done, what is still
missing and what each remaining one needs - is tracked in `GC-GREGFICATION-PLAN.md`.

The machine recipes of `assembler_2.zs` were silent no-ops until 2026-10-12: an assembler
accepts at most **nine** inputs and an integrated circuit set with `.circuit(n)` is one of them, so
every one of those lists written from a 3x3 grid as nine separate stacks plus a circuit was rejected
with `Invalid amount of recipe inputs. Actual: 10. Should be between 1 and 9 inclusive` in
`logs/latest.log`, never entered the map, and left 24 machines of Galaxy Space, PlanetProgression,
Galacticraft and Galacticraft Planets uncraftable (plus one Ender IO dark steel upgrade in
`eio_upgrades.zs`). CraftTweaker's own log says nothing about it. Repeated slots are
folded into a count now, the launch pad hands out its own nine pads per craft again, and
PlanetProgression's communication dish keycard moved off the crafting table into the same assembler.
See TJ-MIGRATION-PLAN.md 6am - and keep the rule: inputs + circuit <= 9.

Since 2026-10-12 the crafting table is no longer allowed to be the compressor.
`src/main/java/com/minespace/unofficial/gtceu/MinespaceCraftingBlocks.java` (called from
`FMLLoadCompleteEvent`) deletes Gregicality's `block_compress_<material>` / `block_decompress_<material>`
recipes and Ender IO's `auto_<material>_9_ingots_to_1_block` / `auto_<material>_1_block_to_9_ingots`
pairs - **1058 of the 1074** - but only when a GregTech machine map already makes the same item, which
is what keeps Ender IO's seven endergy alloys, Galaxy Space's sulphur dust and Forestry's ash (16
entries, printed in the log on every launch) on the table. The same class then deletes **128** machine
recipes that could no longer be run at all, because one of their ingredients could only be satisfied by
a mod item `oredict.zs` had already emptied and stopped producing (AE2's silicon among
them). Together with `ae2_base.zs`, where AE2's own quartz and fluix blocks moved off the
crafting table onto the packer and the compressor, this closes the "ingots straight into a block"
family the owner pointed at. See TJ-MIGRATION-PLAN.md 6an.

Two more passes followed the same day, both from the owner's reports. **Machines have no slots, so they
have no order**: `MinespaceRecipeDedupe` (Java, `FMLLoadCompleteEvent`) merges machine recipes that only
differ by the order of the same materials - a crafting grid is order-sensitive and a machine's input
bus is not, so Galacticraft's beam reflector (lever in either of two cells) and its rocket engine
(flint and steel swapped with the stone button) each existed twice in the assembler. 217 recipes across
thirteen maps are merged into one each, matching on the sorted ingredient list plus counts, fluids in
and out, items out and chanced outputs; duration and EU/t are ignored because the map serves its first
match either way, and a visible recipe always wins over a hidden twin. **`hightech.zs`**
then moves the last 36 machines, machine frames, rocket parts and electronic components still sitting
on the crafting table into the assembler - Galacticraft's air fan / distributor / oxygen detector /
spin thruster / display screen / chromatic applicator / NASA workbench (LV 30), its Planets' Mars
machine and miner base, Galaxy Space's two lower machine frames, liquid extractor, hydroponic base,
modification table, radiation stabiliser, rocket assembler, first rocket module and two upgrades, and
AE2's spatial + storage + fluid components, ME storage housing, blank pattern, three entry-level cells
and crafting accelerator (MV 120 above the 1k tier) - while the low-tech families (cables and dyeing,
paint balls, quartz glass, decorative cuts, wood, stone, food, Galacticraft's hydraulic platform and
air lock frame) stay on the table. See TJ-MIGRATION-PLAN.md 6ao - and remember that nine materials
already fill the assembler's nine inputs, so that one recipe (the chromatic applicator) carries no
circuit.

**Amendment, 2026-10-14 (TJ-MIGRATION-PLAN.md 6ch):** two of the machines named in that list are no
longer in the game at all. The **Chromatic Applicator** (which turned out to be
`galacticraftcore:machine3:0`, not `:9` - that number is only its lang-file index) and the **Astro
Miner Base** (`galacticraftplanets:miner_base`; `miner_base_full` is the docked state's lang key, not
a second item) were the two rows of `GC-GREGFICATION-PLAN.md`'s "Still to do" table whose plan column
was already a verb - "Cosmetic; delete" and "GregTech's ore/fluid drilling plants replace the job" -
and the owner approved carrying them out. Their assembler/crafting recipes in `hightech.zs` and
`gaps.zs` are gone, the items are hidden from JEI and the miner's `galacticraft.astroMiner` category
is hidden with them. Side effect on the baseline: `machine-only enforcement` now reports **12**
entries instead of 13, because the miner base was one of them and it no longer has a crafting recipe
to delete.

The same sweep then closed the rest of that table's "decide" rows (TJ-MIGRATION-PLAN.md 6ci), after a
probe printed each candidate's producers and consumers: **deleted** the **Energy Beam Reflector**
(`galacticraftplanets:beam_reflector:0` - an orphan, since the solar array's controller, module and
receiver were already gone, and its rebuilt recipe in `assembler_2.zs` went with it) and the **Laser
Turret** (`galacticraftplanets:laser_turret` - a combat toy, and already uncraftable before the
change). **Kept** everything else, each with its own live recipe or by design: the Oxygen Detector
(consumed by Galacticraft's own Sealer), the Launch Controller and Landing Pad and Parachest (rocket
logistics), the Terraformer and Cryogenic Chamber (the environment devices the owner wants kept), the
Short Range Telepad, the View Screen / Telemetry / Spin Thruster, and the Space Station Base. Three
ids in that table turned out to be lang-file indices rather than metadata (the applicator, the Launch
Controller and the Cryogenic Chamber) - Galacticraft encodes some machine blocks as type x 4 + tier,
so the `tile.<block>.<n>.name` lines never line up with it; the corrected table now says "measured
registry item".

One launch-side note, from the same day: the client once died with `EXCEPTION_ACCESS_VIOLATION` inside
`versions/1.12.2-forge-14.23.5.2859/natives/OpenAL64.dll` before reaching the main menu - the OpenAL
Soft 1.15.1 that LWJGL 2.9.3 ships crashing while opening the audio device, which is also why the
dedicated server (no audio) was unaffected. `alsoft.ini` in this folder now asks OpenAL for the plain
Windows waveOut backend and `Play-Minespace.ps1` passes it in through `ALSOFT_CONF`. If that ever
faults again, `drivers = null` runs the game with sound off, and replacing `OpenAL64.dll` with OpenAL
Soft 1.23.1 or newer is the proper fix. See TJ-MIGRATION-PLAN.md 6ap.

And one behaviour worth knowing before editing any script here: **CraftTweaker applies every
`recipes.remove` before any `recipes.add`**, so a later script's removal cannot take away a recipe an
earlier script re-added - and a mod that registers its crafting recipe after CraftTweaker's pass puts it
back regardless. That is why `MinespaceCraftingBlocks.removeLeftoverCraftingRecipes`
(`FMLLoadCompleteEvent`) exists: it deletes, and logs by name, any crafting-table recipe still standing
for an item on `src/main/resources/minespace_machine_only.txt` (every item the scripts give a machine
recipe, minus Galacticraft's two canisters and its glowstone torch, where the machine recipe is a bonus
route). The first run found 35 - twenty-nine of this pack's own earlier rewrites (`ct_shaped...`) and
six of Gregicality's late compressed-plate shortcuts. Regenerate that list from the scripts whenever a
machine recipe is added; the one-liner is in TJ-MIGRATION-PLAN.md 6aq.

**The whole AE2 line now starts at MV.** Every AE2 assembler recipe the pack writes is 120 EU/t or
above (80 at MV, 9 at HV, 1 at EV - the 64k crafting storage), so an LV assembler cannot touch any of
it; and `MinespaceCraftingBlocks.removeSubMvAe2BlockRecipes` deletes the one LV door that no script
owned, Gregicality's 4 EU/t packer mirror of AE2's own 2x2 quartz / fluix block recipe, with the MV
replacements written in `ae2_base.zs`. Deliberately below MV: AE2's material pre-processing in
GregTech's ordinary ore machines (LV, like every other material), AE2's own AE-powered machine recipes
(their gate is the machine recipe), and the cables / paint balls / quartz glass / decorative cuts on the
crafting table. See TJ-MIGRATION-PLAN.md 6ar.

Where a table recipe and a machine recipe both existed, the machine route now always wins for the mods
this pack gregifies: `MinespaceCraftingBlocks.removeDuplicatedTableRoutes` (`FMLLoadCompleteEvent`)
deletes 54 of them - the ones the script-side passes could not see, because Gregicality mirrors a mod's
own crafting recipe onto a machine (AE2's dense covered cable), because the "nine identical things into
a block" recipes are named after the mod (Forestry's copper / tin / bronze / apatite / charcoal blocks,
Galaxy Space's block family) rather than after Gregicality, or because they are the nine vanilla
material blocks (iron, gold, diamond, emerald, coal, lapis, redstone, quartz, glowstone). Deliberately
kept: GregTech's and Gregicality's own namespaces, the four-small-dusts-into-a-dust convention, the
three Galacticraft items whose machine recipe is a bonus route, and every other vanilla recipe -
chests, crafting tables, panes, planks, leather, hay and friends stay as vanilla wrote them. See
TJ-MIGRATION-PLAN.md 6as.

A load-order trap that cost two rounds and is worth knowing: **JEI builds its recipe index in its own
`FMLLoadCompleteEvent` handler, and mod load-complete handlers run in mod-load order - JEI loads before
this addon.** A recipe deleted from the registry at load complete is therefore gone in game but still
listed by JEI (measured: JEI indexed at 21:38:44, the clean-ups ran at 21:38:50). The six clean-up
passes (`MinespaceCraftingBlocks`, `MinespaceRecipeDedupe`) now run from **postInit** as well, so JEI
sees the finished state, with the load-complete run left in place as a safety net that reports 0. See
TJ-MIGRATION-PLAN.md 6at.

**AE2's storage family is redesigned, not copied.** `ae2_storage.zs` owns all 25 of
them and every recipe says what the item is: a component is a chip (GT circuit + certus quartz + fine
wire, or a tiny pipe for the fluid ones), the housing is a card cage (aluminium plates, a quartz glass
window, steel screws, a circuit), a cell is a card in that cage, a blank pattern is a plastic plate with
an aluminium foil data layer, and the tier is legible from the recipe (basic -> good -> advanced
circuits, tin -> copper -> silver -> electrum wires). The old blocks - including the crafting-table
rewrites of the 1k cells that 6x had re-added, which is what the owner was seeing - were cut out of
`ae2_base.zs` and `hightech.zs`. AE2's machines get the same treatment next;
see TJ-MIGRATION-PLAN.md 6au.

**AE2's machines are rebuilt the GregTech way too.** An exporter (`MinespaceAe2Export`, temporary)
showed that every machine was AE2's own grid with GregTech iron plates pushed into the gaps - the ME
Drive was four iron plates, two processors and two cables. `ae2_machines.zs` now
builds the 29 machines and tools out of a **tier machine casing** (`machine_casing:2` = MV, `:3` = HV),
the **GregTech part that does the job** (motor, piston, conveyor, robot arm, emitter, sensor), **tier
circuits** and the **AE2 signature part** (quartz glass, fluix, a ME cable, a processor, sky stone): the
Inscriber is a casing with two pistons, the Security Station carries a sensor, the Spatial IO Port an
emitter, the Drive two motors and two ME cables, and the two cards are a plastic plate with a gold foil
layer. Nothing is cheaper, one recipe per machine (the Drive and the view cell each had two before), and
the AE2 parts family is the next batch. See TJ-MIGRATION-PLAN.md 6av.

**AE2's parts and cards followed** (`ae2_parts.zs`, 30 items). Everything that was a
crafting-table rewrite is assembler work now, built by what the device does: an import or export bus
carries a robot arm, a storage bus is a plate plus a ME cable plus a processor, a plane carries its core
and a piston, a level emitter carries a GregTech emitter, terminals and monitors are a quartz glass face
plus a chip, the interface parts carry an engineering processor, and the two base cards are a plastic
plate with a gold foil layer (the advanced one adding a diamond and a good circuit). The four
card-upgrades keep their shape because "a card with a chip added" reads correctly. The machine-only list
grew from 307 to 326 items, so every old table recipe behind these is removed before JEI looks. See
TJ-MIGRATION-PLAN.md 6aw.

**PlanetProgression was redone in the same idiom** (`planetprogression.zs`). Its seven craftable
items left the flattened-grid stage: the telescope is an aluminium frame and tube with motors, quartz
glass lenses, one diamond block as the mirror and a sensor behind the eyepiece (its first version carried
a machine casing, two diamond blocks and four compressed tin, which the owner rightly called unreasonable),
lenses, two motors for the mount and the compressed tin tube; the satellite builder is a casing with two
robot arms; the launcher carries two pistons; the controller has a quartz glass screen and a sensor; the
satellite module is a plate body with its wiring and wafers; the launch pad keeps its reinforced body
plus a circuit and still yields nine; and the keycard is finally a card - plastic, gold foil, the dish
link - instead of three iron blocks. One recipe per item, the research paper stays loot and the Basic
Satellite stays a Satellite Builder product. See TJ-MIGRATION-PLAN.md 6ax.

**Ender IO's own machines were then audited for routes around GregTech** (the owner's instruction:
*"the machines or recipes here that can be used to bypass GregTech must not be usable"*). Every
machine-recipe family in the mod's own XML was read against the pack's ore dictionary. Only two were
handing out a pack material, and both are closed by name in
`config/enderio/recipes/user/user_recipes.xml`: the **alloy smelter**, whose `alloying_modded.xml`
will happily make steel, electrum, invar, bronze, constantan, signalum, lumium or enderium (plus the
four dust-and-sand "blends") because it resolves the plain `ingotX` names that GregTech owns; and the
**SAG Mill**, whose remaining ingot / block -> dust recipes were quietly producing GregTech's dusts
once the mod's ten alloys became GregTech materials. The Vat, Tank, Enchanter, Soul Binder and Painter
are untouched - their outputs are Ender IO's own fluids, vanilla items and enchantments - and so is
`Sagmill: GlowStone`, because GregTech's macerator does not accept a glowstone block at all. One
material needed Java rather than a disabled name: `dustSoularium` had been holding Ender IO's own
powder first, which is why Gregicality's macerator and packer outputs were built against it, so
`oredict.zs` drops that powder from the name and `MinespaceMaterialRepoint` re-points those four
machine outputs (its machine count moves 905 -> 909). See TJ-MIGRATION-PLAN.md 6az.

**Then Ender IO's remaining ingots and fluids followed.** The owner's instruction: *"those
non-GregTech fluids can be registered as GregTech fluids, and the non-GregTech metal ingots have to be
registered on GregTech's side too - and every Ender IO ingot and Ender IO fluid, when it is a product,
must not produce a non-GregTech one."* Eight more metal items are now GregTech `IngotMaterial`s: the
seven "endergy" alloys (which the mod ships as ingot / nugget / block / ball but never gave a
production recipe) and Enderium Base (whose `alloying_modded.xml` entry 6az had switched off, ported
back to GregTech's **mixer** - 3 lead + platinum + 4 ender pearls into four ingots). The ten fluids
are the more interesting half, because GregTech builds its fluids in preInit and Ender IO registers
its own from Forge's **block registry event**, after every preInit: a GregTech fluid under those names
would win the name and break the mod's Vat and Tank. So the direction is inverted - the materials are
registered with `shouldGenerateFluid() == false` (a private `AdoptedFluidMaterial`), Ender IO registers
its fluids untouched, and `MinespaceEioFluids.adopt` runs from the addon's `init` and hands
`material.setMaterialFluid(...)` the fluid the mod actually made, plus a reflection insert into
GregTech's own `MetaFluids.fluidToMaterialMappings` so `getMaterialFromFluid` answers for it. One
fluid, GregTech's material, Ender IO's textures and buckets. `rocket_fuel` needed no adoption at all
- Gregicality already registers that material, so GregTech's fluid had been occupying the name all
along (and Ender IO's own registration of it had been quietly failing). Nine adopted, one already
GregTech's, and the postInit re-run finds nothing to do. Reading a GregTech `FluidMaterial` at all
also makes javac load CraftTweaker types out of its signatures, so `build.gradle` now adds the
instance's `CraftTweaker2-1.12-4.1.20.698.jar` as `compileOnly`, exactly like MixinBooter. See
TJ-MIGRATION-PLAN.md 6ba.

**Then the names, the tags and the recipes that had to follow.** The owner's follow-up: *"(1) the name
or the tag, and (2) mind that the related recipes have to be adapted."* A temporary probe over the
finished registries answered the first: the **tags** are GregTech's - every `ingot*`, `nugget*` and
`dust*` name the pack writes now holds GregTech's item and nothing else, with blocks deliberately still
listing Ender IO's block first and `ball*` being the mod's own grinding ball, both from the owner's
earlier "ingot / fluid / dust / nugget only" instruction - but the **names** were not. GregTech names a
material with `I18n.format("material." + <name>)` and ships 475 such keys for its own materials; every
material this pack registers had none, so the client showed the raw string (`material.dark_steel
Ingot`). `assets/minespace/lang/en_us.lang` and `zh_cn.lang` now carry the 32 missing keys. The second
point was the real work: Gregicality builds a lot of its recipes against whichever item was *first* in a
shared name at generation time (the mod's copy), so those recipes used to be deleted as unreachable.
`MinespaceMaterialRepoint.repointMachineInputs` re-points machine-recipe **inputs** instead - only when
every item an ingredient accepts is a unified mod item - which brought the `9 nuggets -> 1 ingot`
compressor route back for the whole alloy family and took the unreachable count **163 -> 0**. Then the
last two loose ends, on the owner's word: the **block** names were the one place a mod item was still
listed first, so Ender IO's seventeen alloy blocks left `blockX` (GregTech's compressed block is what
those names answer with, and Gregicality's machines that used to hand the mod block out were re-pointed
- machine outputs 973 -> 1058, machine inputs 164 -> 182), and the crafting table stopped compressing
at all: the three Ender IO conversions per alloy (`9 ingots -> block`, `block -> 9 ingots`, `9 nuggets
-> 1 ingot`) are removed rather than rebuilt, because GregTech has all three as machine work. Only `1
ingot -> 9 nuggets` stays, whose output is Ender IO's nugget - its grinding balls are cast from it. See
TJ-MIGRATION-PLAN.md 6bb and 6bc.

**And Ender IO's Alloy Smelter stopped being a three-slot furnace.** The owner's report: *"the alloy
smelter smelting GregTech ores is too cheaty"*. The alloying side was never the problem - Ender IO
gives the machine an *operating profile*, the default `AUTO` lets the player switch it to FURNACE, and
furnace mode wraps the **vanilla `FurnaceRecipes` map** (`VanillaSmeltingRecipe`), which in this pack
is the GregTech one, so any GT ore smelted into a GT ingot on RF power - with
`enderio.cfg`'s `alloy.createSyntheticRecipes` turning single-input recipes into 2- and 3-input batch
variants, i.e. three ores per operation. `config/enderio/enderiomachines.cfg` now sets
`S:profileNormal=ALLOY_ONLY`, `S:profileEnhancedAlloy=ALLOY_ONLY` and
`B:enableAlloySmelterFurnaceJEI=false`, and a deleted probe reading Ender IO's own enums confirmed
`furnaceRecipes=false` on both alloy smelters with their 77 alloy recipes untouched. Left as is: the
mod's dedicated **Simple Furnace**, which smelts one item at a time - a vanilla furnace on RF, which
this pack has always allowed. See TJ-MIGRATION-PLAN.md 6bf.

**Then a mechanical sweep of Ender IO's recipes** (the owner's *"check again which Ender IO recipes
bypass the GregTech line"*). `tools/audit-eio-bypass.ps1` walks every recipe in the mod's XML, resolves
each output through Ender IO's alias table, and classifies it against a **fresh** ore dictionary dump -
excluding the pack's own disables and every recipe Ender IO itself skips (its debug log). It found
**eleven recipes still handing out GregTech material**: the two extra Dark Steel entries in
`optional_tweaks.xml` (the last way the mod's alloy smelter could make one of this pack's metals, missed
by 6az's `alloying_modded.xml` list) and nine SAG Mill outputs (nether quartz dust, aluminium dust,
sulfur dust from blaze rods and from netherrack, certus quartz dust, silicon from clay, coal dust,
obsidian dust, wheat dust). All eleven are now in `config/enderio/recipes/user/user_recipes.xml`; every
one of those materials has plenty of GregTech producers of its own (checked against the full recipe-map
dump), and GregTech's macerator does take a nether quartz gem, wheat and vanilla obsidian, which is what
the earlier "kept" reasoning had missed. Ender IO's recipe log goes 680 -> **691** skipped recipes, the
audit 49 -> 38 live findings. What remains is 34 `smelting` entries that only Ender IO's Simple Furnace
can run (a vanilla furnace on RF), two dye recipes (`dyeRed` / `dyeYellow`, names GregTech also fills)
and two bone recipes (`dyeWhite` via bone meal, a vanilla crafting path) - all listed in
TJ-MIGRATION-PLAN.md 6bg for the owner to call. One earlier note is retracted there: the three
"alternate capacitor" items the Endergy addon's recipes name do **not** exist in this pack (no model, no
texture, no lang entry, and they appear in no recipe), so there is nothing to port or hide.

**Then the owner took the two recommendations: close Ender IO out, and build the reachability audit.**
Closed: the last two dye recipes (`Alloy: Red Dye`, `Sagmill: Yellow Flower`) plus the rest of that
family - `Alloy: Black Dye`, the four Brown and the four Green spellings, whose outputs are the mod's
own organic dyes sitting in `dyeBlack` / `dyeBrown` / `dyeGreen` beside GregTech's dye dusts, so the
three items left those names, the ten recipes are off and the items are hidden; the mod's seventeen
alloy **nuggets**, whose one remaining producer was `1 ingot -> 9 nuggets` and whose justification died
when 6bd showed the balls are made from ingots (so 6bc's retraction is recorded in the plan); and
**Crystalline Pink Slime now has a recipe** - `integration.zs` mixes pulsating powder with a slime ball
and pink dye, labelled in the script as a substitution for the Endergy addon's Industrial-Foregoing
recipe. Kept: the Simple Furnace (a vanilla furnace on RF) and the two bone recipes (bone into bone meal
is vanilla crafting). Then the audit: `MinespaceSourceProbe` (temporary, deleted) counted, for 240 items
the pack cares about, how many recipes produce them - crafting, GregTech machine recipes **including
chanced outputs**, and vanilla smelting. 126 had none; 85 are items the pack deliberately hides and 41
are Forestry tree blocks and leaves, which leaves the four real finds above. After the fixes the
invariant is exact: everything the audit reports is either hidden or a Forestry tree item. See
TJ-MIGRATION-PLAN.md 6bh.

**Then step three: the same audit across every other gregified mod.** A temporary probe walked the whole
crafting registry - every recipe whose namespace is not GregTech's, this addon's or CraftTweaker's - and
read back the mod machines the pack has already dealt with, through their own APIs. Result: **exactly
one** mod crafting recipe in the pack hands out a GregTech item, Ender IO's `Ender Dust` (nine of its
ender-pearl nuggets into one GregTech ender pearl dust), and it is not a bypass - EIO's own SAG mill
turns one GregTech dust into nine of those nuggets, so the pair is a 1:1 closed loop. **Zero** recipes
still produce a unified-away item. AE2's grinder 0, Galacticraft's compressor 0 (the run prints
*"Cleared 30 Galacticraft compressor recipes and 3 circuit fabricator recipes"*), AE2's inscriber 13
(the pack's own rewritten set), Forestry's fabricator/carpenter as their own rounds logged. The step
also found a gap in `tools/audit-eio-bypass.ps1` - it only saw EIO's *machine* recipes, which is how
`Ender Dust` survived four passes - and closed it: the tool now scans `<crafting>` too, covering all
**1896** of Ender IO's crafting recipes. See TJ-MIGRATION-PLAN.md 6bi.

KubeJS 1.12.2 only integrates with the vanilla crafting table and furnace (plus IC2's
machines and GameStages/PackMode) 鈥?it has no GregTech RecipeMap support at all, so machine
recipes must go through CraftTweaker, which is what GTCEu's `ct_integration` module targets.
GTCEu exposes its machines to CraftTweaker through the `<recipemap:鈥?` bracket handler, e.g.
`<recipemap:assembler>.recipeBuilder().inputs(鈥?.outputs(鈥?.duration(鈥?.EUt(鈥?.buildAndRegister();`.
CraftTweaker writes its own log to `crafttweaker.log` in this folder, which is the first place
to look when a script's item or ore-dictionary name is wrong.

Four CraftTweaker/GTCEu details cost a debugging round each and are worth knowing before
editing these scripts:

- **Outputs cannot be ore dictionary entries.** `inputs(鈥?` takes `IIngredient`, `outputs(鈥?`
  takes `IItemStack`, so a GregTech output has to be a concrete stack. The processing script
  pulls those out of the ore dictionary (`oreDict.get("dustDesh").firstItem`).
- **`IOreDictEntry` members are properties**, not the Java getters: `firstItem`, `items`,
  `empty`. `getFirstItem()` fails with "No such member".
- **GTCEu's circuit ore dictionary names are voltage tiers** (`circuitLv` 鈥?`circuitUhv`),
  and GT5's `circuitBasic` exists as a name whose entry is *empty*, which silently yields a
  recipe with a blank slot. Check with `empty`, not `contains`.
- **A machine map has its own input limit and the circuit counts against it.** The assembler takes at
  most nine inputs, `.circuit(n)` is one of them, and a recipe over the limit is dropped with an ERROR
  in `logs/latest.log` and nothing in `crafttweaker.log`. Fold repeats into counts (`<X> * 4`) or leave
  the circuit out; 25 assembler recipes were lost to this before it was found (TJ-MIGRATION-PLAN.md
  6am).

Note the one real dependency in the set: **both Xaero mods declare XaeroLib as a *required*
dependency** 鈥?it is not in their `mcmod.info` (which lists `"dependencies": []`), only in the
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
  1.12.2 鈥?but FML still requires the `micdoodlecore` mod id to be *registered*, which
  only happens when the jar loads through normal mod discovery. This is why the addon's
  `installMods` task copies jars into `run/mods` rather than putting them on the launch
  classpath; see `..\Minespace-unofficial\DEV-NOTES.md`, section 3.
- **GTCEu is a coremod** (`FMLCorePlugin: gregtech.asm.GregTechLoadingPlugin`) and must
  stay in `mods/`.
- **KubeJS 1.12.2 has no mod dependencies.** Its `mcmod.info` declares
  `"dependencies": []`. The Architectury/Rhino pair described in the modern KubeJS
  documentation applies to KubeJS 6 (1.16+), **not** to this 1.12.2 build 鈥?do not add
  them.
- **Load order:** the addon declares
  `required-after:codechickenlib; required-after:gregtech; after:galacticraftcore`, so it
  initialises after GTCEu (needed for material registration) but still loads when
  Galacticraft is absent.
- **The GTCEu addon chain is version-locked to 2.8.10-beta.** GCYM 1.2.11 asks for
  `required-after:gregtech@[2.8.10-beta,)` and GTFO 1.12.8 for `@[2.8.0-beta,)`; those two
  version bounds are the reason GTCEu cannot be moved on its own here. GTFO also declares
  `after:gcy_science` and `after:nutrition`, which are optional integration ordering hints -
  neither mod is installed and neither is required. GTFO is a coremod (`FMLCorePlugin` +
  early/late mixins) and relies on MixinBooter 11.17, the same jar Galaxy Space needs.
- **Anything that sets an empty `FluidProperty` fails on this GTCEu.** Epimorphism Core,
  Serendustry and the 2022 GCYS all do exactly that; the check landed in 2.8.9-beta
  (`verifyProperty` is still a no-op in 2.8.6-2.8.8). Such addons need GTCEu <= 2.8.8 plus GCYM
  1.2.7, which is a real downgrade - read the Serendustry note under the mod table before buying
  into it. When in doubt, check a candidate jar's GTCEu class references against the installed
  gregtech jar before dropping it in `mods/`.

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
| Planet Progression 0.4.8 | CurseForge file `4000252` | `PlanetProgression-1.12.2-0.4.8.jar` |
| MJRLegendsLib 1.2.1 | CurseForge file `3344068` | `MJRLegendsLib-1.12.2-1.2.1.jar` |

The GregTech addons added on 2026-10-09 are Modrinth-only as well:

| Mod | Source | Identifier |
| --- | --- | --- |
| Gregicality Multiblocks 1.2.11 | Modrinth `gregicality-multiblocks` | `https://cdn.modrinth.com/data/tZiutdLG/versions/MeXYT7nJ/GregicalityMultiblocks-1.2.11.jar` |
| GregTech Food Option 1.12.8 | Modrinth `gregtech-food-option` | `https://cdn.modrinth.com/data/RFOSc2Ey/versions/b625baJp/gregtechfoodoption-1.12.2-1.12.8.jar` |
| SussyPatches 1.1.0 | Modrinth `sussypatches` | `https://cdn.modrinth.com/data/34XRY2VK/versions/vS5Ze5yc/sussypatches-1.1.0.jar` |
| ConfigAnytime 3.0 | Modrinth `configanytime` | `https://cdn.modrinth.com/data/Bnsrfd1o/versions/Ha5RG6IC/%21configanytime-3.0.jar` (`%21` is the leading `!`) |
| Epimorphism Core 0.0.2-alpha (**not installed** - see the note under the mod table) | Modrinth `epcore` | `https://cdn.modrinth.com/data/jEYgJjpQ/versions/6CKl7Sdu/epimorphism-0.0.2-alpha.jar` |

Modrinth is key-free, so those seven can be re-fetched with
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

- **Fluids** 鈥?both define oil-like fluids. If you see a duplicate fluid id, check
  `config/gregtech/` and Galacticraft's config.
- **Ores** 鈥?both generate tin, copper and aluminium. Disable one side's generation, or
  accept the duplicates. Ore dictionary unification is the usual fix.
- **Recipe overlap** 鈥?GregTech overrides many vanilla recipes. Use the addon or KubeJS to
  remove a specific recipe.

- **A GregTech machine broken by another mod's worldgen used to crash the server** (2026-10-13,
  TJ-MIGRATION-PLAN.md 6bm). `MetaTileEntity.onRemoval()` ends in
  `MachineSoundManager.stop(getPos())`, and that class is client-only, so on a dedicated server any
  block placed *over* a GregTech machine - measured with Applied Energistics' meteorite crater
  generator (`MeteoritePlacer.placeCrater`) - threw
  `NoClassDefFoundError: gregtech/common/sound/MachineSoundManager` inside the tick loop, about
  thirty seconds after startup and with no player online. The addon now carries
  `com.minespace.unofficial.mixin.MixinMetaTileEntityOnRemoval` (listed in `mixins.minespace.json`),
  which cancels that base body on the physical server; MixinBooter prints
  `APPLY mixins.minespace.json:MixinMetaTileEntityOnRemoval ...` on every start. GregTech's **ores**
  are `BlockOre extends BlockFalling`, not MetaTileEntities, so ordinary mining was never affected.

**GTCEu config switches turned on in this instance** (`config/gregtech/gregtech.cfg`), each followed
by a dedicated-server boot with no new errors:

- `highTierContent=true` - without it GTCEu registers **no** >UV content at all; the log line
  `High-Tier is Disabled.` / `High-Tier is Enabled.` is the tell. With it, the UHV/UEV/UIV/UXV/OpV
  singleblock machines, their parts and casings exist. GTCEu's own comment warns that items
  enabled this way have no recipes - but the machine *crafting* recipes come from
  `CraftingComponent`, which is gated by the same flag, so they come back with it.
- content adds: `enableHighTierSolars`, `enableFEConverters`, `generateLowQualityGems`,
  `allUniqueStoneTypes` (the last one changes ore drops to per-stone-type ore items - the most
  visible of the four).
- the hard-recipe family, all on: `hardGlassRecipes`, `hardIronRecipes`, `hardAdvancedIronRecipes`,
  `hardDyeRecipes`, `hardMiscRecipes`, `hardRedstoneRecipes`, `hardToolArmorRecipes`,
  `hardWoodRecipes`, `harderBrickRecipes`, `harderCharcoalRecipe`, `harderCircuitRecipes`,
  `harderEBFControllerRecipe`, `harderRods`, `nerfWoodCrafting`, `removeVanillaBlockRecipes`.
  All six CraftTweaker scripts still load and apply cleanly with these on.
- deliberately left off: `doTerrainExplosion` (machines explode in rain / next to lava),
  `disableRubberTreeGeneration`, `disableConcreteInWorld` and `disableManualCompression` (these
  *remove* content), `cleanMultiblocks` (drops the cleanroom requirement), and the cosmetic
  `preventAnimatedCables` / `preventBlinkingTooltips` / `debug`.

## Reconciliation pass (TJ-MIGRATION-PLAN.md 6bs, 6bt and 6bu)

The rewrite of the four added mods was checked against a baseline rather than against the pack's own
logs, because a recipe that lost an ingredient still loads silently. The baseline is **each mod's own
shipped recipe**, read out of the jar: `ironchest-1.12.2-7.0.72.847.jar` (209 recipe JSONs) and
`StorageDrawers-1.12.2-5.5.3.jar` (JSON for the machines and upgrades, and the drawer family in code
- `core/ModBlocks$Registration`, whose `TemplateRecipe` rows are the literal `"xxx"` / `" y "` /
`"xxx"` rings). The three `Mods-Get-Gregged` variants disagree with each other and none is usable as
the baseline on its own: GTNH's scripts are 1.7.10 items this pack does not have, and two of the
three simply delete the Iron Chests upgrade items instead of re-costing them.

Four recipes were found cheap: `copper_silver` and `iron_gold`, for the chest upgrade and again for
the shulker upgrade, were four plates plus four screws where the mod's grid is a ring of **eight** of
the target metal, and a GregTech screw is an eighth of an ingot (`extruder: 1 ingot -> 8 bolts`,
`lathe: 1 bolt -> 1 screw`), so they asked for 4.5 ingots where the mod asks for 8. Four more had
drifted from the mod's counts: the 1x1 drawer and the framed 1x1 had lost two items from their rings
(6 against 8), the compacting drawer / controller / slave had 7 smooth stone where the mod's rows
hold 5, the controller and slave had the LV circuit *in place of* the central basic drawer, and the
framing table had 6 trims where the mod has 7. All are the mod's count with a GregTech ingredient
now, and nothing in either family is cheaper than its own recipe was.

Verified with a temporary probe (deleted) that dumped every crafting-table and GregTech map recipe
whose output belongs to Iron Chests, Storage Drawers, Forestry, Ender IO or Applied Energistics,
with the count on every input; the run afterwards reproduced the baseline (47 mods, zero
`crafttweaker.log` errors, zero `Invalid amount of recipe inputs`, zero `duplicate or conflict`, the
baseline two + two, seven grinding-ball recipes, no new crash reports).

Forestry needed a second baseline, because 1.12.2 Forestry registers its crafting recipes in code
and CraftTweaker has deleted them by load complete. A second temporary probe dumped the whole
crafting registry at `init` - Forge's `Register<IRecipe>` event runs between preInit and init, and
CraftTweaker only applies its scripts in postInit, so `init_all.txt` (19,369 recipes) is the mods'
own set - and again at load complete (`final_all.txt`, 19,232). Comparing the pair item by item
found two real defects in `scripts/forestry_wood.zs`, both invisible in every log the pack writes:
all **315** generated wood recipes had lost their output count, so a log made **one** plank instead
of four, three planks made one slab instead of six, and six planks made one stair, fence or door
instead of four or three (126 recipes down 4x, 120 down 3x, 63 down 6x); and because
`recipes.remove(<minecraft:x_door>)` deletes every recipe for the output while only Forestry's
fireproof-plank form was written back, the six plain vanilla doors had lost the ordinary
six-planks-into-three-doors route. Both are fixed - the counts are the mod's own again, read back
out of `init_all.txt`, and the six plain door recipes are restored - which is what this pack's own
vanilla wood already showed the intent to be: GregTech's hard-wood pass leaves `minecraft:planks:0`
at four per log and only adds the saw. Everything else the Forestry diff turned up is accounted for:
341 items whose ingredients changed are plain material -> GregTech material substitutions (planks ->
GT wood plate, glass -> GT glass plate, ingot -> GT plate) plus the tool the pattern needed, 40
outputs lost their crafting recipe on purpose with an assembler recipe standing in (25 machines and
alveary parts, the mod's copper / tin / bronze ingots and gears, and the bronze pickaxe / shovel /
kit / wrench the reference removes too), and 5 conversion routes ("unbuild a machine part" for the
electron tubes, and the manual <-> managed farm-block and peat-bog flips) are recorded as drops
because the generic "if a machine makes it, the table must not" rule removes them - none of them
produces power, a material or a shortcut.

Ender IO (1587 crafted + 147 machine recipes) and Applied Energistics 2 (206 + 111) are the next
items to read: AE2 appears in `init_all.txt` (its recipes are JSON), Ender IO does not (its XML is
loaded after CraftTweaker runs) and is read from `assets/enderio/config/recipes/*.xml` in the jar.

Both are now read, with the same four screens (route counts, output counts, ingredient multisets and
"does every removed recipe have a replacement"). Ender IO's baseline is the 945 `enderio:` crafting
outputs in the jar's own XML; AE2's is the 287 outputs in `init_all.txt`. Results: no EIO output at
load complete has an amount its XML does not declare, no AE2 output that kept a recipe lost a route
or an amount, and all 45 AE2 ingredient changes are additions (a GT tool in an empty slot, or a
vanilla iron ingot become a GT plate). AE2's 108 outputs that lost their crafting recipe are 107
machine recipes plus `material:40` (AE2's wooden gear, retired to GregTech and hidden on purpose);
Ender IO's 119 are 50 assembler recipes plus 68 that are accounted for one by one - 8 generators
removed, 50 alloy ingot/nugget/block items now GregTech's materials, 7 dark steel tools the reference
pack deletes too, and 2 that are the mod's own doing (`item_dark_steel_treetap`'s recipe names
`ic2:treetap, ic2:itemtreetap, techreborn:treetap` and is `required="false"`, so Ender IO skips it;
`item_broken_spawner`'s only recipe lives in the example file `broken_spawner.xml`, which has to be
copied into the `user` folder to activate). One more real defect turned up: **AE2's Quartz Fixture**,
which AE2 makes two of per craft, had been re-costed to one - fixed to `* 2` in `scripts/ae2_base.zs`.
Every AE2 and EIO item that moved into a machine keeps its own recipe's output amount (that is where
`block_omni_reservoir x4` out of the assembler comes from: EIO's XML says `amount="4"`).

That completes the reconciliation for the four added mods. The three defect families it found were
all the same shape - a rewrite that did not carry over what the mod's own recipe had - and all are
fixed: the four Iron Chests upgrades built from 4 plates plus 4 screws (a screw is an eighth of an
ingot, so they cost 4.5 ingots where the mod asked for 8), the drawer rings / drawer-machine stone /
framing-table trims, the 315 Forestry wood recipes that had lost their output count plus the six
vanilla doors' plain route, and AE2's quartz fixture.

## Play-test (TJ-MIGRATION-PLAN.md 6bv)

The player's half of the §6bj checklist was run on the dedicated server with a temporary harness
(deleted, along with a temporary `compileOnly` line in the dev project's build file that the harness
needed for Applied Energistics' interfaces). It waited for the spawn chunks, then censused the ores
that actually generated, broke one, placed the pack's machines as item blocks, ran a machine for real
and asked the checklist's recipes both of the machine maps and of the crafting registry.

Results: in three fresh worlds and about 7,000 ore blocks, every ore is GregTech's or AE2's - no
Galacticraft, Galaxy Space or Forestry ore block anywhere, which is 6bl/6bn confirmed in a generated
world rather than in a vein config. Fifteen machines (the eight steam machines, the electric furnace
at LV-MV-HV-EV and the macerator at LV-MV-HV) placed as items and each read back as exactly itself.
An LV macerator placed in that world, fed a GregTech copper ore and powered (1,024 EU, the LV tier)
produced `gregtech:meta_item_1:5018 x2` (crushed copper) in 400 ticks with its two chanced
byproducts, and a copper ingot produced copper dust in 30. The checklist's products were found where
they belong: plates / dusts / gears / steel plate in the machine maps, Galacticraft's compressed iron
plate in the implosion compressor (and the electric implosion), Mars Heavy-Duty Plate and Galaxy
Space's Modern Wafer and the Galacticraft wafers in the laser engraver (engraved out of GregTech's own
wafers - TJ-MIGRATION-PLAN.md 6cb), AE2's 1k storage component in the assembler from GregTech
screws; and on the crafting table, `circuitBasic`, the EBF / Vacuum Freezer / Implosion Compressor
controllers, the ULV and LV FE-to-EU converters (with EV and IV absent, as designed), Ender IO's
simplest chassis and Forestry's sturdy casing. AE2's logic processor is correctly *not* in a machine
map - the Inscriber makes it.

What still needs a human: GUIs, multiblocks with heat and structure, riding a rocket, bees and trees,
and the mods' own machine GUIs beyond the API audits in 6bq/6br. Verified afterwards: the harness and
the build-file line removed, jar rebuilt, and the clean run reproduced the baseline (47 mods, `Done`,
zero `crafttweaker.log` errors, zero `Invalid amount of recipe inputs`, zero `duplicate or conflict`,
the baseline two + two, seven grinding-ball recipes, no new crash reports, no report file left).

## Galacticraft recipes, second pass (TJ-MIGRATION-PLAN.md 6bw)

The owner's report - "some Galacticraft high-tech items are still too simple or make no sense, and
some assembler recipes don't merge identical items" - was three defects, all fixed:

* **14 assembler recipes listed the same item several times instead of one stack** (`assembler_2.zs`
  8, `eio_upgrades.zs` 4, `integration.zs` 1). A machine has no slots, so eight of an item is one
  stack of eight; the earlier "flatten the crafting grid" passes folded repeated slots in some files
  and not in these. The beam reflector and the rocket engine each also carried the mod's grid *and*
  its mirror image as two whole recipes - `MinespaceRecipeDedupe` already collapsed those at load
  complete, and the script now writes one.
* **Three statements were part of a comment** because a newline was missing after the comment above
  them: AE2's semi-dark monitor lost its 1:1 "panel into monitor" recipe (a real loss - the run's
  shapeless-add count went 16 -> 17 and the new one is `Illuminated Panel`), and the `recipes.remove`
  calls for AE2's `material:26` and Galacticraft-Planets' `mars_machine:4` never ran.
* **The Orion Drive** was still the mod's own crafting recipe: nine raw ores (diamond, lapis, gold,
  redstone, coal, moon rock, desh ore, ilmenite ore, asteroid plating) in a 3x3 grid for a
  nuclear-pulse propulsion unit. It is an **HV assembler** recipe now (800 ticks, 480 EU/t) built
  from the materials those ores produce - Uranium-235 dust x2 for the pulse units, a dense steel
  pusher plate, a titanium plate, a desh plate, ilmenite dust, a diamond plate, and the mod's own
  asteroid plating and moon block, which stay so the mod's chain still matters. The lapis and coal
  filler are replaced by the integrated circuit and the HV gate.

Verified with a temporary probe (deleted): none of the ten touched items has a crafting-table recipe
any more, each has exactly one machine recipe with folded inputs (quoted in the plan section), the
`Invalid amount of recipe inputs` count is 0 - which also proves every folded list still fits the
assembler's nine inputs - and the clean run reproduced the baseline (47 mods, `Done`,
`crafttweaker.log` errors 0, `Invalid amount of recipe inputs` 0, `duplicate or conflict` 0, the
baseline two + two, seven grinding-ball recipes, no new crash reports).

## Recipe hygiene guard (TJ-MIGRATION-PLAN.md 6bx)

`MinespaceRecipeHygiene`, called from `Minespace.loadComplete()` on every start, walks every GregTech
recipe map (70,210 recipes in 73 maps) and reports two mistakes: an ingredient listed more than once
where the counts would fit one stack (<= 64), and two inputs that can both accept the same item. It
never rewrites a recipe; it logs the counts and a per-map histogram, and writes the full list to
`recipe_hygiene.txt` when there is anything to report.

Deliberately not reported: duplicates that add up to more than 64 (GregTech writes 128 items as `x64`
twice) and the Assembly Line, whose inputs are slot-ordered by design and whose recipes are
Gregicality's, not this pack's.

The first run reported 465 duplicates and 2 overlapping pairs; the 465 were those two expected
families, and **the 2 overlaps were a real defect of this pack's**: Ender IO's Advanced Power Monitor
had been flattened with `<ore:dye>` where the mod's grid asks for `dyeRed`, so the red slot accepted
any colour and one dye stack could fill two slots. It asks for `<ore:dyeRed>` again.

Standing state after the fix: 5 mergeable duplicates, 0 overlapping pairs, 460 over the slot limit
(expected) - and all five are Gregicality's own recipes (`ga_armor` x4, `ga_multiblock_casing:13`),
named in the log and left alone on the rule that this pack only re-costs content it takes over. Confirmed by the owner on 2026-10-14: they stay as they are - the matcher deducts each input entry as it is satisfied, so "two entries of one" and "one entry of two" cost and consume the same, and folding them would only change how JEI draws the slot while making this pack the author of another mod's recipes.

## Dense plates vs GC/GS naming (TJ-MIGRATION-PLAN.md 6by)

The owner's report - "GT has dense plates too and they clash with GC/GS's naming" - was measured with
a temporary probe (deleted) that dumped every `dense`/`compress` ore name with all its items, every
name holding both a GT and a GC/GS item, and every recipe eating Galaxy Space's compressed coal or
magnesium, at init and at load complete.

Result: **GregTech's dense plates do not collide with anything.** All 130-odd `plateDenseX` names
hold exactly one item and it is always GregTech's, before and after CraftTweaker; GC/GS's compressed
plates live under their own `compressedX` names. The eleven names that hold both sides are the nine
ore names (their members are Galaxy Space's and GC-Planets' **planet** ores - same tier as GregTech's
ore blocks, generated on their own planets, and they must stay in the name for GregTech to process
them) plus `logWood`/`plankWood` (Barnarda's violet wood).

The one real inconsistency left is `plateCoal` and `plateMagnesium`, which hold Galaxy Space's
*Compressed* Coal and Magnesium - a compressed plate under a plain plate name, the same shape as the
fourteen plates `oredict.zs` already fixed. The pack left them because GregTech has no coal or
magnesium plate to hand the name to. What reads them: GregTech's own plate-recycling lanes
(macerator, plasma arc furnace, arc furnace), Ender IO's coal-dust recipe and two Galaxy Space
decorative blocks. Applying the uniform rule would mean emptying the names and rebuilding those three
mod recipes by id - written up in the plan section as a decision for the owner. This pack's own use is
fixed: the Galaxy Space alloy plate recipe in `gs_removals.zs` now names
`<galaxyspace:compressed_plates:0>` instead of the ambiguous `<ore:plateCoal>`.

## Display names: "致密钛板" twice, and the `minespace-lang` resource pack (TJ-MIGRATION-PLAN.md 6bz)

The ore-dictionary names do not collide, but the **item names do**, in Chinese: Galacticraft-Planets'
and Galaxy Space's compressed plates are translated as 致密X板, which is exactly how GregTech names its
Dense X plates - and they are different tiers (GregTech's is nine plates off a bender, the mods' is
two plates and TNT off the implosion compressor). Three exact collisions: 致密钛板 (GT
`plateDenseTitanium` vs GC-Planets' compressed titanium), 致密钴板 and 致密镍板 (GT dense cobalt and
nickel vs Galaxy Space's compressed cobalt and nickel). The English names never collide.

Fixed on the mods' side, with the word their own English uses: `resourcepacks/minespace-lang/`
renames them to 压缩钛板 / 压缩钴板 / 压缩镍板 / 压缩镁板 / 压缩煤板 (and the `zh_tw` variants), and
`options.txt` enables the pack (`resourcePacks:["minespace-lang"]`). Measured on the client: a lang
file shipped inside this pack's own mod jar does **not** win - the mod that owns the asset keeps its
keys - so a `resourcepacks/` pack, which always loads after every mod pack, is the only reliable
place. Verified by a temporary client probe (deleted): GregTech's names unchanged, the mods' items
now read 压缩X板. Server run afterwards reproduced the baseline.

That wording was then revised on the owner's note that these are flight-rated plates, not shop
parts, and the probe (which also printed each item's **lang key**) showed the renaming had been
incomplete: six more Galacticraft plates collide, translated by a different file
(`item.basic_item.compressed_*`). The whole family - nine Galacticraft plates and five Galaxy Space
ones - is renamed in one family. The wording took three passes: 宇航级 (too low), 星舰船体 (too far),
and what ships - the materials-engineering register the items actually belong to - **X基复合装甲板**
(铜基 / 锡基 / 铝基 / 钢基 / 青铜基 / 铁基 / 陨铁基 / 戴斯基 / 钛基复合装甲板, and 碳基 / 钴基 /
镁基 / 镍基复合装甲板 plus `"SDHC-120" 基复合装甲`). GregTech's 致密X板 names are untouched and no two
items share a name. One trap: the Galacticraft-core keys need the `.name` suffix - without it the
client shows `...铜板.name`, which is how the first attempt failed and the probe caught it. Worth
knowing for the future: two empty `assets/<mod>/lang/` directories left in the dev project made the
jar carry dead entries until they were removed; the shipped jar now contains only
`assets/minespace/lang/`.

The two collisions above were the visible ones; on 2026-10-14 the whole set was swept on the client
(TJ-MIGRATION-PLAN.md 6ce): of 48,737 named stacks, 1,488 names are shared by more than one item and
**93 of those cross a mod boundary**. Most are the families the pack keeps on purpose - each planet's
ore block named like the overworld's, the wood family, vanilla's dyes and glass pane, AE2's quartz -
and 131 ids were already hidden here. Ten were not, and now are (the Galaxy Space blocks and nuggets,
its empty battery state, the Galacticraft-Planets lead ingot, Galacticraft-IC2-Compat's aluminium
dust and Galacticraft's own Oxygen Compressor). One that no hide could fix was a **translation bug**:
GT++'s "Good Phenolic Circuit Board" and "Good Plastic Circuit Board" had lost the "Good" in Chinese
and read exactly like GregTech's two boards, so `minespace-lang` now carries
`assets/gtadditions/lang/zh_cn.lang` with the corrected names; the cross-mod count fell 94 -> 93 with
no board collision left. Renamed the same day on the owner's delegation, all in this same resource pack and each one read back
off the client: Galacticraft's Steel Pole -> **钢柱** (GregTech's steel rod keeps 钢杆), Forestry's
Worktable -> **林业工作台**, and Galaxy Space's two watergrass plants -> **红藻水草 / 褐藻水草**
(GT++'s algae materials keep the plain names). Left alone with reasons: the thermal padding tiers and
the five CNSA schematics each share **one unlocalised key** with the item they collide with, so a lang
file can rename both but cannot split them, and 终极电池 is "Ultimate Battery" in both mods upstream.
Done later the same day (TJ-MIGRATION-PLAN.md 6cf), and the culprit was not the mods' machines at all:
those duplicate powders are produced by **Gregicality's own hand recipes** ("a mortar and nine small
dusts", "an ingot and a hammer"), generated through `OreDictUnifier.get` and therefore handing out the
mod's copy - the 6bk gear bug in the one registry nothing covered, the crafting table's *output*.
`MinespaceMaterialRepoint.removeDeadDuplicateCrafting` now deletes a crafting recipe that hands out a
unified-away mod item when nothing in the finished registries consumes that item (34 recipes across the
two passes), and nine items are hidden from JEI as a result: AE2's iron, gold and ender-pearl dusts,
Ender IO's powdered coal, obsidian powder and soularium powder, Forestry's ash, Galaxy Space's sulfur
dust, and Galacticraft-Planets' desh ingot. The two AE2 quartz dusts keep their producer because AE2's
own recipes still eat them. The desh bridge in `gaps.zs` became moot (the input pass sends
Galacticraft's recipes to GregTech's ingot) and is deleted on every load; the lead bridge beside it is
still load-bearing.

## Version policy

- Forge: pinned to **14.23.5.2859**, the *Recommended* build for 1.12.2 and the version
  the development workspace targets. Newer 1.12.2 builds exist (up to 14.23.5.2864,
  released 2025-12-03) but mods are generally tested against the recommended build.
- GTCEu: **2.8.10-beta**, the latest 1.12.2 release (2024-07-10).
- Galacticraft Legacy: **4.0.7**, the latest 1.12.2 release.
- KubeJS: **1.1.0.65**, the latest 1.12.2 release.
