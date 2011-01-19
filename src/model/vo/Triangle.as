/*
	This is a value object which represents a triangle.
*/

package model.vo
{
import flash.geom.Point;

public class Triangle
{
	public var p1:Point;
	public var p2:Point;
	public var p3:Point;
	
	public function Triangle(p1:Point=null,p2:Point=null,p3:Point=null)
	{
		this.p1 = p1;
		this.p2 = p2;
		this.p3 = p3;
	}
	
	public function get vertices():Array
	{
		return [p1,p2,p3];
	}
}
}