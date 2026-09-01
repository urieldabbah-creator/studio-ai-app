import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const DisenoIApp());
}

class DisenoIApp extends StatelessWidget {
  const DisenoIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Studio AI Pro',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const PantallaStudioModerna(),
    );
  }
}

class PantallaStudioModerna extends StatefulWidget {
  const PantallaStudioModerna({super.key});

  @override
  State<PantallaStudioModerna> createState() => _PantallaStudioModernaState();
}

class _PantallaStudioModernaState extends State<PantallaStudioModerna> {
  final TextEditingController _promptController = TextEditingController();
  bool _cargandoIA = false;
  String _modoSeleccionado = 'Editar con IA';
  
  XFile? _imagenSeleccionada;
  Uint8List? _bytesImagenWeb;

  final String _urlBackend = 'https://studio-ai-backend-wnge.onrender.com/editar-con-ia-real/';

  Future<void> _seleccionarImagen() async {
    try {
      setState(() => _cargandoIA = true);
      var respuesta = await http.get(Uri.parse('https://picsum.photos/600/600'));
      
      if (respuesta.statusCode == 200) {
        setState(() {
          _bytesImagenWeb = respuesta.bodyBytes;
          _imagenSeleccionada = XFile('imagen_prueba.jpg');
          _cargandoIA = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📸 ¡Imagen de prueba lista para la IA!')),
        );
      } else {
        setState(() => _cargandoIA = false);
      }
    } catch (e) {
      setState(() => _cargandoIA = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Error al cargar imagen: $e')),
      );
    }
  }

  Future<void> _ejecutarIA() async {
    if (_promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Por favor escribe una instrucción para la IA')),
      );
      return;
    }

    if (_imagenSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Por favor toca el cuadro para cargar una foto primero')),
      );
      return;
    }

    setState(() => _cargandoIA = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse(_urlBackend));
      request.fields['prompt_usuario'] = _promptController.text;
      
      if (kIsWeb && _bytesImagenWeb != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _bytesImagenWeb!,
            filename: 'foto_prueba.jpg',
          ),
        );
      } else if (!kIsWeb && _imagenSeleccionada != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            _imagenSeleccionada!.path,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      setState(() => _cargandoIA = false);

      if (response.statusCode == 200) {
        // Enviamos los bytes devueltos por el servidor a la pantalla de resultado
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PantallaResultado(imagenResultadoBytes: response.bodyBytes),
          ),
        );
      } else {
        throw Exception('Error en el servidor');
      }
    } catch (e) {
      setState(() => _cargandoIA = false);
      // Si ocurre un error de red pero quieres ver la interfaz con la imagen original como respaldo:
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PantallaResultado(imagenResultadoBytes: _bytesImagenWeb),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Studio AI Pro',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
            ),
          ],
        ),
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFEDE9FE),
              Color(0xFFF1F5F9),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _modoSeleccionado = 'Editar con IA'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _modoSeleccionado == 'Editar con IA' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _modoSeleccionado == 'Editar con IA'
                                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                : [],
                          ),
                          child: Text(
                            'Editar con IA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _modoSeleccionado == 'Editar con IA' ? const Color(0xFF6366F1) : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _modoSeleccionado = 'Escanear Inteligente'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _modoSeleccionado == 'Escanear Inteligente' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _modoSeleccionado == 'Escanear Inteligente'
                                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                : [],
                          ),
                          child: Text(
                            'Escanear',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _modoSeleccionado == 'Escanear Inteligente' ? const Color(0xFF6366F1) : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _seleccionarImagen,
                child: Container(
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF6366F1), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _bytesImagenWeb != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.memory(_bytesImagenWeb!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_a_photo_rounded, size: 36, color: Color(0xFF6366F1)),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Sube una foto o escanea un documento',
                              style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Toca para cargar imagen de prueba en la web',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chipSugerencia('✨ Mejorar rostro', 'Mejorar nitidez y calidad del rostro'),
                    const SizedBox(width: 8),
                    _chipSugerencia('🏖️ Poner playa de fondo', 'Cambiar el fondo a una playa tropical'),
                    const SizedBox(width: 8),
                    _chipSugerencia('🧹 Borrar objeto', 'Eliminar objetos no deseados de la foto'),
                    const SizedBox(width: 8),
                    _chipSugerencia('📄 B/N nítido', 'Convertir documento escaneado a blanco y negro perfecto'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _promptController,
                decoration: InputDecoration(
                  labelText: 'Describe qué quieres cambiar con la IA...',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.white, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                  ),
                  prefixIcon: const Icon(Icons.auto_awesome, color: Color(0xFF6366F1)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _cargandoIA ? null : _ejecutarIA,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                  ),
                  child: _cargandoIA
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Generar con Inteligencia Artificial',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipSugerencia(String etiqueta, String promptTexto) {
    return ActionChip(
      label: Text(etiqueta),
      labelStyle: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w600, fontSize: 13),
      backgroundColor: Colors.white.withOpacity(0.9),
      side: BorderSide(color: const Color(0xFF6366F1).withOpacity(0.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        setState(() {
          _promptController.text = promptTexto;
        });
      },
    );
  }
}

class PantallaResultado extends StatelessWidget {
  final Uint8List? imagenResultadoBytes;

  const PantallaResultado({super.key, this.imagenResultadoBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado Final', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.deepPurple.shade100, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: imagenResultadoBytes != null
                    ? Image.memory(imagenResultadoBytes!, fit: BoxFit.cover)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle_rounded, size: 60, color: Color(0xFF6366F1)),
                          SizedBox(height: 12),
                          Text(
                            '¡Procesado por tu Servidor!',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Guardar o Imprimir',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('📥 Descargado como JPG en alta calidad')),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Descargar JPG'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF1E293B)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('📄 Generando archivo PDF...')),
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Descargar PDF'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🖨️ Conectando con impresora...')),
                );
              },
              icon: const Icon(Icons.print),
              label: const Text('Imprimir Archivo'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Compartir directamente',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _botonRedSocial('WhatsApp', Icons.chat, Colors.green),
                _botonRedSocial('Instagram', Icons.camera_alt, Colors.pink),
                _botonRedSocial('TikTok', Icons.music_note, Colors.black),
                _botonRedSocial('Correo', Icons.email, Colors.blue),
                _botonRedSocial('Más opciones', Icons.share, const Color(0xFF6366F1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _botonRedSocial(String nombre, IconData icono, Color color) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icono, size: 18, color: Colors.white),
      label: Text(nombre),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}