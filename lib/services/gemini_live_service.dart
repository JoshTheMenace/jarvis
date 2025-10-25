import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Service class to handle Gemini Live API WebSocket communication
/// Supports bidirectional audio and text streaming
class GeminiLiveService {
  WebSocketChannel? _channel;
  final String apiKey;
  bool _isConnected = false;

  // Streams for bidirectional communication
  final StreamController<Uint8List> _audioOutputController =
      StreamController<Uint8List>.broadcast();
  final StreamController<String> _textOutputController =
      StreamController<String>.broadcast();
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();
  final StreamController<Map<String, dynamic>> _toolCallController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _turnCompleteController =
      StreamController<bool>.broadcast();

  /// Stream of audio data received from Gemini (PCM 24kHz, 16-bit, mono)
  Stream<Uint8List> get audioOutputStream => _audioOutputController.stream;

  /// Stream of text responses received from Gemini
  Stream<String> get textOutputStream => _textOutputController.stream;

  /// Stream of connection state changes
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  /// Stream of tool calls from Gemini (for display_text function)
  Stream<Map<String, dynamic>> get toolCallStream => _toolCallController.stream;

  /// Stream of turn complete events
  Stream<bool> get turnCompleteStream => _turnCompleteController.stream;

  /// Whether the service is currently connected
  bool get isConnected => _isConnected;

  GeminiLiveService({required this.apiKey});

  /// Connect to the Gemini Live API
  Future<void> connect({
    String model = 'models/gemini-2.5-flash-native-audio-preview-09-2025',
    String voiceName = 'Algenib',
    List<String> responseModalities = const ['AUDIO'],
  }) async {
    try {
      // Construct WebSocket URL with API key
      final wsUrl = Uri.parse(
        'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=$apiKey',
      );

      print('Connecting to Gemini Live API...');
      _channel = WebSocketChannel.connect(wsUrl);

      // Send setup message to configure the session with function calling
      final setupMsg = {
        'setup': {
          'model': model,
          'systemInstruction': {
            'parts': [
              {
                'text': '''You are Jarvis, an advanced AI assistant inspired by Tony Stark's AI. You are helpful, intelligent, proactive, and have a sophisticated personality with a touch of wit.

You help users with:
- Managing notes and reminders
- Organizing calendar events
- Creating lists and tracking tasks
- Providing information and assistance
- Displaying relevant UI components when needed

When users ask to see notes, reminders, calendar events, or lists, use the appropriate tool calls to display them on screen. Be conversational but efficient, and always aim to be genuinely helpful.'''
              }
            ]
          },
          'generationConfig': {
            'responseModalities': responseModalities,
            'speechConfig': {
              'voiceConfig': {
                'prebuiltVoiceConfig': {'voiceName': voiceName}
              }
            }
          },
          'tools': [
            {
              'functionDeclarations': [
                {
                  'name': 'show_note',
                  'description': 'Display a note on the screen. Use this when the user wants to see a note or when you create a new note for them.',
                  'parameters': {
                    'type': 'object',
                    'properties': {
                      'title': {
                        'type': 'string',
                        'description': 'The title of the note'
                      },
                      'content': {
                        'type': 'string',
                        'description': 'The content/body of the note'
                      }
                    },
                    'required': ['title', 'content']
                  }
                },
                {
                  'name': 'show_reminder',
                  'description': 'Display a reminder on the screen. Use this when the user wants to set a reminder or see an existing reminder.',
                  'parameters': {
                    'type': 'object',
                    'properties': {
                      'title': {
                        'type': 'string',
                        'description': 'The title/main text of the reminder'
                      },
                      'time': {
                        'type': 'string',
                        'description': 'ISO 8601 formatted date-time string for when the reminder should trigger'
                      },
                      'description': {
                        'type': 'string',
                        'description': 'Optional additional details about the reminder'
                      }
                    },
                    'required': ['title', 'time']
                  }
                },
                {
                  'name': 'show_calendar_event',
                  'description': 'Display a calendar event on the screen. Use this when the user wants to schedule an event or see an existing event.',
                  'parameters': {
                    'type': 'object',
                    'properties': {
                      'title': {
                        'type': 'string',
                        'description': 'The title of the event'
                      },
                      'startTime': {
                        'type': 'string',
                        'description': 'ISO 8601 formatted date-time string for when the event starts'
                      },
                      'endTime': {
                        'type': 'string',
                        'description': 'ISO 8601 formatted date-time string for when the event ends (optional)'
                      },
                      'description': {
                        'type': 'string',
                        'description': 'Optional description or details about the event'
                      }
                    },
                    'required': ['title', 'startTime']
                  }
                },
                {
                  'name': 'show_list',
                  'description': 'Display a list on the screen. Use this for todo lists, shopping lists, or any bulleted list of items.',
                  'parameters': {
                    'type': 'object',
                    'properties': {
                      'title': {
                        'type': 'string',
                        'description': 'The title of the list'
                      },
                      'items': {
                        'type': 'array',
                        'items': {'type': 'string'},
                        'description': 'Array of items in the list'
                      }
                    },
                    'required': ['title', 'items']
                  }
                },
                {
                  'name': 'show_card',
                  'description': 'Display a custom information card on the screen. Use this for displaying general information, summaries, or any structured content.',
                  'parameters': {
                    'type': 'object',
                    'properties': {
                      'title': {
                        'type': 'string',
                        'description': 'The main title of the card'
                      },
                      'subtitle': {
                        'type': 'string',
                        'description': 'Optional subtitle or secondary heading'
                      },
                      'content': {
                        'type': 'string',
                        'description': 'The main content to display in the card'
                      }
                    },
                    'required': ['title']
                  }
                },
                {
                  'name': 'clear_screen',
                  'description': 'Clear all UI components from the screen. Use this when the user wants to dismiss all notes, reminders, lists, and other displayed items.',
                  'parameters': {
                    'type': 'object',
                    'properties': {}
                  }
                }
              ]
            }
          ]
        }
      };

      print('=== Setup message: ${jsonEncode(setupMsg)}');

      _channel!.sink.add(jsonEncode(setupMsg));
      _isConnected = true;
      _connectionStateController.add(true);
      print('Connected to Gemini Live API');

      // Listen to incoming messages
      _channel!.stream.listen(
        _handleIncomingMessage,
        onError: (error) {
          print('!!! WebSocket error: $error');
          print('!!! Error type: ${error.runtimeType}');
          _isConnected = false;
          _connectionStateController.add(false);
        },
        onDone: () {
          print('!!! WebSocket connection closed');
          _isConnected = false;
          _connectionStateController.add(false);
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('Error connecting to Gemini Live API: $e');
      _isConnected = false;
      _connectionStateController.add(false);
      rethrow;
    }
  }

  /// Handle incoming messages from the WebSocket
  void _handleIncomingMessage(dynamic message) {
    try {
      // Convert binary data to string if needed
      String messageString;
      if (message is String) {
        messageString = message;
      } else if (message is Uint8List) {
        messageString = utf8.decode(message);
      } else if (message is List<int>) {
        messageString = utf8.decode(message);
      } else {
        print('Unknown message type: ${message.runtimeType}');
        return;
      }

      final data = jsonDecode(messageString);
      print('<<< Received message: ${data.keys.join(", ")}');

      // Check for errors
      if (data['error'] != null) {
        print('!!! ERROR from server: ${jsonEncode(data['error'])}');
        return;
      }

      // Handle setup completion
      if (data['setupComplete'] != null) {
        print('Setup complete');
        return;
      }

      // Handle server response with content
      if (data['serverContent'] != null) {
        final modelTurn = data['serverContent']['modelTurn'];
        if (modelTurn != null && modelTurn['parts'] != null) {
          final parts = modelTurn['parts'] as List;
          print('>>> Processing ${parts.length} parts from Gemini');

          for (var part in parts) {
            // Audio data (base64 encoded PCM)
            if (part['inlineData'] != null) {
              final audioB64 = part['inlineData']['data'];
              final audioBytes = base64Decode(audioB64);
              print('>>> Received audio: ${audioBytes.length} bytes');
              _audioOutputController.add(audioBytes);
            }

            // Text data (regular text responses)
            if (part['text'] != null) {
              print('>>> Received text: ${part['text']}');
              _textOutputController.add(part['text']);
            }
          }
        }

        // Check for turn completion (interruption handling)
        if (data['serverContent']['turnComplete'] == true) {
          print('>>> Turn complete');
          _turnCompleteController.add(true);
        }
      }

      // Handle tool calls
      if (data['toolCall'] != null) {
        final toolCall = data['toolCall'];
        print('=== Tool call received');

        // Parse functionCalls array
        if (toolCall['functionCalls'] != null) {
          final functionCalls = toolCall['functionCalls'] as List;
          for (var functionCall in functionCalls) {
            print('=== Calling function: ${functionCall['name']}');
            _handleFunctionCall(functionCall);
          }
        }
      }

      // Also check for functionCall in serverContent parts
      if (data['serverContent'] != null &&
          data['serverContent']['modelTurn'] != null &&
          data['serverContent']['modelTurn']['parts'] != null) {
        final parts = data['serverContent']['modelTurn']['parts'] as List;
        for (var part in parts) {
          if (part['functionCall'] != null) {
            print('=== Function call in parts: ${part['functionCall']['name']}');
            _handleFunctionCall(part['functionCall']);
          }
        }
      }
    } catch (e) {
      print('Error handling incoming message: $e');
    }
  }

  /// Send audio data to Gemini
  /// Audio should be PCM 16kHz, 16-bit, mono
  Future<void> sendAudio(Uint8List audioData) async {
    if (!_isConnected) {
      throw Exception('Not connected to Gemini Live API');
    }

    try {
      final message = {
        'realtimeInput': {
          'mediaChunks': [
            {
              'mimeType': 'audio/pcm',
              'data': base64Encode(audioData),
            }
          ]
        }
      };

      _channel?.sink.add(jsonEncode(message));

      // Log every 50th chunk to avoid spam
      if (DateTime.now().millisecond % 50 == 0) {
        print('>>> Sent audio chunk: ${audioData.length} bytes');
      }
    } catch (e) {
      print('Error sending audio: $e');
      rethrow;
    }
  }

  /// Send text message to Gemini
  Future<void> sendText(String text) async {
    if (!_isConnected) {
      throw Exception('Not connected to Gemini Live API');
    }

    try {
      final message = {
        'clientContent': {
          'turns': [
            {
              'role': 'user',
              'parts': [
                {'text': text}
              ]
            }
          ],
          'turnComplete': true
        }
      };

      _channel?.sink.add(jsonEncode(message));
      print('Sent text: $text');
    } catch (e) {
      print('Error sending text: $e');
      rethrow;
    }
  }

  /// Handle function calls from Gemini
  void _handleFunctionCall(Map<String, dynamic> functionCall) {
    final functionName = functionCall['name'];
    final functionId = functionCall['id'];
    final args = functionCall['args'] as Map<String, dynamic>?;

    print('=== Function called: $functionName (ID: $functionId)');

    String result = 'success';

    switch (functionName) {
      case 'show_note':
        if (args != null) {
          print('=== Creating note: ${args['title']}');
          _toolCallController.add({
            'function': 'show_note',
            'title': args['title'],
            'content': args['content'],
          });
          result = 'Note "${args['title']}" displayed successfully';
        }
        break;

      case 'show_reminder':
        if (args != null) {
          print('=== Creating reminder: ${args['title']}');
          _toolCallController.add({
            'function': 'show_reminder',
            'title': args['title'],
            'time': args['time'],
            'description': args['description'],
          });
          result = 'Reminder "${args['title']}" created successfully';
        }
        break;

      case 'show_calendar_event':
        if (args != null) {
          print('=== Creating calendar event: ${args['title']}');
          _toolCallController.add({
            'function': 'show_calendar_event',
            'title': args['title'],
            'startTime': args['startTime'],
            'endTime': args['endTime'],
            'description': args['description'],
          });
          result = 'Calendar event "${args['title']}" created successfully';
        }
        break;

      case 'show_list':
        if (args != null) {
          print('=== Creating list: ${args['title']}');
          _toolCallController.add({
            'function': 'show_list',
            'title': args['title'],
            'items': args['items'],
          });
          result = 'List "${args['title']}" displayed successfully';
        }
        break;

      case 'show_card':
        if (args != null) {
          print('=== Creating card: ${args['title']}');
          _toolCallController.add({
            'function': 'show_card',
            'title': args['title'],
            'subtitle': args['subtitle'],
            'content': args['content'],
          });
          result = 'Card "${args['title']}" displayed successfully';
        }
        break;

      case 'clear_screen':
        print('=== Clearing screen');
        _toolCallController.add({
          'function': 'clear_screen',
        });
        result = 'Screen cleared successfully';
        break;

      default:
        print('=== Unknown function: $functionName');
        result = 'Unknown function: $functionName';
    }

    // Send function response back to Gemini
    if (functionId != null) {
      _sendFunctionResponse(functionId, functionName, result);
    }
  }

  /// Send function response back to Gemini
  Future<void> _sendFunctionResponse(String functionId, String functionName, String result) async {
    if (!_isConnected) return;

    try {
      final message = {
        'toolResponse': {
          'functionResponses': [
            {
              'id': functionId,
              'name': functionName,
              'response': {
                'output': {
                  'result': result,
                }
              }
            }
          ]
        }
      };

      _channel?.sink.add(jsonEncode(message));
      print('>>> Sent function response for $functionName (ID: $functionId)');
    } catch (e) {
      print('Error sending function response: $e');
    }
  }

  /// Disconnect from the Gemini Live API
  Future<void> disconnect() async {
    try {
      await _channel?.sink.close();
      _isConnected = false;
      _connectionStateController.add(false);
      print('Disconnected from Gemini Live API');
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  /// Dispose of all resources
  void dispose() {
    disconnect();
    _audioOutputController.close();
    _textOutputController.close();
    _connectionStateController.close();
    _toolCallController.close();
    _turnCompleteController.close();
  }
}
