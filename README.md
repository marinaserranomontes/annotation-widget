OpenTok Annotations Widget for JavaScript -- Beta
==================

While TokBox hosts [OpenTok.js](https://tokbox.com/developer/sdks/js/), you must host the JavaScript Annotations widget yourself. This allows you to modify the widget as desired. 

* **[opentok-annotations.js](https://github.com/opentok/annotation-widget/tree/js/web/script)**: includes the CSS. If you already have a website that's making calls against the OpenTok JavaScript client, you can just grab this file and the image files.

* **[Image files](https://github.com/opentok/annotation-widget/tree/js/web/image)**: used for the toolbar icons. 

* **[index.html](https://github.com/opentok/annotation-widget/blob/js/web/index.html)**: this web page provides you with a quick start if you don't already have a web page that's making calls against OpenTok.js. You can also look at this file to see how to implement the toolbar in your own page.

As a beta, this code is subject to change. You can email feedback to collaboration-tools-beta-program@tokbox.com.

Requirements
-----

Review the basic requirements for [OpenTok](https://tokbox.com/developer/requirements/) and [OpenTok.js](https://tokbox.com/developer/sdks/js/#browsers).


Prerequisites
-----

* **OpenTok JavaScript client SDK**: your web page must load [OpenTok.js](https://tokbox.com/developer/sdks/js/) first, then [opentok-annotations.js](https://github.com/opentok/annotation-widg
et/tree/js/web/script).  

* **An API key**: obtained when you sign up for a [developer account](https://dashboard.tokbox.com/users/sign_up).

* **Session ID and token**: during testing and development phases, you can generate these manually inside the [Dashboard](https://dashboard.tokbox.com/). Before going live, you will need to deploy a [server SDK](https://tokbox.com/developer/sdks/server/) and generate these values dynamically.


Downloading the widget
-----

[Download](https://github.com/opentok/annotation-widget/releases/tag/1.0.0-js-beta) the latest release.

**PRO TIP**: Pull requests are welcome! If you think you may want to contribute back to this project, please feel free to fork or clone the repo. 


Deploying the widget
-----

The web page that loads the Annotations Widget for JavaScript must be served over HTTP/HTTPS. Browser security limitations prevent you from publishing video using a `file://` path, as discussed in the OpenTok.js [Release Notes](https://www.tokbox.com/developer/sdks/js/release-notes.html#knownIssues). To support clients running [Chrome 47 or later](https://groups.google.com/forum/#!topic/discuss-webrtc/sq5CVmY69sc), HTTPS is required. A web server such as [MAMP](https://www.mamp.info/) or [Apache](https://httpd.apache.org/) will work, or else you can use a cloud service such as [Heroku](https://www.heroku.com/) to host the widget. Click the following button for a very quick deploy to Heroku.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/opentok/annotation-widget/tree/js)

Using the widget
-----

###Linking and adding the toolbar
Link the active OpenTok session to the annotation toolbar and add the toolbar to a parent container.

```javascript
toolbar = new OTSolution.Annotations.Toolbar({
    session: session,
    container: document.getElementById('toolbar')
});
```

### Attaching the toolbar to a publisher
When the publisher is created, attach the annotation canvas and link it to the toolbar.

```javascript
var canvas = new OTSolution.Annotations({
    feed: publisher,
    container: publisherDiv
});
toolbar.addCanvas(canvas);
```

### Attaching the toolbar to a subscriber
When new streams are created, you can attach the annotation canvases to each subscriber.

```javascript
var subscriber = session.subscribe(stream, subscriberDiv.id);

...

var canvas = new OTSolution.Annotations({
    feed:  subscriber,
    container: subscriberDiv
});
toolbar.addCanvas(canvas);
```

### Cleaning up

To remove a single annotation canvas, call the following:

```javascript
toolbar.removeCanvas(canvasId);
```

For example, `canvasId = publisher.stream.connection.connectionId`

**Note**: `canvasId` is not the ID of the canvas element.

To remove all annotation canvases and the annotation toolbar, call `remove`.

```javascript
toolbar.remove();
```



Customizing the toolbar
-----

### Default menu items

Below is a list of default menu items that can be used in your custom menu. These come pre-built with the action specified.
If no custom items are added to the toolbar initializer, these will be automatically added to your toolbar.

| id            | Action        |
| :------------ | :------------- |
| `OT_pen` | Freehand/Pen tool |
| `OT_line` | Line tool |
| `OT_shapes` | Shapes group/submenu |
| `OT_arrow` | Arrow tool |
| `OT_rect` | Rectangle tool |
| `OT_oval` | Oval tool |
| `OT_colors` | Color picker submenu |
| `OT_line_width` | Line width picker submenu |
| `OT_clear` | Clears active user annotations |
| `OT_capture` | Tap a video frame to capture a screenshot |


### Adding menu items

```javascript
toolbar = new OTSolution.Annotations.Toolbar({
    ...
    items: [
        {
            id: 'OT_pen',
            title: 'Pen',
            icon: 'image/freehand.png',
            selectedIcon: 'image/freehand_selected.png'
        },
        {
            id: 'OT_line',
            title: 'Line',
            icon: 'image/line.png'
        },
        {
            id: 'OT_shapes',
            title: 'Shapes',
            icon: 'image/shapes.png',
            items: [
                {
                    id: 'OT_arrow',
                    title: 'Arrow',
                    icon: 'image/arrow.png'
                },
                {
                    id: 'OT_rect',
                    title: 'Rectangle',
                    icon: 'image/rectangle.png'
                },
                {
                    id: 'OT_oval',
                    title: 'Oval',
                    icon: 'image/oval.png'
                },
                {
                    id: 'custom_star',
                    title: 'Star',
                    icon: 'image/star.png',
                    // points specify the base points that define a shape or object that can be drawn through the annotations
                    points: [
                        [0.5 + 0.5 * Math.cos(90 * (Math.PI / 180)), 0.5 + 0.5 * Math.sin(90 * (Math.PI / 180))],
                        [0.5 + 0.25 * Math.cos(126 * (Math.PI / 180)), 0.5 + 0.25 * Math.sin(126 * (Math.PI / 180))],
                        [0.5 + 0.5 * Math.cos(162 * (Math.PI / 180)), 0.5 + 0.5 * Math.sin(162 * (Math.PI / 180))],
                        [0.5 + 0.25 * Math.cos(198 * (Math.PI / 180)), 0.5 + 0.25 * Math.sin(198 * (Math.PI / 180))],
                        [0.5 + 0.5 * Math.cos(234 * (Math.PI / 180)), 0.5 + 0.5 * Math.sin(234 * (Math.PI / 180))],
                        [0.5 + 0.25 * Math.cos(270 * (Math.PI / 180)), 0.5 + 0.25 * Math.sin(270 * (Math.PI / 180))],
                        [0.5 + 0.5 * Math.cos(306 * (Math.PI / 180)), 0.5 + 0.5 * Math.sin(306 * (Math.PI / 180))],
                        [0.5 + 0.25 * Math.cos(342 * (Math.PI / 180)), 0.5 + 0.25 * Math.sin(342 * (Math.PI / 180))],
                        [0.5 + 0.5 * Math.cos(18 * (Math.PI / 180)), 0.5 + 0.5 * Math.sin(18 * (Math.PI / 180))],
                        [0.5 + 0.25 * Math.cos(54 * (Math.PI / 180)), 0.5 + 0.25 * Math.sin(54 * (Math.PI / 180))],
                        [0.5 + 0.5 * Math.cos(90 * (Math.PI / 180)), 0.5 + 0.5 * Math.sin(90 * (Math.PI / 180))]
                    ]
                }
            ]
        },
        {
            id: 'OT_colors',
            title: 'Colors',
            items: { /* Built dynamically */ }
        },
        {
            id: 'OT_line_width',
            title: 'Line Width',
            icon: 'image/line_width.png',
            items: { /* Built dynamically */ }
        },
        {
            id: 'OT_clear',
            title: 'Clear',
            icon: 'image/clear.png'
        },
        {
            id: 'OT_capture',
            title: 'Capture',
            icon: 'image/camera.png'
        }
    ]
});
```


### Adding a custom color palette

A set of custom color choices can be added when the toolbar is initialized:

```javascript
toolbar = new OTSolution.Annotations.Toolbar({
    ...
    colors: [
        "#1abc9c",
        "#2ecc71",
        "#3498db",
        "#9b59b6",
        "#34495e",
        "#16a085"
    ]
});
```

### Handling menu click events


```javascript
toolbar.itemClicked(function (id) {
    // Handle the event
});
```


Annotations with screen sharing
----------------

For information on setting up your own screen sharing extension, see our sample on [Github](https://github.com/opentok/screensharing-extensions). Once you have
screen sharing set up, follow one of the recommended steps to install the extension on [Firefox](https://github.com/opentok/screensharing-extensions/tree/master/firefox/ScreenSharing#installing-your-extension) or [Chrome](https://github.com/opentok/screensharing-extensions/tree/master/chrome/ScreenSharing#packaging-and-deploying-your-extension-for-use-at-your-website).

Annotations are set up for screen sharing in a similar way as with a video publisher:

```javascript
var parentDiv = document.getElementById('screenshareContainer');
        var screenContainerElement = document.createElement('div');
        screenContainerElement.setAttribute('id', 'screenshare_publisher');
        parentDiv.appendChild(screenContainerElement);

        var screenSharingPublisher = OT.initPublisher(
                screenContainerElement.id,
                {
                    videoSource: 'screen', // Specify the source as screen share
                    width: window.innerWidth,
                    height: window.innerHeight
                },
                function (error) {
                    if (error) {
                        alert('Something went wrong: ' + error.message);
                    } else {
                        // Add the toolbar
                        var toolbarDiv = toolbar.parent; // Re-use existing toolbar (or you can add a new one here)
                        toolbarDiv.style.position = 'absolute';
                        toolbarDiv.style.top = '0px';

                        document.body.appendChild(toolbarDiv);

                        console.log(session);

                        session.publish(
                                screenSharingPublisher,
                                function (error) {
                                    if (error) {
                                        alert('Something went wrong: ' + error.message);
                                    }
                                });

                        var canvas = new OTSolution.Annotations({
                            feed: screenSharingPublisher,
                            container: screenContainerElement
                        });
                        toolbar.addCanvas(canvas);
                    }
                });
```

For best results, we recommend that a new window is opened for annotations with screen sharing. This allows annotations to be added to extents
beyond the browser window (on your desktop, for example). The code snippet below is used to create a new window that points to the URL of the
screen sharing with annotations sample ([screenshare.html](screenshare.html)) and height and width values for the new window.

```javascript
function popupCenter(url, w, h) {
    var left = (screen.width/2)-(w/2);
    var top = (screen.height/2)-(h/2);
    var win = window.open(url, '', 'toolbar=no, location=no, directories=no, status=no, menubar=no, scrollbars=no, resizable=no, copyhistory=no, width='+w+', height='+h+', top='+top+', left='+left);

    // Share the toolbar with the window to be re-used, otherwise you can create a new one in 'screenshare.html'
    win.toolbar = toolbar;
}
```

See the [OpenTok.js screen sharing documentation](https://tokbox.com/developer/guides/screen-sharing/js) for full details on working
with screen sharing.


Cross-platform compatibility notes
----------------

To ensure that all annotations aren't cut off across devices, we recommend:

* Using predefined aspect ratios for your video frames.
* Using the same aspect ratio across device platforms.

The following sample illustrates one way to do this in JavaScript.

```javascript
    function startPublishing() {
        if (!publisher) {
            var parentDiv = document.getElementById('myCamera');
            var publisherDiv = document.createElement('div'); // Create a div for the publisher to replace
            var publisherProperties = {
                name: 'A web-based OpenTok client',
                width: '360px',
                height: '480px'
            };
```

See the [iOS](https://github.com/opentok/annotation-widget/tree/ios#cross-platform-compatibility-notes) and [Android](https://github.com/opentok/annotation-widget/tree/android#cross-platform-compatibility-notes) branches for code samples specific to these platforms.
