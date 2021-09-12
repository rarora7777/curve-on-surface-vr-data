function t = plotData(V, F, data, dataGT, s, str, tubeRadius, ...
    plotRepeatStroke, useGeodesicCurve, strokePlotSelect)
    global geodesic_library;
    geodesic_library = 'geodesic_release';
    
    if nargin < 8
        plotRepeatStroke = false;
    end
    
    if nargin < 9
        useGeodesicCurve = false;
    end
    
    if nargin < 10
        strokePlotSelect = [0 1 2];
    end
    
    if plotRepeatStroke
        d0 = data{1, s}{str}.Repeat;
        d1 = data{2, s}{str}.Repeat;
    else
        d0 = data{1, s}{str};
        d1 = data{2, s}{str};
    end
    
    [pts0, ends0] = getPoints(V{s}, F{s}, d0);
    [pts1, ends1] = getPoints(V{s}, F{s}, d1);
    ptsG = getPoints(V{s}, F{s}, dataGT(s).SS(str));
    KP = getPoints(V{s}, F{s}, dataGT(s).SS(str), true);
    
    
    % take inverse scale
    mat = reshape(d0(1).ModelMatrix.data, 4, 4);
    scale = 1./power(det(mat(1:3, 1:3)), 1/3);
    
    N = normals(V{s}, F{s});
    N = normalizerow(N);
    
    tidxKP = dataGT(s).SS(str).FI(dataGT(s).SS(str).KPI);
    textPos = KP + 1e-2*scale*N(tidxKP, :);
    
    
    tricolor = [227, 251, 227]/255;
    clf
    co = colororder;
    t = tsurf(F{s}, [V{s}(:, 1) -V{s}(:, 3) V{s}(:, 2)], ...
        'FaceAlpha', 0.5, 'EdgeAlpha', 0.5, ...
        'FaceColor', tricolor, 'EdgeColor', .75*tricolor);
%     lighting phong
    daspect([1 1 1])
    hold on
%     xlabel('X')
%     ylabel('Y')
%     zlabel('Z')
    
    if useGeodesicCurve
        mesh = geodesic_new_mesh(V{s}, F{s});
        algorithm = geodesic_new_algorithm(mesh, 'exact');
        if sum(ismember(strokePlotSelect, 1))
            [~, ~, path0] = geodesicCurvature(V{s}, F{s}, d0, algorithm);
            pts0 = [vertcat(cell2mat(path0).x), vertcat(cell2mat(path0).y) vertcat(cell2mat(path0).z)];
        end
        if sum(ismember(strokePlotSelect, 2))
            [~, ~, path1] = geodesicCurvature(V{s}, F{s}, d1, algorithm);
            pts1 = [vertcat(cell2mat(path1).x), vertcat(cell2mat(path1).y) vertcat(cell2mat(path1).z)];
        end
    end
    
    groundTruthAlpha = .25;
    if sum(ismember(strokePlotSelect, 0)) && numel(strokePlotSelect)==1
        groundTruthAlpha = 1;
    end
    
    % draw the tubes
    if sum(ismember(strokePlotSelect, 0))
        [x,y,z] = util.tubeplot([ptsG(:, 1) -ptsG(:, 3) ptsG(:, 2)], tubeRadius*scale, 6);
        surf(x,y,z, ...
            'FaceColor', 'k', 'EdgeAlpha', 0, 'FaceAlpha', groundTruthAlpha, ...
            'facelighting', 'none')
    end
    if sum(ismember(strokePlotSelect, 1))
        [x,y,z] = util.tubeplot([pts0(:, 1) -pts0(:, 3) pts0(:, 2)], tubeRadius*scale, 6);
        surf(x,y,z, 'FaceColor', co(1, :), 'EdgeAlpha', 0, 'facelighting', 'none')
    end
    if sum(ismember(strokePlotSelect, 2))
        [x,y,z] = util.tubeplot([pts1(:, 1) -pts1(:, 3) pts1(:, 2)], tubeRadius*scale, 6);
        surf(x,y,z, 'FaceColor', co(2, :), 'EdgeAlpha', 0, 'facelighting', 'none')
    end
    
%     kpcolor = [107 67 33]/255;
%     % draw keypoints
%     if sum(ismember(strokePlotSelect, 0))
%         scatter3(KP(:, 1), KP(:, 2), KP(:, 3), 40, kpcolor, 'filled')
%     end
%     
%     %draw ends of user strokes
%     if sum(ismember(strokePlotSelect, 1))
%         scatter3(pts0(ends0, 1), pts0(ends0, 2), pts0(ends0, 3), 30, co(1, :)/1.25, 'filled')
%     end
%     if sum(ismember(strokePlotSelect, 2))
%         scatter3(pts1(ends1, 1), pts1(ends1, 2), pts1(ends1, 3), 30, co(2, :)/1.25, 'filled')
%     end
%     
%     if sum(ismember(strokePlotSelect, 0))
%         text(textPos(:, 1), textPos(:, 2), textPos(:, 3), ...
%             num2str((1:size(KP, 1))' - 1), ...
%             'FontSize', 12, 'FontWeight', 'bold', ...
%             'Color', kpcolor, ...
%             'HorizontalAlignment', 'center');
%     end
    
    axis off
%     camlight left
%     material dull
    apply_ambient_occlusion(t, 'AddLights', false, 'Factor', 1/4);
    hold off
end
