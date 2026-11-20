function items = load_bcd_csv(root)
%LOAD_BCD_CSV Dataset 2: Blood Cell Detection Dataset (draaslan).
%   root/images/image-N.png  (256 x 256, RGBA)
%   root/annotations.csv     columnas: image_id,image,xmin,ymin,xmax,ymax,label
%   Las coordenadas vienen normalizadas a [0,1] y las etiquetas son
%   'rbc' / 'wbc'; aqui se pasan a pixeles y a mayusculas.
[header, rows] = read_csv_simple(fullfile(root, 'annotations.csv'));
col = @(name) find(strcmp(header, name), 1);
ci = col('image'); cl = col('label');
cx1 = col('xmin'); cy1 = col('ymin'); cx2 = col('xmax'); cy2 = col('ymax');
coords = str2double(rows(:, [cx1 cy1 cx2 cy2]));
names = unique(rows(:, ci));
% orden natural: image-1, image-2, ..., image-100
num = cellfun(@(s) str2double(regexprep(s, '\D', '')), names);
[~, order] = sort(num);
names = names(order);

items = empty_items();
for k = 1:numel(names)
    path = fullfile(root, 'images', names{k});
    info = imfinfo(path);
    W = info(1).Width; H = info(1).Height;
    sel = strcmp(rows(:, ci), names{k});
    b = coords(sel, :);
    if all(b(:) <= 1.0001)                  % normalizadas -> pixeles
        b = b .* [W H W H];
    end
    it.path = path;
    it.name = names{k};
    it.split = 'all';
    it.gt_boxes = b;
    it.gt_labels = upper(rows(sel, cl));
    it.class_label = '';
    items(end + 1) = it; %#ok<AGROW>
end
end
