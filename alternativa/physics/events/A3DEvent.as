package alternativa.physics.events {
	import alternativa.physics.collision.dispatch.A3DCollisionObject;
	import alternativa.physics.collision.dispatch.A3DManifoldPoint;

	import flash.events.Event;

	public class A3DEvent extends Event {
		/**
		 * Dispatched when the body occur collision
		 */
		public static const COLLISION_ADDED : String = "collisionAdded";
		/**
		 * Dispatched when ray collide
		 */
		 public static const RAY_CAST : String = "rayCast";
		/**
		 * stored which object is collide with target object
		 */
		public var collisionObject : A3DCollisionObject;
		/**
		 * stored collision point, normal, impulse etc.
		 */
		public var manifoldPoint : A3DManifoldPoint;

		public function A3DEvent(type : String) {
			super(type);
		}
	}
}