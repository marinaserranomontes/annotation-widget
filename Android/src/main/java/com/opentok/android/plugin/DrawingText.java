package com.opentok.android.plugin;

import android.graphics.Paint;

class DrawingText {
    String text;
    float x, y;
    Paint paint;

    DrawingText(String text, float x, float y, Paint paint) {
        this.paint = paint;
        this.text = text;
        this.x = x;
        this.y = y;
    }
}
