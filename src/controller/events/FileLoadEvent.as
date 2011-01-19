/*
	The FileLoadEvent is used by the FileLoadPopUp in order to load an iamge or COLLADA file.
*/

package controller.events
{
import flash.events.Event;

public class FileLoadEvent extends Event
{
	public static const IMAGE:String = "image";
	public static const COLLADA:String = "collada";
	
	public var source:Object;
	
	public function FileLoadEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
	{
		super(type, bubbles, cancelable);
	}
}
}