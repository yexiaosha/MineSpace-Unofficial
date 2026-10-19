package com.minespace.unofficial.gtceu;

import net.minecraft.entity.EntityLiving;
import net.minecraft.entity.EntityLivingBase;
import net.minecraft.entity.EnumCreatureType;
import net.minecraft.entity.monster.EntityMob;
import net.minecraftforge.common.MinecraftForge;
import net.minecraftforge.common.config.Configuration;
import net.minecraftforge.event.entity.EntityJoinWorldEvent;
import net.minecraftforge.event.entity.living.LivingSetAttackTargetEvent;
import net.minecraftforge.event.entity.living.LivingEvent.LivingUpdateEvent;
import net.minecraftforge.fml.common.eventhandler.SubscribeEvent;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.File;

/**
 * Makes hostile mobs neutral without removing them from the world.
 *
 * <p>Vanilla and most modded monsters keep their movement/idle AI, but their target-task list
 * is emptied and any target set later is cleared. Creepers therefore do not swell, skeletons do
 * not aim, and bosses do not acquire the player as a target; the entities still exist and can be
 * attacked normally.</p>
 */
public final class MinespacePassiveMobs {

    private static final Logger LOG = LogManager.getLogger("minespace_core");
    private static boolean enabled;
    private static boolean registered;

    private MinespacePassiveMobs() {
    }

    public static void configure(File configFile) {
        Configuration config = new Configuration(configFile);
        config.load();
        enabled = config.getBoolean(
                "passiveHostileMobs", "mobs", true,
                "Keep hostile mobs in the world, but stop them from targeting or attacking players.");
        if (config.hasChanged()) {
            config.save();
        }
        LOG.info("Passive hostile mobs: {}", enabled ? "enabled" : "disabled");
    }

    public static void register() {
        if (enabled && !registered) {
            registered = true;
            MinecraftForge.EVENT_BUS.register(MinespacePassiveMobs.class);
        }
    }

    @SubscribeEvent
    public static void onEntityJoin(EntityJoinWorldEvent event) {
        if (event.getWorld().isRemote || !(event.getEntity() instanceof EntityLiving)) {
            return;
        }
        EntityLiving living = (EntityLiving) event.getEntity();
        if (isHostile(living)) {
            living.targetTasks.taskEntries.clear();
            living.setAttackTarget(null);
        }
    }

    @SubscribeEvent
    public static void onTargetSet(LivingSetAttackTargetEvent event) {
        EntityLivingBase entity = event.getEntityLiving();
        if (event.getTarget() != null && entity instanceof EntityLiving
                && isHostile(entity)) {
            ((EntityLiving) entity).setAttackTarget(null);
        }
    }

    @SubscribeEvent
    public static void onLivingUpdate(LivingUpdateEvent event) {
        EntityLivingBase entity = event.getEntityLiving();
        if (entity instanceof EntityLiving
                && ((EntityLiving) entity).getAttackTarget() != null
                && isHostile(entity)) {
            ((EntityLiving) entity).setAttackTarget(null);
        }
    }

    private static boolean isHostile(EntityLivingBase entity) {
        return entity instanceof EntityMob
                || entity.isCreatureType(EnumCreatureType.MONSTER, false);
    }
}
