/* 
	This is the base class for all the Papervision3D stuff done in the project.
	It contains the render engine, viewport, scene and camera (basically giving a
    way for the AS2-like PV3D engine to be accessed through Flex). 
*/

package view.pv3d
{
import com.afw.papervision3d.view.AutoOrbitDrag;

import flash.display.DisplayObject;
import flash.events.Event;

import mx.binding.utils.BindingUtils;
import mx.collections.ArrayCollection;
import mx.core.Container;
import mx.core.FlexGlobals;
import mx.core.UIComponent;
import mx.events.ResizeEvent;

import org.papervision3d.cameras.Camera3D;
import org.papervision3d.objects.DisplayObject3D;
import org.papervision3d.render.BasicRenderEngine;
import org.papervision3d.scenes.Scene3D;
import org.papervision3d.view.BasicView;
import org.papervision3d.view.Viewport3D;
import org.papervision3d.view.layer.ViewportLayer;

public class FlexPV3D extends UIComponent
{
	/* Variables */
	protected var view:BasicView;
	
	[Bindable] public var displayObject3Ds:ArrayCollection = new ArrayCollection();
	
	private var _zoom:Number = 25;
	public function get zoom():Number { return _zoom; }
	public function set zoom(value:Number):void
	{
		if(_zoom != value)
		{
			_zoom = value;
			if(view && view.camera)
			{
				view.camera.zoom = value;
			}
		}
	}
	
	public function FlexPV3D()
	{
		super();
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}
	
	/* This is an important function for Papervision, where anything with the variables
	 * in this class should be done.  There is a very basic implementation used here
	 * and so it should be overridden for added functionality. */
	protected function onEnterFrame(event:Event):void 
	{
		view.renderer.renderScene(view.scene,view.camera,view.viewport);
	}
	
	/* Function which adds a display object to the scene. */
	public function addDisplayObject3D(child:DisplayObject3D,name:String=null,newLayer:Boolean=false):DisplayObject3D
	{
		invalidateDisplayList();
		if(newLayer)
		{
			var layer:ViewportLayer = new ViewportLayer(view.viewport,child,false);
			
			view.viewport.containerSprite.addLayer(layer);
			view.singleRender();
		}
		displayObject3Ds.addItem(child);
		return view.scene.addChild(child,name);
	}
	
	/* Function which removes a display object to the scene. */
	public function removeDisplayObject3D(child:DisplayObject3D):DisplayObject3D
	{
		invalidateDisplayList();
		displayObject3Ds.removeItemAt(displayObject3Ds.getItemIndex(child));
		return view.scene.removeChild(child);
	}
	
	/* Function which adds a display object to the scene based on the name. */
	public function removeDisplayObject3DByName(name:String):DisplayObject3D
	{
		invalidateDisplayList();
		var child:DisplayObject3D = getDisplayObject3DByName(name);
		return removeDisplayObject3D(child);
	}
	
	/* Removes all the display objects from the scene. */
	public function removeAllDisplayObject3D():void
	{
		while(displayObject3Ds.length > 0)
		{
			removeDisplayObject3D(displayObject3Ds.getItemAt(0) as DisplayObject3D);
		}
	}
	
	/* Returns a display object from the scene based on the name. */
	public function getDisplayObject3DByName(name:String):DisplayObject3D
	{
		return view.scene.getChildByName(name);
	}
	
	/* Overrides the create children function in order to add the BasicView. */
	override protected function createChildren():void
	{
		super.createChildren();
		
		if(!view)
		{
			view = new BasicView();
			view.camera.zoom = zoom;
			view.viewport.interactive = true;
			addChild(view.viewport);
		}
	}
	
	/* Overrides update display list in order to set the width and height of the viewport. */
	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	{
		super.updateDisplayList(unscaledWidth, unscaledHeight);
		
		graphics.clear();
		graphics.beginFill(0xffffff);
		graphics.drawRect(0,0,width,height);
		
		(parent as UIComponent).validateNow();
		var w:Number = parent.width == 0 ? FlexGlobals.topLevelApplication.width : parent.width;
		var h:Number = parent.height == 0 ? FlexGlobals.topLevelApplication.height : parent.height;
		
		if(view.viewport.width != w) width = view.viewport.width = w;
		if(view.viewport.height != h) height = view.viewport.height = h;
	}
}
}