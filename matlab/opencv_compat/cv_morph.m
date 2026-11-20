function bw = cv_morph(bw, K, op, iterations)
%CV_MORPH Morfologia binaria con la semantica de OpenCV.
%   op: 'erode' | 'dilate' | 'open' | 'close'
%   iterations igual que en cv2.morphologyEx/cv2.erode/cv2.dilate:
%     open  = erode x iterations y luego dilate x iterations
%     close = dilate x iterations y luego erode x iterations
%
%   Diferencias con MATLAB que se corrigen aqui:
%   * OpenCV ancla un kernel k x k en (floor(k/2), floor(k/2)); MATLAB, para
%     k par, usa floor((k+1)/2). Se agrega una fila/columna de ceros al
%     final para que el centro coincida.
%   * imdilate refleja el elemento estructurante; cv2.dilate no. Por eso se
%     pasa el kernel rotado 180 grados a imdilate.
if nargin < 4, iterations = 1; end
bw = logical(bw);
K = logical(K);
if mod(size(K, 1), 2) == 0, K(end + 1, :) = false; end
if mod(size(K, 2), 2) == 0, K(:, end + 1) = false; end
Kd = rot90(K, 2);

switch op
    case 'erode'
        bw = do_erode(bw, K, iterations);
    case 'dilate'
        bw = do_dilate(bw, Kd, iterations);
    case 'open'
        bw = do_dilate(do_erode(bw, K, iterations), Kd, iterations);
    case 'close'
        bw = do_erode(do_dilate(bw, Kd, iterations), K, iterations);
    otherwise
        error('cv_morph: operacion desconocida "%s"', op);
end
end

function bw = do_erode(bw, K, n)
for t = 1:n
    bw = imerode(bw, K);
end
end

function bw = do_dilate(bw, K, n)
for t = 1:n
    bw = imdilate(bw, K);
end
end
