#Clang Static Analyzer阅读实验 问题回答
##3.1
5.简要说明test.c、AST.svg、CFG.svg和ExplodedGraph.svg之间的联系与区别。
答：test.c为源代码，lexer和parser会对源代码进行分析，生成AST；CFG是从AST的基础上生成的，它表示了程序的控制流；静态分析器会在CFG的基础上对程序进行检测，每一条程序中可能存在的执行路径都会被检测到，这些路径及对应的状态用ExplodedGraph来表示。

##3.2
1.Checker 对于程序的分析主要在 AST 上还是在 CFG 上进行？
答：CFG。

2.Checker 在分析程序时需要记录程序状态，这些状态一般保存在哪里？
答：首先，程序的状态被保存在`ProgramState`和`ProgramPoint`中。`ProgramPoint`代表程序（或者说CFG）中的一个给定的位置，`ProgramState`则代表了程序的抽象状态，它包含了`Environment`（源代码到符号值之间的映射），`Store`（符号值到内存地址的映射）和`GenericDataMap`（保存和符号值有关的限制条件）。
在分析器到达一个新的状态时，它会按照给定的顺序调用checkers来检测和改变这个状态。checkers需要记录的信息保存在`ProgramState`的`GenericDataMap`内。

3.简要解释分析器在分析下面程序片段时的过程，在过程中产生了哪些symbolic values? 它们的关系是什么？
答：在第一行中，产生了`Sval1`，它代表常数3；`Sval2`，它代表x的`MemoryRegion`，并且与`Sval1`相关联；`Sval3`，代表常数4；`Sval4`，代表y的`MemoryRegion`，并且与`Sval3`相关联；
在第二行中，产生了`Sval5`，它代表x的`MemoryRegion`的地址；产生了`Sval6`，它代表p的`MemoryRegion`,并且和`Sval5`相关联；
在第三行中，产生了`Sval7`，它代表p的`MemoryRegion`，并且和`Sval5`相关联；产生了`Sval8`，它代表常数1；产生了`Sval9`，它是一个子表达式，代表`p+1`的和；产生了`Sval10`，代表`*(p+1)`,与`Sval9`相关联；产生了`Sval11`，它表示z的`MemoryRegion`，与`Sval10`相关联。

##3.3
1.LLVM 大量使用了 `C++11/14`的智能指针，请简要描述几种智能指针的特点、使用场合，如有疑问也可以记录在报告中。
答：LLVM中主要使用了`C++11`标准中新提供的unique_ptr。`C++11`中提供的智能指针有三种，即unique_ptr,shared_ptr和weak_ptr。这里简要列举一些特点：
- unique_ptr:unique_ptr唯一拥有其所指向对象的权限，并且离开作用域时自动销毁其所指向的对象完成内存回收。unique_ptr不能够进行普通的赋值或者复制操作，需要转移所有权限时应该使用move()函数。
- shared_ptr：shared_ptr则允许共享资源，它有一个计数记录来记录某一资源被几个指针所共享。当调用release()，析构函数或者被重新赋值时，其所指向对象的计数记录都会减一，新建时则加一；当计数记录为零时该对象被释放。只使用shared_ptr会存在一些问题（正如讨论课上所提及的那样），如果出现一个循环链表的所有指针都是shared_ptr，那么当没有外部调用使用该链表时，由于所有对象计数都不为零，那么这个无用的链表并不会被删除。因此，shared_ptr在一些情况下可以配合weak_ptr来使用。
- weak_ptr:weak_ptr是对对象的一种弱引用，它不会增加对象的计数。weak_ptr和shared_ptr之间可以相互转换，shared_ptr可以直接赋值给weak_ptr，weak_ptr可通过调用lock函数来获得shared_ptr。在上面链表的例子中，如果把表尾指向表头的指针声明为weak_ptr，那么离开作用域后表头的计数为0，则整个链表可以被正常释放。

2.LLVM 不使用 `C++` 的运行时类型推断（RTTI），理由是什么？LLVM 提供了怎样的机制来代替它？
答：LLVM为了减少代码和生成二进制文件的体积，不使用RTTI。LLVM的设计人员认为像RTTI这种会极大地增加可执行文件体积的语法特点违反了`C++`的设计原则。
LLVM使用手工构造的模板来代替RTTI，例如isa<>， cast<>，和dyn_cast<>。

3.如果你想写一个函数，它的参数既可以是数组，也可以是std::vector，那么你可以声明该参数为什么类型？如果你希望同时接受 C 风格字符串和 std::string 呢？
答：对于前一个问题，可以使用LLVM提供的类`llvm:ArrayRef`，把参数声明为这个类型，就可以同时接受定长数组和std::vector类型。对于后一个问题则更简单，只需要将函数的类型声明为std::string类型即可；在这种情况下，当传入的参数为C风格的字符串时，参数会自动做类型转换，将C风格字符串转换为std::string类型。

4.你有时会在cpp文件中看到匿名命名空间的使用，这是出于什么考虑？
答：匿名命名空间将告诉`C++`编译器，这个命名空间中的内容只在当前的翻译单元中可见，这将有利于C++编译器做出更多的优化，并且避免可能的名字冲突。

##3.4
1.这个 checker 对于什么对象保存了哪些状态？保存在哪里？
答：这个checker对于文件描述符保存了其打开及关闭的状态。状态保存在ExplodedGraph中，也就是上面问题中提到的
`ProgramState`的`GenericDataMap`内。

2.状态在哪些时候会发生变化？
答：当遇到打开函数`fopen()`时，该函数返回值所对应的文件描述符的状态会被置为打开状态；当遇到关闭函数`fclose()`时，该函数参数所对应的文件描述符的状态会被置为关闭状态。

3.在哪些地方有对状态的检查？
答：首先是在`SimpleStreamChecker::checkPreCall`中，这个函数在函数调用之前执行，如果发现当前函数是`fclose()`且其参数对应的文件描述符处在关闭状态，则说明该文件描述符被多次关闭，则报错；还有即是在`SimpleStreamChecker::checkDeadSymbols`中，如果一个Stream的状态已经被声明为dead，那么如果这个Stream的状态是打开，并且它的值不是NULL，则报错，并将已经`dead`的symbol移出streammap。
另外在下一问中提到的函数`SimpleStreamChecker::checkPointerEscape`中也有对状态的检查，它会把不可追踪其状态的文件描述符移出追踪列表。

4.函数SimpleStreamChecker::checkPointerEscape的逻辑是怎样的？实现了什么功能？用在什么地方？
答：这个函数首先检测当前调用是否对应这样一种情况：文件描述符被作为函数的参数传入，并且该函数是一个系统调用并且传入参数不可能导致泄漏；如果是这样的话，那么不做任何操作。否则，它会把所有不可追踪的文件描述符都移出其追踪列表，并将修改过的状态返回给上层调用。它实现了对不可追踪文件指针的识别，例如当该文件指针被赋值给一个全局变量，或者调用了一个可能导致参数`escape`的函数的时候，这些情况下该文件指针的行为不再能够被分析器追踪，因此这些文件指针会从追踪列表中移出。具体的例子可以见下一题。

5.根据以上认识，你认为这个简单的checker能够识别出怎样的bug？又有哪些局限性？请给出测试程序及相关的说明。
答：这个checker能够识别下列的bug：
- 某一个文件描述符在程序的不同位置被多次关闭（double close）；
- 某一个文件描述符在某一位置被打开后没有正确关闭（leak）。

它有一些局限性，例如在碰到全局变量的时候，不能够正确追踪文件描述符的状态：
```cpp
#include <stdio.h>

FILE *fp;

int main( void )
{
    FILE *a;
    a = fopen( "a.txt", "r" );
    fp = a;
}
```
这个程序中a没有被正常关闭，但是分析器不会报任何warning。
另外，在遇到下列的情况时：
```cpp
#include <stdio.h>

int main( void )
{
    FILE *a = fopen("a.txt","w");
    a = a+1;
    fclose(a);
}
```
分析器并不会报告leak。
另外，这个Checker在使用的时候同样也会具有Clang静态分析都具有的问题，比如说不能处理浮点值的条件审查，不能处理多次循环，不能处理按位运算等。另外在调用了跨翻译单元的函数时，如果函数的参数中有某一个文件指针，那么这个文件指针的状态可能也将被置为不可追踪状态，这将导致一些局限性。

##3.5
1.增加一个checker需要增加哪些文件？需要对哪些文件进行修改？
答：首先要新建一个.cpp文件，放在lib/StaticAnalyzer/Checkers目录下。
然后，需要在.cpp文件的末尾添加注册信息，类似这样：
```cpp
void ento::registerSimpleStreamChecker(CheckerManager &mgr) {
  mgr.registerChecker<SimpleStreamChecker>();
}
```
调用类CheckerManager类中的registerChecker函数来注册这个Checker。
接下来，需要在lib/StaticAnalyzer/Checkers/Checkers.td中添加包的注册信息和相关的描述，最后在lib/StaticAnalyzer/Checkers中的CMakeLists.txt添加对应的.cpp文件，使其能够被正确编译。

2.阅读clang/include/clang/StaticAnalyzer/Checkers/CMakeLists.txt，解释其中的 clang_tablegen 函数的作用。
答：这是一个函数调用，它将产生一条命令调用tablegen工具，去根据Checkers.td中的信息，生成各个Checkers对包的依赖关系，并且记录在Checkers.inc中；除此之外，它也指定cmake编译checkers的source和target的名称。生成的Checkers.inc描述了各个包之间的依赖关系，它可能将用于后续步骤中头文件的配置。

3.`.td`文件在clang中出现多次，比如这里的clang/include/clang/StaticAnalyzer/Checkers/Checkers.td。这类文件的作用是什么？它是怎样生成C++头文件或源文件的？这个机制有什么好处？
答：这是LLVM中TableGen工具定义的数据文件，它将能够根据这些数据文件，根据TableGen的语法解释这些数据，并且生成相应的文件供后端调用。TableGen工具会根据对应的语法，将.td文件中的类和定义等进行展开。比如在如下的例子中：
```
class C { bit V = 1; }  
def X : C;  
def Y : C {  
string Greeting ="hello";  
}  
```
保存为.td文件，用TableGen工具处理后变为如下格式：
```
------------- Classes-----------------  
class C {  
bit V = 1;  
string NAME = ?;  
}  
------------- Defs-----------------  
def X { // C  
bit V = 1;  
string NAME = ?;  
}  
def Y { // C  
bit V = 1;  
string Greeting ="hello";  
string NAME = ?;  
}  
```
只要用对应的语法描述相应的数据结构或者头文件引用关系，那么就可以使用TableGen产生`C++`的头文件或者源文件。这个机制主要的好处是避免了对大量相似（但不完全相同）的代码手工地进行修改，减少了工作量的同时也减少了可能出现的错误。





