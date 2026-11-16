# Guion de defensa — DATAFUEL S.A. (Power BI)
**Curso YPF de Análisis de Datos**

> **Cómo usar este guion:** cada hoja tiene 4 partes:
> 1. **Qué pregunta responde** → arrancá siempre por acá.
> 2. **Qué se ve** → señalá los visuales en pantalla.
> 3. **Frase clave** → aprendétela de memoria.
> 4. **Preguntas probables** → con la respuesta corta.
>
> Regla de oro: **no expliques botones, explicá decisiones.** Al profesor no le importa que "acá hay un gráfico de barras"; le importa **qué decisión de negocio** permite tomar.

---

## 🧭 La historia en 30 segundos (la dicen los dos, al inicio)

> "DATAFUEL es una red de **10 estaciones de servicio** en distintas provincias de Argentina, con **64 equipos** (surtidores, compresores de GNC, bombas, tanques y medidores) y **516 órdenes de mantenimiento entre 2009 y 2026**.
> Nuestra pregunta fue: **¿la empresa mantiene bien sus equipos, y cuánto le cuesta no hacerlo?**
> Para responderla recorremos 5 hojas: primero el contexto y el presupuesto, después la frecuencia de mantenimiento, después la comparamos contra lo que pide el fabricante, y terminamos con el riesgo legal y económico."

**Hilo conductor (repítanlo en cada transición):**
**Presupuesto → Frecuencia → Lo que pide el fabricante → Lo que pide la ley → Cuánto cuesta no cumplir.**

---

# 🏁 Hoja 1 — Portada (apertura: la presentan los dos)

> **Reparto sugerido:** vos decís la "historia en 30 segundos" y tu Luis explica la portada y las fuentes de datos, porque él continúa con la hoja 2.

## Hoja 1 — Portada
**Qué pregunta responde:** ¿De qué trata el análisis y para quién es?

**Qué se ve:**
- Logo de DATAFUEL.
- Destinatario: *Dirección de Operaciones y Gestión de Estaciones*.
- Título: *Diagnóstico preliminar de infraestructura y desgaste operativo*.

**Qué decir:**
> "Este tablero está pensado para la **Dirección de Operaciones**. No es un reporte contable: es un **diagnóstico** que evalúa la red en tres ejes: **operativo, técnico y presupuestario**. Lo armamos con una base de datos en **SQL Server** (DATAFUELDW), que modelamos en Power BI con tablas de estaciones, equipos, mantenimientos, movimientos de combustible y presupuestos, todas valorizadas en **dólares** para poder comparar años con inflación distinta."

**Frase clave:** *"Pasamos todo a dólares porque comparar pesos de 2009 con pesos de 2026 no tiene sentido."*

**Preguntas probables:**
- *¿De dónde salen los datos?* → De una base SQL Server con datos de la empresa, ampliados para cubrir 2009–2026. Está documentada en un diccionario de datos.
- *¿Por qué en USD?* → Para neutralizar la inflación y poder comparar costos entre años.

**Transición a la hoja 2:** "Antes de mirar los equipos, vamos a ver **dónde están las estaciones y cómo vienen con el presupuesto**."

---

# 👤 Luis — Hojas 2 y 3

## Hoja 2 — Estaciones del País
**Qué pregunta responde:** ¿Qué estaciones gastan más de lo presupuestado en mantenimiento y cómo evoluciona ese costo?

**Qué se ve (de arriba hacia abajo):**
| Visual | Cómo se lee |
|---|---|
| **Mapa** por provincia | El color indica el **sobrecosto**: cuanto más intenso, más se pasó del presupuesto. |
| **Tabla** con semáforo | Por estación: **presupuesto anual** vs **sobrecosto**. 🟢 dentro del margen · 🟡 al límite · 🔴 sobrecosto. |
| **KPI costo cada 10.000 L** y **cada 10.000 m³** | Cuánto cuesta mantener la estación **por cada 10.000 litros vendidos** (líquidos) o m³ (GNC), comparado con el **año anterior**. |
| **Línea presupuesto vs costo real** | Se ve en qué años el costo real **cruza** la línea del presupuesto. |
| **Línea de volumen vendido** | Litros y m³ vendidos por año (sirve para saber si el costo sube porque se vende más o porque se gasta mal). |
| **Slicers** año / estación | Para filtrar. |

**Qué decir:**
> "No alcanza con mirar cuánto se gastó: hay que **relativizarlo**. Por eso medimos el costo de mantenimiento **cada 10.000 litros vendidos**. Si una estación gasta más pero también vende el doble, no está mal; si gasta más y vende lo mismo, hay un problema. El semáforo de la tabla y el mapa muestran rápido **dónde** está el sobrecosto, y la línea de presupuesto vs real muestra **cuándo** empezó."

**Hallazgo a destacar:** a partir de **2023** aparecen sobrecostos en varias estaciones. Eso coincide con mantenimientos preventivos **postergados o cancelados en temporada alta**, que después generaron **correctivos**, más caros. *(Esto lo profundiza la hoja 3.)*

**Frase clave:** *"El costo absoluto engaña; el costo por litro vendido dice la verdad."*

**Preguntas probables:**
- *¿Por qué cada 10.000 litros?* → Para normalizar por volumen y comparar estaciones de distinto tamaño.
- *¿Qué es el KPI "año anterior"?* → La misma medida calculada con `SAMEPERIODLASTYEAR` (inteligencia de tiempo de DAX) para ver si mejoró o empeoró.
- *¿Por qué hay sobrecosto?* → Por los correctivos que siguieron a preventivos postergados (2023–2026).

**Transición a la hoja 3:** "Ya vimos **dónde** y **cuándo** se gasta de más. Ahora vamos a ver **qué tipo de mantenimiento** se está haciendo, porque ahí está la causa."

---

## Hoja 3 — Frecuencia de Mantenimiento
**Qué pregunta responde:** ¿Cuántos mantenimientos se hacen, de qué tipo y en qué equipos?

**Qué se ve:**
| Visual | Cómo se lee |
|---|---|
| **Barras por estación**, apiladas por tipo | Cuántos mantenimientos tuvo cada estación, separados en **preventivo, correctivo, calibración e inspección**. |
| **Columnas por tipo de equipo** | Qué equipos reciben más intervenciones (surtidor, compresor, bomba, tanque, medidor). |
| **Tarjetas de inventario** | Cuántos surtidores, compresores GNC, bombas, tanques y medidores tiene la estación. |
| **Slicers** de ciudad, año y tipo de mantenimiento | Para filtrar. |

**Concepto previo (decirlo primero):**
> "Hay dos grandes formas de mantener un equipo. El **preventivo** se hace **antes** de que falle: es planificado y más barato. El **correctivo** se hace **después** de la falla: es urgente, más caro y deja el equipo fuera de servicio."

**Qué decir:**
> "Acá vemos la **mezcla** de mantenimientos. Lo sano es que predomine el **preventivo**. Cuando crecen los **correctivos**, crecen los costos y el tiempo fuera de servicio. Eso es justamente lo que vimos en la hoja anterior: los sobrecostos desde 2023 coinciden con más correctivos."

**Hallazgo a destacar (demo en vivo):** filtrar por **Correctivo** y comparar los años **2009–2022** con **2023–2026**. En el segundo período hay más correctivos, porque se postergaron o cancelaron preventivos en **temporada alta**.

**Frase clave:** *"Cada correctivo es un preventivo que no se hizo a tiempo."*

**Preguntas probables:**
- *¿Por qué aumentan los correctivos desde 2023?* → Porque se postergaron preventivos en fechas críticas (verano, cosecha, vacaciones de invierno) para no frenar la venta, y después los equipos fallaron.
- *¿Para qué sirve el inventario?* → Para dimensionar: no es lo mismo 10 mantenimientos en una estación con 3 equipos que en una con 9.
- *¿Qué es "calibración"?* → Ajustar el equipo para que **mida bien**. En los surtidores es **obligatoria por ley** (lo vemos en la hoja 5).

**Transición a mi Luis/a:** "Sabemos **cuánto** mantenimiento se hace. La pregunta es: **¿es suficiente?** Para eso [nombre] lo va a comparar con lo que pide el **fabricante**."

---

# 👤 VOS — Hojas 4 y 5

## Hoja 4 — Análisis de los Mantenimientos según el Manual del OEM
**Qué pregunta responde:** ¿Se mantienen los equipos **con la frecuencia que pide el fabricante**?

**Concepto previo (decirlo primero, 20 segundos):**
> "**OEM** significa *Original Equipment Manufacturer*: el **fabricante** del equipo (Gilbarco, Wayne, Tokheim). Su manual dice **cada cuánto** hay que prevenir, inspeccionar y calibrar cada equipo. Nosotros tomamos esa frecuencia como **objetivo** y la comparamos con lo que **realmente se hizo**."

**Qué se ve:**
| Visual | Cómo se lee |
|---|---|
| **8 tarjetas KPI** (Prevención / Inspección / Calibración × Surtidores / Compresores / Bombas) | Número grande = **mantenimientos ejecutados**. "Objetivo" = lo que pide el OEM. El % = cuánto falta. |
| **Medidor (velocímetro)** | **% de cumplimiento OEM global** de la estación en ese año. Meta: 100 %. |
| **Matriz semáforo** | Las mismas combinaciones en una sola vista: 🟢 ≥ 90 % · 🟡 ≥ 50 % · 🔴 < 50 % · gris = la estación no tiene ese equipo. |
| **Inventario de equipos** | Explica **de dónde sale el objetivo**. |
| **Slicers** año / ciudad | Para elegir estación y año. |

**Cómo se calcula el objetivo (explicarlo con un ejemplo):**
> "El objetivo es **frecuencia del OEM × cantidad de equipos**. Por ejemplo: el fabricante pide **48 inspecciones por año por bomba**. Si La Pampa tiene **4 bombas**, el objetivo es **48 × 4 = 192**. Por eso pusimos el inventario al lado: para que el número **no parezca inventado**."

**Decisiones técnicas que conviene mencionar (suman puntos):**
1. **Solo contamos lo ejecutado.** Filtramos `Estado = "Ejecutado"`. Si contáramos los **cancelados** o **demorados**, el cumplimiento quedaría **inflado**.
2. **Los objetivos están en una tabla de parámetros (`Matriz OEM`).** Si el fabricante cambia una frecuencia, se cambia **en un solo lugar**.
3. **Se muestra 0 y no "en blanco".** Que no haya registros **también es un dato**: significa que no se hizo.

**Hallazgo a destacar (probalo en vivo):**
- Elegí **La Pampa – 2021**: casi todo en **0 %**, solo 1 preventivo de bombas sobre 8. El cumplimiento es prácticamente nulo.
- Elegí **Buenos Aires**: el **compresor de GNC no tiene ningún mantenimiento registrado en 18 años**.

**Frase clave:** *"El fabricante dice cuánto mantenimiento necesita el equipo; los datos dicen cuánto recibió. La diferencia es riesgo."*

**Preguntas probables:**
- *¿De dónde salen las frecuencias (48, 250, 12…)?* → De las recomendaciones del manual del fabricante, tomadas como supuesto del modelo. Están parametrizadas y se pueden ajustar.
- *¿250 preventivos por año para un compresor no es mucho?* → Corresponde a chequeos casi diarios, típicos de equipos de **alta presión** como el GNC. Igual está parametrizado.
- *¿Por qué no aparece la calibración de bombas como tarjeta?* → Está incluida en la matriz y en el % global.
- *¿El medidor no coincide con las tarjetas?* → Porque el global también incluye la calibración de bombas.

**Transición a la hoja 5:** "Hasta acá hablamos de **buenas prácticas**: lo que **conviene** hacer. Pero la calibración de surtidores no es opcional: **la exige la ley**. Veamos cuánto cuesta no cumplirla."

---

## Hoja 5 — Costo de Inactividad (Ley de Metrología 19.511)
**Qué pregunta responde:** Si un inspector encuentra los surtidores sin calibrar, **¿cuánto le cuesta a la empresa?**

**Concepto previo (el marco legal en 3 líneas):**
> "En Argentina rige la **Ley 19.511 de Metrología Legal**. El surtidor es un **instrumento de medición** usado para vender, y por eso necesita **verificación periódica**: si cobramos 40 litros, tenemos que entregar 40 litros. El **INTI** es el organismo técnico y la **Secretaría de Comercio** es la autoridad de aplicación."

**Lo que dice la ley (aprenderlo así):**
| Artículo | Qué dice | Cómo lo usamos |
|---|---|---|
| **Art. 26** | Si hay infracción, el instrumento puede ser **inhabilitado** (precinto). **No fija un plazo.** | Suponemos **12 días** sin vender (escenario). |
| **Art. 33** (texto según **DNU 27/2018**, art. 65) | Multa de **1 a 4.000 Salarios Mínimos, Vitales y Móviles**. | Usamos la **multa mínima**: 1 SMVM = **$398.800** (Res. 4/2026, desde 01/11/2026). |
| **Art. 34** | Si hay **reincidencia**, la multa puede llegar **al doble**. | Lo mencionamos como riesgo adicional. |
| **Art. 35** | **Comiso** si el instrumento no se regulariza en el plazo que fije la autoridad. | Lo mencionamos como riesgo adicional. |

**La fórmula (decirla despacio):**
> **Costo de inactividad = (venta diaria promedio del último año × 12 días) + multa mínima**
> Se calcula **por estación** y se suma la red.

**Qué se ve:**
| Visual | Cómo se lee |
|---|---|
| **Tarjetas** | Costo total de la red · **Costo en riesgo** (solo estaciones con surtidores vencidos) · Estaciones en riesgo · Surtidores sin calibración vigente · Multa mínima. |
| **Barras por estación** | Cuánto es lucro cesante (ventas perdidas) y cuánto es multa. |
| **Tabla** | Venta diaria, lucro cesante, multa, costo total y surtidores vencidos por estación. |
| **Nota al pie** | Fuentes legales y supuestos. |

**Decisiones que conviene defender:**
1. **¿Por qué la multa mínima?** → Es un **escenario conservador**: no inflamos los números. Aun así, **la clausura pesa muchísimo más que la multa**. Con la máxima (4.000 SMVM = **$1.595 millones**) el riesgo sería enorme.
2. **¿Por qué 12 días?** → Porque la ley **no fija plazo**. Es un supuesto explícito y está en la nota al pie.
3. **¿Qué es un surtidor "sin calibración vigente"?** → Uno que no tiene una calibración **ejecutada** en los últimos 365 días.
4. **Costo total vs costo en riesgo:** el total es el riesgo **teórico** si inhabilitaran todo; el costo en riesgo es la exposición **real** según nuestros datos.

**Frase clave (para cerrar la presentación):**
> *"Postergar una calibración parece un ahorro. Pero con solo 12 días de surtidores precintados y la multa más baja que prevé la ley, la empresa pierde mucho más de lo que ahorró. **Calibrar no es un costo: es lo que permite seguir vendiendo.**"*

**Preguntas probables:**
- *¿La ley que usaron es la española 32/2014?* → **No.** Esa es de España. En Argentina rige la **Ley 19.511**, con las multas actualizadas por el **DNU 27/2018**.
- *¿Por qué la multa está en SMVM y no en pesos?* → Porque el DNU 27/2018 la ató al salario mínimo para que **no la licúe la inflación**. Los montos viejos ($100 a $500.000, Ley 24.344 de 1994) hoy serían insignificantes.
- *¿Qué tipo de cambio usaron?* → 1.050 ARS/USD, el de 2026 en nuestra base.
- *¿Las ventas son a precio de venta o a costo?* → Salen de `MovimientosCombustible` (tipo "Venta"), valorizadas con el precio unitario de la base. Si fuera costo, el lucro cesante estaría **subestimado**: el riesgo real sería **mayor**, no menor.
- *¿Hay clausura del local?* → La Ley 19.511 habla de **inhabilitar el instrumento**, no de clausurar el local. La clausura puede venir de otras normas (Defensa del Consumidor, Lealtad Comercial, normas provinciales). Por eso hablamos de **inactividad de surtidores**.

---

## 🎯 Cierre (lo dicen los dos)
> "En resumen: la red tiene **sobrecostos desde 2023** (hoja 2), originados en **preventivos postergados** (hoja 3), con un **cumplimiento muy bajo** de lo que pide el fabricante (hoja 4). Y como la calibración es **obligación legal**, eso se traduce en un **riesgo económico concreto** (hoja 5).
> **Recomendación:** planificar los mantenimientos **fuera de temporada alta**, priorizar las **calibraciones de surtidores** y usar este tablero como **control mensual**."

## ✅ Mejoras futuras (por si preguntan "¿qué le agregarían?")
- Registrar el **error medido** en cada calibración, para compararlo contra el error máximo permitido.
- Agregar **sensores de presión, válvulas y mangueras de GNC** como equipos (hoy no están en la base).
- Cargar la tabla **TiposCambio** en el modelo, para no usar un tipo de cambio fijo.
- Registrar **horas de parada** reales, para calcular MTBF y MTTR exactos.

---

### 🧠 Tips para la defensa
- **Practiquen las transiciones**: son lo que hace que parezca un solo trabajo y no dos.
- Si no saben algo, digan: *"Es un supuesto del modelo y está parametrizado"* (y es verdad).
- **Hagan una demo en vivo**: cambien el año o la estación en las hojas 4 y 5. Eso demuestra que el modelo funciona.
- **Nunca lean la pantalla.** Primero la pregunta, después el visual, después la conclusión.
