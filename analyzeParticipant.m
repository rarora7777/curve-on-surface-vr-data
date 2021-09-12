function [result, kpdist, rawData] = analyzeParticipant(V, F, data, dataGT, seq)
    global geodesic_library;
    geodesic_library = 'geodesic_release';

    
    [numMethod, numShape] = size(data);
    numStroke = numel(data{1, 1});
    
    assert(numel(V) >= numShape);
    assert(numel(F) >= numShape);
    
    kmean = zeros(numShape*(numStroke + 2), numMethod);
    gkmean = kmean;
    gfair = kmean;
    prepTime = kmean;
    execTime = kmean;
    numPieces = kmean;
    distMean = kmean;
    distMeanHauss = kmean;
    effortHeadTranslate = kmean;
    effortHeadRotate = kmean;
    effortPenTranslate = kmean;
    effortPenRotate = kmean;
%     distMeanTrace = kmean;
%     distMeanFree = kmean;
    rawData = cell(numShape*(numStroke + 2), numMethod);
    numKP = kmean;
    strokeId = zeros(numShape*(numStroke + 2));
    shapeId = zeros(numShape*(numStroke + 2));
    
    
    kpdist = cell(numShape*numStroke, numMethod);
    
    for s=1:numShape
        tic;
        
        mat = reshape(data{1, s}{1}(1).ModelMatrix.data, 4, 4);
        scale = power(det(mat(1:3, 1:3)), 1/3);
        
        mesh = geodesic_new_mesh(V{s}, F{s});
        algorithm = geodesic_new_algorithm(mesh, 'exact');
            
        fprintf('\nShape #%d: |V|=%d, |F|=%d, scale=%0.2f\n', ...
            s, size(V{s}, 1), size(F{s}, 1), scale);
        
        for str=1:(numStroke+2)
            idx = (s-1)*(numStroke+2) + str;
            
            if str <= numStroke
                strG = str;
            elseif str == numStroke+1
                strG = seq.StrokeSequence(1+numStroke/2);
            else
                strG = seq.StrokeSequence(2+numStroke);
            end
            
            shapeId(idx) = s;
            strokeId(idx) = strG;
                
            ptsG = getPoints(V{s}, F{s}, dataGT(s).SS(strG));
%             ptsGtrace = ptsG(1:dataGT(s).SS(str).KPI(2), :);
%             ptsGfree = ptsG(1+dataGT(s).SS(str).KPI(2):end, :);
            ptsG = util.interparc(0:.01:1, ptsG, 'spline');
            edge = diff(ptsG, [], 1) * scale;
            eLen = vecnorm(edge, 2, 2);
            L = sum(eLen);
%             ptsGtrace = util.interparc(0:.01:1, ptsGtrace, 'spline');
%             ptsGfree = util.interparc(0:.01:1, ptsGfree, 'spline');
%             
%             if ~isfield(data{1, s}{str}, 'F') || ~isfield(data{2, s}{str}, 'F')
%                 fprintf('Skipping %d %d due to missing data (%d %d)\n', ...
%                     s, str, ...
%                     isfield(data{1, s}{str}, 'F'), isfield(data{2, s}{str}, 'F'));
%                 continue;
%             end
            
            for m=1:numMethod
                fprintf('%d,%d  ', str, m);
                
                if str <= numStroke
                    userStrokeData = data{m, s}{strG};
                else
                    userStrokeData = data{m, s}{strG}.Repeat;
                end
                
                if ~isfield(userStrokeData, 'F')
                    fprintf('Skipping due to missing data\n');
                    continue;
                end
                
                % preparation and execution time
                prepTime(idx, m) = userStrokeData(1).F(1).DF.T;
                execTime(idx, m) = userStrokeData(end).F(end).DF.T - prepTime(idx, m);
                
                % number of pieces
                numPieces(idx, m) = numel(userStrokeData);
                
                nkp = numel(dataGT(s).SS(strG).KPI);
                numKP(idx, m) = nkp;
                % keypoint distances
                kpdist{idx, m} = ...
                    keypointDistances(V{s}, F{s}, dataGT(s).SS(strG), userStrokeData);
                
                % extrinsic and intrinsic (geodesic) curvature
                [gk, k, ~] = geodesicCurvature(V{s}, F{s}, userStrokeData, algorithm);
%                 P = [vertcat(cell2mat(path).x), vertcat(cell2mat(path).y) vertcat(cell2mat(path).z)];
%                 edge = diff(P, [], 1) * scale;
%                 eLen = vecnorm(edge, 2, 2);
%                 L = sum(eLen);
                kmean(idx, m) = sum(k)/L;
                gkmean(idx, m) = sum(abs(gk))/L;
                gfair(idx, m) = sum(abs(diff(gk)))/L;
                
                pts = getPoints(V{s}, F{s}, userStrokeData);
                pts = util.interparc(0:.01:1, pts, 'spline');
                
                distMean(idx, m) = scale * sum(vecnorm(pts - ptsG, 2, 2)) / size(pts, 1);
                
                distA = pdist2(pts, ptsG, 'euclidean', 'Smallest', 1);
                distB = pdist2(ptsG, pts, 'euclidean', 'Smallest', 1);
                
                distMeanHauss(idx, m) = scale * (mean(distA) + mean(distB))/2;
                
%                 distMeanTrace(idx, m) = scale * ...
%                     mean(pdist2(pts, ptsGtrace, 'euclidean', 'Smallest', 1));
%                 distMeanFree(idx, m) = scale * ...
%                     mean(pdist2(pts, ptsGfree, 'euclidean', 'Smallest', 1));
                
                rawData{idx, m} = struct('k', k, 'gk', gk);
                
                [ht, hr, pt, pr] = computeEffortMeasures(userStrokeData);
                effortHeadTranslate(idx, m) = ht/L;
                effortHeadRotate(idx, m) = hr/L;
                effortPenTranslate(idx, m) = pt/L;
                effortPenRotate(idx, m) = pr/L;
            end
            
        end
        
        toc;
        
    end
    
    result = struct(...
        'kmean', kmean,...
        'gkmean', gkmean, ...
        'gfair', gfair, ...
        'numKP', numKP, ...
        'prepTime', prepTime, ...
        'execTime', execTime, ...
        'numPieces', numPieces, ...
        'distMean', distMean, ...
        'distMeanHauss', distMeanHauss, ...
        'effortHeadTranslate', effortHeadTranslate, ...
        'effortHeadRotate', effortHeadRotate, ...
        'effortPenTranslate', effortPenTranslate, ...
        'effortPenRotate', effortPenRotate, ...
        'shapeId', shapeId, ...
        'strokeId', strokeId);
end
