/*
	The MenuHandler is a helper singleton class which has a function (handleCommand) that
	is called to handle input from the user on the menu.
*/

package model
{
import controller.events.FileLoadEvent;
import controller.events.MenuHandlerEvent;

import flash.events.EventDispatcher;

import mx.binding.utils.BindingUtils;
import mx.controls.Alert;
import mx.events.CloseEvent;
import mx.managers.PopUpManager;

import spark.components.Group;

import view.popups.FileLoadPopUp;

[Event(name="menuHandlerClose",type="controller.events.MenuHandlerEvent")]
[Event(name="menuHandlerSave",type="controller.events.MenuHandlerEvent")]
[Event(name="menuHandlerUndo",type="controller.events.MenuHandlerEvent")]
public class MenuHandler extends EventDispatcher
{
	/* Variables */
	private var dataModel:DataModel = DataModel.instance;
	
	private var fileLoadPopUp:FileLoadPopUp;
	
	/* ----- Singleton ----- */
	private static const _instance:MenuHandler = new MenuHandler();
	
	public static function get instance():MenuHandler
	{
		return _instance;
	}
	
	public function MenuHandler()
	{
		if(_instance)
		{
			throw new Error("Singleton MenuHandler must be accessed through MenuHandler.instance");
		}
	}
	
	/* This is the main function of the class.  It takes a command (passed from the MenuBar) and
	   handles it appropriately. */
	public function handleCommand(command:String):void
	{
		if(command == "new")
		{
			if(dataModel.modelOpen)
			{
				if(dataModel.modelChanged)
				{
					closeAlert(alert_closeHandlerNewImage);
				}
				else
				{
					close(loadNewImage);
				}
			}
			else
			{
				loadNewImage();				
			}
		}
		else if(command == "load")
		{
			if(dataModel.modelOpen)
			{
				if(dataModel.modelChanged)
				{
					closeAlert(alert_closeHandlerNewCollada);
				}
				else 
				{
					close(loadNewCollada);
				}
			}
			else
			{
				loadNewCollada();
			}
		}
		else if(command == "close")
		{
			if(dataModel.modelChanged)
			{
				closeAlert(alert_closeHandler);
			}
			else
			{
				close();
			}
		}
		else if(command == "rename")
		{
			if(dataModel.modelOpen)
			{
				dataModel.fileNameSet = false;
				dispatchEvent(new MenuHandlerEvent(MenuHandlerEvent.SAVE));
			}
		}
		else if(command == "save")
		{
			if(dataModel.modelOpen && dataModel.modelChanged)
			{
				dispatchEvent(new MenuHandlerEvent(MenuHandlerEvent.SAVE));
			}
		}
		else if(command == "undo")
		{
			undo();
		}
		else if(command == "2d")
		{
			if(dataModel.modelOpen)
			{
				dataModel.selectedViewIndex = 0;
			}
		}
		else if(command == "3d")
		{
			if(dataModel.modelOpen)
			{
				dataModel.selectedViewIndex = 1;
			}
		}
	}
	
	/* This is called to alert the user they are about to close an unsaved model. */
	private function closeAlert(f:Function):void
	{
		Alert.show("Do you want to save the changes to your model?","",Alert.YES + Alert.NO + Alert.CANCEL,null,f);
	}
	
	/* This creates a popup to load a file.  It takes a state passed from
	   another function and a fnction that should be called. */
	private function loadNew(state:String,type:String,f:Function):void
	{
		fileLoadPopUp = new FileLoadPopUp();
		fileLoadPopUp.currentState = state;
		
		PopUpManager.addPopUp(fileLoadPopUp,dataModel.popUpLayer,true);
		PopUpManager.centerPopUp(fileLoadPopUp);
		
		fileLoadPopUp.addEventListener(type,f);
	}
	
	/* This function passes info to the loadNew function in order to create an Image
	   loading popup (for loading the floorplan). */
	private function loadNewImage():void
	{
		loadNew(FileLoadPopUp.STATE_IMAGE,FileLoadEvent.IMAGE,fileLoadPopUp_onImageLoad);
	}
	
	/* When the image is loaded from the file load pop up, it sets the floorPlanSource in the model
	   and marks the model as changed. */
	private function fileLoadPopUp_onImageLoad(event:FileLoadEvent):void
	{
		dataModel.fileName = "Untitled";
		dataModel.modelChanged = true;
		
		PopUpManager.removePopUp(fileLoadPopUp);
		dataModel.floorPlanSource = event.source;
	}
	
	/* This function passes info to the loadNew function in order to create a COLLADA
       loading popup (for loading an already created model). */
	private function loadNewCollada():void
	{
		loadNew(FileLoadPopUp.STATE_COLLADA,FileLoadEvent.COLLADA,fileLoadPopUp_onColladaLoad);
	}
	
	/* Called once the COLLADA is loaded. */
	private function fileLoadPopUp_onColladaLoad(event:FileLoadEvent):void
	{
		
	}
	
	/* This is called when the model is closed.  It is called when an option is chosen
	   from the handler above.  Based on the user's choice, it saves (and possibly loads
	   a new Image/COLLADA), cancels or closes without saving. */
	private function alert_closeHandler(event:CloseEvent,f:Function=null):void
	{
		if(event.detail == Alert.CANCEL)
		{
			return;
		}
		else
		{
			var e:MenuHandlerEvent;
			if(event.detail == Alert.YES)
			{
				e = new MenuHandlerEvent(MenuHandlerEvent.SAVE);
			} 
			else 
			{
				e = new MenuHandlerEvent(MenuHandlerEvent.CLOSE);				
			}
			
			close(f);
			dispatchEvent(e);
		}
	}
	
	/* Passes a function to the alert close handler in order to load a new
	   image after saving/closing the model. */
	private function alert_closeHandlerNewImage(event:CloseEvent):void
	{
		alert_closeHandler(event,loadNewImage);
	}
	
	/* Passes a function to the alert close handler in order to load a new
	   COLLADA after saving/closing the model. */
	private function alert_closeHandlerNewCollada(event:CloseEvent):void
	{
		alert_closeHandler(event,loadNewCollada);
	}
	
	/* Called when the user selects 'close' from the menu bar. */
	private function close(f:Function=null):void
	{
		dataModel.modelChanged = dataModel.modelOpen = false;
		dataModel.floorPlanSource = null;
		
		if(f != null)
		{
			f.call();
		}
	}
	
	/* Called when the user selects 'undo' from the menu bar. */
	private function undo():void
	{
		var event:MenuHandlerEvent = new MenuHandlerEvent(MenuHandlerEvent.UNDO);
		dispatchEvent(event);
	}
}
}