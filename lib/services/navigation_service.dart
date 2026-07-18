import 'package:flutter/material.dart';

/// Clé de navigation globale — permet de router depuis un contexte sans
/// BuildContext (ex : au tap sur une notification push).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
