/*!
 * g.Raphael 0.51 - Charting library, based on Raphaël
 *
 * Copyright (c) 2009-2012 Dmitry Baranovskiy (http://g.raphaeljs.com)
 * Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) license.
 */
(function(){function s(e,n,o,p,g,k,h,r,c){function s(a){+a[0]&&(a[0]=j.axis(n+b,o+b,p-2*b,t,C,c.axisxstep||Math.floor((p-2*b)/20),2,c.axisxlabels||null,c.axisxtype||"t",null,e));+a[1]&&(a[1]=j.axis(n+p-b,o+g-b,g-2*b,u,D,c.axisystep||Math.floor((g-2*b)/20),3,c.axisylabels||null,c.axisytype||"t",null,e));+a[2]&&(a[2]=j.axis(n+b,o+g-b+x,p-2*b,t,C,c.axisxstep||Math.floor((p-2*b)/20),0,c.axisxlabels||null,c.axisxtype||"t",null,e));+a[3]&&(a[3]=j.axis(n+b-x,o+g-b,g-2*b,u,D,c.axisystep||Math.floor((g-2*
b)/20),1,c.axisylabels||null,c.axisytype||"t",null,e))}for(var c=c||{},j=this,l=j.snapEnds(Math.min.apply(Math,k),Math.max.apply(Math,k),k.length-1),t=l.from,C=l.to,b=c.gutter||10,l=j.snapEnds(Math.min.apply(Math,h),Math.max.apply(Math,h),h.length-1),u=l.from,D=l.to,v=Math.max(k.length,h.length,r.length),l=e[c.symbol]||"circle",m=e.set(),y=e.set(),E=c.max||100,a=Math.max.apply(Math,r),q=[],i=2*Math.sqrt(a/Math.PI)/E,a=0;a<v;a++)q[a]=Math.min(2*Math.sqrt(r[a]/Math.PI)/i,E);var b=Math.max.apply(Math,
q.concat(b)),v=e.set(),x=Math.max.apply(Math,q);if(c.axis){var f=(c.axis+"").split(/[,\s]+/);s.call(j,f);for(var w=[],a=0,i=f.length;a<i;a++){var z=f[a].all?f[a].all.getBBox()[["height","width"][a%2]]:0;w[a]=z+b}b=Math.max.apply(Math,w.concat(b));a=0;for(i=f.length;a<i;a++)f[a].all&&(f[a].remove(),f[a]=1);s.call(j,f);a=0;for(i=f.length;a<i;a++)f[a].all&&v.push(f[a].all);m.axis=v}f=(p-2*b)/(C-t||1);w=(g-2*b)/(D-u||1);a=0;for(i=h.length;a<i;a++){var z=e.raphael.is(l,"array")?l[a]:l,A=n+b+(k[a]-t)*f,
B=o+g-b-(h[a]-u)*w;z&&q[a]&&y.push(e[z](A,B,q[a]).attr({fill:c.heat?"hsb("+[Math.min(0.4*(1-q[a]/x),1),0.75,0.75]+")":j.colors[0],"fill-opacity":c.opacity?q[a]/E:1,stroke:"none"}))}for(var d=e.set(),a=0,i=h.length;a<i;a++)A=n+b+(k[a]-t)*f,B=o+g-b-(h[a]-u)*w,d.push(e.circle(A,B,x).attr(j.shim)),c.href&&c.href[a]&&d[a].attr({href:c.href[a]}),d[a].r=+q[a].toFixed(3),d[a].x=+A.toFixed(3),d[a].y=+B.toFixed(3),d[a].X=k[a],d[a].Y=h[a],d[a].value=r[a]||0,d[a].dot=y[a];m.covers=d;m.series=y;m.push(y,v,d);
m.hover=function(a,b){d.mouseover(a).mouseout(b);return this};m.click=function(a){d.click(a);return this};m.each=function(a){if(!e.raphael.is(a,"function"))return this;for(var b=d.length;b--;)a.call(d[b]);return this};m.href=function(a){for(var b,c=d.length;c--;)b=d[c],b.X==a.x&&(b.Y==a.y&&b.value==a.value)&&b.attr({href:a.href})};return m}var F=function(){};F.prototype=Raphael.g;s.prototype=new F;Raphael.fn.dotchart=function(e,n,o,p,g,k,h,r){return new s(this,e,n,o,p,g,k,h,r)}})();