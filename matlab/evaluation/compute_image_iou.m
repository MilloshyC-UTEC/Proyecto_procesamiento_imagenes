function m = compute_image_iou(gt_boxes, pred_boxes)
%COMPUTE_IMAGE_IOU Promedio, sobre las cajas GT, del mejor IoU con alguna prediccion.
%   Es la funcion compute_image_iou del notebook (alli estaba definida pero
%   no se usaba). Cajas en formato [x1 y1 x2 y2].
if isempty(gt_boxes)
    m = double(isempty(pred_boxes));
    return;
end
if isempty(pred_boxes)
    m = 0;
    return;
end
best = zeros(size(gt_boxes, 1), 1);
for i = 1:size(gt_boxes, 1)
    for j = 1:size(pred_boxes, 1)
        best(i) = max(best(i), compute_iou(gt_boxes(i, :), pred_boxes(j, :)));
    end
end
m = mean(best);
end
