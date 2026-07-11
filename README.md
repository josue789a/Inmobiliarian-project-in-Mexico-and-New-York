[README.md](https://github.com/user-attachments/files/29910055/README.md)
# Predicción de Precios Inmobiliarios — México y New York

Proyecto de análisis de datos y Machine Learning sobre un portafolio de operaciones inmobiliarias (venta/alquiler) en 5 ciudades de México y New York, con el objetivo de limpiar el dataset, explorar patrones de mercado y construir un modelo predictivo del precio de venta.

## Objetivo

Predecir el **precio de venta** de un inmueble a partir de sus características (tipo, ubicación, superficie, y variables adicionales incorporadas en iteraciones posteriores del dataset), evaluando distintos algoritmos y detectando problemas comunes de un pipeline de ML real: overfitting, heterocedasticidad y data leakage.

## Estructura del proyecto

El notebook está organizado en 3 fases:

### Fase 1 — Limpieza de datos
- Carga del dataset original (`Inmuebles.xlsx`, 2,701 registros).
- Diagnóstico de calidad: nulos, duplicados, tipos de dato.
- Eliminación de filas sin `Referencia` (110 registros sin datos, ligados a filas vacías completas).
- Tratamiento de nulos en `Vendedor` (11.65% de los datos) → se conservan e imputan como `"Sin vendedor"`, ya que están ligados a operaciones sin `Fecha de alta`, no a errores de captura.
- Conversión de `Precio_venta` de string con símbolo `$` a `int`.
- Separación de la columna compuesta `Location` (`Continente|Pais|Ciudad`) en 3 columnas.
- Normalización de la columna de estatus (`V`/`P` → `Vendido`/`Proceso`).
- Renombrado de columnas a nombres legibles.

### Fase 2 — Exploración visual (EDA)
- Distribución de operaciones por ciudad y por tipo de inmueble (conteos, tablas cruzadas, gráficos de barras apiladas en valor absoluto y porcentual).
- Hallazgo clave: la distribución de tipos de inmueble es muy similar entre ciudades (no hay un tipo dominante claro), y **New York concentra muchas menos operaciones** que las ciudades mexicanas (50 vs. ~650-680 en cada ciudad mexicana).

### Fase 3 — Machine Learning
Se probaron varias iteraciones de modelos, cada una agregando complejidad:

| Modelo | Features | Target |
|---|---|---|
| Regresión Lineal (base) | Tipo Inmueble, Ciudad, Superficie | Precio (escala real) |
| Regresión Lineal (log) | + Tipo de operación, País | log(Precio) |
| Random Forest (log) | igual que anterior | log(Precio) |
| LR / RF v2 | dataset ampliado con habitaciones, cochera, antigüedad, lat/long, inflación, días en mercado | log(Precio) |
| LR / RF v3 | mismo dataset v2, corrigiendo leakage en `Antiguedad_Anios` (estaba derivada del propio target) | log(Precio) |

## Resultados

| Modelo | R² Test | R² Train | MAE | MAE % | RMSE | MAPE |
|---|---|---|---|---|---|---|
| Regresión Lineal (base) | 0.72 | 0.74 | 264,547 | 21.7% | 335,123 | 23.87% |
| Regresión Lineal (log) | 0.75* | 0.77 (log) | 282,280 | — | 363,523 | 25.45% |
| Random Forest (log) | 0.74 | 0.92 | 297,699 | 24.42% | 390,958 | 26.22% |
| **Regresión Lineal v2** | **0.85** | 0.87 | **210,299** | **17.25%** | 280,177 | **19.17%** |
| Random Forest v2 | 0.89 | 0.99 | 180,030 | 14.77% | 246,199 | 15.98% |
| Regresión Lineal v3 (leakage corregido) | 0.76 | 0.77 | 284,362 | 23.33% | 366,996 | 25.56% |
| Random Forest v3 (leakage corregido) | 0.80 | 0.97 | 269,640 | 22.12% | 347,113 | 23.35% |

*R² en escala log-espacio antes de la transformación exponencial.

### Cross-validation (5 folds)

| Modelo | CV R² promedio | Desv. estándar |
|---|---|---|
| Regresión Lineal (base) | 0.7309 | 0.0162 |
| Regresión Lineal (log) | 0.7643 | — |
| Random Forest (log) | 0.7490 | 0.0087 |
| Regresión Lineal v2 | 0.8643 | 0.0078 |
| Random Forest v2 | 0.8948 | 0.0130 |
| Regresión Lineal v3 | 0.7627 | 0.0108 |
| Random Forest v3 | 0.7890 | 0.0091 |

## Conclusiones clave

- **El modelo base explica ~75% de la variabilidad del precio** usando solo tipo de inmueble, ciudad y superficie, sin señales de overfitting (diferencia train-test de 0.013).
- **Random Forest sobreajusta de forma consistente** en todas las iteraciones (R² train >0.9 vs. test ~0.74-0.89), lo que sugiere que la relación entre variables y precio es mayormente lineal y que agregar complejidad de modelo no compensa la falta de señal en las features.
- **Se detectó y corrigió data leakage**: en el dataset v2, la variable `Antiguedad_Anios` estaba derivada directamente del precio de venta (el target), lo que inflaba artificialmente las métricas (R² test de 0.85-0.89). Al corregirla en v3, el rendimiento cayó a niveles más realistas (R² test ~0.76-0.80), confirmando que la mejora de v2 no era señal genuina sino fuga de información.
- **La transformación logarítmica del target** ayuda a estabilizar la varianza de los residuos (los precios altos tienen errores absolutos mucho mayores — heterocedasticidad confirmada visualmente en el gráfico de residuos vs. predicciones).
- El principal límite del modelo no es el algoritmo sino la **cantidad y calidad de variables predictoras disponibles**; features geográficas y de contexto de mercado (inflación, días en mercado) sí aportan señal real cuando no hay leakage de por medio.

## Tecnologías

- Python (pandas, numpy)
- Visualización: matplotlib, seaborn
- Machine Learning: scikit-learn (`Pipeline`, `ColumnTransformer`, `OneHotEncoder`, `StandardScaler`, `LinearRegression`, `RandomForestRegressor`, `cross_val_score`)

## Cómo ejecutar

```bash
pip install pandas numpy matplotlib seaborn scikit-learn openpyxl
jupyter notebook Proyecto_inmobiliaria_en_Mexico_y_New_York.ipynb
```

> Nota: las rutas de carga de datos (`pd.read_excel(...)`) están hardcodeadas a una ruta local; deben actualizarse a la ubicación de los archivos `Inmuebles.xlsx`, `Inmuebles_mejorado_v2.xlsx` e `Inmuebles_mejorado_v3.xlsx` según el entorno.

## Próximos pasos

- Incorporar más variables de contexto de mercado por ciudad/país 
- Aplicar modelos más completos sobre un dataset mas amplio 

