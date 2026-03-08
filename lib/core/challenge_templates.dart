import 'package:flutter/material.dart';

import '../models/challenge.dart';
import 'challenge_categories.dart';

/// Plantilla predefinida para crear un reto rápidamente.
class ChallengeTemplate {
  const ChallengeTemplate({
    required this.name,
    required this.objective,
    required this.type,
    required this.target,
    required this.category,
    required this.icon,
    this.unit,
    this.unitAmount,
    this.frequency,
  });

  final String name;
  final String objective;
  final ChallengeType type;
  final num target;
  final ChallengeCategory category;
  final IconData icon;
  final String? unit;
  final num? unitAmount;
  final ChallengeFrequency? frequency;
}

/// Lista de plantillas populares.
const List<ChallengeTemplate> challengeTemplates = [
  ChallengeTemplate(
    name: '30 días de ejercicio',
    objective: 'Moverme al menos 30 minutos cada día durante un mes.',
    type: ChallengeType.streak,
    target: 30,
    category: ChallengeCategory.actividadFisica,
    icon: Icons.fitness_center,
  ),
  ChallengeTemplate(
    name: 'Leer 20 páginas diarias',
    objective: 'Crear el hábito de leer todos los días.',
    type: ChallengeType.countUnits,
    target: 20,
    unit: 'páginas',
    unitAmount: 20,
    frequency: ChallengeFrequency.daily,
    category: ChallengeCategory.saludMental,
    icon: Icons.menu_book,
  ),
  ChallengeTemplate(
    name: 'Tomar 2 litros de agua',
    objective: 'Mantenerme hidratado cada día.',
    type: ChallengeType.countUnits,
    target: 2,
    unit: 'litros',
    unitAmount: 2,
    frequency: ChallengeFrequency.daily,
    category: ChallengeCategory.alimentacion,
    icon: Icons.water_drop,
  ),
  ChallengeTemplate(
    name: 'Meditar 10 minutos',
    objective: 'Reducir el estrés con meditación diaria.',
    type: ChallengeType.streak,
    target: 21,
    category: ChallengeCategory.espiritual,
    icon: Icons.self_improvement,
  ),
  ChallengeTemplate(
    name: 'Correr 5 km',
    objective: 'Correr 5 kilómetros sin parar.',
    type: ChallengeType.countUnits,
    target: 5,
    unit: 'km',
    unitAmount: 5,
    frequency: ChallengeFrequency.daily,
    category: ChallengeCategory.actividadFisica,
    icon: Icons.directions_run,
  ),
  ChallengeTemplate(
    name: 'Dormir 8 horas',
    objective: 'Mejorar mi descanso durmiendo lo necesario cada noche.',
    type: ChallengeType.streak,
    target: 14,
    category: ChallengeCategory.saludMental,
    icon: Icons.bedtime,
  ),
  ChallengeTemplate(
    name: 'Sin azúcar añadida',
    objective: 'Eliminar el azúcar añadida de mi dieta.',
    type: ChallengeType.streak,
    target: 30,
    category: ChallengeCategory.alimentacion,
    icon: Icons.restaurant,
  ),
  ChallengeTemplate(
    name: 'Aprender algo nuevo',
    objective: 'Dedicar tiempo cada día a aprender una habilidad.',
    type: ChallengeType.streak,
    target: 30,
    category: ChallengeCategory.saludMental,
    icon: Icons.lightbulb_outline,
  ),
  ChallengeTemplate(
    name: 'Llamar a un amigo',
    objective: 'Fortalecer mis relaciones llamando a alguien cada semana.',
    type: ChallengeType.countTimes,
    target: 4,
    frequency: ChallengeFrequency.monthly,
    category: ChallengeCategory.social,
    icon: Icons.people,
  ),
  ChallengeTemplate(
    name: 'Dibujar o pintar',
    objective: 'Expresarme creativamente con algún arte visual.',
    type: ChallengeType.countTimes,
    target: 3,
    frequency: ChallengeFrequency.weekly,
    category: ChallengeCategory.espiritual,
    icon: Icons.palette,
  ),
  ChallengeTemplate(
    name: 'Andar en bicicleta',
    objective: 'Usar la bici como medio de transporte o ejercicio.',
    type: ChallengeType.countUnits,
    target: 10,
    unit: 'km',
    unitAmount: 10,
    frequency: ChallengeFrequency.weekly,
    category: ChallengeCategory.actividadFisica,
    icon: Icons.directions_bike,
  ),
  ChallengeTemplate(
    name: 'Practicar un idioma',
    objective: 'Estudiar un idioma extranjero cada día.',
    type: ChallengeType.streak,
    target: 30,
    category: ChallengeCategory.saludMental,
    icon: Icons.language,
  ),
];
