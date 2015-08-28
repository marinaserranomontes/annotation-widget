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
toolbar = new OT.Annotations.Toolbar({
    session: session,
    container: document.getElementById('toolbar'),
    colors: palette
});
```

When the publisher is created, attach the annotation canvas and link it to the toolbar

```javascript
var canvas = new OT.Annotations({
    session:  publisher.session,
    container: parentDiv
});
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
