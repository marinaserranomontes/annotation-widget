package com.opentok.android.plugin;

import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.GradientDrawable;
import android.util.AttributeSet;
import android.view.ViewGroup;
import android.widget.ImageButton;

public class AnnotationToolbarItem extends ImageButton {

    int imageResource;
    String action;

    public AnnotationToolbarItem(Context context) {
        this(context, null);
    }

    public AnnotationToolbarItem(Context context, AttributeSet attrs) {
        super(context, attrs);

        ViewGroup.LayoutParams btnParams = new ViewGroup.LayoutParams(dpToPx(35), dpToPx(35));
        this.setLayoutParams(btnParams);

        // TODO Handle attrs so that this can be added in XML
    }

    public AnnotationToolbarItem(Context context, String action, int resource) {
        this(context);
        this.action = action;
        imageResource = resource;

        this.setImageResource(resource);
        this.setBackgroundColor(context.getResources().getColor(android.R.color.transparent));
    }

    public AnnotationToolbarItem(Context context, String action, Drawable icon) {
        this(context);
        this.action = action;

        if (icon == null) {
            try {
                int color = Color.parseColor(action);
                this.setBackgroundResource(R.drawable.circle_button);
                GradientDrawable drawable = (GradientDrawable) this.getBackground();
                drawable.setColor(color);
            } catch (Exception e) {
                // The action wasn't a color, so we should have an icon passed in
            }
        }
    }

    public String getAction() {
        return action;
    }

    /**
     * Converts dp to real pixels, according to the screen density.
     *
     * @param dp A number of density-independent pixels.
     * @return The equivalent number of real pixels.
     */
    private int dpToPx(int dp) {
        double screenDensity = this.getResources().getDisplayMetrics().density;
        return (int) (screenDensity * (double) dp);
    }
}
