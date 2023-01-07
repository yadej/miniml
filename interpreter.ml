(* Interprète Mini-ML *)

open Mml

(* Environnement : associe des valeurs à des noms de variables *)
module Env = Map.Make(String)

(* Valeurs *)
type value =
  | VInt   of int
  | VBool  of bool
  | VUnit
  | VPtr   of int
  | VString of string
  | VTuple of value list
(* Élements du tas *)
type heap_value =
  | VClos  of string * expr * value Env.t
  | VStrct of (string, value) Hashtbl.t
  | VList of value list
  | VAlg of string * value

let rec print_value = function
  | VInt n  -> Printf.printf "%d\n" n
  | VBool b -> Printf.printf "%b\n" b
  | VUnit   -> Printf.printf "() \n "
  | VPtr p  -> Printf.printf "@%d\n" p
  | VString s -> Printf.printf "%s\n" s
  | VTuple t -> Printf.printf "("; (print_value_without_space (List.hd t));
      List.iter (fun x -> Printf.printf ", ";(print_value_without_space x)) (List.tl t );
      Printf.printf ")\n"
and print_value_without_space = function
| VInt n  -> Printf.printf "%d" n
| VBool b -> Printf.printf "%b" b
| VUnit   -> Printf.printf "()  "
| VPtr p  -> Printf.printf "@%d" p
| VString s -> Printf.printf "%s" s
| VTuple t -> Printf.printf "("; (print_value (List.hd t));
    List.iter (fun x -> Printf.printf ", ";(print_value x)) (List.tl t );
    Printf.printf ")"

(* Interprétation d'un programme complet *)
let eval_prog (p: prog): value =
  
  (* Initialisation de la mémoire globale *)
  let (mem: (int, heap_value) Hashtbl.t) = Hashtbl.create 16 in

  (* Création de nouvelles adresses *)
  let new_ptr =
    let cpt = ref 0 in
    fun () -> incr cpt; !cpt
  in

  (* Interprétation d'une expression, en fonction d'un environnement
     et de la mémoire globale *)
  let rec eval (e: expr) (env: value Env.t): value = 
    match e with
    | Int n  -> VInt n
    | Bool b -> VBool b
    | Unit -> VUnit
    | JokerMatch -> VUnit
    | Var x -> (try Env.find x env with Not_found -> VString(x) )
    | Tuple l -> VTuple( eval_list l env )
    | Bop(Add, e1, e2) -> VInt (evali e1 env + evali e2 env)
    | Bop(Mul, e1, e2) -> VInt (evali e1 env * evali e2 env)
    | Bop(Sub, e1, e2) -> VInt (evali e1 env - evali e2 env)
    | Bop(Div, e1, e2) -> VInt (evali e1 env / evali e2 env)
    | Bop(Mod, e1, e2) -> VInt (evali e1 env mod evali e2 env)
    | Uop(Neg, e) -> VInt(- evali e env)
    | Bop(Lt, e1, e2) -> VBool (evali e1 env < evali e2 env)
    | Bop(Le, e1, e2) -> VBool (evali e1 env <= evali e2 env)
    | Bop(And, e1, e2) -> VBool (evalb e1 env && evalb e2 env)
    | Bop(Or, e1, e2) -> VBool (evalb e1 env || evalb e2 env)
    | Seq(e1, e2) -> eval e1 env; eval e2 env
    | Bop(Eq, e1, e2) -> VBool (evalequal e1 e2 env)
    | Bop(Neq, e1, e2) -> VBool (not (evalequal e1 e2 env))
    | Bop(Eqs, e1, e2) -> VBool (eval_eqs e1 e2 env)
    | Bop(Neqs, e1, e2) -> VBool (not (eval_eqs e1 e2 env))
    | Uop(Not, e) -> VBool( not (evalb e env))
    | Let(x, e1, e2)  -> 
      let env' = Env.add x (eval e1 env) env in eval e2 env'
    | Fix(s, t, e) -> 
      let n = new_ptr() in
       begin match  e with 
      | Strct(l) -> let (mem_struct:(string, value) Hashtbl.t) = Hashtbl.create (List.length l  + 1) in 
        let () = List.iter (fun (x,y) -> Hashtbl.add mem_struct x (eval y env)) l in
        Hashtbl.add mem n (VStrct(mem_struct)); VPtr(n)
      | Fun(_, _,_ ) -> Hashtbl.add mem n (VClos(s, e, env)); VPtr(n) 
      | _ -> assert false
      end
    | Fun(x, t, e) -> let n = new_ptr() in
       Hashtbl.add mem n (VClos(x, e, env)); VPtr(n)
    | App(e1, e2) ->
      let var = eval e2 env in 
      begin match Hashtbl.find_opt mem (evalapp e1 env) with
      | Some VClos(x, e, env') -> if Var(x) = e1 then eval (App(e, e2)) env else
          let new_env = Env.add x var env' in
          eval e new_env
      | None -> let x = (fun (VString x) -> x) (eval e1 env)  in
         let n = new_ptr() in
         Hashtbl.add mem n (VAlg(x, var));VPtr(n)
      | _ -> assert false
        end
    | If(e1, e2, e3) -> if (evalb e1 env) then eval e2 env 
      else eval e3 env
    | GetF(e, x) -> 
        begin match Hashtbl.find mem (evalptr e env) with
        | VStrct(mem2)  -> Hashtbl.find mem2 x
        | _ -> assert false
      end
    | SetF(e1, x, e2) -> begin match Hashtbl.find mem (evalptr e1 env) with
        | VStrct(mem2) -> Hashtbl.replace mem2 x (eval e2 env); VUnit
        | _ -> assert false
    end
    | Strct( l ) -> let n = new_ptr () in
      let (mem_struct:(string, value) Hashtbl.t) = Hashtbl.create (List.length l  + 1) in 
      let rec aux = function
      | (a, b)::r -> Hashtbl.add mem_struct a (eval b env); aux r
      | _ -> ()
      in aux l;
      Hashtbl.add mem n (VStrct(mem_struct)); VPtr(n) 
    | List l -> let n = new_ptr () in
        Hashtbl.add mem n (VList(eval_list l env)); VPtr(n)
    | AppList(x, e) -> let val_x = eval x env in
       let n = evalptr e env in
       begin match Hashtbl.find mem n with
      | VList(l) -> Hashtbl.replace mem n (VList( val_x::l )); VPtr(n)
      | _ -> assert false
      end    
    | GetList(e, n) -> begin match Hashtbl.find mem (evalptr e env) with
      | VList(l) ->  List.nth l n
      | _ -> assert false
      end
    | SetList(e1, n, e2) -> let pos = evalptr e1 env in
       begin match Hashtbl.find mem pos with
      | VList(l) ->  let replace l pos a = List.mapi (fun i x -> if i = pos then a else x) l in
            let evale1 = VList( (replace l n (eval e2 env) )) in
            Hashtbl.replace mem pos evale1; VUnit
      | _ -> assert false 
      end
    | Print(e) -> print_eval (eval e env);Printf.printf "\n" ; VUnit
  (* Évaluation d'une expression dont la valeur est supposée entière *)
  and evali (e: expr) (env: value Env.t): int = 
    match eval e env with
    | VInt n -> n
    | _ -> assert false
  (* Evaluation d'une expression dont la valeur est supposee booleene *)
  and evalb (e: expr) (env: value Env.t): bool =
    match eval e env with
    | VBool b -> b
    | _ -> assert false
  and evalequal (e1: expr) (e2: expr) (env: value Env.t): bool =
    match (eval e1 env), (eval e2 env) with
    |VInt a, VInt b -> a = b
    |VBool a ,VBool b -> a = b
    |VPtr a, VPtr b -> a = b
    |VString a, VString b -> a = b
    |_, _ -> false
  and evalptr (e: expr) (env: value Env.t): int =
    begin match eval e env with
        | VPtr(n) -> n
        | _ -> failwith "ce n'est pas une fonction"
    end
  and evalapp (e: expr) (env: value Env.t): int =
    begin match eval e env with
        | VPtr(n) -> n
        | VString(_) -> -1
        | _ -> failwith "ce n'est pas une fonction"
    end
  and eval_list (el: expr list) (env: value Env.t): value list =
    let rec evalAllList = function
    | [] -> []
    | x::s -> (eval x env)::(evalAllList s)
    in
    evalAllList el
  and print_eval (v: value): unit =
    begin match v with
    | VInt n -> Printf.printf "%d " n
    | VBool b -> Printf.printf "%b " b
    | VUnit   -> Printf.printf "() "
    | VPtr p  -> print_eval_vprt p 
    | VString s -> Printf.printf "%s" s
    | VTuple l -> Printf.printf "(";(print_eval (List.hd l));
        List.iter (fun x -> Printf.printf ", "; print_eval x) (List.tl l);Printf.printf ")"
    end
  and print_eval_vprt (n: int): unit =
    begin match Hashtbl.find mem n with
    | VClos(x,Fun(_), env')|VClos(x,Fix(_), env') -> Printf.printf "%d " n
    | VClos(_, e, env') -> print_eval (eval e env')
    | VStrct(l) -> Printf.printf "{ "; 
          Hashtbl.iter (fun x y -> Printf.printf "%s = " x; print_eval y; Printf.printf ";" ) l;
          Printf.printf "}"
    | VList( l ) -> Printf.printf "[";
        (List.iter print_eval l );
        Printf.printf "]" 
    | VAlg(s, v) -> Printf.printf "%s " s; print_eval v
    end
    and eval_eqs (e1: expr) (e2: expr) (env: value Env.t): bool = 
      eval_eq_structurelle (eval e1 env) (eval e2 env) env
    and eval_eq_structurelle (v1: value) (v2: value) (env: value Env.t): bool =
    match v1, v2 with
    |VInt a, VInt b -> a = b
    |VBool a ,VBool b -> a = b
    |VPtr a, VPtr b -> eval_eq_struct_heap_value a b env
    |VString a, VString b -> a = b
    |VTuple a, VTuple b -> List.for_all2 (fun x y -> eval_eq_structurelle x y env) a b
    |_, _ -> false
    and eval_eq_struct_heap_value (n1: int) (n2: int) (env: value Env.t): bool =
    match (Hashtbl.find mem n1),(Hashtbl.find mem n2) with
    | (VClos(_, (Fun(_)|Fix(_)), _)), (VClos(_, (Fun(_)|Fix(_)), _)) -> failwith ("Comparison with 2 functions ")
    | (VList l1), (VList l2) -> List.for_all2 (fun x y -> eval_eq_structurelle x y env) l1 l2
    | (VStrct s1), (VStrct s2) -> let l = Hashtbl.fold (fun k v acc -> (k, v)::acc) s1 [] in
      List.for_all (fun (x,y)-> try  eval_eq_structurelle (Hashtbl.find s2 x) y env with Not_found -> false  ) l
    | (VClos(_, e1, _)), (VClos(_, e2, _)) -> eval_eqs e1 e2 env
    | (VAlg(s1, v1)), (VAlg(s2, v2)) ->  if s1 = s2 then eval_eq_structurelle v1 v2 env 
        else false
    | _ -> false

  in

  eval p.code Env.empty
