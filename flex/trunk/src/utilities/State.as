package utilities
{
	import components.LayerList;
	
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.IExternalizable;
	
	import windows.IdentifyWindow;
	[RemoteClass( alias="data.State" )]
	public class State implements IExternalizable
	
	/*	The State object holds variables that influence the user state of the system.  This class
		can be serialized out into the database, encoded as a Base64 string using the Base64 utility
		class.  The load() and save() methods handle this functionality, using the session key (token)
		as a parameter.
	*/ 
	
	// State is implemented as a Singleton.
	// Do not construct a standalone instance; Use State.state to get the state.
	{
		private static var _state:State = null;
		public var token:String;
		public var layerList:LayerList;
		public var XMLLayers:LayerList;
		public var properties:Object;
		public var identifyWindow:IdentifyWindow;
		
	    public function readExternal(input:IDataInput):void
   		{
   			layerList = input.readObject() as LayerList;
   			properties = input.readObject() as Object;
    	}

	    public function writeExternal(output:IDataOutput):void
	    {
	    	output.writeObject(layerList);
	    	output.writeObject(properties);
	    }
		
		public function State()
		{
            properties = new Object();
            token = "";
            identifyWindow = null;
		}
		private static function loadCompleteHandler(e:Event):void {
			var xml:XML = new XML(e.target.data);
			var ba:ByteArray = Base64.Decode(xml.state);
			//ba.uncompress();
			var o:Object = ba.readObject();
			var s:State = o as State;
			s.token = xml.@token;
			_state = s;
		}
		public static function load(id:String):void {
			var request:URLRequest = new URLRequest(Configuration.hostURL + "state.php");
			request.method = "POST";
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, loadCompleteHandler);
			var query:XML = <state_load/>
			query.@token = id;
			request.data = query;
			loader.load(request);
		}
		[Bindable("stateChange")]
		public static function get state():State
        {
        	if(_state == null) {
        		_state = new State();
        	}
        	
        	return _state;
        }
        
        public static function get token():String
        {
        	if(_state == null) {
        		_state = new State();
        	}
        	
        	return _state.token;
        }
        
        public static function set token(s:String):void
        {
        	if(_state == null) {
        		_state = new State();
        	}
        	
        	_state.token = s;
        }
        
        public static function reset():void
        {
        	_state = new State();
        }
        private static function saveCompleteHandler(e:Event):void {
        	
        }
        public static function save():void {
        	if(_state == null) return;
        	var ba:ByteArray = new ByteArray();
			ba.writeObject(_state);
			//ba.compress();
			var request:URLRequest = new URLRequest(Configuration.hostURL + "state.php");
			request.method = "POST";
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, saveCompleteHandler);
			var query:XML = <state_save/>
			query.@token = _state.token;
			query.state = Base64.Encode(ba);
			request.data = query;
			loader.load(request);
        }

		public static function generateToken(length:int):String {
			var s:String = "";
			var r:int;
			for(var i:int=0;i<length;i++) {
				r = Math.random()*36+48;
				if(r > 57) r += 7;
				s += String.fromCharCode(r);
			}
			return s;
		}
	}
}