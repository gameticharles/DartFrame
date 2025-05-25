import 'package:test/test.dart';
import 'package:dartframe/dartframe.dart';

// Predefined WKT strings for testing
// These are illustrative and should cover the test scenarios.
final Map<String, String> testWKTs = {
  // Points
  'point_inside_poly': 'POINT (0.5 0.5)',
  'point_outside_poly': 'POINT (2 2)',
  'point_on_poly_boundary': 'POINT (0 0)', // On boundary of poly1
  'point_on_poly_boundary_non_vertex': 'POINT (0 0.5)', // On boundary of poly1, not a vertex
  'point_on_line1': 'POINT (0.5 0.5)', // On line1
  'point_not_on_line1': 'POINT (2 2)', // Not on line1
  'point_endpoint_of_line1': 'POINT (0 0)', // Endpoint of line1
  'point_in_hole': 'POINT (0.25 0.25)', // Assuming poly_hole is centered near here
  'point1': 'POINT (1 1)',
  'point2': 'POINT (2 0)',
  'point_identical_to_point1': 'POINT (1 1)',

  // LineStrings
  'line_contained_in_poly': 'LINESTRING (0.1 0.1, 0.2 0.2, 0.1 0.3)',
  'line_partially_in_poly': 'LINESTRING (0.5 0.5, 1.5 0.5)', // Half in poly1
  'line_on_poly_boundary': 'LINESTRING (0 0, 1 0)', // Edge of poly1
  'line_crossing_poly': 'LINESTRING (-0.5 0.5, 1.5 0.5)', // Crosses poly1
  'line1': 'LINESTRING (0 0, 1 1)', // Diagonal
  'line2': 'LINESTRING (1 1, 2 2)', // Extends line1
  'line_crosses_line1': 'LINESTRING (0 1, 1 0)', // Crosses line1 at (0.5, 0.5)
  'line_touches_line1_endpoint': 'LINESTRING (1 1, 2 0)', // Touches line1 at (1,1)
  'line_overlaps_line1_partial': 'LINESTRING (0.5 0.5, 1.5 1.5)', // Overlaps part of line1 and extends
  'line_disjoint_from_line1': 'LINESTRING (2 0, 3 1)',
  'line_touches_poly_boundary': 'LINESTRING (0 0, 0.5 0)', // Touches edge of poly1
  'line_endpoint_touches_poly_vertex': 'LINESTRING (0 0, -1 -1)', // Endpoint (0,0) touches vertex of poly1

  // Polygons
  'poly1': 'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))', // Unit square
  'poly_hole': 'POLYGON ((0.2 0.2, 0.8 0.2, 0.8 0.8, 0.2 0.8, 0.2 0.2))', // Smaller square, can be hole or contained poly
  'poly_disjoint': 'POLYGON ((2 0, 3 0, 3 1, 2 1, 2 0))', // Disjoint from poly1
  'poly2_overlaps_poly1': 'POLYGON ((0.5 0.5, 1.5 0.5, 1.5 1.5, 0.5 1.5, 0.5 0.5))', // Overlaps poly1
  'poly3_touches_poly1': 'POLYGON ((1 0, 2 0, 2 1, 1 1, 1 0))', // Touches poly1 at edge x=1
  'poly_touches_poly1_at_point': 'POLYGON ((1 1, 2 1, 2 2, 1 2, 1 1))', // Touches poly1 at point (1,1)
  'poly_identical_to_poly1': 'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))',
  'poly_shares_edge_with_poly1_exterior': 'POLYGON ((0 0, 1 0, 1 -1, 0 -1, 0 0))', // Shares edge (0,0)-(1,0)
  'poly4_contains_poly1_hole': 'POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0), (0.2 0.2, 0.8 0.2, 0.8 0.8, 0.2 0.8, 0.2 0.2))', // poly1 with poly_hole as a hole
  
  // Multi-Geometries
  'mpoint_in_poly': 'MULTIPOINT (0.1 0.1, 0.2 0.2)', // Intersects poly1
  'mpoint_one_in_poly': 'MULTIPOINT (0.1 0.1, 2 2)', // One point intersects poly1
  'mpoint_partially_in_poly': 'MULTIPOINT (0.1 0.1, 1.2 1.2)',
  'mline_in_poly': 'MULTILINESTRING ((0.1 0.1, 0.2 0.2), (0.3 0.3, 0.4 0.4))',
  'mpoly_in_poly': 'MULTIPOLYGON (((0.1 0.1, 0.2 0.1, 0.2 0.2, 0.1 0.2, 0.1 0.1)))',

  // Empty Geometries (WKT for empty geometries can be tricky/varied, use GEOS standards)
  'empty_point': 'POINT EMPTY',
  'empty_linestring': 'LINESTRING EMPTY',
  'empty_polygon': 'POLYGON EMPTY',
};

// Helper to create GeoJSONGeometry from WKT.
// In a real setup, this might involve a WKT parser or be part of GeoJSONGeometry itself.
// For testing, we assume `GeoJSONGeometry.fromWKT(wktString)` exists or use a placeholder.
// The actual `dartframe` library uses `GeoJSONGeometry.fromWKT(wkt)`.
GeoJSONGeometry GeoJSONGeometry_fromWKT(String wkt) {
  // This is a placeholder. Replace with actual WKT parsing if available.
  // For now, let's assume GeoJSONGeometry has a factory that can parse WKT.
  try {
    return GeoJSONGeometry.fromWKT(wkt);
  } catch (e) {
    // Fallback for empty geometries if fromWKT doesn't support "EMPTY" keyword directly
    // This is highly dependent on the specific WKT parser used by geojson_vi or dartframe
    if (wkt == 'POINT EMPTY') return GeoJSONPoint([]);
    if (wkt == 'LINESTRING EMPTY') return GeoJSONLineString([]);
    if (wkt == 'POLYGON EMPTY') return GeoJSONPolygon([]);
    rethrow;
  }
}

// Helper to create GeoSeries from a list of WKT strings.
GeoSeries GeoSeries_fromWKT(List<String?> wkts, {String name = 'geometry', List<dynamic>? index}) {
  final geoms = wkts.map((wkt) {
    if (wkt == null) return null;
    return GeoJSONGeometry_fromWKT(wkt);
  }).toList();
  return GeoSeries(geoms, name: name, index: index);
}


void main() {
  group('GeoSeries.contains() tests', () {
    // 1. Point in Polygon
    group('Point in Polygon scenarios', () {
      test('Point completely inside a polygon', () {
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final point = GeoJSONGeometry_fromWKT(testWKTs['point_inside_poly']!);
        final result = poly.contains(point);
        expect(result.toList(), [true]);
      });

      test('Point outside a polygon', () {
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final point = GeoJSONGeometry_fromWKT(testWKTs['point_outside_poly']!);
        final result = poly.contains(point);
        expect(result.toList(), [false]);
      });

      test('Point on the boundary of a polygon', () {
        // GEOS ST_Contains: A point on the boundary is considered contained.
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final point = GeoJSONGeometry_fromWKT(testWKTs['point_on_poly_boundary']!);
        final result = poly.contains(point);
        expect(result.toList(), [true]);
      });

      test('Point in a hole of a polygon', () {
        final polyWithHole = GeoSeries_fromWKT([testWKTs['poly4_contains_poly1_hole']!]);
        final pointInHole = GeoJSONGeometry_fromWKT(testWKTs['point_in_hole']!);
        final result = polyWithHole.contains(pointInHole);
        expect(result.toList(), [false]);
      });
    });

    // 2. LineString in Polygon
    group('LineString in Polygon scenarios', () {
      test('LineString completely inside a polygon', () {
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final line = GeoJSONGeometry_fromWKT(testWKTs['line_contained_in_poly']!);
        final result = poly.contains(line);
        expect(result.toList(), [true]);
      });

      test('LineString partially inside and partially outside', () {
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final line = GeoJSONGeometry_fromWKT(testWKTs['line_partially_in_poly']!);
        final result = poly.contains(line);
        expect(result.toList(), [false]);
      });

      test('LineString on the boundary of a polygon', () {
        // GEOS ST_Contains: A line on the boundary is considered contained.
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final line = GeoJSONGeometry_fromWKT(testWKTs['line_on_poly_boundary']!);
        final result = poly.contains(line);
        expect(result.toList(), [true]);
      });

      test('LineString crossing a polygon', () {
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final line = GeoJSONGeometry_fromWKT(testWKTs['line_crossing_poly']!);
        final result = poly.contains(line);
        expect(result.toList(), [false]); // Crosses means it's not fully contained
      });
    });

    // 3. Polygon in Polygon
    group('Polygon in Polygon scenarios', () {
      test('Polygon completely inside another polygon (as a hole definition, but used as geometry here)', () {
        final polyOuter = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final polyInner = GeoJSONGeometry_fromWKT(testWKTs['poly_hole']!);
        final result = polyOuter.contains(polyInner);
        expect(result.toList(), [true]);
      });

      test('Polygon partially overlapping another polygon', () {
        final poly1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final poly2 = GeoJSONGeometry_fromWKT(testWKTs['poly2_overlaps_poly1']!);
        final result = poly1.contains(poly2);
        expect(result.toList(), [false]);
      });

      test('Identical polygons', () {
        final poly1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final polyIdentical = GeoJSONGeometry_fromWKT(testWKTs['poly_identical_to_poly1']!);
        final result = poly1.contains(polyIdentical);
        expect(result.toList(), [true]);
      });
      
      test('Polygon B contained within Polygon A, B shares an edge with A exterior (still contained)', () {
        final polyA = GeoSeries_fromWKT([testWKTs['poly1']!]); // POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))
        // Polygon B shares edge (0,0)-(1,0) with polyA but is otherwise inside if its other points are within.
        // Example: POLYGON ((0 0, 1 0, 0.5 0.5, 0 0)) - this is a triangle sharing an edge and pointing inwards
        final polyB = GeoJSONGeometry_fromWKT('POLYGON ((0 0, 1 0, 0.5 0.5, 0 0))'); 
        final result = polyA.contains(polyB);
        expect(result.toList(), [true]);
      });


      test('Polygon B contained within a hole of Polygon A', () {
        final polyAWithHole = GeoSeries_fromWKT([testWKTs['poly4_contains_poly1_hole']!]);
        // poly_contained_in_hole is smaller than poly_hole and inside it
        final polyBInHole = GeoJSONGeometry_fromWKT('POLYGON ((0.25 0.25, 0.75 0.25, 0.75 0.75, 0.25 0.75, 0.25 0.25))');
        final result = polyAWithHole.contains(polyBInHole);
        expect(result.toList(), [false]);
      });
    });

    // 4. Multi-Geometries
    group('Multi-Geometries scenarios', () {
      test('MultiPoint fully in Polygon', () {
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final mpoint = GeoJSONGeometry_fromWKT(testWKTs['mpoint_in_poly']!);
        final result = poly.contains(mpoint);
        expect(result.toList(), [true]);
      });

      test('MultiPoint partially in Polygon', () {
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final mpoint = GeoJSONGeometry_fromWKT(testWKTs['mpoint_partially_in_poly']!);
        final result = poly.contains(mpoint);
        expect(result.toList(), [false]);
      });
      
      test('Polygon contains MultiPoint (all points inside)', () {
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final mpoint = GeoJSONGeometry_fromWKT(testWKTs['mpoint_in_poly']!);
        final result = poly.contains(mpoint);
        expect(result.toList(), [true]);
      });

      test('MultiLineString fully in Polygon', () {
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final mline = GeoJSONGeometry_fromWKT(testWKTs['mline_in_poly']!);
        final result = poly.contains(mline);
        expect(result.toList(), [true]);
      });

      test('MultiPolygon fully in Polygon', () {
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final mpoly = GeoJSONGeometry_fromWKT(testWKTs['mpoly_in_poly']!);
        final result = poly.contains(mpoly);
        expect(result.toList(), [true]);
      });
    });

    // 5. Empty Geometries
    group('Empty Geometries scenarios', () {
      // GEOS behavior: nothing contains an empty geometry, and an empty geometry cannot contain anything.
      // ST_Contains(A, B) is true if B lies in the interior or on the boundary of A.
      // If B is empty, it has no interior or boundary points, so it cannot be contained.
      // If A is empty, it has no interior or boundary to host B.
      test('Polygon.contains(EmptyPoint)', () {
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final emptyPoint = GeoJSONGeometry_fromWKT(testWKTs['empty_point']!);
        final result = poly.contains(emptyPoint);
        expect(result.toList(), [false]); 
      });

      test('EmptyPolygon.contains(Point)', () {
        final emptyPoly = GeoSeries_fromWKT([testWKTs['empty_polygon']!]);
        final point = GeoJSONGeometry_fromWKT(testWKTs['point1']!);
        final result = emptyPoly.contains(point);
        expect(result.toList(), [false]);
      });

      test('EmptyPolygon.contains(EmptyPoint)', () {
        final emptyPoly = GeoSeries_fromWKT([testWKTs['empty_polygon']!]);
        final emptyPoint = GeoJSONGeometry_fromWKT(testWKTs['empty_point']!);
        final result = emptyPoly.contains(emptyPoint);
        expect(result.toList(), [false]);
      });
    });

    // 6. `other` as `GeoSeries`
    group('`other` as GeoSeries scenarios', () {
      test('Series: poly1.contains(point_inside_poly)', () {
        final polySeries = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final pointSeries = GeoSeries_fromWKT([testWKTs['point_inside_poly']!]);
        final result = polySeries.contains(pointSeries);
        expect(result.toList(), [true]);
      });

      test('Series: [poly1, poly_disjoint] contains [point_inside_poly, point_outside_poly_from_disjoint]', () {
        final polySeries = GeoSeries_fromWKT([testWKTs['poly1']!, testWKTs['poly_disjoint']!]);
        // point_outside_poly_from_disjoint is actually inside poly_disjoint
        final pointSeries = GeoSeries_fromWKT([testWKTs['point_inside_poly']!, 'POINT (2.5 0.5)']);
        final result = polySeries.contains(pointSeries);
        expect(result.toList(), [true, true]);
      });
      
      test('Series: [poly1, poly1] contains [point_inside_poly, point_outside_poly]', () {
        final polySeries = GeoSeries_fromWKT([testWKTs['poly1']!, testWKTs['poly1']!]);
        final pointSeries = GeoSeries_fromWKT([testWKTs['point_inside_poly']!, testWKTs['point_outside_poly']!]);
        final result = polySeries.contains(pointSeries);
        expect(result.toList(), [true, false]);
      });

      test('Series with different lengths (polySeries longer)', () {
        final polySeries = GeoSeries_fromWKT([testWKTs['poly1']!, testWKTs['poly_disjoint']!]);
        final pointSeries = GeoSeries_fromWKT([testWKTs['point_inside_poly']!]);
        final result = polySeries.contains(pointSeries);
        // Expect result to be length of polySeries, with second element false due to no corresponding point.
        expect(result.toList(), [true, false]); 
        expect(result.index.length, 2);
      });

      test('Series with different lengths (pointSeries longer)', () {
        final polySeries = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final pointSeries = GeoSeries_fromWKT([testWKTs['point_inside_poly']!, testWKTs['point_outside_poly']!]);
        final result = polySeries.contains(pointSeries);
        // Expect result to be length of polySeries.
        expect(result.toList(), [true]);
        expect(result.index.length, 1);
      });

      test('Series with null geometry in calling series', () {
        final polySeries = GeoSeries_fromWKT([testWKTs['poly1']!, null]);
        final pointSeries = GeoSeries_fromWKT([testWKTs['point_inside_poly']!, testWKTs['point1']!]);
        final result = polySeries.contains(pointSeries);
        expect(result.toList(), [true, false]); // null geom can't contain anything
      });

      test('Series with null geometry in other series', () {
        final polySeries = GeoSeries_fromWKT([testWKTs['poly1']!, testWKTs['poly1']!]);
        final pointSeries = GeoSeries_fromWKT([testWKTs['point_inside_poly']!, null]);
        final result = polySeries.contains(pointSeries);
        expect(result.toList(), [true, false]); // cannot contain a null geom
      });
    });
  });

  group('GeoSeries.intersects() tests', () {
    // 1. Point Intersections
    group('Point Intersections scenarios', () {
      test('Point intersects Point (identical)', () {
        final p1 = GeoSeries_fromWKT([testWKTs['point1']!]);
        final p2 = GeoJSONGeometry_fromWKT(testWKTs['point_identical_to_point1']!);
        final result = p1.intersects(p2);
        expect(result.toList(), [true]);
      });

      test('Point intersects LineString (point on line)', () {
        final line = GeoSeries_fromWKT([testWKTs['line1']!]); // LINESTRING (0 0, 1 1)
        final point = GeoJSONGeometry_fromWKT(testWKTs['point_on_line1']!); // POINT (0.5 0.5)
        final result = line.intersects(point); // Line intersects Point
        expect(result.toList(), [true]);

        final pointSeries = GeoSeries_fromWKT([testWKTs['point_on_line1']!]);
        final lineGeom = GeoJSONGeometry_fromWKT(testWKTs['line1']!);
        final result2 = pointSeries.intersects(lineGeom); // Point intersects Line
         expect(result2.toList(), [true]);
      });

      test('Point intersects Polygon (point in polygon)', () {
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final point = GeoJSONGeometry_fromWKT(testWKTs['point_inside_poly']!);
        final result = poly.intersects(point);
        expect(result.toList(), [true]);
      });
       test('Point intersects Polygon (point on boundary)', () {
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final point = GeoJSONGeometry_fromWKT(testWKTs['point_on_poly_boundary']!);
        final result = poly.intersects(point);
        expect(result.toList(), [true]);
      });

      test('Point does not intersect LineString', () {
        final line = GeoSeries_fromWKT([testWKTs['line1']!]);
        final point = GeoJSONGeometry_fromWKT(testWKTs['point_not_on_line1']!);
        final result = line.intersects(point);
        expect(result.toList(), [false]);
      });

      test('Point does not intersect Polygon', () {
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final point = GeoJSONGeometry_fromWKT(testWKTs['point_outside_poly']!);
        final result = poly.intersects(point);
        expect(result.toList(), [false]);
      });
    });

    // 2. LineString Intersections
    group('LineString Intersections scenarios', () {
      test('LineString intersects LineString (crossing)', () {
        final line1 = GeoSeries_fromWKT([testWKTs['line1']!]);
        final line2 = GeoJSONGeometry_fromWKT(testWKTs['line_crosses_line1']!);
        final result = line1.intersects(line2);
        expect(result.toList(), [true]);
      });

      test('LineString touches LineString (at endpoint)', () {
        final line1 = GeoSeries_fromWKT([testWKTs['line1']!]);
        final line2 = GeoJSONGeometry_fromWKT(testWKTs['line_touches_line1_endpoint']!);
        final result = line1.intersects(line2);
        expect(result.toList(), [true]);
      });
      
      test('LineString overlaps LineString (partially)', () {
        final line1 = GeoSeries_fromWKT([testWKTs['line1']!]); // (0 0, 1 1)
        final line2 = GeoJSONGeometry_fromWKT(testWKTs['line_overlaps_line1_partial']!); // (0.5 0.5, 1.5 1.5)
        final result = line1.intersects(line2);
        expect(result.toList(), [true]);
      });

      test('LineString overlaps LineString (fully, line1 contains line2)', () {
        final line1 = GeoSeries_fromWKT([testWKTs['line1']!]); // (0 0, 1 1)
        final line2 = GeoJSONGeometry_fromWKT('LINESTRING (0.25 0.25, 0.75 0.75)'); 
        final result = line1.intersects(line2);
        expect(result.toList(), [true]);
      });


      test('LineString disjoint from LineString', () {
        final line1 = GeoSeries_fromWKT([testWKTs['line1']!]);
        final line2 = GeoJSONGeometry_fromWKT(testWKTs['line_disjoint_from_line1']!);
        final result = line1.intersects(line2);
        expect(result.toList(), [false]);
      });

      test('LineString intersects Polygon (crosses)', () {
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final line = GeoJSONGeometry_fromWKT(testWKTs['line_crossing_poly']!);
        final result = poly.intersects(line);
        expect(result.toList(), [true]);
      });

      test('LineString contained in Polygon', () {
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final line = GeoJSONGeometry_fromWKT(testWKTs['line_contained_in_poly']!);
        final result = poly.intersects(line);
        expect(result.toList(), [true]);
      });

      test('LineString touches Polygon boundary', () {
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final line = GeoJSONGeometry_fromWKT(testWKTs['line_touches_poly_boundary']!);
        final result = poly.intersects(line);
        expect(result.toList(), [true]);
      });
    });

    // 3. Polygon Intersections
    group('Polygon Intersections scenarios', () {
      test('Polygon overlaps Polygon', () {
        final poly1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final poly2 = GeoJSONGeometry_fromWKT(testWKTs['poly2_overlaps_poly1']!);
        final result = poly1.intersects(poly2);
        expect(result.toList(), [true]);
      });

      test('Polygon touches Polygon boundary', () {
        final poly1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final poly2 = GeoJSONGeometry_fromWKT(testWKTs['poly3_touches_poly1']!);
        final result = poly1.intersects(poly2);
        expect(result.toList(), [true]);
      });

      test('Polygon contains Polygon', () {
        final polyOuter = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final polyInner = GeoJSONGeometry_fromWKT(testWKTs['poly_hole']!); // poly_hole is smaller and inside poly1
        final result = polyOuter.intersects(polyInner);
        expect(result.toList(), [true]);
      });

      test('Polygon disjoint from Polygon', () {
        final poly1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final poly2 = GeoJSONGeometry_fromWKT(testWKTs['poly_disjoint']!);
        final result = poly1.intersects(poly2);
        expect(result.toList(), [false]);
      });

      test('Identical polygons', () {
        final poly1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final polyIdentical = GeoJSONGeometry_fromWKT(testWKTs['poly_identical_to_poly1']!);
        final result = poly1.intersects(polyIdentical);
        expect(result.toList(), [true]);
      });
    });

    // 4. Multi-Geometries
    group('Multi-Geometries scenarios', () {
      test('MultiPoint intersects Polygon (one point inside)', () {
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final mpoint = GeoJSONGeometry_fromWKT(testWKTs['mpoint_one_in_poly']!);
        final result = poly.intersects(mpoint);
        expect(result.toList(), [true]);
      });

      test('MultiLineString intersects LineString (one line touches)', () {
        final line = GeoSeries_fromWKT([testWKTs['line1']!]); // (0,0)-(1,1)
        final mline = GeoJSONGeometry_fromWKT('MULTILINESTRING ((1 1, 2 0), (3 3, 4 4))'); // First line touches line1
        final result = line.intersects(mline);
        expect(result.toList(), [true]);
      });

      test('MultiPolygon intersects Polygon (one poly overlaps)', () {
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final mpoly = GeoJSONGeometry_fromWKT(
            'MULTIPOLYGON (((0.5 0.5, 1.5 0.5, 1.5 1.5, 0.5 1.5, 0.5 0.5)), ((2 2, 3 2, 3 3, 2 3, 2 2)))');
        final result = poly.intersects(mpoly);
        expect(result.toList(), [true]);
      });
    });

    // 5. Empty Geometries
    group('Empty Geometries scenarios', () {
      // GEOS behavior: empty geometries do not intersect anything.
      test('Polygon.intersects(EmptyPoint)', () {
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final emptyPoint = GeoJSONGeometry_fromWKT(testWKTs['empty_point']!);
        final result = poly.intersects(emptyPoint);
        expect(result.toList(), [false]);
      });

      test('EmptyPolygon.intersects(Point)', () {
        final emptyPoly = GeoSeries_fromWKT([testWKTs['empty_polygon']!]);
        final point = GeoJSONGeometry_fromWKT(testWKTs['point1']!);
        final result = emptyPoly.intersects(point);
        expect(result.toList(), [false]);
      });

      test('EmptyPolygon.intersects(EmptyPolygon)', () {
        final emptyPoly1 = GeoSeries_fromWKT([testWKTs['empty_polygon']!]);
        final emptyPoly2 = GeoJSONGeometry_fromWKT(testWKTs['empty_polygon']!);
        final result = emptyPoly1.intersects(emptyPoly2);
        expect(result.toList(), [false]);
      });
    });

    // 6. `other` as `GeoSeries`
    group('`other` as GeoSeries scenarios', () {
      test('Series: poly1.intersects(poly2_overlaps_poly1)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['poly2_overlaps_poly1']!]);
        final result = s1.intersects(s2);
        expect(result.toList(), [true]);
      });

      test('Series: [poly1, poly_disjoint] intersects [poly2_overlaps_poly1, point1]', () {
        // poly1 intersects poly2_overlaps_poly1 -> true
        // poly_disjoint does not intersect point1 -> false
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!, testWKTs['poly_disjoint']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['poly2_overlaps_poly1']!, testWKTs['point1']!]);
        final result = s1.intersects(s2);
        expect(result.toList(), [true, false]);
      });
      
      test('Series with different lengths (s1 longer)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!, testWKTs['poly_disjoint']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['poly2_overlaps_poly1']!]);
        final result = s1.intersects(s2);
        expect(result.toList(), [true, false]); // Second element of s1 has no counterpart
        expect(result.index.length, 2);
      });

      test('Series with different lengths (s2 longer)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['poly2_overlaps_poly1']!, testWKTs['poly_disjoint']!]);
        final result = s1.intersects(s2);
        expect(result.toList(), [true]); // Result matches length of s1
        expect(result.index.length, 1);
      });

      test('Series with null geometry in calling series', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!, null]);
        final s2 = GeoSeries_fromWKT([testWKTs['poly2_overlaps_poly1']!, testWKTs['poly_disjoint']!]);
        final result = s1.intersects(s2);
        expect(result.toList(), [true, false]); // null geom intersects nothing
      });

      test('Series with null geometry in other series', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!, testWKTs['poly_disjoint']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['poly2_overlaps_poly1']!, null]);
        final result = s1.intersects(s2);
        expect(result.toList(), [true, false]); // poly_disjoint intersects null -> false
      });
    });
  });


// Note: This test suite relies on the GEOS definition of "intersects".
// ST_Intersects(A, B) is true if the geometries "spatially intersect" - (share any portion of space).
// This is equivalent to DE-9IM not being 'FF*FF****'.
// Touching is considered an intersection. Overlapping is an intersection. Containing is an intersection.
// Empty geometries do not intersect anything.

  group('GeoSeries.geom_equals() (topological equality) tests', () {
    // 1. Identical Simple Geometries
    group('Identical Simple Geometries scenarios', () {
      test('Point geom_equals Point (identical)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['point1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['point_identical_to_point1']!);
        final result = s1.geom_equals(g2);
        expect(result.toList(), [true]);
      });

      test('LineString geom_equals LineString (identical)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['line1']!);
        final result = s1.geom_equals(g2);
        expect(result.toList(), [true]);
      });

      test('Polygon geom_equals Polygon (identical)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['poly_identical_to_poly1']!);
        final result = s1.geom_equals(g2);
        expect(result.toList(), [true]);
      });
    });

    // 2. Topologically Equal (Different Representations)
    group('Topologically Equal (Different Representations) scenarios', () {
      test('Polygon geom_equals Polygon (different starting vertex)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!]); // ((0 0, 1 0, 1 1, 0 1, 0 0))
        final g2 = GeoJSONGeometry_fromWKT('POLYGON ((1 0, 1 1, 0 1, 0 0, 1 0))');
        final result = s1.geom_equals(g2);
        expect(result.toList(), [true]);
      });

      test('LineString geom_equals LineString (reversed order of points)', () {
        final s1 = GeoSeries_fromWKT(['LINESTRING (0 0, 1 1)']);
        final g2 = GeoJSONGeometry_fromWKT('LINESTRING (1 1, 0 0)');
        final result = s1.geom_equals(g2);
        expect(result.toList(), [true]);
      });
      
      test('LineString geom_equals LineString (with extra collinear point)', () {
        final s1 = GeoSeries_fromWKT(['LINESTRING (0 0, 2 2)']);
        final g2 = GeoJSONGeometry_fromWKT('LINESTRING (0 0, 1 1, 2 2)'); // (1,1) is collinear
        final result = s1.geom_equals(g2);
        expect(result.toList(), [true]);
      });

      test('LineString geom_equals MultiLineString (single identical component)', () {
        final s1 = GeoSeries_fromWKT(['LINESTRING (0 0, 1 1)']);
        final g2 = GeoJSONGeometry_fromWKT('MULTILINESTRING ((0 0, 1 1))');
        final result = s1.geom_equals(g2);
        expect(result.toList(), [true]);
      });

      test('Polygon geom_equals MultiPolygon (single identical component)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final g2 = GeoJSONGeometry_fromWKT('MULTIPOLYGON (((0 0, 1 0, 1 1, 0 1, 0 0)))');
        final result = s1.geom_equals(g2);
        expect(result.toList(), [true]);
      });
    });

    // 3. Not Topologically Equal
    group('Not Topologically Equal scenarios', () {
      test('Point not geom_equals Point (different)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['point1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['point2']!);
        final result = s1.geom_equals(g2);
        expect(result.toList(), [false]);
      });

      test('LineString not geom_equals LineString (different length/shape)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line1']!]); // (0 0, 1 1)
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['line2']!); // (1 1, 2 2) - shares endpoint but not equal
        final result = s1.geom_equals(g2);
        expect(result.toList(), [false]);
      });

      test('Polygon not geom_equals Polygon (different area/shape)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['poly_disjoint']!);
        final result = s1.geom_equals(g2);
        expect(result.toList(), [false]);
      });

      test('Polygon not geom_equals LineString (different dimension)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final g2 = GeoJSONGeometry_fromWKT('LINESTRING (0 0, 1 0, 1 1, 0 1, 0 0)'); // Closed LineString
        final result = s1.geom_equals(g2);
        expect(result.toList(), [false]);
      });
    });

    // 4. Multi-Geometries
    group('Multi-Geometries scenarios for geom_equals()', () {
      test('MultiPoint geom_equals MultiPoint (identical, same order)', () {
        final s1 = GeoSeries_fromWKT(['MULTIPOINT (0 0, 1 1)']);
        final g2 = GeoJSONGeometry_fromWKT('MULTIPOINT (0 0, 1 1)');
        final result = s1.geom_equals(g2);
        expect(result.toList(), [true]);
      });

      test('MultiPoint geom_equals MultiPoint (same points, different order)', () {
        final s1 = GeoSeries_fromWKT(['MULTIPOINT (0 0, 1 1)']);
        final g2 = GeoJSONGeometry_fromWKT('MULTIPOINT (1 1, 0 0)');
        final result = s1.geom_equals(g2);
        expect(result.toList(), [true]);
      });
      
      test('MultiPoint not geom_equals MultiPoint (different points)', () {
        final s1 = GeoSeries_fromWKT(['MULTIPOINT (0 0, 1 1)']);
        final g2 = GeoJSONGeometry_fromWKT('MULTIPOINT (0 0, 2 2)');
        final result = s1.geom_equals(g2);
        expect(result.toList(), [false]);
      });

      test('MultiPolygon geom_equals MultiPolygon (identical components, same order)', () {
        final s1 = GeoSeries_fromWKT(['MULTIPOLYGON (((0 0, 1 0, 1 1, 0 1, 0 0)), ((2 0, 3 0, 3 1, 2 1, 2 0)))']);
        final g2 = GeoJSONGeometry_fromWKT('MULTIPOLYGON (((0 0, 1 0, 1 1, 0 1, 0 0)), ((2 0, 3 0, 3 1, 2 1, 2 0)))');
        final result = s1.geom_equals(g2);
        expect(result.toList(), [true]);
      });

      test('MultiPolygon geom_equals MultiPolygon (identical components, different order)', () {
        final s1 = GeoSeries_fromWKT(['MULTIPOLYGON (((0 0, 1 0, 1 1, 0 1, 0 0)), ((2 0, 3 0, 3 1, 2 1, 2 0)))']);
        final g2 = GeoJSONGeometry_fromWKT('MULTIPOLYGON (((2 0, 3 0, 3 1, 2 1, 2 0)), ((0 0, 1 0, 1 1, 0 1, 0 0)))');
        final result = s1.geom_equals(g2);
        expect(result.toList(), [true]);
      });
    });

    // 5. Empty Geometries
    group('Empty Geometries scenarios for geom_equals()', () {
      // GEOS: Two geometries are topologically equal if their DE-9IM intersection matrices are identical.
      // Empty geometries of the same dimension are equal. Empty geometries of different dimensions are not.
      test('EmptyPoint.geom_equals(EmptyPoint)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['empty_point']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['empty_point']!);
        final result = s1.geom_equals(g2);
        expect(result.toList(), [true]);
      });

      test('EmptyLineString.geom_equals(EmptyLineString)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['empty_linestring']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['empty_linestring']!);
        final result = s1.geom_equals(g2);
        expect(result.toList(), [true]);
      });

      test('EmptyPolygon.geom_equals(EmptyPolygon)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['empty_polygon']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['empty_polygon']!);
        final result = s1.geom_equals(g2);
        expect(result.toList(), [true]);
      });

      test('EmptyPoint.geom_equals(EmptyLineString)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['empty_point']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['empty_linestring']!);
        final result = s1.geom_equals(g2);
        // GEOS: Empty geometries of different dimensions are not equal.
        expect(result.toList(), [false]);
      });
       test('EmptyPoint.geom_equals(EmptyPolygon)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['empty_point']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['empty_polygon']!);
        final result = s1.geom_equals(g2);
        expect(result.toList(), [false]);
      });
      test('EmptyLineString.geom_equals(EmptyPolygon)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['empty_linestring']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['empty_polygon']!);
        final result = s1.geom_equals(g2);
        expect(result.toList(), [false]);
      });

      test('Point.geom_equals(EmptyPoint)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['point1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['empty_point']!);
        final result = s1.geom_equals(g2);
        expect(result.toList(), [false]);
      });
    });

    // 6. `other` as `GeoSeries`
    group('`other` as GeoSeries scenarios for geom_equals()', () {
      test('Series: point1.geom_equals(point_identical_to_point1)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['point1']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['point_identical_to_point1']!]);
        final result = s1.geom_equals(s2);
        expect(result.toList(), [true]);
      });

      test('Series: [point1, line1] geom_equals [point_identical_to_point1, line1_reversed]', () {
        final s1 = GeoSeries_fromWKT([testWKTs['point1']!, testWKTs['line1']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['point_identical_to_point1']!, 'LINESTRING (1 1, 0 0)']);
        final result = s1.geom_equals(s2);
        expect(result.toList(), [true, true]);
      });
      
      test('Series with different lengths (s1 longer)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['point1']!, testWKTs['line1']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['point_identical_to_point1']!]);
        final result = s1.geom_equals(s2);
        // point1.geom_equals(point_identical_to_point1) -> true
        // line1.geom_equals(no_geom) -> false (as per current padding logic)
        expect(result.toList(), [true, false]); 
        expect(result.index.length, 2);
      });

      test('Series with different lengths (s2 longer)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['point1']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['point_identical_to_point1']!, testWKTs['line1']!]);
        final result = s1.geom_equals(s2);
        expect(result.toList(), [true]); // Result matches length of s1
        expect(result.index.length, 1);
      });

      test('Series with null geometry in calling series for geom_equals', () {
        final s1 = GeoSeries_fromWKT([testWKTs['point1']!, null]);
        final s2 = GeoSeries_fromWKT([testWKTs['point_identical_to_point1']!, testWKTs['line1']!]);
        final result = s1.geom_equals(s2);
        expect(result.toList(), [true, false]); // null geom equals nothing -> false
      });

      test('Series with null geometry in other series for geom_equals', () {
        final s1 = GeoSeries_fromWKT([testWKTs['point1']!, testWKTs['line1']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['point_identical_to_point1']!, null]);
        final result = s1.geom_equals(s2);
        expect(result.toList(), [true, false]); // line1 equals null -> false
      });
    });
  });

  group('GeoSeries.disjoint() tests', () {
    // 1. Point Disjoint
    group('Point Disjoint scenarios', () {
      test('Point disjoint from Point (different points)', () {
        final p1 = GeoSeries_fromWKT([testWKTs['point1']!]);
        final p2 = GeoJSONGeometry_fromWKT(testWKTs['point2']!);
        final result = p1.disjoint(p2);
        expect(result.toList(), [true]);
      });

      test('Point not disjoint from Point (identical)', () {
        final p1 = GeoSeries_fromWKT([testWKTs['point1']!]);
        final p2 = GeoJSONGeometry_fromWKT(testWKTs['point_identical_to_point1']!);
        final result = p1.disjoint(p2);
        expect(result.toList(), [false]); // They intersect
      });

      test('Point disjoint from LineString', () {
        final point = GeoSeries_fromWKT([testWKTs['point_not_on_line1']!]);
        final line = GeoJSONGeometry_fromWKT(testWKTs['line1']!);
        final result = point.disjoint(line);
        expect(result.toList(), [true]);
      });

      test('Point not disjoint from LineString (point on line)', () {
        final point = GeoSeries_fromWKT([testWKTs['point_on_line1']!]);
        final line = GeoJSONGeometry_fromWKT(testWKTs['line1']!);
        final result = point.disjoint(line);
        expect(result.toList(), [false]); // They intersect
      });

      test('Point disjoint from Polygon', () {
        final point = GeoSeries_fromWKT([testWKTs['point_outside_poly']!]);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = point.disjoint(poly);
        expect(result.toList(), [true]);
      });

      test('Point not disjoint from Polygon (point in polygon)', () {
        final point = GeoSeries_fromWKT([testWKTs['point_inside_poly']!]);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = point.disjoint(poly);
        expect(result.toList(), [false]); // Intersects (contains)
      });
      
      test('Point not disjoint from Polygon (point on boundary)', () {
        final point = GeoSeries_fromWKT([testWKTs['point_on_poly_boundary']!]);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = point.disjoint(poly);
        expect(result.toList(), [false]); // Intersects (touches)
      });
    });

    // 2. LineString Disjoint
    group('LineString Disjoint scenarios', () {
      test('LineString disjoint from LineString', () {
        final line1 = GeoSeries_fromWKT([testWKTs['line1']!]);
        final line2 = GeoJSONGeometry_fromWKT(testWKTs['line_disjoint_from_line1']!);
        final result = line1.disjoint(line2);
        expect(result.toList(), [true]);
      });

      test('LineString not disjoint from LineString (crossing)', () {
        final line1 = GeoSeries_fromWKT([testWKTs['line1']!]);
        final line2 = GeoJSONGeometry_fromWKT(testWKTs['line_crosses_line1']!);
        final result = line1.disjoint(line2);
        expect(result.toList(), [false]); // Intersects
      });

      test('LineString not disjoint from LineString (touches at endpoint)', () {
        final line1 = GeoSeries_fromWKT([testWKTs['line1']!]);
        final line2 = GeoJSONGeometry_fromWKT(testWKTs['line_touches_line1_endpoint']!);
        final result = line1.disjoint(line2);
        expect(result.toList(), [false]); // Intersects (touches)
      });
      
      test('LineString not disjoint from LineString (overlaps)', () {
        final line1 = GeoSeries_fromWKT([testWKTs['line1']!]);
        final line2 = GeoJSONGeometry_fromWKT(testWKTs['line_overlaps_line1_partial']!);
        final result = line1.disjoint(line2);
        expect(result.toList(), [false]); // Intersects (overlaps)
      });

      test('LineString disjoint from Polygon', () {
        final line = GeoSeries_fromWKT([testWKTs['line_disjoint_from_line1']!]); // This line is also disjoint from poly1
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = line.disjoint(poly);
        expect(result.toList(), [true]);
      });

      test('LineString not disjoint from Polygon (intersects)', () {
        final line = GeoSeries_fromWKT([testWKTs['line_crossing_poly']!]);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = line.disjoint(poly);
        expect(result.toList(), [false]); // Intersects
      });
       test('LineString not disjoint from Polygon (touches boundary)', () {
        final line = GeoSeries_fromWKT([testWKTs['line_touches_poly_boundary']!]);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = line.disjoint(poly);
        expect(result.toList(), [false]); // Intersects (touches)
      });
    });

    // 3. Polygon Disjoint
    group('Polygon Disjoint scenarios', () {
      test('Polygon disjoint from Polygon', () {
        final poly1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final poly2 = GeoJSONGeometry_fromWKT(testWKTs['poly_disjoint']!);
        final result = poly1.disjoint(poly2);
        expect(result.toList(), [true]);
      });

      test('Polygon not disjoint from Polygon (overlaps)', () {
        final poly1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final poly2 = GeoJSONGeometry_fromWKT(testWKTs['poly2_overlaps_poly1']!);
        final result = poly1.disjoint(poly2);
        expect(result.toList(), [false]); // Intersects
      });

      test('Polygon not disjoint from Polygon (touches boundary)', () {
        final poly1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final poly2 = GeoJSONGeometry_fromWKT(testWKTs['poly3_touches_poly1']!);
        final result = poly1.disjoint(poly2);
        expect(result.toList(), [false]); // Intersects (touches)
      });

      test('Polygon not disjoint from Polygon (one contains other)', () {
        final polyOuter = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final polyInner = GeoJSONGeometry_fromWKT(testWKTs['poly_hole']!); // poly_hole is contained in poly1
        final result = polyOuter.disjoint(polyInner);
        expect(result.toList(), [false]); // Intersects (contains)
      });

      test('Identical polygons are not disjoint', () {
        final poly1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final polyIdentical = GeoJSONGeometry_fromWKT(testWKTs['poly_identical_to_poly1']!);
        final result = poly1.disjoint(polyIdentical);
        expect(result.toList(), [false]); // Intersects (identical)
      });
    });

    // 4. Multi-Geometries
    group('Multi-Geometries scenarios for disjoint()', () {
      test('MultiPoint disjoint from Polygon', () {
        final mpoint = GeoSeries_fromWKT(['MULTIPOINT (2 2, 3 3)']);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = mpoint.disjoint(poly);
        expect(result.toList(), [true]);
      });
      
      test('MultiPoint not disjoint from Polygon (one point inside)', () {
        final mpoint = GeoSeries_fromWKT([testWKTs['mpoint_one_in_poly']!]);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = mpoint.disjoint(poly);
        expect(result.toList(), [false]); // Intersects
      });

      test('MultiLineString disjoint from LineString', () {
        final mline = GeoSeries_fromWKT(['MULTILINESTRING ((2 2, 3 3), (4 4, 5 5))']);
        final line = GeoJSONGeometry_fromWKT(testWKTs['line1']!);
        final result = mline.disjoint(line);
        expect(result.toList(), [true]);
      });
      
       test('MultiLineString not disjoint from LineString (one line touches)', () {
        final mline = GeoSeries_fromWKT(['MULTILINESTRING ((1 1, 2 0), (3 3, 4 4))']); // First line touches line1
        final line = GeoJSONGeometry_fromWKT(testWKTs['line1']!); // (0,0)-(1,1)
        final result = mline.disjoint(line);
        expect(result.toList(), [false]); // Intersects
      });

      test('MultiPolygon disjoint from Polygon', () {
        final mpoly = GeoSeries_fromWKT(['MULTIPOLYGON (((2 2, 3 2, 3 3, 2 3, 2 2)))']);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = mpoly.disjoint(poly);
        expect(result.toList(), [true]);
      });

       test('MultiPolygon not disjoint from Polygon (one poly overlaps)', () {
        final mpoly = GeoSeries_fromWKT(
            ['MULTIPOLYGON (((0.5 0.5, 1.5 0.5, 1.5 1.5, 0.5 1.5, 0.5 0.5)), ((2 2, 3 2, 3 3, 2 3, 2 2)))']);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = mpoly.disjoint(poly);
        expect(result.toList(), [false]); // Intersects
      });
    });

    // 5. Empty Geometries
    group('Empty Geometries scenarios for disjoint()', () {
      // GEOS behavior: ST_Disjoint(A, empty) is false. ST_Disjoint(empty, empty) is false.
      test('Polygon.disjoint(EmptyPoint)', () {
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final emptyPoint = GeoJSONGeometry_fromWKT(testWKTs['empty_point']!);
        final result = poly.disjoint(emptyPoint);
        expect(result.toList(), [false]);
      });

      test('EmptyPolygon.disjoint(Point)', () {
        final emptyPoly = GeoSeries_fromWKT([testWKTs['empty_polygon']!]);
        final point = GeoJSONGeometry_fromWKT(testWKTs['point1']!);
        final result = emptyPoly.disjoint(point);
        expect(result.toList(), [false]);
      });

      test('EmptyPolygon.disjoint(EmptyPolygon)', () {
        final emptyPoly1 = GeoSeries_fromWKT([testWKTs['empty_polygon']!]);
        final emptyPoly2 = GeoJSONGeometry_fromWKT(testWKTs['empty_polygon']!);
        final result = emptyPoly1.disjoint(emptyPoly2);
        expect(result.toList(), [false]);
      });
    });

    // 6. `other` as `GeoSeries`
    group('`other` as GeoSeries scenarios for disjoint()', () {
      test('Series: poly1.disjoint(poly_disjoint)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['poly_disjoint']!]);
        final result = s1.disjoint(s2);
        expect(result.toList(), [true]);
      });

      test('Series: [poly1, poly1] disjoint [poly_disjoint, poly2_overlaps_poly1]', () {
        // poly1 disjoint poly_disjoint -> true
        // poly1 not disjoint poly2_overlaps_poly1 -> false
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!, testWKTs['poly1']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['poly_disjoint']!, testWKTs['poly2_overlaps_poly1']!]);
        final result = s1.disjoint(s2);
        expect(result.toList(), [true, false]);
      });
      
      test('Series with different lengths (s1 longer)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!, testWKTs['poly1']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['poly_disjoint']!]);
        final result = s1.disjoint(s2);
        // poly1.disjoint(poly_disjoint) -> true
        // poly1.disjoint(no_geom) -> false (as per current padding logic)
        expect(result.toList(), [true, false]); 
        expect(result.index.length, 2);
      });

      test('Series with different lengths (s2 longer)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['poly_disjoint']!, testWKTs['poly2_overlaps_poly1']!]);
        final result = s1.disjoint(s2);
        expect(result.toList(), [true]); // Result matches length of s1
        expect(result.index.length, 1);
      });

      test('Series with null geometry in calling series for disjoint', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!, null]);
        final s2 = GeoSeries_fromWKT([testWKTs['poly_disjoint']!, testWKTs['poly_disjoint']!]);
        final result = s1.disjoint(s2);
        expect(result.toList(), [true, false]); // null geom disjoint nothing -> false
      });

      test('Series with null geometry in other series for disjoint', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!, testWKTs['poly1']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['poly_disjoint']!, null]);
        final result = s1.disjoint(s2);
        expect(result.toList(), [true, false]); // poly1 disjoint null -> false
      });
    });
  });

  group('GeoSeries.overlaps() tests', () {
    // 1. Polygon overlaps Polygon
    group('Polygon overlaps Polygon scenarios', () {
      test('Polygon overlaps Polygon (interiors intersect, not contained)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['poly2_overlaps_poly1']!);
        final result = s1.overlaps(g2);
        expect(result.toList(), [true]);
      });

      test('Polygons only touch at a boundary (not overlaps)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['poly3_touches_poly1']!);
        final result = s1.overlaps(g2);
        expect(result.toList(), [false]);
      });

      test('One Polygon completely contains another (not overlaps)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!]); // Outer
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['poly_hole']!); // Inner, contained by poly1
        final result = s1.overlaps(g2);
        expect(result.toList(), [false]); // s1 contains g2
        final result2 = GeoSeries_fromWKT([g2.toWKT()]).overlaps(GeoJSONGeometry_fromWKT(s1.get(0)!.toWKT()));
        expect(result2.toList(), [false]); // g2 is within s1
      });

      test('Polygons are disjoint (not overlaps)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['poly_disjoint']!);
        final result = s1.overlaps(g2);
        expect(result.toList(), [false]);
      });

      test('Identical Polygons (not overlaps, as they are equal)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['poly_identical_to_poly1']!);
        final result = s1.overlaps(g2);
        expect(result.toList(), [false]);
      });
    });

    // 2. LineString overlaps LineString
    group('LineString overlaps LineString scenarios', () {
      test('LineStrings overlap along a segment (not identical, neither contains other)', () {
        // line1: (0 0, 1 1), line_overlaps_line1_partial: (0.5 0.5, 1.5 1.5)
        final s1 = GeoSeries_fromWKT([testWKTs['line1']!]); 
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['line_overlaps_line1_partial']!);
        final result = s1.overlaps(g2);
        expect(result.toList(), [true]);
      });
      
      test('LineStrings overlap (longer example)', () {
        final s1 = GeoSeries_fromWKT(['LINESTRING (0 0, 2 2, 4 4)']);
        final g2 = GeoJSONGeometry_fromWKT('LINESTRING (1 1, 3 3)'); // Overlaps segment (1,1)-(2,2) and (2,2)-(3,3)
        final result = s1.overlaps(g2);
        expect(result.toList(), [true]);
      });


      test('LineStrings only touch at an endpoint (not overlaps)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['line_touches_line1_endpoint']!);
        final result = s1.overlaps(g2);
        expect(result.toList(), [false]);
      });

      test('One LineString is a subset of another but not identical (not overlaps)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line1']!]); // LINESTRING (0 0, 1 1)
        final g2 = GeoJSONGeometry_fromWKT('LINESTRING (0.25 0.25, 0.75 0.75)'); // Subset of line1
        final result = s1.overlaps(g2);
        expect(result.toList(), [false]); // s1 contains g2
        final result2 = GeoSeries_fromWKT([g2.toWKT()]).overlaps(GeoJSONGeometry_fromWKT(s1.get(0)!.toWKT()));
        expect(result2.toList(), [false]); // g2 is within s1
      });

      test('Identical LineStrings (not overlaps, as they are equal)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['line1']!);
        final result = s1.overlaps(g2);
        expect(result.toList(), [false]);
      });

      test('LineStrings that cross at a single point (not overlaps)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['line_crosses_line1']!);
        final result = s1.overlaps(g2);
        expect(result.toList(), [false]); // Intersection is a Point (lower dimension)
      });
    });

    // 3. Point overlaps Point (MultiPoint)
    group('Point overlaps Point (MultiPoint) scenarios', () {
      test('MultiPoint overlaps MultiPoint (share some but not all points)', () {
        final s1 = GeoSeries_fromWKT(['MULTIPOINT ((0 0), (1 1))']);
        final g2 = GeoJSONGeometry_fromWKT('MULTIPOINT ((1 1), (2 2))');
        final result = s1.overlaps(g2);
        expect(result.toList(), [true]); // Intersection is (1 1), same dim, not equal to inputs
      });
      
      test('MultiPoint contains MultiPoint (not overlaps)', () {
        final s1 = GeoSeries_fromWKT(['MULTIPOINT ((0 0), (1 1), (2 2))']);
        final g2 = GeoJSONGeometry_fromWKT('MULTIPOINT ((1 1), (2 2))');
        final result = s1.overlaps(g2);
        expect(result.toList(), [false]); // s1 contains g2
      });

      test('Identical MultiPoints (not overlaps)', () {
        final s1 = GeoSeries_fromWKT(['MULTIPOINT ((0 0), (1 1))']);
        final g2 = GeoJSONGeometry_fromWKT('MULTIPOINT ((0 0), (1 1))');
        final result = s1.overlaps(g2);
        expect(result.toList(), [false]);
      });

      test('Single Point vs Single Point (not overlaps)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['point1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['point_identical_to_point1']!);
        final result = s1.overlaps(g2);
        expect(result.toList(), [false]); // If they intersect, they are equal.
        
        final g3 = GeoJSONGeometry_fromWKT(testWKTs['point2']!);
        final result2 = s1.overlaps(g3);
        expect(result2.toList(), [false]); // Disjoint
      });
    });

    // 4. Different Dimensions
    group('Different Dimensions scenarios for overlaps() (should be false)', () {
      test('LineString vs Polygon', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line_crossing_poly']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = s1.overlaps(g2);
        expect(result.toList(), [false]);
      });

      test('Point vs LineString', () {
        final s1 = GeoSeries_fromWKT([testWKTs['point_on_line1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['line1']!);
        final result = s1.overlaps(g2);
        expect(result.toList(), [false]);
      });
    });

    // 5. Multi-Geometries (more complex cases)
    group('Multi-Geometries scenarios for overlaps()', () {
      test('MultiPolygon overlaps MultiPolygon', () {
        // mpolyA: contains poly1 and a disjoint poly A2
        // mpolyB: contains poly2_overlaps_poly1 and a disjoint poly B2
        // Intersection is overlap of poly1 and poly2_overlaps_poly1
        final s1 = GeoSeries_fromWKT(['MULTIPOLYGON (((0 0, 1 0, 1 1, 0 1, 0 0)), ((10 0, 11 0, 11 1, 10 1, 10 0)))']);
        final g2 = GeoJSONGeometry_fromWKT('MULTIPOLYGON (((0.5 0.5, 1.5 0.5, 1.5 1.5, 0.5 1.5, 0.5 0.5)), ((12 0, 13 0, 13 1, 12 1, 12 0)))');
        final result = s1.overlaps(g2);
        expect(result.toList(), [true]);
      });

      test('MultiLineString overlaps MultiLineString', () {
        // mlineA: contains line1 and a disjoint line A2
        // mlineB: contains line_overlaps_line1_partial and disjoint line B2
        final s1 = GeoSeries_fromWKT(['MULTILINESTRING ((0 0, 1 1), (10 0, 11 1))']);
        final g2 = GeoJSONGeometry_fromWKT('MULTILINESTRING ((0.5 0.5, 1.5 1.5), (12 0, 13 1))');
        final result = s1.overlaps(g2);
        expect(result.toList(), [true]);
      });
    });

    // 6. Empty Geometries
    group('Empty Geometries scenarios for overlaps()', () {
      test('Polygon.overlaps(EmptyPolygon)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['empty_polygon']!);
        final result = s1.overlaps(g2);
        expect(result.toList(), [false]);
      });

      test('EmptyPolygon.overlaps(Polygon)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['empty_polygon']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = s1.overlaps(g2);
        expect(result.toList(), [false]);
      });
      
      test('EmptyLineString.overlaps(EmptyLineString)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['empty_linestring']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['empty_linestring']!);
        final result = s1.overlaps(g2);
        expect(result.toList(), [false]);
      });
    });

    // 7. `other` as `GeoSeries`
    group('`other` as GeoSeries scenarios for overlaps()', () {
      test('Series: poly1.overlaps(poly2_overlaps_poly1)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['poly2_overlaps_poly1']!]);
        final result = s1.overlaps(s2);
        expect(result.toList(), [true]);
      });

      test('Series: [poly1, line1] overlaps [poly2_overlaps_poly1, line_overlaps_line1_partial]', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!, testWKTs['line1']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['poly2_overlaps_poly1']!, testWKTs['line_overlaps_line1_partial']!]);
        final result = s1.overlaps(s2);
        expect(result.toList(), [true, true]);
      });
      
      test('Series with different lengths (s1 longer)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!, testWKTs['poly1']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['poly2_overlaps_poly1']!]);
        final result = s1.overlaps(s2);
        expect(result.toList(), [true, false]); 
        expect(result.index.length, 2);
      });

      test('Series with different lengths (s2 longer)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['poly2_overlaps_poly1']!, testWKTs['poly_disjoint']!]);
        final result = s1.overlaps(s2);
        expect(result.toList(), [true]); 
        expect(result.index.length, 1);
      });

      test('Series with null geometry in calling series for overlaps', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!, null]);
        final s2 = GeoSeries_fromWKT([testWKTs['poly2_overlaps_poly1']!, testWKTs['poly_disjoint']!]);
        final result = s1.overlaps(s2);
        expect(result.toList(), [true, false]); // null geom overlaps nothing -> false
      });

      test('Series with null geometry in other series for overlaps', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!, testWKTs['poly1']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['poly2_overlaps_poly1']!, null]);
        final result = s1.overlaps(s2);
        expect(result.toList(), [true, false]); // poly1 overlaps null -> false
      });
    });
  });

  group('GeoSeries.crosses() tests', () {
    // 1. LineString crosses LineString
    group('LineString crosses LineString scenarios', () {
      test('LineString crosses LineString (intersect in interiors)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line1']!]); // LINESTRING (0 0, 1 1)
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['line_crosses_line1']!); // LINESTRING (0 1, 1 0)
        final result = s1.crosses(g2);
        expect(result.toList(), [true]);
      });

      test('LineStrings only touch at an endpoint (not crosses)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['line_touches_line1_endpoint']!);
        final result = s1.crosses(g2);
        expect(result.toList(), [false]);
      });

      test('LineStrings overlap along a segment (not crosses)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['line_overlaps_line1_partial']!);
        final result = s1.crosses(g2);
        expect(result.toList(), [false]);
      });

      test('LineStrings are disjoint (not crosses)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['line_disjoint_from_line1']!);
        final result = s1.crosses(g2);
        expect(result.toList(), [false]);
      });

      test('One LineString contained within another (not crosses)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line1']!]); // LINESTRING (0 0, 1 1)
        final g2 = GeoJSONGeometry_fromWKT('LINESTRING (0.25 0.25, 0.75 0.75)'); // Contained in line1
        final result = s1.crosses(g2);
        expect(result.toList(), [false]); // s1 contains g2, does not cross
        final result2 = GeoSeries_fromWKT([g2.toWKT()]).crosses(GeoJSONGeometry_fromWKT(s1.get(0)!.toWKT()));
        expect(result2.toList(), [false]);// g2 is within s1, does not cross
      });
       test('Identical LineStrings (not crosses)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['line1']!);
        final result = s1.crosses(g2);
        expect(result.toList(), [false]);
      });
    });

    // 2. LineString crosses Polygon
    group('LineString crosses Polygon scenarios', () {
      test('LineString intersects interior and exterior of Polygon', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line_crossing_poly']!]); // LINESTRING (-0.5 0.5, 1.5 0.5)
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['poly1']!); // POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))
        final result = s1.crosses(g2);
        expect(result.toList(), [true]);
      });
      
      test('Polygon crosses LineString (same as above, reversed role)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['line_crossing_poly']!);
        final result = s1.crosses(g2);
        expect(result.toList(), [true]);
      });

      test('LineString only touches Polygon boundary (not crosses)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line_touches_poly_boundary']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = s1.crosses(g2);
        expect(result.toList(), [false]);
      });

      test('LineString contained within Polygon (not crosses)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line_contained_in_poly']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = s1.crosses(g2);
        expect(result.toList(), [false]);
      });

      test('LineString disjoint from Polygon (not crosses)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line_disjoint_from_line1']!]); // Also disjoint from poly1
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = s1.crosses(g2);
        expect(result.toList(), [false]);
      });
    });

    // 3. Point crosses X / X crosses Point
    group('Point crosses X scenarios (should be false)', () {
      test('Point crosses LineString', () {
        final s1 = GeoSeries_fromWKT([testWKTs['point1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['line1']!);
        final result = s1.crosses(g2);
        expect(result.toList(), [false]);
      });

      test('LineString crosses Point', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['point1']!);
        final result = s1.crosses(g2);
        expect(result.toList(), [false]);
      });

      test('Point crosses Polygon', () {
        final s1 = GeoSeries_fromWKT([testWKTs['point1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = s1.crosses(g2);
        expect(result.toList(), [false]);
      });
      
      test('Polygon crosses Point', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['point1']!);
        final result = s1.crosses(g2);
        expect(result.toList(), [false]);
      });
    });

    // 4. Polygon crosses Polygon
    group('Polygon crosses Polygon scenarios (should be false)', () {
      test('Polygon overlaps Polygon (not crosses)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['poly2_overlaps_poly1']!);
        final result = s1.crosses(g2);
        expect(result.toList(), [false]);
      });

      test('Polygon touches Polygon (not crosses)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['poly3_touches_poly1']!);
        final result = s1.crosses(g2);
        expect(result.toList(), [false]);
      });
    });

    // 5. Multi-Geometries
    group('Multi-Geometries scenarios for crosses()', () {
      test('MultiLineString crosses Polygon (one line crosses)', () {
        final s1 = GeoSeries_fromWKT(['MULTILINESTRING ((-0.5 0.5, 1.5 0.5), (2 2, 3 3))']); // First line crosses poly1
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = s1.crosses(g2);
        expect(result.toList(), [true]);
      });

      test('LineString crosses MultiPolygon (line crosses one polygon in collection)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line_crossing_poly']!]);
        final g2 = GeoJSONGeometry_fromWKT(
            'MULTIPOLYGON (((0 0, 1 0, 1 1, 0 1, 0 0)), ((2 0, 3 0, 3 1, 2 1, 2 0)))'); // poly1 and poly_disjoint
        final result = s1.crosses(g2);
        expect(result.toList(), [true]); // Crosses the first polygon (poly1)
      });
      
      test('MultiPoint crosses LineString (some points on, some not, but interior of MPoint must intersect interior AND exterior of Line)', () {
        // For MultiPoint/LineString, ST_Crosses is true if at least one point is on the line and 
        // at least one point is not on the line.
        // The "interior" of a MultiPoint is the set of points. The "boundary" is empty.
        // The "interior" of a LineString is the line minus its boundary points.
        // Intersection of MPoint interior and LineString interior means a point is on the LineString's interior.
        // Intersection of MPoint interior and LineString exterior means a point is off the LineString.
        final s1 = GeoSeries_fromWKT(['MULTIPOINT (0.5 0.5, 2 2)']); // (0.5,0.5) is on line1, (2,2) is not
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['line1']!); // LINESTRING (0 0, 1 1)
        final result = s1.crosses(g2);
        expect(result.toList(), [true]);
      });

      test('MultiPoint crosses Polygon (some points in, some out)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['mpoint_partially_in_poly']!]); // MULTIPOINT (0.1 0.1, 1.2 1.2)
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['poly1']!); // Unit square
        final result = s1.crosses(g2);
        expect(result.toList(), [true]);
      });
    });

    // 6. Empty Geometries
    group('Empty Geometries scenarios for crosses()', () {
      test('LineString.crosses(EmptyLineString)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line1']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['empty_linestring']!);
        final result = s1.crosses(g2);
        expect(result.toList(), [false]);
      });

      test('EmptyLineString.crosses(Polygon)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['empty_linestring']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = s1.crosses(g2);
        expect(result.toList(), [false]);
      });
      
      test('EmptyLineString.crosses(EmptyPolygon)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['empty_linestring']!]);
        final g2 = GeoJSONGeometry_fromWKT(testWKTs['empty_polygon']!);
        final result = s1.crosses(g2);
        expect(result.toList(), [false]);
      });
    });

    // 7. `other` as `GeoSeries`
    group('`other` as GeoSeries scenarios for crosses()', () {
      test('Series: line1.crosses(line_crosses_line1)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line1']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['line_crosses_line1']!]);
        final result = s1.crosses(s2);
        expect(result.toList(), [true]);
      });

      test('Series: [line1, line_crossing_poly] crosses [line_crosses_line1, poly1]', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line1']!, testWKTs['line_crossing_poly']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['line_crosses_line1']!, testWKTs['poly1']!]);
        final result = s1.crosses(s2);
        expect(result.toList(), [true, true]);
      });
      
      test('Series with different lengths (s1 longer)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line1']!, testWKTs['line_crossing_poly']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['line_crosses_line1']!]);
        final result = s1.crosses(s2);
        expect(result.toList(), [true, false]); 
        expect(result.index.length, 2);
      });

      test('Series with different lengths (s2 longer)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line1']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['line_crosses_line1']!, testWKTs['poly1']!]);
        final result = s1.crosses(s2);
        expect(result.toList(), [true]); 
        expect(result.index.length, 1);
      });

      test('Series with null geometry in calling series for crosses', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line1']!, null]);
        final s2 = GeoSeries_fromWKT([testWKTs['line_crosses_line1']!, testWKTs['line1']!]);
        final result = s1.crosses(s2);
        expect(result.toList(), [true, false]); // null geom crosses nothing -> false
      });

      test('Series with null geometry in other series for crosses', () {
        final s1 = GeoSeries_fromWKT([testWKTs['line1']!, testWKTs['line_crossing_poly']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['line_crosses_line1']!, null]);
        final result = s1.crosses(s2);
        expect(result.toList(), [true, false]); // line_crossing_poly crosses null -> false
      });
    });
  });

  group('GeoSeries.touches() tests', () {
    // 1. Point Touches
    group('Point Touches scenarios', () {
      test('Point touches LineString (point is an endpoint of the line)', () {
        final point = GeoSeries_fromWKT([testWKTs['point_endpoint_of_line1']!]); // POINT (0 0)
        final line = GeoJSONGeometry_fromWKT(testWKTs['line1']!); // LINESTRING (0 0, 1 1)
        final result = point.touches(line);
        expect(result.toList(), [true]);
      });

      test('Point touches LineString (point on line but not an endpoint)', () {
        // A point's boundary is itself. A line's boundary is its endpoints.
        // For a point to touch a line, the point must be one of the line's endpoints.
        // If the point is in the interior of the line, it's 'intersects' but not 'touches'.
        final point = GeoSeries_fromWKT([testWKTs['point_on_line1']!]); // POINT (0.5 0.5)
        final line = GeoJSONGeometry_fromWKT(testWKTs['line1']!); // LINESTRING (0 0, 1 1)
        final result = point.touches(line);
        expect(result.toList(), [false]); 
      });

      test('Point touches Polygon (point is on the boundary, not a vertex)', () {
        final point = GeoSeries_fromWKT([testWKTs['point_on_poly_boundary_non_vertex']!]); // POINT (0 0.5)
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = point.touches(poly);
        expect(result.toList(), [true]);
      });

      test('Point touches Polygon (point is a vertex of the polygon)', () {
        final point = GeoSeries_fromWKT([testWKTs['point_on_poly_boundary']!]); // POINT (0 0)
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = point.touches(poly);
        expect(result.toList(), [true]);
      });

      test('Point inside Polygon does not touch', () {
        final point = GeoSeries_fromWKT([testWKTs['point_inside_poly']!]);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = point.touches(poly);
        expect(result.toList(), [false]);
      });

      test('Point outside Polygon does not touch', () {
        final point = GeoSeries_fromWKT([testWKTs['point_outside_poly']!]);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = point.touches(poly);
        expect(result.toList(), [false]);
      });
    });

    // 2. LineString Touches
    group('LineString Touches scenarios', () {
      test('LineString touches LineString (share an endpoint, do not overlap otherwise)', () {
        final line1 = GeoSeries_fromWKT([testWKTs['line1']!]);
        final line2 = GeoJSONGeometry_fromWKT(testWKTs['line_touches_line1_endpoint']!);
        final result = line1.touches(line2);
        expect(result.toList(), [true]);
      });

      test('LineStrings cross (not touches)', () {
        // Crossing implies interior intersection, so not touches.
        final line1 = GeoSeries_fromWKT([testWKTs['line1']!]);
        final line2 = GeoJSONGeometry_fromWKT(testWKTs['line_crosses_line1']!);
        final result = line1.touches(line2);
        expect(result.toList(), [false]);
      });

      test('LineStrings overlap along a segment (not touches)', () {
        final line1 = GeoSeries_fromWKT([testWKTs['line1']!]);
        final line2 = GeoJSONGeometry_fromWKT(testWKTs['line_overlaps_line1_partial']!);
        final result = line1.touches(line2);
        expect(result.toList(), [false]);
      });

      test('LineString endpoint on another LineString\'s interior (touches)', () {
        final line1 = GeoSeries_fromWKT(['LINESTRING(0 0, 2 0)']); // Target line
        final line2 = GeoJSONGeometry_fromWKT('LINESTRING(1 0, 1 1)'); // Touches at (1,0) which is interior to line1
        final result = line1.touches(line2);
        expect(result.toList(), [true]);
      });

      test('LineString touches Polygon boundary (and does not cross into interior)', () {
        final line = GeoSeries_fromWKT([testWKTs['line_touches_poly_boundary']!]);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = line.touches(poly);
        expect(result.toList(), [true]);
      });

      test('LineString endpoint touches Polygon vertex', () {
        final line = GeoSeries_fromWKT([testWKTs['line_endpoint_touches_poly_vertex']!]);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = line.touches(poly);
        expect(result.toList(), [true]);
      });

      test('LineString contained within Polygon (not touches)', () {
        final line = GeoSeries_fromWKT([testWKTs['line_contained_in_poly']!]);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = line.touches(poly);
        expect(result.toList(), [false]);
      });

      test('LineString crosses Polygon (not touches)', () {
        final line = GeoSeries_fromWKT([testWKTs['line_crossing_poly']!]);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = line.touches(poly);
        expect(result.toList(), [false]);
      });
    });
    
    // 3. Polygon Touches
    group('Polygon Touches scenarios', () {
      test('Polygon touches Polygon at a point', () {
        final poly1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final poly2 = GeoJSONGeometry_fromWKT(testWKTs['poly_touches_poly1_at_point']!);
        final result = poly1.touches(poly2);
        expect(result.toList(), [true]);
      });

      test('Polygon touches Polygon along an edge', () {
        final poly1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final poly2 = GeoJSONGeometry_fromWKT(testWKTs['poly3_touches_poly1']!);
        final result = poly1.touches(poly2);
        expect(result.toList(), [true]);
      });

      test('Polygon overlaps Polygon (not touches)', () {
        final poly1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final poly2 = GeoJSONGeometry_fromWKT(testWKTs['poly2_overlaps_poly1']!);
        final result = poly1.touches(poly2);
        expect(result.toList(), [false]);
      });

      test('Polygon one contains another (not touches)', () {
        final polyOuter = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final polyInner = GeoJSONGeometry_fromWKT(testWKTs['poly_hole']!);
        final result = polyOuter.touches(polyInner);
        expect(result.toList(), [false]); // polyOuter contains polyInner
        final result2 = polyInner.touches(polyOuter);
        expect(result2.toList(), [false]); // polyInner is within polyOuter
      });
      
       test('Identical Polygons (not touches)', () {
        final poly1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final polyIdentical = GeoJSONGeometry_fromWKT(testWKTs['poly_identical_to_poly1']!);
        final result = poly1.touches(polyIdentical);
        expect(result.toList(), [false]);
      });
    });

    // 4. Multi-Geometries
    group('Multi-Geometries scenarios for touches()', () {
      test('MultiPoint touches Polygon (one point on boundary)', () {
        final mpoint = GeoSeries_fromWKT(['MULTIPOINT((0 0.5), (2 2))']); // One point touches poly1 boundary
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = mpoint.touches(poly);
        expect(result.toList(), [true]);
      });
      
      test('MultiPoint inside Polygon (not touches)', () {
        final mpoint = GeoSeries_fromWKT([testWKTs['mpoint_in_poly']!]); 
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = mpoint.touches(poly);
        expect(result.toList(), [false]);
      });

      test('MultiLineString touches Polygon (one line segment touches boundary)', () {
        final mline = GeoSeries_fromWKT(['MULTILINESTRING ((0 0, 0.5 0), (2 2, 3 3))']); // First line touches poly1
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = mline.touches(poly);
        expect(result.toList(), [true]);
      });

      test('MultiPolygon touches MultiPolygon (one pair touches at edge)', () {
        final mpoly1 = GeoSeries_fromWKT(['MULTIPOLYGON (((0 0, 1 0, 1 1, 0 1, 0 0)))']); // This is poly1
        final mpoly2 = GeoJSONGeometry_fromWKT('MULTIPOLYGON (((1 0, 2 0, 2 1, 1 1, 1 0)))'); // This is poly3_touches_poly1
        final result = mpoly1.touches(mpoly2);
        expect(result.toList(), [true]);
      });
    });

    // 5. Empty Geometries
    group('Empty Geometries scenarios for touches()', () {
      // GEOS ST_Touches(A, empty) is always false.
      test('Polygon.touches(EmptyPoint)', () {
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final emptyPoint = GeoJSONGeometry_fromWKT(testWKTs['empty_point']!);
        final result = poly.touches(emptyPoint);
        expect(result.toList(), [false]);
      });

      test('EmptyPolygon.touches(Point)', () {
        final emptyPoly = GeoSeries_fromWKT([testWKTs['empty_polygon']!]);
        final point = GeoJSONGeometry_fromWKT(testWKTs['point1']!);
        final result = emptyPoly.touches(point);
        expect(result.toList(), [false]);
      });

      test('EmptyPolygon.touches(EmptyPolygon)', () {
        final emptyPoly1 = GeoSeries_fromWKT([testWKTs['empty_polygon']!]);
        final emptyPoly2 = GeoJSONGeometry_fromWKT(testWKTs['empty_polygon']!);
        final result = emptyPoly1.touches(emptyPoly2);
        expect(result.toList(), [false]);
      });
    });
    
    // 6. `other` as `GeoSeries`
    group('`other` as GeoSeries scenarios for touches()', () {
      test('Series: poly1.touches(poly3_touches_poly1)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['poly3_touches_poly1']!]);
        final result = s1.touches(s2);
        expect(result.toList(), [true]);
      });

      test('Series: [poly1, poly1] touches [poly3_touches_poly1, poly2_overlaps_poly1]', () {
        // poly1 touches poly3_touches_poly1 -> true
        // poly1 does not touch poly2_overlaps_poly1 (it overlaps) -> false
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!, testWKTs['poly1']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['poly3_touches_poly1']!, testWKTs['poly2_overlaps_poly1']!]);
        final result = s1.touches(s2);
        expect(result.toList(), [true, false]);
      });
      
      test('Series with different lengths (s1 longer)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!, testWKTs['poly1']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['poly3_touches_poly1']!]);
        final result = s1.touches(s2);
        expect(result.toList(), [true, false]); 
        expect(result.index.length, 2);
      });

      test('Series with different lengths (s2 longer)', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['poly3_touches_poly1']!, testWKTs['poly2_overlaps_poly1']!]);
        final result = s1.touches(s2);
        expect(result.toList(), [true]); 
        expect(result.index.length, 1);
      });

      test('Series with null geometry in calling series for touches', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!, null]);
        final s2 = GeoSeries_fromWKT([testWKTs['poly3_touches_poly1']!, testWKTs['poly_disjoint']!]);
        final result = s1.touches(s2);
        expect(result.toList(), [true, false]); // null geom touches nothing -> false
      });

      test('Series with null geometry in other series for touches', () {
        final s1 = GeoSeries_fromWKT([testWKTs['poly1']!, testWKTs['poly1']!]);
        final s2 = GeoSeries_fromWKT([testWKTs['poly3_touches_poly1']!, null]);
        final result = s1.touches(s2);
        expect(result.toList(), [true, false]); // poly1 touches null -> false
      });
    });
  });

  group('GeoSeries.within() tests', () {
    // 1. Point within X
    group('Point within X scenarios', () {
      test('Point completely inside a polygon', () {
        final point = GeoSeries_fromWKT([testWKTs['point_inside_poly']!]);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = point.within(poly);
        expect(result.toList(), [true]);
      });

      test('Point outside a polygon', () {
        final point = GeoSeries_fromWKT([testWKTs['point_outside_poly']!]);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = point.within(poly);
        expect(result.toList(), [false]);
      });

      test('Point on the boundary of a polygon', () {
        // GEOS ST_Within: A point on the boundary is considered within.
        final point = GeoSeries_fromWKT([testWKTs['point_on_poly_boundary']!]);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = point.within(poly);
        expect(result.toList(), [true]);
      });

      test('Polygon within Point (generally false)', () {
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final point = GeoJSONGeometry_fromWKT(testWKTs['point1']!);
        final result = poly.within(point);
        expect(result.toList(), [false]);
      });

      test('Point within Point (identical)', () {
        final point1 = GeoSeries_fromWKT([testWKTs['point1']!]);
        final point2 = GeoJSONGeometry_fromWKT(testWKTs['point_identical_to_point1']!);
        final result = point1.within(point2);
        expect(result.toList(), [true]);
      });
       test('Point within Point (different)', () {
        final point1 = GeoSeries_fromWKT([testWKTs['point1']!]);
        final point2 = GeoJSONGeometry_fromWKT(testWKTs['point2']!);
        final result = point1.within(point2);
        expect(result.toList(), [false]);
      });
    });

    // 2. LineString within X
    group('LineString within X scenarios', () {
      test('LineString completely inside a polygon', () {
        final line = GeoSeries_fromWKT([testWKTs['line_contained_in_poly']!]);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = line.within(poly);
        expect(result.toList(), [true]);
      });

      test('LineString partially inside and partially outside a polygon', () {
        final line = GeoSeries_fromWKT([testWKTs['line_partially_in_poly']!]);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = line.within(poly);
        expect(result.toList(), [false]);
      });

      test('LineString on the boundary of a polygon', () {
        // GEOS ST_Within: A line on the boundary is considered within.
        final line = GeoSeries_fromWKT([testWKTs['line_on_poly_boundary']!]);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = line.within(poly);
        expect(result.toList(), [true]);
      });
       test('LineString within LineString (identical)', () {
        final line1 = GeoSeries_fromWKT([testWKTs['line1']!]);
        final line2 = GeoJSONGeometry_fromWKT(testWKTs['line1']!);
        final result = line1.within(line2);
        expect(result.toList(), [true]);
      });
      test('LineString within LineString (subset)', () {
        final subLine = GeoSeries_fromWKT(['LINESTRING(0.25 0.25, 0.75 0.75)']);
        final superLine = GeoJSONGeometry_fromWKT(testWKTs['line1']!); // LINESTRING (0 0, 1 1)
        final result = subLine.within(superLine);
        expect(result.toList(), [true]);
      });
       test('LineString not within LineString (overlap but not subset)', () {
        final line1 = GeoSeries_fromWKT([testWKTs['line1']!]); // (0 0, 1 1)
        final line2 = GeoJSONGeometry_fromWKT(testWKTs['line_overlaps_line1_partial']!); // (0.5 0.5, 1.5 1.5)
        final result = line1.within(line2);
        expect(result.toList(), [false]); // line1 is not *within* line2
      });
    });

    // 3. Polygon within Polygon
    group('Polygon within Polygon scenarios', () {
      test('Polygon completely inside another polygon', () {
        final polyInner = GeoSeries_fromWKT([testWKTs['poly_hole']!]); // This is smaller poly
        final polyOuter = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = polyInner.within(polyOuter);
        expect(result.toList(), [true]);
      });

      test('Polygon (outer) within another polygon (inner/hole)', () {
        final polyOuter = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final polyInner = GeoJSONGeometry_fromWKT(testWKTs['poly_hole']!);
        final result = polyOuter.within(polyInner);
        expect(result.toList(), [false]);
      });

      test('Identical polygons', () {
        final poly1 = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final polyIdentical = GeoJSONGeometry_fromWKT(testWKTs['poly_identical_to_poly1']!);
        final result = poly1.within(polyIdentical);
        expect(result.toList(), [true]);
      });
      
      test('Polygon A within Polygon B, B shares an edge with A (A is poly_shares_edge_with_poly1_exterior, B is poly1)', () {
        // poly_shares_edge_with_poly1_exterior is adjacent to poly1, not within.
        // Let's define polyA as truly inside polyB but sharing an edge.
        // polyB: POLYGON ((0 0, 2 0, 2 1, 0 1, 0 0))
        // polyA: POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0)) -> polyA is poly1
        final polyA = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final polyB = GeoJSONGeometry_fromWKT('POLYGON ((0 0, 2 0, 2 1, 0 1, 0 0))');
        final result = polyA.within(polyB);
        expect(result.toList(), [true]);
      });
    });

    // 4. Multi-Geometries
    group('Multi-Geometries scenarios', () {
      test('MultiPoint within Polygon (all points inside)', () {
        final mpoint = GeoSeries_fromWKT([testWKTs['mpoint_in_poly']!]);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = mpoint.within(poly);
        expect(result.toList(), [true]);
      });
      
      test('MultiPoint partially within Polygon (one point inside, one outside)', () {
        final mpoint = GeoSeries_fromWKT([testWKTs['mpoint_partially_in_poly']!]);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = mpoint.within(poly);
        expect(result.toList(), [false]);
      });

      test('Polygon within MultiPolygon (poly1 within a MPoly containing poly1 and poly_disjoint)', () {
        final poly = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final mpoly = GeoJSONGeometry_fromWKT(
            'MULTIPOLYGON (((0 0, 1 0, 1 1, 0 1, 0 0)), ((2 0, 3 0, 3 1, 2 1, 2 0)))');
        final result = poly.within(mpoly);
        expect(result.toList(), [true]);
      });
      
      test('MultiLineString within Polygon', () {
        final mline = GeoSeries_fromWKT([testWKTs['mline_in_poly']!]);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = mline.within(poly);
        expect(result.toList(), [true]);
      });

      test('MultiPolygon within MultiPolygon (subset)', () {
        final mpoly1 = GeoSeries_fromWKT([testWKTs['mpoly_in_poly']!]); // Contains one small poly
        final mpoly2 = GeoJSONGeometry_fromWKT(
             'MULTIPOLYGON (((0.1 0.1, 0.2 0.1, 0.2 0.2, 0.1 0.2, 0.1 0.1)), ((0.3 0.3, 0.4 0.3, 0.4 0.4, 0.3 0.4, 0.3 0.3)))');
        final result = mpoly1.within(mpoly2);
        expect(result.toList(), [true]); // mpoly1's single poly is one of mpoly2's
      });
    });

    // 5. Empty Geometries (GEOS specific behavior)
    group('Empty Geometries scenarios for within()', () {
      // GEOS ST_Within(A,B): if A is empty, returns TRUE. If B is empty (and A not), returns FALSE. Both empty, TRUE.
      test('EmptyPoint.within(Polygon)', () {
        final emptyPoint = GeoSeries_fromWKT([testWKTs['empty_point']!]);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = emptyPoint.within(poly);
        expect(result.toList(), [true]); 
      });

      test('Point.within(EmptyPolygon)', () {
        final point = GeoSeries_fromWKT([testWKTs['point1']!]);
        final emptyPoly = GeoJSONGeometry_fromWKT(testWKTs['empty_polygon']!);
        final result = point.within(emptyPoly);
        expect(result.toList(), [false]);
      });

      test('EmptyPoint.within(EmptyPolygon)', () {
        final emptyPoint = GeoSeries_fromWKT([testWKTs['empty_point']!]);
        final emptyPoly = GeoJSONGeometry_fromWKT(testWKTs['empty_polygon']!);
        final result = emptyPoint.within(emptyPoly);
        expect(result.toList(), [true]);
      });
       test('EmptyLineString.within(Polygon)', () {
        final emptyLine = GeoSeries_fromWKT([testWKTs['empty_linestring']!]);
        final poly = GeoJSONGeometry_fromWKT(testWKTs['poly1']!);
        final result = emptyLine.within(poly);
        expect(result.toList(), [true]); 
      });
    });

    // 6. `other` as `GeoSeries`
    group('`other` as GeoSeries scenarios for within()', () {
      test('Series: point_inside_poly.within(poly1)', () {
        final pointSeries = GeoSeries_fromWKT([testWKTs['point_inside_poly']!]);
        final polySeries = GeoSeries_fromWKT([testWKTs['poly1']!]);
        final result = pointSeries.within(polySeries);
        expect(result.toList(), [true]);
      });

      test('Series: [point_inside_poly, point_outside_poly] within [poly1, poly1]', () {
        final pointSeries = GeoSeries_fromWKT([testWKTs['point_inside_poly']!, testWKTs['point_outside_poly']!]);
        final polySeries = GeoSeries_fromWKT([testWKTs['poly1']!, testWKTs['poly1']!]);
        final result = pointSeries.within(polySeries);
        expect(result.toList(), [true, false]);
      });
      
      test('Series with different lengths (pointSeries longer)', () {
        final pointSeries = GeoSeries_fromWKT([testWKTs['point_inside_poly']!, testWKTs['point_outside_poly']!]);
        final polySeries = GeoSeries_fromWKT([testWKTs['poly1']!]); // Shorter
        final result = pointSeries.within(polySeries);
        // Result matches length of calling series (pointSeries)
        // point_inside_poly is within poly1 -> true
        // point_outside_poly has no corresponding poly in polySeries (shorter), so treated as false
        expect(result.toList(), [true, false]); 
        expect(result.index.length, 2);
      });

      test('Series with different lengths (polySeries longer)', () {
        final pointSeries = GeoSeries_fromWKT([testWKTs['point_inside_poly']!]); // Shorter
        final polySeries = GeoSeries_fromWKT([testWKTs['poly1']!, testWKTs['poly_disjoint']!]);
        final result = pointSeries.within(polySeries);
        // Result matches length of calling series (pointSeries)
        expect(result.toList(), [true]);
        expect(result.index.length, 1);
      });

      test('Series with null geometry in calling series for within', () {
        final seriesA = GeoSeries_fromWKT([testWKTs['point_inside_poly']!, null]);
        final seriesB = GeoSeries_fromWKT([testWKTs['poly1']!, testWKTs['poly1']!]);
        final result = seriesA.within(seriesB);
        expect(result.toList(), [true, false]); // null geom is not within anything in this context (predicate returns false)
      });

      test('Series with null geometry in other series for within', () {
        final seriesA = GeoSeries_fromWKT([testWKTs['point_inside_poly']!, testWKTs['point1']!]);
        final seriesB = GeoSeries_fromWKT([testWKTs['poly1']!, null]);
        final result = seriesA.within(seriesB);
        expect(result.toList(), [true, false]); // point1 cannot be within null
      });
    });
  });
}
