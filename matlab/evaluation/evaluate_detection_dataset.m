function [per_image, summary] = evaluate_detection_dataset(items, p, verbose)
%EVALUATE_DETECTION_DATASET Corre detect_cells sobre cada imagen y la compara con el GT.
%   Para datasets con cajas (Dataset 1 y 2). Devuelve:
%   per_image  struct array (una fila por imagen)
%   summary    struct con metricas de conteo y deteccion
if nargin < 3, verbose = true; end
n = numel(items);
per_image = [];
t_all = tic;
for k = 1:n
    it = items(k);
    img = imread(it.path);
    t0 = tic;
    res = detect_cells(img, p);
    dt = toc(t0);
    pred_xyxy = [res.boxes(:, 1:2), res.boxes(:, 1:2) + res.boxes(:, 3:4)];
    r.name = it.name;
    r.split = it.split;
    r.gt_wbc = sum(strcmp(it.gt_labels, 'WBC'));
    r.pred_wbc = res.wbc_count;
    r.gt_rbc = sum(strcmp(it.gt_labels, 'RBC'));
    r.pred_rbc = res.rbc_count;
    for cls = {'RBC', 'WBC'}
        g = it.gt_boxes(strcmp(it.gt_labels, cls{1}), :);
        q = pred_xyxy(strcmp(res.labels, cls{1}), :);
        [tp, fp, fn] = match_detections(g, q, 0.5);
        r.(['iou_' lower(cls{1})]) = compute_image_iou(g, q);
        r.(['tp_' lower(cls{1})]) = tp;
        r.(['fp_' lower(cls{1})]) = fp;
        r.(['fn_' lower(cls{1})]) = fn;
    end
    r.seconds = dt;
    if isempty(per_image), per_image = r; else, per_image(end + 1) = r; end %#ok<AGROW>
    if verbose && (mod(k, 25) == 0 || k == n)
        fprintf('   %4d/%d imagenes (%.0f s)\n', k, n, toc(t_all));
    end
end
summary = split_summary(per_image);
end

