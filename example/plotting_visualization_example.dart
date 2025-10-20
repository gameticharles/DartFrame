import 'package:dartframe/dartframe.dart';

/// Comprehensive example demonstrating plotting and visualization capabilities in DartFrame
/// This example showcases the integrated plotting functionality that provides
/// pandas-like visualization capabilities for data analysis and presentation.
void main() async {
  print('=== DartFrame Plotting and Visualization Example ===\n');

  // Create sample datasets for visualization
  final salesData = DataFrame.fromRows([
    {'Month': 'Jan', 'Sales': 1200, 'Profit': 240, 'Customers': 45, 'Region': 'North'},
    {'Month': 'Feb', 'Sales': 1350, 'Profit': 270, 'Customers': 52, 'Region': 'North'},
    {'Month': 'Mar', 'Sales': 1100, 'Profit': 220, 'Customers': 41, 'Region': 'North'},
    {'Month': 'Apr', 'Sales': 1450, 'Profit': 290, 'Customers': 58, 'Region': 'South'},
    {'Month': 'May', 'Sales': 1600, 'Profit': 320, 'Customers': 64, 'Region': 'South'},
    {'Month': 'Jun', 'Sales': 1380, 'Profit': 276, 'Customers': 55, 'Region': 'South'},
    {'Month': 'Jul', 'Sales': 1520, 'Profit': 304, 'Customers': 61, 'Region': 'East'},
    {'Month': 'Aug', 'Sales': 1420, 'Profit': 284, 'Customers': 57, 'Region': 'East'},
    {'Month': 'Sep', 'Sales': 1300, 'Profit': 260, 'Customers': 52, 'Region': 'East'},
    {'Month': 'Oct', 'Sales': 1480, 'Profit': 296, 'Customers': 59, 'Region': 'West'},
    {'Month': 'Nov', 'Sales': 1650, 'Profit': 330, 'Customers': 66, 'Region': 'West'},
    {'Month': 'Dec', 'Sales': 1750, 'Profit': 350, 'Customers': 70, 'Region': 'West'},
  ]);

  print('Sample Sales Data:');
  print(salesData.head());
  print('');

  // 1. Basic Line Plots
  print('1. BASIC LINE PLOTS');
  print('=' * 40);

  // Single line plot
  print('Creating line plot for Sales over time...');
  salesData.plot.line(
    x: 'Month',
    y: 'Sales',
    title: 'Monthly Sales Trend',
    xlabel: 'Month',
    ylabel: 'Sales ($)',
    color: 'blue',
    lineStyle: 'solid',
    marker: 'o'
  );

  // Multiple line plot
  print('Creating multi-line plot for Sales and Profit...');
  salesData.plot.line(
    x: 'Month',
    y: ['Sales', 'Profit'],
    title: 'Sales and Profit Trends',
    xlabel: 'Month',
    ylabel: 'Amount ($)',
    colors: ['blue', 'green'],
    legend: true
  );
  print('');

  // 2. Bar Charts
  print('2. BAR CHARTS');
  print('=' * 40);

  // Vertical bar chart
  print('Creating vertical bar chart for regional sales...');
  final regionalSales = salesData.groupBy(['Region']).agg({'Sales': 'sum'});
  regionalSales.plot.bar(
    x: 'Region',
    y: 'Sales_sum',
    title: 'Sales by Region',
    color: ['red', 'green', 'blue', 'orange']
  );

  // Horizontal bar chart
  print('Creating horizontal bar chart...');
  regionalSales.plot.barh(
    x: 'Region',
    y: 'Sales_sum',
    title: 'Sales by Region (Horizontal)',
    color: 'skyblue'
  );

  // Stacked bar chart
  print('Creating stacked bar chart...');
  final quarterlyData = DataFrame.fromRows([
    {'Region': 'North', 'Q1': 3650, 'Q2': 4430, 'Q3': 4240, 'Q4': 4880},
    {'Region': 'South', 'Q1': 3200, 'Q2': 3800, 'Q3': 3600, 'Q4': 4100},
    {'Region': 'East', 'Q1': 2900, 'Q2': 3400, 'Q3': 3200, 'Q4': 3700},
    {'Region': 'West', 'Q1': 2600, 'Q2': 3100, 'Q3': 2900, 'Q4': 3400},
  ]);

  quarterlyData.plot.bar(
    x: 'Region',
    y: ['Q1', 'Q2', 'Q3', 'Q4'],
    stacked: true,
    title: 'Quarterly Sales by Region',
    colors: ['lightblue', 'lightgreen', 'lightcoral', 'lightyellow']
  );
  print('');

  // 3. Scatter Plots
  print('3. SCATTER PLOTS');
  print('=' * 40);

  // Basic scatter plot
  print('Creating scatter plot for Sales vs Profit...');
  salesData.plot.scatter(
    x: 'Sales',
    y: 'Profit',
    title: 'Sales vs Profit Relationship',
    xlabel: 'Sales ($)',
    ylabel: 'Profit ($)',
    color: 'red',
    alpha: 0.7
  );

  // Scatter plot with color mapping
  print('Creating scatter plot with color mapping by region...');
  salesData.plot.scatter(
    x: 'Sales',
    y: 'Profit',
    c: 'Region',
    title: 'Sales vs Profit by Region',
    colormap: 'viridis',
    size: 60,
    alpha: 0.8
  );

  // Scatter plot with size mapping
  print('Creating scatter plot with size mapping by customers...');
  salesData.plot.scatter(
    x: 'Sales',
    y: 'Profit',
    s: 'Customers',
    title: 'Sales vs Profit (Size = Customers)',
    color: 'blue',
    alpha: 0.6
  );
  print('');

  // 4. Histograms
  print('4. HISTOGRAMS');
  print('=' * 40);

  // Single histogram
  print('Creating histogram for Sales distribution...');
  salesData.plot.hist(
    columns: ['Sales'],
    bins: 8,
    title: 'Sales Distribution',
    xlabel: 'Sales ($)',
    ylabel: 'Frequency',
    color: 'lightblue',
    alpha: 0.7
  );

  // Multiple histograms
  print('Creating overlaid histograms...');
  salesData.plot.hist(
    columns: ['Sales', 'Profit'],
    bins: 6,
    title: 'Sales and Profit Distributions',
    alpha: 0.6,
    overlay: true,
    colors: ['blue', 'red']
  );

  // Histogram with density
  print('Creating density histogram...');
  salesData.plot.hist(
    columns: ['Sales'],
    bins: 10,
    density: true,
    title: 'Sales Density Distribution',
    color: 'green',
    alpha: 0.7
  );
  print('');

  // 5. Box Plots
  print('5. BOX PLOTS');
  print('=' * 40);

  // Box plot by group
  print('Creating box plot by region...');
  salesData.plot.box(
    by: 'Region',
    column: 'Sales',
    title: 'Sales Distribution by Region',
    showMeans: true,
    showOutliers: true
  );

  // Multiple box plots
  print('Creating multiple box plots...');
  salesData.plot.box(
    columns: ['Sales', 'Profit', 'Customers'],
    title: 'Distribution Comparison',
    showMeans: true
  );
  print('');

  // 6. Time Series Plots
  print('6. TIME SERIES PLOTS');
  print('=' * 40);

  // Create time series data
  final timeSeriesData = DataFrame.fromRows([
    {'Date': DateTime(2023, 1, 1), 'Price': 100.0, 'Volume': 1000},
    {'Date': DateTime(2023, 1, 2), 'Price': 102.5, 'Volume': 1200},
    {'Date': DateTime(2023, 1, 3), 'Price': 98.7, 'Volume': 800},
    {'Date': DateTime(2023, 1, 4), 'Price': 105.2, 'Volume': 1500},
    {'Date': DateTime(2023, 1, 5), 'Price': 103.8, 'Volume': 1100},
    {'Date': DateTime(2023, 1, 6), 'Price': 107.1, 'Volume': 1300},
    {'Date': DateTime(2023, 1, 7), 'Price': 104.5, 'Volume': 900},
  ]);

  print('Creating time series plot...');
  timeSeriesData.plot.timeSeries(
    x: 'Date',
    y: 'Price',
    title: 'Stock Price Over Time',
    xlabel: 'Date',
    ylabel: 'Price ($)',
    dateFormat: 'MM/dd'
  );

  // Time series with secondary axis
  print('Creating time series with secondary y-axis...');
  timeSeriesData.plot.timeSeries(
    x: 'Date',
    y: ['Price', 'Volume'],
    secondaryY: ['Volume'],
    title: 'Price and Volume Over Time',
    colors: ['blue', 'red']
  );
  print('');

  // 7. Statistical Plots
  print('7. STATISTICAL PLOTS');
  print('=' * 40);

  // Regression plot
  print('Creating regression plot...');
  salesData.plot.regplot(
    x: 'Sales',
    y: 'Profit',
    title: 'Sales vs Profit Regression',
    fitLine: true,
    confidenceInterval: true,
    color: 'blue'
  );

  // Correlation heatmap
  print('Creating correlation heatmap...');
  final numericData = salesData[['Sales', 'Profit', 'Customers']];
  numericData.plot.corrHeatmap(
    annot: true,
    colormap: 'coolwarm',
    title: 'Correlation Matrix'
  );

  // Pair plot
  print('Creating pair plot...');
  numericData.plot.pairplot(
    columns: ['Sales', 'Profit', 'Customers'],
    diagonal: 'hist',
    offDiagonal: 'scatter'
  );
  print('');

  // 8. Series Plotting
  print('8. SERIES PLOTTING');
  print('=' * 40);

  final salesSeries = salesData['Sales'];

  // Series line plot
  print('Creating series line plot...');
  salesSeries.plot.line(
    title: 'Sales Series',
    color: 'green'
  );

  // Series histogram
  print('Creating series histogram...');
  salesSeries.plot.hist(
    bins: 8,
    title: 'Sales Distribution',
    color: 'orange',
    alpha: 0.7
  );

  // Series box plot
  print('Creating series box plot...');
  salesSeries.plot.box(
    title: 'Sales Box Plot',
    showMeans: true
  );

  // Series density plot
  print('Creating series density plot...');
  salesSeries.plot.density(
    title: 'Sales Density',
    color: 'purple'
  );
  print('');

  // 9. Customization Examples
  print('9. CUSTOMIZATION EXAMPLES');
  print('=' * 40);

  // Custom styling
  print('Creating plot with custom styling...');
  salesData.plot.line(
    x: 'Month',
    y: 'Sales',
    title: 'Customized Sales Plot',
    style: PlotStyle(
      backgroundColor: 'white',
      gridColor: 'lightgray',
      titleFont: FontStyle(size: 16, weight: 'bold'),
      axisFont: FontStyle(size: 12),
      colors: ['#1f77b4']
    )
  );

  // Plot with annotations
  print('Creating plot with annotations...');
  final plot = salesData.plot.line(x: 'Month', y: 'Sales');
  plot.annotate(
    text: 'Peak Sales',
    xy: ['Dec', 1750],
    arrow: true,
    arrowColor: 'red'
  );
  plot.addHorizontalLine(
    y: 1400,
    color: 'red',
    linestyle: 'dashed',
    label: 'Target'
  );
  plot.addVerticalLine(
    x: 'Jun',
    color: 'green',
    linestyle: 'dotted',
    label: 'Mid-Year'
  );
  print('');

  // 10. Multiple Subplots
  print('10. MULTIPLE SUBPLOTS');
  print('=' * 40);

  print('Creating subplot layout...');
  final fig = PlotFigure(rows: 2, cols: 2, figsize: [12, 10]);

  // Subplot 1: Line plot
  fig.subplot(0, 0).line(
    salesData,
    x: 'Month',
    y: 'Sales',
    title: 'Sales Trend'
  );

  // Subplot 2: Bar plot
  fig.subplot(0, 1).bar(
    regionalSales,
    x: 'Region',
    y: 'Sales_sum',
    title: 'Sales by Region'
  );

  // Subplot 3: Scatter plot
  fig.subplot(1, 0).scatter(
    salesData,
    x: 'Sales',
    y: 'Profit',
    title: 'Sales vs Profit'
  );

  // Subplot 4: Histogram
  fig.subplot(1, 1).hist(
    salesData,
    column: 'Sales',
    title: 'Sales Distribution'
  );

  fig.suptitle('Sales Analysis Dashboard');
  fig.show();
  print('');

  // 11. Geospatial Plotting (Conceptual)
  print('11. GEOSPATIAL PLOTTING');
  print('=' * 40);

  // Create sample geospatial data
  final geoData = GeoDataFrame.fromCoordinates([
    [-74.0060, 40.7128], // New York
    [-118.2437, 34.0522], // Los Angeles
    [-87.6298, 41.8781], // Chicago
  ], attributes: DataFrame.fromRows([
    {'city': 'New York', 'population': 8000000},
    {'city': 'Los Angeles', 'population': 4000000},
    {'city': 'Chicago', 'population': 2700000},
  ]));

  print('Creating map visualization...');
  geoData.plot.map(
    column: 'population',
    colormap: 'viridis',
    legend: true,
    title: 'Population by City',
    markerSize: 'population'
  );

  print('Creating choropleth map...');
  geoData.plot.choropleth(
    column: 'population',
    scheme: 'quantiles',
    k: 3,
    colormap: 'Blues',
    edgecolor: 'black',
    title: 'Population Choropleth'
  );
  print('');

  // 12. Interactive Plotting (Conceptual)
  print('12. INTERACTIVE PLOTTING');
  print('=' * 40);

  print('Creating interactive plot...');
  salesData.plot.interactive(
    x: 'Month',
    y: 'Sales',
    hover: ['Region', 'Profit', 'Customers'],
    title: 'Interactive Sales Plot'
  );

  print('Creating interactive dashboard...');
  final dashboard = InteractiveDashboard();
  dashboard.addPlot(
    salesData.plot.line(x: 'Month', y: 'Sales'),
    position: [0, 0]
  );
  dashboard.addPlot(
    salesData.plot.scatter(x: 'Sales', y: 'Profit'),
    position: [0, 1]
  );
  dashboard.addFilter('Region', salesData['Region'].unique());
  dashboard.show();
  print('');

  // Summary
  print('PLOTTING SUMMARY');
  print('=' * 40);
  print('✓ Line plots for trends and time series');
  print('✓ Bar charts for categorical comparisons');
  print('✓ Scatter plots for relationships');
  print('✓ Histograms for distributions');
  print('✓ Box plots for statistical summaries');
  print('✓ Statistical plots (regression, correlation)');
  print('✓ Geospatial visualizations');
  print('✓ Custom styling and annotations');
  print('✓ Multiple subplots and dashboards');
  print('✓ Interactive plotting capabilities');

  print('\n=== Plotting and Visualization Example Complete ===');
}