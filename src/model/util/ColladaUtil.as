package model.util
{
import mx.formatters.DateFormatter;

import org.papervision3d.core.geom.renderables.Triangle3D;
import org.papervision3d.core.geom.renderables.Vertex3D;
import org.papervision3d.core.math.NumberUV;
import org.papervision3d.objects.DisplayObject3D;

public class ColladaUtil
{
	private static var numTriangles:Number;
	
	/* This is the public function called to create the COLLADA XML from the array of geometries. */
	public static function getCollada(geometries:Array,imageURL:String=""):String
	{
		var collada:XML = new XML("<COLLADA version=\"1.4.0\" xmlns=\"http://www.collada.org/2005/11/COLLADASchema\"/>");
		collada.appendChild(getAsset(imageURL));
		collada.appendChild(getGeometries(geometries));
		collada.appendChild(getVisualScene(geometries));
		collada.appendChild(getScene());
		return collada.toString();
	}
	
	/* Get the asset portion of the COLLADA. */
	private static function getAsset(imageURL:String):XML
	{
		var formatter:DateFormatter = new DateFormatter();
		formatter.formatString = "YYYY-MM-DDTJ:NN:SS";
		var date:String = formatter.format(new Date());
		
		var asset:XML = new XML("<asset/>");
		
		var contributor:XML = new XML("<contributor/>");
		contributor.author = "MITH - http://mith.umd.edu";
		asset.appendChild(contributor);
		
		if(imageURL != "")
		{
			asset.image_url = imageURL;
		}
		
		asset.created = asset.modified = date;
		
		return asset;
	}
	
	/* Returns the geometries portion of the COLLADA which has the geometry, mesh and position-array. */
	private static function getGeometries(geometries:Array):XML
	{
		var geoms:XML = new XML(<library_geometries/>);
		
		var do3d:DisplayObject3D;
		var ts:Array;
		var triangle:Triangle3D;
		var minVal:Number = Number.MAX_VALUE;
		
		/* Calculate the scale */
		for each(do3d in geometries)
		{
			ts = do3d.geometry.faces;
			for each(triangle in ts)
			{
				var v0:Vertex3D = triangle.v0;
				var v1:Vertex3D = triangle.v1;
				var v2:Vertex3D = triangle.v2;
				
				var minX:Number = Math.min(Math.abs(v0.x),Math.abs(v1.x),Math.abs(v2.x));
				var minY:Number = Math.min(Math.abs(v0.y),Math.abs(v1.y),Math.abs(v2.y));
				var minZ:Number = Math.min(Math.abs(v0.z),Math.abs(v1.z),Math.abs(v2.z));
				
				minVal = Math.min(minX,minY,minZ);
			}
		}
		
		var scale:Number = 1/minVal;
		
		for each(do3d in geometries)
		{
			var name:String = do3d.name;
			
			ts = do3d.geometry.faces;
			numTriangles = ts.length;
			
			var vs:Array = [];
			for each(triangle in ts)
			{
				vs.push(triangle.v0,triangle.v1,triangle.v2);
			}
			
			var indexHash:Object = {};
			
			var pos:Number = 0;
			var positions:Array = [], ps:Array = [];
			for each(var vertex:Vertex3D in vs)
			{
				var x:Number = vertex.x, y:Number = vertex.y, z:Number = vertex.z;
				if(indexHash[x] == null) indexHash[x] = {};
				if(indexHash[x][y] == null) indexHash[x][y] = {};
				if(indexHash[x][y][z] == null)
				{
					indexHash[x][y][z] = pos;
					pos++;
					var decimals:Number = 2;
					var multiplier:Number = Math.pow(10,decimals);
					var xScaled:Number = Math.round(x*scale*multiplier)/multiplier;
					var yScaled:Number = Math.round(y*scale*multiplier)/multiplier;
					var zScaled:Number = Math.round(z*scale*multiplier)/multiplier;
					positions.push(xScaled,yScaled,zScaled);
				}
				
				ps.push(indexHash[x][y][z]);
			}
			
			// geometry
			var geometry:XML = new XML(<geometry/>);
			geometry.@id = geometry.@name = name;
			geoms.appendChild(geometry);
			
			// mesh
			var mesh:XML = new XML(<mesh/>);
			geometry.appendChild(mesh);
			
			// position
			var positionString:String = positions.toString().replace(/,/g," ");
			var count:Number = positions.length/3;
			
			var position:XML = new XML(<source/>);
			position.@id = name + "-position";
			mesh.appendChild(position);
			
			var floatArray:XML = new XML(<float_array/>);
			floatArray.@count = positions.length;
			floatArray.@id = name + "-position-array";
			floatArray.appendChild(positionString);
			position.appendChild(floatArray);
			
			var techniqueCommon:XML = new XML(<technique_common/>);
			position.appendChild(techniqueCommon);
			
			var accessor:XML = new XML(<accessor stride="3"/>);
			accessor.@count = count;
			accessor.@source = "#" + name + "-position-array";
			accessor.appendChild(<param type="float" name="X"/>);
			accessor.appendChild(<param type="float" name="Y"/>);
			accessor.appendChild(<param type="float" name="Z"/>);			
			techniqueCommon.appendChild(accessor);
			
			// vertices
			var vertices:XML = new XML(<vertices/>);
			vertices.@id = name + "-vertices";
			mesh.appendChild(vertices);
			
			var input:XML = new XML(<input/>);
			input.@semantic = "POSITION";
			input.@source = "#" + name + "-position";
			vertices.appendChild(input);
			
			// triangles
			var triangles:XML = new XML(<triangles/>);
			triangles.@count = numTriangles;
			mesh.appendChild(triangles);
			
			input = new XML(<input offset="0" semantic="VERTEX"/>);
			input.@source = "#" + name + "-vertices";
			triangles.appendChild(input);
			
			var p:XML = new XML(<p/>);
			p.appendChild(ps.toString().replace(/,/g," "));
			triangles.appendChild(p);
		}
		
		return geoms;
	}
	
	/* Returns the visual scene porition of the COLLADA. */
	private static function getVisualScene(geometries:Array):XML
	{
		var scenes:XML = new XML(<library_visual_scenes/>);
		var scene:XML = new XML(<visual_scene id="scene" name="scene"/>);
		scenes.appendChild(scene);
		
		for each(var do3d:DisplayObject3D in geometries)
		{
			var name:String = do3d.name;
			
			var node:XML = new XML(<node/>);
			node.@layer = name + "-layer";
			scene.appendChild(node);
			
			var instanceGeometry:XML = new XML(<instance_geometry/>);
			instanceGeometry.@url = "#" + name;
			node.appendChild(instanceGeometry);
			
			var bindMaterial:XML = new XML(
				<bind_material>
					<technique_common>
						<material>
							<instance_effect>
								<newparam>
									<surface>
										<plane/>
									</surface>
								</newparam>
							</instance_effect>
						</material>
					</technique_common>
				</bind_material>);
			instanceGeometry.appendChild(bindMaterial);
		}
		
		return scenes;
	}
	
	/* Returns the scene portion of the COLLADA. */
	private static function getScene():XML
	{
		return new XML(<scene><instance_visual_scene url="#scene"/></scene>);
	}
}
}