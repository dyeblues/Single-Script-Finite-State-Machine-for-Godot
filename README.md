# Single-Script-Finite-State-Machine-for-Godot
This is designed to be a light-weight state machine contained in a single script. 
"Oops, it's all Strings."

Capable of handling multiple parallel states through the use of Dictionaries. 
It constructs the dictionaries itself at runtime from the Atomic States dictionary editable in the Inspector.
They Keys of the Dictionary become the Atomic State's name, and the Values of the Dictionary become which Compound State they belong to.
(Compound States are the categories that Atomic States belong to. eg. The 'Walking' Atomic state could belong to the 'Movement' Compound State.)

While being light-weight and versatile, it does not provide much type-safety, as all Compound and Atomic states are Strings,
and State Changes require the use of Strings as well as checking states.
To remedy this as best as possible, multiple debug messages have been included where possible to warn of incorrect strings and potentially help find typos.
