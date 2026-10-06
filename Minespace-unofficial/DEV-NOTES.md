# Minespace Unofficial — addon development notes

Hard-won specifics about building a **GregTech CE: Unofficial + Galacticraft** addon on
Minecraft 1.12.2. Everything here was verified by running the game, not inferred.

---

## 1. GTCEu material registration: the exact contract

This is the single easiest thing to get wrong, and getting it wrong produces a hard
crash instead of a warning. GTCEu registers everything inside its own
`CoreModule.preInit`, in this order (read out of its bytecode):

```
1. post MaterialRegistryEvent     phase == PRE
       addons call createRegistry()      <-- ONLY legal while phase == PRE
2. unfreezeRegistries()           phase PRE -> OPEN
3. GTCEu registers its own materials
4. post MaterialEvent             phase == OPEN
       addons register materials         <-- ONLY legal while phase == OPEN
5. freezeRegistries()             phase -> FROZEN, items get generated
```

### Consequences

**Do not create your material registry in your own `preInit`.**
With `required-after:gregtech`, GTCEu's whole preInit — including step 5 — has already
finished by then. You get:

```
java.lang.IllegalStateException: Cannot create registries in phase FROZEN
```

**Do not register materials from `MaterialRegistryEvent`.** At that point the phase is
still `PRE` and nothing can be added. Use `MaterialEvent`.

The correct shape is two handlers (see `gtceu/MinespaceMaterials.java`):

```java
@SubscribeEvent
public static void onMaterialRegistry(MaterialRegistryEvent event) {   // phase PRE
    GregTechAPI.materialManager.createRegistry(NAMESPACE);
}

@SubscribeEvent
public static void onMaterial(MaterialEvent event) {                    // phase OPEN
    new Material.Builder(32000, new ResourceLocation(NAMESPACE, "desh_steel"))
            .ingot().fluid().color(0x4C5A63).iconSet(MaterialIconSet.METALLIC)
            .build();   // build() registers; do NOT also call register()
}
```

### Two more traps

**`build()` already registers.** Calling `registry.register(material)` afterwards fails
with a message that reads like a self-conflict:

```
Tried to reassign id 32000 to desh_steel (desh_steel),
but it is already assigned to desh_steel (desh_steel)!
```

**`materialManager.getMaterial(key)` needs the namespaced key.** Use
`"minespace:desh_steel"`, not `"desh_steel"`. The bare path returns `null` silently,
which looks identical to "the material never registered". `MinespaceMaterials.lookup`
normalises this.

### Material ids

`Material.Builder(int id, ResourceLocation name)`. The id must be unique across GTCEu
and every addon; **GTCEu keeps its own below 32000**, so start at 32000.

### What you get for free

Adding a flag like `.ingot()` or `.dust()` makes GTCEu generate the items, the ore
dictionary entries, and the processing recipes (macerator, compressor, smelting, …).
You never register those items yourself. Verified in the log: after registering two
materials, GTCEu emitted item registrations for `meta_ingot`, `meta_dust`, `meta_plate`,
`meta_gear`, `cable_*`, `fluid_pipe_*` under the `minespace` namespace, and the read-back
printed `GTCEu material check: desh_steel ingot -> minespace.material.desh_steel Ingot`.

---

## 2. Do not use `Minespace.log()` inside a material handler

Because GTCEu's preInit runs **before** this mod's preInit, `Minespace`'s logger field is
still `null` when your `MaterialEvent` handler runs. Using it throws a
`NullPointerException` that surfaces as a crash "from GregTech", which is very
misleading. Use an immediately-available log4j logger instead:

```java
private static final Logger LOG = LogManager.getLogger("minespace");
```

---

## 3. `runClient` does not work on this machine (known, unresolved)

`gradlew runClient` launches a ForgeGradle 3 *userdev* client. With GTCEu and/or
Galacticraft present in `run/mods`, it dies during mod loading:

```
net.minecraftforge.fml.common.LoaderExceptionModCrash: Caught exception from Forge Mod Loader (FML)
Caused by: java.lang.NullPointerException
    at net.minecraftforge.fml.common.network.NetworkRegistry.newChannel(NetworkRegistry.java:207)
```

### What was established

- The baseline userdev client with **no** mods in `run/mods` starts fine, so ForgeGradle
  itself is set up correctly.
- The crash needs real mods present. It reproduces with **Galacticraft + CodeChickenLib
  alone** (`-PskipMods=gregtech`), so GTCEu is not the sole cause.
- `NetworkRegistry.java:207` in the Forge 2859 sources is
  `channels.get(side).put(name, channel)`, so `channels.get(side)` is null: the
  `NetworkRegistry` instance has not been initialised when FML registers its own channel
  during `FMLContainer.modConstruction`.
- Two supporting problems were found and fixed along the way, and both are worth knowing:
  - **GTCEu's coremod transformer needs MCP mappings.** Without them it fails at launch
    with `ExceptionInInitializerError` → `File.<init>` NPE, because
    `ObfMapping$MCPRemapper` reads `net.minecraftforge.gradle.GradleStart.csvDir` and
    `.srg.notch-srg`. These are the old ForgeGradle 2.x GradleStart properties;
    ForgeGradle 3 dropped GradleStart. The `prepareMcpMappings` task extracts them and the
    `runs.client` block passes them as `jvmArg` (`property` does **not** work — that
    becomes a game argument, not `-D`).
  - **Coremods must be loaded from `run/mods`, not the launch classpath.** A bundled
    coremod on the classpath gets its transformer injected but its own mod id is never
    registered, so Galacticraft dies with `requires [micdoodlecore]`. That is why the
    target mods go through the `mods` configuration and `installMods`, not
    `implementation` + `fg.deobf`.

So the userdev crash is a *third*, deeper problem in the userdev/coremod interaction. It
is not caused by anything in this addon.

### The workaround used instead (recommended)

Test in the real runtime, which loads both mods without trouble:

```powershell
.\tools\gradle.ps1 deployToInstance     # builds and copies the jar into the instance
..\Minespace-unofficial-dev\Play-Minespace.bat
```

`deployToInstance` depends on `reobfJar`, so the jar it copies is properly reobfuscated
and representative of a release build.

---

## 4. Verifying an addon

```
gtceu/                      GTCEu: material registry + materials
galacticraft/               Galacticraft: registry helpers + EU <-> gJ energy bridge
Minespace.java              @Mod entry point and load order
```

Useful commands:

```powershell
.\tools\gradle.ps1 build                 # compile + reobfuscate
.\tools\gradle.ps1 deployToInstance      # build + copy into the instance
.\tools\gradle.ps1 installMods -PskipMods=gregtech   # bisect a load failure
```

After launching the instance, check:

```powershell
Select-String -Path ..\Minespace-unofficial-dev\logs\latest.log -Pattern '\[minespace\]'
```

Expected output:

```
[minespace]: Registered 2 GregTech materials in registry 'minespace': desh_steel, meteoric_iron
[minespace]: Minespace Unofficial 0.2.0 starting up
[minespace]: Target mods: GregTech CE: Unofficial=2.8.10-beta, CodeChicken Lib=3.2.3.358,
             Galacticraft=4.0.7, Galacticraft Planets=4.0.7
[minespace]: GTCEu material check: desh_steel ingot -> minespace.material.desh_steel Ingot
```

---

## 5. Adding another target mod

1. Get its CurseForge **project id** and **file id** from the file page URL.
2. Add `mods fg.deobf('curse.maven:<slug>-<projectId>:<fileId>')` to the `mods`
   configuration in `build.gradle`. `compileOnly.extendsFrom mods` already puts it on the
   compile classpath; `installMods` already copies it to `run/mods`.
3. Add `after:<modid>` (or `required-after:<modid>`) to `Minespace.DEPENDENCIES`.
4. Add the same jar to the playable instance's `mods/` folder, or re-run
   `tools\install-pack.ps1`.

## 6. Known gaps

- **A custom GTCEu machine** (a `MetaTileEntity`) is not included. The base classes and
  the registration call (`GregTechAPI.MTE_REGISTRY`) are identified, but a machine needs
  its own `ModularUI`; that is a larger piece of work than could be verified here.
- **Galacticraft `TileEntity` subclassing** is likewise not included, so the EU → gJ
  bridge in `MinespaceGalacticraft.GcEnergyBridge` is provided as an adapter to implement
  on your own tile entity rather than as a finished block.
- **Registering a new celestial body / dimension** is possible via
  `GalaxyRegistry.registerMoon` / `registerPlanet` and
  `CelestialBody.setDimensionInfo`, but needs a `WorldProvider` and a dimension
  registration to be useful, so it is left out rather than shipped half-working.
