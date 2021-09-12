# Study Data: Mid-Air Drawing of Curves on Surfaces in VR


## Schema for input data

Input data for the study data, that is, the target curves, is provided in the file `./input/study_geometric.json`. The schema is as follows:

```
{
  // PSD (per-shape data): the data for each target object (shape) used in the study.
  // PSD is an array of 6 elements, one for each target object.
  "PSD" :
  [
    {
	  // SS (study stroke): the data for each target curve for this shape.
	  // SS is an array of 10 elements, one for each target curve.
      "SS" :
      [
	    // Let the number of points in this curve be n.
	    { 
		  // Array of n integer elements, giving the 1-indexed face for each point of the curve.
		  "FI"    : [],
		  // Array of n elements, each of which is an array of 3 floats, representing the barycentric coordinate of each point in the corresponding face. Together, "FI" and "B" store the implicit positions of the target curve's points on the target mesh.
		  "B"     :
		  [
		    [b00, b01, b12], 
			[b10, b11, b12], ...
		  ], 
		  // An array of integers, storing the indices (assuming 1-indexing) of the keypoints among the curve points.
		  "KPI"   : [],
		  // The rest of the data are the parameters required to generate this stroke. See Appendix B in the paper. The seed is provided to the MATLAB function generateCurveOnMesh().
		  "seed"  : ,
		  "nc"    : ,
		  "dist"  : ,
		  "angle" :
		}, 
		{
		  "FI:    : ...
		}, ...
	  ]
    }, 
	{
	  "SS" : ...
	}, ...
  ]
}
```


## Schema for study sequence data

For each participant, the order of the two projection techniques and the order of the target curves was varied using a file `study_sequence.json` included with the shipped study executable. The file follows a simple schema.

```
{
  // Order of the two projection techniques.
  // MethodSequence is an array of 2 integers: a permutation of [0, 1].
  // 0 is SprayCan and 1 is Mimicry.
  "MethodSequence" : [],
  // Order of the six study shapes.
  // ShapeSequence is an array of 6 integers, a permutation of [0, ..., 5].
  // This was not varied between participants during out study.
  // 0: torus, 1: cube, 2: trebol, 3: bunny, 4: hand, 5: fertility
  "ShapeSequence" : [],
  // Order of the target curves.
  // StrokeSequence is an array of 12 integers: the 1st to 5th and 7th to 11th entries are a permutation of [0, ...9], while the 6th and 12th are repeated strokes, and are equal to the 1st and 7th, respectively.
  "StrokeSequence" : []
}
```

## Schema for user data

For each user, 12 `json` files were collected which contain the raw user study data. Each file contains the user-drawn curves for a particular shape and projection technique pair. The files are named as `<methodNumber>_<shapeNumber>.json`. For example, the data for curves drawn over the `bunny` shape using the Mimicry technique will be in the file `1_3.json`.

The schema used for the user data is as follows.

```
// A 72-member array of user-drawn strokes, in the order the target curves were presented.
[
  // Each of the elements of the top-level array stores the user inputs for a given target curve.
  // While the user only draws a single continuous stroke in 3D, it can break into multiple projected curves if one or more of the 3D points fails to project onto the target surface.
  // NOTE: This can only happen with the spraycan technique, as mimicry projections are guaranteed to succeed.
  [
    // Each element of this array is a piece of the user stroke that continuously projects to the target surface.
    {
	  // Say the number of points in this piece is n.
	  // P is an n-sized array of projected points ({q_i} in the paper). Each element is a struct as shown below.
	  // 
      "P": 
	  [
	    { 
		  "x" : float,
		  "y" : float, 
		  "z" : float
		}, ...
	  ],
	  
	  // F is an n-sized array containing additional information about the projected point and the system state information for each 3D point.
	  "F" :
	  [
	    {
		  // F(i).PT is same as the corresponding P(i), that is, the ith projected point.
		  "PT" : {"x": float, "y": float, "z": float},
		  
		  // Normal to the surface at the projected point
		  "N"  : {"x": float, "y": float, "z": float},
		  
		  // F(i).TI is the 1-indexed id of the face containing P(i)
		  "TI" : int,
		  
		  // F(i).B is the barycentric coordinate of the point P(i) in the triangle F(i).TI
		  "B"  : {"x": float, "y": float, "z": float},
		  
		  // Distance between the ith 3D point and the projected point (in local coordinates, use ModelMatrix below to scale the distance to world coordinates if needed or directly multiply with the scale values provided in init.m).
		  "D"  : float,
		  
		  // DF (data frame) provides system state information.
		  // All the information is in the target model's local coordinates.
		  "DF" :
		  {
		    // The timestamp (in ms). The zero is when the user started the study. 
		    "T"  : float,
			
			// Position of the head. Note that any device-specific corrections are not performed and this is simply the position of the HMD returned by SteamVR.
			"HP" : {"x": float, "y": float, "z": float},
			
			// Position of the pen.
			"PP: : {"x": float, "y": float, "z": float},
			
			// Up-vector of the HMD.
			"HU" : {"x": float, "y": float, "z": float},
			
			// Forward-vector of the HMD.
			"HF" : {"x": float, "y": float, "z": float},
			
			// Up-vector of the controller.
			"CU" : {"x": float, "y": float, "z": float},
			
			// Forward-vector of the controller.
			"CF" : {"x": float, "y": float, "z": float},
			
			// Spraypaint raycast direction.
			"SD" : {"x": float, "y": float, "z": float},
		  }
		}, ...
	  ],
	  
	  // M stores the projection type. Either "Spray" (Spraycan) or "AnchorPhong" (Mimicry)
	  "M" : string,
	  
	  // ModelMatrix is a struct with only one member called "data".
	  // ModelMatrix.data is a 16-element float array, storing the transformation matrix of the target surface when this stroke was created. The matrix is stored in a column-major format. Post-multiply a point stored as a row-vector to convert it to world space.
	  "ModelMatrix" : 
	  {
	    "data" : [float, float, ...]
	  }
	}, 
	{
	  "P": ...
	}, ...
  ]  
]
```

 