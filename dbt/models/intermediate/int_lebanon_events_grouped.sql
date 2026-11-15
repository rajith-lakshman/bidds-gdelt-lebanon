-- One row per GDELT event (the grain of Annexe B step 2), with flags for
-- whether any article mentioning the event matches the case-study criteria.
select
    event_id,
    min(d.event_date)                        as event_date,
    extract(isoyear from min(d.event_date))  as iso_year,
    extract(isoweek from min(d.event_date))  as iso_week,
    any_value(event_root_code)               as event_root_code,
    any_value(avg_tone)                      as avg_tone,
    any_value(geo_name)                      as geo_name,
    any_value(geo_adm1_code)                 as geo_adm1_code,
    any_value(geo_lat)                       as geo_lat,
    any_value(geo_long)                      as geo_long,
    count(distinct mention_url)              as url_count,
    coalesce(logical_or(regexp_contains(themes, r'{{ var("theme_pattern") }}')), false)
                                             as has_case_theme,
    coalesce(logical_or(regexp_contains(themes, r'(^|;)PROTEST,')), false)
                                             as has_protest_theme,
    coalesce(logical_or(regexp_contains(lower(mention_url), r'{{ var("url_keywords") }}')), false)
                                             as has_url_keyword
from {{ ref('int_lebanon_event_documents') }} as d
group by event_id
having min(d.event_date) between date('{{ var("start_date") }}') and date('{{ var("end_date") }}')
