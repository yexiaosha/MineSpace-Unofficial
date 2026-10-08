# Replacing Galacticraft's machines with GregTech ones

Goal: Galacticraft keeps the *content* (planets, rockets, suits, dungeons, ores) and loses the
*industry*. Every machine it brings is replaced by a GregTech machine or by a new machine in
this addon; nothing GregTech already does is duplicated in a script.

Two mechanisms do the work:

* **Scripts** (`scripts/`) for anything a GregTech recipe can express - processing, fluids,
  crafting tables, and the removal of Galacticraft's own crafting recipes.
* **The addon** (`src/main/java/com/minespace/unofficial/gtceu/machines/`) for the rest. Those
  are the parts that cannot be a recipe: Galacticraft stores a tank's contents in the stack's
  **damage value** (its own compressor adds to it, its decompressor subtracts from it), so it
  takes a machine to move that around. New machines are registered with GTCEu's own registry
  (`GregTechAPI.MTE_REGISTRY`), which means they get GregTech's energy container, voltage
  casing texture, wrench behaviour, JEI page and item form
  (`gregtech:machine:<registry id>`) for free.

## Done

| Galacticraft | Replaced by | Where |
| --- | --- | --- |
| Compressor (`machine:3`), Electric Compressor (`machine2:4`), Advanced Compressor (`machine4:11`) | GT bender (plates), GT implosion compressor (compressed plates), GT compressor (block packing) | `gc_gregify_removals.zs`, `gc_gregify_processing.zs` |
| Electric Furnace (`machine:2`), Electric Arc Furnace (`machine:7`), `machine_tiered:*` | GT electric furnace, GT arc furnace, GT electric blast furnace (titanium) | same |
| Circuit Fabricator (`machine2:5`) | GT assembler (wafers from GregTech silicon + circuit) | `gc_gregify_removals.zs` |
| Deconstructor (`machine2:10`) | GT arc furnace / macerator recycling | `gc_gregify_removals.zs` |
| Coal Generator (`machine:0`), Energy Storage Module/Cluster (`machine:1`, `machine:8`), Solar Panels (`solar:*`) | GT generators; Galacticraft machines that are left take Forge Energy, so a GT "Energy Converter" (EU -> FE) feeds them | `gc_gregify_removals.zs` |
| Venus power set: Solar Array Controller (`galacticraftplanets:solar_array_controller`), Solar Array Module (`:solar_array_module`), Geothermal Generator (`:geothermal_generator`) | GT generators | `gc_gregify_removals.zs` |
| Energy Beam Receiver (`galacticraftplanets:beam_receiver`) | Nothing: it only carried the solar array's power around, so it goes with the array | `gc_gregify_removals.zs` |
| Refinery (`refinery`) | GT distillery: crude oil -> rocket fuel | `gc_gregify_processing.zs` |
| Oxygen Collector (`collector`) | GT gas collector: air -> oxygen | `gc_gregify_processing.zs` |
| Gas Liquefier / Methane Synthesizer / Water Electrolyzer (`mars_machine_t2:4/5/6`) | GT vacuum freezer / chemical reactor / electrolyzer | `gc_gregify_removals.zs` |
| Oxygen Compressor + Decompressor (`oxygen_compressor:0/1`) | **new machine**: GregTech Oxygen Compressor, `gregtech:machine:32000` | addon + `minespace_machines.zs` |
| Fuel Loader (`fuel_loader`) | **new machine**: GregTech Rocket Fuel Loader, `gregtech:machine:32001` - same mechanism as Galacticraft's (neighbour scan every 100 ticks, unwrap `TileEntityMulti`, hand 2 mB/tick to the `IFuelable` landing pad, which forwards it to the rocket), fed by pipe or by Galacticraft fuel canisters | addon + `minespace_machines.zs` |
| Its whole material chain (ingots, silicon, compressed plates, wafers, metal blocks) | GregTech materials through the ore dictionary | `gc_gregify_removals.zs` |
| The **machine recipes** of the removed machines: compressed plates in the compressor (all three compressors share one list) and wafers in the circuit fabricator | Cleared at runtime from Galacticraft's own API in postInit - 23 compressor recipes and 2 circuit fabricator recipes - so an electric compressor from an old world has nothing left to do and JEI has nothing to show | addon (`MinespaceGalacticraftMachineRecipes`) + JEI category hiding in `gc_gregify_removals.zs` |

## Deliberately left alone (owner's decision, 2026-10-08)

These are **not** to be touched for now. An Atmosphere Sealer machine was written and then
reverted at the owner's request, including the removal of Galacticraft's sealer and bubble
distributor crafting recipes - both machines are craftable again.

| Galacticraft machine (exact registry item) | Why it stays |
| --- | --- |
| NASA Workbench (`galacticraftcore:rocket_workbench`, `compact_workbench`) | All tier 1/2/3 rockets *and* the cargo rocket are built here, and stay built here. When GalaxySpace is added, its higher tiers will instead be produced by new GregTech multiblocks written for this pack. |
| Oxygen Sealer (`galacticraftcore:sealer`), Oxygen Bubble Distributor (`galacticraftcore:distributor`) | Left as Galacticraft ships them; revisit later. |
| Cargo Loader / Unloader (`galacticraftcore:cargo:0/1`) | Left as Galacticraft ships them; revisit later. |

## Still to do

Ordered by how badly each one blocks play; every entry says what it needs.

| Galacticraft machine (exact registry item) | Plan | Needs |
| --- | --- | --- |
| Oxygen Detector (`galacticraftcore:oxygen_detector`) | New GT machine (or a GregTech detector cover plus our machine's state) | new machine code |
| Oxygen Storage Module (`galacticraftcore:machine2:6`) | Delete: the buffer tank of the new oxygen machine plus GT fluid tanks cover it | removal only (decide) |
| Launch Controller (`galacticraftplanets:mars_machine:2`) | New GT machine (automated launch) or keep as Galacticraft's launch logic under GT materials | decide |
| Terraformer (`mars_machine:0`), Cryogenic Chamber (`mars_machine:1`, `block_multi:5`) | Environmental devices, no GregTech equivalent; either delete or write GT machines | decide |
| Chromatic Applicator (`machine3:9`) | Cosmetic; delete | decide |
| Astro Miner (`galacticraftplanets:miner_base`, `miner_base_full`) | GregTech's ore/fluid drilling plants replace the job | removal + doc |
| Short Range Telepad (`telepad_short`), Beam Reflector/Receiver, Laser Turret | No GregTech equivalent; delete or write later | decide |
| Landing Pad, Parachest, View Screen, Telemetry, Spin Thruster, Space Station Base | Infrastructure/decoration rather than industry; keep, or replace the screen/telemetry pair later | decide |

## Notes that cost a debugging round each

* GregTech's `outputs(...)` needs an `IItemStack`; an ore dictionary entry only works for
  `inputs(...)`. Outputs are pulled out with `oreDict.get("name").firstItem`.
* `IOreDictEntry` members in ZenScript are `firstItem`, `items`, `empty` - not
  `getFirstItem()` / `getItems()` / `isEmpty()`.
* CEu's circuit ore dictionary names are voltage tiers (`circuitLv` ... `circuitUhv`);
  GT5's `circuitBasic` exists as a name but its entry is **empty**.
* `<ore:itemSilicon>` is Galacticraft's raw silicon; GregTech's is `<ore:ingotSilicon>`.
* The gas collector has no item input - its input is the integrated circuit, so a scripted
  recipe needs `.circuit(n)` or it is rejected with "Recipe inputs are empty".
* Galacticraft owns the fluid names `fuel`, `oil`, `oxygen`, `hydrogen`, `methane`,
  `liquid_oxygen`; the `fuelgc` / `oilgc` fallbacks are not registered in this pack.
* `recipes.remove()` only removes **crafting table** recipes. A mod's own machine recipes live
  in its own lists and keep working (and keep showing in JEI) until the mod's API is used -
  Galacticraft exposes `CompressorRecipes` / `CircuitFabricatorRecipes` for exactly that.

## Galaxy Space and Interstellar: Exoplanets (added later)

Both addons were installed after the Galacticraft work; see `MOD-MANIFEST.md` for the jars and
their sources. The same policy applies to them.

Done (in `gs_gregify_removals.zs`):

* Galaxy Space power generation removed from crafting - Fuel Generator, Gas Generator, Gas
  Burner, Hybrid Solar Panel, Solar Mini-Panel, Modern Solar Mini-Panel, Mini-Panels
  Controller, Solar Wind Panel, Wind Turbine, Advanced Wind Turbine, and its Modern Energy
  Cluster (the upgrade of the Galacticraft cluster that was already removed).
* Machines that duplicate a GregTech machine removed from crafting - Assembly Machine,
  Advanced Circuit Fabricator, Gas Collector, Gas Extractor, Liquid Separator, Universal
  Recycler - with their JEI categories hidden.
* Kept on purpose: the rocket assembler (tier 1-3 and the Galaxy Space tiers are built there
  for now; higher tiers become GregTech multiblocks), the NASA workbench categories, the
  utility machinery (modification table, gravity module, magnetic field generator, planetary
  shield, hydroponic base, oxygen storage cluster, oxygen tanks 4-6) and the batteries.
* Exoplanets needs nothing: its only machine-like block is a satellite antenna, and its ores
  smelting into GregTech ingots is GregTech's own registration being skipped as a duplicate
  (same input, same output).

Still to do - the stone types, which is what actually makes GregTech ore generation work on the
new planets. Two facts read out of GTCEu's `OreDepositDefinition` bytecode decide the design:

* the default `generation_predicate` is `StoneType.computeStoneType(state, world, pos) != null`
  - a vein only replaces blocks whose rock GT knows about, so **an unregistered planet rock
  produces no GregTech ore at all**;
* the default dimension filter is `WorldProvider.isSurfaceWorld()`, so veins without a
  `dimension_filter` (the whole overworld set) are not overworld-only - they apply to every
  surface world whose rock is a registered stone type.

Done, in the addon:

* **17 rock blocks of our own**, one per Galaxy Space body, textured with that body's own rock
  texture copied out of the Galaxy Space jar (`MinespaceGalaxySpaceRocks`, the table in
  `MinespaceGalaxySpacePlanets`, assets under `assets/minespace/`). Same reasoning as
  `minespace:moon_rock`: GregTech has to draw the ore on a base whose model this pack controls.
* **17 stone types**, registered at the block registry event (`MinespaceGalaxySpaceStones`).
  Their predicate matches *any* metadata of that body's Galaxy Space block, because Galaxy Space
  keeps the surface, subsurface and its own ores in one block and the vein generator can meet any
  of them.
* **The Galaxy Space dimensions were added to the planet vein files** earlier (`moon` also covers
  Mercury and the icy moons, `asteroids` covers Ceres / Pluto / Kuiper Belt / Haumea, `venus`
  covers Galaxy Space's Venus), so those veins now actually place ore.
* **Galaxy Space's own ore generation is off** (`config/GalaxySpace/world.conf`: planet ores,
  overworld ores, the new Mars ores, natural gas and its beta custom-ore list).
* **The two Galaxy Space-only ores became GregTech materials**: `dolomite` and `onyx`, each with
  its own vein (`vein/ceres/dolomite_vein.json` for Ceres and Miranda, `vein/barnarda/onyx_vein.json`
  for Barnarda C1). A probe of the ore dictionary is why: Galaxy Space's ore block registered
  `oreDolomite` but there was no dolomite item at all, and its onyx was in no ore dictionary name
  whatsoever, so a GregTech material is the only way those two survive with its ore generation off.

One naming trap worth remembering: GregTech refuses material names that look like
"materialnumber" (`Cannot add materials with names like 'materialnumber'!`), so Barnarda C1's
stone is `barnarda_c_1_stone` while its rock block stays `barnarda_c1_rock`.

Still to verify in game: that the ore *textures* on the new bodies look right (each ore is drawn
as our rock block for that body plus the ore overlay) and that Galaxy Space's progression is
still satisfiable now that its ores come from GregTech veins - the ore dictionary probe showed
magnesium, cobalt, nickel, ilmenite and sapphire all have GregTech counterparts, so only
dolomite and onyx needed the new materials above.

### Scarce, characteristic veins

Copies of the overworld vein set made the planets feel the same as the overworld, with nothing
rare to look for. Five low-weight veins were added, each tied to a group of bodies, after a probe
of the ore dictionary confirmed which rare ores this pack actually has (naquadah, platinum,
palladium, bastnasite, monazite, neodymium, beryllium, lithium, thorium, pitchblende, the gems):

| Vein | Bodies | Mix | Weight |
| --- | --- | --- | --- |
| `moon/rare_earth_vein` | Moon, Mercury, Miranda | bastnasite, monazite, neodymium, thorium | 6 |
| `mars/tungstate_vein` | Mars, Phobos, Deimos | scheelite, molybdenite, molybdenum, lithium | 8 |
| `asteroids/platinum_vein` | Asteroids, Ceres, Pluto | platinum, palladium, nickel, cobaltite | 10 |
| `asteroids/naquadah_vein` | Asteroids, Kuiper Belt, Haumea | naquadah, pitchblende, thorium, graphite | 4 |
| `venus/gem_vein` | Venus, Galaxy Space Venus | ruby, green sapphire, olivine, amethyst | 8 |

(The weight is deliberately far below the 20-50 of the copied veins: these are the veins a
player goes looking for, not the ones they trip over.)

One more trap from that work: `ore:tungsten` exists as an ore dictionary name, but it is
**Exoplanets'** ore, not a GregTech material - a vein filler naming it fails with
`Material with name tungsten not found!` and GT silently drops that vein. The tungstate vein
therefore uses scheelite / molybdenite / molybdenum / lithium, which are GregTech's own.
