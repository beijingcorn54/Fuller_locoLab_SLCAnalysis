% Produces HS/TO indecies from all trials of a specified person/incline/speed 
function [left_HS, right_HS, left_TO, right_TO] = find_HS_TO(data, force_threshold)
    % Extract Data
    z_force = -squeeze(data.forceplates.Force(:, 3, :));
    left_right_vector = data.events.StrideDetails(:, 4);
    
    % Initialize HS and TO vectors
    num_steps = length(left_right_vector);
    i_left_end = 2 * num_steps - sum(left_right_vector);

    left_HS = zeros(1, i_left_end);
    right_HS = zeros(1, num_steps - i_left_end);

    left_TO = left_HS;
    right_TO = right_HS;

    %% Produce HS and TO vectors
    for i_col = 1 : num_steps
        this_HS = 1;
        this_TO = 150;

        upper_threshold = 1000000;
        lower_threshold = 1000000;

        for i_row = 1 : 120
            this_datum = z_force(i_row, i_col);

            if (i_row < 30) && ...
                (abs(this_datum - force_threshold) < abs(lower_threshold - force_threshold))
                lower_threshold = this_datum;
                this_HS = i_row;
            end

            if (i_row > 30) && ...
                (abs(this_datum - force_threshold) < abs(upper_threshold - force_threshold))
                upper_threshold = this_datum;
                this_TO = i_row;
            end

        end

        % Append to HS and TO vectors
        if i_col > i_left_end
            i_right = i_col - i_left_end;
            right_HS(i_right) = this_HS;
            right_TO(i_right) = this_TO;
        else
            left_HS(i_col) = this_HS;
            left_TO(i_col) = this_TO;
        end
    end
end