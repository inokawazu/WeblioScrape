# Description

Weblio provides some functions that scrapes (https://ejje.weblio.jp/) for examples in English
and Japanese.

# How to use.

To get examples for *おはよう*

```julia
using WeblioScrape
word = "おはよう" # must be in Japanese
searchexamples(word)
```
