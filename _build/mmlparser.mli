
(* The type of tokens. *)

type token = 
  | UNIT
  | TYPE
  | TRUE
  | THEN
  | STAR
  | SEMI
  | RPAR
  | REC
  | RBRA
  | RARR
  | PLUS
  | OR
  | NOT
  | NEQ
  | NEG
  | MUTABLE
  | MOINS
  | MOD
  | LT
  | LPAR
  | LET
  | LE
  | LBRA
  | LARR
  | INT
  | IN
  | IF
  | IDENT of (string)
  | FUN
  | FALSE
  | EQ
  | EOF
  | ELSE
  | DIV
  | DEQ
  | DCOMMA
  | CST of (int)
  | COMMA
  | BOOLEAN
  | AND

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val program: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (Mml.prog)
