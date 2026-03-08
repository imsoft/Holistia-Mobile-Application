-- Holistia – Migración 022: permitir 6 emojis en post_reactions
-- Ejecutar en el editor SQL de Supabase.
-- Sin esto, ❤️ y 👍 son rechazados por la restricción anterior.

ALTER TABLE public.post_reactions
  DROP CONSTRAINT IF EXISTS post_reactions_emoji_check;

ALTER TABLE public.post_reactions
  ADD CONSTRAINT post_reactions_emoji_check
  CHECK (emoji IN ('🔥','💪','⭐','🙌','❤️','👍'));
