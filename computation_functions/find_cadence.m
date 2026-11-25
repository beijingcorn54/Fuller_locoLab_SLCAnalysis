% Produces cadences from all trials of a specified person/incline/speed
% Cadences of both legs

function [left_cadences, right_cadences] = find_cadence(data)
    % Establish variables
    stride_details = data.events.StrideDetails;

    % Extract stride times from stride details
    stride_times = [];
    for i = 1 : size(stride_details, 1)
        % 100Hz = 0.01 sec
        stride_times = [stride_times, stride_details(i, 3) * 0.01];
    end

    % Cadence = Steps Per Minute
    cadences = 60 ./ stride_times;

    % Separate into left leg and right leg cadences
    left_right_vector = data.events.StrideDetails(:, 4);
    i_left_end = 2 * length(left_right_vector) - sum(left_right_vector);

    left_cadences = cadences(1 : i_left_end);
    right_cadences = cadences(i_left_end + 1 : end);
end