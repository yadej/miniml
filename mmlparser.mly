%{

  open Lexing
  open Mml
  open List

%}

(* les exp bool*)
%token EQ DEQ NEQ LT LE AND OR
(* operateur *)
%token PLUS STAR DIV MOD
%token MOINS NOT NEG
(* des variables *)
%token <int> CST
%token INT
%token BOOLEAN
%token <string> IDENT
%token LIST
%token MUTABLE
%token TYPE
%token TRUE FALSE
(* () *)
%token UNIT
(* Paire *)
(* ( ) { } <-  ->  [ ]*)
%token LPAR RPAR LBRA RBRA LARR RARR LCRO RCRO
(* ; : . *)
%token SEMI DCOMMA COMMA
(* Condition *)
%token IF THEN ELSE
(* fonction *)
%token FUN 
%token LET REC IN
(* End of line *)
%token EOF

(* priorite des let *)
%nonassoc IN
%right RARR
%nonassoc LBRA
%left LIST
(* priorite des point virgule*)
%right IDENT
%nonassoc TRUE FALSE CST 
%right SEMI
(* priorite condit *)
%nonassoc THEN
%nonassoc ELSE

(* priorite fonction bool *)
%right OR
%right AND

%right LARR 

(* priorite op bool*)
%nonassoc DEQ NEQ LT LE  

(* priorite des operateur *) 
%left PLUS MOINS
%left STAR DIV MOD

%nonassoc NEG
%left NOT

(* priorite des parenthese  *)
%right LPAR LCRO

%start program
%type <Mml.prog> program

%%

program:
| types=type_def* code=expression EOF { {types; code} }
;

type_def:
| TYPE id1=IDENT EQ LBRA st_def=struct_type_def+ RBRA{
        (id1,  st_def  ) 
   } 
;

struct_type_def:
| MUTABLE id=IDENT DCOMMA t=type_ SEMI  { (id, t, true) }
| id=IDENT DCOMMA t=type_ SEMI  { (id, t, false) }

type_:
| INT { TInt }
| BOOLEAN { TBool }
| UNIT { TUnit }
| id=IDENT { TStrct(id) }
| t1=type_ RARR t2=type_ { TFun(t1,t2) }
| LPAR t=type_ RPAR { t }
| t=type_ LIST { TList(t) }
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
| LCRO l=lists RCRO { List(l) }
| LCRO RCRO {List([])}
| s=simple_expression DCOMMA DCOMMA LCRO RCRO { AppList(s, List([]) ) }
| s=simple_expression DCOMMA DCOMMA LCRO s2=simple_expression RCRO { AppList(s, s2) }
| s=simple_expression COMMA LCRO n=CST RCRO { GetList(s, n) }
;

struct_simple_exp:
| id=IDENT EQ e=expression SEMI { (id,e) }

expression:
| e=simple_expression { e }
| e1=expression op=binop e2=expression { Bop(op, e1, e2) }
| uop=unop { uop }
| e=expression s=simple_expression { App(e, s) }
| IF e1=expression THEN e2=expression { If(e1,e2, Unit)  }
| IF e1=expression THEN e2=expression ELSE e3=expression { If(e1,e2,e3) }
| FUN LPAR id=IDENT DCOMMA t=type_ RPAR RARR e=expression { Fun(id, t, e) }
| LET id=IDENT v=argumentLet EQ e1=expression IN e2=expression { Let(id, mk_fun v e1, e2) } 
| LET REC id=IDENT v=argumentLet DCOMMA t=type_ EQ e1=expression IN e2=expression {
  Let(id, Fix(id,mk_fun_type v t, mk_fun v e1 ),e2 )
} 
| s=simple_expression COMMA id=IDENT LARR e=expression { SetF(s, id, e) }
| seq_=sequence {seq_}
| s=simple_expression COMMA LCRO n=CST RCRO LARR e=expression { SetList(s, n, e) }
;

argumentLet:
| LPAR RPAR { [( "not_named", TUnit)]}
| v=variable* {v}
;
variable:
| LPAR id=IDENT DCOMMA t=type_ RPAR { (id, t) } 
;
sequence:
| e1=expression SEMI e2=expression { Seq(e1, e2) }
;
lists:
| e=simple_expression es=exprsemi* { [e] @ es }
;
exprsemi:
| SEMI e=simple_expression { e }
;
unop:
| MOINS e=expression %prec NEG { Uop(Neg, e) }
| NOT e=expression { Uop(Not, e) }
;
%inline binop:
| PLUS { Add }
| STAR { Mul }
| MOINS { Sub }
| DIV { Div }
| MOD { Mod }
| DEQ { Eq }
| NEQ { Neq }
| LT { Lt }
| LE { Le }
| AND { And }
| OR { Or }
;
