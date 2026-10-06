package com.minespace.unofficial.gtceu;

import net.minecraftforge.common.MinecraftForge;
import net.minecraftforge.fml.common.eventhandler.SubscribeEvent;
import net.minecraftforge.fml.common.gameevent.TickEvent;

/**
 * Runs the ore-model probe once, on the first client tick.
 *
 * <h2>Why not during init</h2>
 *
 * The obvious place for a model check is {@code FMLInitializationEvent}, and it is the
 * wrong one: at that point the model registry still answers with unbaked stand-ins, so a
 * perfectly good block reports zero quads and the check cries wolf. That is not
 * hypothetical — it is exactly what happened while this was being written, and it sent a
 * whole debugging round chasing a model bug that did not exist. The first client tick is
 * the earliest moment a model answer means anything, and by then the main menu is up.
 *
 * <p>Deliberately not a {@code @Mod.EventBusSubscriber}: {@link #register()} already
 * registers this on the Forge bus, and doing both would register it twice. The tick
 * listener stays registered afterwards, but the {@code done} flag makes it free.
 */
public final class MinespaceModelCheck {

    private static boolean registered;
    private static boolean done;

    private MinespaceModelCheck() {
    }

    /** Called from this mod's init, which is early enough for the first tick. */
    public static void register() {
        if (!registered) {
            registered = true;
            MinecraftForge.EVENT_BUS.register(MinespaceModelCheck.class);
        }
    }

    @SubscribeEvent
    public static void onClientTick(TickEvent.ClientTickEvent event) {
        if (done || event.phase != TickEvent.Phase.END) {
            return;
        }
        done = true;
        MinespaceStoneTypes.probeOreModels();
    }
}
