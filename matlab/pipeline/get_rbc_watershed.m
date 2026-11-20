function [new_markers, count, steps] = get_rbc_watershed(img, wbc_mask, p)
%GET_RBC_WATERSHED Segmentacion y conteo de globulos rojos (get_rbc_watershed).
%   Canal G + CLAHE -> blur -> umbral adaptativo -> quitar WBC ->
%   fondo seguro -> frente seguro (transformada de distancia) -> watershed
%   por marcadores -> filtro por tamano y estimacion de grupos.
g = cv_clahe(img(:, :, 2), p.clahe_clip, p.clahe_tiles);   % rbc_extract_and_clahe
g = cv_gaussian_blur(g, p.rbc_blur_ksize);                 % rbc_blurring_phase
thresh = rbc_apply_thresholding(g, p);
thresh = rbc_remove_wbc_mask(wbc_mask, thresh, p);
[sure_bg, closing] = rbc_get_sure_bg(thresh, p);
[sure_fg, unknown] = rbc_get_sure_foreground(closing, sure_bg, p);
markers = rbc_apply_watershed(sure_fg, unknown, img);
[new_markers, count] = rbc_size_filtering(markers, p);
if nargout > 2
    steps = struct('green_clahe_blur', g, 'thresh', thresh, 'sure_bg', sure_bg, ...
                   'sure_fg', sure_fg, 'unknown', unknown, 'markers', markers);
end
end

function bw = rbc_apply_thresholding(g, p)
% cv2.adaptiveThreshold(g, 255, ADAPTIVE_THRESH_GAUSSIAN_C, THRESH_BINARY_INV, block, C)
% Umbral local = media gaussiana (redondeada a uint8, borde replicate) - C.
% Con THRESH_BINARY_INV el pixel es blanco si g <= media - C.
k = p.adapt_block;
gk = cv_gaussian_kernel(k, 0);
r = (k - 1) / 2;
P = cv_pad(double(g), r, r, r, r, 'replicate');
mu = round(conv2(gk(:), gk, P, 'valid'));
bw = double(g) - mu <= -p.adapt_C;
end

function thresh = rbc_remove_wbc_mask(wbc_mask, thresh, p)
% Dilata la mascara WBC (5x5, 2 iteraciones) y la borra del umbral de RBC
wbc_dil = cv_morph(wbc_mask, true(p.wbc_remove_ksize), 'dilate', p.wbc_remove_iter);
thresh(wbc_dil) = false;
end

function [sure_bg, closing] = rbc_get_sure_bg(thresh, p)
K = true(p.bg_ksize);
opening = cv_morph(thresh, K, 'open', p.open_iter);
closing = cv_morph(opening, K, 'close', p.close_iter);
sure_bg = cv_morph(closing, K, 'dilate', p.bg_dilate_iter);
end

function [sure_fg, unknown] = rbc_get_sure_foreground(closing, sure_bg, p)
% cv2.distanceTransform(closing, DIST_L2, 5) -> aqui distancia euclidiana exacta
dist = bwdist(~closing);
dist = cv_gaussian_blur(dist, p.dist_blur_ksize);
sure_fg = dist > p.fg_ratio * max(dist(:));
unknown = sure_bg & ~sure_fg;               % cv2.subtract(sure_bg, sure_fg)
end

function markers = rbc_apply_watershed(sure_fg, unknown, img)
markers = int32(bwlabel(sure_fg, 8)) + 1;   % fondo = 1, celulas = 2..N+1
markers(unknown) = 0;                       % region desconocida = 0
markers = cv_watershed(img, markers);       % lineas divisorias = -1
end

function [new_markers, count] = rbc_size_filtering(markers, p)
A = p.typical_rbc_area;
min_t = A * p.min_area_ratio;
clump_t = A * p.clump_ratio;
new_markers = markers;
count = 0;
vals = double(markers(markers > 1));
if isempty(vals), return; end
[labels, ~, j] = unique(vals);
areas = accumarray(j, 1);
small = labels(areas < min_t);
for k = 1:numel(labels)
    a = areas(k);
    if a < min_t
        continue;
    elseif a > clump_t
        count = count + round_half_even(a / A);   % int(round(x)) de Python
    else
        count = count + 1;
    end
end
if ~isempty(small)
    new_markers(ismember(double(markers), small)) = 1;
end
end

function r = round_half_even(x)
r = round(x);
if abs(x - fix(x)) == 0.5
    r = 2 * round(x / 2);
end
end
