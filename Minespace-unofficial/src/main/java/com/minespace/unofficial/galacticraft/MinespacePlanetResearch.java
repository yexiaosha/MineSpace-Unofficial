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
     * <p>So the rule is now one progression per system: a row in the sun's system is PlanetProgression's business, and
     * it is charted when that research has surveyed the system - the rows this pack added are charted together with the
     * bodies they exist to orbit for. Layer 1 is the solar system by construction (6ea).</p>
     */
    public static boolean gateIsPlanetProgression(com.minespace.unofficial.gtceu.MinespacePlanetDimensions.Planet body) {
        return body.layer <= 1 || bodyKnownToGalacticraft(body.dimensionId) != null;
    }

    /** The system a catalog row belongs to: the star it orbits, or the row's own name when it orbits nothing. */
    public static String systemKeyOf(com.minespace.unofficial.gtceu.MinespacePlanetDimensions.Planet body) {
        return body.star.isEmpty() ? body.name : body.star;
    }

    /**
     * Client side: has the pack's planet research surveyed any of the bodies Galacticraft owns in this row's system?
     *
     * <p>Asked instead of "is this exact body in PlanetProgression's list" because the rows it is asked about are the
     * ones PlanetProgression has no entry for: Galaxy Space's Jupiter is a planet with no dimension, so there is no
     * object to hand the research for it. Its system's answer is the closest thing to the truth, and it is the honest
     * one: the pack's giants are part of the same picture as the moons that orbit them.</p>
     */
    public static boolean systemSurveyedOnClient(net.minecraft.client.entity.EntityPlayerSP player,
            com.minespace.unofficial.gtceu.MinespacePlanetDimensions.Planet body) {
        String key = systemKeyOf(body);
        for (com.minespace.unofficial.gtceu.MinespacePlanetDimensions.Planet sibling
                : com.minespace.unofficial.gtceu.MinespacePlanetDimensions.PLANETS) {
            if (systemKeyOf(sibling).equals(key) && bodyKnownToGalacticraft(sibling.dimensionId) != null
                    && surveyedOnClient(player, sibling.dimensionId)) {
                return true;
            }
        }
        return false;
    }

    /** Server side: the same question, from the state that decides whether a rocket may be aimed. */
    public static boolean systemSurveyedOnServer(EntityPlayerMP player,
            com.minespace.unofficial.gtceu.MinespacePlanetDimensions.Planet body) {
        String key = systemKeyOf(body);
        for (com.minespace.unofficial.gtceu.MinespacePlanetDimensions.Planet sibling
                : com.minespace.unofficial.gtceu.MinespacePlanetDimensions.PLANETS) {
            if (systemKeyOf(sibling).equals(key) && bodyKnownToGalacticraft(sibling.dimensionId) != null
                    && surveyedOnServer(player, sibling.dimensionId)) {
                return true;
            }
        }
        return false;
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
