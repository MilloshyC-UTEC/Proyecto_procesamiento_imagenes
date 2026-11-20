function img = draw_boxes(img, boxes_xyxy, color, thickness)
%DRAW_BOXES Dibuja rectangulos directamente sobre los pixeles (sin figuras).
%   boxes_xyxy  N x 4 [x1 y1 x2 y2] en coordenadas 0-based
%   color       [R G B] uint8
%   Funciona sin pantalla (MATLAB -batch u Octave) y sin toolboxes extra.
if nargin < 4, thickness = 2; end
[H, W, ~] = size(img);
for k = 1:size(boxes_xyxy, 1)
    b = round(boxes_xyxy(k, :)) + 1;            % a 1-based
    x1 = min(max(b(1), 1), W); x2 = min(max(b(3), 1), W);
    y1 = min(max(b(2), 1), H); y2 = min(max(b(4), 1), H);
    for t = 0:thickness - 1
        ya = min(y1 + t, H); yb = max(y2 - t, 1);
        xa = min(x1 + t, W); xb = max(x2 - t, 1);
        for c = 1:3
            img(ya, x1:x2, c) = color(c);
            img(yb, x1:x2, c) = color(c);
            img(y1:y2, xa, c) = color(c);
            img(y1:y2, xb, c) = color(c);
        end
    end
end
end
