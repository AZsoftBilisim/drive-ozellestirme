#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the query text with the model structure of the temporary table "Tichodromadidae".
//
// Parameters:
//  AdditionalFields	 - String	 - List of additional fields.
//  
// Returns:
//	String - The text of the request for the formation of a temporary table in the input data.
//
Function TextDescriptionTTInitialBatchesOfOtherExpenses(AdditionalFields = "") Export
	
	QueryText = "
	|SELECT TOP 0
	|	Rows.Period,
	|	Rows.RecordType,
	|	Rows.Organization,
	|	Rows.Department,
	|	Rows.ExpenseItem,
	|	Rows.DimensionOfExpenses,
	|	Rows.AssetsLiabilitiesDimension,
	|	Rows.ExpenseReceiptDocument,
	|	Rows.LotVendorAttributes,
	|	Rows.LineOfBusiness,
	|	Rows.ItemsLocationAttributes,
	|	Rows.VATActivityType,
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS VATManag,
	|	0 AS LocalCost,
	|	0 AS VATLocal,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	Rows.BusinessOperation,
	|	
	|	Rows.FinRecordID,
	|	Rows.BusinessTransactionSetting
	|
	|	,&AdditionalFields
	|
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	AccumulationRegister.ItemisedExpensesLots AS Rows
	|";
	
	AddAdditionalFieldsToRequestText(AdditionalFields, QueryText);
	
	Return QueryText
	
EndFunction

// Forms the text of the query to build a temporary table of "Startupnotification".
//
// Parameters:
//  AdditionalFields	 - String	 - List of additional fields.
//  DifferentPeriodsInRegisteredRecordsArePossible - Boolean - specifies where the batch accounting parameters are stored, in the query parameters or in the temporary table vtparametersparty accounting for processing
//  
// Returns:
//	String - The text of the request for the formation of a temporary table of the party and other expenses.
//
Function QueryTextTableTTLotsOfOtherExpenses(AdditionalFields = "", DifferentPeriodsInRegisteredRecordsArePossible = False) Export
	
	QueryText = "
	|SELECT 
	|	TTInitialBatchesOfOtherExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	MAX(DocumentsRegistry.Organization) AS Organization
	|
	|INTO TTRegisterOfDocumentsOfMaterialOverheadsForAllocation
	|FROM 
	|	TTInitialBatchesOfOtherExpenses AS TTInitialBatchesOfOtherExpenses
	|		INNER JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|			ON TTInitialBatchesOfOtherExpenses.DimensionOfExpenses = DocumentsRegistry.Ref
	|WHERE
	|	(DocumentsRegistry.Ref REFS Document.OBEntry
	|	OR DocumentsRegistry.Ref REFS Document.OBEntryOtherExpenses
	|	OR DocumentsRegistry.Ref REFS Document.TransferOrder
	|	OR DocumentsRegistry.Ref REFS Document.ByAssemblyDisassemblyOrder
	|	OR DocumentsRegistry.Ref REFS Document.PurchaseOrder
	|	OR DocumentsRegistry.Ref REFS Document.VendorInvoice
	|	OR DocumentsRegistry.Ref REFS Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany
	|	OR DocumentsRegistry.Ref REFS Document.AssemblyFromComponents)
	|	AND NOT DocumentsRegistry.AdditionalRecord
	|
	|GROUP BY
	|	TTInitialBatchesOfOtherExpenses.DimensionOfExpenses
	|;
	|
	|SELECT
	|	Rows.Period AS Period,
	|	Rows.RecordType AS RecordType,
	|	Rows.Organization AS Organization,
	|	Rows.Department AS Department,
	|	Rows.ExpenseItem AS ExpenseItem,
	|	Rows.DimensionOfExpenses AS DimensionOfExpenses,
	|	Rows.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	Rows.ExpenseReceiptDocument AS ExpenseReceiptDocument,
	|	Rows.LotVendorAttributes AS LotVendorAttributes,
	|	(CASE
	|		WHEN ISNULL(LinesOfBusiness.CostAccounting, FALSE)
	|			THEN Rows.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) END) AS LineOfBusiness,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	(CASE
	|		WHEN &BatchAccountingVersion22 THEN Rows.VATActivityType
	|		ELSE UNDEFINED END) AS VATActivityType,
	|
	|	(CASE
	|		WHEN AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN Rows.Cost
	|		ELSE 0 END) AS Cost,
	|	(CASE
	|		WHEN AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN Rows.CostExcludingVAT
	|		ELSE 0 END) AS CostExcludingVAT,
	|	(CASE
	|		WHEN &CompanyManagementAccounting
	|			AND (AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|				)
	|			THEN Rows.VATManag
	|		ELSE 0 END) AS VATManag,
	|
	|	(CASE 
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting THEN 0
	|		WHEN AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN Rows.LocalCost
	|		ELSE 0 END) AS LocalCost,
	|	(CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting THEN 0
	|		WHEN AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|		 AND NOT AssetRef.EnteredInTaxAccounting
	|			THEN Rows.LocalCost - Rows.CostTD
	|		WHEN AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN Rows.PermanentDifference
	|		ELSE 0 END) AS PermanentDifference,
	|	(CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting THEN 0
	|		WHEN AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN Rows.CostTD
	|		ELSE 0 END) AS CostTD,
	|	(CASE
	|		WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting THEN 0
	|		WHEN AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN Rows.VATLocal
	|		ELSE 0 END) AS VATLocal,
	|	Rows.BusinessOperation,
	|		
	|	CASE
	|		WHEN VALUETYPE(Rows.DimensionOfExpenses) = TYPE(Catalog.CostCenters)
	|			THEN CAST(Rows.DimensionOfExpenses AS Catalog.CostCenters).Organization
	|		WHEN VALUETYPE(Rows.DimensionOfExpenses) = TYPE(Catalog.ProductionLots)
	|			THEN CAST(Rows.DimensionOfExpenses AS Catalog.ProductionLots).Organization
	|		WHEN VALUETYPE(Rows.DimensionOfExpenses) = TYPE(Document.CustomerInvoiceIntercompany)
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.CustomerInvoiceIntercompany).CompanyRecipient
	|		WHEN VALUETYPE(Rows.DimensionOfExpenses) = TYPE(Document.InventoryTransfer)
	|		 AND CAST(Rows.DimensionOfExpenses AS Document.InventoryTransfer).BusinessOperation
	|				= VALUE(Enum.BusinessTransactions.TransferOfGoodsBetweenBranchOffices)
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.InventoryTransfer).CompanyRecipient
	|		WHEN VALUETYPE(Rows.DimensionOfExpenses) = TYPE(Document.TransferOrder)
	|		 AND CAST(Rows.DimensionOfExpenses AS Document.TransferOrder).BusinessOperation
	|				= VALUE(Enum.BusinessTransactions.TransferOfGoodsBetweenBranchOffices)
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.TransferOrder).CompanyRecipient
	|		WHEN VALUETYPE(Rows.DimensionOfExpenses) = TYPE(Document.InventoryTransfer)
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.InventoryTransfer).Organization
	|		WHEN ISNULL(TTDocumentRegistry.Organization, VALUE(Catalog.Companies.EmptyRef)) 
	|				<> VALUE(Catalog.Companies.EmptyRef)
	|			THEN TTDocumentRegistry.Organization
	|		ELSE Rows.Organization
	|	END AS CompanyRecipient,
	|
	|	Rows.FinRecordID AS FinRecordID,
	|	Rows.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|	,&AdditionalFields
	|
	|INTO TTLotsOfOtherExpenses
	|FROM
	|	TTInitialBatchesOfOtherExpenses AS Rows
	|	INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS AssetRef
	|		ON AssetRef.Ref = Rows.ExpenseItem
	|	LEFT JOIN Catalog.LinesOfBusiness AS LinesOfBusiness
	|		ON LinesOfBusiness.Ref = Rows.LineOfBusiness
	|	LEFT JOIN Constants AS TableOfConstants_ ON TRUE
	|	LEFT JOIN TTRegisterOfDocumentsOfMaterialOverheadsForAllocation AS TTDocumentRegistry
	|		ON Rows.DimensionOfExpenses = TTDocumentRegistry.DimensionOfExpenses
	// The condition for selecting records must match the functions:
	// See CostCalculationDataPreparation.TextOfArticleRequestWithSeparateConsiderationOfNDSInRegisterOfPartyOfOtherExpenses()
	// See VATAccountingERP.ReflectPurchaseFromSupplier()
	// See BatchAccountingServer.TextsOfCancellationRequests()
	|WHERE
	|	&UseAccountingOfOtherIncomeExpenses
	|	AND (AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			AND (&ItemizeMaterialAndItemizedExpensesInInventoryCost
	|				OR &SeparateAccountingOfGoodsByVATTaxation
	|			)
	|		OR AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			AND (&ItemizeMaterialAndItemizedExpensesInInventoryCost
	|				OR &SeparateAccountingOfGoodsByVATTaxation
	|			)
	|	)
	|";
	
	JoinText = "LEFT JOIN Constants AS TableOfConstants_ ON TRUE";
	
	If Not DifferentPeriodsInRegisteredRecordsArePossible Then
		
		QueryText = StrReplace(QueryText, JoinText, "");
		
	Else
		
		// Batch accounting parameters are stored not in the query parameters, but in the fields of the same name in the temporary table of the Batch Accounting parameters for the audit.
		QueryText = StrReplace(QueryText, JoinText,
			"INNER JOIN TTParametersOfBatchAccountingForConducting AS BatchAccountingParameters
			|	ON BatchAccountingParameters.Period = BEGINOFPERIOD(Rows.Period, MONTH)
			|	 AND BatchAccountingParameters.Organization = Rows.Organization");
		
		ParametersArray = New Array;
		ParametersArray.Add("UseAccountingOfOtherIncomeExpensesInLocalAccounting");
		ParametersArray.Add("UseAccountingOfOtherIncomeExpenses");
		ParametersArray.Add("BatchAccountingVersion22");
		ParametersArray.Add("CompanyManagementAccounting");
		ParametersArray.Add("SeparateAccountingOfItemizedProductionCostsForVATTaxation");
		ParametersArray.Add("SeparateAccountingOfGoodsByVATTaxation");
		ParametersArray.Add("SeparateAccountingOfUSNGoods");
		ParametersArray.Add("ItemizeMaterialAndItemizedExpensesInInventoryCost");
		ParametersArray.Add("WriteOffVATByExpensesThatAreNotRecordedInTA");
		ParametersArray.Add("PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT");
		
		For Each CurrentParameter In ParametersArray Do
			QueryText = StrReplace(QueryText, "&" + CurrentParameter, "BatchAccountingParameters." + CurrentParameter);
		EndDo;
		
	EndIf;
	
	AddAdditionalFieldsToRequestText(AdditionalFields, QueryText);
	
	Return QueryText;
	
EndFunction

// Generates the request body for the formation of movements on the register of the "Party other expenses".
//
// Parameters:
//  AdditionalFields	 - String	 - List of additional fields.
//  
// Returns:
//	String - The text of the request for the formation of the batch table of other expenses.
//
Function QueryTextTableItemisedExpensesLots(AdditionalFields = "") Export
	
	QueryText = "
	// Formation of a table for writing to the register of "Lots of other expenses".
	|SELECT
	|	Rows.Period AS Period,
	|	Rows.RecordType AS RecordType,
	|	Rows.Organization AS Organization,
	|	Rows.Department AS Department,
	|	Rows.ExpenseItem AS ExpenseItem,
	|	Rows.DimensionOfExpenses AS DimensionOfExpenses,
	|	Rows.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	Rows.ExpenseReceiptDocument AS ExpenseReceiptDocument,
	|	Rows.LotVendorAttributes AS LotVendorAttributes,
	|	Rows.LineOfBusiness AS LineOfBusiness,
	|	Rows.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Rows.VATActivityType AS VATActivityType,
	|
	|	Rows.Cost AS Cost,
	|	Rows.CostExcludingVAT AS CostExcludingVAT,
	|	Rows.VATManag AS VATManag,
	|
	|	Rows.LocalCost AS LocalCost,
	|	Rows.PermanentDifference AS PermanentDifference,
	|	Rows.CostTD AS CostTD,
	|	Rows.VATLocal AS VATLocal,
	|
	|	Rows.BusinessOperation,
	|
	|	Rows.FinRecordID AS FinRecordID,
	|	Rows.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|	,&AdditionalFields
	|
	|FROM
	|	TTLotsOfOtherExpenses AS Rows
	|WHERE
	|	(Rows.Cost <> 0 OR Rows.CostExcludingVAT <> 0 OR Rows.VATManag <> 0
	|		OR Rows.LocalCost <> 0 OR Rows.VATLocal <> 0
	|		OR Rows.PermanentDifference <> 0 OR Rows.CostTD <> 0)
	|";
	
	AddAdditionalFieldsToRequestText(AdditionalFields, QueryText);
		
	Return QueryText;
	
EndFunction

// Forms part of the request text for getting the value of the recipient Organization field.
//
// Returns:
//	String - The text of the request for the formation of the value of the Recipient Organization field.
//
Function RequestTextValueOfRecipientOrganizationField(TableName = "") Export
	
	QueryText = "
	|	CASE
	|		WHEN Rows.DimensionOfExpenses REFS Catalog.Companies
	|			THEN Rows.DimensionOfExpenses
	|		WHEN Rows.DimensionOfExpenses REFS Document.CustomerInvoiceServices
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.CustomerInvoiceServices).Organization
	|		WHEN Rows.DimensionOfExpenses REFS Document.OBEntry
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.OBEntry).Organization
	|		WHEN Rows.DimensionOfExpenses REFS Document.OBEntryOtherExpenses
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.OBEntryOtherExpenses).Organization
	|		WHEN Rows.DimensionOfExpenses REFS Document.MaterialProviderOrder2_5
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.MaterialProviderOrder2_5).Organization
	|		WHEN Rows.DimensionOfExpenses REFS Document.SalesOrder
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.SalesOrder).Organization
	|		WHEN Rows.DimensionOfExpenses REFS Document.TransferOrder
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.TransferOrder).Organization
	|		WHEN Rows.DimensionOfExpenses REFS Document.ByAssemblyDisassemblyOrder
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.ByAssemblyDisassemblyOrder).Organization
	|		WHEN Rows.DimensionOfExpenses REFS Document.PurchaseOrder
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.PurchaseOrder).Organization
	|		WHEN Rows.DimensionOfExpenses REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.RequestForReturnOfGoodsFromCustomer).Organization
	|		WHEN Rows.DimensionOfExpenses REFS Document.CustomerInvoiceIntercompany
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.CustomerInvoiceIntercompany).CompanyRecipient
	|		WHEN Rows.DimensionOfExpenses REFS Document.InventoryTransfer
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.InventoryTransfer).Organization
	|		WHEN Rows.DimensionOfExpenses REFS Document.VendorInvoice
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.VendorInvoice).Organization
	|		WHEN Rows.DimensionOfExpenses REFS Document.CustomerInvoice
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.CustomerInvoice).Organization
	|		WHEN Rows.DimensionOfExpenses REFS Document.CustomerInvoiceServicesAndAssets
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.CustomerInvoiceServicesAndAssets).Organization
	|		WHEN Rows.DimensionOfExpenses REFS Document.AssemblyFromComponents
	|			THEN CAST(Rows.DimensionOfExpenses AS Document.AssemblyFromComponents).Organization
	|		ELSE UNDEFINED
	|	END
	|";
	If Not IsBlankString(TableName) Then
		QueryText = StrReplace(QueryText, "Rows", TableName);
	EndIf;
	Return QueryText;
	
EndFunction

// Collects the structure from the request texts for further verification of the ban date.
// 
// Parameters:
// 	Query - Query - Request to check the date of the ban, you can set the parameters
// Returns:
// 	Structure - See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
Function RequestTextMonitoringBanDate(Query) Export
	RegisterName = Metadata.AccumulationRegisters.ItemisedExpensesLots.Name;
	NameOfChangeTable = "ChangesTableItemisedExpensesLots"; 
	StructureOfQueryTexts_ = DocumentsPosting.RequestTextTemplateBanDateControl(Query, 
		RegisterName, 
		NameOfChangeTable, 
		"FinancialOutline");
	Return StructureOfQueryTexts_

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

#EndRegion

#EndRegion

#Region Private

Procedure AddAdditionalFieldsToRequestText(AdditionalFields, QueryText)

	If Not ValueIsFilled(AdditionalFields) Then
		QueryText = StrReplace(QueryText, ",&AdditionalFields", "");
		Return;
	EndIf; 
	
	TextAdditionalFields = "";
	
	FieldList = StrSplit(AdditionalFields, ",");
	For Each FieldName In FieldList Do
		TextAdditionalFields = TextAdditionalFields + "
		|	,Rows." + FieldName;
	EndDo; 
	
	QueryText = StrReplace(QueryText, ",&AdditionalFields", TextAdditionalFields); 

EndProcedure

#EndRegion

#EndIf
