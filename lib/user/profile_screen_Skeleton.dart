import 'package:flutter/material.dart';

class ProfileScreenSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileCard(),
            SizedBox(height: 20),
            EditProfileButton(),
            SizedBox(height: 20),
            TabBarSkeleton(),
            SizedBox(height: 20),
            PostsGridSkeleton(),
          ],
        ),
      ),
    );
  }
}

// Profile Card Widget
class ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      elevation: 10,
      margin: EdgeInsets.all(20),
      color: Colors.white,
      shadowColor: const Color.fromARGB(44, 171, 171, 171),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture Placeholder
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name Placeholder
                Container(
                  width: 150,
                  height: 20,
                  color: Colors.grey[300],
                ),
                SizedBox(height: 8),
                // Bio Placeholder
                Container(
                  width: 150,
                  height: 15,
                  color: Colors.grey[300],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    // Followers Count Placeholder
                    Column(
                      children: [
                        Container(
                          width: 60,
                          height: 12,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: 40,
                          height: 15,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                    SizedBox(width: 16),
                    // Following Count Placeholder
                    Column(
                      children: [
                        Container(
                          width: 60,
                          height: 12,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: 40,
                          height: 15,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Edit Profile Button Widget
class EditProfileButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// Tab Bar Skeleton Widget
class TabBarSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: TabBar(
        controller: null, // Null since TabController is not needed for skeleton
        labelColor: Colors.black,
        indicatorColor: Colors.black,
        tabs: [
          Tab(
            child: Container(
              height: 20,
              width: 80,
              color: Colors.grey[300],
            ),
          ),
          Tab(
            child: Container(
              height: 20,
              width: 80,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }
}

// Grid View Skeleton for Posts Widget
class PostsGridSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: MediaQuery.of(context).size.height * 0.45,
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 6, // Placeholder for 6 items
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
            ),
          );
        },
      ),
    );
  }
}
