#Compiling Object-Oriented Languages
C++中提供的继承方法有两种，一种是重复继承，另一种则是虚拟继承。对于重复继承，被重复继承的类在派生类中会有多个实例，而采用虚拟继承，被重复继承的类则在派生类中只有单一实例。我按照书上提供的例子编写了类似的程序：
```cpp
class A {
    public:
        int a;
        void PrintA ( void )
        {
            cout<<"This is class A with integer "<<a<<endl;
        }
};

class B1: public A {
    public:
        int b1;
        void PrintB1 ( void )
        {
            cout<<"This is class B1 with integer "<<b1<<endl;
        }
};

class B2: public A {
    public:
        int b2;
        void PrintB2 ( void )
        {
            cout<<"This is class B2 with integer "<<b2<<endl;
        }
};

class C: public B1, public B2 {
    public:
        int c;
        void PrintC ( void )
        {
            cout<<"This is class C with integer "<<c<<endl;
        }
};
```
这样，在派生类C中会有类A的亮两个实例，它们互不干扰。在主函数中，我用以下的方法去访问这两个成员：
```cpp
	C c;
    B1 *b1;
    B2 *b2;

    b1 = &c;
    b2 = &c;
    b1->a = 1;
    b2->a = 2;
    b1->PrintA();
    b2->PrintA();
    cout<<(long)&(b1->a)<<endl;
    cout<<(long)&(b2->a)<<endl;
```
这样，`b1->PrintA()`和`b2->PrintA()`打印出A的值是不同的，并且`b1->a`和`b2->a`的地址也不同。运行的结果如下：
```
This is class A with integer 1
This is class A with integer 2
140721349460952
140721349460960
```
可以验证派生类C中确实有类A的两个实例，它们在内存中占有不同的位置。另外在这种情况下，直接使用c.a是不合法的，除非将a声明为static类型；因为此时，编译器不知道应该访问哪一个a。
如果在声明类B1和B2时加上virtual字样，则使用的是虚拟继承，类A在类C中只有一个实例。加上virtual，其它代码不变，编译运行之后得到结果如下：
```
This is class A with integer 2
This is class A with integer 2
140732384471952
140732384471952
```
可以验证派生类C中只有类A的一个实例。
在编写程序的时候主要的问题是对C++的语法不是很熟悉，比如说a应该声明为public，这样使用b1->a才是合法的。除此之外没有遇到什么问题。