///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Reusable values for mechanisms
//	- batch accounting version 2.2
//	- cost calculation
//	- closing of the month.
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region LotRecordTypes

// Returns rules for filling in fields in primary document movements in the "Cost of goods" register.
//
// Parameters:
//	NameOfSelectionDocument - String - the name of the document for the selection of rows in the table; if not specified, displays a table of all documents
//
// Returns:
//	ValueTable - rules for filling in records obtained from the layout of the register of accumulation of cost of goods
//
Function RulesForFillingInRecordTypeField(NameOfSelectionDocument = "") Export
	
	RulesTable = New ValueTable;
	RulesTable.Columns.Add("DocumentName", 				 New TypeDescription("String"));
	RulesTable.Columns.Add("EmptyLoggerValue", New TypeDescription(CostCalculationUniversalAlgorithms.DescriptionOfDocumentTypes()));
	RulesTable.Columns.Add("BusinessOperation",   	 New TypeDescription("EnumRef.BusinessTransactions"));
	RulesTable.Columns.Add("PositiveQuantity", 	 New TypeDescription("Boolean, Null")); // acceptable Undefined
	RulesTable.Columns.Add("EntryTypeReceipt", 		  	 New TypeDescription("EnumRef.LotRecordTypes, Null")); // acceptable Undefined
	RulesTable.Columns.Add("EntryTypeExpense", 		  	 New TypeDescription("EnumRef.LotRecordTypes, Null")); // acceptable Undefined
	RulesTable.Columns.Add("DocumentSourceInParish", 	 New TypeDescription("Boolean"));
	RulesTable.Columns.Add("DocumentSourceInExpense", 	 New TypeDescription("Boolean"));
	RulesTable.Columns.Add("CorPartyAtExpense", 		 New TypeDescription("Boolean"));
	
	#Region ExpenseReport
	
	CurrentDocument = Metadata.Documents.ExpenseReport.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.AddExpensesForGoods;
	
	EndIf;
	
	#EndRegion
	#Region InternalAcceptanceCertificate
	
	CurrentDocument = Metadata.Documents.InternalAcceptanceCertificate.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.WorkAcceptanceAndTransferBetweenBusinessUnits;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.InternalWorkReceipt;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.TransferOnAssignmentBasis;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CurrentPeriodCorrections;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CorrectPreviousPeriodTransfer;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
	
	EndIf;
	
	#EndRegion
	#Region CustomerInvoiceServices
	
	CurrentDocument = Metadata.Documents.CustomerInvoiceServices.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
	
	EndIf;
	
	#EndRegion
	
	#Region OBEntry
	
	CurrentDocument = Metadata.Documents.OBEntry.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsRecordingAsReceived;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferToProduction;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.DocumentSourceInParish = True;
	
	EndIf;
	
	#EndRegion
	
	#Region OBEntryGoods
	
	CurrentDocument = Metadata.Documents.OBEntryGoods.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsRecordingAsReceived;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferToProduction;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.DocumentSourceInParish = True;
	
	EndIf;
	
	#EndRegion
	
	#Region InventoryConsumption
	
	CurrentDocument = Metadata.Documents.InventoryConsumption.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsConsumptionOnDemand;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferToOperation;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.CommissioningACAndTA;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferToFixedAssets;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferToIntangibleAssetsAndRD;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferForOtherPurposes;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ConsumptionReverseTransaction;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInExpense = True;
	
	EndIf;
	
	#EndRegion
	
	

	
	#Region IntercompanyGoodsReturn
	
	CurrentDocument = Metadata.Documents.IntercompanyGoodsReturn.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.IntercompanyGoodsReturn;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReverseOfSale;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReverseOfSaleReturnToAnotherWarehouse;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.ReturnToAnotherWarehouse;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReturnToAnotherWarehouse;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PreviousPeriodReturn;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.IntercompanyCommissionReturn;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsReceiptByGoodsReturn;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
	
	EndIf;
	
	#EndRegion
	
	#Region ReturnOfGoodsFromCustomer
	
	CurrentDocument = Metadata.Documents.ReturnOfGoodsFromCustomer.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsReceiptByGoodsReturn;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnPackageFromCustomerOfPreviousPeriods;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PreviousPeriodReturn;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PreviousPeriodReturn;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferredPackageReverseTransaction;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferredPackageReverseTransactionReturnToAnotherWarehouse;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.ReturnToAnotherWarehouse;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReverseOfSale;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReverseOfSaleReturnToAnotherWarehouse;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.ReturnToAnotherWarehouse;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReturnToAnotherWarehouse;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReturnToAnotherWarehouse;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsViaCommissionAgent;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
	
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsReturnViaCommissionAgentOfPreviousPeriods;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PreviousPeriodReturn;
		NewRule.DocumentSourceInParish = True;
	
	EndIf;
	
	#EndRegion
	
	#Region ReturnOfGoodsToVendor
	
	CurrentDocument = Metadata.Documents.ReturnOfGoodsToVendor.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToVendor;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToConsignor;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
	
	EndIf;
	
	#EndRegion
	
	#Region RedemptionOfGoodsFromStorage
	
	CurrentDocument = Metadata.Documents.RedemptionOfGoodsFromStorage.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.RedemptionOfGoodsTransferredToProduction;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.RedemptionOfGoodsFromStorage;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.RedemptionOfGoodsTransferredToStorage;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
	
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.RedemptionOfProviderGoods;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
	
	EndIf;
	
	#EndRegion
	
	#Region RedemptionOfGoodsByCustodian
	
	CurrentDocument = Metadata.Documents.RedemptionOfGoodsByCustodian.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.RedemptionOfGoodsByToller;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.RedemptionOfGoodsByCustodian;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
	
	EndIf;
	
	#EndRegion
	
	
	#Region MovementOfProductsAndMaterials
	
	CurrentDocument = Metadata.Documents.MovementOfProductsAndMaterials.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProducts;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.InternalGoodsReceipt;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.TransferOnAssignmentBasis;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CurrentPeriodCorrections;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CorrectPreviousPeriodTransfer;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
	
	EndIf;
	
	#EndRegion
	#Region ApplicationForImportationOfGoods
	
	CurrentDocument = Metadata.Documents.ApplicationForImportationOfGoods.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CostAdjustment;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.DebitNoteForPreviousPeriod;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.AddExpensesLotIsSpecified;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.AdditionalExpensesReverseTransaction;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.IncludeExciseInCost;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.DocumentSourceInParish = True;
	
	EndIf;
	
	#EndRegion
	
	#Region CorrectionOfSidedBalanceInCompanyGoodsAccounting
	
	CurrentDocument = Metadata.Documents.CorrectionOfSidedBalanceInCompanyGoodsAccounting.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsAssignmentAdjustments;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
	
	EndIf;
	
	#EndRegion
	
	
	#Region InventoryAssignmentAdjustment
	
	CurrentDocument = Metadata.Documents.InventoryAssignmentAdjustment.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsAssignmentAdjustments;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
	
	EndIf;
	
	#EndRegion
	
	
	
	#Region PurchaseAdjustment
	
	CurrentDocument = Metadata.Documents.PurchaseAdjustment.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CostAdjustment;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.ConsumptionReverseTransaction;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.AddExpensesLotIsSpecified;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToVendor;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToVendor;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CostAdjustment;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.DebitNoteForPreviousPeriod;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.DebitNoteForPreviousPeriod;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReceivingForPrincipal;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.DebitNoteForPreviousPeriod;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.AdditionalExpensesReverseTransaction;
		NewRule.DocumentSourceInParish = True;
	
	EndIf;
	
	#EndRegion
	
	#Region SaleAdjustment
	
	CurrentDocument = Metadata.Documents.SaleAdjustment.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ConsumptionGoodsInTransit;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.SaleOfTransferredReturnablePackaging;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ConsignmentSale;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PreviousPeriodReturn;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnPackageFromCustomerOfPreviousPeriods;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PreviousPeriodReturn;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReverseOfSale;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferredPackageReverseTransaction;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CorrectPreviousPeriodTransfer;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CorrectPreviousPeriodTransfer;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CorrectPreviousPeriodTransfer;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CorrectPreviousPeriodTransfer;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CorrectPreviousPeriodTransfer;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ConsumptionReverseTransaction;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ConsumptionReverseTransaction;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ConsumptionReverseTransaction;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ConsumptionReverseTransaction;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ConsumptionReverseTransaction;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProviderAdjustmentOfPastPeriod;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PreviousPeriodReturn;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProviderAdjustmentOfPastPeriod;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
	
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsReturnViaCommissionAgentOfPreviousPeriods;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PreviousPeriodReturn;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.AdjustBeforeEnteringBalance;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PreviousPeriodReturn;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReverseOfSaleReturnToAnotherWarehouse;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.ReturnToAnotherWarehouse;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferredPackageReverseTransactionReturnToAnotherWarehouse;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.ReturnToAnotherWarehouse;
		NewRule.DocumentSourceInParish = True;
		
	EndIf;
	
	#EndRegion
	
	#Region RegisterAdjustment
	
	CurrentDocument = Metadata.Documents.RegisterAdjustment.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
	
	EndIf;
	
	#EndRegion
	
	
	#Region WIPOpeningBalancesByProductionLots
	
	CurrentDocument = Metadata.Documents.WIPOpeningBalancesByProductionLots.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.OBEntryProductionLotCosts;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.OBEntryProductionLotCosts;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.DocumentSourceInParish = True;
	
	EndIf;
	
	#EndRegion
	
	#Region InventorySurplusRecognition
	
	CurrentDocument = Metadata.Documents.InventorySurplusRecognition.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsRecordingAsReceived;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CurrentPeriodCorrections;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.DocumentSourceInParish = True;
	
	EndIf;
	
	#EndRegion
	
	#Region RecognitionOfStockSurplusShippedToCustomer
	
	CurrentDocument = Metadata.Documents.RecognitionOfStockSurplusShippedToCustomer.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfConsignor;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfDepositor;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.RecognitionOfStockSurplusShippedToCustomer;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
	
	EndIf;
	
	#EndRegion
	
	#Region GoodsShipmentFromStorage
	
	CurrentDocument = Metadata.Documents.GoodsShipmentFromStorage.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ConsumptionReverseTransaction;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInExpense = True;
	
	EndIf;
	
	#EndRegion
	
	#Region GoodsShipmentToCustomer
	
	CurrentDocument = Metadata.Documents.GoodsShipmentToCustomer.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsShipmentToCustomer;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CurrentPeriodCorrections;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CorrectPreviousPeriodTransfer;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
	
	EndIf;
	
	#EndRegion
	
	
	
	#Region ReportToMaterialProvider2_5
	
	CurrentDocument = Metadata.Documents.ReportToMaterialProvider2_5.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
	EndIf;
	
	#EndRegion
	
	#Region ConsumptionReportSubcontractingServicesDeliveredIntercompany
	
	CurrentDocument = Metadata.Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Name;
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		NewRule.CorPartyAtExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ProductsRelease;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Supplement;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsConsumptionOnDemand;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsConsumptionOnDemand;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.AdditionPreviousPeriod;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ExpensingToProductionLots;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Supplement;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		NewRule.CorPartyAtExpense = True;
	EndIf;
	
	#EndRegion
	
	#Region ConsignmentReportFromCustomer
	
	CurrentDocument = Metadata.Documents.ConsignmentReportFromCustomer.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ConsignmentReportFromCustomer;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ConsignmentReportFromCustomer;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReturnWithoutSourceDocument;
	
	EndIf;
	
	#EndRegion
	
	#Region WriteOffReportFromCommissionAgent
	
	CurrentDocument = Metadata.Documents.WriteOffReportFromCommissionAgent.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.WriteOffReportFromCommissionAgent;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ConsumptionReverseTransaction;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInExpense = True;
	
	EndIf;
	
	#EndRegion
	
	#Region PurchaseInvoiceConsignmentStockLost
	
	CurrentDocument = Metadata.Documents.PurchaseInvoiceConsignmentStockLost.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PurchaseInvoiceConsignmentStockLost;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PurchaseInvoiceConsignmentStockLost;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ConsumptionReverseTransaction;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
	
	EndIf;
	
	#EndRegion
	
	#Region RetailReturnsReport
	
	CurrentDocument = Metadata.Documents.RetailReturnsReport.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsReceiptByGoodsReturn;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReverseOfSale;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PreviousPeriodReturn;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReverseOfSaleReturnToAnotherWarehouse;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.ReturnToAnotherWarehouse;
		NewRule.DocumentSourceInParish = True;
	
	EndIf;
	
	#EndRegion
	
	#Region RetailSalesReport
	
	CurrentDocument = Metadata.Documents.RetailSalesReport.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.RetailSaleOfGoods;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ConsignmentSale;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
	
	EndIf;
	
	#EndRegion
	
	#Region ReportOnVMIAdjustment
	
	CurrentDocument = Metadata.Documents.ReportOnVMIAdjustment.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.WriteOffOfAcceptedGoodsAtExpenseOfDepositor;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ConsumptionReverseTransaction;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInExpense = True;
	
	EndIf;
	
	#EndRegion
	
	#Region WriteOffOfShippedGoods
	
	CurrentDocument = Metadata.Documents.WriteOffOfShippedGoods.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsWriteOffAtToller;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.WriteOffShortagesAtConsignorSExpense;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.WriteOffShortagesAtDepositorSExpense;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.WriteOffGoodsOfCommissionAgent;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.WriteOffOfShippedGoods;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ConsumptionReverseTransaction;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CurrentPeriodCorrections;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
	
	EndIf;
	
	#EndRegion
	
	
	#Region SubcontractorReport2_5
	
	CurrentDocument = Metadata.Documents.SubcontractorReport2_5.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ExpensingToProductionLots;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Supplement;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ExpensesToOtherProductionLots;
		NewRule.CorPartyAtExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ProductsRelease;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Supplement;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		NewRule.CorPartyAtExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ProductsRelease;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.CorPartyAtExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ProductsReleaseFixCost;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ProductsReleaseFixCost;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsConsumptionOnDemand;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.WriteOffForExpensesFixedCost;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PostingOfReleaseTargetCost;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
	
	EndIf;
	
	#EndRegion
	#Region CommissionReportIntercompany
	
	CurrentDocument = Metadata.Documents.CommissionReportIntercompany.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ConsignmentReportFromCustomer;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ConsignmentReportFromCustomer;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReturnWithoutSourceDocument;
	
	EndIf;
	
	#EndRegion
	
	#Region CommissionWriteOffReportIntercompany
	
	CurrentDocument = Metadata.Documents.CommissionWriteOffReportIntercompany.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.WriteOffReportFromCommissionAgent;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.WriteOffReportFromCommissionAgent;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ConsumptionReverseTransaction;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.WriteOffReportFromCommissionAgent;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PurchaseInvoiceConsignmentStockLost;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PurchaseInvoiceConsignmentStockLost;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.DocumentSourceInParish = True;
	
	EndIf;
	
	#EndRegion
	

	
	
	#Region CustomerInvoiceIntercompany
	
	CurrentDocument = Metadata.Documents.CustomerInvoiceIntercompany.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		NewRule.CorPartyAtExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
	
	EndIf;
	
	#EndRegion
	
	#Region TransferOfGoodsToBailee
	
	CurrentDocument = Metadata.Documents.TransferOfGoodsToBailee.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;

		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferToToller2_5;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CurrentPeriodCorrections;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CorrectPreviousPeriodTransfer;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
	
	EndIf;
	
	#EndRegion
	
	
	#Region InventoryTransfer
	
	CurrentDocument = Metadata.Documents.InventoryTransfer.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.InventoryTransfer;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.InternalGoodsReceipt;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.TransferOnAssignmentBasis;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CurrentPeriodCorrections;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CorrectPreviousPeriodTransfer;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
	
	EndIf;
	
	#EndRegion
	
	#Region GoodsMisgrading
	
	CurrentDocument = Metadata.Documents.GoodsMisgrading.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsMisgrading;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsMisgrading;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CurrentPeriodCorrections;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsMisgradingWithRevaluation;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		NewRule.CorPartyAtExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsMisgradingWithRevaluation;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CurrentPeriodCorrections;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ConsumptionReverseTransaction;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CorrectPreviousPeriodTransfer;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.DocumentSourceInParish = True;

		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsMisgradingWithRevaluation;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
	EndIf;
	
	#EndRegion
	
	#Region MisgradingOfGoodsAtCustodian
	
	CurrentDocument = Metadata.Documents.MisgradingOfGoodsAtCustodian.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsMisgrading;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsMisgrading;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CurrentPeriodCorrections;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsMisgradingWithRevaluation;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		NewRule.CorPartyAtExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsMisgradingWithRevaluation;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CurrentPeriodCorrections;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ConsumptionReverseTransaction;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsMisgradingWithRevaluation;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CorrectPreviousPeriodTransfer;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
	
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.DocumentSourceInParish = True;

	EndIf;
	
	#EndRegion
	
	
	#Region GoodsDamage
	
	CurrentDocument = Metadata.Documents.GoodsDamage.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsDamage;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsDamage;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CurrentPeriodCorrections;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsDamageRevaluation;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		NewRule.CorPartyAtExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsDamageRevaluation;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CurrentPeriodCorrections;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ConsumptionReverseTransaction;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CorrectPreviousPeriodTransfer;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.DocumentSourceInParish = True;

		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsDamageRevaluation;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
	
	EndIf;
	
	#EndRegion
	
	#Region DamageAtCustodian
	
	CurrentDocument = Metadata.Documents.DamageAtCustodian.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsDamage;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsDamage;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CurrentPeriodCorrections;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsDamageRevaluation;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		NewRule.CorPartyAtExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsDamageRevaluation;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CurrentPeriodCorrections;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ConsumptionReverseTransaction;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsDamageRevaluation;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CorrectPreviousPeriodTransfer;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
	
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.DocumentSourceInParish = True;
	
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		NewRule.DocumentSourceInExpense = True;

	EndIf;
	
	#EndRegion
	
	

	#Region ReceiptOfGoodsToWarehouse
	
	CurrentDocument = Metadata.Documents.ReceiptOfGoodsToWarehouse.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PurchaseAdjustment;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CurrentPeriodCorrections;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CorrectPreviousPeriodTransfer;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
	
	EndIf;
	
	#EndRegion

	#Region GoodsReceiptFromCustomer
	
	CurrentDocument = Metadata.Documents.GoodsReceiptFromCustomer.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsReceiptFromCustomer;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CorrectPreviousPeriodTransfer;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CurrentPeriodCorrections;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
	
	EndIf;
	
	#EndRegion
	
	#Region ReceiptOfGoodsFromCustodian
	
	CurrentDocument = Metadata.Documents.ReceiptOfGoodsFromCustodian.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnFromProcessingCompany2_5;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CurrentPeriodCorrections;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CorrectPreviousPeriodTransfer;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
	
	EndIf;
	
	#EndRegion
	
	#Region ReceiptOfServicesToBusinessUnit
	
	CurrentDocument = Metadata.Documents.ReceiptOfServicesToBusinessUnit.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CurrentPeriodCorrections;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
	EndIf;
	
	#EndRegion
	
	#Region VendorInvoice
	
	CurrentDocument = Metadata.Documents.VendorInvoice.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PurchaseByImport;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ImportGoodsInTransit;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReceivingForPrincipal;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToVendor;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		// For households. The operations of the procurementposter and the procurementaesfacturovkapostavka stranakheapacturovkapostavka
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.AddExpensesLotIsSpecified;
		NewRule.DocumentSourceInParish = True;
		
	EndIf;
	
	#EndRegion
	
	#Region VendorInvoiceServicesAndAssets
	
	CurrentDocument = Metadata.Documents.VendorInvoiceServicesAndAssets.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.AddExpensesForGoods;
	
	EndIf;
	
	#EndRegion
	
	#Region GoodsReceiptForStorage
	
	CurrentDocument = Metadata.Documents.GoodsReceiptForStorage.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.DocumentSourceInParish = True;
	
	EndIf;
	
	#EndRegion
	#Region BackflushProduction
	
	CurrentDocument = Metadata.Documents.BackflushProduction.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ProductsReleaseFixCost;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ProductsReleaseFixCost;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Supplement;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ProductsReleaseFixCost;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ProductsReleaseFixCost;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.AdditionPreviousPeriod;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ProductsRelease;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ProductsRelease;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ProductsRelease;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.AdditionPreviousPeriod;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ProductsRelease;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.AdditionPreviousPeriod;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProductionFixedCost;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProductionFixedCost;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.AdditionPreviousPeriod;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProductionFixedCost;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ExpensingToProductionLots;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Supplement;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ExpensesToOtherProductionLots;
		NewRule.CorPartyAtExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ExpensingToProductionLots;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.AdditionPreviousPeriod;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReverseOfCostAllocationToOtherLots;
		NewRule.DocumentSourceInExpense = True;
		NewRule.CorPartyAtExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ExpensingToProductionLots;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInExpense = True;
		NewRule.CorPartyAtExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ExpensingToProductionLots;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsConsumptionOnDemand;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsConsumptionOnDemand;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.AdditionPreviousPeriod;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.WriteOffForExpensesFixedCost;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferToFixedAssets;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferToIntangibleAssetsAndRD;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.AdditionPreviousPeriod;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.AdditionPreviousPeriod;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PostingOfReleaseTargetCost;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PostingOfReleaseTargetCost;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.PositiveQuantity = False;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Supplement;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		NewRule.CorPartyAtExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ConsignedGoodsWriteOff;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
	EndIf;
	
	#EndRegion
	#Region OtherGoodsRecordingAsReceived
	
	CurrentDocument = Metadata.Documents.OtherGoodsRecordingAsReceived.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsRecordingAsReceived;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferToFixedAssets;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PreviousPeriodReturn;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferToIntangibleAssetsAndRD;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PreviousPeriodReturn;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferForOtherPurposes;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PreviousPeriodReturn;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.InventoryConsumptionReverseTransaction;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PreviousPeriodReturn;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.InventoryConsumptionReverseTransaction;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReturnReverseTransaction;
		NewRule.DocumentSourceInExpense = True;

		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInParish = True;
	
	EndIf;
	
	#EndRegion
	
	#Region OtherIncomeExpenses
	
	CurrentDocument = Metadata.Documents.OtherIncomeExpenses.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.AddExpensesForGoods;
	
	EndIf;
	
	#EndRegion
	#Region RecyclableWasteAllocation
	
	CurrentDocument = Metadata.Documents.RecyclableWasteAllocation.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ProductsReleaseFixCost;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ProductsReleaseFixCost;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ProductsReleaseFixCost;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ProductsReleaseFixCost;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.AdditionPreviousPeriod;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.AdditionPreviousPeriod;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInParish = True;
		
	EndIf;
	
	#EndRegion
	#Region ProductionCostAllocation
	
	CurrentDocument = Metadata.Documents.ProductionCostAllocation.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ExpensingToProductionLots;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Supplement;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ExpensesToOtherProductionLots;
		NewRule.CorPartyAtExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsConsumptionOnDemand;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ConsignedGoodsWriteOff;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
	
	EndIf;
	
	#EndRegion
	#Region DeferredExpensesAllocation
	
	CurrentDocument = Metadata.Documents.DeferredExpensesAllocation.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.AddExpensesForGoods;
	
	EndIf;
	
	#EndRegion
	
	#Region CashVoucher
	
	CurrentDocument = Metadata.Documents.CashVoucher.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.AddExpensesForGoods;
	
	EndIf;
	
	#EndRegion
	
	#Region InventoryCostCalculation
	
	CurrentDocument = Metadata.Documents.InventoryCostCalculation.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.AddExpensesForGoods;
	
	EndIf;
	
	#EndRegion
	
	#Region CustomerInvoice
	
	CurrentDocument = Metadata.Documents.CustomerInvoice.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.SaleOfTransferredReturnablePackaging;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ConsignmentSale;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.TransferGoodsInTransit;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ConsumptionGoodsInTransit;
		NewRule.CorPartyAtExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		NewRule.CorPartyAtExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		NewRule.CorPartyAtExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
	
	EndIf;
	
	#EndRegion
	
	#Region AssemblyFromComponents
	
	CurrentDocument = Metadata.Documents.AssemblyFromComponents.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ExpensesToOtherProductionLots;
		NewRule.CorPartyAtExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ExpensesToOtherProductionLots;
		NewRule.CorPartyAtExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReverseOfCostAllocationToOtherLots;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
	
	EndIf;
	
	#EndRegion
	
	#Region BankAccountIssue
	
	CurrentDocument = Metadata.Documents.BankAccountIssue.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.AddExpensesForGoods;
	
	EndIf;
	
	#EndRegion
	
	#Region WriteOffOfGoodsShortages
	
	CurrentDocument = Metadata.Documents.WriteOffOfGoodsShortages.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsConsumption;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsConsumption;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CurrentPeriodCorrections;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ConsumptionReverseTransaction;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CurrentPeriodCorrections;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CorrectPreviousPeriodTransfer;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
	
	EndIf;
	
	#EndRegion
	
	#Region WriteOffDiscrepanciesBetweenReceiptAndPurchase
	
	CurrentDocument = Metadata.Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
	
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.WriteOffOfBalanceWithoutLot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ConsumptionReverseTransaction;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.StornoOfWriteOffOfBalanceWithoutLot;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInExpense = True;
		
	EndIf;
	
	#EndRegion
	
	#Region ReversingEntry
	
	CurrentDocument = Metadata.Documents.ReversingEntry.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CurrentPeriodCorrections;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReversingEntry;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.CorrectPreviousPeriodTransfer;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInParish = True;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PreviousPeriodCorrections;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.PurchaseAdjustment;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReverseOfCostAllocationToOtherLots;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.StornoOfWriteOffOfBalanceWithoutLot;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.AdditionalExpensesReverseTransaction;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.DebitNoteForPreviousPeriod;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Supplement;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.AdditionPreviousPeriod;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.AdditionPreviousPeriod;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReturnReverseTransaction;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.ConsumptionReverseTransaction;
		NewRule.DocumentSourceInParish = True;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ConsumptionReverseTransaction;
		NewRule.DocumentSourceInExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.TransferGoodsInTransit;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ReturnToAnotherWarehouse;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.ReverseOfPreviousPeriodsReturn;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.IncludeVATInCostExpenses;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.ReturnToAnotherWarehouseReverseTransaction;
		NewRule.DocumentSourceInParish = True;
	
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.TransferGoodsInTransit;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ConsumptionGoodsInTransit;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.IncludeExciseInCost;
		NewRule.DocumentSourceInParish = True;
		
	EndIf;
	
	#EndRegion
	
	
	#Region CCDImport
	
	CurrentDocument = Metadata.Documents.CCDImport.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.AdditionalExpensesWithLotDocumentSpecification;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.AddExpensesLotIsSpecified;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.AdditionalExpensesWithoutLotDocumentSpecification;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.AddExpensesLotIsNotSpecified;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.AdditionalExpensesReverseTransaction;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.DebitNoteForPreviousPeriod;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.IncludeVATInCostExpenses;
		NewRule.DocumentSourceInParish = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.IncludeExciseInCost;
		NewRule.DocumentSourceInParish = True;
	
	EndIf;
	
	#EndRegion
	#Region ProductionStage2_2
	
	CurrentDocument = Metadata.Documents.ProductionStage2_2.Name;
	
	If Not ValueIsFilled(NameOfSelectionDocument) Or Lower(NameOfSelectionDocument) = Lower(CurrentDocument) Then
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferToProduction;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ReturnFromProduction;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ProductsRelease;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ProductsRelease;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ProductsReleaseFixCost;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ProductsReleaseFixCost;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsConsumptionOnDemand;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferToFixedAssets;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferToIntangibleAssetsAndRD;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferForOtherPurposes;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.GoodsConsumptionOnDemand;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferForOtherPurposes;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Move;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferToFixedAssets;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferToIntangibleAssetsAndRD;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferForOtherPurposes;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ExpensingToProductionLots;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Supplement;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.ExpensesToOtherProductionLots;
		NewRule.CorPartyAtExpense = True;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.WriteOffForExpensesFixedCost;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.ConsignedGoodsWriteOff;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Consumption;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.PostingOfReleaseTargetCost;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Lot;
		
		NewRule = RulesTable.Add();
		NewRule.DocumentName = CurrentDocument;
		NewRule.BusinessOperation = Enums.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices;
		NewRule.EntryTypeReceipt = Enums.LotRecordTypes.Supplement;
		NewRule.EntryTypeExpense = Enums.LotRecordTypes.Supplement;
		NewRule.CorPartyAtExpense = True;
		
	EndIf;
	
	#EndRegion
	For Each CurrRow In RulesTable Do
		CurrRow.EmptyLoggerValue = Documents[CurrRow.DocumentName].EmptyRef();
	EndDo;
	
	Return RulesTable;
	
EndFunction

// Determines whether the specified record type is a batch record.
//
// Parameters:
// 	EntryType - EnumRef.LotRecordTypes - record type to check
// 	
// Returns:
//	Boolean - the transmitted record type is the primary batch.
//
Function ThisIsPrimaryPartyRecordType(EntryType) Export
	
	Return (CostCalculationAppliedAlgorithms.TypesOfPrimaryBatchRecords().Find(EntryType) <> Undefined);
	
EndFunction

// Determines whether a record of the specified type can be recalculated.
//
// Parameters:
// 	EntryType - EnumRef.LotRecordTypes - record type to check
//
// Returns:
//	Boolean - the transmitted record type is unreadable.
//
Function ThisIsNonReadableRecordType(EntryType) Export
	
	Return (CostCalculationAppliedAlgorithms.UnreadableRecordTypes().Find(EntryType) <> Undefined);
	
EndFunction

// Determines whether the transmitted record type is calculated (not used in primary movements).
// If these are the type of record (e.g., Production, Distribution), then it is generated
// at the stage of filling parties in the cost - for such records is set to sign "Raschetami".
// Otherwise, we assume that this is an already existing primary record, for which the batch accounting fields were simply filled
// in. Used only for the inventory Cost register at the stage of filling in lots in the movements of this register.
//
// Parameters:
// 	EntryType - EnumRef.LotRecordTypes - record type to check
//
// Returns:
//	Boolean - the transmitted record type is calculated.
//
Function ThisIsOnlyCalculatedRecordType(EntryType) Export
	
	Rules = CalculationOfCostCached.RulesForFillingInRecordTypeField();
	RulesRow = Rules.Find(EntryType, "EntryTypeReceipt, EntryTypeExpense");
	
	Return (RulesRow = Undefined); // the recording type is not used in primary movements
	
EndFunction

#EndRegion

#Region CostAccounting_

// Returns whether the cost price can be calculated.
//
//	Parameters:
//		Period - Date - the period for which the ability to calculate the cost price is checked.
//
//	Returns:
//		Boolean - a sign of the possibility of calculating the cost price.
//
Function CostCalculationIsPossible(Period = Undefined) Export
	
	RecordsAreKept = GetFunctionalOption("UseCostAccounting");
	
	If Not RecordsAreKept Or Period = Undefined Then
		Return RecordsAreKept;
	EndIf;
	
	// The calculation is possible from the period preceding the start of cost accounting (from the period in which the initial balances are entered)
	CheckDate = BegOfMonth(BegOfMonth(Constants.CostAccountingStartDate.Get()) - 1);
	
	Return CheckDate <= BegOfMonth(Period);
	
EndFunction

// Returns a flag indicating that it is necessary to generate movements based on cost registers.
//
//	Parameters:
//		Period			- Date		- the period for which the ability to calculate the cost price is checked.
//		ThisIsInputOfResiduals	- Boolean	- indicates that the Registrar is entering balances.
//
//	Returns:
//		Boolean - a sign of the need to form movements according to cost registers.
//
Function GenerateRegisteredRecordsOnCostRegisters(Period, ThisIsInputOfResiduals = False) Export
	
	RecordsAreKept = GetFunctionalOption("UseCostAccounting");
	
	If Not RecordsAreKept Then
		Return False;
	EndIf;
	
	// Document movements are formed from the start of cost accounting.
	CheckDate = BegOfMonth(Constants.CostAccountingStartDate.Get());
	
	If ThisIsInputOfResiduals Then
		// The documents for entering balances form movements starting from the period preceding the start of cost accounting.
		CheckDate = BegOfMonth(CheckDate - 1);
	EndIf;
	
	Return CheckDate <= BegOfMonth(?(ValueIsFilled(Period), Period, CurrentSessionDate()));
	
EndFunction

// Returns a flag indicating that there may be unused cost movements.
//
//	Returns:
//		Boolean - a sign of the possibility of unused cost movements.
//
Function UnusedRegisteredRecordsOnCostRegistersArePossible() Export
	
	KeepRecords = GetFunctionalOption("UseCostAccounting");
	AccountingStartDate = BegOfMonth(Constants.CostAccountingStartDate.Get());
	
	If KeepRecords And Not ValueIsFilled(AccountingStartDate) Then
		Return False; // cost accounting is carried out in all periods
	EndIf;
	
	Return True;
	
EndFunction

// Returns a list of registers that are not used when cost accounting is disabled.
//
//	Returns:
//		Map - a list of registers that are not used when cost accounting is disabled.
//
Function RegistersNotUsedWhenCostAccountingIsDisabled() Export
	
	ListOfRegisters = New Map;
	
	ListOfRegisters.Insert(Metadata.AccumulationRegisters.ItemisedExpensesLots, True);
	ListOfRegisters.Insert(Metadata.AccumulationRegisters.OtherIncome, True);
	ListOfRegisters.Insert(Metadata.AccumulationRegisters.OtherExpenses, True);
	ListOfRegisters.Insert(Metadata.AccumulationRegisters.OtherWorkInProgressExpenses, True);
	ListOfRegisters.Insert(Metadata.AccumulationRegisters.FutureExpenseCommitments, True);
	ListOfRegisters.Insert(Metadata.AccumulationRegisters.InventoryCost, True);
	ListOfRegisters.Insert(Metadata.AccumulationRegisters.WIPLaborCosts, True);
	ListOfRegisters.Insert(Metadata.AccumulationRegisters.FinancialResults, True);
	
	ListOfRegisters.Insert(Metadata.InformationRegisters.GoodsCost, True);
	
	CalculationOfCostLocalization.AddRegistersThatAreNotUsedWhenCostAccountingIsDisabled(ListOfRegisters);
	
	Return ListOfRegisters;
	
EndFunction

// Returns a list of registers that are not calculated when cost accounting is disabled.
//
//	Returns:
//		Map - a list of registers that are not calculated when cost accounting is disabled.
//
Function RegistersThatAreNotCalculatedWhenCostAccountingIsTurnedOff() Export
	
	ListOfRegisters = New Map;
	ListOfRegisters.Insert(Metadata.AccumulationRegisters.RevenueAndCOGS, True);
	ListOfRegisters.Insert(Metadata.AccumulationRegisters.RegisterRecordsProductsIncomeExpenses, True);
	ListOfRegisters.Insert(Metadata.AccumulationRegisters.RecordsProductsProducts, True);
	ListOfRegisters.Insert(Metadata.AccumulationRegisters.Purchases, True);
	ListOfRegisters.Insert(Metadata.AccumulationRegisters.MaterialsAndWorksInProduction, True);
	
	Return ListOfRegisters;
	
EndFunction

// Returns a list of documents that generate movements when cost accounting is disabled.
//
//	Returns:
//		Map - a list of documents that form movements when cost accounting is disabled.
//
Function RecordersWithRegisteredRecordsWhenCostAccountingIsTurnedOff() Export
	
	ListOfRegistrars = New Map;
	
	ListOfRegistrars.Insert(Metadata.Documents.OBEntry       , True);
	ListOfRegistrars.Insert(Metadata.Documents.OBEntryGoods, True);
	ListOfRegistrars.Insert(Metadata.Documents.OBEntryOtherExpenses, True);
	ListOfRegistrars.Insert(Metadata.Documents.InventoryCostCalculation, True);
	ListOfRegistrars.Insert(Metadata.Documents.WIPOpeningBalancesByProductionLots, True);
	ListOfRegistrars.Insert(Metadata.Documents.EntryOfCapitalAssetsBalance2_4, True);
	Return ListOfRegistrars;
	
EndFunction

// Returns the query text of the temporary table of matching distribution options and assignments of distribution rules 
//
//	Returns:
//		String - the text of the request for a temporary table of matching distribution options and assignments of distribution rules
//
Function TextTTMatchingAllocationOptionsToRuleAssignments() Export
	Return "
	|SELECT 
	|	Variants.Ref AS AllocationOption,
	|	CASE 
	|		WHEN Variants.Ref = VALUE(Enum.CostAllocationOptions.ToProductionCosts) 
	|			THEN VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots)
	|		WHEN Variants.Ref = VALUE(Enum.CostAllocationOptions.ToInventoryCost) 
	|			THEN VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationOnInventoryCosts)
	|		WHEN Variants.Ref = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses) 
	|			THEN VALUE(Enum.AssignmentOfCostAllocationRules.CostAllocationToDeferredExpenses)
	|		WHEN Variants.Ref = VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness) 
	|			THEN VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult)
	|		WHEN Variants.Ref = VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly) 
	|			THEN VALUE(Enum.AssignmentOfCostAllocationRules.WithoutExpenseAllocation)
	|		WHEN Variants.Ref = VALUE(Enum.CostAllocationOptions.ToProductionCostDirect) 
	|			THEN VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationToProductionCost)
	|		WHEN Variants.Ref = VALUE(Enum.CostAllocationOptions.ToCostCenters) 
	|			THEN VALUE(Enum.AssignmentOfCostAllocationRules.CostAllocationToCostCenter)
	|	END AS AssignRule
	|INTO TTMatchingAllocationOptionsToRuleAssignments
	|FROM Enum.CostAllocationOptions AS Variants
	|INDEX BY
	|	AllocationOption
	|"
EndFunction

#EndRegion

#Region BatchAccountingModes

// Determines whether batch accounting version 2.2 is used on the specified date.
//
// Parameters:
//	Date - Date - date for which it is necessary to determine the mode of batch accounting.
//
// Returns:
//	Boolean - indication of the use of batch accounting version 2.2 on the specified date
//	If the date is not specified, then the fact of using batch accounting version 2.2 is determined.
//
Function BatchAccountingVersion22(Date = Undefined) Export
	Return CalculationOfCostLocalization.BatchAccountingVersion22(Date);
EndFunction

// Determines whether batch accounting version 2.1 is used on the specified date.
//
// Parameters:
//	Date - Date - date for which it is necessary to determine the mode of batch accounting.
//
// Returns:
//	Boolean - indication of the use of batch accounting version 2.1 on the specified date
//	If the date is not specified, then the fact of using batch accounting version 2.1 is determined.
//
Function BatchAccountingVersion21(Date = Undefined) Export
	
	BatchAccountingWasIncluded = CalculationOfCostCached.BatchAccountingWasUsedBeforeSwitchingToVersion22(Date);
	
	Return ?(BatchAccountingWasIncluded = Undefined, False, BatchAccountingWasIncluded);
	
EndFunction

// Determines whether batch accounting is disabled on the specified date.
//
// Parameters:
//	Date - Date - date for which it is necessary to determine the mode of batch accounting.
//
// Returns:
//	Boolean - indicates that batch accounting is disabled on the specified date.
//
Function BatchAccountingNotUsed(Date = Undefined) Export
	
	BatchAccountingWasIncluded = CalculationOfCostCached.BatchAccountingWasUsedBeforeSwitchingToVersion22(Date);
	
	Return ?(BatchAccountingWasIncluded = Undefined, False, Not BatchAccountingWasIncluded);
	
EndFunction

// Determines whether batch accounting is enabled on the specified date.
//
// Parameters:
//	Date - Date - date for which it is necessary to determine the mode of batch accounting.
//
// Returns:
//	Boolean - indication of the use of batch accounting on the specified date.
//
Function BatchAccountingIsEnabled(Date = Undefined) Export
	
	BatchAccountingWasIncluded =
		CalculationOfCostCached.BatchAccountingVersion22(Date)
		Or CalculationOfCostCached.BatchAccountingVersion21(Date);
	
	Return BatchAccountingWasIncluded;
	
EndFunction

// Defines the" old " batch accounting mode, before switching to batch accounting version 2.2.
//
// Parameters:
//	Date - Date - date for which it is necessary to determine the mode of batch accounting.
//
// Returns:
//	Boolean, Undefined - indication of the use of batch accounting on the specified date
// 		If the Date parameter is not passed, or the Date is in the period of validity of the batch accounting version 2.2,
//		the value is returned Undefined - there is no point in such a check.
//
Function BatchAccountingWasUsedBeforeSwitchingToVersion22(Date) Export
	Return CalculationOfCostLocalization.BatchAccountingWasUsedBeforeSwitchingToVersion22(Date);
EndFunction

// Returns the date of switching to batch accounting version 2.2.
// the date may be empty , which means that batch accounting version 2.2 is enabled for all periods.
//
// Returns:
//	Date - the beginning of the month of transition to batch accounting version 2.2.
//
Function DateOfMigrationToBatchAccounting22() Export
	Return CalculationOfCostLocalization.DateOfMigrationToBatchAccounting22();
EndFunction

#EndRegion

#Region CompanyManagementAccounting

// Returns the start date of management accounting for organizations.
// The date can be empty , which means that management accounting for organizations is enabled for all periods.
//
// Returns:
//	Date - the beginning of the month of management accounting of organizations
//
Function StartDateOfManagementAccountingOfOrganizations() Export
	
	Return CalculationOfCostLocalization.StartDateOfManagementAccountingOfOrganizations();
	
EndFunction

// Determines whether management accounting for organizations is enabled on the specified date.
//
// Parameters:
//	Date - Date - the date for which you need to define the management accounting of organizations.
//
// Returns:
//	Boolean - indication of the use of management accounting of organizations on the specified date
//	If the date is not specified, then the fact of inclusion of batch accounting of organizations is determined.
//
Function CompanyManagementAccounting(Date = Undefined) Export
	Return CalculationOfCostLocalization.CompanyManagementAccounting(Date);
EndFunction

#EndRegion

#Region AccountingByAppointment

// Returns the start date of the inclusion of a separate account of the cost of the appointment.
//
// Returns:
//	Date - the beginning of the month of the inclusion of separate accounting by appointment.
//
Function CostAccountingByAssignmentValidFrom() Export
	
	Return BegOfMonth(Constants.CostAccountingByAssignmentValidFrom.Get());
	
EndFunction

// Determines whether cost accounting for assignments is enabled on the specified date.
//
// Parameters:
//	Date - Date - the date for which you need to define cost accounting by destination.
//
// Returns:
//	Boolean - indication of cost accounting by appointment on the specified date
//	If the date is not specified, then the fact of cost accounting by appointment is determined.
//
Function CostOfGoodsForPurposes(Date = Undefined) Export
	
	KeepRecordsOfInventoryCostByAssignments = GetFunctionalOption("KeepRecordsOfInventoryCostByAssignments")
		And (Date = Undefined
			Or Date >= CalculationOfCostCached.CostAccountingByAssignmentValidFrom());
	
	Return KeepRecordsOfInventoryCostByAssignments;
	
EndFunction

// Returns an indication that there is at least one distribution setting by business lines.
//
// Returns:
// 	Boolean -
Function ThereAreDistributionSettingsForLinesOfBusiness() Export
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS HasSetting
	|FROM
	|	InformationRegister.SetUpAllocationByLinesOfBusiness AS T
	|	LEFT JOIN Catalog.LinesOfBusiness AS LinesOfBusiness
	|		ON T.LineOfBusinessAllocationMethod = LinesOfBusiness.Ref
	|		AND LinesOfBusiness.IncomeAccounting
	|	LEFT JOIN Catalog.AllocationMethodsByLinesOfBusiness.LinesOfBusiness AS DistributionMethods
	|		ON T.LineOfBusinessAllocationMethod = DistributionMethods.Ref
	|		AND DistributionMethods.Ref.AllocatedAccordingToRule = VALUE(Enum.AllocationRulesByLinesOfBusiness.InProportionToFactors)
	|		AND DistributionMethods.LineOfBusiness.IncomeAccounting
	|WHERE
	|	T.Used
	|   AND (NOT LinesOfBusiness.Ref IS NULL
	|	  	OR NOT DistributionMethods.Ref IS NULL)
	|";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion

#Region ValuationMethods

// Returns an array of organizations with the "FIFO sliding" cost estimation method.
// 
// Parameters:
//  Period - Date - the period of determining the accounting policy of organizations
// 
// Returns:
//  Array of CatalogRef.Companies - array of organizations
//
Function OrganizationsWithFIFOAssessmentMethod(Period) Export
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	AccountingPoliciesTaxSettings.SupplementTemporaryTableManagerWithCurrentParametersForAccountingPolicies(
		Metadata.InformationRegisters.FinancialAccountingPolicy.Name,
		Query.TempTablesManager,
		BegOfMonth(Period),
		"TTAccountingPolicyOfFinancialAccounting");
		
	Query.Text =
	"SELECT ALLOWED
	|	T.Ref AS Ref
	|FROM
	|	Catalog.Companies AS T
	|	INNER JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPoliciesOfOrganizations_
	|		ON T.Ref = AccountingPoliciesOfOrganizations_.Organization
	|WHERE
	|	AccountingPoliciesOfOrganizations_.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.FIFORollingValuation)";
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

// Returns an array of organizations with the "monthly average" cost estimation method.
//
// Parameters:
//	Period - Date - the period of determining the accounting policy of organizations
//
// Returns:
//  Array of CatalogRef.Companies - array of organizations
//
Function OrganizationsWithAverageValuationMethod(Period) Export
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	AccountingPoliciesTaxSettings.SupplementTemporaryTableManagerWithCurrentParametersForAccountingPolicies(
		Metadata.InformationRegisters.FinancialAccountingPolicy.Name,
		Query.TempTablesManager,
		BegOfMonth(Period),
		"TTAccountingPolicyOfFinancialAccounting");
		
	Query.Text =
	"SELECT ALLOWED
	|	T.Ref AS Ref
	|FROM
	|	Catalog.Companies AS T
	|	INNER JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPoliciesOfOrganizations_
	|		ON T.Ref = AccountingPoliciesOfOrganizations_.Organization
	|WHERE
	|	AccountingPoliciesOfOrganizations_.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.AveragePerMonth)";
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

// Returns a flag for using the Mid-slip estimation method.
//
// Returns:
//  Boolean - Medium-slip is used
//
Function MediumSlipValuationIsUsed() Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	
	Query.Text =
	"SELECT TOP 1
	|	T.Ref AS Ref
	|FROM
	|	Catalog.Companies AS T
	|	INNER JOIN InformationRegister.FinancialAccountingPolicy AS AccountingPoliciesOfOrganizations_
	|		ON T.Ref = AccountingPoliciesOfOrganizations_.Organization
	|WHERE
	|	AccountingPoliciesOfOrganizations_.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Returns an indication of the distribution of deviations in previous periods.
//
// Returns:
//  Boolean - The distribution of deviations in past periods is used.
//
Function DistributionOfDeviationsInPastPeriodsIsUsed() Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	
	Query.Text =
	"SELECT TOP 1
	|	T.Ref AS Ref
	|FROM
	|	Catalog.Companies AS T
	|	INNER JOIN InformationRegister.FinancialAccountingPolicy AS AccountingPoliciesOfOrganizations_
	|		ON T.Ref = AccountingPoliciesOfOrganizations_.Organization
	|WHERE
	|	AccountingPoliciesOfOrganizations_.AllocateVariancesInPreviousPeriods";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Returns the registers for which Registered Records are generated at the same time as Registered Records at cost at medium-slip.
//
// Returns:
//	Array of MetadataObject - Register Metadata
Function RelatedRegistersWhenConductingMediumSlip() Export
	
	ArrayOfRegisters = New Array;
	ArrayOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	ArrayOfRegisters.Add(Metadata.AccumulationRegisters.RevenueAndCOGS);
	ArrayOfRegisters.Add(Metadata.AccumulationRegisters.OtherExpenses);
	ArrayOfRegisters.Add(Metadata.AccumulationRegisters.OtherIncome);
	ArrayOfRegisters.Add(Metadata.AccumulationRegisters.OtherAssetsLiabilities);
	ArrayOfRegisters.Add(Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords);
	ArrayOfRegisters.Add(Metadata.AccumulationRegisters.RegisterRecordsProductsIncomeExpenses);
	ArrayOfRegisters.Add(Metadata.AccumulationRegisters.RecordsProductsProducts);
	ArrayOfRegisters.Add(Metadata.AccumulationRegisters.GoodsCostVariances);
	
	Return ArrayOfRegisters;
	
EndFunction

#EndRegion

#Region ExpensesDetails

// Returns an array of organizations with the "FIFO sliding" cost estimation method and the "Detail material and item-by-item costs in the cost of goods" attribute.
// 
// Parameters:
//  Period - Date - the period of determining the accounting policy of organizations
// 
// Returns:
//  Array of CatalogRef.Companies - array of organizations
//
Function CompaniesWithCostDetailsInCostPrice(Period) Export
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	AccountingPoliciesTaxSettings.SupplementTemporaryTableManagerWithCurrentParametersForAccountingPolicies(
		Metadata.InformationRegisters.FinancialAccountingPolicy.Name,
		Query.TempTablesManager,
		BegOfMonth(Period),
		"TTAccountingPolicyOfFinancialAccounting");
		
	Query.Text =
	"SELECT ALLOWED
	|	T.Ref AS Ref
	|FROM
	|	Catalog.Companies AS T
	|	INNER JOIN TTAccountingPolicyOfFinancialAccounting AS AccountingPoliciesOfOrganizations_
	|		ON T.Ref = AccountingPoliciesOfOrganizations_.Organization
	|WHERE
	|	AccountingPoliciesOfOrganizations_.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.FIFORollingValuation)
	|	AND AccountingPoliciesOfOrganizations_.ItemizeMaterialAndItemizedExpensesInInventoryCost";
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

Function AllocateItemByItemExpensesRecursively() Export
	Return False; // temporarily not used, algorithm optimization is required
EndFunction

#EndRegion


#Region TechnologicalParametersOfCalculation

// Returns the values of the technological parameters of the month closing operation.
//
// Parameters:
//	Operation - CatalogRef.MonthEndClosingOperations - operation for which process parameters are obtained;
//				if omitted, the parameter values for the "batch and cost Calculation" operation are returned.
//	HiddenOnesHaveDefaultValues - Boolean - 
//		the default value will be returned for hidden parameters regardless of whether the value was changed
//
// Returns:
//	Structure- Values Of Technological Parameters
//
Function ValuesOfTechnologicalParameters(Operation = Undefined, HiddenOnesHaveDefaultValues = True) Export
	
	SetPrivilegedMode(True);
	
	If Operation = Undefined Then
		Operation = Catalogs.MonthEndClosingOperations.LotsAndCostCalculation;
	EndIf;
	
	ParameterValues = Constants.MonthEndClosingSettings.CreateValueManager().SetValuesOfOperationParameters(
		Operation,
		HiddenOnesHaveDefaultValues);
	
	Return ParameterValues;
	
EndFunction

#EndRegion

#Region SystemStateAnalysis

// Returns the importance of the specified system health check.
//
// Parameters:
//	Validation - CatalogRef.AccountingCheckRules - check.
//
// Returns:
//	EnumRef.AccountingIssueSeverity - the importance of verification.
//
Function ImportanceOfCheckingSystemState(Validation) Export
	
	SetPrivilegedMode(True);
	
	IssueSeverity = Common.ObjectAttributeValue(Validation, "IssueSeverity");
	
	Return IssueSeverity;
	
EndFunction

#EndRegion

#Region UniversalProceduresForDescribingMechanismData

// Returns a list of metadata objects that are used for batch calculation.
// The list does not include items that are both the source data of the batch and cost calculation mechanisms.
//
// Parameters:
//	IncomingData - Map - already initialized storage for the description of the incoming data
//	OnlyRequiringRecalculation - Boolean - if it is set, the list will be returned only for those data
//		whose change entails the need to recalculate batches and costs
//		When you change this data, an entry must be created in the data register of the Taskcountercountercountercountercountercountercountercountercountercounter.
//
// Returns:
//	See CalculationOfCost.IncomingMechanismData
//
Function IncomingMechanismData(IncomingData = Undefined, OnlyRequiringRecalculation = False) Export
	
	Return CalculationOfCost.IncomingMechanismData(IncomingData, OnlyRequiringRecalculation);
	
EndFunction

#EndRegion

#Region SavingRegisteredRecords

// There are calculated Registered Records of the specified type of documents in the specified register.
// 
// Parameters:
//  DocumentName - String - document name
//  RegisterName - String - Register name
// 
// Returns:
//  Boolean -  There Are Calculated RegisteredRecords Of The Document
Function ThereAreCalculatedRegisteredRecordsOfDocument(DocumentName, RegisterName) Export
	
	RegisterMetadata 		= Metadata.FindByFullName(RegisterName);
	MetadataOfDocument 	= Metadata.FindByFullName(DocumentName);
	ThereIsCalculationOfParties 		= (RegisterMetadata.Attributes.Find("LotCalculation") <> Undefined);
	ThereIsCostCalculation = (RegisterMetadata.Attributes.Find("CalculationOfCost") <> Undefined);
	
	If Not ThereIsCalculationOfParties And Not ThereIsCostCalculation Then
		Return False;
	EndIf;
	If MetadataOfDocument = Metadata.Documents.ProductionStage2_2 Then
		Return True;
	EndIf;
	DescriptionOfDocuments = CostCalculationAppliedAlgorithms.DocumentsWithDifferentPeriodsOrOrganizationsInRegisteredRecords(True, False, RegisterMetadata.Name);
	
	If DescriptionOfDocuments.Get(MetadataOfDocument) = False Then
		Return True;
	EndIf;
	
	TextTemplate1 =
	"SELECT TOP 1
	|	TRUE AS ThereAreRegisteredRecords
	|FROM
	|	RegisterTable AS T
	|WHERE
	|	&TextSelectionOfRegisteredRecorded
	|	AND TRUE IN (SELECT TOP 1
	|			TRUE
	|		FROM
	|			DocumentTable AS Filter
	|		WHERE
	|			T.Recorder = Filter.Ref
	|			AND T.Period = Filter.Date
	|		)
	|";

	Query = New Query;
	Query.Text = "";
	
	If ThereIsCalculationOfParties Then
		Query.Text = TextTemplate1;
		Query.Text = StrReplace(Query.Text, "&TextSelectionOfRegisteredRecorded", "T.LotCalculation");
	EndIf;

	If ThereIsCostCalculation Then
		Query.Text = ?(Not ThereIsCalculationOfParties, "", Query.Text + "
		|
		|UNION ALL
		|
		|") + TextTemplate1;
		Query.Text = StrReplace(Query.Text, "&TextSelectionOfRegisteredRecorded", "T.CalculationOfCost");
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "RegisterTable", RegisterName);
	Query.Text = StrReplace(Query.Text, "DocumentTable", DocumentName);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Generate a description of the register.
// 
// Parameters:
//  FullRegisterName - String - Full name of the register
// 
// Returns:
//  See CostCalculationAppliedAlgorithms.GenerateCaseDescription
Function GenerateCaseDescription(FullRegisterName) Export
	Return CostCalculationAppliedAlgorithms.GenerateCaseDescription(Metadata.FindByFullName(FullRegisterName));
EndFunction

#EndRegion

#Region HandlingRequests

// Returns a list of query columns.
// 
// Parameters:
//  QueryText - String - Query text
// 
// Returns:
//  Array of String - Request Columns
Function RequestColumns(QueryText) Export
	
	Columns = New Array;
	
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(QueryText);
	
	QueryDetails = QuerySchema.QueryBatch[QuerySchema.QueryBatch.Count() - 1];
	
	For Each CurrentColumn In QueryDetails.Columns Do
		Columns.Add(CurrentColumn.Alias);
	EndDo;
	
	Return Columns;
	
EndFunction

// Returns a list of temporary tables that are created in the request.
// 
// Parameters:
//  QueryText - String - Query text
// 
// Returns:
//  ValueList of String - Temporary query tables
Function QueryTempTables(QueryText) Export
	
	Tables = New ValueList;
	
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(QueryText);
	
	For Each CurrentQuery In QuerySchema.QueryBatch Do
		
		If TypeOf(CurrentQuery) = Type("QuerySchemaSelectQuery")
		 And ValueIsFilled(CurrentQuery.PlacementTable) Then
			Tables.Add(StrLen(CurrentQuery.PlacementTable), CurrentQuery.PlacementTable);
		EndIf;
	EndDo;

	Tables.SortByValue(SortDirection.Desc); // the longest table names will be the first - so that there are no problems with replacement in the Query Text
	
	Return Tables;
	
EndFunction

// Returns a data selection query converted to a temporary table generation query.
// 
// Parameters:
//  QueryText - String - Query text
//  TTName - String - name of the temporary table
// 
// Returns:
//  Structure:
//	 * Columns - Array of String - Request Columns
//	 * QueryText - String - new request text
Function RequestToGenerateTTFromSelectionRequest(QueryText, TTName) Export
	
	Result = New Structure;
	
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(QueryText);
	
	QueryDetails = QuerySchema.QueryBatch[QuerySchema.QueryBatch.Count() - 1];
	
	Result.Insert("Columns", CalculationOfCostCached.RequestColumns(QueryText));

	QueryDetails.PlacementTable = TTName;
	
	Result.Insert("QueryText", QuerySchema.GetQueryText());
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion
