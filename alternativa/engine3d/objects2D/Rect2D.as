/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.objects2D {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.resources.Geometry;

	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import alternativa.engine3d.utils.Helpers;
	import flash.geom.Point;
	import flash.geom.Matrix;
	import alternativa.engine3d.materials.TextureMaterial2D;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Light3D;
	import flash.display3D.textures.Texture;
	import flash.display3D.Context3D;
	import alternativa.engine3d.core.View;
	import alternativa.engine3d.objects.Surface;
	import flash.geom.Vector3D;

	use namespace alternativa3d;

	/**
	 * A cuboid primitive.
	 */
	public class Rect2D extends Mesh {
		/**
		 * Creates a new Box instance.
		 * @param width Width. Can not be less than 0.
		 * @param length Length. Can not be less than 0.
		 * @param height Height. Can not be less than 0.
		 * @param widthSegments Number of subdivisions along x-axis.
		 * @param lengthSegments Number of subdivisions along y-axis.
		 * @param heightSegments Number of subdivisions along z-axis.
		 * @param reverse If <code>true</code>, face normals will turned inside, so the box will be visible from inside only. Otherwise, the normals will turned outside.
		 * @param material Material.
		 */
		private var _rx:Number=0;
		private var _ry:Number=0;
		private var _width:Number=0;
		private var _height:Number=0;
		private var material:Material;
		
		/**
		 * X coordinate.
		 */
		public function get rx():Number {
			return _rx;
		}

		/**
		 * @private
		 */
		public function set rx(value:Number):void {
			if (_rx != value) {
				_rx = value;
				updateRect();
			}
		}

		/**
		 * Y coordinate.
		 */
		public function get ry():Number {
			return _ry;
		}

		/**
		 * @private
		 */
		public function set ry(value:Number):void {
			if (_ry != value) {
				_ry = value;
				updateRect();
			}
		}
		
		/**
		 * X coordinate.
		 */
		public function get width():Number {
			return _width;
		}

		/**
		 * @private
		 */
		public function set width(value:Number):void {
			if (_width != value) {
				_width = value;
				updateRect();
			}
		}

		/**
		 * Y coordinate.
		 */
		public function get height():Number {
			return _height;
		}

		/**
		 * @private
		 */
		public function set height(value:Number):void {
			if (_height != value) {
				_height = value;
				updateRect();
			}
		}		
		
		public var camera:Camera3D = new Camera3D(10, 10000); //стандартная камера можно обратиться Rect2D.camera
		public var updateMap:Texture;
		
		private var scene:Object3D = new Object3D();
		private var cameraCont:Object3D = new Object3D();
		private var context:Context3D;
		private var cachedContext:Context3D;		
		private var cashedParent:Object3D;
		private var cameraParent:Object3D;
		//private var renderObject:Object3D;
		
		
		public function Rect2D(x:Number=0, y:Number=0, width:Number = 100, height:Number = 100) {
			this._rx = x;
			this._ry = y;
			this._width = width;
			this._height = height;
			this.material = new TextureMaterial2D(512);
			updateMap = TextureMaterial2D(material).getUpdateMap();
			context = Helpers.CONTEXT;
			
			updateRect();
			
			//Создаем суб сцену и контейнер для камеры
			scene.addChild(cameraCont);
			scene.name = "2dScene";
			cameraCont.name = "2dcameraCont";
			//Создаем камеру
			camera.view = new View(512, 512, false);
			camera.name = "2dcamera";
			//this.diffuseMap = diffuseMap;
			
		}
		
		private var p1:Point;
		private var p2:Point;
		private var p3:Point;
		private var p4:Point;
		
		private function updateRect():void {
            geometry = new Geometry(4);

            var attributes:Array = new Array();
            attributes[0] = VertexAttributes.POSITION;
            attributes[1] = VertexAttributes.POSITION;
			attributes[2] = VertexAttributes.POSITION;
            attributes[3] = VertexAttributes.TEXCOORDS[0];
            attributes[4] = VertexAttributes.TEXCOORDS[0];
            geometry.addVertexStream(attributes);
			var xk:Number = 2/Helpers.STAGE.stageWidth;
			var yk:Number = -2/Helpers.STAGE.stageHeight;
			//var pos:Vector.<Number> = new Vector.<Number>();
			var m:Matrix = new Matrix();
			m.translate(-1,1);
			//m.rotate(180);
			p1 = m.transformPoint(new Point(_rx*xk, _ry*yk));
			trace("p1 x: "+String(p1.x)+", y: "+String(p1.y));
			p2 = m.transformPoint(new Point(_rx*xk, (_ry+_height)*yk));
			trace("p2 x: "+String(p2.x)+", y: "+String(p2.y));
			p3 = m.transformPoint(new Point((_rx+_width)*xk, (_ry+_height)*yk));
			trace("p3 x: "+String(p3.x)+", y: "+String(p3.y));
			p4 = m.transformPoint(new Point((_rx+_width)*xk, _ry*yk));	
			trace("p4 x: "+String(p4.x)+", y: "+String(p4.y));
            geometry.setAttributeValues(VertexAttributes.POSITION, Vector.<Number>([p1.x, p1.y,0, p2.x, p2.y,0, p3.x, p3.y,0, p4.x, p4.y,0]));
            geometry.setAttributeValues(VertexAttributes.TEXCOORDS[0], Vector.<Number>([0, 0, 0, 1, 1, 1, 1, 0]));

            geometry.indices = Vector.<uint>([0, 1, 2, 2, 3, 0]);

            addSurface(material, 0, 2);
        }


		/**
		 * @private
		 */
		override alternativa3d function collectDraws(camera:Camera3D, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean):void {
			var surface:Surface = _surfaces[0];
			material.collectDraws(camera, surface, geometry, lights, lightsLength, useShadow, -1);
		}

		public function setCameraInWorld(object:Object3D):void
		{
			object.addChild(camera);
			cameraParent=object;
		}
	
		public function update(object:Object3D=null):void
		{
			
			if(object!==null) // если в рендер передаем 1 объект или группу объектов то рендерим суб сцену
			{
				cashedParent = object.parent;
				scene.addChild(object);
				cameraCont.posVector = object.localToGlobal(new Vector3D(0,0,0));
				camera.posVector = new Vector3D(0,-50,20);
				camera.lookAt(0,0,0);

				cameraCont.addChild(camera);
				
				cameraCont.rotationZ +=0.05;
				context.setRenderToTexture(updateMap, true);
				camera.render(Helpers.STAGE3D);
				context.setRenderToBackBuffer();
				
				cashedParent.addChild(object);
			}
			else //иначе рендерим всю сцену
			{
				if(cameraParent!==camera.parent)
				{
					cameraParent.addChild(camera);
					camera.posVector = new Vector3D(0,200,200);
					camera.lookAt(0,0,0);
				}
				context.setRenderToTexture(updateMap, true);
				camera.render(Helpers.STAGE3D);
				context.setRenderToBackBuffer();				
			}
		}


		/**
		 * @inheritDoc 
		 */
		override public function clone():Object3D {
			var res:Rect2D = new Rect2D();
			res.clonePropertiesFrom(this);
			return res;
		}
	}
}
