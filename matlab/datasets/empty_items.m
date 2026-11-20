function items = empty_items()
%EMPTY_ITEMS Struct array vacio con los campos comunes de todos los loaders.
items = struct('path', {}, 'name', {}, 'split', {}, 'gt_boxes', {}, ...
               'gt_labels', {}, 'class_label', {});
end
