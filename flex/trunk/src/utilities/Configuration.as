package utilities
{
	import mx.core.Application;
	import mx.utils.URLUtil;
	public class Configuration
	{
		[Bindable]
		
		/*	This is the URL that points to the main entry point of the application, and where all of
			the PHP scripts reside.
		*/
		
		//public static var hostURL:String = "http://localhost:8080/flexmapviewer/";
		//public static var hostURL:String = "http://0z.ath.cx:8080/flexmapviewer/";
		public static var hostURL:String = "http://demo.flexgis.org/";
		//public static var hostURL:String = "http://geox.cens.ucla.edu/flexgis/";
		//public static var hostURL:String = "http://geox.cens.ucla.edu/flexgis/ecomob/";
		[Bindable]
		
		// This is where the API key for Google Maps is stored.
		
		// localhost
		// public static var apiKey:String = "ABQIAAAABTOrCkQ0V3HWGR6cBaKYZxT2yXp_ZAY8_ufC3CFXhHIE1NvwkxRG3FHErhdrgqqnHRSxrD75XON2Xw";
		// 0z.ath.cx
		// public static var apiKey:String = "ABQIAAAABTOrCkQ0V3HWGR6cBaKYZxRRVMfeDEegO1xsJuu2UmE0OW2pEBQtNTdSN3D6Gn9wdhqQl6rE9FyxBQ";
		// flexgis.org
		public static var apiKey:String = "ABQIAAAABTOrCkQ0V3HWGR6cBaKYZxRENZEkc1UIMUWpSYjr5D8vbaEDzRRDtcJ5UksJigSGmgJ72XdlbW_lTA";
		// geox.cens.ucla.edu
		// public static var apiKey:String = "ABQIAAAABTOrCkQ0V3HWGR6cBaKYZxRjyRZD1CwoU-g6c4ayeRbtuVMG2BTiaPoJB0RGlIgdvj3hTbbzyUMiWg";

	}
}