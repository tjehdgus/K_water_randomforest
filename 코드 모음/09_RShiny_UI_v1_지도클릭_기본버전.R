# R Shiny - 지도 클릭 UI 기본 버전
# 이미지 클릭 시 좌표 확인 및 댐 정보 표시
# 관련 파일: 지도.png, red_coordinates.csv

library(shiny)
library(imager)
library(dplyr)

# Define UI for application
ui <- fluidPage(
  titlePanel("지도 클릭 좌표 확인"),

  sidebarLayout(
    sidebarPanel(
      # 사이드바에는 아무 것도 추가하지 않음
    ),

    mainPanel(
      plotOutput("imagePlot", click = "plot_click", width = "100%", height = "auto"),
      verbatimTextOutput("click_info")
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  # 파일 경로 설정
  img_path <- "C:/data/지도.png"
  csv_path <- "C:/data/red_coordinates.csv"

  print(paste("이미지 파일 경로:", img_path))
  print(paste("CSV 파일 경로:", csv_path))

  if (!file.exists(img_path)) {
    output$click_info <- renderPrint({ print("이미지 파일을 찾을 수 없습니다.") })
    return(NULL)
  }

  if (!file.exists(csv_path)) {
    output$click_info <- renderPrint({ print("CSV 파일을 찾을 수 없습니다.") })
    return(NULL)
  }

  # 이미지 로드
  img <- load.image(img_path)

  # CSV 파일에서 데이터 로드
  coords <- read.csv(csv_path)

  if (!all(c("x", "y", "width", "height") %in% colnames(coords))) {
    output$click_info <- renderPrint({ print("CSV 파일에 필요한 열이 없습니다.") })
    return(NULL)
  }

  if (nrow(coords) == 0) {
    output$click_info <- renderPrint({ print("CSV 파일에 데이터가 없습니다.") })
    return(NULL)
  }

  # 이미지 크기 및 스케일 계산 (세로 1.43배 조정)
  img_width  <- dim(img)[2]
  img_height <- dim(img)[1] * 1.43
  scale_x    <- img_width / coords$width[1]
  scale_y    <- (img_height / 1.43) / coords$height[1]

  # 클릭 가능한 좌표 변환
  clickable_coords <- coords %>% mutate(x = x * scale_x, y = y * scale_y * 1.43)

  # 이미지 크기 재조정
  img <- resize(img, size_x = img_width, size_y = img_height)

  # 이미지 플롯 출력
  output$imagePlot <- renderPlot({
    op <- par(mar = rep(0, 4))
    plot(1, type = "n", xlim = c(0, img_width), ylim = c(0, img_height),
         xlab = "", ylab = "", axes = FALSE, asp = 1)
    rasterImage(as.raster(img), 0, 0, img_width, img_height)
    points(clickable_coords$x, img_height - clickable_coords$y, col = "red", pch = 19)
    par(op)
  }, height = function() { session$clientData$output_imagePlot_width * 1.43 })

  # 클릭한 좌표 출력
  output$click_info <- renderPrint({
    req(input$plot_click)
    click <- input$plot_click
    click_coords <- c(round(click$x / scale_x), round((img_height / 1.43 - click$y) / scale_y))
    print(paste("클릭한 좌표: ", click_coords[1], click_coords[2]))

    selected_row <- filter(coords, x == click_coords[1] & y == click_coords[2])
    if (nrow(selected_row) > 0) {
      print(selected_row)
    } else {
      print("해당 좌표에 대한 정보가 없습니다.")
    }
  })
}

shinyApp(ui = ui, server = server)
