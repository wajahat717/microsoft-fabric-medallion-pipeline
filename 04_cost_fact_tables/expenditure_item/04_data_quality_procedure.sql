CREATE OR ALTER PROCEDURE silver.dq_expenditure_item @run_id VARCHAR(100)
AS
BEGIN
    DECLARE @now DATETIME2(6) = SYSUTCDATETIME();

    -- key is unique (uses every key column)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.expenditure_item', 'key is unique', 'ERROR', COUNT(*), @now
    FROM (SELECT expenditure_item_id FROM silver.expenditure_item
          GROUP BY expenditure_item_id HAVING COUNT(*) > 1) x;

    -- key not null
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.expenditure_item', 'key not null', 'ERROR', COUNT(*), @now
    FROM silver.expenditure_item
    WHERE expenditure_item_id IS NULL;

    -- main column filled (warning only)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.expenditure_item', 'expenditure_item_date not null', 'WARN', COUNT(*), @now
    FROM silver.expenditure_item
    WHERE expenditure_item_date IS NULL AND _is_deleted = 0;

    -- Silver active rows = Bronze distinct keys
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.expenditure_item', 'row count matches bronze', 'ERROR',
           ABS((SELECT COUNT(*) FROM silver.expenditure_item WHERE _is_deleted = 0)
             - (SELECT COUNT(DISTINCT b.PjcExpItemsAllExpenditureItemId) FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjcbiccextractam_expenditureitem] b)), @now;

    -- extra test (Task 9)
    INSERT INTO ops.dq_result
    SELECT @run_id, 'silver.expenditure_item', 'waste number has text but converts to NULL', 'WARN',
           (SELECT COUNT(*) FROM [bronze_lakehouse].[bronze].[br_oracle_fusion_fscm_prjextractam_pjcbiccextractam_expenditureitem] b
              WHERE (b.PjcExpItemsAllUserDefAttribute1 IS NOT NULL AND TRY_CAST(b.PjcExpItemsAllUserDefAttribute1 AS DECIMAL(19,4)) IS NULL)
                 OR (b.PjcExpItemsAllUserDefAttribute5 IS NOT NULL AND TRY_CAST(b.PjcExpItemsAllUserDefAttribute5 AS DECIMAL(19,4)) IS NULL)
                 OR (b.PjcExpItemsAllUserDefAttribute8 IS NOT NULL AND TRY_CAST(b.PjcExpItemsAllUserDefAttribute8 AS DECIMAL(19,4)) IS NULL)), @now;
END;
