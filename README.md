OpenTok Annotations
==================

Plugin to add annotation support to OpenTok.

Installation
-----
You can either use Bower:

`bower install opentok-annotations`

or clone this repo.

Using the plugin
-----

Link the active OpenTok session to the annotation toolbar

```javascript
toolbar = OT.Annotations.Toolbar(session);
```

When the publisher is created, attach the annotation canvas and link it to the toolbar

```javascript
var canvas = OT.Annotations(parentDiv, publisher.session);
toolbar.add(canvas);
```

...

See [demo.html](sample/demo.html)

Build
-------
```
npm install
bower install
gulp
```
