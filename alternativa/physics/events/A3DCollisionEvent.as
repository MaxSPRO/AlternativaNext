package alternativa.physics.events {
	import alternativa.physics.collision.dispatch.A3DCollisionObject;
	import alternativa.physics.collision.dispatch.A3DManifoldPoint;

	import flash.events.Event;

	public class A3DCollisionEvent extends Event {
		/**
		 * Dispatched when the body occur collision
		 */
		public static const COLLISION_ADDED : String = "collisionStart";
		/**
		 * stored which object is collide with target object
		 */
		public var collisionObject : A3DCollisionObject;
		/**
		 * stored collision point, normal, impulse etc.
		 */
		public var manifoldPoint : A3DManifoldPoint;

		public function A3DCollisionEvent(type : String) {
			super(type);
		}
	}
}