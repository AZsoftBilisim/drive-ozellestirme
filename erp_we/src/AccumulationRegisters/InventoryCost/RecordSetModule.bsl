#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		PrepareDataForRegisteringTasksInNonOperationalQueue();
		Return;
	EndIf;
	
	ChangedPeriods = New Array;
	
	If CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		
		If AdditionalProperties.Property("AddRegisteredRecordsFromInformationSecurityForPeriod") Then
			
			If Not CostCalculationAppliedAlgorithms.GenerateRegisteredRecordsOfCostAccountingRegisters(ThisObject) Then
				Return;
			EndIf;
			
			AdditionalProperties.Insert("ExactlyNeedToSaveMovement");
			
			// Let's keep the primary movements unchanged.
			SaveYourRegisteredRecords = SaveUnchangedPrimaryRegisteredRecords(ChangedPeriods);
			
			// Let's save the calculated movements for the periods in which there are primary movements.
			CostCalculationAppliedAlgorithms.SaveRegisteredRecordsGeneratedByCalculationOfBatchesAndCosts(ThisObject, Replacing, ChangedPeriods);
			
		EndIf;
		
		Return;
	EndIf;
	
	PrepareDataForRegisteringTasksInNonOperationalQueue();
	
	If Not CostCalculationAppliedAlgorithms.GenerateRegisteredRecordsOfCostAccountingRegisters(ThisObject) Then
		Return;
	EndIf;
	
	// Let's keep the primary movements unchanged.
	SaveYourRegisteredRecords = SaveUnchangedPrimaryRegisteredRecords(ChangedPeriods);
	
	If SaveYourRegisteredRecords
	 Or AdditionalProperties.Property("OnlyStateOfTransferOfOwnershipHasChanged")
	 And AdditionalProperties.OnlyStateOfTransferOfOwnershipHasChanged Then
		// Let's save the calculated movements for the periods in which there are primary movements.
		CostCalculationAppliedAlgorithms.SaveRegisteredRecordsGeneratedByCalculationOfBatchesAndCosts(ThisObject, Replacing, ChangedPeriods);
	EndIf;
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	*
	|INTO InventoryCostBeforeWrite
	|FROM
	|	AccumulationRegister.InventoryCost AS Cost_
	|WHERE
	|	Cost_.Recorder = &Recorder";
	
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Query.Execute();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		CreateNonOperationalQueueJobsWhenWriting();
		Return;
	EndIf;
	
	If CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		Return;
	EndIf;
	
	CreateNonOperationalQueueJobsWhenWriting();
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	If Not CostCalculationAppliedAlgorithms.GenerateRegisteredRecordsOfCostAccountingRegisters(ThisObject) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Table.Period AS Period,
	|	Table.RecordType AS RecordType,
	|	Table.CostAccountingTransaction AS CostAccountingTransaction,
	|	Table.Recorder AS Recorder,
	|	Table.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Table.AccountingSection AS AccountingSection,
	|	Table.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Table.Organization AS Organization,
	|	Table.Lot AS Lot,
	|	Table.LotVendorAttributes AS LotVendorAttributes,
	|	Table.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	Table.VATActivityType AS VATActivityType,
	|	Table.BusinessOperation AS BusinessOperation,
	|	Table.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	Table.CorAccountingSection AS CorAccountingSection,
	|	Table.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	Table.CorCompany AS CorCompany,
	|	Table.CorGrossInitialCostENT AS CorGrossInitialCostENT,
	|	Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Table.SalesOrder AS SalesOrder,
	|	Table.Department AS Department,
	|	Table.DimensionOfExpenses AS DimensionOfExpenses,
	|	Table.ExpenseItemOfWriteOff AS ExpenseItemOfWriteOff,
	|	Table.IncomeItem AS IncomeItem,
	|	Table.DimensionOfRevenue AS DimensionOfRevenue,
	|	Table.SalePeriod AS SalePeriod,
	|	Table.AssetAndLiabilityItem AS AssetAndLiabilityItem,
	|	Table.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	Table.DocumentRegisterRecords AS DocumentRegisterRecords,
	|	Table.RowID AS RowID,
	|	Table.ProductsGroup AS ProductsGroup,
	|	Table.CorLot AS CorLot,
	|	Table.LotVendorAttributesCorr AS LotVendorAttributesCorr,
	|	Table.CorControllingAttributes AS CorControllingAttributes,
	|	Table.CorVATActivityTypes AS CorVATActivityTypes,
	|	Table.DocumentVATActivityType AS DocumentVATActivityType,
	|	Table.FinancialAccountingDimensionOfDocument AS FinancialAccountingDimensionOfDocument,
	|	SUM(Table.VATLocal) AS VATLocal,
	|	SUM(Table.VATManag) AS VATManag,
	|	Table.ProductCostElement AS ProductCostElement,
	|	Table.EntryType AS EntryType,
	|	Table.DocumentSource AS DocumentSource,
	|	Table.CorLineOfBusiness AS CorLineOfBusiness,
	|	Table.ReversingEntry AS ReversingEntry,
	|	Table.VariancePeriod AS VariancePeriod,
	|	SUM(Table.Count) AS CountUpdate,
	|	SUM(Table.Cost) AS CostUpdate,
	|	SUM(Table.CostExcludingVAT) AS CostExcludingVATUpdate,
	|	SUM(Table.AddExpensesForGoods) AS AddExpensesForGoodsUpdate,
	|	SUM(Table.AdditionalExpensesExcludingVAT) AS AdditionalExpensesExcludingVATUpdate,
	|	SUM(Table.LocalCost) AS LocalCostUpdate,
	|	SUM(Table.PermanentDifference) AS PermanentDifferenceUpdate,
	|	SUM(Table.CostTD) AS CostTDUpdate,
	|	SUM(Table.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTaxUpdate,
	|	SUM(Table.OffBalanceCost) AS OffBalanceCostUpdate,
	|	SUM(Table.LaborCosts) AS LaborCostsUpdate,
	|	SUM(Table.ItemizedFixedCostsIncludingVAT) AS ItemizedFixedCostsIncludingVATUpdate,
	|	SUM(Table.ItemizedVariableCostsIncludingVAT) AS ItemizedVariableCostsIncludingVATUpdate,
	|	SUM(Table.ItemizedFixedCostsExcludingVAT) AS ItemizedFixedCostsExcludingVATUpdate,
	|	SUM(Table.ItemizedVariableCostsExcludingVAT) AS ItemizedVariableCostsExcludingVATUpdate,
	|	SUM(Table.OffBalanceCostLocal) AS OffBalanceCostLocalUpdate,
	|	SUM(Table.AddExpensesLocal) AS AddExpensesLocalUpdate,
	|	SUM(Table.LaborCostsLocal) AS LaborCostsLocalUpdate,
	|	SUM(Table.ItemizedFixedCostsCompl) AS ItemizedFixedCostsComplUpdate,
	|	SUM(Table.ItemizedVariableCostsCompl) AS ItemizedVariableCostsComplUpdate,
	|	SUM(Table.CostMan) AS CostManUpdate,
	|	SUM(Table.AddExpensesMan) AS AddExpensesManUpdate,
	|	SUM(Table.LaborCostsMan) AS LaborCostsManUpdate,
	|	SUM(Table.ItemizedFixedCostsManag) AS ItemizedFixedCostsManagUpdate,
	|	SUM(Table.ItemizedVariableCostsManag) AS ItemizedVariableCostsManagUpdate
	|INTO ChangesTableInventoryCost
	|FROM
	|(SELECT
	|	Cost_.Period AS Period,
	|	Cost_.RecordType AS RecordType,
	|	Cost_.CostAccountingTransaction AS CostAccountingTransaction,
	|	Cost_.Recorder AS Recorder,
	|	Cost_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Cost_.AccountingSection AS AccountingSection,
	|	Cost_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Cost_.Organization AS Organization,
	|	Cost_.Lot AS Lot,
	|	Cost_.LotVendorAttributes AS LotVendorAttributes,
	|	Cost_.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	Cost_.VATActivityType AS VATActivityType,
	|	-Cost_.Count AS Count,
	|	-Cost_.Cost AS Cost,
	|	-Cost_.CostExcludingVAT AS CostExcludingVAT,
	|	-Cost_.AddExpensesForGoods AS AddExpensesForGoods,
	|	-Cost_.AdditionalExpensesExcludingVAT AS AdditionalExpensesExcludingVAT,
	|	-Cost_.LocalCost AS LocalCost,
	|	-Cost_.PermanentDifference AS PermanentDifference,
	|	-Cost_.CostTD AS CostTD,
	|	-Cost_.CostOfPersonalIncomeTax AS CostOfPersonalIncomeTax,
	|	-Cost_.OffBalanceCost AS OffBalanceCost,
	|	-Cost_.LaborCosts AS LaborCosts,
	|	-Cost_.ItemizedFixedCostsIncludingVAT AS ItemizedFixedCostsIncludingVAT,
	|	-Cost_.ItemizedVariableCostsIncludingVAT AS ItemizedVariableCostsIncludingVAT,
	|	-Cost_.ItemizedFixedCostsExcludingVAT AS ItemizedFixedCostsExcludingVAT,
	|	-Cost_.ItemizedVariableCostsExcludingVAT AS ItemizedVariableCostsExcludingVAT,
	|	-Cost_.OffBalanceCostLocal AS OffBalanceCostLocal,
	|	-Cost_.AddExpensesLocal AS AddExpensesLocal,
	|	-Cost_.LaborCostsLocal AS LaborCostsLocal,
	|	-Cost_.ItemizedFixedCostsCompl AS ItemizedFixedCostsCompl,
	|	-Cost_.ItemizedVariableCostsCompl AS ItemizedVariableCostsCompl,
	|	-Cost_.CostMan AS CostMan,
	|	-Cost_.AddExpensesMan AS AddExpensesMan,
	|	-Cost_.LaborCostsMan AS LaborCostsMan,
	|	-Cost_.ItemizedFixedCostsManag AS ItemizedFixedCostsManag,
	|	-Cost_.ItemizedVariableCostsManag AS ItemizedVariableCostsManag,
	|	Cost_.BusinessOperation AS BusinessOperation,
	|	Cost_.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	Cost_.CorAccountingSection AS CorAccountingSection,
	|	Cost_.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	Cost_.CorCompany AS CorCompany,
	|	Cost_.CorGrossInitialCostENT AS CorGrossInitialCostENT,
	|	Cost_.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Cost_.SalesOrder AS SalesOrder,
	|	Cost_.Department AS Department,
	|	Cost_.DimensionOfExpenses AS DimensionOfExpenses,
	|	Cost_.ExpenseItemOfWriteOff AS ExpenseItemOfWriteOff,
	|	Cost_.IncomeItem AS IncomeItem,
	|	Cost_.DimensionOfRevenue AS DimensionOfRevenue,
	|	Cost_.SalePeriod AS SalePeriod,
	|	Cost_.AssetAndLiabilityItem AS AssetAndLiabilityItem,
	|	Cost_.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	Cost_.DocumentRegisterRecords AS DocumentRegisterRecords,
	|	Cost_.RowID AS RowID,
	|	Cost_.ProductsGroup AS ProductsGroup,
	|	Cost_.CorLot AS CorLot,
	|	Cost_.LotVendorAttributesCorr AS LotVendorAttributesCorr,
	|	Cost_.CorControllingAttributes AS CorControllingAttributes,
	|	Cost_.CorVATActivityTypes AS CorVATActivityTypes,
	|	Cost_.DocumentVATActivityType AS DocumentVATActivityType,
	|	Cost_.FinancialAccountingDimensionOfDocument AS FinancialAccountingDimensionOfDocument,
	|	-Cost_.VATLocal AS VATLocal,
	|	-Cost_.VATManag AS VATManag,
	|	Cost_.ProductCostElement AS ProductCostElement,
	|	Cost_.EntryType AS EntryType,
	|	Cost_.DocumentSource AS DocumentSource,
	|	Cost_.CorLineOfBusiness AS CorLineOfBusiness,
	|	Cost_.ReversingEntry AS ReversingEntry,
	|	Cost_.VariancePeriod AS VariancePeriod
	|FROM
	|	InventoryCostBeforeWrite AS Cost_
	|
	|UNION ALL
	|
	|SELECT
	|	Cost_.Period AS Period,
	|	Cost_.RecordType AS RecordType,
	|	Cost_.CostAccountingTransaction AS CostAccountingTransaction,
	|	Cost_.Recorder AS Recorder,
	|	Cost_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Cost_.AccountingSection AS AccountingSection,
	|	Cost_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Cost_.Organization AS Organization,
	|	Cost_.Lot AS Lot,
	|	Cost_.LotVendorAttributes AS LotVendorAttributes,
	|	Cost_.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	Cost_.VATActivityType AS VATActivityType,
	|	Cost_.Count AS Count,
	|	Cost_.Cost AS Cost,
	|	Cost_.CostExcludingVAT AS CostExcludingVAT,
	|	Cost_.AddExpensesForGoods AS AddExpensesForGoods,
	|	Cost_.AdditionalExpensesExcludingVAT AS AdditionalExpensesExcludingVAT,
	|	Cost_.LocalCost AS LocalCost,
	|	Cost_.PermanentDifference AS PermanentDifference,
	|	Cost_.CostTD AS CostTD,
	|	Cost_.CostOfPersonalIncomeTax AS CostOfPersonalIncomeTax,
	|	Cost_.OffBalanceCost AS OffBalanceCost,
	|	Cost_.LaborCosts AS LaborCosts,
	|	Cost_.ItemizedFixedCostsIncludingVAT AS ItemizedFixedCostsIncludingVAT,
	|	Cost_.ItemizedVariableCostsIncludingVAT AS ItemizedVariableCostsIncludingVAT,
	|	Cost_.ItemizedFixedCostsExcludingVAT AS ItemizedFixedCostsExcludingVAT,
	|	Cost_.ItemizedVariableCostsExcludingVAT AS ItemizedVariableCostsExcludingVAT,
	|	Cost_.OffBalanceCostLocal AS OffBalanceCostLocal,
	|	Cost_.AddExpensesLocal AS AddExpensesLocal,
	|	Cost_.LaborCostsLocal AS LaborCostsLocal,
	|	Cost_.ItemizedFixedCostsCompl AS ItemizedFixedCostsCompl,
	|	Cost_.ItemizedVariableCostsCompl AS ItemizedVariableCostsCompl,
	|	Cost_.CostMan AS CostMan,
	|	Cost_.AddExpensesMan AS AddExpensesMan,
	|	Cost_.LaborCostsMan AS LaborCostsMan,
	|	Cost_.ItemizedFixedCostsManag AS ItemizedFixedCostsManag,
	|	Cost_.ItemizedVariableCostsManag AS ItemizedVariableCostsManag,
	|	Cost_.BusinessOperation AS BusinessOperation,
	|	Cost_.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	Cost_.CorAccountingSection AS CorAccountingSection,
	|	Cost_.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	Cost_.CorCompany AS CorCompany,
	|	Cost_.CorGrossInitialCostENT AS CorGrossInitialCostENT,
	|	Cost_.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Cost_.SalesOrder AS SalesOrder,
	|	Cost_.Department AS Department,
	|	Cost_.DimensionOfExpenses AS DimensionOfExpenses,
	|	Cost_.ExpenseItemOfWriteOff AS ExpenseItemOfWriteOff,
	|	Cost_.IncomeItem AS IncomeItem,
	|	Cost_.DimensionOfRevenue AS DimensionOfRevenue,
	|	Cost_.SalePeriod AS SalePeriod,
	|	Cost_.AssetAndLiabilityItem AS AssetAndLiabilityItem,
	|	Cost_.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	Cost_.DocumentRegisterRecords AS DocumentRegisterRecords,
	|	Cost_.RowID AS RowID,
	|	Cost_.ProductsGroup AS ProductsGroup,
	|	Cost_.CorLot AS CorLot,
	|	Cost_.LotVendorAttributesCorr AS LotVendorAttributesCorr,
	|	Cost_.CorControllingAttributes AS CorControllingAttributes,
	|	Cost_.CorVATActivityTypes AS CorVATActivityTypes,
	|	Cost_.DocumentVATActivityType AS DocumentVATActivityType,
	|	Cost_.FinancialAccountingDimensionOfDocument AS FinancialAccountingDimensionOfDocument,
	|	Cost_.VATLocal AS VATLocal,
	|	Cost_.VATManag AS VATManag,
	|	Cost_.ProductCostElement AS ProductCostElement,
	|	Cost_.EntryType AS EntryType,
	|	Cost_.DocumentSource AS DocumentSource,
	|	Cost_.CorLineOfBusiness AS CorLineOfBusiness,
	|	Cost_.ReversingEntry AS ReversingEntry,
	|	Cost_.VariancePeriod AS VariancePeriod
	|FROM
	|	AccumulationRegister.InventoryCost AS Cost_
	|WHERE
	|	Cost_.Recorder = &Recorder
	|) AS Table
	|GROUP BY
	|	Table.Period,
	|	Table.RecordType,
	|	Table.CostAccountingTransaction,
	|	Table.Recorder,
	|	Table.ItemsLocationAttributes,
	|	Table.AccountingSection,
	|	Table.InventoryOwnerAttribute,
	|	Table.Organization,
	|	Table.Lot,
	|	Table.LotVendorAttributes,
	|	Table.FinancialAccountingDimension,
	|	Table.VATActivityType,
	|	Table.BusinessOperation,
	|	Table.CorItemsLocationAttributes,
	|	Table.CorAccountingSection,
	|	Table.CorInventoryOwnerAttribute,
	|	Table.CorCompany,
	|	Table.CorGrossInitialCostENT,
	|	Table.AccountingDimensionByPartners,
	|	Table.SalesOrder,
	|	Table.Department,
	|	Table.DimensionOfExpenses,
	|	Table.ExpenseItemOfWriteOff,
	|	Table.IncomeItem,
	|	Table.DimensionOfRevenue,
	|	Table.SalePeriod,
	|	Table.AssetAndLiabilityItem,
	|	Table.AssetsLiabilitiesDimension,
	|	Table.DocumentRegisterRecords,
	|	Table.RowID,
	|	Table.ProductsGroup,
	|	Table.CorLot,
	|	Table.LotVendorAttributesCorr,
	|	Table.CorControllingAttributes,
	|	Table.CorVATActivityTypes,
	|	Table.DocumentVATActivityType,
	|	Table.FinancialAccountingDimensionOfDocument,
	|	Table.ProductCostElement,
	|	Table.EntryType,
	|	Table.DocumentSource,
	|	Table.CorLineOfBusiness,
	|	Table.ReversingEntry,
	|	Table.VariancePeriod
	|HAVING
	|	SUM(Table.Count) <> 0
	|	OR SUM(Table.Cost) <> 0
	|	OR SUM(Table.CostExcludingVAT) <> 0
	|	OR SUM(Table.AddExpensesForGoods) <> 0
	|	OR SUM(Table.AdditionalExpensesExcludingVAT) <> 0
	|	OR SUM(Table.LocalCost) <> 0
	|	OR SUM(Table.PermanentDifference) <> 0
	|	OR SUM(Table.CostTD) <> 0
	|	OR SUM(Table.CostOfPersonalIncomeTax) <> 0
	|	OR SUM(Table.OffBalanceCost) <> 0
	|	OR SUM(Table.LaborCosts) <> 0
	|	OR SUM(Table.ItemizedFixedCostsIncludingVAT) <> 0
	|	OR SUM(Table.ItemizedVariableCostsIncludingVAT) <> 0
	|	OR SUM(Table.ItemizedFixedCostsExcludingVAT) <> 0
	|	OR SUM(Table.ItemizedVariableCostsExcludingVAT) <> 0
	|	OR SUM(Table.OffBalanceCostLocal) <> 0
	|	OR SUM(Table.AddExpensesLocal) <> 0
	|	OR SUM(Table.LaborCostsLocal) <> 0
	|	OR SUM(Table.ItemizedFixedCostsCompl) <> 0
	|	OR SUM(Table.ItemizedVariableCostsCompl) <> 0
	|	OR SUM(Table.CostMan) <> 0
	|	OR SUM(Table.AddExpensesMan) <> 0
	|	OR SUM(Table.LaborCostsMan) <> 0
	|	OR SUM(Table.ItemizedFixedCostsManag) <> 0
	|	OR SUM(Table.ItemizedVariableCostsManag) <> 0
	|	OR SUM(Table.VATLocal) <> 0
	|	OR SUM(Table.VATManag) <> 0
	|INDEX BY
	|	Organization,
	|	Period
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP InventoryCostBeforeWrite
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.Organization,
	|	T.Period
	|INTO TTOrganizationsAndPeriodsInInventoryCosts
	|FROM
	|	ChangesTableInventoryCost AS T
	|INDEX BY
	|	Organization
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Organization AS Organization,
	|	T.Period,
	|	MAX(AccountingPolicy.Period) AS PolicyPeriod,
	|	MIN(ISNULL(AccountingPolicyIsAsFollows.Period, DATETIME(1,1,1))) AS EndOfPeriod
	|INTO TTPeriodsOfAccountingPoliciesOfInventoryCosts
	|FROM
	|	TTOrganizationsAndPeriodsInInventoryCosts AS T
	|	LEFT JOIN InformationRegister.FinancialAccountingPolicy AS AccountingPolicy
	|		ON T.Organization = AccountingPolicy.Organization
	|		AND T.Period >= AccountingPolicy.Period
	|	LEFT JOIN InformationRegister.FinancialAccountingPolicy AS AccountingPolicyIsAsFollows
	|		ON T.Organization = AccountingPolicyIsAsFollows.Organization
	|		AND T.Period < AccountingPolicyIsAsFollows.Period
	|		AND AccountingPolicyIsAsFollows.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|GROUP BY
	|	T.Organization,
	|	T.Period
	|INDEX BY
	|	Organization
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Organization AS Organization,
	|	T.Period AS Period,
	|	T.EndOfPeriod AS EndOfPeriod
	|INTO TTAverageSlidingInventoryCost
	|FROM
	|	TTPeriodsOfAccountingPoliciesOfInventoryCosts AS T
	|	LEFT JOIN InformationRegister.FinancialAccountingPolicy AS AccountingPolicy
	|		ON T.Organization = AccountingPolicy.Organization
	|		AND T.PolicyPeriod = AccountingPolicy.Period
	|WHERE
	|	ISNULL(AccountingPolicy.InventoryValuationMethod, UNDEFINED) = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|INDEX BY
	|	Organization,
	|	Period
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTOrganizationsAndPeriodsInInventoryCosts
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTPeriodsOfAccountingPoliciesOfInventoryCosts
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Organization,
	|	MIN(T.Period) AS Period
	|FROM
	|	TTAverageSlidingInventoryCost AS T
	|GROUP BY
	|	Organization
	|ORDER BY
	|	Period
	|";
	
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	MediumSlipOrganizations = Query.Execute().Unload();
	
	DocumentsPosting.RegisterControlTable(AdditionalProperties, "TTAverageSlidingInventoryCost",
		MediumSlipOrganizations.Count() > 0, New Structure("MediumSlipOrganizations", MediumSlipOrganizations));
	
EndProcedure

#EndRegion

#Region Private

Function SaveUnchangedPrimaryRegisteredRecords(ChangedPeriods)
	
	If CalculationOfCostCached.ValuesOfTechnologicalParameters().DoNotSaveCalculatedRegisteredRecords
	 Or AdditionalProperties.Property("DoNotSaveCalculatedRegisteredRecords") Then
		Return True;
	EndIf;
	
	Recorder     = Filter.Recorder.Value;
	MetaLogger = Recorder.Metadata(); // MetadataObjectAccumulationRegister
	
	If AdditionalProperties.Property("RecorderDate") Then
		RecorderDate = AdditionalProperties.RecorderDate;
	Else
		RecorderDate = Common.ObjectAttributeValue(Recorder, "Date");
	EndIf;
	
	If Not CalculationOfCostCached.BatchAccountingVersion22(BegOfMonth(RecorderDate)) Then
		Return True;
	EndIf;
	
	If Not AdditionalProperties.Property("ExactlyNeedToSaveMovement") Then
		If Not AdditionalProperties.Property("DocumentProperties")
 		 Or AdditionalProperties.DocumentProperties.WriteMode = DocumentWriteMode.UndoPosting Then
			Return True;
		EndIf;
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Recorder", Recorder);
	Query.SetParameter("RecorderDate", RecorderDate);
	Query.SetParameter("IgnoreChanges",
		AdditionalProperties.Property("OnlyStateOfTransferOfOwnershipHasChanged")
		And AdditionalProperties.OnlyStateOfTransferOfOwnershipHasChanged);
		
	RecordsTable = ThisObject.Unload();
	Query.SetParameter("RecordSet", RecordsTable);
	
	#Region QueryTextTemplates
	
	// We will prepare templates for the formation of query texts.
	ExceptionFields    = New Structure("LineNumber, Active, Recorder, PointInTime, CostCalculationDate");
	PartyFields     	  = New Structure("Lot, LotVendorAttributes, FinancialAccountingDimension, VATActivityType,
		|CorLot, LotVendorAttributesCorr, CorControllingAttributes,
		|CorItemsLocationAttributes, CorVATActivityTypes, DocumentSource, CalculationIsNotCompleted,
		|DocumentVATActivityType, FinancialAccountingDimensionOfDocument,
		|LotCalculationPerformed, MonthEndClosingMode, CostDefiningMethod");
	NonSummableFields = New Structure("RowCode");
	SumFieldsOfAverageSliding = New Structure(CostCalculationDocumentsPosting.SumFieldsOfAverageSliding());
	
	If MetaLogger <> Metadata.Documents.InventoryTransfer
	 And MetaLogger <> Metadata.Documents.MovementOfProductsAndMaterials
	 And MetaLogger <> Metadata.Documents.InventoryAssignmentAdjustment
	 And MetaLogger <> Metadata.Documents.InventoryConsumption
	 And MetaLogger <> Metadata.Documents.GoodsMisgrading
	 And MetaLogger <> Metadata.Documents.GoodsDamage Then
		// For the listed types of documents, cor. The type of VAT activity is determined in the calculation of the cost of filling the parties.The text of the current turnover of the Party items()
		// For the rest of the documents, this detail is determined during the document.
		PartyFields.Delete("CorVATActivityTypes");
 	EndIf;
 	
	CaseFieldText_ = "";
	CaseFieldTextWithMinus = "";
	CaseFieldTextWithoutLots = "";
	TextOfDimensionFieldWithoutBatches = "";
	TextOfSummationField = "";
	ConditionFieldText = "";
	TextOfConditionFieldMediumSlip = "";
	
	For Each CurrentColumn In RecordsTable.Columns Do
		
		If ExceptionFields.Property(CurrentColumn.Name) Then
			Continue;
		EndIf;
		
		ThisIsSummableField = Metadata().Resources.Find(CurrentColumn.Name) <> Undefined
			Or (Metadata().Attributes.Find(CurrentColumn.Name) <> Undefined
					And CurrentColumn.ValueType.ContainsType(Type("Number"))
					And Not NonSummableFields.Property(CurrentColumn.Name));
		 
		CaseFieldText_ = CaseFieldText_ + ?(CaseFieldText_ = "", "", ",
			|	") + "T." + CurrentColumn.Name;
		CaseFieldTextWithMinus = CaseFieldTextWithMinus + ?(CaseFieldTextWithMinus = "", "", ",
			|	") + ?(ThisIsSummableField, "-", "") + "T." + CurrentColumn.Name;
			
		If ThisIsSummableField Then
			
			TextOfSummationField = TextOfSummationField + ?(TextOfSummationField = "", "", ",
				|	") + "SUM(T." + CurrentColumn.Name + ") AS " + CurrentColumn.Name;
			
			If SumFieldsOfAverageSliding.Property(CurrentColumn.Name) Then
				TextOfConditionFieldMediumSlip = TextOfConditionFieldMediumSlip + ?(TextOfConditionFieldMediumSlip = "", "", "
					|			OR ") + "SUM(T." + CurrentColumn.Name + ") <> 0";
			Else
				ConditionFieldText = ConditionFieldText + ?(ConditionFieldText = "", "", "
					|	OR ") + "SUM(T." + CurrentColumn.Name + ") <> 0";
			EndIf;
			
		Else
			
			If Not PartyFields.Property(CurrentColumn.Name) Then
				
				If Lower(CurrentColumn.Name) = Lower("CorVATActivityTypes") Then
					
					// For incoming movements, the Corvide Activity index is not filled in when carrying out the document, it is filled in when calculating batches for VAT accounting purposes.
					// For consumable movements, the Corvide activity index is always filled in by the document itself when conducting.
					// For the implementation of a multi-turn container and for the implementation of the regl. accounting corviddeactivity is not filled in.
					CaseFieldTextWithoutLots = CaseFieldTextWithoutLots + ?(CaseFieldTextWithoutLots = "", "", ",
						|	") + "CASE WHEN (T.EntryType = VALUE(Enum.LotRecordTypes.Move)
						|	  AND T.RecordType = VALUE(AccumulationRecordType.Receipt))
						|" + ?(MetaLogger = Metadata.Documents.CustomerInvoice, "
						|	  OR T.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.DisposalAtFixedCost)
						|	  OR T.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
						|	  OR T.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)", "") + "
						|		THEN UNDEFINED
						| ELSE T." + CurrentColumn.Name + " END AS " + CurrentColumn.Name;
					TextOfDimensionFieldWithoutBatches = TextOfDimensionFieldWithoutBatches + ?(TextOfDimensionFieldWithoutBatches = "", "", ",
						|	") + "CASE WHEN (T.EntryType = VALUE(Enum.LotRecordTypes.Move)
						|	  AND T.RecordType = VALUE(AccumulationRecordType.Receipt))
						|" + ?(MetaLogger = Metadata.Documents.CustomerInvoice, "
						|	  OR T.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.DisposalAtFixedCost)
						|	  OR T.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
						|	  OR T.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)", "") + "
						|		THEN UNDEFINED
						| ELSE T." + CurrentColumn.Name + " END";
					
				Else
						
					CaseFieldTextWithoutLots = CaseFieldTextWithoutLots + ?(CaseFieldTextWithoutLots = "", "", ",
						|	") + "T." + CurrentColumn.Name;
					TextOfDimensionFieldWithoutBatches = TextOfDimensionFieldWithoutBatches + ?(TextOfDimensionFieldWithoutBatches = "", "", ",
						|	") + "T." + CurrentColumn.Name;
					
				EndIf;
				
			Else
				
				If Lower(CurrentColumn.Name) = Lower("DocumentSource") Then
					AdditionalConditionForField =
						 "OR (T.RecordType = VALUE(AccumulationRecordType.Receipt) AND Rules.DocumentSourceInParish)
					|	  OR (T.RecordType = VALUE(AccumulationRecordType.Expense) AND Rules.DocumentSourceInExpense)
					|	  ";
				ElsIf Lower(CurrentColumn.Name) = Lower("CorVATActivityTypes")
				 Or Lower(CurrentColumn.Name) = Lower("CorItemsLocationAttributes") Then
					AdditionalConditionForField =
						 "AND T.RecordType = VALUE(AccumulationRecordType.Receipt)
					|	  ";
				Else
					AdditionalConditionForField = "";
				EndIf;
				
				CaseFieldTextWithoutLots = CaseFieldTextWithoutLots + ?(CaseFieldTextWithoutLots = "", "", ",
					|	") + "CASE WHEN T.EntryType IN (&TypesOfPrimaryBatchRecords)
					|	  " + AdditionalConditionForField + "
					|	  OR T.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef)
					|		THEN T." + CurrentColumn.Name
					+ " ELSE UNDEFINED END AS " + CurrentColumn.Name;
				TextOfDimensionFieldWithoutBatches = TextOfDimensionFieldWithoutBatches + ?(TextOfDimensionFieldWithoutBatches = "", "", ",
					|	") + "CASE WHEN T.EntryType IN (&TypesOfPrimaryBatchRecords)
					|	  " + AdditionalConditionForField + "
					|	  OR T.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef)
					|		THEN T." + CurrentColumn.Name
					+ " ELSE UNDEFINED END";
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	#EndRegion

	#Region LoadingRegisteredRecordsIntoTemporaryTable
	
	Query.Text =
	"SELECT
	|	BEGINOFPERIOD(T.Period, MONTH) AS Month,
	|	&Recorder AS Recorder,
	|	&TextCaseFieldSelection,
	|	T.CostCalculationDate
	|INTO TTRecordset
	|FROM
	|	&RecordSet AS T
	|WHERE
	|	NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|";
	
	If AdditionalProperties.Property("AddRegisteredRecordsFromInformationSecurityForPeriod") Then
		Query.Text = StrReplace(Query.Text, "TTRecordset", "TTSetOfRecordsPreliminary");
	EndIf;

	#EndRegion
	
	#Region AddRegisteredRecordsFromInformationSecurityForPeriod
	
	// If during the document it is known that the data of a certain period has not exactly changed,
	// then you just need to add them to the set of records from the IB.
	If AdditionalProperties.Property("AddRegisteredRecordsFromInformationSecurityForPeriod") Then
		
		Query.SetParameter("BeginOfPeriod", AdditionalProperties.AddRegisteredRecordsFromInformationSecurityForPeriod.BeginOfPeriod);
		Query.SetParameter("EndOfPeriod",  AdditionalProperties.AddRegisteredRecordsFromInformationSecurityForPeriod.EndOfPeriod);
		
		Query.Text = Query.Text + "
		|;
		|" + "
		|SELECT
		|	T.Month,
		|	&Recorder AS Recorder,
		|	&TextCaseFieldSelection,
		|	T.CostCalculationDate
		|INTO TTRecordset
		|FROM
		|	TTSetOfRecordsPreliminary AS T
		|
		|UNION ALL
		|
		|SELECT
		|	BEGINOFPERIOD(T.Period, MONTH) AS Month,
		|	&Recorder AS Recorder,
		|	&TextCaseFieldSelection,
		|	T.CostCalculationDate
		|FROM
		|	AccumulationRegister.InventoryCost AS T
		|WHERE
		|	T.Recorder = &Recorder
		|	AND T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND NOT T.LotCalculation
		|	AND NOT T.CalculationOfCost
		|";
		
	EndIf;
	
	#EndRegion
	
	#Region CheckingAccountingPolicy
	
	Query.Text = StrReplace(Query.Text, "&TextCaseFieldSelection", CaseFieldText_);
	
	Query.Text = Query.Text + "
	|;
	|" + "
	|SELECT DISTINCT
	|	T.Organization AS Organization,
	|	T.Month AS Month
	|INTO CompanySTTPeriods
	|FROM
	|	TTRecordset AS T
	|
	|INDEX BY
	|	Organization";
	
	If CalculationOfCostCached.MediumSlipValuationIsUsed() Then
		
		// With the cost estimation method, the Average Sliding cost calculation does not change the primary Registered Records of the document
		// and does not add calculated Registered Records, so there is no need to save them.
		Query.Text = Query.Text + "
		|;
		|" + "
		|SELECT
		|	T.Organization AS Organization,
		|	T.Month AS Month,
		|	MAX(ISNULL(AccountingPolicy.Period, DATETIME(1, 1, 1))) AS PolicyPeriod
		|INTO TTPolicyPeriods
		|FROM
		|	CompanySTTPeriods AS T
		|		LEFT JOIN InformationRegister.FinancialAccountingPolicy AS AccountingPolicy
		|		ON T.Organization = AccountingPolicy.Organization
		|			AND T.Month >= AccountingPolicy.Period
		|
		|GROUP BY
		|	T.Organization,
		|	T.Month
		|
		|INDEX BY
		|	Organization,
		|	PolicyPeriod
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	T.SaveYourRegisteredRecords AS SaveYourRegisteredRecords
		|FROM
		|	(SELECT
		|		T.Organization AS Organization,
		|		T.Month AS Month,
		|		ISNULL(AccountingPolicy.InventoryValuationMethod, UNDEFINED) <> VALUE(Enum.InventoryValuationMethods.MovingAverage) AS SaveYourRegisteredRecords
		|	FROM
		|		TTPolicyPeriods AS T
		|			LEFT JOIN InformationRegister.FinancialAccountingPolicy AS AccountingPolicy
		|			ON T.Organization = AccountingPolicy.Organization
		|				AND T.PolicyPeriod = AccountingPolicy.Period) AS T
		|WHERE
		|	T.SaveYourRegisteredRecords";
		
		SaveYourRegisteredRecords = Not Query.Execute().IsEmpty();
		
		If Not SaveYourRegisteredRecords Then
			
			If CostCalculationAppliedAlgorithms.TemporaryTableSize(Query, "TTRecordset") <> RecordsTable.Count() Then

				Query.Text =
				"SELECT
				|	*
				|FROM
				|	TTRecordset AS T
				|";
				
				ThisObject.Load(Query.Execute().Unload());
				
			EndIf;
			
			Return False;
			
		EndIf;
		
	Else
		Query.Execute();
	EndIf;
	
	#EndRegion
	
	#Region CreatingTemporaryTables
	
	Query.SetParameter("TypesOfPrimaryBatchRecords", CostCalculationAppliedAlgorithms.TypesOfPrimaryBatchRecords());
	
	// Let's create the right to fill in the record field
	CostCalculationAppliedAlgorithms.CreateTableOfRulesForFillingInRecordTypeField(
		Query.TempTablesManager,
		CalculationOfCostCached.RulesForFillingInRecordTypeField(MetaLogger.Name));
	
	// Let's analyze the presence of altered primary movements in the context of periods (months).
	QueryTextTemplate2 =
	"SELECT DISTINCT
	|	T.Period,
	|	T.CostAccountingTransaction
	|INTO TTModifiedRegisteredRecords
	|FROM
	|(SELECT
	|	NomenclatureAnalysts.ProductCostElement AS ProductCostElement,
	|	&TextCaseFieldSelection
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS NomenclatureAnalysts
	|		ON T.ItemsLocationAttributes = NomenclatureAnalysts.Ref
	|WHERE
	|	T.Recorder = &Recorder
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|
	|UNION ALL
	|
	|SELECT
	|	NomenclatureAnalysts.ProductCostElement AS ProductCostElement,
	|	&CaseFieldTextWithMinus
	|FROM
	|	TTRecordset AS T
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS NomenclatureAnalysts
	|		ON T.ItemsLocationAttributes = NomenclatureAnalysts.Ref
	|) AS T
	|	LEFT JOIN TTRulesForFillingInRecordTypeField AS Rules
	|		ON T.BusinessOperation = Rules.BusinessOperation
	|
	|GROUP BY
	|	&TextOfDimensionFieldWithoutBatches
	|HAVING
	|	&TextOfGeneralConditionsField
	// When accounting on a Sliding Average, we do not check the resources that are filled with this assessment method.
	|	OR (NOT MAX(T.CostDefiningMethod IN
	|			(VALUE(Enum.WaysToCalculateInventoryCost.ByMovingAverage),
	|			 VALUE(Enum.WaysToCalculateInventoryCost.ByCorRecord),
	|			 VALUE(Enum.WaysToCalculateInventoryCost.BySourceDocumentRegisterRecords)))
	|		AND (&TextOfConditionFieldMediumSlip)
	|		)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	T.Period AS Period,
	|	MAX(T.ThereAreAlteredRegisteredRecords) AS ThereAreAlteredRegisteredRecords
	|INTO TTPeriodsOfRegisteredRecords
	|FROM
	|	(SELECT DISTINCT
	|		T.Month AS Period,
	|		FALSE AS ThereAreAlteredRegisteredRecords
	|	FROM
	|		CompanySTTPeriods AS T
	|	
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		BEGINOFPERIOD(T.Period, MONTH) AS Period,
	|		CASE WHEN &IgnoreChanges AND &RecorderDate = T.Period
	|         AND T.CostAccountingTransaction <> VALUE(Enum.CostAccountingTransactions.SaleOfGoodsAndServices)
	|           THEN FALSE ELSE TRUE END AS ThereAreAlteredRegisteredRecords
	|	FROM
	|		TTModifiedRegisteredRecords AS T
	|	) AS T
	|
	|GROUP BY
	|	T.Period
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT TOP 1
	|	T.ThereAreAlteredRegisteredRecords
	|FROM
	|	TTPeriodsOfRegisteredRecords AS T
	|WHERE
	|	T.ThereAreAlteredRegisteredRecords
	|";
	
	Query.Text = StrReplace(QueryTextTemplate2, "&TextCaseFieldSelection", CaseFieldText_);
	Query.Text = StrReplace(Query.Text, "&CaseFieldTextWithMinus", CaseFieldTextWithMinus);
	Query.Text = StrReplace(Query.Text, "&CaseFieldTextWithoutLots", CaseFieldTextWithoutLots);
	Query.Text = StrReplace(Query.Text, "&TextOfSummationField", TextOfSummationField);
	Query.Text = StrReplace(Query.Text, "&TextOfDimensionFieldWithoutBatches", TextOfDimensionFieldWithoutBatches);
	Query.Text = StrReplace(Query.Text, "&TextOfGeneralConditionsField", ConditionFieldText);
	Query.Text = StrReplace(Query.Text, "&TextOfConditionFieldMediumSlip", TextOfConditionFieldMediumSlip);
	
	ThereAreModifiedOnes = Not Query.Execute().IsEmpty(); // There Are Altered Movements
	
	#EndRegion
	
	#Region PopulatingRecordSet
	
	If ThereAreModifiedOnes
	 Or CostCalculationAppliedAlgorithms.TemporaryTableSize(Query, "TTRecordset") <> RecordsTable.Count() Then
		
		// We will take the Registered Records of the unchanged periods from the IB, and the Registered Records of the changed periods from the set of records.
		QueryTextTemplate2 =
		"SELECT
		|	&Recorder AS Recorder,
		|	&CaseFieldText_,
		|	T.CostCalculationDate
		|FROM
		|	AccumulationRegister.InventoryCost AS T
		|WHERE
		|	T.Recorder = &Recorder
		|	AND NOT T.LotCalculation
		|	AND NOT T.CalculationOfCost
		|	AND BEGINOFPERIOD(T.Period, MONTH) IN
		|		(SELECT T.Period
		|		 FROM TTPeriodsOfRegisteredRecords AS T
		|		 WHERE NOT T.ThereAreAlteredRegisteredRecords)
		|
		|UNION ALL
		|
		|SELECT
		|	&Recorder AS Recorder,
		|	&CaseFieldText_,
		|	T.CostCalculationDate
		|FROM
		|	TTRecordset AS T
		|WHERE
		|	BEGINOFPERIOD(T.Period, MONTH) IN
		|		(SELECT T.Period
		|		 FROM TTPeriodsOfRegisteredRecords AS T
		|		 WHERE T.ThereAreAlteredRegisteredRecords)
		|";
		
	Else

		// There are no changes - we will take all the primary Registered Records from the Infobase
		QueryTextTemplate2 =
		"SELECT
		|	&Recorder AS Recorder,
		|	&CaseFieldText_,
		|	T.CostCalculationDate
		|FROM
		|	AccumulationRegister.InventoryCost AS T
		|WHERE
		|	T.Recorder = &Recorder
		|	AND NOT T.LotCalculation
		|	AND NOT T.CalculationOfCost
		|";
		
	EndIf;
	
	Query.Text = StrReplace(QueryTextTemplate2, "&CaseFieldText_", CaseFieldText_);
	
	ThisObject.Load(Query.Execute().Unload());
	
	#EndRegion
	
	Query.Text =
	"SELECT
	|	T.Period
	|FROM
	|	TTPeriodsOfRegisteredRecords AS T
	|WHERE
	|	T.ThereAreAlteredRegisteredRecords
	|";
	
	ChangedPeriods = Query.Execute().Unload().UnloadColumn("Period");
	
	SaveYourRegisteredRecords = Not ThereAreModifiedOnes
		Or CostCalculationAppliedAlgorithms.TemporaryTableSize(Query, "TTPeriodsOfRegisteredRecords") > 1;
	
	Return SaveYourRegisteredRecords;
	
EndFunction

#Region BackdateJobQueue

Procedure PrepareDataForRegisteringTasksInNonOperationalQueue()
	
	If CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		Return;
	EndIf;
	
	If Not BackdateJobQueue.CreationOfNonOperationalQueueTasksIsAvailable(ThisObject) Then
		Return;
	EndIf;
	
	If GetFunctionalOption("NewOnlineARAPAccounting") 
		And GetFunctionalOption("UseBalanceSheetStatement") Then
		
		Query = New Query;
		Query.TempTablesManager = New TempTablesManager;
		Query.Text = "
		|SELECT
		|	InitialEntries.Recorder AS Recorder,
		|	InitialEntries.Period AS Period,
		|	InitialEntries.Active AS Active,
		|	InitialEntries.RecordType AS RecordType,
		|	InitialEntries.Organization AS Organization,
		|	InitialEntries.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	InitialEntries.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	InitialEntries.CorLineOfBusiness AS CorLineOfBusiness,
		|	InitialEntries.AccountingSection AS AccountingSection,
		|	InitialEntries.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	InitialEntries.Cost AS Cost,
		|	InitialEntries.AddExpensesForGoods AS AddExpensesForGoods,
		|	InitialEntries.LaborCosts AS LaborCosts,
		|	InitialEntries.ItemizedFixedCostsIncludingVAT AS ItemizedFixedCostsIncludingVAT,
		|	InitialEntries.ItemizedVariableCostsIncludingVAT AS ItemizedVariableCostsIncludingVAT,
		|	InitialEntries.CalculationOfCost AS CalculationOfCost,
		|	InitialEntries.LotCalculation AS LotCalculation,
		|	InitialEntries.ReversingEntry AS ReversingEntry
		|INTO VT_TaskQueueInitialEntries
		|FROM
		|	AccumulationRegister.InventoryCost AS InitialEntries
		|WHERE
		|	InitialEntries.Recorder = &Recorder";
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		Query.Execute();
		
		AdditionalProperties.Insert("TemporaryTableManagerJobQueue", Query.TempTablesManager);
		
	EndIf;
	
EndProcedure

Procedure CreateNonOperationalQueueJobsWhenWriting()
	
	If CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		Return;
	EndIf;
	
	If Not BackdateJobQueue.CreationOfNonOperationalQueueTasksIsAvailable(ThisObject) Then
		Return;
	EndIf;
	
	If GetFunctionalOption("NewOnlineARAPAccounting") 
		And GetFunctionalOption("UseBalanceSheetStatement") Then
		
		Query = New Query;
		Query.TempTablesManager = AdditionalProperties.TemporaryTableManagerJobQueue;
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		Query.Text = "
		|SELECT DISTINCT
		|	Table.Recorder AS Document,
		|	Table.Period AS TaskPeriod,
		|	Table.Organization AS Organization,
		|	VALUE(Catalog.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords) AS JobKind
		|FROM
		|	(SELECT
		|		InitialEntries.Recorder AS Recorder,
		|		InitialEntries.Period AS Period,
		|		InitialEntries.Active AS Active,
		|		InitialEntries.RecordType AS RecordType,
		|		InitialEntries.Organization AS Organization,
		|		InitialEntries.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|		InitialEntries.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|		InitialEntries.CorLineOfBusiness AS CorLineOfBusiness,
		|		InitialEntries.AccountingSection AS AccountingSection,
		|		InitialEntries.ItemsLocationAttributes AS ItemsLocationAttributes,
		|		InitialEntries.Cost AS Cost,
		|		InitialEntries.AddExpensesForGoods AS AddExpensesForGoods,
		|		InitialEntries.LaborCosts AS LaborCosts,
		|		InitialEntries.ItemizedFixedCostsIncludingVAT AS ItemizedFixedCostsIncludingVAT,
		|		InitialEntries.ItemizedVariableCostsIncludingVAT AS ItemizedVariableCostsIncludingVAT,
		|		InitialEntries.CalculationOfCost AS CalculationOfCost,
		|		InitialEntries.LotCalculation AS LotCalculation,
		|		InitialEntries.ReversingEntry AS ReversingEntry
		|	FROM
		|		VT_TaskQueueInitialEntries AS InitialEntries
		|
		|	UNION ALL
		|
		|	SELECT
		|		Records.Recorder AS Recorder,
		|		Records.Period AS Period,
		|		Records.Active AS Active,
		|		Records.RecordType AS RecordType,
		|		Records.Organization AS Organization,
		|		Records.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|		Records.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|		Records.CorLineOfBusiness AS CorLineOfBusiness,
		|		Records.AccountingSection AS AccountingSection,
		|		Records.ItemsLocationAttributes AS ItemsLocationAttributes,
		|		-Records.Cost AS Cost,
		|		-Records.AddExpensesForGoods AS AddExpensesForGoods,
		|		-Records.LaborCosts AS LaborCosts,
		|		-Records.ItemizedFixedCostsIncludingVAT AS ItemizedFixedCostsIncludingVAT,
		|		-Records.ItemizedVariableCostsIncludingVAT AS ItemizedVariableCostsIncludingVAT,
		|		Records.CalculationOfCost AS CalculationOfCost,
		|		Records.LotCalculation AS LotCalculation,
		|		Records.ReversingEntry AS ReversingEntry
		|	FROM
		|		AccumulationRegister.InventoryCost AS Records
		|	WHERE
		|		Records.Recorder = &Recorder) AS Table
		|GROUP BY
		|	Table.Recorder,
		|	Table.Period,
		|	Table.Active,
		|	Table.RecordType,
		|	Table.Organization,
		|	Table.InventoryOwnerAttribute,
		|	Table.CorInventoryOwnerAttribute,
		|	Table.CorLineOfBusiness,
		|	Table.AccountingSection,
		|	Table.ItemsLocationAttributes,
		|	Table.CalculationOfCost,
		|	Table.LotCalculation,
		|	Table.ReversingEntry
		|HAVING
		|	SUM(Table.Cost) <> 0 OR SUM(Table.AddExpensesForGoods) <> 0 OR SUM(Table.LaborCosts) <> 0
		|	OR SUM(Table.ItemizedFixedCostsIncludingVAT) <> 0 OR SUM(Table.ItemizedVariableCostsIncludingVAT) <> 0
		|;
		|DROP VT_TaskQueueInitialEntries";

		DataForRegisteringTasks = Query.Execute().Unload();

		BackdateJobQueue.CreateNonOperationalQueueJobsWhenRecordingRecordset(ThisObject, Undefined,
			DataForRegisteringTasks);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
