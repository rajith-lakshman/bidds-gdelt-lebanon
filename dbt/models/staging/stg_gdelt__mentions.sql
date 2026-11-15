select
    GLOBALEVENTID       as event_id,
    MentionIdentifier   as mention_url,
    MentionTimeDate     as mention_time,
    MentionSourceName   as source_name,
    MentionDocTone      as doc_tone
from {{ source('gdelt', 'eventmentions_partitioned') }}
where {{ in_window() }}
  and MentionType = 1
