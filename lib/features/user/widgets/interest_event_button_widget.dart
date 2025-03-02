// lib/features/user/widgets/interest_event_button_widget.dart

import 'package:flutter/material.dart';
import 'package:sway/features/user/services/user_interest_event_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/user/widgets/snackbar_login.dart';

class InterestEventButtonWidget extends StatefulWidget {
  final int eventId;

  const InterestEventButtonWidget({
    required this.eventId,
    Key? key,
  }) : super(key: key);

  @override
  _InterestEventButtonWidgetState createState() =>
      _InterestEventButtonWidgetState();
}

class _InterestEventButtonWidgetState extends State<InterestEventButtonWidget> {
  // Possible values: 'not_interested', 'interested', 'going'
  String _interestStatus = 'not_interested';
  bool _isLoading = true;
  bool _isAnonymous = false;

  final UserInterestEventService _interestService = UserInterestEventService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadInterestStatus();
  }

  Future<void> _loadInterestStatus() async {
    try {
      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) {
        setState(() {
          _isAnonymous = true;
          _isLoading = false;
        });
        return;
      }
      // Determine the current state by checking "going" then "interested"
      bool isGoing = await _interestService.isGoingToEvent(widget.eventId);
      bool isInterested =
          await _interestService.isInterestedInEvent(widget.eventId);
      String status;
      if (isGoing) {
        status = 'going';
      } else if (isInterested) {
        status = 'interested';
      } else {
        status = 'not_interested';
      }
      setState(() {
        _interestStatus = status;
        _isAnonymous = false;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading interest status: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateInterestStatus(String newStatus) async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (newStatus == 'interested') {
        await _interestService.addInterest(widget.eventId);
      } else if (newStatus == 'going') {
        await _interestService.markEventAsGoing(widget.eventId);
      } else if (newStatus == 'not_interested') {
        await _interestService.removeInterest(widget.eventId);
      }
      await _loadInterestStatus();
    } catch (e) {
      print('Error updating interest status: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: const Text('Error updating interest status.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isAnonymous) {
      return IconButton(
        icon: Icon(
          Icons.favorite_border,
          color: Colors.grey,
        ),
        onPressed: () => SnackbarLogin.showLoginSnackBar(context),
      );
    }
    IconData iconData;
    Color iconColor;
    switch (_interestStatus) {
      case 'going':
        iconData = Icons.event_available;
        iconColor = Theme.of(context).primaryColor;
        break;
      case 'interested':
        iconData = Icons.favorite;
        iconColor = Theme.of(context).primaryColor;
        break;
      default:
        iconData = Icons.favorite_border;
        iconColor = Theme.of(context).iconTheme.color ?? Colors.grey;
    }
    return PopupMenuButton<String>(
      icon: Icon(
        iconData,
        color: iconColor,
      ),
      onSelected: (String value) {
        _updateInterestStatus(value);
      },
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'interested',
            child: Text('Interested'),
          ),
          const PopupMenuItem<String>(
            value: 'going',
            child: Text('Going'),
          ),
          const PopupMenuItem<String>(
            value: 'not_interested',
            child: Text('Not Interested'),
          ),
        ];
      },
    );
  }
}
