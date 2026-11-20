function row = summary_row(dataset, config, split, p, S)
%SUMMARY_ROW Fila de la tabla resumen (orden de columnas fijo).
row.dataset = dataset;
row.config = config;
row.split = split;
row.scale = p.scale;
row.n_images = S.n_images;
row.wbc_exact_acc = S.wbc_exact_acc;
row.wbc_mae = S.wbc_mae;
row.wbc_total_gt = S.wbc_total_gt;
row.wbc_total_pred = S.wbc_total_pred;
row.rbc_mae = S.rbc_mae;
row.rbc_bias = S.rbc_bias;
row.rbc_mape = S.rbc_mape;
row.rbc_total_gt = S.rbc_total_gt;
row.rbc_total_pred = S.rbc_total_pred;
row.rbc_mean_iou = S.rbc_mean_iou;
row.wbc_mean_iou = S.wbc_mean_iou;
row.rbc_precision50 = S.rbc_precision50;
row.rbc_recall50 = S.rbc_recall50;
row.rbc_f1_50 = S.rbc_f1_50;
row.wbc_precision50 = S.wbc_precision50;
row.wbc_recall50 = S.wbc_recall50;
row.wbc_f1_50 = S.wbc_f1_50;
row.seconds_per_image = S.seconds_per_image;
end
