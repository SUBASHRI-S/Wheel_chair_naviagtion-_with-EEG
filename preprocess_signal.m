function sig_out = preprocess_signal(sig_in, cfg)
%PREPROCESS_SIGNAL  Apply EEG preprocessing to a [samples x channels] matrix.
%
%  Steps applied per channel:
%    1. Remove DC offset (subtract mean)
%    2. Bandpass filter  0.5 – 40 Hz  (4th-order Butterworth, zero-phase)
%    3. Notch filter     50 Hz         (2nd-order IIR, zero-phase)
%    4. Z-score normalization
%
%  Inputs:
%    sig_in : [samples x channels]
%    cfg    : struct with fields Fs, bp_low, bp_high, notch_freq
%
%  Output:
%    sig_out : [samples x channels]  preprocessed signal

Fs    = cfg.Fs;
n_ch  = size(sig_in, 2);

%% ── Design filters once ───────────────────────────────────
% Bandpass: 4th-order Butterworth
[b_bp, a_bp] = butter(4, [cfg.bp_low, cfg.bp_high] / (Fs/2), 'bandpass');

% Notch: 2nd-order Butterworth bandstop at notch_freq ±1 Hz
notch_bw = 2;   % total bandwidth (Hz)
[b_n, a_n] = butter(2, [(cfg.notch_freq - notch_bw/2), ...
                         (cfg.notch_freq + notch_bw/2)] / (Fs/2), 'stop');

sig_out = zeros(size(sig_in));

for ch = 1:n_ch
    x = sig_in(:, ch);

    % 1. Remove DC offset
    x = x - mean(x, 'omitnan');

    % 2. Replace any remaining NaN/Inf with 0
    x(~isfinite(x)) = 0;

    % 3. Bandpass filter (zero-phase)
    try
        x = filtfilt(b_bp, a_bp, x);
    catch
        warning('Bandpass filter failed on channel %d — skipping', ch);
    end

    % 4. Notch filter (zero-phase)
    try
        x = filtfilt(b_n, a_n, x);
    catch
        warning('Notch filter failed on channel %d — skipping', ch);
    end

    % 5. Z-score normalise
    mu  = mean(x);
    sig = std(x);
    if sig > 0
        x = (x - mu) / sig;
    end

    sig_out(:, ch) = x;
end
end