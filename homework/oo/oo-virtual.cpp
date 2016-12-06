#include <iostream>

using namespace std;

class A {
    public:
        int a;
        void PrintA ( void )
        {
            cout<<"This is class A with integer "<<a<<endl;
        }
};

class B1: virtual public A {
    public:
        int b1;
        void PrintB1 ( void )
        {
            cout<<"This is class B1 with integer "<<b1<<endl;
        }
};

class B2: virtual public A {
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

int main ( void )
{
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

    cout<<endl;

    c.b1 = 3;
    c.b2 = 4;
    c.PrintB1();
    c.PrintB2();

    return 0;
}