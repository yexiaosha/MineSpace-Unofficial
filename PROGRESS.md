# Minespace: development progress

**Status snapshot: 2026-10-15.** This file is the hand-off for a fresh session. The *living*
records are the two plan files next to the code (every round is a numbered section there, dated,
with its measurements and its verification); this document is the map to them plus everything that
is not written down anywhere else.

Repository root: `D:\work\minespace`. Two projects:

```
Minespace-unofficial/       the addon (Gradle, Java). Its docs are the living records:
    TJ-MIGRATION-PLAN.md          §1-§8 plus dated rounds 6a .. 6ct - read this first
    GC-GREGFICATION-PLAN.md       the Galacticraft side; its "Still to do" table is empty
    HANDOFF.md, DEV-NOTES.md      older, addon-level (pre-migration) notes
    tools/                        local Gradle 4.10.3 + JDK 8 + setup scripts
Minespace-unofficial-dev/   the playable instance (mods/, config/, scripts/, world/, logs/)
    MOD-MANIFEST.md               per-file inventory of the instance: what each script/config does
    scripts/                      CraftTweaker: the pack's own balance work
    logs/latest.log               the run you verify against; *.log.gz are archived baselines
```

## 1. What the project is

A Minecraft 1.12.2 pack built around the addon: **GregTech CE: TJ Edition** + **Gregicality TJ Fork**
(the GTCE-lineage stack that carries UHV+ content) welded to **Galacticraft / Galaxy Space**, with a
handful of other mods (Forestry, Ender IO, Storage Drawers, Iron Chests, AE2 UEL, JEI, CraftTweaker,
ModTweaker, KubeJS, Xaero's). **The goal throughout has been UHV+ content that is actually playable**
(i.e. with recipes, reachable, and gated the way the owner wants it).

The migration from GregTech CE: Unofficial to GTCE-TJ is **done** (plan §6, milestones M1-M4): the
addon is ported, the real instance runs the TJ stack on a new world, 47 mods, clean boot.

## 2. How work is done here (the pattern every round follows)

1. **Measure, never assume.** Every claim in the plan is a number or a bytecode/registry fact with a
   dated round behind it. Temporary instruments (a Java probe or a CraftTweaker script) are written,
   used, then **deleted**, and the jar is rebuilt so the instance never ships with one.
2. **The instrument for anything about the finished registries** is a small Java class called from
   `Minespace.loadComplete()`. That is the first point after CraftTweaker has applied its actions -
   a *script* that reads the crafting registry while scripts are still loading sees the state
   *before* the pack's own removals (plan 6cl records that trap; it cost a round).
3. **Verify with a dedicated-server run** and diff against the archived baseline (see §5). Zero
   errors in `crafttweaker.log` is the proof that every item id named by the scripts exists - naming
   a missing one is an error there, not a silent skip.
4. **Things a server cannot see are written down as "in game" checks** rather than claimed: GUIs,
   JEI's client-side list, tooltips.

### Commands

```powershell
# rebuild the planet catalog (159 bodies) from NASA sources; the host must reach the internet
cd D:\work\minespace\Minespace-unofficial\tools
.\fetch-planet-data.ps1            # caches to nasa-planet-data.json (a rebuild is then local)
.\build-planet-catalog.ps1         # -> ..\..\Minespace-unofficial-dev\PLANET-CATALOG.md + planet-catalog.csv
```

```powershell
# build the addon and copy it into the instance
cd D:\work\minespace\Minespace-unofficial
.\tools\gradle.ps1 --console=plain deployToInstance        # ~11 s when the network is up

# run the instance (dedicated server; it is how every verification here was done)
cd D:\work\minespace\Minespace-unofficial-dev
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force   # needed for .ps1 once per shell
.\Play-Minespace.ps1 -Server *> .\logs\run-console.txt
# wait for "Done (" in logs/latest.log, then type  stop  to shut it down cleanly
```

Read results in `Minespace-unofficial-dev\logs\latest.log` (the run) and `crafttweaker.log`
(script output; `print(...)` lands there).

Seeing a *screen* without a player (plan 6dt): the star map can photograph itself.

```powershell
cd D:\work\minespace\Minespace-unofficial
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force   # needed for .ps1 once per shell
.\tools\capture-starmap.ps1                  # builds, deploys into D:\minespace-capture-run, photographs, quits
.\tools\capture-starmap.ps1 -Tier 1          # the research-data gate part-way open (see plan 6ep)
.\tools\capture-starmap.ps1 -Tier -1         # no override: the real gate, with nobody playing
.\tools\capture-starmap.ps1 -System Crab     # a named system's own view instead of Sol
.\tools\capture-starmap.ps1 -Tier 0          # everything PlanetProgression has surveyed (plan 6er)
.\tools\capture-starmap.ps1 -PlanetProgression $false -Tier 1   # ... and the survey-data road on its own
.\tools\run-server.ps1                       # the same for the boot check, in the same scratch directory

# regenerate what the registry reads: body icons by kind, and the names Galacticraft and PlanetProgression show
.\tools\build-celestial-art.ps1
.\tools\build-celestial-lang.ps1
```

With the flag set the screen opens itself at the main menu, reads its own framebuffer with
`glReadPixels`, writes both levels to PNGs and shuts the game down. Without it, none of that code runs and
the shipped jar behaves exactly as a player sees it. The script aims the camera at a copy of the game
directory - `D:\minespace-capture-run` holds mods\, config\, scripts\, kubejs\, options.txt, alsoft.ini,
logs\ and shots\ and no saves - so the owner's world is never touched, and it logs to
`Minespace-unofficial-dev\logs\latest.log` (`star map gate:` is the line that says what the gate let through).

### Environment gotchas (all learned the hard way)

* **Java does not use the Windows system proxy by default.** This machine reaches the internet
  through a proxy, so ForgeGradle's own downloads (MCP snapshot, Minecraft client) hang forever in a
  socket read. `gradle.properties` now carries `-Djava.net.useSystemProxies=true` in
  `org.gradle.jvmargs`, and with it the build takes ~11 s instead of hanging for an hour. If a build
  still hangs, `$env:JAVA_TOOL_OPTIONS='-Djava.net.useSystemProxies=true'` for one run does the same
  for the forked build JVM. (A loopback-proxy trick was tried first; it is *not* the fix.)
* `-Dorg.gradle.jvmargs=...` on the PowerShell command line does not survive argument parsing (it
  arrives as a task name); `JAVA_TOOL_OPTIONS` does.
* Only one server can run at a time: the second launch fails because `logs\run-console.txt` is locked.
  Always `stop` the previous run.
* The addon's compile classpath is the *mapped* snapshot, in which some vanilla accessors are not
  named (`ResourceLocation.getPath()`/`getNamespace()` do not exist there; `String.valueOf(id)`
  works). `ForgeRegistries.ITEMS.getKey(stack.getItem())` + `stack.getMetadata()` is the safe
  item-key idiom the pack's own code uses.

## 3. Where things stand (2026-10-15)

### Done and verified

* **The stack migration** (plan §6, M1-M4): GTCE-TJ + Gregicality TJ, 47 mods, new world, the old
  GTCEu save parked as `world-gtceu-backup`.
* **Ore veins on the planets** (6cu/6cv/6cw/6cx): the planets no longer share one base set - 6cw gave each body **GTNH's own per-vein planet lists**, parsed out of the owner's GTNH 2.9 instance (`tools/gtnh-vein-planets.txt`, 78 veins read from GT5U's `OreMixes`), so Moon 6 veins, Mars 12, Venus 13, Io 5, Titan 7, Kuiper Belt 9. **6cx then showed the direction cannot be extended:** of the 38 further GTNH veins that were written, **16 name ore blocks this fork deliberately does not generate** (`chrome`, `titanium`, `tungsten`, `manganese`, `vanadium`, `borax`, ... - the materials exist, the ore blocks do not) and 8 files were written malformed. That round is withdrawn; its files are parked outside the loaded tree in `Minespace-unofficial\tools\vein-staging\gtnh\`. 6cx also read the schema out of the jar, and it matters more than the data: **`weight` is a share inside a body's vein list, the 0..2 veins per 3x3 section are a global config, and there is no per-body richness knob** - so 100+ planets have to be differentiated by *composition*, and one vein cannot hold a different share on two bodies without a second file of the same name. Honest state: 111 files, 78 names, **74 `(dimension, name)` pairs registered more than once**, and Europa had regressed to a single vein (repaired - it has 9 again). The archetype + signature + region scheme proposed for the 100+ planet scale is **written up in plan 6cx but not applied** - that is the open decision.
* **Where the planet content lives** (6cy): the 100+ bodies are going to be **the owner's own content in
  this addon**, not a Galaxy Space expansion - so the planet table and the vein table can be one thing.
  Measured with a temporary probe: the addon **can build and initialize** a vein definition from code
  (`new OreDepositDefinition(name)` + `initializeFromConfig(JsonObject)`, shape/filler/populator all
  live by load complete) but **cannot append one** - `getOreDeposits()` hands out an unmodifiable view
  of a private `ArrayList`. Recommended delivery is therefore config JSON generated from the addon's
  table; the reflection and mixin routes, and the load-order measurement, are in plan 6cy.
* **Ore generation**: every ore in three fresh worlds is GregTech's or AE2's - no Galacticraft,
  Galaxy Space or Forestry ore block anywhere (6bv); planet stone types, vein sets and the scarce
  per-body veins are ported and measured. A 6cu sweep of every vein file's `dimension_id` list (one
  set reaches many bodies) confirms all 21 planet dimensions are mined, 8-14 veins each; **Proxima B
  (-1025) and Tau Ceti F (-1338) had none at all and now carry the rocky-body base set**. Whether ore
  actually generates there is the one thing only an in-game visit can confirm.
* **The addon's two machines** (oxygen compressor, rocket fuel loader): registered, with GT-style
  screens and the "no energy" indicator plate; their in-game look is the only unverified part.
* **The star map is the pack's own** (6do/6dp/6dq/6dr/6dt): `MinespaceStarMapScreen`, opened on **J**,
  two levels deep - 77 systems, then the bodies of one - drawn entirely from the generated table
  (`MinespacePlanetDimensions`), never from Galacticraft's map (that attempt is shelved, 6dq/6dr). Round
  glowing stars tinted by spectral class, a real nebula backdrop (`tools\build-starmap-art.ps1`), dotted
  orbit rings, labels, and a **你在这里 · Sol** marker. The 81 planned dimensions are registered again
  (6dm), verified by two clean client runs, and the 44 observation-only bodies are on the map as
  unreachable. Everything visual here was checked by self-capture, not by asking the owner to restart.
* **The gregification of every other mod's content** (rounds 6d-6ck): materials unified to GregTech's
  items, machines moved off the crafting table, prices re-costed for the content the pack took over,
  a dead-ingredient audit, name-hygiene sweeps, and standing guards that run on every start (recipe
  hygiene, machine-only enforcement, no-double-route).
* **The power rule** (6m, corrected in 6cl): RF -&gt; EU is capped at HV (all FE-to-EU converter
  recipes above HV are removed and hidden), EU -&gt; FE is complete at every tier. 6cl found the
  original rule was on the *wrong family* (the two Gregicality converter families read backwards from
  their names); the fix is measured in the finished registry.
* **The top end** (6cm-6ct):
  * UXV is complete: its machine hull, its machine casing, its two base energy hatches and the whole
    UHV..UXV battery-buffer/charger family are written and buildable;
  * "MAX" is not a voltage tier in this stack (the table ends at UXV, tier 13; GT's "MAX"-labelled
    machines run at tier 9) - so MAX playability is Gregicality's UXV machine set plus GT's
    MAX-labelled infrastructure, all buildable;
  * the top tiers' routes are settled: above UV the hulls and casings are **assembler-only**, in the
    shapes the tiers below use;
  * rule 3 (cost shapes) is green: Gregicality's top-tier machines are uniform (39 per tier at
    hull + circuit + cable), with one repeated cheap shape noted (five machines per tier without the
    tier circuit - recorded, left alone);
  * the complete "second route" list is 27 machine items; the owner's call is that **low-voltage
    content keeps both routes** (GT's/Gregicality's originals are not touched), and that call is
    recorded in 6ct.

### Open / not done

* **In-game looks** (a human, ~10 minutes): the two addon machines' GUIs; whether Proxima B and Tau Ceti F now have ore (6cu - they have vein sets now, but only a visit proves it); the converter check in JEI
  (`Forge Energy Converter` should offer ULV..HV only, `GTEU Energy Converter` craftable at every
  tier, and hovering one must read "Converts GTEU to FE"); and that UXV content (hull, machines, the
  UHV..UXV buffers/chargers) is present and craftable in JEI.
* **Pricing above UV** is measured for rules 1-3 (6cr/6cs) and green; what is *not* done is any
  re-costing of Gregicality's own top-tier prices - they are kept as the mod ships them, deliberately.
* Optional, recorded, not started: the fuller instance `README.md` refresh (6cj notes it); the five
  cheap UXV machines (6cs) if the owner ever wants the top machines to cost the same as each other.
* **The star map's remaining work**: the **unlock gate** (which research item opens which layer - the one
  item only the owner can settle; the roles are in plan 6dr), whether locked bodies are shown at all, real
  positions (RA/Dec through `tools\fetch-planet-data.ps1` and a re-fetch), and the owner's own in-game look
  of the finished screen, which is still the thing that decides.
* `Minespace-unofficial-dev` has a large uncommitted working state; nothing here has been committed.

## 4. The pack's rules, in one place

These are the rules every round is applying, all of them measured rather than assumed:

1. **Unification**: every material comes from GregTech's own item; the mods' copies are emptied and
   hidden.
2. **No second route**: if a machine makes a thing above UV, the crafting table must not; below UV
   the mods' own dual routes are left as their authors wrote them (6ct).
3. **No tier skip**: a machine of a tier consumes that tier's own hull (and its casing, circuit and
   cables - the shape inventory in 6cs).
4. **Tier-shaped costs**: new recipes copy a shape that already exists at or below that tier, with
   that tier's parts (6cr's rule 3 table).
5. **Nothing unobtainable is offered**: an item nothing can make is either completed, or removed and
   hidden (6cn/6co: UXV), and one that has "lost the machines it works with" leaves the pack's view
   (6ci).
6. **The pack does not re-cost another mod's content** unless it is writing that recipe itself, or
   the owner asks.

## 5. The baseline a run is compared against

From a clean dedicated-server start (last measured 2026-10-15):

```
Forge Mod Loader has successfully loaded 47 mods
Done (~1.8s)                      (1.7 - 6 s depending on disk cache)
crafttweaker.log: 0 errors
machine-only enforcement (postInit pass): 10     (loadComplete pass: 0)
no-double-route (postInit pass): 20              (loadComplete pass: 0)
2 x "Invalid recipe" and 2 x "Input cannot contain null"   (both are the archived baseline)
19 "Exception" mentions in latest.log             (vanilla door + Ender IO mod-list noise)
```

A change that moves any of those numbers is either explained in its plan section or a regression.

## 6. Where the recent rounds live

In `Minespace-unofficial/TJ-MIGRATION-PLAN.md`, in order: **6cl** (the EU/FE ceiling was on the wrong
family), **6cm** (the UHV+ census: 920 Gregicality machines, 820 table / 37 machine-only / 63 with no
producer), **6cn** (UXV retired - later overruled), **6co** (UXV completed; the UHV..UXV buffers
written; what MAX is), **6cq** (MAX is not a tier; the build's proxy problem), **6cr** (the pricing
rules above UV, part one: the tier gate, and the route decision), **6cs** (rule 3: the tier shapes are
uniform), **6ct** (the complete dual-route list and the owner's call).
Then the planet veins: **6cu** (two Galaxy Space bodies with no veins at all), **6cv** (what the
distribution is and where it came from), **6cw** (GTNH's own arrangement applied), and **6cx**
("copy GTNH" withdrawn at 100+ planets - the two write bugs that came with it, what the vein schema
actually allows, and the archetype + signature + region proposal that is still an open decision).
Then **6cy**: the 100+ bodies are the owner's own content in this addon, and a probe measured whether
the addon can register veins itself. It can *build* and *initialize* a definition from code
(`new OreDepositDefinition(name)` + `initializeFromConfig(JsonObject)`) but cannot *append* one -
`getOreDeposits()` hands out an unmodifiable view of a private `ArrayList`. Recommended delivery is
therefore config JSON generated from the addon's own table; the reflection and mixin alternatives,
and the load-order measurement, are in 6cy.
Then **6cz**: the owner supplied the design document the 100+ planets follow (*GTCEu 星系整合包详细实施
方案* V1.0, text kept at `tools\gtceu-galaxy-plan.txt`), which turns the vein question from a design
argument into an acceptance list: **5..8 veins per body**, diversity by combination instead of new
ores, a **geological reason** per vein, **no duplicates and no dead definitions**, and **resource
closure** per voltage tier (EV materials 100% obtainable inside the solar system). `tools\
accept-planet-veins.ps1` was written for that list, and its first run measures what 6cx left behind:
**74 duplicate `(dimension, name)` pairs and 22 bodies above the 5..8 range are FAIL**, plus a defect
class nobody had looked for - **3 definitions with no `dimension_filter`**, so they generate nowhere
(`ceres\dolomite_vein.json`, `mars\certus_quartz_vein.json`, `venus\certus_quartz_vein.json`).
Then **6da**: the first two items of the plan's own sequence are done. The vein-variant structure is
`tools\planet-veins.psd1` (bodies with geology cards + variants with primary/secondary/byproduct
shares, weight, depth band and a geological reason), and `tools\build-planet-veins.ps1` derives the
JSON from it while enforcing three invariants: a body's list is exactly the variants naming it (so no
name can appear twice on one body), a managed body's dimension id is stripped from every other vein
file, and every ore must already be in use by a file in the config (the 6cx lesson). Vein names are
written to read as titles, because `GTOreInfo.makePrettyName` shows them with `.`/`_` turned into
spaces - which is why the old names read "gregtech veins ore bauxite". **The Moon is the gold
standard: 7 veins, zero duplicates**; Europa 1 → 6, and the four nearby-system bodies (Barnarda C/C1/C2,
Proxima B, Tau Ceti F) 1/10/9/9/9 → 6/6/6/5/5. Two lessons: the `moon` folder was the only coverage
for five other bodies (deleting it left them with none), and the acceptance script had a false OK
because it iterated the dimensions present in the files instead of the known body list. Verified:
`Loaded 120 worldgen definitions`, 0 parse failures, 47 mods, `Done (1.789s)`, 0 CT errors, 19
`Exception` mentions. Remaining: the other eighteen solar-system dimensions, the 3 dead definitions,
and the resource-closure table.
Then **6db**: the other fourteen solar-system bodies (Mars, Venus with GS Venus, the Asteroids,
Mercury, Ceres, Pluto, the Kuiper Belt, Phobos, Deimos, Io, Ganymede, Enceladus, Titan, Triton,
Callisto, Haumea, Miranda) now carry geology cards too, and **all six of the plan's countable
criteria pass for the first time**: 25 bodies at 5..8 veins, **0 duplicate `(dimension, name)` pairs**
(was 74), 0 bodies without veins, 0 dead definitions, 117 files parsing. Two traps are now caught by
tooling rather than by care: a pruned folder can be another body's only coverage (the generator
warns), and a hand-written ore vocabulary is a hypothesis, not evidence (`ore-vocabulary.txt` is
refreshed with `-UpdateVocabulary` from a server start that parsed cleanly - the loader rejected three
names that had been in it, `sheldonite` because the material does not exist here and `silicon` /
`perlite` because their ore blocks do not). What is left in stage two is the resource-closure table,
and no balance pass has been done at all yet - the shares are a first draft.
Then **6dc**: the resource-closure checklist of plan 2.2 is built - `tools\check-resource-closure.ps1`
joins the config (supply) with a registry dump (demand: 794 materials, **164 with an ore block**, with
each one's byproduct chain, read by a temporary probe and kept in `tools\ore-registry.txt`). Numbers:
127 ores generated (64 solar / 62 overworld-nether-end / 1 nearby), **116 materials reachable from the
solar system alone** including byproduct chains, and 21 ore-bearing materials no vein sources. **The
finding worth acting on: `onyx` is the only material whose sole source is an exoplanet (Barnarda C,
unlocks at IV)** - under 2.2 nothing before IV may need it, and the plan's own remedy is a vein
variant. The other twenty are a strict lower bound, not a verdict: the closure does not yet follow
decomposition or chemistry, which is how iridium, osmium and the carbonate minerals are actually made.
Also fixed: `ore:poor:<material>` - GalacticGreg's quality-prefixed filler form, in use in the nether's
precious vein - had been read as an ore named "poor" by all three of the new scripts.
Then **6dd**, which is the answer to "how do the exo systems work under this": a geology card per body
does not scale to a hundred and ten, so the table grew the **region layer** - a region owns a suite, a
body names a region and optionally a signature. The four nearby-system bodies were rewritten onto it,
and the generated files are **byte-identical** to the verified ones (all 117 hashed, 0 differences),
because the refactor changes what the table costs, not what it produces. The cost is now: ~10-14
suites x 5-6 variants covers every body in the game, signatures only for the ~20-30 bodies the plan
names - **adding a planet is one row**. Two things must be decided before the first exo body: the
dimension-id scheme (plan table 5-2 predates Galaxy Space's real -1005..-1032 / -1338 allocation) and
who owns the planets (self-written dimension provider vs Galacticraft's machinery).
Then **6de**, on the owner's forward plan (adventure mods later, their ores need veins written here,
endgame includes Avaritia and Draconic Evolution): the plan's rule 5.4 "do not add ores" governs this
pack's *own* roster, while a **mod's currency ore** is a different thing that has to exist - so it is
admitted by one of three routes, **natural / exotic / artificial**, the last one tying it to the plan's
own ruin (Kardashev) system rather than pretending a dragon ore is volcanic sulphides. The order of
operations is already enforced by `ore-vocabulary.txt`: install the mod, start the server, refresh the
vocabulary, then author. `check-resource-closure.ps1` was rebuilt around the plan's stage table, so it
now prints a **closure ladder** - stage 1 (Earth) 162 materials, **stage 3 (EV) 173**, stage 4 (IV)
174 - and a mod ore enters at exactly one stage. The gap that would turn that into a verdict is the
demand side (which tier consumes what, from the recipe graph).
Then **6df**, which did that and found the limit of it: a temporary probe walked **73 recipe maps /
70,211 recipes** (786 materials consumed somewhere), and "the lowest tier that consumes a material"
turned out to be **tier 0 for nearly everything** - some cheap processing recipe consumes almost any
material at whatever tier it carries. The statistic that survives is the **highest** consuming tier (a
tier-0 recipe cannot raise a maximum), propagated through byproduct chains so an ore is judged by where
its products are used. That supports one check in `check-resource-closure.ps1` - *a material supplied
after its last use can never be used* - which is **sound but incomplete**: passing it does not prove
rule 2.2, because the registry records what *can* be consumed, never what a player must build.
**The finding: `solar`, this pack's own material, generates on Venus (stage 3 / EV) while nothing above
LV consumes it - it is placed too late for everything that wants it.** The raw demand data is
`tools\recipe-demand.txt`.
Then **6dg**, the composition rule for all ~110 bodies, which is what makes the one-row-per-planet
story complete: every body outside the solar system carries **universal base (5) + layer delta (2-4) +
signature (0-1)** = 5..8 veins structurally, the plan's own rule arrived at by construction. The base
is silicate / iron-nickel / sulphide / rare earth / volatile, shared by every non-solar body so no
landing is a dead end; the delta carries the layer's theme (mid systems = heavy elements and the first
ruin ores; far = crystals and the exotic; deep = extreme matter, and where draconium belongs; ultra =
made rather than mined, Avaritia-tier and the artificial route); the signature belongs to the bodies
the plan names. Layers 5-8 cannot be told apart by *new materials* - this fork's set is fixed at 794
materials - so the differentiation is concentration, geology type and ruin content. Arithmetic: ~105
variants cover the whole game. Implemented and verified: `Includes` (a layer says `@('base')` instead
of repeating five names) and `Planned` (a layer can exist as stage + voltage + theme with no bodies; the
generator skips it and prints it under "planned layers"). All 117 files byte-identical after the
refactor.
Then **6dh**: the five nearby-system bodies got **real cards** (Proxima B, Barnarda C / C1 / C2, Tau
Ceti F), and the design driver was 6dc's own output - the list of ore-bearing materials with no source
anywhere, which is plan 2.2's "any gap is filled by a vein variant" waiting to be obeyed. Each body is
now base 5 + delta 2 + signature 1: Proxima B's signature is **zircon** (the oldest, most re-melted
crust in the pack); Barnarda C keeps onyx; C1 gets a **pegmatite** (columbite/gallite/cassiterite);
C2 gets the first **ruin cache** in the pack (vinteum/opal/jasper on a world that could not have made
them - 6de's artificial route in use); Tau Ceti F gets **carbonate evaporites**
(witherite/celestine/rhodocrosite) and a pressure-diamond vein. To allow it, the ore vocabulary now
also takes its evidence from the registry dump (164 materials have ore blocks) - stronger than "some
file uses it", and without it the check would refuse the very ore the plan asks to place. **Gaps 20 →
9**, ladder stage 4 from +1 to **+11 ores / +13 materials (186 total)**, 126 definitions loaded with
zero failures and all six criteria still OK. The nine left divide: iridium/osmium are not real gaps
(decomposition), and trinium/triniite/bowieite/arsenopyrite/fluoroapatite/caliche/barytocalcite are
candidates for the mid and far layers. `solar` is still flagged as supplied after its last use.
Then **6di**, which closed that last flag and named the reason it existed: `solar` **is** consumed -
`gc_crafting.zs` converts it to Galacticraft's Venus "solar dust" with
`recipes.addShapeless(<galacticraftplanets:basic_item_venus:4>, [<ore:dustSolar>])`, a **crafting-table**
recipe, and GT's recipe maps contain no crafting-table recipes at all. So the ore was placed correctly
(it is on Venus, and a Venus machine wants it) and the check was blind. That names the **three classes
of demand**: GT machine recipes (tier-stamped, measured), the pack's own table recipes (171 materials,
**no tier at all**), and necessity (nowhere - a design decision). `check-resource-closure.ps1` was
rebuilt rather than patched: it reads `<ore:...>` references inside recipe-addition statements only and
excludes those materials, while *printing* how many were excluded and which would otherwise have been
flagged. Result: `[OK] 0 too late`, with `solar` shown as the one material only a crafting table wants.
Then **6dj**: the owner wrote the body list - `Minespace-unofficial-dev\PLANET-CATALOG.md`, tool-generated
from `tools\planet-catalog.psd1` + `nasa-planet-data.json` (fetched from NASA NSSDC / the Exoplanet
Archive). **106 bodies**: 20 solar-system + 86 deep-space targets, all real, all measured. It is the
other half of this work rather than a new requirement: its vein column *reads `planet-veins.psd1`* for
the bodies already configured and says "未配置（按所属层的套件 + signature 生成）" for the rest - which
is the 6dg scheme by name. It also settles what 6dd left open: **dimension ids** (nearby -2000..-2099,
mid -2100..-2199, far -2200..-2299, deep -2300..-2349, ultra-deep -2350..-2399, unknown -2400..-2449,
per-body ids assigned, no overlap with GS). Two of its seven layers have **no landable body** (the Local
Group and beyond the galaxy gates are observation only), so they need no veins - this table carries them
as `Planned` stubs. Galaxy Space's fictional "Barnarda C/C1/C2" became **Barnard's Star b/c/d** on the
same ids, and this table's entries and the audit's body list were renamed. **37 landable bodies still
need vein sets** (layers 2-5); 44 need none. Each has its design brief in the catalog's 备注 column.
Then **6dk**, the first layer designed ahead of its dimensions: the mid systems (TRAPPIST-1 and the
Gliese field, ids -2100..-2121) got their delta - `Heavy_Refractory_Vein` - and **twelve cards**. A new
state was needed: **`Pending`** - a body whose dimension does not exist yet counts toward the design
(its veins are counted, the catalog can read them) and contributes nothing to the output, because vein
files for planets nobody can reach would sit in JEI advertising them. Verified: **126 files unchanged**,
all six criteria still passing. Two of the catalog's fourteen are gas giants (Gliese 876 b, 51 Pegasi b)
and get no vein - a gas giant has no surface, and stage five's own theme is atmospheric harvesting.
Six signatures come from the catalog's 备注 plus the closure gap list: TRAPPIST-1 e's **Dyson wreck**
(trinium/triniite/bowieite), 55 Cancri e's **magma ocean** (arsenopyrite), HD 40307 g's **temperate
brine** (fluoroapatite/caliche/barytocalcite), HD 219134 b's **dense siderophile** vein
(iridium/osmium - the two 6dc called false gaps, mined here for the first time), and the shared
**runaway greenhouse** for TRAPPIST-1 c and Gliese 581 c. TRAPPIST-1 f/g/h reuse Europa's icy veins
instead of inventing new ones. If those six land the gap list goes 9 → 0, but the ladder will not show
it until the dimensions exist - designed-then-inert is the order.
Then **6dl**, an attempt to close the one claim that was never tested - *does ore actually appear on a
planet?* A temporary probe generated a 4x4 chunk area at 2000,2000 in each of the 25 planet dimensions
at server start, waited 100 ticks for the Venus-style fallback, and scanned every block for ore. Result:
**all 25 dimensions are registered and their providers exist** (`-28` reports as `moon.moon`) - but
**`DimensionManager.getWorld(id, true)` returns null for every one of them**, without throwing, so no
chunks could be generated and no ore could be counted. Forge does not create a planet world here;
Galacticraft brings one into existence when a player travels. So that question **cannot be answered
from a dedicated server at all** - the in-game visit 6cu/6cv recorded as the owner's check is the only
route, not the convenient one. The registration half is now positively confirmed, which was previously
assumed. Probe deleted, jar redeployed, `Loaded 126 worldgen definitions`, 0 `VPROBE` lines, baseline.
Then **6dm**: the owner's "register them all first, no terrain" is done - **81 planned dimensions
registered, 37 landable and 44 observation only, 0 conflicting with Galaxy Space or Galacticraft**.
`tools\gen-planet-dimension-table.ps1` generates `MinespacePlanetDimensions.java` from
`planet-catalog.csv`, so the catalog stays the single source of truth and the addon reads no file at
runtime; landability follows the catalog's own rule and reproduces the 37/44 split the plan had computed
by hand. Registration runs in preInit with **one shared void provider** per body and leaves any id that
is already registered alone with a warning. It is cheap because **registering a dimension does not
create a world** (6dl). Verified: `Registered 81 planned dimensions (37 landable, 44 observation only),
0 already owned by another mod`, then the baseline (126 definitions, 47 mods, `Done (2.021s)`, 19
exceptions). **Registered is not playable**: the ore-generation hook only fires for
`IGalacticraftWorldProvider` dimensions, so these 81 have no ore yet - written into the class javadoc so
it cannot be mistaken for done. Next: make those providers Galacticraft-compatible (or widen the guard),
then un-pend the 37 landable bodies' cards.
Then **6dn**, step one of that: the ore hook now reaches the planned dimensions. `isPlanet` was testing
`instanceof IGalacticraftWorldProvider`, which was right when every planet was Galacticraft's; what it
actually needs is **"does this dimension's generator skip `GameRegistry.generateWorld`"**, which is the
reason the class exists at all - Galacticraft's providers skip it, the planned dimensions' void
generator skips it too, and the overworld/Nether/End call it and stay out. Verified: 81 registered, hook
registered, baseline (126 definitions, 47 mods, `Done (1.927s)`, 19 exceptions). **But eligible is not
able**: a void world has *no stone to replace*, and GT's veins work by replacing the dimension's stone
type - so **terrain and a per-dimension stone type come first, ore second**. That is the Galaxy Space
machinery (`MinespaceGalaxySpacePlanets`: rock + stone type + material per body) generalised from 17
bodies to 81, and it is the piece that turns a registered dimension into a minable planet.
Then **6do**: the 81 planned bodies are **on the star map, unreachable** - the owner's "make them
non-landable so the map can show them". The map turned out to be **Galacticraft's**:
`GSMapHandler` is only a render handler on `CelestialBodyRenderEvent`, so a body appears on it by being
in `GalaxyRegistry`, and `CelestialBody.setUnreachable()` is exactly the "shown but not a destination"
switch. `MinespacePlanetSkyRegistry` registers all 81 as `Planet`s in six per-layer `SolarSystem`s, each
with its dimension id, tier from the catalog's stage and a shared placeholder icon (a body without an
icon is where a map render *crashes*, not where it looks plain); `autoRegisterDimension` is false so
Galacticraft does not re-register the ids 6dm already owns, and every body is wrapped in its own
try/catch because the map is client-side and cannot be checked here. Verified: `registered 81 of 81
planned bodies as unreachable (0 failed); 6 systems created`, baseline intact. **How it looks is an
in-game check** - recorded as one.
Then **6dp**, fixing what 6do got wrong: the bodies are grouped by the **star system they actually sit
in**, not by layer (the catalog's `Star` column has had that all along). **74 systems instead of 6** -
30 real host stars, each holding its own planets together (TRAPPIST-1's seven in one system), plus the
44 bodies that orbit nothing (stars, black holes, galaxies, quasars), each standing as a system of its
own. Systems are placed by a deterministic formula so the map has a shape rather than a pile. Verified:
`registered 81 of 81 planned bodies as unreachable (0 failed); 74 systems created`, baseline intact.
Then **6dq**: the first in-game look at the map was a **client crash** (white screen) caused by 6dp -
`SolarSystem`'s galaxy argument is not a label but a **texture path**
(`assets/asmodeuscore/textures/gui/galaxy/galaxy.<name>.png`), and "MilkyWay" has no such file, so the
map got a null texture and died with `NullPointerException: Rendering screen`. Listing the textures that
exist gave the answer in one command: AsmodeusCore ships exactly `galaxy.milky_way.png` and
`galaxy.andromeda.png` - so the identifier is **`milky_way`**, and **only two galaxies exist in this
stack** (which closes the "one galaxy per layer" idea: seven layers would need seven textures nobody has
drawn). Fixed, rebuilt, re-verified on the server (`81 of 81 ... 74 systems created`, 126 definitions,
`Done (1.991s)`, 19 exceptions).
Then **6dr**, and this is where it stopped: the **second** in-game attempt crashed too, in
`asmodeuscore...NewGuiCelestialSelection.drawCircles` → `getScale`, because that code draws **each
system's main star** and **each body's orbit** and the registration set neither (`setMainStar`,
`setRelativeDistanceFromCenter`). Same mistake as 6dq in a new costume: a value that looks like a name is
a texture path; a field that looks like decoration is dereferenced. Both are only discoverable in a
client, and this pack is verified on a dedicated server, so every wrong guess costs one of the owner's
client restarts - **which is why the owner chose to shelve it and write their own star map, per the plan
document, instead of letting us keep guessing.** State: `MinespacePlanetSkyRegistry` is **disabled** (the
call is commented out in `Minespace.java` with the full reason), verified by zero `Star map` log lines;
dimension registration and all 126 vein files are untouched. **6dr also carries the specification for the
owner's own map** - the plan assigns it to the pack (4.3 航道由研究数据解锁, M2 星图金标, M8 门网络图鉴,
M10 宇宙之网, 5.6 Forge GUI), the data it needs already exists and is generated from the catalog
(`planet-catalog.psd1` / `MinespacePlanetDimensions.java` / `planet-veins.psd1` / the closure ladder /
the `Ruin` column), and the four things only the owner can decide are listed there: the unlock gate,
whether locked bodies are shown, 2D vs 3D, and whether PlanetProgression's telescope is the entry point.

Then **6ds**, the crash that was not this build: after the owner's "还是崩溃了", the newest thing in the jar
(the 81 registered dimensions) was switched off - and then the evidence was read, and there was none. No
crash report newer than the already-fixed AE2 one, no `hs_err` younger than 2026-10-12, no Windows
application error for any `java` process, no low-memory event, and a `latest.log` that simply stops at
`Sending event FMLInitializationEvent to mod galacticraftcore`. Galacticraft cannot exit the game itself
(`javap -c` over the jar: no `System.exit`, no `Runtime.halt`), and the *same* jar then loaded fine twice -
one of those runs is the one the owner played in, the other a fresh client from a copied instance. So the
registration went back on (6dt), and the round's real lesson is that a killed client leaves nothing in the
game's own logs: the useful question is "was it killed", not "which change was it".

Then **6dt**, the star map's first real look, which is four bugs. Stars were quarter discs (the UV scale of
`drawModalRectWithCustomSizedTexture` is the drawn size over the texture size, and the code passed the
sprite's real 64 while drawing it 30 wide). The backdrop was the star sprite blown up to the screen; it is
now a real NASA nebula photograph (*Cosmic Cliffs*, public domain), cropped, blurred and crushed by
`tools\build-starmap-art.ps1`, which also generates the glow sprite. 520 dust stars hashed from `"du" + i`
came out as a diagonal line across the sky (a counter needs a mixer, not a string hash). And the orbit rings
were drawn zero times because a local `float height` shadowed `GuiScreen.height`, so the bounds check threw
every dot away - "the rings are too faint" and "the rings were never drawn" look identical from outside.
The round also adds labels beside the stars, the **你在这里 · Sol** marker, scaling against the screen's
width instead of its height, and a legend that no longer shows `LuV^ZPM`. The instrument that found all four
is new and belongs to this project now: `-Dminespace.starmap.capture=<dir>` makes the screen open itself at
the main menu, read its own framebuffer back with `glReadPixels`, write both levels as PNGs and quit - two
and a half minutes, no client restart asked of the owner, and run from a copied game directory
(`D:\minespace-capture-run`) with no `saves`, so the owner's world is never touched.

Then **6du**, where the map got its shape and its motion. The owner's note was *"感觉不是大空间布局，看起来还是
一个大甜甜圈布局"*, and it was right: 6dp put every system at its layer's radius and spread the layer around
that circle, so every system lay in one plane - and a plane in a frame twice as wide as it is tall is a
doughnut. The layout is now a **Fibonacci sphere** (uniform, never lined up), the layers only choosing the
shell, the whole cloud stretched into an **ellipsoid**, and the projection kept at one scale for both axes: a
widescreen frame is filled by changing the *shape of the thing*, not by squashing the drawing of it - the
first attempt here did the latter and produced a flat band. Everything moves now: the camera eases toward a
target (`1 - exp(-dt * 14)`, wall-clock deltas, clamped), a flick keeps turning after release, zoom is a
target too, the level change is a **cross-fade** of both layers with the switch hidden at the midpoint and a
42% dip over the moment they are both half-visible, the screen fades up from black, stars twinkle, and the
hover ring pulses. Input is refused mid-change, because the positions on screen then belong to a layer that is
leaving. The capture harness is now four poses - overview, overview turned, **the middle of the transition**,
and the system - and it paid for itself immediately: the first capture of the animated build was the backdrop
with *no stars at all*, because `transition` means "progress through a change" and the overview's alpha had
been written as `1 - eased`, which is 0 when nothing is changing. Nothing threw and nothing logged; only the
picture said so. Labels also gained nearest-first overlap rejection (seven bodies within a hundred pixels is a
pile of names otherwise), and the transition pose is caught by fade progress rather than by a frame count so
it is the same picture at 20 fps and 60.

Then **6dv**, where the information card moved to the cursor. The owner asked for the selection card to sit
near the star or system it describes and follow the mouse, and that is right for a screen whose entire content
is positions: the fixed bottom-right card made the eye travel 400 pixels and back. The card is now a tooltip
offset from the cursor, **flipped** at the right and bottom edges and clamped when neither side fits; when the
cursor is not on the map it **anchors to the selection** instead, so a clicked star keeps its card. It also
carries more per line - the layer *with its colour and voltage band* (`3 中距 (LuV-ZPM)`), stage, landable or
observation-only, host star, vein count, and for a system the number of bodies and what the next click does -
and the selection is drawn as **corner brackets** rather than a closed box, because a box around a star competes
with the star. The duplicate bottom-left line went with it. The capture harness gained a **fake cursor** for
this: a capture run has no mouse, so the harness parks the pointer on the rightmost system for one pose, which
is the case that has to flip - without it the placement would never have been photographed.

Then **6dw**, where the map learned to fill the frame and to be moved. A constant scale was the wrong shape of
answer to "默认情况下星系遍布整个屏幕": a cloud fitted at one angle is not fitted at another. `fitScale` now
measures, every frame, how far the layer's nodes reach once rotated by the camera that is about to draw them,
and sets the scale so that reach meets the frame - as a **92nd percentile rather than a maximum**, so one
outlier system cannot shrink everything else, eased between frames so turning does not make the map jump, and
kept **per layer** (77 systems and one system's 7 bodies do not fit at the same size, and the cross-fade draws
both at once). Panning arrived with it: **right or middle drag** moves the map one pixel per pixel at any zoom,
**WASD/arrows** do it without a mouse, **R** resets the view, and a right *click* still means "back out" - the
decision is made on release, so a button that never moved is a click and not a pan. The pan is clamped with a
reach that grows with the zoom, because at three times zoom an outer system has to be bringable to the middle.
Verified by the four captures: the cloud reaches all four edges at the default angle *and* at a turned one.

Then **6dx**, where the map became a chart you travel. The owner pointed at a zoomed-in view of it and said
*"这样的布局才对"*, and then gave both the journey and the rule: zoom and pan until the layer-7 **unknown**
systems come into view, and *"在主视图去掉旋转查看，旋转查看只在星系详细查看"*. So the **overview no longer
rotates** - the angle is fixed and a drag moves the map - while rotation stays in a system's own view, where it
is the only way to see what orbits what. The click/drag decision moved to release, because a pan has to be
startable anywhere on the chart, including on top of a star. The layers are now laid out **geometrically
outward** (`0.60 * 1.42^(layer-2)`; layer 7 is 6.3× further out than layer 2), and the fit-percentile became the
design: the overview is fitted to its **35th** percentile so the far half is genuinely off screen and has to be
travelled to, while a system's bodies are fitted to their 92nd, because a system is one glance. Zoom runs
0.5..3.5. Every star on screen is labelled in both views (the owner's reference is a chart with names), the
overlap rejection from 6du keeps it readable, home is named once by its own marker, and the title/legend/hint
got small dark backings because a chart that names everything will always put a name under the legend. The
capture harness grew to five poses - overview, overview pulled back, mid-transition, system, system **turned** -
the last two pinning down where rotation is allowed.

Then **6dy**, where the wheel became a camera. *"3D 放大是穿梭查看，不是上下移动看，是由远到近的过程；平移只是查看
当前平面的星系"* - the zoom was scaling the drawing, which is a picture growing; what was asked for is the camera
moving, where near stars sweep past the edge and a star that goes past the eye disappears. The projection is a
**perspective** now: a focal length (measured by `fitScale` as the 35th percentile of `r / depth`, so the same
"near third fills the frame" rule is measured through the projection that draws it), a camera distance from the
wheel as `reference * exp(-zoom + 1)` (a fixed *ratio* per notch - a fixed minimum was the first version and it
silently made the last half of the wheel dead), and a near plane that scales with the map, past which a point
comes back as NaN and is skipped. Two things had to change for the flight to arrive somewhere: the layout now
**fills its volume** (radii were on shells, so the middle was empty and flying in produced an empty frame -
photographed twice), and the dolly is bounded at 0.45..2.2 times the reference distance, a factor of 4.9 in
distance, because deeper than that seventy-seven systems no longer fill a frame. Panning is unchanged: it moves
the view across the current plane, one pixel per pixel, at any distance.

Then **6dz**: the chart got its order, its centre, and the distinction between a system and an object. Layers own
**non-overlapping annuli** now (home 0, layer 2 at 0.55 units, each band 1.7x further, uniform in area inside a
band), and **home sits at the origin** - the owner asked for the solar system's arrangement in particular, and every
distance on the chart is measured from it. The 44 nodes that are **not** star systems (stars, black holes,
galaxies, quasars, pulsars, the CMB) were being drawn as small grey balls that read as unfinished systems; they get
a pale core with a thin ring, a card that says 单一天体 · 非恒星系, and their own count in the header
(`33 个恒星系 · 44 个单一天体（104 个天体）`). **The GC/GS audit in 6dz is the open item**: reading the ids out of
`GSConfigDimensions.class` and `ConfigManagerCore.class` shows **Venus missing from the star map** (its catalog row
is `-31;-1006`, two ids, and the table generator only accepts a single number) and **Jupiter (-1026) missing from
the catalog entirely**. Fixing them is a data round: a Jupiter row with its geology card, a generator that accepts
two ids, then the vein table and audits re-run.

Then **6ea** and **6eb**, the solar system done properly, both driven by the owner looking at it and asking
*"你觉得这个太阳系对吗"* and then *"海王星天王星没有，该有的卫星没有体现出绕着谁旋转"*. 6ea gave every solar-system body a
**real orbital distance** (`OrbitAu` in `tools\planet-catalog.csv`: Mercury 0.387 ... Kuiper belt 44.0, a moon
carrying its planet's distance plus a small offset), fixed the generator to accept a row with **two** dimension ids
(Venus is Galacticraft's `-31` *and* Galaxy Space's `-1006`, and the old "one number only" filter had been silently
dropping Venus since the table was first generated), added Jupiter as a non-landable gas giant, and made the screen
sort by that distance with a **logarithmic** ring radius. 6eb found the rest: **Earth, Saturn, Uranus and Neptune had
no rows at all** (Earth is dimension 0 - the Overworld itself; the other three have no dimension in any mod, so they
carry placeholder ids `-1996..-1998` in the band our registration skips by construction, and are non-landable), and
**moons now orbit their planets on screen**: a `Parent` column, distances re-cut so a planet sorts before its moons,
moons placed on a 0.075-unit halo around their planet with a dotted halo drawn for the planet, no solar ring for a
moon, and a card that reads `卫星 · 绕 木星` / `距恒星 0.723 AU` / `不可登录 · 无矿脉（气态/冰质）`. Verified by capture
with the harness pointed at Sol: `Sol  24 个天体`, Venus back with its distance, the Galileans together on Jupiter's
halo. Open: belts are still single points, and the four new planets have no stage plan of their own.

Then **6ec**: *"信息板上要写清楚距离地球多远"*. The catalog had a distance for 97 of its 111 rows but as curated text
(`4.24 ly`, `~13.2 billion ly`, `384,400 km`), so a **`DistanceLy`** column now holds the parsed light-year value and
the card prints it in the unit the size deserves - `距地球 384,400 公里` for the Moon, `距地球 0.28 AU` for Venus (plus
`距恒星 0.723 AU`, the ring it sits on), `距地球 4.2 光年` for Proxima b, `1.0 千光年` for Vela Pulsar, `2.5 百万光年`
for Andromeda and `13.0 十亿光年` for GRB 090423. Inside the solar system the figure is the radial distance from Earth's
orbit; outside it is the star's real distance. Also found and fixed on the way: 6eb had created a **duplicate Earth**
- the catalog already had a curated row (no ids, a note saying the Overworld's veins belong to GregTech's own tables),
so the duplicate was removed and the original given the ids and the distance. Verified by capture: Venus's card now
reads `1 太阳系 (IV) · stage 0` / `距恒星 0.723 AU` / `距地球 0.28 AU`, and the map's header counts
`33 个恒星系 · 44 个单一天体（110 个天体）`.

Then **6ed**: every kind of body drawn as itself. The catalog's `Type` column (Planet, Moon, BlackHole, Galaxy, Nebula,
Pulsar, Quasar, Cluster, ...) had never been passed to the game; it is now, and the screen draws a galaxy as a wide
faint disc, a black hole as a *dark* disc inside a bright ring, a pulsar as a pulsing point, a nebula as a cloud, a
star as a glowing ball, a quasar as a bright core with a large halo. The centre of a lone object's view is now that
object instead of a grey fake star. `Period` (text, 54 of 110 rows) became `PeriodDays` (a number, the solar system
filled in) and bodies turn by `clock / (period x tempo)`, with `[` `]` stepping the tempo - and that round found its own
bug: the four planets added in 6eb had been cloned from Mars's row, so **Saturn, Uranus and Neptune all carried
Jupiter's 11.86 years**. Then **6ee**, which is the tension the owner hit twice (*"这也太快了"*, then *"比例还是太快了"*):
a real solar system cannot be shown in one tempo (Mercury 88 d, Neptune 60,182 d, TRAPPIST-1 1.5-18.8 d). The tempo
is now **per system** (the fastest planet gets 30 seconds an orbit, moons excluded, everything else keeps its true
ratio), and **`P` switches between real ratios and compressed ones** (the 0.35th power of the period ratio: the order
stays real, Neptune's 684x becomes about 8x). The card always prints the true period. Measured: TRAPPIST-1 real
30/48/80/121/183/245/373 s per orbit, Sol real Mercury 30 s ... Neptune 5.7 h.

Then **6ef**, closing the three items 6ed left open. The black hole's ring was invisible in practice (one-pixel dots
lost in the nebula), so the disc is now drawn as light - two additive glow stretches in warm gold with the dark sprite
on top, photographed at 1920x1000 as a golden ellipse with a black centre. The asteroid and Kuiper belts are no longer
single dots: `AsteroidBelt` bodies draw five dotted rings from -6% to +6% of their distance and keep a small pale dust
knot as their clickable marker, with the card saying `距恒星 2.70 AU（带状）`. And Earth/Saturn/Uranus/Neptune got their
plan written into the catalog rather than implied: all four at `Stage 0-3` / `蒸汽~EV`, Earth as the home world (its
veins are GregTech's own tables) and the other three as **frame bodies** - non-landable, no veins, each the parent of
the moons that carry that band's content (Jupiter's four Galileans carry `desh` and the rest of the 0-3 materials).
`accept-planet-veins.ps1` re-run green on all six criteria; the deployed jar matches the build.

Then **6eg**: the owner opened the Crab Pulsar and asked why a lone object's detail view selected a copy out on a ring
instead of the thing in the middle. It was drawing such a body **twice** - once at the centre as its own form (6ed) and
once as a selectable node on an "orbit" - so `position()` now returns the origin for any body with no host star: the
object *is* the middle of its view, the centre form is the only mark, and the label, hover ring and selection brackets
all land there. The card stopped telling a single object it had `无宿主恒星` and `矿脉待配置` (now
`单一天体 · 非恒星系 · 仅观测`), and `fitScale` gained a guard for a system whose every node is at the origin (it would
have divided by zero). Photographed with `-Dminespace.starmap.capture.system=Crab`: one pulsar, in the middle.

Then **6eh**, the first slice of §6dn: **TRAPPIST-1 e (-2103) is a world now, not a placeholder.** §6dn's wall was
that GregTech generates ore by replacing a world's stone and a void dimension has none, so the chain is **terrain,
then a stone type, then veins** - and this round built the first two for one body. `MinespacePlanetTerrainPrototype`
gives it its own provider (chosen per body in the registration loop, the other eighty keep the void), a chunk
generator that builds bedrock + rock to a noisy surface height (62 ± a swell of three sines) + air, and a GregTech
`StoneType` (id 64, clear of GT's 0..15 and Galaxy Space's) registered from `Materials.onMaterialsInit()`. The rock is
plain `minecraft:stone` on purpose: the pipeline is what is being proven, and the art pass plus this body's vein files
are the next rounds. Verified by a temporary probe on the dedicated server, then deleted and rebuilt:
`PROBE terrain prototype: dimension -2103 chunk(0,0) y0=minecraft:bedrock y64=minecraft:stone y200=minecraft:air
stoneTypeRecognised=true` - and `stoneTypeRecognised=true` is the one that matters, because it means a vein filtered
to `-2103` will generate there.

Then **6ei**, the third link of the same chain: TRAPPIST-1 e is **mineable**. The vein table had carried its card since
it was written (`Signature = 'dyson_wreck'`, `Pending = $true`, and a region note saying the signature carries the
ruin-delivered ore for exactly this body); `Pending` meant "no such dimension exists in the game yet". It exists now,
so `Pending = $false` was the whole change, and the generator produced **7 veins** - the five body-agnostic frontier
ones, `Heavy_Refractory_Vein`, and the signature `Dyson_Wreck_Vein` (trinium / triniite / bowieite) - inside the plan's
5..8. Five of the seven files already existed for other bodies (a GT vein file carries a *list* of dimension ids), so
the generator added `-2103` to those lists and wrote only two new files. Verified end to end on the dedicated server:
`Loaded 254 worldgen definitions` (was 126), `Done (1.953s)`, 19 exceptions, and `accept-planet-veins.ps1` green on
all six criteria with `dimension -2103` carrying its 7 veins. Not yet true: a player cannot *reach* it (no route, no
research gate - the owner's call), and its rock is still plain stone until the art pass. The other eighty bodies need
the same three steps.

Then **6ej**, the owner's two decisions: **the pack's own star map is the map** (nothing is registered into
Galacticraft's celestial registry, which is also why 6dq/6dr's crashes stop mattering), and **the tiers are the layers,
opened by research data**. Six tiers, six pieces of data: tier I opens layer 2 (近邻, IV), II layer 3 (中距, LuV~ZPM),
III layer 4 (远距, UV), IV layer 5 (深空, UHV), V layer 6 (超深空), VI layer 7 (未知). No new taxonomy was invented -
the legend, the layer colours, the card and the data all name the same seven bands, and a body's tier is `layer - 1`.
Built: one item with six metadata values (`MinespaceResearchData`, `minespace:research_data`), whose icons and models
are **generated** by `tools\build-research-art.ps1`; the gate drawn on the map (locked systems are dim grey balls with
grey names, the card says `等级 VI · 未解锁（需 研究数据 VI）`, a click is refused with a hint, and locked bodies are
shown rather than hidden - reversed in 6ep, where the owner ruled that an unsurveyed body is not on the chart at all);
and a crafting chain in `scripts\research_data.zs` (tier N = previous data + that tier's
circuit + plate) which is explicitly a **placeholder for observing** - when the survey step exists, only the recipe
changes. Verified: `crafttweaker.log` zero errors (so every ore dictionary and the item id resolve),
`254 worldgen definitions`, `Done (1.985s)`, 19 exceptions, and a captured locked overview.

Then **6ek**, the owner's choice of how to reach our own bodies: **adapt Galacticraft's rocket** rather than build a
lane mechanism, with the note that anything outside GC/GS we will build ourselves later. The adapter is small because
GC's rocket already knows how to fly: `EntityAutoRocket.targetDimension` is a public field and GC's launch sequence
reads it. `MinespaceRocketTarget` therefore checks four things and then only *aims* - destination must be a catalog
body, the player must be riding a rocket, the layer's **research data** must be held and the rocket tier high enough
(layer halved, rounded up, capped at GC's four), and it does **not** ignite, because pressing GC's own launch is what
"keep GC's launch flow" means. `MinespaceNetwork` is the mod's first packet (one int: the dimension id) with every
check re-run server-side. On the map, `T` in a body's view requests it and the card says
`按 T 设为火箭目的地（需 T2 火箭 + 燃料）`. Verified: the build and a server run with GC present (`254 worldgen
definitions`, `Done (1.983s)`, 19 exceptions, no NoClassDefFound, channel registered). Not verified: the flight itself,
which needs the owner in a fuelled rocket.

Then **6el**, the owner's question - *"这个星球研究为什么不会跟行星研究一起解锁？"* - which found the round's real mistake: the
research data was built as a self-contained system without asking what already existed. **PlanetProgression stores its
unlock state per Galacticraft `CelestialBody`** (`ResearchHooksMP/SP.hasUnlockedCelestialBody(player, body)`), and our
81 bodies are deliberately not in Galacticraft's celestial registry (6ej), so the two gates had no shared key. The
bridge is `GalaxyRegistry.getCelestialBodyFromDimensionID(int)`: **a body Galacticraft knows is gated by
PlanetProgression's telescope research** (survey the Moon there, the map shows it unlocked here - one progression, not
two), **a body only we know is gated by our survey data**, and the card says which of the two is talking. The server's
rocket check asks the same question through the MP hook. PlanetProgression joined the build as a **compileOnly**
dependency on the instance's jar, with every call behind a mod-presence check so the addon loads without it. Verified:
build + server run (`Loaded 254 worldgen definitions`, `Done (2.279s)`, **0 NoClassDefFoundError**, 19 exceptions).
Not yet seen in game: the card's new lines and the actual hand-off, which need the owner's client.

Then **6em**, two reports from the owner's client and what each actually was. (1) *"发射后还是正常打开的是 GS 的星图"*:
Galacticraft's launch button **is a destination chooser** - pressing it opens the celestial screen and the player's pick
overwrites whatever was preset - so the adapter now **ignites the rocket itself** (`igniteWithResult()`) after setting
the destination; GC's ascent, atmosphere, transfer and landing are untouched. (2) *"星图连太阳系都没解锁"*: the diagnostic
for this round showed the lookup and PlanetProgression's state were both fine (`moon.moon surveyed true`, `planet.mars
surveyed true`, ...), so the fault was the **rule**: a system node is one body of that system, and the whole system was
being gated on that one body - the solar system's representative is Neptune (a map-only id, so Galacticraft has no body
for it), which pushed it onto our tier gate. The owner's screenshot shows it: Sol's card read `等级 I · 未解锁（需 研究
数据 I）` beside `距地球 30.069 AU`, which is Neptune's figure. The rule is now **a system is open when any of its
bodies is**, confirmed per system in the log: `Sol -> known to GC 19, surveyed by PP 19`, plus Proxima/Tau Ceti/Barnard's
all fully surveyed. Also chased down and dismissed: the chat's `for: Minespace` is PlanetProgression's unlock command
naming its **player** argument (the launcher runs as the offline user `Minespace`), not a mod attribution.

Then **6en**, the third report of the same launch (*"发射升空之后还是弹出 gs 的星图"*), and this time the cause was in
Galacticraft's own bytecode: `EntityTieredRocket.onReachAtmosphere()` opens the celestial screen when
`destinationFrequency == -1`, and **a frequency is a landing pad** - GC's routes are pad to pad, so a body we own (no
pad, not in GC's registry) can never satisfy it. Presetting `targetDimension` was therefore overwritten every time. The
pack now takes over exactly the step with no GC equivalent: `MinespaceRocketDestinations` remembers the destination
weakly on the rocket and `MixinEntityTieredRocket` injects at the head of `onReachAtmosphere` - if the rocket was aimed
from the star map, GC's behaviour is cancelled and **the player is moved to the planet**. Everything before that moment
is still GC's (fuel, ignition, ascent, sounds, phases). Deliberate limit, stated in chat and in the docs: **the rocket
stays behind**, because moving it would mean reimplementing GC's ship transfer (pad lookup, landing, cargo) and a
half-transferred ship is a bug report. Verified: build + dedicated-server run with the mixin applied (`Done (2.325s)`,
**0 mixin errors**, 19 exceptions); the flight itself still needs the owner.

Then **6eo**, where the owner replaced 6en's design with a better one in a sentence: *"我想的还是按照 gc 那样的逻辑，升天
之后弹我们自己星图然后选择"*. Galacticraft's flow is launch → fly → **choose the destination at the atmosphere** (the
`destinationFrequency == -1` branch from 6en), so what gets replaced is exactly that screen, not the launch and not the
aiming. Now: the player launches the ordinary GC way; at the atmosphere the mixin cancels GC's celestial screen and
sends `OpenStarMapMessage`, which opens **our star map in choice mode** (`按 T 前往此处`, hint `已进入轨道：选一颗可登陆星球
按 T 前往`); picking sends the target with `inFlight = true` and the server - after re-checking the research gate - moves
the player to the planet. Ground aiming still skips the question. The in-flight path skips the rocket-tier/fuel checks
(that rocket is already airborne) and keeps the data gate, and all of it is re-validated server-side. Verified: build +
server run (`Done (1.944s)`, **0 mixin errors**, 19 exceptions). Not verified: the flight (the owner's half). Two stated
limits: the rocket stays where it launched, and every planet but TRAPPIST-1 e is still void - hence the next round.

Then **6ep**, the three reports that followed it. The map *"一只闪烁"* because the mixin's atmosphere hook runs every tick
and sent `OpenStarMapMessage` on each one; `firstAsk` sends it once. `T` *"没反应"* for everything but Earth because a
refused pick was refused silently - every refusal now prints its reason under the map (`refuse`/`whyNot`). And the map
itself became the progression: *"同样的没解锁的天体，星系是不可找到的，只有解锁了才可以"*. So a locked node is projected to
NaN - the same value the projection already gives a point behind the camera - and the spheres, labels, orbit rings,
hover test, picking, card and **frame fit** all skip it without knowing why ("hidden" is one decision, not a second list
to keep in step). `fitScale` now measures only charted nodes, so the fourteen systems a player has earned fill the frame
instead of huddling in the middle of a screen reserved for the other sixty-three; a planet's halo is drawn only for its
charted moons; the title reads `已测绘 14 / 77 个星系 · 40 / 110 个天体`, a system header `已测绘 2 / 7 个天体`; and the legend
gained a caption and greys the tiers that are still shut, because a map that hides its contents owes the player the
answer to "what opens it". The one exception is the world the map is read from (a body whose dimension is the player's),
on both sides - otherwise a first-day player opens the screen on an empty black field, where "nothing unlocked yet" and
"this screen is broken" look identical. Verified by three capture runs of the map's own camera, which is a new script
now (`tools\capture-starmap.ps1`, with `-Tier 6/1/-1` and `guiScale` 2 at 1920x1000) rather than a hand-assembled java
command: `77 of 77 systems charted` and the picture unchanged, `14 of 77` with the legend greying from `3 中距` up, and
`0 of 77` - nebula, dust and legend, no star to click. `tools\run-server.ps1` does the same for the boot check
(Play-Minespace.ps1's `-Server` path aimed at a scratch directory), and it is green on the baseline: `Done (1.917s)`,
254 worldgen definitions, 47 mods, 19 exceptions, 0 errors. 6em's probe is deleted; the map logs its own gate line once
per open instead. Not verified, and it is the owner's half: a real launch, and the in-orbit chooser against a
partially-charted map.

Then **6eq**, the report that hiding was right and the gate underneath it was wrong: *"你这么搞了之后我全部解锁之后，gs原本木星，
土星等这些都没有了"*. A temporary probe (one server start, deleted again) printed the two facts that explain it: **23 of the
110 catalog rows are bodies Galacticraft knows**, and Galaxy Space registers Jupiter, Saturn, Uranus and Neptune as
planets of the sun's system **with no dimension at all** (`jupiter -> planet.jupiter dim -1`). A body GC owns is gated by
PlanetProgression; a body it does not own falls to this pack's own research data (6el) - so the four giants, whose
dimension ids this pack had to invent (-1026, -1996, -1997, -1998, which is why `getCelestialBodyFromDimensionID`
answers null for them), needed research data I while the moons orbiting them needed the telescope. One system, two
progressions - the exact shape 6el exists to remove - and Deimos is the same case (GS's Deimos has no dimension,
ours is -1013). The rule is now one progression per system: a row in the sun's own system follows PlanetProgression and
is charted when that research has surveyed **any** of the system's Galacticraft-owned bodies, asked through one
predicate (`gateIsPlanetProgression` + `systemSurveyedOnClient/OnServer`) that the card, the `T` refusal and
`MinespaceRocketTarget` all share, with the client caching the answer per frame - layer 2 outward is untouched, still
this pack's own research data. Verified by capture with the camera standing in for the owner's exact state
(everything surveyed in PlanetProgression, no research data): `research data 0 of 6, 4 of 77 systems charted, 28 of
110 bodies charted` and `Sol 已测绘 24 / 24 个天体` - Jupiter, Saturn, Uranus, Neptune and Deimos back with their moons'
haloes, four systems and no exoplanet; `6 of 6` still photographs the whole chart (77/77, 110/110) and `-1` still an
empty one. Not done, and named in the plan: the eleven dimension-less GS moons (Mimas, Dione, Tethys, Rhea, Iapetus,
Ariel, Umbriel, Titania, Oberon, Proteus, Charon) are not in the catalog, so they are not drawn.

Then **6er**, the owner's next rule: *"关于我们自己的其他 gc gs 以外的天体也应当注册到行星研究的研究进程，要解锁全部解锁"*. Measured
in PlanetProgression's bytecode first, because the whole design hangs on it: its research is a
`List<CelestialBody>.contains`, `unlockAllCelestialBodies` walks `getRegisteredPlanets()` + `getRegisteredMoons()`, the
telescope matches a paper's body name against a registered body, and `initResearchPaperItems` **creates one paper per
registered body** in the item registry event - which runs after every mod's preInit, so a body registered from this
pack's preInit gets its paper for free. `MinespaceCelestialRegistry` therefore registers the 81 rows this pack plans
(everything Galacticraft and Galaxy Space do not already own) into Galacticraft's celestial registry through
AsmodeusCore's `BodiesRegistry` - the helper Galaxy Space itself uses - with a generated icon by kind (21 PNGs from
`tools\build-celestial-art.ps1`), generated names (`tools\build-celestial-lang.ps1`, reading the *Java* table rather than
the CSV behind it, because the CSV leaves the solar system's star column empty) and, after a first attempt that was
wrong twice, **the real dimension id**: without it eighty-one bodies answered `getDimensionID() == 0`, the overworld.
Ownership is decided by the dimension band (-2000 and below is this pack's), not by "does a body exist for this
dimension yet" - Galaxy Space registers part of its own catalog *after* this pack's preInit, so twenty rows looked like
ours and this pack's Miranda would have displaced Galaxy Space's own Miranda in a registry that keeps one body per name.
Twenty-nine rows turned out to be bodies GC/GS already has and are adopted instead of re-registered (twenty-three of them
findable only by name, since Galaxy Space registers Jupiter, Saturn, Uranus, Neptune, Deimos and Barnarda C2 with
`dim -1`). The gate is now: a body this pack registered has **two roads** - PlanetProgression's research of it, or this
pack's own survey data for its layer - while a body of theirs has only theirs (6el) and the sun's own rows keep 6eq's
system rule; the star map's legend stopped reading the player's inventory and now marks the layers that have anything
charted in them. Verified on the dedicated server with a probe (deleted after): `registered 81 planets and 0 moons in 73
new systems (... 23 of them found by name, 0 failed)`, 110 of 110 rows resolved, 0 missing language keys, 0 dropped, 0
duplicated dimensions, `0 -> planet.overworld`, `-2103 -> planet.trappist_1_e`, and **PlanetProgression now has 119
research papers, 109 of them for this pack's bodies** (the one without is Galaxy Space's own dimension-less
`moon.deimos`, which `unlockAllCelestialBodies` still covers). Star map captures: everything surveyed gives
`77 of 77 systems charted, 110 of 110 bodies charted` with the card reading `已解锁 · 行星研究（望远镜）`; survey data alone
(`-PlanetProgression $false`) gives 13 systems and 17 bodies with the legend bright on `2 近邻`. Clean boot: `Loaded 254
worldgen definitions`, `Done (1.935s)`, 19 exceptions, 0 crafttweaker errors. Two things left for the owner:
PlanetProgression ships **no recipe producing a research paper** (its items exist; the telescope consumes one), so the
telescope road needs a recipe route of our own - and adding bodies renumbers `research_paper_<n>`, so a world holding
paper items sees Forge's one-time "missing items" list.

The owner then asked the stability question - *"没有使用不稳定的方式做这个功能吧"* - and it deserved an answer in
measurements rather than reassurance. What the round is built on: AsmodeusCore's `BodiesRegistry` (Galaxy Space's own
helper), Galacticraft's public registry API, PlanetProgression's published hooks, registration in preInit, and **no
reflection, no bytecode patching, no field surgery, and no mixin added** (the pack still has exactly 6en's one, on
Galacticraft's atmosphere hook). What it is *coupled* to: two generated files (the language keys and the icons) and
other mods' dimensions - three couplings that fail silently, so they became a standing guard run on every boot
(`MinespaceCelestialRegistry.verify`, at loadComplete and again at server start). It reports, in one line each: 0
missing language keys, 0 missing icons, and how many landable bodies have no registered dimension. The two moments give
two different numbers, and the difference is the finding: at loadComplete it is 24 - *including the Moon and Mars*,
because Galacticraft and Galaxy Space register their own dimensions later - while at server start it is **2**:
`Deimos(-1013)` and `Barnard's Star d(-1032)`, the two landable rows this pack plans whose Galacticraft counterpart has
no dimension at all, so nobody registers their ids. That was live: the map offered Deimos, the gate allowed it, and the
arrival called `changeDimension` on a world that does not exist. Travel to a body without a world is now refused twice
with the reason in chat (`MinespaceRocketTarget.apply` before aiming, `MinespaceRocketDestinations.transfer` as the last
line before Minecraft's own transfer). Left open for the owner, one decision: let those two rows claim their ids as they
stand, or move them into this pack's own band when the terrain round regenerates their vein files.

## 7. Where to start next

The one workstream that is no longer waiting on a decision is the planet veins: 6cz gave it a spec
(*GTCEu 星系整合包详细实施方案*) and an acceptance script (`tools\accept-planet-veins.ps1`), and 6da did
the first two steps of the spec's own order - the vein-variant table plus generator, and the **Moon as
the gold standard** (7 veins, no duplicates); 6db finished the solar system, so **every countable
acceptance criterion the plan sets for stage one/two now passes** - 25 bodies at 5..8 veins, no
duplicates, no gaps. The workstream that continues from here is *design*, not mechanism: the
resource-closure table (plan 2.2, whose input is the 64-ore list the audit prints) and a balance pass
over the shares, which are still a first draft. After that, stage three is the first exoplanet end to
end - and the four nearby-system bodies currently carrying provisional cards are where it starts.

Content development. The foundation is clean: the stack boots, the guards are green, the top tiers are
reachable and priced, and the build takes eleven seconds. The natural first round is whatever content
the owner wants next - a new machine set, a new planet chain, or a chain audit (the "dead ingredient"
and "unobtainable" instruments from 6cc/6cm are templates) - done the way §2 describes.

