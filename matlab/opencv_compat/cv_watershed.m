function markers = cv_watershed(img, markers)
%CV_WATERSHED Watershed por marcadores, mismo algoritmo que cv2.watershed.
%   img      imagen RGB uint8 (H x W x 3)
%   markers  int32 H x W: >0 semillas, 0 = region desconocida
%   Salida   int32 H x W: cada pixel con la etiqueta de su semilla y -1 en
%            las lineas divisorias.
%
%   Por que no se usa watershed() de MATLAB: ese es el watershed clasico
%   sobre una imagen de relieve, no acepta marcadores. OpenCV hace una
%   inundacion de Meyer con 256 colas de prioridad, donde la prioridad de un
%   pixel es max_c |I_c(p) - I_c(vecino)|. Igual que OpenCV, el borde de 1 px
%   de la imagen se marca como -1. Se verifico pixel a pixel contra
%   cv2.watershed.
WSHED = int32(-1);
INQ = int32(-2);
[H, W, ~] = size(img);
N = H * W;
m = int32(markers(:));
m(m < 0) = 0;

% Borde de la imagen = linea divisoria (como OpenCV)
border = false(H, W);
border([1 H], :) = true;
border(:, [1 W]) = true;
m(border(:)) = WSHED;

% Diferencia de color con cada vecino, precalculada:
% D(p, d) = max_c |I_c(p) - I_c(p + offs(d))|, d = izquierda, derecha, arriba, abajo
offs = [-H, H, -1, 1];
I = reshape(double(img), N, 3);
D = zeros(N, 4);
inner = find(~border(:));
for d = 1:4
    D(inner, d) = max(abs(I(inner, :) - I(inner + offs(d), :)), [], 2);
end

% Colas FIFO por nivel (0..255) como listas enlazadas: cada pixel entra a lo
% mas una vez, asi que su indice sirve de nodo.
nxt = zeros(N, 1);
head = zeros(256, 1);
tail = zeros(256, 1);

% Fase inicial (vectorizada): pixeles desconocidos con algun vecino semilla.
% Prioridad = minima diferencia con los vecinos ya etiquetados. Se encolan en
% orden fila por fila, como OpenCV (importa para desempatar).
cand = inner(m(inner) == 0);
lev = 256 * ones(numel(cand), 1);
for d = 1:4
    lab_n = m(cand + offs(d)) > 0;
    lev(lab_n) = min(lev(lab_n), D(cand(lab_n), d));
end
keep = lev < 256;
cand = cand(keep);
lev = lev(keep) + 1;                              % nivel 1-based
[r, c] = ind2sub([H W], cand);
[~, order] = sortrows([lev, r, c]);               % por nivel y luego fila-columna
cand = cand(order);
lev = lev(order);
if isempty(cand)
    markers = reshape(m, H, W);
    return;
end
m(cand) = INQ;
same_next = [lev(2:end) == lev(1:end - 1); false];
nxt(cand(same_next)) = cand([false; same_next(1:end - 1)]);
first = [true; lev(2:end) ~= lev(1:end - 1)];
last = [lev(2:end) ~= lev(1:end - 1); true];
head(lev(first)) = cand(first);
tail(lev(last)) = cand(last);
active = lev(1);

% Inundacion
while true
    if head(active) == 0
        k = find(head(active + 1:end) > 0, 1);
        if isempty(k), break; end
        active = active + k;
    end
    p = head(active);
    head(active) = nxt(p);
    if head(active) == 0, tail(active) = 0; end

    nb = p + offs;
    t = m(nb);
    pos = t(t > 0);
    if isempty(pos)
        lab = int32(0);
    elseif all(pos == pos(1))
        lab = pos(1);
    else
        lab = WSHED;
    end
    m(p) = lab;
    if lab == WSHED, continue; end

    for d = 1:4
        if t(d) == 0
            n = nb(d);
            lv = D(p, d) + 1;
            nxt(n) = 0;
            if tail(lv) == 0, head(lv) = n; else, nxt(tail(lv)) = n; end
            tail(lv) = n;
            m(n) = INQ;
            if lv < active, active = lv; end
        end
    end
end
markers = reshape(m, H, W);
end
