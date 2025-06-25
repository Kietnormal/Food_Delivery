// models/order_model.dart
import 'order_item_model.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  delivering,
  completed,
  cancelled
}

extension OrderStatusExtension on OrderStatus {
  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.delivering:
        return 'delivering';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Chờ xác nhận';
      case OrderStatus.confirmed:
        return 'Đã xác nhận';
      case OrderStatus.preparing:
        return 'Đang chuẩn bị';
      case OrderStatus.delivering:
        return 'Đang giao hàng';
      case OrderStatus.completed:
        return 'Hoàn thành';
      case OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }

  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'delivering':
        return OrderStatus.delivering;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final int subtotal;
  final int deliveryFee;
  final int total;
  final OrderStatus status;
  final String deliveryAddress;
  final String phone;
  final String createdAt;
  final String updatedAt;
  final String? notes; // Ghi chú thêm nếu có

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    required this.deliveryAddress,
    required this.phone,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  factory Order.fromJson(String orderId, Map<String, dynamic> json) {
    List<OrderItem> orderItems = [];

    if (json['items'] != null) {
      if (json['items'] is List) {
        // Xử lý dạng List
        final itemsList = json['items'] as List;
        for (var item in itemsList) {
          if (item != null && item is Map) {
            orderItems.add(OrderItem.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      } else if (json['items'] is Map) {
        // Xử lý dạng Map (trong trường hợp có)
        final itemsMap = json['items'] as Map;
        for (var entry in itemsMap.entries) {
          if (entry.value != null && entry.value is Map) {
            orderItems.add(OrderItem.fromJson(Map<String, dynamic>.from(entry.value)));
          }
        }
      }
    }

    return Order(
      id: orderId,
      userId: json['userId']?.toString() ?? '',
      items: orderItems,
      subtotal: json['subtotal'] is int ? json['subtotal'] : 0,
      deliveryFee: json['deliveryFee'] is int ? json['deliveryFee'] : 0,
      total: json['total'] is int ? json['total'] : 0,
      status: OrderStatusExtension.fromString(json['status']?.toString() ?? 'pending'),
      deliveryAddress: json['deliveryAddress']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'total': total,
      'status': status.value,
      'deliveryAddress': deliveryAddress,
      'phone': phone,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (notes != null) 'notes': notes,
    };
  }

  Order copyWith({
    String? id,
    String? userId,
    List<OrderItem>? items,
    int? subtotal,
    int? deliveryFee,
    int? total,
    OrderStatus? status,
    String? deliveryAddress,
    String? phone,
    String? createdAt,
    String? updatedAt,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  // Helper methods
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  bool get isActive => status != OrderStatus.completed && status != OrderStatus.cancelled;

  bool get canCancel => status == OrderStatus.pending || status == OrderStatus.confirmed;

  @override
  String toString() {
    return 'Order(id: $id, userId: $userId, total: $total, status: ${status.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}