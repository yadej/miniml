%{

  open Lexing
  open Mml

%}

%token EQ NEQ LT LE AND OR
%token PLUS STAR DIV MOD
%token MOINS NOT NEG
%token <int> CST
%token <bool> BOOLEAN
%token <string> IDENT
%token EOF

%left PLUS MOINS
%left STAR DIV
%left MOD
%left NEG NOT

%start program
%type <Mml.prog> program

%%

program:
| (* à compléter *) code=expression EOF { {types=[]; code} }
;

simple_expression:
| n=CST { Int(n) }
| b=BOOLEAN { Bool(b) }
| s=IDENT { Var(s) }
;

expression:
| e=simple_expression { e }
| e1=expression op=binop e2=expression { Bop(op, e1, e2) }
| op=unop e=expression {Uop(op,e)}
;

%inline unop:
| NEG { Neg }
| NOT { Not }
;
%inline binop:
| PLUS { Add }
| STAR { Mul }
| MOINS { Sub }
| DIV { Div }
| MOD { Mod }
| EQ { Eq }
| NEQ { Neq }
| LT { Lt }
| LE { Le }
| AND { And }
| OR { Or }
;
