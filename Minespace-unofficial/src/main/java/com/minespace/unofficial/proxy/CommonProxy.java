package com.minespace.unofficial.proxy;

import net.minecraftforge.fml.common.event.FMLInitializationEvent;
import net.minecraftforge.fml.common.event.FMLPostInitializationEvent;
import net.minecraftforge.fml.common.event.FMLPreInitializationEvent;

/**
 * Server-side (and shared) half of the proxy. Everything that must not touch client-only
 * classes lives here or in a class this one delegates to.
 */
public class CommonProxy {

    public void preInit(FMLPreInitializationEvent event) {
        // Register blocks, items, config here.
    }

    public void init(FMLInitializationEvent event) {
        // Register recipes, world generators, event handlers here.
    }

    public void postInit(FMLPostInitializationEvent event) {
        // Cross-mod integration that needs every mod to be loaded goes here.
    }

    public boolean isClient() {
        return false;
    }
}
