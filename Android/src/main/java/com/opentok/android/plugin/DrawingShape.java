package com.opentok.android.plugin;

import android.graphics.Paint;
import android.graphics.drawable.ShapeDrawable;

class DrawingShape {
    ShapeDrawable drawable;

    DrawingShape(ShapeDrawable drawable, Paint paint, int x, int y, int width, int height) {
        this.drawable = drawable;
        this.drawable.getPaint().set(paint);
        this.drawable.setBounds(x, y, x + width, y + height);
    }
}
