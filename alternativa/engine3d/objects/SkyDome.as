package alternativa.engine3d.objects {
	import alternativa.engine3d.alternativa3d;	
	import alternativa.engine3d.loaders.ParserA3D;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.resources.Geometry;
	import flash.utils.ByteArray;
	import alternativa.engine3d.utils.Helpers;
	import alternativa.engine3d.resources.ATFTextureResource;
	import alternativa.engine3d.materials.TextureMaterial;
	
	use namespace alternativa3d;
	
	public class SkyDome {
		//D:\Program Files\Adobe\Flex_libray\libs\alternativa\engine3d\rez
		[Embed("../../rez/SkyDome.A3D", mimeType="application/octet-stream")]
		private static const SceneClass:Class;	
		
		[Embed("../../rez/SkyDome.atf",mimeType = "application/octet-stream")]
		private const SkyClass:Class;
		
		public var mesh:Mesh;
		
		public function SkyDome() {
			var parser:ParserA3D = new ParserA3D();
			parser.parse(new SceneClass());
			
			mesh = parser.getObjectByName("SkyDome") as Mesh;
			mesh.geometry.upload();
			
			var sky_res:ATFTextureResource = new ATFTextureResource(new SkyClass() as ByteArray);
			sky_res.upload();
			
			mesh.setMaterialToAllSurfaces(new TextureMaterial(sky_res));
		}
		
		public function setSize(value:Number):void
		{
			mesh.scaleXYZ = value;
		}
	}
	
}
