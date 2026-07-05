import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/parcel_model.dart';

class ParcelCard extends StatelessWidget {
  final ParcelModel parcel;
  final VoidCallback? onTap;
  final VoidCallback? onViewDetails;

  const ParcelCard({
    super.key,
    required this.parcel,
    this.onTap,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildParcelIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parcel.ownerDisplay,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      Icons.pin_drop_outlined,
                      parcel.displayName,
                    ),
                    if (parcel.areaSquareMeters != null)
                      _buildInfoRow(
                        Icons.straighten,
                        parcel.areaDisplay,
                      ),
                    if (parcel.community != null)
                      _buildInfoRow(
                        Icons.location_city_outlined,
                        parcel.community!,
                      ),
                  ],
                ),
              ),
              if (onViewDetails != null)
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onPressed: onViewDetails,
                  color: AppTheme.primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParcelIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.map_rounded,
        color: AppTheme.primaryColor,
        size: 24,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
