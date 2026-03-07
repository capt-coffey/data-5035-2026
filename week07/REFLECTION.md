# Week 07 — Reflection: Programming Paradigms

## Assignment: In-Motion EV Charging Lane Pilot Location Selection

---

## 1. Which Programming Paradigm Did I Use Where?

I used **Declarative (SQL)** for the spatial feature calculations — specifically distance to power infrastructure and interchange density using Snowflake's native `ST_DISTANCE` and `ST_DWITHIN` functions. I also used a SQL cell to set the execution context at the top of the notebook.

I used **Imperative (Python)** for loading and merging source tables, applying scoring logic, normalizing values, computing the weighted composite score, and selecting the final 4 pilot locations.

I used **AI-Driven** throughout the entire development process as an iterative reasoning partner — not just for code generation, but for architectural decisions, debugging, interpretation, and score criteria refinement. A full transcript is included in the repository as `Week 7 AI Transcript.pdf`.

---

## 2. Why Did I Choose These Paradigms in That Area?

**SQL for spatial calculations** made sense because Snowflake's geospatial functions are built for set-based geographic aggregation. Calculating the distance from 103 road segments to 55 power infrastructure points and aggregating to find the minimum per segment is exactly what SQL handles elegantly in a single query. It is also worth noting that I found I could have written this entire project as one large SQL query using CTEs — my decision not to was predicated on the desire to mix in Python for more imperative coding examples. In the end, I think I swung a bit too far in the other direction, however I kept running into access issues in my Snowflake SQL code.

**Python for scoring logic** was chosen (as mentioned above) mostly for diversity in paradigms, however it evolved to take on a larger role. Being able to adjust weights, caps, and normalization in explicit procedural steps made the logic easier for me to iterate on, audit, and explain in my README.

**An Observation:** Even with intentional effort to use both coding paradigms, my default instinct throughout this project was to reach for Python. When faced with a new problem, I started with a Python cell rather than thinking declaratively about how SQL could solve it. In hindsight, more of my scoring and ranking logic could have been written in SQL. I think this reflects my comfort with imperative programming (it also scratches the itch of my control issues), rather than a considered architectural choice.

**AI-Driven throughout** to assist throughout the whole process as documented in section 1.

---

## 3. What Additional Data Would Improve My Confidence?

- **Real EV traffic data.** The synthetic data in this assignment was unusually clean — every table joined perfectly on `SEGMENT_ID` or `GEOM` with no gaps or inconsistencies. In reality, I would expect EV traffic data to come from multiple sources with different collection methodologies, misaligned geographic boundaries, and significant gaps in rural areas. Cleaning and reconciling that data would be a substantial part of the project in itself.
- **Power grid capacity.** Proximity to a substation doesn't tell me whether it has the capacity to support a charging lane. A segment adjacent to a small rural substation could score well on proximity but be completely infeasible from a capacity standpoint. Load capacity data from utility companies would make my feasibility score significantly more meaningful.
- **Road geometry for straightness.** The assignment listed straight road geometry as a feasibility factor, but I didn't have a straightness metric available in the source data. The `GEOM` LineString coordinates could theoretically be used to calculate curvature, but I did not implement this.
- **Data to support a true Pilot Value score.** Lane count was the only available proxy for pilot value, which is why I renamed the dimension `lane_score`. A real pilot value score would incorporate proximity to population centers, media market size, state DOT relationships, and regional EV adoption rates.
- **Weather impact on infrastructure specifically.** The `risk_score` column captures general weather risk but doesn't distinguish between events that affect drivers versus those that damage physical infrastructure. A dataset focused on storm, flooding, or ice damage to highway infrastructure would allow me to score this more precisely.

---

## 4. What Political or Operational Risks Do I See?

- **Multi-state DOT coordination.** My corridors cross both Missouri and Illinois, meaning any pilot installation requires coordination with at least two state Departments of Transportation, each with their own approval processes and priorities. Gaining alignment across agencies adds significant complexity and timeline risk.
- **Utility company cooperation.** Even segments that score well on power proximity still require utility buy-in to actually connect to the grid — which can be slow and complicated, especially in rural areas where capacity is already constrained.
- **Consecutive segment selection.** My top two Chicago corridor picks (I55-004 and I55-005) are adjacent segments, limiting the geographic diversity and learning value of the pilot. A future version of this model should include a minimum distance constraint between selected segments within the same corridor.
- **Perceived corridor bias.** The St. Louis ↔ Chicago corridor produced significantly higher composite scores due to higher EV demand, meaning my top I-70 segments ranked 5th and 8th overall. Stakeholders along the I-70 corridor may question the fairness of the selection without clear communication about the corridor coverage constraint and its rationale.
