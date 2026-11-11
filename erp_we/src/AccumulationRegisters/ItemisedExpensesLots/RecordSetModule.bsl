#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load
		Or CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		Return;
	EndIf;
	
	If Not CostCalculationAppliedAlgorithms.GenerateRegisteredRecordsOfCostAccountingRegisters(ThisObject) Then
		Return;
	EndIf;
	
	CostCalculationAppliedAlgorithms.SaveRegisteredRecordsGeneratedByCalculationOfBatchesAndCosts(ThisObject, Replacing);
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	Query = New Query("
	|SELECT
	|	LotsOfExpenses.Period                       AS Period,
	|	LotsOfExpenses.Recorder                  AS Recorder,
	|	LotsOfExpenses.Organization                  AS Organization,
	|	LotsOfExpenses.Department                AS Department,
	|	LotsOfExpenses.ExpenseItem               AS ExpenseItem,
	|	LotsOfExpenses.DimensionOfExpenses            AS DimensionOfExpenses,
	|	LotsOfExpenses.AssetsLiabilitiesDimension     AS AssetsLiabilitiesDimension,
	|	LotsOfExpenses.ExpenseReceiptDocument  AS ExpenseReceiptDocument,
	|	LotsOfExpenses.LotVendorAttributes         AS LotVendorAttributes,
	|	LotsOfExpenses.LineOfBusiness      AS LineOfBusiness,
	|	LotsOfExpenses.ItemsLocationAttributes   AS ItemsLocationAttributes,
	|	LotsOfExpenses.VATActivityType           AS VATActivityType,
	|	LotsOfExpenses.VariancePeriod           	AS VariancePeriod,
	|	LotsOfExpenses.Cost                    AS Cost,
	|	LotsOfExpenses.CostExcludingVAT              AS CostExcludingVAT,
	|	LotsOfExpenses.LocalCost                AS LocalCost,
	|	LotsOfExpenses.VATLocal                      AS VATLocal,
	|	LotsOfExpenses.PermanentDifference            AS PermanentDifference,
	|	LotsOfExpenses.CostTD             AS CostTD,
	|	LotsOfExpenses.VATManag                       AS VATManag
	|
	|INTO ItemisedExpensesLotsBeforeWrite
	|FROM
	|	AccumulationRegister.ItemisedExpensesLots AS LotsOfExpenses
	|WHERE
	|	LotsOfExpenses.Recorder = &Recorder
	|	AND (LotsOfExpenses.RecordType = VALUE(AccumulationRecordType.Receipt) OR &ThisIsCancellationOfEvent)
	|");
	
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	ThisIsCancellationOfEvent = AdditionalProperties.DocumentProperties.WriteMode = DocumentWriteMode.UndoPosting;
	Query.SetParameter("ThisIsCancellationOfEvent", ThisIsCancellationOfEvent);
	
	Query.Execute();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Or Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or ExchangePlans.MasterNode() <> Undefined
		Or CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		Return;
	EndIf;
	
	If Not CostCalculationAppliedAlgorithms.GenerateRegisteredRecordsOfCostAccountingRegisters(ThisObject) Then
		Return;
	EndIf;
	
	ArrayOfRequestTexts = New Array;
	
	TextOfChangeTable = 
	"SELECT
	|	Table.Period                           AS Period,
	|	Table.Recorder                      AS Recorder,
	|	Table.Department                    AS Department,
	|	Table.Organization                      AS Organization,
	|	Table.ExpenseItem                   AS ExpenseItem,
	|	Table.CostAllocationOptionManag  AS CostAllocationOptionManag,
	|	Table.CostAllocationOptionLocal AS CostAllocationOptionLocal,
	|	Table.VATAssetTaxClass                   AS VATAssetTaxClass,
	|	Table.DimensionOfExpenses                AS DimensionOfExpenses,
	|	Table.ExpenseReceiptDocument      AS ExpenseReceiptDocument,
	|	Table.LotVendorAttributes             AS LotVendorAttributes,
	|	Table.ItemsLocationAttributes       AS ItemsLocationAttributes,
	|	Table.LineOfBusiness          AS LineOfBusiness,
	|	Table.VATActivityType               AS VATActivityType,
	|	Table.VariancePeriod           		 AS VariancePeriod,
	|	SUM(Table.Cost)                 AS Cost,
	|	SUM(Table.CostExcludingVAT)           AS CostExcludingVAT,
	|	SUM(Table.LocalCost)             AS LocalCost,
	|	SUM(Table.VATLocal)                   AS VATLocal,
	|	SUM(Table.PermanentDifference)         AS PermanentDifference,
	|	SUM(Table.CostTD)          AS CostTD,
	|	SUM(Table.VATManag)                    AS VATManag
	|INTO ChangesTableItemisedExpensesLots
	|FROM
	|	(SELECT
	|		Table.Period                         			AS Period,
	|		Table.Recorder                     		AS Recorder,
	|		Table.Department                   		AS Department,
	|		Table.Organization                     		AS Organization,
	|		Table.ExpenseItem                  		AS ExpenseItem,
	|		ExpenseItems.CostAllocationOptionManag 	AS CostAllocationOptionManag,
	|		ExpenseItems.CostAllocationOptionLocal AS CostAllocationOptionLocal,
	|		ExpenseItems.VATAssetTaxClass           		AS VATAssetTaxClass,
	|		Table.DimensionOfExpenses               		AS DimensionOfExpenses,
	|		Table.ExpenseReceiptDocument     		AS ExpenseReceiptDocument,
	|		Table.LotVendorAttributes            		AS LotVendorAttributes,
	|		Table.ItemsLocationAttributes      		AS ItemsLocationAttributes,
	|		Table.LineOfBusiness      			AS LineOfBusiness,
	|		CASE
	|			WHEN Table.VATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|				THEN Table.VATActivityType
	|			ELSE Table.LotVendorAttributes.VATTaxation
	|		END                                           AS VATActivityType,
	|		Table.VariancePeriod           				AS VariancePeriod,
	|		Table.Cost                               AS Cost,
	|		Table.CostExcludingVAT                         AS CostExcludingVAT,
	|		Table.LocalCost                   		AS LocalCost,
	|		Table.VATLocal                         		AS VATLocal,
	|		Table.PermanentDifference                       AS PermanentDifference,
	|		Table.CostTD                        AS CostTD,
	|		Table.VATManag                         			AS VATManag
	|	FROM
	|		ItemisedExpensesLotsBeforeWrite AS Table
	|		LEFT JOIN
	|			ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON
	|			Table.ExpenseItem =  ExpenseItems.Ref
	|
	|	UNION ALL
	|	
	|	SELECT
	|		LotsOfExpenses.Period                       	AS Period,
	|		LotsOfExpenses.Recorder                  	AS Recorder,
	|		LotsOfExpenses.Department                	AS Department,
	|		LotsOfExpenses.Organization                  	AS Organization,
	|		LotsOfExpenses.ExpenseItem               	AS ExpenseItem,
	|		ExpenseItems.CostAllocationOptionManag 	AS CostAllocationOptionManag,
	|		ExpenseItems.CostAllocationOptionLocal AS CostAllocationOptionLocal,
	|		ExpenseItems.VATAssetTaxClass               	AS VATAssetTaxClass,
	|		LotsOfExpenses.DimensionOfExpenses            	AS DimensionOfExpenses,
	|		LotsOfExpenses.ExpenseReceiptDocument  	AS ExpenseReceiptDocument,
	|		LotsOfExpenses.LotVendorAttributes         	AS LotVendorAttributes,
	|		LotsOfExpenses.ItemsLocationAttributes   	AS ItemsLocationAttributes,
	|		LotsOfExpenses.LineOfBusiness      	AS LineOfBusiness,
	|		CASE
	|			WHEN LotsOfExpenses.VATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|				THEN LotsOfExpenses.VATActivityType
	|			ELSE LotsOfExpenses.LotVendorAttributes.VATTaxation
	|		END                                           AS VATActivityType,
	|		LotsOfExpenses.VariancePeriod           		AS VariancePeriod,
	|		-LotsOfExpenses.Cost                       AS Cost,
	|		-LotsOfExpenses.CostExcludingVAT                 AS CostExcludingVAT,
	|		-LotsOfExpenses.LocalCost               	AS LocalCost,
	|		-LotsOfExpenses.VATLocal                    		AS VATLocal,
	|		-LotsOfExpenses.PermanentDifference               AS PermanentDifference,
	|		-LotsOfExpenses.CostTD                AS CostTD,
	|		-LotsOfExpenses.VATManag                         	AS VATManag
	|	FROM
	|		AccumulationRegister.ItemisedExpensesLots AS LotsOfExpenses
	|		LEFT JOIN
	|			ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON
	|			LotsOfExpenses.ExpenseItem =  ExpenseItems.Ref
	|	WHERE
	|		LotsOfExpenses.Recorder = &Recorder
	|		AND LotsOfExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|
	|) AS Table
	|
	|GROUP BY
	|	Table.Period,
	|	Table.Recorder,
	|	Table.Organization,
	|	Table.Department,
	|	Table.ExpenseItem,
	|	Table.CostAllocationOptionManag,
	|	Table.CostAllocationOptionLocal,
	|	Table.VATAssetTaxClass,
	|	Table.DimensionOfExpenses,
	|	Table.ExpenseReceiptDocument,
	|	Table.LotVendorAttributes,
	|	Table.ItemsLocationAttributes,
	|	Table.LineOfBusiness,
	|	Table.VATActivityType,
	|	Table.VariancePeriod
	|HAVING
	|	SUM(Table.Cost) <> 0
	|	OR SUM(Table.CostExcludingVAT) <> 0
	|	OR SUM(Table.LocalCost) <> 0
	|	OR SUM(Table.VATLocal) <> 0
	|	OR SUM(Table.PermanentDifference) <> 0
	|	OR SUM(Table.CostTD) <> 0
	|	OR SUM(Table.VATManag) <> 0
	|";
	ArrayOfRequestTexts.Add(TextOfChangeTable);
	ArrayOfRequestTexts.Add("DROP ItemisedExpensesLotsBeforeWrite");
	
	Query = New Query();
	Query.Text = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
	
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Query.Execute();
	
EndProcedure

#EndRegion

#EndIf
