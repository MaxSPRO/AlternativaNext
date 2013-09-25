package alternativa.engine3d.primitives
{
    import __AS3__.vec.*;
    import flash.geom.*;
    import flash.utils.*;

    public class ExtraVertex extends Object
    {
        public var vertex:Vector3D;
        public var normals:Dictionary;
        public var indices:Vector.<uint>;

        public function ExtraVertex(param1:Number, param2:Number, param3:Number)
        {
            this.vertex = new Vector3D(param1, param2, param3);
            this.normals = new Dictionary();
            this.indices = new Vector.<uint>;
            return;
        }// end function

    }
}
