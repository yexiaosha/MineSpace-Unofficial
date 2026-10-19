package com.minespace.unofficial.galacticraft;

import micdoodle8.mods.galacticraft.api.galaxies.CelestialBody;
import micdoodle8.mods.galacticraft.api.galaxies.GalaxyRegistry;
import net.minecraft.entity.player.EntityPlayerMP;
import net.minecraftforge.fml.common.Loader;

/**
 * One progression, not two: whichever gate already owns a body decides whether the star map shows it as reachable.
 *
 * <h2>The question this answers</h2>
 *
 * The owner asked why this pack's own planet research does not unlock *together with* the planet research they already
 * have - PlanetProgression's telescope work. The answer was a wall rather than an oversight: PlanetProgression stores
 * its unlock state **per Galacticraft {@code CelestialBody}**
 * ({@code ResearchHooksMP/SP.hasUnlockedCelestialBody(player, body)}), and the eighty-one bodies this pack plans are
 * deliberately *not* registered into Galacticraft's celestial registry (the owner's own decision, 6ej). There is
 * therefore no object to hand PlanetProgression for them.
 *
 * <p>For the bodies the pack does *not* own - the solar system and the few Galaxy Space outliers, which are exactly the
 * bodies PlanetProgression can already survey - there is a key, and it is reachable by dimension:
 * {@link GalaxyRegistry#getCelestialBodyFromDimensionID(int)}. So:</p>
 *
 * <ul>
 *   <li>a body Galacticraft knows: **PlanetProgression's research decides** - survey the Moon there and the star map
 *       shows the Moon unlocked here, with no second gate and no second item;</li>
 *   <li>a body only this pack knows: this pack's own survey data decides, because nobody else can have an opinion
 *       about a world they have never heard of.</li>
 * </ul>
 *
 * <p>PlanetProgression is optional: every call is behind a mod-presence check, so the pack still loads (with our data
 * as the only gate) if it is ever removed.</p>
 */
public final class MinespacePlanetResearch {

    public static final String PLANET_PROGRESSION = "planetprogression";

    private MinespacePlanetResearch() {
    }

    /**
     * True when PlanetProgression is this row's gate - either because Galacticraft owns the dimension, or because the
     * row is in the sun's own system.
     *
     * <h2>Why the sun's system is a case of its own</h2>
     *
     * The measured shape of the catalog (probe, 6eq) is that nineteen of the solar system's twenty-four rows are bodies
     * Galacticraft or Galaxy Space registers, and that the other five are this pack's: the four gas giants - Jupiter,
     * Saturn, Uranus and Neptune - and Deimos. What makes them different from the eighty-one exoplanets is that they are
     * **not this pack's own discoveries**: Galaxy Space registers all five of them as planets and moons in the sun's
     * system, it just gives them no dimension ({@code jupiter -> planet.jupiter dim -1}), so this pack has to supply a
     * dimension id to put them on a map at all. Gating them with this pack's own survey data meant one system with two
     * progressions in it - exactly the shape 6el was written to avoid - and the owner saw the result: *"我全部解锁之后，
     * gs原本木星，土星等这些都没有了"*, with everything unlocked in PlanetProgression and the solar system still missing
     * its giants.
     *
     * <p>So a row in the sun's system is PlanetProgression's business - and it is charted when that research has
     * surveyed **that body**, one at a time, the way Galacticraft's and Galaxy Space's own charts work. Layer 1 is the
     * solar system by construction (6ea); the per-body rule is 6eu.</p>
     */
    public static boolean gateIsPlanetProgression(com.minespace.unofficial.gtceu.MinespacePlanetDimensions.Planet body) {
        return body.layer <= 1 || bodyKnownToGalacticraft(body.dimensionId) != null;
    }

    /**
     * Server side: the gate for a row in the sun's own system, which is researched **one body at a time**.
     *
     * <h2>Why not the system (6eu)</h2>
     *
     * <p>This used to ask whether *any* body in the row's system had been surveyed, because Galaxy Space's gas giants
     * are planets with no dimension ({@code jupiter -> planet.jupiter dim -1}) and there looked to be no object to hand
     * the research for them. There is one: {@link MinespaceCelestialRegistry#bodyOf} resolves a row to the body that
     * already stands for it - by dimension where it has one, by unlocalized name otherwise - and registers one only
     * when nobody else has, so the per-body question is askable for every row. It is also the answer the owner wants:
     * the system-level question lit up all twenty-four solar rows the moment one of them was researched, so Jupiter,
     * Saturn, Uranus and Neptune appeared on a chart that had never surveyed them.</p>
     *
     * <p>The client's copy of this rule is {@code MinespaceStarMapScreen.surveySolarBody} - the same two lines, written
     * through that screen's stand-in for PlanetProgression, which a capture run has instead of a player. They have to
     * answer the same way or the map offers a destination the server refuses.</p>
     */
    public static boolean surveyedSolarOnServer(EntityPlayerMP player,
            com.minespace.unofficial.gtceu.MinespacePlanetDimensions.Planet row) {
        return bodyKnownToGalacticraft(row.dimensionId) != null
                ? surveyedOnServer(player, row.dimensionId)
                : surveyedOursOnServer(player, row);
    }

    /** The Galacticraft body that owns this dimension, or null when the dimension is this pack's own. */
    public static CelestialBody bodyKnownToGalacticraft(int dimensionId) {
        try {
            return GalaxyRegistry.getCelestialBodyFromDimensionID(dimensionId);
        } catch (Throwable t) {
            // Galacticraft's registry throws rather than returning null for an id it has never seen in some builds.
            return null;
        }
    }

    /** Client side: has the pack's planet research already surveyed the body that owns this dimension? */
    public static boolean surveyedOnClient(net.minecraft.client.entity.EntityPlayerSP player, int dimensionId) {
        if (player == null || !Loader.isModLoaded(PLANET_PROGRESSION)) {
            return false;
        }
        CelestialBody body = bodyKnownToGalacticraft(dimensionId);
        if (body == null) {
            return false;
        }
        try {
            return com.mjr.planetprogression.api.research.ResearchHooksSP.hasUnlockedCelestialBody(player, body);
        } catch (Throwable t) {
            return false;
        }
    }

    /** Server side: the same question, and the one that decides whether a rocket may be aimed. */
    public static boolean surveyedOnServer(EntityPlayerMP player, int dimensionId) {
        if (player == null || !Loader.isModLoaded(PLANET_PROGRESSION)) {
            return false;
        }
        CelestialBody body = bodyKnownToGalacticraft(dimensionId);
        if (body == null) {
            return false;
        }
        try {
            return com.mjr.planetprogression.api.research.ResearchHooksMP.hasUnlockedCelestialBody(player, body);
        } catch (Throwable t) {
            return false;
        }
    }

    /**
     * Client side: has the pack's planet research surveyed the body this pack registered for a catalog row?
     *
     * <p>The other half of 6er. A body Galacticraft owns is found by dimension id; a body this pack registers (see
     * MinespaceCelestialRegistry) has no dimension in Galacticraft's eyes, so the question is asked of the object
     * itself - PlanetProgression stores its research as a list of {@code CelestialBody}, and the telescope, the research
     * papers and {@code unlockAllCelestialBodies} all work off the same registry this pack now adds to.</p>
     */
    public static boolean surveyedOursOnClient(net.minecraft.client.entity.EntityPlayerSP player,
            com.minespace.unofficial.gtceu.MinespacePlanetDimensions.Planet row) {
        CelestialBody body = MinespaceCelestialRegistry.bodyOf(row);
        if (body == null || player == null || !Loader.isModLoaded(PLANET_PROGRESSION)) {
            return false;
        }
        try {
            return com.mjr.planetprogression.api.research.ResearchHooksSP.hasUnlockedCelestialBody(player, body);
        } catch (Throwable t) {
            return false;
        }
    }

    /** Server side: the same question, and the one that decides whether a rocket may be aimed. */
    public static boolean surveyedOursOnServer(EntityPlayerMP player,
            com.minespace.unofficial.gtceu.MinespacePlanetDimensions.Planet row) {
        CelestialBody body = MinespaceCelestialRegistry.bodyOf(row);
        if (body == null || player == null || !Loader.isModLoaded(PLANET_PROGRESSION)) {
            return false;
        }
        try {
            return com.mjr.planetprogression.api.research.ResearchHooksMP.hasUnlockedCelestialBody(player, body);
        } catch (Throwable t) {
            return false;
        }
    }
}
