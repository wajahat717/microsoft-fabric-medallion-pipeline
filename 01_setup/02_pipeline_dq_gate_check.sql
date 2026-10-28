/* Used by the pipeline's Lookup activity ("DQ check") after all loads finish.
   If error_count > 0, the If Condition sends the run to a Fail activity,
   so bad data never reaches the Gold layer or Power BI.

   In the pipeline, @run_id is passed as @pipeline().RunId. */

SELECT COUNT(*) AS error_count
FROM ops.dq_result
WHERE run_id = @run_id
  AND severity = 'ERROR'
  AND failed_rows > 0;
