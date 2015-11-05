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

1. Add `pod 'OpenTokAnnotations', :git => 'https://github.com/opentok/annotation-component-ios.git'` to your podfile.
2. Run `pod install` from your Terminal or using an Xcode plugin.

### Manually add the framework

1. Download the latest OpenTok Annotation [framework file](https://github.com/opentok/annotation-component-ios/releases) and unzip it.
2. Click your project name in the Project Navigator sidebar.
3. Choose the General tab.
4. Expand the Embedded Binaries section.
5. Click the '+' sign to add a framework.
6. Select 'Add Other...' from the popup and navigate to folder you unzipped in step 1.
7. Check "Copy items if needed" and click Finish.
8. Click on 'OpenTokAnnotations.framework' in the Project navigator window and ensure that your application is checked and set to 'required' under Target Membership in File inspector.

Using the plugin
----------------

For a quick start, download the [OpenTok iOS samples](https://github.com/opentok/opentok-ios-sdk-samples). If you already have your own project to work with,
the steps below should help you incorporate the annotations plugin.

Open `Main.storyboard` and drag a `UIView` component into the main view. With the view selected, click on the 'Identity inspector' tab (part of Utilities) and change the class to 'OTAnnotationToolbar'. You should see the view update to the default toolbar layout. 

![image](https://raw.githubusercontent.com/opentok/annotation-component-ios/master/Images/set_custom_class.png)

To use the toolbar in your code, add the following line to your `ViewController.m` file and link the OpenTok toolbar you just created in Interface Builder:

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

#### Capturing frames

Frames and their annotations can be captured when using the 'ot_capture' bar button item. The `UIImage` for these captures can be handled using the following callback from the `OTScreenCaptureDelegate`:

```objective-c
-(void)didCaptureImage:(UIImage *)image forConnection:(NSString *)connectionId {
    // Do something with the image
}
```

Don't forget to add `<OTScreenCaptureDelegate>` to your view controller's .h file and call `_toolbar.screenCaptureDelegate = self;` in your view controller's .m file.

Customizing the toolbar
----------------

#### Adding/removing menu items

To create menu items dynamically, you will need to create a new `UIToolbar` instance and hook it up as the `mainToolbar` outlet in your `OTAnnotationToolbar` instance (`_toolbar.mainToolbar = someToolbar`). Toolbar `UIBarButtonItem`s can then be added using the `items` property:

```objective-c
someToolbar.items = arrayOfItems;
```

See [Add menu items using Interface Builder](#ib-menu) to create static menu items through the visual interface.

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

#### <a name="ib-menu"></a>Add menu items using Interface Builder

OTAnnotations provides Interface Builder support to add custom toolbars and button items. 

##### Link a main toolbar
![image](https://raw.githubusercontent.com/opentok/annotation-component-ios/master/Images/link_main_toolbar.gif)

##### Link a sub toolbar to an `OTAnnotationButtonItem`
![image](https://raw.githubusercontent.com/opentok/annotation-component-ios/master/Images/link_sub_toolbar.gif)

#### Handling custom items

Custom added toolbar items will fire the `didTapItem` callback if the `OTAnnotationToolbarDelegate` is configured in your view controller. Add `<OTAnnotationToolbarDelegate>` to your ViewController.h file and be sure to set `_toolbar.delegate = self;`. Then, add the method below to your view controller implementation file:

```objective-c
-(void)didTapItem:(UIBarButtonItem *)item {
    if ([item isKindOfClass:OTAnnotationButtonItem.class]) {
        NSArray* star = [NSArray arrayWithObjects:
            [NSValue valueWithCGPoint: CGPointMake(0.5f + 0.5f*cos(degreesToRadians(90)), 0.5f + 0.5f*sin(degreesToRadians(90)))],
            [NSValue valueWithCGPoint: CGPointMake(0.5f + 0.25f*cos(degreesToRadians(126)), 0.5f + 0.25f*sin(degreesToRadians(126)))],
            [NSValue valueWithCGPoint: CGPointMake(0.5f + 0.5f*cos(degreesToRadians(162)), 0.5f + 0.5f*sin(degreesToRadians(162)))],
            [NSValue valueWithCGPoint: CGPointMake(0.5f + 0.25f*cos(degreesToRadians(198)), 0.5f + 0.25f*sin(degreesToRadians(198)))],
            [NSValue valueWithCGPoint: CGPointMake(0.5f + 0.5f*cos(degreesToRadians(234)), 0.5f + 0.5f*sin(degreesToRadians(234)))],
            [NSValue valueWithCGPoint: CGPointMake(0.5f + 0.25f*cos(degreesToRadians(270)), 0.5f + 0.25f*sin(degreesToRadians(270)))],
            [NSValue valueWithCGPoint: CGPointMake(0.5f + 0.5f*cos(degreesToRadians(306)), 0.5f + 0.5f*sin(degreesToRadians(306)))],
            [NSValue valueWithCGPoint: CGPointMake(0.5f + 0.25f*cos(degreesToRadians(342)), 0.5f + 0.25f*sin(degreesToRadians(342)))],
            [NSValue valueWithCGPoint: CGPointMake(0.5f + 0.5f*cos(degreesToRadians(18)), 0.5f + 0.5f*sin(degreesToRadians(18)))],
            [NSValue valueWithCGPoint: CGPointMake(0.5f + 0.25f*cos(degreesToRadians(54)), 0.5f + 0.25f*sin(degreesToRadians(54)))],
            [NSValue valueWithCGPoint: CGPointMake(0.5f + 0.5f*cos(degreesToRadians(90)), 0.5f + 0.5f*sin(degreesToRadians(90)))], nil];

        // Add points to custom action items
        if ([((OTAnnotationButtonItem*) item).identifier isEqualToString:@"custom_star"]) {
            [(OTAnnotationButtonItem*) item setPoints:star];
        }
    }
}
```

The example above tests for an `OTAnnotationButtonItem`, which allows a set of points to be defined as the action and will draw the result of those points on the screen as the user interacts with it.

#### Custom colors

To add a new color palette to be used with annotations, call `setColors:` on the toolbar instance.

```objective-c
NSArray* colors = [NSArray arrayWithObjects:
    [UIColor blueColor],
    [UIColor redColor],
    [UIColor greenColor],
    [UIColor orangeColor],
    [UIColor yellowColor],
    [UIColor purpleColor],
    [UIColor brownColor],
    nil];

[_toolbar setColors:colors];
```

To add a new color to the existing palette, call `addColor:` on the toolbar instance.

```objective-c
[_toolbar addColor:[UIColor cyanColor]];
```

For best results
----------------

In order to ensure that all annotations aren't cut off across devices, it is recommended to use predefined
aspect ratios for your video frames. It's a good idea to use the same aspect ratio across device platforms
(see how to set the aspect ratio for [Android](https://github.com/opentok/annotation-component-android#for-best-results) and [JavaScript](https://github.com/opentok/annotation-component-web#for-best-results)).

```objective-c
...

[_subscriber.view setFrame:CGRectMake(x, y, width, height)];

...

[_publisher.view setFrame:CGRectMake(x, y, scale*width, scale*height)];
```
