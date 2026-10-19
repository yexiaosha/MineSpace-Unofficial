package com.minespace.unofficial.navigation;

import net.minecraft.entity.Entity;
import net.minecraft.util.math.BlockPos;
import net.minecraft.world.World;
import net.minecraftforge.common.util.ITeleporter;

/**
 * Where a rocket puts a player down: the destination's own ground, chosen here instead of by vanilla's exit search.
 *
 * <h2>Why this exists (6ez / 6f)</h2>
 *
 * <p>{@code changeDimension(dimensionId)} with no teleporter hands the job to vanilla's {@code Teleporter}, which looks
 * for a portal exit point and, doing that, loads and generates the destination's chunks from inside the dimension
 * change. In this pack that failed twice in a row - {@code RuntimeException: Already decorating!!} once, and a
 * {@code NullPointerException} inside {@code Teleporter} the next time - and both times the client had already been
 * sent its respawn packet, so it sat on "Downloading terrain" with the server idle behind it.</p>
 *
 * <p>What this pack actually wants is the one thing below: put the entity on the body's ground, at the destination's
 * spawn point, on top of whatever solid block is there - and at a fixed height in a world that has no ground yet, which
 * is every body whose terrain is still to come.</p>
 */
public final class MinespaceArrivalTeleporter implements ITeleporter {

    private final double arrivalY;

    /** Ground placement, used when no landing sequence is available. */
    public MinespaceArrivalTeleporter() {
        this(Double.NaN);
    }

    /** A fixed arrival altitude, used to begin a lander descent in the fallback path. */
    public MinespaceArrivalTeleporter(double arrivalY) {
        this.arrivalY = arrivalY;
    }

    @Override
    public void placeEntity(World world, Entity entity, float yaw) {
        BlockPos spawn = world.getSpawnPoint();
        double y = Double.isNaN(arrivalY) ? 64.0D : arrivalY;
        if (Double.isNaN(arrivalY) && !world.isAirBlock(spawn)) {
            BlockPos top = world.getTopSolidOrLiquidBlock(spawn);
            if (top.getY() > 0) {
                y = top.getY() + 1.0D;
            }
        }
        entity.setLocationAndAngles(spawn.getX() + 0.5D, y, spawn.getZ() + 0.5D, yaw, 0.0F);
    }

    @Override
    public boolean isVanilla() {
        return false;
    }
}
