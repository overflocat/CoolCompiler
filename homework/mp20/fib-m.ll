source_filename = "fib.c"

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

declare i32 @printf( i8*, ... )
declare i32 @atoi( i8* )

define i32 @main( i32 %argc, i8** %argv )
{
    entry:
        %index = getelementptr inbounds i8*, i8** %argv, i64 1
        %temp1 = load i8*, i8** %index, align 8

        %retvalue1 = call i32 @atoi( i8* %temp1 )
        %retvalue2 = call i32 @fib( i32 %retvalue1 )
        %retvalue3 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %retvalue2)

        ret i32 0
}

define i32 @fib( i32 %n )
{
    entry:
        %cmpresult1 = icmp eq i32 %n, 0
        br i1 %cmpresult1, label %true1, label %false1

    true1:
        br label %endret0

    false1:
        %cmpresult2 = icmp eq i32 %n, 1
        br i1 %cmpresult2, label %true2, label %false2

    true2:
        br label %endret1

    false2:
        %temp1 = sub nsw i32 %n, 2
        %temp2 = sub nsw i32 %n, 1
        %retvalue1 = call i32 @fib( i32 %temp1 )
        %retvalue2 = call i32 @fib( i32 %temp2 )
        %temp3 = add nsw i32 %retvalue1, %retvalue2
        br label %endretn

    endret0:
        ret i32 0
    
    endret1:
        ret i32 1

    endretn:
        ret i32 %temp3
}
