function save_example_figure(item, p, out_path)
%SAVE_EXAMPLE_FIGURE Guarda un panel: original | GT | mascara WBC | watershed | detecciones.
%   GT: verde = RBC, rojo = WBC, cian = plaquetas (como get_annotated_image)
%   Detecciones: verde = RBC, rojo = WBC (como visualize_detections)
img = imread(item.path);
if size(img, 3) > 3, img = img(:, :, 1:3); end
if size(img, 3) == 1, img = repmat(img, [1 1 3]); end
img = im2uint8(img);
res = detect_cells(img, p);

green = uint8([0 255 0]); red = uint8([255 0 0]); cyan = uint8([0 255 255]);
th = max(1, round(2 * size(img, 1) / 480));

gt = img;
if ~isempty(item.gt_boxes)
    gt = draw_boxes(gt, item.gt_boxes(strcmp(item.gt_labels, 'RBC'), :), green, th);
    gt = draw_boxes(gt, item.gt_boxes(strcmp(item.gt_labels, 'WBC'), :), red, th);
    gt = draw_boxes(gt, item.gt_boxes(strcmp(item.gt_labels, 'PLATELETS'), :), cyan, th);
end

wbc = repmat(uint8(res.wbc_mask) * 255, [1 1 3]);

L = double(res.rbc_markers);
L(L <= 1) = 0;
[~, ~, jj] = unique(L(L > 0));
L(L > 0) = jj;
ws = label2rgb(L, jet(max(max(L(:)), 1)), [0 0 0], 'shuffle');
ws(repmat(res.rbc_markers == -1, [1 1 3])) = 255;

det = img;
xyxy = [res.boxes(:, 1:2), res.boxes(:, 1:2) + res.boxes(:, 3:4)];
det = draw_boxes(det, xyxy(strcmp(res.labels, 'RBC'), :), green, th);
det = draw_boxes(det, xyxy(strcmp(res.labels, 'WBC'), :), red, th);

sep = 255 * ones(size(img, 1), 6, 3, 'uint8');
panel = [img, sep, gt, sep, wbc, sep, ws, sep, det];
imwrite(panel, out_path);
end
