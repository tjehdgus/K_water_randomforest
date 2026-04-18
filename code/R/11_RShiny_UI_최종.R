# R Shiny - 최종 UI: 유역/댐 선택 + SPI 변수 입력
# 관련 파일: 지도.png, red_coordinates.csv, dam.png

library(shiny)
library(imager)
library(dplyr)
library(plotly)

# UI 정의
ui <- fluidPage(
  titlePanel("댐 정보 및 SPI 입력"),

  sidebarLayout(
    sidebarPanel(
      h4("댐의 정보"),
      selectInput("basin", "유역 선택",
                  choices = c("한강 유역", "낙동강 유역", "금강 유역", "섬진강 유역", "영산강 유역")),
      uiOutput("dam_selector"),

      textOutput("dam_name"),
      textOutput("dam_height"),
      textOutput("dam_volume"),

      h4("SPI 입력"),
      sliderInput("precipitation", "누적강수량", min = 0, max = 1000, value = 50, ticks = FALSE),
      numericInput("precipitation_num", "입력:", value = 50, min = 0, max = 1000),

      sliderInput("dry_period", "가뭄시간", min = 0, max = 100, value = 50, ticks = FALSE),
      numericInput("dry_period_num", "입력:", value = 50, min = 0, max = 100),

      sliderInput("storage", "저수량", min = 0, max = 1000, value = 50, ticks = FALSE),
      numericInput("storage_num", "입력:", value = 50, min = 0, max = 1000),

      sliderInput("ranking", "평균기온", min = 0, max = 50, value = 50, ticks = FALSE),
      numericInput("ranking_num", "입력:", value = 50, min = 0, max = 50),

      actionButton("save", "저장"),
      actionButton("reset", "다시하기")
    ),

    mainPanel(
      plotlyOutput("imagePlot", width = "100%", height = "auto")
    )
  )
)

# Server 정의
server <- function(input, output, session) {
  img_path      <- "C:/data/지도.png"
  csv_path      <- "C:/data/red_coordinates.csv"
  dam_icon_path <- "C:/data/dam.png"

  print(paste("지도 이미지 파일 경로:", img_path))
  print(paste("CSV 파일 경로:", csv_path))
  print(paste("댐 아이콘 파일 경로:", dam_icon_path))

  if (!file.exists(img_path) | !file.exists(csv_path) | !file.exists(dam_icon_path)) {
    stop("필요한 파일을 찾을 수 없습니다.")
  }

  img      <- load.image(img_path)
  dam_icon <- load.image(dam_icon_path)
  coords   <- read.csv(csv_path, fileEncoding = "UTF-16", sep = "\t")

  if (!all(c("x", "y", "width", "height", "name") %in% colnames(coords))) {
    stop("CSV 파일에 필요한 열('x', 'y', 'width', 'height', 'name')이 없습니다.")
  }

  # 유역별 댐 목록
  basins <- list(
    "한강 유역"   = c("소양강댐", "달방댐", "광동댐", "횡성댐", "충주댐"),
    "낙동강 유역" = c("영주댐", "안동댐", "임하댐", "성덕댐", "보현산댐", "영천댐", "군위댐", "안계댐",
                      "감포댐", "대암댐", "사연댐", "선암댐", "김천부항댐", "운문댐", "밀양댐",
                      "합천댐", "남강댐", "연초댐", "구천댐"),
    "금강 유역"   = c("대청댐", "보령댐"),
    "섬진강 유역" = c("수어댐", "주암댐", "장흥댐", "섬진강댐"),
    "영산강 유역" = c("부안댐", "평림댐")
  )

  # 유역 선택에 따른 댐 목록 동적 업데이트
  output$dam_selector <- renderUI({
    selectInput("dam", "댐 선택", choices = basins[[input$basin]])
  })

  # 이미지 크기 및 스케일 계산
  img_width  <- dim(img)[2]
  img_height <- dim(img)[1] * 1.43
  scale_x    <- img_width / coords$width[1]
  scale_y    <- (img_height / 1.43) / coords$height[1]

  clickable_coords <- coords %>% mutate(x = as.numeric(x) * scale_x, y = as.numeric(y) * scale_y * 1.43)

  img      <- resize(img, size_x = img_width, size_y = img_height)
  img      <- mirror(img, "y")
  dam_icon <- resize(dam_icon, size_x = 50, size_y = 50)

  # Plotly 지도 출력
  output$imagePlot <- renderPlotly({
    p <- plot_ly() %>%
      add_image(
        source = raster2uri(as.raster(img)),
        x = 0, y = 0,
        xref = "x", yref = "y",
        sizex = img_width, sizey = img_height,
        sizing = "stretch", layer = "below"
      ) %>%
      layout(
        xaxis  = list(visible = FALSE, range = c(0, img_width), constrain = 'domain'),
        yaxis  = list(visible = FALSE, range = c(0, img_height), constrain = 'domain', scaleanchor = "x"),
        images = lapply(1:nrow(clickable_coords), function(i) {
          list(
            source  = raster2uri(dam_icon),
            xref    = "x", yref = "y",
            x       = clickable_coords$x[i],
            y       = img_height - clickable_coords$y[i],
            sizex   = 50, sizey = 50,
            xanchor = "center", yanchor = "center"
          )
        }),
        dragmode = "pan"
      ) %>%
      config(scrollZoom = TRUE, displayModeBar = FALSE)
    p
  })

  # 댐 정보 출력
  output$dam_name   <- renderText({ "댐 이름: " })
  output$dam_height <- renderText({ "댐의 높이: " })
  output$dam_volume <- renderText({ "댐의 저수량: " })

  # 저장 버튼
  observeEvent(input$save, {
    showModal(modalDialog(title = "저장", "저장되었습니다!"))
  })

  # 리셋 버튼
  observeEvent(input$reset, {
    updateSliderInput(session, "precipitation", value = 50)
    updateNumericInput(session, "precipitation_num", value = 50)
    updateSliderInput(session, "dry_period", value = 50)
    updateNumericInput(session, "dry_period_num", value = 50)
    updateSliderInput(session, "storage", value = 50)
    updateNumericInput(session, "storage_num", value = 50)
    updateSliderInput(session, "ranking", value = 50)
    updateNumericInput(session, "ranking_num", value = 50)
  })

  # 슬라이더 ↔ 숫자 입력 동기화
  observeEvent(input$precipitation_num, { updateSliderInput(session, "precipitation", value = input$precipitation_num) })
  observeEvent(input$precipitation,     { updateNumericInput(session, "precipitation_num", value = input$precipitation) })

  observeEvent(input$dry_period_num, { updateSliderInput(session, "dry_period", value = input$dry_period_num) })
  observeEvent(input$dry_period,     { updateNumericInput(session, "dry_period_num", value = input$dry_period) })

  observeEvent(input$storage_num, { updateSliderInput(session, "storage", value = input$storage_num) })
  observeEvent(input$storage,     { updateNumericInput(session, "storage_num", value = input$storage) })

  observeEvent(input$ranking_num, { updateSliderInput(session, "ranking", value = input$ranking_num) })
  observeEvent(input$ranking,     { updateNumericInput(session, "ranking_num", value = input$ranking) })
}

shinyApp(ui = ui, server = server)
