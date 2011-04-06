package dogerty
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.StatusEvent;
	import flash.net.LocalConnection;
	
	[Event(name="connectionEstablished", type="dogerty.TunnelEvent")]
	[Event(name="connectionFault", type="dogerty.TunnelEvent")]
	[Event(name="messageReceived", type="dogerty.TunnelEvent")]
	public class LocalTunnel extends EventDispatcher
	{
		private static const INBOUND_SUFFIX:String = "_in";
		private static const OUTBOUND_SUFFIX:String = "_out";
		
		protected var p_tunnelID:String;
		protected var p_inboundID:String;

		protected var p_outboundID:String;
		protected var p_outboundDomain:String;
		
		protected var p_inbound:LocalConnection;
		protected var p_outbound:LocalConnection;
		
		protected var p_connected:Boolean = false;
		
		protected var p_isSwitched:Boolean;
		
		public function LocalTunnel(tunnelID:String = null, switched:Boolean = false)
		{
			p_inbound = new LocalConnection();
			p_inbound.client = {
				receiveMessage: this.receiveMessage
			};
			
			p_inbound.addEventListener(StatusEvent.STATUS, onStatus);
			
			p_outbound = new LocalConnection();
			
			p_isSwitched = switched;
			
			this.tunnelID = tunnelID;
		}
		
		public function connectInbound():void
		{
			try 
			{
				p_inbound.connect(p_inboundID);
			}
			catch(e:ArgumentError)
			{
				dispatchEvent(new TunnelEvent(TunnelEvent.CONNECTION_FAULT));
			}
		}
		
		private function onStatus(e:StatusEvent):void 
		{
			if(e.level == "error")
			{
				dispatchEvent(new TunnelEvent(TunnelEvent.CONNECTION_FAULT));
			}
			else
			{
				p_connected = true
				dispatchEvent(new TunnelEvent(TunnelEvent.CONNECTION_ESTABLISHED));
			}
		}
		
		public function sendMessage(type:String, message:Object):void
		{
			p_outbound.send(p_outboundDomain+":"+p_outboundID, "receiveMessage", type, message, false, true);
		}
		
		protected function receiveMessage(type:String, message:Object, chuncked:Boolean = false, lastChunk:Boolean = true):void
		{
			dispatchEvent(new TunnelEvent(TunnelEvent.MESSAGE_RECEIVED,type,message));
		}
		
		public function set tunnelID(value:String):void
		{
			if(value){
				p_tunnelID = value;
				p_inboundID = "_"+ value + (p_isSwitched? OUTBOUND_SUFFIX:INBOUND_SUFFIX);
				p_outboundID = "_" + value + (p_isSwitched? INBOUND_SUFFIX:OUTBOUND_SUFFIX);
			}
			else
			{
				p_tunnelID = p_inboundID = p_outboundID = "";
			}
		}
		
		public function get tunnelID():String
		{
			return p_tunnelID;
		}
		
		
		public function get inboundDomain():String
		{
			return p_inbound.domain;
		}
		
		public function get outboundDomain():String
		{
			return p_outboundDomain;
		}
		
		public function set outboundDomain(value:String):void
		{
			this.p_outboundDomain = value;
		}
		
		public function get isSwitched():Boolean
		{
			return this.p_isSwitched;
		}
	}
}