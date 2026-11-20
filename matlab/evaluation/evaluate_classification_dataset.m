function [per_image, summary] = evaluate_classification_dataset(items, p, verbose)
%EVALUATE_CLASSIFICATION_DATASET Evaluacion para el Dataset 3 (sin cajas).
%   Cada imagen tiene UNA celula centrada y su clase. Como no hay conteos ni
%   cajas de referencia, se mide si el detector de WBC encuentra la celula
%   del centro:
%     * n_wbc        WBC detectados en la imagen
%     * center_hit   alguna caja WBC contiene el centro de la imagen
%   Lo esperado: 1 WBC en el centro para los leucocitos (Basophil,
%   Eosinophil, Lymphocyte, Monocyte, Neutrophil, PlasmaCell) y 0 para
%   Platelet. Erythroblast (eritrocito nucleado) se reporta aparte: su
%   nucleo se tine igual que el de un WBC.
%   Los RBC se cuentan pero no hay GT para compararlos.
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
    [H, W] = size(res.wbc_mask);
    cx = (W - 1) / 2; cy = (H - 1) / 2;       % centro en coordenadas 0-based
    wb = res.boxes(strcmp(res.labels, 'WBC'), :);
    hit = any(wb(:, 1) <= cx & cx <= wb(:, 1) + wb(:, 3) & wb(:, 2) <= cy & cy <= wb(:, 2) + wb(:, 4));
    r.name = it.name;
    r.class_label = it.class_label;
    r.pred_wbc = res.wbc_count;
    r.center_hit = double(hit);
    r.pred_rbc = res.rbc_count;
    r.seconds = dt;
    if isempty(per_image), per_image = r; else, per_image(end + 1) = r; end %#ok<AGROW>
    if verbose && (mod(k, 50) == 0 || k == n)
        fprintf('   %4d/%d imagenes (%.0f s)\n', k, n, toc(t_all));
    end
end
summary = summarize_classification(per_image);
end

function s = summarize_classification(T)
classes = unique({T.class_label});
leuko = {'Basophil', 'Eosinophil', 'Lymphocyte', 'Monocyte', 'Neutrophil', 'PlasmaCell'};
s.n_images = numel(T);
s.per_class = struct('class_label', {}, 'n', {}, 'frac_ge1', {}, 'frac_eq1', {}, ...
                     'frac_center', {}, 'mean_wbc', {}, 'mean_rbc', {});
for c = 1:numel(classes)
    sel = strcmp({T.class_label}, classes{c});
    w = [T(sel).pred_wbc]; h = [T(sel).center_hit];
    s.per_class(end + 1) = struct('class_label', classes{c}, 'n', nnz(sel), ...
        'frac_ge1', mean(w >= 1), 'frac_eq1', mean(w == 1), 'frac_center', mean(h), ...
        'mean_wbc', mean(w), 'mean_rbc', mean([T(sel).pred_rbc]));
end
isL = ismember({T.class_label}, leuko);
isP = strcmp({T.class_label}, 'Platelet');
s.leuko_detect_rate = mean([T(isL).center_hit]);                       % WBC del centro encontrado
s.leuko_exact_one = mean([T(isL).pred_wbc] == 1 & [T(isL).center_hit] == 1);
s.platelet_false_wbc = mean([T(isP).pred_wbc] >= 1);                  % plaquetas tomadas como WBC
s.seconds_per_image = mean([T.seconds]);
end
