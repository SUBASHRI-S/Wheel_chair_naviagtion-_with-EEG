%% test_arduino.m
%  Run this FIRST to detect exact byte format from Arduino
%  This tries multiple reading strategies to find what works

clc;
fprintf('Arduino Data Format Detection\n');
fprintf('==============================\n\n');

COM_PORT  = 'COM8';
BAUD_RATE = 230400;

%% Connect
fprintf('Connecting to %s at %d...\n', COM_PORT, BAUD_RATE);
try
    s = serialport(COM_PORT, BAUD_RATE);
    s.Timeout = 5;
    flush(s);
    pause(3);   % wait for Arduino to boot and start streaming
    fprintf('Connected.\n\n');
catch ME
    fprintf('Connection failed: %s\n', ME.message);
    return;
end

%% Strategy 1: Read raw bytes
fprintf('--- Strategy 1: Raw bytes (200 bytes) ---\n');
try
    flush(s);
    pause(0.5);
    n_avail = s.NumBytesAvailable;
    fprintf('Bytes in buffer: %d\n', n_avail);

    if n_avail == 0
        pause(2);
        n_avail = s.NumBytesAvailable;
        fprintf('Bytes after 2s wait: %d\n', n_avail);
    end

    if n_avail > 0
        n_read = min(n_avail, 200);
        raw    = read(s, n_read, 'uint8');
        fprintf('Raw as text:\n%s\n\n', char(raw));
        fprintf('First 30 byte values: ');
        fprintf('%d ', raw(1:min(30,end)));
        fprintf('\n\n');
    else
        fprintf('Still 0 bytes — Arduino not streaming or wrong baud rate\n\n');
    end
catch ME
    fprintf('Strategy 1 failed: %s\n\n', ME.message);
end

%% Strategy 2: Read with 'read' line by line manually
fprintf('--- Strategy 2: Manual line read (look for newline byte=10) ---\n');
try
    flush(s);
    pause(1);
    line_bytes = uint8([]);
    lines_found = 0;
    timeout_count = 0;

    while lines_found < 5 && timeout_count < 5000
        if s.NumBytesAvailable > 0
            b = read(s, 1, 'uint8');
            timeout_count = 0;
            if b == 10   % newline character
                if ~isempty(line_bytes)
                    % Remove carriage return if present
                    line_bytes = line_bytes(line_bytes ~= 13);
                    fprintf('Line %d: %s\n', lines_found+1, char(line_bytes));
                    lines_found  = lines_found + 1;
                    line_bytes   = uint8([]);
                end
            else
                line_bytes = [line_bytes, b]; %#ok<AGROW>
            end
        else
            timeout_count = timeout_count + 1;
            pause(0.001);
        end
    end

    if lines_found == 0
        fprintf('No newline-terminated lines found.\n');
        fprintf('Arduino may be sending binary packets, not text.\n');
    end
catch ME
    fprintf('Strategy 2 failed: %s\n\n', ME.message);
end

%% Strategy 3: Check if data is binary (non-printable bytes)
fprintf('\n--- Strategy 3: Binary packet detection ---\n');
try
    flush(s);
    pause(1);
    if s.NumBytesAvailable > 0
        raw2 = read(s, min(s.NumBytesAvailable, 50), 'uint8');
        printable = sum(raw2 >= 32 & raw2 <= 126);
        total     = numel(raw2);
        fprintf('Printable bytes: %d / %d (%.0f%%)\n', printable, total, 100*printable/total);
        if printable/total > 0.8
            fprintf('→ Data is TEXT format\n');
        else
            fprintf('→ Data is BINARY format\n');
            fprintf('→ Byte values: ');
            fprintf('%d ', raw2(1:min(20,end)));
            fprintf('\n');
        end
    end
catch ME
    fprintf('Strategy 3 failed: %s\n\n', ME.message);
end

clear s;
fprintf('\nDetection complete.\n');