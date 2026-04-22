import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lavamax/core/constants/app_colors.dart';
import 'package:lavamax/data/models/vehicle_brand_model.dart';
/// Tela de seleção de marca com lista completa e índice alfabético lateral.
/// Retorna [VehicleBrandModel] selecionada via [Navigator.pop].
class BrandSelectionScreen extends StatefulWidget {
  final List<VehicleBrandModel> brands;
  const BrandSelectionScreen({super.key, required this.brands});
  @override
  State<BrandSelectionScreen> createState() => _BrandSelectionScreenState();
}
class _BrandSelectionScreenState extends State<BrandSelectionScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  // letra atualmente destacada no índice
  String? _activeLetter;
  // brands filtradas pela busca
  late List<VehicleBrandModel> _filtered;
  // mapa letra → GlobalKey do cabeçalho da seção
  final Map<String, GlobalKey> _sectionKeys = {};
  // letras presentes nas marcas filtradas (em ordem)
  List<String> _letters = [];
  @override
  void initState() {
    super.initState();
    _filtered = List.of(widget.brands);
    _rebuildIndex();
  }
  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  // ── helpers ────────────────────────────────────────────────
  void _rebuildIndex() {
    _sectionKeys.clear();
    final lettersSet = <String>{};
    for (final b in _filtered) {
      if (b.name.isEmpty) continue;
      final l = b.name[0].toUpperCase();
      lettersSet.add(l);
    }
    _letters = lettersSet.toList()..sort();
    for (final l in _letters) {
      _sectionKeys[l] = GlobalKey();
    }
  }
  void _onSearch(String query) {
    setState(() {
      final q = query.trim().toLowerCase();
      _filtered = q.isEmpty
          ? List.of(widget.brands)
          : widget.brands
              .where((b) => b.name.toLowerCase().contains(q))
              .toList();
      _rebuildIndex();
      _activeLetter = null;
    });
  }
  void _scrollToLetter(String letter) {
    final key = _sectionKeys[letter];
    if (key == null) return;
    final ctx = key.currentContext;
    if (ctx == null) return;
    HapticFeedback.selectionClick();
    setState(() => _activeLetter = letter);
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: 0.0,
    );
  }
  // ── build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // agrupa marcas por letra
    final Map<String, List<VehicleBrandModel>> grouped = {};
    for (final b in _filtered) {
      if (b.name.isEmpty) continue;
      final l = b.name[0].toUpperCase();
      grouped.putIfAbsent(l, () => []).add(b);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecione a Marca'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Buscar marca…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _filtered.isEmpty
          ? const Center(child: Text('Nenhuma marca encontrada.'))
          : Stack(
              children: [
                // ── Lista principal ──────────────────────────
                ListView.builder(
                  controller: _scrollController,
                  // margem direita para não sobrepor o índice
                  padding: const EdgeInsets.only(right: 32),
                  itemCount: _letters.length,
                  itemBuilder: (_, i) {
                    final letter = _letters[i];
                    final items = grouped[letter] ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // cabeçalho da seção
                        Container(
                          key: _sectionKeys[letter],
                          width: double.infinity,
                          color: AppColors.grey100,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: Text(
                            letter,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.grey700,
                            ),
                          ),
                        ),
                        // itens da seção
                        ...items.map(
                          (brand) => ListTile(
                            leading: const Icon(
                              Icons.directions_car_outlined,
                              color: AppColors.grey500,
                            ),
                            title: Text(brand.name),
                            onTap: () => Navigator.of(context).pop(brand),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                // ── Índice alfabético lateral ────────────────
                if (_searchController.text.isEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: _AlphabetIndex(
                      letters: _letters,
                      activeLetter: _activeLetter,
                      onLetterTap: _scrollToLetter,
                    ),
                  ),
              ],
            ),
    );
  }
}
// ── Widget do índice lateral ────────────────────────────────
class _AlphabetIndex extends StatelessWidget {
  final List<String> letters;
  final String? activeLetter;
  final ValueChanged<String> onLetterTap;
  const _AlphabetIndex({
    required this.letters,
    required this.activeLetter,
    required this.onLetterTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // arrasto contínuo sobre o índice
      onVerticalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final localY = box.globalToLocal(details.globalPosition).dy;
        final itemHeight = box.size.height / letters.length;
        final idx = (localY / itemHeight).floor().clamp(0, letters.length - 1);
        onLetterTap(letters[idx]);
      },
      child: Container(
        width: 28,
        decoration: BoxDecoration(
          color: AppColors.grey100.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            bottomLeft: Radius.circular(8),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: letters.map((l) {
            final isActive = l == activeLetter;
            return GestureDetector(
              onTap: () => onLetterTap(l),
              child: Container(
                width: 28,
                height: 22,
                alignment: Alignment.center,
                decoration: isActive
                    ? const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      )
                    : null,
                child: Text(
                  l,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppColors.white : AppColors.grey700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
