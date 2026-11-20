function J = cv_clahe(I, clipLimit, tiles)
%CV_CLAHE Reimplementacion de cv2.createCLAHE(clipLimit, tileGridSize).apply.
%   I         imagen uint8 de un canal
%   clipLimit clip limit de OpenCV (3.0 en el notebook)
%   tiles     [tilesX tilesY] (tileGridSize de OpenCV, [8 8] en el notebook)
%
%   adapthisteq de MATLAB usa otra convencion de clip limit y otra
%   interpolacion, por eso se reproduce el algoritmo de OpenCV tal cual.
if nargin < 2, clipLimit = 3.0; end
if nargin < 3, tiles = [8 8]; end
assert(isa(I, 'uint8') && ismatrix(I), 'cv_clahe espera una imagen uint8 de un canal');
tx = tiles(1); ty = tiles(2);
[H, W] = size(I);

% OpenCV hace padding (reflect101) solo si la imagen no es divisible por la
% grilla, y en ese caso agrega (tiles - mod) en AMBOS ejes.
if mod(W, tx) == 0 && mod(H, ty) == 0
    S = I;
else
    S = cv_pad(I, 0, ty - mod(H, ty), 0, tx - mod(W, tx), 'reflect101');
end
th = size(S, 1) / ty;  tw = size(S, 2) / tx;
tileArea = tw * th;

if clipLimit > 0
    clip = max(1, floor(clipLimit * tileArea / 256));
else
    clip = Inf;
end

lut = zeros(256, ty, tx);
for j = 1:ty
    for i = 1:tx
        tile = S((j - 1) * th + (1:th), (i - 1) * tw + (1:tw));
        h = accumarray(double(tile(:)) + 1, 1, [256 1]);
        if isfinite(clip)
            excess = sum(max(h - clip, 0));
            h = min(h, clip);
            batch = floor(excess / 256);
            residual = excess - batch * 256;
            h = h + batch;
            if residual > 0
                step = max(floor(256 / residual), 1);
                k = 0;
                while k < 256 && residual > 0
                    h(k + 1) = h(k + 1) + 1;
                    residual = residual - 1;
                    k = k + step;
                end
            end
        end
        lut(:, j, i) = min(max(round(cumsum(h) * (255 / tileArea)), 0), 255);
    end
end

% Interpolacion bilineal entre las LUT de los 4 tiles vecinos (CLAHE_Interpolation_Body)
xf = (0:W - 1) / tw - 0.5;
x1 = floor(xf); xa = xf - x1; x2 = x1 + 1;
x1 = max(x1, 0); x2 = min(x2, tx - 1);
yf = ((0:H - 1) / th - 0.5)';
y1 = floor(yf); ya = yf - y1; y2 = y1 + 1;
y1 = max(y1, 0); y2 = min(y2, ty - 1);

v = double(I);
L = @(yy, xx) lut(v + 1 + 256 * yy + 256 * ty * xx);   % expansion implicita: (Hx1)+(1xW)
res = (L(y1, x1) .* (1 - xa) + L(y1, x2) .* xa) .* (1 - ya) + ...
      (L(y2, x1) .* (1 - xa) + L(y2, x2) .* xa) .* ya;
J = uint8(round(res));
end
