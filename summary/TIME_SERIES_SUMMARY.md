# Time Series Operations Implementation Summary

## Overview
Implemented comprehensive time series operations for DataFrame, including shift/lag/lead operations, time-based filtering, and timezone support.

## Files Created/Modified

### New Files
1. **lib/src/data_frame/time_series_advanced.dart** - Advanced time series operations
2. **lib/src/data_frame/timezone_operations.dart** - Timezone operations
3. **test/time_series_advanced_test.dart** - Tests for advanced time series operations (38 tests)
4. **test/timezone_operations_test.dart** - Tests for timezone operations (20 tests)

### Modified Files
1. **lib/src/data_frame/data_frame.dart** - Added part directives for new extensions
2. **lib/src/utils/time_series.dart** - Added `FrequencyUtils.addPeriods()` method
3. **todo.md** - Updated to reflect completed features

## Features Implemented

### 1. Shift Operations

#### `shift(periods, {axis, fillValue})`
Shift index by desired number of periods.

```dart
var df = DataFrame.fromMap({
  'A': [1, 2, 3, 4, 5],
  'B': [10, 20, 30, 40, 50]
});

// Shift down by 1 period
var shifted = df.shift(1);
// Result: [null, 1, 2, 3, 4]

// Shift up by 1 period
var shifted = df.shift(-1);
// Result: [2, 3, 4, 5, null]

// Custom fill value
var shifted = df.shift(1, fillValue: 0);
// Result: [0, 1, 2, 3, 4]
```

**Features:**
- Positive periods shift data down (add nulls at beginning)
- Negative periods shift data up (add nulls at end)
- Custom fill values supported
- Preserves all columns and index

#### `lag(periods, {fillValue})`
Lag values by n periods (equivalent to shift(n)).

```dart
var df = DataFrame.fromMap({'A': [1, 2, 3, 4, 5]});

var lagged = df.lag(1);  // [null, 1, 2, 3, 4]
var lagged2 = df.lag(2); // [null, null, 1, 2, 3]
```

**Use Cases:**
- Calculate period-over-period changes
- Create lagged features for machine learning
- Compare current values with historical values

#### `lead(periods, {fillValue})`
Lead values by n periods (equivalent to shift(-n)).

```dart
var df = DataFrame.fromMap({'A': [1, 2, 3, 4, 5]});

var led = df.lead(1);  // [2, 3, 4, 5, null]
var led2 = df.lead(2); // [3, 4, 5, null, null]
```

**Use Cases:**
- Look-ahead analysis
- Future value prediction
- Forward-looking indicators

### 2. Time Index Operations

#### `tshift(periods, {freq})`
Shift the time index using the index's frequency.

```dart
var df = DataFrame.fromMap(
  {'value': [1, 2, 3]},
  index: [
    DateTime(2024, 1, 1),
    DateTime(2024, 1, 2),
    DateTime(2024, 1, 3),
  ],
);

// Shift index by 1 day
var shifted = df.tshift(1, freq: 'D');
// Index becomes: [2024-01-02, 2024-01-03, 2024-01-04]
// Data remains: [1, 2, 3]
```

**Supported Frequencies:**
- `'D'` - Daily
- `'H'` - Hourly
- `'M'` - Monthly
- `'Y'` - Yearly
- `'W'` - Weekly

**Features:**
- Shifts only the index, not the data
- Requires DateTime index
- Supports positive and negative periods

#### `asfreq(freq, {method, fillValue})`
Convert TimeSeries to specified frequency.

```dart
var df = DataFrame.fromMap(
  {'value': [1, 2, 3]},
  index: [
    DateTime(2024, 1, 1),
    DateTime(2024, 1, 3),
    DateTime(2024, 1, 5),
  ],
);

// Convert to daily frequency with forward fill
var daily = df.asfreq('D', method: 'pad');
// Creates entries for Jan 2 and Jan 4 with filled values
```

**Fill Methods:**
- `'pad'` / `'ffill'` - Forward fill (use last known value)
- `'backfill'` / `'bfill'` - Backward fill (use next known value)
- `'nearest'` - Use nearest value in time

**Use Cases:**
- Regularize irregular time series
- Upsample to higher frequency
- Fill gaps in time series data

### 3. Time-Based Filtering

#### `atTime(time, {axis})`
Select values at particular time of day.

```dart
var df = DataFrame.fromMap(
  {'value': [1, 2, 3, 4]},
  index: [
    DateTime(2024, 1, 1, 9, 0),
    DateTime(2024, 1, 1, 12, 0),
    DateTime(2024, 1, 2, 9, 0),
    DateTime(2024, 1, 2, 15, 0),
  ],
);

// Select all rows at 9:00 AM
var morning = df.atTime('09:00:00');
// Returns rows with value [1, 3]
```

**Features:**
- Time format: 'HH:MM:SS' or 'HH:MM'
- Matches exact time across all dates
- Returns empty DataFrame if no matches

#### `betweenTime(startTime, endTime, {includeStart, includeEnd})`
Select values between particular times of day.

```dart
var df = DataFrame.fromMap(
  {'value': [1, 2, 3, 4, 5]},
  index: [
    DateTime(2024, 1, 1, 8, 0),
    DateTime(2024, 1, 1, 10, 0),
    DateTime(2024, 1, 1, 12, 0),
    DateTime(2024, 1, 1, 14, 0),
    DateTime(2024, 1, 1, 16, 0),
  ],
);

// Select business hours (9 AM to 5 PM)
var business = df.betweenTime('09:00:00', '17:00:00');
// Returns rows with value [2, 3, 4]
```

**Features:**
- Inclusive/exclusive boundaries
- Works across multiple dates
- Useful for filtering business hours, trading hours, etc.

#### `first(offset)` and `last(offset)`
Select first/last n periods of time series data.

```dart
var df = DataFrame.fromMap(
  {'value': [1, 2, 3, 4, 5]},
  index: [
    DateTime(2024, 1, 1),
    DateTime(2024, 1, 5),
    DateTime(2024, 1, 10),
    DateTime(2024, 1, 15),
    DateTime(2024, 1, 20),
  ],
);

// Select first 7 days
var firstWeek = df.first('7D');

// Select last 10 days
var lastTenDays = df.last('10D');
```

**Offset Format:**
- `'3D'` - 3 days
- `'2W'` - 2 weeks
- `'1M'` - 1 month
- `'5H'` - 5 hours

### 4. Timezone Operations

#### `tzLocalize(tz, {ambiguous, nonexistent})`
Localize timezone-naive DateTimeIndex to timezone-aware.

```dart
var df = DataFrame.fromMap(
  {'value': [1, 2, 3]},
  index: [
    DateTime(2024, 1, 1, 12, 0),
    DateTime(2024, 1, 2, 12, 0),
    DateTime(2024, 1, 3, 12, 0),
  ],
);

// Localize to UTC
var dfUtc = df.tzLocalize('UTC');

// Localize to New York time
var dfNy = df.tzLocalize('America/New_York');

// Localize with offset
var dfCustom = df.tzLocalize('+05:30');
```

**Supported Timezones:**
- UTC/GMT
- US: EST, EDT, CST, CDT, MST, MDT, PST, PDT
- Named: America/New_York, America/Chicago, America/Denver, America/Los_Angeles
- Europe: Europe/London, Europe/Paris, Europe/Berlin
- Asia: Asia/Tokyo, Asia/Shanghai, Asia/Singapore, Asia/Dubai
- Australia: Australia/Sydney
- Pacific: Pacific/Auckland
- Custom offsets: '+05:30', '-08:00'

**Features:**
- Converts timezone-naive to timezone-aware
- Throws error if already timezone-aware
- Requires DateTime index

#### `tzConvert(tz)`
Convert timezone-aware DateTimeIndex to another timezone.

```dart
var df = DataFrame.fromMap(
  {'value': [1, 2, 3]},
  index: [
    DateTime.utc(2024, 1, 1, 12, 0),
    DateTime.utc(2024, 1, 2, 12, 0),
    DateTime.utc(2024, 1, 3, 12, 0),
  ],
);

// Convert from UTC to New York time
var dfNy = df.tzConvert('America/New_York');

// Convert to Tokyo time
var dfTokyo = df.tzConvert('Asia/Tokyo');
```

**Features:**
- Converts between timezones
- Requires timezone-aware DateTime index
- Preserves data, only changes index

#### `tzNaive()`
Remove timezone information from timezone-aware DateTimeIndex.

```dart
var df = DataFrame.fromMap(
  {'value': [1, 2, 3]},
  index: [
    DateTime.utc(2024, 1, 1, 12, 0),
    DateTime.utc(2024, 1, 2, 12, 0),
    DateTime.utc(2024, 1, 3, 12, 0),
  ],
);

// Remove timezone info
var dfNaive = df.tzNaive();
```

**Use Cases:**
- Convert to local time for display
- Remove timezone for local processing
- Prepare data for systems that don't support timezones

## Real-World Use Cases

### 1. Financial Analysis
```dart
// Calculate returns with lag
var prices = DataFrame.fromMap({'price': [100, 102, 98, 105, 110]});
prices['prev_price'] = prices.lag(1)['price'].data;
prices['return'] = prices.eval('(price - prev_price) / prev_price * 100');
```

### 2. Trading Hours Filtering
```dart
var trades = DataFrame.fromMap(
  {'amount': [100, 200, 300, 400, 500]},
  index: [
    DateTime(2024, 1, 1, 8, 0),
    DateTime(2024, 1, 1, 10, 0),
    DateTime(2024, 1, 1, 14, 0),
    DateTime(2024, 1, 1, 18, 0),
    DateTime(2024, 1, 1, 20, 0),
  ],
);

// Filter to market hours (9:30 AM - 4:00 PM)
var marketHours = trades.betweenTime('09:30:00', '16:00:00');
```

### 3. Multi-Timezone Data Processing
```dart
// Convert trading data from UTC to local time
var trades = DataFrame.fromMap(
  {'price': [100, 101, 102]},
  index: [
    DateTime.utc(2024, 1, 1, 14, 30),
    DateTime.utc(2024, 1, 1, 15, 0),
    DateTime.utc(2024, 1, 1, 15, 30),
  ],
);

// Convert to New York time for analysis
var nyTrades = trades.tzConvert('America/New_York');

// Convert to Tokyo time for reporting
var tokyoTrades = trades.tzConvert('Asia/Tokyo');
```

### 4. Forecasting with Shifted Index
```dart
var sales = DataFrame.fromMap(
  {'actual': [100, 150, 120]},
  index: [
    DateTime(2024, 1, 1),
    DateTime(2024, 1, 2),
    DateTime(2024, 1, 3),
  ],
);

// Shift index forward for forecast comparison
var forecast = sales.tshift(1, freq: 'D');
// Index is now one day ahead, useful for comparing forecasts
```

## Test Coverage

### Advanced Time Series Tests (38 tests)
- ✅ shift() operations (7 tests)
- ✅ lag() operations (3 tests)
- ✅ lead() operations (3 tests)
- ✅ tshift() operations (5 tests)
- ✅ asfreq() operations (3 tests)
- ✅ atTime() operations (4 tests)
- ✅ betweenTime() operations (4 tests)
- ✅ first() operations (3 tests)
- ✅ last() operations (3 tests)
- ✅ Real-world use cases (3 tests)

### Timezone Operations Tests (20 tests)
- ✅ tzLocalize() operations (4 tests)
- ✅ tzConvert() operations (4 tests)
- ✅ tzNaive() operations (3 tests)
- ✅ Timezone offset parsing (3 tests)
- ✅ Common timezone names (3 tests)
- ✅ Real-world use cases (3 tests)

**Total: 58 tests, all passing ✅**

## Technical Implementation

### Key Design Decisions

1. **Extension-Based Architecture**
   - Used Dart extensions to add methods to DataFrame
   - Keeps code organized and maintainable
   - Allows for easy addition of new features

2. **Timezone Handling**
   - Simplified implementation using UTC offsets
   - Supports common timezones without external dependencies
   - Can be extended with `timezone` package for full IANA support

3. **Fill Methods**
   - Consistent fill method names across operations
   - Support for forward fill, backward fill, and nearest
   - Custom fill values for flexibility

4. **Error Handling**
   - Clear error messages for invalid operations
   - Type checking for DateTime index requirements
   - Validation of frequency strings and timezone names

### Performance Considerations

- Efficient list operations using Dart's built-in methods
- Minimal data copying where possible
- Index-based operations for fast lookups
- No external dependencies for core functionality

## Pandas Compatibility

These implementations closely follow pandas API:
- Method names match pandas conventions
- Parameter names and defaults align with pandas
- Behavior is consistent with pandas where applicable
- Documentation includes pandas-style examples

## Future Enhancements

Potential additions for future versions:
1. Business day calendars
2. Holiday calendars
3. Custom business day frequencies
4. Week/month/quarter/year end frequencies
5. Full IANA timezone database support (via `timezone` package)
6. DST (Daylight Saving Time) handling
7. More sophisticated frequency detection
8. Rolling window operations with time-based windows

## Dependencies

No new dependencies added. Uses only:
- Dart core libraries
- Existing DartFrame utilities (TimeSeriesIndex, FrequencyUtils)

## Breaking Changes

None. All new features are additive.

## Migration Guide

No migration needed. All existing code continues to work.

## Conclusion

Successfully implemented comprehensive time series operations for DataFrame, including:
- ✅ 9 new time-based operations (shift, lag, lead, tshift, asfreq, atTime, betweenTime, first, last)
- ✅ 3 new timezone operations (tzLocalize, tzConvert, tzNaive)
- ✅ 58 comprehensive tests
- ✅ Full documentation with examples
- ✅ Real-world use case demonstrations

All features are production-ready and fully tested.
