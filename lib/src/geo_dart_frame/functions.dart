part of '../../dartframe.dart';

extension GeoDataFrameFunctions on GeoDataFrame {

  /// Adds a new feature to the feature collection.
  ///
  /// [geometry]: The GeoJSONGeometry for the feature.
  /// [properties]: The properties map for the feature.
  void addFeature(GeoJSONGeometry geometry, {Map<String, dynamic>? properties}) {
    final feature = GeoJSONFeature(geometry, properties: properties ?? {});
    featureCollection.features.add(feature);
    
    // Update headers if new properties are introduced
    if (properties != null) {
      for (var key in properties.keys) {
        if (!headers.contains(key)) {
          headers.add(key);
        }
      }
    }
  }

  /// Deletes a feature by index.
  void deleteFeature(int index) {
    if (index >= 0 && index < featureCollection.features.length) {
      featureCollection.features.removeAt(index);
    }
  }

  /// Adds a new property to all features.
  void addProperty(String propertyName, {dynamic defaultValue}) {
    if (!headers.contains(propertyName)) {
      headers.add(propertyName);
    }
    
    for (var feature in featureCollection.features) {
      if (feature != null) {
        feature.properties ??= {};
        // Only set the value if it doesn't already exist
        if (!feature.properties!.containsKey(propertyName)) {
          feature.properties![propertyName] = defaultValue;
        }
      }
    }

    // Reinitialize the attributes DataFrame to include the new property
    _initializeAttributesWithSpatial(headers);
  }

  /// Deletes a property from all features.
  void deleteProperty(String propertyName) {
    headers.remove(propertyName);
    
    for (var feature in featureCollection.features) {
      if (feature != null && feature.properties != null) {
        feature.properties!.remove(propertyName);
      }
    }

    // Reinitialize the attributes DataFrame to include the new property
    _initializeAttributesWithSpatial(headers);
  }

  /// Updates a specific property in a feature.
  void updateProperty(int featureIndex, String propertyName, dynamic value) {
    if (featureIndex >= 0 && 
        featureIndex < featureCollection.features.length && 
        featureCollection.features[featureIndex] != null) {
      
      var feature = featureCollection.features[featureIndex]!;
      feature.properties ??= {};
      feature.properties![propertyName] = value;
      
      // Add to headers if it's a new property
      if (!headers.contains(propertyName)) {
        headers.add(propertyName);
      }

      // Reinitialize the attributes DataFrame to include the new property
      _initializeAttributesWithSpatial(headers);
    }
  }

  /// Gets a specific feature by index.
  GeoJSONFeature? getFeature(int index) {
    return (index >= 0 && index < featureCollection.features.length) 
        ? featureCollection.features[index] 
        : null;
  }

  /// Finds features based on a query function.
  List<GeoJSONFeature> findFeatures(
      bool Function(GeoJSONFeature) query) {
    return featureCollection.features
        .where((feature) => feature != null && query(feature))
        .cast<GeoJSONFeature>()
        .toList();
  }

  /// Converts the GeoDataFrame to a list of maps (rows) for backward compatibility.
  List<Map<String, dynamic>> toRows() {
    final rows = <Map<String, dynamic>>[];
    
    for (var feature in featureCollection.features) {
      if (feature != null) {
        final row = <String, dynamic>{};
        
        // Add properties
        if (feature.properties != null) {
          row.addAll(feature.properties!);
        }
        
        // Add geometry information if available
        if (feature.geometry is GeoJSONPoint) {
          final point = feature.geometry as GeoJSONPoint;
          final coords = point.coordinates;
          if (coords.length >= 2) {
            row['longitude'] = coords[0];
            row['latitude'] = coords[1];
            if (coords.length >= 3) {
              row['elevation'] = coords[2];
            }
          }
        }
        
        rows.add(row);
      }
    }
    
    return rows;
  }
}