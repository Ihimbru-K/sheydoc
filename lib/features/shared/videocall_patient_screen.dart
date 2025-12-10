import 'package:agora_uikit/agora_uikit.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VideoCallScreen extends StatefulWidget {
  final String appointmentId;
  final String userName; // Doctor or Patient name
  final bool isDoctor;

  const VideoCallScreen({
    super.key,
    required this.appointmentId,
    required this.userName,
    required this.isDoctor,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late AgoraClient client;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeAgora();
  }

  void _initializeAgora() async {
    try {
      // Generate channel name from appointmentId - THIS IS KEY!
      // Both doctor and patient use the same channel name
      final channelName = 'appointment_${widget.appointmentId}';

      print('🎥 Initializing Agora...');
      print('📺 Channel: $channelName');
      print('👤 User: ${widget.userName}');

      client = AgoraClient(
        agoraConnectionData: AgoraConnectionData(
          appId: "c032b56943db459688e5aadd06cad578", // Your Agora App ID
          channelName: channelName,
          username: widget.userName,
        ),
      );

      await client.initialize();

      setState(() {
        _isInitialized = true;
      });

      // Update appointment status to "in_call"
      await _updateCallStatus('in_call');

      print('✅ Agora initialized successfully');
    } catch (e) {
      print('❌ Error initializing Agora: $e');
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _updateCallStatus(String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({
        'callStatus': status,
        'lastCallUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating call status: $e');
    }
  }

  Future<void> _endCall() async {
    try {
      // Update appointment status
      await _updateCallStatus('ended');

      // Mark appointment as completed if doctor ends it
      if (widget.isDoctor) {
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(widget.appointmentId)
            .update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        });
      }

      // Pop back
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error ending call: $e');
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Call Error'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize video call',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'Connecting to ${widget.isDoctor ? 'patient' : 'doctor'}...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        // Show confirmation dialog before leaving
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('End Call?'),
            content: const Text('Are you sure you want to end this call?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('End Call'),
              ),
            ],
          ),
        );

        if (shouldLeave == true) {
          await _endCall();
          return true;
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isDoctor ? 'Patient Call' : 'Doctor Consultation',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.black87,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            // End call button
            IconButton(
              icon: const Icon(Icons.call_end, color: Colors.red),
              onPressed: () async {
                final shouldEnd = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('End Call?'),
                    content: const Text('Are you sure you want to end this call?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('End Call'),
                      ),
                    ],
                  ),
                );

                if (shouldEnd == true) {
                  await _endCall();
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // Video viewer
              AgoraVideoViewer(
                client: client,
                layoutType: Layout.floating,
                enableHostControls: widget.isDoctor, // Only doctor can control
              ),

              // Video controls
              Align(
                alignment: Alignment.bottomCenter,
                child: AgoraVideoButtons(
                  client: client,
                  addScreenSharing: false,
                ),
              ),

              // Call info overlay (top)
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Call in progress',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      StreamBuilder(
                        stream: Stream.periodic(const Duration(seconds: 1)),
                        builder: (context, snapshot) {
                          final duration = DateTime.now().difference(
                            DateTime.now(), // You can track actual start time
                          );
                          return Text(
                            _formatDuration(duration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}