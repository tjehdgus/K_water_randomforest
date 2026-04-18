-- SPI 랜포 최종 - 저수량 포함 (행정구역, 저수량 변수 추가)
-- 관련 CSV: spi랜포14-22(85퍼)저수량평균O.csv, spi19-22랜포(89퍼)저수량평균X.csv
--           spi19-22랜포(88퍼)저수량평균O.csv, spi18-22랜포(90퍼)저수량평균X.csv

-- 행정구역+저수량 포함 테이블 생성
drop table w;
create table w
as
select rownum as id, s.가뭄, d.누적강수량, s.계절, w.가조시간, w.평균기온, s.행정구역, a.저수량
    from weather w, drought s, water d, dam a
    where a.날짜 = w.일시 and a.지점 = w.지점명 and a.날짜 = s.일시 and a.지점 = s.지점명
    and a.날짜 = d.일시 and a.지점 = d.지점명;

delete from  w where 가조시간 is null;
delete from  w where 평균기온 is null;
select count(*) from w;

-- 랜덤으로 섞기
create table ww
as
SELECT 가뭄, 누적강수량, 계절, 가조시간, 평균기온, 행정구역, 저수량 FROM w ORDER BY DBMS_RANDOM.VALUE;

drop table w;
create table w
as
select rownum as id, 가뭄, 누적강수량, 계절, 가조시간, 평균기온, 행정구역, 저수량
    from ww;

drop table ww;


-- 훈련/테스트 분리 (37700 기준)
drop table w_train;
create table w_train
as
select *
    from w
    where id < 37700;
drop table w_test;
create table w_test
as
select *
    from w
    where id >= 37700;
select count(*) from w_train;
select count(*) from w_test;
select * from w_test;

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
   DBMS_DATA_MINING.DROP_MODEL('MD_CLASSIFICATION_MODEL4');
END;
/

-- 4. 머신러닝 모델을 생성합니다.
BEGIN
   DBMS_DATA_MINING.CREATE_MODEL(
      model_name          => 'MD_CLASSIFICATION_MODEL4',
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
 WHERE MODEL_NAME = 'MD_CLASSIFICATION_MODEL4';

-- 6. 머신러닝 모델 설정 정보를 확인합니다.
SELECT SETTING_NAME, SETTING_VALUE
FROM ALL_MINING_MODEL_SETTINGS
WHERE MODEL_NAME = 'MD_CLASSIFICATION_MODEL4';

-- 7. 모델이 예측한 결과를 확인합니다.
SELECT id, 가뭄,
 PREDICTION(MD_CLASSIFICATION_MODEL4 USING *) MODEL_PREDICT_RESPONSE
FROM w_test
order by id;

-- 8. 정확도를 출력합니다.
SELECT round(sum(decode(실제값, 예측값, 1, 0)) / count(*) * 100, 3) || '%' as 정확도
    from (SELECT id, 가뭄 실제값, PREDICTION(MD_CLASSIFICATION_MODEL4 USING *) 예측값
            FROM w_test
            order by id);
