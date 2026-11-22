# ChemicalOS backend architecture

## Deployment

- Frontend: static single-page application in `index.html`, published through GitHub Pages from `main`.
- Backend: Supabase project `chemicalos-prod` in Mumbai.
- Browser SDK: `@supabase/supabase-js` pinned to `2.119.2`.
- The frontend uses the Supabase project URL and a publishable key only. Never put a service-role or secret key in this repository or browser code.

## Authentication and profiles

Supabase Auth handles email/password sign-up and sign-in. The database trigger creates a matching `public.profiles` row. Supported roles are `buyer`, `supplier`, and `both`.

Supplier accounts are unapproved by default. Supplier role selection during sign-up does not grant supplier capabilities. Publishing products and submitting quotes require the database profile to be approved. The browser cannot edit the role or approval fields.

Supplier approval is currently an operator action in the Supabase dashboard. There is intentionally no client-side admin approval control.

## Marketplace tables

| Table | Purpose |
| --- | --- |
| `profiles` | Account profile, role and supplier approval |
| `products` | Supplier chemical listings and structured specifications |
| `rfqs` | Buyer sourcing requirements |
| `quotes` | Supplier quotations against RFQs |
| `orders` | Orders created by accepting quotes or submitting direct listing requests |
| `commission_records` | Private commission ledger |
| `activity_logs` | Per-user marketplace activity |

All seven tables in the exposed `public` schema have RLS enabled.

## Main permission model

- Anonymous users can read only published products from approved suppliers.
- Buyers can create and read their own RFQs.
- Approved supplier-role accounts can read open RFQs.
- Approved suppliers can create quotes and manage their own products.
- Buyers can read quotes on their own RFQs; suppliers can read their own quotes.
- Only order participants can read an order.
- Direct listing order requests must belong to the signed-in buyer and match a published, fixed-price, standard product from an approved supplier. The database checks supplier identity, currency, unit, price, MOQ and available quantity.
- `commission_records` has no client policy and is not exposed to buyer or supplier clients.

## Order workflows

1. A buyer may submit a direct order request from a fixed-price listing. It is created as `pending`, not as a confirmed sale.
2. A buyer may accept a submitted quote on their own open RFQ through `public.accept_quote`. The function verifies ownership and state, creates the order, accepts the quote and closes the RFQ atomically.
3. Buyer/supplier order status changes use `public.update_order_status`. The function enforces participant-specific transitions.
4. Direct listing order requests do not reserve inventory or act as invoices. Supplier confirmation is still required.

The two public RPCs are SECURITY DEFINER functions with an empty search path and explicit authentication/ownership/transition checks. Their authenticated execute grants are intentional.

## Metadata

The existing marketplace schema keeps flexible frontend-only fields in JSONB metadata on products, RFQs, quotes and orders. Core identity, ownership, quantity, price, currency, status and relationships remain typed columns.

Supplier-entered document labels are not document uploads and are not independent verification. Product verification is controlled by ChemicalOS review; supplier accounts cannot self-verify.

## Operational test checklist

Use real, email-confirmed test accounts before announcing the marketplace as fully live:

- Buyer: sign up, sign in, create an RFQ, refresh and verify it remains.
- Supplier: sign up, confirm that the account is unapproved, and verify that open RFQs and quote submission are unavailable.
- Operator: approve the supplier profile in the Supabase dashboard.
- Supplier: publish a product and submit a quote to an open RFQ.
- Buyer: compare the quote, accept it, and verify that the order is created and the RFQ closes.
- Supplier/buyer: test only the allowed order status transitions.
- Buyer: test a direct listing request against a published fixed-price listing, including MOQ and available-stock boundaries.
- Verify that one account cannot read another buyer's RFQs, private quotes, orders or activity logs.

The syntax validation workflow checks the inline JavaScript on pull requests and updates to `main`. It does not replace the real-account workflow tests above.
