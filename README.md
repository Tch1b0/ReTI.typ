# ReTI.typ

utility for the assembly-like language at the University of Freiburg

## usage example

```typ
#import "ReTI.typ": draw_reti_table, interpret_reti

= Reti Program as a table

== Draw with default options

#draw_reti_table("./example_program.reti", start_idx: 1, storage_name "M")

#let storage = (0,) * 100
#let results = interpret_reti("./example_program.reti", storage)

#let resulting_storage = results.at(0)
#let steps = results.at(1)
```
