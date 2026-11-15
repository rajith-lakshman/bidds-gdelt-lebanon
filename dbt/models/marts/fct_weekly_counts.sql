-- Weekly counts and tone: the first dataset downloaded in the paper.
with case_weekly as (
    select
        iso_year,
        iso_week,
        count(*)                                        as merged_events,
        countif(has_case_theme)                         as case_theme_events,
        countif(has_protest_theme)                      as protest_theme_events,
        countif(has_url_keyword)                        as url_keyword_events,
        countif(has_case_theme or has_url_keyword)      as any_case_signal_events,
        avg(if(has_case_theme, avg_tone, null))         as case_theme_avg_tone
    from {{ ref('int_lebanon_events_grouped') }}
    group by iso_year, iso_week
),

all_events as (
    select
        extract(isoyear from event_date)                       as iso_year,
        extract(isoweek from event_date)                       as iso_week,
        count(*)                                               as total_events,
        countif(cast(event_root_code as string) = '14')        as protest_code_events
    from {{ ref('stg_gdelt__events') }}
    where event_date between date('{{ var("start_date") }}') and date('{{ var("end_date") }}')
    group by iso_year, iso_week
)

select
    a.iso_year,
    a.iso_week,
    a.total_events,
    a.protest_code_events,
    coalesce(c.merged_events, 0)            as merged_events,
    coalesce(c.case_theme_events, 0)        as case_theme_events,
    coalesce(c.protest_theme_events, 0)     as protest_theme_events,
    coalesce(c.url_keyword_events, 0)       as url_keyword_events,
    coalesce(c.any_case_signal_events, 0)   as any_case_signal_events,
    c.case_theme_avg_tone
from all_events as a
left join case_weekly as c
    on a.iso_year = c.iso_year and a.iso_week = c.iso_week
order by a.iso_year, a.iso_week
