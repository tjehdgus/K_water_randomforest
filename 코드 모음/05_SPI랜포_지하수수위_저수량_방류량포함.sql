-- SPI 랜덤포레스트 - 지하수수위, 저수량, 방류량 포함 버전
-- 테이블: dam, accper, spi, wh, weather 조인

-- 데이터 확인
select * from dam;
select * from accper;
select * from spi;
select * from wh;
select * from weather;

-- 기상 전처리 테이블 생성 (지점명 2글자로 축약)
create table weather_p
as
select substr(지점명, 1, 2) 지점명, 일시, 평균기온, 최저기온, 최고기온, 평균풍속, 평균이슬점온도, 평균상대습도, 평균증기압, 평균현지기압, 가조시간, 합계일조시간, 합계일사량, 평균지면온도
 from weather;

-- 누적강수량 전처리 테이블 생성
create table accper_p
as
select substr(지점명, 1, 2) 지점명, 일시, 일강수량, 누적강수량, 강유역
 from accper;


-- 기본 랜포 테이블 생성 (수위 포함)
drop table spi_rf;
create table spi_rf
as
select a.행정구역, a.spi6, a.가뭄, a.계절, b.누적강수량, c.가조시간, c.평균기온, c.합계일조시간, c.평균상대습도, c.평균지면온도, d.수위, e.저수량, e.방류량
 from spi a, accper b, weather c, wh d, dam e
 where a.일시 = b.일시 and a.지점명 = b.지점명 and a.일시 = c.일시 and a.지점명 = c.지점명 and a.일시 = d.일시 and a.지점명 = d.지점명 and a.일시 = e.날짜 and a.지점명 = e.지점;

select * from spi_rf;
select count(*) from spi_rf;

delete from spi_rf where 가조시간 is null;
delete from spi_rf where 평균기온 is null;
delete from spi_rf where 합계일조시간 is null;
delete from spi_rf where 평균상대습도 is null;
delete from spi_rf where 평균지면온도 is null;
delete from spi_rf where 수위 is null;


-- 전처리 테이블(accper_p, weather_p) 사용 버전 2
select * from spi_rf2;
select count(*) from spi_rf2;
create table spi_rf2
as
select a.행정구역, a.spi6, a.가뭄, a.계절, b.누적강수량, c.가조시간, c.평균기온, c.합계일조시간, c.평균상대습도, c.평균지면온도, d.수위, e.저수량, e.방류량
 from spi a, accper_p b, weather_p c, wh d, dam e
 where a.일시 = b.일시 and a.지점명 = b.지점명 and a.일시 = c.일시 and a.지점명 = c.지점명 and a.일시 = d.일시 and a.지점명 = d.지점명 and a.일시 = e.날짜 and a.지점명 = e.지점;


-- 강유역 추가 버전 3
select * from spi_rf3;
select count(*) from spi_rf3;
create table spi_rf3
as
select a.행정구역, a.spi6, a.가뭄, a.계절, b.누적강수량, c.가조시간, c.평균기온, c.합계일조시간, c.평균상대습도, c.평균지면온도, d.수위, e.저수량, e.방류량, b.강유역
 from spi a, accper_p b, weather_p c, wh d, dam e
 where a.일시 = b.일시 and a.지점명 = b.지점명 and a.일시 = c.일시 and a.지점명 = c.지점명 and a.일시 = d.일시 and a.지점명 = d.지점명 and a.일시 = e.날짜 and a.지점명 = e.지점;


-- 댐 컬럼 추가 버전 4
select * from spi_rf4;
select count(*) from spi_rf4;
create table spi_rf4
as
select a.행정구역, a.spi6, a.가뭄, a.계절, b.누적강수량, c.가조시간, c.평균기온, c.합계일조시간, c.평균상대습도, c.평균지면온도, d.수위, e.저수량, e.방류량, b.강유역, e.댐
 from spi a, accper_p b, weather_p c, wh d, dam e
 where a.일시 = b.일시 and a.지점명 = b.지점명 and a.일시 = c.일시 and a.지점명 = c.지점명 and a.일시 = d.일시 and a.지점명 = d.지점명 and a.일시 = e.날짜 and a.지점명 = e.지점;


-- 최종 랜덤포레스트용 테이블 (랜덤 셔플 포함)
drop table w;
create table w
as
select rownum as id, 행정구역, 가뭄, 계절, 누적강수량, 가조시간, 평균기온, 수위, 저수량, 방류량
 from spi_rf;

drop table ww;
create table ww
as
select 가뭄, 행정구역, 계절, 누적강수량, 가조시간, 평균기온, 수위, 저수량, 방류량
from w
order by dbms_random.value;

drop table www;
create table www
as
select rownum as id, w.*
from ww w;

select * from www;


-- 훈련/테스트 분리 (25791 기준)
drop table w_train;
create table w_train
as
select *
    from www
    where id < 25791;
drop table w_test;
create table w_test
as
select *
    from www
    where id >= 25791;
select count(*) from w_train;
select count(*) from w_test;
select * from w_train;

-- 설정 테이블 생성
DROP TABLE SETTINGS_GLM;

CREATE TABLE SETTINGS_GLM
AS
SELECT *
     FROM TABLE (DBMS_DATA_MINING.GET_DEFAULT_SETTINGS)
    WHERE SETTING_NAME LIKE '%GLM%';

BEGIN
   INSERT INTO SETTINGS_GLM
        VALUES (DBMS_DATA_MINING.ALGO_NAME, 'ALGO_RANDOM_FOREST');

   INSERT INTO SETTINGS_GLM
        VALUES (DBMS_DATA_MINING.PREP_AUTO, 'ON');

   INSERT INTO SETTINGS_GLM
        VALUES (
                  DBMS_DATA_MINING.GLMS_REFERENCE_CLASS_NAME,
                  'GLMS_RIDGE_REG_DISABLE');

   COMMIT;
END;
/

-- 3. 머신러닝 모델을 삭제합니다.
BEGIN
   DBMS_DATA_MINING.DROP_MODEL('MD_CLASSIFICATION_MODEL5');
END;
/

-- 4. 머신러닝 모델을 생성합니다.
BEGIN
   DBMS_DATA_MINING.CREATE_MODEL(
      model_name          => 'MD_CLASSIFICATION_MODEL5',
      mining_function     =>  DBMS_DATA_MINING.CLASSIFICATION,
      data_table_name     => 'W_train',
      case_id_column_name => 'ID',
      target_column_name  =>  '가뭄',
      settings_table_name => 'SETTINGS_GLM');
END;
/

-- 5. 머신러닝 모델을 확인합니다.
SELECT MODEL_NAME,
       ALGORITHM,
       MINING_FUNCTION
  FROM ALL_MINING_MODELS
 WHERE MODEL_NAME = 'MD_CLASSIFICATION_MODEL5';

-- 6. 머신러닝 모델 설정 정보를 확인합니다.
SELECT SETTING_NAME, SETTING_VALUE
FROM ALL_MINING_MODEL_SETTINGS
WHERE MODEL_NAME = 'MD_CLASSIFICATION_MODEL5';

-- 7. 모델이 예측한 결과를 확인합니다.
SELECT id, 가뭄,
 PREDICTION(MD_CLASSIFICATION_MODEL5 USING *) MODEL_PREDICT_RESPONSE
FROM w_test
order by id;

-- 8. 정확도를 출력합니다.
SELECT round(sum(decode(실제값, 예측값, 1, 0)) / count(*) * 100, 3) || '%' as 정확도
    from (SELECT id, 가뭄 실제값, PREDICTION(MD_CLASSIFICATION_MODEL5 USING *) 예측값
            FROM w_test
            order by id);
