function g = cv_gaussian_kernel(ksize, sigma)
%CV_GAUSSIAN_KERNEL Kernel gaussiano 1-D identico a cv2.getGaussianKernel.
%   Con sigma <= 0 y ksize impar <= 7, OpenCV usa tablas fijas;
%   si no, sigma = 0.3*((ksize-1)*0.5 - 1) + 0.8.
if nargin < 2, sigma = 0; end
small = {1, [0.25 0.5 0.25], [0.0625 0.25 0.375 0.25 0.0625], ...
         [0.03125 0.109375 0.21875 0.28125 0.21875 0.109375 0.03125]};
if sigma <= 0 && mod(ksize, 2) == 1 && ksize <= 7
    g = small{(ksize + 1) / 2};
else
    if sigma <= 0
        sigma = 0.3 * ((ksize - 1) * 0.5 - 1) + 0.8;
    end
    x = (0:ksize - 1) - (ksize - 1) / 2;
    g = exp(-(x .^ 2) / (2 * sigma ^ 2));
    g = g / sum(g);
end
g = g(:)';
end
