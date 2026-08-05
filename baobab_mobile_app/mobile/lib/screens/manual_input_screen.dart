import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart' show ApiService, AuthException;
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';
import 'results_screen.dart';

class ManualInputScreen extends StatefulWidget {
  const ManualInputScreen({super.key});
  @override
  State<ManualInputScreen> createState() => _ManualInputScreenState();
}

class _ManualInputScreenState extends State<ManualInputScreen> {
  final _form = GlobalKey<FormState>();
  final _height = TextEditingController();
  final _crown = TextEditingController();
  final _trunk = TextEditingController();
  final _altitude = TextEditingController();

  Categories? _cats;
  String? _zone, _habitat, _topo, _soil, _farm;
  bool _loading = true, _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final c = await ApiService.instance.fetchCategories();
      setState(() {
        _cats = c;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load options: $e';
        _loading = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is BaobabInput) {
      if (args.heightM != null) _height.text = args.heightM!.toString();
      if (args.crownDiameterM != null) _crown.text = args.crownDiameterM!.toString();
      if (args.trunkDiameterM != null) _trunk.text = args.trunkDiameterM!.toString();
      if (args.altitudeM != null) _altitude.text = args.altitudeM!.toString();
    }
  }

  void _quickStart(bool healthy) {
    setState(() {
      _height.text = healthy ? '22' : '15';
      _crown.text = healthy ? '25' : '18';
      _trunk.text = healthy ? '3.5' : '2.0';
      _altitude.text = healthy ? '400' : '250';
      if (_cats != null) {
        _zone = _cats!.geographicZones.first;
        _habitat = _cats!.treeGrowthHabitats.first;
        _topo = _cats!.topographies.first;
        _soil = _cats!.soilTextures.first;
        _farm = _cats!.farmCultivatedOptions.first;
      }
    });
  }

  void _clearForm() {
    setState(() {
      _height.clear();
      _crown.clear();
      _trunk.clear();
      _altitude.clear();
      _zone = _habitat = _topo = _soil = _farm = null;
    });
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final input = BaobabInput(source: 'manual')
      ..heightM = double.parse(_height.text)
      ..crownDiameterM = double.parse(_crown.text)
      ..trunkDiameterM = double.parse(_trunk.text)
      ..altitudeM = double.parse(_altitude.text)
      ..geographicZone = _zone
      ..treeGrowthHabitat = _habitat
      ..topography = _topo
      ..soilTexture = _soil
      ..farmCultivated = _farm;

    setState(() => _submitting = true);
    try {
      final result = await ApiService.instance.predict(input);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(input: input, result: result),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e Please log in again.')));
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(appBar: AppBar(), body: Center(child: Text(_error!)));

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Baobab Tree Predictor', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
            const SizedBox(height: 6),
            const Text('ML-powered assessment for agronomic and commercial value', style: TextStyle(color: AppTheme.textLight, fontSize: 15)),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: Column(
                children: [
                  Container(
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4C84FF),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tree Assessment Form', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                          const Divider(height: 32, thickness: 1, color: Color(0xFFE9ECEF)),
                          
                          // Quick Start
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: const Border(left: BorderSide(color: Color(0xFF4C84FF), width: 4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Quick Start', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _quickStart(true),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF4C84FF),
                                          side: const BorderSide(color: Color(0xFF4C84FF)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: const Text('Healthy Tree'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _quickStart(false),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF4C84FF),
                                          side: const BorderSide(color: Color(0xFF4C84FF)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: const Text('Average Tree'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Morphological
                          const _SectionLabel('Morphological Measurements', Icons.straighten, Color(0xFF4C84FF)),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: NumberField(label: 'Height (m)', example: '15.5 m', controller: _height)),
                              const SizedBox(width: 16),
                              Expanded(child: NumberField(label: 'Crown Diameter (m)', example: '20.0 m', controller: _crown)),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: NumberField(label: 'Trunk Diameter (m)', example: '2.5 m', controller: _trunk)),
                              const SizedBox(width: 16),
                              Expanded(child: NumberField(label: 'Altitude (m)', example: '400 m', controller: _altitude)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Environmental
                          const _SectionLabel('Environmental Conditions', Icons.park, Color(0xFF4C84FF)),
                          LabeledDropdown(label: 'Geographic Zone', value: _zone, options: _cats!.geographicZones, onChanged: (v) => setState(() => _zone = v)),
                          LabeledDropdown(label: 'Growth Habitat', value: _habitat, options: _cats!.treeGrowthHabitats, onChanged: (v) => setState(() => _habitat = v)),
                          LabeledDropdown(label: 'Topography', value: _topo, options: _cats!.topographies, onChanged: (v) => setState(() => _topo = v)),
                          LabeledDropdown(label: 'Soil Texture', value: _soil, options: _cats!.soilTextures, onChanged: (v) => setState(() => _soil = v)),
                          LabeledDropdown(label: 'Farm Type', value: _farm, options: _cats!.farmCultivatedOptions, onChanged: (v) => setState(() => _farm = v)),
                          
                          const Divider(height: 40, thickness: 1, color: Color(0xFFE9ECEF)),
                          
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: GradientButton(
                                  text: 'Get Prediction',
                                  icon: Icons.psychology,
                                  onPressed: _submit,
                                  loading: _submitting,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: SizedBox(
                                  height: 52,
                                  child: OutlinedButton.icon(
                                    onPressed: _clearForm,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Clear'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.textDark,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color iconColor;
  const _SectionLabel(this.text, this.icon, this.iconColor);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
        ],
      ),
    );
  }
}
