-- MTC / TOTS-OS final billing reconciliation
-- Safe pre-cutover reconciliation. This does NOT collect money or stop TeamUp.
begin;

-- 1) Finalise ONLY the seven previously proposed/approved billing dates.
with approved_dates(email, customer_name, next_payment_at) as (
  values
    ('arkeddie23@gmail.com', 'Alex Keddie', '2026-10-11T18:24:16Z'::timestamptz),
    ('hesso018@gmail.com', 'Chris Van', '2026-10-28T00:15:45Z'::timestamptz),
    ('erikajaynewilliams@hotmail.co.uk', 'Erika-Jayne Todd', '2026-10-02T08:37:55Z'::timestamptz),
    ('j.a.beattie@sky.com', 'James Beattie', '2026-10-15T18:28:51Z'::timestamptz),
    ('laurenw99@hotmail.co.uk', 'lauren williams', '2026-10-28T00:16:23Z'::timestamptz),
    ('michelle_5756@yahoo.co.uk', 'Michelle Brown', '2026-10-28T00:37:36Z'::timestamptz),
    ('salwayolivia@gmail.com', 'Olivia Salway', '2026-10-28T00:16:15Z'::timestamptz)
)
update public.store_subscriptions s
set next_payment_at = a.next_payment_at,
    metadata = coalesce(s.metadata, '{}'::jsonb) || jsonb_build_object(
      'mtc_proposed_next_payment_at', to_char(a.next_payment_at at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'mtc_next_payment_requires_confirmation', false,
      'mtc_next_payment_finalised_from_proposal', true,
      'mtc_next_payment_finalised_at', now(),
      'mtc_next_payment_finalised_source', 'migration_approval'
    ),
    migration_notes = concat_ws(' | ', nullif(s.migration_notes,''),
      'Next billing date finalised from the existing migration proposal under explicit migration approval. TeamUp remains active; TOTS collection remains OFF.'),
    updated_at = now()
from approved_dates a
where s.organisation_id = '2c96d537-2be4-4917-8982-e7491300f15f'::uuid
  and lower(trim(coalesce(s.customer_email,''))) = lower(a.email)
  and coalesce(s.unit_amount_pence,0) > 0
  and lower(coalesce(s.billing_interval,'')) in ('week','month','year')
  and coalesce(s.collection_enabled,false) = false;

-- 2) Current GoCardless export evidence.
create temporary table _mtc_gc_evidence (
  customer_id text not null, mandate_id text not null, payer_email text not null,
  payer_name text not null, charge_date date not null, payment_amount_pence integer not null,
  payment_status text not null, payment_description text not null
) on commit drop;

insert into _mtc_gc_evidence
(customer_id,mandate_id,payer_email,payer_name,charge_date,payment_amount_pence,payment_status,payment_description)
values
    ('CU0052RKJ0Q0X2', 'MD003R3HNPQW4V', 'jen_brown20.05@icloud.com', 'Jennifer Brown', '2026-09-30', 6900, 'submitted', 'Membership Payment: 3 Per Week'),
    ('CU01KCHV8MKZVS', 'MD01K9C3MYNMKG', 'jennifer.m.clarke4@gmail.com', 'Jennifer Clarke', '2026-09-10', 4900, 'paid_out', 'Membership Payment: 3 Per Week'),
    ('CU01MCXX1V7WEK3BD0VG0ZHQ41TS', 'MD01M2FBZ9CDSS7P61CQDDWSS6RZ', 'l_mackay@hotmail.co.uk', 'Laura Downie', '2026-09-30', 7000, 'submitted', 'Membership Payment: 4 Per Week'),
    ('CU0057AP0KX0TM', 'MD003TSPCA157S', 'abbey_emmett@yahoo.com', 'Abbey Emmett', '2026-09-30', 8900, 'submitted', 'Membership Payment: Unlimited membership'),
    ('CU005FMNC31NP5', 'MD0040058SWJW6', 'beccaxx_@hotmail.co.uk', 'Rebecca Farquhar', '2026-09-30', 8900, 'submitted', 'Membership Payment: 3 Per Week'),
    ('CU01M7SF44ZJJ3NMQABXT9X598ZB', 'MD01KXAXXGY8XXM1ADMKJHNGEDWG', 'rpboyd@hotmail.co.uk', 'Rhiannon Farquhar', '2026-09-30', 6900, 'submitted', 'Membership Payment: 3 Per Week'),
    ('CU01MDJVZNWWEEESYYQRDM7NVPSM', 'MD01M34AS3EBXXJ024Q9N6P7G9AA', 'siobhanforde@hotmail.com', 'Siobhan Forde', '2026-09-30', 4500, 'submitted', 'Membership Payment: CrossFit Preteens'),
    ('CU01M6X1J8F3DXY6CJT1VXSW86AW', 'MD01KWEGDVHTV43KZBZ4TH3W602K', 'audrey.hilsden@hotmail.com', 'Audrey Hilsden', '2026-09-01', 4500, 'paid_out', 'Membership Payment: CrossFit Preteens'),
    ('CU01KV589DBQ6H', 'MD01KJ9CAGA89T', 'karina.kaluzna1994@gmail.com', 'Karina Kaluzna', '2026-09-30', 5900, 'submitted', 'Membership Payment: 3 Per Week'),
    ('CU01M4D99XFPXM2GTSMSCMA16H49', 'MD01KSYRB8A3G7BPD6M5YV83SYSC', 'heatherjeankeddie@gmail.com', 'Heather Keddie', '2026-09-30', 6000, 'submitted', 'Membership Payment: 3 Per Week'),
    ('CU01MDGG5C4TB7B215TNPH5WJE81', 'MD01M31Z04NAZBQDA92HY1EDQMSS', 'nyreelewis70@gmail.com', 'NYREE LEWIS', '2026-10-02', 5900, 'submitted', 'Membership Payment: 3 Per Week'),
    ('CU01MCS2VA0B83P9PKRV420P3E79', 'MD01M2AHVV96T4WG82D98BP527NN', 'deborah.luce83@gmail.com', 'Deborah Luce', '2026-09-30', 6900, 'submitted', 'Membership Payment: 3 Per Week'),
    ('CU01KGW1YQHAH3', 'MD01KC2JV7E9F5', 'smears4@icloud.com', 'Stephen Mears', '2026-09-30', 6900, 'submitted', 'Membership Payment: 3 Per Week'),
    ('CU005A017P3RM4', 'MD003WDXMXPFKE', 'phil@philmitchell.net', 'Philip Mitchell', '2026-09-30', 6900, 'submitted', 'Membership Payment: 3 Per Week'),
    ('CU01MDE1BRJ67MW4RHCMB7RWTWD9', 'MD01M2ZG608D52A43K0Z819DPNRD', 'natalie_munro@sky.com', 'Natalie Munro', '2026-09-30', 5900, 'submitted', 'Membership Payment: 3 Per Week'),
    ('CU003D5H03A5JS', 'MD002R0A87VJHA', 'planetjo@hotmail.com', 'Joanne Napier', '2026-09-30', 5500, 'submitted', 'Membership Payment: 3 Per Week'),
    ('CU005DCE7TPZ1D', 'MD003YJT9T0CGD', 'hsu80f@hotmail.co.uk', 'Charlotte Owens', '2026-09-30', 6900, 'submitted', 'Membership Payment: 3 Per Week'),
    ('CU01MCPP8RMHGNR8WC7BPDMZHZAV', 'MD01M2852YXYXCWRV04QZPD22NG1', 'trishka@hotmail.co.uk', 'Trisha Riddell', '2026-09-30', 9900, 'submitted', 'Membership Payment: Couples 3x'),
    ('CU01MBSTKR9ETP3RP455VP7FXV0W', 'MD01M1B9E4YKP0TPMC30JBGSS9YB', 'stefanie.stewart1412@gmail.com', 'Stefanie Stewart', '2026-09-30', 7900, 'submitted', 'Membership Payment: 3 Per Week'),
    ('CU01MBV5RVFCP7P4YSYT6YX484KY', 'MD01M1CMJJFW13F1XC3ZWWW4E0GK', 'craigstrathdee99@outlook.com', 'Craig Strathdee', '2026-09-30', 4900, 'submitted', 'Membership Payment: Offshore special'),
    ('CU005HR9CCAPB0', 'MD0041CGRNYYKR', 'rachel.swinglehurst@hotmail.com', 'Rachel Swinglehurst-Hewkin', '2026-09-30', 5900, 'submitted', 'Membership Payment: 3 Per Week'),
    ('CU003J4VAW0RT4', 'MD002TRWVDC7GV', 'yasmintodd93@hotmail.com', 'Yasmin Todd', '2026-09-30', 4900, 'submitted', 'Membership Payment: 3 Per Week'),
    ('CU01K7JX1MDJYX', 'MD01K6551GSHKQ', 'hweir84@gmail.com', 'Holly Weir', '2026-09-30', 6900, 'submitted', 'Membership Payment: 3 Per Week'),
    ('CU01M6697NGKN58V457SMGFJM6SR', 'MD01KVQR2K13F3PEXM9ZKW461ZTY', 'jamie.wilding1@hotmail.co.uk', 'Jamie Wilding', '2026-09-30', 2500, 'submitted', 'Membership Payment: CF Kids & Pre Teens \u2014 1 Per Week'),
    ('CU0057VZWHW2B7', 'MD003V49GM6QN1', 'sarahmac0787@googlemail.com', 'Sarah Wu', '2026-09-30', 5900, 'submitted', 'Membership Payment: 3 Per Week');

-- Persist exact ID/email matches. Membership amount is NOT overwritten.
with matched as (
  select distinct on (s.id) s.id, e.*
  from public.store_subscriptions s
  join _mtc_gc_evidence e on (
    s.external_customer_id=e.customer_id
    or s.external_mandate_id=e.mandate_id
    or lower(trim(coalesce(s.customer_email,'')))=lower(e.payer_email)
  )
  where s.organisation_id='2c96d537-2be4-4917-8982-e7491300f15f'::uuid
    and coalesce(s.unit_amount_pence,0)>0
    and lower(coalesce(s.billing_interval,'')) in ('week','month','year')
  order by s.id,
    case when s.external_mandate_id=e.mandate_id then 1
         when s.external_customer_id=e.customer_id then 2 else 3 end
)
update public.store_subscriptions s
set payment_provider='gocardless',
    billing_provider='gocardless',
    external_customer_id=m.customer_id,
    external_mandate_id=m.mandate_id,
    processor_verification_status='verified',
    processor_verified_at=now(),
    last_payment_at=m.charge_date::timestamptz,
    last_payment_amount_pence=m.payment_amount_pence,
    collection_enabled=false,
    teamup_billing_active=true,
    metadata=coalesce(s.metadata,'{}'::jsonb)||jsonb_build_object(
      'mtc_gocardless_export_verified',true,
      'mtc_gocardless_export_verified_at',now(),
      'mtc_gocardless_export_match','exact_id_or_email',
      'mtc_gocardless_export_customer_id',m.customer_id,
      'mtc_gocardless_export_mandate_id',m.mandate_id,
      'mtc_gocardless_export_charge_date',m.charge_date,
      'mtc_gocardless_export_amount_pence',m.payment_amount_pence,
      'mtc_gocardless_export_status',m.payment_status,
      'mtc_gocardless_export_description',m.payment_description,
      'mtc_gocardless_amount_differs_from_current_membership',
        coalesce(s.unit_amount_pence,0)<>m.payment_amount_pence
    ),
    migration_notes=concat_ws(' | ',nullif(s.migration_notes,''),
      format('GoCardless payer/mandate verified from supplied export (%s / %s; exported payment %sp; %s). No debit created. TeamUp remains active; TOTS collection remains OFF.',
        m.customer_id,m.mandate_id,m.payment_amount_pence,m.payment_status)),
    updated_at=now()
from matched m
where s.id=m.id;

-- Explicit known identity aliases only; no fuzzy matching.
with aliases(tots_name,gc_customer_id) as (
  values
    ('Macaulay Watson','CU01MDJVZNWWEEESYYQRDM7NVPSM'),
    ('Yasmin Todd','CU003J4VAW0RT4')
),
matched as (
  select s.id,e.*
  from public.store_subscriptions s
  join aliases a on lower(trim(s.customer_name))=lower(a.tots_name)
  join _mtc_gc_evidence e on e.customer_id=a.gc_customer_id
  where s.organisation_id='2c96d537-2be4-4917-8982-e7491300f15f'::uuid
    and coalesce(s.unit_amount_pence,0)>0
    and lower(coalesce(s.billing_interval,'')) in ('week','month','year')
)
update public.store_subscriptions s
set payment_provider='gocardless', billing_provider='gocardless',
    external_customer_id=m.customer_id, external_mandate_id=m.mandate_id,
    processor_verification_status='verified', processor_verified_at=now(),
    last_payment_at=m.charge_date::timestamptz,
    last_payment_amount_pence=m.payment_amount_pence,
    collection_enabled=false, teamup_billing_active=true,
    metadata=coalesce(s.metadata,'{}'::jsonb)||jsonb_build_object(
      'mtc_gocardless_export_verified',true,
      'mtc_gocardless_export_verified_at',now(),
      'mtc_gocardless_export_match','explicit_migration_alias',
      'mtc_gocardless_export_customer_id',m.customer_id,
      'mtc_gocardless_export_mandate_id',m.mandate_id,
      'mtc_gocardless_export_charge_date',m.charge_date,
      'mtc_gocardless_export_amount_pence',m.payment_amount_pence,
      'mtc_gocardless_export_status',m.payment_status,
      'mtc_gocardless_export_description',m.payment_description,
      'mtc_gocardless_amount_differs_from_current_membership',
        coalesce(s.unit_amount_pence,0)<>m.payment_amount_pence
    ),
    migration_notes=concat_ws(' | ',nullif(s.migration_notes,''),
      format('GoCardless payer/mandate verified using explicit migration payer mapping (%s / %s). No debit created. TeamUp remains active; TOTS collection remains OFF.',
        m.customer_id,m.mandate_id)),
    updated_at=now()
from matched m where s.id=m.id;

-- 3) Canonicalise exact duplicate paid recurring rows.
-- IMPORTANT: do not set cutover_status='duplicate'; that value violates your DB constraint.
with candidates as (
  select s.*,
    lower(regexp_replace(trim(coalesce(s.customer_name,'')),'[^a-zA-Z0-9]+',' ','g')) n_name,
    lower(trim(coalesce(s.customer_email,''))) n_email,
    lower(trim(coalesce(s.legacy_membership_name,''))) n_membership,
    lower(trim(coalesce(s.billing_interval,''))) n_interval
  from public.store_subscriptions s
  where s.organisation_id='2c96d537-2be4-4917-8982-e7491300f15f'::uuid
    and coalesce(s.unit_amount_pence,0)>0
    and lower(coalesce(s.billing_interval,'')) in ('week','month','year')
    and lower(trim(coalesce(s.customer_name,'')))<>'farrah-rose brodie'
    and not (
      coalesce(s.metadata,'{}'::jsonb) @> '{"mtc_redundant_duplicate":true}'::jsonb
      or coalesce(s.metadata,'{}'::jsonb) @> '{"mtc_duplicate_record":true}'::jsonb
      or lower(coalesce(s.migration_notes,'')) like '%do not collect:%duplicate%'
    )
),
ranked as (
  select id,
    first_value(id) over (
      partition by n_name,n_email,n_membership,unit_amount_pence,n_interval
      order by (stripe_subscription_id is not null) desc,
               (processor_verification_status='verified') desc,
               (external_mandate_id is not null) desc,
               (external_customer_id is not null) desc,
               (next_payment_at is not null) desc,
               created_at asc nulls last,id
    ) canonical_id,
    row_number() over (
      partition by n_name,n_email,n_membership,unit_amount_pence,n_interval
      order by (stripe_subscription_id is not null) desc,
               (processor_verification_status='verified') desc,
               (external_mandate_id is not null) desc,
               (external_customer_id is not null) desc,
               (next_payment_at is not null) desc,
               created_at asc nulls last,id
    ) rn,
    count(*) over (partition by n_name,n_email,n_membership,unit_amount_pence,n_interval) group_count
  from candidates where n_name<>'' and n_membership<>''
)
update public.store_subscriptions s
set collection_enabled=false,
    metadata=coalesce(s.metadata,'{}'::jsonb)||jsonb_build_object(
      'mtc_redundant_duplicate',true,
      'mtc_duplicate_record',true,
      'mtc_duplicate_of_subscription_id',r.canonical_id,
      'mtc_duplicate_marked_at',now(),
      'mtc_duplicate_marked_by','supabase_final_reconciliation'
    ),
    migration_notes=concat_ws(' | ',nullif(s.migration_notes,''),
      format('DO NOT COLLECT: duplicate legacy billing record. Canonical subscription: %s.',r.canonical_id)),
    updated_at=now()
from ranked r
where s.id=r.id and r.group_count>1 and r.rn>1;

-- 4) Protect the known access-only child record.
update public.store_subscriptions s
set collection_enabled=false,
    metadata=coalesce(s.metadata,'{}'::jsonb)||jsonb_build_object(
      'mtc_access_only',true,'child_access_only',true,
      'mtc_independent_billing_excluded',true,
      'mtc_independent_billing_excluded_at',now()
    ),
    migration_notes=concat_ws(' | ',nullif(s.migration_notes,''),
      'DO NOT COLLECT independently: access-only dependent record. Billing remains with the responsible payer/guardian relationship.'),
    updated_at=now()
where s.organisation_id='2c96d537-2be4-4917-8982-e7491300f15f'::uuid
  and lower(trim(coalesce(s.customer_name,'')))='farrah-rose brodie';

commit;

-- 5) AUDIT RESULTS

-- Approved/finalised dates
select customer_name,customer_email,unit_amount_pence,next_payment_at,
       stripe_subscription_id,processor_verification_status,
       collection_enabled,teamup_billing_active,
       metadata->>'mtc_next_payment_finalised_from_proposal' finalised_from_proposal
from public.store_subscriptions
where organisation_id='2c96d537-2be4-4917-8982-e7491300f15f'::uuid
  and lower(trim(coalesce(customer_email,''))) in
  ('arkeddie23@gmail.com','hesso018@gmail.com','erikajaynewilliams@hotmail.co.uk',
   'j.a.beattie@sky.com','laurenw99@hotmail.co.uk','michelle_5756@yahoo.co.uk',
   'salwayolivia@gmail.com')
order by customer_name;

-- Verified GoCardless recurring records
select customer_name,customer_email,unit_amount_pence,legacy_membership_name,
       external_customer_id,external_mandate_id,last_payment_at,
       last_payment_amount_pence,processor_verification_status,
       collection_enabled,teamup_billing_active
from public.store_subscriptions
where organisation_id='2c96d537-2be4-4917-8982-e7491300f15f'::uuid
  and payment_provider='gocardless'
  and coalesce(unit_amount_pence,0)>0
  and lower(coalesce(billing_interval,'')) in ('week','month','year')
order by customer_name;

-- Duplicate rows excluded
select customer_name,customer_email,unit_amount_pence,legacy_membership_name,
       stripe_subscription_id,external_customer_id,external_mandate_id,
       metadata->>'mtc_duplicate_of_subscription_id' canonical_subscription_id,
       collection_enabled
from public.store_subscriptions
where organisation_id='2c96d537-2be4-4917-8982-e7491300f15f'::uuid
  and (
    coalesce(metadata,'{}'::jsonb) @> '{"mtc_redundant_duplicate":true}'::jsonb
    or coalesce(metadata,'{}'::jsonb) @> '{"mtc_duplicate_record":true}'::jsonb
  )
order by customer_name;

-- Safety: TOTS collection must still be zero tonight.
select
  count(*) filter (where collection_enabled=true) tots_collection_enabled,
  count(*) filter (where teamup_billing_active=false) teamup_marked_stopped
from public.store_subscriptions
where organisation_id='2c96d537-2be4-4917-8982-e7491300f15f'::uuid and legacy_billing=true;

-- Remaining genuine paid recurring records needing provider reconciliation.
select customer_name,customer_email,unit_amount_pence,billing_interval,
       legacy_membership_name,payment_provider,processor_verification_status,
       stripe_customer_id,stripe_subscription_id,
       external_customer_id,external_mandate_id,next_payment_at
from public.store_subscriptions
where organisation_id='2c96d537-2be4-4917-8982-e7491300f15f'::uuid
  and coalesce(unit_amount_pence,0)>0
  and lower(coalesce(billing_interval,'')) in ('week','month','year')
  and lower(trim(coalesce(customer_name,'')))<>'farrah-rose brodie'
  and not (
    coalesce(metadata,'{}'::jsonb) @> '{"mtc_redundant_duplicate":true}'::jsonb
    or coalesce(metadata,'{}'::jsonb) @> '{"mtc_duplicate_record":true}'::jsonb
  )
  and (
    processor_verification_status is distinct from 'verified'
    or (lower(coalesce(payment_provider,''))='stripe' and stripe_subscription_id is null)
    or (lower(coalesce(payment_provider,''))='gocardless'
        and (external_customer_id is null or external_mandate_id is null))
  )
order by customer_name;
