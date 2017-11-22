(*
 * Copyright (c) 2017 Takahisa Watanabe <linerlock@outlook.com> All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *)
open OUnit2
open Metal
open Metal.Iso

let success r s f =
  match Parser.read (fun () -> r) s with
  | Some x ->
    f x
  | None ->
    assert_failure ""
      
let failure r s =
  match Parser.read (fun () -> r) s with
  | Some r ->
    assert_failure ""
  | None ->
    ()

type 'a exp = Base of 'a | Binop of 'a exp * 'a exp
let base_iso =
  { fwd = (function x0 -> Some (Base x0));
    bwd = (function Base x0 -> Some x0 | _ -> None)
  }
let binop_iso =
  { fwd = (function (e0, e1) -> Some (Binop (e0, e1)));
    bwd = (function Binop (e0, e1) -> Some (e0, e1) | _ -> None)
  }

let _ =
  run_test_tt_main begin "Parser" >::: [
      "char" >:: begin fun _ ->
        success Parser.char "a" (fun real -> assert_equal real 'a');
        success Parser.char "ab" (fun real -> assert_equal real 'a');
      end;
      "lower" >:: begin fun _ ->
        success Parser.lower "a" (fun real -> assert_equal real 'a');
        failure Parser.lower "A"
      end;
      "upper" >:: begin fun _ ->
        success Parser.upper "A" (fun real -> assert_equal real 'A');
        failure Parser.upper "a"
      end;
      "digit" >:: begin fun _ ->
        success Parser.digit "0" (fun real -> assert_equal real '0');
        success Parser.digit "1" (fun real -> assert_equal real '1');
        failure Parser.digit "a"
      end;
      "chainl1" >:: begin fun _ ->
        success Parser.(chainl1 binop_iso (char <$ element '+') (base_iso <$> char)) "1+2+3"
          (fun real -> assert_equal real (Binop (Binop (Base '1', Base '2'), Base '3')));
        success Parser.(chainl1 binop_iso (char <$ element '+') (base_iso <$> char)) "1"
          (fun real -> assert_equal real (Base '1'));
        success Parser.(chainl1 binop_iso (char <$ element '+') (base_iso <$> char)) "1-2-3"
          (fun real -> assert_equal real (Base '1'));
      end;
      "chainr1" >:: begin fun _ ->
        success Parser.(chainr1 binop_iso (char <$ element '+') (base_iso <$> char)) "1+2+3"
          (fun real -> assert_equal real (Binop (Base '1', Binop (Base '2', Base '3'))));
        success Parser.(chainr1 binop_iso (char <$ element '+') (base_iso <$> char)) "1"
          (fun real -> assert_equal real (Base '1'));
        success Parser.(chainr1 binop_iso (char <$ element '+') (base_iso <$> char)) "1-2-3"
          (fun real -> assert_equal real (Base '1'));
      end
    ]
  end
