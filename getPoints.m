function [pts, ends] = getPoints(V, F, data, keypointOnly)
    
    % number of strokes
%     n = numel(data);
    
    if nargin < 4
        keypointOnly = false;
    end
    
    % struct containing study strokes
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
        
        
