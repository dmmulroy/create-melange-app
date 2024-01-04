/*
 * Dom is a collection of browser types provided by Melange.
 * See: https://melange.re/v2.2.0/api/ml/melange/Dom/index.html
 */
include Dom;

[@mel.scope "document"] [@mel.return nullable]
external get_element_by_id: string => option(Dom.element) = "getElementById";
/* TODO: Write docs on bindings */

[@mel.set]
external set_inner_html: (Dom.element, string) => unit = "innerHTML";

/*
 * You can use the above bindings like so:
 *
 * let _ =
 *   "root"
 *   |> get_element_by_id
 *   |. set_inner_html "<p>hello world</p>"
 *
 * and it will generate the following JS:
 *
 * document.getElementById("root").innerHTML = "<p>hello world</p>";
 */
