function res = detect_cells(img, p)
%DETECT_CELLS Pipeline completo (ClassicalCellDetector.run_pipeline del notebook).
%   img  imagen RGB uint8 (si viene en gris o con alfa se corrige)
%   p    parametros (default_params / scale_params)
%   res  struct con:
%        wbc_count, rbc_count  conteos
%        wbc_mask              mascara logica de WBC
%        rbc_markers           etiquetas del watershed (-1 bordes, 1 fondo)
%        boxes                 N x 4 [x y w h] (0-based, como OpenCV)
%        labels                N x 1 cellstr ('RBC' / 'WBC')
if nargin < 2, p = default_params(); end
img = to_rgb_uint8(img);

clahe_img = apply_clahe(img, p);
[wbc_mask, wbc_count] = detect_wbc(clahe_img, p);
[rbc_markers, rbc_count] = get_rbc_watershed(img, wbc_mask, p);
[boxes, labels] = markers_to_detections(rbc_markers, wbc_mask, p);

res.wbc_count = wbc_count;
res.rbc_count = rbc_count;
res.wbc_mask = wbc_mask;
res.rbc_markers = rbc_markers;
res.boxes = boxes;
res.labels = labels;
end

function img = to_rgb_uint8(img)
if ~isa(img, 'uint8')
    img = im2uint8(img);
end
if size(img, 3) == 1
    img = repmat(img, [1 1 3]);
elseif size(img, 3) > 3
    img = img(:, :, 1:3);
end
end
