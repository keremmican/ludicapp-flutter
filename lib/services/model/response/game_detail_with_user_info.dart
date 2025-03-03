import 'package:ludicapp/services/model/response/game_summary.dart';
import 'package:ludicapp/services/model/response/user_game_actions.dart';
import 'package:ludicapp/core/models/game.dart';

class GameDetailWithUserInfo {
  final GameSummary gameDetails;
  final UserGameActions? userActions;

  const GameDetailWithUserInfo({
    required this.gameDetails,
    this.userActions,
  });

  factory GameDetailWithUserInfo.fromJson(Map<String, dynamic> json) {
    final gameDetails = GameSummary.fromJson(json['gameDetails'] as Map<String, dynamic>);
    final userActions = json['userActions'] != null
        ? UserGameActions.fromJson(json['userActions'] as Map<String, dynamic>)
        : null;
    return GameDetailWithUserInfo(
      gameDetails: gameDetails,
      userActions: userActions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gameDetails': gameDetails.toJson(),
      'userActions': userActions?.toJson(),
    };
  }

  Game toGame() {
    final game = Game.fromGameSummary(gameDetails);
    return Game(
      gameId: game.gameId,
      name: game.name,
      slug: game.slug,
      coverUrl: game.coverUrl,
      totalRating: game.totalRating,
      totalRatingCount: game.totalRatingCount,
      releaseDate: game.releaseDate,
      genres: game.genres,
      themes: game.themes,
      platforms: game.platforms,
      companies: game.companies,
      screenshots: game.screenshots,
      summary: game.summary,
      gameVideos: game.gameVideos,
      websites: game.websites,
      releaseFullDate: game.releaseFullDate,
      gameTimeToBeats: game.gameTimeToBeats,
      pegiAgeRating: game.pegiAgeRating,
      franchises: game.franchises,
      gameModes: game.gameModes,
      playerPerspectives: game.playerPerspectives,
      languageSupports: game.languageSupports,
      userActions: userActions, // Set the userActions from the response
    );
  }
}