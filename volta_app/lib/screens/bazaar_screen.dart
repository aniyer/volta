import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/cyber_vibrant_theme.dart';
import '../services/auth_service.dart';
import '../services/pocketbase_service.dart';
import '../utils/icon_mapper.dart';

/// Reward shop (Bazaar) screen
class BazaarScreen extends StatefulWidget {
  const BazaarScreen({super.key});

  @override
  State<BazaarScreen> createState() => _BazaarScreenState();
}

class _BazaarScreenState extends State<BazaarScreen> {
  List<BazaarItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBazaarItems();
  }

  Future<void> _loadBazaarItems() async {
    final pb = context.read<PocketBaseService>();
    
    try {
      final result = await pb.client.collection('bazaar').getList(
        sort: 'cost',
      );
      
      if (mounted) {
        setState(() {
          _items = result.items.map((r) => BazaarItem(
            id: r.id,
            name: r.getStringValue('item_name'),
            description: r.getStringValue('description'),
            icon: r.getStringValue('icon'),
            cost: r.getIntValue('cost'),
            stock: r.getIntValue('stock'),
          )).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading bazaar: $e');
      if (mounted) {
        setState(() {
          _items = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _claimItem(BazaarItem item) async {
    final auth = context.read<AuthService>();
    
    if (auth.points < item.cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough Volts! Keep spinning! ⚡'),
          backgroundColor: CyberVibrantTheme.magmaOrange,
        ),
      );
      return;
    }
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberVibrantTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Claim Reward?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (item.description.isNotEmpty)
              Text(
                item.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: CyberVibrantTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
            Text(
              'This will discharge ${item.cost} Volts',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CLAIM'),
          ),
        ],
      ),
    );
    

    
    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        final pb = context.read<PocketBaseService>();
        
        // 1. Refresh user to get latest points
        await auth.refreshUser();
        
        if (auth.points < item.cost) {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Not enough Volts! Someone spent them? ⚡'),
                backgroundColor: CyberVibrantTheme.magmaOrange,
              ),
            );
            setState(() => _isLoading = false);
          }
          return;
        }

        // 2. Deduct points and claim item
        await pb.client.collection('users').update(
          auth.user!.id,
          body: {'points': auth.points - item.cost},
        );
        
        // 3. Update bazaar item claimed_by
        await pb.client.collection('bazaar').update(
          item.id,
          body: {
            'stock': item.stock - 1,
            'claimed_by+': [auth.user!.id],
          },
        );
        
        // 4. Final refresh
        await auth.refreshUser();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} claimed! Volts Discharged! ⚡'),
              backgroundColor: CyberVibrantTheme.electricTeal,
            ),
          );
          _loadBazaarItems();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to claim: $e'),
              backgroundColor: CyberVibrantTheme.magmaOrange,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('BAZAAR'),
        actions: [
          // Volts display
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: CyberVibrantTheme.successGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${auth.points}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final canAfford = auth.points >= item.cost;
                final inStock = item.stock > 0;
                
                return GestureDetector(
                  onTap: inStock ? () => _claimItem(item) : null,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          CyberVibrantTheme.darkCard,
                          // Tint with a unique color based on index
                          Color.lerp(
                            CyberVibrantTheme.darkCard,
                            [
                              CyberVibrantTheme.neonViolet,
                              CyberVibrantTheme.electricTeal,
                              Colors.pink,
                              Colors.orange,
                              Colors.blue,
                            ][index % 5],
                            0.15,
                          )!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: canAfford && inStock
                            ? [
                                CyberVibrantTheme.neonViolet,
                                CyberVibrantTheme.electricTeal,
                                Colors.pink,
                                Colors.orange,
                                Colors.blue,
                              ][index % 5]
                            : CyberVibrantTheme.withAlpha(Colors.grey, 0.1),
                        width: 2,
                      ),
                      boxShadow: canAfford && inStock
                          ? [
                              BoxShadow(
                                color: [
                                  CyberVibrantTheme.neonViolet,
                                  CyberVibrantTheme.electricTeal,
                                  Colors.pink,
                                  Colors.orange,
                                  Colors.blue,
                                ][index % 5].withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: inStock
                                  ? CyberVibrantTheme.primaryGradient
                                  : LinearGradient(
                                      colors: [
                                        CyberVibrantTheme.textMuted,
                                        CyberVibrantTheme.withAlpha(CyberVibrantTheme.textMuted, 0.7),
                                      ],
                                    ),
                            ),
                            child: Icon(
                              IconMapper.getIcon(item.icon),
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Name
                          Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: inStock 
                                  ? CyberVibrantTheme.textPrimary 
                                  : CyberVibrantTheme.textMuted,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: inStock 
                                    ? Colors.white70
                                    : CyberVibrantTheme.textMuted,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          
                          const SizedBox(height: 8),
                          
                          // Cost
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: canAfford && inStock
                                  ? CyberVibrantTheme.withAlpha(CyberVibrantTheme.electricTeal, 0.2)
                                  : CyberVibrantTheme.darkSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt,
                                  size: 16,
                                  color: canAfford && inStock
                                      ? CyberVibrantTheme.electricTeal
                                      : CyberVibrantTheme.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${item.cost}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: canAfford && inStock
                                        ? CyberVibrantTheme.electricTeal
                                        : CyberVibrantTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const Spacer(),
                          
                          // Stock
                          Text(
                            inStock ? '${item.stock} left' : 'Out of stock',
                            style: TextStyle(
                              fontSize: 12,
                              color: inStock
                                  ? CyberVibrantTheme.textSecondary
                                  : CyberVibrantTheme.magmaOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: (index * 100).ms).scale(
                  begin: const Offset(0.9, 0.9),
                  duration: 200.ms,
                );
              },
            ),
    );
  }


}

/// Simple bazaar item model
class BazaarItem {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int cost;
  final int stock;

  const BazaarItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.cost,
    required this.stock,
  });
}
