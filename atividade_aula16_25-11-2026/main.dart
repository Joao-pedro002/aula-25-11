import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diário de Atividades',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),
      home: const TelaAtividades(),
    );
  }
}

class TelaAtividades extends StatefulWidget {
  const TelaAtividades({super.key});

  @override
  State<TelaAtividades> createState() => _TelaAtividadesState();
}

class _TelaAtividadesState extends State<TelaAtividades> {
  final TextEditingController atividadeController = TextEditingController();

  DateTime dataSelecionada = DateTime.now();
  DateTime mesSelecionado = DateTime.now();

  List atividades = [];

  bool carregando = false;
  bool salvando = false;

  final String urlBase = 'http://localhost/diario_api';

  @override
  void initState() {
    super.initState();
    carregarAtividades();
  }

  Future<void> selecionarData() async {
    DateTime? data = await showDatePicker(
      context: context,
      initialDate: dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (data != null) {
      setState(() {
        dataSelecionada = data;
      });
    }
  }

  Future<void> salvarAtividade() async {
    if (atividadeController.text.trim().isEmpty) {
      mostrarMensagem('Digite uma atividade!');
      return;
    }

    setState(() {
      salvando = true;
    });

    try {
      final resposta = await http.post(
        Uri.parse('$urlBase/salvar.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data':
              '${dataSelecionada.year}-${dataSelecionada.month.toString().padLeft(2, '0')}-${dataSelecionada.day.toString().padLeft(2, '0')}',
          'atividade': atividadeController.text.trim(),
        }),
      );

      final dados = jsonDecode(resposta.body);

      if (resposta.statusCode == 200 && dados['sucesso'] == true) {
        atividadeController.clear();

        setState(() {
          mesSelecionado = DateTime(
            dataSelecionada.year,
            dataSelecionada.month,
          );
        });

        mostrarMensagem('Atividade salva com sucesso!');

        await carregarAtividades();
      } else {
        mostrarMensagem(dados['mensagem'] ?? 'Erro ao salvar');
      }
    } catch (e) {
      mostrarMensagem('Não foi possível conectar ao servidor.');
    }

    setState(() {
      salvando = false;
    });
  }

  Future<void> carregarAtividades() async {
    setState(() {
      carregando = true;
    });

    try {
      final url = Uri.parse(
        '$urlBase/listar.php?mes=${mesSelecionado.month}&ano=${mesSelecionado.year}',
      );

      final resposta = await http.get(url);

      if (resposta.statusCode == 200) {
        setState(() {
          atividades = jsonDecode(resposta.body);
        });
      } else {
        mostrarMensagem('Erro ao carregar atividades');
      }
    } catch (e) {
      mostrarMensagem('Erro de conexão com o servidor');
    }

    setState(() {
      carregando = false;
    });
  }

  void mesAnterior() {
    setState(() {
      mesSelecionado = DateTime(
        mesSelecionado.year,
        mesSelecionado.month - 1,
      );
    });

    carregarAtividades();
  }

  void proximoMes() {
    setState(() {
      mesSelecionado = DateTime(
        mesSelecionado.year,
        mesSelecionado.month + 1,
      );
    });

    carregarAtividades();
  }

  String formatarData(String data) {
    DateTime d = DateTime.parse(data);

    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  String nomeMes(int mes) {
    const meses = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return meses[mes - 1];
  }

  void mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diário de Atividades'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cadastrar atividade',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: selecionarData,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month),
                    const SizedBox(width: 10),
                    Text(
                      '${dataSelecionada.day.toString().padLeft(2, '0')}/'
                      '${dataSelecionada.month.toString().padLeft(2, '0')}/'
                      '${dataSelecionada.year}',
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_calendar),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: atividadeController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Atividade realizada',
                hintText: 'Digite o que você fez durante o dia',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: salvando ? null : salvarAtividade,
                icon: const Icon(Icons.save),
                label: Text(
                  salvando ? 'Salvando...' : 'Salvar atividade',
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const Text(
              'Atividades do mês',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: mesAnterior,
                  icon: const Icon(Icons.arrow_back_ios),
                ),
                Text(
                  '${nomeMes(mesSelecionado.month)} '
                  '${mesSelecionado.year}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: proximoMes,
                  icon: const Icon(Icons.arrow_forward_ios),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (carregando)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (atividades.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Nenhuma atividade cadastrada neste mês.',
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: atividades.length,
                itemBuilder: (context, index) {
                  final item = atividades[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.event_note),
                      ),
                      title: Text(
                        formatarData(item['data_atividade']),
                      ),
                      subtitle: Text(
                        item['atividade'],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    atividadeController.dispose();
    super.dispose();
  }
}
