-- URLs of articles for case-theme events: the third dataset downloaded in the paper.
select
    d.mention_url                   as url,
    g.iso_year,
    g.iso_week,
    count(distinct d.event_id)      as events_linked
from {{ ref('int_lebanon_event_documents') }} as d
inner join {{ ref('int_lebanon_events_grouped') }} as g
    on d.event_id = g.event_id
where g.has_case_theme
group by 1, 2, 3
