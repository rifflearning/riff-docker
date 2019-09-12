# Code Comments

Commenting your code is important!

Bad comments may be worse than no comments.

## What makes a good comment?

### Audience

Remembering to write the comment for its intended target audience is key!

The target audience for a class comment is different from the audience for a
method or function comment and both are different from the target audience for
inline comments.

#### Class comments
A class comment should describe the object being modeled well enough that a
developer can decide if an instance of the class provides the right abstaction
for their use of it.

That description should also let a developer determine if some new properties
and/or methods belong to that class or somewhere else.

Describing classes is very hard.

#### Function/method comments
A function comment should:
- describe what the function does for the caller.
- describe the inputs and the output(s) of the function

Optionally example use(s) may also be included to help show how and why the
function would be used.

It may also contain developer notes (that should be called out as such) about
implementation details and current limitations as well as desired future
enhancements.

If you truly feel that the function is very simple and the inputs and outputs
would be completely obvious to the developer looking at the function signature
then leaving out the description of the inputs and outputs is an acceptable way
to keep the function comment concise.

#### Inline comments
The target audience for inline comments is the developer reading the code to
understand how it accomplishes what the function comment says the function does.
Therefore inline comments should:
- help in understanding the algorithm being implemented.
- point out and explain any esoteric uses of the language.
- note any code added to work around bugs, preferably giving a date and an outside
  reference to the bug so that it can be checked to determine if the workaround
  is still necessary.

### Format
Format the comments to be readable by a common code document reader for the
programming language used if there is one. Even if you don't ever intend to
use a documentation tool to extract the documentation from the code, the
conventions will provide consistency to your comments.

#### Javascript/Ecmascript
- [JSDoc][]

#### Typescript
- [TSDoc][]

#### Go
- [Godoc][]

#### Python
- [PEP 257][] Docstring conventions
- [Python documentation tools][pydoctools]


[jsdoc]: <https://devdocs.io/jsdoc/> "documenting javascript code"
[tsdoc]: <https://github.com/microsoft/tsdoc> "documenting typescript code"
[godoc]: <https://blog.golang.org/godoc-documenting-go-code> "documenting Go code"
[pydoctools]: <https://wiki.python.org/moin/DocumentationTools> "python wiki listing documentation tools"
[PEP 257]: <https://www.python.org/dev/peps/pep-0257/> "Python docstring conventions"
