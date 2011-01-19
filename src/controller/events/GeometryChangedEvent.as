/*
	The GeometryChangedEvent is dispatched by the DrawingSurface and/or the ElementList.  
	It is used when a geometry is added, removed, hidden or shown.
*/

package controller.events
{
import com.degrafa.geometry.Geometry;

import flash.events.Event;

public class GeometryChangedEvent extends Event
{
	public static const GEOMETRY_ADDED:String = "geometryAdded";
	public static const GEOMETRY_REMOVED:String = "geometryRemoved";
	public static const GOMETRY_HIDDEN:String = "geometryHidden";
	public static const GOMETRY_SHOWN:String = "geometryShown";
	
	public var geometry:Geometry;
	
	public function GeometryChangedEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
	{
		super(type, bubbles, cancelable);
	}
	
	override public function clone():Event
	{
		var e:GeometryChangedEvent = new GeometryChangedEvent(this.type);
		e.geometry = this.geometry;
		return e;
	}
}
}