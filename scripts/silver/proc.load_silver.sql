/*
=========================================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
==========================================================================================
 Script Purpose:
      This stored procedure performs the ETL (Extract, Transform, Load) process to
      populate the 'silver' schema tables from the 'bronze schema.
B Actions Performed:
      Truncates Silver tables.
      Inserts transformed and cleansed data from Bronze into Silver tables.
Parameters:
      None.
      This stored procedure does not accept any parameters or return any values.
Usage Example:
      EXEC Silver.load silver;
================================================================================================
*/

EXEC silver.load_silver

Create OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME,@end_time DATETIME,@batch_start_time DATETIME,@batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		print'====================================';
		print'Loading SILVER layer';
		print'====================================';

		print'-------------------------------------';
		print'Loading CRM Table';
		print'-------------------------------------';
	    
		SET @start_time = GETDATE();
    ----===================================1crm
    print'>>> TRUNCATETABLE : silver.crm_cust_info';
    TRUNCATE TABLE silver.crm_cust_info;
    print'>>> Inserting datainto : silver.crm_cust_info';
    INSERT INTO silver.crm_cust_info(
    cst_id,
    cst_KEY,
    cst_firstname,
    cst_lastname,
    cst_material_status,
    cst_gndr,
    cst_create_date
    )

    select
    cst_id,
    cst_KEY,
    TRIM(cst_firstname) As cst_firstname ,
    TRIM(cst_lastname) AS cst_lastname,
    CASE 
	    WHEN TRIM(UPPER(cst_material_status)) = 'S' THEN 'SINGLE'
	    WHEN TRIM(UPPER(cst_material_status)) = 'M' THEN 'MARRIED'
	    ELSE 'NA'
    END cst_material_status,
    CASE 
	    WHEN TRIM(UPPER(cst_gndr)) = 'F' THEN 'FEMALE'
	    WHEN TRIM(UPPER(cst_gndr)) = 'M' THEN 'MALE'
	    ELSE 'NA'
    END cst_gndr,
    cst_create_date
    from(
	    SELECT 
	    *,
	    ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date ) as flagrank
	    from bronze.crm_cust_info
    )t where flagrank = 1; 
    SET @end_time = GETDATE();
		PRINT'Load duration:' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'Second';
		PRINT'>>>--------------'
    -------==========================================================2crm
    SET @start_time = GETDATE();
    print'>>> TRUNCATETABLE : silver.crm_prd_info';
    TRUNCATE TABLE silver.crm_cust_info;
    print'>>> Inserting datainto : silver.crm_prd_info';
    INSERT INTO silver.crm_prd_info(
        prd_id,       
        Cat_id,      
        prd_key,       
        prd_nm,       
        prd_cost,      
        prd_line,      
        prd_start_dt,  
        prd_end_dt    
    )   
    select       
          prd_id,
          replace(substring(prd_key,1,5),'-','_') as cat_id,
          substring(prd_key,1,LEN(prd_key)) AS Prd_key,
          prd_nm,
          isnull(prd_cost,0) AS prd_cost,
          case upper(trim(prd_line))
               when 'R' then 'road'
               when 'M' then 'Mountied'
               when 's' then 'other sales'
               when 'T' then 'Touring'
               else 'NA'
               end AS prd_line,
          CAST(prd_start_dt AS DATE) as prd_start_dt,
          CAST(lead (prd_start_dt) over (partition by prd_key order by prd_start_dt)-1 AS DATE) as prd_end_dt_test
    from bronze.crm_prd_info
    SET @end_time = GETDATE();
		PRINT'Load duration:' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'Second';
		PRINT'>>>--------------'


    ------==========================================================3erp
    SET @start_time = GETDATE();
    print'>>> TRUNCATETABLE : silver.erp_PX_CAT_G1V2';
    TRUNCATE TABLE silver.crm_cust_info;
    print'>>> Inserting datainto : silver.erp_PX_CAT_G1V2';
    insert into silver.erp_PX_CAT_G1V2
    (
    ID,
    CAT,
    SUBCAT,
    MAINTENANCE
    )
    select 
    ID,
    CAT,
    SUBCAT,
    MAINTENANCE
    from bronze.erp_PX_CAT_G1V2;
    SET @end_time = GETDATE();
		PRINT'Load duration:' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'Second';
		PRINT'>>>--------------'

    -------------------------------------------4erp
    SET @start_time = GETDATE();
    print'>>> TRUNCATETABLE : silver.erp_LOCA101';
    TRUNCATE TABLE silver.crm_cust_info;
    print'>>> Inserting datainto : silver.erp_LOCA101';
    Insert into silver.erp_LOCA101(
    CID,
    CNTRY
    )
    select 
    REPLACE(CID,'-','') as cid,
    CASE 
	    WHEN TRIM(CNTRY)= 'DE' then 'Germany'
	    WHEN TRIM(CNTRY) IN ('US','USA') then 'United state'
	    WHEN TRIM(CNTRY)= '' or CNTRY is null then 'Germany'
	    else 'N/A'
    END as country
    from bronze.erp_LOCA101;
    SET @end_time = GETDATE();
		PRINT'Load duration:' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'Second';
		PRINT'>>>--------------'

    ------------------------------------------------------5erp
    SET @start_time = GETDATE();
    print'>>> TRUNCATETABLE : silver.erp_custAZ12';
    TRUNCATE TABLE silver.crm_cust_info;
    print'>>> Inserting datainto : silver.erp_custAZ12';
    Insert into silver.erp_custAZ12(
    CID,
    BDATE,
    GEN
    )
    select 
    CASE WHEN CID LIKE 'NAS%' then SUBSTRING(CID,4,len(CID))
	    else CID
    END as CID,
    CASE 
	    WHEN BDATE > GETDATE() THEN NULL
	    else BDATE
    END AS BDATE,
    CASE 
	    WHEN UPPER(TRIM(GEN)) in ('F','FEMALE') then 'female'
	    WHEN UPPER(TRIM(GEN)) in ('F','MALE') then 'male'
	    else 'N/A'
    END as GEN
    from bronze.erp_custAZ12;
    SET @end_time = GETDATE();
		PRINT'Load duration:' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) +'Second';
		PRINT'>>>--------------'
        	SET @batch_END_time = GETDATE();
		PRINT '=================================================';
		PRINT 'LOding bronze layer is complated';
		PRINT 'Total load duration:' + CAST(DATEDIFF(second,@batch_start_time,@batch_end_time) AS NVARCHAR) +'Second';
		PRINT '=================================================';
	END TRY
	BEGIN CATCH
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
        PRINT 'Error Message' + ERROR_MESSAGE();
        PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
	END CATCH
END
