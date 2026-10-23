# Siore backend

The existing storefront is preserved as a design preview. The database-backed admin lives at /admin and uses ChatGPT sign-in and server-side staff permissions. The owner has permanent full access; staff accounts are matched by approved email and bound to their stable site user ID on first sign-in. Production identity headers are supplied by Sites dispatch; do not expose this Worker directly through an untrusted origin.

## Available features

Products, automatic unique SKUs (or manual override), stock, draft/active/archived status, JPG/PNG/WebP uploads to R2 (4 MB limit), editable delivery fees, COD order entry for Website/Messenger, POS/DM order entry with product search and live totals, order search, lifecycle updates and history, customer and courier editing before dispatch, automatic order invoices with Print/Save as PDF, multiple couriers, staff creation/editing/disabling, role presets and per-user permissions, and a staff activity log. Prices and totals are calculated server-side. Orders reserve inventory transactionally on creation. Cancellation releases reserved inventory once. Returned orders wait for physical inspection; only good received or recovered units are credited. Whole-order returns only at this stage.

## Development and checks

Use the Sites install/build helpers. Generate schema changes with npm run db:generate. Commit migrations and metadata; never rewrite applied migrations. Tests: python tests/inventory.py and node tests/api.mjs. API tests use an isolated Miniflare database and never create production records. Local preview database migrations follow the Sites starter instructions.

## Deploy and operations

The hosting manifest preserves the existing project ID and access policy, with DB and BUCKET storage bindings. Sites applies migrations during deployment. The current catalogue starts empty; add real products in Admin before order entry. Keep the site owner-private until public launch hardening is complete.

## Remaining work before a public store launch

Connect the storefront to product and order APIs; add product variations, fulfillment tracking, coupons, reporting, audit logs for product/settings edits, customer tracking tokens and abuse rate limiting. Payment, SMS, transactional email and courier APIs are not connected. Image upload compression is not yet implemented. No live customer data has been imported.

## Backup and recovery

Source code is versioned in the Site repository; source versions do not back up order data. A verified database/R2 export and restore workflow is still required before accepting real customer orders. Do not assume redeploying an older source version rolls back the database. Preserve applied migrations and use forward fixes.

## Staff onboarding

In Admin → Staff & permissions, add the staff member’s exact ChatGPT sign-in email and select permissions. Separately invite that person through the private Site’s sharing controls with the same email. Application role creation does not send messages or modify the Site access policy. Moderator defaults allow product reading, order creation, own-order reading/editing and courier reading. Admin defaults include store management but exclude staff management; the Owner may explicitly grant it. Fulfillment defaults allow reading all orders and changing statuses. Custom permissions are enforced on every API request, including record-level checks for own orders. Disable accounts to revoke application access immediately on the next request.

## Courier and invoices

Add couriers manually with an optional HTTPS tracking URL template containing {tracking}. Assign courier during POS entry or order editing, then enter the consignment number before dispatch. This does not book parcels with the courier. Every saved order has a deterministic invoice number based on its full unique order ID. Invoice line items retain the SKU and price snapshot from order creation. An invoice is not a payment receipt; collection is not verified. Existing historical order items may have no SKU snapshot. Order edits currently cover customer/address/zone/notes/courier, not item or price changes.

## Order filters and reports

Order lists filter server-side by date, current status, channel, courier, customer/order/phone/consignment search, with 100-row pagination. Status categories retain counts across the other active filters. Reports aggregate all matching records instead of a list-page subset and require reports.read. Non-owner staff additionally remain limited to their own orders unless granted orders.read.all. Existing staff accounts need an explicit reports.read grant; owner access includes it automatically.

Date boundaries and daily buckets use Asia/Dhaka (UTC+6). Date basis can be order creation or latest status-history event matching the order’s current status. This is a current-state report, not an immutable historical ledger: a later return moves a previously delivered order into Returned. Delivered product sales exclude delivery fees. Placed order values include every filtered order and are not recognized revenue. Returned values are product totals, not verified refunds. No net profit or cash collection is asserted. Daily CSV includes the selected date basis. Courier tracking links remain manual; live courier API tracking requires identifying the provider and configuring approved credentials.

Courier records now have a validated manual/carrybee/pathao provider field. Admin enable buttons add or update matching courier records for order selection without creating shipments, sending messages, configuring credentials, or claiming live API access. Both providers still require their approved API specifications and merchant access before adapters can be implemented and tested.

## Admin usability improvements

Dashboard includes today's order/value summary, current status work queue and low-stock active products (threshold 5). Product list supports SKU/name/category search and stock/status filters. POS drafts use tab-local sessionStorage keyed by the signed-in user, preserve the order request key, and clear after successful submission or explicit reset. No courier credential form data is stored in sessionStorage. Phone entry accepts Bengali digits, spaces and +880/880 prefixes and stores a normalized Bangladesh number. Customer history and duplicate-order advisories respect own/all-order permissions and do not block customers automatically. Product and shipping edits are audited; concurrent order edits/status changes report conflicts instead of claiming a successful change.

## CarryBee credential storage

Owner-only API credential form separates production and sandbox, fixes the corresponding API base URLs to the supplied merchant-panel reference, and encrypts Client ID/Secret/Context with AES-GCM. COURIER_ENCRYPTION_KEY is a hosted secret; it is never committed or returned to browsers. Preserve this key when backing up/restoring encrypted records. Blank fields retain previously saved values. The read endpoint returns save status only, never stored credentials. Staff management permission does not grant credential access. Live verification, authentication, booking and tracking are intentionally not implemented until the provider's official documentation is supplied. No real courier credentials have been imported or used; no shipments have been created. Pathao still uses manual configuration pending its verified integration.


## Operations upgrade

POS uses explicit Add product, per-line quantity, removal and up to 30 distinct product/variant lines (quantity max 50 per line, subject to stock). Draft restores selected rows and advances. Variant products link to a base product, have independent SKU/price/stock, and store their label in the order snapshot. Keep non-sellable base products in Draft. This is the first variant-management implementation; there is no storefront variant picker yet.

Payments are a manual append-only ledger of Advance, Collection and Refund, with references and request keys. Database guards reject overpayment and refunds above net receipts. Financial records currently use whole BDT. Closed orders have no further due; unrefunded receipts are shown as credit for review rather than automatically refunded. No real money is moved. Initial courier collectible subtracts original recorded advances and does not allocate subsequent refunds. Settlement is a separate cumulative manual record per order: collection minus delivery/COD/return fees minus net remitted. Negative net remitted means paid to courier. It never automatically changes the customer payment ledger.

Follow-ups store Bangladesh-time next-contact dates, reasons and notes; queues exclude completed/closed orders. There is no automatic notification. Packing checks are per order item; database guards require all lines checked before Packed or Dispatched and prevent editing checks after dispatch. Return completion requires a recorded reason. Return reports aggregate whole-order return requests/returns by reason, channel and SKU, with the existing date/permission rules.

Bulk status and courier assignment act sequentially on selected visible-page orders and show each result. Each request retains server authorization and normal state rules; failures do not undo successful independent orders. Bulk courier assignment is limited to pre-dispatch orders without a consignment and preserves existing money totals. Print up to 50 invoices or packing slips in one browser document. Quick-message templates are editable text with copy only; no messaging integration is invoked.

Courier verification stores exact panel status, explicit mapped status, courier, consignment, reference, checker and time. Evidence entered through this interface is always Manual, even if the caller submits a different source. Matching is recomputed against the store status and current courier/consignment; mismatches, missing evidence and unmapped statuses have separate queues. Explicit reconciliation uses only the latest applicable evidence and the normal state/packing/return rules. It does not claim API verification. No remote courier adapter or webhook is connected yet.

New rights: payments.write, packing.write, courier.verify, settlements.write. Owner always has them; stored staff permissions are not silently expanded. The owner must grant new rights to existing staff as appropriate. Fulfillment role preset includes packing.write; Admin preset includes operational rights, excluding staff management by default.

Validation: isolated Worker API tests cover multi-item totals/advances, ledger idempotency/refund limits, variant stock, mandatory packing, courier mismatch/reconciliation, settlement arithmetic, return reasons/restocking, existing report/security regressions. Browser UI fixture checks cover adding two products, quantity/advance calculations, draft restoration and bulk controls. No fixture, sample customer record or test credentials are deployed. Full provider/live-payment testing remains pending.


## Short references, shipping readiness and weights

Stable short order numbers remain transactionally generated. New orders always start Pending, then Processing → Ready to Ship → In-Transit → Delivered, with On Hold, Cancelled and return branches. Historical Confirmed/Packed/Dispatched records remain readable and supported. Packing and known product weights gate readiness. No automatic courier booking occurs at order creation.

Set unit weight in grams once per product/variant. New order lines snapshot that value and total weight is the sum of unit weight × quantity. Order forms have no manual weight field; submitted weight overrides are ignored. Legacy missing line weights are filled from product configuration when transitioning to shipping readiness; known snapshots remain stable even when product weights change. Missing weights block readiness. Existing dispatched historical records keep their stored weight until explicitly transitioned through a supported state. Unit packaging should be included in product weights; no extra packaging allowance is invented.

The Ready to Ship operations panel shows a disabled Send to Courier control with the missing setup reason. The server rejects pre-ready sends and duplicate consignments. Official CarryBee/Pathao booking, tracking and payment API contracts plus verified credentials are still required; no live provider adapter is implemented. API payment status is explicitly Not synced; manual settlement has a separate label. No successful shipment or API verification is fabricated. courier.book is a new permission; existing staff grants are preserved.

## Manual discounts

POS/DM creation supports whole-BDT discounts with orders.edit permission. Every order's operations screen supports changing/resetting a manual discount, with a required reason and audit entry. Discount ranges from zero to product subtotal; shipping is not discounted. Total = subtotal − discount + shipping. Invoices, due, collectible estimates, reports and delivery-area edits use discounted totals. Open orders cannot be reduced below net receipts: refund excess receipts first. Discount edits on existing courier consignments do not update the provider's booked COD amount; reconcile that separately. Product prices and stock snapshots remain unchanged. All financial values remain whole BDT.

Validated through isolated Worker API tests for discount authorization/bounds/audit/receipt floor, preserved discounts on delivery edits, automatic multi-product weights and snapshots, missing-weight readiness, Pending-first shipping and unconfigured-provider rejection, plus existing operational/report/security regressions.

Browser fixture QA confirmed two products at quantities 2 and 1 produce 350 g, a BDT 50 discount produces total/due BDT 660 including BDT 60 delivery, and draft reload retains quantities and discount. Temporary fixtures were removed before production build.


## Return receiving and courier inquiries

New Returned transitions create a return case with courier/consignment snapshots and do not restock inventory. Cancellation retains its one-time release behavior. Return receiving queue supports original INV, SIO or RMA references, tracking, customer and phone search, and awaiting/inspected/inquiry/legacy filters (500-result cap). Each return keeps its original invoice and a printable return receipt/claim pack; no second sales invoice/order is created.

Receiving records every order line as good, damaged or missing, with exact quantities, handover/loss reference, inspector/time, notes and up to eight R2 evidence photos. Lost parcel inspection marks every unit missing. Single transaction and unique line keys prevent duplicate receiving/restock; inspection quantities are immutable. Only good units return to inventory, and damage/missing quantities open separate inquiries. Evidence can be appended later within the same cap. Uploaded evidence is validated as JPG/PNG/WebP up to 4 MB per image. Claims have manually recorded Open/Submitted/Investigating/Approved/Rejected/Paid/Closed states, requested and paid BDT amounts, courier reference, follow-up/resolution, and full append-only status/value/note history. Closing may credit verified recovered good units once; closed cases cannot reopen. Compensation is a separate manual claim record and does not alter payments/settlements. No automatic courier claim transmission, liability decision, or payment verification occurs.

Legacy Returned orders without a new case were already restocked by the prior workflow. They are explicitly marked inventory review, and inspection/recovery adds no stock again. Existing inventory is not retroactively decremented because units may already have been sold; reconcile legacy damage/missing quantities separately in product inventory. No historical receipt evidence is fabricated.

New rights returns.read, returns.receive, claims.manage are automatically available to owner and the Admin preset; Fulfillment preset gets return read/receive. Existing staff grants remain unchanged; own-order scope is enforced unless orders.read.all is granted. Native Site sharing remains a separate access layer. Current customer refunds remain separate from return receiving.

Worker tests cover awaiting queue, no early restock, mixed/clean/lost receipts, invalid and duplicate receiving, good-only stock/recovery exactly once, claim history, compensation isolation, evidence URL validation, invoice search, permissions and legacy double-credit protection, plus prior regressions.

Browser UI fixture QA verified return queue navigation, original invoice reference, two-product mixed inspection (2 good, 1 damaged), successful receipt display, separate damaged-item claim form and printable claim pack. All fixtures removed before build.


## Public COD launch

Storefront reads active products and current delivery fees from the real API, including per-variant names/SKUs, uploaded photos, stock, categories and product descriptions. Demo sale products/prices were removed. Decorative hero illustration is retained, with neutral missing-photo and empty-catalogue states. Admin product publish/archive/stock changes feed the store. Browser bag stores only IDs/quantities, validates stale entries and enforces stock/quantity limits in UI. Server remains authoritative for prices, weights, stock and totals.

Anonymous checkout submits Website COD orders as Pending, without staff access or courier creation. Customer consent links show return/exchange and factual privacy notice; only COD is offered. Confirmation returns a short reference, total and real status. An interrupted response preserves the exact payload/request key in tab session storage for retry, including recovery after reload, preventing a second order from an identical request. Recovery expires after 24 hours and is cleared on success. Signed-in non-staff visitors remain normal anonymous-capability shoppers. Public submissions cannot set discount, courier or advance. Same-phone Website orders are capped at five per rolling hour (checked after idempotent replay), and a honeypot rejects filled bot-only input. This is basic abuse mitigation, not CAPTCHA/OTP verification.

Admin UI requires ChatGPT sign-in plus owner/staff authorization; every admin endpoint enforces its permission and own/all-order scope. Public product photos are served normally. New return evidence uses separate /api/return-media URLs and R2 returns/ prefix; uploader metadata plus staff/record scope protect reads with private,no-store. Existing unclassified media paths that appear as return evidence are protected as well, so public Site access does not publish return inspection images. Original product photos referenced by catalogue remain public. No credentials, order/customer records, inquiry packs, audit data or staff directory are added to public endpoints.

Validation: isolated Worker tests cover anonymous order persistence, source/discount/courier/advance rejection, authoritative totals/weights, short references, idempotency after phone rate limit, admin endpoint denial, and public-product/private-new-and-legacy-evidence image access. Browser fixture QA covered two-product bag, outside-Dhaka total BDT570, policy checkbox, simulated interrupted submission and identical retry yielding one confirmation. Fixture data/files are not deployed and no live customer/test order was created during QA. Online payment, SMS and live courier adapters remain unconfigured. Domain was explicitly deferred; launch uses the existing Site URL.


## Full catalogue and customer pages

Dedicated URLs: /shop, /categories, /category/{slug-or-legacy-name}, /product/{slug-or-id}, /wishlist, /cart and /checkout. Original brand theme is retained. Home adds category discovery and up to eight active product cards. Product pages provide shareable links, breadcrumb, up to eight gallery photos with cover/thumbnail switching and full-size image links, short and full descriptions, materials, dimensions, care, tags, original/selling price display with calculated discount, per-SKU stock, sibling variant selection, quantity, Add to bag, Buy now, related products and real delivery fees. No product facts, reviews or ratings are invented. Stock and pricing remain server-authoritative.

Shop/category lists include search by name/variant/SKU/tags, min/max price, stock filter, name/price sorting and 24-item pagination. Query URLs preserve filtering. Wishlist stores up to 100 product IDs in this browser; it does not provide customer accounts or cross-device sync. Cart/checkout have direct URLs and use the shared bag/checkout dialog. Shipping, FAQ, ordering information, contact, about, privacy and return/exchange pages are linked. COD checkout and all existing backend operations remain intact; online payment/SMS/live courier integrations remain pending.

Admin product editor adds slug, short description, structured content fields, original price, tags and an eight-photo gallery with cover selection/removal. Existing integrations that omit new catalogue fields preserve their old saved values. Legacy products without slugs use their stable ID URL until edited; no data backfill is fabricated. Category management uses existing product read/write rights, supports name/description/cover/URL/display order/visibility, and renames matching product category names transactionally. Unmanaged existing categories are discovered from active products automatically. Category visibility affects category navigation, while product publication remains controlled by each product status. Changing a product URL slug intentionally changes that link; old slug redirects are not provided.

Product pages render initial escaped product details plus canonical metadata and Product/Offer JSON-LD. Archived/draft/unknown products and unknown categories return real 404 responses. Dynamic catalogue routes use no-store, protecting current stock/content from stale page caching. Product images remain public; return evidence authorization remains unchanged.

Validation: Worker tests cover new data fields, gallery/original-price bounds, active-only details, category discovery/rename/permissions, safe product metadata/JSON-LD, valid/invalid route status, preserved legacy edits and previous operational/security/report suites. Browser fixture QA verified gallery selection, variant options, quantity-to-cart totals, wishlist, combined search/price/stock filters, admin structured fields and cover-photo retention after another photo is removed. All QA files/photos were deleted before final build; no demo product content is published.


## Premium storefront presentation

Warm ivory/deep forest/olive palette, self-hosted Latin Modern serif/italic/sans typography (license included), decorative code-native Siore botanical hero artwork, refined spacing, product/category cards, hover treatment, gallery, forms, policy pages, footer and cart/checkout drawer. Product photos retain their original colors and use contain sizing. No sample product image is added to the catalogue.

Progressive mobile menu supports aria-expanded, Escape/outside close and active links; navigation remains visible if enhancement JS is unavailable. IntersectionObserver reveals are progressive and content remains visible without JS, in print and under prefers-reduced-motion. Motion includes subtle button/image states, drawer entry, reveal transitions and desktop-only decorative hero movement. The admin/backend/order logic is unchanged.

QA: desktop homepage screenshot, 390px iframe layout and menu open/close, mobile product add-to-bag and cart-to-checkout total BDT260, plus existing isolated Worker API suite. Temporary mobile fixtures removed before final build. Native production publication is verified through Sites; earlier direct automated access encountered edge 403 and is not used to claim independent public-browser verification.
