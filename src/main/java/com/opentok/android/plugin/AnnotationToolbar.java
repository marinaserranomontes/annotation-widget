package com.opentok.android.plugin;

import android.app.ActionBar;
import android.content.Context;
import android.content.res.TypedArray;
import android.graphics.Color;
import android.graphics.Path;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.ShapeDrawable;
import android.os.Parcel;
import android.os.Parcelable;
import android.support.v4.view.GravityCompat;
import android.support.v7.widget.Toolbar;
import android.util.AttributeSet;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import com.opentok.android.Connection;
import com.opentok.android.Session;
import java.util.ArrayList;
import java.util.List;

public class AnnotationToolbar extends ViewGroup implements AnnotationMenuInflator.ActionListener {

    private int mGravity;
    private int mWidth;
    private int mHeight;
    private List<ActionListener> listeners = new ArrayList<ActionListener>();

    // FIXME These should be dynamic (allow users to add their own array or individual colors)
    private String[] colors = {
            "#000000",  // Black
            "#0000FF",  // Blue
            "#FF0000",  // Red
            "#00FF00",  // Green
            "#FF8C00",  // Orange
            "#FFD700",  // Yellow
            "#4B0082",  // Purple
            "#800000"   // Brown
    };

    public AnnotationToolbar(Context context) {
        this(context, null);
    }

    public AnnotationToolbar(Context context, AttributeSet attrs) {
        super(context, attrs);

        if (this.getBackground() == null) {
            this.setBackgroundColor(Color.parseColor("#CC000000"));
        }

        TypedArray ta = context.obtainStyledAttributes(attrs, R.styleable.AnnotationToolbar, 0, 0);
        try {
            int tintColor = ta.getColor(R.styleable.AnnotationToolbar_tint_color, Color.WHITE);
            int menuRes = ta.getResourceId(R.styleable.AnnotationToolbar_menu_items, R.xml.ot_main);

            mGravity = ta.getInt(R.styleable.LinearLayoutCompat_android_gravity, Gravity.CENTER_HORIZONTAL);
            mWidth = ta.getInt(R.styleable.LinearLayoutCompat_Layout_android_layout_width, ViewGroup.LayoutParams.MATCH_PARENT);
            mHeight = ta.getInt(R.styleable.LinearLayoutCompat_Layout_android_layout_height, dpToPx(48)); // FIXME Need to get the value from attrs

            AnnotationMenuView toolbar = new AnnotationMenuView(getContext());
            toolbar.inflateMenu(menuRes, this);
            this.addView(toolbar);

            ViewGroup.LayoutParams p = toolbar.getLayoutParams();
            p.height = mHeight; // Match the value passed in by the user
            toolbar.setLayoutParams(p);
        } finally {
            ta.recycle();
        }
    }

    @Override
    protected LayoutParams generateDefaultLayoutParams() {
        return new LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT);
    }

    @Override
    protected void onLayout(boolean changed, int l, int t, int r, int b) {
        final int count = getChildCount();
        int curWidth, curHeight, curLeft, curTop, maxHeight;

        //get the available size of child view
        int childLeft = this.getPaddingLeft();
        int childTop = this.getPaddingTop();
        int childRight = this.getMeasuredWidth() - this.getPaddingRight();
        int childBottom = this.getMeasuredHeight() - this.getPaddingBottom();
        int childWidth = childRight - childLeft;
        int childHeight = childBottom - childTop;

        maxHeight = 0;
        curLeft = childLeft;
        curTop = childTop;
        //walk through each child, and arrange it from left to right
        for (int i = 0; i < count; i++) {
            View child = getChildAt(i);
            if (child.getVisibility() != GONE) {
                //Get the maximum size of the child
                child.measure(MeasureSpec.makeMeasureSpec(childWidth, MeasureSpec.AT_MOST),
                        MeasureSpec.makeMeasureSpec(childHeight, MeasureSpec.AT_MOST));
                curWidth = child.getMeasuredWidth();
                curHeight = child.getMeasuredHeight();
                //wrap is reach to the end
                if (curLeft + curWidth >= childRight) {
                    curLeft = childLeft;
                    curTop += maxHeight;
                    maxHeight = 0;
                }
                //do the layout
                child.layout(curLeft, curTop, curLeft + curWidth, curTop + curHeight);
                //store the max height
                if (maxHeight < curHeight)
                    maxHeight = curHeight;
                curLeft += curWidth;
            }
        }
    }

    public void addMenuItem(String title, Drawable icon, Path path) {

    }

    public void addMenuItem(String title, Drawable icon, ShapeDrawable shape) {

    }

    public void addMenuItem(String title, Drawable icon, Drawable drawable) {

    }

    public void addActionListener(ActionListener listener) {
        this.listeners.add(listener);
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

    @Override
    public void didTapMenuItem(AnnotationToolbarMenuItem menuItem) {
        if (menuItem.getAction() != null) {
            try {
                Color.parseColor(menuItem.getAction());
                showColorSubmenu();
            } catch (IllegalArgumentException e) { // TODO See if there is a better way to do this
                showSubmenu(menuItem);
                e.printStackTrace();
            }
        }

        for (ActionListener listener : listeners) {
            listener.didTapMenuItem(menuItem);
        }
    }

    @Override
    public void didTapItem(AnnotationToolbarItem item) {
        hideSubmenu(); // If the submenu is visible
        for (ActionListener listener : listeners) {
            listener.didTapItem(item);
        }
    }

    public interface ActionListener {
        public void didTapMenuItem(AnnotationToolbarMenuItem menuItem);
        public void didTapItem(AnnotationToolbarItem item);
        public void signalReceived(Session session, String type, String data, Connection connection);
    }

    public void showColorSubmenu() {
        // Show color picker
        if (this.getChildCount() > 1) {
            this.removeViewAt(this.getChildCount() - 1); // Remove the last added view
        }
        AnnotationMenuView colorToolbar = new AnnotationMenuView(getContext());

        for (final String color : colors) {
            final AnnotationToolbarItem item = new AnnotationToolbarItem(getContext(), color, null);
            item.setOnClickListener(new OnClickListener() {
                @Override
                public void onClick(View v) {
                    for (ActionListener listener : listeners) {
                        listener.didTapItem(item);
                    }

                    hideSubmenu();

                    // TODO Update the main button color
                }
            });
            colorToolbar.addView(item);
        }

        ViewGroup.LayoutParams p = this.getLayoutParams();
        p.height = 2*mHeight;
        this.setLayoutParams(p);

        this.addView(colorToolbar);
    }

    private void showSubmenu(AnnotationToolbarMenuItem menuItem) {
        if (this.getChildCount() > 1) {
            this.removeViewAt(this.getChildCount() - 1); // Remove the last added view
        }
        AnnotationMenuView subToolbar = new AnnotationMenuView(getContext());

        for (final AnnotationToolbarItem item : menuItem.getItems()) {
            item.setOnClickListener(new OnClickListener() {
                @Override
                public void onClick(View v) {
                    for (ActionListener listener : listeners) {
                        listener.didTapItem(item);
                    }

                    hideSubmenu();

                    // TODO Update the main button image
                }
            });

            if (item.getParent() != null ) {
                ((ViewGroup)item.getParent()).removeView(item);
            }
            subToolbar.addView(item);
        }

        ViewGroup.LayoutParams p = this.getLayoutParams();
        p.height = 2*mHeight;
        this.setLayoutParams(p);

        this.addView(subToolbar);
    }

    // TODO Add animation to hide the toolbar?
    private void hideSubmenu() {
        if (this.getChildCount() > 1) {
            AnnotationToolbar.this.removeViewAt(AnnotationToolbar.this.getChildCount() - 1);

            ViewGroup.LayoutParams p = AnnotationToolbar.this.getLayoutParams();
            p.height = mHeight;
            AnnotationToolbar.this.setLayoutParams(p);
        }
    }

    public void attachSignal(Session session, String type, String data, Connection connection) {
        for (ActionListener listener : listeners) {
            listener.signalReceived(session, type, data, connection);
        }
    }

    /**
     * Layout information for child views of AnnotationToolbars.
     *
     * <p>AnnotationToolbar.LayoutParams extends Toolbar.LayoutParams for compatibility with existing
     * Toolbar API.
     */
    public static class LayoutParams extends Toolbar.LayoutParams {
        static final int CUSTOM = 0;
        static final int SYSTEM = 1;
        static final int EXPANDED = 2;

        int mViewType = CUSTOM;

        public LayoutParams(Context c, AttributeSet attrs) {
            super(c, attrs);
        }

        public LayoutParams(int width, int height) {
            super(width, height);
            this.gravity = Gravity.CENTER_VERTICAL | GravityCompat.START;
        }

        public LayoutParams(int width, int height, int gravity) {
            super(width, height);
            this.gravity = gravity;
        }

        public LayoutParams(int gravity) {
            this(WRAP_CONTENT, MATCH_PARENT, gravity);
        }

        public LayoutParams(LayoutParams source) {
            super(source);

            mViewType = source.mViewType;
        }

        public LayoutParams(ActionBar.LayoutParams source) {
            super(source);
        }

        public LayoutParams(MarginLayoutParams source) {
            super(source);
            // ActionBar.LayoutParams doesn't have a MarginLayoutParams constructor.
            // Fake it here and copy over the relevant data.
            copyMarginsFromCompat(source);
        }

        public LayoutParams(ViewGroup.LayoutParams source) {
            super(source);
        }

        void copyMarginsFromCompat(MarginLayoutParams source) {
            this.leftMargin = source.leftMargin;
            this.topMargin = source.topMargin;
            this.rightMargin = source.rightMargin;
            this.bottomMargin = source.bottomMargin;
        }
    }

    static class SavedState extends BaseSavedState {
        public int expandedMenuItemId;
        public boolean isOverflowOpen;

        public SavedState(Parcel source) {
            super(source);
            expandedMenuItemId = source.readInt();
            isOverflowOpen = source.readInt() != 0;
        }

        public SavedState(Parcelable superState) {
            super(superState);
        }

        @Override
        public void writeToParcel(Parcel out, int flags) {
            super.writeToParcel(out, flags);
            out.writeInt(expandedMenuItemId);
            out.writeInt(isOverflowOpen ? 1 : 0);
        }

        public static final Creator<SavedState> CREATOR = new Creator<SavedState>() {

            @Override
            public SavedState createFromParcel(Parcel source) {
                return new SavedState(source);
            }

            @Override
            public SavedState[] newArray(int size) {
                return new SavedState[size];
            }
        };
    }
}
