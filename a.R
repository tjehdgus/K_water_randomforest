library(shiny)
library(leaflet)
library(dplyr)
library(plotly)
library(randomForest)
library(caret)
library(tidyr)

# Load dam data
dam_data <- read.csv("c:\\data\\dam_loc.csv", header = TRUE, stringsAsFactors = FALSE, fileEncoding = 'euc-kr')

# Load SPI data and preprocess
spi <- read.csv('c:\\data\\spi유효.csv', header = TRUE, stringsAsFactors = TRUE)
spi <- na.omit(spi)
spi <- spi[,-c(6,7)]

# Training and test split
set.seed(24)
train_indx <- createDataPartition(spi$가뭄, p = 0.9, list = FALSE)
spi_train <- spi[train_indx, ]
spi_test <- spi[-train_indx, ]

# Normalize and standardize functions
normalize <- function(x, min_x, max_x) {
  return ((x - min_x) / (max_x - min_x))
}

standard <- function(x, mean_x, sd_x) {
  return ((x - mean_x) / (sd_x))
}

# Training data statistics
train_min_가조시간 <- min(spi_train$가조시간)
train_max_가조시간 <- max(spi_train$가조시간)
train_min_평균기온 <- min(spi_train$평균기온)
train_max_평균기온 <- max(spi_train$평균기온)
train_mean_저수량 <- mean(spi_train$저수량)
train_sd_저수량 <- sd(spi_train$저수량)
train_mean_누적강수량 <- mean(spi_train$누적강수량)
train_sd_누적강수량 <- sd(spi_train$누적강수량)
train_mean_유효저수량 <- mean(spi_train$유효저수량)
train_sd_유효저수량 <- sd(spi_train$유효저수량)

# Normalize and standardize training data
spi_train$가조시간 <- normalize(spi_train$가조시간, train_min_가조시간, train_max_가조시간)
spi_train$평균기온 <- normalize(spi_train$평균기온, train_min_평균기온, train_max_평균기온)
spi_train$저수량 <- standard(spi_train$저수량, train_mean_저수량, train_sd_저수량)
spi_train$누적강수량 <- standard(spi_train$누적강수량, train_mean_누적강수량, train_sd_누적강수량)

# Normalize and standardize test data
spi_test$가조시간 <- normalize(spi_test$가조시간, train_min_가조시간, train_max_가조시간)
spi_test$평균기온 <- normalize(spi_test$평균기온, train_min_평균기온, train_max_평균기온)
spi_test$저수량 <- standard(spi_test$저수량, train_mean_저수량, train_sd_저수량)
spi_test$누적강수량 <- standard(spi_test$누적강수량, train_mean_누적강수량, train_sd_누적강수량)
# Train random forest model
rf_model <- randomForest(가뭄 ~ ., data = spi_train, ntree = 97)

# Define UI
ui <- fluidPage(
  titlePanel("SPI 입력에 따른 정보 알림 및 댐 위치 정보"),
  sidebarLayout(
    sidebarPanel(
      div(
        h4("댐의 정보"),
        selectInput("region", "유역 선택", choices = c("전체", unique(dam_data$유역))),
        uiOutput("dam_ui"),
        textOutput("dam_info")
      ),
      div(
        h4("SPI 입력"),
        sliderInput("accum_precip", "누적강수량", min = 70, max = 2149, value = 70),
        sliderInput("precip_time", "가조시간", min = 9, max = 16, value = 9),
        uiOutput("storage_ui"),
        sliderInput("avg_standard", "평균기온", min = -20, max = 35, value = -20),
        numericInput("eff_storage", "유효저수량", value = 0, min = 0, max = 5000, step = 1),
        actionButton("predict_btn", "예측하기", class = "btn btn-primary")
      )
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("SPI 예측", 
                 leafletOutput("map"),
                 div(style = "position: absolute; bottom: 20px; right: 20px;", tableOutput("spi_table")),
                 div(style = "margin-top: 20px;", textOutput("prediction_result"))
        ),
        tabPanel("상세 정보", 
                 plotlyOutput("predictionPlot"),
                 div(style = "margin-top: 20px;", tableOutput("spi_table_detail"))
        )
      )
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  
  # 유역 선택에 따른 댐 목록 업데이트
  output$dam_ui <- renderUI({
    dams <- if (input$region == "전체") {
      unique(dam_data$name)
    } else {
      unique(dam_data$name[dam_data$유역 == input$region])
    }
    selectInput("dam", "댐 선택", choices = c("전체", dams))
  })
  
  # 선택된 댐의 정보 표시 및 유효저수량 고정
  output$dam_info <- renderText({
    if (input$dam != "전체") {
      dam_info <- dam_data %>% filter(name == input$dam)
      updateNumericInput(session, "eff_storage", value = dam_info$유효저수량, max = 5000)
      updateSliderInput(session, "storage", max = dam_info$총저수용량)
      paste("유효저수량:", dam_info$유효저수량, "톤\n총저수용량:", dam_info$총저수용량, "톤\n높이:", dam_info$높이, "m")
    } else {
      updateNumericInput(session, "eff_storage", value = 0, max = 5000)
      updateSliderInput(session, "storage", max = 3000)
      "유효저수량: 전체 \n총저수용량: 전체 \n높이: 전체"
    }
  })
  
  # 저수량 슬라이더 업데이트
  output$storage_ui <- renderUI({
    if (input$dam != "전체") {
      dam_info <- dam_data %>% filter(name == input$dam)
      sliderInput("storage", "저수량", min = 0, max = dam_info$총저수용량, value = 0)
    } else {
      sliderInput("storage", "저수량", min = 0, max = 3000, value = 0)
    }
  })
  
  # 지도 렌더링
  output$map <- renderLeaflet({
    leaflet() %>%
      addTiles()
  })
  
  # 지도 업데이트 및 마커 추가
  observe({
    req(input$region, input$dam)
    
    if (input$region == "전체" && input$dam == "전체") {
      leafletProxy("map") %>%
        clearMarkers() %>%
        addMarkers(data = dam_data, ~경도, ~위도, 
                   popup = ~paste(name, "<br>", "유역:", 유역, "<br>", "유효저수량:", 유효저수량, "톤", "<br>", "총저수용량:", 총저수용량, "톤", "<br>", "높이:", 높이, "m")) %>%
        setView(lng = 127.8, lat = 35.8, zoom = 7)
    } else if (input$region != "전체" && input$dam == "전체") {
      region_data <- dam_data %>% filter(유역 == input$region)
      leafletProxy("map") %>%
        clearMarkers() %>%
        addMarkers(data = region_data, ~경도, ~위도, 
                   popup = ~paste(name, "<br>", "유역:", 유역, "<br>", "유효저수량:", 유효저수량, "톤", "<br>", "총저수용량:", 총저수용량, "톤", "<br>", "높이:", 높이, "m")) %>%
        setView(lng = mean(region_data$경도), lat = mean(region_data$위도), zoom = 8)
    } else if (input$dam != "전체") {
      dam_info <- dam_data %>% filter(name == input$dam)
      if (nrow(dam_info) > 0) {
        lat <- dam_info$위도
        lng <- dam_info$경도
        updateNumericInput(session, "eff_storage", value = dam_info$유효저수량, max = 5000)
        updateSliderInput(session, "storage", max = dam_info$총저수용량)
        leafletProxy("map") %>%
          setView(lng = lng, lat = lat, zoom = 12) %>%
          clearMarkers() %>%
          addMarkers(lng = lng, lat = lat, popup = paste(dam_info$name, "<br>", "유역:", dam_info$유역, "<br>", "유효저수량:", dam_info$유효저수량, "톤", "<br>", "총저수용량:", dam_info$총저수용량, "톤", "<br>", "높이:", dam_info$높이, "m"))
      }
    }
  })
  
  observeEvent(input$predict_btn, {
    # 유효저수량은 선택된 댐에 따라 자동 설정됨
    eff_storage_value <- input$eff_storage
    
    # Normalize and standardize input data
    norm_precip_time <- normalize(input$precip_time, train_min_가조시간, train_max_가조시간)
    norm_avg_standard <- normalize(input$avg_standard, train_min_평균기온, train_max_평균기온)
    std_storage <- standard(input$storage, train_mean_저수량, train_sd_저수량)
    std_accum_precip <- standard(input$accum_precip, train_mean_누적강수량, train_sd_누적강수량)
    std_eff_storage <- standard(eff_storage_value, train_mean_유효저수량, train_sd_유효저수량)
    
    # Create a new data frame for prediction
    new_data <- data.frame(
      가조시간 = norm_precip_time,
      평균기온 = norm_avg_standard,
      저수량 = std_storage,
      누적강수량 = std_accum_precip,
      유효저수량 = std_eff_storage
    )
    
    # Make prediction
    prediction <- predict(rf_model, new_data, type = 'prob')
    
    # Convert results to dataframe
    result_df <- as.data.frame(t(prediction))
    result_df$Category <- factor(rownames(result_df), levels = c("심한습윤", "보통습윤", "정상", "보통가뭄", "약한가뭄", "심한가뭄"))
    colnames(result_df)[1] <- "Probability"
    
    # Create bar plot
    output$predictionPlot <- renderPlotly({
      plot_ly(result_df, x = ~Category, y = ~Probability, type = 'bar', 
              marker = list(color = 'rgb(158,202,225)', 
                            line = list(color = 'rgb(8,48,107)', width = 1.5))) %>%
        layout(title = "Prediction Probabilities",
               xaxis = list(title = "가뭄단계"),
               yaxis = list(title = "가뭄 단계 확률"))
    })
    
    output$prediction_result <- renderText({
      pred_class <- rownames(result_df)[which.max(result_df$Probability)]
      paste("예측된 가뭄 상태: ", pred_class)
    })
  })
  
  # Render Leaflet map 초기 설정
  output$map <- renderLeaflet({
    leaflet(options = leafletOptions(maxZoom = 18, minZoom = 6)) %>%
      addTiles() %>%
      setMaxBounds(lng1 = 124, lat1 = 33, lng2 = 130, lat2 = 39) %>%  # South Korea bounding box
      setView(lng = 127.024612, lat = 37.532600, zoom = 7)  # Center on Seoul, South Korea
  })
  
  # SPI6 기준표 출력 (지도 오른쪽 하단)
  output$spi_table <- renderTable({
    data.frame(
      상태 = c("심한 습윤", "보통 습윤", "정상", "약한 가뭄", "보통 가뭄", "심한 가뭄"),
      기준 = c("SPI6 > 1.5", "1.5 > SPI6 > 1", "1 > SPI6 > -1", "-1 > SPI6 > -1.5", "-1.5 > SPI6 > -2", "SPI6 < -2")
    )
  }, bordered = TRUE, striped = TRUE, hover = TRUE)
  
  # SPI6 기준표 출력 (상세 정보 탭 하단)
  output$spi_table_detail <- renderTable({
    data.frame(
      상태 = c("심한 습윤", "보통 습윤", "정상", "약한 가뭄", "보통 가뭄", "심한 가뭄"),
      기준 = c("SPI6 > 1.5", "1.5 > SPI6 > 1", "1 > SPI6 > -1", "-1 > SPI6 > -1.5", "-1.5 > SPI6 > -2", "SPI6 < -2")
    )
  }, bordered = TRUE, striped = TRUE, hover = TRUE)
}

# Run the application 
shinyApp(ui = ui, server = server)
