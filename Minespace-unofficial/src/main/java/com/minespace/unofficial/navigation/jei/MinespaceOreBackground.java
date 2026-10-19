package com.minespace.unofficial.navigation.jei;

import mezz.jei.api.gui.IDrawable;
import net.minecraft.client.Minecraft;

/**
 * The ore page's 176x166 background is taller than the text and the grouped ore slots need.
 * At GUI scale 3-4 that extra height pushes the page past the bottom of the screen, so the page
 * uses a 120-pixel background instead: the second input slot ends at 91 and the spawn-range /
 * weight / dimension text ends around 100.
 */
public class MinespaceOreBackground implements IDrawable {

    private final IDrawable delegate;

    public MinespaceOreBackground(IDrawable delegate) {
        this.delegate = delegate;
    }

    @Override
    public int getWidth() {
        return 176;
    }

    @Override
    public int getHeight() {
        return 120;
    }

    @Override
    public void draw(Minecraft minecraft, int xOffset, int yOffset) {
        if (delegate != null) {
            delegate.draw(minecraft, xOffset, yOffset);
        }
    }
}
