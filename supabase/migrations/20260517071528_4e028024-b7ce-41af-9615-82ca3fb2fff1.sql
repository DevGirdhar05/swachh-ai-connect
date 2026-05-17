-- 1. Fix SECURITY DEFINER view (leaderboard)
DROP VIEW IF EXISTS public.leaderboard;
CREATE VIEW public.leaderboard
WITH (security_invoker = true) AS
SELECT
  user_id,
  full_name,
  green_coins,
  ROW_NUMBER() OVER (ORDER BY green_coins DESC) AS rank
FROM public.profiles
ORDER BY green_coins DESC;

-- 2. Fix function search_path
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $function$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$function$;

-- 3. Restrict green_coins_transactions INSERT policy
DROP POLICY IF EXISTS "System can insert transactions" ON public.green_coins_transactions;
-- No direct INSERT policy: only SECURITY DEFINER function update_user_coins can insert

-- 4. Add UPDATE/DELETE storage policies for report-images
CREATE POLICY "Users can update their own images"
ON storage.objects
FOR UPDATE
USING (bucket_id = 'report-images' AND (auth.uid())::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own images"
ON storage.objects
FOR DELETE
USING (bucket_id = 'report-images' AND (auth.uid())::text = (storage.foldername(name))[1]);