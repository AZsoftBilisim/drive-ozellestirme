#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Collects the structure from the request texts for further verification of the ban date.
// 
// Parameters:
// 	Query - Query - Request to check the date of the ban, you can set the parameters
// Returns:
// 	See DocumentsPosting.RequestTextTemplateBanDateControl
Function RequestTextMonitoringBanDate(Query) Export
	
	RegisterName = Metadata.AccumulationRegisters.InventoryCost.Name;
	NameOfChangeTable = "ChangesTableInventoryCost"; 
	StructureOfQueryTexts_ = DocumentsPosting.RequestTextTemplateBanDateControl(Query, 
		RegisterName, 
		NameOfChangeTable, 
		"FinancialOutline");
	
	Return StructureOfQueryTexts_;

EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

// Fills in the parameters for reflecting register movements in financial accounting
//
// Parameters:
//  RegisterMetadata - MetadataObjectAccumulationRegister - Metadata of the accumulation register
//  RegistrationForReflection - Boolean - Flag for getting parameters to register for accounting
//
// Returns:
// 	See FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting
//
Function ParametersForReflectingRegisteredRecordsInFinancialAccounting(RegisterMetadata = Undefined, RegistrationForReflection = False) Export
	
	ReflectionParameters = FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting(RegistrationForReflection);
	
	If RegistrationForReflection Then
		Return ReflectionParameters;
	EndIf;
	
	ReflectionParameters.DataPathConfigurationObject =
		FinancialAccountingByBalanceSheetRegisterData.HFCProductSampleField(ReflectionParameters.DataSourceAlias);
	ReflectionParameters.DataPathAccountingLocation = "ItemsLocationAttributes.StorageLocation";
	ReflectionParameters.PathToDataLineOfBusiness = "ItemsLocationAttributes.Purpose.LineOfBusiness";
	
	ReflectionParameters.PathToDataLineOfBusiness = StrReplace(
		"CASE
		|		WHEN DataSourceAlias.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|			AND DataSourceAlias.Lot REFS Catalog.ProductionLots
		|			THEN CAST(DataSourceAlias.Lot AS Catalog.ProductionLots).LineOfBusiness
		|		ELSE DataSourceAlias.ItemsLocationAttributes.Purpose.LineOfBusiness
		|	END",
		"DataSourceAlias",
		ReflectionParameters.DataSourceAlias);
	
	ReflectionParameters.PathToDataDivision = StrReplace(
		"CASE
		|		WHEN DataSourceAlias.ItemsLocationAttributes.StorageLocation REFS Catalog.BusinessStructure
		|			THEN DataSourceAlias.ItemsLocationAttributes.StorageLocation
		|		WHEN DataSourceAlias.ItemsLocationAttributes.StorageLocation REFS Catalog.Warehouses
		|			THEN CAST(DataSourceAlias.ItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		ELSE DataSourceAlias.ItemsLocationAttributes.Department
		|	END",
		"DataSourceAlias",
		ReflectionParameters.DataSourceAlias);
		
	ReflectionParameters.ManResources.Add("CostMan");
	ReflectionParameters.ManResources.Add("AddExpensesMan");
	ReflectionParameters.ManResources.Add("LaborCostsMan");
	ReflectionParameters.ManResources.Add("ItemizedFixedCostsManag");
	ReflectionParameters.ManResources.Add("ItemizedVariableCostsManag");
	ReflectionParameters.ManResources.Add("ProvisionForImpairmentMan");
	ReflectionParameters.LocalResources.Add("LocalCost");
	ReflectionParameters.LocalResources.Add("AddExpensesLocal");
	ReflectionParameters.LocalResources.Add("LaborCostsLocal");
	ReflectionParameters.LocalResources.Add("ItemizedFixedCostsCompl");
	ReflectionParameters.LocalResources.Add("ItemizedVariableCostsCompl");
	ReflectionParameters.LocalResources.Add("ProvisionForImpairmentLocal");
	ReflectionParameters.ResourcesQuantity.Add("Count");
	ReflectionParameters.ContainsUnbalancedData = True;
	
	ReflectionParameters.TypeOfAccountingData = Enums.AccountingDataTypes.Products;
	ReflectionParameters.DataPathDopSettingUpHouseholdOfOperation = StrReplace(
		"CASE
		|		WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.SaleWithDeferredTransferOfTitle)
		|			THEN CASE
		|				WHEN DataSourceAlias.RecordType = VALUE(AccumulationRecordType.Receipt) OR DataSourceAlias.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
		|					THEN VALUE(Catalog.BusinessTransactionsSettings.ShipmentWithDeferredTransferOfTitle)
		|				ELSE DataSourceAlias.BusinessTransactionSetting
		|			END
		|		WHEN DataSourceAlias.BusinessTransactionSetting IN (VALUE(Catalog.BusinessTransactionsSettings.ProductsReleaseItemized),
		|			VALUE(Catalog.BusinessTransactionsSettings.ProductsReleaseLaborCosts))
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.ProductsRelease)
		|		WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.PurchaseInvoiceConsignmentStockLost)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.RecordDebtToConsignor)
		|		WHEN DataSourceAlias.BusinessOperation = VALUE(Enum.BusinessTransactions.InternalGoodsReceipt)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.InternalGoodsReceipt)
		|		WHEN DataSourceAlias.ItemsLocationAttributes.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReceivingForPrincipal)
		|		WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.ReportToMaterialProvider2_5)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.TransferToMaterialProvider2_5)
		|		WHEN DataSourceAlias.Recorder REFS Document.PurchaseAdjustment
		|			THEN CASE
		|				WHEN DataSourceAlias.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)
		|					THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseOfReceipt)
		|				WHEN DataSourceAlias.BusinessOperation = VALUE(Enum.BusinessTransactions.DebitNoteForPreviousPeriod)
		|					THEN VALUE(Catalog.BusinessTransactionsSettings.PurchaseFromSupplier)
		|				WHEN DataSourceAlias.BusinessOperation = VALUE(Enum.BusinessTransactions.DebitNoteWithWritingOffAsExpenses)
		|					THEN VALUE(Catalog.BusinessTransactionsSettings.GoodsConsumptionOnDemand)
		|				ELSE DataSourceAlias.BusinessTransactionSetting
		|			END
		|		WHEN DataSourceAlias.Recorder REFS Document.SaleAdjustment
		|			THEN CASE
		|				WHEN DataSourceAlias.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods)
		|					THEN VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGoodsFromCustomerOfPreviousPeriods)
		|				WHEN DataSourceAlias.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsReturnViaCommissionAgentOfPreviousPeriods)
		|					THEN VALUE(Catalog.BusinessTransactionsSettings.GoodsReturnViaCommissionAgentOfPreviousPeriods)
		|				WHEN DataSourceAlias.BusinessOperation = VALUE(Enum.BusinessTransactions.ReverseOfSale)
		|					THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSale)
		|				ELSE DataSourceAlias.BusinessTransactionSetting
		|			END
		|		ELSE DataSourceAlias.BusinessTransactionSetting
		|	END",
		"DataSourceAlias",
		ReflectionParameters.DataSourceAlias);
	IdentifyIndicators(ReflectionParameters);
	
	If RegisterMetadata = Undefined Then
		RegisterMetadata = CreateRecordSet().Metadata();
	EndIf;
	
	FinancialAccountingByBalanceSheetRegisterData.FillReflectionParametersByRegisterMetadata(ReflectionParameters, RegisterMetadata);
	
	Return ReflectionParameters;
	
EndFunction

#EndRegion

#Region BackdateJobQueue

// Data for the formation of tasks for non-operational document verification.
// Called when writing a set of register entries.
// 
// Parameters:
//  RecordSet - AccumulationRegisterRecordSet, InformationRegisterRecordSet - A recordable set of source register records.
//  KindsOfTasks - Array of CatalogRef.BackdateJobKinds - List of types of tasks.
//                According to this list, new tasks must be registered according to the recorded register data.
//  TempTablesManager - Undefined, TempTablesManager - When specifying the MW, the data from the temporary tables will be used when creating new tasks.
//  DataForRegisteringTasks - Undefined, ValueTable - A table with data for registering new tasks.
// 
// Returns:
//  ValueTable - Data For The Formation Of Tasks For Non-Operational Document Verification:
// * Organization - CatalogRef.Companies - The organization for which the new task will be generated.
// * TaskPeriod  - Date - The task period. Coincides with the period of the recorded data in the register.
// * Document - DocumentRef - Link to the document for which the task will be registered.
// * JobKind - CatalogRef.BackdateJobKinds - Type of registered task.
//
Function DataForFormationOfTasksForNonOperationalDocumentVerification(RecordSet, KindsOfTasks,
	TempTablesManager = Undefined, DataForRegisteringTasks = Undefined) Export
	
	If Not DataForRegisteringTasks = Undefined Then
		Return DataForRegisteringTasks;
	EndIf;
	
	DataTable = InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.TaskGenerationTable();
	
	Return DataTable;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Defines register indicators
//
// Parameters:
//  ReflectionParameters - See ParametersForReflectingRegisteredRecordsInFinancialAccounting
//
Procedure IdentifyIndicators(ReflectionParameters)
	
	// Cost
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("CostMan");
	IndicatorReflectionParameters.LocalResources.Add("LocalCost");
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Cost, IndicatorReflectionParameters);
	
	// Cost excl.VAT
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("CostExcludingVAT");
	IndicatorReflectionParameters.LocalResources.Add("0");
	IndicatorReflectionParameters.ResourcesQuantity.Add("0");
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.CostExcludingVAT, IndicatorReflectionParameters);
	
	// VAT amount of the Cost
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("Cost");
	IndicatorReflectionParameters.ManResources.Add("-CostExcludingVAT");
	IndicatorReflectionParameters.LocalResources.Add("0");
	IndicatorReflectionParameters.ResourcesQuantity.Add("0");
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.VATCostAmount, IndicatorReflectionParameters);
	
	// Additional expenses Amount
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("AddExpensesMan");
	IndicatorReflectionParameters.ManResources.Add("LaborCostsMan");
	IndicatorReflectionParameters.ManResources.Add("ItemizedFixedCostsManag");
	IndicatorReflectionParameters.ManResources.Add("ItemizedVariableCostsManag");
	IndicatorReflectionParameters.LocalResources.Add("AddExpensesLocal");
	IndicatorReflectionParameters.LocalResources.Add("LaborCostsLocal");
	IndicatorReflectionParameters.LocalResources.Add("ItemizedFixedCostsCompl");
	IndicatorReflectionParameters.LocalResources.Add("ItemizedVariableCostsCompl");
	IndicatorReflectionParameters.ResourcesQuantity.Add("0");
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AdditExpenseAmount, IndicatorReflectionParameters);
	
	// Additional expensed amount excluding VAT
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("AdditionalExpensesExcludingVAT");
	IndicatorReflectionParameters.ManResources.Add("LaborCosts");
	IndicatorReflectionParameters.ManResources.Add("ItemizedFixedCostsExcludingVAT");
	IndicatorReflectionParameters.ManResources.Add("ItemizedVariableCostsExcludingVAT");
	IndicatorReflectionParameters.LocalResources.Add("0");
	IndicatorReflectionParameters.ResourcesQuantity.Add("0");
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AdditionalExpensesAmountExcludingVAT, IndicatorReflectionParameters);
	
	// VAT amount of the Additional expense amount
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("AddExpensesForGoods");
	IndicatorReflectionParameters.ManResources.Add("ItemizedFixedCostsIncludingVAT");
	IndicatorReflectionParameters.ManResources.Add("ItemizedVariableCostsIncludingVAT");
	IndicatorReflectionParameters.ManResources.Add("-AdditionalExpensesExcludingVAT");
	IndicatorReflectionParameters.ManResources.Add("-ItemizedFixedCostsExcludingVAT");
	IndicatorReflectionParameters.ManResources.Add("-ItemizedVariableCostsExcludingVAT");
	IndicatorReflectionParameters.LocalResources.Add("0");
	IndicatorReflectionParameters.ResourcesQuantity.Add("0");
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountVATAdditionalExpense, IndicatorReflectionParameters);
	
	// Reserve for impairment
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("ProvisionForImpairmentMan");
	IndicatorReflectionParameters.LocalResources.Add("ProvisionForImpairmentLocal");
	IndicatorReflectionParameters.ResourcesQuantity.Add("0");
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.ProvisionForImpairment, IndicatorReflectionParameters);
	
EndProcedure

#Region SavingRegisteredRecords

// Adds a service property to the additional document properties
// that stores the start and end dates of the period
// for which you want to save movements from the IB to the recordable set of register entries.
//
Procedure InitializeSavingDocumentRegisteredRecordsForPeriod(AdditionalDocumentProperties,
			BeginOfPeriod = Undefined, EndOfPeriod = Undefined) Export
	
	AdditionalDocumentProperties.Insert("AddRegisteredRecordsFromInformationSecurityForPeriod", New Structure);
	
	AdditionalDocumentProperties.AddRegisteredRecordsFromInformationSecurityForPeriod.Insert(
		"BeginOfPeriod",
		?(ValueIsFilled(BeginOfPeriod), BeginOfPeriod, Date(1,1,1)));
	
	AdditionalDocumentProperties.AddRegisteredRecordsFromInformationSecurityForPeriod.Insert(
		"EndOfPeriod", 
		?(ValueIsFilled(EndOfPeriod),  EndOfPeriod,  AddMonth(EndOfMonth(CurrentSessionDate()), 12*100)));
	
EndProcedure

Procedure InitializeSavingRecordsetRegisteredRecordsForPeriod(Movement, AdditionalDocumentProperties) Export
	
	If AdditionalDocumentProperties.Property("AddRegisteredRecordsFromInformationSecurityForPeriod") Then
		
		Movement.AdditionalProperties.Insert(
			"AddRegisteredRecordsFromInformationSecurityForPeriod",
			AdditionalDocumentProperties.AddRegisteredRecordsFromInformationSecurityForPeriod);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
