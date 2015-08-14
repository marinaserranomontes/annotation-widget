package com.opentok.android.plugin;

import android.graphics.Paint;
import android.graphics.Path;

class AnnotationPath {
    String connectionId;
    Paint paint;
    Path path;

    AnnotationPath(Path path, Paint paint, String connectionId) {
        this.path = path;
        this.paint = paint;
        this.connectionId = connectionId;
    }

    public String getConnectionId() {
        return connectionId;
    }

    public Paint getPaint() {
        return paint;
    }

    public Path getPath() {
        return path;
    }
}
