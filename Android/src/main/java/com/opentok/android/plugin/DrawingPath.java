package com.opentok.android.plugin;

import android.graphics.Paint;
import android.graphics.Path;

class DrawingPath {
    Paint paint;
    Path path;

    DrawingPath(Path path, Paint paint) {
        this.path = path;
        this.paint = paint;
    }
}
