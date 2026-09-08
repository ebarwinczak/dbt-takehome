-- remove excess spacing before, between, and after string text
-- if a cell is '', return NULL ('' are counted as values while NULL is not)
{% macro clean_string(col) %}
    NULLIF(REGEXP_REPLACE(TRIM({{ col }}), '\s+', ' ', 'g'), '')
{% endmacro %}