function K = cv_ellipse_kernel(k)
%CV_ELLIPSE_KERNEL Elemento estructurante = cv2.getStructuringElement(MORPH_ELLIPSE, (k, k)).
%   Devuelve una matriz logica k x k con el mismo patron que OpenCV. Para k
%   par (p.ej. 20) el ancla de OpenCV es (k/2, k/2) en 0-based; cv_morph se
%   encarga de respetar esa ancla.
r = floor(k / 2);
c = floor(k / 2);
if r > 0, inv_r2 = 1 / (r * r); else, inv_r2 = 0; end
K = false(k, k);
for i = 0:k - 1
    dy = i - r;
    if abs(dy) <= r
        dx = round(c * sqrt((r * r - dy * dy) * inv_r2));
        j1 = max(c - dx, 0);
        j2 = min(c + dx + 1, k);
        K(i + 1, j1 + 1:j2) = true;
    end
end
end
