Fix.sh
======
Fix.sh is a small prototype implementation of [Fix], written in [DASH]. I use
it to play around with Fix features, and to create a end-to-end tests. In the
end it'll probably become a smaller/slower clone of Fix.

Fix.sh is in no way complete, in fact it does not even have command line
options parsing (options are currently set using environment variables).


Fix
===
Fix is a build system inspired by D.J. Bernstein's [redo], but drawing on [a
lot of other peoples insights][inspiration]. For more info on that see the [Fix
wiki].

[Fix]: https://github.com/zrajm/fix
[DASH]: http://gondor.apana.org.au/~herbert/dash/ "Debian Almquist SHell"
[redo]: http://cr.yp.to/redo.html "D.J. Bernstein's redo"
[inspiration]: https://github.com/zrajm/fix/wiki/Inspiration-and-References
               "Inspiration and References"
[Fix wiki]: https://github.com/zrajm/fix/wiki "Fix Wiki (on GitHub)"


Writing Files
=============
Script and source files are never written to by fix (only target, temp and
metadata files are written to).


Exit Status
===========
The exit status reflects whether fix failed or succeeded with its build. More
'severe' errors result in higher exit status value (though the scale is
somewhat arbitrary). Notably, exit status 1 indicate that the build can be
forced to pass (using '--force' -- though this might also expose another
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
           of fix is currently running, but it could also be caused by lack of
           write permissions bits, or a stale lockfile if a previous instance
           of fix was terminated by 'kill -KILL' or somehow failed to remove
           its lockfile.)

      10 = Source buildscript or directory is missing.

      15 = Bad options provided (e.g. using `--source` from the command line
           rather than from inside a buildscript.)

      30 = Internal error: build_finalize() was given an incorrect argument.

    >128 = Terminated by 'kill' or ctrl-c (subtract 128 from exit status to
           find out which signal was received). NOTA BENE: When stopping fix
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

Success
-------
A successful build means that your target and all its dependencies were fully
built.

  * Exit status: 0
  * All built targets guaranteed to be up-to-date.
  * All build tempfiles removed.
  * The current state of all build files stored in metadata.


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
