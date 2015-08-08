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

public class AnnotationView extends View implements AnnotationToolbar.ActionListener {

    private static final String TAG = "ot-annotations-canvas";

	public int width;
	public int height;
	private Bitmap mBitmap;
	private Canvas mCanvas;
    // TODO Merge these three lists so that they can be used for history (undo)
	private List<DrawingPath> mPaths;
	private List<DrawingShape> mShapes;
	private List<DrawingText> mLabels;
	Context context;
	private float mX, mY;
	private float mLastX, mLastY;
	private static final float TOLERANCE = 5;

    private AnnotationToolbar toolbar;

    // FIXME This should be an enum built into the annotation item
    private String[] actions = {
        "Pen",
        "Shapes",
        "Line",
        "Text"
    };

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

    // TODO Create 'Mode' for 'pen', 'text', 'shape', 'line'

    public AnnotationView(Context c) {
        this(c, null);
    }

	public AnnotationView(Context c, AttributeSet attrs) {
		super(c, attrs);
		context = c;

		mPaths = new ArrayList<DrawingPath>();
		mShapes = new ArrayList<DrawingShape>();
		mLabels = new ArrayList<DrawingText>();

        // Default stroke and color
        userColor = activeColor = Color.RED;
        userStrokeWidth = activeStrokeWidth = 6f;

		// Initialize a default path
        createPath(false);
	}

    // TODO Could create attach(subscriber, toolbar) and attach(publisher, toolbar) instead

    // FIXME These need to test for a custom renderer - if one was already added, it should override ours (disable screenshots)
    public void attachSubscriber(Subscriber subscriber) {
        this.setLayoutParams(subscriber.getView().getLayoutParams());
        mSubscriber = subscriber;
//        mSubscriber.setRenderer(new AnnotationVideoRenderer(getContext()));

//        ViewGroup parent = (ViewGroup) subscriber.getView().getParent();
//        parent.removeView(subscriber.getView());
//        parent.addView(mSubscriber.getView());
    }

    public void attachPublisher(Publisher publisher) {
        this.setLayoutParams(publisher.getView().getLayoutParams());
        mPublisher = publisher;
//        mPublisher.setRenderer(new AnnotationVideoRenderer(getContext()));
    }

    public void attachToolbar(AnnotationToolbar toolbar) {
        this.toolbar = toolbar;
        this.toolbar.addActionListener(this);
        this.toolbar.bringToFront();
    }

    /*
        id: OTSession.session && OTSession.session.connection && OTSession.session.connection.connectionId,
        fromX: client.lastX,
        fromY: client.lastY,
        toX: x,
        toY: y,
        color: scope.color,
        lineWidth: scope.lineWidth
     */
    public void signalReceived(Session session, String type, String data, Connection connection) {
        // TODO Add logging to monitor session and connection info

        String mycid = session.getConnection().getConnectionId();
        String cid = connection.getConnectionId();
        if (!cid.equals(mycid)) { // Ensure that we only handle signals from other users
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

                        changeColor(Color.parseColor(((String) json.get("color")).toLowerCase()));
                        changeStrokeWidth(((Number) json.get("lineWidth")).floatValue());
                        startTouch(((Number) json.get("fromX")).floatValue(), ((Number) json.get("fromY")).floatValue());
                        moveTouch(((Number) json.get("toX")).floatValue(), ((Number) json.get("toY")).floatValue());
                        upTouch(); // TODO Should this only get called at the end?
                        invalidate(); // Need this to finalize the drawing on the screen
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

    public void setAnnotationColor(int color) {
        userColor = color;
        createPath(false); // Create a new paint object to allow for color change
    }

    public void setAnnotationSize(float width) {
        userStrokeWidth = width;
        createPath(false); // Create a new paint object to allow for new stroke size
    }

	private void changeColor(int color) {
        activeColor = color;
		createPath(true); // Create a new paint object to allow for color change
	}

	private void changeStrokeWidth(float width) {
        activeStrokeWidth = width;
        createPath(true); // Create a new paint object to allow for new stroke size
	}

	// override onSizeChanged
	@Override
	protected void onSizeChanged(int w, int h, int oldw, int oldh) {
		super.onSizeChanged(w, h, oldw, oldh);

		// your Canvas will draw onto the defined Bitmap
		mBitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888);
		mCanvas = new Canvas(mBitmap);
	}

	// override onDraw
	@Override
	protected void onDraw(Canvas canvas) {
		super.onDraw(canvas);
		// draw the mPath with the mPaint on the canvas when onDraw
        for (DrawingPath drawing : mPaths) {
            canvas.drawPath(drawing.path, drawing.paint);
        }

        for (DrawingShape shape : mShapes) {
            shape.drawable.draw(canvas);
        }

        for (DrawingText label : mLabels) {
            canvas.drawText(label.text, label.x, label.y, label.paint);
        }
	}

	// when ACTION_DOWN start touch according to the x,y values
	private void startTouch(float x, float y) {
        getActivePath().moveTo(x, y);
		mX = x;
		mY = y;
	}

	// when ACTION_MOVE move touch according to the x,y values
	private void moveTouch(float x, float y) {
		float dx = Math.abs(x - mX);
		float dy = Math.abs(y - mY);
		if (dx >= TOLERANCE || dy >= TOLERANCE) {
            getActivePath().quadTo(mX, mY, (x + mX) / 2, (y + mY) / 2);
			mX = x;
			mY = y;
		}
	}

	public void clearCanvas() {
		mPaths.clear();
		mShapes.clear();
		mLabels.clear();
		invalidate();
        createPath(false);
	}

	// when ACTION_UP stop touch
	private void upTouch() {
        getActivePath().lineTo(mX, mY);
	}

    private Paint getActivePaint() {
        return mPaths.get(mPaths.size()-1).paint;
    }

    private Path getActivePath() {
        return mPaths.get(mPaths.size()-1).path;
    }

	@Override
	public boolean onTouchEvent(MotionEvent event) {
		float x = event.getX();
		float y = event.getY();

        // TODO Generate a new path if necessary

        // FIXME Switch on global action (pen, shape (subshape), text, etc.)
        if (action.equalsIgnoreCase("Pen")) {
            switch (event.getAction()) {
                case MotionEvent.ACTION_DOWN:
                    createPath(false);
                    startTouch(x, y);
                    mLastX = x;
                    mLastY = y;
                    invalidate();
                    break;
                case MotionEvent.ACTION_MOVE:
                    moveTouch(x, y);

                    JSONArray jsonArray = new JSONArray();
                    JSONObject jsonObject = new JSONObject();

                    jsonObject.put("id", "android-test");//mSession.getSessionId() & mSession.getConnection().getConnectionId());
                    jsonObject.put("fromX", mLastX);
                    jsonObject.put("fromY", mLastY);
                    jsonObject.put("toX", x);
                    jsonObject.put("toY", y);
                    jsonObject.put("color", String.format("#%06X", (0xFFFFFF & userColor)));
                    jsonObject.put("lineWidth", userStrokeWidth);

                    // TODO These need to be batched
                    jsonArray.add(jsonObject);

                    String update = jsonArray.toJSONString();
                    mLastX = x;
                    mLastY = y;
                    invalidate();

                    sendUpdate(Mode.Pen.toString(), update);
                    break;
                case MotionEvent.ACTION_UP:
                    upTouch();
                    invalidate();
                    break;
            }
        } else if (action.equalsIgnoreCase("Text")) {
            // TODO Add text input and submit data below as user types

            Log.i(TAG, "Adding text...");

            Paint paint = new Paint();
            paint.setColor(Color.RED);
            paint.setTextSize(16);

            mLabels.add(new DrawingText("This is a test", x, y, paint));
            invalidate();

            JSONArray jsonArray = new JSONArray();
            JSONObject jsonObject = new JSONObject();

            // TODO This ID should refer to the path, as well - this way it can be removed using history
            jsonObject.put("id", "android-test");//mSession.getSessionId() & mSession.getConnection().getConnectionId());
            jsonObject.put("x", x);
            jsonObject.put("y", y);
            jsonObject.put("text", "This is a test");
            jsonObject.put("color", String.format("#%06X", (0xFFFFFF & userColor)));
            jsonObject.put("textSize", 16/*userTextSize*/);

            // TODO These need to be batched
            jsonArray.add(jsonObject);

            String update = jsonArray.toJSONString();

            sendUpdate(Mode.Text.toString(), update);
        } else if (action.equalsIgnoreCase("Shape")) {
            switch (event.getAction()) {
                case MotionEvent.ACTION_DOWN:
                    createPath(false);
                    startTouch(x, y);
                    mLastX = x;
                    mLastY = y;
                    invalidate();
                    break;
                case MotionEvent.ACTION_MOVE:
                    moveTouch(x, y);

                    JSONArray jsonArray = new JSONArray();
                    JSONObject jsonObject = new JSONObject();

                    // TODO This ID should refer to the path, as well - this way it can be removed using history
                    jsonObject.put("id", "android-test");//mSession.getSessionId() & mSession.getConnection().getConnectionId());
                    jsonObject.put("fromX", mLastX);
                    jsonObject.put("fromY", mLastY);
                    jsonObject.put("toX", x);
                    jsonObject.put("toY", y);
                    jsonObject.put("color", String.format("#%06X", (0xFFFFFF & userColor)));
                    jsonObject.put("lineWidth", userStrokeWidth);

                    // TODO These need to be batched
                    jsonArray.add(jsonObject);

                    String update = jsonArray.toJSONString();
                    mLastX = x;
                    mLastY = y;
                    invalidate();

                    sendUpdate(Mode.Pen.toString(), update);
                    break;
                case MotionEvent.ACTION_UP:
                    upTouch();
                    invalidate();
                    break;
            }
        } else if (action.equalsIgnoreCase("Line")) {

        } else if (action.equalsIgnoreCase("Capture")) {
            captureView();
        }
		return true;
	}

    private void createPath(boolean incoming) {
        Paint paint = new Paint();
        paint.setAntiAlias(true);
        paint.setColor(incoming ? activeColor : userColor);
        paint.setStyle(Paint.Style.STROKE);
        paint.setStrokeJoin(Paint.Join.ROUND);
        paint.setStrokeWidth(activeStrokeWidth);

        mPaths.add(new DrawingPath(new Path(), paint)); // Generate a new drawing path
    }

    // TODO Reference http://developer.android.com/guide/topics/graphics/2d-graphics.html for an example of
    // TODO adding custom shapes
    /*internal*/ void draw(ShapeDrawable d, int x, int y, int width, int height) {
        d.getPaint().setColor(0xff74AC23);
        d.setBounds(x, y, x + width, y + height);
    }

    void drawText(String text, int x, int y) {

    }

    void changeTextSize(float size) {
        getActivePaint().setTextSize(size);
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

    private void setAction(String action) {
        this.action = action;
    }

    public void drawPathFromPoints(FloatPoint[] points) {
        // Start with point 0
        startTouch(points[0].x, points[0].y);

        // Iterate through the rest
        int i = 0;
        for (FloatPoint point : points) {
            if (i != 0) {
                moveTouch(point.x, point.y);
            }
            i++;
        }

        // Close the path
        upTouch();
    }

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

    public void captureView() {
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

}