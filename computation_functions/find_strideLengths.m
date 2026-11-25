% v_treadmill expects a negative number
% stride lengths of both legs
function [left_SL, right_SL, left_normSL, right_normSL] = find_strideLengths(data, v_treadmill, incline, participant_details)
    y = correct_strides(data, v_treadmill);
    stride_lengths = zeros(1, size(y, 2));

    % Make calculations
    for i = 1 : size(y, 2)
        stride_lengths(i) = abs(y(150, i) - y(1, i));
    end

    % Account for incline
    stride_lengths = stride_lengths ./ cos(incline * pi /180);

    % Separate into left leg and right leg stride lengths
    left_right_vector = data.events.StrideDetails(:, 4);
    i_left_end = 2 * length(left_right_vector) - sum(left_right_vector);

    left_SL = stride_lengths(1 : i_left_end);
    right_SL = stride_lengths(i_left_end + 1 : end);

    % Produce normalized stride lengths
    left_length = participant_details{6, 2};
    right_length = participant_details{9, 2};

    left_normSL = left_SL / left_length;
    right_normSL = right_SL / right_length;
end