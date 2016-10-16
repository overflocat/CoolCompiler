class A {
};

Class BB__ inherits A {
    a : Int;
    b : Int <- 2;
    test1 ( ) : Int { 1 };
    test2 ( x : Int, y : A ) : Int { x };
}; -- Features

Class C inherits A {
    test1 ( ) : String {
        let x : String in 
        {
            "string";
        }
    };
    test2 ( ) : Bool {
        let x : Bool <- true in {
            x <- false;
        }
    };
    test3 ( a : Int, b : Int ) : Int {
        let x : Bool <- true, 
        y : Bool <- false, z : Int in 1 
        + 1
    };
}; -- Let struct

Class D {
    test1 ( ) : Int { b ( ) };
    test2 ( ) : Int { c ( 1, 
    2 ) };
    b ( ) : D { self };
    c ( a : Int, b : Int ) : D { self };   
}; -- Self dispatch

Class E inherits D {
    test1 ( ) : Int { ( new E ).b().c() };
    test2 ( ) : D { self@D.b() };
}; -- dynamic & static dispatch

Class F {
    a : Bool <- 1 <= 2;
    b : Bool <- 3 < 4;
    c : Bool <- 56 = 78;
    test1 ( ) : Int {
        let x : Int, y : Int in {
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
}; -- expressions

class Main inherits IO {
    a : Bool <- isvoid (1 + 2);
    main() : Object {
	    let a : Main 
        in 0
    };
}; -- isvoid

