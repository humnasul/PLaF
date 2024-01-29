let letter_e = [0;2;2;3;3;5;5;4;3;5;4;3;3;5;5;1]

let mirror_image : int -> int =
  fun n ->
    match n with
    | 3 -> 5
    | 5 -> 3
    | 2 -> 4
    | 4 -> 2
    | 1 -> 1
    | 0 -> 0
    | _ -> failwith "Invalid encoding to mirror"


let rotate_90_letter : int -> int =
  fun n ->
    match n with
    | 3 -> 4
    | 5 -> 2
    | 2 -> 3
    | 4 -> 5
    | 1 -> 1
    | 0 -> 0
    | _ -> failwith "Invalid encoding to mirror"

- rotate_90_word
- repeat
- pantograph
- coverage
- compress
- uncompress
- optimize