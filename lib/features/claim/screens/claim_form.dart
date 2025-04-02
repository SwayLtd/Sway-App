// lib/features/claim/claim.dart

import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:sway/core/constants/dimensions.dart';
import 'package:sway/core/utils/validators.dart';
import 'package:sway/features/claim/screens/claim_history.dart';
import 'package:sway/features/claim/services/claim_service.dart';
import 'package:sway/features/security/services/storage_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/venue/services/venue_service.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';

/// A screen that displays a claim form for any type of entity.
/// It shows read-only fields for entity type, entity name, and the current user's username.
/// It also provides a text field for the user to enter additional evidence or proof,
/// and allows uploading up to one file as supporting evidence.
class ClaimFormScreen extends StatefulWidget {
  final int entityId;
  final String entityType;

  const ClaimFormScreen({
    Key? key,
    required this.entityId,
    required this.entityType,
  }) : super(key: key);

  @override
  _ClaimFormScreenState createState() => _ClaimFormScreenState();
}

class _ClaimFormScreenState extends State<ClaimFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  final TextEditingController _entityNameController =
      TextEditingController(text: "Loading...");
  final TextEditingController _userNameController =
      TextEditingController(text: "Loading...");

  Uint8List? _selectedFileData;
  String? _selectedFileName;
  bool _isSubmitting = false;

  // Instance of the global validator used for text fields.
  // It will be updated with the combined forbiddenWords (French + English).
  late FieldValidator defaultValidator;

  @override
  void initState() {
    super.initState();
    _fetchEntityName();
    _fetchUserName();

    // Initialize defaultValidator with base parameters and an empty forbiddenWords.
    defaultValidator = FieldValidator(
      isRequired: true,
      maxLength: 500,
      forbiddenWords: [],
    );

    // Load forbidden words for French and English, then update the validator.
    _loadDefaultForbiddenWords();
  }

  Future<void> _loadDefaultForbiddenWords() async {
    try {
      final frWords = await loadForbiddenWords('fr');
      final enWords = await loadForbiddenWords('en');
      // Combine the two lists and remove duplicates.
      final combined = {...frWords, ...enWords}.toList();
      setState(() {
        defaultValidator = FieldValidator(
          isRequired: true,
          maxLength: 2000,
          forbiddenWords: combined,
        );
      });
      // Optionnel : Revalider le formulaire pour mettre à jour les erreurs si besoin.
      _formKey.currentState?.validate();
    } catch (e) {
      debugPrint('Error loading forbidden words: $e');
    }
  }

  @override
  void dispose() {
    _entityNameController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  /// Fetches the name of the entity based on its type.
  Future<void> _fetchEntityName() async {
    String name = '';
    switch (widget.entityType.toLowerCase()) {
      case 'artist':
        final artist = await ArtistService().getArtistById(widget.entityId);
        name = artist?.name ?? '';
        break;
      case 'venue':
        final venue = await VenueService().getVenueById(widget.entityId);
        name = venue?.name ?? '';
        break;
      case 'promoter':
        final promoter =
            await PromoterService().getPromoterById(widget.entityId);
        name = promoter?.name ?? '';
        break;
      default:
        name = '';
    }
    setState(() {
      _entityNameController.text = name;
    });
  }

  /// Fetches the current user's username.
  Future<void> _fetchUserName() async {
    final user = await UserService().getCurrentUser();
    setState(() {
      _userNameController.text = user?.username ?? 'Unknown';
    });
  }

  /// Allows the user to pick a file.
  Future<void> _pickFile() async {
    // Limiter à un seul fichier
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: true, // pour récupérer les données directement
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedFileData = result.files.single.bytes;
        _selectedFileName = result.files.single.name;
      });
    }
  }

  /// Handles form submission.
  Future<void> _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isSubmitting = true;
      });

      String? proofFileUrl;

      // If a file has been selected, upload it
      if (_selectedFileData != null && _selectedFileName != null) {
        proofFileUrl = await StorageService().uploadFile(
          bucketName: 'claim-proof',
          fileName: _selectedFileName!,
          fileData: _selectedFileData!,
        );
      }

      // Optionally, you could update ClaimService.submitClaim to accept proofFileUrl.
      // For now, we assume that proofFileUrl can be concatenated or saved within proof_data.
      final combinedProofData = _formKey.currentState!.value['proof_data'] +
          (proofFileUrl != null ? '\nFile URL: $proofFileUrl' : '');

      final success = await ClaimService.submitClaim(
        entityId: widget.entityId,
        entityType: widget.entityType,
        proofData: combinedProofData,
      );
      setState(() {
        _isSubmitting = false;
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Your claim has been submitted and will be processed shortly.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('There was an error submitting your claim.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Claim Form for ${widget.entityType.capitalize()}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              // Read-only field for entity type
              FormBuilderTextField(
                name: 'entity_type',
                initialValue: widget.entityType.capitalize(),
                decoration: const InputDecoration(
                  labelText: 'Entity Type',
                ),
                enabled: false,
              ),
              const SizedBox(height: sectionTitleSpacing),
              // Read-only field for entity name using controller
              FormBuilderTextField(
                name: 'entity_name',
                controller: _entityNameController,
                decoration: const InputDecoration(
                  labelText: 'Entity Name',
                ),
                enabled: false,
              ),
              const SizedBox(height: sectionTitleSpacing),
              // Read-only field for current user's username using controller
              FormBuilderTextField(
                name: 'user_name',
                controller: _userNameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                ),
                enabled: false,
              ),
              const SizedBox(height: sectionTitleSpacing),
              // Button to pick a file as proof (optional)
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file),
                label: Text(_selectedFileName ?? 'UPLOAD PROOF FILE'),
              ),
              const SizedBox(height: sectionTitleSpacing),
              // Text field for additional evidence or proof data.
              FormBuilderTextField(
                name: 'proof_data',
                decoration: const InputDecoration(
                  labelText: 'Evidence / Proof',
                  hintText:
                      'e.g., link to official website, social media profile, or attach a file as proof',
                ),
                maxLines: 5,
                validator: (value) => defaultValidator.validate(value),
              ),

              const SizedBox(height: sectionSpacing),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('SUBMIT CLAIM'),
              ),
              const SizedBox(height: sectionSpacing),
// TextButton to navigate to Claim History Screen
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClaimHistoryScreen(
                        entityId: widget.entityId,
                        entityType: widget.entityType,
                      ),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                ),
                child: const Text('View Claim History'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
