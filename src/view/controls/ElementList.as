/*
	The ElementList creates and displays previews for drawn 2D elements.
    It gives the ability to hide and remove an element from the view.
*/

package view.controls
{
import com.degrafa.GeometryGroup;
import com.degrafa.IGeometry;
import com.degrafa.Surface;
import com.degrafa.core.DegrafaObject;
import com.degrafa.core.IDegrafaObject;
import com.degrafa.core.collections.DisplayObjectCollection;
import com.degrafa.geometry.Geometry;

import controller.events.GeometryChangedEvent;

import flash.display.DisplayObjectContainer;
import flash.events.MouseEvent;
import flash.utils.getQualifiedClassName;

import mx.collections.ArrayCollection;
import mx.controls.Button;
import mx.controls.List;
import mx.controls.listClasses.IListItemRenderer;
import mx.core.Application;
import mx.core.ClassFactory;
import mx.core.FlexGlobals;
import mx.core.UIComponent;
import mx.events.ListEvent;

import view.drawing.DrawingSurface;

public class ElementList extends List
{
	public var surface:DrawingSurface;
	
	private var countHash:Object = {};
	
	public function ElementList()
	{
		super();
		
		super.dataProvider = [];
		itemRenderer = new ClassFactory(GeometryElement);
	}
	
	/* This function is an override of the default.  It is used to deal
	   with mouse events on the EyeButtons and XButtons.  */
	override protected function mouseEventToItemRenderer(event:MouseEvent):IListItemRenderer
	{
		if(event.type == MouseEvent.CLICK)
		{
			var target:UIComponent = event.target as UIComponent;
			if(target)
			{
				var parent:DisplayObjectContainer = target.parent;
				while(parent != null && !(parent is GeometryElement)) parent = parent.parent;
				
				/* If the target is an EyeButton, dispatch an event to show or hide the item's
				   geometry. */
				if(target is EyeButton)
				{
					if(parent)
					{
						var geomElement:GeometryElement = parent as GeometryElement;
						var selected:Boolean = (target as EyeButton).selected;
						geomElement.data.visible = selected;
						
						var e:GeometryChangedEvent;
						
						if(selected) e = new GeometryChangedEvent(GeometryChangedEvent.GOMETRY_SHOWN);
						else e = new GeometryChangedEvent(GeometryChangedEvent.GOMETRY_HIDDEN);		
						e.geometry = (geomElement.data as ElementItem).element as Geometry;
						surface.dispatchEvent(e);
						
						invalidateList();
					}
					return null;
				}
				/* If the target is an XButton, remove the item's geometry from the drawing 
				   surface and remove this item. */
				else if(target is XButton)
				{
					if(parent && parent.hasOwnProperty("data"))
					{
						var data:ElementItem = parent["data"] as ElementItem;
						var index:int = dataProvider.getItemIndex(data);
						if(index >= 0)
						{
							(dataProvider as ArrayCollection).removeItemAt(index);
							invalidateList();
						}
						
						surface.removeGeometry(data.element);
					}
					return null;
				}
			}
			return null;
		}
		return super.mouseEventToItemRenderer(event);
	}
	
	/* This is called when a user wants to undo their last drawing, and it
	   removes the last drawn item. */
	public function undo():void
	{
		dataProvider.source.shift();
		invalidateList()
	}
	
	/* This function removes all elements. */
	public function removeAllElements():void
	{
		dataProvider.source = [];
	}
	
	/* This function is called to add a Geometry item to the ElementList.
	   It creates and ElementItem and adds it to the dataProvider. */
	public function addElement(element:Geometry):void
	{
		var className:String = getQualifiedClassName(element);
		var temp:Array = className.split("::");
		className = temp[1];
		if(className == "QuadraticBezier") className = "Curve";
		else if(className == "RegularRectangle") className = "Rectangle";
		
		if(countHash[className] == null) countHash[className] = 1;
		else countHash[className] = countHash[className] + 1;
		
		var count:Number = countHash[className];
		
		dataProvider.addItemAt(new ElementItem(element,className + " " + count),0);
		
		invalidateList();
	}
	
	/* This override blocks the user from setting the dataProvider.  It is necessary
	   because the ElementList takes care of all the dataProvider things on its own. */
	override public function set dataProvider(value:Object):void {}
}
}
import com.degrafa.IGeometry;

class ElementItem
{
	/* Variables */
	public var element:Geometry;
	public var title:String;
	public var visible:Boolean = true;
	
	/* Constructor */
	public function ElementItem(element:Geometry,title:String):void
	{
		this.element = element;
		this.title = title;
	}
	
	/* Functions */
	public function toString():String
	{
		return title;
	}
}

import com.degrafa.IGeometry;

import mx.containers.Box;
import mx.containers.HBox;
import mx.controls.Text;
import com.degrafa.geometry.Line;
import com.degrafa.geometry.Geometry;
import com.degrafa.Surface;
import com.degrafa.GeometryGroup;
import com.degrafa.paint.SolidStroke;
import flash.geom.Rectangle;
import mx.core.Application;
import mx.controls.Button;
import mx.binding.utils.BindingUtils;
import flash.filters.ColorMatrixFilter;
import flash.geom.Matrix;
import mx.controls.Spacer;
import flash.events.MouseEvent;
import com.degrafa.geometry.QuadraticBezier;
import com.degrafa.geometry.RegularRectangle;
import com.degrafa.paint.SolidFill;
import com.degrafa.geometry.Ellipse;
import view.controls.ElementList;
import mx.core.FlexGlobals;

class GeometryElement extends HBox
{
	private var geometry:Geometry;
	private var title:String;
	
	private var geometryViewer:Surface;
	private var geometryGroup:GeometryGroup;
	private var labelText:Text;
	private var visibleButton:EyeButton;
	private var closeButton:XButton;
	
	private const ELEMENT_WIDTH:Number = 50;
	private const ELEMENT_HEIGHT:Number = 50;
	
	private var surface:Surface;
	private var geomGroup:GeometryGroup;
	
	public function GeometryElement()
	{
		super();
		
		height = 55;
		setStyle("verticalAlign","middle");
		setStyle("paddingLeft",5);
		setStyle("paddingRight",5);
		verticalScrollPolicy = horizontalScrollPolicy = "off";
	}
	
	
	/* This function overrides the createChildren function and adds the view
	   items including the preview box and buttons. */
	override protected function createChildren():void
	{
		super.createChildren();
		
		if(!geometryViewer)
		{
			var holder:Box = new Box();
			holder.setStyle("borderColor",0x0);
			holder.setStyle("borderStyle","solid");
			holder.setStyle("borderThickness",1);
			addChild(holder);
			
			geometryViewer = new Surface();
			geometryViewer.setStyle("borderColor",0x0);
			geometryViewer.setStyle("borderStyle","solid");
			geometryViewer.setStyle("borderThickness",1);
			geometryViewer.width = ELEMENT_WIDTH;
			geometryViewer.height = ELEMENT_HEIGHT;
			geometryGroup = new GeometryGroup();
			geometryViewer.addChild(geometryGroup);
			holder.addChild(geometryViewer);
		}
		
		if(!labelText)
		{
			labelText = new Text();
			labelText.selectable = false;
			labelText.text = title;
			addChild(labelText);
		}
		
		if(!visibleButton)
		{
			var spacer:Spacer = new Spacer();
			spacer.percentWidth = 100;
			addChild(spacer);
			
			visibleButton = new EyeButton();
			addChild(visibleButton);
		}
		
		if(!closeButton)
		{
			closeButton = new XButton();
			addChild(closeButton);
		}
	}
	
	/* This function stops mouse click event propgation since it is handled
	   in the ElementList. */
	private function onMouseClick(event:MouseEvent):void
	{
		event.stopImmediatePropagation();
		event.stopPropagation();
	}
	
	/* This function overrides the setter for data in order to draw the GeometryObject
	   when it is set. */
	override public function set data(value:Object):void
	{
		super.data = value;
		
		if(value)
		{
			this.geometry = value.element;
			var owner:ElementList = this.owner as ElementList;
			surface = owner.surface;
			geomGroup = owner.surface.geometryGroup;
			
			labelText.text = this.title = value.title;
			
			var newGeom:Geometry;
			var width:Number, height:Number, scale:Number, minX:Number, maxX:Number, minY:Number, maxY:Number, x1:Number, y1:Number;
			var x:Number = geometry.x;
			var y:Number = geometry.y;
			if(geometry is Line)
			{
				var line:Line = geometry as Line;
				x1 = line.x1;  y1 = line.y1;
				
				width = Math.abs(x-x1);  height = Math.abs(y-y1);
				scale = Math.min(ELEMENT_WIDTH/width,ELEMENT_HEIGHT/height);
				
				if(scale < 1)
				{
					x = Math.floor(x*scale); x1 = Math.floor(x1*scale); 
					y = Math.floor(y*scale); y1 = Math.floor(y1*scale);
				}
				
				minX = Math.min(x,x1);  minY = Math.min(y,y1);
				x -= minX; x1 -= minX; y -= minY; y1 -= minY;
				
				width = Math.abs(x-x1);  height = Math.abs(y-y1);
				
				x += Math.floor((ELEMENT_WIDTH-width)/2); x1+= Math.floor((ELEMENT_WIDTH-width)/2);
				y += Math.floor((ELEMENT_HEIGHT-height)/2); y1+= Math.floor((ELEMENT_HEIGHT-height)/2);
				
				newGeom = new Line(x,y,x1,y1);
			}
			else if(geometry is QuadraticBezier)
			{
				var curve:QuadraticBezier = geometry as QuadraticBezier;
				x = curve.x0; y = curve.y0;
				x1 = curve.x1;  y1 = curve.y1;
				var cx:Number = curve.cx;
				var cy:Number = curve.cy;
				
				minX = Math.min(x,x1,cx);  maxX = Math.max(x,x1,cx);
				minY = Math.min(y,y1,cy);  maxY = Math.max(x,y,y1,cy);
				
				width = Math.abs(minX-maxX);  height = Math.abs(minY-maxY);
				scale = Math.min(ELEMENT_WIDTH/width,ELEMENT_HEIGHT/height);
				
				if(scale < 1)
				{
					x = Math.floor(x*scale); x1 = Math.floor(x1*scale); 
					y = Math.floor(y*scale); y1 = Math.floor(y1*scale);
					cx = Math.floor(cx*scale); cy = Math.floor(cy*scale);
				}
				
				minX = Math.min(x,x1,cx);  minY = Math.min(y,y1,cy);
				x -= minX; x1 -= minX; cx -= minX; y -= minY; y1 -= minY; cy -= minY;
				
				minX = Math.min(x,x1,cx);  maxX = Math.max(x,x1,cx);
				minY = Math.min(y,y1,cy);  maxY = Math.max(y,y1,cy);
				
				width = Math.abs(minX-maxX);  height = Math.abs(minY-maxY);
				x += Math.floor((ELEMENT_WIDTH-width)/2); x1 += Math.floor((ELEMENT_WIDTH-width)/2); cx += Math.floor((ELEMENT_WIDTH-width)/2);
				y += Math.floor((ELEMENT_HEIGHT-height)/2); y1 += Math.floor((ELEMENT_HEIGHT-height)/2); cy += Math.floor((ELEMENT_HEIGHT-height)/2);
				
				newGeom = new QuadraticBezier(x,y,cx,cy,x1,y1);
			}
			else if(geometry is RegularRectangle)
			{
				var rectangle:RegularRectangle = geometry as RegularRectangle;
				width = rectangle.width;
				height = rectangle.height;
				scale = Math.min(Math.abs(ELEMENT_WIDTH/width),Math.abs(ELEMENT_HEIGHT/height));
				
				if(scale < 1)
				{
					width = Math.floor(width*scale);  height = Math.floor(height*scale);
				}
				
				x = Math.floor((ELEMENT_WIDTH-width)/2);
				y = Math.floor((ELEMENT_HEIGHT-height)/2);
				
				newGeom = new RegularRectangle(x,y,width,height);
			}
			else if(geometry is Ellipse)
			{
				var ellipse:Ellipse = geometry as Ellipse;
				width = ellipse.width;
				height = ellipse.height;
				scale = Math.min(Math.abs(ELEMENT_WIDTH/width),Math.abs(ELEMENT_HEIGHT/height));
				
				if(scale < 1)
				{
					width = Math.floor(width*scale);  height = Math.floor(height*scale);
				}
				
				x = Math.floor((ELEMENT_WIDTH-width)/2);
				y = Math.floor((ELEMENT_HEIGHT-height)/2);
				
				newGeom = new Ellipse(x,y,width,height);
			}
			
			if(newGeom)
			{
				newGeom.stroke = new SolidStroke((geometry.stroke as SolidStroke).color,1,1);
				geometryGroup.geometry = [newGeom];
				
				geometryGroup.draw(null,null);
			}
		}
	}
	
	/* On update display list, it redraws the geometry and sets the geometry to the
	   desired visibility. */
	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	{
		super.updateDisplayList(unscaledWidth,unscaledHeight);
		
		if(data)
		{
			geometry.visible = visibleButton.selected = data.visible;
			
			redrawGeometry();
		}
	}
	
	/* This is called to force a redraw of the geomtry. */
	private function redrawGeometry(value:Boolean=true):void
	{
		geomGroup.draw(null,null);
	}
}

/*
	This class extends Button and adds the eye open/closed functionality.
	It is used only in the ElementsList.
*/
class EyeButton extends Button
{
	[Embed(source="assets/icons/eye.png")]
	private var eyeIcon:Class;
	
	[Embed(source="assets/icons/eye_closed.png")]
	private var eyeClosedIcon:Class;
	
	public function EyeButton()
	{
		super();
		
		selected = toggle = true;
		width = height = 15;
		
		var rLum:Number = 0.2225, gLum:Number = 0.7169, bLum:Number = 0.0606;
		var matrix:Array = [rLum, gLum, bLum, 0, 0, rLum, gLum, bLum, 0, 0, rLum, gLum, bLum, 0, 0, 0, 0, 0, 1, 0];
		filters = [new ColorMatrixFilter(matrix)];
		
		setStyle("skin",null);
		setStyle("icon",eyeClosedIcon);
		setStyle("selectedUpIcon",eyeIcon);
		setStyle("selectedDownIcon",eyeIcon);
		setStyle("selectedOverIcon",eyeIcon);
		setStyle("selectedDisabledIcon",eyeIcon);
	}
}

/*
	The XButton extends Button and adds the x image.  It is used
    only in the ElementList.
*/
class XButton extends Button
{
	[Embed(source="assets/icons/x.png")]
	private var xIcon:Class;
	
	public function XButton()
	{
		super();
		
		width = height = 10;
		setStyle("skin",null);
		setStyle("icon",xIcon);
	}
}