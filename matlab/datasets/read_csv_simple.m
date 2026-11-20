function [header, rows] = read_csv_simple(path)
%READ_CSV_SIMPLE Lee un CSV simple (sin comas dentro de comillas).
%   header: 1 x C cellstr; rows: R x C cellstr. Funciona en MATLAB y Octave
%   sin depender de readtable.
txt = fileread(path);
lines = regexp(txt, '\r?\n', 'split');
lines = lines(~cellfun(@isempty, strtrim(lines)));
header = strtrim(strsplit(lines{1}, ','));
rows = cell(numel(lines) - 1, numel(header));
for k = 2:numel(lines)
    parts = strtrim(strsplit(lines{k}, ','));
    rows(k - 1, 1:numel(parts)) = parts;
end
end
