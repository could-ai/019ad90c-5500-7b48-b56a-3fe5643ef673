import 'package:flutter/material.dart';
import 'dart:math';

// Game constants
const double paddleWidth = 100.0;
const double paddleHeight = 20.0;
const double ballRadius = 10.0;
const double brickHeight = 20.0;

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Game state
  Offset? ballPosition;
  Offset ballVelocity = const Offset(4, -4); // Initial velocity
  Rect paddleRect = Rect.zero;
  List<Rect> bricks = [];
  int score = 0;
  int lives = 3;
  bool gameStarted = false;
  bool gameOver = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 99), // Effectively infinite
    )..addListener(_updateGame);
  }
  
  void _startGame() {
    if (mounted) {
      final size = MediaQuery.of(context).size;
      _initializeGame(size);
      setState(() {
        gameStarted = true;
        gameOver = false;
        score = 0;
        lives = 3;
      });
      _controller.forward();
    }
  }

  void _initializeGame(Size size) {
    // Initialize paddle
    paddleRect = Rect.fromLTWH(
      (size.width - paddleWidth) / 2,
      size.height - paddleHeight - 50, // 50 pixels from bottom
      paddleWidth,
      paddleHeight,
    );

    // Initialize ball
    ballPosition = Offset(
      paddleRect.center.dx,
      paddleRect.top - ballRadius,
    );
    
    ballVelocity = const Offset(4, -4);

    // Initialize bricks
    bricks.clear();
    const brickRowCount = 5;
    const brickColumnCount = 8;
    final brickWidth = (size.width - (brickColumnCount + 1) * 4) / brickColumnCount;
    for (int i = 0; i < brickRowCount; i++) {
      for (int j = 0; j < brickColumnCount; j++) {
        bricks.add(
          Rect.fromLTWH(
            (j * (brickWidth + 4)) + 4,
            (i * (brickHeight + 4)) + 50, // Start 50px from top
            brickWidth,
            brickHeight,
          ),
        );
      }
    }
  }

  void _updateGame() {
    if (!gameStarted || gameOver) return;

    setState(() {
      final size = MediaQuery.of(context).size;
      
      // Move ball
      ballPosition = ballPosition! + ballVelocity;

      // Ball collision with walls
      if (ballPosition!.dx <= ballRadius || ballPosition!.dx >= size.width - ballRadius) {
        ballVelocity = Offset(-ballVelocity.dx, ballVelocity.dy);
      }
      if (ballPosition!.dy <= ballRadius) {
        ballVelocity = Offset(ballVelocity.dx, -ballVelocity.dy);
      }

      // Ball collision with paddle
      if (paddleRect.contains(ballPosition! + Offset(0, ballRadius))) {
        // Simple bounce
        ballVelocity = Offset(ballVelocity.dx, -ballVelocity.dy);
      }
      
      // Ball collision with bricks
      Rect? hitBrick;
      for (final brick in bricks) {
        if (brick.contains(ballPosition!)) {
          hitBrick = brick;
          score += 10;
          // Simple bounce logic
          ballVelocity = Offset(ballVelocity.dx, -ballVelocity.dy);
          break;
        }
      }
      if (hitBrick != null) {
        bricks.remove(hitBrick);
      }
      
      // Check for win
      if (bricks.isEmpty) {
        _controller.stop();
        setState(() {
          gameOver = true;
        });
        // You could show a "You Win!" message here
      }

      // Check for losing a life
      if (ballPosition!.dy > size.height) {
        lives--;
        if (lives <= 0) {
          _controller.stop();
          setState(() {
            gameOver = true;
          });
        } else {
          // Reset ball position
           ballPosition = Offset(
            paddleRect.center.dx,
            paddleRect.top - ballRadius,
          );
           ballVelocity = const Offset(4, -4);
        }
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (gameOver) return;
    setState(() {
      final newLeft = (paddleRect.left + details.delta.dx).clamp(0.0, MediaQuery.of(context).size.width - paddleWidth);
      paddleRect = Rect.fromLTWH(
        newLeft,
        paddleRect.top,
        paddleWidth,
        paddleHeight,
      );
      if (!gameStarted) {
        // Ball follows paddle before game starts
        ballPosition = Offset(paddleRect.center.dx, paddleRect.top - ballRadius);
      }
    });
  }
  
  void _onTap() {
      if (!gameStarted) {
          _startGame();
      } else if (gameOver) {
          _startGame();
      }
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize game on first build if not already done
    if (paddleRect == Rect.zero) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if(mounted) {
            final size = MediaQuery.of(context).size;
            _initializeGame(size);
            setState((){});
         }
       });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onTap: _onTap,
        child: CustomPaint(
          painter: GamePainter(
            paddleRect: paddleRect,
            ballPosition: ballPosition,
            bricks: bricks,
            score: score,
            lives: lives,
            gameStarted: gameStarted,
            gameOver: gameOver,
          ),
          child: Container(),
        ),
      ),
    );
  }
}

class GamePainter extends CustomPainter {
  final Rect paddleRect;
  final Offset? ballPosition;
  final List<Rect> bricks;
  final int score;
  final int lives;
  final bool gameStarted;
  final bool gameOver;

  GamePainter({
    required this.paddleRect,
    required this.ballPosition,
    required this.bricks,
    required this.score,
    required this.lives,
    required this.gameStarted,
    required this.gameOver,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw paddle
    final paddlePaint = Paint()..color = Colors.blue;
    canvas.drawRect(paddleRect, paddlePaint);

    // Draw bricks
    final brickPaint = Paint()..color = Colors.red;
    for (final brick in bricks) {
      canvas.drawRect(brick, brickPaint);
    }

    // Draw ball
    if (ballPosition != null) {
      final ballPaint = Paint()..color = Colors.yellow;
      canvas.drawCircle(ballPosition!, ballRadius, ballPaint);
    }
    
    // Draw Score and Lives
    final textPainter = TextPainter(
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.text = TextSpan(
      text: 'Score: $score',
      style: const TextStyle(color: Colors.white, fontSize: 24),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(20, 20));

    textPainter.text = TextSpan(
      text: 'Lives: $lives',
      style: const TextStyle(color: Colors.white, fontSize: 24),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - textPainter.width - 20, 20));
    
    // Draw Start/Game Over message
    if (!gameStarted) {
      _drawCenteredText(canvas, size, 'Tap to Start');
    } else if (gameOver) {
      if (bricks.isEmpty) {
        _drawCenteredText(canvas, size, 'You Win!\\nScore: $score\\nTap to Play Again');
      } else {
        _drawCenteredText(canvas, size, 'Game Over\\nScore: $score\\nTap to Play Again');
      }
    }
  }
  
  void _drawCenteredText(Canvas canvas, Size size, String text) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(color: Colors.white, fontSize: 48),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(minWidth: 0, maxWidth: size.width * 0.8);
      final position = Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      );
      textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
