/*
	This is a value object which represents a cylinder.
*/

package model.vo
{
import flash.geom.Point;

public class FlatCylinder extends Point
{
	public var radius:Number;
	
	public function FlatCylinder(x:Number=0, y:Number=0, radius:Number = 0)
	{
		super(x, y);
		this.radius = radius;
	}
}
}