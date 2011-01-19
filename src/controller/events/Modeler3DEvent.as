/*
	The Modeler3DEvent is dispatched when the selected item of the 3D model is changed.
*/

package controller.events
{
import flash.events.Event;

public class Modeler3DEvent extends Event
{
	public static const SELECTED_ITEM_CHANGE:String = "selectedItemChange";
	
	public function Modeler3DEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
	{
		super(type, bubbles, cancelable);
	}
}
}