import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sheydoc_app/core/constants/app_colors.dart';
import 'dart:async';

class AudioCallScreen extends StatefulWidget {
  final String appointmentId;
  final String channelName;
  final String otherUserName;
  final String otherUserId;
  final bool isDoctor;

  const AudioCallScreen({
    super.key,
    required this.appointmentId,
    required this.channelName,
    required this.otherUserName,
    required this.otherUserId,
    required this.isDoctor,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  int _callDuration = 0;
  Timer? _timer;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeAudioCall();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _endCall();
    super.dispose();
  }

  Future<void> _initializeAudioCall() async {
    // TODO: Initialize Agora Audio SDK here
    // For now, simulate connection
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isConnected = true;
      });
      _startTimer();
    }

    print('');
    print('🎙️ AUDIO CALL INITIALIZED');
    print('📌 Appointment ID: ${widget.appointmentId}');
    print('📺 Channel Name: ${widget.channelName}');
    print('👤 Other User: ${widget.otherUserName}');
    print('🏥 Is Doctor: ${widget.isDoctor}');
    print('');
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration++;
        });
      }
    });
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    // TODO: Toggle mute in Agora SDK
    print('🎙️ Mute toggled: $_isMuted');
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    // TODO: Toggle speaker in Agora SDK
    print('🔊 Speaker toggled: $_isSpeakerOn');
  }

  Future<void> _endCall() async {
    _timer?.cancel();
    // TODO: Leave Agora channel and cleanup
    print('📞 Call ended after $_callDuration seconds');

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Column(
          children: [
            // Top section
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isDoctor ? 'Patient Call' : 'Doctor Call',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white70,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.minimize,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                    onPressed: () {
                      // TODO: Implement minimize to PIP mode
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Picture-in-Picture coming soon!'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Center - User avatar and call status
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Large avatar
                Container(
                  width: 140.w,
                  height: 140.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person,
                      size: 70.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // User name
                Text(
                  widget.otherUserName,
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),

                // Call status
                Text(
                  _isConnected
                      ? _formatDuration(_callDuration)
                      : 'Connecting...',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.white70,
                  ),
                ),

                if (!_isConnected)
                  Padding(
                    padding: EdgeInsets.only(top: 16.h),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                    ),
                  ),
              ],
            ),

            const Spacer(),

            // Bottom - Control buttons
            Container(
              padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 24.w),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        label: _isMuted ? 'Unmute' : 'Mute',
                        onTap: _toggleMute,
                        isActive: _isMuted,
                      ),
                      _buildControlButton(
                        icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                        label: 'Speaker',
                        onTap: _toggleSpeaker,
                        isActive: _isSpeakerOn,
                      ),
                      _buildControlButton(
                        icon: Icons.add,
                        label: 'Add User',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Add user feature coming soon!'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),

                  // End call button
                  GestureDetector(
                    onTap: _endCall,
                    child: Container(
                      width: 70.w,
                      height: 70.h,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.call_end,
                        color: Colors.white,
                        size: 32.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56.w,
            height: 56.h,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? AppColors.primaryBlue : Colors.white,
              size: 24.sp,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}