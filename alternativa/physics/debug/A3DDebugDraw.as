﻿package alternativa.physics.debug {
	
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Resource;
	import alternativa.engine3d.objects.WireFrame;
	import alternativa.engine3d.resources.Geometry;
	
	import alternativa.physics.collision.dispatch.A3DRay;
	import alternativa.physics.collision.dispatch.A3DCollisionObject;
	import alternativa.physics.collision.shapes.*;
	import alternativa.physics.data.A3DCollisionShapeType;
	import alternativa.physics.data.A3DTypedConstraintType;
	import alternativa.physics.dynamics.A3DDynamicsWorld;
	import alternativa.physics.dynamics.constraintsolver.*;
	import alternativa.physics.math.A3DTransform;
	
	import flash.display.Stage3D;
	import flash.display.Sprite;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.getTimer;
	

	/** 
	* Класс реализующий механизм debug отрисовки тел.
	* @public 
	* @author redefy 
	*/
	public class A3DDebugDraw {

		/** 
		* Ничего не отрисовывать
		* @public (constant) 
		*/
		public static const DBG_NoDebug : int = 0;

		/** 
		* Отрисовывать шейпы
		* @public (constant) 
		*/
		public static const DBG_DrawCollisionShapes : int = 1;

		/** 
		* Отрисовывать ограничения
		* @public (constant) 
		*/
		public static const DBG_DrawConstraints : int = 2;

		/** 
		* Отрисовывать лимиты ограничений, то есть от какой до какой точки действует ограничение.
		* @public (constant) 
		*/
		public static const DBG_DrawConstraintLimits : int =4;

		/** 
		* Отрисовывать оси XYZ, для каждого тела
		* @public (constant) 
		*/
		public static const DBG_DrawTransform:int = 8;
		
		/** 
		* Отрисовывать лучи
		* @public (constant) 
		*/
		public static const DBG_DrawRay : int = 16;
		

		private var _stage3D:Stage3D;
		private var _physicsWorld:A3DDynamicsWorld;
		private var _container:Object3D;
		private var _containerLines:WireFrame;
	
		private var linesFFFFFF:Vector.<Vector3D> = Vector.<Vector3D>([]);
		private var lines00FF00:Vector.<Vector3D> = Vector.<Vector3D>([]);
		private var lines00FFFF:Vector.<Vector3D> = Vector.<Vector3D>([]);
		private var linesFF0000:Vector.<Vector3D> = Vector.<Vector3D>([]);
		private var linesFFFF00:Vector.<Vector3D> = Vector.<Vector3D>([]);
		private var lines0000FF:Vector.<Vector3D> = Vector.<Vector3D>([]);
		
		private var m_debugMode:int;
		

		/** 
		* Конструктор
		* @public 
		* @param stage3D ссылка на используемую в проекте stage3D
		* @param container контейнер в котором будут отрисовываться debug тела
		* @param physicsWorld ссылка на мир Bullet
		*/
		public function A3DDebugDraw(stage3D:Stage3D, container:Object3D, physicsWorld:A3DDynamicsWorld) {
			_stage3D = stage3D;	
			_container = container;
			
			_physicsWorld = physicsWorld;
			m_debugMode = 1;
		}
		

		/** 
		* Флаги отрисовки
		* @public (getter) 
		* @return int 
		*/
		public function get debugMode():int {
			return m_debugMode;
		}

		/** 
		* Передавайте в этот геттер флаги, определяющие какие виды объектов отрисовывать
		* @public (setter) 
		* @param mode 
		* @return void 
		*/
		public function set debugMode(mode:int):void {
			m_debugMode = mode;
		}
		
		private function drawLine(from:Vector3D, to:Vector3D, color:uint):void {
			switch (color) {
				case 0xffffff: linesFFFFFF.push(from, to); break;
				case 0x00ff00: lines00FF00.push(from,to); break;
				case 0x00ffff: lines00FFFF.push(from, to); break;
				case 0xff0000: linesFF0000.push(from, to); break;
				case 0xffff00: linesFFFF00.push(from, to); break;
				case 0x0000FF: lines0000FF.push(from, to); break;
			}
			
		}
		
		private function drawSphere(radius:Number, transform:A3DTransform, color:uint):void {
			var pos:Vector3D = transform.position;
			var rot:Matrix3D = transform.rotationWithMatrix;
			
			var xoffs:Vector3D = rot.transformVector(new Vector3D(radius, 0, 0));
			var yoffs:Vector3D = rot.transformVector(new Vector3D(0, radius, 0));
			var zoffs:Vector3D = rot.transformVector(new Vector3D(0, 0, radius));
			
			drawLine(pos.subtract(xoffs), pos.add(yoffs), color);
			drawLine(pos.add(yoffs), pos.add(xoffs), color);
			drawLine(pos.add(xoffs), pos.subtract(yoffs), color);
			drawLine(pos.subtract(yoffs), pos.subtract(xoffs), color);

			drawLine(pos.subtract(xoffs), pos.add(zoffs), color);
			drawLine(pos.add(zoffs), pos.add(xoffs), color);
			drawLine(pos.add(xoffs), pos.subtract(zoffs), color);
			drawLine(pos.subtract(zoffs), pos.subtract(xoffs), color);

			drawLine(pos.subtract(yoffs), pos.add(zoffs), color);
			drawLine(pos.add(zoffs), pos.add(yoffs), color);
			drawLine(pos.add(yoffs), pos.subtract(zoffs), color);
			drawLine(pos.subtract(zoffs), pos.subtract(yoffs), color);
		}
		
		private function drawTriangle(v0:Vector3D, v1:Vector3D, v2:Vector3D, color:uint):void {
			drawLine(v0, v1, color);
			drawLine(v1, v2, color);
			drawLine(v2, v0, color);
		}
		
		private function drawAabb(from:Vector3D, to:Vector3D, color:uint):void {
			var halfExtents:Vector3D = to.subtract(from);
			halfExtents.scaleBy(0.5);
			var center:Vector3D = to.subtract(from);
			center.scaleBy(0.5);
			var i:int, j:int, othercoord:int;

			var edgecoord:Vector.<Number> = new Vector.<Number>(3, true);
			edgecoord[0] = 1;
			edgecoord[1] = 1;
			edgecoord[2] = 1;
			
			var pa:Vector3D = new Vector3D();
			var pb:Vector3D = new Vector3D();
			for (i = 0; i < 4; i++)
			{
				for (j = 0; j < 3; j++)
				{
					pa.setTo(edgecoord[0] * halfExtents.x, edgecoord[1] * halfExtents.y, edgecoord[2] * halfExtents.z);
					pa = pa.add(center);
					
					othercoord = j % 3;
					edgecoord[othercoord] *= -1;
					pb.setTo(edgecoord[0] * halfExtents.x, edgecoord[1] * halfExtents.y, edgecoord[2] * halfExtents.z);
					pb += center;
					
					drawLine(pa,pb,color);
				}
				edgecoord[0] = -1;
				edgecoord[1] = -1;
				edgecoord[2] = -1;
				if (i<3)
					edgecoord[i] *= -1;
			}
		}
		
		private function drawTransform(transform:A3DTransform, orthoLen:Number):void {
			var pos:Vector3D = transform.position;
			var rot:Matrix3D = transform.rotationWithMatrix;
			
			drawLine(pos, pos.add(rot.transformVector(new Vector3D(orthoLen, 0, 0))), 0xff0000);
			drawLine(pos, pos.add(rot.transformVector(new Vector3D(0, orthoLen, 0))), 0x00ff00);
			drawLine(pos, pos.add(rot.transformVector(new Vector3D(0, 0, orthoLen))), 0x0000ff);
		}
		
		private function drawArc(center:Vector3D, normal:Vector3D, axis:Vector3D, radiusA:Number, radiusB:Number, minAngle:Number, maxAngle:Number, color:uint, drawSect:Boolean, stepDegrees:Number = 10):void {
			var vx:Vector3D = axis;
			var vy:Vector3D = normal.crossProduct(axis);
			var step:Number = stepDegrees * 2 * Math.PI / 360;
			var nSteps:int = int((maxAngle - minAngle) / step);
			if (!nSteps) nSteps = 1;
			
			var temp:Vector3D;
			temp = vx.clone();
			temp.scaleBy(radiusA * Math.cos(minAngle));
			var prev:Vector3D = center.add(temp);
			temp = vy.clone();
			temp.scaleBy(radiusB * Math.sin(minAngle));
			prev = prev.add(temp);
			if(drawSect)
			{
				drawLine(center, prev, color);
			}
			
			var angle:Number;
			var next:Vector3D;
			for(var i:int = 1; i <= nSteps; i++)
			{
				angle = minAngle + (maxAngle - minAngle) * i / nSteps;
				temp = vx.clone();
				temp.scaleBy(radiusA * Math.cos(angle));
				next = center.add(temp);
				temp = vy.clone();
				temp.scaleBy(radiusB * Math.sin(angle));
				next = next.add(temp);
				drawLine(prev, next, color);
				prev = next;
			}
			if(drawSect)
			{
				drawLine(center, prev, color);
			}
		}
		
		private function drawSpherePatch(center:Vector3D, up:Vector3D, axis:Vector3D, radius:Number, minTh:Number, maxTh:Number, minPs:Number, maxPs:Number, color:uint, stepDegrees:Number = 10):void {
			
		}
		
		private function drawBox(bbMin:Vector3D, bbMax:Vector3D, transform:A3DTransform, color:uint):void {
			var from:Vector3D = new Vector3D();
			var to:Vector3D = new Vector3D();
			
			var pos:Vector3D = transform.position;
			var rot:Matrix3D = transform.rotationWithMatrix;
			
			from.setTo(bbMin.x, bbMin.y, bbMin.z);
			from = rot.transformVector(from);
			from = from.add(pos);
			to.setTo(bbMax.x, bbMin.y, bbMin.z);
			to = rot.transformVector(to);
			to = to.add(pos);
			drawLine(from, to, color);
			
			from = new Vector3D(0, 0, 0);
			to = new Vector3D(0, 0, 0);
			
			from.setTo(bbMax.x, bbMin.y, bbMin.z);
			from = rot.transformVector(from);
			from = from.add(pos);
			to.setTo(bbMax.x, bbMax.y, bbMin.z);
			to = rot.transformVector(to);
			to = to.add(pos);
			drawLine(from, to, color);
			
			from = new Vector3D(0, 0, 0);
			to = new Vector3D(0, 0, 0);
			
			from.setTo(bbMax.x, bbMax.y, bbMin.z);
			from = rot.transformVector(from);
			from = from.add(pos);
			to.setTo(bbMin.x, bbMax.y, bbMin.z);
			to = rot.transformVector(to);
			to = to.add(pos);
			drawLine(from, to, color);
			
			from = new Vector3D(0, 0, 0);
			to = new Vector3D(0, 0, 0);
			
			from.setTo(bbMin.x, bbMax.y, bbMin.z);
			from = rot.transformVector(from);
			from = from.add(pos);
			to.setTo(bbMin.x, bbMin.y, bbMin.z);
			to = rot.transformVector(to);
			to = to.add(pos);
			drawLine(from, to, color);
			
			from = new Vector3D(0, 0, 0);
			to = new Vector3D(0, 0, 0);
			
			from.setTo(bbMin.x, bbMin.y, bbMin.z);
			from = rot.transformVector(from);
			from = from.add(pos);
			to.setTo(bbMin.x, bbMin.y, bbMax.z);
			to = rot.transformVector(to);
			to = to.add(pos);
			drawLine(from, to, color);
			
			from = new Vector3D(0, 0, 0);
			to = new Vector3D(0, 0, 0);
			
			from.setTo(bbMax.x, bbMin.y, bbMin.z);
			from = rot.transformVector(from);
			from = from.add(pos);
			to.setTo(bbMax.x, bbMin.y, bbMax.z);
			to = rot.transformVector(to);
			to = to.add(pos);
			drawLine(from, to, color);
			
			from = new Vector3D(0, 0, 0);
			to = new Vector3D(0, 0, 0);
			
			from.setTo(bbMax.x, bbMax.y, bbMin.z);
			from = rot.transformVector(from);
			from = from.add(pos);
			to.setTo(bbMax.x, bbMax.y, bbMax.z);
			to = rot.transformVector(to);
			to = to.add(pos);
			drawLine(from, to, color);
			
			from = new Vector3D(0, 0, 0);
			to = new Vector3D(0, 0, 0);
			
			from.setTo(bbMin.x, bbMax.y, bbMin.z);
			from = rot.transformVector(from);
			from = from.add(pos);
			to.setTo(bbMin.x, bbMax.y, bbMax.z);
			to = rot.transformVector(to);
			to = to.add(pos);
			drawLine(from, to, color);
			
			from = new Vector3D(0, 0, 0);
			to = new Vector3D(0, 0, 0);
			
			from.setTo(bbMin.x, bbMin.y, bbMax.z);
			from = rot.transformVector(from);
			from = from.add(pos);
			to.setTo(bbMax.x, bbMin.y, bbMax.z);
			to = rot.transformVector(to);
			to = to.add(pos);
			drawLine(from, to, color);
			
			from = new Vector3D(0, 0, 0);
			to = new Vector3D(0, 0, 0);
			
			from.setTo(bbMax.x, bbMin.y, bbMax.z);
			from = rot.transformVector(from);
			from = from.add(pos);
			to.setTo(bbMax.x, bbMax.y, bbMax.z);
			to = rot.transformVector(to);
			to = to.add(pos);
			drawLine(from, to, color);
			
			from = new Vector3D(0, 0, 0);
			to = new Vector3D(0, 0, 0);
			
			from.setTo(bbMax.x, bbMax.y, bbMax.z);
			from = rot.transformVector(from);
			from = from.add(pos);
			to.setTo(bbMin.x, bbMax.y, bbMax.z);
			to = rot.transformVector(to);
			to = to.add(pos);
			drawLine(from, to, color);
			
			from = new Vector3D(0, 0, 0);
			to = new Vector3D(0, 0, 0);
			
			from.setTo(bbMin.x, bbMax.y, bbMax.z);
			from = rot.transformVector(from);
			from = from.add(pos);
			to.setTo(bbMin.x, bbMin.y, bbMax.z);
			to = rot.transformVector(to);
			to = to.add(pos);
			drawLine(from, to, color);
		}
		
		private function drawCapsule(radius:Number, halfHeight:Number, upAxis:int, transform:A3DTransform, color:uint):void {
			var pos:Vector3D = transform.position;
			var rot:Matrix3D = transform.rotationWithMatrix;
			
			var capStart:Vector3D = new Vector3D();
			capStart.y = -halfHeight;

			var capEnd:Vector3D = new Vector3D();
			capEnd.y = halfHeight;

			var tr:A3DTransform = transform.clone();
			tr.position = transform.transform.transformVector(capStart);
			drawSphere(radius, tr, color);
			tr.position = transform.transform.transformVector(capEnd);
			drawSphere(radius, tr, color);

			// Draw some additional lines
			capStart.z = radius;
			capEnd.z = radius;
			drawLine(pos.add(rot.transformVector(capStart)), pos.add(rot.transformVector(capEnd)), color);
			capStart.z = -radius;
			capEnd.z = -radius;
			drawLine(pos.add(rot.transformVector(capStart)), pos.add(rot.transformVector(capEnd)), color);

			capStart.z = 0;
			capEnd.z = 0;

			capStart.x = radius;
			capEnd.x = radius;
			drawLine(pos.add(rot.transformVector(capStart)), pos.add(rot.transformVector(capEnd)), color);
			capStart.x = -radius;
			capEnd.x = -radius;
			drawLine(pos.add(rot.transformVector(capStart)), pos.add(rot.transformVector(capEnd)), color);
		}
		
		private function drawCylinder(radius:Number, halfHeight:Number, upAxis:int, transform:A3DTransform, color:uint):void {
			var pos:Vector3D = transform.position;
			var rot:Matrix3D = transform.rotationWithMatrix;
			
			var	offsetHeight:Vector3D = new Vector3D(0, halfHeight, 0);
			var	offsetRadius:Vector3D = new Vector3D(0, 0, radius);
			drawLine(pos.add(rot.transformVector(offsetHeight.add(offsetRadius))), pos.add(rot.transformVector(offsetRadius.subtract(offsetHeight))), color);
			
			var vec:Vector3D = offsetHeight.add(offsetRadius);
			vec.scaleBy(-1);
			drawLine(pos.add(rot.transformVector(offsetHeight.subtract(offsetRadius))), pos.add(rot.transformVector(vec)), color);

			// Drawing top and bottom caps of the cylinder
			var yaxis:Vector3D = new Vector3D(0, 1, 0);
			var xaxis:Vector3D = new Vector3D(0, 0, 1);
			drawArc(pos.subtract(rot.transformVector(offsetHeight)), rot.transformVector(yaxis), rot.transformVector(xaxis), radius, radius, 0, 2 * Math.PI, color, false, 10);
			drawArc(pos.add(rot.transformVector(offsetHeight)), rot.transformVector(yaxis), rot.transformVector(xaxis), radius, radius, 0, 2 * Math.PI, color, false, 10);
		}
		
		private function drawCone(radius:Number, height:Number, upAxis:int, transform:A3DTransform, color:uint):void {
			var pos:Vector3D = transform.position;
			var rot:Matrix3D = transform.rotationWithMatrix;

			var	offsetHeight:Vector3D = new Vector3D(0, 0.5 * height, 0);
			var	offsetRadius:Vector3D = new Vector3D(0, 0, radius);
			var	offset2Radius:Vector3D = new Vector3D(radius, 0, 0);

			var vec:Vector3D;
			drawLine(pos.add(rot.transformVector(offsetHeight)), pos.add(rot.transformVector(offsetRadius.subtract(offsetHeight))), color);
			vec = offsetHeight.add(offsetRadius);
			vec.scaleBy(-1);
			drawLine(pos.add(rot.transformVector(offsetHeight)), pos.add(rot.transformVector(vec)), color);
			drawLine(pos.add(rot.transformVector(offsetHeight)), pos.add(rot.transformVector(offset2Radius.subtract(offsetHeight))), color);
			vec = offsetHeight.add(offset2Radius);
			vec.scaleBy(-1);
			drawLine(pos.add(rot.transformVector(offsetHeight)), pos.add(rot.transformVector(vec)), color);

			// Drawing the base of the cone
			var yaxis:Vector3D = new Vector3D(0, 1, 0);
			var xaxis:Vector3D = new Vector3D(0, 0, 1);
			drawArc(pos.subtract(rot.transformVector(offsetHeight)), rot.transformVector(yaxis), rot.transformVector(xaxis), radius, radius, 0, 2 * Math.PI, color, false, 10);
		}
		
		private function drA3Dlane(planeNormal:Vector3D, planeConst:Number, transform:A3DTransform, color:uint):void {
			var pos:Vector3D = transform.position;
			var rot:Matrix3D = transform.rotationWithMatrix;
			
			var planeOrigin:Vector3D = planeNormal.clone();
			planeOrigin.scaleBy(planeConst);
			var vec0:Vector3D = new Vector3D();
			var vec1:Vector3D = new Vector3D();
			btPlaneSpace1(planeNormal, vec0, vec1);
			var vecLen:Number = 100*_physicsWorld.scaling;
			vec0.scaleBy(vecLen);
			vec1.scaleBy(vecLen);
			var pt0:Vector3D = planeOrigin.add(vec0);
			var pt1:Vector3D = planeOrigin.subtract(vec0);
			var pt2:Vector3D = planeOrigin.add(vec1);
			var pt3:Vector3D = planeOrigin.subtract(vec1);
			
			pt0 = rot.transformVector(pt0);
			pt0 = pt0.add(pos);
			pt1 = rot.transformVector(pt1);
			pt1 = pt1.add(pos);
			drawLine(pt0, pt1, color);
			
			pt2 = rot.transformVector(pt2);
			pt2 = pt2.add(pos);
			pt3 = rot.transformVector(pt3);
			pt3 = pt3.add(pos);
			drawLine(pt2, pt3, color);
		}
		 
		private function btPlaneSpace1(n:Vector3D, p:Vector3D, q:Vector3D):void {
			if (Math.abs(n.z) > 0.707) {
				var a:Number = n.y * n.y + n.z * n.z;
				var k:Number = 1 / Math.sqrt(a);
				p.x = 0;
				p.y = -n.z * k;
				p.z = n.y * k;
				// set q = n x p
				q.x = a*k;
				q.y = -n.x * p.z;
				q.z = n.x * p.y;
			} else {
				a = n.x * n.x + n.y * n.y;
				k = 1 / Math.sqrt(a);
				p.x = -n.y * k;
				p.y = n.x * k;
				p.z = 0;
				q.x = -n.z * p.y;
				q.y = n.z * p.x;
				q.z = a * k;
		    }
		}
		
		private function drawTriangles(geometry:Geometry, scale:Vector3D, transform:A3DTransform, color:uint):void {
			var indexData:Vector.<uint> = geometry.indices;
			var vertexData:Vector.<Number> = geometry.getAttributeValues(VertexAttributes.POSITION)
			var indexDataLen:int = indexData.length;
			
			var m:int = 0;
			var v0:Vector3D = new Vector3D(0,0,0);
			var v1:Vector3D = new Vector3D(0,0,0);
			var v2:Vector3D = new Vector3D(0,0,0);
			for (var i:int = 0; i < indexDataLen; i += 3 ) {
				v0.setTo(vertexData[3*indexData[m]] * scale.x, vertexData[3*indexData[m]+1] * scale.y, vertexData[3*indexData[m]+2] * scale.z);
				m++;
				v1.setTo(vertexData[3*indexData[m]] * scale.x, vertexData[3*indexData[m]+1] * scale.y, vertexData[3*indexData[m]+2] * scale.z);
				m++;
				v2.setTo(vertexData[3*indexData[m]] * scale.x, vertexData[3*indexData[m]+1] * scale.y, vertexData[3*indexData[m]+2] * scale.z);
				m++;
				drawTriangle(transform.transform.transformVector(v0), transform.transform.transformVector(v1), transform.transform.transformVector(v2), color);
			}
		}
		
		private function debugDrawObject(transform:A3DTransform, shape:A3DCollisionShape, color:uint):void {
			if (m_debugMode & A3DDebugDraw.DBG_DrawTransform) {
				drawTransform(transform, 200);
			}
			
			if (shape.shapeType == A3DCollisionShapeType.COMPOUND_SHAPE) {
				var i:int = 0;
				var childTrans:A3DTransform;
				var compoundShape:A3DCompoundShape = shape as A3DCompoundShape;
				for each (var sp:A3DCollisionShape in compoundShape.children) {
					childTrans = compoundShape.getChildTransform(i).clone();
					childTrans.appendTransform(transform);
					debugDrawObject(childTrans, sp, color);
					i++;
				}
			}else if (shape.shapeType == A3DCollisionShapeType.BOX_SHAPE) {
				var boxShape:A3DBoxShape = shape as A3DBoxShape;
				var halfExtents:Vector3D = boxShape.dimensions;
				halfExtents.scaleBy(0.5);
				drawBox(new Vector3D( -halfExtents.x, -halfExtents.y, -halfExtents.z), halfExtents, transform, color);
			}else if (shape.shapeType == A3DCollisionShapeType.SPHERE_SHAPE) {
				var sphereShape:A3DSphereShape = shape as A3DSphereShape;
				drawSphere(sphereShape.radius, transform, color);
			}else if (shape.shapeType == A3DCollisionShapeType.CAPSULE_SHAPE) {
				var capsuleShape:A3DCapsuleShape = shape as A3DCapsuleShape;
				drawCapsule(capsuleShape.radius, capsuleShape.height / 2, 1, transform, color);
			}else if (shape.shapeType == A3DCollisionShapeType.CONE_SHAPE) {
				var coneShape:A3DConeShape = shape as A3DConeShape;
				drawCone(coneShape.radius, coneShape.height, 1, transform, color);
			}else if (shape.shapeType == A3DCollisionShapeType.CYLINDER_SHAPE) {
				var cylinder:A3DCylinderShape = shape as A3DCylinderShape;
				drawCylinder(cylinder.radius, cylinder.height / 2, 1, transform, color);
			}else if (shape.shapeType == A3DCollisionShapeType.STATIC_PLANE) {
				var staticPlaneShape:A3DStaticPlaneShape = shape as A3DStaticPlaneShape;
				drA3Dlane(staticPlaneShape.normal, staticPlaneShape.constant, transform, color);
			}else if (shape.shapeType == A3DCollisionShapeType.CONVEX_HULL_SHAPE) {
				var convex:A3DConvexHullShape = shape as A3DConvexHullShape;
				drawTriangles(convex.geometry, convex.localScaling, transform, color);
			}else if (shape.shapeType == A3DCollisionShapeType.TRIANGLE_MESH_SHAPE) {
				var triangleMesh:A3DBvhTriangleMeshShape = shape as A3DBvhTriangleMeshShape;
				drawTriangles(triangleMesh.geometry, triangleMesh.localScaling, transform, color);
			}else if (shape.shapeType == A3DCollisionShapeType.HEIGHT_FIELD_TERRAIN) {
				var terrain:A3DHeightfieldTerrainShape = shape as A3DHeightfieldTerrainShape;
				drawTriangles(terrain.geometry, terrain.localScaling, transform, color);
			}
		}
		
		private function debugDrawConstraint(constraint:A3DTypedConstraint):void {
			var drawFrames:Boolean = ((m_debugMode & A3DDebugDraw.DBG_DrawConstraints) != 0);
			var drawLimits:Boolean = ((m_debugMode & A3DDebugDraw.DBG_DrawConstraintLimits) != 0);
			if (constraint.constraintType == A3DTypedConstraintType.POINT2POINT_CONSTRAINT_TYPE) {
				var p2pC:A3DPoint2PointConstraint = constraint as A3DPoint2PointConstraint;
				var tr:A3DTransform = new A3DTransform();
				var pivot:Vector3D = p2pC.pivotInA.clone();
				pivot = p2pC.rigidBodyA.transform.transformVector(pivot);
				tr.position = pivot;
				if (drawFrames) drawTransform(tr, 200);
				if (p2pC.rigidBodyB) {
					pivot = p2pC.pivotInB.clone();
					pivot = p2pC.rigidBodyB.transform.transformVector(pivot);
					tr.position = pivot;
					if (drawFrames) drawTransform(tr, 200);
				}
			}else if (constraint.constraintType == A3DTypedConstraintType.HINGE_CONSTRAINT_TYPE) {
				var pHinge:A3DHingeConstraint = constraint as A3DHingeConstraint;
				var pos:Vector3D = pHinge.rigidBodyA.worldTransform.position;
				var rot:Matrix3D = pHinge.rigidBodyA.worldTransform.rotationWithMatrix;
				var from:Vector3D = rot.transformVector(pHinge.pivotInA);
				from = from.add(pos);
				var to:Vector3D = rot.transformVector(pHinge.axisInA);
				to.scaleBy(200);
				to = from.add(to);
				if (drawFrames) drawLine(from,to,0xff0000);
				if (pHinge.rigidBodyB) {
					pos = pHinge.rigidBodyB.worldTransform.position;
					rot = pHinge.rigidBodyB.worldTransform.rotationWithMatrix;
					from = rot.transformVector(pHinge.pivotInB);
					from = from.add(pos);
					to = rot.transformVector(pHinge.axisInB);
					to.scaleBy(200);
					to = from.add(to);
					if (drawFrames) drawLine(from,to,0xff0000);
				}
				
				var minAng:Number = pHinge.limit.low;
				var maxAng:Number = pHinge.limit.high;
				if (minAng != maxAng) {
					var drawSect:Boolean = true;
					if(minAng > maxAng) {
						minAng = 0;
						maxAng = 2 * Math.PI;
						drawSect = false;
					}
					if (drawLimits) {
						var normal:Vector3D = to.subtract(from);
						normal.normalize();
						var axis:Vector3D = normal.crossProduct(new Vector3D(0, 0, 1));
						if (axis.length > -0.01 && axis.length < 0.01) {
							axis = normal.crossProduct(new Vector3D(0, -1, 0));
						}
						axis.normalize();
						to = rot.transformVector(axis);
						to.scaleBy(200);
						to = from.add(to);
						drawLine(from,to,0x00ff00);
						drawArc(from, normal, axis, 200, 200, minAng, maxAng, 0xffff00, drawSect);
					}
				}
			}else if (constraint.constraintType == A3DTypedConstraintType.CONETWIST_CONSTRAINT_TYPE) {
				var pCT:A3DConeTwistConstraint = constraint as A3DConeTwistConstraint;
				var trA:A3DTransform = pCT.rbAFrame.clone();
				trA.appendTransform(pCT.rigidBodyA.worldTransform);
				if (drawFrames) drawTransform(trA, 200);
				if (pCT.rigidBodyB) {
					var trB:A3DTransform = pCT.rbBFrame.clone();
					trB.appendTransform(pCT.rigidBodyB.worldTransform);
					if (drawFrames) drawTransform(trB, 200);
				}
				if (drawLimits) {
					rot = pCT.rigidBodyA.worldTransform.rotationWithMatrix;
					normal = rot.transformVector(pCT.rbAFrame.axisZ);
					axis = rot.transformVector(pCT.rbAFrame.axisY);
					minAng = -pCT.swingSpan1;
					maxAng = pCT.swingSpan1;
					drawArc(trA.position, normal, axis, 200, 200, minAng, maxAng, 0xffff00, true);
					
					normal = rot.transformVector(pCT.rbAFrame.axisX);
					axis = rot.transformVector(pCT.rbAFrame.axisY);
					minAng = -pCT.twistSpan;
					maxAng = pCT.twistSpan;
					drawArc(trA.position, normal, axis, 200, 200, minAng, maxAng, 0xffff00, true);
					
					normal = rot.transformVector(pCT.rbAFrame.axisY);
					axis = rot.transformVector(pCT.rbAFrame.axisX);
					minAng = -pCT.swingSpan2;
					maxAng = pCT.swingSpan2;
					drawArc(trA.position, normal, axis, 200, 200, minAng, maxAng, 0xffff00, true);
				}
			}else if (constraint.constraintType == A3DTypedConstraintType.D6_CONSTRAINT_TYPE) {
				var p6DOF:A3DGeneric6DofConstraint = constraint as A3DGeneric6DofConstraint;
				trA = p6DOF.rbAFrame.clone();
				trA.appendTransform(p6DOF.rigidBodyA.worldTransform);
				if (drawFrames) drawTransform(trA, 200);
				if (p6DOF.rigidBodyB) {
					trB = p6DOF.rbBFrame.clone();
					trB.appendTransform(p6DOF.rigidBodyB.worldTransform);
					if (drawFrames) drawTransform(trB, 200);
				}
				if (drawLimits) {
					rot = p6DOF.rigidBodyA.worldTransform.rotationWithMatrix;
					normal = rot.transformVector(p6DOF.rbAFrame.axisX);
					axis = rot.transformVector(p6DOF.rbAFrame.axisY);
					minAng = p6DOF.getRotationalLimitMotor(0).loLimit;
					maxAng = p6DOF.getRotationalLimitMotor(0).hiLimit;
					drawArc(trA.position, normal, axis, 200, 200, minAng, maxAng, 0xffff00, true);
					
					rot = p6DOF.rigidBodyA.worldTransform.rotationWithMatrix;
					normal = rot.transformVector(p6DOF.rbAFrame.axisY);
					axis = rot.transformVector(p6DOF.rbAFrame.axisX);
					minAng = p6DOF.getRotationalLimitMotor(1).loLimit;
					maxAng = p6DOF.getRotationalLimitMotor(1).hiLimit;
					drawArc(trA.position, normal, axis, 200, 200, minAng, maxAng, 0xffff00, true);
					
					rot = p6DOF.rigidBodyA.worldTransform.rotationWithMatrix;
					normal = rot.transformVector(p6DOF.rbAFrame.axisZ);
					axis = rot.transformVector(p6DOF.rbAFrame.axisY);
					minAng = p6DOF.getRotationalLimitMotor(2).loLimit;
					maxAng = p6DOF.getRotationalLimitMotor(2).hiLimit;
					drawArc(trA.position, normal, axis, 200, 200, minAng, maxAng, 0xffff00, true);
					
					var bbMin:Vector3D = p6DOF.getTranslationalLimitMotor().lowerLimit;
					var bbMax:Vector3D = p6DOF.getTranslationalLimitMotor().upperLimit;
					drawBox(bbMin, bbMax, trA, 0xffff00);
				}
			}
		}
		
		private function removeAllLines():void {
			linesFFFFFF.splice(0, linesFFFFFF.length);
			linesFFFF00.splice(0, linesFFFF00.length);
			linesFF0000.splice(0, linesFF0000.length);
			lines00FFFF.splice(0, lines00FFFF.length);
			lines00FF00.splice(0, lines00FF00.length);
			lines0000FF.splice(0, lines0000FF.length);
			if (_containerLines) {
				for each (var resource:Resource in _containerLines.getResources(true)) {resource.dispose();}
				_container.removeChild(_containerLines);
			}
				
		}
		

		/** 
		* Вызывайте для перерисовки тел.
		* @public 
		* @return void 
		*/
		public function debugDrawWorld():void {
			if (m_debugMode & A3DDebugDraw.DBG_NoDebug) return;
			
			removeAllLines();
			if (m_debugMode & A3DDebugDraw.DBG_DrawCollisionShapes)
			{
				var color:uint;
				for each (var obj:A3DCollisionObject in _physicsWorld.collisionObjects) {
					switch(obj.activationState)
					{
						case  A3DCollisionObject.ACTIVE_TAG:
							color = 0xffffff; break;
						case A3DCollisionObject.ISLAND_SLEEPING:
							color = 0x00ff00; break;
						case A3DCollisionObject.WANTS_DEACTIVATION:
							color = 0x00ffff; break;
						case A3DCollisionObject.DISABLE_DEACTIVATION:
							color = 0xff0000; break;
						case A3DCollisionObject.DISABLE_SIMULATION:
							color = 0xffff00; break;
						default:
							color = 0xff0000;
					}
					debugDrawObject(obj.worldTransform, obj.shape, color);
				}
			if (m_debugMode & A3DDebugDraw.DBG_DrawRay) {
   	          for each (var ray:A3DRay in obj.rays) {
						drawLine(obj.worldTransform.transform.transformVector(ray.rayFrom), obj.worldTransform.transform.transformVector(ray.rayTo), 0xff0000);
   	           }
			}
   	       }
			
			if (m_debugMode & (A3DDebugDraw.DBG_DrawConstraints | A3DDebugDraw.DBG_DrawConstraintLimits))
			{
				for each(var constraint:A3DTypedConstraint in _physicsWorld.constraints) {
					debugDrawConstraint(constraint);
				}
			}
			
			_containerLines = new WireFrame();
			
			if (linesFFFFFF.length) _containerLines.addChild(WireFrame.createLinesList(linesFFFFFF, 0xFFFFFF, 1, 2));
			if (lines00FF00.length) _containerLines.addChild(WireFrame.createLinesList(lines00FF00, 0x00FF00, 1, 2));
			if (linesFFFF00.length) _containerLines.addChild(WireFrame.createLinesList(linesFFFF00, 0xFFFF00, 1, 2));
			if (linesFF0000.length) _containerLines.addChild(WireFrame.createLinesList(linesFF0000, 0xFF0000, 1, 2));
			if (linesFFFF00.length) _containerLines.addChild(WireFrame.createLinesList(linesFFFF00, 0xFFFF00, 1, 2));
			if (lines0000FF.length) _containerLines.addChild(WireFrame.createLinesList(lines0000FF, 0x0000FF, 1, 2));
			for each (var resource:Resource in _containerLines.getResources(true)) { resource.upload(_stage3D.context3D); }
			_container.addChild(_containerLines);
			
		}
	}
}