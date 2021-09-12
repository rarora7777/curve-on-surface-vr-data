function [gk, k, path] = geodesicCurvature(V, F, data, algorithm)
% Computes the geodesic curvature `gk` of the stroke. Also computes the
% Euclidean curvature `k` and the geodesic curve `path`. The geodesic curve
% simply takes the implicit points in `data` and connects consecutive pts
% with shortest paths on the mesh (`V`, `F`). If `algorithm` is provided,
% the geodesic library is not re-initialized. It is then the caller's
% responsibility to ensure that geodesic_library was initialized
% for the input mesh. Otherwise, it is constructed here, and the exact
% geodesic algorithm is used for shortest path queries.

    global geodesic_library;
        
    if nargin < 4
        geodesic_library = 'geodesic_release';
        mesh = geodesic_new_mesh(V, F);
        algorithm = geodesic_new_algorithm(mesh, 'exact');
    end
    
    E = edges(F);
    Edir = normalizerow(V(E(:, 2), :) - V(E(:, 1), :));
    
    LENGTH_THRESHOLD = 1e-3;
    
    if isfield(data, 'F')
        fIdx = vertcat(data.F);
        fIdx = vertcat(fIdx.TI);

        bary = vertcat(data.F);
        bary = vertcat(bary.B);
        bary = [vertcat(bary.x), vertcat(bary.y), vertcat(bary.z)];
        
        pts = getPoints(V, F, data);
        n = size(pts, 1);
        len = cumsum(vecnorm(diff(pts, [], 1), 2, 2));
        mat = len - len';
        useful = false(n, 1);
        useful(1) = true;
        i=1;
        while 1
            i = find(mat(:, i) > LENGTH_THRESHOLD, 1);
            if isempty(i)
                break;
            else
                useful(i) = true;
            end
        end
        fIdx = fIdx(useful);
        bary = bary(useful, :);
        fprintf('Size unfiltered %d, filtered %d\n', n, numel(fIdx));
    else
        fIdx = data.FI;
        bary = data.B;
    end
    
    bary(bary<0) = 0;
    bary = bary ./ sum(bary, 2);
%     
%     fIdx = fIdx(1:50);
%     bary = bary(1:50, :);
    
    path = cell(0, 0);
    
    n = numel(fIdx);
    
    for i = n:-1:2
        if fIdx(i) ~= fIdx(i-1)
            fv = [V(F(fIdx(i), 1), :); V(F(fIdx(i), 2), :); V(F(fIdx(i), 3), :)];
            [type, id] = getPointTypeAndId(E, F, fIdx(i), bary(i, :));
            source_points = {geodesic_create_surface_point(type, id, bary(i, :) * fv)};

            fv = [V(F(fIdx(i-1), 1), :); V(F(fIdx(i-1), 2), :); V(F(fIdx(i-1), 3), :)];
            [type, id] = getPointTypeAndId(E, F, fIdx(i-1), bary(i-1, :));
            destination = geodesic_create_surface_point(type, id, bary(i-1, :) * fv);

            geodesic_propagate(algorithm, source_points);
            segment = geodesic_trace_back(algorithm, destination, true);
            path = [segment(2:end); path(:)];
        else
            fv = [V(F(fIdx(i), 1), :); V(F(fIdx(i), 2), :); V(F(fIdx(i), 3), :)];
            src = bary(i, :) * fv;
            [type, id] = getPointTypeAndId(E, F, fIdx(i), bary(i, :));
            pt = struct(...
                'x', src(1), ...
                'y', src(2), ...
                'z', src(3), ...
                'type', type, ...
                'id', id, ...
                'b0', bary(i, 1), ...
                'b1', bary(i, 2));
            path = [{pt}; path(:)];
        end
    end
    
    fv = [V(F(fIdx(1), 1), :); V(F(fIdx(1), 2), :); V(F(fIdx(1), 3), :)];
    [type, id] = getPointTypeAndId(E, F, fIdx(1), bary(1, :));
    destination = geodesic_create_surface_point(type, id, bary(1, :) * fv);
    firstPt = struct(...
        'x', destination.x, ...
        'y', destination.y, ...
        'z', destination.z, ...
        'type', destination.type, ...
        'id', destination.id, ...
        'b0', bary(1, 1), ...
        'b1', bary(1, 2));
    path = [{firstPt}; path];
    
    
    % can this be vectorized?
    for i=1:numel(path)
        if strcmpi(path{i}.type, 'vertex')
            path{i}.type = 0;
        elseif strcmpi(path{i}.type, 'edge')
            path{i}.type = 1;
        else
            path{i}.type = 2;
        end
    end
    
    P = [vertcat(cell2mat(path).x), vertcat(cell2mat(path).y) vertcat(cell2mat(path).z)];
%     b0 = vertcat(cell2mat(path).b0);
%     b1 = vertcat(cell2mat(path).b1);
    type = vertcat(cell2mat(path).type);
    sid = vertcat(cell2mat(path).id);
    
    
    edge = diff(P, [], 1);
    eLen = vecnorm(edge, 2, 2);
    T = edge ./ eLen;
    
    k = [0; acos(clamp(dot(T(1:end-1, :), T(2:end, :), 2), -1, 1)); 0];
%     k([eLen; 0] < 1e-7) = 0;
%     k([0; eLen] < 1e-7) = 0;
    
%     T(eLen < 1e-7, :) = 0;

    
    
    nP = size(P, 1);
    gk = k;
    
    % Only compute adjacency stuff if we need to compute the geodesic
    % curvature at a mesh vertex
    if sum(type==0) > 0
%         vv = adjacency_matrix(F);
        vf = vertex_triangle_adjacency(F);
        ef = edge_triangle_adjacency(F, E);
    end
    
    % can this be vectorized?
    for i=2:nP-1
        switch type(i)
            case 0  % vertex
                if eLen(i) < 1e-7 || eLen(i-1) < 1e-7
                    gk(i) = 0;
                else
                    gk(i) = geodesicCurvatureAtVertex(...
                        E, Edir, vf, ef, T, type, sid, i);
                end
                
            case 1  % edge requires some computation
                theta0 = acos(clamp(dot(T(i-1, :), Edir(sid(i), :), 2), -1, 1));
                theta1 = acos(clamp(dot(T(i, :), Edir(sid(i), :), 2), -1, 1));
                gk(i) = theta1 - theta0;

            case 2  % face is easy
                fv = [V(F(sid(i), 1), :); V(F(sid(i), 2), :); V(F(sid(i), 3), :)];
                Rx = (fv(2, :) - fv(1, :));
                Rx = Rx / norm(Rx);
                Rz = cross(Rx, fv(3, :) - fv(1, :));
                Rz = Rz / norm(Rz);
                R = [Rx; cross(Rz, Rx); Rz];
                
                T0 = T(i-1, :) / R;
                T1 = T(i, :) / R;
                gk(i) = atan2(T0(1)*T1(2) - T0(2)*T1(1), T0(1)*T1(1) + T0(2)*T1(2));

                if abs(gk(i)) > k(i) + 1e-6
                    disp('WTF');
                end
            otherwise
                disp('wtf');
        end
    end
end

function gkv = geodesicCurvatureAtVertex(E, Edir, vf, ef, T, type, sid, idx)
    T0 = T(idx-1, :);
    T1 = T(idx, :);
%     ptPrev = P(idx-1, :);
    u = sid(idx);
    
    % convert older edges or vertices to triangles
    if type(idx-1) == 1
        temp = ef(sid(idx-1), :);
        if ismember(temp(1), find(vf(:, u)))
            f0 = temp(1);
        else
            f0 = temp(2);
        end
    elseif type(idx-1) == 2
        f0 = sid(idx-1);
    else
        temp = find((E(:, 1)==u & E(:, 2)==sid(idx-1)) | (E(:, 2)==u & E(:, 1)==sid(idx-1)), 1);
        f0 = ef(temp, 1);
    end
    
    if type(idx+1) == 1
        temp = ef(sid(idx+1), :);
        if ismember(temp(1), find(vf(:, u)))
            f1 = temp(1);
        else
            f1 = temp(2);
        end
    elseif type(idx+1) == 2
        f1 = sid(idx+1);
    else
        temp = find((E(:, 1)==u & E(:, 2)==sid(idx+1)) | (E(:, 2)==u & E(:, 1)==sid(idx+1)), 1);
        f1 = ef(temp, 1);
    end
    
%     ringFaces = find(vf(u, :));
%     ring = ringFaces;
%     ring(1) = f0;
%     curFace = -1;
    fEdges = find(ef(:, 1)==f0 | ef(:, 2)==f0);
    assert(numel(fEdges)==3)    % should find 3 edges incidet on the face
    uEdges = fEdges(E(fEdges, 1)==u | E(fEdges, 2)==u);
    assert(numel(uEdges)==2)    % should find 2 edges incident on the vertex
    leftEdge = uEdges(1);
    rightEdge = uEdges(2);
    curFace = f0;
    theta = 0;
    
    if f0==f1
        phi = acos(clamp(dot(-T0, T1, 2), -1, 1));
        phiComputed = true;
    else
        if E(rightEdge, 1)==u
            rightEdgeDir =  Edir(rightEdge, :);
        else
            rightEdgeDir = -Edir(rightEdge, :);
        end
        
        phi = acos(clamp(dot(-T0, rightEdgeDir, 2), -1, 1));
        phiComputed = false;
    end
    
    while 1
        if E(leftEdge, 1)==u
            leftEdgeDir =  Edir(leftEdge, :);
        else
            leftEdgeDir = -Edir(leftEdge, :);
        end
        
        if E(rightEdge, 1)==u
            rightEdgeDir =  Edir(rightEdge, :);
        else
            rightEdgeDir = -Edir(rightEdge, :);
        end
        
        faceAngle = acos(clamp(dot(leftEdgeDir, rightEdgeDir, 2), -1, 1));
        theta = theta + faceAngle;
        if ~phiComputed
            if curFace~=f0 && curFace~=f1
               phi = phi + faceAngle;
            elseif curFace~=f0   % curFace is f1
               phi = phi + acos(clamp(dot(leftEdgeDir, T1, 2), -1, 1));
               phiComputed = true;
            end
        end
        
        rightEdgeFaces = ef(rightEdge, :);
        if rightEdgeFaces(1)==curFace
            curFace = rightEdgeFaces(2);
        else
            assert(rightEdgeFaces(2)==curFace);
            curFace = rightEdgeFaces(1);
        end
        
        if curFace == f0
            break;
        end
        leftEdge = rightEdge;
        fEdges = find(ef(:, 1)==curFace | ef(:, 2)==curFace);
        assert(numel(fEdges)==3)    % should find 3 edges incidet on the face
        uEdges = fEdges(E(fEdges, 1)==u | E(fEdges, 2)==u);
        assert(numel(uEdges)==2)    % should find 2 edges incident on the vertex
        rightEdge = uEdges(uEdges~=leftEdge);
        assert(numel(rightEdge)==1) % exactly one of those should be left edge
    end
    
    assert(phiComputed == true);
    
    gkv = phi - theta/2;
end

function [type, id] = getPointTypeAndId(E, F, f, bary)
    [bary, order] = sort(bary);
    if bary(2) < 1e-7                           % vertex
        type = 'vertex';
        id = F(f, order(3));
    elseif bary(1) < 1e-7                       % edge
        type = 'edge';
        id = find(...
            (E(:, 1)==F(f, order(2)) & E(:, 2)==F(f, order(3))) |...
            (E(:, 2)==F(f, order(2)) & E(:, 1)==F(f, order(3))), 1);
    else
        type = 'face';
        id = f;
    end
end
