function out = apply_clahe(img, p)
%APPLY_CLAHE CLAHE sobre el canal L de LAB (celda "apply_CLAHE" del notebook).
%   Se imita la representacion LAB de 8 bits de OpenCV (L*255/100, a+128,
%   b+128 cuantizados) para que el CLAHE vea los mismos valores.
lab = rgb2lab(img);
L8 = uint8(min(max(round(lab(:, :, 1) * 255 / 100), 0), 255));
a  = min(max(round(lab(:, :, 2) + 128), 0), 255) - 128;
b  = min(max(round(lab(:, :, 3) + 128), 0), 255) - 128;
L8 = cv_clahe(L8, p.clahe_clip, p.clahe_tiles);
rgb = lab2rgb(cat(3, double(L8) * 100 / 255, a, b));
out = uint8(round(255 * min(max(rgb, 0), 1)));
end
