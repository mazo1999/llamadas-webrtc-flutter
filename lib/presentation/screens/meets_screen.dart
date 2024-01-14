import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class MeetsScreen extends StatefulWidget {
  final String? meetId, callerId;
  const MeetsScreen({
    super.key,
    this.meetId,
    this.callerId,
  });

  @override
  State<MeetsScreen> createState() => _MeetsScreenState();
}

class _MeetsScreenState extends State<MeetsScreen> {
  FirebaseFirestore db = FirebaseFirestore.instance;

  final _localRTCVideoRenderer = RTCVideoRenderer();

  final _remoteRTCVideoRenderer = RTCVideoRenderer();

  MediaStream? _localStream;

  RTCPeerConnection? _rtcPeerConnection;

  List<RTCIceCandidate> rtcIceCadidates = [];

  // media status
  bool isAudioOn = true, isVideoOn = true, isFrontCameraSelected = true;

  Map<String, dynamic>? offer;

  @override
  void initState() {
    _localRTCVideoRenderer.initialize();
    _remoteRTCVideoRenderer.initialize();

    _setupPeerConnection();
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  _setupPeerConnection() async {
    // create peer connection
    _rtcPeerConnection = await createPeerConnection({
      'iceServers': [
        {
          'urls': [
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302'
          ]
        }
      ]
    });

    // listen for remotePeer mediaTrack event
    _rtcPeerConnection!.onTrack = (event) {
      _remoteRTCVideoRenderer.srcObject = event.streams[0];
      setState(() {});
    };

    // get localStream
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': isAudioOn,
      'video': isVideoOn
          ? {'facingMode': isFrontCameraSelected ? 'user' : 'environment'}
          : false,
    });

    // add mediaTrack to peerConnection
    _localStream!.getTracks().forEach((track) {
      _rtcPeerConnection!.addTrack(track, _localStream!);
    });

    // set source for local video renderer
    _localRTCVideoRenderer.srcObject = _localStream;
    setState(() {});

    // for Incoming call
    if (widget.callerId != null) {
      final getOffer = db.collection('rooms').doc(widget.callerId);
      getOffer.get().then((snapshot) async {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          if (data['offer'] != null) {
            print('Mostrando offer: ${data['offer']}');
            offer = data['offer'];

            setState(() {});
            print('Id del que llama: ${widget.callerId}');
            print('Ingreso a la llamada');
            final roomRef = db.collection('rooms').doc(widget.callerId);

            //! Esta es con get
            roomRef.collection('callerCandidates').get().then((snapshot) {
              snapshot.docs.forEach((document) async {
                var data = document.data() as Map<String, dynamic>;
                print(data);
                print('Got new remote ICE candidate: $data');
                await _rtcPeerConnection!.addCandidate(
                  RTCIceCandidate(
                    data['candidate'],
                    data['sdpMid'],
                    data['sdpMLineIndex'],
                  ),
                );
              });
            });
            // set SDP offer as remoteDescription for peerConnection
            await _rtcPeerConnection!.setRemoteDescription(
              RTCSessionDescription(offer!["sdp"], offer!["type"]),
            );

            //create SDP answer
            RTCSessionDescription answer =
                await _rtcPeerConnection!.createAnswer();

            // set SDP answer as localDescription for peerConnection
            _rtcPeerConnection!.setLocalDescription(answer);

            // log('${answer.toMap()}');

            roomRef.update({
              'id': widget.callerId,
              'answer': answer.toMap(),
            });
          }
        } else {
          print('No data');
        }
      });
      setState(() {});
    } else {
      final roomRef = db.collection('rooms').doc(widget.meetId);
      var callerCandidatesCollection = roomRef.collection('callerCandidates');
      // listen for local iceCandidate and add it to the list of IceCandidate
      _rtcPeerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        rtcIceCadidates.add(candidate);
        callerCandidatesCollection.add(candidate.toMap());
      };

      roomRef.snapshots().listen((DocumentSnapshot snapshot) async {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()! as Map<String, dynamic>;
          setState(() {});
          try {
            if (data['answer'] != null) {
              print('Mostrando answer: ${data['answer']}');
              final remoteDesc = data['answer'];
              await _rtcPeerConnection!.setRemoteDescription(
                RTCSessionDescription(remoteDesc['sdp'], remoteDesc['type']),
              );
            }
          } catch (e) {
            if (data['answer'] != null) {
              print('Mostrando answer: ${data['answer']}');
              final rtcSessionDescription = RTCSessionDescription(
                data['answer']['sdp'],
                data['answer']['type'],
              );
              _rtcPeerConnection!.setRemoteDescription(
                rtcSessionDescription,
              );
            }
          }
        } else {
          print('No data');
        }
      });

      // create SDP Offer
      RTCSessionDescription offer = await _rtcPeerConnection!.createOffer();

      // set SDP offer as localDescription for peerConnection
      await _rtcPeerConnection!.setLocalDescription(offer);

      roomRef.set({
        'offer': offer.toMap(),
      });
      setState(() {});
    }
  }

  _leaveCall() {
    Navigator.pop(context);
  }

  _toggleMic() {
    // change status
    isAudioOn = !isAudioOn;
    // enable or disable audio track
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = isAudioOn;
    });
    setState(() {});
  }

  _toggleCamera() {
    // change status
    isVideoOn = !isVideoOn;

    // enable or disable video track
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = isVideoOn;
    });
    setState(() {});
  }

  _switchCamera() {
    // change status
    isFrontCameraSelected = !isFrontCameraSelected;

    // switch camera
    _localStream?.getVideoTracks().forEach((track) {
      // ignore: deprecated_member_use
      track.switchCamera();
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("P2P Call App"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(children: [
                RTCVideoView(
                  _remoteRTCVideoRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: SizedBox(
                    height: 150,
                    width: 120,
                    child: RTCVideoView(
                      _localRTCVideoRenderer,
                      mirror: isFrontCameraSelected,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                )
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.call_end),
                    iconSize: 30,
                    onPressed: _leaveCall,
                  ),
                  IconButton.filled(
                    selectedIcon: const Icon(Icons.mic),
                    isSelected: isAudioOn,
                    icon: const Icon(Icons.mic_off),
                    iconSize: 30,
                    onPressed: _toggleMic,
                  ),
                  IconButton.filled(
                    selectedIcon: const Icon(Icons.videocam),
                    isSelected: isVideoOn,
                    icon: const Icon(Icons.videocam_off),
                    iconSize: 30,
                    onPressed: _toggleCamera,
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.cameraswitch),
                    iconSize: 30,
                    onPressed: _switchCamera,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _localRTCVideoRenderer.dispose();
    _remoteRTCVideoRenderer.dispose();
    _localStream?.dispose();
    _rtcPeerConnection?.dispose();
    super.dispose();
  }
}
