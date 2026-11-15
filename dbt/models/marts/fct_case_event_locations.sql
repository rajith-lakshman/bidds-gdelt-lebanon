-- Where case-theme events happened: the second dataset downloaded in the paper.
select
    geo_name,
    geo_adm1_code,
    geo_lat,
    geo_long,
    count(*) as events
from {{ ref('int_lebanon_events_grouped') }}
where has_case_theme
  and geo_lat is not null
group by geo_name, geo_adm1_code, geo_lat, geo_long
