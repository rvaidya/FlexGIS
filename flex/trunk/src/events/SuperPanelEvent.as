package events
{
import flash.events.Event;

public class SuperPanelEvent extends Event
{
	//--------------------------------------------------------------------------
	//
	//  Class constants
	//
	//--------------------------------------------------------------------------
	
	static public const MAXIMIZE:String =     "maximize";
	static public const MINIMIZE:String =     "minimize";
	static public const RESTORE:String =      "restore";
	static public const DRAG_START:String =   "dragStart";
	static public const DRAG:String =         "drag";
	static public const DRAG_END:String =     "dragEnd";
	static public const RESIZE_START:String = "resizeStart";
	static public const RESIZE_END:String =   "resizeEnd";
	
	
	
	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------
	
	public function SuperPanelEvent(type:String, 
									cancelable:Boolean=false,
									bubbles:Boolean=false)
	{
		super(type, bubbles, cancelable);
	}
}
}