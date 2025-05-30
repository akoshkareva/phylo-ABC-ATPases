# Подготовка последовательностей для моделирования в AlphaFold

> **Важно:** Все команды предполагают выполнение из **корневой папки проекта**, если не указано обратное.

---

## 1.1 Разделение FASTA-файла по источникам

Исходный FASTA-файл выравнивания разбивается на отдельные FASTA-файлы, где каждая группа соответствует своему источнику последовательностей. Результаты сохраняются в папку `./data/processed/06_seq_for_alphafold/`.

```bash
#!/bin/bash

tail -n +2 ./results/result_sources_ID.csv \
  | cut -d ',' -f 2 \
  | sort \
  | uniq \
  | while read source; do
      clean_source=$(echo "$source" | tr -cd '[:alnum:]._-')
      output_file="./data/processed/06_seq_for_alphafold/${clean_source}.fasta"

      awk -F, -v src="$source" 'NR>1 && $2==src {print $1}' ./results/result_sources_ID.csv > tmp_ids.txt
      count=$(wc -l < tmp_ids.txt)

      awk 'BEGIN { while ((getline < "tmp_ids.txt") > 0) ids[$0] = 1 }
           /^>/ { seq_id = substr($1, 2); keep = (seq_id in ids) }
           keep { print }' ./data/processed/05_seq_for_tree/seq_for_tree_v7.fasta > "$output_file"

      rm tmp_ids.txt
      echo "Created ${output_file} with $count sequences"
    done
```
### 1.2 Удаление символов гэпов (`-`) из FASTA-файлов

После разделения общего FASTA-файла на группы по источникам, каждый файл содержит выровненные последовательности, в которых присутствуют символы гэпов (`-`).  
На этом шаге мы удаляем эти символы, чтобы **восстановить оригинальные последовательности** перед подачей их на моделирование в AlphaFold.  
Это важно, так как AlphaFold ожидает полные аминокислотные последовательности без символов выравнивания.

Следующий код обрабатывает **все файлы** в папке `./data/processed/06_seq_for_alphafold/`, **удаляя символы `-` прямо в тех же файлах**:

```bash
#!/bin/bash

for fasta in ./data/processed/06_seq_for_alphafold/*.fasta; do
  awk '/^>/ { print; next } { gsub("-", "", $0); print }' "$fasta" > "${fasta}.tmp" && mv "${fasta}.tmp" "$fasta"
  echo "Удалены гэпы в: $fasta"
done
```

### 1.3 Создание подпапок для каждой группы последовательностей

На этом этапе для каждой FASTA-группы в `./data/processed/06_seq_for_alphafold/` создаются отдельные подпапки с соответствующим именем, а сам FASTA-файл копируется внутрь этой подпапки.

Это необходимо для последующей независимой кластеризации каждой группы.

```bash
#!/bin/bash

data_dir="./data/processed/06_seq_for_alphafold"

# Обрабатываем каждый FASTA файл в папке
for fasta_path in "$data_dir"/*.fasta; do
  [ -f "$fasta_path" ] || continue  # Пропуск, если файл не существует

  # Извлекаем имя файла без пути и расширения
  filename=$(basename -- "$fasta_path")
  dir_name="${filename%.fasta}"

  # Создаём подпапку и копируем туда файл
  target_dir="$data_dir/$dir_name"
  mkdir -p "$target_dir"
  cp "$fasta_path" "$target_dir/$filename"

  echo "Создана папка '$target_dir' с файлом '$filename'"
done

echo "Готово!"
```

## 1.4 Кластеризация последовательностей (грубая) для каждой группы

> **Примечание:** Код в этом пункте должен выполняться **внутри каждой подпапки группы последовательностей** в `./data/processed/06_seq_for_alphafold/`.

На этом этапе проводится **грубая кластеризация** последовательностей в каждой группе с помощью инструмента `mmseqs2`.

### Пояснение параметров кластеризации:

- `--min-seq-id 0.3` — минимальная доля идентичности между последовательностями: 30%.
- `-c 0.3` — минимальное покрытие между последовательностями: 30%.
- `--cluster-mode 1` — кластеризация в режиме "connected component":
  
  **Connected component** (`--cluster-mode 1`) использует транзитивные связи между последовательностями, позволяя объединять и более отдалённые гомологи.  
  Кластер строится, начиная с наиболее связанной вершины (последовательности), включая все последовательности, достижимые в обходе графа в ширину (breadth-first search). Это приводит к более широкому охвату и укрупнённым кластерам по сравнению с другими режимами кластеризации.

### Что делает скрипт:

1. Создаёт базу данных из FASTA-файла.
2. Выполняет кластеризацию последовательностей.
3. Создаёт таблицу соответствий: какая последовательность к какому кластеру принадлежит.
4. Извлекает представительные последовательности кластеров.
5. Определяет **топ-3 кластера** по числу входящих последовательностей.
6. Извлекает представителя каждого из топ-3 кластеров:
   - `top3_clusters.txt` — список топ-3 кластеров и число последовательностей в них.
   - `top3_representatives.fasta` — FASTA-файл с представителями этих кластеров.

```bash
#!/bin/bash
set -e

INPUT_FASTA=$(ls *.fasta 2>/dev/null | head -n1)

echo "Шаг 1/6: Создание базы данных..."
mmseqs createdb "$INPUT_FASTA" DB

echo "Шаг 2/6: Кластеризация последовательностей..."
mmseqs cluster DB DB_clu tmp --min-seq-id 0.3 -c 0.3 --cluster-mode 1

echo "Шаг 3/6: Создание таблицы кластеров..."
mmseqs createtsv DB DB DB_clu DB_clu.tsv

echo "Шаг 4/6: Извлечение представителей..."
mmseqs createsubdb DB_clu DB DB_clu_rep
mmseqs convert2fasta DB_clu_rep DB_clu_rep.fasta

echo "Шаг 5/6: Определение топ-3 кластеров..."
awk '{ print $1 }' DB_clu.tsv \
  | sort \
  | uniq -c \
  | sort -nr \
  | head -n3 > top3_clusters.txt
awk '{ print $2 }' top3_clusters.txt > top3_ids.txt

echo "Шаг 6/6: Извлечение представителей топ-3 кластеров..."
awk 'NR==FNR { top[$1]; next }
     /^>/ { seqname = substr($1, 2); keep = (seqname in top) }
     keep { print }' top3_ids.txt DB_clu_rep.fasta > top3_representatives.fasta
```

### 1.5 Сбор результатов кластеризации

На этом этапе мы проходим по всем подпапкам внутри `./data/processed/06_seq_for_alphafold/`, находим файлы `top3_representatives.fasta` и `top3_clusters.txt`, и копируем их в основную папку `./data/processed/06_seq_for_alphafold/`, одновременно переименовывая по имени подпапки. Это упрощает последующую работу с этими файлами.

```bash
#!/bin/bash

base_dir="./data/processed/06_seq_for_alphafold"

find "$base_dir" -mindepth 2 -maxdepth 2 -type f \( -name "top3_representatives.fasta" -o -name "top3_clusters.txt" \) | while read -r file; do
  parent_dir=$(dirname "$file")
  folder_name=$(basename "$parent_dir")
  filename=$(basename "$file")
  new_name="${folder_name}_${filename}"
  cp "$file" "$base_dir/$new_name"
  echo "Скопировано: $file -> $base_dir/$new_name"
done

echo "Готово!"
```

### 1.6 Объединение представителей и множественное выравнивание

На этом шаге объединяются представители топ-3 кластеров из всех групп в один общий FASTA-файл, исключаются нежелательные представители (например, AAA ATPases), и выполняется **множественное выравнивание**.

Все файлы берутся из папки `./data/processed/06_seq_for_alphafold/`, а результаты сохраняются туда же.  
Команды выполняются из корневой папки проекта.

```bash
#!/bin/bash

# Путь к рабочей директории с фаста файлами
work_dir="./data/processed/06_seq_for_alphafold"

# Объединяем все топ-3 представителей в один файл
cat "$work_dir"/*_top3_representatives.fasta > "$work_dir/all_clades_representatives.fasta"
echo "Создан объединённый FASTA: $work_dir/all_clades_representatives.fasta"

# Удаляем представителей AAA ATPases по ID
awk '/^>/ {keep=1} /^>rept_Dm_17737635|^>Tery3729_Ter_23043094|^>McrB_Ec_2144460/ {keep=0} keep' "$work_dir/all_clades_representatives.fasta" > "$work_dir/tmp.fasta" && mv "$work_dir/tmp.fasta" "$work_dir/all_clades_representatives.fasta"
echo "Удалены представители AAA ATPases из объединённого FASTA"

# Выполняем множественное выравнивание с Clustal Omega
clustalo -i "$work_dir/all_clades_representatives.fasta" -o "$work_dir/msa_all_clades_representatives.fasta" --full --threads=4
echo "Выравнивание завершено: $work_dir/msa_all_clades_representatives.fasta"
```
---

## ✅ Итоги этапа 1: Подготовка последовательностей для моделирования в AlphaFold

На этом этапе была выполнена **предварительная обработка и организация данных**, необходимых для корректной подачи последовательностей в AlphaFold. В частности:

1. **Разделение общего FASTA-файла** по источникам — для упрощения индивидуального анализа и моделирования.
2. **Удаление гэпов (`-`)** — восстановление исходных аминокислотных последовательностей, пригодных для подачи в AlphaFold.
3. **Создание структуры папок** — каждая группа последовательностей была помещена в отдельную подпапку, что обеспечивает изоляцию при кластеризации и дальнейших шагах.
4. **Грубая кластеризация** в каждой группе — объединение схожих последовательностей в кластеры для выявления их разнообразия.
   - Были выбраны представители **топ-3 кластеров** — это позволяет сосредоточиться на наиболее типичных (или распространённых) последовательностях.
5. **Сбор итоговых файлов** — все файлы с представителями топ-3 кластеров и статистикой по кластерам были скопированы в один каталог `./data/processed/06_seq_for_alphafold`.
6. **Множественное выравнивание** — все представители топ-3 кластеров были выровнены (`msa_all_clades_representatives.fasta`).

В результате подготовлен **набор очищенных и структурированных последовательностей** готовых для подачи на структурное моделирование с помощью AlphaFold, а также их выравнивание для дальнейшего анализа консервативных и вариабельных участков.
