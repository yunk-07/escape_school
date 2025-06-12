import 'package:audioplayers/audioplayers.dart';

class MusicManager {
  static final MusicManager _instance = MusicManager._internal();
  factory MusicManager() => _instance;
  MusicManager._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  String? _currentBgm;

  // 初始化方法
  Future<void> initialize() async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop); // 背景音乐循环播放
    await _sfxPlayer.setReleaseMode(ReleaseMode.release); // 音效只播放一次
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
}