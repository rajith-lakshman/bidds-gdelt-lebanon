select
    e.event_id, e.event_date, e.event_code, e.event_root_code,
    e.goldstein_scale, e.num_mentions, e.avg_tone,
    e.geo_type, e.geo_name, e.geo_adm1_code, e.geo_lat, e.geo_long,
    e.source_url,
    m.mention_url, m.mention_time, m.doc_tone,
    g.gkg_record_id, g.themes, g.tone
from {{ ref('stg_gdelt__events') }} as e
inner join {{ ref('stg_gdelt__mentions') }} as m
    on e.event_id = m.event_id
inner join {{ ref('stg_gdelt__gkg') }} as g
    on m.mention_url = g.document_url
