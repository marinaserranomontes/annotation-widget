OpenTok Annotations
==================

Plugin to add annotation support to OpenTok.

Installation
-----

Add [opentok-annotations.js]() to your source.

Using the plugin
-----

Link the active OpenTok session to the annotation toolbar and add it to a parent container

```javascript
toolbar = new OTSolution.Annotations.Toolbar({
    session: session,
    container: document.getElementById('toolbar')
});
```

When the publisher is created, attach the annotation canvas and link it to the toolbar

```javascript
var canvas = new OTSolution.Annotations({
    session:  publisher.session,
    container: parentDiv
});
toolbar.addCanvas(canvas);
```

When new streams are created, you can attach the annotation canvases to each subscriber using the same code as above:

```javascript
var subscriber = session.subscribe(stream, subscriberDiv.id);

...

var canvas = new OTSolution.Annotations({
    feed:  subscriber,
    container: subscriberDiv
});
toolbar.addCanvas(canvas);
```

Customization
-----

#### Adding menu items

```javascript
toolbar = new OTSolution.Annotations.Toolbar({
    ...
    items: [
        {
            id: 'OT_pen',
            title: 'Pen',
            icon: '../img/freehand.png',
            selectedIcon: '../img/freehand.png'
        },
        {
            id: 'OT_line',
            title: 'Line',
            icon: '../img/line.png'
        },
        {
            id: 'OT_shapes',
            title: 'Shapes',
            icon: '../img/shapes.png',
            items: [
                {
                    id: 'OT_arrow',
                    title: 'Arrow',
                    icon: '../img/arrow.png'
                },
                {
                    id: 'OT_rect',
                    title: 'Rectangle',
                    icon: '../img/rectangle.png'
                },
                {
                    id: 'OT_oval',
                    title: 'Oval',
                    icon: '../img/oval.png'
                },
                {
                    id: 'custom_star',
                    title: 'Star',
                    icon: '../img/star.png',
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
            icon: '../img/line_width.png',
            items: { /* Built dynamically */ }
        },
        {
            id: 'OT_clear',
            title: 'Clear',
            icon: '../img/clear.png'
        },
        {
            id: 'OT_capture',
            title: 'Capture',
            icon: '../img/camera.png'
        }
    ]
});
```

##### Default menu items

Below is a list of default menu items that can be used in your custom menu. These come pre-built with the action specified. 
If no custom items are added to the toolbar initializer, these will be automatically added to your toolbar.

| id            | Action        |
| ------------- | ------------- |
| OT_pen | Freehand/Pen tool |
| OT_line | Line tool |
| OT_shapes | Shapes group/submenu |
| OT_arrow | Arrow tool |
| OT_rect | Rectangle tool |
| OT_oval | Oval tool |
| OT_colors | Color picker submenu |
| OT_line_width | Line width picker submenu |
| OT_clear | Clears active user annotations |
| OT_capture | Tap a video frame to capture a screenshot |

#### Adding a custom color palette

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

#### Handling menu click events

```javascript
toolbar.itemClicked(function (id) {
    // Handle the event
});
```

#### Cleaning up

To remove a single annotation canvas, call the following:

```javascript
toolbar.removeCanvas(canvasId); 
```

For example, canvasId = publisher.stream.connection.connectionId

`Note: This is not the ID of the canvas element`

To remove all annotation canvases and the annotation toolbar, call:

```javascript
toolbar.remove();
```

See [demo.html](sample/demo.html)
