import matplotlib.pyplot as plt
import numpy as np

# Data untuk visualisasi
categories = ['Low Vision', 'Full Buta']
dunia = [124, 43.3]  # Juta orang
indonesia = [6.4, 1.6]  # Juta orang

# Pengaturan posisi batang
x = np.arange(len(categories))
width = 0.35  # Lebar batang

# Membuat bar chart
fig, ax = plt.subplots(figsize=(10, 6))
bars1 = ax.bar(x - width/2, dunia, width, label='Dunia', color='#66b3ff')
bars2 = ax.bar(x + width/2, indonesia, width, label='Indonesia', color='#ff9999')

# Menambahkan label dan judul
ax.set_xlabel('Kategori Gangguan Penglihatan')
ax.set_ylabel('Jumlah (Juta Orang)')
ax.set_title('Perbandingan Low Vision dan Full Buta di Dunia dan Indonesia')
ax.set_xticks(x)
ax.set_xticklabels(categories)
ax.legend()

# Menambahkan nilai di atas batang
def autolabel(bars):
    for bar in bars:
        height = bar.get_height()
        ax.annotate(f'{height}',
                    xy=(bar.get_x() + bar.get_width() / 2, height),
                    xytext=(0, 3),  # Offset 3 poin ke atas
                    textcoords="offset points",
                    ha='center', va='bottom')

autolabel(bars1)
autolabel(bars2)

# Menampilkan plot
plt.tight_layout()
plt.show()