package com.minespace.unofficial.gtceu;

import com.minespace.unofficial.Minespace;
import gregtech.api.recipes.Recipe;
import gregtech.api.recipes.RecipeMap;
import net.minecraft.item.Item;
import net.minecraft.item.ItemStack;
import net.minecraft.item.crafting.FurnaceRecipes;
import net.minecraft.util.ResourceLocation;
import net.minecraftforge.fml.common.registry.ForgeRegistries;
import net.minecraftforge.oredict.OreDictionary;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Removes the "free" producers Gregicality generates for Galacticraft's compressed plates.
 *
 * <h2>The problem</h2>
 *
 * Galacticraft's compressed plate is this pack's "dense" tier for its metals, and
 * {@code gc_processing.zs} sets its price: an implosion compressor, two GregTech plates plus
 * TNT. It is not the only way to make one. Gregicality unifies a mod's material forms onto GregTech's
 * machines, and because Galacticraft registers those plates in the ore dictionary it generated a full
 * set of "make this item out of GregTech material" recipes for them - and they are ruinous. Read out of
 * the finished maps with a probe:
 *
 * <pre>
 *   metal_bender      1 steel INGOT          -&gt; 1 compressed steel plate
 *   alloy_smelter     2 steel ingots + mold  -&gt; 1
 *   forge_hammer      3 steel ingots         -&gt; 2
 *   extruder          1 steel ingot + mold   -&gt; 1
 *   cutting_saw       1 steel BLOCK          -&gt; 9
 *   fluid_solidifier                         the same item again
 * </pre>
 *
 * <p>And one more, in a registry the machine maps do not cover - vanilla smelting, which is what JEI
 * shows under its own tab:</p>
 *
 * <pre>
 *   furnace   plateSteelMagnetic -&gt; 1 compressed steel plate
 *   furnace   plateIronMagnetic  -&gt; 1 compressed iron plate
 * </pre>
 *
 * <p>That is why the dense plate stayed cheap however the pack's own recipes were written: the ore
 * dictionary was clean (a probe found zero ingredients mixing a Galacticraft compressed plate with a
 * GregTech plate), the <em>producers</em> were the leak. Every Galacticraft compressed plate is
 * affected, not just steel.</p>
 *
 * <h2>The second half of the same bug: the plain plates lost their producers</h2>
 *
 * <p>Gregicality writes those recipes with {@code OreDictUnifier.get(OrePrefix.plate, material)} as the
 * <em>output</em> as well, and that call returns the first stack in the ore dictionary name - which for
 * these nine metals was the mod's compressed plate. So the recipes this guard deletes were not extra
 * recipes: they were GregTech's own plate recipes, mis-pointed at the wrong item. Deleting them left
 * {@code plateCopper}, {@code plateTin}, {@code plateIron}, {@code plateSteel}, {@code plateBronze},
 * {@code plateDesh}, {@code plateTitanium}, {@code plateCobalt} and {@code plateNickel} with no source at
 * all, which a progression probe over the finished registries found as nine dead leaves (their only
 * remaining "producers" were disassembler chance outputs).</p>
 *
 * <p>So the recipe is not deleted any more - its output is re-pointed at the plain GregTech plate whose
 * material it belongs to. The bender, forge hammer, extruder, cutting saw, alloy smelter and fluid
 * solidifier routes for those nine metals come back exactly as Gregicality meant them, and the compressed
 * plate still has no producer outside the implosion compressor. Removal is kept as the fallback for a
 * recipe whose plain plate cannot be resolved, so the compressed plate can never leak back in.</p>
 *
 * <p>The crafting-table half of the same hijack ({@code plate_x} / {@code flatten_plate_x}, which also
 * output the compressed plate) cannot be re-pointed from here, because CraftTweaker owns the crafting
 * registry and the recipe is a Forge {@code ShapedOreRecipe}; {@code plate_bridge.zs} removes those and
 * rebuilds GregTech's hammer-plus-two-ingots shape.</p>
 *
 * <p>Two of the eleven plates in {@link #COMPRESSED_PLATES} are the pack's own as well as being
 * hijacked: Galaxy Space's cobalt and nickel plate stay in the compressor at the mod's own cost
 * ({@link #KEPT_RECIPES}) because Galaxy Space's own machines are built from them, and only their
 * Gregicality-generated plate recipes - one ingot in a bender for a "compressed" plate, cheaper than
 * the pack's own two-ingot recipe - are re-pointed like the other nine. Compressed desh is the mirror
 * image: the pack had an implosion recipe for every other Galacticraft metal but not for desh, so once
 * the mis-pointed recipes were dealt with it had no producer at all; that recipe is in
 * {@code gc_processing.zs}, with the other seven.</p>
 *
 * <h2>Why this is Java and not a script</h2>
 *
 * Because it runs too late for CraftTweaker. The pack's own rule (TJ-MIGRATION-PLAN.md, section 6e) is
 * that a mod which registers recipes after CraftTweaker's recipe pass can only be undone in that mod's
 * own config or "through a late removal in the addon (FMLLoadCompleteEvent), never through a script" -
 * and Gregicality registers these in its own init / postInit. CraftTweaker's GT integration also
 * exposes no recipe-removal method for a machine map (`ccGetRecipeList` is not a ZenScript member), so
 * the fix lives here.
 *
 * <p>{@link #removeCheapProducers()} is called twice - from this mod's postInit and again from
 * {@code FMLLoadCompleteEvent} - and is idempotent. Whichever call sees Gregicality's recipes first
 * does the work; the log line says which, and how many.</p>
 *
 * <h2>What is deliberately kept</h2>
 *
 * The {@code implosion_compressor} map is not touched: that is where this pack's own recipes for these
 * plates live (`plateX` x2 + explosives -&gt; the compressed plate), and cutting it would delete the
 * route the pack intends. The recipe Gregicality leaves in that map has empty item inputs, so it can
 * never match a machine - it is one of the two baseline {@code Invalid recipe} lines in the log.
 */
public final class MinespaceCompressedPlateGuard {

    private MinespaceCompressedPlateGuard() {
    }

    /**
     * Galacticraft's and Galaxy Space's compressed plates - the pack's "dense" tier for these metals.
     *
     * <p>Galaxy Space's cobalt and nickel plate are in the set even though the pack <em>wants</em> them
     * made (see {@link #KEPT_RECIPES}): Gregicality generated its plate recipes against those items as
     * well, and a bender turning one cobalt ingot into one "compressed" plate undercut the pack's own
     * two-ingot compressor recipe.</p>
     */
    private static final Set<String> COMPRESSED_PLATES = new HashSet<>(Arrays.asList(
            "galacticraftcore:basic_item:6",               // compressed copper
            "galacticraftcore:basic_item:7",               // compressed tin
            "galacticraftcore:basic_item:8",               // compressed aluminium
            "galacticraftcore:basic_item:9",               // compressed steel
            "galacticraftcore:basic_item:10",              // compressed bronze
            "galacticraftcore:basic_item:11",              // compressed iron
            "galacticraftcore:item_basic_moon:1",          // compressed meteoric iron
            "galacticraftplanets:item_basic_asteroids:6",  // compressed titanium
            "galacticraftplanets:item_basic_mars:5",       // compressed desh
            "galaxyspace:compressed_plates:1",             // "compressed" cobalt (Galaxy Space)
            "galaxyspace:compressed_plates:3"              // "compressed" nickel (Galaxy Space)
    ));

    /**
     * Recipes of the pack's own that must survive the re-point, per compressed plate.
     *
     * <p>Galaxy Space's cobalt and nickel plate are the pack's dense tier for those two metals and stay
     * at the mod's own cost - {@code gs_removals.zs} writes them as two ingots into one plate in the
     * compressor, "Costs are GS's own; only the machine changed", because Galaxy Space's own machines
     * are built from them. Gregicality's plate recipes for the same two metals are the hijack here and
     * are re-pointed like the other seven; the compressor entry is the pack's, and is left alone.</p>
     */
    private static final Map<String, Set<String>> KEPT_RECIPES = new LinkedHashMap<>();

    static {
        KEPT_RECIPES.put("galaxyspace:compressed_plates:1", new HashSet<>(Arrays.asList("compressor")));
        KEPT_RECIPES.put("galaxyspace:compressed_plates:3", new HashSet<>(Arrays.asList("compressor")));
    }

    /**
     * Maps left alone.
     *
     * <p>{@code implosion_compressor} - the pack's own recipes for these plates live there
     * ({@code plateX} x2 + explosives).</p>
     *
     * <p>{@code electric_implosion} - this one was swept by the first version of this guard and had to
     * be put back. That map is the *Electric Implosion Compressor*, Gregicality's "implosion without
     * explosives" machine: a UV multiblock whose controller is itself built in GregTech's Assembly
     * Line (491,520 EU/t, 48,000 ticks, from 64 long osmium sticks, 64 osmium rings, 16 UV
     * superconductor wires, 16 UV circuits, 2 Incoloy-MA blocks and a regular Implosion Compressor).
     * Its recipes turn two plates into one compressed plate with no TNT - the same material cost as
     * the pack's own route - at 375,000 EU/t, i.e. a late-game mass-production convenience, not a
     * shortcut. Removing them gutted the machine's reason to exist. The cheap routes are the
     * *crafting-age* machines above, not this one.</p>
     */
    private static final Set<String> KEPT_MAPS = new HashSet<>(Arrays.asList(
            "implosion_compressor",
            "electric_implosion"
    ));

    /**
     * The plain GregTech plate each compressed plate was mistaken for, by ore dictionary name.
     *
     * <p>The GregTech stack itself is picked out of the name at runtime ({@link #plainPlateFor}) rather
     * than hard-coded, so a re-ordered ore dictionary cannot silently point a recipe at the wrong item.
     * The damage values in {@link #PLAIN_PLATE_DAMAGE} are only the fallback for the case that the name
     * holds no GregTech stack at all.</p>
     */
    private static final Map<String, String> PLAIN_PLATE_NAMES = new LinkedHashMap<>();
    private static final Map<String, Integer> PLAIN_PLATE_DAMAGE = new LinkedHashMap<>();

    static {
        // Galacticraft's compressed copper / tin / steel / bronze / iron, Galacticraft Planet's desh and
        // titanium, Galaxy Space's cobalt and nickel.
        plate("galacticraftcore:basic_item:6", "plateCopper", 12018);
        plate("galacticraftcore:basic_item:7", "plateTin", 12071);
        plate("galacticraftcore:basic_item:9", "plateSteel", 12184);
        plate("galacticraftcore:basic_item:10", "plateBronze", 12095);
        plate("galacticraftcore:basic_item:11", "plateIron", 12033);
        plate("galacticraftplanets:item_basic_asteroids:6", "plateTitanium", 12072);
        plate("galacticraftplanets:item_basic_mars:5", "plateDesh", 12000);
        plate("galaxyspace:compressed_plates:1", "plateCobalt", 12017);
        plate("galaxyspace:compressed_plates:3", "plateNickel", 12044);
    }

    private static void plate(String compressedId, String plainPlateOreName, int plainPlateDamage) {
        PLAIN_PLATE_NAMES.put(compressedId, plainPlateOreName);
        PLAIN_PLATE_DAMAGE.put(compressedId, plainPlateDamage);
    }

    /**
     * Re-points every non-kept-map recipe whose output is a Galacticraft compressed plate back at the
     * plain GregTech plate of the same metal, and removes any it cannot re-point.
     *
     * @return the number of recipes changed by this call (0 when there was nothing left to do)
     */
    public static int repointCheapProducers(String phase) {
        int repointed = 0;
        int removed = 0;
        for (RecipeMap<?> map : RecipeMap.getRecipeMaps()) {
            String mapName = map.getUnlocalizedName();
            if (KEPT_MAPS.contains(mapName)) {
                continue;
            }
            Collection<Recipe> recipes;
            try {
                recipes = map.getRecipeList();
            } catch (Throwable t) {
                continue;
            }
            List<Recipe> victims = new ArrayList<>();
            for (Recipe recipe : recipes) {
                for (ItemStack output : recipe.getOutputs()) {
                    if (COMPRESSED_PLATES.contains(idOf(output))) {
                        victims.add(recipe);
                        break;
                    }
                }
            }
            if (victims.isEmpty()) {
                continue;
            }
            int changedHere = 0;
            int skippedHere = 0;
            for (Recipe victim : victims) {
                if (keepsPackRecipe(victim, mapName)) {
                    skippedHere++;
                    continue;
                }
                if (repointOutputs(victim)) {
                    repointed++;
                    changedHere++;
                } else {
                    try {
                        if (map.removeRecipe(victim)) {
                            removed++;
                            changedHere++;
                        }
                    } catch (Throwable t) {
                        Minespace.log().warn("compressed-plate guard: could not remove a recipe from {}",
                                mapName, t);
                    }
                }
            }
            Minespace.log().info("compressed-plate guard: {} recipes re-pointed in {}{}",
                    changedHere, mapName,
                    skippedHere == 0 ? "" : " (" + skippedHere + " of the pack's own left alone)");
        }

        // Vanilla smelting is a different registry from the machine maps, and it is what JEI shows in
        // its own "Smelting" tab. Gregicality's generator meant the plain plate there too (the inputs are
        // GregTech's own magnetic iron and steel plates), so the value is re-pointed rather than deleted.
        Map<ItemStack, ItemStack> smelting = FurnaceRecipes.instance().getSmeltingList();
        List<ItemStack> smeltingInputs = new ArrayList<>();
        for (Map.Entry<ItemStack, ItemStack> entry : smelting.entrySet()) {
            if (COMPRESSED_PLATES.contains(idOf(entry.getValue()))) {
                smeltingInputs.add(entry.getKey());
            }
        }
        for (ItemStack input : smeltingInputs) {
            ItemStack output = smelting.get(input);
            if (output == null) {
                continue;
            }
            ItemStack plain = plainPlateFor(idOf(output));
            if (plain.isEmpty()) {
                smelting.remove(input);
                removed++;
                Minespace.log().info("compressed-plate guard: removed smelting {} -> {}",
                        idOf(input), idOf(output));
            } else {
                plain.setCount(output.getCount());
                smelting.put(input, plain);
                repointed++;
                Minespace.log().info("compressed-plate guard: re-pointed smelting {} -> {} (was {})",
                        idOf(input), idOf(plain), idOf(output));
            }
        }

        if (repointed > 0 || removed > 0) {
            Minespace.log().info("compressed-plate guard ({} pass): {} Gregicality-generated "
                            + "compressed-plate producers re-pointed at the plain GregTech plate, {} removed "
                            + "because no plain plate could be resolved; the implosion compressor is the only "
                            + "route to a compressed plate", phase, repointed, removed);
        } else {
            Minespace.log().info("compressed-plate guard ({} pass): nothing left to change", phase);
        }
        return repointed + removed;
    }

    /** The plain GregTech plate that a compressed plate stands in for, or empty when it is unknown. */
    private static ItemStack plainPlateFor(String compressedId) {
        String oreName = PLAIN_PLATE_NAMES.get(compressedId);
        if (oreName != null) {
            for (ItemStack stack : OreDictionary.getOres(oreName, false)) {
                ResourceLocation name = ForgeRegistries.ITEMS.getKey(stack.getItem());
                if (name != null && "gregtech".equals(name.getResourceDomain())) {
                    ItemStack plain = stack.copy();
                    plain.setCount(1);
                    return plain;
                }
            }
        }
        Integer damage = PLAIN_PLATE_DAMAGE.get(compressedId);
        if (damage != null) {
            Item item = ForgeRegistries.ITEMS.getValue(new ResourceLocation("gregtech:meta_item_1"));
            if (item != null) {
                return new ItemStack(item, 1, damage);
            }
        }
        return ItemStack.EMPTY;
    }

    /** Re-points every compressed-plate output of one recipe; false when one of them cannot be resolved. */
    private static boolean repointOutputs(Recipe recipe) {
        boolean changed = false;
        List<ItemStack> outputs = recipe.getOutputs();
        for (int i = 0; i < outputs.size(); i++) {
            ItemStack output = outputs.get(i);
            String id = idOf(output);
            if (!COMPRESSED_PLATES.contains(id)) {
                continue;
            }
            ItemStack plain = plainPlateFor(id);
            if (plain.isEmpty()) {
                return false;
            }
            plain.setCount(output.getCount());
            outputs.set(i, plain);
            changed = true;
        }
        return changed;
    }

    /**
     * True when every compressed-plate output of this recipe is one the pack keeps in this map - that
     * is, a recipe the pack wrote itself rather than one Gregicality generated through the ore
     * dictionary.
     */
    private static boolean keepsPackRecipe(Recipe recipe, String mapName) {
        boolean sawKept = false;
        for (ItemStack output : recipe.getOutputs()) {
            String id = idOf(output);
            if (!COMPRESSED_PLATES.contains(id)) {
                continue;
            }
            Set<String> keptMaps = KEPT_RECIPES.get(id);
            if (keptMaps == null || !keptMaps.contains(mapName)) {
                return false;
            }
            sawKept = true;
        }
        return sawKept;
    }

    private static String idOf(ItemStack stack) {
        if (stack == null || stack.isEmpty()) {
            return "<empty>";
        }
        ResourceLocation name = ForgeRegistries.ITEMS.getKey(stack.getItem());
        return name == null ? "<unknown>" : name + ":" + stack.getMetadata();
    }
}
