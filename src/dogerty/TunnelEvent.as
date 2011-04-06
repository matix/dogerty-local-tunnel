package dogerty
{
	import flash.events.Event;
	
	public class TunnelEvent extends Event
	{
		public static const CONNECTION_ESTABLISHED:String = "connectionEstablished";
		public static const CONNECTION_FAULT:String = "connectionFault";
		public static const MESSAGE_RECEIVED:String = "messageReceived";
		
		protected var p_messageType:String;
		protected var p_messageContent:Object;
		
		public function TunnelEvent(type:String, messageType:String = null, messageContent:Object = null):void
		{
			super(type)
			p_messageType = messageType;
			p_messageContent = messageContent;
		}
		
		public function get messageType():String
		{
			return p_messageType;
		}
		
		public function get messageContent():Object
		{
			return p_messageContent;
		}
		
		override public function clone():Event
		{
			return new TunnelEvent(this.type,p_messageType, p_messageContent);
		}
	}
}