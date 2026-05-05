---
name: linear-read
description: Read from Linear (GraphQL queries and attachment downloads). Use whenever the user references a Linear identifier (e.g. `GAM-1234`, `ENG-42`), a Linear URL (`https://linear.app/...`), an attachment URL (`https://uploads.linear.app/...`), or asks about issues, projects, cycles, comments, or notifications.
---

# linear-read

Read-only wrapper around Linear. Two subcommands:

- `query` — run any GraphQL query against the Linear API. Covers issues (by identifier or filter), projects, cycles, comments, notifications, teams, users, custom views, and schema introspection.
- `fetch` — download an uploaded attachment from `*.linear.app` (e.g. images embedded in issue descriptions or comments via `![](https://uploads.linear.app/...)`).

Reach for this skill when the user references a `GAM-1234`-style identifier, asks about notifications/projects/issues, or wants to see an image attached to a Linear issue or comment.

Do not use for mutations: creating issues, posting comments, webhooks, or file uploads.

## Invoke

```
scripts/linear-read query '<gql>' [--vars '<json>']
scripts/linear-read query [--vars '<json>'] < query.graphql
scripts/linear-read fetch '<url>' [-o <path>]
```

`query` stdout: response body, including any `errors` array (read it, fix the query). `fetch` saves the attachment and prints the resolved path to stderr. Non-zero exit: transport, auth, or config error on stderr.

## Fetch attachments

`fetch` downloads a Linear-hosted attachment (host must end in `.linear.app`; non-Linear hosts are refused so the API key never leaks). Default output is `<skill>/tmp/<basename>.<ext>`, with the extension derived from the response `Content-Type`. Pass `-o <path>` to override. Re-fetching the same URL overwrites the file.

```
scripts/linear-read fetch 'https://uploads.linear.app/.../<uuid>'
# linear-read: saved <skill>/tmp/<uuid>.png
```

Use this for images embedded in issue descriptions or comments (Markdown `![](https://uploads.linear.app/...)`), then read the saved file.

## Gotchas

- `issue(id: "GAM-1234")` accepts the human identifier directly. Most other id args (`parentId`, `stateId`, `assigneeId`, `cycleId`, `projectId`) require UUID; resolve with a prior query.
- Filter operators: `eq, neq, in, nin, null, lt, lte, gt, gte`, string `eqIgnoreCase, containsIgnoreCase, startsWith, endsWith`. Top-level `and:`/`or:`. Many-to-many: `every`, `some` (default). Dates: ISO 8601 absolute or signed durations (`"-P2W"` is two weeks ago).
- Connections default `first: 50`, cap ~250. Select `pageInfo { hasNextPage endCursor }` whenever you may loop. Wrapper does not auto-paginate.
- Complexity ceiling: 10,000 points per query (scalar 0.1, object 1, connection multiplied by page size). Deep nests with default pages blow the budget; shrink pages or split queries.
- Throttle: HTTP 400 with `extensions.code == "RATELIMITED"` (wrapper exits 2). Back off, do not retry tightly.
- `notifications` returns the `Notification` interface; use inline fragments for type-specific fields. `subtitle` is a pre-formatted "who did what" string, use verbatim.
- No subscriptions, no REST. One GraphQL endpoint.

## Schema

- Apollo Studio: https://studio.apollographql.com/public/Linear-API/schema/reference
- Raw: https://github.com/linear/linear/blob/master/packages/sdk/src/schema.graphql
- Introspect: `scripts/linear-read query '{ __type(name:"Issue") { fields { name type { name kind ofType { name } } } } }'`

## Examples

Each demonstrates a distinct mechanic. Adapt by changing fields and filters; do not treat as templates.

Point lookup by identifier:
```graphql
query { issue(id: "GAM-1234") { identifier title state { name } assignee { name } } }
```

Filtered list with relation filter, relative date, pagination:
```graphql
query MyRecent($cursor: String) {
  issues(
    first: 50, after: $cursor, orderBy: updatedAt
    filter: {
      assignee: { isMe: { eq: true } }
      state: { type: { in: ["unstarted", "started"] } }
      labels: { every: { name: { neq: "ignored" } } }
      updatedAt: { gt: "-P1W" }
    }
  ) {
    nodes { identifier title updatedAt state { name } }
    pageInfo { hasNextPage endCursor }
  }
}
```

Interface with inline fragments:
```graphql
query Unread {
  notifications(first: 20, filter: { readAt: { null: true } }) {
    nodes {
      id type createdAt
      ... on IssueNotification { issue { identifier title url } comment { body } }
      ... on ProjectNotification { project { name url } }
    }
  }
}
```
