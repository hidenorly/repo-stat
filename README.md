# repo-stat

Diff-ed line count per git between android-pure-s and myproject-based-on-s.
Usually Android project has modifications based on pure S then the diffed-lines are counted by this tool.

Remarkable point is that this tool internally uses ```diff``` command to count the diffed lines on existing files and/or newly added files.

The diffed file enumerations are used by ```git log``` command internally.
But please note that in some case, ```git log``` may give up the modification tracking. You may encounter this behavior on ```frameworks/base.git```, etc.

The diff between -s specified repo dir and -t specified repo dir

```
Usage: -s sourceRepoDir -t targetRepoDir
        --manifestFile=
                                     Specify manifest file (default:manifest.xml)
    -j, --numOfThreads=              Specify number of threads (default:10)
    -v, --verbose                    Enable verbose status output (default:false)
    -s, --source=                    Specify source repo dir.
        --sourceGitOpt=
                                     Specify gitOpt for source repo dir.
    -t, --target=                    Specify target repo dir.
        --targetGitOpt=
                                     Specify gitOpt for target repo dir.
    -g, --gitPath=                   Specify target git path (regexp) if you want to limit to execute the git only
    -p, --prefix=                    Specify prefix if necessary to add for the path
    -m, --mode=                      Specify mode (default:existingOnly,inclNewFile)
    -o, --output=                    Specify report file path )
```

# Usage

```
$ ruby repo-stat.rb -s ~/work/android/android-pure-s -t ~/work/android/myproject-based-on-s -m existingOnly
```
