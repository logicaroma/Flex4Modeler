/*
	The MenuHandlerEvent is dispatched by MenuHandler and the HeaderBar to deal with the
	cases when the model should be saved or closed.
*/

package controller.events
{
import flash.events.Event;

public class MenuHandlerEvent extends Event
{
	public static const CLOSE:String = "menuHandlerClose";
	public static const SAVE:String = "menuHandlerSave";
	public static const UNDO:String = "menuHandlerUndo";
	
	public function MenuHandlerEvent(type:String, bubbles:Boolean=true, cancelable:Boolean=false)
	{
		super(type, bubbles, cancelable);
	}
	
	override public function clone():Event
	{
		return new MenuHandlerEvent(this.type);
	}
}
}