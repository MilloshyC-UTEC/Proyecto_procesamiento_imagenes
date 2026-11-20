function [tp, fp, fn] = match_detections(gt_boxes, pred_boxes, thr)
%MATCH_DETECTIONS Emparejamiento voraz 1 a 1 por IoU >= thr (por defecto 0.5).
%   Agregado para tener precision/recall; el notebook no lo tenia.
%   Cajas en formato [x1 y1 x2 y2].
if nargin < 3, thr = 0.5; end
ng = size(gt_boxes, 1); np_ = size(pred_boxes, 1);
if ng == 0 || np_ == 0
    tp = 0; fp = np_; fn = ng;
    return;
end
M = zeros(ng, np_);
for i = 1:ng
    for j = 1:np_
        M(i, j) = compute_iou(gt_boxes(i, :), pred_boxes(j, :));
    end
end
tp = 0;
while true
    [v, k] = max(M(:));
    if isempty(v) || v < thr, break; end
    [i, j] = ind2sub(size(M), k);
    tp = tp + 1;
    M(i, :) = -1;
    M(:, j) = -1;
end
fp = np_ - tp;
fn = ng - tp;
end
