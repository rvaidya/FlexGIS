/*
	SuperPanel - A Flex Panel component with drag, resize, close, maximize 
		and minimize capabilities.
    Copyright (C) 2009  Brandon A. Meyer

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
package components.containers
{
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.text.TextLineMetrics;
import flash.utils.clearInterval;
import flash.utils.setInterval;

import mx.containers.HBox;
import mx.containers.Panel;
import mx.controls.Button;
import mx.controls.Image;
import mx.core.EdgeMetrics;
import mx.core.FlexVersion;
import mx.core.UIComponent;
import mx.core.UITextFormat;
import mx.core.mx_internal;
import mx.events.ChildExistenceChangedEvent;
import mx.events.CloseEvent;
import mx.events.FlexEvent;
import mx.events.IndexChangedEvent;
import mx.events.MoveEvent;
import mx.events.ResizeEvent;

import events.SuperPanelEvent;

use namespace mx_internal;


//--------------------------------------
//  Events
//--------------------------------------

/**
 *  Dispatched when the panel is maximized.
 *
 *  @eventType net.brandonmeyer.events.SuperPanelEvent.MAXIMIZE
 */
[Event(name="maximize", type="net.brandonmeyer.events.SuperPanelEvent")]

/**
 *  Dispatched when the panel is minimized.
 *
 *  @eventType net.brandonmeyer.events.SuperPanelEvent.MINIMIZE
 */
[Event(name="minimize", type="net.brandonmeyer.events.SuperPanelEvent")]

/**
 *  Dispatched when the panel is restored from either a minimized or 
 *  maximized state.
 *
 *  @eventType net.brandonmeyer.events.SuperPanelEvent.RESTORE
 */
[Event(name="restore", type="net.brandonmeyer.events.SuperPanelEvent")]

/**
 *  Dispatched when the panel is closed.
 *
 *  @eventType mx.events.CloseEvent.CLOSE
 */
[Event(name="close", type="mx.events.CloseEvent")]

/**
 *  Dispatched when the panel starts being dragged.
 *
 *  @eventType net.brandonmeyer.events.SuperPanelEvent.DRAG_START
 */
[Event(name="dragStart", type="net.brandonmeyer.events.SuperPanelEvent")]

/**
 *  Dispatched while the panel is being dragged.
 *
 *  @eventType net.brandonmeyer.events.SuperPanelEvent.DRAG
 */
[Event(name="drag", type="net.brandonmeyer.events.SuperPanelEvent")]

/**
 *  Dispatched when the panel stops being dragged.
 *
 *  @eventType net.brandonmeyer.events.SuperPanelEvent.DRAG_END
 */
[Event(name="dragEnd", type="net.brandonmeyer.events.SuperPanelEvent")]

/**
 *  Dispatched when the resize handle is pressed.
 *
 *  @eventType net.brandonmeyer.events.SuperPanelEvent.RESIZE_START
 */
[Event(name="resizeStart", type="net.brandonmeyer.events.SuperPanelEvent")]

/**
 *  Dispatched when the mouse is released from the resize handle.
 *
 *  @eventType net.brandonmeyer.events.SuperPanelEvent.RESIZE_END
 */
[Event(name="resizeEnd", type="net.brandonmeyer.events.SuperPanelEvent")]


//--------------------------------------
//  Styles
//--------------------------------------

/**
 *  The skin for the resize 'grip' icon.
 *
 *  @default none
 */
[Style(name="resizeGripSkin", type="Class", inherit="no")]

/**
 *  The alpha level applied during drag and resize actions.
 *
 *  @default 1
 */
[Style(name="actionAlpha", type="Number", format="Length", inherit="no")]

/**
 *  The style name for the minimize button.
 */
[Style(name="minimizeButtonStyleName", type="String", inherit="no")]

/**
 *  The style name for the maximize button.
 */
[Style(name="maximizeButtonStyleName", type="String", inherit="no")]

/**
 *  The style name for the close button.
 */
[Style(name="closeButtonStyleName", type="String", inherit="no")]

/**
 *  Header colors to be applied when the panel is not in front.
 */
[Style(name="inactiveHeaderColors", type="Array", inherit="no")]

/**
 *  Highlight alphas to be applied when the panel is not in front.
 */
[Style(name="inactiveHighlightAlphas", type="Array", inherit="no")]

/**
 *  Footer colors to be applied when the panel is not in front.
 */
[Style(name="inactiveFooterColors", type="Array", inherit="no")]

/**
 *  Border color to be applied when the panel is not in front.
 */
[Style(name="inactiveBorderColor", type="uint", format="Color", inherit="no")]

/**
 *  Border alpha to be applied when the panel is not in front.
 */
[Style(name="inactiveBorderAlpha", type="Number", format="Length", inherit="no")]

/**
 *  Title style to be applied when the panel is not in front.
 */
[Style(name="inactiveTitleStyleName", type="String", inherit="no")]

/**
 *  Title style to be applied when the panel is not in front.
 */
[Style(name="inactiveShadowDistance", type="Number", format="Length", inherit="no")]



/**
 *  A Panel container that has the added functionality of drag, minimize,
 *  maximize, resize and close.
 *  
 *  @mxml
 *  
 *  <p>The <code>&lt;SuperPanel&gt;</code> tag inherits all of the tag 
 *  attributes of its superclass and adds the following tag attributes:</p>
 *  
 *  <pre>
 *  &lt;SuperPanel
 *   <strong>Properties</strong>
 *   allowClose="true|false"
 *   allowDrag="true|false"
 *   allowMaximize="true|false"
 *   allowMinimize="true|false"
 *   allowResize="true|false"
 *   sizeRatio="1:1"
 *   &gt;
 *      ...
 *      <i>child tags</i>
 *      ...
 *  &lt;/SuperPanel&gt;
 *  </pre>
 *  
 *  @see mx.containers.Panel
 * 
 *  @internal
 *  
 *  Version: 1.3.2
 * 
 *  TODOs:
 * 		- Add a minimized width.
 * 			Maybe need to do something like 'minimizeMode' and have values
 * 			like 'shade' or 'dock' that would determine whether to use a
 * 			docking position when minimized or just shrink in place to the 
 * 			height of the titlebar.
 * 		- Add a 'minimize to' location. (i.e. top-right, top, top-left, etc...)
 * 			Would require some sort of a manager so that the panel would not
 * 			overlap another minimized panel.
 * 		- Add ability to set the anchoring of the title bar's buttons.
 * 			(i.e. left or right)
 *      - Add ability to re-arrange title bar's buttons.
 * 		- Add ability to change title bar double-click function.
 *      - If minimize() is called on creationComplete and a resizeEffect is set,
 *          the first transition will be screwed up due to attempting to set the
 *          height to NaN. Need to fix this. As a workaround, explicitly set the
 *          height of the panel.
 */
public class SuperPanel extends Panel
{
    //--------------------------------------------------------------------------
    //
    //  Class constants
    //
    //--------------------------------------------------------------------------
    
    /**
     *  The default alpha value to set on the panel while dragging or resizing.
     * 
     *  @private
     */
    static private const DEFAULT_ACTION_ALPHA:Number = 1;
    
    /**
     *  Array of style names to clear while dragging or resizing and
     * 	restore once the operation has completed.
     * 
     *  Not intended for constraints. (i.e. top, bottom, right, left)
     * 
     *  @private
     */
    static private const SAVED_STYLES:Array = ["moveEffect", 
                                               "resizeEffect"];
    
    /**
     *  Array of property names that we intend on altering while dragging 
     *  or resizing and plan to restore to their original values once the 
     *  operation has completed.
     * 
     *  @private
     */
    static private const SAVED_PROPERTIES:Array = ["alpha"];
    
    /**
     *  Array of styles that we intend on altering based on the panel's index.
     *  Using the naming convention: inactive<StyleName> in the style 
     *  declarations above will allow the panel to automatically parse this
     *  array and preserve and restore these styles.
     * 
     *  @private
     */
    static private const INDEX_BASED_STYLES:Array = ["headerColors", 
    												 "footerColors",
    												 "borderColor",
    												 "borderAlpha",
    												 "highlightAlphas",
    												 "titleStyleName",
    												 "shadowDistance"];
    
    /**
     *  Regular expression for validating the sizeRatio property.
     * 
     *  @private
     */
    static private const SIZE_RATIO_FORMAT:RegExp = 
    	/^(?!^0*$)(?!^0*\.0*$)^\d{1,2}(\.\d{1,2})?\:(?!0*$)(?!0*\.0*$)\d{1,2}(\.\d{1,2})?$/;
    
    
    
    //--------------------------------------------------------------------------
    //
    //  Class variables
    //
    //--------------------------------------------------------------------------
    
    /**
     *  Amount of time in milliseconds to wait during a move or resize to
     *  ensure that the transition has completed before calling an end 
     *  handler function.
     * 
     *  @private
     */
    static private var TRANSITION_END_WAIT:Number = 500;
    
    
    
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------
    
    /**
     *  Constructor
     */
    public function SuperPanel()
    {
    	super();
    	
    	this.addEventListener(FlexEvent.CREATION_COMPLETE, 
                              creationCompleteHandler);
        
        this.addEventListener(Event.ADDED_TO_STAGE,
                              addedToStageHandler);
    	
    	this.addEventListener(MoveEvent.MOVE,
                              moveAndResizeHandler);
    	
    	this.addEventListener(ResizeEvent.RESIZE,
                              moveAndResizeHandler);
        
        this.addEventListener(FlexEvent.REMOVE, 
        					  removedHandler);
        
    	_showCloseButton = false;
    	
    	// Preserve original styling so that we can apply index-based 
    	// styling later.
    	preserveOriginalIndexBasedStyles();
    }
    
    
    
    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------
    
    //----------------------------------
    //  allowClose
    //----------------------------------
    
    /**
     *  @private
     */
    private var _allowClose:Boolean = false;
    
    /**
     *  Indicates whether the panel will show the close 
     * 	button.
     */
    [Bindable]
    public function set allowClose(value:Boolean):void
    {
    	if (_allowClose == value)
    		return;
    	
    	_allowClose = value;
    	
    	invalidateProperties();
    }
    
    /**
     *  @private
     */
    public function get allowClose():Boolean
    {
    	 return _allowClose;
    }
    
    
    //----------------------------------
    //  allowMaximize
    //----------------------------------
    
    /**
     *  @private
     */
    private var _allowMaximize:Boolean = false;
    
    /**
     *  Indicates whether the panel will show the maximize 
     * 	button.
     */
    [Bindable]
    public function set allowMaximize(value:Boolean):void
    {
    	if (_allowMaximize == value)
    		return;
    	
    	_allowMaximize = value;
    	
    	invalidateProperties();
    }
    
    /**
     *  @private
     */
    public function get allowMaximize():Boolean
    {
    	 return _allowMaximize;
    }
    
    
    //----------------------------------
    //  allowMinimize
    //----------------------------------
    
    /**
     *  @private
     */
    private var _allowMinimize:Boolean = false;
    
    /**
     *  Indicates whether the panel will show the minimize 
     * 	button.
     */
    [Bindable]
    public function set allowMinimize(value:Boolean):void
    {
    	if (_allowMinimize == value)
    		return;
    	
    	_allowMinimize = value;
    	
    	invalidateProperties();
    }
    
    /**
     *  @private
     */
    public function get allowMinimize():Boolean
    {
    	 return _allowMinimize;
    }
    
    
    //----------------------------------
    //  allowDrag
    //----------------------------------
    
    /**
     *  @private
     */
    private var _allowDrag:Boolean = false;
    
    /**
     *  Indicates whether the panel is allowed to be
     *  dragged by its titlebar.
     */
    [Bindable]
    public function set allowDrag(value:Boolean):void
    {
    	if (_allowDrag == value)
    		return;
    	
    	_allowDrag = value;
    	
    	invalidateProperties();
    }
    
    /**
     *  @private
     */
    public function get allowDrag():Boolean
    {
    	 return _allowDrag;
    }
    
    
    //----------------------------------
    //  allowResize
    //----------------------------------
    
    /**
     *  @private
     */
    private var _allowResize:Boolean = false;
    
    /**
     *  Indicates whether the panel can be resized by
     *  dragging the lower-right corner of the control.
     */
    [Bindable]
    public function set allowResize(value:Boolean):void
    {
    	if (_allowResize == value)
    		return;
    	
    	_allowResize = value;
    	
    	invalidateProperties();
    }
    
    /**
     *  @private
     */
    public function get allowResize():Boolean
    {
    	return _allowResize;
    }
    
    
    //----------------------------------
    //  sizeRatio
    //----------------------------------
    
    /**
     *  @private
     */
    private var _sizeRatio:String = null;
    
    /**
     *  Size constraint ratio to maintain while resizing the panel.
     */
    [Bindable]
    public function set sizeRatio(value:String):void
    {
    	if (_sizeRatio == value)
    		return;
    	
		if (value && !SIZE_RATIO_FORMAT.test(value))
		{
			throw new Error("sizeRatio must contain 2 numbers " + 
							"separated by a colon. (i.e. '2.35:3')");
		}
		else if (value)
		{
    		_sizeRatioWidth = parseFloat(value.split(":")[0]);
    		_sizeRatioHeight = parseFloat(value.split(":")[1]);
    	}
    	
    	_sizeRatio = value;
    	
    	if (value)
    		checkSizeRatio();
    }
    
    /**
     *  @private
     */
    public function get sizeRatio():String
    {
    	return _sizeRatio;
    }
    
    
    /**
     *  Indicates whether the panel is currently minimized.
     */
    public function get minimized():Boolean
    {
    	return isMinimized;
    }
    
    /**
     *  Indicates whether the panel is currently maximized.
     */
    public function get maximized():Boolean
    {
    	return isMaximized;
    }
    
    /**
     *  Indicates whether panel is allowed to perform a resize action.
     * 
     *  If we attempt to move or resize while there are active effects
     *  the panel may not behave as expected.
     */
    protected function get canAnimate():Boolean
    {
    	return (!activeEffects || activeEffects.length == 0);
    }
    
    // Children
    protected var buttonContainer:HBox;
    protected var closeButton:Button;
    protected var maximizeButton:Button;
    protected var minimizeButton:Button;
    protected var resizeHitBox:Image;
    
    // States
    protected var isMaximized:Boolean = false;
    protected var isMinimized:Boolean = false;
    
    // Restore dimensions
    protected var maximizeRestoreRect:Rectangle;
    protected var minimizeRestoreRect:Rectangle;
    
    
    
    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private
     */
    private var _originalIndexBasedStyles:Object = {};
    
    /**
     *  @private
     */
    private var _isResizing:Boolean = false;
    
    /**
     *  @private
     */
    private var _isDragging:Boolean = false;
    
    /**
     *  @private
     */
    private var _originalProperties:Object;
    
    /**
     *  @private
     */
    private var _originalStyles:Object;
    
    /**
     *  @private
     */
    private var _resizeCursorID:int;
    
    /**
     *  @private
     */
    private var _transitionEndInterval:Number;
    
    /**
     *  @private
     */
    private var _resizeGripSkinChanged:Boolean = true;
    
    /**
     *  @private
     */
    private var _closeButtonStyleChanged:Boolean = true;
    
    /**
     *  @private
     */
    private var _maximizeButtonStyleChanged:Boolean = true;
    
    /**
     *  @private
     */
    private var _minimizeButtonStyleChanged:Boolean = true;
    
    /**
     *  @private
     */
    private var _indexChanged:Boolean = true;
    
    /**
     *  @private
     */
    private var _sizeRatioWidth:Number;
    
    /**
     *  @private
     */
    private var _sizeRatioHeight:Number;
    
    
    
    //--------------------------------------------------------------------------
    //
    //  Event handlers
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     */
    private function creationCompleteHandler(event:FlexEvent):void
    {
    	this.addEventListener(MouseEvent.MOUSE_DOWN,
    						  mouseDownHandler);
    	
    	titleBar.addEventListener(MouseEvent.MOUSE_DOWN, 
    							  titleBar_mouseDownHandler);
    	
    	titleBar.doubleClickEnabled = true;
    	titleBar.addEventListener(MouseEvent.DOUBLE_CLICK,
    							  titleBar_doubleClickHandler);
    	
    	systemManager.addEventListener(Event.DEACTIVATE,
    	                               stopAllHandler);
    	
    	systemManager.addEventListener(MouseEvent.MOUSE_UP,
    								   systemManager_mouseUpHandler);
    	
    	// Make sure to validate our size if we have a sizeRatio
    	if (sizeRatio)
 			checkSizeRatio();
    }
    
    /**
     *  @private
     */
    private function addedToStageHandler(event:Event):void
    {
        stage.addEventListener(Event.MOUSE_LEAVE,
                               stopAllHandler);
    
    	this.parent.addEventListener(IndexChangedEvent.CHILD_INDEX_CHANGE,
    								 parent_indexChangeHandler);
		
 		this.parent.addEventListener(ChildExistenceChangedEvent.CHILD_ADD,
 									 parent_indexChangeHandler);
		
		this.parent.addEventListener(ChildExistenceChangedEvent.CHILD_REMOVE,
 									 parent_indexChangeHandler);
    }
    
    /**
     *  @private
     */
    private function removedHandler(event:Event):void
    {
    	this.removeEventListener(event.type, removedHandler);
		
    	systemManager.removeEventListener(Event.DEACTIVATE,
    									  stopAllHandler);
    	
    	systemManager.removeEventListener(MouseEvent.MOUSE_UP,
    									  systemManager_mouseUpHandler);
    	
    	systemManager.removeEventListener(MouseEvent.MOUSE_MOVE,
    									  systemManager_mouseMoveHandler);
    	
    	try
    	{
	    	stage.removeEventListener(Event.MOUSE_LEAVE,
	    							  stopAllHandler);
    	}
    	catch (e:Error) {}
    	
    	try
    	{
    		this.parent.removeEventListener(IndexChangedEvent.CHILD_INDEX_CHANGE,
    										parent_indexChangeHandler);
    		
    		this.parent.removeEventListener(ChildExistenceChangedEvent.CHILD_ADD,
    										parent_indexChangeHandler);
    		
    		this.parent.removeEventListener(ChildExistenceChangedEvent.CHILD_REMOVE,
    										parent_indexChangeHandler);
    	}
    	catch (e:Error) {}
    	
    	maximizeRestoreRect = null;
    	minimizeRestoreRect = null;
    	
    	_originalIndexBasedStyles = null;
    	_originalProperties = null;
    	_originalStyles = null;
    }
    
    /**
     *  @private
     */
    private function parent_indexChangeHandler(event:*):void
    {
    	_indexChanged = true;
    	
    	invalidateProperties();
    }
    
    /**
     *  @private
     */
    private function moveAndResizeHandler(event:*):void
    {
    	if (!canAnimate)
    	{
    		clearInterval(_transitionEndInterval);
    		_transitionEndInterval = setInterval(updateRestoreRect, TRANSITION_END_WAIT);
    	}
    	else if (_isDragging)
    	{
    	    updateRestoreRect();
    	}
    }
    
    /**
     *  @private
     */
    private function titleBar_doubleClickHandler(event:MouseEvent):void
    {
    	if (_allowMaximize)
    		toggleMaximize();
    }
    
    /**
     *  @private
     */
    private function mouseDownHandler(event:MouseEvent):void
    {
    	try
    	{
    		this.parent.setChildIndex(this, this.parent.numChildren - 1);
    	}
    	catch (e:Error) {}
    }
    
    /**
     *  @private
     */
    private function titleBar_mouseDownHandler(event:MouseEvent):void
    {
    	if (!allowDrag)
    		return;
    	
    	titleBar.addEventListener(MouseEvent.MOUSE_MOVE, 
    							  titleBar_mouseMoveHandler);
    	
    	titleBar.addEventListener(MouseEvent.MOUSE_UP, 
    							  titleBar_mouseUpHandler);
		
		var myEvent:SuperPanelEvent = new SuperPanelEvent(SuperPanelEvent.DRAG_START);
    	dispatchEvent(myEvent);
    }
    
    /**
     *  @private
     */
    private function titleBar_mouseUpHandler(event:*):void
    {
    	if (!allowDrag)
    		return;
    	
    	titleBar.removeEventListener(MouseEvent.MOUSE_MOVE, 
    								 titleBar_mouseMoveHandler);
    	
    	titleBar.removeEventListener(MouseEvent.MOUSE_UP, 
    								 titleBar_mouseUpHandler);
    	
    	this.stopDrag();
    	
    	_isDragging = false;
        
    	restoreOriginalProperties();
    	callLater(restoreOriginalStyles);
    	
    	updateRestoreRect();
    	
    	var myEvent:SuperPanelEvent = new SuperPanelEvent(SuperPanelEvent.DRAG_END);
    	dispatchEvent(myEvent);
    }
    
    /**
     *  @private
     */
    private function titleBar_mouseMoveHandler(event:MouseEvent):void
    {
    	if (this.width < this.parent.width)
    	{
    		if (!_isDragging)
    		{
    			preserveOriginalProperties();
    			preserveOriginalStyles();
                
        		// If we don't clear out the constraints, the panel will jump to an
        		// old constraint value when minimizing/restoring.
        		this.clearStyle("top");
        		this.clearStyle("bottom");
        		this.clearStyle("left");
        		this.clearStyle("right");
        		
        		this.alpha = getActionAlpha();
        		this.startDrag(false, new Rectangle(0, 
        											0, 
        											parent.width - this.width, 
        											parent.height - this.height));
        		
        		_isDragging = true;
    		}
    	}
    	
    	var myEvent:SuperPanelEvent = new SuperPanelEvent(SuperPanelEvent.DRAG);
    	dispatchEvent(myEvent);
    }
    
    /**
     *  @private
     */
    private function closeButton_clickHandler(event:MouseEvent):void
    {
    	dispatchEvent(new CloseEvent(CloseEvent.CLOSE));
    }
    
    /**
     *  @private
     */
    private function maximizeButton_clickHandler(event:MouseEvent):void
    {
    	toggleMaximize();
    }
    
    /**
     *  @private
     */
    private function minimizeButton_clickHandler(event:MouseEvent):void
    {
    	toggleMinimize();
    }
    
    /**
     *  @private
     */
    private function systemManager_mouseMoveHandler(event:MouseEvent):void
    {
    	if (_isResizing)
    	{
    		var globalXY:Point = localToGlobal(new Point(0, 0));
    		var myPt:Point = new Point(parent.width, parent.height);
    		var globalParentWH:Point = parent.localToGlobal(myPt);
    		
    		var tmpWidth:Number;
    		var tmpHeight:Number;
    		var tmpMaxHeight:Number = (globalParentWH.y - globalXY.y);
    		var tmpMaxWidth:Number = (globalParentWH.x - globalXY.x);
    		var tmpMinWidth:Number = Math.max(UIComponent.DEFAULT_MEASURED_MIN_WIDTH,
    										  buttonContainer.width);
    		
    		var tmpMinHeight:Number = Math.max(UIComponent.DEFAULT_MEASURED_MIN_HEIGHT,
    										   this.minHeight);
    		
			tmpWidth = Math.min(tmpMaxWidth, 
								Math.max(Math.max(tmpMinWidth, this.minWidth), 
										 (stage.mouseX - globalXY.x)));
    		
    		if (sizeRatio)
    		{
	    		checkSizeRatio(tmpWidth);
	    		return;
    		}
    		// No sizeRatio - just a regular resize
    		else
    		{
	    		if (((stage.mouseY - globalXY.y) > this.minHeight))
	    		{
	    			tmpHeight = Math.min(tmpMaxHeight, (stage.mouseY - globalXY.y));
	    		}
    		}
    		
    		// Apply our new dimensions if applicable
    		if (!isNaN(tmpWidth))
	    		this.width = tmpWidth;
	    	
	    	if (!isNaN(tmpHeight))
	    		this.height = tmpHeight;
    	}
    }
    
    /**
     *  @private
     */
    private function systemManager_mouseUpHandler(event:MouseEvent):void
    {
    	if (_isResizing)
    	{
    		_isResizing = false;
    		
    		// TODO: Remove resize mouse cursor
    		
    		restoreOriginalProperties();
    		callLater(restoreOriginalStyles);
    		
    		systemManager.removeEventListener(MouseEvent.MOUSE_MOVE,
    								 		  systemManager_mouseMoveHandler);
    		
    		var myEvent:SuperPanelEvent = new SuperPanelEvent(SuperPanelEvent.RESIZE_END);
    		dispatchEvent(myEvent);
    	}
    	
    	if (_isDragging)
    	    titleBar_mouseUpHandler(event);
    }
    
    /**
     *  @private
     */
    private function stopAllHandler(event:*):void
    {
        if (_isDragging)
            titleBar_mouseUpHandler(null);
        
        if (_isResizing)
            systemManager_mouseUpHandler(null);
    }
    
    /**
     *  @private
     */
    private function resizeHitBox_mouseOverHandler(event:MouseEvent):void
    {
    	if (!_allowResize || isMinimized)
    		return;
    	
    	resizeHitBox.addEventListener(MouseEvent.MOUSE_DOWN,
    								  resizeHitBox_mouseDownHandler);
    	
    	// TODO: Set resize mouse cursor
    }
    
    /**
     *  @private
     */
    private function resizeHitBox_mouseOutHandler(event:MouseEvent):void
    {
    	if (_isResizing)
    		return;
    	
    	// TODO: Remove resize mouse cursor
    }
    
    /**
     *  @private
     */
    private function resizeHitBox_mouseDownHandler(event:MouseEvent):void
    {
    	if (!_allowResize)
    		return;
    	
    	_isResizing = true;
    	
    	preserveOriginalProperties();
    	preserveOriginalStyles();
    	
    	this.alpha = getActionAlpha();
    	
    	systemManager.addEventListener(MouseEvent.MOUSE_MOVE,
    						  		   systemManager_mouseMoveHandler);
    	
    	var myEvent:SuperPanelEvent = new SuperPanelEvent(SuperPanelEvent.RESIZE_START);
    	dispatchEvent(myEvent);
    }
    
    
    
    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------
    
    /**
     *  Minimize the panel.
     */
    public function minimize():void
    {
    	if (!canAnimate)
    		return;
    	
    	isMinimized = true;
    	isMaximized = false;
    	
    	/*
    	 If we try to call this too soon it will screw up our first transition
    	 so we'll hold off unless we have the properties set.
    	*/
    	updateRestoreRect();
        
    	
    	if (minimizeRestoreRect)
        	this.width = minimizeRestoreRect.width;
    	this.height = titleBar.height;
    	
    	var myEvent:SuperPanelEvent = new SuperPanelEvent(SuperPanelEvent.MINIMIZE);
    	dispatchEvent(myEvent);
    }
    
    /**
     *  Restore the panel from a minimized state.
     */
    public function minimizeRestore():void
    {
    	if (!canAnimate)
    		return;
    	
    	if (minimizeRestoreRect)
    	{
    		this.move(minimizeRestoreRect.x, minimizeRestoreRect.y);
    		
    		this.width = minimizeRestoreRect.width;
    		this.height = minimizeRestoreRect.height;
    	}
    	else
    	{
    		this.height = Math.max(titleBar.height, this.measuredMinHeight);
    	}
    	
    	isMinimized = false;
    	
    	var myEvent:SuperPanelEvent = new SuperPanelEvent(SuperPanelEvent.RESTORE);
    	dispatchEvent(myEvent);
    }
    
    /**
     *  Toggle the minimized state for the panel.
     */
    public function toggleMinimize():void
    {
    	if (isMinimized)
    		minimizeRestore();
    	else
    		minimize();
    }
    
    /**
     *  Maximize the panel.
     */
    public function maximize():void
    {
    	if (!canAnimate)
    		return;
    	
    	isMaximized = true;
    	isMinimized = false;
    	
    	maximizeRestoreRect = new Rectangle(this.x, 
    										this.y, 
    										this.width, 
    										this.height);
    	
    	this.move(0, 0);
    	
    	this.height = this.parent.height;
    	this.width = this.parent.width;
    	
    	var myEvent:SuperPanelEvent = new SuperPanelEvent(SuperPanelEvent.MAXIMIZE);
    	dispatchEvent(myEvent);
    }
    
    /**
     *  Restore the panel from a maximized state.
     */
    public function maximizeRestore():void
    {
    	if (!canAnimate)
    		return;
    	
    	if (isMinimized)
    	{
    		minimizeRestore();
    	}
    	else
    	{
    		var desiredHeight:Number;
    		var desiredWidth:Number;
    		
    		if (maximizeRestoreRect)
    		{
    			desiredWidth = maximizeRestoreRect.width;
    			desiredHeight = maximizeRestoreRect.height;
    		}
    		else
    		{
    			desiredWidth = this.minWidth;
    			desiredHeight = this.minHeight;
    		}
    		
    		if (maximizeRestoreRect)
	    		this.move(maximizeRestoreRect.x, maximizeRestoreRect.y);
    		
    		// Find out if we're going back to our minimized state.
    		// If so, restore from the minimize dimensions
    		if (desiredHeight == titleBar.height)
    		{
    			desiredWidth = minimizeRestoreRect.width;
    			desiredHeight = minimizeRestoreRect.height;
    		}

    		this.width = desiredWidth;
    		this.height = desiredHeight;
    	}
    	
    	isMaximized = false;
    	
    	var myEvent:SuperPanelEvent = new SuperPanelEvent(SuperPanelEvent.RESTORE);
    	dispatchEvent(myEvent);
    }
    
    /**
     *  Toggle the minimized state for the panel.
     */
    public function toggleMaximize():void
    {
    	if (maximized)
    		maximizeRestore();
    	else
    		maximize();
    }
    
    /**
     *  Returns a Rectangle containing the largest piece of header
     *  text (can be either the title or status, whichever is bigger).
     * 
     * 	Copied from Panel.measureHeaderTest() for use in measure().
     * 
     *  @private
     */
    private function measureHeaderText():Rectangle
    {
        var textWidth:Number = 20;
        var textHeight:Number = 14;
    
        var textFormat:UITextFormat;
        var metrics:TextLineMetrics;
        
        if (titleTextField && titleTextField.text)
        {
            titleTextField.validateNow();
            textFormat = titleTextField.getUITextFormat();
            metrics = textFormat.measureText(titleTextField.text, false);
            textWidth = metrics.width;
            textHeight = metrics.height;
        }
        
        if (statusTextField && statusTextField.text)
        {
            statusTextField.validateNow();
            textFormat = statusTextField.getUITextFormat();
            metrics = textFormat.measureText(statusTextField.text, false);
            textWidth = Math.max(textWidth, metrics.width);
            textHeight = Math.max(textHeight, metrics.height);
        }
    
        return new Rectangle(0, 
        					 0, 
        					 Math.round(textWidth), 
        					 Math.round(textHeight));
    }
    
    /**
     *  Stores off the original values for any styles so that they
     *  can be restored later by calling <code>restoreOriginalStyles()</code>.
     * 
     *  This also clears the styles so that the panel can be moved or
     *  resized without any effects interfering with the process.
     */
    protected function preserveOriginalStyles():void
    {
    	_originalStyles = {};
    	
    	for (var i:int = 0; i < SAVED_STYLES.length; i++)
    	{
    		var val:* = SAVED_STYLES[i];
    		try
    		{
    			_originalStyles[val] = this.getStyle(val);
    			this.clearStyle(val);
    		}
    		catch (e:Error)
    		{
    			trace("Could not save style: " + val);
    		}
    	}
    }
    
    /**
     *  Restores any styles that were preserved using 
     *  <code>preserveOriginalStyles</code>.
     */
    protected function restoreOriginalStyles():void
    {
    	for (var s:String in _originalStyles)
    	{
    		try
    		{
    			this.setStyle(s, _originalStyles[s]);
    			delete _originalStyles[s];
    		}
    		catch (e:Error)
    		{
    			trace("Could not restore style: " + s);
    		}
    	}
    	
    	_originalStyles = null;
    }
    
    /**
     *  Stores off the original values for any properties that we'll be
     *  setting for a move/resize so that they can be restored later by 
     *  calling <code>restoreOriginalProperties()</code>.
     * 
     *  This also clears the styles so that the panel can be moved or
     *  resized without any effects interfering with the process.
     */
    protected function preserveOriginalProperties():void
    {
    	_originalProperties = {};
    	
    	for (var i:int = 0; i < SAVED_PROPERTIES.length; i++)
    	{
    		var val:* = SAVED_PROPERTIES[i];
    		try
    		{
    			_originalProperties[val] = this[val];
    		}
    		catch (e:Error)
    		{
    			trace("Could not save property: " + val);
    		}
    	}
    }
    
    /**
     *  Restores any properties that were preserved using 
     *  <code>preserveOriginalProperties</code>.
     */
    protected function restoreOriginalProperties():void
    {
    	for (var s:String in _originalProperties)
    	{
    		try
    		{
    			if (_originalProperties[s] is Number && 
    				!isNaN(_originalProperties[s]))
    			{
    				this[s] = _originalProperties[s];
    			}
    			else if (!_originalProperties[s] is Number)
    			{
    				this[s] = _originalProperties[s];
    			}
    			
    			delete _originalProperties[s];
    		}
    		catch (e:Error)
    		{
    			trace("Could not restore property: " + s);
    		}
    	}
    	
    	_originalProperties = null;
    }
    
    /**
     *  Stores off the original values for any styles so that they
     *  can be restored later by calling restoreOriginalIndexBasedStyles().
     * 
     *  @private
     */
    private function preserveOriginalIndexBasedStyles():void
    {
    	_originalIndexBasedStyles = {};
    	
    	for (var i:int = 0; i < INDEX_BASED_STYLES.length; i++)
    	{
    		var val:* = INDEX_BASED_STYLES[i];
    		try
    		{
    			_originalIndexBasedStyles[val] = this.getStyle(val);
    			this.clearStyle(val);
    		}
    		catch (e:Error)
    		{
    			trace("Could not save style: " + val);
    		}
    	}
    }
    
    /**
     *  Restores any styles that were preserved using 
     *  preserveOriginalIndexBasedStyles().
     * 
     *  @private
     */
    private function restoreOriginalIndexBasedStyles():void
    {
    	for (var s:String in _originalIndexBasedStyles)
    	{
    		try
    		{
    			this.setStyle(s, _originalIndexBasedStyles[s]);
    		}
    		catch (e:Error)
    		{
    			trace("Could not restore style: " + s);
    		}
    	}
    }
    
    /**
     *  @private
     */
    private function applyInactiveIndexBasedStyles():void
    {
    	for (var s:String in INDEX_BASED_STYLES)
    	{
    		var originalStyleName:String = INDEX_BASED_STYLES[s];
    		var inactiveStyleName:String = originalStyleName.substr(1, (originalStyleName.length - 1));
    		
    		// Upper-case the first letter
    		inactiveStyleName = originalStyleName.substr(0, 1).toUpperCase() + inactiveStyleName;
    		
    		// Prepend 'inactive'
    		inactiveStyleName = "inactive" + inactiveStyleName;
    		
    		this.setStyle(originalStyleName, this.getStyle(inactiveStyleName));
    	}
    }
    
    /**
     *  Perform measurement calculations based on the sizeRatio property.
     * 
     *  @private
     */
    private function checkSizeRatio(width:Number = NaN):void
    {
    	try
    	{
	    	var tmpWidth:Number;
	    	var tmpHeight:Number;
	    	
	    	if (!isNaN(width))
	    		tmpWidth = width;
	    	else
	    		tmpWidth = this.width;
	    	
	    	var globalXY:Point = localToGlobal(new Point(0, 0));
	    	var myPt:Point = new Point(parent.width, parent.height);
	    	var globalParentWH:Point = parent.localToGlobal(myPt);
	    	
	    	var tmpMaxHeight:Number = (globalParentWH.y - globalXY.y);
			var tmpMaxWidth:Number = (globalParentWH.x - globalXY.x);
			var tmpMinWidth:Number = Math.max(UIComponent.DEFAULT_MEASURED_MIN_WIDTH,
											  buttonContainer.width);
	    	var tmpMinHeight:Number = Math.max(UIComponent.DEFAULT_MEASURED_MIN_HEIGHT,
	    										   this.minHeight);
	    	
			var ratio:Number = _sizeRatioHeight / _sizeRatioWidth;
			
			tmpHeight = ratio * tmpWidth;
			
			// Will the new height cause our parent to scroll?
			if (tmpHeight > tmpMaxHeight)
			{
				// Scale both the width and height back so that the panel 
				// fits in the allowed area
				tmpHeight = tmpMaxHeight;
				tmpWidth = tmpHeight / ratio;
			}
			// Respect the minHeight
			else if (tmpHeight < tmpMinHeight)
			{
				tmpHeight = tmpMinHeight;
				tmpWidth = tmpHeight / ratio;
			}
			
			// Apply our new dimensions if applicable
			if (!isNaN(tmpWidth))
	    		this.width = tmpWidth;
	    	
	    	if (!isNaN(tmpHeight))
	    		this.height = tmpHeight;
    	}
    	catch (e:Error) {}
    }
    
    /**
     *  Updates the values inside of <code>minimizeRestoreRect</code>
     *  based on the current state of the panel.
     */
    protected function updateRestoreRect():void
    {
    	clearInterval(_transitionEndInterval);
    	
    	if (!canAnimate)
    		return;
    	
    	if (!isMinimized && !maximized)
    	{
    		minimizeRestoreRect = new Rectangle(this.x, 
    											this.y, 
    											this.width, 
    											this.height);
    	}
    	else if (minimizeRestoreRect != null)
    	{
    		// Otherwise just update the X and Y values.
    		minimizeRestoreRect.x = this.x;
    		minimizeRestoreRect.y = this.y;
    	}
    	else
    	{
    		minimizeRestoreRect = new Rectangle(this.x, 
    											this.y, 
    											Math.max(this.explicitWidth, measuredMinWidth), 
    											Math.max(this.explicitHeight, measuredMinHeight));
    	}
    }
    
    
    //----------------------------------
    // Default style accessors
    //----------------------------------
    
    /**
     *  Convenience method for retrieving the appropriate actionAlpha
     *  for the panel.
     * 
     *  Returns the default value if no style is specified.
     * 
     *  @returns The actionAlpha.
     */
    protected function getActionAlpha():Number
    {
    	var retVal:Number = this.getStyle("actionAlpha");
    	
    	if (isNaN(retVal))
    		retVal = DEFAULT_ACTION_ALPHA;
    	
    	return retVal;
    }
    
    
    
    //--------------------------------------------------------------------------
    //
    //  Overridden methods: Container
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private
     */
    override protected function layoutChrome(unscaledWidth:Number,
                                             unscaledHeight:Number):void
    {
        super.layoutChrome(unscaledWidth, unscaledHeight);
        
        var leftPadding:Number = 5;
        
        if (resizeHitBox)
    	{
    		resizeHitBox.setActualSize(
    			resizeHitBox.getExplicitOrMeasuredWidth(),
    			resizeHitBox.getExplicitOrMeasuredHeight());
    		
    		resizeHitBox.move(unscaledWidth - resizeHitBox.width,
    						  unscaledHeight - resizeHitBox.height);
    	}
    	
    	if (buttonContainer)
    	{
    		var hGap:Number = buttonContainer.getStyle("horizontalGap");
    		
    		var buttonWidths:Number = 0;
    		var maxButtonHeight:Number = 0;
    		
    		for (var i:int = 0; i < buttonContainer.numChildren; i++)
    		{
    			var child:UIComponent = buttonContainer.getChildAt(i) as UIComponent;
    			
    			if (child.includeInLayout)
    			{
    				buttonWidths += (hGap + child.width);
    				
    				if (child.height > maxButtonHeight)
    					maxButtonHeight = child.height;
    			}
    		}
    		
    		buttonContainer.setActualSize(buttonWidths, maxButtonHeight);
    		buttonContainer.move(unscaledWidth - buttonContainer.width - leftPadding,
    							 (titleBar.height - maxButtonHeight) * 0.5);
    	}
    }
    
    
    
    //--------------------------------------------------------------------------
    //
    //  Overridden methods: UIComponent
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private
     */
    override protected function createChildren():void
    {
    	super.createChildren();
    	
    	if (!buttonContainer)
    	{
    		buttonContainer = new HBox();
    		buttonContainer.setStyle("horizontalAlign", "right");
    		buttonContainer.setStyle("verticalAlign", "middle");
    		
    		titleBar.addChild(buttonContainer);
    	}
    	
    	if (!minimizeButton)
    	{
    		minimizeButton = new Button();
    		minimizeButton.width = minimizeButton.height = 16;
    		minimizeButton.toggle = true;
    		minimizeButton.addEventListener(MouseEvent.CLICK, 
    										minimizeButton_clickHandler, 
    										false, 
    										0, 
    										true);
    		
    		buttonContainer.addChild(minimizeButton);
    	}
    	
    	if (!maximizeButton)
    	{
    		maximizeButton = new Button();
    		maximizeButton.width = maximizeButton.height = 16;
    		maximizeButton.toggle = true;
    		maximizeButton.addEventListener(MouseEvent.CLICK, 
    										maximizeButton_clickHandler, 
    										false, 
    										0, 
    										true);
    		
    		buttonContainer.addChild(maximizeButton);
    	}
    	
    	if (!closeButton)
    	{
    		closeButton = new Button();
    		closeButton.width = closeButton.height = 16;
    		closeButton.addEventListener(MouseEvent.CLICK, 
    									 closeButton_clickHandler, 
    									 false, 
    									 0, 
    									 true);
    		
    		buttonContainer.addChild(closeButton);
    	}
    	
    	if (!resizeHitBox)
    	{
    		resizeHitBox = new Image();
    		
    		resizeHitBox.addEventListener(MouseEvent.MOUSE_OVER, 
    									  resizeHitBox_mouseOverHandler,
    									  false,
    									  0,
    									  true);
    		
    		resizeHitBox.addEventListener(MouseEvent.MOUSE_OUT, 
    									  resizeHitBox_mouseOutHandler,
    									  false,
    									  0,
    									  true);
    		
    		rawChildren_addChild(resizeHitBox);
    	}
    	
    	invalidateProperties();
    }
    
    /**
     *  @private
     */
    override public function styleChanged(styleProp:String):void
    {
    	super.styleChanged(styleProp);
    	
    	switch (styleProp)
    	{
    		case "resizeGripSkin":
    		{
    			_resizeGripSkinChanged = true;
    			invalidateProperties();
    			
    			break;
    		}
    		
    		case "closeButtonStyleName":
    		{
    		    _closeButtonStyleChanged = true;
    		    invalidateProperties();
    		    
    		    break;
    		}
    		
    		case "maximizeButtonStyleName":
    		{
    		    _maximizeButtonStyleChanged = true;
    		    invalidateProperties();
    		    
    		    break;
    		}
    		
    		case "minimizeButtonStyleName":
    		{
    		    _minimizeButtonStyleChanged = true;
    		    invalidateProperties();
    		    
    		    break;
    		}
    	}
    }
    
    /**
     *  @private
     */
    override protected function commitProperties():void
    {
    	super.commitProperties();
    	
    	if (closeButton)
    	{
    		closeButton.enabled = this.enabled;
    		closeButton.visible = closeButton.includeInLayout = _allowClose;
    	    
    	    if (_closeButtonStyleChanged)
    	    {
    	        closeButton.styleName = this.getStyle("closeButtonStyleName");
    	        _closeButtonStyleChanged = false;
    	    }
    	}
    	
    	if (maximizeButton)
    	{
    		maximizeButton.enabled = this.enabled;
    		maximizeButton.visible = maximizeButton.includeInLayout = _allowMaximize;
    		
    		maximizeButton.selected = maximized;
    		
    		if (_maximizeButtonStyleChanged)
    		{
    		    maximizeButton.styleName = this.getStyle("maximizeButtonStyleName");
    		    _maximizeButtonStyleChanged = false;
    		}
    	}
    	
    	if (minimizeButton)
    	{
    		minimizeButton.enabled = this.enabled;
    		minimizeButton.visible = minimizeButton.includeInLayout = _allowMinimize;
    		
    		minimizeButton.selected = isMinimized;
    		
    		if (_minimizeButtonStyleChanged)
    		{
    		    minimizeButton.styleName = this.getStyle("minimizeButtonStyleName");
    		    _minimizeButtonStyleChanged = false;
    		}
    	}
    	
    	if (resizeHitBox)
    	{
    	    if (_resizeGripSkinChanged)
    	    {
    	        resizeHitBox.source = this.getStyle("resizeGripSkin");
    	        _resizeGripSkinChanged = false;
    	    }
    	    
    		resizeHitBox.visible = (_allowResize && !isMinimized);
    		
    		if (this.height == titleBar.height || maximized)
    			resizeHitBox.visible = false;
    		else
    			resizeHitBox.visible = _allowResize;
    	}
    	
    	if (_indexChanged && this.parent)
    	{
    		
    		if (this.parent.getChildIndex(this) == (this.parent.numChildren - 1))
    		{
    			restoreOriginalIndexBasedStyles();
    		}
    		else
    		{
    			applyInactiveIndexBasedStyles();
    		}
    		
    		_indexChanged = false;
    	}
    	
    	invalidateDisplayList();
    	invalidateSize();
    }
    
    /**
     *  Copied from Panel.measure() and included consideration for 
     *  buttonContainer's size.
     * 
     *  @private
     */
    override protected function measure():void
    {
    	super.measure();
    	
    	var textSize:Rectangle = measureHeaderText();
        var textWidth:Number = textSize.width;
        var textHeight:Number = textSize.height;
        
        var bm:EdgeMetrics =
            FlexVersion.compatibilityVersion < FlexVersion.VERSION_3_0 ?
            borderMetrics :
            EdgeMetrics.EMPTY;
        textWidth += bm.left + bm.right;    
        
        var offset:Number = 5;
        textWidth += offset * 2;
    
        if (titleIconObject)
            textWidth += titleIconObject.width;
        
        if (closeButton)
            textWidth += closeButton.getExplicitOrMeasuredWidth() + 6;
    
        measuredMinWidth = Math.max(textWidth + buttonContainer.width, 
        							measuredMinWidth);
        
        measuredWidth = Math.max(textWidth + buttonContainer.width, 
        						 measuredWidth);
    }
    
    
    
    //--------------------------------------------------------------------------
    //
    //  Overridden methods: Panel
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private
     */
    override protected function startDragging(event:MouseEvent):void
    {
        // We'll handle our own dragging, thank you very much...
    }
}
}