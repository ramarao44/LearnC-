Deque
======
For operations that involve frequent insertion or removals of elements at positions other than the beginning or the end, 
deques perform worse and have less consistent iterators and references than lists and forward lists.
Container properties
Sequence
Elements in sequence containers are ordered in a strict linear sequence. Individual elements are accessed by
their position in this sequence.
Dynamic array
Generally implemented as a dynamic array, it allows direct access to any element in the sequence and provides 
relatively fast addition/removal of elements at the beginning or the end of the sequence.
Allocator-aware
The container uses an allocator object to dynamically handle its storage needs.
 they provide a functionality similar to vectors, but with efficient insertion and deletion of elements also at 
 the beginning of the sequence, and not only at its end. But, unlike vectors, deques are not guaranteed to 
 store all its elements in contiguous storage locations:
 accessing elements in a deque by offsetting a pointer to another element causes undefined behavior.
 Insert elements
The deque container is extended by inserting new elements before the element at the specified position.

This effectively increases the container size by the amount of elements inserted.

Double-ended queues are designed to be efficient performing insertions (and removals) from either the end or
the beginning of the sequence. Insertions on other positions are usually less efficient 
than in list or forward_list containers.
=================
list
=====
Lists are sequence containers that allow constant time insert and erase operations anywhere within the sequence, 
and iteration in both directions.

List containers are implemented as doubly-linked lists; Doubly linked lists can store each of the elements they contain 
in different and unrelated storage locations. The ordering is kept internally by the association to each element of a 
link to the element preceding it and a link to the element following it.

They are very similar to forward_list: The main difference being that forward_list objects are single-linked lists,
and thus they can only be iterated forwards, in exchange for being somewhat smaller and more efficient.

Compared to other base standard sequence containers (array, vector and deque), lists perform generally better in inserting, 
extracting and moving elements in any position within the container for which an iterator has already been obtained, 
and therefore also in algorithms that make intensive use of these, like sorting algorithms.

The main drawback of lists and forward_lists compared to these other sequence containers is that they lack direct access to 
the elements by their position; For example, to access the sixth element in a list, one has to iterate from a known
position (like the beginning or the end) to that position, which takes linear time in the distance between these. 
They also consume some extra memory to keep the linking information associated to each element
(which may be an important factor for large lists of small-sized elements).

lis provides additional functionalities compared to deque
which are
=========
remove,splice,unique
===================
Map
=======
Container properties
Associative
Elements in associative containers are referenced by their key and not by their absolute position in the container.
Ordered
The elements in the container follow a strict order at all times. All inserted elements are given a position in this order.
Map
Each element associates a key to a mapped value: Keys are meant to identify the elements whose main content is the mapped value.
Unique keys
No two elements in the container can have equivalent keys.
Allocator-aware
The container uses an allocator object to dynamically handle its storage needs.
=====
queue
=====
template <class T, class Container = deque<T> > class queue;
FIFO queue
queues are a type of container adaptor, specifically designed to operate in a FIFO context (first-in first-out), 
where elements are inserted into one end of the container and extracted from the other.

queues are implemented as containers adaptors, which are classes that use an encapsulated object of a specific 
container class as its underlying container, providing a specific set of member functions to access its elements. 
Elements are pushed into the "back" of the specific container and popped from its "front".

The underlying container may be one of the standard container class template or some other specifically designed container 
class. This underlying container shall support at least the following operations:
empty
size
front
back
push_back
pop_front

The standard container classes deque and list fulfill these requirements. By default, 
if no container class is specified for a particular queue class instantiation, 
the standard container deque is used.
==================
set
=============
Set
Sets are containers that store unique elements following a specific order.

In a set, the value of an element also identifies it (the value is itself the key, of type T), and each value must be unique. The value of the elements in a set cannot
be modified once in the container (the elements are always const), but they can be inserted or removed from the container.

Internally, the elements in a set are always sorted following a specific strict weak ordering criterion indicated by 
its internal comparison object (of type Compare).

set containers are generally slower than unordered_set containers to access individual elements by their key, 
but they allow the direct iteration on subsets based on their order.

Sets are typically implemented as binary search trees.

==========
multiset
==========
Multiple-key set
Multisets are containers that store elements following a specific order, and where multiple elements can have equivalent 
values.

In a multiset, the value of an element also identifies it (the value is itself the key, of type T). The value of the elements
in a multiset cannot be modified once in the container (the elements are always const), but they can be inserted or 
removed from the container.

Internally, the elements in a multiset are always sorted following a specific strict weak ordering criterion indicated 
by its internal comparison object (of type Compare).

multiset containers are generally slower than unordered_multiset containers to access individual elements by 
their key, but they allow the direct iteration on subsets based on their order.

Multisets are typically implemented as binary search trees.
====================
vector
==========
Vector
Vectors are sequence containers representing arrays that can change in size.

Just like arrays, vectors use contiguous storage locations for their elements, which means that their elements can also 
be accessed using offsets on regular pointers to its elements, and just as efficiently as in arrays. 
But unlike arrays, their size can change dynamically, with their storage being handled automatically by the container.

Internally, vectors use a dynamically allocated array to store their elements. This array may need to be reallocated 
in order to grow in size when new elements are inserted, which implies allocating a new array and moving all elements to it.
This is a relatively expensive task in terms of processing time, and thus, vectors do not reallocate each time an element
is added to the container.

Instead, vector containers may allocate some extra storage to accommodate for possible growth, and thus the container
may have an actual capacity greater than the storage strictly needed to contain its elements (i.e., its size).
Libraries can implement different strategies for growth to balance between memory usage and reallocations, 
but in any case, reallocations should only happen at logarithmically growing intervals of
size so that the insertion of individual elements at the end of the vector can be provided with amortized 
constant time complexity (see push_back).

Therefore, compared to arrays, vectors consume more memory in exchange for the ability to manage storage
and grow dynamically in an efficient way.

Compared to the other dynamic sequence containers (deques, lists and forward_lists), 
vectors are very efficient accessing its elements (just like arrays) and relatively efficient adding or removing elements
from its end. For operations that involve inserting or removing elements at positions other than the end, 
they perform worse than the others, and have less consistent iterators and references than lists and forward_lists.
=================
iterator
========
Iterators are classified into five categories depending on the functionality they implement:

Input
Output
Forward
Bidirectional
Random Access

Input and output iterators are the most limited types of iterators: they can perform sequential single-
pass input or output operations.

Forward iterators have all the functionality of input iterators and -if they are not constant iterators- 
also the functionality of output iterators,
although they are limited to one direction in which to iterate through a range (forward).
All standard containers support at least forward iterator types.

Bidirectional iterators are like forward iterators but can also be iterated through backwards.

Random-access iterators implement all the functionality of bidirectional iterators, and also have the ability to 
access ranges non-sequentially: distant elements can be accessed directly by applying an offset value to an iterator 
without iterating through all the elements in between. These iterators have a similar functionality to standard pointers 
(pointers are iterators of this category).
==============================
dynamic cast
============
When dynamic_cast cannot cast a pointer because it is not a complete object of the required class -
as in the second conversion in the previous example- it returns a null pointer to indicate the failure.
If dynamic_cast is used to convert to a reference type and the conversion is not possible, 
an exception of type bad_cast is thrown instead.

dynamic_cast can also perform the other implicit casts allowed on pointers: casting null pointers between pointers types
(even between unrelated classes), and casting any pointer of any type to a void* pointer.

============
static cast
===========
static_cast can perform conversions between pointers to related classes, not only upcasts 
(from pointer-to-derived to pointer-to-base), but also downcasts (from pointer-to-base to pointer-to-derived).
No checks are performed during runtime to guarantee that the object being converted is in fact a full object of 
the destination type. Therefore, it is up to the programmer to ensure that the conversion is safe. 
On the other side, it does not incur the overhead of the type-safety checks of dynamic_cast.

1
2
3
4
class Base {};
class Derived: public Base {};
Base * a = new Base;
Derived * b = static_cast<Derived*>(a);
=====================

static_cast is also able to perform all conversions allowed implicitly (not only those with pointers to classes),
and is also able to perform the opposite of these. It can:
Convert from void* to any pointer type. In this case, it guarantees that if the void* value was obtained by converting 
from that same pointer type, the resulting pointer value is the same.
Convert integers, floating-point values and enum types to enum types.

Additionally, static_cast can also perform the following:
Explicitly call a single-argument constructor or a conversion operator.
Convert to rvalue references.
Convert enum class values into integers or floating-point values.
Convert any type to void, evaluating and discarding the value
============
reinterpret cast
================
reinterpret_cast converts any pointer type to any other pointer type, even of unrelated classes. 
The operation result is a simple binary copy of the value from one pointer to the other. 
All pointer conversions are allowed: neither the content pointed nor the pointer type itself is checked.

It can also cast pointers to or from integer types. The format in which this integer value represents a pointer 
is platform-specific. The only guarantee is that a pointer cast to an integer type large enough to fully contain 
it (such as intptr_t), is guaranteed to be able to be cast back to a valid pointer.

The conversions that can be performed by reinterpret_cast but not by static_cast are low-level operations based on 
reinterpreting the binary representations of the types, which on most cases results in code which is system-specific,
and thus non-portable. For example:

1
2
3
4
class A { /* ... */ };
class B { /* ... */ };
A * a = new A;
B * b = reinterpret_cast<B*>(a);


This code compiles, although it does not make much sense, since now b points to an object of a totally unrelated and 
likely incompatible class. Dereferencing b is unsafe.

