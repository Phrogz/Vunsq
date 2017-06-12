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
		evt.inverseMatrix = evt.matrix.inverse();
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

	if (this.debugCanvas) {
		var c = this.debugCanvas.getContext('2d');
		c.clearRect(0,0,this.debugCanvas.width,this.debugCanvas.height);
		c.strokeStyle = 'rgba(255,0,255,0.8)';
		c.lineWidth = 1;
	}

	var bbox = {};
	var d=this.tmpData.data;
	for (var i=0;i<activeEffectsByLayer.length;++i) {
		if (!activeEffectsByLayer[i]) continue;
		for (var j=0;j<activeEffectsByLayer[i].length;++j) {
			var evt = activeEffectsByLayer[i][j];
			var effect = this.effects[evt.effect];
			var effectTime = (t-evt.start)*evt.speed;

			// Calculate transformed bounding box of pixels to affect
			effect.bbox(effectTime, bbox);
			if (evt.matrix) {
				var x0,x1,y0,y1,pt;
				this.pt.x = bbox.x0;
				this.pt.y = bbox.y0;
				pt = this.pt.matrixTransform(evt.inverseMatrix);
				x0=x1=pt.x;
				y0=y1=pt.y;

				this.pt.x = bbox.x1;
				pt = this.pt.matrixTransform(evt.inverseMatrix);
				if (pt.x<x0) x0=pt.x;
				if (pt.x>x1) x1=pt.x;
				if (pt.y<y0) y0=pt.y;
				if (pt.y>y1) y1=pt.y;

				this.pt.y = bbox.y1;
				pt = this.pt.matrixTransform(evt.inverseMatrix);
				if (pt.x<x0) x0=pt.x;
				if (pt.x>x1) x1=pt.x;
				if (pt.y<y0) y0=pt.y;
				if (pt.y>y1) y1=pt.y;

				this.pt.x = bbox.x0;
				pt = this.pt.matrixTransform(evt.inverseMatrix);
				if (pt.x<x0) x0=pt.x;
				if (pt.x>x1) x1=pt.x;
				if (pt.y<y0) y0=pt.y;
				if (pt.y>y1) y1=pt.y;
			}

			// Floor minimums, ceil maximums, without function call
			bbox.x0 = x0<0 ? (pt=x0<<0, pt==x0 ? pt : pt-1) : (x0<<0);
			bbox.y0 = y0<0 ? (pt=y0<<0, pt==y0 ? pt : pt-1) : (y0<<0);
			bbox.x1 = x1<0 ? (x1<<0) : (pt=x1<<0, pt==x1 ? pt : pt+1);
			bbox.y1 = y1<0 ? (y1<<0) : (pt=y1<<0, pt==y1 ? pt : pt+1);

			// Clamp values to within canvas
			if (bbox.x0<0) bbox.x0=0; else if (bbox.x0>=this.w) bbox.x0=this.w-1;
			if (bbox.x1<0) bbox.x1=0; else if (bbox.x1>=this.w) bbox.x1=this.w-1;
			if (bbox.y0<0) bbox.y0=0; else if (bbox.y0>=this.h) bbox.y0=this.h-1;
			if (bbox.y1<0) bbox.y1=0; else if (bbox.y1>=this.h) bbox.y1=this.h-1;

			bbox.w = bbox.x1-bbox.x0;
			bbox.h = bbox.y1-bbox.y0;

			// FIXME: this should not be hard-coded to 4x the main canvas resolution
			if (this.debugCanvas) c.strokeRect(bbox.x0*4,bbox.y0*4,bbox.w*4,bbox.h*4);

			for (var x=bbox.x0;x<=bbox.x1;++x) {
				for (var y=bbox.y0;y<=bbox.y1;++y) {
					var offset = (y*this.w+x)*4;
					d[offset+3] = 0; // clear out old values before calling the effect
					this.pt.x = x;
					this.pt.y = y;
					if (evt.matrix) this.pt = this.pt.matrixTransform(evt.matrix);
					effect(effectTime,this.pt.x,this.pt.y,d,offset,evt.arg);
				}
			}
			this.tmpCtx.putImageData(this.tmpData,0,0,bbox.x0,bbox.y0,bbox.w,bbox.h);
			this.ctx.globalCompositeOperation = evt.blend;
			this.ctx.drawImage(this.tmpCanvas,bbox.x0,bbox.y0,bbox.w,bbox.h,bbox.x0,bbox.y0,bbox.w,bbox.h);
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
		},500);
	}
	crank(0);
	function crank(t){
		me.update(t);
		requestAnimationFrame(crank);
		if (fpsEl) {
			msPerFrame += (t-lastUpdate-msPerFrame)/8;
			lastUpdate = t;
		}
	}
};