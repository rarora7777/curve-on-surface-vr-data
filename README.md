# Study Data: Mid-Air Drawing of Curves on Surfaces in VR

This repository provides MATLAB code to load and analyze the user study data collected for and reported in the TOG 2021 paper _Mid-air Drawing of Curves on 3D Surfaces in Virtual Reality_ by Arora and Singh. For further information, go to https://www.dgp.toronto.edu/~arorar/mimicry/.

## Installation

If you wish to use the provided MATLAB scripts to read and/or analyze the data, please read on. Otherwise, skip to step 4 to download the data.
1. Clone the repo, including submodules
```
git clone --recurse-submodules https://github.com/raora7777/curve-on-surface-vr-data
```
2. Then, build the `geodesic_matlab` submodule according to instructions: https://github.com/rarora7777/geodesic_matlab.
3. Download the dependency `gptoolbox` from https://github.com/alecjacobson/gptoolbox/ and add it to the MATLAB path according to the instructions in that repo.
4. Download the data [here](https://github.com/rarora7777/curve-on-surface-vr-data/releases/tag/v1.0) to the root folder of this repo (`somewhere/curve-on-surface-vr-data/`) and extract using the command (works on Linux and probably MacOS). On Windows, use 7-Zip: https://www.7-zip.org/.
```
tar -xf studydata.tar.xz
```
5. In MATLAB, change path to the root folder of this repo. Then use `init` to initialize.

## How to use
The following scripts/functions should get you started. These functions are self-documented.

`init`: This script initializes the global structures you'll need to read and analyze the user data.

`loadParticipantData`: This function loads the data for a single participant.

`analyzeParticipant`: This function computes all the measures reported in the paper for the strokes executed by a single participant.


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

For each participant, 12 `json` files were collected which contain the raw user study data. Data for a participant with ID `i` is in the folder `./studydata/pi`. with Each file contains the user-drawn curves for a particular shape and projection technique pair. The files are named as `<methodNumber>_<shapeNumber>.json`. For example, the data for curves drawn over the `bunny` shape using the Mimicry technique will be in the file `1_3.json`.

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

## Meshes used in the study

Please cite the original source of each mesh and respect the associated license agreements. Check the acknowledgements secion of the paper for details.

## Third-party code

This repository contains third party code in `interparc.m` and `tubeplot.m`. The licenses for those files are included directly in the files themselves. Both are opn, MIT-like licenses, but please check the actual license text if you're concerned.
 
