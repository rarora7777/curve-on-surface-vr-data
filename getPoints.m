function [pts, ends] = getPoints(V, F, data, keypointOnly)
    
    % Extract the points of either a projected curve or a target curve.
    % V, F : A triangle mesh (note that this is a single mesh, unlike many
    % other functions in this repository).
    % data : data corresponding to a single target curve, either the target
    % curve itself or the user-drawn curve (see typical usage below)
    % keypointOnly : only return the keypoints (valid for the target curve
    % usage only, not for user curves)
    %
    % The second output `ends` contains the endpoints of the target curve
    % (in target curve usage) or of each continuous piece of the prokected
    % curves (in user curve usage). This output is meaningless when
    % keypointOnly is true.
    %
    % Typical usages (assuming dataGT, V, F loaded in init, and data loaded
    % in loadParticipantData):
    % Target curve mode:
    % methodID = 1; shapeID = 3; curveID = 5;
    % [pts, ends] = getPoints(V{shapeID}, F{shapeID}, dataGT(shapeID).SS(curveID));
    % User-drawn curve mode:
    % methodID = 1; shapeID = 3; curveID = 5;
    % [pts, ends] = getPoints(V{shapeID}, F{shapeID}, data{methodID, shapeID}{curveID});
    
    if nargin < 4
        keypointOnly = false;
    end
    
    % struct containing user-drawn curves
    if isfield(data, 'P')
        pts = vertcat(data.P);
        pts = [vertcat(pts.x), vertcat(pts.y), vertcat(pts.z)];
        ends = zeros(1, 2*numel(data));
        ends(1) = 1;
        ends(2) = numel(data(1).P);
        for i=2:numel(data)
            ends(2*i-1) = ends(2*i-2) + 1;
            ends(2*i) = ends(2*i-2) + numel(data(i).P);
        end
    % struct containing target curves
    elseif isfield(data, 'FI') && isfield(data, 'B')
        if keypointOnly
            pts = getCartesianFromBarycentric(V, F, ...
                data.FI(data.KPI), data.B(data.KPI, :));
        else
            pts = getCartesianFromBarycentric(V, F, data.FI, data.B);
        end
        ends = [1, size(pts, 1)];
    else
        warning('Invalid data structure!');
        pts = zeros(0, 3);
        ends = [];
    end
end
        
        
