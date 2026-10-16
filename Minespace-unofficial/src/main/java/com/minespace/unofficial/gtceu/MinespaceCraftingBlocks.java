package com.minespace.unofficial.gtceu;

import com.minespace.unofficial.Minespace;
import gregtech.api.recipes.CountableIngredient;
import gregtech.api.recipes.Recipe;
import gregtech.api.recipes.RecipeMap;
import gregtech.api.recipes.recipes.DummyRecipe;
import net.minecraft.item.Item;
import net.minecraft.item.ItemStack;
import net.minecraft.item.crafting.CraftingManager;
import net.minecraft.item.crafting.IRecipe;
import net.minecraft.util.ResourceLocation;
import net.minecraftforge.fml.common.registry.ForgeRegistries;

import java.util.ArrayList;
import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;

/**
 * "Nine ingots into a block is the compressor's job, not the crafting table's."
 *
 * <h2>What this removes, and why it is safe</h2>
 *
 * Gregicality generates a crafting-table recipe for every GregTech material - {@code
 * block_compress_<material>} (nine ingots into a block) and {@code block_decompress_<material>} (the
 * way back) - and Ender IO's own endergy alloys bring seven more pairs under the names {@code
 * auto_<material>_9_ingots_to_1_block} / {@code auto_<material>_1_block_to_9_ingots}. A probe over
 * the finished crafting registry counts **1074** of them. They are the reason a GregTech pack still
 * lets a player skip the compressor entirely, which is exactly what the owner reported: "look at the
 * unreasonable recipes, especially ingots straight into a block".
 *
 * <p>The removal is decided per recipe, not by a blanket name match: a recipe is only deleted when
 * the GregTech recipe maps can already make the same item (a compressor, packer, alloy smelter,
 * fluid solidifier, extruder, ... route). That leaves the sixteen pairs that have nowhere to go -
 * Ender IO's seven endergy alloys, Galaxy Space's sulphur dust and Forestry's ash, all of which are
 * not GregTech materials - in place, so nothing becomes unobtainable. The skipped names are logged
 * on every launch, which is how the list can be re-checked after a mod update.</p>
 *
 * <h2>Second pass: recipes that can no longer be run at all</h2>
 *
 * The same probe found GT machine recipes still asking for a *mod* item the pack has unified away
 * (the clearest case: Gregicality's compressor and packer recipes for the silicon block still take
 * AE2's silicon, which {@code oredict.zs} stopped producing in section 6l). Those
 * recipes cannot be run by any player, and JEI shows them as if they could - so the second pass
 * deletes a machine recipe when one of its ingredients can only be satisfied by items on {@link
 * MinespaceMaterialRepoint#unifiedAwayIds()}. An ingredient that still lists GregTech's item among
 * its alternatives is left alone: it works.</p>
 *
 * <h2>Why Java and not a script</h2>
 *
 * Both passes are decided *from the finished recipe maps* - "does a machine make this?", "is every
 * alternative of this ingredient dead?" - which CraftTweaker cannot ask, and the crafting recipes
 * here are registered by other mods' own generators. Runs once from {@code FMLLoadCompleteEvent},
 * after every mod has registered, and is idempotent.
 */
public final class MinespaceCraftingBlocks {

    private MinespaceCraftingBlocks() {
    }

    /** The registry-name shapes Gregicality and Ender IO generate for the two directions. */
    private static boolean isCompressionRecipe(String path) {
        return path.startsWith("block_compress_")
                || path.startsWith("block_decompress_")
                || (path.startsWith("auto_") && path.endsWith("_9_ingots_to_1_block"))
                || (path.startsWith("auto_") && path.endsWith("_1_block_to_9_ingots"));
    }

    /**
     * Deletes every crafting-table compression / decompression recipe whose output a GregTech machine
     * also makes, and reports the ones left behind.
     *
     * @return the number of crafting-table recipes deleted by this call
     */
    public static int removeCraftingTableCompression(String phase) {
        Set<String> machineOutputs = new HashSet<>();
        for (RecipeMap<?> map : RecipeMap.getRecipeMaps()) {
            for (Recipe recipe : map.getRecipeList()) {
                for (ItemStack output : recipe.getOutputs()) {
                    if (!output.isEmpty()) {
                        machineOutputs.add(idOf(output));
                    }
                }
            }
        }

        List<ResourceLocation> victims = new ArrayList<>();
        List<String> kept = new ArrayList<>();
        for (IRecipe recipe : CraftingManager.REGISTRY) {
            ResourceLocation name = CraftingManager.REGISTRY.getNameForObject(recipe);
            if (name == null || !isCompressionRecipe(name.getResourcePath())) {
                continue;
            }
            ItemStack output = recipe.getRecipeOutput();
            if (output.isEmpty()) {
                continue;
            }
            if (machineOutputs.contains(idOf(output))) {
                victims.add(name);
            } else {
                kept.add(idOf(output) + " (" + name + ")");
            }
        }

        for (ResourceLocation name : victims) {
            // GregTech's own way of deleting a crafting recipe by name: a placeholder registered under
            // the same name replaces the recipe (ModHandler.removeRecipeByName does the same thing).
            ForgeRegistries.RECIPES.register(new DummyRecipe().setRegistryName(name));
        }

        Minespace.log().info("crafting-table compression ({} pass): {} of {} compression / "
                        + "decompression recipes deleted, {} kept because no GregTech machine makes "
                        + "the same item", phase, victims.size(), victims.size() + kept.size(),
                kept.size());
        for (String entry : kept) {
            Minespace.log().info("crafting-table compression: kept {} - no machine route", entry);
        }
        return victims.size();
    }

    /**
     * Deletes GregTech machine recipes that can no longer be run, i.e. those with an ingredient whose
     * every alternative is an item the pack has unified away.
     *
     * @return the number of machine recipes deleted by this call
     */
    public static int removeUnreachableMachineRecipes(String phase) {
        Set<String> gone = MinespaceMaterialRepoint.unifiedAwayIds();
        int removed = 0;
        for (RecipeMap<?> map : RecipeMap.getRecipeMaps()) {
            List<Recipe> victims = new ArrayList<>();
            for (Recipe recipe : map.getRecipeList()) {
                if (hasDeadIngredient(recipe, gone)) {
                    victims.add(recipe);
                }
            }
            for (Recipe victim : victims) {
                try {
                    if (map.removeRecipe(victim)) {
                        removed++;
                        if (removed <= 10) {
                            Minespace.log().info("unreachable machine recipe: {} {} -> {}",
                                    map.getUnlocalizedName(), describeInputs(victim),
                                    describeOutputs(victim));
                        }
                    }
                } catch (Throwable t) {
                    Minespace.log().warn("could not remove an unreachable recipe from {}",
                            map.getUnlocalizedName(), t);
                }
            }
        }
        Minespace.log().info("unreachable machine recipes ({} pass): {} deleted (ingredients that "
                + "only the unified-away mod items could satisfy)", phase, removed);
        return removed;
    }

    /**
     * Deletes every crafting-table recipe whose output a GregTech machine can also make, for the items
     * of the mods this pack has gregified - and the same for "N of the same thing into a block" recipes
     * in any namespace except GregTech's own.
     *
     * <h2>Why the earlier passes missed these</h2>
     *
     * The first pass (`removeLeftoverCraftingRecipes`) enforced the rule for the items *this pack's
     * scripts* put into a machine. A finished-recipes audit then showed two families it could not see:
     *
     * <ul>
     *   <li>machine routes nobody in this pack wrote - Gregicality mirrors a mod's own crafting recipe
     *       onto a GregTech machine, e.g. AE2's dense covered cable, where four cables into a dense
     *       cable became a packer recipe while the crafting-table version stayed;</li>
     *   <li>"N identical things into a block" recipes that are not named {@code block_compress_*} or
     *       {@code auto_*_9_ingots_to_1_block} - Forestry's copper / tin / bronze / apatite / charcoal
     *       blocks, Galaxy Space's block family and the vanilla ones (nine iron ingots into an iron
     *       block) all carry the mod's own name, so the name-pattern pass of section 6an walked past
     *       them even though a GregTech compressor or packer makes the same block.</li>
     * </ul>
     *
     * <h2>The rule, and what it deliberately does not touch</h2>
     *
     * A recipe goes when its output has a GregTech machine route <em>and</em>
     *
     * <ul>
     *   <li>the <em>output is an item of one of the mods this pack gregifies</em> - AE2, Ender IO,
     *       Forestry, Galacticraft, Galacticraft Planets, Galaxy Space, PlanetProgression, Iron Chests,
     *       Storage Drawers. The output's own namespace decides, not the recipe's: a mod recipe that
     *       merely produces a *vanilla* item (Galacticraft's cobblestone alternatives, Forestry's
     *       string-from-silk, Ender IO's stick tweak) is left alone, because the item was never
     *       gregified; or</li>
     *   <li>the output is one of the nine vanilla blocks GregTech itself compresses - iron, gold,
     *       diamond, emerald, coal, lapis, redstone, quartz and glowstone block - in the "four or more
     *       identical things into one" shape. That is exactly the pair of recipes Gregicality's own
     *       "Remove 3x3 Block Crafting Recipes" switch was written for, and the compressor / packer
     *       route exists for each. Every other vanilla recipe (chests, crafting tables, panes, planks,
     *       leather, hay, clay, brick, snow, slime, bone, prismarine, wool, nugget assembly, ...) is
     *       left exactly as vanilla wrote it.</li>
     * </ul>
     *
     * Kept on purpose: anything in GregTech's or Gregicality's own namespace (those items have both
     * routes by GregTech's own design - a machine crafted at the table with a wrench is what every
     * GregTech player expects), the "four small dusts into a dust" assembly recipes, which are a
     * GregTech convention rather than a shortcut, and the three Galacticraft items where the machine
     * recipe was a bonus route all along (the two canister forms and the glowstone torch). Every
     * deletion is logged with its recipe name, so the list can be read rather than guessed.
     *
     * @return the number of crafting-table recipes deleted by this call
     */
    public static int removeDuplicatedTableRoutes(String phase) {
        Set<String> machineOutputs = new HashSet<>();
        for (RecipeMap<?> map : RecipeMap.getRecipeMaps()) {
            for (Recipe recipe : map.getRecipeList()) {
                for (ItemStack output : recipe.getOutputs()) {
                    if (!output.isEmpty()) {
                        machineOutputs.add(idOf(output));
                    }
                }
            }
        }
        List<String> removed = new ArrayList<>();
        for (IRecipe recipe : CraftingManager.REGISTRY) {
            ResourceLocation name = CraftingManager.REGISTRY.getNameForObject(recipe);
            if (name == null) {
                continue;
            }
            ItemStack output = recipe.getRecipeOutput();
            if (output.isEmpty()) {
                continue;
            }
            String id = idOf(output);
            if (!machineOutputs.contains(id)) {
                continue;
            }
            String outputNamespace = id.substring(0, id.indexOf(':'));
            if ("gregtech".equals(outputNamespace) || "gtadditions".equals(outputNamespace)) {
                continue;
            }
            String recipeNamespace = name.getResourceDomain();
            if ("gregtech".equals(recipeNamespace) || "gtadditions".equals(recipeNamespace)) {
                continue;
            }
            String path = name.getResourcePath();
            if (path.startsWith("small_dust_assembling_") || path.startsWith("tiny_dust_assembling_")) {
                continue;
            }
            if (KEPT_ITEMS.contains(id)) {
                continue;
            }
            boolean modItem = GREGIFIED_NAMESPACES.contains(outputNamespace);
            boolean materialBlock = VANILLA_MATERIAL_BLOCKS.contains(id)
                    && isUniformCompression(recipe);
            if (!modItem && !materialBlock) {
                continue;
            }
            removed.add(id + " (" + name + ")"
                    + (materialBlock ? " [material block]" : " [" + outputNamespace + "]"));
            ForgeRegistries.RECIPES.register(new DummyRecipe().setRegistryName(name));
        }
        Minespace.log().info("no-double-route ({} pass): {} crafting-table recipes deleted because a "
                + "GregTech machine makes the same item", phase, removed.size());
        for (String entry : removed) {
            Minespace.log().info("no-double-route: {}", entry);
        }
        return removed.size();
    }

    /** The mods this pack gregifies: for these, a machine route always wins over a table one. */
    private static final Set<String> GREGIFIED_NAMESPACES = new HashSet<>(java.util.Arrays.asList(
            "appliedenergistics2", "enderio", "forestry", "galacticraftcore", "galacticraftplanets",
            "galaxyspace", "planetprogression", "ironchest", "storagedrawers"));

    /** Machine recipes that are a bonus route next to the table one, not a replacement for it. */
    private static final Set<String> KEPT_ITEMS = new HashSet<>(java.util.Arrays.asList(
            "galacticraftcore:canister:0", "galacticraftcore:canister:1",
            "galacticraftcore:glowstone_torch:0"));

    /**
     * The vanilla blocks GregTech itself compresses from a material: nine ingots, gems or dusts into
     * one block. Gregicality's own "Remove 3x3 Block Crafting Recipes" switch names two of them
     * (glowstone and quartz) as its whole scope, which is how narrow this line is meant to be.
     */
    private static final Set<String> VANILLA_MATERIAL_BLOCKS = new HashSet<>(java.util.Arrays.asList(
            "minecraft:iron_block:0", "minecraft:gold_block:0", "minecraft:diamond_block:0",
            "minecraft:emerald_block:0", "minecraft:coal_block:0", "minecraft:lapis_block:0",
            "minecraft:redstone_block:0", "minecraft:quartz_block:0", "minecraft:glowstone:0"));

    /**
     * True when every filled crafting slot accepts the same item and there are at least four of them -
     * the "2x2 or 3x3 of one thing into one thing" shape, whatever the recipe is called.
     */
    private static boolean isUniformCompression(IRecipe recipe) {
        String only = null;
        int slots = 0;
        for (net.minecraft.item.crafting.Ingredient ingredient : recipe.getIngredients()) {
            if (ingredient == null) {
                continue;
            }
            ItemStack[] candidates = ingredient.getMatchingStacks();
            if (candidates.length == 0) {
                continue;
            }
            slots++;
            String key = acceptedStacksKey(candidates);
            if (only == null) {
                only = key;
            } else if (!only.equals(key)) {
                return false;
            }
        }
        return slots >= 4;
    }

    private static String acceptedStacksKey(ItemStack[] candidates) {
        List<String> ids = new ArrayList<>();
        for (ItemStack candidate : candidates) {
            ids.add(idOf(candidate));
        }
        java.util.Collections.sort(ids);
        return String.join(",", ids);
    }

    /** True when the item carries one of GregTech's {@code block*} ore dictionary names. */
    private static boolean isMaterialBlock(ItemStack stack) {
        for (int id : net.minecraftforge.oredict.OreDictionary.getOreIDs(stack)) {
            String ore = net.minecraftforge.oredict.OreDictionary.getOreName(id);
            if (ore != null && ore.startsWith("block")) {
                return true;
            }
        }
        return false;
    }

    /**
     * The AE2 line starts at MV: any packer or compressor recipe that makes AE2's quartz or fluix block
     * for less than 120 EU/t is deleted here.
     *
     * <p>It exists for one recipe: Gregicality mirrors AE2's own 2x2 crafting recipe (four crystals into
     * a block) onto the packer at LV, which would leave an LV door into the middle of the AE2 line even
     * though every other AE2 recipe in the pack now asks for an MV assembler. The MV replacement for
     * that recipe, and the grown-crystal one that had no mirror at all, are written in
     * {@code ae2_base.zs}; this pass only clears the LV original. See
     * TJ-MIGRATION-PLAN.md 6ar.</p>
     *
     * @return the number of sub-MV AE2 block recipes deleted by this call
     */
    public static int removeSubMvAe2BlockRecipes(String phase) {
        int removed = 0;
        for (RecipeMap<?> map : RecipeMap.getRecipeMaps()) {
            String mapName = map.getUnlocalizedName();
            if (!"packer".equals(mapName) && !"compressor".equals(mapName)) {
                continue;
            }
            List<Recipe> victims = new ArrayList<>();
            for (Recipe recipe : map.getRecipeList()) {
                if (recipe.getEUt() >= 120) {
                    continue;
                }
                for (ItemStack output : recipe.getOutputs()) {
                    String id = idOf(output);
                    if ("appliedenergistics2:quartz_block:0".equals(id)
                            || "appliedenergistics2:fluix_block:0".equals(id)) {
                        victims.add(recipe);
                        break;
                    }
                }
            }
            for (Recipe victim : victims) {
                try {
                    if (map.removeRecipe(victim)) {
                        removed++;
                        Minespace.log().info("AE2 MV floor: removed {} recipe {} EU/t -> {}", mapName,
                                victim.getEUt(), describeOutputs(victim));
                    }
                } catch (Throwable t) {
                    Minespace.log().warn("could not remove an LV AE2 block recipe from {}", mapName, t);
                }
            }
        }
        Minespace.log().info("AE2 MV floor ({} pass): {} packer / compressor recipes below MV deleted",
                phase, removed);
        return removed;
    }

    /**
     * Deletes any crafting-table recipe that is still there for an item this pack has moved into a
     * machine, and says which ones they were.
     *
     * <h2>Why this is needed at all</h2>
     *
     * The scripts already call {@code recipes.remove(...)} for every one of these items - but
     * CraftTweaker applies **all of its removals before any of its additions**, and a mod that registers
     * a crafting recipe later (Ender IO's XML files, Galaxy Space's code, Gregicality's own
     * compressed-plate recipes) puts the recipe straight back. The trap the owner ran into is the same
     * one one step earlier: when an *older* script of this pack re-adds the table recipe
     * (`recipes.remove` then `recipes.addShaped`, the "rewrite it harder" pattern used all over
     * `gs_removals.zs` and `ae2_base.zs`), a *later* script's `recipes.remove` cannot
     * take it away again - the add always wins. That is why an item with a brand new assembler recipe
     * could still be crafted on the table, and it is what this pass reports and deletes: 35 recipes on
     * the 2026-10-12 run, every one of them named `crafttweaker:ct_shaped...` (this pack's own rewrite)
     * or `gtadditions:...` (Gregicality's own late registration).
     *
     * <p>The list is `minespace_machine_only.txt`, generated from the scripts as "every item this pack
     * writes a machine recipe for", minus a short list of deliberate exceptions - the two Galacticraft
     * canister forms and the glowstone torch, where the machine recipe is a bonus route next to the
     * table recipe rather than a replacement. An item that is only in the remove-and-rewrite set of the
     * scripts is therefore not in it and stays craftable.</p>
     *
     * <p>Runs last, from {@code FMLLoadCompleteEvent}, which is the only point after every mod's own
     * registration.</p>
     *
     * @return the number of leftover crafting-table recipes deleted by this call
     */
    public static int removeLeftoverCraftingRecipes(String phase) {
        Set<String> machineOnly = loadMachineOnlyIds();
        if (machineOnly.isEmpty()) {
            Minespace.log().warn("machine-only list is empty - {} did not make it into the jar?",
                    "minespace_machine_only.txt");
            return 0;
        }
        List<String> removed = new ArrayList<>();
        for (IRecipe recipe : CraftingManager.REGISTRY) {
            ResourceLocation name = CraftingManager.REGISTRY.getNameForObject(recipe);
            if (name == null) {
                continue;
            }
            ItemStack output = recipe.getRecipeOutput();
            if (output.isEmpty() || !machineOnly.contains(idOf(output))) {
                continue;
            }
            removed.add(idOf(output) + " (" + name + ")");
            ForgeRegistries.RECIPES.register(new DummyRecipe().setRegistryName(name));
        }
        Minespace.log().info("machine-only enforcement ({} pass): {} crafting-table recipes were still "
                + "there for items this pack moved into a machine and have been deleted", phase,
                removed.size());
        for (String entry : removed) {
            Minespace.log().info("machine-only enforcement: {}", entry);
        }
        return removed.size();
    }

    /** The item list that ships inside the jar, one {@code namespace:path:meta} per line. */
    private static Set<String> loadMachineOnlyIds() {
        return loadIds("/minespace_machine_only.txt");
    }

    private static Set<String> loadIds(String resource) {
        Set<String> ids = new HashSet<>();
        try (InputStream in = MinespaceCraftingBlocks.class.getResourceAsStream(resource)) {
            if (in == null) {
                return ids;
            }
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(in, "UTF-8"))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    String id = line.trim();
                    if (!id.isEmpty() && !id.startsWith("#")) {
                        ids.add(normalize(id));
                    }
                }
            }
        } catch (Throwable t) {
            Minespace.log().error("could not read the machine-only item list", t);
        }
        return ids;
    }

    /** {@code namespace:path} is the same item as {@code namespace:path:0} for our purposes. */
    private static String normalize(String id) {
        return id.indexOf(':') == id.lastIndexOf(':') ? id + ":0" : id;
    }

    private static boolean hasDeadIngredient(Recipe recipe, Set<String> gone) {
        for (CountableIngredient input : recipe.getInputs()) {
            ItemStack[] candidates = input.getIngredient().getMatchingStacks();
            if (candidates.length == 0) {
                continue;
            }
            boolean allGone = true;
            for (ItemStack candidate : candidates) {
                if (candidate.isEmpty() || !gone.contains(idOf(candidate))) {
                    allGone = false;
                    break;
                }
            }
            if (allGone) {
                return true;
            }
        }
        return false;
    }

    private static String describeInputs(Recipe recipe) {
        StringBuilder sb = new StringBuilder();
        for (CountableIngredient input : recipe.getInputs()) {
            ItemStack[] candidates = input.getIngredient().getMatchingStacks();
            if (candidates.length == 0) {
                continue;
            }
            if (sb.length() > 0) {
                sb.append(" + ");
            }
            sb.append(input.getCount()).append('x').append(idOf(candidates[0]));
        }
        return sb.toString();
    }

    private static String describeOutputs(Recipe recipe) {
        StringBuilder sb = new StringBuilder();
        for (ItemStack output : recipe.getOutputs()) {
            if (sb.length() > 0) {
                sb.append(" + ");
            }
            sb.append(output.getCount()).append('x').append(idOf(output));
        }
        return sb.toString();
    }

    private static String idOf(ItemStack stack) {
        if (stack == null || stack.isEmpty()) {
            return "<empty>";
        }
        Item item = stack.getItem();
        ResourceLocation name = ForgeRegistries.ITEMS.getKey(item);
        return name == null ? "<unknown>" : name + ":" + stack.getMetadata();
    }
}
