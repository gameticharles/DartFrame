part of '../../dartframe.dart';

extension GeoDataFrameFunctions on GeoDataFrame {

    /// Adds a new feature to the GeoDataFrame.
  ///
  /// [geometry]: The GeoJSONGeometry for the feature.
  /// [properties]: The properties map for the feature.
  void addFeature(GeoJSONGeometry geometry, {Map<String, dynamic>? properties}) {
    // Create a new row for the DataFrame
    final List<dynamic> newRow = List.filled(columns.length, null);
    
    // Set the geometry in the appropriate column
    final geomIndex = columns.indexOf(geometryColumn);
    if (geomIndex >= 0) {
      newRow[geomIndex] = geometry;
    }
    
    // Add properties to the row
    if (properties != null) {
      for (var key in properties.keys) {
        final colIndex = columns.indexOf(key);
        if (colIndex >= 0) {
          newRow[colIndex] = properties[key];
        }
      }
    }
    
    // Add the row to the internal data structure
    _data.add(newRow);
    
    // Add any new properties as columns if they don't exist
    if (properties != null) {
      for (var key in properties.keys) {
        if (!columns.contains(key) && key != geometryColumn) {
          // Add the new column with default values
          addColumn(key, defaultValue: null);
          
          // Update the value in the new row for this column
          final colIndex = columns.indexOf(key);
          if (colIndex >= 0 && colIndex < _data.last.length) {
            _data.last[colIndex] = properties[key];
          }
        }
      }
    }
  }
  
  /// Deletes a feature at the specified index.
  void deleteFeature(int index) {
    if (index >= 0 && index < rows.length) {
      rows.removeAt(index);
    }
  }

  /// Deletes a feature by index.
  void deleteRow(int index) => deleteFeature( index);
  
    /// Gets a specific feature as a GeoJSONFeature.
  GeoJSONFeature? getFeature(int index) {
    if (index < 0 || index >= _data.length) {
      return null;
    }
    
    final row = _data[index];
    final geomIndex = columns.indexOf(geometryColumn);
    final geom = geomIndex >= 0 && geomIndex < row.length ? 
        row[geomIndex] : GeoJSONPoint([0, 0]);
    
    // Create properties
    final properties = <String, dynamic>{};
    for (int j = 0; j < columns.length; j++) {
      if (j != geomIndex && j < row.length) {
        properties[columns[j].toString()] = row[j];
      }
    }
    
    return GeoJSONFeature(
      geom is GeoJSONGeometry ? geom : GeoJSONPoint([0, 0]),
      properties: properties
    );
  }

  /// Finds features based on a query function.
  List<GeoJSONFeature> findFeatures(bool Function(GeoJSONFeature) query) {
    final features = <GeoJSONFeature>[];
    
    for (int i = 0; i < _data.length; i++) {
      final feature = getFeature(i);
      if (feature != null && query(feature)) {
        features.add(feature);
      }
    }
    
    return features;
  }

  /// Get the rows as List of Maps
  List<Map<String, dynamic>> get rowMaps => toRows();

  /// Converts the GeoDataFrame to a list of maps (rows).
  List<Map<String, dynamic>> toRows() {
    final result = <Map<String, dynamic>>[];
    
    for (int i = 0; i < _data.length; i++) {
      final row = _data[i];
      final Map<String, dynamic> rowMap = {};
      
      // Add all properties
      for (int j = 0; j < columns.length; j++) {
        if (j < row.length) {
          final colName = columns[j].toString();
          if (colName != geometryColumn) {
            rowMap[colName] = row[j];
          } else {
            // Handle geometry column specially
            final geom = row[j];
            if (geom is GeoJSONPoint) {
              final coords = geom.coordinates;
              if (coords.length >= 2) {
                rowMap['longitude'] = coords[0];
                rowMap['latitude'] = coords[1];
                if (coords.length >= 3) {
                  rowMap['elevation'] = coords[2];
                }
              }
            }
            // Add the geometry object itself
            rowMap[geometryColumn] = geom;
          }
        }
      }
      
      result.add(rowMap);
    }
    
    return result;
  }
  /// Renames the geometry column.
  ///
  /// [newName]: The new name for the geometry column.
  ///
  /// Returns a new GeoDataFrame with the renamed geometry column.
  GeoDataFrame renameGeometry(String newName) {
    if (newName == geometryColumn) {
      return this; // No change needed
    }
    
    // Create a copy of the DataFrame
    final newDf = copy();
    
    // Rename the column
    newDf.rename({geometryColumn: newName});
    
    // Create a new GeoDataFrame with the updated geometry column name
    return GeoDataFrame(newDf, geometryColumn: newName, crs: crs);
  }
  /// Sets a different column as the geometry column.
  ///
  /// [columnName]: The name of the column to set as the geometry column.
  ///
  /// Returns a new GeoDataFrame with the specified column as the geometry.
  GeoDataFrame setGeometry(String columnName) {
    if (columnName == geometryColumn) {
      return this; // No change needed
    }
    
    if (!columns.contains(columnName)) {
      throw ArgumentError('Column $columnName not found in DataFrame');
    }
    
    // Create a new GeoDataFrame with the updated geometry column
    return GeoDataFrame(this, geometryColumn: columnName, crs: crs);
  }
  
}