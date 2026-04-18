# R Shiny - 지도 클릭 UI Plotly 인터랙티브 버전
# 댐 아이콘 표시, 줌/이동 가능
# 관련 파일: 지도.png, red_coordinates.csv, dam.png(댐 아이콘)

library(shiny)
library(imager)
library(dplyr)
library(plotly)

# Define UI
ui <- fluidPage(
  titlePanel("지도 클릭 좌표 확인"),

  sidebarLayout(
    sidebarPanel(),

    mainPanel(
      plotlyOutput("imagePlot", width = "100%", height = "auto"),
      verbatimTextOutput("click_info")
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  img_path      <- "C:/data/지도.png"
  csv_path      <- "C:/data/red_coordinates.csv"
  dam_icon_path <- "/mnt/data/image.png"  # 댐 아이콘 이미지 경로

  print(paste("지도 이미지 파일 경로:", img_path))
  print(paste("CSV 파일 경로:", csv_path))
  print(paste("댐 아이콘 파일 경로:", dam_icon_path))

  if (!file.exists(img_path) | !file.exists(csv_path) | !file.exists(dam_icon_path)) {
    stop("필요한 파일을 찾을 수 없습니다.")
  }

  img      <- load.image(img_path)
  dam_icon <- load.image(dam_icon_path)
  coords   <- read.csv(csv_path)

  if (!all(c("x", "y", "width", "height") %in% colnames(coords))) {
    stop("CSV 파일에 필요한 열이 없습니다.")
  }

  # 이미지 크기 및 스케일 계산
  img_width  <- dim(img)[2]
  img_height <- dim(img)[1] * 1.43
  scale_x    <- img_width / coords$width[1]
  scale_y    <- (img_height / 1.43) / coords$height[1]

  clickable_coords <- coords %>% mutate(x = as.numeric(x) * scale_x, y = as.numeric(y) * scale_y * 1.43)

  img      <- resize(img, size_x = img_width, size_y = img_height)
  img      <- mirror(img, "y")
  dam_icon <- resize(dam_icon, size_x = 24, size_y = 24)

  # Plotly 인터랙티브 이미지 출력
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
            sizex   = 24, sizey = 24,
            xanchor = "center", yanchor = "center"
          )
        }),
        dragmode = "pan"
      ) %>%
      config(scrollZoom = TRUE, displayModeBar = FALSE)
    p
  })

  output$click_info <- renderPrint({
    req(input$imagePlot_click)
    click <- input$imagePlot_click
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
