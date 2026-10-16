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

| Galacticraft machine (measured registry item) | Decision, 2026-10-14 | Why, and what it has now |
| --- | --- | --- |
| Oxygen Detector (`galacticraftcore:oxygen_detector:0`) | **keep** | already in the pack's life-support keep-list (`gc_removals.zs`); gregfied into the assembler (`hightech.zs`), and Galacticraft's own Oxygen Sealer eats it - a build aid, not industry |
| Oxygen Storage Module (a `machine2` meta; this table's `:6` was a guess) | **keep, nothing left to do** | no `machine2` meta has a recipe in this stack - the pack took them all out - and `gc_removals.zs` already records that several `machine2` metas are not in JEI at all, so there is nothing to delete or hide. The pack's own Oxygen Compressor carries a 16000 mB buffer and GregTech's fluid tanks cover the storage job |
| Launch Controller (`galacticraftplanets:mars_machine:8` - the table's `:2` was the lang-file index) | **keep** | rocket logistics, the pack's "moves a player and a rocket" rule; it has a live MV assembler recipe |
| Terraformer (`mars_machine:0`), Cryogenic Chamber (`mars_machine:4` - the table's `:1` was the lang index again) | **keep** | the owner already had one attempt at removing Galacticraft's environmental machines reverted (the sealer and bubble distributor), and terraforming a planet and sleeping off-world are the space gameplay, not industry. Both have live recipes (table grid / assembler with a bed) |
| ~~Chromatic Applicator (`machine3:0`)~~ | **deleted 2026-10-14** (6ch) | cosmetic; the table's `:9` was the lang index, not the metadata |
| ~~Astro Miner Base (`galacticraftplanets:miner_base`)~~ | **deleted 2026-10-14** (6ch) | GregTech's ore/fluid drilling plants do the job; `miner_base_full` was never a second item |
| ~~Energy Beam Reflector (`galacticraftplanets:beam_reflector:0`)~~ | **deleted 2026-10-14** (6ci) | an orphan: a reflector only redirects the solar array's energy beams, and the array's controller, module and receiver were all removed earlier |
| ~~Laser Turret (`galacticraftplanets:laser_turret`)~~ | **deleted 2026-10-14** (6ci) | "can target meteors, players, and mobs" - a combat toy with no place in the chain. It was already uncraftable; the change only stops it showing as an obtainable item |
| Short Range Telepad (`galacticraftplanets:telepad_short:0`) | **keep** | it moves players, which is the pack's keep rule; live assembler recipe |
| Landing Pad (`galacticraftcore:landing_pad:0` Rocket Launch Pad, `:1` Buggy Fueling Pad), Parachest (`galacticraftcore:parachest`) | **keep** | rocket logistics. The pad keeps its own grid; the parachest has no recipe by design - it falls from the sky with the rocket |
| View Screen (`view_screen:0`), Telemetry (`telemetry:0`), Spin Thruster (`spin_thruster:0`) | **keep** | rocket electronics, already gregfied into the assembler. "Replace the screen/telemetry pair later" remains a nice-to-have, not a blocker |
| Space Station Base (`galacticraftcore:dummyblock`) | **keep** | a multi-block part with no recipe by design, like every dummy block on this list |

The ids were measured on 2026-10-14 with a probe over the finished registries (deleted again), which is
how the three lang-index mistakes in the old table were caught: `machine3:9` for the Chromatic
Applicator, `mars_machine:2` for the Launch Controller, `mars_machine:1` for the Cryogenic Chamber.
A second lesson from the same probe: Galacticraft encodes `mars_machine` as *type x 4 + tier*, so the
lang file's sequential names (`tile.mars_machine.0` ... ) never line up with the metadata.

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

## Galaxy Space (added later)

Galaxy Space was installed after the Galacticraft work; see `MOD-MANIFEST.md` for the jar and
its source. The same policy applies to it.

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

One more trap from that work: `ore:tungsten` is **not** a GregTech material. It only ever
existed because of Interstellar: Exoplanets, which has since been removed from the pack, and a
vein filler naming it fails with `Material with name tungsten not found!` - GT then drops that
whole vein silently. The tungstate vein therefore uses scheelite / molybdenite / molybdenum /
lithium, all of which are GregTech's own, so it stays valid with Exoplanets gone.

## The planet catalog: the 106 bodies the seven layers are made of - 2026-10-15

The master plan (the owner's `GTCEu星系整合包详细实施方案`, text at `tools\gtceu-galaxy-plan.txt`)
asks for seven layers of space, twelve solar-system bodies and "nearly 110" deep-space targets, all
under real names, with 5..8 veins each (5.4) and a design sheet per body (5.5). The vein table
already existed (`tools\planet-veins.psd1`); what did not exist was the **list** - the names and the
data that turn "about 110 bodies" into something a generator can be pointed at.

That list is now `tools\planet-catalog.psd1`, and it is rendered into
`Minespace-unofficial-dev\PLANET-CATALOG.md` (plus `tools\planet-catalog.csv` for the tools) by
`tools\build-planet-catalog.ps1`, whose numbers come from `tools\fetch-planet-data.ps1`.

**What it holds, measured by the generator's own report:** 106 bodies in the plan's seven layers -
20 solar system, then 16 in the nearby layer, 14 mid, 14 far, 14 deep, 13 ultra-deep and 15
"unknown" (observation only). Every one resolves to a NASA source; **24 carry veins today**.

**Reduced to 10-20 bodies per layer** (owner's decision, 2026-10-15) by one rule: *one or two
representative bodies per star system*, keeping - in this order - what the plan names, what the
instance already has a dimension for, and what is notable for habitability or for being a "first"
ever measured. 50 bodies were cut, and they were not thrown away: they sit verbatim in
`planet-catalog.psd1`'s `BodiesCut` block with their NASA data and notes intact, so restoring one is
moving a block back into `Bodies`. The 24 vein-carrying bodies all survive (three of them are
Galaxy Space's own planets), and so do all twelve of the plan's counted landing bodies.

**The layers are bands of _distance from Earth_, one order of magnitude each** (owner's instruction,
2026-10-15), and every body sits in the band its measured distance puts it in:

| layer | distance from Earth | bodies | what it is |
| --- | --- | --- | --- |
| 1 太阳系 | inside 40 AU (0.0000026-0.00042 ly) | 20 | the instance's own bodies: 19 landable plus Earth. The four gas giants are not bodies here - they are Galaxy Space's existing map objects, and stage five's atmospheric harvesting hangs off them |
| 2 近邻星系区 | 4-16 ly | 16 | Proxima b/d, Barnard b/c/d (Galaxy Space's three planets), Tau Ceti f, Teegarden b, Ross 128 b, GJ 887 d, Wolf 1061 c, GJ 1061 c, GJ 1002 b, Luyten's b, eps Eri b, Alpha Cen A, Sirius B |
| 3 中距星系区 | 16-100 ly | 14 | all seven TRAPPIST-1 planets, plus one representative each from Gliese 581 / 667 C / 876, HD 219134, HD 40307, 55 Cnc e and 51 Peg b |
| 4 远距星系区 | 100-2,000 ly | 14 | Kepler-452 b and one representative per other Kepler system, plus the bodies this close that are extreme rather than planetary (Betelgeuse, the Vela pulsar, PSR B1257+12 b) |
| 5 深空星系区 | 2,000 ly-100 kly | 14 | still inside the Milky Way: the disk, the centre, microquasars, molecular clouds |
| 6 超深空星系区 | 100 kly-100 Mly | 13 | the Magellanic Clouds through the Virgo Cluster |
| 7 未知星系 | 100 Mly-46.5 Gly | 15 | 10 of them beyond 10 billion ly (GN-z11, JADES-GS-z14-0, MoM-z14, UHZ1, GRB 090423, the two early quasars, Earendel, Ton 618, the Great Wall) plus the CMB shell at 46.5 Gly |

Two things this round corrected in the previous draft of the same day: bodies that violated their own
band (Betelgeuse, the Vela pulsar and PSR B1257+12 were sitting in "deep space", which starts at
2,000 ly - they are 548, 960 and 1,957 ly, so they now sit in the far layer), and a gap in the scale
itself (ultra-deep ended at 100 Mly while "unknown" was written as starting at 2 Gyr of light travel,
leaving 100 Mly-2 Gly unclaimed; the unknown layer now starts at 100 Mly). Eleven bodies beyond
10 billion ly were added, because that part of the scale had only five.

**The plan document contains no distances at all.** Searching its full text (including the tables)
for 光年/亿光年/万光年/AU/距离/尺度 returns zero hits: it names the seven layers and maps stages onto
"spatial ranges", but the numbers are this catalog's assignment, not the document's. Worth knowing
before treating any band boundary as a requirement.

**Scale, in the owner's own terms.** Each layer in `planet-catalog.psd1` also carries the owner's
`Real` / `InGame` / `Ratio` triple - how much the real universe holds in that shell, how many bodies
the pack actually places there, and the ratio (1:1 in the solar system and next door, ≈1:100 in the
mid layer, ≈1:10^6 far, ≈1:10^9 in the deep layer, ≈1:10^11 in the ultra-deep, ≈1:10^23 for the
observation-only shell). The generator prints all three, so the ratio cannot quietly drift away from
the body count.

**The solar system is closed: no new solar-system bodies** (owner's decision, 2026-10-15). The 24 are
the ones this instance already has - Earth, the Moon, Mercury, Venus, Mars, Phobos, Deimos, the
asteroid belt, Ceres, Io, Europa, Ganymede, Callisto, Enceladus, Titan, Miranda, Triton, Pluto,
Haumea, the Kuiper belt, and the four gas giants as Galaxy Space's existing map objects. Fourteen
candidates that would each have needed a new dimension were dropped on the way and are named in the
catalog's own header comment (the Sun, Vesta, Mimas, Tethys, Dione, Iapetus, Ariel, Umbriel,
Titania, Oberon, Proteus, Charon, Makemake, Eris), so a later round that wants one of them can see
exactly what it is re-opening. The other five entries with no vein card are Earth (GregTech's own
overworld tables, not this table) and the four gas giants (harvesting targets, not surfaces).
Worth noting for stage one: all twelve of the plan's counted landing bodies are inside that 24, so
the 90-day target needs no dimension of its own.

**Where the numbers come from, and why the fetch step exists.** The catalog file states design
decisions only - name, layer, stage, voltage, vein region or signature, ruin class, environment,
dimension id. Every measured quantity is fetched: planets, the Moon and Pluto from the NSSDC
planetary fact sheets (which also carry the atmosphere composition), moons from the NSSDC satellite
fact sheets, exoplanets from the NASA Exoplanet Archive `pscomppars` table over TAP, and the 40-odd
objects that have no archive entry (black holes, pulsars, galaxies, quasars, the CMB) as values in
the catalog with the NASA page they came from, whose stating sentences are kept in the cache as
`Evidence`. `fetch-planet-data.ps1` caches to `tools\nasa-planet-data.json`; a tag in the catalog says
which source formula a body uses (`sheet:`, `sat:`, `mooncol:`, `exo:`, `fixed`).

Four findings from building it, in the order they cost time:

* **JPL's SSD host does not complete a TLS handshake from this machine** (`ssd.jpl.nasa.gov`,
  measured 2026-10-15), which is why the moon parameters come from NSSDC rather than JPL. NED
  (NASA/IPAC) answers, but `ObjectLookup` returns position and redshift only - no distance - so it is
  not usable as a distance source either.
* **The NSSDC sheets come in three layouts, not one**: horizontal (a row per metric - Mars, Venus),
  vertical (a *cell* per row - the Sun, the Moon, the satellite sheets, and the comparative sheet
  itself), and inline (label and value in one cell - Earth's sheet, Charon's table inside Pluto's).
  Reading one with another's parser yields a plausible-looking table of empty columns rather than an
  error, so `Parse-BodyFactSheet` runs all three and keeps the richest result.
* **A `.ps1` or `.psd1` containing Chinese must be saved as UTF-8 *with* BOM.** Windows PowerShell
  5.1 decodes both by the ANSI code page otherwise, and a 3-byte UTF-8 sequence can swallow the
  closing quote of the string it lives in; the file then fails to parse with errors a hundred lines
  away from the real cause. `Import-PowerShellDataFile` refuses the whole catalog with no line
  number. Both new scripts and the catalog are BOM'd, and re-BOM after editing with a tool that
  strips it.
* **`$cells[0..($cells.Count - 2)]` is an infinite loop when the array holds one element** -
  PowerShell reads `0..-1` as "index 0 and index -1", so the array never shrinks. It cost a
  fifteen-minute hang in the HTML reader before it was found.

**Two design decisions this round had to make, both flagged rather than assumed:**

* **The plan never names its twelve solar-system bodies.** It gives a work order instead (week 2 the
  Moon as the gold standard, week 3 "the inner three" Mercury/Venus/Mars, week 4 the asteroid belt
  and six moons). Read literally that is eleven, so the twelve are taken as Earth + the Moon + the
  inner three + the belt + six moons (Phobos, Deimos, Io, Europa, Ganymede, Titan). They carry
  `Priority = 1` in the catalog; changing the set is one field per body.
* **Galaxy Space's `Barnarda C`, `C1` and `C2` are fictional names**, and the plan requires real
  ones, while its `Proxima C`/`Proxima D` happen to be real. The catalog therefore maps dimension
  `-1030/-1031/-1032` onto the real **Barnard b/c/d** (discovered 2024-2025, all four now in the
  archive) and keeps each dimension's signature vein. That is a rename decision the owner should
  confirm, because it changes what a saved world's map calls those planets - the dimension ids
  themselves do not move.
* **"Tau Ceti e/f/g/h" are not in the archive at all** (they are 2017 candidates that later work
  questioned), so they are in the catalog as `fixed` entries with the paper's numbers and an explicit
  "candidate, not in the archive" note rather than being presented as confirmed bodies.

**Dimension ids.** The plan's table 5-2 allocates -100/-110/-120, which is ten ids per band; Galaxy
Space already occupies -1005..-1032, -1126..-1129, -1234 and -1338, and the solar system now adds
nothing at all, so the new bands are all outside it: nearby -2000..-2099, mid -2100..-2199, far
-2200..-2299, deep -2300..-2349, ultra-deep -2350..-2399, and observation-only -2400..-2449. The
generator fails the build on a collision.
