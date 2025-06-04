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

The Precedence Climbing algorithm is one way, the simplest in my opinion, of handling infix expressions. I will assume we are trying to evaluate a numerical expression for a more straightforward description, but the algorithm's "output" can easily be something else like a parse tree.

The basic idea is this: 

1. We take the first number in the expression and place a bookmark after the number.
2. If we are now at the end of the expression, we return the number we have and that is our final calculation.
3. Otherwise: we walk through the remaining part of the expression from left to right until we find an operator with lower or equal precedence to the one just before it and place a bookmark just before that operator.
4. We evaluate the part of the expression between the bookmarks, starting from the rightmost bookmark from step 3. (It is important to start the calculation from the rightmost bookmark because we only advance through the expression if there is higher precedence.)
5. We feed our calculated-so-far number back into step 2 starting from the rightmost bookmark, and repeat step 2 - 4 until the whole expression is consumed.

There are two things to keep in mind not explicitly stated in the previous steps:

- In step 3, we look for an operator with lower or equal precedence to the operator just before it. However, this is only if the latest operator is left-associative. If the operator we are comparing with is right-associative, we still continue if the next operator has equal precedence.
- In our first walk through the expression at step 3, we accept any operator at all because there is no previous operator for us to compare with. We also accept any operator at all when reach step 5 which instructs us to go to step 2.

Finally, the above rules don't consider parenthesised sub-expressions like `1 - (2 - 3)`. I'm trying not to get too technical, but two ways to handle parenthesised expressions are:

1. Encode parenthesised expressions in our grammar with a rule like `exp ::= (exp)`
2. Start an "inner" precedence climbing algorithm through recursion after the first `(`, and skip past the matching `)` in the outer algorithm once the inner algorithm finishes, treating the whole sub-expression as one unit.

I personally prefer the first approach when writing a recursive descent parser for a programming language because the precedence climbing algorithm doesn't need to concern itself with parenthesised expression, but if my goal is to build a calculator, I will go with the second approach as a calculator does not really need a BNF or a formal grammar.

That explanation might be a lot to take in from one's first encounter with the algorithm, but going through some examples will help illustrate the idea.

To help with that, I built a visualisation tool that lets you input a numerical expression and walks through the steps of calculating it using this algorithm.

Here is the link: {to do: create the tool}
