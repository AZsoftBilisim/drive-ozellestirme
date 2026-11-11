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
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	CreateBasedOnCommand = DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(
									GenerationCommands);
	
	If CreateBasedOnCommand <> Undefined Then
		DocumentOperations = New Array;
		DocumentOperations.Add(Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse);
		DocumentOperations.Add(Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse);
		DocumentOperations.Add(Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors);
		
		AttachableCommands.AddCommandVisibilityCondition(CreateBasedOnCommand,
															"BusinessOperation",
															DocumentOperations,
															ComparisonType.InList);
	EndIf;
	
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
	OBEntryLocalization.EnteringBalancesAddReportCommands(ReportsCommands, Parameters);
EndProcedure

#EndRegion

#Region SetOfSeries

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
	SeriesSpecificationParameters.FullObjectName = "Document.OBEntry";
	
	If Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned Then
		WarehouseSeriesParameters = WarehousesServer.UsingSeriesInDivision(Object.Department);
		SeriesSpecificationParameters.WarehouseFieldName = "Department";
	Else
		WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	EndIf; 
	
	RequiredOperation = Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryWarehouseBinAddressOfOwnedInventory 
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryWareroomAddressOfOwnedInventory;
	
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch And RequiredOperation;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches And RequiredOperation;
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.OBEntry);
	SeriesSpecificationParameters.SeriesWhenPlanningShipmentVHFSeriesAreIndicated = True;
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	
	SeriesSpecificationParameters.ThisIsAnInvoice     = True;
	SeriesSpecificationParameters.Date             = Object.Date;
	SeriesSpecificationParameters.FieldNameRoom = "Premise";
	
	If Object.BusinessOperation = Enums.BusinessTransactions.OBEntryWarehouseBinAddressOfOwnedInventory
		Or ((Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse
				Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
				Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors)
			And WarehousesServer.UseBinLocationWarehousing(Object.Warehouse, Object.Premise, Object.Date)) Then 
			
		SeriesSpecificationParameters.UseBinLocationWarehousing = True;
		SeriesSpecificationParameters.LinkFields.Add("Package");
		SeriesSpecificationParameters.FieldNameQuantity = "NumberOfPackages";
		
	EndIf;
	
	SeriesSpecificationParameters.OnlySeriesTakingIntoAccountLeftovers = Object.BusinessOperation = Enums.BusinessTransactions.OBEntryWarehouseBinAddressOfOwnedInventory 
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryWareroomAddressOfOwnedInventory;
	
	Return SeriesSpecificationParameters;
	
EndFunction

// The procedure fills in the statuses for specifying series in the PM goods lines
//
// Parameters:
//  SeriesSpecificationParameters - Structure - structure of parameters for specifying series returned by the appropriate procedure of the document Manager module (processing)
//
// Returns:
//	String - The text of the request to fill in statuses.
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	If SeriesSpecificationParameters.WarehouseFieldName = "Department" Then
		Return TextOfRequestToFillInStatusesForSpecifyingSerialNumbers();
	Else
		Return TextOfRequestToFillInStatusesForSpecifyingSerialNumbers_(SeriesSpecificationParameters);
	EndIf;
	
EndFunction

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


#Region InterfaceImplementation

//
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
	|	)AND( ValueAllowed(CompanyRecipient)
	|	OR CompanyRecipient = VALUE(Catalog.Companies.EmptyRef)
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
#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query                       = New Query;
	QueryTexts                = New ValueList();
	
	FullDocumentName = "Document.OBEntry"; 
	RequestHasSource = False;
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID(Metadata.Documents.OBEntry));
	
	RedefiningParameterCalculation = New Structure;
	
	If RegisterName = "GoodsInStorageBins" Then
		
		QueryText = QueryTextTableGoodsInStorageBins(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "GoodsTable";
		
	ElsIf RegisterName = "StockAllocationRecords" Then
		
		QueryTexts = New ValueList();
		SynonymForDocumentTable = "TabPart";
		ReflectStockDistribution(Query, QueryTexts, RegisterName);
		QueryText = StrConcat(QueryTexts.UnloadValues(), TMCommonUse.QuerySeparatorInJoin());
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		RequestHasSource = True;
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName%belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
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
	Result.QueryText       = QueryText;
	Result.ParameterValues = ParameterValues;
	
	Return Result;
	
EndFunction

Function QueryTextTTTableProducts(Query, QueryTexts)
	
	RegisterName = "TTTableProducts";
	
	QueryText =
	"SELECT
	|	GoodsTable.Products        AS Products,
	|	GoodsTable.Characteristic      AS Characteristic,
	|	GoodsTable.Purpose             AS Purpose,
	|	GoodsTable.Package            AS Package,
	|	GoodsTable.Count          AS Count,
	|	GoodsTable.NumberOfPackages  AS NumberOfPackages,
	|	GoodsTable.Series               AS Series,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus
	|INTO TTTableProducts
	|FROM
	|	Document.OBEntry.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors),
	|		VALUE(Enum.BusinessTransactions.OBEntryWarehouseBinAddressOfOwnedInventory),
	|		VALUE(Enum.BusinessTransactions.OBEntryWareroomAddressOfOwnedInventory),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned))
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
	|	Document.OBEntry.SetOfSeries AS SeriesTable
	|		INNER JOIN Document.OBEntry.Goods AS GoodsTable
	|		ON SeriesTable.Ref = GoodsTable.Ref
	|			AND SeriesTable.Products = GoodsTable.Products
	|			AND SeriesTable.Characteristic = GoodsTable.Characteristic
	|			AND SeriesTable.Purpose = GoodsTable.Purpose
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors),
	|		VALUE(Enum.BusinessTransactions.OBEntryWarehouseBinAddressOfOwnedInventory),
	|		VALUE(Enum.BusinessTransactions.OBEntryWareroomAddressOfOwnedInventory),
	|		VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned))
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
	|			OR &BusinessOperation IN (VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse), VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse), VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors))
	|				AND &ReceivingArea <> VALUE(Catalog.StorageBins.EmptyRef))
	|	AND &RecordInOperationalAccounting";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction


Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "SELECT
	|	&MetadataIdentifier AS RefType,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS StorageLocation,
	|	UNDEFINED AS Counterparty,
	|	&Department AS Department,
	|	&Period AS IBDocumentDate,
	|	&Ref AS Ref,
	|	&Number AS IBDocumentNumber,
	|	UNDEFINED AS Status,
	|	&EmployeeResponsible AS EmployeeResponsible,
	|	&Author AS Author,
	|	FALSE AS AdditionalRecord,
	|	UNDEFINED AS More,
	|	&Posted AS Posted,
	|	&DeletionMark AS DeletionMark,
	|	UNDEFINED AS SourceDocumentDate,
	|	UNDEFINED AS SourceDocumentNumber,
	|	&Currency AS Currency,
	|	&Contract AS Contract,
	|	&LineOfBusiness AS LineOfBusiness,
	|	&Period AS RecordingInAccountingDate,
	|	&Patch AS ReverseTransactionCorrection,
	|	&ReversedDocument AS ReversedDocument,
	|	&CorrectedDocument AS CorrectedDocument,
	|	SUM(ISNULL(DataOfTabularPartOfGoods.Sum,0)) + SUM(ISNULL(CheckoutTabularData.Sum,0)) +
	|		SUM(ISNULL(TabularDataBankAccounts.Sum,0)) + SUM(ISNULL(CashRegisterTabularData.Sum,0)) +
	|		SUM(ISNULL(TabularDataSettlementsBetweenOrganizations.Sum,0)) + SUM(ISNULL(TabularDataSettlementsWithPartners.Sum,0)) +
	|		SUM(ISNULL(DataInTabularPartCalculationsWithAccountablePersons.Sum,0)) + SUM(ISNULL(DataOfTabularPartCalculationsForAcquiring.Sum,0)) +
	|		SUM(ISNULL(TableDataOtherAssetsLiabilities.Sum,0)) +
	|		SUM(ISNULL(TableDataGiftCertificates.AmountInCertificateCurrency,0)) +
	|		SUM(ISNULL(DataOfTabularPartCalculationsOnFinancialInstruments.Sum,0)) + SUM(ISNULL(DataOfTabularPartOfTMTSVOperation.Sum,0))
	|		+ SUM(ISNULL(DataOfTabularPartOtherExpenses.Sum,0)) +
	|		SUM(ISNULL(DataOfTabularPartFinancialResultExpenses.ExpenseAmount,0)) +
	|		SUM(ISNULL(DataOfTabularPartFinancialResultIncome.IncomeAmount,0)) + SUM(ISNULL(DataOfTablePartWholesaleSales.Sum,0))
	|		+ SUM(ISNULL(DataOfTabularPartRetailSales.Sum,0)) + SUM(ISNULL(DataOfTabularPartOfVATPresented.AmountExcludingVAT,0)) +
	|		SUM(ISNULL(DataOfTabularPartOfVATPresented.VAT,0)) + SUM(ISNULL(DataOfTabularPartExpensesForUSN.ExpenseAmount,0)) AS Sum,
	|	CAST(DocumentData.Comment AS STRING(100)) AS Comment,
	|	UNDEFINED AS Priority
	|FROM
	|	Document.OBEntry AS DocumentData
	|		LEFT JOIN Document.OBEntry.Goods AS DataOfTabularPartOfGoods
	|		ON DocumentData.Ref = DataOfTabularPartOfGoods.Ref
	|		LEFT JOIN Document.OBEntry.CashAccounts AS CheckoutTabularData
	|		ON DocumentData.Ref = CheckoutTabularData.Ref
	|		LEFT JOIN Document.OBEntry.BankAccounts AS TabularDataBankAccounts
	|		ON DocumentData.Ref = TabularDataBankAccounts.Ref
	|		LEFT JOIN Document.OBEntry.CashRegisters AS CashRegisterTabularData
	|		ON DocumentData.Ref = CashRegisterTabularData.Ref
	|		LEFT JOIN Document.OBEntry.IntercompanyARAP AS TabularDataSettlementsBetweenOrganizations
	|		ON DocumentData.Ref = TabularDataSettlementsBetweenOrganizations.Ref
	|		LEFT JOIN Document.OBEntry.PartnersARAPAccounting AS TabularDataSettlementsWithPartners
	|		ON DocumentData.Ref = TabularDataSettlementsWithPartners.Ref
	|		LEFT JOIN Document.OBEntry.AdvanceHoldersARAPAccounting_ AS DataInTabularPartCalculationsWithAccountablePersons
	|		ON DocumentData.Ref = DataInTabularPartCalculationsWithAccountablePersons.Ref
	|		LEFT JOIN Document.OBEntry.AcquiringContractARAP AS DataOfTabularPartCalculationsForAcquiring
	|		ON DocumentData.Ref = DataOfTabularPartCalculationsForAcquiring.Ref
	|		LEFT JOIN Document.OBEntry.OtherAssetsLiabilities AS TableDataOtherAssetsLiabilities
	|		ON DocumentData.Ref = TableDataOtherAssetsLiabilities.Ref
	|		LEFT JOIN Document.OBEntry.GiftCertificates AS TableDataGiftCertificates
	|		ON DocumentData.Ref = TableDataGiftCertificates.Ref
	|		LEFT JOIN Document.OBEntry.FinancialInstrumentsARAP AS
	|			DataOfTabularPartCalculationsOnFinancialInstruments
	|		ON DocumentData.Ref = DataOfTabularPartCalculationsOnFinancialInstruments.Ref
	|		LEFT JOIN Document.OBEntry.InventoryInOperation AS DataOfTabularPartOfTMTSVOperation
	|		ON DocumentData.Ref = DataOfTabularPartOfTMTSVOperation.Ref
	|		LEFT JOIN Document.OBEntry.OtherExpenses AS DataOfTabularPartOtherExpenses
	|		ON DocumentData.Ref = DataOfTabularPartOtherExpenses.Ref
	|		LEFT JOIN Document.OBEntry.FinancialResultExpenses AS DataOfTabularPartFinancialResultExpenses
	|		ON DocumentData.Ref = DataOfTabularPartFinancialResultExpenses.Ref
	|		LEFT JOIN Document.OBEntry.FinancialResultIncome AS DataOfTabularPartFinancialResultIncome
	|		ON DocumentData.Ref = DataOfTabularPartFinancialResultIncome.Ref
	|		LEFT JOIN Document.OBEntry.WholesaleSalesInPastPeriods AS DataOfTablePartWholesaleSales
	|		ON DocumentData.Ref = DataOfTablePartWholesaleSales.Ref
	|		LEFT JOIN Document.OBEntry.RetailSales AS DataOfTabularPartRetailSales
	|		ON DocumentData.Ref = DataOfTabularPartRetailSales.Ref
	|		LEFT JOIN Document.OBEntry.VATInvoiced AS DataOfTabularPartOfVATPresented
	|		ON DocumentData.Ref = DataOfTabularPartOfVATPresented.Ref
	|		LEFT JOIN Document.OBEntry.STSExpenses AS DataOfTabularPartExpensesForUSN
	|		ON DocumentData.Ref = DataOfTabularPartExpensesForUSN.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|GROUP BY
	|	DocumentData.Date,
	|	DocumentData.Number,
	|	DocumentData.Ref,
	|	CAST(DocumentData.Comment AS STRING(100))";
	
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
		|	TabPart.Ref.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.OBEntry.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.RecordInOperationalAccounting
		|	AND TabPart.Ref.BusinessOperation IN
		|		(VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse),
		|		VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse),
		|		VALUE(Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors))";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
EndProcedure

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
	DocumentOperations.Add(Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors);
	
	AttachableCommands.AddCommandVisibilityCondition(PrintCommand,
														"BusinessOperation",
														DocumentOperations,
														ComparisonType.InList);
	
	OBEntryLocalization.EnteringLeftoversAddPrintCommands(PrintCommands);

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
	|                          AND NOT &OnlySeriesTakingIntoAccountLeftovers
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
#EndRegion
#EndRegion

#EndIf
