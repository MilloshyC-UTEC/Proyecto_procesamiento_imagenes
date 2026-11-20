function [mask, count, raw_mask, morph_mask] = detect_wbc(clahe_img, p)
%DETECT_WBC Deteccion de globulos blancos (ClassicalCellDetector.detect_wbc).
%   1. Blur gaussiano 7x7 sobre la imagen con CLAHE
%   2. Mascara HSV de los tonos morados (get_hsv_mask)
%   3. Apertura + cierre morfologico (clean_wbc_morphology)
%   4. Filtro por area minima (filter_wbc_by_size)
blurred = cv_gaussian_blur(clahe_img, p.wbc_blur_ksize);
hsv = cv_rgb2hsv8(blurred);
raw_mask = get_hsv_mask(hsv, p.hsv_lower, p.hsv_upper);
morph_mask = clean_wbc_morphology(raw_mask, p);
[mask, count] = filter_wbc_by_size(morph_mask, p.wbc_min_area);
end

function mask = get_hsv_mask(hsv, lower, upper)
% cv2.inRange: lower <= pixel <= upper en los tres canales
mask = true(size(hsv, 1), size(hsv, 2));
for c = 1:3
    mask = mask & hsv(:, :, c) >= lower(c) & hsv(:, :, c) <= upper(c);
end
end

function cleaned = clean_wbc_morphology(mask, p)
% Apertura (quita ruido) y cierre fuerte (rellena huecos del nucleo)
opened  = cv_morph(mask, cv_ellipse_kernel(p.wbc_open_ksize), 'open', p.wbc_open_iter);
cleaned = cv_morph(opened, cv_ellipse_kernel(p.wbc_close_ksize), 'close', p.wbc_close_iter);
end

function [final_mask, count] = filter_wbc_by_size(mask, min_area)
% connectedComponentsWithStats (conectividad 8): se queda con area > min_area
cc = bwconncomp(mask, 8);
areas = cellfun(@numel, cc.PixelIdxList);
keep = find(areas > min_area);
final_mask = false(size(mask));
for k = keep
    final_mask(cc.PixelIdxList{k}) = true;
end
count = numel(keep);
end
