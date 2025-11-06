# HomeGame Improvement Plan
## Analysis: NCAAF Scores vs HomeGame

Based on review of the official NCAAF Scores app source code:
https://raw.githubusercontent.com/tidbyt/community/refs/heads/main/apps/ncaafscores/ncaaf_scores.star

---

## 🔍 Key Findings from NCAAF Scores App

### ✅ **What They Do Well (We Should Adopt)**

#### 1. **Defensive Color/Logo Handling**
```python
homeColorCheck = competition["competitors"][0]["team"].get("color", "NO")
if homeColorCheck == "NO":
    homePrimaryColor = "000000"
else:
    homePrimaryColor = competition["competitors"][0]["team"]["color"]
```
- **Issue**: They check if color/logo exists before using it
- **Our app**: Could crash if ESPN doesn't provide team colors
- **Impact**: HIGH - Prevents crashes

#### 2. **Alternative Color/Logo Dictionaries**
- Maintain hardcoded mappings for teams with bad/missing colors
- Example: `"SYR": "#000E54"`, `"LSU": "#461D7C"`
- **Our app**: Relies 100% on ESPN API data
- **Impact**: MEDIUM - Better visual quality

#### 3. **Text Shortening Dictionary**
```python
SHORTENED_WORDS = {
    " PM": "P",
    " AM": "A",
    "Postponed": "PPD",
    "Overtime": "OT",
    "1st Quarter": "Q1",
    "2nd Quarter": "Q2",
    "3rd Quarter": "Q3",
    "4th Quarter": "Q4"
}
```
- Automatically shortens common phrases
- **Our app**: Shows full text which may not fit on display
- **Impact**: MEDIUM - Better space utilization

#### 4. **Configurable Cache TTL**
```python
CACHE_TTL_SECONDS = 60
```
- Uses named constant instead of magic number
- **Our app**: Has magic number `300` (5 minutes) hardcoded
- **Impact**: LOW - Better code maintainability

#### 5. **Date Range API Query**
```python
datePast = now - time.parse_duration("%dh" % 1 * 24)
dateFuture = now + time.parse_duration("%dh" % 6 * 24)
```
- Queries past 1 day + future 6 days to catch recent/upcoming games
- **Our app**: Only queries single team endpoint (may miss recent games)
- **Impact**: LOW - We only show next game (by design)

#### 6. **Null Safety Patterns**
- Extensive use of `.get()` with fallbacks
- Validates values after retrieval
- **Our app**: Uses `.get()` but doesn't validate values
- **Impact**: HIGH - Prevents crashes

#### 7. **Render Animation for Multiple Games**
```python
return render.Root(
    delay = int(rotationSpeed) * 1000,
    show_full_animation = True,
    child = render.Animation(children = renderCategory)
)
```
- Can display multiple games in rotation
- **Our app**: Single game only (as designed, but could offer option)
- **Impact**: LOW - Not our core feature

---

### ⚠️ **What They Do Poorly (We Should Avoid)**

#### 1. **Massive Hardcoded Data**
- 100+ lines of ALT_COLOR dictionary
- 100+ lines of ALT_LOGO dictionary
- 1000+ lines of team options in schema
- **Our app**: Minimal hardcoded data ✅
- **Assessment**: We're better here - maintainability nightmare

#### 2. **No Test Suite**
- No automated tests visible in their codebase
- **Our app**: Full integration test suite with golden images ✅
- **Assessment**: We're WAY ahead here

#### 3. **Complex Configuration**
- 8+ configuration options (overwhelming for users)
- Display type, pregame display, rotation speed, etc.
- **Our app**: Simple, focused configuration ✅
- **Assessment**: We have better UX

#### 4. **Multiple Display Modes**
- 6 different display modes to maintain
- "colors", "logos", "horizontal", "stadium", "retro"
- **Our app**: Single, focused display ✅
- **Assessment**: We have better focus

---

## 🎯 **Recommended Improvements for HomeGame**

### Priority 1: Defensive Programming ⭐⭐⭐ (High Impact, Low Effort)

**Problems to solve:**
- App could crash if ESPN API returns unexpected data
- No handling of missing scores, team names, colors
- Period numbers not validated

**Solutions:**
1. Add defensive checks for missing API data
2. Add fallback values for team names, colors, scores
3. Validate period numbers are in expected range
4. Handle malformed ESPN responses gracefully

**Code locations:**
- `parse_game_event()` - lines 171-348
- `main()` - lines 61-87

**Example improvements:**
```python
# Current (vulnerable)
our_score = game_data.get("our_score", 0)

# Improved (defensive)
our_score = game_data.get("our_score")
if our_score is None or not isinstance(our_score, (int, str)):
    our_score = 0
else:
    our_score = int(our_score)
```

**Time estimate**: 30-45 minutes

---

### Priority 2: Error Handling ⭐⭐ (High Impact, Medium Effort)

**Problems to solve:**
- No try-catch around API calls
- Network failures cause crashes
- No timeout handling
- Users see cryptic errors

**Solutions:**
1. Wrap API calls in try-catch blocks
2. Display friendly error messages instead of crashing
3. Add timeout handling for slow API responses
4. Log errors for debugging

**Code locations:**
- `get_next_game()` - lines 89-169
- API call at line ~115

**Example improvements:**
```python
try:
    response = http.get(url, ttl_seconds=300)
    if response.status_code != 200:
        return None
    data = response.json()
except Exception as e:
    print("API Error:", str(e))
    return None
```

**Time estimate**: 45-60 minutes

---

### Priority 3: Text Optimization ⭐ (Medium Impact, Low Effort)

**Problems to solve:**
- Long team names may overflow display
- Period text could be shorter ("Q3" vs "3rd Quarter")
- Magic numbers throughout code

**Solutions:**
1. Add text shortening for long team names
2. Abbreviate overtime periods (OT, 2OT, 3OT) - already done! ✅
3. Use constants for magic numbers (cache TTL, dimensions)

**Code locations:**
- Text rendering in `render_game_display()` - lines 377-555
- Constants at top of file

**Example improvements:**
```python
# Add constants
CACHE_TTL_SECONDS = 300  # 5 minutes
DISPLAY_WIDTH = 64
DISPLAY_HEIGHT = 32
MAX_TEAM_NAME_LENGTH = 6

# Shorten team names
def shorten_team_name(name, max_length=6):
    if len(name) <= max_length:
        return name
    return name[:max_length-1] + "."
```

**Time estimate**: 20-30 minutes

---

### Priority 4: Configuration ⭐ (Low Impact, Low Effort)

**Problems to solve:**
- Cache TTL is hardcoded
- No option to customize display
- Limited user control

**Solutions:**
1. Make cache TTL configurable (via schema)
2. Add option to show multiple upcoming games (future feature)
3. Make colors/fonts user-configurable (future feature)

**Code locations:**
- `get_schema()` - lines 584-596
- Cache calls throughout

**Example improvements:**
```python
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "team_id",
                name = "Team ID",
                desc = "ESPN Team ID",
                icon = "football",
            ),
            schema.Dropdown(
                id = "cache_ttl",
                name = "Refresh Rate",
                desc = "How often to fetch new data",
                icon = "clock",
                default = "300",
                options = [
                    schema.Option(display = "1 minute", value = "60"),
                    schema.Option(display = "5 minutes", value = "300"),
                    schema.Option(display = "10 minutes", value = "600"),
                ],
            ),
        ],
    )
```

**Time estimate**: 15-20 minutes

---

## 📋 **Proposed Implementation Phases**

### Phase 1: Defensive Programming (30-45 min)
**Goal**: Prevent crashes from bad API data

- [ ] Add null checks for scores, team names, period
- [ ] Add type validation (ensure scores are numbers)
- [ ] Add fallback values for missing data
- [ ] Extract magic numbers to constants
- [ ] Test with malformed mock data

**Test strategy**: Update test data to include edge cases

---

### Phase 2: Error Handling (45-60 min)
**Goal**: Graceful degradation on errors

- [ ] Wrap API calls in try-catch
- [ ] Add HTTP status code checks
- [ ] Add timeout handling (already exists via http.get ttl)
- [ ] Enhance error rendering function
- [ ] Add friendly error messages
- [ ] Test with network failures

**Test strategy**: Create test case that simulates API failure

---

### Phase 3: Text Optimization (20-30 min)
**Goal**: Better space utilization

- [ ] Create constants for dimensions
- [ ] Create constants for cache TTL
- [ ] Add team name shortening function (if needed)
- [ ] Review all text for opportunities to abbreviate
- [ ] Test with long team names

**Test strategy**: Test with longest possible team names

---

### Phase 4: Documentation (15-20 min)
**Goal**: Document defensive patterns

- [ ] Document error handling approach in DEVELOPMENT.md
- [ ] Update REQUIREMENTS.md with defensive patterns
- [ ] Add error handling examples
- [ ] Document constants and their purposes
- [ ] Add troubleshooting section

---

## 🚫 **What NOT to Change**

**Our Strengths - Keep These!**

1. ✅ **Keep single-game focus** (core feature - don't dilute)
2. ✅ **Keep simple configuration** (better UX than NCAAF)
3. ✅ **Keep test suite** (we're WAY ahead of NCAAF here!)
4. ✅ **Keep clean architecture** (their code is bloated with 100+ line dictionaries)
5. ✅ **Keep focused display** (1 mode is better than 6 modes to maintain)
6. ✅ **Keep minimal hardcoded data** (easier to maintain)

---

## 📊 **Comparison Summary**

| Feature | NCAAF Scores | HomeGame | Winner |
|---------|--------------|----------|--------|
| **Defensive Programming** | ✅ Excellent | ⚠️ Basic | NCAAF |
| **Error Handling** | ⚠️ Basic | ⚠️ Basic | Tie |
| **Test Suite** | ❌ None | ✅ Full Integration | HomeGame |
| **Code Complexity** | ⚠️ Very High | ✅ Clean | HomeGame |
| **Configuration** | ⚠️ Overwhelming | ✅ Simple | HomeGame |
| **Display Modes** | ⚠️ 6 modes | ✅ 1 focused | HomeGame |
| **Maintainability** | ❌ Poor | ✅ Excellent | HomeGame |
| **User Experience** | ⚠️ Complex | ✅ Simple | HomeGame |

---

## 🏆 **Bottom Line**

**NCAAF Scores Strengths**:
- Defensive programming (null checks, fallbacks)
- Extensive team color/logo mappings

**HomeGame Strengths**:
- Clean, maintainable code
- Comprehensive test suite with visual regression
- Focused, simple UX
- Modern development practices (linting, pre-commit hooks)

**Best Strategy**:
Adopt NCAAF's **defensive patterns** WITHOUT adopting their **complexity and bloat**.

---

## 🎯 **Next Steps**

1. **Review this plan** - Discuss priorities
2. **Choose phase to start** - Recommend Phase 1 (defensive programming)
3. **Implement incrementally** - One phase at a time
4. **Test thoroughly** - Run integration tests after each change
5. **Update golden images** - As visual output changes

---

## 📝 **Notes**

- All time estimates are conservative
- Each phase can be done independently
- Tests must pass before moving to next phase
- Keep git commits small and focused
- Update documentation as you go

---

**Created**: 2025-10-12
**Source**: Review of [NCAAF Scores](https://raw.githubusercontent.com/tidbyt/community/refs/heads/main/apps/ncaafscores/ncaaf_scores.star)
**Status**: Planning phase - not implemented yet
