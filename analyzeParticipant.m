function result = analyzeParticipant(V, F, data, dataGT, sequence)
    global geodesic_library;
    geodesic_library = 'geodesic_release';

    % Analyze the data for a participant.
    % V, F, dataGT : see init.m
    % data, sequence : load from files using loadParticipantData
    % result : struct with a field each for the measures reported in the
    % paper. Each field is an 72*2 array. For a field, say "f", f{j, i} is
    % that measure when using the ith projection technique for the jth
    % stroke in the study sequence, that is, the sequence as seen by the
    % participant. The actual shapeID and strokeID are added as fields of
    % results to allow for parsing the data in terms of those IDs.
    % See the end of the function for the names and short descriptions of
    % all the fields.
    
    [numMethod, numShape] = size(data);
    numStroke = numel(data{1, 1});
    
    
    assert(numel(V) >= numShape);
    assert(numel(F) >= numShape);
    
    kmean = zeros(numShape*(numStroke + 2), numMethod);
    gkmean = kmean;
    gfair = kmean;
    execTime = kmean;
    numPieces = kmean;
    distMeanEP = kmean;
    distMeanSym = kmean;
    effortHeadTranslate = kmean;
    effortHeadRotate = kmean;
    effortPenTranslate = kmean;
    effortPenRotate = kmean;

    numKP = kmean;
    curveID = zeros(numShape*(numStroke + 2), 1);
    shapeID = zeros(numShape*(numStroke + 2), 1);
    
    
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
                strG = sequence.StrokeSequence(1+numStroke/2);
            else
                strG = sequence.StrokeSequence(2+numStroke);
            end
            
            shapeID(idx) = s;
            curveID(idx) = strG;
                
            ptsG = getPoints(V{s}, F{s}, dataGT(s).SS(strG));
            ptsG = interparc(0:.01:1, ptsG, 'spline');
            edge = diff(ptsG, [], 1) * scale;
            eLen = vecnorm(edge, 2, 2);
            L = sum(eLen);
            
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
                
                % execution time
                startTime = userStrokeData(1).F(1).DF.T;
                execTime(idx, m) = userStrokeData(end).F(end).DF.T - startTime;
                
                % number of pieces
                numPieces(idx, m) = numel(userStrokeData);
                
                nkp = numel(dataGT(s).SS(strG).KPI);
                numKP(idx, m) = nkp;
                
                % extrinsic and intrinsic (geodesic) curvature
                [gk, k, ~] = geodesicCurvature(V{s}, F{s}, userStrokeData, algorithm);
                kmean(idx, m) = sum(k)/L;
                gkmean(idx, m) = sum(abs(gk))/L;
                gfair(idx, m) = sum(abs(diff(gk)))/L;
                
                pts = getPoints(V{s}, F{s}, userStrokeData);
                pts = interparc(0:.01:1, pts, 'spline');
                
                distMeanEP(idx, m) = scale * sum(vecnorm(pts - ptsG, 2, 2)) / size(pts, 1);
                
                distA = pdist2(pts, ptsG, 'euclidean', 'Smallest', 1);
                distB = pdist2(ptsG, pts, 'euclidean', 'Smallest', 1);
                
                distMeanSym(idx, m) = scale * (mean(distA) + mean(distB))/2;
                
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
        'kmean', kmean,...                              % Euclidean curvature
        'gkmean', gkmean, ...                           % geodesic curvature
        'gfair', gfair, ...                             % geodesic fairness
        'numKP', numKP, ...                             % number of keypoints
        'execTime', execTime, ...                       % execution time
        'numPieces', numPieces, ...                     % no. of pieces
        'distMeanEP', distMeanEP, ...                   % equi-parameter distance
        'distMeanSym', distMeanSym, ...                 % symmetric distance
        'effortHeadTranslate', effortHeadTranslate, ... % head translation
        'effortHeadRotate', effortHeadRotate, ...       % head rotation
        'effortPenTranslate', effortPenTranslate, ...   % pen/controller translation
        'effortPenRotate', effortPenRotate, ...         % pen/controller rotation
        'shapeID', shapeID, ...                         % shape (model) ID
        'curveID', curveID);                            % target curve ID
end
