import 'dart:async';
import 'package:http/http.dart' as http;
import '../data_frame/data_frame.dart';
import 'data_source.dart';
import 'csv_reader.dart';

/// Registry of popular scientific and machine learning datasets.
///
/// Provides easy access to commonly used datasets for testing, learning,
/// and prototyping. Datasets are loaded from reliable public sources.
///
/// ## Available Datasets
/// - **mnist**: MNIST handwritten digits (training and test sets)
/// - **iris**: Iris flower classification dataset
/// - **titanic**: Titanic passenger survival dataset
/// - **boston**: Boston housing prices dataset
/// - **wine**: Wine quality dataset
/// - **diabetes**: Diabetes dataset
/// - **breast_cancer**: Breast cancer Wisconsin dataset
/// - **california_housing**: California housing prices
///
/// ## Example
/// ```dart
/// // Load MNIST training data
/// final mnist = await DataFrame.read('dataset://mnist/train');
///
/// // Load Iris dataset
/// final iris = await DataFrame.read('dataset://iris');
///
/// // Load with options
/// final titanic = await DataFrame.read('dataset://titanic', options: {
///   'subset': 'train',  // or 'test'
/// });
/// ```
class ScientificDatasets {
  static final Map<String, DatasetInfo> _datasets = {
    'mnist': DatasetInfo(
      name: 'MNIST',
      description: 'Handwritten digits dataset (0-9)',
      source: 'http://yann.lecun.com/exdb/mnist/',
      subsets: ['train', 'test'],
      features: 784, // 28x28 pixels
      samples: {'train': 60000, 'test': 10000},
      loader: _loadMnist,
    ),
    'iris': DatasetInfo(
      name: 'Iris',
      description: 'Iris flower species classification',
      source: 'https://archive.ics.uci.edu/ml/datasets/iris',
      features: 4,
      samples: {'full': 150},
      loader: _loadIris,
    ),
    'titanic': DatasetInfo(
      name: 'Titanic',
      description: 'Titanic passenger survival dataset',
      source: 'https://www.kaggle.com/c/titanic',
      subsets: ['train', 'test'],
      features: 11,
      samples: {'train': 891, 'test': 418},
      loader: _loadTitanic,
    ),
    'wine': DatasetInfo(
      name: 'Wine Quality',
      description: 'Wine quality dataset',
      source: 'https://archive.ics.uci.edu/ml/datasets/wine+quality',
      subsets: ['red', 'white'],
      features: 11,
      samples: {'red': 1599, 'white': 4898},
      loader: _loadWine,
    ),
    'diabetes': DatasetInfo(
      name: 'Diabetes',
      description: 'Diabetes dataset for regression',
      source: 'https://www4.stat.ncsu.edu/~boos/var.select/diabetes.html',
      features: 10,
      samples: {'full': 442},
      loader: _loadDiabetes,
    ),
    'breast_cancer': DatasetInfo(
      name: 'Breast Cancer Wisconsin',
      description: 'Breast cancer diagnostic dataset',
      source:
          'https://archive.ics.uci.edu/ml/datasets/Breast+Cancer+Wisconsin+(Diagnostic)',
      features: 30,
      samples: {'full': 569},
      loader: _loadBreastCancer,
    ),
    'california_housing': DatasetInfo(
      name: 'California Housing',
      description: 'California housing prices dataset',
      source: 'https://www.dcc.fc.up.pt/~ltorgo/Regression/cal_housing.html',
      features: 8,
      samples: {'full': 20640},
      loader: _loadCaliforniaHousing,
    ),
    'boston': DatasetInfo(
      name: 'Boston Housing',
      description: 'Boston housing prices dataset',
      source: 'https://www.cs.toronto.edu/~delve/data/boston/bostonDetail.html',
      features: 13,
      samples: {'full': 506},
      loader: _loadBoston,
    ),
  };

  /// Gets information about a dataset
  static DatasetInfo? getInfo(String name) {
    return _datasets[name.toLowerCase()];
  }

  /// Lists all available datasets
  static List<String> listDatasets() {
    return _datasets.keys.toList();
  }

  /// Lists all available datasets with their descriptions
  static Map<String, String> listDatasetsWithDescriptions() {
    return Map.fromEntries(
      _datasets.entries.map((e) => MapEntry(e.key, e.value.description)),
    );
  }

  /// Loads a dataset by name
  static Future<DataFrame> load(
    String name, {
    String? subset,
    Map<String, dynamic>? options,
  }) async {
    final info = _datasets[name.toLowerCase()];
    if (info == null) {
      throw DataSourceError('Unknown dataset: $name');
    }

    return await info.loader(subset, options ?? {});
  }

  // Dataset loaders

  static Future<DataFrame> _loadMnist(
    String? subset,
    Map<String, dynamic> options,
  ) async {
    subset ??= 'train';
    if (!['train', 'test'].contains(subset)) {
      throw DataSourceError('MNIST subset must be "train" or "test"');
    }

    // Use a simplified version from a reliable source
    final url = subset == 'train'
        ? 'https://raw.githubusercontent.com/pjreddie/mnist-csv-png/master/mnist_train.csv'
        : 'https://raw.githubusercontent.com/pjreddie/mnist-csv-png/master/mnist_test.csv';

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(Duration(seconds: 60));
      if (response.statusCode != 200) {
        throw DataSourceError('Failed to download MNIST dataset');
      }

      return CsvReader().parseCsvContent(response.body, {'hasHeader': true});
    } catch (e) {
      throw DataSourceError('Failed to load MNIST dataset', e);
    }
  }

  static Future<DataFrame> _loadIris(
    String? subset,
    Map<String, dynamic> options,
  ) async {
    const url =
        'https://raw.githubusercontent.com/mwaskom/seaborn-data/master/iris.csv';

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw DataSourceError('Failed to download Iris dataset');
      }

      return CsvReader().parseCsvContent(response.body, {'hasHeader': true});
    } catch (e) {
      throw DataSourceError('Failed to load Iris dataset', e);
    }
  }

  static Future<DataFrame> _loadTitanic(
    String? subset,
    Map<String, dynamic> options,
  ) async {
    subset ??= 'train';
    if (!['train', 'test'].contains(subset)) {
      throw DataSourceError('Titanic subset must be "train" or "test"');
    }

    final url = subset == 'train'
        ? 'https://raw.githubusercontent.com/datasciencedojo/datasets/master/titanic.csv'
        : 'https://raw.githubusercontent.com/datasciencedojo/datasets/master/titanic_test.csv';

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw DataSourceError('Failed to download Titanic dataset');
      }

      return CsvReader().parseCsvContent(response.body, {'hasHeader': true});
    } catch (e) {
      throw DataSourceError('Failed to load Titanic dataset', e);
    }
  }

  static Future<DataFrame> _loadWine(
    String? subset,
    Map<String, dynamic> options,
  ) async {
    subset ??= 'red';
    if (!['red', 'white'].contains(subset)) {
      throw DataSourceError('Wine subset must be "red" or "white"');
    }

    final url = subset == 'red'
        ? 'https://raw.githubusercontent.com/mwaskom/seaborn-data/master/wine.csv'
        : 'https://raw.githubusercontent.com/mwaskom/seaborn-data/master/wine.csv';

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw DataSourceError('Failed to download Wine dataset');
      }

      return CsvReader().parseCsvContent(response.body, {'hasHeader': true});
    } catch (e) {
      throw DataSourceError('Failed to load Wine dataset', e);
    }
  }

  static Future<DataFrame> _loadDiabetes(
    String? subset,
    Map<String, dynamic> options,
  ) async {
    // Using sklearn's diabetes dataset via a public source
    const url =
        'https://raw.githubusercontent.com/jbrownlee/Datasets/master/pima-indians-diabetes.csv';

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw DataSourceError('Failed to download Diabetes dataset');
      }

      return CsvReader().parseCsvContent(response.body, {
        'hasHeader': false,
        'columnNames': [
          'pregnancies',
          'glucose',
          'blood_pressure',
          'skin_thickness',
          'insulin',
          'bmi',
          'diabetes_pedigree',
          'age',
          'outcome'
        ],
      });
    } catch (e) {
      throw DataSourceError('Failed to load Diabetes dataset', e);
    }
  }

  static Future<DataFrame> _loadBreastCancer(
    String? subset,
    Map<String, dynamic> options,
  ) async {
    const url =
        'https://raw.githubusercontent.com/mwaskom/seaborn-data/master/breast_cancer.csv';

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw DataSourceError('Failed to download Breast Cancer dataset');
      }

      return CsvReader().parseCsvContent(response.body, {'hasHeader': true});
    } catch (e) {
      throw DataSourceError('Failed to load Breast Cancer dataset', e);
    }
  }

  static Future<DataFrame> _loadCaliforniaHousing(
    String? subset,
    Map<String, dynamic> options,
  ) async {
    const url =
        'https://raw.githubusercontent.com/ageron/handson-ml/master/datasets/housing/housing.csv';

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw DataSourceError('Failed to download California Housing dataset');
      }

      return CsvReader().parseCsvContent(response.body, {'hasHeader': true});
    } catch (e) {
      throw DataSourceError('Failed to load California Housing dataset', e);
    }
  }

  static Future<DataFrame> _loadBoston(
    String? subset,
    Map<String, dynamic> options,
  ) async {
    const url =
        'https://raw.githubusercontent.com/selva86/datasets/master/BostonHousing.csv';

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw DataSourceError('Failed to download Boston Housing dataset');
      }

      return CsvReader().parseCsvContent(response.body, {'hasHeader': true});
    } catch (e) {
      throw DataSourceError('Failed to load Boston Housing dataset', e);
    }
  }
}

/// Information about a dataset
class DatasetInfo {
  final String name;
  final String description;
  final String source;
  final List<String>? subsets;
  final int features;
  final Map<String, int> samples;
  final Future<DataFrame> Function(String?, Map<String, dynamic>) loader;

  DatasetInfo({
    required this.name,
    required this.description,
    required this.source,
    this.subsets,
    required this.features,
    required this.samples,
    required this.loader,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Dataset: $name');
    buffer.writeln('Description: $description');
    buffer.writeln('Features: $features');
    buffer.writeln('Samples: $samples');
    if (subsets != null) {
      buffer.writeln('Subsets: ${subsets!.join(", ")}');
    }
    buffer.writeln('Source: $source');
    return buffer.toString();
  }
}

/// Data source for scientific datasets using dataset:// URI scheme.
///
/// ## Example
/// ```dart
/// // Register the source
/// DataSourceRegistry.register(ScientificDataSource());
///
/// // Load datasets
/// final iris = await DataFrame.read('dataset://iris');
/// final mnist = await DataFrame.read('dataset://mnist/train');
/// final titanic = await DataFrame.read('dataset://titanic/test');
/// ```
class ScientificDataSource extends DataSource {
  @override
  String get scheme => 'dataset';

  @override
  bool canHandle(Uri uri) {
    return uri.scheme == 'dataset';
  }

  @override
  Future<DataFrame> read(Uri uri, Map<String, dynamic> options) async {
    // Parse URI: dataset://name or dataset://name/subset
    // Handle both host-based (dataset://iris) and path-based (dataset:///iris) URIs
    String? name;
    String? subset;

    if (uri.host.isNotEmpty) {
      name = uri.host;
      final pathParts = uri.path.split('/').where((p) => p.isNotEmpty).toList();
      subset = pathParts.isNotEmpty ? pathParts[0] : null;
    } else {
      final parts = uri.path.split('/').where((p) => p.isNotEmpty).toList();
      if (parts.isEmpty) {
        throw DataSourceError(
            'Dataset name is required: dataset://name[/subset]');
      }
      name = parts[0];
      subset = parts.length > 1 ? parts[1] : null;
    }

    return await ScientificDatasets.load(name,
        subset: subset, options: options);
  }

  @override
  Future<void> write(
      DataFrame df, Uri uri, Map<String, dynamic> options) async {
    throw UnsupportedError('Writing to scientific datasets is not supported');
  }

  @override
  Future<Map<String, dynamic>> inspect(Uri uri) async {
    // Handle both host-based (dataset://iris) and path-based (dataset:///iris) URIs
    String? name;

    if (uri.host.isNotEmpty) {
      name = uri.host;
    } else {
      final parts = uri.path.split('/').where((p) => p.isNotEmpty).toList();
      if (parts.isEmpty) {
        return {
          'available_datasets':
              ScientificDatasets.listDatasetsWithDescriptions(),
        };
      }
      name = parts[0];
    }

    final info = ScientificDatasets.getInfo(name);
    if (info == null) {
      throw DataSourceError('Unknown dataset: $name');
    }

    return {
      'name': info.name,
      'description': info.description,
      'features': info.features,
      'samples': info.samples,
      'subsets': info.subsets,
      'source': info.source,
    };
  }
}
