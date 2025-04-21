import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/gemini_service.dart';

enum TemperatureUnit { celsius, fahrenheit }

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  final GeminiService _geminiService = GeminiService();
  Weather? _weather;
  String? _errorMessage;
  bool _isLoading = false;
  String? _aiWeatherReport;
  bool _isGeneratingReport = false;
  final TextEditingController _cityController = TextEditingController();
  TemperatureUnit _temperatureUnit = TemperatureUnit.celsius;

  @override
  void initState() {
    super.initState();
    _fetchWeatherByLocation();
  }

  Future<void> _fetchWeatherByLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _aiWeatherReport = null;
    });

    try {
      final weather = await _weatherService.getWeatherByLocation();
      setState(() {
        _weather = weather;
        _isLoading = false;
      });
      _generateAIReport();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchWeatherByCity() async {
    if (_cityController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _aiWeatherReport = null;
    });

    try {
      final weather = await _weatherService.getWeatherByCity(_cityController.text);
      setState(() {
        _weather = weather;
        _isLoading = false;
      });
      _generateAIReport();
    } catch (e) {
      setState(() {
        _errorMessage = 'City not found. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _generateAIReport() async {
    if (_weather == null) return;
    
    setState(() {
      _isGeneratingReport = true;
    });
    
    try {
      final report = await _geminiService.generateWeatherReport(_weather!);
      setState(() {
        _aiWeatherReport = report;
        _isGeneratingReport = false;
      });
    } catch (e) {
      setState(() {
        _aiWeatherReport = 'Failed to generate AI report: ${e.toString()}';
        _isGeneratingReport = false;
      });
    }
  }

  // Conversion functions
  double celsiusToFahrenheit(double celsius) {
    return (celsius * 9 / 5) + 32;
  }

  String getTemperatureDisplay(double tempCelsius) {
    if (_temperatureUnit == TemperatureUnit.celsius) {
      return '${tempCelsius.toStringAsFixed(1)}°C';
    } else {
      return '${celsiusToFahrenheit(tempCelsius).toStringAsFixed(1)}°F';
    }
  }

  void _toggleTemperatureUnit() {
    setState(() {
      _temperatureUnit = _temperatureUnit == TemperatureUnit.celsius
          ? TemperatureUnit.fahrenheit
          : TemperatureUnit.celsius;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final detailBackgroundColor = isDarkMode 
        ? const Color(0xFF212121) 
        : const Color(0xFFE0E0E0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        // AppBar styling is handled by the theme
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      hintText: 'Enter city name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: isDarkMode 
                          ? const Color(0xFF212121) 
                          : const Color(0xFFF5F5F5),
                    ),
                    onSubmitted: (_) => _fetchWeatherByCity(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _fetchWeatherByCity,
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _fetchWeatherByLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Use my location'),
            ),
            const SizedBox(height: 20),
            
            // Loading indicator
            if (_isLoading)
              CircularProgressIndicator(
                color: primaryColor,
              )
            
            // Error message
            else if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              )
            
            // Weather display
            else if (_weather != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _weather!.cityName,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // Temperature unit toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'C°',
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: _temperatureUnit == TemperatureUnit.celsius 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                            ),
                          ),
                          Switch(
                            value: _temperatureUnit == TemperatureUnit.fahrenheit,
                            onChanged: (value) => _toggleTemperatureUnit(),
                            activeColor: primaryColor,
                            inactiveTrackColor: isDarkMode 
                                ? Colors.grey.shade800 
                                : Colors.grey.shade300,
                          ),
                          Text(
                            'F°',
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: _temperatureUnit == TemperatureUnit.fahrenheit 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      
                      Image.network(
                        'https://openweathermap.org/img/wn/${_weather!.icon}@4x.png',
                        height: 100,
                        width: 100,
                      ),
                      Text(
                        getTemperatureDisplay(_weather!.temperature),
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w200,
                        ),
                      ),
                      Text(
                        _weather!.description,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 30),
                      
                      // Additional weather details
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: detailBackgroundColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            _buildWeatherDetail(
                              'Feels like', 
                              getTemperatureDisplay(_weather!.feelsLike),
                              Icons.thermostat,
                            ),
                            const SizedBox(height: 10),
                            _buildWeatherDetail(
                              'Humidity', 
                              '${_weather!.humidity.toStringAsFixed(0)}%',
                              Icons.water_drop,
                            ),
                            const SizedBox(height: 10),
                            _buildWeatherDetail(
                              'Wind speed', 
                              '${_weather!.windSpeed.toStringAsFixed(1)} m/s',
                              Icons.air,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // AI Weather Report Section
                      if (_isGeneratingReport)
                        Column(
                          children: [
                            const Text(
                              'Generating AI Weather Report...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            CircularProgressIndicator(
                              color: primaryColor,
                            ),
                          ],
                        )
                      else if (_aiWeatherReport != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          margin: const EdgeInsets.only(top: 20.0),
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'AI Weather Report',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _aiWeatherReport!,
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.4,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: _generateAIReport,
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Refresh'),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else
              const Text('No weather data available'),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Row(
      children: [
        Icon(icon, color: primaryColor),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}