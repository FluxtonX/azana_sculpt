class MotivationQuotes {
  static const List<_Quote> _quotes = [
    _Quote(
      text: 'She believed she could, so she did.',
      author: 'R.S. Grey',
    ),
    _Quote(
      text: 'Your body can stand almost anything. It\'s your mind you have to convince.',
      author: 'Unknown',
    ),
    _Quote(
      text: 'Strength doesn\'t come from what you can do. It comes from overcoming the things you once thought you couldn\'t.',
      author: 'Rikki Rogers',
    ),
    _Quote(
      text: 'The only bad workout is the one that didn\'t happen.',
      author: 'Unknown',
    ),
    _Quote(
      text: 'Take care of your body. It\'s the only place you have to live.',
      author: 'Jim Rohn',
    ),
    _Quote(
      text: 'You are one workout away from a good mood.',
      author: 'Unknown',
    ),
    _Quote(
      text: 'Progress, not perfection.',
      author: 'Unknown',
    ),
    _Quote(
      text: 'Don\'t wish for a good body. Work for it.',
      author: 'Unknown',
    ),
    _Quote(
      text: 'Small daily improvements over time lead to stunning results.',
      author: 'Robin Sharma',
    ),
    _Quote(
      text: 'Your future self is watching you through memories.',
      author: 'Unknown',
    ),
    _Quote(
      text: 'The pain you feel today will be the strength you feel tomorrow.',
      author: 'Unknown',
    ),
    _Quote(
      text: 'Embrace the discomfort. It means you are growing.',
      author: 'Unknown',
    ),
    _Quote(
      text: 'You didn\'t come this far to only come this far.',
      author: 'Unknown',
    ),
    _Quote(
      text: 'Be the woman who decided to go for it.',
      author: 'Unknown',
    ),
    _Quote(
      text: 'Every rep. Every set. Every day. That\'s how legends are built.',
      author: 'Unknown',
    ),
    _Quote(
      text: 'Sweat, smile, repeat.',
      author: 'Unknown',
    ),
    _Quote(
      text: 'Your only limit is you.',
      author: 'Unknown',
    ),
    _Quote(
      text: 'Difficult roads often lead to beautiful destinations.',
      author: 'Zig Ziglar',
    ),
    _Quote(
      text: 'The secret of getting ahead is getting started.',
      author: 'Mark Twain',
    ),
    _Quote(
      text: 'Train like a beast. Look like a beauty.',
      author: 'Unknown',
    ),
    _Quote(
      text: 'She is fierce. She is strong. She is unstoppable.',
      author: 'Unknown',
    ),
    _Quote(
      text: 'Fall in love with taking care of yourself — mind, body, spirit.',
      author: 'Unknown',
    ),
    _Quote(
      text: 'Consistency over intensity. Always.',
      author: 'Unknown',
    ),
    _Quote(
      text: 'Every morning you have two choices: continue to sleep with your dreams, or wake up and chase them.',
      author: 'Unknown',
    ),
    _Quote(
      text: 'You are stronger than you think.',
      author: 'Unknown',
    ),
    _Quote(
      text: 'Make yourself a priority — once in a while, at least.',
      author: 'Unknown',
    ),
    _Quote(
      text: 'The body achieves what the mind believes.',
      author: 'Unknown',
    ),
    _Quote(
      text: 'Move because you love your body, not because you hate it.',
      author: 'Unknown',
    ),
    _Quote(
      text: 'Champions train. Legends gain.',
      author: 'Unknown',
    ),
    _Quote(
      text: 'Today\'s effort is tomorrow\'s result.',
      author: 'Unknown',
    ),
  ];

  /// Returns a deterministic daily quote based on day of year
  static _Quote getDailyQuote() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return _quotes[dayOfYear % _quotes.length];
  }

  static String get dailyText => getDailyQuote().text;
  static String get dailyAuthor => getDailyQuote().author;
}

class _Quote {
  final String text;
  final String author;
  const _Quote({required this.text, required this.author});
}
