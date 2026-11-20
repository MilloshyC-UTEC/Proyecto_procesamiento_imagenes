function write_struct_csv(S, path)
%WRITE_STRUCT_CSV Escribe un struct array (campos escalares o texto) como CSV.
fields = fieldnames(S);
fid = fopen(path, 'w');
if fid < 0, error('No se pudo escribir %s', path); end
fprintf(fid, '%s\n', strjoin(fields', ','));
for k = 1:numel(S)
    vals = cell(1, numel(fields));
    for f = 1:numel(fields)
        v = S(k).(fields{f});
        if ischar(v)
            vals{f} = v;
        elseif islogical(v) || (isnumeric(v) && v == round(v))
            vals{f} = sprintf('%d', v);
        else
            vals{f} = sprintf('%.6g', v);
        end
    end
    fprintf(fid, '%s\n', strjoin(vals, ','));
end
fclose(fid);
end
