package model.util
{
import com.degrafa.geometry.Ellipse;
import com.degrafa.geometry.Geometry;
import com.degrafa.geometry.Line;
import com.degrafa.geometry.Polygon;
import com.degrafa.geometry.QuadraticBezier;
import com.degrafa.geometry.RegularRectangle;
import com.degrafa.paint.SolidStroke;

import flash.geom.Point;
import flash.geom.Rectangle;

import mx.collections.ArrayCollection;

import org.papervision3d.core.geom.renderables.Vertex3D;

public class ConversionUtil
{
	/* This function accepts an array of Geometry elements and returns an array of
	   triangles for use in making the 3D model. */
	public static function convertGeometryTo3D(geometry:Array):Array
	{
		var polygons:ArrayCollection = new ArrayCollection();
		var polygon:Array = [];
		
		// First convert all types of geometry (curve, rect, ellipse) that aren't lines to lines
		// Also for cubes or spheres, once they are converted to lines add a polygon to the list
		var temp:ArrayCollection = new ArrayCollection(geometry);
		var rect:RegularRectangle;
		var x:Number, y:Number;
		for(x= 0; x < temp.length; x++)
		{
			var geom:Geometry = temp.getItemAt(x) as Geometry;
			if(!(geom is Line))
			{
				var index:Number = temp.getItemIndex(geom);
				temp.removeItemAt(index);
				x--;

				if(geom is QuadraticBezier)
				{
					var lines:Array = getLinesFromCurve(geom as QuadraticBezier);
					temp.addAllAt(new ArrayCollection(lines),index);
				}
				else if(geom is RegularRectangle || geom is Ellipse)
				{
					polygon = [];
//					if(geom is RegularRectangle) getLinesFromRect(geom as RegularRectangle,polygon);
//					else if(geom is Ellipse) getLinesFromEllipse(geom as Ellipse,polygon);
					if(polygon.length > 0) polygons.addItem(polygon);
				}
			}
		}
		geometry = temp.toArray();
		
		var p1:Point, p2:Point, p3:Point, p4:Point;
		var head:Geometry, tail:Geometry;
		var point:Point;
		while(geometry.length > 0)
		{	
			if(polygon.length == 0)
			{
				polygon = [];
				polygons.addItem(polygon);
				polygon.push(geometry.shift());
			}
			else
			{
				var found:Boolean = false;
				tail = polygon[polygon.length-1] as Geometry;
				var length:Number = geometry.length;
				for(x = 0; x < length; x++)
				{
					var next:Geometry = geometry.shift();
					point = IntersectionUtil.intersects(tail,next);
					if(point)
					{
						polygon.push(next);
						found = true;
						break;
					}
					else
					{
						geometry.push(next);
					}
				}
				if(!found)
				{
					polygon = [];
					polygons.addItem(polygon);
				}
			}
		}
		for(x = 0; x < polygons.length; x++)
		{
			polygon = polygons.getItemAt(x) as Array;
			if(polygon.length < 3)
			{
				polygons.removeItemAt(x);
				x--;
				continue;
			}
			head = polygon[0] as Geometry;
			tail = polygon[polygon.length-1] as Geometry;
			point = IntersectionUtil.intersects(head,tail);
			if(!point)
			{
				polygons.removeItemAt(x);
				x--;
			}
			else
			{
//				trace('Polygon with',polygon.length,'sides found!');
			}
		}
		
		var points:Array = [];
		for each(polygon in polygons)
		{
			var polyPoints:Array = [];
			for(x = 0; x < polygon.length - 1; x++)
			{
				point = IntersectionUtil.intersects(polygon[x] as Geometry,polygon[x+1] as Geometry);
				polyPoints.push(point);
			}
			
			
			point = IntersectionUtil.intersects(polygon[x] as Geometry,polygon[polygon.length-1] as Geometry);
			polyPoints.push(point);
			points.push(polyPoints);
		}
		
		var tris:Array = [];
		for each(var poly:Array in points)
		{
			tris.push(TriangulationUtil.process(poly));
		}
		return tris;
	}
	
	/* This function (attempts) to convert a curve into a series of lines. */
	public static function getLinesFromCurve(curve:QuadraticBezier):Array
	{
		// y = ax^2 + bx + c
		
		var x1:Number = curve.x0;
		var y1:Number = curve.y0;
		var p1:Point = new Point(x1,y1);
		var x2:Number = curve.x1;
		var y2:Number = curve.y1;
		var p2:Point = new Point(x2,y2);
		
		var p3:Point = getMidpoint(getMidpoint(p1,p2),new Point(curve.cx,curve.cy));
		var x3:Number = p3.x;
		var y3:Number = p3.y;
		
		var obj:Object = getABC(x1,y1,x2,y2,x3,y3);
		var a:Number = obj.a, b:Number = obj.b, c:Number = obj.c;
		
		var vx:Number = -b/(2*a);
		var vy:Number = ((4*a*c) - Math.pow(b,2))/(4*a);
		var v:Point = new Point(vx,vy);
		
		var points:Array = multiplyPoints([p1,v,p2],a,b,c);
		var lines:Array = [];
		for(var x:Number = 0; x < points.length - 1; x++)
		{
			p1 = points[x] as Point;
			p2 = points[x+1] as Point;
			
			var line:Line = new Line(p1.x,p1.y,p2.x,p2.y);
			lines.push(line);
		}
		
		return lines;
	}
	
	/* Returns the "midpoint" of a curve. */
	private static function getMidPointOnCurve(p1:Point,p2:Point,a:Number,b:Number,c:Number):Point
	{
		var lineMidpoint:Point = getMidpoint(p1,p2);
		return new Point(lineMidpoint.x,getY(lineMidpoint.x,a,b,c));
	}
	
	/* Takes an array of points and multiplies them but adding midpoints from a curve. */
	private static function multiplyPoints(points:Array,a:Number,b:Number,c:Number):Array
	{
		var newPoints:ArrayCollection = new ArrayCollection();
		for(var z:Number = 0; z < points.length - 1; z++)
		{
			var point:Point = points[z] as Point;
			var next:Point = points[z+1] as Point;
			
			var mid:Point = getMidPointOnCurve(point,next,a,b,c);
			newPoints.addItem(point);
			newPoints.addItem(getMidPointOnCurve(point,mid,a,b,c));
			newPoints.addItem(mid);
			newPoints.addItem(getMidPointOnCurve(mid,next,a,b,c));
			newPoints.addItem(next);
		}
		
		return newPoints.toArray();
	}
	
	/* Returns the y value of a ax^2 + bx + c formula. */
	private static function getY(x:Number,a:Number,b:Number,c:Number):Number
	{
		return a*Math.pow(x,2) + b*x + c;
	}
	
	/* Returns the distance between two points. */
	private static function distance(p1:Point,p2:Point):Number
	{
		var x1:Number = p1.x, y1:Number = p1.y;
		var x2:Number = p2.x, y2:Number = p2.y;
		
		var xs:Number = Math.pow((x2-x1),2);
		var ys:Number = Math.pow((y2-y1),2);
		
		return Math.sqrt(xs+ys);
	}
	
	/* Returns a, b, and c values from a curve (y = ax^2+bx+c) represented by 3 points */
	private static function getABC(x1:Number,y1:Number,x2:Number,y2:Number,x3:Number,y3:Number):Object
	{
		var x1S:Number = Math.pow(x1,2);
		var x2S:Number = Math.pow(x2,2);
		var x3S:Number = Math.pow(x3,2);
		
		var a:Number = ((y2-y1)*(x1-x3) + (y3-y1)*(x2-x1))/((x1-x3)*(x2S-x1S) + (x2-x1)*(x3S-x1S));
		var b:Number = ((y2-y1) - a*(x2S-x1S)) / (x2-x1);
		var c:Number = y1 - a*x1S - b*x1;
		
		return {a: a, b: b, c: c};
	}
	
	/* Returns the midpoint between two points. */
	private static function getMidpoint(p1:Point,p2:Point):Point
	{
		var x:Number = (p2.x+p1.x)/2;
		var y:Number = (p2.y+p1.y)/2;
		return new Point(x,y);
	}
	
	/* Converts a rectangle into an array of lines. */
	public static function getLinesFromRect(rect:RegularRectangle):Array
	{
		var p1:Point = new Point(rect.x,rect.y);
		var p2:Point = new Point(rect.x,rect.y+rect.height);
		var p3:Point = new Point(rect.x+rect.width,rect.y+rect.height);
		var p4:Point = new Point(rect.x+rect.width,rect.y);
		
		return [new Line(p1.x,p1.y,p2.x,p2.y),new Line(p2.x,p2.y,p3.x,p3.y),
				new Line(p3.x,p3.y,p4.x,p4.y),new Line(p4.x,p4.y,p1.x,p1.y)];
	}
	
	/* Attempts to convert an ellipse into a series of lines. */
	public static function getLinesFromEllipse(ellipse:Ellipse):Array
	{
		var mid:Point = new Point(ellipse.x + (ellipse.width/2), ellipse.y + (ellipse.height/2));
		var left:Point = new Point(ellipse.x, ellipse.y + (ellipse.height/2));
		var right:Point = new Point(ellipse.x + ellipse.width, ellipse.y + (ellipse.height/2));
		var top:Point = new Point(ellipse.x + (ellipse.width/2), ellipse.y);
		var bottom:Point = new Point(ellipse.x + (ellipse.width/2), ellipse.y + ellipse.height);
		
		var lines:Array = [];
		var control:Point;
		var curve:QuadraticBezier;
		var obj:Object;
		var a:Number, b:Number, c:Number;
		// Create a curve using the left, right, mid and top points
		control = new Point(mid.x,mid.y - ellipse.height);
		lines = lines.concat(getLinesFromCurve(new QuadraticBezier(left.x,left.y,control.x,control.y,right.x,right.y)));
		
		// Create a curve using the left, right, mid and bottom points
		control = new Point(mid.x,mid.y + ellipse.height);
		lines = lines.concat(getLinesFromCurve(new QuadraticBezier(right.x,right.y,control.x,control.y,left.x,left.y)));
		
		return lines;
	}
}
}