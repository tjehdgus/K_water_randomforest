# SPI 가뭄 분류 성능 평가: 민감도, 특이도, 정밀도, F1 스코어, ROC
# 관련 CSV: f1.csv

# 필요한 패키지 설치 및 로드
install.packages("pROC")
install.packages("caret")
library(pROC)
library(caret)

# 데이터 로드
data <- read.csv("c:\\data\\f1.csv", header = T, fileEncoding = "euc-kr")

# 실제값과 예측값 추출
actual <- as.factor(data$가뭄)
predicted <- as.factor(data$예측값)

# 혼동 행렬 생성
conf_matrix <- confusionMatrix(predicted, actual)

# 민감도, 정밀도, 특이도, F1 스코어 계산
sensitivity <- conf_matrix$byClass[, "Sensitivity"]
precision   <- conf_matrix$byClass[, "Precision"]
specificity <- conf_matrix$byClass[, "Specificity"]
f1_score    <- conf_matrix$byClass[, "F1"]

# 각 클래스에 대한 ROC 곡선 및 AUC 계산
roc_curve <- multiclass.roc(actual, as.numeric(predicted))
auc <- auc(roc_curve)

# 결과 출력
list(
  sensitivity = sensitivity,
  precision   = precision,
  specificity = specificity,
  f1_score    = f1_score,
  auc         = auc
)
