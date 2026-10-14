; extends

; Constructors are calls too. Re-emit the stock C++ constructor captures above
; LSP semantic tokens so they use the same color as ordinary function calls.

((call_expression
  function: (identifier) @constructor)
  (#lua-match? @constructor "^[%u]")
  (#set! priority 130))

((call_expression
  function: (qualified_identifier
    name: (identifier) @constructor))
  (#lua-match? @constructor "^[%u]")
  (#set! priority 130))

((call_expression
  function: (field_expression
    field: (field_identifier) @constructor))
  (#lua-match? @constructor "^[%u]")
  (#set! priority 130))
