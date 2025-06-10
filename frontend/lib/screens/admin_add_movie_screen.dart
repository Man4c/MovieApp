import 'package:flutter/material.dart';
import 'package:flutter_video_app/models/video_model.dart';
import 'package:flutter_video_app/services/api_service.dart';

class AdminAddMovieScreen extends StatefulWidget {
  const AdminAddMovieScreen({super.key});

  @override
  State<AdminAddMovieScreen> createState() => _AdminAddMovieScreenState();
}

class _AdminAddMovieScreenState extends State<AdminAddMovieScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // TextEditingControllers
  final _tmdbIdController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _posterPathController = TextEditingController();
  final _backdropPathController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _ratingController = TextEditingController();
  final _releaseDateController = TextEditingController();

  // Genre and Type selections
  final List<String> _availableGenres = [
    'Action', 'Comedy', 'Drama', 'Sci-Fi', 'Horror', 'Romance', 'Thriller', 'Documentary', 'Animation', 'Fantasy'
  ];
  final Set<String> _selectedGenres = {};

  final List<String> _availableTypes = ['Movie', 'Series', 'TV Show', 'Short Film'];
  final Set<String> _selectedTypes = {};

  @override
  void dispose() {
    _tmdbIdController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _posterPathController.dispose();
    _backdropPathController.dispose();
    _videoUrlController.dispose();
    _ratingController.dispose();
    _releaseDateController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedGenres.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one genre.')),
        );
        return;
      }
      if (_selectedTypes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one type.')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final newMovie = VideoModel(
          tmdbId: _tmdbIdController.text,
          title: _titleController.text,
          description: _descriptionController.text,
          posterPath: _posterPathController.text,
          backdropPath: _backdropPathController.text.isNotEmpty ? _backdropPathController.text : _posterPathController.text,
          videoUrl: _videoUrlController.text,
          genre: _selectedGenres.toList(),
          type: _selectedTypes.toList(),
          rating: double.tryParse(_ratingController.text) ?? 0.0,
          releaseDate: _releaseDateController.text,
          // Tags are optional in VideoModel, so not collecting them for simplicity here
        );

        final createdMovie = await ApiService.addMovieByAdmin(newMovie);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Movie "${createdMovie.title}" added successfully!')),
        );
        _formKey.currentState!.reset();
        _selectedGenres.clear();
        _selectedTypes.clear();
        // Clear controllers
        _tmdbIdController.clear();
        _titleController.clear();
        _descriptionController.clear();
        _posterPathController.clear();
        _backdropPathController.clear();
        _videoUrlController.clear();
        _ratingController.clear();
        _releaseDateController.clear();


      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add movie: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumeric = false, bool isRequired = true}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return '$label is required';
        }
        if (isNumeric && value != null && value.isNotEmpty && double.tryParse(value) == null) {
          return 'Please enter a valid number for $label';
        }
        return null;
      },
    );
  }

  Widget _buildCheckboxGroup(String title, List<String> availableItems, Set<String> selectedItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: availableItems.map((item) {
            return FilterChip(
              label: Text(item),
              selected: selectedItems.contains(item),
              onSelected: (isSelected) {
                setState(() {
                  if (isSelected) {
                    selectedItems.add(item);
                  } else {
                    selectedItems.remove(item);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Movie'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildTextField(_tmdbIdController, 'TMDB ID'),
                _buildTextField(_titleController, 'Title'),
                _buildTextField(_descriptionController, 'Description'),
                _buildTextField(_posterPathController, 'Poster Path (URL)'),
                _buildTextField(_backdropPathController, 'Backdrop Path (URL)', isRequired: false),
                _buildTextField(_videoUrlController, 'Video URL'),
                _buildTextField(_ratingController, 'Rating (e.g., 7.5)', isNumeric: true),
                _buildTextField(_releaseDateController, 'Release Date (YYYY-MM-DD)'),

                const SizedBox(height: 16),
                _buildCheckboxGroup('Genres', _availableGenres, _selectedGenres),
                const SizedBox(height: 16),
                _buildCheckboxGroup('Types', _availableTypes, _selectedTypes),
                const SizedBox(height: 24),

                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Add Movie'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
