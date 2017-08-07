import QtQuick 2.9
import "vunsq.js" as V

Item {
    Header {
        id: header
        name:'Preview'
    }

    Canvas {
        scale:2
        id:previewCanvas
        property var vid
        property real startTime
        property var idata
        property var hackContext
        property bool initialized

        contextType: '2d'
        anchors.centerIn: parent
        width:24; height:240;
        Canvas { id:tmpCanvas; anchors.fill:parent; anchors.left:parent.right; contextType:'2d'; opacity:1 }

        onPaint: {
            if (!initialized && available && tmpCanvas.available) initialize();
            if (initialized) vid.update(new Date - startTime);
            requestAnimationFrame(requestPaint);
        }

        function initialize() {
            startTime = Date.now();
            initialized = true;
            vid = new V.Vunsq(previewCanvas.context, fauxContext(tmpCanvas));

            function fallingStripe(t,x,y,data,offset,arg) {
                if (x>=1 || x<0) return;
                var limit = Math.round(t/10);
                if (y<=limit) {
                    data[offset+0] = arg ? arg[0] : 255;
                    data[offset+1] = arg ? arg[1] : 255;
                    data[offset+2] = arg ? arg[2] : 255;
                    data[offset+3] = 255 - (limit-y)*10;
                }
            }
            fallingStripe.bbox = function(t,bbox) {
                var limit = Math.round(t/10);
                bbox.x0 = 0;
                bbox.x1 = 1;
                bbox.y0 = limit-25;
                bbox.y1 = limit+1;
            }

            function gadoosh(t,x,y,data,offset,arg) {
                var msPerBeat = 32;
                var t2 = (t/30)%96-48;
                var a = 255-((x-t2)*(x-t2)+y*y);
                if (a>15) {
                    data[offset+3] = a;
                    hsv(
                        (Math.sin(y/5)*Math.cos(x/5))*180+t/5,
                        0.8+Math.pow((Math.sin(t%msPerBeat/msPerBeat*3.14)+1)/2,30),
                        0.5,
                        data, offset);
                }
            }
            gadoosh.bbox = function(t,bbox) {
                bbox.x0 = (t/30)%96-64;
                bbox.x1 = bbox.x0+32;
                bbox.y0 = -18;
                bbox.y1 = 18;
            }

            vid.effect(0,fallingStripe);
            vid.effect(1,gadoosh);

            vid.loadFromObject({
                patterns:[
                    { id:0, events:[
                        { effect:0, start:0,   x:0, length:2000, args:[255,0,0], blend:'lighter' },
                        { effect:0, start:200, x:2, length:2000, args:[0,255,0], blend:'lighter' },
                        { effect:0, start:400, x:4, length:2000, args:[0,0,255], blend:'lighter' },
                    ] }
                ],
                timeline:[
//                    { pattern:0, speed:0.1, start:1000, x:10, repeat:3 },
//                    { effect:1, x:0, y:0 },
//                    { effect:0, x:0, y:0, start:000, length:1000, repeat:15, args:[255,0,0] },
//                    { effect:0, x:2, y:0, start:100, length:1000, repeat:15, args:[0,255,0] },
//                    { effect:0, x:3, y:0, start:200, length:1000, repeat:15, args:[0,0,255] },
                    { effect:0, x:20, y:0, start:300, length:2000, repeat:15, args:[255,0,255] },
                ]
            });

            function hsv(h,s,v,data,offset) {
                //***h (hue) should be a value from 0 to 360
                //***s (saturation) and v (value) should be a value between 0 and 1
                //***The .r, .g, and .b properties of the returned object are all in the range 0 to 1
                var r,g,b,i,f,p,q,t;
                while (h<0) h+=360; h%=360;
                s=s>1?1:s<0?0:s;
                v=v>1?1:v<0?0:v;

                if (s===0) r=g=b=v;
                else {
                    h/=60;
                    f=h-(i=Math.floor(h));
                    p=v*(1-s);
                    q=v*(1-s*f);
                    t=v*(1-s*(1-f));
                    switch (i) {
                        case 0:r=v; g=t; b=p; break;
                        case 1:r=q; g=v; b=p; break;
                        case 2:r=p; g=v; b=t; break;
                        case 3:r=p; g=q; b=v; break;
                        case 4:r=t; g=p; b=v; break;
                        case 5:r=v; g=p; b=q; break;
                    }
                }
                data[offset+0]=r*255;
                data[offset+1]=g*255;
                data[offset+2]=b*255;
            }
        }

        // Working around https://bugreports.qt.io/browse/QTBUG-62280
        function fauxContext(canvas) {
            return {
                canvas: canvas,
                getImageData:function() {
                    return {
                        width:canvas.width,
                        height:canvas.height,
                        data:Array.apply(null,Array(canvas.width*canvas.height*4)).map(Number.prototype.valueOf,0)
                    };
                },
                putImageData:function(imagedata, dx, dy, dirtyX, dirtyY, dirtyWidth, dirtyHeight) {
                    var x1 = dirtyX||0,
                        x2 = x1 + (dirtyWidth || canvas.width),
                        y1 = dirtyY||0,
                        y2 = y1 + (dirtyHeight || canvas.height);
                    for (var y=y1;y<y2;++y) {
                        for (var x=x1;x<x2;++x) {
                            var o=(y * imagedata.width + x)*4;
                            var a=imagedata.data[o+3];
                            if (a>0) {
                                canvas.context.fillStyle = 'rgba('+imagedata.data[o]+','+imagedata.data[o+1]+','+imagedata.data[o+2]+','+a/255+')';
                                canvas.context.fillRect(x+dx,y+dy,1,1);
                            }
                        }
                    }
                }
            }
        }
    }
}
