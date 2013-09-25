package alternativa.engine3d.core{
	
	import alternativa.engine3d.alternativa3d;	
	import flash.display.*;
	import flash.events.*;
	import com.adobe.utils.AGALMiniAssembler;
    import flash.display3D.*;
    import flash.geom.Matrix3D;
    import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	import alternativa.engine3d.utils.Helpers;
	use namespace alternativa3d;	
	
	public class TextureRender {
		
		private var stage3D:Stage3D;
		private var context:Context3D;
		protected var worldTransform:Matrix3D;
        
        protected var vertBuf:VertexBuffer3D;
        protected var idxBuf:IndexBuffer3D;
		protected var uvBuf:VertexBuffer3D;
        
        protected var vertShaderAsm:AGALMiniAssembler = new AGALMiniAssembler;
        protected var fragShaderAsm:AGALMiniAssembler = new AGALMiniAssembler;
		
        protected var mulVertShader:AGALMiniAssembler = new AGALMiniAssembler;
        protected var mulFragShader:AGALMiniAssembler = new AGALMiniAssembler;		
		
		
        protected var program:Program3D;

		public var view:View;
		private var resReady:Boolean = false;

		public function TextureRender(view:View=null) {
			stage3D = Helpers.STAGE3D;
			context = stage3D.context3D;
			//context.enableErrorChecking=true;
			if(view!==null)
			{
				this.view = view;
			}
			readyResource();
			
		}
		
		private function readyResource():void {
            // vertex stream
            var verts:Vector.<Number> = new Vector.<Number>;
            verts.push( -1, -1, 0,
                        -1, 1, 0,
                        1, 1, 0,
                        1, -1, 0);
            vertBuf = context.createVertexBuffer(4, 3);
            vertBuf.uploadFromVector(verts, 0, 4);
            //context.setVertexBufferAt(0, vertBuf, 0, "float3")
            
            // index stream
            var indices:Vector.<uint> = new Vector.<uint>;
            indices.push(0, 2, 1,
                        2, 0, 3);
            idxBuf = context.createIndexBuffer(6);
            idxBuf.uploadFromVector(indices, 0, 6);
            
            // uv
            var uv:Vector.<Number> = new Vector.<Number>;
            uv.push(0, 1,
                    0, 0,
                    1, 0,
                    1, 1);
            uvBuf = context.createVertexBuffer(4, 2);
            uvBuf.uploadFromVector(uv, 0, 4);
			resReady=true;
        }
		
		private var presentProgramm:Program3D;
		
		public function presentTexture(tex1:TextureBase, size:Number=512):void
		{
			if (presentProgramm==null)
			{
				presentProgramm = context.createProgram();
				vertShaderAsm.assemble(Context3DProgramType.VERTEX,	"mov op, va0 \n mov v0, va1");
				fragShaderAsm.assemble(Context3DProgramType.FRAGMENT, "tex ft0, v0, fs0<2d,repeat,linear>\n mov oc, ft0\n");
				presentProgramm.upload(vertShaderAsm.agalcode, fragShaderAsm.agalcode);				
				
			}
			//var cloneProgramm:Program3D = context.createProgram();


			//Set resourse
			//context.configureBackBuffer(size, size, 4, false);
			//context.setRenderToTexture(outTexture,true);
			//readyResource();
			context.clear(0, 0, 0);
			context.setRenderToBackBuffer();
			context.setProgram(presentProgramm);
			context.setVertexBufferAt(0, vertBuf, 0, "float3");
			context.setVertexBufferAt(1, uvBuf, 0, "float2");
			context.setTextureAt(0, tex1);
			//render
			
            context.drawTriangles(idxBuf, 0, 2);
            context.present();
			//context.setRenderToBackBuffer();
			trace("present!");
		}			
		
		private var mullProgramm:Program3D;
		
		public function mullTexture(tex1:TextureBase, tex2:TextureBase, size:Number=512):TextureBase
		{
			var outTexture:Texture = context.createTexture(size, size, "bgra", true);
			if(view==null)
			{
				trace("View not initialise!");
				return outTexture;
			}
			
			if(mullProgramm==null)
			{
				mullProgramm = context.createProgram();
				mulVertShader.assemble(Context3DProgramType.VERTEX, "mov op, va0 \n mov v0, va1");
				mulFragShader.assemble(Context3DProgramType.FRAGMENT,
				//"tex ft1, v0, fs0<2d,repeat,linear,nomip>\n tex ft2, v0, fs1<2d,repeat,linear>\n sub ft0, ft2, ft1\n mul ft0, ft0, fc0.y\n add ft0, ft0, ft1\n mov oc, ft0\n"
					"tex ft1, v0, fs0<2d,repeat,linear,nomip>\n"+
					"tex ft2, v0, fs1<2d,repeat,linear>\n"+
					"sge ft3, ft1, ft2\n"+
					"mul ft1, ft1, ft3.xxxx\n"+
					"sge ft3, ft2, ft1\n"+
					"mul ft2, ft2, ft3.xxxx\n"+
					//"mov oc, ft2\n"
					//"mul ft0, ft0, fc0.y\n"+
					"add ft0, ft1, ft2\n"+
					"mov oc, ft0\n"
				);
				mullProgramm.upload(mulVertShader.agalcode, mulFragShader.agalcode);				
			}
			/*if(cloneProgramm==null)
			{
				cloneProgramm = context.createProgram();
				vertShaderAsm.assemble(Context3DProgramType.VERTEX,	
					"mov op, va0 \n"+
					"mov v0, va1");
				fragShaderAsm.assemble(Context3DProgramType.FRAGMENT, 
					"tex ft0, v0, fs0<2d,repeat,linear,nomip>\n"+//,repeat,linear,nomip
					"mov oc, ft0");
				cloneProgramm.upload(vertShaderAsm.agalcode, fragShaderAsm.agalcode);
			}*/
			
			//Set resourse
			context.setRenderToTexture(outTexture,true);
			context.configureBackBuffer(size, size, 4);
			context.setProgram(mullProgramm);
			context.setVertexBufferAt(0, vertBuf, 0, "float3");
			context.setVertexBufferAt(1, uvBuf, 0, "float2");
			//context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,0,Vector.<Number>([0.0, 0.65, 1.0, 2.0]));//.setFragmentConstantsFromNumbers(0, 0.0, 0.3, 1.0, 2.0);
			context.setTextureAt(0, tex1);
			context.setTextureAt(1, tex2);
			context.setDepthTest(false, Context3DCompareMode.LESS);
			//context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.DESTINATION_COLOR);
			//render
			
			
			
			context.clear(0, 0, 0, 0.3);
			
			context.drawTriangles(idxBuf, 0, 2);
			//context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE);
			//context.setProgram(cloneProgramm);
			//context.setTextureAt(0, tex2);
			//context.drawTriangles(idxBuf, 0, 2);            
            context.present();
			context.configureBackBuffer(view._width, view._height, view.antiAlias);
			context.setRenderToBackBuffer();
			
			return outTexture;
		}
		
		private var cloneProgramm:Program3D;
		
		public function cloneTexture(inTex:TextureBase, outTex:TextureBase, size:Number=512):TextureBase
		{
			var outTexture:Texture = context.createTexture(size, size, "bgra", true);
			if(cloneProgramm==null)
			{
				cloneProgramm = context.createProgram();
				vertShaderAsm.assemble(Context3DProgramType.VERTEX,	
					"mov op, va0 \n"+
					"mov v0, va1");
				fragShaderAsm.assemble(Context3DProgramType.FRAGMENT, 
					"tex ft0, v0, fs0<2d,repeat,linear,nomip>\n"+//,repeat,linear,nomip
					"mov oc, ft0");
				cloneProgramm.upload(vertShaderAsm.agalcode, fragShaderAsm.agalcode);
			}
			if(!resReady)
			{
				readyResource();
			}
			//
			//Set resourse
			context.setRenderToTexture(outTexture,true);
			
			context.configureBackBuffer(size, size, 4);
			
			context.setProgram(cloneProgramm);
			//context.set
			context.setVertexBufferAt(0, vertBuf, 0, "float3");
			context.setVertexBufferAt(1, uvBuf, 0, "float2");
			context.setTextureAt(0, inTex);
			context.setDepthTest(true, Context3DCompareMode.LESS);
			//render
			context.clear(1, 0, 0, 0.3);
            context.drawTriangles(idxBuf, 0, 2);
            context.present();
			context.configureBackBuffer(view._width, view._height, view.antiAlias);
			//view.configureContext3D(
			context.setRenderToBackBuffer();
			
			return outTexture;
		}		
		
		public function inverseTextureX(tex1:Texture, size:Number=512):Texture
		{
			var outTexture:Texture = context.createTexture(size, size, "bgra", true);
			var cloneProgramm:Program3D = context.createProgram();
			vertShaderAsm.assemble(Context3DProgramType.VERTEX,	"mov op, va0 \n mov v0, va1");
			fragShaderAsm.assemble(Context3DProgramType.FRAGMENT, "tex ft0, v0, fs0<2d,repeat,linear>\n mov oc, ft0\n");
			cloneProgramm.upload(vertShaderAsm.agalcode, fragShaderAsm.agalcode);
			
			//context.configureBackBuffer(size, size, 4, false);
			context.clear(0, 0, 0);
			context.setRenderToTexture(outTexture,true);
			context.setProgram(cloneProgramm);
			context.setVertexBufferAt(0, vertBuf, 0, "float3");
			context.setVertexBufferAt(1, uvBuf, 0, "float2");
			context.setTextureAt(0, tex1);
            context.drawTriangles(idxBuf, 0, 2);
            //if(bmp) context.drawToBitmapData(bmp.bitmapData)
            context.present();
			context.setRenderToBackBuffer();
			
			return outTexture;
		}				
		
		public function inverseTextureY(tex1:Texture, size:Number=512):Texture
		{
			var outTexture:Texture = context.createTexture(size, size, "bgra", true);
			var cloneProgramm:Program3D = context.createProgram();
			vertShaderAsm.assemble(Context3DProgramType.VERTEX,	"mov op, va0 \n mov v0, va1");
			fragShaderAsm.assemble(Context3DProgramType.FRAGMENT, "tex ft0, v0, fs0<2d,repeat,linear>\n mov oc, ft0\n");
			cloneProgramm.upload(vertShaderAsm.agalcode, fragShaderAsm.agalcode);
			
			//context.configureBackBuffer(size, size, 4, false);
			context.clear(0, 0, 0);
			context.setRenderToTexture(outTexture,true);
			context.setProgram(cloneProgramm);
			context.setVertexBufferAt(0, vertBuf, 0, "float3");
			context.setVertexBufferAt(1, uvBuf, 0, "float2");
			context.setTextureAt(0, tex1);
            context.drawTriangles(idxBuf, 0, 2);
            //if(bmp) context.drawToBitmapData(bmp.bitmapData)
            context.present();
			context.setRenderToBackBuffer();
			
			return outTexture;
		}		
	}
	
}
