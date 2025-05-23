part of '../../dartframe.dart';

/// Accessor for datetime-like properties of Series data.
///
/// This class provides methods to extract components of DateTime objects
/// within a Series, such as year, month, day, etc.
///
/// It is accessed via the `.dt` property on a `Series` instance.
class SeriesDateTimeAccessor {
  final Series _series;

  /// Constructs a SeriesDateTimeAccessor for the given Series.
  SeriesDateTimeAccessor(this._series);

  // Helper function to process data and extract components
  Series _extractComponent(String componentName, dynamic Function(DateTime dt) extractor, {bool isDateTimeOutput = false}) {
    final missingRep = _series._missingRepresentation; // Use Series' helper
    List<dynamic> resultData = [];

    for (var value in _series.data) {
      if (_series._isMissing(value)) { // Use Series' helper
        resultData.add(missingRep);
      } else if (value is DateTime) {
        try {
          resultData.add(extractor(value));
        } catch (e) { // Should not happen with DateTime properties, but good for safety
          resultData.add(missingRep);
        }
      } else { // Not a DateTime and not identified as missing
        resultData.add(missingRep);
      }
    }
    return Series(
      resultData,
      name: '${_series.name}_$componentName',
      index: _series.index?.toList(), // Use toList() for safety
    );
  }

  /// Returns a Series containing the year of each DateTime.
  /// Non-DateTime values or missing values in the original Series result in
  /// the Series' missing value representation in the output.
  /// Example: `series.dt.year`
  Series get year => _extractComponent('year', (dt) => dt.year);

  /// Returns a Series containing the month (1-12) of each DateTime.
  /// Non-DateTime values or missing values result in the Series' missing value representation.
  /// Example: `series.dt.month`
  Series get month => _extractComponent('month', (dt) => dt.month);

  /// Returns a Series containing the day of the month (1-31) of each DateTime.
  /// Non-DateTime values or missing values result in the Series' missing value representation.
  /// Example: `series.dt.day`
  Series get day => _extractComponent('day', (dt) => dt.day);

  /// Returns a Series containing the hour (0-23) of each DateTime.
  /// Non-DateTime values or missing values result in the Series' missing value representation.
  /// Example: `series.dt.hour`
  Series get hour => _extractComponent('hour', (dt) => dt.hour);

  /// Returns a Series containing the minute (0-59) of each DateTime.
  /// Non-DateTime values or missing values result in the Series' missing value representation.
  /// Example: `series.dt.minute`
  Series get minute => _extractComponent('minute', (dt) => dt.minute);

  /// Returns a Series containing the second (0-59) of each DateTime.
  /// Non-DateTime values or missing values result in the Series' missing value representation.
  /// Example: `series.dt.second`
  Series get second => _extractComponent('second', (dt) => dt.second);

  /// Returns a Series containing the millisecond (0-999) of each DateTime.
  /// Non-DateTime values or missing values result in the Series' missing value representation.
  /// Example: `series.dt.millisecond`
  Series get millisecond => _extractComponent('millisecond', (dt) => dt.millisecond);

  /// Returns a Series containing the microsecond (0-999) of each DateTime.
  /// Non-DateTime values or missing values result in the Series' missing value representation.
  /// Example: `series.dt.microsecond`
  Series get microsecond => _extractComponent('microsecond', (dt) => dt.microsecond);

  /// Returns a Series containing the day of the week for each DateTime.
  /// (e.g., [DateTime.monday] is 1, ..., [DateTime.sunday] is 7).
  /// Non-DateTime values or missing values result in the Series' missing value representation.
  /// Example: `series.dt.weekday`
  Series get weekday => _extractComponent('weekday', (dt) => dt.weekday);

  /// Returns a Series containing the ordinal day of the year (1-365 or 1-366 for leap years) for each DateTime.
  /// Non-DateTime values or missing values result in the Series' missing value representation.
  /// Example: `series.dt.dayofyear`
  Series get dayofyear {
    return _extractComponent('dayofyear', (dt) {
      // Calculate day of year manually
      final firstDayOfYear = DateTime(dt.year, 1, 1);
      return dt.difference(firstDayOfYear).inDays + 1;
    });
  }
  
  /// Returns a Series containing only the date part (time set to 00:00:00.000000) of each DateTime.
  /// Non-DateTime values or missing values result in the Series' missing value representation.
  /// Example:
  /// ```dart
  /// var s = Series([DateTime(2023,1,10,14,30)], name: 'datetime');
  /// print(s.dt.date); // Output Series contains [DateTime(2023,1,10)]
  /// ```
  Series get date {
    return _extractComponent('date', (dt) {
      return DateTime(dt.year, dt.month, dt.day);
    }, isDateTimeOutput: true);
  }
}
