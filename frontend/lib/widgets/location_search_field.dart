import 'dart:async';
import 'package:flutter/material.dart';
import '../services/geocoding_service.dart';

const Color _primary = Color(0xFFA3D9E2);

/// Champ de recherche de localisation avec suggestions en temps réel (comme Google Maps).
/// Utilise un Overlay pour afficher les suggestions au-dessus du contenu, toujours visibles.
class LocationSearchField extends StatefulWidget {
  const LocationSearchField({
    super.key,
    required this.controller,
    required this.onLocationSelected,
  });

  final TextEditingController controller;
  final void Function(GeocodingResult result) onLocationSelected;

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  final GeocodingService _geocoding = GeocodingService();
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  List<GeocodingResult> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;
  OverlayEntry? _overlayEntry;
  String _lastQuery = '';

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onTextChanged(String text) {
    _debounce?.cancel();
    if (text.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      _removeOverlay();
      return;
    }
    _debounce =
        Timer(const Duration(milliseconds: 350), () => _search(text.trim()));
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) return;
    _lastQuery = query;
    setState(() => _isLoading = true);
    _removeOverlay();
    final results = await _geocoding.searchSuggestions(query);
    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _isLoading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _lastQuery.isNotEmpty) _showOverlay();
    });
  }

  void _showOverlay() {
    _removeOverlay();
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final size = renderBox.size;
    final theme = Theme.of(context);

    _overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: theme.scaffoldBackgroundColor,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 260),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                          child: SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))),
                    )
                  : _suggestions.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Aucun résultat pour « $_lastQuery »',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Colors.grey.shade200),
                          itemBuilder: (context, i) {
                            final s = _suggestions[i];
                            return ListTile(
                              leading: const Icon(Icons.location_on,
                                  color: _primary, size: 22),
                              title: Text(
                                s.displayName,
                                style: const TextStyle(fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _selectSuggestion(s),
                            );
                          },
                        ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _selectSuggestion(GeocodingResult s) {
    widget.controller.text = s.displayName;
    widget.onLocationSelected(s);
    setState(() => _suggestions = []);
    _focusNode.unfocus();
    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller,
            builder: (context, value, _) {
              return TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                onChanged: _onTextChanged,
                onTapOutside: (_) {
                  Future.delayed(
                      const Duration(milliseconds: 150), _removeOverlay);
                },
                decoration: InputDecoration(
                  hintText:
                      'Rechercher une adresse (ex: Sousse, Paris, Ariana...)',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  prefixIcon:
                      const Icon(Icons.location_on, color: _primary, size: 24),
                  suffixIcon: value.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              size: 20, color: Colors.grey.shade600),
                          onPressed: () {
                            widget.controller.clear();
                            setState(() => _suggestions = []);
                            _removeOverlay();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: InputBorder.none,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: _primary.withOpacity(0.5), width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              );
            },
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))),
            ),
        ],
      ),
    );
  }
}
