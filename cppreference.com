====================
Namespace members
If the name on the left of :: refers to a namespace or if there is nothing on the left of ::
(in which case it refers to the global namespace), the name that appears on the right hand side of :: 
is looked up in the scope of that namespace, except that

names used in template arguments are looked up in the current scope
namespace N {
   template<typename T> struct foo {};
   struct X {};
}
N::foo<X> x; // error: X is looked up as ::X, not as N::X
===================
http://en.cppreference.com/w/cpp/language/qualified_lookup
----------------------------------------------------------
====================================
Definition outside of its namespace
====================================
For a name used in the definition of a namespace-member variable outside the namespace, lookup proceeds the same way as for a name used inside the namespace:

namespace X {
    extern int x; // declaration, not definition
    int n = 1; // found 1st
};
int n = 2; // found 2nd.
int X::x = n; // finds X::n, sets X::x to 1
=====================================
Non-member function definition
==============================
namespace A {
   namespace N {
       void f();
       int i=3; // found 3rd (if 2nd is not present)
    }
    int i=4; // found 4th (if 3rd is not present)
}
 
int i=5; // found 5th (if 4th is not present)
 
void A::N::f() {
    int i = 2; // found 2nd (if 1st is not present)
    while(true) {
       int i = 1; // found 1st: lookup is done
       std::cout << i;
    }
}
========================================
class defination
=========================================

namespace M {
    // const int i = 1; // never found
    class B {
        // const const int i = 3; // found 3nd (but later rejected by access check)
    };
}
// const int i = 5; // found 5th
namespace N {
    // const int i = 4; // found 4th
    class Y : public M::B {
        // static const int i = 2; // found 2nd
        class X {
            // static const int i = 1; // found 1st
            int a[i]; // use of i
            // static const int i = 1; // never found
        };
        // static const int i = 2; // never found
    };
    // const int i = 4; // never found
}
// const int i = 5; // never found
===================================
