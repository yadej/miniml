%{

  open Lexing
  open Mml
  open List

%}

(* les exp bool*)
%token EQ DEQ NEQ LT LE AND OR NEQS
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
(* ; : .  | , _*)
%token SEMI DPOINT POINT BAR COMMA UNDERSCORE
(* Condition *)
%token IF THEN ELSE
(* fonction *)
%token FUN 
%token LET REC IN
(* Print *)
%token PRINT
(*of*)
%token OF
%token MATCH WITH
(* End of line *)
%token EOF

(* priorite des let *)
%nonassoc IN
%right RARR
%nonassoc LBRA
%left DPOINT
%nonassoc POINT
%right LIST
(* priorite des point virgule*)
%right IDENT
%right SEMI
(* priorite condit *)
%nonassoc THEN
%nonassoc ELSE

(* priorite fonction bool *)
%right OR
%right AND

%right LARR 
(* priorite op bool*)

%right DEQ NEQ LT LE EQ NEQS

(* priorite des operateur *) 
%left PLUS MOINS
%left STAR DIV MOD

%nonassoc NEG
%left NOT
%nonassoc TRUE FALSE CST 
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
        (id1,  Typ_Strct st_def  ) 
   } 
| TYPE id=IDENT EQ enum_def=enumere_type_def+  { (id, Typ_Enum enum_def)}
;

struct_type_def:
| MUTABLE id=IDENT DPOINT t=type_ SEMI  { (id, t, true) }
| id=IDENT DPOINT t=type_ SEMI  { (id, t, false) }

enumere_type_def:
| BAR id=IDENT { (id, None) }
| BAR id=IDENT OF t=type_ { (id, Some t) }
| BAR id=IDENT OF t=type_ tl=typelist+ { (id, Some (TTuple (t::tl))) }

typelist:
| STAR t=type_ {t }

type_:
| INT { TInt }
| BOOLEAN { TBool }
| UNIT { TUnit }
| id=IDENT { TStrct(id) }
| t1=type_ RARR t2=type_ { TFun(t1,t2) }
| LPAR t=type_ RPAR { t }
| t=type_ LIST { TList(t) }
| LPAR t=type_ tu=tuple+ RPAR { TTuple (t::tu) }
;

simple_expression:
| n=CST { Int(n) }
| TRUE { Bool(true) }
| FALSE { Bool(false) }
| LPAR RPAR { Unit }
| id=IDENT { Var(id) }
| s=simple_expression POINT id=IDENT { GetF(s, id) }
| LBRA stsimpexp=struct_simple_exp+ RBRA { Strct( stsimpexp ) } 
| LPAR e=expression RPAR { e }
| LPAR e=expression te=tupleexpr+ RPAR { Tuple (e::te) }
| LCRO l=lists RCRO { List(l) }
| LCRO RCRO {List([])}
| s=simple_expression DPOINT DPOINT s2=simple_expression { AppList(s, s2) }
| s=simple_expression POINT LCRO n=CST RCRO { GetList(s, n) }
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
| FUN LPAR id=IDENT DPOINT t=type_ RPAR RARR e=expression { Fun(id, t, e) }
| LET id=IDENT v=argumentLet EQ e1=expression IN e2=expression { Let(id, mk_fun v e1, e2) } 
| LET REC id=IDENT v=argumentLet DPOINT t=type_ EQ e1=expression IN e2=expression {
  Let(id, Fix(id,mk_fun_type v t, mk_fun v e1 ),e2 )
} 
| s=simple_expression POINT id=IDENT LARR e=expression { SetF(s, id, e) }
| seq_=sequence {seq_}
| s=simple_expression POINT LCRO n=CST RCRO LARR e=expression { SetList(s, n, e) }
| PRINT LPAR s=simple_expression RPAR { Print(s) }
(*| MATCH s=simple_expression WITH el=matchexpr+ { Match(s,el) }*)
;

argumentLet:
| LPAR RPAR { [( "not_named", TUnit)]}
| v=variable* {v}
;
variable:
| LPAR id=IDENT DPOINT t=type_ RPAR { (id, t) } 
;
sequence:
| e1=expression SEMI e2=expression { Seq(e1, e2) }
;
lists:
| e=simple_expression es=exprsemi* { [e] @ es }
;
tuple:
| STAR t=type_ { t }
tupleexpr:
| COMMA e=expression { e }
exprsemi:
| SEMI e=simple_expression { e }
;
(*matchexpr:
| BAR e1=simple_expression RARR e2=simple_expression { (e1, e2) }
| BAR UNDERSCORE RARR s=simple_expression { (JokerMatch, s) }*)
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
| EQ { Eqs }
| NEQS { Neqs }
;
