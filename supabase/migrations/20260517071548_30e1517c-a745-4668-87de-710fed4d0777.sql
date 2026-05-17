CREATE OR REPLACE FUNCTION public.update_user_coins(_user_id uuid, _coins integer, _action text, _type text, _report_id uuid DEFAULT NULL::uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  -- Only admins may call this RPC directly. Internal trigger calls run as superuser (auth.uid() IS NULL) and are allowed.
  IF auth.uid() IS NOT NULL AND NOT public.has_role(auth.uid(), 'admin'::app_role) THEN
    RAISE EXCEPTION 'Only admins can adjust user coins';
  END IF;

  UPDATE profiles
  SET green_coins = green_coins + _coins
  WHERE user_id = _user_id;

  INSERT INTO green_coins_transactions (user_id, action, coins, transaction_type, related_report_id)
  VALUES (_user_id, _action, ABS(_coins), _type, _report_id);
END;
$function$;