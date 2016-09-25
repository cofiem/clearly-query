# Query Hash Specification

Inspired by [Elastic Search filters](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-filters.html).

## Available Filter Operators

### Combine / logical Operators

     Operator |   Query hash   |       SQL
    ----------|----------------|---------------------
    and       | {and: { ... }} | WHERE ... AND  ...
    or        | {or:  { ... }} | WHERE ... OR  (...)
    not       | {not: { ... }} | WHERE ... NOT (...)
    
An implicit `and` operator is used when no logical operator is specified.

### Filter Operators

All filter operators have multiple forms to help with constructing queries that read more 'naturally'.
Be aware that it is possible operators may be 
'case sensitive by default for unicode characters that are beyond the ASCII range'. 
For example, in [sqlite](https://www.sqlite.org/lang_expr.html).

#### Comparison Operators

Comparison operators are self-explanatory. 

                   Operator              |         Query hash         |        SQL
    -------------------------------------|----------------------------|---------------------------------
    eq, equal                            | {attr: {eq: 'test'}}       | "table"."attr" = 'test'
    not_eq, not_equal                    | {attr: {not_eq: 'test'}}   | "table"."attr" != 'test'
    lt, less_than                        | {attr: {lt: 'test'}}       | "table"."attr" < 'test'
    not_lt, not_less_than                | {attr: {not_lt: 'test'}}   | "table"."attr" >= 'test'
    gt, greater_than                     | {attr: {gt: 'test'}}       | "table"."attr" > 'test'
    not_gt, not_greater_than             | {attr: {not_gt: 'test'}}   | "table"."attr" <= 'test'
    lteq, less_than_or_equal             | {attr: {lteq: 'test'}}     | "table"."attr" <= 'test'
    not_lteq, not_less_than_or_equal     | {attr: {not_lteq: 'test'}} | "table"."attr" > 'test'
    gteq, greater_than_or_equal          | {attr: {gteq: 'test'}}     | "table"."attr" >= 'test'
    not_gteq, not_greater_than_or_equal  | {attr: {not_gteq: 'test'}} | "table"."attr" < 'test'

#### Special Comparisons

There are special operators for `null` comparisons. 
The only valid values for these operators is `true` or `false`.

            Operator       |         Query hash         |        SQL
    -----------------------|----------------------------|---------------------------------
    null, is_null          | {attr: {null: true}}       | "table"."attr" IS NULL

#### Subset Operators

##### Range

A simple range can be specified from an inclusive lower bound and to an exclusive upper bound.

              Operator      |                      Query hash                     |                             SQL
    ------------------------|-----------------------------------------------------|------------------------------------------------------------------
    range, in_range         | {attr: {range: {from: 'value1', to: 'value2'}}}     | "table"."attr" >= 'value1' AND "table"."attr" < 'value2'
    not_range, not_in_range | {attr: {not_range: {from: 'value1', to: 'value2'}}} | ("table"."attr" < 'value1' OR "table"."attr" >= 'value2')
    
A more complex range can be specified using a special format which allows for inclusive or exclusive bounds.

       Operator  |                Query hash                 |                           SQL
    -------------|-------------------------------------------|----------------------------------------------------------
    interval     | {attr: {interval: '(value1,value2]'}}     | "table"."attr" > 'value1' AND "table"."attr" <= 'value2'
    not_interval | {attr: {not_interval: '(value1,value2]'}} | ("table"."attr" <= 'value1' OR "table"."attr" > 'value2')

The `interval` must match the regex  `/(\[|\()(.*),(.*)(\)|\])/`, 
where `(` or `)` indicates exclusive and `[` or `]` indicates inclusive.
Specifying `[value1,value2]` is equivalent to `BETWEEN value1 AND value2`.

Any spaces between the brackets will be included in the value.
The result of including commas (`,`) in either value is undefined. 
Use a single comma for separating the two values.

##### Array

An array of values to match the attribute value. Compared using an exact match (which may be case sensitive, depending on the database).

    Operator |            Query hash                  |                             SQL
    ---------|----------------------------------------|-----------------------------------------------
    in       | {attr: {in: ['value1', 'value2']}}     | "table"."attr" IN ('value1', 'value2')
    not_in   | {attr: {not_in: ['value1', 'value2']}} | "table"."attr" NOT IN ('value1', 'value2')
    
##### Contents Match

A variety of ways to match the contents of model attribute content. 
These comparison operators are case insensitive where possible (again, depends on the database).
It is possible to match the entire content, at the start of the content, at the end, or using a regular expression.

Regular expression match may not be supported by all databases.

                        Operator                          |           Query hash              |                SQL
    ------------------------------------------------------|-----------------------------------|-----------------------------------------------
    contains, contain                                     | {attr: {contain: 'value'}}        | "table"."attr" LIKE '%value%'
    not_contains, not_contain, does_not_contain           | {attr: {not_contain: 'value'}}    | "table"."attr" NOT LIKE '%value%'
    starts_with, start_with                               | {attr: {start_with: 'value'}}     | "table"."attr" LIKE 'value%'
    not_starts_with,not_start_with, does_not_start_with   | {attr: {not_start_with: 'value'}} | "table"."attr" NOT LIKE 'value%'
    ends_with, end_with                                   | {attr: {end_with: 'value'}}       | "table"."attr" LIKE '%value'
    not_ends_with, not_end_with, does_not_end_with        | {attr: {not_end_with: 'value'}}   | "table"."attr" NOT LIKE '%value'
    regex, regex_match, matches, match                    | {attr: {regex: 'value'}}          | "table"."attr" SIMILAR TO 'value'
    not_regex, not_regex_match, does_not_match, not_match | {attr: {not_regex: 'value'}}      | "table"."attr" NOT SIMILAR TO 'value'
