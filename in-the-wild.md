---
title: In the wild
nav_order: 4
permalink: /in-the-wild/
description: Real Row-Level Security fixes pgrls surfaced and contributed to open-source Postgres / Supabase projects.
---

# pgrls in the wild

Row-Level Security bugs are easy to write and hard to see — an unwrapped per-row
`auth.uid()`, a missing `WITH CHECK`, an anonymously-readable table, a cross-tenant
leak. pgrls surfaces them and `pgrls fix` writes the migration.

Below are real fixes it produced for open-source Postgres / Supabase projects.

## Merged upstream

Accepted by the maintainers.

| Project | ★ | What pgrls surfaced | Links |
|---|--:|---|---|
| [MODSetter/SurfSense](https://github.com/MODSetter/SurfSense) | 15,175★ | Scope index endpoint authorization | [#1503](https://github.com/MODSetter/SurfSense/pull/1503) |
| [miurla/morphic](https://github.com/miurla/morphic) | 8,949★ | Wrap `current_setting()` for per-statement eval | [#902](https://github.com/miurla/morphic/pull/902) |
| [gridaco/grida](https://github.com/gridaco/grida) | 2,548★ | Wrap `auth.uid()`, enable FORCE RLS | [issue](https://github.com/gridaco/grida/issues/873) · [#874](https://github.com/gridaco/grida/pull/874) |
| [crbnos/carbon](https://github.com/crbnos/carbon) | 2,240★ | Per-statement auth wrap (USING + WITH CHECK) | [issue](https://github.com/crbnos/carbon/issues/964) · [#965](https://github.com/crbnos/carbon/pull/965) |
| [moyangzhan/langchain4j-aideepin](https://github.com/moyangzhan/langchain4j-aideepin) | 1,319★ | Fix cross-user knowledge-base read | [issue](https://github.com/moyangzhan/langchain4j-aideepin/issues/104) · [#105](https://github.com/moyangzhan/langchain4j-aideepin/pull/105) |
| [elymsyr/dungeon-master-tool](https://github.com/elymsyr/dungeon-master-tool) | 107★ | Wrap auth calls across 56 policies | [#74](https://github.com/elymsyr/dungeon-master-tool/pull/74) |
| [usetrmnl/byos_next](https://github.com/usetrmnl/byos_next) | 89★ | Wrap the per-row session lookup | [issue](https://github.com/usetrmnl/byos_next/issues/81) · [#82](https://github.com/usetrmnl/byos_next/pull/82) |
| [kdpisda/django-rls](https://github.com/kdpisda/django-rls) | 88★ | RLS-hardening polish items | [issue](https://github.com/kdpisda/django-rls/issues/53) · [#54](https://github.com/kdpisda/django-rls/pull/54) |
| [OpenStudy-dev/OpenStudy](https://github.com/OpenStudy-dev/OpenStudy) | 69★ | Wrap RLS policy functions | [issue](https://github.com/OpenStudy-dev/OpenStudy/issues/2) · [#3](https://github.com/OpenStudy-dev/OpenStudy/pull/3) |
| [tutur3u/platform](https://github.com/tutur3u/platform) | 53★ | Wrap auth calls (incl. correlated EXISTS) | [#4907](https://github.com/tutur3u/platform/pull/4907) |

## In review

Open pull requests.

| Project | ★ | What pgrls surfaced | Links |
|---|--:|---|---|
| [onlook-dev/onlook](https://github.com/onlook-dev/onlook) | 26,111★ | Wrap auth calls in RLS policies | [#3121](https://github.com/onlook-dev/onlook/pull/3121) |
| [Helicone/helicone](https://github.com/Helicone/helicone) | 5,899★ | Wrap auth calls for per-statement eval | [#5705](https://github.com/Helicone/helicone/pull/5705) |
| [scosman/CMSaasStarter](https://github.com/scosman/CMSaasStarter) | 2,341★ | Wrap `auth.uid()` | [issue](https://github.com/scosman/CMSaasStarter/issues/212) · [#213](https://github.com/scosman/CMSaasStarter/pull/213) |
| [firecrawl/open-scouts](https://github.com/firecrawl/open-scouts) | 1,294★ | Wrap `auth.uid()` | [issue](https://github.com/firecrawl/open-scouts/issues/12) · [#13](https://github.com/firecrawl/open-scouts/pull/13) |
| [lucasastorian/llmwiki](https://github.com/lucasastorian/llmwiki) | 1,259★ | Wrap `auth.uid()` | [issue](https://github.com/lucasastorian/llmwiki/issues/63) · [#64](https://github.com/lucasastorian/llmwiki/pull/64) |
| [KolbySisk/next-supabase-stripe-starter](https://github.com/KolbySisk/next-supabase-stripe-starter) | 799★ | Wrap `auth.uid()` | [#31](https://github.com/KolbySisk/next-supabase-stripe-starter/pull/31) |
| [Kanba-co/kanba](https://github.com/Kanba-co/kanba) | 630★ | Wrap auth calls (USING + WITH CHECK) | [#32](https://github.com/Kanba-co/kanba/pull/32) |
| [supabase-community/chatgpt-your-files](https://github.com/supabase-community/chatgpt-your-files) | 514★ | Wrap `auth.uid()` | [#53](https://github.com/supabase-community/chatgpt-your-files/pull/53) |
| [10xapp/core-oss](https://github.com/10xapp/core-oss) | 436★ | Wrap `auth.uid()` for per-statement eval | [issue](https://github.com/10xapp/core-oss/issues/50) · [#51](https://github.com/10xapp/core-oss/pull/51) |
| [antoineross/Hikari](https://github.com/antoineross/Hikari) | 386★ | Harden RLS: wrap + index filters | [issue](https://github.com/antoineross/Hikari/issues/6) · [#7](https://github.com/antoineross/Hikari/pull/7) |
| [supabase-community/svelte-kanban](https://github.com/supabase-community/svelte-kanban) | 316★ | Harden RLS: wrap, index, FORCE | [issue](https://github.com/supabase-community/svelte-kanban/issues/25) · [#26](https://github.com/supabase-community/svelte-kanban/pull/26) |
| [nolly-studio/ai-chatbot-supabase](https://github.com/nolly-studio/ai-chatbot-supabase) | 290★ | Wrap auth calls (24 policies) | [#4](https://github.com/nolly-studio/ai-chatbot-supabase/pull/4) |
| [kizivat/saas-kit](https://github.com/kizivat/saas-kit) | 125★ | Wrap `auth.uid()` | [#7](https://github.com/kizivat/saas-kit/pull/7) |
| [GeronimoDiClemente/raven-nest](https://github.com/GeronimoDiClemente/raven-nest) | 30★ | Wrap auth calls (39 policies) | [#12](https://github.com/GeronimoDiClemente/raven-nest/pull/12) |
| [kindfi-org/kindfi](https://github.com/kindfi-org/kindfi) | 20★ | Wrap RLS policy functions | [issue](https://github.com/kindfi-org/kindfi/issues/906) · [#907](https://github.com/kindfi-org/kindfi/pull/907) |
| [getpact/pact](https://github.com/getpact/pact) | 20★ | Wrap `current_setting()` | [issue](https://github.com/getpact/pact/issues/6) · [#7](https://github.com/getpact/pact/pull/7) |
| [isaacsight/kernel](https://github.com/isaacsight/kernel) | 15★ | Wrap 131 policy auth calls | [#54](https://github.com/isaacsight/kernel/pull/54) |
| [arcadia-eternity/arcadia-eternity](https://github.com/arcadia-eternity/arcadia-eternity) | 9★ | Wrap RLS policy functions | [issue](https://github.com/arcadia-eternity/arcadia-eternity/issues/195) · [#196](https://github.com/arcadia-eternity/arcadia-eternity/pull/196) |

## Ecosystem

| Project | ★ | What pgrls surfaced | Links |
|---|--:|---|---|
| [drizzle-team/drizzle-orm](https://github.com/drizzle-team/drizzle-orm) | 35,019★ | Add `.forceRLS()` to the pgTable builder | [issue](https://github.com/drizzle-team/drizzle-orm/issues/5819) · [#5843](https://github.com/drizzle-team/drizzle-orm/pull/5843) |
| [analysis-tools-dev/static-analysis](https://github.com/analysis-tools-dev/static-analysis) | 14,656★ | List pgrls | [#1829](https://github.com/analysis-tools-dev/static-analysis/pull/1829) |
| [dhamaniasad/awesome-postgres](https://github.com/dhamaniasad/awesome-postgres) | 11,974★ | List pgrls | [#514](https://github.com/dhamaniasad/awesome-postgres/pull/514) |
| [supabase/splinter](https://github.com/supabase/splinter) | 252★ | Propose a lint for inverted-auth read policies | [issue](https://github.com/supabase/splinter/issues/165) · [#169](https://github.com/supabase/splinter/pull/169) |

---

Have an RLS issue pgrls could help with? `pip install pgrls && pgrls lint`, or
[open an issue](https://github.com/pgrls/pgrls/issues).
