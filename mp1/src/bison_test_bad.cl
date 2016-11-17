(* no error *)
class A {
};

(* error:  b is not a type identifier *)
Class b inherits A {
};

(* error:  a is not a type identifier *)
Class C inherits a {
};

(* error:  keyword inherits is misspelled *)
Class D inherts A {

    (*error: The definition of the feature is wrong *)
    a : 123 <- 666;
    (*error: The definition of the feature is wrong *)
    b : 123;
};

Class E inherits A {
    (* error: The definition of the function is wrong *)
    test1 ( ) : 123 {
        (* error: The definition int let is wrong *)
        let x : 123, y : 456 in 
        {
            123+456;
        }
    };
};

Class F inherits A {
    test1 ( ) : String {
        let x : String in 
        {
            (* error: The expression is wrong *)
            1++++;
        }
    };
    test2 ( ) : Int {
        let x : String in 
        {
            case x of
                (* error: The branch is not correct *)
                z : 123;
                (* error: The branch is not correct *)
                z : 456
            esac;
        }
    };
};

(* error: The semicolon is missed *)
class G inherits A {

}

(* error: The '}' is missed *)
Class H inherits A {
;

Class I inherits A {
     test1 ( ) : String {
        let x : String in 
        {
            (* error: The expression is wrong *)
            test2( 123+ );
        }
    };
    (* error: The formal is wrong *)
    test2 ( a : 666, ) : Int {

    };
};
