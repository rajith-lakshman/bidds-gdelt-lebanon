select
    GLOBALEVENTID                                   as event_id,
    parse_date('%Y%m%d', cast(SQLDATE as string))   as event_date,
    EventCode                                       as event_code,
    EventRootCode                                   as event_root_code,
    GoldsteinScale                                  as goldstein_scale,
    NumMentions                                     as num_mentions,
    AvgTone                                         as avg_tone,
    ActionGeo_Type                                  as geo_type,
    ActionGeo_FullName                              as geo_name,
    ActionGeo_ADM1Code                              as geo_adm1_code,
    ActionGeo_Lat                                   as geo_lat,
    ActionGeo_Long                                  as geo_long,
    SOURCEURL                                       as source_url
from {{ source('gdelt', 'events_partitioned') }}
where {{ in_window() }}
  and ActionGeo_CountryCode = '{{ var("country_code") }}'
