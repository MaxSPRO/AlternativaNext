package alternativa.physics.extend {
	import alternativa.engine3d.materials.Material;
	import flash.display.BitmapData;


	/** 
	* 
	* @public 
	* @author redefy 
	*/
	public class A3DTerrain extends Elevation {

		/** 
		* 
		* @private 
		*/
		private var _segmentsW : int;

		/** 
		* 
		* @private 
		*/
		private var _segmentsH : int;

		/** 
		* 
		* @private 
		*/
		private var _maxHeight : Number;

		/** 
		* 
		* @private 
		*/
		private var _heights : Vector.<Number>;

		public function A3DTerrain(material : Material, heightMap : BitmapData, width : Number = 1000, height : Number = 100, depth : Number = 1000, segmentsW : uint = 30, segmentsH : uint = 30, maxElevation : uint = 255, minElevation : uint = 0, smoothMap : Boolean = false) {
			super(material, heightMap, width, height, depth, segmentsW, segmentsH, maxElevation, minElevation, smoothMap);

			_segmentsW = segmentsW;
			_segmentsH = segmentsH;
			_maxHeight = maxElevation;

			var _minW : Number = -width / 2;
			var _minH : Number = -depth / 2;
			var _dw : Number = width / segmentsW;
			var _dh : Number = depth / segmentsH;

			_heights = new Vector.<Number>();
			for ( var iy : int = 0; iy < _segmentsH; iy++ ) {
				for ( var ix : int = 0; ix < _segmentsW; ix++ ) {
					_heights.push(this.getHeightAt(_minW + (_dw * ix), _minH + (_dh * iy)));
				}
			}
		}

		public function get sw() : int {
			return _segmentsW;
		}

		public function get sh() : int {
			return _segmentsH;
		}

		public function get lw() : Number {
			return this.width;
		}

		public function get lh() : Number {
			return this.depth;
		}

		public function get maxHeight() : Number {
			return _maxHeight;
		}

		public function get heights() : Vector.<Number> {
			return _heights;
		}
	}
}