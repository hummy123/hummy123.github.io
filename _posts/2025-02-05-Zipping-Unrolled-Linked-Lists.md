## Zipping Unrolled Linked Lists

Since October 2024, I've been slowly working on a text editor project similar to Vi/Vim using Standard ML, and one of the first choices I had to make was about the particular data structure to use.

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

![Diagram of showing that arrays are in contiguous memory, linked lists are scattered over memory with pointers to the next element, and unrolled linked lists use a mix of having some elements stored contiguously like arrays while having others scattered in meemory like linked lists](https://github.com/hummy123/hummy123.github.io/blob/main/docs/assets/array-linked-list-unrolled-linked-list.png?raw=true)

- The array is contiguous in memory, not needing pointers to indicate the next element
- The linked list is scattered in memory, needing pointers to indicate the next element
- The unrolled linked list is a mix of the two: the nodes of the linked list contain an array with contiguous memory but the next node is indicated by a pointer like a normal linked list

If we want to insert an element into the middle of a node, say 2.5, we have to check if the array is at the max capacity we impose on it. If it is, we split this array into two arrays and link them as required, as shown in the below diagram.

Such splitting only occurs when an insertion would cause us to exceed the maximum length. In the default case, we would insert in the same way standard arrays do: shifting the necessary elements rightwards by one and placing our new element in the gap. This is fast because of our maximum limit on the array.

![To insert 2.5 into a full node containing "1,2,3", we split the full node into two nodes, and randomly choose to insert 2.5 into any one of the split nodes.](https://github.com/hummy123/hummy123.github.io/blob/main/docs/assets/splitting-unrolled-linked-list.png?raw=true)

This approach does the trick in providing a better balance between arrays and linked lists.

- If we want to `remove from` or `add to` the start or middle of any node, because there are fewer elements in the array contained at this node, the constant is significantly lower than a standard array so it takes less time
- If we want to add a new node containing '0' or '10', then that takes constant time like a normal linked list (assuming we have travelled to the place we want to insert to)

However, there is a notable weakness in traversal. Imagine we had 100 elements in our unrolled linked list and we wanted to do many operations at the end.

Although the traversal time is better than a standard linked list (there are fewer pointers to chase because each node contains many elements), it still involves a fair amount of time to get to the end, and this is bad if we want to reach the end repeatedly.

What can we do to alleviate this problem?

### The List Zipper

A zipper is a general way to "save the context" or "save a specific position" in a data structure. We will only concern ourselves with zippers on linked lists as other kinds of zippers are not relevant.

The list zipper is simple conceptually and  can generally be visualised as two stacks as below.

![A list zipper represented as two stacks: one left stack containing "hello" and a right stack containing "world"](https://github.com/hummy123/hummy123.github.io/blob/main/docs/assets/initial-zipper.png?raw=true)

Notice how the left stack spells "hello" when read from the bottom to the top, from the "h" at the bottom to the "o" at the top of the stack. This is different from the right stack which is read from top to bottom, with the "w" at the top and the "d" at the bottom.

In pure textual form, the left stack would be: `["o", "l", "l", "e", "h"]` and the right stack would be `["w", "o", "r", "l", "d"]`.

This unintuitive-at-first representation helps us move the cursor efficiently.

To move rightwards one character, we just need to do a couple of operations that take constant time:

- Pop the "w" off the right stack
- Push the "w" onto the left stack

We can move our cursor rightwards by popping the top element off from the right stack and pushing it onto the left stack.

![We can move rightwards in the zipper by popping the top element from the right stack and pushing it onto the left stack](https://github.com/hummy123/hummy123.github.io/blob/main/docs/assets/zipper-move-right.png?raw=true)

If we want to move leftwards, we perform the inverse: pop the top element off the left stack and push it onto the right stack. 

Inserting or removing text is simple. Both first involve traversing to the desired point first. After that, removal simply involves popping an element off the relevant stack, while insertion involves pushin an element on either stack.

The list zipper is basically a doubly linked list except immutable, and with lower storage overheadc as each node has one pointer to the next node instead of two.

It's fair to note that traversal time has improved. While it is still O(n) in the worst case, when one stack is empty and all of the elements are on the other side, it is usually the case that we are closer to the middle rather than the far end, and this helps bring down the traversal time by a constant factor.

In other words, a linked list traverses by chasing pointers after each element. To get from 1 to 5, the chain would be `1 -> 2 -> 3 -> 4 -> 5`. That's four pointer chases.

An unrolled linked list can traverse more quickly because there are fewer pointers to chase. To get from 1 to 5, the chain would be `[1, 2, 3] -> [4, 5]` which is just one pointer traversal from the first array node to the next. The constant factor is lower.

### The Zipped and Unrolled Linked List

We can put together the two previous ideas, combining unrolled linked lists with zippers, for a surprisingly simple and efficient data structure.

![An unrolled linked list contains a left stack and a right stack like a list zipper, and the elements of the stack are array nodes like an unrolled linked list](https://github.com/hummy123/hummy123.github.io/blob/main/docs/assets/unrolled-list-zipper.png?raw=true)

Each word is its own linked list node for readability in the diagram, but we want to set a maximum length to our array nodes in practice. If inserting an element would cause us to exceed the maximum length, we split the array off into two and put one array on the left stack and the other on the right stack.

This guiding principle, "maximise the length of the array node until we reach some limit", is key for getting good performance out of the structure.

If we set too high of a limit, our data structure will degenerate into a simple array. If we set too low of a limit, it will degenerate into a plain old linked list.

The best way to find a good limit is to measure, of course. If we are dealing with UTF-8 strings, I've found in practice that 1024 characters is a good limit. 

If we're dealing with some other type, we will likely want a lower limit. UTF-8 chars take just one byte, which means we can fit a higher number of chars in the same block of memory compared to 32-bit integers. There's less copying involved.

The zipper has been described as conceptually being a generalisation of the Gap Buffer, so I usually refer to the resulting data structure as a Gap Buffer too.

### How does it perform?

I normally code in Standard ML for hobby projects these days, and have a good implementation of both Ropes and a Gap Buffers. We can run the data structures against [the real-life recordings of editing traces helpfully shared by Joseph Gentle](https://github.com/josephg/editing-traces).

These datasets record how people typed out a given piece of text in practice, the sequence of insertions and deletions to go from a blank document to the final text. They're a good way to measure real life performance for text editing (although they notably don't test retrieval time which involves getting the words to display on the screen).

| Dataset | Mean [ms] | Min [ms] | Max [ms] | Relative |
|:---|---:|---:|---:|---:|
| svelte_component [Gap Buffer] | 2.4 ± 0.9 | 1.1 | 6.0 | 1.00 |
| svelte_component [Rope] | 5.3 ± 1.7 | 2.7 | 10.8 | 2.19 ± 1.07 |
| rustcode [Gap Buffer] | 5.2 ± 1.6 | 2.9 | 10.5 | 1.00 |
| rustcode [Rope] | 19.7 ± 3.0 | 10.8 | 26.9 | 3.82 ± 1.33 |
| seph-blog1 [Gap Buffer] | 12.9 ± 3.3 | 7.1 | 19.7 | 1.00 |
| seph-blog1 [Rope] | 33.7 ± 7.0 | 19.0 | 46.4 | 2.60 ± 0.86 |
| automerge-paper [Gap Buffer] | 24.0 ± 4.0 | 16.6 | 32.4 | 1.00 |
| automerge-paper [Rope] | 56.8 ± 11.8 | 39.1 | 74.0 | 2.36 ± 0.63 |

These edit traces measure how long the data structure takes to perform all of the insertion and deletion operations to complete a given text document: two code files, one blog post, and an academic paper.

Both data structures are far faster than necessary: they are on the order of milliseconds for completing texts that took a longer stretch of time (hours, days, weeks) to type out. The performance game is still fun though, and we have time for other compute-intensive tasks because of it.

We can see here that the Gap Buffer is, on these traces, at least twice as fast as the Rope. In one case, it is approximately 4x faster.

These benchmark results are reproducible and can be run by installing the hyperfine benchmarking tool, going to the `bench` folder in [brolib-sml](https://github.com/hummy123/brolib-sml/tree/main/bench) and entering `make` in the terminal.

One might wonder if the Rope is a bad implementation for these comparisons. It might not be the fastest implementation of a Rope (that award probably goes to libraries written in C or Rust), but I implemented [the same Rope in OCaml](https://github.com/hummy123/brolib) before.

In that ecosystem, it massively outperformed all of the competing and comparable data structures I could find, where this Rope was often more than 10x faster than two other Rope implementations (one in the [ocaml-bazaar repository](https://github.com/backtracking/ocaml-bazaar) and [zed](https://github.com/ocaml-community/zed) which is often the community's first choice and not to be confused by the Zed editor written in Rust). It is also often 10x faster than my own [OCaml "piecerope" implementation](https://github.com/hummy123/ocaml-piecerope) which was an attempt to combine VS Code style "Piece Trees" with the Rope (mostly sticking to the Piece Tree side of things).

So, it's a pretty good Rope. That criticism doesn't hold water.

There is also the [latency argument](https://news.ycombinator.com/item?id=37821854). Because the Gap Buffer (including traditional mutable Gap Buffers) has constant-time operations where the cursor is but worst case O(n) operations when moving the from one node to the next, the user might perceive lag during individual operations, even though the total time taken for all operations is technically faster.

This is a valid argument as Gap Buffers have two slow operations: resizing the gap when it gets full (copying all the string contents into a larger buffer) and traversing/moving the cursor. The first source of latency is not really a problem with unrolled linked lists because every node is small enough to make copying cheap: there is no need to copy everything. 

However, the second problem still persists. In practice, I've found the variance for operations on unrolled linked lists to often be no worse than 5 milliseconds than the same operation for Ropes (and even that is rare). 

I'm quite happy sticking with the unrolled linked list as my data structure of choice. It might not be as asymptotically optimal as other structures, but it will often perform better in practice.

### Other uses of Gap Buffers

The Gap Buffer is usually considered a data structure for manipulating text, but there is no reason that has to be the case: you can insert anything into the array instead.

The Jetpack Compose team has [used the structure to good effect](https://medium.com/androiddevelopers/under-the-hood-of-jetpack-compose-part-2-of-2-37b2c20c6cdd) for storing widget/component state, as an alternative to an array but with better support for inserting in the middle or the start.

I've used them as an alternative to a set data structure in my text editor, where they perform well for keeping track of "matching indices" when performing find-and-replace operations. They work well there (although I might consider other data structures at some point - there is some level of incrementality currently, but the matched indices will need to change as the text changes, requiring  all indices after the insert/deletion to be changed as well - maybe a Fenwick tree of some kind would be better). 

They are probably not suited for some of the fancier set operations (intersection, difference) but they work well for insertion, removal, and membership (testing existence of an element) operations. They work just as well for maps (a collection of key-value pairs) as they do for sets.

The most natural competing data structure might be [Clojure's persistent Vectors](https://hypirion.com/musings/understanding-persistent-vector-pt-1). Rich Hickey has developed a very fast vector supporting the following operations in close-to-constant (actually O(log n)) time: append-to-end, remove-last-element, update-at-index and get-at-index.

These operations on Clojure's vectors perform better in the worst case than for unrolled linked lists, but worse in cases where many edits are made in neighbouring places in an unrolled linked list. The unrolled linked list also supports more operations: insert or remove at any point in the structure and not just the end.

As an improvement to Clojure's persistent vectors, there is the [Relaxed Radix Balanced Tree](https://peter.horne-khan.com/relaxed-radix-balanced-trees/) which attains support for more operations (insert and remove at any point, as well as merging two trees together). It is more complex than an unrolled linked list conceptually, but it may be a winner. I would like to try implementing it some day.
