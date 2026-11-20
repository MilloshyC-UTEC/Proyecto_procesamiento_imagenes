function items = load_pbc_sample(root)
%LOAD_PBC_SAMPLE Dataset 3: muestra de ehottl/blood_dataset (Hugging Face).
%   root/<Clase>/row_XXXXX.jpg y root/labels.csv (file,label,row_idx).
%   Es un dataset de CLASIFICACION: una celula centrada por imagen y una
%   etiqueta (8 clases). No hay cajas, asi que gt_boxes queda vacio y la
%   clase va en class_label.
[header, rows] = read_csv_simple(fullfile(root, 'labels.csv'));
cf = find(strcmp(header, 'file'), 1);
cl = find(strcmp(header, 'label'), 1);
[~, order] = sort(rows(:, cf));
rows = rows(order, :);
items = empty_items();
for k = 1:size(rows, 1)
    it.path = fullfile(root, rows{k, cf});
    it.name = rows{k, cf};
    it.split = 'sample';
    it.gt_boxes = zeros(0, 4);
    it.gt_labels = {};
    it.class_label = rows{k, cl};
    items(end + 1) = it; %#ok<AGROW>
end
end
