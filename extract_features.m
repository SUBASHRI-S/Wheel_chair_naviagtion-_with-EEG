function [X, Y] = extract_features(segments, seg_labels, cfg)
%EXTRACT_FEATURES  Extract research-grade EEG features from windowed segments.
%
%  Features per channel (repeated for each channel):
%    Time-domain  (8): mean, std, variance, rms, energy, zcr, skewness, kurtosis
%    Frequency    (5): delta, theta, alpha, beta, gamma band power
%    Advanced     (4): spectral entropy, Hjorth activity, mobility, complexity
%  Total per channel = 17
%  Total features    = 17 x 2 channels = 34

Fs      = cfg.Fs;
N       = size(segments, 1);
n_ch    = size(segments, 2);
win_len = size(segments, 3);

bands = [cfg.bands.delta; cfg.bands.theta; cfg.bands.alpha; ...
         cfg.bands.beta;  cfg.bands.gamma];
n_bands = size(bands, 1);

n_feat_per_ch = 8 + n_bands + 4;   % 17
n_feat_total  = n_feat_per_ch * n_ch;

X = zeros(N, n_feat_total);
Y = seg_labels;

% pwelch window must be <= win_len
pwelch_win = min(256, win_len);
NFFT       = max(512, 2^nextpow2(win_len));

fprintf('  Extracting features: ');
progress_step = max(1, floor(N/20));

for i = 1:N
    if mod(i, progress_step) == 0
        fprintf('.');
    end

    feat_row = zeros(1, n_feat_total);
    col_ptr  = 1;

    for ch = 1:n_ch
        x = double(squeeze(segments(i, ch, :)));   % [win_len x 1]

        % Guard: replace any NaN/Inf
        x(~isfinite(x)) = 0;

        %% Time-domain features
        x_mean   = mean(x);
        x_std    = std(x);
        x_var    = var(x);
        x_rms    = sqrt(mean(x.^2));
        x_energy = sum(x.^2);
        x_zcr    = sum(abs(diff(sign(x - x_mean)))) / (2 * win_len);
        x_skew   = safe_skewness(x);
        x_kurt   = safe_kurtosis(x);

        feat_td = [x_mean, x_std, x_var, x_rms, x_energy, x_zcr, x_skew, x_kurt];

        %% Frequency-domain: band power via trapz (no toolbox dependency)
        [pxx, f_psd] = pwelch(x, hamming(pwelch_win), ...
                               floor(pwelch_win/2), NFFT, Fs);

        feat_bp = zeros(1, n_bands);
        for b = 1:n_bands
            lo  = bands(b, 1);
            hi  = bands(b, 2);
            idx = f_psd >= lo & f_psd <= hi;
            if sum(idx) >= 2
                feat_bp(b) = trapz(f_psd(idx), pxx(idx));
            elseif sum(idx) == 1
                feat_bp(b) = pxx(idx);
            else
                % Fallback: nearest bin to band centre
                [~, nearest] = min(abs(f_psd - (lo + hi)/2));
                feat_bp(b)   = pxx(nearest);
            end
        end

        %% Advanced features
        % Spectral entropy (normalised to [0,1])
        total_pwr    = sum(pxx) + eps;
        pxx_norm     = pxx / total_pwr;
        spec_entropy = -sum(pxx_norm .* log2(pxx_norm + eps));
        spec_entropy = spec_entropy / log2(numel(pxx));

        % Hjorth parameters
        dx  = diff(x);
        ddx = diff(dx);
        hjorth_act  = var(x);
        var_dx      = var(dx);
        hjorth_mob  = sqrt(var_dx / (hjorth_act + eps));
        hjorth_cplx = sqrt(var(ddx) / (var_dx + eps)) / (hjorth_mob + eps);

        feat_adv = [spec_entropy, hjorth_act, hjorth_mob, hjorth_cplx];

        %% Concatenate
        all_feat = [feat_td, feat_bp, feat_adv];
        feat_row(col_ptr : col_ptr + n_feat_per_ch - 1) = all_feat;
        col_ptr = col_ptr + n_feat_per_ch;
    end

    X(i, :) = feat_row;
end

fprintf(' done.\n');

% Final sanitize
X(~isfinite(X)) = 0;

% Export feature names to workspace
feat_names = {};
td_names   = {'mean','std','var','rms','energy','zcr','skewness','kurtosis'};
band_names = {'delta','theta','alpha','beta','gamma'};
adv_names  = {'spec_entropy','hjorth_act','hjorth_mob','hjorth_cplx'};
for ch = 1:n_ch
    prefix     = sprintf('ch%d_', ch);
    feat_names = [feat_names, strcat(prefix, td_names), ...
                  strcat(prefix, band_names), strcat(prefix, adv_names)]; %#ok<AGROW>
end
assignin('base', 'feature_names', feat_names);

fprintf('  Feature extraction complete: %d windows x %d features\n', N, n_feat_total);
end

%% Safe statistics (avoid division by zero on flat signals)
function s = safe_skewness(x)
    mu  = mean(x);
    sig = std(x);
    if sig < eps
        s = 0;
    else
        s = mean(((x - mu) / sig).^3);
    end
end

function k = safe_kurtosis(x)
    mu  = mean(x);
    sig = std(x);
    if sig < eps
        k = 0;
    else
        k = mean(((x - mu) / sig).^4);
    end
end