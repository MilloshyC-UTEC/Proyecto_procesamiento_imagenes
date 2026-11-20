function p = default_params()
%DEFAULT_PARAMS Parametros del notebook (clase ClassicalCellDetector), tal cual.
%   Estan calibrados para BCCD (Dataset 1, imagenes de 640x480, RBC de
%   ~102 px de lado). Para otros datasets ver scale_params.m.
p.name  = 'original';
p.scale = 1.0;

% --- Preprocesamiento comun ---
p.clahe_clip  = 3.0;      % cv2.createCLAHE(clipLimit=3.0, ...)
p.clahe_tiles = [8 8];    % tileGridSize=(8, 8)

% --- WBC ---
p.wbc_blur_ksize  = 7;                % apply_gaussian_blur, kernel (7,7)
p.hsv_lower       = [79 77 109];      % unidades OpenCV: H 0-180, S y V 0-255
p.hsv_upper       = [151 212 212];
p.wbc_open_ksize  = 5;  p.wbc_open_iter  = 2;   % elipse 5x5, iterations=2
p.wbc_close_ksize = 20; p.wbc_close_iter = 2;   % elipse 20x20, iterations=2
p.wbc_min_area    = 1500;                       % filter_wbc_by_size

% --- RBC ---
p.rbc_blur_ksize   = 5;               % rbc_blurring_phase, kernel (5,5)
p.adapt_block      = 201;             % adaptiveThreshold blockSize
p.adapt_C          = 2;               % adaptiveThreshold C
p.wbc_remove_ksize = 5;  p.wbc_remove_iter = 2; % dilatacion de la mascara WBC
p.bg_ksize         = 3;               % np.ones((3,3))
p.open_iter        = 2;  p.close_iter = 3;  p.bg_dilate_iter = 3;
p.dist_blur_ksize  = 3;               % blur de la transformada de distancia
p.fg_ratio         = 0.35;            % sure_fg = dist > 0.35*max(dist)
p.typical_rbc_area = 6000;            % FIXED_AREA
p.min_area_ratio   = 0.4;             % < 0.4*area -> ruido
p.clump_ratio      = 1.8;             % > 1.8*area -> grupo de varias celulas

% --- Cajas (markers_to_detections) ---
p.pad           = 10;
p.wbc_pad_extra = 10;                 % los WBC usan padding + 10
end
