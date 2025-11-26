# Advanced Features Quick Reference

## Merging & Joining

### mergeOrdered()
```dart
df.mergeOrdered(other, on: 'col', fillMethod: 'ffill')
```

### joinMultiple()
```dart
df.joinMultiple([df2, df3], on: 'key')
```

### joinWithSuffix()
```dart
df.joinWithSuffix(other, on: 'id', lsuffix: '_left', rsuffix: '_right')
```

## Grouping

### groupByEnhanced()
```dart
df.groupByEnhanced('col', dropna: true, sort: true)
```

### rollingEnhanced()
```dart
df.rollingEnhanced(3, center: true).mean()
```

### expandingEnhanced()
```dart
df.expandingEnhanced(minPeriods: 2).sum()
```

### ewmEnhanced()
```dart
df.ewmEnhanced(span: 3, adjust: true).mean()
```

## Time Series

### inferFreq()
```dart
df.inferFreq()  // Returns 'D', 'W', 'M', 'Y', 'H', 'T', 'S', or null
```

### toPeriod()
```dart
df.toPeriod('M')  // Convert DateTime index to period strings
```

### toTimestamp()
```dart
df.toTimestamp('M', how: 'start')  // Convert period strings to DateTime
```

### normalize()
```dart
df.normalize()  // Set all times to midnight
```

## Frequency Codes

- **D** - Daily
- **W** - Weekly  
- **M** - Monthly
- **Q** - Quarterly
- **Y** - Yearly
- **H** - Hourly
- **T** - Minutely
- **S** - Secondly

## Window Types

- **boxcar** - Uniform weighting (default)
- **triang** - Triangular window
- **blackman** - Blackman window

## Fill Methods

- **ffill** - Forward fill (propagate last valid observation forward)
- **bfill** - Backward fill (use next valid observation to fill gap)

## Join Types

- **inner** - Use intersection of keys
- **outer** - Use union of keys
- **left** - Use keys from left frame
- **right** - Use keys from right frame
