function [ht, hr, pt, pr] = computeEffortMeasures(data)
    
    % Compute effort measures for a single user-drawn stroke.
    % The time taken measure is simpler to compute and is calculated
    % directly in analyzeParticipant().
    % Output variables are head translation and rotation, and pen
    % translation and rotation, respectively.
    
    if ~isfield(data(1), 'ModelMatrix')
        warning('ModelMatrix not found. Stroke may be empty!');
        ht = 0;
        hr = 0;
        pt = 0;
        pr = 0;
        return
    end
    
    mat = reshape(data(1).ModelMatrix.data, 4, 4)';
%     T = [zeros(3, 4); mat(4, :)];
    RS = mat(1:3, 1:3);
    scale = power(det(mat), 1/3);
    R = RS / scale;
    
    DF = vertcat(vertcat(data.F).DF);
    
    t = vertcat(DF.T)/1000;
      
    repPts = diff(t)==0;
    t(repPts) = [];
    
    n = numel(t);
    
    structToMatrix = @(S) [vertcat(S.x), vertcat(S.y), vertcat(S.z)];
    
    % head position and frame (given by up and forward vectors)
    HP = structToMatrix(vertcat(DF.HP));
    HU = structToMatrix(vertcat(DF.HU));
    HF = structToMatrix(vertcat(DF.HF));
    
    HP(repPts, :) = [];
    HU(repPts, :) = [];
    HF(repPts, :) = [];
    
    
    % same for controller (pen)
    PP = structToMatrix(vertcat(DF.PP));
    PU = structToMatrix(vertcat(DF.CU));
    PF = structToMatrix(vertcat(DF.CF));
    
    PP(repPts, :) = [];
    PF(repPts, :) = [];
    PU(repPts, :) = [];
    
    
    oneVec = ones(n, 1);
    
    % convert to world space
    HP = [HP oneVec] * mat;
    PP = [PP oneVec] * mat;
    HP = HP(:, 1:3);
    PP = PP(:, 1:3);
    
    HU = HU * R;
    HF = HF * R;
    PU = PU * R;
    PF = PF * R;
    
    
    
%     disp(max(vecnorm(HQ, 2, 2)));
%     disp(max(vecnorm(PQ, 2, 2)));
    
    %% Now the main task: Smooth things out and integrate
    
    % Smoothing is easy for translations
    HP = smoothdata(HP, 1, 'Gaussian', .1, 'SamplePoints', t);
    PP = smoothdata(PP, 1, 'Gaussian', .1, 'SamplePoints', t);
    ht = sum(vecnorm(diff(HP, [], 1), 2, 2));
    pt = sum(vecnorm(diff(PP, [], 1), 2, 2));
    
%     % Rotations are more involved. Smooth using 
%     % https://dx.doi.org/10.1007/s11263-012-0601-0 Algorithm 1.
%     smoothWindowSize = 4;
%     [HF, HU] = avgrotations(HF, HU, smoothWindowSize);
%     [PF, PU] = avgrotations(PF, PU, smoothWindowSize);

    % Try simply smoothing the directions and re-orthogonalizing
    HF = smoothdata(HF, 1, 'Gaussian', .1, 'SamplePoints', t);
    HU = smoothdata(HU, 1, 'Gaussian', .1, 'SamplePoints', t);
    PF = smoothdata(PF, 1, 'Gaussian', .1, 'SamplePoints', t);
    PU = smoothdata(PU, 1, 'Gaussian', .1, 'SamplePoints', t);
    % Get back to unit normals
    HF = HF ./ vecnorm(HF, 2, 2);
    HU = HU ./ vecnorm(HU, 2, 2);
    PF = PF ./ vecnorm(PF, 2, 2);
    PU = PU ./ vecnorm(PU, 2, 2);
    % compute orthogonal direction
    HX = cross(HU, HF, 2);
    PX = cross(PU, PF, 2);
    % recompute the forward direction for re-orthogonalization
    HF = cross(HX, HU, 2);
    PF = cross(PX, PU, 2);
    
    % convert frames to quaternions
    HQ = framevec2quat(HF, HU);
    PQ = framevec2quat(PF, PU);
    
    % Effort is just the sum over rotation angles between consecutive 
    % points. That is, integrate out the distance covered in SO(3), using 
    % the natural metric.
    hr = sum(acos(abs(dot(HQ(1:end-1, :), HQ(2:end, :), 2))));
    pr = sum(acos(abs(dot(PQ(1:end-1, :), PQ(2:end, :), 2))));
end

function q = framevec2quat(F, U)
% Note that the returned quaternions are in [w x y z] format
    n = size(F, 1);
    % construct left vector (X)
    X = cross(F, U, 2);
    
    % Now the ith rotation matrix is [X_i', U_i', F_i'], where V_i gives
    % the ith row of a matrix, and ' is the transpose operation
    
    R00 = X(:, 1);
    R01 = U(:, 1);
    R02 = F(:, 1);
    R10 = X(:, 2);
    R11 = U(:, 2);
    R12 = F(:, 2);
    R20 = X(:, 3);
    R21 = U(:, 3);
    R22 = F(:, 3);
    
    tr = R00 + R11 + R22;
    
    % Condition #1 : trace is positive
    cond1 = tr > 0;
    
    % Condition #2 : R00 > R11 & R11 > R22
    cond2 = R00 > R11 & R11 > R22;
    
    % Condition #3 : R11 > R22
    cond3 = R11 > R22;
    
    
    cond4 = ~cond1 & ~cond2 & ~cond3;
    cond3 = ~cond1 & ~cond2 & cond3;
    cond2 = ~cond1 & cond2;
    
    
    q = zeros(n, 4);
    
    q(cond1, 1) = sqrt(1 + R00(cond1) + R11(cond1) + R22(cond1)) * 2.0;
    q(cond1, 2) = (R21(cond1) - R12(cond1)) ./ q(cond1, 1);
    q(cond1, 3) = (R02(cond1) - R20(cond1)) ./ q(cond1, 1);
    q(cond1, 4) = (R10(cond1) - R01(cond1)) ./ q(cond1, 1);
    q(cond1, 1) = q(cond1, 1)/4;
    
    q(cond2, 2) = sqrt(1 + R00(cond2) - R11(cond2) - R22(cond2)) * 2.0;
    q(cond2, 1) = (R21(cond2) - R12(cond2)) ./ q(cond2, 2);
    q(cond2, 3) = (R01(cond2) + R10(cond2)) ./ q(cond2, 2);
    q(cond2, 4) = (R02(cond2) - R20(cond2)) ./ q(cond2, 2);
    q(cond2, 2) = q(cond2, 2) / 4;
    
    q(cond3, 3) = sqrt(1 + R11(cond3) - R00(cond3) - R22(cond3)) * 2.0;
    q(cond3, 1) = (R02(cond3) - R20(cond3)) ./ q(cond3, 3);
    q(cond3, 2) = (R01(cond3) + R10(cond3)) ./ q(cond3, 3);
    q(cond3, 4) = (R12(cond3) + R21(cond3)) ./ q(cond3, 3);
    q(cond3, 3) = q(cond3, 3) / 4;
    
    q(cond4, 4) = sqrt(1 + R22(cond4) - R00(cond4) - R11(cond4)) * 2.0;
    q(cond4, 1) = (R10(cond4) - R01(cond4)) ./ q(cond4, 4);
    q(cond4, 2) = (R02(cond4) + R20(cond4)) ./ q(cond4, 4);
    q(cond4, 3) = (R12(cond4) + R21(cond4)) ./ q(cond4, 4);
    q(cond4, 4) = q(cond4, 4) / 4;
    
    q = q ./ vecnorm(q, 2, 2);
end

function [F, U] = avgrotations(F, U, window)
    X = cross(U, F, 2);
    n = size(F, 1);
    R = zeros(3, 3, n);
    
    R(:, 1, :) = X';
    R(:, 2, :) = U';
    R(:, 3, :) = F';
    
    epsilon = 1e-2;
    
    R_mean = R;
    
    for i=1:n
        Ri_mean = R(:, :, i);
        r = eye(3);
        while norm(r, 'Fro') > epsilon
            % Compute r = 1/n Σ_i logm(Ri'Ri)
            jmin = max(1, i-window);
            jmax = min(n, i+window);
            num = jmax - jmin + 1;
            r = zeros(3);
            for j=jmin:jmax
                r = r + logm(Ri_mean' * R(:, :, j));
            end
            r = r / num;
            
            Ri_mean = Ri_mean * expm(r);
        end
        R_mean(:, :, i) = Ri_mean;
    end
    
    F = permute(R_mean(:, 3, :), [3 1 2]);
    U = permute(R_mean(:, 2, :), [3 1 2]);
end
