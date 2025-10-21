Love it. Here’s your “hard mode” netcode turned into a tight, shippable spec you can hand to yourself (or a teammate) and build against—no fluff.

# Deterministic Fixed-Tick Netcode (Competitive)

## Core Loop (authoritative server, predictive clients)

* **Tick rate:** server & clients simulate at fixed `dt = 1/ts` (e.g., 60 Hz → 16.666… ms).
* **Clock sync:** clients discipline their local tick to server time (slew, don’t jump) via periodic time messages (offset + drift).
* **Input model:** clients send *inputs tagged with clientTick*; server simulates on receipt in authoritative order.
* **Buffering:** each client buffers remote players by `bufferTicks = ceil((avgRTT/2 + jitterP95 + safety) / dt)`.
* **Playback:** render frame uses the latest **complete** remote snapshots (tick-aligned), then **interpolates** (or **extrapolates** on missing data) to present a smooth pose.
* **Prediction:** client predicts **its own** movement using local inputs immediately; reconciles when the authoritative snapshot arrives (rewind → re-simulate unacked inputs → apply).
* **Ordering:** server enforces per-connection, per-tick ordering; clients play other players’ ticks strictly in order.

## Data Flow (per tick)

1. **Client:**

   * Sample inputs → enqueue `(clientId, clientTick, inputBits)`.
   * Predict: `state = Sim(state, input, dt)` (client-only).
   * Send input packet (bundled across 2–3 ticks for loss resilience).
2. **Server:**

   * Receive inputs; map `clientTick` → `serverTick` via known offset.
   * Sim authoritative world for `serverTick` with last known inputs.
   * Emit **snapshot** (or delta) tagged with `serverTick`.
3. **Client (on snapshot):**

   * Store snapshot in a ring buffer by `serverTick`.
   * If snapshot is for **self**:

     * Set `state = snapshot.state`.
     * **Reapply** all locally buffered inputs with `clientTick > snapshot.ackTick`.
   * For **others**: just buffer for render interpolation.

## Key Parameters (start here)

* `tickRate`: 60 (fighters) / 30 (shooters) / 20 (MOBA).
* `snapshotRate`: `tickRate/2` or `tickRate/3` to save bandwidth.
* `bufferTicks`: compute at runtime
  `bufferTicks = clamp( ceil((RTT/2 + jitterP95 + safetyMs) / dt), minBuf, maxBuf )`
  Use `safetyMs ≈ 10–20ms`, `minBuf=1–2`, `maxBuf=10–12`.
* **Jitter tracking:** EWMA mean + P95 over last ~3–5s.

## Interp / Extrap (render step)

* **Interpolation:** when you have ticks `t0` and `t1 = t0+1`, lerp (or hermite/slerp for quats) by fractional alpha from clock offset.
* **Short extrapolation (≤ 100–150ms):** last velocity + angular velocity; clamp to max speed; stop on collision volumes.
* **State compression:** quantize pos/vel/rot to minimize bandwidth; dead-reckon to reduce updates.

## Client Prediction & Reconciliation (for instant feel)

* Keep a circular buffer of `(clientTick, input, predictedState)`.
* When server snapshot `S(ackTick)` for self arrives:

  * Set `state = S.state`.
  * For `tick in (ackTick+1 .. localTick)`: `state = Sim(state, input[tick], dt)`.
* **Deltas only:** store minimal state (pos, vel, yaw, animState) to keep rewind fast.

## Server Authority & Anti-Cheat

* Inputs are suggestions; server validates: speed, acceleration, teleport, fire rate, hit claims.
* **Lag compensation** (hitscan): rewind authoritative world to `shotTime = now - clientRTT/2` and test against historical collider states.
* **Command rate limits:** drop floods, cap buffered inputs per client.

## Bandwidth & Reliability

* **Transport:** UDP + reliability layer (acks, seq, selective retransmit for critical headers); QUIC is a viable alt.
* **Packet layout (example):**

  * Header: `connId | seq | ack | ackBits | serverTick | timecode`
  * Inputs: `N x {clientTick, inputBits}`
  * Snapshots: `M x {entityId, fieldsMask, compressedDelta}`
* **Delta coding:** against last acknowledged baseline per client; periodic keyframes.

## Desync & Drift Handling

* **Clock discipline:** PI controller adjusts local tick pace by tiny ppm (slew ≤ 250 µs/frame).
* **Hysteresis:** only change `bufferTicks` when P95 jitter crosses thresholds for N frames to avoid oscillation.
* **Hold-last-good:** on loss burst, extrapolate ≤150ms then fade to “network smoothing” or freeze pose.

## Debugging & Telemetry (must-have)

* On-screen graphs: RTT, jitter (P50/P95), loss, bufferTicks, local vs server tick.
* Event logs: prediction error magnitudes after reconciliation; extrap duration; dropped/late inputs.
* Record/playback: capture net stream to reproduce deterministically.

## Rollback (when needed)

* For precise combat or hit validation, maintain short **server** history (e.g., 200ms) of world states to:

  * Rewind for lag-comp hits,
  * Re-sim small windows after late inputs.

## Tuning Cheatsheet

* **Feels sluggish?** Lower buffer (risk pops) or raise tick rate; add client-side anticipation (animation/FX).
* **Rubber-banding spikes?** Increase buffer safety by ~1–2 ticks; improve jitter estimate window.
* **Peeker’s advantage too high?** Reduce lag-comp window; require LOS at shot time; server-side fire rate checks.
* **High CPU from rewinds?** Cut recorded fields; shorten history window; cap re-sim frames per snapshot.

## Risks & Reality Check

* **Complexity risk:** medium-high (sync, rewind, deltas, lag-comp).
* **Latency masking:** good up to ~120–160ms; beyond that, tradeoffs show.
* **Success odds (solo/small team, proven engine net stack):** ~75% to reach smooth PvP for <10 players per match; ~50–60% for 32+ without engine-level optimizations. Basis: common indie implementations + known patterns from competitive shooters/MOBAs.

---

