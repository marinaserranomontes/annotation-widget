package com.opentok.android.plugin;

import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.GradientDrawable;
import android.util.AttributeSet;
import android.view.ViewGroup;
import android.widget.ImageButton;
import java.util.ArrayList;
import java.util.List;

public class AnnotationToolbarMenuItem extends ImageButton {
    private int imageResource;
    private String action;
    private Drawable mIcon;
    private int mMinWidth;
    // List of submenu items
    private List<AnnotationToolbarItem> items = new ArrayList<AnnotationToolbarItem>();

    private static final int MAX_ICON_SIZE = 32; // dp
    private int mMaxIconSize;

    public AnnotationToolbarMenuItem(Context context) {
        this(context, null);
    }

    public AnnotationToolbarMenuItem(Context context, AttributeSet attrs) {
        super(context, attrs);

        final float density = context.getResources().getDisplayMetrics().density;
        mMaxIconSize = (int) (MAX_ICON_SIZE * density + 0.5f);

        // TODO Handle attrs so that this can be added in XML
    }

    public AnnotationToolbarMenuItem(Context context, String action, int resource) {
        this(context);
        this.action = action;
        imageResource = resource;

        this.setImageResource(resource);
        this.setBackgroundColor(context.getResources().getColor(android.R.color.transparent));
    }

    public AnnotationToolbarMenuItem(Context context, String action, Drawable icon) {
        this(context);
        this.action = action;

        if (icon == null) {
            try {
                ViewGroup.LayoutParams btnParams = new ViewGroup.LayoutParams(dpToPx(35), dpToPx(35));
                this.setLayoutParams(btnParams);
                int color = Color.parseColor(action);
                this.setBackgroundResource(R.drawable.circle_button);
                GradientDrawable drawable = (GradientDrawable) this.getBackground();
                drawable.setColor(color);
            } catch (Exception e) {
                // The action wasn't a color, so we should have an icon passed in
            }
        } else {
            setIcon(icon);
        }
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        if (MeasureSpec.getMode(heightMeasureSpec) == MeasureSpec.AT_MOST) {
            // Fill all available height.
            heightMeasureSpec = MeasureSpec.makeMeasureSpec(
                    MeasureSpec.getSize(heightMeasureSpec), MeasureSpec.EXACTLY);
        }

        super.onMeasure(widthMeasureSpec, heightMeasureSpec);

        final int widthMode = MeasureSpec.getMode(widthMeasureSpec);
        final int widthSize = MeasureSpec.getSize(widthMeasureSpec);
        final int oldMeasuredWidth = getMeasuredWidth();
        final int targetWidth = widthMode == MeasureSpec.AT_MOST ? Math.min(widthSize, 0/*mMinWidth*/)
                : 0/*mMinWidth*/;

        if (widthMode != MeasureSpec.EXACTLY && mMinWidth > 0 && oldMeasuredWidth < targetWidth) {
            // Remeasure at exactly the minimum width.
            super.onMeasure(MeasureSpec.makeMeasureSpec(targetWidth, MeasureSpec.EXACTLY),
                    heightMeasureSpec);
        }

        if (mIcon != null) {
            // TextView won't center compound drawables in both dimensions without
            // a little coercion. Pad in to center the icon after we've measured.
            final int w = getMeasuredWidth();
            final int dw = mIcon.getBounds().width();
            super.setPadding((w - dw) / 2, getPaddingTop(), getPaddingRight(), getPaddingBottom());
        }
    }

    public void setIcon(Drawable icon) {
        mIcon = icon;
        if (icon != null) {
            int width = icon.getIntrinsicWidth();
            int height = icon.getIntrinsicHeight();
            if (width > mMaxIconSize) {
                final float scale = (float) mMaxIconSize / width;
                width = mMaxIconSize;
                height *= scale;
            }
            if (height > mMaxIconSize) {
                final float scale = (float) mMaxIconSize / height;
                height = mMaxIconSize;
                width *= scale;
            }
            icon.setBounds(0, 0, width, height);
        }
//        setCompoundDrawables(icon, null, null, null);
//
//        updateTextButtonVisibility();
    }

    public void addItem(AnnotationToolbarItem item) {
        this.items.add(item);
    }

    public List<AnnotationToolbarItem> getItems() {
        return items;
    }

    public void setItems(List<AnnotationToolbarItem> items) {
        this.items = items;
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
