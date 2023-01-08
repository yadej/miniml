(* Syntaxe abstraite Mini-ML *)

type typ = 
  | TInt 
  | TBool
  | TUnit
  | TFun of typ * typ
  | TStrct of string
  | TList of typ
  | TTuple of typ list
type strct = 
  | Typ_Strct of (string * typ * bool) list
  | Typ_Enum of (string * typ option) list

let rec typ_to_string = function
  | TInt  -> "int"
  | TBool -> "bool"
  | TUnit -> "unit"
  | TFun(typ1, typ2) -> 
     Printf.sprintf "(%s) -> %s" (typ_to_string typ1) (typ_to_string typ2)
  | TStrct s -> Printf.sprintf "Struct %s" s
  | TList l -> Printf.sprintf "List %s" (typ_to_string l)
  | TTuple [x] -> Printf.sprintf "%s" (typ_to_string x)
  | TTuple (x::s) -> Printf.sprintf "%s * %s " (typ_to_string x) (typ_to_string (TTuple s))
  | TTuple [] -> Printf.sprintf ""

type uop = Neg | Not
type bop = Add | Sub | Mul | Div | Mod | Eq | Neq | Lt | Le | And | Or | Eqs | Neqs
 
type expr =
  | Int   of int
  | Bool  of bool
  | Unit
  | Uop   of uop * expr
  | Bop   of bop * expr * expr
  | Var   of string
  | Let   of string * expr * expr
  | If    of expr * expr * expr
  | Fun   of string * typ * expr
  | App   of expr * expr
  | Fix   of string * typ * expr
  | Strct of (string * expr) list
  | GetF  of expr * string
  | SetF  of expr * string * expr
  | Seq   of expr * expr
  | List of expr list
  | AppList of expr * expr
  | GetList of expr * int
  | SetList of expr * int * expr
  | Print of expr
  | Tuple of expr list
type prog = {
    types: (string * strct) list;
    code: expr;
  }

(* Fonctions auxiliaires, utilisables pour gérer le sucre syntaxique
     let f (x1:t1) ... (xN:tN) = ...
   de définition d'une fonction à plusieurs arguments. *)
let rec mk_fun xs e = match xs with
  | [] -> e
  | (x, t)::xs -> Fun(x, t, mk_fun xs e)
  
let rec mk_fun_type xs t = match xs with
  | [] -> t
  | (_, t')::xs -> TFun(t', mk_fun_type xs t)
