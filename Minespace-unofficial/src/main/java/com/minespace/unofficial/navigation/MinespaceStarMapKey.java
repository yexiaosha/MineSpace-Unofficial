package com.minespace.unofficial.navigation;

import net.minecraft.client.Minecraft;
import net.minecraft.client.settings.KeyBinding;
import net.minecraftforge.common.MinecraftForge;
import net.minecraftforge.fml.client.event.ConfigChangedEvent;
import net.minecraftforge.fml.common.eventhandler.SubscribeEvent;
import net.minecraftforge.fml.common.gameevent.TickEvent;
import net.minecraftforge.fml.relauncher.Side;
import net.minecraftforge.fml.relauncher.SideOnly;
import org.lwjgl.input.Keyboard;

/**
 * Opens this pack's star map on M, client side only. J is kept as a second binding.
 *
 * <p>M is the key Galacticraft's own map used, and since 6ev this pack's map is the default one. The takeover is a
 * released binding rather than a mixin (see {@code NavigationClientProxy.releaseGalacticraftMapKey}): their key stays
 * in the controls list, so a player who wants that screen back can put a key on it there.</p>
 *
 * <p>Kept apart from the screen so that the screen can be opened from anywhere (a command, a research
 * machine's GUI, a keybind) without the screen knowing how it was reached.</p>
 */
@SideOnly(Side.CLIENT)
public final class MinespaceStarMapKey {

    public static final KeyBinding OPEN_MAP =
            new KeyBinding("Open the star map", Keyboard.KEY_M, "Minespace");

    /** The key this screen was on first, kept so nobody has to relearn it. */
    public static final KeyBinding OPEN_MAP_ALT =
            new KeyBinding("Open the star map (J)", Keyboard.KEY_J, "Minespace");

    private static boolean registered;

    private MinespaceStarMapKey() {
    }

    public static void register() {
        if (registered) {
            return;
        }
        registered = true;
        MinecraftForge.EVENT_BUS.register(MinespaceStarMapKey.class);
    }

    @SubscribeEvent
    public static void onClientTick(TickEvent.ClientTickEvent event) {
        if (event.phase != TickEvent.Phase.END) {
            return;
        }
        Minecraft mc = Minecraft.getMinecraft();
        // `|`, not `||`: isPressed() consumes the press, so both bindings have to be asked every pass.
        while (OPEN_MAP.isPressed() | OPEN_MAP_ALT.isPressed()) {
            mc.displayGuiScreen(new MinespaceStarMapScreen());
        }
        openForCapture();
    }

    /**
     * The camera: with -Dminespace.starmap.capture set, this is what opens the star map when nobody is
     * there to press J.
     *
     * <p>It waits for the main menu rather than firing at the first client tick, because the point is to
     * photograph the screen as a player sees it - after every mod has loaded, at the GUI scale the player
     * has set, with the game in a state that can be drawn.</p>
     */
    private static void openForCapture() {
        if (captureOpened || !MinespaceStarMapScreen.captureRequested()) {
            return;
        }
        Minecraft mc = Minecraft.getMinecraft();
        captureTicks++;
        // Five seconds of game loop is past every loading screen this pack has, and after that whatever is
        // on screen is the state a player would be looking at.
        boolean settled = captureTicks > 100;
        if (settled && mc.currentScreen != null
                && !(mc.currentScreen instanceof MinespaceStarMapScreen)) {
            org.apache.logging.log4j.LogManager.getLogger("minespace_navigation").info(
                    "star map capture: opening over {} after {} ticks",
                    mc.currentScreen.getClass().getName(), captureTicks);
            captureOpened = true;
            mc.displayGuiScreen(new MinespaceStarMapScreen());
            return;
        }
        if (captureTicks % 40 == 0) {
            org.apache.logging.log4j.LogManager.getLogger("minespace_navigation").info(
                    "star map capture: waiting, screen is {} after {} ticks",
                    mc.currentScreen == null ? "(null)" : mc.currentScreen.getClass().getName(),
                    captureTicks);
        }
    }

    private static boolean captureOpened;
    private static int captureTicks;
}
