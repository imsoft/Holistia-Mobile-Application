-- Migration 020: Rueda de Vida (Life Wheel)
-- Tabla para guardar la autoevaluación del usuario en 8 áreas de su vida (puntuación 1-5).

CREATE TABLE IF NOT EXISTS public.life_assessments (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  aspect     TEXT        NOT NULL
               CHECK (aspect IN ('personal','fisico','laboral','familiar','pareja','alimentacion','social','dinero')),
  score      INTEGER     NOT NULL CHECK (score BETWEEN 1 AND 5),
  reason     TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT life_assessments_user_aspect_unique UNIQUE (user_id, aspect)
);

CREATE INDEX IF NOT EXISTS idx_life_assessments_user ON public.life_assessments(user_id);

ALTER TABLE public.life_assessments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Ver propias evaluaciones"
  ON public.life_assessments FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Insertar evaluacion propia"
  ON public.life_assessments FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Actualizar evaluacion propia"
  ON public.life_assessments FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Eliminar evaluacion propia"
  ON public.life_assessments FOR DELETE
  USING (user_id = auth.uid());
