
(*
 *  execute "coolc bad.cl" to see the error messages that the coolc parser
 *  generates
 *
 *  execute "myparser bad.cl" to see the error messages that your parser
 *  generates
 *)

(* no error *)
class A {
};

class G inherits A {
    a : Int <- { 123- };
    test1 ( ) : Int {
        let x : 666, y : 666 in {
            while 1+1 loop 1-1 pool;
            if true then 1+1 else 1-1 fi;
            x <- 1+1*1/1-1*1-(2*
            5)=3+(3-3)/358*
            5-5+65;
            y <- x <- 1;
            case x of
                y : Int => true;
                z : Object => 
                false;
            esac;
            y <- not 3-3;
            x <- ~6; 
        }
    };
};

(* error:  b is not a type identifier *)
Class b inherits A {
};

(* error:  a is not a type identifier *)
Class C inherits a {
};

(* error:  keyword inherits is misspelled *)
Class D inherts A {
};

Class F inherits A {
};