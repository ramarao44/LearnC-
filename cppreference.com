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

===============================
int n = 42; //const int n=42; this will work
double a[n][5]; // error
auto p1 = new double[n][5]; // okay
auto p2 = new double[5][n]; // error
=========================
static cast
===============
#include <vector>
#include <iostream>
 
struct B {
    int m = 0;
    void hello() const {
        std::cout << "Hello world, this is B!\n";
    }
};
struct D : B {
    void hello() const {
        std::cout << "Hello world, this is D!\n";
    }
};
 
enum class E { ONE = 1, TWO, THREE };
enum EU { ONE = 1, TWO, THREE };
 
int main()
{
    // 1: initializing conversion
    int n = static_cast<int>(3.14); 
    std::cout << "n = " << n << '\n';
    std::vector<int> v = static_cast<std::vector<int>>(10);
    std::cout << "v.size() = " << v.size() << '\n';
 
    // 2: static downcast
    D d;
    B& br = d; // upcast via implicit conversion
    br.hello();
    D& another_d = static_cast<D&>(br); // downcast
    another_d.hello();
 
    // 3: lvalue to xvalue
    std::vector<int> v2 = static_cast<std::vector<int>&&>(v);
    std::cout << "after move, v.size() = " << v.size() << '\n';
 
    // 4: discarded-value expression
    static_cast<void>(v2.size());
 
    // 5. inverse of implicit conversion
    void* nv = &n;
    int* ni = static_cast<int*>(nv);
    std::cout << "*ni = " << *ni << '\n';
 
    // 6. array-to-pointer followed by upcast
    D a[10];
    B* dp = static_cast<B*>(a);
 
    // 7. scoped enum to int or float
    E e = E::ONE;
    int one = static_cast<int>(e);
    std::cout << one << '\n';
 
    // 8. int to enum, enum to another enum
    E e2 = static_cast<E>(one);
    EU eu = static_cast<EU>(e2);
 
    // 9. pointer to member upcast
    int D::*pm = &D::m;
    std::cout << br.*static_cast<int B::*>(pm) << '\n';
 
    // 10. void* to any type
    void* voidp = &e;
    std::vector<int>* p = static_cast<std::vector<int>*>(voidp);
}

const cast
===============
#include <iostream>
 
struct type {
    type() :i(3) {}
    void m1(int v) const {
        // this->i = v;                 // compile error: this is a pointer to const
        const_cast<type*>(this)->i = v; // OK as long as the type object isn't const
    }
    int i;
};
 
int main() 
{
    int i = 3;                    // i is not declared const
    const int& cref_i = i; 
    const_cast<int&>(cref_i) = 4; // OK: modifies i
    std::cout << "i = " << i << '\n';
 
    type t; // note, if this is const type t;, then t.m1(4); is UB
    t.m1(4);
    std::cout << "type::i = " << t.i << '\n';
 
    const int j = 3; // j is declared const
    int* pj = const_cast<int*>(&j);
    *pj = 4;         // undefined behavior!
 
    void (type::*mfp)(int) const = &type::m1; // pointer to member function
//  const_cast<void(type::*)(int)>(mfp); // compiler error: const_cast does not
                                         // work on function pointers
}
=======================================
dynamic cast
====================================
#include <iostream>
 
struct V {
    virtual void f() {};  // must be polymorphic to use runtime-checked dynamic_cast
};
struct A : virtual V {};
struct B : virtual V {
  B(V* v, A* a) {
    // casts during construction (see the call in the constructor of D below)
    dynamic_cast<B*>(v); // well-defined: v of type V*, V base of B, results in B*
    dynamic_cast<B*>(a); // undefined behavior: a has type A*, A not a base of B
  }
};
struct D : A, B {
    D() : B((A*)this, this) { }
};
 
struct Base {
    virtual ~Base() {}
};
 
struct Derived: Base {
    virtual void name() {}
};
 
int main()
{
    D d; // the most derived object
    A& a = d; // upcast, dynamic_cast may be used, but unnecessary
    D& new_d = dynamic_cast<D&>(a); // downcast
    B& new_b = dynamic_cast<B&>(a); // sidecast
 
 
    Base* b1 = new Base;
    if(Derived* d = dynamic_cast<Derived*>(b1))
    {
        std::cout << "downcast from b1 to d successful\n";
        d->name(); // safe to call
    }
 
    Base* b2 = new Derived;
    if(Derived* d = dynamic_cast<Derived*>(b2))
    {
        std::cout << "downcast from b2 to d successful\n";
        d->name(); // safe to call
    }
 
    delete b1;
    delete b2;
}
==============================================
namespace defination only after declaration and within enclosing 
==============================================
namespace Q {
  namespace V { // original-namespace-definition for V
    void f(); // declaration of Q::V::f
  }
  void V::f() {} // OK
  void V::g() {} // Error: g() is not yet a member of V
  namespace V { // extension-namespace-definition for V
    void g(); // declaration of Q::V::g
  }
}
namespace R { // not a enclosing namespace for Q
   void Q::V::g() {} // Error: cannot define Q::V::g inside R
}
void Q::V::g() {} // OK: global namespace encloses Q
==============================================
friend functions in namespace
=================================================
void h(int);
namespace A {
  class X {
    friend void f(X); // A::f is a friend
    class Y {
        friend void g(); // A::g is a friend
        friend void h(int); // A::h is a friend, no conflict with ::h
    };
  };
  // A::f, A::g and A::h are not visible at namespace scope
  // even though they are members of the namespace A
  X x;
  void g() {  // definition of A::g
     f(x); // A::X::f is found through ADL
  }
  void f(X) {}       // definition of A::f
  void h(int) {}     // definition of A::h
  // A::f, A::g and A::h are now visible at namespace scope
  // and they are also friends of A::X and A::X::Y
}
=====================================================
unnamed namespace
====================================
namespace {
    int i;  // defines ::(unique)::i
}
void f() {
    i++;  // increments ::(unique)::i
}
 
namespace A {
    namespace {
        int i; // A::(unique)::i
        int j; // A::(unique)::j
    }
    void g() { i++; } // A::unique::i++
}
 
using namespace A; // introduces all names from A into global namespace
void h() {
    i++;    // error: ::(unique)::i and ::A::(unique)::i are both in scope
    A::i++; // ok, increments ::A::(unique)::i
    j++;    // ok, increments ::A::(unique)::j
}
=====================================
using declaration
===========================
void f();
namespace A {
    void g();
}
namespace X {
    using ::f; // global f is now visible as ::X::f
    using A::g; // A::g is now visible as ::X::g
    using A::g, A::g; // (C++17) OK: double declaration allowed at namespace scope
}
void h()
{
    X::f(); // calls ::f
    X::g(); // calls A::g
}
=====================
namespace extension
======================
namespace A {
    void f(int);
}
using A::f; // ::f is now a synonym for A::f(int)
 
namespace A { // namespace extension
   void f(char); // does not change what ::f means
}
void foo() {
    f('a'); // calls f(int), even though f(char) exists.
} 
void bar() {
   using A::f; // this f is a synonym for both A::f(int) and A::f(char)
   f('a'); // calls f(char)
}
=================================
Inner namespaces are preferred
=================================
namespace A {
    int i;
}
namespace B {
    int i;
    int j;
    namespace C {
        namespace D {
            using namespace A; // all names from A injected into global namespace
            int j;
            int k;
            int a = i; // i is B::i, because A::i is hidden by B::i
        }
        using namespace D; // names from D are injected into C
                           // names from A are injected into global namespace
        int k = 89; // OK to declare name identical to one introduced by a using
        int l = k;  // ambiguous: C::k or D::k
        int m = i;  // ok: B::i hides A::i
        int n = j;  // ok: D::j hides B::j
    }
}
====================
redeclaration of namesapce member
===============================
namespace D {
   int d1;
   void f(char);
}
using namespace D; // introduces D::d1, D::f, D::d2, D::f,
                   //  E::e, and E::f into global namespace!
 
int d1; // OK: no conflict with D::d1 when declaring
namespace E {
    int e;
    void f(int);
}
namespace D { // namespace extension
    int d2;
    using namespace E; // transitive using-directive
    void f(int);
}
void f() {
    d1++; // error: ambiguous ::d1 or D::d1?
    ::d1++; // OK
    D::d1++; // OK
    d2++; // OK, d2 is D::d2
    e++; // OK: e is E::e due to transitive using
    f(1); // error: ambiguous: D::f(int) or E::f(int)?
    f('a'); // OK: the only f(char) is D::f(char)
}
============================
Reference
==============================
Declares a named variable as a reference, that is, an alias to an already-existing object or function.

Syntax
A reference variable declaration is any simple declaration whose declarator has the form

& attr(optional) declarator	(1)	lvalue decl
&& attr(optional) declarator	(2)	rvalue decl  (since C++11)

A reference is required to be initialized to refer to a valid object or function: see reference initialization.

There are no references to void and no references to references.
Reference types cannot be cv-qualified at the top level; there is no syntax for that in declaration, 
and if a qualification is introduced through a typedef, decltype, or template type argument, it is ignored.
References are not objects; they do not necessarily occupy storage, although the compiler may allocate 
storage if it is necessary to implement the desired semantics (e.g. a non-static data member of reference
type usually increases the size of the class by the amount necessary to store a memory address).

Because references are not objects, there are no arrays of references, no pointers to references, 
and no references to references:


int& a[3]; // error
int&* p;   // error
int& &r;   // error
======================
const reference
================
int main()
{
    std::string s = "Ex";
    std::string& r1 = s;
    const std::string& r2 = s;
 
    r1 += "ample";           // modifies s
//  r2 += "!";               // error: cannot modify through reference to const
    std::cout << r2 << '\n'; // prints s, which now holds "Example"
}
===========================
function call reference
=======================
#include <iostream>
#include <string>
 
char& char_number(std::string& s, std::size_t n)
{
    return s.at(n); // string::at() returns a reference to char
}
 
int main()
{
    std::string str = "Test";
    char_number(str, 1) = 'a'; // the function call is lvalue, can be assigned to
    std::cout << str << '\n';
}
================================
Rvalue references
Rvalue references can be used to extend the lifetimes of temporary objects
(note, lvalue references to const can extend the lifetimes of temporary objects too, 
but they are not modifiable through them):
========================
const reference
=========================
#include <iostream>
#include <string>
 
int main()
{
    std::string s1 = "Test";
//  std::string&& r1 = s1;           // error: can't bind to lvalue
 
    const std::string& r2 = s1 + s1; // okay: lvalue reference to const extends lifetime
//  r2 += "Test";                    // error: can't modify through reference to const
 
    std::string&& r3 = s1 + s1;      // okay: rvalue reference extends lifetime
    r3 += "Test";                    // okay: can modify through reference to non-const
    std::cout << r3 << '\n';
}
========================
reference function overload
=======================
#include <iostream>
#include <utility>
 
void f(int& x)
{
    std::cout << "lvalue reference overload f(" << x << ")\n";
}
 
void f(const int& x)
{
    std::cout << "lvalue reference to const overload f(" << x << ")\n";
}
 
void f(int&& x)
{
    std::cout << "rvalue reference overload f(" << x << ")\n";
}
 
int main()
{
    int i = 1;
    const int ci = 2;
    f(i);  // calls f(int&)
    f(ci); // calls f(const int&)
    f(3);  // calls f(int&&)
           // would call f(const int&) if f(int&&) overload wasn't provided
    f(std::move(i)); // calls f(int&&)
}
=====================================
Dangling references
=======================
Although references, once initialized, always refer to valid objects or functions, 
it is possible to create a program where the lifetime of the referred-to object ends,
but the reference remains accessible (dangling). Accessing such a reference is undefined behavior.
A common example is a function returning a reference to an automatic variable:
std::string& f()
{
    std::string s = "Example";
    return s; // exits the scope of s:
              // its destructor is called and its storage deallocated
}
 
std::string& r = f(); // dangling reference
std::cout << r;       // undefined behavior: reads from a dangling reference
std::string s = f();  // undefined behavior: copy-initializes from a dangling reference
===================================
pointer declaration
===================================
int n;
int* np = &n; // pointer to int
int* const* npp = &np; // non-const pointer to const pointer to non-const int
 
int a[2];
int (*ap)[2] = &a; // pointer to array of int
 
struct S { int n; };
S s = {1};
int* sp = &s.n; // pointer to the int that is a member of s
========================================
int n;
int* p = &n;     // pointer to n
int& r = *p;     // reference is bound to the lvalue expression that identifies n
r = 7;           // stores the int 7 in n
std::cout << *p; // lvalue-to-rvalue implicit conversion reads the value from n
==================
int a[2];
int* p1 = a; // pointer to the first element a[0] (an int) of the array a
 
int b[6][3][8];
int (*p2)[3][8] = b; // pointer to the first element b[0] of the array b,
                     // which is an array of 3 arrays of 8 ints
 ===============================Because of the derived-to-base implicit conversion for pointers, pointer to a base class can be initialized with the address of a derived class:

struct Base {};
struct Derived : Base {};
 
Derived d;
Base* p = &d;
If Derived is polymorphic, such pointer may be used to make virtual function calls.
=====================
pointer to functions
=======================
Pointers to functions
A pointer to function can be initialized with an address of a non-member function or a static member function. Because of the function-to-pointer implicit conversion, the address-of operator is optional:

void f(int);
void (*p1)(int) = &f;
void (*p2)(int) = f; // same as &f
=========================
Dereferencing a function pointer yields the lvalue identifying the pointed-to function:

int f();
int (*p)() = f;  // pointer p is pointing to f
int (&r)() = *p; // the lvalue that identifies f is bound to a reference
r();             // function f invoked through lvalue reference
(*p)();          // function f invoked through the function lvalue
p();             // function f invoked directly through the pointer
===============================
A pointer to function may be initialized from an overload set which may include functions, function template specializations, and function templates, if only one overload matches the type of the pointer (see address of an overloaded function for more detail):

template<typename T> T f(T n) { return n; }
double f(double n) { return n; }
 
int main()
{
    int (*p)(int) = f; // instantiates and selects f<int>
}
==================================
Pointers to data members
A pointer to non-static member object m which is a member of class C can be initialized with the expression &C::m exactly. Expressions such as &(C::m) or &m inside C's member function do not form pointers to members.

Such pointer may be used as the right-hand operand of the pointer-to-member access operators operator.* and operator->*:

struct C { int m; };
 
int main()
{
    int C::* p = &C::m;          // pointer to data member m of class C
    C c = {7};
    std::cout << c.*p << '\n';   // prints 7
    C* cp = &c;
    cp->m = 10;
    std::cout << cp->*p << '\n'; // prints 10
}
=========================
Pointer to data member of an accessible unambiguous non-virtual base class can be implicitly converted to pointer to the same data member of a derived class:

struct Base { int m; };
struct Derived : Base {};
 
int main()
{
    int Base::* bp = &Base::m;
    int Derived::* dp = bp;
    Derived d;
    d.m = 1;
    std::cout << d.*dp << ' ' << d.*bp << '\n'; // prints 1 1
}
=============================
Conversion in the opposite direction, from a pointer to data member of a derived class to a pointer to data member of an unambiguous non-virtual base class, is allowed with static_cast and explicit cast, even if the base class does not have that member (but the most-derived class does, when the pointer is used for access):

struct Base {};
struct Derived : Base { int m; };
 
int main()
{
    int Derived::* dp = &Derived::m;
    int Base::* bp = static_cast<int Base::*>(dp);
 
    Derived d;
    d.m = 7;
    std::cout << d.*bp << '\n'; // okay: prints 7
 
    Base b;
    std::cout << b.*bp << '\n'; // undefined behavior
}
================================
Pointers to member functions
A pointer to non-static member function f which is a member of class C can be initialized with the expression &C::f exactly. Expressions such as &(C::f) or &f inside C's member function do not form pointers to member functions.

Such pointer may be used as the right-hand operand of the pointer-to-member access operators operator.* and operator->*. The resulting expression can be used only as the left-hand operand of a function-call operator:

struct C
{
    void f(int n) { std::cout << n << '\n'; }
};
 
int main()
{
    void (C::* p)(int) = &C::f; // pointer to member function f of class C
    C c;
    (c.*p)(1);                  // prints 1
    C* cp = &c;
    (cp->*p)(2);                // prints 2
}

Pointer to member function of a base class can be implicitly converted to pointer to the same member function of a derived class:
=====================
pointer to member function of a base class 
==================================
Pointer to member function of a base class can be implicitly converted to pointer to the same member function of a derived class:

struct Base
{
    void f(int n) { std::cout << n << '\n'; }
};
struct Derived : Base {};
 
int main()
{
    void (Base::* bp)(int) = &Base::f;
    void (Derived::* dp)(int) = bp;
    Derived d;
    (d.*dp)(1);
    (d.*bp)(2);
}
========================================
Array-to-pointer decay
There is an implicit conversion from lvalues and rvalues of array type to rvalues of pointer type: it constructs a pointer to the first element of an array. This conversion is used whenever arrays appear in context where arrays are not expected, but pointers are:

Run this code
#include <iostream>
#include <numeric>
#include <iterator>
 
void g(int (&a)[3])
{
    std::cout << a[0] << '\n';
}
 
void f(int* p)
{
    std::cout << *p << '\n';
}
 
int main()
{
    int a[3] = {1, 2, 3};
    int* p = a;
 
    std::cout << sizeof a << '\n'  // prints size of array
              << sizeof p << '\n'; // prints size of a pointer
 
    // where arrays are acceptable, but pointers aren't, only arrays may be used
    g(a); // okay: function takes an array by reference
//  g(p); // error
 
    for(int n: a)              // okay: arrays can be used in range-for loops
        std::cout << n << ' '; // prints elements of the array
//  for(int n: p)              // error
//      std::cout << n << ' ';
 
    std::iota(std::begin(a), std::end(a), 7); // okay: begin and end take arrays
//  std::iota(std::begin(p), std::end(p), 7); // error
 
    // where pointers are acceptable, but arrays aren't, both may be used:
    f(a); // okay: function takes a pointer
    f(p); // okay: function takes a pointer
 
    std::cout << *a << '\n' // prints the first element
              << *p << '\n' // same
              << *(a + 1) << ' ' << a[1] << '\n'  // prints the second element
              << *(p + 1) << ' ' << p[1] << '\n'; // same
 ================================================
 int a[2];            // array of 2 int
int* p1 = a;         // a decays to a pointer to the first element of a
 
int b[2][3];         // array of 2 arrays of 3 int
// int** p2 = b;     // error: b does not decay to int**
int (*p2)[3] = b;    // b decays to a pointer to the first 3-element row of b
 
int c[2][3][4];      // array of 2 arrays of 3 arrays of 4 int
// int*** p3 = c;    // error: c does not decay to int***
int (*p3)[3][4] = c; // c decays to a pointer to the first 3 × 4-element plane of c
====================================
Arrays of unknown bound
If expr is omitted in the declaration of an array, the type declared is "array of unknown bound of T", which is a kind of incomplete type, except when used in a declaration with an aggregate initializer:

extern int x[];      // the type of x is "array of unknown bound of int"
int a[] = {1, 2, 3}; // the type of a is "array of 3 int"
Because array element cannot have incomplete type, multidimensional arrays cannot have unknown bound in a dimension other than the first:

extern int a[][2]; // okay: array of unknown bound of arrays of 2 int
extern int b[2][]; // error: array has incomplete element type
References and pointers to arrays of unknown bound can be formed, but cannot be initialized or assigned from arrays and pointers to arrays of known bound. Note that in the C programming language, pointers to arrays of unknown bound are compatible with pointers to arrays of known bound and are thus convertible and assignable in both directions.

extern int a1[];
int (&r1)[] = a1;  // okay
int (*p1)[] = &a1; // okay
int (*q)[2] = &a1; // error (but okay in C)
 
int a2[] = {1, 2, 3};
int (&r2)[] = a2;  // error
int (*p2)[] = &a2; // error (but okay in C)
Pointers to arrays of unknown bound cannot participate in pointer arithmetic and cannot be used on the left of the 
subscript operator, but can be dereferenced. Pointers and references to arrays of unknown bound cannot be used in 
function parameters (until C++14).
===============================
#include <iostream>
#include <type_traits>
#include <utility>
 
void f(int (&&x)[2][3])
{
    std::cout << sizeof x << '\n';
}
 
struct X
{
    int i[2][3];
} x;
 
template<typename T> using identity = T;
 
int main()
{
    std::cout << sizeof X().i << '\n';           // size of the array
    f(X().i);                                    // okay: binds to xvalue
//  f(x.i);                                      // error: cannot bind to lvalue
 
    int a[2][3];
    f(std::move(a));                             // okay: binds to xvalue
 
    using arr_t = int[2][3];
    f(arr_t{});                                  // okay: binds to prvalue
    f(identity<int[][3]>{{1, 2, 3}, {4, 5, 6}}); // okay: binds to prvalue
 
}
=======================================
enumeration
=====================
enum Color { red, green, blue };
Color r = red;
switch(r)
{
    case red  : std::cout << "red\n";   break;
    case green: std::cout << "green\n"; break;
    case blue : std::cout << "blue\n";  break;
}
=================
enum color { red, yellow, green = 20, blue };
color col = red;
int n = blue; // n == 21
=====
enum access_t { read = 1, write = 2, exec = 4 }; // enumerators: 1, 2, 4 range: 0..7
access_t rw = static_cast<access_t>(3);
assert(rw & read && rw & write);
=================================
When an unscoped enumeration is a class member, its enumerators may be accessed using class member access operators . and ->:

struct X
{
    enum direction { left = 'l', right = 'r' };
};
X x;
X* p = &x;
 
int a = X::direction::left; // allowed only in C++11 and later
int b = X::left;
int c = x.left;
int d = p->left;
============================
enum class Color { red, green = 20, blue };
Color r = Color::blue;
switch(r)
{
    case Color::red  : std::cout << "red\n";   break;
    case Color::green: std::cout << "green\n"; break;
    case Color::blue : std::cout << "blue\n";  break;
}
// int n = r; // error: no scoped enum to int conversion
int n = static_cast<int>(r); // OK, n = 21
==============================
storage
=============================
Linkage
A name that denotes object, reference, function, type, template, namespace, or value, may have linkage. If a name has linkage, it refers to the same entity as the same name introduced by a declaration in another scope. If a variable, function, or another entity with the same name is declared in several scopes, but does not have sufficient linkage, then several instances of the entity are generated.

The following linkages are recognized:

no linkage. The name can be referred to only from the scope it is in.
Any of the following names declared at block scope have no linkage:
Variables that aren't explicitly declared extern (regardless of the static modifier)
Local classes and their member functions
Other names declared at block scope such as typedefs, enumerations, and enumerators
internal linkage. The name can be referred to from all scopes in the current translation unit.
Any of the following names declared at namespace scope have internal linkage
variables, functions, or function templates declared static
non-volatile non-inline (since C++17) const-qualified variables (including constexpr) that aren't declared extern and aren't previously declared to have external linkage.
data members of anonymous unions
In addition, all names declared in unnamed namespace or a namespace within an unnamed namespace, even ones explicitly declared extern, have internal linkage.
(since C++11)
external linkage. The name can be referred to from the scopes in the other translation units. Variables and functions with external linkage also have language linkage, which makes it possible to link translation units written in different programming languages.
Any of the following names declared at namespace scope have external linkage unless the namespace is unnamed or is contained within an unnamed namespace (since C++11)
variables and functions not listed above (that is, functions not declared static, namespace-scope non-const variables not declared static, and any variables declared extern)
enumerations and enumerators
names of classes, their member functions, static data members (const or not), nested classes and enumerations, and functions first introduced with friend declarations inside class bodies
names of all templates not listed above (that is, not function templates declared static)
Any of the following names first declared at block scope have external linkage
names of variables declared extern
names of functions
Static local variables
Variables declared at block scope with the specifier static have static storage duration but are initialized the first time control passes through their declaration (unless their initialization is zero- or constant-initialization, which can be performed before the block is first entered). On all further calls, the declaration is skipped.

If the initialization throws an exception, the variable is not considered to be initialized, and initialization will be attempted again the next time control passes through the declaration.

If the initialization recursively enters the block in which the variable is being initialized, the behavior is undefined.

If multiple threads attempt to initialize the same static local variable concurrently, the initialization occurs exactly once (similar behavior can be obtained for arbitrary functions with std::call_once).
Note: usual implementations of this feature use variants of the double-checked locking pattern, which reduces runtime overhead for already-initialized local statics to a single non-atomic boolean comparison.	(since C++11)
The destructor for a block-scope static variable is called at program exit, but only if the initialization took place successfully.
========================
Default initialization
=======================
Explanation
Default initialization is performed in three situations:

1) when a variable with automatic, static, or thread-local storage duration is declared with no initializer;
2) when an object with dynamic storage duration is created by a new-expression with no initializer or when an object is created by a new-expression with the initializer consisting of an empty pair of parentheses (until C++03);
3) when a base class or a non-static data member is not mentioned in a constructor initializer list and that constructor is called.
=============================
value initialization
===========================
include <string>
#include <vector>
#include <iostream>
 
struct T1
{
    int mem1;
    std::string mem2;
}; // implicit default constructor
 
struct T2
{
    int mem1;
    std::string mem2;
    T2(const T2&) { } // user-provided copy constructor
};                    // no default constructor
 
struct T3
{
    int mem1;
    std::string mem2;
    T3() { } // user-provided default constructor
};
 
std::string s{}; // class => default-initialization, the value is ""
 
int main()
{
    int n{};                // scalar => zero-initialization, the value is 0
    double f = double();    // scalar => zero-initialization, the value is 0.0
    int* a = new int[10](); // array => value-initialization of each element
                            //          the value of each element is 0
    T1 t1{};                // class with implicit default constructor =>
                            //     t1.mem1 is zero-initialized, the value is 0
                            //     t1.mem2 is default-initialized, the value is ""
//  T2 t2{};                // error: class with no default constructor
    T3 t3{};                // class with user-provided default constructor =>
                            //     t3.mem1 is default-initialized to indeterminate value
                            //     t3.mem2 is default-initialized, the value is ""
    std::vector<int> v(3);  // value-initialization of each element
                            // the value of each element is 0
    std::cout << s.size() << ' ' << n << ' ' << f << ' ' << a[9] << ' ' << v[2] << '\n';
    std::cout << t1.mem1 << ' ' << t3.mem1 << '\n';
    delete[] a
    ===================================
Possible output:

0 0 0 0 0
0 4199376
===================
Copy-initialization is less permissive than direct-initialization: explicit constructors are not converting constructors and are not considered for copy-initialization.

struct Exp { explicit Exp(const char*) {} }; // not convertible from const char*
Exp e1("abc");  // OK
Exp e2 = "abc"; // Error, copy-initialization does not consider explicit constructor
 
struct Imp { Imp(const char*) {} }; // convertible from const char*
Imp i1("abc");  // OK
Imp i2 = "abc"; // OK
In addition, the implicit conversion in copy-initialization must produce T directly from the initializer, while, e.g. direct-initialization expects an implicit conversion from the initializer to an argument of T's constructor.

struct S { S(std::string) {} }; // implicitly convertible from std::string
S s("abc"); // OK: conversion from const char[4] to std::string
S s = "abc"; // Error: no conversion from const char[4] to S
S s = "abc"s; // OK: conversion from std::string to S
============================
Explanation
Direct initialization is performed in the following situations:

1) initialization with a nonempty parenthesized list of expressions
2) during list-initialization sequence, if no initializer-list constructors are provided and a matching constructor is accessible, and all necessary implicit conversions are non-narrowing.
3) initialization of a prvalue temporary by functional cast or with a parenthesized expression list
4) initialization of a prvalue temporary by a static_cast expression
5) initialization of an object with dynamic storage duration by a new-expression with a non-empty initializer
6) initialization of a base or a non-static member by constructor initializer list
7) initialization of closure object members from the variables caught by copy in a lambda-expression
=================
#include <string>
#include <iostream>
#include <memory>
 
struct Foo {
    int mem;
    explicit Foo(int n) : mem(n) {}
};
 
int main()
{
    std::string s1("test"); // constructor from const char*
    std::string s2(10, 'a');
 
    std::unique_ptr<int> p(new int(1)); // OK: explicit constructors allowed
//  std::unique_ptr<int> p = new int(1); // error: constructor is explicit
 
    Foo f(2); // f is direct-initialized:
              // constructor parameter n is copy-initialized from the rvalue 2
              // f.mem is direct-initialized from the parameter n
//  Foo f2 = 2; // error: constructor is explicit
 
    std::cout << s1 << ' ' << s2 << ' ' << *p << ' ' << f.mem  << '\n';
}
===========================
aggregate initialization
=======================
#include <string>
#include <array>
struct S {
    int x;
    struct Foo {
        int i;
        int j;
        int a[3];
    } b;
};
 
union U {
    int a;
    const char* b;
};
 
int main()
{
    S s1 = { 1, { 2, 3, {4, 5, 6} } };
    S s2 = { 1, 2, 3, 4, 5, 6}; // same, but with brace elision
    S s3{1, {2, 3, {4, 5, 6} } }; // same, using direct-list-initialization syntax
    S s4{1, 2, 3, 4, 5, 6}; // error in C++11: brace-elision only allowed with equals sign
                            // okay in C++14
 
    int ar[] = {1,2,3}; // ar is int[3]
//  char cr[3] = {'a', 'b', 'c', 'd'}; // too many initializer clauses
    char cr[3] = {'a'}; // array initialized as {'a', '\0', '\0'}
 
    int ar2d1[2][2] = {{1, 2}, {3, 4}}; // fully-braced 2D array: {1, 2}
                                        //                        {3, 4}
    int ar2d2[2][2] = {1, 2, 3, 4}; // brace elision: {1, 2}
                                    //                {3, 4}
    int ar2d3[2][2] = {{1}, {2}};   // only first column: {1, 0}
                                    //                    {2, 0}
 
    std::array<int, 3> std_ar2{ {1,2,3} };    // std::array is an aggregate
    std::array<int, 3> std_ar1 = {1, 2, 3}; // brace-elision okay
 
    int ai[] = { 1, 2.0 }; // narrowing conversion from double to int:
                           // error in C++11, okay in C++03
 
    std::string ars[] = {std::string("one"), // copy-initialization
                         "two",              // conversion, then copy-initialization
                         {'t', 'h', 'r', 'e', 'e'} }; // list-initialization
 
    U u1 = {1}; // OK, first member of the union
//    U u2 = { 0, "asdf" }; // error: too many initializers for union
//    U u3 = { "asdf" }; // error: invalid conversion to int
 
}
 
// aggregate
struct base1 { int b1, b2 = 42; };
// non-aggregate
struct base2 {
  base2() : b3(42) {}
  int b3;
};
// aggregate in C++17
struct derived : base1, base2 { int d; };
derived d1{ {1, 2}, { }, 4}; // d1.b1 = 1, d1.b2 = 2,  d1.b3 = 42, d1.d = 4
derived d2{ {    }, { }, 4}; // d2.b1 = 0, d2.b2 = 42, d2.b3 = 42, d2.d = 4
======================
reference initialization
=========================
#include <utility>
#include <sstream>
struct S {
 int mi;
 const std::pair<int,int>& mp; // reference member
};
 
void foo(int) {}
 
struct A {};
struct B : A {
   int n;
   operator int&() { return n; };
};
 
B bar() {return B(); }
 
//int& bad_r; // error: no initializer
extern int& ext_r; // OK
 
int main()
{
 // lvalues
    int n = 1;
    int& r1 = n;  // lvalue reference to the object n
    const int& cr(n); // reference can be more cv-qualified
    volatile int& cv{n}; // any initializer syntax can be used
    int& r2 = r1; // another lvalue reference to the object n
//    int& bad = cr; // error: less cv-qualified
    int& r3 = const_cast<int&>(cr); // const_cast is needed
 
    void (&rf)(int) = foo; // lvalue reference to function
    int ar[3];
    int (&ra)[3] = ar; // lvalue reference to array
 
    B b;
    A& base_ref = b; // reference to base subobject
    int& converted_ref = b; // reference to the result of a conversion
 
// rvalues
//  int& bad = 1; // error: cannot bind lvalue ref to rvalue
    const int& cref = 1; // bound to rvalue
    int&& rref = 1; // bound to rvalue
 
    const A& cref2 = bar(); // reference to A subobject of B temporary
    A&& rref2 = bar();      // same
 
    int&& xref = static_cast<int&&>(n); // bind directly to n
//  int&& copy_ref = n; // error: can't bind to an lvalue
    double&& copy_ref = n; // bind to an rvalue temporary with value 1.0
 
// restrictions on temporary lifetimes
    std::ostream& buf_ref = std::ostringstream() << 'a'; // the ostringstream temporary
                      // was bound to the left operand of operator<<, but its lifetime
                      // ended at the semicolon: buf_ref is now a dangling reference.
 
    S a { 1, {2,3} }; // temporary pair {2,3} bound to the reference member
                      // a.mp and its lifetime is extended to match a
                      // (Note: does not compile in C++17)
    S* p = new S{ 1, {2,3} }; // temporary pair {2,3} bound to the reference
                      // member p->mp, but its lifetime ended at the semicolon
                      //  p->mp is a dangling reference
    delete p;
}
=====================
The names used in the default arguments are looked up, checked for accessibility, and bound at the point of declaration, but are executed at the point of the function call:

int a = 1;
int f(int);
int g(int x = f(a)); // lookup for f finds ::f, lookup for a finds ::a
                     // the value of ::a, which is 1 at this point, is not used
void h()
{
  a = 2;  // changes the value of ::a
  {
     int a = 3;
     g();       // calls f(2), then calls g() with the result
  }
}
For a member function of a non-template class, the default arguments are allowed on the out-of-class definition, and are combined with the default arguments provided by the declaration inside the class body. If these out-of-class defaults would turn a member function into a default, copy, or move constructor the program is ill-formed. For member functions of class templates, all defaults must be provided in the initial declaration of the member function.

class C {
    void f(int i = 3);
    void g(int i, int j = 99);
    C(int arg); // non-default constructor
};
void C::f(int i = 3) {         // error: default argument already
}                              // specified in class scope
void C::g(int i = 88, int j) { // OK: in this translation unit,
}                              // C::g can be called with no argument
C::C(int arg = 1) {   // Error: turns this into a default constructor
}
The overriders of virtual functions do not acquire the default arguments from the base class declarations, and when the virtual function call is made, the default arguments are decided based on the static type of the object (note: this can be avoided with non-virtual interface pattern).

struct Base {
    virtual void f(int a = 7);
};
struct Derived : Base {
    void f(int a) override;
};
void m() {
    Derived d;
    Base& b = d;
    b.f(); // OK: calls Derived::f(7) 
    d.f(); // Error: no default 
}
Local variables are not allowed in default arguments unless used in unevaluated context (since C++14):

void f() 
{
    int n = 1;
    extern void g(int x = n); // error: local variable cannot be a default
    extern void h(int x = sizeof n); // OK as of CWG 2082
}
=========================
The this pointer is not allowed in default arguments:

class A {
  void f(A* p = this) { } // error: this is not allowed
};
Non-static class members are not allowed in default arguments (even if they are not evaluated), except when used to form a pointer-to-member or in a member access expression.

int b;
class X {
  int a;
  int mem1(int i = a); // error: non-static member cannot be used
  int mem2(int i = b); // OK: lookup finds X::b, the static member
  static int b;
};
Function parameters are not allowed in default arguments (even if they are not evaluated) (until C++14)except if they are unevaluated (since C++14). Note that parameters that appear earlier in the parameter list are in scope:

int a;
int f(int a, int b = a); // Error: the parameter a used in a default argument
int g(int a, int b = sizeof a); // Error until CWG 2082
                                // OK after CWG 2082: use in unevaluated context is OK
The default arguments are not part of the function type

int f(int = 0);
void h() {
  int j = f(1);
  int k = f();  // calls f(0);
}
int (*p1)(int) = &f;
int (*p2)()    = &f; //Error: the type of f is int(int)
=======================================
Operator functions shall not have default arguments, except for the function call operator.

class C {
    int operator[](int i = 0); // ill-formed
    int operator()(int x = 0); // ok
};
====================================
forward declaration
====================================
struct s { int a; };
struct s; // does nothing (s already defined in this scope)
void g() {
    struct s; // forward declaration of a new, local struct "s"
              // this hides global struct s until the end of this block
    s* p;     // pointer to local struct s
    struct s { char* p; }; // definitions of the local struct s
}
=================================
Union declaration
  C++  C++ language  Classes 
A union is a special class type that can hold only one of its non-static data members at a time.

The class specifier for a union declaration is similar to class or struct declaration:

union attr class-head-name { member-specification }		
attr(C++11)	-	optional sequence of any number of attributes
class-head-name	-	the name of the union that's being defined. Optionally prepended by nested-name-specifier (sequence of names and scope-resolution operators, ending with scope-resolution operator). The name may be omitted, in which case the union is unnamed
member-specification	-	list of access specifiers, member object and member function declarations and definitions.
A union can have member functions (including constructors and destructors), but not virtual functions.

A union cannot have base classes and cannot be used as a base class.

A union cannot have data members of reference types.
====================================
#include <iostream>
 
// S has one non-static data member (tag), three enumerator members (CHAR, INT, DOUBLE), 
// and three variant members (c, i, d)
struct S
{
    enum{CHAR, INT, DOUBLE} tag;
    union
    {
        char c;
        int i;
        double d;
    };
};
 
void print_s(const S& s)
{
    switch(s.tag)
    {
        case S::CHAR: std::cout << s.c << '\n'; break;
        case S::INT: std::cout << s.i << '\n'; break;
        case S::DOUBLE: std::cout << s.d << '\n'; break;
    }
}
 
int main()
{
    S s = {S::CHAR, 'a'};
    print_s(s);
    s.tag = S::INT;
    s.i = 123;
    print_s(s);
}
===========================
data members
===============================Non-static data members are declared in a member specification of a class.

class S
{
    int n;                // non-static data member
    int& r;               // non-static data member of reference type
    int a[10] = {1, 2};   // non-static data member with initializer (C++11)
    std::string s, *ps;   // two non-static data members
    struct NestedS {
        std::string s;
    } d5, *d6;            // two non-static data members of nested type
    char bit : 2;         // two-bit bitfield
};
Any simple declarations are allowed, except

extern and register storage class specifiers are not allowed;
thread_local storage class specifier is not allowed (but it is allowed for static data members);
incomplete types are not allowed: in particular, a class C cannot have a non-static data member of type C, although it can have a non-static data member of type C& (reference to C) or C* (pointer to C);
a non-static data member cannot have the same name as the name of the class if at least one user-declared constructor is present;
the auto specifier cannot be used in a non-static data member declaration (although it is allowed for static data members that are initialized in the class definition).
In addition, bit field declarations are allowed.
===========================
class default initializer
=================================
#include <iostream>
 
int x = 0;
struct S
{
    int n = ++x;
    S() { }                 // uses default member initializer
    S(int arg) : n(arg) { } // uses member initializer list
};
 
int main()
{
    std::cout << x << '\n'; // prints 0
    S s1;
    std::cout << x << '\n'; // prints 1 (default initializer ran)
    S s2(7);
    std::cout << x << '\n'; // prints 1 (default initializer did not run)
}
==========================================
Default member initializers are not allowed for bit field members.

Members of array type cannot deduce their size from member initializers:

struct X {
   int a[] = {1,2,3}; // error
   int b[3] = {1,2,3}; // OK
};
=====================================
Static member functions
Static member functions are not associated with any object. When called, they have no this pointer.

Static member functions cannot be virtual, const, or volatile.

The address of a static member function may be stored in a regular pointer to function, 
but not in a pointer to member function.
====================================
Static data members
Static data members are not associated with any object. They exist even if no objects of the class have been defined. If the static member is declared thread_local(since C++11), there is one such object per thread. Otherwise, there is only one instance of the static data member in the entire program, with static storage duration.

Static data members cannot be mutable.

Static data members of a class in namespace scope have external linkage if the class itself has external linkage (i.e. is not a member of unnamed namespace). Local classes (classes defined inside functions) and unnamed classes, including member classes of unnamed classes, cannot have static data members.

A static data member may be declared inline. An inline static data member can be defined in the class definition and may specify a default member initializer. It does not need an out-of-class definition:

======================================
Constant static members
If a static data member of integral or enumeration type is declared const (and not volatile), it can be initialized with an initializer in which every expression is a constant expression, right inside the class definition:

struct X
{
    const static int n = 1;
    const static int m{2}; // since C++11
    const static int k;
};
const int X::k = 3;
=====================
USING 
=======================
#include <iostream>
struct B {
    virtual void f(int) { std::cout << "B::f\n"; }
    void g(char)        { std::cout << "B::g\n"; }
    void h(int)         { std::cout << "B::h\n"; }
 protected:
    int m; // B::m is protected
    typedef int value_type;
};
 
struct D : B {
    using B::m; // D::m is public
    using B::value_type; // D::value_type is public
 
    using B::f;
    void f(int) { std::cout << "D::f\n"; } // D::f(int) overrides B::f(int)
    using B::g;
    void g(int) { std::cout << "D::g\n"; } // both g(int) and g(char) are visible
                                           // as members of D
    using B::h;
    void h(int) { std::cout << "D::h\n"; } // D::h(int) hides B::h(int)
};
 
int main()
{
    D d;
    B& b = d;
 
//    b.m = 2; // error, B::m is protected
    d.m = 1; // protected B::m is accessible as public D::m
    b.f(1); // calls derived f()
    d.f(1); // calls derived f()
    d.g(1); // calls derived g(int)
    d.g('a'); // calls base g(char)
    b.h(1); // calls base h()
    d.h(1); // calls derived h()
}
Output:

D::f
D::f
D::g
B::g
B::h
D::h
===============================
#include <iostream>
struct Base {
   virtual void f() {
       std::cout << "base\n";
   }
};
struct Derived : Base {
    void f() override { // 'override' is optional
        std::cout << "derived\n";
    }
};
int main()
{
    Base b;
    Derived d;
 
    // virtual function call through reference
    Base& br = b; // the type of br is Base&
    Base& dr = d; // the type of dr is Base& as  well
    br.f(); // prints "base"
    dr.f(); // prints "derived"
 
    // virtual function call through pointer
    Base* bp = &b; // the type of bp is Base*
    Base* dp = &d; // the type of dp is Base* as  well
    bp->f(); // prints "base"
    dp->f(); // prints "derived"
 
    // non-virtual function call
    br.Base::f(); // prints "base"
    dr.Base::f(); // prints "base"
}
=======================================
struct A { virtual void f(); };     // A::f is virtual
struct B : A { void f(); };         // B::f overrides A::f in B
struct C : virtual B { void f(); }; // C::f overrides A::f in C
struct D : virtual B {}; // D does not introduce an overrider, B::f is final in D
struct E : C, D  {       // E does not introduce an overrider, C::f is final in E
    using A::f; // not a function declaration, just makes A::f visible to lookup
};
int main() {
   E e;
   e.f();    // virtual call calls C::f, the final overrider in e
   e.E::f(); // non-virtual call calls A::f, which is visible in E
}
=====================
final override function
====================
struct A {
    virtual void f();
};
struct VB1 : virtual A {
    void f(); // overrides A::f
};
struct VB2 : virtual A {
    void f(); // overrides A::f
};
// struct Error : VB1, VB2 {
//     // Error: A::f has two final overriders in Error
// };
struct Okay : VB1, VB2 {
    void f(); // OK: this is the final overrider for A::f
};
struct VB1a : virtual A {}; // does not declare an overrider
struct Da : VB1a, VB2 {
    // in Da, the final overrider of A::f is VB2::f
}
=====================
struct B {
    virtual void f();
};
struct D : B {
    void f(int); // D::f hides B::f (wrong parameter list)
};
struct D2 : D {
    void f(); // D2::f overrides B::f (doesn't matter that it's not visible)
};
 
int main()
{
    B b;   B& b_as_b   = b;
    D d;   B& d_as_b   = d;    D& d_as_d = d;
    D2 d2; B& d2_as_b  = d2;   D& d2_as_d = d2;
 
    b_as_b.f(); // calls B::f()
    d_as_b.f(); // calls B::f()
    d2_as_b.f(); // calls D2::f()
 
    d_as_d.f(); // Error: lookup in D finds only f(int)
    d2_as_d.f(); // Error: lookup in D finds only f(int)
}
===================
Non-member functions and static member functions cannot be virtual.

Functions templates cannot be declared virtual. This applies only to functions that are themselves templates - a regular member function of a class template can be declared virtual.

Virtual functions cannot have any associated constraints.

========================
Virtual destructor
Even though destructors are not inherited, if a base class declares its destructor virtual, the derived destructor always overrides it. This makes it possible to delete dynamically allocated objects of polymorphic type through pointers to base

class Base {
 public:
    virtual ~Base() { /* releases Base's resources */ }
};
 
class Derived : public Base {
    ~Derived() { /* releases Derived's resources */ }
};
 
int main()
{
    Base* b = new Derived;
    delete b; // Makes a virtual function call to Base::~Base()
              // since it is virtual, it calls Derived::~Derived() which can
              // release resources of the derived class, and then calls
              // Base::~Base() following the usual order of destruction
}
===================
During construction and destruction
When a virtual function is called directly or indirectly from a constructor or from a destructor (including during the construction or destruction of the class’s non-static data members, e.g. in a member initializer list), and the object to which the call applies is the object under construction or destruction, the function called is the final overrider in the constructor’s or destructor’s class and not one overriding it in a more-derived class. In other words, during construction or destruction, the more-derived classes do not exist.

When constructing a complex class with multiple branches, within a constructor that belongs to one branch, polymorphism is restricted to that class and its bases: if it obtains a pointer or reference to a base subobject outside this subhierarchy, and attempts to invoke a virtual function call (e.g. using explicit member access), the behavior is undefined:

struct V {
    virtual void f();
    virtual void g();
};
 
struct A : virtual V {
    virtual void f(); // A::f is the final overrider of V::f in A
};
struct B : virtual V {
    virtual void g(); // B::g is the final overrider of V::g in B
    B(V*, A*);
};
struct D : A, B {
    virtual void f(); // D::f is the final overrider of V::f in D
    virtual void g(); // D::g is the final overrider of V::g in D
 
    // note: A is initialized before B
    D() : B((A*)this, this) 
    {
    }
};
 
// the constructor of B, called from the constructor of D 
B::B(V* v, A* a)
{
    f(); // virtual call to V::f (although D has the final overrider, D doesn't exist)
    g(); // virtual call to B::g, which is the final overrider in B 
 
    v->g(); // v's type V is base of B, virtual call calls B::g as before
 
    a->f(); // a’s type A is not a base of B. it belongs to a different branch of the
            // hierarchy. Attempting a virtual call through that branch causes
            // undefined behavior even though A was already fully constructed in this
            // case (it was constructed before B since it appears before B in the list
            // of the bases of D). In practice, the virtual call to A::f will be
            // attempted using B's virtual member function table, since that's what
            // is active during B's construction)
}
===============================
struct Abstract {
    virtual void f() = 0; // pure virtual
    virtual void g() {}; // non-pure virtual
    ~Abstract() {
        g(); // okay, calls Abstract::g()
        // f(); // undefined behavior!
        Abstract::f(); // okay, non-virtual call
    }
};
 
//definition of the pure virtual function
void Abstract::f() { std::cout << "A::f()\n"; }
 
struct Concrete : Abstract {
    void f() override {
        Abstract::f(); // OK: calls pure virtual function
    }
    void g() override {}
    ~Concrete() {
        g(); // okay, calls Concrete::g()
        f(); // okay, calls Concrete::f()
    }
};
========================================
In detail
All members of a class (bodies of member functions, initializers of member objects, and the entire nested class definitions) have access to all the names to which a class can access. A local class within a member function has access to all the names the member function itself can access.

A class defined with the keyword class has private access for its members and its base classes by default. A class defined with the keyword struct has public access for its members and its base classes by default. A union has public access for its members by default.

To grant access to additional functions or classes to protected or private members, a friendship declaration may be used.

Accessibility applies to all names with no regard to their origin, so a name introduced by a typedef or using declarations is checked, not the name it refers to.

class A : X {
  class B { }; // B is private in A
public:
  typedef B BB; // BB is public
};
void f() {
  A::B y; // error, A::B is private
  A::BB x; // OK, A::BB is public
}
=====================
Member access does not affect visibility: names of private and privately-inherited members are visible and considered by overload resolution, implicit conversions to inaccessible base classes are still considered, etc. Member access check is the last step after any given language construct is interpreted. The intent of this rule is that replacing any private with public never alters the behavior of the program.

Access checking for the names used in default function arguments as well as in the default template parameters is performed at the point of declaration, not at the point of use.

Access rules for the names of virtual functions are checked at the call point using the type of the expression used to denote the object for which the member function is called. The access of the final overrider is ignored.

struct B { virtual int f(); }; // f is public in B
class D : public B { private: int f(); }; // f is private in D
void f() {
 D d;
 B& b = d;
 b.f(); // OK: B::f() is public, D::f() is invoked even though it's private
 d.f(); // error: D::f() is private
}
=====================================
A name that is private according to unqualified name lookup, may be accessible through qualified name lookup:

class A { };
class B : private A { };
class C : public B {
   A* p; // error: unqualified name lookup finds A as the private base of B
   ::A* q; // OK, qualified name lookup finds the namespace-level declaration
};
========================
A name that is accessible through multiple paths in the inheritance graph has the access of the path with the most access:

class W { public: void f(); };
class A : private virtual W { };
class B : public virtual W { };
class C : public A, public B {
void f() { W::f(); } // OK, W is accessible to C through B
};
===========================
When a member is redeclared within the same class, it must do so under the same member access:

struct S {
  class A; // S::A is public
private:
  class A {}; // error: cannot change access
};
=================
Protected member access
Protected members form the interface for the derived classes (which is distinct from the public interface of the class).

A protected member of a class Base can only be accessed

1) by the members and friends of Base
2) by the members and friends (until C++17) of any class derived from Base, but only when operating on an object of a type that is derived from Base (including this)
struct Base {
 protected:
    int i;
 private:
    void g(Base& b, struct Derived& d);
};
 
struct Derived : Base {
    void f(Base& b, Derived& d) // member function of a derived class
    {
        ++d.i; // okay: the type of d is Derived
        ++i; // okay: the type of the implied '*this' is Derived
//      ++b.i; // error: can't access a protected member through Base
    }
};
 
void Base::g(Base& b, Derived& d) // member function of Base
{
    ++i; // okay
    ++b.i; // okay
    ++d.i; // okay
}
 
void x(Base& b, Derived& d) // non-member non-friend
{
//    ++b.i; // error: no access from non-member
//    ++d.i; // error: no access from non-member
}
When a pointer to a protected member is formed, it must use a derived class in its declaration:

struct Base {
 protected:
    int i;
};
 
struct Derived : Base {
    void f()
    {
//      int Base::* ptr = &Base::i;    // error: must name using Derived
        int Base::* ptr = &Derived::i; // okay
    }
};
===================================
 Designates a function or several functions as friends of this class
class Y {
    int data; // private member
    // the non-member function operator<< will have access to Y's private members
    friend std::ostream& operator<<(std::ostream& out, const Y& o);
    friend char* X::foo(int); // members of other classes can be friends too
    friend X::X(char), X::~X(); // constructors and destructors can be friends
};
// friend declaration does not declare a member function
// this operator<< still needs to be defined, as a non-member
std::ostream& operator<<(std::ostream& out, const Y& y)
{
    return out << y.data; // can access private member Y::data
}
=============================
Notes
Friendship is not transitive (a friend of your friend is not your friend)

Friendship is not inherited (your friend's children are not your friends)

Prior to C++11, member declarations and definitions inside the nested class of the friend of class T cannot access the private and protected members of class T, but some compilers accept it even in pre-C++11 mode.

Storage class specifiers are not allowed in friend function declarations. A function that is defined in the friend declaration has external linkage, a function that was previously defined, keeps the linkage it was defined with.

Access specifiers have no effect on the meaning of friend declarations (they can appear in private: or in public: sections, with no difference)

A friend class declaration cannot define a new class (friend class X {}; is an error)

When a local class declares an unqualified function or class as a friend, only functions and classes in the innermost non-class scope are looked up, not the global functions:

class F {};
int f();
int main()
{
    extern int g();
    class Local { // Local class in the main() function
        friend int f(); // Error, no such function declared in main()
        friend int g(); // OK, there is a declaration for g in main()
        friend class F; // friends a local F (defined later)
        friend class ::F; // friends the global F
    };
    class F {}; // local F
}
A name first declared in a friend declaration within class or class template X becomes a member of the innermost enclosing namespace of X, but is not accessible for lookup (except argument-dependent lookup that considers X) unless a matching declaration at the namespace scope is provided - see namespaces for details.


============================
When a friend declaration refers to a full specialization of a function template, the keyword inline and default arguments cannot be used.

template<class T> void f(int);
template<> void f<int>(int);
 
class X {
    friend void f<int>(int x = 1); // error: default args not allowed
};
=========================
When a friend declaration refers to a full specialization of a function template, the keyword inline and default arguments cannot be used.

template<class T> void f(int);
template<> void f<int>(int);
 
class X {
    friend void f<int>(int x = 1); // error: default args not allowed
};
====================
If a member of a class template A is declared to be a friend of a non-template class B, the corresponding member of every specialization of A becomes a friend of B. If A is explicitly specialized, as long as there is a member of the same name, same kind (type, function, class template, function template), same parameters/signature, it will be a friend of B.

template<typename T> // primary template
struct A
{
    struct C {};
    void f();
    struct D {
        void g();
    };
};
 
template<> // full specialization
struct A<int>
{
    struct C {};
    int f();
    struct D {
        void g();
    };
};
 
class B // non-template class
{
    template<class T>
    friend struct A<T>::C; // A<int>::C is a friend, as well as all A<T>::C
 
    template<class T>
    friend void A<T>::f(); // A<int>::f() is not a friend, because the
                           // signatures do not match, but A<char>::f() is
 
    template<class T>
    friend void A<T>::D::g(); // A<int>::D::g() is not a friend: it is not a member
                              // of A, and A<int>::D is not a specialization of A<T>::D
};
=============================
#include <iostream>
 
template<typename T>
class Foo; // forward declare to make function declaration possible
 
template<typename T> // declaration
std::ostream& operator<<(std::ostream&, const Foo<T>&);
 
template<typename T>
class Foo {
 public:
    Foo(const T& val) : data(val) {}
 private:
    T data;
 
    // refers to a full specialization for this particular T 
    friend std::ostream& operator<< <> (std::ostream&, const Foo&);
    // note: this relies on template argument deduction in declarations
    // can also specify the template argument with operator<< <T>"
};
 
// definition
template<typename T>
std::ostream& operator<<(std::ostream& os, const Foo<T>& obj)
{
    return os << obj.data;
}
 
int main()
{
    Foo<double> obj(1.23);
    std::cout << obj << '\n';
}
=================================
#include <iostream>
struct S {
    // will usually occupy 2 bytes:
    // 3 bits: value of b1
    // 5 bits: unused
    // 6 bits: value of b2
    // 2 bits: value of b3
    unsigned char b1 : 3;
    unsigned char :0; // start a new byte
    unsigned char b2 : 6;
    unsigned char b3 : 2;
};
int main()
{
    std::cout << sizeof(S) << '\n'; // usually prints 2
=============================
If the specified size of the bit field is greater than the size of its type, the value is limited by the type: a std::uint8_t b : 1000; would still hold values between 0 and 255. the extra bits become unused padding.

Because bit fields do not necessarily begin at the beginning of a byte, address of a bit field cannot be taken. Pointers and non-const references to bit fields are not possible. When initializing a const reference from a bit field, a temporary is created (its type is the type of the bit field), copy initialized with the value of the bit field, and the reference is bound to that temporary.

The type of a bit field can only be integral or enumeration type.

A bit field cannot be a static data member.

There are no bit field prvalues: lvalue-to-rvalue conversion always produces an object of the underlying type of the bit field.

Notes
There are no default member initializers for bit fields: int b : 1 = 0; and int b : 1 {0} are ill-formed.

The following properties of bit fields are implementation-defined

The value that results from assigning or initializing a signed bit field with a value out of range, or from incrementing a signed bit field past its range.
Everything about the actual allocation details of bit fields within the class object
For example, on some platforms, bit fields don't straddle bytes, on others they do
Also, on some platforms, bit fields are packed left-to-right, on others right-to-left
===================================
constructors
===========
struct A {
    A() : v(42) { }  // Error
    const int& v;
};
==================
struct A {
    A() : v(42) { }  // Error
    const int& v;
};
=============================
#include <iostream>
 
struct A
{
    int i;
 
    A ( int i ) : i ( i ) {}
 
    ~A()
    {
        std::cout << "~a" << i << std::endl;
    }
};
 
int main()
{
    A a1(1);
    A* p;
 
    { // nested scope
        A a2(2);
        p = new A(3);
    } // a2 out of scope
 
    delete p; // calls the destructor of a3
}
Output:

~a2
~a3
~a1
====================
