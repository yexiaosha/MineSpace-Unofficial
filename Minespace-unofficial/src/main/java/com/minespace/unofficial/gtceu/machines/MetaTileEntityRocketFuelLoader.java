package com.minespace.unofficial.gtceu.machines;

import com.minespace.unofficial.Minespace;
import gregtech.api.capability.impl.FluidTankList;
import gregtech.api.gui.GuiTextures;
import gregtech.api.gui.ModularUI;
import gregtech.api.gui.widgets.SlotWidget;
import gregtech.api.gui.widgets.TankWidget;
import gregtech.api.metatileentity.MetaTileEntity;
import gregtech.api.metatileentity.TieredMetaTileEntity;
import gregtech.api.metatileentity.interfaces.IGregTechTileEntity;
import micdoodle8.mods.galacticraft.api.entity.IFuelable;
import micdoodle8.mods.galacticraft.core.tile.TileEntityMulti;
import net.minecraft.entity.player.EntityPlayer;
import net.minecraft.item.ItemStack;
import net.minecraft.tileentity.TileEntity;
import net.minecraft.util.EnumFacing;
import net.minecraft.util.ResourceLocation;
import net.minecraftforge.common.capabilities.Capability;
import net.minecraftforge.fluids.FluidRegistry;
import net.minecraftforge.fluids.FluidStack;
import net.minecraftforge.fluids.FluidTank;
import net.minecraftforge.fluids.capability.CapabilityFluidHandler;
import net.minecraftforge.fluids.capability.IFluidHandlerItem;
import net.minecraftforge.items.IItemHandlerModifiable;
import net.minecraftforge.items.ItemStackHandler;

/**
 * GregTech replacement for Galacticraft's Fuel Loader.
 *
 * <h2>How it fills a rocket</h2>
 *
 * This copies Galacticraft's own mechanism instead of inventing one. Galacticraft's loader
 * looks at the six neighbouring tile entities every 100 ticks, unwraps a
 * {@link TileEntityMulti} to its main tile and remembers the first neighbour that is an
 * {@link IFuelable}; the landing pad tile implements that interface and forwards the fuel to
 * the rocket docked on it. Then, each tick, it hands 2 mB of its fuel to that neighbour and
 * drains whatever the neighbour accepted. The values here are the same: 2 mB per tick, the
 * neighbour scan every 100 ticks.
 *
 * <h2>Getting fuel in</h2>
 *
 * Two ways, both GregTech-shaped: a pipe (this machine exposes a fluid tank and only accepts
 * Galacticraft's {@code fuel}), or Galacticraft's own fuel canisters in the slot - they are
 * Forge fluid containers, so they are drained through the fluid handler capability and the
 * empty container is left in the slot.
 *
 * <p>Registered only when Galacticraft is present, and every Galacticraft call is behind
 * {@link Minespace#hasGalacticraft()}, so this class is never loaded in a pack without it.
 */
public class MetaTileEntityRocketFuelLoader extends TieredMetaTileEntity {

    /** Galacticraft registers its rocket fuel as "fuel" (checked at runtime, not assumed). */
    public static final String FUEL_FLUID_NAME = "fuel";

    public static final int TANK_CAPACITY = 16000;
    /** Galacticraft's own loader pushes 2 mB per tick; same here. */
    public static final int FUEL_PER_TICK = 2;
    /** Canister draining: one bucket a tick at most. */
    public static final int CANISTER_DRAIN_PER_TICK = 1000;
    public static final long ENERGY_PER_OPERATION = 8L;
    private static final int TARGET_SCAN_INTERVAL = 100;

    private final FluidTank fuelTank;
    private IFuelable fuelTarget;

    public MetaTileEntityRocketFuelLoader(ResourceLocation metaTileEntityId, int tier) {
        super(metaTileEntityId, tier);
        // Before initializeInventory(), which builds this machine's fluid handlers.
        this.fuelTank = new GalacticraftFuelTank(TANK_CAPACITY);
        initializeInventory();
    }

    @Override
    public MetaTileEntity createMetaTileEntity(IGregTechTileEntity tileEntity) {
        return new MetaTileEntityRocketFuelLoader(metaTileEntityId, getTier());
    }

    /** One slot: a filled Galacticraft fuel canister goes in, the empty one comes back out. */
    @Override
    protected IItemHandlerModifiable createImportItemHandler() {
        return new ItemStackHandler(1);
    }

    @Override
    protected IItemHandlerModifiable createExportItemHandler() {
        return new ItemStackHandler(0);
    }

    @Override
    protected FluidTankList createImportFluidHandler() {
        return new FluidTankList(false, fuelTank);
    }

    @Override
    protected FluidTankList createExportFluidHandler() {
        return new FluidTankList(false);
    }

    @Override
    protected ModularUI createUI(EntityPlayer entityPlayer) {
        return ModularUI.builder(GuiTextures.BACKGROUND, 176, 166)
                .label(10, 5, getMetaFullName())
                .widget(new SlotWidget(importItems, 0, 79, 34, true, false)
                        .setBackgroundTexture(GuiTextures.SLOT))
                .widget(new TankWidget(fuelTank, 45, 20, 18, 60)
                        .setBackgroundTexture(GuiTextures.FLUID_SLOT))
                .bindPlayerInventory(entityPlayer.inventory, GuiTextures.SLOT, 84)
                .build(getHolder(), entityPlayer);
    }

    @Override
    public void update() {
        super.update();
        if (getWorld() == null || getWorld().isRemote || !Minespace.hasGalacticraft()) {
            return;
        }

        drainCanister();

        if (getOffsetTimer() % TARGET_SCAN_INTERVAL == 0) {
            fuelTarget = findFuelTarget();
        }
        if (fuelTarget == null) {
            return;
        }

        FluidStack fuel = fuelTank.getFluid();
        int available = fuel == null ? 0 : Math.min(fuel.amount, FUEL_PER_TICK);
        if (available <= 0 || energyContainer.getEnergyStored() < ENERGY_PER_OPERATION) {
            return;
        }

        int accepted = fuelTarget.addFuel(new FluidStack(fuel.getFluid(), available), true);
        if (accepted > 0) {
            fuelTank.drain(accepted, true);
            energyContainer.changeEnergy(-ENERGY_PER_OPERATION);
            markDirty();
        }
    }

    /**
     * The neighbour scan from Galacticraft's own loader: the landing pad next to (or under)
     * this machine is the {@link IFuelable}, and the pad forwards the fuel to the rocket
     * standing on it.
     */
    private IFuelable findFuelTarget() {
        for (EnumFacing facing : EnumFacing.values()) {
            TileEntity neighbour = getWorld().getTileEntity(getPos().offset(facing));
            if (neighbour == null) {
                continue;
            }
            if (neighbour instanceof TileEntityMulti) {
                neighbour = ((TileEntityMulti) neighbour).getMainBlockTile();
            }
            if (neighbour instanceof IFuelable) {
                return (IFuelable) neighbour;
            }
        }
        return null;
    }

    /** Empties a Galacticraft fuel canister into the buffer tank, leaving the empty can. */
    private void drainCanister() {
        ItemStack canister = importItems.getStackInSlot(0);
        if (canister.isEmpty() || fuelTank.getFluidAmount() >= fuelTank.getCapacity()) {
            return;
        }
        IFluidHandlerItem handler =
                canister.getCapability(CapabilityFluidHandler.FLUID_HANDLER_ITEM_CAPABILITY, null);
        if (handler == null) {
            return;
        }
        FluidStack drained = handler.drain(new FluidStack(fuelTank.getFluid() == null
                ? net.minecraftforge.fluids.FluidRegistry.getFluid(FUEL_FLUID_NAME)
                : fuelTank.getFluid().getFluid(), CANISTER_DRAIN_PER_TICK), true);
        if (drained == null || drained.amount <= 0) {
            return;
        }
        if (fuelTank.fill(drained, true) > 0) {
            importItems.setStackInSlot(0, handler.getContainer());
            markDirty();
        }
    }

    /** Only Galacticraft's rocket fuel, so a pipe cannot park diesel in it. */
    private static final class GalacticraftFuelTank extends FluidTank {

        GalacticraftFuelTank(int capacity) {
            super(capacity);
        }

        @Override
        public boolean canFillFluidType(FluidStack fluid) {
            return fluid != null && FUEL_FLUID_NAME.equals(FluidRegistry.getFluidName(fluid));
        }
    }
}
