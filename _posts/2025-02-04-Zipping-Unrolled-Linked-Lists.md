## Zipping Unrolled Linked Lists

Sicne October 2024, I've been slowly working on a text editor project similar to Vi/Vim using Standard ML, and one of the first choices I had to make was about the particular data structure to use.

The three data structures most commonly used for such a purpose are:

- [Ropes](https://en.wikipedia.org/wiki/Rope_(data_structure)), built on balanced trees
- [Piece Tables](http://1017.songtrellisopml.com/whatsbeenwroughtusingpiecetables), containing an append-only string and a list of 'piece' objects
- [Gap Buffers](https://scienceblogs.com/goodmath/2009/02/18/gap-buffers-or-why-bother-with-1), a simple array of characters with a "gap" (null or junk characters) where the caret is, resizing as the user types text

I've implemented each of these (and variations of the three) as part of deciding which to use, and found the Gap Buffer to be my favourite for its conceptual simplicity and performance characteristics.

However, I had to make some modifications to make it fit a functional language since Gap Buffers traditionally rely on mutability.  In doing so, I've made a different set of trade-offs from those commonly associated with the structure, and I think those trade-offs are worth documenting.

Let's back up a bit and go over simpler data structures which explain how this one came about.

### The Unrolled Linked List: Between Arrays and Linked Lists

In the first year of most Computer Science courses, students are taught about the difference between arrays and linked lists, and the differing performance characteristics of each.

An array is data contiguous in memory, without any gaps. An array offers constant time O(1) access to its elements which makes it a great option for reading data. They also allow updating a single element, or popping the last element, in constant time too.

Dynamic arrays (offered by many imperative languages like C++/C#/Java but notably not C) allow adding a new element to the end of an array in amortised constant time: the operation is usually constant time, but on occasion, the array reaches its capacity and has to be copied into a newer, larger array.

The other troubling operation with arrays that makes them a subpar choice for some situations is that inserting or removing an element from the beginning or middle can take O(n) time as the elements need to be moved around.

In contrast, the linked list is implemented using pointers rather than using contiguous memory like arrays do. They have different characteristics because of this: linked lists perform badly for those operations which arrays excel at, and excel at those operations which arrays do comparatively badly at.

To be specific, the linked list offers insertion, removal and update in constant time for any node in the list once that node has been traversed to. However, traversing to the node itself takes O(n) time in the worst case, which is much worse than with arrays.

That;s the basic analysis on the performance characteristics of arrays and linked lists which any first year Computer Science student should be familiar with.

It makes sense for programmers to want a third data structure which provides good performance for all of these operations, perhaps sacrificing the best case of both to provide a more balanced runtime which is not the best at any operation but is good at all of them. 

One such data structure is the unrolled linked list, which is a linked list containing arrays, where those arrays have some maximum length.

The below diagram illustrates how each of the three data structures are represented in memory.

(todo: insert diagram)

- The array is contiguous in memory, not needing pointers to indicate the next element
- The linked list is scattered in memory, needing pointers to indicate the next element
- The unrolled linked list is a mix of the two: the nodes of the linked list contain an array with contiguous memory but the next node is indicated by a pointer like a normal linked list

If we want to insert an element into the middle of a node, say 2.5, we have to check if the array is at the max capacity we impose on it. If it is, we split this array into two arrays and link them as required, as shown in the below diagram.

(todo: insert diagram)

This approach does the trick in providing a better balance between arrays and linked lists.

- If we want to (remove or add to) the start or middle of any node, because there are fewer elements in the array contained at this node, the constant is significantly lower than a standard array so it takes less time
- If we want to add a new node containing '0' or '10', then that takes constant time like a normal linked list (assuming we have travelled to the place we want to insert to)

However, there is a glaring weakness in traversal. Imagine we had 100 elements in our unrolled linked list and we wanted to do many operations at the end.

Although the traversal time is better than a standard linked list (there are fewer pointers to chase because each node contains many elements), it still involves a fair amount of time to get to the end, and this is bad if we want to reach the end repeatedly.

What can we do to alleviate this problem?

### The List Zipper

A zipper is a general way to "save a specific position" in a data structure. We will only concern ourselves with zippers on linked lists as other kinds of zippers are not relevant.


