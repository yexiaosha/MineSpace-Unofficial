package com.minespace.unofficial.navigation.mixin;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.ModifyVariable;

import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * The One Probe builds its harvest line as a hard-coded English string:
 * {@code "Pickaxe (level iron)"}. TOP 1.12 has no language key for that line, so the only way to
 * make it Chinese without replacing TOP is to rewrite the string as it is added to the probe panel.
 *
 * <p>Only the known harvest-line forms are touched. Every other probe line goes through unchanged.</p>
 */
@Mixin(targets = "mcjty.theoneprobe.apiimpl.elements.AbstractElementPanel")
public abstract class MixinTheOneProbeText {

    private static final Pattern HARVEST_LINE =
            Pattern.compile("([A-Za-z]+) \\(level ([A-Za-z]+)\\)");

    private static final Map<String, String> TOOLS = new HashMap<String, String>();
    private static final Map<String, String> LEVELS = new HashMap<String, String>();

    static {
        TOOLS.put("Pickaxe", "镐");
        TOOLS.put("Axe", "斧");
        TOOLS.put("Shovel", "铲");
        TOOLS.put("Hoe", "锄");
        TOOLS.put("Shears", "剪刀");
        TOOLS.put("Sword", "剑");
        TOOLS.put("Hammer", "锤");
        TOOLS.put("Saw", "锯");
        TOOLS.put("Drill", "钻头");
        TOOLS.put("Wrench", "扳手");

        LEVELS.put("stone", "石头");
        LEVELS.put("iron", "铁");
        LEVELS.put("diamond", "钻石");
        LEVELS.put("obsidian", "黑曜石");
        LEVELS.put("cobalt", "钴");
        LEVELS.put("netherite", "下界合金");
    }

    @ModifyVariable(
            method = "text(Ljava/lang/String;)Lmcjty/theoneprobe/api/IProbeInfo;",
            at = @At("HEAD"),
            argsOnly = true,
            remap = false
    )
    private String minespaceLocalizeProbeText(String text) {
        if (text == null || text.isEmpty()) {
            return text;
        }
        String localized = text
                .replace("Tool:", "工具：")
                .replace("Not harvestable", "不可采集")
                .replace("Harvestable", "可采集")
                .replace("No tool", "无需工具");
        Matcher matcher = HARVEST_LINE.matcher(localized);
        StringBuffer out = new StringBuffer();
        while (matcher.find()) {
            String tool = TOOLS.containsKey(matcher.group(1)) ? TOOLS.get(matcher.group(1)) : matcher.group(1);
            String level = LEVELS.containsKey(matcher.group(2)) ? LEVELS.get(matcher.group(2)) : matcher.group(2);
            matcher.appendReplacement(out,
                    Matcher.quoteReplacement(tool + "（等级 " + level + "）"));
        }
        matcher.appendTail(out);
        return out.toString();
    }
}
