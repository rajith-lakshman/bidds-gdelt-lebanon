select
    GKGRECORDID         as gkg_record_id,
    DocumentIdentifier  as document_url,
    SourceCommonName    as source_name,
    V2Themes            as themes,
    V2Tone              as tone
from {{ source('gdelt', 'gkg_partitioned') }}
where {{ in_window() }}
