import 'package:audioplayers/audioplayers.dart';

class MusicManager {
  static final MusicManager _instance = MusicManager._internal();
  factory MusicManager() => _instance;
  MusicManager._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _heartbeatPlayer = AudioPlayer();
  String? _currentBgm;
  bool _heartbeatOn = false;

  // 初始化方法
  Future<void> initialize() async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop); // 背景音乐循环播放
    await _sfxPlayer.setReleaseMode(ReleaseMode.release); // 音效只播放一次
    await _heartbeatPlayer.setReleaseMode(ReleaseMode.loop); // 心跳音循环
    await _heartbeatPlayer.setVolume(0.0); // 初始静音
  }

  // 播放背景音乐
  Future<void> playBgm(String path) async {
    if (_currentBgm == path) return; // 已经在播放相同的背景音乐

    _currentBgm = path;
    await _bgmPlayer.stop(); // 停止当前背景音乐
    await _bgmPlayer.play(AssetSource(path));
  }

  // 停止背景音乐
  Future<void> stopBgm() async {
    await _bgmPlayer.stop();
    _currentBgm = null;
  }

  // 播放音效
  Future<void> playSfx(String path) async {
    await _sfxPlayer.stop(); // 停止当前音效
    await _sfxPlayer.play(AssetSource(path));
  }

  // 预定义音乐路径
  static const bgmGameStart = 'music/01.mp3';
  static const bgmGhostDetect = 'music/02.mp3';
  static const sfxButtonClick = 'music/s01.mp3';
  static const sfxPurchase = 'music/s02.mp3';
  static const sfxGhostAttack = 'music/03.mp3';
  static const sfxHeartbeat = 'music/heart-sound.mp3';

  // 根据接近度开启/更新/关闭心跳音效
  // proximity: 0.0-1.0；threshold: 触发阈值，默认0.2
  Future<void> updateHeartbeat(double proximity, {double threshold = 0.2}) async {
    final p = proximity.clamp(0.0, 1.0);
    if (p >= threshold) {
      // 计算音量与播放速率
      final double volume = (0.2 + 0.8 * p).clamp(0.0, 1.0); // 越近越响
      final double rate = (1.0 + 0.5 * p).clamp(0.8, 1.5);   // 越近越快

      if (!_heartbeatOn) {
        _heartbeatOn = true;
        await _heartbeatPlayer.stop();
        await _heartbeatPlayer.setVolume(volume);
        // setPlaybackRate在部分平台可用；若不可用会被忽略
        try { await _heartbeatPlayer.setPlaybackRate(rate); } catch (_) {}
        await _heartbeatPlayer.play(AssetSource(sfxHeartbeat));
      } else {
        await _heartbeatPlayer.setVolume(volume);
        try { await _heartbeatPlayer.setPlaybackRate(rate); } catch (_) {}
      }
    } else {
      // 低于阈值停止心跳音
      if (_heartbeatOn) {
        _heartbeatOn = false;
        await _heartbeatPlayer.stop();
      }
    }
  }
}