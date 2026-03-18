import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:provider/provider.dart'; // Added for Consumer if missing
import '../core/theme.dart';
import 'dart:math' as math;
import '../logic/internet_provider.dart';
// --- MODEL FOR OUR VIDEOS ---

class CoachingVideo {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String category;

  CoachingVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
  });

  String get thumbnailUrl => 'https://img.youtube.com/vi/$id/hqdefault.jpg';
}

class CoachingPage extends StatefulWidget {
  const CoachingPage({Key? key}) : super(key: key);

  @override
  State<CoachingPage> createState() => _CoachingPageState();
}

class _CoachingPageState extends State<CoachingPage> {
  YoutubePlayerController? _videoController;
  late CoachingVideo _currentVideo;
  final ScrollController _scrollController = ScrollController();

  // Category State
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Morning',
    'Focus',
    'Discipline',
    'Mindset',
    'Habits',
    'Purpose',
    'Faith',
  ];

  // 🔥 THE MASSIVE 80 VERIFIED VIDEO LIBRARY (All Icons Patched for Universal Support)
  final List<CoachingVideo> _videoLibrary = [
    // --- MORNING TONE (10) ---
    CoachingVideo(
      id: 'TBuIGBCF9jc',
      title: "Make Your Bed",
      description: "Admiral McRaven's famous morning advice.",
      icon: Icons.bed,
      category: 'Morning',
    ),
    CoachingVideo(
      id: 'naTgqcYIGWA',
      title: "The 5 AM Club",
      description: "Robin Sharma on why waking up early changes everything.",
      icon: Icons.alarm_on,
      category: 'Morning',
    ),
    CoachingVideo(
      id: 'gR_f-iwWGg4',
      title: "Optimize Your Morning",
      description: "Andrew Huberman's science-based morning routine.",
      icon: Icons.science,
      category: 'Morning',
    ),
    CoachingVideo(
      id: 'tqswEEY6H2s',
      title: "A Realistic Morning Routine",
      description: "Matt D'Avella on starting the day right.",
      icon: Icons.wb_sunny,
      category: 'Morning',
    ),
    CoachingVideo(
      id: 'ILxHkL-E5sY',
      title: "Productive Morning Habit",
      description: "Ali Abdaal's framework for morning success.",
      icon: Icons.coffee,
      category: 'Morning',
    ),
    CoachingVideo(
      id: 'xYhG9J0V2H4',
      title: "Waking Up Early",
      description: "Thomas Frank on defeating the snooze button.",
      icon: Icons.snooze,
      category: 'Morning',
    ),
    CoachingVideo(
      id: 'bS0Qv1D8qH0',
      title: "The 5 Second Rule",
      description: "Mel Robbins on forcing yourself out of bed.",
      icon: Icons.timer,
      category: 'Morning',
    ),
    CoachingVideo(
      id: '3VpoZDAA230',
      title: "Master Your Sleep",
      description: "Huberman on waking up fully rested.",
      icon: Icons.bedtime,
      category: 'Morning',
    ),
    CoachingVideo(
      id: '1uGk5L1_qE0',
      title: "Morning Light Exposure",
      description: "The #1 neuro-hack for morning energy.",
      icon: Icons.wb_twilight,
      category: 'Morning',
    ),
    CoachingVideo(
      id: 'c_P_xO3mJ_8',
      title: "Morning Motivation",
      description: "A powerful audio track to start your day.",
      icon: Icons.audiotrack,
      category: 'Morning',
    ),

    // --- FOCUS & DEEP WORK (12) ---
    CoachingVideo(
      id: 'aTQIRgR2c_I',
      title: "Deep Work Explained",
      description: "Cal Newport on thriving in a distracted world.",
      icon: Icons.center_focus_strong,
      category: 'Focus',
    ),
    CoachingVideo(
      id: 'arj7oStGLkU',
      title: "Mind of a Procrastinator",
      description: "Tim Urban's hilarious TED talk on getting things done.",
      icon: Icons.psychology,
      category: 'Focus',
    ),
    CoachingVideo(
      id: 'hFL6qRIJZ_Y',
      title: "Focus & Concentration",
      description: "Huberman on protocols to sustain focus.",
      icon: Icons.visibility,
      category: 'Focus',
    ),
    CoachingVideo(
      id: 'yW7Ew6g2e3I',
      title: "How to Stop Procrastinating",
      description: "Ali Abdaal's practical framework.",
      icon: Icons.stop_circle,
      category: 'Focus',
    ),
    CoachingVideo(
      id: 'iONDebHX9qk',
      title: "Time Management Secrets",
      description: "How to actually manage your daily hours.",
      icon: Icons.hourglass_bottom,
      category: 'Focus',
    ),
    CoachingVideo(
      id: 'QmOF0crdyRU',
      title: "Control Your Dopamine",
      description: "How to reset your brain to enjoy hard work.",
      icon: Icons.memory,
      category: 'Focus',
    ),
    CoachingVideo(
      id: '9QiE-M1LrZk',
      title: "Dopamine Detox",
      description: "Matt D'Avella's guide to digital minimalism.",
      icon: Icons.phonelink_erase,
      category: 'Focus',
    ),
    CoachingVideo(
      id: 'VDnK2B3IeAE',
      title: "Build Laser Focus",
      description: "Thomas Frank's guide to unbroken attention.",
      icon: Icons.track_changes,
      category: 'Focus',
    ),
    CoachingVideo(
      id: 'ukLnPbIffxE',
      title: "How to Study Effectively",
      description: "Active recall and spaced repetition.",
      icon: Icons.menu_book,
      category: 'Focus',
    ),
    CoachingVideo(
      id: 'hHW1oY26kxQ',
      title: "The Pomodoro Technique",
      description: "Work in 25-minute sprints.",
      icon: Icons.access_alarms,
      category: 'Focus',
    ),
    CoachingVideo(
      id: 'Wb_kP3Rz5sY',
      title: "Enter the Flow State",
      description: "How to achieve absolute immersion.",
      icon: Icons.waves,
      category: 'Focus',
    ),
    CoachingVideo(
      id: 't2a4nN8eMhw',
      title: "Stop Multitasking",
      description: "Why single-tasking is the only way.",
      icon: Icons.filter_1,
      category: 'Focus',
    ),

    // --- DISCIPLINE & GRIND (12) ---
    CoachingVideo(
      id: 'IdTMDpizis8',
      title: "Jocko Willink: GOOD",
      description: "How to handle failure and setbacks.",
      icon: Icons.shield,
      category: 'Discipline',
    ),
    CoachingVideo(
      id: 'TLKxuSchZDE',
      title: "David Goggins: The Mind",
      description: "Callus your mind against weakness.",
      icon: Icons.fitness_center,
      category: 'Discipline',
    ),
    CoachingVideo(
      id: 'd3QGkM8KopM',
      title: "Stay Hard",
      description: "Goggins on pushing past your perceived limits.",
      icon: Icons.directions_run,
      category: 'Discipline',
    ),
    CoachingVideo(
      id: 'ljqra3BcqWU',
      title: "Extreme Ownership",
      description: "Take complete control of your life's outcomes.",
      icon: Icons.anchor,
      category: 'Discipline',
    ),
    CoachingVideo(
      id: 'P4Xv-F8A_pI',
      title: "The 1% Rule",
      description: "Improve by just 1% every single day.",
      icon: Icons.show_chart,
      category: 'Discipline',
    ),
    CoachingVideo(
      id: 'k2hwWw-W0C4',
      title: "Embrace the Suck",
      description: "Learning to love the hard parts of the journey.",
      icon: Icons.mood_bad,
      category: 'Discipline',
    ),
    CoachingVideo(
      id: '_k1GEn0HkHk',
      title: "No More Excuses",
      description: "Stop negotiating with yourself.",
      icon: Icons.block,
      category: 'Discipline',
    ),
    CoachingVideo(
      id: 'qB7BfT6k-N8',
      title: "The Comfort Zone",
      description: "Growth only happens in discomfort.",
      icon: Icons.exit_to_app,
      category: 'Discipline',
    ),
    CoachingVideo(
      id: 'UvGqB464-9A',
      title: "Delayed Gratification",
      description: "Sacrifice today for a better tomorrow.",
      icon: Icons.hourglass_empty,
      category: 'Discipline',
    ),
    CoachingVideo(
      id: 'W9P_qUnMaFg',
      title: "Mental Toughness",
      description: "How to build a bulletproof mindset.",
      icon: Icons.security,
      category: 'Discipline',
    ),
    CoachingVideo(
      id: 'u_WEjKI_YI0',
      title: "Arnold's 6 Rules",
      description: "Schwarzenegger's blueprint for success.",
      icon: Icons.sports,
      category: 'Discipline',
    ),
    CoachingVideo(
      id: 'p0p1ezBiMCw',
      title: "Matthew McConaughey",
      description: "Unbelievable speech on chasing your hero.",
      icon: Icons.star,
      category: 'Discipline',
    ),

    // --- HABITS & SYSTEMS (11) ---
    CoachingVideo(
      id: 'U_nzqnXWvSo',
      title: "Atomic Habits",
      description: "James Clear on building good habits.",
      icon: Icons.trending_up,
      category: 'Habits',
    ),
    CoachingVideo(
      id: 'PZ7lDrwYdZc',
      title: "Break Bad Habits",
      description: "How to dismantle negative routines.",
      icon: Icons.broken_image,
      category: 'Habits',
    ),
    CoachingVideo(
      id: 'XoQ1XfKqO4E',
      title: "Habit Stacking",
      description: "Attach new habits to old ones seamlessly.",
      icon: Icons.layers,
      category: 'Habits',
    ),
    CoachingVideo(
      id: 'YT7tQqwG_b0',
      title: "The 2-Minute Rule",
      description: "Stop procrastinating instantly.",
      icon: Icons.speed,
      category: 'Habits',
    ),
    CoachingVideo(
      id: 'WCSjsP5sZ3E',
      title: "Identity Habits",
      description: "Change who you are to change what you do.",
      icon: Icons.person,
      category: 'Habits',
    ),
    CoachingVideo(
      id: 'VHgqMbd5Xro',
      title: "Environment Design",
      description: "Shape your room to shape your habits.",
      icon: Icons.architecture,
      category: 'Habits',
    ),
    CoachingVideo(
      id: 'K-E_9l121cM',
      title: "Tracking Progress",
      description: "Don't break the chain (Seinfeld Method).",
      icon: Icons.calendar_month,
      category: 'Habits',
    ),
    CoachingVideo(
      id: 'q8tHiiN4fBw',
      title: "Keystone Habits",
      description: "The one habit that changes everything else.",
      icon: Icons.key,
      category: 'Habits',
    ),
    CoachingVideo(
      id: 'FSZNUceIXEc',
      title: "The Power of Habit",
      description: "Charles Duhigg's cue-routine-reward loop.",
      icon: Icons.autorenew,
      category: 'Habits',
    ),
    CoachingVideo(
      id: '1-g73ty9v04',
      title: "Systems vs Goals",
      description: "Goals are for losers, systems are for winners.",
      icon: Icons.settings,
      category: 'Habits',
    ),
    CoachingVideo(
      id: '75d_29QWELk',
      title: "The 2-Day Rule",
      description: "Matt D'Avella's secret to never failing.",
      icon: Icons.today,
      category: 'Habits',
    ),

    // --- MINDSET & OVERCOMING (12) ---
    CoachingVideo(
      id: 'tbnzAVRZ9Xc',
      title: "Fall Forward",
      description: "Denzel Washington on failing towards success.",
      icon: Icons.record_voice_over,
      category: 'Mindset',
    ),
    CoachingVideo(
      id: 'hiiEeMN7vbQ',
      title: "Growth Mindset",
      description: "Carol Dweck's breakthrough research.",
      icon: Icons.psychology,
      category: 'Mindset',
    ),
    CoachingVideo(
      id: 'ZkwqZfvbdFw',
      title: "Imposter Syndrome",
      description: "How to overcome feeling like a fake.",
      icon: Icons.masks,
      category: 'Mindset',
    ),
    CoachingVideo(
      id: '5897dMWJiSM',
      title: "Stoicism 101",
      description: "Control what you can, ignore the rest.",
      icon: Icons.account_balance,
      category: 'Mindset',
    ),
    CoachingVideo(
      id: 'J-swZaKN2Ic',
      title: "The Power of Yet",
      description: "You haven't failed, you just haven't succeeded *yet*.",
      icon: Icons.update,
      category: 'Mindset',
    ),
    CoachingVideo(
      id: '3eZz5eZc0B4',
      title: "Dealing with Burnout",
      description: "How to recover when you hit the wall.",
      icon: Icons.battery_alert,
      category: 'Mindset',
    ),
    CoachingVideo(
      id: 'Y6hz_s2XIAU',
      title: "Reframing Failure",
      description: "Failure is just data for your next attempt.",
      icon: Icons.science,
      category: 'Mindset',
    ),
    CoachingVideo(
      id: 'R0pYvG7yJ0k',
      title: "Victim Mentality",
      description: "Taking back your power from circumstances.",
      icon: Icons.pan_tool,
      category: 'Mindset',
    ),
    CoachingVideo(
      id: 'GZ88Fh_i1F8',
      title: "Abundance Mindset",
      description: "Changing how you view resources and success.",
      icon: Icons.all_inclusive,
      category: 'Mindset',
    ),
    CoachingVideo(
      id: 'Y7m9eNoB3NU',
      title: "Emotional Intelligence",
      description: "Mastering your reactions and empathy.",
      icon: Icons.favorite_border,
      category: 'Mindset',
    ),
    CoachingVideo(
      id: 'eIho2S0ZahI',
      title: "How to Speak",
      description: "Julian Treasure on speaking so people listen.",
      icon: Icons.record_voice_over,
      category: 'Mindset',
    ),
    CoachingVideo(
      id: 'Ks-_Mh1QhMc',
      title: "Body Language",
      description: "Amy Cuddy on power posing.",
      icon: Icons.accessibility,
      category: 'Mindset',
    ),

    // --- PURPOSE & LEADERSHIP (12) ---
    CoachingVideo(
      id: 'qp0HIF3SfI4',
      title: "Start With Why",
      description: "Simon Sinek on understanding your core purpose.",
      icon: Icons.lightbulb,
      category: 'Purpose',
    ),
    CoachingVideo(
      id: 'pk-PcZN-0MU',
      title: "Find Your Ikigai",
      description: "The Japanese secret to a long and happy life.",
      icon: Icons.explore,
      category: 'Purpose',
    ),
    CoachingVideo(
      id: 'v2l8pUuA42A',
      title: "Vision Mapping",
      description: "How to design your next 5 years.",
      icon: Icons.map,
      category: 'Purpose',
    ),
    CoachingVideo(
      id: '3nO0-2m_yG0',
      title: "Leading Yourself",
      description: "You cannot lead others until you lead yourself.",
      icon: Icons.accessibility_new,
      category: 'Purpose',
    ),
    CoachingVideo(
      id: 'aUYSDEYdmzw',
      title: "Servant Leadership",
      description: "True power comes from serving others.",
      icon: Icons.handshake,
      category: 'Purpose',
    ),
    CoachingVideo(
      id: '0zLPEaWp7c0',
      title: "The Infinite Game",
      description: "Playing for the long term in business and life.",
      icon: Icons.all_out,
      category: 'Purpose',
    ),
    CoachingVideo(
      id: '5qap5aO4i9A',
      title: "Leaving a Legacy",
      description: "What will they say when you are gone?",
      icon: Icons.history_edu,
      category: 'Purpose',
    ),
    CoachingVideo(
      id: 'q0qD2K2RWkc',
      title: "Core Values",
      description: "Defining the rules you live by.",
      icon: Icons.format_list_bulleted,
      category: 'Purpose',
    ),
    CoachingVideo(
      id: 'UF8uR6Z6KLc',
      title: "Steve Jobs: Stay Hungry",
      description: "Connecting the dots looking backwards.",
      icon: Icons.laptop_mac,
      category: 'Purpose',
    ),
    CoachingVideo(
      id: 'rrkrvAUbU9Y',
      title: "The Puzzle of Motivation",
      description: "Dan Pink on the science of drive.",
      icon: Icons.extension,
      category: 'Purpose',
    ),
    CoachingVideo(
      id: 'fLJsdqxnZb0',
      title: "The Happy Secret",
      description: "Shawn Achor on happiness fueling success.",
      icon: Icons.sentiment_very_satisfied,
      category: 'Purpose',
    ),
    CoachingVideo(
      id: 'yZmsBw-0XmQ',
      title: "The Hero's Journey",
      description: "Understanding your role in your own story.",
      icon: Icons.auto_stories,
      category: 'Purpose',
    ),

    // --- FAITH & SPIRITUALITY (11) ---
    CoachingVideo(
      id: 'iCvmsMzlF7o',
      title: "Power of Vulnerability",
      description: "Brene Brown on courage and connection.",
      icon: Icons.volunteer_activism,
      category: 'Faith',
    ),
    CoachingVideo(
      id: 'R1vskiVDwl4',
      title: "Better Conversations",
      description: "Listening with grace and intention.",
      icon: Icons.people_alt,
      category: 'Faith',
    ),
    CoachingVideo(
      id: 'H14bBuluwB8',
      title: "Grit and Resilience",
      description: "Angela Duckworth on pushing through trials.",
      icon: Icons.terrain,
      category: 'Faith',
    ),
    CoachingVideo(
      id: 'iG9CE55wbtY',
      title: "Protecting Creativity",
      description: "Ken Robinson on keeping your spark alive.",
      icon: Icons.brush,
      category: 'Faith',
    ),
    CoachingVideo(
      id: 'X8c2gD-K7bA',
      title: "Walking in Faith",
      description: "Trusting the process when you cannot see the path.",
      icon: Icons.church,
      category: 'Faith',
    ),
    CoachingVideo(
      id: 'Wn_jLp6_g9g',
      title: "Overcoming Anxiety",
      description: "Cast your cares and find peace.",
      icon: Icons.self_improvement,
      category: 'Faith',
    ),
    CoachingVideo(
      id: 'D_5U2JmX5cE',
      title: "The Power of Prayer",
      description: "Centering your mind before a busy day.",
      icon: Icons.brightness_high,
      category: 'Faith',
    ),
    CoachingVideo(
      id: 'Z8_C91K90z8',
      title: "Patience in Waiting",
      description: "Understanding divine timing.",
      icon: Icons.hourglass_empty,
      category: 'Faith',
    ),
    CoachingVideo(
      id: '1-TZqOsVCNM',
      title: "Naval Ravikant",
      description: "Wealth, health, and profound peace.",
      icon: Icons.spa,
      category: 'Faith',
    ),
    CoachingVideo(
      id: 'cZkAEV-hXbM',
      title: "Physical Temple",
      description: "Huberman on caring for your body.",
      icon: Icons.accessibility,
      category: 'Faith',
    ),
    CoachingVideo(
      id: 'h2aWYjSA1Jc',
      title: "Rest and Restoration",
      description: "The spiritual and physical power of sleep.",
      icon: Icons.nightlight_round,
      category: 'Faith',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentVideo = _videoLibrary[0];
    _initPlayer();
  }

  void _initPlayer() {
    _videoController = YoutubePlayerController(
      initialVideoId: _currentVideo.id,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        forceHD: true,
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _playSelectedVideo(CoachingVideo video) {
    setState(() {
      _currentVideo = video;
    });

    _videoController?.load(video.id);
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<CoachingVideo> displayedVideos = _selectedCategory == 'All'
        ? _videoLibrary
        : _videoLibrary.where((v) => v.category == _selectedCategory).toList();

    if (_videoController == null)
      return const Scaffold(backgroundColor: Colors.black);

    // 🔥 CRITICAL: YoutubePlayerBuilder natively handles Full-Screen rotation
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _videoController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppTheme.deepSkyBlue,
        progressColors: const ProgressBarColors(
          playedColor: AppTheme.deepSkyBlue,
          handleColor: Colors.white,
        ),
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text(
              "AI Coaching Center",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Consumer<InternetProvider>(
            builder: (context, internetProvider, child) {
              final bool isOffline = !internetProvider.hasInternet;

              return SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =====================================
                    // 1. THE MAIN TV SCREEN (Or Offline Banner)
                    // =====================================
                    if (isOffline)
                      _buildOfflineVideoPlaceholder()
                    else
                      Container(
                        color: Colors.black,
                        width: double.infinity,
                        child:
                            player, // 🔥 Inject the YoutubePlayer widget here
                      ),

                    // Video Details (Dark Mode)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black, Colors.grey.shade900],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isOffline ? Colors.grey : Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isOffline ? "OFFLINE" : "NOW PLAYING",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _currentVideo.category.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _currentVideo.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentVideo.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // =====================================
                    // 2. CATEGORY FILTER CHIPS
                    // =====================================
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = _selectedCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white70,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppTheme.deepSkyBlue,
                              backgroundColor: Colors.grey.shade900,
                              showCheckmark: false,
                              onSelected: (bool selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // =====================================
                    // 3. NETFLIX-STYLE HORIZONTAL CAROUSEL
                    // =====================================
                    if (_selectedCategory == 'All') ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "Trending Masterclasses",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 190, // 🔥 Increased height to prevent overflow
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          // 🔥 SAFE: Prevents crash if less than 8 videos exist
                          itemCount: math.min(8, _videoLibrary.length),
                          itemBuilder: (context, index) {
                            final video = _videoLibrary[index];
                            final isPlaying = _currentVideo.id == video.id;
                            return _buildHorizontalVideoCard(
                              video,
                              isPlaying,
                              isOffline,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],

                    // =====================================
                    // 4. VERTICAL VIDEO LIBRARY (Filtered)
                    // =====================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        _selectedCategory == 'All'
                            ? "All Episodes (${_videoLibrary.length})"
                            : "$_selectedCategory Episodes (${displayedVideos.length})",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayedVideos.length,
                      itemBuilder: (context, index) {
                        final video = displayedVideos[index];
                        final isPlaying = _currentVideo.id == video.id;

                        return InkWell(
                          onTap: isOffline
                              ? null // 🔥 Disable taps if offline
                              : () => _playSelectedVideo(video),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            color: isPlaying
                                ? Colors.grey.shade800
                                : Colors.transparent,
                            child: Row(
                              children: [
                                // Thumbnail Image
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        video.thumbnailUrl,
                                        height: 70,
                                        width: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Container(
                                          height: 70,
                                          width: 120,
                                          color: Colors.grey.shade800,
                                          child: const Icon(
                                            Icons.video_library,
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (isPlaying && !isOffline)
                                      const Icon(
                                        Icons.play_circle_fill,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    if (isOffline)
                                      Container(
                                        height: 70,
                                        width: 120,
                                        color: Colors.black54,
                                        child: const Icon(
                                          Icons.wifi_off,
                                          color: Colors.white70,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        video.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isPlaying
                                              ? AppTheme.deepSkyBlue
                                              : Colors.grey.shade200,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        video.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // =====================================
                    // 5. TEXT-BASED READING MODULES
                    // =====================================
                    Container(
                      margin: const EdgeInsets.only(top: 40),
                      padding: const EdgeInsets.only(top: 20, bottom: 60),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 8.0,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.menu_book,
                                  color: AppTheme.navyBlue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "OFFLINE READING MASTERCLASS",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildTrainingModule(
                            title: "The 5-Minute Evening Rule",
                            icon: Icons.nightlight_round,
                            content:
                                "Never wake up wondering what to do. Spend 5 minutes every evening writing down your top 3 tasks for the next day. Your brain will subconsciously prepare for them while you sleep, allowing you to hit the ground running.",
                          ),
                          _buildTrainingModule(
                            title: "Eat The Frog Strategy",
                            icon: Icons.pest_control,
                            content:
                                "Identify your hardest, most important task (The Frog). Do it first thing in the morning before checking emails, messages, or doing easy chores. Once the hardest thing is done, the rest of the day feels effortless.",
                          ),
                          _buildTrainingModule(
                            title: "Biological Energy Mapping",
                            icon: Icons.battery_charging_full,
                            content:
                                "Not all hours are equal. Track when you feel most alert (usually mornings) and protect that time for deep work. Save low-energy tasks like answering emails or doing laundry for the afternoon dip.",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // --- WIDGETS ---

  Widget _buildHorizontalVideoCard(
    CoachingVideo video,
    bool isPlaying,
    bool isOffline,
  ) {
    return GestureDetector(
      onTap: isOffline ? null : () => _playSelectedVideo(video),
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isPlaying
              ? Border.all(color: AppTheme.deepSkyBlue, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    video.thumbnailUrl,
                    height: 100,
                    width: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      height: 100,
                      width: 140,
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.image, color: Colors.white24),
                    ),
                  ),
                  if (isPlaying && !isOffline)
                    Container(
                      color: Colors.black45,
                      height: 100,
                      width: 140,
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  if (isOffline)
                    Container(
                      color: Colors.black54,
                      height: 100,
                      width: 140,
                      child: const Center(
                        child: Icon(
                          Icons.wifi_off,
                          color: Colors.white70,
                          size: 30,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              video.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isPlaying ? AppTheme.deepSkyBlue : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineVideoPlaceholder() {
    return Container(
      width: double.infinity,
      height: 220, // Standard 16:9 YouTube height approximation
      color: Colors.grey.shade900,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.grey.shade600, size: 48),
          const SizedBox(height: 16),
          const Text(
            "Offline Mode Active",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Scroll down to read the Offline Masterclass.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingModule({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.lightBlue.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.navyBlue),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Text(
              content,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.5,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
