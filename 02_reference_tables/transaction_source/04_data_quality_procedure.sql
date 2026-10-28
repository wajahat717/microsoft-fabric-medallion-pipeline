CREATE OR ALTER PROCEDURE silver.dq_transaction_source @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    -- key is unique (uses every key column)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.transaction_source', 'key is unique', 'ERROR', COUNT(*), @now
    FROM (SELECT transaction_source_id FROM silver.transaction_source
          GROUP BY transaction_source_id HAVING COUNT(*) > 1) x;

    -- key not null
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.transaction_source', 'key not null', 'ERROR', COUNT(*), @now
    FROM silver.transaction_source
    WHERE transaction_source_id IS NULL;

    -- main column filled (warning only)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.transaction_source', 'user_transaction_source not null', 'WARN', COUNT(*), @now
    FROM silver.transaction_source
    WHERE user_transaction_source IS NULL AND _is_deleted = 0;

    -- Silver active rows = Bronze distinct keys (after filter)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.transaction_source', 'row count matches bronze', 'ERROR',
           ABS(
             (SELECT COUNT(*) FROM silver.transaction_source WHERE _is_deleted = 0)
           - (SELECT COUNT(*) FROM (SELECT DISTINCT b.TransactionSourceBasePEOTransactionSourceId
                                    FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjfbiccextractam_transactionsource] b WHERE b.TransactionSourceTLPEOLanguage = 'US') d)
           ), @now;
END;
