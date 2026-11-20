function d = estimate_rbc_diameter(items, max_images)
%ESTIMATE_RBC_DIAMETER Diametro tipico de un RBC (en px) sin usar anotaciones.
%   Sirve para escalar los parametros en datasets sin cajas (Dataset 3).
%   Metodo: Otsu sobre el canal verde, limpieza morfologica y mediana del
%   diametro equivalente de los blobs aislados, convexos y casi redondos
%   (que no toquen el borde). Validado en el Dataset 2: da ~54 px frente a
%   ~51 px de lado medio en las cajas anotadas.
if nargin < 2, max_images = 200; end
n = min(numel(items), max_images);
pick = round(linspace(1, numel(items), n));
diams = [];
for k = pick
    img = imread(items(k).path);
    if size(img, 3) > 3, img = img(:, :, 1:3); end
    if size(img, 3) == 1, img = repmat(img, [1 1 3]); end
    g = cv_gaussian_blur(im2uint8(img(:, :, 2)), 5);
    bw = double(g) <= 255 * graythresh(g);
    bw = cv_morph(bw, true(5), 'close', 1);
    bw = cv_morph(bw, true(5), 'open', 1);
    [H, W] = size(bw);
    st = regionprops(bw, 'Area', 'BoundingBox', 'ConvexArea');
    for j = 1:numel(st)
        bb = st(j).BoundingBox;           % [x y w h] con bordes en .5
        x1 = bb(1) + 0.5; y1 = bb(2) + 0.5; x2 = x1 + bb(3) - 1; y2 = y1 + bb(4) - 1;
        if x1 <= 1 || y1 <= 1 || x2 >= W || y2 >= H || st(j).Area < 100, continue; end
        solidity = st(j).Area / max(st(j).ConvexArea, 1);
        ratio = bb(3) / bb(4);
        if solidity > 0.93 && ratio > 0.8 && ratio < 1.25
            diams(end + 1) = sqrt(4 * st(j).Area / pi); %#ok<AGROW>
        end
    end
end
if isempty(diams), d = NaN; else, d = median(diams); end
end
