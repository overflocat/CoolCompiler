#Compiling Object-Oriented Languages

## 作业一

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

## 作业二

为了弄清源码成员（类方法名）在反汇编的代码中都变成了什么，我并没有在第一个实验的例子上直接进行修改，而是另外编写了一个简单的例子，如下：

```cpp
#include <iostream>

using namespace std;

class A {
	public:
  		int a;
		void PrintA( void )
		{
			cout<<"123"<<endl;
		}
};

int main ( void )
{
	A a1;
	a1.PrintA( );
	return 0;
}
```

使用`objdump`来查看反汇编代码，可以看到PrintA函数变成了如下的汇编代码：

```gas
00000000004008d0 <_ZN1A6PrintAEv>:
  4008d0:	55                   	push   %rbp
  4008d1:	48 89 e5             	mov    %rsp,%rbp
  4008d4:	48 83 ec 10          	sub    $0x10,%rsp
  4008d8:	48 b8 60 10 60 00 00 	movabs $0x601060,%rax
  4008df:	00 00 00 
  4008e2:	48 be a4 09 40 00 00 	movabs $0x4009a4,%rsi
  4008e9:	00 00 00 
  4008ec:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  4008f0:	48 89 c7             	mov    %rax,%rdi
  4008f3:	e8 18 fe ff ff       	callq  400710 <_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc@plt>
  4008f8:	48 be 30 07 40 00 00 	movabs $0x400730,%rsi
  4008ff:	00 00 00 
  400902:	48 89 c7             	mov    %rax,%rdi
  400905:	e8 16 fe ff ff       	callq  400720 <_ZNSolsEPFRSoS_E@plt>
  40090a:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  40090e:	48 83 c4 10          	add    $0x10,%rsp
  400912:	5d                   	pop    %rbp
  400913:	c3                   	retq   
  400914:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  40091b:	00 00 00 
  40091e:	66 90                	xchg   %ax,%ax
```

这里，PrintA函数的名称被改变，变成了`_ZN1A6PrintAEv`。clang++应该有自己的一套名字转换规则（见后文的name mangling）。另外这里有两个问题需要注意：

1. cout函数变成了一个函数调用`_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc@plt`，并且clang++默认使用的是动态链接，因此在反汇编得到的文件中是看不到这个函数的函数体的，这个函数是一个系统调用。不过，如果在编译的时候加上`-static`选项的话，那么就可以看到这个函数的函数体，并且反汇编的得到的文件也会非常大，猜测静态链接的时候可能还往程序中链接了一些没有用到的函数。这两个函数的具体代码在后文的附录中给出。

2. 关于类A中的成员`int a`，这个名称在反汇编得到的代码中已经找不到了。事实上，程序只会给这个变量分配内存空间，在主函数中可以看到：

   ```gas
   00000000004008b0 <main>:
     4008b0:	55                   	push   %rbp
     4008b1:	48 89 e5             	mov    %rsp,%rbp
     4008b4:	48 83 ec 10          	sub    $0x10,%rsp
     4008b8:	48 8d 7d f8          	lea    -0x8(%rbp),%rdi
     4008bc:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
     4008c3:	e8 08 00 00 00       	callq  4008d0 <_ZN1A6PrintAEv>
     4008c8:	31 c0                	xor    %eax,%eax
     4008ca:	48 83 c4 10          	add    $0x10,%rsp
     4008ce:	5d                   	pop    %rbp
     4008cf:	c3                   	retq   
   ```

   `sub    $0x10,%rsp`负责给指定的变量在栈上分配空间。和上面的例子结合起来看，可以发现在汇编代码中，程序面向对象的属性已经不存在了，类中的函数会变成名字为`类名`+`函数名`+...得到的普通函数，类中的成员域也只是在栈上分配空间。

再回到多重继承的例子，由于在反汇编代码中不存在任何面向对象的特征，因此比较第一份作业中编写的两份虚拟继承和多重继承的代码反汇编得到的汇编码，可以发现：

1. 在虚拟继承和多重继承的时候，函数PrintA的代码都只有一份，都是`_ZN1A6PrintAEv`。
2. 在虚拟继承的时候，会比多重继承的时候在栈上分配更多的存储空间（暂不清楚原因，应该是由于虚拟继承的实现机制）。在多重继承的时候，对基类中成员的赋值语句`movl   $0x2,-0x10(%rbp)`在虚拟继承的时候会变成`movl   $0x2,-0x20(%rbp,%rax,1)`，因此在调用相同的函数的时候也得到了不同的结果。

另外，我把第一次作业中用指针访问的方法改成了限定名字空间来访问的办法，这样可以让汇编代码简单一些，便于观察。

### 附录：静态链接和动态链接得到的cout

动态链接得到的`_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc@plt`：

```gas
0000000000400710 <_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc@plt>:
  400710:	ff 25 22 09 20 00    	jmpq   *0x200922(%rip)        # 601038 <_GLOBAL_OFFSET_TABLE_+0x38>
  400716:	68 04 00 00 00       	pushq  $0x4
  40071b:	e9 a0 ff ff ff       	jmpq   4006c0 <_init+0x28>
```

静态链接得到的`_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc`：

```gas
0000000000405290 <_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc>:
  405290:	55                   	push   %rbp
  405291:	53                   	push   %rbx
  405292:	48 89 fd             	mov    %rdi,%rbp
  405295:	48 83 ec 08          	sub    $0x8,%rsp
  405299:	48 85 f6             	test   %rsi,%rsi
  40529c:	74 2a                	je     4052c8 <_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc+0x38>
  40529e:	48 89 f3             	mov    %rsi,%rbx
  4052a1:	48 89 f7             	mov    %rsi,%rdi
  4052a4:	e8 97 75 0c 00       	callq  4cc840 <strlen>
  4052a9:	48 89 de             	mov    %rbx,%rsi
  4052ac:	48 89 ef             	mov    %rbp,%rdi
  4052af:	48 89 c2             	mov    %rax,%rdx
  4052b2:	e8 e9 fa ff ff       	callq  404da0 <_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l>
  4052b7:	48 83 c4 08          	add    $0x8,%rsp
  4052bb:	48 89 e8             	mov    %rbp,%rax
  4052be:	5b                   	pop    %rbx
  4052bf:	5d                   	pop    %rbp
  4052c0:	c3                   	retq   
  4052c1:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
  4052c8:	48 8b 07             	mov    (%rdi),%rax
  4052cb:	48 03 78 e8          	add    -0x18(%rax),%rdi
  4052cf:	8b 77 20             	mov    0x20(%rdi),%esi
  4052d2:	83 ce 01             	or     $0x1,%esi
  4052d5:	e8 36 c8 ff ff       	callq  401b10 <_ZNSt9basic_iosIcSt11char_traitsIcEE5clearESt12_Ios_Iostate>
  4052da:	48 83 c4 08          	add    $0x8,%rsp
  4052de:	48 89 e8             	mov    %rbp,%rax
  4052e1:	5b                   	pop    %rbx
  4052e2:	5d                   	pop    %rbp
  4052e3:	c3                   	retq   
  4052e4:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
  4052eb:	00 00 00 
  4052ee:	66 90                	xchg   %ax,%ax
```

`_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_`也是一个非常长的函数，这里就不列出了。

### 附录：name mangling

name mangling（应该翻译为名字分解？）是c++编译器在编译时对函数名称的一种转换机制。具体而言，可以参见维基百科上的一个例子：

```cpp
namespace wikipedia 
{
   class article 
   {
   public:
      std::string format (void); 
         /* = _ZN9wikipedia7article6formatEv */

      bool print_to (std::ostream&); 
         /* = _ZN9wikipedia7article8print_toERSo */

      class wikilink 
      {
      public:
         wikilink (std::string const& name);
            /* = _ZN9wikipedia7article8wikilinkC1ERKSs */
      };
   };
}

```

这里，format函数会被命名为`_ZN9wikipedia7article6formatEv`，这个函数名字的来源是：

1. 一般函数名都以_Z开头；
2. 9wikipedia代表名字空间的名称，9为字符wikipedia的长度；
3. 7article代表类名；
4. 6format代表函数名；
5. E代表函数名称的结束，后面是函数参数类型。这里类型为空，所以后面只有一个v。

上面PrintA的例子同理可以推出。另外，可以用c++filt命令将转换后的函数名转换回原函数名，用这种方式可以更加直观地看出命名的机制。

