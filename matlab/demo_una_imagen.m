%% DEMO_UNA_IMAGEN
% Muestra paso a paso el pipeline sobre una imagen, en el mismo orden que
% el notebook (sirve para el informe / la presentacion).
% Cambia DATASET y IDX para ver otras imagenes.

clear; clc; close all;
here = fileparts(mfilename('fullpath'));
repo = fileparts(here);
addpath(genpath(here));
if exist('OCTAVE_VERSION', 'builtin'), pkg load image; end

DATASET = 1;     % 1 = BCCD, 2 = Blood Cell Detection, 3 = blood_dataset (muestra)
IDX = 1;         % indice de la imagen dentro del dataset

p = default_params();
switch DATASET
    case 1
        items = load_bccd_supervisely(fullfile(repo, 'bccd-blood-cell-count-and-detection-dataset'));
    case 2
        items = load_bcd_csv(fullfile(repo, 'blood-cell-detection-dataset'));
        p = scale_params(p, 0.479, 'adaptado');          % escala que reporta run_all_datasets
        p.hsv_lower = [79 77 85]; p.hsv_upper = [151 235 212];
    case 3
        items = load_pbc_sample(fullfile(repo, 'blood_dataset_sample'));
        p = scale_params(p, 0.67, 'adaptado');
end
it = items(IDX);
img = imread(it.path);
if size(img, 3) > 3, img = img(:, :, 1:3); end
fprintf('Imagen: %s (%s)\n', it.name, p.name);

% --- Ground truth ---
figure('Name', 'Entrada');
subplot(1, 3, 1); imshow(img); title('Imagen original');
subplot(1, 3, 2); bar(imhist(rgb2gray(img)), 1, 'k'); xlim([0 256]); title('Histograma');
gt = img;
if ~isempty(it.gt_boxes)
    gt = draw_boxes(gt, it.gt_boxes(strcmp(it.gt_labels, 'RBC'), :), uint8([0 255 0]), 2);
    gt = draw_boxes(gt, it.gt_boxes(strcmp(it.gt_labels, 'WBC'), :), uint8([255 0 0]), 2);
    gt = draw_boxes(gt, it.gt_boxes(strcmp(it.gt_labels, 'PLATELETS'), :), uint8([0 255 255]), 2);
    fprintf('GT -> RBC: %d, WBC: %d\n', sum(strcmp(it.gt_labels, 'RBC')), sum(strcmp(it.gt_labels, 'WBC')));
else
    fprintf('Clase: %s (sin cajas)\n', it.class_label);
end
subplot(1, 3, 3); imshow(gt); title('Anotaciones');

% --- WBC ---
clahe_img = apply_clahe(img, p);
[wbc_mask, wbc_count, raw_mask, morph_mask] = detect_wbc(clahe_img, p);
figure('Name', 'WBC');
subplot(2, 3, 1); imshow(clahe_img); title('CLAHE en canal L (LAB)');
subplot(2, 3, 2); bar(imhist(rgb2gray(clahe_img)), 1, 'k'); xlim([0 256]); title('Histograma con CLAHE');
subplot(2, 3, 3); imshow(cv_gaussian_blur(clahe_img, p.wbc_blur_ksize)); title('CLAHE + blur 7x7');
subplot(2, 3, 4); imshow(raw_mask); title('Mascara HSV (morado)');
subplot(2, 3, 5); imshow(morph_mask); title('Apertura + cierre');
subplot(2, 3, 6); imshow(wbc_mask); title(sprintf('Filtro por area -> %d WBC', wbc_count));

% --- RBC ---
[rbc_markers, rbc_count, st] = get_rbc_watershed(img, wbc_mask, p);
figure('Name', 'RBC');
subplot(2, 3, 1); imshow(st.green_clahe_blur); title('Canal G + CLAHE + blur');
subplot(2, 3, 2); imshow(st.thresh); title('Umbral adaptativo (sin WBC)');
subplot(2, 3, 3); imshow(st.sure_bg); title('Fondo seguro');
subplot(2, 3, 4); imshow(st.sure_fg); title('Frente seguro (distancia)');
subplot(2, 3, 5); imshow(st.unknown); title('Region desconocida');
L = double(rbc_markers); L(L <= 1) = 0;
subplot(2, 3, 6); imshow(label2rgb(L, 'jet', 'k', 'shuffle')); title(sprintf('Watershed -> %d RBC', rbc_count));

% --- Resultado final ---
[boxes, labels] = markers_to_detections(rbc_markers, wbc_mask, p);
xyxy = [boxes(:, 1:2), boxes(:, 1:2) + boxes(:, 3:4)];
det = draw_boxes(img, xyxy(strcmp(labels, 'RBC'), :), uint8([0 255 0]), 2);
det = draw_boxes(det, xyxy(strcmp(labels, 'WBC'), :), uint8([255 0 0]), 2);
figure('Name', 'Resultado');
subplot(1, 2, 1); imshow(gt); title('Ground truth');
subplot(1, 2, 2); imshow(det); title(sprintf('Pipeline: WBC = %d, RBC = %d', wbc_count, rbc_count));
fprintf('Pipeline -> WBC: %d, RBC: %d\n', wbc_count, rbc_count);
