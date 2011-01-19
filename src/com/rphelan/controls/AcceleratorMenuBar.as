/*
Copyright (c) 2008 Ryan Phelan
    http://www.rphelan.com

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

package com.rphelan.controls
{
	import com.rphelan.controls.menuClasses.Accelerator;
	import com.rphelan.controls.menuClasses.AcceleratorMenuItemRenderer;
	
	import flash.events.KeyboardEvent;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ICollectionView;
	import mx.controls.Label;
	import mx.controls.Menu;
	import mx.controls.MenuBar;
	import mx.controls.listClasses.IListItemRenderer;
	import mx.core.ClassFactory;
	import mx.core.FlexGlobals;
	import mx.events.FlexEvent;
	import mx.events.MenuEvent;
	
	import spark.components.Application;
	
	/**
	 * 	This class doesn't currently support the iconField property.
	 * 	All icons are rendered as labels, as specified by the iconFunction.
	 */
	[Exclude(name="iconField", kind="property")]

	/**
	 * 	The AcceleratorMenuBar is a MenuBar which displays windows/mac style
	 * 	accelerators next to the menu labels.
	 * 
	 * 	The Menu's 'icon' is used to display the accelerator.
	 * 
	 * 	@see com.rphelan.controls.menuClasses.AcceleratorMenuItemRenderer
	 * 	@see mx.controls.MenuBar
	 */
	public class AcceleratorMenuBar extends MenuBar
	{
		private var _accelerators:ArrayCollection;
		
		/**
		 * 	Constructor.
		 */
		public function AcceleratorMenuBar()
		{
			super();
			addEventListener(FlexEvent.CREATION_COMPLETE,acceleratorMenuBar_onCreationComplete);
		}
		
		protected function acceleratorMenuBar_onCreationComplete(event:FlexEvent):void
		{
			var application:Application = FlexGlobals.topLevelApplication as Application;
			application.addEventListener(KeyboardEvent.KEY_UP, application_onKeyUp, false, 0, true);
		}
		
		protected function application_onKeyUp(event:KeyboardEvent):void
		{
			for each(var accelerator:Accelerator in _accelerators)
			{
				if(accelerator.test(event))
				{
					handleMenuFunction(accelerator.data);
				}
			}
		}
		
		protected function handleMenuFunction(menuItem:Object):void
		{
			var e:MenuEvent = new MenuEvent(MenuEvent.ITEM_CLICK,false,true,this,null,menuItem,null,menuItem.@label);
			dispatchEvent(e);
		}
		
		override public function set dataProvider(value:Object):void
		{
			super.dataProvider = value;
			if(value is XML)
			{
				parseAccelerators(value as XML);
			}
		}
		
		private function parseAccelerators(xml:XML):void
		{
			if(!(xml is XML)) return;
			
			_accelerators = new ArrayCollection();
			
			for each( var child:XML in xml.menuparent.menuitem )
			{
				if( String(child.@accelerator) )
				{
					var item:Accelerator = Accelerator.fromString( child.@accelerator );
					item.data = child;
					_accelerators.addItem( item );
				}
			}
		}
		
		/**
		 * 	By overriding getMenuAt, we can ensure that each new Menu
		 * 	uses AcceleratorMenuItemRenderer for its itemRenderer
		 * 	and Label for all of its icons.
		 */
		public override function getMenuAt( index:int ):Menu
		{
			var menu:Menu = super.getMenuAt(index);
			menu.itemRenderer = new ClassFactory(AcceleratorMenuItemRenderer);
			menu.iconFunction = getIcon;

			return menu;
		}
		
		/**
		 * 	@private
		 * 	this is an iconFunction for a Menu
		 * 
		 * 	@return a reference to the Label class
		 */
		private function getIcon( item:Object ):Class
		{
			return Label;
		}
	}
}