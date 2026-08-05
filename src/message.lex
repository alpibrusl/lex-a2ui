# lex-a2ui — A2UI (Agent to UI) Protocol v1.0 message envelope.
#
# Verified against the actual spec source
# (raw.githubusercontent.com/a2ui-project/a2ui/main/specification/v1_0/docs/a2ui_protocol.md,
# checked 2026-08), including a full worked `createSurface` example.
# A2UI's component catalog is open/extensible by design (agents can
# declare custom catalogs, see https://a2ui.org/concepts/catalogs/), so
# this package does NOT hardcode a fixed sum type for every basic-catalog
# component (Text/Button/Column/TextField/...). `Component` instead
# carries `id` + `component` (the catalog kind, a plain string) + an
# open `extra` field list -- exactly reproducing the flat wire shape
# (e.g. `{"id":"user_name","component":"Text","text":{"path":"/name"}}`)
# without guessing at every catalog's field set.
#
# Verified message kinds: createSurface, updateDataModel (both shown in
# the spec's worked examples). updateComponents and deleteSurface are
# inferred by structural analogy (surfaceId + the same components list /
# no extra fields) -- NOT lifted from a worked example, flagged below.
# callFunction and actionResponse are UNVERIFIED beyond their envelope
# key name -- no field-level detail was available when this package was
# written, so they carry an opaque `jv.Json` payload rather than a
# guessed record shape. Re-verify all four against the spec before
# relying on them.
#
# Effects: none. Construction and serialization are pure.

import "std.str" as str

import "std.list" as list

import "std.int" as int

import "std.float" as float

import "lex-schema/json_value" as jv

# ---- Dynamic values (JSON-Pointer data binding) ---------------------
# A property that can be a literal or a `{"path": "/pointer"}` binding
# into the surface's data model (DynamicString/DynamicNumber/... in the
# spec all share this one wire shape).
type DynamicValue = Literal(jv.Json) | PathRef(Str)

fn dynamic_json(d :: DynamicValue) -> jv.Json {
  match d {
    Literal(j) => j,
    PathRef(p) => JObj([("path", JStr(p))]),
  }
}

# ---- Component (generic -- see module doc) ---------------------------
type Component = { id :: Str, component :: Str, extra :: List[(Str, jv.Json)] }

fn component_json(c :: Component) -> jv.Json {
  JObj(list.concat([("id", JStr(c.id)), ("component", JStr(c.component))], c.extra))
}

# ---- Message payloads --------------------------------------------------
type CreateSurface = { surface_id :: Str, catalog_id :: Str, send_data_model :: Bool, components :: List[Component], data_model :: Option[jv.Json] }

# INFERRED (not from a worked example) -- surfaceId + a replacement
# components list, by analogy with createSurface.
type UpdateComponents = { surface_id :: Str, components :: List[Component] }

type UpdateDataModel = { surface_id :: Str, path :: Option[Str], value :: jv.Json }

# INFERRED (not from a worked example) -- every other message carries
# surfaceId; deleteSurface is assumed to need nothing else.
type DeleteSurface = { surface_id :: Str }

type A2uiMessage = CreateSurfaceMsg(CreateSurface) | UpdateComponentsMsg(UpdateComponents) | UpdateDataModelMsg(UpdateDataModel) | DeleteSurfaceMsg(DeleteSurface) | CallFunctionMsg(jv.Json) | ActionResponseMsg(jv.Json)

fn opt_field(name :: Str, o :: Option[jv.Json]) -> List[(Str, jv.Json)] {
  match o {
    None => [],
    Some(j) => [(name, j)],
  }
}

fn opt_str_field(name :: Str, o :: Option[Str]) -> List[(Str, jv.Json)] {
  match o {
    None => [],
    Some(s) => [(name, JStr(s))],
  }
}

fn envelope_json(key :: Str, body :: jv.Json) -> jv.Json {
  JObj([("version", JStr("v1.0")), (key, body)])
}

fn to_json(m :: A2uiMessage) -> jv.Json {
  match m {
    CreateSurfaceMsg(f) => envelope_json("createSurface", JObj(list.concat([("surfaceId", JStr(f.surface_id)), ("catalogId", JStr(f.catalog_id)), ("sendDataModel", JBool(f.send_data_model)), ("components", JList(list.map(f.components, component_json)))], opt_field("dataModel", f.data_model)))),
    UpdateComponentsMsg(f) => envelope_json("updateComponents", JObj([("surfaceId", JStr(f.surface_id)), ("components", JList(list.map(f.components, component_json)))])),
    UpdateDataModelMsg(f) => envelope_json("updateDataModel", JObj(list.concat([("surfaceId", JStr(f.surface_id))], list.concat(opt_str_field("path", f.path), [("value", f.value)])))),
    DeleteSurfaceMsg(f) => envelope_json("deleteSurface", JObj([("surfaceId", JStr(f.surface_id))])),
    CallFunctionMsg(payload) => envelope_json("callFunction", payload),
    ActionResponseMsg(payload) => envelope_json("actionResponse", payload),
  }
}

# ---- Json -> Str (lex-schema/json_value has no stringify -- see README) --
fn escape_char(c :: Str) -> Str {
  match c {
    "\"" => "\\\"",
    "\\" => "\\\\",
    "\n" => "\\n",
    "\r" => "\\r",
    "\t" => "\\t",
    _ => c,
  }
}

fn escape_str(s :: Str) -> Str {
  str.join(list.map(str.split(s, ""), escape_char), "")
}

fn write_json(j :: jv.Json) -> Str {
  match j {
    JNull => "null",
    JBool(b) => if b {
      "true"
    } else {
      "false"
    },
    JInt(n) => int.to_str(n),
    JFloat(x) => float.to_str(x),
    JStr(s) => str.concat("\"", str.concat(escape_str(s), "\"")),
    JList(xs) => str.concat("[", str.concat(str.join(list.map(xs, write_json), ","), "]")),
    JObj(kvs) => str.concat("{", str.concat(str.join(list.map(kvs, write_pair), ","), "}")),
  }
}

fn write_pair(kv :: (Str, jv.Json)) -> Str {
  match kv {
    (k, v) => str.concat("\"", str.concat(escape_str(k), str.concat("\":", write_json(v)))),
  }
}

# ---- Public entry point -----------------------------------------------
fn encode(m :: A2uiMessage) -> Str {
  write_json(to_json(m))
}

