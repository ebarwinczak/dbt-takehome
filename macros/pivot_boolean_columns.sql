{% macro pivot_boolean_columns(column, values) %}

    {% for value in values %}

        BOOL_OR(
            {{ column }} = '{{ value | replace("'", "''") }}'
        ) AS {{ value
            | lower
            | replace(' ', '_')
            | replace('-', '_')
            | replace('/', '_')
            | replace('\\', '_')
            | replace('&', 'and')
            | replace(',', '')
            | replace('.', '')
            | replace(':', '')
            | replace(';', '')
            | replace('’', '')
            | replace("'", '')
            | replace('"', '')
            | replace('(', '')
            | replace(')', '')
            | replace('[', '')
            | replace(']', '')
            | replace('{', '')
            | replace('}', '')
        }}

        {% if not loop.last %}
            ,
        {% endif %}

    {% endfor %}

{% endmacro %}