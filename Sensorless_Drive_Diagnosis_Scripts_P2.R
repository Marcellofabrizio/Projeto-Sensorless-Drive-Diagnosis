rm(list = ls())

library(stringr)
library(caret)
library(mclust)
library(class)
# Número de partições que serão criadas
K = 1

set.seed(1)

sensor_data = read.csv(
  "Sensorless_drive_diagnosis.txt",
  sep = " ",
  na.strings = "?",
  dec = "."
)

str(sensor_data)

sensor_data = na.omit(sensor_data)

features_names = vector("list", length = length(names(sensor_data)))
for (i in 1:length(names(sensor_data)) - 1) {
  features_names[i] = str_interp("Feature${i}")
}

features_names[49] = "label"
names(sensor_data) = features_names

sensor_data$label = factor(sensor_data$label, levels = 1:11)

partitions = createFolds(sensor_data$label, k = K)

accuracies = matrix(nrow = K, ncol = 12)

for (partition in 1:K) {
  test_indexes = partitions[[partition]]
  training_indexes = unlist(partitions[-partition])
  
  test_data    = sensor_data[test_indexes,-49]
  test_labels  = sensor_data[test_indexes, 49]
  
  training_data    = sensor_data[training_indexes,-49]
  training_labels  = sensor_data[training_indexes, 49]
  
  ## Normalização por Z-Score
  normalization_parameters = preProcess(training_data, method = c("center", "scale"))
  training_data            = predict(normalization_parameters, training_data)
  test_data                = predict(normalization_parameters, test_data)
  rm(normalization_parameters)
  
  
  ## Seleção de caracteristicas
  correlation_matrix = cor(training_data)
  strong_correlations = findCorrelation(correlation_matrix, cutoff = 0.95)

  if (length(strong_correlations) > 0) {
    training_data[, strong_correlations] = NULL
    test_data[, strong_correlations] = NULL
  }

  ## Treinamento de dados utilizando modelo de misturas gaussianas
  
  methods = c("VII", "VVI", "VVE")

  gmm.model = MclustDA(training_data, training_labels, modelNames = c("VVE"))
  ## Predição dos dados
  gmm.predict = predict(gmm.model, test_data)
  confusion_matrix = confusionMatrix(gmm.predict$classification, test_labels)
  accuracies[partition, 1] = confusion_matrix$overall[1]
  
}

