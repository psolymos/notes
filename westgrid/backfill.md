# backfill tricks for WestGrid usage optimization

This summary is based on this presentation:
https://www.westgrid.ca/files/webfm/seminar_docs/2011/siegert-20111116.pdf

## Strategy

1. Write code that is modular and jobs are predictable, e.g. iterates through a set of labels that can be recovered from the output
2. use the output to scan for remaining jobs (also called *checkpoint/restart*)
3. exploit backfilling if the code can pick up wherever it was left.

## Cheat sheet for regular operations

* `qsub <pbsfile>` submit a job
* `qdel <jobid>` delete a job
* `showq -u <username>` list jobs
* `qstat -u <username>` list info about jobs

## Diagnostics

* `showstart <jobid>` gives an estimate for submitted jobs
* `showbf` shows what kind of jobs can start immediately
* `jobinfo -f` gives fairshare priority
* `showq -i` gives rank in input queue
* `showq -b` lists blocked jobs
* `checkjob -v <jobid>` indicates the problem of the blocked job
 
## Useful Linux commands

* `ls <directory> -1 | wc -l` counts number of files in directory
* `cat <filename>` or `less <filename>` is handy to look at `.out` or `.err` files (`less` can paginate long output)

Additional resources at [LinuxJourney](https://linuxjourney.com/lesson/the-shell)
 
