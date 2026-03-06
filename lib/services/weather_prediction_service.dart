import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class WeatherPredictionService {
  static final WeatherPredictionService _instance =
      WeatherPredictionService._internal();
  factory WeatherPredictionService() => _instance;
  WeatherPredictionService._internal();

  OrtSession? _session;
  Map<String, dynamic>? _metadata;
  bool _isInitialized = false;
  List<String> _featureNames = [];
  List<String> _classNames = [];
  List<double> _scalerMean = [];
  List<double> _scalerScale = [];

  // Weather condition categories with colors and icons
  static const Map<String, Color> weatherColors = {
    'Clear': Color(0xFFFFD700),
    'Partly Cloudy': Color(0xFFC0C0C0),
    'Rain': Color(0xFF4682B4),
    'Drizzle': Color(0xFF87CEEB),
    'Thunderstorm': Color(0xFF4B0082),
    'Snow': Color(0xFFFFFFFF),
  };

  static const Map<String, IconData> weatherIcons = {
    'Clear': Icons.wb_sunny,
    'Partly Cloudy': Icons.wb_cloudy,
    'Rain': Icons.umbrella,
    'Drizzle': Icons.grain,
    'Thunderstorm': Icons.flash_on,
    'Snow': Icons.ac_unit,
  };

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize ONNX Runtime
      OrtEnv.instance.init();

      // Load model from assets
      final modelData = await rootBundle.load(
        'assets/models/weather_model.onnx',
      );
      final modelBytes = modelData.buffer.asUint8List();

      // Create session
      final sessionOptions = OrtSessionOptions();
      _session = OrtSession.fromBuffer(modelBytes, sessionOptions);

      // Load metadata
      try {
        final metadataString = await rootBundle.loadString(
          'assets/models/model_metadata.json',
        );
        _metadata = json.decode(metadataString);

        if (_metadata != null) {
          if (_metadata!.containsKey('feature_names')) {
            _featureNames = List<String>.from(_metadata!['feature_names']);
          }
          if (_metadata!.containsKey('classes')) {
            _classNames = List<String>.from(_metadata!['classes']);
          }
          if (_metadata!.containsKey('scaler_mean')) {
            _scalerMean = List<double>.from(_metadata!['scaler_mean']);
          }
          if (_metadata!.containsKey('scaler_scale')) {
            _scalerScale = List<double>.from(_metadata!['scaler_scale']);
          }
        }
      } catch (e) {
        print('Metadata not found, using default: $e');
        _metadata = {};
      }

      _isInitialized = true;
      print('Weather prediction model initialized successfully');
      print('Classes: $_classNames');
    } catch (e) {
      print('Error initializing weather model: $e');
    }
  }

  // Get weather data from Open-Meteo API
  Future<Map<String, double>> _getWeatherFeatures(
    double lat,
    double lng,
    DateTime date,
  ) async {
    try {
      final url =
          'https://archive-api.open-meteo.com/v1/archive?'
          'latitude=$lat&longitude=$lng'
          '&start_date=${_formatDate(date)}'
          '&end_date=${_formatDate(date)}'
          '&daily=temperature_2m_max,temperature_2m_min,temperature_2m_mean,'
          'apparent_temperature_max,apparent_temperature_min,apparent_temperature_mean,'
          'daylight_duration,sunshine_duration,precipitation_sum,rain_sum,'
          'precipitation_hours,wind_speed_10m_max,wind_gusts_10m_max,'
          'wind_direction_10m_dominant,shortwave_radiation_sum,et0_fao_evapotranspiration'
          '&timezone=auto';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final daily = data['daily'];

        if (daily != null &&
            daily['time'] != null &&
            daily['time'].isNotEmpty) {
          return {
            'temperature_2m_max_C': (daily['temperature_2m_max']?[0] ?? 30.0)
                .toDouble(),
            'temperature_2m_min_C': (daily['temperature_2m_min']?[0] ?? 25.0)
                .toDouble(),
            'temperature_2m_mean_C': (daily['temperature_2m_mean']?[0] ?? 27.0)
                .toDouble(),
            'apparent_temperature_max_C':
                (daily['apparent_temperature_max']?[0] ?? 32.0).toDouble(),
            'apparent_temperature_min_C':
                (daily['apparent_temperature_min']?[0] ?? 26.0).toDouble(),
            'apparent_temperature_mean_C':
                (daily['apparent_temperature_mean']?[0] ?? 29.0).toDouble(),
            'daylight_duration_s': (daily['daylight_duration']?[0] ?? 43200)
                .toDouble(),
            'sunshine_duration_s': (daily['sunshine_duration']?[0] ?? 36000)
                .toDouble(),
            'precipitation_sum_mm': (daily['precipitation_sum']?[0] ?? 0.0)
                .toDouble(),
            'rain_sum_mm': (daily['rain_sum']?[0] ?? 0.0).toDouble(),
            'precipitation_hours_h': (daily['precipitation_hours']?[0] ?? 0.0)
                .toDouble(),
            'wind_speed_10m_max_km_h': (daily['wind_speed_10m_max']?[0] ?? 10.0)
                .toDouble(),
            'wind_gusts_10m_max_km_h': (daily['wind_gusts_10m_max']?[0] ?? 15.0)
                .toDouble(),
            'wind_direction_10m_dominant':
                (daily['wind_direction_10m_dominant']?[0] ?? 180.0).toDouble(),
            'shortwave_radiation_sum_MJ_m2':
                (daily['shortwave_radiation_sum']?[0] ?? 20.0).toDouble(),
            'et0_fao_evapotranspiration_mm':
                (daily['et0_fao_evapotranspiration']?[0] ?? 5.0).toDouble(),
          };
        }
      }
    } catch (e) {
      print('Error fetching weather data from API: $e');
    }
    return _getFallbackFeatures(date);
  }

  // Prepare features in correct order and scale them
  List<double> _prepareFeatures(Map<String, double> features) {
    List<double> rawFeatures = [];

    for (String featureName in _featureNames) {
      rawFeatures.add(features[featureName] ?? 0.0);
    }

    // Scale features if scaler data is available
    if (_scalerMean.isNotEmpty && _scalerScale.isNotEmpty) {
      List<double> scaledFeatures = [];
      for (int i = 0; i < rawFeatures.length; i++) {
        scaledFeatures.add((rawFeatures[i] - _scalerMean[i]) / _scalerScale[i]);
      }
      return scaledFeatures;
    }

    return rawFeatures;
  }

  // Predict weather using ML model
  Future<Map<String, dynamic>> predictWeather({
    required double latitude,
    required double longitude,
    required DateTime date,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      // Get weather features
      final features = await _getWeatherFeatures(latitude, longitude, date);

      // If model not initialized, use rule-based
      if (_session == null || _classNames.isEmpty) {
        return _getRuleBasedPrediction(date, features);
      }

      // Prepare features for model
      final featureList = _prepareFeatures(features);

      // Create input tensor with correct shape [1, num_features]
      final inputShape = [1, featureList.length];
      final inputTensor = OrtValueTensor.createTensorWithDataList(
        featureList,
        inputShape,
      );

      // Run inference
      final runOptions = OrtRunOptions();
      final inputs = {'float_input': inputTensor};
      final outputs = _session!.run(runOptions, inputs);

      // FIX: Get output data using value getter or toList() method
      final outputTensor = outputs[0] as OrtValueTensor?;
      if (outputTensor == null) {
        throw Exception('Model output is null');
      }

      // Try to get data - onnxruntime package uses 'value' property or toList()
      List<double> outputData;
      try {
        // Try value getter first (common in newer versions)
        final rawValue = outputTensor.value;
        if (rawValue is List) {
          outputData = rawValue.cast<double>();
        } else if (rawValue is List<List>) {
          // If 2D array, flatten it
          outputData = rawValue.expand((e) => e).cast<double>().toList();
        } else {
          throw Exception('Unexpected output format');
        }
      } catch (e) {
        // Fallback: try to extract from Float32List or similar
        final rawData = outputTensor.value;
        if (rawData is Float32List) {
          outputData = rawData.toList();
        } else if (rawData is List<double>) {
          outputData = rawData;
        } else {
          // Last resort: convert to string and parse (not recommended but fallback)
          outputData = List<double>.from(rawData as List);
        }
      }

      final predictionIndex = _getMaxIndex(outputData);
      final confidence = outputData[predictionIndex];

      final weatherCondition = predictionIndex < _classNames.length
          ? _classNames[predictionIndex]
          : 'Partly Cloudy';

      final isGoodForTravel = [
        'Clear',
        'Partly Cloudy',
      ].contains(weatherCondition);

      // Clean up tensors and options
      inputTensor.release();
      outputTensor.release();
      runOptions.release();

      return {
        'condition': weatherCondition,
        'confidence': confidence,
        'isGoodForTravel': isGoodForTravel,
        'recommendation': _getRecommendation(weatherCondition),
        'color': weatherColors[weatherCondition] ?? Colors.grey,
        'icon': weatherIcons[weatherCondition] ?? Icons.help,
        'temperature': features['temperature_2m_mean_C'] ?? 28.0,
        'precipitation': features['precipitation_sum_mm'] ?? 0.0,
        'windSpeed': features['wind_speed_10m_max_km_h'] ?? 10.0,
      };
    } catch (e) {
      print('Error predicting weather: $e');
      return _getFallbackPrediction();
    }
  }

  // Rule-based prediction (fallback)
  Map<String, dynamic> _getRuleBasedPrediction(
    DateTime date,
    Map<String, double> features,
  ) {
    final month = date.month;
    final precipitation = features['precipitation_sum_mm'] ?? 0;

    String condition;
    if (precipitation > 10) {
      condition = 'Rain';
    } else if (precipitation > 5) {
      condition = 'Drizzle';
    } else if (month >= 5 && month <= 9) {
      condition = 'Partly Cloudy';
    } else if (month >= 10 && month <= 11) {
      condition = precipitation > 2 ? 'Drizzle' : 'Partly Cloudy';
    } else {
      condition = 'Clear';
    }

    return {
      'condition': condition,
      'confidence': 0.7,
      'isGoodForTravel': ['Clear', 'Partly Cloudy'].contains(condition),
      'recommendation': _getRecommendation(condition),
      'color': weatherColors[condition] ?? Colors.grey,
      'icon': weatherIcons[condition] ?? Icons.help,
      'temperature': features['temperature_2m_mean_C'] ?? 28.0,
      'precipitation': precipitation,
      'windSpeed': features['wind_speed_10m_max_km_h'] ?? 10.0,
    };
  }

  // Predict for multiple days
  Future<List<Map<String, dynamic>>> predictTripWeather({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required int days,
  }) async {
    List<Map<String, dynamic>> predictions = [];
    for (int i = 0; i < days; i++) {
      predictions.add(
        await predictWeather(
          latitude: latitude,
          longitude: longitude,
          date: startDate.add(Duration(days: i)),
        ),
      );
    }
    return predictions;
  }

  // Recommend destinations based on weather
  Future<List<Map<String, dynamic>>> recommendDestinations({
    required DateTime tripDate,
    String? preferredWeather,
  }) async {
    final destinations = [
      {
        'name': 'Sigiriya',
        'latitude': 7.9570,
        'longitude': 80.7603,
        'category': 'Historical',
        'description': 'Ancient rock fortress',
      },
      {
        'name': 'Kandy',
        'latitude': 7.2906,
        'longitude': 80.6337,
        'category': 'Cultural',
        'description': 'Temple of the Tooth',
      },
      {
        'name': 'Galle',
        'latitude': 6.0269,
        'longitude': 80.2171,
        'category': 'Historical',
        'description': 'Dutch Fort',
      },
      {
        'name': 'Nuwara Eliya',
        'latitude': 6.9497,
        'longitude': 80.7891,
        'category': 'Hills',
        'description': 'Tea plantations',
      },
      {
        'name': 'Mirissa',
        'latitude': 5.9464,
        'longitude': 80.4583,
        'category': 'Beach',
        'description': 'Whale watching',
      },
      {
        'name': 'Ella',
        'latitude': 6.8697,
        'longitude': 81.0464,
        'category': 'Hills',
        'description': 'Scenic views',
      },
    ];

    List<Map<String, dynamic>> recommendations = [];
    for (var dest in destinations) {
      final weather = await predictWeather(
        latitude: dest['latitude'] as double,
        longitude: dest['longitude'] as double,
        date: tripDate,
      );

      double matchScore = weather['isGoodForTravel'] ? 85.0 : 60.0;
      if (preferredWeather != null &&
          preferredWeather != 'Any' &&
          weather['condition'] == preferredWeather) {
        matchScore += 15;
      }

      recommendations.add({
        ...dest,
        'weatherPrediction': weather,
        'matchScore': matchScore,
        'isRecommended': weather['isGoodForTravel'],
      });
    }

    recommendations.sort(
      (a, b) =>
          (b['matchScore'] as double).compareTo(a['matchScore'] as double),
    );
    return recommendations;
  }

  Map<String, double> _getFallbackFeatures(DateTime date) {
    final month = date.month;
    if (month >= 12 || month <= 3) {
      return {
        'temperature_2m_max_C': 32.0,
        'temperature_2m_min_C': 24.0,
        'temperature_2m_mean_C': 28.0,
        'apparent_temperature_max_C': 34.0,
        'apparent_temperature_min_C': 25.0,
        'apparent_temperature_mean_C': 29.5,
        'daylight_duration_s': 43200,
        'sunshine_duration_s': 39600,
        'precipitation_sum_mm': 2.0,
        'rain_sum_mm': 1.5,
        'precipitation_hours_h': 0.5,
        'wind_speed_10m_max_km_h': 8.0,
        'wind_gusts_10m_max_km_h': 12.0,
        'wind_direction_10m_dominant': 180.0,
        'shortwave_radiation_sum_MJ_m2': 25.0,
        'et0_fao_evapotranspiration_mm': 6.0,
      };
    } else if (month >= 5 && month <= 9) {
      return {
        'temperature_2m_max_C': 30.0,
        'temperature_2m_min_C': 25.0,
        'temperature_2m_mean_C': 27.5,
        'apparent_temperature_max_C': 32.0,
        'apparent_temperature_min_C': 26.0,
        'apparent_temperature_mean_C': 29.0,
        'daylight_duration_s': 43200,
        'sunshine_duration_s': 21600,
        'precipitation_sum_mm': 15.0,
        'rain_sum_mm': 12.0,
        'precipitation_hours_h': 4.0,
        'wind_speed_10m_max_km_h': 15.0,
        'wind_gusts_10m_max_km_h': 25.0,
        'wind_direction_10m_dominant': 270.0,
        'shortwave_radiation_sum_MJ_m2': 15.0,
        'et0_fao_evapotranspiration_mm': 4.0,
      };
    } else {
      return {
        'temperature_2m_max_C': 31.0,
        'temperature_2m_min_C': 24.5,
        'temperature_2m_mean_C': 27.8,
        'apparent_temperature_max_C': 33.0,
        'apparent_temperature_min_C': 25.5,
        'apparent_temperature_mean_C': 29.2,
        'daylight_duration_s': 43200,
        'sunshine_duration_s': 28800,
        'precipitation_sum_mm': 8.0,
        'rain_sum_mm': 6.0,
        'precipitation_hours_h': 2.0,
        'wind_speed_10m_max_km_h': 10.0,
        'wind_gusts_10m_max_km_h': 18.0,
        'wind_direction_10m_dominant': 225.0,
        'shortwave_radiation_sum_MJ_m2': 20.0,
        'et0_fao_evapotranspiration_mm': 5.0,
      };
    }
  }

  Map<String, dynamic> _getFallbackPrediction() {
    return {
      'condition': 'Partly Cloudy',
      'confidence': 0.75,
      'isGoodForTravel': true,
      'recommendation': 'Good weather for travel',
      'color': weatherColors['Partly Cloudy']!,
      'icon': weatherIcons['Partly Cloudy']!,
      'temperature': 28.0,
      'precipitation': 2.0,
      'windSpeed': 10.0,
    };
  }

  String _getRecommendation(String condition) {
    switch (condition) {
      case 'Clear':
        return 'Perfect weather for outdoor activities!';
      case 'Partly Cloudy':
        return 'Good weather for sightseeing';
      case 'Rain':
        return 'Consider indoor activities, carry umbrella';
      case 'Drizzle':
        return 'Light rain, carry raincoat';
      case 'Thunderstorm':
        return 'Avoid outdoor activities, stay safe';
      case 'Snow':
        return 'Cold weather, pack warm clothes';
      default:
        return 'Weather conditions are moderate';
    }
  }

  int _getMaxIndex(List<double> list) {
    int maxIndex = 0;
    double maxValue = list[0];
    for (int i = 1; i < list.length; i++) {
      if (list[i] > maxValue) {
        maxValue = list[i];
        maxIndex = i;
      }
    }
    return maxIndex;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void dispose() {
    _session?.release();
    _isInitialized = false;
  }
}
