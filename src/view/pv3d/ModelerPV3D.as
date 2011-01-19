/*
	This function extends MouseControllPV3D in order to give mouse
	control functionality to the 3D version of the model.
*/

package view.pv3d
{
import com.degrafa.geometry.Ellipse;
import com.degrafa.geometry.Geometry;
import com.degrafa.geometry.Line;
import com.degrafa.geometry.QuadraticBezier;
import com.degrafa.geometry.RegularRectangle;
import com.degrafa.paint.SolidStroke;

import controller.events.Modeler3DEvent;

import flash.display.InteractiveObject;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.GlowFilter;
import flash.geom.Point;

import model.util.ConversionUtil;
import model.vo.Triangle;

import mx.graphics.SolidColor;
import mx.utils.ColorUtil;

import org.papervision3d.core.geom.TriangleMesh3D;
import org.papervision3d.core.geom.renderables.Triangle3D;
import org.papervision3d.core.geom.renderables.Vertex3D;
import org.papervision3d.core.math.NumberUV;
import org.papervision3d.core.utils.virtualmouse.VirtualMouseMouseEvent;
import org.papervision3d.events.InteractiveScene3DEvent;
import org.papervision3d.materials.ColorMaterial;
import org.papervision3d.materials.WireframeMaterial;
import org.papervision3d.objects.DisplayObject3D;
import org.papervision3d.scenes.Scene3D;
import org.papervision3d.view.Viewport3D;
import org.papervision3d.view.layer.ViewportLayer;

[Event(name="selectedItemChange",type="controller.events.Modeler3DEvent")]

public class ModelerPV3D extends MouseControlledPV3D
{
	private const DEFAULT_BUILDING_HEIGHT:Number = 250;
	
	[Bindable] 
	public var selectedItem:DisplayObject3D = null;
	
	[Bindable] 
	public var selectable:Boolean = false;
	
	private var mouseDownPoint:Point;
	
	public function ModelerPV3D():void
	{
		super();
		addEventListener(MouseEvent.MOUSE_DOWN,onMouseDown);
		addEventListener(MouseEvent.MOUSE_UP,onMouseUp);
	}
	
	/* Mouse down function which saves the point where the mouse was clicked. */
	private function onMouseDown(event:MouseEvent):void
	{
		mouseDownPoint = new Point(event.stageX,event.stageY);
	}

	/* Mouse up function. Loops over the display objects and removes the glow filter. */
	private function onMouseUp(event:MouseEvent):void
	{
		if(selectable)
		{
			var mouseUpPoint:Point = new Point(event.stageX,event.stageY);
			if(mouseDownPoint && mouseUpPoint.x == mouseDownPoint.x && mouseUpPoint.y == mouseDownPoint.y)
			{
				if(event.target == this && event.target == event.currentTarget)
				{
					selectedItem = null;
					for each(var do3d:DisplayObject3D in this.view.scene.children)
					{
						var layer:ViewportLayer = do3d.container;
						if(layer)
						{
							layer.filters = [];
						}
					}
				}
			}
		}
	}
	
	/* Function which converts a Geometry object into a DisplayObject3D. It then adds
	   the object to the view. */
	public function addGeometry(geometry:Geometry,width:Number=0,height:Number=0):void
	{
		var color:uint = (geometry.stroke as SolidStroke).color as uint;
		var material:ColorMaterial = new ColorMaterial(color);
		material.doubleSided = true;
		material.interactive = true;
		
		var vertices:Array = [], faces:Array = [];
		var lines:Array = getLines(geometry);
		for each(var line:Line in lines)
		{
			var x:Number = line.x - width/2;
			var y:Number = line.y - height/2;
			var x1:Number = line.x1 - width/2;
			var y1:Number = line.y1 - height/2;
			
			var v1:Vertex3D = new Vertex3D(x,DEFAULT_BUILDING_HEIGHT/2,y);
			var v2:Vertex3D = new Vertex3D(x,-DEFAULT_BUILDING_HEIGHT/2,y);
			var v3:Vertex3D = new Vertex3D(x1,DEFAULT_BUILDING_HEIGHT/2,y1);
			var v4:Vertex3D = new Vertex3D(x1,-DEFAULT_BUILDING_HEIGHT/2,y1);
			
			vertices.push(v1,v2,v3,v4);
			
			var uv:Array = [new NumberUV(),new NumberUV(),new NumberUV()];
			
			var t1:Triangle3D = new Triangle3D(null,[v1,v2,v3]); t1.uv = uv;
			var t2:Triangle3D = new Triangle3D(null,[v3,v2,v4]); t2.uv = uv;
			
			faces.push(t1,t2);
		}
		
		var poly:TriangleMesh3D = new TriangleMesh3D(material,vertices,faces,geometry.name);
		for each(var triangle:Triangle3D in faces)
		{
			triangle.instance = poly;
		}
		
		poly.rotationZ = 180;
		addDisplayObject3D(poly,geometry.name,true);
		
		poly.addEventListener(InteractiveScene3DEvent.OBJECT_CLICK, onPolyClick);
	}
	
	/* Click function for the 3D polygons. When it is selected, it adds a glow filter to the
	   display object, otherwise it removes it. */
	public function onPolyClick(event:InteractiveScene3DEvent):void
	{
		if(selectable)
		{
			for each(var do3d:DisplayObject3D in this.view.scene.children)
			{
				var layer:ViewportLayer = do3d.container;
				if(layer)
				{
					if(do3d == event.displayObject3D)
					{
						selectedItem = do3d;
						dispatchEvent(new Modeler3DEvent(Modeler3DEvent.SELECTED_ITEM_CHANGE));
						layer.filters = [new GlowFilter(0xFFFF00,1,20,4,3)];
					}
					else
					{
						layer.filters = [];
					}
				}
			}
		}
	}
	
	/* Converts a geometry into an array of lines. */
	private function getLines(geometry:Geometry):Array
	{
		if(geometry is Line) return [geometry];
		else if(geometry is QuadraticBezier) return ConversionUtil.getLinesFromCurve(geometry as QuadraticBezier);
		else if(geometry is RegularRectangle) return ConversionUtil.getLinesFromRect(geometry as RegularRectangle);
		else if(geometry is Ellipse) return ConversionUtil.getLinesFromEllipse(geometry as Ellipse);
		else return null;
		
	}
	
	/* Removes the 3D version of a geometry. */
	public function removeGeometry(geometry:Geometry):void
	{
		removeDisplayObject3DByName(geometry.name);
	}
	
	/* Hides the 3D version of a geometry that was visible. */
	public function hideGeometry(geometry:Geometry):void
	{
		var do3d:DisplayObject3D = getDisplayObject3DByName(geometry.name);
		do3d.visible = false;
	}
	
	/* Shows the 3D version of a geometry that was not visible. */
	public function showGeometry(geometry:Geometry):void
	{
		var do3d:DisplayObject3D = getDisplayObject3DByName(geometry.name);
		do3d.visible = true;
	}
}
}