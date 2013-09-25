package alternativa.physics.collision.shapes {
	import flash.geom.Vector3D;
	import alternativa.physics.A3DBase;
	

	/** 
	* Базовый класс для всех шейпов.
	* @public 
	* @author redefy 
	*/
	public class A3DCollisionShape extends A3DBase {
		
		protected var m_shapeType:int;
		protected var m_localScaling:Vector3D;
		
		protected var m_counter:int = 0;
		/** 
		* Конструктор
		* @public 
		* @param ptr 
		* @param type Тип шейпа
		*/
		public function A3DCollisionShape(ptr:uint, type:int) {
			pointer = ptr;
			m_shapeType = type;
			
			m_localScaling = new Vector3D(1, 1, 1);
		}
		
		/** 
		* Тип шейпа. Константы типов шейпов определены в классе A3DCollisionShapeType.
		* @public (getter) 
		* @return int
		*/
		public function get shapeType():int {
			return m_shapeType;
		}
		

		/** 
		* Вектор с значениями текущего масштабирования.
		* @public (getter) 
		* @return Vector3D 
		*/
		public function get localScaling():Vector3D {
			return m_localScaling;
		}
		

		/** 
		* Масштабирует шейп
		* @public (setter) 
		* @param scale Вектор с значениями масштабирования для всех трех осей
		* @return void 
		*/
		public function set localScaling(scale:Vector3D):void {
			m_localScaling.setTo(scale.x, scale.y, scale.z);
			bullet.setShapeScalingMethod(pointer, scale.x, scale.y, scale.z);
		}
		
		/**
		* this function just called by internal
		*/
		public function retain():void {
			m_counter++;
		}
		
		/**
		* this function just called by internal
		*/
		public function dispose():void {
			m_counter--;
			if (m_counter > 0) {
				return;
			}else {
				m_counter = 0;
			}
			if (!cleanup) {
				cleanup	= true;
				bullet.disposeCollisionShapeMethod(pointer);
			}
		}
	}
}