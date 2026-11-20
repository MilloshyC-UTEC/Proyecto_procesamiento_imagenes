function J = cv_gaussian_blur(I, ksize, border)
%CV_GAUSSIAN_BLUR Equivalente a cv2.GaussianBlur(I, (ksize, ksize), 0).
%   Gaussiano separable con el kernel y el borde de OpenCV (BORDER_REFLECT_101
%   por defecto). Entrada uint8 -> salida uint8 redondeada; double -> double.
if nargin < 3, border = 'reflect101'; end
g = cv_gaussian_kernel(ksize, 0);
r = (ksize - 1) / 2;
P = cv_pad(double(I), r, r, r, r, border);
J = zeros(size(I));
for c = 1:size(I, 3)
    J(:, :, c) = conv2(g(:), g, P(:, :, c), 'valid');
end
if isa(I, 'uint8')
    J = uint8(round(J));
end
end
