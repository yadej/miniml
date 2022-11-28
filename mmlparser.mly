%{

  open Lexing
  open Mml
  open List
  
  let rec get_tuple_fun = function
  | (a ,b)::s, e -> Fun(a, b, get_tuple_fun (s,e ) )
  | _, e -> e

  let rec get_tuple_type = function
  | (_, b)::s, t -> TFun(b, get_tuple_type(s, t))
  | _, t -> t 
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

(* priorite constante *)
%nonassoc CST
%nonassoc IDENT
%nonassoc TRUE FALSE
(*%nonassoc CST IDENT TRUE FALSE*)
(* priorite des point virgule*)
%right SEMI
(* priorite condit *)
%nonassoc THEN
%nonassoc ELSE
(* priorite fonction bool *)
%nonassoc AND OR
%right DEQ NEQ LT LE  
(* priorite des operateur *) 
%left PLUS MOINS
%left STAR DIV MOD
%nonassoc NEG NOT
(* priorite des fleche parenthese et point virgule *)
%right RARR LARR 
%nonassoc LPAR LBRA 
(* priorite des let *)
%nonassoc IN

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
| LET id=IDENT v=variable* EQ e1=expression IN e2=expression { Let(id, get_tuple_fun(v ,e1), e2) } 
| LET REC id=IDENT v=variable* DCOMMA t=type_ EQ e1=expression IN e2=expression {
  Let(id, Fix(id,get_tuple_type (v, t), get_tuple_fun(v, e1) ),e2 )
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
