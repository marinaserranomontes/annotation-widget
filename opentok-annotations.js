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
    this.videoFeed = options.feed;

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

    // INFO Mirrored canvases contain the OT_mirrored class
    mirrored = (' ' + self.videoFeed.element.className + ' ').indexOf(' ' + 'OT_mirrored' + ' ') > -1;

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

        var update;

        if (self.selectedItem.title === 'Pen') {
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
                        update = {
                            id: self.videoFeed.stream.connection.connectionId,
                            fromId: self.session.connection.connectionId,
                            fromX: client.lastX,
                            fromY: client.lastY,
                            toX: x,
                            toY: y,
                            color: self.userColor,
                            lineWidth: self.lineWidth,
                            canvasWidth: canvas.width,
                            canvasHeight: canvas.height,
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
        } else if (self.selectedItem.title === 'Capture') {
            // TODO Allow a video feed to be clicked to take a screenshot
        } else {
            console.log(self.selectedItem);
            // We have a shape or custom object
            if (self.selectedItem && self.selectedItem.points) {
                client.mX = x;
                client.mY = y;

                console.log("Drawing shape from points...");

                switch (event.type) {
                    case 'mousedown':
                    case 'touchstart':
                        client.isDrawing = true;
                        client.dragging = true;
                        client.startX = x;
                        client.startY = y;
                        break;
                    case 'mousemove':
                    case 'touchmove':
                        if (client.dragging) {
                            update = {
                                color: self.userColor,
                                lineWidth: self.lineWidth
                                // INFO The points for scaling will get added when drawing is complete
                            };

                            // TODO Color value above is not getting set when switching colors
                            draw(update);
                        }
                        break;
                    case 'mouseup':
                    case 'touchend':
                        client.isDrawing = false;

                        var points = self.selectedItem.points;

                        var scale = scaleForPoints(points);

                        for (var i = 0; i < points.length; i++) {
                            // Scale the points according to the difference between the start and end points
                            var pointX = client.startX + (scale.x * points[i][0]);
                            var pointY = client.startY + (scale.y * points[i][1]);

                            console.log(pointX, pointY);

                            if (i === 0) {
                                client.lastX = pointX;
                                client.lastY = pointY;
                            }

                            update = {
                                id: self.videoFeed.stream.connection.connectionId,
                                fromId: self.session.connection.connectionId,
                                fromX: client.lastX,
                                fromY: client.lastY,
                                toX: pointX,
                                toY: pointY,
                                color: self.userColor,
                                lineWidth: self.lineWidth,
                                canvasWidth: canvas.width,
                                canvasHeight: canvas.height,
                                mirrored: mirrored
                            };

                            drawHistory.push(update);

                            sendUpdate(update);

                            client.lastX = pointX;
                            client.lastY = pointY;
                        }

                        draw(null);

                        client.dragging = false;
                }
            }
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

        // Clear the canvas
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        if (update) {
            ctx.strokeStyle = update.color;
            ctx.lineWidth = update.lineWidth;
        }

        // Repopulate the canvas with items from drawHistory
        drawHistory.forEach(function (history) {
            ctx.strokeStyle = history.color;
            ctx.lineWidth = history.lineWidth;

            ctx.beginPath();
            ctx.moveTo(history.fromX, history.fromY);
            ctx.lineTo(history.toX, history.toY);
            ctx.stroke();
            ctx.closePath();
        });

        if (self.selectedItem && self.selectedItem.title === 'Pen') {
            if (update) {
                ctx.beginPath();
                ctx.moveTo(update.fromX, update.fromY);
                ctx.lineTo(update.toX, update.toY);
                ctx.stroke();
                ctx.closePath();

                drawHistory.push(update);
            }
        } else {
            if (client.isDrawing) {
                if (self.selectedItem && self.selectedItem.points) {
                    drawPoints(ctx, self.selectedItem.points);
                }
            }
        }
    };

    var drawPoints = function (ctx, points) {
        console.log("Drawing points...");
        var scale = scaleForPoints(points);

        ctx.beginPath();

        if (points.length == 2) {
            // We have a line
            ctx.moveTo(client.startX, client.startY);
            ctx.lineTo(client.mX, client.mY);
        } else {
            for (var i = 0; i < points.length; i++) {
                // Scale the points according to the difference between the start and end points
                var pointX = client.startX + (scale.x * points[i][0]);
                var pointY = client.startY + (scale.y * points[i][1]);

                if (i == 0) {
                    ctx.moveTo(pointX, pointY);
                } else {
                    ctx.lineTo(pointX, pointY);
                }
            }
        }

        ctx.stroke();
        ctx.closePath();
    };

    var scaleForPoints = function (points) {
        // mX and mY refer to the end point of the enclosing rectangle (touch up)
        var minX = Number.MAX_VALUE;
        var minY = Number.MAX_VALUE;
        var maxX = 0;
        var maxY = 0;
        for (var i = 0; i < points.length; i++) {
            if (points[i][0] < minX) {
                minX = points[i][0];
            } else if (points[i][0] > maxX) {
                maxX = points[i][0];
            }

            if (points[i][1] < minY) {
                minY = points[i][1];
            } else if (points[i][1] > maxY) {
                maxY = points[i][1];
            }
        }
        var dx = Math.abs(maxX - minX);
        var dy = Math.abs(maxY - minY);

        console.log("AnnotationView", "Delta: " + dx + ", " + dy);

        var scaleX = (client.mX - client.startX) / dx;
        var scaleY = (client.mY - client.startY) / dy;

        console.log("AnnotationView", "Scale: " + scaleX + ", " + scaleY);

        return {x: scaleX, y: scaleY};
    };

    var drawIncoming = function (update) {
        if (!ctx) {
            ctx = canvas.getContext("2d");
            ctx.lineCap = "round";
            ctx.fillStyle = "solid";
        }

        var width = update.canvasWidth;
        var height = update.canvasHeight;

        var scale = 1;

        var canvasRatio = canvas.width / canvas.height;
        var aspectRatio = width / height;

        console.log("CanvasOffset", "Aspects: " + canvasRatio + ", " + aspectRatio);

        // The offset is meant to center-align the canvases
        var offsetX = 0;
        var offsetY = 0;

        /**
         * This assumes that if the width is the greater value, video frames
         * can be scaled so that they have equal widths, which can be used to
         * find the offset in the y axis. Therefore, the offset on the x axis
         * will be 0. If the height is the greater value, the offset on the y
         * axis will be 0.
         */
        if (canvasRatio > aspectRatio && canvasRatio < 0) {
            scale = canvas.width / width;
            offsetY = (canvas.height / 2) - (scale * height / 2);
        } else {
            scale = canvas.height / height;
            offsetX = (canvas.width / 2) - (scale * width / 2);
        }

        console.log("CanvasOffset", "Offset: " + offsetX + ", " + offsetY);
        console.log("CanvasOffset", "Scale: " + scale);

        ctx.strokeStyle = update.color;
        // FIXME If possible, the scale should also scale the line width (use a min width value?)
        ctx.lineWidth = update.lineWidth;
        ctx.beginPath();

        // INFO Since the offset is calculated on the "scaled" frame, we need to scale it back
        var fromX = scale *  update.fromX + offsetX;
        var fromY = scale * update.fromY + offsetY;

        var toX = scale * update.toX + offsetX;
        var toY = scale * update.toY + offsetY;

        // Check if the incoming signal was mirrored
        if (update.mirrored) {
            fromX = this.width - fromX;
            toX = this.width - toX;
        }

        // Check to see if the active video feed is also mirrored (double negative)
        if (mirrored) {
            // Revert (Double negative)
            fromX = this.width - fromX;
            toX = this.width - toX;
        }

        ctx.moveTo(fromX, fromY);
        ctx.lineTo(toX, toY);
        ctx.stroke();
        ctx.closePath();

        drawHistory.push(update);
    };

    var drawUpdates = function (updates) {
        updates.forEach(function (update) {
            drawIncoming(update);
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
    if (self.videoFeed.session) {
        self.videoFeed.session.on({
            'signal:otAnnotation_pen': function (event) {
                if (event.from.connectionId !== self.session.connection.connectionId) {
                    drawUpdates(JSON.parse(event.data));
//                    scope.$emit('otWhiteboardUpdate');
                }
            },
            'signal:otAnnotation_text': function (event) {
                if (event.from.connectionId !== self.session.connection.connectionId) {
                    drawText(JSON.parse(event.data));
//                    scope.$emit('otWhiteboardUpdate');
                }
            },
            'signal:otWhiteboard_history': function (event) {
                // We will receive these from everyone in the room, only listen to the first
                // person. Also the data is chunked together so we need all of that person's
                if (!drawHistoryReceivedFrom || drawHistoryReceivedFrom === event.from.connectionId) {
                    drawHistoryReceivedFrom = event.from.connectionId;
                    drawUpdates(JSON.parse(event.data));
//                    scope.$emit('otWhiteboardUpdate');
                }
            },
            'signal:otAnnotation_clear': function (event) {
                if (event.from.connectionId !== self.session.connection.connectionId) {
                    clearCanvas();
                }
            },
            connectionCreated: function (event) {
                if (drawHistory.length > 0 && event.connection.connectionId !== self.session.connection.connectionId) {
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
                    batchSignal('otAnnotation_pen', batchUpdates);
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
    var self = this;

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
            icon: '../img/line.png',
            points: [
                [0, 0],
                [0, 1]
            ]
        },
        {
            title: 'Shapes',
            icon: '../img/shapes.png',
            items: [
                {
                    title: 'Arrow',
                    icon: '../img/arrow.png',
                    points: [
                        [0, 1],
                        [3, 1],
                        [3, 0],
                        [5, 2],
                        [3, 4],
                        [3, 3],
                        [0, 3],
                        [0, 1] // Reconnect point
                    ]
                },
                {
                    title: 'Rectangle',
                    icon: '../img/rectangle.png',
                    points: [
                        [0, 0],
                        [1, 0],
                        [1, 1],
                        [0, 1],
                        [0, 0] // Reconnect point
                    ]
                },
                {
                    title: 'Oval',
                    icon: '../img/oval.png',
                    points: [
                        [0, 0.5],
                        [0.5 + 0.5 * Math.cos(Math.PI / 4), 0.5 + 0.5 * Math.sin(5 * Math.PI / 4)],
                        [0.5, 0],
                        [0.5 + 0.5 * Math.cos(7 * Math.PI / 4), 0.5 + 0.5 * Math.sin(7 * Math.PI / 4)],
                        [1, 0.5],
                        [0.5 + 0.5 * Math.cos(Math.PI / 4), 0.5 + 0.5 * Math.sin(Math.PI / 4)],
                        [0.5, 1],
                        [0.5 + 0.5 * Math.cos(3 * Math.PI / 4), 0.5 + 0.5 * Math.sin(3 * Math.PI / 4)],
                        [0, 0.5]
                    ]
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

    this.cbs = [];
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
     *  - `autoclose` (Boolean): If `false`, the color picker will not be hidden by default (default: `true`).
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
            var color = ev.target.getAttribute("data-col");
            if (!color) {
                return;
            }
            self.set(color);
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
        var subPanel = document.createElement("div");

        console.log(this.items);

        for (var i = 0, total = this.items.length; i < total; i++) {
            var item = this.items[i];

            var button = document.createElement("input");
            button.setAttribute('type', 'button');
            // TODO Only use this style id for internal actions? Let devs use their own, unmodified ids
            button.setAttribute('id', 'OT-Annotation-' + item.title.replace(" ", "-"));

            if (item.title === 'Colors') {
                var colorPicker = document.createElement("div");
                colorPicker.setAttribute('class', 'color-picker');
                colorPicker.style.backgroundColor = this.backgroundColor;
                this.parent.appendChild(colorPicker);

                var pk = new ColorPicker(".color-picker", this.colors, null);

                pk.colorChosen(function (color) {
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

            button.setAttribute('data-col', item.title);
            button.style.border = 'none';
            button.style.cursor = 'pointer';

            if (item.items) {
                // Indicate that we have a group
                button.setAttribute('data-type', 'group');

                console.log(item.items);
                // TODO We have a group - build a submenu
                subPanel.setAttribute('class', 'OT_subpanel');
                subPanel.style.backgroundColor = this.backgroundColor;
                subPanel.style.width = '100%';
                subPanel.style.height = '100%';
                subPanel.style.paddingLeft = '15px';
                subPanel.style.display = 'none';
                this.parent.appendChild(subPanel);

                if (Array.isArray(item.items)) {
                    var submenuItems = [];

                    item.items.forEach(function (subItem) {
                        var itemButton = document.createElement("input");
                        itemButton.setAttribute('type', 'button');
                        itemButton.setAttribute('data-col', subItem.title);
                        // TODO Only use this style id for internal actions? Let devs use their own, unmodified ids
                        itemButton.setAttribute('id', 'OT-Annotation-' + subItem.title.replace(" ", "-"));
                        itemButton.style.background = 'url("' + subItem.icon + '") no-repeat';
                        itemButton.style.transform = 'translateY(25%)';
                        itemButton.style.backgroundSize = self.iconWidth + ' ' + self.iconHeight;
                        itemButton.style.width = self.buttonWidth;
                        itemButton.style.height = self.buttonHeight;
                        itemButton.style.border = 'none';
                        itemButton.style.cursor = 'pointer';

                        submenuItems.push(itemButton.outerHTML);
                    });

                    subPanel.innerHTML = submenuItems.join('');
                }
            }

            toolbarItems.push(button.outerHTML);
        }

        panel.innerHTML = toolbarItems.join('');

        panel.onclick = function(ev) {
            var group = ev.target.getAttribute("data-type") === 'group';
            var itemName = ev.target.getAttribute("data-col");
            var id = ev.target.getAttribute("id");

            // Close the submenu if we are clicking on an item and not a group button
            if (!group) {
                self.items.forEach(function (item) {
                    if (item.title !== 'Clear' && item.title === itemName) {
                        self.selectedItem = item;
                        console.log(self.selectedItem);

                        self.attachDefaultAction(item);

                        canvases.forEach(function (canvas) {
                            canvas.selectedItem = self.selectedItem;
                        });

                        return false;
                    }
                });
                subPanel.style.display = 'none';
            } else {
                self.items.forEach(function (item) {
                    if (item.title === itemName) {
                        self.selectedGroup = item;
                    }
                });
            }

            self.cbs.forEach(function (cb) {
                cb.call(self, id);
            });
        };

        subPanel.onclick = function(ev) {
            var group = ev.target.getAttribute("data-type") === 'group';
            var itemName = ev.target.getAttribute("data-col");
            var id = ev.target.getAttribute("id");
            subPanel.style.display = 'none';

            if (!group) {
                self.selectedGroup.items.forEach(function (item) {
                    if (item.title !== 'Clear' && item.title === itemName) {
                        self.selectedItem = item;
                        console.log(self.selectedItem);

                        self.attachDefaultAction(item);

                        canvases.forEach(function (canvas) {
                            canvas.selectedItem = self.selectedItem;
                        });

                        return false;
                    }
                });
            }

            self.cbs.forEach(function (cb) {
                cb.call(self, id);
            });
        };

        // TODO Attach remaining click listeners
        document.getElementById('OT-Annotation-Shapes').onclick = function() {
            if (subPanel) {
                subPanel.style.display = 'block';
            }
            pk.close();
        };

        document.getElementById('OT-Annotation-Colors').onclick = function() {
            if (subPanel) {
                subPanel.style.display = 'none';
            }
            pk.open();
        };

        document.getElementById('OT-Annotation-Clear').onclick = function() {
            canvases.forEach(function (canvas) {
                console.log('Clearing canvas');
                canvas.clear();
            });
        };
    }

    this.attachDefaultAction = function (item) {
        if (!item.points) {
            // Attach default actions
            if (item.title === 'Line') {
                self.selectedItem.points = [
                    [0, 0],
                    [0, 1]
                ]
            } else if (item.title === 'Arrow') {
                self.selectedItem.points = [
                    [0, 1],
                    [3, 1],
                    [3, 0],
                    [5, 2],
                    [3, 4],
                    [3, 3],
                    [0, 3],
                    [0, 1] // Reconnect point
                ]
            } else if (item.title === 'Rectangle') {
                self.selectedItem.points = [
                    [0, 0],
                    [1, 0],
                    [1, 1],
                    [0, 1],
                    [0, 0] // Reconnect point
                ]
            } else if (item.title === 'Oval') {
                self.selectedItem.points = [
                    [0, 0.5],
                    [0.5 + 0.5 * Math.cos(Math.PI / 4), 0.5 + 0.5 * Math.sin(5 * Math.PI / 4)],
                    [0.5, 0],
                    [0.5 + 0.5 * Math.cos(7 * Math.PI / 4), 0.5 + 0.5 * Math.sin(7 * Math.PI / 4)],
                    [1, 0.5],
                    [0.5 + 0.5 * Math.cos(Math.PI / 4), 0.5 + 0.5 * Math.sin(Math.PI / 4)],
                    [0.5, 1],
                    [0.5 + 0.5 * Math.cos(3 * Math.PI / 4), 0.5 + 0.5 * Math.sin(3 * Math.PI / 4)],
                    [0, 0.5]
                ]
            }
        }
    };

    this.itemClicked = function(cb) {
        this.cbs.push(cb);
    };

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
            // TODO Should this be canvasStream.stream.connectionId??
            if (annotationView.videoFeed.stream.connection.connectionId === connectionId) {
                // FIXME Make sure sub-menus are removed, too - ensure they are added back in the right order (sub-menu currently shows up on top in second run)
                canvas.parentNode.removeChild(canvas);
            }
        });

        canvases = canvases.filter(function (annotationView) {
            return annotationView.videoFeed.stream.connection.connectionId !== connectionId;
        });
    };

    this.remove = function() {
        panel.parentNode.removeChild(panel);
    };
};
