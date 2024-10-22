class Model {
  final String jobId;
  final String approveName;

  Model({required this.jobId, required this.approveName});

  factory Model.fromJson(Map<String, dynamic> json) {
    return Model(
      jobId: json['job_id'],
      approveName: json['approve_name'],
    );
  }
}
