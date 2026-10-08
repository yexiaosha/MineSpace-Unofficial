package com.minespace.unofficial.gtceu;

import net.minecraft.block.state.IBlockState;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * Client-side model probe used by the stone-type check.
 *
 * <h2>Why this lives in its own class</h2>
 *
 * It has to be somewhere that is <em>not</em> a {@code @Mod.EventBusSubscriber}.
 * Forge registers those with {@code Class.getDeclaredMethods()}, which resolves every
 * method's parameter and return types — so a private helper taking
 * {@code BlockRendererDispatcher} makes the whole mod fail to load on a dedicated
 * server with {@code NoClassDefFoundError: net/minecraft/client/renderer/BlockRendererDispatcher}.
 * Method <em>bodies</em> are not resolved that eagerly, so keeping the client types here
 * (referenced only from those bodies) is safe: this class is never handed to the event bus.
 */
final class MinespaceOreModelProbe {

    private static final Logger LOG = LogManager.getLogger("minespace");

    private MinespaceOreModelProbe() {
    }

    /** Resolves one state's model and reports what the renderer would get. */
    static void probe(net.minecraft.client.renderer.BlockRendererDispatcher dispatcher,
                      String label, IBlockState state) {
        if (state == null) {
            LOG.info("probe {}: state is null", label);
            return;
        }
        net.minecraft.client.renderer.block.model.IBakedModel model = dispatcher.getModelForState(state);
        if (model == null) {
            LOG.info("probe {}: no model", label);
            return;
        }
        int quads = model.getQuads(state, null, 0L).size();
        for (net.minecraft.util.EnumFacing facing : net.minecraft.util.EnumFacing.values()) {
            quads += model.getQuads(state, facing, 0L).size();
        }
        LOG.info("probe {}: {} quads, model {}", label, quads, model.getClass().getName());
    }

    /** The shared positive control: if this reports nothing, the check proves nothing. */
    static void probeVanillaStone(net.minecraft.client.renderer.BlockRendererDispatcher dispatcher) {
        probe(dispatcher, "vanilla stone", net.minecraft.init.Blocks.STONE.getDefaultState());
    }
}
