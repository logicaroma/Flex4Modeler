/*
	This class is designed to return whether two geometry items intersect.
	** This class is not fully implemented.
*/

package model.util
{
import com.degrafa.geometry.Geometry;
import com.degrafa.geometry.Line;
import com.degrafa.geometry.QuadraticBezier;

import flash.geom.Point;

public class IntersectionUtil
{
	private static const TOLERANCE:Number = 3; // Line stroke width
	private static const EPSILON:Number = .0001;
	
	/* This is the main function which checks the types of the geometry passed in
	   and returns whether they intersect (if they do it returns the point where
	   they intersect). */
	public static function intersects(first:Geometry,second:Geometry):Point
	{
		if(first is Line)
		{
			if(second is Line)
			{
				return lineSegmentsIntersect(first as Line,second as Line);
			}
			if(second is QuadraticBezier)
			{
				return lineSegmentIntersectsCurve(first as Line,second as QuadraticBezier);
			}
		}
		else if(first is QuadraticBezier)
		{
			if(second is Line)
			{
				return lineSegmentIntersectsCurve(second as Line,first as QuadraticBezier);
			}
		}
		
		return null;
	}
	
	/* Checks whether two Lines intersect. */
	private static function lineSegmentsIntersect(first:Line,second:Line):Point
	{
		var x1:Number = first.x, x2:Number = first.x1, y1:Number = first.y, y2:Number = first.y1;
		var x3:Number = second.x, x4:Number = second.x1, y3:Number = second.y, y4:Number = second.y1;
		
		var ua:Number = ((((x4-x3)*(y1-y3))-((y4-y3)*(x1-x3)))/(((y4-y3)*(x2-x1))-((x4-x3)*(y2-y1))));
		
		var point:Point = new Point(x1 + ua*(x2-x1),y1 + ua*(y2-y1));
		
		if(pointExistsOnSegment(first,point) && pointExistsOnSegment(second,point)) return point;
		return null;
	}
	
	/* Checks whether a line intersects with a curve. */
	private static function lineSegmentIntersectsCurve(line:Line,curve:QuadraticBezier):Point
	{
		// check if the end points of the curve are on the line 
		// (easiest but not most accurate way, since it could intersect anywhere else)
		var p1:Point = new Point(curve.x0,curve.y0);
		var p2:Point = new Point(curve.x1,curve.y1);
		
		if(pointExistsOnSegment(line,p1)) return p1;
		if(pointExistsOnSegment(line,p2)) return p2;
		return null;
	}
	
	/* This function assumes that the point is somewhere on the line. */
	private static function pointExistsOnSegment(line:Line,point:Point):Boolean
	{
		var minX:Number = Math.min(line.x,line.x1) - TOLERANCE/2, maxX:Number = Math.max(line.x,line.x1) + TOLERANCE/2;
		var minY:Number = Math.min(line.y,line.y1) - TOLERANCE/2, maxY:Number = Math.max(line.y,line.y1) + TOLERANCE/2;
		
		var betweenX:Boolean = (point.x >= minX) && (point.x <= maxX);
		var betweenY:Boolean = (point.y >= minY) && (point.y <= maxY);
		
		return betweenX && betweenY;
	}
	
	/* Returns the distance between two points. */
	public static function distanceBetweenPoints(p1:Point,p2:Point):Number
	{
		return Math.sqrt(Math.pow((p2.x-p1.x),2) + Math.pow((p2.y-p1.y),2));
	}
	
	/* Returns whether a point exists in a triangle. */
	public static function pointInTriangle(t0:Point,t1:Point,t2:Point,point:Point):Boolean
	{
		var pab:Number = triangleArea(point,t0,t1);
		var pbc:Number = triangleArea(point,t1,t2);
		var pac:Number = triangleArea(point,t0,t2);
		
		var abc:Number = triangleArea(t0,t1,t2);
		
		return Math.abs(abc-(pab+pbc+pac)) < EPSILON;
	}
	
	/* Finds the area of a triangle. */
	private static function triangleArea(t0:Point,t1:Point,t2:Point):Number
	{
		var x1:Number = t0.x, y1:Number = t0.y;
		var x2:Number = t1.x, y2:Number = t1.y;
		var x3:Number = t2.x, y3:Number = t2.y;
		return Math.abs((x1*y2+x2*y3+x3*y1-x1*y3-x3*y2-x2*y1)/2);
	}
	
	/* Returns whether a point is in a rectangle. */
	public static function pointInRect(x:Number,y:Number,width:Number,height:Number,point:Point):Boolean
	{
		return point.x > x && point.y > y && point.x < (x+width) && point.y < (y+height);
	}
}
}