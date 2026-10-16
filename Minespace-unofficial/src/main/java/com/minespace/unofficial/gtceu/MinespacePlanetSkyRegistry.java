package com.minespace.unofficial.gtceu;

import micdoodle8.mods.galacticraft.api.galaxies.CelestialBody;
import micdoodle8.mods.galacticraft.api.galaxies.GalaxyRegistry;
import micdoodle8.mods.galacticraft.api.galaxies.Planet;
import micdoodle8.mods.galacticraft.api.galaxies.SolarSystem;
import micdoodle8.mods.galacticraft.api.vector.Vector3;
import net.minecraft.util.ResourceLocation;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * Puts the planned bodies on Galacticraft's star map, as bodies you cannot land on.
 *
 * <h2>Why this works at all</h2>
 *
 * The star map is Galacticraft's, not Galaxy Space's: {@code GSMapHandler} is only a render handler
 * hooked to {@code CelestialBodyRenderEvent}, which adds Galaxy Space's own flourishes (Haumea's ring)
 * to a map that draws whatever is in {@code GalaxyRegistry}. So this pack can be on that map without
 * touching another mod's jar and without writing a screen of its own.
 *
 * <h2>Unreachable is the whole point</h2>
 *
 * {@link CelestialBody#setUnreachable()} is what the owner asked for: the body appears on the map and is
 * not offered as a rocket destination. It is also what makes this honest - there is no terrain, no rock
 * block and no stone type behind any of these yet (6dn), so a body you could fly to would be a body you
 * could stand on nothing.
 *
 * <h2>What can and cannot be checked here</h2>
 *
 * The map is drawn on the client, and this pack is verified on a dedicated server. What a server run can
 * prove is that the registration happens, that every body is accepted, and that nothing throws; how it
 * looks is an in-game check, recorded as one.
 */
public final class MinespacePlanetSkyRegistry {

    private static final Logger LOG = LogManager.getLogger("minespace");

    private static boolean registered;

    private MinespacePlanetSkyRegistry() {
    }

    /** Called from this mod's preInit, on both sides - the map only exists on the client. */
    public static void register() {
        if (registered) {
            return;
        }
        registered = true;

        // Grouped by the star eached body orbits, which is what the catalog records: TRAPPIST-1's seven
        // planets share one system, the Gliese planets do not. A body that is not a planet - a star, a
        // black hole, a galaxy - orbits nothing, so it stands as a system of its own; that is the only
        // shape Galacticraft's model offers for it, and for a galaxy it is also the truthful one.
        java.util.Map<String, SolarSystem> systems = new java.util.HashMap<>();
        int added = 0;
        int failed = 0;
        int created = 0;

        for (MinespacePlanetDimensions.Planet planet : MinespacePlanetDimensions.PLANETS) {
            try {
                String systemKey = planet.star.isEmpty() ? planet.name : planet.star;
                String registryKey = systemKey.toLowerCase().replaceAll("[^a-z0-9]+", "_");
                if (registryKey.length() > 40) {
                    registryKey = registryKey.substring(0, 40);
                }
                SolarSystem system = systems.get(registryKey);
                if (system == null) {
                    // The galaxy identifier is not free text: the map resolves it to
                    // assets/asmodeuscore/textures/gui/galaxy/galaxy.<name>.png, and "MilkyWay" has no
                    // such texture - the file is galaxy.milky_way.png. Passing the wrong one crashed the
                    // client with a NullPointerException while drawing the map, so the name is exactly
                    // the one the texture uses.
                    system = new SolarSystem("minespace_" + registryKey, "milky_way");
                    // Spread them out deterministically: a ring per layer, and within a layer an even
                    // spacing, so the map has a shape rather than a pile.
                    int index = created;
                    system.setMapPosition(new Vector3(
                            planet.layer * 3.0F,
                            (float) Math.cos(index * 0.7D) * 2.0F,
                            (float) Math.sin(index * 0.7D) * 2.0F));
                    GalaxyRegistry.register(system);
                    systems.put(registryKey, system);
                    created++;
                }

                Planet body = new Planet("minespace_" + planet.key);
                body.setParentSolarSystem(system);
                // The third argument is autoRegisterDimension. It must be false: 6dm already registered
                // every one of these ids with DimensionManager, and letting Galacticraft register them a
                // second time would either throw or move the id.
                body.setDimensionInfo(planet.dimensionId,
                        MinespacePlanetDimensionsRegistration.VoidProvider.class, false);
                body.setTierRequired(planet.stage);
                body.setRelativeSize(planet.landable ? 1.0F : 2.0F);
                body.setBodyIcon(ICON);
                body.setUnreachable();
                GalaxyRegistry.register(body);
                added++;
            } catch (Throwable t) {
                failed++;
                LOG.warn("Could not put {} on the star map: {}", planet.name, t.toString());
            }
        }

        LOG.info("Star map: registered {} of {} planned bodies as unreachable ({} failed); "
                        + "{} systems created", added, MinespacePlanetDimensions.PLANETS.size(), failed,
                created);
    }

    /**
     * One placeholder icon for now: a per-body icon is an asset question, and a body without one is
     * where a map render crashes rather than looks plain. Galacticraft's own sun icon is reused here
     * until the pack has pictures of its own.
     */
    private static final ResourceLocation ICON =
            new ResourceLocation("galacticraftcore", "textures/gui/celestialbodies/sun.png");
}
