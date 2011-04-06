package dogerty
{
	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.SecurityErrorEvent;
	import flash.events.StatusEvent;
	import flash.events.TimerEvent;
	import flash.net.LocalConnection;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import mx.core.INavigatorContent;
	
	[Event(name="connectionEstablished", type="dogerty.TunnelEvent")]
	[Event(name="connectionFault", type="dogerty.TunnelEvent")]
	[Event(name="messageReceived", type="dogerty.TunnelEvent")]
	public class LocalTunnel extends EventDispatcher
	{
		private static const INBOUND_SUFFIX:String = "_in";
		private static const OUTBOUND_SUFFIX:String = "_out";
		private static const CHUNK_SIZE_LIMIT:uint = 40960;
		
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
			p_inbound.allowDomain("*");
			p_inbound.client = {
				receiveMessage: this.receiveMessage
			};
			
			
			p_outbound = new LocalConnection();
			p_outbound.addEventListener(StatusEvent.STATUS, onStatus);
			p_outbound.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onError);
			p_outbound.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			
			p_isSwitched = switched;
			
			this.tunnelID = tunnelID;
		}
		
		protected var timer:Timer;
		
		public function connectInbound():void
		{
			try 
			{
				p_inbound.connect(p_inboundID);
			}
			catch(e:ArgumentError)
			{
				dispatchEvent(new TunnelEvent(TunnelEvent.CONNECTION_FAULT, "fault", e.message));
			}
			
			// introduce a 1 sec delay to avoid async errors, in most cases unnecessary, but just in case
			timer = new Timer(1000,1);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE, function (e:TimerEvent):void {
				dispatchEvent(new TunnelEvent(TunnelEvent.CONNECTION_ESTABLISHED));
			});
			timer.start()
		}
		
		private function onStatus(e:StatusEvent):void 
		{
			if(e.level == "error")
			{
				dispatchEvent(new TunnelEvent(TunnelEvent.CONNECTION_FAULT, "fault", "Status: "+e.code+"("+e.level+")"));
			}
		}
		
		private function onError(e:Event):void 
		{
			dispatchEvent(new TunnelEvent(TunnelEvent.CONNECTION_FAULT, "fault", e));
		}
		
		public function sendMessage(type:String, message:Object):void
		{
			var encoddedMessage:ByteArray = new ByteArray();
			encoddedMessage.writeObject(message);
			encoddedMessage.compress();
			if(encoddedMessage.length > CHUNK_SIZE_LIMIT){
				var chunkCount:uint = Math.ceil(encoddedMessage.length / CHUNK_SIZE_LIMIT);
				var chunk:ByteArray;
				var lastChunk:Boolean;
				for(var i:int = 0; i< chunkCount; i++)
				{
					chunk = new ByteArray();
					lastChunk = i == chunkCount - 1;
					encoddedMessage.readBytes(chunk,i*CHUNK_SIZE_LIMIT,CHUNK_SIZE_LIMIT);
					_sendMessage(type, chunk, true, lastChunk);
				}
			}
			else{
				_sendMessage(type,encoddedMessage);
			}
		}
			
		private function _sendMessage(type:String, message:Object, chunk:Boolean = false, lastChunk:Boolean = true):void
		{
			try{
				var domainPrefix:String = outboundDomain? p_outboundDomain+":":"";
				p_outbound.send(domainPrefix+p_outboundID, "receiveMessage", type, message, chunk, lastChunk);
			}
			catch(e:Error)
			{}
		}
		
		private var messageBuffer:ByteArray;
		
		protected function receiveMessage(type:String, message:Object, chuncked:Boolean = false, lastChunk:Boolean = true):void
		{
			var messageToDispatch:Object;
			var encodedMessage:ByteArray = message as ByteArray;
			
			if(encodedMessage){
				if(chuncked){
					if(!messageBuffer) messageBuffer = new ByteArray();
					messageBuffer.writeBytes(encodedMessage,messageBuffer.length,encodedMessage.length);
					
					if(lastChunk){
						messageBuffer.uncompress();
						messageToDispatch = messageBuffer.readObject();
						messageBuffer = null;
						dispatchEvent(new TunnelEvent(TunnelEvent.MESSAGE_RECEIVED,type,messageToDispatch));
					}
				}else{
					encodedMessage.uncompress();
					messageToDispatch = encodedMessage.readObject();
					dispatchEvent(new TunnelEvent(TunnelEvent.MESSAGE_RECEIVED,type,messageToDispatch));
				}
			}
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