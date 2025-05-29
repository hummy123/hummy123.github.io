## Parsing Infix Expressions and Precedence Climbing

Have you ever given much thought to the order-of-operations (described by acronyms like BODMAS and PEMDAS) that we always remember when performing arithematic? Why this particular order instead of a different one where, for example, addition is done before multiplication?

Sadly, there is nothing special about the order of operations. It has nothing to do with maths itself and everything to do with humans writing maths.

For example, given the expression `1 + 2 * 3`, we must define some order of operations for the operators, or we won't agree on what it means and how to calculate it.

The notation I just used in the expression `1 + 2 * 3` is also just a human convention, where a mathematical operator has one number to the left and one number to the right. There are other conventions (like Reverse Polish Notation where we would write `1 + 2` as `1 2 +`) but this is the most common. We might call it infix notation.

Infix notation is particularly interesting on this blog about coding because it is a bit more challenging for computers to calculate than other competing notations. There are two additional concepts we require in infix notation: **precedence** and **associativity**.

### Precedence and Associativity

Precedence is simply the order of operations we have defined. For example, `*` and `/` have higher precedence than `+` and `-`. We perform those operations which have higher precedence first. Brackets may be used to override precedence and force a specific calculation order.

Mathematical associativity is the property of some operators that we get the same result regardless of which order the numbers are in. For example, `1 + 2 + 3` is the same as `3 + 2 + 1` and `1 * 2 * 3` is the same as `3 * 2 * 1`. However, not every operator is associative: `1 - 2 - 3` gives a different result from `3 - 2 - 1`, and division also gives us a different result.

Mathematical associativity has some nice properties, but it's not the type of associativity we are concerned with in calculating infix expressions on a computer. We are only concerned with how "associativity" is defined in Computer Science for now.

In Computer Science, every infix operator is said to be either left associative or right associative. What this means is, in an expression where an operator is repeated, do we apply that operator to the numbers on the left first or to the numbers on the right?

For example, we can consider `1 - 3 - 5 - 7` and `1 ^ 3 ^ 5 ^ 7` (where `^` means `to the power of`). How would we put brackets around these expressions to make it clear?

For subtraction, we would write `((1 - 3) - 5) - 7`. Subtraction is said to be left associative because we calculate the left side first.

For exponentiation, we would write `1 ^ (3 ^ (5 ^ 7))`. The power operator is said to be right associative because we calculate the right side first.

The main factor determining the order of operations is precedence, but the associativity of an operator tells us how to perform the calculation when we have two adjacent operators which have the same precedence (like `+` and `-`).

### The Precedence Climbing Algorithm

The Precedence Climbing algorithm is one way, the simplest in my opinion, of handling infix expressions.

The basic idea is this: 

1. We take the first number in the expression and bookmark our position.
2. We walk through the remaining part of the expression from left to right until we find an operator with lower or equal precedence to the one just before it.
3. We perform some action (like calculating a number or creating a parse tree) from the point we finished at in step 2, up to the point we started at before step 2.
4. We repeat steps 2 and 3 until we have walked through the entire expression.

Let's look at some examples to better understand this.

**1 + 3 + 5**

1. We take the first number, leaving us with the the partial expression `+ 3 + 5`.
2. We look at the next operator `+`, the next number `3`, and the operator after `3` which is `+` again.
3. The precedence of the first and second operator are equal so we 
4. We look at the next operator `+` and the next number `5`.
5. Seeing that there are no more operators
