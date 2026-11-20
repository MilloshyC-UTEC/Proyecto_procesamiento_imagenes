function items = load_bccd_supervisely(root, splits)
%LOAD_BCCD_SUPERVISELY Dataset 1: BCCD en formato Supervisely (Kaggle orvile).
%   root/<split>/img/BloodImage_XXXXX.jpeg
%   root/<split>/ann/BloodImage_XXXXX.jpeg.json
%   Cada JSON trae objects(k).classTitle ('RBC','WBC','Platelets') y
%   objects(k).points.exterior = [[x1,y1],[x2,y2]].
%
%   items(k): path, name, split, gt_boxes (N x 4 [x1 y1 x2 y2]), gt_labels,
%             class_label ('' porque es un dataset de deteccion)
if nargin < 2, splits = {'train', 'val', 'test'}; end
items = empty_items();
for s = 1:numel(splits)
    imgdir = fullfile(root, splits{s}, 'img');
    files = dir(fullfile(imgdir, '*.jpeg'));
    names = sort({files.name});
    for k = 1:numel(names)
        ann_path = fullfile(root, splits{s}, 'ann', [names{k} '.json']);
        if ~exist(ann_path, 'file')
            error('No se encontro la anotacion %s', ann_path);
        end
        data = jsondecode(fileread(ann_path));
        [boxes, labels] = parse_objects(data);
        it.path = fullfile(imgdir, names{k});
        it.name = names{k};
        it.split = splits{s};
        it.gt_boxes = boxes;
        it.gt_labels = labels;
        it.class_label = '';
        items(end + 1) = it; %#ok<AGROW>
    end
end
end

function [boxes, labels] = parse_objects(data)
boxes = zeros(0, 4);
labels = {};
if ~isfield(data, 'objects') || isempty(data.objects), return; end
objs = data.objects;
if ~iscell(objs), objs = num2cell(objs); end
for k = 1:numel(objs)
    o = objs{k};
    if ~strcmp(o.geometryType, 'rectangle'), continue; end
    e = o.points.exterior;           % jsondecode -> [x1 y1; x2 y2]
    if iscell(e), e = cell2mat(cellfun(@(v) v(:)', e, 'UniformOutput', false)); end
    boxes(end + 1, :) = [e(1, 1) e(1, 2) e(2, 1) e(2, 2)]; %#ok<AGROW>
    labels{end + 1, 1} = upper(o.classTitle); %#ok<AGROW>
end
end
