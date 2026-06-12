// EXP milestones: key = level, value = total accumulated EXP required
const Map<int, int> kLevelMilestones = {
  1: 0,
  10: 1000,
  20: 5000,
  30: 10000,
  40: 20000,
  50: 40000,
};

// Evolution thresholds (level)
const kEvolutionLevels = [10, 20, 30, 40];

// Skin unlock level
const kSkinUnlockLevel = 50;

// Base reward per km
const double kExpPerKm = 100.0;
const double kCoinsPerKm = 100.0;

// EXP bonus multipliers
const double kMorningBonus = 1.1;  // 05:00-08:00
const double kNightBonus = 1.1;    // 20:00-24:00
const double kFiveKmBonus = 1.2;
const double kTenKmBonus = 1.5;

// Run validity constraints
const double kMinRunDistanceKm = 0.5;
const int kMinRunDurationSeconds = 3 * 60;
const double kMaxSpeedKmh = 25.0;
