{

  open Lexing
  open Mmlparser

  exception Lexing_error of string

  let keyword_or_ident =
    let h = Hashtbl.create 21 in
    List.iter (fun (s, k) -> Hashtbl.add h s k)
      [ ("true", TRUE);
        ("false", FALSE);
        ("not", NOT);
        ("mod", MOD);
        ("mutable", MUTABLE);
        ("if", IF);
        ("then", THEN);
        ("else", ELSE);
        ("fun", FUN);
        ("let", LET);
        ("rec", REC);
        ("in", IN);
        ("type", TYPE);
        ("int", INT);
        ("bool", BOOLEAN);
        ("unit", UNIT);
        ("and", AND);
        ("or", OR);
        ("list", LIST);
        ("print", PRINT);
      ] ;
    fun s ->
      try  Hashtbl.find h s
      with Not_found -> IDENT(s)
        
}

let digit = ['0'-'9']
let number = digit+
let alpha = ['a'-'z' 'A'-'Z']
let ident = ['a'-'z' '_' 'A'-'Z'] (alpha | '_' | digit)*
  
rule token = parse
  | ['\n']
      { new_line lexbuf; token lexbuf }
  | [' ' '\t' '\r']+
      { token lexbuf }
  | "(*" 
      { comment lexbuf; token lexbuf }
  | number as n
      { CST(int_of_string n) }
  | ident as id
     { keyword_or_ident id }
  | "+"
      { PLUS }
  | "*"
      { STAR }
  | "-"
      { MOINS }
  | "/"
      { DIV }
  | '='
      { EQ }
  | "<>"
      { NEQS }
  | "=="
      { DEQ }
  | "!="
      { NEQ }
  | "<"
      { LT }
  | "<="
      { LE }
  | "&&"
      { AND }
  | "||"
      { OR }
  | "|"
      { BAR }
  | "("
     { LPAR }
  | ")"
     { RPAR } 
  | "{"
     { LBRA }
  | "}"
     { RBRA }
  | "<-"
     { LARR }
  | "->" 
     { RARR } 
  | "["
    { LCRO }
  | "]"
    { RCRO }
  | ";"
     { SEMI }
  | ":"
     { DPOINT}
  | "."
     { POINT }
  | _
      { raise (Lexing_error ("unknown character : " ^ (lexeme lexbuf))) }
  | eof
      { EOF }

and comment = parse
  | "*)"
      { () }
  | "(*"
      { comment lexbuf; comment lexbuf }
  | _
      { comment lexbuf }
  | eof
      { raise (Lexing_error "unterminated comment") }
