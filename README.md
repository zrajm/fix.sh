Fix.sh
======
Fix.sh is a small prototype implementation of [Fix], written for POSIX
compatible shells (using [Dash]). I use it to play around with Fix features,
and to create end-to-end tests. In the end it'll probably become a
smaller clone of Fix, suitable for machines without Perl.

Fix.sh is in no way complete, in fact it is not yet able to figure out
dependencies properly, it is however maturing slowly, and might some day be
merged into the the main [Fix] repository.


Fix
===
Fix is a build system inspired by D.J. Bernstein's [redo], but drawing on [a
lot of other peoples insights][inspiration]. For more info on that see the [Fix
wiki].

[Fix]: https://github.com/zrajm/fix
[Dash]: http://gondor.apana.org.au/~herbert/dash/ "Debian Almquist SHell"
[redo]: http://cr.yp.to/redo.html "D.J. Bernstein's redo"
[inspiration]: https://github.com/zrajm/fix/wiki/Inspiration-and-References
               "Inspiration and References"
[Fix wiki]: https://github.com/zrajm/fix/wiki "Fix Wiki (on GitHub)"


Options
=======
`-D`, `--debug` Enables debug mode, which causes Fix to output extra messages
on standard error.

`-f`, `--force` Normally Fix will not overwrite any target files that has been
manually modified since Fix built the file. This option can be used to override
that.

`-h`, `--help` Display help information, then exit.

`--init` Initializes a new Fix work tree, setting its root to the current
directory. This creates a `.fix` dir (where Fix stores its build state) in the
current directory.

`--source` This is used in buildscripts to declare source dependencies for its
target. Whenever a source dependency has changed, the target becomes dirty and
will be rebuild next time Fix is invoked. This option cannot be used on the
command line.

`-V`, `--version` Display version information and copyright information, then
exit.


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

      10 = Source buildscript or directory is missing.

      14 = Couldn't find the root of the Fix work tree. Fix searched for
           searched for the '.fix' dir in current dir and then upwards towards
           '/', but nothing was found. (This usually means that you either
           invoked Fix from the wrong directory, or that you've forgotten to
           run `fix --init`.)

      15 = Bad options provided (e.g. using `--source` from the command line
           rather than from inside a buildscript.)

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


Environment Variables
=====================
Fix uses environment variables to pass information to its child processes (for
a large project these can be quite a few!)

| Variable          | Explanation                       | Default        |
|-------------------|-----------------------------------|----------------|
| `$FIX_DEBUG`      | Set if `--debug` option was used  | empty          |
| `$FIX_DIR`        | Dir for build state               | `.fix/`        |
| `$FIX_FORCE`      | Set if `--force` option was used  | empty          |
| `$FIX_LEVEL`      | 0 = mother process, >0 = child    | number >= 1    |
| `$FIX_LOCK`       | Lock file                         | filename       |
| `$FIX_PID`        | Mother process PID                | PID            |
| `$FIX_PWD`        | Invoking user's current dir       | dir name       |
| `$FIX_SCRIPT_DIR` | Buildscripts dir                  | `fix/`         |
| `$FIX_SOURCE_DIR` | Source file dir                   | `src/`         |
| `$FIX_TARGET`     | Current target name               | filename       |
| `$FIX_TARGET_DIR` | Target file dir                   | `build/`       |
| `$FIX_WORK_TREE`  | Dir in which '.fix' dir resides   |                |


Additional Notes
================
Fix uses [semantic versioning](http://semver.org/).


Glossary
========
These are some, some of which terms used by build systems in general, and some
of which are specific to Fix.

**child process** - A Fix process started from within a buildscript. When a Fix
child process fails, it will automatically kill the invoking buildscript (by
means of a `SIGTERM` signal). In a child process `$FIX_LEVEL` will be non-zero.

**dependency**

**dependency graph** or **dependency tree** - Is a _directed acyclic graph_ (or
_DAG_ for short) describing all the dependencies for a target. As long as no
_listdeps_ have been modified we know that the dependency graph will be the
same as when we last built all dependencies.

**clean tree** - A Fix project tree in which all target files have been built
and are up-to-date. If Fix is invoked to build a clean tree, it will quickly
determine that nothing needs to be done and exit with exit status 0.

**dirty tree** - A Fix project tree that contains one or more unbuild or
unupdated target files.

**listdep** (or **listing dependency**) - A dependency that defines what other
dependencies need to be built. Buildscripts (`.fix` files) fall into this
category since they declare which other files are needed to build their target.

**mother process** - The process started from the command line. The mother
process will invoke one or more buildscripts, which in turn will invoke Fix to
declare and build dependencies their dependency. In a mother process
`$FIX_LEVEL` will be zero.

**sourcedep** (or **source dependency**) - A dependency that isn't built by
Fix, but is used to produce a target (typically a source file of some kind).
Whenever a sourcedep has changed, all targets that depend on it will have to be
rebuilt.

------------------------------------------------------------------------------

Pseudocode
==========

    if (not exists script) {
        FAILURE
    }

    run script (producing tempfile)
    if (script failed) {
        FAILURE: script exited non-zero
    }

    if (targetfile does not exists) {
        copy tempfile to target
        SUCCESS
    } elsif (targetfile == tempfile) {
        delete tempfile
        SUCCESS
    } elsif (
        targetfile metadata exist and
        targetfile == targetfile metadata
    ) {
        copy tempfile to target
        SUCCESS
    } elsif ('--force') {
        copy tempfile to target
        SUCCESS
    } else {
        FAILURE: target externally modified
    }

    write metadata
