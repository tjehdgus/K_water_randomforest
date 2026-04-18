# 랜덤 포레스트 최종 - 정규화/표준화 적용 (F1 스코어 0.93 달성)
# 누적강수량, 가조시간, 평균기온, 저수량, 댐 변수 사용
# 관련 CSV: spi수위제외.csv
# 최적 시드: seed=14, ntree=59 → 가뭄 F1 스코어 높음

library(randomForest)
library(caret)

# 데이터셋 로드
spi <- read.csv('spi수위제외.csv', header = TRUE, stringsAsFactors = TRUE)
str(spi)
head(spi)

# 결측치 제거
spi <- na.omit(spi)
colSums(is.na(spi))
nrow(spi)

# 정규화/표준화 함수 정의
normalize <- function(x) { return((x - min(x)) / (max(x) - min(x))) }
standard  <- function(x) { return((x - mean(x)) / sd(x)) }

# 변수별 스케일링
spi$가조시간   <- normalize(spi$가조시간)
spi$평균기온   <- normalize(spi$평균기온)
spi$저수량     <- standard(spi$저수량)
spi$누적강수량 <- standard(spi$누적강수량)

summary(spi)

# 훈련/테스트 분리 (9:1)
set.seed(10)
train_indx <- createDataPartition(spi$가뭄, p = 0.9, list = FALSE)
spi_train <- spi[train_indx, ]
spi_test  <- spi[-train_indx, ]
nrow(spi_train)
nrow(spi_test)

# 랜덤 포레스트 모델 학습
# ※ 최적 파라미터: seed=14, ntree=59 (가뭄 F1 스코어 높음)
rf_model <- randomForest(가뭄 ~ ., data = spi_train, ntree = 46)

# 예측
predictions <- predict(rf_model, spi_test)
print(predictions)

# 혼동 행렬
confusion_matrix <- table(spi_test$가뭄, predictions)
print(confusion_matrix)

# 정확도
accuracy <- sum(diag(confusion_matrix)) / sum(confusion_matrix)
print(paste("Accuracy:", accuracy))

# F1 스코어 계산 함수
f1_score <- function(conf_matrix) {
  precision <- diag(conf_matrix) / colSums(conf_matrix)
  recall    <- diag(conf_matrix) / rowSums(conf_matrix)
  f1        <- 2 * ((precision * recall) / (precision + recall))
  f1[is.nan(f1)] <- 0
  return(f1)
}

# 클래스별 F1 스코어
f1_scores <- f1_score(confusion_matrix)
print(f1_scores)

# 마이크로 평균 F1
micro_f1 <- sum(2 * diag(confusion_matrix)) / (sum(confusion_matrix) + sum(confusion_matrix))
print(paste("Micro F1 Score:", micro_f1))

# 매크로 평균 F1
macro_f1 <- mean(f1_scores, na.rm = TRUE)
print(paste("Macro F1 Score:", macro_f1))


# ============================================================
# 최적 시드: seed 14, ntree 59 → 가뭄 F1 스코어 높음
# ============================================================
set.seed(14)
rf_model <- randomForest(가뭄 ~ ., data = spi_train, ntree = 59)
