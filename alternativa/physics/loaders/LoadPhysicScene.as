package alternativa.physics.loaders
{
	/**
	 * ...
	 * @author MaxSPro
	 */
	import alternativa.engine3d.core.*;
	import alternativa.engine3d.materials.NormalMapSpace;
	import alternativa.engine3d.materials.StandardMaterial;
	import alternativa.engine3d.objects.Mesh
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.resources.BitmapTextureResource;
	import alternativa.engine3d.loaders.ParserCollada;
	import alternativa.engine3d.loaders.ParserA3D;
	import alternativa.engine3d.loaders.TexturesLoader;
	import alternativa.engine3d.loaders.events.TexturesLoaderEvent;
	import alternativa.engine3d.objects.Surface;
	import alternativa.engine3d.loaders.ParserMaterial;
	import alternativa.engine3d.resources.ExternalTextureResource;
	import alternativa.engine3d.resources.BitmapTextureResource;
	import alternativa.engine3d.resources.TextureResource;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.primitives.Box;
	import alternativa.engine3d.core.Resource;
	import alternativa.engine3d.resources.Geometry;
	import alternativa.engine3d.materials.*;
	import alternativa.engine3d.utils.*;
	import flash.display.Stage;
	import flash.text.TextField;
	
	import flash.geom.Vector3D;
	import flash.geom.Matrix3D;
	import flash.display.Stage3D;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import alternativa.engine3d.resources.ColorTextureResource;
	import flash.events.SecurityErrorEvent;
	import flash.events.IOErrorEvent;
	import alternativa.engine3d.lights.AmbientLight;
	import alternativa.engine3d.lights.OmniLight;
	import alternativa.physics.collision.shapes.A3DBvhTriangleMeshShape;
	import alternativa.physics.dynamics.A3DRigidBody;
	import alternativa.engine3d.loaders.ResourceLoader;
	
	/*import alternativaphysics.collision.dispatch.A3DCollisionObject;
	import alternativaphysics.collision.shapes.*;
	import alternativaphysics.dynamics.*;
	//import by.max.alternativa.felink.Alternativa3D4Physics;
	import alternativaphysics.dynamics.A3DDynamicsWorld;
	import by.max.alternativa.utils.VectorUtil;
	import by.max.alternativa.LoadWorldBullet;	import alternativaphysics.dynamics.vehicle.*;*/
	
	
	public class LoadPhysicScene extends Object3D
	{		
		public var complite:Boolean = false;
		public var _stage:Stage;
		private var _URL:String;
		private var _texturePatch:String;
		private var _stage3D:Stage3D;
		private var _scene:Object3D;
		public var _debugs:Object3D;
		private var loader:URLLoader;
		public var process:TextField = new TextField();
		public var texturesLoader:ResourceLoader;
				
		public function LoadPhysicScene(url:String, scene:Object3D=null) 
		{
			_URL=url;
			_texturePatch = url.substr(0, url.lastIndexOf('/')+1);
			_scene = this;
			if(scene!==null){_scene = scene;}
					
			var loaderA3D:URLLoader = new URLLoader();
			loaderA3D.dataFormat = URLLoaderDataFormat.BINARY;
			loaderA3D.load(new URLRequest(_URL+"?nocash="+String(Math.random())));
			loaderA3D.addEventListener(Event.COMPLETE, onA3DLoad); //окончание загрузки
			loaderA3D.addEventListener(SecurityErrorEvent.SECURITY_ERROR, httpRequestError);
			loaderA3D.addEventListener(IOErrorEvent.IO_ERROR, httpRequestError);
		}
	
		private function httpRequestError(error:* ):void
		{ 
			trace("ioErrorHandler: " + error);
		}	
	
		private var msh:Mesh;
		private var light:*;
		private var mat:ParserMaterial;
		private var surface:Surface;
		private var diffuse:*;  
		private var normal:*; 
		private var specular:*;
		private var opacity:*;
		private var glossines:*;
		private var material:*;
		private var textures:Vector.<ExternalTextureResource> = new Vector.<ExternalTextureResource>();
		
		private function onA3DLoad(e:Event):void {
			var parser:ParserA3D = new ParserA3D();
			parser.parse((e.target as URLLoader).data);			
			for each (var obj:Object3D in parser.objects) 
			{    
                 //trace(obj.toString());
				 if (obj is Mesh) 
				 {    
					msh = obj as Mesh;
					if(obj.name.substr(0,3)=="pm_")
					{
						var sceneShape:A3DBvhTriangleMeshShape = new A3DBvhTriangleMeshShape(msh.geometry);
						var sceneBody:A3DRigidBody = new A3DRigidBody(sceneShape, msh, 0);
						sceneBody.position = new Vector3D(msh.x, msh.y, msh.z);
						Helpers.physicsWorld.addRigidBody(sceneBody);
					}
					else if(obj.name.substr(0,3)=="pb_")
					{
						/*var sceneShape:A3DBvhTriangleMeshShape = new A3DBvhTriangleMeshShape(msh.geometry);
						var sceneBody:A3DRigidBody = new A3DRigidBody(sceneShape, msh, 0);
						sceneBody.position = new Vector3D(msh.x, msh.y, msh.z);
						Helpers.physicsWorld.addRigidBody(sceneBody);*/
					}
					else
					{
						_scene.addChild(msh);				
						msh.geometry.upload();
	
						for (var i:int = 0; i < msh.numSurfaces; i++) 
						{  
							surface = msh.getSurface(i);  
							mat = surface.material as ParserMaterial;
							if (mat != null) 
							{
								//trace(mat.name);
								surface.material = getMaterial(mat);
							}
						}
					}
				 } 
				 else if(obj is Object3D)
				 {
					_scene.addChild(obj);
					trace(obj.name);
				 }				 
				 else if(obj is AmbientLight)
				 {
					light = obj as AmbientLight;
					_scene.addChild(light);
				 }
				 else if(obj is OmniLight)
				 {
					light = obj as OmniLight;
					trace(light.name+': <'+String(light.attenuationBegin)+'> '+String(light.attenuationEnd));
					_scene.addChild(light);
				 }				 
             }

			texturesLoader = new ResourceLoader(false);
			texturesLoader.addResources(textures); 
			texturesLoader.addEventListener(Event.COMPLETE, textureComplite); 
			texturesLoader.load(Helpers.CONTEXT);
		}	
		
		private function addResource(res:ExternalTextureResource):void
		{
			if(textures.indexOf(res)==-1)
			{
				res.url = _texturePatch+res.url;
				textures.push(res);
			}
		}
		
		private var typeMat:String="";
		
		private function getMaterial(mat:ParserMaterial):Material
		{		
			
			if(mat.textures["diffuse"] !== null)
			{
				typeMat = mat.textures["diffuse"].url.substr(0,2);
				diffuse = mat.textures["diffuse"] as ExternalTextureResource;
				addResource(diffuse);
			}
			else
			{
				diffuse = new ColorTextureResource(0xFF0101);
				diffuse.upload();
			}
			
			
			if(mat.textures["bump"] !== null)
			{
				normal  = mat.textures["bump"] as ExternalTextureResource;
				addResource(normal);
			}
			else
			{
				normal = new ColorTextureResource(0x7F7FFF);
				normal.upload();
			}
			
			material = new StandardMaterial();
			if(typeMat=="t_")
			{
				material = new TextureMaterial();
				material.diffuseMap = diffuse;
			}		
			else
			{
				material.diffuseMap = diffuse;
				material.normalMap = normal;
			}
			
			  
			
			
			
			/*if(mat.textures["specular"] !== null)
			{
				specular  = mat.textures["specular"] as ExternalTextureResource;
				addResource(specular);
				material.specularMap = specular;
			}
			else
			{
				//specular = new ColorTextureResource(0x333333);
				//specular.upload();
			}*/
			
			
			/*if(mat.textures["transparent"] !== null)
			{
				opacity  = mat.textures["transparent"] as ExternalTextureResource;
				addResource(opacity);
				material.opacityMap = opacity;
				material.alphaThreshold = 0.89;
			}
			else
			{
				opacity = null;
			}	*/		
			
			
			/*if(mat.textures["glossiness"] !== null)
			{
				glossines  = mat.textures["glossiness"] as ExternalTextureResource;
				addResource(glossines);
				//material.glossinessMap = glossines;
				//material.glossiness = 0.98;
			}
			else
			{
				glossines = null;
			}	*/			

			//material = new StandardMaterial(diffuse, normal, specular,glossines,opacity);//		
			material.alphaThreshold = 0.89;
			return material;		
		}		
		
		private function textureComplite(e:Event):void
		{
			complite = true;
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		private function onTextures(event:Event):void {

		}				
	}

}