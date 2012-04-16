package events
{
	import flash.events.Event;
	public class RefreshedEvent extends Event {
		
		/*	This event is thrown when all of the MapServer tiles have loaded.  It includes the duration
			of the render.
		*/
		
		public var timestamp:Date;
		
		public function RefreshedEvent(type:String) {
			super(type);
		}

	}
}