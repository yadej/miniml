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
    | Var x ->( try  SymTbl.find x tenv 
            with Not_found -> raise (Type_error "x n'est pas dans la map"))
    | Unit -> TUnit
    | Uop(Neg, e') ->
      check e' TInt tenv; TInt
    | Uop(Not, e') ->
      check e' TBool tenv; TBool
    | Bop((Add | Mul | Sub | Div | Mod), e1, e2) -> 
       check e1 TInt tenv; check e2 TInt tenv; TInt
    | Bop(( Lt | Le ), e1, e2) ->
      check e1 TInt tenv; check e2 TInt tenv; TBool
    | Bop(( And | Or), e1, e2) ->
      check e1 TBool tenv; check e2 TBool tenv; TBool
    | Bop(( Eq | Neq ), e1, e2) ->
        let typ_e1 = type_expr e1 tenv in
        (*le deuxieme check ne sert pas a grand chose mais pour etre sur*)
        let typ_e2 = type_expr e2 tenv in
        check e1 typ_e2 tenv;check e2 typ_e1 tenv;TBool
    | Let(x, e1, e2) ->
      let typ_e1 = type_expr e1 tenv in
      let tenv' = SymTbl.add x typ_e1 tenv in
      let typ_e2 = type_expr e2 tenv' in
      typ_e2
    | If(e1, e2, e3) ->   
      let typ_e2 = type_expr e2 tenv in
      check e1 TBool tenv;check e3 typ_e2 tenv;typ_e2
    | Fun(x, t, e') ->
      let tenv' = SymTbl.add x t tenv in
      check (Var(x)) t tenv';
      let typ_e = type_expr e' tenv' in
      TFun(t, typ_e)
    | App(e1, e2) ->
      let t2 = type_expr e2 tenv in
      (match type_expr e1 tenv with
      | TFun(t, t1) when t = t2 -> t1
      | _ -> raise (Type_error "application de e1 a e2 mais e1 n ai pas une app " ))
    | Fix(x, t, e') ->
      let tenv' = SymTbl.add x t tenv in
      let typ_e = type_expr e' tenv' in
      typ_e
    | Seq(e1, e2) ->
      let typ_e1 = type_expr e1 tenv in
      let typ_e2 = type_expr e2 tenv in
      typ_e2
    | GetF(e', s) ->
      let program_type = prog.types in
      let nom = type_expr e' tenv in
      let rec f_str = function
      | TStrct(l), ((s', a)::r) -> if s' = l then a else
        (f_str ((TStrct(l)), r))
      | _ -> assert false
      in
      let typ_s = (typ_f((f_str (nom,program_type) ), s))  in
      typ_s
    | SetF(e1, s, e2) -> 
      Printf.printf "je suis passe par SetF";
      (* On cherche les struct dans les types pour savoir si c'est mutable*)
      let program_type = prog.types in
      
      let t = snd (find_struct(e1, program_type , tenv)) in
      let rec find_t_mutable = function
      | s1 , (s2, t, b)::r -> if String.compare s1 s2 == 0 then
        (t, b) else find_t_mutable(s1, r)
      | _ -> raise (Type_error  "cette variable n appartient pas a la structure")
      in
      let (t , b) = find_t_mutable(s, t) in
      if not b then raise (Type_error "cette variable n'est pas mutable");check e2 t tenv;
      
      TUnit
    | Strct( l ) as st ->
       let program_type = prog.types in
       let (nom, t) = find_struct(st, program_type, tenv) in
       TStrct(nom)
    and typ_f = function
      (* Regarde dans la structure si le nom correspond 
         a un nom de type dans la structure 
         puis on donne son type *)
    | (k, b, _)::r , s -> Printf.printf "k: %s == s: %s"k s;
       if s == k  then b  
    else typ_f(r, s)
    | _ -> assert false
    and eq_struct = function
      (* Regarde pour chaque nom et type que c est les meme que dans la structure*)
    | Strct((k, b)::r1), ( a, (s, t, boolean)::r2) , tenv
    when  String.compare k s == 0 && (type_expr b tenv) = t  ->
      eq_struct( Strct(r1),(a,(r2)) , tenv)
    | Strct([]), (_, []) , tenv-> true
    | _ -> false
    and find_struct = function
      (* Regarde pour chaque structure si il correspond a st*)
    | st, t1::t2 , tenv-> if eq_struct(st, t1, tenv) then t1 
    else find_struct(st, t2, tenv)
    | _ -> Printf.printf "je fail find_struct";assert false
  in

  type_expr prog.code SymTbl.empty
