package com.opentok.android.plugin;

import android.graphics.Paint;

class AnnotationText {
    String text;
    float x, y;
    Paint paint;

    AnnotationText(String text, float x, float y, Paint paint) {
        this.paint = paint;
        this.text = text;
        this.x = x;
        this.y = y;
    }
}
