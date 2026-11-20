function s = median_rbc_side(items)
%MEDIAN_RBC_SIDE Mediana de sqrt(ancho*alto) de las cajas RBC anotadas (px).
%   En BCCD da ~102 px; se usa como referencia para escalar los parametros.
sides = [];
for k = 1:numel(items)
    b = items(k).gt_boxes(strcmp(items(k).gt_labels, 'RBC'), :);
    sides = [sides; sqrt((b(:, 3) - b(:, 1)) .* (b(:, 4) - b(:, 2)))]; %#ok<AGROW>
end
s = median(sides);
end
