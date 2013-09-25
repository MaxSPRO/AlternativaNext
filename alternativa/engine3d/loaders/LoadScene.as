package alternativa.engine3d.loaders
{
	/**
	 * ...
	 * @author MaxSPro
	 */
	import alternativa.engine3d.core.Object3D;
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
	import alternativa.engine3d.materials.VertexLightTextureMaterial;
	import alternativa.engine3d.utils.*;
	import alternativa.engine3d.lights.AmbientLight;
	import alternativa.engine3d.lights.OmniLight;
	import alternativa.engine3d.lights.DirectionalLight;
	import alternativa.engine3d.lights.SpotLight;	
	import alternativa.engine3d.resources.ColorTextureResource;
	
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
	
	import flash.events.SecurityErrorEvent;
	import flash.events.IOErrorEvent;
	
	/*import alternativaphysics.collision.dispatch.A3DCollisionObject;
	import alternativaphysics.collision.shapes.*;
	import alternativaphysics.dynamics.*;
	//import by.max.alternativa.felink.Alternativa3D4Physics;
	import alternativaphysics.dynamics.A3DDynamicsWorld;
	import by.max.alternativa.utils.VectorUtil;
	import by.max.alternativa.LoadWorldBullet;	import alternativaphysics.dynamics.vehicle.*;*/
	
	
	public class LoadScene extends Object3D
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
		private var format:String="A3D";
		
		private var msh:Mesh;
		private var light:*;
		private var mat:ParserMaterial;
		private var surface:Surface;
		private var diffuse:*;  
		private var normal:*; 
		private var specular:*;
		private var material:StandardMaterial;
		private var textures:Vector.<ExternalTextureResource> = new Vector.<ExternalTextureResource>();
		private var parser:*;
				
		public function LoadScene(url:String, scene:Object3D=null) 
		{
			_URL=url;
			_texturePatch = url.substr(0, url.lastIndexOf('/')+1);
			_scene = this;
			if(scene!==null){_scene = scene;}
			format = url.substr(url.lastIndexOf('.')+1);
			
					
			var loaderA3D:URLLoader = new URLLoader();
			loaderA3D.dataFormat = URLLoaderDataFormat.BINARY;
			loaderA3D.load(new URLRequest(_URL));//+"?nocash="+String(Math.random())
			loaderA3D.addEventListener(Event.COMPLETE, onLoad); //окончание загрузки
			loaderA3D.addEventListener(SecurityErrorEvent.SECURITY_ERROR, httpRequestError);
			loaderA3D.addEventListener(IOErrorEvent.IO_ERROR, httpRequestError);
		}
	
		private function httpRequestError(error:* ):void
		{ 
			trace("ioErrorHandler: " + error);
		}	
		
		private function onLoad(e:Event):void {
			if(format == "DAE" || format == "dae")
			{
				parser = new ParserCollada();
				parser.parse(XML((e.target as URLLoader).data), _texturePatch, false );
			}
			else
			{
				parser = new ParserA3D();
				parser.parse((e.target as URLLoader).data);	
			}
			
					
			for each (var obj:Object3D in parser.objects) 
			{    
                 //trace(obj.toString());
				 if (obj is Mesh) 
				 {    
					msh = obj as Mesh; 
					_scene.addChild(msh);				
					msh.geometry.upload();

					for (var i:int = 0; i < msh.numSurfaces; i++) 
					{  
						surface = msh.getSurface(i);  
						mat = surface.material as ParserMaterial;
						if (mat != null) 
						{
							surface.material = getMaterial(mat);
						}
					}
				 } 
				 else if(obj is AmbientLight)
				 {
					light = obj as AmbientLight;
					//trace("AmbientLight: "+light.name);
					_scene.addChild(light);
				 }
				 else if(obj is OmniLight)
				 {
					light = obj as OmniLight;
					//trace("OmniLight: "+light.name+': <'+String(light.attenuationBegin)+'> '+String(light.attenuationEnd));
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
		
		private function getMaterial(mat:ParserMaterial):StandardMaterial
		{		
			if(mat.textures["diffuse"] !== null)
			{
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
			  
			if(mat.textures["specular"] !== null)
			{
				specular  = mat.textures["specular"] as ExternalTextureResource;
				addResource(specular);
			}
			else
			{
				specular = new ColorTextureResource(0x333333);
				specular.upload();
			}

			material = new StandardMaterial(diffuse, normal, specular);//		
			material.alphaThreshold = 0.98;
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