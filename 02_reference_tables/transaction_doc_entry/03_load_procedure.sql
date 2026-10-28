CREATE OR ALTER PROCEDURE silver.load_transaction_doc_entry @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    DROP TABLE IF EXISTS silver.stg_transaction_doc_entry;

    CREATE TABLE silver.stg_transaction_doc_entry AS
    SELECT
        x.doc_entry_id, x.doc_entry_name,
        x.source_last_update_date,
        CAST(HASHBYTES('SHA2_256', CONCAT(
            x.doc_entry_name, '|'
        )) AS VARBINARY(32)) AS _row_hash
    FROM (
        SELECT
            b.TransactionDocEntryBasePEODocEntryId                         AS doc_entry_id,
            CAST(b.TransactionDocEntryTLPEODocEntryName AS VARCHAR(240))   AS doc_entry_name,
            b.TransactionDocEntryBasePEOLastUpdateDate                     AS source_last_update_date,
            ROW_NUMBER() OVER (
                PARTITION BY b.TransactionDocEntryBasePEODocEntryId
                ORDER BY b.TransactionDocEntryBasePEOLastUpdateDate DESC, b._LoadDTS DESC
            ) AS rn
        FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjfbiccextractam_transactiondocumententry] b
        WHERE b.TransactionDocEntryTLPEOLanguage = 'US'
    ) x
    WHERE x.rn = 1;

    UPDATE t
    SET
        t.doc_entry_name           = s.doc_entry_name,
        t.source_last_update_date  = s.source_last_update_date,
        t._row_hash                = s._row_hash,
        t._silver_loaded_at        = @now,
        t._is_deleted              = 0,
        t._run_id                  = @run_id
    FROM silver.transaction_doc_entry t
    INNER JOIN silver.stg_transaction_doc_entry s
        ON t.doc_entry_id = s.doc_entry_id
    WHERE t._row_hash <> s._row_hash
       OR t._is_deleted = 1;

    INSERT INTO silver.transaction_doc_entry
        (doc_entry_id, doc_entry_name,
         source_last_update_date, _row_hash, _silver_loaded_at, _is_deleted, _run_id)
    SELECT s.doc_entry_id, s.doc_entry_name,
           s.source_last_update_date, s._row_hash, @now, 0, @run_id
    FROM silver.stg_transaction_doc_entry s
    WHERE NOT EXISTS (SELECT 1 FROM silver.transaction_doc_entry t
                      WHERE t.doc_entry_id = s.doc_entry_id);

    UPDATE t
    SET t._is_deleted = 1, t._silver_loaded_at = @now, t._run_id = @run_id
    FROM silver.transaction_doc_entry t
    WHERE t._is_deleted = 0
      AND NOT EXISTS (SELECT 1 FROM silver.stg_transaction_doc_entry s
                      WHERE s.doc_entry_id = t.doc_entry_id);

    DROP TABLE IF EXISTS silver.stg_transaction_doc_entry;
END;
