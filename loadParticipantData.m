function [data, sequence] = loadParticipantData(folder)
    % Load the study data and the sequence information for a single
    % participant. Typical usage:
    % [data, sequence] = loadParticipantData(['./studydata/p1']);
    % data is a 2D cell array, with the (i,j)th cell containing data for
    % the ith projection technique and the jth model.
    % Each data{i, j} is in turn a 1D cell array, with data{i}{j}{k}
    % storing the data for the kth target curve.
    % Each data{i, j}{k} is an array of structs, and each element
    % contains data for a continuous projected curve drawn by the user.
    % Note that there can be multiple projected curves for each target
    % curve since the projected curve may be broken into pieces when using
    % the Spraycan projection.
    % For repeated curves, the data is stored at data{i, j}{k}(1).Repeat
    %
    % The struct for each continuous projected curve contains the following
    % pieces of information:
    % P (projected points): n*1 struct array. Each point is a
    % "3D vector struct": ('x', double, 'y', double, 'z', double).
    % F (frames): n*1 struct array. The "frame" struct is explained below.
    % M (method): string, either 'Spray' (spraycan) or 'AnchorPhong'
    % (mimicry)
    % ModelMatrix: 1*1 struct array. The only field in the struct is
    % 'data', a 16*1 array. This is the transformation matrix of the target
    % model when this curve was drawn, stored in col-major format.
    % Index: The position of this stroke in the sequence exposed to the user.
    % TaskType: Either 'Trace' or 'Recreate'
    %
    % The "frame" struct has the following fields:
    % PT (projected point): a "3D vector struct" as defined above.
    % N (mesh normal at projected point): 3D vector struct
    % TI (triangle index at projected point): integer
    % B (barycentric coordinate at projected point): 3D vector struct
    % D (distance b/w 3D point and projection): double
    % DF (system state when this point was projection): a struct with the
    % following fields:
    %
    % T (timestamp, ms since study started): integer
    % HP (head position) : 3D vector struct
    % PP (pen position) : 3D vector struct
    % HU (head up vector) : 3D vector struct
    % HF (head fwd vector) : 3D vector struct
    % CU (controller up vector) : 3D vector struct
    % CF (controller fwd vector) : 3D vector struct
    % SD (spraypaint raycast direction) : 3D vector struct
    
    numMethod = 2;
    numShape = 6;
    numStroke = 10;
    
    data = cell(numMethod, numShape);
    
    sequence = jsondecode(fileread(fullfile(folder, 'study_sequence.json')));
    
    % Convert from 0-indexed to 1-indexed data
    sequence.MethodSequence = sequence.MethodSequence + 1;
    sequence.ShapeSequence = sequence.ShapeSequence + 1;
    sequence.StrokeSequence = sequence.StrokeSequence + 1;
    
    mseq = sequence.MethodSequence;
    sseq = sequence.ShapeSequence;
    stseq = sequence.StrokeSequence;
    
    % The 6th and 12th strokes are repeated
    rep1 = numStroke/2+1;
    rep2 = numStroke+2;
            
    for m = 1:numMethod
        for s = 1:numShape
            % Load a file and parse the JSON
            file = fullfile(folder, [num2str(m-1) '_' num2str(s-1) '.json']);
            tempData = jsondecode(fileread(file));
            if ~iscell(tempData)
                tempData = num2cell(tempData);
            end
            data{mseq(m), sseq(s)} = cell(numStroke, 1);
            
            
            % Parse data for all the original (not repeated) strokes
            for str=1:numStroke/2
                idx = find(stseq==str, 1);
                data{mseq(m), sseq(s)}{str} = tempData{idx};
                for i=1:numel(data{mseq(m), sseq(s)}{str})
                    data{mseq(m), sseq(s)}{str}(i).Index = idx;
                    % First five strokes in the sequence were utilized for
                    % Tracing task, and the last five for Re-creating task.
                    if idx <= numStroke/2
                        data{mseq(m), sseq(s)}{str}(i).TaskType = 'Trace';
                    else
                        data{mseq(m), sseq(s)}{str}(i).TaskType = 'Recreate';
                    end
                    data{mseq(m), sseq(s)}{str}(i).Repeat = struct();
                end
            end
            
            for str=numStroke/2 + (1:numStroke/2)
                idx = find(stseq==str, 1);
                data{mseq(m), sseq(s)}{str} = tempData{idx};
                for i=1:numel(data{mseq(m), sseq(s)}{str})
                    data{mseq(m), sseq(s)}{str}(i).Index = idx;
                    if idx <= numStroke/2
                        data{mseq(m), sseq(s)}{str}(i).TaskType = 'Trace';
                    else
                        data{mseq(m), sseq(s)}{str}(i).TaskType = 'Recreate';
                    end
                    data{mseq(m), sseq(s)}{str}(i).Repeat = struct();
                end
            end
            

            data{mseq(m), sseq(s)}{stseq(1)}(1).Repeat = tempData{rep1};
            for i=1:numel(data{mseq(m), sseq(s)}{stseq(1)}(1).Repeat)
                data{mseq(m), sseq(s)}{stseq(1)}(1).Repeat(i).Index = rep1;
                data{mseq(m), sseq(s)}{stseq(1)}(1).Repeat(i).TaskType = 'Trace';
            end
            data{mseq(m), sseq(s)}{stseq(2 + numStroke/2)}(1).Repeat = tempData{rep2};
            for i=1:numel(data{mseq(m), sseq(s)}{stseq(2 + numStroke/2)}(1).Repeat)
                data{mseq(m), sseq(s)}{stseq(2 + numStroke/2)}(1).Repeat(i).Index = rep2;
                data{mseq(m), sseq(s)}{stseq(2 + numStroke/2)}(1).Repeat(i).TaskType = 'Memory';
            end
        end
    end
end
