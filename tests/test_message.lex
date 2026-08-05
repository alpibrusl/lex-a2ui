# lex-a2ui — message.lex tests (pure, run via `lex test`)
#
# test_create_surface_spec_example and test_update_data_model_spec_example
# reproduce the worked examples straight from the A2UI v1.0 spec source
# verbatim -- a change here that breaks either is a real wire-format
# regression, not just an internal refactor.

import "std.list" as list

import "../src/message" as m

fn check(name :: Str, cond :: Bool) -> Result[Unit, Str] {
  if cond {
    Ok(())
  } else {
    Err(name)
  }
}

fn count_failures(results :: List[Result[Unit, Str]]) -> Int {
  list.fold(results, 0, fn (acc :: Int, r :: Result[Unit, Str]) -> Int {
    match r {
      Ok(_) => acc,
      Err(_) => acc + 1,
    }
  })
}

fn test_create_surface_spec_example() -> Result[Unit, Str] {
  let root := { id: "root", component: "Column", extra: [("children", JList([JStr("user_name")]))] }
  let user_name := { id: "user_name", component: "Text", extra: [("text", JObj([("path", JStr("/name"))]))] }
  let msg := CreateSurfaceMsg({ surface_id: "user_profile_card", catalog_id: "https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json", send_data_model: true, components: [root, user_name], data_model: Some(JObj([("name", JStr("John Doe"))])) })
  let got := m.encode(msg)
  let want := "{\"version\":\"v1.0\",\"createSurface\":{\"surfaceId\":\"user_profile_card\",\"catalogId\":\"https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json\",\"sendDataModel\":true,\"components\":[{\"id\":\"root\",\"component\":\"Column\",\"children\":[\"user_name\"]},{\"id\":\"user_name\",\"component\":\"Text\",\"text\":{\"path\":\"/name\"}}],\"dataModel\":{\"name\":\"John Doe\"}}}"
  check("createSurface matches the spec's worked example byte-for-byte", got == want)
}

fn test_update_data_model_spec_example() -> Result[Unit, Str] {
  let msg := UpdateDataModelMsg({ surface_id: "surface_id", path: Some("/user/name"), value: JStr("Jane Doe") })
  let got := m.encode(msg)
  let want := "{\"version\":\"v1.0\",\"updateDataModel\":{\"surfaceId\":\"surface_id\",\"path\":\"/user/name\",\"value\":\"Jane Doe\"}}"
  check("updateDataModel matches the spec's worked example byte-for-byte", got == want)
}

fn test_update_data_model_omitted_path() -> Result[Unit, Str] {
  let msg := UpdateDataModelMsg({ surface_id: "s", path: None, value: JObj([]) })
  let got := m.encode(msg)
  let want := "{\"version\":\"v1.0\",\"updateDataModel\":{\"surfaceId\":\"s\",\"value\":{}}}"
  check("updateDataModel omits path (replaces whole data model) when None", got == want)
}

fn test_delete_surface() -> Result[Unit, Str] {
  let msg := DeleteSurfaceMsg({ surface_id: "s1" })
  let got := m.encode(msg)
  check("deleteSurface envelope shape", got == "{\"version\":\"v1.0\",\"deleteSurface\":{\"surfaceId\":\"s1\"}}")
}

fn suite_pure() -> List[Result[Unit, Str]] {
  [test_create_surface_spec_example(), test_update_data_model_spec_example(), test_update_data_model_omitted_path(), test_delete_surface()]
}

fn run_all() -> Int {
  count_failures(suite_pure())
}

