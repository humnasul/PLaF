open ReM
open Dst
open Parser_plaf.Ast
open Parser_plaf.Parser

(*
   Humna Sultan and Michelle Elias Flores
   CS496 HW5 - 4/19/24
   I pledge my Honor that I have abided by the Stevens Honor System.
   *)
       
let rec chk_expr : expr -> texpr tea_result = function 
  | Int _n -> return IntType
  | Var id -> apply_tenv id
  | IsZero(e) ->
    chk_expr e >>= fun t ->
    if t=IntType
    then return BoolType
    else error "isZero: expected argument of type int"
  | Add(e1,e2) | Sub(e1,e2) | Mul(e1,e2)| Div(e1,e2) ->
    chk_expr e1 >>= fun t1 ->
    chk_expr e2 >>= fun t2 ->
    if (t1=IntType && t2=IntType)
    then return IntType
    else error "arith: arguments must be ints"
  | ITE(e1,e2,e3) ->
    chk_expr e1 >>= fun t1 ->
    chk_expr e2 >>= fun t2 ->
    chk_expr e3 >>= fun t3 ->
    if (t1=BoolType && t2=t3)
    then return t2
    else error "ITE: condition not boolean or types of then and else do not match"
  | Let(id,e,body) ->
    chk_expr e >>= fun t ->
    extend_tenv id t >>+
    chk_expr body
  | Proc(var,Some t1,e) ->
    extend_tenv var t1 >>+
    chk_expr e >>= fun t2 ->
    return @@ FuncType(t1,t2)
  | Proc(_var,None,_e) ->
    error "proc: type declaration missing"
  | App(e1,e2) ->
    chk_expr e1 >>=
    pair_of_funcType "app: " >>= fun (t1,t2) ->
    chk_expr e2 >>= fun t3 ->
    if t1=t3
    then return t2
    else error "app: type of argument incorrect"
  (* type-checking references *)
  | NewRef (e) -> 
    chk_expr e >>= fun ev ->
    return @@ RefType ev
  | DeRef (e) -> 
    chk_expr e >>=  fun ev ->
    (match ev with
    | (RefType x) -> return x
    | _ -> error "deref: invalid input")
  | SetRef (e1 , e2 ) -> 
    chk_expr e1 >>= fun n1 ->
    chk_expr e2 >>= fun n2 ->
    (match n1 with
    | (RefType x) -> (if x = n2 then return UnitType else error "setref: type mismatch")
    | _ -> error "setref: invalid input")
  | BeginEnd ([]) -> 
    return UnitType
  | BeginEnd ( es ) -> 
    (List.hd (List.rev (chk_exprs es) ) )
  (* type-checking lists *)
  | EmptyList (t) -> 
    (match t with 
    | Some x -> return (ListType x)
    | _ -> error "EmptyList: type mismatch")
  | Cons (e1 , e2 ) -> (* return type of e2 if types of e1 and e2 match, else return error *)
    chk_expr e1 >>= fun n1 ->
    chk_expr e2 >>= fun n2 ->
     (match n2 with
      | (ListType x) -> (if x = n1 then return n2 else error "cons : type of head and tail do not match")
      | _ -> error "cons: invalid input")
  | IsEmpty (e ) -> 
    chk_expr e >>= fun ev ->
    (match ev with
    | ListType _ | TreeType _ -> return (BoolType)
    | _ -> error "IsEmpty: type mismatch" )
  | Hd (e ) -> 
    chk_expr e >>= fun ev ->
      (match ev with
      | (ListType x) -> return x
      | _ -> error "Hd: invalid input")
  | Tl (e ) -> 
    chk_expr e >>= fun ev -> return ev
  (* type-checking trees *)
  | EmptyTree (t) -> 
    (match t with 
    | Some x -> return (TreeType x)
    | _ -> error "EmptyTree: type mismatch")
  | Node (de , le , re ) -> 
    chk_expr de >>= fun n1 ->
    chk_expr le >>= fun n2 ->
    chk_expr re >>= fun n3 ->
      (match n2,n3 with
      | TreeType x, TreeType y -> (if x=y && y=n1 then return n2 else error "Node: type mismatch")
      | _ -> error "Node: type mismatch")
  | CaseT ( target , emptycase , id1 , id2 , id3 , nodecase ) ->
    chk_expr target >>= fun e1 -> 
    (match e1 with
    | TreeType x -> chk_expr emptycase >>= fun e2 -> 
      extend_tenv id1 x >>+
      extend_tenv id2 e1 >>+
      extend_tenv id3 e1 >>+
      chk_expr nodecase >>= fun e3 -> (if e2=e3 then return e2 else error "CaseT: type mismatch")
    | _ -> error "CaseT: type mismatch")

  | Letrec([(_id,_param,None,_,_body)],_target) | Letrec([(_id,_param,_,None,_body)],_target) ->
    error "letrec: type declaration missing"
  | Letrec([(id,param,Some tParam,Some tRes,body)],target) ->
    extend_tenv id (FuncType(tParam,tRes)) >>+
    (extend_tenv param tParam >>+
     chk_expr body >>= fun t ->
     if t=tRes 
     then chk_expr target
     else error
         "LetRec: Type of recursive function does not match
declaration")
  | Debug(_e) ->
    string_of_tenv >>= fun str ->
    print_endline str;
    error "Debug: reached breakpoint"
  | _ -> failwith "chk_expr: implement"    
and
  chk_prog (AProg(_,e)) =
  chk_expr e

  and chk_exprs : expr list -> texpr tea_result list =
    fun es ->
      match es with
      | [] -> []
      | h :: t -> ( chk_expr h :: chk_exprs t )
    (* type check every value in BeginEnd *)


(* Type-check an expression *)
let chk (e:string) : texpr result =
  let c = e |> parse |> chk_prog
  in run_teac c

let chkpp (e:string) : string result =
  let c = e |> parse |> chk_prog
  in run_teac (c >>= fun t -> return @@ string_of_texpr t)


