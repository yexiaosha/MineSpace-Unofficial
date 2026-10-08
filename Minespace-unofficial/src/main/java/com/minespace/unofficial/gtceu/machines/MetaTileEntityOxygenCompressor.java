package com.minespace.unofficial.gtceu.machines;

import gregtech.api.capability.impl.FluidTankList;
import gregtech.api.gui.GuiTextures;
import gregtech.api.gui.ModularUI;
import gregtech.api.gui.widgets.SlotWidget;
import gregtech.api.gui.widgets.TankWidget;
import gregtech.api.metatileentity.MetaTileEntity;
import gregtech.api.metatileentity.TieredMetaTileEntity;
import gregtech.api.metatileentity.interfaces.IGregTechTileEntity;
import net.minecraft.entity.player.EntityPlayer;
import net.minecraft.item.Item;
import net.minecraft.item.ItemStack;
import net.minecraft.util.ResourceLocation;
import net.minecraftforge.fluids.FluidRegistry;
import net.minecraftforge.fluids.FluidStack;
import net.minecraftforge.fluids.FluidTank;
import net.minecraftforge.items.IItemHandlerModifiable;
import net.minecraftforge.items.ItemStackHandler;

/**
 * GregTech replacement for Galacticraft's Oxygen Compressor.
 *
 * <h2>Why this machine exists</h2>
 *
 * Galacticraft's oxygen chain (Collector -&gt; pipes -&gt; Compressor -&gt; tanks) is being taken
 * out of the pack in favour of GregTech machines, but Galacticraft's oxygen tanks cannot be
 * filled by a normal GregTech recipe: the tank's contents live in the stack's <b>damage
 * value</b> (0 = empty, {@code getMaxDamage()} = full - the value Galacticraft's own
 * compressor adds to and its decompressor subtracts from), and GregTech's canner can only
 * produce a fixed stack. So this is a real machine: it holds a buffer tank of Galacticraft's
 * oxygen fluid, and moves that oxygen into whichever tank is in its slot.
 *
 * <p>Because it extends {@link TieredMetaTileEntity} it gets GregTech's energy container, the
 * voltage casing texture, the wrench/paint behaviour and the item form
 * ({@code gregtech:machine:&lt;registry id&gt;}) for free - the item is created from the meta
 * tile entity registry, so no item or block registration is needed here.
 *
 * <h2>Rates</h2>
 *
 * Galacticraft's own compressor moves 2 units per operation and its decompressor empties at
 * the same step, so the transfer step here is 2 as well; energy is 4 EU per unit (8 EU per
 * operation) at LV. The buffer tank is 16000 mB, which is more than a heavy tank holds.
 */
public class MetaTileEntityOxygenCompressor extends TieredMetaTileEntity {

    /** Galacticraft registers its oxygen under this name (checked at runtime, not assumed). */
    public static final String OXYGEN_FLUID_NAME = "oxygen";

    public static final int TANK_CAPACITY = 16000;
    public static final int OXYGEN_PER_OPERATION = 2;
    public static final long ENERGY_PER_OPERATION = 8L;

    /** The three tanks Galacticraft ships (registry names, read out of the 4.0.7 jar). */
    private static final ResourceLocation[] GALACTICRAFT_TANKS = {
            new ResourceLocation("galacticraftcore", "oxygen_tank_light_full"),
            new ResourceLocation("galacticraftcore", "oxygen_tank_med_full"),
            new ResourceLocation("galacticraftcore", "oxygen_tank_heavy_full"),
    };

    private final FluidTank oxygenTank;

    public MetaTileEntityOxygenCompressor(ResourceLocation metaTileEntityId, int tier) {
        super(metaTileEntityId, tier);
        // Assigned before initializeInventory(), which is what builds the fluid handlers
        // around this tank. (TieredMetaTileEntity's own constructor does not do that for us -
        // GregTech's machines call initializeInventory() from their own constructor.)
        this.oxygenTank = new GalacticraftOxygenTank(TANK_CAPACITY);
        initializeInventory();
    }

    @Override
    public MetaTileEntity createMetaTileEntity(IGregTechTileEntity tileEntity) {
        return new MetaTileEntityOxygenCompressor(metaTileEntityId, getTier());
    }

    /** One slot: the oxygen tank to fill. Nothing is ever ejected from it. */
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
        return new FluidTankList(false, oxygenTank);
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
                .widget(new TankWidget(oxygenTank, 45, 20, 18, 60)
                        .setBackgroundTexture(GuiTextures.FLUID_SLOT))
                // 84 is GregTech's usual player-inventory row in a 166-high machine GUI; the
                // overload without it is bindPlayerInventory(InventoryPlayer, int).
                .bindPlayerInventory(entityPlayer.inventory, GuiTextures.SLOT, 84)
                // The UI holder is the tile entity holder, not the machine itself
                // (MetaTileEntity does not implement IUIHolder; its holder does).
                .build(getHolder(), entityPlayer);
    }

    @Override
    public void update() {
        super.update();
        if (getWorld() == null || getWorld().isRemote) {
            return;
        }

        ItemStack tank = importItems.getStackInSlot(0);
        if (tank.isEmpty() || !isGalacticraftOxygenTank(tank.getItem())) {
            return;
        }

        int capacity = tank.getMaxDamage();
        int stored = tank.getItemDamage();
        if (capacity <= 0 || stored >= capacity) {
            return; // malformed stack, or already full
        }

        FluidStack oxygen = oxygenTank.getFluid();
        if (oxygen == null || oxygen.amount < OXYGEN_PER_OPERATION) {
            return;
        }
        if (energyContainer.getEnergyStored() < ENERGY_PER_OPERATION) {
            return;
        }

        int moved = Math.min(OXYGEN_PER_OPERATION, capacity - stored);
        oxygenTank.drain(moved, true);
        energyContainer.changeEnergy(-ENERGY_PER_OPERATION);
        tank.setItemDamage(stored + moved);
        importItems.setStackInSlot(0, tank);
        markDirty();
    }

    private static boolean isGalacticraftOxygenTank(Item item) {
        for (ResourceLocation name : GALACTICRAFT_TANKS) {
            // Null without Galacticraft: the loop then simply never matches.
            if (Item.REGISTRY.getObject(name) == item) {
                return true;
            }
        }
        return false;
    }

    /**
     * A tank that only accepts Galacticraft's oxygen, so a pipe cannot park diesel in it.
     *
     * <p>The name is the Forge fluid registry name, and "oxygen" is Galacticraft's: its
     * alternative "fuelgc"/"oilgc" names do not appear at runtime, which is what a probe run
     * was used to check before this class was written.
     */
    private static final class GalacticraftOxygenTank extends FluidTank {

        GalacticraftOxygenTank(int capacity) {
            super(capacity);
        }

        @Override
        public boolean canFillFluidType(FluidStack fluid) {
            return fluid != null && OXYGEN_FLUID_NAME.equals(FluidRegistry.getFluidName(fluid));
        }
    }
}
