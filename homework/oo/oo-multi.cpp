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

int main ( void )
{
    C c;

    c.B1::a = 1;
    c.B2::a = 2;
    c.B1::PrintA();
    c.B2::PrintA();
    cout<<(long)&(c.B1::a)<<endl;
    cout<<(long)&(c.B2::a)<<endl;
    
    return 0;
}