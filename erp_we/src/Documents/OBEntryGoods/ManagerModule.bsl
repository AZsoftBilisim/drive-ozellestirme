#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region GenerateFrom

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BTVisibilityCondition = New Structure;
	BTVisibilityCondition.Insert("Attribute", Metadata.Documents.OBEntryGoods.Attributes.BusinessOperation.Name);
	BTVisibilityCondition.Insert("ComparisonType", ComparisonType.NotInList);
	OperationArray = New ValueList();
	OperationArray.Add(Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse);
	OperationArray.Add(Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5);
	OperationArray.Add(Enums.BusinessTransactions.EnterRemainingGoodsTransferredToVMI);
	OperationArray.Add(Enums.BusinessTransactions.OBEntryShippedGoods);
	BTVisibilityCondition.Insert("Value", OperationArray);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(GenerationCommands, BTVisibilityCondition);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	OBEntryLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	OBEntryLocalization.EnteringProductBalancesAddReportCommands(ReportsCommands, Parameters);
EndProcedure

#EndRegion

#Region Print

// Returns the rules for printing the printed form of the Task for selecting (placing) products.
//
// Returns:
//	Structure - composition of properties See DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand.
//
Function RulesForPrintingTasksForSelectionPlacement() Export
	
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.ReceiptOperation	= True;
	JobPrintingRules.FieldNameRoom		= "Premise";
	
	Return JobPrintingRules;
	
EndFunction

#EndRegion

//Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Warehouse,Premise,Department,BusinessOperation,Date";
	Return AttributesNames;
EndFunction

//Returns parameters for specifying series for products specified in the document
//
//	Parameters:
//	 Object - Structure - structure of object details values required for filling in parameters for specifying series
//	Returns:
//	 Structure - See ProductsServer.SeriesSpecificationParameters
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.OBEntryGoods";
	
	If Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned Then
		WarehouseSeriesParameters = WarehousesServer.UsingSeriesInDivision(Object.Department);
		SeriesSpecificationParameters.WarehouseFieldName = "Department";
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5 Then
		
		WarehouseSeriesParameters = New Structure;
		WarehouseSeriesParameters.Insert(
			"UseCostAccountingByBatches",
			GetFunctionalOption("UseCostAccountingByBatchesWarehouse", New Structure()));
		WarehouseSeriesParameters.Insert(
			"UseItemsBatch",
			GetFunctionalOption("UseItemsBatchWarehouse", New Structure()));
		
		SeriesSpecificationParameters.WarehouseFieldName = "Contract";
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingGoodsTransferredToVMI
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryShippedGoods Then
		
		WarehouseSeriesParameters = New Structure;
		WarehouseSeriesParameters.Insert(
			"UseCostAccountingByBatches",
			GetFunctionalOption("UseCostAccountingByBatchesWarehouse", New Structure()));
		WarehouseSeriesParameters.Insert(
			"UseItemsBatch",
			GetFunctionalOption("UseItemsBatchWarehouse", New Structure()));
		
		SeriesSpecificationParameters.SelectionPlanning = True;
		SeriesSpecificationParameters.FactOfSelection         = True;
		
		SeriesSpecificationParameters.WarehouseFieldName = "Contract";
		
		SeriesSpecificationParameters.RegisterSeries = ProductsClientServer.ItIsNecessaryToRegisterSeries(
														SeriesSpecificationParameters);
														
	Else
		WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	EndIf;
	If Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
		Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
		Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider Then
		
		WarehouseSeriesParameters.UseItemsBatch =
			WarehouseSeriesParameters.UseItemsBatch
				And Not WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Object.Warehouse, Object.Date)
			Or WarehouseSeriesParameters.UseCostAccountingByBatches;
			
	EndIf;
	RequiredOperation =
		Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned
		Or Object.BusinessOperation = Enums.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
		Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
		Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
		Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingReceivedVMI
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryWarehouseBinAddressOfOwnedInventory
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryWareroomAddressOfOwnedInventory
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingGoodsTransferredToVMI
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryShippedGoods;
	
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch And RequiredOperation;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches And RequiredOperation;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.OBEntry);
	
	OperationsForWhichSeriesIsNotSpecifiedVHFSeries = New Array;
	OperationsForWhichSeriesIsNotSpecifiedVHFSeries.Add(Enums.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5);
	If OperationsForWhichSeriesIsNotSpecifiedVHFSeries.Find(Object.BusinessOperation) = Undefined Then
		SeriesSpecificationParameters.SeriesWhenPlanningShipmentVHFSeriesAreIndicated = True;
	EndIf;
	
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	
	SeriesSpecificationParameters.ThisIsAnInvoice     = True;
	SeriesSpecificationParameters.Date             = Object.Date;
	SeriesSpecificationParameters.FieldNameRoom = "Premise";
	
	If Object.BusinessOperation = Enums.BusinessTransactions.OBEntryWarehouseBinAddressOfOwnedInventory
		Or ((Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse
				Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
				Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingReceivedVMI
				Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors)
			And WarehousesServer.UseBinLocationWarehousing(Object.Warehouse, Object.Premise, Object.Date)) Then 
			
		SeriesSpecificationParameters.UseBinLocationWarehousing = True;
		SeriesSpecificationParameters.LinkFields.Add("Package");
		SeriesSpecificationParameters.FieldNameQuantity = "NumberOfPackages";
		
	EndIf;
	
	SeriesSpecificationParameters.OnlySeriesTakingIntoAccountLeftovers =
		Object.BusinessOperation = Enums.BusinessTransactions.OBEntryWarehouseBinAddressOfOwnedInventory
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryWareroomAddressOfOwnedInventory;
	
	SeriesSpecificationParameters.QueryOptions.Insert("BusinessOperation", Object.BusinessOperation);
	
	Return SeriesSpecificationParameters;
	
EndFunction

// The procedure fills in the statuses for specifying series in the PM goods lines
//
// Parameters:
//  SeriesSpecificationParameters - Structure - structure of parameters for specifying series returned by the corresponding procedure of the document Manager module (processing)
//
// Returns:
//	String - The text of the request to fill in statuses.
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	If SeriesSpecificationParameters.WarehouseFieldName = "Contract" Then
		Return QueryTextOfFillingInStatusesOfIndicatingSeriesIsSubcontractingAndForCommission();
	ElsIf SeriesSpecificationParameters.WarehouseFieldName = "Department" Then
		Return TextOfRequestToFillInStatusesForSpecifyingSerialNumbers();
	Else
		Return TextOfRequestToFillInStatusesForSpecifyingSerialNumbers_(SeriesSpecificationParameters);
	EndIf;
	
EndFunction
#Region ConductingRegulatedAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	Return OBEntryLocalization.EnteringProductBalancesToBeReflectedInLocalAccounting();
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting
//
// Returns:
//  String - Containing the text of the request for temporary tables to be reflected in the regl. accounting.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	Return OBEntryLocalization.EnteringProductBalancesRequestTextTTReflectedInLocalAccounting();
EndFunction

#EndRegion

#Region FillingInAccordingToOperationalAccountingData

// Returns a table of values for filling in the balance entry document with data obtained from operational accounting data.
// 
// Parameters:
// 	Date - Date - The date on which balances are generated.
// 	BusinessOperation - EnumRef.BusinessTransactions - Business transaction for which balances are selected
// 	Companies - Array - Array containing elements of the reference Link type.Organizations for which balances are selected.
// 	AdditionalSelection - Structure - Structure containing the key and value of the additional selection.
// 	ParametersForFillingBalances - Structure - A structure that contains additional parameters that are necessary for filling in balances.
// Returns:
// 	ValueTable, Undefined - If there is data for this business operation, a table of values with fill values is returned for it.
//
Function BalancesByTypeOfOperation(Date, BusinessOperation, Companies, AdditionalSelection = Undefined, ParametersForFillingBalances = Undefined) Export

	
	Return Undefined;
	
EndFunction

// Returns an array that contains the names of fields that need to be changed to generate a new document for entering balances.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - A business transaction for which key fields are defined.
// Returns:
// 	Array - An array containing field names.
//
Function KeyFieldsOfLocalAccountingByTypeOfOperation(BusinessOperation) Export
	
	KeyFieldsArray = New Array;
	
	Return KeyFieldsArray;
	
EndFunction

#EndRegion
// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	// Needs for goods in stock.
	// "Transitionaddress Storage of Goods" is the name of the tabular part of the form "FormaTovary". That is, the mechanism is configured in such a way
	// that it expects this name of the tabular part in each form where assignments are embedded.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.DataPaths.Products   = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse          = "Object.Warehouse";
	
	DescriptionOfColumns.FormItemName = "OwnProductsPurpose";
	DescriptionOfColumns.FormTableName = "OwnProducts";
	
	Return FormTemplate;
	
EndFunction

#Region InterfaceImplementation

// Adds a command to create a document based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
// Returns:
//	FormCommand - the command being added.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	Return GenerateFrom.AddGenerationCommand(GenerationCommands, Metadata.Documents.OBEntryGoods);
	
EndFunction

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND( ValueAllowed(Warehouse)
	|	OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|	) ";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#Region InitializingDocumentAndDocumentParameters

// Initialization parameters for registering invoices received
//  Parameters:
//    ObjectData - DocumentObject.OBEntry - Object of the balance entry document
//
//  Returns:
//    See VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived
Function InitializeParametersForRegisteringInvoicesReceived(ObjectData) Export
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
	RegistrationParameters.Ref                        = ObjectData.Ref;
	RegistrationParameters.Date                          = ObjectData.Date;
	RegistrationParameters.Organization                   = ObjectData.Organization;
	RegistrationParameters.Counterparty                    = ObjectData.Counterparty;
	RegistrationParameters.VATTaxation            = ObjectData.VATTaxation;
	RegistrationParameters.PurchaseOfGoodsWorksServices = True;
	
	Return RegistrationParameters;
	
EndFunction

// Initializing parameters for registering invoices received
//  Parameters:
//    ObjectData - DocumentObject.OBEntry - Object of the balance entry document
//
//  Returns:
//    See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
//
Function InitializeParametersForVATActivities(ObjectData) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Organization             = ObjectData.Organization;
	FillParameters.Date                    = ObjectData.Date;
	FillParameters.Warehouse                   = ObjectData.Warehouse;
	FillParameters.Contract                 = ObjectData.Contract;
	FillParameters.LineOfBusiness = ObjectData.LineOfBusiness;
	FillParameters.PurchaseOfGoods     = True;
	
	Return FillParameters;
	
EndFunction

// Returns the structure of parameters for filling in VAT taxation for sales or returns of goods from the buyer.
// Parameters:
// 	ObjectData - DocumentObject - BalanceInputDocument
// Returns:
// 	See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function InitializeVATTaxationParameters(ObjectData) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	FillParameters.Organization             = ObjectData.Organization;
	FillParameters.Date                    = ObjectData.Date;
	FillParameters.Contract                 = ObjectData.Contract;
	FillParameters.LineOfBusiness = ObjectData.LineOfBusiness;
	FillParameters.TransferToCommissionAgent      = True;
	
	Return FillParameters;
	
EndFunction

// Returns the structure of parameters for filling in the VAT tax for accepting goods for commission.
// Parameters:
// 	ObjectData - DocumentObject - BalanceInputDocument
// Returns:
// 	See VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases
//
Function InitializeVATTaxParametersConsignmentProcurement(ObjectData) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
	FillParameters.Counterparty      = ObjectData.Counterparty;
	FillParameters.Contract         = ObjectData.Contract;
	FillParameters.Period          = ObjectData.Date;
	FillParameters.ConsignmentProcurement = True;
	
	Return FillParameters;
	
EndFunction

// Defines for a business transaction and the operation of product distribution.
// 
// Parameters:
// 	ObjectData - DocumentObject - BalanceInputDocument
// Returns:
// 	Structure - Description: A structure with a description of the type of goods movement operation
//
Function InitializeEconomicOperationOfCommodityMovement(ObjectData) Export
	
	EconomicOperationOfCommodityMovement = New Structure();
	EconomicOperationOfCommodityMovement.Insert("ThisIsRemainingReceivedPackage",                       ObjectData.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors);
	EconomicOperationOfCommodityMovement.Insert("TheseAreRemainingTransferredPackages",                     ObjectData.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingSentToCustomers);
	EconomicOperationOfCommodityMovement.Insert("ThisIsOwnStockBalance",                 ObjectData.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse);
	EconomicOperationOfCommodityMovement.Insert("ThisIsConsignedStockBalanceIssued",        ObjectData.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse);
	EconomicOperationOfCommodityMovement.Insert("ThisIsConsignedStockBalanceIssued2_5",     ObjectData.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5);
	EconomicOperationOfCommodityMovement.Insert("ThisIsConsignedStockBalanceReceived",          ObjectData.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse);
	EconomicOperationOfCommodityMovement.Insert("TheseAreBalancesOfGoodsAcceptedForStorage",          ObjectData.BusinessOperation = Enums.BusinessTransactions.EnterRemainingReceivedVMI);
	EconomicOperationOfCommodityMovement.Insert("TheseAreBalancesOfGoodsTransferredForStorage",        ObjectData.BusinessOperation = Enums.BusinessTransactions.EnterRemainingGoodsTransferredToVMI);
	EconomicOperationOfCommodityMovement.Insert("TheseAreRemnantsOfShippedItems",                 ObjectData.BusinessOperation = Enums.BusinessTransactions.OBEntryShippedGoods);
	EconomicOperationOfCommodityMovement.Insert("TheseAreBalancesOfDeviations",                         ObjectData.BusinessOperation = Enums.BusinessTransactions.OBEntryGoodsCostVariances);
	EconomicOperationOfCommodityMovement.Insert("ThisIsStockBalanceTransferredToToller2_5", ObjectData.BusinessOperation = Enums.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5);
	EconomicOperationOfCommodityMovement.Insert("ThisIsStockBalanceTransferredToProduction",     ObjectData.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned);
	EconomicOperationOfCommodityMovement.Insert("ThisIsTransitionToBinLocationWarehousing",                 ObjectData.BusinessOperation = Enums.BusinessTransactions.OBEntryWarehouseBinAddressOfOwnedInventory);
	EconomicOperationOfCommodityMovement.Insert("ThisIsTransitionToWarerooms",               ObjectData.BusinessOperation = Enums.BusinessTransactions.OBEntryWareroomAddressOfOwnedInventory);
	EconomicOperationOfCommodityMovement.Insert("TheseAreBalancesOfMaterialsTakenIntoProcessing2_5",  ObjectData.BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting);
	EconomicOperationOfCommodityMovement.Insert("TheseAreBalancesOfSemiFinishedProductsOfGiver2_5",          ObjectData.BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider);
	EconomicOperationOfCommodityMovement.Insert("TheseAreBalancesOfOutputOfGiver2_5",               ObjectData.BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider);
	Return EconomicOperationOfCommodityMovement;
	
EndFunction

// Fills in the type of activity for separate VAT accounting according to the passed parameters.
// Parameters:
// 	ObjectData - DocumentObject - Document for entering initial balances.
// 	FormToFillIn - ClientApplicationForm - fills in the form details with the available values.
// 	ReFill_ - Boolean - Determines whether to re-fill an existing value or not.
//
Procedure FillInTypeOfActivityVAT(ObjectData, FormToFillIn, ReFill_ = False) Export
	
	TypesOfCommodityMovementOperations          = InitializeEconomicOperationOfCommodityMovement(ObjectData);
	ParametersForFillingInActivityType = InitializeParametersForVATActivities(ObjectData);
	FillInFormElement              = Undefined;
	
	If TypesOfCommodityMovementOperations.ThisIsOwnStockBalance Then
		FillInFormElement = FormToFillIn.Items.OwnGoodsTypeOfActivityVAT;
	ElsIf TypesOfCommodityMovementOperations.ThisIsRemainingReceivedPackage Then
		FillInFormElement = FormToFillIn.Items.AcceptedPackagingTypeOfActivityVAT;
	ElsIf TypesOfCommodityMovementOperations.ThisIsStockBalanceTransferredToProduction Then
		FillInFormElement = FormToFillIn.Items.GoodsTransferredToProductionTypeOfActivityVAT;
	ElsIf TypesOfCommodityMovementOperations.ThisIsStockBalanceTransferredToToller2_5 Then
		FillInFormElement = FormToFillIn.Items.GoodsTransferredToProcessorsTypeOfActivityVAT;
	ElsIf TypesOfCommodityMovementOperations.TheseAreBalancesOfGoodsTransferredForStorage Then
		FillInFormElement = FormToFillIn.Items.DepositedVATTaxation;
	ElsIf TypesOfCommodityMovementOperations.TheseAreBalancesOfDeviations Then
		FillInFormElement = FormToFillIn.Items.DeviationsFromVATTaxationTypeOfBusiness;
	ElsIf TypesOfCommodityMovementOperations.TheseAreBalancesOfSemiFinishedProductsOfGiver2_5 Then
		FillInFormElement = FormToFillIn.Items.SemiFinishedProductsGiverTypeOfActivityVAT;
	ElsIf TypesOfCommodityMovementOperations.TheseAreBalancesOfOutputOfGiver2_5 Then
		FillInFormElement = FormToFillIn.Items.GiverSProductsTypeOfActivityVAT;
	EndIf;
	
	If FillInFormElement = Undefined Then
		Return;
	EndIf;
	
	If ReFill_ Then
		VATAccountingERP.FillInTypeOfActivityVAT(
			ObjectData.VATActivityType,
			ParametersForFillingInActivityType,
			FormToFillIn.VATAccountingCachedParameterValues);
	EndIf;
	
	VATAccountingERP.FillInActivitySelectionList(
		FillInFormElement,
		ObjectData.VATActivityType,
		ParametersForFillingInActivityType,
		FormToFillIn.VATAccountingCachedParameterValues);
	
EndProcedure

// Returns the Attribute header of the partner form, depending on the business transaction.
//
// Parameters:
//  BusinessOperation  - EnumRef.BusinessTransactions - an operation that affects the title text.
//
// Returns:
//   String   - the generated header.
//
Function HeaderOfPartnerDetailsDependingOnBusinessOperation(BusinessOperation) Export
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse Then
		TitlePartner = NStr("vi = 'Người đặt ký gửi';
							|ru = 'Комитент';
							|en = 'Consignor'; fa = 'امانت‌گذار';
							|it = 'Committente';
							|pl = 'Komitent';
							|tr = 'Gönderici'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse Then
		TitlePartner = NStr("vi = 'Người nhận ký gửi';
							|ru = 'Комиссионер';
							|en = 'Consignee'; fa = 'امانت‌دار';
							|it = 'Commissionario';
							|pl = 'Komisant';
							|tr = 'Konsinye'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors Then
		TitlePartner = NStr("vi = 'Nhà cung cấp';
							|ru = 'Поставщик';
							|en = 'Vendor'; fa = 'تأمین‌کننده';
							|it = 'Vendor';
							|pl = 'Vendor';
							|tr = 'Tedarikçi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingSentToCustomers Then
		TitlePartner = NStr("vi = 'Khách hàng';
							|ru = 'Клиент';
							|en = 'Customer'; fa = 'مشتری';
							|it = 'Клиент';
							|pl = 'Customer';
							|tr = 'Müşteri'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5 Then
		TitlePartner = NStr("vi = 'Người nhận ký gửi';
							|ru = 'Комиссионер';
							|en = 'Consignee'; fa = 'امانت‌دار';
							|it = 'Commissionario';
							|pl = 'Komisant';
							|tr = 'Konsinye'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.EnterRemainingGoodsTransferredToVMI Then
		TitlePartner = NStr("vi = 'Bên bảo quản';
							|ru = 'Хранитель';
							|en = 'Custodian'; fa = 'امین';
							|it = 'Custodian';
							|pl = 'Custodian';
							|tr = 'Emanetçi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.EnterRemainingReceivedVMI Then
		TitlePartner = NStr("vi = 'Nhà cung cấp';
							|ru = 'Поставщик';
							|en = 'Vendor'; fa = 'تأمین‌کننده';
							|it = 'Vendor';
							|pl = 'Vendor';
							|tr = 'Tedarikçi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5 Then
		TitlePartner = NStr("vi = 'Bên nhận gia công';
							|ru = 'Переработчик';
							|en = 'Subcontractor'; fa = 'پیمانکار فرعی';
							|it = 'Переработчик';
							|pl = 'Subcontractor';
							|tr = 'Fason üretici'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting Then
		TitlePartner = NStr("vi = 'Bên đặt gia công';
							|ru = 'Давалец';
							|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
							|it = 'Давалец';
							|pl = 'Material provider';
							|tr = 'Malzeme tedarikçisi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider Then
		TitlePartner = NStr("vi = 'Bên đặt gia công';
							|ru = 'Давалец';
							|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
							|it = 'Давалец';
							|pl = 'Material provider';
							|tr = 'Malzeme tedarikçisi'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider Then
		TitlePartner = NStr("vi = 'Bên đặt gia công';
							|ru = 'Давалец';
							|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
							|it = 'Давалец';
							|pl = 'Material provider';
							|tr = 'Malzeme tedarikçisi'");
	Else
		If GetFunctionalOption("UsePartnersAsCounterparties") Then
			TitlePartner = NStr("vi = 'Đối tác';
								|ru = 'Контрагент';
								|en = 'Counterparty'; fa = 'طرف حساب';
								|it = 'Controparte';
								|pl = 'Kontrahent';
								|tr = 'Cari hesap'");
		Else
			TitlePartner = NStr("vi = 'Bạn hàng';
								|ru = 'Партнер';
								|en = 'Partner'; fa = 'شریک تجاری';
								|it = 'Partner';
								|pl = 'Partner';
								|tr = 'İş ortağı'");
		EndIf;
	EndIf;
	
	Return TitlePartner;
	
EndFunction

#EndRegion

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	SelectedOperation = Undefined;
	
	If Parameters.Property("Key") And ValueIsFilled(Parameters.Key) Then
		SelectedOperation = Parameters.Key.BusinessOperation;
	ElsIf Parameters.Property("FillingValues") Then
		Parameters.FillingValues.Property("BusinessOperation", SelectedOperation);
	ElsIf Parameters.Property("CopyingValue") Then
		SelectedOperation = GeneralPurposeTMServerCall.ObjectAttributeValue(Parameters.CopyingValue,"BusinessOperation");
	ElsIf Parameters.Property("FilterByTransactionTypes") And Parameters.FilterByTransactionTypes.Count() = 1 Then
		
		SelectedOperation = Parameters.FilterByTransactionTypes[0].Value;
		FillingValues = New Structure;
		FillingValues.Insert("BusinessOperation", SelectedOperation);
		
		Parameters.Insert("FillingValues", FillingValues);
		
		If Parameters.Property("Organization") Then
			FillingValues.Insert("Organization", Parameters.Organization);
		EndIf;
		
		If Parameters.Property("RecordInOperationalAccounting") Then
			FillingValues.Insert("RecordInOperationalAccounting", Parameters.RecordInOperationalAccounting);
		EndIf;
		
		If Parameters.Property("PostInCostAccounting") Then
			FillingValues.Insert("PostInCostAccounting", Parameters.PostInCostAccounting);
		EndIf;
		
		If Parameters.Property("PostInFinancialAndTaxAccounting") Then
			FillingValues.Insert("PostInFinancialAndTaxAccounting", Parameters.PostInFinancialAndTaxAccounting);
		EndIf;
		
		If Parameters.Property("RecordInMA") Then
			FillingValues.Insert("RecordInMA", Parameters.RecordInMA);
		EndIf;
		
	EndIf;

	If ValueIsFilled(SelectedOperation) Then
		
		StandardProcessing = False;
		MatchingOperationTypesToForms = New Map;
		MatchingOperationTypesToForms.Insert(PredefinedValue("Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse"), "FormGoods");
		MatchingOperationTypesToForms.Insert(PredefinedValue("Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse"), "FormGoods");
		MatchingOperationTypesToForms.Insert(PredefinedValue("Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5"), "FormGoods");
		MatchingOperationTypesToForms.Insert(PredefinedValue("Enum.BusinessTransactions.EnterRemainingGoodsTransferredToVMI"), "FormGoods");
		MatchingOperationTypesToForms.Insert(PredefinedValue("Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse"), "FormGoods");
		MatchingOperationTypesToForms.Insert(PredefinedValue("Enum.BusinessTransactions.EnterRemainingReceivedVMI"), "FormGoods");
		MatchingOperationTypesToForms.Insert(PredefinedValue("Enum.BusinessTransactions.OBEntryShippedGoods"), "FormGoods");
		MatchingOperationTypesToForms.Insert(PredefinedValue("Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingSentToCustomers"), "FormGoods");
		MatchingOperationTypesToForms.Insert(PredefinedValue("Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors"), "FormGoods");
		MatchingOperationTypesToForms.Insert(PredefinedValue("Enum.BusinessTransactions.OBEntryWarehouseBinAddressOfOwnedInventory"), "FormGoods");
		MatchingOperationTypesToForms.Insert(PredefinedValue("Enum.BusinessTransactions.OBEntryWareroomAddressOfOwnedInventory"), "FormGoods");
		MatchingOperationTypesToForms.Insert(PredefinedValue("Enum.BusinessTransactions.OBEntryGoodsCostVariances"), "FormGoods");
		MatchingOperationTypesToForms.Insert(PredefinedValue("Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5"), "FormGoods");
		MatchingOperationTypesToForms.Insert(PredefinedValue("Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned"), "FormGoods");
		MatchingOperationTypesToForms.Insert(PredefinedValue("Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting"), "FormGoods");
		MatchingOperationTypesToForms.Insert(PredefinedValue("Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider"),         "FormGoods");
		MatchingOperationTypesToForms.Insert(PredefinedValue("Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider"),              "FormGoods");
		SelectedForm = MatchingOperationTypesToForms[SelectedOperation];
		
	EndIf;
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Ref");
	Fields.Add("Number");
	Fields.Add("Date");
	Fields.Add("BusinessOperation");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	
	If Data.Ref <> Undefined Then
		Presentation = 
			OBEntryServerCall.DocumentTitleEnteringBalancesForBusinessTransaction(Data.Ref, Data.Number, Data.Date, Data.BusinessOperation);
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Posting

Function ItemsAndDimensionsSelectionParameters() Export
	
	ItemsAndDimensionsSelectionParameters = New Array;
	Return ItemsAndDimensionsSelectionParameters;
	
EndFunction

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	DataSources = New Map;
	Return DataSources; 
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.OBEntryGoods";
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID(Metadata.Documents.OBEntryGoods));
	ParameterValues.Insert("UseTraceableImportedGoodsAccounting",
		AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Date(1,1,1)));
	ParameterValues.Insert("DateOfTraceableImportedGoodsAccountingStart",
		AccountingForTraceableGoodsLocalization.DateOfTraceableImportedGoodsAccountingStart());
	
	TextOfRequestToRedefineWarehouse = "
		|	CASE
		|		WHEN GoodsTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse)
		|				OR GoodsTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingSentToCustomers)
		|			THEN GoodsTable.Ref.Partner
		|		ELSE GoodsTable.Ref.Warehouse
		|	END";
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("Warehouse", TextOfRequestToRedefineWarehouse);
	
	If RegisterName = "GoodsInStorageBins" Then
		
		QueryText = QueryTextTableGoodsInStorageBins(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "GoodsTable";
		
	ElsIf RegisterName = "CompanyGoods" Then
		
		QueryText = QueryTextTableCompanyGoods(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "GoodsTable";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		RequestHasSource = True;
		
	ElsIf RegisterName = "ShipmentAndReturnReferences" Then
		
		QueryText = QueryTextTableShipmentReferences(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "GoodsTable";
		RequestHasSource = True;
		
	Else
		
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName%belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%",        RegisterName);
		
		Raise ExceptionText;
		
	EndIf;
	
	If SynonymForDocumentTable <> "GoodsTable" Then
		For Each CalculationParameter In RedefiningParameterCalculation Do
			RedefiningParameterCalculation[CalculationParameter.Key] = StrReplace(
				CalculationParameter.Value, "GoodsTable", SynonymForDocumentTable);
		EndDo;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RequestHasSource,
			RedefiningParameterCalculation);
		
	Else
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RedefiningParameterCalculation);
	
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.QueryText = QueryText;
	Result.ParameterValues = ParameterValues;
	
	Return Result;
	
EndFunction

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("HandoverForSafekeeping");
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("Sales");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingOfWorks");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses"); // for the formation of Registered Records for deviations in the cost of goods
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentCorrection");
	
	OBEntryLocalization.EnteringProductBalancesAndAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

Procedure FillInInitializationParameters(Query, DocumentRef) Export
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text ="SELECT
		|	DocumentData.Date AS Period,
		|	DocumentData.Number AS Number,
		|	DocumentData.Ref AS Ref,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	DocumentData.Department.OptionOfAssignedAccountingOfGoods AS OptionOfAssignedAccountingOfGoods,
		|	DocumentData.Warehouse AS Warehouse,
		|	DocumentData.Currency AS Currency,
		|	DocumentData.Premise AS Premise,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|	DocumentData.VATTaxation AS VATTaxation,
		|	DocumentData.VATActivityType AS VATActivityType,
		|	CASE WHEN DocumentData.Lot = VALUE(Document.SourceDocument.EmptyRef)
		|		THEN DocumentData.Ref
		|		ELSE DocumentData.Lot
		|	END AS Lot,
		|	ISNULL(DocumentData.Lot.SourceDocumentType, VALUE(Enum.SourceDocumentTypes.EmptyRef)) = VALUE(Enum.SourceDocumentTypes.InternalInvoice) AS InternalInvoiceInBatch,
		|	DocumentData.Partner AS Partner,
		|	DocumentData.Counterparty AS Counterparty,
		|	DocumentData.Contract AS Contract,
		|	DocumentData.TermsOfConsignmentSales AS TermsOfConsignmentSales,
		|	DocumentData.TermsOfConsignmentPurchase AS TermsOfConsignmentPurchase,
		|	DocumentData.CustomerTermsOfSales AS CustomerTermsOfSales,
		|	DocumentData.Partner AS Vendor,
		|	DocumentData.TermsOfConsignmentPurchase AS Terms,
		|	FALSE AS EnabledGoodsAssignmentInSalesOpportunity,
		|	DocumentData.OrderDocument AS OrderDocument,
		|	DocumentData.ReceivingArea AS ReceivingArea,
		|	DocumentData.Manager AS Manager,
		|	DocumentData.Author AS Author,
		|	DocumentData.PriceIncludesVAT AS PriceIncludesVAT,
		|	DocumentData.LineOfBusiness AS LineOfBusiness,
		|	DocumentData.RecordInOperationalAccounting AS RecordInOperationalAccounting,
		|	DocumentData.PostInCostAccounting AS PostInCostAccounting,
		|	DocumentData.PostInFinancialAndTaxAccounting AS PostInFinancialAndTaxAccounting,
		|	DocumentData.RecordInMA AS RecordInMA,
		|	CAST(DocumentData.Comment AS STRING(100)) AS Comment,
		|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
		|	DocumentData.DeletionMark AS DeletionMark,
		|	DocumentData.Patch AS Patch,
		|	DocumentData.ReversedDocument AS ReversedDocument,
		|	DocumentData.CorrectedDocument AS CorrectedDocument,
		|	DocumentData.GenerateVATCharged AS GenerateVATCharged,
		|	DocumentData.Posted AS Posted,
		|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting,
		|	SUM(ISNULL(DataOfTabularPartOfGoods.Sum, 0)) AS DocumentAmount
		|FROM
		|	Document.OBEntryGoods AS DocumentData
		|		LEFT JOIN Document.OBEntryGoods.Goods AS DataOfTabularPartOfGoods
		|		ON DocumentData.Ref = DataOfTabularPartOfGoods.Ref
		|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
		|WHERE
		|	DocumentData.Ref = &Ref
		|
		|GROUP BY
		|	DocumentData.Date,
		|	DocumentData.Number,
		|	DocumentData.Ref,
		|	DocumentData.Organization,
		|	DocumentData.Department,
		|	DocumentData.Department.OptionOfAssignedAccountingOfGoods,
		|	DocumentData.Warehouse,
		|	DocumentData.Currency,
		|	DocumentData.Premise,
		|	DocumentData.BusinessOperation,
		|	DocumentData.VATTaxation,
		|	DocumentData.VATActivityType,
		|	CASE WHEN DocumentData.Lot = VALUE(Document.SourceDocument.EmptyRef)
		|		THEN DocumentData.Ref
		|		ELSE DocumentData.Lot
		|	END,
		|	ISNULL(DocumentData.Lot.SourceDocumentType, VALUE(Enum.SourceDocumentTypes.EmptyRef)) = VALUE(Enum.SourceDocumentTypes.InternalInvoice),
		|	DocumentData.Partner,
		|	DocumentData.Counterparty,
		|	DocumentData.Contract,
		|	DocumentData.TermsOfConsignmentSales,
		|	DocumentData.TermsOfConsignmentPurchase,
		|	DocumentData.CustomerTermsOfSales,
		|	DocumentData.OrderDocument,
		|	DocumentData.ReceivingArea,
		|	DocumentData.Manager,
		|	DocumentData.Author,
		|	DocumentData.PriceIncludesVAT,
		|	DocumentData.LineOfBusiness,
		|	DocumentData.RecordInOperationalAccounting,
		|	DocumentData.PostInCostAccounting,
		|	DocumentData.PostInFinancialAndTaxAccounting,
		|	DocumentData.RecordInMA,
		|	CAST(DocumentData.Comment AS STRING(100)),
		|	DocumentData.EmployeeResponsible,
		|	DocumentData.DeletionMark,
		|	DocumentData.Patch,
		|	DocumentData.ReversedDocument,
		|	DocumentData.CorrectedDocument,
		|	DocumentData.GenerateVATCharged,
		|	DocumentData.Posted,
		|	BusinessTransactionsSettings.Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();

	Query.SetParameter("Period",   Attributes.Period);
	Query.SetParameter("Number",    Attributes.Number);
	Query.SetParameter("Posted", Attributes.Posted);
	
	If Attributes.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse 
		Or Attributes.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingSentToCustomers Then
		Query.SetParameter("Warehouse" , Attributes.Partner);
	Else
		Query.SetParameter("Warehouse" , Attributes.Warehouse);
	EndIf;
	
	ListOfOrderTypes = New ValueList;
	ListOfOrderTypes.Add(Type("CatalogRef.CounterpartyContracts"));
	ListOfOrderTypes.Add(Type("CatalogRef.IntercompanyContracts"));
	ListOfOrderTypes.Add(Type("DocumentRef.SalesOrder"));
	ListOfOrderTypes.Add(Type("DocumentRef.PurchaseOrder"));
	ListOfOrderTypes.Add(Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"));
	ListOfOrderTypes.Add(Type("DocumentRef.MaterialProviderOrder2_5"));
	ListOfOrderTypes.Add(Type("DocumentRef.SubcontractOrder2_5"));
	Query.SetParameter("ListOfOrderTypes", ListOfOrderTypes);
	
	Query.SetParameter("Premise",                             Attributes.Premise);
	Query.SetParameter("Organization",                           Attributes.Organization);
	Query.SetParameter("Department",                         Attributes.Department);
	Query.SetParameter("BusinessOperation",                 Attributes.BusinessOperation);
	Query.SetParameter("Partner",                               Attributes.Partner);
	Query.SetParameter("Counterparty",                            Attributes.Counterparty);
	Query.SetParameter("Contract",                               Attributes.Contract);
	Query.SetParameter("CustomerTermsOfSales",                   Attributes.CustomerTermsOfSales);
	Query.SetParameter("TermsOfConsignmentSales",              Attributes.TermsOfConsignmentSales);
	Query.SetParameter("VATTaxation",                    Attributes.VATTaxation);
	Query.SetParameter("VATActivityType",                    Attributes.VATActivityType);
	Query.SetParameter("UseAccountingOfOtherIncomeExpenses", GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	Query.SetParameter("Manager",                              Attributes.Manager);
	Query.SetParameter("Author",                                 Attributes.Author);
	Query.SetParameter("LocalAccountingCurrency",        SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
	Query.SetParameter("ManagementAccountingCurrency",            Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("ReceivingArea",                           Attributes.ReceivingArea);
	Query.SetParameter("OrderDocument",                                 Attributes.OrderDocument);
	Query.SetParameter("PriceIncludesVAT",                       Attributes.PriceIncludesVAT);
	Query.SetParameter("LineOfBusiness",               Attributes.LineOfBusiness);
	Query.SetParameter("RecordInOperationalAccounting",             Attributes.RecordInOperationalAccounting);
	Query.SetParameter("PostInFinancialAndTaxAccounting",                        Attributes.PostInFinancialAndTaxAccounting);
	Query.SetParameter("RecordInMA",                           Attributes.RecordInMA);
	Query.SetParameter("EmptyAssignment",                      Catalogs.Assignments.EmptyRef());
	Query.SetParameter("Lot",                                Attributes.Lot);
	Query.SetParameter("InternalInvoiceInBatch",            Attributes.InternalInvoiceInBatch);
	Query.SetParameter("EmployeeResponsible",                         Attributes.EmployeeResponsible);
	Query.SetParameter("Comment",                           Attributes.Comment);
	Query.SetParameter("DeletionMark",                       Attributes.DeletionMark);
	Query.SetParameter("DocumentAmount",                        Attributes.DocumentAmount);
	Query.SetParameter("Currency",                                Attributes.Currency);
	Query.SetParameter("Patch",                           Attributes.Patch);
	Query.SetParameter("ReversedDocument",                  Attributes.ReversedDocument);
	Query.SetParameter("CorrectedDocument",                  Attributes.CorrectedDocument);
	Query.SetParameter("GenerateVATCharged",           Attributes.GenerateVATCharged);
	Query.SetParameter("BusinessTransactionSetting",        Attributes.BusinessTransactionSetting);
	Query.SetParameter("MetadataIdentifier", 
		Common.MetadataObjectID("Document." + Metadata.Documents.OBEntryGoods.Name));
	Query.SetParameter("AdjustmentPeriod_",                   Date(1,1,1));
	
	// Unlike other documents, the input of the units can be carried out according to the cost registers in the month before the inclusion of cost accounting.
	Query.SetParameter("PostInCostAccounting", Attributes.PostInCostAccounting
		And CalculationOfCostCached.GenerateRegisteredRecordsOnCostRegisters(BegOfMonth(Attributes.Period), True));
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
EndProcedure

Procedure InitializeProductAccountingAnalyticsKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query("
	|SELECT DISTINCT
	|	Keys.Products         AS Products,
	|	Keys.Characteristic       AS Characteristic,
	|	&EmptyAssignment          AS Purpose,
	|	Keys.Series                AS Series,
	|	Keys.Warehouse                AS Warehouse
	|FROM
	|	(
	|	SELECT DISTINCT
	|		Goods.ItemsLocationAttributes.Products   AS Products,
	|		Goods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		&EmptyAssignment                                AS Purpose,
	|		Goods.ItemsLocationAttributes.Series          AS Series,
	|		Goods.ItemsLocationAttributes.StorageLocation  AS Warehouse
	|	FROM
	|		Document.OBEntryGoods.Goods AS Goods
	|	WHERE
	|		NOT &KeepRecordsOfInventoryCostByAssignments
	|		AND Goods.Ref = &Ref
	|	) AS Keys
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON Keys.Products = Dimension.Products
	|		AND Keys.Characteristic = Dimension.Characteristic
	|		AND Keys.Series = Dimension.Series
	|		AND Keys.Warehouse = Dimension.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		AND &EmptyAssignment = Dimension.Purpose
	|WHERE
	|	Dimension.DimensionKey IS NULL
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingGoodsTransferredToVMI),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI),
	|		VALUE(Enum.BusinessTransactions.OBEntryShippedGoods),
	|		VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingSentToCustomers),
	|		VALUE(Enum.BusinessTransactions.OBEntryStatisticsOfWholesaleTransactionsInPastPeriods),
	|		VALUE(Enum.BusinessTransactions.OBEntryStatisticsOfRetailSaleTransactionsInPastPeriods)
	|		)	
	|");
	
	QueryAnalyst.SetParameter("Ref",                                     Query.Parameters.Ref);
	QueryAnalyst.SetParameter("EmptyAssignment",                           Query.Parameters.EmptyAssignment);
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	QueryAnalyst.SetParameter("BusinessOperation",                      Query.Parameters.BusinessOperation);
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure

Function QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers)
	
	RegisterName = "DatesOfCompanyGoodsReceipt";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTTProducts_1(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT DISTINCT
	|	&Period                       AS DateOfReceipt,
	|	GoodsTable.Products    AS Products,
	|	GoodsTable.Characteristic  AS Characteristic,
	|	GoodsTable.Series           AS Series,
	|	GoodsTable.Purpose      AS Purpose,
	|	GoodsTable.InventoryOwnerAttribute      AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber        AS CCDNumber
	|FROM
	|	TTProducts_1 AS GoodsTable
	|
	|		LEFT JOIN
	|			InformationRegister.DatesOfCompanyGoodsReceipt AS UninvoicedReceipts
	|		ON 
	|			  GoodsTable.InventoryOwnerAttribute     = UninvoicedReceipts.InventoryOwnerAttribute
	|			AND GoodsTable.Products   = UninvoicedReceipts.Products
	|			AND GoodsTable.Characteristic = UninvoicedReceipts.Characteristic
	|			AND GoodsTable.Series          = UninvoicedReceipts.Series
	|			AND GoodsTable.Purpose     = UninvoicedReceipts.Purpose
	|			AND GoodsTable.CCDNumber       = UninvoicedReceipts.CCDNumber
	|WHERE
	|	(UninvoicedReceipts.DateOfReceipt IS NULL 
	|			OR UninvoicedReceipts.DateOfReceipt < &Period)
	|	AND &RecordInOperationalAccounting
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider),
	|		VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors))
	|	AND NOT GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&Period                       AS DateOfReceipt,
	|	GoodsTable.Products    AS Products,
	|	GoodsTable.Characteristic  AS Characteristic,
	|	GoodsTable.Series           AS Series,
	|	GoodsTable.Purpose      AS Purpose,
	|	GoodsTable.InventoryOwnerAttribute      AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber        AS CCDNumber
	|FROM
	|	TTProducts_1 AS GoodsTable
	|
	|		LEFT JOIN
	|			InformationRegister.DatesOfCompanyGoodsReceipt AS UninvoicedReceipts
	|		ON 
	|			  GoodsTable.InventoryOwnerAttribute     = UninvoicedReceipts.InventoryOwnerAttribute
	|			AND GoodsTable.Products   = UninvoicedReceipts.Products
	|			AND GoodsTable.Characteristic = UninvoicedReceipts.Characteristic
	|			AND GoodsTable.Series          = UninvoicedReceipts.Series
	|			AND GoodsTable.Purpose     = UninvoicedReceipts.Purpose
	|			AND GoodsTable.CCDNumber       = UninvoicedReceipts.CCDNumber
	|WHERE
	|	(UninvoicedReceipts.DateOfReceipt IS NULL 
	|			OR UninvoicedReceipts.DateOfReceipt < &Period)
	|	AND &RecordInOperationalAccounting
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned)
	|	AND GoodsTable.Count <> 0
	|	AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND &UseTraceableImportedGoodsAccounting
	|	AND GoodsTable.Products.TracedGoods
	|
	|ORDER BY
	|	GoodsTable.InventoryOwnerAttribute,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.Purpose,
	|	GoodsTable.CCDNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDatesOfConsignmentGoodsTransfer(Query, QueryTexts, Registers)
	
	RegisterName = "DatesOfConsignmentGoodsTransfer";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTTProducts_1(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT DISTINCT
	|	&Period                           AS TransferDate,
	|	Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Goods.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	Goods.CCDNumber                   AS CCDNumber,
	|	&TermsOfConsignmentSales         AS Terms,
	|	&Organization                      AS Organization
	|FROM
	|	TTProducts_1 AS Goods
	|
	|	LEFT JOIN
	|		InformationRegister.DatesOfConsignmentGoodsTransfer AS DatesOfConsignmentGoodsTransfer
	|	ON
	|		  Goods.InventoryOwnerAttribute                 = DatesOfConsignmentGoodsTransfer.InventoryOwnerAttribute 
	|		AND Goods.ItemsLocationAttributes = DatesOfConsignmentGoodsTransfer.ItemsLocationAttributes
	|		AND Goods.CCDNumber                   = DatesOfConsignmentGoodsTransfer.CCDNumber 
	|		AND DatesOfConsignmentGoodsTransfer.Terms  = &TermsOfConsignmentSales
	|		AND DatesOfConsignmentGoodsTransfer.Organization = &Organization
	|
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse)
	|	AND &RecordInOperationalAccounting
	|	AND (DatesOfConsignmentGoodsTransfer.TransferDate IS NULL
	|		OR DatesOfConsignmentGoodsTransfer.TransferDate < &Period)
	|
	|ORDER BY
	|	Goods.ItemsLocationAttributes,
	|	Goods.CCDNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)     AS RecordType,
	|	&Period                                    AS Period,
	|	&Organization                               AS Organization,
	|	GoodsTable.Products                 AS Products,
	|	GoodsTable.Characteristic               AS Characteristic,
	|	GoodsTable.InventoryOwnerAttribute                   AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber                     AS CCDNumber,
	|	GoodsTable.Count                   AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE GoodsTable.QuantityByGBRN
	|	END                                      AS QuantityByGBRN,
	|	GoodsTable.ItemsLocationAttributes   AS ItemsLocationAttributes,
	|	TRUE                                     AS Primary,
	|	&BusinessOperation                     AS BusinessOperation
	|FROM
	|	Document.OBEntryGoods.Goods AS GoodsTable
	|WHERE
	|	&RecordInOperationalAccounting
	|	AND GoodsTable.Ref = &Ref
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingGoodsTransferredToVMI),
	|		VALUE(Enum.BusinessTransactions.OBEntryShippedGoods),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider),
	|		VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors))
	|	AND GoodsTable.Count <> 0
	|	AND NOT GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)     AS RecordType,
	|	&Period                                    AS Period,
	|	&Organization                               AS Organization,
	|	GoodsTable.Products                 AS Products,
	|	GoodsTable.Characteristic               AS Characteristic,
	|	GoodsTable.InventoryOwnerAttribute                   AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber                     AS CCDNumber,
	|	GoodsTable.Count                   AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE GoodsTable.QuantityByGBRN
	|	END                                      AS QuantityByGBRN,
	|	GoodsTable.ItemsLocationAttributes   AS ItemsLocationAttributes,
	|	TRUE                                     AS Primary,
	|	&BusinessOperation                     AS BusinessOperation
	|FROM
	|	Document.OBEntryGoods.Goods AS GoodsTable
	|WHERE
	|	&RecordInOperationalAccounting
	|	AND GoodsTable.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned)
	|	AND GoodsTable.Count <> 0
	|	AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND &UseTraceableImportedGoodsAccounting
	|	AND GoodsTable.Products.TracedGoods
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableShipmentReferences(Query, QueryTexts, Registers)
	
	RegisterName = "ShipmentAndReturnReferences";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	GoodsTable.Ref.Lot AS ReferenceOrder,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.RowCode AS RowCode,
	|	CASE
	|		WHEN TableOfIndicators.Ref IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Ordered),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped))
	|			THEN GoodsTable.Ref.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	CASE
	|		WHEN TableOfIndicators.Ref IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Ordered),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped))
	|		AND GoodsTable.BatchesIndicationStatus IN (10, 14)
	|			THEN GoodsTable.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TableOfIndicators.Ref AS Factor,
	|	GoodsTable.Count AS Count,
	|	0 AS Sum,
	|	VALUE(Catalog.ReasonsForSaleOrderCancellation.EmptyRef) AS CancellationReason
	|FROM
	|	Document.OBEntryGoods.Goods AS GoodsTable
	|		INNER JOIN Enum.IndicatorsOfShipmentAndReturnReferences AS TableOfIndicators
	|		ON TableOfIndicators.Ref IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Ordered),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped))
	|WHERE
	|	&RecordInOperationalAccounting
	|	AND GoodsTable.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryShippedGoods)
	|	AND GoodsTable.Count <> 0
	|	AND NOT GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|
	|ORDER BY
	|	LineNumber,
	|	Factor";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsTransferredToCommissionAgent(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsTransferredToCommissionAgent";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTTProducts_1(Query, QueryTexts);
	EndIf;
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	QueryText =
	"SELECT
	|	GoodsTable.LineNumber                AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)   AS RecordType,
	|	&Period                                  AS Period,
	|	&Organization                             AS Organization,
	|	&Partner                                 AS Partner,
	|	&TermsOfConsignmentSales                AS Terms,
	|	&Contract                                 AS Contract,
	|	GoodsTable.Products               AS Products,
	|	GoodsTable.Characteristic             AS Characteristic,
	|	GoodsTable.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber                   AS CCDNumber,
	|	GoodsTable.Count                 AS Count,
	|	CASE
	|		WHEN &UseTraceableImportedGoodsAccounting
	|				AND BEGINOFPERIOD(&Period, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
	|			THEN GoodsTable.QuantityByGBRN
	|		ELSE 0
	|	END AS QuantityByGBRN,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM
	|	TTProducts_1 AS GoodsTable
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse)
	|	AND &RecordInOperationalAccounting
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	LineNumberText = CostCalculationDocumentsPosting.RequestTextStringCodesForBatchAccountingAnalytics(
		Metadata.Documents.OBEntryGoods.Name,
		"Goods");
	
	TextSelectionOfAnalystField = LineNumberText + "
	|SELECT
	|	""Goods""                                                                AS TabularSectionName,
	|	DocumentTable.LineNumber                                              AS LineNumber,
	|	ISNULL(SourceDocument.Partner, DocumentData.Partner)              AS Vendor,
	|	ISNULL(SourceDocument.Counterparty, DocumentData.Counterparty)        AS Counterparty,
	|	DocumentTable.VATRate                                                AS VATRate,
	|	CASE 
	|		WHEN DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse),
	|			VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider),
	|			VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider),
	|			VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting),
	|			VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors),
	|			VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5),
	|			VALUE(Enum.BusinessTransactions.OBEntryGoodsCostVariances),
	|			VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned))
	|		THEN CASE
	|			WHEN ISNULL(DocumentTable.Purpose.VATActivityType,VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|				THEN DocumentTable.Purpose.VATActivityType
	|			ELSE DocumentData.VATActivityType
	|			END
	|		ELSE DocumentData.VATTaxation 
	|	END                                                                     AS VATTaxation,
	|	ISNULL(FAG.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods)) AS AssetTaxClass,
	|	LineCodes.RowCode														  AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.OBEntryGoods.Goods AS DocumentTable
	|	INNER JOIN Document.OBEntryGoods AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|	INNER JOIN TTLineCodesForBatchAccountingAnalytics AS LineCodes
	|		ON DocumentTable.LineNumber = LineCodes.LineNumber
	|		AND LineCodes.TabularSectionName = ""Goods""
	|	LEFT JOIN Catalog.InventoryAccountingGroups AS FAG
	|		ON DocumentTable.Products.FinancialAccountingGroup = FAG.Ref
	|	LEFT JOIN Document.SourceDocument AS SourceDocument
	|		ON SourceDocument.Ref = DocumentData.Lot
	|WHERE
	|	DocumentTable.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	""LotDetails""                                                   AS TabularSectionName,
	|	DocumentTable.LineNumber                                            AS LineNumber,
	|	DocumentTable.Partner                                                AS Vendor,
	|	DocumentTable.Counterparty                                             AS Counterparty,
	|	DocumentTable.VATRate                                              AS VATRate,
	|	CASE 
	|		WHEN DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse),
	|			VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned),
	|			VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider),
	|			VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider),
	|			VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5),
	|			VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors))
	|		THEN DocumentData.VATActivityType
	|		ELSE DocumentData.VATTaxation 
	|	END                                                                   AS VATTaxation,
	|	DocumentTable.AssetTaxClass                                            AS AssetTaxClass,
	|	0                                                                       AS RowCode
	|FROM
	|	Document.OBEntryGoods.LotDetails AS DocumentTable
	|	INNER JOIN Document.OBEntryGoods AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|WHERE
	|	DocumentTable.Ref = &Ref
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTTProducts_1(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTPartyDetails", QueryTexts) Then
		QueryTextTTPartyDetails(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDetailingOfBatchesAmounts", QueryTexts) Then
		QueryTextTTDetailingOfBatchesAmounts(Query, QueryTexts);
	EndIf; 

	TextProducts_1 = 
	"SELECT
	|	Goods.Ref.Date AS Period,
	|	Goods.Ref AS Ref,
	|	VALUE(Enum.BusinessTransactions.GoodsRecordingAsReceived) AS BusinessOperation,
	|	FALSE AS OBEntry22,
	|	Goods.Ref.Organization AS Organization,
	|	Goods.Ref.Department AS Department,
	|	Goods.Ref.Lot.Counterparty AS Counterparty,
	|	Goods.Ref.Lot AS BatchPurchaseOfGoods,
	|	Goods.Ref.VATActivityType AS VATActivityType,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.VATRate AS VATRate,
	|	Goods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Goods.CCDNumber AS CCDNumber,
	|	CASE
	|		WHEN Goods.SumCompl - ISNULL(DetailingTotalAmount.SumCompl, 0) > 0
	|		THEN Goods.SumCompl - ISNULL(DetailingTotalAmount.SumCompl, 0)
	|		ELSE 0
	|	END AS AmountExcludingVATCompl,
	|	CASE
	|		WHEN Goods.VATLocal - ISNULL(DetailingTotalAmount.VATLocal, 0) > 0
	|		THEN Goods.VATLocal - ISNULL(DetailingTotalAmount.VATLocal, 0)
	|		ELSE 0
	|	END AS VATAmountCompl,
	|	CASE
	|		WHEN Goods.VATManag - ISNULL(DetailingTotalAmount.VATManag, 0) > 0
	|		THEN Goods.VATManag - ISNULL(DetailingTotalAmount.VATManag, 0)
	|		ELSE 0
	|	END AS VATAmountMan,
	|	Goods.RowID AS RowID
	|FROM
	|	TTProducts_1 AS Goods
	|	LEFT JOIN
	|		TTDetailingOfBatchesAmounts AS DetailingTotalAmount
	|	ON 
	|		Goods.RowID = DetailingTotalAmount.RowID
	|		AND Goods.Ref = DetailingTotalAmount.Ref
	|WHERE
	|	Goods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse)
	|	AND Goods.Ref.PostInCostAccounting
	|	AND Goods.Ref.Lot <> VALUE(Document.SourceDocument.EmptyRef)
	|	AND &GenerateVATCharged
	|	
	|UNION ALL
	|
	|SELECT
	|	Goods.Ref.Date AS Period,
	|	Goods.Ref AS Ref,
	|	VALUE(Enum.BusinessTransactions.GoodsRecordingAsReceived) AS BusinessOperation,
	|	FALSE AS OBEntry22,
	|	Goods.Ref.Organization AS Organization,
	|	Goods.Ref.Department AS Department,
	|	Goods.LotVendorAttributesOfReceiptDocument.Counterparty AS Counterparty,
	|	Goods.DocumentInflow AS BatchPurchaseOfGoods,
	|	Goods.Ref.VATActivityType AS VATActivityType,
	|
	|	Goods.ItemsLocationAttributes.Products AS Products,
	|	Goods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	Goods.VATRate AS VATRate,
	|	Goods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Goods.CCDNumber AS CCDNumber,
	|	Goods.SumCompl AS AmountExcludingVATCompl,
	|	Goods.VATLocal AS VATAmountCompl,
	|	Goods.VATManag AS VATAmountMan,
	|	Goods.RowID AS RowID
	|FROM
	|	TTPartyDetails AS Goods
	|WHERE
	|	Goods.Ref.PostInCostAccounting
	|	AND Goods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse)
	|	AND &GenerateVATCharged
	|";
	
	VATAccountingERP.ReflectEntryOfBalancesOfOwnGoods(Query, QueryTexts, Registers, TextProducts_1);
	
EndProcedure

Function QueryTextTTProducts_1(Query, QueryTexts)
	
	RegisterName = "TTProducts_1";
	
	InitializeProductAccountingAnalyticsKeys(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	GoodsTable.Ref                             AS Ref,
	|	GoodsTable.LineNumber                        AS LineNumber,
	|	GoodsTable.Products                       AS Products,
	|	GoodsTable.Characteristic                     AS Characteristic,
	|	GoodsTable.Purpose.LineOfBusiness AS LineOfBusiness,
	|	GoodsTable.Purpose                         AS Purpose,
	|	GoodsTable.Series                              AS Series,
	|	GoodsTable.ItemsLocationAttributes         AS ItemsLocationAttributes,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments 
	|		THEN GoodsTable.ItemsLocationAttributes
	|		ELSE DimensionCostOfProduction.DimensionKey
	|	END                                           AS CostAccountingAnalytics,
	|	
	|	GoodsTable.VATRate                         AS VATRate,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass          AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation   AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	GoodsTable.Count                        AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE GoodsTable.QuantityByGBRN
	|	END                                           AS QuantityByGBRN,
	|	CASE
	|		WHEN &PriceIncludesVAT
	|		THEN GoodsTable.Sum
	|		ELSE GoodsTable.AmountIncludingVAT
	|	END                                           AS Sum,
	|	GoodsTable.AmountExcludingVAT                       AS AmountExcludingVAT,
	|	GoodsTable.AmountExcludingVAT                       AS SumMan,
	|	GoodsTable.VATAmount                          AS VATAmount,
	|	GoodsTable.SumCompl                         AS SumCompl,
	|	GoodsTable.VATLocal                           AS VATLocal,
	|	CASE
	|		WHEN &PriceIncludesVAT
	|		THEN GoodsTable.Sum - GoodsTable.AmountExcludingVAT
	|		ELSE GoodsTable.AmountIncludingVAT - GoodsTable.AmountExcludingVAT
	|	END                                           AS VATManag,
	|	GoodsTable.AmountPermanentDifferences                           AS AmountPermanentDifferences,
	|	GoodsTable.AmountTemporaryDifferences                           AS AmountTemporaryDifferences,
	|	GoodsTable.AmountOffBalance                     AS AmountOffBalance,
	|	GoodsTable.AmountLocalOffBalance                 AS AmountLocalOffBalance,
	|	-GoodsTable.ProvisionForImpairmentLocal         AS ProvisionForImpairmentLocal,
	|	-GoodsTable.ProvisionForImpairmentMan          AS ProvisionForImpairmentMan,
	|	GoodsTable.AITAmount                          AS AITAmount,
	|	GoodsTable.InventoryOwnerAttribute                        AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber                          AS CCDNumber,
	|	GoodsTable.DepositForPackageIsRequired           AS DepositForPackageIsRequired,
	|	GoodsTable.RowCode                         AS RowCode,
	|	GoodsTable.ProductsGroup                   AS ProductsGroup,
	|	GoodsTable.RowID               AS RowID
	|INTO TTProducts_1
	|FROM
	|	Document.OBEntryGoods.Goods AS GoodsTable
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionCostOfProduction
	|	ON GoodsTable.ItemsLocationAttributes.Products = DimensionCostOfProduction.Products
	|		AND GoodsTable.ItemsLocationAttributes.Characteristic = DimensionCostOfProduction.Characteristic
	|		AND GoodsTable.ItemsLocationAttributes.Series = DimensionCostOfProduction.Series
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = DimensionCostOfProduction.ProductCostElement
	|		AND GoodsTable.ItemsLocationAttributes.StorageLocation = DimensionCostOfProduction.StorageLocation
	|		AND &EmptyAssignment = DimensionCostOfProduction.Purpose
	|
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber       = GoodsTable.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Goods""
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingGoodsTransferredToVMI),
	|		VALUE(Enum.BusinessTransactions.OBEntryShippedGoods),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingSentToCustomers),
	|		VALUE(Enum.BusinessTransactions.OBEntryWarehouseBinAddressOfOwnedInventory),
	|		VALUE(Enum.BusinessTransactions.OBEntryWareroomAddressOfOwnedInventory),
	|		VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned),
	|		VALUE(Enum.BusinessTransactions.OBEntryGoodsCostVariances)
	|		)
	|	AND (GoodsTable.Count <> 0
	|		OR &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryGoodsCostVariances))
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTPartyDetails(Query, QueryTexts)
	
	RegisterName = "TTPartyDetails";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	BatchDetailTable.Ref                       AS Ref,
	|	BatchDetailTable.LineNumber                  AS LineNumber,
	|	GoodsTable.Products                            AS Products,
	|	GoodsTable.Characteristic                          AS Characteristic,
	|	GoodsTable.Purpose.LineOfBusiness      AS LineOfBusiness,
	|	GoodsTable.ItemsLocationAttributes              AS ItemsLocationAttributes,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments 
	|		THEN GoodsTable.ItemsLocationAttributes
	|		ELSE DimensionCostOfProduction.DimensionKey
	|	END                                                 AS CostAccountingAnalytics,
	|	GoodsTable.InventoryOwnerAttribute                              AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber                                AS CCDNumber,
	|	BatchDetailTable.VATRate                    AS VATRate,
	|	BatchDetailTable.DocumentInflow          AS DocumentInflow,
	|	PartyAccountingAnalystTablePartyDetails.AssetTaxClass          AS AssetTaxClass,
	|	PartyAccountingAnalystTablePartyDetails.VATTaxation   AS VATActivityType,
	|	PartyAccountingAnalystTablePartyDetails.LotVendorAttributes AS LotVendorAttributesOfReceiptDocument,
	|	TableOfBatchAccountingAnalystsGoods.LotVendorAttributes AS LotVendorAttributes,
	|	BatchDetailTable.ExpenseItem 			  AS ExpenseItem,
	|	BatchDetailTable.SumCompl                    AS SumCompl,
	|	BatchDetailTable.SumMan                     AS SumMan,
	|	BatchDetailTable.VATLocal                      AS VATLocal,
	|	BatchDetailTable.VATManag                       AS VATManag,
	|	
	|	GoodsTable.ProductsGroup                         AS ProductsGroup,
	|	BatchDetailTable.RowID          AS RowID
	|
	|INTO TTPartyDetails
	|FROM
	|	Document.OBEntryGoods.LotDetails AS BatchDetailTable
	|	
	|	INNER JOIN Document.OBEntryGoods.Goods AS GoodsTable
	|	ON BatchDetailTable.Ref = GoodsTable.Ref
	|		AND BatchDetailTable.RowID = GoodsTable.RowID
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionCostOfProduction
	|	ON GoodsTable.ItemsLocationAttributes.Products = DimensionCostOfProduction.Products
	|		AND GoodsTable.ItemsLocationAttributes.Characteristic = DimensionCostOfProduction.Characteristic
	|		AND GoodsTable.ItemsLocationAttributes.Series = DimensionCostOfProduction.Series
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = DimensionCostOfProduction.ProductCostElement
	|		AND GoodsTable.ItemsLocationAttributes.StorageLocation = DimensionCostOfProduction.StorageLocation
	|		AND &EmptyAssignment = DimensionCostOfProduction.Purpose
	|
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS PartyAccountingAnalystTablePartyDetails
	|	ON PartyAccountingAnalystTablePartyDetails.LineNumber = BatchDetailTable.LineNumber
	|	 AND PartyAccountingAnalystTablePartyDetails.TabularSectionName = ""LotDetails""
	|	
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalystsGoods
	|	ON TableOfBatchAccountingAnalystsGoods.LineNumber       = GoodsTable.LineNumber
	|	 AND TableOfBatchAccountingAnalystsGoods.TabularSectionName = ""Goods""
	|	
	|WHERE
	|	GoodsTable.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTDetailingOfBatchesAmounts(Query, QueryTexts)
	
	RegisterName = "TTDetailingOfBatchesAmounts";
	
	QueryText =
	"SELECT
	|	BatchDetailTable.Ref               AS Ref,
	|	BatchDetailTable.RowID  AS RowID,
	|	BatchDetailTable.ExpenseItem  	  AS ExpenseItem,
	|	DocumentTable.Lot 					  AS DocumentInflow,
	|	SUM(BatchDetailTable.SumCompl)     AS SumCompl,
	|	SUM(BatchDetailTable.SumMan)      AS SumMan,
	|	SUM(BatchDetailTable.VATLocal)       AS VATLocal,
	|	SUM(BatchDetailTable.VATManag)        AS VATManag
	|INTO TTDetailingOfBatchesAmounts
	|FROM
	|	Document.OBEntryGoods.LotDetails AS BatchDetailTable
	|	INNER JOIN Document.OBEntryGoods AS DocumentTable
	|		ON BatchDetailTable.Ref = DocumentTable.Ref
	|
	|WHERE
	|	BatchDetailTable.Ref = &Ref
	|	
	|GROUP BY
	|	BatchDetailTable.Ref,
	|	BatchDetailTable.RowID,
	|	BatchDetailTable.ExpenseItem,
	|	DocumentTable.Lot
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableProducts(Query, QueryTexts)
	
	RegisterName = "TTTableProducts";
	
	QueryText =
	"SELECT
	|	GoodsTable.Products        AS Products,
	|	GoodsTable.Characteristic      AS Characteristic,
	|	GoodsTable.Purpose       AS Purpose,
	|	GoodsTable.Package            AS Package,
	|	GoodsTable.Count          AS Count,
	|	GoodsTable.NumberOfPackages  AS NumberOfPackages,
	|	GoodsTable.Series               AS Series,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus
	|INTO TTTableProducts
	|FROM
	|	Document.OBEntryGoods.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI),
	|		VALUE(Enum.BusinessTransactions.OBEntryShippedGoods),
	|		VALUE(Enum.BusinessTransactions.OBEntryWarehouseBinAddressOfOwnedInventory),
	|		VALUE(Enum.BusinessTransactions.OBEntryWareroomAddressOfOwnedInventory),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider),
	|		VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors))
	|	AND GoodsTable.Count <> 0
	|	AND NOT GoodsTable.BatchesIndicationStatus IN (4, 6, 8, 10)
	|
	|UNION ALL
	|
	|SELECT
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	SeriesTable.Purpose,
	|	SeriesTable.Package,
	|	MAX(SeriesTable.Count),
	|	MAX(SeriesTable.NumberOfPackages),
	|	SeriesTable.Series,
	|	MAX(GoodsTable.BatchesIndicationStatus)
	|FROM
	|	Document.OBEntryGoods.SetOfSeries AS SeriesTable
	|		INNER JOIN Document.OBEntryGoods.Goods AS GoodsTable
	|		ON SeriesTable.Ref = GoodsTable.Ref
	|			AND SeriesTable.Products = GoodsTable.Products
	|			AND SeriesTable.Characteristic = GoodsTable.Characteristic
	|			AND SeriesTable.Purpose = GoodsTable.Purpose
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI),
	|		VALUE(Enum.BusinessTransactions.OBEntryWarehouseBinAddressOfOwnedInventory),
	|		VALUE(Enum.BusinessTransactions.OBEntryWareroomAddressOfOwnedInventory),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider),
	|		VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors))
	|	AND SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|
	|GROUP BY
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	SeriesTable.Purpose,
	|	SeriesTable.Series,
	|	SeriesTable.Package
	|
	|HAVING
	|	MAX(GoodsTable.BatchesIndicationStatus) IN (4, 6, 8, 10)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableProductStock(Query, QueryTexts, Registers)
	
	RegisterName = "ProductStock";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Warehouse AS Warehouse,
	|	&Premise AS Premise,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Count AS InStock
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	&RecordInOperationalAccounting
	|	AND (&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse)
	|			OR &BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting)
	|			OR &BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider)
	|			OR &BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider)
	|			OR &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|			OR &BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI)
	|			OR &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors)
	|			OR &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryWareroomAddressOfOwnedInventory))
	|	AND NOT GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense),
	|	&Period,
	|	&Warehouse,
	|	VALUE(Catalog.Warerooms.EmptyRef),
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef),
	|	GoodsTable.Series,
	|	GoodsTable.Count
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryWareroomAddressOfOwnedInventory)
	|	AND &RecordInOperationalAccounting";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction


// Parameters:
//  Query - Query
//  QueryTexts - ValueList
//  Registers - String - register name;
//  		 - Structure -list of register names 
// 
// Returns:
//  String - Query text
Function QueryTextTableDetailsOfBatchesOfGoodsForLBSiUSN2_4(Query, QueryTexts, Registers) Export
	
	// Now the movements are formed offline according to the new VAT batch registers.
	RegisterName = "DetailsOfBatchesOfGoodsForLBSiUSN2_4";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers)
		And Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, "InventoryCost") Then
		Return "";
	EndIf;
	
	SetParametersForCreatingVATBatchRegisters(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTTProducts_1(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTPartyDetails", QueryTexts) Then
		QueryTextTTPartyDetails(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDetailingOfBatchesAmounts", QueryTexts) Then
		QueryTextTTDetailingOfBatchesAmounts(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)                     AS RecordType,
	|	LotDetails.LineNumber                              AS LineNumber,
	|	&Period                                                    AS Period,
	|	&Organization                                               AS Organization,
	|	LotDetails.ItemsLocationAttributes			   AS ItemsLocationAttributes,
	|	LotDetails.InventoryOwnerAttribute			   				   AS InventoryOwnerAttribute,
	|	CASE 
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN &BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse)
	|			OR &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingGoodsTransferredToVMI)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners)
	|		ELSE
	|			CASE WHEN ISNULL(LotDetails.CostAccountingAnalytics.WarehouseArea.ShopFloorStockroom, FALSE)
	|				THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|				ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|			END
	|	END                                            		   AS AccountingSection,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned)
	|			 AND LotDetails.ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN LotDetails.ProductsGroup
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|				THEN &Manager
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|				THEN &Department
	|		ELSE UNDEFINED
	|	END                                                      AS FinancialAccountingDimension,
	|	&Lot                                                    AS Lot,
	|	LotDetails.LotVendorAttributes                     AS LotVendorAttributes,
	|	LotDetails.VATActivityType	                   AS VATActivityType,
	|	LotDetails.DocumentInflow	                   AS DocumentInflow,
	|	LotDetails.LotVendorAttributesOfReceiptDocument AS AnalysisOfReceiptDocumentAccounting,
	|	LotDetails.Products                             AS Products,
	|	LotDetails.Characteristic                           AS Characteristic,
	|	LotDetails.LineOfBusiness                  AS LineOfBusiness,
	|	LotDetails.ExpenseItem						   AS ExpenseItemAssets,
	|	0														   AS Count,
	|	LotDetails.SumCompl                                AS CostExcludingVAT,
	|	LotDetails.VATLocal                                  AS VAT,
	|	LotDetails.SumMan                                 AS CostExcludingVATMan,
	|	LotDetails.VATManag                                   AS VATManag,
	|	VALUE(Enum.LotRecordTypes.AddExpensesForGoods)        AS EntryType
	|//%PutInTempTable
	|FROM
	|	TTPartyDetails AS LotDetails
	|WHERE
	|	&DetailedSpecificationOfBatchesOfGoodsForLBSiUSN2_4
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingGoodsTransferredToVMI),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned),
	|		VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors))
	|	AND &PostInCostAccounting
	|	
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)                     AS RecordType,
	|	0                                                          AS LineNumber,
	|	&Period                                                    AS Period,
	|	&Organization                                               AS Organization,
	|	Goods.ItemsLocationAttributes			   			   AS ItemsLocationAttributes,
	|	Goods.InventoryOwnerAttribute			   				   			   AS InventoryOwnerAttribute,
	|	CASE 
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN &BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse)
	|			OR &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingGoodsTransferredToVMI)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners)
	|		ELSE
	|			CASE WHEN ISNULL(Goods.CostAccountingAnalytics.WarehouseArea.ShopFloorStockroom, FALSE)
	|				THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|				ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|			END
	|	END                                            		   AS AccountingSection,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned)
	|			 AND Goods.ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN Goods.ProductsGroup
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|				THEN &Manager
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|				THEN &Department
	|		ELSE UNDEFINED
	|	END                                                      AS FinancialAccountingDimension,
	|	&Lot                                                    AS Lot,
	|	Goods.LotVendorAttributes                     		   AS LotVendorAttributes,
	|	Goods.VATActivityType                                  AS VATActivityType,
	|	ISNULL(DetailingTotalAmount.DocumentInflow, &Lot) AS DocumentInflow,
	|	Goods.LotVendorAttributes                                AS AnalysisOfReceiptDocumentAccounting,
	|	UNDEFINED                                               AS Products,
	|	UNDEFINED                                               AS Characteristic,
	|	Goods.LineOfBusiness                             AS LineOfBusiness,
	|	DetailingTotalAmount.ExpenseItem					   AS ExpenseItemAssets,
	|	SUM(Goods.Count)								   AS Count,
	|	SUM(Goods.SumCompl - ISNULL(DetailingTotalAmount.SumCompl, 0)) AS CostExcludingVAT,
	|	SUM(Goods.VATLocal - ISNULL(DetailingTotalAmount.VATLocal, 0)) 	AS VAT,
	|	SUM(Goods.SumMan - ISNULL(DetailingTotalAmount.SumMan, 0)) 	AS CostExcludingVATMan,
	|	SUM(Goods.VATManag - ISNULL(DetailingTotalAmount.VATManag, 0)) 		AS VATManag,
	|	VALUE(Enum.LotRecordTypes.Lot)            AS EntryType
	|FROM
	|	TTProducts_1 AS Goods
	|	
	|	LEFT JOIN TTDetailingOfBatchesAmounts AS DetailingTotalAmount
	|	ON Goods.RowID = DetailingTotalAmount.RowID
	|	
	|WHERE
	|	&DetailedSpecificationOfBatchesOfGoodsForLBSiUSN2_4
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5),
	|		VALUE(Enum.BusinessTransactions.EnterRemainingGoodsTransferredToVMI),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned),
	|		VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors))
	|	AND &PostInCostAccounting
	|	
	|GROUP BY
	|	CASE 
	|		WHEN &FIFORollingValuation
	|			THEN &Lot
	|		ELSE UNDEFINED
	|	END,
	|	Goods.ItemsLocationAttributes,
	|	Goods.InventoryOwnerAttribute,
	|	CASE 
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN &BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse)
	|			OR &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingGoodsTransferredToVMI)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners)
	|		ELSE
	|			CASE WHEN ISNULL(Goods.CostAccountingAnalytics.WarehouseArea.ShopFloorStockroom, FALSE)
	|				THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|				ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|			END
	|	END,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned)
	|			 AND Goods.ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN Goods.ProductsGroup
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|				THEN &Manager
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|				THEN &Department
	|		ELSE UNDEFINED
	|	END,
	|	Goods.VATActivityType,
	|	Goods.LotVendorAttributes,
	|	Goods.LineOfBusiness,
	|	ISNULL(DetailingTotalAmount.DocumentInflow, &Lot),
	|	DetailingTotalAmount.ExpenseItem
	|";
	
	If CostCalculationAppliedAlgorithms.FormationOfDocumentTablesWhenCalculatingBatchesAndCosts(Query) Then
		QueryText = StrReplace(QueryText, "//%PutInTempTable", "INTO " + Query.Parameters.NameOfTemporaryBatchTableNDS2_4);
	Else
		QueryText = StrReplace(QueryText, "//%PutInTempTable", "");
		QueryText = QueryText + "
			|	
			|ORDER BY
			|	LineNumber";
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	SeriesTable.Products   AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	SeriesTable.Purpose     AS Purpose,
	|	SeriesTable.Series          AS Series,
	|	SeriesTable.Count     AS Count,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned)
	|			THEN &Department
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5)
	|				OR &BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingGoodsTransferredToVMI)
	|				OR &BusinessOperation = VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5)
	|				OR &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryShippedGoods)
	|			THEN &Partner
	|		ELSE &Warehouse
	|	END                       AS Recipient,
	|	CASE
	|		WHEN &BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5),
	|				VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned)
	|)
	|			THEN UNDEFINED
	|		ELSE &Premise
	|	END                       AS WareroomOfRecipient,
	|	CASE
	|		WHEN &BusinessOperation IN (VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse),
	|								VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting),
	|								VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider),
	|								VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider),
	|								VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse),
	|								VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI))
	|			THEN &Partner
	|		ELSE UNDEFINED
	|	END                       AS Sender,
	|	UNDEFINED                AS WareroomOfSender,
	|	VALUE(Enum.WarehouseTransactions.OBEntry) AS WarehouseOperation,
	|	&Ref                     AS Document,
	|	&Period                     AS Period,
	|	&Ref                     AS Recorder,
	|	TRUE                      AS ThisIsWarehouseRecord
	|FROM
	|	Document.OBEntryGoods.SetOfSeries AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND SeriesTable.Count <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	SeriesTable.Purpose,
	|	SeriesTable.Series,
	|	SeriesTable.Count,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned)
	|			THEN &Department
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5)
	|				OR &BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingGoodsTransferredToVMI)
	|				OR &BusinessOperation = VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5)
	|				OR &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryShippedGoods)
	|			THEN &Partner
	|		ELSE &Warehouse
	|	END,
	|	CASE
	|		WHEN &BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5),
	|				VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned))
	|			THEN UNDEFINED
	|		ELSE &Premise
	|	END,
	|	CASE
	|		WHEN &BusinessOperation IN (VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse),
	|								VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting),
	|								VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider),
	|								VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider),
	|								VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse),
	|								VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI))
	|			THEN &Partner
	|		ELSE UNDEFINED
	|	END        AS Sender,
	|	UNDEFINED AS WareroomOfSender,
	|	VALUE(Enum.WarehouseTransactions.OBEntry),
	|	&Ref,
	|	&Period,
	|	&Ref,
	|	TRUE
	|FROM
	|	Document.OBEntryGoods.Goods AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers)
	
	RegisterName = "LotsOfGoodsOfOrganizations";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTTProducts_1(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	GoodsTable.LineNumber                  AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)     AS RecordType,
	|	&Period                                    AS Period,
	|	&Organization                               AS Organization,
	|	GoodsTable.ItemsLocationAttributes   AS ItemsLocationAttributes,
	|	CASE
	|		WHEN &Lot <> VALUE(Document.SourceDocument.EmptyRef)
	|		THEN &Lot
	|		ELSE &Ref
	|	END                                      AS DocumentInflow,
	|	GoodsTable.InventoryOwnerAttribute                   AS InventoryOwnerAttribute,
	|	GoodsTable.Count                   AS Count,
	|	GoodsTable.LotVendorAttributes         AS LotVendorAttributes,
	|	GoodsTable.Sum                        AS Cost,
	|	GoodsTable.AmountExcludingVAT                  AS CostExcludingVAT,
	|	(CASE &BusinessOperation
	|		WHEN VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|			THEN GoodsTable.SumCompl + GoodsTable.VATLocal
	|		ELSE GoodsTable.SumCompl END) AS LocalCost,
	|	GoodsTable.AmountPermanentDifferences                      AS PermanentDifference,
	|	GoodsTable.AmountTemporaryDifferences                      AS CostTD,
	|	GoodsTable.VATLocal                      AS VATLocal,
	|	GoodsTable.Products                 AS Products,
	|	GoodsTable.Characteristic               AS Characteristic,
	|	GoodsTable.VATActivityType           AS VATTaxation,
	|	VALUE(Enum.BusinessTransactions.GoodsRecordingAsReceived) AS BusinessOperation,
	|	TRUE                                     AS Primary,
	|	UNDEFINED                               AS DocumentSource
	|
	|FROM
	|	TTProducts_1 AS GoodsTable
	|WHERE
	|	&BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse),
	|			VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse),
	|			VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI),
	|			VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors))
	|	AND &PostInCostAccounting
	|	AND &BatchAccountingVersion21
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableLotsOfGoodsTransferredToCommission(Query, QueryTexts, Registers)
	
	RegisterName = "LotsOfGoodsTransferredToCommission";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTTProducts_1(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	Goods.LineNumber                                   AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)               AS RecordType,
	|	&Period                                              AS Period,
	|	&Organization                                         AS Organization,
	|	Goods.ItemsLocationAttributes                    AS ItemsLocationAttributes,
	|	&Ref                                              AS DocumentInflow,
	|	Goods.InventoryOwnerAttribute                                    AS InventoryOwnerAttribute,
	|	Goods.LotVendorAttributes                          AS LotVendorAttributes,
	|	&Ref                                              AS DocumentOfTransferToCommission,
	|	Goods.Count                                    AS Count,
	|	Goods.Sum                                         AS Cost,
	|	Goods.AmountExcludingVAT                                   AS CostExcludingVAT,
	|	Goods.SumCompl                                     AS LocalCost,
	|	Goods.VATLocal                                       AS VATLocal,
	|	Goods.AmountPermanentDifferences                                       AS PermanentDifference,
	|	Goods.AmountTemporaryDifferences                                       AS CostTD,
	|	Goods.Products                                  AS Products,
	|	Goods.Characteristic                                AS Characteristic,
	|	Goods.VATActivityType                            AS VATTaxation
	|FROM
	|	TTProducts_1 AS Goods
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse)
	|	AND &PostInCostAccounting
	|	AND &BatchAccountingVersion21
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableReceivedReturnablePackaging(Query, QueryTexts, Registers)
	
	RegisterName = "ReceivedReturnablePackaging";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTTProducts_1(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	GoodsTable.LineNumber                               AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)                  AS RecordType,
	|	&Period                                                 AS Period,
	|	GoodsTable.Products                              AS Products,
	|	GoodsTable.Characteristic                            AS Characteristic,
	|	GoodsTable.Count                                AS Count,
	|	GoodsTable.Sum                                     AS Sum,
	|	&Partner                                                AS Partner,
	|	UNDEFINED                                            AS DocumentInflow,
	|	GoodsTable.DepositForPackageIsRequired                   AS DepositIsRequired,
	|	GoodsTable.RowID                       AS FinRecordID,
	|	&BusinessTransactionSetting                         AS BusinessTransactionSetting
	|FROM
	|	TTProducts_1 AS GoodsTable
	|WHERE
	|	GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|	AND &RecordInOperationalAccounting
	|	AND &BusinessOperation IN
	|		(VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors))
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTransferredReturnablePackaging(Query, QueryTexts, Registers)
	
	RegisterName = "TransferredReturnablePackaging";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTTProducts_1(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	GoodsTable.LineNumber              AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Count               AS Count,
	|	GoodsTable.QuantityByGBRN         AS QuantityByGBRN,
	|	GoodsTable.Sum                    AS Sum,
	|	&Partner                               AS Partner,
	|	GoodsTable.InventoryOwnerAttribute               AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber                 AS CCDNumber,
	|	GoodsTable.DepositForPackageIsRequired  AS DepositIsRequired,
	|	GoodsTable.RowID      AS FinRecordID,
	|	&BusinessTransactionSetting        AS BusinessTransactionSetting
	|FROM
	|	TTProducts_1 AS GoodsTable
	|WHERE
	|	GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|	AND &RecordInOperationalAccounting
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingSentToCustomers)
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsInStorageBins(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsInStorageBins";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	&ReceivingArea                           AS Cell,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Purpose               AS Purpose,
	|	GoodsTable.Series                    AS Series,
	|	CASE
	|		WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
	|			THEN GoodsTable.Package
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END                                  AS Package,
	|	CASE
	|		WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
	|			THEN GoodsTable.NumberOfPackages
	|		ELSE GoodsTable.Count
	|	END                                  AS InStock
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	(&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryWarehouseBinAddressOfOwnedInventory)
	|			OR &BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse),
	|					VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting),
	|					VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider),
	|					VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider),
	|					VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse),
	|					VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI),
	|					VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors))
	|				AND &ReceivingArea <> VALUE(Catalog.StorageBins.EmptyRef))
	|	AND &RecordInOperationalAccounting
	|	AND NOT GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction


Function QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers)
	
	RegisterName = "MaterialsAndWorksInProduction";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	&Period                                         AS Period,
	|	&Period                                         AS RecorderDate,
	|	&Organization                                    AS Organization,
	|	GoodsTable.Products                      AS Products,
	|	GoodsTable.Characteristic                    AS Characteristic,
	|	GoodsTable.Series	                            AS Series,
	|	GoodsTable.Purpose                        AS Purpose,
	|	&Department                                  AS Department,
	|	VALUE(Enum.BusinessTransactions.TransferToProduction) AS BusinessOperation,
	|	ProductionKeys.DimensionKey                 AS ItemsLocationAttributes,
	|	UNDEFINED                                    AS CostItem,
	|	UNDEFINED                                    AS ProductionOrder,
	|	GoodsTable.Count                        AS Count
	|FROM
	|	TTTableProducts AS GoodsTable
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS ProductionKeys
	|	ON
	|		GoodsTable.Products = ProductionKeys.Products
	|		AND GoodsTable.Characteristic = ProductionKeys.Characteristic
	|		AND GoodsTable.Purpose = ProductionKeys.Purpose
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = ProductionKeys.ProductCostElement
	|		AND (CASE GoodsTable.BatchesIndicationStatus 
	|			WHEN 14 THEN GoodsTable.Series
	|			ELSE VALUE(Catalog.ItemsBatches.EmptyRef) END) = ProductionKeys.Series
	|		AND &Department = ProductionKeys.StorageLocation
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned)
	|	AND &RecordInOperationalAccounting
	|	AND NOT (GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND GoodsTable.Products.TracedGoods)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)              AS RecordType,
	|	&Period                                             AS Period,
	|	&Period                                             AS RecorderDate,
	|	&Organization                                        AS Organization,
	|	GoodsTable.Products                          AS Products,
	|	GoodsTable.Characteristic                        AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	GoodsTable.Purpose                            AS Purpose,
	|	&Department                                      AS Department,
	|	&BusinessOperation                              AS BusinessOperation,
	|	ProductionKeys.DimensionKey                     AS ItemsLocationAttributes,
	|	UNDEFINED                                        AS CostItem,
	|	UNDEFINED                                        AS ProductionOrder,
	|	GoodsTable.Count                            AS Count
	|FROM
	|	TTTableProducts AS GoodsTable
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS ProductionKeys
	|	ON ProductionKeys.Products = GoodsTable.Products
	|	AND ProductionKeys.Characteristic = GoodsTable.Characteristic
	|	AND ProductionKeys.Purpose = GoodsTable.Purpose
	|	AND ProductionKeys.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
	|	AND ProductionKeys.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND ProductionKeys.StorageLocation = &Department
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider)
	|	AND &RecordInOperationalAccounting
	|	AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT GoodsTable.Products.TracedGoods
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableBatchesOfProductionCosts(Query, QueryTexts, Registers)
	
	RegisterName = "BatchesOfProductionCosts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTTProducts_1(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Period AS RecorderDate,
	|	&Organization AS Organization,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.Sum AS Cost,
	|	GoodsTable.AmountExcludingVAT AS CostExcludingVAT,
	|	GoodsTable.LotVendorAttributes AS LotVendorAttributes,
	|	&Ref AS DocumentInflow,
	|	GoodsTable.AmountPermanentDifferences AS PermanentDifference,
	|	GoodsTable.AmountTemporaryDifferences AS CostTD,
	|	GoodsTable.SumCompl AS LocalCost,
	|	GoodsTable.VATLocal AS VATLocal,
	|	GoodsTable.VATActivityType AS VATTaxation
	|FROM
	|	TTProducts_1 AS GoodsTable
	|WHERE
	|	(&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned)
	|			OR FALSE)
	|	AND &PostInCostAccounting
	|	AND NOT &BatchAccountingVersion22
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure SetParametersForCreatingVATBatchRegisters(Query)
	
	If Query.Parameters.Property("DetailedSpecificationOfBatchesOfGoodsForLBSiUSN")
		And Query.Parameters.Property("DetailedSpecificationOfBatchesOfGoodsForLBSiUSN2_4") Then
		Return;
	EndIf;
	
	DetailedSpecificationOfBatchesOfGoodsForLBSiUSN = False;
	
	If CostCalculationAppliedAlgorithms.FormationOfDocumentTablesWhenCalculatingBatchesAndCosts(Query) Then
		DetailedSpecificationOfBatchesOfGoodsForLBSiUSN2_4 = True;
	Else
		
		DetailedSpecificationOfBatchesOfGoodsForLBSiUSN2_4 = False;
		
	EndIf;
	
	Query.SetParameter("DetailedSpecificationOfBatchesOfGoodsForLBSiUSN",    DetailedSpecificationOfBatchesOfGoodsForLBSiUSN);
	Query.SetParameter("DetailedSpecificationOfBatchesOfGoodsForLBSiUSN2_4", DetailedSpecificationOfBatchesOfGoodsForLBSiUSN2_4);
	
EndProcedure

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&MetadataIdentifier AS RefType,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	UNDEFINED AS Partner,
	|	&Warehouse AS StorageLocation,
	|	&Counterparty AS Counterparty,
	|	&Department AS Department,
	|	&Period AS IBDocumentDate,
	|	&Ref AS Ref,
	|	&Number AS IBDocumentNumber,
	|	UNDEFINED AS Status,
	|	&EmployeeResponsible AS EmployeeResponsible,
	|	&Author AS Author,
	|	FALSE AS AdditionalRecord,
	|	UNDEFINED AS More,
	|	CAST(&Comment AS STRING(100)) AS Comment,
	|	&Posted AS Posted,
	|	&DeletionMark AS DeletionMark,
	|	UNDEFINED AS SourceDocumentDate,
	|	UNDEFINED AS SourceDocumentNumber,
	|	CASE
	|		WHEN DocumentData.PostInFinancialAndTaxAccounting
	|			THEN CASE
	|				WHEN DocumentData.RecordInMA
	|				OR DocumentData.PostInCostAccounting
	|					THEN 0
	|				WHEN DocumentData.RecordInOperationalAccounting
	|					THEN SUM(ISNULL(DataOfTabularPartOfGoods.Sum, 0))
	|				ELSE SUM(ISNULL(DataOfTabularPartOfGoods.SumCompl, 0))
	|			END
	|		WHEN DocumentData.RecordInMA
	|		OR DocumentData.PostInCostAccounting
	|			THEN SUM(ISNULL(DataOfTabularPartOfGoods.Sum, 0))
	|		ELSE 0
	|	END AS Sum,
	|	CASE
	|		WHEN DocumentData.PostInFinancialAndTaxAccounting
	|			THEN CASE
	|				WHEN DocumentData.RecordInMA
	|				OR DocumentData.PostInCostAccounting
	|					THEN DocumentData.Organization.LocalAccountingCurrency
	|				WHEN DocumentData.RecordInOperationalAccounting
	|					THEN TableConstantCurrencyOfManagementAccounting.Value
	|				ELSE DocumentData.Organization.LocalAccountingCurrency
	|			END
	|		WHEN DocumentData.RecordInMA
	|		OR DocumentData.PostInCostAccounting
	|			THEN TableConstantCurrencyOfManagementAccounting.Value
	|		ELSE DocumentData.Organization.LocalAccountingCurrency
	|	END AS Currency,
	|	&Contract AS Contract,
	|	&LineOfBusiness AS LineOfBusiness,
	|	&Patch AS ReverseTransactionCorrection,
	|	&ReversedDocument AS ReversedDocument,
	|	&CorrectedDocument AS CorrectedDocument,
	|	&Period AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority
	|FROM
	|	Document.OBEntryGoods AS DocumentData
	|		LEFT JOIN Document.OBEntryGoods.Goods AS DataOfTabularPartOfGoods
	|		ON DocumentData.Ref = DataOfTabularPartOfGoods.Ref
	|		LEFT JOIN Constant.ManagementAccountingCurrency AS TableConstantCurrencyOfManagementAccounting
	|		ON TRUE
	|WHERE
	|	DocumentData.Ref = &Ref
	|GROUP BY
	|	DocumentData.Ref,
	|	CASE
	|		WHEN DocumentData.PostInFinancialAndTaxAccounting
	|			THEN CASE
	|				WHEN DocumentData.RecordInMA
	|				OR DocumentData.PostInCostAccounting
	|					THEN DocumentData.Organization.LocalAccountingCurrency
	|				WHEN DocumentData.RecordInOperationalAccounting
	|					THEN TableConstantCurrencyOfManagementAccounting.Value
	|				ELSE DocumentData.Organization.LocalAccountingCurrency
	|			END
	|		WHEN DocumentData.RecordInMA
	|		OR DocumentData.PostInCostAccounting
	|			THEN TableConstantCurrencyOfManagementAccounting.Value
	|		ELSE DocumentData.Organization.LocalAccountingCurrency
	|	END";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN TabPart.Ref.Department
		|		ELSE TabPart.Ref.Warehouse
		|	END AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.OBEntryGoods.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.BusinessOperation IN(
		|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse),
		|			VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting),
		|			VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider),
		|			VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider),
		|			VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse),
		|			VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI),
		|			VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors))
		|		AND TabPart.Ref.RecordInOperationalAccounting";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
EndProcedure

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	
	If Query <> Undefined Then
		// There are no additional parameters.
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTProducts_1");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTProducts_1(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region ExternalReceipt_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	UNDEFINED			AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.CostAccountingAnalytics 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	CASE WHEN &BatchAccountingVersion22 AND &FIFORollingValuation
	|		THEN DocumentTable.Lot
	|		ELSE UNDEFINED
	|	END                                           AS Lot,
	|	CASE WHEN &BatchAccountingVersion22
	|		THEN TableTypesOfStocks_.VATActivityType
	|		ELSE UNDEFINED
	|	END 											AS VATActivityType,
	|	DocumentTable.VATActivityType				AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes AS LotVendorAttributes,
	|	CASE WHEN &BatchAccountingVersion22 AND NOT &FIFORollingValuation
	|		THEN TableTypesOfStocks_.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END 							AS LotVendorAttributesCorr,
	|	DocumentTable.Partner 		AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate 	AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED 					AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|	CASE WHEN &BatchAccountingVersion22
	|			AND DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse)
	|			AND TableTypesOfStocks_.ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|		THEN TableTypesOfStocks_.ProductsGroup
	|		ELSE UNDEFINED
	|	END 							AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryGoodsCostVariances)
	|		THEN 0
	|		ELSE TableTypesOfStocks_.Count
	|	END AS Count,
	|	TableTypesOfStocks_.RowID 	AS RowID,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider)
	|		THEN TableTypesOfStocks_.AmountExcludingVAT
	|		WHEN DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|			AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI)
	|			AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider)
	|			AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting)
	|			AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryGoodsCostVariances)
	|		THEN TableTypesOfStocks_.Sum
	|		ELSE 0
	|	END 									AS Cost,
	|	CASE WHEN DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryGoodsCostVariances)
	|		THEN TableTypesOfStocks_.AmountExcludingVAT
	|		ELSE 0
	|	END 									AS CostExcludingVAT,
	|	CASE WHEN DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryGoodsCostVariances)
	|		THEN TableTypesOfStocks_.SumCompl
	|		ELSE 0
	|	END 									AS LocalCost,
	|	CASE WHEN DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting)
	|		THEN TableTypesOfStocks_.VATLocal
	|		ELSE 0
	|	END                                   AS VATLocal,
	|	CASE WHEN DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryGoodsCostVariances)
	|		THEN TableTypesOfStocks_.AmountExcludingVAT
	|		ELSE 0
	|	END 									AS CostMan,
	|	CASE 
	|		WHEN DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|		 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI)
	|		 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider)
	|	 	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting)
	|			THEN TableTypesOfStocks_.VATManag 
	|		ELSE 0
	|	END 									AS VATManag,
	|	CASE WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|			THEN TableTypesOfStocks_.Sum
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider)
	|			THEN TableTypesOfStocks_.AmountOffBalance
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider)
	|	 	  OR DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI)
	|	 	  OR DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting)
	|			THEN TableTypesOfStocks_.AmountExcludingVAT
	|			ELSE 0
	|	END 									AS OffBalanceCost,
	|	CASE WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|			THEN TableTypesOfStocks_.SumCompl + TableTypesOfStocks_.VATLocal
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider)
	|			THEN TableTypesOfStocks_.AmountLocalOffBalance
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider)
	|	 	  OR DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI)
	|	 	  OR DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting)
	|			THEN TableTypesOfStocks_.SumCompl
	|			ELSE 0
	|	END 									AS OffBalanceCostLocal,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryGoodsCostVariances)
	|		THEN TableTypesOfStocks_.Sum
	|		ELSE 0
	|	END AS AddExpensesForGoods,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryGoodsCostVariances)
	|		THEN TableTypesOfStocks_.AmountExcludingVAT
	|		ELSE 0
	|	END AS AdditionalExpensesExcludingVAT,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryGoodsCostVariances)
	|		THEN TableTypesOfStocks_.SumCompl
	|		ELSE 0
	|	END AS AddExpensesLocal,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryGoodsCostVariances)
	|		THEN TableTypesOfStocks_.AmountExcludingVAT
	|		ELSE 0
	|	END AS AddExpensesMan,
	|	CASE WHEN DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|		THEN TableTypesOfStocks_.AmountPermanentDifferences
	|		ELSE 0
	|	END 									AS PermanentDifference,
	|	CASE WHEN DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|		THEN TableTypesOfStocks_.AmountTemporaryDifferences
	|		ELSE 0
	|	END 									AS CostTD,
	|	0										AS ProvisionForImpairmentLocal,
	|	0										AS ProvisionForImpairmentMan,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|			 AND DocumentTable.RecordAIT
	|			THEN 
	|				CASE WHEN TableTypesOfStocks_.VATActivityType IN (
	|					VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|					VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|					OR DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|						THEN TableTypesOfStocks_.AITAmount + TableTypesOfStocks_.VATLocal
	|					ELSE TableTypesOfStocks_.AITAmount
	|				END
	|		ELSE 0
	|	END									AS CostOfPersonalIncomeTax,
	|	0										AS CorGrossInitialCostENT,
	|
	// Other fields
	|	CASE WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned)
	|		THEN VALUE(Enum.BusinessTransactions.TransferToProduction)
	|		ELSE VALUE(Enum.BusinessTransactions.GoodsRecordingAsReceived)
	|	END                                    AS BusinessOperation,
	|	TableTypesOfStocks_.RowID   AS FinRecordID,
	|	&BusinessTransactionSetting          AS BusinessTransactionSetting
	|
	|FROM
	|	Document.OBEntryGoods AS DocumentTable
	|	INNER JOIN TTProducts_1 AS TableTypesOfStocks_
	|		ON TRUE
	|	LEFT JOIN Document.SourceDocument AS PrimaryDocuments
	|		ON DocumentTable.Lot = PrimaryDocuments.Ref
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.BusinessOperation IN
	|		(VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse),
	|		 VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse),
	|		 VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned),
	|		 VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse),
	|		 VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider),
	|		 VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider),
	|		 VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting),
	|		 VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5),
	|		 VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors),
	|		 VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5),
	|		 VALUE(Enum.BusinessTransactions.EnterRemainingGoodsTransferredToVMI),
	|		 VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI),
	|		 VALUE(Enum.BusinessTransactions.OBEntryShippedGoods),
	|		 VALUE(Enum.BusinessTransactions.OBEntryGoodsCostVariances))
	|	AND &PostInCostAccounting
	|	AND CASE WHEN &BatchAccountingVersion22 AND &FIFORollingValuation
	|		THEN ISNULL(PrimaryDocuments.SourceDocumentType, UNDEFINED) IN (
	|				VALUE(Enum.SourceDocumentTypes.PurchaseFromVendor),
	|				VALUE(Enum.SourceDocumentTypes.VMIProcurement))
	|		ELSE TRUE
	|	END";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion
	
	#Region ExternalInput_ImpairmentOfGoods
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	UNDEFINED			AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.CostAccountingAnalytics 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	CASE WHEN &BatchAccountingVersion22 AND &FIFORollingValuation
	|		THEN DocumentTable.Lot
	|		ELSE UNDEFINED
	|	END                                           AS Lot,
	|	CASE WHEN &BatchAccountingVersion22
	|		THEN TableTypesOfStocks_.VATActivityType
	|		ELSE UNDEFINED
	|	END 											AS VATActivityType,
	|	DocumentTable.VATActivityType				AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes AS LotVendorAttributes,
	|	CASE WHEN &BatchAccountingVersion22 AND NOT &FIFORollingValuation
	|		THEN TableTypesOfStocks_.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END 									AS LotVendorAttributesCorr,
	|	DocumentTable.Partner 		AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate 	AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED 					AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	0										AS Count,
	|	TableTypesOfStocks_.RowID	AS RowID,
	|	0										AS Cost,
	|	0										AS CostExcludingVAT,
	|	0										AS LocalCost,
	|	0										AS VATLocal,
	|	0										AS CostMan,
	|	0										AS VATManag,
	|	0										AS OffBalanceCost,
	|	0										AS OffBalanceCostLocal,
	|	0										AS AddExpensesForGoods,
	|	0										AS AdditionalExpensesExcludingVAT,
	|	0										AS AddExpensesLocal,
	|	0										AS AddExpensesMan,
	|	0										AS PermanentDifference,
	|	0										AS CostTD,
	|	TableTypesOfStocks_.ProvisionForImpairmentLocal	AS ProvisionForImpairmentLocal,
	|	TableTypesOfStocks_.ProvisionForImpairmentMan	AS ProvisionForImpairmentMan,
	|	0										AS CostOfPersonalIncomeTax,
	|	0										AS CorGrossInitialCostENT,
	|
	// Other fields
	|	CASE WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned)
	|		THEN VALUE(Enum.BusinessTransactions.TransferToProduction)
	|		ELSE VALUE(Enum.BusinessTransactions.GoodsRecordingAsReceived)
	|	END                                    AS BusinessOperation,
	|	TableTypesOfStocks_.RowID   AS FinRecordID,
	|	CASE
	|		WHEN &BusinessOperation IN (VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse),
	|										VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.OBEntryImpairmentOfGoodsTransferredToCommissionAgent)
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.OBEntryImpairmentOfMaterialsTransferredToProduction)
	|		WHEN &BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.OBEntryImpairmentOfMaterialsTransferredToToller)
	|		WHEN &BusinessOperation =
	|				VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.EnterRemainingManufacturedProductsOfProvider)
	|		WHEN &BusinessOperation =
	|				VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.EnterRemainingSemiFinishedProductsOfProvider)
	|		WHEN &BusinessOperation =
	|				VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.EnterRemainingMaterialsReceivedForSubcontracting)
	|		WHEN &BusinessOperation =
	|				VALUE(Enum.BusinessTransactions.EnterRemainingGoodsTransferredToVMI)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.EnterBalanceOfImpairmentOfGoodsTransferredToVMI)
	|		ELSE
	|			VALUE(Catalog.BusinessTransactionsSettings.OBEntryImpairmentOfOwnGoods)
	|	END                                    AS BusinessTransactionSetting
	|
	|FROM
	|	Document.OBEntryGoods AS DocumentTable
	|	INNER JOIN TTProducts_1 AS TableTypesOfStocks_
	|		ON TRUE
	|	LEFT JOIN Document.SourceDocument AS PrimaryDocuments
	|		ON DocumentTable.Lot = PrimaryDocuments.Ref
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.BusinessOperation IN
	|		(VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse),
	|		 VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse),
	|		 VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors),
	|		 VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned),
	|		 VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider),
	|		 VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider),
	|		 VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting),
	|		 VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5),
	|		 VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors),
	|		 VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5),
	|		 VALUE(Enum.BusinessTransactions.EnterRemainingGoodsTransferredToVMI))
	|	AND (TableTypesOfStocks_.ProvisionForImpairmentLocal <> 0 OR TableTypesOfStocks_.ProvisionForImpairmentMan <> 0)
	|	AND &PostInCostAccounting
	|	AND CASE WHEN &BatchAccountingVersion22 AND &FIFORollingValuation
	|		THEN ISNULL(PrimaryDocuments.SourceDocumentType, UNDEFINED) IN (
	|				VALUE(Enum.SourceDocumentTypes.PurchaseFromVendor),
	|				VALUE(Enum.SourceDocumentTypes.VMIProcurement))
	|		ELSE TRUE
	|	END";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion

	#Region InternalReceipt_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	UNDEFINED			AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.CostAccountingAnalytics 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	CASE WHEN &BatchAccountingVersion22 AND &FIFORollingValuation
	|		THEN DocumentTable.Lot
	|		ELSE UNDEFINED
	|	END                                           AS Lot,
	|	CASE WHEN &BatchAccountingVersion22
	|		THEN TableTypesOfStocks_.VATActivityType
	|		ELSE UNDEFINED
	|	END 											AS VATActivityType,
	|	DocumentTable.VATActivityType				AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes AS LotVendorAttributes,
	|	CASE WHEN &BatchAccountingVersion22 AND NOT &FIFORollingValuation
	|		THEN TableTypesOfStocks_.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END 									AS LotVendorAttributesCorr,
	|	0 										AS RowCode,
	|
	// Corresponding fields
	|	UNDEFINED						AS CorItemsLocationAttributes,
	|	UNDEFINED						AS CorInventoryOwnerAttribute,
	|	UNDEFINED						AS CorGroupOfManufacturedProducts,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED 						AS SalesOpportunity,
	|	DocumentTable.Department 		AS Department,
	|	DocumentTable.Manager 			AS Manager,
	|	TableTypesOfStocks_.ProductsGroup 	AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryGoodsCostVariances)
	|		THEN 0
	|		ELSE TableTypesOfStocks_.Count
	|	END AS Count,
	|	TableTypesOfStocks_.RowID 	AS RowID,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider)
	|		THEN TableTypesOfStocks_.AmountExcludingVAT
	|		WHEN DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|			AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI)
	|			AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider)
	|			AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting)
	|	 		AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryGoodsCostVariances)
	|		THEN TableTypesOfStocks_.Sum
	|		ELSE 0
	|	END 									AS Cost,
	|	CASE WHEN DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryGoodsCostVariances)
	|		THEN TableTypesOfStocks_.AmountExcludingVAT
	|		ELSE 0
	|	END 									AS CostExcludingVAT,
	|	CASE WHEN DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryGoodsCostVariances)
	|		THEN TableTypesOfStocks_.SumCompl
	|		ELSE 0
	|	END 									AS LocalCost,
	|	CASE WHEN DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting)
	|		THEN TableTypesOfStocks_.VATLocal
	|		ELSE 0
	|	END                                   AS VATLocal,
	|	CASE WHEN DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting)
	|	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryGoodsCostVariances)
	|		THEN TableTypesOfStocks_.AmountExcludingVAT
	|		ELSE 0
	|	END 									AS CostMan,
	|	CASE 
	|		WHEN DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|		 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI)
	|		 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider)
	|	 	 AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting)
	|			THEN TableTypesOfStocks_.VATManag 
	|		ELSE 0
	|	END 									AS VATManag,
	|	CASE WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|			THEN TableTypesOfStocks_.Sum
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider)
	|			THEN TableTypesOfStocks_.AmountOffBalance
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider)
	|	 	  OR DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI)
	|	 	  OR DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting)
	|			THEN TableTypesOfStocks_.AmountExcludingVAT
	|			ELSE 0
	|	END 									AS OffBalanceCost,
	|	CASE WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|			THEN TableTypesOfStocks_.SumCompl + TableTypesOfStocks_.VATLocal
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider)
	|			THEN TableTypesOfStocks_.AmountLocalOffBalance
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider)
	|	 	  OR DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI)
	|	 	  OR DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting)
	|			THEN TableTypesOfStocks_.SumCompl
	|			ELSE 0
	|	END 									AS OffBalanceCostLocal,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryGoodsCostVariances)
	|		THEN TableTypesOfStocks_.Sum
	|		ELSE 0
	|	END AS AddExpensesForGoods,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryGoodsCostVariances)
	|		THEN TableTypesOfStocks_.AmountExcludingVAT
	|		ELSE 0
	|	END AS AdditionalExpensesExcludingVAT,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryGoodsCostVariances)
	|		THEN TableTypesOfStocks_.SumCompl
	|		ELSE 0
	|	END AS AddExpensesLocal,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryGoodsCostVariances)
	|		THEN TableTypesOfStocks_.AmountExcludingVAT
	|		ELSE 0
	|	END AS AddExpensesMan,
	|	CASE WHEN DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|		THEN TableTypesOfStocks_.AmountPermanentDifferences
	|		ELSE 0
	|	END 									AS PermanentDifference,
	|	CASE WHEN DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|		THEN TableTypesOfStocks_.AmountTemporaryDifferences
	|		ELSE 0
	|	END 									AS CostTD,
	|	0										AS ProvisionForImpairmentLocal,
	|	0										AS ProvisionForImpairmentMan,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|			 AND DocumentTable.RecordAIT
	|			THEN 
	|				CASE WHEN TableTypesOfStocks_.VATActivityType IN (
	|					VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|					VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|					OR DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse)
	|						THEN TableTypesOfStocks_.AITAmount + TableTypesOfStocks_.VATLocal
	|					ELSE TableTypesOfStocks_.AITAmount
	|				END
	|		ELSE 0
	|	END									AS CostOfPersonalIncomeTax,
	|	0										AS CorGrossInitialCostENT,
	|
	// Other fields
	|	CASE WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned)
	|		THEN VALUE(Enum.BusinessTransactions.TransferToProduction)
	|		ELSE VALUE(Enum.BusinessTransactions.GoodsRecordingAsReceived)
	|	END                                    AS BusinessOperation,
	|	TableTypesOfStocks_.RowID   AS FinRecordID,
	|	&BusinessTransactionSetting          AS BusinessTransactionSetting
	|
	|FROM
	|	Document.OBEntryGoods AS DocumentTable
	|	INNER JOIN TTProducts_1 AS TableTypesOfStocks_
	|		ON TRUE
	|	LEFT JOIN Document.SourceDocument AS PrimaryDocuments
	|		ON DocumentTable.Lot = PrimaryDocuments.Ref
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.BusinessOperation IN
	|		(VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse),
	|		 VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse),
	|		 VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned),
	|		 VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse),
	|		 VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider),
	|		 VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider),
	|		 VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting),
	|		 VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5),
	|		 VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors),
	|		 VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5),
	|		 VALUE(Enum.BusinessTransactions.EnterRemainingGoodsTransferredToVMI),
	|		 VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI),
	|		 VALUE(Enum.BusinessTransactions.OBEntryShippedGoods),
	|		 VALUE(Enum.BusinessTransactions.OBEntryGoodsCostVariances))
	|	AND &PostInCostAccounting
	|	AND NOT CASE WHEN &BatchAccountingVersion22 AND &FIFORollingValuation
	|		THEN ISNULL(PrimaryDocuments.SourceDocumentType, UNDEFINED) IN (
	|				VALUE(Enum.SourceDocumentTypes.PurchaseFromVendor),
	|				VALUE(Enum.SourceDocumentTypes.VMIProcurement))
	|		ELSE TRUE
	|	END";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.InternalReceipt,
		QueryText);
	
	#EndRegion

	#Region InternalReceipt_ImpairmentOfGoods
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	UNDEFINED			AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.CostAccountingAnalytics 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	CASE WHEN &BatchAccountingVersion22 AND &FIFORollingValuation
	|		THEN DocumentTable.Lot
	|		ELSE UNDEFINED
	|	END                                           AS Lot,
	|	CASE WHEN &BatchAccountingVersion22
	|		THEN TableTypesOfStocks_.VATActivityType
	|		ELSE UNDEFINED
	|	END 											AS VATActivityType,
	|	DocumentTable.VATActivityType				AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes AS LotVendorAttributes,
	|	CASE WHEN &BatchAccountingVersion22 AND NOT &FIFORollingValuation
	|		THEN TableTypesOfStocks_.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END 									AS LotVendorAttributesCorr,
	|	0 										AS RowCode,
	|
	// Corresponding fields
	|	UNDEFINED						AS CorItemsLocationAttributes,
	|	UNDEFINED						AS CorInventoryOwnerAttribute,
	|	UNDEFINED						AS CorGroupOfManufacturedProducts,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED 						AS SalesOpportunity,
	|	DocumentTable.Department 		AS Department,
	|	DocumentTable.Manager 			AS Manager,
	|	TableTypesOfStocks_.ProductsGroup 	AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	0										AS Count,
	|	TableTypesOfStocks_.RowID	AS RowID,
	|	0										AS Cost,
	|	0										AS CostExcludingVAT,
	|	0										AS LocalCost,
	|	0										AS VATLocal,
	|	0										AS CostMan,
	|	0										AS VATManag,
	|	0										AS OffBalanceCost,
	|	0										AS OffBalanceCostLocal,
	|	0										AS AddExpensesForGoods,
	|	0										AS AdditionalExpensesExcludingVAT,
	|	0										AS AddExpensesLocal,
	|	0										AS AddExpensesMan,
	|	0										AS PermanentDifference,
	|	0										AS CostTD,
	|	TableTypesOfStocks_.ProvisionForImpairmentLocal	AS ProvisionForImpairmentLocal,
	|	TableTypesOfStocks_.ProvisionForImpairmentMan	AS ProvisionForImpairmentMan,
	|	0										AS CostOfPersonalIncomeTax,
	|	0										AS CorGrossInitialCostENT,
	|
	// Other fields
	|	CASE WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned)
	|		THEN VALUE(Enum.BusinessTransactions.TransferToProduction)
	|		ELSE VALUE(Enum.BusinessTransactions.GoodsRecordingAsReceived)
	|	END                                    AS BusinessOperation,
	|	TableTypesOfStocks_.RowID   AS FinRecordID,
	|	CASE
	|		WHEN &BusinessOperation IN (VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse),
	|										VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.OBEntryImpairmentOfGoodsTransferredToCommissionAgent)
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.OBEntryImpairmentOfMaterialsTransferredToProduction)
	|		WHEN &BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.OBEntryImpairmentOfMaterialsTransferredToToller)
	|		WHEN &BusinessOperation =
	|				VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.EnterRemainingManufacturedProductsOfProvider)
	|		WHEN &BusinessOperation =
	|				VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.EnterRemainingSemiFinishedProductsOfProvider)
	|		WHEN &BusinessOperation =
	|				VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.EnterRemainingMaterialsReceivedForSubcontracting)
	|		WHEN &BusinessOperation =
	|				VALUE(Enum.BusinessTransactions.EnterRemainingGoodsTransferredToVMI)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.EnterBalanceOfImpairmentOfGoodsTransferredToVMI)
	|		ELSE
	|			VALUE(Catalog.BusinessTransactionsSettings.OBEntryImpairmentOfOwnGoods)
	|	END                                    AS BusinessTransactionSetting
	|
	|FROM
	|	Document.OBEntryGoods AS DocumentTable
	|	INNER JOIN TTProducts_1 AS TableTypesOfStocks_
	|		ON TRUE
	|	LEFT JOIN Document.SourceDocument AS PrimaryDocuments
	|		ON DocumentTable.Lot = PrimaryDocuments.Ref
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.BusinessOperation IN
	|		(VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse),
	|		 VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse),
	|		 VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors),
	|		 VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned),
	|		 VALUE(Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider),
	|		 VALUE(Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider),
	|		 VALUE(Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting),
	|		 VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5),
	|		 VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors),
	|		 VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5),
	|		 VALUE(Enum.BusinessTransactions.EnterRemainingGoodsTransferredToVMI))
	|	AND (TableTypesOfStocks_.ProvisionForImpairmentLocal <> 0 OR TableTypesOfStocks_.ProvisionForImpairmentMan <> 0)
	|	AND &PostInCostAccounting
	|	AND NOT CASE WHEN &BatchAccountingVersion22 AND &FIFORollingValuation
	|		THEN ISNULL(PrimaryDocuments.SourceDocumentType, UNDEFINED) IN (
	|				VALUE(Enum.SourceDocumentTypes.PurchaseFromVendor),
	|				VALUE(Enum.SourceDocumentTypes.VMIProcurement))
	|		ELSE TRUE
	|	END";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.InternalReceipt,
		QueryText);
	
	#EndRegion

	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

#EndRegion

#Region Other

// Determines the visibility of the form group that contains the accounting types checkboxes.
// Used in forms where all types of accounting are available.
//
// Parameters:
//  Object - DocumentObject.OBEntryGoods - A document for which it is necessary to calculate the group display
//
// Returns:
//	 Boolean - A flag that signals whether or not to show the group on the form
// 
Function VisibilityOfAccountingGroups(Object) Export
	
	VisibilityOfAccountingGroups = GetFunctionalOption("UseLocal")
		Or CalculationOfCostCached.GenerateRegisteredRecordsOnCostRegisters(BegOfMonth(Object.Date), True);
	
	Return VisibilityOfAccountingGroups;
	
EndFunction

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection:
//     of Table elements<Register Name> - Assignment tables - a table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If TypeOf(Document) = Type("DocumentObject.OBEntryGoods") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// Create a motion initialization request
	
	Query = New Query;
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTexts = New ValueList;
		QueryTextTableProductStock(Query, QueryTexts, Registers);
		QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers);
		QueryTextTableDatesOfConsignmentGoodsTransfer(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableShipmentReferences(Query, QueryTexts, Registers);
		QueryTextTableGoodsTransferredToCommissionAgent(Query, QueryTexts, Registers);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers);
		QueryTextTableLotsOfGoodsTransferredToCommission(Query, QueryTexts, Registers);
		QueryTextTableReceivedReturnablePackaging(Query, QueryTexts, Registers);
		QueryTextTableTransferredReturnablePackaging(Query, QueryTexts, Registers);
		QueryTextTableGoodsInStorageBins(Query, QueryTexts, Registers);
		QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers);
		QueryTextTableBatchesOfProductionCosts(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		ReflectVATInAccounting_(Query, QueryTexts, Registers);
		
		OBEntryLocalization.EnteringProductBalancesAddRequestTexts(Query, QueryTexts, Registers);
	
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

// Returns whether the Contract must be filled in in the object.
//
// Parameters:
//  Object - DocumentObject.OBEntryGoods - A document for which it is necessary to calculate
//  the obligation to fill out the Contract.
//
// Returns:
//  Boolean - Indicates whether the Contract must be completed.
//
Function ContractMustBeCompleted(Object) Export
	
	ContractMustBeCompleted = True;
	
	BusinessOperation = Object.BusinessOperation;
	TermsOfConsignmentPurchase = Object.TermsOfConsignmentPurchase;
	BusinessTransactions = Enums.BusinessTransactions;
	AttributeName = "ContractsAreUsed";
	
	If BusinessOperation <> BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5
		And BusinessOperation <> BusinessTransactions.EnterRemainingGoodsTransferredToVMI
		And (Not Object.RecordInOperationalAccounting
			And Not Object.PostInCostAccounting
			Or Not BusinessOperation = BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5)
	 	And BusinessOperation <> BusinessTransactions.EnterRemainingReceivedVMI
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryShippedGoods
		And Not (BusinessOperation = BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
			And ValueIsFilled(TermsOfConsignmentPurchase)
				And TMCommonUse.ValueOfBooleanObjectSProps(TermsOfConsignmentPurchase, AttributeName)) Then
		ContractMustBeCompleted = False;
	EndIf;
	
	Return ContractMustBeCompleted;
	
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	// Assignment for the placement of goods
	PrintCommand = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands,
																							"PlacementJob");
	
	DocumentOperations = New Array;
	DocumentOperations.Add(Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse);
	DocumentOperations.Add(Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse);
	DocumentOperations.Add(Enums.BusinessTransactions.EnterRemainingReceivedVMI);
	DocumentOperations.Add(Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors);
	DocumentOperations.Add(Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting);
	DocumentOperations.Add(Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider);
	DocumentOperations.Add(Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider);
	AttachableCommands.AddCommandVisibilityCondition(PrintCommand,
														"BusinessOperation",
														DocumentOperations,
														ComparisonType.InList);
	
	OBEntryLocalization.EnteringProductBalancesAddPrintCommands(PrintCommands);
	
EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray  - Array    - references to objects that should be printed;
//  PrintParameters - Structure - advanced print settings;
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects         - ValueList  - value - the object reference;
//                                            view - name of the area where the object was output (output parameter);
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export

EndProcedure

#EndRegion

#Region SetOfSeries

Function TextOfRequestToFillInStatusesForSpecifyingSerialNumbers_(SeriesSpecificationParameters)

	If SeriesSpecificationParameters.LinkFields.Find("Package") <> Undefined Then
		QueryText = 
		"SELECT
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Purpose,
		|	Goods.Package AS Package,
		|	Goods.Series,
		|	Goods.NumberOfPackages AS Count,
		|	Goods.LineNumber,
		|	Goods.BatchesIndicationStatus
		|INTO Goods
		|FROM
		|	&Goods AS Goods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SetOfSeries.Products,
		|	SetOfSeries.Characteristic,
		|	SetOfSeries.Purpose,
		|	SetOfSeries.Package AS Package,
		|	SetOfSeries.NumberOfPackages AS Count
		|INTO SetOfSeries
		|FROM
		|	&SetOfSeries AS SetOfSeries";
	Else
		QueryText = 
		"SELECT
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Purpose,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
		|	Goods.Series,
		|	Goods.Count,
		|	Goods.LineNumber,
		|	Goods.BatchesIndicationStatus
		|INTO Goods
		|FROM
		|	&Goods AS Goods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SetOfSeries.Products,
		|	SetOfSeries.Characteristic,
		|	SetOfSeries.Purpose,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
		|	SetOfSeries.Count
		|INTO SetOfSeries
		|FROM
		|	&SetOfSeries AS SetOfSeries";
	EndIf;	
	
	QueryText = QueryText + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	QueryText = QueryText + 
	"SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Package,
	|	SUM(Goods.Count) AS Count,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Package,
	|	Goods.Characteristic,
	|	Goods.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.Package,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Products,
	|	SetOfSeries.Package,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS StatusOfSpecifyingSeriesIsOld,
	|	CASE
	|		WHEN NOT BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|						THEN CASE
	|								WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|									THEN 14
	|								ELSE 13
	|							END
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 10
	|								ELSE 9
	|							END
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 8
	|								ELSE 7
	|							END
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult
	|							AND BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 4
	|								ELSE 3
	|							END
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.PolicyType = VALUE(Enum.TypesOfBatchSpecificationPolicies.FEFOAutoCalculationOfRemainingBatch)
	|						AND NOT &OnlySeriesTakingIntoAccountLeftovers
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 2
	|								ELSE 1
	|							END
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.PolicyType = VALUE(Enum.TypesOfBatchSpecificationPolicies.ReferenceBatchSpecification)
	|						AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceivingByOtherRecordingAsReceived
	|						AND NOT &OnlySeriesTakingIntoAccountLeftovers
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 2
	|								ELSE 1
	|							END
	|					ELSE 0
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|			LEFT JOIN SeriesToRequest AS SeriesToRequest
	|			ON ProductsToRequest.Products = SeriesToRequest.Products
	|				AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|				AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
	|				AND ProductsToRequest.Package = SeriesToRequest.Package
	|			LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|				INNER JOIN Catalog.Warehouses AS Warehouses
	|				ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|			ON (BatchAccountingPolicies.Warehouse = &Warehouse)
	|				AND ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|			AND Goods.Package = ProductsToRequest.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StatusTable.LineNumber AS LineNumber,
	|	StatusTable.BatchesIndicationStatus
	|FROM
	|	Statuses AS StatusTable
	|WHERE
	|	StatusTable.StatusOfSpecifyingSeriesIsOld <> StatusTable.BatchesIndicationStatus
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;

EndFunction

Function TextOfRequestToFillInStatusesForSpecifyingSerialNumbers()

	QueryText = 
	"SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|	Goods.Series,
	|	Goods.Count,
	|	Goods.LineNumber,
	|	Goods.BatchesIndicationStatus
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|	SetOfSeries.Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Package,
	|	SUM(Goods.Count) AS Count,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Package,
	|	Goods.Characteristic,
	|	Goods.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.Package,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Products,
	|	SetOfSeries.Package,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS StatusOfSpecifyingSeriesIsOld,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|								AND ProductsToRequest.Count > 0
	|						THEN 10
	|					ELSE 9
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenReceivingMaterials
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|								AND ProductsToRequest.Count > 0
	|							OR Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN CASE
	|								WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|									THEN 4
	|								ELSE 2
	|							END
	|					ELSE CASE
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|								THEN 3
	|							ELSE 1
	|						END
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|			LEFT JOIN SeriesToRequest AS SeriesToRequest
	|			ON ProductsToRequest.Products = SeriesToRequest.Products
	|				AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|				AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
	|				AND ProductsToRequest.Package = SeriesToRequest.Package
	|			LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|			ON (BatchAccountingPolicies.Warehouse = &Warehouse)
	|				AND ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|			AND Goods.Package = ProductsToRequest.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StatusTable.LineNumber AS LineNumber,
	|	StatusTable.BatchesIndicationStatus
	|FROM
	|	Statuses AS StatusTable
	|WHERE
	|	StatusTable.StatusOfSpecifyingSeriesIsOld <> StatusTable.BatchesIndicationStatus
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;

EndFunction

Function QueryTextOfFillingInStatusesOfIndicatingSeriesIsSubcontractingAndForCommission()

	QueryText = 
	"SELECT
	|	Goods.LineNumber         AS LineNumber,
	|	Goods.Products        AS Products,
	|	Goods.Characteristic      AS Characteristic,
	|	Goods.Purpose          AS Purpose,
	|	Goods.Series               AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.Count          AS Count
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	Goods.Products      AS Products,
	|	Goods.Characteristic    AS Characteristic,
	|	Goods.Purpose        AS Purpose,
	|	Goods.Series             AS Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind,
	|	SUM(Goods.Count) AS Count
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	Goods.LineNumber         AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		ELSE
	|			CASE
	|				WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches
	|					THEN
	|						CASE
	|							WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5)
	|										AND ProductsToRequest.ProductKind.BatchAccountingPolicy.AccountingOfBatchesInGoodsTransferredToCommissionAgent
	|									OR &BusinessOperation = VALUE(Enum.BusinessTransactions.EnterRemainingGoodsTransferredToVMI)
	|										AND ProductsToRequest.ProductKind.BatchAccountingPolicy.BatchesAccountingInDepositedGoods
	|									OR ProductsToRequest.ProductKind.BatchAccountingPolicy.SeriesAccountingOfGoodsTransferredToSubcontractor
	|										AND &BusinessOperation = VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5)
	|									OR ProductsToRequest.ProductKind.BatchAccountingPolicy.AccountingForGoodsBatchesShippedToCustomer
	|										AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryShippedGoods)
	|								THEN
	|									CASE
	|										WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|											THEN 18
	|										ELSE 17
	|									END
	|								ELSE 0
	|						END
	|					ELSE 0
	|			END
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT
	|	Statuses.LineNumber         AS LineNumber,
	|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;

EndFunction

#EndRegion

#Region ServiceProceduresForFillingInAccordingToOperationalAccountingData

#EndRegion

#EndRegion

#EndIf
