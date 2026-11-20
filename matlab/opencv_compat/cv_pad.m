function P = cv_pad(I, top, bottom, left, right, mode)
%CV_PAD Rellena (padding) un arreglo 2-D/3-D como cv2.copyMakeBorder.
%   mode: 'reflect101' (BORDER_REFLECT_101, el default de GaussianBlur)
%         'replicate'  (BORDER_REPLICATE, el que usa adaptiveThreshold)
if nargin < 6, mode = 'reflect101'; end
[H, W, ~] = size(I);
rows = border_index((1 - top):(H + bottom), H, mode);
cols = border_index((1 - left):(W + right), W, mode);
P = I(rows, cols, :);
end

function idx = border_index(i, n, mode)
switch mode
    case 'replicate'
        idx = min(max(i, 1), n);
    case 'reflect101'
        if n == 1
            idx = ones(size(i));
            return;
        end
        period = 2 * n - 2;
        j = mod(i - 1, period);          % posicion 0-based dentro de un periodo
        j(j >= n) = period - j(j >= n);
        idx = j + 1;
    otherwise
        error('cv_pad: modo de borde desconocido "%s"', mode);
end
end
