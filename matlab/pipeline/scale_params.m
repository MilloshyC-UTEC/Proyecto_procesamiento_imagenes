function p = scale_params(p, s, name)
%SCALE_PARAMS Adapta los parametros geometricos a otra escala de imagen.
%   s = (tamano tipico de un RBC en el dataset nuevo) / (tamano en BCCD).
%   Longitudes se multiplican por s y areas por s^2. Los kernels chicos
%   (3x3, 5x5, 7x7) se dejan igual porque ya estan en el minimo razonable.
%   Los umbrales de color (HSV) NO se tocan aqui: si la tincion cambia se
%   ajustan aparte en run_all_datasets.m.
if nargin < 3, name = sprintf('escalado_s%.2f', s); end
p.name  = name;
p.scale = s;
p.wbc_close_ksize  = max(3, round(p.wbc_close_ksize * s));
p.adapt_block      = make_odd(max(3, round(p.adapt_block * s)));
p.wbc_min_area     = p.wbc_min_area * s ^ 2;
p.typical_rbc_area = p.typical_rbc_area * s ^ 2;
p.pad              = round(p.pad * s);
p.wbc_pad_extra    = round(p.wbc_pad_extra * s);
end

function k = make_odd(k)
if mod(k, 2) == 0, k = k + 1; end
end
