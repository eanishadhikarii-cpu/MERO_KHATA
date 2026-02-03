import 'package:flutter/material.dart';
import '../services/athena_voice_assistant.dart';
import '../services/permission_manager.dart';
import '../models/voice_ledger_entry.dart';
import '../services/entity_extractor.dart';

class VoiceLedgerScreen extends StatefulWidget {
  const VoiceLedgerScreen({super.key});

  @override
  State<VoiceLedgerScreen> createState() => _VoiceLedgerScreenState();
}

class _VoiceLedgerScreenState extends State<VoiceLedgerScreen> {
  final AthenaVoiceAssistant _athena = AthenaVoiceAssistant();
  final PermissionManager _permissionManager = PermissionManager();
  
  String _transcribedText = '';
  String _statusMessage = 'Tap to start Athena Assistant';
  String _responseMessage = '';
  VoiceEntity? _extractedEntity;
  bool _isProcessing = false;
  bool _awaitingFollowUp = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _athena.initialize();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await _permissionManager.canUseVoiceFeatures();
    setState(() {
      _hasPermission = hasPermission;
      if (!hasPermission) {
        _statusMessage = 'Microphone permission required';
      }
    });
  }

  Future<void> _startAthenaSession() async {
    if (!_hasPermission) {
      final granted = await _permissionManager.requestMicrophonePermission(context);
      if (!granted) return;
      setState(() { _hasPermission = true; });
    }

    _showVoiceInputDialog();
  }

  Future<void> _showVoiceInputDialog() async {
    final TextEditingController controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.assistant, color: Colors.blue),
            SizedBox(width: 8),
            Text(_awaitingFollowUp ? 'Athena Follow-up' : 'Athena Voice Assistant'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_awaitingFollowUp 
              ? 'Please provide the requested information:'
              : 'Speak naturally to Athena in Nepali or English:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: _awaitingFollowUp 
                  ? 'e.g., "Ram" or "1000"'
                  : 'e.g., "आज रामले पाँच सय तिरे" or "Ram paid 500 today"',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.mic, color: Colors.blue),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Process with Athena'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      _processWithAthena(result);
    }
  }

  Future<void> _processWithAthena(String text) async {
    setState(() {
      _transcribedText = text;
      _isProcessing = true;
      _statusMessage = 'Athena is processing...';
      _responseMessage = '';
    });

    final response = _awaitingFollowUp 
        ? await _athena.handleFollowUp(text)
        : await _athena.processVoice(text);
    
    setState(() {
      _isProcessing = false;
      _responseMessage = response.message;
      
      if (response.type == AthenaResponseType.question) {
        _awaitingFollowUp = true;
        _statusMessage = 'Athena needs more information';
      } else {
        _awaitingFollowUp = false;
        _statusMessage = response.success ? 'Athena completed the task' : 'Athena encountered an error';
        
        if (response.success && response.data is VoiceLedgerEntry) {
          _extractedEntity = VoiceEntity(
            customerName: (response.data as VoiceLedgerEntry).ledgerName,
            amount: (response.data as VoiceLedgerEntry).amount,
            actionType: (response.data as VoiceLedgerEntry).transactionType,
          );
        }
      }
    });

    // Athena speaks the response
    await _athena.speak(response.message);

    if (response.success && !_awaitingFollowUp) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Athena completed the task successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _cancelAthenaSession() {
    _athena.cancelSession();
    setState(() {
      _awaitingFollowUp = false;
      _transcribedText = '';
      _responseMessage = '';
      _extractedEntity = null;
      _statusMessage = 'Athena session cancelled';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Ledger'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Voice Assistant Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[400]!, Colors.blue[600]!],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.mic,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Athena Voice Assistant',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _statusMessage,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Transcribed Text
            if (_transcribedText.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'You said:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _transcribedText,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Extracted Entity Display
            if (_extractedEntity != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _extractedEntity!.actionType == 'credit' 
                              ? Icons.add_circle 
                              : Icons.remove_circle,
                          color: _extractedEntity!.actionType == 'credit' 
                              ? Colors.green 
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          (_extractedEntity!.actionType ?? 'TRANSACTION').toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _extractedEntity!.actionType == 'credit' 
                                ? Colors.green 
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_extractedEntity!.customerName != null)
                      Text(
                        'Customer: ${_extractedEntity!.customerName}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    if (_extractedEntity!.amount != null)
                      Text(
                        'Amount: Rs. ${_extractedEntity!.amount!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),

            // Response Message
            if (_responseMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _awaitingFollowUp ? Colors.orange[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _awaitingFollowUp ? Colors.orange[200]! : Colors.blue[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _awaitingFollowUp ? Icons.help_outline : Icons.check_circle,
                          color: _awaitingFollowUp ? Colors.orange : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _awaitingFollowUp ? 'System Question:' : 'Response:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _awaitingFollowUp ? Colors.orange[700] : Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _responseMessage,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            // Action Buttons
            if (_awaitingFollowUp)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _cancelAthenaSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel Athena'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _startAthenaSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Continue with Athena'),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _startAthenaSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasPermission ? Colors.blue[600] : Colors.orange[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _hasPermission 
                                  ? Icons.assistant
                                  : Icons.mic_off,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _hasPermission
                                  ? 'Start Athena Assistant'
                                  : 'Enable Microphone',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                ),
              ),

            const SizedBox(height: 16),

            // Permission Status & Example Commands
            if (!_hasPermission)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Microphone permission is required for voice commands',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap "Enable Microphone" to allow voice ledger features',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[600],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Athena Assistant Examples:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• "आज रामले पाँच सय तिरे"\n• "Ram paid five hundred today"\n• "रामको बाँकी रकम कति छ?"\n• "आजको बिक्री कति भयो?"\n• "Add thousand rupees to Shyam account"\n• "Athena, show me low stock items"',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
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
}