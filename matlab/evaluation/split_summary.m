function S = split_summary(T)
%SPLIT_SUMMARY Recalcula el resumen de deteccion para un subconjunto de filas.
gw = [T.gt_wbc]; pw = [T.pred_wbc]; gr = [T.gt_rbc]; pr = [T.pred_rbc];
S.n_images = numel(T);
S.wbc_exact_acc = mean(gw == pw);
S.wbc_mae = mean(abs(pw - gw));
S.rbc_mae = mean(abs(pr - gr));
S.rbc_bias = mean(pr - gr);
S.rbc_mape = 100 * mean(abs(pr(gr > 0) - gr(gr > 0)) ./ gr(gr > 0));
S.rbc_total_gt = sum(gr); S.rbc_total_pred = sum(pr);
S.wbc_total_gt = sum(gw); S.wbc_total_pred = sum(pw);
S.rbc_mean_iou = mean([T.iou_rbc]);
S.wbc_mean_iou = mean([T.iou_wbc]);
for cls = {'rbc', 'wbc'}
    tp = sum([T.(['tp_' cls{1}])]); fp = sum([T.(['fp_' cls{1}])]); fn = sum([T.(['fn_' cls{1}])]);
    prec = tp / max(tp + fp, 1); rec = tp / max(tp + fn, 1);
    S.([cls{1} '_precision50']) = prec;
    S.([cls{1} '_recall50']) = rec;
    S.([cls{1} '_f1_50']) = 2 * prec * rec / max(prec + rec, eps);
end
S.seconds_per_image = mean([T.seconds]);
end
