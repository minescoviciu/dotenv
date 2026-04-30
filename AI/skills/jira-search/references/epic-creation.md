# Jira Epic Creation Reference (MW-Services)

Use this reference when the user asks to create a Jira Epic in project `SW` for Team-MW-Services.

## Rules

- Use Jira MCP tools only.
- If Jira MCP is unavailable, state this clearly and stop.
- If the user asks for draft text only, do not create the Epic.
- If `Prod_Target_Version` is missing, ask the user to choose one from the next 3 PI values.

## Required Fields

For `SW` Epic creation in this workflow, include:

- `project_key`: `SW`
- `issue_type`: `Epic`
- `summary`
- `description`
- `customfield_10006` (`Epic Name`)
- `customfield_10200` (`Team`)
- `customfield_12206` (`Common Category`)
- `customfield_11797` (`Prod_Target_Version`)

## Team Field Format

`Team` must be sent as scalar team ID string, not as an object.

- Team name: `Team-MW-Services`
- Team ID: `28`
- Correct payload: `"customfield_10200": "28"`
- Incorrect examples: `{"id": "28"}`, `{"value": "Team-MW-Services"}`

## Defaults for MW-Services

Use these defaults unless the user asks otherwise:

- Component: `MW`
- Common Category (`customfield_12206`): `{"value": "Infra Generic"}`

## Prod_Target_Version Selection

If user did not provide `Prod_Target_Version`, generate 3 options and ask user to choose one.

Format:

- `PI_<quarter>_<year>`

Quarter mapping:

- `Q1`: January-March
- `Q2`: April-June
- `Q3`: July-September
- `Q4`: October-December

Generation algorithm:

1. Determine the current quarter from current UTC date.
2. Start from the next quarter.
3. Generate 3 consecutive PI values, with year rollover when quarter passes 4.

Examples:

- Current date in March 2026 (Q1): `PI_2_2026`, `PI_3_2026`, `PI_4_2026`
- Current date in November 2026 (Q4): `PI_1_2027`, `PI_2_2027`, `PI_3_2027`

Prompt template:

- `Please choose Prod_Target_Version: PI_2_2026, PI_3_2026, PI_4_2026.`

After selection, send as labels array:

- `"customfield_11797": ["PI_2_2026"]`

## Error-Handling Notes

Known errors and fixes from real Epic creation:

1. `Team id ... is not valid`
   - Fix: set `customfield_10200` to scalar string team ID (`"28"`).

2. `Common Category is required`
   - Fix: add `customfield_12206` (default `Infra Generic` unless user specifies otherwise).

3. `Field 'Prod_Target_Version' must be populated`
   - Fix: ask user for PI choice and set `customfield_11797` as string array.

## Suggested Epic Creation Sequence

1. Read the relevant ticket(s) for context.
2. Draft concise Epic summary and description.
3. Confirm whether to create now or wait for user approval.
4. If `Prod_Target_Version` is missing, ask user to choose from the generated 3 PI options.
5. Create Epic with required fields and payload formats above.
6. If this is an enhancement of another issue, add a `Relates` link and mention it in the final response.
