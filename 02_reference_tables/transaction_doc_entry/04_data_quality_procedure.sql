CREATE OR ALTER PROCEDURE silver.dq_transaction_doc_entry @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    -- key is unique (uses every key column)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.transaction_doc_entry', 'key is unique', 'ERROR', COUNT(*), @now
    FROM (SELECT doc_entry_id FROM silver.transaction_doc_entry
          GROUP BY doc_entry_id HAVING COUNT(*) > 1) x;

    -- key not null
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.transaction_doc_entry', 'key not null', 'ERROR', COUNT(*), @now
    FROM silver.transaction_doc_entry
    WHERE doc_entry_id IS NULL;

    -- main column filled (warning only)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.transaction_doc_entry', 'doc_entry_name not null', 'WARN', COUNT(*), @now
    FROM silver.transaction_doc_entry
    WHERE doc_entry_name IS NULL AND _is_deleted = 0;

    -- Silver active rows = Bronze distinct keys (after filter)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.transaction_doc_entry', 'row count matches bronze', 'ERROR',
           ABS(
             (SELECT COUNT(*) FROM silver.transaction_doc_entry WHERE _is_deleted = 0)
           - (SELECT COUNT(*) FROM (SELECT DISTINCT b.TransactionDocEntryBasePEODocEntryId
                                    FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjfbiccextractam_transactiondocumententry] b WHERE b.TransactionDocEntryTLPEOLanguage = 'US') d)
           ), @now;
END;
