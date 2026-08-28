# lex-a2ui

A Lex implementation of the [A2UI](https://a2ui.org) (Agent to UI)
Protocol v1.0 message envelope — the JSON format an agent uses to
declare UI, without shipping arbitrary executable code to the client.

## Scope: envelope only, not the component catalog

A2UI's component catalog (`Text`, `Button`, `Column`, `TextField`, ...)
is open and extensible by design — agents can declare custom catalogs
(see [a2ui.org/concepts/catalogs](https://a2ui.org/concepts/catalogs/)).
This package does **not** hardcode a fixed sum type for every
basic-catalog component. `Component` instead carries `id` + `component`
(the catalog kind, a plain string) + an open `extra` field list,
reproducing the real flat wire shape:

```json
{"id": "user_name", "component": "Text", "text": {"path": "/name"}}
```

Typed convenience constructors for the basic catalog's components are a
natural follow-up once there's a real consumer to build them against —
deliberately not guessed at here.

## Verification status — read before relying on any of this

- **Verified against a worked example**: `createSurface` and
  `updateDataModel` are lifted directly from the spec source
  (`raw.githubusercontent.com/a2ui-project/a2ui/main/specification/v1_0/docs/a2ui_protocol.md`,
  checked 2026-08) and covered by tests that assert the *exact* JSON
  the spec shows, byte for byte (`tests/test_message.lex`).
- **Inferred, not verified**: `updateComponents` and `deleteSurface` —
  the spec confirmed these envelope key names exist, but no worked
  example showed their internal fields. Modeled by structural analogy
  with the verified messages (`surfaceId` + the obvious payload).
- **Unverified beyond the key name**: `callFunction` and
  `actionResponse` — no field-level detail was available when this
  package was written. They carry an opaque `jv.Json` payload rather
  than a guessed record shape, so nothing here can silently drift from
  a wrong schema — wrap whatever payload the agent actually needs.

Re-verify all four inferred/unverified message kinds against the spec
(or a real reference implementation) before depending on them.

## `lex-schema/json_value` has no `stringify`

Same finding as `lex-ag-ui`: the pinned `lex-schema` (0.9.3) has no
`stringify`/`write_json` export despite other packages in this ecosystem
(`lex-agent/src/stream.lex`) calling one. `message.lex` hand-rolls its
own JSON writer rather than depend on a function that doesn't exist in
the pinned version.

## Relationship to `lex-ag-ui`

Independent protocols, not layered — see
[copilotkit.ai's writeup](https://www.copilotkit.ai/blog/build-with-googles-new-a2ui-spec-agent-user-interfaces-with-a2ui-ag-ui)
for how the two typically compose: AG-UI is the agent↔frontend event
transport, A2UI is a payload format that can ride over it (or over A2A).
This package doesn't depend on `lex-ag-ui` and has no transport of its
own yet.

## Status

v1, unreleased, envelope-only skeleton. Not wired into any agent server
or renderer. Treated as the lower-priority, higher-risk half of a
two-package plan — `lex-ag-ui` is the near-term integration target;
this package is here so the scaffolding exists when there's a concrete
reason to render agent-declared UI rather than plain chat text.

## License

Copyright (c) 2026 lex-a2ui contributors.

Licensed under the [EUPL-1.2](LICENSE) — the European Union Public Licence, as used across the `lex-*` ecosystem.
