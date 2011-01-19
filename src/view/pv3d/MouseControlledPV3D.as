/* 
   This is a class which adds mouse control functionality to the FlexPV3D class. 
   The ojbect that should be rotated should be set to this class' mouseControlled
   object. 
*/

package view.pv3d
{
import com.afw.papervision3d.view.AutoOrbitDrag;

import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Point;

import mx.core.UIComponent;

import org.papervision3d.cameras.Camera3D;
import org.papervision3d.core.proto.CameraObject3D;
import org.papervision3d.objects.DisplayObject3D;

public class MouseControlledPV3D extends FlexPV3D
{
	protected var orbiter:AutoOrbitDrag;
	
	private var orbiterChange:Boolean = false;
	private var _cameraYaw:Number;
	public function set cameraYaw(value:Number):void
	{
		_cameraYaw = value;
		orbiterChange = true;
	}
	
	private var _cameraPitch:Number;
	public function set cameraPitch(value:Number):void
	{
		_cameraPitch = value;
		orbiterChange = true;
	}
	
	/* Overrides the createChildren functon to add the AutoOrbitDrag. */
	override protected function createChildren():void
	{
		super.createChildren();
		
		if(!orbiter)
		{
			orbiter = new AutoOrbitDrag(this.view);
			orbiter.target = this;
		}
	}
	
	private var _target:UIComponent;
	public function get target():UIComponent { return _target; }
	public function set target(value:UIComponent):void
	{
		if(_target != value)
		{
			_target = orbiter.target = value;
		}
	}
	
	/* Overrides the default onEnterFrame to control the rotation of the object
	   based on the movements of the mouse. */
	override protected function onEnterFrame(event:Event):void
	{
		super.onEnterFrame(event);
		
		if(mouseEnabled) orbiter.update();
	}
	
	
	[Bindable] 
	public function get mouseDown():Boolean 
	{ 
		return orbiter.mouseDown 
	}
	public function set mouseDown(value:Boolean):void {}
	
	/* Overrides commitProperties in order to update the pitch/yaw when they
	   are explicitly set. */
	override protected function commitProperties():void
	{
		super.commitProperties();
		
		if(orbiterChange)
		{
			orbiter.forceUpdate(_cameraPitch,_cameraYaw);
			orbiterChange = false;
		}
	}
}
}