close all
clearvars -except HKIC SLC

% Time is stored in DataRecordCommon.timeOut
% The foot contact signal is in DataRecordCommon.robustFC (1 for foot contact, 0 for no foot contact)
% Knee torque commands are in DataRecordCommon.kneeCommands_tau_Nm
% Ankle torque commands are in DataRecordCommon.ankleCommands_tau_Nm
% Knee angle is in Knee_Encoder.Angle
% Ankle angle is in Ankle_Encoder.Angle

HKIC = load("/Users/kefuller/Documents/Fuller_locoLab_SLC_initialAnalysis/locolab_files/1117_HKIC.mat");
SLC = load("/Users/kefuller/Documents/Fuller_locoLab_SLC_initialAnalysis/locolab_files/1117_SLC.mat");
load("/Users/kefuller/Documents/Fuller_locoLab_SLC_initialAnalysis/locolab_files/Normalized.mat");

[SLC_ankleTorque, SLC_kneeTorque, SLC_ankleAngle, SLC_kneeAngle] = formatData(SLC);
SLC_SLCvector = get_SLC(SLC_ankleTorque);

[HKIC_plotting_matrices, HKIC_SLCvector] = get_sorted_plottingMatrices(HKIC);
[SLC_plotting_matrices, SLC_SLCvector_new] = get_sorted_plottingMatrices(SLC);
AB_plotting_matrices = 0;

dataStem = Normalized.AB01.Walk.s1.i0;
force_threshold = 25;
addpath("computation_functions/");
[left_HS, right_HS, left_TO, right_TO] = find_HS_TO(dataStem, force_threshold);
HS = [left_HS, right_HS];
TO = [left_TO, right_TO];

% --- PDF output ---
pdfName = "SLC_HKIC_plots.pdf";
if isfile(pdfName)
    delete(pdfName);   % start fresh each run
end

for data_type = 1 : 4
    for sorting_type = 1 : 2
        HKIC_extracted_plottingData = HKIC_plotting_matrices{sorting_type}(:, :, data_type);
        SLC_extracted_plottingData = SLC_plotting_matrices{sorting_type}(:, :, data_type);
        AB_extracted_plottingData = AB_plotting_matrices;

        % Sorted SL/cadence values, same order as columns
        HKIC_vals = sort(HKIC_SLCvector(sorting_type, :));
        SLC_vals  = sort(SLC_SLCvector_new(sorting_type, :));

        plotHelper_makePlotSet(HKIC_extracted_plottingData, SLC_extracted_plottingData, AB_extracted_plottingData, ...
                               HKIC_vals, SLC_vals, data_type, sorting_type);

        % Add this figure as a new PDF page
        exportgraphics(gcf, pdfName, 'Append', true, 'ContentType', 'vector');
    end
end

% Helper functions
function plotHelper_makePlotSet(HKIC_matrices, SLC_matrices, AB_matrix, HKIC_vals, SLC_vals, data_type, sorting_type)
    d_data = dictionary([1 2 3 4], ["Ankle Torque", "Knee Torque", "Ankle Angle", "Knee Angle"]);
    d_sort = dictionary([1 2], ["Stride Length (m)", "Cadence (strides / min)"]);
    levels = ["Low", "Medium", "High"];

    % --- Split Data ---
    HKIC_plot = splitThirds(HKIC_matrices);
    SLC_plot  = splitThirds(SLC_matrices);
    HKIC_valGroups = splitThirds(HKIC_vals);
    SLC_valGroups  = splitThirds(SLC_vals);

    figure;
    tiledlayout(1, 3);

    % --- Plot Low / Medium / High ---
    for g = 1:3
        nexttile;
        hold on;
        plotHelper_makeOnePlot(HKIC_plot{g}, SLC_plot{g}, AB_matrix, d_data(data_type));
        title(levels(g) + " " + d_sort(sorting_type));
        subtitle("HKIC: " + rangeStr(HKIC_valGroups{g}) + "   SLC: " + rangeStr(SLC_valGroups{g}));
    end

    % --- Title ---
    sgtitle("SLC & HKIC " + d_data(data_type) + ", sorted by " + d_sort(sorting_type));
end
function groups = splitThirds(M)
    % Split sorted columns into 3 ~equal groups
    n = size(M, 2);
    edges = round(linspace(0, n, 4));
    groups = cell(1, 3);
    for g = 1:3
        groups{g} = M(:, edges(g)+1 : edges(g+1));
    end
end
function s = rangeStr(v)
    % "min–max" of a group
    s = sprintf("%.2f–%.2f", min(v), max(v));
end
function plotHelper_makeOnePlot(HKIC_matrix, SLC_matrix, AB_matrix, y_label)
    % --- Plot 1: HKIC ---
    hold on;
    this_data = HKIC_matrix;
    x = linspace(1, 100, size(this_data, 1));
    y = mean(this_data, 2);
    error = std(this_data, 0, 2);
    
    addpath("plotting&testing_functions/");
    plotShaded(x, [y + error, y, y - error], 'm', '-', 1);
    
    % --- Plot 2: SLC ---
    this_data = SLC_matrix;
    x = linspace(1, 100, size(this_data, 1));
    y = mean(this_data, 2);
    error = std(this_data, 0, 2);
    
    addpath("plotting&testing_functions/");
    plotShaded(x, [y + error, y, y - error], 'c', '-', 1);

    % --- Plot Settings ---
    grid on;
    xlabel('Gait Percentage');
    ylabel(y_label);
    legend({"HKIC", "SLC"}, 'location','best');
    hold off;
end
function [plotting_matrices, SLCvector] = get_sorted_plottingMatrices(data)
    [aT, kT, aA, kA] = formatData(data);
    SLCvector = get_SLC(aT);

    plotting_matrices = cell(1, 3);

    LOCAL_skeleton_matrix = zeros(size(aT, 1), size(aT, 2), 4);
    raw_plotting_matrix = LOCAL_skeleton_matrix;
    SLsorted_plotting_matrix = LOCAL_skeleton_matrix;
    Csorted_plotting_matrix = LOCAL_skeleton_matrix;

    raw_plotting_matrix(:, :, 1) = reformatData_forPlotting(aT);
    raw_plotting_matrix(:, :, 2) = reformatData_forPlotting(kT);
    raw_plotting_matrix(:, :, 3) = reformatData_forPlotting(aA);
    raw_plotting_matrix(:, :, 4) = reformatData_forPlotting(kA);

    [~, I] = sort(SLCvector(1, :));
    SLsorted_plotting_matrix(:, :, 1) = raw_plotting_matrix(:, I, 1);
    SLsorted_plotting_matrix(:, :, 2) = raw_plotting_matrix(:, I, 2);
    SLsorted_plotting_matrix(:, :, 3) = raw_plotting_matrix(:, I, 3);
    SLsorted_plotting_matrix(:, :, 4) = raw_plotting_matrix(:, I, 4);

    [~, I] = sort(SLCvector(2, :));
    Csorted_plotting_matrix(:, :, 1) = raw_plotting_matrix(:, I, 1);
    Csorted_plotting_matrix(:, :, 2) = raw_plotting_matrix(:, I, 2);
    Csorted_plotting_matrix(:, :, 3) = raw_plotting_matrix(:, I, 3);
    Csorted_plotting_matrix(:, :, 4) = raw_plotting_matrix(:, I, 4);

    plotting_matrices{1} = SLsorted_plotting_matrix;
    plotting_matrices{2} = Csorted_plotting_matrix;
    plotting_matrices{3} = raw_plotting_matrix;
end
function[matrix_plottable] = reformatData_forPlotting(matrix_unplottable)
    matrix_plottable = matrix_unplottable(:, :, 1);
    numStrides = size(matrix_unplottable, 2);

    for i_col = 1 : numStrides
        max_data_length = size(matrix_unplottable, 1);
        i_last = find(matrix_unplottable(:, i_col, 2), 1, 'last');
        if i_last ~= max_data_length
            this_length = i_last;
        
            x = 1 : this_length;
            y = matrix_unplottable(1 : i_last, i_col, 1);
        
            interpolate_x = linspace(1, this_length, max_data_length);
            interpolate_y = interp1(x', y, interpolate_x)';
            matrix_plottable(:, i_col) = interpolate_y;
        end
    end
end
function [SLC] = get_SLC(data)
    numStrides = size(data, 2);
    times = data(:, :, 2);
    SLC = zeros(2, numStrides);

    for i_col = 1 : numStrides
        i_last = find(times(:, i_col), 1, 'last');
        t_first = times(1, i_col);
        t_last  = times(i_last, i_col);
        t_diff = t_last - t_first;
    
        SLC(1, i_col) = t_diff * 2; % meters = velocity * time * 2
        SLC(2, i_col) = 60 / t_diff; % Strides per minute
    end
end
function [aT, kT, aA, kA] = formatData(dataSet)
    global time
    global contact_signal
    global skeleton_matrix

    time = dataSet.DataRecordCommon.timeOut;
    contact_signal = dataSet.DataRecordCommon.robustFC;
    ankle_Torque_raw = dataSet.DataRecordCommon.ankleCommands_tau_Nm;
    knee_Torque_raw = dataSet.DataRecordCommon.kneeCommands_tau_Nm;
    ankle_Angle_raw = dataSet.Ankle_Encoder.Angle;
    knee_Angle_raw = dataSet.Knee_Encoder.Angle;
    
    % Get max_strideFrames (longest run of foot contact)
    count = contact_signal(1);
    num_steps = count;
    max_strideFrames = count;
    
    for i = 2 : numel(contact_signal)
        if contact_signal(i)
            count = count + 1;
            max_strideFrames = max(max_strideFrames, count);
            if ~contact_signal(i - 1)
                num_steps = num_steps + 1;
            end
        else
            count = 0;
        end
    end
    skeleton_matrix = zeros(max_strideFrames, num_steps, 2);
    
    % Resize each matrix
    aT = resize_matrix(ankle_Torque_raw);
    kT = resize_matrix(knee_Torque_raw);
    aA = resize_matrix(ankle_Angle_raw);
    kA = resize_matrix(knee_Angle_raw);
end
function [out_matrix] = resize_matrix(raw_data)
    global time
    global contact_signal
    global skeleton_matrix
    out_matrix = skeleton_matrix;
    i_row = 1;
    i_col = 1;
    i_end = numel(raw_data) - 1;
    for i = 1 : i_end
        if contact_signal(i)
            out_matrix(i_row, i_col, 1) = raw_data(i);
            out_matrix(i_row, i_col, 2) = time(i);
    
            if contact_signal(i + 1)
                i_row = i_row + 1;
                if i == i_end
                    out_matrix(i_row, i_col, 1) = raw_data(i + 1);
                    out_matrix(i_row, i_col, 2) = time(i + 1);
                end
            else
                i_col = i_col + 1;
                i_row = 1;
            end
        end
    end
    if contact_signal(end) && ~contact_signal(end - 1)
        % Edge case: If contact_signal(end - 1) == 0 && contact_signal(end) == 1, 
        % that 1-frame step is counted in num_steps but never written, so its column stays all zeros
        out_matrix(1, i_col, 1) = raw_data(end);
        out_matrix(1, i_col, 2) = time(end);
    end
end