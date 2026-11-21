# Pipeline clásico de conteo de células sanguíneas en MATLAB

Reproducción en MATLAB del notebook de Kaggle
[*Detecting and Counting Blood Cells*](https://www.kaggle.com/code/francesconesler/detecting-and-counting-blood-cells)
(F. Nesler y F. Di Bon), que está en la raíz del repo como `detecting-and-counting-blood-cells.ipynb`,
evaluada en tres datasets.

## Cómo correrlo

1. Abre MATLAB en la carpeta del repo. Necesitas la **Image Processing Toolbox**.
2. Corre `matlab/run_all_datasets.m` con F5. Procesa los tres datasets y guarda todo en `resultados_matlab/`.
   * Para una prueba rápida, pon `MAX_IMAGES = 10` al inicio del script.
   * Con `RUN_D1`, `RUN_D2` y `RUN_D3` eliges qué datasets correr.
3. `matlab/demo_una_imagen.m` muestra el pipeline paso a paso sobre una imagen, igual que el notebook, con figuras listas para el informe.

También corre en GNU Octave 8 con el paquete `image`, que es como se probó.

Los datasets van en la raíz del repo:

| Carpeta | Dataset | Contenido |
|---|---|---|
| `bccd-blood-cell-count-and-detection-dataset/` | **D1** BCCD ([Kaggle orvile](https://www.kaggle.com/datasets/orvile/bccd-blood-cell-count-and-detection-dataset)) | 364 imágenes 640×480 con cajas RBC/WBC/plaquetas en JSON de Supervisely, ya divididas en train/val/test |
| `blood-cell-detection-dataset/` | **D2** Blood Cell Detection ([Kaggle draaslan](https://www.kaggle.com/datasets/draaslan/blood-cell-detection-dataset), descargado de su [mirror en Hugging Face](https://huggingface.co/datasets/draaslan/blood-cell-detection)) | 100 PNG 256×256 y `annotations.csv` con cajas RBC/WBC normalizadas a [0,1] |
| `blood_dataset_sample/` | **D3** [ehottl/blood_dataset](https://huggingface.co/datasets/ehottl/blood_dataset), muestra | 480 imágenes (60 por clase × 8 clases), solo las de formato PBC 360×363. `download_sample.py` + `manifest.csv` permiten volver a bajarla |

## Estructura

```
matlab/
├── run_all_datasets.m        script principal (los 3 datasets + resumen)
├── demo_una_imagen.m         pipeline paso a paso con figuras
├── pipeline/                 = celdas del notebook
│   ├── default_params.m      parámetros de ClassicalCellDetector, tal cual
│   ├── scale_params.m        adapta los parámetros geométricos a otra escala
│   ├── detect_cells.m        = run_pipeline
│   ├── apply_clahe.m         = apply_CLAHE (canal L de LAB)
│   ├── detect_wbc.m          = get_hsv_mask + clean_wbc_morphology + filter_wbc_by_size
│   ├── get_rbc_watershed.m   = rbc_extract_and_clahe ... rbc_size_filtering
│   └── markers_to_detections.m
├── opencv_compat/            funciones de OpenCV reimplementadas (ver abajo)
├── datasets/                 un loader por dataset + estimación de escala
├── evaluation/               IoU, precisión/recall, resúmenes, CSV
└── visualization/            paneles de ejemplo
```

## Fidelidad con el notebook

El objetivo es que el código en MATLAB haga **lo mismo** que el de Python, así que las funciones de OpenCV
que no tienen un equivalente exacto en MATLAB se reimplementaron en `opencv_compat/`:

| OpenCV | Problema con la función nativa de MATLAB | Reimplementación |
|---|---|---|
| `cv2.watershed` | `watershed()` de MATLAB no recibe marcadores | `cv_watershed.m`: inundación de Meyer con 256 colas, igual que OpenCV. **Idéntica píxel a píxel** |
| `createCLAHE(3.0, (8,8))` | `adapthisteq` usa otra escala de *clip limit* y otra interpolación | `cv_clahe.m`: mismo algoritmo (diferencias de ±1 nivel por redondeo) |
| `getStructuringElement(ELLIPSE)` y `morphologyEx` | `strel('disk')` es otra forma, y `imdilate` refleja el kernel y centra distinto los kernels pares (20×20) | `cv_ellipse_kernel.m` + `cv_morph.m`. **Idénticos** |
| `GaussianBlur(k, 0)` | sigma y borde distintos | `cv_gaussian_blur.m`: kernel y borde `REFLECT_101` de OpenCV. **Idéntico** |
| `adaptiveThreshold` | — | media gaussiana de 201×201 con borde replicado, `g <= media − C` |
| HSV de 8 bits | `rgb2hsv` va de 0 a 1 | `cv_rgb2hsv8.m`: H 0–180, S/V 0–255, para usar los mismos umbrales `[79 77 109]–[151 212 212]` |

Las únicas diferencias que quedan son de redondeo en la conversión LAB y que la transformada de distancia
es exacta (`bwdist`) en vez de la aproximación 5×5 de OpenCV. **Comparación con el notebook original en
Python** (primeras 62 imágenes de BCCD, mismas imágenes en ambos): el conteo de WBC sale igual en el 100% de las imágenes,
el de RBC sale igual en el 81% y difiere en a lo más ±1 en el 98%. Las métricas finales también coinciden:
WBC exacto 95.2% en ambos y MAE de RBC 3.18 (MATLAB) frente a 3.16 (Python).

## Configuraciones

* **original**: los parámetros del notebook sin tocar, que están calibrados para BCCD.
* **adaptado** (D2 y D3): las imágenes tienen otra escala y otra tinción, así que se ajustan los parámetros:
  * **Escala** `s` = tamaño de un RBC en el dataset ÷ tamaño en BCCD (102 px). Longitudes × `s` (kernel de cierre 20, `blockSize` 201, padding) y áreas × `s²` (área mínima de WBC 1500, área típica de RBC 6000).
    * D2: `s` sale de las cajas anotadas (≈ 49 px → `s` = 0.479).
    * D3: como no tiene cajas, `estimate_rbc_diameter.m` mide los RBC aislados (Otsu en el canal G). Ese estimador se calibra con D2, donde sí hay anotaciones (`s` ≈ 0.67; el script imprime el valor exacto).
  * **Color (solo D2)**: el núcleo de los WBC es más oscuro y saturado que en BCCD, así que la ventana HSV pasa de `V ≥ 109` a `V ≥ 85` y de `S ≤ 212` a `S ≤ 235`.

## Métricas

* **D1 y D2** (tienen cajas):
  * Conteo: acierto exacto de WBC, MAE y sesgo del conteo de RBC.
  * Detección: `compute_image_iou` del notebook (estaba definida pero no se usaba) y precisión/recall/F1 con IoU ≥ 0.5.
* **D3** (una célula por imagen, sin cajas): % de imágenes donde se detecta un WBC que contiene el centro de la imagen, por clase.
  * Lo esperado es detectarlo en los 6 tipos de leucocito y no detectar nada en `Platelet`.
  * `Erythroblast` es un glóbulo rojo inmaduro con núcleo y se tiñe como un WBC.

## Resultados

`run_all_datasets.m` imprime la tabla completa y la guarda en `resultados_matlab/resumen_deteccion.csv` y
`resultados_matlab/resumen_d3_por_clase.csv`. Los resultados por imagen quedan en CSV y los paneles de ejemplo
(original | GT | máscara WBC | watershed | detecciones) en `resultados_matlab/ejemplos/`.

Valores de referencia de la prueba en Octave:

| Dataset | Config | WBC exacto | RBC MAE | RBC sesgo | RBC F1@0.5 |
|---|---|---|---|---|---|
| D1 BCCD (notebook en Python, 364 img) | original | 94.8% | 3.86 | +1.58 | — |
| D2 BCD (100 img) | original | 55% | 18.92 | −18.92 | 0.04 |
| D2 BCD (100 img) | adaptado | 90% | 5.51 | −5.01 | 0.63 |

Con los parámetros originales el pipeline casi no encuentra RBC en D2, porque las células miden la mitad que en
BCCD y el filtro de área las descarta como ruido. Al escalar los parámetros se recupera la mayor parte del conteo.
