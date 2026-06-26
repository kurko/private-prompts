# Asana field reference — Team Catalog

All GIDs below were read live from the Team Catalog project and its tasks. If a
create call rejects a GID, re-fetch with `asana_get_task` on a recent task
(`opt_fields: custom_fields`) or `asana_get_project_sections` — option GIDs can
change if someone edits the field.

- **Workspace**: `752389237742425`
- **Project (Team Catalog)**: `1201647585774820`
- **Slack channel #bot-exceptions-backend**: `C0906JG9N1G`

## Sections

| Section | GID | Use for |
|---------|-----|---------|
| Quick wins | `1206602220889093` | Default for exception-tracking pings |
| Up next | `1202971212086474` | Scoped bug with a clear next action |
| Backlog | `1203904722071016` | Lower-urgency, will sit a while |
| In flight | `1201647568184945` | Already being worked |
| Inbox | `1203536068727346` | Untriaged |
| Requires follow-up | `1205295842155330` | Waiting on something |

## Custom fields

### Vendor — field `1208902832894620` (single enum)

| Vendor | Option GID |
|--------|-----------|
| Hyperwallet | `1208902832894623` |
| Galileo | `1208902832894624` |
| Wogi | `1208902832894625` |
| InComm | `1208902832894626` |
| Lithic | `1208902832894627` |
| Xoxoday | `1208902832894628` |
| Runa | `1208902832894629` |
| Tillo | `1208902832894630` |
| Onbe | `1208904875256933` |
| Qwikcilver | `1208904880663731` |
| Astra | `1209113256251325` |
| Marqeta | `1209490634069660` |
| Nium | `1211577106457084` |
| US Bank | `1211653591811150` |
| Paynetics | `1214438774124834` |

### Priority — field `1168757481515865` (single enum)

| Value | Option GID |
|-------|-----------|
| High | `1168757481515866` |
| Medium | `1168757481515867` |
| Low | `1168757481515868` |

### Status — field `1203802047219329` (single enum)

| Value | Option GID |
|-------|-----------|
| Ready for work | `1203802047219330` |
| Requires discussion | `1203802047219331` |
| Blocked | `1203802047219332` |
| Waiting for client | `1203904847913827` |
| Waiting for designs | `1203904938049560` |
| Waiting for product | `1204293645599686` |
| Waiting for vendor | `1210746093387085` |
| Won't do | `1205197782046642` |
| Incomplete | `1207957231979742` |
| Monitoring | `1208246098349637` |

### Eng estimate — field `1203617045718222` (single enum)

| Value | Option GID |
|-------|-----------|
| < 1 day | `1203617045718223` |
| 1-3 days | `1203617045718230` |
| ~1 week | `1203617045718224` |
| ~2 weeks | `1203617045718225` |
| ~1 month | `1203617045718226` |
| Months | `1203617045718227` |

### Tag — field `1205285032368226` (multi-select enum)

Common ones for exceptions:

| Value | Option GID |
|-------|-----------|
| bug | `1205285114948663` |
| observability | `1205285114948662` |
| incident-remediation | `1206780426498259` |
| bug prevention | `1206826278999039` |
| tech debt | `1206602220889096` |
| maintainability | `1206042462028388` |
| performance | `1206835073439748` |
| vendors | `1206920171000290` |
| unplanned | `1205297973195842` |

## `custom_fields` shape for `asana_create_task`

The parameter is a **JSON string**. Enum values are the option GID (a string);
the multi-select Tag is an array of option GIDs. Example for a Low-priority,
Ready-for-work Hyperwallet exception tagged `observability`:

```json
{
  "1208902832894620": "1208902832894623",
  "1168757481515865": "1168757481515868",
  "1203802047219329": "1203802047219330",
  "1205285032368226": ["1205285114948662"]
}
```

Omit any field you are not setting (e.g. drop the Vendor key for a non-vendor
exception, drop the Tag key when none fits).
