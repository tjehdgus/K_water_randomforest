-- SPI 머신러닝 필요 데이터 테이블 생성
-- 관련 CSV: OBS_ASOS_DD_20240704193011.csv, 누적강수량.csv, 가뭄데이터전처리최종.csv, spi지수 예측관련 기상 데이터.csv

-- 기본 테이블 생성 (초기 버전)
drop table w;
create table w
as
select rownum as id, s.spi6, d.누적강수량,
w.가조시간,
w.평균지면온도, w.합계소형증발량
    from weather w, drou s, addw d
    where s.일시 = w.일시 and s.지점명 = w.지점명 and w.일시 = d.일시 and w.지점명 = d.지점명;


-- 전체 변수 포함 버전
create table w
as
select rownum as id, s.spi6, d.누적강수량,
w.최대풍속,
w.최대풍속풍향,
w.최다풍향,
w.최소상대습도,
w.평균상대습도,
w.평균증기압,
w.평균현지기압,
w.최고해면기압,
w.평균해면기압,
w.가조시간,
w.합계일조시간,
w.평균전운량,
w.평균중하층운량,
w.평균지면온도,
w.최저초상온도,
w.합계소형증발량,
w.최고기온,
w.최대순간풍속
    from weather w, drou s, addw d
    where s.일시 = w.일시 and s.지점명 = w.지점명 and s.일시 = d.일시 and s.지점명 = d.지점명;

-- null 값 제거
delete from  w where 최대순간풍속시각 is null;
delete from  w where 최대풍속 is null;
delete from  w where 최대풍속풍향 is null;
delete from  w where 최대풍속시각 is null;
delete from  w where 평균풍속 is null;
delete from  w where 풍정합 is null;
delete from  w where 최다풍향 is null;
delete from  w where 평균이슬점온도 is null;
delete from  w where 최소상대습도 is null;
delete from  w where 최소상대습도시각 is null;
delete from  w where 평균상대습도 is null;
delete from  w where 평균증기압 is null;
delete from  w where 평균현지기압 is null;
delete from  w where 최고해면기압 is null;
delete from  w where 최고해면기압시각 is null;
delete from  w where 최저해면기압 is null;
delete from  w where 최저해면기압시각 is null;
delete from  w where 평균해면기압 is null;
delete from  w where 가조시간 is null;
delete from  w where 합계일조시간 is null;
delete from  w where 최다일사시각1H is null;
delete from  w where 최다일사량1H is null;
delete from  w where 합계일사량 is null;
delete from  w where 일최심신적설 is null;
delete from  w where 일최심신적설시각 is null;
delete from  w where 일최심적설 is null;
delete from  w where 일최심적설시각 is null;
delete from  w where 합계3시간신적설 is null;
delete from  w where 평균전운량 is null;
delete from  w where 평균중하층운량 is null;
delete from  w where 평균지면온도 is null;
delete from  w where 최저초상온도 is null;
delete from  w where 평균5CM지중온도 is null;
delete from  w where 평균10CM지중온도 is null;
delete from  w where 평균20CM지중온도 is null;
delete from  w where 평균30CM지중온도 is null;
delete from  w where 지중온도0_5 is null;
delete from  w where 지중온도1 is null;
delete from  w where 지중온도1_5 is null;
delete from  w where 지중온도3 is null;
delete from  w where 지중온도5 is null;
delete from  w where 합계대형증발량 is null;
delete from  w where 합계소형증발량 is null;
delete from  w where 강수99 is null;
delete from  w where 안개계속시간 is null;
delete from  w where 평균기온 is null;
delete from  w where 최저기온 is null;
delete from  w where 최저기온시각 is null;
delete from  w where 최고기온 is null;
delete from  w where 최고기온시각 is null;
delete from  w where 강수계속시간 is null;
delete from  w where 최다강수량10 is null;
delete from  w where 최다강수량시각10 is null;
delete from  w where 최다강수량1H is null;
delete from  w where 최다강수량시각1H is null;
delete from  w where 일강수량 is null;
delete from  w where 최대순간풍속 is null;
delete from  w where 최대순간풍속풍향 is null;
