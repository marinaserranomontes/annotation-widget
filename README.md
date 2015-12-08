OpenTok Annotations Widget for Android -- Beta
===========================

The OpenTok Annotations Widget for Android is written in Java, includes an AAR file for easy import into Android Studio, and also offers JitPack Gradle support.

As a beta, this code is subject to change. Pull requests are welcome. You can also email feedback to collaboration-tools-beta-program@tokbox.com.


Requirements
-----

Review the requirements for [OpenTok](https://tokbox.com/developer/requirements/) and the [OpenTok Android SDK](https://tokbox.com/developer/sdks/android/#developer-and-client-requirements).


Prerequisites
-----

* [OpenTok Android SDK](https://tokbox.com/developer/sdks/android/) version 2.7, 2.6, or 2.5: *latest version is preferred*

* A project that uses the OpenTok Android SDK

**PRO TIP**: If you don't already have a project, grab [OpenTok Android SDK Samples](https://github.com/opentok/opentok-android-sdk-samples) for a quick start.


Installing
----------

### Gradle

1. Include the JitPack repository in your module's `build.gradle` file by adding `maven { url "https://jitpack.io" }` to the `repositories` section.
2. Add `compile 'com.github.opentok:annotation-widget:1.0.0-android-beta'` to `dependencies` in your module's `build.gradle` file.
3. Sync Gradle and build your project.

### .AAR in Android Studio

1. Download the [latest version](https://github.com/opentok/annotation-widget/releases/tag/1.0.0-android-beta) of the widget.
2. Right click on your project module (usually called "app" but may be something else) and choose "Open Module Settings" from the bottom of the menu.
3. Click the '+' sign in the upper left hand corner.
4. Choose "Import .JAR or .AAR Package" from the list in the popup.
5. Locate the AAR file in the zip downloaded in step 1. You can set the module name to `:opentokAnnotations` or similar.
6. Follow the prompts and build your project.
7. Click the "+" button at the bottom of the dependencies screen, and choose "module dependency". It will add the line `compile project(':opentokAnnotations')` to the app build.gradle.

### Clone/download this repo

1. Once you've cloned/downloaded the files from this repo, right click on your project module (usually called "app" but may be something else) and choose "Open Module Settings" from the bottom of the menu.
2. Click the '+' sign in the upper left hand corner.
3. Choose "Import Existing Project" from the list of options.
4. Browse to the location of the cloned/downloaded files, select "Ok" and then "Finish".

Using the widget
----------------

We'll use the `HelloWorldActivity` from the [OpenTok Android samples](https://github.com/opentok/opentok-android-sdk-samples) to illustrate how to use the Android Annotations widget.

### Including the annotation toolbar in your layout

Add `AnnotationToolbar` to your view. The easiest way is to include in in your layout resource file:

```xml
<com.opentok.android.plugin.AnnotationToolbar
    android:id="@+id/toolbar"
    android:layout_width="match_parent"
    android:layout_height="?android:attr/actionBarSize"/>
```

In `HelloWorldActivity.java`, add the following to the `onCreate` method:

```java
mToolbar = (AnnotationToolbar) findViewById(R.id.toolbar);
```

### Adding a custom annotation renderer

The Android Annotation widget includes a `AnnotationVideoRenderer` class which extends the `BaseVideoRenderer` class in the OpenTok Android SDK. Instantiate `AnnotationVideoRenderer` using the following sample code.

```java
AnnotationVideoRenderer renderer = new AnnotationVideoRenderer(this);
```

You can then attach this to a publisher/subscriber using the `setRenderer(...)` method.

**PRO TIP**: If you have already developed your own custom video renderer simply modify it so that it extends `AnnotationVideoRenderer` instead of `BaseVideoRenderer`.


### Attaching an annotation canvas to a subscriber view

Add the following lines to the end of the `attachSubscriberView` method.

**PRO TIP**: Add the annotation view to the `mSubscriberViewContainer` *after* the subscriber view.

```java
private void attachSubscriberView(Subscriber subscriber) {
    ...

    // Add these 3 lines to attach the annotation view to the subscriber view
    AnnotationView annotationView = new AnnotationView(this);
    mSubscriberViewContainer.addView(annotationView);
    annotationView.attachSubscriber(subscriber);

    // Add this line to attach the annotation view to the toolbar
    annotationView.attachToolbar(mToolbar);
}
```

### Attaching an annotation canvas to a publisher view

Add the following lines to the end of the `attachPublisherView` method.

**PRO TIP**: Add the annotation view to the `mPublisherViewContainer` *after* the publisher view.

```java
private void attachPublisherView(Publisher publisher) {
    ...

    // Add these 3 lines to attach the annotation view to the publisher view
    AnnotationView annotationView = new AnnotationView(this);
    mPublisherViewContainer.addView(annotationView);
    annotationView.attachPublisher(publisher);

    // Add this line to attach the annotation view to the toolbar
    annotationView.attachToolbar(mToolbar);
}
```

### Hooking in signals

Lastly, pass signals through the `AnnotationToolbar` object in the `onSignalReceived` method.

```java
@Override
public void onSignalReceived(Session session, String type, String data, Connection connection) {
    // Attach the signals to the canvas objects
    mToolbar.attachSignal(session, type, data, connection);
}
```

**IMPORTANT**: Make sure that your class implements `Session.SignalListener`. You will also need to make sure you have set the session's signal listener using `mSession.setSignalListener(this);` See the [OpenTok Android SDK docs](https://tokbox.com/developer/sdks/android/reference/) for more details.

### Grabbing frames

Frames and their annotations can be captured when using the 'ot_item_capture' menu item. The `Bitmap` for
 these captures can be handled using the following callback:

```java
mToolbar.addScreenCaptureListener(new AnnotationToolbar.ScreenCaptureListener() {
    @Override
    public void onScreenCapture(Bitmap screenCapture, String connectionId) {
        Log.i(LOGTAG, "Captured screenshot for connection: " + connectionId);
        // Handle the screen capture, i.e. save the file or create a share intent, etc.
    }
});
```

Customizing the toolbar
----------------

### <a name="menu-defaults"></a>Default menu items

Below is a list of default menu items that can be used in your custom menu. These come pre-built with the action specified. If no custom menu is inflated
in the `onCreateAnnotationMenu` listener method, these will be automatically added to your toolbar.

| id            | Action        |
| ------------- | ------------- |
| R.id.ot_item_pen | Freehand/Pen tool |
| R.id.ot_item_line | Line tool |
| R.id.ot_menu_shape | Shapes group/submenu |
| R.id.ot_item_arrow | Arrow tool |
| R.id.ot_item_rectangle | Rectangle tool |
| R.id.ot_item_oval | Oval tool |
| R.id.ot_menu_colors | Color picker submenu |
| R.id.ot_menu_line_width | Line width picker submenu |
| R.id.ot_item_clear | Clears active user annotations |
| R.id.ot_item_capture | Tap a video frame to capture a screenshot |

### <a name="menu-xml"></a>Create menu items through XML

Below is an example of a custom annotation menu, located in <var>res/xml</var>. Here, we create a custom `item_star` menu item in the `ot_menu_shape` group.

**PRO TIP**: Refer to the list of [default menu items](#menu-defaults) to find out what actions come built into the widget.

```xml
<?xml version="1.0" encoding="utf-8"?>
<ot-menu
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto">
    <item
        android:id="@+id/ot_item_pen"
        app:icon="@drawable/ic_freehand"/>
    <item
        android:id="@+id/ot_item_line"
        app:icon="@drawable/ic_line"/>
    <menu-item
        android:id="@+id/ot_menu_shape"
        app:icon="@drawable/ic_shapes">
        <item
            android:id="@+id/ot_item_arrow"
            app:icon="@drawable/ic_arrow"/>
        <item
            android:id="@+id/ot_item_rectangle"
            app:icon="@drawable/ic_rectangle"/>
        <item
            android:id="@+id/ot_item_oval"
            app:icon="@drawable/ic_oval"/>
        <!-- User-added custom item -->
        <item
            android:id="@+id/item_star"
            app:icon="@drawable/ic_star"/>
    </menu-item>
    <menu-item
        android:id="@+id/ot_menu_colors">
        <!-- Items added dynamically -->
    </menu-item>
    <menu-item
        android:id="@+id/ot_menu_line_width"
        app:icon="@drawable/ic_line_width">
        <!-- Items added dynamically -->
    </menu-item>
    <item
        android:id="@+id/ot_item_clear"
        app:icon="@drawable/ic_clear" />
</ot-menu>
```

To inflate the custom menu in the toolbar:
1. Make sure your class implements `AnnotationToolbar.ActionListener`
2. Make sure you add an action listener to the toolbar object using `mToolbar.addActionListener(this);`
Add the following to the `onCreateAnnotationMenu` method.

```java
@Override
public boolean onCreateAnnotationMenu(AnnotationMenuView menu) {
    // ot_extended is the name of the annotation menu xml file in 'res/xml'
    menu.inflateMenu(R.xml.ot_extended, mToolbar);

    return true;
}
```

**PRO TIP**: The annotation toolbar only supports a single submenu. For additional group/menu options, you can use the `onAnnotationMenuItemSelected`
listener method to add a popover, dropdown, dialog, or any other view to allow more options.

### Handling custom items

First, make sure you add an action listener (`mToolbar.addActionListener(this);`) to the toolbar (implement `AnnotationToolbar.ActionListener`).

Below is an example of adding a star annotation shape to the `R.id.item_star` menu item created [above](#menu-xml).

```java
@Override
public void onAnnotationItemSelected(AnnotationToolbarItem item) {
    int id = item.getItemId();

    switch (id) {
        case R.id.item_star: {
            FloatPoint[] starPoints = {
                    // INFO To invert the star, use 360-a for the angle
                    new FloatPoint(0.5f + 0.5f*(float)Math.cos(Math.toRadians(90)), 0.5f + 0.5f*(float)Math.sin(Math.toRadians(90))),
                    new FloatPoint(0.5f + 0.25f*(float)Math.cos(Math.toRadians(126)), 0.5f + 0.25f*(float)Math.sin(Math.toRadians(126))),
                    new FloatPoint(0.5f + 0.5f*(float)Math.cos(Math.toRadians(162)), 0.5f + 0.5f*(float)Math.sin(Math.toRadians(162))),
                    new FloatPoint(0.5f + 0.25f*(float)Math.cos(Math.toRadians(198)), 0.5f + 0.25f*(float)Math.sin(Math.toRadians(198))),
                    new FloatPoint(0.5f + 0.5f*(float)Math.cos(Math.toRadians(234)), 0.5f + 0.5f*(float)Math.sin(Math.toRadians(234))),
                    new FloatPoint(0.5f + 0.25f*(float)Math.cos(Math.toRadians(270)), 0.5f + 0.25f*(float)Math.sin(Math.toRadians(270))),
                    new FloatPoint(0.5f + 0.5f*(float)Math.cos(Math.toRadians(306)), 0.5f + 0.5f*(float)Math.sin(Math.toRadians(306))),
                    new FloatPoint(0.5f + 0.25f*(float)Math.cos(Math.toRadians(342)), 0.5f + 0.25f*(float)Math.sin(Math.toRadians(342))),
                    new FloatPoint(0.5f + 0.5f*(float)Math.cos(Math.toRadians(18)), 0.5f + 0.5f*(float)Math.sin(Math.toRadians(18))),
                    new FloatPoint(0.5f + 0.25f*(float)Math.cos(Math.toRadians(54)), 0.5f + 0.25f*(float)Math.sin(Math.toRadians(54))),
                    new FloatPoint(0.5f + 0.5f*(float)Math.cos(Math.toRadians(90)), 0.5f + 0.5f*(float)Math.sin(Math.toRadians(90))),
            };

            item.setPoints(starPoints);
        }
            break;
    }
}
```

### Customizing the palette

#### Adding a entire palette
To add a completely new custom palette, create an array of colors and pass it into the toolbar object.

```java
int[] colors = {
        Color.BLUE,
        Color.RED,
        Color.GREEN,
        Color.parseColor("#FF8C00"),  // Orange
        Color.parseColor("#FFD700"),  // Yellow
        Color.parseColor("#4B0082")   // Purple
};

mToolbar.setColorChoices(colors);
```

#### Adding a color to the existing palette

To add a new color to the existing palette, pass the <var>int</var> value for the color into the toolbar object.

```java
mToolbar.addColorChoice(Color.parseColor("#008080")); /* Teal */
```

Cross-platform compatibility notes
----------------

To ensure that annotations don't get cut off across devices, we recommend:

* Using predefined aspect ratios for your video frames. 
* Using the same aspect ratio across device platforms.

The following Java code illustrates how to accomplish this for an Android app.

**Subscriber view**
```java
RelativeLayout.LayoutParams layoutParams = new RelativeLayout.LayoutParams(width, height);
mSubscriberViewContainer.addView(mSubscriber.getView(), layoutParams);
```
**Publisher view**
```java
RelativeLayout.LayoutParams layoutParams = new RelativeLayout.LayoutParams(scale*width, scale*height);
mPublisherViewContainer.addView(mPublisher.getView(), layoutParams);
```
See the [iOS](https://github.com/opentok/annotation-widget/tree/ios#cross-platform-compatibility-notes) and [JavaScript](https://github.com/opentok/annotation-widget/tree/js#cross-platform-compatibility-notes) Annotations widget repos for code samples specific to these platforms.

