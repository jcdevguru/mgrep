# [mgrep](https://github.com/jcdevguru/mgrep/tree/main/mgrep)

- Type: CLI (zsh script)
- Environment: MacOS
- Provided for: search through files

## Description: faceted command line search of multiple terms in a source hierarchy

Developers often search through source files to find strings in an effort to locate functions. However, a search for just one string often returns too many matches to be useful. It can often be true that we need find source files that contain all of more than one string to pinpoint the subject we are seeking.

For example, suppose you were working in Node JS and wanted to find uses of the `lodash` function `reduce`. A search for just `lodash` would probably return a lot of files. The same would be true if you searched for `reduce`. The natural way to deal with this is to make the search more specific, such as by searching for `lodash.reduce` or `_.reduce`. However, you cannot be sure that this would find all the occurrences you want to change. For example, it is possible that the the function `reduce` was imported from the `lodash` module individually, such as with this code:

```
const { reduce } = require('lodash')
...
const obj = reduce(otherObj)
```

In this situation, results would likely be better by finding all the files that contain `lodash` and then search for the word `reduce` from only those files. Although IDE's provide this functionality by allowing users to search open files, it is convenient to be able to do this search on a command line. That is what `mgrep` provides.

---

## Sample case - why faceted search is tough with standard UNIX commands

Here is an example of files to search and some places within them that hold the strings `forEach` and `iterate`:

| Name               | Contains                     |
| :----------------- | ---------------------------- |
| `src/array-utils.js` | `arr.forEach()`              |
|                    | `// call forEach`              |
|                    | `// iterates through array`    |
| `app/search.js`      | `items.forEach(v=> v)`         |
|                    | `const iterate = (items) => {` |
| `test/test all.js`   | `_.forEach(item1)`            |
|                      | `// iterate over this array`  |

You can search the files that contain occurrences of both string using a fairly simple UNIX command line:

```
 List all files that contain the strings "forEach" and "iterate"

egrep -l $(find . -type f -print | egrep -l forEach) iterate
```

We would expect to see all the files as follows because they contain both strings:

```
./src/array-utils.js
./app/search.js
./app/test all.js
```

However, that won't be so.  You would instead see a partial result, and error messages that are hard to interpret: 
```
./src/array-utils.js
./app/search.js
./test/test: No such file or directory
all.js: No such file or directory
```

Although the `find...egrep` subcommand correctly listed all the files that contained `forEach`, the space in the file name `test all.js` caused the shell to provide `./test/test` and `all.js` to the outer `egrep` command as separate file arguments, which cannot work.

While it is possible to apply quoting and such to avoid issues like that, the simple task of searching multiple files for multiple strings will get much more challenging, especially when you want to search more than two strings, or when you have to search through a large, diverse hierarchy of files, as most software projects often are.  Here are a few:

- Shell expansion syntax shown above won't work easily with multiple levels of expansion, which means three or more strings is hard to search at once
- You will search files and directories you probably don't care about, such as `.git`, git-ignored files, or software installation folders (e.g., `node_modules`)
- `egrep` will (by default) open and match non-textual files, which is usually not useful and will slow the search down unnecessarily
- The expansion of the `find...egrep` command might provide so many file names that the shell command line will hit system limits and fail

Because of the simple and commonplace need to search files with multiple strings without having to overcome these problems every time, I wrote `mgrep`.

---

## mgrep hides the complexity & avoids the issues

Now let's try the above search with `mgrep`

```
mgrep forEach iterate
```

In the above, `mgrep` will run the equivalent of:

```
git ls-files -z \
xargs -0 \
  egrep \
    --binary-files=without-match \
    --files-with-matches \
    --null \
    foreach
xargs -0 \
  egrep \
    --files-with-matches \
    iterate
```

This means the only files that will be searched are non-binary files tracked recognized by `git`, and the NULL-delimiting options in `git ls-files`, `xargs` and `egrep` will be used to handle file names that contain spaces.

The result will then be correct, fixing the problem described in the previous section.

```
src/array-utils.js
app/search.js
test/test all.js
```

---

## Flexibility

Because this script delegates its matching to `egrep`, the `egrep`-style of regular expression syntax is fully supported and need only be quoted normally.  I also support per-pattern flags. For example, to list the files that contain the string `foreach` in any mix of lowercase or uppercase characters that also include `iterate` as a whole word in only lowercase, you can provide flags to specialize each match separately.

```
mgrep -i foreach -w iterate
```
The results will exclude `src/array-utils.js`, because it does not contain `iterate` as a word:
```
app/search.js
test/test all.js
```

`mgrep` will also allow you to see the matches, rather than just the file names that match. To do this, provide `-S` or `--show-matches` as the first argument.

```
mgrep -S iterate -i foreach

 outputs
src/array-utils.js:arr.forEach()
src/array-utils.js:// call forEach
src/array-utils.js:// iterates through array
app/search.js:items.forEach(v=>v)
app/search.js:// const iterate = (items) => {
test/test all.js:_.forEach(item1)
test/test all.js:// iterate over this array
```

---

## Caveats

`mgrep` is specialized to Github projects and has other limitations. I will make updates to support more use cases as I go along.
