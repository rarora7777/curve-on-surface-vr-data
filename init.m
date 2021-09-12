numShape = 6;
numMethod = 2;
numStroke = 10;

% names of all the models (in order)
modelNames = [...
    "torus", "cube", "trebol", "bunny", "hand", "fertility"];

% Names of the projection techniques is:
% 1: spraycan
% 2: mimicry
% When referring to the "1st technique" anywhere in the code, we mean
% spraycan. Similary, "2nd technique" is mimicry.

% scale at which the models were shown to the participants
scales = [.4 .25 .15 .4 .45 .6];

% load the meshes (takes some time).
V = cell(numShape, 1);
F = cell(numShape, 1);
for s=1:numShape
[V{s}, F{s}] = readOBJ("shapes/" + modelNames(s) + ".obj");
end

addpath('geodesic_matlab/matlab/')
addpath('geodesic_matlab/src/')
addpath('geodesic_matlab/build/Release/')
% addpath('smooth-closest-point/')
% addpath('smooth-closest-point/matlab/')
% addpath('smooth-closest-point/decimator/')

% Some useful conversion functions
% Converts an n×1 or 1×n array of structs of the form
% ('x', <double>, 'y', <double>, 'z', <double>)
% to an n×3 matrix.
toMat = @(s) [vertcat(s.x) vertcat(s.y) vertcat(s.z)];

% Conversion similar to above, but additionally convert from a Y-up to Z-up
% coordinate system.
toMatR = @(s) [vertcat(s.x) -vertcat(s.z) vertcat(s.y)];

% All the participant ids. Participant IDs 12 and 17 were assigned but
% could not be utilized due to system incompatibilities.
pid = [1 2 3 4 5 6 7 8 9 10 11 13 14 15 16 18 19 20 21 22];