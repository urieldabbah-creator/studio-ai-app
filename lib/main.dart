import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const StudioAiAppMain());
}

class StudioAiAppMain extends StatelessWidget {
  const StudioAiAppMain({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Studio AI App Main',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
          const SnackBar(content: Text('Imagen de prueba lista para la IA!')),
        );
      } else {
        setState(() => _cargandoIA = false);
      }
    } catch (e) {
      setState(() => _cargandoIA = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar imagen: $e')),
      );
    }
  }

  Future<void> _ejecutarIA() async {
    if (_bytesImagenWeb == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero selecciona una imagen de prueba')),
      );
      return;
    }

    setState(() => _cargandoIA = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse(_urlBackend));
      request.fields['prompt'] = _promptController.text;
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _bytesImagenWeb!,
          filename: 'imagen.jpg',
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        setState(() {
          _bytesImagenWeb = response.bodyBytes;
          _cargandoIA = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Transformación aplicada con éxito!')),
        );
      } else {
        setState(() => _cargandoIA = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error del servidor: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => _cargandoIA = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Studio AI'),
        backgroundColor: const Color(0xFF6366F1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: _bytesImagenWeb != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      image: Image.memory(_bytesImagenWeb!, fit: BoxFit.cover),
                    )
                  : const Center(
                      child: Text('Sin imagen cargada'),
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _seleccionarImagen,
              icon: const Icon(Icons.image),
              label: const Text('Cargar Imagen de Prueba'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: '¿Qué cambio deseas hacer con la IA?',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.auto_awesome, color: Color(0xFF6366F1)),
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
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
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
    );
  }
}
