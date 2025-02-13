// lib/features/claim/claim.dart

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:sway/features/claim/screens/claim_history.dart';
import 'package:sway/features/claim/services/claim_service.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/venue/services/venue_service.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/user/services/user_service.dart';

/// A screen that displays a claim form for any type of entity.
/// It shows read-only fields for entity type, entity name, and the current user's username.
/// It also provides a text field for the user to enter additional evidence or proof.
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

  // Controllers for read-only fields.
  final TextEditingController _entityNameController =
      TextEditingController(text: "Loading...");
  final TextEditingController _userNameController =
      TextEditingController(text: "Loading...");

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchEntityName();
    _fetchUserName();
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

  /// Handles form submission.
  Future<void> _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isSubmitting = true;
      });
      final formData = _formKey.currentState!.value;
      final success = await ClaimService.submitClaim(
        entityId: widget.entityId,
        entityType: widget.entityType,
        proofData: formData['proof_data'],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              const SizedBox(height: 10),
              // Read-only field for entity name using controller
              FormBuilderTextField(
                name: 'entity_name',
                controller: _entityNameController,
                decoration: const InputDecoration(
                  labelText: 'Entity Name',
                ),
                enabled: false,
              ),
              const SizedBox(height: 10),
              // Read-only field for current user's username using controller
              FormBuilderTextField(
                name: 'user_name',
                controller: _userNameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                ),
                enabled: false,
              ),
              const SizedBox(height: 10), // Reduced spacing from 20 to 10
              // Text field for additional evidence or proof data.
              FormBuilderTextField(
                name: 'proof_data',
                decoration: const InputDecoration(
                  labelText: 'Evidence / Proof',
                  hintText:
                      'e.g., link to official website or social media profile',
                ),
                maxLines: 5,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.maxLength(500),
                ]),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  elevation: isDark ? 2 : 0,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  side: BorderSide(
                    color: isDark ? Colors.white : Colors.black,
                    width: 1,
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit Claim'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
