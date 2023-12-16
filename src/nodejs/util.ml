let __filename () = Url.file_url_to_path [%mel.raw "import.meta.url"]
let __dirname () = Node.Path.dirname @@ __filename ()
