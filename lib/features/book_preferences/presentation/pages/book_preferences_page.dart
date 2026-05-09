import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_app/core/theme/app_theme.dart';

class BookPreferencesPage extends StatefulWidget {
  const BookPreferencesPage({super.key});

  @override
  State<BookPreferencesPage> createState() => _BookPreferencesPageState();
}

class _BookPreferencesPageState extends State<BookPreferencesPage> {
  final List<String> _allGenres = [
    'Fiction',
    'Technology',
    'Self-Help',
    'History',
    'Science',
    'Mystery',
    'Fantasy',
    'Business',
    'Psychology',
    'Biography',
    'Poetry',
    'Art',
  ];

  final List<String> _selectedGenres = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGenres = prefs.getStringList('favorite_genres') ?? [];
    setState(() {
      _selectedGenres.addAll(savedGenres);
      _isLoading = false;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_genres', _selectedGenres);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Preferences saved successfully!',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppTheme.kPrimaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.kBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.kPrimaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.kBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.kBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'BOOK PREFERENCES',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Favorite Genres',
              'Select genres you love to read',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: _allGenres.map((genre) {
                final isSelected = _selectedGenres.contains(genre);
                return FilterChip(
                  label: Text(genre),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedGenres.add(genre);
                      } else {
                        _selectedGenres.remove(genre);
                      }
                    });
                  },
                  backgroundColor: AppTheme.kSurfaceContainerLowColor,
                  selectedColor: AppTheme.kPrimaryColor,
                  checkmarkColor: Colors.black,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.kPrimaryColor
                          : Colors.white10,
                      width: 1,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            _buildSectionHeader(
              'Reading Goals',
              'Customize your reading experience',
            ),
            const SizedBox(height: 16),
            _buildSettingTile(
              Icons.auto_stories_outlined,
              'Daily Goal',
              '30 minutes per day',
              onTap: () {},
            ),
            _buildSettingTile(
              Icons.dark_mode_outlined,
              'Reader Theme',
              'Obsidian Dark',
              onTap: () {},
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kPrimaryColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'SAVE PREFERENCES',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 54),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white38,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    IconData icon,
    String title,
    String value, {
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.kSurfaceContainerLowColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppTheme.kPrimaryColor, size: 20),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white12,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}
