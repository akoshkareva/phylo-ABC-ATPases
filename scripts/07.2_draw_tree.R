## Установка необходимых пакетов и проверка правильности директории

if (!require("BiocManager", quietly = TRUE))
  install.packages("BiocManager")

if (!require("treedataverse")) {
  BiocManager::install("remotes")
  BiocManager::install("YuLab-SMU/treedataverse")
}

library(treedataverse)
library(ggnewscale)

library(treedataverse)  # Для работы с филогенетическими деревьями (treeio, ggtree)
library(dplyr)          # Для манипуляций с данными
library(scales)         # Для работы с цветовыми шкалами
library(paletteer)      # Для работы с цветовыми палитрами
library(cartography)    # Для работы с цветовыми палитрами
getwd()


## Подготовка данных


getwd()

# Чтение файла Newick-формата и преобразование в treedata-объект

file <- "./results/fasttree_new_v0.nwk"
tree <- read.newick(file)  %>% 
  as.treedata()

### Укоренение дерева

# Список листьев для укоренения
outgroup_labels <- c(
  'DnaA(1l8q)_Aqae_24158831', 
  'Tery3729_Ter_23043094', 
  'CDC48_Sp_27151477', 
  'McrB_Ec_2144460', 
  'AFG1_Sc_6320783', 
  'gp9a_phiC31_9631173', 
  'clpB_Ssp_16331048', 
  'HOLB(1a5t)_Ec_16129062', 
  'ClpX_Scoe_21221074', 
  'rept_Dm_17737635'
)

# Проверка наличия всех листьев в дереве
missing <- setdiff(outgroup_labels, tree@phylo$tip.label)
if (length(missing) > 0) {
  stop("Отсутствующие листья: ", paste(missing, collapse = ", "))
}

outgroup_labels <- c(
  "DnaA",          # Было: 'DnaA(1l8q)_Aqae_24158831'
  "HOLB",          # Было: 'HOLB(1a5t)_Ec_16129062'
  'Tery3729_Ter_23043094', 
  'CDC48_Sp_27151477',
  'McrB_Ec_2144460',
  'AFG1_Sc_6320783',
  'gp9a_phiC31_9631173',
  'clpB_Ssp_16331048',
  'ClpX_Scoe_21221074',
  'rept_Dm_17737635'
)

# Повторяем проверку
missing <- setdiff(outgroup_labels, tree@phylo$tip.label)
if(length(missing) > 0) stop("Отсутствуют: ", paste(missing, collapse = ", "))


# Находим MRCA для указанных листьев
mrca_node <- ape::getMRCA(tree@phylo, outgroup_labels)

# Укореняем дерево
tree@phylo <- ape::root(
  phy = tree@phylo,
  node = mrca_node,
  resolve.root = TRUE,
  edgelabel = TRUE
)

### Другое укоренение

# Указываем лист для укоренения (аутгруппу)
outgroup_leaf <- "DnaA"  # Используйте реальное название из вашего дерева

# Проверяем наличие листа в дереве
if (!outgroup_leaf %in% tree@phylo$tip.label) {
  stop("Лист '", outgroup_leaf, "' отсутствует в дереве!")
}

# Укореняем дерево
tree@phylo <- ape::root(
  phy = tree@phylo,
  outgroup = outgroup_leaf,
  resolve.root = TRUE,
  edgelabel = TRUE
)

# Проверяем результат
ape::is.rooted(tree@phylo)  # Должно вернуть TRUE

# Чтение метаданных и их подготовка

metadata <- read.csv("./results/result_sources_ID_with_root.csv", stringsAsFactors = FALSE)  %>% 
  rename(label = ID) %>% # Переименование колонки для совместимости с ggtree
  mutate(
    label = case_when(
      label == "DnaA(1l8q)_Aqae_24158831" ~ "DnaA",
      label == "HOLB(1a5t)_Ec_16129062" ~ "HOLB",
      TRUE ~ label  # Сохраняем остальные значения как есть
    ),
    sources = factor(sources) # Преобразование в фактор
  )

# Создание цветовой схемы для источников
source_colors <- metadata %>%
  distinct(sources) %>% 
  arrange(sources) %>%  # Важно для стабильного порядка цветов
  mutate(
    # Сначала создаем цвета для ВСЕХ источников
    color = c(
      cartography::carto.pal(pal1 = "pastel.pal", n1 = 18)
      # scales::viridis_pal(option = "D")(18),  # Первые 15 цветов
      # scales::viridis_pal(option = "C")(0)     # Следующие 6 цветов
    )
  ) %>%
  # Затем заменяем цвет для специфичного источника
  mutate(
    color = if_else(
      sources == "AAA_ATPases",
      "#808080",  # Серый цвет
      color        # Оригинальный цвет для остальных
    )
  )

# Создание data frame с bootstrap значениями для узлов
n_tips <- length(tree@phylo$tip.label)
node_ids <- (n_tips + 1):(n_tips + tree@phylo$Nnode)

branch_data <- tibble(
  node = node_ids,
  bootstrap = as.numeric(ifelse(
    tree@phylo$node.label %in% c("", NA), 
    NA, 
    tree@phylo$node.label
  ))
)

# # Обновляем данные дерева
# tree <- treeio::full_join(tree, metadata, by = "label")


## Визуализация

### Базовая визуализация с цветом

ggtree(tree, ladderize=FALSE) + 
  geom_tippoint(aes(color = sources)) + 
  geom_tiplab(offset = 0.1)

### Пробую разные формы

# 1. Rectangular
ggtree(tree, layout = "rectangular", ladderize = FALSE) +
  geom_tippoint(aes(color = sources), show.legend = FALSE) +
  ggtitle("Rectangular Layout") +
  theme(legend.position = "none",
        plot.title = element_text(hjust = 0.5, size = 12))

# 2. Dendrogram
ggtree(tree, layout = "dendrogram", ladderize = FALSE) +
  geom_tippoint(aes(color = sources), show.legend = FALSE) +
  ggtitle("Dendrogram Layout") +
  theme(legend.position = "none",
        plot.title = element_text(hjust = 0.5, size = 12))

# 3. Slanted
ggtree(tree, layout = "slanted", ladderize = FALSE) +
  geom_tippoint(aes(color = sources), show.legend = FALSE) +
  ggtitle("Slanted Layout") +
  theme(legend.position = "none",
        plot.title = element_text(hjust = 0.5, size = 12))

# 4. Ellipse
ggtree(tree, layout = "ellipse", ladderize = FALSE) +
  geom_tippoint(aes(color = sources), show.legend = FALSE) +
  ggtitle("Ellipse Layout") +
  theme(legend.position = "none",
        plot.title = element_text(hjust = 0.5, size = 12))

# 5. Roundrect
ggtree(tree, layout = "roundrect", ladderize = FALSE) +
  geom_tippoint(aes(color = sources), show.legend = FALSE) +
  ggtitle("Roundrect Layout") +
  theme(legend.position = "none",
        plot.title = element_text(hjust = 0.5, size = 12))

# 6. Fan
ggtree(tree, layout = "fan", ladderize = FALSE) +
  geom_tippoint(aes(color = sources), show.legend = FALSE) +
  ggtitle("Fan Layout") +
  theme(legend.position = "none",
        plot.title = element_text(hjust = 0.5, size = 12))

# 7. Circular
ggtree(tree, layout = "circular", ladderize = FALSE) +
  geom_tippoint(aes(color = sources), show.legend = FALSE) +
  ggtitle("Circular Layout") +
  theme(legend.position = "none",
        plot.title = element_text(hjust = 0.5, size = 12))

# 8. Inward Circular
ggtree(tree, layout = "inward_circular", ladderize = FALSE) +
  geom_tippoint(aes(color = sources), show.legend = FALSE) +
  ggtitle("Inward Circular Layout") +
  theme(legend.position = "none",
        plot.title = element_text(hjust = 0.5, size = 12))

# 9. Radial
ggtree(tree, layout = "radial", ladderize = FALSE) +
  geom_tippoint(aes(color = sources), show.legend = FALSE) +
  ggtitle("Radial Layout") +
  theme(legend.position = "none",
        plot.title = element_text(hjust = 0.5, size = 12))

# 10. Equal Angle
ggtree(tree, layout = "equal_angle", ladderize = FALSE) +
  geom_tippoint(aes(color = sources), show.legend = FALSE) +
  ggtitle("Equal Angle Layout") +
  theme(legend.position = "none",
        plot.title = element_text(hjust = 0.5, size = 12))

# 11. Daylight
ggtree(tree, layout = "daylight", ladderize = FALSE) +
  geom_tippoint(aes(color = sources), show.legend = FALSE) +
  ggtitle("Daylight Layout") +
  theme(legend.position = "none",
        plot.title = element_text(hjust = 0.5, size = 12))

# 12. APE
ggtree(tree, layout = "ape", ladderize = FALSE) +
  geom_tippoint(aes(color = sources), show.legend = FALSE) +
  ggtitle("APE Layout") +
  theme(legend.position = "none",
        plot.title = element_text(hjust = 0.5, size = 12))
### С bootstrap и sources

# 3. Визуализация ---------------------------------------------------------
# Базовый график дерева
ggtree(tree, layout = "circular") %<+% branch_data %<+% metadata + 
  xlim(-5, NA) + 
  geom_rootedge(5) +         # Удлиняем корень
  geom_treescale() +         # Добавление шкалы длины ветвей
  
  ## Слой 1: Раскраска ветвей по bootstrap значениям ----
aes(color = ifelse(bootstrap >= 0.75, "≥0.75", "<0.75")) +  # Привязка цвета ветвей к bootstrap
  scale_color_manual(
    values = c("≥0.75" = "grey30", "<0.75" = "grey70"), # Цвета для двух групп
    # limits = c(0,1),         # Диапазон значений для bootstrap
    na.value = "grey70",     # Цвет для NA значений
    name = "Bootstrap"       # Название легенды
  ) +
  
  ## Слой 2: Heatmap с источниками (внешнее кольцо) ----
geom_fruit(
  geom = geom_tile,        # Тип геометрии - плитки
  mapping = aes(fill = sources), # Раскраска по источникам
  pwidth = 1.5,              # Ширина кольца
  offset = 0.05,           # Смещение от дерева
  na.rm = TRUE,            # Игнорировать пропущенные значения
  axis.params = list(      # Параметры осей
    axis = "none",         # Скрыть оси
    text = NULL
  )
) +
  scale_fill_manual(
    name = "Source",         # Название легенды
    values = setNames(source_colors$color, source_colors$sources) # Привязка цветов
  ) +
  # Настройка темы
  theme(
    legend.position = "right", # Позиция легенды
    legend.box = "vertical"    # Вертикальное расположение легенд
  )