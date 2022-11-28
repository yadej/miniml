open Mml

(* Environnement de typage : associe des types aux noms de variables *)
module SymTbl = Map.Make(String)
type tenv = typ SymTbl.t

(* Pour remonter des erreurs circonstanciées *)
exception Type_error of string
let error s = raise (Type_error s)
let type_error ty_actual ty_expected =
  error (Printf.sprintf "expected %s but got %s" 
           (typ_to_string ty_expected) (typ_to_string ty_actual))
(* vous pouvez ajouter d'autres types d'erreurs *)

(* Vérification des types d'un programme *)
let type_prog prog =

  (* Vérifie que l'expression [e] a le type [type] *)
  let rec check e typ tenv =
    let typ_e = type_expr e tenv in
    if typ_e <> typ then type_error typ_e typ

  (* Calcule le type de l'expression [e] *)
  and type_expr e tenv = match e with
    | Int _  -> TInt
    | Bool _ -> TBool
    | Var x ->  TStrct(x)
    | Unit -> TUnit
    | Uop(Neg, e) ->
      check e TInt tenv; TInt
    | Uop(Not, e) ->
      check e TBool tenv; TBool
    | Bop((Add | Mul | Sub | Div | Mod), e1, e2) -> 
       check e1 TInt tenv; check e2 TInt tenv; TInt
    | Bop(( Lt | Le ), e1, e2) ->
      check e1 TInt tenv; check e2 TInt tenv; TBool
    | Bop(( And | Or), e1, e2) ->
      check e1 TBool tenv; check e2 TBool tenv; TBool
    | Bop(( Eq | Neq ), e1, e2) ->
        let typ_e1 = type_expr e1 tenv in
        let typ_e2 = type_expr e2 tenv in
        check e1 typ_e2 tenv;check e2 typ_e1 tenv;TBool
    | Let(x, e1, e2) ->
      let typ_e1 = type_expr e1 tenv in
      let typ_e2 = type_expr e2 tenv in
      typ_e2
    
  in

  type_expr prog.code SymTbl.empty
