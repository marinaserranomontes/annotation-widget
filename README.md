OpenTok Android Annotations Plugin
===========================

This plugin adds annotation and screen capture capabilities to OpenTok for Android.

Notes
-----

* See [OpenTok Android SDK developer and client requirements](http://tokbox.com/opentok/libraries/client/android/#developerandclientrequirements) for a list or system requirements and supported devices.

* See the [OpenTok Android SDK Reference](http://tokbox.com/opentok/libraries/client/android/reference/index.html)
for details on the API.

Installing
----------

### Gradle

1. Add `compile 'com.opentok.android.plugin:annotations-component:1.0.0'` to `dependencies` in your module's build.gradle file.
2. Sync Gradle and build your project.

### .AAR in Android Studio

1. Right click on your project module (usually called "app" but may be something else) and choose "Open Module Settings" from the bottom of the menu.
2. Click the '+' sign in the upper left hand corner.
3. Choose "Import .JAR or .AAR Package" from the list in the popup.
4. Follow the prompts and build your project.

Using the plugin
----------------

For a quick start, download the [OpenTok Android samples](https://github.com/opentok/opentok-android-sdk-samples). If you already have your own project to work with,
the steps below should help you incorporate the annotations plugin.

We'll use the `HelloWorldActivity` from the samples to demonstrate how the plugin works.

Add the `AnnotationToolbar` to your view. The easiest way is to include in in your layout resource file:

```xml
<com.opentok.android.plugin.AnnotationToolbar
    android:id="@+id/toolbar"
    android:layout_width="match_parent"
    android:layout_height="?android:attr/actionBarSize"/>
```

In `HelloWorldActivity.java`, add the following to the onCreate method:

```java
mToolbar = (AnnotationToolbar) findViewById(R.id.toolbar);
```

Add the following lines to the end of the `attachSubscriberView` method (Note: the annotation view should be added to the `mSubscriberViewContainer` after the subscriber view).

```java
private void attachSubscriberView(Subscriber subscriber) {
    RelativeLayout.LayoutParams layoutParams = new RelativeLayout.LayoutParams(
            getResources().getDisplayMetrics().widthPixels, getResources()
            .getDisplayMetrics().heightPixels);
    mSubscriberViewContainer.removeView(subscriber.getView());
    mSubscriberViewContainer.addView(subscriber.getView(), layoutParams);
    subscriber.setStyle(BaseVideoRenderer.STYLE_VIDEO_SCALE,
            BaseVideoRenderer.STYLE_VIDEO_FILL);

    // Add these 3 lines to attach the annotation view to the subscriber view
    AnnotationView annotationView = new AnnotationView(this);
    mSubscriberViewContainer.addView(annotationView);
    annotationView.attachSubscriber(subscriber);
    
    // Add this line to attach the annotation view to the toolbar
    annotationView.attachToolbar(mToolbar);
}
```

Add the following lines to the ends of the `attachPublisherView` method (Note: the annotation view should be added to the `mPublisherViewContainer` after the publisher view).

```java
private void attachPublisherView(Publisher publisher) {
    publisher.setStyle(BaseVideoRenderer.STYLE_VIDEO_SCALE,
            BaseVideoRenderer.STYLE_VIDEO_FILL);
    RelativeLayout.LayoutParams layoutParams = new RelativeLayout.LayoutParams(
            320, 240);
    layoutParams.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM,
            RelativeLayout.TRUE);
    layoutParams.addRule(RelativeLayout.ALIGN_PARENT_RIGHT,
            RelativeLayout.TRUE);
    layoutParams.bottomMargin = dpToPx(8);
    layoutParams.rightMargin = dpToPx(8);
    mPublisherViewContainer.addView(publisher.getView(), layoutParams);

    // Add these 3 lines to attach the annotation view to the publisher view
    AnnotationView annotationView = new AnnotationView(this);
    mPublisherViewContainer.addView(annotationView);
    annotationView.attachPublisher(publisher);
    
    // Add this line to attach the annotation view to the toolbar
    annotationView.attachToolbar(mToolbar);
}
```

Last, pass signals through the `AnnotationToolbar` object in the onSignalReceived method.

    @Override
    public void onSignalReceived(Session session, String type, String data, Connection connection) {
        // Attach the signals to the canvas objects
        mToolbar.attachSignal(session, type, data, connection);
    }

Note: Make sure that your class implements `Session.SignalListener`. See []() for more details.