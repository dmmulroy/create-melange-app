(lang dune 3.11)

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
   (>= 5.1.0))
  (dune
   (>= 3.11))
  (melange
   (>= 2.1.0))
  opam-check-npm-deps
  (reason
   (>= 3.10.0))
  (reason-react
   (>= 0.13.0))
  reason-react-ppx
  ppx_deriving)
 (tags
  (cli, react, reasonml, ocaml, melange)))
