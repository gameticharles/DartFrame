// ignore_for_file: depend_on_referenced_packages

library;

import 'dart:convert';
import 'dart:math';

import 'package:geoxml/geoxml.dart';
import 'package:intl/intl.dart';
import 'package:geojson_vi/geojson_vi.dart';

import 'src/file_helper/file_io.dart';

export 'package:geojson_vi/geojson_vi.dart';

part 'src/utils/utils.dart';

part 'src/geo_series/geo_series.dart';
part 'src/geo_series/geo_processes.dart';
part 'src/geo_series/functions.dart';

part 'src/geo_dart_frame/geodata_frame.dart';
part 'src/geo_dart_frame/functions.dart';
part 'src/geo_dart_frame/extension.dart';

part 'src/dart_frame/dart_frame.dart';
part 'src/dart_frame/operations.dart';
part 'src/dart_frame/functions.dart';
part 'src/dart_frame/accessors.dart';

part 'src/series/series.dart';
part 'src/series/operations.dart';
part 'src/series/functions.dart';
part 'src/series/string_accessor.dart';

// This function should return an instance of FileIODesktop or FileIOWeb depending on the platform.
FileIO fileIO = FileIO();
