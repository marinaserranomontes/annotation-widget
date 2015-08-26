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

OT.Annotations = function(parent, session) {

    var canvas = document.createElement("canvas");
    canvas.setAttribute('id', 'opentok_canvas'); // session.connection.id?
    canvas.style.width =  parent.clientWidth + "px";
    canvas.style.height = parent.clientHeight + "px";
    parent.appendChild(canvas);

    var ctx,
        color,
        lineWidth,
        mirrored,
        batchUpdates = [],
        drawHistory = [],
        drawHistoryReceivedFrom,
        client = {dragging: false};

    var colors = [
        {'background-color': '#000000'},  // Black
        {'background-color': '#0000FF'},  // Blue
        {'background-color': '#FF0000'},  // Red
        {'background-color': '#00FF00'},  // Green
        {'background-color': '#FF8C00'},  // Orange
        {'background-color': '#FFD700'},  // Yellow
        {'background-color': '#4B0082'},  // Purple
        {'background-color': '#800000'}   // Brown
    ];

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

    this.link = function(session) {
        this.session = session;
    };

    this.changeColor = function (color) {
        this.color = color['background-color'];
        if (!this.lineWidth) {
            this.lineWidth = 2;
        }
    };

    this.changeLineWidth = function (size) {
        this.lineWidth = size;
    };

    this.changeColor(colors[2]); // FIXME Default to the first color choice

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

        var self = this;

        var scaleX = canvas.width / parent.clientWidth,
            scaleY = canvas.height / parent.clientHeight,
            offsetX = event.offsetX || event.pageX - canvas.offsetLeft ||
                event.changedTouches[0].pageX - canvas.offsetLeft,
            offsetY = event.offsetY || event.pageY - canvas.offsetTop ||
                event.changedTouches[0].pageY - canvas.offsetTop,
            x = offsetX * scaleX,
            y = offsetY * scaleY;

//        console.log("Offset X: " + offsetX + ", Offset Y: " + offsetY);
        console.log("x: " + x + ", y: " + y);

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
                        color: this.color,
                        lineWidth: this.lineWidth,
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
        var self = this;
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
        var self = this;
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

OT.Annotations.Toolbar = function(session) {
    var canvases = [];

    var add = function(canvas) {
        canvas.link(session);
        canvases.push(canvas);
    }
};