// Daily mission template definitions.
// Each day, 3 are chosen at random from this pool.
const List<Map<String, dynamic>> kMissionTemplates = [
  {
    'id': 'run_1km',
    'title': '1km走る',
    'condition': {'type': 'distance', 'value': 1.0},
    'rewardCoins': 50,
  },
  {
    'id': 'run_3km',
    'title': '3km走る',
    'condition': {'type': 'distance', 'value': 3.0},
    'rewardCoins': 100,
  },
  {
    'id': 'run_5km',
    'title': '5km走る',
    'condition': {'type': 'distance', 'value': 5.0},
    'rewardCoins': 150,
  },
  {
    'id': 'run_10km',
    'title': '10km走る',
    'condition': {'type': 'distance', 'value': 10.0},
    'rewardCoins': 300,
  },
  {
    'id': 'run_morning',
    'title': '朝ラン（6〜9時）',
    'condition': {'type': 'time_of_day', 'start_hour': 6, 'end_hour': 9},
    'rewardCoins': 80,
  },
  {
    'id': 'run_night',
    'title': '夜ラン（20〜24時）',
    'condition': {'type': 'time_of_day', 'start_hour': 20, 'end_hour': 24},
    'rewardCoins': 80,
  },
  {
    'id': 'earn_100exp',
    'title': '100 EXP以上獲得',
    'condition': {'type': 'exp_single', 'value': 100},
    'rewardCoins': 100,
  },
  {
    'id': 'earn_500exp',
    'title': '500 EXP以上獲得',
    'condition': {'type': 'exp_single', 'value': 500},
    'rewardCoins': 200,
  },
  {
    'id': 'run_under_6pace',
    'title': '6分/km以下のペースで走る',
    'condition': {'type': 'pace', 'max_pace': 6.0},
    'rewardCoins': 100,
  },
  {
    'id': 'run_under_5pace',
    'title': '5分/km以下のペースで走る',
    'condition': {'type': 'pace', 'max_pace': 5.0},
    'rewardCoins': 200,
  },
  {
    'id': 'run_30min',
    'title': '30分以上走る',
    'condition': {'type': 'duration', 'seconds': 1800},
    'rewardCoins': 100,
  },
  {
    'id': 'run_1hour',
    'title': '1時間以上走る',
    'condition': {'type': 'duration', 'seconds': 3600},
    'rewardCoins': 300,
  },
  {
    'id': 'daily_login',
    'title': '今日ログイン',
    'condition': {'type': 'login'},
    'rewardCoins': 30,
  },
  {
    'id': 'collect_coins_200',
    'title': 'コイン200以上獲得',
    'condition': {'type': 'coins_single', 'value': 200},
    'rewardCoins': 100,
  },
  {
    'id': 'run_twice',
    'title': '今日2回走る',
    'condition': {'type': 'run_count', 'value': 2},
    'rewardCoins': 150,
  },
  {
    'id': 'run_2km_under20',
    'title': '2km以上を20分以内',
    'condition': {'type': 'distance_under_time', 'min_km': 2.0, 'max_seconds': 1200},
    'rewardCoins': 150,
  },
  {
    'id': 'run_with_morning_bonus',
    'title': '朝ボーナスを使ってランする',
    'condition': {'type': 'time_of_day', 'start_hour': 5, 'end_hour': 9},
    'rewardCoins': 100,
  },
  {
    'id': 'run_with_night_bonus',
    'title': '夜ボーナスを使ってランする',
    'condition': {'type': 'time_of_day', 'start_hour': 21, 'end_hour': 24},
    'rewardCoins': 100,
  },
  {
    'id': 'run_500m',
    'title': '500m走る',
    'condition': {'type': 'distance', 'value': 0.5},
    'rewardCoins': 30,
  },
  {
    'id': 'run_any',
    'title': '1回走る',
    'condition': {'type': 'run_count', 'value': 1},
    'rewardCoins': 30,
  },
];
