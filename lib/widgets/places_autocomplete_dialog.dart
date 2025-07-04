// lib/widgets/places_autocomplete_dialog.dart
import 'package:flutter/material.dart';
import 'package:homeypark_mobile_application/services/places_service.dart';

class PlacesAutocompleteDialog extends StatefulWidget {
  final Function(PlaceDetails) onPlaceSelected;

  const PlacesAutocompleteDialog({super.key, required this.onPlaceSelected});

  @override
  State<PlacesAutocompleteDialog> createState() => _PlacesAutocompleteDialogState();
}

class _PlacesAutocompleteDialogState extends State<PlacesAutocompleteDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<PlaceAutocomplete> _suggestions = [];
  bool _isLoading = false;

  Future<void> _getSuggestions(String query) async {
    if (query.length < 3) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final suggestions = await PlacesService.getAutocompleteSuggestions(query);
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _suggestions = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar dirección',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _getSuggestions(value);
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    return ListTile(
                      title: Text(suggestion.description),
                      onTap: () async {
                        final details = await PlacesService.getPlaceDetails(suggestion.placeId);
                        if (details != null) {
                          Navigator.pop(context);
                          widget.onPlaceSelected(details);
                        }
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}