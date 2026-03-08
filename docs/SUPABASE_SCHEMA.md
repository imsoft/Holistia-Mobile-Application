# Holistia – Esquema de base de datos (Supabase)

Este documento describe las tablas, relaciones y políticas RLS. Ejecuta el SQL en el **SQL Editor** de tu proyecto Supabase (en orden).

---

## Resumen de tablas

| Tabla | Descripción |
|-------|-------------|
| `profiles` | Perfil extendido del usuario (auth.users). Nombre, avatar, visibilidad. |
| `challenges` | Retos creados por el usuario. Tipo, meta, unidad, público/privado. |
| `check_ins` | Registros de avance (un día cumplido, un valor numérico, etc.). |
| `posts` | Publicaciones de progreso (visibles en el feed). Reciben Zenit. |
| `zenits` | “Like” a una publicación. Un Zenit por usuario por publicación. |

---

## 1. Enums (tipos de reto y frecuencia)

```sql
-- Tipos de reto soportados en v1
CREATE TYPE challenge_type AS ENUM (
  'streak',        -- X días seguidos
  'count_times',   -- X veces en un periodo (ej. 3 por semana)
  'count_units'    -- X unidades (km, páginas, minutos)
);

-- Periodo para count_times
CREATE TYPE challenge_frequency AS ENUM (
  'daily',
  'weekly',
  'monthly'
);
```

---

## 2. Tabla `profiles`

Extiende `auth.users`. Se crea/actualiza con trigger al registrar usuario.

```sql
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  is_public BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Trigger: crear perfil al registrarse
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Perfiles públicos son visibles por todos"
  ON public.profiles FOR SELECT
  USING (is_public = true OR id = auth.uid());

CREATE POLICY "Usuario puede ver su propio perfil"
  ON public.profiles FOR SELECT
  USING (id = auth.uid());

CREATE POLICY "Usuario puede actualizar su propio perfil"
  ON public.profiles FOR UPDATE
  USING (id = auth.uid());
```

---

## 3. Tabla `challenges`

```sql
CREATE TABLE public.challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type challenge_type NOT NULL,
  target NUMERIC NOT NULL CHECK (target > 0),
  unit TEXT,
  frequency challenge_frequency,
  is_public BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT frequency_for_count_times
    CHECK (type != 'count_times' OR frequency IS NOT NULL)
);

-- Índices
CREATE INDEX idx_challenges_user_id ON public.challenges(user_id);
CREATE INDEX idx_challenges_is_public ON public.challenges(is_public) WHERE is_public = true;

-- RLS
ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios ven sus propios retos"
  ON public.challenges FOR ALL
  USING (user_id = auth.uid());

CREATE POLICY "Retos públicos son visibles por todos"
  ON public.challenges FOR SELECT
  USING (is_public = true);
```

---

## 4. Tabla `check_ins`

Un registro por “avance”: un día cumplido (streak), una vez más (count_times), o un valor (count_units).

```sql
CREATE TABLE public.check_ins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  value NUMERIC,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(challenge_id, date)
);

-- value: para count_units (ej. 5.2 km). Para streak/count_times puede ser 1 o NULL.
CREATE INDEX idx_check_ins_challenge_id ON public.check_ins(challenge_id);
CREATE INDEX idx_check_ins_user_id ON public.check_ins(user_id);
CREATE INDEX idx_check_ins_date ON public.check_ins(date);

-- RLS
ALTER TABLE public.check_ins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios gestionan sus propios check-ins"
  ON public.check_ins FOR ALL
  USING (user_id = auth.uid());

-- Ver check-ins de retos públicos (para rankings/feed)
CREATE POLICY "Check-ins de retos públicos visibles"
  ON public.check_ins FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.challenges c
      WHERE c.id = check_ins.challenge_id AND c.is_public = true
    )
  );
```

---

## 5. Tabla `posts`

Publicaciones de progreso (lo que aparece en el feed y puede recibir Zenit). Opcionalmente vinculadas a un check-in.

```sql
CREATE TABLE public.posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  check_in_id UUID REFERENCES public.check_ins(id) ON DELETE SET NULL,
  body TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_posts_user_id ON public.posts(user_id);
CREATE INDEX idx_posts_challenge_id ON public.posts(challenge_id);
CREATE INDEX idx_posts_created_at ON public.posts(created_at DESC);

-- RLS
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios crean y gestionan sus publicaciones"
  ON public.posts FOR ALL
  USING (user_id = auth.uid());

CREATE POLICY "Publicaciones de retos públicos son visibles"
  ON public.posts FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.challenges c
      WHERE c.id = posts.challenge_id AND c.is_public = true
    )
  );
```

---

## 6. Tabla `zenits`

Un Zenit por usuario por publicación.

```sql
CREATE TABLE public.zenits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(from_user_id, post_id)
);

CREATE INDEX idx_zenits_post_id ON public.zenits(post_id);
CREATE INDEX idx_zenits_from_user_id ON public.zenits(from_user_id);

-- RLS
ALTER TABLE public.zenits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios pueden dar y quitar su propio Zenit"
  ON public.zenits FOR ALL
  USING (from_user_id = auth.uid());

CREATE POLICY "Zenits son visibles por todos (para contador en post)"
  ON public.zenits FOR SELECT
  USING (true);
```

---

## 7. Vista útil: posts con conteo de Zenits

```sql
CREATE OR REPLACE VIEW public.posts_with_zenit_count AS
SELECT
  p.*,
  COALESCE(z.zenit_count, 0)::int AS zenit_count
FROM public.posts p
LEFT JOIN (
  SELECT post_id, COUNT(*) AS zenit_count
  FROM public.zenits
  GROUP BY post_id
) z ON z.post_id = p.id
ORDER BY p.created_at DESC;
```

(Opcional: en la app puedes hacer el count con una query o función; la vista facilita el feed.)

---

## Orden de ejecución en Supabase

1. Crear enums: `challenge_type`, `challenge_frequency`.
2. Crear `profiles` + trigger + RLS.
3. Crear `challenges` + RLS.
4. Crear `check_ins` + RLS.
5. Crear `posts` + RLS.
6. Crear `zenits` + RLS.
7. Crear vista `posts_with_zenit_count` (opcional).

---

## Tipos de reto en la app (v1)

| type | Descripción | target | unit | frequency |
|------|-------------|--------|------|-----------|
| `streak` | Días seguidos cumpliendo | Nº de días | opcional (ej. "días") | — |
| `count_times` | Veces en un periodo | Nº de veces | — | daily / weekly / monthly |
| `count_units` | Cantidad acumulada | Valor (km, páginas…) | "km", "páginas", etc. | — |

Ejemplos:
- “Meditar 7 días seguidos” → streak, target 7.
- “Correr 3 veces por semana” → count_times, target 3, frequency weekly.
- “Leer 10 páginas al día” → count_units, target 10, unit "páginas" (y check_ins con value = páginas ese día).

---

*Actualizar este esquema si añades campos (ej. nivel, insignias) en fases posteriores.*
