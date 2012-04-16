package mapserver
{
	import com.google.maps.Alpha;
	import com.google.maps.CopyrightCollection;
	import com.google.maps.Map;
	import com.google.maps.TileLayerBase;
	import com.google.maps.interfaces.ICopyrightCollection;
	import com.google.maps.overlays.TileLayerOverlay;
	
	import components.LayerList;
	
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.events.*;
	import flash.geom.Point;
	import flash.net.URLRequest;
	
	import events.RefreshedEvent;
	
	import utilities.Configuration;
	
	public class MapServerTileLayer extends TileLayerBase
	{
		
		/*	This class is an internal class specific to overlaying images rendered by MapServer onto
			Google Maps.  Rendered images are 256x256 in size, and correspond to tiles (and tile indices)
			within Google Maps.  
		*/
		
		public var mapServerURL:String = null;
		private var sessionID:String;
		private var parameters:Object = new Object;
		private var layerList:LayerList;
		private var loaderCounter:int;
		private var loadError:Boolean;
		private var garbageString:String;
		private var map:Map;
		private var overlay:TileLayerOverlay;
		private var timestamp:Date;
		
		public function MapServerTileLayer(m:Map, copyrightCollection:ICopyrightCollection = null,
                                minResolution:Number = NaN,
                                maxResolution:Number = NaN,
                                alpha:Number=Alpha.OPAQUE)
        {
        	map = m;
        	map.addEventListener("TileLayerRefresh", refresh);
        	map.addEventListener("TileLayerReload", reload);
            var cC:ICopyrightCollection;
            if(copyrightCollection != null) cC = copyrightCollection;
            else {
            	cC = new CopyrightCollection("");
            }
            super(cC, minResolution, maxResolution, alpha);
            mapServerURL = Configuration.hostURL + "mapserver_mapscript.php";
            loaderCounter = 0;
            loadError = false;
            garbageString = generateGarbage(16);
        }
        
        public function setLayerList(l:LayerList):void {
        	layerList = l;
        }
        public function setOverlay(o:TileLayerOverlay):void {
        	overlay = o;
        }
        
        private function loadCompleteListener(e:Event):void {
        	loaderCounter--;
        	if(loaderCounter == 0) {
        		if(loadError) {
        			map.dispatchEvent(new Event("TileLayerRefreshError"));
        			loadError = false;
        		}
        		else {
        			if(timestamp != null) {
        				var diff:Date = new Date();
        				diff.setTime(diff.getTime() - timestamp.getTime());
        				var re:RefreshedEvent = new RefreshedEvent("TileLayerRefreshed");
        				re.timestamp = diff;
        				map.dispatchEvent(re);
        			}
        			else map.dispatchEvent(new RefreshedEvent("TileLayerRefreshed"));
        			
        		}
        	}
        }
        private function progressListener(e:ProgressEvent):void {
        	
        }
        private function errorListener(e:Event):void {
        	loaderCounter--;
        	loadError = true;
        }
        
        public function reload(e:Event):void {
        	garbageString = generateGarbage(16);
        	timestamp = new Date();
        	refresh(e);	
        }
        
        public function refresh(e:Event):void {
        	map.removeOverlay(overlay);
        	overlay = new TileLayerOverlay(this);
        	timestamp = new Date();
        	map.addOverlay(overlay);
        }
        
        public override function loadTile(tilePos:Point, zoom:Number):DisplayObject {
			var loader:Loader = new Loader();
			var tileUrl:String = constructURLString(tilePos, zoom);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadCompleteListener);
			loaderCounter++;
			loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, progressListener);
			loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorListener);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, errorListener);
			loader.load(new URLRequest(tileUrl));
			return loader;
		}
		
		public function setParameter(name:String, value:String):void {
			parameters[name] = value;
		}
		public function getParameter(name:String):String {
			return parameters[name];
		}
		
		private function constructURLString(tilePos:Point, zoom:Number):String {
			var s:String = mapServerURL + "?SESSIONID=" + sessionID;
			s += "&X="+tilePos.x+"&Y="+tilePos.y+"&Z="+zoom;
			s += "&GARBAGESTRING=" + garbageString;
			for(var parameter:String in parameters) {
				s += "&" + parameter + "=" + parameters[parameter];
			}
			
			var layersBody:String = "";
			for(var i:int = 0; i<layerList.length(); i++) {
				var layer:XML = layerList.getLayer(i);
				if(layer.@enabled == false) continue;
				layersBody += layer.@name + ",";
			}
			if(layersBody.length > 0) {
				s += "&LAYERS=" + layersBody.substring(0,layersBody.length-1);
			}
			return s;
		}
		
		public static function generateGarbage(length:int):String {
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