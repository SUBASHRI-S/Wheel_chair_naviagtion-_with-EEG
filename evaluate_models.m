function results = evaluate_models(models, X_test, Y_test, class_names)
%EVALUATE_MODELS  Evaluate all trained models and print full classification report.

model_names = {'Cubic SVM', 'Bagging Tree', 'Neural Net', ...
               'CNN',        'Random Forest', 'Grad. Boost'};
n_models  = numel(model_names);
n_classes = numel(class_names);
n_test    = numel(Y_test);

acc_list  = zeros(1, n_models);
prec_list = zeros(1, n_models);
rec_list  = zeros(1, n_models);
f1_list   = zeros(1, n_models);
Y_preds   = cell(1, n_models);
CMs       = cell(1, n_models);

%% ── Predict with all models ───────────────────────────────
for m = 1:n_models
    fprintf('  Evaluating %-18s... ', model_names{m});
    try
        Y_pred = predict_one(models, m, X_test, Y_test);
    catch ME
        warning('Prediction failed for %s: %s', model_names{m}, ME.message);
        Y_pred = ones(n_test, 1);
    end
    Y_pred     = double(Y_pred(:));
    Y_pred     = max(1, min(n_classes, round(Y_pred)));
    Y_preds{m} = Y_pred;

    CM     = confusionmat(Y_test, Y_pred, 'Order', 1:n_classes);
    CMs{m} = CM;

    prec_k = zeros(n_classes, 1);
    rec_k  = zeros(n_classes, 1);
    f1_k   = zeros(n_classes, 1);
    for k = 1:n_classes
        TP = CM(k,k);
        FP = sum(CM(:,k)) - TP;
        FN = sum(CM(k,:)) - TP;
        prec_k(k) = TP / max(TP+FP, 1);
        rec_k(k)  = TP / max(TP+FN, 1);
        denom     = prec_k(k) + rec_k(k);
        f1_k(k)   = 2 * prec_k(k) * rec_k(k) / max(denom, eps);
    end

    acc_list(m)  = sum(diag(CM)) / n_test;
    prec_list(m) = mean(prec_k);
    rec_list(m)  = mean(rec_k);
    f1_list(m)   = mean(f1_k);
    fprintf('Accuracy: %.2f%%\n', acc_list(m)*100);
end

%% ── Best model ────────────────────────────────────────────
[best_acc, best_idx] = max(acc_list);

%% ── Summary table ─────────────────────────────────────────
fprintf('\n%s\n', repmat('=',1,68));
fprintf('  MODEL COMPARISON SUMMARY\n');
fprintf('%s\n', repmat('=',1,68));
fprintf('  %-20s  %8s  %9s  %8s  %8s\n', ...
        'Model','Accuracy','Precision','Recall','F1-Score');
fprintf('  %s\n', repmat('-',1,62));
for m = 1:n_models
    marker = '';
    if m == best_idx, marker = ' ★'; end
    fprintf('  %-20s  %7.2f%%  %8.2f%%  %7.2f%%  %7.2f%%%s\n', ...
        model_names{m}, acc_list(m)*100, prec_list(m)*100, ...
        rec_list(m)*100, f1_list(m)*100, marker);
end
fprintf('%s\n', repmat('=',1,68));
fprintf('  ★ Best model: %s  |  Accuracy: %.2f%%\n', ...
        model_names{best_idx}, best_acc*100);
fprintf('%s\n\n', repmat('=',1,68));

%% ── Ranking table ─────────────────────────────────────────
fprintf('  RANKING\n');
fprintf('  %-6s  %-20s  %s\n', 'Rank','Model','Accuracy');
fprintf('  %s\n', repmat('-',1,40));
[sorted_acc, sort_idx] = sort(acc_list, 'descend');
for r = 1:n_models
    fprintf('  #%-5d  %-20s  %.2f%%\n', r, model_names{sort_idx(r)}, sorted_acc(r)*100);
end
fprintf('\n');

%% ── Per-class classification report for BEST model ───────
print_classification_report(Y_test, Y_preds{best_idx}, ...
    class_names, model_names{best_idx}, CMs{best_idx});

%% ── Per-class report for ALL models ──────────────────────
for m = 1:n_models
    if m ~= best_idx
        print_classification_report(Y_test, Y_preds{m}, ...
            class_names, model_names{m}, CMs{m});
    end
end

%% ── Plots ─────────────────────────────────────────────────
plot_confusion_matrices(Y_test, Y_preds, model_names, class_names, n_models);
plot_accuracy_bar(acc_list, prec_list, rec_list, f1_list, model_names, n_models);
plot_per_class_metrics(CMs, model_names, class_names, n_models, n_classes);

%% ── Pack results ──────────────────────────────────────────
results.acc_list    = acc_list;
results.prec_list   = prec_list;
results.rec_list    = rec_list;
results.f1_list     = f1_list;
results.model_names = model_names;
results.CMs         = CMs;
results.best_idx    = best_idx;
results.best_name   = model_names{best_idx};
results.best_acc    = best_acc;

switch best_idx
    case 1, results.best_model = models.m1;
    case 2, results.best_model = models.m2;
    case 3, results.best_model = models.m3;
    case 4, results.best_model = models.m4;
    case 5, results.best_model = models.m5;
    case 6, results.best_model = models.m6;
end
results.best_model_idx = best_idx;
end

%% ════════════════════════════════════════════════════════════
%%  CLASSIFICATION REPORT (per-class breakdown)
%% ════════════════════════════════════════════════════════════
function print_classification_report(Y_test, Y_pred, class_names, model_name, CM)
n_classes = numel(class_names);
n_test    = numel(Y_test);

fprintf('%s\n', repmat('-',1,68));
fprintf('  CLASSIFICATION REPORT — %s\n', upper(model_name));
fprintf('%s\n', repmat('-',1,68));
fprintf('  %-10s  %9s  %9s  %9s  %9s\n', ...
        'Class','Precision','Recall','F1-Score','Support');
fprintf('  %s\n', repmat('-',1,55));

prec_all = zeros(n_classes,1);
rec_all  = zeros(n_classes,1);
f1_all   = zeros(n_classes,1);
sup_all  = zeros(n_classes,1);

for k = 1:n_classes
    TP  = CM(k,k);
    FP  = sum(CM(:,k)) - TP;
    FN  = sum(CM(k,:)) - TP;
    prec = TP / max(TP+FP, 1);
    rec  = TP / max(TP+FN, 1);
    f1   = 2*prec*rec / max(prec+rec, eps);
    sup  = sum(Y_test == k);

    prec_all(k) = prec;
    rec_all(k)  = rec;
    f1_all(k)   = f1;
    sup_all(k)  = sup;

    fprintf('  %-10s  %8.2f%%  %8.2f%%  %8.2f%%  %9d\n', ...
        class_names{k}, prec*100, rec*100, f1*100, sup);
end

fprintf('  %s\n', repmat('-',1,55));

% Macro average
fprintf('  %-10s  %8.2f%%  %8.2f%%  %8.2f%%  %9d\n', ...
    'Macro avg', mean(prec_all)*100, mean(rec_all)*100, mean(f1_all)*100, n_test);

% Weighted average
w_prec = sum(prec_all .* sup_all) / n_test;
w_rec  = sum(rec_all  .* sup_all) / n_test;
w_f1   = sum(f1_all   .* sup_all) / n_test;
fprintf('  %-10s  %8.2f%%  %8.2f%%  %8.2f%%  %9d\n', ...
    'Weighted', w_prec*100, w_rec*100, w_f1*100, n_test);

% Overall accuracy
acc = sum(diag(CM)) / n_test;
fprintf('\n  Overall Accuracy: %.2f%%   (%d / %d correct)\n\n', ...
    acc*100, round(acc*n_test), n_test);
end

%% ════════════════════════════════════════════════════════════
%%  PLOT: Confusion matrices for all models
%% ════════════════════════════════════════════════════════════
function plot_confusion_matrices(Y_test, Y_preds, model_names, class_names, n_models)
try
    figure('Name','Confusion Matrices — All Models', ...
           'NumberTitle','off','Position',[30 30 1400 750]);
    for m = 1:n_models
        subplot(2, 3, m);
        confusionchart(Y_test, Y_preds{m}, ...
            'RowSummary',    'row-normalized', ...
            'ColumnSummary', 'column-normalized', ...
            'Title',          model_names{m});
    end
    sgtitle('Confusion Matrices — All Models', 'FontSize', 13, 'FontWeight','bold');
catch ME
    warning('Confusion matrix plot failed: %s', ME.message);
end
end

%% ════════════════════════════════════════════════════════════
%%  PLOT: Grouped bar — Accuracy / Precision / Recall / F1
%% ════════════════════════════════════════════════════════════
function plot_accuracy_bar(acc_list, prec_list, rec_list, f1_list, model_names, n_models)
try
    figure('Name','Model Performance Comparison', ...
           'NumberTitle','off','Position',[30 820 1100 450]);

    metrics = [acc_list; prec_list; rec_list; f1_list]' * 100;
    b = bar(metrics, 'grouped');
    colors = {[0.2 0.6 0.9], [0.2 0.8 0.4], [1.0 0.6 0.1], [0.9 0.2 0.3]};
    for i = 1:4
        b(i).FaceColor = colors{i};
    end

    set(gca, 'XTickLabel', model_names, 'XTickLabelRotation', 15, 'FontSize', 9);
    ylabel('Score (%)');
    title('Model Performance: Accuracy / Precision / Recall / F1', ...
          'FontWeight','bold');
    legend({'Accuracy','Precision','Recall','F1-Score'}, 'Location','southeast');
    ylim([0 110]);
    grid on; grid minor;

    % Label best accuracy bar
    [~, best_idx] = max(acc_list);
    text(best_idx - 0.3, acc_list(best_idx)*100 + 1.5, ...
         sprintf('★ %.1f%%', acc_list(best_idx)*100), ...
         'FontSize', 9, 'FontWeight','bold', 'Color',[0 0 0.6]);
catch ME
    warning('Accuracy bar plot failed: %s', ME.message);
end
end

%% ════════════════════════════════════════════════════════════
%%  PLOT: Per-class F1 heatmap across all models
%% ════════════════════════════════════════════════════════════
function plot_per_class_metrics(CMs, model_names, class_names, n_models, n_classes)
try
    f1_matrix = zeros(n_models, n_classes);
    for m = 1:n_models
        CM = CMs{m};
        for k = 1:n_classes
            TP = CM(k,k);
            FP = sum(CM(:,k)) - TP;
            FN = sum(CM(k,:)) - TP;
            prec = TP / max(TP+FP, 1);
            rec  = TP / max(TP+FN, 1);
            f1_matrix(m,k) = 2*prec*rec / max(prec+rec, eps);
        end
    end

    figure('Name','Per-Class F1 Score Heatmap', ...
           'NumberTitle','off','Position',[30 1330 700 320]);
    imagesc(f1_matrix * 100);
    colormap(hot);
    colorbar;
    clim([0 100]);
    set(gca, 'XTick', 1:n_classes,  'XTickLabel', class_names, ...
             'YTick', 1:n_models,   'YTickLabel', model_names, ...
             'FontSize', 10);
    title('Per-Class F1 Score (%) — All Models', 'FontWeight','bold');
    xlabel('Class'); ylabel('Model');

    % Annotate cells
    for m = 1:n_models
        for k = 1:n_classes
            text(k, m, sprintf('%.1f', f1_matrix(m,k)*100), ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','middle', ...
                'FontSize', 9, 'FontWeight','bold', 'Color','white');
        end
    end
catch ME
    warning('Per-class heatmap failed: %s', ME.message);
end
end

%% ════════════════════════════════════════════════════════════
%%  HELPER: dispatch prediction per model type
%% ════════════════════════════════════════════════════════════
function Y_pred = predict_one(models, m, X_test, ~)
switch m
    case 1  % Cubic SVM
        Y_pred = predict(models.m1, X_test);

    case 2  % Bagging
        Y_pred = predict(models.m2, X_test);

    case 3  % patternnet
        out = models.m3(full(X_test'));
        [~, Y_pred] = max(out, [], 1);
        Y_pred = Y_pred';

    case 4  % CNN or fallback tree
        if isa(models.m4, 'DAGNetwork') || isa(models.m4, 'SeriesNetwork')
            n_feat = size(X_test, 2);
            X_cnn  = reshape(X_test', [n_feat, 1, 1, size(X_test,1)]);
            Y_cat  = classify(models.m4, X_cnn);
            Y_pred = double(Y_cat);
        else
            Y_pred = predict(models.m4, X_test);
        end

    case 5  % TreeBagger
        Y_cell = predict(models.m5, X_test);
        Y_pred = cellfun(@str2double, Y_cell);

    case 6  % Gradient Boosting
        Y_pred = predict(models.m6, X_test);

    otherwise
        error('Unknown model index: %d', m);
end
Y_pred = double(Y_pred(:));
end