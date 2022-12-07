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
(* Élements du tas *)
type heap_value =
  | VClos  of string * expr * value Env.t
  | VStrct of (string, value) Hashtbl.t

let print_value = function
  | VInt n  -> Printf.printf "%d\n" n
  | VBool b -> Printf.printf "%b\n" b
  | VUnit   -> Printf.printf "()\n"
  | VPtr p  -> Printf.printf "@%d\n" p

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
    | Var x -> Env.find x env 
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
    | Uop(Not, e) -> VBool( not (evalb e env))
    | Let(x, e1, e2)  -> 
      let env' = Env.add x (eval e1 env) env in eval e2 env'
    | Fix(s, t, e) -> (match e with
      | Fun(_,_,_) | Strct(_)  ->
        eval e env
      | _ -> assert false
      ) 
    | Fun(x, t, e) -> let n = new_ptr() in
       Hashtbl.add mem n (VClos(x, e, env)); VPtr(n)
    | App(e1, e2) ->
      let var = eval e2 env in 
      begin match Hashtbl.find mem (evalptr e1 env) with
      | VClos(x, e, env') -> 
          let new_env = Env.add x var env' in
          eval e new_env
      | _ -> assert false
        end
    | If(e1, e2, e3) -> if (evalb e1 env) then eval e2 env 
      else eval e3 env
    | GetF(e, x) -> 
        begin match Hashtbl.find mem (evalptr e env) with
        | VStrct(mem2)  ->Hashtbl.find mem2 x
        | _ -> assert false
      end
    | SetF(e1, x, e2) ->  eval e1 env
    | Strct( l ) -> let n = new_ptr () in
      let (mem_struct:(string, value) Hashtbl.t) = Hashtbl.create (List.length l  + 1) in 
      let rec aux = function
      | (a, b)::r -> Hashtbl.add mem_struct a (eval b env); aux r
      | _ -> ()
      in aux l;
      Hashtbl.add mem n (VStrct(mem_struct)); VPtr(n)     
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
    |_, _ -> false
  and evalptr (e: expr) (env: value Env.t): int =
    begin match eval e env with
        | VPtr(n) -> n
        | _ -> assert false
    end
  in

  eval p.code Env.empty
