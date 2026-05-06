import '../models/session_model.dart';

abstract class ScheduleRemoteDataSource {
  Future<List<SessionModel>> getSessionsByDate(DateTime date);
}

class ScheduleRemoteDataSourceImpl implements ScheduleRemoteDataSource {
  @override
  Future<List<SessionModel>> getSessionsByDate(DateTime date) async {
    // Mock data for Oct 10, 2024 as seen in the design
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      const SessionModel(
        id: '1',
        time: '09:00',
        title: 'Vinyl Archive Curation',
        description: 'Reviewing the new 1970s jazz acquisitions for the "Midnight Blue" playlist collection.',
        tag: 'EDITORIAL',
        participants: ['Sarah Jenkins'],
      ),
      const SessionModel(
        id: '2',
        time: '14:30',
        title: 'The Digital Pulse #42',
        description: 'Monthly community live stream focusing on upcoming electronic music releases and gear reviews.',
        tag: 'LIVE STREAM',
        isLive: true,
      ),
      const SessionModel(
        id: '3',
        time: '18:00',
        title: 'Album Deep-Dive',
        description: 'Analysis of "Echoes of Silence"',
        tag: 'REVIEW',
      ),
    ];
  }
}
