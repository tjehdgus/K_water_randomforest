# 랜덤 포레스트 - 트리 수(1~100) 반복하며 최적 ntree 탐색
# 관련 CSV: spi6.csv (진짜 R에서 사용할 spi 랜포 테이블.csv)

install.packages("plotly")
library(plotly)
library(randomForest)
library(caret)
library(ggplot2)
library(plotly)

# 데이터셋 로드
spi <- read.csv('spi6.csv', header = TRUE, stringsAsFactors = TRUE)
str(spi)
spi <- spi[, -c(1, 2, 4, 8, 9, 10, 13, 14)]

# 데이터셋을 훈련 데이터와 테스트 데이터로 분할
set.seed(13)
train_indx <- createDataPartition(spi$가뭄, p = 0.9, list = FALSE)
spi_train <- spi[train_indx, ]
spi_test  <- spi[-train_indx, ]

# 정확도와 F1 스코어를 저장할 벡터 초기화
accuracy_results <- numeric(100)
f1_results       <- numeric(100)

# 트리 개수를 1부터 100까지 반복
for (ntree in 1:100) {
  print(paste("Training with", ntree, "trees"))

  # 랜덤 포레스트 모델 학습
  rf_model <- randomForest(가뭄 ~ ., data = spi_train, ntree = ntree)

  # 테스트 데이터에 대한 예측 수행
  predictions <- predict(rf_model, spi_test)

  # 혼동 행렬 계산
  confusion_matrix <- table(spi_test$가뭄, predictions)

  # 정확도 계산
  accuracy <- sum(diag(confusion_matrix)) / sum(confusion_matrix)
  accuracy_results[ntree] <- accuracy

  # F1 스코어 계산
  precision <- diag(confusion_matrix) / colSums(confusion_matrix)
  recall    <- diag(confusion_matrix) / rowSums(confusion_matrix)
  f1        <- 2 * ((precision * recall) / (precision + recall))
  f1[is.nan(f1)] <- 0  # NaN을 0으로 대체
  f1_macro  <- mean(f1, na.rm = TRUE)
  f1_results[ntree] <- f1_macro
}

# 결과를 데이터 프레임으로 변환
results_df <- data.frame(ntree = 1:100, accuracy = accuracy_results, f1_score = f1_results)

# 정확도 라인 그래프
accuracy_plot <- ggplot(results_df, aes(x = ntree, y = accuracy)) +
  geom_line(color = "blue") +
  labs(title = "Random Forest Accuracy vs Number of Trees",
       x = "Number of Trees", y = "Accuracy") +
  theme_minimal()

# F1 스코어 라인 그래프
f1_plot <- ggplot(results_df, aes(x = ntree, y = f1_score)) +
  geom_line(color = "red") +
  labs(title = "Random Forest F1 Score vs Number of Trees",
       x = "Number of Trees", y = "F1 Score") +
  theme_minimal()

# Plotly 인터랙티브 플롯
accuracy_plotly <- ggplotly(accuracy_plot)
f1_plotly       <- ggplotly(f1_plot)

accuracy_plotly
f1_plotly
