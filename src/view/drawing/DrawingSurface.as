package view.drawing
{
import com.degrafa.GeometryGroup;
import com.degrafa.Surface;
import com.degrafa.geometry.Ellipse;
import com.degrafa.geometry.Geometry;
import com.degrafa.geometry.Line;
import com.degrafa.geometry.QuadraticBezier;
import com.degrafa.geometry.RegularRectangle;
import com.degrafa.paint.SolidStroke;

import controller.events.GeometryChangedEvent;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.IBitmapDrawable;
import flash.events.MouseEvent;
import flash.geom.Point;

import mx.collections.ArrayCollection;
import mx.core.FlexGlobals;
import mx.core.UIComponent;
import mx.events.FlexEvent;
import mx.graphics.ImageSnapshot;

import spark.components.Group;

import view.controls.ElementList;

[Event(name="geometryAdded",type="controller.events.GeometryChangedEvent")]
[Event(name="geometryRemoved",type="controller.events.GeometryChangedEvent")]
[Event(name="geometryShown",type="controller.events.GeometryChangedEvent")]
[Event(name="geometryHidden",type="controller.events.GeometryChangedEvent")]

public class DrawingSurface extends Surface implements IBitmapDrawable
{
	/* Variables and constants */
	private var bitmapData:BitmapData;
	private var mouseDownPoint:Point;
	private var mouseDownColor:uint;
	private var currentGeometry:Geometry;
	
	private var curvePhase:String = CURVE_PHASE_LINE;
	private const CURVE_PHASE_LINE:String = "curve_phase_line";
	private const CURVE_PHASE_CURVE:String = "curve_phase_curve";

	private const X_OFFSET:Number = 1;
	private const Y_OFFSET:Number = 71;
	
	public var geometryGroup:GeometryGroup;
	public var elements:ElementList;
	public var type:String = "lineButton";
	public var color:uint;
	
	private var lastX:Number = Number.MIN_VALUE;
	private var lastY:Number = Number.MIN_VALUE;
	
	/* Constructor */
	public function DrawingSurface()
	{
		super();
		percentHeight = percentWidth = 100;
		addEventListener(FlexEvent.CREATION_COMPLETE,onCreationComplete);
	}
	
	/* Overrides */
	
	/* This is necessary to make the whole DrawingSurface accept tht mouse events.  
	   Draw a transparent color over the whole DrawingSurface. */
	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	{
		super.updateDisplayList(unscaledWidth, unscaledHeight);
		
		graphics.beginFill(0x0,0);
		graphics.drawRect(0,0,unscaledWidth,unscaledHeight);
		graphics.endFill();
	}
	
	/* Creates the GeometryGroup, which holds all the geometries. */
	override protected function createChildren():void
	{
		super.createChildren();
		if(!geometryGroup)
		{
			geometryGroup = new GeometryGroup();
			geometryGroup.percentHeight = geometryGroup.percentWidth = 100;
			geometryGroup.geometry = [];
			addChild(geometryGroup);
		}
	}
	
	/* This function is called to remove the most recently added Geometry item. */
	public function undo():void
	{
		if(type == "curveButton" && curvePhase == CURVE_PHASE_CURVE) return;
		if(geometryGroup.geometry.length == 0) return;
		
		var event:GeometryChangedEvent = new GeometryChangedEvent(GeometryChangedEvent.GEOMETRY_REMOVED);
		event.geometry = geometryGroup.geometry.shift();
		dispatchEvent(event);
		
		geometryGroup.draw(null,null);
	}
	
	/* This function is called to remove all Geometry items. */
	public function removeAllDrawing():void
	{
		geometryGroup.geometry = [];
		geometryGroup.draw(null,null);
	}
	
	/* Adds mouse listener when the DrawingSurface is created. */
	private function onCreationComplete(event:FlexEvent):void
	{
		systemManager.addEventListener(MouseEvent.MOUSE_DOWN,onMouseDown);
	}
	
	/* This is the main function of the class.  When the mouse is down, it begins to draw
	   geometry based on the selected control from the Controls2D. It does this using the
	   Geometry classes from the Degrafa library. */
	private function onMouseDown(event:MouseEvent):void
	{
		var target:Object = event.target;
		if(!enabled) return;
		while(target && !(target is UIComponent) && target.hasOwnProperty("parent"))
		{
			target = target.parent;
		}
		if(target is UIComponent && owner == target.owner)
		{
			systemManager.removeEventListener(MouseEvent.MOUSE_DOWN,onMouseDown);
			systemManager.addEventListener(MouseEvent.MOUSE_MOVE,onMouseMove);
			systemManager.addEventListener(MouseEvent.MOUSE_UP,onMouseUp);
			
			mouseDownPoint = new Point(event.stageX-(x+X_OFFSET),event.stageY-(y+Y_OFFSET));
	
			if(type == "fillButton")
			{
				bitmapData = new BitmapData(width,height); bitmapData.draw(this);
				mouseDownColor = bitmapData.getPixel(mouseDownPoint.x,mouseDownPoint.y);
				doFill(mouseDownPoint);
			}
			else
			{
				if(type == "lineButton")
				{
					currentGeometry = new Line(mouseDownPoint.x,mouseDownPoint.y,mouseDownPoint.x,mouseDownPoint.y);
					geometryGroup.geometry.unshift(currentGeometry);
				}
				else if(type == "curveButton")
				{
					if(curvePhase == CURVE_PHASE_LINE)
					{
						currentGeometry = new QuadraticBezier(mouseDownPoint.x,mouseDownPoint.y,mouseDownPoint.x,mouseDownPoint.y,mouseDownPoint.x,mouseDownPoint.y);
						geometryGroup.geometry.unshift(currentGeometry);
					}
				}
				else if(type == "rectangleButton")
				{
					currentGeometry = new RegularRectangle(mouseDownPoint.x,mouseDownPoint.y,0,0);
					geometryGroup.geometry.unshift(currentGeometry);			
				}
				else if(type == "circleButton")
				{
					currentGeometry = new Ellipse(mouseDownPoint.x,mouseDownPoint.y,0,0);
					geometryGroup.geometry.unshift(currentGeometry);
				}
				currentGeometry.stroke = new SolidStroke(color,1,3);
			}
		}
	}
	
	/* This functino is (supposed) to fill in a polygon.  Doesn't work without
	   locking up and causing an error. */
	private function doFill(point:Point):void
	{
		/*var checked:Object = new Object();
		var pixels:Array = [];
		
		while(true)
		{
			if(!point) return;
			var x:Number = point.x;
			var y:Number = point.y;
			
			if(!checked[x] || !checked[x][y])
			{
				if(!checked[x]) checked[x] = new Object();
				checked[x][y] = true;
				
				if(!checked[x+1])
				{
					checked[x+1] = new Object();
					checked[x+1][y] = false;
				}
				if(!checked[x-1])
				{
					checked[x-1] = new Object();
					checked[x-1][y] = false;
				}
				if(!checked[x][y+1]) checked[x][y+1] = false;
				if(!checked[x][y-1]) checked[x][y-1] = false;
			}
			else if(checked[x][y])
			{
				point = pixels.pop();
				continue;
			}
			
			if(y+1 < height && !checked[x][y+1] && bitmapData.getPixel(x,y+1) == mouseDownColor)
			{
				pixels.push(new Point(x,y+1));
			}
			
			if(y-1 > 0 && !checked[x][y-1] && bitmapData.getPixel(x,y-1) == mouseDownColor)
			{
				pixels.push(new Point(x,y-1));					
			}
			
			if(x-1 > 0 && !checked[x-1][y] && bitmapData.getPixel(x-1,y) == mouseDownColor)
			{
				pixels.push(new Point(x-1,y));
			}
			
			if(x+1 < width && !checked[x+1][y] && bitmapData.getPixel(x+1,y) == mouseDownColor)
			{
				pixels.push(new Point(x+1,y));
				
			}
			
			graphics.beginFill(0x0);
			graphics.drawRect(x,y,1,1);
			graphics.endFill();
			
			point = pixels.pop();
		}*/
	}
	
	/* This function is only called when a drawing has already been started.
	   It updates the ending position of the geometry based on where the user moves
	   the mouse. */
	private function onMouseMove(event:MouseEvent):void
	{
		var x:Number = event.stageX - (x+X_OFFSET);
		var y:Number = event.stageY - (y+Y_OFFSET);
		
		if(lastX != Number.MIN_VALUE && lastY != Number.MIN_VALUE)
		{
			var diffX:Number = Math.abs(lastX - x);
			var diffY:Number = Math.abs(lastY - y);
			
			if(diffX > 400 || diffY > 400)
			{
				x = lastX;
				y = lastY;
			}
		}
		
		if(y < -5) y = -5;
		
		if(type == "lineButton")
		{
			var line:Line = currentGeometry as Line;
			line.x1 = x; line.y1 = y;
		}
		else if(type == "curveButton")
		{
			var curve:QuadraticBezier = currentGeometry as QuadraticBezier;
			if(curvePhase == CURVE_PHASE_LINE)
			{
				curve.x1 = x; curve.y1 = y;
			}
			else if(curvePhase == CURVE_PHASE_CURVE)
			{
				curve.cx = x; curve.cy = y;							
			}
		}
		else if(type == "rectangleButton")
		{
			var rect:RegularRectangle = currentGeometry as RegularRectangle;
			rect.width = x - rect.x;
			rect.height = y - rect.y;
		}
		else if(type == "circleButton")
		{
			var ellipse:Ellipse = currentGeometry as Ellipse;
			ellipse.width = x - ellipse.x;
			ellipse.height = y - ellipse.y;
		}
		geometryGroup.draw(null,null);
		
		lastX = x;
		lastY = y;
	}
	
	/* This is called when the user lifts up the mouse button.  It officially adds the drawing
	   (including to the ElementList) and makes the program available to draw another geometry. */
	private function onMouseUp(event:MouseEvent):void
	{
		lastX = lastY = Number.MIN_VALUE;
		
		systemManager.removeEventListener(MouseEvent.MOUSE_MOVE,onMouseMove);
		systemManager.removeEventListener(MouseEvent.MOUSE_UP,onMouseUp);
		systemManager.addEventListener(MouseEvent.MOUSE_DOWN,onMouseDown);
		
		var e:GeometryChangedEvent;
		var mouse:Point = new Point(event.stageX-(x+X_OFFSET),event.stageY-(y+Y_OFFSET));
		if(type == "lineButton" || type == "rectangleButton" || type == "circleButton")
		{
			if(mouse.x == mouseDownPoint.x && mouse.y == mouseDownPoint.y)
			{
				geometryGroup.geometry.shift();
			}
			else
			{
				e = new GeometryChangedEvent(GeometryChangedEvent.GEOMETRY_ADDED);
				e.geometry = currentGeometry;
				elements.addElement(currentGeometry);
			}
		}
		else if(type == "curveButton")
		{
			if(curvePhase == CURVE_PHASE_CURVE)
			{
				e = new GeometryChangedEvent(GeometryChangedEvent.GEOMETRY_ADDED);
				e.geometry = currentGeometry;
				elements.addElement(currentGeometry);
				curvePhase = CURVE_PHASE_LINE;
			}
			else if(curvePhase == CURVE_PHASE_LINE)
			{
				curvePhase = CURVE_PHASE_CURVE;
			}
		}
		
		if(e)
		{
			dispatchEvent(e);
		}
	}
	
	/* This is called to remove a geometry item. It dispatches an event and has the
	   surface redraw (to visually remove the item). */
	public function removeGeometry(geometry:Geometry):void
	{
		var temp:ArrayCollection = new ArrayCollection(geometryGroup.geometry);
		var index:Number = temp.getItemIndex(geometry);
		if(index >= 0)
		{
			temp.removeItemAt(index);
			geometryGroup.geometry = temp.toArray();
			
			var event:GeometryChangedEvent = new GeometryChangedEvent(GeometryChangedEvent.GEOMETRY_REMOVED);
			event.geometry = geometry;
			dispatchEvent(event);
			
			geometryGroup.draw(null,null);
		}
	}
}
}