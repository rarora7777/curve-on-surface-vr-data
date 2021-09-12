function quality = computeDataQualityMeasures(V, F, data, dataGT, sequence)
    % Compute data quality measures to remove meaningless user strokes.
    % This function's API works exactly like analyzeParticipant(). Please
    % see the documentation for that function.
    
    numMethod = size(data, 1);
    numShape = size(data, 2);
    numStroke = numel(data{1, 1});
    
    toMat = @(S) [vertcat(S.x), vertcat(S.y), vertcat(S.z)];
    
    % these quality measures are TRUE is the stroke shows BAD quality for
    % that particular measure of quality
    
    % stroke too short: len < target_length / 2
    short = false(numShape*(numStroke+2), numMethod);
    % stroke is likely inverted: list of indices of stroke points closest
    % to the ordered sequence of has over n*(n-1)/2 inversions
    inverted = short;
    % 3D tracking shows jumps: dist b/w ANY pair of consecutive pts > 5cm
    noisy = short;
    
    
    for s=1:numShape
        mat = reshape(data{1, s}{1}(1).ModelMatrix.data, 4, 4);
        scale = power(det(mat(1:3, 1:3)), 1/3);
        
        for str=1:numStroke+2
            idx = (s-1)*(numStroke+2) + str;
            
            if str <= numStroke
                strG = str;
            elseif str == numStroke+1
                strG = sequence.StrokeSequence(1+numStroke/2);
            else
                strG = sequence.StrokeSequence(2+numStroke);
            end

            ptsG = getPoints(V{s}, F{s}, dataGT(s).SS(strG));
            KP = getPoints(V{s}, F{s}, dataGT(s).SS(strG), true);
            
            lenG = sum(vecnorm(diff(ptsG, [], 1), 2, 2));
            
            for m=1:numMethod
                
                if str <= numStroke
                    d = data{m, s}{strG};
                else
                    d = data{m, s}{strG}.Repeat;
                end
                
                if ~isfield(d, 'F')
                    short(idx, m) = true;
                    continue;
                end
                
                frames = vertcat(d.F);
                DF = vertcat(frames.DF);
                PP = toMat(vertcat(DF.PP)) * scale;
                edge = diff(PP, [], 1);
                eLen3d = vecnorm(edge, 2, 2);
                
                noisy(idx, m) = any(eLen3d > 0.05);
                
                
                pts = getPoints(V{s}, F{s}, d);
                eLen = vecnorm(diff(pts, [], 1), 2, 2);
                
                short(idx, m) = sum(eLen) < 0.5*lenG;
                
                if isempty(pts)
                    inverted(idx, m) = false;
                else
                    [~, pIdx] = pdist2(pts, KP, 'squaredeuclidean', 'Smallest', 1);
                    signMat = sign(triu(pIdx - pIdx'));
                    n = size(KP, 1);
                    inverted(idx, m) = sum(signMat, 'all') < n * (n+1) / 4;
                end
            end
        end
    end
    
    
    % A stroke is bad (to be ignored) if either of the three quality
    % measures is bad.
    badStroke = short | inverted | noisy;
    
    % A stroke pair is considered bad if either of the two strokes is bad,
    % so that this pair is not taken into account when comparing mimicry
    % against spraycan.
    badPair = badStroke(:, 1) | badStroke(:, 2);
    
    quality = struct(...
        'short', short, ...
        'inverted', inverted, ...
        'noisy', noisy, ....
        'badStroke', badStroke, ...
        'badPair', badPair);    % badPair is 72*1, unlike the rest which are 72*2
end
