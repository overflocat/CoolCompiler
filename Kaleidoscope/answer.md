##Kaleidoscope阅读 问题回答
###词法分析
1.解释函数`gettok()`如何向调用者传递`token`类别、`token`语义值（数字值、变量名）
- 答：对于所有的`token`，其类别通过不同的整形数区分，每一个`token`拥有不同的整形数值。`gettok()`通过返回不同的整形数来区分`token`的类别（如果该`token`是已经定义的，则按照枚举列表中的类型返回值，否则直接返回当前字符）；
  对于`token`的语义值，`gettok()`会将读到的变量名存放在全局变量`IdentifierStr`中，若读入到的是数字，其数值会被存放在全局变量`NumVal`中。

###语法分析和AST的构建
1.解释`ExprAST`里的`virtual`的作用，在继承时的原理（解释`vtable`)。
- 答：virtual表示定义的函数是一个虚函数。对于虚函数，简单的解释是：每一个类都有一个虚函数表，虚函数表中保存了指向虚函数入口的指针。每个派生类都继承了它基类的`vtable`，但如果派生类覆写了该项对应的虚函数，则派生类的`vtable`中对应的指针指向覆写后的虚函数。每一个由该类定义的对象都有一个指向该虚函数表的指针。在这里，基类将析构函数定义为虚函数是为了当用基类操作派生类的时候，析构时只析构基类而不析构派生类。举例而言，在用一个基类指针操作派生类对象的时候，此时`delete`该指针，若基类中析构函数声明为虚函数，那么会先访问派生类中的虚函数表并调用派生类的析构函数来正确地析构该对象；否则，若基类的析构函数没有被声明为虚函数，那么该操作只会调用基类的析构函数，不能够正确地析构该对象。

2.解释代码里的`<std::unique_ptr>`和为什么要使用它？
- 答：`unique_ptr`是c++标准库里定义的一种智能指针，它与指向的对象构成一一对应的关系，并在离开作用域时自动地删除对象完成内存回收。在这里，使用`unique_ptr`和`move()`函数可以明确对象的所有权并进行传递。

3.阅读`src/toy.cpp`中的`MainLoop`及其调用的函数. 阅读`HandleDefinition`和`HandleTopLevelExpression`，忽略`Codegen`部分，说明两者对应的`AST`结构.
- 答：`HandleDefinition()`调用`ParseDefinition()`来产生定义对应的AST结点，在`Kaleidoscope`中，定义指函数声明，包括一个函数原型以及对应的函数体（表达式）。`HandleTopLevelExpression()`调用`ParseTopLevelExpr()`来产生一个特殊的函数声明，该函数的名称以及参数均为空，用来将接下来分析的用户程序包裹在其函数体中。

4.Kaleidoscope 如何在`Lexer`和`Parser`间传递信息？（token、语义值、用什么函数和变量）
- 答：对于`token`值的区分，`Lexer`和`Parser`共享一套相同的对`token`值的定义，每个`token`都有其对应的整形数用来区分类型。每次调用`getNextToken()`的时候，`token`对应的整形数值会被保存在`CurTok`内。对于字符串（定义名称）和数字的语义值通过共享全局变量`IdentifierStr`和`NumVal`来进行传递。

5.`Kaleidoscope`如何处理算符优先级（重点解释`ParseBinOpRHS`）？解释`a*b*c`、`a*b+c`、`a+b*c`分别是如何被分析处理的？
- 答：简单来讲，`ParseBinOpRHS`是通过将表达式分成左串和右串，通过判断操作符和哪一个串的结合性更紧密来处理算符优先级的。举例而言，如对`a+b*c`，第一次调用`ParseBinOpRHS()`时，判断`+`对应的优先级大于0，因此保存当前的符号`+`，读取表达式`b`并读取下一个操作符`*`。再次进行判断，由于`*`对应的优先级高于`+`，因此将表达式`b`作为`LHS`，`*`的优先级加一（这样做是为了保证下一次导致递归调用时碰到的操作符优先级必须大于`*`）来去调用`ParseBinOpRHS()`。在这一次调用中，由于表达式`c`右侧不再有操作符，因此`b*c`会被直接作为一个结点生成表达式，并作为`LHS`返回上一层递归调用，赋值给上一层的`RHS`，然后在上一层中生成完整的表达式`a+b*c`，这样就确保了正确的表达式结构。对于`a*b+c`，函数将不再有递归调用，将直接把`a*b`作为一个表达式返回给上一层，最后在生成`a*b+c`；`a*b*c`同样如此。

6.解释`Error` 、`ErrorP`的作用，举例说明它们在语法分析中的应用。
- 答：`LogError()`将返回一个空指针，并向标准错误流中写入错误信息。`LogErrorP()`将调用`LogError()`进行报错，并返回一个空指针。这些函数将在遇到的`token`不符合预期时时被调用，并返回有用的错误信息。举例而言，例如在函数声明中没有遇到右括号，那么整个函数声明将被立即废弃，并调用`LogErrorP()`来产生错误信息`"Expected ')' in prototype"`，然后返回一个空指针。

7.`Kaleidoscope`不支持声明变量和给变量赋值，那么变量的作用是什么？
- 答：变量主要出现在函数调用的参数中，调用时变量可以依据情况被赋予不同的值，但值不能在函数体内更改。具体可以参见第一章中给出的计算斐波那契数的函数以及相关的说明。

### 中间代码生成

1.解释教程3.2节中`Moudle`、`IRBuilder<>`的作用。
- 答：`IRBuilder<>`是一个类模板，用它创建类`Builder`，它提供了一个方便的方式用来追踪当前应该插入指令的位置，同时它提供了一些用于构造`LLVMIR`的方法。`Module`用于创建类`TheMoudle`，它包含了一些函数以及全局变量，它同时也拥有所有我们为保存生成指令所分配的内存空间。

2.为何使用常量时用的函数名都是`get`而不是`create`？
- 答：因为在`LLVM`中，常量都只保存一份，并且是共享的。因此，在实现API的时候，对于已经存在的常量不需要重新生成，所以在提供API的时候通常采用`foo:get(…)`的形式。

3.简要说明声明和定义一个函数的过程。
- 答：这里分为两个部分：
  1. 声明函数：
     - 首先，在`PrototypeAST`中利用`FunctionType:get()`创建一个`FunctionType`对象，这个对象描述了一个函数类型，它的参数是一个由`N`个`double`类型变量组成的向量，返回值也是`double`；
     - 然后，它利用这个`FunctionType`去生成一个`Function`类型的`LLVMIR`；
     - 最后用一个循环去设置该函数原型中各参数的名称，并返回生成的`IR`。
  2. 定义函数：
     - 首先，检查是否已经有相同名字的函数已经用`extern`声明过，如果没有的话则调用声明函数的代码生成过程来产生一个函数声明；接着检查这个函数的函数体是不是为空，如果不是的话说明这个函数接下来被重复定义，需要返回一个错误。
     - 然后，生成一个`BasicBlock`类型的函数体，把函数体放入函数内，并且将接下来所有语句的插入点改成函数体内。接着，将这个函数中所有的参数加入到变量名列表中以便于之后的调用（每次插入之前，需要将之前使用的变量名列表清空）。
     - 接下来对函数体的根表达式调用代码生成的函数，如果一切顺利，这些表达式会产生对应的`IR`并插入到函数体内。最后，插入计算返回值的`IR`并完成生成函数的过程。如果在计算函数体表达式的过程中出错，那么整个函数所生成的代码都会被抹去。

4.文中提到了`visitor pattern`，虽然这里没有用到，但是是一个很重要的设计模式，请调研后给出解释（字数不做限制）。
- 答：这一部分网上提供的资料很多，介绍也比较详细，这里摘抄一部分：
  - 访问者模式的目的是封装一些施加于某种数据结构元素之上的操作。一旦这些操作需要修改的话，接受这个操作的数据结构则可以保持不变。
  - 访问者模式有如下的优点：
    - 访问者模式使得增加新的操作变得很容易。如果一些操作依赖于一个复杂的结构对象的话，那么一般而言，增加新的操作会很复杂。而使用访问者模式，增加新的操作就意味着增加一个新的访问者类，因此变得很容易。
    - 访问者模式将有关的行为集中到一个访问者对象中，而不是分散到一个个的节点类中。
    - 访问者模式可以跨过几个类的等级结构访问属于不同的等级结构的成员类。迭代子只能访问属于同一个类型等级结构的成员对象，而不能访问属于不同等级结构的对象。访问者模式可以做到这一点。
    - 积累状态。每一个单独的访问者对象都集中了相关的行为，从而也就可以在访问的过程中将执行操作的状态积累在自己内部，而不是分散到很多的节点对象中。这是有益于系统维护的优点。
  - 访问者模式有如下的缺点：
    - 增加新的节点类变得很困难。每增加一个新的节点都意味着要在抽象访问者角色中增加一个新的抽象操作，并在每一个具体访问者类中增加相应的具体操作。
    - 破坏封装。访问者模式要求访问者对象访问并调用每一个节点对象的操作，这隐含了一个对所有节点对象的要求：它们必须暴露一些自己的操作和内部状态。不然，访问者的访问就变得没有意义。由于访问者对象自己会积累访问操作所需的状态，从而使这些状态不再存储在节点对象中，这也是破坏封装的。
  - 另外给出两个我的参考链接：
    - https://en.wikipedia.org/wiki/Visitor_pattern
    - http://www.cnblogs.com/zhenyulu/articles/79719.html