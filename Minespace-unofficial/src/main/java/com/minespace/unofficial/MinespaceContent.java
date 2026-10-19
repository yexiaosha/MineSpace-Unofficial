package com.minespace.unofficial;

/**
 * The pack's content namespace, frozen at {@code "minespace"} forever.
 *
 * <h2>Why this is not the mod id</h2>
 *
 * <p>Since the module split this addon ships four Forge mods out of one jar (see {@link MinespaceModules}), and
 * the core module's own id is {@code minespace_core}. The <em>content</em> namespace is a different thing and
 * deliberately does not follow it. Registry names, block and item model paths, texture paths, translation keys,
 * the GregTech material namespace and the network channel were all written against {@code minespace} while there
 * was a single mod, and every one of those is either persisted in a save or baked into a generated resource file.
 * Renaming them would empty the corresponding blocks out of every existing world (a placed
 * {@code minespace:moon_rock} would come back as air) and break the model and lang files under
 * {@code assets/minespace/}.</p>
 *
 * <p>So the rule is one line long: <b>anything that names a game object keeps {@code "minespace"}; only a
 * {@code @Mod} id may carry a module name.</b></p>
 *
 * <h2>Who uses it (measured, not guessed)</h2>
 *
 * <p>The rock and research-data registry names and their {@code setUnlocalizedName} keys
 * ({@code MinespaceMoonRock}, {@code MinespacePlanetRocks}, {@code MinespaceGalaxySpaceRocks},
 * {@code MinespaceResearchData}); the GregTech stone type model paths ({@code MinespaceStoneTypes},
 * {@code MinespaceGalaxySpaceStones}, {@code MinespacePlanetTerrainPrototype}); the two
 * {@code MetaTileEntity} registry names ({@code MinespaceGregMachines} - these are persisted in the world, so a
 * rename would orphan every placed Oxygen Compressor and Rocket Fuel Loader);
 * {@code com.minespace.unofficial.gtceu.MinespaceMaterials#NAMESPACE}; the celestial body icon paths and the body
 * keys registered with Galacticraft and AsmodeusCore ({@code MinespaceCelestialRegistry}); and the network
 * channel name ({@code MinespaceNetwork}).</p>
 */
public final class MinespaceContent {

    /** The frozen content namespace. Do not change this value - see the class javadoc. */
    public static final String NAMESPACE = "minespace";

    private MinespaceContent() {
    }
}
