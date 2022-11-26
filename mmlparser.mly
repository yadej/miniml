%{

  open Lexing
  open Mml

%}

(* les exp bool*)
%token EQ NEQ LT LE AND OR
(* operateur *)
%token PLUS STAR DIV MOD
%token MOINS NOT NEG
(* des variables *)
%token <int> CST
%token <int> INT
%token <bool> BOOLEAN
%token <string> IDENT
%token <bool> MUTABLE
%token TYPE
%token TRUE FALSE
(* () *)
%token UNIT
(* Paire *)
(* ( ) { } <-  ->*)
%token LPAR RPAR LBRA RBRA LARR RARR
(* ; : . *)
%token SEMI DCOMMA COMMA
%token EOF

%nonassoc AND OR
%nonassoc EQ NEQ LT LE   
%left PLUS MOINS
%left STAR DIV MOD
%nonassoc NEG NOT
%nonassoc RARR LARR 
%right SEMI
%nonassoc LPAR LBRA 
%nonassoc TRUE FALSE CST IDENT
%start program
%type <Mml.prog> program

%%

program:
| types=type_def* code=expression EOF { {types=[]; code} }
;

type_def:
| TYPE id1=IDENT EQ LBRA st_def=struct_type_def+ RBRA{
        (id1,  st_def  ) 
   } 
;

struct_type_def:
| m=MUTABLE? id=IDENT DCOMMA t=type_ SEMI  { (id, t, m) }

type_:
| INT { TInt }
| BOOLEAN { TBool }
| UNIT { TUnit }
| id=IDENT { TStrct(id) }
| t1=type_ RARR t2=type_ { TFun(t1,t2) }
| LPAR t=type_ RPAR { t }
;

simple_expression:
| n=CST { Int(n) }
| TRUE { Bool(true) }
| FALSE { Bool(false) }
| LPAR RPAR { Unit }
| id=IDENT { Var(id) }
| s=simple_expression COMMA id=IDENT { GetF(s, id) }
| LBRA stsimpexp=struct_simple_exp+ RBRA { Strct( stsimpexp ) } 
| LPAR e=expression RPAR { e }

;

struct_simple_exp:
| id=IDENT EQ e=expression SEMI { (id,e) }

expression:
| e=simple_expression { e }
| e1=expression op=binop e2=expression { Bop(op, e1, e2) }
| op=unop e=expression {Uop(op,e)}
| e=expression s=simple_expression { App(e, s) }



| s=simple_expression COMMA id=IDENT LARR e=expression { SetF(s, id, e) }
| e1=expression SEMI e2=expression { Seq(e1, e2) }
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
