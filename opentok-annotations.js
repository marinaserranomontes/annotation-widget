/*!
 *  Annotation Plugin for OpenTok
 *
 *  @Author: Trevor Boyer
 *  @Copyright (c) 2015 TokBox, Inc
 **/

// loggingURL: 'http://hlg.tokbox.com/prod' -- Use this for logging??

//--------------------------------------
//  OPENTOK ANNOTATION CANVAS/VIEW
//--------------------------------------

OT.Annotations = function(options) {
    options || (options = {});

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
        scaledToFill,
        batchUpdates = [],
        drawHistory = [],
        drawHistoryReceivedFrom,
        client = {dragging: false};

    // INFO Mirrored feeds contain the OT_mirrored class
    // FIXME Looks like there may be a bug here - all divs seem to have this class
    mirrored = (' ' + self.videoFeed.element.className + ' ').indexOf(' ' + 'OT_mirrored' + ' ') > -1;
    scaledToFill = (' ' + self.videoFeed.element.className + ' ').indexOf(' ' + 'OT_fit-mode-cover' + ' ') > -1;

    this.canvas = function() {
        return canvas;
    };

    /**
     * Links an OpenTok session to the annotation canvas. Typically, this is automatically linked
     * when using {@link Toolbar#addCanvas}.
     * @param session The OpenTok session.
     */
    this.link = function(session) {
        this.session = session;
    };

    /**
     * Changes the active annotation color for the canvas.
     * @param color The hex string representation of the color (#rrggbb).
     */
    this.changeColor = function (color) {
        self.userColor = color;
        if (!self.lineWidth) {
            self.lineWidth = 2; // TODO Default to first option in list of line widths
        }
    };

    /**
     * Changes the line/stroke width of the active annotation for the canvas.
     * @param size The size in pixels.
     */
    this.changeLineWidth = function (size) {
        this.lineWidth = size;
    };

    /**
     * Sets the selected menu item from the toolbar. This is typically handled
     * automatically by the toolbar, but can be used to programmatically select an item.
     * @param item The menu item to set as selected.
     */
    this.selectItem = function (item) {
        if (item.title === 'Capture') {
            self.selectedItem = item;

            self.overlay = document.createElement("div");
            self.overlay.style.width = this.parent.clientWidth + 'px';
            self.overlay.style.height = this.parent.clientHeight + 'px';
            self.overlay.backgroundColor = 'rgba(0, 0, 0, 0.4)';
            self.overlay.style.cursor = 'pointer';
            self.overlay.style.opacity = 0;

            self.parent.appendChild(self.overlay);

            self.overlay.onmouseover = function () {
                self.overlay.style.opacity = 1;
            };

            self.overlay.onmouseout = function () {
                self.overlay.style.opacity = 0;
            };

            self.overlay.onclick = function () {
                console.log("Clicked feed: " + self.videoFeed.stream.connection.connectionId);

                self.captureScreenshot();

                // TODO Provide callback with the screenshot obj
            };
        } else if (item.title.indexOf('Line Width') !== -1) {
            if (item.size) {
                self.changeLineWidth(item.size);
            }
        } else {
            self.selectedItem = item;

            if (self.overlay) {
                self.parent.removeChild(self.overlay);
                self.overlay = null;
            }
        }
    };

    /**
     *
     * @param colors
     */
    this.colors = function (colors) {
        this.colors = colors;
        this.changeColor(colors[0]);
    };

    /**
     * Clears the canvas for the active user. Only annotations added by the active OpenTok user will
     * be removed, leaving the history of all other annotations.
     */
    this.clear = function () {
        clearCanvas(false, self.session.connection.connectionId);
        if (session) {
            session.signal({
                type: 'otAnnotation_clear'
            });
        }
    };

    // TODO Allow the user to choose the image type? (jpg, png) Also allow size?
    /**
     * Captures a screenshot of the annotations displayed on top of the active video feed.
     */
    this.captureScreenshot = function() {
        var canvasCopy = document.createElement('canvas');
        canvasCopy.width = canvas.width;
        canvasCopy.height = canvas.height;

        var width = self.videoFeed.videoWidth();
        var height = self.videoFeed.videoHeight();

        var scale = 1;

        if (width > height) {
            scale = canvas.width / width;
            width = canvas.width;
            height = height * scale;
        } else {
            scale = canvas.height / height;
            height = canvas.height;
            width = width * scale;
        }

        var offsetX = 0;
        var offsetY = 0;

        if (scaledToFill) {
            // If stretched to fill, we need an offset to center the image
            offsetX = (canvas.width - width) / 2;
            offsetY = (canvas.height - height) / 2;
        }

        // Combine the two
        var image = new Image();
        image.onload = function() {
            var ctxCopy = canvasCopy.getContext('2d');
            if (mirrored) {
                ctxCopy.translate(width, 0);
                ctxCopy.scale(-1, 1);
            }
            ctxCopy.drawImage(image, offsetX, offsetY, width, height);

            // We want to make sure we draw the annotations the same way, so we need to flip back
            if (mirrored) {
                ctxCopy.translate(width, 0);
                ctxCopy.scale(-1, 1);
            }
            ctxCopy.drawImage(canvas, 0, 0);

            // FIXME Remove this (testing only)
//            var win = window.open(canvasCopy.toDataURL(), '_blank');
//            win.focus();

            // TODO Send image through callback
            // canvasCopy.toDataURL()

            // Clear and destroy the canvas copy
            canvasCopy = null;
        };
        image.src = 'data:image/png;base64,' + self.videoFeed.getImgData();

    };

    /** Canvas Handling **/

    function addEventListeners(el, s, fn) {
        var evts = s.split(' ');
        for (var i = 0, iLen = evts.length; i < iLen; i++) {
            el.addEventListener(evts[i], fn, true);
        }
    }

    addEventListeners(canvas, 'mousedown mousemove mouseup mouseout touchstart touchmove touchend', function (event) {
        if (event.type === 'mousemove' && !client.dragging) {
            // Ignore mouse move Events if we're not dragging
            return;
        }
        event.preventDefault();

        var scaleX = canvas.width / self.parent.clientWidth;
        var scaleY = canvas.height / self.parent.clientHeight;
        var offsetX = event.offsetX || event.pageX - canvas.offsetLeft ||
                event.changedTouches[0].pageX - canvas.offsetLeft;
        var offsetY = event.offsetY || event.pageY - canvas.offsetTop ||
                event.changedTouches[0].pageY - canvas.offsetTop;
        var x = offsetX * scaleX;
        var y = offsetY * scaleY;

//        console.log("Video size: " + self.videoFeed.videoWidth(), self.videoFeed.videoHeight());
//        console.log("Canvas size: " + canvas.width, canvas.height);

//        console.log("Offset X: " + offsetX + ", Offset Y: " + offsetY);
//        console.log("x: " + x + ", y: " + y);

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
                            videoWidth: self.videoFeed.videoWidth(),
                            videoHeight: self.videoFeed.videoHeight(),
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
        } else {
            // We have a shape or custom object
            if (self.selectedItem && self.selectedItem.points) {
                client.mX = x;
                client.mY = y;

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

                            draw(update);
                        }
                        break;
                    case 'mouseup':
                    case 'touchend':
                        client.isDrawing = false;

                        var points = self.selectedItem.points;

                        if (points.length == 2) {
                            update = {
                                id: self.videoFeed.stream.connection.connectionId,
                                fromId: self.session.connection.connectionId,
                                fromX: client.startX,
                                fromY: client.startY,
                                toX: client.mX,
                                toY: client.mY,
                                color: self.userColor,
                                lineWidth: self.lineWidth,
                                videoWidth: self.videoFeed.videoWidth(),
                                videoHeight: self.videoFeed.videoHeight(),
                                canvasWidth: canvas.width,
                                canvasHeight: canvas.height,
                                mirrored: mirrored
                            };

                            drawHistory.push(update);

                            sendUpdate(update);
                        } else {
                            var scale = scaleForPoints(points);

                            for (var i = 0; i < points.length; i++) {
                                // Scale the points according to the difference between the start and end points
                                var pointX = client.startX + (scale.x * points[i][0]);
                                var pointY = client.startY + (scale.y * points[i][1]);

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
                                    videoWidth: self.videoFeed.videoWidth(),
                                    videoHeight: self.videoFeed.videoHeight(),
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
                        }

                        client.dragging = false;
                }
            }
        }
    });

    var draw = function (update) {
        if (!ctx) {
            ctx = canvas.getContext("2d");
            ctx.lineCap = "round";
            ctx.fillStyle = "solid";
        }

        // Clear the canvas
        ctx.clearRect(0, 0, canvas.width, canvas.height);

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
                ctx.strokeStyle = update.color;
                ctx.lineWidth = update.lineWidth;
                ctx.beginPath();
                ctx.moveTo(update.fromX, update.fromY);
                ctx.lineTo(update.toX, update.toY);
                ctx.stroke();
                ctx.closePath();

                drawHistory.push(update);
            }
        } else {
            if (client.isDrawing) {
                if (update) {
                    ctx.strokeStyle = update.color;
                    ctx.lineWidth = update.lineWidth;
                }
                if (self.selectedItem && self.selectedItem.points) {
                    drawPoints(ctx, self.selectedItem.points);
                }
            }
        }
    };

    var drawPoints = function (ctx, points) {
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

        var scaleX = (client.mX - client.startX) / dx;
        var scaleY = (client.mY - client.startY) / dy;

        return {x: scaleX, y: scaleY};
    };

    var drawIncoming = function (update) {
        var iCanvas = {
            width: update.canvasWidth,
            height: update.canvasHeight
        };

        var iVideo = {
            width: update.videoWidth,
            height: update.videoHeight
        };

        var video = {
            width: self.videoFeed.videoWidth(),
            height: self.videoFeed.videoHeight()
        };

        var scale = 1;

        var canvasRatio = canvas.width / canvas.height;
        var videoRatio = video.width / video.height;
        var iCanvasRatio = iCanvas.width / iCanvas.height;
        var iVideoRatio = iVideo.width / iVideo.height;

        // The offset is meant to center-align the canvases
        var offsetX = 0;
        var offsetY = 0;

        // First, calculate the offset on the incoming video
        if (iCanvasRatio > iVideoRatio && iCanvasRatio < 0) {
            scale = iCanvas.width / iVideo.width;
            offsetY = (iCanvas.height / 2) - (scale * iVideo.height / 2);
        } else {
            scale = iCanvas.height / iVideo.height;
            offsetX = (iCanvas.width / 2) - (scale * iVideo.width / 2);
        }

        // Then, calculate the offset on the current video
        if (canvasRatio > videoRatio && canvasRatio < 0) {
            scale = canvas.width / video.width;
            offsetY += (canvas.height / 2) - (scale * video.height / 2);
        } else {
            scale = canvas.height / video.height;
            offsetX += (canvas.width / 2) - (scale * video.width / 2);
        }

        // Last, calculate the total offset based on the scale of the current and incoming canvases

        /**
         * This assumes that if the width is the greater value, video frames
         * can be scaled so that they have equal widths, which can be used to
         * find the offset in the y axis. Therefore, the offset on the x axis
         * will be 0. If the height is the greater value, the offset on the y
         * axis will be 0.
         */
        if (canvasRatio > iCanvasRatio && canvasRatio < 0) {
            scale = canvas.width / iCanvas.width;
            offsetY += (canvas.height / 2) - (scale * iCanvas.height / 2);
        } else {
            scale = canvas.height / iCanvas.height;
            offsetX += (canvas.width / 2) - (scale * iCanvas.width / 2);
        }

        update.fromX = scale * update.fromX + offsetX;
        update.fromY = scale * update.fromY + offsetY;

        update.toX = scale * update.toX + offsetX;
        update.toY = scale * update.toY + offsetY;

        // Check if the incoming signal was mirrored
        if (update.mirrored) {
            update.fromX = canvas.width - update.fromX;
            update.toX = canvas.width - update.toX;
        }

        // Check to see if the active video feed is also mirrored (double negative)
        if (mirrored) {
            // Revert (Double negative)
            update.fromX = canvas.width - update.fromX;
            update.toX = canvas.width - update.toX;
        }

        console.log(update);
        drawHistory.push(update);

        draw(update);
    };

    var drawUpdates = function (updates) {
        updates.forEach(function (update) {
            if (update.id === self.videoFeed.stream.connection.connectionId) {
                drawIncoming(update);
            }
        });
    };

    var clearCanvas = function (incoming, cid) {
        console.log("cid: " + cid);
        // Remove all elements from history that were drawn by the sender
        drawHistory = drawHistory.filter(function (history) {
            console.log(history.fromId);
            return history.fromId !== cid;
        });

        if (!incoming) {
            if (session) {
                session.signal({
                    type: 'otAnnotation_clear'
                });
            }
        }

        // Refresh the canvas
        draw();
    };

    /** Signal Handling **/
    if (self.videoFeed.session) {
        self.videoFeed.session.on({
            'signal:otAnnotation_pen': function (event) {
                if (event.from.connectionId !== self.session.connection.connectionId) {
                    drawUpdates(JSON.parse(event.data));
                }
            },
            'signal:otAnnotation_text': function (event) {
                if (event.from.connectionId !== self.session.connection.connectionId) {
                    drawText(JSON.parse(event.data));
                }
            },
            'signal:otWhiteboard_history': function (event) {
                // We will receive these from everyone in the room, only listen to the first
                // person. Also the data is chunked together so we need all of that person's
                if (!drawHistoryReceivedFrom || drawHistoryReceivedFrom === event.from.connectionId) {
                    drawHistoryReceivedFrom = event.from.connectionId;
                    drawUpdates(JSON.parse(event.data));
                }
            },
            'signal:otAnnotation_clear': function (event) {
                if (event.from.connectionId !== self.session.connection.connectionId) {
                    // Only clear elements drawn by the sender's (from) Id
                    clearCanvas(true, event.from.connectionId);
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
                        [0.5 + 0.5 * Math.cos(5 * Math.PI / 4), 0.5 + 0.5 * Math.sin(5 * Math.PI / 4)],
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

        for (var i = 0, total = this.items.length; i < total; i++) {
            var item = this.items[i];

            var button = document.createElement("input");
            button.setAttribute('type', 'button');
            // TODO Only use this style id for internal actions? Let devs use their own, unmodified ids
            button.setAttribute('id', 'OT-Annotation-' + item.title.replace(" ", "-"));

            button.style.position = 'relative';
            button.style.top = "50%";
            button.style.transform = 'translateY(-50%)';

            if (item.title === 'Colors') {
                var colorPicker = document.createElement("div");
                colorPicker.setAttribute('class', 'color-picker');
                colorPicker.style.backgroundColor = this.backgroundColor;
                this.parent.appendChild(colorPicker);

                var pk = new ColorPicker(".color-picker", this.colors, null);

                pk.colorChosen(function (color) {
                    var colorGroup = document.getElementById('OT-Annotation-Colors');
                    colorGroup.style.backgroundColor = color;

                    canvases.forEach(function (canvas) {
                        canvas.changeColor(color);
                    });
                });

                button.setAttribute('class', 'OT_color');
                button.style.marginLeft = '10px';
                button.style.marginRight = '10px';
                button.style.borderRadius = '50%';
                button.style.backgroundColor = this.colors[0];
                button.style.width = this.iconWidth;
                button.style.height = this.iconHeight;
                button.style.paddingTop = this.buttonHeight.replace('px', '') - this.iconHeight.replace('px', '') + 'px';
            } else {
                button.style.background = 'url("' + item.icon + '") no-repeat';
                button.style.backgroundSize = this.iconWidth + ' ' + this.iconHeight;
                button.style.backgroundPosition = 'center';
                button.style.width = this.buttonWidth;
                button.style.height = this.buttonHeight;
            }

            // If we have an object as item.items, it was never set by the user
            if (item.title === 'Line Width' && !Array.isArray(item.items)) {
                // Add defaults
                item.items = [
                    {
                        title: 'Line Width 2',
                        size: 2
                    },
                    {
                        title: 'Line Width 4',
                        size: 4
                    },
                    {
                        title: 'Line Width 6',
                        size: 6
                    },
                    {
                        title: 'Line Width 8',
                        size: 8
                    },
                    {
                        title: 'Line Width 10',
                        size: 10
                    },
                    {
                        title: 'Line Width 12',
                        size: 12
                    },
                    {
                        title: 'Line Width 14',
                        size: 14
                    }
                ];
            }

            if (item.items) {
                // Indicate that we have a group
                button.setAttribute('data-type', 'group');
            }

            button.setAttribute('data-col', item.title);
            button.style.border = 'none';
            button.style.cursor = 'pointer';

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

                        attachDefaultAction(item);

                        canvases.forEach(function (canvas) {
                            canvas.selectItem(self.selectedItem);
                        });

                        return false;
                    }
                });
                subPanel.style.display = 'none';
            } else {
                self.items.forEach(function (item) {
                    if (item.title === itemName) {
                        self.selectedGroup = item;

                        if (item.items) {
                            subPanel.setAttribute('class', 'OT_subpanel');
                            subPanel.style.backgroundColor = self.backgroundColor;
                            subPanel.style.width = '100%';
                            subPanel.style.height = '100%';
                            subPanel.style.paddingLeft = '15px';
                            subPanel.style.display = 'none';
                            self.parent.appendChild(subPanel);

                            if (Array.isArray(item.items)) {
                                var submenuItems = [];

                                if (item.title === 'Line Width') {
                                    // We want to dynamically create icons for the list of possible line widths
                                    item.items.forEach(function (subItem) {
                                        // INFO Using a div here - not input to create an inner div representing the line width - better option?
                                        var itemButton = document.createElement("div");
                                        itemButton.setAttribute('data-col', subItem.title);
                                        // TODO Only use this style id for internal actions? Let devs use their own, unmodified ids
                                        itemButton.setAttribute('id', 'OT-Annotation-' + subItem.title.replace(" ", "-"));
                                        itemButton.style.position = 'relative';
                                        itemButton.style.top = "50%";
                                        itemButton.style.transform = 'translateY(-50%)';
                                        itemButton.style.float = 'left';
                                        itemButton.style.width = self.buttonWidth;
                                        itemButton.style.height = self.buttonHeight;
                                        itemButton.style.border = 'none';
                                        itemButton.style.cursor = 'pointer';

                                        var lineIcon = document.createElement("div");
                                        // TODO Allow devs to change this?
                                        lineIcon.style.backgroundColor = '#FFFFFF';
                                        lineIcon.style.width = '80%';
                                        lineIcon.style.height = subItem.size + 'px';
                                        lineIcon.style.position = 'relative';
                                        lineIcon.style.left = "50%";
                                        lineIcon.style.top = "50%";
                                        lineIcon.style.transform = 'translateX(-50%) translateY(-50%)';
                                        // Prevents div icon from catching events so they can be passed to the parent
                                        lineIcon.style.pointerEvents = 'none';

                                        itemButton.appendChild(lineIcon);

                                        submenuItems.push(itemButton.outerHTML);
                                    });
                                } else {
                                    item.items.forEach(function (subItem) {
                                        var itemButton = document.createElement("input");
                                        itemButton.setAttribute('type', 'button');
                                        itemButton.setAttribute('data-col', subItem.title);
                                        // TODO Only use this style id for internal actions? Let devs use their own, unmodified ids
                                        itemButton.setAttribute('id', 'OT-Annotation-' + subItem.title.replace(" ", "-"));
                                        itemButton.style.background = 'url("' + subItem.icon + '") no-repeat';
                                        itemButton.style.position = 'relative';
                                        itemButton.style.top = "50%";
                                        itemButton.style.transform = 'translateY(-50%)';
                                        itemButton.style.backgroundSize = self.iconWidth + ' ' + self.iconHeight;
                                        itemButton.style.backgroundPosition = 'center';
                                        itemButton.style.width = self.buttonWidth;
                                        itemButton.style.height = self.buttonHeight;
                                        itemButton.style.border = 'none';
                                        itemButton.style.cursor = 'pointer';

                                        submenuItems.push(itemButton.outerHTML);
                                    });
                                }

                                subPanel.innerHTML = submenuItems.join('');
                            }
                        }

                        if (id === 'OT-Annotation-Shapes' || id === 'OT-Annotation-Line-Width') {
                            if (subPanel) {
                                subPanel.style.display = 'block';
                            }
                            pk.close();
                        } else if (id === 'OT-Annotation-Colors') {
                            if (subPanel) {
                                subPanel.style.display = 'none';
                            }
                            pk.open();
                        }
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

                        attachDefaultAction(item);

                        canvases.forEach(function (canvas) {
                            canvas.selectItem(self.selectedItem);
                        });

                        return false;
                    }
                });
            }

            self.cbs.forEach(function (cb) {
                cb.call(self, id);
            });
        };

        document.getElementById('OT-Annotation-Clear').onclick = function() {
            canvases.forEach(function (canvas) {
                canvas.clear();
            });
        };
    }

    var attachDefaultAction = function (item) {
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
                    [0.5 + 0.5 * Math.cos(5 * Math.PI / 4), 0.5 + 0.5 * Math.sin(5 * Math.PI / 4)],
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

    /**
     * Callback function for toolbar menu item click events.
     * @param cb The callback function used to handle the click event.
     */
    this.itemClicked = function(cb) {
        this.cbs.push(cb);
    };

    /**
     * Links an annotation canvas to the toolbar so that menu actions can be handled on it.
     * @param canvas The annotation canvas to be linked to the toolbar.
     */
    this.addCanvas = function(canvas) {
        var self = this;
        canvas.link(session);
        canvas.colors(self.colors);
        canvases.push(canvas);
    };

    // FIXME For video feeds that are terminated by the subscriber, the parentNode is removed, but not the reference to the canvas
    /**
     * Removes the annotation canvas with the specified connectionId from its parent container and
     * unlinks it from the toolbar.
     * @param connectionId The stream's connection ID for the video feed whose canvas should be removed.
     */
    this.removeCanvas = function(connectionId) {
        canvases.forEach(function (annotationView) {
            var canvas = annotationView.canvas();
            if (annotationView.videoFeed.stream.connection.connectionId === connectionId) {
                if (canvas.parentNode) {
                    canvas.parentNode.removeChild(canvas);
                }
            }
        });

        canvases = canvases.filter(function (annotationView) {
            return annotationView.videoFeed.stream.connection.connectionId !== connectionId;
        });
    };

    /**
     * Removes the toolbar and all associated annotation canvases from their parent containers.
     */
    this.remove = function() {
        panel.parentNode.removeChild(panel);

        canvases.forEach(function (annotationView) {
            var canvas = annotationView.canvas();
            if (canvas.parentNode) {
                canvas.parentNode.removeChild(canvas);
            }
        });

        canvases = [];
    };
};
