/*
	The DataModel class holds variables that are used throughout the application.
    It is a singleton class, which is called through the get instance() method.
*/

package model
{
import mx.rpc.events.FaultEvent;
import mx.rpc.events.ResultEvent;
import mx.rpc.http.HTTPService;

import spark.components.Group;

import view.pv3d.ModelerPV3D;

[Bindable]
public class DataModel
{
	/* ----- Singleton ----- */
	private static const _instance:DataModel = new DataModel();
	
	public static function get instance():DataModel
	{
		return _instance;
	}
	
	public function DataModel()
	{
		if(_instance)
		{
			throw new Error("Singleton DataModel must be accessed through DataModel.instance");
		}
	}
	
	/* -------- Data ------- */
	// PopUpLayer
	public var popUpLayer:Group;
	
	// Menu
	private var menuXMLLoaded:Boolean = false;
	
	private var _menuXMLOpen:XML = new XML();
	private var _menuXMLClosed:XML = new XML();
	
	/* This is in charge of passing the correct XML to the menu.
	   If a model is open, then it uses the menuXMLOpen, otherwise
	   it uses menuXMLClosed */
	public function get menuXML():XML
	{
		if(!menuXMLLoaded)
		{
			loadMenuXML();
			menuXMLLoaded = true;
		}
		if(modelOpen)
		{
			return _menuXMLOpen;
		}
		else
		{
			return _menuXMLClosed;
		}
	}
	private function set menuXML(value:XML):void {}
	
	/* This function loads the menu xml, getting both the XML for when
	   a model is open and for when one is closed */
	private function loadMenuXML():void
	{
		var openMenu:HTTPService = new HTTPService();
		openMenu.url = "menu_model_open.xml";
		openMenu.resultFormat = "e4x";
		openMenu.addEventListener(ResultEvent.RESULT,function(event:ResultEvent):void {
			_menuXMLOpen = event.result as XML;
			menuXML = new XML();
		});
		openMenu.send();

		var closedMenu:HTTPService = new HTTPService();
		closedMenu.url = "menu_model_closed.xml";
		closedMenu.resultFormat = "e4x";
		closedMenu.addEventListener(ResultEvent.RESULT,function(event:ResultEvent):void {
			_menuXMLClosed = event.result as XML;
			menuXML = new XML();
		});
		closedMenu.send();
	}
	
	// 3D Model
	public var preview3D:ModelerPV3D;
	public var model3D:ModelerPV3D;
	
	public var modelChanged:Boolean = false;
	
	private var _modelOpen:Boolean = false;
	public function get modelOpen():Boolean { return _modelOpen; }
	public function set modelOpen(value:Boolean):void
	{
		if(_modelOpen != value)
		{
			_modelOpen = value;
			menuXML = null;
		}
	}
	
	// COLLADA
	public var colladaServiceURL:String;
	
	// Floorplan
	public var floorPlanSource:Object;
	
	// File
	public var fileName:String = "Untitled";
	public var fileNameSet:Boolean = false;
	
	// View
	public var selectedViewIndex:Number = 0;
}
}