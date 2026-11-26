# Divider restart

The ADPCM decoder clock enable must have the same timing after every reset.
The test holds the reset for many lengths, with `cen` running, and releases it
at the same `cen` phase. The `cen_dec` pulses after each release must come at
the same cycles as after the first release, and at `cen/(4*(divby+1))`.
A divider that keeps its count through the reset fails, which makes the PCM
output change from one FPGA load to the next.

```sh
simunit-all.sh --only jt7759
```
