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
%token MUTABLE
%token TYPE
%token TRUE FALSE
(* () *)
%token UNIT
(* Paire *)
(* ( ) { } <-  ->*)
%token LPAR RPAR LBRA RBRA LARR RARR
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
(*%nonassoc CST IDENT TRUE FALSE*)
%right IDENT

(* priorite des point virgule*)
%nonassoc SEMI
(* priorite condit *)
%nonassoc THEN
%nonassoc ELSE

(* priorite fonction bool *)
%right OR
%right AND


(* priorite op bool*)
%nonassoc DEQ NEQ LT LE  
%right RARR LARR 

(* priorite des operateur *) 
%left PLUS MOINS
%left STAR DIV MOD 
%nonassoc NEG
%left NOT

(* priorite constante *)
%nonassoc TRUE FALSE CST

(* priorite des fleche parenthese et point virgule *)
%nonassoc LPAR LBRA 

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
| uop=unop { uop }
| e=expression s=simple_expression { App(e, s) }
| IF e1=expression THEN e2=expression { If(e1,e2, Unit)  }
| IF e1=expression THEN e2=expression ELSE e3=expression { If(e1,e2,e3) }
| FUN LPAR id=IDENT DCOMMA t=type_ RPAR RARR e=expression { Fun(id, t, e) }
| LET id=IDENT v=variable* EQ e1=expression IN e2=expression { Let(id, mk_fun v e1, e2) } 
| LET REC id=IDENT v=variable* DCOMMA t=type_ EQ e1=expression IN e2=expression {
  Let(id, Fix(id,mk_fun_type v t, mk_fun v e1 ),e2 )
} 
| s=simple_expression COMMA id=IDENT LARR e=expression { SetF(s, id, e) }
| seq_=sequence {seq_}
;

variable:
| LPAR id=IDENT DCOMMA t=type_ RPAR { (id, t) } 

sequence:
| e1=expression SEMI e2=expression { Seq(e1, e2) }

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
