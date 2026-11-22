GRANT INSERT ON TABLE public.orders TO authenticated;

DROP POLICY IF EXISTS "Buyers create direct listing order requests" ON public.orders;
CREATE POLICY "Buyers create direct listing order requests"
ON public.orders
FOR INSERT
TO authenticated
WITH CHECK (
  buyer_id = (SELECT auth.uid())
  AND rfq_id IS NULL
  AND quote_id IS NULL
  AND EXISTS (
    SELECT 1
    FROM public.profiles buyer_profile
    WHERE buyer_profile.id = (SELECT auth.uid())
      AND buyer_profile.role IN ('buyer'::public.marketplace_role, 'both'::public.marketplace_role)
  )
  AND private.chemicalos_supplier_is_approved(supplier_id)
  AND EXISTS (
    SELECT 1
    FROM public.products p
    WHERE p.id::text = orders.metadata ->> 'listing_id'
      AND p.supplier_id = orders.supplier_id
      AND p.is_published = true
  )
);
