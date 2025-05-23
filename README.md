# [mgrep](https://github.com/jcdevguru/mgrep/tree/main/mgrep)

- Type: CLI (zsh script)
- Environment: MacOS (or any UNIX/Linux system with zsh)
- Provided for: search through files

## mgrep: search files for multiple terms in a source hierarchy

Often, we are stuck having to search for text through a large number of files, and suffer from the problem of "too much" or "not enough."  Developers especially know this - we are often tasked with the need to find a piece of code, and although `egrep` and its variants are excellent low-level commands for searching, what they deliver in flexibility comes at the expense of usability.  One simple string search will match too many files.  A longer, more complicated version - after some painful minutes crafting a clever regular expression to cover all the possibilities - will end up getting it all wrong.

Though it takes work, we often find exactly what we need by finding what files contain both of two strings.  That is, when two individual strings appear together in the same file, we have a far better chance of it being on the subject we are searching than if it is contained just one of them. We can - and often do - turn to the "grep" family to assist us, but while quite good at showing us *lines* that contain more than one of a string, they are not so easily coaked into showing us *files* when the strings are on separate lines.   We can make a *grep*-style command do this by running it multiple times - first, by finding files that contain one string, and then by using that list as input to another "grep" command to search for the second string. This, too, can end up being complicated - you're trying to find some code - did you really have time to write a shell script to make it happen?

You are in luck.  *I* wrote you that shell script.  It really is just that - a wrapper to `egrep` (or any other "grep" you prefer) - and I took care of all the stuff that usually gets in the way.

I don't expect any thanks.  Just run it, share it, and enjoy - but let me know if something goes wrong.  But if you want to tell me about the time it saves you, I'll be very happy.

Here are use cases and explanations.

### A typical example - finding code

For example, suppose we were working in Node JS and wanted to find uses of the [Lodash](https://lodash.com) function `reduce` in an effort to change the code to use the native ES6 version of `Array.reduce()`. A way to start is to search for files that contain the word `lodash`, but the search would match any use of `lodash`, not just for `reduce`. If we searched for `reduce` on its own, we would find any occurrence of that word, which also would be too general.  If we then decided to make the search more specific and look just for `lodash.reduce` or `_.reduce` we would get closer to finding what we need, but would inevitably miss some occurrences, since Lodash's `reduce` function can be used without specifically referencing the library. For example:

```js
import { reduce } from 'lodash';
...
const reducedArray = reduce(srcArray...);
```

This call to `lodash`'s version of `reduce` would be missed.

Clearly, our chances for success would go up considerably if we could search for files that contain *both* the words `lodash` and `reduce`.   However, to do this on the command line with calls to UNIX command line utilities like `find` and `egrep` would be cumbersome, since we would first have to find all the files that contain the word `lodash`, and then find occcurrences of `reduce` from those files alone.  This would require a tedious set of commands that require you to save file lists, fashion command lines, and so on.  

That is exactly what `mgrep` does for you.  Here is the command line:

```sh
mgrep -w lodash -w reduce
```

The output will be a list of all the files (in and below the current directory) that contain occurrences of both `lodash` and `reduce` as distinct words, in any order, and not necessarily within the same line of text. The search for multiple strings at once is far more likely to match our objective than searches for just one string, and `mgrep` makes this convenient and simple.

---

### A (tedious) example of searching with standard UNIX commands

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

```sh
# List all files that contain the strings "forEach" and "iterate"

egrep -l $(find . -type f -print | egrep -l forEach) iterate
```

We would expect to see all the files as follows because they contain both strings:

```
./src/array-utils.js
./app/search.js
./app/test all.js
```

However, we would not.  You would instead see a partial result, with error messages that are hard to interpret: 
```
./src/array-utils.js
./app/search.js
./test/test: No such file or directory
all.js: No such file or directory
```

Although the subcommand withing `$(...)` correctly listed all the files that contained `forEach`, the space in the file name `test all.js` caused the shell to provide `./test/test` and `all.js` to the outer `egrep` command as separate file arguments.  This caused the operation to fail.

Spaces in file names might be exotic, but here are some other, more common complications to consider:

- Shell expansion syntax shown above won't work easily with multiple levels of expansion, which means three or more strings are hard to search at once
- You will search files and directories you probably don't care about, such as `.git`, git-ignored files, or software installation folders (e.g., `node_modules`)
- `egrep` will (by default) open and match non-textual files, which is usually not useful and will slow the search down unnecessarily
- Just expanding the output of a command with `$(...)` may provide so many file names that the shell command line will hit system limits and fail

`mgrep` manages all of the above, as explained below.

---

### What mgrep does to make this work

First, let's try out the above case with `mgrep` and see what happens to make it work:

```sh
mgrep forEach iterate
```

In the above, `mgrep` will run the equivalent of:

```sh
git ls-files -z | \
xargs -0 \
  egrep \
    --binary-files=without-match \
    --files-with-matches \
    --null \
    foreach | \
xargs -0 \
  egrep \
    --files-with-matches \
    iterate
```

In the search for `foreEach`, the commands `git ls-files`, `xargs`, and `egrep` will cause all non-binary files tracked by Github to be searched and file names to be processed with NULL delimitation.  That allows us to ignore the uninteresting files as well as preserve the space correctly when sending it to the next command, in this form:

```
src/array-utils.js\0app/search.js\0test/test all.js
```

The second command, which begins with `xargs -0`, will supply these files to `egrep` directly, without using the shell to expand them into a list. Even though `test all.js` has a space in its name, the file will be opened and searched correctly.  `mgrep` will then show its final results correctly.

```
./src/array-utils.js
./app/search.js
./test/test all.js
```

**No errors!!**

---

## Options

`mgrep` accepts flags that start with `+`, not `-`, since flags that begin with `-` are passed to `egrep` (see below).  You can have multiple occurrences of flags to use for filtering. 

| Option | Description | Default |
|--------|-------------|---------|
| `+d`, `+D` | Turn on (`+d`) or off (`+D`) debug messages | Off |
| `+s`, `+S` | Show (`+s`) or do not show (`+S`) matching strings | Off |
| `+g`, `+G` | Use `github ls-files` (`+g`), or bypass Github (`+G`), for files to search if in Github directory | On |
| `+i=`*cmd* | Initialize options with command *cmd* | None |
| `+n`, `+N` | Dry run: apply (`+n`) or do not apply (`+N`) debugging and do not execute search | Off |
| `+xd=`*pat1*[,*pat2*,...] | Ignore files under directories whose names match any pattern in comma-separated list| None |
| `+od=`*pat1*[,*pat2*,...] | Search only under directories whose names match any pattern in comma-separated list| None |
| `+xf=`*pat1*[,*pat2*,...] | Ignore plain files whose names match any pattern in comma-separated list| None |
| `+of=`*pat1*[,*pat2*,...] | Search only in hierarchy under directory with name that matches any pattern in comma-separated list | None |
| `+ixd=`*pat* `+iod=`*pat* `+ixf=`*pat* `+iof=`*pat* | Same as `+xd`, `+od`, `+xf`, `+of`, except without comma-separation | None |

The options that select or ignore files and directories (`xd`, `od`, `xf`, `of`, and variants that start with the letter `i`) have the following features:

* Any of these options can be used multiple times on the command line, in any combination or order.
* Arguments that do not begin with `i` can be used with comma-separated lists
* Shell-style wildcards that are usable by `find` in its `name` or `path` arguments may also be used
* Strings with any characters can be used as arguments, including whitespace
* You can use the variants `ixd`, `iod`, `ixf`, or `iof` if the arguments contain commas
* Will combine with filtering provided by Github when `+g` is used

## Configuring mgrep options with .mgrep

### Description

The `mgrep` script supports custom configurations through a `.mgrep` file located in the base directory of the search or in the user's $HOME directory. This file allows users to set up their preferred environment and default flags for `mgrep`.

Here's how it works:

* The `.mgrep` file is a shell script (Zsh) that defines functions to set various options.
* These functions can be used to ignore specific directories or files, set the GitHub usage flag, and more.
* Users can define their own functions to group common settings (e.g., `ignore_npm`, `ignore_artifact`).
* At the end of the file, users can call these functions to apply their preferred settings.

Example usage (from file `dot-mgrep.example.zsh`):

```zsh

# Sample preferences for a developer who
# uses Github but is not interested in
# lock files from package managers, and
# where minified files are tracked in Github

dev_github
ignore_minified
ignore_package_manager_artifact
```

By grouping together favorite combinations of flags and qualifiers, it is easy to adapt `mgrep` for different projects or environments. Users can quickly switch between different configurations by commenting/uncommenting function calls at the end of the file.

### Application of options

With the `.mgrep` file, your runtime preferencs will be applied in the following order:

* The `.mgrep` file in your home directory will be read first
* A local `.mgrep` file at the starting point of the search will be read next, which will combine with or override options in `$HOME/mgrep`
* If an initialization command is supplied with `+i` that matches the name of a function defined in `.mgrep`, it will be run inline to specialize preferences (using the shell's `.` command)
* Flags submitted on the command line will be processed last, combining with and overriding all previously set options.

To see what options would be in effect in any particlar run, you can apply the `+n` flag to just do a dry run.  The options will show with an `options` tag on standard error output.  This command will show you debugging output and errors only, without execting the search.

```sh
$ mgrep +n anystring
DEBUG [options]: debug=1 dry_run=1 github=1 show=0 xf=() of=() xd=() od=() init=''
DEBUG [process]: using git to list files (directory in git)
DEBUG [execute]: command = [git ls-files -z . | xargs -0 egrep --binary-files=without-match --files-with-matches 'anystring']
```

## Flexibility

Because this script delegates its matching to `egrep`, the `egrep`-style of regular expression syntax is fully supported and needs only be quoted normally.  It also support per-pattern flags, which will precede each pattern argument in every call to `egrep`. Taking from the above example, we can list the files that contain both the string `foreach` in any mix of lowercase or uppercase characters and the string `iterate` as a whole word in only lowercase by applying separate flags for each pattern.

```sh
mgrep -i foreach -w iterate
```
The results will contain the following:

```
app/search.js
test/test all.js
```

but will exclude `src/array-utils.js`, because it does not contain `iterate` as a word.

## See the matches

`mgrep` will also allow you to see the matches, rather than just the file names that match. To do this, provide `+s` flag.

```sh
mgrep +s iterate -i foreach
```

```
# outputs
src/array-utils.js:arr.forEach()
src/array-utils.js:// call forEach
src/array-utils.js:// iterates through array
app/search.js:items.forEach(v=>v)
app/search.js:// const iterate = (items) => {
test/test all.js:_.forEach(item1)
test/test all.js:// iterate over this array
```

---

## More examples

### Raw search, without Git or just ignoring it

By default, `mgrep` will traverse the files listed in a Git sourcebase.  However, if you do not have `git` in your command path or are not in a directory structure that is manged by Git, `mgrep` will use `find` rather than `git ls-files` to get its initial file list to search. If you **are** in a Git directory hierarchy, and want to traverse all files anyway, you can supply the `+G` flag:

```sh
mgrep +G abc def
```

would generate this command to search:

```sh
find . -type f -print0 | \
xargs -0 \
  egrep \
    --binary-files=without-match \
    --files-with-matches \
    --null \
    abc | \
xargs -0 \
  egrep \
    --files-with-matches \
    def
```

which means all text files under the current directory would be searched if the directory hierarchy is not managed by Git.


### Raw search, exclude certain directories

If you don't want certain directories traversed, you can name them in command arguments to `mgrep`.  For example, if you do not want to traverse directories named `log`, `tmp`, or `.git` anywhere in the hierarchy, you can use this command:

```sh
mgrep +G +xd=log,tmp,.git abc def
```

to make `mgrep` use this command to search:

```sh
find . \( -type d \( -name 'log' -o -name 'tmp' -o -name '.git' \) ! -name . -prune \) -o -type f -print0 | \
xargs -0 \
  egrep \
    --binary-files=without-match \
    --files-with-matches \
    --null \
    abc | \
xargs -0 \
  egrep \
    --files-with-matches \
    def
```

This would also work with shell-style wildcards, which are supported by `find`.  For example, to exclude all hidden directories, you could use:

```sh
mgrep +xd='.*' abc def
```

would cause the initial file list to be generated with:

```sh
find . \( -type d \( -name '.*' \) ! -name . -prune \) -o -type f -print0
```

which ignores all directories named with a leading `.` (not including `.`, of course, which would stop `find` from traversing anywhere).

### Raw search, but only in certain directories

You can also use `mgrep` with `+od` to look only under certain directories by name, excluding all others.  You can use wildcards here as well.

```sh
mgrep +G +xd=.git +od='node_modules,.npm*' eslint airbnb
```

The above would cause the search to occur only on plain files in directory hierarchies that are under directories name `node_modules` or under `.npm*` but nowhere under `.git`:

```sh
find . \( -type d ! \( -name '.git' \) ! -name . -prune \) -o -type f -path='*/node_modules/*' -o -path='*/.npm*/*' -print0

```

### Raw search, but only inside or outside certain text files

Like `+xd` and `+od`, you can use `+xf` or `+of` to exclude or include certain text files (respectively).

The command:


```sh
mgrep +G +xd=tmp +of=package.json,package-lock.json,.pnpm-lock.yaml module1 module2
```

will list all plain files named `package.json`, `package-lock.json`, or `.pnpm-lock.yaml` not in a hierachy under any directory named `tmp` and that contain both strings `module1` and `module2`.  The generated command would look this way:

```sh
find . \( -type d \( -name 'tmp' \) ! -name . -prune \) -o \
  -type f \( -name 'package.json' -o -name 'package-lock.json' -o -name '.pnpm-lock.yaml' \) -print0 | \
  xargs -0 \
  egrep \
    --binary-files=without-match \
    --files-with-matches \
    --null \
    module1 | \
xargs -0 \
  egrep \
    --files-with-matches \
    module2
```

## Discuss?

Please submit commentary in the `Issues` tab of this Github repository.
