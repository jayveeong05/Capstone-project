import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingPage extends StatefulWidget {
  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  bool onLastPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _controller,
              onPageChanged: (index) {
                setState(() {
                  onLastPage = index == 3;
                });
              },
              children: [
                buildPage(
                  image: 'lib/assets/images/OnboardPagePic1.png',
                  title: "Welcome to NextGen Fitness 💪",
                  subtitle: "Your personalized fitness and diet companion — tailored to your goals, lifestyle, and progress."
                ),
                buildPage(
                  image: 'lib/assets/images/OnboardPagePic2.png',
                  title: "Fitness That Fits You",
                  subtitle: "Customized workout and diet plans based on your health data and preferences."
                ),
                buildPage(
                  image: 'lib/assets/images/OnboardPagePic3.png',
                  title: "Track Meals & Workouts Effortlessly",
                  subtitle: "Use voice and image scanning to log your progress."
                ),
                buildPage(
                  image: 'lib/assets/images/OnboardPagePic4.png',
                  title: "Stay Motivated with Music & Videos",
                  subtitle: "Workout with guidance and energizing playlists."
                ),
              ],
            ),

            // Skip button
            Positioned(
              right: 20,
              top: 20,
              child: TextButton(
                onPressed: () => navigateToHome(context),
                child: Text("Skip", style: TextStyle(color: Colors.black)),
              ),
            ),

            // Dot indicators
            Positioned(
              bottom: 150,
              left: 0,
              right: 0,
              child: Center(
                child: SmoothPageIndicator(
                  controller: _controller,
                  count: 4,
                  effect: WormEffect(
                    dotColor: Colors.grey,
                    activeDotColor: Colors.blueAccent,
                  ),
                ),
              ),
            ),

            // Next or Done button
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        minimumSize: Size.fromHeight(50),
                      ),
                      onPressed: () {
                        if (onLastPage) {
                          navigateToHome(context);
                        } else {
                          _controller.nextPage(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        }
                      },
                      child: Text(
                        onLastPage ? "Let’s Get Started" : "Next",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Text(
                        "I’ve already have an account",
                        style: TextStyle(color: Colors.blueAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPage({required String image, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(image, height: 300),
          SizedBox(height: 30),
          Text(title,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
              textAlign: TextAlign.center),
          SizedBox(height: 20),
          Text(subtitle,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void navigateToHome(BuildContext context) {
    Navigator.pushNamed(context, '/signup'); // Change route as needed
  }
}
