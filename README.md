# Point Extrapolation Canvas

Interactive Flutter canvas for:
- dragging points,
- fitting a line on the last `N` points,
- selecting a projected farthest (green) point,
- plotting circles sequentially along a smooth curve,
- building and clipping a final fallback circle near the endpoint.

---

## What This App Does

The app lets you manipulate a set of points and visualize derived geometry:

1. **Point editing**
   - Add/remove points.
   - Drag points in the canvas.
   - Keep points normalized (`0..1`) and map them to canvas pixels for drawing.

2. **Tail fitting**
   - Use `Fit last N` to choose how many last points participate in fitting.
   - Fit uses orthogonal least squares (TLS/PCA style) over the tail.
   - Project tail points on the fitted line.
   - Choose the projected point farthest from reference point #2 as the selected projected point.

3. **Curve building**
   - Build a smooth path from non-tail prefix plus selected projected point.
   - Draw this bridge path in purple.

4. **Circle plotting**
   - Circle plotting starts from the configured start index in state.
   - Snap start to nearest position on the drawn curve path.
   - Draw circles one-after-another with non-overlap spacing.
   - First circle starts from circumference (not start-center).
   - Final fallback circle can be constructed from second-last center toward endpoint.
   - Final fallback is clipped so it does not render beyond the green endpoint.
   - A play button starts/pauses progressive plotting animation.

---

## Validation Rules

- `Fit last N` **must be >= 3**
  - Invalid input shows `SnackBar`.
- Total points **must stay >= 5**
  - Trying to remove below 5 shows `SnackBar`.

---

## Controls

- **Add point**: `+`
- **Remove point**: `-` (blocked below 5)
- **Play/Pause**: toggles circle plotting animation
- **Fit last N**: text input + Update
- **Circle radius**: slider
- **Drag point**: move point position

---

## Project Structure

- `lib/main.dart`
  - Main page UI and controls.
  - Input validation + snackbars.

- `lib/bloc/canvas_state.dart`
  - App state (points, fit count, circle radius, selection, play state).

- `lib/bloc/canvas_cubit.dart`
  - State transitions and interaction methods.

- `lib/presentation/widgets/interactive_canvas.dart`
  - Gesture handling.
  - Animation controller for plotting progress.

- `lib/presentation/painters/points_canvas_painter.dart`
  - Core geometry and all drawing logic.

- `lib/utils/canvas_math.dart`
  - Coordinate conversion and point hit-testing helpers.

---

## Engineering Rationale (Design Thought Process)

This section describes the implementation rationale and trade-offs.

### 1) Why normalized points?
- Drag interactions and point generation are simpler and screen-size independent.
- Rendering always converts normalized points to canvas coordinates at paint time.

### 2) Why tail-based fitting?
- Focusing on recent points (`Fit last N`) makes extrapolation responsive to latest trend.
- Orthogonal least squares is robust for arbitrary line orientation.

### 3) Why select farthest projected point?
- Provides a stable and meaningful endpoint candidate from fitted projection results.
- Green point clearly communicates selected extrapolated target.

### 4) Why draw circles on the curve path (not straight line)?
- The visual path intent is defined by the smooth bridge curve.
- Circle plotting follows that same path for geometric consistency.

### 5) Why nearest-path snapping for start point?
- User picks a start from existing points, which may not lie exactly on curve geometry.
- Snapping guarantees circle centers are constructed from the same path metric space.

### 6) Non-overlap strategy
- Spacing is based on diameter with a small gap (`2 * radius + 2`).
- This avoids ambiguous overlap artifacts and keeps sequence readability.

### 7) Final fallback circle strategy
- When remaining path segment cannot naturally place another on-curve center,
  construct last center on line from second-last center toward endpoint.
- Enforce non-overlap relative to second-last center.
- Clip final circle against endpoint boundary so no part goes past green target.

### 8) Why snackbars for validation feedback?
- Immediate and unobtrusive user feedback.
- Keeps interaction flow uninterrupted while enforcing constraints.

---

## How to Run

```bash
flutter pub get
flutter run
```

If you target a specific platform:

```bash
flutter run -d ios
flutter run -d android
flutter run -d macos
```

---

## Notes

- App behavior is primarily painter-driven and geometry-heavy.
- If adjusting visuals, prefer changing constants in painter helpers first
  (spacing, stroke widths, colors, clip behavior).
- If adding more constraints, enforce in cubit and surface feedback in UI.
