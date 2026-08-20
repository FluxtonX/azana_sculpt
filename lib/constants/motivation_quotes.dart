class MotivationQuotes {
  static const List<Quote> _quotes = [
    Quote(
      text: 'She believed she could, so she did.',
      author: 'R.S. Grey',
    ),
    Quote(
      text: 'Your body can stand almost anything. It\'s your mind you have to convince.',
      author: 'Unknown',
    ),
    Quote(
      text: 'Strength doesn\'t come from what you can do. It comes from overcoming the things you once thought you couldn\'t.',
      author: 'Rikki Rogers',
    ),
    Quote(
      text: 'The only bad workout is the one that didn\'t happen.',
      author: 'Unknown',
    ),
    Quote(
      text: 'Take care of your body. It\'s the only place you have to live.',
      author: 'Jim Rohn',
    ),
    Quote(
      text: 'You are one workout away from a good mood.',
      author: 'Unknown',
    ),
    Quote(
      text: 'Progress, not perfection.',
      author: 'Unknown',
    ),
    Quote(
      text: 'Don\'t wish for a good body. Work for it.',
      author: 'Unknown',
    ),
    Quote(
      text: 'Small daily improvements over time lead to stunning results.',
      author: 'Robin Sharma',
    ),
    Quote(
      text: 'Your future self is watching you through memories.',
      author: 'Unknown',
    ),
    Quote(
      text: 'The pain you feel today will be the strength you feel tomorrow.',
      author: 'Unknown',
    ),
    Quote(
      text: 'Embrace the discomfort. It means you are growing.',
      author: 'Unknown',
    ),
    Quote(
      text: 'You didn\'t come this far to only come this far.',
      author: 'Unknown',
    ),
    Quote(
      text: 'Be the woman who decided to go for it.',
      author: 'Unknown',
    ),
    Quote(
      text: 'Every rep. Every set. Every day. That\'s how legends are built.',
      author: 'Unknown',
    ),
    Quote(
      text: 'Sweat, smile, repeat.',
      author: 'Unknown',
    ),
    Quote(
      text: 'Your only limit is you.',
      author: 'Unknown',
    ),
    Quote(
      text: 'Difficult roads often lead to beautiful destinations.',
      author: 'Zig Ziglar',
    ),
    Quote(
      text: 'The secret of getting ahead is getting started.',
      author: 'Mark Twain',
    ),
    Quote(
      text: 'Train like a beast. Look like a beauty.',
      author: 'Unknown',
    ),
    Quote(
      text: 'She is fierce. She is strong. She is unstoppable.',
      author: 'Unknown',
    ),
    Quote(
      text: 'Fall in love with taking care of yourself — mind, body, spirit.',
      author: 'Unknown',
    ),
    Quote(
      text: 'Consistency over intensity. Always.',
      author: 'Unknown',
    ),
    Quote(
      text: 'Every morning you have two choices: continue to sleep with your dreams, or wake up and chase them.',
      author: 'Unknown',
    ),
    Quote(
      text: 'You are stronger than you think.',
      author: 'Unknown',
    ),
    Quote(
      text: 'Make yourself a priority — once in a while, at least.',
      author: 'Unknown',
    ),
    Quote(
      text: 'The body achieves what the mind believes.',
      author: 'Unknown',
    ),
    Quote(
      text: 'Move because you love your body, not because you hate it.',
      author: 'Unknown',
    ),
    Quote(
      text: 'Champions train. Legends gain.',
      author: 'Unknown',
    ),
    Quote(
      text: 'Today\'s effort is tomorrow\'s result.',
      author: 'Unknown',
    ),
  ];

  /// Returns a deterministic daily quote based on day of year
  static Quote getDailyQuote() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return _quotes[dayOfYear % _quotes.length];
  }

  static String get dailyText => getDailyQuote().text;
  static String get dailyAuthor => getDailyQuote().author;
}

class Quote {
  final String text;
  final String author;
  const Quote({required this.text, required this.author});
}
