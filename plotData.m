function t = plotData(V, F, data, dataGT, shapeID, curveID, tubeRadius, ...
    plotRepeatCurve, useGeodesicCurve, strokePlotSelect)
    global geodesic_library;
    geodesic_library = 'geodesic_release';
    
    % Draw the target curve and/or user curve for a given user, shape ID,
    % and curve ID. The curves are drawn as a tube of the given radius.
    % V (target mesh vertices) : loaded in init.m
    % F (target mesh faces) : loaded in init.m
    % data (user data) : loaded using loadParticipantData()
    % dataGT (target curves data) : loaded in init.m
    % shapeID : ID of the model
    % strokeID : ID of the stroke
    % plotRepeatStroke : plot the original (default = false) or the repeat
    % (true)
    % useGeodesicCurve : trace geodesic segments before drawing (true) or
    % not (default = false)
    % strokePlotSelect : List of integers containing [0 1 2] (default) or a
    % subset. Including 0 draws the target curve, 1 draws the user curve
    % drawn using spraycan, and 2 draws the one using mimicry.
    
    if nargin < 8
        plotRepeatCurve = false;
    end
    
    if nargin < 9
        useGeodesicCurve = false;
    end
    
    if nargin < 10
        strokePlotSelect = [0 1 2];
    end
    
    if plotRepeatCurve
        d0 = data{1, shapeID}{curveID}.Repeat;
        d1 = data{2, shapeID}{curveID}.Repeat;
    else
        d0 = data{1, shapeID}{curveID};
        d1 = data{2, shapeID}{curveID};
    end
    
    [pts0, ~] = getPoints(V{shapeID}, F{shapeID}, d0);
    [pts1, ~] = getPoints(V{shapeID}, F{shapeID}, d1);
    ptsG = getPoints(V{shapeID}, F{shapeID}, dataGT(shapeID).SS(curveID));
    KP = getPoints(V{shapeID}, F{shapeID}, dataGT(shapeID).SS(curveID), true);
    
    
    % take inverse scale
    mat = reshape(d0(1).ModelMatrix.data, 4, 4);
    scale = 1./power(det(mat(1:3, 1:3)), 1/3);
    
    N = normals(V{shapeID}, F{shapeID});
    N = normalizerow(N);
    
    tidxKP = dataGT(shapeID).SS(curveID).FI(dataGT(shapeID).SS(curveID).KPI);
    textPos = KP + 1e-2*scale*N(tidxKP, :);
    
    
    tricolor = [227, 251, 227]/255;
    clf
    co = colororder;
    t = tsurf(F{shapeID}, [V{shapeID}(:, 1) -V{shapeID}(:, 3) V{shapeID}(:, 2)], ...
        'FaceAlpha', 0.5, 'EdgeAlpha', 0.5, ...
        'FaceColor', tricolor, 'EdgeColor', .75*tricolor);
%     lighting phong
    daspect([1 1 1])
    hold on
    
    if useGeodesicCurve
        mesh = geodesic_new_mesh(V{shapeID}, F{shapeID});
        algorithm = geodesic_new_algorithm(mesh, 'exact');
        if sum(ismember(strokePlotSelect, 1))
            [~, ~, path0] = geodesicCurvature(V{shapeID}, F{shapeID}, d0, algorithm);
            pts0 = [vertcat(cell2mat(path0).x), vertcat(cell2mat(path0).y) vertcat(cell2mat(path0).z)];
        end
        if sum(ismember(strokePlotSelect, 2))
            [~, ~, path1] = geodesicCurvature(V{shapeID}, F{shapeID}, d1, algorithm);
            pts1 = [vertcat(cell2mat(path1).x), vertcat(cell2mat(path1).y) vertcat(cell2mat(path1).z)];
        end
    end
    
    groundTruthAlpha = .25;
    if sum(ismember(strokePlotSelect, 0)) && numel(strokePlotSelect)==1
        groundTruthAlpha = 1;
    end
    
    % draw the tubes
    if sum(ismember(strokePlotSelect, 0))
        [x,y,z] = tubeplot([ptsG(:, 1) -ptsG(:, 3) ptsG(:, 2)], tubeRadius*scale, 6);
        surf(x,y,z, ...
            'FaceColor', 'k', 'EdgeAlpha', 0, 'FaceAlpha', groundTruthAlpha, ...
            'facelighting', 'none')
    end
    if sum(ismember(strokePlotSelect, 1))
        [x,y,z] = tubeplot([pts0(:, 1) -pts0(:, 3) pts0(:, 2)], tubeRadius*scale, 6);
        surf(x,y,z, 'FaceColor', co(1, :), 'EdgeAlpha', 0, 'facelighting', 'none')
    end
    if sum(ismember(strokePlotSelect, 2))
        [x,y,z] = tubeplot([pts1(:, 1) -pts1(:, 3) pts1(:, 2)], tubeRadius*scale, 6);
        surf(x,y,z, 'FaceColor', co(2, :), 'EdgeAlpha', 0, 'facelighting', 'none')
    end
    
    
    axis off
%     camlight left
%     material dull
    apply_ambient_occlusion(t, 'AddLights', false, 'Factor', 1/4);
    hold off
end
