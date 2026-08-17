import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../models/cotizacion.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'leo_confecciones.db');
    return await openDatabase(
      path,
      version: 8, // 👈 CAMBIADO a 8 para que ejecute onUpgrade
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ============================================================
  // CREACIÓN DE TABLAS
  // ============================================================
  Future<void> _onCreate(Database db, int version) async {
    // ===== 1. COTIZACIONES (con telaColor) =====
    await db.execute('''
      CREATE TABLE cotizaciones(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente TEXT NOT NULL,
        tela TEXT NOT NULL,
        telaColor TEXT DEFAULT '',     -- 👈 NUEVO: color de la tela
        ancho REAL NOT NULL,
        alto REAL NOT NULL,
        factorTela REAL NOT NULL,
        precioTela REAL NOT NULL,
        precioBase REAL NOT NULL,
        totalAccesorios REAL NOT NULL,
        precioFinal REAL NOT NULL,
        accesorios TEXT NOT NULL,
        estado TEXT NOT NULL,
        fecha TEXT NOT NULL
      )
    ''');

    // ===== 2. CLIENTES =====
    await db.execute('''
      CREATE TABLE clientes(
        id_cliente INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        telefono TEXT,
        direccion TEXT,
        fecha_registro TEXT NOT NULL,
        estado TEXT DEFAULT 'activo'
      )
    ''');

    // ===== 3. USUARIOS =====
    await db.execute('''
      CREATE TABLE usuarios(
        id_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        rol TEXT DEFAULT 'vendedor'
      )
    ''');

    // ===== 4. INSUMOS =====
    await db.execute('''
      CREATE TABLE insumos(
        id_insumo INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        color TEXT DEFAULT '',
        unidad_medida TEXT NOT NULL,
        stock_minimo REAL NOT NULL,
        precio REAL DEFAULT 0,
        tipo TEXT DEFAULT 'tela'
      )
    ''');

    // ===== 5. STOCK =====
    await db.execute('''
      CREATE TABLE stock(
        id_stock INTEGER PRIMARY KEY AUTOINCREMENT,
        id_insumo INTEGER NOT NULL,
        cantidad_disponible REAL NOT NULL,
        FOREIGN KEY (id_insumo) REFERENCES insumos(id_insumo) ON DELETE CASCADE
      )
    ''');

    // ===== 6. PRODUCTOS =====
    await db.execute('''
      CREATE TABLE productos(
        id_producto INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        precio_base REAL NOT NULL,
        estado TEXT DEFAULT 'en_produccion',
        id_cotizacion INTEGER,
        fecha_creacion TEXT NOT NULL,
        FOREIGN KEY (id_cotizacion) REFERENCES cotizaciones(id) ON DELETE SET NULL
      )
    ''');

    // ===== 7. PRODUCTO_INSUMO =====
    await db.execute('''
      CREATE TABLE producto_insumo(
        id_producto INTEGER NOT NULL,
        id_insumo INTEGER NOT NULL,
        cantidad_requerida REAL NOT NULL,
        PRIMARY KEY (id_producto, id_insumo),
        FOREIGN KEY (id_producto) REFERENCES productos(id_producto) ON DELETE CASCADE,
        FOREIGN KEY (id_insumo) REFERENCES insumos(id_insumo)
      )
    ''');

    // ===== 8. VENTAS =====
    await db.execute('''
      CREATE TABLE ventas(
        id_venta INTEGER PRIMARY KEY AUTOINCREMENT,
        id_cliente INTEGER NOT NULL,
        id_usuario INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        total REAL NOT NULL,
        estado TEXT DEFAULT 'completada',
        FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
        FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
      )
    ''');

    // ===== 9. DETALLE_VENTA =====
    await db.execute('''
      CREATE TABLE detalle_venta(
        id_detalle INTEGER PRIMARY KEY AUTOINCREMENT,
        id_venta INTEGER NOT NULL,
        id_producto INTEGER NOT NULL,
        cantidad INTEGER NOT NULL,
        precio_unitario REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (id_venta) REFERENCES ventas(id_venta) ON DELETE CASCADE,
        FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
      )
    ''');

    // ===== 10. MOVIMIENTOS_STOCK =====
    await db.execute('''
      CREATE TABLE movimientos_stock(
        id_movimiento INTEGER PRIMARY KEY AUTOINCREMENT,
        id_insumo INTEGER NOT NULL,
        id_usuario INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        cantidad REAL NOT NULL,
        fecha_hora TEXT NOT NULL,
        referencia TEXT,
        responsable TEXT,
        FOREIGN KEY (id_insumo) REFERENCES insumos(id_insumo),
        FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
      )
    ''');

    // ===== 11. CONFIGURACION =====
    await db.execute('''
      CREATE TABLE configuracion(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_taller TEXT NOT NULL,
        telefono TEXT,
        email TEXT,
        direccion TEXT,
        mano_obra_por_metro REAL DEFAULT 12.0,
        factor_tela_defecto REAL DEFAULT 3.0,
        iva REAL DEFAULT 0.0
      )
    ''');

    // ===== DATOS INICIALES =====
    await db.execute('''
      INSERT INTO usuarios (nombre, email, password, rol) VALUES
      ('Administrador', 'admin@leo.com', '1234', 'admin')
    ''');

    await db.execute('''
      INSERT INTO configuracion (nombre_taller, telefono, email, direccion, mano_obra_por_metro, factor_tela_defecto) VALUES
      ('LEO CONFECCIONES', '78945612', 'leo@confecciones.com', 'Calle Principal N°123', 12.0, 3.0)
    ''');

    // ===== DATOS INICIALES DE INSUMOS =====
    await db.execute('''
      INSERT INTO insumos (nombre, color, unidad_medida, stock_minimo, precio, tipo) VALUES
      ('Tela gruesa', '', 'metros', 10, 45.0, 'tela'),
      ('Lino sin diseño', '', 'metros', 10, 30.0, 'tela'),
      ('Lino con diseño', '', 'metros', 10, 35.0, 'tela'),
      ('Lino bordado', '', 'metros', 10, 40.0, 'tela'),
      ('Gasa lisa', '', 'metros', 10, 20.0, 'tela'),
      ('Gasa nevada', '', 'metros', 10, 24.0, 'tela'),
      ('Gasa bordada', '', 'metros', 10, 45.0, 'tela'),
      ('Riel vacía', '', 'metros', 5, 11.0, 'accesorio'),
      ('Crusetas', '', 'pares', 5, 7.0, 'accesorio'),
      ('Poleas', '', 'pares', 5, 7.0, 'accesorio'),
      ('Finales', '', 'unidades', 5, 2.0, 'accesorio'),
      ('Pita', '', 'metros', 10, 1.5, 'accesorio'),
      ('Rodajas', '', 'docenas', 5, 2.0, 'accesorio')
    ''');

    // ===== STOCK INICIAL =====
    await db.execute('''
      INSERT INTO stock (id_insumo, cantidad_disponible) VALUES
      (1, 50),
      (2, 30),
      (3, 25),
      (4, 20),
      (5, 40),
      (6, 30),
      (7, 15),
      (8, 20),
      (9, 15),
      (10, 15),
      (11, 30),
      (12, 100),
      (13, 10)
    ''');

    await db.execute('''
      INSERT INTO clientes (nombre, telefono, direccion, fecha_registro) VALUES
      ('Juan Pérez', '78945612', 'Calle 1 N°123', '2024-01-15'),
      ('María Gómez', '74185296', 'Av. Principal N°456', '2024-01-20'),
      ('Carlos López', '96385274', 'Calle 2 N°789', '2024-02-01')
    ''');
  }

  // ============================================================
  // ACTUALIZACIÓN DE BD (onUpgrade)
  // ============================================================
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // ===== ACTUALIZACIÓN DE VERSIÓN 7 A 8 =====
    if (oldVersion < 8) {
      // 👈 NUEVO: Agregar campo telaColor a cotizaciones
      try {
        // Verificar si la columna ya existe
        final columns = await db.rawQuery('PRAGMA table_info(cotizaciones)');
        final hasTelaColor = columns.any((col) => col['name'] == 'telaColor');
        
        if (!hasTelaColor) {
          await db.execute('ALTER TABLE cotizaciones ADD COLUMN telaColor TEXT DEFAULT ""');
        }
      } catch (e) {
        print('⚠️ Error al agregar telaColor: $e');
      }
    }

    // ===== ACTUALIZACIÓN DE VERSIÓN 6 A 7 (insumos) =====
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE insumos_temporal(
          id_insumo INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          color TEXT DEFAULT '',
          unidad_medida TEXT NOT NULL,
          stock_minimo REAL NOT NULL,
          precio REAL DEFAULT 0,
          tipo TEXT DEFAULT 'tela'
        )
      ''');

      await db.execute('''
        INSERT INTO insumos_temporal (id_insumo, nombre, unidad_medida, stock_minimo, precio, color, tipo)
        SELECT id_insumo, nombre, unidad_medida, stock_minimo, precio, '', 'tela'
        FROM insumos
      ''');

      await db.execute('DROP TABLE insumos');
      await db.execute('ALTER TABLE insumos_temporal RENAME TO insumos');

      await db.execute('''
        INSERT OR REPLACE INTO insumos (id_insumo, nombre, color, unidad_medida, stock_minimo, precio, tipo) VALUES
        (1, 'Tela gruesa', '', 'metros', 10, 45.0, 'tela'),
        (2, 'Lino sin diseño', '', 'metros', 10, 30.0, 'tela'),
        (3, 'Lino con diseño', '', 'metros', 10, 35.0, 'tela'),
        (4, 'Lino bordado', '', 'metros', 10, 40.0, 'tela'),
        (5, 'Gasa lisa', '', 'metros', 10, 20.0, 'tela'),
        (6, 'Gasa nevada', '', 'metros', 10, 24.0, 'tela'),
        (7, 'Gasa bordada', '', 'metros', 10, 45.0, 'tela'),
        (8, 'Riel vacía', '', 'metros', 5, 11.0, 'accesorio'),
        (9, 'Crusetas', '', 'pares', 5, 7.0, 'accesorio'),
        (10, 'Poleas', '', 'pares', 5, 7.0, 'accesorio'),
        (11, 'Finales', '', 'unidades', 5, 2.0, 'accesorio'),
        (12, 'Pita', '', 'metros', 10, 1.5, 'accesorio'),
        (13, 'Rodajas', '', 'docenas', 5, 2.0, 'accesorio')
      ''');
    }
  }

  // ============================================================
  // MÉTODOS PARA COTIZACIONES
  // ============================================================
  Future<int> insertCotizacion(Cotizacion cotizacion) async {
    final db = await database;
    return await db.insert('cotizaciones', cotizacion.toMap());
  }

  Future<List<Cotizacion>> getCotizaciones() async {
    final db = await database;
    final result = await db.query('cotizaciones', orderBy: 'fecha DESC');
    return result.map((map) => Cotizacion.fromMap(map)).toList();
  }

  Future<Cotizacion?> getCotizacionById(int id) async {
    final db = await database;
    final result = await db.query('cotizaciones', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) return Cotizacion.fromMap(result.first);
    return null;
  }

  Future<int> updateEstadoCotizacion(int id, String estado) async {
    final db = await database;
    return await db.update('cotizaciones', {'estado': estado}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCotizacion(int id) async {
    final db = await database;
    return await db.delete('cotizaciones', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================================
  // MÉTODOS PARA CLIENTES
  // ============================================================
  Future<int> insertCliente(Map<String, dynamic> cliente) async {
    final db = await database;
    return await db.insert('clientes', cliente);
  }

  Future<List<Map<String, dynamic>>> getClientes() async {
    final db = await database;
    return await db.query('clientes', orderBy: 'nombre ASC');
  }

  Future<Map<String, dynamic>?> getClienteById(int id) async {
    final db = await database;
    final result = await db.query('clientes', where: 'id_cliente = ?', whereArgs: [id]);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<int> updateCliente(Map<String, dynamic> cliente) async {
    final db = await database;
    return await db.update(
      'clientes',
      cliente,
      where: 'id_cliente = ?',
      whereArgs: [cliente['id_cliente']],
    );
  }

  Future<int> deleteCliente(int id) async {
    final db = await database;
    return await db.delete('clientes', where: 'id_cliente = ?', whereArgs: [id]);
  }

  // ============================================================
  // MÉTODOS PARA USUARIOS
  // ============================================================
  Future<List<Map<String, dynamic>>> getUsuarios() async {
    final db = await database;
    return await db.query('usuarios', orderBy: 'nombre ASC');
  }

  Future<Map<String, dynamic>?> getUsuarioByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<int> insertUsuario(Map<String, dynamic> usuario) async {
    final db = await database;
    return await db.insert('usuarios', usuario);
  }

  Future<int> updateUsuario(Map<String, dynamic> usuario) async {
    final db = await database;
    return await db.update(
      'usuarios',
      usuario,
      where: 'id_usuario = ?',
      whereArgs: [usuario['id_usuario']],
    );
  }

  Future<int> deleteUsuario(int id) async {
    final db = await database;
    return await db.delete(
      'usuarios',
      where: 'id_usuario = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // MÉTODOS PARA INSUMOS
  // ============================================================
  Future<List<Map<String, dynamic>>> getInsumos() async {
    final db = await database;
    return await db.query('insumos', orderBy: 'nombre ASC');
  }

  Future<List<Map<String, dynamic>>> getTelas() async {
    final db = await database;
    return await db.query(
      'insumos',
      where: 'tipo = ?',
      whereArgs: ['tela'],
      orderBy: 'nombre ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getAccesorios() async {
    final db = await database;
    return await db.query(
      'insumos',
      where: 'tipo = ?',
      whereArgs: ['accesorio'],
      orderBy: 'nombre ASC',
    );
  }

  Future<Map<String, dynamic>?> getInsumoById(int id) async {
    final db = await database;
    final result = await db.query('insumos', where: 'id_insumo = ?', whereArgs: [id]);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<int> insertInsumo(Map<String, dynamic> insumo) async {
    final db = await database;
    insumo.putIfAbsent('color', () => '');
    insumo.putIfAbsent('tipo', () => 'tela');
    return await db.insert('insumos', insumo);
  }

  Future<int> updateInsumo(Map<String, dynamic> insumo) async {
    final db = await database;
    return await db.update(
      'insumos',
      insumo,
      where: 'id_insumo = ?',
      whereArgs: [insumo['id_insumo']],
    );
  }

  Future<int> deleteInsumo(int id) async {
    final db = await database;
    await db.delete('stock', where: 'id_insumo = ?', whereArgs: [id]);
    return await db.delete('insumos', where: 'id_insumo = ?', whereArgs: [id]);
  }

  // ============================================================
  // MÉTODOS PARA STOCK
  // ============================================================
  Future<List<Map<String, dynamic>>> getStockCompleto() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT i.*, s.cantidad_disponible, s.id_stock
      FROM insumos i
      INNER JOIN stock s ON i.id_insumo = s.id_insumo
      ORDER BY i.nombre ASC
    ''');
  }

  Future<int> updateStock(int idInsumo, double nuevaCantidad) async {
    final db = await database;
    return await db.update(
      'stock',
      {'cantidad_disponible': nuevaCantidad},
      where: 'id_insumo = ?',
      whereArgs: [idInsumo],
    );
  }

  Future<double> getStockByInsumo(int idInsumo) async {
    final db = await database;
    final result = await db.query('stock', where: 'id_insumo = ?', whereArgs: [idInsumo]);
    if (result.isNotEmpty) return result.first['cantidad_disponible'] as double;
    return 0;
  }

  Future<int> insertStock(Map<String, dynamic> stock) async {
    final db = await database;
    return await db.insert('stock', stock);
  }

  // ============================================================
  // MÉTODOS PARA PRODUCTOS
  // ============================================================
  Future<int> insertProducto(Map<String, dynamic> producto) async {
    final db = await database;
    return await db.insert('productos', producto);
  }

  Future<List<Map<String, dynamic>>> getProductos() async {
    final db = await database;
    return await db.query('productos', orderBy: 'fecha_creacion DESC');
  }

  Future<List<Map<String, dynamic>>> getProductosByEstado(String estado) async {
    final db = await database;
    return await db.query(
      'productos',
      where: 'estado = ?',
      whereArgs: [estado],
      orderBy: 'fecha_creacion DESC',
    );
  }

  Future<int> updateProductoEstado(int id, String nuevoEstado) async {
    final db = await database;
    return await db.update(
      'productos',
      {'estado': nuevoEstado},
      where: 'id_producto = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteProducto(int id) async {
    final db = await database;
    return await db.delete('productos', where: 'id_producto = ?', whereArgs: [id]);
  }

  // ============================================================
  // MÉTODOS PARA PRODUCTO_INSUMO
  // ============================================================
  Future<void> insertProductoInsumos(int idProducto, List<Map<String, dynamic>> insumos) async {
    final db = await database;
    for (var insumo in insumos) {
      await db.insert('producto_insumo', {
        'id_producto': idProducto,
        'id_insumo': insumo['id_insumo'],
        'cantidad_requerida': insumo['cantidad'],
      });
    }
  }

  Future<List<Map<String, dynamic>>> getInsumosByProducto(int idProducto) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT pi.*, i.nombre, i.color, i.unidad_medida, s.cantidad_disponible
      FROM producto_insumo pi
      INNER JOIN insumos i ON pi.id_insumo = i.id_insumo
      INNER JOIN stock s ON i.id_insumo = s.id_insumo
      WHERE pi.id_producto = ?
    ''', [idProducto]);
  }

  // ============================================================
  // MÉTODOS PARA VENTAS
  // ============================================================
  Future<int> insertVenta(Map<String, dynamic> venta) async {
    final db = await database;
    return await db.insert('ventas', venta);
  }

  Future<int> insertDetalleVenta(Map<String, dynamic> detalle) async {
    final db = await database;
    return await db.insert('detalle_venta', detalle);
  }

  Future<List<Map<String, dynamic>>> getVentasCompletas() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT v.*, c.nombre as cliente_nombre, u.nombre as usuario_nombre
      FROM ventas v
      INNER JOIN clientes c ON v.id_cliente = c.id_cliente
      INNER JOIN usuarios u ON v.id_usuario = u.id_usuario
      ORDER BY v.fecha DESC
    ''');
  }

  Future<Map<String, dynamic>?> getVentaById(int id) async {
    final db = await database;
    final result = await db.query('ventas', where: 'id_venta = ?', whereArgs: [id]);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  // ============================================================
  // MÉTODOS PARA MOVIMIENTOS_STOCK
  // ============================================================
  Future<int> insertMovimientoStock(Map<String, dynamic> movimiento) async {
    final db = await database;
    return await db.insert('movimientos_stock', movimiento);
  }

  Future<List<Map<String, dynamic>>> getMovimientosByInsumo(int idInsumo) async {
    final db = await database;
    return await db.query(
      'movimientos_stock',
      where: 'id_insumo = ?',
      whereArgs: [idInsumo],
      orderBy: 'fecha_hora DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getMovimientosStock() async {
    final db = await database;
    return await db.query('movimientos_stock', orderBy: 'fecha_hora DESC');
  }

  // ============================================================
  // MÉTODOS PARA CONFIGURACIÓN
  // ============================================================
  Future<Map<String, dynamic>?> getConfiguracion() async {
    final db = await database;
    final result = await db.query('configuracion');
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<int> updateConfiguracion(Map<String, dynamic> config) async {
    final db = await database;
    return await db.update('configuracion', config, where: 'id = ?', whereArgs: [1]);
  }

  // ============================================================
  // MÉTODOS ADICIONALES
  // ============================================================
  Future<int> updateEstado(int id, String estado) async {
    final db = await database;
    return await db.update('cotizaciones', {'estado': estado}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateStockInsumo(int idInsumo, double nuevaCantidad) async {
    final db = await database;
    return await db.update('stock', {'cantidad_disponible': nuevaCantidad}, where: 'id_insumo = ?', whereArgs: [idInsumo]);
  }

  // ============================================================
  // MÉTODOS PARA SINCRONIZACIÓN CON FIREBASE
  // ============================================================
  Future<List<Map<String, dynamic>>> getProductoInsumos() async {
    final db = await database;
    return await db.query('producto_insumo');
  }

  Future<List<Map<String, dynamic>>> getDetallesVenta() async {
    final db = await database;
    return await db.query('detalle_venta');
  }
}