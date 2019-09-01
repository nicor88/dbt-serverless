{{ config(
    materialized='incremental',
    unique_key='row_id'
    )
}}


select
    md5(cast(now() as varchar(36))) as row_id,
    now() as inserted_at
