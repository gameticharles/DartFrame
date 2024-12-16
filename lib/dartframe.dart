// ignore_for_file: depend_on_referenced_packages

library;

import 'dart:convert';
import 'dart:math';

import 'package:intl/intl.dart';

import 'src/file_helper/file_io.dart';

part 'src/dart_frame/dart_frame.dart';
part 'src/dart_frame/operations.dart';
part 'src/dart_frame/functions.dart';
part 'src/series/series.dart';
part 'src/series/operations.dart';
part 'src/series/functions.dart';

// This function should return an instance of FileIODesktop or FileIOWeb depending on the platform.
FileIO fileIO = FileIO();
