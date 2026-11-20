function save_examples(items, p, out_dir, prefix, n)
%SAVE_EXAMPLES Guarda n paneles de ejemplo repartidos a lo largo del dataset.
if n <= 0 || isempty(items), return; end
idx = unique(round(linspace(1, numel(items), min(n, numel(items)))));
for k = idx
    [~, base] = fileparts(items(k).name);
    save_example_figure(items(k), p, fullfile(out_dir, sprintf('%s_%s.png', prefix, base)));
end
end
