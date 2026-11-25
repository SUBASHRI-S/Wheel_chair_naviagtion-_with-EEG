%% setup_dataset.m
%  Run this ONCE before running main.m to organize your 4 CSV files
%  into the required dataset/ folder structure.
%
%  Your files:
%    ChordsWeb-20260212-162848.csv  → LEFT
%    ChordsWeb-20260212-165722.csv  → RIGHT
%    ChordsWeb-20260212-172830.csv  → FORWARD
%    ChordsWeb-20260212-181430.csv  → STOP
%
%  After running this script:
%    dataset/left/left_1.csv
%    dataset/right/right_1.csv
%    dataset/forward/forward_1.csv
%    dataset/stop/stop_1.csv

clc;
fprintf('Setting up dataset folder structure...\n\n');

% ─── EDIT THESE PATHS TO MATCH WHERE YOUR CSV FILES ARE ──────────────────
csv_files = { ...
    'ChordsWeb-20260212-162848.csv',   'left',    'left_1.csv';    % LEFT
    'ChordsWeb-20260212-165722.csv',   'right',   'right_1.csv';   % RIGHT
    'ChordsWeb-20260212-172830.csv',   'forward', 'forward_1.csv'; % FORWARD
    'ChordsWeb-20260212-181430.csv',   'stop',    'stop_1.csv';    % STOP
};
% ─────────────────────────────────────────────────────────────────────────

dataset_root = 'dataset';

for i = 1:size(csv_files, 1)
    src_file  = csv_files{i, 1};
    class_dir = csv_files{i, 2};
    dst_name  = csv_files{i, 3};

    dst_folder = fullfile(dataset_root, class_dir);
    if ~isfolder(dst_folder)
        mkdir(dst_folder);
    end

    dst_file = fullfile(dst_folder, dst_name);

    if isfile(src_file)
        copyfile(src_file, dst_file);
        fprintf('  ✓ Copied %s → %s\n', src_file, dst_file);
    elseif isfile(dst_file)
        fprintf('  ✓ Already exists: %s\n', dst_file);
    else
        fprintf('  ✗ SOURCE NOT FOUND: %s\n', src_file);
        fprintf('    → Place the file in the same folder as this script,\n');
        fprintf('      or edit csv_files paths in setup_dataset.m\n');
    end
end

fprintf('\nDataset folder structure:\n');
for i = 1:size(csv_files, 1)
    cls = csv_files{i, 2};
    f   = fullfile(dataset_root, cls, csv_files{i, 3});
    if isfile(f)
        info = dir(f);
        fprintf('  [%s] %s  (%.1f KB)\n', upper(cls), f, info.bytes/1024);
    end
end

fprintf('\nSetup complete. Now run: main.m\n');

%% ─── QUICK DATA INSPECTION ────────────────────────────────────────────────
fprintf('\n─── Quick Data Inspection ──────────────────────────────\n');
classes = {'left','right','forward','stop'};
Fs = 500;

for c = 1:4
    fp = fullfile(dataset_root, classes{c}, [classes{c} '_1.csv']);
    if ~isfile(fp), continue; end
    data = readmatrix(fp);
    ch1  = data(2:end, 2);   % skip header if readmatrix kept it
    ch2  = data(2:end, 3);
    n    = numel(ch1);
    dur  = n / Fs;
    fprintf('  [%-8s]  samples: %5d  duration: %.1fs  ', ...
        upper(classes{c}), n, dur);
    fprintf('Ch1 range: [%.4f, %.4f]  Ch2 range: [%.4f, %.4f]\n', ...
        min(ch1), max(ch1), min(ch2), max(ch2));
end
