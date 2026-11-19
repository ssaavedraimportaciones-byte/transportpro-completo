-- ROLLBACK de 20260930b_proteger_facturacion.sql (restaura el estado previo exacto)
DROP TRIGGER IF EXISTS tp_proteger_facturacion ON public.empresas;
DROP FUNCTION IF EXISTS public.tp_proteger_facturacion_empresa();

DROP POLICY IF EXISTS payments_empresa ON public.payments;
CREATE POLICY payments_empresa ON public.payments FOR ALL TO authenticated
  USING (empresa_id IN (SELECT usuarios.empresa_id FROM usuarios WHERE usuarios.auth_uid = auth.uid()));

DROP POLICY IF EXISTS subscriptions_empresa ON public.subscriptions;
CREATE POLICY subscriptions_empresa ON public.subscriptions FOR ALL TO authenticated
  USING (empresa_id IN (SELECT usuarios.empresa_id FROM usuarios WHERE usuarios.auth_uid = auth.uid()));

DROP POLICY IF EXISTS usage_empresa ON public.usage_monthly;
CREATE POLICY usage_empresa ON public.usage_monthly FOR ALL TO authenticated
  USING (empresa_id IN (SELECT usuarios.empresa_id FROM usuarios WHERE usuarios.auth_uid = auth.uid()));
