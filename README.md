Fix.sh
======
Fix.sh is a small prototype implementation of [Fix], written for POSIX
compatible shells (using [Dash]). I use it to play around with Fix features,
and to create end-to-end tests. In the end it'll probably become a
smaller clone of Fix, suitable for machines without Perl.

Fix.sh is in no way complete, in fact it is not yet able to figure out
dependencies properly, it is however maturing slowly, and might some day be
merged into the the main [Fix] repository.

Fix, in turn, is a build system inspired by D.J. Bernstein's [Redo], but
drawing on [a lot of other peoples insights][inspiration]. For more info on
that see the [Fix wiki].


Options
=======
Options override both environment variable and configuration file settings.

  * `-D`, `--debug`: Enables debug mode, which causes Fix to output extra
    messages on standard error.

  * `-f`, `--force`: Normally Fix will not overwrite any target files that has
    been manually modified since Fix built the file. This option can be used to
    override that.

  * `-h`, `--help`: Display help information, then exit.

  * `--init`: Initializes a new Fix work tree, setting its root to the current
    directory. This creates a `.fix` dir (where Fix stores its build state) in
    the current directory.

  * `--script-dir=DIR` Specifies the directory in which Fix looks for
    buildscripts (`.fix` files). Same as the `$FIX_SCRIPT_DIR` environment
    variable. (Fix never writes to this dir, unless the same dir is also given
    as the target directory.)

  * `--source`: This is used in buildscripts to declare source dependencies for
    its target. Whenever a source dependency has changed, the target becomes
    dirty and will be rebuild next time Fix is invoked. This option cannot be
    used on the command line.

  * `--source-dir=DIR` Specifies the directory in which Fix looks for source
    files. Same as the `$FIX_SOURCE_DIR` environment variable. (Fix never
    writes to this dir, unless the same dir is also given as the target
    directory.)

  * `--target-dir=DIR` Specifies the directory in which Fix will write target
    files. Same as the `$FIX_TARGET_DIR` environment variable. (Fix writes to
    this dir.)

  * `-V`, `--version` Display version information and copyright information,
    then exit.


On File Names
=============
When running Fix your current dir must be inside a Fix work tree (i.e. the
current dir, or one of its parent directories must contain a `.fix` dir with
Fix's build state). All targets specified must also reside in that same work
tree.

On the command line target file names are specified relative to the current
directory, meaning that the following commands are all equivalent (assuming
that your target directory is called `build` and that the current dir is the
Fix worktree root):

    fix build/index.txt

    cd build
    fix index.tx

    cd build/pages
    fix ../index.txt

When running Fix from inside a buildscript (to build a dependency), targets
paths are instead relative to the current `$FIX_TARGET_DIR`, so running `fix
index.txt` inside a buildscript will build `build/index.txt` regardless of your
current directory.


Exit Status
===========
The exit status reflects whether Fix failed or succeeded with its build. More
'severe' errors result in higher exit status value (though the scale is
somewhat arbitrary). Notably, exit status 1 indicate that the build can be
forced to pass (using `--force` -- though this might also expose another
problem, [e.g. 'permission denied'] making the build fail again with a higher
exit value).

The following exit status values are used:

       0 = Success.

       1 = A buildscript failed to execute. This usually means that a
           buildscript (or a buildscript invoked to build one of its
           dependencies) terminated with non-zero exit status, but it could
           also mean that it failed for some other reason, e.g. it wasn't
           executable, could not be found, or that Fix refused to overwrite its
           target file because it had been modified and `--force` wasn't used.

               It is worth noting that when Fix is run from inside a
           buildscript and fail, it will kill the invoking buildscript by means
           of a SIGTERM signal. This guarantees that failure in dependency
           building (or source dependency declaring) abort the build at that
           point, and make sure that the buildscript in question terminates
           with a non-zero exit status, thereby aborting the building of
           everything that depended on it.

               This also means that you don't have to explicitly catch and
           react to dependency errors in your buildscripts (there is no need to
           use `set -e`, or to look at the exit value of each Fix invocation in
           your buildscripts). If you have a buildscript that needs to do
           cleanup in the event of a failure, trap SIGTERM then make sure you
           exit by removing the trap and terminating your script by re-killing
           yourself (e.g. `trap -- TERM; kill -TERM $$`).

       6 = Build succeeded, but failed to write target. E.g. target dir could
           not be created, old target (or target directory) was write protected
           or similar.

       7 = Failed to write metadata.

       8 = Failed to create lockfile. (Most likely this means that another copy
           of Fix is currently running, but it could also be caused by lack of
           write permissions bits, or a stale lockfile if a previous instance
           of Fix was terminated by 'kill -KILL' or somehow failed to remove
           its lockfile.)

       9 = Failed to parse config file.

      10 = Source buildscript or directory is missing.

      13 = `fix --init` failed.

      14 = Couldn't find the root of the Fix work tree. Fix searched for
           searched for the '.fix' dir in current dir and then upwards towards
           '/', but nothing was found. (This usually means that you either
           invoked Fix from the wrong directory, or that you've forgotten to
           run `fix --init`.)

      15 = Bad options, or arguments to options, provided (e.g. using
           `--source` from the command line rather than from inside a
           buildscript, using `--target-dir` with an empty dirname and
           similar).

      16 = Bad target file name provided. One or more of the specified targets
           are outside of the target dir (`$FIX_TARGET_DIR`), and Fix will
           refuse to build them.

      30 = Internal error: build_finalize() was given an incorrect argument.

      31 = Internal error: file_checksum() failed to calculate a SHA1 sum for
           the specified file.

    >128 = Terminated by 'kill' or ctrl-c (subtract 128 from exit status to
           find out which signal was received). NOTA BENE: When stopping Fix
           with 'kill', use the negated PID of the mother process. The mother
           process is the process group leader, and using a negative PID sends
           the signal to all process group members, thereby making sure all
           child processes are signaled too (ctrl-c does this automatically).

Failure
-------
Any exit status except 0 indicates a build failure. You should not trust the
state of your target directory after a failed build -- dependencies are built
first, and one or more of the dependencies may have been successfully built
before the failure occurred leaving parts of your target tree updated, but not
all of it.

  * Exit status: >0
  * Failing target will not be modified (but a tempfile will be created).
  * Failing target's metadata will not be modified.
  * *Nota Bene:* Successful dependencies will be built even on error.

Fix will normally refuse to overwrite a build target if it has been manually
modified since being built, however this behaviour can be overridden using the
`--force` option.


Success
-------
A successful build means that your target and all its dependencies were fully
built.

  * Exit status: 0
  * All built targets guaranteed to be up-to-date.
  * All build tempfiles removed.
  * The current state of all build files stored in metadata.


Writing Files
=============
Script and source files are never overwritten by Fix (only target, tempfiles
and metadata files are written to) -- and in the case of target files, those
will only be overwritten if Fix they have not been modified since last build
(or `--force` was used).


Configuration
=============

Precedence
----------

   1. Command line options will override all other configuration.
   2. Environment variables will override config file options.
   3. Config file will override built-in default values.


Environment
===========
Environment variables override configuration file settings, but they can in
turn be overridden by command line options.

**Boolean** options (`$FIX_FORCE`, `$FIX_DEBUG`) are considered turned off when
unset or empty, and enabled otherwise. **Paths** are relative to the worktree
root.

  * `$FIX_DEBUG` Boolean. See `--debug`.

  * `$FIX_FORCE` Boolean. See `--force`.

  * `$FIX_SCRIPT_DIR`: See `core.scriptdir` and `--script-dir`.

  * `$FIX_SOURCE_DIR` See `core.sourcedir` and `--source-dir`.

  * `$FIX_TARGET_DIR` See `core.targetdir` and `--target-dir`.

See also 'Internal Environment Variables'.


Configuration File
==================
Fix uses a simple INI style file format for its configuration files. It
contains [sections], comments, and config variable assignments.

When you run `fix --init` to initialize your build worktree, a config file with
the default values is created for you in `.fix/config`.

Example:

    #
    # This a the config file, and
    # a '#' or ';' character indicates a comment
    #
    [core]
        ; Set the script dir
        scriptdir = fix

File names in `.fix/config` should be either absolute, or relative to the
worktree root.


Configuration Variables
-----------------------
Paths are relative to the worktree root.

  * `core.scriptdir` (default: `fix/`): Buildscript directory (i.e. where the
    `*.fix` files are located). Can be overridden by the `$FIX_SCRIPT_DIR`
    environment variable.

  * `core.sourcedir` (default: `src/`): Source file directory. Can be
    overridden by the `$FIX_SOURCE_DIR` environment variable.

  * `core.targetdir` (default: `build/`): Target file directory (i.e. where the
    files built by Fix are written). Can be overridden by the `$FIX_TARGET_DIR`
    environment variable.


Internals
=========

Internal Environment Variables
------------------------------
In addition to the environment variables Fix accepts as options, there are also
a number of environment variables that are used internally.

Setting any of these in the shell before invoking Fix will not affect Fix's
behavior (as they are all reset by Fix), but care should be taken not to modify
them inside your buildscripts, as Fix use these variables to communicate with
the its child processes (which are responsible for building your targets).

If you do wish to invoke Fix as if from the command line, make sure
`$FIX_LEVEL` is unset, empty or 0 (e.g. `FIX_LEVEL=0 fix`).

  * `$FIX_DIR`: Full path to the `.fix/` directory in your current worktree
    root. This is the directory where keeps its configuration, build state
    metadata etc.

  * `$FIX_LEVEL`: Used by Fix to determine whether it was invoked from the
    command line (if unset, empty or 0), or from within a buildscript (if > 0).

  * `$FIX_LOCK`: Only one instance of Fix started from the command line can be
    running at the same time in the worktree. This is the lockfile that Fix
    uses to keep track of that.

  * `$FIX_PID`: System process ID of the mother process.

  * `$FIX_PWD`: Full path to current directory of the user as they invoked Fix.
    Filenames displayed on screen (in error messages etc) are shown relative to
    this path.

  * `$FIX_TARGET`: Name of the current target being built.

  * `$FIX_WORK_TREE`: Full path to the root directory of the current worktree.


Tests
=====
The Fix test suite (found in the directory `t/`) can be run using:

    prove

Fix comes with a test suite, with tests written using the [Dash] shell. (Dash
was chosen for its small file size and fast execution time, something that
really matters when you're invoking it multiple times like in a test suite.)
The tests use a a home-brewed test framework called Dashtap (included in this
repo and found in the file `t/dashtap.sh`).

Dashtap's output uses the [TAP] (*Test Anything Protocol*) format, allowing you
run and process the test result with any compatible set of tools (e.g. `prove`
above). There's also a set of tests for Dashtap, which can be found in the
author test directory `xt/` directory. To run these tests, use:

    prove xt/


Additional Notes
================
Fix uses [semantic versioning][SemVer] (also known as SemVer).


Glossary
========
These are some, some of which terms used by build systems in general, and some
of which are specific to Fix.

  * **child process**: A Fix process started from within a buildscript. When a
    Fix child process fails, it will automatically kill the invoking
    buildscript (by means of a `SIGTERM` signal). In a child process
    `$FIX_LEVEL` will be non-zero.

  * **dependency**

  * **dependency graph** or **dependency tree**: Is a _directed acyclic graph_
    (or _DAG_ for short) describing all the dependencies for a target. As long
    as no _listdeps_ have been modified we know that the dependency graph will
    be the same as when we last built all dependencies.

  * **clean tree**: A Fix project tree in which all target files have been
    built and are up-to-date. If Fix is invoked to build a clean tree, it will
    quickly determine that nothing needs to be done and exit with exit
    status 0.

  * **dirty tree**: A Fix project tree that contains one or more unbuild or
    unupdated target files.

  * **listdep** (or **listing dependency**): A dependency that defines what
    other dependencies need to be built. Buildscripts (`.fix` files) fall into
    this category since they declare which other files are needed to build
    their target.

  * **mother process**: The process started from the command line. The mother
    process will invoke one or more buildscripts, which in turn will invoke Fix
    to declare and build dependencies their dependency. In a mother
    process`$FIX_LEVEL` will be zero.

  * **sourcedep** (or **source dependency**): A dependency that isn't built by
    Fix, but is used to produce a target (typically a source file of some
    kind). Whenever a sourcedep has changed, all targets that depend on it will
    have to be rebuilt.


[Dash]: http://gondor.apana.org.au/~herbert/dash/ "Debian Almquist SHell"
[Fix]: //github.com/zrajm/fix
[Fix wiki]: //github.com/zrajm/fix/wiki "Fix Wiki (on GitHub)"
[inspiration]: //github.com/zrajm/fix/wiki/Inspiration-and-References
               "Inspiration and References"
[Redo]: //cr.yp.to/redo.html "D.J. Bernstein's redo"
[SemVer]: //semver.org/ "Semantic Versioning"
[TAP]: https://testanything.org "Test Anything Protocol"

<!--[eof]-->
