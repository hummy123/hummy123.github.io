## State management for GUI frameworks

GUI frameworks have their own state to manage, separately from the application built on the framework.

This post will not be concerned with the state for drawing widgets (textures, vertex buffers or what have you) but with the behavioural state of a widget independent from that.

For example, a framework needs to record state about each and every button: is the mouse hovering over this button, is the button being clicked, is the button the focused widget, is the user pressing <Space> or <Enter> while the button is focused to trigger a button’s action? Those are all different states a button can be in. 

A framework needs to keep track of such state for behavioural widgets. I will describe the data structure I used to solve this problem, listing some benefits and drawbacks, as well as what I might do differently if I had another go at this problem.

The language I used was OCaml (avoiding mutation, although I didn't avoid IO as I planned to do that later). Some thoughts and observations may be helpful and interesting to others, which is the reason for writing this post.

I won’t be talking about the type of individual widgets at all: when types are concerned, only their state will be mentioned.

### The problem in detail

Most UI frameworks typically ask users of that framework to lay their widgets out in trees. This is true of most, including HTML, WPF, Flutter, Swift, and so on (although some exceptions like Dear ImGui exist). Two natural choices for the representation of our framework’s state arise from this:

1. We can store our state in widget objects themselves, in which case we don't need another data structure for the state
2. We can create a “state tree” which mirrors the widget tree

There may be other solutions but I went with the second, which I think is a natural fit for programming languages that discourage mutation like OCaml. 

Diagrams showing the correspondence between the widget tree and state tree are below.

#### Widget tree

![Diagram of a widget tree, containing a column widget at the root, text boxes at the first two indices of the column, and a button wrapped in a Center widget in the third index.](placeholder_url)

This represents an example widget tree for a standard login form. There’s a column laying out three widgets vertically: the first widget is a textbox for the email, the second is another textbox for the password, and the third is a centred button containing a label.

#### State tree

![Diagram of a state tree. This diagram depicts a column state object, which contains textbox state objects at the first two indices and a button state object at the third index. The button itself contains a Leaf state object.](placeholder_url)

The state tree mirrors the widget tree, although with some differences. The main difference is “path compression”: the centre widget has no state and needs no place in the state tree because of this.

The second difference in need of explanation is the Leaf in the state tree. A button in a GUI framework can typically contain another widget, including another button, and it needs a child in the state tree because of this. The Leaf simply means “there is no state here” because a Label widget needs no state unless the label is selectable.

Here is the definition of an OCaml type that can represent this tree:

```
type button_state =
  | Inactive
  | Focused
  | Hovered
  | Clicked
  | …

Type textbox_state = 
  | …

type state_tree =
  | Leaf
  | Button of button_state * state_tree
  | Textbox of textbox_state
  | Column of state_tree array
  | Row of state_tree array
  | …

(* example tree representing login form *)
let form_state_tree = 
  Column [| 
    Textbox (tb1),
    Textbox (tb2), 
    Button (Inactive, Leaf) 
|] 
```

Of course, one would often want more cases in the state tree, including keyed columns (think of the key prop in React), but I think the main idea has been explained quite well.

---
A small aside on accessibility: I have no experience programming with accessibility in mind and may be wrong, but I believe an immutable state tree such as this can represent the data needed for interacting with accessibility APIs quite well.

Chromium uses an (accessibility tree)[https://chromium.googlesource.com/chromium/src/+/master/docs/accessibility/overview.md] which sounds similar to this state tree, and so does the AccessKit crate in Rust.

The main data representation change needed, I think, involves annotating the tree with more information (such as having nodes in the state tree for Labels, and possibly for the Center widget too, so that layout information can be conveyed to accessibility tools).

Then one would need to implement two functions: 

- A pattern matching function which detects the difference between two trees and notifies the OS of differences using its accessibility API
- Another function which receives input such as voice commands from the accessibility service to trigger actions like button callbacks (which would have to be stored in the button_state type at that point).

---

This idea is sound and it works. I’ve implemented it in OCaml but it has a shortcoming which is due to the use of tagged unions/variants/datatypes/enums or whatever you want to call them. 

That issue is extensibility: one cannot add new cases to the state_tree type.

It’s uncommon for frameworks that don’t allow adding new widgets (with state which may need to be modelled differently from any existing state), and I consider the inability to do so a significant flaw for a general purpose GUI framework.

There are “solutions” to extensibility while retaining the general idea, but they are unsatisfactory in my opinion or require language-level support (which OCaml may have to be fair, although I don’t know because of my unfamiliarity with that part of the language).

### Trying to add extensibility

#### Dynamic typing

The problem comes from static typing and wanting to add more cases to a type. 

We can drop the static typing constraint to trivially solve this and allow “open” extensibility with any number of state types.

This is not a compelling solution for those of us who appreciate the benefits of static typing, so I won’t discuss it further.

#### Add primitives to the state tree

The state tree will have new cases like:

```
type state_tree =
  | Int of int * state_tree
  | Float of float * state_tree
  | Bool of bool * state_tree
  | Char of char * state_tree
  | String of string * state_tree
  | ...etc.
```

With these additions, you can represent any “compound type” you want, by nesting primitives inside each other.

We can add a float parameter to a button for example (to control transparency), with the code `Float (1.0, Button (Inactive, Empty))`. 

This is cumbersome though. It’s less ergonomic to type, it involves more pointer indirections which causes performance to suffer, and there’s a chance it will conflict with other “compound types” which also use a float with a button (but the float may have different semantic meaning).

It’s not a satisfactory solution.

#### Support open polymorphism

By open polymorphism, I mean a kind of polymorphism which supports unbounded extension. This is already provided by object-oriented languages, and it is also provided by at least some of the functional languages on the JVM and CLR. It’s probably also supported by OCaml’s object system too.

Consider the following C# code:

```
// empty interface
interface IStateTree {}

// button implementing interface
class ButtonState : IStateTree {
  public bool IsClicked { get; }
}

// … button’s update function
public …output_type… updateButton(IStateTree state, ...other_input_arguments…) {
  if (state is ButtonState buttonState) {
    // processing logic if we received the expected type…
  } else {
    // processing logic if we received a different type…
  }
}
```

In this code, we’re simulating datatypes by defining a class which implements an empty interface. (We could also extend an empty base class to achieve the same thing.) 

This is what I am calling “open polymorphism” in this post. The only real difference between this example and typical pattern matching in functional languages is that the interface permits unbounded implementations, which is what we want in this case.

In contrast,datatypes in functional languages tend only permit a fixed number of cases, which can be expanded by the library which defines the datatype but is not extensible by users of that library.

If I were to continue developing the framework I had started, I might consider adopting this approach. 

I might also take a look at the approaches taken by other similar projects such as Monomer in Haskell, or eXene in Standard ML.

I have learned a lot about various topics from people on the internet and hoped to give back by sharing something I learned with the wider community. 

---

The main inspiration behind this idea comes from @yawaramin and @art-w on the (OCaml forum)[https://discuss.ocaml.org/t/unique-function-ids/12576]. I don’t claim the idea presented here is a unique one that hasn’t been tried before but it may be useful to others and worth writing about.
