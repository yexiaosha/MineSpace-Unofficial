package com.minespace.unofficial.navigation;

import com.minespace.unofficial.gtceu.MinespacePlanetDimensions;
import micdoodle8.mods.galacticraft.core.client.gui.screen.GuiTeleporting;
import net.minecraftforge.fml.relauncher.Side;
import net.minecraftforge.fml.relauncher.SideOnly;

/**
 * The pack's own arrival screen: the same moment Galacticraft calls "teleporting", drawn as this pack's document.
 *
 * <h2>What is reused and what is replaced (6h)</h2>
 *
 * <p>It extends {@code GuiTeleporting} for one reason: that class's constructor registers itself in
 * {@code TickHandlerClient.teleportingGui}, and the client tick handler forces that screen back every tick until the
 * destination world is there, clearing the field when it is. That is the mechanism that lets a screen survive
 * vanilla's "Downloading terrain", and re-implementing it would be a second copy of a working thing. What is replaced
 * is everything the player sees: the field, the panel, the destination, the distance and the progress.</p>
 *
 * <p>The progress is a sweeping band rather than a percentage on purpose. The server does not report how much of the
 * world is ready, and a bar that pretends to know would be a lie with a fill level.</p>
 */
@SideOnly(Side.CLIENT)
public final class MinespaceTeleportingScreen extends GuiTeleporting {

    private static final int CYAN = 0xFF5CDCEB;
    private static final int AMBER = 0xFFF0AC3E;
    private static final int STEEL = 0xFF8A9AB4;
    private static final int PANEL = 0xFF0B1020;
    private static final int FRAME = 0xFF2E3E5A;
    private static final int TRACK = 0xFF1A2436;

    private final int dimensionId;
    private final MinespacePlanetDimensions.Planet destination;
    private int ticks;
    private int landingTicks = -1;

    public MinespaceTeleportingScreen(int dimensionId) {
        super(dimensionId);
        this.dimensionId = dimensionId;
        this.destination = MinespaceRocketTarget.bodyOf(dimensionId);
    }

    @Override
    public void initGui() {
        super.initGui();
        ticks = 0;
    }

    @Override
    public void updateScreen() {
        // A screen must never be able to take the client down: 6i was a NullPointerException in this very method and it
        // closed the whole game. Anything that goes wrong here now closes the screen and says so.
        try {
            tick();
        } catch (Throwable t) {
            org.apache.logging.log4j.LogManager.getLogger("minespace_navigation")
                    .error("star map: the arrival screen failed on update - closing it", t);
            close();
        }
    }

    private void tick() {
        // This is deliberately not Galacticraft's rule. Its version closes when a position comparison holds (posY
        // against posZ) and has no timeout, so a body whose spawn sits at a low z would pin the player on this screen.
        // Ours is "we are in the destination, or we have waited long enough", and it clears Galacticraft's forced-screen
        // field itself.
        ticks++;
        if (mc == null || mc.player == null || mc.player.world == null) {
            return;
        }
        if (mc.player.world.provider.getDimension() == dimensionId) {
            // The world is here. Galacticraft's own screen stays until the player starts descending, which is
            // exactly when the lander (or the ship) begins its descent; that is the landing the owner expects
            // to see. A timeout remains as the way out of a body that has no descent at all.
            if (landingTicks < 0) {
                landingTicks = 0;
            }
            landingTicks++;
            if (mc.player.posY < mc.player.prevPosY) {
                close();
            } else if (landingTicks > 20 * 60) {
                close();
            }
            return;
        }
        if (ticks > 20 * 60) {
            close();
        }
    }

    @Override
    public void drawScreen(int mouseX, int mouseY, float partialTicks) {
        try {
            draw(mouseX, mouseY, partialTicks);
        } catch (Throwable t) {
            org.apache.logging.log4j.LogManager.getLogger("minespace_navigation")
                    .error("star map: the arrival screen failed to draw - closing it", t);
            close();
        }
    }

    private void draw(int mouseX, int mouseY, float partialTicks) {
        // Our screen keeps the destination visible while it forms, under a light veil, instead of covering it with
        // Galacticraft's opaque loading background. The landing itself is GC's: the player is mounted in the lander
        // or ship before this screen closes, and the close below happens when that descent starts.
        drawRect(0, 0, width, height, 0x40000000);

        int panelW = 360;
        int panelH = 132;
        int x = (width - panelW) / 2;
        int y = (height - panelH) / 2;

        drawRect(x - 1, y - 1, x + panelW + 1, y + panelH + 1, FRAME);
        drawRect(x, y, x + panelW, y + panelH, PANEL);
        drawRect(x, y, x + panelW, y + 2, CYAN);
        drawRect(x, y + panelH - 2, x + panelW, y + panelH, 0xFF1E2C44);

        int cx = x + panelW / 2;
        String kicker = "MINESPACE  \u00b7  \u822a\u884c";
        drawCenteredString(fontRenderer, kicker, cx, y + 16, STEEL);

        String title = destination == null
                ? "\u6b63\u5728\u524d\u5f80  \u7ef4\u5ea6 " + dimensionId
                : "\u6b63\u5728\u524d\u5f80  " + destination.nameZh;
        drawCenteredString(fontRenderer, title, cx, y + 36, 0xFFFFFFFF);

        if (destination != null) {
            drawCenteredString(fontRenderer, where(), cx, y + 54, CYAN);
            drawCenteredString(fontRenderer, destination.name, cx, y + 68, STEEL);
        }

        int trackX = x + 26;
        int trackW = panelW - 52;
        int trackY = y + 94;
        drawRect(trackX, trackY, trackX + trackW, trackY + 4, TRACK);
        int bandW = trackW / 3;
        int span = trackW + bandW;
        int head = (ticks * 4) % span - bandW;
        int from = Math.max(trackX, trackX + head);
        int to = Math.min(trackX + trackW, trackX + head + bandW);
        if (to > from) {
            drawRect(from, trackY, to, trackY + 4, CYAN);
            drawRect(from, trackY, to, trackY + 1, AMBER);
        }

        String phase = landingTicks >= 0 ? "\u964d\u843d\u4e2d" : "\u4e16\u754c\u52a0\u8f7d\u4e2d";
        drawCenteredString(fontRenderer, phase, cx, y + 108, STEEL);
    }

    /** Get out of the way: close this screen and release Galacticraft's forced-screen field with it. */
    private void close() {
        if (mc != null) {
            mc.displayGuiScreen(null);
            micdoodle8.mods.galacticraft.core.tick.TickHandlerClient.teleportingGui = null;
        }
    }

    /** The system and the distance, from the catalog: AU inside the solar system, light years outside it. */
    private String where() {
        String system = destination.star.isEmpty() ? "" : destination.star + "  \u00b7  ";
        if (destination.orbitAu > 0.0F) {
            return system + destination.orbitAu + " AU";
        }
        if (destination.distanceLy > 0.0F) {
            return system + destination.distanceLy + " \u5149\u5e74";
        }
        return system.isEmpty() ? "" : destination.star;
    }
}
