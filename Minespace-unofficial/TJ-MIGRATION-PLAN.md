# Migrating Minespace from GTCEu to GTCE: TJ Edition

Status: **M1 and M4 done (2026-10-11).** The addon is ported, builds, and the real instance
(`..\Minespace-unofficial-dev`) runs the TJ stack on a fresh world: `successfully loaded 45 mods`,
`Done (5.392s)!`, **0** `NullPointerException`s and **0** CraftTweaker errors. M2 is partly done
(stone types now work, see section 6a; the planet vein sets are ported, 6b); M3 (machine GUIs) is
still open. Section 6e records the gregification of the four mods added on top of the stack
(Forestry, Ender IO, Storage Drawers, Iron Chests) and the three broken recipes it uncovered;
section 6f records the same duplicate-material sweep applied to Galacticraft and Galaxy Space;
section 6g adds ModTweaker + MTLib and the routes into machine recipes that are not crafting-table
recipes (AE2's inscriber, Forestry's machines, Ender IO's XML).

This is the counterpart of `GC-GREGFICATION-PLAN.md` for a much bigger change: replacing the
**GregTech CE: Unofficial** stack this addon compiles against with **GregTech CE: TJ Edition** and
its Gregicality fork.

---

## 1. Why this is on the table

| | GTCEu (today) | GTCE: TJ Edition |
| --- | --- | --- |
| 1.12.2 releases | last one 2.8.10-beta, **2024-07-10** | `gregtech_tj_fork-1.18.3`, **2026-09-21** |
| post-UV content | GCYS dead (2022), Serendustry alpha-only | **Gregicality TJ Fork 0.26.3**, 2026-09-21 - the continuation of Gregicality Legacy (UHV+ tiers, multiblocks, chemistry) |
| addon API era | `Material` + properties + two-stage `MaterialRegistryEvent`/`MaterialEvent` | GTCE-style material *types* (`IngotMaterial`, `DustMaterial`, ...) + `IMaterialHandler` |

The user's goal throughout this project has been **UHV+ content that is actually playable** (i.e.
with recipes). That is exactly what Gregicality provides, and it only exists for the GTCE/TJ
lineage.

## 2. Target pack composition

Keep (verified in the boot test): CodeChickenLib, **GTCE-TJ**, **Gregicality TJ**,
**AE2UEL**, Galacticraft, GalaxySpace, AsmodeusCore, MixinBooter, PlanetProgression,
MJRLegendsLib, JEI, The One Probe, CraftTweaker, KubeJS, Xaero's three jars.

Drop, because they are GTCEu-only: GTCEu itself, Gregicality Multiblocks (GCYM), GregTech Food
Option, SussyPatches, ConfigAnytime. (`GTFO`'s food chains and `SussyPatches`' fixes have no TJ
equivalent. Gregicality TJ covers the multiblock content GCYM provided.)

**TJ Additions is excluded on purpose.** Versions 2.9.0 and 2.10.0 both collide with Gregicality
TJ on machine id 4205 (`gtadditions:disassembler.uv` vs `tj:mega_coke_oven`), in all four
Gregicality/TJ-Additions pairings that exist on CurseForge. Its own `dependencies.gradle` targets
`gregtech_tj_fork-1.18.2-dev` + `gregicality_tj_fork-0.26.2-dev`, so it expects the authors' dev
builds, not the public files.

## 3. Evidence: the stack boots (2026-10-11)

Scratch instance `..\Minespace-tj-test` (runtime/libraries/versions/assets are directory
junctions into `..\Minespace-unofficial-dev`, so it costs no extra space), 17 jars -> 27 mod
containers:

```
[FML]: Forge Mod Loader has successfully loaded 27 mods
[DedicatedServer]: Done (7.845s)!
```

CurseForge coordinates used (all 1.12.2):

| Mod | CF project | File | File id | Date |
| --- | --- | --- | --- | --- |
| GTCE: TJ Edition | 597032 | `gregtech_tj_fork-1.18.3.jar` | 8942273 | 2026-09-21 |
| Gregicality TJ Fork | 607023 | `gregicality_tj_fork-0.26.3.jar` | 8942284 | 2026-09-21 |
| AE2UEL | 570458 | `ae2-uel-v0.56.7.jar` | 6302098 | 2025-03-14 |
| (TJ Additions - excluded) | 1553760 | `tj-2.10.0.jar` | 8936798 | 2026-09-21 |

## 4. API mapping (read out of `gregtech_tj_fork-1.18.3.jar`)

Present in TJ, so most of the addon's imports survive unchanged: `OrePrefix`, `StoneType` /
`StoneTypes`, `MetaItem` / `StandardMetaItem`, `RecipeMap` / `RecipeMaps`, `GTValues`,
`GTUtility`, `MetaTileEntity`, `TieredMetaTileEntity`, **`WorkableTieredMetaTileEntity`**,
`MTETrait`, `ModularUI` / `Widget` / `GuiTextures` / `TextureArea`, `IMaterialHandler`.

What differs:

| GTCEu 2.8 (current code) | GTCE-TJ replacement |
| --- | --- |
| `gregtech.api.unification.material.Material` + `MaterialProperties` / `PropertyKey` | `gregtech.api.unification.material.type.Material` and its subclasses (`IngotMaterial`, `DustMaterial`, `FluidMaterial`, `GemMaterial`, ...) |
| `new Material.Builder(id, name).ingot().fluid().color(c).iconSet(s).build()` | type constructor: `new IngotMaterial(id, name, color, MaterialIconSet.X, harvestLevel, components, flags, ...)` |
| `@SubscribeEvent MaterialRegistryEvent` -> `GregTechAPI.materialManager.createRegistry("minespace")` | class implements `IMaterialHandler.onMaterialsInit()`, annotated `@RegisterMaterialHandler` |
| `@SubscribeEvent MaterialEvent` -> register the materials | same `onMaterialsInit()` (TJ calls it before its own materials are built) |
| `GregTechAPI.MTE_REGISTRY.register(id, name, mte)` | `GregTechAPI.registerMetaTileEntity(id, mte)` |
| `gregtech.api.gui.resources.IGuiTexture` | `TextArea`/`TextureArea` + `ModularUI` widgets; `IGuiTexture` does not exist |
| `gregtech.api.metatileentity.interfaces.IGregTechTileEntity` | `MetaTileEntity` / `MetaTileEntityHolder` (the interface moved) |
| `MaterialIconSet` | unchanged (same class name) |

Class-reference scan of the current `minespace-0.2.0.jar` against the TJ jar: **31 distinct
`gregtech/*` references, 10 missing** - all of them in the material-definition and GUI rows
above. Every machine base class the addon uses is present.

## 5. File-by-file work list

| File | Change |
| --- | --- |
| `gtceu/MinespaceMaterials.java` | rewrite: `IMaterialHandler` + `@RegisterMaterialHandler`, `IngotMaterial`/`DustMaterial` constructors instead of `Material.Builder`; drop the registry-phase code and `lookup()`'s namespaced-key workaround |
| `gtceu/MinespaceStoneTypes.java`, `MinespacePlanetStoneTypes.java` | keep the shape; `StoneType` exists in TJ, but the constructor/registration signature must be checked against `StoneTypes` |
| `gtceu/MinespacePlanetRocks.java`, `MinespaceMoonRock.java`, `MinespacePlanetRocks` tables | unchanged (plain Forge blocks) |
| `gtceu/MinespacePlanetOreGen.java` | keep the idea (Galacticraft's `ChunkProviderSpace` never calls `GameRegistry.generateWorld`); the hook itself is GT-agnostic |
| `gtceu/machines/*` | `WorkableTieredMetaTileEntity` exists, so the machine classes are close; registration switches to `GregTechAPI.registerMetaTileEntity`; the GUI has to move from GTCEu textures to `ModularUI` widgets |
| `galacticraft/*` | unchanged (Galacticraft API only) |
| `Minespace.java` | `@Mod` version bounds and `required-after:gregtech` stay; the `MaterialRegistryEvent` import/comment block goes away |
| `scripts/own_machines.zs` and the other CraftTweaker scripts | GTCE's CraftTweaker integration is a different API from GTCEu's `<recipemap:...>` - they need re-porting and re-testing against TJ |
| `gradle.properties` / `build.gradle` | swap the CurseMaven coordinates to GTCE-TJ (+ Gregicality TJ) and bump `gtceu_version` accordingly |

## 6. Milestones

1. **M1 - compile**: material + machine registration ported, `gradlew build` green against the TJ
   jars. Deliverable: a jar that loads in the TJ test instance without `NoClassDefFoundError`.
   **Done 2026-10-11** - `minespace-0.2.0.jar` loads on the TJ stack, registers 6 materials and
   both machines, and the dedicated server reaches `Done` on a fresh world.
2. **M2 - content**: stone types / planet ore bases / ore-gen hook verified in game on a planet.
   Stone types are fixed and verified (6a), the ore-gen hook registers; what is missing is the
   **planet vein sets** (6b) - ported and verified 2026-10-11 together with the three integration
   bugs in 6c.
3. **M3 - machines**: the two machines (oxygen compressor, rocket fuel loader) placed, powered and
   crafting, with their `ModularUI` screens. **The screens were complete from the start; the last gap
   - the "nothing to work with" feedback GregTech's own machines give - was closed 2026-10-14
   (section 6cg): both carry `INDICATOR_NO_ENERGY` at the same place and size GTCE's single-block
   machines use. Only the in-game look is unverified, and only a right-click can verify it.**
4. **M4 - switch the real instance**: move the TJ stack into `Minespace-unofficial-dev`, park the
   GTCEu jars, start a **new world** (the save's `gregtech:*` registry cannot be carried over).
   **Done 2026-10-11** - the GTCEu stack is parked at
   `%TEMP%\minespace-removed\2026-10-11-gtceu-stack\`, the old world is kept as
   `world-gtceu-backup`, and the TJ world is new.

## 6a. The stone type timing rule (the crash this migration surfaced)

GTCE-TJ bakes its ore blocks in **its own preInit** (`GregTechMod.preInit` ->
`MetaBlocks.init()`), reading `StoneType.STONE_TYPE_REGISTRY` and putting 16 stone type ids into
each `BlockOre`'s `stone_type` property. That is *earlier* than GTCEu 2.8 did it, and earlier
than any `RegistryEvent.Register<Block>` listener - so the GTCEu-era "register stone types from
the block event at `HIGH`" trick silently stopped working:

* our 21 stone types were in the registry but in **no** ore block, so
  `OreConfigUtils.getOreForMaterial()` returned only GT's own 14 types (measured: 162 of 162 ore
  materials had exactly 14/35), and
* `FillerConfigUtils$OreFilterEntry.apply` is `blockStateMap.get(computeStoneType(...))` with no
  null guard, so any vein meeting one of those rocks fed `null` to `World.setBlockState` and died
  with a NullPointerException (147 of them in the overworld, all from air resolved to a stone
  type).

The addon now registers all 21 stone types from `MinespaceMaterials.onMaterialsInit()` - the
window between `Material.runMaterialHandlers()` and `MetaBlocks.init()` - and resolves every
block-shaped piece lazily by registry name, because no mod has registered a block yet at that
point. `MinespaceGalaxySpaceStones.lazyBlock` also treats Forge's `minecraft:air` placeholder as
"not registered": using the placeholder as a predicate target is what made a missing Galaxy
Space lookup match every air block in the world.

Evidence after the fix: `ore coverage: 162 ore materials, 0 with a stone type missing`, block
scan lists only real Galacticraft/Galaxy Space rocks, `All 17 Galaxy Space rock blocks resolved`,
0 NullPointerExceptions.

Known limitation in the same area: `BlockBasicMoon`, `BlockBasicMars` and `BlockBasicVenus`
override `isReplaceableOreGen` and ignore the predicate, so those three rocks resolve to GT's own
`stone` type (id 0) instead of ours - the ores generate, but draw the overworld stone base.
The asteroid block and all 17 Galaxy Space rocks honour the predicate. Fixing the three
Galacticraft blocks needs an opt-in mixin (MixinBooter is already in the stack).

## 6b. Planet vein sets - ported 2026-10-11

The GTCEu-era per-body sets (moon 9, mars 14, venus 13, asteroids 11, ceres 1, barnarda 1) used
GTCEu's `layered` generator/filler, which GTCE-TJ does not have (checked in both the GTCE-TJ and
Gregicality jars). `tools\port-worldgen-veins.ps1` rewrites them: `layered` generator ->
`ellipsoid` with the same radius pair, `layered` filler -> `simple`+`weight_random` with the
primary/secondary/between/sporadic keys mapped onto decaying weights (55/25/15/5, 60/25/15,
70/30, 100 depending on how many distinct materials the vein lists) and duplicates merged,
`ore:minespace:x` -> `ore:x`, and `ore:plutonium` (no GTCE-TJ ore) ->
`ore:enriched_naquadric_compound`. Files are written **without a BOM** - gson treats a BOM as
malformed JSON and that aborts the whole worldgen reload, not just the one file.

Result: `Loaded 111 worldgen definitions` (62 GT + 49 ported), no parse failures, and real ore in
every sampled dimension (Overworld 11489 ore blocks in 64 chunks, Moon 1574, Mars 1532,
Asteroids 1379, Ceres 1521 - `gregtech:ore_brown_limonite_1@ceres_stone`, i.e. on our stone
type).

## 6c. Three integration bugs found while verifying the port

1. **Overworld veins applied to planets.** GT's overworld files have no `dimension_filter`, so
   they fall back to `is_surface_world`, which in 1.12.2 reads
   `WorldProvider.getDimensionType()` - default `OVERWORLD`, and Galacticraft's planet providers
   inherit that. The overworld set would therefore generate on planets, and worse, its oil/gas
   definitions use `biome_dictionary`, so GT called `BiomeDictionary.hasType` on a planet biome
   Galacticraft never registered; Forge answers with `makeBestGuess` -> `addTypes` ->
   `IllegalArgumentException: Cannot add types to unregistered biome`, aborting the whole vein
   pass. Fixed by `tools\fix-worldgen-overworld-scope.ps1` (44 files pinned to `dimension_id:0`).
2. **Galaxy Space crashes planet decoration.** `config\GalaxySpace\world.conf` had an empty entry
   inside `S:oreGenSettings`, and `GSEventHandler.onPlanetDecorated` runs every entry through
   `Integer.parseInt` - `NumberFormatException: For input string: ""` on every planet chunk.
   Fixed by emptying the list properly.
3. **GregTech's vein grid had 0/0 terrain heights on planets** (addon fix): `CachedGridEntry`
   measures the terrain only when no chunk of its 3x3 cell is generated yet; in a Galacticraft
   dimension the chunk already counts as generated, so the chunk capability keeps its default
   heights, `doGenerateVein` computes `maxHeight = min(0, limit) = 0 < minHeight` and skips
   every vein. `MinespacePlanetOreGen` now primes the whole generated 3x3 cell's capabilities in
   `PopulateChunkEvent.Pre` with `getPrecipitationHeight` / `getTopSolidOrLiquidBlock`.
4. **Galacticraft's three planet-rock blocks ignored the stone type predicate** (addon fix, the
   one the user asked for: "ores with each planet's own material"). `BlockBasicMoon`,
   `BlockBasicMars` and `BlockBasicVenus` override `isReplaceableOreGen` and return their variant
   check *without* consulting the predicate they are handed, so `computeStoneType` returned GT's
   own `stone` (id 0) for every one of those rocks and the ores were placed as the overworld
   variant. Three Mixins now inject at the head of that method and only ever turn a "yes" into a
   "no" (`if (target != null && !target.apply(state)) setReturnValue(false)`), which keeps
   Galacticraft's own variant selection intact. They are registered through the `MixinConfigs`
   manifest attribute, the same mechanism AsmodeusCore and Galaxy Space use, and compiled against
   MixinBooter's Mixin (`compileOnly`, so no second Mixin is bundled). Verified per dimension:
   Moon `@moon_stone`, Mars `@mars_stone`, Asteroids `@venus_stone`, Ceres `@ceres_stone`,
   overworld unchanged.
5. **GC's Venus provider fires no populate events** (addon fix): neither the height priming nor
   the `GameRegistry.generateWorld` call could run there. `MinespacePlanetOreGen` now also queues
   chunks from `ChunkEvent.Load` and drives GregTech's generator directly ~2 s later for
   dimensions that never registered a populate hook, and only for those (so the Moon/Mars/
   Asteroids path is untouched and no veins are generated twice).
6. **Vanilla worldgen cleanup** (pack change + addon fix, 2026-10-11 afternoon):
   `config/gregtech.cfg` now has `B:disableVanillaOres=true`, which removes all eight vanilla
   ores (measured 0 in a fresh 144-chunk sample that used to hold 41k of them).
   `MinespaceVanillaWorldgen` additionally replaces `BiomeDecorator.graniteGen`/`dioriteGen`/
   `andesiteGen` with a no-op - they are not ores and are not reachable through any ore-gen event
   in this Forge build - for every biome the chunk's `BiomeProvider` reports, at
   `DecorateBiomeEvent.Pre` (patching only the registered biomes is not enough: the world
   decorates with its provider's instances). That took the vanilla stone variants from ~78k-97k
   to ~2.2k per sample. Gregicality's separate lava-to-stone-variant flavour is reverted to plain
   cobblestone at `EventPriority.LOWEST`. `config/minespace.cfg` -> `S:disabledVanillaGenerators`
   is the knob.

## 6d. CraftTweaker scripts - ported 2026-10-11

The pack's six `.zs` files were parked during the migration (GTCEu's recipe-map API does not
exist in GTCE-TJ). They are ported now by `tools\port-crafttweaker-scripts.ps1`:

* 30 uses of GTCEu's `<recipemap:assembler>.recipeBuilder()` became
  `mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()`. The Java method is
  `RecipeMap.ctRecipeBuilder()`, but it carries `@ZenMethod("recipeBuilder")`, so the script name
  is `recipeBuilder()` - the unannotated Java `recipeBuilder()` returns a raw builder scripts
  cannot use. Everything after the accessor (`inputs`, `outputs`, `duration`, `EUT`, `property`,
  `circuit`, `fluidInputs`, `buildAndRegister`) is identical in both forks.
* Two maps were renamed, read out of `RecipeMaps`' static initialiser: `bender` -> `metal_bender`
  and `electric_blast_furnace` -> `blast_furnace`.
* The gas collector statement is **unportable**: GTCE-TJ registers 51 recipe maps and none is a
  gas collector (the machine does not exist in this lineage). The statement is commented out with
  an explanation; oxygen comes from GregTech's electrolyser instead (133 recipes in that map
  output oxygen fluid), which is exactly what the addon's Oxygen Compressor bottles into
  Galacticraft tanks.
* Everything else - `recipes.remove`, `recipes.addShaped/Shapeless`, `mods.jei.JEI.hide*`, the ore
  dictionary names, the Galacticraft metas, the JEI category ids - needed no change.

Verified on a dedicated server: `crafttweaker.log` reports **0 errors** (the JEI category and hide
calls resolve, which they only do when the ids exist), the log shows the eight re-added crafting
recipes by name, and a probe against GregTech's own maps found the recipes in place:
`assembler` 4038 recipes (including one for `gregtech:machine:32000` and one for `:32001`),
`metal_bender` 1004, `canner` 22, `macerator` 11607, `implosion_compressor` 304,
`blast_furnace` 396, `distillery` 247.

## 6e. Forestry / Ender IO / Storage Drawers / Iron Chests - 2026-10-11

The four mods added on the user's request (`forestry_1.12.2-5.8.2.427`, `EnderIO-1.12.2-5.3.72`
with `EnderCore`, `StorageDrawers-1.12.2-5.5.3` with `Chameleon`, `ironchest-1.12.2-7.0.72.847`)
are now wired into the GregTech chain by `scripts\integration.zs`.

The reference material the user supplied (`Mods-Get-Gregged`) is **1.7.10** for both packs -
`GT5-scripts\` and `Custom-Modpack-Scripts\GTNewHorizons\` are Forge 10.13.4 / Forestry 4.2 /
EnderIO 2.3 / Storage Drawers 1.10 - so the recipes are not transliterable (`<GalacticraftCore:tile.*>`
and `gregtech:gt.metaitem.01:*` do not exist here). What *is* ported is the method: delete the mod's
recipe, rebuild it with the matching GregTech plate, put an LV circuit into machines that process
items, and delete the generators GregTech already provides.

| Mod | What changed |
| --- | --- |
| Iron Chests | all 8 chests + 9 upgrades rebuilt as 8 GT plates around a centre (`ironchest:iron_chest` metadata is `IronChestType.ordinal()`: 0 Iron, 1 Gold, 2 Diamond, 3 Copper, 4 Silver, 5 Crystal, 6 Obsidian, 7 Dirt, 8 Wood) |
| Storage Drawers | drawers, trims, framed drawers/trim, framing table, compacting drawer, controller + slave, and the upgrade family rebuilt from GT wood plates, GT metal plates and GT screws; the controller, slave and compacting drawer also take an LV circuit |
| Ender IO | the stirling / combustion / zombie / franken-zombie / ender / lava generators and the solar panel are removed and hidden (GT generators replace them, exactly as for Galacticraft); the machine chassis, machine parts and the base capacitor are re-costed in GT steel; power and fluid conduits move to the GT **assembler** |
| Forestry | sturdy casing, carpenter, centrifuge, squeezer, fermenter, moistener, still, rain tank, analyzer, thermionic fabricator, rainmaker, mailbox, both engines, the managed peat bog, the farm frame and the alveary family rebuilt from GT plates / glass plates, with circuits in the processing machines |

Three bugs were found and fixed on the way, all of them the "the recipe exists but cannot be built"
family the user reported:

1. **CraftTweaker's `<ore:...>` does not fail for a name that does not exist.** The ported scripts
   used `circuitLv` / `circuitMv` / `circuitHv` - GTCE-TJ registers those names but with **zero**
   stacks (it kept GT5's `circuitBasic` / `circuitGood` / `circuitAdvanced` instead). Every recipe
   built on them landed in JEI with a blank circuit slot: the oxygen distributor, sealer and
   detector, both Galacticraft wafers, the addon's own Oxygen Compressor and Rocket Fuel Loader,
   the astro miner base and the Galaxy Space rocket assembler. All 15 sites now use the real names.
2. **`<ore:plateAlloyAdvanced>` is empty in this pack** (it is IC2's advanced alloy, and there is no
   IC2). The *whole middle row* of the rocket launch pad recipe was blank, and the launch pad is on
   the rocket critical path. GT stainless-steel plate stands in - the same tier as the stainless
   screws the air lock frame next to it already asks for.
3. **GTCE-TJ's `metal_bender` and `distillery` do not match GTCEu's input counts.** `metal_bender`
   is declared `new RecipeMap("metal_bender", 2, 2, ...)` - its own plate recipes pass an
   integrated circuit plus the ingot - and `distillery` takes exactly one item input. The canister
   bender recipes and the oil-to-rocket-fuel distillery recipe were rejected on load
   (`Invalid amount of recipe inputs. Actual: 1/0`) and now carry `.circuit(1)`.

Verification, on a dedicated server against a fresh world:

* `Forge Mod Loader has successfully loaded 45 mods`, `Done (5.392s)!`.
* `crafttweaker.log` reports **0 errors / 0 warnings** and logs **288** added recipes, including every
  chest, every chest upgrade, all nine shulker-box upgrades, every drawer family, the drawer key,
  `Simple Machine Chassis`, `Machine Parts`, `Basic Capacitor`, `Sturdy Casing`, `Carpenter`,
  `Centrifuge`, `Squeezer`, `Fermenter`, `Still`, `Moistener`, `Thermionic Fabricator`,
  `Rainmaker`, `Rain Tank`, `Analyzer`, `Mailbox`, `Bottler`, `Habitat Former`, `Trade Station`,
  `Database`, `Apiary`, both engines, `Peat Bog (Managed)`, `Farm Block`, the six single-block
  farms (`Arboretum`, `Farm Crops/Mushroom/Gourd/Nether/Ender`) and the six alveary parts.
* **Forestry's own duplicate materials and generic tools are deleted**, which is the first thing the
  reference pack's `Forestry.zs` does (its lines 60-80), and the same treatment
  `gc_removals.zs` gives Galacticraft's duplicate metals. Removed with no replacement:
  `gear_bronze` / `gear_copper` / `gear_tin` (two recipes each - a "sticks + plates + wrench" shape
  and an "ingot ring around a stone gear" shape), the mod's own `ingot_copper` / `ingot_tin` /
  `ingot_bronze` (nine-nugget, block-splitting and bronze-mixing recipes), and the generic tools
  `bronze_pickaxe` / `bronze_shovel` / `kit_pickaxe` / `kit_shovel` / `wrench`. Nothing is re-added:
  the ore dictionary entries (`ingotCopper`, `gearBronze`, ...) still list GregTech's items, so every
  recipe written against those names keeps working. Two shortcuts that have no GregTech equivalent
  are re-costed instead of deleted - the tin cans (tin plate) and stamps 1n/2n/5n/10n (copper / tin /
  gold plate) - and the naturalist's goggles are re-costed in bronze plate and glass plate.
* Ender IO's dark steel armour and tools (`item_dark_steel_helmet/chestplate/leggings/boots/sword/
  pickaxe/axe`) are removed and hidden from JEI, exactly the seven the reference pack's
  `Ender_IO.zs` removes. A check against the full crafting dump first proved no recipe anywhere uses
  one of them as an ingredient, so nothing can be stranded, and Ender IO's dark steel *upgrades* are
  untouched.
* The **sixteen coloured shulker box chains** are the last family that was still on the mod's own
  recipes, and they are now rewritten too: 176 recipes (16 colours x 7 tiers, with the tiers the mod
  itself makes reachable two ways kept reachable two ways). Writing those by hand would only invite
  typos, so they are generated with a ZenScript loop over a colour array plus
  `itemUtils.getItem("ironchest:iron_shulker_box_" + colour, tier)` - `itemUtils.getItem(name, meta)`
  is literally the same code path as the `<item:...>` bracket handler with an explicit metadata
  (`MCItemUtils.getItem` calls `BracketHandlerItem.getItem`), so it is safe to build a name at
  runtime. The vanilla light-grey box is `minecraft:silver_shulker_box` in 1.12.2, not
  `light_gray`.
* Ender IO's nine alloys are now also made by GregTech, from the inputs in the mod's own
  `assets/enderio/config/recipes/alloying.xml`: the two-input ones (Vibrant Alloy, Redstone Alloy,
  Conductive Iron, Pulsating Iron, Soularium, plus the Electrical Steel and Dark Steel "variant"
  recipes) in the **alloy smelter**, the three-input ones (Electrical Steel, Energetic Alloy,
  Dark Steel, End Steel, Construction Alloy) in the **mixer**. The split is forced: GTCE-TJ declares
  `alloy_smelter` as `new RecipeMap("alloy_smelter", 1, 2, ...)`, i.e. a hard maximum of two item
  inputs, while `mixer` is `(0, 4, ...)`; a third input in the alloy smelter is rejected on load.
* **The old route for those alloys is actually deleted**, which a script cannot do.
  Ender IO reads its recipes from XML in its own postInit - the log shows
  `[enderio]: Reading user recipe file user_recipes.xml` *after* CraftTweaker's recipe event - so by
  the time Ender IO registers them, `recipes.remove(...)` has already run and finds nothing. The
  fixes are the twelve `disabled="true"` entries in
  `config/enderio/recipes/user/user_recipes.xml`; the names are copied verbatim from `alloying.xml`,
  and Ender IO's `Recipe.readResolve()` returns before registering when that flag is set. Verified
  by reading Ender IO's own manager back through reflection: the alloy smelter still holds 85
  recipes (fused quartz/glass variants, dyes, cookie, chassis, nethercotta, ...) and **not one of
  them outputs `enderio:item_alloy_ingot`** any more.

**Rule this establishes:** `recipes.remove(...)` only ever sees recipes that exist when
CraftTweaker runs. For a mod that registers from its own config or in a later phase, deletion has
to go through that mod's own config, or through a late removal in the addon
(`FMLLoadCompleteEvent`), never through a script.

Both concerns were then proved directly, with a temporary probe that walked
`CraftingManager.REGISTRY` at `FMLServerStartedEvent` (after every mod has finished):

* `outputs produced by scripts: 112`, `OLD RECIPES SURVIVING NEXT TO A SCRIPTED ONE: 0` - i.e. no
  gregified item has both an old and a new crafting recipe.
* 28 sampled targets, all `PASS`: the eleven items that are removed *without* a replacement
  (`forestry:gear_bronze:0`, `gear_copper:0`, `gear_tin:0`, `ingot_copper:0`, `ingot_tin:0`,
  `ingot_bronze:0`, `bronze_pickaxe:0`, `bronze_shovel:0`, `kit_pickaxe:0`, `kit_shovel:0`,
  `wrench:0`) end with **0** recipes, and the re-costed ones
  (`forestry:can:0`, `stamps:0..3`, `naturalist_helmet:0`, `sturdy_machine:0`, `carpenter:0`,
  `bottler:0`, `apiary:0`, `farm_crops:0`, `ironchest:iron_chest:0`,
  `ironchest:iron_gold_chest_upgrade:0`, `storagedrawers:basicdrawers:0`,
  `storagedrawers:controller:0`, `enderio:item_material:0`, `enderio:item_basic_capacitor:0`) end
  with **exactly one**, e.g. `storagedrawers:basicdrawers:1 <- [plateWood]... x2` and
  `forestry:carpenter:0 <- [plateBronze][plateGlass]...`. The one deliberate exception is
  `enderio:item_power_conduit:0 -> 0 crafting recipes`, which is correct: that recipe moved to
  GregTech's assembler.
* The shulker family was checked the same way: `outputs produced by scripts: 224` (112 + 16x7) and
  the survivor list still empty, and every recipe the probe printed under a shulker output is
  registered as `crafttweaker:ct_shaped*` with GT plates in it - i.e. the mod's original recipes are
  gone, and the tiers that show two recipes are the two the mod's own design offers.
* The run still reports exactly **two** `Invalid recipe` errors, both from GregTech's and
  Gregicality's *own* recipe loaders (`MachineRecipeLoader.registerAssemblerRecipes`,
  `Gregicality MiscRecipes`) - the same two that every run since the GTCEu days has reported. No
  `duplicate or conflict found` line appeared, so none of the new machine recipes collided with an
  existing one.

**Trap worth remembering: the `.zs` files must not start with a UTF-8 BOM.** ZenScript fails with
`TokenException: Invalid character at null:1` and silently drops *the whole file* - the log line is
the only sign, `crafttweaker.log` loses every recipe in it, and the run still reaches `Done`. It is
easy to introduce one accidentally: Windows PowerShell 5's `Set-Content -Encoding utf8` and
`Out-File` write a BOM, `[IO.File]::WriteAllText($p, $t, (New-Object Text.UTF8Encoding($false)))`
does not. `Get-ChildItem scripts\*.zs | % { $b=[IO.File]::ReadAllBytes($_.FullName); $b[0] -eq 0xEF }`
is the check.
* Every ore-dictionary name and every item id used by the new script was checked against a full
  dump of the running server's ore dictionary (16 080 populated names, 834 empty ones) before the
  script was written - that dump is what caught `plateAlloyAdvanced`, `plateObsidian`,
  `plateDarkSteel`, `screwDiamond`, `wireGt02Aluminium` and the rest of the empty entries that the
  reference pack's 1.7.10 ore dictionary had and this one does not.
* The dead-recipe audit (every surviving crafting recipe whose every matching stack is a machine
  this pack removes) now reports **0** hits: the two that existed - the astro miner base and the
  Galaxy Space rocket assembler - were rebuilt in `scripts\gaps.zs`.

Deliberately *not* changed, and why:

* Ender IO's own alloy smelter and SAG mill stay craftable. Their alloys now come from GregTech
  (above), but deleting the machines themselves would strand Ender IO's own machine tree for no
  gain.
* Ender IO's *own* items stay on their own recipes: the nugget / ball / block forms of its alloys,
  the SAG-mill grinding balls, and the machine recipes it keeps (tank, buffer, vacuum chest,
  inventory chests, obelisks, chargers, ...). None of those duplicates a GregTech item - they are
  what Ender IO *is* - so the only thing that was a genuine duplicate (the alloys themselves) is the
  part that was moved.
* Storage Drawers' keys (concealment / personal / quantify) and the packing tape: shapeless
  combinations, or paper and slimeballs, with no metal in them at all.

At this point every item in the four mods whose recipe could be expressed in GregTech materials has
been rewritten, and the only recipes left on a mod's original materials are Ender IO's own alloy
derivatives and the drawer keys above - neither of which has a GregTech counterpart to move to.
* The Storage Drawers concealment / personal / quantify keys and the packing tape are shapeless
  combinations (or paper and slimeballs) with no metal in them at all.
* The Galacticraft / Galaxy Space leftovers (`item.battery`, the machine frames, the rocket
  workbench) were left alone deliberately: `gs_removals.zs` documents that the batteries
  are storage for their own tools rather than generators.

## 6f. The same sweep over Galacticraft and Galaxy Space - 2026-10-12

The four mods above were audited; Galacticraft and Galaxy Space were not, even though the first
gregification pass only handled Galacticraft's *materials* and never looked at Galaxy Space's. Two
steps, both cheap and both repeatable:

1. **Offline.** The full ore dictionary dump from section 6e was filtered for names that hold *both*
   a GregTech item and a Galacticraft / Galaxy Space item. That is the definition of "the mod ships
   its own copy of a material GregTech already makes", and it is how the two blocks and three ingots
   below were found - plus 20-odd GS items that turned out to be reachable only through GregTech
   recipes and needed nothing.
2. **Runtime.** A probe listed every surviving crafting recipe whose output is one of those items,
   i.e. exactly which duplicates are still craftable, and then re-ran the dead-recipe audit.

Removed (`gc_removals.zs`, `gs_removals.zs`):

| Item | Was craftable as |
| --- | --- |
| `galacticraftcore:basic_block_core:11` | aluminium block, from 9 ingots (GT's `blockAluminium` is listed first) |
| `galacticraftcore:basic_block_core:13` | silicon block, from 9 silicon (GT has `blockSilicon`) |
| `galacticraftplanets:item_basic_mars:2` | desh ingot, from `<ore:blockDesh>` |
| `galacticraftplanets:item_basic_asteroids:0` | titanium ingot, from `<ore:blockTitanium>` |
| `galacticraftplanets:basic_item_venus:1` | lead ingot, from `<ore:blockLead>` |
| `galaxyspace:ingots:*` / `blocksmetals:*` / `nuggets:*` | Galaxy Space's whole cobalt / magnesium / nickel set, including the "block to nine ingots" and "nine nuggets to an ingot" routes |

Two mistakes were caught by the audit before they shipped:

* **18 Galacticraft recipes went dead.** Galacticraft's desh armour and tools, the arc lamp, the
  atmospheric valve, the Mars machine block and the atomic battery are written against the exact
  item id `galacticraftplanets:item_basic_mars:2` / `basic_item_venus:1`, *not* against the ore
  dictionary, so taking those two ingots out of the grid stranded them. Fixed with two one-to-one
  bridges in `gaps.zs` (`recipes.addShapeless` from GregTech's exact desh / lead ingot,
  ids 10000 and 10035), so the metal still originates in GregTech's chain. The audit then reported
  `DEAD: 0`. The titanium ingot needed no bridge - nothing asks for it by id once its own
  "cut the storage block back down" recipe is gone.
* **The probe itself lied twice before it was trusted**: its first version treated "removed" as
  "gone" and reported the bridges as dead, and its `Set`/`HashSet` imports were missing (a build
  failure rather than a silent one). Both are worth remembering when reusing it.

What is deliberately left: Galaxy Space's `compressed_plates` (coal, cobalt, magnesium, nickel) -
coal and magnesium have no GregTech plate at all, and the cobalt / nickel ones are produced only by
GregTech's hammer and flatten recipes, which is what Galaxy Space's own machines consume - and
Galaxy Space's decorative Barnarda C planks, which merely happen to register `plankWood`.

Running total after this pass: `crafttweaker.log` logs **290** added recipes, 0 errors; the ore
dictionary cross-reference now shows only Gregicality's own plate / dust / block recipes producing
Galacticraft or Galaxy Space items, which is intentional - those mods own the ore dictionary name in
question, so Gregicality's generic recipes hand out the item they need.

## 6g. Widening what a script can touch - 2026-10-12

The crafting grid was covered, but most of a mod's *machine* recipes never were: Ender IO carries its
own alloy smelter and SAG mill, Forestry its carpenter / centrifuge / squeezer / fermenter / still,
AE2 its inscriber and grinder. None of those are `CraftingManager` recipes, so `recipes.remove(...)`
does not see them. Three separate routes exist and all three are now available in this pack:

| Route | Covers | How it is reached |
| --- | --- | --- |
| **ModTweaker 4.0.20.11** + **MTLib 3.0.7** (added 2026-10-12) | Forestry's eight machines, Tinkers / Thermal Expansion / Botania / AE2-adjacent mods that are not installed | `mods.forestry.Carpenter`, `.Centrifuge`, `.Squeezer`, `.Fermenter`, `.Still`, `.Moistener`, `.ThermionicFabricator`, `.CharcoalWall` |
| **native CraftTweaker support inside the mod** | Applied Energistics 2 | `mods.appliedenergistics2.Inscriber` / `.Grinder` / `.Cannon` (AE2UEL rv6 ships `appeng/integration/modules/crafttweaker/*`) |
| **the mod's own recipe files** | Ender IO (alloy smelter, SAG mill, vat, soul binder, enchanter, ...) | `config/enderio/recipes/user/*.xml` - see the alloys in section 6e |

Notes worth keeping:

* ModTweaker needs `mtlib`; the pair is loaded and the server reaches `successfully loaded 47 mods`
  with them in.
* ModTweaker's handlers were confirmed present by reflection at runtime
  (`com.blamejared.compat.forestry.*`, 2-6 methods each), because seeing the classes in the jar is
  not the same as CraftTweaker exposing them as `mods.forestry.*`.
* AE2's inscriber recipe shapes were **dumped from AE2's own registry** rather than guessed:
  `IInscriberRegistry.getRecipes()` through reflection, printing output, process type, middle input
  and the two optional slots. AE2's `CTModule.toStacks(null)` returns `Optional.empty()`, so the
  `top` / `bottom` arguments may be `null` - which the printed-circuit recipes need.
* AE2's item metadata is **not** the enum ordinal: `MaterialType` carries an explicit damage value
  (`GOLD_DUST` is ordinal 6 but meta 51, `SILICON` ordinal 8 but meta 5). Read it from the
  constructor arguments in `<clinit>`, not from the declaration order.

First use of it, `scripts/ae2_base.zs`: AE2's printed logic circuit now costs a GregTech
**gold plate** instead of a gold ingot, the printed engineering circuit a GregTech **diamond plate**
instead of a diamond, and duplicating any of the four processor presses costs a GregTech **steel
block** instead of an iron block. Verified by reading AE2's registry back after the scripts ran:

```
out=material:18 (Printed Logic)        in=gregtech:meta_item_1:12026   (GT gold plate)
out=material:17 (Printed Engineering)  in=gregtech:meta_item_1:12111   (GT diamond plate)
out=material:13/14/15/19 (presses)     in=gregtech:meta_block_compressed_11:8  (GT steel block)
```

`crafttweaker.log` stays at 0 errors; the AE2 additions do not show up in its recipe count because
they go through AE2's own registry rather than CraftTweaker's shaped-recipe list.

### The rest of AE2's chain (same pass)

AE2's storage family and machine blocks are ordinary crafting recipes, and every one of them spends
plain vanilla iron. All 29 that are full 3x3 grids were rewritten - the four storage and fluid
component housing chain, the eleven storage / fluid / spatial cells, the empty housing, the blank
pattern, and the machine blocks (drive, chest, crafting unit, charger, energy acceptor, molecular
assembler, inscriber, condenser, interface, fluid interface, I/O port, spatial I/O port, security
station, vibration chamber, cell workbench, quantum ring) - plus AE2's quartz glass.

**The rule the owner asked for was "do not make any of it easier", so the rewrite is constrained:**

* every change is `ingotIron` -> a GregTech **iron plate** (meta 12033), one plate per ingot, so the
  metal cost is identical and only the *route* changes (a GregTech rolling mill or hammer);
* AE2's quartz glass is now made from GregTech **glass plates** instead of vanilla glass, which puts
  every cell and every machine above behind GregTech glass as well;
* no ingredient was dropped and no count was lowered anywhere;
* one recipe got deliberately *dearer*: AE2's empty storage cell has an empty centre slot, and it now
  takes an **LV GregTech circuit**, so a storage housing needs a circuit line behind it.

Where a slot accepted several aliases of the same vanilla item, the rewrite uses the alias with the
widest ore-dictionary entry (`dyeBlue` for lapis, `blockGlass` for glass, `wool`, `chestWood`), so
nothing that used to work stops working - those aliases are the same items, not cheaper ones.

Verified by dumping AE2's recipe registry again after the scripts ran and diffing it against the
pre-change dump: **292 outputs before, 292 after, 30 of them changed**, and every single difference
is one of the three intended substitutions (`ingotIron` -> `plateIron`, `blockGlass` -> `plateGlass`,
the one added `[circuitBasic]`). The eleven cable / bus / panel recipes that also spend iron were
*not* touched: they are not full 3x3 grids, their width cannot be recovered from a dump that lists
ingredients in order, and guessing a width would silently produce a recipe that accepts the wrong
shape - left on vanilla iron rather than guessed at.

### Advanced items: moved off the crafting table entirely

The owner's rule for this pass: an advanced machine or item should have to be **produced by a
GregTech machine**, not merely cost GregTech materials - and that the former is what matters. So 24
AE2 items lose their crafting recipe outright and get an **assembler** recipe instead: the sixteen
ME machines (drive, ME chest, crafting unit, charger, energy acceptor, molecular assembler,
inscriber, condenser, interface, fluid interface, I/O port, spatial I/O port, security station,
vibration chamber, cell workbench, quantum ring) and the eight higher-capacity cells (4k / 16k /
64k storage, 4k / 16k / 64k fluid, 16- and 128-cubed spatial).

In play that means a GregTech assembler and EU are a hard prerequisite for any of them - the
crafting table no longer offers them at all. The materials are untouched: the nine grid slots are
flattened into an input list (which is what an assembler recipe is), nothing is dropped and no
count is lowered, and the vanilla iron is still a GregTech iron plate. Machines additionally carry
an integrated circuit, and EU/t follows how deep the item sits in AE2's tree: **LV 30** for the
first machines and the 4k tier, **MV 120** for the molecular assembler, spatial I/O port, security
station and the 16k tier, **HV 480** for the quantum ring and the 64k / 128-cubed tier.

Side effect, intended: AE2's one-to-one "housing + component" shortcut for those cells goes away
too, because a recipe removal matches on the output. The three entry-level cells (1k storage, 1k
fluid, 2-cubed spatial) keep their crafting recipes - with GregTech iron plates - plus the housing
shortcut, so entry-level AE2 is still reachable without an assembler.

Verified after the scripts ran: **all 24 items report 0 crafting recipes**, the three entry-level
cells report 2 (the crafted one plus the housing shortcut - the pairing is intended), and the
assembler accepted all 24 with no `duplicate or conflict found` and no `Invalid amount of recipe
inputs` line. Total crafting recipes fell from 21 355 to 21 321, which is the 34 recipes that moved.

`crafttweaker.log` after this pass: **299** added recipes, 0 errors.

Still on the table, in the order the evidence is ready:

* **The same "assembler instead of the crafting table" treatment for the other mods' machines** -
  Ender IO's machines through its user XML, Forestry's machines through ModTweaker. The pattern is
  established and the AE2 pass is the worked example: delete the crafting recipe, add an assembler
  recipe with the same materials plus a circuit, tiered by depth in the mod's tree.
* **Forestry's machine recipes** (carpenter, centrifuge, squeezer, fermenter, still) through
  ModTweaker - the handlers are available but the recipes themselves have not been rewritten yet.
* **Ender IO's SAG mill / vat / soul binder** through its user XML.
* **AE2's cable / bus / panel family** (11 recipes): they spend vanilla iron and are not full 3x3
  grids, so they need their width read from somewhere better than the ingredient dump - JEI's
  category data or a per-recipe class check.

## 6h. Advanced machines and items now require a GregTech assembler - 2026-10-12

The rule the owner settled on: an advanced machine or item has to be **produced by a GregTech
machine**, and that matters more than merely costing GregTech materials. So starting with the four
added mods plus AE2, every advanced item's crafting-table recipe is deleted and an **assembler**
recipe takes its place. The crafting table no longer offers them at all, which is the point - a
GregTech assembler (LV at the lowest) and EU are now a hard prerequisite.

`scripts/assembler_1.zs` carries 115 outputs and 168 assembler recipes (one per
crafting variant the mod had):

* **Ender IO** - 57 machine blocks: alloy smelters, SAG mills, simple furnace, enchanter, farming
  station, painter, reservoirs, slicer, soul binder, powered spawner, vats, wired / wireless
  chargers, transceiver, vacuum chest, XP vacuum, Niard, travel anchor, tele pad, dialing device,
  impulse hopper, crafters, gauge, power monitors, Killer Joe, electric light, the five obelisks,
  inventory panels and chests, detector block. Ender IO's own "upgrade to the next tier" recipes
  moved into the assembler too.
* **Forestry** - 26 machines: carpenter, centrifuge, squeezer, fermenter, moistener, still, rain
  tank, analyzer, thermionic fabricator, rainmaker, bottler, habitat former, trade station,
  database, the three engines, the farm frame and the peat bog, and the seven alveary parts. What
  stays craftable is the sturdy casing, the apiary, the mailbox, the farm blocks, the cans, the
  stamps and the goggles.
* **AE2** - 23 more: energy cell, dense energy cell, crafting storage 1k/4k/16k/64k, crafting
  monitor, controller, spatial pylon, the four wireless terminals, wireless access point, view
  cell, portable cell, matter cannon, colour applicator, entropy manipulator, charged staff, sky
  compass, memory and biometric card.

Materials are untouched - the grid slots are flattened into an input list (which is what an
assembler recipe is), nothing is dropped, no count is lowered. Every recipe additionally takes an
integrated circuit, and EU/t follows the item's depth in its own tree: Ender IO / Forestry
`simple` and untiered -> LV 30, `normal` / `advanced` -> MV 120, `enhanced` -> HV 480; AE2 1k and
the basic machines -> LV, 4k -> MV, 16k / controller / spatial pylon -> HV, 64k -> EV.

**The one real trap in this pass, worth remembering:** *CraftTweaker applies all `recipes.remove`
calls before all `recipes.add*` calls.* A removal in a later script therefore **cannot** delete a
recipe an earlier script added, no matter the load order (the load order was confirmed correct -
`integration.zs` then `ae2_base.zs` then `assembler_1.zs` - and
the crafted Forestry machines still survived). The first run of this pass failed exactly that way:
all 24 Forestry machines still had a crafting recipe. The fix is to delete those `addShaped` blocks
from the source: 24 of them came out of `integration.zs`, and the AE2 machines and
advanced cells were already handled that way in `ae2_base.zs`. If a future change wants to
take a scripted recipe away, delete it where it is written - do not try to remove it later.

Verified after the scripts ran: a probe over all 115 outputs reported
`moved-to-assembler: 115 ok, 0 still craftable`; the GT log contains no `duplicate or conflict
found` and no `Invalid amount of recipe inputs`; `crafttweaker.log` reports 0 errors. The crafting
recipe count fell 21 355 -> 21 133 over the whole exercise.

### The AE2 leftovers, and why they were easy in the end

The eleven AE2 recipes that spend vanilla iron and are **not** full 3x3 grids turned out not to need
their width at all: an assembler recipe's inputs are an unordered list, so flattening a shaped recipe
into one loses nothing but the arrangement. That removed the only reason they had been left alone.
Seventeen more outputs moved to the assembler in the same section of `assembler_1.zs`:

* the **bus / panel / emitter family** - `part:240/241` (level emitter and its energy variant),
  `part:260/261` (storage monitor and its energy variant), `part:300/320` (the import/export/storage
  bus pair) - LV for the plain ones, HV for the "energy" ones;
* the **card family** - `material:25` (basic card) and `28` (advanced card), which both produce
  **two**, plus the upgrades `26/27/29/30/31` and the crafting / pattern-expansion cards `53/58` - MV
  for the advanced half;
* the **wireless pair** - `material:41` (wireless receiver) and `42` (wireless booster).

Two small items were *not* moved: AE2's Quartz Fixture and Light Detector are two-item lamp recipes,
so they are re-costed in place with a GregTech iron plate and re-added shapeless (same two items,
any arrangement) rather than dragging a lamp through an assembler.

Two problems were caught before they shipped:

* **Duplicate recipes.** Two of the bus shapes fold into the same input list, so the generated
  assembler recipes would have been byte-identical and GregTech would have logged
  `duplicate or conflict found`. Deduplicating the flattened input lists to one recipe per distinct
  set fixed it - and the verification run shows no conflict line.
* **Lost output counts.** Flattening a shaped recipe drops its output count unless it is carried
  over, and the first generation of this whole assembler pass quietly emitted one item where the mod
  produces four: `enderio:block_reservoir` and `block_omni_reservoir` both produce **4**. Both were
  corrected to `.outputs(<...> * 4)`. Anything regenerating these recipes from a dump must carry the
  `xN` over.

Final state of the assembler pass: **132 outputs assembler-only** (115 + 17), 2 re-costed in place,
185 assembler recipes across `assembler_1.zs` and `ae2_base.zs`. A probe over
all 134 outputs reported the assembler-only ones at 0 crafting recipes and the two lamps at 1, which
is the intended split. `crafttweaker.log`: 277 added recipes, 0 errors; the crafting recipe count is
now 21 114, down from 21 355 when this exercise started.

Still open: the deliberately-kept crafting recipes listed above (basic AE2 parts, the Forestry
casings / apiary / farm blocks / cans / stamps, the Iron Chests and Storage Drawers families), and
Galacticraft / Galaxy Space, whose own machines were replaced by GregTech rather than moved into it.

## 6i. Galacticraft's compressed plates were sharing ore dictionary names with GregTech's - 2026-10-12

The owner spotted this one: "dense" plates and GregTech's plain plates could be used
interchangeably. They were right, and it is a genuine loophole rather than a display problem.

Galacticraft registers its **compressed** copper / tin / steel / bronze / iron plate under the
plain ore dictionary names as well as under its own `compressedX` names, and Galaxy Space does the
same with its cobalt / nickel plates, so each of those names held two very different items:

```
plateCopper -> [galacticraftcore:basic_item:6   (compressed: 2 GregTech plates + TNT),
                gregtech:meta_item_1:12018      (one plain plate)]
```

A recipe written as `<ore:plateCopper>` therefore accepted either. Excluding the wasteful direction
(building a GregTech machine out of a two-plate compressed plate), the real problem is the other
one: a Galacticraft / Galaxy Space recipe that was meant to need the compressed plate could be
satisfied with a single cheap GregTech plate, skipping the implosion compressor that the pack uses
to make compressed plates at all.

Measured before the fix, with a probe that flags any ingredient matching both a Galacticraft /
Galaxy Space item and a GregTech item: **52 GC/GS crafting recipes** were in that position, and nine
of the shared names held both an obtainable compressed plate and an obtainable plain one
(`plateCopper`, `plateTin`, `plateSteel`, `plateBronze`, `plateIron`, `plateTitanium`, `plateDesh`,
`plateCobalt`, `plateNickel`).

`scripts/oredict.zs` takes the mods' plates back out of those nine names:

```zenscript
oreDict.get("plateCopper").remove(<galacticraftcore:basic_item:6>);
... one line per name ...
```

so `plateX` now means GregTech's plate and nothing else. Galacticraft's own recipes already ask for
`compressedX` (its own name), which is untouched; Galaxy Space's recipes that asked for the generic
name now get GregTech's plate, which is what the generic name means. **Nothing becomes cheaper**: the
plain GregTech plate was already an accepted input before, so the minimum cost of every affected
recipe is unchanged - what disappears is the ambiguity, and with it the ability to spend a compressed
plate where a plain one was meant. The pack's own implosion-compressor recipes
(`gc_processing.zs`) also become unambiguous, which is what they were written for.

**The file has to load first, and that is not cosmetic.** CraftTweaker resolves `<ore:...>` into a
concrete ingredient when it *applies* a recipe action, in script order, so the dictionary must be
corrected before any of the pack's own recipes are built; with a `zz_` name they would keep the old,
ambiguous ingredient list. (Mod-registered recipes are unaffected by ordering - Forge's
`OreIngredient` reads the dictionary lazily on first use - so Galacticraft's and Galaxy Space's own
recipes pick the change up too.)

**The separation alone is not the whole fix, and the owner caught that too.** Taking the compressed
plate out of the shared name stops a recipe from *wasting* a compressed plate, but it also means a
recipe that was written against the generic name now gets the cheap plain plate - and Galaxy Space's
machine frames, batteries, jetpack, space-suit parts and rocket modules were written meaning
Galacticraft's compressed plate all along. Left there, twenty-odd machines would have quietly become
cheaper. So the 23 Galaxy Space recipes that used a shared plate name are rebuilt against the
compressed item they always meant, in the "Galaxy Space machines that must keep the compressed
plates" section of `gs_removals.zs` - the grids are the mod's own (read off a live dump
before the dictionary was corrected), with only the plate token changed:

```
<ore:plateSteel>   -> <ore:compressedSteel>                 (Galacticraft's compressed plate)
<ore:plateCobalt>  -> <galaxyspace:compressed_plates:1>     (Galaxy Space's own plate)
<ore:plateNickel>  -> <galaxyspace:compressed_plates:3>
```

The pack's own two re-additions follow the same rule: the astro miner base's filler slot and the
Galaxy Space rocket assembler's tooling slot now take `compressedSteel` / `compressedTitanium`
instead of the plain plates they had been given, so the rocket parts still cost what they should.

Verified by re-running the probe: all nine names now list **only** the GregTech plate, and of the 25
recipes that had been drawing from a shared plate name, **24 are clean and 1 still reports a mix -
`galaxyspace:modern_battery`, and its mix is `dustSulfur`** (Galaxy Space's sulfur dust and
GregTech's are the same material, so that is not a discount). Beyond those, 27 recipes still touch a
shared *ingot* or *dust* name: `ingotCopper`, `ingotTin`, `ingotAluminum`, `ingotTitanium`,
`ingotCobalt`, `ingotNickel` and friends, where Galacticraft's / Galaxy Space's copies have no
crafting recipe any more (the desh and lead ingots do, but it is a one-to-one bridge from GregTech's
ingot, so the two are genuinely equivalent). Those entries are a display wart in JEI, not an exploit,
and are left for now.

### The rest of the shared names: ingots, dusts and blocks

With the plates settled, a probe walked **every** ore dictionary name that holds both a GregTech
item and a Galacticraft / Galaxy Space item, and asked of the mod's item: does anything still make
it? (Any surviving crafting recipe or furnace recipe counts.) That splits the leftovers in two, and
they are treated differently on purpose:

| Group | Examples | Treatment |
| --- | --- | --- |
| **The mod's copy has no source at all** | Galacticraft's copper / tin / aluminium / silicon blocks, its desh / titanium / lead blocks, its titanium dust | taken out of the shared name - nothing a player can hold, so the extra JEI entry only offered a choice that cannot be made |
| **The mod's copy is obtainable and is the same material** | Galacticraft's copper, tin, aluminium, meteoric-iron, desh, lead and titanium ingots (smelted from its own ores; desh and lead also convert one-to-one from GregTech's ingot), Galaxy Space's cobalt / magnesium / nickel ingots (smelted from its ores), the sulphur and aluminium dusts | **left in place**, deliberately - an ingot is an ingot and a dust is a dust, so `<ore:ingotCopper>` taking either is correct rather than a discount, and several of those entries are what Gregicality's own ore-processing recipes hand out (removing them would leave those recipes producing an item nothing can use) |

So the earlier guess that the ingot entries were "unobtainable, therefore harmless" was wrong: they
*are* obtainable, by smelting the mods' own ores. They are simply the same metal, which is why they
stay - the thing that made the plates special is that Galacticraft's compressed plate is a
*different, more expensive item* (two GregTech plates plus TNT) wearing the same name.

Verified after the change: `blockCopper`, `blockTin`, `blockAluminium`, `blockSilicon`,
`blockTitanium`, `blockDesh`, `blockLead` and `dustTitanium` no longer appear in the shared list at
all, and the names that remain there are the ore blocks (mined rather than crafted, so the probe
mislabels them), the equivalent ingots and dusts, and Galaxy Space's decorative wood.

### Unifying every ingot and dust on GregTech

With the plates and the leftovers sorted, the pack owner asked for the rest of the ore dictionary to
be unified on GregTech too: other mods' **ingots and dusts** should stop sharing names with it. The
same offline cross-reference produced 27 names holding both a GregTech item and another mod's item,
and `oredict.zs` now cuts each down to the GregTech item - 33 removals in all:

| Mod | Taken out of |
| --- | --- |
| Forestry | `ingotCopper`, `ingotTin`, `ingotBronze`, `dustAsh` |
| Ender IO | the copper / tin / coal / lapis / obsidian / cobalt powders, plus its gold, iron and nether-quartz dusts |
| AE2 | its certus, nether quartz, ender pearl, iron, gold and wheat dusts |
| Galacticraft | `ingotAluminum`, `ingotMeteoricIron`, its aluminium dust |
| Galaxy Space | `ingotCobalt`, `ingotMagnesium`, `ingotNickel`, its sulfur dust |

Nothing is deleted - the mods' items stay obtainable from their own recipes, and a recipe naming one
by its exact id still works. What changes is that `<ore:ingotCopper>` or `<ore:dustIron>` now means
the GregTech item. Two consequences, both intended and documented in the script: a mod recipe that
produced one of those items (Gregicality's dust recipes handed out Galacticraft's aluminium dust)
still produces it, but generic `<ore:...>` recipes no longer accept it; and anything that used to be
fed with the mod's copy now needs GregTech's, which for a powder means GregTech's macerator. The
names holding only GregTech plus vanilla Minecraft (`ingotIron`, `dustRedstone`, `dustGlowstone`)
are left alone, because vanilla's item *is* the GregTech item there.

Verified by a probe that walked every `ingot*` / `dust*` name: **2972 unified on GregTech, 0 still
sharing**. The same probe also checks for recipe slots that nothing can fill - it reports 548, and
those are pre-existing rather than caused by this change: a removal only ever touches a name that
keeps a GregTech item, so no ingredient can lose its last member. The 548 are Gregicality's
`gem_to_gem` family (recipes asking for a flawed-gem name that was already empty), vanilla's
`mapextending`, and GT's own NBT-keyed recipes; they were in the very first audit before any of this
work.

`crafttweaker.log` stays at 0 errors (300 added recipes after the 23 rebuilds).

## 6j. The aluminium spelling gap, and the two plates that have no GregTech twin - 2026-10-12

The plate pass above sorted the nine names Galacticraft and Galaxy Space were contesting, and left
three names behind. They were left for a reason and they were revisited for the same reason, because
"the name has no GregTech member" turns out to describe two different situations:

| Name | Held | GregTech's equivalent | Treatment |
| --- | --- | --- | --- |
| `plateAluminum` | GC's compressed aluminium plate | `plateAluminium` - a *different spelling* of the same name | **unified** |
| `blockAluminum` | GC's aluminium block | `blockAluminium` | **unified** |
| `dustAluminum` | GC's aluminium dust | `dustAluminium` | **unified** |
| `plateCoal` | Galaxy Space's compressed coal plate | none - GregTech has no coal plate | left alone |
| `plateMagnesium` | Galaxy Space's compressed magnesium plate | none - GregTech stops at ingot / dust / block for magnesium | left alone |

The first three are not "a name GregTech does not have" - they are the *American spelling* of a name
it does have. GregTech registers `plateAluminium` / `blockAluminium` / `dustAluminium`; Galacticraft
registers its compressed plate and its dust as `compressedAluminum` **and** as `plateAluminum` /
`dustAluminum`. Nothing ever met, so nothing was ever removed, and the ore dictionary ended up with
two names for one metal pointing at two different items: `<ore:plateAluminium>` was one GregTech
plate, `<ore:plateAluminum>` was Galacticraft's compressed plate - two GregTech plates plus TNT.

That is now closed the same way the other nine names were, in `oredict.zs`: the mod's
item comes out of the bare name (it keeps `compressedAluminum`, which is what Galacticraft's own
recipes ask for, and which `gc_crafting.zs` rebuilds them against) and the GregTech item goes
in. Both spellings of each name now answer with the same item.

Measured before the change with a probe that walks every *finished* crafting recipe and every
GregTech machine recipe: **no recipe anywhere consumed `<ore:plateAluminum>`, `<ore:blockAluminum>` or
`<ore:dustAluminum>`**. Every Galacticraft recipe that touches the compressed plate asks for
`compressedAluminum` (its own name), and the only recipes that mention the dust are Gregicality's
recycling pass, which *produces* it. So the unification moves no cost: it removes a name that
silently meant the expensive item, and leaves the item itself reachable - by id, and under the name
Galacticraft actually uses.

Verified after the change, on the same probe:

```
name plateAluminum   -> gregtech:meta_item_1:12001      (GregTech aluminium plate)
name plateAluminium  -> gregtech:meta_item_1:12001
name blockAluminum   -> gregtech:meta_block_compressed_0:1
name blockAluminium  -> gregtech:meta_block_compressed_0:1
name dustAluminum    -> gregtech:meta_item_1:2001       (GregTech aluminium dust)
name plateCoal       -> galaxyspace:compressed_plates:0 (unchanged, no GregTech twin)
name plateMagnesium  -> galaxyspace:compressed_plates:2 (unchanged, no GregTech twin)
```

Everything else touched by this pass reads back clean too: `plateIron` / `plateCopper` / `plateSilver`
/ `plateGold` / `plateDiamond` / `plateGlass` / `plateEmerald` / `plateWood` / `plateCobalt` /
`plateNickel` each resolve to the GregTech item and nothing else, so every name the new assembler
recipes below draw on is unambiguous.

## 6k. Iron Chests and Storage Drawers: the advanced half goes into the assembler - 2026-10-12

Section 6h took 132 advanced machines and items off the crafting table and into a GregTech
assembler. Two of the four new mods were only partly covered by it, and this is the rest: the owner's
rule is that an advanced item must be *produced by* a GregTech machine, not merely cost GregTech
materials, so an item is either on the crafting table or in the assembler, never both.

Where the line falls, and why:

| Family | Stay on the crafting table | Move to the assembler | EU/t |
| --- | --- | --- | --- |
| Iron Chests tiers | copper (3), iron (0), dirt (7) | silver (4), gold (1), diamond (2), crystal (5), obsidian (6) | LV / LV / MV / HV / HV |
| Iron Chests chest upgrades | wood→copper, wood→iron, copper→iron | copper→silver, silver→gold, iron→gold, gold→diamond, diamond→crystal, diamond→obsidian | LV / LV / LV / MV / HV / HV |
| Iron Chests shulker boxes (16 colours) | tiers 0 and 3 only | tiers 1, 2, 4, 5, 6 - the same five tiers as the chests | LV / MV / LV / HV / HV |
| Iron Chests shulker upgrades | vanilla→iron, vanilla→copper, copper→iron | the six that lead above the iron tier | LV / LV / LV / MV / HV / HV |
| Storage Drawers blocks | drawers, trims, framed variants, upgrade template | compacting drawer, controller, controller slave, framing table | LV |
| Storage Drawers storage upgrades | the obsidian "1x" upgrade | 2x (iron) and 4x (gold) LV; 8x (diamond) and 16x (emerald) MV | LV / MV |

The iron chest is the mod's namesake and its entry point and the copper chest is the step below it,
so those two stay hand-craftable and everything above iron needs a machine. The shulker boxes are the
same chests in portable form - the same seven tiers, built from the same plates - so leaving them on
the crafting table would have been a way around the gate for exactly the tiers that were just gated;
they move with the chests, through the same colour loop that used to shape them. On the Storage
Drawers side the four blocks that are machines rather than furniture are the ones that already needed
a GregTech circuit or a GregTech screw to exist, and a drawer that holds 8x or 16x of a stack is not
a hand tool.

**Nothing was made cheaper, and nothing was made dearer.** Each grid was moved verbatim: an assembler
recipe is a flat input list, so the plates that filled several shaped slots are merged and multiplied
(three along the top plus one in the centre is `* 4`, not `* 3`), and every count was read back off
the grid it replaces rather than recomputed. The only additions are the two this pack gives every
assembler recipe - the integrated circuit and the EU/t.

One CraftTweaker trap is worth writing down, because it cost a run. **A top-level `val` is local to
its own `.zs` file.** `integration.zs` declares `PlateSilver`, `ScrewGold`, `Obsidian`
and friends, and using them from `assembler_1.zs` does not resolve:

```
assembler_1.zs:1462 > No such static member in crafttweaker.item.IIngredient: PlateSilver
```

ZenScript reports one error per use and then discards **the whole file** - and the silent half of
that is worse than the error: the 168 assembler recipes that were already in it disappeared with it,
and `crafttweaker.log` showed 0 shaped recipe additions for the entire pack. The assembler file now
uses the literal `<ore:...>` / `<gregtech:meta_item_1:...>` ingredients it was already using
everywhere else.

Verified with a temporary probe that walks the finished recipe registries at the first server tick
(a CraftTweaker probe cannot do this - it runs while the script is being evaluated, before the
recipe actions are applied):

```
PROBE moved-to-assembler: 105 ok, 0 still craftable
PROBE assembler total outputs=1329 recipes=4481
Invalid recipe: 2      (the same two Gregicality / GregTech loaders as every run since the port)
duplicate or conflict: 0
```

105 is every output this pass claims to move (5 chests + 12 chest upgrades + 16x5 shulker boxes + 4
drawer blocks + 4 storage upgrades). For each one the probe reports `crafting=0` *and* at least one
assembler recipe, and the assembler recipes for those outputs sum to **153** - exactly the number of
crafting-table recipes that left `crafttweaker.log` (292 shaped adds before, 139 after, plus the same
8 shapeless). What stayed behind is equally explicit: `iron_chest` 0/3/7, the three low upgrades,
shulker tiers 0 and 3 for all sixteen colours, every drawer, trim and framed part, the upgrade
template, the obsidian 1x storage upgrade and the drawer keys each still have their one shaped
recipe, and `storagedrawers:controller`, `:controllerslave`, `:compdrawers` and `:framingtable` have
none.

The test procedure is in section 6h's trap list and was followed to the letter: the world is removed
before each run, the server is started headless, and the run is accepted on `Done (x.xxxs)` with 47
mods, 0 `crafttweaker.log` errors and no new GregTech `Invalid recipe` lines.

## 6l. Silicon: the three mods' items are discarded, GregTech's silicon is the only one - 2026-10-12

The owner's instruction: *"硅的合成，GC、EIO、AE 自带的硅直接舍弃，合成也舍弃"* - and, in the same
breath, the clarification that when they say "unify onto GregTech" they mean **removing the other
mods' entries from the ore dictionary**, not adding new ones.

Silicon was in exactly the state that rule is aimed at. `itemSilicon` - the name every cross-mod
recipe in the pack reaches for - held three foreign items and **no GregTech one at all**:

| Member of `itemSilicon` | Whose | Where its silicon came from | Treatment |
| --- | --- | --- | --- |
| `appliedenergistics2:material:5` | AE2 | a furnace recipe, quartz powder in | **discarded** (item removed from the name, 3 furnace recipes deleted, hidden from JEI) |
| `galacticraftcore:basic_item:2` | Galacticraft "raw silicon" | no crafting recipe of its own | **discarded** (removed from the name, hidden from JEI) |
| `enderio:item_material:5` | Ender IO | the SAG mill's `itemSilicon` outputs | **discarded** (removed from the name, hidden from JEI) |
| `gregtech:meta_item_1:10061` | **GregTech** - its silicon *ingot* | GregTech's own chain | **the one that stays** |

Two things made this more than a one-line dictionary edit.

First, **the name cannot simply be emptied.** Galacticraft's own config literally points its silicon
recipes at the ore dictionary name (`S: "OreDict name of other mod's silicon"=itemSilicon`), Ender IO's
XML recipes all take `<input name="itemSilicon">`, and AE2's inscriber had a printed-silicon recipe
against it. Emptying the name would leave blank slots in all three, silently. So the three foreign
items come out and **GregTech's silicon ingot goes in**: every existing reference now resolves to
GregTech's silicon without a single recipe being rewritten to reach it - which is the owner's
definition of the unification, applied to a name GregTech had never claimed.

Second, **removing the items is not the same as removing the production.** Ender IO's SAG mill
produced silicon *by ore dictionary name*, so left alone it would have gone on making silicon - now
GregTech's, from sand, at 50% - which is a non-GregTech silicon source and a shortcut past GregTech's
own chain. Four recipes had a silicon output; they were split deliberately, because the config switch
is per-recipe and three of them produce something else as their main output:

| SAG mill recipe | Main output | Silicon output | Treatment |
| --- | --- | --- | --- |
| `Sagmill: Silicon` (sand) | - | `itemSilicon` @50% | **disabled** in `config/enderio/recipes/user/user_recipes.xml` |
| `Sagmill: ClayBlock` | 2 clay balls | `itemSilicon` x2 @80% | left on - now yields GregTech silicon |
| `Sagmill: oreRedstone Ore` | 8 redstone dust | `itemSilicon` @80% | left on - now yields GregTech silicon |
| `Sagmill: Nether Redstone Ore` | 21 redstone dust | `itemSilicon` x2 @80% | left on (the recipe does not even exist here - no `oreNetherRedstone`) |

Disabling the last three would have taken the clay balls and the redstone grinding with them, which the
owner did not ask for; they now hand out GregTech's silicon as a byproduct instead. The dedicated
sand-to-silicon recipe, whose only purpose was to make silicon, is gone. Ender IO's disabled-recipe
file is the only way to reach these - they are registered from XML after CraftTweaker has run, which
is the trap section 6e documents.

Verified with a probe that reads the **finished** registries at the first server tick (a CraftTweaker
script cannot: it runs while the script is still being evaluated) and that also reflects into Ender
IO's own SAG-mill recipe manager, which no script can see:

```
name itemSilicon -> gregtech:meta_item_1:10061          (GregTech silicon ingot, and nothing else)
crafting  producers of any of the three mod items: 0
furnace   AE2 silicon smelting recipes: 0               (3 removed)
sagmill   183 recipes total, 2 touch silicon            (was 4)
          clay        -> clay balls + gregtech:meta_item_1:10061 x2 @0.8
          redstone ore-> 8 redstone dust + gregtech:meta_item_1:10061 @0.8
```

The two recipes that used to eat `itemSilicon` on the crafting table - Ender IO's photovoltaic powder
and its awareness upgrade - now match **only** `gregtech:meta_item_1:10061`; before, they matched all
three mod items. Everything else in the probe's consumer list is GregTech's or Gregicality's own
silicon (plate, dust, nugget, block) recipes.

Our own scripts were made explicit at the same time: the five assembler recipes and three alloy /
mixer recipes that asked for `<ore:itemSilicon>` now ask for `<ore:ingotSilicon>`, the name the
Galacticraft wafer recipes were already using, and AE2's printed-silicon inscriber recipe was
rewritten against it too. The shared name still resolves to GregTech's silicon, so anything that
reaches for it - Galacticraft's own code included - lands on the same item.

Running total: `crafttweaker.log` unchanged at 139 shaped + 8 shapeless script recipes and 0 errors;
the engine still reports exactly the two baseline GregTech / Gregicality `Invalid recipe` lines and no
`duplicate or conflict`.

## 6m. Power: the generators are not the leak, the exchange is - 2026-10-12

The owner's rule for power is *"not that easy"*, not *"gone"*, so this pass is deliberately smaller than
a GTNH-style clearing-out. It has two halves.

### The generators

| Mod | Its own generators | State |
| --- | --- | --- |
| Galacticraft | coal generator, basic / advanced solar panel, Venus solar array + module, geothermal generator, beam receiver | deleted (recipes + JEI) in `gc_removals.zs` |
| Galaxy Space | its generators and the Modern Energy Cluster | deleted in `gs_removals.zs` |
| Ender IO | stirling / combustion / lava / zombie generators, solar panel | deleted in `integration.zs` |
| Forestry | `engine_peat`, `engine_biogas`, `engine_clockwork` | **kept, re-costed** in `assembler_1.zs` |

The Forestry engines used to be LV 30 assembler recipes out of copper and bronze gears and three
ingots - copper-age power. They are now:

* `engine_peat` - MV 128 EU/t, 3 GregTech **steel** plates + piston + LV circuit + glass + 2 copper ingots;
* `engine_biogas` - MV 128 EU/t, 4 steel plates + piston + LV circuit + glass + a cauldron;
* `engine_clockwork` - **HV 480 EU/t**, 4 **stainless steel** plates + piston + MV circuit + glass + a clock.
  It is the one that needs no fuel at all, which is why it is priced a tier above the other two.

They stay cheap to *fuel* - that is what Forestry is for - but the block that turns fuel into power
now needs a real rolling line, not three copper ingots.

### The exchange

The generators were never the whole story. Gregicality ships two mirrored converter families, one
machine per GT tier and per amperage size (1 / 4 / 9 / 16 A):

* `convert_gteu.<tier>.<amps>` - "GTEU Energy Converter" - **EU to FE**: GregTech power being spent
  on the mods' machines. Harmless: it is paying out, and FE cannot come back by itself.
* `convert_forge.<tier>.<amps>` - "Forge Energy Converter" - **FE to EU**: the direction that makes
  power too easy. An RF generator anywhere in the pack becomes a GregTech generator with one extra
  block bolted on.

> **Corrected 2026-10-15 (6cl).** These two lines were the other way round for a day: the machine
> called "GTEU Energy Converter" is the EU-to-FE one and "Forge Energy Converter" is the FE-to-EU one.
> The names are written from the *input* side, and the mod says so itself - the machine's tooltip is
> built from its own input and output and reads "Converts GTEU to FE". The rule below is what the pack
> wants; the first version of `power.zs` put the ceiling on the opposite family, which both removed the
> safe direction above HV and left the arbitrage one craftable at every tier. 6cl is the measurement.

The owner's rule for the exchange, in their words: *"not a bad deal, a balanced one - a little easier
than GregTech's own generation, but it must not carry you through every voltage"*. So the exchange
rate is deliberately **not** punitive and the gate is a **ceiling**, not a penalty:

1. **`config/gtadditions.cfg` pointed the wrong way, and now does not.** As shipped in this instance
   the block read `Disable GregTech EU to FE Energy Converters?=true` and `Dusable FE to GregTech EU
   Energy Converters?=false`, i.e. the *safe* direction was switched off and the *arbitrage* direction
   was switched on. The two booleans are read by Gregicality's `EnergyConverterType.isDisabled()`
   (checked in the jar: they gate whether a converter *works*, not whether it is registered), so that
   was a live hole. `Disable GregTech EU to FE ...` is now `false`. `EU/FE Ratio` stays **4.0** - the
   same ballpark as GT New Horizons' published 1 EU = 3.6 RF - because the exchange is meant to be a
   legitimate, slightly convenient route early on, not a punishment.
2. **FE to EU exists up to HV and stops there.** `scripts/power.zs` removes the
   crafting recipes of the `convert_forge` machines for **EV, IV, LuV, ZPM, UV, UHV, UEV, UIV and UMV**
   (35 blocks, ids `gregtech:machine:2933..4104`, the *second* member of each (tier, amperage) pair,
   because Gregicality registers the EU-to-FE machine of a pair first) and hides them
   from JEI. **ULV, LV, MV and HV keep theirs, and the EU-to-FE family is untouched at every tier.**
   An RF-driven base is therefore a perfectly good way
   to run the early and middle tiers - slightly easier than building GregTech's own generation, which
   is the point of having the RF mods - and from EV upward the player has to have built real GregTech
   power. Moving the ceiling is moving those lines: keeping a tier means deleting its block in that
   file, stopping a tier earlier means adding one.

**The converters themselves were left priced as Gregicality ships them, because they are not the cheap
part.** The probe printed their recipes straight out of the registry: each one is a machine hull of its
own tier plus eight tier cables plus that tier's circuit, e.g. EV 1 A = `gregtech:machine:504` +
8x `cableGtSingleAluminium` + `cableExtreme`-class circuit (with 4 / 8 / 16 cables for the 4 / 9 / 16 A
variants). That is real industry at every tier it exists in, so the ceiling - not a re-cost - is what
does the balancing.

If it should instead be impossible at every tier (GTNH's rule: *"The reverse is not possible; RF cannot
be converted to EU"*), the single line to flip is `Dusable FE to GregTech EU Energy
Converters?=true`; the ULV-HV blocks in `power.zs` would then need deleting as well.

**What was deliberately not touched**, and why: Galacticraft's and Galaxy Space's own wires / batteries
and AE2's Energy Acceptor. Those are the *consumption* side - they move FE inside the mods' own
ecosystem, and with RF to EU gated they cannot leak into GregTech progression at all. Deleting them
would have stranded the mods' machines (Forestry's carpenter still needs RF, and AE2's Energy Acceptor
is how AE2 is fed) without making anything harder.

Verified with a probe that reads the finished registry on the first server tick:

```
PPROBE engine forestry:engine_peat:0      <- steel plates x3 + piston + circuitBasic + glass + copper x2  (128 EU/t, 400 ticks)
PPROBE engine forestry:engine_biogas:0    <- steel plates x4 + piston + circuitBasic + glass + cauldron  (128 EU/t, 400 ticks)
PPROBE engine forestry:engine_clockwork:0 <- stainless x4 + piston + circuitGood + glass + clock         (480 EU/t, 600 ticks)
XPROBE end (16 FE-to-EU converters craftable)   <- ULV, LV, MV, HV only; EV and up removed
XPROBE convert_gteu.ev.1 -> machine:2932 : [cableGtSingleAluminium]x8 [chest] [machine:504] [circuitExtreme]
XPROBE EU->FE untouched: all tiers
```

> The two `XPROBE` labels above are the pre-6cl reading of the names, and they are the reason `power.zs`
> removed the family it removed. What the probe *measured* is which ids answer with a crafting recipe;
> the direction words it attached to them are the assumption 6cl corrects (the family it called FE-to-EU
> is the EU-to-FE one). The probe's own id/name pair (`convert_gteu.ev.1 -> machine:2932`) was right,
> and that half - the id-to-name mapping - is what 6cl went on to use.

The ceiling is the whole point of the change: the early and middle tiers can be run off RF, and from
EV on the pack is back to GregTech generation only.

## 6n. Galacticraft's wiring: the item stays, the crafting got the GregTech treatment - 2026-10-12

The owner asked what happens to Galacticraft's and Galaxy Space's wires now that their generators are
disabled, and then settled the point: *the item is fine, the crafting was too easy.* Both halves are
true, and they are answered separately.

**The wire cannot be deleted.** Galacticraft's `aluminum_wire` is not only a cable: scanning the jar,
24 recipe files mention it and only 5 of those are the wire's own recipes - the other **19 consume it
as a material**, including the machines this pack deliberately keeps (the `machine2` electric
machines, `enclosed:14/15`, `basic_item:0`, the air-lock and oxygen-logistics family). Deleting the
wire would strand the life-support and rocket-logistics machines, which is the opposite of balancing a
pack. Galaxy Space, for its part, has no wires at all - the jar has no wire or cable classes, only
generators, solar/wind panels, storage and a charging pad, and all of those are already removed.

**What the wire is for now.** Galacticraft machines accept Forge Energy, GregTech power reaches them
through the EU to FE converter (or Gregicality's native EU-to-FE), and the wire is how a base
distributes that power. With FE to EU capped at HV (section 6m) and every RF generator in the pack
deleted, cheap wiring cannot leak into GregTech progression: it is consumption-side equipment, in the
same class as AE2's Energy Acceptor.

**The crafting is what changed, and the owner then asked for all of it.** The base recipe,
`aluminum_wire:0` - 6 wires per craft - used to be 3 aluminium ingots and 6 wool in the crafting grid,
i.e. copper-age wiring. All four wire types are now **GregTech assembler** recipes at **LV
(30 EU/t, 200 ticks)**, and nothing about Galacticraft wiring is left on the crafting table:

| Recipe | Assembled from | Out |
| --- | --- | --- |
| `aluminum_wire:0` | 3 GregTech **fine aluminium wire** (`wireFineAluminium`, what a wiremill makes) + 6 wool | 6 |
| `aluminum_wire:1` | 1 GregTech aluminium ingot + 1 `wire:0` + 1 wool | 1 |
| `aluminum_wire:2` | 1 `wire:0` + 1 repeater | 1 |
| `aluminum_wire:3` | 1 `wire:1` + 1 repeater | 1 |

A Galacticraft base therefore needs GregTech wire production - and a GregTech assembler - before it can
be wired at all. One shape collapsed on the way: Galacticraft shipped **two mirrored grid recipes** for
`wire:1` (Z/Y/X and X/Y/Z), and a removal matches on the output, so the single assembler recipe above
replaces both.

Verified with a probe on the finished registries:

```
WPROBE crafting end (0 aluminum_wire recipes left on the table)
WPROBE assembler galacticraftcore:aluminum_wire:0x6 <- [wool]x6 [wireFineAluminium]x3 [circuit] (30 EU/t, 200 ticks; wool=16 colours)
WPROBE assembler galacticraftcore:aluminum_wire:1x1 <- [ingotAluminium]x1 [aluminum_wire:0]x1 [wool]x1 [circuit] (30 EU/t, 200 ticks)
WPROBE assembler galacticraftcore:aluminum_wire:2x1 <- [aluminum_wire:0]x1 [repeater]x1 [circuit] (30 EU/t, 200 ticks)
WPROBE assembler galacticraftcore:aluminum_wire:3x1 <- [aluminum_wire:1]x1 [repeater]x1 [circuit] (30 EU/t, 200 ticks)
```

The wool wildcard was probed against all sixteen colours on purpose: the original JSON used
`data: 32767`, and a wildcard that quietly matched white wool only would have been a silent downgrade
of the recipe rather than a gregging of it. `<minecraft:wool:*>` matches all sixteen.

## 6o. The dense plate was still cheap, and the ore dictionary was not the leak - 2026-10-12

The owner's question: *"why is the dense steel plate still a problem?"* Section 6i had already
separated the ore dictionary names, and the probe confirms that separation is intact - **0** recipe
ingredients anywhere, in the crafting table or in any GregTech machine map, match both a Galacticraft
compressed plate and a GregTech plate:

```
DPROBE crafting end (0 mixed ingredients)
DPROBE machine  end (0 mixed ingredients)
DPROBE name plateDenseSteel -> gregtech:meta_item_1:13184     (GregTech only)
DPROBE name compressedSteel -> galacticraftcore:basic_item:9  (Galacticraft only)
```

So the names were not the answer. The **producers** were. Gregicality unifies a mod's material forms
onto GregTech's machines, and because Galacticraft registers its compressed plates in the ore
dictionary it generated a full set of "make this item out of GregTech material" recipes for them:

| Map | Deleted | What it was doing |
| --- | --- | --- |
| `metal_bender` | 15 | 1 steel **ingot** -> 1 compressed steel plate |
| `alloy_smelter` | 8 | 2 steel ingots + mold -> 1 |
| `forge_hammer` | 8 | 3 steel ingots -> 2 |
| `extruder` | 8 | 1 steel ingot + mold -> 1 |
| `cutting_saw` | 21 | 1 steel **block** -> **9** |
| `fluid_solidifier` | 7 | the same item again |
| **vanilla smelting** | **2** | `plateSteelMagnetic` -> 1 compressed steel plate, `plateIronMagnetic` -> 1 compressed iron plate |
| **total** | **69** | 67 recipe-map entries plus the 2 smelting ones, across all nine Galacticraft compressed plates |

That is why the dense plate stayed cheap however the pack's own recipes were written: the pack's route
(an implosion compressor, **two GregTech plates plus TNT** - `gc_processing.zs`) was competing
with a one-ingot bending recipe that the ore dictionary could not police.

The two smelting entries were the follow-up question ("why are the smelting recipes still there?"), and
they are their own trap: **`FurnaceRecipes` is not one of GregTech's recipe maps**, it is vanilla's own
registry and it is what JEI shows under its "Smelting" tab, so a sweep of the machine maps cannot see
it. The two recipes turned a single magnetic plate into a compressed plate, one step and no TNT:

```
SMPROBE smelt gregtech:meta_item_1:12298 (plateSteelMagnetic) -> galacticraftcore:basic_item:9  (compressed steel)
SMPROBE smelt gregtech:meta_item_1:12297 (plateIronMagnetic)  -> galacticraftcore:basic_item:11 (compressed iron)
```

The guard now sweeps that registry too, on the same output test, and reports the total smelting table
as 22152 -> 22150 - exactly the two entries.

**Why the fix is Java and not a script.** Two reasons, both measured rather than assumed:

1. CraftTweaker's GregTech integration exposes **no** recipe-removal method for a machine map. The
   attempt failed with `No such member in mods.gregtech.recipe.RecipeMap: ccGetRecipeList` - only
   `recipeList` (a getter) and `recipeBuilder` are exposed, and `removeRecipe` takes a Java `Recipe`,
   which ZenScript has no type for.
2. Gregicality registers these in its own init / postInit, which is exactly the case section 6e's rule
   describes: *"a mod which registers after CraftTweaker can only be undone in that mod's own config,
   or through a late removal in the addon (`FMLLoadCompleteEvent`), never through a script."*

So the removal lives in `src/main/java/com/minespace/unofficial/gtceu/MinespaceCompressedPlateGuard.java`
and is called from this mod's postInit **and** again from `FMLLoadCompleteEvent` (idempotent; whichever
call sees the recipes first does the work). The log says which one it was, and that also settles the
JEI question - postInit is before JEI reads the recipe maps, so JEI is clean too:

```
compressed-plate guard (postInit pass): 77 Gregicality-generated compressed-plate producers deleted;
                                        the implosion compressor is now the only route
compressed-plate guard (loadComplete pass): nothing left to remove
SMPROBE end (0 watched smelting recipes)
```

Deliberately kept, and why:

* **the `implosion_compressor` map** - that is where this file's own recipes for these plates live
  (`plateX` x2 + explosives -> the compressed plate). Gregicality also leaves one recipe in that map
  with *empty* item inputs, so it can never match a machine; it is one of the two baseline
  `Invalid recipe` lines.
* **the `electric_implosion` map** - the first version of this guard swept it too, and that was wrong.
  It is the **Electric Implosion Compressor**, Gregicality's "implosion without explosives" machine: a
  **UV multiblock** whose own controller is built in GregTech's **Assembly Line** at 491,520 EU/t over
  48,000 ticks (64 long osmium sticks, 64 osmium rings, 16 UV superconductor wires, 16 UV circuits, 2
  Incoloy-MA blocks and a regular Implosion Compressor). Its recipes turn two plates into one
  compressed plate with **no TNT** - the same material cost as the pack's own route - at 375,000 EU/t,
  which is late-game mass production, not a shortcut. Removing them gutted the machine's reason to
  exist, so that map is now in the guard's keep-list and the run total dropped from 77 to 69 (67 map
  entries + 2 smelting).
* **Galaxy Space's compressed plates** (coal, cobalt, magnesium, nickel) - their GT-machine producers
  are the intended route, documented in 6f/6i ("produced only by GregTech's hammer and flatten
  recipes, which is what Galaxy Space's own machines consume"), so the guard's target list is
  Galacticraft's nine plates only.
* **GregTech's own plates and dense plates** (`metal_bender`: 9 steel plates -> 1 dense steel plate)
  - untouched; that is GregTech's own cost curve.

### Why the Electric Implosion Compressor looked like it had no recipe

It has one - it is just not on the crafting table and not in any script-visible registry. Gregicality
generates its multiblock controllers as **"reverse engineered" recipes** (Disassembler, Electric
Implosion, and friends) and `config/gtadditions.cfg` ships:

```
# Whether or not to have reverse engineered recipes (Disassembler, Electric Implosion, etc.) done before or after CT recipes.
# If True, they will be done after CT, meaning the reversed recipes are not touchable by scripts. If False, it is on the pack maker to fix the recipes manually.
B:"Reverse recipes after CT"=true
```

With that on its default, those recipes land **after** CraftTweaker has finished, so no script can see
or change them - which is why the probe had to read them back from the finished maps in Java, and why
the Electric Implosion Compressor shows no recipe in JEI's crafting tab while being perfectly
obtainable through the Assembly Line:

```
EPROBE machine gregtech:machine:4211 = 'Electric Implosion Compressor' craftingTableRecipes=0
EPROBE machine gregtech:machine:4211 made in assembly_line <-
    [stickLongOsmium]x64 [ringOsmium]x64 [wireGtSingleUvSuperconductor]x16
    [gregtech:meta_item_1:32647]x16 [blockIncoloyMa]x2 [gregtech:machine:2536]x1
    (491520 EU/t, 48000 ticks)
```

Worth remembering for the next "there is no recipe for X": for a Gregicality multiblock, check the
**Assembly Line**, not the crafting table.

## 6p. Galaxy Space's plate family: the machines went, the parts were never rebuilt - 2026-10-12

The owner's question - *"why can't Galaxy Space's other heavy plates and alloy plates be crafted?"* - a
probe answered with six numbers. It walked the crafting table, every GregTech recipe map and vanilla
smelting, for every Galaxy Space item whose display name mentions Plate / Alloy / Compressed:

| Item | Producers before |
| --- | --- |
| compressed coal plate (`compressed_plates:0`) | **0 anywhere** |
| compressed cobalt plate (`:1`) | 2 crafting + 9 map |
| compressed magnesium plate (`:2`) | 0 crafting + 1 map (a fluid solidifier) |
| compressed nickel plate (`:3`) | 2 crafting + 9 map |
| compressed "SDHC-120" alloy plate (`:4`) | **0 anywhere** |
| Heavy Duty Plates (`hdp:0..7`, eight metas) | **0 anywhere** |

The cause is the machine pass itself. Galaxy Space makes its plate family in **two machines this pack
removed**: Galacticraft's Compressor (for the compressed plates) and Galaxy Space's own Assembly
Machine (`galaxyspace:assembly_machine`, removed as "-> GT assembler"). The pass rebuilt GS's *blocks*
against GregTech and never rebuilt these *parts*, so everything without a Gregicality-generated
"material form" cousin lost its only route: coal and magnesium are not materials GregTech makes plates
of, and the SDHC-120 alloy and the Heavy Duty Plates are GS-only items GregTech has never heard of.
Cobalt and nickel survived only because Gregicality generated producers for them - one cobalt ingot in
a bender, a cobalt block into nine plates in a cutting saw, and so on (its own balance question, see
6o). The ore dictionary was not involved at all.

Fixed using **Galaxy Space's own recipes**, read out of its source
(`BlesseNtumble/GalaxySpace`, `.../overworld/recipes/CraftingRecipesOverworld.java`), with GregTech's
compressor standing in for Galacticraft's and GregTech's assembler for GS's:

| GT machine | Recipe | Output |
| --- | --- | --- |
| compressor | 9 coal, or 1 coal block | compressed coal plate |
| compressor | 2 cobalt ingots | compressed cobalt plate |
| compressor | 2 magnesium ingots | compressed magnesium plate |
| compressor | 2 nickel ingots | compressed nickel plate |
| assembler | bronze plate + coal plate + aluminium plate | SDHC-120 alloy plate |

The coal plate matters twice over: it is an ingredient of the alloy plate, so without it the alloy plate
- and every machine that needs it - was unreachable.

Verified after the change:

```
GPROBE galaxyspace:compressed_plates:0    map 2   (was 0)
GPROBE galaxyspace:compressed_plates:2    map 2   (was 1 - a fluid solidifier only)
GPROBE galaxyspace:compressed_plates:4    map 1   (was 0)
```

### Still open: the Heavy Duty Plate chain, and Galacticraft's own plate

Two further links are broken, and they are deliberately **not** guessed at here, because GS builds its
rocket parts from them tier by tier:

* **Galacticraft's Heavy-Duty Plate** (`galacticraftplanets:item_basic_asteroids:5`) - 0 recipes
  anywhere. It was made in Galacticraft's own machine, which this pack removed, so GS's chain cannot
  start.
* **Galaxy Space's Heavy Duty Plates** (`galaxyspace:hdp:0..7`) - 0 recipes anywhere. GS's source
  chains them through its Assembly Machine: `hdp:0` = `plateMagnesium` + the SDHC-120 alloy +
  Galacticraft's Heavy-Duty Plate; `hdp:1` = `plateCobalt` + `hdp:0` + `plateNickel` + dolomite meal;
  `hdp:2` = the alloy + `hdp:1` + volcanic stone. `hdp:3..7` have no recipe even in GS's source,
  although GS builds rocket parts from `HDP:i` per tier.
* Two of those ingredients do not exist under those names in the GS 2.2.0 jar this pack runs - a scan
  of every item's display name finds no "Dolomite Meal" and no "Volcanic Stone"; the closest matches are
  GregTech's `dustDolomite` and Galacticraft's `galacticraftplanets:venus:2` ("Venus Volcanic Rock").
  The chain therefore cannot be transliterated without a decision about those two substitutions and
  about `hdp:3..7`.

## 6q. GregTech's own ores were smelting into the mods' ingots - 2026-10-12

The owner's report: *"also the meteoric iron recipe, and other ores' names display oddly."* A probe over
the finished smelting table found the recipe half of that immediately - and it is the same family of
problem as 6o, in the opposite direction:

```
gregtech:meta_item_1:2136  (GregTech meteoric iron DUST)  -> galacticraftcore:item_basic_moon:0
gregtech:ore_meteoric_iron_0:2 ... (every GregTech meteoric iron ORE) -> galacticraftcore:item_basic_moon:0
```

Gregicality registers a mod's metal as a GregTech *material*, and the ore processing it generates
around that material was handing out the **mod's** copy. Section 6i then took those copies out of the
shared ore dictionary names (`ingotMeteoricIron`, `ingotCobalt`, ...), so the ingot a player got for
smelting GregTech's own ore had become an item nothing accepts any more - hundreds of recipes producing
a dead end. That is also what "the names display oddly" was seeing: GregTech's ore chain was producing
Galacticraft's and Galaxy Space's items.

Fixed in `src/main/java/com/minespace/unofficial/gtceu/MinespaceSmeltRepoint.java`, which maps each
mod's copy of a unified metal to GregTech's item and re-points every smelting recipe that produced one:
the same input, the same yield, the same experience, only the output changes. Eleven mappings cover
meteoric iron, aluminium, copper, tin, desh, titanium, lead, cobalt, magnesium, nickel and the
aluminium dust. It runs from the addon's postInit (and again at load complete, idempotent).

Verified:

```
smelt re-point: gregtech:ore_magnesite_0:6  -> gregtech:meta_item_1:10038 (was galaxyspace:ingots:1)
smelt re-point: gregtech:ore_pentlandite_0:12 -> gregtech:meta_item_1:10044 (was galaxyspace:ingots:2)
smelt re-point: gregtech:ore_lead_0:9       -> gregtech:meta_item_1:10035 (was galacticraftplanets:basic_item_venus:1)
smelt re-point: gregtech:ore_cobalt_1:12    -> gregtech:meta_item_1:10017 (was galaxyspace:ingots:0)
smelt re-point (postInit pass): 890 smelting recipes now yield GregTech's item instead of a mod's copy of the same metal
smelt re-point (loadComplete pass): nothing to change
NPROBE producers: gregtech:meta_item_1:10136 (GregTech meteoric iron ingot) = 110   (was 0)
                  galacticraftcore:item_basic_moon:0 (Galacticraft's)     = 13
```

The 13 that still produce Galacticraft's ingot are its own chains (its block-to-ingot route and the
Gregicality-generated conversions); they are left as they are, because the pack's rule is that a mod's
item stays reachable by id - it just is not what GregTech's ore chain hands out any more.

### The display half of the report

The same probe scanned every registered item's display name for unlocalised keys (`item.xxx.name`)
and found no such entry for any GregTech, Galacticraft or Galaxy Space ore or ingot - the names on
those are real. What it did find is **Forestry's own** missing language entries, which show up as raw
keys in JEI and in tooltips:

```
forestry:ffarm:6..15          tile.for.ffarm.<n>.name
forestry:sapling_ge:*         tile.for.sapling_ge.name
forestry:mushroom:*           tile.for.mushroom.name
forestry:fruits:7..15         item.for.fruits.name
forestry:thermionic_tubes:14,15   item.for.thermionic_tubes.name
forestry:resources:3..15      tile.for.resources.Invalid Item Meta.name
```

Those are gaps in Forestry's own `en_us.lang` (the game falls back to the key when a translation is
missing), not something this pack renamed - and most of the entries are out-of-range metadata that no
player can hold. If the report was about a specific ore, the item id and the name shown would pin it
down in one probe; nothing so far points at GregTech's, Galacticraft's or Galaxy Space's ores.

## 6r. "All materials come from GregTech" - the re-point, generalised - 2026-10-12

The owner's instruction after 6q: *"unify **all** materials on GregTech's."* 6q had fixed smelting for
eleven mappings by hand; the general version does the same for every material the pack ever took out of
a shared ore dictionary name, and applies it to the machine recipes as well.

`src/main/java/com/minespace/unofficial/gtceu/MinespaceMaterialRepoint.java`:

* the mapping is **not invented** - it is exactly the list in `scripts/oredict.zs`, where
  the pack decided which mod item leaves which shared name. Each entry is "this mod item was taken out
  of this name", and since the pack left GregTech's item in the name, the target is simply the first
  item the name holds now - **resolved from the ore dictionary at runtime**, so a GregTech id change
  cannot break it;
* deliberately **not** in the map: the compressed / dense plates (`plateCopper`, `plateSteel`, the GS
  cobalt and nickel plates, Galacticraft's compressed aluminium). The pack's earlier decision stands -
  a rocket part that needs a dense plate keeps needing a dense plate - those stay as items produced by
  GregTech machines (6i, 6p); they are just not what a plain `plateX` recipe hands out;
* applied to **vanilla smelting** (input, yield and experience unchanged) and to **every GregTech
  recipe map's outputs** (the recipe, its inputs, its EU/t and its duration are untouched - only the
  stack it produces changes);
* run from the addon's postInit and again at load complete, because Gregicality registers its material
  recipes late. Idempotent: the second pass finds nothing.

Verified with a probe that counts, for every mod item the pack removed from a shared name, how many
recipes still produce it:

```
material re-point (postInit pass, smelting): 2173 recipes now yield GregTech's item
material re-point (postInit pass, machines):  803 machine outputs now yield GregTech's item
material re-point (loadComplete pass, smelting): 0
material re-point (loadComplete pass, machines):  0

RPROBE galacticraftcore:item_basic_moon:0 ('Meteoric Iron Ingot') craft=0 smelt=0 maps=[]
RPROBE galaxyspace:ingots:0              ('Cobalt Ingot')        craft=0 smelt=0 maps=[]
RPROBE forestrcraft... every watched item: smelt=0, maps=[]
RPROBE end (0 watched items still produced by smelting or a machine)
```

Two things the probe leaves on the table, both deliberate:

* a handful of items are still produced by **crafting-table** recipes - `desh` and `lead` ingots (one
  each: the pack's own one-to-one bridges from GregTech's ingot, section 6f), and the mods' *native*
  dust recipes (Ender IO's coal / iron powders, AE2's certus and ender dust, Galacticraft's aluminium
  dust, Galaxy Space's sulfur). Those are the mods' own chains and the pack's rule has always been that
  a mod item stays reachable - it simply is not what GregTech hands out any more;
* the 110 producers of GregTech's own meteoric iron ingot are unchanged, because they were already
  correct.

## 6s. The rule, corrected: mod machinery -> GregTech machines; crafting table -> GregTech materials

The owner's rule, as they stated it after reading 6r:

> "Materials should go through GregTech and not through the mod's own chain. But: I only mean the
> things that need another mod's *machine* - those have to be made in a GregTech machine. Everything
> else, the things the crafting table can make, needs to be made GregTech-complex."

So there are two cases, and an earlier attempt here got them wrong:

1. **An item that needed a mod's own machine** gets a GregTech machine recipe, and the mod's machine
   is no longer the way to make it. That is what 6h / 6o / 6p already did for Ender IO's alloys and
   machines, AE2's inscriber chain and the compressed plates, and what this section finishes for the
   Heavy Duty Plates (below).
2. **An item the crafting table can make** is **kept** and re-costed in GregTech materials, which is
   what the pack does everywhere else (plates, screws and circuits instead of ingots). It is *not*
   deleted.

A first version of this section deleted the mods' own recipes for their copies of GregTech materials
(39 items) and the pack's two one-to-one bridges. **That was the wrong reading and is reverted**:
`zzzzzz_minespace_materials.zs` is gone and the bridges are back in `gaps.zs`. A mod's own
crafting recipes stay; what is unified is the *material* they are built from.

What stays from that pass, because it is the rule working in the right direction:

* the **smelting / machine-output re-point** of 6q and 6r - GregTech's own ores and dusts smelt and
  process into *GregTech's* items, never the mods' copies. That is case 1: the mod's own material
  chain is out of the way;
* `MinespaceMaterialRepoint.repointCraftingInputs` - a crafting recipe that could *only* be satisfied
  by a mod's copy now takes GregTech's item. That is case 2, re-costing in GregTech materials, and it
  only touches an ingredient whose every member is a mod copy, so a mixed name such as `dyeBlue` (where
  Ender IO's lapis powder sits next to vanilla lapis) is left alone.

### Case 1, finished for the Heavy Duty Plates

Galacticraft's Heavy-Duty Plate (`item_basic_asteroids:5`) and Galaxy Space's `hdp:0..2` were made in
Galacticraft's Compressor and GS's Assembly Machine - both deleted by this pack - and a probe found
**no producer anywhere** for any of them, which left GS's rocket parts (built from `HDP:i` per tier)
unbuildable. They now come out of GregTech's compressor and assembler, following GS's own chain from
its source:

| GT machine | Recipe | Output |
| --- | --- | --- |
| compressor | 2 titanium ingots | Galacticraft's Heavy-Duty Plate |
| assembler | GS magnesium plate + SDHC-120 alloy + Galacticraft's Heavy-Duty Plate | `hdp:0` |
| assembler | GS cobalt plate + `hdp:0` + GS nickel plate + dolomite dust | `hdp:1` |
| assembler | SDHC-120 alloy + `hdp:1` + Venus Volcanic Rock | `hdp:2` |

Two ingredients had to be chosen rather than transliterated: GS's source names a "dolomite meal" and a
"volcanic stone" that do not exist as items in the GS 2.2.0 jar this pack runs, so GregTech's dolomite
dust and Galacticraft's `galacticraftplanets:venus:2` ("Venus Volcanic Rock") stand in for them.

```
HPROBE galacticraftplanets:item_basic_asteroids:5 <- [ingotTitanium]x2 (30 EU/t, 200 ticks)  producers = 1
HPROBE galaxyspace:hdp:0 <- [plateMagnesium] [compressed_plates:4] [item_basic_asteroids:5] [circuit]
HPROBE galaxyspace:hdp:1 <- [compressed_plates:1] [hdp:0] [compressed_plates:3] [dustDolomite] [circuit]
HPROBE galaxyspace:hdp:2 <- [compressed_plates:4] [hdp:1] [galacticraftplanets:venus:2] [circuit]
```

`hdp:3..7` stay open: GS's rocket parts reference them per tier, but GS's own source has no recipe for
them either - nothing this pack removed. They gate rocket tiers, so they need a decision, not a guess.

### Case 1, still open: the mods' own machine registries

A mod's *own* machine recipes are in neither the crafting table, a GregTech map nor smelting, so no
script and no re-point can see them: Applied Energistics' grinder can still grind its own crystals
into its own certus dust, and Ender IO's SAG mill can still grind its ores into its own powders. By the
rule those belong in GregTech machines (macerator / forge hammer). Both expose the hooks -
`mods.appliedenergistics2.Grinder.removeRecipe` and Ender IO's `user_recipes.xml disabled="true"` - and
are waiting on the owner's go-ahead rather than being guessed at.

## 6t. Mod machines -> GregTech machines (1): AE2's grinder becomes the macerator - 2026-10-12

The owner's first instruction this round, verbatim: *"the grinder recipes have to go - that is far too
cheaty; the recipes should be converted to GregTech's pulveriser."* AE2's grinder is exactly that: a
machine of its own that duplicates GregTech's macerator, with 443 recipes registered **in code** (there
is no config file to disable them - the AE2 config directory holds only the main cfg, facades and the
item csv).

`src/main/java/com/minespace/unofficial/gtceu/MinespaceGrinderToMacerator.java` walks AE2's own grinder
registry on load and, for every recipe whose *input* GregTech's macerator does not already handle,
builds the equivalent macerator recipe - same input, same guaranteed output, same optional outputs
with their chances (AE2 stores 0..1 floats, GregTech wants 1/10000) and AE2's own `turns` as the
duration. Then it empties the grinder through AE2's `IGrinderRegistry.removeRecipe`, which is the only
way in: `getRecipes()` hands back an *unmodifiable* view, so `clear()` throws. Runs from the addon's
postInit, guarded so the load-complete pass is a no-op.

```
grinder->macerator (postInit pass): 10 AE2 grinder recipes moved to GregTech's macerator, 443 removed from the grinder
grinder->macerator (loadComplete pass): already converted this launch
WPROBE2 grinder end (0 recipes)                                     <- the grinder is empty
```

The 10-vs-443 gap is de-duplication: GregTech's macerator already covers GregTech's own ores, so only
the recipes that add something (mod ores, crystals) are moved; JEI will not show two identical rows.
And because the conversion runs before the material re-point of 6q/6r, the moved macerator recipes then
get their outputs re-pointed to *GregTech's* dusts - AE2's grinder recipes come out of a GregTech
machine producing GregTech's material, which is the rule working end to end:

```
material re-point (macerator): output gregtech:meta_item_1:2202 -> gregtech:meta_item_1:2202 (was appliedenergistics2:material:2)
material re-point (macerator): output gregtech:meta_item_1:2201 -> gregtech:meta_item_1:2201 (was appliedenergistics2:material:3)
```

**The same treatment is queued for the other mod machines that duplicate a GregTech one** - Ender IO's
SAG mill (its powders), Forestry's machines are exempt, Galacticraft's and Galaxy Space's machines were
deleted outright in 6e/6f - each reached through its own API or config, as with AE2 here.

## 6u. Crafting-table recipes: the worklist for "GregTech-complex" - 2026-10-12

The owner's second instruction: *"by complexifying crafting-table recipes I mean the items you make
directly on the crafting table - they should be re-costed the way GTNH does, using GregTech materials
like screws and bolts and GregTech tools like the saw and the file. It depends on how the item would
really be made, which depends on what its crafting-table recipe is now."*

A probe produced the worklist by the only definition that matters here: **every crafting recipe whose
output belongs to a mod and none of whose ingredients is a GregTech item**. There are **1221** of them.
They are not all equal - AE2's paint balls and the decorative quartz tools are cosmetic, while the
machine components and tools are the ones that change how the pack plays - which is why this is a pass
to be worked family by family rather than one sweep.

The pattern to apply, per item, is the one the pack already uses everywhere else (6e, 6h, 6o):

* a **plate** where the recipe has a plain ingot; a **screw** or **bolt** where it has a small metal
  part; a **ring** or **foil** for a washer or a lining;
* a **GT tool** in the grid - `craftingToolSaw` for cutting planks and logs, `craftingToolFile` for
  shaping, `craftingToolHardHammer` and `craftingToolWrench` for assembling, `craftingToolScrewdriver`
  for screws - wherever the real object would need one;
* and the mod's own item kept as the *output*, because this is re-costing, not removal.

Work is proceeding in batches, family by family (AE2's machine components and tools first, then Ender
IO's, then the rest), each batch validated the same way every other change in this pack has been: a
server run that reaches `Done (x.xxxs)` with 47 mods, zero `crafttweaker.log` errors, exactly the two
baseline GregTech `Invalid recipe` lines and no `duplicate or conflict`.

## 6v. Crafting-table pass, batch 1: AE2's quartz tools and network tool - 2026-10-12

First batch of the worklist in 6u. The owner's rule for these: the item keeps its crafting-table recipe
and its output, but the recipe is re-costed GTNH-style - GregTech materials where the object would
really be metal, and GregTech **tools** where the real object would need shaping, hammering or screwing.

**The shapes were read off a live run, not remembered.** A probe printed every slot including the empty
ones, and it turned out AE2's tools mix the two kinds: the wrenches, the knife and the axes are
`ShapedOreRecipe`, while the network tool is `ShapelessOreRecipe`, and the sword / spade are one-row
shaped recipes. Writing them from memory would have produced recipes with the wrong layout, which in
this pack is the difference between "craftable" and "silently blank slot".

| Item (both the nether-quartz and certus-quartz versions) | Kept | Added |
| --- | --- | --- |
| wrench | the five crystals of its cross | GT file, GT hard hammer (the two free middle slots) |
| sword | 2 crystals + a wood stick | GT file |
| spade | 1 crystal + 2 sticks | GT file |
| pickaxe | 3 crystals + 2 sticks | GT file, GT hard hammer |
| hoe | 2 crystals + 2 sticks | GT file, GT hard hammer |
| axe | 3 crystals + 2 sticks | GT file, GT hard hammer |
| cutting knife | 2 crystals + 2 sticks | **GT iron plate** instead of the bare iron ingot, GT file, GT hard hammer |
| network tool | AE2's shapeless four (panel, chest, quartz wrench, fluix) | GT screwdriver, LV circuit |

No ingredient was dropped and no count lowered - every recipe is strictly harder than it was, and the
cutting knife's blade went from an ingot to a plate, which is how a blade is actually made.

Verified on a run: all fifteen recipes replaced (`ct_shaped*` for fourteen, `ct_shapeless*` for the
network tool), 47 mods, `Done (4.503s)`, zero `crafttweaker.log` errors, the two baseline GregTech
`Invalid recipe` lines and no `duplicate or conflict`.

**Queued next, in this order:** AE2's remaining crafting-table parts (the ME tunnels, toggle buses and
the terminal family in the worklist), then Ender IO's items, then the rest of the 1221 - each batch the
same way: read the real shape, re-cost with GregTech materials and tools, keep the output, verify on a run.

## 6w. Crafting-table pass, batch 2: AE2's ME parts - 2026-10-12

Same rule and same method as batch 1, same source of truth for the shapes (a probe printing every slot of
the live recipe). Every part **keeps all of its original ingredients** and gains a GregTech
**screwdriver** and an **LV circuit**: an ME part is an electronic assembly, so it is wired together with
a screwdriver and needs a circuit, which is what the GTNH reference does with Applied Energistics parts.
The one material change is in the ME tunnel, whose three bare iron ingots became GregTech **iron plates** -
a tunnel body is plate work, and a plate has to come off a bender.

| Item | Kept | Added |
| --- | --- | --- |
| ME tunnel (`part:460`) | the fluix ring and the housing | 3 iron ingots -> **GT iron plates**, GT screwdriver, LV circuit |
| toggle bus (`part:80`) | redstone, lever, two AE2 buses | GT screwdriver, LV circuit |
| ME terminal (`part:380`) | AE2's four parts | GT screwdriver, LV circuit |
| crafting terminal (`part:360`) | terminal + crafting table + fluix | GT screwdriver, LV circuit |
| fluid terminal (`part:520`) | terminal + blue dye + fluix (the dye stays - it is a dye, not a material) | GT screwdriver, LV circuit |
| pattern terminal (`part:340`) | housing + crafting terminal | GT screwdriver, LV circuit |
| interface terminal (`part:480`) | panel + housing + interface | GT screwdriver, LV circuit |
| extended processing terminal (`part:341`) | fluix ring + two terminals + a bus | GT screwdriver, LV circuit |

**Deliberately not touched**, and why: the pure 1:1 mode flips - `toggle_bus` to `toggle_bus_inverted` and
back, and the interface configuration and its revert. Those are not manufacturing, they change a part's
mode in place, so a tool in that grid would be noise rather than difficulty.

Verified on a run: eight recipes replaced (three shaped, five shapeless - the shaped-add count went
153 -> 156 and the shapeless count 9 -> 14), 47 mods, `Done (5.480s)`, zero `crafttweaker.log` errors, the
two baseline GregTech `Invalid recipe` lines and no `duplicate or conflict`. Every ore dictionary name the
new grids use was checked against the pack's own dump first (`crystalFluix`, `itemIlluminatedPanel`,
`craftingTableWood`, `dustRedstone`, `gemLapis` - all populated).

**Queued next:** the remainder of AE2's worklist (cabling, storage components, seeds and the deconstruction
recipes), then Ender IO's items, then the other families in the 1221-recipe list.

## 6x. Crafting-table pass, batch 3: AE2's storage components, buses and monitors - 2026-10-12

Third batch of the worklist, same method: the shapes come off a live run (this time a probe that listed
every AE2 recipe still without a GregTech item - 102 of them - and printed all nine slots of each), and
no ingredient is dropped.

Two kinds of recipe, and they need different treatment:

* the **storage, spatial and fluid components** (1k / 4k / 16k / 64k, the three spatial tiers and the
  64k fluid one) fill all nine slots: four dusts in the corners, four of the previous tier on the edges,
  quartz glass in the middle. There is no room for a tool, so the GT-ification is in the *material* - the
  four corner dusts became **GregTech screws**. A memory board is held together with screws, and a screw
  has to come off a GT lathe rather than being a dust you picked up:
  redstone dust -> iron screws (1k, 4k), glowstone dust -> gold screws (16k, 64k), lapis -> bronze screws
  (fluid 64k), glowstone -> steel screws (spatial);
* the **buses, emitter, plane, monitors and the crafting accelerator** are shapeless with room to spare,
  so they gain a **GT screwdriver** and an **LV circuit** like the ME parts of batch 2.

The AE2 interfaces in the bus recipes were narrowed from "the interface block *or* its part form" to the
block itself, which makes those three recipes strictly harder rather than easier.

Still not touched, and why: the pure 1:1 flips and colour swaps (the alternate storage bus, the monitor
panel colour swaps, the terminal configuration flips) and the paint balls - a mode flip is not
manufacturing, and a paint ball is decoration.

Verified on a run: sixteen recipes replaced - the shaped-add count went 156 -> 164 and the shapeless count
14 -> 22 - with 47 mods, `Done (5.012s)`, zero `crafttweaker.log` errors, the two baseline GregTech
`Invalid recipe` lines and no `duplicate or conflict`. Every ore dictionary name the new grids use was
checked against the pack's own dump first (`crystalCertusQuartz`, `pearlFluix`, `craftingPiston`,
`craftingBook`, `craftingRedstoneTorch`, `craftingToolScrewdriver`, `circuitBasic` - all populated).

**Queued next:** what is left of AE2 (the cabling family, the seeds, the deconstruction recipes and the
paint balls if the owner wants even those), then Ender IO, then the other families in the 1221-recipe list.

## 6y. Crafting-table pass, batch 4: AE2's machine parts, its stone, and Ender IO's shortcut around them - 2026-10-12

The rest of the AE2 worklist, with the shapes read out of **AE2's own recipe JSONs** (`assets/appliedenergistics2/recipes/`)
rather than off the probe - the probe prints ingredients in pattern order, which cannot tell a 2x1 recipe from a
1x2 one, and AE2 really does have one of each here (`chiseled_quartz_block` is `"aa"`, `quartz_pillar` is `"a","a"`).
Writing the pillar from the probe alone would have produced the same shape as the chiselled block and left one of
them unreachable. The ore dictionary names were checked against the pack's own dump before use.

**Machine parts, into the GregTech assembler** (crafting recipe deleted, LV circuit added, nothing dropped):

| item | original | now |
|---|---|---|
| formation core / annihilation core | certus-or-nether crystal + fluix dust + logic processor | same three, LV assembler, 200 t / 30 EU/t |
| quantum link chamber | 4 quartz glass + 4 fluix pearls | same, MV-HV assembler, 400 t / 480 EU/t |
| crystal growth accelerator | 4 iron ingots + 2 fluix glass cable + 2 quartz glass + fluix block | the iron is 4 **GregTech iron plates**, LV assembler, 400 t / 30 EU/t |
| semi-dark monitor (x3) | glowstone / iron ingot / redstone / quartz glass pattern | the ingot is a **GregTech iron plate** and the two free corners take a screwdriver and an LV circuit |

**Ordinary crafted things, re-costed only** (recipe and output count kept, GregTech tools added):

* the **fluid storage components 1k / 4k / 16k** get the same treatment the 64k part got in batch 3 - the four
  corner lapis dusts become four **GregTech bronze screws**; every other slot is AE2's own;
* the **eight stair recipes** and the **eight slab recipes** (sky stone, its two brick cuts, smooth sky stone,
  certus quartz, chiselled quartz, the quartz pillar and fluix), the **quartz / fluix / chiselled / pillar blocks**,
  the **vibrant quartz glass** and the two **sky stone chests** each gain a **GT saw** and a **GT hard hammer**
  (a screwdriver for the chests) - a cut stone block really is a saw job, and a crystal block really is pressed;
* the three 1:1 **sky stone** conversions are cuts too, so each now wants a saw;
* the hand grindstone's **wooden gear** (4 sticks) and **crank** (7 sticks) gain a **GT saw** and a **GT file**.

Narrowing found and fixed on the way: AE2's own recipes reference an item *tag* (`certusCrystal`) that accepts the
plain, the charged and the pure grown certus crystal, while only the plain one carries the `crystalCertusQuartz`
ore name - and batches 3 and 4 address certus quartz by that name. A player whose only certus crystal came out of
the growth chamber could not make a storage component or an ME core at all. `oredict.zs` now puts the
charged and the pure crystal back into that ore name, which restores exactly what AE2 meant by the tag.

**Ender IO's four wooden gears.** `GEAR_WOOD` in Ender IO's own config resolves to AE2's wooden gear
(`appliedenergistics2:material:40`), and `assets/enderio/config/recipes/materials.xml` ships four interchangeable
five-stick recipes that make it - the cheap way straight past the saw and file above. Ender IO registers its XML
recipes after CraftTweaker has run, so a script cannot touch them; the four are switched off by name in
`config/enderio/recipes/user/user_recipes.xml` instead.

Verified on a run: 47 mods, `Done (4.756s)`, zero `crafttweaker.log` errors, the two baseline GregTech
`Invalid recipe` lines and no `duplicate or conflict`; the shaped-add count went 164 -> 195 and the shapeless
count 22 -> 26, which is exactly the 31 + 4 recipes rewritten here. Ender IO's own recipe log (with its debug
output temporarily promoted) prints all four as
`Skipping XML recipe 'Gear, Wood' (valid=false, active=false, required=false, disabled=true)`.

Still not touched, and why: the sixteen paint balls, the "clean"/colour-wash recipes, the mode flips (an inverted
toggle bus, a terminal's configuration, a part's flat panel form) - none of those are manufacturing; and the four
"deconstruction" recipes, which are the reverse of a recipe that still exists.

**Queued next:** the AE2 cable family (its own pass - the "wash the colour off" recipe shares an output with the
cable's own recipe, so a removal by output would take the washing away with it), then Ender IO's SAG mill and its
crafting family, then the remaining families in the 1221-recipe list.

## 6z. Crafting-table pass, batch 5: AE2's cable family - 2026-10-12

The four cable families were the last plain manufacturing recipes in AE2. They could not be taken with the
method the earlier batches used, and the reason is worth recording: every cable recipe shares its *output*
with a second recipe - the "wash the colour off" recipe that turns a dyed cable back into the fluix one -
so `recipes.remove(<cable>)` would have deleted the washing along with the cable.

`recipes.removeShapeless(output, ingredients)` does the job instead: it matches one specific shapeless
recipe. It works on AE2's recipes because CraftTweaker 1.12's `ActionRemoveShapelessRecipes` casts to both
`ShapelessRecipes` and `ShapelessOreRecipe`, and AE2 registers its cables as the latter. It also logs how
many recipes it removed, which is exactly the evidence needed - the run shows **four calls, four
`Removing 1 Shapeless recipes.` lines**, so the washing recipes are provably untouched.

The shapes come from AE2's own recipe JSONs (`assets/appliedenergistics2/recipes/network/cables/*.json`),
not from the probe, which cannot tell a 2x1 recipe from a 1x2 one. Nothing was dropped and no count
changed - the fluix glass cable is still four per craft:

| cable | recipe | added |
|---|---|---|
| fluix glass | quartz fibre + 2 fluix crystal -> 4 | GT wire cutter (a fibre has to be cut to length) |
| fluix smart | covered cable + redstone + glowstone | wire cutter + LV circuit (the logic layer is electronics) |
| dense fluix covered | 4 covered cables | wire cutter |
| dense fluix smart | dense covered + redstone + glowstone | wire cutter + LV circuit |

Not touched: the wool wrap that turns a glass cable into a covered one - there is no GregTech tool for
wrapping something in wool and it consumes no metal - and every "clean" recipe, which changes a part in
place rather than making anything.

Verified: 47 mods, `Done (4.318s)`, zero `crafttweaker.log` errors, the two baseline `Invalid recipe`
lines and no `duplicate or conflict`; the shapeless-add count went 26 -> 30 (the four rewritten cables)
and the shaped count stayed 195.

## 6aa. Galaxy Space's heavy duty plates: the fourth tier was a real gap - 2026-10-12

Galaxy Space ships eight damage values of `galaxyspace:hdp` (Heavy Duty Plate) and its own recipes reach
exactly four of them. Disassembling the 2.2.0 jar with `javap` settles it: all five NASA-workbench part
recipes (`Schematic{Body,Booster,Cone,Engine,Fins}Recipe.registerRecipeWorkBench()`) run
`for (int i = 0; i <= 3; i++)` and build their part out of `new ItemStack(HDP, 1, i)`, the deconstructor's
salvage list stops at `HDP:2`, and nothing anywhere in the jar mentions 4, 5, 6 or 7.

So **`hdp:3` was a genuine blocker** - the fourth rocket's body, booster, cone, engine and fins could not
be assembled at all - and it is the one tier that had to be rebuilt. It continues the mod's own pattern:
previous tier, a plate of the next rocket metal (desh), GregTech stainless steel, and the dolomite the
tiers above already use. MV assembler, 600 t / 120 EU/t.

`hdp:4..7` have no recipe to restore because there never was one. They are filled in anyway, because an
item that ships with eight tiers and can only ever make four is worse than one that is explicit about it -
but they are **this pack's invention, not a port**, each a strictly dearer version of the one below
(previous tier + two more plates + a mineral, one voltage up: HV 480 / EV 1920 / IV 7680 / LuV 30720).
They can be deleted again without breaking a single mod recipe.

Verified on the same run as 6z: no new `Invalid recipe` line, so all five assembler recipes registered
with their ore dictionary inputs intact (`plateDesh`, `plateStainlessSteel`, `plateTitanium`,
`plateTungsten`, `plateTungstenSteel`, `plateHssg`, `plateUltimet`, `plateHsse`,
`plateTungstenCarbide`, `plateOsmiridium`, `dustDolomite` - each checked against the pack's own ore
dictionary dump first).

## 6ab. Ender IO's SAG Mill stops grinding the pack's ores - 2026-10-12

The SAG Mill was not a parallel route to GregTech's ore processing, it was a route *around* it: for 3600 RF
it turned any `ore*` ore dictionary entry straight into **finished powder** - two `POWDER_IRON` plus tin
and nickel dust by chance - where GregTech's chain for that same ore is macerator -> crushed ore -> ore
washer -> thermal centrifuge -> smelting. That is the clearest case of the owner's first rule (another
mod's machine does not get to produce this pack's materials) that was still standing.

Ender IO registers its XML recipes *after* CraftTweaker has run, so no script can remove them; the 203 ore
recipes the mod actually ships (`assets/enderio/config/recipes/sagmill_ores.xml`) are switched off by name
in `config/enderio/recipes/user/user_recipes.xml`. The 40 ore recipes in `sagmill_silentgems.xml` are not
listed because Silent Gems is not installed and Ender IO already skips every one of them.

Nothing becomes unobtainable: every one of those ores still smelts, and GregTech's macerator still turns
the ingot back into dust. The SAG Mill keeps everything else it can do - its non-ore recipes, its grinding
balls and its own machine blocks.

Verified with Ender IO's own recipe log (its debug output temporarily promoted): 221 unique
`Skipping XML recipe '<name>' (valid=false, active=false, required=false, disabled=true)` lines, of which
**all 203 are the ore recipes** and the rest are the alloy / silicon / wooden-gear disables from the
earlier passes - the list was diffed name by name against the file's own disable list. The same run:
47 mods, `Done (4.393s)`, CT errors 0, the two baseline `Invalid recipe` lines, no `duplicate or
conflict`.

**Queued next:** the rest of Ender IO's SAG Mill (its ingot / block / gem recipes, which duplicate the
macerator and the forge hammer) and its `alloying`-adjacent families, then the remaining families in the
1221-recipe worklist.

## 6ac. The SAG Mill, second pass: what GregTech already covers, proven with a probe - 2026-10-12

The first SAG Mill pass (6ab) switched off the 203 ore recipes in `sagmill_ores.xml`. Two things were
still open: recipes in the mill's *other* XML files, and every ingot / block / gem recipe, which is the
same duplication the macerator and the forge hammer already do.

Both were settled with a **probe** rather than a guess: `MinespaceGTMapProbe` (temporary, since deleted)
dumped GregTech's own `macerator` (11,620 recipes), `forge_hammer` (6,903), `thermal_centrifuge` (337),
`centrifuge` (610), `extractor` (31), `compressor` (902), `mixer` (298), `alloy_smelter` (1,669),
`chemical_bath` (5,902) and `lathe` (402) into `gtmap_probe.txt`, each input written as its ore
dictionary name plus the concrete item id. (`ore_washer`, `bender` and `hammer` are not the names the TJ
fork uses for those maps, so they came back MISSING; the macerator and forge hammer are the two that
decide ore and metal coverage.) The probe was removed and the jar rebuilt before the final run - the
shipped jar contains only the permanent `MinespaceOreModelProbe`.

Two conclusions came out of the dump:

* **the first pass had missed thirteen ore recipes.** It scanned `sagmill*.xml`, but the eight
  Railcraft-style `Sagmill: Poor X Ore` recipes live in `integration_railcraft_recipes.xml` and five gem
  ores (`oreBlueTopaz`, `oreJasper`, `oreOnyx`, `oreOpal`, `oreZircon`) live in
  `sagmill_silentgems.xml` - and those five are live, because the pack has those ores even though Silent
  Gems itself is not installed. Two more (`appliedenergistics2:quartz_ore`, `minecraft:quartz_ore`) are
  addressed by item id, not by an ore name, so a name-shaped filter could never have caught them.
* **everything else the mill still does with a metal is already a GregTech input.** Every ore
  dictionary name below (GT's iron / gold / copper / tin / lead / silver / nickel / steel / titanium /
  tungsten / uranium / osmium / platinum / magnesium / manganese / zinc / cobalt / brass / bronze /
  electrum / invar / enderium / graphite / black steel / Damascus steel ingots and blocks, the diamond /
  emerald / lapis / prismarine gems, and the vanilla stone, wood and plant conversions) appears as an
  input somewhere in that dump.

87 recipes are therefore switched off as well, bringing the file to **307 disabled entries**, and the
run confirms it: Ender IO's own recipe log (debug output temporarily promoted) prints **308 unique
`Skipping XML recipe ... disabled=true` lines** - 307 from the file plus Ender IO's own
`Tank: Player Token Alternative` - and a name-by-name diff shows **0 of the 87 missing**. SAG Mill
recipes still live: 55.

Kept deliberately, and why: Ender IO's own materials (its nine alloys and its Precient / Pulsating /
Vibrant / Ender crystals - GregTech has no material for them, so there is nothing to move them to),
Forestry's apatite (Forestry is the owner's exception), and the handful of vanilla items GregTech's own
maps turned out not to accept, such as coal and charcoal.

Verified on the final clean run: 47 mods, `Done (3.494s)`, zero `crafttweaker.log` errors, the two
baseline `Invalid recipe` lines, no `duplicate or conflict`, and the debug-only lines back at 0.

## 6ad. Advanced machines, second half: Galacticraft, Galaxy Space, PlanetProgression - 2026-10-12

### The worklist, rebuilt from the live registry

The 1221-recipe worklist of 6u was derived from a probe run on 2026-10-11, and a day of work later it had
gone stale: it still listed Ender IO machine blocks and Iron Chests tiers that no longer have a crafting
recipe at all. It was rebuilt properly, and the way that was possible is worth recording.

**A CraftTweaker script cannot do this job.** A script body runs during init, but Ender IO, Storage
Drawers, Forestry and Galaxy Space all register their crafting recipes *later* - a script-level dump came
back with AE2, Iron Chests and Galacticraft and **no Ender IO at all**. The rebuild therefore uses a
temporary Java probe (`MinespaceCraftWorklistProbe`, since deleted) hung off `loadComplete`, which walks
CraftTweaker's own `IRecipeManager` by reflection and writes every mod recipe - output, each ingredient
as concrete item ids, and the registry name - to `craft_worklist.txt`. Two temporary probes were written
and both were removed and the jar rebuilt before the final run; the shipped jar contains only the
permanent `MinespaceOreModelProbe`.

The current numbers, with "worklist" meaning *a crafting recipe whose ingredients contain no GregTech
item*:

| family | before this pass | after |
|---|---|---|
| Forestry | 469 | 469 (the owner's exception) |
| Ender IO | 374 | 374 |
| Galacticraft core | 133 | 123 |
| Galaxy Space | 50 | 44 |
| Galacticraft Planets | 46 | 41 |
| PlanetProgression | 7 | 1 |
| our own scripts | 41 | 41 |
| AE2 | 38 | 38 |
| EnderCore / Storage Drawers / The One Probe | 28 | 28 |
| **total** | **1186** | **1159** |

### What this pass changed

27 machines were still built at the crafting table after the first assembler pass, which only covered
Ender IO, Forestry and AE2 (6h). They are now assembler work, same materials, no count lowered, plus an
integrated circuit - Galacticraft core at LV 30, everything else at MV 120:

* **Galaxy Space** - hydroponic farm, energy pad, planet shield, oxygen storage module, gravitation
  module, machine frame;
* **PlanetProgression** - telescope, basic satellite module, satellite launcher, controller and builder,
  advanced launch pad;
* **Galacticraft Planets** - the Mars machine, beam reflector, short telepad, heavy nose cone;
* **Galacticraft core** - the rocket engine (both of its recipes), two cargo loaders, the dish base, the
  buggy material, the sensor and frequency module, the telemetry unit and the battery.

### A real gap the worklist check found: Galacticraft's Heavy-Duty Plate

The same audit checked whether anything the new recipes *need* is still obtainable, and found one genuine
hole. `galacticraftcore:heavy_plating` is an ingredient of GC's rocket engine, nose cone, fins and the
tier-2 engine, and **nothing in the pack produced it**. Disassembling Galacticraft's own
`RecipeManagerGC` explains why: it was a *compressor* recipe - shape `"XYZ"/"XYZ"` with X = compressed
steel, Y = compressed aluminium, Z = compressed bronze, giving two plates - and Galacticraft's compressor
is one of the machines this pack deleted, so the recipe went with it. Every GC rocket part that needs a
Heavy-Duty Plate was therefore uncraftable.

It is rebuilt in the **assembler** now - the three compressed plates are themselves already made in
GregTech machines, so this is an assembly job: the same six plates in, the same two plates out.

Verified on the final clean run: 47 mods, `Done (4.006s)`, zero `crafttweaker.log` errors, the two
baseline `Invalid recipe` lines, no `duplicate or conflict`, and neither temporary probe present in the
jar.

**Left in the list, and why:** Forestry (the owner's exception), Ender IO's remaining 374 (its own
alloys, capacitors, upgrades, conduits, decorative blocks and levers - items whose ingredients are Ender
IO's own materials, for which GregTech has no counterpart to move them to), GC's parachutes, food,
slabs, walls, lighting and steel tools, Galaxy Space's coloured glass and thermal padding, AE2's paint
balls and one-to-one mode flips, and Storage Drawers' keys.

## 6ae. Ender IO's own materials become GregTech materials - 2026-10-12

The owner's call: *"Ender IO's remaining materials can be expanded into GregTech materials - the ingot,
its molten fluid, the dust and the nugget; the other forms are not wanted. And the other things that
look high-tech can go into the assembler or get a harder recipe."*

### The ten alloys

`MinespaceMaterials` now registers Ender IO's ten alloys as GregTech `IngotMaterial`s -
`dark_steel`, `electrical_steel`, `energetic_alloy`, `vibrant_alloy`, `redstone_alloy`,
`conductive_iron`, `pulsating_iron`, `soularium`, `end_steel` and `construction_alloy` (Ender IO calls
the last one "Iron Alloy"). The only flag set is `SMELT_INTO_FLUID`, which is exactly the set the owner
asked for and nothing more: an `IngotMaterial` builds the ingot, the nugget, the block, the dust and -
with that flag - the molten fluid, while the plate / gear / rod / foil / ring families all need a flag
that is deliberately left unset.

The component lists are deliberately **empty**. Declaring what an alloy is made of makes GregTech
generate its own mixer and alloy-smelter recipes, and this pack already declares those by hand in
`integration.zs` (copied from Ender IO's own `alloying.xml`); two sources for the same
alloy in the same recipe map is the duplicate this migration has spent its whole length avoiding. A
material GT already owns under the same name is reused instead of re-created - a second material under
one name corrupts GT's name-keyed registry and kills the load inside `Material.toCamelCaseString`,
which is what happened once already with dolomite. The run logs all ten as newly registered, so there
was no collision: `dark_steel` took id 179, the rest 208 and 222, and 256-262.

### Handing the shared names to GregTech

`oredict.zs` takes Ender IO's ingot and nugget out of all twenty `ingotX` / `nuggetX`
names, so the pack's rule holds - the GregTech item wins the shared name - and
`MinespaceMaterialRepoint` gained the matching twenty entries, which makes the existing machinery do
the rest:

* **machine outputs** that used to hand out Ender IO's ingot now hand out GregTech's. The alloy
  smelter / mixer recipes this pack declares for the ten alloys are re-pointed by exactly that pass;
* **crafting-table inputs** are re-pointed too, so Ender IO's own recipes - its blocks, its grinding
  balls, its conduits, its capacitors - now cost GregTech's ingot. The run shows it directly:
  `material re-point (crafting input): enderio:auto_electrical_steel_1_ingot_to_9_nuggets.0 ->
  gregtech:meta_item_1:10208` and nine more of the same shape.

Two Ender IO recipes cannot be re-pointed that way and are rebuilt in
`eio_materials.zs` instead: `IRecipe#getRecipeOutput()` is computed rather than
stored, so a crafting-table *output* can only be changed by replacing the recipe. Those are the
block -> 9 ingots and the 9 nuggets -> ingot conversions for each of the ten alloys. The script writes
the output as `oreDict.get("ingotDarkSteel").firstItem` - GregTech hands material ids out at runtime
from the lowest free slot, so the item id cannot be written down in a script, but the ore name can.

Deliberately left alone: the *block* forms. Blocks are the one form GregTech builds alongside the
ingot whether one wants it or not, so Ender IO's own blocks stay where they are and keep working.

### The high-tech items

Six more recipes moved into the assembler in `assembler_2.zs`, next to the Galacticraft
machines of 6ad: Ender IO's **liquid conduit** in two tiers and its **item conduit** (eight pieces of
Conduit Binder around the core part), and the **second capacitor tier** (two Vibrant Alloy ingots, two
first-tier capacitors and a glowstone). Same materials, no count lowered, plus an integrated circuit at
MV 120.

The **ME conduits** are deliberately *not* in that batch. One of their three recipes accepts any of the
seventeen coloured AE2 cables in its centre slot, the recipe dump prints that slot truncated, and
removing the output would take all three recipes with it - including the one that cannot be written back
without guessing which cable was meant.

Verified on the clean run: 47 mods, `Done (4.020s)`, zero `crafttweaker.log` errors, the two baseline
`Invalid recipe` lines, no `duplicate or conflict`, shaped 195 and shapeless 50 (the twenty rebuilt alloy
conversions), and twenty `Removing ... from ore dictionary entry ingotX/nuggetX` lines naming Ender IO's
item in each.

## 6af. Ender IO's dark steel upgrades: the blank goes to GregTech, the forty-five variants become assembler work - 2026-10-12

### What Ender IO's own files say

Reading `assets/enderio/config/recipes/darksteel_upgrades*.xml` out of the jar gives the whole shape of
this family, and it is two different things:

* the **blank** upgrade (`item_dark_steel_upgrade:0`) is made in **Ender IO's own alloy smelter** - its
  recipe is an `<alloying>` entry named "Dark Steel Upgrade": dark iron bars + clay + four string;
* the **forty-five variants** are ordinary crafting-table recipes that take a blank upgrade plus one or
  two parts and produce an upgrade carrying an NBT tag. The tag is not a guess: each recipe in that file
  writes it out, e.g. `nbt='{"enderio:dsu":"enderio:carpet"}'`, and the value always equals the
  recipe's own `dependency` attribute.

The recipe registry names EIO gives them are slugified from the display name with *every* capital
starting a new word, so "Dark Steel Upgrade: TNT 2" is `dark_steel_upgrade_t_n_t_2`. That is what makes
the join between the XML (which has the NBT) and the live recipe dump (which has the ingredients)
possible, and all 45 rows joined cleanly.

### What changed

`scripts/eio_upgrades.zs`:

* the **blank** is now a **GT assembler** recipe (dark iron bars + clay + 4 string; three inputs is over
  the alloy smelter's two-input limit, so the assembler is the machine that fits). Ender IO's alloying
  entry is switched off by name in `config/enderio/recipes/user/user_recipes.xml`;
* each of the **45 variants** is an assembler recipe now, with the NBT written through
  `.withTag({ "enderio:dsu": "..." })`. Materials unchanged, no count lowered, one integrated circuit
  each. Ender IO's alloy ingots and nuggets in those grids are written as the GregTech ore names,
  because an assembler recipe is not a crafting-table recipe and so is not something
  `MinespaceMaterialRepoint` re-points.

Ingredients that EIO stores as a list of alternatives are written back as the ore name or wildcard they
came from, never as the first member of the list: `GEAR_WOOD` -> `<ore:gearWood>` (which now holds AE2's,
Ender IO's *and* GregTech's wooden gear), the chest slot -> `<ore:chestWood>`, carpet -> 
`<minecraft:carpet:32767>`, wool -> `<ore:wool>`.

### Evidence, and where the family stands now

The temporary worklist probe was put back for one run to measure the result and removed again:

* **`dark_steel_upgrade` rows left in the crafting registry: 0** (they were 45);
* mod crafting recipes 2838 -> 2787 (the 45 upgrades plus the six conduits/capacitors of 6ae);
* the worklist - "a crafting recipe whose ingredients contain no GregTech item" - 1186 at the start of
  the Ender IO material work -> **1024** now, with Ender IO itself dropping 374 -> **219**.

| family | worklist |
|---|---|
| Forestry | 469 (the owner's exception) |
| Ender IO | 219 |
| Galacticraft core | 123 |
| our own scripts | 61 |
| Galaxy Space | 44 |
| Galacticraft Planets | 41 |
| AE2 | 38 |
| EnderCore / Storage Drawers / The One Probe / PlanetProgression | 29 |
| **total** | **1024** |

Verified on the final clean run: 47 mods, `Done (5.269s)`, zero `crafttweaker.log` errors, the two
baseline `Invalid recipe` lines, no `duplicate or conflict`, shaped 195 / shapeless 50, and neither
temporary probe present in the jar.

## 6ag. Galacticraft's heavy steel tools and armour: dense plates and GregTech tools - 2026-10-12

The owner's second rule, applied to the one family in Galacticraft's remaining 123 that is made of
metal by hand: the heavy-duty tools and the heavy-duty armour. Every one of them was a plain
crafting-table recipe built out of Galacticraft's **compressed steel plate** (`basic_item:9`), which is
itself made in this pack by the GregTech implosion compressor from two steel plates and four
explosives - so the material was already GregTech's, and what was missing was the *shaping*.

`scripts/gc_tools.zs` rewrites sixteen recipes - the axe (both of its shapes), sword,
pickaxe, shovel, hoe, helmet, chestplate, leggings, boots, the steel pole, the standard wrench, the
advanced landing pad and the two buggy wheels:

* **the compressed steel plate becomes GregTech's dense steel plate** (`<ore:plateDenseSteel>`). A
  heavy-duty tool or a suit of heavy armour really is made of the densest plate the pack has, and one
  dense plate is nine steel plates against the compressed one's two - so this is strictly *dearer*, in
  line with the standing instruction never to make a recipe easier;
* **the free grid slots take the tools the object needs**: a file and a hard hammer for the bladed and
  headed tools, a hard hammer alone for the armour plates, a saw for the pole, and a wrench with a
  hammer or screwdriver for the wrench, the landing pad and the wheels.

No ingredient is dropped and no count is lowered. The shapes are Galacticraft's own, read out of the
live recipe registry, and the tools go into slots the pattern already left empty.

Two things were deliberately **not** done:

* Galacticraft's *machines* - the oxygen concentrator, air lock frames, lighting panels, thrusters,
  heavy oxygen tanks, the rocket workbench, the view screen and so on - also use that compressed plate,
  and a pass over them was started and then thrown away. Their steel plate is Galacticraft's own
  compressed plate and GregTech already makes it, so they are not a mod-material leak; deciding that a
  machine housing should take nine steel plates per slot is a different balance call from the one the
  owner asked for here.
* Galacticraft's parachutes, food, slabs, walls, stairs and lighting stay as they are - decoration and
  food, not manufacturing.

Verified: 47 mods, `Done (3.966s)`, zero `crafttweaker.log` errors, the two baseline `Invalid recipe`
lines, no `duplicate or conflict`, and the shaped-add count 195 -> **211**, which is exactly the sixteen
recipes rewritten here.

## 6ah. Galacticraft-Planets' titanium and desh tools and armour - 2026-10-12

The same pass as 6ag, for the two metal families of the asteroids and Mars. Twenty-two recipes in
`scripts/gcp_tools.zs` - the titanium axe (both shapes), sword, pickaxe, shovel, hoe,
helmet, chestplate, leggings and boots, and the desh axe (both shapes), sword, pick, spade, hoe,
helmet, chestplate, leggings and boots:

* **titanium** was built from Galacticraft's compressed titanium plate
  (`item_basic_asteroids:6`, which this pack makes in the GT implosion compressor from two titanium
  plates and explosives). It takes GregTech's **dense titanium plate** now - one dense plate is nine
  titanium plates against the compressed one's two, so strictly dearer, never easier;
* **desh** was three plain GregTech desh *ingots* plus a handle - the material re-point had already
  made those GregTech's, so the only thing wrong with them was the *form*. A tool head is not an
  ingot: the ingots become GregTech **desh plates**, one ingot each, which have to come off a bending
  machine first;
* both families also take the GregTech tools the object needs, in slots the pattern already leaves
  empty: a file and a hard hammer for the bladed and headed tools, a hard hammer alone for the armour
  plates.

No ingredient is dropped and no count is lowered; the shapes are Galacticraft-Planets' own, read out of
the live recipe registry. One bug of the generator's own is worth recording, because it produced a
script that would have failed to parse: PowerShell unwraps a one-element `@()` inside `$(if ...)`, so
the "one tool" armour recipes ended up with the string's **first character** in a grid slot instead of
the tool. Two of the cells read `<,` in the generated file. Caught by reading the generated script
before running it, fixed by keeping the tool list as an array, and the file now has none.

Verified: 47 mods, `Done (5.590s)`, zero `crafttweaker.log` errors, the two baseline `Invalid recipe`
lines, no `duplicate or conflict`, and the shaped-add count 211 -> **233**, exactly the twenty-two
recipes rewritten here.

## 6ai. Forestry is no longer the exception - 2026-10-12

The owner's note: *"Forestry's recipes are a bit special: items a Forestry **machine** makes should be
made more complex, with GregTech items put into them; the other items just get gregified."* Up to now
this pack had treated Forestry as the one untouched mod, so its 469 worklist rows had never been looked
at. Two scripts now do the workbench half of that, and the machine half is called out below.

### `forestry_wood.zs` - 315 recipes

Forestry's whole wood family: planks, fences, slabs, stairs and its wood doors (plus the six vanilla
doors it adds recipes for out of its fireproof planks). GTNH cuts wood with a saw, and a fence or a slab
is cut from planks the same way, so **each recipe gains a GregTech saw** in a slot the pattern already
leaves empty. No ingredient is dropped and no count is lowered.

The outputs are Forestry's dotted registry names (`forestry:planks.fireproof.1`,
`forestry:fences.0:3`, ...). Great care was needed with the generator twice, and both mistakes were
caught by reading the generated script before running it rather than by a failed load:

* a nested `-notmatch` inside the row parser **overwrote PowerShell's `$matches`**, so the captured
  ingredient list came back empty and the first version produced 315 recipes that were nothing but a
  saw. Capturing the three groups into locals first fixed it;
* wildcard ingredients (`minecraft:planks:32767`) were turned back into the ore name they came from
  (`plankWood`, `logWood`) rather than being narrowed to the first member of the list.

### `forestry_items.zs` - 12 recipes

The workbench items that belong to the machines and the apiary, re-costed with GregTech items:

* the **grafter** takes a file and a hard hammer (it is a shaped tool) and the **scoop** takes a saw;
* the **pulsating mesh** the carpenter presses is held together with a **GregTech steel screw** and a
  screwdriver - a screw has to come off a GT lathe;
* the **worktable** and the three special chests (tree, bee, butterfly) are boxes and take a
  screwdriver;
* the **habitat locator** is an electronic locator, so it takes a screwdriver and an **LV circuit**;
* each of the four pieces of **apiarist armour** takes a hard hammer - woven silk beaten into shape.

Ingredients Forestry stores as a list of alternatives are written back as the ore name they came from
(`blockGlass`, `treeSapling`, `chestWood`), never as the first member of the list.

Deliberately left alone: the eight beekeeper bags (woven cloth and string - no GregTech tool fits), the
untreated and impregnated frames and the genetic filter (their grids are completely full, so there is
nowhere to put a tool without dropping one of their own parts, which would make them cheaper), the
greenhouse and climatiser deconstruction recipes, and the peat bog / farm block placement flips.

Verified: 47 mods, `Done (5.734s)`, zero `crafttweaker.log` errors, the two baseline `Invalid recipe`
lines, no `duplicate or conflict`, and the shaped-add count 233 -> **560**, exactly the 315 + 12 recipes
written here.

### Still to do: the recipes of Forestry's *machines*

The owner's first half - "items a Forestry machine makes should be made more complex with GregTech items
in them" - is about the machine recipes themselves (the Thermionic Fabricator's electron tubes, the
Carpenter's casings, the Centrifuge's outputs), and those are not crafting recipes: they live in
Forestry's own recipe managers. The pack already ships **ModTweaker**, which exposes exactly those -
`mods.forestry.ThermionicFabricator.addSmelting/removeSmelting`, `Carpenter.addRecipe/removeRecipe`,
`Centrifuge.addRecipe/removeRecipe` and the rest of the factory machines - so the change is a script, not
a Java patch. What it needs first is the machines' **current** recipe lists, which are registered in
Forestry's code rather than in a data file; that is one probe round away.

## 6aj. Forestry's machines: the electron tubes take GregTech items - 2026-10-12

The other half of the owner's Forestry note: *items a Forestry **machine** makes are to be made more
complex, with GregTech items put into them*. The clearest case, and the one that only a Forestry machine
can make at all, is the **electron tube**.

### What the machine actually registers

Forestry keeps its machine recipes in code, so nothing on disk could be read - and a CraftTweaker script
runs before the mods that register late. A temporary Java probe (`MinespaceForestryProbe`, since
deleted) was hung off `loadComplete` and worked through `forestry.api.recipes.RecipeManagers`:

* **101** Thermionic Fabricator cast recipes, 7 glass-smelting recipes;
* **209** Carpenter recipes;
* **25** Centrifuge recipes.

The tubes are 13 of those 101 casts. Each is a 3x3 pattern - five of the tube's metal in a cross, two
redstone - into molten glass, for four tubes, and every one of them leaves **two cells empty**:

```
out=forestry:thermionic_tubes:1 size=3x3  [ ][tin][ ][redstone][tin][redstone][tin][tin][tin]
```

### Why this is Java and not ModTweaker

ModTweaker does ship a Forestry integration, and it was the first choice - but its fabricator API works
off the recipe's **plan** (the cast), and the probe shows every tube recipe's plan is **empty**. There is
nothing for `removeCast` to match on. Forestry's own `FabricatorRecipeManager` exposes `recipes()`,
`removeRecipe` and `addRecipe` for exactly this purpose, so `MinespaceForestryTubes` (a permanent class
now, in the same family as `MinespaceGrinderToMacerator`) rewrites them there.

Each tube keeps its plan, its molten glass, its output and its whole grid, and gains two GregTech items
in the two empty cells: a **fine wire** - matched to the tube's own metal where that metal is a GregTech
material, copper otherwise - and an **iron screw**. Nothing is dropped and no count is lowered.

### The mistake worth remembering

The first version reported `0 of 101 tube recipes rewritten (13 named)` - it had found the tubes and then
silently done nothing to them. The list Forestry hands back is **nine cells, each holding that cell's
list of accepted alternatives**, and an empty cell is a *list with no alternatives in it* - not a cell
holding an empty stack. The code was looking for empty stacks, found none, and `fill` returned -1 for
every cell. Reading the probe output carefully (the grid printed as nine groups, one per cell) is what
gave it away.

Verified on the final clean run, with the probe temporarily moved after the conversion so it would show
the new grids: the tin tube now reads
`[wireFineTin][tin][iron screw][redstone][tin][redstone][tin][tin][tin]`, the tubes whose metal GregTech
does not know (blaze, obsidian, apatite, ender) read `wireFineCopper`, and all 13 carry the iron screw.
The conversion logs `13 of 101 tube recipes rewritten (13 named)`; the probe and its file are deleted
and the jar rebuilt, leaving only the permanent `MinespaceOreModelProbe` and `MinespaceForestryTubes`.

Run: 47 mods, `Done (4.515s)`, zero `crafttweaker.log` errors, the two baseline `Invalid recipe` lines,
no `duplicate or conflict`, shaped 560 / shapeless 50.

### The Carpenter as well: the chipsets and the scented paneling

The same probe dumped the **Carpenter** (209 recipes) and the **Centrifuge** (25). Going through the
Carpenter's list shows almost nothing the rule should touch - a hundred-odd of them are *crates*
(packaging an item into a box), the rest are comb and fruit conversions, stone, saplings and log
peeling. Two things are Forestry's own machine parts, and those are now handled by a second permanent
class, `MinespaceForestryCarpenter`:

* the four **chipsets** (the circuit boards every Forestry machine eats) - eight redstone and one metal
  ingot each. The ingot becomes a **GregTech plate** of the same metal, and one of the eight redstone
  becomes a **GregTech steel screw**. This is the one place in the whole migration where an ingredient
  is *replaced* rather than added, and it is deliberate: the chipset grids are completely full, so
  there is nowhere to put a screw, and a single redstone is as close to free as an item gets - swapping
  it for a lathe product can only make the recipe dearer. The ingredient count is unchanged;
* the **scented paneling** (`crafting_material:6`) has two empty cells and simply gains a steel screw.

**The trap, worth recording because it cost four attempts.** The obvious way to do this is to rebuild the
recipe - read the grid, change it, construct a new `CarpenterRecipe` around a new `ShapedRecipeCustom`.
Forge's `CraftingHelper.parseShaped` refused it three times in a row, and each refusal taught something:

1. *"Invalid shaped ore recipe"* with the grid as read - because a cell Forestry leaves empty can be a
   list holding one **empty stack**, and an empty stack inside a shaped pattern is illegal;
2. the same error after filtering those out - because the pattern had a **trailing space**. Forge
   requires the pattern to be a tight bounding box (a space *inside* the box is fine, which is how every
   vanilla JSON recipe writes a ring);
3. the same error again with a fully trimmed pattern and proper `Ingredient` values - at which point
   rebuilding was abandoned as the wrong idea.

The recipe's own ingredients are perfectly good, so the class now reaches into `ShapedOreRecipe`'s
private `input` list - the very list its own matcher uses - and replaces only the one or two cells that
change. The Carpenter's water, its box, its packaging time and every other cell, alternatives included,
are untouched. That worked first try: `5 recipes rewritten - 4 chipsets (GT plate + steel screw) and 1
scented paneling (steel screw)`.

### Still open in Forestry

The **Centrifuge** (25 recipes: `in=<item> time=<n> out=<product> @chance ; ...`). It is deliberately
*not* done: its outputs are the bee products - beeswax, honey drops, propolis, pollen - which are
separated from a comb rather than manufactured, and pushing GregTech items into that would drag
beekeeping into the GregTech early game for no gain. The full dump of all three machines is parked in
`%TEMP%\minespace-cleanup-2026-10-12\temp-scratch\forestry_probe.txt` if that judgement is ever
revisited.

Run for this half: 47 mods, `Done (3.731s)`, zero `crafttweaker.log` errors, the two baseline `Invalid
recipe` lines, no `duplicate or conflict`.

## 6al. "The same material twice, and only one of them has a recipe" - 2026-10-12

The owner's report was that many recipes are missing, and the useful detail: *"some items that are the
same but of different materials have only one recipe."* Rather than guess, a **recipe audit probe**
(temporary, since deleted) was written that dumps everything the pack *produces* - the whole crafting
registry, every GregTech recipe map, vanilla smelting, and Forestry's machine managers - and everything
it *consumes*, so an item nothing makes any more can be found by subtraction. Two bugs in the analysis
script itself had to be fixed first (a `' , '` split where the dump uses `','`, and PowerShell's
`$matches` being overwritten by a nested `-match`), which is why the raw count of "used but never
produced" fell 658 -> 489 -> 336 -> 171 as each was corrected.

### What the audit found

Two different problems, and only the second one is a real recipe bug:

1. **The emptied mod materials were never hidden from JEI.** `oredict.zs` hands every
   shared material name to GregTech's item, and the scripts then delete the mod's own production - but
   only the three *silicon* items were hidden from JEI. So JEI lists, say, "Dark Steel Ingot" twice:
   GregTech's (craftable) and Ender IO's (nothing makes it). That is exactly the owner's description.
2. **One genuine recipe gap.** Cross-referencing "removed by one of our scripts", "never re-added",
   "nothing produces it" and "something consumes it" leaves exactly one item:
   `galacticraftcore:basic_item:12`. It is one of the three ingredients of Galacticraft's **Basic
   Wafer** (`basic_item:0`, the wafer behind every Galacticraft circuit), and its own recipe was deleted
   by the batch that took Galacticraft's ingots and compressed plates out of the ore dictionary.

### The fix for (1): `jei_dupes.zs`

The rule applied is precise and checkable: hide a mod item from JEI exactly when

* the pack removed it from a shared ore dictionary name (so GregTech's twin now owns that name), **and**
* nothing in the pack produces it any more.

**39 items** qualify: Ender IO's ten alloy ingots and seven of its powders, Forestry's copper / tin /
bronze ingots, Galacticraft's four metal blocks and four ingots plus meteoric iron, Galacticraft
Planets' titanium / desh / lead blocks and its titanium ingot and dust, Galaxy Space's three ingots, and
the three silicons. The items themselves stay in the game - a player who has one can still use it - they
just stop appearing in JEI as a duplicate that cannot be made.

### What is left to fix

`galacticraftcore:basic_item:12` still has no producer. Its identity is not in the class's string pool,
so the next step is to read Galacticraft's `ItemBasic` names array in the right order (or probe the live
item) and then either rebuild its producer in a GregTech machine - the way the compressed plates were -
or re-point the Basic Wafer recipe at whatever GregTech item replaced it. That is a single, bounded
change.

Also worth recording: 104 items are "removed and never re-added", but almost all of that is deliberate -
Ender IO's and Galacticraft's and Galaxy Space's generators, the machines this pack replaced, the EV and
above FE-to-EU converters of 6m, and the mod tool and armour sets GregTech replaces. Those are already
hidden from JEI, and none of them is consumed by another recipe.

Run: 47 mods, `Done (6.014s)`, zero `crafttweaker.log` errors, the two baseline `Invalid recipe` lines,
no `duplicate or conflict`.

## 6am. "You deleted the machine recipes and now they cannot be made" - the assembler's nine-input limit - 2026-10-12

The owner's report, after the assembler passes of 6ad / 6ae, was that several machines could not be made
any more, together with an instruction for how to continue: *"let's do one mod at a time - start with
Planet Progression."* The audit of 6al had already printed the symptom (24 outputs in `audit_maps.txt`
with no producer at all) but not the cause. The cause turned out to be one validation rule in GregTech
itself.

### What actually happened

GregTech's `RecipeMap.postValidateRecipe` compares the recipe's *input count* against the map's own
limits, and **the assembler's maximum is nine**:

```
[Server thread/ERROR] [gregtech]: Invalid amount of recipe inputs. Actual: 10. Should be between 1 and 9 inclusive.
[Server thread/ERROR] [gregtech]: Stacktrace: ...
```

An integrated circuit added with `.circuit(1)` **is** one of those inputs - the assembler's builder is
`IntCircuitRecipeBuilder`, and the programmed circuit is put into the recipe's input list. So a recipe
written from a 3x3 grid as *nine separate stacks* plus a circuit is ten inputs: it is rejected and
**never enters the map at all**. The message is loud in `logs/latest.log` and completely absent from
`crafttweaker.log`, which is exactly why the earlier passes looked clean - they read the script log for
errors, and the script log had none.

Counted in `logs/run-6al-final.log`: 25 such errors. Counted in the scripts: exactly 25 recipe builders
whose inputs plus circuit exceed nine - 24 in `assembler_2.zs` and 1 in
`eio_upgrades.zs`. The two lists are the same list: this was not an approximation, it
was the whole of the damage, and every machine the owner could not craft is in it.

| Mod | Recipes that had been silently deleted |
| --- | --- |
| Galaxy Space | hydroponic farm, energy pad, planet shield, oxygen storage cluster, gravity module, modern machine frame |
| PlanetProgression | telescope, basic satellite module, satellite launch module, satellite controller, satellite builder, launch pad |
| Galacticraft Planets | Mars machine (cryogenic chamber), short range telepad |
| Galacticraft core | both cargo loaders, buggy storage box, ambient thermal controller, telemetry unit |
| Ender IO | liquid conduits (both tiers), item conduit, the blank dark steel upgrade |

### The fix

Repeated slots are folded into a count - `<minecraft:glass> * 5` instead of five separate
`<minecraft:glass>` entries. In an assembler those are the same requirement (each entry is one
ingredient the input bus has to satisfy) and it is how GregTech writes its own recipes, so nothing is
dropped, no count is lowered, and the empty cells the original grid had were already omitted. The 25
lists now hold eight entries or fewer and the circuit fits.

### PlanetProgression, as the first of these mod-by-mod passes

The mod owns ten things. Where each of them comes from now:

| Item | Route, and what it costs |
| --- | --- |
| Telescope | assembler, MV 120: compressed tin x4, diamond block x2, compressed aluminium x2, glass pane |
| Basic Satellite Module | assembler, MV 120: heavy aluminium wire x4, `basic_item:14` x2, compressed bronze x2, green dye |
| Satellite Launch Module | assembler, MV 120: compressed steel x6, `basic_item:19`, `basic_item:14`, aluminium wire |
| Satellite Controller | assembler, MV 120: compressed aluminium x4, basic satellite x2, heavy aluminium wire x2, `basic_item:14` |
| Satellite Builder | assembler, MV 120: compressed aluminium x6, heavy aluminium wire x2, `basic_item:14` |
| Satellite Launch Pad | assembler, MV 120: compressed iron x6, iron block x3, **nine pads out** |
| Communication Dish Keycard | assembler, LV 30: compressed iron x3, Galacticraft dish base x3, iron block x3 |
| Basic Satellite | not crafted: the mod builds it in its own Satellite Builder |
| Research Paper | loot only - the mod's own lang file says dungeon loot, a world-gen structure, or the Satellite Controller |
| Satellite Rocket | not a crafting recipe at all: the mod's own NASA-workbench schematic (`SatelliteRocketRecipes`), nine heavy-duty plates and a nose cone; it stays in Galacticraft's rocket workbench |

Two corrections came out of this pass, and both were the pack's fault rather than the mod's:

* **The launch pad's yield.** PlanetProgression's JSON asks for **nine** pads per craft (the pad is
  placed as a 3x3) and the flattened recipe was handing out one. It is `<...> * 9` again.
* **The keycard** was the mod's last remaining crafting-table recipe. It is a chip card - the kind of
  item GregTech expects out of an assembler - so it moved there too, with the mod's own nine materials
  plus the circuit.

### Evidence

A temporary CraftTweaker read-back script (since deleted) walked the finished assembler map through
`mods.gregtech.recipe.RecipeMap.getByName("assembler").recipes` and printed, for each of the 24 lost
outputs and for PlanetProgression's seven:

```
VCHECK assembler maxInputs=9 recipes=4506 targets=24
VCHECK Hydroponic Farm Block = true      ... (all 24 read "true")
VPP planetprogression:telescope:0 x1
VPP planetprogression:satellite_module_basic:0 x1
VPP planetprogression:satellite_launcher:0 x1
VPP planetprogression:satellite_controller:0 x1
VPP planetprogression:satellite_builder:0 x1
VPP planetprogression:advanced_launch_pad:0 x9
VPP planetprogression:dish_keycard:0 x1
VPP planetprogression assembler recipes = 7
VPP assembler output stacks with amount>1 = 293
```

One trap in that check is worth recording: `IItemStack.matches` is not an identity test - it compares
stack size and NBT too, so the x9 launch pad and the NBT-carrying dark steel upgrade both read as
"missing" until the comparison was changed to item id plus metadata.

Run: 47 mods, `Done (6.038s)`, zero `crafttweaker.log` errors, **zero** `Invalid amount of recipe
inputs` (was 25), the two baseline `Invalid recipe` lines, no `duplicate or conflict`.

### The rule to keep

Before writing an assembler recipe from a script: `number of .inputs() entries + (1 if .circuit(n) else
0) <= 9`. Nine grid slots only fit without a circuit; with one, fold or drop to eight. A script that
breaks it still loads, still logs nothing, and leaves a machine that cannot be built.

## 6an. "Ingots straight into a block" - the crafting table stops being the compressor - 2026-10-12

The owner's request for this pass: *"now about AE2 - look at some unreasonable recipes, especially
ingots straight into a block, and check whether any recipe is missing."* Both halves turned out to be
about the same mechanism, and the second half answers a question the earlier audits could not.

### What AE2 was doing at the crafting table

AE2's quartz block and fluix block were compressed by hand, and the pack had made them *more* explicit:

| Recipe | Was | Now |
| --- | --- | --- |
| quartz block, four certus quartz crystals | 2x2 + hard hammer on the table | packer, 4 crystals + 2x2 mould |
| quartz block, grown crystals | 3x3 (8 crystals) + hard hammer on the table | **compressor, 9 crystals** |
| fluix block, four fluix crystals | 2x2 + hard hammer on the table | packer, 4 crystals + 2x2 mould |
| fluix block, grown crystals | 3x3 (8 crystals) + hard hammer on the table | **compressor, 9 crystals** |

"Put N of a thing in and get the compressed block out" is the packer's and the compressor's job - it is
the one shape a GregTech pack must not hand out on the table - so the four table recipes are gone. The
two *plain* machine recipes are not ours: Gregicality mirrors AE2's own registered 2x2 JSON recipe onto
the packer with the same mould its material recipes use, and that mirror survives deleting the table
recipe (measured: the packer's recipe count does not drop when the table recipe goes). The *grown*
crystal conversion had no mirror, because AE2 writes that one as a 3x3 with the centre empty; it is
written out in `ae2_base.zs`, in the compressor, because the packer accepts only **two**
inputs - one ingredient plus one non-consumed mould - and because nine-into-a-block is precisely how
GregTech splits the two machines itself (four on the packer, nine on the compressor). Nine is one
crystal more than AE2's own eight, so the move never makes the block cheaper.

A cut block is still sawn to size on the table (chiselled quartz, the pillar, stairs, slabs - all of
them already carry a GregTech saw), the three 1:1 sky-stone conversions keep their saw, and AE2's own
`deconstruction_*` recipes stay where they are: they take a block *apart* into four crystals, so there
is nothing to exploit (four crystals into a block on the packer, four crystals back out again).

### The same complaint, measured across the whole pack

The audit dump answered *how many* "nine of one thing into a block" recipes exist: Gregicality
generates `block_compress_<material>` and `block_decompress_<material>` for every GregTech material,
and Ender IO's seven endergy alloys bring `auto_<material>_9_ingots_to_1_block` /
`auto_<material>_1_block_to_9_ingots` with them - **1074 recipes in the crafting registry**, every one
of them a way to skip the compressor.

`src/main/java/com/minespace/unofficial/gtceu/MinespaceCraftingBlocks.java` (new, called from
`FMLLoadCompleteEvent`) deletes them **per recipe, not by name alone**: a recipe goes only when a
GregTech recipe map already makes the same item. That is what keeps the sixteen pairs that have nowhere
to go - Ender IO's seven endergy alloys (crude steel, crystalline, melodic, stellar, crystalline pink
slime, energetic silver, vivid alloy - no GregTech material exists for them), Galaxy Space's sulphur
dust and Forestry's ash - on the crafting table, so nothing becomes unobtainable. The log prints the
counts and every kept name on each launch:

```
crafting-table compression (loadComplete pass): 1058 of 1074 compression / decompression recipes
    deleted, 16 kept because no GregTech machine makes the same item
crafting-table compression: kept forestry:ash:0 (gtadditions:block_decompress_ash) - no machine route
crafting-table compression: kept galaxyspace:gs_basic:7 (gtadditions:block_decompress_sulfur) - no machine route
crafting-table compression: kept enderio:block_alloy_endergy:0 (enderio:auto_crude_steel_9_ingots_to_1_block) ...
```

### The missing-recipe audit: 128 machine recipes that could no longer be run

The second question - "is anything missing?" - was answered by the same audit from the other side. An
ingredient whose *every* alternative is an item the pack has unified away (section 6i, 6j, 6l: the
mod's copies of copper, tin, aluminium, meteoric iron, desh, titanium, lead, cobalt, nickel and the
three silicons) can never be supplied again, so any recipe that requires one by exact item is dead
weight - and JEI shows it as if it worked. **128** machine recipes are in that state, listed in the
log with their inputs and outputs:

```
unreachable machine recipe: compressor 9xappliedenergistics2:material:5 -> 1xgregtech:meta_block_compressed_3:13
unreachable machine recipe: compressor 9xgalacticraftcore:basic_item:3 -> 1xforestry:resource_storage:1
unreachable machine recipe: compressor 9xenderio:item_alloy_nugget:7 -> 1xgregtech:meta_item_1:10260
...
unreachable machine recipes (loadComplete pass): 128 deleted (ingredients that only the unified-away
    mod items could satisfy)
```

The first line is the one that mattered for AE2: the compressor and the packer both still carried a
silicon-block recipe taking **AE2's** silicon, which nothing has produced since 6l. GT's own silicon
block route (nine `gregtech:meta_item_1:10061` ingots) was there all along, so nothing was uncraftable -
but the dead recipes were what JEI showed next to it. An ingredient that still lists GregTech's item
among its alternatives is left alone by this pass, because it works; that is why the pass deletes 128
recipes and not the thousands that merely *print* a mod item first in the audit dump.

Everything else the audit could have flagged for AE2 resolves to one of AE2's own machines or to world
generation: the charger makes charged certus quartz, the growth chamber the pure crystals, the
inscriber the presses, the printed circuits and the three processors, the matter condenser the matter
balls and singularities, and the sky stone and the two certus ores come out of the world. No AE2 item
is without a producer.

### Verification

A read-only CraftTweaker probe (since deleted) read the two machines back at load complete:

```
AE2CK packer maxInputs=2 recipes=2754
AE2CK   packer makes appliedenergistics2:quartz_block:0 x1
AE2CK   packer makes appliedenergistics2:fluix_block:0 x1
AE2CK packer crystal-block recipes = 2
AE2CK compressor maxInputs=1 recipes=924
AE2CK   compressor makes appliedenergistics2:quartz_block:0 x1
AE2CK   compressor makes appliedenergistics2:fluix_block:0 x1
AE2CK compressor crystal-block recipes = 2
```

Two packer routes (the mod's own four-crystal conversion, as before the change) and two compressor
routes (the grown-crystal conversion, where the audit before this pass showed none).

Run: 47 mods, `Done (5.336s)`, zero `crafttweaker.log` errors, zero `Invalid amount of recipe inputs`,
the two baseline `Invalid recipe` lines, no `duplicate or conflict`.

## 6ao. Machines have no slots - merging the assembler's duplicates, and the last high-tech items - 2026-10-12

Two more reports in the same sitting: *"some items in the assembler have recipes moved straight over
from the crafting table - they should be merged, the assembler has no need for material order"* and
*"besides the unrealistic ones, high-tech items should go through the assembler while low-tech ones
can stay on the crafting table."*

### The duplicates: a grid has slots, a machine does not

A crafting grid is order-sensitive, so a mod that registers one shape can register a second shape for
the same item - Galacticraft's beam reflector exists with the lever in either of two cells, its rocket
engine with the flint and steel and the stone button swapped. Both shapes were moved to the assembler
as their own recipe, and there they are the *same* recipe twice: the machine matches the input bus,
not a pattern. They are merged
(`src/main/java/com/minespace/unofficial/gtceu/MinespaceRecipeDedupe.java`, called from
`FMLLoadCompleteEvent`):

```
recipe de-duplication (loadComplete pass): 217 recipes removed as input-order duplicates; by map:
    {compressor=10, macerator=2, assembler=15, mixer=7, fluid_solidifier=162, fluid_extractor=2,
     electrolyzer=1, chemical_reactor=1, alloy_smelter=2, cutting_saw=3, packer=2, unpacker=2,
     large_chemical_reactor=1, large_mixer=7}
```

Two recipes count as the same when *everything the machine can see* matches once the inputs are
sorted: each ingredient by the sorted list of stacks it accepts plus its count (so the integrated
circuit, which is one of those inputs, keeps recipes apart), the fluid inputs **and fluid outputs**, the
item outputs, and the chanced outputs with their chances. The fluid outputs are in there because a
distillation recipe and its neighbour can share an input and still produce a different fluid: the first
version of this pass left them out and reported **404**, and adding them took the number to **217** -
the 187 that disappeared were exactly those false pairs (distillery 175, pyrolyse oven 7, bio reactor 3,
chemical reactor 1, large chemical reactor 1). A wrong merge here would have deleted a working
distillation recipe, so that correction matters. Duration and EU/t are deliberately *not* part of the
test: the map hands out its first match either way, so dropping the later entry changes nothing a
player sees. Where a group holds both a hidden and a visible recipe, the visible one is the one kept,
so nothing disappears from JEI.

### The last high-tech items on the crafting table

`hightech.zs` closes the gap the two earlier assembler passes left. Every item in it
is a machine, a machine frame, a rocket part or an electronic component, and each keeps its own
materials and output:

| Mod | Moved | Tier |
| --- | --- | --- |
| Galacticraft core | air fan, oxygen bubble distributor, oxygen detector, spin thruster, display screen, chromatic applicator (`machine3:0`), the NASA workbench itself | LV 30 |
| Galacticraft Planets | Mars machine, miner base | MV 120 |
| Galaxy Space | machine frames 0 and 1 (tier 2 was already moved), liquid extractor, hydroponic base, modification table, radiation stabiliser, rocket assembler, first rocket module, the two machine upgrades | MV 120 |
| Applied Energistics 2 | spatial and storage components (16/128 cubed plus 1k..64k), ME storage housing, blank pattern, the three fluid components, the three entry-level cells and the crafting accelerator | LV 30 for the 1k tier, MV 120 above |

Deliberately left on the table, because they are low-tech or building work rather than devices: the
hydraulic platform and the air lock frame, AE2's cables and their dyeing, the paint balls, quartz glass
and the decorative cuts, Galacticraft's coloured blocks, and the wood / stone / food families.

One trap re-appeared while writing it: the chromatic applicator's own grid is *eight dyes plus a
compressed steel plate*, and adding an integrated circuit made it ten inputs, so the assembler threw it
away with the familiar `Invalid amount of recipe inputs. Actual: 10` in the log and the item came back
as missing from the verification probe. It is the one recipe in the file without a circuit, with a
comment saying why - nine materials fill the machine's nine inputs (section 6am).

### Verification

A read-only probe (since deleted) asked the assembler map for all 36 outputs:

```
HITECH assembler recipes=4541 targets=36
HITECH galacticraftcore:air_fan:0 in assembler = true
... (36 lines, all true after the circuit fix)
```

Run: 47 mods, `Done (4.634s)`, zero `crafttweaker.log` errors, zero `Invalid amount of recipe inputs`,
zero `duplicate or conflict`, the two baseline `Invalid recipe` lines, and the three load-complete
passes reporting 1058 / 128 / 404.

## 6ap. The client crash was the audio library, not a recipe - 2026-10-12

The owner reported "it crashed" right after the recipe passes. It was not them. The client's
`hs_err_pid23020.log` (the JVM's own crash dump - Forge wrote no crash report, which is the first clue
that nothing in the pack threw the exception) says:

```
#  EXCEPTION_ACCESS_VIOLATION (0xc0000005) at pc=0x000002e49bcd1066
# Problematic frame:
# C  [OpenAL64.dll+0x11066]
Current thread: JavaThread "Thread-7"      <- the Sound Library Loader
```

and `logs/latest.log` ends, in order, at:

```
[Sound Library Loader/INFO] [SoundManager]: Starting up SoundSystem...
[Thread-7/INFO] [SoundManager]: Initializing LWJGL OpenAL
[Thread-7/INFO] [SoundManager]: (The LWJGL binding of OpenAL ...)
```

- i.e. the process died inside the OpenAL native library while opening the audio device, before the
  main menu. `versions/1.12.2-forge-14.23.5.2859/natives/OpenAL64.dll` is the 2013 OpenAL Soft 1.15.1
  that LWJGL 2.9.3 (and so Minecraft 1.12.2) ships, and its Windows device path is what faults.

The recipe work of 6am - 6ao is unrelated, and the evidence is the whole point of this entry: the
dedicated server runs the *same* jar and the *same* scripts and started cleanly six times in a row
(`47 mods`, `Done (...)`, zero `crafttweaker.log` errors), because a dedicated server never opens an
audio device. The recipe passes 1058 / 128 / 404 all reported the same numbers on the last of those
runs.

### The fix

`alsoft.ini` in the instance root, handed to the game by `Play-Minespace.ps1` through the `ALSOFT_CONF`
environment variable:

```ini
[general]
drivers = winmm      ; the plain Windows waveOut backend; the DirectSound path is the one that faults
sample-type = int16
period-size = 1024
```

Two ways out if it ever comes back, both written into the file as comments: set `drivers = null` to run
with sound switched off entirely, or replace `natives/OpenAL64.dll` with a current OpenAL Soft build
(1.23.1 or newer), which fixes the bug class and keeps the modern backends.

### Verification

The client was launched again with the configuration in place and reached the main menu with audio
working:

```
[Thread-7/INFO] [SoundManager]: OpenAL initialized.
[Sound Library Loader/INFO] [SoundManager]: Sound engine started
```

No new `hs_err_pid*.log`, and the process stayed up. The crashed run's logs are parked as
`logs/run-client-crash.log` and `logs/hs_err_pid23020-crash1.log`; the fixed run's as
`logs/run-client-fixed.log`.

## 6aq. "Why do items that already have an assembler recipe still have a crafting-table one?" - 2026-10-12

The owner asked exactly that. The answer is a CraftTweaker ordering rule the pack had already met once
and this session met twice more: **all `recipes.remove(...)` calls of every script are applied before
any `recipes.add...(...)` call of any script.** So

- a script that *removes* a table recipe and *re-adds* a hardened one (the "rewrite it harder" pattern
  used all over `gs_removals.zs` and `ae2_base.zs`) always ends up with its re-added
  recipe in the table, no matter what a *later* script removes;
- and a mod that registers a crafting recipe after CraftTweaker's action pass (Ender IO's XML files,
  Galaxy Space's code, Gregicality's own compressed-plate recipes) simply puts it back after the
  scripts have had their turn.

Both were happening. The photo finish of it: the items the two new assembler passes moved were, in most
cases, items an *earlier* pass had already rewritten as a crafting-table recipe - so `zzzzzzzz_
minespace_hightech.zs` removed them, the add phase put them back, and the machine-only rule looked
broken.

### Finding them without guessing

A temporary diagnostic (since removed) read the finished crafting registry at `FMLLoadCompleteEvent` and
asked, for all 310 items this pack writes a machine recipe for, which ones still had a table recipe. It
printed **38**, and every one of their recipe names answered the question by itself:

```
machine-output audit: 38 of 310 items this pack makes in a machine still have a crafting-table recipe
machine-output audit: still craftable galaxyspace:machineframes:0 (crafttweaker:ct_shaped336284053)
machine-output audit: still craftable appliedenergistics2:material:35 (crafttweaker:ct_shaped706870359)
machine-output audit: still craftable galaxyspace:compressed_plates:1 (gtadditions:plate_cobalt)
machine-output audit: still craftable galacticraftplanets:item_basic_asteroids:6 (gtadditions:flatten_plate_titanium)
```

Twenty-nine of the thirty-eight carry this pack's own `crafttweaker:ct_shaped...` names (the older
rewrites), six carry Gregicality's `gtadditions:plate_*` / `flatten_plate_*` names - the very
"one plate into a compressed plate on the crafting table" shortcut that section 6o wanted gone - and
three were deliberate: Galacticraft's two canister forms and its glowstone torch, where the machine
recipe is a *bonus* route next to a table recipe rather than a replacement.

### The fix: enforce it late, and list what was found

`MinespaceCraftingBlocks.removeLeftoverCraftingRecipes` (called from `FMLLoadCompleteEvent`, after
every script's add phase *and* every mod's own registration) deletes a table recipe whenever its output
is on the machine-only list, using the same placeholder-registration trick
`ModHandler.removeRecipeByName` uses, and logs every single one. The list is
`src/main/resources/minespace_machine_only.txt`: every item the scripts write a machine recipe for,
minus the three deliberate exceptions above. It currently holds 307 items and is regenerated from the
scripts with:

```powershell
$outs = New-Object System.Collections.Generic.HashSet[string]
foreach ($f in Get-ChildItem scripts -Filter *.zs) {
  foreach ($m in [regex]::Matches([IO.File]::ReadAllText($f.FullName), '\.outputs\(\s*(<[^>]+>[^),]*)')) {
    if ($m.Groups[1].Value -match '^<([^>]+)>') { [void]$outs.Add($matches[1]) }
  }
}
[IO.File]::WriteAllLines('src/main/resources/minespace_machine_only.txt',
    ($outs | Where-Object { $_ -notin 'galacticraftcore:canister:0','galacticraftcore:canister:1','galacticraftcore:glowstone_torch:0' } | Sort-Object))
```

The first run with the new list reported:

```
machine-only enforcement (loadComplete pass): 35 crafting-table recipes were still there for items this
    pack moved into a machine and have been deleted
machine-only enforcement: galaxyspace:machineframes:0 (crafttweaker:ct_shaped336284053)
machine-only enforcement: appliedenergistics2:material:57 (crafttweaker:ct_shaped781159186)
machine-only enforcement: galaxyspace:compressed_plates:1 (gtadditions:plate_cobalt)
... (all 35, item by item)
```

35 = 38 collected by the diagnostic minus the three deliberate exceptions. The messages keep printing
on every launch, which is the point: if a mod update ever re-registers one of these recipes, the log
says so and the recipe is removed anyway.

The older scripts' rewrite blocks for those 29 items are left in place on purpose: they are inert now
(the enforcement pass deletes their output at load complete), and rewriting two large script files
mechanically would risk more than it fixes. The single source of truth for "this item is made in a
machine only" is `minespace_machine_only.txt`.

### Verification

Run: 47 mods, `Done (3.556s)`, zero `crafttweaker.log` errors, zero `Invalid amount of recipe inputs`,
zero `duplicate or conflict`, the two baseline `Invalid recipe` lines, and the four load-complete
passes reporting 1058 / 128 / 35 / 404.

## 6ar. The AE2 line starts at MV - 2026-10-12

The owner's question: *"looking at the whole AE2 tech line, can the crafting voltage be raised so it
starts at MV?"*

### Can it, and is it smooth

Yes, and nothing deadlocks. AE2 is a leaf in this pack - no other mod's recipes ask for it - so a
player only reaches it after MV is already available, and AE2's own power comes from machines this pack
now builds in an MV assembler (the vibration chamber burns fuel into AE; the energy acceptor takes FE,
which Gregicality's converters supply from ULV to HV). Nothing in AE2 needs AE2 to start. The ceiling
question ("does anything need 120 EU/t before an MV assembler exists?") answers itself: an MV assembler
is one MV machine hull and heat-proof casings, entirely inside GregTech's own line.

### What was raised

Every AE2 assembler recipe the pack writes was at or above MV except forty-nine at 30 EU/t. Those are
now 120: the machines (charger, inscriber, drive, ME chest, crafting unit, energy acceptor, condenser,
interface, fluid interface, IO port, vibration chamber, cell workbench, quartz growth accelerator), the
4k storage cells, the 1k components and cells, the wireless and terminal families, the cards, the
quartz and fluix blocks, and the components and housings of 6ao. The inventory afterwards:

```
AE2 assembler recipes: 90      below MV (120): 0
   120 EU/t -> 80 recipes      (MV)
   480 EU/t ->  9 recipes      (HV: the 16k/64k crafting storages, the quantum ring, the 128-cubed cell)
  1920 EU/t ->  1 recipe       (the 64k crafting storage)
```

An MV assembler is therefore the gate for the whole line: an LV assembler cannot run a 120 EU/t recipe
at all.

### The one door that needed Java

AE2's quartz and fluix blocks had an LV way in that no script owns: Gregicality mirrors AE2's own 2x2
crafting recipe onto the **packer** for free, and the audit's finished recipes show it running at
**4 EU/t**. `MinespaceCraftingBlocks.removeSubMvAe2BlockRecipes` (called from
`FMLLoadCompleteEvent`) deletes any packer or compressor recipe producing those two blocks below
120 EU/t - two recipes on the run - and `ae2_base.zs` writes the MV replacements: four
crystals plus the 2x2 mould on the packer, nine grown crystals on the compressor. Both directions stay
machine-only as 6an set them up.

### What deliberately stays below MV, and why

- **Material pre-processing.** Grinding certus quartz, nether quartz, fluix or sky stone into dust
  happens in GregTech's ordinary ore-processing machines at their ordinary LV settings, exactly like
  every other material in the pack. The gate is on AE2's *manufacturing*, not on the material chain -
  raising the macerator would gate every ore in the pack, not AE2.
- **AE2's own machine recipes.** The inscriber, charger, growth chamber and matter condenser run on AE,
  not EU, so they have no EU/t to raise; their gate is that the machines themselves are MV assembler
  work now.
- **Cables, paint balls, quartz glass and the decorative cuts** stay on the crafting table, per the
  owner's own rule that low-tech, in-world work stays there. If the intent is a *fully* MV-gated
  network - cables included - they can move into the assembler next; say the word.

### Verification, and one self-inflicted scare

The retier itself was a bulk edit of three scripts, and the first attempt cut one `.buildAndRegister()`
line out of `ae2_base.zs` while removing an older duplicate block: CraftTweaker then refused
the whole file (`Error parsing ae2_base.zs:958 -- ; expected` in `crafttweaker.log`), which
dropped every recipe and removal in it and made the run's counts look wrong (1097 compression recipes
instead of 1074, 470 machine-only deletions instead of 35). The parse error pointed straight at the
line, the two missing lines went back in, and the next run was clean. Worth remembering: after a bulk
edit, check `crafttweaker.log` for `Error parsing` before reading anything else in the log.

Run: 47 mods, `Done (5.233s)`, zero `crafttweaker.log` errors, zero `Invalid amount of recipe inputs`,
zero `duplicate or conflict`, the two baseline `Invalid recipe` lines, and the five load-complete
passes reporting 1058 / 128 / 2 / 35 / 217.

## 6as. "Why is it still there?" - the machine routes no script wrote - 2026-10-12

After 6aq the owner reported it again: items with an assembler recipe *and* a crafting-table recipe. The
enforcement of 6aq only knew about the items **this pack's scripts** put into a machine, and a fresh
audit of the finished registries showed two families it could not see:

1. **machine routes nobody in this pack wrote.** Gregicality mirrors a mod's own crafting recipe onto a
   GregTech machine. AE2's dense covered cable is the clear case: four cables into one dense cable exists
   as a packer recipe (written by Gregicality, not by us) *and* as the mod's crafting recipe (plus our
   6z rewrite of it), so JEI showed it under both tabs.
2. **"N identical things into a block" recipes named after the mod.** Section 6an's pass matched
   *names* (`block_compress_*`, `auto_*_9_ingots_to_1_block`); Forestry's copper / tin / bronze /
   apatite / charcoal blocks carry Forestry's own names, Galaxy Space's block family carries
   `galaxyspace:barnarda_c_blocks`, and the vanilla iron / gold / diamond / emerald / coal / lapis /
   redstone / quartz / glowstone blocks carry vanilla's - all of them have a GregTech compressor or
   packer route and none of them matched the pattern.

### The rule, after two wrong attempts

`MinespaceCraftingBlocks.removeDuplicatedTableRoutes` (called from `FMLLoadCompleteEvent`) deletes a
crafting-table recipe when its output has a GregTech machine route **and** the recipe's output is either

- an item of one of the mods this pack gregifies (AE2, Ender IO, Forestry, Galacticraft, Galacticraft
  Planets, Galaxy Space, PlanetProgression, Iron Chests, Storage Drawers); or
- one of those nine vanilla material blocks, in the "four or more identical things into one" shape.

The output's namespace decides, not the recipe's, and that distinction is what the first two attempts
got wrong. Attempt one treated *any* uniform "N identical ingredients" recipe as a compression and
deleted 110 recipes including chests, crafting tables, glass panes, leather and hay blocks; attempt two
trusted the recipe's namespace and deleted 49, including Galacticraft's cobblestone alternatives,
Forestry's string-from-silk / letter recycling / beeswax-to-torch tweaks and Ender IO's stick recipe -
all of which merely *produce a vanilla item* and were never part of the gregification. The final rule
finds the 54 that matter:

```
no-double-route (loadComplete pass): 54 crafting-table recipes deleted because a GregTech machine makes
    the same item
no-double-route: appliedenergistics2:part:516 (appliedenergistics2:network/cables/dense_covered_fluix_clean) [appliedenergistics2]
no-double-route: appliedenergistics2:part:516 (crafttweaker:ct_shapeless-1809018434) [appliedenergistics2]
no-double-route: minecraft:iron_block:0 (minecraft:iron_block) [material block]
no-double-route: forestry:resource_storage:1 (forestry:copper_block) [forestry]
no-double-route: forestry:thermionic_tubes:4 (forestry:greenhouse_heater) [forestry]
no-double-route: galaxyspace:barnarda_c_blocks:5 (galaxyspace:barnarda_c_blocks) [galaxyspace]
... (54 in total, item by item)
```

Kept on purpose: GregTech's and Gregicality's own namespaces (those items have both routes by
GregTech's own design - a machine crafted at the table with a wrench and a hammer is what every
GregTech player expects), the "four small dusts into a dust" assembly recipes (a GregTech convention,
not a shortcut), the three Galacticraft items where the machine recipe is a bonus route (the two
canister forms and the glowstone torch), and every vanilla recipe that is not a material compression.

### Verification

The two enforcement passes now divide the work between them - this one takes 54, the 6aq pass takes the
remaining 6 (it runs second and sees the rest as already deleted), so all 60 items that had two routes
are down to one:

```
no-double-route (loadComplete pass): 54 crafting-table recipes deleted ...
machine-only enforcement (loadComplete pass): 6 crafting-table recipes were still there ...
```

Run: 47 mods, `Done (3.983s)`, zero `crafttweaker.log` errors, zero `Invalid amount of recipe inputs`,
zero `duplicate or conflict`, the two baseline `Invalid recipe` lines, and the six load-complete passes
reporting 1058 / 128 / 2 / 54 / 6 / 217.

## 6at. Why JEI kept showing the recipes we had already deleted - 2026-10-12/13

The owner reported it twice: *"items with an assembler recipe still have a crafting-table one"*, and
when asked which ones, *"AE2's storage cells"*. The deletions were real - the Java passes printed every
name and the registry agreed - but JEI kept showing the recipes, and the reason is a load-order trap
worth remembering:

**JEI builds its recipe index inside its own `FMLLoadCompleteEvent` handler, and every mod's load
complete handler runs in mod-load order. JEI loads before this mod.** The timestamps from a client run
say it plainly:

```
[21:38:44] [jei]: Building recipe registry...
[21:38:50] [minespace]: no-double-route (loadComplete pass): ... deleted
```

JEI took its snapshot six seconds *before* the clean-ups ran. Everything after that - our recipe being
gone from the registry, the block being uncraftable, the item not appearing when you click the
ingredient - was true, and JEI still listed it. That is why two rounds of "I deleted it, here is the
log" did not change what the owner saw.

### The fix

The six clean-up passes now run **twice**: once from `postInit`, which is early enough for JEI, and
again from `loadComplete` as a safety net. `postInit` is also late enough for every recipe source this
pack cares about - CraftTweaker applies its own actions during its postInit and it loads before this
mod, and Gregicality's mirrored machine recipes exist by then - so the first run sees the same finished
recipe set the second one used to. Every pass is idempotent, so the second run simply reports zero.

### Verification

The same client run, with the passes moved:

```
[08:30:52] [minespace]: crafting-table compression (postInit pass): 1058 of 1074 ... deleted, 16 kept
[08:30:53] [minespace]: unreachable machine recipes (postInit pass): 128 deleted
[08:30:53] [minespace]: AE2 MV floor (postInit pass): 2 packer / compressor recipes below MV deleted
[08:30:53] [minespace]: machine-only enforcement (postInit pass): 35 crafting-table recipes ... deleted
[08:30:53] [minespace]: no-double-route (postInit pass): 25 crafting-table recipes deleted
[08:30:53] [minespace]: recipe de-duplication (postInit pass): 217 recipes removed as input-order duplicates
[08:31:03] [jei]: Building recipe registry...          <- now AFTER the clean-ups
[08:31:09] [minespace]: ... (loadComplete pass): 0 ...  <- nothing left for the safety net
```

The AE2 storage cells the owner meant - `storage_cell_1k`, `fluid_storage_cell_1k`,
`spatial_storage_cell_2_cubed` and the components they are built from (`material:32/35/54`) - are in
that 35, so their crafting-table recipes are gone before JEI ever looks. The 4k / 16k / 64k cells were
already assembler-only since 6x. JEI rebuilds its index on every launch (there is no on-disk cache), so
one restart is all it takes.

Server run afterwards: 47 mods, `Done (5.678s)`, zero `crafttweaker.log` errors, zero
`Invalid amount of recipe inputs`, zero `duplicate or conflict`, the two baseline `Invalid recipe`
lines, every pass reporting the same numbers at postInit and 0 at load complete.

## 6au. AE2's storage family, redesigned instead of copied - 2026-10-13

The owner's verdict on the assembler passes: *"you are almost copying the original recipes over, there
is no invention in it"*, plus *"some crafting-table recipes do not look like recipes for that item"*,
and, about the storage items specifically, *"it is still not cleaned up"*. All three were fair:

- the assembled recipes were AE2's own grids flattened, with GregTech parts pushed into the slots;
- the 1k storage cells still had a **crafting-table** recipe, and it was this pack's own: 6x had removed
  AE2's copy and re-added a 3x3 of quartz glass, redstone and iron plates, plus the mod's "housing +
  component" shapeless as a second route. The late passes deleted both before JEI looked (6at), but the
  script was still writing them, so the model the owner was looking at *was* the old one;
- a three-quartz-glass-three-redstone cell does not read as "a card in a cage", which is exactly the
  "does not look like this item" complaint.

### The recipe language

`ae2_storage.zs` holds the whole storage family now (25 items) and the shape of every
recipe says what the object is:

| Item | Reads as | Recipe |
| --- | --- | --- |
| 1k storage component | a chip | basic circuit + 2 certus quartz + 4 fine tin wires |
| 4k / 16k / 64k component | the same chip, denser | good / advanced circuit + two of the previous tier + fine copper / silver / electrum wires |
| 1k..64k fluid component | a chip with a pipe | the storage chip's shape with a tiny steel / stainless / titanium pipe instead of the wire |
| spatial components | geometry storage | good / advanced circuit + 2 fluix pearls + fine gold / electrum wires |
| ME storage housing | a card cage | 4 aluminium plates + 2 quartz glass windows + 3 steel screws + a basic circuit |
| blank pattern | a data card | a plastic plate + aluminium foil + a basic circuit |
| storage / fluid / spatial cell | a card in the cage | housing + the matching component + 2 screws + a circuit |
| crafting accelerator | a CPU card | crafting unit + good circuit + 2 steel screws + 4 fine red-alloy wires |

The tier is legible from the recipe rather than from a number (basic -> good -> advanced circuits, tin ->
copper -> silver -> electrum wires, steel -> stainless -> titanium pipes, steel -> aluminium -> stainless
screws), nothing is cheaper than what it replaced - every recipe carries GregTech parts the mod's grid
never asked for - and the assembler circuits 1 to 8 keep the eight families apart in JEI.

### What was removed

The old blocks for these 25 items were cut out of `zae2_base.zs` (the crafting-table rewrites
and the two shells of the 1k cells included, 24 blocks) and `hightech.zs` (17 blocks),
and both files now carry a note saying where the family went.

### Verification

A read-only probe (since deleted) counted assembler recipes per item:

```
STORAGECHECK assembler recipes=4542 targets=25
STORAGECHECK appliedenergistics2:material:35 assemblerRecipes=1
STORAGECHECK appliedenergistics2:storage_cell_64k:0 assemblerRecipes=1
... (all 25 report exactly 1)
```

Run: 47 mods, `Done (4.264s)`, zero `crafttweaker.log` errors, zero `Invalid amount of recipe inputs`,
zero `duplicate or conflict`, the two baseline `Invalid recipe` lines. The later load-complete passes
report 16 crafting-table leftovers for the storage items - those are the last of the old rewrites, which
the script no longer writes, so on the next script pass they disappear from the log entirely.

### Still to do in this style

The AE2 *machines* (drive, inscriber, charger, interfaces, controller, quantum ring, ...) are still the
flattened originals; they get the same treatment next - GT casing or hull, circuits by tier, quartz glass,
and the AE2 part that makes the machine recognisable. Tell me which crafting-table recipes look wrong and
they go on the list too.

## 6av. Exporting AE2 and rebuilding its machines - 2026-10-13

The owner's instruction was blunt and fair: *"export AE2's recipes yourself, work out which ones are
neither scientific nor good-looking, and fix them yourself."* So the pack now has a temporary exporter
(`MinespaceAe2Export`, since deleted) that walks the finished registries at load complete and writes
every AE2 recipe to `ae2_recipes.txt` - 92 GregTech machine recipes with their inputs, counts, EU/t and
duration, and the 226 crafting-table recipes still on the table. Reading it is what found the pattern:

```
MAP assembler OUT appliedenergistics2:drive:0  IN 4x iron plate, 2x engineering processor, 2x ME cable
MAP assembler OUT appliedenergistics2:inscriber:0  IN 5x iron plate, 2x piston, 1x fluix crystal
MAP assembler OUT appliedenergistics2:vibration_chamber:0  IN 7x iron plate, energy acceptor, furnace
MAP assembler OUT appliedenergistics2:security_station:0  IN 4x iron plate, 2x ME cable, ME chest, ...
```

Every machine was AE2's own grid with GregTech iron plates pushed into the empty slots. That is not a
GregTech recipe and it does not look like the machine either - the complaint was right.

### The design language now used for AE2 machines

GregTech builds a machine out of a body, a function, a control and a signature, and
`ae2_machines.zs` (29 machines and tools) now does the same:

| layer | what it is |
| --- | --- |
| body | the machine casing of the tier - `machine_casing:2` = MV, `:3` = HV, `:4` = EV |
| function | the GregTech part that does the job: motor (turns), piston (presses), conveyor (moves items), robot arm (inserts them), emitter (projects), sensor (reads) |
| control | GregTech circuits of the tier: basic -> good -> advanced |
| signature | the AE2 part that makes the machine recognisable: quartz glass, fluix, a ME glass cable, an engineering processor, smooth sky stone |

The result reads like the machine: the Inscriber is a casing with two pistons (it presses), the Security
Station carries a sensor (it reads you), the Spatial IO Port and the Quantum Ring carry emitters (they
project), the Drive has two motors and two ME cables (two bays), the IO Port two conveyors (it moves
things in and out), the Energy Acceptor is a casing with four copper wires running in, and the two
cards are a plastic plate with a gold foil layer - a memory card adds a circuit, a biometric card adds a
sensor. Identifiers came from the same export: motors are `32600/01/02`, pistons `32640/41`, conveyors
`32630/31`, robot arms `32650/51`, emitters `32680/81`, sensors `32690/91`, casings `machine_casing:2..4`.

Nothing was made cheaper - the old grids never asked for a casing or a motor at all - and the tier is
legible from the recipe.

### Verification

The export was taken again after the change and shows one recipe per machine, in the new shape:

```
MAP assembler OUT 1xappliedenergistics2:drive:0 EUt=120 ticks=300 IN 2x32601 2xcircuitGood 2xpart:16 1xmachine_casing:2
MAP assembler OUT 1xappliedenergistics2:inscriber:0 EUt=120 ticks=300 IN 2x32641 2xcrystalCertusQuartz 1xmachine_casing:2 1xcircuitGood 1xplateAluminium
MAP assembler OUT 1xappliedenergistics2:security_station:0 EUt=120 ticks=400 IN 2xplateAluminium 1xmachine_casing:2 1x32691 1xcircuitGood 1xengProcessor
MAP assembler OUT 1xappliedenergistics2:quantum_ring:0 EUt=480 ticks=600 IN 2x32681 2xfluixPearl 1xmachine_casing:3 1xcircuitAdvanced 1xenergy_cell
```

Also visible in that export: the ME Drive and the view cell had *two* recipes each (the old rewrite and
the older grid); both are now one. Run: 47 mods, `Done (5.071s)`, zero `crafttweaker.log` errors, zero
`Invalid amount of recipe inputs`, zero `duplicate or conflict`, the two baseline `Invalid recipe` lines.

### What the export says to leave alone, and what is next

Left on the crafting table on purpose, because they are in-world work rather than machines: the 32 paint
balls (matter ball + dye), the cable colouring and washing, the decorative quartz and sky-stone cuts,
and the "four small dusts into a dust" assembly (a GregTech convention). The AE2 **parts** family - the
bus / panel / terminal rewrites of 6y and 6z - is the next batch: they read better than the machines did
(a piston, an interface, a circuit and a screwdriver) but the same treatment applies - an importer or an
exporter is a robot arm, a level emitter is an emitter, a monitor or a terminal is a display plus a
circuit.

## 6aw. AE2's parts and cards, built by function - 2026-10-13

The second half of the AE2 pass (the first was the machines, 6av). The exporter's crafting list showed
what was left: the parts were the pack's own crafting-table rewrites of 6y/6z - a storage bus was "a
piston, a ME interface, another piston, a screwdriver and an LV circuit" and was still made on the table
- and the two base cards were three iron plates, two gold ingots, a processor and some redstone.

`ae2_parts.zs` now writes all 30 of them as assembler recipes, each designed by what
the device does:

| device | how it is built |
| --- | --- |
| import / export bus (item and fluid) | two aluminium plates, a **robot arm** (it takes items in and puts them out), a ME cable, a circuit |
| storage bus (item / fluid / ore dictionary) | two plates, a ME cable, an AE2 processor - a channel onto the network, not a mover; the fluid one also takes a tiny steel pipe |
| annihilation / formation plane | two plates, the core that sets it, a **piston** that works it, a circuit |
| level emitter | two plates, a GregTech **emitter**, a ME cable, a circuit |
| terminal / crafting terminal / pattern terminal / interface terminal / fluid terminal | two plates, two quartz glass faces, a ME cable, a circuit (a chip too on the higher ones) |
| storage and conversion monitor | the same face-and-chip build with the panel recipe |
| interface parts (item and fluid) | two plates, two ME cables, an engineering processor, a circuit |
| P2P tunnel, toggle bus | two plates, a ME cable, a circuit |
| illuminated panel (light and dark) | a plate, a quartz glass face, glowstone dust, a circuit |
| basic card | a **plastic plate** with a **gold foil** layer, a circuit and redstone |
| advanced card | the same with a good circuit and a diamond |
| wireless receiver | a plate, a good circuit, a fluix pearl, two fine gold wires (an antenna) |
| crafting card, pattern expansion card | built on the blank pattern/plastic card idea instead of iron plates |

Everything that was a crafting-table rewrite is now machine work at MV (the interface terminal at HV),
and the four "upgrade on top of a card" recipes (redstone / capacity / fuzzy / acceleration / inverter)
keep their shape because a card with a chip added to it reads correctly.

### Verification

A read-only probe (since deleted) counted the assembler recipes per item:

```
PARTSCHECK assembler recipes=4560 targets=30
PARTSCHECK appliedenergistics2:part:220 assemblerRecipes=1
PARTSCHECK appliedenergistics2:part:80 assemblerRecipes=1
... (all 30 exactly 1)
```

`minespace_machine_only.txt` was regenerated from the scripts and grew from 307 to 326 items, so the
old crafting-table recipes for all of them are deleted before JEI indexes (6at) - the run reports 17
leftovers at postInit, which are the mod's own part recipes (`ME Interface` from the block, and friends)
that the new assembler recipes replace. Run: 47 mods, `Done (4.672s)`, zero `crafttweaker.log` errors,
zero `Invalid amount of recipe inputs`, zero `duplicate or conflict`, the two baseline `Invalid recipe`
lines.

### Where AE2 stands now

Machines (6av), storage (6au) and parts and cards (here) are all built the GregTech way, one recipe each,
at MV and up. What is left on the crafting table is deliberate and low-tech: the four cable families and
their colouring/washing, the 32 paint balls, the decorative quartz and sky-stone cuts, the certus quartz
hand tools, the crystal seeds and the "four small dusts into a dust" convention, and the growth chamber's
own recipes. Say the word for the next mod, or point at anything in AE2 that still reads wrong.

## 6ax. PlanetProgression, redone in the same idiom - 2026-10-13

With AE2 finished the owner asked for the same treatment on PlanetProgression, and the export of that
line showed the same shape as AE2's first pass: the mod's seven craftable items sat in the assembler as
their own crafting grids, flattened. The telescope was four compressed tin, two diamond blocks, two
compressed aluminium and a glass pane; the satellite builder was wiring, wafers, compressed bronze and
green dye; the keycard was compressed iron, dish bases and three iron blocks.

`planetprogression.zs` rewrites all seven with the vocabulary the AE2 passes use - an MV machine
casing for a body, the GregTech part that does the job, circuits by tier, and the mod's own signature
parts - while keeping the materials the mod's balance rests on:

| item | how it is built now |
| --- | --- |
| telescope | an aluminium **frame** for the mount, 2 MV motors for the tracking drive, 2 quartz glass lenses, one diamond block as the precision mirror, 4 aluminium plates as the tube and an MV sensor behind the eyepiece |
| satellite builder | MV casing + 2 robot arms + the bronze frame and the wafers it works in |
| satellite launcher | MV casing + 2 pistons (it is what throws the rocket up) + compressed steel + a wafer |
| satellite controller | MV casing + aluminium plates + wafers + a quartz glass screen + a sensor that listens |
| basic satellite module | a plate body carrying the heavy aluminium wiring, wafers and the bronze housing |
| launch pad | the same reinforced pad (compressed iron and iron blocks) plus the circuit that makes it a launcher, nine out |
| communication dish keycard | a plastic card with a gold foil layer, the dish link and the card body it always needed - no three iron blocks |

The telescope was wrong on the first try and the owner said so: it had a machine casing, **two** diamond
blocks (the mod's own pile - eighteen diamonds) as well as the quartz glass lenses, four compressed tin
for the tube and two motors, which is neither an optical instrument nor a sensible use of the materials.
The row above is the second attempt: a frame carries the tube, the motors drive it, the lenses are glass,
the mirror is a single diamond block, and a sensor sits where the eyepiece would be - the parts each do
the job their name says, and the diamond cost stays in the recipe rather than being doubled by the mod's
grid.

The two items that are not crafted stay as they are: the research paper is loot, and the Basic Satellite
is built inside the mod's own Satellite Builder. The rocket's NASA-workbench schematic is untouched.

### Verification

A read-only export (temporary, deleted) listed the machine recipes for every PlanetProgression item:

```
PPX MAP assembler -> planetprogression:telescope:0 x1
PPX MAP assembler -> planetprogression:satellite_builder:0 x1
PPX MAP assembler -> planetprogression:satellite_launcher:0 x1
PPX MAP assembler -> planetprogression:satellite_controller:0 x1
PPX MAP assembler -> planetprogression:satellite_module_basic:0 x1
PPX MAP assembler -> planetprogression:advanced_launch_pad:0 x9
PPX MAP assembler -> planetprogression:dish_keycard:0 x1
```

One recipe each, the pad still handing out nine, and the crafting-table counts for all seven are zero
once the pack's removals and the postInit enforcement have run (`machine-only enforcement: 18` on this
run, which includes the mod's own recipes behind them). Run: 47 mods, `Done (5.594s)`, zero
`crafttweaker.log` errors, zero `Invalid amount of recipe inputs`, zero `duplicate or conflict`, the two
baseline `Invalid recipe` lines.

## 6ay. Script names that say what they do, and the order stated instead of spelled - 2026-10-13

The owner's objection was to the file names: `zzzzzzzz_minespace_ae2_machines.zs` is a load order spelled
as a row of z's, and reading the folder told you nothing about what runs when. CraftTweaker has the
right tool for that - the `#priority` preprocessor, which sets a numeric order per file instead of
leaning on the alphabet - so the folder was renamed and every file now opens with its order:

```
#priority 900
// The HIGHER the number, the earlier CraftTweaker runs this file (it sorts the list descending).
// oredict.zs runs first because every other script reads the ore dictionary names it fixes;
// after that the order only has to keep the pack's own passes behind the mods they edit.
```

| order | files |
| --- | --- |
| 900 | `oredict.zs` (was `aa_minespace_oredict.zs`) - the ore dictionary surgery everything reads |
| 850 .. 845 | `gc_removals.zs`, `gc_crafting.zs`, `gc_machines.zs`, `gc_processing.zs`, `gs_removals.zs`, `own_machines.zs` |
| 800 .. 793 | `gaps.zs`, `ae2_base.zs`, `integration.zs`, `assembler_1.zs`, `assembler_2.zs`, `gc_tools.zs`, `gcp_tools.zs`, `power.zs` |
| 700 .. 696 | `eio_materials.zs`, `jei_dupes.zs`, `eio_upgrades.zs`, `forestry_items.zs`, `forestry_wood.zs` |
| 600 .. 596 | `ae2_machines.zs`, `ae2_parts.zs`, `ae2_storage.zs`, `hightech.zs`, `planetprogression.zs` |

Nothing about the content changed - the same text, the same order the z-prefixes used to produce, now
written down where a reader can see it.

### The trap in the middle, and the proof it is fixed

The first attempt assumed the number worked the other way round (lower first, as `Integer.compare` in the
comparator suggests). The load log proved otherwise - CraftTweaker sorts **descending**, so
`planetprogression.zs` ran first and `oredict.zs` last:

```
Loading Script: {[54:crafttweaker]: planetprogression.zs}     <- first with the wrong numbering
...
Loading Script: {[10:crafttweaker]: oredict.zs}               <- last
```

and the run's own counts caught it even though CraftTweaker reported no errors (`machine-only
enforcement: 38` instead of 18, because the scripts had read ore dictionary names before the ore
dictionary was fixed). Renumbering to descending put `oredict.zs` back at the front:

```
Loading Script: {[900:crafttweaker]: oredict.zs}
Loading Script: {[850:crafttweaker]: gc_removals.zs}
...
Loading Script: {[596:crafttweaker]: planetprogression.zs}
```

and the five pass counts returned to exactly the values they had before the rename - 1058 / 128 / 2 / 18
/ 25 / 217 - with zero `crafttweaker.log` errors, 47 mods, `Done (5.489s)`, two baseline `Invalid
recipe` lines. Every reference in this plan and in MOD-MANIFEST.md was updated with the names (111 of
them), and the Java javadoc comments mention the new file names too.

## 6az. Ender IO: the machines and recipes that bypass GregTech - 2026-10-13

The owner's instruction for this round: *"we are on Ender IO now; note that the machines or recipes
here that can be used to bypass GregTech must not be usable."*

### The audit

Ender IO keeps its recipes in its own XML (`assets/enderio/config/recipes/*.xml`) and registers them
*after* CraftTweaker has run, so a script cannot see them and `recipes.remove` finds nothing to
remove. The lever is the one 6e / 6l / 6ab / 6ac already used: `<recipe name="..." disabled="true"/>`
in `config/enderio/recipes/user/user_recipes.xml`, with the `name` copied verbatim out of the mod's
own file. Every machine-recipe family was exported from the jar and read against the ore dictionary
the pack ends up with:

| Ender IO file(s) | machine | what it produces |
| --- | --- | --- |
| `alloying.xml`, `alloying_modded.xml` | Alloy Smelter | alloys, dyes, fused quartz and glass, the machine chassis |
| `sagmill*.xml`, `integration_railcraft_recipes.xml` | SAG Mill | ore, metal, gem and plant grinding |
| `vat.xml`, `fuels.xml` | Vat | nutrient distillate, hootch, rocket fuel, cloud seed |
| `tank.xml` | Tank | XP bottles, sponge, concrete |
| `enchanter.xml`, `soulbinder.xml`, `spawner.xml` | Enchanter / Soul Binder | enchantments, spawner and crystal work |
| `machines.xml`, `items.xml`, `powertools*.xml`, `darksteel_upgrades*.xml`, `conduits*.xml`, `capacitor*.xml` | crafting table | the machines, tools and conduits themselves - already assembler work (6ad, 6ae, 6af) |

Only two of them were handing out a GregTech material, and both are now closed.

### 1. The Alloy Smelter was the pack's second alloy furnace

`alloying_modded.xml` ships sixteen recipes whose output is a GregTech metal, and they work because
they name the plain `ingotX` ore names, which hold GregTech's ingot:

| name in the file | input -> output |
| --- | --- |
| `Alloy: Steel` / `Alloy: Steel (Oredict)` | iron + coal (or coke) -> `ingotSteel` |
| `Alloy: Electrum Ingot (Thermal Expansion)` | gold + silver -> `ingotElectrum` |
| `Alloy: Invar Ingot (Thermal Expansion)` | nickel + 2 iron -> `ingotInvar` |
| `Alloy: Bronze (Thermal Expansion)` | 3 copper + tin -> `ingotBronze` |
| `Alloy: Constantan (Thermal Expansion)` | copper + nickel -> `ingotConstantan` |
| `Alloy: Signalum (Thermal Expansion)` | 3 copper + silver + 10 redstone -> `ingotSignalum` |
| `Alloy: Lumium (Thermal Expansion)`, `Alloy: Lumium from dust (Thermal Expansion)` | 3 tin + silver + glowstone -> `ingotLumium` |
| `Alloy: Enderium Base (Thermal Expansion)` | 3 lead + platinum + 4 ender pearls -> `ingotEnderiumBase` |
| `Alloy: Enderium (Thermal Expansion)` | 2 enderium base + sand -> `ingotEnderium` |
| `Alloy: Invar Blend`, `Alloy: Signalum Blend`, `Alloy: Lumium Blend`, `Alloy: Enderium Blend` | the metal's dust + sand -> the ingot |
| `Alloy: Manyullyn` | cobalt + ardite -> `ingotManyullyn` |

Every one of them is a route around GregTech's mixer / alloy smelter, and the four "blend" entries
are worse: they take a GregTech *dust* straight back to the ingot. All sixteen are switched off by
name. The file's other entries need NuclearCraft, which is not installed, so Ender IO already skips
them (`ingotFerroboron`, `ingotTough` and the rest are empty ore names here) and they are not listed.

### 2. The SAG Mill, fourth pass: the ingot -> dust step

6ab and 6ac had already switched off the 203 ore recipes and the 87 ingot / block / gem recipes whose
input a probe proved GregTech's own maps accept. What the mill could still do with a pack material
fell into three groups:

* **its own alloys.** 6ae made Ender IO's ten alloys GregTech materials, so `dustDarkSteel`,
  `dustEnergeticAlloy` and the rest resolve to GregTech's dust - which turned
  `Sagmill: <alloy> Ingot` / `Sagmill: <alloy> Block` (eight alloys, sixteen recipes, in
  `sagmill_metals.xml`) into a non-GregTech source of the pack's dusts;
* **the Thermal-Foundation metals** in `sagmill_modded.xml`: `Sagmill: Signalum Ingot` / `Block` and
  `Sagmill: Lumium Ingot` / `Block` (enderium and invar were already in the second pass);
* **two lapis recipes whose names carry no `Sagmill: ` prefix** - `Lapis Dust` (gemLapis ->
  dustLapis) and `Lapis Block Dust` (blockLapis -> dustLapis). That missing prefix is exactly why
  the earlier passes, which filtered on names, could not see them; `dustLapis` is GregTech's dust, and
  GregTech's macerator already performs the same step on the gem and on the block.

### 3. The one material that needed Java, not the mill

The ten alloy dusts are not all GregTech's yet. `dustSoularium` held **Ender IO's own powder first**
(`enderio:item_material:74`) and GregTech's dust second, and that membership is why Gregicality built
its outputs against the powder: its macerator recipe read `macerator IN ingotSoularium ... OUT
enderio:item_material:74` and the storage-block form read `... OUT 9x enderio:item_material:74`, with
two more in the packer. So there was nothing to *add* here. Instead:

* `scripts/oredict.zs` takes `enderio:item_material:74` out of `dustSoularium`, so the name is
  GregTech's dust alone - the same treatment the pack already gave the mod's iron / gold / coal /
  lapis / obsidian / cobalt powders; and
* `MinespaceMaterialRepoint` gains that one pair (`enderio:item_material:74` -> `dustSoularium`), so
  its existing "machine outputs hand out GregTech's item" pass re-points those four recipes at the
  dust. The pass's machine count moves 905 -> 909, and that +4 is the whole fix.

### A wrong turn worth recording: the macerator recipes that were not needed

The first attempt at the same problem was to write the missing `macerator` recipe for all ten alloys
in `eio_materials.zs`. The de-duplication counter (below) caught it: adding ten single-input recipes
pushed `macerator=2` to `macerator=11`, which means **nine of the ten already existed** - Gregicality
generates them itself, so nine of the ten were duplicates of GregTech's own recipe and were removed
again on the spot. A one-recipe-at-a-time diagnostic (construction alloy first, which also merged;
then soularium, which did not) identified the single exception as soularium, the same one the ore
dictionary entry explains. The script's recipes were therefore dropped in favour of the re-point
above, and the pack's counter is back at its documented value instead of drifting to 226.

### What was deliberately left alone, and why

* **The Vat, the Tank, the Enchanter, the Soul Binder, the Painter and the obelisks.** Their outputs
  are Ender IO's own fluids (nutrient distillate, hootch, fire water, cloud seed), vanilla items
  (concrete, sponge, XP bottles), enchantments and Ender IO's crystals. None of them is a pack
  material, so none is a way around GregTech - and removing an enchanter's enchantments or a vat's
  brewing would delete the content rather than the shortcut.
* **`Sagmill: GlowStone` and `Quartz Dust`.** GregTech's macerator does not take a glowstone block or
  a nether-quartz *gem* at all (it takes `plateGlowstone` and the ore blocks), so switching these off
  would strand the powder instead of moving the step. This is the same rule 6ac applied to bone,
  wool, logs and sand.
* **Ender IO's own gears, crystals, balls, chassis and decorative blocks.** Their outputs are Ender
  IO items (`gearIronInfinity`, `gearDark` and friends are the mod's own item ids, not `gearIron`),
  so they are the mod's content, not a copy of a pack material.
* **The machines themselves stay craftable.** Ender IO without its alloy smelter and SAG mill is not
  Ender IO; what was removed is their GT-material *processing*, exactly as 6e removed the Galacticraft
  machines' outputs and kept the machines.

### Verification

The EIO side was read out of Ender IO's own recipe log (its debug output temporarily promoted, then
restored): the run prints **364 `Skipping XML recipe ... (disabled=true)` lines for the pack's file -
one per entry, none missing - plus 316 of Ender IO's own** for recipes whose target mod is not
installed (the NuclearCraft alloys, the Tinkers casting and smelting forms, the Thaumcraft upgrades).
All sixteen alloy-smelter names, all twenty SAG-mill names and both lapis names appear in that list,
and `user_recipes.xml` is at 364 entries (326 + 38: 16 + 20 + 2), with no duplicate names - the first
run failed loudly on a duplicate `Sagmill: Enderium Ingot`, because the second pass had already
covered enderium and invar, and EIO refuses to start with a duplicate in a user file.

The final run: **47 mods**, `Done (6.227s)`, zero `crafttweaker.log` errors, zero
`Invalid amount of recipe inputs`, zero `duplicate or conflict`, the two baseline `Invalid recipe`
lines and the two baseline `Input cannot contain null` lines, and the pass counters at exactly their
documented values - 69 compressed-plate producers, 1058 of 1074 crafting-table compressions, 128
unreachable machine recipes, 2 sub-MV AE2 packer recipes, 18 machine-only leftovers, 25 double routes
and **217** order-duplicates, with the loadComplete re-run all zeroes. The machine re-point count is
the only number that moves (905 -> 909), and it is the soularium fix above.

## 6ba. Ender IO's remaining ingots and fluids become GregTech's - 2026-10-13

The owner's next instruction: *"I think those non-GregTech fluids can be registered as GregTech
fluids, and the non-GregTech metal ingots have to be registered on GregTech's side too - and every
Ender IO ingot and Ender IO fluid, when it is a product, must not produce a non-GregTech one."*

### The ingots: eight more metal items Ender IO still owned

6ae had registered Ender IO's ten alloys; two families were left. Both are now GregTech
`IngotMaterial`s with the same shape as the ten (`SMELT_INTO_FLUID`, empty component list, so an
ingot, nugget, block, dust and molten fluid and nothing else), and their ingot and nugget come out of
the shared ore names in `scripts/oredict.zs`:

| Ender IO item | name | why it was still the mod's |
| --- | --- | --- |
| `item_alloy_endergy_ingot:0..6` | `crude_steel`, `crystalline_alloy`, `melodic_alloy`, `stellar_alloy`, `crystalline_pink_slime`, `energetic_silver`, `vivid_alloy` | the "Endergy" alloys. The mod ships ingot, nugget, block and grinding ball, but **no production recipe** - the only recipes touching them were the four auto block / nugget conversions, two of which the pack had deliberately kept on the crafting table precisely because no GregTech material existed for them |
| `item_material:39` | `enderium_base` | the Thermal-Foundation intermediate on Enderium's way. 6az switched Ender IO's alloy-smelter entry for it off with the other fifteen, which left the item in `ingotEnderiumBase` and nothing producing it |

The mechanics are the ones 6ae established, so nothing new had to be invented:

* `MinespaceMaterials.ENDER_IO_ENDERGY_ALLOYS` and `.ENDER_IO_OTHER_INGOTS` register the eight;
* `oredict.zs` takes the mod's ingot and nugget out of their shared names (14 removals for the
  endergy seven, one for enderium base);
* `MinespaceMaterialRepoint` gains the same fifteen pairs, which moves every Gregicality and
  Ender IO *machine* output that used a mod ingot or nugget onto GregTech's - 63 machine outputs and
  14 smelting recipes on this run;
* `scripts/eio_materials.zs` rebuilds the two crafting-table conversions that *produce* one of them
  (block -> 9 ingots and 9 nuggets -> ingot), because `IRecipe#getRecipeOutput()` cannot be
  re-pointed from Java; and
* enderium base, being an alloy rather than an endergy fragment, gets Ender IO's own recipe back on
  GregTech's side: `scripts/integration.zs` ports the `alloying_modded.xml` entry (3 lead + 1
  platinum + 4 ender pearls -> 4 ingots, the same 1:4 ratio) to the **mixer**, which is the machine
  with enough slots for three inputs. The endergy seven have no recipe anywhere in the pack - the mod
  never shipped one - so none was invented for them.

The measured fallout is exactly that story and nothing else: the fourteen "no machine makes this"
compression recipes are gone (1072 -> 1074 of 1076 deleted, the two that remain being Galaxy Space's
sulphur dust and Forestry's ash), and the unreachable-machine-recipe pass rises 128 -> 163 because
Gregicality's own recipes that *fed on* the mod's endergy ingots and nuggets can no longer be run -
which is what that pass exists to clean up (TJ-MIGRATION-PLAN.md 6an).

### The fluids: GregTech gets the mod's fluid, not a second one

Ender IO owns ten fluids - the Vat's nutrient distillation, hootch, fire water, cloud seed (and the
concentrated form), liquid sunshine, the Ender distillation and vapor of levity chain, rocket fuel,
and its Liquid XP. Two things had to be true at once: GregTech must own them, and Ender IO's Vat,
Tank, Enchanter, conduits and buckets must keep working on exactly the fluid they always used.

The obvious approach - let GregTech create fluids under those names - is the wrong way round, and the
reason is a load-order detail: **GregTech builds its material fluids in its preInit, and Ender IO
registers its own from Forge's `RegistryEvent.Register<Block>`, which fires after every mod's
preInit.** GregTech's fluid would therefore win the name, and Ender IO's `FluidRegistry.registerFluid`
would return false (Forge returns false rather than throwing - the bytecode of
`FluidRegistry.registerFluid` was read to be sure), leaving the mod's machines pointing at a fluid
with none of its properties.

So the direction is inverted:

* `MinespaceMaterials.ENDER_IO_FLUIDS` registers the ten as `FluidMaterial`s through a private
  `AdoptedFluidMaterial`, whose only job is to override `shouldGenerateFluid()` to `false`. GregTech
  therefore knows the material, the name and the colour, and deliberately creates no fluid of its own;
* Ender IO then registers its fluids exactly as it always did, and nothing collides;
* `MinespaceEioFluids.adopt` runs from the addon's `init` - the first point at which those fluids are
  guaranteed to exist - and calls `material.setMaterialFluid(fluid)`, i.e. **GregTech's material now
  *is* Ender IO's fluid**. It also puts the fluid into GregTech's own
  `MetaFluids.fluidToMaterialMappings` by reflection, guarded by a try/catch, so
  `MetaFluids.getMaterialFromFluid` answers for it the way it does for a fluid GregTech built itself
  (that map is private, and a material that adopts somebody else's fluid is not in it otherwise).

The run prints exactly what that predicts, and one case needed no work at all:

```
Ender IO fluids as GregTech materials: 9 registered, 1 already GT's
  reusing GT's own material 'rocket_fuel' for Ender IO's fluid
adopted Ender IO fluid 'nutrient_distillation' as GregTech's material 'nutrient_distillation'
adopted Ender IO fluid 'ender_distillation' as GregTech's material 'ender_distillation'
adopted Ender IO fluid 'vapor_of_levity' as GregTech's material 'vapor_of_levity'
Ender IO fluids as GregTech fluids (init pass): 9 adopted, 0 not registered yet
Ender IO fluids as GregTech fluids (postInit pass): 0 adopted, 0 not registered yet
```

`rocket_fuel` is the one GT already had (Gregicality registers a material by that name, so the pack's
Rocket Fuel Loader was already running on it) - GregTech's fluid had been occupying the name all
along, which is also why Ender IO's own registration of it had been quietly failing. The other nine
are adopted; the postInit pass finding nothing left to do is the idempotence check.

### One build change, and why

Reading a GregTech `FluidMaterial` at all makes javac load its class, and that class carries
CraftTweaker types in its signatures (`crafttweaker.api.liquid.ILiquidDefinition`), as does
`MetaFluids`, which is `@ZenRegister`ed. Without CraftTweaker on the compile classpath the build dies
with `cannot access crafttweaker.annotations.ZenRegister` and `unknown enum constant OperatorType.MUL`.
`build.gradle` therefore adds the instance's `CraftTweaker2-1.12-4.1.20.698.jar` as `compileOnly`, the
same way it already does for MixinBooter - compiled against the exact jar the pack ships, never
bundled.

### What was deliberately left, and what is open

* Two more EIO items carry `ingot` in their ore dictionary name but are not metals, so the "metal
  ingots" instruction does not cover them: `ingotBrickNetherGlazed` (Ender IO's glazed nether brick,
  a ceramic) and the mod's Ender Pearl nugget. Both stay Ender IO's.
* **Open, and worth the owner's call:** the seventeen alloys now each have a crafting-table route
  "nine nuggets -> one ingot", inherited from Ender IO's own `auto_<material>_9_nuggets_to_1_ingot`
  entries. Its input is GregTech's nugget after the re-point, so nothing mod-owned is produced, but
  "nine identical things into one thing" is the compressor's job - the same complaint the owner made
  about ingots into blocks in 6an. Deleting it is a one-line change in `eio_materials.zs` (stop
  re-adding the nugget direction) and would leave GregTech's compressor as the only route.

### Verification

The final run: **47 mods**, `Done (5.120s)`, zero `crafttweaker.log` errors, zero
`Invalid amount of recipe inputs`, zero `duplicate or conflict`, the two baseline `Invalid recipe`
lines and the two baseline `Input cannot contain null` lines, and the loadComplete re-run all zeroes.
The counters that this change is expected to move, and did: crafting-table compression **1074 of
1076** deleted with 2 kept (was 1058 / 1074 with 16 - the fourteen endergy pairs now have a GregTech
machine route), unreachable machine recipes **163** (was 128 - Gregicality's recipes that fed on the
mod's endergy items are now unrunable), machine re-points **973** (was 909), smelting re-points
**2208** (was 2193) and crafting-input re-points **71** (was 57). Everything else is at its documented
value: 69 compressed-plate producers, 2 sub-MV AE2 recipes, 18 machine-only leftovers, 25 double
routes and 217 order-duplicates. Gregicality's own `block_compress_enderium_base` /
`block_decompress_enderium_base` appear in the log, which is the proof that it treats the new material
like any other.

## 6bb. The names, the tags, and the recipes that had to follow the registration - 2026-10-13

The owner read the previous section and came back with two things: *"(1) the name or the tag, and (2)
mind that the related recipes have to be adapted."* Both were real, and a probe run over the finished
registries (temporary `MinespaceEioProbe`, since deleted) settled which was which.

### What the probe found: the tags were already GregTech's, the names were not

For every shared ore dictionary name this pack writes, the probe dumped the items the name actually
holds, with the string a player sees next to each. The answer to "is it the name or the tag":

```
ingotDarkSteel  -> 1 item(s)   gregtech:meta_item_1:10179   "item.meta_item.name"
nuggetDarkSteel -> 1 item(s)   gregtech:meta_item_1:9179    "item.meta_item.name"
dustDarkSteel   -> 1 item(s)   gregtech:meta_item_1:2179    "item.meta_item.name"
ingotCrudeSteel -> 1 item(s)   gregtech:meta_item_1:10263   "item.meta_item.name"
ingotEnderiumBase -> 1 item(s) gregtech:meta_item_1:10338   "item.meta_item.name"
blockCrudeSteel -> 2 item(s)   enderio:block_alloy_endergy:0 "Crude Steel Block"
                               gregtech:meta_block_compressed_16:7 "tile.compressed.name"
ballCrudeSteel  -> 1 item(s)   enderio:item_alloy_endergy_ball:0 "Crude Steel Grinding Ball"
```

* **The tags are GregTech's.** Every `ingot*`, `nugget*` and `dust*` name this pack writes now holds
  GregTech's item and nothing else - the mod's copy is out. The two exceptions are deliberate and
  unchanged: the **block** names still list Ender IO's block *first* (with GregTech's compressed block
  beside it), and `ball*` is Ender IO's grinding ball, which is the mod's own consumable. Both are the
  owner's earlier instruction, quoted in 6ae: *"the ingot, its molten fluid, the dust and the nugget;
  the other forms are not wanted"*. Every machine recipe that reads a `block*` name accepts either item
  (the probe shows the recipe's ingredient as `{enderio:block_alloy_endergy:0,
  gregtech:meta_block_compressed_16:7}`), so nothing there is broken - it is the one place a mod item is
  still an option, and it is one line in `oredict.zs` to change if the owner wants blocks unified too.
* **The names were the problem.** GregTech draws a material name as
  `Material#getLocalizedName()` -> `I18n.format("material." + <registry name>)`, and GregTech ships one
  such key for each of its own **475** materials (`material.iron=Iron`, `material.steel=Steel`, ...).
  Every material this pack registers had **no key at all**, so the client had nothing to resolve and
  fell back to the raw string: JEI said `material.dark_steel Ingot`, `material.crude_steel Ingot`,
  `material.xpjuice`. The probe shows the same raw key on the *dedicated server* even for GregTech's own
  aluminium (`Adding item.meta_item.name to ore dictionary entry plateAluminum`), which is why this had
  gone unnoticed: it is a client-side name, and the client is where the owner was looking.

`assets/minespace/lang/en_us.lang` and `zh_cn.lang` (the client runs in Chinese here) now carry the 32
missing keys - the 15 EIO alloys and enderium base, the ten fluids, and the pack's own `desh`,
`meteoric_iron`, `desh_steel`, `solar` and `onyx`. The names are Ender IO's own, minus the
`Ingot`/`Nugget` part that GregTech adds from the ore prefix.

### The recipes: re-point the inputs instead of deleting the recipes

The second point was the more consequential. Gregicality builds most of its material recipes against
whichever item was <em>first</em> in a shared ore dictionary name at generation time, and for the mods
this pack unifies that was the mod's copy - `compressor 9x enderio:item_alloy_endergy_nugget:0`, and
about 160 more. Those recipes cannot be run once the pack stops producing the mod item, so 6an's second
pass used to **delete** them (163 of them went on the 6ba run). Deleting is the wrong answer when the
material still exists: what the recipe wants is the pack's nugget, which is exactly GregTech's.

`MinespaceMaterialRepoint.repointMachineInputs` is the missing half of the re-point. It walks every
recipe map and replaces an ingredient with GregTech's item when - and only when - **every** item that
ingredient accepts is one of the unified mod items, the same conservative rule the crafting-input pass
uses, so an ore dictionary name that already lists GregTech's item is left alone. Counts, duration and
EU/t are untouched. It runs after `MinespaceGrinderToMacerator`, because that pass *adds* macerator
recipes and the first attempt therefore still lost seven of them (the Forestry / Galacticraft / Galaxy
Space ingot grinders) to the unreachable pass.

The effect is exactly what the owner asked for. `9 nuggets -> 1 ingot` came back as a GregTech machine
route for the whole alloy family instead of existing only on the crafting table:

```
compressor: 9xgregtech:meta_item_1:9179 -> 1xgregtech:meta_item_1:10179   (dark steel)
compressor: 9xgregtech:meta_item_1:9263 -> 1xgregtech:meta_item_1:10263   (crude steel)
compressor: 9xgregtech:meta_item_1:9335 -> 1xgregtech:meta_item_1:10335   (crystalline pink slime)
compressor: 9xgregtech:meta_item_1:9337 -> 1xgregtech:meta_item_1:10337   (vivid alloy)
compressor: 9xgregtech:meta_item_1:9338 -> 1xgregtech:meta_item_1:10338   (enderium base)
```

and **the unreachable-recipe count fell from 163 to 0** - nothing is thrown away any more, because
everything Gregicality built on a mod item has been adapted to the pack's item. The one place that was
not a re-point is the AE2 grinder conversion, which is re-pointed by the same call placed after it.

### The JEI half of the same complaint

The eight items that lost their only producer in 6ba - Ender IO's seven endergy ingots and its Enderium
Base ingot - were still in JEI next to the new GregTech ones, because `jei_dupes.zs` is a hand-written
list and nothing had added them to it. They meet both halves of that file's rule (out of a shared name,
and produced by nothing), so they are hidden now (39 -> 47 items). Ender IO's endergy *nuggets*, *blocks*
and *grinding balls* are deliberately left visible: the nuggets and blocks still have producers, and the
balls are made from the mod's own nuggets.

### Verification

The final run (probe removed, jar rebuilt): **47 mods**, `Done (5.840s)`, zero `crafttweaker.log`
errors, zero `Invalid amount of recipe inputs`, zero `duplicate or conflict`, the two baseline `Invalid
recipe` lines and the two baseline `Input cannot contain null` lines, and the loadComplete re-run all
zeroes. The re-point counters are now four: 2207 smelting, 973 machine outputs, **164 machine inputs**
and 71 crafting inputs. The passes that this change moves, and how: unreachable machine recipes **0**
(was 163), order-duplicates **248** (was 217 - the adapted recipes that came out identical to GregTech's
own are merged, `compressor=17, macerator=12, packer=9, unpacker=9`), crafting-table double routes
**26** (was 25 - one more table recipe now has a machine twin). Unchanged: 69 compressed-plate
producers, 1074 of 1076 crafting-table compressions with 2 kept, 2 sub-MV AE2 recipes, 18 machine-only
leftovers.

## 6bc. The block names, and the conversions the crafting table should not have - 2026-10-13

Two things were left on the table at the end of 6bb, and the owner asked for both: *"handle these
two."*

### 1. The block tags follow the ingots

6bb's probe showed the one place a mod item was still an option in a shared name: every `blockX` name
held Ender IO's block **first**, with GregTech's compressed block second. The consequence was not
cosmetic - Gregicality builds a recipe against the first item of a name, so its own machines were
handing the mod's block out (`fluid_solidifier: 0x32308 -> 1xenderio:block_alloy:6`, the compressor's
nine-ingots-into-a-block, and so on), and a recipe that resolved `blockDarkSteel` got Ender IO's block
rather than GregTech's.

`scripts/oredict.zs` now takes Ender IO's seventeen block items out of their names - the ten alloys
and the seven endergy alloys - and `MinespaceMaterialRepoint` gains the same seventeen pairs. The CT
log confirms each removal (`Removing Dark Steel Block from ore dictionary entry blockDarkSteel`, ...)
and the re-point pass reports **no unresolved name**, so every `blockX` now answers with GregTech's
compressed block. The measured fallout:

* machine **outputs** re-pointed: 973 -> **1058** (+85 - every Gregicality recipe that used to hand out
  a mod block now hands out GregTech's);
* machine **inputs** re-pointed: 164 -> **182** (+18 - the recipes that fed on a mod block, among them
  one of Ender IO's dark steel upgrade variants, now eat GregTech's);
* crafting **inputs**: 71 -> 54, seventeen fewer because the rebuilt conversions that used to consume a
  mod block no longer exist (see below).

Ender IO's block *items* stay in the game - a recipe naming one by id still works, the input re-point
turns it into GregTech's block - and since nothing produces them any more they join `jei_dupes.zs`
(47 -> 64 hidden items). The one form that deliberately stays Ender IO's is the **grinding ball**:
that is the mod's own consumable, cast from the mod's own nuggets.

### 2. The crafting table stops compressing

6bb's restored machine routes made the 6ba rebuilds unnecessary, and they were the wrong shape anyway:
this file used to re-create Ender IO's `block -> 9 ingots` and `9 nuggets -> 1 ingot` crafting recipes
against GregTech's item, which left the crafting table doing the compressor's work - the owner's
original complaint about "ingots straight into a block", one step over.

`scripts/eio_materials.zs` now simply removes the three conversions Ender IO generated for each of the
seventeen alloys (`9 ingots -> block`, `block -> 9 ingots`, `9 nuggets -> 1 ingot`) and rebuilds
none of them, because GregTech has all three as machine work: the compressor for nuggets into an ingot
and ingots into a block, the alloy smelter's mould form and the macerator for a block back into
ingots. The file is now 34 recipes shorter, which is why the compression pass's pool reads 1042
instead of 1076 (1040 of 1042 deleted, the same two kept).

That paragraph used to end by keeping one direction - `1 ingot -> 9 nuggets` - on the grounds that Ender
IO's grinding balls are cast from its own nuggets. **6bh retracts that**: the ball recipes the mod
actually ships are the crafting-table ones, five **ingots** into twenty-four balls, and the casting
forms want Tinkers Construct, which this pack does not have. The nugget direction is gone as well and
the mod's nugget items are hidden from JEI.

### Verification

Final run: **47 mods**, `Done (5.220s)`, zero `crafttweaker.log` errors, zero `Invalid amount of recipe
inputs`, zero `duplicate or conflict`, the two baseline `Invalid recipe` lines and the two baseline
`Input cannot contain null` lines, no crash, and the loadComplete re-run all zeroes. Counters other
than the ones quoted above are unchanged: 69 compressed-plate producers, **0** unreachable machine
recipes, 2 sub-MV AE2 recipes, 18 machine-only leftovers, 26 double routes, 248 order-duplicates. The
re-point pass logged no `is empty, cannot re-point` line, which is the check that every one of the
seventeen block names still resolves after the removal.

## 6bd. The seven endergy alloys' recipes were never in Ender IO - 2026-10-13

The owner, looking at the seven freshly registered alloys in JEI: *"why are these alloys' crafting
methods gone? They go through the GT alloy smelter."*

They were gone because they were never there. Ender IO 5.3.72 ships the seven alloys - ingot, nugget,
block, grinding ball and the four auto conversions - and **no production recipe at all**; that is why
this pack's earlier passes found nothing to disable and 6ba found nothing to port. The production
recipes live in the separate **Ender IO - Endergy** addon (same version, 5.3.72), which is not
installed. Its recipe file was fetched from the addon's own jar on Modrinth and read out
(`assets/enderio/config/recipes/endergy.xml` and `endergy_balls.xml`), so nothing below is invented -
the inputs, the counts and the shapes are the addon's.

### The six alloys that can be made

| alloy | addon recipe | ported to |
| --- | --- | --- |
| Crude Steel | gravel + clay + cobblestone -> 1 ingot | mixer (three inputs) |
| Crystalline Alloy | pulsating powder + gold -> 1 ingot | **alloy smelter** |
| Melodic Alloy | popped chorus fruit + end steel -> 1 ingot | **alloy smelter** |
| Stellar Alloy | nether star + melodic alloy + 4 clay -> 2 ingots | mixer (three inputs) |
| Energetic Silver | redstone + silver + glowstone -> 1 ingot | mixer (three inputs) |
| Vivid Alloy | ender pearl + energetic silver -> 1 ingot | **alloy smelter** |

The split is the machine's own limit, not a design choice: GregTech's alloy smelter has two item
slots, so the three-input recipes go to the mixer - exactly where the ten alloys' three-input recipes
(Electrical Steel, Energetic Alloy, Dark Steel, End Steel, Construction Alloy, Enderium Base) already
are. Energetic Silver and Vivid Alloy are the addon's "Energetic Alloy / Vibrant Alloy pattern on
silver" pair, which is why their recipes mirror those two. Outputs are written as Ender IO's items
like every other alloy recipe in `integration.zs`, and `MinespaceMaterialRepoint` turns them into
GregTech's ingot - the machine-output re-point count moves 1058 -> 1064, exactly these six.

Two of the addon's eight entries are deliberately not ported:

* **Crystalline Pink Slime** needs `industrialforegoing:pink_slime_ingot`, and Industrial Foregoing is
  not in this pack. The addon itself marks that entry `required="false"` for future packs that lack
  it, so skipping it is the addon's own behaviour - but it does leave this one alloy without a recipe.
* **Combustive Metal** produces `ingotCombustiveMetal`, an item the *addon* adds. The pack installs
  EIO 5.3.72 only, so the item does not exist and there is nothing to make.

### The seven grinding balls, which the addon also owns

The same investigation found the second half of the gap: the seven endergy *grinding balls* were
unobtainable too, because their recipes are in `endergy_balls.xml`. The addon ships them in the same
shape the ten alloys use - five ingots in a cross on the crafting table into **24 balls** - so they are
ported that way, and the CT log confirms all seven (`Adding shaped recipe for Crude Steel Grinding
Ball`, ... `Vivid Alloy Grinding Ball`). The addon's other two forms are Tinkers casting recipes that
want `tconstruct:cast_custom:2`; Tinkers Construct is not in this pack and Ender IO skips any recipe
whose dependency is missing, which is why the cross is the only form that exists here for the ten
alloys too. This matters because those balls are what Ender IO's SAG Mill grinds with.

### Same cause, checked and retracted: EIO's "alternate capacitors"

`endergy.xml` also holds the recipes of three capacitor items - `item_capacitor_silver`,
`item_capacitor_energetic_silver` and `item_capacitor_vivid` - and the first reading of this section
said they existed in the base mod, were visible in JEI and had no recipe. That was wrong, and the check
that settled it is simple: those three names appear **nowhere** in the base mod's jar except as the
second entries of the `CAPACITOR1` / `CAPACITOR2` / `CAPACITOR3` aliases - no model, no texture, no lang
entry - and they appear in no crafting or machine recipe in the whole pack. They are the *addon's* items,
the addon is not installed, and Ender IO's alias table simply tolerates the missing form. So there is
nothing to port and nothing to hide here; the item that matters, `item_basic_capacitor`, already has its
assembler recipes.

### Verification

Final run: **47 mods**, `Done (4.557s)`, zero `crafttweaker.log` errors (so all thirteen new recipes
parsed and registered), zero `Invalid amount of recipe inputs` (so the two-input recipes fit the alloy
smelter and the three-input ones the mixer), zero `duplicate or conflict`, the two baseline `Invalid
recipe` lines and the two baseline `Input cannot contain null` lines. The machine re-point count is
the one number that moves: 1058 -> **1064**, six more. Everything else is where 6bc left it - 69
compressed-plate producers, 1040 of 1042 crafting-table compressions with 2 kept, 0 unreachable
machine recipes, 2 sub-MV AE2 recipes, 18 machine-only leftovers, 26 double routes, 248
order-duplicates - and the loadComplete re-run is all zeroes.

### Addendum: every alloy audited, and the one bug the audit found

The owner's follow-up question - *"does the energetic ingot have a recipe too?"* - is exactly the kind
of thing that deserves a list rather than an answer from memory, so a second temporary probe
(`MinespaceAlloyProbe`, since deleted) walked **every** recipe map for a producer of each of the
eighteen metals' ingot *and* of its molten fluid. The result:

| alloy | production recipe (inputs that are not the same metal) |
| --- | --- |
| dark_steel | mixer: iron + coal dust + obsidian, and alloy smelter: steel plate + obsidian |
| electrical_steel | mixer: iron + coal dust + silicon, and alloy smelter: steel plate + silicon |
| **energetic_alloy** | **mixer: redstone + gold + glowstone** |
| vibrant_alloy | alloy smelter: energetic alloy + ender pearl |
| redstone_alloy | alloy smelter: redstone + silicon |
| conductive_iron | alloy smelter: redstone + iron |
| pulsating_iron | alloy smelter: iron + ender pearl |
| soularium | alloy smelter: soul sand + gold |
| end_steel | mixer: end stone + dark steel + obsidian |
| construction_alloy | mixer: copper + iron + copper -> 3 |
| crude_steel | mixer: gravel + clay + cobblestone |
| crystalline_alloy | alloy smelter: pulsating powder + gold |
| melodic_alloy | alloy smelter: popped chorus fruit + end steel |
| stellar_alloy | mixer: nether star + melodic alloy + clay x4 -> 2 |
| crystalline_pink_slime | **none** - the addon's recipe needs Industrial Foregoing's pink slime ingot |
| **energetic_silver** | **mixer: redstone + silver + glowstone** |
| vivid_alloy | alloy smelter: ender pearl + energetic silver |
| enderium_base | mixer: 3 lead + platinum + 4 ender pearls -> 4 |

So both energetic ingots - Energetic Alloy (`energetic_alloy`) and Energetic Silver
(`energetic_silver`) - have a recipe, and the only alloy in the family without one is Crystalline Pink
Slime, for the missing-mod reason above. On top of the production recipes every one of them also has
GregTech's whole conversion family (compressor nine nuggets into an ingot, alloy smelter block or nine
nuggets into an ingot with a mould, packer / unpacker, fluid extractor into molten and fluid solidifier
back out), which is what 6bb's input re-point restored.

**The bug it found.** The audit caught a defect in two of the recipes 6bd had just added: the clay
input in Crude Steel and in Stellar Alloy was written as `<ore:itemClay>`, and that ore name is
**empty at the moment CraftTweaker runs** - it is registered later in the load - so GregTech accepted
both recipes with a dead slot instead of the clay. Both now take `<minecraft:clay_ball>`, which is what
the name holds (EIO's own `itemClay` alias resolves to it too). Nothing else in the audit was wrong.

One more thing learned while writing the probe, worth recording because it will catch the next person:
`OreDictUnifier.get(OrePrefix.ingot, material)` does **not** give the pack's item for these materials.
GregTech builds its material-to-item map when it creates the material items, which is *before* the
pack's ore dictionary surgery, so for every EIO metal it still points at the mod's item. The audit had
to read the ore dictionary name instead (`OreDictionary.getOres("ingotDarkSteel").get(0)`), which is
where the pack's fix actually lives.

Verified after the fix: **47 mods**, `Done (4.280s)`, zero `crafttweaker.log` errors, the seven
grinding-ball recipes still logged, the machine re-point count still 1064, and the two baseline `Invalid
recipe` / `Input cannot contain null` pairs unchanged.

## 6bf. Ender IO's Alloy Smelter stops being a three-slot furnace - 2026-10-13

The owner: *"the alloy smelter smelting GregTech ores is too cheaty."* It was, and it was not the alloy
recipes - it was the machine's other half.

### What the mod actually does

Ender IO's Alloy Smelter has an **operating profile**, and the interesting part is what "furnace mode"
means in the implementation:

* `crazypants.enderio.machines.machine.alloy.OperatingMode` is `ALL` / `ALLOY` / `FURNACE`, and
  `doFurnaceRecipes()` is what decides whether the machine will run a *vanilla furnace recipe*;
* `crazypants.enderio.base.recipe.alloysmelter.VanillaSmeltingRecipe` is the wrapper that puts the
  whole vanilla `FurnaceRecipes` map in front of the machine - and this pack's smelting map is the
  GregTech one (6e / 6i re-pointed every smelting output at GregTech's item, and ores smelt into
  GregTech ingots);
* `crazypants.enderio.machines.config.config.AlloySmelterConfig` hands each machine a profile from
  `SIMPLE_ALLOY`, `SIMPLE_FURNACE`, `ALLOY_ONLY`, `FURNACE_ONLY` and `AUTO`. The **defaults are
  `AUTO`** for the Alloy Smelter and the Enhanced Alloy Smelter, i.e. the player can flip them to
  FURNACE in the GUI.

So any GT ore could be smelted in Ender IO's alloy smelter on RF power - and `enderio.cfg`'s
`alloy.createSyntheticRecipes` (default true) generates 2- and 3-input batch variants of
single-input recipes, so it was **three ores per operation**, not one. That is another mod's machine
performing a GregTech processing step, the same rule 6ab / 6ac enforced for the SAG Mill and 6az for
the alloy smelter's *alloying* side.

### The fix

`config/enderio/enderiomachines.cfg`, three values:

```
S:profileNormal=ALLOY_ONLY           (was AUTO)
S:profileEnhancedAlloy=ALLOY_ONLY    (was AUTO)
B:enableAlloySmelterFurnaceJEI=false (was true)
```

`ALLOY_ONLY` is a profile the player cannot switch out of: the machine runs alloy recipes and nothing
else. The JEI switch stops the machine from advertising a furnace category it can no longer use. (The
one-liner proof that the values are real: Forge rewrote the file on the next launch and kept all
three, which it only does for values it accepted.)

### Evidence

A one-off probe (`MinespaceSmelterProbe`, since deleted) read the profiles back out of the finished
configuration through Ender IO's own enums - Ender IO is not a compile dependency of this addon, so the
probe went by class name and `setAccessible`:

```
SMELTER PROBE profileSimpleAlloy     = SIMPLE_ALLOY -> operating mode ALLOY   : alloyRecipes=true  furnaceRecipes=false
SMELTER PROBE profileSimpleFurnace   = SIMPLE_FURNACE -> operating mode FURNACE : alloyRecipes=false furnaceRecipes=true
SMELTER PROBE profileNormal          = ALLOY_ONLY  -> operating mode ALLOY   : alloyRecipes=true  furnaceRecipes=false
SMELTER PROBE profileEnhancedAlloy   = ALLOY_ONLY  -> operating mode ALLOY   : alloyRecipes=true  furnaceRecipes=false
SMELTER PROBE alloy recipe count: 77
```

`furnaceRecipes=false` on all three alloy smelters is the fix; the 77 alloy recipes still registered is
the check that nothing else moved. Final run after the probe was removed: **47 mods**,
`Done (4.628s)`, zero `crafttweaker.log` errors, the baselines unchanged, the seven grinding-ball
recipes still logged and the machine re-point count still 1064.

### Left alone, and why

Ender IO's **Simple Furnace** (`profileSimpleFurnace`, the fourth line above) *does* still run furnace
recipes - it is the mod's dedicated furnace machine, one item at a time, which is exactly a vanilla
furnace on RF. The pack has always allowed vanilla smelting (that is how an ore becomes an ingot
without any machine at all), so this is not a new route around GregTech the way the three-slot alloy
smelter was. Locking it out is possible, but only by taking the machine's crafting recipe away - there
is no "off" value in Ender IO's profile enum - so it is the owner's call rather than a one-line config
change.

## 6bg. A mechanical sweep of Ender IO's recipes - 2026-10-13

The owner: *"check again which Ender IO recipes bypass the GregTech line."* Six earlier passes had done
this by eye and by pattern, which is how two Dark Steel variants and nine SAG Mill outputs had slipped
through. So the sweep was made into a tool, kept in the repository:

**`tools/audit-eio-bypass.ps1`.** It reads every recipe in Ender IO's XML - all thirteen machine types
actually in use here (alloying 77, casting 38, enchanting 50, fermenting 9, sagmilling 536, smelting 96,
soulbinding 13, spawning 16, tanking 27) - resolves each output through the mod's own alias table, and
then classifies it against two things the last passes did not have:

* a **fresh ore dictionary dump**, taken from the running pack (`OREDICT <name> = <items>`, the probe
  that took it was deleted afterwards) instead of the 2026-10-12 snapshot; and
* the set of recipes that **actually run** - the pack's own disables from
  `config/enderio/recipes/user/user_recipes.xml` *and* every recipe Ender IO skips because its inputs,
  outputs or dependency mods are missing, which only appears with Ender IO's debug log promoted
  (`Skipping XML recipe '<name>' (...)`).

Each finding is `GT ITEM` (the output is a GregTech item, or a name whose *first* item is),
`SHARED NAME` (a mod item first, a GregTech item beside it) or `GT SHARED` (a vanilla item in a name
that also holds a GregTech one).

### What it found, and what was fixed

**Eleven recipes were still handing out GregTech material and are now switched off.** Two of them were
the last way Ender IO's alloy smelter could make a pack metal - `optional_tweaks.xml` carries two extra
Dark Steel entries (steel plus obsidian **dust**, and the dust-only variant) that 6az's list, taken from
`alloying_modded.xml`, never saw. The other nine were the SAG Mill's remaining GregTech dusts:

| recipe | output | GregTech producers of that output, from the full map dump |
| --- | --- | --- |
| `Quartz Dust` | nether quartz dust | 17 |
| `Sagmill: Aluminium Block` | aluminium dust | 61 |
| `Sagmill: BlazeRod` | sulfur dust (plus blaze powder) | 21 |
| `Sagmill: Charged Certus Quartz Crystal` | certus quartz dust | 16 |
| `Sagmill: ClayBlock` | silicon (byproduct of the clay balls) | 14 |
| `Sagmill: Flower Pot` | coal dust | 16 |
| `Sagmill: Netherrack` | sulfur dust | 21 |
| `Sagmill: Obsidian` | obsidian dust | 4 |
| `Sagmill: Wheat` | wheat dust | 4 |

The second and third passes had kept these because the *input* looked like something GregTech's maps did
not accept. The full map dump says otherwise for the three that mattered: GregTech's macerator *does*
take `minecraft:quartz:0`, `minecraft:wheat:0` and `obsidian` (as `{blockObsidian, obsidian}`), and
every one of the eight materials above has plenty of GregTech producers of its own - so switching the
mill's copies off moves the step to GregTech instead of stranding it. One correction to 6ac's notes
follows from the same dump: `dustGlowstone` holds **vanilla's** glowstone dust, not a GregTech material,
so `Sagmill: GlowStone` was never a bypass and stays.

Verified the way the earlier passes were: Ender IO's own recipe log goes from **680 to 691** skipped
recipes, exactly the eleven added names, and the audit drops from 49 live findings to 38 with 267
already switched off (was 256).

### What is left, and why it is left

* **34 `smelting` entries** (`Smelting: <metal> Dust` from the mod's own files) turn a GregTech dust into
  a GregTech ingot. Since 6bf locked the Alloy Smelter to `ALLOY_ONLY`, the only machine that can run
  them is Ender IO's dedicated **Simple Furnace** - one item at a time, i.e. a vanilla furnace on RF,
  which this pack allows. They are the reason the Simple Furnace question in 6bf is worth an answer, not
  a bypass on their own.
* **Two dye recipes** - `Alloy: Red Dye` in the alloy smelter and `Sagmill: Yellow Flower` in the mill -
  land on `dyeRed` / `dyeYellow`, names GregTech fills with its own dye dusts (the pack has GTCEu's
  `hardDyeRecipes` enabled). They make the *vanilla* dye item, so this is a cheap route to something
  GregTech also makes rather than a pack material handed out by another machine. Left in place, listed
  here so the owner can call it.
* **Two bone recipes** (`Sagmill: Bone`, `Sagmill: Bone Block`) land on `dyeWhite` because bone meal is
  one of that name's members. Bone into bone meal is a vanilla crafting recipe, so the mill is
  automating vanilla, not replacing GregTech.

Final run after the probe was removed and Ender IO's debug log switched back off: **47 mods**,
`Done (4.421s)`, zero `crafttweaker.log` errors, zero `Invalid amount of recipe inputs`, zero
`duplicate or conflict`, the two baseline `Invalid recipe` lines and the two baseline
`Input cannot contain null` lines, and no new Ender IO errors.

## 6bh. Closing Ender IO out, and the first reachability audit - 2026-10-13

The owner took the two recommendations from the end of 6bg: *"do step one and step two."*

### Step one: the loose ends 6bg left

* **The last two dye recipes.** `Alloy: Red Dye` (alloy smelter) and `Sagmill: Yellow Flower` (mill) are
  off. Both resolve to *vanilla* dye items in names GregTech also fills with its own dye dust
  (`dyeRed`, `dyeYellow`), which made them a cheap route around GregTech's dye line - this pack has
  GTCEu's `hardDyeRecipes` enabled.
* **The rest of that family, on the same rule.** `Alloy: Black Dye`, the four `Brown Dye` spellings and
  the four `Green Dye` spellings output Ender IO's *own* organic dye items, and those sit in
  `dyeBlack` / `dyeBrown` / `dyeGreen` beside GregTech's dye dusts - the "mod copy in a shared name"
  case this pack removes everywhere else. The three items left those names, `MinespaceMaterialRepoint`
  gained the three pairs, the ten recipes are switched off and the items are hidden. Vanilla's
  flower-into-dye crafting and GregTech's chemical dyes are untouched.
* **The mod's nuggets are gone too, and 6bc is retracted.** 6bc kept `1 ingot -> 9 nuggets` because
  Ender IO's grinding balls were believed to be cast from the mod's nuggets. 6bd's audit of the ball
  recipes showed otherwise: the mod ships the crafting-table form - five **ingots** in a cross into
  twenty-four balls, for the ten alloys and (via the Endergy addon) for the seven - and the casting
  forms want Tinkers Construct. With no consumer left, the nugget producers
  (`auto_<alloy>_1_ingot_to_9_nuggets` and Gregicality's mirrored `nugget_disassembling_<alloy>`) are
  removed in `eio_materials.zs` and the seventeen items are hidden.
* **Crystalline Pink Slime has a recipe** (6bd had left it without one because the addon's entry needs
  Industrial Foregoing). `integration.zs` now mixes pulsating powder with a slime ball and pink dye -
  the reagent substituted, not the shape, and labelled as a substitution in the script so it is deleted
  if Industrial Foregoing ever comes back.
* **Kept, with reasons:** Ender IO's Simple Furnace (a vanilla furnace on RF, one item at a time), and
  the two bone recipes (`Sagmill: Bone`, `Sagmill: Bone Block`), because bone into bone meal is a
  vanilla crafting path the mill would merely be automating.

### Step two: a reachability audit

The reason this was worth building: the owner's last four reports were all the same shape - something
the pack registered or un-unified that nothing can make. `MinespaceSourceProbe` (temporary, since
deleted) turns that into a list. It counts, for every item the pack cares about, how many recipes
produce it, where "produce" means a crafting-table recipe, a GregTech machine recipe - **main or
chanced output**, because most of GregTech's small and tiny dusts only exist as ore-processing
byproducts - or vanilla smelting. Its items are the members of every ore dictionary name that also
holds a GregTech item, restricted to the mods this pack gregifies, plus every form of the materials
this addon registers, plus every mod item the pack took out of a shared name.

The first run checked **240 items and found 126 with no producer**. Triaged, that is:

* **85 items the pack hides on purpose** (`scripts/jei_dupes.zs`) - the mod copies it unified away;
* **41 Forestry tree items** - logs, planks, saplings and leaves, which come from trees rather than
  from a recipe (and Forestry's fireproof forms from its own machines; Forestry is the owner's
  exception);
* **four real finds**, all fixed here: Ender IO's three organic dyes (above) and its **wooden gear**
  (`item_material:9`), which sits in `gearWood` beside AE2's and GregTech's and whose four five-stick
  recipes were switched off back in 6y - nothing has produced the mod's copy since, and it was still
  visible in JEI.

After the fixes the audit's invariant is exact and checkable: **every item it reports is either in the
JEI hide list or a Forestry tree item** (85 + 41 = 126), which is the state a pack wants - an item
that has no recipe is either deliberately out of the way or comes from the world.

### Verification

Ender IO's own recipe log goes **691 -> 703** skipped recipes - the twelve added names (two dye recipes
in step one, ten in the same family) - and the source audit's report is unchanged in size because
hiding an item does not give it a producer; the check is the hide-list comparison above. Baselines
unchanged throughout: 47 mods, zero `crafttweaker.log` errors, zero `Invalid amount of recipe inputs`,
zero `duplicate or conflict`, the two `Invalid recipe` and two `Input cannot contain null` baseline
lines, seven grinding-ball recipes.

## 6bi. Step three: the bypass audit across the other gregified mods - 2026-10-13

6bg and 6bh proved, mechanically, what Ender IO's recipes do. This step asks the same question of every
other mod in the pack: can any of them hand out a GregTech material, or keep producing a mod copy the
pack has unified away?

### What was checked

A temporary probe (`MinespaceBypassProbe`, since deleted) in two passes:

* **the crafting table, all mods.** Every recipe in the crafting registry whose namespace is not
  GregTech's, this addon's or CraftTweaker's - a mod's or vanilla's own recipe - checked for an output
  that *is* a GregTech item, and for an output the pack has unified away
  (`MinespaceMaterialRepoint.unifiedAwayIds()`: a leftover producer of a mod copy whose production the
  pack meant to stop).
* **the mod machines this pack has already dealt with**, read back through their own APIs - Applied
  Energistics' grinder and inscriber, Galacticraft's compressor and circuit fabricator, Forestry's
  thermionic fabricator and carpenter - so that "we cleared it" is a measurement and not a memory.

### What it found

**Exactly one crafting recipe in the whole pack hands out a GregTech item**, and it is not a bypass:

```
BYPASS PROBE mod crafting recipe makes a GregTech item: enderio:ender_dust -> gregtech:meta_item_1:2218
BYPASS PROBE crafting table: 1 GregTech-item outputs, 0 unified-away outputs
```

That is Ender IO's `Ender Dust`: nine of the mod's ender-pearl nuggets into one GregTech ender pearl
dust. Its partner recipe, in EIO's own SAG mill, turns one GregTech ender pearl dust into nine of those
nuggets - the pair is a **1:1 closed loop**, and EIO's XML says so in a comment. Nothing is gained, so
the pair stays; what matters is that it was read rather than assumed.

**Nothing anywhere still produces a unified-away item** (the second count above is 0). The mod copies
the pack took out of the shared names stay out - there is no Forestry / Galacticraft / Galaxy Space /
AE2 / Storage Drawers / Iron Chests / PlanetProgression recipe quietly handing one back.

**The mod machines are empty or rewritten as documented:**

```
BYPASS PROBE AE2 grinder recipes: 0
BYPASS PROBE AE2 inscriber recipes: 13
BYPASS PROBE Galacticraft compressor recipes: 0
```

and the final run prints GregTech's clearing of Galacticraft's machines directly: *"Cleared 30
Galacticraft compressor recipes and 3 circuit fabricator recipes (those machines are replaced by
GregTech)"*. AE2's 13 inscriber recipes are this pack's own rewritten set (GregTech inputs, AE2
outputs). Forestry's two managers could not be reached by the probe's reflection guesses, but those
were measured in their own rounds and are in every run's log: *"101 fabricator recipes visible, 13 of
101 tube recipes rewritten"* and *"5 carpenter recipes rewritten"*.

### The gap this step found in the tool - and closed

`tools/audit-eio-bypass.ps1` audited Ender IO's **machine** recipes only, which is why `Ender Dust` had
survived four passes of that tool without ever appearing: it is a `<crafting>` recipe. The tool now
scans the `crafting` block too, so **all 1896 of Ender IO's crafting recipes** are audited alongside
its 536 sagmilling, 96 smelting, 77 alloying and the rest. Re-run against the same state, the complete
EIO picture is:

| bucket | live | meaning |
| --- | --- | --- |
| `GT ITEM` | 35 | 1 crafting (`Ender Dust`, the 1:1 loop) + 34 `smelting` entries (reachable only from EIO's Simple Furnace) |
| `SHARED NAME` | 0 | - the dye recipes that used to sit here are all switched off |
| `GT SHARED` | 2 | `Sagmill: Bone` / `Bone Block`, bone meal in `dyeWhite`, a vanilla crafting path |
| already switched off | 273 | the pack's own disables plus Ender IO's own skipped recipes |

So Ender IO is mechanically closed, and so is every other mod: the only GregTech-item producer outside
GregTech is a lossless loop the pack already had two halves of.

### Verification

Final run with the probe removed: **47 mods**, `Done (5.706s)`, zero `crafttweaker.log` errors, zero
`Invalid amount of recipe inputs`, zero `duplicate or conflict`, the two baseline `Invalid recipe`
lines and the two baseline `Input cannot contain null` lines, no probe output, the seven grinding-ball
recipes still registered, and Galacticraft's clearing line above.

## 6bj. Step four: the playtest walk, and the nine plates it found - 2026-10-13

Steps two and three asked "is this item obtainable" and "does this recipe bypass GregTech". This step
asks the player's question, in order. It takes the items the pack deliberately moved into a machine -
`src/main/resources/minespace_machine_only.txt`, the same 326 ids `MinespaceCraftingBlocks` enforces -
and walks every input of every recipe that makes them, four levels deep, over the crafting table,
every GregTech recipe map (main *and* chanced outputs) and vanilla smelting. Whatever it runs out of
ingredients on is a leaf, and the leaves are the checklist: an ore or a flower is a legitimate root,
a plate that nothing makes is a broken chain.

The probe (`MinespaceProgressionProbe`) is temporary and is deleted with its call in
`Minespace.loadComplete()`; it writes `progression_probe.txt` into the instance rather than the log,
because 200 lines of leaves push everything else out of the console window.

### What it found: the nine plate kinds that had no source at all

The first run reported, among the leaves:

```
gregtech:meta_item_1:12018   plateCopper      producers=0
gregtech:meta_item_1:12071   plateTin         producers=0
gregtech:meta_item_1:12095   plateBronze      producers=0
gregtech:meta_item_1:12000   plateDesh        producers=0
gregtech:meta_item_1:12017   plateCobalt      producers=1   (a crafting recipe from nothing)
gregtech:meta_item_1:12044   plateNickel      producers=1
gregtech:meta_item_1:12033   plateIron        producers=5   (all of them disassembler chance outputs)
gregtech:meta_item_1:12184   plateSteel       producers=13  (the same)
gregtech:meta_item_1:12072   plateTitanium    producers=14  (the same)
```

Iron, steel and titanium had *only* machine-disassembler entries - the recycling map handing plates
back out of machine blocks, not a way to make one - which is why they never appeared as leaves at
all. Copper, tin, bronze, desh, cobalt and nickel had nothing. Every one of the nine is used by the
pack's own scripts (`integration.zs` builds chests out of `plateIron`, `gcp_tools.zs` builds the
Galacticraft-Planets tools out of `plateDesh`, ...), so the chains were broken at the first step.

### The cause: one ore dictionary resolution, read twice

Galacticraft registers its *compressed* copper / tin / steel / bronze / iron plate under GregTech's
plain names, and Galaxy Space does the same with cobalt and nickel. Gregicality writes its recipes
with `OreDictUnifier.get(OrePrefix.plate, material)` on both sides - as the ingredient where the
machine eats a plate, and as the **output** of the recipes it generates for the plate itself - and
that call answers with the first item in the ore dictionary name, which was the mod's compressed
plate. So the bender's "one ingot into one plate" wrote the *compressed* plate as its output, and the
guard from 6o then deleted that recipe, because a compressed plate is supposed to come out of the
implosion compressor and nowhere else. The deletion was right about the output and wrong about the
recipe: those 67 recipes were GregTech's own plate recipes, mis-pointed at the wrong item.

The evidence is the same run: the crafting-table half of the same generator (`plate_x` /
`flatten_plate_x`) also handed out the compressed plate - two ingots and a hammer in a grid for the
tier that is meant to cost two plates and TNT - and a `:32767` wildcard in an early probe version is
what hid the plate hole for a while.

### The fix, in its two halves

**Machines (Java, `MinespaceCompressedPlateGuard`).** The guard now re-points instead of deleting: a
recipe whose output is one of the compressed plates has that output replaced by the plain GregTech
plate of the same metal, resolved through the ore dictionary name (`plateCopper` -> the `gregtech`
stack in it) with the damage value as a fallback, and the recipe is deleted only when no plain plate
can be resolved. Counts, duration and EU/t are untouched, and the compressed plate keeps exactly one
producer - the implosion compressor - because nothing that outputs it survives un-repointed.

```
compressed-plate guard: 9 recipes re-pointed in fluid_solidifier
compressed-plate guard: 19 recipes re-pointed in metal_bender
compressed-plate guard: 10 recipes re-pointed in alloy_smelter
compressed-plate guard: 27 recipes re-pointed in cutting_saw
compressed-plate guard: 10 recipes re-pointed in extruder
compressed-plate guard: 10 recipes re-pointed in forge_hammer
compressed-plate guard: re-pointed smelting ...:12297 -> ...:12033 (was galacticraftcore:basic_item:11)
compressed-plate guard: re-pointed smelting ...:12298 -> ...:12184 (was galacticraftcore:basic_item:9)
compressed-plate guard (postInit pass): 87 ... re-pointed at the plain GregTech plate, 0 removed
```

Galaxy Space's cobalt and nickel plate stay the pack's exception: they are the dense tier for those
two metals **on purpose**, at the mod's own cost, `2 ingots into 1 plate` in the compressor, written
by `gs_removals.zs` ("Costs are GS's own; only the machine changed") because Galaxy Space's own
machines are built from them. Gregicality's nine plate recipes for each of those two metals were
*cheaper than the pack's own recipe* - one ingot in a bender - and those are re-pointed; the two
compressor entries are the pack's and are left alone (`KEPT_RECIPES` in the guard, and the log line
says so: "0 recipes re-pointed in compressor (2 of the pack's own left alone)").

**Crafting table (ZenScript, `plate_bridge.zs`).** `plate_x` / `flatten_plate_x` are mod-registered
Forge `ShapedOreRecipe`s, so the crafting registry is CraftTweaker's business, not the guard's. The
new script does both halves: `recipes.remove(<compressed plate>)` for all nine (the table must not
make the dense tier), then GregTech's own plate shape back for each of the nine - a hard hammer over
two ingots in a column, exactly what `gtadditions:plate_aluminium` does for a metal that was never
hijacked. Measured afterwards, `plateDesh` has ten producers: the six machine routes, the three
cutting-saw routes and the crafting recipe.

### The other dead recipes the walk exposed

* **Compressed desh** (`galacticraftplanets:item_basic_mars:5`) had one producer - the implosion
  compressor entry with empty item inputs, i.e. the invalid placeholder. The pack had an implosion
  recipe for the other seven metals and not for desh, and while Gregicality's mis-pointed recipes
  existed nobody noticed: a bender turning one desh ingot into a "compressed" plate was the only
  source. `gc_processing.zs` now has the eighth recipe, `2x plateDesh + TNT`, exactly the price the
  other seven pay. Galacticraft's own compressor recipe for the same item is "one desh ingot",
  which is the cheap route the pack deliberately does not keep.
* **Galaxy Space's Modern Wafer** (`galaxyspace:gs_basic:5`) was made in Galacticraft's Circuit
  Fabricator, which this pack clears, and eight assembler recipes in the pack are built from it.
  Galaxy Space registers it in its own source (`CraftingRecipesOverworld.addCircuitFabricator()`) as
  the third rung of Galacticraft's wafer ladder - a diamond, two raw silicon and the *previous*
  wafer - so `gaps.zs` adds the third rung in the shape `gc_removals.zs` already uses for the first
  two: two GregTech silicon plus four HV circuits in the assembler.
* **Galacticraft's Mars Heavy-Duty Plate** (`galacticraftplanets:item_basic_mars:3`) was a Compressor
  recipe and went with them. It is what the pack's own Mars machine block needs
  (`assembler_2.zs`, two per machine), so that recipe was dead. Galacticraft's source
  (`RecipeManagerMars.addUniversalRecipes()`) is `1x Tier-1 Heavy-Duty Plate + 1x compressed
  meteoric iron`, and `gaps.zs` writes it - in the **assembler**, not the compressor, and that is
  forced: GTCE-TJ declares the compressor map with exactly one item input ("Invalid amount of recipe
  inputs. Actual: 2. Should be between 1 and 1 inclusive." - the first version of this recipe was
  rejected on load, which is how the limit was found), while Galacticraft's recipe combines two
  different items.
* **Ender IO's four solar upgrades** were assembler recipes built from the solar panels this pack
  removes as generators, so they were dead recipes that JEI still showed. Their four recipes are gone
  from `eio_upgrades.zs` and the four NBT variants are hidden next to the panels in
  `integration.zs`. This is the same decision as the panels: the pack keeps neither a machine nor an
  upgrade that runs on free RF.
* **Galacticraft's two asteroid shards** (`item_basic_asteroids:3` / `:4`, Iron Shard and Titanium
  Shard) were not a dead recipe but a live leak, and the last one the walk found. GregTech's own shard
  lane (`OreDictionaryLoader` -> `OreRecipeHandler.processMetalSmelting`) writes "one shard -> one
  ingot" furnace recipes for any `shardX` name it finds, and Galacticraft is the only thing in the pack
  that fills two of them - with the shards its asteroid rock drops
  (`BlockBasicAsteroids.getDrops` builds exactly `basicItem:3` and `:4`). So iron and titanium ingots
  could be smelted out of a mod item that never went through GregTech's chain, which is the one thing
  the material unification is for. The iron lane is removed and both shards are hidden
  (`gc_removals.zs`); the titanium one turns out never to have existed - CraftTweaker's own count says
  **"1 recipes removed for: `<minecraft:iron_ingot>`" and "0 recipes removed for:
  `<ore:ingotTitanium>`"** - which is also why the walk had flagged the Iron Shard and not the
  Titanium Shard. The second call is kept so a mod update cannot quietly put the lane back. The items
  still drop from asteroid rock, because that is the block's own behaviour rather than a recipe, they
  are simply useless now - the smelting recipe was their only consumer in the pack.

### The leaves that are not holes

The final walk leaves 13390 leaves, and reading them is the point:

| bucket | count | what it is |
| --- | --- | --- |
| under an `ore` name | 13187 | world generation: `ore*` blocks, the planet rocks, the moon's and the asteroids' own blocks. Legitimate roots. |
| no producer, but a produced sibling under one of its own ore names | 21 | `circuitGood` / `circuitElite` (the Gregicality variants are made, the bare GregTech ids are alternatives under the same name), Ender IO's ten alloy ingots and its two metal powders (the GregTech items are produced under the same names), the pure/charged certus crystals (`crystalCertusQuartz`), `dyeBlack`, `enchanted_book`, `obsidian` |
| holes | 182 | everything else, and almost all of it is the probe's own blind spot, below |

The blind spot is worth stating plainly: the walk can only see the crafting table, GregTech's maps and
smelting. **A mod's own machine recipe is invisible to it.** So the 182 holes are, per mod:

* **Forestry** (18): honey combs, pollen, royal jelly and fruit come out of bees and trees; the
  circuit boards, electron tubes, flexible casing, woven silk, scented paneling and the hardened
  machine casing are the Carpenter's and the Thermionic Fabricator's, which `MinespaceForestryCarpenter`
  and `MinespaceForestryTubes` rewrite through Forestry's own managers ("101 fabricator recipes
  visible, 13 tube recipes rewritten", "5 carpenter recipes rewritten", every run).
* **Applied Energistics** (5): the three processors are the Inscriber's (13 recipes, this pack's own
  rewritten set), the pure fluix crystal is the throw-it-in-water mechanic, sky stone is a world
  structure.
* **Ender IO** (14): the industrial chassis, the soul and enhanced chassis and the machine parts are
  the Alloy Smelter's (`alloying.xml` "Chassis" / "Enhanced Chassis" / "Soul Chassis", which the pack
  keeps on ALLOY_ONLY), the crystals and powders are the SAG Mill's and the Vat's, the four skull
  items are the Soul Binder's.
* **Galacticraft / Galaxy Space** (18): the moon rock, asteroid rock, Venus volcanic rock, Barnard C
  ores and violet wood are world generation; the filled oxygen / fuel / liquid-nitrogen canisters come
  from the life-support and rocket-logistics machines the pack deliberately keeps;
  `item_basic_asteroids:3` (Iron Shard) was a mod leftover whose smelting recipe was the only thing
  that asked for it, and that lane is now removed with the shard hidden (the list above).
* **GregTech's own items** (109): the FE-to-EU converters from EV up (`power.zs` hides and removes
  them on purpose, and the disassembler is the only thing that mentions them), the MAX machine casing
  and the UHV-and-up converter ids, and the turbine-blade / long-stick / exquisite-gem variants of
  gem materials GregTech itself generates no recipe for. **`gregtech:machine:511..517` are the same
  kind of leftover and were checked before being left alone**: they are GTCE's own multiblock
  controllers (EBF / vacuum freezer / implosion compressor / pyrolyse oven / multi smelter / diesel
  engine), which this fork replaced with Gregicality's `ga_*` controllers - the frozen crafting dump
  shows `ga_electric_blast_furnace` and twenty other `ga_large_*` / `ga_alloy_blast_furnace`
  controllers all being produced, and 511's only user is Gregicality's own
  `ga_electric_blast_furnace_compatibility` conversion, which upgrades an old world's controller. So
  the blast furnace is reachable and the legacy ids are unreachable on purpose. Plus vanilla and
  Minecraft's own world items
  (flowers, saplings, logs, bone, clay, soul sand, prismarine shards, anvil damage stages, horse
  armour, elytra): those are the pack's world, not its recipes.

### The checkout list: what a play-test walks through, tier by tier

This is the deliverable of the step - the order to test in, and the check that says the chain is
still there. "Probe" means the number was read out of the finished registries in this round; "log"
means every server start prints it.

| tier | must be reachable | the check |
| --- | --- | --- |
| Minecraft | stone / iron tools, furnace, chest, and **GregTech's own ores** in the overworld | no mod ore blocks in the world; a GT ore drops GT's crushed / raw item; `MinespaceVanillaWorldgen` has the overworld vein list |
| steam / ULV | GT steam machines; a **copper plate** off the steam bending machine; the 9 grinding-ball recipes | probe: `plateCopper` 10 producers (bender, forge hammer, extruder, cutting saw x3, alloy smelter, fluid solidifier, crafting); log: 7 grinding-ball recipes |
| LV | circuits, tin/copper cable, the electric blast furnace's own chain, GT's EBF / vacuum freezer / implosion compressor controllers | probe: `circuitGood` family produced; every machine-only item still has a producer; log: `Invalid amount of recipe inputs` = 0 |
| MV | AE2's entry tier (the pack starts AE2 at MV), GT assembler work, steel and aluminium plate lines | `ae2_base.zs` MV recipes; probe: steel `24` and titanium `24` producers |
| GC rocket | compressed copper / tin / aluminium / steel / bronze / iron / **desh** / titanium plates, then Heavy-Duty Plates and the rocket parts | probe: each compressed plate has the implosion compressor (and the electric implosion) as its only producer, desh included; `gcp_tools.zs` uses dense plates where it always did |
| AE2 | the storage family, the ME machines, the processors | probe: processors are the Inscriber's (blind spot); log: 13 inscriber recipes, 0 grinder recipes |
| EIO | the ten alloys and seven endergy alloys through the GT alloy smelter / mixer, machine chassis through EIO's own Alloy Smelter, the machine recipes the pack rewrote | `eio_materials.zs` / `integration.zs`; `tools/audit-eio-bypass.ps1` re-run (1896 crafting, 536 sagmilling, 96 smelting) |
| RF / power | ULV-to-HV FE-to-EU converters work, EV and up do not exist | `power.zs` + the 182-hole list above: the EV+ converters are holes on purpose |

### Verification

The walk was run six times this round; the two numbers that matter are the plate holes and the dead
recipes. Leaves with no producer went **215 -> 203**: six plate ids, then the four solar panels, the
Modern Wafer and the Mars Heavy-Duty Plate. Iron, steel and titanium were never leaves at all -
machine-disassembler chance outputs counted as producers - which is why the nine only became visible
when the guard's log and the producer *sources* were read against the walk rather than the walk
alone. The hole bucket went **188 -> 182**, exactly those same four panels, wafer and plate. The
final run of the step is with the probe removed: **47 mods**, `Done` in the server log, zero
`crafttweaker.log` errors, zero `Invalid amount of recipe inputs`, zero `duplicate or conflict`, the
two baseline `Invalid recipe` and two `Input cannot contain null` lines, the seven grinding-ball
recipes, and the guard reporting 87 re-points with nothing left at load complete.

## 6bk. Step five: gears, and the same hijack a fourth time - 2026-10-13

The owner's question was "how should Ender IO's and the other mods' gears be unified with GregTech's?".
The answer is that gears were the plate bug again, measured with a live probe (`MinespaceGearProbe`,
deleted again afterwards):

| ore dictionary name | the name's first entry | GregTech's gear | its producers, before |
| --- | --- | --- | --- |
| `gearCopper` | `forestry:gear_copper:0` | `gregtech:meta_item_2:26018` | **0** |
| `gearTin` | `forestry:gear_tin:0` | `26071` | **0** |
| `gearBronze` | `forestry:gear_bronze:0` | `26095` | **0** |
| `gearWood` | `appliedenergistics2:material:40`, then `enderio:item_material:9` | `26196` | **0** |
| `gearIron` (control) | GregTech's only | `26033` | 4 |

Gregicality writes its gear recipes through `OreDictUnifier.get(OrePrefix.gear, material)` - the
extruder lane (4 ingots plus the extruder shape), the alloy smelter lane (8 ingots plus the mould) and
the fluid solidifier lane, plus the crafting recipe (four sticks and four plates around a wrench) - so
every lane for copper, tin and bronze was written against Forestry's gear and the wooden lane against
AE2's. GregTech's four gear items were unmakeable and the machines were making the mod's copies.

The probe also measured the half that decides whether the fix is safe: **every consumer of these four
names asks for the ore name, never the exact item**. The candidate list of each gear ingredient reads
`[forestry:gear_copper:0|gregtech:meta_item_2:26018]` and the like - Ender IO's machine recipes, the
moistener and the farm blocks, Galacticraft's, GregTech's own `casing_bronze_gearbox`, the macerator's
recycling lane and the arc furnaces - so handing the names to GregTech breaks nothing, and no bridge
recipe is needed.

### The rule the owner set

* **Ender IO's gears stay Ender IO's.** They are "bimetal" - an iron / construction-alloy core coated
  in an alloy's nuggets - GregTech has no counterpart for them and no gear at all for the alloys they
  are made of, so there is nothing to hand the names to. Only the machine changes: they are machine
  components and every Ender IO machine block is built from them, so the four
  (`item_material:11` Infinity, `:12` Energized, `:13` Vibrant, `:73` Dark) are assembler recipes now,
  same materials and counts, one tier up each rung (LV 30 / MV 120 / HV 480) with an integrated
  circuit. `item_material:10`, the stone compound gear, stays on the crafting table: cobblestone,
  sticks and a wooden gear is LV work.
* **Everything that is a same-material gear leaves.** Forestry's copper, tin and bronze gear (single
  metals GregTech has gears for; their own crafting recipes were removed by `integration.zs` long ago)
  and the two wooden gears, AE2's and Ender IO's.

<p>The one open option this step raised was whether to give the Ender IO alloys themselves a
`GENERATE_GEAR` flag so GregTech could make `gearDarkSteel`, `gearEnergeticAlloy` and the like. The
owner's answer, recorded here so it does not come up again: **no**. Ender IO's bimetal gears stay the
only gears those metals have, which is what "the bimetal gear is unique to Ender IO" means in
practice.</p>

### The changes

* `oredict.zs` - five removals hand the four names to GregTech. The heading there also records why
  Ender IO's five gears are *not* in the list.
* `MinespaceMaterialRepoint.sharedNames()` - five entries, which is all the gear swap needs, because
  that table already drives the three-way re-point: machine outputs (the three lanes per metal that
  were making Forestry's gear), machine inputs and crafting inputs. The plates stay in their own guard
  only because Galaxy Space's two compressed plates have a "keep the pack's own recipe" case this table
  cannot express.
* `gear_bridge.zs` (new) - GregTech's own crafting shape back for copper, tin and bronze: four sticks
  at the corners, four plates at the edges and a wrench in the middle, copied from the surviving
  `gtadditions:gear_iron` (whose input list is `stickIron, plateIron, stickIron, plateIron,
  craftingToolWrench, plateIron, stickIron, plateIron, stickIron`). Gregicality's hijacked copies of
  that recipe had been deleted as "a machine makes the same item", so copper and tin and bronze gears
  were about to be the only metals with no table recipe.
* `ae2_base.zs` - the pack's saw-and-file wooden gear recipe now outputs **GregTech's** wooden gear.
  That recipe has to be the one that makes it, because GregTech itself ships no recipe for its wooden
  gear at all: `PartsRecipeHandler.processGear` writes the machine lanes only for an `IngotMaterial`
  (wood is not one) and the crafting lane wants double plates, of which there is no wooden one. The
  `recipes.remove(<appliedenergistics2:material:40>)` above it still matches AE2's gear, which is also
  what clears Ender IO's four `<crafting>`-registered `GEAR_WOOD` recipes for the same item.
* `assembler_1.zs` - Ender IO's four gears leave the crafting table (3x3 grids) and are assembler
  recipes at the same cost. Its comment records where the Grains of Infinity come from: not a recipe
  but Ender IO's in-world crafting (bedrock into Fire Water, `InfinityConfig.bedrock`), which is why no
  registry audit ever sees a producer for `item_material:20`.
* `jei_dupes.zs` - Forestry's three gears and AE2's wooden gear are hidden: out of a shared name and
  produced by nothing, the same rule the ingots, dusts and blocks follow. Ender IO's wooden gear was
  hidden there already.

### Verification

The same probe, run again with the changes in - every line is a measurement, not a claim:

```
NAME gearCopper = *gregtech:meta_item_2:26018      (1 entry, GregTech's)
NAME gearTin    = *gregtech:meta_item_2:26071
NAME gearBronze = *gregtech:meta_item_2:26095
NAME gearWood   = *gregtech:meta_item_2:26196
WATCH gregtech:meta_item_2:26018  producers = 4   (crafting + fluid solidifier + alloy smelter + extruder)
WATCH gregtech:meta_item_2:26071  producers = 4
WATCH gregtech:meta_item_2:26095  producers = 4
WATCH gregtech:meta_item_2:26196  producers = 1   (the saw-and-file crafting recipe)
WATCH forestry:gear_copper:0      producers = 0
WATCH forestry:gear_tin:0         producers = 0
WATCH forestry:gear_bronze:0      producers = 0
WATCH appliedenergistics2:material:40  producers = 0
WATCH enderio:item_material:9     producers = 0
WATCH enderio:item_material:10    producers = 2   (its own stone-gear recipes, untouched)
WATCH enderio:item_material:11    producers = 1   (map:assembler)
WATCH enderio:item_material:12    producers = 1   (map:assembler)
WATCH enderio:item_material:13    producers = 1   (map:assembler)
WATCH enderio:item_material:73    producers = 1   (map:assembler)
```

and the consumers read `[gregtech:meta_item_2:26018]` where they used to read
`[forestry:gear_copper:0|gregtech:meta_item_2:26018]`: the mod's copy is out of the name and out of the
recipes. The final run is with the probe removed - 47 mods, zero `crafttweaker.log` errors, zero
`Invalid amount of recipe inputs`, zero `duplicate or conflict`, the baseline two `Invalid recipe` and
two `Input cannot contain null` lines, the seven grinding-ball recipes, the plate guard's 87 re-points
and nothing left at load complete.

## 6bl. Step six: the ore round - the sweep, the world, and the leftovers - 2026-10-13

The last three rounds (6bj plates, 6bk gears, and the material unification before them) all worked from
the same measurement: which ore dictionary names hold both a GregTech item and another mod's item, and
which of them the name answers with. This round does the three things that were left on that list.

### 1. The sweep, re-read live

A temporary probe (`MinespaceOreSweepProbe`, deleted again) replaced the stale 10-12 dump and split every
shared name by its answer. Before this round:

```
# totals: gt-first=4 vanilla-first=27 other-first=19
```

and after it:

```
# totals: gt-first=4 vanilla-first=27 other-first=4
```

The four that remain are the deliberate ones, and the probe's own listing says why:

| name | answer | why it stays |
| --- | --- | --- |
| `gemApatite`, `oreApatite`, `blockApatite` | Forestry's | Forestry's own material: its apatite ore is the only source of it and still generates (`common.cfg: apatite=true`), so its copy is obtainable and is the same material - the pack's "an ingot is an ingot" case, plus the owner's Forestry exception |
| `oreCertusQuartz` | AE2's | AE2's quartz ore is what its meteorites are made of, and the meteorites are the only source of the sky stone the whole AE2 machine line is built from; GregTech's own certus ore sits in the same name |

The rule the other fifteen followed, and the one to use for the next name that turns up:

* **unobtainable mod copy** (its own generation is off and nothing else makes it) -> hand the name to
  GregTech, re-point everything that produced or ate it, delete the furnace lanes that smelted it, and
  hide the item;
* **obtainable copy of the same material** -> leave it, that is the "an ingot is an ingot" case;
* **Forestry's own material** -> leave it, that is the owner's exception.

### 2. The world, measured rather than assumed

The ore blocks in those names are unobtainable on paper only if the generation switches really are off,
so each one was read:

* **Galaxy Space** - `config/GalaxySpace/world.conf`: `enableOresGeneration=false`,
  `enableOverworldOres=false`, `enableMarsNewOres=false`, `enableNatureGasGen=false`.
* **Galacticraft** - `config/Galacticraft/core.cfg`: overworld copper / tin / aluminium / silicon all
  `false`, and the Moon's cheese / tin / copper / sapphire ore generation all disabled;
  `config/Galacticraft/planets.cfg`: Mars (iron, copper, tin, desh), Asteroids (iron, aluminium,
  ilmenite) and Venus (aluminium, copper, galena, quartz, silicon, tin, solar) all disabled.
* **Vanilla** - GregTech's own `B:disableVanillaOres=true`, which `MinespaceVanillaWorldgen` records as
  "measuring a fresh overworld shows all eight at exactly 0 blocks".
* **Forestry** - `config/forestry/common.cfg` had `copper=true` and `tin=true`: the last live duplicate
  copper and tin ore in the world, sitting next to GregTech's own ores. Both are switched off in this
  round (`apatite` is Forestry's own material and stays `true`).

The measurement that closes it: the probe's block census of nine chunks around the spawn of a freshly
generated overworld, **after** the change:

```
CENSUS appliedenergistics2:quartz_ore = 21        (an AE2 meteorite, kept on purpose)
CENSUS galacticraftcore:crude_oil_still = 1       (GC's oil, kept on purpose)
```

No Forestry ore, no vanilla ore, and nothing from Galacticraft's or Galaxy Space's ore lists. (The two
that show up are the two kinds of world content this round deliberately keeps: AE2's meteorite sky
stone and Galacticraft's oil.)

### 3. The leftovers

* `oredict.zs` - 33 ore-block removals (the Galacticraft and Galaxy Space ore blocks plus Forestry's
  copper and tin ore) and 4 block removals (Forestry's copper / tin / bronze / charcoal storage block;
  its apatite block is left with the rest of apatite). The heading in the file states the rule and the
  three names that are deliberately not in the list.
* `MinespaceMaterialRepoint.sharedNames()` - 36 new entries, which is what makes the re-point cover the
  ore and block names: machine outputs (the compressor's `block_compress_copper` and friends were
  written against Forestry's block), machine inputs and crafting inputs.
* **`MinespaceMaterialRepoint.pruneDeadSmelting`** (new, called after `repointSmelting` in both rounds)
  - deletes a vanilla-furnace entry whose *input* is an item this table has handed to GregTech. Those
    entries are the mods' own "ore block -> one ingot" lanes; they were unbuildable while JEI still
    listed them, and `repointSmelting` had already moved their outputs to GregTech's ingot. Measured:
    **43 recipes deleted on the postInit pass, 0 on the loadComplete pass** (idempotent), e.g.
    `forestry:resources:1 -> gregtech:meta_item_1:10018` and
    `galacticraftplanets:venus:11 -> gregtech:meta_item_1:10071`.
* `jei_dupes.zs` - 39 hides for the same items: out of a shared name and produced by nothing, the same
  rule the ingots, dusts, gears and blocks follow. CraftTweaker reported zero
  "Could not find any matching ingredients" lines, so every one of them was a real JEI entry.

### What the swap did not touch

GregTech's own ore processing. The probe printed the candidate list of every consuming ingredient, and
the macerator / chemical bath / forge hammer lanes take an **ore-name** ingredient listing all 34
`oreCopper` entries (down to GregTech's own after the swap), so they keep working on every block - and
so does GT's `OreRecipeHandler` chain for GregTech's own ore blocks. The only exact-item consumers were
the per-block furnace lanes, which is exactly what the pruner deletes. Nothing else in the pack - no
Galacticraft, Galaxy Space, Forestry or AE2 recipe - references one of these blocks by id.

### Verification

The sweep probe ran with the changes in (the numbers above), and the final run is with the probe
removed: **47 mods**, `Done`, zero `crafttweaker.log` errors, zero `Invalid amount of recipe inputs`,
zero `duplicate or conflict`, the baseline two `Invalid recipe` and two `Input cannot contain null`
lines, seven grinding-ball recipes, the plate guard's 87 re-points, 53 ore / block ore-dictionary
removals in the CraftTweaker log and 43 pruned furnace lanes.

## 6bm. The crash the audit found: a client-only sound class, called from the server - 2026-10-13

Step six's block census needed two runs, and the second run's crash report is what this section is
about. An earlier run of the same evening had already died, and the report says how:

```
Description: Exception in server tick loop
	at gregtech.api.metatileentity.MetaTileEntity.onRemoval(MetaTileEntity.java:1271)
	at gregtech.api.block.machines.BlockMachine.func_180663_b(BlockMachine.java:258)
	at net.minecraft.world.chunk.Chunk.func_177436_a(Chunk.java:567)
	at net.minecraft.world.World.func_180501_a(World.java:343)
	at appeng.worldgen.meteorite.ChunkOnly.setBlock(ChunkOnly.java:76)
	at appeng.worldgen.meteorite.MeteoritePlacer.placeCrater(MeteoritePlacer.java:174)
	...
Caused by: Attempted to load class gregtech/common/sound/MachineSoundManager for invalid side SERVER
```

Applied Energistics places its meteorites with the world's ordinary `setBlockState`, and when a crater
overwrote a GregTech MetaTileEntity - a machine, or one of the surface ore rocks GregTech generates to
mark a vein - that block's `breakBlock` called `MetaTileEntity.onRemoval()`, whose base implementation
is exactly one statement:

```
public void onRemoval() { MachineSoundManager.stop(getPos()); }
```

and `gregtech.common.sound.MachineSoundManager` is client-only. On a dedicated server Forge strips the
class, the class-load throws, and the server dies **with no player online**, about thirty seconds after
`Done` - which is why two of the last four runs had been recorded as green here: their logs looked
clean right up to the moment the tick loop reached the meteorite queue. The lesson for the rest of this
document: a run is not verified at `Done`, it is verified after the server has ticked for a while and
the crash-report directory has been checked.

### The fix

A one-method mixin, `MixinMetaTileEntityOnRemoval`, using the mixin infrastructure the Moon / Mars /
Venus rock fix already brought in:

```java
@Mixin(MetaTileEntity.class)
public class MixinMetaTileEntityOnRemoval {
    @Inject(method = "onRemoval", at = @At("HEAD"), cancellable = true)
    private void minespace$skipClientOnlySoundOnServer(CallbackInfo callback) {
        if (!FMLCommonHandler.instance().getSide().isClient()) {
            callback.cancel();
        }
    }
}
```

Nothing is lost by cancelling: the base body is only that sound call (read out of
`gregtech_tj_fork-1.18.3.jar`), so a server has nothing else in it to run; a subclass that overrides
`onRemoval` keeps its own behaviour and only loses the client sound; and on a client the guard does not
cancel, so the sound still stops as before. It covers every worldgen that overwrites a GregTech machine
- Galacticraft's and Galaxy Space's features included - not just AE2's meteorites.

### What was verified, and what could not be

* the mixin is applied on every start; MixinBooter's audit prints it:
  `APPLY mixins.minespace.json:MixinMetaTileEntityOnRemoval from mod minespace ->
  gregtech.api.metatileentity.MetaTileEntity` (`logs/mixinbooter.log`);
* the base method's body is exactly the one client-only call - bytecode read, not assumed;
* `gregtech.common.blocks.BlockOre extends BlockFalling`, **not** a MetaTileEntity, so ordinary ore
  mining never went near this path (checked because "breaking a GT block crashes the server" would
  have been a much bigger claim);
* the crash itself could **not** be reproduced on demand: a controlled test that looked for a GregTech
  machine block to break found none in eighty-one spawn chunks of a fresh overworld, so it reported
  "the guard is not proven this run" instead of claiming a pass. The trigger is a meteorite landing on
  a machine or a surface rock, which is exactly why the bug survived several rounds of testing.

For the record of the instance's `crash-reports/` directory: the report
`crash-2026-10-13_20.03.57-server.txt` **is** this bug (the AE2 meteorite on a GregTech machine), and
the later `crash-2026-10-13_20.19.48-server.txt` is a mistake of the census probe itself - it tried to
register an `@SubscribeEvent` listener for FML's `FMLServerStartedEvent`, which is a mod-lifecycle
event rather than a Forge `Event`, and Forge's bus refuses that at registration time and takes the
start down with it (the fixed probe used `WorldEvent.Load`). Neither is a recipe problem.

## 6bn. Apatite and certus quartz: GregTech has the veins, so the names go to it - 2026-10-13

6bl's sweep was left with four names still answering with a mod item, and the owner's rule for two of
them is the subject of this section: **apatite and certus quartz must have GregTech veins**. They do,
and this round hands the names over on the strength of it.

### What was measured

The veins are not just files on disk; they are in the running registry, which a temporary probe
(`MinespaceVeinCensusProbe`, deleted again) printed out of `WorldGenRegistry.getOreDeposits()`:

```
VEIN mars\certus_quartz_vein.json      weight=24  density=0.25  height=80..120    isVein=true
VEIN moon\certus_quartz_vein.json      weight=62  density=0.25  height=80..120    isVein=true
VEIN nether\netherquartz_vein.json     weight=170 density=0.2   height=40..110    isVein=true
VEIN overworld\apatite_vein.json       weight=60  density=0.3   height=60..(max)  isVein=true
VEIN overworld\quartz_vein.json        weight=70  density=0.4   height=40..(max)  isVein=true
VEIN venus\certus_quartz_vein.json     weight=36  density=0.25  height=80..120    isVein=true
```

and the part that actually matters - **which block the vein places** - is GregTech's own ore, not the
mod's, because `"ore:apatite"` in a vein file is *not* an ore dictionary lookup. The probe called the
same resolution the filler uses:

```
FILLER ore:apatite      -> 35 stone types: gregtech:ore_apatite_2:1  gregtech:ore_apatite_0:3  ...
FILLER ore:certus_quartz -> 35 stone types: gregtech:ore_certus_quartz_0:3  ...
```

`OreConfigUtils.getOreStateMap("ore:<material>")` strips the prefix and goes through
`getMaterialByName` -> `getOreForMaterial`, which walks **`MetaBlocks.ORES`** - GregTech's own ore
blocks, per stone type. The ore-dictionary route exists but is a different notation (`ore_dict:`,
which none of these veins uses). So a GregTech apatite vein yields GregTech apatite, and the certus
quartz vein on the Moon, Mars, Venus, the fourteen Galaxy Space bodies (the vein's
`dimension_filter` lists them all) and 30% of the overworld's quartz vein yields GregTech certus
quartz. `MinespacePlanetOreGen` is what makes GregTech's veins run on the Galacticraft bodies at all.

One honest negative: a 15x15-chunk census of a fresh overworld around spawn found **no** apatite vein.
That is expected and not a failure - a specific vein is rare (apatite's weight 60 against the
overworld's whole vein list), so a spawn-sized sample usually misses every individual vein; the
registration, the filler resolution and the pack's earlier whole-save measurement (83,827 GregTech ore
blocks in 289 chunks) are the evidence, not the sample.

### The rule this changes

6bl's rule was "an obtainable copy of the same material stays in the name", and it was applied to
these two because the mods' sources were the only ones measured. With GregTech's vein confirmed, the
owner's rule takes over: the GT source is the canonical one, so the mods' copies leave.

* `oreApatite`, `gemApatite`, `blockApatite` - Forestry's apatite ore, gem and block leave the names,
  and Forestry's apatite **ore generation is switched off** (`config/forestry/common.cfg:
  apatite=false`, the last of its three ore switches). Gregicality's gem lanes for apatite (the ore's
  own gem yield, gem -> flawed, gem -> flawless) had been written against Forestry's gem; the three
  ids are in `MinespaceMaterialRepoint.sharedNames()`, so those outputs now come out as GregTech's
  apatite gem and the whole chain - ore, dust, gem, flawed, flawless - is GregTech's. Forestry's
  machines ask for `<ore:gemApatite>`, which now answers with GregTech's gem: same material, so the
  fertiliser and stamp chains are untouched. The three Forestry items are hidden (`jei_dupes.zs`) -
  out of a shared name and produced by nothing.
* `oreCertusQuartz` - AE2's quartz ore and charged quartz ore leave the name. The **meteorites stay**:
  they are the only source of the sky stone the whole AE2 line is built from, so their ore is still
  obtainable, it is simply no longer what the name answers with. `oreChargedCertusQuartz` is left
  exactly as it was - that name holds only AE2's charged ore, and GregTech has no charged certus ore.
  AE2's two ore blocks are deliberately **not** in `MinespaceMaterialRepoint.sharedNames()` either:
  that table is what `pruneDeadSmelting` uses to find furnace lanes whose input nothing produces, and
  AE2's ore is still produced.

The sweep is now clean:

```
ANSWER gemApatite           -> *gregtech:meta_item_1:8226          (1 entry)
ANSWER oreApatite           -> *gregtech:ore_apatite_0:0 ...       (26 entries, all GregTech's)
ANSWER blockApatite         -> *gregtech:meta_block_compressed_14:2 (1 entry)
ANSWER oreCertusQuartz      -> *gregtech:ore_certus_quartz_0:0 ... (26 entries, all GregTech's)
ANSWER oreChargedCertusQuartz -> *appliedenergistics2:charged_quartz_ore:0 (1 entry, kept)
```

and the shared-name sweep's `other-first` count is **0**: every ore dictionary name in the pack that
GregTech and another mod both fill now answers with GregTech's item, except `oreChargedCertusQuartz`,
which only AE2 fills.

## 6bo. Certus quartz: GregTech's material and AE2's crystal, bridged - 2026-10-13

The owner's report right after 6bn: *"AE2's certus quartz crystal and GregTech's certus quartz cannot be
used interchangeably, and there is no way to convert GregTech's certus quartz into AE2's crystal."*
Measured, both halves are true:

* `<ore:crystalCertusQuartz>` held only AE2's three crystals - `material:0` (plain), `:1` (charged),
  `:10` (pure) - which is exactly the set 6y had put back into it. GregTech's certus quartz was in
  none of them;
* the recipes that matter are **not** all written against the name. This pack's own AE2 assembler
  recipes address `appliedenergistics2:material:0` by item id (the energy cell, the view cell, the
  processors `material:27/42/43`, quartz glass, the quartz block), and so do AE2's charger and
  inscriber - the two machines that turn a crystal into a charged crystal and into printed circuits.
  AE2's crystal is AE2's own form of the material and its machines hardcode it, so it cannot be
  replaced by GregTech's item, and the player's only source of it used to be AE2's meteorite ore.

GregTech's side of the same material is a full chain, measured from the registries rather than
assumed: GregTech's certus quartz **vein** (6bn) on the Moon, Mars, Venus and the Galaxy Space bodies
plus a quarter of the overworld's quartz vein; the ore; the crushed line; the dust
(`gregtech:meta_item_1:2202`); and the gem (`gregtech:meta_item_1:8202`), which the autoclave makes
out of the dust (`MAP autoclave OUT 8202 <- IN 2202`) and the forge hammer out of a flawless gem. So
the gap was exactly the two halves the owner named - no shared name, and no conversion.

### The fix, in two parts

* `oredict.zs` adds GregTech's certus quartz gem to `crystalCertusQuartz`, **appended** so that AE2's
  plain crystal stays the first entry - what AE2's own code expects. Every recipe written against the
  name (this pack's AE2 tools and its grindstone, the storage rewrites) now takes either material.
* `gaps.zs` adds the 1:1 bridges in **both** directions, one crystal for one gem and back, for
  everything that addresses the crystal by item id: this pack's AE2 assembler recipes, AE2's charger
  and its inscriber. Nothing is gained or lost - the same reasoning the pack kept Ender IO's Ender
  Dust loop on - AE2's crystal stays AE2's item, and GregTech's gem stays GregTech's.

### Verification

The CraftTweaker log names what it added; on the next run:

```
Adding item.meta_item.name to ore dictionary entry crystalCertusQuartz
Adding shapeless recipe for Certus Quartz Crystal with name ct_shapeless-1246815012
Adding shapeless recipe for item.meta_item.name with name ct_shapeless1777905286
```

The first line is GregTech's gem joining the name (its display name is unlocalised server-side, which
is why it prints as `item.meta_item.name`; the client shows GregTech's own name), and the second and
third are the two bridges. The baseline is unchanged: 47 mods, zero `crafttweaker.log` errors, zero
`Invalid amount of recipe inputs`, zero `duplicate or conflict`, the baseline two `Invalid recipe` and
two `Input cannot contain null` lines, seven grinding-ball recipes, and no new crash reports.

## 6bp. The step-six acceptance: `power.zs` and the play-test checklist, measured - 2026-10-13

The two items that were still queued after the ore round were `power.zs`'s red line and the §6bj
checklist. Both are registry questions, so a temporary probe (`MinespaceChecklistProbe`, deleted again)
answered them instead of reading the scripts back.

### `power.zs`: the EU ceiling holds

Gregicality registers two converter families per tier: a "GTEU Energy Converter (tier)" and a "Forge
Energy Converter (tier)" per amperage size. (This sentence originally said the names tell you which
way each one converts - `GTEU` into GregTech, `Forge` back out. They do not: the names are written
from the *input* side, and 6cl measured it the other way round - see the note below the table.)
Walking every `gregtech:machine` meta in the converter ranges and asking the crafting registry:

```
ULV  2900..2907   GTEU CRAFTABLE   Forge CRAFTABLE
LV   2908..2915   GTEU CRAFTABLE   Forge CRAFTABLE
MV   2916..2923   GTEU CRAFTABLE   Forge CRAFTABLE
HV   2924..2931   GTEU CRAFTABLE   Forge CRAFTABLE
EV   2932..2939   GTEU NO-RECIPE   Forge CRAFTABLE
IV   2940..2947   GTEU NO-RECIPE   Forge CRAFTABLE
LuV  2948..2955   GTEU NO-RECIPE   Forge CRAFTABLE
ZPM  2956..2963   GTEU NO-RECIPE   Forge CRAFTABLE
UV   2964..2971   GTEU NO-RECIPE   Forge CRAFTABLE
UHV  4075..4082   GTEU NO-RECIPE   Forge CRAFTABLE
UEV  4083..4090   GTEU NO-RECIPE   Forge CRAFTABLE
UIV  4091..4096   GTEU NO-RECIPE   Forge CRAFTABLE
UMV  4097..4104   GTEU NO-RECIPE   Forge CRAFTABLE
```

**Corrected 2026-10-15 (6cl): this table is the inversion named there.** The measurement is the
right-hand half of each row - which ids have a recipe - but the two labels were the pre-6cl reading of
the names, and the names mean the opposite. Read with the directions the jar actually implements
(6cl), the table says that **from EV up the FE-to-EU machine stayed craftable and the EU-to-FE one was
the one being removed**, i.e. exactly the reverse of the design 6m describes: mod power could still be
turned into GregTech power at every tier, and GregTech power could no longer be spent on a mod's
machine above HV. Which ids the probe found without a recipe is what `power.zs` was looking at; the
labels are the mistake, and `power.zs` moved to the other family of each pair on 2026-10-15.

With that reading in place, the design 6m describes is what the pack now implements: ULV to HV can turn
mod power into GregTech power, EV and up cannot, and the EU-to-FE direction is untouched at every tier
- GregTech power may always be *spent* on
a Forestry / Ender IO / Galacticraft / Galaxy Space / AE2 machine, it may never be *made* by one. The
same probe also confirms the checklist's LV / MV machinery: every Gregicality multiblock controller is
craftable, including the three the early tiers are gated on - **Electric Blast Furnace (`machine:2534`),
Vacuum Freezer (`2535`) and Implosion Compressor (`2536`)** - alongside the large machines (thermal
centrifuge, electrolyzer, bending and forming, centrifuge, cutting, macerator, mixer, sifter, washing
plant, wiremill, chemical reactor, extruder, assembler), the Multi Smelter, the three large turbines,
the Large Transformer, the Alloy Blast Furnace and the three Miners.

### The §6bj checklist, item by item

Thirty-one items across the tiers, with their producer counts. Every one is satisfied; the four that
came back at zero from the plain registry walk are the two known probe blind spots, and both were then
measured through the right API:

| tier | item | producers |
| --- | --- | --- |
| LV | `circuitBasic` (`meta_item_2:32487`) | 108 |
| LV | `circuitAdvanced` (`32491`) | 3 (circuit assembler) |
| LV | copper / iron / steel plate | 10 / 16 / 24 |
| GC | compressed copper, steel, iron, desh, titanium | 3 / 3 / 3 / 3 / 2, implosion compressor |
| GC | Tier-1 Heavy-Duty Plate, Mars Heavy-Duty Plate, Mars machine block | 1 each, assembler |
| GC | Galaxy Space Modern Wafer | 1, assembler |
| AE2 | ME Controller, Energy Cell, 1k / 64k Crafting Storage | 1 each, assembler |
| EIO | the four bimetal gears | 1 each, assembler |
| EIO | Alloy Smelter, SAG Mill, enhanced versions | 2 each, assembler |

and the two blind spots:

* **`circuitGood`** - the name holds several MV circuit variants and the bare GregTech ids
  (`meta_item_2:32489` / `32490`) are the unused ones, so "producer count 0" for those two means
  nothing. What matters is the name: `gtadditions:ga_meta_item:32200`, also under `circuitGood`, has
  **116 producers**, and `32201` has 6 (the circuit assembler). Recipes written against
  `<ore:circuitGood>` - which is what the pack's scripts use - are satisfied.
* **AE2's three processors** (`material:22` logic, `:23` calculation, `:24` engineering) - they are made
  in the Inscriber, which is not a GregTech recipe map, so the walk cannot see them and reads "0". Read
  through AE2's own registry instead: the Inscriber holds **13 recipes**, and their outputs include
  `material:22`, `:23` and `:24` exactly, alongside the printed circuits `13..20` and `59/60`.

So every row of the checklist is satisfied at the registry level. What the registry cannot prove is the
player's half - blocks mined, machines placed and run, a rocket actually built - and the checklist in
6bj is written so those are the checks a play-test performs; nothing in the mechanical half is
outstanding.

## 6bq. The mods' own machines: AE2's Inscriber and Forestry's factory - 2026-10-13

Every audit so far has read the crafting registry, GregTech's recipe maps and vanilla smelting. A
mod's *own* machine keeps its recipes somewhere else, and that is the last place a bypass can hide.
Both registries were therefore read through the mods' own APIs by a temporary probe
(`MinespaceMachineCostProbe`, deleted again) - the same accessors this pack's Java classes use:
`AEApi.instance().registries().inscriber()/.grinder()` and
`forestry.api.recipes.RecipeManagers.{carpenter,fabricator,centrifuge,squeezer,fermenter,moistener,still}Manager`.
Each recipe was flagged if it hands out a GregTech item, hands out an item the pack has given to
GregTech ({@link MinespaceMaterialRepoint#unifiedAwayIds()}), or lives entirely on such an item.

### Applied Energistics: clean

* **Inscriber, 13 recipes.** The three processors are not made out of redstone: each one takes the
  matching *printed circuit* plus its press, e.g.
  `PRESS top=material:16 bottom=material:20 -> material:23 <- redstone`. The printed circuits are the
  ones this pack re-costed (`material:17 <- GT diamond plate 12111`, `material:18 <- GT gold plate
  12026`, `material:20 <- GT silicon ingot 10061`), and the presses themselves
  (`material:13/14/15`) come out of **GT steel blocks** (`meta_block_compressed_11:8`). So the AE2
  line starts from GregTech's metal and silicon, exactly as 6y intended.
* **Grinder, 0 recipes** - emptied by 6t, its unique recipes moved into the macerator.
* No inscriber recipe outputs a GregTech item and none is dead, so the AE2 side carries no flags.

### Forestry: one real finding, in the Carpenter

* **Thermionic Fabricator, 101 recipes** - clean. The 13 tube recipes carry the GregTech fine wire
  and iron screw 6aj put there, the rest are Forestry's own wood / refractory wax / glass work, and
  the dye cells still list GregTech's dye dusts among their alternatives.
* **Centrifuge, 25 recipes** - Gregicality's bee combs (`gtadditions:comb:*`) centrifuge into
  GregTech dusts and items. That is the intended interop (the comb chain is the beekeeping side of
  GregTech), so it is reported rather than flagged as a bypass.
* **Carpenter** - seven recipes handed a retired item back out: the crate pairs for tin, copper,
  bronze, apatite and ash (`forestry:crated.x -> x x9`, plus the filling recipes) and two "broken tool
  into ingots" recipes. They are not a source of a retired item out of nothing - a crate needs nine
  of the item and the broken tools cannot be made any more - but they did make those items
  "produced by something", which is the rule `jei_dupes.zs` hides them on, and an old crate could
  convert GregTech's ingots back into Forestry's.

### What was fixed, including a bug the audit exposed in this pack's own code

`MinespaceForestryCarpenter` gained `repointRetiredItems`, which re-points the Carpenter's outputs
and cells at GregTech's items (the same table `MinespaceMaterialRepoint` uses, now exposed as
`currentTargets()`). The crates keep working - nine **GregTech** tin ingots fill a crate of tin and
open back into nine - and nothing produces the retired copies any more, so the `jei_dupes` rule is
true again. Measured targets include `forestry:ingot_bronze:0 -> gregtech:meta_item_1:10095`,
`forestry:ingot_tin:0 -> 10071`, `forestry:ingot_copper:0 -> 10018`,
`forestry:apatite:0 -> 8226` and `forestry:ash:0 -> 2089`.

Writing that pass exposed a second bug in the existing chipset rewrite: it wrote a Forge
`Ingredient` into Forestry's own cell list, whose cells are `NonNullList<ItemStack>` - and
`ShapedRecipeCustom.checkMatch` reads *that* list, not Forge's, and compares the elements as stacks.
The rewrite now writes the stack itself. It also replaces the **cell object** rather than clearing
and refilling it, because Forestry shares cell objects between recipes (the four chipsets share their
redstone cells): an in-place edit changes every recipe using that cell, which is exactly what a first
attempt did - the chipsets rewrite dropped from four recipes to one, and the bronze crate then picked
up the *plate* the chipset rewrite had written into the shared cell. With the cell replaced, the log
is back to `5 recipes rewritten - 4 chipsets (GT plate + steel screw) and 1 scented paneling`.

### Verification

The audit re-run after the fixes: no `CELL-BAD` line (every Carpenter cell holds an `ItemStack`), the
seven retired-output flags turned into the *intended* GregTech-output rows, the AE2 section
unchanged. Final run with the probe removed: 47 mods, `Done`, zero `crafttweaker.log` errors, zero
`Invalid amount of recipe inputs`, zero `duplicate or conflict`, the baseline two + two, seven
grinding-ball recipes, and the guard / re-point counts unchanged.

## 6br. The rest of Forestry's factory, and one free-lava leak - 2026-10-13

6bq left the remaining Forestry machines unread - the dump had them, but nobody had gone through them.
This round does, per recipe, and also settles the one "machine" in another mod that no audit had
looked at: Storage Drawers' compacting drawer.

### The recipes, one by one

* **Squeezer, 23 recipes.** Fruit into juice and seed oil (six fruit types, apple, carrot), honey drops
  and honeydew into Forestry's honey, snowballs plus ice shards into ice, phosphor into lava, mulch
  into biomass, cactus into water, and one bee-comb row that feeds GregTech's oil. Everything but the
  lava is Forestry's own chain and needs no change.
* **Fermenter, 25 recipes.** Mushrooms, saplings, honeydew and the fluid combinations (water, juice,
  honey) into Forestry's biomass. Forestry's own chain; the pack keeps it - GT's own biomass line
  exists and this is the equivalent.
* **Moistener, 4 recipes.** Seeds into mycelium, stone bricks into mossy stone bricks, leaves into
  podzol, cobblestone into mossy cobblestone. Decorative vanilla behaviour, nothing to audit.
* **Still, 1 recipe.** Biomass into Forestry's ethanol. The fuel value is the same chain GT ships.
* **Centrifuge, 25 recipes.** Already reported in 6bq: Gregicality's combs into GregTech dusts and
  items, plus Forestry's own comb/propolis/honeydew separation.

### The leak: the Squeezer's lava

Four recipes - two phosphor plus one sand, dirt or cobblestone - produce **1,600 to 2,000 mB of lava**
each. No GregTech route makes lava that cheap and lava is a GregTech fuel, so the pair is free EU
with extra steps: GregTech's own phosphor ore (or the apatite chain) supplies the phosphor and a
lava-fired GT generator turns the result into power. That is the line 6m draws for RF, applied to
lava: the pack may *spend* power on a mod's machines, it may not *make* power out of one.

`MinespaceForestryCarpenter.removeLavaSqueezing` removes exactly the recipes whose fluid output is
lava, through Forestry's own `RecipeManagers.squeezerManager.removeRecipe`. Measured on the next run:
`forestry squeezer (loadComplete pass): 4 lava recipes removed`. Everything else the Squeezer does
stays, which is the point - the machine keeps its place in the pack's food, honey and mulch chains.

### Storage Drawers' compacting drawer: already covered

The compacting drawer offers a 9-into-1 and 1-into-9 conversion for anything it holds, with no power,
which would be a free compressor. It is not one, and the reason is worth writing down: the drawer does
not keep its own table of conversions. `CompactingHelper` builds its candidates by walking
**`CraftingManager`'s recipe registry** (`findAllMatchingRecipes` -> `CraftingManager.field_193380_a`)
and matching a synthetic grid, so when `MinespaceCraftingBlocks.removeCraftingTableCompression`
replaces the "nine ingots into a block" recipes with a `DummyRecipe`, the drawer loses the conversion
with them. The GT materials this pack cares about therefore have no drawer compaction, and the mod's
own `mods.storagedrawers.compaction.add/remove` CraftTweaker hooks remain available if a future case
needs one.

### Verification

Final run: 47 mods, `Done (5.417s)`, zero `crafttweaker.log` errors, zero
`Invalid amount of recipe inputs`, zero `duplicate or conflict`, the baseline two + two, seven
grinding-ball recipes, the squeezer's four removals, and no new crash reports.

## 6bs. The reconciliation pass, part 1: Iron Chests and Storage Drawers - 2026-10-13

Every audit up to 6br asked one question - *is there a bypass, or an item nobody can make any more* -
and answered it from the finished registries. This pass asks the mirror question, which none of those
audits can see: **did the rewrite lose an ingredient, or make something cheaper than it used to be?**
A ring that quietly dropped two plates from eight still loads, still shows in JEI and still logs
nothing, so the only way to answer it is to compare against a baseline. That is what "reconcile"
means here, and it is now the plan's first item.

### Three references, and which one is the baseline

`Mods-Get-Gregged-master` holds three rewrites of the same mods, and they disagree with each other:

| reference | Iron Chests style | upgrades |
| --- | --- | --- |
| `GT5-scripts\Iron-Chests\IronChests.zs` (Retep998, 2017) | eight plates around the centre, chained copper -> iron -> silver -> gold -> diamond -> crystal / obsidian | **deleted, not rebuilt** |
| `GT5-scripts\Iron-Chests\IronChests-alt.zs` (SteamT) | the same rings plus a second "plate + glass" route per tier | rebuilt as rings |
| `Custom-Modpack-Scripts\GTNewHorizons\scripts\Iron-Chests.zs` | 4 double plates + 2 screws + hammer + screwdriver, plus an assembler alternative | deleted |
| `Custom-Modpack-Scripts\Grind-Complex\scripts\Iron-Chests.zs` | 4 rods + 4 plates per ring | rebuilt with rods |

So "the reference" is not one thing, and none of the three can be the baseline on its own: GTNH's
script is for 1.7.10 items this pack does not have (`IItemStack`-typed Forestry variants, Project Red
gates, Carpenter's Blocks), and its Iron Chests upgrades are simply gone, so it cannot say what an
upgrade should cost. The baseline this pass uses instead is **each mod's own shipped recipe**, which
is the only statement of "what this item used to cost" that is true for this pack's version of the
mod - read straight out of the jar rather than remembered:

* `ironchest-1.12.2-7.0.72.847.jar` - 209 recipe JSONs under `assets/ironchest/recipes/`, a
  `forge:ore_shaped` per chest, per upgrade and per colour;
* `StorageDrawers-1.12.2-5.5.3.jar` - JSON for the machines, keys and upgrades, and **the drawer
  family in code**: `core/ModBlocks$Registration` builds one `TemplateRecipe` per shape from the
  literal rows `"xxx"` / `" y "` / `"xxx"` (the 1x1 drawer), `"xyx"` / `"xxx"` / `"xyx"` (1x2) and
  `"yxy"` / `"xxx"` / `"yxy"` (2x2), with `x` the wood and `y` the chest, plus `"xyx"` / `"yyy"` /
  `"xyx"` for the trim. That is where the eight-item rings come from.

The bar is then "**the mod's own count, with a GregTech ingredient in place of the plain one, never
fewer items**". Two things about a GT ingredient make that a real constraint rather than a slogan:
a plate is one ingot, but a **screw is an eighth of one** (`extruder: 1 iron ingot -> 8 bolts`;
`lathe: 1 bolt -> 1 screw`, both in the recipe-map dump), so "plate -> screw" reads as a small
substitution and costs 87% less; and a GT wood plate needs a cutting machine, so the wooden families
get harder without changing their counts at all.

### Iron Chests, line by line

The mod's own recipes are two-route per tier (a plain "eight ingots around a chest" and a cheaper
"four of the new metal plus four glass around the tier below"); the reference keeps one route and
chains the tiers. Ours does the same, and the numbers below are what a probe read out of the
finished registry, not what the script says:

| item | the mod's own recipe | ours now | verdict |
| --- | --- | --- | --- |
| Dirt Chest (`:7`) | 8 dirt + chest | 8 dirt + chest, shaped | unchanged |
| Copper (`:3`) | 8 copper ingot + chest | 8 GT copper plate + chest, shaped | one ingot each, off a bender |
| Iron (`:0`) | 8 iron ingot + chest, or 4 iron + 4 glass + copper chest | 8 GT iron plate + copper chest, shaped | the GT5 route, GT plates |
| Silver (`:4`) | 8 silver ingot + copper chest, or 4 silver + 4 glass + iron chest | 8 GT silver plate + iron chest, **assembler LV** | one ingot each, plus the machine |
| Gold (`:1`) | 8 gold ingot + iron chest, or 4 gold + 4 glass + silver chest | 8 GT gold plate + silver chest, **assembler LV** | ditto |
| Diamond (`:2`) | 2 diamond + 6 glass + gold chest, or 3 diamond + 5 glass + silver chest | 8 GT diamond plate + gold chest, **assembler MV** | *dearer* than the mod (8 diamonds against 2-3) |
| Crystal (`:5`) | 8 glass + diamond chest | 8 GT glass plate + diamond chest, **assembler HV** | glass has to be cut and rolled |
| Obsidian (`:6`) | 8 obsidian + diamond chest | 8 obsidian + diamond chest, **assembler HV** | the mod's own grid, unchanged |

The Obsidian tier is the one place a GT5-style recipe could not be written: **GregTech has no
obsidian plate in this stack** - the ore dictionary dump lists `dustObsidian`, `dustTinyObsidian`,
`dustSmallObsidian` and the compressed block, and no `plateObsidian` - so the reference's
`<ore:plateObsidian>` has no item behind it here. The mod's own eight blocks stay, which is honest
rather than a downgrade, and the tier is still gated behind the HV assembler step.

The nine chest upgrades keep the mod's grids exactly, and three stay on the crafting table because
they only reach the copper or iron chest (`wood_copper`, `wood_iron`, `copper_iron` - the last one
is the mod's own 4 iron + 4 glass + 1 copper). The other six are assembled at the tier they lead to.
The sixteen coloured shulker boxes run the same seven tiers from the same eleven grids (16 x 11
recipes and 16 x 9 upgrades), the entry tiers shaped and the upper five assembled at the matching
chest's voltage, so a shulker box is never a way around the assembler step its chest has.

### The finding: two upgrades lost half their metal

`copper_silver` and `iron_gold` - in both families, so four recipes - were written as **four plates
and four screws** where the mod's own recipe is a ring of **eight** of the target metal. With a
screw worth an eighth of an ingot that is 4.5 ingots against 8: a 44% discount on exactly the two
upgrades whose whole point is that you pay the next tier's metal. This is the failure mode the pass
exists for, and it is the one the v2 comment could not catch because the script's own comment said
"the screw pair on the outer edge is the GregTech screw of the same metal" and there is no screw in
the mod's grid.

Fixed to the mod's ring with GT plates - `copper_silver` = 8 silver plate + 1 copper plate,
`iron_gold` = 8 gold plate + 1 iron plate, in `assembler_1.zs` for the chests and again for the
shulkers, with the counts verified in the dump below.

`IronChest-Minecarts` (the reference's second Iron Chests folder) is **not applicable**: the
minecart variant is a separate 1.7.10 mod and is not installed here, so its eight removed recipes
have nothing to audit.

### Storage Drawers, line by line

| item | the mod's own recipe | ours now |
| --- | --- | --- |
| 1x1 drawer (`basicdrawers:0`) | 8 wood + 1 chest | **8 GT wood plate + 1 chest**, shaped |
| 1x2 full (`:1`) x2 | 7 wood + 2 chests | 7 GT wood plate + 2 chests |
| 2x2 full (`:2`) x4 | 5 wood + 4 chests | 5 GT wood plate + 4 chests |
| half 1x2 (`:3`) x2 / half 2x2 (`:4`) x4 | 7 slabs + 2 chests / 5 slabs + 4 chests | unchanged |
| trim (`trim:0..5`) x4 | 4 sticks + 5 wood | 4 sticks + 5 GT wood plate |
| framed drawers (`customdrawers:0..4`) | 8 sticks + chest; 6 sticks + 2 chests + 1 plank; 4 chests + 4 sticks + 1 plank; the two slab variants | same, wood plate where the mod has a plank, **8 sticks** on the 1x1 |
| framed trim (`customtrim`) x4 | 4 sticks + 5 planks | 4 sticks + 5 GT wood plate |
| upgrade template x2 | 8 sticks + 1 basic drawer | unchanged |
| storage upgrade, obsidian | 8 sticks + 2 obsidian | 6 GT iron screws (0.75 ingot) + 2 obsidian + template, shaped |
| storage upgrades, iron / gold / diamond / emerald | 8 sticks + 2 of the metal | 4 screws + 2 GT plates + template, **assembler** LV / LV / MV / MV |
| compacting drawer | 5 stone + basic drawer + 2 pistons + 1 iron ingot | 5 smooth stone + basic drawer + 2 pistons + 1 **GT iron plate** + **LV circuit**, assembler LV |
| controller / slave | 5 stone + 2 comparators + basic drawer + 1 diamond / gold ingot | 5 smooth stone + 2 comparators + **basic drawer** + **LV circuit** + GT diamond / gold plate, assembler LV |
| framing table | 7 drawer trims | 7 trims + 1 **GT steel screw**, assembler LV |
| void / conversion / status x2 / redstone x3 / key | the mod's JSON grids | unchanged, or with a GT plate where the mod had an ingot |

Three of those rows are also findings, all the same shape as the Iron Chests one - a ring that had
lost items, or an ingredient that had quietly replaced another:

* the **1x1 drawer** was `[null, chest, null]` in the middle row, so 6 wood plates where the mod's
  `TemplateRecipe` says `"xxx" / " y " / "xxx"` = 8, and the **framed 1x1** was 6 sticks against the
  mod's 8. Both are 8 now;
* the **controller and its slave** had the LV circuit *in place of* the basic drawer the mod puts in
  their centre, so the drawer had dropped out of the cost; the drawer is back and the circuit is an
  addition (which is also what this file's own header describes - "put an LV integrated circuit into
  machines that process items");
* the **compacting drawer, controller and slave** asked for **7** smooth stone where the mod's rows
  (`"###"` / `"TXT"` / `"#I#"`) contain 5, and the **framing table** asked for 6 trims where the mod's
  `"XXX"` / `"X X"` contains 7. Both are the mod's count now.

Everything in the Storage Drawers table is either the mod's own count with a GT ingredient, or
**higher**: the storage upgrades trade eight near-free sticks for three-quarters of an iron ingot
(2.5 ingots of metal against the mod's 2), and the framed 2x2 drawers take two wood plates where the
mod takes one. Nothing is cheaper.

### The two deviations that are deliberate

* **The assembler gate itself.** Everything from the silver chest up, the four drawer machines and
  the 2x and above storage upgrades need a GregTech assembler, which the mod's recipes did not. That
  is the owner's own rule ("an advanced item must be produced by a GregTech machine") and it is
  strictly harder.
* **The Iron Chests upgrades exist at all.** The GT5 reference deletes the nine upgrade items,
  because its chest recipes upgrade the tiers directly. This pack keeps them so the mod's own upgrade
  slot still works, which is why they had to be costed from the mod's grid rather than from the
  reference's silence.

### Verification

A temporary probe (`MinespaceReconcileProbe`, deleted again) dumped, at load complete, **every
crafting-table recipe and every GregTech map recipe whose output belongs to one of the five rewritten
mods, with the count on every input**, into `reconcile_dump.txt`: ironchest 57 crafted + 145 machine
recipes, storagedrawers 36 + 8, forestry 490 + 61, enderio 1587 + 147, appliedenergistics2 206 + 111.
The lines for the fixed recipes, as printed:

```
MAP assembler OUT ironchest:copper_silver_chest_upgrade:0 <- IN gregtech:meta_item_1:12062 x8 , 12018 x1
MAP assembler OUT ironchest:iron_gold_chest_upgrade:0    <- IN gregtech:meta_item_1:12026 x8 , 12033 x1
MAP assembler OUT ironchest:copper_silver_shulker_upgrade:0 <- IN gregtech:meta_item_1:12062 x8 , 12018 x1
MAP assembler OUT ironchest:iron_gold_shulker_upgrade:0     <- IN gregtech:meta_item_1:12026 x8 , 12033 x1
CRAFT OUT storagedrawers:basicdrawers:0 <- 12196 x8 , minecraft:chest
CRAFT OUT storagedrawers:customdrawers:0 <- minecraft:stick x8 , minecraft:chest
MAP assembler OUT storagedrawers:compdrawers:0   <- IN minecraft:stone x5 , piston x2 , basicdrawer , 12033 , 32487
MAP assembler OUT storagedrawers:controller:0    <- IN minecraft:stone x5 , comparator x2 , basicdrawer , 32487 , 12111
MAP assembler OUT storagedrawers:controllerslave:0 <- IN minecraft:stone x5 , comparator x2 , basicdrawer , 32487 , 12026
MAP assembler OUT storagedrawers:framingtable:0  <- IN drawerTrim x7 , 17184
```

The probe was then deleted, the jar rebuilt, and the clean server run reproduced the baseline
exactly: **47 mods**, `Done (4.524s)`, zero `crafttweaker.log` errors, zero `Invalid amount of recipe
inputs`, zero `duplicate or conflict`, the baseline two + two, seven grinding-ball recipes, and no new
crash reports. The comment corrections went into `scripts/integration.zs` (the drawer rings and the
upgrade note) and `scripts/assembler_1.zs` (the four Iron Chests upgrades and the four drawer
machines), each saying what the mod's own count is and why a screw must not be used to make it.

## 6bt. The reconciliation pass, part 2: Forestry - 2026-10-13

### A second baseline, because the first probe cannot see the mod's recipes

The Iron Chests and Storage Drawers half of 6bs could use the mods' own recipe files, because both
register their crafting recipes from JSON. Forestry does not: 1.12.2 Forestry builds every recipe in
code, inside its module classes (`ModuleFactory`, `ModuleCore`, `ModuleApiculture`, ...), so there is
nothing to read out of the jar without decompiling. The other half of the problem is that a
load-complete dump cannot see the mod's recipes either - by then CraftTweaker has already deleted
them - and this is the state every audit since 6a has read.

The fix is a probe at the right moment. Forge's `Register<IRecipe>` event runs **between preInit and
init**, and CraftTweaker applies its scripts in postInit, so a dump taken in this mod's own `init`
sees the finished mod recipe set *before* anything of ours has touched it. `MinespacePreCtProbe`
(temporary, deleted again) wrote the whole crafting registry at both points -
`init_all.txt` (19,369 recipes) and `final_all.txt` (19,232) - and the five rewritten namespaces were
diffed out of the pair: 1,312 of the init recipes belong to them, against 1,871 at load complete.

The comparison itself is item by item, on three axes: the **route count** (how many recipes make the
item), the **ingredient multiset with counts**, and the **output count**. The first two caught
nothing in Forestry beyond the intended GregTech substitutions; the third caught a large one.

### The finding: every wooden recipe lost its output count

`scripts/forestry_wood.zs` is generated. Its header says "keep the recipe and the output ... no count
is lowered", and it generated 315 shaped recipes that add a GregTech saw to a slot the pattern
already leaves empty. Every one of those 315 lines was written as `recipes.addShaped(<output>, [...])`
with **no multiplier**, so the table made:

| family | the mod's own recipe | what the pack actually shipped | now |
| --- | --- | --- | --- |
| planks (1 log) | 4 planks | **1 plank** | 4 |
| slabs (3 planks) | 6 slabs | **1 slab** | 6 |
| stairs (6 planks) | 4 stairs | **1 stair** | 4 |
| fences (4 planks + 2 sticks) | 3 fences | **1 fence** | 3 |
| doors (6 planks) | 3 doors | **1 door** | 3 |

126 recipes were down by 4x or more, 120 fences and doors by 3x, 63 slabs by 6x - a quarter of a
tree per plank. Nothing in the pack's logs says a word about it: the recipes load, they show in JEI,
and JEI is showing a cycle the player would never use. What settles the intent is **this pack's own
vanilla wood**: GregTech's hard-wood pass rewrites `minecraft:planks:0` and leaves the count alone -

```
PRE OUT minecraft:planks:0 x4 <- gregtech:meta_tool:5 (saw) , minecraft:log:0
```

- so the saw is the gregging and the yield is the mod's. The numbers are now the mod's own, read back
out of `init_all.txt`; the distribution after the fix is identical to the one before CraftTweaker ran
(120 recipes at 3, 126 at 4, 63 at 6).

### The second finding: the six vanilla doors lost their plain route

`recipes.remove(<minecraft:wooden_door:0>)` removes **every** recipe for that output. Forestry ships
two kinds of door recipe - vanilla's own, six planks straight into three doors, and a fireproof one
out of Forestry's fireproof planks - and the generator wrote back only the fireproof form. The plain
route was therefore gone: an oak door could only be made by fireproofing six oak planks first. The six
vanilla doors are restored at the end of the file exactly as vanilla had them, next to the fireproof
recipes, and the probe confirms two routes each in the finished registry.

### Everything else in Forestry, screened and accounted for

* **The 341 items whose ingredients changed are all substitutions, not discounts.** Every one is a
  plain material becoming its GregTech form - `minecraft:planks` -> GT wood plate (apiary), glass ->
  GT glass plate (arboretum and the five other farm blocks), bronze ingot -> GT bronze plate
  (`sturdy_machine`, the naturalist helmet), gold ingot -> GT gold plate (the 100n stamp) - plus the
  GregTech tool the pattern needed. `sturdy_machine` also gains the LV circuit, so the mod's eight
  bronze ingots become eight bronze plates *and* a circuit.
* **40 Forestry outputs lost their crafting recipe on purpose**, and each has a replacement:
  25 are the machines and alveary parts, all of which have an assembler recipe in the finished
  registry (`carpenter`, `centrifuge`, `squeezer`, `fermenter`, `moistener`, `still`, `bottler`,
  `fabricator`, `raintank`, `analyzer`, `rainmaker`, `database`, `habitat_former`, `peat_bog`,
  `trade_station`, the three engines, the seven alveary parts); the rest are the mod's own copper /
  tin / bronze ingots and gears (`ingotCopper` and friends belong to GregTech now, 6bl / 6bk) and the
  bronze pickaxe / shovel / kit / wrench, which the reference pack removes for the same reason - the
  ore names still answer with GregTech's items, so every recipe written against them keeps working.
  `database`'s twelve recipes were the three chest variants times two reagents times two grid
  orders, and its six are the deduplicated set `MinespaceRecipeDedupe` is for (6av).
* **Five conversion routes went with them**, and they are worth naming because they are the only
  drops that are not substitutions: the "unbuild the machine part" recipes that turned a climate
  control / greenhouse part back into two electron tubes (`thermionic_tubes:1/4/7/11`), and the
  manual <-> managed flips for the six farm blocks and the peat bog. `MinespaceCraftingBlocks`'
  "if a machine makes it, the table must not" rule removes them because the item they produce has a
  machine route; none of them is a source of power, a material or a shortcut - they only recycle an
  already-built part - and the reverse direction of each flip survives. Recorded rather than
  restored.

### Verification

The two dumps and the fixed wood counts are in the log archive; the fix is `scripts/forestry_wood.zs`
(315 lines given their output counts, the six doors appended, header rewritten with the finding).
The probe was then deleted, the jar rebuilt, and the clean run reproduced the baseline: **47 mods**,
`Done (3.832s)`, zero `crafttweaker.log` errors, zero `Invalid amount of recipe inputs`, zero
`duplicate or conflict`, the baseline two + two, seven grinding-ball recipes, no new crash reports -
and the registry grew by exactly six recipes, the restored door routes.

### What is still queued

**Ender IO** (1,587 crafted + 147 machine) and **Applied Energistics 2** (206 + 111). Both already
have their references: AE2 registers its crafting recipes from JSON, so it appears in
`init_all.txt`; Ender IO registers its XML recipes *after* CraftTweaker runs, so its own set is read
from `assets/enderio/config/recipes/*.xml` inside the jar instead (the same files
`config/enderio/recipes/user/user_recipes.xml` switches off by name). Then the items the reference
pack covers that these namespaces do not reach: `Iron-Chests-Minecarts` is not installed, and
`Storage-Drawers`' per-wood loops do not apply to the 1.12.2 mod, whose wood variants are NBT rather
than separate items.

## 6bu. The reconciliation pass, part 3: Ender IO and Applied Energistics - 2026-10-13

### Two different baselines again

Both mods were checked with the same four screens - route counts, output counts, ingredient
multisets, and "does every removed recipe have a replacement" - but they had to be fed from
different places.

**Applied Energistics** registers its crafting recipes from JSON, so the `init_all.txt` dump from 6bt
is already its own set: 287 outputs before CraftTweaker ran, 179 after.

**Ender IO** does not: its recipes are XML in the jar (`assets/enderio/config/recipes/*.xml`) and it
loads them *after* CraftTweaker has applied its scripts, which is why the `init` dump holds only its
84 code-registered recipes while the finished registry holds 1,587. Its own set therefore comes
straight out of the jar's XML - the same files `config/enderio/recipes/user/user_recipes.xml`
switches entries off by name - parsed into 945 `enderio:` crafting outputs with their `amount` and
ingredients.

### The screens, and what they cleared

* **Output amounts.** For every EIO output the XML declares, the finished registry has an amount the
  XML declares; for every AE2 output that kept a recipe, the amount is the one it started with. The
  Forestry failure mode of 6bt - a rewrite that drops the multiplier - has no other instance in
  either mod, with the one exception below.
* **Routes.** No AE2 output that kept a crafting recipe lost one of its routes. AE2 has 108 outputs
  whose crafting recipe is gone, and **107 of them have a GregTech machine recipe**; the 108th is
  `appliedenergistics2:material:40`, AE2's wooden gear, which this pack retires on purpose - `gearWood`
  belongs to GregTech now (6bk), the item is hidden (`jei_dupes.zs`), and the hand grindstone's
  recipe makes GregTech's gear. Ender IO has 119 XML outputs with no crafting recipe left: 50 have a
  machine recipe (the machine blocks, the third capacitor tier and the dark-steel upgrade, all moved
  to the assembler in 6h / 6k / 6ak), and the other 68 are accounted for one by one below.
* **Ingredients.** 45 AE2 outputs have a changed ingredient signature and every single change is an
  *addition* - a GregTech tool (saw, file, wire cutter) in a slot the pattern already leaves empty, or
  a vanilla iron ingot become a GregTech iron plate/ingot. Nothing lost an ingredient, and no EIO
  crafting recipe at all takes a GregTech screw or bolt, which is where the 6bs downgrade would have
  shown up if it had been repeated here.
* **The machine side.** Every AE2 and EIO item that moved from the crafting table into a machine keeps
  the output amount its own recipe had - checked the other way round, machine amount against mod
  amount. That is where `block_omni_reservoir x4` coming out of the assembler comes from: EIO's own
  XML says `amount="4"`.

### Ender IO's 68 outputs with no recipe at all

None of them is a loss:

* **8 generators** - the stirling (plain and simple), combustion (plain and enhanced), zombie,
  frankenzombie, ender and lava generators, removed because this pack makes GregTech generation the
  only route to power (6m).
* **50 alloy items** - the ten alloys' blocks and nuggets and the seven endergy alloys': ingots,
  nuggets and blocks. These are the mod's copies of materials GregTech now owns; the GT alloy smelter,
  mixer, compressor and the `MinespaceMaterialRepoint` pass that moves every recipe output onto
  GregTech's item do the work (6az, 6ba, 6bb, 6bc).
* **7 dark steel tools and armour** - helmet, chestplate, leggings, boots, sword, pickaxe, axe - the
  same seven the reference pack deletes and hides (`GT5-scripts\Ender_IO\Ender-IO.zs`), which GregTech's
  own tool sets replace.
* **2 that are the mod's own doing**, and worth writing down because they look like pack damage at
  first glance: `item_dark_steel_treetap` is declared `required="false"` and its grid names
  `ic2:treetap, ic2:itemtreetap, techreborn:treetap`, so Ender IO itself skips the recipe when none of
  those mods is installed; and `item_broken_spawner`'s only recipe lives in `broken_spawner.xml`, an
  example file Ender IO ships for the player to copy into the `user` folder - it is not active by
  default.

### The one finding: AE2's Quartz Fixture

AE2 makes **two** quartz fixtures per craft - one charged certus quartz plus one iron ingot, two out.
`ae2_base.zs` had re-costed it to a charged certus quartz plus a GregTech iron plate and re-added it
shapeless, but wrote the output with no multiplier, so it gave one. Fixed to `* 2`; everything else
about that recipe (the plate, the shapeless form) is the pack's intended GregTech re-cost and stays.

### Verification

The quartz fixture fix is the only change this part of the pass needed. The clean run after it
reproduced the baseline - 47 mods, `Done`, zero `crafttweaker.log` errors, zero `Invalid amount of
recipe inputs`, zero `duplicate or conflict`, the baseline two + two, seven grinding-ball recipes, no
new crash reports - and the load-complete dump shows `appliedenergistics2:quartz_fixture:0 x2`.

### The pass is complete for the four mods

Iron Chests, Storage Drawers, Forestry, Ender IO and Applied Energistics have now been reconciled
against their own shipped recipes: **three real defects**, all the same shape - a rewrite that lost
what the mod's own recipe carried - and all fixed:

| finding | where | what was lost |
| --- | --- | --- |
| four chest/shulker upgrades built from 4 plates + 4 screws (a screw is 1/8 of an ingot) | `integration.zs`, `assembler_1.zs` | half the metal of an eight-plate ring |
| the 1x1 drawer and framed drawer rings, the drawer machines' stone, the framing table's trims | `integration.zs`, `assembler_1.zs` | 2 plates, 2 stone, 1 trim |
| **all 315** Forestry wood recipes, and the six vanilla doors' plain route | `forestry_wood.zs` | the output count (4x / 6x / 3x) and one route |
| AE2's quartz fixture | `ae2_base.zs` | half the output (2 -> 1) |

What is left is not reconciliation but the play-test: the registry half of the §6bj checklist is
green, and the player's half - blocks mined, machines placed and run, a rocket built - is what a
play-test performs.

## 6bv. The play-test, run on the dedicated server - 2026-10-13

The §6bj checklist has two halves: the registry half (can this item be made, does any recipe bypass
GregTech) and the player's half (mine it, put the machine down, watch it work). Everything up to 6bu
is the first half. This round does the second half - as much of it as a machine can do without a
human at the keyboard, because the pack is tested by launching the dedicated server.

### The harness

`MinespacePlaytestHarness` (temporary, deleted again with its build change) registers a server-tick
handler, waits 200 ticks so the spawn chunks exist, and then:

1. **censuses the ores that actually generated** in a 5x5-chunk box around spawn, y 1..79;
2. **breaks one** and reads the drops a player would pick up;
3. **places the pack's key machines as item blocks** - the same path a player uses - and reads back
   which machine each one became;
4. **runs one machine for real**: items in, energy in, ticks, items out;
5. **asks the checklist's own recipes** whether they exist, in the machine maps and in the crafting
   registry.

It had to be compiled with Applied Energistics on the classpath (GTCE-TJ's `MetaTileEntityHolder`
and `MachineItemBlock` carry AE2 interfaces in their signatures), so the build file gained one
`compileOnly` line for the duration. Both are reverted - it is a test instrument, not part of the
pack.

### What the world actually generated

Three fresh worlds were sampled across the runs; the ore census covered 310, 1,877 and 4,852 ore
blocks in 6, 16 and 17 block types. Every one of those types is either **GregTech's own ore**
(`gregtech:ore_copper_0`, `ore_tenorite_0`, `ore_malachite_0`, `ore_lepidolite_0`, `ore_gypsum_0`,
`ore_rock_salt_0`, ...) or **AE2's** quartz and charged quartz ore. In three worlds and ~7,000 ore
blocks there is **not one Galacticraft, Galaxy Space or Forestry ore block** - which is the whole
point of 6bl / 6bn, and until now it had only been verified in the vein configuration rather than in
a generated world.

An ore block's drops are its own item (`gregtech:ore_rock_salt_0:0 x1`), which is GregTech's design:
ore blocks are the item you macerate, not the finished material.

### Placing, and running

Fifteen machines were placed as items and read back: the eight steam machines (macerator /
compressor / furnace / alloy smelter, bronze and steel), the electric furnace at LV, MV, HV and EV,
and the macerator at LV, MV and HV. Every one came back as **exactly the machine it was placed as**,
which is the placement path (`MachineItemBlock.placeBlockAt` -> `MetaTileEntityHolder`), and covers
the "put the machine down" step for the pack's two entry tiers.

Then one of them was run. An **LV macerator** was placed in the generated world, given a GregTech
copper ore block, kept topped up on energy (its container reports 1,024 EU, the LV tier) and ticked:

```
recipe: gregtech:meta_item_1:5018 x2  chance[...@14%] chance[...@67%]  (400 ticks, 12 EU/t)
after 900 ticks, inventory:
  slot 1: gregtech:meta_item_1:5018 x2          <- crushed copper
```

A second machine in the same run took one GregTech copper **ingot** and produced
`gregtech:meta_item_1:2018 x1` (copper dust) in 30 ticks. So the chain the checklist's first rows
describe - a generated GregTech ore, a placed machine, a ticked recipe, GregTech's own output - is
verified end to end on the server, not inferred from a recipe map.

### The checklist's products, both ways

Asked of the **machine maps** (the same maps the machines run):

* copper plate - 9 recipes (fluid solidifier, the two metal benders) at 24-28 EU/t; copper dust - 68
  recipes; copper gear - the alloy smelter and extruder lanes the gear bridge restored; steel plate -
  9 recipes. The steam/ULV and LV rows are intact.
* Galacticraft's compressed iron plate - two implosion-compressor entries plus the electric
  implosion; Mars Heavy-Duty Plate and Galaxy Space's Modern Wafer - assembler recipes.
* AE2's 1k storage component - assembler, from `meta_item_2:16071 x4` (GregTech screws, the re-point
  from 6y) plus two certus crystals.
* AE2's logic processor - **no** GregTech machine recipe, which is correct: the Inscriber makes it
  (13 recipes, audited in 6bq).

Asked of the **crafting registry** (where machine blocks and circuits live):

* `circuitBasic` and the bare LV circuit id - a crafting recipe, from GT's own parts.
* the Electric Blast Furnace, Vacuum Freezer and Implosion Compressor controllers - crafting
  recipes (plus Gregicality's conversion recipes from the legacy `machine:511..513`).
* the ULV and LV **FE-to-EU converters** - crafting recipes, as they must be; the **EV and IV ones -
  none**, which is 6m's power ceiling verified in a world rather than in a probe.
* Ender IO's simple machine chassis and Forestry's sturdy casing - crafting recipes with GregTech
  steel plates and bronze plates.

### What a human still has to do

The harness is not a play-through, and the gap is worth stating plainly: it cannot open a GUI, feed a
multiblock (no heat, no structure), ride a rocket, breed a bee or watch a tree grow, and it cannot
see a mod's own machine internals beyond the API audits already recorded in 6bq and 6br. What it does
prove is that the pack's own chain works on a live server: ores generate as GregTech's, machines
place and tick, recipes run and return GregTech's items, the tiers' controllers and converters exist
exactly where the design says they should, and nothing that should be gone is there.

### Verification

The harness and the build-file line were removed, the jar rebuilt, and the clean run reproduced the
baseline: **47 mods**, `Done (4.105s)`, zero `crafttweaker.log` errors, zero `Invalid amount of
recipe inputs`, zero `duplicate or conflict`, the baseline two + two, seven grinding-ball recipes, no
new crash reports, and no report file left in the instance.

## 6bw. Galacticraft's recipes again: unmerged assembler inputs, three swallowed lines, and the Orion Drive - 2026-10-13

The owner reported two things: some Galacticraft high-tech items are still made far too cheaply or
from unreasonable materials, and some assembler recipes list the same item several times instead of
one stack. Both turned out to be mechanical, and a third problem turned up next to them.

### Unmerged assembler inputs: 14 recipes

A machine has no slots, so a recipe that needs eight of an item is one input stack of eight, not eight
inputs of one. The earlier "flatten the crafting grid into an input list" passes folded repeated
slots - `hightech.zs` says so in its own header - but three files did not: `assembler_2.zs` (8
recipes), `eio_upgrades.zs` (4) and `integration.zs` (1). They are all folded now. The GC/GS ones are
the visible ones:

| recipe | before | now |
| --- | --- | --- |
| beam reflector | 4 separate asteroid plates | one stack of 4 |
| rocket engine | 4 separate heavy-duty plates | one stack of 4 |
| dish base | 3 + 2 of two items in 7 inputs | 4 inputs |
| frequency module (`basic_item:19`) | 7 inputs, two of them repeated | 5 inputs |
| battery | 5 separate aluminium plates | one stack of 5 |
| heavy nose cone | 3 separate asteroid plates | one stack of 3 |
| EIO redstone alloy (mixer) | copper listed twice | one stack of 2 |
| EIO anvil II / III / step-assist upgrades | nuggets, ingots, sticks and bricks repeated | one stack each |

The beam reflector and the rocket engine also had **two whole recipes each** - the mod registers the
grid and its mirror image, and both had been written out. `MinespaceRecipeDedupe` already collapses
them at load complete (that class's own javadoc names these two items), but the script was still
writing two, so one of each is gone.

### Three statements that a comment had swallowed

Three lines in the scripts had been written as `...text.recipes.addX(...)` or `...text.recipes.remove(...)`
with no newline between the comment and the statement, so the statement was part of the comment and
never ran:

* `ae2_base.zs` - **a lost recipe**: AE2's semi-dark monitor keeps a 1:1 "turn a panel into the
  monitor" recipe next to its three-per-craft grid. The `recipes.remove` above it removed both, and
  the line that put the 1:1 one back was commented out, so it was gone. The CraftTweaker log says it
  is back: the run has **17** shapeless adds where it had 16, and the new one is `Illuminated Panel`
  (`part:180`, AE2's display name for the semi-dark monitor).
* `assembler_1.zs` - the `recipes.remove` for AE2's `material:26` (a level emitter) never ran.
* `assembler_2.zs` - the `recipes.remove` for Galacticraft-Planets' `mars_machine:4` never ran.
  Both items are machine-made now, so the leftover crafting recipes were only kept out of the game by
  `MinespaceCraftingBlocks`' late pass; the scripts say what they meant again.

### The Orion Drive: nine ores in a grid for a nuclear-pulse propulsion unit

This is the item the owner meant by "too simple, and the recipe makes no sense". It is the mod's own
crafting recipe, and nothing in this pack had touched it:

```
galacticraftplanets:orion_drive <- diamond ore, lapis ore, gold ore, redstone ore, coal ore,
                                   a block of moon rock, desh ore, ilmenite ore, asteroid plating
```

Nine things you dig up, in a 3x3 grid, for the propulsion unit of the end-game rockets. It is an
**HV assembler** recipe now (800 ticks, 480 EU/t) whose every ingredient is the material that comes
*out* of those ores, off a GregTech machine:

| input | what it replaces |
| --- | --- |
| Uranium-235 dust x2 | the pulse units - the thing an Orion drive actually burns |
| dense steel plate | the pusher plate |
| titanium plate | the structural plate |
| desh plate | the mod's desh ore |
| ilmenite dust | the mod's ilmenite ore |
| diamond plate | the diamond ore |
| asteroid plating, moon block | the mod's own two items, kept so the mod's chain still matters |

The lapis and coal the grid used as filler are gone: the integrated circuit (`.circuit(1)`) and the
HV gate replace them, and every replacement is a plate or a dust a machine has to make first. The
rest of the Galacticraft and Galaxy Space list was checked the same way and only this one recipe still
took raw ores - the machines had already been moved by `hightech.zs`, and what is still on the table
is building blocks and decoration by design (that file's header lists them).

### Verification

A temporary probe (`MinespaceOrionProbe`, deleted again with its call) read the finished registries:
**no crafting-table recipe** is left for any of the ten items this pass touched (the Orion Drive, the
beam reflector, the nose cone, the engine, the dish base, the frequency module, the battery, the Mars
machine, AE2's `material:26`), and each one has exactly one machine recipe with its inputs folded -
for example

```
MAP assembler -> galacticraftplanets:orion_drive:0 x1
    <- gregtech:meta_item_1:2076 (U-235) x2, asteroids:8, basic_block_moon:2,
       plateDenseSteel, plateTitanium, plateDesh, dustIlmenite, plateDiamond   (800t, 480EU/t)
MAP assembler -> galacticraftcore:engine:0 x1
    <- heavy_plating x4, stone_button, flint_and_steel, canister, air_vent     (400t, 30EU/t)
```

One mishap worth recording: the first attempt at folding the inputs was a PowerShell script that
builds the replacement argument list in a sub-expression, and PowerShell refused the expression -
which left `.inputs()` empty in all fourteen places. The lines were rebuilt from the original text
and from the mods' own recipe files (the four Ender IO upgrades from `darksteel_upgrades.xml`), and
the probe above is what confirms they are right. A recipe list longer than nine inputs is rejected by
GregTech with `Invalid amount of recipe inputs`, so that count being **0** is also a check that every
folded list still fits.

The probe was then removed, the jar rebuilt, and the clean run reproduced the baseline: **47 mods**,
`Done (5.802s)`, zero `crafttweaker.log` errors, zero `Invalid amount of recipe inputs`, zero
`duplicate or conflict`, the baseline two + two, seven grinding-ball recipes, **17** shapeless adds
(the restored panel recipe), and no new crash reports.

## 6bx. A standing guard for unfolded recipe inputs, and the one it found - 2026-10-13

6bw fixed fourteen recipes whose assembler input lists repeated an item instead of folding it into one
stack, and the owner asked for that to be a permanent check rather than a one-off sweep. It is now
`MinespaceRecipeHygiene`, called from `Minespace.loadComplete()` on every start.

### What it checks, and what it deliberately does not

Every GregTech recipe map is walked (70,210 recipes in 73 maps on this pack) and each recipe's item
inputs are compared pairwise. Two things are reported:

* **a mergeable exact duplicate** - the same ingredient more than once, where the counts add up to a
  single stack of at most 64, so it could have been written as one entry;
* **overlapping inputs** - two entries that can both accept the same item, e.g. a bare ore dictionary
  name next to a colour of it. There were two of these in the first run and both were real.

Two things are counted but *not* reported, and the reason matters:

* duplicates whose counts add up to **more than 64**. GregTech's own recipes are full of `x64` twice -
  that is a real 128 items over two slots and could not be folded into one;
* the **Assembly Line**. Its inputs are slots fed from separate buses, GregTech writes its recipes one
  entry per slot there, and this pack never authors that map. Folding one of its 383 duplicates would
  be rewriting Gregicality's content, not ours.

The check never rewrites a recipe - folding counts silently would change what the pack ships without
anyone reading it. When it has something to say it logs the counts, a per-map histogram and the first
25 offenders, and writes the complete list to `recipe_hygiene.txt`.

### What the first run found

The naive first version reported **465 exact duplicates and 2 overlapping pairs**, and reading it was
the point:

* the 465 were dominated by the two expected families above - the Assembly Line's slot-ordered
  recipes and GregTech's 128-item stacks - which is what led to the two exclusions;
* the **2 overlaps were ours**: Ender IO's Advanced Power Monitor. The mod's own grid is
  `wool x5 + power monitor + dyeRed + dyeYellow + dyeGreen`, and the flattening pass had written the
  red one as the bare `<ore:dye>`, which matches *every* colour - so the recipe accepted two greens
  and a yellow, and one green dye stack could satisfy the red slot and the green slot at once. It
  asks for `<ore:dyeRed>` again (the ore name that holds the red dye items and nothing else), so the
  three slots are three different colours exactly as the mod wrote them.

### Standing state

```
recipe hygiene (loadComplete): 70210 recipes in 73 maps - 5 mergeable duplicates,
    0 overlapping pairs (460 more duplicates over the slot limit, which is how a 128-item cost is written)
  assembler: 4 mergeable, 0 overlapping
  forming_press: 1 mergeable, 0 overlapping
```

All five are **Gregicality's own recipes**, not this pack's: four `gtadditions:ga_armor` entries list
the same circuit twice, and `gtadditions:ga_multiblock_casing:13` lists nine plates twice (18 in all).
They are named in the log and in `recipe_hygiene.txt` on every start, and they are left alone - the
pack only re-costs content it takes over, and merging another mod's recipe would be re-costing it. The
line will read zero mergeable duplicates in the pack's own recipes, and any new script that leaves an
unfolded grid will name itself in this line the next time the server starts.

**Owner's decision, 2026-10-14: they stay.** Asked what the five were and whether they affect balance,
the answer is no and that is now measured rather than assumed: `Recipe.matchesItems` walks the input
list entry by entry and *deducts* what each one takes from the working copy of the container before
moving to the next, so "two entries of one" and "one entry of two" both require and consume the same
two Lapotron Crystals (and the same eighteen dense lead plates), including when the material is split
across several slots. The only difference is how many slots JEI draws - which is not worth making this
pack the author of another mod's five recipes. The interesting half of the same guard is the
*overlapping* half, where one stack can satisfy two different entries; that one was a real defect and
it is at zero.

The run after the fix reproduced the baseline: **47 mods**, `Done`, zero `crafttweaker.log` errors,
zero `Invalid amount of recipe inputs`, zero `duplicate or conflict`, the baseline two + two, seven
grinding-ball recipes, no new crash reports - and **0 overlapping pairs** where there had been 2.

## 6by. "GT has dense plates too, and GC/GS collide with them": measured - 2026-10-14

The owner's report was that GregTech's dense plates clash with Galacticraft's and Galaxy Space's
naming. A temporary probe (`MinespaceDensePlateProbe`, deleted again) dumped, at **init** (before
CraftTweaker runs) and at **load complete**:

* every ore dictionary name containing `dense` or `compress`, with **all** the items in it;
* every name that holds both a `gregtech:` item and a `galacticraft*` / `galaxyspace:` item;
* every recipe - crafting table and machine map - that eats Galaxy Space's compressed coal or
  magnesium.

### What is not a conflict

GregTech's dense plates are **not** in any shared name. There are 130-odd of them (`plateDenseSteel`
`13184`, `plateDenseTitanium` `13072`, ... `plateDenseNeutronium` `13993`), and every one holds
exactly one item, and it is always GregTech's - the same before CraftTweaker's scripts and after.
Galacticraft's and Galaxy Space's compressed plates are registered by the mods under their own
`compressedX` names (`compressedCopper`, `compressedSteel`, `compressedDesh`, `compressedTitanium`,
...) and nowhere else, so `<ore:plateDenseX>` and `<ore:compressedX>` are two separate worlds and a
recipe cannot reach the wrong one.

The names that *do* hold both sides today are eleven, and reading them is the point:

| name | the GC/GS member | why it stays |
| --- | --- | --- |
| `oreIron`, `oreGold`, `oreCoal`, `oreDiamond`, `oreLapis`, `oreRedstone`, `oreEmerald`, `oreLead`, `oreSolar` | Galaxy Space's planet ores (Mars / Titan / Proxima B / Barnarda C / Enceladus / Europa / Mercury / Phobos / Miranda) and GC-Planets' Mars, Venus and asteroid ores | they are the *same tier* as GregTech's ore block (an iron ore block is an iron ore block), they generate on their own planets, and they have to stay in the name or GregTech's processing lanes could not touch them - the same rule as Forestry's apatite |
| `logWood`, `plankWood` | Barnarda's violet wood (`barnarda_c_test_log`, `barnarda_c_blocks:6`) | same case: a wood log is a wood log, and it is that planet's own tree |

### The one real inconsistency: `plateCoal` and `plateMagnesium`

Those two names hold Galaxy Space's **Compressed Coal** and **Compressed Magnesium** - a *compressed*
(2 metal + TNT in the implosion compressor) plate sitting under a *plain* plate name. That is exactly
the shape of the fourteen plates `oredict.zs` already fixed (the GC/GS copper, tin, steel, bronze,
iron, titanium, desh, cobalt and nickel ones), and the pack left these two deliberately: GregTech has
no coal and no magnesium plate at all, so there is no GregTech item to hand the name to, and Galaxy
Space's own recipes are written against the name.

Leaving them has a cost, and the probe measured it - these are the things that read the two names:

```
CRAFT -> enderio:item_material:23   (Ender IO's coal dust)
CRAFT -> galaxyspace:decoblocks:1   (Galaxy Space decorative block)
CRAFT -> galaxyspace:decoblocks:5   (Galaxy Space decorative block)
MAP macerator -> gregtech:meta_item_1 (x2)      \
MAP plasma_arc_furnace -> ... (x2)               } GregTech's own "plate back into dust/metal" lanes
MAP arc_furnace -> gregtech:meta_item_1         /
```

So a *compressed* plate can be recycled through GregTech's plate lanes as if it were a plain one, and
two mods' recipes name a plate that is really a two-metal plate. The uniform rule - no compressed
plate under a plain `plateX` name, which is what the other fourteen follow - can be applied here too,
but it is not a one-line change: emptying the names leaves Ender IO's coal-dust recipe and Galaxy
Space's two decorative blocks with an empty ingredient, so those three recipes would have to be
rebuilt by item id in the same way `gs_removals.zs` rebuilds Galaxy Space's machine recipes. That is
a decision about two other mods' recipes, so it is written down here and left for the owner.

What *is* fixed now: this pack's own use of the name. The Galaxy Space alloy plate recipe in
`gs_removals.zs` asked for `<ore:plateCoal>`; it now asks for
`<galaxyspace:compressed_plates:0>`, the item it always meant, so it cannot be affected by whatever
the name holds later.

### Verification

The probe was removed, the jar rebuilt, and the clean run reproduced the baseline: **47 mods**,
`Done (4.783s)`, zero `crafttweaker.log` errors, zero `Invalid amount of recipe inputs`, zero
`duplicate or conflict`, the baseline two + two, seven grinding-ball recipes, no new crash reports -
and the recipe hygiene guard still reports only the five Gregicality-authored entries of 6bx.

## 6bz. "Dense Titanium Plate" twice: the display-name collision, and where a rename has to live - 2026-10-14

6by answered the ore-dictionary half of "GT has dense plates too" - the names do not collide. The
owner's question was the other half, and it is a real one: **the items' own names**. They are right,
and the collision is exact:

| item | name the client shows |
| --- | --- |
| `gregtech:meta_item_1:13072` (GregTech `plateDenseTitanium`) | 致密钛板 |
| `galacticraftplanets:item_basic_asteroids:6` (Galacticraft-Planets "Compressed Titanium") | **致密钛板** |
| `gregtech:meta_item_1:13017` (GregTech `plateDenseCobalt`) | 致密钴板 |
| `galaxyspace:compressed_plates:1` ("Compressed Cobalt") | **致密钴板** |
| `gregtech:meta_item_1:13044` (GregTech `plateDenseNickel`) | 致密镍板 |
| `galaxyspace:compressed_plates:3` ("Compressed Nickel") | **致密镍板** |

The English names do not collide - GregTech says "Dense X Plate", the mods say "Compressed X" - but
the mods' **Chinese translation renders "Compressed" as "致密"**, which is exactly the word GregTech
uses for its dense tier. So a player searching JEI for 致密钛板 gets two different items, and they are
*not* the same tier: GregTech's dense plate is nine plates off a bender, Galacticraft's is two plates
and TNT off the implosion compressor. Picking the wrong one wastes nine plates, or - the other way
round - buys a compressed plate at a plain plate's price. That is precisely the confusion the owner
asked about.

### Measuring it, and where the rename has to live

The server is no help here: a dedicated server resolves names in `en_US` (a probe there printed
"Compressed Titanium"), so the collision only exists on the client, in the language the client has
selected (`options.txt: lang:zh_cn`). The display names were therefore read on the **client**, at the
first client tick, by a temporary probe (`MinespaceNameProbe`, deleted again) - and the first attempt
at a fix is worth recording because it silently did nothing:

* putting `assets/galacticraftplanets/lang/zh_CN.lang` into **this pack's own mod jar** did not work.
  The probe still showed 致密钛板. Resource packs are merged in load order and the pack that *owns*
  the asset wins its keys; a mod jar cannot reliably override another mod's lang file.
* a pack in the instance's `resourcepacks/` always loads **after** every mod pack, so that is where
  the override belongs: `resourcepacks/minespace-lang/` (`pack.mcmeta`, format 3) plus
  `assets/galacticraftplanets/lang/zh_cn.lang` and `assets/galaxyspace/lang/zh_cn.lang` (and the
  `zh_tw` pair, where the mods say 緻密鎳 / 緻密鈷), and the instance's `options.txt` enables it
  (`resourcePacks:["minespace-lang"]`).

The rename goes on the **mods' side**, to the word their own English names already use
(`压缩钛板`, `压缩钴板`, `压缩镍板`, `压缩镁板`, `压缩煤板`, `压缩 "SDHC-120" 合金`) - not on GregTech's, whose
`plateDense` prefix is load-bearing for 130-odd items and is the pack's own terminology.

### Verification

The same client probe after enabling the pack:

```
GT plateDenseTitanium  = "致密钛板"      GC-Planets compressed titanium = "压缩钛板"
GT plateDenseCobalt    = "致密钴板"      GS compressed cobalt            = "压缩钴板"
GT plateDenseNickel    = "致密镍板"      GS compressed nickel            = "压缩镍板"
                                        GS compressed magnesium         = "压缩镁板"
                                        GS compressed coal              = "压缩煤板"
```

Three exact collisions, gone; GregTech's own names untouched. The probe was then removed, the jar
rebuilt, and the server run reproduced the baseline: **47 mods**, `Done (4.553s)`, zero
`crafttweaker.log` errors, zero `Invalid amount of recipe inputs`, zero `duplicate or conflict`, the
baseline two + two, seven grinding-ball recipes, no new crash reports, and the hygiene guard still
reporting only the five Gregicality-authored entries of 6bx.

## 6ca. The compressed plates get a name that fits them: 宇航级 - 2026-10-14

6bz renamed the colliding Galacticraft / Galaxy Space plates to 压缩X板 - the word their English names
use. The owner's answer was that this reads like a plumbing part for what is actually flight-rated
plate stock: these are the plates the rocket hulls, the machines and the space suits are built from.
Fair, and the deeper reading of the same probe showed the renaming had also been **incomplete**: the
client probe printed the *lang key* as well as the name, and six more of Galacticraft's compressed
plates collide with GregTech's dense plates - they are simply translated by a different file
(`item.basic_item.compressed_*` rather than `item.compressed_*`):

| Galacticraft item | key | name before |
| --- | --- | --- |
| compressed copper | `item.basic_item.compressed_copper` | 致密铜板 |
| compressed tin | `item.basic_item.compressed_tin` | 致密锡板 |
| compressed aluminium | `item.basic_item.compressed_aluminum` | 致密铝板 |
| compressed steel | `item.basic_item.compressed_steel` | 致密钢板 |
| compressed bronze | `item.basic_item.compressed_bronze` | 致密青铜板 |
| compressed iron | `item.basic_item.compressed_iron` | 致密铁板 |
| compressed meteoric iron | `item.compressed_meteoric_iron` | 致密陨铁板 |

GregTech has a dense plate for copper, aluminium, steel, iron and bronze, so those four names were a
straight collision with a nine-plate item; tin and meteoric iron have no GregTech dense plate, but
they are the same family and were renamed with the rest.

### The name

The whole family - nine Galacticraft plates, five Galaxy Space ones - is renamed in one family, and
the wording took three tries because "high-tech" has two failure modes and the owner rejected one end
of the range each time: 宇航级X板 ("space grade") read *too low* - like a catalogue part - and
星舰船体X板 ("starship hull") read *too far* - science fiction rather than engineering.

What ships is the **materials-engineering** register, which is what these items actually are: a
compressed, reinforced structural plate. **X基复合装甲板** -
铜基 / 锡基 / 铝基 / 钢基 / 青铜基 / 铁基 / 陨铁基 / 戴斯基 / 钛基复合装甲板 from Galacticraft and its
planets, and 碳基 / 钴基 / 镁基 / 镍基复合装甲板 plus `"SDHC-120" 基复合装甲` from Galaxy Space. It says
what the item is (a matrix composite armour plate), it is grounded in real materials language rather
than in fiction, and it cannot be confused with GregTech's 致密X板. The wording is one line per item
in the same resource pack, so any of `纳米晶X板` (nanocrystalline), `航天结构X板`, `X基梯度复合板` or
`爆炸成型X板` (which is the process the item is actually made by: two plates and TNT in an implosion
compressor) is a one-message change.

### A trap worth recording

The first attempt at the Galacticraft-core names used the item's unlocalised name as the key
(`item.basic_item.compressed_copper`) and the client showed **`宇航级铜板.name`** - items look their
display name up under `<unlocalised name> + ".name"`, so the key needs the suffix. The probe printing
the key next to the name is what caught it; the keys for the Galacticraft-Planets and Galaxy Space
items already end in `.name`, which is why 6bz's four lines worked.

### Result, measured on the client

```
GT dense titanium/copper, plain steel = 致密钛板 / 致密铜板 / 钢板      (unchanged)
GC compressed copper/aluminium/steel  = 铜基复合装甲板 / 铝基复合装甲板 / 钢基复合装甲板
GC compressed meteoric iron / desh / titanium = 陨铁基 / 戴斯基 / 钛基复合装甲板
Galaxy Space carbon / nickel / SDHC-120 = 碳基复合装甲板 / 镍基复合装甲板 / "SDHC-120" 基复合装甲
```

No name is repeated between the two families any more, and nothing in GregTech was touched. The probe
was removed, the jar rebuilt, and the server run reproduced the baseline: **47 mods**,
`Done (5.858s)`, zero `crafttweaker.log` errors, zero `Invalid amount of recipe inputs`, the baseline
two + two, seven grinding-ball recipes.

## 6cb. The mod wafers come off GregTech's wafer line - 2026-10-14

The owner's note was short: *"GC 的晶圆和 GT 的晶圆，我觉得应该做成可以从 GT 的晶圆生产出 GC 的，而不是现在的那种做法，
高级晶圆也要改"* - the mod wafers should be produced *from* GregTech's wafers rather than the way the pack
did it, and the advanced ones have to change too.

### What the pack did before, and why it was the wrong shape

Galacticraft's wafers came out of its **Circuit Fabricator**, which this pack removes
(`MinespaceGalacticraftMachineRecipes`). The first translation put them back in GregTech's
**assembler** using the GT5 source's shape - `2x ingotSilicon + 4x circuitBasic` for the basic wafer,
`circuitGood` for the advanced one, and `2x ingotSilicon + 4x circuitAdvanced` for Galaxy Space's
modern one. It loaded, it was not cheap, and it was still wrong in the way the owner pointed at: the
mod wafer was built *beside* GregTech's wafer line, out of raw ingots and circuits, and shared
nothing with any GregTech wafer. A player looking at JEI saw a silicon-ingot recipe, not a wafer.

There was a second, quieter hole. Only three of the five mod wafers had a recipe at all:

| ore name | item | producer before |
| --- | --- | --- |
| `waferSolar` | `galacticraftcore:basic_item:12` blue solar wafer | **none** |
| `waferBasic` | `galacticraftcore:basic_item:13` basic wafer | assembler |
| `waferAdvanced` | `galacticraftcore:basic_item:14` advanced wafer | assembler |
| `waferSolarThin` | `galacticraftplanets:basic_item_venus:6` solar array wafer | **none** |
| `waferModern` | `galaxyspace:gs_basic:5` modern wafer | assembler |

The blue solar wafer had no source because the Circuit Fabricator that made it was removed and
nothing replaced it - which also left Galacticraft's Basic Solar Panel (`basic_item:0`), Full Solar
Panel (`basic_item:1`), Galaxy Space's solar panel (`gs_basic:1`) and the panel above it
(`gs_basic:2`) uncraftable. A progression probe over the finished registries had not flagged it
because those items are at the end of a dead branch; nothing needs them, so nothing broke loudly.

### What GregTech's wafer line actually is

Two probe runs (`MinespaceWaferProbe`, both temporary and both removed afterwards) dumped every
recipe that makes or eats each GregTech wafer, with ids rather than display names. The chain GTCE-TJ
registers is

```
Silicon Boule          = 32x silicon dust + tiny gallium, blast 1784K, circuit 1
Glowstone-doped Boule  = 64x silicon dust + 8x glowstone dust + 8000mb nitrogen, blast 2484K, circuit 1
Naquadah-doped Boule   = 9x silicon block + 1x naquadah ingot + 8000mb argon, blast 5400K, circuit 1
     |  cutting saw
     v
16x Silicon Wafer (32440) / 32x Glowstone-doped Wafer (32441) / 64x Naquadah-doped Wafer (32442)
     |  laser engraver + a gem lens (notConsumable - the lens is the mask, it is not spent)
     v
Integrated Circuit Wafer (32463) / RAM (32471) / CPU (32464) / NAND (32466) / NOR (32468) /
Power IC (32469), then SoC (32472) and ASoC (32462) off the naquadah wafer; PIC + 2x indium in the
chemical reactor gives the High-Power IC Wafer (32465)
     |  cutting saw
     v
8x Integrated Circuit / 32x NAND / 16x NOR / 4x Power IC / 2x HPIC / ... chip dies
```

Three numbers out of that dump decided the rebuild. A wafer is 1/16 of a boule and a boule is 32
silicon dust, so **one silicon wafer carries 2 silicon ingots** - exactly what the old assembler
recipe spent on raw silicon. GT's engraving recipes run at **120 EU/t off a silicon wafer, 480 EU/t
off a glowstone wafer and 1920 EU/t off a naquadah wafer**, and the lenses they pass are gem lenses
(`lensGarnetRed` for the integrated circuit, `lensCubicZirconia` for the CPU, `lensGreenSapphire`,
`lensSapphire`, `lensTopaz`), all of them already registered ore dictionary entries.

### What ships

All five mod wafers are now **engraved in GregTech's laser engraver out of a GregTech wafer**, one
rung per mod tier, using GT's own gem lens as a `notConsumable` and GT's own engraving tiers:

| mod item | input (GregTech) | lens | duration / EU/t |
| --- | --- | --- | --- |
| blue solar wafer `basic_item:12` | 2x Glowstone-doped Wafer `32441` | `lensGreenSapphire` | 500t / 480 |
| basic wafer `basic_item:13` | 2x Integrated Circuit Wafer `32463` | `lensGarnetRed` | 900t / 120 |
| advanced wafer `basic_item:14` | 2x CPU Wafer `32464` | `lensCubicZirconia` | 500t / 480 |
| solar array wafer `basic_item_venus:6` | 2x Naquadah-doped Wafer `32442` | `lensTopaz` | 200t / 1920 |
| modern wafer `gs_basic:5` | 2x High-Power IC Wafer `32465` | `lensSapphire` | 1200t / 1920 |

The three deliberate choices, each of which a reviewer can check in the script comments:

* **The lens**, because it is what GregTech's own engraving recipes do - it is the lithography mask,
  so it must be in the machine but is not consumed. Reusing GT's own lens ore entries means nothing
  new has to exist for these recipes, and JEI shows the mod wafer sitting next to GT's own wafer
  recipes in the same machine.
* **The count of 2**, because it keeps the material account honest: the old assembler recipe's "2
  silicon ingots" *is* one wafer, the mod wafer costs two of them plus the boule, the cutting saw
  and the engraver, and the four circuits the old recipe wanted are gone. Nothing here is cheaper
  than what it replaces.
* **The tiers**, because they are GregTech's own three engraving tiers, so every mod wafer lands in
  a laser engraver the GregTech chain already needs (LV for the basic wafer, MV for the advanced -
  GT's CPU wafer is engraved from the glowstone-doped substrate - and EV for the modern and solar
  array wafers).

The blue solar wafer is the photovoltaic one, so it takes the **glowstone-doped** substrate (GT's
own silicon doped for light) rather than a logic wafer, and the Venus solar array wafer takes the
**naquadah-doped** substrate one tier up. The pack removed Galacticraft's solar *generators* long
ago and nothing consumes either panel item, so this is the end of a decorative line: it does not
reintroduce a power source, it just stops the panels from being uncraftable.

### Removals

The three assembler recipes are gone with the section that held them - `gc_removals.zs` for the
basic, advanced and blue solar wafers, `gaps.zs` for Galaxy Space's modern one - and `gc_processing.zs`
no longer lists the wafer as an unported GT5 recipe (it is superseded, not translated). Each mod
wafer has exactly one producer.

### Verified

The temporary probe, run against the rebuilt registries, printed exactly the five recipes above,
one producer per wafer, and the ore entries `waferSolar` / `waferBasic` / `waferAdvanced` /
`waferModern` / `waferSolarThin` holding one stack each - the mod items, with no GregTech wafer
leaking into those names. The lens entries resolve (`lensGarnetRed` -> `gregtech:meta_item_1:15243`,
and so on). The probe was then removed, the jar rebuilt, and a clean server run reproduced the
baseline exactly: **47 mods**, `Done (6.264s)`, zero `crafttweaker.log` errors, zero
`Invalid amount of recipe inputs`, zero `duplicate or conflict`, the baseline two `Invalid recipe`
plus two `Input cannot contain null`, seven grinding-ball recipes, 22 `no-double-route` and 13
`machine-only enforcement` lines, no new crash reports.

## 6cc. The dead-ingredient audit: what the scripts took away, and what they did not - 2026-10-14

The Blue Solar Wafer in 6cb was the shape of a whole bug class: an item that a live recipe still asks
for, whose only producer was a mod machine this pack removes. It was found by accident, while chasing
something else. This section is the deliberate sweep for the rest of them.

### The question and the tool

One temporary probe (`MinespaceDeadIngredientProbe`, removed again) answered a single question over
the finished registries: **which items are needed by a live recipe but have no producer at all?**

* producers were collected from every crafting recipe in `ForgeRegistries.RECIPES`, every GregTech
  recipe map - `getOutputs()` **and** `getChancedOutputs()`, which is what a first version missed and
  which is how the gem byproducts (`gemExquisiteDiamond` and friends) turned up as false positives -
  and vanilla smelting;
* an ingredient counts as reachable if **any** stack it can match has a producer, so an ore dictionary
  name with one live member is not reported;
* every item in an `ore*` name counts as world-generated, and an `ItemBlock` whose block has **no
  tile entity** is skipped outright - that is terrain, plants and decoration, 151 stacks of it, which
  no recipe ever makes;
* the remainder was reported with its id, its ore dictionary names, how many recipes need it, and up
  to four of those recipes.

That produced 315 flagged keys in the pack's mods and 84 outside them. Numbers that size are useless
without a second measurement, so the probe was extended with the one that decides the question:

> **a snapshot at `postInit`, i.e. before CraftTweaker's scripts run, recorded 14,710 producers.
> Load complete has 14,769 - the scripts add 59 producers and remove none that matter. The diff, the
> items whose producer existed before the scripts and is gone after them, is `0`.**

### What the residual 315 actually are

Everything left never had a crafting or GregTech-machine producer, in this pack or without it - each
bucket checked against something other than memory:

| bucket | examples | the evidence |
| --- | --- | --- |
| the mod's own machine | Ender IO's industrial / enhanced / soul chassis (`alloying.xml`, "Chassis"), Forestry's four chipsets and the scented paneling, its Portable Analyzer and Flexible Casing, its combs / honey / wax / pollen, AE2's processors, matter ball and singularity | the pack's own parked dumps: `forestry_probe.txt` shows `carpenter out=forestry:portable_alyzer` and `cast ... out=forestry:flexible_casing`, and section 6aj already recorded that those five Carpenter recipes are the ones `MinespaceForestryCarpenter` rewrites; EIO's machine recipes are the `config/enderio/recipes/user/user_recipes.xml` file this pack edits by hand (section 6bj lists the chassis among the outputs Ender IO's own Alloy Smelter keeps) |
| world generation and loot | ores, logs, saplings, the fallen meteor, GC's raw meteoric iron, Galacticraft and Galaxy Space rocket schematics and the rockets themselves, GregTech's `coin.gold.ancient` | the probe's own exclusions, plus the mods' loot tables, which no recipe dump can see |
| an item's *state*, not a recipe | AE2's charged certus quartz, Galacticraft's `battery:0` | Galacticraft's own arc lamp recipe asks for a **drained** battery; the unmodified mod never crafted one either - the charged battery is `battery:100`, which the pack rewrites into GregTech's assembler in `assembler_2.zs` |
| GT++'s MAX tier | `emitter.max`, `motor.max`, `nitride*` | they are consumed only by other MAX-tier GT++ casings, and **no recipe map in the game produces them - before or after CraftTweaker** (they are absent from the `postInit` snapshot too), so they are GT++ items without a source in GT++ itself rather than something this pack removed |

The Galacticraft / Galaxy Space residue was checked against the pack's *own* pre-CraftTweaker dumps as
well, since those are the items this pack rewrites most (`%TEMP%\minespace-cleanup-2026-10-12\
temp-scratch\6bs-init_all.txt`, `audit_crafting.txt`, `audit_maps.txt`): Galaxy Space's dolomite
crystal and meal, its volcanic and "unknown crystal" shards, its blank schematic and raw plastic,
Galacticraft's filled fuel canister, its LOX and LN2 canisters and the radioisotope core have **no
producer in the init dump either**, i.e. they come from the mods' own machines, planets and dungeon
chests. None of them is something this pack broke.

### Result

The class has exactly one member in this migration - the mod wafers of 6cb - and it is fixed. The
audit's permanent value is the measurement itself: if a future remove-script takes a producer away
from something still in use, the same probe finds it in one run, and the `postInit` diff says so
immediately instead of leaving it to a play test.

The probe was removed and the jar rebuilt (199,838 bytes); the server runs on both sides of that
removal reproduced the baseline exactly: **47 mods**, `Done` in four to six seconds, zero
`crafttweaker.log` errors, zero
`Invalid amount of recipe inputs`, zero `duplicate or conflict`, the baseline two `Invalid recipe` and
two `Input cannot contain null`, seven grinding-ball recipes, 22 `no-double-route` and 13
`machine-only enforcement` lines.

## 6cd. The last two compressed-plate names: `plateCoal` and `plateMagnesium` - 2026-10-14

6by left these two alone on purpose and said why: GregTech has no coal plate and no magnesium plate,
so unlike the fourteen plates around them there was no GregTech item to move the name onto, and a
name with a single, non-duplicated member is not an ambiguity. The owner's follow-up was "do it if you
see fit, but do not touch the GregTech tech line", so this is the measurement that decides it.

### What the dump said

The same probe dumped both names and every recipe that reads their items:

```
name plateCoal      (1): galaxyspace:compressed_plates:0      <- 9 coal, GregTech compressor
name plateMagnesium (1): galaxyspace:compressed_plates:2      <- 2 magnesium ingots, compressor / fluid solidifier

read by:  enderio:item_material:23   (Ender IO's powdered coal: <ore:plateCoal> + a mortar)
          galaxyspace:decoblocks:1 and :5   (the two magnesium decorative blocks, x4 each)
          GregTech's own plate lanes (macerator, arc furnace, plasma arc furnace, fluid extractor)
```

So the shape 6by described is real and small: a *compressed* plate (two metal and TNT through the
implosion compressor) sitting under a *plain* plate name, read by one Ender IO recipe and two Galaxy
Space ones. The item that "compressed coal plate" was satisfying in Ender IO's recipe is a coal
plate, a thing that does not exist in this pack - an accidental pairing of two mods sharing a name.

### What shipped

* the two names are **emptied** in `oredict.zs`, the same surgery as the fourteen plates above, with
  the same result: the items are reachable as `galaxyspace:compressed_plates:0` / `:2` and nowhere
  else. They stay craftable exactly as before (GregTech's compressor for both, the fluid solidifier
  for the magnesium one);
* Galaxy Space's two magnesium decorative blocks are rebuilt against the item they always meant, in
  `gs_removals.zs` next to their cobalt / nickel / copper siblings, with the mod's own grids and
  output counts;
* Ender IO's powdered-coal recipe is handled with the bridge this pack uses for every other mod copy
  of a GregTech material - but not the way it was planned, and the difference is worth recording.
  `recipes.remove(output, ingredient)` in CraftTweaker **does not filter by ingredient**: the first
  version was written against `<ore:plateCoal>` and took all five powdered-coal recipes with it, and
  rewriting it against the item id changed nothing. The lever CraftTweaker offers is "every recipe
  with this output", so instead of reconstructing four recipe grids out of a dump, the pack removes
  the set and adds one bridge: **one GregTech coal dust in, one powdered coal out**. Powdered coal is
  a duplicate whose name `dustCoal` this file already took away from it; nothing else in the pack or
  in the mods consumes it (Ender IO's own recipe files in `config/enderio/recipes` hold no reference
  to it), and the bridge cannot be run backwards because the shared name no longer holds it;
* GregTech's plate lanes are deliberately **not** touched. They were generated from the ore dictionary
  when Galaxy Space registered the entries and they hold the item, not the name, so they keep working
  either way: a compressed coal plate still macerates to a coal dust, a compressed magnesium plate
  still arc-furnaces to a magnesium ingot. Both are lossy round trips through GregTech machinery
  rather than shortcuts into it, so nothing is gained by removing them and the tech line is untouched.

### Verified

```
name plateCoal (0), name plateMagnesium (0)
galaxyspace:decoblocks:1 x4  <- 5x stone + galaxyspace:compressed_plates:2      (rebuild)
galaxyspace:decoblocks:5 x4  <- 5x stone + galaxyspace:compressed_plates:2      (rebuild)
enderio:item_material:23 x1  <- gregtech:meta_item_1:2106 (coal dust)           (bridge)
"producers that existed before CraftTweaker and are gone now: 0"
```

The probe was removed, the jar rebuilt, and the clean run again reproduced the baseline exactly:
**47 mods**, zero `crafttweaker.log` errors, zero `Invalid amount of recipe inputs`, zero
`duplicate or conflict`, two `Invalid recipe`, two `Input cannot contain null`, seven grinding-ball
recipes, 22 `no-double-route`, 13 `machine-only enforcement`.

## 6ce. The two name-hygiene sweeps: shared ore names, and every item whose display name is not unique - 2026-10-14

Two follow-ups from 6by / 6bz / 6ca, both asked for by the owner: clean the ore dictionary names that
still hold an *unobtainable* duplicate, and sweep the display names systematically instead of fixing
one collision at a time.

### The tool

One temporary client-side probe (`MinespaceDictNameProbe`, removed again) answered both questions in
one run, because the interesting half is only visible on the client: it is the client that resolves
the player's language.

* for every ore dictionary name, the members, their mod, and - for the members from the pack's mods -
  whether **anything produces them** (all crafting recipes, every GregTech recipe map including
  chanced outputs, and smelting) or whether they are world-generated (`ore*` names);
* for every item, `getSubItems(CreativeTabs.SEARCH)` so metaitems and subtyped items are enumerated,
  then each stack's **display name as the player sees it**, with `§` colour codes stripped and
  untranslated keys discarded, grouped to find names two different items share;
* and for the ids that came out of that, a third pass listing their producers and consumers in the
  *current* registries, which is what separates "a leftover nothing wants" from "a real item that
  merely shares a name".

### Part one: the shared ore dictionary names are clean

`oredict.zs` carried a note saying that the names holding an *unobtainable* duplicate - Galacticraft's
ingots, whose crafting recipes this pack deletes, and the GC/GS dusts - were deliberately left alone
because they cannot be acquired, so they are a display wart rather than an exploit.

The sweep shows the passes since have closed all of them. **Fifteen names** still hold both a
GregTech (or this pack's) item and a pack mod's, and every one is a family the pack keeps on purpose:

| family | names | why it stays |
| --- | --- | --- |
| planet ore blocks | `oreIron`, `oreGold`, `oreCoal`, `oreDiamond`, `oreLapis`, `oreRedstone`, `oreEmerald`, `oreLead`, `oreSolar` | an iron ore block is an iron ore block; each planet's ore has to be in the name for GregTech's own processing lanes to see it (6by) |
| wood | `logWood`, `plankWood`, `treeSapling`, `treeLeaves` | GregTech and Forestry both ship the family, and a plank is a plank |
| AE2 | `crystalCertusQuartz` | the mod's own crystal forms, and 6bn added the one-to-one bridge to GregTech's certus quartz |
| Ender IO | `dyeBlue` | that mod's lapis dust doubles as blue dye, which is what lapis is |

No name is left holding a *processed* duplicate - an ingot, a dust, a plate - which is what this file
exists to prevent. The stale note in `oredict.zs` is replaced with that measurement.

### Part two: 93 display names are shared across a mod boundary

Of 48,737 named stacks the client sees, 1,488 names are held by more than one item and **93 of those
cross a mod boundary**. Reading them splits them into three groups:

* **the documented-legit families**, as above: the ore blocks (each planet's ore is named 铁矿石,
  金矿石, ...), the wood family, vanilla's seven dyes next to GregTech's chemical ones, vanilla's
  glass pane next to GregTech's glass plate, and vanilla's torch next to Galacticraft's lit torch.
  These are the same shape as the ore dictionary decision and are left alone;
* **the leftovers this file already hides** - the pack's `jei_dupes.zs` had 131 ids hidden, which is
  why most of the duplicate ingots, dusts, gears and alloy blocks do not appear in the list at all
  once the hidden ones are set aside;
* **ten that were hiding in plain sight**, each verified in the third pass to have a producer and no
  consumer, i.e. a mod copy of a GregTech material whose only recipe is the neutral round trip:
  Galaxy Space's cobalt / nickel / magnesium **blocks** and **nuggets** (the GregTech block or nugget
  is the one to make; GregTech's unpacker already converts its own item back), the **empty** state of
  Galaxy Space's Ultimate Battery (`:0`; `:100` is the crafted one), Galacticraft-Planets' lead ingot
  (only reachable through the one-to-one bridge in `gaps.zs`), Galacticraft-IC2-Compat's aluminium
  dust, and **Galacticraft's own Oxygen Compressor** - whose own recipe is gone with the mod's
  power-consuming machines, because this pack's GregTech-powered `gregtech:machine:32000` of the same
  name is what replaces it (6m). All ten now leave JEI.

### The one that was a translation bug

`gtadditions:ga_meta_item:32030` and GregTech's own phenolic circuit board printed the *same* Chinese
name, and the same was true of the plastic pair. The English is "Good Phenolic Circuit Board" and
"Good Plastic Circuit Board"; GT++'s Chinese translation simply dropped the "Good", so its two boards
read exactly like GregTech's. That is a translation fault rather than a design question, so it is
fixed in the same resource pack `minespace-lang` that 6bz/6ca use - `assets/gtadditions/lang/
zh_cn.lang` (and `zh_tw`) - and the cross-mod count fell from 94 to 93 on the next client run with no
board names left in the list.

### The renames - decided 2026-10-14, wording delegated by the owner

Renamed, all in the same `minespace-lang` resource pack, and each one read back off the client:

| item | was | now | the other side |
| --- | --- | --- | --- |
| Galacticraft Steel Pole (`item.steel_pole.name`) | 钢杆 | **钢柱** | GregTech's steel rod keeps 钢杆 |
| Forestry Worktable (`tile.for.worktable.name`) | 工作台 | **林业工作台** | vanilla's crafting table keeps 工作台 |
| Galaxy Space's red watergrass (`tile.watergrass_red.name`) | 红藻 | **红藻水草** | GT++'s red algae material keeps 红藻 |
| Galaxy Space's brown watergrass (`tile.watergrass_thick_green.name`) | 褐藻 | **褐藻水草** | GT++'s brown algae material keeps 褐藻 |

The rule behind the choice: rename the side that is *not* the GregTech material and whose name is the
vaguer one. A pole that this pack builds out of three dense steel plates and a hammer is a column, not
a rod; Forestry's bench is *Forestry's* bench; and the watergrass is a plant, while GT++'s two algae
are the material items (its own file already calls the powder 红藻粉末). The GT++ board pair above is
the same kind of fix in the opposite direction - there the mod's Chinese was simply missing a word.

### Left alone, and why

* **the thermal padding family** (热防护帽 / 背心 / 裤 / 靴 and 热防护布料 shared by Galacticraft
  Planets' Tier 1 and Galaxy Space's Tier 3 and Tier 4): **a lang file cannot separate them.** Galaxy
  Space registers its pieces against Galacticraft's own unlocalised keys - `javap` on
  `ItemThermalPaddingBase` shows `names[] = {"thermal_helm", "thermal_chestplate", "thermal_leggings",
  "thermal_boots"}` and a `getUnlocalizedName` of `"item." + names[meta]` - so any override renames
  Galacticraft's pieces identically. The tier is already in the tooltip (`gui.tier`), so nothing is
  lost but the first line of the name; splitting them would take a name hook in Java;
* **the five `CNSA工程设计图` schematics**: the same shape. All of Galacticraft's schematic items
  share one key, `item.schematic.name`, verified in the mod's own `zh_cn.lang`, and the type is in the
  tooltip;
* **终极电池**: Galaxy Space's `item.ultimate_battery` and GregTech's `metaitem.zpm2` are both
  "Ultimate Battery" *upstream* - the mods' own translations agree with each other. Neither is an
  ingredient of a recipe that asks for the other, the icons differ, and renaming one mod's signature
  item to paper over an upstream name clash is not this pack's call;
* **the duplicate dusts and materials that a live mod machine still produces** - AE2's 铁粉 / 金粉 /
  赛特斯石英粉 / 末影粉 / 面粉 / 下界石英粉 / 硅板 / 木齿轮 next to GregTech's, and Forestry's
  灰烬 / 木浆 / 碎冰 next to GregTech's. These are *not* the same case as the ten hidden above: their
  producer is the mod's own machine (AE2's grinder, Forestry's machines), so hiding them would take an
  item out of a machine's own JEI page. The real fix is to point those machine recipes at GregTech's
  items the way `MinespaceGrinderToMacerator` and the alloy rewrites already do for other lanes - that
  is a job of its own and is recorded here as the next candidate.

### Verified

Two client runs and two server runs. The second client run is the one that matters for the rename: the
cross-mod count is **93** and no 电路基板 name is duplicated any more. The two temporary probes were
removed, the jar rebuilt (199,838 bytes), and the clean server run reproduced the baseline exactly:
**47 mods**, `Done (6.913s)`, zero `crafttweaker.log` errors, zero `Invalid amount of recipe inputs`,
zero `duplicate or conflict`, the baseline two `Invalid recipe` and two `Input cannot contain null`,
seven grinding-ball recipes, 22 `no-double-route` and 13 `machine-only enforcement` lines.

## 6cf. The last duplicate class: Gregicality's *hand* recipes - 2026-10-14

6ce closed by naming the only duplicate class it had not fixed: the powders and materials that AE2's
and Forestry's *own machines* still produce, whose names collide with GregTech's. This is that job,
and the measurement turned up a different culprit than the note expected.

### What the probe found

A temporary server-side probe (deleted again) printed, for the sixteen duplicate dusts and materials
in that list, every producer and every consumer in the finished registries. The producers are **not**
the mods' machines:

```
appliedenergistics2:material:49  (iron dust)
    producer: crafting <- gregtech:meta_tool:6 (mortar), gregtech:meta_item_1:7033 (small dust)
    producer: crafting <- minecraft:iron_ingot, gregtech:meta_tool:12 (hammer)
    producer: crafting <- gregtech:meta_item_1:1033 x4, ...            <- and a small-block form
    consumers: NONE
```

Every one of them is a **Gregicality hand recipe** - a mortar and small dusts, an ingot and a hammer,
nine nuggets and a mortar - and those recipes were generated through `OreDictUnifier.get(prefix,
material)`, which answers with the *first* stack in the shared name. That is exactly the bug section
6bk described for the gears, in the one registry the fix never covered: `repointMaps` rewrites
GregTech's recipe maps and `repointCraftingInputs` rewrites what crafting recipes *eat*, but nothing
rewrote what a crafting recipe *hands out* - so the crafting table kept producing the mod's copy of a
material GregTech had already taken over.

Two of the sixteen are different: AE2's **certus quartz** and **nether quartz dusts** are still eaten
by AE2's own recipes (`appliedenergistics2:part:140`, `tiny_tnt`), whose ingredient lists mix AE2's
dust with items the conservative input pass leaves alone. Those keep their producer.

### The fix

`MinespaceMaterialRepoint.removeDeadDuplicateCrafting`, called from postInit and again at load
complete right after the input passes, deletes a crafting recipe when

* its output is one of the unified-away mod items, **and**
* nothing in the finished registries consumes that item - not a crafting recipe, not a GregTech
  machine map. Smelting lanes for these items were already removed by `pruneDeadSmelting`.

It deletes rather than re-points, and that is deliberate: replacing the output means building a new
recipe object, which loses the shaped / shapeless layout JEI draws from the original class, and these
recipes all produce an item that nothing wants - so the honest end state is the one the silicons and
the apatite already reached: the conversion goes, and the mod's item goes with it.

Nine items are left without a producer and are hidden from JEI in the same commit (three more were
hidden already): AE2's iron, gold and ender-pearl dusts, Ender IO's powdered coal, obsidian powder and
soularium powder, Forestry's ash, Galaxy Space's sulfur dust, and Galacticraft-Planets' **desh
ingot**.

That last one has a consequence worth recording. `gaps.zs` keeps a one-to-one bridge "GregTech desh
ingot -> Galacticraft's desh ingot" so that Galacticraft's own recipes, which name the mod's ingot by
exact id, stay buildable. The input re-point pass now rewrites those recipes to ask for GregTech's
ingot directly, so nothing consumes the mod's ingot any more, the bridge is deleted on every load and
the item leaves JEI. The bridge line stays in the script as insurance if that pass ever fails to run.
The **lead** bridge beside it is still load-bearing: a Galacticraft recipe keeps asking for
`basic_item_venus:1` by id with a mixed ingredient list, so it is left alone and still needs the
bridge.

### Verified

```
dead duplicate crafting (postInit pass):     21 recipes deleted, 7 unified mod items left without a producer
dead duplicate crafting (loadComplete pass): 13 recipes deleted, 5 more (the pack's own bridges and
                                             CraftTweaker-added recipes)
post-change dead ingredient audit: none of the twelve appears as needed-but-unproducible
```

The 6cc audit was re-run in the same session to check the safety property that matters - nothing is
left needing an item that no longer exists - and none of the twelve items appears in it. (That re-run
used the simpler variant of the probe, without 6cc's world-block filter, so its raw count is larger
by the wood and decoration families; and it reports every member of an ingredient it cannot satisfy,
which is why one or two names appear that merely *share* an ingredient with an unobtainable item.)

The probes were removed, the jar rebuilt (200,871 bytes - the new pass is code), and a clean server
run reproduced the baseline exactly: **47 mods**, `Done (4.028s)`, zero `crafttweaker.log` errors,
zero `Invalid amount of recipe inputs`, zero `duplicate or conflict`, the baseline two `Invalid
recipe` and two `Input cannot contain null`, seven grinding-ball recipes, 22 `no-double-route` and 13
`machine-only enforcement` lines.

## 6cg. The two addon machines get their last screen feedback - 2026-10-14

M3 asked for the two machines this addon registers - the GregTech **Oxygen Compressor**
(`gregtech:machine:32000`) and **Rocket Fuel Loader** (`:32001`) - to be "placed, powered and
crafting, with their `ModularUI` screens", and section 7 listed the GUI as the one part of the port
with no GregTech original to copy.

Reading the two classes settles it: **the screens were already there.** Each machine overrides
`createUI(EntityPlayer)` and builds the same layout GTCE gives its own single-block machines - a
`LabelWidget` with the machine name, one `SlotWidget` (the oxygen tank to fill / the fuel canister to
drain), a `TankWidget` over the machine's own buffer tank, and the player inventory bound at row 84.

What they did *not* have is the one piece of feedback GregTech's own machines add on top of that: an
`ImageWidget` over `GuiTextures.INDICATOR_NO_ENERGY`, shown while the machine's energy buffer is
empty. Both machines now carry it - same texture, same 18x18 size, x 79 as in
`SimpleMachineMetaTileEntity`, y 60 rather than 42 because the tank slot occupies that row in these
two layouts:

```java
.widget(new ImageWidget(79, 60, 18, 18, GuiTextures.INDICATOR_NO_ENERGY)
        .setPredicate(() -> energyContainer.getEnergyStored() == 0))
```

Worth recording for the next machine: this fork ships **no proportional energy bar**. A sweep of
`GuiTextures` finds `INDICATOR_NO_ENERGY` and nothing else energy-shaped - no `ENERGY_BAR`. The icon
*is* GregTech's energy vocabulary here, which is why copying it is the faithful move rather than
inventing a bar. The same sweep did turn up the arrow and process bars
(`PROGRESS_BAR_ARROW`, `PROGRESS_BAR_COMPRESS`, ...), so a `ProgressWidget` is available if the
owner ever wants the oxygen compressor to show the *tank in its slot* filling up
(`damage / maxDamage`, which no stock texture is shaped for).

Verified: the two additions compile; the server run reproduced the baseline exactly (**47 mods**,
`Done (5.238s)`, zero `crafttweaker.log` errors, the baseline two `Invalid recipe` and two `Input
cannot contain null`, 22 `no-double-route` and 13 `machine-only enforcement` lines, and the same 19
`Exception` mentions in `latest.log` as the archived baseline - the vanilla door-advancement noise
plus Ender IO's mod-list messages). **A GUI cannot be looked at headlessly**, so the layout itself
still wants one right-click in game.

## 6ch. Two more Galacticraft machines retired: the Astro Miner Base and the Chromatic Applicator - 2026-10-14

The next items off `GC-GREGFICATION-PLAN.md`'s "Still to do" table, the two whose plan column was
already a verb rather than a question:

| machine | the plan said | what it is |
| --- | --- | --- |
| `galacticraftplanets:miner_base` **Astro Miner Base** | "GregTech's ore/fluid drilling plants replace the job" | Galacticraft parks a mining vehicle on an asteroid and rocks up with ore; a GregTech Mining Drill or Fluid Rig does that inside the pack's own chain |
| `galacticraftcore:machine3:0` **Chromatic Applicator** | "Cosmetic; delete" | it paints a colour onto Galacticraft's space glass |

### The metadata trap

The plan's row named the applicator as `machine3:9`, and that number came from the mod's **lang file
key** (`tile.machine3.9.name=Chromatic Applicator`), not from the metadata the block is registered
with. `hightech.zs` disagreed - its assembler recipe for the applicator - eight dyes and a compressed
steel plate - is written against `machine3:0` - so a probe printed every `machine3` meta's display
name and its recipe links, and **`machine3:0` is the one with the dye recipe** (every meta answers to
the same display name, so the name alone cannot tell them apart). `machine3:0` it is; the plan's row
is corrected in `GC-GREGFICATION-PLAN.md`.

### What was removed

Both machines were *producers* of themselves through this pack's own scripts, so removing the machine
means removing those:

* `gaps.zs` had rebuilt the Astro Miner Base's 3x3 grid (Galacticraft's own, minus the Energy Storage
  Module this pack deletes) and `hightech.zs` had rebuilt it again as an MV assembler recipe; both are
  gone, replaced by the note that the machine is retired;
* `hightech.zs` had the applicator as an assembler recipe (no integrated circuit - its nine inputs
  were already full, the lesson of 6am); that is gone too;
* `gc_removals.zs` carries the rest: `recipes.remove` for both, `mods.jei.JEI.hide` for both items,
  and `hideCategory("galacticraft.astroMiner")` for the miner's JEI category (the applicator has no
  category of its own - it is a block with a GUI, not a recipe machine).

### Two lessons worth keeping

* **`recipes.remove(<an item that does not exist>)` is an ERROR, not a silent skip.** The first
  version of this change also named `galacticraftplanets:miner_base_full` - a name that appears in the
  mod's lang file but is not a registered item - and the log came back with two errors
  ("Cannot remove recipes for a null item!", "Unable to hide null itemstack! null") against the
  baseline's zero. The item is `miner_base`; the `_full` name is Galacticraft's docked *state*, not a
  second block.
* **A hidden item is only hidden if JEI knows it.** The pack's existing hide list was built by
  watching for "Could not find any matching ingredients to remove", and the same check is the reason
  `hideCategory` must spell a category exactly (`astroMiner`, capital M; the pack's own note about
  `methaneSynthesizer` is the same trap).

### Verified

The probe (removed again) confirmed both items now have **no producer and no consumer** in the
finished registries, and a clean server run reproduced the baseline except for one line that moved on
purpose: **`machine-only enforcement` is 12, not 13**, because the Astro Miner Base was in that list
(its crafting recipe was deleted in favour of a machine route) and now has no crafting recipe left to
delete - the diff against the archived baseline is exactly that one entry and nothing else. Everything
else unchanged: **47 mods**, `Done (6.833s)`, zero `crafttweaker.log` errors, zero `Invalid amount of
recipe inputs`, zero `duplicate or conflict`, the baseline two `Invalid recipe` and two `Input cannot
contain null`, seven grinding-ball recipes, 22 `no-double-route`, and the same 19 `Exception` mentions
in `latest.log` as the archived baseline.

## 6ci. The last of Galacticraft's "decide" machines - 2026-10-14

`GC-GREGFICATION-PLAN.md`'s "Still to do" table ended with a set of rows whose plan column said
"decide": the machines that neither duplicate a GregTech machine nor obviously have to go. The owner
delegated the call ("可以，你改就行"), so each was measured first - a probe over the finished
registries printed, per candidate, its display name, every producer and every consumer - and then
decided against the two rules this pack already applied everywhere else:

* **delete** what duplicates GregTech's job, is cosmetic, or has lost the machines it works with;
* **keep** life support, rocket logistics and planet-environment devices - the things the pack's own
  `gc_removals.zs` keep-list already names, and which the owner re-affirmed when the one attempt to
  remove the Oxygen Sealer was reverted.

### Deleted

| machine | why |
| --- | --- |
| **Energy Beam Reflector** (`galacticraftplanets:beam_reflector:0`) | an orphan: a reflector only redirects the **solar array's** energy beams, and the array's controller, module and receiver had all been removed in the first pass. The pack had even rebuilt the reflector's recipe in `assembler_2.zs` - that rebuild is gone with it |
| **Laser Turret** (`galacticraftplanets:laser_turret`) | GC's own description: "can target meteors, players, and mobs". A combat toy with no place in the material chain. The probe showed it was **already uncraftable** - no recipe, no consumer - so the change only stops it showing up as an obtainable item |

### Kept, with what they have now

| machine (measured id) | what the probe found |
| --- | --- |
| Oxygen Detector (`galacticraftcore:oxygen_detector:0`) | assembler recipe (`hightech.zs`), and Galacticraft's own Oxygen Sealer consumes it |
| Oxygen Storage Module | not identifiable as a craftable item: it is a `machine2` meta, and **no** `machine2` meta has a recipe in this stack; `gc_removals.zs` already records that several of those metas are not in JEI at all. The pack's own Oxygen Compressor carries a 16 000 mB buffer |
| Launch Controller (`galacticraftplanets:mars_machine:8`) | MV assembler recipe |
| Terraformer (`mars_machine:0`) / Cryogenic Chamber (`mars_machine:4`) | table grid / assembler recipe (with a bed); the environment devices the owner wants kept |
| Short Range Telepad (`galacticraftplanets:telepad_short:0`) | assembler recipe; moves players |
| Landing Pad (`galacticraftcore:landing_pad:0` Rocket Launch Pad, `:1` Buggy Fueling Pad) | both keep their own grids |
| Parachest (`galacticraftcore:parachest`), Space Station Base (`galacticraftcore:dummyblock`) | no recipe **by design** - the parachest falls with the rocket, the station base is a multi-block part |
| View Screen (`view_screen:0`), Telemetry (`telemetry:0`), Spin Thruster (`spin_thruster:0`) | assembler recipes; rocket electronics |

### The trap that cost three rows

Three ids in that table were **lang-file indices, not metadata**: the Chromatic Applicator
(`machine3:9` -> `machine3:0`, 6ch), the Launch Controller (`mars_machine:2` -> `:8`) and the
Cryogenic Chamber (`mars_machine:1` -> `:4`). Galacticraft writes one `tile.<block>.<n>.name` line per
*type*, and at least two of its machine blocks encode metadata as **type x 4 + tier**, so the
sequential names in the lang file never line up with the item metadata. The probe - which prints the
runtime display name *and* the recipe links for every meta - is the only cheap way to tell them apart,
and it is why the corrected table in `GC-GREGFICATION-PLAN.md` now says "measured registry item".

### Verified

Both deleted machines were confirmed to have no producer and no consumer before the change (the
reflector had the pack's assembler recipe, removed with the rest of it; the turret already had
nothing). The probes were removed, the jar rebuilt (201,599 bytes), and a clean server run reproduced
the baseline: **47 mods**, `Done (4.162s)`, zero `crafttweaker.log` errors, zero `Invalid amount of
recipe inputs`, zero `duplicate or conflict`, the baseline two `Invalid recipe` and two `Input cannot
contain null`, seven grinding-ball recipes, 12 `machine-only enforcement` (13 until 6ch removed the
miner base's last crafting recipe), 22 `no-double-route` and the same 19 `Exception` mentions as the
archived baseline.

With that, `GC-GREGFICATION-PLAN.md`'s "Still to do" table is empty: every row is either carried out
or explicitly kept.

## 6cj. The last two section-7 bullets: material ids, and the new-world requirement - 2026-10-15

Section 7 had four bullets. Two were closed earlier (the machine GUI, 6cg); the other two are these.

### Material id collisions: measured, none

The bullet asked for a check that the addon's materials do not collide with Gregicality's, on the
observation that "material indices start at a project-specific offset, so pick ids well above
Gregicality's". The code had already changed shape since it was written, and reading it is what
settles the question: GTCE's `Material.MATERIAL_REGISTRY` is a `GTControlledRegistry` with a **fixed
capacity of 1000** (`new GTControlledRegistry<>(1000)`), Gregicality fills the *top* of that range
(its `luv_superconductor_base` is at 972, which is where a hand-picked high block had collided), and
`MinespaceMaterials` therefore hands ids out from the **lowest free slot upwards** - GT and
Gregicality fill the low ids densely and their free holes there are stable.

That is a good design, but "good design" is not a measurement, and the shape of this particular
failure is nasty: `register(id, name, value)` writes into an `IntIdentityHashBiMap`, so a taken id
does **not** fail loudly - it re-points the earlier material's id lookup at the new one, and GT's
per-id arrays quietly disagree with its name map. So the probe iterated the whole registry and asked
each material's id to resolve back to *itself*:

```
materials: 794, highest id: 999
ids that resolve to a different material than their own: 0
this addon's materials: desh 0, meteoric_iron 136, desh_steel 147, solar 160, onyx 178, dolomite 289
```

Zero mismatches across all 794, the highest id is 999 (inside the 1000-slot capacity), and the
addon's six materials each own their id. The bullet is closed. (The full id map is parked in
`%TEMP%\minespace-cleanup-2026-10-12\logs-archive\material_ids_all.txt.*` if a future material needs
a free slot looked up.)

The other half of that bullet - the "Potentially Dangerous alternative prefix" warnings - is not a
defect at all: Gregicality registers into the `gregtech` item namespace and Galaxy Space registers
into others, deliberately. The instance README already lists those lines as expected noise.

### The new-world requirement: now stated where players will see it

"The world must be new" is not a task, it is a property of the migration: an existing save's
registry cannot be carried over, because GTCEu's material ids, meta item ids, ore blocks, stone types
and vein definitions all moved when the stack switched to GTCE-TJ. M4 handled the mechanics (the
GTCEu stack is parked, the old save is kept as `world-gtceu-backup`, the current world is new), but
the requirement itself only existed in this plan file - which is the *developer's* document.

So the instance `README.md` (the file a player reads first) got the missing part: a **"必须开新世界"**
section at the top explaining that old worlds cannot be loaded into this stack and what to do with
one, plus a corrected status paragraph. The README was still describing the GTCEu era - "28 mods",
the old `minespace:desh_steel` material item, and a KubeJS-first scripting story - so the status
block now carries the current numbers (47 mods, `Done` in four to seven seconds, zero
`crafttweaker.log` errors) and the mod list points at `MOD-MANIFEST.md` for the real stack. The
KubeJS section keeps its 1.12.2 notes (they are still true) with a line saying the pack's recipe work
is CraftTweaker's now. A fuller README refresh is a writing task of its own and is noted here rather
than half-done.

Verified: the probe was removed, the jar rebuilt (201,599 bytes) and the clean server run reproduced
the baseline - **47 mods**, `Done (3.514s)`, zero `crafttweaker.log` errors, zero `Invalid amount of
recipe inputs`, zero `duplicate or conflict`, the baseline two `Invalid recipe` and two `Input cannot
contain null`, seven grinding-ball recipes, 12 `machine-only enforcement`, 22 `no-double-route` and
the same 19 `Exception` mentions as the archived baseline.

## 6ck. The TJ config audit: every GTCEu-era switch, checked - 2026-10-15

The last bullet in section 7 was "everything done for GTCEu configuration does not carry over; the TJ
config has its own switches to review". This is that review, and it had a free source of truth: the
parked GTCEu stack keeps its own `config/gregtech/gregtech.cfg` and `modules.cfg`, so the GTCEu-era
values could be diffed against the current `config/gregtech.cfg`, `gtadditions.cfg` and
`gregtechfoodoption.cfg` switch by switch. Where a GTCEu switch no longer exists, GTCEu's *own jar*
was read (`javap` on its `ModHandler`) to get the rule it implemented.

### Matches

| GTCEu decision | GTCEu | TJ now | note |
| --- | --- | --- | --- |
| no vanilla ores | `disableVanillaOres=true` | **true** | the plan's §214 measurement: 0 vanilla ore blocks |
| energy cost of electric items | `energyUsageMultiplier=100` | **100** | |
| iron-family crafting needs plates | `hardIronRecipes=true` | `ironConsumingCraftingRecipesRequirePlates=true` | TJ's own name for the same rule |
| paper, flint-and-steel, bowls, buckets | `hard*Recipes=true` | `nerfPaperCrafting=true`, `flintAndSteelRequireSteel=true`, `bowlRequireKnife=true`, `bucketRequirePlatesAndHammer=true` | |
| overclocking rule | GTCE/GT5-style | `gregicalityOverclocking=false` | *"use CE's tiers for overclocking"* - GTCEu's behaviour, and the stricter of the two (GCY tiers overclock better) |
| dungeon loot | `increaseDungeonLoot=true` | **true** | |

### Deliberate divergences

* **High-tier solar.** GTCEu shipped `enableHighTierSolars=true`; this stack has
  `enableHighTierSolar=false` and `enableSupraSolar=false`. That is not a regression but the owner's
  power rule arriving later - the pack's whole thread about cheap mod/GT generation ends with "GT
  generators, not a cheap panel" - so the TJ value is the one to keep.
* **Wood.** GTCEu had `hardWoodRecipes=true` and `harderRods=true`; this fork's hard-wood pass instead
  leaves `minecraft:planks:0` at four per log and *adds* a saw recipe, and the pack's `forestry_wood.zs`
  header records the decision taken on top of it: "keep the recipe and the output, and re-cost it the
  way GTNH does. For wood that is the saw" - no ingredient dropped, no count lowered. The switches stay
  off because the saw pass is the pack's own work.
* **Vein density** (`minVeinsInSection` 1 -> 0, `additionalVeinsInSection` 0 -> 2, and
  `generateVeinsInCenterOfChunk` false): this fork spreads veins differently. It is covered by the
  pack's own vein port and its measurement (11489 GT ore blocks in the overworld, and the per-planet
  counts in the instance README), so the fork's values stay.

### One decision that had to be rebuilt: EBF-metal smelting

GTCEu shipped `removeSmeltingForEBFMetals=true`, documented as *"Whether Gregtech should remove
smelting recipes from the vanilla furnace for ingots requiring the Electric Blast Furnace."* This fork
has **no such switch**, and the audit's probe found **243** dust-to-ingot furnace lanes in the
finished game - so the question was whether the rule is baked in or lost. Reading GTCEu's own
implementation (`ModHandler.removeSmeltingEBFMetals`) settled both the rule and the answer: for every
furnace lane whose output is a GregTech ingot whose material carries the blast property, with that
material's dust as the input, delete the lane - and the switch was **not** baked into this fork.

`MinespaceMaterialRepoint.pruneEbfMetalSmelting` now reproduces exactly that, in both phases:

```
EBF-metal smelting (postInit pass): 5 dust-to-ingot furnace lanes removed
    (GTCEu's removeSmeltingForEBFMetals): dustSteel, dustTungsten, dustOsmium,
    dustDamascusSteel, dustBlackSteel
EBF-metal smelting (loadComplete pass): 0
```

Those five are the metals *this* fork gates behind the blast furnace; the other 238 lanes belong to
materials it deliberately does not gate (aluminium and titanium among them, both furnace-smeltable
here), so they stay. GTCEu also spared a lane that a CraftTweaker script had added; nothing in this
pack adds a furnace lane - the one script that touches the registry removes AE2's own silicon lane -
so there was nothing to spare and that half is not reproduced.

### Housekeeping

Two config files belong to mods this stack does not have: `config/gcym.cfg` (GCYM was tried and then
replaced by the TJ fork) and `config/sussypatches.cfg` (SussyPatches was part of the parked GTCEu
stack). Both were moved to `%TEMP%\minespace-removed\2026-10-15-stale-configs\` - recoverable, and no
mod reads them.

### Verified

The audit probe was removed, the jar rebuilt (202,435 bytes) and the clean server run reproduced the
baseline exactly: **47 mods**, `Done (6.029s)`, zero `crafttweaker.log` errors, zero `Invalid amount of
recipe inputs`, zero `duplicate or conflict`, the baseline two `Invalid recipe` and two `Input cannot
contain null`, seven grinding-ball recipes, 12 `machine-only enforcement`, 22 `no-double-route` and the
same 19 `Exception` mentions as the archived baseline.

## 6cl. EU <-> FE: the ceiling was on the wrong family, and the names are why - 2026-10-15

This is the "which way does the energy actually go" half of the round: section 6m's rule was written
against a *reading of the two machine names*, and 6bp's probe - the only measurement anyone had made -
asked whether a converter had a crafting recipe, never which direction it converts. Reading the mod
settles it, and it settles it the other way round.

### What the jar says

From `gregicality_tj_fork-0.26.3.jar` (`javap` on `EnergyConverterType`, `ConverterType`, `Energy`,
the traits and `GATileEntities`):

* the two families are the enum constants `CONVERT_GTEU` and `CONVERT_FORGE`, and both carry the
  *same* `ConverterType.GTEU_TO_FORGE`; what separates them is a boolean, `isGTEU` (`true` for
  `CONVERT_GTEU`);
* `getInput(isGTEU = true)` is `Energy.GTEU` and `getOutput(true)` is `Energy.FE`, and the two swap
  when the flag is false - so `CONVERT_GTEU` **takes EU and puts out FE**;
* the traits follow: `Energy.GTEU.createEnergyReceiverTrait` builds `TraitGTEUIn` and
  `Energy.FE.createEnergyEmitterTrait` builds `TraitFEOut`;
* `ratio()` with `EU/FE Ratio = 4.0` gives `1 EU -> 4 FE` when the output is FE (`ratioOf(1, 4)`), and
  `4 FE -> 1 EU` when the output is EU - the same 4.0 that 6m records;
* `isDisabled()` reads `disableEUtoFEConverter` - the switch named *"Disable GregTech EU to FE Energy
  Converters?"* - for the `isGTEU` family, which is the same mapping again;
* the player-visible half: `MetaTileEntityEnergyConverter.addInformation` fills
  `gtadditions.converter.description` ("Converts %s to %s") with the machine's own `getInput()` and
  `getOutput()`, so the machine called **GTEU Energy Converter literally says "Converts GTEU to FE"**
  when hovered;
* `GATileEntities` registers each (tier, amperage) pair in the order GTEU first, Forge second, so in
  every pair **the lower id is the EU-to-FE machine and the higher id is the FE-to-EU one**. 6bp's own
  probe output already had this half right - `convert_gteu.ev.1 -> machine:2932`.

### What was measured

A temporary CraftTweaker probe (`zzz_converter_probe.zs`, deleted again) printed each id's display
name. The 09:25 sample and the 10:07 full sweep:

```
CPROBE 2900 | GTEU Energy Converter (ULV)      CPROBE 2901 | Forge Energy Converter (ULV)
CPROBE 2932 | GTEU Energy Converter (EV)       CPROBE 2933 | Forge Energy Converter (EV)
CPROBE 2940 | GTEU Energy Converter (IV)       CPROBE 2941 | Forge Energy Converter (IV)
CPROBE 2948 | GTEU Energy Converter (LuV)      CPROBE 2949 | Forge Energy Converter (LuV)
CPROBE 2956 | GTEU Energy Converter (ZPM)      CPROBE 2957 | Forge Energy Converter (ZPM)
CPROBE 2964 | GTEU Energy Converter (UV)       CPROBE 2965 | Forge Energy Converter (UV)
CPROBE 4075 | GTEU Energy Converter (UHV)      CPROBE 4076 | Forge Energy Converter (UHV)
CPROBE 4083 | GTEU Energy Converter (UEV)      CPROBE 4084 | Forge Energy Converter (UEV)
CPROBE 4091 | GTEU Energy Converter (UIV)      CPROBE 4092 | Forge Energy Converter (UIV)
CPROBE 4097 | GTEU Energy Converter (UMV)      CPROBE 4098 | Forge Energy Converter (UMV)
CPROBE 4099 | GTEU Energy Converter (UMV)      CPROBE 4100 | Forge Energy Converter (UMV)
CPROBE 4101 | gtadditions.machine.convert_gteu.uxv.4.name    CPROBE 4102 | gtadditions.machine.convert_forge.uxv.4.name
CPROBE 4103 | gtadditions.machine.convert_gteu.uxv.16.name   CPROBE 4104 | gtadditions.machine.convert_forge.uxv.16.name
```

Odd id, name "GTEU..." -> EU to FE. Even id, name "Forge..." -> FE to EU. `power.zs` was removing the
**odd** ids from EV up.

The sweep that was kept covers both registration blocks id by id: 2900..2970 and 4075..4109, every one
of them alternating as above. (ZenScript's `..` stops one short of its upper bound, so 2971 - the UV
16 A `Forge` machine, the only id of the 72 in the first block the sweep did not print - is inferred
from the alternation rather than printed; the run after the change names it and is error-free, which is
the same thing CraftTweaker would refuse to do for an id that does not exist.) The two `UXV` pairs at
4101..4104 printed their raw lang keys instead of a display name, the same server-side unlocalisation
6ce records elsewhere - and the keys say `convert_gteu` / `convert_forge` outright. They are worth
naming because the **old** list stopped at 4099: the ceiling had never seen the UXV pair at all, and
4105 upwards is where the transformers start.

**One trap worth carrying forward**: the same probe first reported `recipes=1` for every single id,
including the ones the pack had already removed, and that is not "the removals never worked". A
CraftTweaker script *reads* the crafting registry while the scripts are still loading, but CraftTweaker
*applies* `recipes.remove` in its own postInit - its log line for those removals ("Removing recipes for
various outputs") is written one phase later. A script can therefore never answer "what does the
finished crafting registry look like"; that needs something after CraftTweaker's postInit (6bp's Java
probe, `loadComplete`) or a look at JEI in game.

### What changed

`scripts/power.zs` now removes and hides the **second** member of each pair - the `convert_forge`
machines, i.e. the FE-to-EU direction - from EV upward: `2933 / 2935 / 2937 / 2939` (EV),
`2941..2947` (IV), `2949..2955` (LuV), `2957..2963` (ZPM), `2965..2971` (UV), then `4076 / 4078 / 4080 /
4082` (UHV), `4084..4090` (UEV), `4092 / 4094 / 4096` (UIV), `4098 / 4100` (UMV) and `4102 / 4104`
(UXV, the pair the old list never named). That is 35 ids where the old list had 33, and the EU-to-FE
family is now untouched at every tier - with one qualification added the same day by 6cn: **UXV is not
a reachable tier in this pack** (its hull has no recipe anywhere, and Gregicality's own hull code stops
at UMV), so its EU-to-FE converters are hidden with the rest of that tier by `uxv_removals.zs`, and
"every tier" means ULV to UMV. The file's
header was rewritten with the evidence above, and the "which family is which" paragraph in 6m and the
one in 6bp carry correction notes.

Two consequences of the day the ceiling sat on the wrong family, worth naming because they are what a
player would have hit:

* **the ceiling did not exist**: the FE-to-EU machine of every tier above HV stayed craftable, so an
  RF-driven base could be carried all the way up - the exact thing the owner's rule forbids;
* **the safe direction died at EV**: because the removed family was the EU-to-FE one, at EV and above
  GregTech power could no longer be spent on a Forestry, Ender IO, Galacticraft, Galaxy Space or AE2
  machine at all.

The UHV-and-up block carries fewer sizes per tier (UHV and UEV four each, UIV three, UMV two, UXV the
4 A and 16 A machines) because Gregicality's second registration loop skips pairs it cannot register:
that is why "EV and up" is 20 ids in the low block and 15 in the high one.

### Verified, and what a look at JEI still has to confirm

The server run after the change reproduced the archived pre-change baseline exactly: **47 mods**,
`Done (1.735s)`, zero `crafttweaker.log` errors, zero `Invalid amount of recipe inputs`, zero
`duplicate or conflict`, the baseline two `Invalid recipe` and two `Input cannot contain null`,
`machine-only enforcement` 10 and `no-double-route` 20 (both in the postInit pass, 0 in the
loadComplete pass, as in the archived run), and the same 19 `Exception` mentions in `latest.log`. The
zero-errors half is the check that matters here: naming an id that does
not exist is an error in CraftTweaker, not a silent skip (`Cannot remove recipes for a null item!`,
`Unable to hide null itemstack!` - the lesson of 6ch), so all 35 ids and all 35 `JEI.hide` calls
resolved.

What could not be re-measured headlessly this round is the finished registry's per-id state: that needs
a Java probe, and the addon build would not run on 2026-10-15 - ForgeGradle hung inside
`MCPRepo.getMCP -> Utils.downloadFile` on a socket read that never returns, and it also does so with
`--offline`, because ForgeGradle downloads the MCP snapshot through its own resolver rather than
Gradle's. (Not a pack problem: the previous build's outputs are intact and the instance jar is
unchanged.) The *mechanism* was measured in 6bp - the ids `power.zs` names do come back without a
recipe - and today's run is clean, so what is left is the JEI side, which is a client-side list and
cannot be read from a dedicated server at all. The check is one search:

* JEI: `Forge Energy Converter` should offer **ULV, LV, MV, HV only** - EV and above must be absent;
* JEI: `GTEU Energy Converter` should be present and craftable at **every** tier;
* hover any one of them: the tooltip says which way it converts ("Converts GTEU to FE" for the GTEU
  family), which is the same fact this section is built on.
- **UXV is complete** (6co, 2026-10-15 - the owner overruled 6cn's retirement). One recipe for
  `hull.uxv` **and one for the UXV machine casing** - the two things Gregicality left out of the tier -
  in the mod's own shapes, and the 56 machines, the sized hatches and the converters that depend on them
  are obtainable again. Nothing in the tier is hidden, and every part the chain asks for was followed to
  its own producer (plate, cables, circuit, reinforced glass, casing). The hull recipe's plate choice
  (Neutronium, the tier's material, in both slots) is the pack's - the mod never wrote one, so there was
  nothing to copy there - and only the two table forms are mirrored, not the assembler variants.
- **The UHV..UXV battery buffers and chargers are the last producer-less family** (25 machines, still
  written in this section). All 25 are in `top_tier_completion.zs` now, in GT's own buffer/charger shape with
  each tier's own material and circuit; verified by 25 `Adding shaped recipe` lines and zero
  CraftTweaker errors. Nothing above UV is producer-less any more.
- **The top tiers' routes are settled** (6cr, 2026-10-15): the owner's call was to keep the machine route and drop the table one, imitating the tiers below. The four Gregicality hulls (3239..3242), the four tier casings, the fusion casing and `ga_armor:8` lost their table recipes, and the pack's own UXV hull and casing are assembler recipes in the tiers' own shapes; all twelve measure table=0 machine=1. Six *low-tier* Gregicality machines (4213/4214/4235..4238) still carry the same dual shape one tier band down - a separate round, recorded in 6cr.
- **MAX is not a tier in this stack** (6cq, 2026-10-15). The voltage table ends at UXV (tier 13); GT's
  "MAX"-labelled machines (hull, buffers, chargers, hatches, rotor holder) run at tier 9, and
  Gregicality's UXV machines are the processing set of the top tier. A MAX-named parallel set was
  written, hit the missing tier index, and was dropped as a duplicate of Gregicality's set - so
  "MAX playable" is already true and needs no new machines. Also from 6cq: the build's ForgeGradle
  hangs were a Java-proxy problem, fixed with `-Djava.net.useSystemProxies=true`.

## 6cm. The UHV+ census: what Gregicality's content actually is in this pack - 2026-10-15

The migration's whole point was *UHV+ content that is actually playable* (section 1), and until this
round nothing in the pack's own work had gone above UV: the only file in `scripts/` that mentions a
tier above UV is `power.zs`, and that is the converter ceiling. So the first question for any content
work is not "what should we add" but "what is already reachable" - and that is measurable.

### The instrument

`MinespaceMachineCensus` (temporary, deleted again) is called from `loadComplete()`, i.e. after
CraftTweaker has applied its actions (6cl records why a script cannot see that state). It walks
`GregTechAPI.META_TILE_ENTITY_REGISTRY` and counts, for every machine's item form, **both** the
crafting-table recipes that produce it **and** the GregTech machine-map recipes that produce it. The
second half is what makes the answer mean anything here: this pack deliberately makes machines *in*
machines (that is the whole "machine-only" rule), so "no recipe on the table" is the normal case and
"no recipe anywhere" is the finding.

### Result

**920 machines** are registered by Gregicality (namespace `gtadditions`):

| how it is obtained | count |
| --- | --- |
| crafting table | 820 |
| only in a machine (a GregTech recipe map) | 37 |
| **nothing produces it** | **63** |

The 63 are exactly three groups, and two of them are known:

* **35 = `convert_forge.*` from EV up** - that is 6cl's ceiling seen from the other side, and it is the
  measurement 6cl owed: the FE-to-EU machines above HV now have *no* producer at all (no table recipe,
  no machine recipe), while the EU-to-FE `convert_gteu` machines carry their table recipe at every
  tier (`convert_gteu.ev.1 table=1`, `convert_gteu.uxv.4 table=1`). The ceiling holds and the safe
  direction is intact, both measured in the finished registry.
* **25 = the UHV-and-up battery buffers and chargers** - `battery_buffer.uhv.1` through
  `battery_buffer.uxv.16` (four sizes on five tiers) plus one `charger` per tier. Nothing makes them:
  not the table, not any machine map.
* **3 = `hull.uxv` and the two base `energy_hatch.input/output.uxv` machines.** The *sized* UXV
  hatches (`.4 / .16 / .64 / .128`) are craftable, and the UHV, UEV, UIV and UMV base hatches are too,
  so UXV is the one tier whose **hull** has no producer.

Also worth recording: **0** machines outside Gregicality's namespace carry a UHV-and-up registry path -
the entire top end of the stack is Gregicality's, hulls and hatches included.

The 37 machine-only machines are, in the order the registry lists them: `monitor_screen` and
`central_monitor`, the three `fusion_reactor` tiers, `void_miner` and its `uhv`/`uev` variants,
`advanced_distillation_tower`, `large_rocket_engine`, `large_naquadah_reactor`, the three `buffer`
tiers, `hyper_reactor.i/ii/iii`, `advanced_fusion_reactor`, `stellar_forge`, `qubit_computer`,
`large_laser_engraver`, `bio_reactor`, `plasma_condenser`, `cosmic_ray_detector`, `electric_implosion`,
`fullauto_maintenance_hatch`, `chemical_plant`, `large_mass_fabricator`, `large_replicator`, the three
`mega_*` machines, the three `fluid_drilling_plant` tiers and `miner.void`. That list is the pack's
intent rather than a defect - a machine that makes machines - but it is the first time it has been
written down in full.

### What it means for the next round of content

* **UHV, UEV, UIV and UMV are complete.** Their hulls, their base energy hatches and every multiblock
  above them - fusion, hyper reactors, stellar forge, qubit computer, the mega machines, the chemical
  plant, the large replicators, the void miners - have a producer. Content can be built on top of
  those tiers.
* **UXV is not.** A player can build the UXV converters, the sized UXV energy hatches and nothing else
  in that tier, because there is no UXV hull. Either it gets a recipe or the tier should be declared
  out of scope and its leftovers hidden from JEI - the pack already has that habit (6ch, 6ci).
* **The UHV+ battery buffer / charger family has no producer at all** (25 machines). Above HV there is
  no way to build an EU buffer or a charger, which is a usability hole in the *tier* rather than in a
  chain: either give the family a recipe (GregTech's own shape is a hull plus batteries, and a charger
  is a hull plus a circuit) or accept buffers as a low-tier convenience and hide the 25 items.
* **Nothing above UV has been priced by this pack.** The census answers "can it be built", not "is it
  priced the way this pack prices things". Gregicality's own costs for the top end are untouched -
  exactly as deliberately as 6m left the converters' prices alone, but this is where a content round
  would start.

The probe was removed, the jar rebuilt (**202,436 bytes**) and deployed, and the clean run reproduces
the baseline: **47 mods**, `Done (1.893s)`, zero `crafttweaker.log` errors, zero `Invalid amount of
recipe inputs`, zero `duplicate or conflict`, the baseline two `Invalid recipe` and two `Input cannot
contain null`, `machine-only enforcement` 10 and `no-double-route` 20 (postInit; 0 in both at load
complete) and the same 19 `Exception` mentions.

### The build, and the hour this round spent on it

Worth writing down because it cost real time and will come back. ForgeGradle hung for over an hour in
its own downloader - twice, at two different stages (`Utils.testServerConnection` while the userdev
plugin is applied, and `MCPRepo.getMCP -> Utils.downloadFile` during `compileJava`) - on a socket read
that never returns. Two things are true about it:

* `--offline` does not help: ForgeGradle fetches through its own resolver, not Gradle's, so Gradle's
  offline mode never sees the request;
* the classic `org.gradle.internal.http.*` timeouts do not help either, because those are Gradle's own
  client. `gradle.properties` now also carries the `sun.net.client.defaultConnectTimeout` /
  `defaultReadTimeout` pair, which covers plain `URLConnection`s - but a remote that trickles data is
  still not timed out by it, and that is what this machine's proxy does on a bad day.

What does work, when the remote is unreachable, is to make the connection fail *fast* instead of
waiting: point the JVM at a dead loopback proxy for one build. `JAVA_TOOL_OPTIONS` is the lever that
reaches the forked build JVM (a `-Dorg.gradle.jvmargs=` on the PowerShell command line does not - it
arrives as a task name):

```powershell
$env:JAVA_TOOL_OPTIONS = '-Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=1 -Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=1'
.\tools\gradle.ps1 --console=plain deployToInstance
```

Both of that round's builds then took 54 seconds, and the "restarted the proxy" the owner did is what
made the first one succeed at all.

## 6cn. UXV is not a tier: the top end gets ruled on - 2026-10-15

6cm ended with two questions for the owner and no answer. This round answers them by measuring what the
UXV machines are actually made of, and the answer for UXV turns out to be the mod's, not the pack's.

### Every UXV machine needs a hull that does not exist

`MinespaceRecipeShapeProbe` (temporary, deleted again, called from `loadComplete`) walked every
crafting-table recipe and printed the ingredients of the interesting ones, then every recipe with
`gregtech:machine:3243` - the UXV Machine Hull - among its ingredients:

* **56 recipes need it**: 46 single-block UXV machines (cluster mill, mass fabricator, replicator,
  dehydrator, decay chamber, greenhouse, disassembler, diode, and the whole GT machine set at that
  tier: macerator, assembler, chemical reactor, arc furnace, plasma arc furnace, ...), the 8 sized UXV
  energy hatches, and the 2 `convert_gteu` UXV converters;
* the hull itself has **no** recipe anywhere - not on the table, not in any machine map.

### Why: the mod never wrote one

Gregicality's `MachineCraftingRecipes` was read out of the jar (`javap -c`): it registers
`ga_hull_ulv` through `ga_hull_umv` and stops. **There is no `ga_hull_uxv` in the mod at all**, so
there is no recipe to remove, re-point or re-cost - the tier's hull was simply never authored, and
everything built on it inherits that. The parts it *would* need do exist (the tier casing is
`gtadditions:ga_machine_casing:4`, the UXV converters are built from `cableGtQuadruple(Neutronium)`,
and the hull shape every other tier uses is `plate/plate/plate` over `cable/casing/cable`), so
completing the tier is possible - it would just be this pack authoring content Gregicality never
finished, which is what the pack's own discipline says not to do.

### What was done instead

Section 6ci's criterion, applied to a whole tier: **an item that has lost the machines it works with
leaves the pack's view.** `scripts/uxv_removals.zs` (priority 796) therefore

* removes the 56 recipes - they exist only on paper, and in JEI they would advertise a machine whose
  ingredient nobody can obtain;
* hides 88 items: those 56, the hull itself, the two base (unsized) UXV energy hatches, and the 25
  UHV..UXV battery buffers and chargers from the paragraph below.

### The battery buffers and chargers

The second 6cm group: Gregicality registers a `battery_buffer.<tier>.<size>` family (four sizes) and one
`charger.<tier>` for UHV, UEV, UIV, UMV and UXV - **25 machines, and nothing produces any of them**,
neither the table nor a machine map. GT's own battery-buffer family covers ULV through UV *and* MAX, so
the function is not lost at those tiers: GT's MAX buffer is the one that can be built and used. These
25 are hidden rather than given invented recipes; if they are ever wanted, the shape to mirror is GT's
own (`battery_buffer_max_1x1` is cable / chest / cable over cable / hull / cable, with the tier's hull
and cable), and the chargers are that recipe plus two tier circuits.

### Verified

The run with the probe still in place, after the script was added:

```
RPROBE --- machine:3243 is an ingredient of 0 crafting recipes
RPROBE --- UXV leftovers: 0 of 59 still have a crafting recipe
```

(The 59 are the 56 plus the hull and the two base hatches - the last three had no recipe to begin with.)
The probe was then removed, the jar rebuilt (**202,435 bytes**, the size it had before this round) and
deployed, and the clean run reproduces the baseline: **47 mods**, `Done (1.802s)`, zero
`crafttweaker.log` errors, zero `Invalid amount of recipe inputs`, zero `duplicate or conflict`, the
baseline two `Invalid recipe` and two `Input cannot contain null`, `machine-only enforcement` 10 and
`no-double-route` 20 (postInit; 0 in both at load complete) and the same 19 `Exception` mentions. Zero
CraftTweaker errors is the check that matters for the new file: an id that does not exist is an error
there (`Cannot remove recipes for a null item!`), so all 56 removals and all 88 hides resolved.

The JEI half of a hide is a client-side fact and cannot be read from a dedicated server (the same note
6cl carries) - the in-game look covers it, together with the converter search in 6cl.

### What this changes around it

* 6cl's ceiling: "EU to FE stays complete at every tier" now reads **ULV to UMV**. UXV is not a tier a
  player can reach, so its EU-to-FE converters are hidden with the rest of that tier rather than left
  craftable - the two files together (`power.zs` and `uxv_removals.zs`) are why no FE-to-EU converter
  is obtainable above HV and no UXV converter is obtainable at all.
* What is left for the owner is a *taste* question rather than a hole: whether to complete UXV (one
  hull recipe in the mod's own shape would unlock 56 machines) or leave it retired. Both are one
  script.
* And the third question from 6cm stands, unchanged and now better informed: **nothing above UV has
  been priced by this pack.** That is where a content round starts - the machinery to check it
  (recipe maps, the crafting registry, the standing guards) is all in place.

## 6co. UXV completed, and what MAX actually is - 2026-10-15

The owner's call, after 6cn: **UXV and MAX both have to be playable.** So UXV is completed rather than
retired, and MAX is measured rather than assumed. The two turned out to be very different jobs.

### UXV: one recipe, and the tier works

6cn retired UXV because 56 recipes need `gregtech:machine:3243` (the UXV Machine Hull) and no recipe for
that hull exists anywhere - Gregicality's own `MachineCraftingRecipes` stops at `ga_hull_umv`. What the
mod never wrote is one recipe, and everything that recipe needs was measured out of the tier's *own*
machine recipes (`MinespaceTopTierProbe`, temporary, deleted again):

| part | the UXV tier's own item |
| --- | --- |
| the tier's circuit | `gtadditions:ga_meta_item:32339` |
| the tier's cable | `cableGtQuadruple(Neutronium)` = `gregtech:ga_cable:7993` |
| the tier's casing | `gtadditions:ga_machine_casing:4` |
| the machines' 1x cable | `gregtech:ga_cable:5993` |

and the shape is the mod's own, read out of its bytecode in 6cn: `plate / plate / plate` over
`cableGtQuadruple / casing / cableGtQuadruple`. `scripts/top_tier_completion.zs` writes exactly that,
with Neutronium - the tier's material - in both plate slots, and with ore dictionary names so whichever
variant is unified to GregTech's own works:

```zs
recipes.addShaped(<gregtech:machine:3243>, [
    [<ore:plateNeutronium>, <ore:plateNeutronium>, <ore:plateNeutronium>],
    [<ore:cableGtQuadrupleNeutronium>, <gtadditions:ga_machine_casing:4>, <ore:cableGtQuadrupleNeutronium>]
]);
```

`uxv_removals.zs` is gone with it - the 56 recipes it removed are Gregicality's own and are back, and
nothing in the tier is hidden any more. Verified in the finished registry (the probe runs at
`loadComplete`, i.e. after CraftTweaker's postInit - the timing 6cl records):

```
QPROBE --- recipe of machine:3243 (gtadditions:hull.uxv)
QPROBE   crafttweaker:ct_shaped-1057928569: [gregtech:meta_item_1:12993] x3 [gregtech:ga_cable:7993] [gtadditions:ga_machine_casing:4] [gregtech:ga_cable:7993]
```

Three GregTech neutronium plates (the ore names resolved to GregTech's own item), two 4x Neutronium
cables and the UXV casing: the tier's own parts in the mod's own shape. With the hull buildable, the 46
single-block UXV machines, the 8 sized energy hatches and the 2 UXV converters that need it are
obtainable again - and the UXV EU-to-FE converters stay craftable, exactly as `power.zs` intends.

### ... except that a hull with an unobtainable ingredient is not a fix

The owner's question the same day - "can those two high-voltage parts be made?" - is the right one, and
the honest answer when it was asked was **no**: a recipe that exists is not a recipe that can be made.
Following every part the new hull recipe asks for through the finished registries (`MinespacePartProbe`,
temporary, deleted again) gave:

| part | producers | how |
| --- | --- | --- |
| `plateNeutronium` (`meta_item_1:12993`) | 2 table + 9 machine | hammer from the ingot, metal bender, alloy smelter, fluid solidifier |
| `cableGtQuadruple(Neutronium)` (`ga_cable:7993`) | 3 table + 2 machine | assembler, and table doubling from 1x / splitting from 8x |
| `1x Neutronium cable` (`ga_cable:5993`) | 1 table + 1 machine | assembler from the tier's wire |
| the UXV circuit (`ga_meta_item:32339`) | 1 machine (assembly line) | the endgame input list, as a top tier should be |
| the UXV reinforced glass (`ga_transparent_casing:6`) | 1 machine (fluid solidifier) | from the tier below's glass |
| **the UXV machine casing (`ga_machine_casing:4`)** | **none - 0 table, 0 machine** | - |

The casing is the second thing Gregicality never wrote for UXV, and it is the same pattern as the hull:
`ga_machine_casing:0` (UHV) and `:3` (UMV) each have a table recipe (eight of that tier's plate around a
hammer - `ga_casing_uhv`, `ga_casing_umv`) *and* an assembler variant, while `:4` (UXV) has neither. My
own hull recipe had just been pointed at it, so the pack would have shipped a hull nobody could build.
`top_tier_completion.zs` now writes that casing too, in the same shape with the tier's own plate:

```zs
recipes.addShaped(<gtadditions:ga_machine_casing:4>, [
    [<ore:plateNeutronium>, <ore:plateNeutronium>, <ore:plateNeutronium>],
    [<ore:plateNeutronium>, <gregtech:meta_tool:8>, <ore:plateNeutronium>],
    [<ore:plateNeutronium>, <ore:plateNeutronium>, <ore:plateNeutronium>]
]);
```

Only the two table forms are mirrored (the hull's and the casing's): the assembler variants the other
tiers have were not measured - their EU/t and circuit settings are part of the recipe - and the table
form is what makes the tier buildable. Measured after the change: **the UXV machine casing now has 1
table recipe** (`Adding shaped recipe for UXV Machine Casing`), and the UMV casing still has its own
1 table + 1 machine. Every part of the UXV chain now has a producer, so the tier is not just
"unhidden" but reachable.

### The battery buffers and chargers are written too

The 25 UHV..UXV battery buffers and chargers were the last producer-less family in the stack: they had
no table recipe and no machine recipe anywhere, and GT's own family stops at UV and then jumps to MAX,
so those tiers had no buffer of their own. `top_tier_completion.zs` now writes all 25, in GT's own shape
read out of `battery_buffer_max_1x1` and the MAX charger:

```zs
cable / chestWood / cable
cable / hull      / cable
             ...and for a charger, a third row of the tier's circuits
```

The cable steps through the tier material's sizes as the buffer's slot count grows (GT's own
progression: its 1-slot buffer takes the 1x cable, its 16-slot the largest of the four), and the four
buffer sizes take the material's single / quadruple / octal / hex cables. The tier's material is the
one Gregicality's own hull recipes use for it (UHV TungstenTitaniumCarbide, UEV Pikyonium, UIV
Cinobite, UMV NaquadriaticTaranium, UXV Neutronium - the first four read out of `MachineCraftingRecipes`,
the last out of the UXV machines' own recipes), and the circuits are each tier's converter circuit,
measured from `convert_gteu.<tier>.1`:

| tier | cable (1x form) | circuit |
| --- | --- | --- |
| UHV | `gregtech:ga_cable:5755` | `gregtech:meta_item_2:32501` (+4 variants) |
| UEV | `gregtech:ga_cable:5854` | `gtadditions:ga_meta_item:32232` (+4) |
| UIV | `gregtech:ga_cable:5856` | `gtadditions:ga_meta_item:32337` (+3) |
| UMV | `gregtech:ga_cable:5993` | `gtadditions:ga_meta_item:32338` (+2) |
| UXV | `gregtech:ga_cable:7993` | `gtadditions:ga_meta_item:32339` (+1) |

Verified the way a CraftTweaker-only change has to be (see below): the run reports **25**
`Adding shaped recipe ... Battery Buffer / Charger` lines and **zero** CraftTweaker errors - the error
count is the check that every ore dictionary name resolved, since an unknown name is an error there and
not a silent skip. With that, nothing above UV is producer-less any more: UHV..UXV have their hulls,
their casings, their machines, their energy hatches, their converters, their buffers and their chargers.

The build could not confirm it in the finished registry this time: the addon build hung again in
ForgeGradle's downloader (6cm's problem, and with the loopback-proxy workaround it failed instead on
`net.minecraft:client:1.12.2` metadata, so the cache is now the part that is stale). The probe written
for it is not in the source tree; the jar in the instance is the previous probe-free build
(**202,436 bytes**), and the recipes are scripts, so they are live either way.

### MAX: measured, and it is not the same job at all

The tier-based census (tiered machines at tier 9 and above) plus a registry-name sweep says what MAX is
in this stack: **19 machines carry a MAX registry path, and none of them lacks a producer.**

| MAX machine | what makes it |
| --- | --- |
| `gregtech:hull.max` (509) | a machine map - the assemble route, like every other hull |
| `battery_buffer.max.1/.4/.9/.16` | crafting table (Gregicality registers a second, duplicate set at 4138..4141, also craftable) |
| `charger.max` | crafting table (and Gregicality's duplicate at 4142) |
| `item_bus.import/export.max`, `fluid_hatch.import/export.max` | crafting table |
| `energy_hatch.input/output.max` | crafting table |
| `rotor_holder.max` | crafting table |

So MAX has its hull, its logistics, its energy blocks and its buffers, and all of it is buildable. What
MAX does **not** have - in this stack or upstream - is *processing* machines: there is no
`macerator.max`, no assembler, no multiblock at that tier, because GT's own single-block machine set
stops at UV and Gregicality's stops at UXV. MAX is GT's endgame *infrastructure* tier (hull, casings,
logistics, energy), which is why the pack's top-tier story is "UHV..UXV are the processing tiers, MAX is
what you build the endgame out of".

Giving MAX its own processing machines is therefore not a repair - it is content this addon would have
to author: the pattern exists (Gregicality registers its single-block set by mirroring GT's
`SimpleMachineMetaTileEntity` per tier, which the addon can do too, at tier 14, reusing GT's own class
rather than writing machine code), and the ids and recipes follow from that, but it is a feature rather
than a fix and it is the owner's call.

### Verified

The probes were removed, the jar rebuilt (**202,435 bytes** in the round's first half) and deployed, and
the clean run is the
baseline: **47 mods**, `Done (1.733s)`, zero `crafttweaker.log` errors, zero `Invalid amount of recipe
inputs`, zero `duplicate or conflict`, the baseline two `Invalid recipe` and two `Input cannot contain
null`, `machine-only enforcement` 10 and `no-double-route` 20 (postInit; 0 in both at load complete),
and the same 19 `Exception` mentions. CraftTweaker's own lines confirm both new recipes are in:
`Adding shaped recipe for UXV Machine Hull` and `Adding shaped recipe for UXV Machine Casing`.

## 6cq. "MAX" is not a tier here, and the build's real problem was Java's proxy - 2026-10-15

Two things came out of the owner's "UXV and MAX both have to be playable": one is an answer, the other
is the reason this session spent an hour fighting the build.

### MAX is not a voltage tier in this stack

The round started as "register a MAX machine set the way Gregicality registers its UXV one", and the
first attempt at it is the measurement: registering a machine at **tier 14** throws
`ArrayIndexOutOfBoundsException: 14` out of `TieredMetaTileEntity.reinitializeEnergyContainer`. This
stack's voltage table has **fourteen** entries, `ULV` (0) through **`UXV` (13)**, and no fifteenth. What
the machines GTCE labels "MAX" actually run at was then measured directly:

```
machine:509  gregtech:hull.max                    tier=9  MetaTileEntityHull
machine:646  gregtech:battery_buffer.max.1        tier=9  MetaTileEntityBatteryBuffer
machine:689  gregtech:charger.max                 tier=9  MetaTileEntityCharger
machine:794  gregtech:energy_hatch.input.max      tier=9  MetaTileEntityEnergyHatch
machine:819  gregtech:rotor_holder.max            tier=9  MetaTileEntityRotorHolder
machine:3258 gtadditions:macerator.uxv            tier=13 GASimpleMachineMetaEntity
machine:4101 gtadditions:convert_gteu.uxv.4       tier=13 MetaTileEntityEnergyConverter
```

So GTCE's "MAX" is a *label* its own code puts on its last tier - which this fork's table maps onto
tier 9 - while the top of the table is Gregicality's **UXV at 13**, and Gregicality's UXV machines are
the processing machines of that top tier. "MAX playable" therefore needs no new machines: the top
tier's machines are Gregicality's UXV set (all of them obtainable as of 6co), and the MAX-labelled
machinery a player builds at the top is GT's hull, buffers, chargers, hatches and rotor holder (all
obtainable as of 6co's census). A MAX-*named* parallel machine set was written and then **dropped**:
at tier 13 it would be a second copy of Gregicality's set at the same voltage, which is the kind of
duplicate this pack removes rather than ships (6ch, 6ci). It is recorded here so it is not re-attempted.

### The build's real problem, found

Every ForgeGradle hang this session (6cm's hour, this round's retries, the failed proxy workaround) had one
cause: **a plain JVM does not use the machine's Windows proxy settings.** This machine reaches the
internet through a proxy configured in Windows; Gradle's own HTTP client honours it, which is why
Gradle could resolve its dependencies, but ForgeGradle fetches the MCP snapshot and the Minecraft
client through its *own* `URLConnection`, and that one ignores the system proxy unless the JVM is told
to use it. Those connections were black-holed: a socket read that never returns, with no timeout. With

```
-Djava.net.useSystemProxies=true
```

the same build takes **eleven seconds**. It is in `gradle.properties` now, next to the two timeout
settings, with the reasoning; the loopback-proxy trick that was tried first is *not* the fix (it makes
the build fail fast on the very artifacts it needs) and is not in the file.

### Verified

The MAX machine class, its lang entries and the probe were all removed again, the jar rebuilt
(**202,436 bytes**) and deployed, and the clean run is the baseline: **47 mods**, `Done (1.904s)`, zero
`crafttweaker.log` errors, zero `Invalid amount of recipe inputs`, zero `duplicate or conflict`, the
baseline two `Invalid recipe` and two `Input cannot contain null`, `machine-only enforcement` 10 and
`no-double-route` 20 (postInit; 0 in both at load complete), and the same 19 `Exception` mentions.

## 6cr. "Pricing" above UV, part one: the tier gate - 2026-10-15

The owner asked what a pricing round is even for, so it is worth writing down before the numbers.
"Pricing" in this pack has never meant "make it expensive". It is three rules, and every one of them
had been applied only up to UV:

1. **no second route** - if an item belongs in a machine, the crafting table must not still offer it
   (6cc, 6ce, and the standing `no-double-route` pass);
2. **no tier skip** - a UHV-era machine has to consume UHV-era industry, not lower-tier parts;
3. **a cost in the shape its tier uses** - the same class of parts, from the same tier, as everything
   else at that voltage.

Above UV none of the three had been looked at: Gregicality's own prices stand there untouched (as
deliberately as 6m left the converters' prices alone), the pack's own new recipes for UXV (6co) have
never been held against rule 3, and nobody had asked whether the top tiers can be shortcut. That is
why it is the prerequisite for content work rather than a polish pass: content built on tiers that can
be skipped is worth nothing, and content on tiers that cannot be reached is worth even less.

### The first measurement: does every machine consume its own tier's hull?

Rule 2, in its sharpest form. `MinespaceTierGateProbe` (temporary, deleted again) takes every machine
Gregicality registers for UHV..UXV and asks whether its crafting recipe contains *that tier's* machine
hull:

| tier | machines | of which consume their own hull |
| --- | --- | --- |
| UHV | 53 | 50 |
| UEV | 52 | 49 |
| UIV | 51 | 49 |
| UMV | 51 | 49 |
| UXV | 51 | 47 |

Every exception is structural, and reading them is the point:

* the tier's **hull itself** (one recipe, and it cannot consume itself);
* the tier's **transformer** (a transformer is hull-less at every tier by GregTech's own design);
* `void_miner.uhv` / `.uev`, which have **no table recipe at all** because they are built in a machine
  map - their gate is in that recipe, which this sweep does not read (the next pass does);
* and, the one real find: **`energy_hatch.input.uxv` and `energy_hatch.output.uxv` have no recipe of
  any kind.** Every other tier's base hatch pair has one, and the *sized* UXV hatches have theirs, so
  these two were the last items in the tier that JEI offered and nobody could build. `top_tier_
  completion.zs` writes both now, in the shape the tier's sized input hatch uses (the tier's 1x cable
  and the tier's hull).

So the gate holds: with the expected structural exceptions, every processing machine at every top tier
consumes its own tier's hull. That is rule 2 measured rather than assumed, and it is the first line of
the answer to "can the top end be skipped".

### Rule 2 for the machines built in machines

Same probe, second pass: for every machine-map recipe whose output is a top-tier machine, does *that*
recipe consume the tier's hull? Only five machines at those tiers are built in a machine at all:

* `hull.<tier>` in the **assembler** - and a hull cannot consume itself; its gate is its own parts;
* `void_miner.uhv` and `void_miner.uev` in the **assembly line** - a multiblock, and multiblocks do not
  take hulls (their gate is the controllers and casings GregTech's own multiblocks use);
* nothing at UXV at all.

So rule 2 holds in both routes, with no exceptions left to explain: **every processing machine at
UHV..UXV consumes its own tier's industry, on the table or in a machine.**

### Rule 1 at the top, and the one decision it leaves

The same walk asked which top-tier items both a crafting table and a GT machine produce: **399**, and
reading the list is what makes the number useful. Almost all of them are Gregicality's *materials*
(`ga_meta_item:*` - plates, dusts, ingots), where a hand recipe next to a machine recipe is GregTech's
own design (the hammer exists next to the bender at every tier) and not a bypass. What is left when the
materials are set aside is a short list of **machine-class items**:

* `gregtech:machine:3239..3242` - Gregicality's UHV..UMV **machine hulls**, which have both a table
  recipe and an assembler recipe;
* `gtadditions:ga_machine_casing:0..3` plus `ga_fusion_casing:0` - the tier casings, likewise;
* `gtadditions:ga_armor:8` and `gregtech:machine:4213 / 4214 / 4235..4238` - the same shape of pair.

GT's own hulls are **assembler-only** (`hull.max`, measured in 6cq: one assembler recipe, no table
recipe), so the tier's dual route is Gregicality's own choice rather than GT's convention. The owner's
call (2026-10-15): **keep the machine route, drop the table route, and imitate the tiers below.** The
machine routes were read out of the finished registries first, so the pack copies shapes rather than
inventing them:

* every hull from UHV to UMV has an **assembler** recipe of two of that tier's cables plus that tier's
  casing, at EUt 16 / 50 ticks (the same shape GT gives its own `hull.max`);
* every tier casing has an **assembler** recipe of eight of that tier's plates plus a programmed
  circuit, same EUt and duration;
* `ga_fusion_casing:0` and `ga_armor:8` likewise have their own assembler recipes.

So `top_tier_completion.zs` removes the table recipes of those ten items and writes the pack's own two
UXV recipes as **assembler** recipes in exactly those shapes - the hull as two 4x Neutronium cables
over the UXV casing, the casing as eight Neutronium plates plus the same programmed circuit, both at
EUt 16 / 50 ticks. Measured after the change, in the finished registry:

```
gregtech:machine:3239..3242   table=0 machine=1        gtadditions:ga_machine_casing:0..3  table=0 machine=1
gtadditions:ga_fusion_casing:0 table=0 machine=1       gtadditions:ga_armor:8              table=0 machine=1
gregtech:machine:3243           table=0 machine=1      gtadditions:ga_machine_casing:4     table=0 machine=1
```

That is rule 1 at the top, in the tier's own shape: how a hull and a casing are made above UV is now
the assembler and nothing else, exactly as it is for GT's own hulls below it.

One thing the same walk turned up *outside* this round's range, recorded so it is not lost: six
Gregicality machines with **low-tier** recipes (`machine:4213`, `4214`, `4235..4238` - their assembler
recipes use the LV hull `machine:501`) carry the same table-plus-machine pair, at LV/MV rather than
above UV. They are the same shape of question one tier band down, and the `no-double-route` pass does
not catch them because it only walks material blocks; that is a separate round.

### Rule 3 against the pack's own recipes

Measured by comparing the shapes rather than by price tags, since this pack's costs are shapes:

| the pack's new recipe | the shape it copies | matches |
| --- | --- | --- |
| UXV hull: 3 neutronium plates, 2 4x neutronium cables, the UXV casing | the UMV hull: 3 plates, 2 cables, the UMV casing | yes - same slots, same class of parts |
| UXV casing: eight neutronium plates around a hammer | `ga_casing_umv`: eight of that tier's plates around a hammer | yes - literally the same shape |
| the 25 UHV..UXV buffers and chargers: the tier's hull, the tier's cables, its chest, the tier's circuit | GT's own `battery_buffer_max_1x1` and MAX charger | yes - GT's own shape with the tier's parts |
| the two base UXV energy hatches: the tier's 1x cable and the tier's hull | the tier's own sized hatch recipe | yes |

So rule 3 is satisfied by construction: every one of the pack's top-tier recipes is a copy of a shape
that already exists at or below that tier, with that tier's own parts in it.

## 6cs. Rule 3 against Gregicality's own machines: the tier shapes are uniform - 2026-10-15

The last piece of the top-end audit: rules 1 and 2 are about routes and gates, rule 3 is about
*shape* - a machine of a tier should be made of that tier's parts, the way everything else at that
voltage is. 6cr checked the pack's own new recipes by hand (all copies of existing shapes). This checks
Gregicality's ~250 top-tier machines the same way, by looking at what each machine's recipe - table or
machine map, whichever it has - actually consumes. The tier's signature parts are its hull, its casing,
its circuit and its own cables.

| tier | machines | consume the tier circuit | shape distribution |
| --- | --- | --- | --- |
| UHV | 53 | 43 | `hull circuit cable` 39, `hull cable` 7, `hull circuit` 3, `hull` 1, `casing cable` 1, `circuit cable` 1, `cable` 1 |
| UEV | 52 | 43 | `hull circuit cable` 39, `hull cable` 7, `hull circuit` 3, `casing cable` 1, `circuit cable` 1, `cable` 1 |
| UIV | 51 | 42 | same as UEV |
| UMV | 51 | 42 | same as UEV |
| UXV | 51 | 42 | same as UEV |

Two things are worth reading off that table, and one exception list.

**Nothing is priced as if it belonged somewhere else.** There is no machine at any top tier whose
recipe consumes none of its tier's signature parts, and the core machine set is *uniform across all
five tiers*: 39 machines per tier at exactly `hull + circuit + cable`. Gregicality prices the top end
by the same rule the pack prices its own content by, which is what rule 3 was asking.

**The exception list is the same list at every tier** - ten machines, in the same roles:

| what | shape | why it is structural |
| --- | --- | --- |
| `hull.<tier>` | casing + cable | the hull itself, now assembler-only (6cr) |
| `energy_hatch.input/output.<tier>` | hull + cable | hatch hardware |
| `transformer.<tier>` | cable | a transformer is a cable device at every tier |
| `rotor_holder.<tier>` (UHV only) | hull | a holder is a hull |
| `plasma_arc_furnace`, `polarizer`, `replicator`, `mass_fab`, `diode` | hull + cable | **no tier circuit** - the one shape that is cheaper than its tier's standard |

The last row is the only finding: five machines take the tier's hull and cables but not its circuit at
*every* top tier, which makes them the cheapest machines of their voltage. It is Gregicality's own
shape, repeated identically at all five tiers, so it is internally consistent and is left as it stands -
recorded here as the one place where a stricter rule 3 would bite, if the owner ever wants the top
machines to cost the same as each other.

The probe was removed, the jar rebuilt (**202,436 bytes**) and deployed, and the clean run is the
baseline (47 mods, `Done`, zero `crafttweaker.log` errors, `machine-only` 10, `no-double-route` 20, 19
`Exception` mentions). With that, all three pricing rules have been measured above UV: **rules 1 and 2
hold, rule 3 holds, and every exception is a shape Gregicality repeats on purpose.**

## 6ct. The complete dual-route list, and the owner's call on it - 2026-10-15

### What "a second route" means here

A single item can be obtainable **two ways at once**: a crafting-table recipe *and* a GregTech machine
recipe (an assembler). Rule 1 says that is one route too many, and the reason is what it does to the
tier: as long as the table also makes a thing, the machine that is supposed to make it is optional, and
the industry the tier is built around can be skipped. One route means the machine is on the critical
path; two means it is a convenience.

### The complete list

6cr could only show the first forty entries of its sweep, so this round asked the finished registries
the narrow question - every `gregtech:machine:*` item that both a table and a machine produce:

**27 items**, in three families:

| family | ids | routes |
| --- | --- | --- |
| Gregicality storage: 6 drums, 6 crates | `machine:2195..2200`, `2207..2212` | table (1-2 recipes) + assembler |
| Gregicality multiblock hatches: maintenance, automatic maintenance, 4x/9x fluid input and output | `machine:4213`, `4214`, `4235..4238` | table + assembler |
| **GregTech's own machine hulls, `hull.ulv` .. `hull.uv`** | `machine:500..508` | table + assembler |
| (for contrast) `hull.max`, the top-tier hull | `machine:509` | assembler only |

That last row corrects a claim this plan made earlier in the same day: 6cr and 6cs read "GT's own hulls
are assembler-only" off `hull.max` alone, and the sweep says otherwise - GT's own hulls from ULV to UV
carry **both** routes, and the single hull GT ships without a table recipe is the top-tier one. That
also explains the shape of the question better than the earlier reading did: the top of the table is
where GT itself stopped writing table recipes for hulls, and the pack's top-tier decision (6cr) extended
that one tier further up rather than inventing a convention.

### The owner's call

**Low-voltage content keeps both routes.** The six Gregicality hatches are LV..IV machines, and the pack
does not go back over GregTech's or Gregicality's own low-tier content to strip a route their authors
wrote on purpose - the same principle that leaves GT's nine hulls and Gregicality's twelve drums and
crates alone. The top-tier change from 6cr stands as its own decision: above UV the pack *wrote* those
recipes, so it decides their shape, and that shape is the assembler.

A `scripts/hatch_routes.zs` was written for the six hatches and withdrawn again within the same round
once the owner ruled; nothing of it is in the instance.

## 6cu. "The ore veins never reached the Galaxy Space planets": measured, two bodies were missing - 2026-10-15

The owner's hunch was that the vein sets only cover Galacticraft's bodies. It is worth recording how it
was checked, because the first glance *looks* like it confirms the fear: the vein folders on disk are
`overworld`, `nether`, `end`, `moon`, `mars`, `venus`, `asteroids`, `ceres`, `barnarda` - one folder per
*set*, not per body. The sets reach further than their names: **one vein file carries a list of
dimension ids**, so a single "moon" set is what Mercury, Phobos, Io, Europa, Ganymede, Enceladus, Titan,
Callisto, Triton, Miranda and both Barnarda moons are mined from. Inverting that mapping - every vein
file's `dimension_id` entries, grouped by dimension - is the actual coverage check:

| dimension | body | veins |
| --- | --- | --- |
| -28 / -29 / -30 / -31 | Moon / Mars / Asteroids / Venus (Galacticraft) | 9 / 14 / 11 / 13 |
| -1005 / -1006 | Mercury / Galaxy Space's Venus | 9 / 13 |
| -1007 / -1008 / -1009 | Ceres / Pluto / Kuiper Belt | 11 / 10 / 10 |
| -1012 / -1013 | Phobos / Deimos | 9 / 9 |
| -1014 / -1015 / -1016 / -1017 / -1018 | Io / Europa / Ganymede / Enceladus / Titan | 8 each |
| -1021 / -1022 / -1023 / -1024 | Triton / Callisto / Haumea / Miranda | 8 / 8 / 10 / 10 |
| -1031 / -1032 | Barnarda C1 / C2 | 9 / 8 |

So the Galaxy Space bodies *are* mined, and the 6b note ("ceres 1, barnarda 1") described the *folders*,
not the coverage. But the sweep did find two real holes, and they are the ones a player notices late:

* **Proxima B (`dimensionIDProxima_B = -1025`)** and **Tau Ceti F (`dimensionIDTauCetiF = -1338`)** had
  **no vein file at all**. Both bodies have a rock and a stone type registered by this addon (they are
  landable, and their ores would have been GregTech's), so they were planets you could reach, mine
  nothing on, and conclude the pack was broken.

Both are now on the rocky-body base set - the same eight veins Mercury, Callisto, Miranda, Triton,
Phobos, Deimos, Io, Europa, Ganymede, Enceladus and Titan are mined from (`bauxite`, `cassiterite`,
`certus_quartz`, `copper`, `galena`, `molybdenum`, `monazite`, `pitchblende`) - by adding the two
dimension ids to those eight files' `dimension_id` lists. Nothing else was touched: no file was added
or removed, and the other twenty-one planet dimensions still resolve to exactly the vein counts in the
table above.

Verified the way a config change has to be (6b's lesson: one malformed JSON aborts the whole vein
reload, not just its own file): the server run reports **`Loaded 111 worldgen definitions`** - the same
count as before - then the usual baseline (47 mods, `Done (1.798s)`, zero `crafttweaker.log` errors, 19
`Exception` mentions).

What a server cannot see is whether ore actually *generates* on a body; that needs chunks in those
dimensions, which is the 6bv harness pattern (mine a box, count the ore blocks) - recorded as the
in-game check for Proxima B and Tau Ceti F rather than claimed.

## 6cv. What the planet vein distribution actually is, and where it comes from - 2026-10-15

The owner asked what the planets' vein distribution looks like and whether it follows GTNH. Both
halves are measurable, and the answer is "the same idiom, this pack's own numbers".

### The distribution

Every body gets one *set* of veins, and a set is a list of vein definitions: a weight (relative
frequency within the set), a height band, a density, an ellipsoid radius pair and a weighted material
mix. Measured, per group:

| set | veins | weights | height bands | the shape of it |
| --- | --- | --- | --- | --- |
| `moon` (Moon, Mercury, Phobos, Deimos, Io, Europa, Ganymede, Enceladus, Titan, Triton, Callisto, Miranda, Barnarda C1/C2, Proxima B, Tau Ceti F) | 8 + `rare_earth_vein` | 16-249, scarce 6 | 5..120 | bauxite/copper/galena dominate; certus quartz only at 80..120 |
| `mars` (Mars, Phobos, Deimos) | 13 + `tungstate_vein` | 12-193, scarce 8 | 5..120 | magnetite and iron are the bulk; `desh_vein` and `sulfur_vein` are Mars-specific |
| `venus` (Venus and Galaxy Space's Venus) | 12 + `gem_vein` | 18-179, scarce 8 | 5..120 | sulfur and tetrahedrite dominate; `solar_vein` is Venus-specific |
| `asteroids` (Asteroids, Ceres, Pluto, Kuiper Belt, Haumea) | 10 + `platinum_vein` + `naquadah_vein` | 4-250, scarce 4/10 | 5..120 | magnetite 250; the two rare ones are the reason to go |
| `ceres` / `barnarda` | `dolomite_vein` / `onyx_vein` | 20 / 15 | 5..40 | one characteristic vein each, for the pack's own materials |

Density is 0.15-0.25 everywhere and the scarce veins are small (radius 6..14 against the base veins'
14..32). The pattern is the one the GC plan states in words: the base veins are the ones a player
trips over, and the five scarce ones - weight 4..20 against 16..250 - are the ones they go looking for.

### Where it comes from

Two layers, and they are worth keeping apart:

* **The idiom is GT5U's, by way of GTCE.** The GTCEu-era files this pack started from described a vein
  with GTCEu's `layered` generator and its `layered` filler, whose four slots are
  `primary / secondary / between / sporadic` - GT5U's own field names, inherited by GTCE and GTCEu.
  `tools/port-worldgen-veins.ps1` (6b) translated that schema into GTCE-TJ's (`ellipsoid` generator,
  `simple` + `weight_random` filler) mapping the four structural slots onto decaying weights, and GT's
  own overworld / nether / end tables - which this pack leaves untouched - are GTCE's, i.e. the same
  GT5U lineage.
* **The numbers are this pack's, not GTNH's.** The planet sets are *not* copies of GT's overworld set:
  the same vein names carry different weights (bauxite 249 on the moon against 90 in the overworld,
  galena 125 against 40), `copper`/`pitchblende`/`certus_quartz` exist as planet veins with no
  overworld counterpart under that name, and the five scarce veins (`rare_earth`, `tungstate`,
  `platinum`, `naquadah`, `gem`) are this pack's own additions - the GC plan records them as added
  after an ore-dictionary probe, precisely because copies of the overworld set "made the planets feel
  the same as the overworld, with nothing rare to look for".

So: GTNH's *classification and shape* (vein families, weight/height/density, the layered slot idea, the
rare-vein-below-the-common-veins idea), this pack's *numbers and per-body assignment* - and the
assignment is one shared definition per filter list, which is why a single "moon" set mines sixteen
bodies and why 6cu's two missing dimensions were a two-line fix.

### Checked against a real GTNH 2.9 instance

The owner pointed at a local GTNH install, so the arrangement could be compared with the source instead
of with its reputation. Read out of `gregtech-5.09.54.133.jar` (GT5U, which is where GTNH's veins live -
there is no vein data file in the instance) and its bundled NEI plugin:

* GTNH's planet ore comes from GT5U's `galacticgreg`, which registers **GT veins**
  (`GalacticGreg.oreVeinWorldgenList`) for the dimensions of **GalactiCraftCore, GalacticraftMars,
  GalaxySpace and AmunRa** - so GTNH mines Galaxy Space bodies too, the same call this pack made;
* a GTNH vein is described by `OreLayerWrapper`: a name, the four-slot mix GT5U has always used
  (`primary / secondary / between / sporadic` - the same slots this pack's pre-migration files had), a
  weight, a size, a density, a height range that **can differ per dimension**, and
  **`allowedDimWithOrigNames`** - an explicit list of the dimensions that vein spawns in. That is the
  same shape as this pack's `dimension_filter`, and GTNH's per-dimension "how common" knob is
  `ModDimensionDef.oreVeinChance`, which is what this pack expresses with weight and density;
* the vein *families* are the same list (`OreMixes`: Naquadah, LigniteCoal, Coal, Magnetite, Gold,
  Iron, Cassiterite, Tetrahedrite, NetherQuartz, Sulfur, Copper, Bauxite, Salts, Redstone, Soapstone,
  Nickel, Platinum, Pitchblende, Monazite, Molybdenum, Tungstate, Sapphire, Manganese, Quartz, Diamond,
  Olivine, Apatite, Galena, ...) - GTCE inherited them from GT5U, so both packs are naming the same
  things.

So the *style* and the *structure* do follow GTNH, and the difference is in the assignment's
granularity: GTNH writes the dimension list per vein (each body ends up with its own combination), while
this pack wrote one set per body *group* - Io, Europa, Ganymede, Enceladus, Titan, Callisto, Triton,
Phobos, Deimos and Miranda all resolve to the identical eight base veins, measured in 6cu/6cv. Where
GTNH's own per-vein dimension lists would have to be read to compare further is inside `OreMixBuilder`
calls in its code (or an in-game NEI vein page / the plugin's `CSVMaker` export), which is the next step
if this pack's planets are to be given distinct ore identities instead of a shared base set.

## 6cw. The planet veins are GTNH's arrangement now - 2026-10-15

The owner's call after 6cv was "copy GTNH", so this round reads GTNH's actual arrangement out of the
GTNH 2.9.0-beta-3 instance they pointed at and applies it to this pack's planet veins.

### Where GTNH's arrangement lives, and how it was read

GT5U defines its veins in code, not in config: `gregtech.api.enums.OreMixes` is an enum whose constants
are built from an `OreMixBuilder` chain -

```
new OreMixBuilder().name("ore.mix.naquadah").heightRange(..).weight(..).density(..).size(..)
    .enableInDim(new String[] { "Overworld", ... })       // vanilla and GTNH's own dimensions
    .enableInDim(new DimensionDef[] { Dim.Moon, ... })    // galacticgreg's planets
    .primary(..).secondary(..).inBetween(..).sporadic(..)
```

so the per-vein planet list is the `DimensionDef[]` array of each constant. `javap -c` on that enum,
parsed per constant, yields it: **78 veins carry a planet list**, saved as
`tools/gtnh-vein-planets.txt` (one `Vein = Dimension,...` per line). Examples: `Bauxite` 13 bodies,
`Tungstate` 14, `Iron` 8, `Nickel` 10, `Platinum` 4.

### The mapping, and the rule for bodies GTNH does not have

GTNH names its planets; this pack knows them by dimension id, so the two were mapped by *name* (Moon
-28, Mars -29, Asteroids -30, Venus -31, Mercury -1005, Ceres -1007, Pluto -1008, KuiperBelt -1009,
Phobos -1012, Deimos -1013, Io -1014, Europa -1015, Ganymede -1016, Enceladus -1017, Titan -1018,
Triton -1021, Callisto -1022, Haumea -1023, Miranda -1024, BarnardC -1030). 23 of this pack's planet
veins have a GTNH mix of the same name (`bauxite_vein` -> `Bauxite`, `certus_quartz_vein` ->
`CertusQuartz`, `tungstate_vein` -> `Tungstate`, ...); **42 files were rewritten** to carry exactly
GTNH's planet list for that vein, and **7 were left alone** because GTNH has no mix of that name
(`scheelite`, `sheldonite`, `solar`, `gem`, `onyx`, `dolomite`, `rare_earth` - the last two and
`rare_earth` because GTNH's own list for them names bodies this pack does not have).

Two rules for the edge cases, both applied and both written down here:

* **Bodies GTNH does not have keep this pack's assignment.** Barnarda C1 (-1031), Barnarda C2 (-1032),
  Proxima B (-1025) and Tau Ceti F (-1338) are landable here and absent from GTNH's lists, so whatever
  veins covered them before still do.
* **Escalation on the way in, mirroring on the way out.** Galaxy Space's Venus (-1006) is the same body
  as Galacticraft's Venus, so it now mirrors -31 exactly (13 veins). Europa was the one body GTNH mines
  *only* with mixes this pack does not have (`Europa`, `EuropaCore`, `Ledox`, `GarnetTin`,
  `MineralSand`), which would have left it oreless; it keeps the rocky base set instead.

### Result

The planets are no longer interchangeable. Before this round every rocky body resolved to the same
eight veins; now each has its own list, straight from GTNH:

| body | veins | body | veins |
| --- | --- | --- | --- |
| Moon | 6 | Phobos / Deimos | 6 / 6 |
| Mars | 12 | Io | 5 |
| Asteroids | 7 | Europa | 8 (base set, see above) |
| Venus / GS Venus | 13 / 13 | Ganymede | 7 |
| Mercury | 6 | Enceladus | 3 |
| Ceres | 7 | Titan | 7 |
| Pluto | 9 | Triton / Callisto | 4 / 4 |
| Kuiper Belt | 9 | Haumea | 8 |
| Miranda | 5 | Barnarda C / C1 / C2 | 1 / 9 / 8 |
| Proxima B / Tau Ceti F | 8 / 8 | | |

### Verified

The per-dimension sweep (every vein file's `dimension_id` list, grouped by dimension) reproduces the
table above from the files on disk, and no body is left without a vein. The server run reports
`Loaded 111 worldgen definitions` - the same count, so every rewritten file still parses (6b's lesson:
one malformed JSON aborts the whole vein reload) - then the usual baseline (47 mods, `Done (1.783s)`,
zero `crafttweaker.log` errors, 19 `Exception` mentions).

### What 100% parity would still need

GTNH mines some bodies with mixes this pack has no file for - `Europa`, `EuropaCore`, `Ledox`,
`GarnetTin`, `MineralSand` at Europa, `LigniteCoal` / `Mica` / `Osmium` / `TungstenIrons` /
`BlackPlutonium` / `SecondLanthanid` / `HeavyPentele` at Barnarda C, and the GTNH-only ores
(`Quantium`, `Mytryl`, `Draconium`, `InfinityCatalyst`, `CosmicNeutronium`, ...) on various bodies.
Their data is in the same `OreMixes` enum (the four slots, height range, weight, density and size are
all in the same builder chain that was parsed for the dimensions), so adding them means writing new
vein files in this pack's format from that table - the natural next step if the owner wants the
planets' ore identities to match GTNH's completely rather than only where a vein with the same name
exists.

## 6cx. "Copying GTNH is not right": the round is withdrawn, and what the schema actually allows - 2026-10-15

The call after 6cw was to copy GTNH's arrangement for the veins this pack has no file for, and that
round was built and run: 38 new vein files written into `config\gregtech\worldgen\gtnh\` from the
`OreMixes` data already parsed for 6cw (height band, weight, density, size, the four ore slots), with
GTNH-only slots dropped. It came back broken, and the owner withdrew the direction for a reason worth
writing down:

> Actually copying GTNH is not right - because 100+ planets are coming, and just these veins and the
> balance won't be enough to work with.

### What the round measured before it was withdrawn

| what the run reported | value | why |
| --- | --- | --- |
| `Loaded N worldgen definitions` | 125 (baseline 111) | 38 files added, 24 dropped by the loader |
| `Failed to parse worldgen definition` | 24 | the two causes below |
| `Exception` mentions | 43 (baseline 19) | 24 of them the parse failures |

Two separate causes, and neither is the one the round was suspected of:

* **8 files were not valid JSON.** `moon\bauxite_vein.json`, `cassiterite`, `certus_quartz`, `copper`,
  `galena`, `molybdenum`, `monazite`, `pitchblende` carried a stray `,` on its own line inside
  `dimension_filter` (and on the last four, a trailing one) - the writer that appended dimensions
  emitted the separator before checking whether anything preceded it. GT parses the array as
  `[..., null]`, `getAsInt` on a `JsonNull` throws, and **that file's whole vein reload is abandoned**
  - the 6b lesson again. `moon\rare_earth_vein.json` had the opposite defect: an **empty**
  `dimension_filter`, i.e. a vein that generates nowhere at all.
* **16 veins name ore blocks this stack does not have.** `OreConfigUtils.getOreForMaterial` throws
  `There is no ore generated for material X` for `chrome`, `titanium`, `tungsten`, `manganese`,
  `vanadium`, `arsenic`, `yttrium`, `samarium`, `uvarovite`, `mirabilite`, `borax`, `nether_star`,
  `neutronium`, `plutonium`, `plutonium241`. These are not missing *materials* - every one is
  registered - they are materials this fork generates **no ore block** for, which is the same reason
  `end\manganese_vein.json` mines `grossular` / `spessartine` / `pyrolusite` and not `manganese`. So
  GTNH's roster is not portable by construction: its titanium, tungsten, chrome and manganese veins
  have no vocabulary here at all.

The name collisions the round was expected to trip over are **not** an error: GT registers several
files under the same `name` without complaint, and this pack depends on that.

### What the schema actually allows (read out of the jar, not assumed)

This is what decides what a 100+ planet pack can and cannot do, so it was read from the bytecode of
`gregtech_tj_fork-1.18.3.jar` rather than from the documentation:

* `CachedGridEntry.triggerVeinsGeneration()` picks up to
  `ConfigHolder.minVeinsInSection + gridRandom.nextInt(additionalVeinsInSection + 1)` veins **per 3x3
  chunk section**, drawing from the body's vein list by weight and **without replacement**;
* that count is a **global** setting - this pack's `config\gregtech.cfg` has
  `minVeinsInSection=0` and `additionalVeinsInSection=2` - so it is 0..2 veins per section on *every*
  dimension, planets included;
* `weight` belongs to the vein definition (the file). `WorldOreVeinCache` builds the per-dimension
  list as `weight x biomeWeightModifier(biome)`, and there is **no per-dimension weight multiplier**.

Three consequences:

1. **Weight is a share, not a density.** `w / SUM(w)` is the chance that vein is the one drawn.
   Equalising the totals across bodies changes nothing; it only makes the numbers readable.
2. **"This body has more ore" is not expressible.** The four per-body knobs are which veins are in
   the filter, their weights (share), the filler's ore mix, and the height band. A pack that wants a
   rich body next to a poor one has to say so through composition - or raise
   `additionalVeinsInSection`, which applies to the overworld too. The one near-miss is
   `biomeWeightModifier`, which keys on the *biome*, not the dimension.
3. **Giving one vein a different share on different bodies needs a second file with the same name.**
   That is why `galena` exists three times (`moon` 125, `mars` 48, `asteroids` 30) - not sloppiness,
   the only mechanism the format offers.

### The state the arrangement was actually in

A sweep of all 111 files, grouped by dimension and by name:

| measurement | value |
| --- | --- |
| files / distinct vein names | 111 / 78 |
| `(dimension, name)` pairs registered more than once | **74** |
| worst case | `galena` on Triton, Ganymede, Venus, Mars, Moon and GS Venus - **4 files each** |
| per-body weight totals | 6 (Europa) to 2615 (overworld) |
| bodies with a single vein in the filter | 2 (Europa, Barnarda C) |

Two of those are player-visible bugs rather than design questions. With one vein in the filter that
vein is **100%** of the body's sections, so Europa was a pure rare-earth mine and Barnarda C a pure
salt mine; and a four-fold `galena` registration enters the draw four times. Europa is also a
regression from what 6cw recorded ("Europa keeps the rocky base set", 8 veins) - the round dropped
that special case.

**Fixed, and nothing else changed:** the eight rocky base veins carry `-1015` again (Europa has 9
veins, no duplicates), the eight malformed `moon` files are repaired, `rare_earth` generates on the 16
rocky bodies again, and the 38 GTNH files are parked **outside** the loaded tree, in
`Minespace-unofficial\tools\vein-staging\gtnh\`, so nothing is lost while the direction is open.

Verified the way a config change has to be: `Loaded 111 worldgen definitions`, 47 mods,
`Done (1.783s)`, zero `crafttweaker.log` errors, 19 `Exception` mentions - the baseline exactly.

### What a 100+ planet pack needs instead

The owner's reading is that the roster (78 names, about 30 of them used by the planets) plus
hand-written per-body lists cannot carry 100+ bodies. What follows from the schema above is three
layers - written down as the proposal it still is; **nothing below is applied yet**:

1. **Archetype.** A body belongs to one of ~8 physical archetypes (airless rock, thick-atmosphere
   rock, icy moon, volcanic moon, metallic asteroid, large moon, gas-giant moon, exotic world), and
   the archetype owns a *vein suite*: which veins, and each one's **share** out of 1000.
2. **Identity.** A body is its archetype plus, optionally, one **signature vein**, which takes its
   share from the archetype's base veins. This is what gives a body a reason to be visited, and it is
   the only axis of freedom the schema actually has.
3. **Region.** At 100+ bodies the signatures are grouped per star system rather than per body, so the
   number of distinct experiences is `archetypes x regions`, and adding a system is one table entry.

The roster grows the same way. The vocabulary is wider than the current file set: the 111 live files
use **130** distinct `ore:` values, and the 22 staged GTNH files that *do* parse add eight this pack
has never mined - `iridium`, `osmium`, `uranium`, `vinteum`, `opal`, `jasper`, `pyrochlore`,
`saltpeter` - so new suites can be built without touching GT's own overworld / nether / end tables.

The mechanical half falls out of the layering: the archetype table is the source of truth and a
generator writes each vein file's `weight` and `dimension_filter` from it - one row per body, and the
74 duplicate registrations become impossible by construction rather than by care.

### Still open

The archetype list itself, and what each suite contains, are balance decisions. They are the owner's
call, and precisely what the withdrawal was about.

## 6cy. "The planets are mine to build": can this addon own the vein table? - 2026-10-15

The answer to 6cx's closing question came back as a decision rather than a number: the 100+ bodies are
going to be built **by the owner, in this addon**, not by a Galaxy Space expansion or a second planet
mod. That moves the vein question from "how do we maintain a hundred config lists" to "can the planet
table and the vein table be the same object", so it was measured with a temporary probe class
(`MinespaceVeinRegistrationProbe`, called from this mod's `loadComplete`; deleted again afterwards, and
the re-deployed jar verified probe-free - 0 `VPROBE` lines, 111 definitions, 47 mods,
`Done (1.761s)`, 19 `Exception` mentions).

### What the probe found

| step | result |
| --- | --- |
| `WorldGenRegistry.getOreDeposits()` | `Collections$UnmodifiableRandomAccessList` - readable (44 entries for the overworld, the 44 overworld files) but `add` throws `UnsupportedOperationException` |
| the field behind it, `registeredDefinitions` | a plain `java.util.ArrayList`, and a *different object* from what `getOreDeposits()` returns - GT wraps a fresh unmodifiable view per call |
| `new OreDepositDefinition(name)` | constructible from the addon |
| `initializeFromConfig(JsonObject)` | **works**: 10 keys parsed, `weight` / `density` / `heightLimit` read back, shape, filler and populator all non-null - the shape / filler / populator factories are live by `FMLLoadCompleteEvent` |
| `ctCheckDimension(0)` at load complete | `NullPointerException` in `DimensionManager.getProvider` - the CraftTweaker bridge is not usable that early; `getDimensionFilter()` is |
| `ctCheckDimension(0)` once the server has started | `true` |
| `getCachedBiomeVeins(overworld, biome)` | callable from the addon, 44 entries; the cache is built lazily per provider |

So a definition can be built *and* initialized from the addon, but it **cannot be appended through the
public API**. Three ways in, in increasing order of hack:

1. **Ship the veins as config JSON, generated from the addon's table.** GT's own loader, no private
   state touched. The file count is bounded by *veins x share groups*, not by bodies: one file per
   (vein, share group) whose `dimension_filter` lists every body of that group, so 100+ planets cost
   dimension ids inside roughly 120 files rather than 120 new files per planet.
2. **Reflection onto `registeredDefinitions`** - append to the real `ArrayList` at
   `FMLLoadCompleteEvent`, before any provider's cache exists, so `oreVeinCache` needs no
   invalidation, and nothing is generated at all. Depends on a private field name GT never renames
   (its jar is not reobfuscated) and on no reload happening afterwards.
3. **A mixin on `WorldGenRegistry`** doing the same append inside GT's own code path. This pack ships
   mixins (MixinBooter), so it is available - it is just more machinery than adding data warrants.

**Recommended: (1)**, with the archetype table as the single source of truth and a generator writing
the files from it. It keeps `Loaded N worldgen definitions` meaningful, keeps the veins visible in JEI
and in the instance, and touches no private state. (2) is recorded as the fallback if the owner would
rather have zero generated files.

### What the probe also settled

The load order, which 6cx had to guess: GregTech loads its files **before** this mod's `loadComplete`
(`Loaded 111 worldgen definitions` at 15:50:16, this mod's `loadComplete` at 15:50:20, the server
started at 15:50:22), so an addon that is `required-after:gregtech` runs after the list is populated -
and every provider's vein cache is still empty at that point.

Not settled: whether an append made *after* a provider's cache exists becomes visible. The probe could
not test it, because the append is the step that failed. It does not matter for either mechanism above
(both append before any world exists), and it is the reason the recommendation does not lean on the
cache being live.

## 6cz. The planet plan has a spec now: "GTCEu星系整合包详细实施方案" - 2026-10-15

The owner supplied the design document the 100+ planets are to be built from - *GTCEu 星系整合包
详细实施方案 V1.0*, 2026-10-10, written for the GTCEu stack this pack has since migrated off ("this was
the GTCEu plan, but the gameplay and content depth are the same"). A text extraction is kept next to
the other reference data at `tools\gtceu-galaxy-plan.txt`; the original is a `.docx` on the owner's
desktop. This section records only what binds the vein work, and the places the document and this pack
disagree.

### The rules that bind the veins

| the plan says | section | consequence here |
| --- | --- | --- |
| every body carries **5..8 veins** | 5.4, 4.2 | an arrangement of 1..44 veins per body has to be rebuilt |
| diversity comes from **combinations, not new ores** | 5.4, 4.2 | the roster stays at the 130 `ore:` values already in use; variety is the mixing |
| each vein **must carry a geological reason** in the body's 地质设定卡 | 5.4, 4.2 | the per-body list stops being an assignment and becomes a derivation |
| a vein = 主矿 / 伴生矿 / 副产物 / 生成权重 / 环境偏好 | 5.4 | already this pack's file schema - see the mapping below |
| **no ore generates twice and none is missing** | 4.1 | 74 duplicate `(dimension, name)` pairs are a stage-one **FAIL**, as is any dead definition |
| the 12 solar-system bodies all carry geology-driven veins = the 90-day goal | 1.2, 4.2 | stage two in this plan's own numbering is that goal |
| the Moon is the gold standard and runs first | 5.4, 8 | the first body to be rebuilt, at 5..8 veins |
| every material a voltage tier needs must be obtainable inside the space that tier unlocks | 2.2, 4.2 | a resource-closure table per tier, driving what each body must carry |

### The plan's vein spec is this pack's file schema

The five fields the plan names map one-to-one onto what a vein file already holds, which is why the
"unified vein-variant data structure" the plan asks for at stage one is a *naming and rules* exercise
rather than a new format:

| the plan's field | where it lives |
| --- | --- |
| 主矿 primary | first entry of `filler.value.values`, the highest weight |
| 伴生矿 secondary | second entry |
| 副产物 byproduct | the remaining entries |
| 生成权重 weight | `weight` - and per 6cx this is a *share* within one body's list |
| 环境偏好: body | `dimension_filter` |
| 环境偏好: depth | `min_height` / `max_height` |
| 环境偏好: biome | `biome_modifier` (unused by this pack's planet veins so far) |

### What the acceptance criteria say about the state this pack is in

`tools\accept-planet-veins.ps1` turns the plan's countable criteria into numbers, because checking them
by flying to twenty-one bodies is neither repeatable nor cheap. First run, against the arrangement as
6cx left it:

| criterion (plan 4.1, 5.4) | result |
| --- | --- |
| the Moon shows at least 3 veins | **OK** (13) |
| no vein file fails to parse | **OK** (111 files, 0 failures) |
| no ore generates twice on the same body | **FAIL - 74 pairs** |
| no body is left without a vein | **OK** |
| every body carries 5..8 veins | **FAIL - 1 body below, 22 above** |

The spread the script prints is the one to keep in view: **Barnarda C at 1 vein, Venus and GS Venus at
27, Mars at 24, the Kuiper Belt at 17, Ganymede at 16**. The plan asks for 5..8 on every body, so most
of these are two to four times over.

...and the script found a defect class nobody had looked for: **3 definitions carry no
`dimension_filter` at all**, so they generate nowhere - `ceres\dolomite_vein.json`,
`mars\certus_quartz_vein.json`, `venus\certus_quartz_vein.json`. That is the same silent hole 6cx
repaired in `moon\rare_earth_vein.json`, and it survived because a definition that generates nowhere
parses perfectly and is counted in `Loaded 111 worldgen definitions` like any other.

Of the 20 solar-system dimensions, the veins supply **67 distinct ores** today. That list is the input
the resource-closure check (plan 2.2) needs; the check itself needs the material set each voltage tier
consumes, which comes from the recipes and is the next step after the Moon gold standard.

### Where the plan and this pack disagree

Three conflicts, all of them consequences of the migration rather than of the design:

* **Body count.** The plan counts **12** solar-system bodies; this pack has **17** (Galacticraft's
  Moon, Mars, Venus and Asteroids, plus Galaxy Space's Mercury, Ceres, Pluto, Haumea, Phobos, Io,
  Europa, Ganymede, Callisto, Enceladus, Titan, Miranda and Triton). The stage goal becomes 17.
* **Dimension ids.** The plan's table (exoplanets from `-100`, gas giants `-110`, deep space from
  `-120`) was written without Galaxy Space's real allocation, which this pack already uses: `-1005`
  through `-1032` and `-1338`. New bodies therefore have to be planned around the occupied range, and
  the plan's reuse mechanism (planet dimension + era variable) has to be checked against what Galaxy
  Space does with its ids before it can be relied on.
* **The delivery mechanism.** The plan says vein generation is `GTCEu WorldGenLayer` plus KubeJS. This
  stack's GT fork has neither: veins are `config\gregtech\worldgen\**\*.json`, and 6cy measured that
  the addon cannot append to the registry at runtime. So the plan's *intent* (data-driven,
  script-assisted, per-body) holds, and its *instrument* is the generated-JSON route 6cy recommended.

### The next step, in the plan's own order

The plan's stage-one weeks one and two are: define the unified vein-variant structure, then run the
Moon as the gold standard (three variants, verified in the acceptance world), with the one-click
acceptance script alongside - which this section has now started. The body-by-body rollout is stage
two, and its driver is the resource-closure table rather than taste.

## 6da. The vein-variant structure, and the Moon as the gold standard - 2026-10-15

6cz turned the planet work into an acceptance list; this round does the first two items of the plan's
own sequence (weeks one and two: define the unified vein-variant structure, then run the Moon as the
gold standard). Two new tools carry it, and nothing about the old arrangement is left implicit.

### The structure: one table, files derived from it

`tools\planet-veins.psd1` is the single source of truth. A `Bodies` entry is a body (display name,
dimension id, folder, geology card); a `Variants` entry is one vein - primary / secondary / byproduct
ores with shares that must add to 100, a weight, a depth band, an ellipsoid radius, a surface rock and
the geological reason the plan demands. A variant's `Bodies` list is the assignment, so
`dimension_filter` is derived rather than typed.

`tools\build-planet-veins.ps1` writes the files and enforces three invariants:

1. **A body's vein list is exactly the variants that name it**, so one body can never carry the same
   vein name twice - which is what 6cx's 74 duplicate `(dimension, name)` pairs were.
2. **A managed body's dimension id is removed from every other vein file.** That is the mechanism
   that ends the cross-folder drift, where the `moon` folder was quietly mining Mars, Venus, the
   Kuiper Belt, Barnarda C1 and Proxima B.
3. **Every ore and every surface rock must already be in use by a vein file in the config today.**
   The last server start reported zero parse failures, so that set is exactly the ores this fork has
   blocks for - the check that 6cx would have needed, where 16 GTNH veins named materials that exist
   without an ore block and GregTech refused the whole definition.

A managed body also owns its folder: files in it that the run did not write are deleted, and bodies
the table does not manage are left byte-for-byte alone, so the migration runs one body at a time.

**The naming rule came out of a measurement.** `GTOreInfo.makePrettyName` builds the JEI page title by
replacing `.` and `_` with spaces and never consulting a lang file, so the pack's existing names show
up as *"gregtech veins ore bauxite"*. A vein name is therefore written to *read* as a title -
`Mare_Ilmenite_Vein` becomes "Mare Ilmenite Vein" - and the generator refuses a name claimed twice.

### What was rebuilt

| body | before | after | the geology card's line |
| --- | --- | --- | --- |
| Moon (-28) | 13 veins, 4 duplicated names | **7, none duplicated** | mare ilmenite / highland anorthosite / impact iron-nickel / mare sulphide / impact platinum / KREEP rare earth / impact diamond |
| Europa (-1015) | 1 vein, then 0 | **6** | a stack, not a scatter: brine in the ice shell, the crystalline shell, tidal hydrothermal sulphides, the silicate mantle, the metal core, ocean-floor PGM |
| Barnarda C / C1 / C2 | 1 / 10 / 9, all duplicated | **6 each** | provisional frontier suite plus the pack's own onyx as the signature |
| Proxima B (-1025) | 9 | **5** | provisional frontier suite; the brine vein is what says "habitable zone" |
| Tau Ceti F (-1338) | 9 | **5** | provisional frontier suite |

The Moon's seven are the plan's shape: two that dominate (ilmenite 27.5%, iron-nickel 27.5%), two that
carry the body's character (anorthosite 24.8%, sulphide 12.4%) and three scarce ones down to 1.7%.

### Two things the round found the hard way

* **The `moon` folder was the only coverage for five other bodies.** Deleting it left Barnarda C2,
  Proxima B and Tau Ceti F with *no* veins at all and Europa with none either - the same class of hole
  6cu opened this whole thread with. All of them are in the table now, which is why the round ended up
  covering seven bodies rather than one.
* **The acceptance script could not see a body with no veins.** It iterated the dimensions *present in
  the files*, so a body with zero veins produced no row and no failure - a false OK. It now iterates
  the known body list and reports `MISSING`, and it counts definitions that generate nowhere
  (no `dimension_filter`) as a FAIL of its own.

### Verified

`Loaded 120 worldgen definitions` (was 111; +19 new, -9 old Moon files, +1 Europa folder), zero parse
failures, 47 mods, `Done (1.789s)`, zero `crafttweaker.log` errors, 19 `Exception` mentions - the
baseline. The audit script's criteria now read:

| criterion | before this round | now |
| --- | --- | --- |
| the Moon shows at least 3 veins | OK (13) | **OK (7)** |
| no vein file fails to parse | OK | **OK** |
| no ore generates twice on the same body | FAIL - 74 | **FAIL - 49** (the 18 bodies not yet rebuilt) |
| no body is left without a vein | OK *(false - it could not see them)* | **OK (real)** |
| every body carries 5..8 veins | FAIL - 1 below, 22 above | **FAIL - 2 below, 11 above** |
| no definition generates nowhere | not checked | **FAIL - 3** |

### What is left, in order

1. **The other eighteen solar-system dimensions** (Mars, Venus/GS Venus as one body, Asteroids,
   Mercury, Ceres, Pluto, the Kuiper Belt, Phobos, Deimos, Io, Ganymede, Enceladus, Titan, Triton,
   Callisto, Haumea, Miranda), each with its card - the plan's stage two, and the source of the
   remaining 49 duplicates.
2. **Three dead definitions** are waiting for that pass: `ceres\dolomite_vein.json`,
   `mars\certus_quartz_vein.json` and `venus\certus_quartz_vein.json` have no `dimension_filter` at
   all - they were dead before this round and are recorded rather than silently adopted.
3. **The resource-closure table** (plan 2.2), whose input the audit already prints: the solar system
   supplies 64 distinct ores today.
4. **The four frontier bodies keep provisional cards** until the plan's stage three gives each its own.

## 6db. The rest of the solar system, and two traps the tooling now catches - 2026-10-15

6da did the Moon as the gold standard and the four nearby-system bodies that had been living off the
`moon` folder. This round does the other fourteen solar-system bodies - Mars, Venus (with GS Venus as
the same body), the Asteroids, Mercury, Ceres, Pluto, the Kuiper Belt, Phobos, Deimos, Io, Ganymede,
Enceladus, Titan, Triton, Callisto, Haumea and Miranda - and every countable criterion the plan sets
for the stage now passes.

### The shape of it

| the plan asks for | where it came from |
| --- | --- |
| Mars: a colder, rusted Earth that lost its air | basalt / hematite, the water history as sulphates and evaporites, the Martian metal (desh) and the Mo-W pair, plus a scarce incompatible-element vein |
| Venus: high-temperature sulphides (the plan names this) | primary sulphides, the resurfaced basalt, **the acid cloud deck as a 40..90 vein** - the one ore in the system that forms in the sky - evaporites, high-pressure corundum gems, volatile cinnabar, and the pack's own solar |
| the Asteroids: planetesimals that never became a planet | M-type metal (meteoric iron, literally), S-type silicate, C-type carbonaceous, PGM, diamond, tungsten and naquadah |
| Mercury: unoxidised metal and impact PGM (the plan names this) | core metal, thin silicate shell, primary sulphide, graphite (Mercury's dark surface), impact PGM |
| Io: the volcanic sulphur system (the plan names this) | sulphur, the ultramafic lava, the other sulphides, alkali plume salt, PGM |
| Titan: low-temperature hydrocarbons and nitrogen (the plan names this) | hydrocarbons as oilsands/coal/graphite, the nitrogen haze as a 40..90 vein with niter standing in, over the ice and silicate suites |
| the icy dwarf planets and KBOs | a shared icy suite (silicate, volatile, rare earth, crystal, carbonaceous) plus one signature each: Ceres' carbonates, Pluto's tholins, the Kuiper Belt's naquadah |
| the moons that never differentiated | the same shared suites - Callisto, Miranda, Haumea and Triton get the icy five and no signature, which their cards say in as many words |

Reuse is the point, not a compromise: forty of the fifty-five variants are shared by more than one
body, which is how the plan's "diversity from combination rather than new ores" survives a hundred
planets.

### Trap one: a folder is not owned by the body it is named after

Deleting `mars`, `venus` and `asteroids` left **fourteen bodies with no veins at all** - the moons,
the dwarf planets and the Kuiper Belt had been living off those three folders, the same way five
bodies had been living off `moon` in 6da. The lesson is not "be careful": it is that coverage is a
property of the whole tree and cannot be reasoned about folder by folder.

`build-planet-veins.ps1` now measures every dimension's vein count before and after a run and prints
`WARNING - these dimensions had veins before this run and have none now` for any that go to zero. The
guard is what makes the rest of the migration safe to do in bulk.

### Trap two: a hand-written vocabulary is not evidence

Deleting the old files also removed the last references to five ores, and the generator's own
vocabulary check (6da's invariant 3, "every ore must already be in use") then rejected the two that
needed restoring. That check was right to, and the fix was to give it an explicit baseline file,
`tools\ore-vocabulary.txt`, seeded from a config state that had loaded cleanly.

Then the loader rejected three names that were in that baseline: **`sheldonite` is not a material in
this fork at all** ("Material with name sheldonite not found"), and **`silicon` and `perlite` are
materials whose ore block this fork does not generate** ("There is no ore generated for material
silicon"). Two real ores came back where geology wants them - `meteoric_iron` into the belt's metal
vein, `molybdenum` into Mars' Mo-W vein - and the three bad names left the table and the baseline.

The durable part is the rule that came out of it: `-UpdateVocabulary` now rewrites the baseline from
**only what the config actually uses**, so it can never refresh itself from its own guesses, and it is
run after a server start that parsed cleanly. A hand-kept list is a hypothesis; a loader run is
evidence.

### Verified

`Loaded 117 worldgen definitions` (111 before 6da), **zero parse failures**, 47 mods,
`Done (1.814s)`, zero `crafttweaker.log` errors, 19 `Exception` mentions - the baseline. All six
countable criteria pass, for the first time:

| criterion | result |
| --- | --- |
| the Moon shows at least 3 veins | **OK** (7) |
| no vein file fails to parse | **OK** (117 files, 0 failures) |
| no ore generates twice on the same body | **OK** (0 duplicate pairs, was 74) |
| no body is left without a vein | **OK** (0 of 25 empty) |
| every body carries 5..8 veins | **OK** (0 below, 0 above, was 1/22) |
| no definition generates nowhere | **OK** (0, was 3) |

The solar system supplies **64 distinct ores** across its twenty dimensions (62 before the round, and
none of the pack's own materials - desh, solar, onyx, dolomite, meteoric iron - was lost).

### What is left

1. **The resource-closure table** (plan 2.2) is now the only stage-two item outstanding, and its input
   is the 64-ore list the audit prints.
2. **The four frontier bodies** keep provisional cards until stage three.
3. **A balance pass** has not been done at all: the shares in the table are defensible but they are
   the first draft, and the plan's own criterion is that every vein has a geological reason - not that
   the ratio between them is right yet.

## 6dc. The resource-closure checklist, and the one material that lives too far out - 2026-10-15

The plan's rule 2.2 - every material a voltage tier needs must be collectable inside the space that
tier unlocks, with stage two's acceptance being "EV materials 100 percent obtainable inside the solar
system" - is the only stage-two deliverable 6db left. It needs two halves that no single source has:
what GregTech gives an ore block to, and what the veins supply, in which space.

### The two halves

* **Demand** comes from the registry, not from a file: `DustMaterial.oreByProducts` is the only place
  a chain like "ilmenite gives iron and rutile" is written down, and rutile is where this pack's
  titanium comes from. A temporary probe (`MinespaceOreClosureProbe`, deleted after the run - the
  re-deployed jar verified at 0 `VPROBE` lines) walked all 794 materials and wrote out which of them
  have an ore block and what each one yields: **164 of 794 have an ore block**, kept in
  `tools\ore-registry.txt`.
* **Supply** comes from the config: every `ore:` value the vein files generate, classified by the
  space that unlocks it - the solar system (EV), the overworld / nether / end (reachable from the
  start, and therefore inside every tier's unlocked space), or a nearby system (IV).

`tools\check-resource-closure.ps1` joins them. A material is reachable when a vein supplies its ore or
when it is a byproduct of something reachable, followed transitively.

### What it says

| measurement | value |
| --- | --- |
| materials in the registry / with an ore block | 794 / **164** |
| ores the veins actually generate | **127** - 64 in the solar system, 62 in the overworld / nether / end, **1 only in a nearby system** |
| materials reachable from the solar system alone (ores plus byproduct chains) | **116** |
| materials reachable once the vanilla dimensions count too | 173 |
| ore-bearing materials no vein sources, directly or as a byproduct | **21** |

### The finding that matters

**`onyx` is the only material in the pack whose sole source is beyond the solar system.** It comes from
Barnarda C, which unlocks at IV, so under 2.2 nothing before IV may need it. That is exactly the kind
of hole the checklist exists to find, and the plan already says what to do about it: fill it with a
vein variant rather than a new ore. Whether it *needs* filling depends on who consumes onyx and at
which tier, which is the next question - the item is recorded here rather than acted on, because
moving a pack material's only source is a balance decision, not a bug fix.

The other twenty are **not** actionable yet, and the reason is worth writing down: the byproduct-only
closure is a *strict lower bound*. It does not follow decomposition (`Material.materialComponents`,
which is how `iridium` and `osmium` come out of `iridium_metal_residue` - a material the solar system
does reach) and it does not follow chemical routes (which is how the carbonate and sulphate minerals
on the list - celestine, witherite, barytocalcite, caliche, fluoroapatite, rhodocrosite - are made).
So the list is a candidate set for 2.2's "fill the gaps with vein variants", not a verdict. Adding
decomposition and the recipe graph to the closure is the refinement that turns it into a verdict.

### A bug the round found in its own tooling

The nether's `precious_vein.json` writes its filler values as `ore:poor:precious_metal`,
`ore:rich:gold`, `ore:pure:precious_metal` - **GalacticGreg's quality-prefixed form**, in a file whose
filler type is GalacticGreg's `ga_simple` rather than this fork's `simple`. All three of the scripts
added in 6da/6db read an `ore:` value as its *first* segment, which turned those qualities into three
phantom ores (`poor`, `pure`, `rich`) in the vocabulary and made the closure check report a real
material as a gap. Fixed in all three, and the refreshed vocabulary dropped the phantoms - the
baseline is 127 ores again.

### Verified

The probe is gone and the jar redeployed: `Loaded 117 worldgen definitions`, 0 `VPROBE` lines, 47
mods, `Done (1.785s)`, 19 `Exception` mentions. `accept-planet-veins.ps1` still passes all six
criteria, and the closure checklist runs from the two files with no game running.

### What is left in stage two

Only the judgement call: whether onyx gets a solar-system vein, and the twenty-one candidate gaps
whittled down by adding decomposition and the recipe graph to the closure.

## 6dd. The region layer: how a hundred and ten bodies stay one row each - 2026-10-15

The owner asked the question this round exists to answer - "with it done this way, what happens to the
exo systems?". The honest first answer was that a geology card per body does not scale: twenty-five
bodies justified it, a hundred and ten do not. So the table grew the layer 6cx proposed and the solar
system did not need: **a region owns a suite, and a body names a region**.

### The mechanism

```
Regions = @{ nearby_systems = @{ Layer = 'IV'; Variants = @(frontier_silicate, ...) } }
Bodies  = @{ proxima_b = @{ Region = 'nearby_systems'; Card = ... } }
```

A body's vein list is now the union of three contributions: an explicit `Bodies` list on the variant
(what the solar system still uses, because those assignments are individual), the suite of the region
the body names, and its own `Signature` if it has one. A variant that carries no bodies at all is a
validation error rather than a silently dead definition.

The four nearby-system bodies were rewritten onto it - Barnarda C, C1 and C2 keep `barnarda_onyx` as
their signature, Proxima B and Tau Ceti F take the suite alone - and **the generated files are
byte-identical to the ones the server already verified** (all 117 hashed before and after; 0
differences). Which is the point: the refactor changes what the table *costs*, not what it produces.

### What a hundred and ten bodies cost now

* one **suite** per (region, physical archetype) - five or six shared variants each, and the plan's
  seven universal layers put that at roughly ten to fourteen suites, so **about sixty variants cover
  every body in the game**;
* a **signature** only for the bodies the plan names (Proxima Centauri b, TRAPPIST-1e, Kepler-452b,
  the Gliese systems ...), which is twenty to thirty of them;
* the rest take the suite. Adding a body is then one row: region, optional signature, card.

That is the plan's own stage-three acceptance criterion - "the template copied to a second planet
takes under a day" - met with minutes, and it is why the solar system's cards were worth writing: they
are what the suites are abstracted from.

### The two things that must be decided before the first exo body

1. **Dimension ids.** Plan table 5-2 (exoplanets from `-100`, gas giants `-110`, deep space from
   `-120`) was written without Galaxy Space's real allocation, which this pack has already used:
   `-1005` through `-1032` and `-1338`. Either carve the plan's intent out of a free range, or use the
   plan's own reuse mechanism (planet dimension + era variable, section 5.2) - which first has to be
   checked against what Galaxy Space does with its ids.
2. **Who owns the planets.** A self-written dimension (own `WorldProvider` / chunk generator) decides
   its own ids and can register veins at a known point; reusing Galacticraft's machinery inherits its
   allocation and its ordering. 6cy already measured where the vein registry can be touched.

Neither is a vein problem, and neither blocks anything in the solar system.

### What is deliberately not done

No exo content was invented: the region suite for the nearby systems is still the *provisional*
frontier set 6da wrote, and the plan's stage-three sample - Proxima Centauri b, end to end - is where
a real card replaces it. The closure table from 6dc is the tool that should decide what each region's
suite has to contain, because the plan's rule is per tier: a tier's materials must be collectable in
the space that tier unlocks. Inventing suites before that is guesswork.

## 6de. Mod ores, and the closure ladder in stages - 2026-10-15

The owner's forward plan: adventure mods arrive later, and their ores will need veins written here -
placed, as they put it, "according to each planet's real environment". The endgame is expected to
include Avaritia (无尽贪婪) and Draconic Evolution (龙之研究). That runs straight into the plan's own
rule 5.4, "do not add ores; diversity comes from combination", so the rule needs its second half
written down before the first such mod lands.

### Two kinds of ore, two rules

Rule 5.4 governs **this pack's own roster**: the hundred-odd `ore:` values the solar system draws from,
where the temptation is padding - "this body feels thin, add a mineral". Combination is the answer
there.

A **mod's currency ore is a different thing.** Draconium is not flavour: nothing else yields it, so it
has to exist or the mod does not work. It is admitted deliberately rather than by accident, and the
three ways it can be admitted are what keep the plan's other rule - *every vein carries a geological
reason* - honest:

| route | when | example |
| --- | --- | --- |
| **natural** | the ore behaves like a mineral and the body could plausibly have it | a mod's iron-analogue on a rocky body, placed by the same environment rules as everything else |
| **exotic** | it is only plausible far out, and its *stage* is the gate | this pack already treats naquadah this way: the belt, and then the Kuiper Belt |
| **artificial** | the body's geology cannot produce it at all, and pretending otherwise would be a lie | the plan's own 遗迹 / Kardashev system: the ore is what the previous civilisation left, not what the planet made |

The third route is the one worth having. Draconium is a *dragon* material from a mod about a dead
dragon; writing it into a geology card as "volcanic sulphides" would be the kind of thing that makes
these documents untrustworthy. Naming it as ruin-delivered keeps the card honest and ties the mod into
the one system the plan already has for "something was here before you".

### The order of operations is already enforced

`tools\ore-vocabulary.txt` plus `-UpdateVocabulary` (6db) will not let a vein name an ore until a
server start has shown that ore block loading - which is exactly the right sequence for a new mod:
**install it, start the server, refresh the vocabulary, then author**. It was born from the 6cx
failure, where sixteen veins named materials that existed without ore blocks and GregTech rejected the
whole definition. A mod's ore now has to prove itself before it can be placed.

### The closure checklist now speaks in stages

Rule 2.2 is per tier, so `check-resource-closure.ps1` was rebuilt around the plan's stage table 2-1
rather than around "solar system versus the rest". It reads the region stages out of
`planet-veins.psd1` and prints the ladder - what a player can reach at the end of each stage:

| stage | voltage | new ores | new materials | reachable in total |
| --- | --- | --- | --- | --- |
| 1 | LV~MV (Earth) | 116 | 162 | 162 |
| 3 | **EV (solar system)** | 10 | 11 | **173** |
| 4 | IV (nearby systems) | 1 | 1 | 174 |

The stage-3 row is the stage-two acceptance target ("EV materials 100 percent obtainable inside the
solar system"), and it now reads as a number rather than a claim. `onyx` is flagged as the one ore that
exists only beyond the solar system - the only row of the ladder that is not where the plan's table 2-1
would put it, because it is a pack material parked on Barnarda C.

A mod ore enters this table at exactly one stage, which is what makes "nothing before stage N may need
it" checkable. What is still missing for that check to be a verdict is the **demand side**: which tier
consumes which material, from the recipe graph. It is the same gap 6dc recorded - the closure follows
ore byproducts, not decomposition and not recipes - and it becomes load-bearing the moment a mod's
material has to be justified against a stage.

### What the endgame mods mean for the ladder

Plan table 2-1 puts deep space at UHV (neutron stars, black holes) and ultra-deep / unknown space at
UHV+ (the genesis engine, galaxy gates). Draconic Evolution's draconium is an endgame material, so its
natural home is a deep-space route. Avaritia's content is *crafted* rather than mined, which means it
needs materials and recipes rather than veins - but that does not let it off the hook: its materials
still have to appear somewhere in the ladder, and the ladder is what says where.

## 6df. The demand side: what the recipe registry can and cannot answer - 2026-10-15

6de ended with the item that would turn the closure ladder into a verdict: the demand side, "which tier
consumes which material", read out of the recipe graph. A temporary probe
(`MinespaceRecipeDemandProbe`, deleted after the run) walked the registry: **73 recipe maps, 70,211
recipes, 67,937 of them with material inputs, 786 materials consumed somewhere** (`RecipeMap.recipeList`
has no getter, so it is read reflectively).

### The first statistic was noise, and it is worth recording why

"The lowest tier that consumes material M" comes out as **tier 0 for essentially every material**.
The reason is not a bug: some cheap processing recipe - macerate an iridium ingot, smelt an iridium
dust - consumes M at whatever tier that recipe carries, and that says nothing about when a player
*needs* iridium. Restricting to the assembly maps does not rescue it either: 4,553 assembler recipes
span tiers 0 to 8, and iridium is in the tier-0 ones.

The statistic that survives is the other end: **the highest tier that consumes a material.** A tier-0
recipe cannot raise a maximum, so the cheap-recipe flood cannot touch it. One correction is still
needed on top, and it is the same fact 6dc recorded: an *ore's* own consumption is always a low-tier
processing step, and what matters is where its **products** are used - so a material's last use is the
later of its own and of everything it yields, followed through the byproduct chains to a fixed point.
Without that, the check flags `cooperite` (consumed by cheap grinding) even though the platinum and
palladium it yields are wanted much later.

### What that supports, and what it cannot

`check-resource-closure.ps1` now runs one demand-side check:

> a material whose **last use** is below the tier that first supplies it can never be used at all.

That is **sound but incomplete**, and the asymmetry is the point. A failure is real - something is
placed too late for anything that wants it. Passing does **not** prove rule 2.2, because *necessity is
not in the registry*: a recipe says what *can* be consumed, never what a player is obliged to build.
Answering "must be obtainable by tier T" needs the pack's own definition of its progression - the
tier-priced machine content that rounds 6cr/6cs/6ct already audited in `scripts\*.zs` - not a scan of
70,211 recipes.

### The finding

**`solar` - this pack's own material - is supplied too late to be usable.** It generates on Venus,
which unlocks at stage 3 (EV, tier 4), and **nothing above tier 1 consumes it**: its highest use is
LV. So as it stands, a player reaches it only after everything that wants it is already built, and
`onyx` is clean by comparison - its last use is tier 7 (ZPM, because of its byproduct chain), well
above the stage 4 it is placed at.

Two ways out, and it is a design question rather than a bug: either `solar` belongs where a tier-1
material can be found (the Moon, an asteroid, or the overworld set), or something above LV should
consume it - which would mean a recipe the pack intends but never wrote.

### What this means for mod ores

When Draconic Evolution arrives, this tool gives two of the three numbers needed to place draconium:
the **bound** (a mod ore is needed no later than the highest tier that consumes it) and the **ladder**
(a mod ore enters the table at exactly one stage, 6de). The third - "from which stage *should* it
start" - is a progression decision, and it is exactly the half the registry cannot supply.

## 6dg. The vein composition for a hundred and ten bodies - 2026-10-15

6dd made an exo body cost one row. This section is what that row should *contain*: the composition
rule that holds for every body in the game, and the theme each layer's part of it has to express. It
is a design, not an implementation - two of the seven layers have no bodies yet, and naming their veins
before they exist would be inventing content. What is implemented is the mechanism that carries the
design.

### The rule: universal base + layer delta + signature

Every body outside the solar system carries three things, and nothing else decides its vein list:

| part | how many | what it is | why |
| --- | --- | --- | --- |
| **universal base** | 5 | silicate, iron-nickel, sulphide, rare earth, volatile | so that no landing is a dead end - the ordinary materials are always local, which is what makes flying out *possible* instead of a supply run |
| **layer delta** | 2..4 | the layer's theme (table below) | so that a layer is recognisable, and so that the tier's new material demand has somewhere to sit |
| **signature** | 0 or 1 | one vein only that body has | only for the bodies the plan names - this is the answer to "why this one" |

That is 5..8 veins per body *structurally*, which is the plan's rule 5.4, arrived at by construction
rather than by counting each body. The base's five reasons are deliberately generic, because they are
true of any rocky body; the delta's are layer-specific; the signature's is that body's alone.

### The seven layers, and what each delta is for

| stage | voltage | the space | delta theme |
| --- | --- | --- | --- |
| 0-2 | steam to HV | Earth and low orbit | **not ours** - the plan's own overworld / nether / end sets, untouched |
| 3 | EV | the solar system (25 bodies, 55 variants) | done: per-body geology cards, because twenty-five bodies justify them |
| 4 | IV | nearby systems (Proxima, Barnard, Tau Ceti) | **base only, for now** - these four are the plan's stage-three sample, and their cards are still provisional |
| 5 | LuV~ZPM | mid systems, TRAPPIST-1 and the Gliese systems | heavy elements, and the first ruin-delivered ores. Gas giants are a *harvesting* system, not a vein |
| 6 | UV | far systems, Kepler-452b and kin | crystals and the exotic: bodies that are already dead, and what observing them yields |
| 7 | UHV | deep space: neutron stars, black holes | extreme matter. This is where Draconic Evolution's draconium belongs (6de route 2) |
| 8 | UHV+ | ultra-deep and unknown: the genesis engine, galaxy gates | made rather than mined - Avaritia-tier content, and every ore on the artificial route |

The layers are themes rather than designs on purpose. Their *content* is fixed by three things that
are already measurable, and inventing veins ahead of them would be guessing:

1. **the tier band's material demand** - what the tier this layer unlocks actually consumes (6df's
   demand data, which bounds where a material may appear);
2. **the plan's own systems** - atmospheric harvesting for gas giants, ruin-delivered ore for the
   artificial route, observation instead of mining where the plan says observation (stage 6);
3. **the closure ladder** - each layer adds one row, and the row says how much the layer has to bring.

One honest consequence worth writing down: layers 5 to 8 cannot be differentiated by *new materials*,
because this fork's material set is fixed at 794 and the outer tiers mostly re-use the same names with
deeper processing. What differentiates them is **concentration** (deep bodies carry the scarce end of
the roster and little of the mundane), **geology type** (ice worlds, metallic bodies, atmosphere), and
**ruin-delivered content** - which is why the delta themes above are what they are.

### The arithmetic, and the mechanism that carries it

| what | how many | note |
| --- | --- | --- |
| bodies | ~110 over seven layers | the plan's own count |
| variants for the solar system | 55 | done, 25 bodies |
| base suite | 5 | shared by every non-solar body |
| layer deltas | ~10-20 | five layers at two to four each |
| signatures | ~25-30 | one per body the plan names |
| **variants for the whole game** | **~105** | and ~550-880 vein *entries* inside those files |

Two fields of `planet-veins.psd1` make that work, and both are implemented and verified:

* **`Includes`** - a layer lists `@('base')` and its own delta, instead of repeating five names. The
  generator resolves it recursively and reports an `Includes` cycle rather than hanging.
* **`Planned`** - a layer can exist in the table as a stage, a voltage and a theme with no variants and
  no bodies. The generator skips it for placement and prints it under "planned layers", so the plan
  sits exactly where the next body will be added rather than in a document nobody opens. Marking a
  layer planned is a claim the table has to keep repeating until it is done.

Verified: the four nearby bodies' generated files are **byte-identical** after the refactor (all 117
hashed before and after, 0 differences), so the mechanism changed what the table costs and nothing
about what it produces.

## 6dh. The nearby systems get real cards, and the gap list becomes the driver - 2026-10-15

6dg left the inner layers as themes and the nearby bodies as "base plus a provisional signature". This
round writes those five cards for real, and the thing that made them *designable* rather than invented
was 6dc's own output: the closure checklist's list of ore-bearing materials with no source anywhere.
That list is not an inventory of oversights - it is plan 2.2's instruction, "any gap is filled by a vein
variant", and the exo layers are where those variants go.

### Ten materials found a home

| body | card | what it fills |
| --- | --- | --- |
| **Proxima B** (-1025) | tidally locked inside a flare star's habitable zone: one face always toward Proxima, X-ray flares every few hours, a substellar sea as the only liquid water | signature = **zircon** (the oldest, most re-melted crust in the pack, and exactly where zircon plus its niobium-rare-earth companions belong) → fills `zircon`, `pyrochlore`; delta = `Flare_Baked_Regolith_Vein` (sulphur, nitrate, tellurium - chemistry of a surface under a star that will not leave it alone) and `Substellar_Sea_Vein` (salt, lithium, calcite - what evaporating the day-side sea leaves) |
| **Barnarda C** (-1030) | the system's ordinary crust, cold for billions of years | keeps `onyx` as its signature - the pack's own material, and the only thing here nothing else carries |
| **Barnarda C1** (-1031) | the one that cooled fast enough to fractionate | signature = a **pegmatite**: `columbite`, `gallite`, `cassiterite` - a pegmatite is what a small planet's leftover melt makes, and it is where niobium, tantalum and gallium concentrate |
| **Barnarda C2** (-1032) | outermost, and **the first body in this pack whose ore is not geology** | signature = a **ruin cache**: `vinteum`, `opal`, `jasper` on a world that could not have made them - plan 2.2's artificial route (6de) doing its job, and the visible half of the same story is the I-type ruins stage three injects |
| **Tau Ceti F** (-1338) | a super-Earth around an old, metal-poor star with a debris disc | signature = the **carbonate evaporites**: `witherite`, `celestine`, `rhodocrosite` - what a crust that has been wet and dry many times over accumulates; delta = `TauCeti_Pressure_Diamond_Vein`, because a super-Earth is deep enough that diamond is a rock-forming mineral rather than a gem |

Each of the five is now **base 5 + delta 2 + signature 1** = 8 veins (Tau Ceti F is 7), which is the
plan's 5..8 arrived at by the rule rather than by counting.

### The vocabulary had to learn something to allow this

Filling a gap means naming an ore that no vein file uses yet - and 6db's vocabulary check exists
precisely to refuse those. It was right to, and the fix is a stronger source of evidence: the registry
dump from 6df's probe says which materials GregTech gives an ore block to (164 of 794), and *that* is
better evidence than "some file uses it". So `build-planet-veins.ps1` now reads both. Without it the
check would have refused the very ore the plan asks to place; with it, the twenty candidates are
admissible and the twenty materials that have no ore block stay rejected.

### Numbers

| measurement | before this round | now |
| --- | --- | --- |
| ore-bearing materials with no source | 20 | **9** |
| closure ladder, stage 4 (IV) | +1 ore, +1 material, 174 total | **+11 ores, +13 materials, 186 total** |
| generated definitions | 117 | 126 |
| the six acceptance criteria | all OK | **all OK** |

Verified in the loader, which is the only thing that can confirm the new ore names: `Loaded 126 worldgen
definitions`, zero parse failures, 47 mods, `Done (1.812s)`, zero `crafttweaker.log` errors, 19
`Exception` mentions. The vocabulary was then refreshed from that clean run (137 ores).

### What is left

The nine remaining gaps divide cleanly. **`iridium` and `osmium` are not real gaps** - 6dc recorded that
they come out of `iridium_metal_residue` by decomposition, which the byproduct-only closure does not
follow. The other seven are candidates for the layers that come next: `trinium`, `triniite`,
`bowieite` and `arsenopyrite` for the mid and far layers, and `fluoroapatite`, `caliche`,
`barytocalcite` for a wet body somewhere. `solar` is still flagged as supplied after its last use -
unchanged, and still a design decision rather than a bug.

## 6di. `solar`, and the third class of demand - 2026-10-15

6df's demand check flagged exactly one material: **`solar`, this pack's own, supplied on Venus while
"nothing above tier 1 consumes it"**. The owner asked for it to be looked into before moving outward,
and the answer turned out to be about the tool rather than the ore.

`gc_crafting.zs` line 122:

```
recipes.addShapeless(<galacticraftplanets:basic_item_venus:4>, [<ore:dustSolar>]);
```

Galacticraft's circuit fabricator consumes its own "solar dust", which carries no ore-dictionary name,
so the pack converts GregTech's solar dust into it. That is a **crafting-table recipe**, and GT's
recipe maps do not contain crafting-table recipes at all. So `solar` is consumed, on Venus, by a Venus
machine - **the placement was right and the check was blind.**

### Three classes of demand, and only one of them is in the registry

That case names the whole problem, and it is worth writing down because it bounds every future check:

| class | where it lives | does it have a tier? |
| --- | --- | --- |
| GT **machine** recipes | the recipe registry - the 70,211 the demand probe walked | yes, from EUt |
| the pack's own **crafting-table** recipes | `scripts\*.zs` - 171 materials are consumed this way | **no**, at all |
| **necessity** - what a player is obliged to build | nowhere | not applicable |

So the demand side is complete in the only sense the data allows: machine consumption is tier-stamped
and measured; table consumption is known to exist but carries no tier, so it can prove "used" and never
"used at tier N"; and necessity is a design decision that has to be stated rather than derived. The
plan's own tier table is that statement.

### The check was rebuilt rather than patched

Adding an exception for `solar` would have hidden the class. Instead `check-resource-closure.ps1` now
reads the pack's scripts for `<ore:...>` references **inside a recipe-addition statement only** - a
`recipes.remove(...)` or a paragraph of the pack's rather thorough prose says nothing about
consumption - and excludes those materials from the "supplied after its last use" rule. Crucially it
does not drop them silently: it prints how many materials the scripts consume (171) and lists the ones
that would otherwise have been flagged (one, `solar`, with both tiers). A signal a person can see beats
either a false alarm or a suppression.

The result: `[ OK ] no material is supplied after its last use (0 too late)`, with `solar` named as the
one material only a crafting table wants.

## 6dj. The owner's planet catalog: 106 bodies, and where the veins come from - 2026-10-15

The owner wrote `Minespace-unofficial-dev\PLANET-CATALOG.md` - tool-generated, from
`tools\planet-catalog.psd1` (design fields), `tools\nasa-planet-data.json` (fetched by
`fetch-planet-data.ps1` from the NASA NSSDC fact sheets and the Exoplanet Archive) and
`tools\build-planet-catalog.ps1`. It is the concrete body list for the plan's seven layers:
**20 solar-system bodies + 86 deep-space targets = 106**, every one a real body with real measured
values, which is what plan 1.1 demands.

### The two documents are two halves of one system

The catalog's vein column *reads `planet-veins.psd1`*: for layer 1 and for the five nearby bodies it
lists exactly the veins this table generates, and for everything else it says
"未配置（登陆时按所属层的套件 + signature 生成，方案 5.4）" - not configured, to be generated from the
layer's suite plus a signature. Which is the 6dg scheme, named in the owner's document as the thing
that fills the remaining 37 cards. The catalog also runs its own validation of the same rule this
table's audit enforces ("太阳系的可登陆体矿脉数必须落在 5..8") and reports it passing.

### What the catalog decides that this plan had left open

* **Dimension ids.** 6dd recorded the conflict between the plan's `-100` / `-110` / `-120` bands and
  Galaxy Space's real allocation. The catalog resolves it by keeping the plan's structure and widening
  the bands: nearby `-2000..-2099`, mid `-2100..-2199`, far `-2200..-2299`, deep `-2300..-2349`,
  ultra-deep `-2350..-2399`, unknown `-2400..-2449` - with a per-body id already assigned. No overlap
  with the measured GC/GS occupancy, and the solar system opens no new dimension at all (the four gas
  giants reuse Galaxy Space's existing objects).
* **The layer count is seven, and two of them have no landable body.** Layers 6 (the Local Group and
  the Virgo Cluster) and 7 (beyond the galaxy gates) are observation only - galaxies, nebulae, M87*,
  quasars, the CMB. **A layer with nothing to land on needs no vein**, so this table carries them as
  stubs with no delta, which is what its `Planned` mechanism is for. The real vein work is in layers
  2 to 5.
* **The body names are real.** Galaxy Space's fictional "Barnarda C / C1 / C2" map to **Barnard's Star
  b / c / d** on the same dimension ids, so this table's entries were renamed (Display, and the mapping
  recorded in each card) and the audit script's body list followed.

### The size of the remaining vein work

| layer | bodies in the catalog | landable | of those, cards done |
| --- | --- | --- | --- |
| 1 solar system | 20 | 19 | **19** - every one has a real card (6da / 6db / 6dh) |
| 2 nearby systems | 16 | 14 | **5** (Proxima b, Barnard b/c/d, Tau Ceti f) |
| 3 mid systems | 14 | 14 | 0 |
| 4 far systems | 14 | 11 | 0 |
| 5 deep space | 14 | 3 | 0 |
| 6 ultra-deep | 13 | 0 | n/a |
| 7 unknown | 15 | 0 | n/a |

So **37 landable bodies still need vein sets** - and 44 targets need none, because there is nothing to
land on. Each of the 37 has a design brief already written in the catalog's 备注 column ("熔岩海直接
开采", "水世界", "环双星行星", "微行星采样教学", "母星已经死过一次"), which is what makes the cards
designable rather than invented: the layer supplies the delta, the 备注 supplies the signature.

What this table still owes them is the part 6dg described and has not yet written: the **layer deltas**
for stages 5, 6 and 7 (heavy elements and the first ruin ores; crystals and the exotic; extreme
matter and age), and then one row per body.

## 6dk. The mid layer: designed before its dimensions exist - 2026-10-15

6dg's sequence is: write the layer's delta, then one row per body. The catalog hands over layer 3 with
fourteen bodies and their ids (-2100..-2121), so this round does the first of those layers for real.

### A state the table needed: designed, not generated

PLANET-CATALOG assigns dimension ids to 86 targets, but **no such dimension exists in the game**. A vein
file for one would load fine and then sit in JEI, advertising a planet nobody can reach - which is the
mirror image of the problem 6cu set out to fix (a planet you *can* reach and mine nothing on). So a body
can now be `Pending`: it counts toward the design (its veins are counted, the catalog reads them) and
contributes nothing to the output - no file, no folder, no dimension filter - and the generator lists it
under "designed but not generated". Verified: **126 files, unchanged**, all six acceptance criteria
still passing.

### Two of the fourteen are not landable

Gliese 876 b and 51 Pegasi b are gas giants. A gas giant has no surface, and the plan's own stage-five
theme is "气态行星采集上线" - atmospheric harvesting comes online - which is a different system from a
vein. They are therefore **not** in the table, and the catalog's list of them as vein-bearing is a
catalog correction rather than a vein one. Twelve cards, not fourteen.

### The layer delta, and six signatures that come from the catalog's own notes

The delta is `Heavy_Refractory_Vein` (scheelite, molybdenite, molybdenum, powellite; weight 120) - "heavy
elements", the theme 6dg set for this layer. The signatures follow the catalog's 备注 column and the
closure checklist's gap list, which is where the remaining nine unsourced ores live:

| body | signature | fills |
| --- | --- | --- |
| **TRAPPIST-1 e**, the type II ruin stage | `Dyson_Wreck_Vein` - trinium, triniite, bowieite | trinium, triniite, bowieite |
| **55 Cancri e**, 1958 K, magma ocean | `Magma_Ocean_Vein` - magnetite, ilmenite, arsenopyrite, rutile | arsenopyrite |
| **HD 40307 g**, 255 K and wet | `Temperate_Brine_Vein` - fluoroapatite, caliche, barytocalcite | fluoroapatite, caliche, barytocalcite |
| **HD 219134 b**, the density benchmark | `Dense_Siderophile_Vein` - iridium, osmium, platinum | iridium, osmium |
| **TRAPPIST-1 c** and **Gliese 581 c**, both announced habitable and both un-announced | `Runaway_Greenhouse_Vein` (shared) | - |
| **TRAPPIST-1 d**, 0.39 Earth masses | `Stripped_Mantle_Vein` - olivine, magnesite, chromite | - |

Two things are worth naming. The iridium and osmium vein is the honest answer to 6dc's "false gap":
they are siderophiles, a dense super-Earth's core is exactly where they belong, and this is the first
place in the pack where they are mined rather than recovered from `iridium_metal_residue`. And
TRAPPIST-1 f, g and h **reuse Europa's icy veins** rather than inventing new ones - f has eight veins
(base, delta, both ice veins), g and h seven - which is the sharing 6dg was built for.

If the six signatures land, the gap list goes from nine to zero. It will not show that yet, and the
reason is correct: **the closure checklist reads the config, not the design**, so the mid layer's ores
appear in the ladder the day the first mid-system planet exists. Designed-then-inert is the order.

## 6dl. The one claim that was never tested: does ore actually appear? - 2026-10-15

Everything this pack knows about its planet veins is config-level. 6cu said the limit out loud - "what a
server cannot see is whether ore actually generates on a body; that needs chunks in those dimensions" -
and it has been open ever since. This round tried to close it headlessly, with a temporary probe
(`MinespacePlanetOreProbe`, deleted after the run; the re-deployed jar verified at 0 `VPROBE` lines,
126 definitions, baseline).

What it did: at server start, for each of the 25 planet dimensions, create the world and generate a 4x4
chunk area at 2000,2000 - out where nothing has ever been generated - then, a hundred ticks later (past
the point where the tick fallback 6b added for Venus-style providers has run), scan every block of those
chunks for ore and tally by block name.

| step | result |
| --- | --- |
| planet dimensions registered | **all 25** - provider types exist, -28 reports as `moon.moon` |
| server instance | `DedicatedServer`, non-null |
| `DimensionManager.getWorld(id, true)` | **null for all 25**, and no exception thrown |
| chunks generated / ore blocks found | 0 / 0 |

The finding is a negative one, and it is worth recording exactly because it closes a route: **Forge's
`DimensionManager` will not create a planet world here.** The dimension is registered, the server is
running, the load flag is set, and it still returns null without complaint. Galacticraft brings its
planet worlds into existence through its own path - a player travelling there - not through the generic
API.

Two consequences:

* **The "does ore appear" question cannot be answered from a dedicated server** - not merely "is easier
  in game". The in-game visit that 6cu and 6cv recorded as the owner's check is the *only* route, not
  the convenient one.
* The registration half is now positively confirmed: **all 25 planet dimensions are registered and
  their providers exist**, so the `dimension_id` filters these 126 vein files carry do point at real
  dimensions. That was assumed before; it is measured now.

What remains verified is the load side (126 definitions, 25 bodies at 5..8 veins, no duplicates, no dead
definitions, the closure ladder), and what remains unverified is the half a server cannot reach: whether
the ores a vein names end up in the world.

Two Forge details learned on the way, both worth keeping: `DimensionManager.getWorld(id)` does not load
- it needs the boolean - and `Chunk`'s three-argument `getBlockState` and `MutableBlockPos#setPos` are
not in this mapping, so a block scan has to go through `World#getBlockState(new BlockPos(...))`. That is
the 6b lesson about the mapped snapshot, one more time.

## 6dm. All 81 planned dimensions registered - 2026-10-15

The owner's call was "register them all first, no terrain, the star map can see them later". Done, and
the reason it is cheap is 6dl: **registering a dimension does not create a world.** Forge only builds one
when something travels there, so eighty-one registrations cost a list entry each and nothing else - no
world files, no memory, no chunks.

### The table is generated, not typed

`tools\gen-planet-dimension-table.ps1` reads `planet-catalog.csv` and writes
`MinespacePlanetDimensions.java` - a compile-time table of id, name (English and Chinese), layer, stage,
landability and card size. Generated rather than hand-written so that **PLANET-CATALOG stays the single
source of truth** and the addon depends on no file at runtime; re-run the script after the catalog
changes.

Landability follows the catalog's own rule, which is the one its 不适用 text already uses: a Planet,
Moon, DwarfPlanet or AsteroidBelt can be landed on, a Star, WhiteDwarf, Pulsar, BlackHole, Galaxy,
Nebula, Cluster, Quasar, Transient, SupernovaRemnant, CosmicWeb, CMB, GravitationalWave or
InterstellarObject cannot. The output reproduces the two numbers 6dj had already worked out by hand -
**37 landable, 44 observation only** - which is a useful check on the reading.

### Registration

`MinespacePlanetDimensionsRegistration.register()` runs in this mod's preInit: one `DimensionType` per
body, one shared `WorldProvider` (a void world - no terrain, as asked), and
`DimensionManager.registerDimension`. **An id that is already registered is left alone with a warning**,
because Galaxy Space and Galacticraft own the ids they have and a silent re-registration would move a
real planet.

Verified on the server: `Registered 81 planned dimensions (37 landable, 44 observation only), 0 already
owned by another mod; 81 in total from PLANET-CATALOG`, then the usual baseline - 126 definitions, 47
mods, `Done (2.021s)`, 19 `Exception` mentions.

### Registered is not playable, and that is written into the class

The pack's planet ore generation only runs for dimensions whose provider is a Galacticraft one
(`MinespacePlanetOreGen.isPlanet` checks `IGalacticraftWorldProvider`). These 81 providers are not, so
**no ore will generate in them yet**. That sentence is in the registration class's own javadoc, so the
next person cannot mistake "registered" for "done": a planet you can reach and mine nothing on is
exactly the bug 6cu set out to fix. The next piece of work is either making these providers
Galacticraft-compatible or widening that guard.

### Four things learned the hard way, all worth keeping

* `Arrays.asList(a, b, c,)` - a trailing comma is legal in an array initializer and **illegal** here.
* `IChunkGenerator`'s method signatures do not line up with the mapped snapshot (`getPossibleCreatures`
  could not be implemented), so the void generator extends `ChunkGeneratorOverworld` and overrides two
  methods instead of implementing the interface.
* `ChunkGeneratorOverworld.world` is private - a subclass needs its own reference.
* Chinese text in a generated Java file has to be `\uXXXX`-escaped: javac reads sources in the platform
  encoding here, which is GBK, and the names came out as mojibake until they were escaped.

## 6dn. The ore hook reaches the planned dimensions, and a void world cannot hold ore - 2026-10-15

Step one of what 6dm left open: make the pack's ore generation *eligible* in the 81 new dimensions.

`MinespacePlanetOreGen.isPlanet` was testing `instanceof IGalacticraftWorldProvider`, which was the right
test when every planet was Galacticraft's and the wrong one now. What that class actually needs to know
is not "is this a Galacticraft planet" but **"does this dimension's generator skip
`GameRegistry.generateWorld`"** - that is the entire reason the class exists. Galacticraft's chunk
providers never call it, and neither does the void generator the planned dimensions use, so both need the
call made for them; the overworld, Nether and End do call it and stay out, because running every mod's
generator twice is worse than running none. The guard now accepts either provider.

Verified on the server: `Registered 81 planned dimensions (...)` and the hook line both appear, then the
baseline - 126 definitions, 47 mods, `Done (1.927s)`, 19 `Exception` mentions.

### The hard fact this exposed

Being *eligible* is not the same as being *able*. Two walls stand between the 81 dimensions and a single
ore block, and both are consequences of the owner's own "register them all first, no terrain" call:

1. **The world does not exist until something travels there** (6dl), so nothing generates at all yet;
2. **a void world has no stone to replace.** GT's vein generation works by replacing the dimension's
   stone type - that is what `PREDICATE_STONE_TYPE` and the per-body stone types are for - so a world of
   nothing can never hold ore, however many veins its filter names.

So the order is now fixed and worth stating plainly: **terrain and a stone type per dimension come
first, ore second.** That is the existing Galaxy Space machinery - `MinespaceGalaxySpacePlanets` (a rock
block, a stone type and a material per body) - generalised from 17 bodies to the 81 planned ones, and it
is the piece that turns a registered dimension into a minable planet. Until it exists, un-pending the 37
landable bodies' cards would produce files that are honestly inert: correct, loadable, and pointing at
worlds with nothing in them.

## 6do. The 81 planned bodies are on the star map, unreachable - 2026-10-15

The owner's call: "make them non-landable planets first, so the star map can show them."

### The map turned out to be Galacticraft's

Before writing anything, the map was identified. `galaxyspace.core.handler.GSMapHandler` sounds like it
owns a map, and it does not: it is a **render handler** subscribed to
`micdoodle8.mods.galacticraft.api.event.client.CelestialBodyRenderEvent`, which adds Galaxy Space's own
flourishes (Haumea's ring) to a map that draws **whatever is registered in `GalaxyRegistry`**. So this
pack can be on that map by calling one API, without touching another mod's jar and without writing a
screen of its own. The measurement took one `javap` and saved a mixin.

### `setUnreachable()` was already the switch

`CelestialBody` carries exactly what the request needed: `setUnreachable()` (shown, not offered as a
rocket destination), `setDimensionInfo(id, providerClass, autoRegisterDimension)`, `setTierRequired`,
`setRelativeSize`, `setRelativeDistanceFromCenter`, `setPhaseShift`, `setRelativeOrbitTime`,
`setBodyIcon`. So "cannot land on it" and "the map shows it" are the same API call, and no part of this
had to be invented.

`MinespacePlanetSkyRegistry` registers all 81 bodies: one `SolarSystem` per layer (six, for layers 2 to
7), each body a `Planet` with its dimension id, `tierRequired` from the catalog's stage, a relative size,
and `setUnreachable()`. Three details matter:

* **`setDimensionInfo(..., false)`** - the third argument is `autoRegisterDimension`. It must be false
  because 6dm already registered all 81 ids with `DimensionManager`; letting Galacticraft register them
  again would either throw or move an id.
* **A body without an icon is where a map render crashes rather than looks plain**, so every body shares
  one placeholder for now (Galacticraft's own sun icon). Per-layer or per-type icons are an asset
  question, deliberately deferred.
* **Every body is registered inside its own try/catch.** The map is drawn on the client and this pack is
  verified on a dedicated server; one bad row must not be able to take the map down where nobody here
  can see it.

### Verified, and what is not

`Star map: registered 81 of 81 planned bodies as unreachable (0 failed); 6 systems created`, then the
baseline: 126 definitions, 47 mods, `Done (1.996s)`, 19 `Exception` mentions. (The first run of this
logged "8 systems created" - it printed the array's length instead of the number created. Fixed and
re-run rather than left standing, because a log line is evidence.)

What a server cannot check is how it *looks*: whether the six systems sit somewhere sensible on the map
and whether the bodies are readable there. That is an in-game check, and it joins the list 6cu and 6cv
already keep - the point of this round is that there is now something to look at.

## 6dp. The bodies are grouped by their own star system, not by layer - 2026-10-15

6do put the 81 bodies on the map in six systems, one per layer, because its first pass did not know each
body's host star. The owner's correction was immediate and right: "these planets are defined by the star
system they sit in". The catalog has recorded that all along - its `Star` column carries the host of
every planet - so the grouping is now the real one.

`gen-planet-dimension-table.ps1` emits a `star` field per body; `MinespacePlanetSkyRegistry` groups by
it, **74 systems instead of 6**: 30 real host stars (TRAPPIST-1 M8.0 V, GJ 581 M3.0 V, 55 Cnc G8 V and
the rest, each holding its own planets together) plus the 44 bodies that orbit nothing at all - stars,
black holes, galaxies, quasars - each of which stands as a system of its own. That is the only shape
Galacticraft's model offers for a body with no primary, and for a galaxy it is also the truthful one.

Systems are placed by a deterministic formula (a ring per layer, evenly spaced within it) rather than
left at the origin, so the map has a shape; where exactly they land is one of the things the in-game look
decides.

Verified: `Star map: registered 81 of 81 planned bodies as unreachable (0 failed); 74 systems created`,
then the baseline - 47 mods, `Done (2.042s)`, 19 `Exception` mentions.

## 6dq. The white screen: the galaxy name is a texture path, not free text - 2026-10-15

The first in-game look at the star map was a crash, and it was this round's fault:

```
java.io.FileNotFoundException: asmodeuscore:textures/gui/galaxy/galaxy.milkyway.png
[Client thread/FATAL] Reported exception thrown! Caused by: java.lang.NullPointerException: Rendering screen
```

`SolarSystem`'s second constructor argument is not a label - the map resolves it to
`assets/asmodeuscore/textures/gui/galaxy/galaxy.<name>.png`. 6dp passed `"MilkyWay"`, the loader looked
for `galaxy.milkyway.png`, found nothing, got a null texture and took the client down while drawing.

Listing the textures that actually exist settled it in one command: AsmodeusCore ships exactly
`galaxy.milky_way.png` and `galaxy.andromeda.png`. So the identifier is **`milky_way`**, and there are
**only two galaxies available in this stack** - which also closes the "one galaxy per layer" idea from
6dp's notes: seven layers cannot become seven galaxies without seven textures nobody has drawn.

Fixed to `milky_way`, rebuilt, and re-verified on the server: `Star map: registered 81 of 81 planned
bodies as unreachable (0 failed); 74 systems created`, 126 definitions, `Done (1.991s)`, 19
`Exception` mentions.

The lesson is the same one this project keeps meeting in a new costume: a value that *looks* like a name
is often a path or a key, and the only way to know which is to look at what the other end actually
reads. It cost a client crash to learn, and it is written here so it costs no more than that.

## 6dr. The star map is shelved, and the owner writes their own - 2026-10-15

The second in-game attempt crashed too, in a different place, and the owner's call after it was to stop
and build their own map instead. Both are recorded here because the first decision is a *withdrawal* and
the second is a *specification*, and the second is what the next round of work follows.

### Why it stopped (the second crash)

```
NullPointerException: Rendering screen
  at asmodeuscore...NewGuiCelestialSelection.getScale(...:3219)
  at asmodeuscore...NewGuiCelestialSelection.drawCircles(...:2929)
```

`drawCircles` draws, per system, **its main star**, and per body **its orbit** - and the registration set
neither: no `setMainStar(Star)` on any of the 74 systems, and no `setRelativeDistanceFromCenter(...)` on
any body. The renderer dereferences both, so a missing "decoration" is a crash.

**The two crashes are the same mistake twice.** 6dq: a value that looked like a name (`"MilkyWay"`) was a
texture path. 6dr: fields that looked like decoration (main star, orbit radius) are dereferenced. Both
were only discoverable in a client, and this project is verified on a dedicated server, so every wrong
guess is paid for with one of the owner's client restarts. That is the reason for the withdrawal, not the
amount of work left.

**State: `MinespacePlanetSkyRegistry` is disabled** - the call is commented out in `Minespace.java` with
all of the above in the comment, so it is not re-enabled by accident. Verified: the server reports
`Registered 81 planned dimensions ...`, `Loaded 126 worldgen definitions`, and **zero** `Star map` lines
(the registration no longer runs). The dimension registration (6dm) and every vein file are untouched: it
is only the map that is off.

What the map needs, when someone builds it properly or re-enables that class: a `Star` per system, a
`relativeDistanceFromCenter` + `relativeOrbitTime` + `phaseShift` per body, a galaxy identifier that is
literally one of the textures that exist (`milky_way`, `andromeda` - this stack has only those two), and
an icon path that exists per body.

### The owner's own star map: what the plan already fixes, and where the data is

The plan does not leave this open-ended - it assigns the star map to the pack, in four places:

| the plan says | section |
| --- | --- |
| "星际航行引入**星图**、航道与燃料经济，航道由**研究数据**解锁" | 4.3 |
| M2 太阳系大满贯 → "**星图金标**与专属任务书条目" | 3 |
| M8 星系的路标 → "**门网络图鉴**解锁，超深空快速通行" | 3 |
| M10 超星系之网 → "**宇宙之网**全图点亮，此后没有终点" | 3 |
| 界面走 "Forge GUI、SkyRenderer、自定义 ParticleType 与 billboard" | 5.6 |
| 星图是研究链的产物：射电望远镜阵列 → 深空探测器控制中心 → 航道解锁 | 4.5 |

So: the map is **not** a view of Galacticraft's registry, it is the pack's own screen, and what gates it
is **research data**, not rocket tiers. That also settles why a Galacticraft-based attempt was the wrong
vehicle: GC's map is a picture of GC's own galaxy, while this pack's subject is 106 bodies across seven
layers, 44 of which cannot be landed on at all.

**The data it needs already exists**, and all of it is generated from the owner's catalog:

| what the map shows | where it comes from |
| --- | --- |
| the 106 bodies, their layer, stage, distance, temperature, host star | `planet-catalog.psd1` → `planet-catalog.csv` |
| which can be landed on, and which are observation only | the catalog's `Type` column, already reduced to a boolean in `MinespacePlanetDimensions.java` |
| dimension id per body, and whether it already exists | `PlannedDim` / `NativeDim` |
| what each body's veins are, once written | `planet-veins.psd1` (the catalog's vein column already reads it) |
| what a stage can actually reach - the numbers behind "航道解锁" | `tools\check-resource-closure.ps1`'s closure ladder |
| ruin class per body (I / II / III / IV / unknown) | the catalog's `Ruin` column |

### What is still the owner's call

1. **Unlock gate**: the plan says research data. Which research item opens which layer is not written
   anywhere yet, and it is the one thing the map cannot be built without.
2. **What the map shows at once**: all 106 from the start (with locked ones greyed) or only what has been
   discovered - the plan's M2 and M10 both imply the second.
3. **2D schematic or 3D positions**: the plan's asset pipeline (5.6) suggests 2D with generated art is
   affordable, and the catalog's real distances span 26 orders of magnitude, so a linear plot is not an
   option either way.
4. **Whether it reuses PlanetProgression's telescope** (already in the pack, already a research chain) as
   the *entry point* to the screen, or ignores it.

### The shape the owner wants: a 3D map in the No Man's Sky style

Three consequences worth writing down before any of it is built.

**It is buildable in this stack.** A Forge `GuiScreen` with its own GL camera - drag to orbit, scroll to
zoom, stars as billboards, lanes as lines - is ordinary 1.12 work, and the pack already renders 3D skies
(`SkyRenderer` through Galaxy Space and AsmodeusCore). The plan's own asset pipeline (5.6) names
billboards and particles for exactly this.

**The one real question is where the coordinates come from**, and there are three answers:

1. **Real ones.** The source the catalog already fetches from - the NASA Exoplanet Archive's
   `pscomppars` table - carries `ra`, `dec` and `sy_dist`, so a genuine cartesian position per system is
   **one set of columns away** from the data that is already in `nasa-planet-data.json`. That gives a map
   that is astronomically true, which suits a pack whose whole premise is real bodies with real numbers.
2. **Derived ones.** Layer becomes a shell radius, the host star a point inside it, the bodies arranged
   around their star. No new data, no external dependency, and honest as a *schematic* - but it is a
   diagram that resembles the galaxy rather than one that is the galaxy.
3. **Hand-placed.** Rejected: 106 bodies is past the point where hand placement stays consistent, and it
   is the one option that cannot be regenerated from the catalog.

**Scale is the thing that will break it if it is not decided first.** The catalog's distances span from
0.0000026 light years to 46.5 billion - twenty-six orders of magnitude. No camera, no zoom curve and no
logarithm makes that one continuous 3D space; the layers have to become **concentric shells with their
own scales**, which is what the plan's own seven-layer structure is for. That is also what makes the
research gate legible: a shell is what a research item unlocks.

So the first artefact the map needs is a per-body **(x, y, z) plus its shell** - real if the fetcher is
re-run with RA/Dec, derived if not. Everything else about the screen can be built against either.

## 6ds. The crash that was not this build, and the day the 81 dimensions were switched off - 2026-10-15

The owner's report was two words - "还是崩溃了" - and it arrived a few minutes after the AE2 fix (the
`Invalid dimension id -11` crash below) had been deployed. The build that was running when it happened
had the 81 planned dimensions registered (6dm), and Galacticraft's client init is dimension-heavy, so the
newest thing in the build was the obvious suspect. It was switched off, the jar was rebuilt, and then the
evidence had to be read, because "the newest thing" is a suspect list generator and not a diagnosis.

What the machine actually recorded:

- **No crash report.** The newest file in `crash-reports\` is still `crash-2026-10-15_20.37.30-client.txt`,
  and that one is the AE2 dimension crash this round had already fixed.
- **The log stops mid-sentence.** `logs\latest.log` and `debug.log` both end at
  `Sending event FMLInitializationEvent to mod galacticraftcore` with nothing after it - no exception, no
  stack, no FML "Reported exception thrown". FML logs the event it is about to send and then the event: the
  second half never happened.
- **No JVM-level death.** The only `hs_err_pid*.log` on the machine is from 2026-10-12. A JVM that dies of
  a native fault writes one, every time.
- **No operating-system kill either.** The Windows Application log has no error event for any `java`
  process in the hour around it, and the System log has no low-memory event.

So: not an exception, not a fatal error, not a recorded OS kill. A process that ends like that was ended -
closed, killed, or cut short - and no log in this project's reach can distinguish those cases afterwards.

Two more pieces of evidence settled the question of what it *was not*:

- **Galacticraft cannot exit the game itself.** `javap -c` over the whole jar finds no `System.exit` and no
  `Runtime.halt` anywhere in it, and its `init` is the loop this round suspected - it walks its own
  celestial bodies and calls `GalacticraftRegistry.registerDimension(...)` per body, which is why extra
  dimensions looked plausible.
- **The same jar loaded fine, twice.** A client launched from the deployed jar (the run the owner played
  in) reached the main menu, loaded a world and opened the star map with all 81 dimensions registered; a
  second client, launched from a copy of the instance with the registration switched back on, loaded to
  the main menu and self-captured the star map. Two clean runs is not proof of innocence, but it does mean
  the suspect did not reproduce, and a finished milestone (6dm) should not stay switched off on an
  unreproduced suspicion. **6dt re-enabled it.**

The lesson is worth more than the crash: this project verifies on a dedicated server, and a client that is
killed leaves *nothing* in the game's own logs. When a client "crashes" with no report, the useful
questions are not "which of our changes did it" but "was it killed, and what was the machine doing" -
which is why 6dt builds a way to run a client on purpose instead of asking the owner to keep launching one.

## 6dt. The star map gets its first real look, and a camera to look at it with - 2026-10-15

The owner's screenshot ended the guessing about the visuals in one go: **every star was a quarter disc and
the backdrop was two enormous circles.** Both had the same root cause, and neither was the texture.

### The four bugs, and what found each of them

1. **Fans instead of spheres.** `drawModalRectWithCustomSizedTexture` computes its UVs as
   `(offset + pixel) / textureSize`, so the last two arguments are *the size of the texture*, not a hint.
   The code passed the sprite's real size (64) while drawing it 30 pixels wide, which samples the top-left
   30/64 of the image - and the top-left 30/64 of a centred radial gradient is a quarter disc. The fix is
   to pass the drawn size as the texture size: `drawModalRectWithCustomSizedTexture(x, y, 0, 0, side, side,
   side, side)` samples the whole sprite at any size, which is what one sprite drawn as both a two-pixel
   core and a thirty-pixel halo needs.
2. **The backdrop was two circles** because it *was* the star sprite, blown up to the size of the screen.
   A nebula wants structure and a radial gradient has none. It is now a real photograph: NASA's *Cosmic
   Cliffs* (Carina Nebula, JWST - NASA material is public domain, credit written next to the source),
   cropped to 1280x640, blurred twice, brightness 0.75, gamma 2.0, vignette 0.55, with a half-transparent
   scrim drawn over it so labels stay readable. `tools\build-starmap-art.ps1` generates it and the glow
   sprite from the source image, so both files are reproducible rather than hand-drawn.
3. **The starfield came out as a diagonal line.** 520 dust stars were placed with `hash("du" + i)`, and a
   string hash advances by a small amount for successive strings, so the "random" points were a line across
   the sky. A counter needs a mixer, not a hash: it is now an xorshift-multiply scramble, which is the
   standard fix for exactly this.
4. **The orbit rings were drawn zero times.** A local `float height` shadowed `GuiScreen.height`, so the
   bounds check below it compared the screen against 0.06 and threw away every dot. The rings were correct
   and invisible - the same symptom as a ring that is too faint - and what said so was the capture
   harness's own log line, `orbit rings: 0 dots for 7 bodies`.

Also in this round: a label beside each star (the selected and hovered one always, every system once
zoomed past 1.45, every body of a system always), the **你在这里 · Sol** marker with its own colour,
the map scaled against the screen's width rather than its height (the old scaling left the sides empty -
the "a knot in the middle" complaint in a new costume), and the legend's `LuV~ZPM` corrected to
`LuV-ZPM` because the vanilla font has no tilde and drew `LuV^ZPM`.

### The camera: `-Dminespace.starmap.capture=<directory>`

Every visual bug above cost a client restart, and the reason is structural: this project can verify a
dedicated server, and cannot see a screen. So the screen now photographs itself. With that flag set,
`MinespaceStarMapKey` opens the map by itself once the game is past its loading screens, the screen draws
the overview, **reads its own framebuffer back** with `glReadPixels`, writes it to a PNG, switches to the
first system with several bodies, captures that too, and quits. A whole run is two and a half minutes and
needs nobody to press anything - which is how all four bugs above were found and confirmed fixed inside one
session.

It is deliberately a run-time flag rather than a build-time one, and a player without the flag sees exactly
the same jar with the harness dormant. The instance used for it is a copy of the game directory
(`D:\minespace-capture-run`): its own `mods`, its own `logs`, and no `saves`, so a capture run cannot
touch the owner's world.

Verified: the capture run with the dimension registration re-enabled reports
`Registered 81 planned dimensions (37 landable, 44 observation only), 0 already owned by another mod, 23
left to their owners; 104 in total from PLANET-CATALOG`, then `Loaded 126 worldgen definitions`, then
`orbit rings: 308 dots for 7 bodies`, writes both PNGs and shuts down cleanly.

## 6du. A cloud instead of a doughnut, and motion instead of jumps - 2026-10-15

The owner's verdict on 6dt's map was two words of geometry and one of them was right: *"还是不是很舒服，感觉
不是大空间布局，看起来还是一个大甜甜圈布局"*. The stars were no longer fans and the backdrop was no longer
two circles, but the map itself was a flat disc - and from the default camera angle a flat disc of stars reads
as a ring.

### Why it was a doughnut

6dp's layout gave every system a radius from its layer and then spread that layer's systems around the *circle*
at that radius, with a vertical wobble of ±0.055. Every system therefore lay in the same plane. The projection
could not hide it: the GUI is twice as wide as it is tall, so the plane filled the width and left the top and
bottom empty, which is precisely a doughnut seen edge-on.

The fix is a volume. Positions now come from a **Fibonacci sphere** - the standard way to spread n points
evenly over a sphere, and one that never lines successive indices up the way a golden-angle walk on a circle
does - with the layer deciding the shell and a jitter of 0.85..1.15 of it so the shells blur into one cloud.
The cloud is then stretched along x and z into an **ellipsoid**, and the projection stays a single scale for
both axes. Both of those are the same decision seen twice: *fill a widescreen frame by changing the shape of
the thing, not by squashing the drawing of it.* The first attempt here did the opposite - one scale per axis -
and produced a flat band, which is the doughnut in yet another costume.

The consequence worth knowing: with systems spread over a volume, the outermost ones leave the frame at the
default zoom. They rotate back into view, which is the point - the map is bigger than the window - and the
zero of that scale is a judgement, not a measurement: 0.52 of the smaller screen axis, chosen because 0.46 kept
every star inside the frame and left the frame looking half empty.

### The motion

Everything the screen does now eases, and all of it is driven by wall-clock deltas (`System.nanoTime`, clamped
at 0.1 s so a GC pause does not teleport the camera) rather than by per-frame fractions:

* **The camera is drawn and asked-for at once.** A drag moves a target; the drawn angle follows it a frame
  behind, `1 - exp(-dt * 14)`. That is the difference between a map that snaps to the mouse and one that has
  mass.
* **A flick keeps turning.** The drag's last velocity is kept and applied to the target after release, decaying
  at `exp(-dt * 3.2)`. A slow drag is set to zero on release, so only a flick coasts.
* **Zoom is a target too**, so a wheel notch is a move rather than a jump in scale.
* **The level change is a cross-fade.** Both layers - the systems and the chosen system's bodies - are drawn at
  once, one fading out as the other fades in, the arriving layer starting 55% oversized so it reads as a move
  towards the cluster rather than a dissolve. The level switch itself happens at the midpoint, where the two
  layers are least visible, so no frame ever shows a half-changed state. A 42% darkening over the whole screen
  peaks at that midpoint, because half of each layer is not a picture of anything.
* **The screen fades up from black** over 0.45 s, and **stars twinkle** (±13%, per-star phase) and the hover
  highlight pulses rather than blinking on.

Input is refused while a change is in flight: during the cross-fade the positions on screen belong to a layer
that is on its way out, and picking one of those is the kind of surprise that reads as a bug.

### What the camera caught this time

The capture harness now takes **four** poses - overview, overview turned, *the middle of the transition*, and
the system - and it earned its keep immediately: the first capture of the animated build was the nebula
backdrop with no stars on it at all. The cause was mine and was silent: `transition` means "progress through a
change" (0 just started, 1 settled), and the overview's alpha was written as `1 - eased`, which is 0 when
nothing is changing. Nothing threw, nothing logged; the map simply drew its background and stopped. A second
capture, of the same build, is what said so.

Two smaller things came out of the same round: labels are now placed nearest-first with overlap rejection
(seven bodies of one system sit within a hundred pixels of each other, and "label everything" without it is a
pile of names), and the transition pose is caught by **fade progress**, not by a frame count, so it is the same
picture at 20 fps and at 60.

Verified: four captures at 1920x1000 (the owner's GUI scale, 480x250), and the server baseline unchanged -
`Registered 81 planned dimensions ... 104 in total`, `Loaded 126 worldgen definitions`, 47 mods,
`Done (...)`, 19 `Exception` mentions.

## 6dv. The card comes to the cursor - 2026-10-15

The owner's next note was about where the information lives: *"行星选中提示框可以做成在星球、星系范围内显示跟踪
鼠标显示"* - the card should be next to the thing it describes, following the cursor, instead of pinned in a
corner. On a screen whose entire content is positions, a card 400 pixels from the star is the wrong shape: the
eye has to go there and come back.

So the fixed bottom-right card is gone, and with it the duplicate line of text the screen used to print along
the bottom edge. In its place:

* **A tooltip that follows the cursor**, offset down-right of it, **flipped** to the left when it would cross
  the right edge and upwards when it would cross the bottom one, and clamped if it fits on neither side. The
  cursor can be anywhere, so that placement is the whole job.
* **Anchored to the selection when the cursor is not on the map.** A clicked star keeps its card next to
  itself, so the map answers "what did I just click" without the cursor having to stay there.
* **More per line, fewer lines**: the title, the Chinese name, the layer *with its colour and its voltage band*
  (`3 中距 (LuV-ZPM)` - the layer name is the catalog's, not a number), stage, landable or observation-only,
  host star, and the vein count. A system in the overview says how many bodies it holds and what the next click
  does.
* **Corner brackets instead of a box** around the selection: a closed rectangle around a star competes with the
  star, and a reticle frames it while leaving the middle alone. It is the same four `drawRect` calls a ring is,
  only shorter.

The capture harness got one more instrument for this: a **fake cursor**. A capture run has no mouse, and a
screen whose tooltip placement is never exercised is a screen whose tooltip placement is untested, so the
harness parks the pointer on the rightmost system for one pose - which is exactly the case that has to flip -
and the photographs show the card on the correct side of the cursor, with the layer's colour in its border.

## 6dw. It fills the frame, because the scale is measured, and the map can be moved - 2026-10-15

The owner's last note named three things at once: *"默认情况下星系遍布整个屏幕，可以缩进查看，可以旋转查看，左右上下
平移查看"* - spread over the whole screen by default, zoomable, rotatable, **pannable**. Two of the three were
missing, and the third was hiding a mistake.

### Filling the frame cannot be a constant

6du gave the cloud a fixed scale, and 0.52 of the smaller screen axis was the wrong shape of answer: a cloud
fitted at one angle is not fitted at another, and what the owner saw was the parts of the frame that were
empty. `fitScale` now **measures** the extent of the layer's nodes after rotating them by the camera that is
about to draw them, and sets the scale so that extent meets the frame. Three details make it work rather than
merely exist:

* It is a **92nd percentile of the projected extent, not the maximum**. Fitting to the farthest of seventy-seven
  systems lets one stray point shrink the whole cloud; letting the outermost few leave the screen is what makes
  it feel like a map instead of a picture of a map.
* It is **eased between frames** (`1 - exp(-dt * 7)`), so turning the map does not make it jump as the
  measurement changes.
* It is **kept per layer**: seventy-seven systems and one system's seven bodies do not fit at the same size, and
  the cross-fade draws both at once. The arriving layer therefore also arrives from its own scale, which turns
  out to look like a move towards the cluster.

The margin (26 px horizontally, 20 px vertically) is not decoration either: the outermost node's label is drawn
to its right, and a fit that touches the edge cuts that label off the screen.

### Panning

* **Right drag or middle drag moves the map under the window**, one screen pixel per pixel of mouse: at any zoom
  or angle that is what a hand expects.
* **WASD or the arrow keys** do the same without a mouse.
* **R** puts the view back - angle, zoom and position - because a map that can be moved needs a defined way back
  to the middle.
* **A right click is still "back out"**: the decision is made on release. If the button never moved, nothing was
  panned and the click was a click.
* Panning is clamped, and the reach grows with the zoom (`max(0.32 * screen, fitted * zoom * 0.9)`): at three
  times zoom an outer system has to be bringable to the middle of the screen, and at the widest view the cloud
  has to stay reachable.

Verified by the four captures at 1920x1000: the cloud reaches all four edges at the default angle *and* at a
turned one, and the system view puts all seven bodies of TRAPPIST-1 inside the frame with their labels.

## 6dx. The chart, the journey, and where turning belongs - 2026-10-15

6dw's answer to "spread over the whole screen" was a measured fit, and the owner's reply named the picture they
actually meant: *"这样的布局才对"* over a zoomed-in view of the map, followed by *"滚轮缩放看到更远的星系，平移
移动，直到看到未知星系"* and the rule that decides the controls - *"在主视图去掉旋转查看，旋转查看只在星系详细
查看"*.

So the screen is now a **chart you travel**, not a ball you spin:

* **The overview does not rotate.** The camera angle is fixed; a drag moves the map. Rotation lives only in a
  system's own view, where it is the only way to see what orbits what. The press is still decided on release, so
  a click that never moved is a click: on a system it goes one level in, on nothing it starts a pan.
* **Panning works from every button in the overview** and from the right or middle button inside a system, plus
  WASD and the arrow keys, plus R to put the view back. That is why the click/drag decision moved to release -
  a pan has to be startable anywhere on the chart, including on top of a star.
* **The layers are laid out geometrically outward** (`0.60 * 1.42^(layer-2)`, so layer 2 is next door and layer
  7 is 6.3× further out, `LAYOUT_REACH` measures the result). A linear ramp had put the unknown systems in the
  same view as the near ones, and "travel until you see the unknown" needs them to be somewhere.
* **The fit is a percentile, and which percentile is the design.** The overview is fitted to its 35th - the near
  third fills the frame and the rest of the chart is genuinely off screen - while a system's own bodies are
  fitted to their 92nd, because a system is one glance and not a journey. Zoom now runs 0.5..3.5, so pulling back
  to see the outer layers is a few notches and never collapses the map to a knot.
* **Every star on screen is labelled**, in both views, which is what the owner's reference picture shows; the
  overlap rejection from 6du is what keeps it readable, and home is named once (its own marker) rather than
  twice. The title, legend and hint line got small dark backings, because a chart that names everything will
  always put one of those names under the legend.

The capture harness followed: five poses now - overview, overview pulled back to 0.5 (where the far layers and
the unknown systems appear), the middle of the transition, the system, and the system **turned**. The last two
exist to pin the rule down: rotation is only reachable inside a system, and the first and second overview poses
are taken from the same angle on purpose.

## 6dy. The wheel is a camera, not a scale - 2026-10-15

The owner's correction was one sentence and it named the projection: *"3D 放大是穿梭查看，不是上下移动看，是由远到近
的过程；平移只是查看当前平面的星系"*. Everything up to here zoomed by scaling the drawing, which is a picture
growing - the stars move outward from the centre together and nothing is ever passed. What they want is the
camera moving: the near stars sweep past the edge, the far ones shrink away, and a star that goes past the eye
disappears.

So the projection is a **perspective** now. Each frame has a focal length (pixels per unit at the reference
distance) and a camera distance, and a point is drawn at `r * focal / (distance - depth)`. Three numbers carry
the whole thing:

* **The focal** comes from `fitScale`, which now measures the 35th percentile of `r / depth` instead of `r` - the
  same "near third of the chart fills the frame" rule, measured through the projection that will draw it.
* **The distance** comes from the wheel, as `reference * exp(-zoom + 1)`: one notch is a fixed *ratio* of
  distance, which is the only way a chart whose near layer is one unit out and whose far layer is seven units out
  can be travelled at all. A fixed minimum distance was the first version and it quietly made the last half of
  the wheel dead.
* **The near plane** scales with the reference distance, and anything past it comes back as NaN and is skipped -
  that is what "flying past a star" means in code.

Two things had to change for the flight to arrive *somewhere*:

* **The layout fills its volume.** The radii used to sit on shells (`layer radius * jitter`), so the middle of the
  map was empty and flying in produced a frame with nothing in it - photographed, not guessed, twice. A radius
  uniform in volume (`cbrt`) with a floor is what puts stars in front of the camera all the way in, while a far
  layer still never lands next door to home.
* **The dolly is bounded**, at 0.45 to 2.2 times the reference distance: a factor of 4.9 in distance between the
  far end and the near one. Deeper than that and seventy-seven systems stop filling the frame - a galaxy would,
  a catalogue does not - so the deepest view is a close approach rather than an empty screen.

*Panning is unchanged and is still what the owner described: it moves the view across the current plane, one
screen pixel per pixel of mouse, at any distance.

The capture harness now photographs the flight itself: overview at the reference distance, pulled back to the
far end, flown in to the near end, the transition, and a system at both ends. The two "flown in" poses are the
ones that answer whether the zoom is a camera or a scale - if it were a scale, they would be the same picture
with everything proportionally larger.

## 6dz. Bands, home in the middle, and the objects that are not systems - 2026-10-15

Four things in one note from the owner: *"这些星系的排布由近到远 ... 有些星系没有恒星，其本身就是一个天体，不是恒星
系统，需要改，然后星系的排列也要改，特别是太阳系的，gc gs 的星球要沿用"*.

**Near to far is now a shape, not a tendency.** The radii used to be geometric shells with a wide jitter, so
adjacent layers overlapped and the chart had no readable order. Each layer now owns an **annulus** and no two
annuli touch: home is 0, layer 2 starts at 0.55 units and every band is 1.7x further out than the one before,
and inside a band the radius is uniform in *area* (the square root of the interpolation) so a ring of stars is an
even ring. **Home sits at the origin** - "特别是太阳系的": every distance on this chart is measured from the solar
system, so it is the middle of it rather than one ring among many, which is also where the 你在这里 marker
already was.

**An object is not a system.** 44 of the 77 nodes are single bodies - stars, black holes, galaxies, quasars,
pulsars, the CMB - and they were drawn as small grey balls that read as "a system we have not filled in". They
now get their own mark: a pale core with a thin ring around it, instead of the soft coloured ball a star system
gets. The card says it in words (单一天体 · 非恒星系, and no host star line), and the title counts them separately,
which is what the header now reads: `33 个恒星系 · 44 个单一天体（104 个天体）`.

### What the Galacticraft / Galaxy Space audit found (this is the part that needs a data round)

The owner asked for the GC and GS planets to be **reused**, so the catalog was checked against what those two mods
actually register. The dimension ids were read out of `javap -c` on
`galaxyspace/core/configs/GSConfigDimensions.class` and `ConfigManagerCore.class` rather than guessed:

```
GS: -1005 Mercury  -1006 Venus    -1007 Ceres    -1008 Pluto   -1009 Kuiper Belt
    -1012 Phobos   -1013 Deimos   -1014 Io       -1015 Europa  -1016 Ganymede
    -1017 Enceladus -1018 Titan   -1021 Triton   -1022 Callisto -1023 Haumea
    -1024 Miranda  -1026 Jupiter  -1234 (test)
GC: -28 Moon  -29 Mars  -30 Asteroid belt  -31 Venus    (-27/-26 space station and
    its copy: not planets)
```

Against the table this pack generates:

- **Venus is missing from the star map.** The catalog row has `NativeDim = -31;-1006` (the same planet exists as a
  GC dimension *and* a GS one, which is what the catalog's own note says), and
  `gen-planet-dimension-table.ps1` only accepts a cell that is a single number - so the row has been silently
  dropped ever since the table was first generated. Nothing else is affected by that filter; it is one body.
- **Jupiter is missing from the catalog entirely** (`-1026`). The CSV has no row for it.
- Everything else matches: the other 15 GS bodies, the three GC ones, Barnarda C/c/d (-1030..-1032), Proxima b
  (-1025) and Tau Ceti f (-1338) are all in the table with the right ids.

Fixing those two is a data round, not a screen round: a row for Jupiter (layer, geology card, veins, Chinese name)
and a generator that accepts `-31;-1006`, then `build-planet-veins.ps1`, the dimension table and the vein audit
re-run. It is written down here because it is a real hole in "gc gs 的星球要沿用" and because the audit above is
the evidence for it.

## 6ea. The solar system in the right order, and the two bodies that were missing - 2026-10-16

The owner's verdict on the solar system view was one question - *"你觉得这个太阳系对吗"* - and the answer was no.
The rings were not distances at all: they were the order the table happened to be generated in (descending dimension
id), so Mercury sat on the outer ring, the Moon on the outermost, Jupiter's moons inside Mars, and the Kuiper belt
closer to the Sun than Mars. The fix is in three places:

* **The catalog carries a real orbital distance now** (`OrbitAu`, a new column in `tools\planet-catalog.csv`): the
  nineteen solar-system bodies get their true figures (Mercury 0.387, Venus 0.723, Moon 1.000, Mars 1.524, Phobos
  1.5241, Deimos 1.5242, asteroid belt 2.700, Ceres 2.770, Io/Europa/Ganymede/Callisto 5.2030..5.2033, Enceladus
  9.5400, Titan 9.5401, Miranda 19.200, Triton 30.100, Pluto 39.240, Haumea 43.100, Kuiper belt 44.000). A moon
  carries its **parent planet's** distance plus a small offset, so a moon is drawn at its planet's orbit and the
  moons of one planet keep their real order among themselves - which is also the honest thing to draw, since they
  orbit the planet and not the star.
* **The generator accepts more than one id per row and reads the distance.** Venus is the same planet as
  Galacticraft's `-31` *and* Galaxy Space's `-1006`; the catalog writes `-31;-1006`, and `gen-planet-dimension-table.ps1`
  only accepted a cell that was nothing but one number, so **Venus had been silently missing from the star map
  since the table was first generated**. The first id in the cell is the body's own and the others are its mirrors.
  The generator also emits `orbitAu` and honours a `Landable` column: **Jupiter is a new row** (`-1026`, non-landable,
  no veins, "气态巨行星：不可登录、无矿脉；沿用 GC/GS 的 -1026"), because the owner's rule for gas giants is that they are
  not somewhere to put a rocket down. The table went from 104 to **106 bodies**.
* **The screen orders by that distance and draws it on a log scale.** Bodies of a system are sorted by `orbitAu`
  (falling back to table order for the systems the catalog has no figure for), the ring radius is
  `0.26 + 0.74 * (ln AU - ln 0.3) / (ln 50 - ln 0.3)` - a linear radius over 0.387..44 AU cannot work - and the
  card carries `距恒星 X AU`. `Minespace-unofficial\tools\planet-catalog.csv.bak-6ea` is the file as it was before
  the edit.

Not yet done, and the honest state of this round: the new order has **not** been photographed yet (the build compiles,
the generator reports `wrote 106 planned dimensions ... landable 62, observation only 44`, and the deployed jar
matches the build), and the belts are still drawn as single points rather than as dotted bands. The capture harness
is the way to check it: `-Dminespace.starmap.capture=...` on the copied instance, poses 4/5 are the system view.

## 6eb. A solar system with its planets, and moons that orbit something - 2026-10-16

The owner looked at 6ea's solar system and named what was still wrong: *"海王星天王星没有，该有的卫星没有体现出绕着谁
旋转"*. Both were true, and both were data-shaped problems rather than drawing problems.

**Four planets were missing, not two.** Galacticraft and Galaxy Space register dimensions for the Moon, Mars, the
asteroid belt, Mercury, Venus, Ceres, Pluto, the Kuiper belt, Phobos, Deimos, Io, Europa, Ganymede, Enceladus,
Titan, Triton, Callisto, Haumea, Miranda and Jupiter - and for no other planet of the solar system. So the map had
Jupiter's moons without Jupiter, Saturn's moons without Saturn, Miranda without Uranus and Triton without Neptune,
and no Earth at all. Four rows were added to the catalog:

| body | id | why that id | landable |
|---|---|---|---|
| Earth | `0` | it *is* the Overworld, the one place the player already stands on | yes |
| Saturn | `-1996` | no mod registers a dimension for it | no - gas giant |
| Uranus | `-1997` | no mod registers a dimension for it | no - ice giant |
| Neptune | `-1998` | no mod registers a dimension for it | no - ice giant |

The three placeholder ids sit in the band above `-2000`, which this pack's own registration **skips by construction**
(`if (planet.dimensionId > -2000) continue;`), so the map gains three nodes and the game gains no half-built void
worlds for planets nobody can land on. If a travel route to them is ever wanted, that is the row to change.

**A moon now says what it orbits.** The catalog gained a `Parent` column (Moon→Earth, Phobos/Deimos→Mars,
Io/Europa/Ganymede/Callisto→Jupiter, Enceladus/Titan→Saturn, Miranda→Uranus, Triton→Neptune) and the distance
column was re-cut so a parent always sorts **before** its moons (Earth 1.000 / Moon 1.001, Mars 1.524 / Phobos
1.525 / Deimos 1.526, Jupiter 5.204 / Io 5.205 ... Saturn 9.583 / Enceladus 9.584, Uranus 19.191 / Miranda 19.192,
Neptune 30.069 / Triton 30.070). On the screen a moon is placed *on its planet*: same ring, same angle as the
planet, plus a 0.075-unit hop out along a halo, with the siblings spread round that halo so two moons of one planet
are never drawn on top of each other. Planets with moons wear a **dotted halo** (the same primitive the orbit rings
use), a moon gets no solar ring of its own, and the card says `卫星 · 绕 木星`. The planets' own card gained
`距恒星 X AU`, the gas and ice giants say `不可登录 · 无矿脉（气态/冰质）` instead of offering an empty vein count,
and layer 1 finally has a name of its own (`1 太阳系 (IV)`) - the card of every solar-system body used to read
`· stage 0`.

Verified on the copied instance at 1920x1000, with the harness now pointed at the solar system on purpose
(`firstSystemWithBodies` prefers `Sol`): the header reads `Sol  24 个天体`, the card of 金星 reads `距恒星 0.723 AU`,
water ice and rock are where they belong (Mercury inside, the four Galileans together on Jupiter's halo, Enceladus
on Saturn's, Uranus and Neptune and Pluto and Haumea outward), and the haloes are visible around Mars, Jupiter,
Saturn, Uranus and Neptune.

Still open: the asteroid and Kuiper belts are drawn as single points rather than as dotted bands, and the four new
planets have no stated voltage/stage plan of their own (they inherit the solar system's `0-3`). Neither blocks the
map; both are refinements.

## 6ec. How far from Earth, in the unit the number deserves - 2026-10-16

*"信息板上要写清楚距离地球多远"*. The catalog has carried a distance for 97 of its 111 rows all along, but as the text it
was curated in - `4.24 ly`, `~13.2 billion ly`, `384,400 km`, `43.1 AU (mean)` - which is a figure a reader has to
translate in their head, and the scale runs over twenty-six orders of magnitude.

So the catalog gained a **`DistanceLy`** column: the same figures, parsed to light years by a small function that
understands `ly`, `million ly`, `billion ly`, `AU` and `km` (and strips the `~` and the thousands separators). The
generator emits it, and the card prints it in the unit the size calls for:

| body | what the card says |
|---|---|
| the Moon | `距地球 384,400 公里` |
| Venus | `距地球 0.28 AU` (plus `距恒星 0.723 AU` - the ring it sits on) |
| Proxima Centauri b | `距地球 4.2 光年` |
| Vela Pulsar | `距地球 1,000 千光年` → `1.0 千光年` |
| the Andromeda galaxy | `距地球 2.5 百万光年` |
| GRB 090423 (the farthest thing in the catalog) | `距地球 13.0 十亿光年` |

Two rules keep it honest. Inside the solar system the figure is the **radial distance from Earth's orbit**
(`|AU − 1|`), because "how far is Venus" from a map is answered by the orbit it is on; and a body close enough to
Earth to make that number meaningless is printed in kilometres from its own catalog figure instead - which is exactly
the Moon, whose entry is its distance from Earth. Outside the solar system the figure is the **star's** distance from
Earth, since that is what a star map is for.

Found on the way: adding Earth in 6eb had created a **second** Earth row. The catalog already had a carefully written
one - no dimension ids, with a note saying the Overworld's veins are GregTech's own tables and `planet-veins.psd1`
deliberately does not touch it. The duplicate was removed and the original got the ids (`0`), the distance and the
landable flag, so there is one Earth row again and it is the curated one.

Verified on the copied instance at 1920x1000: the solar system's card for 金星 reads `1 太阳系 (IV) · stage 0` /
`距恒星 0.723 AU` / `距地球 0.28 AU` / `可登陆` / `宿主 Sol` / `矿脉 7 条`, and the overview's card for GRB 090423
reads `距地球 13.0 十亿光年`. `tools\planet-catalog.csv.bak-6eb` and `.bak-6ec` are the file before each edit.

## 6ed. Every kind of body drawn as itself, and orbits that move - 2026-10-16

Three things in one note: *"一些非恒星系查看还是有那颗静态的恒星在中央这不好，一些非行星天体应该呈现他们自有的形态而不是跟恒星
一样。还有恒星系最好能让星球转起来，确保真实按比例的公转周期"*.

**The catalog already knew what everything is** - its `Type` column carries Planet, Moon, DwarfPlanet, AsteroidBelt,
Star, WhiteDwarf, BlackHole, Galaxy, Nebula, Pulsar, Quasar, Cluster, CMB, CosmicWeb, GravitationalWave,
InterstellarObject, SupernovaRemnant - and the generator had never passed it on. It does now, and the screen draws
each kind as itself: a **galaxy** as a wide faint disc with a bright core, a **black hole** as a *dark* disc (the glow
sprite tinted black under normal blending - the only thing on this screen that takes light away) inside a bright ring,
a **pulsar** as a point that pulses inside a breathing ring, a **nebula** as a big soft cloud with a second tinted
one beside it, a **star or white dwarf** as a glowing ball, a **quasar** as a very bright core with a large halo, a
**cluster** as seven small points, and everything that is only ever seen as a marker (the CMB, a cosmic web, a
gravitational wave, an interstellar object) as the marker it was. The centre of a view was the worst of it: opening a
black hole used to draw a grey *star* in the middle of it. Now the middle of a node that is one object is that object.

**The planets move, with their real periods.** The catalog had a `Period` column for 54 of 110 rows, written as text
("11.86 y", "365.256", "~636 days"); it is now `PeriodDays`, a number, with the solar system filled in properly - and
that is where the round's own bug was found: the four planets added in 6eb were *clones of Mars's row*, so
`Period = 11.86 y` had been copied onto **Saturn, Uranus and Neptune** as well as Jupiter. The real figures are
10759.22, 30688.5 and 60182 days, and the moons are there too (Io 1.769, Phobos 0.3189, the Moon 27.3217). The screen
turns each body by `clock / (period × tempo)`, and `[` and `]` step the tempo by a factor of two so the same real
ratios can be watched at any pace.

## 6ee. Real ratios against a watchable map, and why both are now available - 2026-10-16

The owner watched 6ed's version for a minute and said *"这也太快了"*, then, after the tempo was made per system, said
*"比例还是太快了"*. Both statements are about the same tension, and it is worth writing down because it will come back:

**A real solar system cannot be shown in one tempo.** Mercury takes 88 days and Neptune 60,182 - a factor of 684.
TRAPPIST-1's seven planets take 1.51 to 18.8 days, so the tempo that suits the solar system gives TRAPPIST-1 five
orbits a second. Three settings now exist:

* **The tempo is per system.** The fastest *planet* of the system being looked at (moons excluded - they move inside
  a planet's halo, where speed is unreadable) gets 30 seconds for one orbit, and every other body in that system keeps
  its true ratio to it. `[` and `]` scale that by two either way.
* **`P` switches the ratios between real and compressed.** Real (`真`) keeps the true figure; compressed takes the
  0.35th power of the period ratio, which keeps the *order* real - nothing overtakes anything - and flattens it, so
  Neptune's 684x becomes about 8x. This is the honest way to have both: the compromise is a mode the owner chooses,
  not a number invented on their behalf.
* **The card always prints the true period** (`公转周期 60182 天`), whichever mode is on, so nothing is hidden.

The measured figures, taken from the generated table the game actually reads:

| system | real ratios, seconds per orbit | compressed |
|---|---|---|
| TRAPPIST-1 | b 30 · c 48 · d 80 · e 121 · f 183 · g 245 · h 373 | 30 -> 72 |
| Sol | Mercury 30 · Venus 77 · Earth 125 · Mars 234 · Jupiter 1478 (25 min) · Neptune 20,524 (5.7 h) | 30 · 49 · 117 · 295 · Kuiper 363 |

Verified to the data (every figure above is read back out of `MinespacePlanetDimensions`); the motion itself is checked
in 6ef, where the capture harness photographs one system twice, seconds apart.

## 6ef. The disc, the belts, and what the four new planets are for - 2026-10-16

The three items 6ed left open, all three closed.

**The accretion disc is visible now.** 6ed drew a black hole as a dark disc inside a ring of one-pixel dots, and the
photograph showed a black smudge with no ring at all - the dots vanished into the nebula. It is now light, drawn as
light: two additive stretches of the glow sprite (wide and flat, `radius * 7.5 x 2.3` and `radius * 5.4 x 1.5` in warm
gold) with the dark sprite on top of them, which is what leaves a bright rim around a black centre. Photographed at
1920x1000 with `-Dminespace.starmap.capture.system=M87`: a golden ellipse with a black hole in the middle of it.

**A belt is a band, not a ring.** The asteroid belt and the Kuiper belt were single dots on one orbit, which is exactly
what a rubble belt is not. `AsteroidBelt` bodies now draw **five** dotted rings from -6% to +6% of their distance
(fainter towards the edges) and their own marker shrinks to a small pale dust knot, so the band can still be hovered,
clicked and labelled; the card says `距恒星 2.70 AU（带状）`. Photographed on Sol: the two belts read as broad annuli
of rubble between Mars and Jupiter and beyond Neptune.

**What Earth, Saturn, Uranus and Neptune are for** is now written in the catalog rather than implied. All four sit at
`Stage 0-3` / `蒸汽~EV`, the solar system's own band, which is what they inherited and what is right for them: Earth is
the home world (its veins are GregTech's own tables and `planet-veins.psd1` deliberately does not touch it), and the
other three are **frame bodies** - non-landable, no veins, each one the parent of the moons that carry that band's
content (Jupiter: Io/Europa/Ganymede/Callisto - the four of them supply `desh` and the rest of the 0-3 materials;
Saturn: Enceladus and Titan; Uranus: Miranda; Neptune: Triton). `Layer` was also normalised to `sol` for the four, so
all 24 solar-system rows read the same way. The catalog is the source of truth and `tools\planet-catalog.csv.bak-6ef`
is the file before this edit; the generator's output is unchanged by it, because none of those columns is emitted.

Re-checked after the edit: `accept-planet-veins.ps1` green on all six criteria (126 files, 0 parse failures, 0
duplicates, 0 empty, 0 out of the 5..8 range, 0 without a dimension filter), and the deployed jar matches the build.

## 6eg. One object, one mark, in the middle - 2026-10-16

The owner opened the Crab Pulsar and asked the question the screen had no answer for: *"本来就是一个非恒星系天体为什么选择的是
中央静态之外的选项呢？不是应该直接选择中央的那个就可以了吗"*. The detail view of a body that is its own object was drawing it
**twice** - once at the centre as its own form (the 6ed fix) and once out on its "orbit", selectable, with the selection
brackets and the label attached to that second copy. A pulsar with an orbit is a contradiction, and so is selecting the
copy rather than the thing.

`position()` now returns the origin for any body with no host star, so a lone object **is** the middle of its own view:
the node draws nothing of its own (the centre form is the mark), and the label, the hover ring and the selection
brackets all land on the centre with it. The card lost its last two wrong lines as well - a single object was still
being told it had `无宿主恒星` and `矿脉待配置`; it now says `单一天体 · 非恒星系 · 仅观测`, which is what it is.
`fitScale` needed one guard for the same change: a system whose every node is at the origin has no extent to fit and
the percentile arithmetic would have divided by zero, so it returns a neutral scale instead.

Photographed at 1920x1000 with `-Dminespace.starmap.capture.system=Crab`: one pulsar, in the middle, labelled
`蟹状星云脉冲星`, and nothing else pretending to orbit it.

## 6eh. The first planned body that is a world, not a placeholder - 2026-10-16

§6dn ended on a measured wall: the eighty-one planned dimensions are registered and their ids are real, but they
cannot hold ore, because GregTech generates ore by *replacing the stone of a world* and a void dimension has no stone.
The chain from "an id exists" to "a planet you can mine" is **terrain, then a stone type, then veins**, and this round
built the first two links for one body.

The body is **TRAPPIST-1 e** (`-2103`, layer 3, stage 5): landable in the catalog, one of the worlds the star map
already names, and one nobody has touched. `MinespacePlanetTerrainPrototype` gives it:

* its **own provider** (`RockProvider`) instead of the shared `VoidProvider` - chosen in the registration loop by
  `isPrototype(planet)`, so the other eighty keep the void until their turn;
* a **chunk generator that builds ground**: bedrock at y=0, rock up to a surface height of 62 plus a swell of three
  sines of the world coordinates, air above. Not fractal noise and not pretending to be - what it has to prove is that
  a real generator runs there and produces ground a vein generator can walk over;
* a **GregTech stone type** (id 64, clear of GT's 0..15 and of Galaxy Space's), registered from
  `MinespaceMaterials.onMaterialsInit()` - the same window and the same reasoning as `MinespaceStoneTypes`.

**The rock is plain `minecraft:stone`, and that is deliberate.** It is honest rather than pretty: what this round
measures is the pipeline. The art pass (this mod's own rock block and texture, per body) and this body's vein files
are the next two rounds, and neither is needed to know whether the pipeline works.

Verified by a temporary probe on the dedicated server (`FMLServerStartedEvent`, opening the dimension and generating
chunk (0,0)), then deleted and the jar rebuilt:

```
Registered a stone type for trappist_1_e (id -2103, stone type 64) - the terrain prototype
PROBE terrain prototype: dimension -2103 chunk(0,0) y0=minecraft:bedrock y64=minecraft:stone
    y200=minecraft:air stoneTypeRecognised=true
```

`stoneTypeRecognised=true` is the line that matters: `StoneType.computeStoneType` resolves the prototype's rock, so a
vein whose filter names `-2103` will now generate there. The wall is down for one body, and the same three steps are
what the other eighty need.

## 6ei. The prototype is mineable: the third link - 2026-10-16

6eh built terrain and a stone type for TRAPPIST-1 e. The third link was already designed and waiting: the vein table
has carried a card for that body since the table was written - `Signature = 'dyson_wreck'`, `Pending = $true`, and a
region note saying in as many words that "signatures carry the ruin-delivered ore (TRAPPIST-1 e)". `Pending` meant
"no such dimension exists in the game yet, and generating vein files for it would put a planet nobody can reach into
JEI".

The body exists now, so `Pending` is `$false` and that is the whole change. The generator did the rest:

```
TRAPPIST-1 e (-2103) - 7 veins, total weight 750
    Frontier_Silicate_Vein        220   29.3%  5..60  bauxite / aluminium / quartzite / iron
    Frontier_Iron_Nickel_Vein     200   26.7%  5..60  iron / nickel / cobaltite / pentlandite
    Frontier_Sulfide_Vein         100   13.3%  5..50  sulfur / galena / lead / redstone
    Frontier_Rare_Earth_Vein       25    3.3%  5..35  bastnasite / monazite / neodymium / thorium
    Frontier_Volatile_Vein         60      8%  5..45  salt / rock_salt / trona / lithium
    Heavy_Refractory_Vein         120     16%  5..55  scheelite / molybdenite / molybdenum / powellite
    Dyson_Wreck_Vein               25    3.3%  5..40  trinium / triniite / bowieite
```

Seven veins, which is inside the plan's 5..8, and the signature is the ruin-delivered ore the card promised. Note what
the generator did with the files: five of the seven **already existed** for other bodies (a GT vein file carries a list
of dimension ids, which is how one definition reaches many bodies), so it added `-2103` to those lists and wrote only
two new files - `dyson_wreck_vein.json` and `heavy_refractory_vein.json`.

Verified end to end on the dedicated server:

```
Registered a stone type for trappist_1_e (id -2103, stone type 64) - the terrain prototype
Loaded 254 worldgen definitions        (was 126: the shared definitions now cover one more body)
Done (1.953s)   exceptions: 19

accept-planet-veins.ps1: 128 files, 0 parse failures, and all six criteria OK -
    including dimension -2103 with its 7 veins
```

That is the chain §6dn described as missing, closed for one body: **terrain, stone type, veins**. What is still not
true is that a player can *reach* it - there is no route and no research gate yet, which is the one piece of this that
needs the owner's decision - and its rock is still plain stone until the art pass. The other eighty bodies need the
same three steps, and 6eh's provider plus this round's two-line table edit are the shape that work takes.

## 6ej. Star system tiers, and the research data that opens them - 2026-10-16

Two decisions from the owner in one message: *"之后我们默认使用我们自己做的星图，不用 GCGS 的"* and *"我们现在可以规划恒星系等级
了，研究数据也要开始落实了"*. The first closes the question 6dr left open - the pack's own star map is the map, and
nothing gets registered into Galacticraft's celestial registry, which is also why the two crashes in 6dq/6dr stop
mattering: that screen is not on the path any more.

The second is the gate, and it needed a shape before it needed code. **The tiers are the layers already in the
catalog**, one piece of survey data each:

| tier | the data | layer | the band |
|---|---|---|---|
| I | 研究数据 I | 2 | 近邻 (IV) - Proxima, Barnard, Tau Ceti |
| II | 研究数据 II | 3 | 中距 (LuV~ZPM) - TRAPPIST-1 and the Gliese systems |
| III | 研究数据 III | 4 | 远距 (UV) - the Kepler field |
| IV | 研究数据 IV | 5 | 深空 (UHV) |
| V | 研究数据 V | 6 | 超深空 (UHV+) |
| VI | 研究数据 VI | 7 | 未知 (UHV+) |

What that buys is that no new taxonomy had to be invented: the legend, the card, the layer colours and the research
data all name the same seven bands, and the tier of any body is `layer - 1`.

### What was built

* **One item, six metadata values** (`MinespaceResearchData`, `minespace:research_data`, meta 1..6). Holding it is
  what unlocks - it is a key, not a consumable - so the check is a scan of the player's own inventory on the client,
  and the map never asks the server anything. `tierOfLayer` is the whole mapping.
* **The icons and the models are generated** (`tools\build-research-art.ps1`): six 16x16 cards whose stripe colour
  runs from violet at the near systems to white-hot at the unknown, with one bar per tier so the icons differ in
  shape as well as in hue, plus the six `item/generated` models a Forge subtype item needs.
* **The gate is on the map, not in a book.** A system beyond the player's data is drawn as a dim grey ball, its name
  is grey rather than blue, its card says `等级 VI · 未解锁（需 研究数据 VI）` in amber (`已解锁` in green once held),
  and a click on it is **refused** with a hint under the map for a few seconds - a click that does nothing at all
  reads as a bug. Locked bodies are *shown*: the plan's open question about hiding them is answered by showing them,
  because a chart of what is out there is the point of a chart.
  *(Superseded by 6ep: the owner's rule is now that an unsurveyed body is not on the chart at all - "同样的没解锁的天体，
  星系是不可找到的，只有解锁了才可以" - so the dim grey ball and the grey name are gone and the fit, the counters and the
  legend carry the progress instead.)*
* **The chain is a crafting chain for now** (`scripts\research_data.zs`): tier N = the previous tier's data + a
  circuit and a plate of the tier it opens (steel/basic, stainless/good, titanium/advanced, tungstensteel/elite,
  HSS-G/master, neutronium/ultimate), assembled at 30/120/480/1920/7680/30720 EU/t. It is written in the script and
  in the plan that this is a **placeholder for observing**: 4.3 wants lanes opened by survey work, and when that
  step exists only the recipe changes, not the item and not the gate.

### Verified

* The dedicated server: `254 worldgen definitions`, `Done (1.985s)`, 19 exceptions (the baseline) - and
  **`crafttweaker.log` with zero errors**, which is what proves every ore dictionary the six recipes name exists,
  including `circuitElite` / `circuitMaster` / `circuitUltimate` and the mod's own `minespace:research_data` item id.
* The capture harness: the overview photographs the locked state - dim balls, grey names, and the card's
  `等级 VI · 未解锁（需 研究数据 VI）` - because the capture client carries no data, which makes it the ideal subject
  for testing exactly this.

Not yet seen in game: the six icons themselves (they appear in the creative tab and JEI on the next client start), and
an unlocked map, which needs a player holding the data.

## 6ek. The rocket adapter: GC flies, the pack's map aims - 2026-10-16

The owner's choice between the two ways to reach a body this pack owns - adapt Galacticraft's rocket, or build a lane
mechanism of our own - was the adapter, with a note for the future (*"gcgs之外的东西可能我们会自己做"*: what lies outside
GC and GS we will build ourselves, in our own time).

The adapter is small because Galacticraft's rocket already knows how to fly somewhere: `EntityAutoRocket.targetDimension`
is a **public field**, and GC's own launch sequence - ignition, ascent, atmosphere, world transfer, landing - reads it.
So `MinespaceRocketTarget` does four things and no fifth:

1. the destination must be a body in this pack's catalog (looked up by dimension id, never invented);
2. the player must be **riding** a rocket - the vehicle stays Galacticraft's;
3. the gate: the layer's research data in the inventory, plus a rocket tier high enough (the layer halved, rounded up,
   capped at GC's four - the pack's own mapping, because GC has no opinion about layers it has never heard of);
4. it sets `targetDimension` and says so in chat. It deliberately does **not** ignite: the owner presses Galacticraft's
   own launch, which is what "keep GC's launch flow" means.

`MinespaceNetwork` is the mod's first packet - one int, the dimension id - because the map is drawn on the client and the
rocket lives on the server, and a client is never the authority on whether it may go somewhere: every check runs again
on the server. On the map side, `T` in a body's own view asks for it, the card says `按 T 设为火箭目的地（需 T2 火箭 + 燃料）`
for a body that is unlocked and landable, and a lone object says `不可登陆 · 无法设为目的地`.

Verified: the build, and a dedicated-server run with GC present - `254 worldgen definitions`, `Done (1.983s)`, 19
exceptions (the baseline), no `NoClassDefFoundError`, and the channel registered without complaint. What is **not**
verified is the flight itself: that needs a player in a fuelled rocket, which is the owner's half of this. The recipe
for the first piece of data is in `scripts\research_data.zs` (4 steel plates + 1 basic circuit + 8 paper in an LV
assembler).

## 6el. Why the two researches did not unlock together, and the bridge - 2026-10-16

The owner asked the question that found the gap: *"这个星球研究为什么不会跟行星研究一起解锁？"* - why does this pack's planet
research not unlock together with the planet research they already have (PlanetProgression's telescope work).

The answer was a wall, not an oversight of intent: **PlanetProgression stores its unlock state per Galacticraft
`CelestialBody`** - its API is `ResearchHooksMP/SP.hasUnlockedCelestialBody(player, body)` and
`hasUnlockedBodiesInSystem(player, system)` - and the eighty-one bodies this pack plans are deliberately **not**
registered into Galacticraft's celestial registry (the owner's decision in 6ej). There is no object to hand
PlanetProgression for them, so the two gates stood side by side with no shared key. That is the round's real mistake:
the research data was built as a self-contained system without asking what already existed.

There is a key for the bodies PlanetProgression *can* survey, and it is reachable by dimension id:
`GalaxyRegistry.getCelestialBodyFromDimensionID(int)`. `MinespacePlanetResearch` uses it to make the two one system:

* **A body Galacticraft knows** (the solar system, and the Galaxy Space outliers that registered into it):
  **PlanetProgression's research decides.** Survey the Moon with the telescope and the star map shows the Moon
  unlocked, with no second gate and no second item.
* **A body only this pack knows**: this pack's survey data decides, because nobody can have surveyed a world they have
  never heard of.

The card says which of the two is talking - `已解锁 · 行星研究` / `未解锁 · 由行星研究（望远镜）解锁`, or
`等级 III · 未解锁（需 研究数据 III）` - because "which book do I read next" is the whole job of a gate. The rocket
check on the server asks the same question through the MP hook, so the client is never the authority on whether it may
go somewhere.

PlanetProgression joined the build as a **compileOnly** dependency on the jar the instance ships, for the same reason
CraftTweaker and MixinBooter are: its classes carry the API in their signatures, the mod is not ours to bundle, and
every call stays behind a mod-presence check so the addon still loads without it (our data then being the only gate).

Verified: the build, and a dedicated-server run with PlanetProgression present - `Loaded 254 worldgen definitions`,
`Done (2.279s)`, **zero `NoClassDefFoundError`**, 19 exceptions (the baseline). Not yet seen in game: the two-line
change on the card, and the actual hand-off (survey a body in PlanetProgression, open the map, see it unlocked), which
needs the owner's client.

## 6em. Two reports from the owner's client, and what each one actually was - 2026-10-16

The owner tested 6ek/6el in game and reported two failures: *"按 t 确实选了一个星球但是发射后还是正常打开的是 gs 的星图"*, and
*"我用 PlanetProgression 命令解锁了所有行星但是新的星图连太阳系都没解锁"*.

**The launch: Galacticraft's launch button is a destination chooser.** Setting `targetDimension` and leaving the launch
to GC's own button cannot work, because that button *opens the celestial screen* and the player's pick overwrites
whatever was set. `MinespaceRocketTarget` now **ignites the rocket itself** (`igniteWithResult()`) after setting the
destination; GC's ascent, atmosphere, transfer and landing are untouched, which is what "keep GC's launch flow" meant.

**The unlock was this pack's own bug, and the card showed it.** The diagnostic added for this round
(`MinespacePlanetResearch.logDiagnostics`) printed, when the map opened:

```
PROBE research: dimension -28   -> galacticraft body moon.moon,        surveyed true
PROBE research: dimension -29   -> galacticraft body planet.mars,       surveyed true
PROBE research: dimension -1025 -> galacticraft body planet.proxima_b,  surveyed true
PROBE research: dimension -1030 -> galacticraft body planet.barnarda_c, surveyed true
```

So the lookup and PlanetProgression's client-side state were both fine: the fault was the *rule*. A system node on the
star map is one body out of that system (`node.body`), and the star map had been asking **that one body's** gate for the
whole system. The solar system's representative is Neptune - invented for the map in 6eb, so Galacticraft has no body
for its id - which pushed the entire solar system onto this pack's tier gate. The owner's screenshot shows the
fingerprint plainly: Sol's card read `等级 I · 未解锁（需 研究数据 I）` next to `距地球 30.069 AU`, and 30.069 AU is
Neptune.

The rule is now **a system is open when any of its bodies is**, and the per-system diagnostic confirms it where it
matters:

```
PROBE research system: Sol                      -> known to GC 19, surveyed by PP 19
PROBE research system: Proxima Cen M5.5 V        -> known to GC 1,  surveyed by PP 1
PROBE research system: Tau Ceti (G8 V)           -> known to GC 1,  surveyed by PP 1
PROBE research system: Barnard's star M3.5-4 V   -> known to GC 2,  surveyed by PP 2
```

Every system Galacticraft knows is fully surveyed, so every one of them is unlocked on the map; the systems that are
only this pack's do not appear in that list at all, because they have no Galacticraft body - which is exactly why they
keep the survey-data gate.

**One more thing, chased down and dismissed:** the owner's chat showed `You have discovered 月球! for: Minespace` and
asked whether this pack had mislabelled somebody else's bodies. The strings live in PlanetProgression's own
`CommandUnlockAllCelestialBody`, whose usage takes a **player** argument (` <player>`); the launcher runs the instance
as the offline user `Minespace`. So `for: Minespace` is the *player*, not a mod attribution, and nothing of ours is
claiming the Moon.

## 6en. Why the launch still opened Galacticraft's map, and the mixin that takes over - 2026-10-16

The owner reported the third attempt ending the same way: *"发射升空之后还是弹出 gs 的星图"* - the rocket now lifts off
(6em's self-ignition works), and then GC's celestial screen appears anyway.

`javap -c` on `EntityTieredRocket.onReachAtmosphere()` gives the whole answer in its first two instructions:

```
0: getfield destinationFrequency
4: iconst_m1
5: if_icmpeq 617            <-- no frequency, no destination: GC asks the player
23: setTarget(true, destinationFrequency)
```

**A frequency is a landing pad**, and `setTarget` resolves it to a `targetVec` on a registered body. Galacticraft's
routes are pad to pad. A body this pack owns has no pad and is not in Galacticraft's registry, so no value of
`targetDimension` and no amount of ignition can satisfy that test - which is why presetting the target was overwritten
by the screen every time.

So the pack takes over exactly the step that has no Galacticraft equivalent. `MinespaceRocketDestinations` remembers the
destination on the rocket (weakly, so nothing outlives the flight), and `MixinEntityTieredRocket` injects at the head of
`onReachAtmosphere`: if this rocket was aimed from the star map, GC's behaviour is cancelled and **the player is moved
to the planet** - the arrival is ours because it has to be. Everything the owner watches before that moment is still
Galacticraft's: the fuel, the ignition, the ascent, the sounds, the phase changes.

**What this does not do yet, deliberately:** the rocket stays where it was. Moving it too would mean reimplementing
Galacticraft's ship transfer - its pad lookup, landing sequence and cargo - and a rocket left behind is one the owner
can find again, while a ship that half-transferred is a bug report. The player's chat line says so
(`已抵达 …（火箭留在原地）`), so nobody has to guess where their rocket went.

Verified: the build, and a dedicated-server run with the mixin applied - `Done (2.325s)`, **zero mixin errors**, 19
exceptions (the baseline). Not yet verified: the flight itself, which needs the owner in a fuelled rocket.

## 6eo. The flow the owner actually wanted: GC's logic, this pack's map - 2026-10-16

The owner rejected 6en's aim-then-fly with a better design, in one sentence: *"我想的还是按照 gc 那样的逻辑，升天之后弹我们
自己星图然后选择。这样才靠谱"*. Galacticraft's flow is: launch from the pad, fly, and **choose the destination at the
atmosphere** - that choice is the `destinationFrequency == -1` branch found in 6en. So the right thing to replace is not
the launch, and not the aiming, but **that one screen**.

What happens now:

* The player launches the ordinary Galacticraft way. Nothing about the ascent changes.
* At the atmosphere, `MixinEntityTieredRocket` cancels Galacticraft's celestial screen and - if the rocket was *not*
  already aimed from the ground - sends the player `OpenStarMapMessage`, which opens **this pack's star map in
  choice mode** on their client.
* Choice mode changes what `T` means: `按 T 前往此处` instead of `按 T 设为火箭目的地（需 T2 火箭 + 燃料）`, and the hint
  reads `已进入轨道：选一颗可登陆星球按 T 前往`. Picking sends the same target message with `inFlight = true`, and the
  server answers it - after re-checking the research gate - by moving the player to the planet.
* Aiming on the ground still works and still skips the question: a rocket that already knows where it is going is taken
  straight there when it reaches the atmosphere.

The gate moved with it: `inFlight` requests skip the rocket-tier and fuel checks (that rocket is already in the air, so
there is nothing left to ignite) but keep the research check, and every check still runs on the server - the client is
never the authority on whether it may go somewhere.

Verified: the build, and a dedicated-server run with the new mixin and the new packet registration - `Done (1.944s)`,
**zero mixin errors**, 19 exceptions (the baseline). Not yet verified: the flight, which is the owner's half again. Two
limits stand, both stated in chat and here: **the rocket stays where it launched**, and every planet except
TRAPPIST-1 e is still a void world, so aiming at the other eighty means arriving in an empty sky - which is why the
next round of work is filling them in.

## 6ep. The star map is the progression: an unsurveyed body is not on the chart - 2026-10-16

Three reports from the owner's client, in the order they arrived.

**The map flickered when it opened in orbit** (*"能打开，但是一只闪烁"*). `EntityTieredRocket.onReachAtmosphere` runs
every tick, and the mixin sent `OpenStarMapMessage` on every one of them - the client was told to open the screen sixty
times a second, which reads exactly as a screen that cannot settle. `MinespaceRocketDestinations` now remembers that a
rocket has already asked (`firstAsk`) and the message goes out once.

**`T` did nothing and said nothing.** *"选定了星球，但是按 t 没反应。但是只有选择地球有反应"* - the key worked only for the
one body that happened to read as surveyed, and every other pick was refused in silence, which from the player's side
is indistinguishable from a bug. Every refusal now prints its reason in the hint line under the map
(`refuse` / `whyNot`): `需要 研究数据 II 才能前往 TRAPPIST-1 e`, `行星研究（望远镜）还没观测过 水星`,
`该天体不可登陆（木星）`, `先点开一个星系，选中里面的天体，再按 T`.

**The chart is the progression** (*"新的星图要跟那个行星研究的进度一样才可以，同样的没解锁的天体，星系是不可找到的，只有解锁了才
可以"*). That reverses 6dv, where the open question about locked systems was answered by drawing them as a dim grey ball
with a grey name. Now an unsurveyed body is **not there at all**:

* A node the gate has not opened is projected to NaN - the value the projection already returns for a point behind the
  camera - and every consumer of that array skips it without knowing why: the spheres, the labels, the orbit rings, the
  hover test, the picking, the card, the counters and the frame fit. One object, one decision, no second list of
  "hidden" to keep in step with the first.
* `fitScale` measures **only charted nodes**. Fitting the whole cloud would shrink the handful of stars the player has
  earned into a knot in the middle of an otherwise empty screen. The 35th percentile of fourteen charted systems is a
  chart; the 35th percentile of seventy-seven is a chart of sixty-three stars nobody may visit yet.
* A planet's halo ring is drawn for its **charted** moons only (`visibleMoons`): a ring around nothing is a bug to the
  eye even when every number behind it is right.
* The counters became progress. The title reads `已测绘 14 / 77 个星系 · 40 / 110 个天体（其中 44 个单一天体）`, a system's
  header `已测绘 2 / 7 个天体`, and the legend gained a caption (`研究数据解锁的星层：`) and marks the tiers that are still
  shut - a map that hides its unsurveyed contents owes the player the answer to "what is missing, and what opens it",
  and the chart itself can no longer say it. The card, for the same reason, now names the gate that **opened** the body
  it describes: a card can only exist for a body that is on the chart.

One exception, and it is not a hole in the rule: **the world the map is read from is always on it**
(`computeUnlocked` returns true for `body.dimensionId == mc.player.dimension`, and `MinespaceRocketTarget` makes the
same exception on the server so the two sides cannot disagree). Without it, a player with no research at all - which is
every player on their first day - would open this screen on an empty black field, and "nothing is unlocked yet" and
"this screen is broken" look identical from the outside. Galacticraft's own map is built the same way: it is centred on
the planet the player is standing on.

The answers are cached once per frame (`gateThisFrame`, cleared by `refreshGate` at the top of a frame) not for speed
but for consistency - the drawing, the picking, the fit, the counters and the card all ask the same question, and a
body that counted as charted in one of them and not in another is a star the cursor cannot touch.

**The instrument this was checked with.** A capture run opens the screen at the main menu, where there is no player: with
the gate honoured the camera photographs an empty screen and proves nothing, and with the gate ignored it proves nothing
either. `tools\capture-starmap.ps1` is new and replaces the hand-assembled java command line - it builds the jar, drops
it into a scratch game directory, sets `guiScale` to the owner's 2, launches at 1920x1000 and passes
`-Dminespace.starmap.capture.tier=N`: the camera holds tier N of this pack's survey data and treats a body Galacticraft
owns as surveyed, because nobody is there to have PlanetProgression's state. `-Tier 6` is the whole chart, `-Tier 1` is
the gate part-way open, `-Tier -1` applies no override at all and photographs the real gate. `tools\run-server.ps1` is
the same idea for the boot check: Play-Minespace.ps1's `-Server` path aimed at a scratch directory, so a verification
run never touches the owner's world.

Verified - three captures and a boot:

| run | gate line in `latest.log` | what the picture shows |
| --- | --- | --- |
| `-Tier 6` | `research data 6 of 6, 77 of 77 systems charted, 110 of 110 bodies charted` | the whole chart, as in 6eo: both bands, labels, the `你在这里 · Sol` marker, the card on the pointer |
| `-Tier 1` | `research data 1 of 6, 14 of 77 systems charted, 40 of 110 bodies charted` | fourteen systems spread over the frame with nothing reserved for the other sixty-three; the legend greys `3 中距` upward |
| `-Tier -1` | `research data -1 of 6, 0 of 77 systems charted, 0 of 110 bodies charted` | nebula, dust and legend, and no star, no name and no cursor target: "nothing unlocked" is an empty chart, not a broken one |
| dedicated server | `Loaded 254 worldgen definitions`, 47 mods, `Done (1.917s)` | the baseline, unchanged: 19 exception mentions, 0 `NoClassDefFound`, 0 errors in `crafttweaker.log` |

The temporary probe from 6em is **deleted**. The map logs its own gate once per open instead
(`star map gate: research data N of 6, X of 77 systems charted, Y of 110 bodies charted`), which is the evidence the
probe existed to produce, without a per-body diagnostic in the shipped jar.

Not verified, and it is the owner's half again: a real launch with this gate, the in-orbit chooser against a
partially-charted map, and whether PlanetProgression's client-side state reads the same on the owner's machine as it
did in 6em's probe. Two limits stand unchanged: the rocket stays where it launched, and every planet except
TRAPPIST-1 e is still a void world - so the map now hides planets that would be empty sky, which is the right answer
arrived at from the wrong direction, and 6eh's terrain work is what will make them real.

## 6eq. One progression per system: the sun's own rows follow PlanetProgression - 2026-10-16

The owner's report after 6ep: *"你这么搞了之后我全部解锁之后，gs原本木星，土星等这些都没有了"* - with everything unlocked in
PlanetProgression, the Galaxy Space originals had left the map. The gate was doing what it said; the catalog was not.

**The measurement.** A temporary probe printed, once per dedicated-server start, which of the 110 catalog rows
Galacticraft has a body for (those are PlanetProgression's) and, separately, every body Galacticraft and Galaxy Space
actually register, with its dimension id:

```
PROBE registry: 23 of 110 catalog rows are bodies Galacticraft knows
PROBE row: layer 1 dim -1026 Jupiter -> OURS (tier-gated)      ... 19 of Sol's 24 rows are GC/GS bodies
PROBE row: layer 1 dim -1996 Saturn  -> OURS (tier-gated)
PROBE row: layer 1 dim -1997 Uranus  -> OURS (tier-gated)
PROBE row: layer 1 dim -1998 Neptune -> OURS (tier-gated)
PROBE row: layer 1 dim -1013 Deimos  -> OURS (tier-gated)
PROBE body: jupiter -> planet.jupiter dim -1 tier 0    (also saturn, uranus, neptune, and deimos)
```

So Galaxy Space **does** register Jupiter, Saturn, Uranus and Neptune as planets of the sun's system - and gives them
**no dimension** (`dim -1`), which is why this pack's catalog had to invent ids for them (-1026 was kept as GS's
Jupiter, the other three became -1996/-1997/-1998) and why `GalaxyRegistry.getCelestialBodyFromDimensionID` answers
null for all four. The gate reads "Galacticraft knows the dimension? PlanetProgression : our survey data" (6el), so
those four fell into this pack's own research-data gate - layer 1, tier I - and 6ep then hid them, while the moons
*orbiting* them (Io, Europa, Ganymede, Callisto, Titan, Enceladus) stayed on PlanetProgression's side. One system, two
progressions, which is the shape 6el was written to remove. Deimos is the same case: Galaxy Space has a Deimos with no
dimension, this pack's -1013 is its own, so it needed research data I while Mars next door needed the telescope.

**The rule now.** One progression per system: a row in the sun's own system is PlanetProgression's business, whether or
not Galacticraft has a body for its dimension, and it is charted when that research has surveyed **any** of the system's
Galacticraft-owned bodies (`MinespacePlanetResearch.gateIsPlanetProgression` / `systemSurveyedOnClient` /
`systemSurveyedOnServer`, with a per-frame answer on the client). Layer 2 and outward are unchanged: those are this
pack's own discoveries and its own research data opens them. `whyNot` and the card name the gate through the same
predicate, and `MinespaceRocketTarget` makes the same exception on the server so the two sides cannot disagree -
Deimos is landable, so a click that the client allows must not be refused by the server.

Measured on the client, with the capture's stand-ins standing in for the owner's own state:

| run | gate line | picture |
| --- | --- | --- |
| the owner's state: everything surveyed in PlanetProgression, no research data | `research data 0 of 6, 4 of 77 systems charted, 28 of 110 bodies charted` | `Sol  已测绘 24 / 24 个天体`, Jupiter, Saturn, Uranus and Neptune back with their moons' haloes; four systems in total (Sol + the three nearby ones GS owns) and no exoplanet, because those are ours and need our data |
| everything, both halves | `research data 6 of 6, 77 of 77 systems charted, 110 of 110 bodies charted` | the whole chart, as in 6ep |
| the real gate, no player | `research data -1 of 6, 0 of 77 systems charted, 0 of 110 bodies charted` | nebula, dust, legend - nothing to click |

The probe is deleted again and the jar rebuilt. Two things this round did **not** do, both worth stating: the moons
Galaxy Space registers without a dimension (Mimas, Dione, Tethys, Rhea, Iapetus, Ariel, Umbriel, Titania, Oberon,
Proteus, Charon) are not in the catalog at all, so they are not drawn - the sun's system is complete *as this pack
catalogs it*, and those eleven are available to add if the owner wants them; and the four giants are still not places
(non-landable, no veins), so their cards say `不可登录 · 无矿脉（气态/冰质）` and `T` refuses them as before.

## 6er. This pack's own bodies join PlanetProgression's research - 2026-10-16

The owner's rule: *"关于我们自己的其他 gc gs 以外的天体也应当注册到行星研究的研究进程，要解锁全部解锁"*. The eighty-one rows this
pack adds - every exoplanet, belt, dwarf planet and deep-sky object the catalog plans - were not in Galacticraft's
celestial registry, so PlanetProgression could not see them: no research paper, no line in the telescope, and
"unlock everything" left them behind this pack's own survey data. They are registered now, and the research is one
progression again.

**What PlanetProgression actually needs** (measured in its bytecode, not guessed): `hasUnlockedCelestialBody` is a
`List<CelestialBody>.contains`, `unlockAllCelestialBodies` iterates `GalaxyRegistry.getRegisteredPlanets()` and
`getRegisteredMoons()`, the telescope matches a research paper's body name against a registered body's unlocalized name,
and `initResearchPaperItems` **creates one research paper per registered body** during the item registry event - which
runs after every mod's preInit and init, so a body registered from this pack's preInit gets its paper without
PlanetProgression knowing this mod exists.

**What was registered, and what was not.** Registration goes through AsmodeusCore's `BodiesRegistry` - the same helper
Galaxy Space itself builds its systems with, which is the difference between a body Galacticraft's map can draw and one
it crashes on (6dq/6dr). Ownership is decided by **the dimension band**, the rule
`MinespacePlanetDimensionsRegistration` already used: at or below -2000 is this pack's, above it is somebody else's. The
first attempt decided it by asking "does Galacticraft have a body for this dimension yet", and that is the wrong
question: Galaxy Space registers part of its own catalog **after** this pack's preInit, so twenty rows looked like ours,
and the registry keeps one body per name - this pack's Miranda would have been kept and Galaxy Space's own Miranda
thrown away. A probe at `loadComplete` found all twenty, which is why the band rule is now the rule.

Twenty-nine rows turned out to be bodies Galacticraft or Galaxy Space already has, and they are **adopted** rather than
re-registered: this pack's catalog row *is* that body, so its gate is that body's gate. Twenty-three of the twenty-nine
have **no dimension at all** in Galacticraft's eyes (Galaxy Space registers Jupiter, Saturn, Uranus, Neptune, Deimos and
Barnarda C2 with `dim -1`), so they can only be found by name - an alias table of one entry covers the single row whose
name disagrees (this pack calls it `barnard_s_star_d`, Galaxy Space calls it `moon.barnarda_c2`).

**A body with a dimension, said out loud.** Every registered body now carries its dimension and its provider
(`setDimensionInfo(dim, provider, false)` - `false` because MinespacePlanetDimensionsRegistration already registered it).
Leaving it out was the first version and it was wrong twice over: eighty-one bodies answered `getDimensionID() == 0`,
which is the overworld, so anything asking Galacticraft "which body owns this dimension" could be handed an exoplanet;
and PlanetProgression skips dimension `-1` bodies, which is exactly why Galaxy Space's own dimension-less Deimos is the
one body in the catalog with no research paper.

**Two roads, one progression.** A body this pack registered is opened either by PlanetProgression's research of it (the
telescope, a paper, `unlockAllCelestialBodies`) or by this pack's own survey data for its layer - the data item is a
shortcut, the telescope is the road. A body Galacticraft or Galaxy Space made is opened only by their research (6el),
and the sun's own rows stay the system rule of 6eq. Client and server ask the same question through the same predicate
(`MinespaceCelestialRegistry.registeredByPack`), and the star map's card says which road opened the body under the
cursor. The legend stopped answering "is this layer open" with the survey data the player carries - after this round
that answer was wrong on a fully drawn chart - and now marks the layers that have anything charted in them
(`layerCharted`, recomputed once a frame).

**The language files are generated, from the table the Java reads.** Galacticraft builds a body's name from its registry
key (`<type>.<name>` + `.name`), so `tools\build-celestial-lang.ps1` writes `planet.<key>.name` / `moon.<key>.name` for
all 110 rows plus a system and a star line per group, and `tools\build-celestial-art.ps1` writes the twenty-one body
icons by kind (a star, a black hole, a galaxy, a gas giant, a belt...) that Galacticraft's own screens draw. Both read
`MinespacePlanetDimensions.java` rather than the CSV behind it, because the CSV leaves the solar system's star column
empty - a generator reading the CSV invented a system per solar-system row and wrote keys no body has.

**Verified** - a probe run and a clean run, both on the dedicated server, and two capture runs of the star map:

| check | result |
| --- | --- |
| registration | `registered 81 planets and 0 moons in 73 new systems (29 rows are bodies Galacticraft already owns, 23 of them found by name, 0 failed)`; Galacticraft then knows 102 planets, 12 moons, 77 systems |
| every row in the pack's hands | 110 of 110, `0 missing language keys`, `0 of ours were dropped by the registry`, `0 duplicate a dimension Galacticraft owns` |
| PlanetProgression | 119 research papers, **109 of them for this pack's bodies**; the one without a paper is Galaxy Space's own dimension-less `moon.deimos` (its `unlockAllCelestialBodies` still unlocks it - that command walks the registry at run time, not a paper list) |
| dimensions | `0 -> planet.overworld`, `-2103 -> planet.trappist_1_e`, `-2400 -> planet.gn_z11`; `0` of this pack's bodies would have Galacticraft register their dimension a second time |
| the star map, everything surveyed | `research data 0 of 6, 77 of 77 systems charted, 110 of 110 bodies charted` - the owner's state after unlocking everything, with the card reading `已解锁 · 行星研究（望远镜）` |
| the star map, survey data only | `-Tier 1 -PlanetProgression $false`: `13 of 77 systems charted, 17 of 110 bodies charted`, the legend bright on `2 近邻` and dim above it |
| boot | `Loaded 254 worldgen definitions`, `Done (1.935s)`, 19 exceptions, 0 `NoClassDefFound`, 0 errors in `crafttweaker.log` |

The probe is deleted and the jar rebuilt (build, instance and capture directory, hash `ADD2B2B9...376DF`).

### The stability audit the owner asked for - 2026-10-16

*"没有使用不稳定的方式做这个功能吧"* - a fair question about a round that reaches into three other mods' registries, so here
is what it is built on and what it is coupled to.

**What it uses.** AsmodeusCore's `BodiesRegistry` (the helper Galaxy Space itself builds every one of its systems with),
Galacticraft's own public registry API (`GalaxyRegistry.registerPlanet` / `registerMoon` / `getCelestialBodyFromUnlocalizedName`,
`CelestialBody.setDimensionInfo` / `setBodyIcon` / `setTierRequired`), and PlanetProgression's published research hooks.
**No reflection, no bytecode patching, no field surgery, no registry mutation after mod loading** - the one mixin in the
pack is still 6en's, on Galacticraft's atmosphere hook, and this round did not add any. Registration happens in
preInit, before the registry events, which is the window FML provides for exactly this.

**What it is coupled to, and therefore checks on every start.** Three couplings fail *silently*, so they are a standing
guard (`MinespaceCelestialRegistry.verify`, called at loadComplete and again at server start) rather than a one-off probe:
a body whose language key the generated `.lang` does not carry shows a raw key in Galacticraft's windows; a body whose
icon file is missing draws as the purple checkerboard; and a landable body whose dimension no mod registers is a
destination that cannot be reached. Two of the three are couplings to files this repository generates
(`tools\build-celestial-lang.ps1`, `tools\build-celestial-art.ps1`), which is the point: the day one side changes, the
next boot says so instead of a player finding it in a window.

```
Celestial registry check (loadComplete):   81 of 110 bodies registered by this pack, 0 missing language keys [],
                                           0 missing icons [], 24 landable bodies whose dimension is not registered,
                                           0 of them in this pack's own band [...]
Celestial registry check (server started): 81 of 110 bodies registered by this pack, 0 missing language keys [],
                                           0 missing icons [], 2 landable bodies whose dimension is not registered,
                                           0 of them in this pack's own band [Barnard's Star d(-1032) Deimos(-1013)]
```

**The two lines are two different questions, and that difference is itself a measurement.** At loadComplete *every*
landable dimension of Galacticraft's and Galaxy Space's own worlds answers "not registered" - the Moon and Mars included
- because those mods register their dimensions later. Only at server start does the number mean what it says, and there
it is **2**: `Deimos(-1013)` and `Barnard's Star d(-1032)`, the two catalog rows that are landable, are this pack's
plan, and whose Galacticraft counterpart is a body **with no dimension at all** (Galaxy Space's `moon.deimos` and
`moon.barnarda_c2`, both `dim -1`) - so no other mod registers those two ids and this pack's own dimension registration
skips them (it skips everything above -2000 as "somebody else's band", the rule that keeps AE2's -11 out of this pack's
way).

That was a live hole rather than a cosmetic one: the star map's card offered Deimos as a destination, the gate's
system rule allowed it, and the arrival called `changeDimension` on a dimension with no world - a stack trace at the end
of a flight. It is now refused twice, with the reason in the chat message: once in `MinespaceRocketTarget.apply`, where
every other refusal lives (before aiming or igniting), and once in `MinespaceRocketDestinations.transfer` as the last
line before Minecraft's own transfer. **Open, and deliberately not decided here:** whether those two rows should claim
their dimension ids as they stand (-1013 is a gap in Galaxy Space's numbering, and Galaxy Space will never register it
because it deliberately has no dimension for that body), or move into this pack's own band (-2500 and down) when the
terrain round gives them a provider and a rock - which is the round that has to regenerate the vein files' dimension
ids anyway. Both are one decision for the owner, and neither is silent.

**Two things this round did not do, both worth knowing.** PlanetProgression ships **no recipe that produces a research
paper** - the items exist and the telescope consumes one per body, so on this pack's side the telescope road needs a
recipe route of our own (one per body, or one generic paper that names its target); asked for, not assumed. And adding
bodies renumbers PlanetProgression's `research_paper_<n>` item ids, so a world that already holds paper items will see
Forge's one-time "missing minecraft:items" list on its next launch - harmless, and it is the price of the registry
growing, but a player should be told rather than surprised.

## 6es. Stage two's countable half is green, and the checklist stops crying wolf - 2026-10-16

The owner asked to continue stage two. Before touching anything, both countable acceptance tools were run
against the tree as it stands, and the state and the defects came out of the same measurement.

**What stage two's acceptance says** (`tools\accept-planet-veins.ps1`): 128 vein files, 128 parsed, 0
failures; all 26 bodies carry 5..8 veins (Moon 7, Venus 7, Mars 7, Io 6, Europa 6, Titan 5); no duplicate
`(dimension, name)` pair anywhere; no definition without a dimension filter; the Moon shows 7. The 20
solar-system dimensions supply 64 distinct ores between them, which is the plan's "5..8 per body,
diversity by combination rather than new ores" (5.4) and its 4.1 criteria, met.

**The closure checklist said `[ FAIL ] 6 gaps` - and the six were not gaps.** `arsenopyrite`,
`barytocalcite`, `caliche`, `fluoroapatite`, `iridium` and `osmium` are each named in the table's variants
(lines 1872, 1923 and 1941), and each of those variants belongs to a body marked `Pending`: 55 Cancri e,
HD 40307 g and HD 219134 b, all mid-layer, all stage five. Their dimensions are registered - the star map
needs the ids - and 6dn measured that their worlds are the shared void provider, so no vein file is written
for them on purpose, and the supply half of the check, which reads files, cannot see them. The checklist
was reading "designed, not generated" as "missing".

That is worth fixing rather than living with: a checklist that is always red is one nobody reads, and the
next real gap would have hidden behind these six. `check-resource-closure.ps1` now reads the table's
`Pending` flag and its variants, splits the missing materials into *real* gaps and *designed, not yet
generated*, and names the body and the stage each planned one arrives at:

    [ OK ] no ore-bearing material is left without a source          (0 gaps)
        designed, not generated yet (6) - the only body that will carry them has no terrain:
            arsenopyrite             55 Cancri e        stage 5  LuV~ZPM
            barytocalcite            HD 40307 g         stage 5  LuV~ZPM
            caliche                  HD 40307 g         stage 5  LuV~ZPM
            fluoroapatite            HD 40307 g         stage 5  LuV~ZPM
            iridium                  HD 219134 b        stage 5  LuV~ZPM
            osmium                   HD 219134 b        stage 5  LuV~ZPM

Only a real gap can fail that check now. Two smaller defects went with it: a `$homeOres` reference the
script never defines (a no-op that read like a rule, now gone), and `build-planet-veins.ps1`'s summary
line, which said "no dimension exists yet" about bodies whose ids have been registered since 6dm - it now
says what 6dn measured ("id registered, world still void").

**The body map in `accept-planet-veins.ps1` was a second source of truth.** Its dimension-to-name table
predates `planet-veins.psd1` and printed `dimension -2103` for TRAPPIST-1 e. It is filled in from the table
now - skipping `Pending` bodies, because their absence from the files is deliberate and counting them would
have turned eleven designs into eleven `MISSING` failures - and that row reads `TRAPPIST-1 e` with its 7
veins. The hardcoded entries stay for the dimensions the table does not own (Galaxy Space's mirror
dimension -1006, for one).

**Verified, not assumed**

| check | result |
| --- | --- |
| `accept-planet-veins.ps1` | 6 of 6 criteria OK: 26 bodies, 0 duplicates, 0 parse failures, 0 empty |
| `check-resource-closure.ps1` | `OK` on both criteria: 0 gaps, 0 supplied after their last use |
| table vs generated files | in sync - the table was saved at 11:41:00 and the fifteen managed folders written at 11:41:10 |
| `build-planet-veins.ps1 -DryRun` | 71 variants, 37 managed bodies, 66 files to write, 0 to remove, 0 to strip |
| the plan's own five examples (4.2) | each card matches the theme the plan names: Mercury's least-oxidised rock and impact-delivered platinum-group metal, Venus's high-temperature sulphides, Io's volcanic sulphur, Titan's hydrocarbon-and-nitrogen chemistry, Europa's under-ice brine and hydrothermal sulphides |

**What stage two still owes, and it is not countable from here**: the two in-game acceptance lines - the
generation screenshots and the Earth to Moon to Mars to Ganymede sampling trip - and the one claim no round
has tested (6dl), that ore actually appears in a planet's ground. A temporary server-side probe that
generates a grid of chunks in the solar-system dimensions and counts the GregTech ore blocks in them is how
to answer that without a player; that is the next round, and the instrument gets deleted after use like
every other one.

## 6et. The four modules get their own banners, and the mod list reads pack.png - 2026-10-16

The owner asked for logos and descriptions for the modules the split created. The interesting part is what
measurement turned up before any art was drawn.

**Minecraft 1.12.2 does not read `logoFile`.** `GuiModList#updateCache`'s bytecode does this, and nothing
else:

    IResourcePack pack = FMLClientHandler.instance().getResourcePackFor(mod.getModId());
    if (pack != null) img = pack.getPackImage();                      // <- the mod list image
    else img = getClass().getResourceAsStream(logoFile);              // <- resolved against Forge's own class

So the image in the mod list is the resource pack's `pack.png`, and `logoFile` is only consulted for a mod
that has no resource pack at all - where it is then resolved relative to the FML class, which can only ever
find a file inside Forge's own jar. A jar-based mod can therefore never show its `logoFile`.

That is why this pack's mod list has never shown a logo: no jar in the instance has a root `pack.png` - all
25 were checked, and Galacticraft does not either, although its `mcmod.info` declares
`assets/galacticraftcore/core-logo.png`. The `make-logo.py` docstring's geometry (400x130 authored, scaled
0.5x into the 200x65 box) is right; its assumption about *which file* Forge loads was not.

**What shipped**

* `tools/make-logo.py` now takes `--module <id>` and `--all`. One palette-and-mark class drives all five
  images, so they stay one family: same backdrop, star field, frame and lighting, five accents, five
  emblems (gear-and-planet for the umbrella and core, a cut planet with a moon for planets, an instrument
  face with a plotted course for navigation, a star in a segmented shell for cosmic).
* Four module banners at `assets/minespace_<module>/logo.png`, one per resource domain, plus 4x versions in
  `docs/`. Each is wordmarked `MINESPACE * <role>` with the module's own headline and contents line.
* `pack.png` at the jar root, so the mod list has an image at all. One jar is one resource pack, so all four
  entries share it: the umbrella mark. Per-module mod-list logos are not something 1.12.2 can do.
* `mcmod.info` declares each module's own banner in `logoFile` (inert in practice, but it is the declared
  intent and costs nothing) and carries rewritten per-module descriptions.

**Verified**

* The umbrella mark is byte-identical after the refactor: `logo.png` SHA256 `d3019921...` and
  `docs/logo.png` `d6434811...` both before and after, so the committed art still regenerates from the
  script exactly (which is also how the refactor was checked at each step).
* The four banners were looked at, not assumed. The first render **had the taglines cut off at the right
  edge** - they were longer than the umbrella's line and the script had no fitting - so the script gained a
  `fit_size` for the headline, the kicker and the tagline, and the taglines were shortened.
* Server run after the change: 50 mods, `Done (2.000s)`, `crafttweaker.log` 0 errors, ERROR 40 / WARN 5352 -
  identical to the run before it. The four modules' `Missing English translation` warnings stay gone.

Recorded in MODULE-SPLIT-PLAN.md section five as well, because it is a rule about the module layout rather
than about art.

## 6eu. The solar system is researched one body at a time, not one system at a time - 2026-10-16

The owner opened the star map and reported the shape of the bug in one line: *"没研究的行星都不会展示啊，我这里都还没
研究怎么木星这些星球都展示了呢"* - follow Galacticraft and Galaxy Space, where a body you have not researched is not on
the chart; Jupiter was on theirs before they had researched it.

**Measured first.** The gate had two roads into a solar row and the second one was the whole system:
`MinespaceStarMapScreen.computeUnlocked` asked `systemSurveyed(body)` - "has *any* body Galacticraft owns in this row's
system been surveyed?" - for every row this pack registered in layer 1, and for every row whose dimension nobody
registers (Galaxy Space's four gas giants, which it registers as planets with no dimension). The capture harness could
not photograph the difference, because its stand-in for PlanetProgression was all-or-nothing:

| stand-in | systems charted | bodies charted |
| --- | --- | --- |
| PlanetProgression surveyed everything (`-Tier 0`) | 77 of 77 | 110 of 110 |
| PlanetProgression surveyed nothing (`-Tier 0 -PlanetProgression $false`) | 0 of 77 | 0 of 110 |

So the *smallest non-empty* state - one body surveyed - was the same as the largest: the moment the telescope had
surveyed the Moon, all twenty-four solar rows were charted, giants and all. 6eq chose the system as the unit because
Galaxy Space's Jupiter looked like a planet with no object to research ({@code jupiter -> planet.jupiter dim -1}); the
missing piece is that this pack resolves such a row to the body that already stands for it - by dimension where it has
one, by unlocalized name otherwise - so the per-body question *is* askable for every row.

**Changed**

* `MinespaceStarMapScreen.surveySolarBody` - a row in the sun's own system is charted when *that body* has been
  surveyed: by dimension where Galacticraft knows one, by the body object otherwise. No system question, and no
  research-data shortcut either (layer 1's tier is I, and a data item is not a telescope).
* `MinespacePlanetResearch.surveyedSolarOnServer` - the same two lines for the rocket gate in `MinespaceRocketTarget`, so
  the map cannot offer a destination the server refuses. `systemSurveyedOnClient`, `systemSurveyedOnServer` and the now
  unused `systemKeyOf` are gone.
* The refusal for one of these rows now says the *body* has not been surveyed; it used to say its *system* had not.
* `capture-starmap.ps1 -Surveyed <key>` - the harness's stand-in answers for one body, which is what makes this rule
  photographable at all. `-Tier 0 -PlanetProgression $false -Surveyed moon`:

| check | result |
| --- | --- |
| one body surveyed (the Moon) | the Sol view reads **已测绘 1 / 24 个天体**; Sol's marker and nothing else |
| everything surveyed | 110 of 110 bodies, unchanged |
| nothing surveyed | 0 of 110 bodies, unchanged |
| dedicated-server run | 50 mods, `Done (1.982s)`, `crafttweaker.log` 0 errors, ERROR 40 / WARN 5352 - identical to before the change |

**Two traps recorded.** (1) The four gas giants are reachable per body only because `MinespaceCelestialRegistry.bodyOf`
falls back to the unlocalized name - if that ever stops resolving, those rows go dark rather than wrong, and the
registry's own standing check is what would say so. (2) Reading a `.java` file with PowerShell's `Get-Content` on this
machine decodes UTF-8 as GBK, so Chinese literals look like mojibake; an edit scripted that way must use
`[IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)` and verify by dumping code points, which is how a message was
cut in half and the damage caught here.

**Still open, and it is the owner's call**: Galacticraft's own map (the M key) is not ours and hides nothing - Galaxy
Space's Jupiter is in its registry, so that screen lists it whatever the research says. Making *that* map behave the
same way is a different job (a mixin into its celestial screen, or removing GS's bodies from it).

## 6ev. M opens this pack's star map, because that is what the default map should be - 2026-10-16

The owner's request, after 6eu put the gate in: *"建议改成默认星图打开就是我们新的"*. The pack's map was on J, and the
comment on that binding said why - M already opens Galacticraft's map, and this screen was "a different document, not a
replacement for it yet". It is the replacement now.

**Measured first.** Galacticraft's map key is `micdoodle8.mods.galacticraft.core.tick.KeyHandlerClient.galaxyMap`, a
**public static** `KeyBinding`, registered through `ClientRegistry.registerKeyBinding` in `ClientProxyCore`. That is
what makes a takeover possible without a mixin: the field can be written, and their binding stays in the controls list
where a player can put a key back on it.

**What changed**

* `MinespaceStarMapKey.OPEN_MAP` is on **M** ("Open the star map"), with `OPEN_MAP_ALT` keeping **J** so nobody has to
  relearn anything; the tick handler drains both.
* `NavigationClientProxy.releaseGalacticraftMapKey` sets GC's key to `KEY_NONE` - **only while it is still on M**, so a
  key the player has already moved is left alone - and logs one line. No mixin, no reflection: the field is public.
* Why ours deserves the default: Galacticraft's map cannot hide anything, because Galaxy Space's bodies are in its
  registry whatever the research says (6eu), while this pack's map is built on the gate.

**Verified**

| check | result |
| --- | --- |
| a real client run (the capture harness) | `minespace_navigation: star map: M opens this pack's map (J also works); Galacticraft's own map key released`, and all six capture poses still written |
| the same client | 51 mods loaded, clean shutdown |
| dedicated server | 50 mods, `Done (1.964s)`, ERROR 40 / WARN 5352, `crafttweaker.log` 0 errors - identical to before, and the takeover line does **not** appear (the class it touches is client-only) |

**Left for the owner, in game**: press M and confirm this pack's map opens; the controls screen should show
Galacticraft's own "Galaxy Map" as unbound (rebindable, so that screen is not lost, only off the default key). The
release is idempotent: once the game has saved GC's key as `NONE`, later launches find it off M and log nothing.

## 6ew. The launch asks through one funnel, and Galaxy Space's rockets never used ours - 2026-10-16

After 6ev put the map on M, the owner launched a rocket and reported the other half: *"不对，发射之后星图还是gs的"*. The
injection from 6en was still in place, so this was a measurement problem, not an oversight.

**What the four classes actually do.** `onReachAtmosphere` is declared in four places that matter:

| class | declares it | opens the screen via |
| --- | --- | --- |
| `api.prefab.entity.EntitySpaceshipBase` | yes (the base) | - |
| `api.prefab.entity.EntityTieredRocket` | yes (override) | `WorldUtil.toCelestialSelection(player, stats, tier)` |
| `galaxyspace...EntityTier6Rocket` | yes (**override**) | the same call |
| `galaxyspace...EntityMultiSeatRocket` | yes (**override**) | the same call |

The 6en injection targeted `EntityTieredRocket.onReachAtmosphere`. Galaxy Space's two rockets **override** that method and
never run the parent's body, so for the rockets the owner actually flies, the injection never fired and Galaxy Space's map
opened. The old injection was wrong in the other direction as well: it cancelled Galacticraft's method
unconditionally, so a normal pad-to-pad flight to a space station was intercepted and asked this pack's map instead.

**The funnel.** Every one of those road ends - Galacticraft's own rockets and Galaxy Space's overrides both - goes
through `micdoodle8.mods.galacticraft.core.util.WorldUtil.toCelestialSelection(EntityPlayerMP, GCPlayerStats, int)`, and
that method is reached *only* when the rocket has no destination of its own (a resolved pad frequency takes the other
branch). So the takeover belongs there, once, instead of per rocket class:

* new `navigation/mixin/MixinWorldUtil` - at the head of that method: if the player asking is **riding an
  `EntityAutoRocket`**, hand the choice to `MinespaceRocketDestinations.takeOver` and cancel Galacticraft's screen;
* `MinespaceRocketDestinations.takeOver(player, rocket)` - aimed before launch: fly them there; not aimed: this pack's
  map, once per flight. Its `nameOf` moved here verbatim from the deleted mixin;
* `MixinEntityTieredRocket` is **deleted** - with the funnel in place it is dead weight, and its
  unconditional cancel is the bug in this round;
* the other callers of that method - the `/planetteleport` command and Galacticraft's player handler - are left alone:
  neither has a rocket being ridden, so they still get Galacticraft's screen.

**Verified**

| check | result |
| --- | --- |
| mixin audit (dedicated server, `mixinbooter.log`) | `APPLY mixins.minespace.navigation.json:MixinWorldUtil ... -> micdoodle8.mods.galacticraft.core.util.WorldUtil` |
| the same run | 50 mods, `Done (1.971s)`, ERROR 40 / WARN 5352, `crafttweaker.log` 0 errors - the transformed class loads and every number is where it was |
| `toCelestialSelection`'s signature | read out of the jar: exactly one overload, `(EntityPlayerMP, GCPlayerStats, int)V` - the descriptor the injection names |

**Left for the owner, in game** (a launch cannot be scripted with this pack's instruments): launch a rocket, and this
pack's map should come up instead of Galaxy Space's; pick a body and the flight should continue to it. Then check the
one that is deliberately *not* ours: a pad-to-pad flight to a space station should still use Galacticraft's own screen.

## 6ex. "Get into a rocket" was refused while sitting in one - 2026-10-16

The owner sent one screenshot, no words: standing on a planet at -172 C, Galacticraft's launch keys and its parachute
warning in chat, and a red line from this pack - *"无法前往:先坐进火箭(Earth 需要 GC 火箭)"*. That is
`MinespaceRocketTarget`'s riding check, and it should not be reachable from inside a rocket.

**What the evidence says.** Read out of the owner's own running instance (the log is locked by their client, so it was
read through a shared handle):

* the four chat lines `SPACE - 发射 / A / D - 左-右转 / W / S - 上-下移 / F - 物品栏 / 燃料` are Galacticraft's, and its
  own lang file says they belong to the pre-launch checklist - they are sent to the player on **boarding**, so the
  player was in the rocket when they arrived;
* `Running GregTech ore generation on Galacticraft dimension -1014` at login says the session started on **Io**;
* the star map opened at 21:02:41 with `research data 0 of 6, 77 of 77 systems charted, 110 of 110 bodies charted` - the
  owner's PlanetProgression is fully surveyed, so the research gate is not involved and the only refusal left was the
  riding one;
* the refusal itself is at 21:03:01, twenty seconds after that map opened - the shape of the in-flight choice (the funnel
  opens the map at the atmosphere, the player browses, then presses T).

**What the classes say.** Every rocket in this pack is an `EntityAutoRocket`, and Galaxy Space's multi-seat and tier-6
rockets extend Galacticraft's `EntityTieredRocket`, which does too - so `ridden instanceof EntityAutoRocket` should have
held. There is no separate seat entity in Galaxy Space either (`EntityMultiSeatRocketTest` is a rocket subclass, not a
seat), and no `startRiding` anywhere in its classes; extra passengers ride the rocket itself.

**What changed (6ex)**

* `MinespaceRocketTarget.rocketRiddenBy(Entity)` follows the riding chain instead of asking for one link, with a depth cap
  against a cycle: a seat or a mount in between is still the rocket. The refusal now uses it.
* The refusal **logs what the player was actually riding** - player, dimension, requested body, the in-flight flag, and
  the vehicle's class name (or "(nothing)"). Those are the three cases that can produce this refusal, and this one line
  tells them apart on the next attempt instead of leaving it to guesswork.
* Verified: build green with `checkModuleBoundaries` (55 files, no violations), dedicated-server run 50 mods,
  `Done (2.068s)`, ERROR 40 / WARN 5352, `crafttweaker.log` 0 errors - the same numbers as before the change.

**Not done, and why**: the star map's card still invites `T` for any landable body, whether or not the player is in a
rocket, and the refusal's wording says only "get into a rocket". Both should follow the measurement above - the card
lines are Chinese literals in a file this machine's tooling reads as mojibake, so they are being changed with a scripted
edit against ASCII anchors rather than by hand, and what they should *say* depends on which of the three cases the log
line names. The owner is asked to relaunch (the jar is deployed) and send that line if it refuses again.

## 6ey. The in-orbit answer is authorised by the question, not by the rocket - 2026-10-16

6ex's diagnostic line, taken from the owner's own running session, named the case exactly:

    [21:30:53] star map: Minespace (dim -1014) asked for Moon in flight=true but is riding (nothing) - refusing

`in flight=true` is the in-orbit choice - the funnel opened this pack's map at the atmosphere - and `(nothing)` is what
was under the player when they pressed T. Their log has the same shape twice: the map opened at 21:02:41 and the
refusal came at 21:03:01; second attempt, map at 21:30:41 and refusal at 21:30:53. The answer arrives **after** the
flight is over, and the ground-aim rule - "the player must be riding a rocket" - was being applied to it.

**Why that rule cannot apply here.** A ground aim has to name a rocket, so asking for one is the only way to know which
ship the player means. An in-orbit answer does not: the arrival is a `changeDimension` for the player, and the choice is
already constrained by the fact that this pack asked for it at all. Validating it by the riding link was checking the one
thing that is guaranteed to be gone by the time a human has browsed a chart.

**Changed**

* `MinespaceRocketDestinations` remembers the question: `ASKED_PLAYERS`, keyed by player, holding the tier of the rocket
  that asked and when it was asked, with a ten-minute game-time expiry. `takeOver` writes it just before it sends the
  map message; `tierAwaitingAnswer` reads it; `answered` consumes it.
* `MinespaceRocketTarget.apply` lets an in-flight answer through when the question is outstanding - no riding link, no
  fuel check (the fuel was spent getting up) - and takes the tier from the rocket that asked rather than from a rocket
  that may no longer exist. The ground path is unchanged: it still needs the rocket, because it has to aim one.
* This is also the *safer* rule. A client cannot claim to be in orbit: without a question from this pack, an in-flight
  message is refused, and the refusal logs "and not asked to choose" so that state is distinguishable from the old one.
* Verified: `checkModuleBoundaries` 55 files, no violations; dedicated-server run 50 mods, `Done (1.979s)`,
  ERROR 40 / WARN 5352, `crafttweaker.log` 0 errors - the same numbers as before. The behaviour itself is the owner's
  next launch: at the atmosphere the map should open, and pressing T on a body should take them there regardless of how
  long they browsed.

**Still open**: the star map's card invites `T` for any landable body whether or not the player is in a rocket, and the
ground refusal says only "get into a rocket". Both are Chinese literals in files this machine's tooling reads as
mojibake, so they are queued for a scripted edit against ASCII anchors rather than a by-hand patch.

## 6ez. The crash: a packet handler on the wrong thread - 2026-10-16

The owner reported "闪退" with no crash report, and the log explains why there was none: this was not a Minecraft crash
but a **fatal packet-handler exception**, which Forge answers by terminating the connection. In single-player the
integrated server disconnecting the player is a client back at the main menu.

**The stack, from the session that died (21:35:24 to 21:39:28):**

    java.lang.RuntimeException: Already decorating!!
        at micdoodle8.mods.galacticraft.core.world.gen.BiomeDecoratorMoon.decorate(BiomeDecoratorMoon.java:49)
        at net.minecraft.world.biome.Biome.decorate / BiomeAdaptive.decorate
        at micdoodle8.mods.galacticraft.core.world.gen.ChunkProviderMoon.populate(ChunkProviderMoon.java:288)
        at net.minecraft.world.chunk.Chunk.populate / Chunk.onLoad / ChunkProviderServer.provideChunk
        at net.minecraft.world.World.getBlockState
        at net.minecraft.world.Teleporter.adjustExitPoint / placeEntity
        at net.minecraft.server.management.PlayerList.transferEntityToWorld
        at net.minecraft.entity.player.EntityPlayerMP.changeDimension
        at com.minespace.unofficial.navigation.MinespaceRocketDestinations.transfer(MinespaceRocketDestinations.java:152)
        at com.minespace.unofficial.navigation.MinespaceRocketTarget.apply(MinespaceRocketTarget.java:181)
        at com.minespace.unofficial.navigation.MinespaceNetwork$RocketTargetMessage$Handler.onMessage(MinespaceNetwork.java:109)

**And the thread**, from the same log line: `[Netty Server IO #1/ERROR]`. A simple channel delivers its message on the
network thread, and everything under `apply` touches the world - `changeDimension` loads the destination, generates its
spawn chunks and populates the ore in them. That ran **beside** the server thread doing its own generation, the guard
against re-entering a chunk population fired, and Forge turned the exception into a disconnection.

That is why the earlier attempts only refused politely: they read state. The first attempt that actually *arrived*
somewhere (6ey's fix working) is the first one that mutated the world from the wrong thread. 6eu-6ey were all read-only
on the server, so the bug was latent from 6en onwards.

**Changed**

* `MinespaceNetwork.RocketTargetMessage.Handler` schedules its work onto the server thread
  (`player.mcServer.addScheduledTask`) and wraps it in a `catch (Throwable)`: a bug in this handler is now a log line,
  never a disconnection.
* `OpenStarMapMessage.ClientHandler` schedules onto the client thread for the same reason - a GUI opened from the
  network thread is a GUI opened behind the game's back.
* Verified: `checkModuleBoundaries` 55 files, no violations; dedicated-server run 50 mods, `Done (1.972s)`,
  ERROR 40 / WARN 5352, `crafttweaker.log` 0 errors.

**The owner's world**: the exception fired inside the destination's exit-point search, before the transfer completed,
so the frame they were standing on should still be where they left it - worth one look when they next log in.

**Lesson to keep**: in this pack, *any* server-side packet handler that touches the world must schedule onto the server
thread first. `SimpleNetworkWrapper` does not do it for you. The two handlers in `MinespaceNetwork` are the pack's only
ones, and both are fixed; a third would need the same line.

## 6f. The hang: vanilla's teleporter, and the player data it left behind - 2026-10-16

The owner's next attempt ended on "loading world" and never left it. A thread dump of the live client (PID 7276, second
session, started 21:44) says exactly what that screen was waiting for:

    "Client thread"  RUNNABLE  ... net.minecraft.client.gui.GuiDownloadTerrain.drawScreen
    "Server thread"  TIMED_WAITING (sleeping) at net.minecraft.server.MinecraftServer.run(MinecraftServer.java:530)

The client is drawing "Downloading terrain" and the server is **idle** - nobody is generating anything. The client is
waiting for a player position that never arrives.

**Why.** `MinespaceRocketDestinations.transfer` used `player.changeDimension(dimensionId)`, the single-argument call,
which hands the arrival to vanilla's `Teleporter`: it searches for an exit point and, doing that, loads and generates
the destination's chunks **inside the dimension change**. In this pack that has now thrown twice - 6ez's
`RuntimeException: Already decorating!!`, and this round's `NullPointerException` inside `Teleporter` (stack:
`transfer -> changeDimension -> PlayerList.transferEntityToWorld -> Teleporter.placeEntity`). Both times the outcome was
the same, because vanilla sends `SPacketRespawn` **before** it places anybody: the client is told to load the new
dimension, the placement then fails, and the client sits on the loading screen forever while the server goes idle.

Galacticraft does not use vanilla's teleporter for this: `WorldUtil.transferEntityToDimension` does the move per
dimension through that dimension's own `ITeleportType` (`TeleportTypeMoon`, `TeleportTypeMars`, ...). This pack was
calling the wrong thing from 6en onwards; every arrival that ever worked did so by luck.

**Changed**

* new `navigation/MinespaceArrivalTeleporter` - an `ITeleporter` that does the one thing an arrival here needs: put the
  entity at the destination's spawn point, on top of the solid block found there (a fixed height in a world that has no
  ground yet). No exit-portal search, so nothing loads chunks behind the dimension change's back.
* `transfer` refuses a body whose world is still the shared void provider (`isStillVoid`, read through
  `DimensionManager.getWorld(id, false)` so asking does not create it): the planned bodies have no terrain yet, and a
  player dropped into one falls through nothing. It reuses the existing "world is not built yet" message.
* `transfer` also recovers instead of stranding: if the move still fails, the player is moved **back** to the dimension
  they came from through this pack's own placement, so the client is told to load a dimension it can actually stand in.
* Verified: `checkModuleBoundaries` 56 files, no violations; dedicated-server run 50 mods, `Done (2.232s)`,
  ERROR 40 / WARN 5352, `crafttweaker.log` 0 errors.

**The owner's save, and what is done about it.** The failed transfer left the player data in a state that only shows on
the next login. Read out of `saves/新的世界/playerdata/00000000-0000-0000-0000-000000000000.dat` byte-wise (the NBT
`Dimension` int tag and the `Pos` list, no parser needed):

    Dimension = -1024   (Miranda - the destination of the attempt that failed)
    Pos       = (233.25, 927.67, 46.0)   (Io's coordinates, from inside the rocket)

Logging in would place the player at y 928 over Miranda, which is a fall, not an arrival. **This round does not touch
that file.** The repair - `Dimension` back to Io (-1014) and `Pos.y` down to the pad's ground height, X/Z unchanged -
waits until the owner has closed the game, because the hung client's own exit-save would simply write the bad state
back, and it will be made with a copy of the file beside it.

**Lesson**: in this pack an arrival is never `changeDimension(int)`. It is either Galacticraft's own transfer or this
pack's teleporter, and no body without ground may be a destination at all.

## 6g. An arrival that loads the way Galacticraft's does - 2026-10-17

6f fixed the hang and the owner arrived on Venus (their player data reads `Dimension = -31`, pos (161, 89, 255)), and
the next remark was the right one: *"没有弄成gs那样加载世界"* - it does not load the world the way Galaxy Space does.
Ours showed vanilla's "Downloading terrain"; every Galacticraft and Galaxy Space trip shows their own progress screen.

**How Galacticraft does it, measured.** `GuiTeleporting` is not just a screen: its **constructor** writes itself into
`TickHandlerClient.teleportingGui`, and `TickHandlerClient.onClientTick` starts with

    if (teleportingGui != null && mc.currentScreen != teleportingGui) mc.currentScreen = teleportingGui;

so the screen is forced back every tick - which is why it survives the vanilla respawn that replaces `currentScreen`
with `GuiDownloadTerrain` - and the screen clears the static field itself once the destination dimension is there. In
Galacticraft's own flow the field is set by `GuiCelestialSelection` when the player picks a destination.

**Changed**

* new `MinespaceNetwork.TeleportingMessage` (server to client, id 2, registered only on the client side): carries the
  destination dimension and constructs `GuiTeleporting` on the client thread - GC's screen, GC's mechanism, not a copy
  of the look.
* `MinespaceRocketDestinations.transfer` sends it immediately before the `changeDimension`, and again with the original
  dimension before the back-out path of 6f, so the screen tracks whichever move actually happens.
* Verified: `checkModuleBoundaries` 56 files, no violations; dedicated-server run 50 mods, `Done (1.969s)`,
  ERROR 40 / WARN 5352, `crafttweaker.log` 0 errors - the packet class is never loaded on a server, because its
  registration sits inside the existing client-side branch.

**Left for the owner, in game**: fly again; the progress screen should come up while the destination loads and clear
itself when the new world is there, exactly as a Galacticraft flight does.

## 6h. The arrival screen is this pack's now, and it is configurable - 2026-10-17

6g put Galacticraft's teleporting screen on our arrivals. The owner's clarification: *"我们的这个取代gs的，就像可以配置星图
那样"* - ours should replace Galacticraft's the way the star map did, and be configurable.

**What makes that cheap.** `GuiTeleporting` is neither final nor does it seal `drawScreen`, and its **constructor**
does the one thing that matters: it writes `this` into `TickHandlerClient.teleportingGui`, which the client tick
handler forces back as `currentScreen` every tick and which the screen clears when the destination is there. So a
subclass keeps the whole mechanism and replaces only what the player sees - which is exactly the split the pack has
used everywhere else.

**Changed**

* `MinespaceTeleportingScreen extends GuiTeleporting`: a dark field, a framed panel in the pack's palette, the kicker
  `MINESPACE · 航行`, `正在前往 <body>`, the body's system and distance (AU inside the solar system, light years outside
  it), a sweeping bar and `世界加载中`. The bar is deliberately **indeterminate**: the server does not report how much
  of the destination is ready, and a fill level that pretends to know would be a lie.
* `MinespaceNavigationSettings` and `config/minespace_navigation.cfg`: `interface.ownTeleportScreen` (default `true` =
  this pack's screen, `false` = Galacticraft's own). Loaded in the module's `preInit`.
* `TeleportingMessage`'s client handler constructs whichever the setting names, still on the client thread.
* Verified: `checkModuleBoundaries` 58 files, no violations; dedicated-server run 50 mods, `Done (1.977s)`,
  ERROR 40 / WARN 5352, `crafttweaker.log` 0 errors.

**The look is an in-game check.** The capture harness photographs the star map, not this screen; the owner is the one
who will see it while a rocket lands, and the next round of tuning depends on that picture.

## 6i. The arrival screen crashed the client: constructed is not shown - 2026-10-17

The owner's first flight with 6h's screen ended in a crash report (`crash-2026-10-17_12.45.23-client.txt`):

    java.lang.NullPointerException: Ticking screen
        at micdoodle8.mods.galacticraft.core.client.gui.screen.GuiTeleporting.func_73876_c(GuiTeleporting.java:48)
        at com.minespace.unofficial.navigation.MinespaceTeleportingScreen.func_73876_c(MinespaceTeleportingScreen.java:52)
        ...
        Affected screen: com.minespace.unofficial.navigation.MinespaceTeleportingScreen

**What the NPE was.** `GuiScreen.mc`, `width`, `height` and `fontRenderer` are assigned by
`setWorldAndResolution`, which `Minecraft.displayGuiScreen` calls. Our handler only **constructed** the screen: the
constructor registered it with Galacticraft's tick handler, the tick handler then forced it into `currentScreen` - an
object that had never been initialised - and its first `updateScreen` dereferenced `this.mc` (null) at
`GuiTeleporting.updateScreen`'s first field read. Galacticraft's own screen survives the same forcing for one simple
reason: `GuiCelestialSelection` *shows* it once, so it is initialised before the tick handler starts re-forcing it after
vanilla replaces `currentScreen` with `GuiDownloadTerrain`. Constructed is not shown.

The arrival itself had worked: the crash report's level is dimension 0 and the player data says `Dimension = 0` - the
player was on Earth when the screen killed the client.

**Changed**

* both branches of `TeleportingMessage.ClientHandler` now `displayGuiScreen(new ...)`, ours and Galacticraft's alike - the
  Galacticraft branch would have crashed in exactly the same way.
* the screen owns its closing rule instead of calling `GuiTeleporting.updateScreen`: close when the player is in the
  destination, or after a minute. Galacticraft's version closes on a `posY`-against-`posZ` comparison and has no
  timeout, so a body whose spawn sits at a low z would pin the player on the screen.
* `drawScreen` and `updateScreen` are wrapped: a failure closes the screen and logs one line. A bug in a screen must not
  be able to take the whole client down, which is what 6i cost.
* Verified: `checkModuleBoundaries` 58 files, no violations; dedicated-server run 50 mods, `Done (1.952s)`,
  ERROR 40 / WARN 5352, `crafttweaker.log` 0 errors.

**Lesson**: a `GuiScreen` that a tick handler forces into `currentScreen` must have been shown through
`displayGuiScreen` at least once, or nothing in it is initialised.

## 6j. The "special loading background" was the world itself - 2026-10-17

The owner's next note: *"还是没有像gc那样有降落，有特别加载背景"*. Reading Galacticraft's screen settled what those two
things are:

* `GuiTeleporting.drawScreen` calls `drawBackground(0)` - **tint zero, i.e. nothing** - and then draws one centred
  line of white text. So its "special background" is not an image at all: it is the **destination world showing
  through**, generating while you wait, with the panel's text on top.
* `WorldUtil.transferEntityToDimension` for a player sends `SPacketRespawn`, then `ITeleportType.getPlayerSpawnLocation`
  and `forceMoveEntityToPos` - a placement, not a fall. So "landing like GC" is the *moment* of arrival, not a
  simulated descent.

Our screen was doing the opposite of both: an opaque `0xF0` overlay hid the world, and the arrival cut straight to the
ground.

**Changed**

* the overlay is now a 25 % veil: the destination forms behind the panel, which is the loading background the owner
  remembered;
* a landing phase: once the player is in the destination, the screen stays for 1.5 s with `降落中` instead of vanishing
  the instant the dimension changes.
* Verified: `checkModuleBoundaries` 58 files, no violations; build and deploy clean. No server run this round: the
  change is inside a `@SideOnly(CLIENT)` screen that a dedicated server never loads, and the previous round's boot with
  the same class set was green.

**Still open, and it is a real limitation rather than a look**: the rocket itself stays behind. `transfer`'s javadoc
records that as this version's deliberate limit - moving the ship too means a second dimension transfer (GC's
`transferEntityToDimension` takes an `EntityAutoRocket` for exactly that) and re-seating the rider. That is the next
candidate, and it needs a test flight because it moves a second entity.

## 7. Open questions / risks

- ~~The machine GUI is the only part with no obvious 1:1 mapping; it needs a `ModularUI` layout
  built from scratch (`GuiTextures` + widgets).~~ **Closed 2026-10-14 (section 6cg).** Both machines
  had their `createUI` from the start (title, one slot, one tank, player inventory); what they were
  missing was *feedback*, and GregTech's own single-block machines answer that with one plate -
  `GuiTextures.INDICATOR_NO_ENERGY` shown while the energy buffer is empty - which both machines now
  carry at the same texture and size (`ImageWidget(79, 60, 18, 18, ...)`; y 60 instead of GregTech's
  42 because the tank slot occupies that row here). This fork ships **no proportional energy bar**
  (a `GuiTextures` sweep finds `INDICATOR_NO_ENERGY` and nothing else energy-shaped), so the icon is
  its whole energy vocabulary. The one nicety left, if it is ever wanted: a `ProgressWidget` on the
  oxygen compressor showing the *tank in the slot* filling up (0..maxDamage), which no GT texture
  covers directly. The look itself needs one right-click in game; nothing headless can see a GUI.
- ~~Gregicality TJ registers itself into the `gregtech` item namespace ... check that nothing the
  addon adds collides with its material ids~~ - **measured and closed 2026-10-15 (6cj).** The addon
  does not pick a block of ids at all: GTCE's material registry is a `GTControlledRegistry` with a
  **capacity of 1000**, Gregicality occupies the top of it (its `luv_superconductor_base` sits at
  972), and `MinespaceMaterials` therefore allocates from the **lowest free slot upwards**. A probe
  over the finished registry printed **794 materials, highest id 999, and 0 ids that resolve to a
  different material than their own** - which is the collision test that matters, because a taken id
  does not fail loudly, it silently re-points the earlier material's id. This addon's six materials
  landed on desh 0, meteoric iron 136, desh steel 147, solar 160, onyx 178, dolomite 289. The
  "Potentially Dangerous alternative prefix" lines in the log are Gregicality and Galaxy Space
  registering into another mod's namespace on purpose (the README lists them as expected).
- **The world must be new** - this stays, and it is a *constraint*, not a task: the GTCEu registry
  cannot be migrated (material ids, meta item ids, ore blocks, stone types and veins all moved), M4
  parked the old stack with the old save at `world-gtceu-backup`, and the instance `README.md` now
  says so in its own section for players instead of only here.
- ~~Everything done for GTCEu configuration in `Minespace-unofficial-dev/config/gregtech/`
  (`highTierContent`, the hard-recipe family, ...) is GTCEu-specific and does not carry over; the TJ
  config has its own switches to review.~~ **Audited switch by switch 2026-10-15 (6ck)** against the
  parked GTCEu config and, where a switch no longer exists, against GTCEu's own bytecode. Result:
  every GTCEu-era decision is now either the same switch with the same value, a rule this fork bakes
  in, a rule the pack's own scripts reproduce, or a divergence taken deliberately and written down -
  plus one rebuilt from scratch (`removeSmeltingForEBFMetals`, which this fork lost:
  `MinespaceMaterialRepoint.pruneEbfMetalSmelting` removes the five dust-to-ingot furnace lanes for
  the metals it does gate). Section 7 is empty.
- **The EU <-> FE ceiling, as a player sees it** (opened by 6cl, 2026-10-15). The direction of the two
  Gregicality converter families is settled in the jar and the swap that puts the ceiling on the
  FE-to-EU family is in `power.zs` - but *which items JEI offers* is a client-side list, and so is the
  tooltip the whole correction rests on. A dedicated server cannot see either. One search settles both:
  `Forge Energy Converter` must offer ULV / LV / MV / HV and nothing above, `GTEU Energy Converter`
  must be craftable at every tier, and hovering one must read "Converts GTEU to FE". Everything else
  about the exchange - the ratio, the prices, which ids exist - is measured; see 6cl.
- **The planet vein arrangement, at 100+ planets** (opened by 6cx, 2026-10-15). The owner withdrew
  "copy GTNH" because the roster and the balance have to carry 100+ bodies, so what is left is the
  proposal in 6cx - archetype + signature vein + region, one row per body, each suite's veins
  carrying a *share* out of 1000 - and a balance call on two things: the archetype list itself, and
  what each archetype's suite contains. **Nothing is applied**; the 38 withdrawn GTNH files are parked
  in `Minespace-unofficial\tools\vein-staging\gtnh\`. Two facts to design against, both read out of
  the jar: `weight` is a share inside one body's vein list, and the 0..2 veins per 3x3 section are a
  global config - so bodies can differ only by composition, never by richness. Sub-question that the
  redesign answers either way: the 74 duplicate `(dimension, name)` registrations are legal but make a
  name ambiguous per body, so they should either be kept deliberately or removed by construction.
  **6cy settled where the arrangement lives** - the 100+ bodies will be this addon's own content, and
  the vein table belongs to the addon, delivered as config JSON generated from that table (the
  measured alternatives are in 6cy). So the input still needed to start is the planet plan itself: how
  many bodies, what differs between them, and what gates access to them.
  **6cz supplies it.** The owner's *GTCEu 星系整合包详细实施方案* now governs the planets, and it fixes
  the vein rules: 5..8 per body, diversity by combination rather than new ores, a geological reason
  written in the body's 地质设定卡, no duplicate and no dead definitions, and resource closure per
  voltage tier. So the archetype proposal above is not the plan of record - the plan's per-body geology
  card is, and an archetype is one way to *implement* a card, not a substitute for it.

## 8. Rollback

Every file the experiments replaced is parked, so either direction is one move:

- GTCEu 2.8.10-beta + GCYM 1.2.11 + SussyPatches 1.1.0 + ConfigAnytime 3.0:
  `%TEMP%\minespace-removed\2026-10-11-downgrade\`
- Serendustry (the downgrade's only content payoff): `%TEMP%\minespace-removed\2026-10-11-serendustry\`
- TJ jars: `%TEMP%\gt-tj\` (plus the scratch instance `..\Minespace-tj-test`)
- The 38 withdrawn GTNH planet-vein files (6cx): `Minespace-unofficial\tools\vein-staging\gtnh\` -
  parked outside the loaded tree, 16 of them unusable against this stack's ore blocks.
