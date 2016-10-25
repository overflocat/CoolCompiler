##控制流错误
程序如下：
```cpp
#include <stdio.h>

int main( void )
{
    break;
    return 0;
}
```
编译器能够发现这个错误，并且报告该break不在指定的程序块内：
```bash
control_flow_error.c: In function ‘main’:
control_flow_error.c:5:5: error: break statement not within loop or switch
     break;
     ^
```
##不满足唯一性要求
程序如下：
```cpp
#include <stdio.h>

int main ( void )
{
    int a;
    a = 1;
    int a;
    return 0;
}
```
编译器能够发现这个错误，提醒a已经被定义过并且报告之前定义a的位置：
```bash
uniqueness_unsatisfied.c: In function ‘main’:
uniqueness_unsatisfied.c:7:9: error: redeclaration of ‘a’ with no linkage
     int a;
         ^
uniqueness_unsatisfied.c:5:9: note: previous declaration of ‘a’ was here
     int a;
         ^
```
##备注
实验环境如下：
```
gcc (Ubuntu 5.4.0-6ubuntu1~16.04.2) 5.4.0 20160609
```



