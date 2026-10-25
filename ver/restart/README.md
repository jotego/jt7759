# Stand-alone sample restart

Regression for jt7759 issue #2. Plays two distinct synthetic ADPCM samples
consecutively without resetting, then repeats with an external reset between
samples. Each start must assert busy, produce nonzero audio, and finish.
The ROM model registers data and only acknowledges a stable address.
The short streams also exercise cancellation of a pending FIFO read at sample
completion; leaving that read active prevents the next sample from fetching.

Run from the jtcores root after sourcing `setprj.sh`:

```sh
simunit-all.sh --only jt7759
```
