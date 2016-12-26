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
=================================================
Pre-increment and pre-decrement operators increments or decrements the value of the object and returns a reference to the result.

Post-increment and post-decrement creates a copy of the object, increments or decrements the value of the object and returns the copy from before the increment or decrement.

Built-in prefix operators
For every optionally volatile-qualified arithmetic type A other than bool, and for every optionally volatile-qualified pointer P to optionally cv-qualified object type, the following function signatures participate in overload resolution:

A& operator++(A&)
bool& operator++(bool&)
(deprecated)(until C++17)
P& operator++(P&)
A& operator--(A&)
P& operator--(P&)
The operand of a built-in prefix increment or decrement operator must be a modifiable (non-const) lvalue of non-boolean arithmetic type or pointer to complete object type. For non-boolean operands, the expression ++x is exactly equivalent to x += 1, and the expression --x is exactly equivalent to x -= 1, that is, the prefix increment or decrement is an lvalue expression that identifies the modified operand. All arithmetic conversion rules and pointer arithmetic rules defined for arithmetic operators apply.

If the operand of the pre-increment operator is of type bool, it is set to true (deprecated). (until C++17)

Built-in postfix operators
For every optionally volatile-qualified arithmetic type A other than bool, and for every optionally volatile-qualified pointer P to optionally cv-qualified object type, the following function signatures participate in overload resolution:

A operator++(A&, int)
bool operator++(bool&, int)
(deprecated)(until C++17)
P operator++(P&, int)
A operator--(A&, int)
P operator--(P&, int)
======================================
 
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
// the class whose member functions are friended
===============================================
struct A { 
    typedef int AT;
    void f1(AT);
    void f2(float);
    template <class T> void f3();
};
 
// the class that is granting friendship
struct B {
    typedef char AT;
    typedef float BT;
    friend void A::f1(AT); // lookup for AT finds A::AT
    friend void A::f2(BT); // lookup for BT finds B::BT 
    friend void A::f3<AT>(); // lookup for AT finds B::AT 
};
==========================================
Default arguments
==========================================

class X {
    int a, b, i, j;
public:
    const int& r;
    X(int i): r(a), // initializes X::r to refer to X::a
              b(i), // initializes X::b to the value of the parameter i
              i(i), // initializes X::i to the value of the parameter i
              j(this->i) // initializes X::j to the value of X::i
    { }
}
 
int a;
int f(int a, int b = a); // error: lookup for a finds the parameter a, not ::a
                         // and parameters are not allowed as default arguments
                         
=============================================
Static data member definition
=============================
For a name used in the definition of a static data member, lookup proceeds the same way as for a name used in the definition of a member function.

struct X {
    static int x;
    static const int n = 1; // found 1st
};
int n = 2; // found 2nd.
int X::x = n; // finds X::n, sets X::x to 1, not 2
=============================================
Enumerator declaration
=======================
For a name used in the initializer part of the enumerator declaration, previously declared enumerators in the same enumeration are found first, before the unqualified name lookup proceeds to examine the enclosing block, class, or namespace scope.

const int RED = 7;
enum class color {
    RED,
    GREEN = RED+2, // RED finds color::RED, not ::RED, so GREEN = 2
    BLUE = ::RED+4 // qualified lookup finds ::RED, BLUE = 11
};
=============================================
Overloaded operator
For an operator used in expression (e.g., operator+ used in a+b), the lookup rules are slightly different from the operator used in an explicit function-call expression such as operator+(a,b): when parsing an expression, two separate lookups are performed: for the non-member operator overloads and for the member operator overloads (for the operators where both forms are permitted). Those sets are then merged with the built-in operator overloads on equal grounds as described in overload resolution. If explicit function call syntax is used, regular unqualified name lookup is performed:
=======================================
struct A {};
void operator+(A, A); // user-defined non-member operator+
 
struct B {
    void operator+(B); // user-defined member operator+
    void f ();
};
 
A a;
 
void B::f() // definition of a member function of B
{
    operator+(a,a); // error: regular name lookup from a member function
                    // finds the declaration of operator+ in the scope of B
                    // and stops there, never reaching the global scope
    a + a; // OK: member lookup finds B::operator+, non-member lookup
           // finds ::operator+(A,A), overload resolution selects ::operator+(A,A)
}
==============================
When # appears before __VA_ARGS__, the entire expanded __VA_ARGS__ is enclosed in quotes:

#define showlist(...) puts(#__VA_ARGS__)
showlist();            // expands to puts("")
showlist(1, "x", int); // expands to puts("1, \"x\", int")
===============================================
A ## operator between any two successive identifiers in the replacement-list runs parameter replacement on the two identifiers (which are not macro-expanded first) and then concatenates the result. This operation is called "concatenation" or "token pasting". Only tokens that form a valid token together may be pasted: identifiers that form a longer identifier, digits that form a number, or operators + and = that form a +=. A comment cannot be created by pasting / and * because comments are removed from text before macro substitution is considered. If the result of concatenation is not a valid token, the behavior is undefined.

Note: some compilers offer an extension that allows ## to appear after a comma and before __VA_ARGS__, in which case the ## does nothing when __VA_ARGS__ is non-empty, but removes the comma when __VA_ARGS__ is empty: this makes it possible to define macros such as fprintf (stderr, format, ##__VA_ARGS__)
==================================
#include <iostream>
 
//make function factory and use it
#define FUNCTION(name, a) int fun_##name() { return a;}
 
FUNCTION(abcd, 12)
FUNCTION(fff, 2)
FUNCTION(qqq, 23)
 
#undef FUNCTION
#define FUNCTION 34
#define OUTPUT(a) std::cout << #a << '\n'
 
int main()
{
    std::cout << "abcd: " << fun_abcd() << '\n';
    std::cout << "fff: " << fun_fff() << '\n';
    std::cout << "qqq: " << fun_qqq() << '\n';
    std::cout << FUNCTION << '\n';
    OUTPUT(million);               //note the lack of quotes
}
Output:

abcd: 12
fff: 2
qqq: 23
34
million
========================================
Pre-increment and pre-decrement operators increments or decrements the value of the object and returns a reference to the result.

Post-increment and post-decrement creates a copy of the object, increments or decrements the value of the object and returns the copy from before the increment or decrement.

Built-in prefix operators
For every optionally volatile-qualified arithmetic type A other than bool, and for every optionally volatile-qualified pointer P to optionally cv-qualified object type, the following function signatures participate in overload resolution:

A& operator++(A&)
bool& operator++(bool&)
(deprecated)(until C++17)
P& operator++(P&)
A& operator--(A&)
P& operator--(P&)
The operand of a built-in prefix increment or decrement operator must be a modifiable (non-const) lvalue of non-boolean arithmetic type or pointer to complete object type. For non-boolean operands, the expression ++x is exactly equivalent to x += 1, and the expression --x is exactly equivalent to x -= 1, that is, the prefix increment or decrement is an lvalue expression that identifies the modified operand. All arithmetic conversion rules and pointer arithmetic rules defined for arithmetic operators apply.

If the operand of the pre-increment operator is of type bool, it is set to true (deprecated). (until C++17)

Built-in postfix operators
For every optionally volatile-qualified arithmetic type A other than bool, and for every optionally volatile-qualified pointer P to optionally cv-qualified object type, the following function signatures participate in overload resolution:

A operator++(A&, int)
bool operator++(bool&, int)
(deprecated)(until C++17)
P operator++(P&, int)
A operator--(A&, int)
P operator--(P&, int)
================================
The keyword-like forms (and,or,not) and the symbol-like forms (&&,||,!) can be used interchangeably (See alternative representations)
All built-in operators return bool, and most user-defined overloads also return bool so that the user-defined operators can be used in the same manner as the built-ins. However, in a user-defined operator overload, any type can be used as return type (including void).
Builtin operators && and || perform short-circuit evaluation (do not evaluate the second operand if the result is known after evaluating the first), but overloaded operators behave like regular function calls and always evaluate both operands
