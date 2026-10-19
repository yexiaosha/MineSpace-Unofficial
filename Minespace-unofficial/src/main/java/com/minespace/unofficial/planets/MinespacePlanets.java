package com.minespace.unofficial.planets;

import com.minespace.unofficial.MinespaceModules;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.common.Mod.EventHandler;
import net.minecraftforge.fml.common.event.FMLPreInitializationEvent;

/**
 * Minespace Planets - the celestial body module.
 *
 * <h2>What belongs here</h2>
 *
 * <p>The data and the presentation of the pack's bodies, and nothing else: the body table itself (dimension id,
 * layer, star system, whether it can be landed on), the solar system's twenty and the deep field's eighty-six,
 * their geology cards and vein tables, the per-body rock and dimension rows, biomes, environmental hazards, gas
 * giant harvesting, the icons and the names - plus the six ruin tiers under {@code ruins/}.</p>
 *
 * <h2>The boundary, measured rather than assumed</h2>
 *
 * <p>The body table and the first body's terrain prototype were both meant to move here. They cannot, and the
 * reason is a window this project documented the hard way (see {@code MinespaceStoneTypes}): every GregTech stone
 * type this pack registers - the Moon's, Mars', Venus', the asteroid belt's, the seventeen Galaxy Space ones and
 * the terrain prototype's - has to be created between GregTech's {@code runMaterialHandlers()} and
 * {@code MetaBlocks.init()}, because afterwards GregTech has already baked its ore blocks and a missing stone type
 * is not a wrong texture but an NPE in every vein that meets that rock. That window is inside GregTech's preInit,
 * which this pack reaches during {@code minespace_core}'s own preInit ({@code MinespaceMaterials.onMaterialsInit}).</p>
 *
 * <p>The body table feeds those stone types, so it has to be readable <em>before</em> that moment - and FML loads
 * this module (which is {@code required-after:minespace_core}) after core has finished preInit. Putting the table
 * here would therefore mean either core depending on this module, or a stone type registered outside its only
 * viable window. So the table stays in core, next to the mechanisms that read it during that window, and this
 * module takes the content whose registration can happen <em>after every mod's preInit</em>: per-body terrain,
 * biomes, environmental hazards, veins and ruins - the work of stages two through six.</p>
 *
 * <p>Its data pipelines stay with the module either way: {@code tools/planet-catalog.psd1} with
 * {@code build-planet-catalog.ps1}, and {@code tools/planet-veins.psd1} with {@code build-planet-veins.ps1} /
 * {@code accept-planet-veins.ps1}.</p>
 *
 * <p>Shipped with no content of its own yet: the module exists so the four-mod layout is real and can be tested
 * (removing it leaves a working game - see the plan's disable test).</p>
 */
@Mod(
        modid = MinespacePlanets.MOD_ID,
        name = MinespacePlanets.MOD_NAME,
        version = MinespaceModules.VERSION,
        acceptedMinecraftVersions = "[1.12.2]",
        dependencies = "required-after:" + MinespaceModules.CORE
)
public class MinespacePlanets {

    public static final String MOD_ID = MinespaceModules.PLANETS;
    public static final String MOD_NAME = "Minespace Planets";

    @EventHandler
    public void preInit(FMLPreInitializationEvent event) {
        event.getModLog().info("{} {} starting up", MOD_NAME, MinespaceModules.VERSION);
    }
}
