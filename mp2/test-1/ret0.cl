class Main {
  main(): Int {
    {
       let x : Int, y : Bool <- true, z : Int, temp : Int in {
         x = 9973;
         z = 2;
         while z < x loop
         {
            temp = x / z;
            if ( temp * z = x ) then
              y = false
            else
              false
            fi;
            z <- z + 1;
         }
         pool;
         if ( y = true ) then
           1
         else
           0
         fi;
       };
    }
  };
};