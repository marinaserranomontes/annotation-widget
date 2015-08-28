/*!
 *  Annotation Plugin for OpenTok
 *
 *  @Author: Trevor Boyer
 *  @Copyright (c) 2015 TokBox, Inc
 **/

// https://facadejs.com/
// https://github.com/facadejs/Facade.js

// loggingURL: 'http://hlg.tokbox.com/prod' -- Use this for logging??

//--------------------------------------
//  OPENTOK ANNOTATION CANVAS/VIEW
//--------------------------------------

OT.Annotations = function(options) {
    options || (options = {});
//    console.log(options);

    this.parent = options.container;
    // canvasSession differs from the session - this allows us to grab publisher.connection.connectionId
    this.canvasSession = options.session;

    if (this.parent) {
        var canvas = document.createElement("canvas");
        canvas.setAttribute('id', 'opentok_canvas'); // session.connection.id?
        canvas.style.position = 'absolute';
        this.parent.appendChild(canvas);
        canvas.setAttribute('width', this.parent.clientWidth + 'px');
        canvas.style.width = this.parent.clientWidth + 'px';
        canvas.setAttribute('height', this.parent.clientHeight + 'px');
        canvas.style.height = this.parent.clientHeight + 'px';
    }

    var self = this,
        ctx,
        colors,
        lineWidth,
        mirrored,
        batchUpdates = [],
        drawHistory = [],
        drawHistoryReceivedFrom,
        client = {dragging: false};

// OT.Annotations.Shape

    var star = [
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
    ];

    var arrow = [
        [0, 1],
        [3, 1],
        [3, 0],
        [5, 2],
        [3, 4],
        [3, 3],
        [0, 3],
        [0, 1] // Reconnect point
    ];

    var rect = [
        [0, 0],
        [1, 0],
        [1, 1],
        [0, 1],
        [0, 0] // Reconnect point
    ];

    this.canvas = function() {
        return canvas;
    };

    this.link = function(session) {
        this.session = session;
    };

    this.changeColor = function (color) {
        console.log(color);
        this.userColor = color;
        if (!this.lineWidth) {
            this.lineWidth = 2;
        }
    };

    this.changeLineWidth = function (size) {
        this.lineWidth = size;
    };

    this.colors = function (colors) {
        this.colors = colors;
        this.changeColor(colors[0]);
    };

    this.clear = function () {
        clearCanvas();
        if (session) {
            session.signal({
                type: 'otAnnotation_clear'
            });
        }
    };

    /** Canvas Handling **/

    addEventListeners(canvas, 'mousedown mousemove mouseup mouseout touchstart touchmove touchend', function (event) {
//        console.log(event);
        if (event.type === 'mousemove' && !client.dragging) {
            // Ignore mouse move Events if we're not dragging
            return;
        }
        event.preventDefault();

        var scaleX = canvas.width / self.parent.clientWidth,
            scaleY = canvas.height / self.parent.clientHeight,
            offsetX = event.offsetX || event.pageX - canvas.offsetLeft ||
                event.changedTouches[0].pageX - canvas.offsetLeft,
            offsetY = event.offsetY || event.pageY - canvas.offsetTop ||
                event.changedTouches[0].pageY - canvas.offsetTop,
            x = offsetX * scaleX,
            y = offsetY * scaleY;

//        console.log("Offset X: " + offsetX + ", Offset Y: " + offsetY);
//        console.log("x: " + x + ", y: " + y);

        console.log(self.userColor);

        switch (event.type) {
            case 'mousedown':
            case 'touchstart':
                client.dragging = true;
                client.lastX = x;
                client.lastY = y;
                break;
            case 'mousemove':
            case 'touchmove':
                if (client.dragging) {
                    var update = {
                        id: session.connection.connectionId,
                        fromId: self.session ? self.session.connection.connectionId : '',
                        fromX: client.lastX,
                        fromY: client.lastY,
                        toX: x,
                        toY: y,
                        color: self.userColor,
                        lineWidth: self.lineWidth,
                        canvasWidth: canvas.clientWidth,
                        canvasHeight: canvas.clientHeight,
                        mirrored: mirrored
                    };
                    draw(update);
                    client.lastX = x;
                    client.lastY = y;
                    sendUpdate(update);
                }
                break;
            case 'mouseup':
            case 'touchend':
            case 'mouseout':
                client.dragging = false;
        }
    });

    function addEventListeners(el, s, fn) {
        var evts = s.split(' ');
        for (var i = 0, iLen = evts.length; i < iLen; i++) {
            el.addEventListener(evts[i], fn, true);
        }
    }

    var draw = function (update) {
        if (!ctx) {
            ctx = canvas.getContext("2d");
            ctx.lineCap = "round";
            ctx.fillStyle = "solid";
        }

        ctx.strokeStyle = update.color;
        ctx.lineWidth = update.lineWidth;
        ctx.beginPath();
        ctx.moveTo(update.fromX, update.fromY);
        ctx.lineTo(update.toX, update.toY);
        ctx.stroke();
        ctx.closePath();

        drawHistory.push(update);
    };

    var drawUpdates = function (updates) {
        updates.forEach(function (update) {
            draw(update);
        });
    };

    var clearCanvas = function () {
        ctx.save();

        // Use the identity matrix while clearing the canvas
        ctx.setTransform(1, 0, 0, 1, 0, 0);
        ctx.clearRect(0, 0, canvas.clientWidth, canvas.clientWidth);

        // Restore the transform
        ctx.restore();
        drawHistory = [];
    };

    /** Signal Handling **/

    if (this.session) {
        this.session.on({
            'signal:otAnnotation_pen': function (event) {
                if (event.from.connectionId !== self.session.connection.connectionId) {
                    drawUpdates(JSON.parse(event.data));
                    scope.$emit('otWhiteboardUpdate');
                }
            },
            'signal:otAnnotation_text': function (event) {
                if (event.from.connectionId !== self.session.connection.connectionId) {
                    drawText(JSON.parse(event.data));
                    scope.$emit('otWhiteboardUpdate');
                }
            },
            'signal:otWhiteboard_history': function (event) {
                // We will receive these from everyone in the room, only listen to the first
                // person. Also the data is chunked together so we need all of that person's
                if (!drawHistoryReceivedFrom || drawHistoryReceivedFrom === event.from.connectionId) {
                    drawHistoryReceivedFrom = event.from.connectionId;
                    drawUpdates(JSON.parse(event.data));
                    scope.$emit('otWhiteboardUpdate');
                }
            },
            'signal:otAnnotation_clear': function (event) {
                if (event.from.connectionId !== OTSession.session.connection.connectionId) {
                    clearCanvas();
                }
            },
            connectionCreated: function (event) {
                if (drawHistory.length > 0 && event.connection.connectionId !==
                    self.session.connection.connectionId) {
                    batchSignal('otWhiteboard_history', drawHistory, event.connection);
                }
            }
        });
    }

    var batchSignal = function (type, data, toConnection) {
        // We send data in small chunks so that they fit in a signal
        // Each packet is maximum ~250 chars, we can fit 8192/250 ~= 32 updates per signal
        var dataCopy = data.slice(), self = this;
        var signalError = function (err) {
            if (err) {
                TB.error(err);
            }
        };
        while (dataCopy.length) {
            var dataChunk = dataCopy.splice(0, Math.min(dataCopy.length, 32));
            var signal = {
                type: type,
                data: JSON.stringify(dataChunk)
            };
            if (toConnection) signal.to = toConnection;
            self.session.signal(signal, signalError);
        }
    };

    var updateTimeout;
    var sendUpdate = function (update) {
        if (self.session) {
            batchUpdates.push(update);
            if (!updateTimeout) {
                updateTimeout = setTimeout(function () {
                    batchSignal('otAnnotation_update', batchUpdates);
                    batchUpdates = [];
                    updateTimeout = null;
                }, 100);
            }
        }
    };
};

//--------------------------------------
//  OPENTOK ANNOTATION TOOLBAR
//--------------------------------------

OT.Annotations.Toolbar = function(options) {
    options || (options = {});
//    console.log(options);

    this.session = options.session;
    this.parent = options.container;
    // TODO Allow 'style' objects to be passed in for buttons, menu toolbar, etc?
    this.backgroundColor = options.backgroundColor || 'rgba(0, 0, 0, 0.7)';
    this.buttonWidth = options.buttonWidth || '40px';
    this.buttonHeight = options.buttonHeight || '40px';
    this.iconWidth = options.iconWidth || '30px';
    this.iconHeight = options.iconHeight || '30px';
    this.items = options.items || [
        {
            title: 'Pen',
            icon: '../img/freehand.png', // FIXME All of these need to be relative to where the script is located or a full url
            selectedIcon: '../img/freehand.png' // TODO Create an icon for selected states
        },
        {
            title: 'Line',
            icon: '../img/line.png'
        },
        {
            title: 'Shapes',
            icon: '../img/shapes.png',
            items: [
                {
                    title: 'Arrow',
                    icon: '../img/arrow.png'
                },
                {
                    title: 'Rectangle',
                    icon: '../img/rectangle.png'
                },
                {
                    title: 'Oval',
                    icon: '../img/oval.png'
                }
            ]
        },
        {
            title: 'Colors',
            icon: '',
            items: { /* Built dynamically */ }
        },
        {
            title: 'Line Width',
            icon: '../img/line_width.png',
            items: { /* Built dynamically */ }
        },
        {
            title: 'Clear',
            icon: '../img/clear.png'
        },
        {
            title: 'Capture',
            icon: '../img/camera.png'
        }
    ];
    this.colors = options.colors || [
        '#000000',  // Black
        '#0000FF',  // Blue
        '#FF0000',  // Red
        '#00FF00',  // Green
        '#FF8C00',  // Orange
        '#FFD700',  // Yellow
        '#4B0082',  // Purple
        '#800000'   // Brown
    ];

    var canvases = [];

    /**
     * Creates a sub-menu with a color picker.
     *
     * @param {String|Element} parent The parent div container for the color picker sub-menu.
     * @param {Array} colors The array of colors to add to the palette.
     * @param {Object} options options An object containing the following fields:
     *
     *  - `openEvent` (String): The open event (default: `"click"`).
     *  - `style` (Object): Some style options:
     *    - `display` (String): The display value when the picker is opened (default: `"block"`).
     *  - `template` (String): The color item template. The `{color}` snippet will be replaced
     *    with the color value (default: `"<div data-col=\"{color}\" style=\"background-color: {color}\"></div>"`).
     *  - `autoclose` (Boolean): If `false`, the color picker will not be hided by default (default: `true`).
     *
     * @constructor
     */
    var ColorPicker = function(parent, colors, options) {
        var self = this;

        this.getElm = function (el) {
            if (typeof el === "string") {
                return document.querySelector(el);
            }
            return el;
        };

        this.render = function () {
            var self = this,
                html = "";

            self.colors.forEach(function (c) {
                html += self.options.template.replace(/\{color\}/g, c);
            });

            self.elm.innerHTML = html;
        };

        this.close = function () {
            this.elm.style.display = "none";
        };

        this.open = function () {
            this.elm.style.display = this.options.style.display;
        };

        this.colorChosen = function (cb) {
            this.cbs.push(cb);
        };

         this.set = function (c, p) {
            var self = this;
            self.color = c;
            if (p === false) {
                return;
            }
            self.cbs.forEach(function (cb) {
                cb.call(self, c);
            });
        };

        options = options || {};
        options.openEvent = options.openEvent || "click";
        options.style = Object(options.style);
        options.style.display = options.style.display || "block";
        options.template = options.template || "<div data-col=\"{color}\" style=\"background-color: {color}\"></div>";
        self.elm = self.getElm(parent);
        self.cbs = [];
        self.colors = colors;
        self.options = options;
        self.render();

        // Click on colors
        self.elm.addEventListener("click", function (ev) {
            var col = ev.target.getAttribute("data-col");
            if (!col) {
                return;
            }
            self.set(col);
            self.close();
        });

        if (options.autoclose !== false) {
            self.close();
        }
    };

    if (this.parent) {
        var panel = document.createElement("div");
        panel.setAttribute('id', 'opentok_toolbar');
        panel.setAttribute('class', 'OT_panel');
        panel.style.width = '100%';
        panel.style.height = '100%';
        panel.style.backgroundColor = this.backgroundColor;
        panel.style.paddingLeft = '15px';
        this.parent.appendChild(panel);
        this.parent.style.position = 'relative';
        this.parent.zIndex = 1000;

        var toolbarItems = [];

        console.log(this.items);

        for (var i = 0, total = this.items.length; i < total; i++) {
            var item = this.items[i];

            var button = document.createElement("input");
            button.setAttribute('type', 'button');
            button.setAttribute('id', 'OT-Annotation-' + item.title.replace(" ", "-"));

            if (item.title === 'Colors') {
                var colorPicker = document.createElement("div");
                colorPicker.setAttribute('class', 'color-picker');
                colorPicker.style.backgroundColor = this.backgroundColor;
                this.parent.appendChild(colorPicker);

                var pk = new ColorPicker(".color-picker", this.colors, null);

                pk.colorChosen(function (color) {
//                    console.log('Picked color: ' + color);
                    var colorGroup = document.getElementById('OT-Annotation-Colors');
                    colorGroup.style.backgroundColor = color;

                    console.log(canvases);
                    canvases.forEach(function (canvas) {
                        canvas.changeColor(color);
                    });
                });

                button.setAttribute('class', 'OT_color');
                button.style.marginLeft = '10px';
                button.style.marginRight = '10px';
                button.style.transform = 'translateY(20%)'; // TODO Need a better way to center this vertically
                button.style.borderRadius = '50%';
                button.style.backgroundColor = this.colors[0];
                button.style.width = this.iconWidth;
                button.style.height = this.iconHeight;
            } else {
                button.style.background = 'url("' + item.icon + '") no-repeat';
                button.style.transform = 'translateY(25%)';
                button.style.backgroundSize = this.iconWidth + ' ' + this.iconHeight;
                button.style.width = this.buttonWidth;
                button.style.height = this.buttonHeight;
            }

            button.style.border = 'none';
            button.style.cursor = 'pointer';

            if (item.items) {
                // TODO We have a group - build a submenu
            }

            toolbarItems.push(button.outerHTML);
        }

        panel.innerHTML = toolbarItems.join('');

        // TODO Attach remaining click listeners
        document.getElementById('OT-Annotation-Colors').onclick = function() {
            pk.open();
        };

        document.getElementById('OT-Annotation-Clear').onclick = function() {
            canvases.forEach(function (canvas) {
                console.log('Clearing canvas');
                canvas.clear();
            });
        };
    }

    this.addCanvas = function(canvas) {
        console.log("Adding canvas " + canvas);
        var self = this;
        canvas.link(session);
        canvas.colors(self.colors);
        canvases.push(canvas);
    };

    this.removeCanvas = function(connectionId) {
        canvases.forEach(function (annotationView) {
            var canvas = annotationView.canvas();
            console.log(canvas);
            if (annotationView.canvasSession.connection.connectionId === connectionId) {
                // FIXME Make sure sub-menus are removed, too - ensure they are added back in the right order (sub-menu currently shows up on top in second run)
                canvas.parentNode.removeChild(canvas);
            }
        });

        canvases = canvases.filter(function (annotationView) {
            return annotationView.canvasSession.connection.connectionId !== connectionId;
        });
    };

    this.remove = function() {
        panel.parentNode.removeChild(panel);
    };
};