package alternativa.engine3d.utils 
{
	import flash.geom.Vector3D;
	import flash.geom.Matrix3D;
	import flash.display.*;
	import flash.display3D.*;
	import flash.events.*;
	import flash.utils.setTimeout;
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.*;
	import alternativa.physics.dynamics.A3DDynamicsWorld;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.Surface;
	import alternativa.engine3d.materials.StandardMaterial;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.materials.VertexLightTextureMaterial;
	import alternativa.engine3d.resources.Geometry;
	
	use namespace alternativa3d;

	public class Helpers {

		public static const RAD2DEG:Number = 180 / Math.PI;
		public static const DEG2RAD:Number = Math.PI / 180;

		public static var STAGE:Stage;
		public static var CONTEXT:Context3D;
		public static var STAGE3D:Stage3D;
		
		public static var physicsWorld:A3DDynamicsWorld;
		
		/**
		 * @private
		 */
		public static var fogParam:FogParam;
		
		public static var textureRender:TextureRender;
		
		public static var RGBA:String = ", rgba";
        public static var DXT5:String = ", dxt5";
        public static var DXT1:String = ", dxt1";
        public static var COMPRESS:String = RGBA;
		
		
		public static function contextReqest(stage:Stage, callback:Function):void {
			STAGE = stage;
			STAGE3D = stage.stage3Ds[0];
			STAGE3D.addEventListener(Event.CONTEXT3D_CREATE, procceedContext);
			STAGE3D.requestContext3D(Context3DRenderMode.AUTO,Context3DProfile.BASELINE);
			
			// init the physics world
			physicsWorld = A3DDynamicsWorld.getInstance();
			physicsWorld.initWithDbvtBroadphase();			
			physicsWorld.gravity = new Vector3D(0, 0, -20);

			function procceedContext(e:Event):void {
				STAGE3D.removeEventListener(Event.CONTEXT3D_CREATE, procceedContext);
				STAGE3D.context3D.enableErrorChecking = false;
				CONTEXT = STAGE3D.context3D;
				textureRender = new TextureRender();
				setTimeout(callback,100);
			}

		}

		public static function useFog(param:FogParam):void {
			fogParam = param;
		}


		public static function randomBetween(minNum:Number, maxNum:Number):Number {
			return (Math.floor(Math.random() * (maxNum - minNum + 1)) + minNum);
		}

		public static function UINT2RGB(component : String, uintColor: uint, usePercent : Boolean = false ) : Number {
			
			switch ( component.toLowerCase() ) {
				case "r" :
					return usePercent == false ? (( uintColor >> 16 ) & 0xFF) :((( uintColor >> 16 ) & 0xFF) / 255);
					break;
				case "g" :
					return usePercent == false ? (( uintColor >> 8 ) & 0xFF) : ((( uintColor >> 8 ) & 0xFF) / 255);
					break;
				case "b" :
					return usePercent == false ? (( uintColor & 0xFF )) : ((( uintColor & 0xFF )) / 255);
					break;
			}
			return 0;
		}
		
		public static function UINTtoVECTOR(component : String, uintColor: uint, usePercent : Boolean = false ) : Number {
			
			switch ( component.toLowerCase() ) {
				case "r" :
					return usePercent == false ? (( uintColor >> 16 ) & 0xFF) :((( uintColor >> 16 ) & 0xFF) / 255);
					break;
				case "g" :
					return usePercent == false ? (( uintColor >> 8 ) & 0xFF) : ((( uintColor >> 8 ) & 0xFF) / 255);
					break;
				case "b" :
					return usePercent == false ? (( uintColor & 0xFF )) : ((( uintColor & 0xFF )) / 255);
					break;
			}
			return 0;
		}	
		
		private static function getChildbyVector(parent:Object3D, v:Array,m:Vector.<Material>):void
		{		
			var object:Object3D;
			var msh:Mesh; var sur:Surface; var mat:Material;
			for(var i:int=0;i<parent.numChildren-1; i++)
			{
				object = parent.getChildAt(i);
				if (object is Mesh)
				{
					msh = object as Mesh;
					for(var s:int=0; s<msh.numSurfaces-1; s++)
					{
						sur = msh.getSurface(s);
						mat = sur.material;
						if(mat is StandardMaterial)
						{
							//addMaterial(mat, v:Array, m:Vector.<Material>);
						}
						else if(mat is TextureMaterial)
						{
							
						}
						else if(mat is FillMaterial)
						{
							
						}
						else if(mat is VertexLightTextureMaterial)
						{
							
						}						
						
					}
				}
			}			
		}		
		
		public static function combineScene(parent:Object3D):void
		{		
			var sceneMaterials:Vector.<Material>=new Vector.<Material>();
			var sceneMesh:Array=new Array();//Vector.<Material>;
			//собираем все материалы
			//getChildbyVector(parent);
			
			
			
			
		}
		
		public static function combine(meshes:Vector.<Mesh>, material:Material = null):Mesh
		{
			var res:Mesh;
			
			var indices:Vector.<uint> = new Vector.<uint>();
			var vert:Vector.<Number> = new Vector.<Number>();
			var norm:Vector.<Number> = new Vector.<Number>();
			var tex:Vector.<Number> = new Vector.<Number>();
			
			var i:int, il:uint, nil:uint, vec:Vector3D,vecn:Vector3D, transf:Matrix3D,vt:Vector.<Number>, v:Vector.<Number>,vn:Vector.<Number>, tempind:Vector.<uint>;
			
			for each (res in meshes)
			{	
				v = res.geometry.getAttributeValues(VertexAttributes.TEXCOORDS[0]);
				il = v.length;
				for (i = 0; i < il; i += 2)
				{
					tex.push(v[i], v[i + 1]);
				}
				
				v = res.geometry.getAttributeValues(VertexAttributes.POSITION);
				vn = res.geometry.getAttributeValues(VertexAttributes.NORMAL);
				il = v.length; 
				for (i = 0; i < il; i += 3)
				{
					vec = new Vector3D(v[i], v[i + 1], v[i + 2]);
					vecn = new Vector3D(vn[i], vn[i + 1], vn[i + 2]);
					vecn.incrementBy(vec);
					
					vec = res.localToGlobal(vec);
					vecn = res.localToGlobal(vecn);
					
					vert.push(vec.x, vec.y, vec.z);
					
					vecn.decrementBy(vec);
					vecn.normalize();
					
					norm.push(vecn.x, vecn.y, vecn.z);
				}
				
				tempind = res.geometry.indices;
				il = tempind.length;
				for (i = 0; i < il; i++)
				{
					indices.push(nil + tempind[i])
				}
				nil += v.length / 3;
			
			}
			
			res = new Mesh();
			
			var geometry:Geometry = new Geometry(vert.length / 3);
			geometry._indices = indices;
			var attributes:Array = [];
			attributes[0] = VertexAttributes.POSITION;
			attributes[1] = VertexAttributes.POSITION;
			attributes[2] = VertexAttributes.POSITION;
			attributes[3] = VertexAttributes.TEXCOORDS[0];
			attributes[4] = VertexAttributes.TEXCOORDS[0];
			attributes[5] = VertexAttributes.NORMAL;
			attributes[6] = VertexAttributes.NORMAL;
			attributes[7] = VertexAttributes.NORMAL;
			attributes[8] = VertexAttributes.TANGENT4;
			attributes[9] = VertexAttributes.TANGENT4;
			attributes[10] = VertexAttributes.TANGENT4;
			attributes[11] = VertexAttributes.TANGENT4;
			
			geometry.addVertexStream(attributes);
			geometry.setAttributeValues(VertexAttributes.POSITION, vert);
			geometry.setAttributeValues(VertexAttributes.NORMAL, norm);
			geometry.setAttributeValues(VertexAttributes.TEXCOORDS[0], tex);
			geometry.calculateTangents(0);
			
			res.geometry = geometry;
			res.addSurface(material, 0, indices.length / 3);
			res.calculateBoundBox();
			
			return res;
		}
	}

}