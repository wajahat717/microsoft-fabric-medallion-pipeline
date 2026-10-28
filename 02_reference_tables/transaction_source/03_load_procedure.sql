CREATE OR ALTER PROCEDURE silver.load_transaction_source @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    DROP TABLE IF EXISTS silver.stg_transaction_source;

    CREATE TABLE silver.stg_transaction_source AS
    SELECT
        x.transaction_source_id, x.user_transaction_source,
        x.source_last_update_date,
        CAST(HASHBYTES('SHA2_256', CONCAT(
            x.user_transaction_source, '|'
        )) AS VARBINARY(32)) AS _row_hash
    FROM (
        SELECT
            b.TransactionSourceBasePEOTransactionSourceId                  AS transaction_source_id,
            CAST(b.TransactionSourceTLPEOUserTransactionSource AS VARCHAR(240)) AS user_transaction_source,
            b.TransactionSourceBasePEOLastUpdateDate                       AS source_last_update_date,
            ROW_NUMBER() OVER (
                PARTITION BY b.TransactionSourceBasePEOTransactionSourceId
                ORDER BY b.TransactionSourceBasePEOLastUpdateDate DESC, b._LoadDTS DESC
            ) AS rn
        FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjfbiccextractam_transactionsource] b
        WHERE b.TransactionSourceTLPEOLanguage = 'US'
    ) x
    WHERE x.rn = 1;

    UPDATE t
    SET
        t.user_transaction_source  = s.user_transaction_source,
        t.source_last_update_date  = s.source_last_update_date,
        t._row_hash                = s._row_hash,
        t._silver_loaded_at        = @now,
        t._is_deleted              = 0,
        t._run_id                  = @run_id
    FROM silver.transaction_source t
    INNER JOIN silver.stg_transaction_source s
        ON t.transaction_source_id = s.transaction_source_id
    WHERE t._row_hash <> s._row_hash
       OR t._is_deleted = 1;

    INSERT INTO silver.transaction_source
        (transaction_source_id, user_transaction_source,
         source_last_update_date, _row_hash, _silver_loaded_at, _is_deleted, _run_id)
    SELECT s.transaction_source_id, s.user_transaction_source,
           s.source_last_update_date, s._row_hash, @now, 0, @run_id
    FROM silver.stg_transaction_source s
    WHERE NOT EXISTS (SELECT 1 FROM silver.transaction_source t
                      WHERE t.transaction_source_id = s.transaction_source_id);

    UPDATE t
    SET t._is_deleted = 1, t._silver_loaded_at = @now, t._run_id = @run_id
    FROM silver.transaction_source t
    WHERE t._is_deleted = 0
      AND NOT EXISTS (SELECT 1 FROM silver.stg_transaction_source s
                      WHERE s.transaction_source_id = t.transaction_source_id);

    DROP TABLE IF EXISTS silver.stg_transaction_source;
END;
