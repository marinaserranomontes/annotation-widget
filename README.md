OpenTok iOS Annotations Plugin
===========================

This plugin adds annotation and screen capture capabilities to OpenTok for iOS.

Notes
-----

* See [OpenTok iOS SDK developer and client requirements](https://tokbox.com/developer/sdks/ios/#system-requirements) for a list of system requirements and supported devices.

* See the [OpenTok iOS SDK Reference](https://tokbox.com/developer/sdks/ios/reference/index.html)
for details on the API.

Installing
----------

### CocoaPods

1. Add `pod 'OpenTokAnnotations'` to your podfile.
2. Run `pod install` from your Terminal or using an Xcode plugin.

### Manually add the framework

1. Download the OpenTok Annotation [framework files]() and unzip it.
2. Click your project name in the Project Navigator sidebar.
3. Choose the Build Phases tab.
4. Expand the Link Binary With Libraries section.
5. Click the '+' sign to add a framework.
6. Select 'Add Other...' from the popup and navigate to folder you unzipped in step 1.

Using the plugin
----------------

For a quick start, download the [OpenTok iOS samples](https://github.com/opentok/opentok-ios-sdk-samples). If you already have your own project to work with,
the steps below should help you incorporate the annotations plugin.

Open `Main.storyboard` and drag a `UIView` component into the main view. With the view selected, click on the 'Identity inspector' tab (part of Utilities) and change the class to 'OTAnnotationToolbar'. You should see the view update to the default toolbar layout. To use the toolbar in your code, add the following line to your `ViewController.m` file and link the OpenTok toolbar you just created in Interface Builder:

![image]()

```objective-c
@implementation ViewController {
    ...

    IBOutlet OTAnnotationToolbar* _toolbar;

    ...
}
```

Create a new `OTAnnotationView` instance in the `doPublish` method (called by the `sessionDidConnect:` method from the `OTSessionDelegate`) and link it to the toolbar.

```objective-c
- (void)doPublish
{
    ...

    OTAnnotationView* annotationView = [[OTAnnotationView alloc] initWithPublisher:_publisher];
    [_publisher.view addSubview:annotationView];

    [_toolbar attachAnnotationView: annotationView];
}
```

Similarly, an annotation view can be added to an incoming subscriber feed in the `subscriberDidConnectToStream:` method from the `OTSubscriberKitDelegate`.

```objective-c
- (void)subscriberDidConnectToStream:(OTSubscriberKit*)subscriber
{
    ...

    OTAnnotationView* annotationView = [[OTAnnotationView alloc] initWithSubscriber:_subscriber];
    [_subscriber.view.superview addSubview:annotationView];

    [_toolbar attachAnnotationView: annotationView];
}
```

Customizing the toolbar
----------------

#### Adding/removing menu items

To create menu items dynamically, you will need to create a new `UIToolbar` instance and hook it up as the `mainToolbar` outlet in your OTAnnotationToolbar instance (`_toolbar.mainToolbar = someToolbar`). Toolbar `UIBarButtonItem`s can then be added using the `items` property:

```objective-c
someToolbar.items = arrayOfItems;
```

See Add menu items using Interface Builder to create static menu items through the visual interface.

The `OTAnnotationButtonItem` class provides an `identifier` property that allows a string to be associated with the button for use on delegate callback (or you can use the `tag` property associated with all `UIView`s.

*Info: You may want to add* `[self.view bringSubviewToFront:_toolbar];` *to ensure the toolbar is always drawn on top of*

#### Defaults

Below is a list of default `OTAnnotationButtonItem` identifiers and their corresponding actions:

| id            | Action        |
| ------------- | ------------- |
| ot_pen | Freehand/Pen tool |
| ot_line | Line tool |
| ot_shape | Shapes group/submenu |
| ot_arrow | Arrow tool |
| ot_rectangle | Rectangle tool |
| ot_oval | Oval tool |
| ot_colors | Color picker submenu |
| ot_line_width | Line width picker submenu |
| ot_clear | Clears active user annotations |
| ot_capture | Tap a video frame to capture a screenshot |

#### Add menu items using Interface Builder

OTAnnotations provides Interface Builder support to add custom toolbars and button items. 

![image]()

![image]()

#### Handling custom items

#### Custom colors

For best results
----------------

In order to ensure that all annotations are visible across devices, it is recommended to use predefined
aspect ratios for your video frames.

[code sample]