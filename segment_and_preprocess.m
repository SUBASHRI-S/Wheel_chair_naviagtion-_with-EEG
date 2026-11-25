function [segments, seg_labels] = segment_and_preprocess(raw_signals, labels, cfg)
%SEGMENT_AND_PREPROCESS  Segment continuous EEG into overlapping windows
%                        and preprocess each window.
%
%  The raw_signals matrix contains concatenated sessions. We detect
%  class boundaries using the labels vector and segment WITHIN each
%  contiguous class block to avoid mixing classes across boundaries.
%
%  Inputs:
%    raw_signals : [total_samples x 2]
%    labels      : [total_samples x 1]  integer labels
%    cfg         : configuration struct
%
%  Outputs:
%    segments   : [N x n_channels x window_len]  (single precision)
%    seg_labels : [N x 1]

Fs          = cfg.Fs;
win_len     = round(cfg.window_sec * Fs);          % samples per window
step        = round(win_len * (1 - cfg.overlap_ratio));  % hop size

segments   = [];
seg_labels = [];

% Find contiguous blocks of same label
block_starts = [1; find(diff(labels) ~= 0) + 1; numel(labels)+1];

for b = 1:numel(block_starts)-1
    s_start = block_starts(b);
    s_end   = block_starts(b+1) - 1;
    lbl     = labels(s_start);
    block   = raw_signals(s_start:s_end, :);   % [block_samples x 2]
    n_samp  = size(block, 1);

    if n_samp < win_len
        continue;  % block too short for even one window
    end

    % Preprocess the entire block first (more efficient, better filter edge handling)
    block_proc = preprocess_signal(block, cfg);

    % Slide window
    win_starts = 1 : step : (n_samp - win_len + 1);

    for ws = win_starts
        we  = ws + win_len - 1;
        win = block_proc(ws:we, :);            % [win_len x 2]
        % Store as [1 x n_channels x win_len]
        segments   = cat(1, segments, reshape(win', [1, size(win,2), win_len]));
        seg_labels = [seg_labels; lbl]; %#ok<AGROW>
    end
end

segments = single(segments);
fprintf('  Windows per class:\n');
for c = 1:4
    fprintf('    Class %d : %d windows\n', c, sum(seg_labels == c));
end
end
