enum LearningMilestone { firstStory, firstTopicPractice, firstMasteredWord }

typedef PracticeMilestoneResult = ({
  bool successful,
  List<LearningMilestone> milestones,
});
