function quality = computeDataQualityMeasures(V, F, data, dataGT, seq)
    numMethod = size(data, 1);
    numShape = size(data, 2);
    numStroke = numel(data{1, 1});
    
    toMat = @(S) [vertcat(S.x), vertcat(S.y), vertcat(S.z)];
    
    % these quality measures are TRUE is the stroke shows BAD quality for
    % that particular measure of quality
    
    % stroke too short: len < target_length / 2
    short = false(numShape*(numStroke+2), numMethod);
    % tangent noise: avg. dot product b/w consecute tangents in 3D is < 0.9
    tangentNoise = short;
    % stroke is likely inverted: list of indices of stroke points closest
    % to the ordered sequence of has over n*(n-1)/2 inversions
    inverted = short;
    % 3D tracking shows jumps: dist b/w ANY pair of consecutive pts > 5cm
    jumpy = short;
    
    
    for s=1:numShape
        mat = reshape(data{1, s}{1}(1).ModelMatrix.data, 4, 4);
        scale = power(det(mat(1:3, 1:3)), 1/3);
        
        for str=1:numStroke+2
            idx = (s-1)*(numStroke+2) + str;
            
            if str <= numStroke
                strG = str;
            elseif str == numStroke+1
                strG = seq.StrokeSequence(1+numStroke/2);
            else
                strG = seq.StrokeSequence(2+numStroke);
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
                T = edge ./ eLen3d;
                
                jumpy(idx, m) = any(eLen3d > 0.05);
                
                tangentNoise(idx, m) = ...
                    mean(dot(T(1:end-1, :), T(2:end, :), 2)) < 0.9;
                
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
    
    
    % badStroke = short | tangentNoise | inverted | jumpy;
	badStroke = short | inverted | jumpy;
    badPair = badStroke(:, 1) | badStroke(:, 2);
    
    quality = struct(...
        'short', short, ...
        'tangentNoise', tangentNoise, ...
        'inverted', inverted, ...
        'jumpy', jumpy, ....
        'badStroke', badStroke, ...
        'badPair', badPair);
end
