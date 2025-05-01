import 'package:flutter/material.dart';
import 'package:ludicapp/core/enums/activity_type.dart';
import 'package:ludicapp/models/user_activity.dart';
import 'package:ludicapp/features/profile/presentation/widgets/activity_item_card.dart';
import 'package:ludicapp/features/profile/presentation/user_activities_page.dart';

class UserActivitiesSection extends StatelessWidget {
  final String username;
  final String? userId;
  final bool isCurrentUser;
  final int maxVisibleActivities;
  
  // Mock activities for now
  final List<UserActivity> activities;
  
  const UserActivitiesSection({
    Key? key,
    required this.username,
    this.userId,
    required this.isCurrentUser,
    this.maxVisibleActivities = 10,
    required this.activities,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'Recent Activity',
          onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserActivitiesPage(
                  userId: isCurrentUser ? null : userId,
                  username: username,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        
        _buildActivitiesContent(context),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 16),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See All',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivitiesContent(BuildContext context) {
    // If activities are empty
    if (activities.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            isCurrentUser
                ? 'You don\'t have any recent activity yet.'
                : '$username doesn\'t have any recent activity yet.',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Show horizontally scrollable activities
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: activities.length > maxVisibleActivities 
            ? maxVisibleActivities 
            : activities.length,
        itemBuilder: (context, index) {
          final activity = activities[index];
          return ActivityItemCard(activity: activity);
        },
      ),
    );
  }
} 