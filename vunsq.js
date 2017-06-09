function Vunsq(canvas){
	this.can = canvas;
	this.ctx = canvas.getContext('2d');
	this.w = canvas.width;
	this.h = canvas.height;
	this.ctx.fillStyle = 'black';
	this.effects = [];
	this.timeline = [];
	this.tmpCanvas = document.createElement('canvas');
	this.tmpCanvas.width  = this.w;
	this.tmpCanvas.height = this.h;
	this.tmpCtx = this.tmpCanvas.getContext('2d');
	this.tmpData = this.tmpCtx.getImageData(0,0,this.w,this.h);
	this.pt = document.createElementNS("http://www.w3.org/2000/svg", "svg").createSVGPoint();
}

Vunsq.prototype.effect = function(index,func) {
	this.effects[index] = func;
};

// TODO: loop/repeat
Vunsq.prototype.add = function(evt) {
	if (!('start' in evt)) evt.start = 0;
	if (!('stop'  in evt)) evt.stop  = Infinity;
	if (!('blend' in evt)) evt.blend = 'source-over';
	if (!('speed' in evt)) evt.speed = 1;
	if (evt.matrix || evt.x || evt.y || evt.rotate || evt.scale || evt.scaleX || evt.scaleY) {
		var m = evt.matrix;
		evt.matrix = document.createElementNS("http://www.w3.org/2000/svg", "svg").createSVGMatrix();
		if (m) {
			evt.matrix.a = m[0];
			evt.matrix.b = m[1];
			evt.matrix.c = m[2];
			evt.matrix.d = m[3];
			evt.matrix.e = m[4];
			evt.matrix.f = m[5];
		} else {
			if (evt.scale)      evt.matrix = evt.matrix.scale(1/evt.scale);
			else if (evt.scaleX || evt.scaleY) evt.matrix = evt.matrix.scaleNonUniform(1/(evt.scaleX||1), 1/(evt.scaleY||1));
			if (evt.rotate)     evt.matrix = evt.matrix.rotate(evt.rotate);
			if (evt.x || evt.y) evt.matrix = evt.matrix.translate(-evt.x||0, -evt.y||0);
		}
	}
	this.timeline.push(evt);
};


Vunsq.prototype.update = function(t) {
	// FIXME: make a far, far more efficient active scan and layer build up
	var activeEffectsByLayer = [];
	for (var i=0;i<this.timeline.length;++i) {
		var e = this.timeline[i];
		if (t>=e.start && t<e.stop) {
			if ('layer' in e) {
				if (activeEffectsByLayer[e.layer]) activeEffectsByLayer[e.layer].push(e);
				else activeEffectsByLayer[e.layer] = [e];
			} else activeEffectsByLayer.push([e]);
		}
	}

	this.ctx.globalCompositeOperation = 'source-over';
	this.ctx.fillRect(0,0,this.w,this.h);

	var d=this.tmpData.data;
	for (var i=0;i<activeEffectsByLayer.length;++i) {
		if (!activeEffectsByLayer[i]) continue;
		for (var j=0;j<activeEffectsByLayer[i].length;++j) {
			var evt = activeEffectsByLayer[i][j];
			for (var x=0;x<this.w;++x) {
				for (var y=0;y<this.h;++y) {
					var offset = (y*this.w+x)*4;
					d[offset+3] = 0; // clear out old values
					if (evt.matrix) {
						this.pt.x = x;
						this.pt.y = y;
						var pt = this.pt.matrixTransform(evt.matrix);
						this.effects[evt.effect]((t-evt.start)*evt.speed,pt.x,pt.y,d,offset,evt.arg);
					} else {
						this.effects[evt.effect]((t-evt.start)*evt.speed,x,y,d,offset,evt.arg);
					}
				}
			}
			this.tmpCtx.putImageData(this.tmpData,0,0);
			this.ctx.globalCompositeOperation = evt.blend;
			this.ctx.drawImage(this.tmpCanvas,0,0);
		}
	}
};

Vunsq.prototype.go = function(fpsEl) {
	var me = this;
	if (fpsEl) {
		var msPerFrame = 1000/60;
		var lastUpdate = 0;
		setInterval(function(){
			fpsEl.innerHTML = (1000/msPerFrame).toFixed(1)+' fps';
		},1000);
	}
	crank(0);
	function crank(t){
		me.update(t);
		requestAnimationFrame(crank);
		if (fpsEl) {
			msPerFrame += (t-lastUpdate-msPerFrame)/10;
			lastUpdate = t;
		}
	}
};