package alternativa.physics.controllers {
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.ui.*;
	import flash.utils.*;
	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.*;
	
	import alternativa.physics.dynamics.character.A3DKinematicCharacterController;
	import alternativa.physics.collision.shapes.*;
	
	use namespace alternativa3d;
	
	public class CharacterController {

		private static const Bobtime:Number = 0.15;

		public var object:A3DKinematicCharacterController;
		public var eventSource:InteractiveObject;
		public var camera:Camera3D;
		
		public var speed:Number=1;
		
		public var fovMin:Number=Math.PI/4;
		public var fovMax:Number=Math.PI/2;
		public var fov:Number=Math.PI/2;
		public var cachedFov:Number=Math.PI/2;
		
		private var delta:Vector3D = new Vector3D();
		private var deltar:Vector3D = new Vector3D();
		public var neytralX:Number=200;
		public var neytralY:Number=120;
		
		private var move:Boolean=false;
		
		private static const RAD2DEG:Number = 180/Math.PI;
		private static const DEG2RAD:Number = Math.PI/180;
		
		private var position:Vector3D;
		private var rotation:Vector3D;
		
		private var keyRight : Boolean = false;
		private var keyLeft : Boolean = false;
		private var keyForward : Boolean = false;
		private var keyReverse : Boolean = false;
		private var keyUp : Boolean = false;
		private var walkDirection : Vector3D = new Vector3D();
		private var walkSpeed : Number = 1.00;
		private var chRotation : Number = 0;
		
		private var mousePoint:Point = new Point();
		private var mouseLook:Boolean;
		
		public var tridPerson:Boolean=false;
		/**
		 * Speed multiplier for acceleration mode.
		 */
		public var speedMultiplier:Number=3;
		
		/**
		 * Mouse sensitivity.
		 */
		public var mouseSensitivity:Number=10;
		
		/**
		 * The maximal slope in the vertical plane in radians.
		 */
		public var maxPitch:Number = -30;
		
		/**
		 * The minimal slope in the vertical plane in radians.
		 */
		public var minPitch:Number = -150;
		
		public var cameraSet:Number = 3;
		
		private var timeb:Number = Math.PI / 2;
		private var headbob:Number=5;

		private var useLookInterface:Boolean=false;
		
		public function CharacterController(eventSource:InteractiveObject, object:A3DKinematicCharacterController, camera:Camera3D=null) {
			
			this.eventSource = eventSource;
			this.object = object;
			this.camera = camera;
			
			var h:Number = A3DBoxShape(object.ghostObject.shape).dimensions.z;
			
			cameraSet = h/2-h*0.1;
			//cameraSet = A3DCapsuleShape(object.ghostObject.shape).height/2;

			position = new Vector3D(object.ghostObject.position.x,object.ghostObject.position.y,object.ghostObject.position.z);
			if(camera!==null)
			{
				rotation = new Vector3D(camera.rotationX*RAD2DEG,camera.rotationY*RAD2DEG,camera.rotationZ*RAD2DEG);
			}
			else
			{
				rotation = new Vector3D(-90,0,0);
			}
			if (rotation.x > maxPitch) rotation.x = maxPitch;
			if (rotation.x < minPitch) rotation.x = minPitch;
			
			
			eventSource.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			eventSource.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			eventSource.addEventListener(MouseEvent.MOUSE_MOVE, isMove);
			eventSource.addEventListener(MouseEvent.MOUSE_WHEEL, isZoom);
			
			eventSource.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			eventSource.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
		}
		
		private function keyDownHandler(event:KeyboardEvent) : void {
			switch(event.keyCode) {
				case Keyboard.UP:
					keyForward = true;
					keyReverse = false;
					break;
				case Keyboard.DOWN:
					keyReverse = true;
					keyForward = false;
					break;
				case Keyboard.LEFT:
					keyLeft = true;
					keyRight = false;
					break;
				case Keyboard.RIGHT:
					keyRight = true;
					keyLeft = false;
					break;
				case 87:
					keyForward = true;
					keyReverse = false;
					break;
				case 83:
					keyReverse = true;
					keyForward = false;
					break;
				case 65:
					keyLeft = true;
					keyRight = false;
					break;
				case 68:
					keyRight = true;
					keyLeft = false;
					break;					
				case Keyboard.SPACE:
					keyUp = true;
					break;
				case Keyboard.SHIFT:
					walkSpeed = 2;
					break;
			}
		}

		private function keyUpHandler(event : KeyboardEvent) : void {
			switch(event.keyCode) {
				case Keyboard.UP:
					keyForward = false;
					walkDirection.scaleBy(0);
					object.setWalkDirection(walkDirection);
					break;
				case Keyboard.DOWN:
					keyReverse = false;
					walkDirection.scaleBy(0);
					object.setWalkDirection(walkDirection);
					break;
				case Keyboard.LEFT:
					keyLeft = false;
					walkDirection.scaleBy(0);
					object.setWalkDirection(walkDirection);					
					break;
				case Keyboard.RIGHT:
					keyRight = false;
					walkDirection.scaleBy(0);
					object.setWalkDirection(walkDirection);					
					break;
				case 87:
					keyForward = false;
					walkDirection.scaleBy(0);
					object.setWalkDirection(walkDirection);
					break;
				case 83:
					keyReverse = false;
					walkDirection.scaleBy(0);
					object.setWalkDirection(walkDirection);
					break;
				case 65:
					keyLeft = false;
					walkDirection.scaleBy(0);
					object.setWalkDirection(walkDirection);					
					break;
				case 68:
					keyRight = false;
					walkDirection.scaleBy(0);
					object.setWalkDirection(walkDirection);					
					break;					
					
				case Keyboard.SPACE:
					keyUp = false;
					break;
				case Keyboard.SHIFT:
					walkSpeed = 1;
					break;					
					
			}
		}
			
		private function onMouseDown(e:MouseEvent):void {
			if(!useLookInterface)
			{
				startMouseLook();
			}
		}
	
		private function onMouseUp(e:MouseEvent):void {
			if(!useLookInterface)
			{			
				stopMouseLook();
			}
		}
	
		/**
		 * Enables mouse look mode.
		 */
		public function startMouseLook():void {
			mousePoint.x = eventSource.mouseX;
			mousePoint.y = eventSource.mouseY;
			mouseLook = true;
		}
	
		/**
		 * Disables mouse look mode.
		 */
		public function stopMouseLook():void {
			mouseLook = false;
		}
		
		private function isZoom(e:MouseEvent):void
		{
			if(e.delta>0)
			{
				fov-=0.05;
			}
			else
			{
				fov+=0.05;
			}
			
			if(fov>fovMax)
			{
				fov=fovMax;
			}
			if(fov<fovMin)
			{
				fov=fovMin;
			}			
			
		}		
		
		private var MouseX:Number;
		private var MouseY:Number;		
		private function isMove(e:MouseEvent):void
		{
			
			deltar.x = e.movementX;
			deltar.z = e.movementY;			
			//trace(e.delta);
			/*if(useLookInterface)
			{

			}
			else
			{
				deltar.x = 0;
				deltar.z = 0;				
			}*/
		}		
		
		private var StageX:Number;
		private var StageY:Number;	
		private var deltaR:Number=3;//Math.PI/60;	
		private var destination:Vector3D;
		private var time:int;
		private var tmp:Matrix3D;
		
		private var dx:Number;
		private var dy:Number;
		private var _camrad:Number=1800;
		private var med:Number;
		private var cRad:Number;
		
		private var campos:Vector3D;
		private var _target:Vector3D;
		
		public function update():void
		{
			var frameTime:Number = time;
			time = getTimer();
			frameTime = 0.02*(time - frameTime);
			if (frameTime > 1) frameTime = 1;
			
			if (keyLeft) {
				walkDirection = object.ghostObject.right;
				walkDirection.scaleBy(-speed*speedMultiplier*walkSpeed);
				object.setWalkDirection(walkDirection);	
				timeb += Bobtime;
			}
			if (keyRight) {
				walkDirection = object.ghostObject.right;
				walkDirection.scaleBy(speed*speedMultiplier*walkSpeed);
				object.setWalkDirection(walkDirection);
				timeb += Bobtime;
			}
			if (keyForward) {
				walkDirection = object.ghostObject.front;
				walkDirection.scaleBy(speed*speedMultiplier*walkSpeed);
				object.setWalkDirection(walkDirection);
				timeb += Bobtime;
			}
			if (keyReverse) {
				walkDirection = object.ghostObject.front;
				walkDirection.scaleBy(-speed*speedMultiplier*walkSpeed);
				object.setWalkDirection(walkDirection);
				timeb += Bobtime;
			}
			//trace(object.onGround());
			if (keyUp && object.onGround()) {
				object.jump();
			}
			
			if (mouseLook) {
				if(useLookInterface)
				{
					if(abs(deltar.x)>0.5){dx = deltar.x*7;}else{dx=0;}
					if(abs(deltar.z)>0.5){dy = deltar.z*7;}else{dy=0;}
					deltar.x=0;deltar.z=0;
				}
				else
				{
					dx = eventSource.mouseX - mousePoint.x;
					dy = eventSource.mouseY - mousePoint.y;
					mousePoint.x = eventSource.mouseX;
					mousePoint.y = eventSource.mouseY;					
				}

				if(tridPerson)
				{
					rotation.x += dy*Math.PI/180*mouseSensitivity;
				}
				else
				{
					rotation.x -= dy*Math.PI/180*mouseSensitivity;
				}
				if (rotation.x > maxPitch) rotation.x = maxPitch;
				if (rotation.x < minPitch) rotation.x = minPitch;
				rotation.z -= dx*Math.PI/180*mouseSensitivity;
				//moved = true;
			}
			
			object.ghostObject.rotationZ = rotation.z;
			if(camera!==null)
			{
				_target = object.ghostObject.position;
				campos = new Vector3D();
				if(tridPerson)
				{
					campos.x = camera.x - _target.x;
					campos.y = camera.y - _target.y;
					cRad = (rotation.z-90)*DEG2RAD;//Math.atan2(campos.y, campos.x);			
					campos.z = _target.z + Math.cos(rotation.x*DEG2RAD) * _camrad;
					med = Math.sin(70*Math.PI/180) * _camrad;
					campos.x = _target.x + Math.cos(cRad) * med;
					campos.y = _target.y + Math.sin(cRad) * med;
					camera.posVector = campos;				
					camera.lookVector(_target);
				}
				else
				{
					camera.rotationZ = object.ghostObject.rotationZ*DEG2RAD;
					camera.rotationX = rotation.x*DEG2RAD;
					campos = object.ghostObject.position.add(new Vector3D(0,0,cameraSet))
					//trace("1 " + campos.toString());
					campos.z += abs(Math.sin(timeb)) * (headbob*walkSpeed);
   					campos.x += Math.cos(timeb) * (headbob*walkSpeed);
					//trace("2 " + campos.toString());
					
					camera.posVector = campos;
					//camera.lookVector(object.ghostObject.position);
				}
				
				if (cachedFov !== fov)
				{
					camera.fov = fov;
					camera.calculateProjection(camera.view.width, camera.view.height);					
				}
				cachedFov = fov;
			}
			
			/*object.x = position.x;
			object.y = position.y;
			object.z = position.z;
			object.rotationX = rotation.x;
			object.rotationY = rotation.y;
			object.rotationZ = rotation.z;			
			if (object is Camera3D)
			{
				if (cachedFov !== fov)
				{
					//var cam:Camera3D = object as Camera3D;
					//cam.fov = fov;
					//cam.calculateProjection(cam.view.width, cam.view.height);					
				}
			}
			cachedFov = fov;*/
		}
		
		private static function abs(a:Number):Number
		{
			if (a < 0)
				return -a;
			return a;
		}

		public function setMouseLook(flag:Boolean=true):void {
			if(flag)
			{
				mouseLook = true;
				useLookInterface = true;
				move = true;
			}
			else
			{
				mouseLook = false;
				useLookInterface = false;
				move = false;
			}
			
		}

	}
	
}
