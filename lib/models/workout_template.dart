class TemplateItem {
  final String name;
  final int sets;
  final int reps;

  const TemplateItem({required this.name, this.sets = 3, this.reps = 8});

  TemplateItem copyWith({String? name, int? sets, int? reps}) => TemplateItem(
        name: name ?? this.name,
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
      );

  Map<String, dynamic> toMap() => {'name': name, 'sets': sets, 'reps': reps};

  factory TemplateItem.fromMap(Map map) => TemplateItem(
        name: map['name'] as String,
        sets: (map['sets'] as num?)?.toInt() ?? 3,
        reps: (map['reps'] as num?)?.toInt() ?? 8,
      );
}

class WorkoutTemplate {
  final String id;
  final String name;
  final List<TemplateItem> items;
  final DateTime createdAt;

  const WorkoutTemplate({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'items': items.map((i) => i.toMap()).toList(),
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory WorkoutTemplate.fromMap(Map map) => WorkoutTemplate(
        id: map['id'] as String,
        name: map['name'] as String,
        items: ((map['items'] as List?) ?? const [])
            .map((i) => TemplateItem.fromMap(i as Map))
            .toList(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['createdAt'] as num?)?.toInt() ?? 0,
        ),
      );
}
