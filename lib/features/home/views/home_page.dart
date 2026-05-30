import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/home_viewmodel.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get view model without listening for build to access methods
    // We will use Consumer for specific parts or just context.watch inside widgets
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontak - WA, TTS & Suara'),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () => context
                .read<HomeViewModel>()
                .speak("Selamat datang. Ini contoh suara Text to Speech."),
            tooltip: "Contoh TTS",
          ),
        ],
      ),
      body: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              _buildTopInfoCard(context, viewModel),
              _buildSpeechResultSection(viewModel),
              if (viewModel.hasCapturedImage)
                _buildImageDescriptionSection(viewModel),
              _buildContactsList(viewModel),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          return FloatingActionButton(
            onPressed: viewModel.startListening,
            backgroundColor:
                viewModel.isListening ? Colors.red : Colors.blueGrey,
            child: Icon(viewModel.isListening ? Icons.mic_off : Icons.mic),
            tooltip: "Tekan untuk bicara",
          );
        },
      ),
    );
  }

  Widget _buildTopInfoCard(BuildContext context, HomeViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status USB: ${viewModel.usbStatus}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Data Diterima: ${viewModel.receivedData}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    viewModel.callType == 'whatsapp'
                        ? Icons.message
                        : Icons.phone,
                    color: viewModel.callType == 'whatsapp'
                        ? Colors.green
                        : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Jenis Panggilan: ${viewModel.callType == 'whatsapp' ? 'WhatsApp' : 'Panggilan Langsung'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  for (int i = 1; i <= 7; i++)
                    ElevatedButton(
                      onPressed: () => viewModel.triggerN("N_$i"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('$i'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeechResultSection(HomeViewModel viewModel) {
    return Expanded(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blueGrey),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Hasil Perintah Suara',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (viewModel.lastSpokenText.isNotEmpty) ...[
                      const Text('Hasil Suara (Mic):',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 4),
                      Text(viewModel.lastSpokenText,
                          style: const TextStyle(fontSize: 16)),
                      const Divider(),
                    ],
                    if (viewModel.isClarifyingContact &&
                        viewModel.ambiguousMatches.isNotEmpty) ...[
                      const Text('Beberapa Pilihan Ditemukan:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange)),
                      const SizedBox(height: 4),
                      ...viewModel.ambiguousMatches.map((match) => Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                                "- ${match.key} (${match.value.toStringAsFixed(0)}%)"),
                          )),
                      const Divider(),
                    ],
                    if (viewModel.lastMatchedContact.isNotEmpty &&
                        !viewModel.isClarifyingContact) ...[
                      const Text('Kontak Terbaca:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                      const SizedBox(height: 4),
                      Text(viewModel.lastMatchedContact,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const Divider(),
                    ],
                    const Text('Detail Perintah:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(viewModel.speechResult,
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDescriptionSection(HomeViewModel viewModel) {
    return Expanded(
      flex: 2,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blueGrey),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.image, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Deskripsi Gambar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Text(viewModel.imageDescription,
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsList(HomeViewModel viewModel) {
    return Expanded(
      flex: 3,
      child: viewModel.contacts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: viewModel.contacts.length,
              itemBuilder: (context, index) {
                final contact = viewModel.contacts[index];
                final phone = contact.phones.isNotEmpty
                    ? contact.phones.first.number
                    : "No Phone";
                return ListTile(
                  title: Text(contact.displayName),
                  subtitle: Text(phone),
                  onTap: () => viewModel.speakContact(contact.displayName),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.message),
                        color: Colors.green,
                        onPressed: () =>
                            viewModel.launchCall(contact.displayName, phone),
                        tooltip: "Panggil via WhatsApp",
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone),
                        color: Colors.blue,
                        onPressed: () {
                          // Force direct call for this button
                          // We might need to handle this better in VM, but for now:
                          viewModel.callType = 'direct';
                          viewModel.launchCall(contact.displayName, phone);
                        },
                        tooltip: "Panggil via Panggilan Langsung",
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
