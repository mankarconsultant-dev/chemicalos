-- Allow signed-in buyers to update their own RFQs and approved suppliers to update their own products.
-- Row-level security policies remain the authority for which rows may be changed.
GRANT UPDATE ON TABLE public.rfqs, public.products TO authenticated;
