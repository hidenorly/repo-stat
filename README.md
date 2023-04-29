# repo-stat

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