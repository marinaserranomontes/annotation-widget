package com.opentok.android.plugin;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.PathMeasure;
import android.graphics.Point;
import android.graphics.drawable.ShapeDrawable;
import android.support.annotation.NonNull;
import android.util.AttributeSet;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;

import com.opentok.android.Connection;
import com.opentok.android.Publisher;
import com.opentok.android.Session;
import com.opentok.android.Subscriber;

import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

// TODO Determine if this class should be allowed to be extended
public class AnnotationView extends View implements AnnotationToolbar.ActionListener {

    private static final String TAG = "ot-annotations-canvas";

    private String mycid;
    private String canvascid;

	public int width;
	public int height;
	private Bitmap mBitmap;
	private Canvas mCanvas;
    // TODO Merge these lists so that they can be used for history (undo)
	private List<AnnotationPath> mPaths;
	private List<AnnotationText> mLabels;
	private Context context;
	private float mX, mY;
	private float mLastX, mLastY;
	private float mStartX, mStartY;
	private static final float TOLERANCE = 5;

    /**
     * Indicates if you are drawing
     */
    private boolean isDrawing = false;

    private boolean allowsSizing = false;

    private AnnotationToolbar toolbar;

    // FIXME This should be an enum built into the annotation item
    private String[] actions = {
        "Pen",
        "Shapes",
        "Line",
        "Text"
    };

    // TODO May want to put these in their own file
    private FloatPoint[] linePoints = {
            new FloatPoint(0, 0),
            new FloatPoint(0, 1)
    };

    private FloatPoint[] arrowPoints = {
            new FloatPoint(0, 1),
            new FloatPoint(3, 1),
            new FloatPoint(3, 0),
            new FloatPoint(5, 2),
            new FloatPoint(3, 4),
            new FloatPoint(3, 3),
            new FloatPoint(0, 3),
            new FloatPoint(0, 1) // Reconnect point
    };

    private FloatPoint[] rectanglePoints = {
            new FloatPoint(0, 0),
            new FloatPoint(1, 0),
            new FloatPoint(1, 1),
            new FloatPoint(0, 1),
            new FloatPoint(0, 0)
    };

    // TODO Need to ensure this uses Path.quadTo
    private FloatPoint[] circlePoints = {
            new FloatPoint(0, 0.5f),
            new FloatPoint(0.5f + 0.5f*(float)Math.cos(5*Math.PI/4), 0.5f + 0.5f*(float)Math.sin(5*Math.PI/4)),
            new FloatPoint(0.5f, 0),
            new FloatPoint(0.5f + 0.5f*(float)Math.cos(7*Math.PI/4), 0.5f + 0.5f*(float)Math.sin(7*Math.PI/4)),
            new FloatPoint(1, 0.5f),
            new FloatPoint(0.5f + 0.5f*(float)Math.cos(Math.PI/4), 0.5f + 0.5f*(float)Math.sin(Math.PI/4)),
            new FloatPoint(0.5f, 1),
            new FloatPoint(0.5f + 0.5f*(float)Math.cos(3*Math.PI/4), 0.5f + 0.5f*(float)Math.sin(3*Math.PI/4)),
            new FloatPoint(0, 0.5f)
    };

    // TODO This should come from the first menu item, if possible
    private String action = "Pen"; // Default to pen

    @Override
    public void didTapMenuItem(AnnotationToolbarMenuItem menuItem) {
//        setAction(menuItem.getAction());
    }

    @Override
    public void didTapItem(AnnotationToolbarItem item) { // INFO This method will be available to users to handle their own actions
        try {
            int color = Color.parseColor(item.getAction());
            setAnnotationColor(color);
        } catch (Exception e) {
            // We don't have a color selection
            if (item.getAction() != null) {
                if (item.getAction().equalsIgnoreCase("Clear")) {
                    clearCanvas();
                    if (mSubscriber != null) {
                        mSubscriber.getSession().sendSignal(Mode.Clear.toString(), null);
                    } else if (mPublisher != null) {
                        mPublisher.getSession().sendSignal(Mode.Clear.toString(), null);
                    } else {
                        throw new IllegalStateException("A publisher or subscriber must be passed into the class. " +
                                "See attachSubscriber() or attachPublisher().");
                    }
                } else if (item.getAction().equalsIgnoreCase("Capture")) {
                    // Add a tap listener to the canvas - if it gets tapped, snap a screenshot
                    this.setAction("Capture");
                } else {
                    setAction(item.getAction());
                }
            }
        }
    }

    // FIXME Should really only have update, clear, and possibly text (since text handling will be different)
    private enum Mode {
        Pen("otAnnotation_pen"),
        Clear("otAnnotation_clear"),
        Shape("otAnnotation_shape"),
        Line("otAnnotation_line"),
        Text("otAnnotation_text");

        private String type;

        Mode(String type) {
            this.type = type;
        }

        public String toString() {
            return this.type;
        }
    }

    private Subscriber mSubscriber;
    private Publisher mPublisher;

    // Color and stroke associated with incoming annotations
    private int activeColor;
    private float activeStrokeWidth;

    // Color and stroke selected by the current user
    private int userColor;
    private float userStrokeWidth;

    /** ==== Constructors ==== **/

    public AnnotationView(Context c) {
        this(c, null);
    }

	public AnnotationView(Context c, AttributeSet attrs) {
		super(c, attrs);
		context = c;

		mPaths = new ArrayList<AnnotationPath>();
		mLabels = new ArrayList<AnnotationText>();

        // Default stroke and color
        userColor = activeColor = Color.RED;
        userStrokeWidth = activeStrokeWidth = 6f;
	}

    /** ==== Linkers ==== **/

    // FIXME These need to test for a custom renderer - if one was already added, it should override ours (disable screenshots)
    // INFO We pass in a subscriber or publisher so that the canvas can be auto scaled to match the video frame

    /**
     * Attaches an annotation canvas to the provided {@code Subscriber}.
     * @param subscriber The OpenTok {@code Subscriber}.
     */
    public void attachSubscriber(@NonNull Subscriber subscriber) {
        this.setLayoutParams(subscriber.getView().getLayoutParams());
        mSubscriber = subscriber;

        new Thread() {
            @Override
            public void run() {
                while (mSubscriber.getStream() == null) { /* Wait */ }
                while (mSubscriber.getStream().getConnection() == null) { /* Wait */ }
                canvascid = mSubscriber.getStream().getConnection().getConnectionId();

                Log.i("Canvas Signal", "Subscriber: " + canvascid);

                // Initialize a default path
                createPath(false, canvascid);
            }
        }.start();

//        mSubscriber.setRenderer(new AnnotationVideoRenderer(getContext()));

//        ViewGroup parent = (ViewGroup) subscriber.getView().getParent();
//        parent.removeView(subscriber.getView());
//        parent.addView(mSubscriber.getView());
    }

    /**
     * Attaches an annotation canvas to the provided {@code Publisher}.
     * @param publisher The OpenTok {@code Publisher}.
     */
    public void attachPublisher(@NonNull Publisher publisher) {
        this.setLayoutParams(publisher.getView().getLayoutParams());
        mPublisher = publisher;

        new Thread() {
            @Override
            public void run() {
                while (mPublisher.getStream() == null) { /* Wait */ }
                while (mPublisher.getStream().getConnection() == null) { /* Wait */ }
                canvascid = mPublisher.getStream().getConnection().getConnectionId();

                Log.i("Canvas Signal", "Publisher: " + canvascid);

                // Initialize a default path
                createPath(false, canvascid);
            }
        }.start();

//        mPublisher.setRenderer(new AnnotationVideoRenderer(getContext()));
    }

    /**
     * Attaches an {@code AnnotationToolbar} to the current {@code AnnotationView}.
     * Note: The same {@code AnnotationToolbar} should be reused for all {@code AnnotationView}s in
     * a visible view.
     * @param toolbar The {@code AnnotationToolbar} to be attached.
     */
    public void attachToolbar(AnnotationToolbar toolbar) {
        this.toolbar = toolbar;
        this.toolbar.addActionListener(this);
        this.toolbar.bringToFront();
    }

    /** ==== Public Getters/Setters ==== **/

    /**
     * Allows the color of the annotations to be manually changed.
     * @param color The integer representation of the color.
     */
    public void setAnnotationColor(int color) {
        userColor = color;
        createPath(false, canvascid); // Create a new paint object to allow for color change
    }

    /**
     * Sets the line width for annotations.
     * @param width The line width (dp).
     */
    public void setAnnotationSize(float width) {
        userStrokeWidth = width;
        createPath(false, canvascid); // Create a new paint object to allow for new stroke size
    }

    /** ==== Private Getters/Setters ==== **/

    // TODO Not sure I want this method - we should be able to get a path from the menu item, but users can use the res id to switch handling on taps
    private void setAction(String action) {
        this.action = action;
    }

    /**
     * Changes the color of incoming annotations (set by the signal string).
     * @param color The integer representation of the color.
     */
    private void changeColor(int color) {
        activeColor = color;
        createPath(true, canvascid); // Create a new path/paint object to allow for color change
    }

    /**
     * Sets the line width for incoming annotations (set by the signal string).
     * @param width The line width (dp).
     */
    private void changeStrokeWidth(float width) {
        activeStrokeWidth = width;
        createPath(true, canvascid); // Create a new path/paint object to allow for new stroke size
    }

    /**
     * Gets the active paint object from the list.
     * @return The active {@code Paint}.
     */
    private Paint getActivePaint() {
        return mPaths.get(mPaths.size()-1).paint;
    }

    /**
     * Gets the active path from the list.
     * @return The active {@code Path}.
     */
    private Path getActivePath() {
        return mPaths.get(mPaths.size()-1).path;
    }

    void drawText(String text, int x, int y) {

    }

    void changeTextSize(float size) {
        getActivePaint().setTextSize(size);
    }

    /** ==== Signal Handling ==== **/

    @Override
    public void signalReceived(Session session, String type, String data, Connection connection) {
        // TODO Add logging to monitor session and connection info

        mycid = session.getConnection().getConnectionId();
        String cid = connection.getConnectionId();

        Log.i("Canvas Signal", cid);
        if (!cid.equals(mycid)) { // Ensure that we only handle signals from other users on the current canvas
            if (type.contains("otAnnotation")) {
                // TODO Do initial parse up here? Iterate below where required?
                if (type.equalsIgnoreCase(Mode.Pen.toString())) {
                    Log.i(TAG, data);
                    // Build object from JSON array
                    JSONParser parser = new JSONParser();

                    try {
                        JSONArray updates = (JSONArray) parser.parse(data);

                        Iterator<String> iterator = updates.iterator();
                        // The data will be batched
                        while (iterator.hasNext()) {
                            Object obj = iterator.next();
                            JSONObject json = (JSONObject) obj;

                            String id = (String) json.get("id");
                            if (canvascid.equals(id)) {
                                changeColor(Color.parseColor(((String) json.get("color")).toLowerCase()));
                                changeStrokeWidth(((Number) json.get("lineWidth")).floatValue());
                                startTouch(((Number) json.get("fromX")).floatValue(), ((Number) json.get("fromY")).floatValue());
                                moveTouch(((Number) json.get("toX")).floatValue(), ((Number) json.get("toY")).floatValue(), true);
                                upTouch();
                                invalidate(); // Need this to finalize the drawing on the screen
                            }
                        }
                    } catch (ParseException e) {
                        Log.e(TAG, e.getMessage());
                    }
                } else if (type.equalsIgnoreCase(Mode.Clear.toString())) {
                    Log.i(TAG, "Clearing canvas");
                    this.clearCanvas();
                }
            }
        }
    }

    private String buildSignalFromPoints(float x, float y) {
        JSONArray jsonArray = new JSONArray();
        JSONObject jsonObject = new JSONObject();

        // TODO Include a unique ID for the path?
        jsonObject.put("id", canvascid);
        jsonObject.put("fromid", mycid);
        jsonObject.put("fromX", mLastX);
        jsonObject.put("fromY", mLastY);
        jsonObject.put("toX", x);
        jsonObject.put("toY", y);
        jsonObject.put("color", String.format("#%06X", (0xFFFFFF & userColor)));
        jsonObject.put("lineWidth", userStrokeWidth);

        // TODO These need to be batched
        jsonArray.add(jsonObject);

        return jsonArray.toJSONString();
    }

    private void sendUpdate(String type, String update) {
        Log.i(TAG, update);

        // Pass this through signal
        if (mSubscriber != null) {
            mSubscriber.getSession().sendSignal(type, update);
        } else if (mPublisher != null) {
            mPublisher.getSession().sendSignal(type, update);
        } else {
            throw new IllegalStateException("A publisher or subscriber must be passed into the class. " +
                    "See attachSubscriber() or attachPublisher().");
        }
    }

    /** ==== Touch Events ==== **/

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        float x = event.getX();
        float y = event.getY();

        if (mPublisher == null || mSubscriber == null) {
            throw new IllegalStateException("An OpenTok Publisher or Subscriber must be passed into the class. " +
                    "See AnnotationView.attachSubscriber() or AnnotationView.attachPublisher().");
        }

        // FIXME Switch on global action (pen, shape (subshape), text, etc.)
        if (action.equalsIgnoreCase("Pen")) {
            switch (event.getAction()) {
                case MotionEvent.ACTION_DOWN:
                    createPath(false, canvascid);
                    startTouch(x, y);
                    mLastX = x;
                    mLastY = y;
                    invalidate();
                    break;
                case MotionEvent.ACTION_MOVE:
                    moveTouch(x, y, true);
                    invalidate();

                    sendUpdate(Mode.Pen.toString(), buildSignalFromPoints(x, y));

                    mLastX = x;
                    mLastY = y;

                    break;
                case MotionEvent.ACTION_UP:
                    upTouch();
                    invalidate();
                    break;
            }
        } else if (action.equalsIgnoreCase("Text")) {
            // INFO Per Meeta Dash, omit text for now (include if time)
            // TODO Add text input and submit data below as user types

            Log.i(TAG, "Adding text...");

            Paint paint = new Paint();
            paint.setColor(Color.RED);
            paint.setTextSize(16);

            mLabels.add(new AnnotationText("This is a test", x, y, paint));
            invalidate();

            JSONArray jsonArray = new JSONArray();
            JSONObject jsonObject = new JSONObject();

            // TODO Include a unique ID for the path? - this way it can be removed using history
            jsonObject.put("id", canvascid);
            jsonObject.put("fromid", mycid);
            jsonObject.put("x", x);
            jsonObject.put("y", y);
            jsonObject.put("text", "This is a test");
            jsonObject.put("color", String.format("#%06X", (0xFFFFFF & userColor)));
            jsonObject.put("textSize", 16/*userTextSize*/);

            // TODO These need to be batched
            jsonArray.add(jsonObject);

            String update = jsonArray.toJSONString();

            sendUpdate(Mode.Text.toString(), update);
        } else if (action.equalsIgnoreCase("Arrow")) { // TODO Switch points based on selection (pull from menu item)
            mX = x;
            mY = y;

            onTouchEvent(event, arrowPoints);
        } else if (action.equalsIgnoreCase("Rectangle")) {
            mX = x;
            mY = y;

            onTouchEvent(event, rectanglePoints);
        } else if (action.equalsIgnoreCase("Oval")) {
            mX = x;
            mY = y;

            onTouchEvent(event, circlePoints);
        } else if (action.equalsIgnoreCase("Line")) {
            mX = x;
            mY = y;
            onTouchEvent(event, linePoints);
        } else if (action.equalsIgnoreCase("Capture")) {
            captureView();
        }
        return true;
    }

    private void onTouchEvent(MotionEvent event, FloatPoint[] points) {
        switch (event.getAction()) {
            case MotionEvent.ACTION_DOWN:
                isDrawing = true;
                // Last x and y for shape paths is the start touch point
                mStartX = mX;
                mStartY = mY;
                invalidate();
                break;
            case MotionEvent.ACTION_MOVE:
                invalidate();
                break;
            case MotionEvent.ACTION_UP:
                isDrawing = false;

                if (points.length == 2) {
                    // We have a line
                    startTouch(mStartX, mStartY);
                    moveTouch(mX, mY, false);
                    upTouch();
                    Log.i(TAG, "Points: (" + mStartX + ", " + mStartY + "), (" + mX + ", " + mY + ")");
                    sendUpdate(Mode.Pen.toString(), buildSignalFromPoints(mX, mY));
                } else {
                    FloatPoint scale = scaleForPoints(points);

                    for (int i = 0; i < points.length; i++) {
                        // Scale the points according to the difference between the start and end points
                        float pointX = mStartX + (scale.x * points[i].x);
                        float pointY = mStartY + (scale.y * points[i].y);

                        if (i == 0) {
                            mLastX = pointX;
                            mLastY = pointY;
                            startTouch(pointX, pointY);
                        } else {
                            // TODO Way to know whether to use curved/smooth or not?
                            moveTouch(pointX, pointY, false);
                        }

                        sendUpdate(Mode.Pen.toString(), buildSignalFromPoints(pointX, pointY));

                        mLastX = pointX;
                        mLastY = pointY;
                    }
                }

                invalidate();
                break;
        }
    }

    private void startTouch(float x, float y) {
        getActivePath().moveTo(x, y);
        mX = x;
        mY = y;
    }

    private void moveTouch(float x, float y, boolean curved) {
        float dx = Math.abs(x - mX);
        float dy = Math.abs(y - mY);
        if (dx >= TOLERANCE || dy >= TOLERANCE) {
            if (curved) {
                getActivePath().quadTo(mX, mY, (x + mX) / 2, (y + mY) / 2);
            } else {
                getActivePath().lineTo(x, y);
            }
            mX = x;
            mY = y;
        }
    }

    private void upTouch() {
        getActivePath().lineTo(mX, mY);
    }

    /** ==== Canvas Events ==== **/

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        super.onSizeChanged(w, h, oldw, oldh);

        // your Canvas will draw onto the defined Bitmap
        mBitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888);
        mCanvas = new Canvas(mBitmap);
    }

	@Override
	protected void onDraw(Canvas canvas) {
		super.onDraw(canvas);
		// draw the mPath with the mPaint on the canvas when onDraw
        for (AnnotationPath drawing : mPaths) {
            canvas.drawPath(drawing.path, drawing.paint);
        }

        for (AnnotationText label : mLabels) {
            canvas.drawText(label.text, label.x, label.y, label.paint);
        }

        if (isDrawing) {
            // TODO Use generic method and switch based on the base path (points) from active menu item
            if (action.equalsIgnoreCase("Line")) {
                onDrawPoints(canvas, linePoints);
            } else if (action.equalsIgnoreCase("Arrow")) {
                onDrawPoints(canvas, arrowPoints);
            } else if(action.equalsIgnoreCase("Rectangle")) {
                onDrawPoints(canvas, rectanglePoints);
            } else if (action.equalsIgnoreCase("Oval")) {
                onDrawPoints(canvas, circlePoints);
            }
        }
	}

    private void onDrawPoints(Canvas canvas, FloatPoint[] points) {
        float dx = Math.abs(mX - mLastX);
        float dy = Math.abs(mY - mLastY);
        if (dx >= TOLERANCE || dy >= TOLERANCE) {
            FloatPoint scale = scaleForPoints(points);
            Path path = new Path();

            if (points.length == 2) {
                // We have a line
                path.moveTo(mStartX, mStartY);
                path.lineTo(mX, mY);
            } else {
                for (int i = 0; i < points.length; i++) {
                    // Scale the points according to the difference between the start and end points
                    float pointX = mStartX + (scale.x * points[i].x);
                    float pointY = mStartY + (scale.y * points[i].y);

                    if (i == 0) {
                        path.moveTo(pointX, pointY);
                    } else {
                        path.lineTo(pointX, pointY);
                    }
                }
            }

            canvas.drawPath(path, getActivePaint());
        }
    }

    /**
     * Scales a path (defined by its points) based on the drag gesture by the user.
     * @param points The base points to be scaled.
     * @return A {@code FloatPoint} indicating the scales in both the x and y directions.
     */
    private FloatPoint scaleForPoints(FloatPoint[] points) {
        // mX and mY refer to the end point of the enclosing rectangle (touch up)
        float minX = Float.MAX_VALUE;
        float minY = Float.MAX_VALUE;
        float maxX = 0;
        float maxY = 0;
        for (int i = 0; i < points.length; i++) {
            if (points[i].x < minX) {
                minX = points[i].x;
            } else if (points[i].x > maxX) {
                maxX = points[i].x;
            }

            if (points[i].y < minY) {
                minY = points[i].y;
            } else if (points[i].y > maxY) {
                maxY = points[i].y;
            }
        }
        float dx = Math.abs(maxX - minX);
        float dy = Math.abs(maxY - minY);

        Log.i("AnnotationView", "Delta: " + dx + ", " + dy);

        float scaleX = (mX - mStartX) / dx;
        float scaleY = (mY - mStartY) / dy;

        Log.i("AnnotationView", "Scale: " + scaleX + ", " + scaleY);

        return new FloatPoint(scaleX, scaleY);
    }

	public void clearCanvas() {
        Iterator<AnnotationPath> iter = mPaths.iterator();

        while (iter.hasNext()) {
            AnnotationPath path = iter.next();

            if (path.connectionId.equals(mycid)) {
                iter.remove();
            }
        }

        // TODO Send signal to clear paths with connection ID

		invalidate();
        createPath(false, canvascid);
	}

    private void createPath(boolean incoming, String cid) {
        Paint paint = new Paint();
        paint.setAntiAlias(true);
        paint.setColor(incoming ? activeColor : userColor);
        paint.setStyle(Paint.Style.STROKE);
        paint.setStrokeJoin(Paint.Join.ROUND);
        paint.setStrokeWidth(incoming ? activeStrokeWidth : userStrokeWidth);

        if (mPublisher == null && mSubscriber == null) {
            throw new IllegalStateException("An OpenTok Publisher or Subscriber must be passed into the class. " +
                    "See AnnotationView.attachSubscriber() or AnnotationView.attachPublisher().");
        }

        Log.i(TAG, cid);

        mPaths.add(new AnnotationPath(new Path(), paint, cid)); // Generate a new drawing path
    }

    /** ==== View capture (screenshots) ==== **/

    public void captureView() {
        // TODO Add a "flash" animation to indicate the screenshot was captured
        try {
            boolean notSupported = false;
            // Use custom renderer to get screenshot from publisher/subscriber
            Bitmap videoFrame = null;
            if (mPublisher != null) {
                if (mPublisher.getRenderer() instanceof  AnnotationVideoRenderer) {
                    videoFrame = ((AnnotationVideoRenderer) mPublisher.getRenderer()).captureScreenshot();
                } else {
                    notSupported = true;
                }
            } else if (mSubscriber != null) {
                if (mSubscriber.getRenderer() instanceof  AnnotationVideoRenderer) {
                    videoFrame = ((AnnotationVideoRenderer) mSubscriber.getRenderer()).captureScreenshot();
                } else {
                    notSupported = true;
                }
            } else {
                Log.e("AnnotationView", "The AnnotationView is not attached to a subscriber or " +
                        "publisher. See AnnotationView.attachSubscriber() or AnnotationView.attachPublisher().");
                return;
            }

            if (notSupported) {
                Log.e("AnnotationView", "Screen capturing is not supported without using an " +
                        "AnnotationVideoRender. See the docs for details.");
                return;
            }

            if (videoFrame != null) {
                View v = ((View) this.getParent());
                v.setDrawingCacheEnabled(true);
                Bitmap annotations = v.getDrawingCache(true).copy(Bitmap.Config.ARGB_8888, false);
                v.setDrawingCacheEnabled(false);

                // Overlay the annotations on top of the video capture and store a final bitmap
                Bitmap screenshot = overlay(annotations, videoFrame);

                // TODO Send screenshot bitmap through callback

            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /**
     * Allows the annotations to be overlaid on top of the video frame.
     * @param overlay The annotation overlay.
     * @param underlay The annotation video frame.
     * @return The "merged" bitmap of the images.
     */
    private Bitmap overlay(Bitmap overlay, Bitmap underlay) {
        Bitmap bmOverlay = Bitmap.createBitmap(overlay.getWidth(), overlay.getHeight(), overlay.getConfig());

        // TODO Make sure the scaling is handled correctly
        double ratio;
        if (overlay.getWidth() > overlay.getHeight()) {
            ratio = (double) overlay.getWidth() / (double) underlay.getWidth();
        } else {
            ratio = (double) overlay.getHeight() / (double) underlay.getHeight();
        }

        int scaledWidth = (int) (underlay.getWidth() * ratio);
        int scaledHeight = (int) (underlay.getHeight() * ratio);

        Bitmap scaledBitmap = Bitmap.createScaledBitmap(underlay, scaledWidth, scaledHeight, false);
        Canvas canvas = new Canvas(bmOverlay);
        canvas.drawBitmap(scaledBitmap, 0, 0, null);
        canvas.drawBitmap(overlay, 0, 0, null);
        return bmOverlay;
    }

    /** ==== Misc. ==== **/

    // INFO This method shouldn't be necessary, but in case we need it...
    private Point[] getPoints(Path path) {
        Point[] pointArray = new Point[20];
        PathMeasure pm = new PathMeasure(path, false);
        float length = pm.getLength();
        float distance = 0f;
        float speed = length / 20;
        int counter = 0;
        float[] aCoordinates = new float[2];

        while ((distance < length) && (counter < 20)) {
            // get point from the path
            pm.getPosTan(distance, aCoordinates, null);
            pointArray[counter] = new Point((int)aCoordinates[0],
                    (int)aCoordinates[1]);
            counter++;
            distance = distance + speed;
        }

        return pointArray;
    }
}