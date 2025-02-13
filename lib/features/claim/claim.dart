// lib/features/claim/claim.dart

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:sway/features/claim/services/claim_service.dart';

/// A screen that displays a claim form for any type of entity.
/// Accepts an entityId and an entityType as arguments.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Claim Form for ${widget.entityType}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            children: <Widget>[
              // Text field for additional claim information or proof data.
              FormBuilderTextField(
                name: 'proof_data',
                decoration: InputDecoration(
                  labelText: 'Evidence / Proof',
                ),
                maxLines: 5,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.maxLength(500),
                ]),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    // Get the form values
                    final formData = _formKey.currentState!.value;

                    // Call the ClaimService to submit the claim
                    final success = await ClaimService.submitClaim(
                      entityId: widget.entityId,
                      entityType: widget.entityType,
                      proofData: formData['proof_data'],
                    );

                    if (success) {
                      // Show notification for successful claim submission
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Your claim has been submitted and will be processed shortly.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.pop(context);
                    } else {
                      // Show error notification
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('There was an error submitting your claim.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                child: Text('Submit Claim'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
