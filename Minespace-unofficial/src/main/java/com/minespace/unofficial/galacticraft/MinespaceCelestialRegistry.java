package com.minespace.unofficial.galacticraft;

import asmodeuscore.api.dimension.IAdvancedSpace.ClassBody;
import asmodeuscore.core.astronomy.BodiesRegistry;
import asmodeuscore.core.astronomy.BodiesRegistry.Galaxies;
import asmodeuscore.core.prefab.celestialbody.ExMoon;
import asmodeuscore.core.prefab.celestialbody.ExPlanet;
import com.minespace.unofficial.Minespace;
import com.minespace.unofficial.gtceu.MinespacePlanetDimensions;
import com.minespace.unofficial.gtceu.MinespacePlanetDimensionsRegistration;
import com.minespace.unofficial.gtceu.MinespacePlanetTerrainPrototype;
import micdoodle8.mods.galacticraft.api.galaxies.CelestialBody;
import micdoodle8.mods.galacticraft.api.galaxies.GalaxyRegistry;
import micdoodle8.mods.galacticraft.api.galaxies.Moon;
import micdoodle8.mods.galacticraft.api.galaxies.Planet;
import micdoodle8.mods.galacticraft.api.galaxies.SolarSystem;
import micdoodle8.mods.galacticraft.api.vector.Vector3;
import net.minecraft.util.ResourceLocation;
import net.minecraftforge.fml.common.Loader;
import org.apache.logging.log4j.Logger;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * Puts this pack's own bodies into Galacticraft's celestial registry, so that PlanetProgression's research covers them.
 *
 * <h2>Why, in one paragraph</h2>
 *
 * The owner's rule: *"关于我们自己的其他 gc gs 以外的天体也应当注册到行星研究的研究进程，要解锁全部解锁"*. PlanetProgression's
 * research is stored **per Galacticraft {@code CelestialBody}}** (`ResearchHooksMP/SP.hasUnlockedCelestialBody`) and
 * its `unlockAllCelestialBodies` command iterates `GalaxyRegistry.getRegisteredPlanets()` and
 * `getRegisteredMoons()` - measured in its bytecode, not assumed. The eighty-seven rows this pack adds (everything
 * the catalog plans that Galacticraft and Galaxy Space do not already own: the exoplanets, the belts, the dwarf
 * planets and the deep-sky objects) were not in those maps, so the telescope could not see them, no research paper
 * existed for them, and "unlock everything" left them locked behind this pack's own survey data. Registering them is
 * the whole fix: from here on PlanetProgression's progress and this pack's star map are the same progress.
 *
 * <h2>What is registered, and what deliberately is not</h2>
 *
 * <ul>
 *   <li><b>Nothing already known to Galacticraft.</b> The nineteen solar-system rows, Proxima B, Barnarda C and its
 *       moons and Tau Ceti f are already theirs; re-registering them would be a second body with the same dimension id
 *       and the same name.</li>
 *   <li><b>No dimension info.</b> {@code setDimensionInfo} is left out on purpose. Galacticraft's own lookup
 *       {@code getCelestialBodyFromDimensionID} must keep answering exactly what it answered before this round: a body
 *       this pack adds is on the map and in the research list, but Galacticraft is never told that dimension N is "its"
 *       body, so nothing in Galacticraft, Galaxy Space or AsmodeusCore gains a reason to build a world, a landing or a
 *       transfer for a body that is not theirs. Travel stays this pack's own path (MinespaceRocketTarget /
 *       MinespaceRocketDestinations).</li>
 *   <li><b>Systems and main stars are created</b> for the keys this pack owns, because Galacticraft's map draws a
 *       system through its main star - the crash of 6dr was exactly a system without one. Where Galacticraft already
 *       has a system for one of this pack's keys (the sun's own system, for the gas giants), the existing system is
 *       reused instead of a second one being invented.</li>
 * </ul>
 *
 * <h2>When</h2>
 *
 * From this mod's preInit, after the planet dimensions exist. That is early enough: PlanetProgression creates its
 * research-paper items in the item registry event, which runs after every mod's preInit and init, so each of these
 * bodies gets a paper and a place in the telescope's list without PlanetProgression knowing this mod exists.
 */
public final class MinespaceCelestialRegistry {

    /** AsmodeusCore is Galaxy Space's astronomy library: the helper every body registered here goes through. */
    public static final String ASMODEUS_CORE = "asmodeuscore";

    private static final String MOD_ID = "minespace";
    private static final Logger LOG = Minespace.log();

    /** Galacticraft's own four rocket tiers are what a body's tier means, so the pack's layers map onto them. */
    private static final int[] LAYER_ROCKET_TIER = { 1, 1, 1, 2, 2, 3, 3, 4 };

    /**
     * Body key (the catalog's own slug) -> the body that stands for it. Read by the star map's gate.
     *
     * <p>Concurrent because a row that turned out to be somebody else's body is resolved when it is first asked about
     * (see {@link #bodyOf}), which happens on the client's map thread and on a server's command thread.</p>
     */
    private static final Map<String, CelestialBody> BY_KEY =
            new java.util.concurrent.ConcurrentHashMap<String, CelestialBody>();

    /**
     * The dimension band this pack owns. Everything at or below -2000 is planned by this pack's catalog; everything
     * above it belongs to Galacticraft, Galaxy Space or another mod - the same rule
     * {@link MinespacePlanetDimensionsRegistration} uses, learnt there the hard way (registering -11, which is Applied
     * Energistics' spatial storage, took the game down).
     *
     * <p>Measured, not assumed (probe, 6er): deciding ownership by asking "is there a body for this dimension yet" gets
     * the wrong answer for twenty rows, because Galaxy Space registers its own bodies **after** this pack's preInit - and
     * the cost of getting it wrong is not a cosmetic duplicate: the registry keeps one body per name, so this pack's
     * Miranda would have been kept and Galaxy Space's own Miranda thrown away.</p>
     */
    private static final int OUR_DEEPEST_OWN_DIMENSION = -2000;

    /**
     * Catalog key -> the unlocalized name Galacticraft or Galaxy Space registered the same body under, for the rows
     * whose names disagree.
     *
     * <p>Measured (probe, 6er): exactly one of the hundred and ten rows has no body it can be matched to, because this
     * pack's catalog named it after the star it belongs to and Galaxy Space named the same body after its planet -
     * {@code barnard_s_star_d} ("Barnard's Star d", 巴纳德 d) is Galaxy Space's {@code moon.barnarda_c2}, and Galaxy Space
     * gives it no dimension, so neither the dimension id nor this pack's name finds it. It is written down here rather
     * than renamed in the catalog because the star map, the vein files and the plan all use the catalog's name.</p>
     */
    private static final Map<String, String> ALIASED_NAMES = new LinkedHashMap<String, String>();

    static {
        ALIASED_NAMES.put("barnard_s_star_d", "moon.barnarda_c2");
    }

    private static boolean registered;

    /** The catalog keys this pack registered itself (as opposed to adopting a body Galacticraft already had). */
    private static final java.util.Set<String> REGISTERED_BY_PACK = new java.util.HashSet<String>();

    private MinespaceCelestialRegistry() {
    }

    /** The body this pack registered for one catalog row, or null when the row is Galacticraft's own. */
    public static CelestialBody bodyOf(MinespacePlanetDimensions.Planet row) {
        CelestialBody body = BY_KEY.get(row.key);
        if (body != null) {
            return body;
        }
        // Late adoption: Galaxy Space registers its own bodies after this pack's preInit (measured, 6er), so a row that
        // is theirs is resolved when the map asks about it rather than when the game starts.
        body = existingBody(row);
        if (body != null) {
            BY_KEY.put(row.key, body);
        }
        return body;
    }

    /**
     * True when this row's body is one **this pack made**, rather than a body Galacticraft or Galaxy Space already had.
     *
     * <p>It decides which progression opens a body: a body this pack registered has two roads into it (the telescope's
     * research of it, or this pack's own survey data - 6er), while a body of theirs has exactly one (theirs).</p>
     */
    public static boolean registeredByPack(MinespacePlanetDimensions.Planet row) {
        return REGISTERED_BY_PACK.contains(row.key);
    }

    /**
     * The body that already stands for a catalog row in Galacticraft's registry, or null.
     *
     * <p>Two ways, because Galacticraft's registry has two: by dimension id where the body has one, and by the
     * unlocalized name it was registered under. The second is not optional - Galaxy Space's Jupiter is
     * {@code planet.jupiter} with no dimension, so a check that only asked for a dimension would register a second
     * Jupiter, and a second body with the same name is a duplicate in every map and every research paper.</p>
     */
    private static CelestialBody existingBody(MinespacePlanetDimensions.Planet row) {
        CelestialBody byDimension = MinespacePlanetResearch.bodyKnownToGalacticraft(row.dimensionId);
        if (byDimension != null) {
            return byDimension;
        }
        // Both prefixes, because the catalog and Galaxy Space do not always agree on what a body *is*: this pack's
        // `barnarda_c2` is an entry of its own, while Galaxy Space's is `moon.barnarda_c2`, a moon of Barnarda C.
        String alias = ALIASED_NAMES.get(row.key);
        String[] names = { alias, "planet." + row.key, "moon." + row.key };
        for (String name : names) {
            if (name == null) {
                continue;
            }
            try {
                CelestialBody body = GalaxyRegistry.getCelestialBodyFromUnlocalizedName(name);
                if (body != null) {
                    return body;
                }
            } catch (Throwable ignored) {
                // Not registered under that name - the next one is the answer.
            }
        }
        return null;
    }

    /**
     * Registers every catalog row Galacticraft does not already know, once.
     *
     * <p>Silent when Galacticraft or AsmodeusCore is missing: the pack must still load without them, so this is a
     * mod-presence check and not a dependency.</p>
     */
    public static void register() {
        if (registered) {
            return;
        }
        registered = true;
        if (!Minespace.hasGalacticraft() || !Loader.isModLoaded(ASMODEUS_CORE)) {
            LOG.info("Celestial registry: not registering this pack's bodies (Galacticraft or {} missing)",
                    ASMODEUS_CORE);
            return;
        }

        // A system Galacticraft already owns, for a key this pack also uses: the sun's system for the four gas giants
        // and Deimos. Reusing it is the point - one system, one progression (6eq) - and inventing a second "Sol" system
        // would be a visible duplicate in every map that reads the registry.
        Map<String, SolarSystem> systems = new LinkedHashMap<String, SolarSystem>();
        int adopted = 0;
        for (MinespacePlanetDimensions.Planet row : MinespacePlanetDimensions.PLANETS) {
            CelestialBody known = existingBody(row);
            if (known != null) {
                // Adopted: this pack's catalog row *is* that body, so its gate is that body's gate.
                BY_KEY.put(row.key, known);
                adopted++;
            }
            if (known != null) {
                SolarSystem system = systemOf(known);
                if (system != null) {
                    systems.put(keyOf(row), system);
                }
            }
        }

        Map<String, List<MinespacePlanetDimensions.Planet>> ours =
                new LinkedHashMap<String, List<MinespacePlanetDimensions.Planet>>();
        int knownToGalacticraft = 0;
        for (MinespacePlanetDimensions.Planet row : MinespacePlanetDimensions.PLANETS) {
            // Ownership is decided by the dimension band, not by what happens to be registered yet - see
            // OUR_DEEPEST_OWN_DIMENSION.
            if (row.dimensionId > OUR_DEEPEST_OWN_DIMENSION || existingBody(row) != null) {
                knownToGalacticraft++;
                continue;
            }
            List<MinespacePlanetDimensions.Planet> rows = ours.get(keyOf(row));
            if (rows == null) {
                rows = new ArrayList<MinespacePlanetDimensions.Planet>();
                ours.put(keyOf(row), rows);
            }
            rows.add(row);
        }

        int newSystems = 0;
        int newPlanets = 0;
        int newMoons = 0;
        int failed = 0;
        for (Map.Entry<String, List<MinespacePlanetDimensions.Planet>> entry : ours.entrySet()) {
            String key = entry.getKey();
            List<MinespacePlanetDimensions.Planet> rows = entry.getValue();
            try {
                SolarSystem system = systems.get(key);
                if (system == null) {
                    system = newSystem(key, rows);
                    if (system == null) {
                        failed += rows.size();
                        continue;
                    }
                    systems.put(key, system);
                    newSystems++;
                }
                // Two passes: planets first, so that a moon always has an object to be a moon *of* - whether its parent
                // is one of ours or one of Galacticraft's (Deimos orbits their Mars).
                for (int pass = 0; pass < 2; pass++) {
                    for (MinespacePlanetDimensions.Planet row : rows) {
                        boolean isMoon = !row.parent.isEmpty();
                        if (isMoon != (pass == 1)) {
                            continue;
                        }
                        CelestialBody body = isMoon ? newMoon(row) : newPlanet(system, row);
                        if (body == null) {
                            failed++;
                            continue;
                        }
                        BY_KEY.put(row.key, body);
                        REGISTERED_BY_PACK.add(row.key);
                        if (isMoon) {
                            newMoons++;
                        } else {
                            newPlanets++;
                        }
                    }
                }
            } catch (Throwable t) {
                // One bad row must not take the registry - and therefore the game - down with it, and this is the one
                // place in the load where an exception would be a black screen instead of a log line.
                failed += rows.size();
                LOG.warn("Celestial registry: system {} failed to register: {}", key, t.toString());
            }
        }

        LOG.info("Celestial registry: registered {} planets and {} moons in {} new systems ({} rows are bodies "
                        + "Galacticraft already owns, {} of them found by name, {} failed); Galacticraft now knows "
                        + "{} planets, {} moons, {} systems",
                newPlanets, newMoons, newSystems, knownToGalacticraft, adopted, failed,
                GalaxyRegistry.getRegisteredPlanets().size(), GalaxyRegistry.getRegisteredMoons().size(),
                GalaxyRegistry.getRegisteredSolarSystems().size());
    }

    /**
     * Standing check, run once at loadComplete: the three things this registration gets wrong *silently*.
     *
     * <p>None of them throws, and all three of them are couplings to something outside this mod, which is exactly why
     * they are checked on every start rather than once with a probe (the house rule for recipe hygiene, 6cc):</p>
     *
     * <ul>
     *   <li><b>A body with no language entry</b> shows a raw key such as {@code planet.trappist_1_e.name} in
     *       Galacticraft's and PlanetProgression's own windows. The keys are generated by
     *       tools\build-celestial-lang.ps1 from the same table this class reads, so the two can drift apart the day
     *       either side changes.</li>
     *   <li><b>A body with no icon file</b> draws as the purple checkerboard in those same windows. The files come from
     *       tools\build-celestial-art.ps1, by kind.</li>
     *   <li><b>A body whose dimension is not registered</b> is a body a rocket can be aimed at and cannot land on: the
     *       catalog gives six rows above this pack's own dimension band a dimension id (the gas giants, Deimos, Barnarda
     *       C2), and whether anything actually registers those ids is a fact about the other mods, not about this one.
     *       A row that is not landable cannot be aimed at, so it is only reported for the landable ones.</li>
     * </ul>
     */
    public static void verify(String when) {
        if (!registered || BY_KEY.isEmpty()) {
            return;
        }
        java.util.Set<String> langKeys = new java.util.HashSet<String>();
        for (String locale : new String[] { "en_us", "zh_cn" }) {
            java.io.InputStream in = Minespace.class
                    .getResourceAsStream("/assets/minespace/lang/" + locale + ".lang");
            if (in == null) {
                LOG.warn("Celestial registry check: {} is missing from the jar, so no name can be checked", locale);
                continue;
            }
            try {
                java.io.BufferedReader reader = new java.io.BufferedReader(new java.io.InputStreamReader(in, "UTF-8"));
                String line;
                while ((line = reader.readLine()) != null) {
                    int eq = line.indexOf('=');
                    if (eq > 0) {
                        langKeys.add(line.substring(0, eq).trim());
                    }
                }
                reader.close();
            } catch (Throwable t) {
                LOG.warn("Celestial registry check: could not read {}: {}", locale, t.toString());
            }
        }

        int missingNames = 0;
        int missingIcons = 0;
        StringBuilder nameless = new StringBuilder();
        StringBuilder iconless = new StringBuilder();
        for (MinespacePlanetDimensions.Planet row : MinespacePlanetDimensions.PLANETS) {
            if (!registeredByPack(row)) {
                // Adopted from Galacticraft or Galaxy Space: their language files name it and their assets draw it.
                continue;
            }
            String key = (row.parent.isEmpty() ? "planet." : "moon.") + row.key + ".name";
            if (!langKeys.contains(key)) {
                missingNames++;
                if (missingNames <= 6) {
                    nameless.append(key).append(' ');
                }
            }
            String icon = "textures/gui/celestialbodies/" + iconKind(row) + ".png";
            if (Minespace.class.getResource("/assets/minespace/" + icon) == null) {
                missingIcons++;
                if (missingIcons <= 6) {
                    iconless.append(icon).append(' ');
                }
            }
        }

        int unregistered = 0;
        int unregisteredOurs = 0;
        StringBuilder dimensionless = new StringBuilder();
        for (MinespacePlanetDimensions.Planet row : MinespacePlanetDimensions.PLANETS) {
            if (!row.landable || net.minecraftforge.common.DimensionManager.isDimensionRegistered(row.dimensionId)) {
                continue;
            }
            unregistered++;
            if (row.dimensionId <= OUR_DEEPEST_OWN_DIMENSION) {
                // Ours to register, and this pack's own dimension registration is the only thing that can do it: a row
                // here means a world a rocket can be aimed at and cannot land on. Not expected, and worth a name.
                unregisteredOurs++;
            }
            dimensionless.append(row.name).append('(').append(row.dimensionId).append(") ");
        }

        LOG.info("Celestial registry check ({}): {} of {} bodies registered by this pack, {} missing language keys [{}], "
                        + "{} missing icons [{}], {} landable bodies whose dimension is not registered, {} of them in "
                        + "this pack's own band [{}]",
                when, REGISTERED_BY_PACK.size(), MinespacePlanetDimensions.PLANETS.size(),
                missingNames, nameless.toString().trim(), missingIcons, iconless.toString().trim(),
                unregistered, unregisteredOurs, dimensionless.toString().trim());
    }

    /** The parent system of a body Galacticraft registered, whichever kind of body it is. */
    private static SolarSystem systemOf(CelestialBody body) {
        if (body instanceof Planet) {
            return ((Planet) body).getParentSolarSystem();
        }
        if (body instanceof Moon) {
            Planet parent = ((Moon) body).getParentPlanet();
            return parent == null ? null : parent.getParentSolarSystem();
        }
        return null;
    }

    /** The catalog's own grouping key: the star a row orbits, or the row's own name when it orbits nothing. */
    public static String keyOf(MinespacePlanetDimensions.Planet row) {
        return row.star.isEmpty() ? row.name : row.star;
    }

    /**
     * A new solar system for a key this pack owns, with its main star.
     *
     * <p>The registry names are slugs and the readable names live in the language files
     * ({@code solarsystem.minespace_<key>.name} and {@code star.minespace_star_<key>.name}, written by
     * tools\build-celestial-lang.ps1 from the catalog). A row that orbits nothing - a black hole, a galaxy, the cosmic
     * microwave background - is its own centre, so its system's star carries the object's name and the object itself is
     * registered as the planet in it.</p>
     */
    private static SolarSystem newSystem(String key, List<MinespacePlanetDimensions.Planet> rows) {
        String slug = "minespace_" + slug(key);
        String starSlug = "minespace_star_" + slug(key);
        // A deterministic position on the galaxy map: the same on every client and every server, spread over a sphere
        // instead of stacking every system this pack adds on one point.
        double hash = key.hashCode();
        float angle = (float) (hash % 360.0D) * 0.017453292F;
        float tilt = (float) ((hash / 360.0D) % 60.0D) * 0.017453292F;
        float radius = 9.0F;
        Vector3 position = new Vector3(
                (float) (Math.cos(angle) * Math.cos(tilt) * radius),
                (float) (Math.sin(tilt) * radius),
                (float) (Math.sin(angle) * Math.cos(tilt) * radius));
        SolarSystem system = BodiesRegistry.registerSolarSystem(MOD_ID, slug, Galaxies.MILKYWAY, position,
                starSlug, starSize(rows.get(0)));
        if (system == null) {
            return null;
        }
        GalaxyRegistry.registerSolarSystem(system);
        if (system.getMainStar() != null) {
            system.getMainStar().setBodyIcon(icon("star"));
        }
        return system;
    }

    /** A star drawn by its spectral class, which the catalog carries in the star's own name ("TRAPPIST-1 M8.0 V"). */
    private static float starSize(MinespacePlanetDimensions.Planet row) {
        String star = row.star;
        if (star.isEmpty()) {
            return 1.2F;
        }
        char spectral = 'M';
        for (int i = star.length() - 1; i > 0; i--) {
            char c = star.charAt(i);
            if (c == 'O' || c == 'B' || c == 'A' || c == 'F' || c == 'G' || c == 'K' || c == 'M') {
                spectral = c;
                break;
            }
        }
        switch (spectral) {
            case 'O':
            case 'B':
                return 2.4F;
            case 'A':
                return 1.9F;
            case 'F':
                return 1.6F;
            case 'G':
                return 1.4F;
            case 'K':
                return 1.2F;
            default:
                return 0.9F;
        }
    }

    private static CelestialBody newPlanet(SolarSystem system, MinespacePlanetDimensions.Planet row) {
        ExPlanet planet = BodiesRegistry.registerExPlanet(system, row.key, MOD_ID, relativeSize(row));
        if (planet == null) {
            return null;
        }
        fill(planet, row, null);
        GalaxyRegistry.registerPlanet(planet);
        return planet;
    }

    /** A moon of a body that already exists - this pack's own planet, or Galacticraft's (Deimos orbits their Mars). */
    private static CelestialBody newMoon(MinespacePlanetDimensions.Planet row) {
        Planet parent = parentOf(row);
        if (parent == null) {
            LOG.warn("Celestial registry: moon {} has no parent body ({}), leaving it unregistered",
                    row.name, row.parent);
            return null;
        }
        ExMoon moon = BodiesRegistry.registerExMoon(parent, row.key, MOD_ID, relativeSize(row));
        if (moon == null) {
            return null;
        }
        fill(moon, row, parent);
        GalaxyRegistry.registerMoon(moon);
        return moon;
    }

    /** Resolves a moon's parent: one of this pack's rows, or a body Galacticraft already owns. */
    private static Planet parentOf(MinespacePlanetDimensions.Planet row) {
        for (MinespacePlanetDimensions.Planet candidate : MinespacePlanetDimensions.PLANETS) {
            if (!candidate.name.equals(row.parent)) {
                continue;
            }
            CelestialBody ours = BY_KEY.get(candidate.key);
            if (ours instanceof Planet) {
                return (Planet) ours;
            }
            CelestialBody known = MinespacePlanetResearch.bodyKnownToGalacticraft(candidate.dimensionId);
            if (known instanceof Planet) {
                return (Planet) known;
            }
        }
        return null;
    }

    /**
     * The fields every registered body needs, filled from what the catalog actually knows.
     *
     * <p>Galacticraft draws a body from its orbit, its size and its icon, and AsmodeusCore adds the physical data; the
     * catalog carries a real orbital distance and period for every row but no radius - so the size is by kind (a star
     * is not the size of a moon) rather than invented per body, and the gravity follows the kind the same way. None of
     * this is read by this pack's own star map, which reads the catalog; all of it is what *other* maps need in order
     * not to draw a body at the wrong place or crash on a missing field.</p>
     */
    private static void fill(CelestialBody body, MinespacePlanetDimensions.Planet row, Planet parent) {
        float size = relativeSize(row);
        // A watchable orbit inside Galacticraft's own animation, keeping the catalog's order and ratios.
        float orbitTime = row.periodDays <= 0.0F ? 1.0F
                : Math.max(0.4F, Math.min(12.0F, row.periodDays / 30.0F));
        BodiesRegistry.setOrbitData(body, phase(row), size, orbitTime);
        body.setBodyIcon(icon(iconKind(row)));
        // The dimension this pack registered for the row, with the provider it registered it with, and the tier is the
        // rocket tier the layer asks for (BodiesRegistry.setProviderData sets dimension, tier and biomes together).
        //
        // Saying which dimension a body lives in is not decoration: without it every body this pack registers answers
        // `getDimensionID() == 0`, which is the overworld - so anything that asks Galacticraft "which body owns this
        // dimension" could be answered with an exoplanet, and PlanetProgression skips bodies whose dimension is -1,
        // which is a different lie it does not tell about ours (measured, 6er: Galaxy Space's own dimension-less Deimos
        // is the one body in the catalog with no research paper).
        Class<? extends net.minecraft.world.WorldProvider> provider = providerOf(row);
        BodiesRegistry.setProviderData(body, provider, row.dimensionId, rocketTier(row.layer),
                new net.minecraft.world.biome.Biome[0]);
        // ... and `false`, because the dimension is already registered: MinespacePlanetDimensionsRegistration did it in
        // the same preInit, and Galacticraft must not register it a second time.
        body.setDimensionInfo(row.dimensionId, provider, false);
        if (row.orbitAu > 0.0F) {
            float distance = parent == null ? Math.max(0.3F, Math.min(6.0F, row.orbitAu)) : 0.06F;
            body.setRelativeDistanceFromCenter(new CelestialBody.ScalableDistance(distance, distance));
        }
        ClassBody kind = classOf(row);
        if (body instanceof ExPlanet) {
            ((ExPlanet) body).setClassPlanet(kind).setGravity(gravity(row)).setDayLength(dayLength(row))
                    .setAtmosphericPressure(row.landable ? 1.0F : 0.0F);
        } else if (body instanceof ExMoon) {
            ((ExMoon) body).setClassPlanet(kind).setGravity(gravity(row)).setDayLength(dayLength(row))
                    .setAtmosphericPressure(row.landable ? 1.0F : 0.0F);
        }
    }

    /** Deterministic and body-specific, so the bodies of one system do not start in a line. */
    private static float phase(MinespacePlanetDimensions.Planet row) {
        return Math.abs(row.key.hashCode() % 360);
    }

    private static long dayLength(MinespacePlanetDimensions.Planet row) {
        return 12000L + Math.abs((long) row.key.hashCode()) % 48000L;
    }

    /** Galacticraft's rocket tier for a catalog layer - the same mapping the star map's card prints. */
    private static int rocketTier(int layer) {
        return LAYER_ROCKET_TIER[Math.max(0, Math.min(LAYER_ROCKET_TIER.length - 1, layer))];
    }

    /** The size Galacticraft's map draws a body at, by kind: the catalog has no radius, and a kind is not a guess. */
    private static float relativeSize(MinespacePlanetDimensions.Planet row) {
        String type = row.type;
        if ("Star".equals(type) || "WhiteDwarf".equals(type)) {
            return 1.6F;
        }
        if ("Galaxy".equals(type) || "Cluster".equals(type) || "Nebula".equals(type)
                || "CosmicWeb".equals(type)) {
            return 1.4F;
        }
        if (!"Planet".equals(type) && !"Moon".equals(type) && !"DwarfPlanet".equals(type)) {
            return 1.0F;
        }
        if ("Moon".equals(type)) {
            return 0.55F;
        }
        if ("DwarfPlanet".equals(type)) {
            return 0.45F;
        }
        // A planet: the gas giants are the ones this catalog marks non-landable with no veins and no parent.
        if (!row.landable && row.veins == 0 && row.parent.isEmpty()) {
            return 1.8F;
        }
        return 1.0F;
    }

    private static float gravity(MinespacePlanetDimensions.Planet row) {
        if ("Moon".equals(row.type)) {
            return 0.16F;
        }
        if ("DwarfPlanet".equals(row.type) || "AsteroidBelt".equals(row.type)
                || "InterstellarObject".equals(row.type)) {
            return 0.08F;
        }
        if (!row.landable) {
            // A gas giant, a black hole, a galaxy: nobody stands on it, so the number only has to be a sane one.
            return 2.0F;
        }
        return 0.9F;
    }

    private static ClassBody classOf(MinespacePlanetDimensions.Planet row) {
        if ("AsteroidBelt".equals(row.type) || "InterstellarObject".equals(row.type)) {
            return ClassBody.ASTEROID;
        }
        if ("Saturn".equals(row.name) || "Jupiter".equals(row.name)) {
            return ClassBody.GASGIANT;
        }
        if ("Uranus".equals(row.name) || "Neptune".equals(row.name)) {
            return ClassBody.ICEGIANT;
        }
        if (contains(row.nameZh, "冰")) {
            return ClassBody.ICEWORLD;
        }
        if ("Moon".equals(row.type)) {
            return ClassBody.SELENA;
        }
        if (!row.landable || !"Planet".equals(row.type)) {
            return ClassBody.SELENA;
        }
        if (contains(row.nameZh, "火") || "Mercury".equals(row.name)) {
            return ClassBody.DESERT;
        }
        return ClassBody.TERRA;
    }

    /**
     * The icon Galacticraft's own maps draw a body with, by kind - the file names written by
     * tools\build-celestial-art.ps1. One icon per kind rather than one per body: eighty-seven textures that this
     * pack's own map never looks at would be eighty-seven files to keep, and it is kinds that a map legend shows.
     */
    private static ResourceLocation icon(String kind) {
        return new ResourceLocation(MOD_ID, "textures/gui/celestialbodies/" + kind + ".png");
    }

    private static String iconKind(MinespacePlanetDimensions.Planet row) {
        switch (row.type) {
            case "Star":
                return "star";
            case "WhiteDwarf":
                return "white_dwarf";
            case "Galaxy":
                return "galaxy";
            case "Cluster":
                return "cluster";
            case "Nebula":
                return "nebula";
            case "BlackHole":
                return "black_hole";
            case "Quasar":
                return "quasar";
            case "Pulsar":
                return "pulsar";
            case "SupernovaRemnant":
                return "supernova";
            case "GravitationalWave":
                return "gravitational_wave";
            case "CMB":
                return "cmb";
            case "Transient":
                return "transient";
            case "InterstellarObject":
                return "interstellar";
            case "AsteroidBelt":
                return "belt";
            case "CosmicWeb":
                return "cosmic_web";
            case "DwarfPlanet":
                return "dwarf_planet";
            case "Moon":
                return contains(row.nameZh, "冰") ? "moon_ice" : "moon_rock";
            default:
                if (!row.landable && row.veins == 0 && row.parent.isEmpty()) {
                    return "gas_giant";
                }
                return row.landable ? "planet_rocky" : "planet_ice";
        }
    }

    private static boolean contains(String text, String needle) {
        return text != null && text.contains(needle);
    }

    /** A key turned into something usable as a registry name: lowercase letters, digits and single underscores. */
    public static String slug(String key) {
        StringBuilder out = new StringBuilder();
        for (int i = 0; i < key.length(); i++) {
            char c = Character.toLowerCase(key.charAt(i));
            if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9')) {
                out.append(c);
            } else if (out.length() > 0 && out.charAt(out.length() - 1) != '_') {
                out.append('_');
            }
        }
        while (out.length() > 0 && out.charAt(out.length() - 1) == '_') {
            out.setLength(out.length() - 1);
        }
        return out.toString().toLowerCase(Locale.ROOT);
    }

    /** The provider class this pack registered a body's dimension with - see MinespacePlanetDimensionsRegistration. */
    public static Class<? extends net.minecraft.world.WorldProvider> providerOf(
            MinespacePlanetDimensions.Planet row) {
        return MinespacePlanetTerrainPrototype.isPrototype(row)
                ? MinespacePlanetTerrainPrototype.RockProvider.class
                : MinespacePlanetDimensionsRegistration.VoidProvider.class;
    }
}
