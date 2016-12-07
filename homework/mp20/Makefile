FIB_M = fib-m.bc
FIB = fib.out

all: fib fib-m
fib-m:	
	llvm-as fib-m.ll -o ${FIB_M}
fib:	
	gcc fib.c -o ${FIB}
clean:	
	rm -f ${FIB_M} ${FIB}
