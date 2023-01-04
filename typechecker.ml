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
    let check2 = begin match typ_e with
    | TList(_) when e = List([]) -> true
    | _ -> false
    end in
    if typ_e <> typ && check2 then type_error typ_e typ

  (* Calcule le type de l'expression [e] *)
  and type_expr e tenv = match e with
    | Int _  -> TInt
    | Bool _ -> TBool
    | Var x ->( try  SymTbl.find x tenv 
            with Not_found -> find_enum(x, prog.types))
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
    | Bop(( Eq | Neq | Eqs | Neqs ), e1, e2) ->
        let typ_e1 = type_expr e1 tenv in
        check e2 typ_e1 tenv;TBool
    | Let(x, e1, e2) ->
      let typ_e1 = type_expr e1 tenv in
      let tenv' = SymTbl.add x typ_e1 tenv in
      let typ_e2 = type_expr e2 tenv' in
      typ_e2
    | If(e1, e2, e3) ->
      let typ_e3 = type_expr e3 tenv in
      check e1 TBool tenv;
      check e2 typ_e3 tenv;
      typ_e3
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
      if typ_e1 = TUnit then Printf.printf "this expresion is not unit";
      let typ_e2 = type_expr e2 tenv in
      typ_e2
    | GetF(e', s) ->
      let typ_e' = type_expr e' tenv in
      let typ_se' = el_s typ_e' in
      let program_type = prog.types in
      let rec trouve_type = function
      | (nom', t, _)::next-> if nom' = s then t else (trouve_type  next)
      | _ -> assert false
      in
      let typ_s = trouve_type ( f_str(program_type, typ_se')  )in
      typ_s
    | SetF(e1, s, e2) -> 
      (* On cherche les struct dans les types pour savoir si c'est mutable*)
      let typ_e1 = type_expr e1 tenv in
      let typ_se' = el_s typ_e1 in
      let program_type = prog.types in
      let rec trouve_type = function
      |  ( (nom', t, b)::next ) -> if nom' = s then (t, b) else trouve_type(next)
      | _ -> assert false
      in
      let (t1, b) = trouve_type(f_str(program_type, typ_se')) in
      if not b then raise (Type_error "cette variable n'est pas mutable");check e2 t1 tenv;
      TUnit
    | Strct( l ) as st ->
       let program_type = prog.types in
       let (nom, t) = find_struct(st, program_type, tenv) in
       TStrct(nom)
    | List l -> begin match l with
      | [] -> TStrct("alpha") (* Je fais un random car il sait pas vraiment*)
      |  x::s ->
        let typ_x = type_expr x tenv in
        checkList(s,typ_x,tenv)
      end
    | AppList(x, l) ->
      let typ_x = type_expr x tenv in
      check l (TList(typ_x)) tenv;
      TList(typ_x)
    | GetList(e, n) ->
      let typ_e = type_expr e tenv in
      begin match typ_e with
      | TList(l) -> l
      | _ -> error (Printf.sprintf "%s n'est pas de type list" (typ_to_string typ_e ))
      end
    | SetList(e1, n, e2) ->
      let typ_e1 = type_expr e1 tenv in
      begin match typ_e1 with
      | TList(l) -> check e2 l tenv;TUnit
      | _ -> error (Printf.sprintf "%s n'est pas de type list" (typ_to_string typ_e1 ))
      end
    | Print(e) -> ignore(type_expr e tenv); TUnit
    and eq_struct = function
      (* Regarde pour chaque nom et type que c est les meme que dans la structure*)
    | Strct((k, b)::r1), ( a,(Typ_Strct ((s, t, boolean)::r2))) , tenv
    when  String.compare k s == 0 && (type_expr b tenv) = t  ->
      eq_struct( Strct(r1),(a,(Typ_Strct r2)) , tenv)
    | Strct([]), (_, (Typ_Strct [])) , tenv-> true
    | _ -> false
    and find_struct = function
      (* Regarde pour chaque structure si il correspond a st*)
    | st, t1::t2 , tenv-> if eq_struct(st, t1, tenv) then t1 
    else find_struct(st, t2, tenv)
    | _ -> error (Printf.sprintf "Cette structure n'est pas defini")
    and el_s = function
    | TStrct(new_s) -> new_s
    | _ -> assert false
    and f_str = function
    | (nom, Typ_Strct strc)::a2, nomtype -> 
       if nom = nomtype then strc 
    else f_str(a2, nomtype)
    | _ -> assert false
    and checkList = function
    |[], typ, tenv -> TList(typ)
    | x::s, typ, tenv -> check x typ tenv; checkList (s, typ, tenv)
    and find_enum = function
    | s, t1::t2 -> if eq_enum(s,snd t1) then TStrct(fst t1) else find_enum(s, t2)
    | s, [] -> error (Printf.sprintf "%s n'est pas defini" s)
    and eq_enum = function
    | s, Typ_Enum te -> List.exists (fun x  -> x = s) te
    | _ -> false
  in
  type_expr prog.code SymTbl.empty
