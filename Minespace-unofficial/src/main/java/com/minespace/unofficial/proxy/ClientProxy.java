package com.minespace.unofficial.proxy;

import net.minecraftforge.fml.common.event.FMLInitializationEvent;
import net.minecraftforge.fml.common.event.FMLPostInitializationEvent;
import net.minecraftforge.fml.common.event.FMLPreInitializationEvent;

/**
 * Client-only half of the proxy: model/texture registration and other classes that would
 * crash a dedicated server if they were loaded there.
 */
public class ClientProxy extends CommonProxy {

    @Override
    public void preInit(FMLPreInitializationEvent event) {
        super.preInit(event);
        // Client-side model and colour handlers go here.
    }

    @Override
    public void init(FMLInitializationEvent event) {
        super.init(event);
        // The star map keybind. J on purpose: M already opens Galacticraft's map and this pack's own
        // screen is a different document, not a replacement for it yet.
        net.minecraftforge.fml.client.registry.ClientRegistry.registerKeyBinding(
                com.minespace.unofficial.gtceu.MinespaceStarMapKey.OPEN_MAP);
        com.minespace.unofficial.gtceu.MinespaceStarMapKey.register();

        // One model per research-data tier: a Forge item with subtypes needs its own model resource location per
        // metadata value, and these names are the ones tools\build-research-art.ps1 writes.
        for (int tier = 1; tier <= com.minespace.unofficial.gtceu.MinespaceResearchData.TIERS; tier++) {
            net.minecraftforge.client.model.ModelLoader.setCustomModelResourceLocation(
                    com.minespace.unofficial.gtceu.MinespaceResearchData.ITEM, tier,
                    new net.minecraft.client.renderer.block.model.ModelResourceLocation(
                            "minespace:research_data_" + tier, "inventory"));
        }
    }

    @Override
    public void postInit(FMLPostInitializationEvent event) {
        super.postInit(event);
    }

    @Override
    public boolean isClient() {
        return true;
    }
}
