function hsv = cv_rgb2hsv8(rgb)
%CV_RGB2HSV8 HSV con las unidades de OpenCV para imagenes de 8 bits.
%   cv2.cvtColor(..., COLOR_BGR2HSV) da H en [0,180) y S, V en [0,255].
%   rgb2hsv de MATLAB da todo en [0,1], asi que se reescala para poder usar
%   los mismos umbrales del notebook ([79 77 109] - [151 212 212]).
x = rgb2hsv(double(rgb) / 255);
H = mod(round(x(:, :, 1) * 180), 180);
S = round(x(:, :, 2) * 255);
V = round(x(:, :, 3) * 255);
hsv = cat(3, H, S, V);
end
