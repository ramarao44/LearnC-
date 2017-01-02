Deque
======
For operations that involve frequent insertion or removals of elements at positions other than the beginning or the end, 
deques perform worse and have less consistent iterators and references than lists and forward lists.
Container properties
Sequence
Elements in sequence containers are ordered in a strict linear sequence. Individual elements are accessed by their position in this sequence.
Dynamic array
Generally implemented as a dynamic array, it allows direct access to any element in the sequence and provides relatively fast addition/removal of elements at the beginning or the end of the sequence.
Allocator-aware
The container uses an allocator object to dynamically handle its storage needs.
 they provide a functionality similar to vectors, but with efficient insertion and deletion of elements also at 
 the beginning of the sequence, and not only at its end. But, unlike vectors, deques are not guaranteed to store all its elements in contiguous storage locations:
 accessing elements in a deque by offsetting a pointer to another element causes undefined behavior.
 Insert elements
The deque container is extended by inserting new elements before the element at the specified position.

This effectively increases the container size by the amount of elements inserted.

Double-ended queues are designed to be efficient performing insertions (and removals) from either the end or
the beginning of the sequence. Insertions on other positions are usually less efficient than in list or forward_list containers.
=================
list
=====
List
Lists are sequence containers that allow constant time insert and erase operations anywhere within the sequence, and iteration in both directions.

List containers are implemented as doubly-linked lists; Doubly linked lists can store each of the elements they contain in different and unrelated storage locations. The ordering is kept internally by the association to each element of a link to the element preceding it and a link to the element following it.

They are very similar to forward_list: The main difference being that forward_list objects are single-linked lists, and thus they can only be iterated forwards, in exchange for being somewhat smaller and more efficient.

Compared to other base standard sequence containers (array, vector and deque), lists perform generally better in inserting, extracting and moving elements in any position within the container for which an iterator has already been obtained, and therefore also in algorithms that make intensive use of these, like sorting algorithms.

The main drawback of lists and forward_lists compared to these other sequence containers is that they lack direct access to 
the elements by their position; For example, to access the sixth element in a list, one has to iterate from a known
position (like the beginning or the end) to that position, which takes linear time in the distance between these. They also consume some extra memory to keep the linking information associated to each element (which may be an important factor for large lists of small-sized elements).

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
