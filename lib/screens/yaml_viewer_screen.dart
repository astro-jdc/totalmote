import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/tv_service_factory.dart';
import '../utils/app_logger.dart';

class YamlViewerScreen extends StatefulWidget {
  const YamlViewerScreen({Key? key}) : super(key: key);

  @override
  State<YamlViewerScreen> createState() => _YamlViewerScreenState();
}

class _YamlViewerScreenState extends State<YamlViewerScreen> {
  String? _selectedBrand;
  List<String> _availableBrands = [];
  String _yamlContent = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    try {
      final brands = await TVServiceFactory.getSupportedBrands();
      setState(() {
        _availableBrands = brands;
        _isLoading = false;
        if (brands.isNotEmpty) {
          _selectedBrand = brands.first;
          _loadYamlFile(brands.first);
        }
      });
    } catch (e) {
      logger.e('Failed to load brands', error: e);
      setState(() {
        _isLoading = false;
        _yamlContent = 'Error loading brands: $e';
      });
    }
  }

  Future<void> _loadYamlFile(String brand) async {
    setState(() {
      _yamlContent = 'Loading...';
    });

    try {
      final content = await rootBundle.loadString('assets/${brand.toLowerCase().replaceAll(' ', '_')}.yaml');
      setState(() {
        _yamlContent = content;
      });
    } catch (e) {
      logger.e('Failed to load YAML for $brand', error: e);
      setState(() {
        _yamlContent = 'Error loading file: $e';
      });
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _yamlContent));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('YAML content copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YAML Configuration Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _yamlContent.isNotEmpty && !_yamlContent.startsWith('Loading') && !_yamlContent.startsWith('Error')
                ? _copyToClipboard
                : null,
            tooltip: 'Copy to Clipboard',
          ),
        ],
      ),
      body: Column(
        children: [
          // Brand Selector
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            color: const Color(0xFF16213e),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.tv, color: Colors.blue),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButton<String>(
                      value: _selectedBrand,
                      isExpanded: true,
                      underline: Container(),
                      items: _availableBrands.map((brand) {
                        return DropdownMenuItem(
                          value: brand,
                          child: Text(
                            brand.toUpperCase(),
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedBrand = value;
                          });
                          _loadYamlFile(value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // YAML Content
          Expanded(
            child: Card(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              elevation: 4,
              color: const Color(0xFF0f1419),
              child: _yamlContent.isEmpty
                  ? const Center(child: Text('No content'))
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  _yamlContent,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // Info Footer
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black12,
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Configuration file: assets/${_selectedBrand?.toLowerCase().replaceAll(' ', '_') ?? ''}.yaml',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
