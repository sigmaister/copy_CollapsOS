( Inner core. This unit represents core definitions that
  happen right after native definitions. Before core.fs.

  Unlike core.fs and its followers, this unit isn't self-
  sustained. Like native defs it uses the machinery of a
  full Forth interpreter, notably for flow structures.

  Because of that, it has to obey specific rules:

  1. It cannot compile a word from higher layers. Using
     immediates is fine though.
  2. If it references a word from this unit or from native
     definitions, these need to be properly offsetted
     because their offset at compile time are not the same
     as their runtime offsets.
  3. Anything they refer to in the boot binary has to be
     properly stabilized.
  4. Make sure that the words you compile are not overridden
     by the full interpreter.
)

: INTERPRET
    BEGIN
    WORD
    (find)
    IF
        1 FLAGS !
        EXECUTE
        0 FLAGS !
    ELSE
        (parse*) @ EXECUTE
    THEN
    AGAIN
;
