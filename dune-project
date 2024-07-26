(lang dune 3.14)

(using melange 0.1)

(using directory-targets 0.1)

(name create_melange_app)

(generate_opam_files true)

(source
 (github dmmulroy/create-melange-app))

(authors "Dillon Mulroy <dillon.mulroy@gmail.com>")

(maintainers "Dillon Mulroy <dillon.mulroy@gmail.com>")

(license MIT)

(documentation https://github.com/dmmulroy/create-melange-app)

(package
 (name create_melange_app)
 (synopsis "A cli tool for generating and managing Melange apps")
 (description "A cli tool for generating and managing Melange apps")
 (allow_empty)
 (depends
  (ocaml
   (>= 5.2))
  (dune
   (>= 3.14))
  (melange (= 4.0.1-52))
  (reason
   (>= 3.12.0))
  (reason-react
   (>= 0.15.0))
  reason-react-ppx
  ppx_deriving)
 (tags
  (cli, react, reasonml, ocaml, melange)))
