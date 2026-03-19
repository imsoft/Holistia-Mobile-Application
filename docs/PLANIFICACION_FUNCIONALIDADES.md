# Planificación de nuevas funcionalidades — Holistia

Documento para que tú y tu socia propongan ideas, respondan las mismas preguntas y registren si están de acuerdo **antes** de meter algo al desarrollo.

---

## Uso con IA (para que entienda las preguntas y el formato)

Si vas a pedirle a una IA que rellene una ficha:

1. Pídele que responda **solo** con el bloque `PLANTILLA_IA_POR_IDEA` (sin texto extra fuera del bloque).
2. La IA debe respetar **los nombres de campos** y el formato `CAMPO: valor`.
3. Donde haya valores permitidos (por ejemplo `ACUERDO_ESTADO`), la IA debe usar **uno de esos valores**.

Regla: si algún campo no aplica, la IA debe poner `N/A` (no inventar).

---

## Cómo usarlo

1. **Una idea = una ficha** (podéis copiar la plantilla de abajo para cada idea).
2. **Los dos** respondéis las preguntas (en reunión o por escrito).
3. **Solo se aprueba** cuando los dos marquéis que estáis de acuerdo (o con condiciones claras).
4. Las fichas aprobadas pasan a “Lista de acuerdos” o al backlog; las rechazadas o en pausa quedan archivadas con el motivo.

---

## Plantilla por idea (copiar y rellenar)

```
### Idea: [Nombre corto de la funcionalidad]

**1. ¿Qué es en una frase?**  
[Ej: "Que el usuario pueda invitar a un amigo a un reto por link".]

**2. ¿Qué problema resuelve o qué mejora aporta?**  
[Ej: "Ahora solo se invita desde dentro de la app; con link es más fácil compartir".]

**3. ¿A quién le importa?**  
[Ej: "Usuarios que crean retos y quieren que se unan amigos que no usan mucho la app".]

**4. ¿Qué tendría que hacer el usuario (en 2–4 pasos)?**  
1.  
2.  
3.  
4.  

**5. ¿Es algo solo para móvil o también web / otros?**  
- [ ] Solo móvil  
- [ ] Móvil y web  
- [ ] N/A

**6. ¿Qué tan grande lo vemos (chico / mediano / grande)?**  
- [ ] chico (pocos días)  
- [ ] mediano (1–2 sprints)  
- [ ] grande (varias semanas)

**7. ¿Cómo sabremos que funcionó? (1–2 métricas):**  
1. [Métrica/criterio 1]
2. [Métrica/criterio 2 o N/A]

**8. ¿Qué impacto esperamos en el usuario?**  
- [ ] Aumenta activación (primer uso)
- [ ] Mejora retención (uso recurrente)
- [ ] Reduce fricción / tiempo (menos pasos)
- [ ] Mejora confianza / seguridad
- [ ] N/A

**9. ¿Estamos de acuerdo en hacerla?**  
- [ ] Sí, los dos  
- [ ] Sí, pero con condiciones: [escribir]  
- [ ] No por ahora: [motivo]  
- [ ] La dejamos para más adelante  

**10. Notas / dudas:**  
[Lo que quieran anotar para revisar después.]
```

## Plantilla por idea (IA - formato estructurado)

Copia este bloque y úsalo como “contrato” para que una IA rellene la ficha de forma consistente:

```
PLANTILLA_IA_POR_IDEA

IDEA_NOMBRE: [Nombre corto, 3-6 palabras]

QUE_ES_EN_UNA_FRase: [Texto en 1 frase]

PROBLEMA_MEJORA: [Que problema resuelve y/o qué mejora aporta]

A_QUIEN_LE_IMPORTA: [Tipo de usuario + por qué]

PASOS_USUARIO:
1. [Paso 1 en lenguaje simple]
2. [Paso 2 en lenguaje simple]
3. [Paso 3 o poner N/A si no aplica]
4. [Paso 4 o poner N/A si no aplica]

PLATAFORMAS: [Solo móvil / Móvil y web / N/A]

TAMANO: [chico | mediano | grande]

CRITERIOS_EXITO:
1. [Métrica/criterio 1]
2. [Métrica/criterio 2 o N/A]

IMPACTO_ESPERADO_USUARIO: [Aumenta activacion | Mejora retencion | Reduce friccion/tiempo | Mejora confianza/seguridad | N/A]

ACUERDO_ESTADO: [SI | SI_CON_CONDICIONES | NO_POR_AHORA | PARA_MAS_ADELANTE]
CONDICIONES_O_MOTIVO: [Texto. Si ACUERDO_ESTADO=SI_CON_CONDICIONES -> condiciones; si NO_POR_AHORA -> motivo; si PARA_MAS_ADELANTE -> por qué se pospone; si SI -> N/A]

NOTAS_DUDAS: [Cualquier detalle adicional para revisar]

PREGUNTAS_OPCIONALES (si aplica; si no, poner N/A):
- HOLISTIA_VISION: [Sí/No + por qué o N/A]
- EJEMPLOS_SIMILARES_OTRAS_APPS: [Qué nos gusta/no nos gusta o N/A]
- QUE_PASARIA_SI_NO_LA_HACEMOS_3_6_MESES: [Resumen o N/A]
- DEPENDE_DE_OTRA_FUNCION_O_DATO: [De qué depende o N/A]
```

---

## Preguntas opcionales (si quieren profundizar)

- ¿Esta idea hace que la app sea más “Holistia” o encaja con nuestra visión? ¿Por qué?
- ¿Hay algo parecido en otras apps que nos guste o no nos guste?
- ¿Qué pasaría si **no** la hacemos en los próximos 3–6 meses?
- ¿Depende de otra funcionalidad o de un dato que aún no tenemos?

---

## Lista de acuerdos (ideas aprobadas)

Aquí podéis pegar solo el **nombre** y **prioridad acordada** de lo que ya pasó la plantilla y los dos dieron el visto bueno. Así tenéis una sola lista de “qué sí vamos a hacer”.

| Idea | Prioridad acordada | Nota |
|------|--------------------|------|
| *Ejemplo: Invitar por link* | Alta | Hacer en siguiente sprint |
|  |  |  |

---

## Ideas en revisión / pausa

Ideas que aún están en discusión o que decidisteis dejar para después (copiar el nombre y una línea de motivo).

| Idea | Estado | Motivo |
|------|--------|--------|
|  | En revisión / Pausa |  |

---

## Sugerencia de ritmo

- **Reunión corta (ej. 30 min):** repasar 1–3 ideas con la plantilla y rellenar juntos la tabla de acuerdos.
- **Una vez a la semana o cada 2 semanas:** revisar la "Lista de acuerdos" y decidir qué entra al siguiente sprint o fase de desarrollo.

Si quieres, en el futuro se puede convertir esto en una página dentro de la app (solo para vosotros) o en un Notion/Google Doc; por ahora el documento os sirve para estar alineados y dar orden a las ideas.
