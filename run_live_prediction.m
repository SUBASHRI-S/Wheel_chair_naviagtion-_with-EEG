%% run_live_prediction.m
%  Real-time EEG Wheelchair BCI — Full Integrated Pipeline
%
%  EEG Device  : Arduino UNO R4 Minima + EXG Pills (COM8, 230400 baud)
%  Robot Car   : Arduino UNO + L298N + HC-05 Bluetooth (COM10, 9600 baud)
%
%  Command mapping:
%    LEFT    → 'L'  pivot left then forward (handled in Arduino)
%    RIGHT   → 'R'  pivot right then forward (handled in Arduino)
%    FORWARD → 'F'  move forward
%    STOP    → 'S'  stop all motors
%
%  Safety features:
%    1. Confidence threshold  — below 60% sends STOP
%    2. Consecutive limit     — same non-STOP command > MAX_SAME_CMD sends STOP

clc;
fprintf('╔══════════════════════════════════════════════╗\n');
fprintf('║   EEG Wheelchair BCI — Full System Active    ║\n');
fprintf('╚══════════════════════════════════════════════╝\n\n');

%% ── CONFIGURATION ────────────────────────────────────────────────────────
EEG_PORT       = 'COM8';
EEG_BAUD       = 230400;
CAR_PORT       = 'COM10';
CAR_BAUD       = 9600;

Fs             = 500;
WINDOW_SEC     = 2;
OVERLAP        = 0.5;
VOTE_COUNT     = 3;
MIN_CONFIDENCE = 0.60;   % below this → safety STOP
MAX_SAME_CMD   = 3;      % max consecutive same non-STOP decisions → force STOP

% Chords binary protocol
SYNC_BYTE_1  = hex2dec('C7');
SYNC_BYTE_2  = hex2dec('7C');
END_BYTE     = hex2dec('01');
HEADER_LEN   = 3;
NUM_CHANNELS = 6;
PACKET_LEN   = HEADER_LEN + (NUM_CHANNELS * 2) + 1;  % 16 bytes
ADC_MAX      = 2^14 - 1;
ADC_REF      = 5.0;

win_len  = Fs * WINDOW_SEC;
step_len = round(win_len * (1 - OVERLAP));

%% ── LOAD MODEL ───────────────────────────────────────────────────────────
fprintf('[1] Loading trained model...\n');
if ~isfile('eeg_model.mat')
    error('eeg_model.mat not found. Run main.m first.');
end
loaded = load('eeg_model.mat');
model  = loaded.best_model;
cfg    = loaded.feature_cfg;
cfg.Fs = Fs;
fprintf('    Model : %s\n\n', class(model));

%% ── CONNECT EEG DEVICE ───────────────────────────────────────────────────
fprintf('[2] Connecting to EEG device on %s...\n', EEG_PORT);
try
    eeg = serialport(EEG_PORT, EEG_BAUD);
    eeg.Timeout = 10;
    configureTerminator(eeg, 'LF');
    flush(eeg);
    pause(2);

    writeline(eeg, 'WHORU');
    pause(0.5);
    response = '';
    try, response = strtrim(char(readline(eeg))); catch, end
    fprintf('    Device   : %s\n', response);

    writeline(eeg, 'START');
    pause(1);
    fprintf('    Streaming: started\n');

    pause(1);
    if eeg.NumBytesAvailable == 0
        error('No bytes received after START.');
    end
    fprintf('    Bytes    : %d available\n\n', eeg.NumBytesAvailable);
catch ME
    fprintf('  EEG connection failed: %s\n', ME.message);
    return;
end

%% ── CONNECT ROBOT CAR ────────────────────────────────────────────────────
fprintf('[3] Connecting to Robot Car on %s...\n', CAR_PORT);
try
    car = serialport(CAR_PORT, CAR_BAUD);
    car.Timeout = 2;
    pause(2);
    flush(car);
    write(car, uint8('S'), 'uint8');
    fprintf('    Connected. Initial STOP sent.\n\n');
catch ME
    fprintf('  Robot car connection failed: %s\n', ME.message);
    fprintf('  Continuing in prediction-only mode...\n\n');
    car = [];
end

%% ── BUFFERS ──────────────────────────────────────────────────────────────
sample_buffer  = zeros(win_len, 2);
vote_commands  = cell(VOTE_COUNT, 1);
vote_confs     = zeros(VOTE_COUNT, 1);
vote_ptr       = 0;
vote_filled    = 0;
sample_count   = 0;
pred_count     = 0;
decision_count = 0;
packets_ok     = 0;
packets_bad    = 0;
last_command   = 'S';
same_cmd_count = 0;
class_names    = {'LEFT','RIGHT','FORWARD','STOP'};

%% ── HEADER ───────────────────────────────────────────────────────────────
fprintf('╔══════════════════════════════════════════════════════════╗\n');
fprintf('║  System Ready. Hold each mental command for ~3 seconds. ║\n');
fprintf('║  LEFT/RIGHT → pivot then forward  |  Ctrl+C to stop     ║\n');
fprintf('╚══════════════════════════════════════════════════════════╝\n\n');
fprintf('  %-10s  %-10s  %-8s  %-6s  %s\n', ...
        'Time','Decision','Conf','Votes','Car');
fprintf('  %s\n', repmat('─',1,55));

%% ── MAIN LOOP ────────────────────────────────────────────────────────────
byte_buf = uint8([]);

try
while true

    %% Read bytes from EEG device
    n_new = eeg.NumBytesAvailable;
    if n_new > 0
        new_bytes = read(eeg, n_new, 'uint8');
        byte_buf  = [byte_buf, new_bytes(:)']; %#ok<AGROW>
    else
        pause(0.001);
        continue;
    end

    %% Parse binary packets
    while numel(byte_buf) >= PACKET_LEN

        % Find sync bytes
        sync_idx = [];
        for k = 1:numel(byte_buf)-1
            if byte_buf(k) == SYNC_BYTE_1 && byte_buf(k+1) == SYNC_BYTE_2
                sync_idx = k;
                break;
            end
        end

        if isempty(sync_idx)
            byte_buf = byte_buf(end);
            break;
        end

        if sync_idx > 1
            byte_buf = byte_buf(sync_idx:end);
        end

        if numel(byte_buf) < PACKET_LEN
            break;
        end

        packet = byte_buf(1:PACKET_LEN);

        if packet(end) == END_BYTE
            packets_ok = packets_ok + 1;

            ch1_raw = uint16(packet(4)) * 256 + uint16(packet(5));
            ch2_raw = uint16(packet(6)) * 256 + uint16(packet(7));
            ch1_v   = (double(ch1_raw) / ADC_MAX * ADC_REF) - ADC_REF/2;
            ch2_v   = (double(ch2_raw) / ADC_MAX * ADC_REF) - ADC_REF/2;

            byte_buf = byte_buf(PACKET_LEN+1:end);

            sample_buffer(1:end-1, :) = sample_buffer(2:end, :);
            sample_buffer(end, :)     = [ch1_v, ch2_v];
            sample_count              = sample_count + 1;

            %% Predict every step_len samples once buffer is full
            if sample_count >= win_len && mod(sample_count - win_len, step_len) == 0

                pred_count = pred_count + 1;

                try
                    [cmd, conf] = predict_realtime(sample_buffer, model, cfg);
                catch
                    continue;
                end

                vote_ptr                = mod(vote_ptr, VOTE_COUNT) + 1;
                vote_commands{vote_ptr} = cmd;
                vote_confs(vote_ptr)    = conf;
                vote_filled             = min(vote_filled + 1, VOTE_COUNT);

                %% Majority vote
                if vote_filled == VOTE_COUNT && mod(pred_count, VOTE_COUNT) == 0

                    decision_count = decision_count + 1;

                    votes    = zeros(1,4);
                    conf_sum = zeros(1,4);
                    for v = 1:VOTE_COUNT
                        idx = find(strcmp(class_names, vote_commands{v}));
                        if ~isempty(idx)
                            votes(idx)    = votes(idx)    + 1;
                            conf_sum(idx) = conf_sum(idx) + vote_confs(v);
                        end
                    end

                    avg_conf         = conf_sum ./ max(votes,1);
                    [max_v, win_idx] = max(votes + avg_conf * 0.01);
                    final_cmd        = class_names{win_idx};
                    final_conf       = avg_conf(win_idx);
                    win_sym          = command_symbol(final_cmd);
                    t_now            = datestr(now, 'HH:MM:SS');

                    % Vote breakdown
                    breakdown = '';
                    for v = 1:VOTE_COUNT
                        breakdown = [breakdown, command_symbol(vote_commands{v})]; %#ok<AGROW>
                    end

                    %% ── Safety Check 1: Confidence threshold ─────────
                    if final_conf < MIN_CONFIDENCE
                        car_cmd    = 'S';
                        status_str = '✘ LOW CONF → STOP';
                        if ~isempty(car)
                            try, write(car, uint8('S'), 'uint8'); catch, end
                        end
                        fprintf('  [%s]  %-8s  %5.1f%%  [%s]  %s\n', ...
                                t_now, final_cmd, final_conf*100, breakdown, status_str);

                    else
                        %% ── Safety Check 2: Consecutive command limit ─
                        if strcmp(final_cmd, last_command) && ~strcmp(final_cmd, 'STOP')
                            same_cmd_count = same_cmd_count + 1;
                        else
                            same_cmd_count = 1;
                        end

                        if same_cmd_count > MAX_SAME_CMD && ~strcmp(final_cmd, 'STOP')
                            % Too many repeats — force a STOP
                            car_cmd        = 'S';
                            same_cmd_count = 0;
                            status_str     = sprintf('⚠ REPEATED %dx → STOP', MAX_SAME_CMD+1);
                            if ~isempty(car)
                                try, write(car, uint8('S'), 'uint8'); catch, end
                            end
                            fprintf('  [%s]  %-8s  %5.1f%%  [%s]  %s\n', ...
                                    t_now, final_cmd, final_conf*100, breakdown, status_str);
                        else
                            %% ── Send command to car ───────────────────
                            car_cmd = map_to_car(final_cmd);
                            if ~isempty(car)
                                try, write(car, uint8(car_cmd), 'uint8'); catch, end
                            end
                            status_str = sprintf('✔ → %s', car_cmd);
                            fprintf('  [%s]  %s %-7s  %5.1f%%  [%s]  %s  (%d/%d)\n', ...
                                    t_now, win_sym, final_cmd, final_conf*100, ...
                                    breakdown, status_str, round(max_v), VOTE_COUNT);
                        end

                        last_command = final_cmd;
                    end
                    fprintf('\n');

                    % Reset vote buffer
                    vote_commands = cell(VOTE_COUNT,1);
                    vote_confs    = zeros(VOTE_COUNT,1);
                    vote_ptr      = 0;
                    vote_filled   = 0;
                end
            end
        else
            packets_bad = packets_bad + 1;
            byte_buf    = byte_buf(2:end);
        end
    end
end

catch ME
    fprintf('\n  Stopped: %s\n', ME.message);
end

%% ── CLEANUP ──────────────────────────────────────────────────────────────
fprintf('\n[4] Shutting down...\n');
if ~isempty(car)
    try
        write(car, uint8('S'), 'uint8');
        fprintf('    Car stopped.\n');
        pause(0.3);
        clear car;
    catch
    end
end
try
    writeline(eeg, 'STOP');
    pause(0.3);
    clear eeg;
    fprintf('    EEG stopped.\n');
catch
end

fprintf('\n╔══════════════════════════════════════════╗\n');
fprintf('║              SESSION SUMMARY             ║\n');
fprintf('╠══════════════════════════════════════════╣\n');
fprintf('║  EEG packets     : %5d good / %3d bad  ║\n', packets_ok, packets_bad);
fprintf('║  Raw predictions : %5d                  ║\n', pred_count);
fprintf('║  Voted decisions : %5d                  ║\n', decision_count);
fprintf('║  Last command    : %-8s               ║\n', last_command);
fprintf('╚══════════════════════════════════════════╝\n');

%% ── Helpers ──────────────────────────────────────────────────────────────
function car_cmd = map_to_car(bci_cmd)
switch bci_cmd
    case 'FORWARD', car_cmd = 'F';
    case 'LEFT',    car_cmd = 'L';
    case 'RIGHT',   car_cmd = 'R';
    case 'STOP',    car_cmd = 'S';
    otherwise,      car_cmd = 'S';
end
end

function sym = command_symbol(cmd)
switch cmd
    case 'LEFT',    sym = '←';
    case 'RIGHT',   sym = '→';
    case 'FORWARD', sym = '↑';
    case 'STOP',    sym = '■';
    otherwise,      sym = '?';
end
end