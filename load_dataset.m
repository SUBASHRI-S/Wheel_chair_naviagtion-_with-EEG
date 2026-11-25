function [raw_signals, labels] = load_dataset(cfg)
%LOAD_DATASET  Scan dataset/ folder and load all EEG CSV files.
%
%  Folder structure expected:
%    dataset/left/     *.csv   → label 1
%    dataset/right/    *.csv   → label 2
%    dataset/forward/  *.csv   → label 3
%    dataset/stop/     *.csv   → label 4
%
%  ALSO supports a single-session mode:
%    If cfg.dataset_root points to a folder containing CSV files directly,
%    those files are loaded with their labels from cfg.file_labels map.
%
%  Output:
%    raw_signals  : [total_samples x 2]  (Channel1, Channel2)
%    labels       : [total_samples x 1]  integer class label

class_map = struct('left',1,'right',2,'forward',3,'stop',4);
class_dirs = fieldnames(class_map);

raw_signals = [];
labels      = [];

for c = 1:numel(class_dirs)
    cls      = class_dirs{c};
    lbl      = class_map.(cls);
    dir_path = fullfile(cfg.dataset_root, cls);

    if ~isfolder(dir_path)
        warning('Folder not found: %s  (skipping)', dir_path);
        continue;
    end

    csv_files = dir(fullfile(dir_path, '*.csv'));
    if isempty(csv_files)
        warning('No CSV files in: %s', dir_path);
        continue;
    end

    for f = 1:numel(csv_files)
        fpath = fullfile(csv_files(f).folder, csv_files(f).name);
        fprintf('  Loading [%s] %s\n', upper(cls), csv_files(f).name);

        try
            data = readmatrix(fpath);  % Auto-skips header row
        catch
            opts      = detectImportOptions(fpath);
            opts.DataLines = 2;
            data = readmatrix(fpath, opts);
        end

        % Columns: Counter(1), Channel1(2), Channel2(3)
        if size(data,2) < 3
            warning('  File has fewer than 3 columns, skipping: %s', fpath);
            continue;
        end

        ch1 = data(:, 2);
        ch2 = data(:, 3);

        % Remove NaN rows
        valid = ~isnan(ch1) & ~isnan(ch2);
        ch1 = ch1(valid);
        ch2 = ch2(valid);

        n = numel(ch1);
        raw_signals = [raw_signals; ch1, ch2];  %#ok<AGROW>
        labels      = [labels; repmat(lbl, n, 1)]; %#ok<AGROW>
    end
end

if isempty(raw_signals)
    error(['No data loaded. Check that the dataset folder exists:\n  %s\n' ...
           'Expected sub-folders: left/ right/ forward/ stop/'], ...
           cfg.dataset_root);
end

fprintf('  Total samples loaded: %d\n', size(raw_signals,1));
end
