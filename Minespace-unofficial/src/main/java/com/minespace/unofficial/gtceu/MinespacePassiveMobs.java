package com.minespace.unofficial.gtceu;

import net.minecraft.entity.Entity;
import net.minecraft.entity.EntityLiving;
import net.minecraft.entity.EntityLivingBase;
import net.minecraft.entity.EnumCreatureType;
import net.minecraft.entity.boss.EntityDragon;
import net.minecraft.entity.boss.EntityWither;
import net.minecraft.entity.monster.EntityMob;
import net.minecraft.entity.player.EntityPlayer;
import net.minecraftforge.common.MinecraftForge;
import net.minecraftforge.common.config.Configuration;
import net.minecraftforge.event.entity.EntityJoinWorldEvent;
import net.minecraftforge.event.entity.living.LivingHurtEvent;
import net.minecraftforge.event.entity.living.LivingSetAttackTargetEvent;
import net.minecraftforge.event.entity.living.LivingEvent.LivingUpdateEvent;
import net.minecraftforge.fml.common.eventhandler.SubscribeEvent;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.File;
import java.util.Map;
import java.util.UUID;
import java.util.WeakHashMap;

/**
 * Hostile mobs do not initiate combat, but retaliate after a player damages them.
 *
 * <p>Target tasks stay installed; targets are filtered instead. A mob with no recent player
 * attacker has its target cleared. Damaging a mob records that player for 30 seconds and sets
 * the mob's target, so creepers can swell, skeletons can shoot and melee mobs can hit back.
 * Bosses (the dragon, the wither, and modded entity classes whose names contain "boss")
 * keep their normal AI.</p>
 */
public final class MinespacePassiveMobs {

    private static final Logger LOG = LogManager.getLogger("minespace_core");
    private static final int RETALIATION_TICKS = 600;
    private static final Map<EntityLiving, Provoked> PROVOKED = new WeakHashMap<>();
    private static boolean enabled;
    private static boolean registered;

    private MinespacePassiveMobs() {
    }

    public static void configure(File configFile) {
        Configuration config = new Configuration(configFile);
        config.load();
        enabled = config.getBoolean(
                "passiveHostileMobs", "mobs", true,
                "Hostile mobs do not initiate combat; the player they attack retaliates. Bosses keep normal AI.");
        if (config.hasChanged()) {
            config.save();
        }
        LOG.info("Neutral hostile mobs: {}", enabled ? "enabled" : "disabled");
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
        if (isHostile(living) && !isBoss(living)) {
            living.setAttackTarget(null);
        }
    }

    @SubscribeEvent
    public static void onHurt(LivingHurtEvent event) {
        EntityLivingBase victim = event.getEntityLiving();
        if (!(victim instanceof EntityLiving) || isBoss(victim) || !isHostile(victim)) {
            return;
        }
        Entity source = event.getSource().getTrueSource();
        if (source == null) {
            source = event.getSource().getImmediateSource();
        }
        if (!(source instanceof EntityPlayer)) {
            return;
        }
        EntityPlayer player = (EntityPlayer) source;
        EntityLiving living = (EntityLiving) victim;
        PROVOKED.put(living, new Provoked(player.getUniqueID(),
                living.world.getTotalWorldTime() + RETALIATION_TICKS));
        living.setAttackTarget(player);
    }

    @SubscribeEvent
    public static void onTargetSet(LivingSetAttackTargetEvent event) {
        EntityLivingBase entity = event.getEntityLiving();
        if (event.getTarget() == null || !(entity instanceof EntityLiving)
                || isBoss(entity) || !isHostile(entity)) {
            return;
        }
        EntityLiving living = (EntityLiving) entity;
        Provoked provoked = PROVOKED.get(living);
        if (provoked == null || provoked.expired(living.world.getTotalWorldTime())
                || !(event.getTarget() instanceof EntityPlayer)
                || !provoked.player.equals(((EntityPlayer) event.getTarget()).getUniqueID())) {
            living.setAttackTarget(null);
        }
    }

    @SubscribeEvent
    public static void onLivingUpdate(LivingUpdateEvent event) {
        EntityLivingBase entity = event.getEntityLiving();
        if (!(entity instanceof EntityLiving) || isBoss(entity) || !isHostile(entity)) {
            return;
        }
        EntityLiving living = (EntityLiving) entity;
        EntityLivingBase target = living.getAttackTarget();
        if (target == null) {
            return;
        }
        Provoked provoked = PROVOKED.get(living);
        long now = living.world.getTotalWorldTime();
        if (provoked == null || provoked.expired(now)
                || !(target instanceof EntityPlayer)
                || !provoked.player.equals(((EntityPlayer) target).getUniqueID())) {
            living.setAttackTarget(null);
        }
    }

    private static boolean isHostile(EntityLivingBase entity) {
        return entity instanceof EntityMob
                || entity.isCreatureType(EnumCreatureType.MONSTER, false);
    }

    private static boolean isBoss(EntityLivingBase entity) {
        return entity instanceof EntityDragon
                || entity instanceof EntityWither
                || entity.getMaxHealth() >= 200.0F
                || entity.getClass().getName().toLowerCase(java.util.Locale.ROOT).contains("boss");
    }

    private static final class Provoked {
        private final UUID player;
        private final long expiresAt;

        private Provoked(UUID player, long expiresAt) {
            this.player = player;
            this.expiresAt = expiresAt;
        }

        private boolean expired(long now) {
            return now > expiresAt;
        }
    }
}
