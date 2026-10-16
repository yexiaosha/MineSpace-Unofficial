package com.minespace.unofficial.gtceu;

import com.minespace.unofficial.Minespace;
import gregtech.api.recipes.CountableIngredient;
import gregtech.api.recipes.Recipe;
import gregtech.api.recipes.RecipeMap;
import net.minecraft.item.ItemStack;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;

/**
 * A recipe is a shopping list, not a grid: a machine has no slots to tell two entries apart, so a
 * recipe that needs eight of an item must carry one stack of eight and not eight stacks of one.
 *
 * <p>This pass reads every GregTech recipe map at load complete and reports two shapes of mistake,
 * both of which have shipped in this pack before:</p>
 *
 * <ul>
 *   <li><b>a mergeable exact duplicate</b> - the same ingredient listed more than once with the
 *       counts adding up to a single stack of at most one slot (TJ-MIGRATION-PLAN.md 6bw: fourteen
 *       recipes, one of them the rocket engine with its four heavy-duty plates written out four
 *       times). Two entries that add up to more than a stack are *not* reported: GregTech's own
 *       Assembly Line recipes are full of `x64` twice, which is a real 128 items over two slots and
 *       could not be folded;</li>
 *   <li><b>overlapping inputs</b> - two entries that can both accept the same item, e.g. a bare ore
 *       dictionary name next to the item it resolves to. Not always wrong, but in an assembler it is
 *       a redundancy the author almost never meant.</li>
 * </ul>
 *
 * <p>It only reports; it does not rewrite a recipe. Rewriting one silently - folding the counts and
 * dropping the later entry - would change what the pack ships without anyone reading it, and the two
 * mistakes above are cheap to fix by hand once the log names them. Output is one summary line per
 * run, a per-map histogram, and (when there is anything to report) the whole list in
 * {@code recipe_hygiene.txt}, so it works as a standing guard rather than a one-off audit.</p>
 *
 * <p>The Assembly Line is counted but not reported: its inputs are <em>slots</em> fed from separate
 * buses, GregTech's own recipes there are written one entry per slot (the `x64` twice pattern is a
 * real 128 items), and this pack never writes that map by hand. Everything else is reported as it is
 * found, including Gregicality's own recipes, because the log naming the output is what tells the
 * reader whether it is the pack's recipe or a mod's.</p>
 */
public final class MinespaceRecipeHygiene {

    /** How many offending recipes to name in the log; the file gets all of them. */
    private static final int SAMPLES = 25;

    /** Matching stacks are read per ingredient, capped so a huge ore name cannot stall the check. */
    private static final int MAX_MATCHES = 64;

    /** A slot holds 64; two entries that add up to more than this could not have been folded. */
    private static final int MAX_STACK = 64;

    /** The one map whose duplicates are the format rather than a mistake (see the class javadoc). */
    private static final String SLOT_ORDERED_MAP = "assembly_line";

    private MinespaceRecipeHygiene() {
    }

    /** Walks every machine recipe map and logs the recipes whose inputs are not folded. */
    public static void checkUnmergedInputs(String phase) {
        int recipes = 0;
        int maps = 0;
        int mergeable = 0;
        int overLimit = 0;
        int overlapping = 0;
        int shown = 0;
        StringBuilder report = new StringBuilder();
        StringBuilder samples = new StringBuilder();
        Map<String, int[]> byMap = new HashMap<>();

        Map<String, Set<String>> idCache = new HashMap<>();
        for (RecipeMap<?> map : RecipeMap.getRecipeMaps()) {
            maps++;
            for (Recipe recipe : map.getRecipeList()) {
                recipes++;
                List<CountableIngredient> inputs = recipe.getInputs();
                if (inputs == null || inputs.size() < 2) {
                    continue;
                }
                String[] keys = new String[inputs.size()];
                Set<String>[] ids = newSetArray(inputs.size());
                for (int i = 0; i < inputs.size(); i++) {
                    CountableIngredient input = inputs.get(i);
                    ItemStack[] stacks = input.getIngredient().getMatchingStacks();
                    TreeSet<String> signature = new TreeSet<>();
                    Set<String> set = new HashSet<>();
                    int seen = 0;
                    for (ItemStack stack : stacks) {
                        if (stack == null || stack.isEmpty()
                                || stack.getItem().getRegistryName() == null) {
                            continue;
                        }
                        String id = stack.getItem().getRegistryName() + ":"
                                + stack.getMetadata();
                        signature.add(id);
                        set.add(id);
                        if (++seen >= MAX_MATCHES) {
                            break;
                        }
                    }
                    keys[i] = signature.toString() + " x" + input.getCount();
                    ids[i] = idCache.computeIfAbsent(keys[i], k -> set);
                }
                for (int a = 0; a < inputs.size(); a++) {
                    for (int b = a + 1; b < inputs.size(); b++) {
                        if (keys[a].equals(keys[b])) {
                            int merged = inputs.get(a).getCount() + inputs.get(b).getCount();
                            if (merged > MAX_STACK) {
                                overLimit++;
                                continue;
                            }
                            if (SLOT_ORDERED_MAP.equals(map.getUnlocalizedName())) {
                                overLimit++;
                                continue;
                            }
                            mergeable++;
                            int[] counter = byMap.computeIfAbsent(map.getUnlocalizedName(),
                                    k -> new int[2]);
                            counter[0]++;
                            String line = "\n  MERGE " + map.getUnlocalizedName() + " -> "
                                    + output(recipe) + "  lists " + keys[a] + " twice (" + merged
                                    + " together)";
                            report.append(line);
                            if (shown++ < SAMPLES) {
                                samples.append(line);
                            }
                            continue;
                        }
                        if (!overlaps(ids[a], ids[b])) {
                            continue;
                        }
                        overlapping++;
                        int[] counter = byMap.computeIfAbsent(map.getUnlocalizedName(),
                                k -> new int[2]);
                        counter[1]++;
                        String line = "\n  OVERLAP " + map.getUnlocalizedName() + " -> "
                                + output(recipe) + "  " + keys[a] + "  vs  " + keys[b];
                        report.append(line);
                        if (shown++ < SAMPLES) {
                            samples.append(line);
                        }
                    }
                }
            }
        }
        if (mergeable == 0 && overlapping == 0) {
            Minespace.log().info("recipe hygiene ({}): {} recipes in {} maps, every input folded -"
                    + " no recipe lists the same ingredient twice ({} over the slot limit, which is"
                    + " how a 128-item cost is written)", phase, recipes, maps, overLimit);
        } else {
            StringBuilder histogram = new StringBuilder();
            for (Map.Entry<String, int[]> entry : new TreeMap<>(byMap).entrySet()) {
                histogram.append("\n  ").append(entry.getKey()).append(": ")
                        .append(entry.getValue()[0]).append(" mergeable, ")
                        .append(entry.getValue()[1]).append(" overlapping");
            }
            Minespace.log().warn("recipe hygiene ({}): {} recipes in {} maps - {} mergeable"
                            + " duplicates, {} overlapping pairs ({} more duplicates over the slot"
                            + " limit, which is how a 128-item cost is written){}", phase, recipes,
                    maps, mergeable, overlapping, overLimit, histogram);
            Minespace.log().warn("recipe hygiene ({}): first {} of the offenders{}", phase, SAMPLES,
                    samples);
            writeFile(report.toString());
        }
    }

    /** The complete list, for the run that has something to fix. */
    private static void writeFile(String body) {
        try (java.io.PrintWriter w = new java.io.PrintWriter(
                new java.io.File("recipe_hygiene.txt"), "UTF-8")) {
            w.println("GregTech machine recipes whose item inputs are not folded:");
            w.println(body);
            Minespace.log().warn("recipe hygiene: full list written to {}",
                    new java.io.File("recipe_hygiene.txt").getAbsolutePath());
        } catch (Throwable t) {
            Minespace.log().error("recipe hygiene could not write its report", t);
        }
    }

    @SuppressWarnings("unchecked")
    private static Set<String>[] newSetArray(int size) {
        return (Set<String>[]) new Set[size];
    }

    private static boolean overlaps(Set<String> a, Set<String> b) {
        Set<String> small = a.size() <= b.size() ? a : b;
        Set<String> large = small == a ? b : a;
        for (String id : small) {
            if (large.contains(id)) {
                return true;
            }
        }
        return false;
    }

    private static String output(Recipe recipe) {
        StringBuilder sb = new StringBuilder();
        for (ItemStack stack : recipe.getOutputs()) {
            if (stack == null || stack.isEmpty()) {
                continue;
            }
            if (sb.length() > 0) {
                sb.append(" + ");
            }
            sb.append(stack.getItem().getRegistryName()).append(':').append(stack.getMetadata());
            if (stack.getCount() > 1) {
                sb.append(" x").append(stack.getCount());
            }
        }
        return sb.length() == 0 ? "(no item output)" : sb.toString();
    }

    /** Kept for the javadoc's benefit; the check itself never rewrites a recipe. */
    static List<String> policy() {
        return new ArrayList<>(Arrays.asList("report", "never rewrite"));
    }
}
