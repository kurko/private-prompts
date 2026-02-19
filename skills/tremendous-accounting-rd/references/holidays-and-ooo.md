# Holidays and OOO Detection

## Public holidays by country (2026)

### United States

| Date | Holiday |
|---|---|
| Jan 1 | New Year's Day |
| Jan 19 | Martin Luther King Jr. Day |
| Feb 16 | Presidents' Day |
| May 25 | Memorial Day |
| Jul 3 | Independence Day (observed) |
| Jul 4 | Independence Day |
| Sep 7 | Labor Day |
| Nov 26 | Thanksgiving |
| Nov 27 | Day after Thanksgiving |
| Dec 25 | Christmas Day |

### Brazil

| Date | Holiday |
|---|---|
| Jan 1 | New Year's Day |
| Feb 16 | Carnival Monday |
| Feb 17 | Carnival Tuesday |
| Feb 18 | Ash Wednesday (half day, typically off) |
| Apr 3 | Good Friday |
| Apr 21 | Tiradentes |
| May 1 | Labor Day |
| Jun 4 | Corpus Christi |
| Sep 7 | Independence Day |
| Oct 12 | Our Lady of Aparecida |
| Nov 2 | All Souls' Day |
| Nov 15 | Republic Proclamation Day |
| Dec 25 | Christmas Day |

### Portugal

| Date | Holiday |
|---|---|
| Jan 1 | New Year's Day |
| Apr 3 | Good Friday |
| Apr 5 | Easter Sunday |
| Apr 25 | Freedom Day |
| May 1 | Labor Day |
| Jun 4 | Corpus Christi |
| Jun 10 | Portugal Day |
| Aug 15 | Assumption of Mary |
| Oct 5 | Republic Day |
| Nov 1 | All Saints' Day |
| Dec 1 | Restoration of Independence Day |
| Dec 8 | Immaculate Conception |
| Dec 25 | Christmas Day |

**Note on Filipe Costa:** Based in Brazil. Uses Brazil holidays.

**Holiday accuracy:** These are standard public holidays. Tremendous may observe additional company holidays or skip some. When Notion's Engineering Calendar shows a holiday not on this list, trust the calendar. When this list has a holiday the calendar doesn't mention, flag it for the user.

## OOO detection from Notion

**Engineering Calendar database ID:** `21e266b7-da09-43ab-a307-efe19b4943d8`

1. Fetch the Engineering Calendar database using `mcp__notion__notion-fetch` with ID `21e266b7-da09-43ab-a307-efe19b4943d8`
2. If searching, use `mcp__notion__notion-search` with `content_search_mode: "workspace_search"`. **NEVER use the default `ai_search` mode** (it returns empty results for this page).
3. Look for entries in the target month matching engineer names
4. Extract: date range, type (PTO, holiday, medical, offsite)
5. If the Engineering Calendar is inaccessible, STOP (do not proceed with partial data)

## Working days calculation

For a given month and engineer:

1. Use **20 working days** as the standard denominator (not the actual weekday count for the specific month). This matches how the spreadsheet is typically filled.
2. Count days lost: public holidays (for their country) + PTO + other OOO
3. Each day lost = 5% non-capitalizable (1 day / 20 days)
4. Support rotation days also count as non-capitalizable at the same rate

**Examples:**
- 1 day holiday = 5%
- 1 week PTO = 25%
- 2 weeks support rotation = 50%
- New Year's Day (1d) + 1 week PTO = 30% non-capitalizable
