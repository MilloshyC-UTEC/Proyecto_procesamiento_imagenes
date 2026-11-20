function [boxes, labels] = markers_to_detections(markers, wbc_mask, p)
%MARKERS_TO_DETECTIONS Convierte la segmentacion en cajas [x y w h].
%   Coordenadas 0-based como cv2.boundingRect, con el mismo padding que el
%   notebook (p.pad para RBC y p.pad + p.wbc_pad_extra para WBC).
%   Una region marcada como "grupo" (clump) sigue siendo una sola caja.
[H, W] = size(markers);
boxes = zeros(0, 4);
labels = {};

% RBC: una caja por etiqueta > 1 del watershed
idx = find(markers > 1);
if ~isempty(idx)
    [r, c] = ind2sub([H W], idx);
    [~, ~, j] = unique(double(markers(idx)));     % orden ascendente como np.unique
    rmin = accumarray(j, r, [], @min); rmax = accumarray(j, r, [], @max);
    cmin = accumarray(j, c, [], @min); cmax = accumarray(j, c, [], @max);
    for k = 1:numel(rmin)
        b = padded_box(cmin(k) - 1, rmin(k) - 1, cmax(k) - cmin(k) + 1, ...
                       rmax(k) - rmin(k) + 1, p.pad, W, H);
        boxes(end + 1, :) = b; %#ok<AGROW>
        labels{end + 1, 1} = 'RBC'; %#ok<AGROW>
    end
end

% WBC: una caja por componente conexa de la mascara
cc = bwconncomp(wbc_mask, 8);
for k = 1:cc.NumObjects
    [r, c] = ind2sub([H W], cc.PixelIdxList{k});
    b = padded_box(min(c) - 1, min(r) - 1, max(c) - min(c) + 1, max(r) - min(r) + 1, ...
                   p.pad + p.wbc_pad_extra, W, H);
    boxes(end + 1, :) = b; %#ok<AGROW>
    labels{end + 1, 1} = 'WBC'; %#ok<AGROW>
end
end

function b = padded_box(x, y, w, h, pad, max_w, max_h)
% get_padded_box del notebook (se copia tal cual, incluido el recorte)
nx = max(0, x - pad);
ny = max(0, y - pad);
nw = min(max_w - nx, w + 2 * pad);
nh = min(max_h - ny, h + 2 * pad);
b = [nx ny nw nh];
end
