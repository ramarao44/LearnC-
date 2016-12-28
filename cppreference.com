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

