-- Añadir campo para días de la semana seleccionados en retos tipo streak.
-- Almacena un array de enteros: 0=Lunes, 1=Martes, 2=Miércoles, 3=Jueves, 4=Viernes, 5=Sábado, 6=Domingo.
ALTER TABLE public.challenges
  ADD COLUMN IF NOT EXISTS weekdays INTEGER[];

COMMENT ON COLUMN public.challenges.weekdays IS 'Días de la semana seleccionados para retos tipo streak (0=Lunes, 6=Domingo). NULL o vacío significa todos los días.';
