package com.minespace.unofficial.gtceu;

import net.minecraft.client.gui.GuiScreen;
import net.minecraftforge.fml.relauncher.Side;
import net.minecraftforge.fml.relauncher.SideOnly;
import org.lwjgl.input.Keyboard;
import org.lwjgl.input.Mouse;
import org.lwjgl.opengl.GL11;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * The star map, two levels deep: pick a star system, then look at what orbits it.
 *
 * <h2>The shape it imitates, and the shape it refuses to be</h2>
 *
 * Galaxy Space's map works by selecting a system and then showing its bodies, and that is the structure
 * here - a system view and a system-detail view - because 106 bodies at once is a cloud, not a map. What
 * it deliberately does not do is reuse Galacticraft's map to get there: that attempt crashed the client
 * twice (6dq: the galaxy name is a texture path; 6dr: its drawCircles dereferences a system's main star
 * and a body's orbit radius), and both times the cause was a value the other mod's renderer expected and
 * this pack had not supplied. This screen therefore supplies everything it draws, and draws only what it
 * can compute:
 *
 * <ul>
 *   <li><b>Two textures, both this mod's.</b> A star is a tinted copy of a radial-gradient sprite, and
 *       the backdrop is a real nebula photograph crushed to a wisp (see tools\build-starmap-art.ps1,
 *       which generates both). Nothing here is another mod's art, and nothing is drawn with raw GL:
 *       every call goes through the vanilla primitives this screen has already been seen to draw
 *       with.</li>
 *   <li><b>No other mod's objects, no registries.</b> The data is this pack's own generated table.</li>
 *   <li><b>Software projection.</b> Positions are rotated and projected by hand, so nothing depends on GL
 *       matrix state set elsewhere, and picking a body is arithmetic rather than a guess.</li>
 * </ul>
 *
 * <h2>Controls</h2>
 *
 * Left drag to turn, right or middle drag to move the map under the window, WASD or the arrow keys to do the
 * same without a mouse, scroll to zoom, left click to select (a system goes one level in), right click to come
 * back out, R to put the view back the way it started, ESC to close.
 *
 * <h2>Why it fills the frame, and why that is measured</h2>
 *
 * The requirement is that the systems are spread over the whole screen by default. That is what
 * {@link #fitScale} does: every frame it measures how far this layer's nodes reach once rotated by the camera
 * that is about to draw them, and sets the scale so that reach meets the frame. A constant scale cannot - a
 * cloud is wider than it is tall, so the same number is either too small for the sides or too large for the
 * top and bottom, and which one changes as the map turns. The measurement is a 92nd percentile rather than a
 * maximum so that one outlier system cannot shrink everything else, and it is eased between frames so the map
 * does not jump while it turns.
 *
 * <h2>Looking at it without a player</h2>
 *
 * {@code -Dminespace.starmap.capture=<directory>} turns this screen into a camera: the screen opens
 * itself at the main menu, draws both levels, writes each one to a PNG in that directory and quits the
 * game. There is no way to check a render from outside the client, and every visual bug this screen has
 * had was found by a client restart; this is what replaces that, and it is deliberately a run-time flag
 * rather than a build-time one, so the shipped jar behaves exactly as a player would see it.
 */
@SideOnly(Side.CLIENT)
public class MinespaceStarMapScreen extends GuiScreen {

    private static final int[] LAYER_COLORS = {
            0xFFFFFF, 0xFFFFFF, 0x9BD4FF, 0x7FE07F, 0xFFD37F, 0xFF9F6E, 0xFF6E9F, 0xC79BFF
    };
    private static final String[] LAYER_LABELS = {
            // "LuV-ZPM", not "LuV~ZPM": the vanilla font has no tilde and drew the label as "LuV^ZPM".
            // Layer 1 is the solar system itself - the bodies Galacticraft and Galaxy Space own - so its name is not
            // blank: the card used to read "· stage 0" for every body of it.
            "", "1 太阳系 (IV)", "2 近邻 (IV)", "3 中距 (LuV-ZPM)", "4 远距 (UV)", "5 深空 (UHV)",
            "6 超深空 (UHV+)", "7 未知 (UHV+)"
    };

    /** Tier numerals for the gate's card lines. Tier I is layer 2; tier VI is layer 7. */
    private static final String[] ROMAN = { "", "I", "II", "III", "IV", "V", "VI" };

    /**
     * The legend's own heading: it lists the layers of the catalog and marks the ones nothing is charted in yet.
     *
     * <p>It named the survey data until 6er, when PlanetProgression's research also began to open this pack's bodies -
     * after which "which data the player is carrying" was no longer the answer to "is this layer open", and the legend
     * said 未解锁 about every layer of a chart that was fully drawn.</p>
     */
    private static final String LEGEND_CAPTION = "星层（亮 = 已测绘）：";

    /** This mod's own radial-gradient glow, white so that tinting it is what colours a star. */
    private static final net.minecraft.util.ResourceLocation GLOW_TEXTURE =
            new net.minecraft.util.ResourceLocation("minespace", "textures/gui/star_glow.png");

    /** The backdrop: a nebula photograph, blurred until only its wisps are left. See the tool script. */
    private static final net.minecraft.util.ResourceLocation NEBULA_TEXTURE =
            new net.minecraft.util.ResourceLocation("minespace", "textures/gui/nebula.png");

    /** Grain for the backdrop: how many distant stars, and where they sit. */
    private static final int DUST_COUNT = 520;

    /** The mod's own log channel, so a star map line is findable in a client log by the same name. */
    private static final org.apache.logging.log4j.Logger LOG =
            org.apache.logging.log4j.LogManager.getLogger("minespace");

    /** One drawable thing: a system on the first level, a body on the second. */
    private static final class Node {
        final MinespacePlanetDimensions.Planet body;
        final String systemKey;
        final int bodyCount;

        Node(MinespacePlanetDimensions.Planet body, String systemKey, int bodyCount) {
            this.body = body;
            this.systemKey = systemKey;
            this.bodyCount = bodyCount;
        }
    }

    private static final List<Node> SYSTEMS = buildSystems();
    private static final Map<String, List<MinespacePlanetDimensions.Planet>> BY_SYSTEM = buildBySystem();
    /** The same bodies, wrapped as nodes, so both levels draw from one list type. */
    private static final Map<String, List<Node>> NODES_BY_SYSTEM = buildNodesBySystem();
    /** Where each system sits on the first level, laid out once. */
    private static final Map<String, float[]> LAYOUT = buildLayout();

    /** How far the chart reaches from home, in layout units - the pan limit is built from it. */
    private static final float LAYOUT_REACH = layoutReach();

    /** How many of the systems are not systems at all: a body that is its own object, with no star to orbit. */
    private static final int LONE_OBJECTS = countLoneObjects();

    private static int countLoneObjects() {
        int count = 0;
        for (int i = 0; i < SYSTEMS.size(); i++) {
            if (SYSTEMS.get(i).body.star.isEmpty()) {
                count++;
            }
        }
        return count;
    }

    private static float layoutReach() {
        float reach = 1.0F;
        for (Map.Entry<String, float[]> entry : LAYOUT.entrySet()) {
            float[] p = entry.getValue();
            reach = Math.max(reach, (float) Math.sqrt(p[0] * p[0] + p[1] * p[1] + p[2] * p[2]));
        }
        return reach;
    }

    /**
     * Where a layer's band starts, in layout units. Home is 0; layer 2 starts at 0.55 and every band is 1.7 times
     * further out than the one before, so the seven layers read as a chart from here outward and nothing lands
     * between two of them.
     */
    private static float bandInner(int layer) {
        if (layer <= 2) {
            return 0.55F;
        }
        float value = 0.55F;
        for (int i = 2; i < layer; i++) {
            value *= 1.7F;
        }
        return value;
    }

    private int level;
    private int openedSystem = -1;
    private int selected = -1;

    /**
     * The drawn camera, and the camera the input is asking for.
     *
     * <p>Two sets of angles rather than one is the whole of the smoothing: a drag moves the target and the
     * drawn value follows it a frame behind, so a flick of the mouse turns the cloud rather than teleporting
     * it, and the last drag keeps turning for a moment after the button is released (see {@link #spinYaw}).</p>
     */
    private float yaw = 0.6F;
    private float pitch = 0.35F;
    private float zoom = 1.0F;
    private float targetYaw = 0.6F;
    private float targetPitch = 0.35F;
    private float targetZoom = 1.0F;
    private float spinYaw;
    private float spinPitch;

    /**
     * The map's position on the screen, in GUI pixels, and the one being asked for - panning moves these.
     *
     * <p>Panning is what turns a map into something you can *look at* rather than only turn: zooming in on an
     * interesting corner and then dragging it to the middle of the screen is the move the owner asked for, and
     * there is no way to do it by rotating a sphere.</p>
     */
    private float panX;
    private float panY;
    private float targetPanX;
    private float targetPanY;
    private float spinPanX;
    private float spinPanY;

    /**
     * The scale that makes each layer fill the frame, eased between frames - one per layer, because seventy
     * seven systems and one system's seven bodies do not fit at the same size, and the cross-fade draws both
     * at once.
     *
     * <p>Computed from the nodes rather than fixed: a cloud is wider than it is tall, so a constant scale
     * either wastes the sides or pushes the top and bottom off screen - and which of the two depends on how
     * the cloud is turned, which changes as the owner drags. Fitting to a high percentile of the projected
     * extent (not the maximum: one outlier system should not shrink everything else) is what keeps the
     * promise "spread over the whole screen" at every angle.</p>
     */
    private float fittedOverview = -1.0F;
    private float fittedSystem = -1.0F;
    private float frameDt = 0.016F;

    /**
     * The camera.
     *
     * <p>{@code viewFocal} is pixels per unit at the reference distance, {@code viewDistance} is how far the
     * camera is from the middle of the map in layout units, and {@code referenceDistance} is the distance the
     * frame was fitted for. Zooming changes {@code viewDistance} only, which is the whole difference between a
     * picture that grows and a camera that moves: at the reference distance the projection is exactly the old
     * orthographic one, and every step of zoom away from it makes the near stars larger than the far ones.</p>
     */
    private float viewFocal = 1.0F;
    private float viewDistance = 10.0F;
    private float referenceDistance = 10.0F;

    /** How far the camera stands back from the map, as a multiple of the map's own reach. */
    private static final float PERSPECTIVE_REACH = 2.6F;
    /** Nothing inside this fraction of the reference distance of the camera is drawn: it is past the eye. */
    private static final float NEAR_PLANE_FRACTION = 0.02F;
    /**
     * How fast the wheel flies, as an exponent on distance: one notch is a fixed *ratio* of distance, not a
     * fixed number of units - which is the only way a chart whose near layer is a unit out and whose far layer is
     * seven units out can be travelled at all. A fixed minimum distance was the first version of this and it made
     * the last half of the wheel dead in a system's own view.
     */
    private static final float DOLLY_SPEED = 1.0F;
    /**
     * Stop the camera this far from the middle of the map, as a fraction of the reference distance. Flown in to
     * 0.45 the map is 2.2 times larger than it was - a real approach, and the flight from the far end to this one is
     * a factor of 4.9 in distance - while flown back to 2.2 the same map is a chart of the whole neighbourhood.
     * Going deeper was tried twice: the near stars leave the frame faster than new ones arrive and the destination
     * is an empty screen, because seventy-seven systems do not fill a volume the way a galaxy does.
     */
    private static final float MIN_DISTANCE_FRACTION = 0.45F;
    /** ... and this far out, so that pulling back cannot leave the map as a speck. */
    private static final float MAX_DISTANCE_FRACTION = 2.2F;
    /** A system's own reach, in layout units (its outermost orbit). */
    private static final float SYSTEM_REACH = 1.05F;

    /** The node the button went down on, and whether the press has turned into a drag since. */
    private int pressedNode = -1;
    private boolean dragMoved;
    private int pressX;
    private int pressY;

    /**
     * The level change, as a fade: 0 is the frame the input asked for it, 1 is settled.
     *
     * <p>{@link #pendingLevel} is applied in the middle of it, where the two layers are least visible, so the
     * map never draws a half-changed state. -1 means nothing is pending.</p>
     */
    private float transition = 1.0F;
    private int pendingLevel = -1;
    private int pendingSystem = -1;
    private static final float TRANSITION_SECONDS = 0.42F;

    /** 0 to 1 as the screen opens: the map fades up from black instead of appearing. */
    private float openFade;

    /** Seconds since the screen opened, and the previous frame's timestamp, for everything time-based. */
    private float clock;
    private long lastFrameNanos;

    /** Eases toward 1 while the cursor is over a node, so the highlight grows instead of blinking on. */
    private float hoverGlow;
    private int hovered = -1;
    private int mouseXNow;
    private int mouseYNow;

    /**
     * The highest research-data tier the player is carrying, and the gate it drives.
     *
     * <p>Read from the player's own inventory every frame: a piece of survey data is a key, not a consumable, and the
     * map must be able to answer "may I go there" without asking the server. Tier I opens layer 2, tier VI layer 7 -
     * the star system tiers the owner asked for, which are the layers' own voltage bands (see
     * {@link MinespaceResearchData}).</p>
     */
    private int unlockedTier;

    /** When the last refused click happened, in screen seconds - 0 means none, and the hint fades after a while. */
    private float lockedHint;

    /** Why the last `T` was refused, shown under the map for a few seconds. Null when the last one worked. */
    private String refusal;

    /** Says why, in the same place every time: a key press that does nothing reads as a bug. */
    private void refuse(String why) {
        refusal = why;
        lockedHint = clock;
    }

    /** The gate's reason for a body, or null when it may be travelled to. */
    private String whyNot(Node node) {
        if (!node.body.landable) {
            return "该天体不可登陆（" + node.body.name + "）";
        }
        if (locked(node)) {
            if (com.minespace.unofficial.galacticraft.MinespaceCelestialRegistry.registeredByPack(node.body)) {
                // A body this pack registered has two roads in (see computeUnlocked), so a refusal names both.
                return "还没解锁 " + node.body.name + "：需要 研究数据 "
                        + ROMAN[MinespaceResearchData.tierOfLayer(node.body.layer)]
                        + "，或先用行星研究（望远镜）观测过它";
            }
            return gateIsPlanetProgression(node)
                    ? "行星研究（望远镜）还没观测过 " + node.body.name
                    : "需要 研究数据 " + ROMAN[MinespaceResearchData.tierOfLayer(node.body.layer)]
                            + " 才能前往 " + node.body.name;
        }
        return null;
    }

    /**
     * True while this screen is the in-orbit destination chooser.
     *
     * <p>Galacticraft's flow ends with a choice (6en: `onReachAtmosphere` when there is no pad frequency), and this
     * pack draws that choice with its own map instead of GC's celestial screen. The flag changes what `T` means - from
     * "remember this and ignite" on the ground to "take me there now" in orbit - and what the hint says.</p>
     */
    private static boolean choosingDestination;

    /** Called from the client-side handler of {@code OpenStarMapMessage}. */
    public static void openForChoice() {
        choosingDestination = true;
        net.minecraft.client.Minecraft.getMinecraft().displayGuiScreen(new MinespaceStarMapScreen());
    }

    /**
     * True when nothing has charted this node yet - and a node that is not charted is **not drawn at all**.
     *
     * <p>The owner's rule for this screen is that the star map *is* the progression. So a locked node is hidden
     * rather than greyed - no sphere, no name, no pixel the cursor can land on - which is why every consumer of this
     * screen (the drawing, the labels, the picking, the orbit rings, the card and the frame fit) asks this one
     * question instead of each inventing its own idea of "reachable".</p>
     */
    private boolean locked(Node node) {
        // A system node stands for several bodies, so it is open when **any** of them is: one unsurveyed body (the
        // solar system's representative is Mercury, which PlanetProgression does not list) must not close the whole
        // system its surveyed neighbours live in. That is what made "the solar system is not unlocked" possible while
        // the Moon and Mars inside it were.
        if (node.bodyCount > 1 && node.systemKey != null) {
            java.util.List<MinespacePlanetDimensions.Planet> bodies = BY_SYSTEM.get(node.systemKey);
            if (bodies != null) {
                for (MinespacePlanetDimensions.Planet body : bodies) {
                    if (bodyUnlocked(body)) {
                        return false;
                    }
                }
            }
            return true;
        }
        return !bodyUnlocked(node.body);
    }

    /**
     * Body dimension id -> whether it is on the chart, for the frame being drawn. Emptied once a frame by
     * {@link #refreshGate}.
     *
     * <p>Not an optimisation but a correctness device: the same question is asked by the drawing, the picking, the
     * frame fit, the counters and the card, and a body that counted as charted in one of those and not in another
     * would show up as a star the cursor cannot touch or a click that answers about a different body. One answer per
     * frame, given once.</p>
     */
    private final java.util.Map<Integer, Boolean> gateThisFrame = new java.util.HashMap<Integer, Boolean>();

    /** One body's own gate: PlanetProgression's research where Galacticraft knows the world, our data where it does not. */
    private boolean bodyUnlocked(MinespacePlanetDimensions.Planet body) {
        Integer key = Integer.valueOf(body.dimensionId);
        Boolean cached = gateThisFrame.get(key);
        if (cached != null) {
            return cached.booleanValue();
        }
        boolean unlocked = computeUnlocked(body);
        gateThisFrame.put(key, Boolean.valueOf(unlocked));
        return unlocked;
    }

    private boolean computeUnlocked(MinespacePlanetDimensions.Planet body) {
        // The world the map is being read from is always on it, whatever the gate says. A chart that does not show
        // where it is read from is not a chart, and without this a player with no research at all would open this
        // screen on an empty black field - which reads as "this screen is broken" rather than "nothing is unlocked
        // yet". Galacticraft's own map does the same thing: it is centred on the planet the player stands on.
        if (body.dimensionId == currentDimension()) {
            return true;
        }
        // One body, one question, and the answer depends on who made the body - not on the layer it sits in:
        //
        //   * a body this pack registered (6er) has **two roads**: PlanetProgression's research of it - which the
        //     telescope, a research paper and `unlockAllCelestialBodies` all reach, because the body is in Galacticraft's
        //     registry now - or this pack's own survey data for its layer. The data item is a shortcut, the telescope is
        //     the road.
        //   * a body Galacticraft or Galaxy Space made has exactly one road, theirs: if that research has surveyed the
        //     Moon, the Moon is open here too - one progression, not two (see MinespacePlanetResearch).
        //   * and a row in the sun's own system is theirs even where the catalog owns the dimension (the four gas giants
        //     and Deimos, which Galaxy Space registers with no dimension at all - 6eq), so it is charted with the system.
        if (com.minespace.unofficial.galacticraft.MinespaceCelestialRegistry.registeredByPack(body)) {
            return body.layer <= 1
                    ? systemSurveyed(body) || tierGate(body.layer)
                    : surveyedOurs(body) || tierGate(body.layer);
        }
        if (com.minespace.unofficial.galacticraft.MinespacePlanetResearch
                .bodyKnownToGalacticraft(body.dimensionId) != null) {
            return surveyed(body.dimensionId);
        }
        return systemSurveyed(body) || tierGate(body.layer);
    }

    /** This pack's own survey data covers this layer, once the capture's stand-in has had its say. */
    private boolean tierGate(int layer) {
        return MinespaceResearchData.tierOfLayer(layer) <= unlockedTier;
    }

    /** Has the pack's planet research surveyed this row? (For a row this pack did not register, false.) */
    private boolean surveyedOurs(MinespacePlanetDimensions.Planet row) {
        if (CAPTURE_DIR != null) {
            // A camera has no player: it stands in for "PlanetProgression has surveyed everything" unless told not to,
            // which is the state the owner is in after unlocking everything (see CAPTURE_PP).
            return CAPTURE_PP;
        }
        return com.minespace.unofficial.galacticraft.MinespacePlanetResearch
                .surveyedOursOnClient(mc == null ? null : mc.player, row);
    }

    /** PlanetProgression's answer for one dimension, or the capture run's stand-in for it (see CAPTURE_TIER). */
    private boolean surveyed(int dimensionId) {
        if (CAPTURE_DIR != null) {
            return CAPTURE_PP;
        }
        return com.minespace.unofficial.galacticraft.MinespacePlanetResearch
                .surveyedOnClient(mc == null ? null : mc.player, dimensionId);
    }

    /** Per-frame answers for {@link #systemSurveyed}, keyed by system - a system's state is asked about by every row. */
    private final java.util.Map<String, Boolean> systemSurveyedThisFrame =
            new java.util.HashMap<String, Boolean>();

    /** True when the pack's planet research has surveyed this row's own system (see the layer-1 case above). */
    private boolean systemSurveyed(MinespacePlanetDimensions.Planet body) {
        String key = com.minespace.unofficial.galacticraft.MinespacePlanetResearch.systemKeyOf(body);
        Boolean cached = systemSurveyedThisFrame.get(key);
        if (cached != null) {
            return cached.booleanValue();
        }
        boolean surveyed = CAPTURE_DIR != null
                ? CAPTURE_PP
                : com.minespace.unofficial.galacticraft.MinespacePlanetResearch
                        .systemSurveyedOnClient(mc == null ? null : mc.player, body);
        systemSurveyedThisFrame.put(key, Boolean.valueOf(surveyed));
        return surveyed;
    }

    /**
     * How many of a body's moons are on the chart, which is what decides whether its halo ring is drawn.
     *
     * <p>The ring is the answer to "which body does this moon go round" (see {@code drawLayer}), so it belongs to the
     * moons that are drawn: a halo around a planet whose moons have not been surveyed yet would be a ring around
     * nothing, and a ring around nothing is a bug to the eye even when every number behind it is right.</p>
     */
    private int visibleMoons(MinespacePlanetDimensions.Planet parent) {
        int count = 0;
        for (MinespacePlanetDimensions.Planet body : MinespacePlanetDimensions.PLANETS) {
            if (body.parent.equals(parent.name) && bodyUnlocked(body)) {
                count++;
            }
        }
        return count;
    }

    /** True when this node's gate is the pack's planet research rather than this pack's own survey data. */
    private static boolean gateIsPlanetProgression(Node node) {
        return com.minespace.unofficial.galacticraft.MinespacePlanetResearch
                .gateIsPlanetProgression(node.body);
    }

    /**
     * Reads the gate once, at the top of a frame: how much research data the player is carrying, and then a clean
     * slate for the per-body answers (see {@link #gateThisFrame}).
     */
    private void refreshGate() {
        unlockedTier = CAPTURE_DIR == null
                ? MinespaceResearchData.highestHeld(mc == null ? null : mc.player)
                : CAPTURE_TIER;
        gateThisFrame.clear();
        systemSurveyedThisFrame.clear();
        // Which layers have anything charted in them, once a frame: the legend used to answer that question with the
        // survey data the player is carrying, and since 6er that is only one of the two roads into a body - a chart whose
        // every layer is drawn and whose legend says every layer is locked is a legend that lies about the map it sits on.
        layerCharted = new boolean[LAYER_LABELS.length];
        for (MinespacePlanetDimensions.Planet body : MinespacePlanetDimensions.PLANETS) {
            int layer = Math.max(0, Math.min(layerCharted.length - 1, body.layer));
            if (bodyUnlocked(body)) {
                layerCharted[layer] = true;
            }
        }
    }

    /** Which layers have anything charted in them, recomputed once a frame by {@link #refreshGate}. */
    private boolean[] layerCharted = new boolean[LAYER_LABELS.length];

    /** True when at least one body of this layer is on the chart. */
    private boolean layerCharted(int layer) {
        return layer >= 0 && layer < layerCharted.length && layerCharted[layer];
    }

    /** The dimension the map is being read from, or a value no catalog body can have when nobody is playing. */
    private int currentDimension() {
        return mc == null || mc.player == null ? Integer.MIN_VALUE : mc.player.dimension;
    }

    private int dragging = -1;
    private int lastX;
    private int lastY;

    /** Where the self-portrait below writes its frames, or null - which it is for every player. */
    private static final String CAPTURE_DIR = System.getProperty("minespace.starmap.capture");

    /**
     * What a capture run pretends the player is carrying, so that a camera with no player can photograph a chart.
     *
     * <p>A capture opens this screen at the main menu, where there is no player, no inventory and therefore no
     * research data - and since a locked body is not drawn (that is the rule this whole screen is built around), the
     * camera would photograph an empty screen and prove nothing. The camera is therefore told two things: a body
     * Galacticraft owns counts as surveyed (nobody is there to have PlanetProgression's state), and it holds this much
     * of this pack's own data. So the default 6 is the whole chart; 0 is the owner's own state after unlocking
     * everything in PlanetProgression - the sun's system complete, no exoplanet; and {@code -1} applies no override at
     * all, which is how the empty chart is photographed to check that the hiding works.</p>
     */
    private static final int CAPTURE_TIER = Integer.getInteger("minespace.starmap.capture.tier", 6).intValue();

    /**
     * Whether a capture run photographs the chart as PlanetProgression has surveyed everything - the default, and the
     * state the owner is in after its unlock-all command, which now covers this pack's own bodies too (6er).
     *
     * <p>{@code -Dminespace.starmap.capture.pp=false} is the other half of the picture: the camera then holds only this
     * pack's survey data, which is how the data-item road is photographed on its own.</p>
     */
    private static final boolean CAPTURE_PP =
            Boolean.parseBoolean(System.getProperty("minespace.starmap.capture.pp", "true"));

    /**
     * Which system a capture run photographs, by name (a substring, case-insensitive). Empty means the solar system,
     * which is the default because it is the one whose rings carry real distances, whose moons have planets to orbit
     * and whose planets have periods - but a claim like "the middle of a black hole is a black hole now" can only be
     * checked by photographing one.
     */
    private static final String CAPTURE_SYSTEM =
            System.getProperty("minespace.starmap.capture.system", "");
    private int captureFrames;
    private int captureStep;
    private int captureWait;
    private int capturePointer = -1;
    private boolean captureFinished;

    /** The view for this frame, set at the top of {@link #drawScreen} and shared by everything drawn. */
    private float viewCosYaw;
    private float viewSinYaw;
    private float viewCosPitch;
    private float viewSinPitch;
    private float viewScale;

    /**
     * How far the cloud is stretched along x and z.
     *
     * <p>A GUI is about twice as wide as it is tall, and a *sphere* of stars cannot fill one without either
     * wasting the sides or being stretched flat at draw time. Stretching the layout instead keeps the
     * projection honest: what is on screen is one wide ellipsoid - a cloud, which is the shape the map is
     * imitating - and turning it looks like turning an object rather than like a drawing that squashes.</p>
     */
    private static final float CLOUD_X = 1.45F;
    private static final float CLOUD_Y = 0.80F;
    private static final float CLOUD_Z = 1.30F;

    /** The system the player is in - home, and the one marker on the map that is not a destination. */
    private static final int HOME_SYSTEM = findSystem("Sol");

    private static int findSystem(String key) {
        for (int i = 0; i < SYSTEMS.size(); i++) {
            if (SYSTEMS.get(i).systemKey.equalsIgnoreCase(key)) {
                return i;
            }
        }
        return -1;
    }

    /** Screen positions of the current level's nodes, refreshed each frame and reused for picking. */
    private final List<float[]> onScreen = new ArrayList<>();

    /** The nodes the active layer is drawing - what the cursor and the card are referring to. */
    private List<Node> activeNodes;

    /** Distant stars: a fixed grain in the unit square, scrolled by the view and wrapped at the edges. */
    private static final float[][] DUST = buildDust();

    /**
     * True when this run was started to photograph the map rather than to play it. Read by
     * {@link MinespaceStarMapKey} to open the screen by itself at the main menu.
     */
    public static boolean captureRequested() {
        return CAPTURE_DIR != null;
    }

    private static float[][] buildDust() {
        float[][] dust = new float[DUST_COUNT][3];
        for (int i = 0; i < DUST_COUNT; i++) {
            // noise(), not hash("du" + i): the string hash advances by a small amount for successive
            // indices, so 520 of them came out as a diagonal line of stars across the sky. A counter
            // needs a mixer, and hash() is for the handful of layout keys where being small is the point.
            dust[i][0] = noise(i, 1);
            dust[i][1] = noise(i, 2);
            // Squared, so most of the grain is faint and a handful of stars stand out: an even spread
            // reads as noise, a weighted one reads as sky.
            dust[i][2] = (float) (0.22D + 0.78D * Math.pow(noise(i, 3), 2.0D));
        }
        return dust;
    }

    /**
     * A counter-to-float scramble: the xorshift-multiply mix every procedural-graphics code uses for this,
     * because the obvious "hash the index" version (see {@link #hash}) does not decorrelate neighbours and
     * this screen's sky is 520 neighbours.
     */
    private static float noise(int index, int salt) {
        int x = index * 374761393 + salt * 668265263;
        x = (x ^ (x >>> 13)) * 1274126177;
        x ^= x >>> 16;
        return (x & 0x7FFFFFFF) / (float) 0x7FFFFFFF;
    }

    private static String keyOf(MinespacePlanetDimensions.Planet body) {
        return body.star.isEmpty() ? body.name : body.star;
    }

    private static List<Node> buildSystems() {
        Map<String, MinespacePlanetDimensions.Planet> first = new LinkedHashMap<>();
        Map<String, Integer> counts = new LinkedHashMap<>();
        for (MinespacePlanetDimensions.Planet body : MinespacePlanetDimensions.PLANETS) {
            String key = keyOf(body);
            if (!first.containsKey(key)) {
                first.put(key, body);
                counts.put(key, 1);
            } else {
                counts.put(key, counts.get(key) + 1);
            }
        }
        List<Node> nodes = new ArrayList<>();
        for (Map.Entry<String, MinespacePlanetDimensions.Planet> entry : first.entrySet()) {
            nodes.add(new Node(entry.getValue(), entry.getKey(), counts.get(entry.getKey())));
        }
        return nodes;
    }

    private static Map<String, List<Node>> buildNodesBySystem() {
        Map<String, List<Node>> map = new LinkedHashMap<String, List<Node>>();
        for (Map.Entry<String, List<MinespacePlanetDimensions.Planet>> entry : BY_SYSTEM.entrySet()) {
            List<Node> nodes = new ArrayList<Node>();
            for (MinespacePlanetDimensions.Planet body : entry.getValue()) {
                nodes.add(new Node(body, entry.getKey(), 1));
            }
            map.put(entry.getKey(), nodes);
        }
        return map;
    }

    /**
     * The first level's layout: one cloud in three dimensions, not six rings in a plane.
     *
     * <p>The first version gave each system a radius from its layer and then spread the systems of that
     * layer around the circle at that radius, with a vertical wobble of a twentieth of the radius. Every
     * system therefore sat in the same plane, and the plane is what the owner saw: "还是一个大甜甜圈布局" -
     * a doughnut, wide and flat, with the screen's top and bottom empty. A star map reads as *space* only
     * when the stars have depth, so positions now come from a Fibonacci sphere - the standard way to spread
     * n points over a sphere, and one that never lines successive indices up - with the layer deciding the
     * shell the point sits in and a jitter wide enough (0.82..1.24 of the shell) that the shells blur into
     * one cloud instead of reading as onion layers.</p>
     *
     * <p>The consequence worth knowing: with the points spread over a volume, the projection can no longer
     * be scaled by a single number if the GUI is wider than it is tall - see {@link #project}. That is why
     * this method returns a sphere and the projection does the stretching.</p>
     */
    private static Map<String, float[]> buildLayout() {
        Map<String, float[]> layout = new LinkedHashMap<String, float[]>();
        int count = SYSTEMS.size();
        float span = LAYER_COLORS.length - 3.0F;
        for (int s = 0; s < count; s++) {
            Node node = SYSTEMS.get(s);
            int layer = Math.max(2, Math.min(LAYER_COLORS.length - 1, node.body.layer));
            if (node.systemKey.equalsIgnoreCase("Sol")) {
                // Home is the middle of the chart, not one ring among many: every distance on this map is
                // measured from here, and the owner asked for the solar system to be arranged that way.
                layout.put(node.systemKey, new float[] { 0.0F, 0.0F, 0.0F });
                continue;
            }
            // Geometric, not linear: layer 2 is next door and layer 7 is the edge of the chart. A linear ramp
            // put the unknown systems in the same view as the near ones, and the owner's map has a *journey* in
            // it - "滚轮缩放/平移，直到看到未知星系" - which needs the far layers to actually be far.
            // Layer L owns an *annulus*, and no two annuli touch: home sits at the middle and the chart reads
            // outward from it, which is what the owner asked for - "这些星系的排布由近到远". The bands grow
            // geometrically (1.7x per layer) so the far layers are genuinely far, and inside a band the radius is
            // uniform in *area* (sqrt of the interpolation), so a ring of stars is an even ring rather than one
            // crowded at its inner edge.
            float inner = bandInner(layer);
            float outer = bandInner(layer + 1);
            float unit = (float) hash(node.systemKey);
            float radius = (float) Math.sqrt(inner * inner + unit * (outer * outer - inner * inner));
            double y = 1.0D - 2.0D * (s + 0.5D) / count;
            double ring = Math.sqrt(Math.max(0.0D, 1.0D - y * y));
            double angle = s * 2.39996D;
            layout.put(node.systemKey, new float[] {
                    (float) (Math.cos(angle) * ring * radius * CLOUD_X),
                    (float) (y * radius * CLOUD_Y),
                    (float) (Math.sin(angle) * ring * radius * CLOUD_Z)
            });
        }
        return layout;
    }

    private static Map<String, List<MinespacePlanetDimensions.Planet>> buildBySystem() {
        Map<String, List<MinespacePlanetDimensions.Planet>> map = new LinkedHashMap<>();
        for (MinespacePlanetDimensions.Planet body : MinespacePlanetDimensions.PLANETS) {
            // Explicit type argument: the diamond through computeIfAbsent does not infer under this
            // project's compiler settings ("inferred type does not conform to bounds").
            List<MinespacePlanetDimensions.Planet> forSystem =
                    map.get(keyOf(body));
            if (forSystem == null) {
                forSystem = new ArrayList<MinespacePlanetDimensions.Planet>();
                map.put(keyOf(body), forSystem);
            }
            forSystem.add(body);
        }
        // Real distance first. A system whose bodies carry an orbital distance is laid out in that order, which is
        // what makes the solar system read Mercury-outward instead of "whatever order the table was generated in" -
        // the owner's note, and the reason the card and the table now carry an AU figure at all.
        for (List<MinespacePlanetDimensions.Planet> forSystem : map.values()) {
            java.util.Collections.sort(forSystem, new java.util.Comparator<MinespacePlanetDimensions.Planet>() {
                @Override
                public int compare(MinespacePlanetDimensions.Planet a, MinespacePlanetDimensions.Planet b) {
                    float keyA = a.orbitAu > 0.0F ? a.orbitAu : Float.MAX_VALUE;
                    float keyB = b.orbitAu > 0.0F ? b.orbitAu : Float.MAX_VALUE;
                    return keyA < keyB ? -1 : keyA > keyB ? 1 : 0;
                }
            });
        }
        return map;
    }

    @Override
    public void drawScreen(int mouseX, int mouseY, float partialTicks) {
        advanceAnimation();
        mouseXNow = mouseX;
        mouseYNow = mouseY;
        if (CAPTURE_DIR != null) {
            applyCapturePointer();
        }

        drawDefaultBackground();
        drawBackdrop();
        drawStarDust();

        // Both layers are drawn while a change is in flight, each fading as the other arrives. The system
        // layer always shows the system being moved *to*, which is what makes the two cross-fade into one
        // move instead of one state being replaced by another.
        // transition is progress through a change (0 just started, 1 settled), *not* which level is showing,
        // so which layer is arriving decides which of the two alphas climbs. Getting this backwards is silent:
        // the map draws its background and nothing else, which is exactly what the first capture of this
        // version showed.
        float eased = ease(transition);
        int shownSystem = pendingSystem >= 0 ? pendingSystem : openedSystem;
        boolean arrivingSystem = pendingLevel == 1 || pendingLevel < 0 && level == 1;
        float alphaOverview = arrivingSystem ? 1.0F - eased : eased;
        float alphaSystem = 1.0F - alphaOverview;
        if (alphaOverview > 0.001F) {
            drawLayer(SYSTEMS, true, shownSystem, alphaOverview, 1.0F + 0.55F * alphaSystem, level == 0);
        }
        if (alphaSystem > 0.001F) {
            drawLayer(nodesOfSystem(shownSystem), false, shownSystem, alphaSystem,
                    1.0F + 0.55F * alphaOverview, level == 1);
        }

        // The two layers are half-visible at the same time in the middle of the change, and half of each is
        // not a picture of anything. A dip makes that moment deliberate.
        float dip = (1.0F - Math.abs(eased * 2.0F - 1.0F)) * 0.42F;
        if (dip > 0.002F) {
            drawRect(0, 0, width, height, withAlpha(0x000000, dip));
        }

        float active = level == 0 ? alphaOverview : alphaSystem;
        if (active > 0.02F) {
            drawReadouts(active);
            Node tip = tipNode();
            if (tip != null) {
                // Pinned to the selected star when the cursor is off the map, otherwise under the cursor.
                boolean pinned = hovered < 0 && selected >= 0 && !Float.isNaN(onScreen.get(selected)[0]);
                float atX = pinned ? onScreen.get(selected)[0] : mouseXNow;
                float atY = pinned ? onScreen.get(selected)[1] : mouseYNow;
                drawTooltip(tip, level == 0, atX, atY,
                        active * (pinned ? 1.0F : Math.max(0.4F, hoverGlow)));
            }
        }

        if (CAPTURE_DIR != null) {
            captureTick();
        }

        // Last, so it covers the readouts too: the map arrives out of black rather than being switched on.
        if (openFade < 1.0F) {
            drawRect(0, 0, width, height, withAlpha(0x000000, 1.0F - openFade));
        }
    }

    /**
     * Moves everything that is animated, once per frame.
     *
     * <p>Time comes from {@code System.nanoTime} rather than from the frame count, so the motion is the same
     * whether the client is drawing at 60 or at 20 frames a second, and every easing here is written as
     * {@code 1 - exp(-dt * rate)} rather than as a fixed fraction per frame for the same reason. The delta is
     * clamped: after a stall (a chunk load, a GC pause) a single huge step would teleport the camera.</p>
     */
    private void advanceAnimation() {
        long now = System.nanoTime();
        float dt = lastFrameNanos == 0L ? 0.016F : (now - lastFrameNanos) / 1.0e9F;
        lastFrameNanos = now;
        dt = Math.max(0.0F, Math.min(0.1F, dt));
        frameDt = dt;
        clock += dt;
        refreshGate();

        // A released drag keeps turning, slowing down. This is what separates "the map followed my mouse" from
        // "the map is a thing I am spinning".
        if (dragging < 0 && (Math.abs(spinYaw) > 0.02F || Math.abs(spinPitch) > 0.02F)) {
            targetYaw += spinYaw * dt;
            targetPitch = clampPitch(targetPitch + spinPitch * dt);
            float decay = (float) Math.exp(-dt * 3.2F);
            spinYaw *= decay;
            spinPitch *= decay;
        }

        float follow = 1.0F - (float) Math.exp(-dt * 14.0F);
        yaw += (targetYaw - yaw) * follow;
        pitch += (targetPitch - pitch) * follow;
        zoom += (targetZoom - zoom) * follow;
        panX += (targetPanX - panX) * follow;
        panY += (targetPanY - panY) * follow;

        if (dragging < 0 && (Math.abs(spinPanX) > 0.5F || Math.abs(spinPanY) > 0.5F)) {
            targetPanX += spinPanX * dt;
            targetPanY += spinPanY * dt;
            float decay = (float) Math.exp(-dt * 3.6F);
            spinPanX *= decay;
            spinPanY *= decay;
            clampPan();
        }

        hoverGlow += ((hovered >= 0 ? 1.0F : 0.0F) - hoverGlow)
                * (1.0F - (float) Math.exp(-dt * 12.0F));
        openFade = Math.min(1.0F, openFade + dt / 0.45F);

        if (transition < 1.0F) {
            float before = transition;
            transition = Math.min(1.0F, transition + dt / TRANSITION_SECONDS);
            if (pendingLevel >= 0 && before < 0.5F && transition >= 0.5F) {
                level = pendingLevel;
                if (pendingSystem >= 0) {
                    openedSystem = pendingSystem;
                }
                selected = -1;
                pendingLevel = -1;
                pendingSystem = -1;
            }
        }
    }

    private static float ease(float t) {
        float x = Math.max(0.0F, Math.min(1.0F, t));
        return x * x * (3.0F - 2.0F * x);
    }

    private static float clampPitch(float value) {
        return Math.max(-1.4F, Math.min(1.4F, value));
    }

    /** One astronomical unit in light years, and one light year in kilometres - for printing distances. */
    private static final double AU_IN_LY = 1.0D / 63241.1D;
    private static final double KM_IN_LY = 9.4607e12D;

    /**
     * How far from Earth, in the unit the size calls for.
     *
     * <p>The catalog keeps the figure as the text it was curated in - "4.24 ly", "~2.5 million ly", "384,400 km" -
     * and printing it as it stands is what a reader has to translate in their head. The number means nothing without
     * its scale, and the scale runs from the Moon's quarter of a million kilometres to a quasar at thirteen billion
     * light years.</p>
     */
    /** An orbital period in the unit a reader uses: hours, days or years. */
    private static String formatPeriod(float days) {
        if (days < 1.0F) {
            return String.format(java.util.Locale.ROOT, "%.1f 小时", days * 24.0D);
        }
        if (days < 900.0F) {
            return String.format(java.util.Locale.ROOT, "%.2f 天", days);
        }
        return String.format(java.util.Locale.ROOT, "%.2f 年", days / 365.25D);
    }

    private static String formatDistance(double ly) {
        if (ly <= 0.0D) {
            return null;
        }
        if (ly < 1.0e-5D) {
            return String.format(java.util.Locale.ROOT, "%,.0f 公里", ly * KM_IN_LY);
        }
        if (ly < 0.1D) {
            return String.format(java.util.Locale.ROOT, "%.3f AU", ly / AU_IN_LY);
        }
        if (ly < 1000.0D) {
            return String.format(java.util.Locale.ROOT, "%.1f 光年", ly);
        }
        if (ly < 1.0e6D) {
            return String.format(java.util.Locale.ROOT, "%.0f 千光年", ly / 1.0e3D);
        }
        if (ly < 1.0e9D) {
            return String.format(java.util.Locale.ROOT, "%.1f 百万光年", ly / 1.0e6D);
        }
        return String.format(java.util.Locale.ROOT, "%.1f 十亿光年", ly / 1.0e9D);
    }

    /**
     * An opaque RGB colour at a share of its opacity.
     *
     * <p>Never zero: {@code FontRenderer} reads a zero alpha as "no alpha given" and draws the text solid, so
     * a faded-out label would come back at full strength. Callers skip drawing below a visible threshold.</p>
     */
    private static int withAlpha(int rgb, float alpha) {
        int a = Math.round(Math.max(0.004F, Math.min(1.0F, alpha)) * 255.0F);
        return (a << 24) | (rgb & 0xFFFFFF);
    }

    /**
     * One layer of the map: the systems, or the bodies of one system, at an alpha and a scale.
     *
     * <p>The active layer is the one the cursor is on and the one {@link #onScreen} describes, so picking and
     * the hover ring both work on what is actually drawn. The other layer is drawn with the same camera and
     * its own fade, and is not pickable - it is on its way out.</p>
     */
    private void drawLayer(List<Node> nodes, boolean overview, int system, float alpha, float boost,
            boolean active) {
        viewCosYaw = (float) Math.cos(yaw);
        viewSinYaw = (float) Math.sin(yaw);
        viewCosPitch = (float) Math.cos(pitch);
        viewSinPitch = (float) Math.sin(pitch);
        // One scale for both axes, and its *value* comes from the frame rather than from a constant: a cloud
        // that fills a frame twice as wide as it is tall does so only at the angle it was fitted for, and the
        // owner wants it filling the frame while they turn it. See fitScale.
        referenceDistance = PERSPECTIVE_REACH * (overview ? LAYOUT_REACH : SYSTEM_REACH);
        // The wheel is the camera's distance, not a scale: further when it is rolled back, closer when it is
        // rolled forward, and always as a fraction of this layer's own size.
        float wanted = referenceDistance * (float) Math.exp(-DOLLY_SPEED * (zoom - 1.0F));
        viewDistance = Math.max(referenceDistance * MIN_DISTANCE_FRACTION,
                Math.min(referenceDistance * MAX_DISTANCE_FRACTION, wanted));
        float fit = fitScale(nodes, overview);
        float eased = overview ? fittedOverview : fittedSystem;
        eased = eased < 0.0F ? fit
                : eased + (fit - eased) * (1.0F - (float) Math.exp(-frameDt * 7.0F));
        if (overview) {
            fittedOverview = eased;
        } else {
            fittedSystem = eased;
        }
        viewFocal = eased * boost;
        // The scale at the *reference* distance: what the pan limit and the geometry descriptions need, and
        // what "relativeScale == 1" means.
        viewScale = viewFocal / referenceDistance;

        List<float[]> points = new ArrayList<float[]>(nodes.size());
        int hoveredHere = -1;
        float hoveredDepth = Float.MAX_VALUE;
        for (int i = 0; i < nodes.size(); i++) {
            float[] p = overview && LAYOUT.containsKey(nodes.get(i).systemKey)
                    ? LAYOUT.get(nodes.get(i).systemKey)
                    : position(nodes.get(i), i, nodes.size());
            float[] projected = project(p[0], p[1], p[2]);
            if (locked(nodes.get(i))) {
                // Not surveyed, therefore not on the chart - the owner's rule: "没解锁的天体，星系是不可找到的，只有解锁了
                // 才可以". Hiding it is done with the same NaN the projection uses for a point behind the camera, so it
                // is skipped by the drawing, by the labels and by the picking without any of them knowing why.
                points.add(new float[] { Float.NaN, Float.NaN, 0.0F, 0.0F });
                continue;
            }
            points.add(projected);
            if (Float.isNaN(projected[0])) {
                // Past the camera: it has no position, so it is neither hoverable nor labelled.
                continue;
            }
            if (active) {
                double distance = Math.hypot(projected[0] - mouseXNow, projected[1] - mouseYNow);
                if (distance < 12 && projected[2] < hoveredDepth) {
                    hoveredHere = i;
                    hoveredDepth = projected[2];
                }
            }
        }
        if (active) {
            activeNodes = nodes;
            onScreen.clear();
            onScreen.addAll(points);
            hovered = hoveredHere;
        }

        if (!overview) {
            drawOrbits(nodes, alpha);
        }

        /** Which nodes earned a label, in draw order (far to near), and where each one goes. */
        List<Integer> labelled = new ArrayList<Integer>();
        List<float[]> labelPos = new ArrayList<float[]>();

        // Back to front, so nearer spheres overdraw the ones behind them.
        int[] order = new int[nodes.size()];
        for (int i = 0; i < order.length; i++) {
            order[i] = i;
        }
        // Insertion sort by depth, nearest last. Written out rather than handed to Arrays.sort: the lambda
        // form did not type-check against this project's compiler settings, and seventy-seven elements do not
        // need a library sort.
        for (int i = 1; i < order.length; i++) {
            int current = order[i];
            int j = i - 1;
            while (j >= 0 && points.get(order[j])[2] < points.get(current)[2]) {
                order[j + 1] = order[j];
                j--;
            }
            order[j + 1] = current;
        }

        for (int index : order) {
            Node node = nodes.get(index);
            float[] s = points.get(index);
            if (Float.isNaN(s[0])) {
                continue;
            }
            if (s[0] < -40 || s[0] > width + 40 || s[1] < -40 || s[1] > height + 40) {
                continue;
            }
            boolean selectedNow = index == selected;
            // Size and brightness both come from the perspective now: at the reference distance a star is drawn
            // as it was before, closer to the camera it grows and brightens, further away it shrinks and fades -
            // which is what makes flying in feel like flying rather than zooming a picture.
            float near = Math.max(0.32F, Math.min(3.2F, s[3]));
            float radius = (overview ? 5.0F : 3.0F) * near;
            int color = LAYER_COLORS[Math.max(0, Math.min(LAYER_COLORS.length - 1, node.body.layer))];
            // A star breathes: a few percent of brightness at a rate of its own, which is the difference
            // between a field of lights and a field of stickers.
            float twinkle = 0.87F + 0.13F * (float) Math.sin(clock * 1.9D + index * 1.7D);
            float lit = alpha * twinkle * Math.min(1.0F, 0.42F + 0.58F * near);

            if (active && index == hovered && hoverGlow > 0.05F) {
                float pulse = 0.5F + 0.5F * (float) Math.sin(clock * 5.0D);
                drawSelectionRing(s[0], s[1], radius + 5.0F + 2.0F * pulse,
                        withAlpha(0xFFFFFF, alpha * hoverGlow * (0.35F + 0.45F * pulse)));
            }
            if (selectedNow && alpha > 0.2F) {
                drawBrackets(s[0], s[1], radius + 5.0F, withAlpha(0xFFFFFF, alpha));
            }
            if (overview) {
                if (node.body.star.isEmpty()) {
                    // A single object - a star, a black hole, a galaxy, a pulsar - is not a star *system*, and it is
                    // drawn as the kind of thing it is rather than as a grey ball (drawObjectForm).
                    drawObjectForm(node, s[0], s[1], radius, lit);
                } else {
                    // There is no branch for "surveyed or not": a system nobody has survey data for never reaches this
                    // loop at all (see the projection above), so every sphere drawn here is a charted one.
                    drawGlowingSphere(s[0], s[1], radius, starColor(node.body.star), lit * 0.95F);
                }
            } else {
                if (node.body.star.isEmpty()) {
                    // A lone object is drawn once, at the middle of its own view (drawObjectForm in the caller), so the
                    // node itself draws nothing here - only its label, its brackets and its hover ring, all of which
                    // land on the centre with it.
                } else if (isBelt(node)) {
                    // The belt's own dot is a dust knot on the band, not a body: small, pale, and there so the band
                    // can still be hovered and clicked.
                    drawGlowSprite(s[0], s[1], radius * 1.1F, radius * 1.1F, 0xC8D8FF, lit * 0.55F, true);
                } else {
                    drawGlowingSphere(s[0], s[1], radius, node.body.landable ? color : 0x8090A0,
                            lit * (node.body.landable ? 0.9F : 0.5F));
                }
                // A planet with moons wears a thin halo, and its moons are drawn on it (see position()): that ring
                // is the whole answer to "which body does this moon go round". The count is the number of its moons
                // that are *on the chart*: an empty halo around a planet whose moons have not been surveyed would be
                // a ring around nothing, which is a bug the eye reads immediately.
                int moons = visibleMoons(node.body);
                if (moons > 0 && alpha > 0.2F) {
                    drawDottedRing(s[0], s[1], MOON_HALO * s[3] * viewScale,
                            withAlpha(0x9FB8FF, alpha * 0.6F), 22);
                }
            }
            // Everything on screen is labelled, in both views. The owner's own reference for this screen is a
            // chart with the names written next to the stars; the overlap rejection below is what keeps that
            // readable when the cursor is over a cluster.
            boolean label = true;
            if (overview && index == HOME_SYSTEM) {
                // Home is named by its own marker ("你在这里 · Sol"), and two labels on one star is one label
                // printed twice over itself.
                label = false;
            }
            if (label && alpha > 0.25F) {
                labelled.add(Integer.valueOf(index));
                labelPos.add(new float[] { s[0] + radius + 4.0F, s[1] - 4.0F });
            }
        }

        // Labels last, nearest first, and never on top of each other. A system's seven bodies sit within a
        // hundred pixels of one another, so "label everything" without this produced a pile of overlapping
        // names - which is worse than an unlabelled star, because it is unreadable *and* hides the map.
        List<int[]> taken = new ArrayList<int[]>();
        for (int k = labelled.size() - 1; k >= 0; k--) {
            int index = labelled.get(k).intValue();
            Node node = nodes.get(index);
            String text = overview ? node.systemKey : labelOf(node.body);
            int lx = (int) labelPos.get(k)[0];
            int ly = (int) labelPos.get(k)[1];
            int[] box = new int[] { lx - 1, ly - 2, lx + fontRenderer.getStringWidth(text) + 1, ly + 8 };
            boolean free = true;
            for (int t = 0; t < taken.size(); t++) {
                int[] other = taken.get(t);
                if (box[0] < other[2] && other[0] < box[2] && box[1] < other[3] && other[1] < box[3]) {
                    free = false;
                    break;
                }
            }
            if (!free) {
                continue;
            }
            taken.add(box);
            // One colour, because every name on this chart belongs to a charted body: an unsurveyed one was never
            // given a position to put a name at.
            fontRenderer.drawStringWithShadow(text, (float) lx, (float) ly, withAlpha(0xD8E8FF, alpha));
        }

        GL11.glColor4f(1.0F, 1.0F, 1.0F, 1.0F);
        GL11.glEnable(GL11.GL_TEXTURE_2D);

        if (overview) {
            drawHomeMarker(alpha);
        } else {
            // The centre of the view: the star the bodies orbit - or, for a node that is one object rather than a
            // system, that object's own form. A black hole's own view used to open on a grey star that does not exist.
            float centreX = width / 2.0F + panX;
            float centreY = height / 2.0F + panY;
            if (system >= 0 && system < SYSTEMS.size()) {
                Node centre = SYSTEMS.get(system);
                if (centre.body.star.isEmpty()) {
                    drawObjectForm(centre, centreX, centreY, 14.0F, alpha);
                } else {
                    drawGlowingSphere(centreX, centreY, 14.0F, starColor(centre.body.star), alpha);
                }
            }
        }
    }

    /** The title, legend, selection line, hints and card, all faded together with the layer they describe. */
    private void drawReadouts(float alpha) {
        if (level == 0) {
            // The counts are the player's own progress, because the chart now shows the progress and nothing else:
            // "3 / 77" says how much of the catalogue has been surveyed without drawing a single unsurveyed star.
            String title = "Minespace 星图 — 已测绘 " + chartedSystems() + " / " + SYSTEMS.size() + " 个星系 · "
                    + chartedBodies() + " / " + MinespacePlanetDimensions.PLANETS.size() + " 个天体（其中 "
                    + LONE_OBJECTS + " 个单一天体）";
            // A backing under the title and the legend: the chart puts a name next to every star, and one of
            // them will always land on the legend - unreadable text in the corner of a readable map.
            // Two small backings rather than one big one: the chart puts a name next to every star, and one of
            // them will land on the legend - but a single box around both the title and the legend reads as a
            // black panel someone left on the map.
            int legendWidest = fontRenderer.getStringWidth(LEGEND_CAPTION) + 16;
            for (int layer = 2; layer < LAYER_LABELS.length; layer++) {
                legendWidest = Math.max(legendWidest, fontRenderer.getStringWidth(legendText(layer)) + 16);
            }
            drawRect(4, 4, 12 + fontRenderer.getStringWidth(title), 20, withAlpha(0x000000, 0.55F * alpha));
            // One line taller than the number of tiers, because the legend now carries a caption: it marks which
            // tiers are still locked, and an unlabelled list of greyed-out names is a riddle.
            drawRect(4, 22, 8 + legendWidest, 24 + (LAYER_LABELS.length - 1) * 11 + 3,
                    withAlpha(0x000000, 0.55F * alpha));
            drawString(fontRenderer, title, 8, 8, withAlpha(0xFFFFFF, alpha));
            drawLegend(alpha);
            String hint = "点击星系进入 · 拖拽平移 · 滚轮缩放 · R 复位 · ESC 关闭"
                    + " · 未解锁的天体不会出现在星图上（按 T 前往，见右下卡片）";
            if (clock - lockedHint < 4.0F && lockedHint > 0.0F) {
                // The refusal, for a few seconds after a click on a locked system: the card already says what is
                // needed, but a click that does nothing at all reads as a bug.
                hint = refusal != null ? refusal
                        : "该星系尚未解锁：需要 研究数据 " + ROMAN[Math.max(1, unlockedTier + 1)]
                                + "（按 J 关闭后合成，见 scripts\\research_data.zs）";
            }
            drawRect(4, height - 22, 14 + fontRenderer.getStringWidth(hint), height - 6,
                    withAlpha(0x000000, 0.66F * alpha));
            drawString(fontRenderer, hint, 8, height - 18, withAlpha(0xB0B0B0, alpha));
        } else {
            List<Node> bodies = nodesOfSystem(openedSystem);
            int chartedHere = 0;
            for (int i = 0; i < bodies.size(); i++) {
                if (!locked(bodies.get(i))) {
                    chartedHere++;
                }
            }
            String header = "▸ " + (openedSystem >= 0 ? SYSTEMS.get(openedSystem).systemKey : "?")
                    + "   已测绘 " + chartedHere + " / " + bodies.size() + " 个天体";
            drawRect(4, 4, 14 + fontRenderer.getStringWidth(header), 20, withAlpha(0x000000, 0.42F * alpha));
            drawString(fontRenderer, header, 8, 8, withAlpha(0xFFFFFF, alpha));
            String hint = choosingDestination
                    ? "已进入轨道：选一颗可登陆星球按 T 前往 · 未解锁的天体不显示 · 右键单击返回 · ESC 取消"
                    : "左键拖拽旋转 · 右键拖拽平移 · 滚轮缩放 · [ ] 调速 · P "
                            + (realRatios ? "改用压缩比例" : "改用真实比例")
                            + " · T 设为目的地 · 未解锁的天体不显示 · 右键单击返回 · ESC 关闭";
            drawRect(4, height - 22, 14 + fontRenderer.getStringWidth(hint), height - 6,
                    withAlpha(0x000000, 0.66F * alpha));
            drawString(fontRenderer, hint, 8, height - 18, withAlpha(0xB0B0B0, alpha));
        }
    }

    /**
     * The card, where the cursor is.
     *
     * <p>The first version of this card was pinned to the bottom right of the screen, which meant the eye had
     * to travel from the star to a corner and back to read it - and on a map whose whole content is positions,
     * that is the wrong shape. It now sits beside the cursor, and beside the selected star when the cursor is
     * nowhere: within reach of the thing it describes, which is what the owner asked for.</p>
     *
     * <p>The placement is the fiddly part, and it is fiddly for a real reason: the cursor can be anywhere, so
     * the card flips to the other side of it near the right and bottom edges, and is clamped if even that does
     * not fit. The two primitives are the ones this screen has proved it can draw with - a {@code drawRect}
     * panel and {@code drawString} lines.</p>
     */
    private void drawTooltip(Node node, boolean overview, float atX, float atY, float alpha) {
        if (node == null || alpha < 0.12F) {
            return;
        }
        List<String> lines = new ArrayList<String>();
        List<Integer> colours = new ArrayList<Integer>();
        MinespacePlanetDimensions.Planet body = node.body;
        int layer = Math.max(0, Math.min(LAYER_LABELS.length - 1, body.layer));
        if (overview) {
            lines.add(node.systemKey);
            colours.add(Integer.valueOf(0xFFFFFF));
            if (body.star.isEmpty()) {
                // The distinction the owner asked for, in words: this is a body, not a system.
                lines.add("单一天体 · 非恒星系");
                colours.add(Integer.valueOf(0xC0C0E0));
                lines.add("stage " + body.stage);
                colours.add(Integer.valueOf(0xA0A0A0));
            } else {
                lines.add("恒星系 · 宿主 " + body.star);
                colours.add(Integer.valueOf(0xE0C080));
                lines.add(node.bodyCount + " 个天体 · stage " + body.stage);
                colours.add(Integer.valueOf(0xA0A0A0));
            }
            lines.add(LAYER_LABELS[layer]);
            colours.add(Integer.valueOf(LAYER_COLORS[layer]));
            // The gate, on the card, as the reason this body is on the chart at all. Every card that exists belongs to
            // a charted body - an unsurveyed one is not drawn and cannot be hovered (see locked) - so there is no
            // "not unlocked yet" line to write here. What the card owes the player is the name of the gate that opened
            // this one, because that is the gate that has to open the next.
            int tier = MinespaceResearchData.tierOfLayer(body.layer);
            if (node.bodyCount > 1) {
                // A system card: its members can belong to different gates, and one of them was enough.
                lines.add("已测绘 · 星系内至少一个天体已解锁");
                colours.add(Integer.valueOf(0x90E090));
            } else if (node.body.dimensionId == currentDimension()) {
                // The one body that is on the chart without a gate: the world the map is being read from.
                lines.add("已测绘 · 你正站在这个天体上");
                colours.add(Integer.valueOf(0x90E090));
            } else if (com.minespace.unofficial.galacticraft.MinespaceCelestialRegistry
                    .registeredByPack(node.body)) {
                // A body this pack registered: two roads open it (see whyNot), so the card says which one did.
                lines.add(surveyedOurs(node.body) ? "已解锁 · 行星研究（望远镜）"
                        : "已解锁 · 研究数据 " + ROMAN[tier]);
                colours.add(Integer.valueOf(0x90E090));
            } else if (gateIsPlanetProgression(node)) {
                // PlanetProgression's telescope research is the gate: Galacticraft knows this body, or it is one of the
                // sun's own - see MinespacePlanetResearch.gateIsPlanetProgression. The card says which book to read
                // next, because that is the question a gate exists to answer.
                lines.add("已解锁 · 行星研究（望远镜）");
                colours.add(Integer.valueOf(0x90E090));
            } else {
                lines.add("等级 " + ROMAN[tier] + " · 已解锁（研究数据 " + ROMAN[tier] + "）");
                colours.add(Integer.valueOf(0x90E090));
            }
            String away = formatDistance(body.distanceLy);
            if (away != null) {
                lines.add("距地球 " + away
                        + (body.star.isEmpty() || layer > 1 ? "" : "（恒星距离）"));
                colours.add(Integer.valueOf(0x9FD0FF));
            }
            lines.add("左键进入查看");
            colours.add(Integer.valueOf(0x808080));
        } else {
            lines.add(body.name);
            colours.add(Integer.valueOf(0xFFFFFF));
            lines.add(body.nameZh);
            colours.add(Integer.valueOf(0xFFE080));
            lines.add(LAYER_LABELS[layer] + " · stage " + body.stage);
            colours.add(Integer.valueOf(LAYER_COLORS[layer]));
            if (!body.parent.isEmpty()) {
                String parentZh = ZH_BY_NAME.get(body.parent);
                lines.add("卫星 · 绕 " + (parentZh == null ? body.parent : parentZh));
                colours.add(Integer.valueOf(0xC8C8F0));
            } else if (body.orbitAu > 0.0F) {
                lines.add("距恒星 " + body.orbitAu + " AU" + (isBelt(node) ? "（带状）" : ""));
                colours.add(Integer.valueOf(0x9FD0FF));
            }
            if (body.periodDays > 0.0F) {
                lines.add("公转周期 " + formatPeriod(body.periodDays));
                colours.add(Integer.valueOf(0x9FD0FF));
            }
            // How to get there: Galacticraft's rocket does the flying, this map only aims it (see
            // MinespaceRocketTarget), so the card says which rocket and which data it wants.
            // The card is only drawn for a charted body, so the question here is only whether the body can be landed
            // on - the gate is already answered by the body being on the chart at all (see whyNot for the server's
            // copy of the same rule, which is the one that decides).
            if (body.landable) {
                lines.add(choosingDestination
                        ? "按 T 前往此处"
                        : "按 T 设为火箭目的地（需 T"
                                + com.minespace.unofficial.galacticraft.MinespaceRocketTarget
                                        .rocketTierForLayer(body.layer) + " 火箭 + 燃料）");
                colours.add(Integer.valueOf(0xC0FFC0));
            } else if (body.star.isEmpty()) {
                lines.add("不可登陆 · 无法设为目的地");
                colours.add(Integer.valueOf(0xB0B0B0));
            }
            // How far it is from the player's own world: the radial distance from Earth's orbit inside the solar
            // system (0.05 AU is close enough to count as "here"), and the star's real distance for anything
            // outside it. The Moon is the one body whose catalog figure is its distance from *Earth*, so a very
            // small distance is printed in kilometres from it rather than in AU.
            if (body.name.equals("Earth")) {
                lines.add("距地球 0 —— 你在这里");
                colours.add(Integer.valueOf(0x9FD0FF));
            } else if (body.orbitAu > 0.0F) {
                double fromEarth = Math.abs(body.orbitAu - 1.0F);
                if (fromEarth >= 0.05D) {
                    lines.add(String.format(java.util.Locale.ROOT, "距地球 %.2f AU", fromEarth));
                    colours.add(Integer.valueOf(0x9FD0FF));
                } else {
                    String close = formatDistance(body.distanceLy);
                    lines.add("距地球 " + (close == null ? "≈ 0.00 AU" : close));
                    colours.add(Integer.valueOf(0x9FD0FF));
                }
            } else {
                String away = formatDistance(body.distanceLy);
                if (away != null) {
                    lines.add("距地球 " + away);
                    colours.add(Integer.valueOf(0x9FD0FF));
                }
            }
            if (!body.landable && !body.star.isEmpty()) {
                // A gas or ice giant: a planet, and still not a place to put a rocket down, and no veins to list.
                lines.add("不可登录 · 无矿脉（气态/冰质）");
                colours.add(Integer.valueOf(0xB0B0B0));
            } else if (body.star.isEmpty()) {
                // A body that is its own object: no host star to name and nothing to mine - it is an observation.
                lines.add("单一天体 · 非恒星系 · 仅观测");
                colours.add(Integer.valueOf(0xC0C0E0));
            } else {
                lines.add(body.landable ? "可登陆" : "不可登陆 · 仅观测");
                colours.add(Integer.valueOf(body.landable ? 0x90E090 : 0xB0B0B0));
                lines.add(body.star.isEmpty() ? "无宿主恒星" : "宿主 " + body.star);
                colours.add(Integer.valueOf(0xA0A0A0));
                lines.add(body.veins > 0 ? "矿脉 " + body.veins + " 条" : "矿脉待配置");
                colours.add(Integer.valueOf(body.veins > 0 ? 0xE0E0A0 : 0x808080));
            }
        }

        int widest = 0;
        for (int i = 0; i < lines.size(); i++) {
            widest = Math.max(widest, fontRenderer.getStringWidth(lines.get(i)));
        }
        int boxW = widest + 12;
        int boxH = lines.size() * 11 + 8;
        int left = (int) atX + 16;
        int top = (int) atY + 10;
        if (left + boxW > width - 6) {
            left = (int) atX - 16 - boxW;
        }
        if (top + boxH > height - 6) {
            top = (int) atY - 10 - boxH;
        }
        left = Math.max(6, Math.min(width - 6 - boxW, left));
        top = Math.max(6, Math.min(height - 6 - boxH, top));

        drawRect(left, top, left + boxW, top + boxH, withAlpha(0x000000, 0.84F * alpha));
        drawRect(left, top, left + boxW, top + 1, withAlpha(LAYER_COLORS[layer], alpha));
        int line = top + 5;
        for (int i = 0; i < lines.size(); i++) {
            fontRenderer.drawStringWithShadow(lines.get(i), (float) (left + 6), (float) line,
                    withAlpha(colours.get(i).intValue(), alpha));
            line += 11;
        }
    }

    /**
     * The backdrop: a nebula photograph stretched over the whole screen, then a dark scrim on top of it.
     *
     * <p>The previous version drew the star sprite itself at the size of the screen, which is why the
     * backdrop was two enormous circles - the same soft ball a star is, blown up until nothing was left of
     * it. A nebula wants structure, and structure is the one thing a radial gradient does not have.</p>
     *
     * <p>The scrim is not decoration: the photograph has bright regions, the map draws labels over them,
     * and text on a bright cloud is unreadable. Half-transparent black costs nothing and buys back the
     * contrast the labels need.</p>
     */
    private void drawBackdrop() {
        mc.getTextureManager().bindTexture(NEBULA_TEXTURE);
        net.minecraft.client.renderer.GlStateManager.enableBlend();
        net.minecraft.client.renderer.GlStateManager.blendFunc(
                org.lwjgl.opengl.GL11.GL_SRC_ALPHA, org.lwjgl.opengl.GL11.GL_ONE_MINUS_SRC_ALPHA);
        net.minecraft.client.renderer.GlStateManager.color(1.0F, 1.0F, 1.0F, 1.0F);
        // The texture size passed in is the size drawn, which is the whole point: that ratio is the UV
        // scale, and getting it wrong is what turned every star into a quarter disc.
        drawModalRectWithCustomSizedTexture(0, 0, 0.0F, 0.0F, width, height, width, height);
        net.minecraft.client.renderer.GlStateManager.disableBlend();
        drawRect(0, 0, width, height, 0x60040813);
    }

    /**
     * The sky behind the map: five hundred faint points, scrolled a little by the view and wrapped at the
     * edges.
     *
     * <p>They are grain rather than data, so they are drawn in screen space and moved by the drag instead
     * of being projected like the systems: the point is depth, and a layer that slides slowly under a map
     * that turns quickly says "far away" without any of them being placeable.</p>
     */
    private void drawStarDust() {
        float offsetX = yaw * 0.05F;
        float offsetY = pitch * 0.05F;
        for (int i = 0; i < DUST.length; i++) {
            float u = DUST[i][0] + offsetX;
            float v = DUST[i][1] + offsetY;
            u -= (float) Math.floor(u);
            v -= (float) Math.floor(v);
            int x = (int) (u * width);
            int y = (int) (v * height);
            float bright = DUST[i][2];
            int alpha = (int) (30.0F + 190.0F * bright);
            int tint = bright > 0.93F ? 0xFFE8C0 : bright > 0.6F ? 0xE8F0FF : 0xC0D0FF;
            int size = bright > 0.86F ? 2 : 1;
            drawRect(x, y, x + size, y + size, (alpha << 24) | tint);
        }
    }

    /**
     * Opens with one line in the log: the numbers that decide whether anything can be on screen at all.
     *
     * <p>"Nothing on screen" has four completely different causes - no data, drawn outside the visible
     * area, hidden by the gate, or the screen never drawing at all - and from outside the client they look
     * identical. The line this package used to print here was a throwaway probe; it is kept, and now counts
     * what the gate lets through, because "how many of the seventy-seven systems are on the chart" is the
     * difference between a chart that is empty because the player has no research yet and one that is
     * empty because the gate is wrong.</p>
     */
    @Override
    public void initGui() {
        super.initGui();
        // A fresh timestamp, so the first frame's delta is a frame rather than however long the screen sat on
        // the stack before being opened.
        lastFrameNanos = 0L;
        if (CAPTURE_DIR != null && selected < 0 && SYSTEMS.size() > 2) {
            // A captured frame should show the card as well as the field, and there is no mouse to hover
            // with, so the first capture run selects something itself.
            selected = 2;
        }
        LOG.info("star map opened: gui {}x{} scale {}, {} systems from {} table rows",
                width, height, mc == null ? -1 : mc.gameSettings.guiScale, SYSTEMS.size(),
                MinespacePlanetDimensions.PLANETS.size());
        refreshGate();
        LOG.info("star map gate: research data {} of {}, {} of {} systems charted, {} of {} bodies charted",
                unlockedTier, MinespaceResearchData.TIERS, chartedSystems(), SYSTEMS.size(),
                chartedBodies(), MinespacePlanetDimensions.PLANETS.size());
    }

    /** How many systems the player's own progress puts on the chart - the answer the open line above prints. */
    private int chartedSystems() {
        int count = 0;
        for (int i = 0; i < SYSTEMS.size(); i++) {
            if (!locked(SYSTEMS.get(i))) {
                count++;
            }
        }
        return count;
    }

    private int chartedBodies() {
        int count = 0;
        for (MinespacePlanetDimensions.Planet body : MinespacePlanetDimensions.PLANETS) {
            if (bodyUnlocked(body)) {
                count++;
            }
        }
        return count;
    }

    /**
     * The camera half of the capture flag in the class javadoc: draw a frame, write it out, move to the
     * next pose, and once the poses are done let the client tick below quit the game.
     *
 * <p>Five poses: the overview, the overview pulled back to its widest, the *middle of the transition* into a
 * system, the system itself, and the system turned - because those are the five ways this screen has actually
 * looked wrong. The frames are counted rather than taken immediately so that a capture is always of a frame that
 * has been drawn twice - the first frame after opening a GUI in 1.12.2 is not always the one on screen.</p>
     */
    private void captureTick() {
        // The opening fade is waited out - a photograph of black is not a photograph of the map - but the
        // level change is deliberately caught in the middle: see the switch below.
        if (openFade < 0.999F) {
            return;
        }
        if (captureWait > 0) {
            captureWait--;
            return;
        }
        captureFrames++;
        if (captureFrames < 3) {
            return;
        }
        captureFrames = 0;
        if (captureStep == 0) {
            writeFrame("starmap-1-overview.png");
            // The chart, pulled back: the far layers are what the wheel is for, and the angle does *not* change
            // here because the overview does not turn any more.
            zoom = 0.62F;
            targetZoom = zoom;
            captureStep = 1;
            return;
        }
        if (captureStep == 1) {
            writeFrame("starmap-2-overview-out.png");
            // ... and flown into: the same chart from much closer, which is the pose that says whether the zoom
            // is a camera or a scale. If it is a camera, the stars near the eye are much larger than the ones at
            // the far side and their arrangement is no longer the same picture, only bigger.
            zoom = 3.4F;
            targetZoom = zoom;
            captureStep = 6;
            return;
        }
        if (captureStep == 6) {
            writeFrame("starmap-2b-overview-close.png");
            // Aim the camera's pointer at the rightmost system: the card has to survive being asked to open
            // towards the edge it does not have room for, and this is the only way to photograph that.
            capturePointer = rightmostNode();
            zoom = 1.0F;
            targetZoom = zoom;
            // Entering a system the way a click does, so that the frame after this one is the transition
            // itself rather than a jump.
            pendingSystem = firstSystemWithBodies();
            pendingLevel = 1;
            transition = 0.0F;
            captureStep = 2;
            return;
        }
        if (captureStep == 2) {
            // Waits on the fade itself rather than on a frame count, so the pose is the same at 20 fps and at
            // 60: just past a third of the way through, where both layers are on screen at once.
            if (transition < 0.42F) {
                return;
            }
            writeFrame("starmap-3-transition.png");
            selected = 1;
            capturePointer = -1;
            captureStep = 3;
            captureWait = 40;
            return;
        }
        if (captureStep == 3) {
            writeFrame("starmap-4-system.png");
            // Flying into the system: the same camera move as the overview, one level down.
            zoom = 3.5F;
            targetZoom = zoom;
            captureStep = 4;
            captureWait = 40;
            return;
        }
        if (captureStep == 4) {
            writeFrame("starmap-5-system-close.png");
            captureStep = 5;
            // ... and then wait long enough that the inner bodies have visibly moved: at the tempo of the inner solar
            // system a planet takes thirty seconds an orbit, so twenty seconds is most of a lap. Two photographs are
            // the only way a still camera can say whether the map is moving.
            captureWait = 600;
            return;
        }
        writeFrame("starmap-6-system-after.png");
        captureStep = 6;
        capturePointer = -1;
        captureFinished = true;
    }

    /**
     * The fake cursor the capture runs with: the capture has no mouse, and a screen whose card placement is
     * never exercised is a screen whose card placement is untested.
     */
    private void applyCapturePointer() {
        if (capturePointer >= 0 && capturePointer < onScreen.size()) {
            mouseXNow = (int) onScreen.get(capturePointer)[0];
            mouseYNow = (int) onScreen.get(capturePointer)[1];
        }
    }

    private int rightmostNode() {
        int found = -1;
        float best = -Float.MAX_VALUE;
        for (int i = 0; i < onScreen.size(); i++) {
            float x = onScreen.get(i)[0];
            if (x < width * 0.55F) {
                continue;
            }
            if (x > best) {
                best = x;
                found = i;
            }
        }
        return found;
    }

    private static int firstSystemWithBodies() {
        if (!CAPTURE_SYSTEM.isEmpty()) {
            for (int i = 0; i < SYSTEMS.size(); i++) {
                if (SYSTEMS.get(i).systemKey.toLowerCase(java.util.Locale.ROOT)
                        .contains(CAPTURE_SYSTEM.toLowerCase(java.util.Locale.ROOT))) {
                    return i;
                }
            }
        }
        // The capture photographs the solar system: it is the one system whose rings carry real distances and whose
        // moons have planets to orbit, so it is the one that can be wrong in a way the others cannot.
        for (int i = 0; i < SYSTEMS.size(); i++) {
            if (SYSTEMS.get(i).systemKey.equalsIgnoreCase("Sol")) {
                return i;
            }
        }
        for (int i = 0; i < SYSTEMS.size(); i++) {
            if (SYSTEMS.get(i).bodyCount >= 3) {
                return i;
            }
        }
        return 0;
    }

    /**
     * Reads the frame back out of the framebuffer and writes it as a PNG.
     *
     * <p>GL hands back rows bottom-up and the screen wants them top-down, so the row index is flipped on
     * the way into the image. Reading here rather than after the frame is presented is deliberate: the
     * back buffer is still this screen's, with no other mod's overlay drawn on top of it.</p>
     */
    private void writeFrame(String name) {
        int w = mc.displayWidth;
        int h = mc.displayHeight;
        try {
            java.nio.ByteBuffer pixels = org.lwjgl.BufferUtils.createByteBuffer(w * h * 4);
            org.lwjgl.opengl.GL11.glPixelStorei(org.lwjgl.opengl.GL11.GL_PACK_ALIGNMENT, 1);
            org.lwjgl.opengl.GL11.glReadPixels(0, 0, w, h, org.lwjgl.opengl.GL11.GL_RGBA,
                    org.lwjgl.opengl.GL11.GL_UNSIGNED_BYTE, pixels);
            java.awt.image.BufferedImage image =
                    new java.awt.image.BufferedImage(w, h, java.awt.image.BufferedImage.TYPE_INT_RGB);
            for (int y = 0; y < h; y++) {
                for (int x = 0; x < w; x++) {
                    int i = ((h - 1 - y) * w + x) * 4;
                    int r = pixels.get(i) & 0xFF;
                    int g = pixels.get(i + 1) & 0xFF;
                    int b = pixels.get(i + 2) & 0xFF;
                    image.setRGB(x, y, (r << 16) | (g << 8) | b);
                }
            }
            java.io.File dir = new java.io.File(CAPTURE_DIR);
            if (!dir.exists() && !dir.mkdirs()) {
                throw new java.io.IOException("could not create " + dir);
            }
            java.io.File out = new java.io.File(dir, name);
            javax.imageio.ImageIO.write(image, "png", out);
            LOG.info("star map capture: {} ({}x{})", out, w, h);
        } catch (Throwable t) {
            // A capture that fails must not take the client with it: this code only ever runs on a
            // developer's command line, and the log line is the whole point of it.
            LOG.error("star map capture failed", t);
            captureFinished = true;
        }
    }

    /** The tick half of the capture flag: quit the game once both frames are on disk. */
    @Override
    public void updateScreen() {
        if (captureFinished && mc != null) {
            mc.shutdown();
        }
    }

    /**
     * The tier chart in the corner: which layers of the catalogue the player's survey data opens, and which are
     * still dark.
     *
     * <p>This is not decoration and it is not a second gate - it is the answer to the one question a chart that hides
     * its unsurveyed contents creates: *"what is missing, and what opens it"*. The map itself cannot say it any more
     * (an unsurveyed system is not drawn at all), so the legend carries it, in the same order the layers are laid out
     * on the chart.</p>
     */
    private void drawLegend(float alpha) {
        int x = 8;
        int y = 24;
        drawString(fontRenderer, LEGEND_CAPTION, x, y, withAlpha(0x808898, alpha));
        y += 11;
        for (int layer = 2; layer < LAYER_LABELS.length; layer++) {
            boolean open = layerCharted(layer);
            drawRect(x, y + 2, x + 8, y + 10, withAlpha(LAYER_COLORS[layer], alpha * (open ? 1.0F : 0.3F)));
            drawString(fontRenderer, legendText(layer), x + 12, y + 2,
                    withAlpha(open ? 0xA0A0A0 : 0x666C76, alpha));
            y += 11;
        }
    }

    /** One legend line: the layer's own name, plus what it is waiting for when it is still locked. */
    private String legendText(int layer) {
        return LAYER_LABELS[layer]
                + (layerCharted(layer) ? "" : "  · 未解锁");
    }

    /**
     * A star: a radial-gradient texture, tinted, with additive blending so a cluster of them reads as
     * light rather than as overlapping squares.
     *
     * <p>Square rects were the fallback that proved this screen could draw at all, but a star should be a
     * ball. The texture is this mod's own (assets/minespace/textures/gui/star_glow.png, a white core
     * fading to nothing), which is what makes two things true at once: the shape is round, and the tint
     * decides the colour - so a spectral class costs no extra art.</p>
     *
     * <p>Drawn through the vanilla sprite call rather than raw GL, and through {@code GlStateManager} for
     * the state: a missing texture shows as the purple checkerboard instead of throwing, and the manager
     * keeps its cached GL state in step, which raw {@code GL11} calls do not. That distinction is exactly
     * what 6dr cost a client crash to learn.</p>
     */
    private void drawGlowingSphere(float x, float y, float radius, int rgb, float alpha) {
        float r = ((rgb >> 16) & 0xFF) / 255.0F;
        float g = ((rgb >> 8) & 0xFF) / 255.0F;
        float b = (rgb & 0xFF) / 255.0F;
        float glow = radius * 3.0F;
        float core = Math.max(1.5F, radius * 0.55F);

        net.minecraft.client.renderer.GlStateManager.enableBlend();
        net.minecraft.client.renderer.GlStateManager.blendFunc(
                org.lwjgl.opengl.GL11.GL_SRC_ALPHA, org.lwjgl.opengl.GL11.GL_ONE);
        // Two passes of the same sprite: the wide one is the halo, the small one is the hot centre that
        // makes it a star rather than a smudge.
        net.minecraft.client.renderer.GlStateManager.color(r, g, b, alpha * 0.85F);
        drawGlowQuad(x - glow, y - glow, glow * 2.0F);
        net.minecraft.client.renderer.GlStateManager.color(1.0F, 1.0F, 1.0F, alpha);
        drawGlowQuad(x - core, y - core, core * 2.0F);
        net.minecraft.client.renderer.GlStateManager.blendFunc(
                org.lwjgl.opengl.GL11.GL_SRC_ALPHA, org.lwjgl.opengl.GL11.GL_ONE_MINUS_SRC_ALPHA);
        net.minecraft.client.renderer.GlStateManager.disableBlend();
        net.minecraft.client.renderer.GlStateManager.color(1.0F, 1.0F, 1.0F, 1.0F);
    }

    /**
     * One square of the glow sprite, at the requested size.
     *
     * <p>The last two arguments of {@code drawModalRectWithCustomSizedTexture} are the texture's size in
     * pixels, and the UVs are computed as (offset + pixel) / textureSize. Passing the drawn size as the
     * texture size therefore means "sample the whole texture", whatever the sprite is and whatever the
     * size it is drawn at - which is the property this needs, because the same sprite is drawn as a
     * two-pixel core and as a thirty-pixel halo.</p>
     *
     * <p>The awkward alternative was passing the file's real size (64) and the drawn size (say 30): the
     * ratio then samples the top-left 30/64 of the sprite, and a radial gradient sampled from a corner
     * comes out as a quarter disc. That is exactly what the owner saw - every star a fan - and it is why
     * this is a method with a comment rather than an argument at each call site.</p>
     */
    private void drawGlowQuad(float x, float y, float size) {
        int side = Math.max(1, Math.round(size));
        mc.getTextureManager().bindTexture(GLOW_TEXTURE);
        drawModalRectWithCustomSizedTexture(Math.round(x), Math.round(y), 0.0F, 0.0F, side, side,
                side, side);
    }

    /**
     * One stretch of the glow sprite, tinted, centred on a point, at any width and height.
     *
     * <p>The plasma-free primitive under every shape in {@link #drawObjectForm}: a galaxy is this drawn wide, a nebula
     * is this drawn huge and faint, a black hole is the same sprite tinted black with normal blending. Additive
     * blending is for light; a black hole is the one thing on this screen that takes light away.</p>
     */
    private void drawGlowSprite(float cx, float cy, float width, float height, int rgb, float alpha,
            boolean additive) {
        float r = ((rgb >> 16) & 0xFF) / 255.0F;
        float g = ((rgb >> 8) & 0xFF) / 255.0F;
        float b = (rgb & 0xFF) / 255.0F;
        int w = Math.max(1, Math.round(width));
        int h = Math.max(1, Math.round(height));
        mc.getTextureManager().bindTexture(GLOW_TEXTURE);
        net.minecraft.client.renderer.GlStateManager.enableBlend();
        net.minecraft.client.renderer.GlStateManager.blendFunc(
                org.lwjgl.opengl.GL11.GL_SRC_ALPHA,
                additive ? org.lwjgl.opengl.GL11.GL_ONE : org.lwjgl.opengl.GL11.GL_ONE_MINUS_SRC_ALPHA);
        net.minecraft.client.renderer.GlStateManager.color(r, g, b, alpha);
        drawModalRectWithCustomSizedTexture(Math.round(cx - w / 2.0F), Math.round(cy - h / 2.0F),
                0.0F, 0.0F, w, h, w, h);
        net.minecraft.client.renderer.GlStateManager.blendFunc(
                org.lwjgl.opengl.GL11.GL_SRC_ALPHA, org.lwjgl.opengl.GL11.GL_ONE_MINUS_SRC_ALPHA);
        net.minecraft.client.renderer.GlStateManager.disableBlend();
        net.minecraft.client.renderer.GlStateManager.color(1.0F, 1.0F, 1.0F, 1.0F);
    }

    /**
     * A body that is not a planet and not a star system, drawn as the kind of thing it is.
     *
     * <p>Everything here used to be one pale ball, which made a galaxy, a black hole and an unfinished planet look
     * the same. The owner's note was exact: *"一些非行星天体应该呈现他们自有的形态而不是跟恒星一样"*. The kinds the
     * catalog actually contains are covered one by one; the rest - the CMB, a cosmic web, a gravitational wave, an
     * interstellar object - are markers by nature and keep the marker: a pale core with a thin ring.</p>
     */
    private void drawObjectForm(Node node, float x, float y, float radius, float alpha) {
        String type = node.body.type == null ? "" : node.body.type;
        if (type.equals("Galaxy")) {
            drawGlowSprite(x, y, radius * 7.5F, radius * 2.8F, 0xFFE2B4, alpha * 0.5F, true);
            drawGlowSprite(x, y, radius * 2.4F, radius * 2.4F, 0xFFF3DC, alpha * 0.85F, true);
            return;
        }
        if (type.equals("Nebula")) {
            drawGlowSprite(x, y, radius * 9.0F, radius * 7.0F, 0x86C4FF, alpha * 0.30F, true);
            drawGlowSprite(x + radius * 1.6F, y - radius * 0.9F, radius * 5.0F, radius * 4.0F,
                    0xFF90C0, alpha * 0.22F, true);
            return;
        }
        if (type.equals("BlackHole")) {
            // The accretion disc, then the hole over it. The first version drew a dark disc inside a ring of
            // one-pixel dots, and the ring vanished into the nebula - photographed, so this is the second version:
            // light that is actually light (additive, wide and flat, two thicknesses of it), with the dark disc on
            // top of it, which is what leaves a bright rim rather than a dotted circle.
            drawGlowSprite(x, y, radius * 7.5F, radius * 2.3F, 0xFFD8A0, alpha * 0.50F, true);
            drawGlowSprite(x, y, radius * 5.4F, radius * 1.5F, 0xFFF0C8, alpha * 0.45F, true);
            drawGlowSprite(x, y, radius * 3.4F, radius * 3.4F, 0x000000, alpha, false);
            return;
        }
        if (type.equals("Pulsar")) {
            float pulse = 0.55F + 0.45F * (float) Math.sin(clock * 6.0D);
            drawGlowSprite(x, y, radius * 3.2F, radius * 3.2F, 0xE8F0FF, alpha * pulse, true);
            drawDottedRing(x, y, radius * 2.1F, withAlpha(0xA0D0FF, alpha * pulse * 0.75F), 18);
            return;
        }
        if (type.equals("Star") || type.equals("WhiteDwarf") || type.equals("Quasar")) {
            boolean quasar = type.equals("Quasar");
            drawGlowSprite(x, y, radius * (quasar ? 6.5F : 4.2F), radius * (quasar ? 6.5F : 4.2F),
                    quasar ? 0xFFFFE8 : 0xF0F4FF, alpha * 0.8F, true);
            drawGlowSprite(x, y, radius * 0.95F, radius * 0.95F, 0xFFFFFF, alpha, true);
            return;
        }
        if (type.equals("Cluster")) {
            for (int i = 0; i < 7; i++) {
                double a = i * 2.39996D;
                float r = radius * (0.6F + 0.45F * (i % 3));
                drawGlowSprite(x + (float) Math.cos(a) * r, y + (float) Math.sin(a) * r,
                        radius * 1.5F, radius * 1.5F, 0xFFF0E0, alpha * 0.8F, true);
            }
            return;
        }
        drawGlowSprite(x, y, radius * 1.4F, radius * 1.4F, 0xE8E8FF, alpha * 0.8F, true);
        drawSelectionRing(x, y, radius + 3.0F, withAlpha(0x9090C0, alpha * 0.85F));
    }

    /** A square bracket around the selection, in the same primitive. */
    private void drawSelectionRing(float x, float y, float radius, int argb) {
        int left = (int) (x - radius);
        int right = (int) (x + radius);
        int top = (int) (y - radius);
        int bottom = (int) (y + radius);
        drawRect(left, top, right, top + 1, argb);
        drawRect(left, bottom - 1, right, bottom, argb);
        drawRect(left, top, left + 1, bottom, argb);
        drawRect(right - 1, top, right, bottom, argb);
    }

    /**
     * Four corners instead of a box, for the thing that is selected.
     *
     * <p>A closed rectangle around a star competes with the star; a targeting reticle frames it and leaves the
     * middle alone. The corners are the same four {@code drawRect} calls a ring is, just shorter, so nothing
     * new is being asked of the renderer - and it is what makes the difference between "this screen has a
     * selection" and "this screen is a map you are reading".</p>
     */
    private void drawBrackets(float x, float y, float radius, int argb) {
        int arm = (int) Math.max(3.0F, radius * 0.6F);
        int left = (int) (x - radius);
        int right = (int) (x + radius);
        int top = (int) (y - radius);
        int bottom = (int) (y + radius);
        drawRect(left, top, left + arm, top + 1, argb);
        drawRect(left, top, left + 1, top + arm, argb);
        drawRect(right - arm, top, right, top + 1, argb);
        drawRect(right - 1, top, right, top + arm, argb);
        drawRect(left, bottom - 1, left + arm, bottom, argb);
        drawRect(left, bottom - arm, left + 1, bottom, argb);
        drawRect(right - arm, bottom - 1, right, bottom, argb);
        drawRect(right - 1, bottom - arm, right, bottom, argb);
    }

    /** A dotted circle in screen space, used for a planet's moon halo. */
    private void drawDottedRing(float cx, float cy, float radius, int argb, int steps) {
        if (radius < 3.0F) {
            return;
        }
        for (int step = 0; step < steps; step++) {
            double angle = step * Math.PI * 2.0 / steps;
            int x = (int) (cx + Math.cos(angle) * radius);
            int y = (int) (cy + Math.sin(angle) * radius);
            if (x < 0 || x >= width || y < 0 || y >= height) {
                continue;
            }
            drawRect(x, y, x + 1, y + 1, argb);
        }
    }

    /** What the card is about: the node under the cursor, or the selected one when the cursor is elsewhere. */
    private Node tipNode() {
        if (activeNodes == null) {
            return null;
        }
        if (hovered >= 0 && hovered < activeNodes.size()) {
            Node node = activeNodes.get(hovered);
            if (!locked(node)) {
                return node;
            }
        }
        if (selected >= 0 && selected < activeNodes.size()) {
            Node node = activeNodes.get(selected);
            if (!locked(node)) {
                return node;
            }
        }
        return null;
    }

    /**
     * Where a point in the map's own space lands on the screen, and everything the caller needs to draw it
     * there.
     *
     * <p>The rotation is applied by hand - yaw about the vertical axis, then pitch about the horizontal one -
     * and then the **perspective** division, because that is what the owner asked for and it is not a detail:
     * *"3D 放大是穿梭查看 ... 是由远到近的过程"*. A zoom that scales the drawing uniformly is a picture getting
     * bigger; a zoom that moves the camera closer makes the near stars sweep outward past the edge, shrinks the
     * far ones, and eventually leaves the ones behind the camera gone. That is travel, and it only happens if
     * there is a dividing depth.</p>
     *
     * <p>Returns {x, y, depth, relativeScale}. Depth is the rotated z and decides both draw order and which of
     * two overlapping stars the cursor is on. relativeScale is how much bigger this point is drawn than it would
     * be at the reference distance - 1.0 there, more when the camera is closer, less when it is further - and it
     * is what the size and the opacity of a star are multiplied by. A point that has passed the camera comes back
     * as NaN x, and callers skip it: a star flying past the camera should vanish, not become a wall.</p>
     */
    private float[] project(float px, float py, float pz) {
        float rx = px * viewCosYaw - pz * viewSinYaw;
        float rz = px * viewSinYaw + pz * viewCosYaw;
        float ry = py * viewCosPitch - rz * viewSinPitch;
        rz = py * viewSinPitch + rz * viewCosPitch;
        float depth = viewDistance - rz;
        if (depth < referenceDistance * NEAR_PLANE_FRACTION) {
            return new float[] { Float.NaN, Float.NaN, rz, 0.0F };
        }
        float persp = viewFocal / depth;
        return new float[] {
                width / 2.0F + panX + rx * persp,
                height / 2.0F + panY + ry * persp,
                rz,
                persp / viewScale
        };
    }

    /**
     * The scale at which this layer's nodes reach the edges of the frame at the current angles.
     *
     * <p>Three properties matter. It is measured, not guessed: the nodes are rotated by the camera that is about
     * to draw them, so the number is right for whatever angle they are seen from, and it is re-measured every
     * frame (and eased, so the map does not jump). It is a **percentile, not a maximum**: fitting to the
     * outermost system of seventy-seven would let one stray point shrink the whole cloud. And **which**
     * percentile is the difference between a chart and a picture: the overview is fitted to its 35th, so the far
     * half of the chart is genuinely off screen and has to be travelled to, while a system's own bodies are
     * fitted to their 92nd, because a system is one glance and not a journey.</p>
     */
    private float fitScale(List<Node> nodes, boolean overview) {
        // Only the charted nodes are fitted, because only they are drawn: with a third of the catalog surveyed, a fit
        // that measured the whole cloud would shrink the handful of stars the player has earned down to a knot in the
        // middle of an empty screen, with the rest of the frame reserved for bodies that are not on it.
        int n = 0;
        for (int i = 0; i < nodes.size(); i++) {
            if (!locked(nodes.get(i))) {
                n++;
            }
        }
        if (n == 0) {
            // Nothing charted at all: an empty chart has no extent, and the caller's eased value keeps the camera
            // from jumping while the rest of the map is worked out.
            return overview ? Math.max(1.0F, fittedOverview) : Math.max(1.0F, fittedSystem);
        }
        float[] xs = new float[n];
        float[] ys = new float[n];
        float cy = (float) Math.cos(yaw);
        float sy = (float) Math.sin(yaw);
        float cp = (float) Math.cos(pitch);
        float sp = (float) Math.sin(pitch);
        int slot = 0;
        for (int i = 0; i < nodes.size(); i++) {
            if (locked(nodes.get(i))) {
                continue;
            }
            float[] p = overview && LAYOUT.containsKey(nodes.get(i).systemKey)
                    ? LAYOUT.get(nodes.get(i).systemKey)
                    : position(nodes.get(i), i, nodes.size());
            float rx = p[0] * cy - p[2] * sy;
            float rz = p[0] * sy + p[2] * cy;
            float ry = p[1] * cp - rz * sp;
            rz = p[1] * sp + rz * cp;
            float depth = referenceDistance - rz;
            // The fit is measured through the same perspective the frame will be drawn with - the projected
            // offset is r * focal / depth, so the fraction that matters is r / depth and the focal is what
            // gets solved for. Anything already behind the camera is not part of the frame.
            if (depth < referenceDistance * NEAR_PLANE_FRACTION) {
                xs[slot] = 0.0F;
                ys[slot] = 0.0F;
                slot++;
                continue;
            }
            xs[slot] = Math.abs(rx) / depth;
            ys[slot] = Math.abs(ry) / depth;
            slot++;
        }
        java.util.Arrays.sort(xs);
        java.util.Arrays.sort(ys);
        int index = Math.min(n - 1, (int) (n * (overview ? 0.35F : 0.92F)));
        float px = Math.max(0.0001F, xs[index]);
        float py = Math.max(0.0001F, ys[index]);
        if (xs[index] <= 0.0F && ys[index] <= 0.0F) {
            // Every node is at the middle - a system that is one object, which is drawn at a fixed pixel size - so
            // there is no extent to fit and any scale would do; a neutral one keeps the arithmetic sane.
            return Math.min(width, height) * 0.5F;
        }
        // The margin is not decoration: the outermost node's *label* is drawn to its right, and a fit that
        // touches the edge cuts the label off the screen.
        return Math.min((width * 0.5F - 26.0F) / px, (height * 0.5F - 20.0F) / py);
    }

    /**
     * Keeps the cloud within reach. The window on the map grows with the zoom - at three times zoom the owner
     * has to be able to bring an outer system to the middle of the screen - and the floor keeps a fully zoomed
     * out map from being dragged entirely out of sight.
     */
    private void clampPan() {
        // The limit is the chart's own reach, not the screen's: with the near layers fitted to the frame, the far
        // ones are several screens out, and the whole point is that they can be reached.
        float units = level == 0 ? LAYOUT_REACH : 1.05F;
        // Apparent pixels per unit where the camera is looking: the focal divided by the distance the camera has
        // actually come to. The reach the pan limit has to cover grows with it.
        float scale = (level == 0 ? fittedOverview : fittedSystem) / Math.max(0.05F, viewDistance);
        float limitX = Math.max(width * 0.32F, units * scale * 1.15F);
        float limitY = Math.max(height * 0.32F, units * scale * 1.15F);
        targetPanX = Math.max(-limitX, Math.min(limitX, targetPanX));
        targetPanY = Math.max(-limitY, Math.min(limitY, targetPanY));
        panX = Math.max(-limitX, Math.min(limitX, panX));
        panY = Math.max(-limitY, Math.min(limitY, panY));
    }

    /** Back to the default three-quarter view, centred. */
    private void resetView() {
        targetYaw = 0.6F;
        targetPitch = 0.35F;
        targetZoom = 1.0F;
        targetPanX = 0.0F;
        targetPanY = 0.0F;
        spinYaw = 0.0F;
        spinPitch = 0.0F;
        spinPanX = 0.0F;
        spinPanY = 0.0F;
    }

    /**
     * The orbit radius level 1 gives one body; the rings have to agree with it.
     *
     * <p>With a real orbital distance the radius is **logarithmic**: the solar system runs from Mercury at 0.387 AU
     * to the Kuiper belt at 44 AU, a factor of 113, and a linear radius would put Mercury inside the star's glow
     * and the belt off the screen. 0.3 AU maps to 0.26 and 50 AU to 1.0, which separates every body in between.
     * Without a figure - every exoplanet system - the bodies keep the even spacing they had before.</p>
     */
    private static float orbitRadius(Node node, int index) {
        if (node.body.orbitAu > 0.0F) {
            return logRadius(node.body.orbitAu);
        }
        return 0.34F + 0.09F * index;
    }

    /** The logarithmic ring radius for a real orbital distance, shared by planets, moons and their haloes. */
    private static float logRadius(float au) {
        double t = (Math.log(au) - Math.log(0.3D)) / (Math.log(50.0D) - Math.log(0.3D));
        return (float) (0.26D + 0.74D * Math.max(0.0D, Math.min(1.0D, t)));
    }

    /** True for a rubble belt, which is drawn as a band of rings rather than as a body on one. */
    private static boolean isBelt(Node node) {
        return "AsteroidBelt".equals(node.body.type);
    }

    /** How far a moon sits from its planet on screen, in layout units - the radius of the halo. */
    private static final float MOON_HALO = 0.075F;

    /**
     * One real day of orbital motion per this many seconds on screen.
     *
     * <p>The owner asked for the planets to move *with their real periods*, which is a statement about ratios and not
     * about speed: Mercury has to come round ~4.15 times while Earth comes round once, and Neptune has to take 165
     * Earth years. That is what this constant cannot change - all it decides is how long Earth's own year takes to
     * watch (0.12 s per day makes it 44 seconds; Mercury's 88 days fly past in 10.6).</p>
     */
    private static final float SECONDS_PER_DAY = 0.12F;

    /**
     * The clock, in seconds of screen time per real day, and its two ends.
     *
     * <p>Real periods are real ratios, and one ratio cannot suit both ends of a solar system: at a tempo where Earth
     * takes 44 seconds, Io goes round Jupiter five times a second. So the ratios stay true and the *tempo* is the
     * owner's - `[` and `]` step it by a factor of two, and the card prints the period it is honouring.</p>
     */
    private float secondsPerDay = SECONDS_PER_DAY;

    /** The owner's own factor on top of the per-system tempo: `[` slows the clock, `]` speeds it up. */
    private float tempoMultiplier = 1.0F;

    /** The tempo of one system, by index into {@link #SYSTEMS}. */
    private static float tempoOf(int systemIndex) {
        if (systemIndex < 0 || systemIndex >= SYSTEMS.size()) {
            return SECONDS_PER_DAY;
        }
        Float tempo = TEMPO_BY_SYSTEM.get(SYSTEMS.get(systemIndex).systemKey);
        return tempo == null ? SECONDS_PER_DAY : tempo.floatValue();
    }

    /**
     * Where a body is right now: its place in the list, plus however far its own period has carried it since the
     * screen opened. A body whose catalog entry has no period stands still rather than being given an invented one.
     */
    private double bodyAngle(Node node, int index, int count) {
        return orbitAngle(node, node.body.periodDays, index, count);
    }

    /** The same, for a body named rather than held - a moon needs its planet's period to know where the planet is. */
    private double orbitAngle(Node node, float periodDays, int index, int count) {
        double base = index * Math.PI * 2.0 / Math.max(1, count) + 0.4;
        if (periodDays <= 0.0F) {
            return base;
        }
        Float fastest = node.systemKey == null ? null : FASTEST_BY_SYSTEM.get(node.systemKey);
        if (fastest == null || fastest.floatValue() <= 0.0F) {
            return base;
        }
        double ratio = periodDays / fastest.floatValue();
        double seconds = FASTEST_ORBIT_SECONDS
                * Math.pow(ratio, realRatios ? 1.0D : COMPRESSED_EXPONENT) * tempoMultiplier;
        return base + Math.PI * 2.0 * (clock / Math.max(0.25D, seconds));
    }

    /** name → orbital period in days, for the bodies a moon has to follow. */
    private static final Map<String, Float> PERIOD_BY_NAME = buildPeriodByName();

    /**
     * The clock each system runs at, and why a single number cannot work.
     *
     * <p>The owner asked for real periods and then said, of TRAPPIST-1, *"这也太快了"*. Both are right: the ratios are
     * real, and a tempo that suits them cannot suit the solar system. Its planets take 88 to 60,182 days; TRAPPIST-1's
     * take 1.51 to 18.8. So the tempo is per system: the **fastest planet** (moons excluded - they move inside a
     * planet's halo, where speed is unreadable) is given eight seconds for one orbit, and every other body in that
     * system keeps its true ratio to it. The owner's own multiplier from `[` and `]` then scales the whole clock.</p>
     */
    private static final float FASTEST_ORBIT_SECONDS = 30.0F;

    /**
     * How far the periods are compressed when the owner asks for it, as an exponent.
     *
     * <p>Real ratios and a watchable map pull in opposite directions, and the owner has now said both: *"确保真实按比例
     * 的公转周期"* and then, with the real thing in front of them, *"比例还是太快了"*. Neither is wrong - a real solar
     * system has Neptune taking 684 times as long as Mercury, and no single view shows both - so there are two modes
     * and `P` switches between them. Compressed keeps the *order* real (nothing overtakes anything) and takes the
     * 0.35th power of the period ratio, which brings Neptune's 684x down to about 8x.</p>
     */
    private static final double COMPRESSED_EXPONENT = 0.35D;

    /** True: real periods. False: real order, compressed ratios. Switched with `P`. */
    private boolean realRatios = true;

    /** systemKey → the period of its fastest planet, which is what both modes are normalised against. */
    private static final Map<String, Float> FASTEST_BY_SYSTEM = buildFastest();

    private static Map<String, Float> buildFastest() {
        Map<String, Float> map = new LinkedHashMap<String, Float>();
        for (Map.Entry<String, List<MinespacePlanetDimensions.Planet>> entry : BY_SYSTEM.entrySet()) {
            float fastest = 0.0F;
            for (MinespacePlanetDimensions.Planet body : entry.getValue()) {
                if (body.periodDays <= 0.0F || !body.parent.isEmpty()) {
                    continue;
                }
                fastest = fastest <= 0.0F ? body.periodDays : Math.min(fastest, body.periodDays);
            }
            if (fastest > 0.0F) {
                map.put(entry.getKey(), Float.valueOf(fastest));
            }
        }
        return map;
    }
    private static final Map<String, Float> TEMPO_BY_SYSTEM = buildTempo();

    private static Map<String, Float> buildTempo() {
        Map<String, Float> map = new LinkedHashMap<String, Float>();
        for (Map.Entry<String, List<MinespacePlanetDimensions.Planet>> entry : BY_SYSTEM.entrySet()) {
            float fastest = 0.0F;
            for (MinespacePlanetDimensions.Planet body : entry.getValue()) {
                if (body.periodDays <= 0.0F || !body.parent.isEmpty()) {
                    continue;
                }
                fastest = fastest <= 0.0F ? body.periodDays : Math.min(fastest, body.periodDays);
            }
            map.put(entry.getKey(), Float.valueOf(fastest <= 0.0F
                    ? SECONDS_PER_DAY
                    : Math.max(0.004F, Math.min(2.0F, FASTEST_ORBIT_SECONDS / fastest))));
        }
        return map;
    }

    private static Map<String, Float> buildPeriodByName() {
        Map<String, Float> map = new LinkedHashMap<String, Float>();
        for (MinespacePlanetDimensions.Planet body : MinespacePlanetDimensions.PLANETS) {
            map.put(body.name, Float.valueOf(body.periodDays));
        }
        return map;
    }

    private static float periodOf(String name) {
        Float period = PERIOD_BY_NAME.get(name);
        return period == null ? 0.0F : period.floatValue();
    }

    /** name → its own orbital distance, and name → its Chinese name. */
    private static final Map<String, Float> AU_BY_NAME = buildAuByName();
    private static final Map<String, String> ZH_BY_NAME = buildZhByName();

    /** systemKey|moonName → the index of the planet it orbits, in that system's sorted body list. */
    private static final Map<String, Integer> PARENT_INDEX = buildParentIndex();

    /** moonName → how many moons its planet has, i.e. how many dots fit on one halo. */
    private static final Map<String, Integer> SIBLING_COUNT = buildSiblingCount();

    /** moonName → its place among its siblings, so two moons of one planet are not drawn on top of each other. */
    private static final Map<String, Integer> SIBLING_SLOT = buildSiblingSlot();

    private static Map<String, Float> buildAuByName() {
        Map<String, Float> map = new LinkedHashMap<String, Float>();
        for (MinespacePlanetDimensions.Planet body : MinespacePlanetDimensions.PLANETS) {
            map.put(body.name, Float.valueOf(body.orbitAu));
        }
        return map;
    }

    private static Map<String, String> buildZhByName() {
        Map<String, String> map = new LinkedHashMap<String, String>();
        for (MinespacePlanetDimensions.Planet body : MinespacePlanetDimensions.PLANETS) {
            map.put(body.name, body.nameZh);
        }
        return map;
    }

    private static Map<String, Integer> buildParentIndex() {
        Map<String, Integer> map = new LinkedHashMap<String, Integer>();
        for (Map.Entry<String, List<MinespacePlanetDimensions.Planet>> entry : BY_SYSTEM.entrySet()) {
            List<MinespacePlanetDimensions.Planet> bodies = entry.getValue();
            for (int i = 0; i < bodies.size(); i++) {
                MinespacePlanetDimensions.Planet moon = bodies.get(i);
                if (moon.parent.isEmpty()) {
                    continue;
                }
                for (int p = 0; p < bodies.size(); p++) {
                    if (bodies.get(p).name.equals(moon.parent)) {
                        map.put(entry.getKey() + "|" + moon.name, Integer.valueOf(p));
                        break;
                    }
                }
            }
        }
        return map;
    }

    private static Map<String, Integer> buildSiblingCount() {
        Map<String, Integer> counts = new LinkedHashMap<String, Integer>();
        for (MinespacePlanetDimensions.Planet body : MinespacePlanetDimensions.PLANETS) {
            if (body.parent.isEmpty()) {
                continue;
            }
            Integer seen = counts.get(body.parent);
            counts.put(body.parent, Integer.valueOf(seen == null ? 1 : seen.intValue() + 1));
        }
        return counts;
    }

    private static Map<String, Integer> buildSiblingSlot() {
        Map<String, Integer> slots = new LinkedHashMap<String, Integer>();
        Map<String, Integer> next = new LinkedHashMap<String, Integer>();
        for (MinespacePlanetDimensions.Planet body : MinespacePlanetDimensions.PLANETS) {
            if (body.parent.isEmpty()) {
                continue;
            }
            Integer seen = next.get(body.parent);
            int slot = seen == null ? 0 : seen.intValue();
            next.put(body.parent, Integer.valueOf(slot + 1));
            slots.put(body.name, Integer.valueOf(slot));
        }
        return slots;
    }

    /**
     * The dashed rings the bodies of one system sit on.
     *
     * <p>They are dotted rather than continuous because a line is not a primitive this screen has; a point
     * every twelve degrees is, and at this size the dots read as a line while staying inside the drawing
     * calls that are known to work. A ring is also the one annotation that makes an orbit visible at all -
     * without it the bodies of a system are eight dots with no relationship.</p>
     */
    private void drawOrbits(List<Node> nodes, float alpha) {
        int drawn = 0;
        for (int i = 0; i < nodes.size(); i++) {
            if (locked(nodes.get(i))) {
                // No orbit for a body that is not on the chart: a dotted ring with nothing on it is a ring the player
                // cannot explain, and it would also say "there is something here" about a body the gate is hiding.
                continue;
            }
            if (nodes.get(i).body.star.isEmpty()) {
                // A body with no host star is not orbiting anything, so it gets no ring.
                continue;
            }
            if (!nodes.get(i).body.parent.isEmpty()) {
                // A moon does not get a ring of its own around the star: it is drawn on its planet's halo, and the
                // halo is what says it orbits that planet.
                continue;
            }
            int color = LAYER_COLORS[Math.max(0, Math.min(LAYER_COLORS.length - 1,
                    nodes.get(i).body.layer))];
            // Bright enough to be seen over the nebula: at a quarter alpha the first version's rings were
            // drawn and invisible, which is the same as not drawing them.
            int dot = withAlpha(color, 0.60F * alpha);
            float orbit = orbitRadius(nodes.get(i), i);
            if (isBelt(nodes.get(i))) {
                // A belt is a band, not a ring: five rings from -6% to +6% of its distance, each fainter towards the
                // edge, which reads as a broad annulus of rubble instead of one thin circle the owner could not tell
                // apart from a planet's orbit.
                for (int band = -2; band <= 2; band++) {
                    float bandOrbit = orbit * (1.0F + band * 0.03F);
                    int bandDot = withAlpha(color, alpha * (band == 0 ? 0.55F : 0.30F));
                    for (int step = 0; step < 44; step++) {
                        double angle = step * Math.PI * 2.0 / 44.0;
                        float[] s = project((float) (Math.cos(angle) * bandOrbit),
                                (i % 3 - 1) * 0.06F, (float) (Math.sin(angle) * bandOrbit));
                        if (Float.isNaN(s[0]) || s[0] < 0 || s[0] >= width || s[1] < 0 || s[1] >= height) {
                            continue;
                        }
                        drawRect((int) s[0], (int) s[1], (int) s[0] + 1, (int) s[1] + 1, bandDot);
                    }
                }
                continue;
            }
            // Not called "height": that is GuiScreen's field, and shadowing it here made the bounds check
            // below compare the screen's height against 0.06 and throw away every dot. The rings were
            // drawn, correctly, zero times - which looks exactly like a ring that is too faint.
            float ringY = (i % 3 - 1) * 0.06F;
            for (int step = 0; step < 44; step++) {
                double angle = step * Math.PI * 2.0 / 44.0;
                float[] s = project((float) (Math.cos(angle) * orbit), ringY,
                        (float) (Math.sin(angle) * orbit));
                if (Float.isNaN(s[0]) || s[0] < 0 || s[0] >= width || s[1] < 0 || s[1] >= height) {
                    continue;
                }
                drawRect((int) s[0], (int) s[1], (int) s[0] + 1, (int) s[1] + 1, dot);
                drawn++;
            }
        }
        if (CAPTURE_DIR != null) {
            LOG.info("orbit rings: {} dots for {} bodies, scale {}", drawn, nodes.size(), viewScale);
        }
    }

    /**
     * "You are here": the one body on the map the player has actually stood on.
     *
     * <p>Named with a ring in a colour nothing else uses, because it is the only marker on this screen that
     * is not a destination - the rest of the map is somewhere to go, and this is where the map is read
     * from.</p>
     */
    private void drawHomeMarker(float alpha) {
        if (HOME_SYSTEM < 0 || HOME_SYSTEM >= onScreen.size()) {
            return;
        }
        float[] s = onScreen.get(HOME_SYSTEM);
        if (Float.isNaN(s[0])) {
            // Home is past the camera: at that distance the map is somewhere else entirely.
            return;
        }
        drawSelectionRing(s[0], s[1], 11.0F, withAlpha(0x40D0FF, alpha));
        String label = "你在这里 · " + SYSTEMS.get(HOME_SYSTEM).systemKey;
        int lx = (int) (s[0] + 15.0F);
        int ly = (int) (s[1] + 4.0F);
        // The marker can land on top of another system's stars, and unreadable text is not a label.
        drawRect(lx - 2, ly - 2, lx + fontRenderer.getStringWidth(label) + 2, ly + 9,
                withAlpha(0x000000, 0.63F * alpha));
        fontRenderer.drawStringWithShadow(label, (float) lx, (float) ly, withAlpha(0x80E4FF, alpha));
    }

    /** The short name for a label: Chinese when the catalog has one, the designation when it does not. */
    private static String labelOf(MinespacePlanetDimensions.Planet body) {
        return body.nameZh == null || body.nameZh.isEmpty() ? body.name : body.nameZh;
    }

    private static List<MinespacePlanetDimensions.Planet> bodiesOf(int systemIndex) {
        if (systemIndex < 0 || systemIndex >= SYSTEMS.size()) {
            return java.util.Collections.emptyList();
        }
        return BY_SYSTEM.get(SYSTEMS.get(systemIndex).systemKey);
    }

    private static List<Node> nodesOfSystem(int systemIndex) {
        if (systemIndex < 0 || systemIndex >= SYSTEMS.size()) {
            return new ArrayList<Node>();
        }
        List<Node> nodes = NODES_BY_SYSTEM.get(SYSTEMS.get(systemIndex).systemKey);
        return nodes == null ? new ArrayList<Node>() : nodes;
    }

    /** Level 0 spreads systems on one shell per layer; level 1 rings the chosen system's bodies. */
    private float[] position(Node node, int index, int count) {
        if (node.bodyCount > 0 && node.systemKey != null && count == SYSTEMS.size()) {
            float shell = 0.34F + 0.11F * node.body.layer;
            double angle = hash(node.systemKey) * Math.PI * 2.0;
            return new float[] {
                    (float) (Math.cos(angle) * shell),
                    (float) ((hash(node.body.key) - 0.5) * 0.5F),
                    (float) (Math.sin(angle) * shell)
            };
        }
        if (node.body.star.isEmpty()) {
            // A body that is its own object IS the middle of its own view: the first version also drew it out on a ring,
            // so a pulsar appeared twice - once at the centre and once selectable beside it - and the owner asked the
            // obvious question ("本来就是一个非恒星系天体 ... 不是应该直接选择中央的那个就可以了吗"). One object, one mark,
            // in the middle, where the card and the selection brackets now both point.
            return new float[] { 0.0F, 0.0F, 0.0F };
        }
        // The angles move: each body is where its own orbital period says it is by now (see bodyAngle).
        double angle = bodyAngle(node, index, count);
        if (!node.body.parent.isEmpty()) {
            // A moon is drawn around its planet: same ring, same angle, plus a short hop out of it. Which planet is
            // decided by the catalog's Parent column, and the planet's own place in the list by the AU sort - so a
            // moon follows its planet to whatever ring the planet's real distance puts it on.
            Integer parentIndex = node.systemKey == null ? null
                    : PARENT_INDEX.get(node.systemKey + "|" + node.body.name);
            Float parentAu = AU_BY_NAME.get(node.body.parent);
            if (parentIndex != null && parentAu != null) {
                int p = parentIndex.intValue();
                float parentRadius = logRadius(parentAu.floatValue());
                double parentAngle = orbitAngle(node, periodOf(node.body.parent), p, count);
                Integer siblings = SIBLING_COUNT.get(node.body.parent);
                Integer slot = SIBLING_SLOT.get(node.body.name);
                int place = slot == null ? 0 : slot.intValue();
                int total = siblings == null ? 1 : Math.max(1, siblings.intValue());
                double moonAngle = place * Math.PI * 2.0 / total + 0.6D;
                return new float[] {
                        (float) (Math.cos(parentAngle) * parentRadius + Math.cos(moonAngle) * MOON_HALO),
                        (p % 3 - 1) * 0.06F + (place % 2 == 0 ? 0.025F : -0.025F),
                        (float) (Math.sin(parentAngle) * parentRadius + Math.sin(moonAngle) * MOON_HALO)
                };
            }
        }
        float orbit = orbitRadius(node, index);
        return new float[] {
                (float) (Math.cos(angle) * orbit),
                (float) ((index % 3 - 1) * 0.06F),
                (float) (Math.sin(angle) * orbit)
        };
    }

    private static double hash(String text) {
        int h = 0;
        for (int i = 0; i < text.length(); i++) {
            h = h * 31 + text.charAt(i);
        }
        return (Math.abs(h) % 1000) / 1000.0;
    }

    /**
     * The star's colour from its spectral class, which the catalog already records - "TRAPPIST-1 M8.0 V"
     * is an M dwarf, "eps Eri K2 V" is a K, "55 Cnc G8 V" is a G. Taken from the *last* class-looking
     * token so a catalogue prefix cannot win (GJ 273 M3.5 is an M, not a G).
     *
     * <p>The colours are the usual blackbody approximations for each class, which is why an M dwarf comes
     * out red-orange and a G comes out near-white. When nothing parses, the star is drawn sun-coloured
     * rather than guessed at.</p>
     */
    private static int starColor(String star) {
        java.util.regex.Matcher matcher = java.util.regex.Pattern
                .compile("([OBAFGKM])\\s*(\\d(?:\\.\\d)?)?").matcher(star);
        String spectralClass = null;
        while (matcher.find()) {
            if (matcher.group(2) != null) {
                spectralClass = matcher.group(1);
            }
        }
        if (spectralClass == null) {
            return 0xFFF0D0;
        }
        switch (spectralClass) {
            case "O": return 0x9BB0FF;
            case "B": return 0xAABFFF;
            case "A": return 0xCAD7FF;
            case "F": return 0xF8F7FF;
            case "G": return 0xFFF4EA;
            case "K": return 0xFFD2A1;
            case "M": return 0xFF9A6A;
            default: return 0xFFF0D0;
        }
    }

    @Override
    protected void mouseClicked(int mouseX, int mouseY, int mouseButton) {
        // Nothing is clickable while a change is in flight: the positions on screen belong to a layer that is
        // on its way out, and picking one of those is exactly the kind of surprise that reads as a bug.
        if (transition < 1.0F) {
            return;
        }
        pressX = mouseX;
        pressY = mouseY;
        // What the press *might* be is remembered, and decided on release. A press that moves is a drag - and in
        // the overview every drag is a pan, including one that started on a star, because "move the map" has to
        // work wherever the cursor happens to be.
        dragMoved = false;
        pressedNode = mouseButton == 0 ? pick(mouseX, mouseY) : -1;
        dragging = mouseButton;
        lastX = mouseX;
        lastY = mouseY;
    }

    private int pick(int mouseX, int mouseY) {
        float best = Float.MAX_VALUE;
        int found = -1;
        for (int i = 0; i < onScreen.size(); i++) {
            float[] s = onScreen.get(i);
            if (Float.isNaN(s[0])) {
                continue;
            }
            double d = Math.hypot(s[0] - mouseX, s[1] - mouseY);
            if (d < 12 && s[2] < best) {
                best = s[2];
                found = i;
            }
        }
        return found;
    }

    @Override
    protected void mouseClickMove(int mouseX, int mouseY, int clickedMouseButton, long timeSinceLastClick) {
        if (dragging < 0) {
            return;
        }
        if (!dragMoved) {
            if (Math.abs(mouseX - pressX) + Math.abs(mouseY - pressY) < 3) {
                // Still a click: the deltas are measured from the press, so nothing is lost when it becomes a
                // drag a few pixels later.
                return;
            }
            dragMoved = true;
        }
        int rawX = mouseX - lastX;
        int rawY = mouseY - lastY;
        boolean rotating = level == 1 && dragging == 0;
        if (rotating) {
            float dx = rawX * 0.01F;
            float dy = rawY * 0.01F;
            targetYaw += dx;
            targetPitch = clampPitch(targetPitch + dy);
            // How fast the drag is going, remembered for the throw after release. Scaled down from the raw
            // per-event delta so a quick flick coasts rather than spins.
            spinYaw = dx * 2.5F;
            spinPitch = dy * 2.5F;
        } else {
            // Panning is in screen pixels because that is what the hand expects: the map follows the cursor
            // one to one, whatever the zoom or the angle.
            targetPanX += rawX;
            targetPanY += rawY;
            spinPanX = rawX * 2.5F;
            spinPanY = rawY * 2.5F;
            clampPan();
        }
        lastX = mouseX;
        lastY = mouseY;
    }

    @Override
    protected void mouseReleased(int mouseX, int mouseY, int state) {
        if (!dragMoved && transition >= 1.0F) {
            if (dragging == 1) {
                if (level == 1) {
                    // A right click that never moved: back out one level.
                    pendingSystem = -1;
                    pendingLevel = 0;
                    transition = 0.0F;
                    spinYaw = 0.0F;
                    spinPitch = 0.0F;
                }
            } else if (dragging == 0 && pressedNode >= 0) {
                if (level == 0) {
                    if (locked(SYSTEMS.get(pressedNode))) {
                        // A lane that is not surveyed yet is not a lane: the click is refused here rather than one
                        // level down, so nothing half-enters a system the player has no data for. Since a locked
                        // system is not drawn, `pick` cannot find one any more and this is a guard rather than a code
                        // path - kept because the alternative is a click that opens a system nobody may enter, and
                        // that failure would only ever happen in front of a player.
                        lockedHint = clock;
                    } else {
                        pendingSystem = pressedNode;
                        pendingLevel = 1;
                        transition = 0.0F;
                        spinYaw = 0.0F;
                        spinPitch = 0.0F;
                        // A system is read from above: the tilt goes back to the default and the map is centred on
                        // it, while the direction the owner is looking from is theirs to keep.
                        targetPitch = 0.35F;
                        targetZoom = 1.0F;
                        targetPanX = 0.0F;
                        targetPanY = 0.0F;
                    }
                } else {
                    selected = pressedNode;
                }
            }
        }
        dragging = -1;
        pressedNode = -1;
        // A slow drag should stop where it was released, not coast: the throw is for a flick.
        if (Math.abs(spinYaw) < 0.15F) {
            spinYaw = 0.0F;
        }
        if (Math.abs(spinPitch) < 0.15F) {
            spinPitch = 0.0F;
        }
        if (Math.abs(spinPanX) < 1.5F) {
            spinPanX = 0.0F;
        }
        if (Math.abs(spinPanY) < 1.5F) {
            spinPanY = 0.0F;
        }
        clampPan();
    }

    /**
     * Keyboard panning and a view reset, because dragging is not the only way a hand wants to move a map - and
     * because a screen that can be panned needs a defined way back to the middle.
     */
    @Override
    protected void keyTyped(char typedChar, int keyCode) throws java.io.IOException {
        float stepX = Math.max(12.0F, width * 0.06F);
        float stepY = Math.max(8.0F, height * 0.06F);
        if (keyCode == Keyboard.KEY_W || keyCode == Keyboard.KEY_UP) {
            targetPanY -= stepY;
        } else if (keyCode == Keyboard.KEY_S || keyCode == Keyboard.KEY_DOWN) {
            targetPanY += stepY;
        } else if (keyCode == Keyboard.KEY_A || keyCode == Keyboard.KEY_LEFT) {
            targetPanX -= stepX;
        } else if (keyCode == Keyboard.KEY_D || keyCode == Keyboard.KEY_RIGHT) {
            targetPanX += stepX;
        } else if (keyCode == Keyboard.KEY_R) {
            resetView();
            return;
        } else if (keyCode == Keyboard.KEY_LBRACKET) {
            // The clock, not the orbits: real periods are ratios, and the ratios never change - only how long the
            // owner is willing to wait for Earth to come round.
            tempoMultiplier = Math.max(0.03F, tempoMultiplier / 2.0F);
            return;
        } else if (keyCode == Keyboard.KEY_RBRACKET) {
            tempoMultiplier = Math.min(32.0F, tempoMultiplier * 2.0F);
            return;
        } else if (keyCode == Keyboard.KEY_P) {
            // Real periods, or real order with the ratios flattened. Both are honest about what they show; the card
            // keeps printing the true period either way.
            realRatios = !realRatios;
            return;
        } else if (keyCode == Keyboard.KEY_T) {
            if (choosingDestination) {
                // The in-orbit choice (6eo): the server asked for it at the atmosphere, so picking a body here is
                // "take me there now" rather than "remember this and ignite".
                if (level == 1 && activeNodes != null && selected >= 0 && selected < activeNodes.size()) {
                    Node node = activeNodes.get(selected);
                    String why = whyNot(node);
                    if (why == null) {
                        com.minespace.unofficial.galacticraft.MinespaceNetwork.CHANNEL.sendToServer(
                                new com.minespace.unofficial.galacticraft.MinespaceNetwork.RocketTargetMessage(
                                        node.body.dimensionId, true));
                        choosingDestination = false;
                        mc.displayGuiScreen(null);
                    } else {
                        refuse(why);
                    }
                } else {
                    refuse("先点开一个星系，选中里面的天体，再按 T");
                }
                return;
            }
            // "Aim my rocket here." Only from a body's own view, only for a body that can be landed on and that the
            // player's data covers - and the server re-checks every one of those (MinespaceRocketTarget), because a
            // client is never the authority on whether it may go somewhere.
            if (level == 1 && activeNodes != null && selected >= 0 && selected < activeNodes.size()) {
                Node node = activeNodes.get(selected);
                String why = whyNot(node);
                if (why == null) {
                    com.minespace.unofficial.galacticraft.MinespaceNetwork.CHANNEL.sendToServer(
                            new com.minespace.unofficial.galacticraft.MinespaceNetwork.RocketTargetMessage(
                                    node.body.dimensionId));
                } else {
                    refuse(why);
                }
            } else {
                refuse("先点开一个星系，选中里面的天体，再按 T");
            }
            return;
        } else {
            super.keyTyped(typedChar, keyCode);
            return;
        }
        spinPanX = 0.0F;
        spinPanY = 0.0F;
        clampPan();
    }

    @Override
    public void handleMouseInput() throws java.io.IOException {
        super.handleMouseInput();
        int wheel = Mouse.getEventDWheel();
        if (wheel != 0) {
            // The target, not the drawn zoom: the wheel chooses where the camera is going and the easing
            // above decides how it gets there. The range is what makes the map travellable: out to 0.5 to pull
            // back and see the far layers, in to 3.5 to read one cluster. It does not go lower because at 0.3 the
            // whole map collapsed into a knot in the middle of the screen, which is what the owner saw.
            targetZoom = Math.max(0.5F, Math.min(3.5F, targetZoom * (wheel > 0 ? 1.22F : 0.82F)));
        }
    }

    @Override
    public boolean doesGuiPauseGame() {
        return false;
    }
}
