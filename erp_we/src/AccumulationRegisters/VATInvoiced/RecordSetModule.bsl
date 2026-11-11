#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	// Verification of fraud.Loading is not required, because this object in the RIB must create tasks when writing.
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text =
		"SELECT
		|	Table.Period                     AS Period,
		|	Table.Organization                AS Organization,
		|	Table.TaxInvoice                AS TaxInvoice,
		|	Table.Vendor                  AS Vendor,
		|	Table.AssetTaxClass                AS AssetTaxClass,
		|	Table.VATRate                  AS VATRate,
		|	Table.VATActivityType         AS VATActivityType,
		|	Table.CorrectedTaxInvoice    AS CorrectedTaxInvoice,
		|	Table.SaleExport          AS SaleExport,
		|	Table.Event                    AS Event,
		|	Table.CorVATActivityTypes      AS CorVATActivityTypes,
		|	Table.RowID        AS RowID,
		|	Table.PeriodEndTransaction       AS PeriodEndTransaction,
		|	Table.Department              AS Department,
		|	Table.LineOfBusiness    AS LineOfBusiness,
		|	Table.CorLineOfBusiness AS CorLineOfBusiness,
		|	Table.ExpenseItem             AS ExpenseItem,
		|	Table.DimensionOfExpenses          AS DimensionOfExpenses,
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Table.AmountExcludingVAT
		|		ELSE -Table.AmountExcludingVAT
		|	END AS AmountExcludingVATBeforeWrite,
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Table.VAT
		|		ELSE -Table.VAT
		|	END AS VATBeforeWrite,
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Table.VATManag
		|		ELSE -Table.VATManag
		|	END AS VATManagBeforeWrite
		|INTO VATInvoicedBeforeWrite
		|FROM
		|	AccumulationRegister.VATInvoiced AS Table
		|WHERE
		|	Table.Recorder = &Recorder";
	
	Query.Execute();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	// Verification of fraud.Loading is not required, because this object in the RIB must create tasks when writing.
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	// The change of the new set relative to the current one is calculated taking into account the accumulated changes
	// and placed in a temporary table.
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	
	QueryText =
		"SELECT
		|	ChangesTable.Period                      AS Period,
		|	ChangesTable.Organization                 AS Organization,
		|	ChangesTable.TaxInvoice                 AS TaxInvoice,
		|	ChangesTable.Vendor                   AS Vendor,
		|	ChangesTable.AssetTaxClass                 AS AssetTaxClass,
		|	ChangesTable.VATRate                   AS VATRate,
		|	ChangesTable.VATActivityType          AS VATActivityType,
		|	ChangesTable.CorrectedTaxInvoice     AS CorrectedTaxInvoice,
		|	ChangesTable.SaleExport           AS SaleExport,
		|	ChangesTable.Event                     AS Event,
		|	ChangesTable.CorVATActivityTypes       AS CorVATActivityTypes,
		|	ChangesTable.RowID         AS RowID,
		|	ChangesTable.PeriodEndTransaction        AS PeriodEndTransaction,
		|	ChangesTable.Department               AS Department,
		|	ChangesTable.LineOfBusiness     AS LineOfBusiness,
		|	ChangesTable.CorLineOfBusiness  AS CorLineOfBusiness,
		|	ChangesTable.ExpenseItem              AS ExpenseItem,
		|	ChangesTable.DimensionOfExpenses           AS DimensionOfExpenses,
		|	SUM(ChangesTable.AmountExcludingVATUpdate) AS AmountExcludingVATUpdate,
		|	SUM(ChangesTable.VATUpdate)         AS VATUpdate,
		|	SUM(ChangesTable.VATManagUpdate)      AS VATManagUpdate
		|INTO VATInvoicedUpdate
		|FROM
		|	(SELECT
		|		Table.Period                     AS Period,
		|		Table.Organization                AS Organization,
		|		Table.TaxInvoice                AS TaxInvoice,
		|		Table.Vendor                  AS Vendor,
		|		Table.AssetTaxClass                AS AssetTaxClass,
		|		Table.VATRate                  AS VATRate,
		|		Table.VATActivityType         AS VATActivityType,
		|		Table.CorrectedTaxInvoice    AS CorrectedTaxInvoice,
		|		Table.SaleExport          AS SaleExport,
		|		Table.Event                    AS Event,
		|		Table.CorVATActivityTypes      AS CorVATActivityTypes,
		|		Table.RowID        AS RowID,
		|		Table.PeriodEndTransaction       AS PeriodEndTransaction,
		|		Table.Department              AS Department,
		|		Table.LineOfBusiness    AS LineOfBusiness,
		|		Table.CorLineOfBusiness AS CorLineOfBusiness,
		|		Table.ExpenseItem             AS ExpenseItem,
		|		Table.DimensionOfExpenses          AS DimensionOfExpenses,
		|		Table.AmountExcludingVATBeforeWrite    AS AmountExcludingVATUpdate,
		|		Table.VATBeforeWrite            AS VATUpdate,
		|		Table.VATManagBeforeWrite         AS VATManagUpdate
		|	FROM
		|		VATInvoicedBeforeWrite AS Table
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Table.Period                     AS Period,
		|		Table.Organization                AS Organization,
		|		Table.TaxInvoice                AS TaxInvoice,
		|		Table.Vendor                  AS Vendor,
		|		Table.AssetTaxClass                AS AssetTaxClass,
		|		Table.VATRate                  AS VATRate,
		|		Table.VATActivityType         AS VATActivityType,
		|		Table.CorrectedTaxInvoice    AS CorrectedTaxInvoice,
		|		Table.SaleExport          AS SaleExport,
		|		Table.Event                    AS Event,
		|		Table.CorVATActivityTypes      AS CorVATActivityTypes,
		|		Table.RowID        AS RowID,
		|		Table.PeriodEndTransaction       AS PeriodEndTransaction,
		|		Table.Department              AS Department,
		|		Table.LineOfBusiness    AS LineOfBusiness,
		|		Table.CorLineOfBusiness AS CorLineOfBusiness,
		|		Table.ExpenseItem             AS ExpenseItem,
		|		Table.DimensionOfExpenses          AS DimensionOfExpenses,
		|		CASE
		|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -Table.AmountExcludingVAT
		|			ELSE Table.AmountExcludingVAT
		|		END,
		|		CASE
		|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -Table.VAT
		|			ELSE Table.VAT
		|		END,
		|		CASE
		|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -Table.VATManag
		|			ELSE Table.VATManag
		|		END
		|	FROM
		|		AccumulationRegister.VATInvoiced AS Table
		|	WHERE
		|		Table.Recorder = &Recorder) AS ChangesTable
		|
		|GROUP BY
		|	ChangesTable.Period,
		|	ChangesTable.Organization,
		|	ChangesTable.TaxInvoice,
		|	ChangesTable.Vendor,
		|	ChangesTable.AssetTaxClass,
		|	ChangesTable.VATRate,
		|	ChangesTable.VATActivityType,
		|	ChangesTable.CorrectedTaxInvoice,
		|	ChangesTable.SaleExport,
		|	ChangesTable.Event,
		|	ChangesTable.CorVATActivityTypes,
		|	ChangesTable.RowID,
		|	ChangesTable.PeriodEndTransaction,
		|	ChangesTable.Department,
		|	ChangesTable.LineOfBusiness,
		|	ChangesTable.CorLineOfBusiness,
		|	ChangesTable.ExpenseItem,
		|	ChangesTable.DimensionOfExpenses
		|
		|HAVING
		|	(SUM(ChangesTable.AmountExcludingVATUpdate) <> 0 
		|		OR SUM(ChangesTable.VATUpdate) <> 0
		|		OR SUM(ChangesTable.VATManagUpdate) <> 0) 
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	BEGINOFPERIOD(ChangesTable.Period, MONTH) AS Month,
		|	ChangesTable.Organization AS Organization,
		|	ChangesTable.TaxInvoice AS TaxInvoice
		|INTO TTName
		|FROM
		|	VATInvoicedUpdate AS ChangesTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP VATInvoicedBeforeWrite";
	
	TTName = Metadata().Name + "_JobsForGeneratingVATRecords";
	QueryText = StrReplace(QueryText, "TTName", TTName);
	
	Query.Text = QueryText;
	Result = Query.ExecuteBatch();
	Selection = Result[1].Select();
	
	DocumentsPosting.RegisterControlTable(
		AdditionalProperties,
		TTName,
		Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf