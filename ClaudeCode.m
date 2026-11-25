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
Normalized = load("/Users/kefuller/Documents/Fuller_locoLab_SLC_initialAnalysis/locolab_files/Normalized.mat");
addpath("plotting&testing_functions/");

[HKIC_plotting_matrix, HKIC_SLCvector] = get_plottingMatrices(HKIC);
[SLC_plotting_matrix, SLC_SLCvector] = get_plottingMatrices(SLC);

% Drop empty / 1-frame strides
HKIC_SLCvector = clean_SLCvector(HKIC_SLCvector);
SLC_SLCvector = clean_SLCvector(SLC_SLCvector);

% Shared bucket edges (tertiles of HKIC + SLC strides)
SL_edges = tertile_edges([HKIC_SLCvector(1, :), SLC_SLCvector(1, :)]);
cad_edges = tertile_edges([HKIC_SLCvector(2, :), SLC_SLCvector(2, :)]);
fprintf("Stride length edges: %.3f  %.3f  %.3f  %.3f\n", SL_edges);
fprintf("Cadence edges:       %.1f  %.1f  %.1f  %.1f\n", cad_edges);

for graphType = 1 : 4
    plot_buckets(HKIC_plotting_matrix, SLC_plotting_matrix, HKIC_SLCvector, SLC_SLCvector, ...
                 graphType, {SL_edges, cad_edges});
end

% Export all figures to one PDF (in creation order)
pdf_file_name = "HKIC SLC Torque and Angle by Stride Length and Cadence.pdf";
figs = findall(groot, 'Type', 'figure');
[~, order] = sort([figs.Number]);
figs = figs(order);

if isfile(pdf_file_name)
    delete(pdf_file_name)
end
for i = 1 : numel(figs)
    set(figs(i), 'Units', 'inches', 'Position', [0 0 14 5]); % wide for 3 tiles
    exportgraphics(figs(i), pdf_file_name, 'ContentType', 'vector', 'Append', i > 1);
end
fprintf("Saved %d figures to %s\n", numel(figs), pdf_file_name);


function plot_buckets(HKIC_pm, SLC_pm, HKIC_vec, SLC_vec, graphType, edges)
% One figure per sort type (stride length, cadence), 3 tiles each
    d = dictionary([1 2 3 4], ["Ankle Torque", "Knee Torque", "Ankle Angle", "Knee Angle"]);
    sort_names = ["Stride Length", "Cadence"];
    units = ["m", "strides/min"];
    bucket_names = ["Short", "Medium", "Long"; "Low", "Medium", "High"];

    for r = 1 : 2
        figure('Name', d(graphType) + " by " + sort_names(r));
        tiledlayout(1, 3, 'TileSpacing', 'compact');
        for b = 1 : 3
            nexttile; hold on; grid on;
            entries = {};
            entries = add_bucket(entries, HKIC_pm(:, :, graphType), HKIC_vec(r, :), edges{r}, b, 'm', "HKIC");
            entries = add_bucket(entries, SLC_pm(:, :, graphType), SLC_vec(r, :), edges{r}, b, 'c', "SLC");

            title(bucket_names(r, b) + " " + sort_names(r) + ...
                  sprintf(" (%.2f - %.2f ", edges{r}(b), edges{r}(b + 1)) + units(r) + ")");
            xlabel('Gait Percentage');
            ylabel(d(graphType));
            legend(entries, 'location', 'best');
            hold off;
        end
        linkaxes(findobj(gcf, 'Type', 'axes'), 'y');
        sgtitle("SLC & HKIC " + d(graphType) + " by " + sort_names(r), 'FontSize', 16, 'FontWeight', 'bold');
    end
end

function entries = add_bucket(entries, data, sort_vec, edges, b, color, label)
% Mean +/- std of strides in bucket b
    in_b = sort_vec >= edges(b) & (sort_vec < edges(b + 1) | (b == 3 & sort_vec <= edges(b + 1)));
    if ~any(in_b), return; end

    this_data = data(:, in_b);
    x = linspace(1, 100, size(this_data, 1));
    y = mean(this_data, 2);
    error = std(this_data, 0, 2);
    plotShaded(x, [y + error, y, y - error], color, '-', 1);
    entries{end + 1} = label + ", " + nnz(in_b) + " strides";
end

function SLCvector = clean_SLCvector(SLCvector)
% NaN out invalid strides so they fall in no bucket
    bad = SLCvector(1, :) <= 0 | ~isfinite(SLCvector(2, :));
    SLCvector(:, bad) = NaN;
end

function edges = tertile_edges(v)
% [min, 33rd pct, 67th pct, max]
    v = sort(v(~isnan(v)));
    edges = [v(1), interp1(linspace(0, 1, numel(v)), v, [1/3 2/3]), v(end)];
end

% Helper functions
function [plotting_matrix, SLCvector] = get_plottingMatrices(data)
    [aT, kT, aA, kA] = formatData(data);
    SLCvector = get_SLC(aT);

    plotting_matrix = zeros(size(aT, 1), size(aT, 2), 4);
    plotting_matrix(:, :, 1) = reformatData_forPlotting(aT);
    plotting_matrix(:, :, 2) = reformatData_forPlotting(kT);
    plotting_matrix(:, :, 3) = reformatData_forPlotting(aA);
    plotting_matrix(:, :, 4) = reformatData_forPlotting(kA);
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