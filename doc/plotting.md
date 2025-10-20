# Plotting and Visualization Documentation

DartFrame provides integrated plotting capabilities that allow you to create visualizations directly from DataFrames and Series, similar to pandas plotting functionality.

## Table of Contents
- [Plotting and Visualization Documentation](#plotting-and-visualization-documentation)
  - [Table of Contents](#table-of-contents)
  - [Basic Plotting Interface](#basic-plotting-interface)
    - [1. DataFrame Plotting](#1-dataframe-plotting)
    - [2. Series Plotting](#2-series-plotting)
  - [Chart Types](#chart-types)
    - [1. Line Plots](#1-line-plots)
    - [2. Bar Charts](#2-bar-charts)
    - [3. Scatter Plots](#3-scatter-plots)
    - [4. Histograms](#4-histograms)
    - [5. Box Plots](#5-box-plots)
  - [Time Series Plotting](#time-series-plotting)
    - [1. Time Series Line Plots](#1-time-series-line-plots)
    - [2. Seasonal Decomposition Plots](#2-seasonal-decomposition-plots)
  - [Statistical Plots](#statistical-plots)
    - [1. Distribution Plots](#1-distribution-plots)
    - [2. Correlation Plots](#2-correlation-plots)
  - [Geospatial Plotting](#geospatial-plotting)
    - [1. Map Visualization](#1-map-visualization)
    - [2. Choropleth Maps](#2-choropleth-maps)
  - [Customization Options](#customization-options)
    - [1. Styling](#1-styling)
    - [2. Annotations](#2-annotations)
    - [3. Multiple Subplots](#3-multiple-subplots)

## Basic Plotting Interface

### 1. DataFrame Plotting

DataFrames provide a convenient `.plot` accessor for creating various types of visualizations.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'Date': DateTime(2023, 1, 1), 'Sales': 100, 'Profit': 20},
  {'Date': DateTime(2023, 1, 2), 'Sales': 120, 'Profit': 25},
  {'Date': DateTime(2023, 1, 3), 'Sales': 90, 'Profit': 15},
  {'Date': DateTime(2023, 1, 4), 'Sales': 150, 'Profit': 35},
]);

// Basic line plot
df.plot.line(x: 'Date', y: ['Sales', 'Profit']);

// Multiple chart types
df.plot.bar(x: 'Date', y: 'Sales');
df.plot.scatter(x: 'Sales', y: 'Profit');
df.plot.hist(columns: ['Sales', 'Profit']);
```

### 2. Series Plotting

Series objects also provide plotting capabilities for single-variable visualizations.

**Example:**
```dart
final sales = df['Sales'];

// Series line plot
sales.plot.line();

// Series histogram
sales.plot.hist(bins: 10);

// Series box plot
sales.plot.box();

// Series density plot
sales.plot.density();
```

## Chart Types

### 1. Line Plots

Create line plots for continuous data and time series.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'Month': 'Jan', 'Revenue': 1000, 'Expenses': 800},
  {'Month': 'Feb', 'Revenue': 1200, 'Expenses': 900},
  {'Month': 'Mar', 'Revenue': 1100, 'Expenses': 850},
]);

// Basic line plot
df.plot.line(
  x: 'Month',
  y: ['Revenue', 'Expenses'],
  title: 'Monthly Financial Data',
  xlabel: 'Month',
  ylabel: 'Amount ($)'
);

// Customized line plot
df.plot.line(
  x: 'Month',
  y: 'Revenue',
  color: 'blue',
  lineStyle: 'dashed',
  marker: 'o',
  markerSize: 8
);
```

### 2. Bar Charts

Create bar charts for categorical data comparison.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'Category': 'A', 'Value': 25},
  {'Category': 'B', 'Value': 30},
  {'Category': 'C', 'Value': 20},
  {'Category': 'D', 'Value': 35},
]);

// Vertical bar chart
df.plot.bar(
  x: 'Category',
  y: 'Value',
  title: 'Category Comparison'
);

// Horizontal bar chart
df.plot.barh(
  x: 'Category',
  y: 'Value',
  color: ['red', 'green', 'blue', 'orange']
);

// Stacked bar chart
final multiDf = DataFrame.fromRows([
  {'Category': 'A', 'Q1': 10, 'Q2': 15, 'Q3': 12, 'Q4': 18},
  {'Category': 'B', 'Q1': 12, 'Q2': 18, 'Q3': 14, 'Q4': 20},
]);

multiDf.plot.bar(
  x: 'Category',
  y: ['Q1', 'Q2', 'Q3', 'Q4'],
  stacked: true
);
```

### 3. Scatter Plots

Create scatter plots to visualize relationships between variables.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'Height': 170, 'Weight': 65, 'Age': 25},
  {'Height': 175, 'Weight': 70, 'Age': 30},
  {'Height': 165, 'Weight': 60, 'Age': 22},
  {'Height': 180, 'Weight': 75, 'Age': 35},
]);

// Basic scatter plot
df.plot.scatter(
  x: 'Height',
  y: 'Weight',
  title: 'Height vs Weight'
);

// Scatter plot with color mapping
df.plot.scatter(
  x: 'Height',
  y: 'Weight',
  c: 'Age', // Color by age
  colormap: 'viridis',
  size: 50
);

// Scatter plot with size mapping
df.plot.scatter(
  x: 'Height',
  y: 'Weight',
  s: 'Age', // Size by age
  alpha: 0.7
);
```

### 4. Histograms

Create histograms to visualize data distributions.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'Score': 85}, {'Score': 92}, {'Score': 78}, {'Score': 88},
  {'Score': 95}, {'Score': 82}, {'Score': 90}, {'Score': 87},
]);

// Basic histogram
df.plot.hist(
  columns: ['Score'],
  bins: 10,
  title: 'Score Distribution'
);

// Multiple histograms
final multiDf = DataFrame.fromRows([
  {'Math': 85, 'Science': 90},
  {'Math': 92, 'Science': 88},
  {'Math': 78, 'Science': 85},
]);

multiDf.plot.hist(
  columns: ['Math', 'Science'],
  bins: 8,
  alpha: 0.7,
  overlay: true
);

// Histogram with density
df.plot.hist(
  columns: ['Score'],
  density: true,
  cumulative: false
);
```

### 5. Box Plots

Create box plots to visualize data distribution and outliers.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'Group': 'A', 'Value': 10}, {'Group': 'A', 'Value': 12},
  {'Group': 'B', 'Value': 15}, {'Group': 'B', 'Value': 18},
  {'Group': 'C', 'Value': 8}, {'Group': 'C', 'Value': 14},
]);

// Box plot by group
df.plot.box(
  by: 'Group',
  column: 'Value',
  title: 'Value Distribution by Group'
);

// Multiple box plots
multiDf.plot.box(
  columns: ['Math', 'Science'],
  showMeans: true,
  showOutliers: true
);
```

## Time Series Plotting

### 1. Time Series Line Plots

Specialized plotting for time series data.

**Example:**
```dart
final timeSeries = DataFrame.fromRows([
  {'Date': DateTime(2023, 1, 1), 'Price': 100.0},
  {'Date': DateTime(2023, 1, 2), 'Price': 102.5},
  {'Date': DateTime(2023, 1, 3), 'Price': 98.7},
  {'Date': DateTime(2023, 1, 4), 'Price': 105.2},
]);

// Time series line plot
timeSeries.plot.timeSeries(
  x: 'Date',
  y: 'Price',
  title: 'Price Over Time',
  dateFormat: 'MM/dd'
);

// Multiple time series
timeSeries.plot.timeSeries(
  x: 'Date',
  y: ['Price', 'Volume'],
  secondaryY: ['Volume'], // Use secondary y-axis
  title: 'Price and Volume Over Time'
);
```

### 2. Seasonal Decomposition Plots

Visualize seasonal patterns in time series data.

**Example:**
```dart
final seasonalData = DataFrame.fromRows([
  // Monthly data with seasonal patterns
]);

// Seasonal decomposition plot
seasonalData.plot.seasonalDecompose(
  dateColumn: 'Date',
  valueColumn: 'Value',
  period: 12, // Monthly seasonality
  model: 'additive'
);

// Autocorrelation plot
seasonalData.plot.autocorrelation(
  column: 'Value',
  lags: 40
);
```

## Statistical Plots

### 1. Distribution Plots

Visualize statistical distributions and relationships.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'X': 1, 'Y': 2}, {'X': 2, 'Y': 4},
  {'X': 3, 'Y': 6}, {'X': 4, 'Y': 8},
]);

// Regression plot
df.plot.regplot(
  x: 'X',
  y: 'Y',
  fitLine: true,
  confidenceInterval: true
);

// Residual plot
df.plot.residplot(
  x: 'X',
  y: 'Y',
  lowess: true
);

// Q-Q plot
df.plot.qqplot(
  column: 'Y',
  distribution: 'normal'
);
```

### 2. Correlation Plots

Visualize correlations between variables.

**Example:**
```dart
final df = DataFrame.fromRows([
  {'A': 1, 'B': 2, 'C': 3, 'D': 4},
  {'A': 2, 'B': 4, 'C': 1, 'D': 3},
  {'A': 3, 'B': 1, 'C': 4, 'D': 2},
]);

// Correlation heatmap
df.plot.corrHeatmap(
  annot: true, // Show correlation values
  colormap: 'coolwarm',
  title: 'Correlation Matrix'
);

// Pair plot
df.plot.pairplot(
  columns: ['A', 'B', 'C'],
  diagonal: 'hist', // 'hist' or 'kde'
  offDiagonal: 'scatter'
);
```

## Geospatial Plotting

### 1. Map Visualization

Plot geospatial data on maps.

**Example:**
```dart
final gdf = await GeoDataFrame.readFile('data.geojson');

// Basic map plot
gdf.plot.map(
  column: 'population',
  colormap: 'viridis',
  legend: true,
  title: 'Population by Region'
);

// Interactive map
gdf.plot.interactiveMap(
  column: 'population',
  tooltip: ['name', 'population'],
  basemap: 'OpenStreetMap'
);
```

### 2. Choropleth Maps

Create choropleth maps for statistical visualization.

**Example:**
```dart
final gdf = await GeoDataFrame.readFile('regions.geojson');

// Choropleth map
gdf.plot.choropleth(
  column: 'density',
  scheme: 'quantiles',
  k: 5, // Number of classes
  colormap: 'Blues',
  edgecolor: 'black',
  linewidth: 0.5
);

// Bivariate choropleth
gdf.plot.bivariateMap(
  x: 'income',
  y: 'education',
  colormap: 'bivariate'
);
```

## Customization Options

### 1. Styling

Customize plot appearance and styling.

**Example:**
```dart
// Set global plot style
PlotStyle.setTheme('seaborn');

// Custom styling
df.plot.line(
  x: 'Date',
  y: 'Value',
  style: PlotStyle(
    backgroundColor: 'white',
    gridColor: 'lightgray',
    titleFont: FontStyle(size: 16, weight: 'bold'),
    axisFont: FontStyle(size: 12),
    colors: ['#1f77b4', '#ff7f0e', '#2ca02c']
  )
);
```

### 2. Annotations

Add annotations and labels to plots.

**Example:**
```dart
df.plot.line(x: 'Date', y: 'Value')
  ..annotate(
    text: 'Peak Value',
    xy: [DateTime(2023, 1, 15), 150],
    arrow: true
  )
  ..addHorizontalLine(y: 100, color: 'red', linestyle: 'dashed')
  ..addVerticalLine(x: DateTime(2023, 1, 10), color: 'green');
```

### 3. Multiple Subplots

Create multiple subplots in a single figure.

**Example:**
```dart
// Create subplot layout
final fig = PlotFigure(rows: 2, cols: 2);

// Add plots to subplots
fig.subplot(0, 0).line(df, x: 'Date', y: 'Sales');
fig.subplot(0, 1).bar(df, x: 'Category', y: 'Value');
fig.subplot(1, 0).scatter(df, x: 'X', y: 'Y');
fig.subplot(1, 1).hist(df, column: 'Score');

// Show the figure
fig.show();
```

This documentation covers the comprehensive plotting and visualization capabilities available in DartFrame, providing pandas-like plotting functionality for data analysis and presentation.