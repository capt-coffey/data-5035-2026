# Week 07 — In-Motion EV Charging Lane Pilot Location Selection

## Project Overview

This project identifies the **best 4 pilot locations** for an in-motion EV charging lane technology along two major highway corridors:

- **St. Louis ↔ Kansas City** via I-70
- **St. Louis ↔ Chicago** via I-55, I-64, I-57, and I-80

Instead of stopping to charge, drivers using this technology move into a dedicated lane, slow to 30 mph, attach to a guided charging cable, and travel approximately 10 miles while charging. The goal of this analysis is to identify which 10-mile road segments along these corridors offer the best combination of EV demand, infrastructure feasibility, safety, and lane suitability for a pilot installation.

The solution demonstrates three programming paradigms: **Imperative** (Python), **Declarative** (SQL), and **AI-Driven** (iterative reasoning with a large language model throughout the development process).

---

## Repository Contents

| File | Description |
|------|-------------|
| `week07_assignment.ipynb` | Main Snowflake notebook containing all code |
| `SEGMENTS.csv` | All 103 road segments with composite suitability scores |
| `TOP4_SEGMENTS.csv` | The final 4 recommended pilot locations |
| `README.md` | This file — project overview, instructions, and assumptions |
| `REFLECTION.md` | Answers to assignment reflection questions |
| `conversation_transcript.pdf` | Full AI-assisted development transcript |

---

## How to Run

This project runs entirely within a **Snowflake Notebook** environment. All source data is pre-loaded in the `DATA5035.SPRING26` schema.

1. Open `week07_assignment.ipynb` in your Snowflake notebook environment
2. Ensure your execution context is set by running the first SQL cell:
   ```sql
   USE DATABASE DATA5035;
   USE SCHEMA SPRING26;
   ```
3. Run all cells in order from top to bottom
4. The final two cells will print the contents of `SEGMENTS.csv` and `TOP4_SEGMENTS.csv` to the notebook output

---

## Code Structure & Paradigm Breakdown

### Cell 1 — Execution Context (SQL | Declarative)
Sets the active database and schema so subsequent cells can reference tables without fully qualified names.

### Cell 2 — Base DataFrame Construction (Python | Imperative & Declaritive)
Loads four source tables (`ROAD_SEGMENTS`, `TRAFFIC_COUNTS`, `WEATHER_RISK`, `INCIDENTS`) from Snowflake into pandas DataFrames and merges them on `SEGMENT_ID`. Also derives a `CORRIDOR` label using `numpy.where` to classify each segment as either St. Louis ↔ Kansas City or St. Louis ↔ Chicago.

This cell also embeds a SQL spatial query that calculates:
- `dist_to_power_m` — distance in meters from each segment to the nearest power infrastructure point
- `close_to_power` — boolean flag indicating whether a segment is within 10 miles of power infrastructure
- `power_distance_ratio` — normalized 0–1 ratio of power distance relative to the furthest segment
- `interchange_count` — count of interchanges within 10 miles of each segment (capped at 10)

The SQL within this cell uses Snowflake's native geospatial functions (`ST_DISTANCE`, `ST_DWITHIN`) which are a natural fit for declarative, set-based operations. Python was chosen for the surrounding orchestration because it allows procedural control over table loading, merging, and column normalization.

**Note:** A standalone SQL cell containing this spatial query is preserved but commented out. It was the original approach before permissions constraints required it to be embedded in Python rather than saved as a view.

---

### Cell 3 — Demand Score (Python | Imperative)
Scores each segment on EV traffic demand using `aadt_ev` (annual average daily EV traffic). Min-max normalization is applied so the highest-demand segment scores 1.0 and the lowest scores 0.0.

```
demand_score = (aadt_ev - min) / (max - min)
```

Min-max was chosen over percent rank because the actual magnitude of EV traffic matters here. A segment with significantly more EV traffic should score proportionally higher, not just marginally higher based on rank position.

---

### Cell 4 — Feasibility Score (Python | Imperative)
Scores each segment on infrastructure feasibility using two components weighted equally at 50/50:

- **Power proximity** (50%) — `power_distance_ratio` inverted so that segments closer to power score higher
- **Interchange density** (50%) — `interchange_count` normalized and inverted so that segments with fewer interchanges score higher

```
power_score        = 1 - power_distance_ratio
interchange_score  = 1 - normalize(min(interchange_count, 10))
feasibility_score  = (power_score * 0.5) + (interchange_score * 0.5)
```

`close_to_power` was considered as an alternative to `power_distance_ratio` but was dropped because it is binary — it does not distinguish between a segment 1 mile from power and one 9 miles away. `power_distance_ratio` provides more meaningful granularity for scoring.

The interchange count is capped at 10 within this cell explicitly in Python. This was a deliberate choice to keep the data layer (SQL) separate from scoring decisions (Python), making assumptions easier to audit and adjust.

---

### Cell 5 — Safety Score (Python | Imperative)
Scores each segment on safety using three components:

- **Incident rate** (50%) — inverted, lower incidents = safer
- **Crash rate** (30%) — inverted, lower crashes = safer
- **Weather risk** (20%) — inverted, lower risk = safer

```
safety_score = (incident_score * 0.50) + (crash_score * 0.30) + (weather_score * 0.20)
```

Incident rate was weighted most heavily because minor incidents that do not qualify as crashes can still disrupt lane usability. Weather risk was weighted lowest because drivers can self-select out of adverse conditions, and weather-related vehicle incidents are likely already captured in the incident rate — making `risk_score` most relevant for non-vehicle infrastructure risks such as storm damage.

---

### Cell 6 — Lane Score (Python | Imperative)
Scores each segment based on number of lanes, where fewer lanes score higher. This reflects the assumption that a pilot installation is easier to implement on a lower-lane-count road, with future expansion potentially targeting higher-lane roads for lane conversion.

```
lane_score = 1 - normalize(lanes)
```

This was originally conceived as a broader "Pilot Value" score but was renamed `lane_score` to more accurately reflect what is actually being measured. A true pilot value score would incorporate additional data not available in this dataset (see REFLECTION.md).

---

### Cell 7 — Composite Score (Python | Imperative)
Combines all four dimension scores into a single weighted composite score:

| Dimension | Weight | Rationale |
|-----------|--------|-----------|
| Demand | 35% | EV traffic volume is a primary driver of pilot value |
| Feasibility | 35% | Infrastructure constraints are the most complex real-world factor |
| Safety | 25% | Critical but partially correlated with demand (urban = higher both) |
| Lane Score | 5% | Weak signal — 77 of 103 segments share the minimum lane count |

```
composite_score = (demand * 0.35) + (feasibility * 0.35) + (safety * 0.25) + (lane_score * 0.05)
```

---

### Cell 8 — Final Selection (Python | Imperative)
Selects the top 2 segments per corridor by composite score using `groupby` and `nlargest`, ensuring geographic coverage across both the St. Louis ↔ Kansas City and St. Louis ↔ Chicago corridors.

---

### Cells 9 & 10 — CSV Output (Python | Imperative)
Prints the full scored segment list and top 4 selections as CSV-formatted output.

---

## Scoring Assumptions

- **Interchange cap of 10** — segments near Chicago have interchange counts as high as 28, which would unfairly dominate the feasibility score. Any segment with more than 10 interchanges within 10 miles is treated equally as high-density.
- **Power proximity threshold** — `close_to_power` uses a 10-mile (16,093 meter) radius. The raw distance ratio is used for scoring rather than this binary flag.
- **Corridor coverage** — final selection enforces 2 picks per corridor to ensure the pilot covers both the St. Louis ↔ Kansas City and St. Louis ↔ Chicago routes.
- **Geographic spread within corridor** — the model selects the top 2 by score within each corridor. Note that the top 2 Chicago corridor picks (I55-004 and I55-005) are consecutive segments. A future iteration could add a minimum distance constraint between selected segments.

---

## Note on Final CSV Exports 
I could not get the final CSV exports to work correctly (and I used a lot of different avenues). Ultimately, it seems like the files were "created" but not visibile on Snowflake OR Github. To ensure it was available for final submission I went ahead and copy / pasted the values into a file and manually uploaded to GitHub. 