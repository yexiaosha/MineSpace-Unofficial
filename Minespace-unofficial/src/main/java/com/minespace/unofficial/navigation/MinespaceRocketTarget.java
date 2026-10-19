package com.minespace.unofficial.navigation;

import com.minespace.unofficial.Minespace;
import com.minespace.unofficial.galacticraft.MinespaceCelestialRegistry;
import com.minespace.unofficial.galacticraft.MinespacePlanetResearch;
import com.minespace.unofficial.gtceu.MinespacePlanetDimensions;
import com.minespace.unofficial.gtceu.MinespaceResearchData;
import micdoodle8.mods.galacticraft.api.entity.IRocketType;
import micdoodle8.mods.galacticraft.api.prefab.entity.EntityAutoRocket;
import net.minecraft.entity.Entity;
import net.minecraft.entity.player.EntityPlayerMP;
import net.minecraft.util.text.TextComponentString;
import net.minecraft.util.text.TextFormatting;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * The adapter between Galacticraft's rocket and this pack's own star map: GC flies, we aim.
 *
 * <h2>Why this and not a registration into Galacticraft's map</h2>
 *
 * The owner's decision (6ej/6ek): the pack's own star map is the map, and nothing is registered into Galacticraft's
 * celestial registry - which is also why the two crashes of 6dq/6dr are no longer on the path. That leaves exactly one
 * question, "how does a player get to a body this pack owns", and it has a small answer because Galacticraft's rocket
 * already knows how to fly somewhere: {@link EntityAutoRocket#targetDimension} is a public field, and its launch
 * sequence - ignition, ascent, atmosphere, world transfer, landing - reads it.
 *
 * So this class does four things and no fifth:
 *
 * <ol>
 *   <li>the destination must be a body this pack knows (a dimension id from the catalog);</li>
 *   <li>the player must be **riding** a rocket - the vehicle stays Galacticraft's, and the parked-pad case is
 *       Galacticraft's own flow, not ours;</li>
 *   <li>the gate: the tier's research data in the player's inventory, and a rocket tier high enough for the layer;</li>
 *   <li>it sets {@code targetDimension} and says so. It does **not** ignite: the owner presses Galacticraft's own
 *       launch, which is what "keep GC's launch flow" means.</li>
 * </ol>
 *
 * <p>The rocket tier is derived from the same layer the research data opens, halved and rounded up, capped at
 * Galacticraft's four tiers - the pack's own mapping, recorded here because Galacticraft has no opinion about layers
 * it has never heard of.</p>
 */
public final class MinespaceRocketTarget {

    private static final Logger LOG = LogManager.getLogger("minespace_navigation");

    private MinespaceRocketTarget() {
    }

    /**
     * The rocket this entity is in, following the riding chain - a seat or a mount in between is still the rocket.
     *
     * <p>The first version asked {@code getRidingEntity()} once and required an {@code EntityAutoRocket} there. Every
     * rocket in this pack either is one or extends one (Galacticraft's tiered ones, Galaxy Space's tier-4/5/6 and
     * multi-seat ones), so one link should be enough - and when the owner was refused while sitting in a rocket (6ex),
     * the remaining explanations were a link this pack cannot see or a vehicle that never was a rocket. Following the
     * chain removes the first of those, and the log line at the refusal names the second.</p>
     */
    public static EntityAutoRocket rocketRiddenBy(Entity entity) {
        Entity vehicle = entity == null ? null : entity.getRidingEntity();
        // A depth cap, because a cyclic riding chain would otherwise hang a tick.
        for (int depth = 0; vehicle != null && depth < 4; depth++) {
            if (vehicle instanceof EntityAutoRocket) {
                return (EntityAutoRocket) vehicle;
            }
            vehicle = vehicle.getRidingEntity();
        }
        return null;
    }

    /** The rocket tier a layer asks for: I/II need T1, III/IV T2, V/VI T3. */
    public static int rocketTierForLayer(int layer) {
        int tier = MinespaceResearchData.tierOfLayer(layer);
        return Math.max(1, Math.min(4, (tier + 1) / 2));
    }

    /** The body in the catalog with this dimension id, or null. */
    public static MinespacePlanetDimensions.Planet bodyOf(int dimensionId) {
        for (MinespacePlanetDimensions.Planet planet : MinespacePlanetDimensions.PLANETS) {
            if (planet.dimensionId == dimensionId) {
                return planet;
            }
        }
        return null;
    }

    /**
     * Points the player's rocket at one of this pack's bodies, and returns the line to put in their chat.
     *
     * <p>Every refusal is answered with a reason rather than silence: this is the one place where "nothing happened"
     * would be indistinguishable from a bug, and the player is looking at a star map that already told them which
     * bodies their data covers.</p>
     */
    public static String apply(EntityPlayerMP player, int dimensionId) {
        return apply(player, dimensionId, false);
    }

    /**
     * The same, with the two ways of asking told apart.
     *
     * <p>{@code inFlight} is the in-orbit choice: the player is in a rocket that has already left the atmosphere
     * (Galacticraft's own moment for choosing a destination, 6en), so there is nothing to ignite - they are taken to
     * the planet. Without it the request comes from the ground: the destination is remembered and the rocket is
     * ignited, which is the shortcut for a player who already knows where they are going.</p>
     */
    public static String apply(EntityPlayerMP player, int dimensionId, boolean inFlight) {
        MinespacePlanetDimensions.Planet body = bodyOf(dimensionId);
        if (body == null) {
            return deny("这个目标不在星表里");
        }
        int tier = MinespaceResearchData.tierOfLayer(body.layer);
        // A world that does not exist is not a destination. The catalog knows six rows whose dimension id no mod
        // registers - the bodies Galaxy Space has as dimension-less decorations (the four gas giants, Deimos, Barnarda C2)
        // - and Deimos is landable, so the map used to offer it and the arrival used to call changeDimension on a
        // dimension with no world (measured by the 6er standing check). Refused here, where every other refusal lives,
        // with the reason in the message rather than in a stack trace.
        if (body.landable && !net.minecraftforge.common.DimensionManager.isDimensionRegistered(dimensionId)) {
            return deny(body.name + " 的世界还没建成（维度 " + dimensionId + " 未注册）");
        }
        // Whichever gate owns this body decides, on the server, for the same reason the client's copy of the rule
        // exists: a body Galacticraft knows is PlanetProgression's business (one progression, not two), and a body only
        // this pack knows is ours.
        //
        // The one body that needs no gate is the one the player is standing on: it is on their star map whatever their
        // research says (see MinespaceStarMapScreen.bodyUnlocked), so the two sides of this rule have to agree or the
        // map would offer a destination the server refuses.
        if (dimensionId != player.dimension) {
            if (MinespaceCelestialRegistry.registeredByPack(body)) {
                // A body this pack registered has two roads (6er): the telescope's research of it, or this pack's own
                // survey data for its layer. Checked in the same order as the client's copy of the rule.
                if (!MinespacePlanetResearch.surveyedOursOnServer(player, body)
                        && MinespaceResearchData.highestHeld(player) < tier) {
                    return deny("需要 研究数据 " + roman(tier) + "，或先用行星研究（望远镜）观测过 " + body.name);
                }
            } else if (MinespacePlanetResearch.bodyKnownToGalacticraft(dimensionId) != null) {
                if (!MinespacePlanetResearch.surveyedOnServer(player, dimensionId)) {
                    return deny(body.name + " 还没被行星研究（望远镜）观测过");
                }
            } else if (body.layer <= 1) {
                // A row in the sun's own system is PlanetProgression's business, researched one body at a time (6eu) -
                // including the rows whose dimension Galacticraft has no body for, because Galaxy Space registers the
                // gas giants without one and this pack resolves them by name (see MinespacePlanetResearch).
                if (!MinespacePlanetResearch.surveyedSolarOnServer(player, body)) {
                    return deny(body.name + " 还没被行星研究（望远镜）观测过");
                }
            } else if (MinespaceResearchData.highestHeld(player) < tier) {
                return deny("需要 研究数据 " + roman(tier) + " 才能前往 " + body.name);
            }
        }
        Entity ridden = player.getRidingEntity();
        EntityAutoRocket rocket = rocketRiddenBy(player);
        // An in-orbit answer is authorised by the question this pack asked at the atmosphere, not by the riding link:
        // 6ex measured the owner pressing T a minute after the map opened, with the flight already over and "(nothing)"
        // under them. See MinespaceRocketDestinations.tierAwaitingAnswer.
        int askedTier = inFlight
                ? MinespaceRocketDestinations.tierAwaitingAnswer(player.getUniqueID(), player.world.getTotalWorldTime())
                : 0;
        if (rocket == null && askedTier == 0) {
            // Refusing here is rare, and it was once wrong: the owner sat in a Galaxy Space rocket and still got this
            // message (6ex). The line below is the measurement that tells the three cases apart - nothing ridden at
            // all, a vehicle that is not a rocket, or a riding link this pack cannot see - and it is the only place
            // that answer can come from.
            LOG.info("star map: {} (dim {}) asked for {} in flight={} riding {} and not asked to choose - refusing",
                    player.getName(), player.dimension, body.name, inFlight,
                    ridden == null ? "(nothing)" : ridden.getClass().getName());
            if (nearestRocket(player, 8.0D) != null) {
                return deny("你靠近了火箭，但还没坐进去；先右键坐进火箭再按 T");
            }
            return deny("先坐进火箭（" + body.name + " 需要 GC/GS 火箭；当前没有检测到骑乘）");
        }
        int needed = rocketTierForLayer(body.layer);
        int have = rocket instanceof IRocketType ? ((IRocketType) rocket).getRocketTier() : askedTier;
        if (have < needed) {
            return deny(body.name + " 需要 T" + needed + " 火箭，这艘是 T" + have);
        }
        if (rocket != null && !rocket.hasValidFuel()) {
            return deny("燃料不足：先给火箭加满燃料再设定目的地");
        }
        if (inFlight) {
            // The in-orbit choice: Galacticraft's ascent is already done, so the arrival is ours (6en/6eo). No fuel
            // check above and no rocket needed here - the fuel was spent getting up, and the flight may well be over by
            // the time the player answers (6ex). The question is consumed either way.
            EntityAutoRocket arrivalRocket = rocket != null
                    ? rocket
                    : MinespaceRocketDestinations.rocketAwaitingAnswer(player.getUniqueID());
            MinespaceRocketDestinations.answered(player.getUniqueID());
            MinespaceRocketDestinations.transfer(player, body.dimensionId,
                    body.name + "（" + body.nameZh + "）", arrivalRocket);
            // The transfer writes its own line; nothing to add.
            return null;
        }
        rocket.targetDimension = body.dimensionId;
        // Remember it: Galacticraft's own flight will ask for a *frequency* (a landing pad) at the atmosphere, and a
        // body this pack owns has none - so the destination has to be remembered here and taken over there
        // (MinespaceRocketDestinations / MixinEntityTieredRocket).
        MinespaceRocketDestinations.aim(rocket, body.dimensionId);
        // **Ignite it ourselves.** Galacticraft's own launch button is a *destination chooser*: pressing it opens the
        // celestial screen, and the player's pick overwrites whatever target was set - which is exactly what happened
        // when the owner aimed here and launched ("发射后还是正常打开的是 GS 的星图"). So the adapter does the one step
        // the button would have done for a GC destination, and GC's own ascent, atmosphere and transfer do the rest.
        if (!rocket.igniteWithResult()) {
            return deny("火箭未能点火（GC 会说明原因：燃料、发射台或倒计时）");
        }
        Minespace.log().info("Rocket of {} pointed at {} (dimension {}) and ignited",
                player.getName(), body.name, body.dimensionId);
        return TextFormatting.GREEN + "已点火：目的地 " + body.name + "（" + body.nameZh + "）";
    }

    private static EntityAutoRocket nearestRocket(EntityPlayerMP player, double radius) {
        EntityAutoRocket best = null;
        double bestDistance = Double.MAX_VALUE;
        for (Entity entity : player.world.getEntitiesWithinAABB(EntityAutoRocket.class,
                player.getEntityBoundingBox().grow(radius))) {
            double distance = entity.getDistanceSq(player);
            if (distance < bestDistance) {
                bestDistance = distance;
                best = (EntityAutoRocket) entity;
            }
        }
        return best;
    }

    private static String deny(String why) {
        return TextFormatting.RED + "无法前往：" + why;
    }

    private static String roman(int tier) {
        String[] roman = { "", "I", "II", "III", "IV", "V", "VI" };
        return tier >= 1 && tier < roman.length ? roman[tier] : String.valueOf(tier);
    }

    /** Sends a status line to the player's chat; used for both the refusal and the confirmation. */
    public static void tell(EntityPlayerMP player, String message) {
        if (message != null && !message.isEmpty()) {
            player.sendMessage(new TextComponentString(message));
        }
    }
}
