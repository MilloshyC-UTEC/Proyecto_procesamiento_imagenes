%% RUN_ALL_DATASETS
% Reproduce en MATLAB el pipeline clasico del notebook
% "Detecting and Counting Blood Cells" (F. Nesler, F. Di Bon) y lo evalua en:
%   Dataset 1  BCCD (Kaggle orvile, formato Supervisely)      -> deteccion + conteo
%   Dataset 2  Blood Cell Detection Dataset (draaslan)          -> deteccion + conteo
%   Dataset 3  ehottl/blood_dataset (muestra de 60 img/clase)   -> 1 celula por imagen
%
% Uso: abrir este archivo en MATLAB y correrlo (F5). Requiere Image
% Processing Toolbox. Los datasets deben estar en la carpeta del repo con
% los nombres de abajo. Los resultados se guardan en resultados_matlab/.
%
% Configuraciones:
%   original  parametros del notebook sin cambios (calibrados para BCCD)
%   adaptado  parametros geometricos escalados al tamano de los RBC de cada
%             dataset (scale_params.m) y, en el Dataset 2, umbrales HSV
%             ajustados a su tincion (nucleos mas oscuros y saturados)

clear; clc;
here = fileparts(mfilename('fullpath'));
repo = fileparts(here);
addpath(genpath(here));
if exist('OCTAVE_VERSION', 'builtin'), pkg load image; end

% ---------------------------- Opciones ----------------------------------
MAX_IMAGES = Inf;    % p.ej. 10 para una prueba rapida
N_EXAMPLES = 4;      % paneles de ejemplo por dataset/configuracion
RUN_D1 = true;  RUN_D2 = true;  RUN_D3 = true;

D1_DIR = fullfile(repo, 'bccd-blood-cell-count-and-detection-dataset');
D2_DIR = fullfile(repo, 'blood-cell-detection-dataset');
D3_DIR = fullfile(repo, 'blood_dataset_sample');
OUT    = fullfile(repo, 'resultados_matlab');
if ~exist(OUT, 'dir'), mkdir(OUT); end
fig_dir = fullfile(OUT, 'ejemplos');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

p_orig = default_params();
REF_RBC_SIDE = 101.98;   % mediana sqrt(w*h) de los RBC anotados en BCCD
summary = [];
d3_summary = [];

%% ------------------------------ Dataset 1 ------------------------------
if RUN_D1 && exist(D1_DIR, 'dir')
    fprintf('\n=== Dataset 1: BCCD (%s) ===\n', D1_DIR);
    items1 = load_bccd_supervisely(D1_DIR);
    REF_RBC_SIDE = median_rbc_side(items1);
    fprintf('Imagenes: %d | lado mediano RBC (GT): %.1f px\n', numel(items1), REF_RBC_SIDE);
    items1 = items1(1:min(end, MAX_IMAGES));

    [T1, S1] = evaluate_detection_dataset(items1, p_orig);
    write_struct_csv(T1, fullfile(OUT, 'd1_bccd_original_por_imagen.csv'));
    summary = [summary, summary_row('D1_BCCD', 'original', 'all', p_orig, S1)];
    for sp = {'train', 'val', 'test'}
        sel = strcmp({T1.split}, sp{1});
        if any(sel)
            summary = [summary, summary_row('D1_BCCD', 'original', sp{1}, p_orig, split_summary(T1(sel)))]; %#ok<AGROW>
        end
    end
    save_examples(items1, p_orig, fig_dir, 'd1_bccd_original', N_EXAMPLES);
else
    fprintf('\n(Dataset 1 omitido: no existe %s)\n', D1_DIR);
end

%% ------------------------------ Dataset 2 ------------------------------
s2 = NaN;
if RUN_D2 && exist(D2_DIR, 'dir')
    fprintf('\n=== Dataset 2: Blood Cell Detection (%s) ===\n', D2_DIR);
    items2 = load_bcd_csv(D2_DIR);
    s2 = median_rbc_side(items2) / REF_RBC_SIDE;
    fprintf('Imagenes: %d | lado mediano RBC (GT): %.1f px | escala vs BCCD: %.3f\n', ...
            numel(items2), median_rbc_side(items2), s2);
    items2_all = items2;                       % para calibrar la escala del Dataset 3
    items2 = items2(1:min(end, MAX_IMAGES));

    p2 = scale_params(p_orig, s2, 'adaptado');
    % Tincion distinta: el nucleo de los WBC es mas oscuro (V hasta ~90) y mas
    % saturado (S hasta ~225) que en BCCD. Se amplia la ventana HSV del
    % notebook en esas dos direcciones (mismo procedimiento que el HSV picker).
    p2.hsv_lower = [79 77 85];
    p2.hsv_upper = [151 235 212];

    configs = {p_orig, p2};
    for c = 1:numel(configs)
        p = configs{c};
        fprintf('-- configuracion: %s (s = %.3f)\n', p.name, p.scale);
        [T2, S2] = evaluate_detection_dataset(items2, p);
        write_struct_csv(T2, fullfile(OUT, sprintf('d2_bcd_%s_por_imagen.csv', p.name)));
        summary = [summary, summary_row('D2_BCD', p.name, 'all', p, S2)]; %#ok<AGROW>
        save_examples(items2, p, fig_dir, ['d2_bcd_' p.name], N_EXAMPLES);
    end
else
    fprintf('\n(Dataset 2 omitido: no existe %s)\n', D2_DIR);
end

%% ------------------------------ Dataset 3 ------------------------------
if RUN_D3 && exist(D3_DIR, 'dir')
    fprintf('\n=== Dataset 3: ehottl/blood_dataset, muestra (%s) ===\n', D3_DIR);
    items3 = load_pbc_sample(D3_DIR);
    % Sin cajas: el tamano de los RBC se estima de la imagen. El estimador se
    % calibra con el Dataset 2 (donde si hay GT) para traducirlo a la escala BCCD.
    d3 = estimate_rbc_diameter(items3);
    if ~isnan(s2)
        d2 = estimate_rbc_diameter(items2_all);
        s3 = (d3 / d2) * s2;
        fprintf('Diametro RBC estimado: D3 %.1f px, D2 %.1f px -> escala vs BCCD: %.3f\n', d3, d2, s3);
    else
        s3 = d3 / REF_RBC_SIDE;
        fprintf('Diametro RBC estimado: %.1f px -> escala vs BCCD: %.3f\n', d3, s3);
    end
    items3 = items3(1:min(end, MAX_IMAGES));

    configs = {p_orig, scale_params(p_orig, s3, 'adaptado')};
    for c = 1:numel(configs)
        p = configs{c};
        fprintf('-- configuracion: %s (s = %.3f)\n', p.name, p.scale);
        [T3, S3] = evaluate_classification_dataset(items3, p);
        write_struct_csv(T3, fullfile(OUT, sprintf('d3_blood_dataset_%s_por_imagen.csv', p.name)));
        pc = S3.per_class;
        [pc.config] = deal(p.name);
        [pc.scale] = deal(p.scale);
        d3_summary = [d3_summary, pc]; %#ok<AGROW>
        fprintf('   leucocitos detectados en el centro: %.1f%% | exactamente 1: %.1f%% | plaquetas tomadas como WBC: %.1f%%\n', ...
                100 * S3.leuko_detect_rate, 100 * S3.leuko_exact_one, 100 * S3.platelet_false_wbc);
        % un ejemplo por clase
        classes = unique({items3.class_label});
        for k = 1:numel(classes)
            idx = find(strcmp({items3.class_label}, classes{k}), 1);
            save_example_figure(items3(idx), p, fullfile(fig_dir, ...
                sprintf('d3_%s_%s.png', p.name, classes{k})));
        end
    end
    write_struct_csv(d3_summary, fullfile(OUT, 'resumen_d3_por_clase.csv'));
else
    fprintf('\n(Dataset 3 omitido: no existe %s)\n', D3_DIR);
end

%% ------------------------------ Resumen --------------------------------
if ~isempty(summary)
    write_struct_csv(summary, fullfile(OUT, 'resumen_deteccion.csv'));
    fprintf('\n%-8s %-9s %-6s %5s %6s | %8s %7s %7s %7s | %6s %6s\n', 'Dataset', 'Config', 'Split', ...
            'Escala', 'N', 'WBC ok', 'RBC MAE', 'RBC sesgo', 'RBC F1', 'IoU R', 'IoU W');
    for k = 1:numel(summary)
        r = summary(k);
        fprintf('%-8s %-9s %-6s %5.2f %6d | %7.1f%% %7.2f %9.2f %7.3f | %6.3f %6.3f\n', ...
                r.dataset, r.config, r.split, r.scale, r.n_images, ...
                100 * r.wbc_exact_acc, r.rbc_mae, r.rbc_bias, r.rbc_f1_50, r.rbc_mean_iou, r.wbc_mean_iou);
    end
end
if ~isempty(d3_summary)
    fprintf('\nDataset 3 (WBC detectado por clase)\n%-9s %-12s %6s %6s %8s %8s\n', 'Config', 'Clase', '>=1', '==1', 'centro', 'RBC/img');
    for k = 1:numel(d3_summary)
        r = d3_summary(k);
        fprintf('%-9s %-12s %5.0f%% %5.0f%% %7.0f%% %8.1f\n', r.config, r.class_label, ...
                100 * r.frac_ge1, 100 * r.frac_eq1, 100 * r.frac_center, r.mean_rbc);
    end
end
fprintf('\nResultados en %s\n', OUT);
