import 'package:flutter/material.dart';

class StarRating extends StatefulWidget {
  final double initialRating;
  final bool interactive;
  final ValueChanged<double>? onRated;
  final double size;

  const StarRating({
    super.key,
    this.initialRating = 0,
    this.interactive = false,
    this.onRated,
    this.size = 24,
  });

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < _rating.floor();
        final half = !filled && (index < _rating);
        return GestureDetector(
          onTap: widget.interactive
              ? () {
                  setState(() => _rating = index + 1.0);
                  widget.onRated?.call(_rating);
                }
              : null,
          child: Icon(
            filled
                ? Icons.star_rounded
                : half
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
            color: const Color(0xFFFFB300),
            size: widget.size,
          ),
        );
      }),
    );
  }
}

// Display-only rating row with count
class RatingDisplay extends StatelessWidget {
  final double rating;
  final int count;
  final double size;

  const RatingDisplay({
    super.key,
    required this.rating,
    required this.count,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StarRating(initialRating: rating, size: size),
        const SizedBox(width: 6),
        Text(
          '$rating ($count)',
          style: TextStyle(color: Colors.white60, fontSize: size - 2),
        ),
      ],
    );
  }
}
