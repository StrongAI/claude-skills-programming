# Boundary Value Catalog

Quick-reference test values by type class. Apply only the type classes that match inputs identified in Step 2 of BVA. Do not mechanically apply every entry.

## Numeric (Integer)

| Boundary         | Test Values                  |
| ---------------- | ---------------------------- |
| Zero crossing    | -1, 0, 1                     |
| Type minimum     | MIN_INT, MIN_INT+1           |
| Type maximum     | MAX_INT-1, MAX_INT           |
| Signedness       | -1, 0 (if unsigned expected) |
| Powers of 2      | 2^N-1, 2^N, 2^N+1            |
| Division-related | Divisor = 0, 1, -1           |

## Numeric (Float)

| Boundary          | Test Values                               |
| ----------------- | ----------------------------------------- |
| Special values    | NaN, +Infinity, -Infinity, +0.0, -0.0     |
| Precision         | 0.1 + 0.2 (rounding), values near epsilon |
| Integer precision | 2^53, 2^53+1 (loss in doubles)            |
| Subnormal         | ~5e-324 (double min subnormal)            |
| Max finite        | ~1.8e+308 (double max)                    |
| Comparison hazard | Values differing by less than tolerance   |

## String

| Boundary           | Test Values                                          |
| ------------------ | ---------------------------------------------------- |
| Empty/null         | null, undefined, "", " " (whitespace)                |
| Length             | 0, 1, maxLen-1, maxLen, maxLen+1                     |
| Unicode            | ASCII, BMP, surrogate pairs (emoji), combining chars |
| Special characters | null byte, newline, tab, backslash                   |
| Encoding           | Characters requiring 1/2/3/4 bytes in UTF-8          |

## Collection

| Boundary          | Test Values                                        |
| ----------------- | -------------------------------------------------- |
| Size              | 0 (empty), 1, 2, many, capacity, capacity+1        |
| Index access      | 0, length-1, length (out of bounds)                |
| Negative index    | -1 (if supported by language)                      |
| Subarray/slice    | start=0, end=0, start=end, start>end               |
| Sorted assumption | Already sorted, reverse sorted, all equal          |
| Duplicates        | No duplicates, all duplicates, adjacent duplicates |

## Nullable/Optional

| Boundary            | Test Values                                |
| ------------------- | ------------------------------------------ |
| Absence             | null, undefined, None, nil                 |
| Falsy vs absent     | 0, "", false vs null/undefined             |
| Nested              | obj=null, obj.prop=null, obj.prop.sub=null |
| Default interaction | Omitted (uses default) vs explicit value   |

## Enum/Union

| Boundary         | Test Values                                 |
| ---------------- | ------------------------------------------- |
| Exhaustiveness   | Every declared variant, one test each       |
| Default/unknown  | Value not matching any variant              |
| Case sensitivity | "Active" vs "active" (string enums)         |
| Flags/bitfield   | 0, individual bits, all bits, invalid combo |

## Date/Time

| Boundary          | Test Values                                               |
| ----------------- | --------------------------------------------------------- |
| Epoch             | 1970-01-01T00:00:00Z, negative timestamps                 |
| Month boundaries  | Jan 31, Feb 28/29, Apr 30                                 |
| Leap year         | Feb 29 leap, Feb 28 non-leap                              |
| DST transitions   | Spring forward (missing hour), fall back (ambiguous hour) |
| Year boundary     | Dec 31 23:59:59 → Jan 1 00:00:00                          |
| Max representable | Platform max date, 2038 overflow (32-bit)                 |

## Recursion/Depth

| Boundary         | Test Values                             |
| ---------------- | --------------------------------------- |
| Base case        | Input triggering immediate return       |
| Depth 1          | Single recursive call then base         |
| At limit         | Exactly at depth/stack limit            |
| Over limit       | One beyond limit (tests guard)          |
| Degenerate shape | Maximally unbalanced tree (linked list) |

## Return Values

| Boundary            | Test Values                                              |
| ------------------- | -------------------------------------------------------- |
| Success vs error    | Input producing success, input producing each error type |
| Empty vs populated  | Input producing empty result vs non-empty                |
| Optional return     | Input producing null/nil return vs present value         |
| Discriminated union | Input producing each possible return variant             |
| Numeric return      | Inputs producing 0, negative, MAX_INT return values      |

Return value boundaries are derived — work backwards from each distinct return path to find the input that triggers it.

## Three-Value Selection Per Boundary

| Operator | Boundary | Test Points                        |
| -------- | -------- | ---------------------------------- |
| `x > K`  | K        | K-1 (false), K (false), K+1 (true) |
| `x >= K` | K        | K-1 (false), K (true), K+1 (true)  |
| `x < K`  | K        | K-1 (true), K (false), K+1 (false) |
| `x <= K` | K        | K-1 (true), K (true), K+1 (false)  |
| `x == K` | K        | K-1 (false), K (true), K+1 (false) |
| `x != K` | K        | K-1 (true), K (false), K+1 (true)  |

**Increment rules:**
- Integer: ±1
- Float: ±context-appropriate epsilon (not machine epsilon)
- String length: ±1 character
- Collection size: ±1 element
- Date: ±1 of the smallest unit used
