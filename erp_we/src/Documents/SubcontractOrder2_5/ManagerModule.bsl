#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - See ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Manager", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, ReferenceOrder, Manager";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"BankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CashAccount", Parameters);
	
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("Purchases");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("TransferToRecycling");
	DocumentMechanisms.Add("Sales");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("PricesAndDiscounts");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.SubcontractOrder2_5") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers);
		
		QueryTextTableShipmentReferences(Query, QueryTexts, Registers);
		QueryTextTablePurchaseOrders(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableItemsPricesOfVendor(Query, QueryTexts, Registers);
		
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	ScheduleGoodsReceipt(Query, QueryTexts, Registers);
	ReflectReserve(Query, QueryTexts, Registers);
	ScheduleShipmentOfGoods(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

// Update document registry entries.
// It is used to generate register entries based on the data of production stages.
// 
// Parameters:
//  Ref - DocumentRef.SubcontractOrder2_5
//  Cancel - Boolean
//
Procedure UpdateDocumentRegistryEntries(Ref, Cancel) Export
	
	Query = New Query;
	FillInInitializationParameters(Query, Ref);
	
	QueryTexts = New ValueList;
	QueryTextTableDocumentsRegistry(Query, QueryTexts, New Structure("DocumentsRegistry"));
	
	Query.SetParameter("Ref", Ref);
	
	TablesForRegisteredRecords =
		DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, Undefined);
	
	InformationRegisters.DocumentsRegistry.WriteData(TablesForRegisteredRecords, Ref, Undefined, Cancel);
	
EndProcedure
#EndRegion

#Region FillType

// Checks the completeness of the verified details.
//
// Parameters:
//	 OrderDocument              - DocumentRef.SubcontractOrder2_5 - The document on the basis of which the input is made
//	 Status             - EnumRef - Status of the document that is used for entering data
//	 ThereAreErrorsPosted - Boolean - If True-the document on the basis of which the input is made is not held
//	 ForCompletion        - Boolean - Allows you to enter documents in the status of Vypolneniyu.
//
Procedure CheckPossibilityOfEnteringBasedOn(OrderDocument, Status = Undefined, ThereAreErrorsPosted = False, ForCompletion = False) Export
	
	ArrayOfValidStatuses = ValidInputStatusesBasedOn();
	ThereAreErrorsStatus = ArrayOfValidStatuses.Find(Status) = Undefined;
	
	CheckParameters = TMCommonUse.ParametersForCheckingPossibilityOfEnteringBasedOn();
	CheckParameters.Status = Status;
	CheckParameters.ThereAreErrorsPosted = ThereAreErrorsPosted;
	CheckParameters.ThereAreErrorsStatus = ThereAreErrorsStatus;
	CheckParameters.ArrayOfValidStatuses = ArrayOfValidStatuses;
	
	TMCommonUse.CheckPossibilityOfInputBasedOnParameters(OrderDocument, CheckParameters);
	
EndProcedure

// Generates an array of acceptable statuses based on the program settings
//
// Parameters:
//	DocumentName - String - Name of the document to enter.
//
// Returns:
//	Array - array of valid statuses.
//
Function ValidInputStatusesBasedOn(DocumentName = Undefined) Export
	
	ArrayOfValidStatuses = New Array;
	ArrayOfValidStatuses.Add(Enums.TollingOrderStatuses.ForFulfillment);
	ArrayOfValidStatuses.Add(Enums.TollingOrderStatuses.Closed);
	
	Return ArrayOfValidStatuses;
	
EndFunction

// Fills in by-products, materials and works according to product specifications
//
// Parameters:
//  ProductList_	 - Array, TabularSection - list of product lines
//  Object			 - DocumentObject, FormDataStructure - order.
// 	ListOfTS		 - String - a list of names of table parts that need to be filled in.
//
Procedure FillInByProductsMaterialsServicesAccordingToSpecification(ProductList_, Object, ListOfTS = "") Export
	
	NamesOfTS = New Structure(ListOfTS);
	FillInAll_ = NamesOfTS.Count() = 0;
	
	ExceptionFields = Undefined;
	If TypeOf(Object) = Type("FormDataStructure") Then
		ExceptionFields = "ReferenceOrder";
	EndIf;
	CostGroups = New Array;
	ItemList = Catalogs.BillsOfMaterials.ItemList();
	// Grouping fields
	ItemList.Columns.Add("CostGroupNumber");
	ItemList.Columns.Add("Stage");
	
	For Each CurrentData In ProductList_ Do
		
		CostGroups.Add(CurrentData.CostGroupNumber);
		
		If Not ValueIsFilled(CurrentData.BillOfMaterials)
			Or CurrentData.Count = 0 Then
			Continue;
		EndIf;
		
		NewRow = ItemList.Add();
		FillPropertyValues(
			NewRow,
			CurrentData,,
			ExceptionFields);
		
		NewRow.ProductionStart      = Object.Date;
		NewRow.LineOfBusiness = Object.LineOfBusiness;
		
	EndDo;
	
	CommonClientServer.CollapseArray(CostGroups);
	
	#Region StructureOfActionsProductsAndMaterials
	
	ProductActionStructure = New Structure;
	
	StructureAndMaterials = New Structure;
	
	#Region CheckFillWarehouse
	
	ActionParameters =
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(
			Object,
			Catalogs.Warehouses.IsFolder(Object.ManufacturedProductsWarehouse),
			"ManufacturedProductsWarehouse",
			"Recipient");
	
	If Not GetFunctionalOption("UseSeveralWarehouses") Then
		ActionParameters.DefaultWarehouse = TMCommonUse.GetCheckWarehouseByDefault();
	EndIf;
	
	ProductActionStructure.Insert("CheckFillWarehouse" , ActionParameters);
	
	ActionParameters =
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(
			Object,
			Catalogs.Warehouses.IsFolder(Object.MaterialsWarehouse),
			"MaterialsWarehouse",
			"Warehouse");
	
	If Not GetFunctionalOption("UseSeveralWarehouses") Then
		ActionParameters.DefaultWarehouse = TMCommonUse.GetCheckWarehouseByDefault();
	EndIf;
	
	StructureAndMaterials.Insert("CheckFillWarehouse" , ActionParameters);
	
	#EndRegion
	
	#Region QualityControl
	
	ProductActionStructure.Insert("FillInCheckQualityDateOfQualityConfirmation", QualityControl.DataCacheOfMechanism(Object));
	
	#EndRegion
	
	#Region FillInSalePrice
	
	ActionParameters = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object, True);
	ActionParameters.Insert("PriceKind", Object.PriceKind);
	ProductActionStructure.Insert("FillInSalePrice", ActionParameters);
	StructureAndMaterials.Insert("FillInSalePrice", ActionParameters);
	
	#EndRegion
	
	#Region RecalculateAmount
	
	ProductActionStructure.Insert("RecalculateAmount");
	StructureAndMaterials.Insert("RecalculateAmount");
	
	#EndRegion
	
	#EndRegion
	
	#Region StructureOfServiceActions
	
	If Object.ProcessingServices = Enums.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder Then
		
		StructureOfServiceActions = New Structure;
		
		ActionParameters = New Structure;
		
		SelectingTypeOfPrices = New Structure("Owner, PriceIncludesVAT", Object.Partner, Object.PriceIncludesVAT);
		DefaultVendorPriceView = Catalogs.VendorPriceTypes.DefaultPriceType(Undefined, SelectingTypeOfPrices);
		
		ActionParameters.Insert("NameOfPriceTypeField", "VendorPriceKind");
		ActionParameters.Insert("PriceKind", DefaultVendorPriceView);
		StructureOfServiceActions.Insert("FillInPriceView", ActionParameters);
		
		ActionParameters = BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object);
		//Installing an empty link to the packaging, since there is no record of work on packaging
		ActionParameters.Insert("Package", PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
		StructureOfServiceActions.Insert("FillInPurchasePrice", ActionParameters);
		
		ActionParameters = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
		StructureOfServiceActions.Insert("FillInVATRate", ActionParameters);
		
		StructureOfServiceActions.Insert("RecalculateAmount", "Count");
		
		ActionParameters = New Structure;
		ActionParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
		ActionParameters.Insert("VATTaxation", Object.VATTaxation);
		StructureOfServiceActions.Insert("RecalculateVATAmount", ActionParameters);
		StructureOfServiceActions.Insert("RecalculateAmountWithVAT", ActionParameters);
		
	EndIf;
	
	#EndRegion
	
	ListOfData = New Array;
	ListOfData.Add("Stages");
	
	If FillInAll_
		Or NamesOfTS.Property("SideAndIntermediateRelease")
		Or NamesOfTS.Property("SupplyWithMaterialsAndWorks") Then
		ListOfData.Add("RecyclableWaste");
	EndIf;
	
	If FillInAll_
		Or NamesOfTS.Property("SideAndIntermediateRelease")
		Or NamesOfTS.Property("SupplyWithMaterialsAndWorks") Then
		ListOfData.Add("MaterialsAndServices");
	EndIf;
	
	SelectionParameters = Catalogs.BillsOfMaterials.DataSamplingParameters(ListOfData);
	
	SelectionParameters.GetAutoSelectionInformation = False;
	SelectionParameters.GetPresentations      = False;
	SelectionParameters.OverridingReleasePartySetting.Use = True;
	SelectionParameters.OverridingReleasePartySetting.ProductionIssueByCustomPortions = True;
	
	SpecificationsData = Catalogs.BillsOfMaterials.SpecificationDataByProductsList(
		ItemList,
		SelectionParameters,
		True,
		"CostGroupNumber, Stage");
	
	// If there is an interactive filling call on the form, then the table of output products is not subject to change.
	If Not TypeOf(Object) = Type("FormDataStructure")
		And Not ListOfData.Find("RecyclableWaste") = Undefined Then
		ExcludeByProductsFromWeekends(Object, ProductList_, SpecificationsData);
	EndIf;
	
	For Each StructureOfData In SpecificationsData Do
		
		If StructureOfData = Undefined Then
			Continue;
		EndIf;
		
		If FillInAll_
			Or NamesOfTS.Property("SideAndIntermediateRelease")
			Or NamesOfTS.Property("SupplyWithMaterialsAndWorks") Then
			Catalogs.BillsOfMaterials.ExcludeIntermediateRelease(StructureOfData);
		EndIf;
		
		// SideAndIntermediateRelease
		If FillInAll_
			Or NamesOfTS.Property("SideAndIntermediateRelease") Then
			
			OperationDateParameters = New Structure;
			OperationDateParameters.Insert("FieldName", "DateOfReceipt");
			OperationDateParameters.Insert("Date",    ?(Object.OneDateReceipt, Object.DateOfReceipt, Undefined));
			
			FillInStandards_(
				Object.SideAndIntermediateRelease,
				StructureOfData.RecyclableWaste,
				StructureOfData.CostGroupNumber,
				ProductActionStructure,
				OperationDateParameters);
			
		EndIf;
		
		// SupplyWithMaterialsAndWorks
		If FillInAll_
			Or NamesOfTS.Property("SupplyWithMaterialsAndWorks") Then
			
			OperationDateParameters = New Structure;
			OperationDateParameters.Insert("FieldName", "DateOfShipment");
			OperationDateParameters.Insert("Date",    ?(Object.NotShipInInstallments, Object.DateOfShipment, Undefined));
			
			FillInStandards_(
				Object.SupplyWithMaterialsAndWorks,
				StructureOfData.MaterialsAndServices,
				StructureOfData.CostGroupNumber,
				StructureAndMaterials,
				OperationDateParameters);
			
			If Not Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
				And Not Object.SupplyWithMaterialsAndWorks.Count() = 0
				And CommonClientServer.HasAttributeOrObjectProperty(Object.SupplyWithMaterialsAndWorks[0], "Produced") Then
				For Each CurrentData In Object.SupplyWithMaterialsAndWorks Do
					CurrentData.Produced = False;
				EndDo;
			EndIf;
			
			FillInAssignmentsInMaterials(Object, StructureOfData.CostGroupNumber);
			
		EndIf;
		
		// Services
		If Object.ProcessingServices = Enums.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder
			And (FillInAll_
				Or NamesOfTS.Property("Services")) Then
			
			OperationDateParameters = New Structure;
			OperationDateParameters.Insert("FieldName", "ExecutionDate");
			OperationDateParameters.Insert("Date",    ?(Object.WorkPerformanceAsOneDay, Object.ExecutionDate, Undefined));
			
			For Each CurStage In StructureOfData.Stages Do
				
				If Not CurStage.Stage = StructureOfData.Stage
						And ValueIsFilled(StructureOfData.Stage)
					Or Not CurStage.ProductionByThirdParty
					Or CurStage.SubcontractorServices.Count() = 0 Then
					Continue;
				EndIf;
				
				FillInStandards_(
					Object.Services,
					CurStage.SubcontractorServices,
					StructureOfData.CostGroupNumber,
					StructureOfServiceActions,
					OperationDateParameters);
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	If Object.ProcessingServices = Enums.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder
		And (FillInAll_
			Or NamesOfTS.Property("Services")) Then
		
		RowsToProcess = New Array;
		Filter = New Structure("CostGroupNumber");
		For Each CurrentData In CostGroups Do
			
			Filter.CostGroupNumber = CurrentData;
			
			If Object.Services.FindRows(Filter).Count() = 0 Then
				NewRow = Object.Services.Add();
				NewRow.CostGroupNumber = CurrentData;
				RowsToProcess.Add(NewRow);
			EndIf;
			
		EndDo;
		
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		
		ActionParameters = New Structure;
		ActionParameters.Insert("NameOfPriceTypeField", "VendorPriceKind");
		ActionParameters.Insert("PriceKind", DefaultVendorPriceView);
		
		StructureOfServiceActions = New Structure;
		StructureOfServiceActions.Insert("FillInPriceView", ActionParameters);
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfServiceActions,
			Object.Services,
			CachedValues);
	
	EndIf;
	
EndProcedure

// Fill in the assignments in the materials.
// 
// Parameters:
//  Object - DocumentObject.SubcontractOrder2_5, FormDataStructure - order.
//  CostGroupNumber - Number - the number of the processed cost group, if 0, then all cost groups are processed.
//
Procedure FillInAssignmentsInMaterials(Object, CostGroupNumber = 0) Export
	
	MatchingAssignments = New Map;
	
	If Object.SeparationOfMaterialsByProductPurpose
		Or GetFunctionalOption("UseTollManufacturing2_5")
		Or False Then
		DestinationData = New Map;
		For Each String In Object.ManufacturedProducts Do
			
			If Not CostGroupNumber = 0
				And Not String.CostGroupNumber = CostGroupNumber Then
				Continue;
			EndIf;
			AssignmentsData = DestinationData.Get(String.Purpose);
			If AssignmentsData = Undefined Then
				
				AssignmentsData =
					Common.ObjectAttributesValues(
						String.Purpose,
						"AssignmentType, LineOfBusiness, Partner, Contract, OrderDocument");
				
				DestinationData.Insert(String.Purpose, AssignmentsData);
				
			EndIf;
			If Object.SeparationOfMaterialsByProductPurpose
				And ValueIsFilled(String.Purpose)
				And Not AssignmentsData.AssignmentType = Enums.AssignmentTypes.Giveaway2_5
				And (Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductsAndAssignments
					Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductBOMAndAssignments) Then
				MatchingAssignments.Insert(String.CostGroupNumber, String.Purpose);
			ElsIf ValueIsFilled(String.Purpose)
				And AssignmentsData.AssignmentType = Enums.AssignmentTypes.Giveaway2_5 Then
				DestinationTemplateMaterials = AssignmentTemplateGiverSMaterials(AssignmentsData);
				MatchingAssignments.Insert(String.CostGroupNumber, Catalogs.Assignments.FindByTemplate(DestinationTemplateMaterials));
			EndIf;
			
		EndDo;
		
	EndIf;
	
	For Each String In Object.SupplyWithMaterialsAndWorks Do
		
		If Not CostGroupNumber = 0
			And Not String.CostGroupNumber = CostGroupNumber Then
			Continue;
		EndIf;
		
		If String.WithAssignment Then
			FoundDestination = MatchingAssignments.Get(String.CostGroupNumber);
			String.Purpose = ?(ValueIsFilled(FoundDestination), FoundDestination, Object.Purpose);
		Else
			String.Purpose = Undefined;
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills in the document by production stages
//
// Parameters:
//  StageList - Array - contains a list of stages
//  Object - DocumentObject.SubcontractOrder2_5, FormDataStructure - the document to fill out.
//
// Returns:
// 	Array - Array of table rows added when filling in by production stages.
//
Function FillByStagesOfProduction(StageList, Object) Export
	
	If StageList.Count() = 0 Then
		Return New Array;
	EndIf;
	
	QueryText = RequestTextOutputProductsOfStages(True);
	QueryText = StrReplace(QueryText, "&CostGroupNumber", "0");
	
	ListOfOrderStages = Object.References.Unload(, "ReferenceOrder").UnloadColumn("ReferenceOrder");
	ListOfNewStages = CommonClientServer.ArraysDifference(StageList, ListOfOrderStages);
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("StageList", ListOfNewStages);
	
	Result = Query.Execute();
	
	NumberOfOrdersBeforeFilling = Object.References.Count();
	ProductionInOneDay = True;
	LeaveProductsAtSubcontractor = True;
	ProductionDate = '000101010000';
	NotShipInInstallments = True;
	DateOfShipment = '000101010000';
	ListOfNewOrders = New Array;
	
	// Used to fill in data about the processor's services
	ItemList = Catalogs.BillsOfMaterials.ItemList();
	ItemList.Columns.Add("CostGroupNumber");
	ItemList.Columns.Add("Stage");
	
	References = Result.Unload(QueryResultIteration.ByGroups);
	For Each TechnicalOrder In References.Rows Do
		
		Object.MaximumNumberOfCostGroup = Object.MaximumNumberOfCostGroup + 1;
		
		CommandLine_ = Object.References.Add();
		FillPropertyValues(CommandLine_, TechnicalOrder);
		CommandLine_.CostGroupNumber = Object.MaximumNumberOfCostGroup;
		
		If TechnicalOrder.ProductionDate = '000101010000' Then
			StageProductionDate = Documents.ProductionStage2_2.PlannedDateOfReceipt(TechnicalOrder.ReferenceOrder);
		Else
			StageProductionDate = TechnicalOrder.ProductionDate;
		EndIf;
		
		If Not TechnicalOrder.ProductionInOneDay
			Or Not ProductionDate = '00010101'
				And Not ProductionDate = StageProductionDate Then
			ProductionInOneDay = False;
		Else
			ProductionDate = StageProductionDate;
		EndIf;
		
		If Not TechnicalOrder.LeaveProductsAtSubcontractor Then
			LeaveProductsAtSubcontractor = False;
		EndIf;
		
		If Not TechnicalOrder.NotShipInInstallments
			Or Not DateOfShipment = '00010101'
				And Not DateOfShipment = TechnicalOrder.DateOfShipment Then
			NotShipInInstallments = False;
		Else
			DateOfShipment = TechnicalOrder.DateOfShipment;
		EndIf; 
		
		If Not ValueIsFilled(Object.GoodsReceiptOption) Then
			Object.GoodsReceiptOption = TechnicalOrder.GoodsReceiptOption;
		ElsIf Object.GoodsReceiptOption <> TechnicalOrder.GoodsReceiptOption Then
			Raise NStr("vi = 'Lỗi. Thử tạo đơn hàng đặt gia công theo các công đoạn sản xuất có những phương án tiếp nhận khác nhau trong kho hai pha';
						|ru = 'Ошибка. Попытка создания заказа переработчику по этапам производства, имеющим разные варианты приемки на ордерный склад';
						|en = 'Error. An attempt to create a ""Subcontracting purchase order"" by production stages which have different options of receiving to warehouse'; fa = 'Error. An attempt to create a ""Subcontracting purchase order"" by production stages which have different options of receiving to warehouse';
						|it = 'Errore. Tentativo di creare un ordine al subfornitore per le fasi di produzione che hanno le varianti diverse di accettazione al magazzino dei mandati';
						|pl = 'Błąd. Próba utworzenia zamówienia przetwórcy według etapów produkcji, mającym różne warianty przyjęcia do zaawansowanego zarządzania magazynem';
						|tr = 'Hata. Ambara kabule yönelik farklı seçeneklere sahip olan üretim aşamaları için fason üretici satın alma siparişi oluşturma denemesi'");
		EndIf;
		
		ListOfNewOrders.Add(CommandLine_);
		
		// We will fill out the products to receive these services
		If Object.ProcessingServices = Enums.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder Then
			For Each CurProduct In TechnicalOrder.Rows Do
				NewRow = ItemList.Add();
				FillPropertyValues(
					NewRow,
					CurProduct,
					"Products, Characteristic, BillOfMaterials, Stage, Count");
				NewRow.CostGroupNumber = CommandLine_.CostGroupNumber;
			EndDo;
		EndIf;
		
	EndDo;
	
	If Object.ProcessingServices = Enums.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder Then
		FillInByProductsMaterialsServicesAccordingToSpecification(ItemList, Object, "Services");
	EndIf;
	
	Object.MethodOfAllocatingFinishedProductCosts = Enums.MethodsOfCostAllocatingOnProductCosts.EmptyRef();
	
	If NumberOfOrdersBeforeFilling = 0 Then
		Object.OneDateReceipt = ProductionInOneDay;
		Object.LeaveProductsAtSubcontractor = LeaveProductsAtSubcontractor;
		Object.DateOfReceipt = ProductionDate;
		Object.NotShipInInstallments = NotShipInInstallments;
		Object.DateOfShipment = DateOfShipment;
	EndIf; 
	
	OrdersServer.FillInOrderInOrderHeaderInTableSection(Object.ReferenceOrder, Object.References, "ReferenceOrder");
	
	Return ListOfNewOrders;
	
EndFunction

// The text of the request "Output products of stages".
// 
// Parameters:
//  GenerateResults - Boolean - Generate results
// 
// Returns:
//  String -- Query text
Function RequestTextOutputProductsOfStages(GenerateResults) Export
	
	QueryText =
	"SELECT ALLOWED
	|	DocumentData.Ref                  AS ReferenceOrder,
	|	DocumentData.Stage                    AS Stage,
	|	DocumentData.BillOfMaterials            AS BillOfMaterials,
	|	DocumentData.ProductionInOneDay  AS ProductionInOneDay,
	|	DocumentData.ProductionDate        AS ProductionDate,
	|	DocumentData.NotShipInInstallments      AS NotShipInInstallments,
	|	DocumentData.DateOfShipment            AS DateOfShipment,
	|	DocumentData.GoodsReceiptOption   AS GoodsReceiptOption,
	|	DocumentData.LeaveProductsAtSubcontractor AS LeaveProductsAtSubcontractor,
	|	ProductTable_.Products             AS Products,
	|	ProductTable_.Characteristic           AS Characteristic,
	|	ProductTable_.Count               AS Count,
	|	&CostGroupNumber                      AS CostGroupNumber
	|FROM
	|	Document.ProductionStage2_2 AS DocumentData
	|
	|	LEFT JOIN Document.ProductionStage2_2.ManufacturedProducts AS ProductTable_
	|	ON ProductTable_.Ref.ProductionLot = DocumentData.ProductionLot
	|
	|WHERE
	|	DocumentData.Ref IN (&StageList)
	|	AND DocumentData.SubcontractOrder IN (UNDEFINED, &Ref)
	|";
	
	If GenerateResults Then
		QueryText = QueryText +"
		|
		|TOTALS
		|	MAX(Stage),
		|	MAX(BillOfMaterials),
		|	MAX(ProductionInOneDay),
		|	MAX(ProductionDate),
		|	MAX(NotShipInInstallments),
		|	MAX(DateOfShipment),
		|	MAX(GoodsReceiptOption),
		|	MAX(LeaveProductsAtSubcontractor)
		|BY
		|	ReferenceOrder
		|";
	EndIf;
	
	Return QueryText;
	
EndFunction

#Region TextsOfRequestOrderOfInvoices

// Adds the key details of the order to the selection collection
// 
// Parameters:
// 	Filter - Map
//
Procedure AddSelectionBasedOnKeyOrderDetails(Filter) Export
	
	KeyAttributes = New Array;
	KeyAttributes.Add("Organization");
	KeyAttributes.Add("Partner");
	KeyAttributes.Add("Counterparty");
	KeyAttributes.Add("Contract");
	KeyAttributes.Add("SalesOpportunity");
	KeyAttributes.Add("Currency");
	KeyAttributes.Add("LineOfBusiness");
	
	TMCommonUse.AddSelectionBasedOnKeyOrderDetails(KeyAttributes, Filter);
	
EndProcedure

// Returns the text of the request for orders to processors according to key and additional selections.
// 
// Parameters:
// 	Parameters - See TMCommonUse.ParametersOfRequestTextForOrdersInvoices
// Returns:
//  String - Query text
//
Function RequestTextForOrdersInvoices(Parameters) Export
	
	AddSelectionBasedOnKeyOrderDetails(Parameters.Filter);
	
	QueryText =
	"SELECT
	|	TableOfOrders.Ref AS ReferenceOrder
	|FROM
	|	Document.SubcontractOrder2_5 AS TableOfOrders
	|WHERE
	|	TableOfOrders.Posted
	|	AND &FilterText1
	|";
	
	If Parameters.GenerateTT Then
		QueryText = RequestSchemes.SetSelectionOfAllowedRecords(QueryText, True);
		QueryText = RequestSchemes.SetRoomToTemporaryTable(QueryText, Parameters.TTName);
		QueryText = RequestSchemes.SetIndexingOfQueryFields(QueryText, "ReferenceOrder");
	EndIf;
	
	QueryText =
		StrReplace(QueryText, "&FilterText1", TMCommonUse.SelectionTextBySelectionCollection(Parameters.Filter));
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#Region Status

// Generates a verification request when changing the status of the list of documents
//
// Parameters:
//	DocumentsArray - Array - An array of references to documents that should be reviewed
//	NewStatus - String - Name of the new status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.TollingOrderStatuses[NewStatus];
	
	QueryText =
	"SELECT
	|	DocumentsTable.Ref					AS Ref,
	|	PRESENTATION(DocumentsTable.Ref)		AS Presentation,
	|	PRESENTATION(DocumentsTable.Status)		AS PresentationOfCurStatus,
	|	PRESENTATION(&Status)						AS PresentationOfNewStatus,
	|	CASE WHEN DocumentsTable.Status = &Status THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END										AS StatusMatches,
	|	DocumentsTable.Posted					AS Posted,
	|	DocumentsTable.DeletionMark			AS DeletionMark,
	|	CASE WHEN NOT &UseStatuses
	|			AND NOT DocumentsTable.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|		THEN TRUE
	|	ELSE
	|		FALSE
	|	END										AS ItIsForbiddenToChangeStatus,
	|	TRUE										AS Recording
	|FROM
	|	Document.SubcontractOrder2_5 AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN(&DocumentsArray)
	|";
	
	UseStatuses = GetFunctionalOption("UseTollingOrderStatuses2_5");
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	Query.SetParameter("UseStatuses", UseStatuses);
	
	Return Query;
	
EndFunction

// Generates a verification request when the status of the list of documents is changed automatically
//
// Parameters:
//	DocumentsArray - Array - An array of references to documents that should be reviewed
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenCalculatingStatusAutomatically(DocumentsArray, AdditionalParameters) Export
	
	QueryText =
	"SELECT
	|	DocumentsTable.Ref					AS Ref,
	|	PRESENTATION(DocumentsTable.Ref)		AS Presentation,
	|	DocumentsTable.Posted					AS Posted,
	|	DocumentsTable.DeletionMark			AS DeletionMark,
	|	CASE WHEN NOT &UseStatuses
	|			AND NOT DocumentsTable.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|		THEN TRUE
	|	ELSE
	|		FALSE
	|	END										AS ItIsForbiddenToChangeStatus,
	|	TRUE										AS Recording
	|FROM
	|	Document.SubcontractOrder2_5 AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN(&DocumentsArray)
	|";
	
	UseStatuses = GetFunctionalOption("UseTollingOrderStatuses2_5");
	
	Query = New Query(QueryText);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	Query.SetParameter("UseStatuses", UseStatuses);
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes
//
// Parameters:
//	ValidationSample - QueryResultSelection - Current selection string
//	NewStatus - EnumRef.TollingOrderStatuses - New status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Cancel = False;
	
	If ValidationSample.ItIsForbiddenToChangeStatus Then
		
		ErrorText = NStr("vi = 'Trong chứng từ %Document% chưa đặt trạng thái ""%Status%"", bởi vì đơn hàng đặt gia công đã tạo không trên cơ sở đơn hàng sản xuất.';
						|ru = 'У документа %Document% статус ""%Status%"" не установлен, т.к. заказ переработчику создан не на основании заказа на производство.';
						|en = 'The ""%Status%"" status is not set for document %Document% as the ""Subcontracting purchase order"" is generated not based on the production order.'; fa = 'The ""%Status%"" status is not set for document %Document% as the ""Subcontracting purchase order"" is generated not based on the production order.';
						|it = 'Lo stato ""%Status%"" del documento %Document% non è impostato, perché l''ordine al subfornitore non è stato creato in base all''ordine di produzione.';
						|pl = 'Dla dokumentu %Document% nie ustawiono statusu ""%Status%"", ponieważ zamówienie do przetwórcy utworzono nie na podstawie zlecenia produkcyjnego.';
						|tr = 'Fason satın alma siparişi, bir üretim emri temelinde oluşturulmadığından dolayı %Document% belgesinde ""%Status%"" durumu ayarlanmadı.'");
		ErrorText = StrReplace(ErrorText, "%Document%", ValidationSample.Ref);
		ErrorText = StrReplace(ErrorText, "%Status%", ValidationSample.PresentationOfNewStatus);
		Common.MessageToUser(ErrorText, ValidationSample.Ref);
		Cancel = True;
		
	EndIf;
	
	Return Not Cancel;
	
EndFunction

// Corrects lines that had not been issued a receipt or warehouse warrant or there are differences in the measured products.
// 
// Parameters:
// 	Object - DocumentObject.SubcontractOrder2_5, FormDataStructure - 
// 	ParametersStructure - See OrdersServer.OrderLineAdjustmentStructure
// Returns:
// 	See OrdersServer.ResultOfUndoingUnprocessedRows
//
Function AdjustOrderLines(Object, ParametersStructure) Export
	
	If Not ParametersStructure.CancelUnprocessedLines
		And Not (ParametersStructure.CorrectMeasuringGoods Or ParametersStructure.AdjustTheMeasuredGoodsUponAcceptance) Then
		Return OrdersServer.ResultOfUndoingUnprocessedRows(Undefined)
	EndIf;
	If Object.GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages")
		And Not ParametersStructure.TabularSectionName = "Services" Then
		ReasonFieldName = "ReasonForCancellationOfProduction";
	Else
		ReasonFieldName = "CancellationReason";
	EndIf;
	NumberOfAdjustedRows = 0;
	
	AdjustProducts =
		(ParametersStructure.CancelUnprocessedLines
			Or ParametersStructure.AdjustTheMeasuredGoodsUponAcceptance)
		And (ParametersStructure.TabularSectionName = "Goods"
			Or ParametersStructure.TabularSectionName = "ManufacturedProducts");
	
	AdjustWhoWaste =
		(ParametersStructure.CancelUnprocessedLines
			Or ParametersStructure.AdjustTheMeasuredGoodsUponAcceptance)
		And (ParametersStructure.TabularSectionName = "Goods"
			Or ParametersStructure.TabularSectionName = "SideAndIntermediateRelease");
	
	AdjustMaterials =
		(ParametersStructure.CancelUnprocessedLines
			Or ParametersStructure.CorrectMeasuringGoods)
		And (ParametersStructure.TabularSectionName = "Goods"
			Or ParametersStructure.TabularSectionName = "SupplyWithMaterialsAndWorks");
	
	AdjustServices =
		ParametersStructure.CancelUnprocessedLines
		And (ParametersStructure.TabularSectionName = "Goods"
			Or ParametersStructure.TabularSectionName = "Services");
	
	If Not ParametersStructure.CheckBalance Then
		
		PropertiesOfCanceledRow = New Structure;
		PropertiesOfCanceledRow.Insert("Canceled",            True);
		PropertiesOfCanceledRow.Insert(ReasonFieldName,        ParametersStructure.CancellationReason);
		PropertiesOfCanceledRow.Insert("BatchesIndicationStatus", 0);
		// Quality control
		PropertiesOfCanceledRow.Insert("ToControlQuality", False);
		PropertiesOfCanceledRow.Insert("QualityConfirmationDate", Undefined);
		
		If AdjustProducts Then
			
			For Each LineProducts_ In Object.ManufacturedProducts Do
				If Not LineProducts_.Canceled Then
					FillPropertyValues(LineProducts_, PropertiesOfCanceledRow);
					NumberOfAdjustedRows = NumberOfAdjustedRows + 1;
				EndIf;
			EndDo;
			
		EndIf;
		
		If AdjustWhoWaste Then
			For Each LineProducts_ In Object.SideAndIntermediateRelease Do
				If Not LineProducts_.Canceled Then
					FillPropertyValues(LineProducts_, PropertiesOfCanceledRow);
					NumberOfAdjustedRows = NumberOfAdjustedRows + 1;
				EndIf;
			EndDo;
		EndIf;
		
		If AdjustMaterials Then
			For Each LineProducts_ In Object.SupplyWithMaterialsAndWorks Do
				If Not LineProducts_.Canceled Then
					FillPropertyValues(LineProducts_, PropertiesOfCanceledRow);
					NumberOfAdjustedRows = NumberOfAdjustedRows + 1;
				EndIf;
			EndDo;
		EndIf;
		
		If AdjustServices Then
			For Each LineProducts_ In Object.Services Do
				If Not LineProducts_.Canceled Then
					FillPropertyValues(LineProducts_, PropertiesOfCanceledRow);
					NumberOfAdjustedRows = NumberOfAdjustedRows + 1;
				EndIf;
			EndDo;
		EndIf;
		
		Return OrdersServer.ResultOfUndoingUnprocessedRows(NumberOfAdjustedRows);
		
	EndIf;
	
	CancellationReason = ?(ParametersStructure.CancelUnprocessedLines, ParametersStructure.CancellationReason,
		Catalogs.ReasonsForPurchaseOrderCancellation.VarianceOnDimensionalGoodsReceiving);
	
	FillParameters = OrdersServer.FillOptionsForCancelingRows();
	FillParameters.RegisterManager  = AccumulationRegisters.PurchaseOrders;
	
	CancellationOptions = OrdersServer.OptionsForCancelingOrderLines();
	CancellationOptions.CancellationReason = CancellationReason;
	CancellationOptions.CancelOnlyMeasuredGoods =
		Not ParametersStructure.CancelUnprocessedLines
		And ParametersStructure.AdjustTheMeasuredGoodsUponAcceptance;
	If Object.GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages")
		And Not ParametersStructure.TabularSectionName = "Services" Then
		CancellationOptions.FieldNameReasonForCancellation = "ReasonForCancellationOfProduction";
	EndIf;
	CancellationOptions.CorrectMeasuringGoods = ParametersStructure.AdjustTheMeasuredGoodsUponAcceptance;
	
	If AdjustProducts Then
		
		FillParameters.TabularSectionName = "ManufacturedProducts";
		
		NumberOfAdjustedRowsUpTo = NumberOfAdjustedRows;
		NumberOfAdjustedRows =
			NumberOfAdjustedRows
			+ OrdersServer.CancelUnprocessedAcceptanceLines(Object, FillParameters, CancellationOptions).RowsCount;
		
		If Not NumberOfAdjustedRowsUpTo = NumberOfAdjustedRows Then
			For Each LineProducts_ In Object.ManufacturedProducts Do
				If LineProducts_.Canceled Then
					LineProducts_.ToControlQuality = False;
					LineProducts_.QualityConfirmationDate = Undefined;
				EndIf;
			EndDo;
		EndIf;
		
	EndIf;
	
	If AdjustServices Then
		
		FillParameters.TabularSectionName = "Services";
		
		NumberOfAdjustedRows =
			NumberOfAdjustedRows
			+ OrdersServer.CancelUnprocessedAcceptanceLines(Object, FillParameters, CancellationOptions).RowsCount;
		
	EndIf;
	
	If AdjustWhoWaste Then
		
		FillParameters.TabularSectionName = "SideAndIntermediateRelease";
		CancellationOptions.AdjustAmount = True;
		
		NumberOfAdjustedRowsUpTo = NumberOfAdjustedRows;
		NumberOfAdjustedRows =
			NumberOfAdjustedRows
			+ OrdersServer.CancelUnprocessedAcceptanceLines(Object, FillParameters, CancellationOptions).RowsCount;
		
		If Not NumberOfAdjustedRowsUpTo = NumberOfAdjustedRows Then
			For Each LineProducts_ In Object.SideAndIntermediateRelease Do
				If LineProducts_.Canceled Then
					LineProducts_.ToControlQuality = False;
					LineProducts_.QualityConfirmationDate = Undefined;
				EndIf;
			EndDo;
		EndIf;
		
	EndIf;
	
	If AdjustMaterials Then
		
		FillParameters.RegisterManager  = AccumulationRegisters.ShipmentAndReturnReferences;
		FillParameters.TabularSectionName = "SupplyWithMaterialsAndWorks";
		
		NumberOfAdjustedRows =
			NumberOfAdjustedRows
			+ OrdersServer.UndoUnprocessedShippingLines(Object, FillParameters, CancellationOptions).RowsCount;
		
		NumberOfAdjustedRows =
			NumberOfAdjustedRows
			+ CancelUnspentLinesThatWereSentEarlier(Object);
		
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.SubcontractOrder2_5));
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
		
	EndIf;
	
	Return OrdersServer.ResultOfUndoingUnprocessedRows(NumberOfAdjustedRows);
	
EndFunction

// Cancel unspent lines that were sent earlier.
// The algorithm:
// - We get the amount of materials from the reports of the processor.
// - We reduce the number of materials from the processor's reports by the number of materials shipped.
// - We cancel the amount of materials transferred earlier, which is not reflected in the reports of the processor.
// 
// Parameters:
//  Object - DocumentObject.SubcontractOrder2_5, FormDataStructure - Object
// 
// Returns:
//  Number - Number of cancelled rows
//
Function CancelUnspentLinesThatWereSentEarlier(Object)
	
	// 1. Description of the table
	TableOfSelectedRows = New ValueTable();
	TableOfSelectedRows.Columns.Add("CostGroupNumber",        New TypeDescription("Number"));
	TableOfSelectedRows.Columns.Add("Products",             New TypeDescription("CatalogRef.Products"));
	TableOfSelectedRows.Columns.Add("Characteristic",           New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfSelectedRows.Columns.Add("Series",                    New TypeDescription("CatalogRef.ItemsBatches"));
	TableOfSelectedRows.Columns.Add("SupplyOption",       New TypeDescription("EnumRef.SupplyOptions"));
	TableOfSelectedRows.Columns.Add("Id",            New TypeDescription("Number"));
	
	TableOfSelectedRows.Columns.Add("Count",               New TypeDescription("Number"));
	TableOfSelectedRows.Columns.Add("AmountTransmittedEarlier",   New TypeDescription("Number"));
	
	// 2. Filling in the document data
	For Each CurrentData In Object.SupplyWithMaterialsAndWorks Do
		
		If CurrentData.Canceled
			Or (Not CurrentData.SupplyOption = Enums.SupplyOptions.Ship
				And Not CurrentData.SupplyOption = Enums.SupplyOptions.TransferedEarlier) Then
			Continue;
		EndIf;
		
		NewRow = TableOfSelectedRows.Add();
		FillPropertyValues(NewRow, CurrentData);
		NewRow.Id = CurrentData.LineNumber - 1;
		
	EndDo;
	
	// 3. Receipt of the quantity of materials reflected in the reports of the processor, minus those shipped by order.
	Query = New Query;
	If Common.DebugMode() Then
		Query.TempTablesManager = New TempTablesManager;
	EndIf;
	
	Query.Text =
	"SELECT
	|	TableMaterials.CostGroupNumber AS CostGroupNumber,
	|	TableMaterials.Products      AS Products,
	|	TableMaterials.Characteristic    AS Characteristic,
	|	TableMaterials.Series             AS Series,
	|	TableMaterials.Count        AS Count
	|INTO ShippedMaterials
	|FROM
	|	&TableOfSelectedRows AS TableMaterials
	|WHERE
	|	TableMaterials.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ProductItemTable.Ref                                AS Ref,
	|	ProductItemTable.CostGroupNumber                     AS CostGroupNumber
	|INTO ProductItemTable
	|FROM
	|	(SELECT
	|		ProductItemTable.Ref             AS Ref,
	|		ProductItemTable.CostGroupNumber  AS CostGroupNumber
	|	FROM
	|		Document.SubcontractorReport2_5.ManufacturedProducts AS ProductItemTable
	|	WHERE
	|		ProductItemTable.SubcontractOrder = &SubcontractOrder
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProductItemTable.Ref             AS Ref,
	|		ProductItemTable.CostGroupNumber  AS CostGroupNumber
	|	FROM
	|		Document.SubcontractorReport2_5.SideAndIntermediateRelease AS ProductItemTable
	|	WHERE
	|		ProductItemTable.SubcontractOrder = &SubcontractOrder
	|	) AS ProductItemTable
	|
	|GROUP BY
	|	ProductItemTable.Ref,
	|	ProductItemTable.CostGroupNumber
	|
	|INDEX BY
	|	Ref,
	|	CostGroupNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TableMaterials.CostGroupNumber AS CostGroupNumber,
	|	TableMaterials.Products      AS Products,
	|	TableMaterials.Characteristic    AS Characteristic,
	|	TableMaterials.Series             AS Series,
	|	SUM(TableMaterials.Count) AS Count
	|FROM
	|	(SELECT
	|		TableMaterials.CostGroupNumber AS CostGroupNumber,
	|		TableMaterials.Products      AS Products,
	|		TableMaterials.Characteristic    AS Characteristic,
	|		TableMaterials.Series             AS Series,
	|		TableMaterials.Count        AS Count
	|	FROM
	|		ProductItemTable AS ProductItemTable
	|		
	|		INNER JOIN Document.SubcontractorReport2_5.MaterialsAndWorks AS TableMaterials
	|		ON TableMaterials.Ref = ProductItemTable.Ref
	|		AND TableMaterials.CostGroupNumber = ProductItemTable.CostGroupNumber
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableMaterials.CostGroupNumber AS CostGroupNumber,
	|		TableMaterials.Products      AS Products,
	|		TableMaterials.Characteristic    AS Characteristic,
	|		TableMaterials.Series             AS Series,
	|		-TableMaterials.Count       AS Count
	|	FROM
	|		ShippedMaterials AS TableMaterials
	|	) AS TableMaterials
	|
	|GROUP BY
	|	TableMaterials.CostGroupNumber,
	|	TableMaterials.Products,
	|	TableMaterials.Characteristic,
	|	TableMaterials.Series
	|
	|HAVING
	|	SUM(TableMaterials.Count) > 0
	|";
	
	Query.SetParameter("SubcontractOrder",    Object.Ref);
	Query.SetParameter("TableOfSelectedRows", TableOfSelectedRows);
	
	Var_Key = "CostGroupNumber, Products, Characteristic, Series";
	SpentMaterials = Query.Execute().Unload();
	SpentMaterials.Indexes.Add(Var_Key);
	
	// 4. Cancellation of unspent materials
	CancelledRowsCount = 0;
	
	RowsToProcess = New Array;
	For Each CurrentData In TableOfSelectedRows Do
		
		If Not CurrentData.SupplyOption = Enums.SupplyOptions.TransferedEarlier Then
			Continue;
		EndIf;
		
		Filter = New Structure(Var_Key);
		FillPropertyValues(Filter, CurrentData);
		For Each FoundRow In SpentMaterials.FindRows(Filter) Do
			
			If FoundRow.Count = 0 Then
				Continue;
			EndIf;
			
			AmountSpent = Min(CurrentData.Count, FoundRow.Count);
			
			CurrentData.AmountTransmittedEarlier = CurrentData.AmountTransmittedEarlier + AmountSpent;
			CurrentData.Count = CurrentData.Count - AmountSpent;
			
			FoundRow.Count = FoundRow.Count - AmountSpent;
			
			If CurrentData.Count = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
		If Not CurrentData.AmountTransmittedEarlier = 0
			And Not Object.SupplyWithMaterialsAndWorks[CurrentData.Id].Count = CurrentData.AmountTransmittedEarlier Then
			
			Object.SupplyWithMaterialsAndWorks[CurrentData.Id].Count = CurrentData.AmountTransmittedEarlier;
			RowsToProcess.Add(Object.SupplyWithMaterialsAndWorks[CurrentData.Id]);
			
		EndIf;
		
		If Not CurrentData.Count = 0 Then
			
			If Not Object.SupplyWithMaterialsAndWorks[CurrentData.Id].Count = CurrentData.Count Then
				
				NewRow = Object.SupplyWithMaterialsAndWorks.Add();
				FillPropertyValues(NewRow, Object.SupplyWithMaterialsAndWorks[CurrentData.Id]);
				NewRow.Count = CurrentData.Count;
				RowsToProcess.Add(NewRow);
				
			Else
				NewRow = Object.SupplyWithMaterialsAndWorks[CurrentData.Id];
			EndIf;
			
			NewRow.Canceled = True;
			
			CancelledRowsCount = CancelledRowsCount + 1;
			
		EndIf;
		
	EndDo;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	StructureOfActions.Insert("RecalculateAmount");
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.SupplyWithMaterialsAndWorks,
		CachedValues);
	
	Return CancelledRowsCount;
	
EndFunction

#EndRegion

#Region CostGroups

// Updates the list of document cost groups
// 
// Parameters:
// 	Object - DocumentObject.SubcontractOrder2_5, Structure - object data
// 	CostGroups - ValueTable, FormDataCollection - table of cost groups
// 	NumberOfCostGroups - Number - form details storing the number of cost groups
//
Procedure UpdateCostGroups(Object, CostGroups, NumberOfCostGroups) Export

	FieldList =
		ProcessingByThirdPartiesClientServer.ListOfOrderCostGroupFieldsForProcessor(Object.GroupCosts);
	
	TextOfSelectionField = ProcessingByThirdPartiesClientServer.RequestTextByCostGroupFields("DataTable", FieldList);
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT 
	|	DataTable.CostGroupNumber
	|	,&TextOfSelectionField
	|INTO TT_CostGroups
	|FROM
	|	&DataTable AS DataTable
	|;
	|
	|/////////////////////////////////////////////////////
	|SELECT
	|	DataTable.CostGroupNumber
	|	,&TextOfSelectionField
	|FROM
	|	TT_CostGroups AS DataTable
	|;
	|
	|/////////////////////////////////////////////////////
	|SELECT
	|	MAX(TT_CostGroups.CostGroupNumber) AS CostGroupNumber
	|FROM
	|	TT_CostGroups AS TT_CostGroups";
	
	Query.Text = StrReplace(Query.Text, ",&TextOfSelectionField", TextOfSelectionField);
	If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		Query.SetParameter("DataTable", Object.References.Unload());
	Else
		Query.SetParameter("DataTable", Object.ManufacturedProducts.Unload());
	EndIf;
	Result = Query.ExecuteBatch();
	
	If TypeOf(CostGroups) = Type("ValueTable") Then
		For Each CurRow In Result[1].Unload() Do
			FillPropertyValues(CostGroups.Add(), CurRow);
		EndDo;
	Else
		CostGroups.Load(Result[1].Unload());
	EndIf;
	
	NumberOfCostGroups = CostGroups.Count();
	
	If Not Result[2].IsEmpty() Then
		Selection = Result[2].Select();
		Selection.Next();
		Object.MaximumNumberOfCostGroup = Selection.CostGroupNumber;
	EndIf;
	
	For Each CurGroup In CostGroups Do
		FillInServiceDetailsOfCostGroup(Object, CostGroups, CurGroup);
		FillInDependentServiceDetailsOfCostGroup(Object, CostGroups, CurGroup);
	EndDo;
	
EndProcedure

// Updates the document's cost group view
// 
// Parameters:
// 	Object - DocumentObject.SubcontractOrder2_5, Structure - object data
// 	CostGroups - ValueTable
//
Procedure UpdateCostGroupPresentation(Object, CostGroups) Export
	
	For Each CurGroup In CostGroups Do
		CurGroup.ExpenseGroup = CostGroupPresentation(CurGroup, Object.GroupCosts);
	EndDo;
	
EndProcedure

// Fills in the service details
// 
// Parameters:
// 	Object - DocumentObject.SubcontractOrder2_5, Structure - object data
// 	CostGroups - ValueTable
// 	CostGroupDescription - Structure
//
Procedure FillInServiceDetailsOfCostGroup(Object, CostGroups, CostGroupDescription) Export
	
	DescriptionOfCostGroupBeforeChange = Common.CopyRecursive(CostGroupDescription);
	CostGroupDescription.ProductTableName = "ManufacturedProducts";
	If ValueIsFilled(CostGroupDescription.Purpose) Then
		
		DataPurpose =
			Common.ObjectAttributesValues(
				CostGroupDescription.Purpose,
				"AssignmentType, LineOfBusiness, Partner, Contract, OrderDocument");
		
		CostGroupDescription.TollManufacturing =
			DataPurpose.AssignmentType = Enums.AssignmentTypes.Giveaway2_5;
		
	EndIf;
	If Not Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		If Object.SeparationOfMaterialsByProductPurpose
			And Not CostGroupDescription.TollManufacturing
			And ValueIsFilled(CostGroupDescription.Purpose) Then
			CostGroupDescription.SupplyAssignment = CostGroupDescription.Purpose;
		ElsIf CostGroupDescription.TollManufacturing Then
			DestinationTemplateMaterials = AssignmentTemplateGiverSMaterials(DataPurpose);
			CostGroupDescription.SupplyAssignment = Catalogs.Assignments.FindByTemplate(DestinationTemplateMaterials);
		Else
			CostGroupDescription.SupplyAssignment = Object.Purpose;
		EndIf;
	Else
		
		TheseOrders_ = OrderDataByCostGroupNumber(Object, CostGroupDescription.CostGroupNumber);
		FillPropertyValues(CostGroupDescription, TheseOrders_);
		
		If Not ProductionManagementClientServer.ThisIsAProductionIssueStage(TheseOrders_) Then
			CostGroupDescription.ProductTableName = "SideAndIntermediateRelease";
		EndIf;
		
	EndIf;
	If TypeOf(CostGroupDescription) = Type("Structure")
		And Not TMCommonUseClientServer.StructuresAreEqual(DescriptionOfCostGroupBeforeChange, CostGroupDescription) Then
		UpdateCostGroup(CostGroups, CostGroupDescription);
	EndIf;
	
EndProcedure

// Fills in the service details
// 
// Parameters:
// 	Object - DocumentObject.SubcontractOrder2_5, Structure - object data
// 	CostGroups - ValueTable
// 	CostGroupDescription - Structure
//
Procedure FillInDependentServiceDetailsOfCostGroup(Object, CostGroups, CostGroupDescription) Export
	
	If CostGroupDescription.CostGroupNumber = 0 Then
		Return;
	EndIf;
	
	DescriptionOfCostGroupBeforeChange = Common.CopyRecursive(CostGroupDescription);
	CostGroupDescription.AllProductLinesAreCancelled = AllCostGroupProductLinesAreCanceled(Object, CostGroupDescription);
	
	If TypeOf(CostGroupDescription) = Type("Structure")
		And Not TMCommonUseClientServer.StructuresAreEqual(DescriptionOfCostGroupBeforeChange, CostGroupDescription) Then
		UpdateCostGroup(CostGroups, CostGroupDescription);
	EndIf;
	
EndProcedure

// Presentation of the document cost group
// 
// Parameters:
// 	Group - Structure
// 	GroupCosts - EnumRef.CostGroupingsInTollingOrder
// Returns:
// 	String
//
Function CostGroupPresentation(Group, GroupCosts) Export
	
	Return ProcessingByThirdPartiesClientServer.CostGroupPresentation(
				Group,
				ProcessingByThirdPartiesClientServer.ListOfOrderCostGroupFieldsForProcessor(GroupCosts));
	
EndFunction

// Cost Group Table Constructor
// 
// Returns:
// 	ValueTable:
// * CostGroupNumber - Number
// * ExpenseGroup - String
// * BillOfMaterials - CatalogRef.BillsOfMaterials
// * Purpose - CatalogRef.Assignments
// * Products - CatalogRef.Products
// * Characteristic - CatalogRef.ItemsCharacteristics
// * ReferenceOrder - DocumentRef.ProductionStage2_2
// * MethodOfAllocatingFinishedProductCosts - EnumRef.MethodsOfCostAllocatingOnProductCosts
// * SupplyAssignment - CatalogRef.Assignments
// * ProductTableName - String
// * AllProductLinesAreCancelled - Boolean
//
Function CostGroupTable() Export
	
	CostGroups = New ValueTable;
	CostGroups.Columns.Add("CostGroupNumber",                New TypeDescription("Number"));
	CostGroups.Columns.Add("ExpenseGroup",                     New TypeDescription("String"));
	CostGroups.Columns.Add("BillOfMaterials",                     New TypeDescription("CatalogRef.BillsOfMaterials"));
	CostGroups.Columns.Add("Purpose",                       New TypeDescription("CatalogRef.Assignments"));
	CostGroups.Columns.Add("Products",                     New TypeDescription("CatalogRef.Products"));
	CostGroups.Columns.Add("Characteristic",                   New TypeDescription("CatalogRef.ItemsCharacteristics"));
	CostGroups.Columns.Add("ReferenceOrder",                     New TypeDescription("DocumentRef.ProductionStage2_2"));
	CostGroups.Columns.Add("Stage",                             New TypeDescription("CatalogRef.ProductionStages"));
	CostGroups.Columns.Add("TollManufacturing", New TypeDescription("Boolean"));
	CostGroups.Columns.Add(
		"MethodOfAllocatingFinishedProductCosts",
		New TypeDescription("EnumRef.MethodsOfCostAllocatingOnProductCosts"));
	
	CostGroups.Columns.Add("OrderDocument",                    New TypeDescription("DocumentRef.SubcontractOrder2_5"));
	CostGroups.Columns.Add("SupplyAssignment",    New TypeDescription("CatalogRef.Assignments"));
	CostGroups.Columns.Add("ProductTableName",        New TypeDescription("String"));
	CostGroups.Columns.Add("AllProductLinesAreCancelled", New TypeDescription("Boolean"));
	
	Return CostGroups;
	
EndFunction

// The request text of the document's cost group.
// 
// Parameters:
//  Ref - DocumentRef.SubcontractOrder2_5
//  TTName - String
// 
// Returns:
//  String - Request Text For The Document's Cost Group
Function RequestTextForDocumentSCostGroup(Ref = Undefined, TTName = Undefined) Export
	
	QueryText =
	"SELECT DISTINCT
	|	TabularSection.CostGroupNumber AS CostGroupNumber
	|	,TabularSection.ProductionStage AS ProductionStage
	|INTO CostGroupNumbers
	|FROM
	|	(SELECT
	|		TabularSection.CostGroupNumber AS CostGroupNumber
	|		,VALUE(Document.ProductionStage2_2.EmptyRef) AS ProductionStage
	|	FROM
	|		ManufacturedProducts AS TabularSection
	|	WHERE
	|		&FilterByReference_
	|		AND NOT TabularSection.CostGroupNumber = 0
	|		AND NOT &GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TabularSection.CostGroupNumber AS CostGroupNumber,
	|		TabularSection.ReferenceOrder AS ProductionStage
	|	FROM
	|		References AS TabularSection
	|	WHERE
	|		&FilterByReference_
	|		AND NOT TabularSection.CostGroupNumber = 0
	|		AND &GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|	) AS TabularSection
	|
	|INDEX BY
	|	CostGroupNumber
	|";
	
	FilterByReference_ = "TRUE";
	If Not Ref = Undefined Then
		FilterByReference_ = "TabularSection.Ref = &SubcontractOrder";
		QueryText = StrReplace(QueryText, "ManufacturedProducts", "Document.SubcontractOrder2_5.ManufacturedProducts");
		QueryText = StrReplace(QueryText, "References", "Document.SubcontractOrder2_5.References");
	EndIf;
	QueryText = StrReplace(QueryText, "&FilterByReference_", FilterByReference_);
	
	If ValueIsFilled(TTName) Then
		QueryText = StrReplace(QueryText, "INTO CostGroupNumbers", "INTO " + TTName);
	EndIf;
	
	Return QueryText;
	
EndFunction

// The text of the request "Imported document materials".
// 
// Returns:
//  String - Request Text TT Imported Document Materials
Function QueryTextTTImportedDocumentMaterials() Export
	
	QueryText =
	"SELECT
	|	TabularSection.CostGroupNumber		AS CostGroupNumber,
	|	TabularSection.Products				AS Products,
	|	TabularSection.Characteristic			AS Characteristic,
	|	MAX(CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN FALSE
	|		ELSE ISNULL(Goods.TracedGoods, FALSE)
	|	END)									AS Traceable
	|INTO TTImportedDocumentMaterials
	|FROM
	|	SupplyWithMaterialsAndWorks AS TabularSection
	|	
	|	LEFT JOIN Catalog.Products AS Goods
	|	ON TabularSection.Products = Goods.Ref
	|
	|WHERE
	|	ISNULL(Goods.KeepRecordsByCCD, FALSE)
	|	AND ISNULL(Goods.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) IN
	|			(VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.Work_5),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|GROUP BY
	|	TabularSection.CostGroupNumber,
	|	TabularSection.Products,
	|	TabularSection.Characteristic
	|
	|INDEX BY
	|	CostGroupNumber,
	|	Products,
	|	Characteristic
	|";
	
	Return QueryText;
	
EndFunction

// The text of the check "No imported material specified".
// 
// Returns:
//  String - Verification Text Omitted Imported Material
Function VerificationTextOmittedImportedMaterial() Export
	
	QueryText =
	"SELECT DISTINCT
	|	&NameOfMaterialsAndWorksTable					AS TableName,
	|	&SynonymTSMaterialsAndWorks					AS TSSynonym,
	|	0											AS LineNumber,
	|	ImportedProductsOfDocument.CostGroupNumber	AS CostGroupNumber,
	|	""ImportedMaterialNotSpecified""				AS TypeOfVerification
	|FROM
	|	TTImportedProducts AS ImportedProductsOfDocument
	|
	|WHERE
	|	&UseImportedGoods
	|	AND NOT ImportedProductsOfDocument.Traceable
	|	AND NOT ImportedProductsOfDocument.CostGroupNumber IN
	|			(SELECT
	|				ImportedDocumentMaterials.CostGroupNumber
	|			FROM
	|				TTImportedDocumentMaterials AS ImportedDocumentMaterials)
	|";
	
	Return QueryText;
	
EndFunction
#EndRegion

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	Return "Date";
	
EndFunction

// Returns parameters for specifying series for products specified in the document
//
//	Parameters:
//		Object - Structure - structure of object details values required for filling in parameters for specifying series
//	Returns:
//		See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = New Structure;
	
	#Region SupplyWithMaterialsAndWorks
	
	ParametersForSpecifyingTSSeries = ProductsClientServer.SeriesSpecificationParameters();
	
	ParametersForSpecifyingTSSeries.FullObjectName = FullObjectName();
	ParametersForSpecifyingTSSeries.NameTSGoods = "SupplyWithMaterialsAndWorks";
	ParametersForSpecifyingTSSeries.TSSeriesName  = "SupplyWithMaterialsAndWorks";
	
	ParametersForSpecifyingTSSeries.AdditionalFieldNames.Add("Warehouse");
	
	ParametersForSpecifyingTSSeries.UseItemsBatch  = GetFunctionalOption("UseItemsBatchWarehouse", New Structure());
	ParametersForSpecifyingTSSeries.UseCostAccountingByBatches = GetFunctionalOption("UseCostAccountingByBatchesWarehouse", New Structure());
	
	ParametersForSpecifyingTSSeries.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentToCustomer);
	
	ParametersForSpecifyingTSSeries.ThisIsOrder = True;
	ParametersForSpecifyingTSSeries.ShipmentPlanning = True;
	ParametersForSpecifyingTSSeries.RegisterSeries = False;
	
	ParametersForSpecifyingTSSeries.Date = Object.Date;
	
	SeriesSpecificationParameters.Insert("SupplyWithMaterialsAndWorks", ParametersForSpecifyingTSSeries);
	
	#EndRegion
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.Warehouse,
	|	Goods.Products,
	|	Goods.Series,
	|	Goods.Canceled,
	|	Goods.SupplyOption,
	|	Goods.Count,
	|	Goods.BatchesIndicationStatus,
	|	Goods.LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN Goods.Canceled
	|				OR BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|				OR NOT Goods.SupplyOption IN (
	|						VALUE(Enum.SupplyOptions.FromWarehouse),
	|						VALUE(Enum.SupplyOptions.Ship))
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					WHEN Goods.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
	|						THEN 15
	|					ELSE 13
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 10
	|					WHEN Goods.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
	|						THEN 11
	|					ELSE 9
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|			INNER JOIN Catalog.Warehouses AS Warehouses
	|			ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|		ON (BatchAccountingPolicies.Warehouse = Goods.Warehouse)
	|			AND CAST(Goods.Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber AS LineNumber,
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

#Region QualityControl

// Document parameters for the Attribute filling mechanism to check the quality and data confirmation of the quality
// in the document.
// 
// Parameters:
//  Object - DocumentObject.SubcontractOrder2_5 - Object.
// 
// Returns:
//  Structure - structure with fields:
// * Key - String - An identifier used when there are two or more data sources to fill in in the same object.
// * FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//
Function QualityControlActionParameters(Object) Export
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "");
	
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	
	ActionParameters.FullObjectName = "Document.SubcontractOrder2_5";
	ActionParameters.ReadableFields = "Products,Recipient,ToExpenseAs,DateOfReceipt,Canceled";
	ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
	
	ActionParameters.KeyDetailsOfHeader.Insert("WarehouseForReceipt", Object.ManufacturedProductsWarehouse);
	ActionParameters.KeyDetailsOfHeader.Insert("OneDateReceipt", Object.OneDateReceipt);
	
	ActionParameters.QueryOptions.QualityControlContract = Object.Contract;
	ActionParameters.QueryOptions.Insert("QualityControlLeaveProductWithProcessor", Object.LeaveProductsAtSubcontractor);
	ActionParameters.QueryOptions.Insert("QualityControlAdmissionByOneDate", Object.OneDateReceipt);
	ActionParameters.QueryOptions.Insert("QualityControlDateOfReceipt", Object.DateOfReceipt);
	
	ActionParameters.QueryTextDocumentData =
	"SELECT
	|	Table.IdOfTTRow AS IdOfTTRow,
	|	Table.Products AS Products,
	|	Table.Recipient AS Warehouse,
	|	&QualityControlContract AS Contract,
	|	CASE
	|		WHEN &QualityControlAdmissionByOneDate
	|			THEN &QualityControlDateOfReceipt
	|		ELSE Table.DateOfReceipt
	|	END AS DateOfReceipt,
	|	FALSE AS Set,
	|	Table.Canceled
	|		OR Table.ToExpenseAs
	|		OR &QualityControlLeaveProductWithProcessor AS Reset
	|INTO DataOfDocumentToBeFilledInCheckQualityDateOfQualityConfirmation
	|FROM
	|	#DataSource AS Table
	|
	|INDEX BY
	|	Products,
	|	Warehouse,
	|	Contract
	|";
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	Return Action_Parameters;
	
EndFunction

// Document parameters for the mechanism of filling in the Attributes of the controlled party in the document.
// 
// Parameters:
//  ObjectOrRef - DocumentObject.SubcontractOrder2_5, DocumentRef.SubcontractOrder2_5 - Document.
//  FieldNameControlledLotReference - String - field name, controlled Lot reference.
// 
// Returns:
//  See QualityControl.NewAttributesOfControlledLotReference
Function AttributesOfControlledLotReference(ObjectOrRef, FieldNameControlledLotReference) Export
	
	Attributes = QualityControl.NewAttributesOfControlledLotReference();
	ObjectAttributes = QualityControl.AttributesOfItemOrLink(ObjectOrRef,
		"Ref,
		|Partner,
		|Contract,
		|Date,
		|Number,
		|LineOfBusiness,
		|Counterparty,
		|Organization,
		|Department");
		
	Attributes.Lot = ObjectAttributes.Ref;
	Attributes.Partner = ObjectAttributes.Partner;
	Attributes.Contract = ObjectAttributes.Contract;
	Attributes.ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Attributes.LineOfBusiness = ObjectAttributes.LineOfBusiness;
	Attributes.Counterparty = ObjectAttributes.Counterparty;
	Attributes.ReceiptDocumentNumber = ObjectAttributes.Number;
	Attributes.DateOfReceiptDocument = ObjectAttributes.Date;
	Attributes.Organization = ObjectAttributes.Organization;
	Attributes.Department = ObjectAttributes.Department;
	
	// The Attributes for Registering Records according to the Accumulation register "Goods for receipt", when the Lot reference is known, for example, for return
	// without registration in the document "Quality control Act". The logic of filling in the fields is synchronized with the Registered Records of the current
	// document, as an order in "Goods for receipt".
	Attributes.Sender = ObjectAttributes.Partner;
	Attributes.BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5;
	
	Return Attributes;
	
EndFunction

#EndRegion

#Region References

// Transfers changes to the stage.
//
// Parameters:
//  OrderObject__ - DocumentObject.ProductionStage2_2
//  OrderData_3 - Structure - data of orders.
//
Procedure TransferChangesToOrder(OrderObject__, OrderData_3) Export
	
	OrderObject__.ProductionInOneDay  = OrderData_3.OrderDetailsForProcessor.OneDateReceipt;
	OrderObject__.ProductionDate        = OrderData_3.OrderDetailsForProcessor.DateOfReceipt;
	OrderObject__.NotShipInInstallments      = OrderData_3.OrderDetailsForProcessor.NotShipInInstallments;
	OrderObject__.DateOfShipment            = OrderData_3.OrderDetailsForProcessor.DateOfShipment;
	
	OrderObject__.LeaveProductsAtSubcontractor =
		OrderData_3.OrderDetailsForProcessor.LeaveProductsAtSubcontractor;
	
	TheStructureOfTheSearch = New Structure("Ref", OrderObject__.Ref);
	
	OrderObject__.ManufacturedProducts.Clear();
	FoundRows = OrderData_3.ManufacturedProducts.FindRows(TheStructureOfTheSearch);
	For Each CurRow In FoundRows Do
		FillPropertyValues(OrderObject__.ManufacturedProducts.Add(), CurRow);
	EndDo;
	
	OrderObject__.SideAndIntermediateRelease.Clear();
	FoundRows = OrderData_3.SideAndIntermediateRelease.FindRows(TheStructureOfTheSearch);
	For Each CurRow In FoundRows Do
		FillPropertyValues(OrderObject__.SideAndIntermediateRelease.Add(), CurRow);
	EndDo;
	
	OrderObject__.SupplyWithMaterialsAndWorks.Clear();
	FoundRows = OrderData_3.SupplyWithMaterialsAndWorks.FindRows(TheStructureOfTheSearch);
	For Each CurRow In FoundRows Do
		FillPropertyValues(OrderObject__.SupplyWithMaterialsAndWorks.Add(), CurRow);
	EndDo;
	
	OrderObject__.MaterialsAndWorksSets.Clear();
	FoundRows = OrderData_3.MaterialsAndWorksSets.FindRows(TheStructureOfTheSearch);
	For Each CurRow In FoundRows Do
		FillPropertyValues(OrderObject__.MaterialsAndWorksSets.Add(), CurRow);
	EndDo;
	
	FoundRows = OrderData_3.Attributes.FindRows(TheStructureOfTheSearch);
	If Not FoundRows.Count() = 0 Then
		StatusBeforeChange = OrderObject__.Status;
		If FoundRows[0].Status <> StatusBeforeChange Then
			OrderObject__.Status = FoundRows[0].Status;
			ProductionManagement.FillInStageDetailsWhenStatusChanges(OrderObject__, StatusBeforeChange);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

// Creates a representation of the metadata object in the main language.
// 
// Returns:
//	String - Representation of the metadata object in the main language.
//
Function PresentationOfObjectInMainLanguage() Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	ObjectPresentation = NStr(
		"vi = 'Đơn đặt hàng gia công';
		|ru = 'Заказ переработчику';
		|en = 'Subcontracting purchase order'; fa = 'سفارش خرید پیمانکاری فرعی';
		|it = 'Ordine al subfornitore';
		|pl = 'Zamówienie do przetwórcy';
		|tr = 'Fason satın alma siparişi'",
		DefaultLanguageCode);
		
	Return ObjectPresentation;
	
EndFunction

// The function returns the text of the query to determine the details of the delivery.
//
// Returns:
//	String - Query text
//
Function QueryTextDeliveryDetails_() Export
	
	QueryText =
	"SELECT
	|	Header.Number             AS Number,
	|	Header.Posted          AS Posted,
	|	Header.Ref            AS Ref,
	|	Header.Date              AS Date,
	|	Header.Partner           AS RecipientSender,
	|	Header.CarrierPartner AS Carrier,
	|	CASE WHEN Header.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|			AND NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|		THEN VALUE(Enum.TransportMethods.SelfPickup)
	|		ELSE Header.DeliveryMethod
	|	END                   AS DeliveryMethod,
	|	Header.DeliveryZone      AS Zone,
	|	Header.DeliveryAddress     AS Address,
	|	Header.DeliveryAddressFieldValues
	|		                    AS FieldValueAddress,
	|	Header.DeliveryTimeFrom    AS TimeFrom,
	|	Header.DeliveryTimeTo   AS TimeTo,
	|	Header.AdditionalDeliveryInformation
	|		                    AS AdditionalInformation,
	|	T.Warehouse                 AS Warehouse,
	|	T.DeliverFully    AS DeliverFully,
	|	Header.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	Header.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	FALSE AS SplitGoodsIssueNotesByReferences
	|
	|FROM
	|	(SELECT
	|		T.Ref AS Ref,
	|		T.Warehouse AS Warehouse,
	|		MIN(CASE
	|				WHEN T.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|					THEN TRUE
	|				ELSE FALSE
	|			END) AS DeliverFully
	|	FROM
	|		Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks AS T
	|	WHERE
	|		T.Ref IN (&References)
	|	
	|	GROUP BY
	|		T.Ref,
	|		T.Warehouse
	|
	|	HAVING
	|		MAX(CASE
	|				WHEN T.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|					THEN TRUE
	|			END) = TRUE
	|
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentOrderDocument.Ref AS Ref,
	|		T.Warehouse AS Warehouse,
	|		MIN(CASE
	|				WHEN T.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|					THEN TRUE
	|				ELSE FALSE
	|			END) AS DeliverFully
	|	FROM
	|		Document.SubcontractOrder2_5 AS DocumentOrderDocument
	|			INNER JOIN Document.ProductionStage2_2 OneStageTable
	|			ON OneStageTable.SubcontractOrder = DocumentOrderDocument.Ref
	|			INNER JOIN Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS T
	|			ON T.Ref = OneStageTable.Ref
	|	WHERE
	|		DocumentOrderDocument.Ref IN (&References)
	|		AND NOT T.Canceled
	|	
	|	GROUP BY
	|		DocumentOrderDocument.Ref,
	|		T.Warehouse
	|	
	|	HAVING
	|		MAX(CASE
	|				WHEN T.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|					THEN TRUE
	|			END) = TRUE
	|	) AS T
	|		INNER JOIN Document.SubcontractOrder2_5 AS Header
	|		ON (Header.Ref = T.Ref)";
	
	Return QueryText;
	
EndFunction

// This function determines the details of the selected document
//
// Parameters:
//	DocumentRef - DocumentRef.SubcontractOrder2_5 - link to the document.
//
// Returns:
//	Structure - details of the selected document.
//
Function DocumentAttributes(DocumentRef) Export
	
	Query = New Query("
	|SELECT
	|	DocumentData.Date                  AS Date,
	|	DocumentData.Organization           AS Organization,
	|	DocumentData.Partner               AS Partner,
	|	DocumentData.Counterparty            AS Counterparty,
	|	DocumentData.Currency                AS Currency,
	|	DocumentData.Currency                AS ARAPCurrency,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.DocumentAmount        AS DocumentAmount,
	|	DocumentData.Posted              AS Posted,
	|	DocumentData.Contract               AS Contract,
	|	DocumentData.ARAPObjectSettings       AS ARAPObjectSettings,
	|	DocumentData.DocumentAmount        AS AmountARAP
	|
	|FROM
	|	Document.SubcontractOrder2_5 AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentRef
	|");
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Date                  = Selection.Date;
		Organization           = Selection.Organization;
		Partner               = Selection.Partner;
		Counterparty            = Selection.Counterparty;
		Contract               = Selection.Contract;
		ARAPObjectSettings       = Selection.ARAPObjectSettings;
		Currency                = Selection.Currency;
		ARAPCurrency  = Selection.ARAPCurrency;
		BusinessOperation = ?(ValueIsFilled(Selection.BusinessOperation), 
													Selection.BusinessOperation, 
													Enums.BusinessTransactions.ProductionByToller2_5);
		DocumentAmount        = Selection.DocumentAmount;
		AmountARAP   = Selection.AmountARAP;
	Else
		Date                  = Date(1,1,1);
		Organization           = Catalogs.Companies.EmptyRef();
		Partner               = Catalogs.Partners.EmptyRef();
		Counterparty            = Catalogs.Counterparties.EmptyRef();
		Contract               = Catalogs.CounterpartyContracts.EmptyRef();
		ARAPObjectSettings       = Enums.ARAPObjectSettings.EmptyRef();
		Currency                = Catalogs.Currencies.EmptyRef();
		ARAPCurrency  = Catalogs.Currencies.EmptyRef();
		BusinessOperation = Enums.BusinessTransactions.ProductionByToller2_5;
		DocumentAmount        = 0;
		AmountARAP   = 0;
	EndIf;
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Date", Date);
	AttributesStructure1.Insert("Organization", Organization);
	AttributesStructure1.Insert("Partner", Partner);
	AttributesStructure1.Insert("Counterparty", Counterparty);
	AttributesStructure1.Insert("Contract", Contract);
	AttributesStructure1.Insert("ARAPObjectSettings", ARAPObjectSettings);
	AttributesStructure1.Insert("Currency", Currency);
	AttributesStructure1.Insert("ARAPCurrency", ARAPCurrency);
	AttributesStructure1.Insert("BusinessOperation", BusinessOperation);
	AttributesStructure1.Insert("DocumentAmount", DocumentAmount);
	AttributesStructure1.Insert("AmountARAP", AmountARAP);
	
	Return AttributesStructure1;

EndFunction

// Calculates the current status of the order to the processor
//
// Parameters:
//	SubcontractOrder      - DocumentRef.SubcontractOrder2_5 - Document whose state needs to be calculated
//	Contract                 - CatalogRef.CounterpartyContracts - Contract with the supplier
//	StateOfCalculations       - ClientApplicationForm - The form in which the calculated state will be placed.
//
Procedure CalculateStatus(Val SubcontractOrder,
	                          Val Contract,
	                          StateOfCalculations) Export
	
	FillPropertyValues(StateOfCalculations, StructureOfStateOfCalculations());
	
	If ValueIsFilled(SubcontractOrder) And AccessRight("Read", Metadata.AccumulationRegisters.VendorsARAPAccounting) Then

		QueryText = RequestTextForCalculatingOrderStates();
		QueryText = StrReplace(
						QueryText,
						"ARAPObject IN (SELECT ARAPObject FROM ARAPObjects)",
						"ARAPObject = &ARAPObject");

		Query = New Query;
		Query.Text = QueryText;
		
		AnArrayOfOrders  = New Array;
		AnArrayOfOrders.Add(SubcontractOrder);
		
		ARAPObject = Common.ObjectAttributeValue(SubcontractOrder, "ARAPObject");
		
		Query.SetParameter("AnArrayOfOrders"	,				AnArrayOfOrders);
		Query.SetParameter("ARAPObject",					ARAPObject);
		Query.SetParameter("CurrentDate",					BegOfDay(CurrentSessionDate()));
		
		SetPrivilegedMode(True);
		Selection = Query.Execute().Select();
		Selection.Next();
		
		FillPropertyValues(StateOfCalculations, Selection);
		
	EndIf;
	
EndProcedure

// The function returns the text of the query to calculate the order status.
//
// Returns:
//	String - Query text
//
Function RequestTextForCalculatingOrderStates() Export
	
	QueryText =
	"SELECT 
	// NOT CARRIED OUT /////////////////////////////////////////////////////////////
	|	CASE WHEN NOT OrderDocument.Posted THEN
	|		UNDEFINED
	// APPROVAL IS EXPECTED //////////////////////////////////////////////////
	|	WHEN OrderDocument.Status = VALUE(Enum.TollingOrderStatuses.NotApproved) THEN
	|		VALUE(Enum.PurchaseOrderStates.PendingApproval)
	// AN ADVANCE PAYMENT IS EXPECTED BEFORE CONFIRMATION /////////////////////////////////////////
	|	WHEN OrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
	|			AND (OrderDocument.Status = VALUE(Enum.TollingOrderStatuses.NotApproved) OR &DonTUseOrderStatuses)
	|			AND OrderDocument.AmountAdvanceBeforeConfirmation > 0
	|			AND ISNULL(VendorsARAPAccountingBalance.AmountDueReceipt, 0) < OrderDocument.AmountAdvanceBeforeConfirmation THEN
	|		VALUE(Enum.PurchaseOrderStates.PendingAdvanceBeforeConfirmation)
	// CONFIRMATION IS EXPECTED //////////////////////////////////////////////////
	|	WHEN OrderDocument.Status = VALUE(Enum.TollingOrderStatuses.NotApproved)
	|			AND OrderDocument.DocumentAmount > 0
	|			AND (ISNULL(VendorsARAPAccountingBalance.AmountDueReceipt, 0) >= OrderDocument.AmountAdvanceBeforeConfirmation
	|				OR OrderDocument.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)) THEN
	|		VALUE(Enum.PurchaseOrderStates.PendingConfirmation)
	// PREPAYMENT IS EXPECTED BEFORE RECEIPT //////////////////////////////////////
	|	WHEN OrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
	|			AND (&DonTUseOrderStatuses
	|				OR OrderDocument.Status = VALUE(Enum.TollingOrderStatuses.ForFulfillment))
	|			AND OrderDocument.PrepaymentAmountBeforeReceipt > 0
	|			AND ISNULL(VendorsARAPAccountingBalance.AmountDueReceipt, 0) < OrderDocument.PrepaymentAmountBeforeReceipt + OrderDocument.AmountAdvanceBeforeConfirmation THEN
	|		VALUE(Enum.PurchaseOrderStates.PendingPrepaymentBeforePurchase)
	// READY FOR ADMISSION //////////////////////////////////////////////////////
	|	WHEN OrderDocument.Status = VALUE(Enum.TollingOrderStatuses.ForFulfillment)
	|			AND OrderDocument.DocumentAmount > 0
	|			AND (ISNULL(VendorsARAPAccountingBalance.AmountDueReceipt, 0) >= OrderDocument.PrepaymentAmountBeforeReceipt + OrderDocument.AmountAdvanceBeforeConfirmation
	|				OR OrderDocument.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)) THEN
	|		VALUE(Enum.PurchaseOrderStates.ReadyForReceipt)
	// EXPECTED RECEIPT //////////////////////////////////////////////////////
	|	WHEN OrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
	|			AND (OrderDocument.Status = VALUE(Enum.TollingOrderStatuses.ForFulfillment) OR &DonTUseOrderStatuses)
	|			AND OrderDocument.DocumentAmount > 0
	|			AND ISNULL(VendorsARAPAccountingBalance.AmountDueReceipt, 0) >= OrderDocument.PrepaymentAmountBeforeReceipt + OrderDocument.AmountAdvanceBeforeConfirmation
	|			AND ISNULL(VendorsARAPAccountingBalance.ToReceiveClosingBalance, 0) > 0 THEN
	|		VALUE(Enum.PurchaseOrderStates.PendingReceipt)
	// PAYMENT IS EXPECTED ////////////////////////////////////////////////////////
	|	WHEN OrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
	|			AND (OrderDocument.Status = VALUE(Enum.TollingOrderStatuses.ForFulfillment) OR &DonTUseOrderStatuses)
	|			AND OrderDocument.DocumentAmount - OrderDocument.AmountAdvanceBeforeConfirmation - OrderDocument.PrepaymentAmountBeforeReceipt > 0
	|			AND ISNULL(VendorsARAPAccountingBalance.AmountDueClosingBalance, 0) < 0 THEN
	|		VALUE(Enum.PurchaseOrderStates.PendingPaymentAfterReceipt)
	// READY TO CLOSE ////////////////////////////////////////////////////////
	|	WHEN OrderDocument.Status <> VALUE(Enum.TollingOrderStatuses.Closed) THEN
	|		VALUE(Enum.PurchaseOrderStates.ReadyForClosure)
	// unopened //////////////////////////////////////////////////////////////////
	|	WHEN OrderDocument.Status = VALUE(Enum.TollingOrderStatuses.Closed) OR &DonTUseOrderStatuses THEN
	|		VALUE(Enum.PurchaseOrderStates.Closed)
	|	END AS State,
	// NOT CARRIED OUT /////////////////////////////////////////////////////////////
	|	CASE WHEN NOT OrderDocument.Posted THEN
	|		FALSE
	// unopened //////////////////////////////////////////////////////////////////
	|	WHEN OrderDocument.Status = VALUE(Enum.TollingOrderStatuses.Closed) AND NOT &DonTUseOrderStatuses THEN
	|		FALSE
	// APPROVAL IS OVERDUE /////////////////////////////////////////////////
	|	WHEN OrderDocument.Status = VALUE(Enum.TollingOrderStatuses.NotApproved) THEN
	|		FALSE
	// THE ADVANCE PAYMENT IS OVERDUE BEFORE CONFIRMATION ////////////////////////////////////////
	|	WHEN OrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
	|			AND (OrderDocument.Status = VALUE(Enum.TollingOrderStatuses.NotApproved) OR &DonTUseOrderStatuses)
	|			AND OrderDocument.AmountAdvanceBeforeConfirmation > 0
	|			AND ISNULL(VendorsARAPAccountingBalance.AmountDueReceipt, 0) < OrderDocument.AmountAdvanceBeforeConfirmation
	|			AND SettlementsWithSuppliersBalancesAsOfDate.AmountDueBalance < 0 THEN
	|		TRUE
	// CONFIRMATION EXPIRED ////////////////////////////////////////////////
	|	WHEN OrderDocument.Status = VALUE(Enum.TollingOrderStatuses.NotApproved)
	|			AND OrderDocument.DocumentAmount > 0
	|			AND OrderDocument.DateOfFirstReceipt <> DATETIME(1,1,1)
	|			AND OrderDocument.DateOfFirstReceipt  < &CurrentDate
	|			AND (ISNULL(VendorsARAPAccountingBalance.AmountDueReceipt, 0) >= OrderDocument.AmountAdvanceBeforeConfirmation
	|				OR OrderDocument.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)) THEN
	|		TRUE
	// OVERDUE PREPAYMENT BEFORE RECEIPT ////////////////////////////////////
	|	WHEN OrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
	|			AND (&DonTUseOrderStatuses
	|				OR OrderDocument.Status = VALUE(Enum.TollingOrderStatuses.ForFulfillment))
	|			AND OrderDocument.PrepaymentAmountBeforeReceipt > 0
	|			AND ISNULL(VendorsARAPAccountingBalance.AmountDueReceipt, 0) < OrderDocument.PrepaymentAmountBeforeReceipt + OrderDocument.AmountAdvanceBeforeConfirmation
	|			AND SettlementsWithSuppliersBalancesAsOfDate.AmountDueBalance < 0 THEN
	|		TRUE
	// OVERDUE EXPECTED RECEIPT ////////////////////////////////////////
	|	WHEN OrderDocument.Status = VALUE(Enum.TollingOrderStatuses.ForFulfillment)
	|			AND OrderDocument.DateOfFirstReceipt <> DATETIME(1,1,1)
	|			AND OrderDocument.DateOfFirstReceipt  < &CurrentDate
	|			AND (ISNULL(VendorsARAPAccountingBalance.AmountDueReceipt, 0) >= OrderDocument.PrepaymentAmountBeforeReceipt + OrderDocument.AmountAdvanceBeforeConfirmation
	|				OR OrderDocument.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)) THEN
	|		TRUE
	// OVERDUE RECEIPT //////////////////////////////////////////////////
	|	WHEN OrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
	|			AND (OrderDocument.Status = VALUE(Enum.TollingOrderStatuses.ForFulfillment) OR &DonTUseOrderStatuses)
	|			AND ISNULL(VendorsARAPAccountingBalance.AmountDueReceipt, 0) >= OrderDocument.PrepaymentAmountBeforeReceipt + OrderDocument.AmountAdvanceBeforeConfirmation
	|			AND ISNULL(SettlementsWithSuppliersBalancesAsOfDate.ToReceiveBalance, 0) > 0 THEN
	|		TRUE
	// OVERDUE PAYMENT ///////////////////////////////////////////////////////
	|	WHEN OrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
	|			AND (OrderDocument.Status = VALUE(Enum.TollingOrderStatuses.ForFulfillment) OR &DonTUseOrderStatuses)
	|			AND OrderDocument.DocumentAmount - OrderDocument.AmountAdvanceBeforeConfirmation - OrderDocument.PrepaymentAmountBeforeReceipt > 0
	|			AND ISNULL(VendorsARAPAccountingBalance.AmountDueClosingBalance, 0) < 0
	|			AND SettlementsWithSuppliersBalancesAsOfDate.AmountDueBalance < 0 THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS StateOverdue,
	// PAYMENT AMOUNT /////////////////////////////////////////////////////////////
	|	CASE WHEN OrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
	|			AND OrderDocument.BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|			AND OrderDocument.Posted
	|			AND OrderDocument.DocumentAmount > 0 THEN
	|		CAST (ISNULL(VendorsARAPAccountingBalance.AmountDueReceipt, 0) AS NUMBER(31,2))
	|	ELSE
	|		0
	|	END AS PayAmount,
	// PERCENTAGE OF PAYMENT ///////////////////////////////////////////////////////////
	|	CASE WHEN OrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
	|			AND OrderDocument.BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|			AND OrderDocument.Posted
	|			AND OrderDocument.DocumentAmount > 0 THEN
	|		CAST (ISNULL(VendorsARAPAccountingBalance.AmountDueReceipt, 0) * 100 / OrderDocument.DocumentAmount AS NUMBER(15, 0))
	|	ELSE
	|		0
	|	END AS PayPercentage,
	// AMOUNT OF OVERDUE PAYMENT ////////////////////////////////////////////////
	|	CASE WHEN OrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
	|			AND OrderDocument.Posted
	|			AND OrderDocument.DocumentAmount > 0
	|			AND ISNULL(SettlementsWithSuppliersBalancesAsOfDate.AmountDueBalance, 0) < 0 THEN
	|		CAST (-ISNULL(SettlementsWithSuppliersBalancesAsOfDate.AmountDueBalance, 0) AS NUMBER(31,2))
	|	ELSE
	|		0
	|	END AS LatePaymentAmount,
	// RECEIPT AMOUNT ////////////////////////////////////////////////////////
	|	CASE WHEN OrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
	|			AND OrderDocument.Posted
	|			AND OrderDocument.DocumentAmount > 0 THEN
	|		ISNULL(VendorsARAPAccountingBalance.ToReceiveExpense, 0)
	|	ELSE
	|		0
	|	END AS OrderReceiptAmount,
	// PERCENTAGE OF RECEIPT //////////////////////////////////////////////////////
	|	CASE WHEN OrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
	|			AND OrderDocument.Posted
	|			AND OrderDocument.DocumentAmount > 0 THEN
	|		CAST(ISNULL(VendorsARAPAccountingBalance.ToReceiveExpense, 0) * 100 / OrderDocument.DocumentAmount AS NUMBER(15, 0))
	|	ELSE
	|		0
	|	END AS PercentageOfOrderReceipt,
	// DEBT (+ WE ARE OWED, - WE MUST)//////////////////////////////////////////
	|	CASE WHEN OrderDocument.Posted
	|			AND (OrderDocument.DocumentAmount > 0
	|				OR OrderDocument.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)) THEN
	|		CAST (ISNULL(VendorsARAPAccountingBalance.SumClosingBalance, 0) AS NUMBER(31,2))
	|	ELSE
	|		0
	|	END AS AmountOfDebt,
	|	CASE WHEN OrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
	|			AND OrderDocument.Posted
	|			AND OrderDocument.DocumentAmount > 0 THEN
	|		CAST( (	CASE WHEN ISNULL(VendorsARAPAccountingBalance.SumClosingBalance, 0) > 0 THEN
	|						ISNULL(VendorsARAPAccountingBalance.SumClosingBalance, 0)
	|					ELSE
	|						ISNULL(-VendorsARAPAccountingBalance.SumClosingBalance, 0)
	|					END * 100 / OrderDocument.DocumentAmount ) AS NUMBER(15, 0))
	|	ELSE
	|		0
	|	END AS DebtPercentage,
	|CASE
	|	WHEN
	|		OrderDocument.Posted AND
	|		OrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
	|	THEN
	|		-VendorsARAPAccountingBalance.AmountDueClosingBalance
	|	ELSE
	|		0
	|END AS AmountToPay,
	//LINK TO THE ORDER///////////////////////////////////////////////////////
	|OrderDocument.Ref AS OrderDocument
	|FROM
	|	Document.SubcontractOrder2_5 AS OrderDocument
	|	LEFT JOIN
	|		AccumulationRegister.VendorsARAPAccounting.BalanceAndTurnovers(,,,,&FilterARAPObject) AS VendorsARAPAccountingBalance
	|	ON
	|		TRUE
	|	LEFT JOIN
	|		AccumulationRegister.VendorsARAPAccounting.Balance(ENDOFPERIOD(&CurrentDate, DAY), &FilterARAPObject) AS SettlementsWithSuppliersBalancesAsOfDate
	|	ON
	|		TRUE
	|WHERE
	|	OrderDocument.Ref IN(&AnArrayOfOrders)
	|";

	QueryText = StrReplace(
					QueryText,
					"&DonTUseOrderStatuses",
					?(GetFunctionalOption("UseTollingOrderStatuses2_5"), "FALSE", "TRUE"));
					
	QueryText = StrReplace(
					QueryText,
					"&FilterARAPObject",
					"ARAPObject IN (SELECT ARAPObject FROM ARAPObjects)");
	
	Return QueryText

EndFunction

// Initializes the status structure of the document
// 
// Returns:
// 		Structure - The structure of the document execution status.
//
Function StructureStateOfDocumentExecution() Export
	
	StructureState = Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState();
	
	StructureState.Insert("DisplayCalculationsWithSuppliersTable", 1);
	StructureState.Insert("OutputTablesSupply", 2);
	StructureState.Insert("DisplayShipmentTables", 3);
	StructureState.Insert("DisplayReceiptTables", 4);
	StructureState.Insert("DisplayProductsForProcessingTableInReportToProcessor_", 5);
	StructureState.Insert("DisplayTablesCanceledShipment", 6);
	StructureState.Insert("DisplayTablesCanceledReceipt", 7);
	StructureState.Insert("DisplayRawMaterialsTableAtProcessor_", 8);
	StructureState.Insert("ThisIsOrder", True);
	StructureState.Insert("ThereAreReasonsForCancelingAdmission", GetFunctionalOption("UseReasonsForPurchaseOrderCancellations"));
	StructureState.Insert("NameTSGoodsShipment", "SupplyWithMaterialsAndWorks");
	StructureState.Insert("NameTSGoodsArrival", "ManufacturedProducts");
	StructureState.Insert("ThereAreSummaryShipmentIndicators", False);
	StructureState.Insert("TextProductServiceShipment", NStr("vi = 'Nguyên vật liệu và công việc';
															|ru = 'Материалы и работы';
															|en = 'Materials and works'; fa = 'Materials and works';
															|it = 'Materiali e lavori';
															|pl = 'Materiały i prace';
															|tr = 'Malzemeler ve işler'"));
	StructureState.Insert("TextProductServiceReceipt", NStr("vi = 'Sản phẩm và phế liệu thu hồi';
															|ru = 'Продукция и возвратные отходы';
															|en = 'Products and recyclable waste'; fa = 'Products and recyclable waste';
															|it = 'Prodotti e scarti riciclabili';
															|pl = 'Wiersze pozycji i odpady i półprodukty';
															|tr = 'İmal edilen ürünler ve geri dönüştürülebilir atıklar'"));
	StructureState.Insert("TextCanceledShipment", NStr("vi = 'Đã hủy giao nguyên vật liệu (%1%)';
														|ru = 'Отменена отгрузка сырья и материалов (%1%)';
														|en = 'Shipment of raw and consumable materials is canceled (%1%)'; fa = 'Shipment of raw and consumable materials is canceled (%1%)';
														|it = 'Spedizione di materie prime annullata (%1%)';
														|pl = 'Anulowano wysyłkę materiałów (%1%)';
														|tr = 'Hammadde ve malzeme sevkiyatı iptal edildi (%1%)'"));
	StructureState.Insert("TextCanceledReceipt", NStr("vi = 'Đã hủy xuất xưởng (%1%)';
														|ru = 'Отменен выпуск (%1%)';
														|en = 'Release is canceled (%1%)'; fa = 'Release is canceled (%1%)';
														|it = 'Pubblicazione annullata (%1%)';
														|pl = 'Anulowano wyprodukowanie (%1%)';
														|tr = 'Ürün çıkışı iptal edildi (%1%)'"));
	
	StructureState.Insert("SuffixOfTemplateForProductsTableInReportToProcessor", "2_5");
	StructureState.Insert("SuffixOfTemplateTableRawMaterialsAtProcessor", "2_5");
	
	StructureOfAdditionalRequests = New Structure;
	StructureOfAdditionalRequests.Insert("QueryTextTTGoodsOrdersArrivalOrder", QueryTextTTGoodsOrdersArrivalOrder());
	StructureOfAdditionalRequests.Insert("QueryTextTableCanceledReceipt", QueryTextTableCanceledReceipt());
	StructureOfAdditionalRequests.Insert("QueryTextTableProductsToBeProcessedInReportToProcessor", QueryTextTableProductsToBeProcessedInReportToProcessor());
	StructureOfAdditionalRequests.Insert("TableRawMaterialsAtProcessor", TableRawMaterialsAtProcessor());
	StructureOfAdditionalRequests.Insert("QueryTextTableSupplyState", QueryTextTableSupplyState());
	StructureState.Insert("StructureOfAdditionalRequests", StructureOfAdditionalRequests);
	
	StructureState.Insert("ActionDecryptionQuantityShipped", "ShowDocumentsOfTransferOfRawMaterialsToProcessor2_5");
	StructureState.Insert("ActionDecryptionQuantityReceived", "ShowDocumentsReceivedFromProcessor2_5");
	
	Return StructureState;
	
EndFunction

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export

	Documents.TransferOfGoodsToBailee.AddCreateBasedOnOrderToProcessorCommand(GenerationCommands);
	
	Command = Documents.ReceiptOfGoodsFromCustodian.AddCreateCommandBasedOnReceiptFromProcessor(GenerationCommands);
	If Not Command = Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"LeaveProductsAtSubcontractor",
			False);
	EndIf;
	
	Documents.SubcontractorReport2_5.AddGenerateCommand(GenerationCommands);
	
	Documents.ReceiptOfGoodsFromCustodian.AddCreateCommandBasedOnReturnFromProcessor(GenerationCommands);
	
	Documents.IssuedLetterOfAuthority.AddGenerateCommand(GenerationCommands);
	
	Documents.PurchaseOrder.AddCreateSecuringOrderCommand(GenerationCommands);
	
	Command = Documents.InventoryAssignmentAdjustment.AddGenerateCommand(GenerationCommands);
	If Not Command = Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"GroupCosts",
			Enums.CostGroupingsInTollingOrder.ByProductionStages,
			DataCompositionComparisonType.NotEqual);
	EndIf;
	
	Command = Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	If Not Command = Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"ProcessingServices",
			Enums.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder);
	EndIf;
	
	Command = Documents.CashVoucher.AddGenerateCommand(GenerationCommands);
	If Not Command = Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"ProcessingServices",
			Enums.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder);
	EndIf;
	
	Command = Documents.BankAccountIssue.AddGenerateCommand(GenerationCommands);
	If Not Command = Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"ProcessingServices",
			Enums.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder);
	EndIf;
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.GoodsIssueNote.AddCommandToCreateSpendingOrderForGoodsBasedOnIt(GenerationCommands);
	
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	
	Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	
	Command = Documents.VendorInvoiceServicesAndAssets.AddGenerateCommand(GenerationCommands);
	If Not Command = Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"ProcessingServices",
			Enums.OptionsOfRegisteringProcessingDocumentServices.RegisteredSeparately);
	EndIf;
	Command = Documents.MaterialProviderOrder2_5.AddCreateBasedOnOrderToProcessorCommand(GenerationCommands);
EndProcedure

// Adds a command to create a document "Order processor".
// 
// Parameters:
// 	GenerationCommands - See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject.Commands
// Returns:
// 	ValueTableRow
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.SubcontractOrder2_5) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.SubcontractOrder2_5.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.SubcontractOrder2_5);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseSubcontractOrders2_5";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds a command to create a document "Order processor".
//
// Parameters:
//  GenerationCommands - See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject.Commands
// Returns:
//  ValueTableRow, Undefined - description of the added command.
//
Function AddCreateSecuringOrderCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.SubcontractOrder2_5) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.SubcontractOrder2_5.FullName();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateSecuringOrder";
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.SubcontractOrder2_5);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseSubcontractOrders2_5";
		CreationParameters = ProvisionInDocumentsServer.ParametersForCreatingSecuringOrder(CreateBasedOnCommand.AdditionalParameters);
		
		CreationParameters.NameOfDocumentManager = "SubcontractOrder2_5";
		CreationParameters.FormName = "Document.SubcontractOrder2_5.ObjectForm";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Creation parameters based on the providing order.
// Returns:
// See ProvisionInDocumentsServer.ProductSelectionParametersForCreatingSecuringOrder
Function CreationParametersBasedOnProvidingOrder() Export
	
	ProductTableParameters = ProvisionInDocumentsServer.ProductSelectionParametersForCreatingSecuringOrder();
	ProductTableParameters.ItemsTypes.Add(Enums.ItemsTypes.OwnGoods);
	ProductTableParameters.ItemsTypes.Add(Enums.ItemsTypes.ReusablePackage);
	ProductTableParameters.ItemsTypes.Add(Enums.ItemsTypes.Work_5);
	ProductTableParameters.OneWarehouse = True;
	
	Return ProductTableParameters;
	
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithSupplier_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm";
	EndIf;
	
	Reports.ControlOfRawAndConsumableMaterialsDeliveryToToller2_5.AddReportCommand(ReportsCommands);
	
	Reports.ProductsDeliveryControlByToller2_5.AddReportCommand(ReportsCommands);
	
	ReportCommand = ARAPAccountingServer.IndebtednessToSuppliers_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm";
	EndIf;
	
	// Job
	ReportCommand = Reports.DocumentFulfillmentStatus.AddOrderFulfillmentStateCommandToHandler(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Order = 1;
	EndIf;
	
	ReportCommand = ARAPAccountingServer.IndebtednessToSuppliers_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "Workplace";
		ReportCommand.Importance = "Ordinary";
		ReportCommand.Order = 1;
	EndIf;
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithSupplier_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "Workplace";
		ReportCommand.Importance = "Ordinary";
		ReportCommand.Order = 2;
	EndIf;
	
EndProcedure

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	#Region WithoutOrders
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "Object.SupplyWithMaterialsAndWorks.Purpose");
	DestinationPattern.TermsOfUse_    = "Object.GroupCosts <> VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)";
	DestinationPattern.LineOfBusiness = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Own);
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Giveaway2_5);
	#Region ManufacturedProducts
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "Object.ManufacturedProducts.Purpose");
	DestinationPattern.TermsOfUse_    = "Object.GroupCosts <> VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)";
	DestinationPattern.LineOfBusiness = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Own);
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Giveaway2_5);
	// Needs for products in stock.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.ManufacturedProducts.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.ManufacturedProducts.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
											|AND Object.GroupCosts <> VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
											|";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.ManufacturedProducts.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.ManufacturedProducts.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.ManufacturedProducts.Recipient";
	
	// The needs for the work performed in the recipient unit.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "FulfillOrdersWithWorks", True, "Object.ManufacturedProducts.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.ManufacturedProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
											|AND Object.GroupCosts <> VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
											|";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.ManufacturedProducts.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.ManufacturedProducts.Characteristic";
	DescriptionOfColumns.DataPaths.Department    = "Object.ManufacturedProducts.Recipient";
	
	// Product needs in all warehouses.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "SecuringOrdersAllWarehouses", True, "Object.ManufacturedProducts.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.ManufacturedProducts.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
											|AND Object.GroupCosts <> VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
											|";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.ManufacturedProducts.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.ManufacturedProducts.Characteristic";
	
	#EndRegion
	
	#Region SideAndIntermediateRelease
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "Object.SideAndIntermediateRelease.Purpose");
	DestinationPattern.TermsOfUse_    = "Object.GroupCosts <> VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)";
	DestinationPattern.LineOfBusiness = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Own);
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Giveaway2_5);
	// The need for returnable waste in the warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.SideAndIntermediateRelease.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.SideAndIntermediateRelease.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
											|AND Object.GroupCosts <> VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
											|";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.SideAndIntermediateRelease.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.SideAndIntermediateRelease.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.SideAndIntermediateRelease.Recipient";
	
	// The need for returnable work in the recipient unit.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "FulfillOrdersWithWorks", True, "Object.SideAndIntermediateRelease.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.SideAndIntermediateRelease.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
											|AND Object.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
											|";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.SideAndIntermediateRelease.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.SideAndIntermediateRelease.Characteristic";
	DescriptionOfColumns.DataPaths.Department    = "Object.SideAndIntermediateRelease.Recipient";
	
	// Product needs in all warehouses.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "SecuringOrdersAllWarehouses", True, "Object.SideAndIntermediateRelease.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.SideAndIntermediateRelease.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
											|AND Object.GroupCosts <> VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
											|";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.SideAndIntermediateRelease.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.SideAndIntermediateRelease.Characteristic";
	
	#EndRegion
	
	#EndRegion
	#Region ByReferences
	
	#Region SupplyWithMaterialsAndWorks
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "Object.SupplyWithMaterialsAndWorks.SupplyAssignment");
	DestinationPattern.TermsOfUse_    = "Object.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)";
	DestinationPattern.LineOfBusiness = "Object.LineOfBusiness";
	If Not Users.RolesAvailable("SelectArbitraryAssignmentsInProductionStage") Then
		DestinationPattern.Ref = "&RefsFilterInSelectionOfAssignmentsForm";
	EndIf;
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Own);
	
	//
	
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.SupplyWithMaterialsAndWorks.SupplyAssignment");
	DescriptionOfColumns.Columns.FindByValue("InStock").Check = True;
	DescriptionOfColumns.Columns.FindByValue("AvailableForReservation").Check = True;
	
	DescriptionOfColumns.DataPaths.Products     = "Object.SupplyWithMaterialsAndWorks.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.SupplyWithMaterialsAndWorks.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.SupplyWithMaterialsAndWorks.Warehouse";
	
	#EndRegion
	
	#Region ManufacturedProducts
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "Object.ManufacturedProducts.Purpose");
	DestinationPattern.TermsOfUse_    = "Object.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)";
	DestinationPattern.LineOfBusiness = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Own);
	
	// The needs for manufactured products in the warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.ManufacturedProducts.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
											|AND Object.ManufacturedProducts.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.ManufacturedProducts.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.ManufacturedProducts.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.ManufacturedProducts.Recipient";
	DescriptionOfColumns.DataPaths.Recorder      = "Object.ManufacturedProducts.ReferenceOrder";
	DescriptionOfColumns.DataPaths.ReferenceOrder     = "Object.ManufacturedProducts.ReferenceOrder.ReferenceOrder";
	
	// The needs for the work performed in the recipient unit.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "FulfillOrdersWithWorks", True, "Object.ManufacturedProducts.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
											|AND Object.ManufacturedProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.ManufacturedProducts.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.ManufacturedProducts.Characteristic";
	DescriptionOfColumns.DataPaths.Department    = "Object.ManufacturedProducts.Recipient";
	DescriptionOfColumns.DataPaths.Recorder      = "Object.ManufacturedProducts.ReferenceOrder";
	DescriptionOfColumns.DataPaths.ReferenceOrder     = "Object.ManufacturedProducts.ReferenceOrder.ReferenceOrder";
	
	// Product needs in all warehouses.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "SecuringOrdersAllWarehouses", True, "Object.ManufacturedProducts.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
											|AND Object.ManufacturedProducts.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.ManufacturedProducts.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.ManufacturedProducts.Characteristic";
	DescriptionOfColumns.DataPaths.Recorder      = "Object.ManufacturedProducts.ReferenceOrder";
	DescriptionOfColumns.DataPaths.ReferenceOrder     = "Object.ManufacturedProducts.ReferenceOrder.ReferenceOrder";
	
	#EndRegion
	
	#Region SideAndIntermediateRelease
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "Object.SideAndIntermediateRelease.Purpose");
	DestinationPattern.TermsOfUse_    = "Object.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)";
	DestinationPattern.LineOfBusiness = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Own);
	
	// The needs for manufactured products in the warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.SideAndIntermediateRelease.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
											|AND Object.SideAndIntermediateRelease.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.SideAndIntermediateRelease.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.SideAndIntermediateRelease.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.SideAndIntermediateRelease.Recipient";
	DescriptionOfColumns.DataPaths.Recorder      = "Object.SideAndIntermediateRelease.ReferenceOrder";
	DescriptionOfColumns.DataPaths.ReferenceOrder     = "Object.SideAndIntermediateRelease.ReferenceOrder.ReferenceOrder";
	
	// The needs for the work performed in the recipient unit.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "FulfillOrdersWithWorks", True, "Object.SideAndIntermediateRelease.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
											|AND Object.SideAndIntermediateRelease.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.SideAndIntermediateRelease.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.SideAndIntermediateRelease.Characteristic";
	DescriptionOfColumns.DataPaths.Department    = "Object.SideAndIntermediateRelease.Recipient";
	DescriptionOfColumns.DataPaths.Recorder      = "Object.SideAndIntermediateRelease.ReferenceOrder";
	DescriptionOfColumns.DataPaths.ReferenceOrder     = "Object.SideAndIntermediateRelease.ReferenceOrder.ReferenceOrder";
	
	// Product needs in all warehouses.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "SecuringOrdersAllWarehouses", True, "Object.SideAndIntermediateRelease.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
											|AND Object.SideAndIntermediateRelease.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.SideAndIntermediateRelease.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.SideAndIntermediateRelease.Characteristic";
	DescriptionOfColumns.DataPaths.Recorder      = "Object.SideAndIntermediateRelease.ReferenceOrder";
	DescriptionOfColumns.DataPaths.ReferenceOrder     = "Object.SideAndIntermediateRelease.ReferenceOrder.ReferenceOrder";
	
	#EndRegion
	
	#EndRegion
	Return FormTemplate;
	
EndFunction

// Returns parameters for selecting specifications for the items specified in the document.
//
// Parameters:
//   Object - Structure - the structure of the values of the details object required to populate the parameters of the choice specs.
//
// Returns:
//   Structure - A structure that overrides the defaults set in the management function of the Client Server's data items.Parameterselectionspecifications().
//
Function BOMSelectionParameters(Object) Export
	
	Parameters = New Structure;
	
	#Region ManufacturedProducts
	
	BOMSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
	
	BOMSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.Assembly);
	BOMSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.Valid);
	
	ChoiceParameterLinks = New Structure(ProductDataManagementClientServer.ProductDataStructureFieldsForSelectingSpecifications());
	
	ChoiceParameterLinks.Products            = "Object.ManufacturedProducts.Products";
	ChoiceParameterLinks.Characteristic          = "Object.ManufacturedProducts.Characteristic";
	ChoiceParameterLinks.ProductionStart      = "Object.Date";
	ChoiceParameterLinks.LineOfBusiness = "Object.LineOfBusiness";
	
	BOMSelectionParameters.ChoiceParameterLinks.Insert("Object.ManufacturedProducts.BillOfMaterials", ChoiceParameterLinks);
	
	BOMSelectionParameters.Insert("IgnoredDestinationParameters",
		CommonClientServer.ValueInArray(Enums.TypesOfBOMAssignmentParameters.ProductionDispatcherBusinessUnit));
	
	Parameters.Insert("ManufacturedProducts", BOMSelectionParameters);
	
	#EndRegion
	
	#Region SupplyWithMaterialsAndWorks
	
	BOMSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
	
	BOMSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.Assembly);
	BOMSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.Repair);
	
	BOMSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.Valid);
	
	ChoiceParameterLinks = New Structure(ProductDataManagementClientServer.ProductDataStructureFieldsForSelectingSpecifications());
	
	ChoiceParameterLinks.Products            = "Object.SupplyWithMaterialsAndWorks.Products";
	ChoiceParameterLinks.Characteristic          = "Object.SupplyWithMaterialsAndWorks.Characteristic";
	ChoiceParameterLinks.ProductionStart      = "Object.Date";
	ChoiceParameterLinks.LineOfBusiness = "Object.LineOfBusiness";
	
	BOMSelectionParameters.ChoiceParameterLinks.Insert("Object.SupplyWithMaterialsAndWorks.BillOfMaterials", ChoiceParameterLinks);
	
	BOMSelectionParameters.Insert("IgnoredDestinationParameters",
		CommonClientServer.ValueInArray(Enums.TypesOfBOMAssignmentParameters.ProductionDispatcherBusinessUnit));
	
	Parameters.Insert("SupplyWithMaterialsAndWorks", BOMSelectionParameters);
	
	#EndRegion
	
	Return Parameters;
	
EndFunction

// The names of the details, the values of which depend on the selection parameters spec
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSelectingSpecifications() Export
	
	AttributesNames = "";
	Return AttributesNames;
	
EndFunction

// Returns the parameters of the distribution of the costs of the output product.
//
// Parameters:
//   Object - Structure - the structure of the values of the details object required to populate the parameters of cost allocation.
//
// Returns:
//  Structure - parameters specifying the specifics of the distribution of costs for output products.
//
Function CostAllocationParameters(Object) Export
	
	CostAllocationParameters = ProductionClientServer.CostAllocationParametersForOutputProducts(
		"ManufacturedProducts",
		Object.MethodOfAllocatingFinishedProductCosts);
	
	If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.NoGrouping
		Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
		Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductBOM
		Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductBOMAndAssignments Then
		
		CostAllocationParameters.ThereIsFieldCanceled = True;
		
		CostAllocationParameters.CalculateShareCostPercentageField = True;
		CostAllocationParameters.ThisFlagIndicatesThatThereAreFillInErrors = True;
		CostAllocationParameters.CalculateShareOfCostAttributeRequired = True;
		CostAllocationParameters.ParametersForFillingInCostShares.Date = 
									?(CommonClientServer.HasAttributeOrObjectProperty(Object, "Date"), 
									Object.Date, 
									Date("00010101"));
		CostAllocationParameters.ParametersForFillingInCostShares.Currency = 
									?(CommonClientServer.HasAttributeOrObjectProperty(Object, "Currency"), 
									Object.Currency, 
									Catalogs.Currencies.EmptyRef());
		
		CostAllocationParameters.CostGroupingField = "CostGroupNumber";
		CostAllocationParameters.CostGroupingPresentationField = "ExpenseGroup";
		If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
			CostAllocationParameters.FieldNameMethodOfCostAllocationForOutputProducts = "MethodOfAllocatingFinishedProductCosts";
		EndIf;
	EndIf;
	
	Return CostAllocationParameters;
	
EndFunction

#EndRegion

#Region ArticleSelectionAndAnalytics

// Parameters for selecting articles and analytics.
// 
// Returns:
//  Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters() Export
	
	ArticleSelectionOptions = New Array;
	
	// ManufacturedProducts
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.DataPath					= "Object.ManufacturedProducts";
	ChoiceParameters.AssetRef						= "ExpenseItem";
	ChoiceParameters.ArticleType					= "ArticleType";
	
	ChoiceParameters.ChoosingExpenseItem			= True;
	ChoiceParameters.DimensionOfExpenses			= "DimensionOfExpenses";
	ChoiceParameters.SelectingItemOfAssetsLiabilities	= True;
	ChoiceParameters.AssetsLiabilitiesDimension	= "AssetsLiabilitiesDimension";
	
	FormItems = ChoiceParameters.FormItems;
	FormItems.AssetRef.Add("ManufacturedProductsExpenseItem");
	FormItems.DimensionOfExpenses.Add("ManufacturedProductsDimensionOfExpenses");
	FormItems.AssetsLiabilitiesDimension.Add("ManufacturedProductsAssetsLiabilitiesDimension");
	
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("ToExpenseAs", True);
	
	ArticleSelectionOptions.Add(ChoiceParameters);
	
	// Returnable waste
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.DataPath					= "Object.SideAndIntermediateRelease";
	ChoiceParameters.AssetRef						= "ExpenseItem";
	ChoiceParameters.ArticleType					= "ArticleType";
	
	ChoiceParameters.ChoosingExpenseItem			= True;
	ChoiceParameters.DimensionOfExpenses			= "DimensionOfExpenses";
	ChoiceParameters.SelectingItemOfAssetsLiabilities	= True;
	ChoiceParameters.AssetsLiabilitiesDimension	= "AssetsLiabilitiesDimension";
	
	FormItems = ChoiceParameters.FormItems;
	FormItems.AssetRef.Add("SideAndIntermediateReleaseExpenseItem");
	FormItems.DimensionOfExpenses.Add("SideAndIntermediateReleaseDimensionOfExpenses");
	FormItems.AssetsLiabilitiesDimension.Add("SideAndIntermediateReleaseAssetsLiabilitiesDimension");
	
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("ToExpenseAs", True);
	
	ArticleSelectionOptions.Add(ChoiceParameters);
	
	Return ArticleSelectionOptions;
	
EndFunction

#EndRegion

#Region VATAccounting

// Initializes the parameters for filling in the VAT activity type
//
// Parameters:
//  Object		- DocumentObject.SubcontractOrder2_5, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
//
Function ParametersForFillingInVATActivityType(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Organization							= Object.Organization;
	FillParameters.Date								= Object.Date;
	FillParameters.Contract								= Object.Contract;
	FillParameters.LineOfBusiness				= Object.LineOfBusiness;
	FillParameters.OutputOfProductsAndWorks				= True;
	
	Return FillParameters;
	
EndFunction

// Returns the structure of parameters for filling in the purchase VAT tax.
//
// Parameters:
//  Object - DocumentObject.SubcontractOrder2_5, DocumentRef.SubcontractOrder2_5, FormDataStructure - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases
//
Function ParametersForFillingInVATTaxationPurchases(Object) Export

	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
	
	If TypeOf(Object) = Type("DocumentObject.SubcontractOrder2_5")
		Or TypeOf(Object) = Type("FormDataStructure") Then
		ObjectData = Object;
	ElsIf TypeOf(Object) = Type("DocumentRef.SubcontractOrder2_5") Then
		ObjectData = Common.ObjectAttributesValues(Object, "Counterparty,Contract,Date");
	EndIf;
	
	FillParameters.Counterparty               = ObjectData.Counterparty;
	FillParameters.Contract                  = ObjectData.Contract;
	FillParameters.Period                   = ObjectData.Date;
	FillParameters.AcquisitionOfWorks        = True;
	FillParameters.PurchaseOnArticles     = True;
	FillParameters.ReceiptFromProcessing = True;
	
	FillParameters.ImportOfGoodsFromCustomsUnion = (ObjectData.BusinessOperation = 
														Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5);
	
	Return FillParameters;
	
EndFunction

#EndRegion

#Region ARAPAccounting

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	Array of See ARAPAccountingServer.MechanismParameters - Array of parameters of the functions of the settlement mechanism
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.ThisIsOrder                     = True;
	ParametersStructure.SourceOfAmountsTabularPart   = True;
	ParametersStructure.PaymentType_                  = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	
	ParametersStructure.CourseNumerator                = "";
	ParametersStructure.CourseDenominator              = "";
	
	ParametersStructure.PathToTSData                   = "Object.Services";
	ParametersStructure.PathToTSDataPaymentSteps        = "Object.PaymentScheduleSteps";
	ParametersStructure.Terms                      = "";
	ParametersStructure.ShipInOneDay             = "Object.NotShipInInstallments";
	
	ParametersStructure.CompanyBankAccount    = "Object.BankAccount";
	ParametersStructure.CounterpartyBankAccount    = "";
	ParametersStructure.Manager                     = "Object.Manager";
	ParametersStructure.DocumentAmountForm          = "Form.Object.DocumentAmount";
	
	ParametersStructure.FormItems.InscriptionStages   = "DecorationPaymentSteps";
	ParametersStructure.FormItems.InscriptionCalculations = "DecorationSettlementState";
	ParametersStructure.FormItems.PaymentSettlement    = "CreditPaymentForm";
	ParametersStructure.PaymentStepsText           = "Form.PaymentStepsText";
	
	ParametersStructure.FormItems.FinancialAccountingGroup  = "FinancialAccountingGroup";
	
	ParametersStructure.ApprovalDate             = "Object.ApprovalDate";
	ParametersStructure.DateOfShipment                 = "Object.Services.ExecutionDate";
	ParametersStructure.ARAPObject               = "Object.ARAPObject";
	
	Return ParametersStructure;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Partner)
	|	AND ValueAllowed(Department)
	|	AND (ValueAllowed(ManufacturedProducts.Recipient)
	|		OR ValueAllowed(SideAndIntermediateRelease.Recipient)
	|		OR ManufacturedProducts.Recipient IS NULL
	|		AND SideAndIntermediateRelease.Recipient IS NULL)";

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

#Region Rounding

// Returns the parameters for rounding
// 
// Returns:
// 	Structure - the elements contain a structure of rounding parameters 
// 				See ProductsServer.ParametersForRoundingNumberOfUnitProducts
// 
Function TSParametersForRounding() Export
	
	TSParameters = New Structure;
	
	TSName = "ManufacturedProducts";
	WarehouseFieldName = "Recipient";
	TSParameters.Insert(TSName, ProductsServer.ParametersForCheckingFillingQuantity());
	TSParameters[TSName].TSName = TSName;
	TSParameters[TSName].AdditionalFields.Insert(WarehouseFieldName, TSName + "." + WarehouseFieldName);
	TSParameters[TSName].ConditionForSelectingRowsByAdditionalFields = 
			ProductionServer.ConditionForSelectingRowsForRounding(TSName, WarehouseFieldName);
	
	TSName = "SideAndIntermediateRelease";
	WarehouseFieldName = "Recipient";
	TSParameters.Insert(TSName, ProductsServer.ParametersForCheckingFillingQuantity());
	TSParameters[TSName].TSName = TSName;
	TSParameters[TSName].AdditionalFields.Insert(WarehouseFieldName, TSName + "." + WarehouseFieldName);
	TSParameters[TSName].ConditionForSelectingRowsByAdditionalFields = 
			ProductionServer.ConditionForSelectingRowsForRounding(TSName, WarehouseFieldName);
	
	TSName = "SupplyWithMaterialsAndWorks";
	WarehouseFieldName = "Warehouse";
	TSParameters.Insert(TSName, ProductsServer.ParametersForCheckingFillingQuantity());
	TSParameters[TSName].TSName = TSName;
	TSParameters[TSName].AdditionalFields.Insert(WarehouseFieldName, TSName + "." + WarehouseFieldName);
	TSParameters[TSName].ConditionForSelectingRowsByAdditionalFields = 
			ProductionServer.ConditionForSelectingRowsForRounding(TSName, WarehouseFieldName);
	
	Return TSParameters;

EndFunction

#EndRegion

#Region Supply

// Forms the structure of the document parameters for embedding the document in the security mechanisms.
// Parameters:
//  DocumentObject - DocumentObject.SubcontractOrder2_5 - Document
// Returns:
//  See ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions
//
Function AvailableRemainingEmbeddingOptions(DocumentObject = Undefined) Export
	
	EmbeddingParameters = ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions();
	EmbeddingParameters.AttributesToBeCleared = "RowCode";
	
	// Updating the "Available" column.
	EmbeddingParameters.FormTableName = "SupplyWithMaterialsAndWorks";
	
	// Conditional registration.
	FormItems = EmbeddingParameters.ConditionalAppearance.FormItems;
	FormItems.SupplyOption = "SupplyWithMaterialsAndWorksSupplyOption";
	FormItems.Available           = "SupplyWithMaterialsAndWorksAvailable";
	FormItems.Series              = "SupplyWithMaterialsAndWorksSeries";
	FormItems.WithAssignment        = "SupplyWithMaterialsAndWorksWithAssignment";
	FormItems.Warehouse              = "SupplyWithMaterialsAndWorksWarehouse";
	
	DataPaths = EmbeddingParameters.ConditionalAppearance.DataPaths;
	DataPaths.ReallocateInventory = "Object.SupplyWithMaterialsAndWorks.ReallocateInventory";
	DataPaths.NoEditingAllowed   = "Object.SupplyWithMaterialsAndWorks.Canceled";
	
	// The choice of the security option.
	Links = EmbeddingParameters.ConnectionsOfSoftwareOptionSelectionParameters;
	Links.Available              = "Items.SupplyWithMaterialsAndWorks.CurrentData.Available";
	Links.NumberOfPackages    = "Items.SupplyWithMaterialsAndWorks.CurrentData.NumberOfPackages";
	Links.Count            = "Items.SupplyWithMaterialsAndWorks.CurrentData.Count";
	Links.ShipIfAvailable = "Items.SupplyWithMaterialsAndWorks.CurrentData.ShipIfAvailable";
	Links.WithAssignment           = "Items.SupplyWithMaterialsAndWorks.CurrentData.WithAssignment";
	Links.ItemsType       = "Items.SupplyWithMaterialsAndWorks.CurrentData.ItemsType";
	Links.Package              = "Items.SupplyWithMaterialsAndWorks.CurrentData.Package";
	Links.Products          = "Items.SupplyWithMaterialsAndWorks.CurrentData.Products";
	Links.SupplyOption    = "Items.SupplyWithMaterialsAndWorks.CurrentData.SupplyOption";
	Links.Warehouse                 = "Items.SupplyWithMaterialsAndWorks.CurrentData.Warehouse";
	Links.MultipleWarehouses      = "WarehouseMaterialsVHF";
	
	// The name of the shipment registration register.
	EmbeddingParameters.NameOfShipmentRegistrationRegister = "ShipmentAndReturnReferences";
	
	// Temporary document data table.
	EmbeddingParameters.ObjectName = "Document.SubcontractOrder2_5";
	EmbeddingParameters.TableName = "Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks";
	
	EmbeddingParameters.DescriptionOfGettingDocumentData =
		"SELECT
		|	TabPart.Products       AS Products,
		|	TabPart.Characteristic     AS Characteristic,
		|	Attributes.Department     AS Department,
		|	TabPart.Warehouse              AS Warehouse,
		|	TabPart.Purpose         AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	Attributes.Ref            AS ShipmentOrder,
		|	TabPart.SupplyOption AS SupplyOption,
		|	TabPart.WithAssignment        AS WithAssignment,
		|	TabPart.Count         AS Count,
		|	TabPart.NumberOfPackages AS NumberOfPackages,
		|	TabPart.Package           AS Package,
		|	Attributes.Status IN(
		|			VALUE(Enum.TollingOrderStatuses.ForFulfillment),
		|			VALUE(Enum.TollingOrderStatuses.Closed)) AS ReadyForSupply,
		|	Attributes.Status IN(
		|			VALUE(Enum.TollingOrderStatuses.ForFulfillment),
		|			VALUE(Enum.TollingOrderStatuses.Closed)) AS ReadyToShip,
		|	CASE
		|		WHEN Attributes.NotShipInInstallments
		|			THEN Attributes.DateOfShipment
		|		ELSE TabPart.DateOfShipment
		|	END                       AS RequestShipmentOn,
		|	TabPart.Series              AS Series,
		|	TabPart.RowCode          AS RowCode,
		|	TabPart.Canceled           AS Canceled,
		|	TabPart.LineNumber        AS LineNumber,
		|	CASE
		|		WHEN Attributes.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
		|			THEN TabPart.ReferenceOrder
		|		WHEN TRUE
		|			THEN Attributes.Ref
		|	END                       AS Recorder,
		|	Attributes.Date              AS DocumentDate,
		|	CASE
		|		WHEN Attributes.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
		|			THEN UNDEFINED
		|		WHEN TRUE
		|			THEN Attributes.MaterialsWarehouse
		|	END                       AS GroupOfWarehouses,
		|	Attributes.Priority         AS Priority,
		|	CASE
		|		WHEN Attributes.NotShipInInstallments
		|			THEN Attributes.DateOfShipment
		|		ELSE UNDEFINED
		|	END                       AS TheShipmentDateOfAllLinesIsASingleDate
		|INTO TemporaryDocumentDataTable
		|FROM
		|	Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks AS TabPart
		|	
		|	LEFT JOIN Document.SubcontractOrder2_5 AS Attributes
		|	ON TRUE
		|";
		
	// Template for serialization of form data.
	SupplyWithMaterialsAndWorks = New Structure();
	SupplyWithMaterialsAndWorks.Insert("LineNumber",             New TypeDescription("Number"));
	SupplyWithMaterialsAndWorks.Insert("Products",            New TypeDescription("CatalogRef.Products"));
	SupplyWithMaterialsAndWorks.Insert("Characteristic",          New TypeDescription("CatalogRef.ItemsCharacteristics"));
	SupplyWithMaterialsAndWorks.Insert("Purpose",              New TypeDescription("CatalogRef.Assignments"));
	SupplyWithMaterialsAndWorks.Insert("Warehouse",                   New TypeDescription("CatalogRef.Warehouses"));
	SupplyWithMaterialsAndWorks.Insert("SupplyOption",      New TypeDescription("EnumRef.SupplyOptions"));
	SupplyWithMaterialsAndWorks.Insert("WithAssignment",             New TypeDescription("Boolean"));
	SupplyWithMaterialsAndWorks.Insert("Produced",            New TypeDescription("Boolean"));
	SupplyWithMaterialsAndWorks.Insert("Count",              New TypeDescription("Number"));
	SupplyWithMaterialsAndWorks.Insert("NumberOfPackages",      New TypeDescription("Number"));
	SupplyWithMaterialsAndWorks.Insert("Package",                New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	SupplyWithMaterialsAndWorks.Insert("DateOfShipment",            New TypeDescription("Date"));
	SupplyWithMaterialsAndWorks.Insert("Series",                   New TypeDescription("CatalogRef.ItemsBatches"));
	SupplyWithMaterialsAndWorks.Insert("Canceled",                New TypeDescription("Boolean"));
	SupplyWithMaterialsAndWorks.Insert("RowCode",               New TypeDescription("Number"));
	SupplyWithMaterialsAndWorks.Insert("CostGroupNumber",       New TypeDescription("Number"));
	SupplyWithMaterialsAndWorks.Insert("ReferenceOrder",            New TypeDescription("DocumentRef.ProductionStage2_2"));
	Object = New Structure();
	Object.Insert("GroupCosts",                 New TypeDescription("EnumRef.CostGroupingsInTollingOrder"));
	Object.Insert("ProcessingByOrder",               New TypeDescription("Boolean"));
	Object.Insert("Department",                     New TypeDescription("CatalogRef.BusinessStructure"));
	Object.Insert("MaterialsWarehouse",                   New TypeDescription("CatalogRef.Warehouses"));
	Object.Insert("SeparationOfMaterialsByProductPurpose", New TypeDescription("Boolean"));
	Object.Insert("Purpose",                        New TypeDescription("CatalogRef.Assignments"));
	Object.Insert("Ref",                            New TypeDescription("DocumentRef.SubcontractOrder2_5"));
	Object.Insert("Status",                            New TypeDescription("EnumRef.TollingOrderStatuses"));
	Object.Insert("NotShipInInstallments",                New TypeDescription("Boolean"));
	Object.Insert("DateOfShipment",                      New TypeDescription("Date"));
	Object.Insert("Date",                              New TypeDescription("Date"));
	Object.Insert("Priority",                         New TypeDescription("CatalogRef.Priorities"));
	Object.Insert("SupplyWithMaterialsAndWorks",   SupplyWithMaterialsAndWorks);
	
	EmbeddingParameters.FormDataSerializationPattern.Insert("Object", Object);
	
	EmbeddingParameters.RelationshipFieldsOfTableParts.Insert("ManufacturedProducts", New Structure("CostGroupNumber", "CostGroupNumber"));
	
	ItemsNames = EmbeddingParameters.ItemsNames;
	ItemsNames.PagesHyperlinkSoftwareStatus = "PagesHyperlinkSoftwareStatus";
	ItemsNames.SecurityStatusHyperlink = "SecurityStatusHyperlink";
	ItemsNames.PageHyperlinkSecurityStatusIsBeingShipped = "PageHyperlinkSecurityStatusIsBeingShipped";
	ItemsNames.HyperlinkSecurityStatusIsBeingShipped = "HyperlinkSecurityStatusIsBeingShipped";
	ItemsNames.PageHyperlinkSoftwareStatusIssue = "PageHyperlinkSoftwareStatusIssue";
	ItemsNames.HyperlinkSecurityStatusIssue = "HyperlinkSecurityStatusIssue";
	ItemsNames.PageHyperlinkStateOfProvisionWithTitle = "PageHyperlinkStateOfProvisionWithTitle";
	ItemsNames.ProvisionStateHyperlinkWithTitle = "ProvisionStateHyperlinkWithTitle";
	
	Return EmbeddingParameters;
	
EndFunction

// Parameters:
//  Ref - DocumentRef.SubcontractOrder2_5 - a link to an order that has built-in commands for creating an assignment adjustment
//  AdditionalParameters - Structure - Structure with fields:
//  * IDInStorage - UUID - A unique identifier to put the goods of the document in the storage
//  * ThisIsWithdrawalOfReserve - Boolean - True if the data needs to be obtained for a reserve withdrawal operation, False if for a reservation operation
//  Returns:
//   Structure - Document data required to execute the assignment adjustment creation command
Function DocumentDataForCreatingDestinationAdjustment(Ref, AdditionalParameters) Export
	
	Query = New Query();
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("ThisIsWithdrawalOfReserve", AdditionalParameters.ThisIsWithdrawalOfReserve);
	Query.Text =
	"SELECT
	|	DocumentAttributes.Posted AS Posted
	|FROM
	|	Document.SubcontractOrder2_5 AS DocumentAttributes
	|WHERE
	|	DocumentAttributes.Ref = &Ref
	|;
	|SELECT DISTINCT
	|	OrderMaterials.Purpose AS Ref
	|FROM
	|	Document.SubcontractOrder2_5 AS DocumentAttributes
	|		
	|		LEFT JOIN Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS OrderMaterials
	|		ON DocumentAttributes.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|			AND OrderMaterials.Ref.SubcontractOrder = &Ref
	|			AND OrderMaterials.Ref.Posted
	|WHERE
	|	OrderMaterials.Ref.SubcontractOrder = &Ref
	|		AND OrderMaterials.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|		AND (&ThisIsWithdrawalOfReserve OR NOT OrderMaterials.Canceled)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	OrderMaterials.Purpose AS Ref
	|FROM
	|	Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks AS OrderMaterials
	|WHERE
	|	OrderMaterials.Ref = &Ref
	|		AND OrderMaterials.Ref.GroupCosts <> VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|		AND OrderMaterials.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|		AND (&ThisIsWithdrawalOfReserve OR NOT OrderMaterials.Canceled)
	|;
	|SELECT DISTINCT
	|	OrderMaterials.Products AS Products,
	|	OrderMaterials.Characteristic AS Characteristic,
	|	OrderMaterials.Purpose AS Purpose
	|FROM
	|	Document.SubcontractOrder2_5 AS DocumentAttributes
	|		
	|		LEFT JOIN Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS OrderMaterials
	|		ON DocumentAttributes.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|			AND OrderMaterials.Ref.SubcontractOrder = &Ref
	|			AND OrderMaterials.Ref.Posted
	|WHERE
	|	OrderMaterials.Ref.SubcontractOrder = &Ref
	|		AND (&ThisIsWithdrawalOfReserve OR NOT OrderMaterials.Canceled)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	OrderMaterials.Products AS Products,
	|	OrderMaterials.Characteristic AS Characteristic,
	|	OrderMaterials.Purpose AS Purpose
	|FROM
	|	Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks AS OrderMaterials
	|WHERE
	|	OrderMaterials.Ref = &Ref
	|		AND OrderMaterials.Ref.GroupCosts <> VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|		AND (&ThisIsWithdrawalOfReserve OR NOT OrderMaterials.Canceled)
	|";
	
	ZaposResultPackage = Query.ExecuteBatch();
	Selection = ZaposResultPackage[0].Select();
	Selection.Next();
	Posted = Selection.Posted;
	Assignments = ZaposResultPackage[1].Unload().UnloadColumn("Ref");
	ZaposResultPackage[2].Unload();
	Goods = ZaposResultPackage[2].Unload();
	AddressOfGoods = PutToTempStorage(Goods, AdditionalParameters.IDInStorage);
	
	ThereAreGoodsToSeparateProvision = Documents.InventoryAssignmentAdjustment.ThereAreGoodsToSeparateProvision(
		Assignments, AddressOfGoods);
	
	ThereAreGoodsToWithdrawReserve = Documents.InventoryAssignmentAdjustment.ThereAreGoodsToWithdrawReserve(
		Assignments, AddressOfGoods);
	
	DocumentData = New Structure();
	DocumentData.Insert("Posted", Posted);
	DocumentData.Insert("Assignments", Assignments);
	DocumentData.Insert("AddressOfGoods", AddressOfGoods);
	DocumentData.Insert("ThereAreGoodsToSeparateProvision", ThereAreGoodsToSeparateProvision);
	DocumentData.Insert("ThereAreGoodsToWithdrawReserve", ThereAreGoodsToWithdrawReserve);
	
	Return DocumentData;

EndFunction

#EndRegion

#Region Assignments

// Returns a template for generating a material provisioning assignment.
//
// Parameters:
// 		Object - DocumentObject.SubcontractOrder2_5, FormDataStructure - order to the processor for which you need to get the destination template.
//
// Returns:
// 		See Catalogs.Assignments.NewSubmenuTemplate
//
Function DestinationPattern(Object) Export
	
	DestinationPattern = Catalogs.Assignments.NewSubmenuTemplate();
	
	If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(Object.LineOfBusiness) Then
		DestinationPattern.LineOfBusiness = Object.LineOfBusiness;
	EndIf;
	
	OptionOfAssignment = Constants.OptionOfAssignmentAtTransferToSubcontractor2_5.Get();
	
	If OptionOfAssignment = Enums.OptionsOfAssignmentDuringTransferToProcessing.ByTollerContract Then
		
		DestinationPattern.Partner = Object.Partner;
		DestinationPattern.Contract = Object.Contract;
		
	ElsIf OptionOfAssignment = Enums.OptionsOfAssignmentDuringTransferToProcessing.SubcontractOrder
		Or Not ValueIsFilled(DestinationPattern.LineOfBusiness) Then
		
		DestinationPattern.OrderDocument = Object.Ref;
		
	EndIf;
	
	Return DestinationPattern;
	
EndFunction

// Returns a template for generating a product assignment in a document.
//
// Parameters:
// 		Object - DocumentObject.SubcontractOrder2_5, FormDataStructure - order to the processor for which you need to get the destination template.
//
// Returns:
// 		See Catalogs.Assignments.NewSubmenuTemplate
//
Function TransferDestinationPattern(Object) Export
	
	DestinationPattern = Catalogs.Assignments.NewSubmenuTemplate();
	
	If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(Object.LineOfBusiness) Then
		DestinationPattern.LineOfBusiness = Object.LineOfBusiness;
	EndIf;
	
	DestinationPattern.OrderDocument = Object.Ref;
	
	Return DestinationPattern;
	
EndFunction

// Returns a template for generating the assignment of giving materials in the document.
// 
// Parameters:
//  Object - CatalogObject.Assignments, FormDataStructure, Structure - Purpose of products
//
// Returns:
//  Structure - See Catalogs.Assignments.NewSubmenuTemplate
//
Function AssignmentTemplateGiverSMaterials(Object) Export
	
	DestinationPattern = Catalogs.Assignments.NewSubmenuTemplate();
	
	If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(Object.LineOfBusiness) Then
		DestinationPattern.LineOfBusiness = Object.LineOfBusiness;
	EndIf;
	
	DestinationPattern.Partner       = Object.Partner;
	DestinationPattern.Contract       = Object.Contract;
	DestinationPattern.AssignmentType = Enums.AssignmentTypes.Giveaway2_5;
	
	OptionOfAssignment = Constants.OptionOfMaterialAssignmentUponSubcontractingServicesDelivered.Get();
	If OptionOfAssignment = Enums.AssignmentAtSubcontractingServicesDelivered.MaterialProviderOrder Then
		DestinationPattern.OrderDocument     = Object.OrderDocument;
	EndIf;
	
	Return DestinationPattern;
	
EndFunction

#EndRegion

#Region MessageTemplates

// Called when preparing message templates and allows you to redefine the list of details and attachments.
//
// Parameters:
//  Attributes               - ValueTree - list of template Attributes:
//         * Name            - String - the unique name of the shared prop.
//         * Presentation  - String - representation of general props.
//         * Type            - Type    - Type of props. By default, a string.
//         * Format         - String - Format for output values for numbers, dates, strings, and Boolean values.
//  Attachments                - ValueTable - Printed forms and attachments:
//         * Name            - String - the unique name of the attachment.
//         * Presentation  - String - representation of the option.
//         * FileType       - String - Attachment type that corresponds to the file extension: "pdf", "png", "jpg", mxl"
//                                      , etc.
//  AdditionalParameters - Structure - more information about the message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export
	
EndProcedure

// Called when creating messages based on a template to fill in the values of details and attachments.
//
// Parameters:
//  Message - Structure - structure with keys:
//    * AttributesValues - Map of KeyAndValue- list of Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * CommonAttributesValues - Map of KeyAndValue - list of common Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * Attachments - Map of KeyAndValue - the values of the requisites
//      * Key     - String - name of the attachment in the template;
//      * Value - BinaryData, String - binary data or an address in the attachment's temporary storage.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//  AdditionalParameters - Structure -  additional information about the message template.
//
Procedure OnCreateMessage(Message, MessageSubject, AdditionalParameters) Export
	
EndProcedure

// Fills in the list of SMS recipients when sending a message generated by a template.
//
// Parameters:
//   SMSMessageRecipients - ValueTable - the list is received by SMS:
//     * PhoneNumber - String - phone number where the SMS message will be sent.
//     * Presentation - String - representation of the recipient of the SMS message.
//     * Contact       - CatalogRef - the contact that the phone number belongs to.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsPhonesInMessage(SMSMessageRecipients, MessageSubject) Export
	
EndProcedure

// Fills in the list of email recipients when sending a message generated by a template.
//
// Parameters:
//   EmailRecipients - ValueTable - list of received emails:
//     * Address           - String - recipient's email address.
//     * Presentation   - String - submission of the email message.
//     * SendingOption - String - Options for sending emails: "To", "Copy", "Hidden Copy", " Reverse Address";
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, MessageSubject) Export
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ListForm" Then
		
		If ProductionServerCall.AvailableWorkplaceOrdersProcessors() Then
			SelectedForm = "Workplace";
			StandardProcessing = False;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Function PerformActionForOrdersAfterQuestion(ProcedureParameters) Export
	
	Query = New Query();
	Query.SetParameter("Orders", ProcedureParameters.Orders);
	Query.Text =
		"SELECT
		|	Orders.Ref AS Ref
		|FROM
		|	Document.SubcontractOrder2_5 AS Orders
		|WHERE
		|	Orders.Ref IN(&Orders)
		|		AND Orders.GroupCosts
		|			<> VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
		
		|;
		|SELECT
		|	Orders.Ref AS Ref,
		|	Orders.SubcontractOrder AS SubcontractOrder
		|FROM
		|	Document.ProductionStage2_2 AS Orders
		|WHERE
		|	Orders.SubcontractOrder IN(&Orders)
		|ORDER BY
		|	SubcontractOrder
		
		|";
		
	QueryResult = Query.ExecuteBatch();
	
	ProcedureParameters.EmbeddingParameters = Documents.SubcontractOrder2_5.AvailableRemainingEmbeddingOptions();
	ProcedureParameters.Orders = QueryResult[0].Unload().UnloadColumn("Ref");
	ExecutionResultIsComplete = ProvisionInDocumentsServer.PerformActionForOrdersAfterQuestion(ProcedureParameters);
	
	Table = QueryResult[1].Unload();
	OrdersToProcessor = New Array();
	For IndexOf = 0 To Table.Count() - 1 Do
		TableRow = Table[IndexOf];
		If OrdersToProcessor.Count() = 0
				Or TableRow.SubcontractOrder
						<> OrdersToProcessor[OrdersToProcessor.UBound()].SubcontractOrder Then
				
				OrdersToProcessor.Add(
					New Structure("SubcontractOrder,Stages", TableRow.SubcontractOrder, New Array()));
				
		EndIf;
		OrdersToProcessor[OrdersToProcessor.UBound()].Stages.Add(TableRow.Ref);
	EndDo;
	
	For Each Item In OrdersToProcessor Do
		
		Ref = Item.SubcontractOrder;
		Orders = Item.Stages;
		FillParameters = ProcedureParameters.FillParameters;
		
		ErrorText = "";
		BeginTransaction();
		Try
			
			Block = New DataLock();
			
			LockItem = Block.Add(Ref.Metadata().FullName());
			LockItem.SetValue("Ref", Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			For Each Stage In Orders Do
				LockItem = Block.Add(Ref.Metadata().FullName());
				LockItem.SetValue("Ref", Ref);
				LockItem.Mode = DataLockMode.Exclusive;
			EndDo;
			
			ErrorText = NStr("vi = 'Không thể đặt phong tỏa đối tượng. Đối với %1 chưa đặt thao tác.';
							|ru = 'Не удалось установить блокировку объекта. Для %1 установка действия не выполнена.';
							|en = 'Cannot set object lock. Cannot set the action for %1.'; fa = 'Cannot set object lock. Cannot set the action for %1.';
							|it = 'Non è stato possibile impostare il blocco dell''oggetto, Impostazione di azione per %1 non riuscita.';
							|pl = 'Nie udało się ustawić blokowania obiektu. Dla %1 nie wykonano ustawienia działania.';
							|tr = 'Nesne kilidi ayarlanamadı. %1 için işlem ayarı gerçekleştirilemedi.'");
			Block.Lock();
			
			FillInByForce = False;
			If FillParameters <> Undefined Then // a question was asked about the shipment by one date
				
				AttributesValues = Common.ObjectAttributesValues(Ref, "NotShipInInstallments,DateOfShipment");
				FillInByForce = AttributesValues.NotShipInInstallments
					And AttributesValues.DateOfShipment < BegOfDay(CurrentSessionDate());
				
			EndIf;
			
			UnchangedStages = New Array();
			AdditionalParameters = New Structure("ReturnProductionParametersOnSide", False);
			StageEmbeddingParameters = Documents.ProductionStage2_2.AvailableRemainingEmbeddingOptions(
				Undefined,
				AdditionalParameters);
			ExpressionForQuestion = StageEmbeddingParameters.ExpressionForQuestionWhenPerformingActionInOrderList;
			AdditionalParameters.ReturnProductionParametersOnSide = True;
			StageEmbeddingParameters = Documents.ProductionStage2_2.AvailableRemainingEmbeddingOptions(
				Undefined,
				AdditionalParameters);
			StageEmbeddingParameters.ExpressionForQuestionWhenPerformingActionInOrderList = ExpressionForQuestion;
			ProcedureParameters.EmbeddingParameters = StageEmbeddingParameters;
			For Each Stage In Orders Do
				
				ProcedureParameters.Orders = CommonClientServer.ValueInArray(Stage);
				ExecutionResult = ProvisionInDocumentsServer.PerformActionForOrdersAfterQuestion(
					ProcedureParameters);
				If ExecutionResult.ErrorList.Count() > 0 Then
					CommonClientServer.SupplementArray(
						ExecutionResultIsComplete.ErrorList,
						ExecutionResult.ErrorList);
					ErrorText = NStr("vi = 'Lỗi điền thao tác trong danh sách chứng từ. Đơn hàng %1.';
									|ru = 'Ошибка заполнения действия в списке документов. Заказ %1.';
									|en = 'Action population error in the documents list. The %1 order.'; fa = 'Action population error in the documents list. The %1 order.';
									|it = 'Ошибка заполнения действия в списке документов. Заказ %1.';
									|pl = 'Action population error in the documents list. The %1 order.';
									|tr = 'Belge listesinde eylem doldurulurken hata oluştu. %1 emri.'");
					Raise ErrorText;
				EndIf;
				If ExecutionResult.QuantityProcessed = 0 Then
					UnchangedStages.Add(Stage);
				EndIf;
				
			EndDo;
			
			AtLeastOneStageHasBeenChanged = UnchangedStages.Count() < Orders.Count();
			If FillInByForce And AtLeastOneStageHasBeenChanged Then
				
				ProcedureParameters.Orders = CommonClientServer.ValueInArray(Ref);
				ProcedureParameters.EmbeddingParameters = Documents.SubcontractOrder2_5.AvailableRemainingEmbeddingOptions();
				ExecutionResult = ProvisionInDocumentsServer.PerformActionForOrdersAfterQuestion(
					ProcedureParameters,
					True,
					True);
				If ExecutionResult.ErrorList.Count() > 0 Then
					
					CommonClientServer.SupplementArray(ExecutionResultIsComplete.ErrorList,
						ExecutionResult.ErrorList);
					ErrorText = NStr("vi = 'Lỗi điền thao tác trong danh sách chứng từ. Đơn hàng %1.';
									|ru = 'Ошибка заполнения действия в списке документов. Заказ %1.';
									|en = 'Action population error in the documents list. The %1 order.'; fa = 'Action population error in the documents list. The %1 order.';
									|it = 'Ошибка заполнения действия в списке документов. Заказ %1.';
									|pl = 'Action population error in the documents list. The %1 order.';
									|tr = 'Belge listesinde eylem doldurulurken hata oluştu. %1 emri.'");
					Raise ErrorText;
					
				EndIf;
				
				ProcedureParameters.Orders = UnchangedStages;
				ProcedureParameters.EmbeddingParameters = StageEmbeddingParameters;
				ExecutionResult = ProvisionInDocumentsServer.PerformActionForOrdersAfterQuestion(
					ProcedureParameters,
					FillInByForce);
				If ExecutionResult.ErrorList.Count() > 0 Then
					CommonClientServer.SupplementArray(
						ExecutionResultIsComplete.ErrorList,
						ExecutionResult.ErrorList);
					ErrorText = NStr("vi = 'Lỗi điền thao tác trong danh sách chứng từ. Đơn hàng %1.';
									|ru = 'Ошибка заполнения действия в списке документов. Заказ %1.';
									|en = 'Action population error in the documents list. The %1 order.'; fa = 'Action population error in the documents list. The %1 order.';
									|it = 'Ошибка заполнения действия в списке документов. Заказ %1.';
									|pl = 'Action population error in the documents list. The %1 order.';
									|tr = 'Belge listesinde eylem doldurulurken hata oluştu. %1 emri.'");
					Raise ErrorText;
				EndIf;
				
			EndIf;
			
			If AtLeastOneStageHasBeenChanged Then
				ExecutionResultIsComplete.QuantityProcessed = ExecutionResultIsComplete.QuantityProcessed + 1;
			EndIf;
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			ExecutionResultIsComplete.ErrorList.Add(
				New Structure("Text,Ref", StrTemplate(ErrorText, Ref), Ref));
			
		EndTry;
		
	EndDo;
	
	Return ExecutionResultIsComplete;
	
EndFunction

Function QueryTextDocumentGoods(Filter, Resource) Export
	
	If Resource = "ManufacturedProducts" Then
		
		QueryText = 
		"SELECT
		|	Table.Ref                       AS PurchaseOrder,
		|	Table.RowCode                    AS RowCode,
		|	Table.DateOfReceipt              AS DateOfReceipt,
		|	Table.Products                 AS Products,
		|	Table.Characteristic               AS Characteristic,
		|	Table.Purpose                   AS Purpose,
		|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
		|	Table.Count                   AS Count,
		|	0                                    AS Price,
		|	0                                    AS Sum,
		|	Table.Package                     AS Package,
		|	Table.Recipient                   AS Warehouse,
		|	ISNULL(DataOfAccounting.ToRegister, 0) AS ToRegister
		|FROM
		|	Document.SubcontractOrder2_5.ManufacturedProducts AS Table
		|	
		|	INNER JOIN TTAccountingData AS DataOfAccounting
		|	ON Table.Ref = DataOfAccounting.ReferenceOrder
		|	AND Table.RowCode = DataOfAccounting.RowCode
		|	
		|WHERE
		|	NOT Table.ToExpenseAs
		|	AND &FilterText1
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref                       AS PurchaseOrder,
		|	TableProduction.RowCode           AS RowCode,
		|	TableProduction.ProductionDate    AS DateOfReceipt,
		|	TableProduction.Products        AS Products,
		|	TableProduction.Characteristic      AS Characteristic,
		|	TableProduction.Purpose          AS Purpose,
		|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
		|	TableProduction.Count          AS Count,
		|	0                                    AS Price,
		|	0                                    AS Sum,
		|	TableProduction.Package            AS Package,
		|	TableProduction.Recipient          AS Warehouse,
		|	ISNULL(DataOfAccounting.ToRegister, 0) AS ToRegister
		|FROM
		|	Document.SubcontractOrder2_5 AS Table
		|
		|	INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS TableProduction
		|	ON TableProduction.Ref.SubcontractOrder = Table.Ref
		|	AND NOT TableProduction.Canceled
		|	
		|	INNER JOIN TTAccountingData AS DataOfAccounting
		|	ON Table.Ref = DataOfAccounting.ReferenceOrder
		|	AND TableProduction.RowCode = DataOfAccounting.RowCode
		|	
		|WHERE
		|	Table.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
		|	AND NOT TableProduction.ToExpenseAs
		|	AND &FilterText1
		|";
		
	ElsIf Resource = "SideAndIntermediateRelease" Then
		
		QueryText = 
		"SELECT
		|	Table.Ref                       AS PurchaseOrder,
		|	Table.RowCode                    AS RowCode,
		|	Table.DateOfReceipt              AS DateOfReceipt,
		|	Table.Products                 AS Products,
		|	Table.Characteristic               AS Characteristic,
		|	Table.Purpose                   AS Purpose,
		|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
		|	Table.Count                   AS Count,
		|	0                                    AS Price,
		|	0                                    AS Sum,
		|	Table.Package                     AS Package,
		|	Table.Recipient                   AS Warehouse,
		|	ISNULL(DataOfAccounting.ToRegister, 0) AS ToRegister
		|FROM
		|	Document.SubcontractOrder2_5.SideAndIntermediateRelease AS Table
		|
		|	INNER JOIN TTAccountingData AS DataOfAccounting
		|	ON Table.Ref = DataOfAccounting.ReferenceOrder
		|	AND Table.RowCode = DataOfAccounting.RowCode
		|	
		|WHERE
		|	NOT Table.ToExpenseAs
		|	AND &FilterText1
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref                       AS PurchaseOrder,
		|	TableWaste.RowCode              AS RowCode,
		|	TableWaste.ProductionDate       AS DateOfReceipt,
		|	TableWaste.Products           AS Products,
		|	TableWaste.Characteristic         AS Characteristic,
		|	TableWaste.Purpose             AS Purpose,
		|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
		|	TableWaste.Count             AS Count,
		|	0                                    AS Price,
		|	0                                    AS Sum,
		|	TableWaste.Package               AS Package,
		|	TableWaste.Recipient             AS Warehouse,
		|	ISNULL(DataOfAccounting.ToRegister, 0) AS ToRegister
		|FROM
		|	Document.SubcontractOrder2_5 AS Table
		|
		|	INNER JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS TableWaste
		|	ON TableWaste.Ref.SubcontractOrder = Table.Ref
		|	AND NOT TableWaste.Canceled
		|
		|	INNER JOIN TTAccountingData AS DataOfAccounting
		|	ON Table.Ref = DataOfAccounting.ReferenceOrder
		|	AND TableWaste.RowCode = DataOfAccounting.RowCode
		|
		|WHERE
		|	Table.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
		|	AND NOT TableWaste.ToExpenseAs
		|	AND &FilterText1
		|";
		
	Else
		
		QueryText = 
		"SELECT
		|	Table.Ref                       AS PurchaseOrder,
		|	Table.RowCode                    AS RowCode,
		|	Table.DateOfShipment                 AS DateOfShipment,
		|	Table.Products                 AS Products,
		|	Table.Characteristic               AS Characteristic,
		|	CASE
		|		WHEN Table.WithAssignment
		|			THEN Table.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END                                AS Purpose,
		|	Table.Series                        AS Series,
		|	Table.Count                   AS Count,
		|	0                                    AS Price,
		|	0                                    AS Sum,
		|	Table.Package                     AS Package,
		|	Table.Warehouse                        AS Warehouse,
		|	ISNULL(DataOfAccounting.ToRegister, 0) AS ToRegister
		|FROM
		|	Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks AS Table
		|
		|	INNER JOIN TTAccountingData AS DataOfAccounting
		|	ON Table.Ref = DataOfAccounting.ReferenceOrder
		|	AND Table.RowCode = DataOfAccounting.RowCode
		|	
		|WHERE
		|	&FilterText1
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref                       AS PurchaseOrder,
		|	Software_3.RowCode         AS RowCode,
		|	Software_3.DateOfShipment      AS DateOfShipment,
		|	Software_3.Products      AS Products,
		|	Software_3.Characteristic    AS Characteristic,
		|	CASE
		|		WHEN Software_3.WithAssignment
		|			THEN Software_3.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END                                AS Purpose,
		|	Software_3.Series             AS Series,
		|	Software_3.Count        AS Count,
		|	0                                    AS Price,
		|	0                                    AS Sum,
		|	Software_3.Package          AS Package,
		|	Software_3.Warehouse             AS Warehouse,
		|	ISNULL(DataOfAccounting.ToRegister, 0) AS ToRegister
		|FROM
		|	Document.SubcontractOrder2_5 AS Table
		|
		|	LEFT JOIN Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS Software_3
		|	ON Software_3.Ref.SubcontractOrder = Table.Ref
		|	AND NOT Software_3.Canceled
		|
		|	INNER JOIN TTAccountingData AS DataOfAccounting
		|	ON Table.Ref = DataOfAccounting.ReferenceOrder
		|	AND Software_3.RowCode = DataOfAccounting.RowCode
		|
		|WHERE
		|	Table.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
		|	AND &FilterText1
		|";
		
	EndIf;	

	FilterText1 = TMCommonUse.SelectionTextBySelectionCollection(Filter);
	QueryText = StrReplace(QueryText, "&FilterText1", FilterText1);
	
	Return QueryText;

EndFunction

Function RequestTextOutputDocumentItems(Filter = Undefined) Export
	
	QueryTexts = New Array;
	QueryText =
	"SELECT
	|	WareFromOrder.CostGroupNumber        AS CostGroupNumber,
	|	VALUE(Document.ProductionStage2_2.EmptyRef) AS ProductionStage,
	|	WareFromOrder.RowCode                AS RowCode,
	|	TRUE                                 AS ThisIsAProductionIssueStage,
	|	WareFromOrder.Products             AS Products,
	|	WareFromOrder.Characteristic           AS Characteristic,
	|	WareFromOrder.Purpose               AS Purpose,
	|	WareFromOrder.Recipient               AS Recipient,
	|	WareFromOrder.ToExpenseAs         AS ToExpenseAs,
	|	WareFromOrder.ExpenseItem           AS ExpenseItem,
	|	WareFromOrder.DimensionOfExpenses        AS DimensionOfExpenses,
	|	WareFromOrder.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	UNDEFINED                           AS GLAccountSettings,
	|	WareFromOrder.Package                 AS Package,
	|	WareFromOrder.BillOfMaterials             AS BillOfMaterials,
	|	WareFromOrder.CostShare            AS CostShare,
	|	WareFromOrder.CostSharePerUnit   AS CostSharePerUnit,
	|	WareFromOrder.Count               AS Count
	|INTO ManufacturedProducts
	|FROM
	|	Document.SubcontractOrder2_5.ManufacturedProducts AS WareFromOrder
	|	//&CompoundUnitGoodsInUnitOfMeasure
	|WHERE
	|	WareFromOrder.Ref = &SubcontractOrder
	|	AND NOT WareFromOrder.Canceled
	|	AND &FilterText1
	|";
	QueryTexts.Add(QueryText);
	QueryText =
	"SELECT
	|	CostGroupNumbers.CostGroupNumber    AS CostGroupNumber,
	|	CostGroupNumbers.ReferenceOrder         AS ProductionStage,
	|	WareFromOrder.RowCode                AS RowCode,
	|	WareFromOrder.Ref.NextStageNo = 0 AS ThisIsAProductionIssueStage,
	|	WareFromOrder.Products             AS Products,
	|	WareFromOrder.Characteristic           AS Characteristic,
	|	WareFromOrder.Purpose               AS Purpose,
	|	WareFromOrder.Recipient               AS Recipient,
	|	WareFromOrder.ToExpenseAs         AS ToExpenseAs,
	|	WareFromOrder.ExpenseItem           AS ExpenseItem,
	|	WareFromOrder.DimensionOfExpenses        AS DimensionOfExpenses,
	|	WareFromOrder.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	WareFromOrder.GLAccountSettings     AS GLAccountSettings,
	|	WareFromOrder.Package                 AS Package,
	|	WareFromOrder.Ref.BillOfMaterials      AS BillOfMaterials,
	|	WareFromOrder.CostShare            AS CostShare,
	|	WareFromOrder.CostSharePerUnit   AS CostSharePerUnit,
	|	WareFromOrder.Count               AS Count
	|FROM
	|	Document.SubcontractOrder2_5.References AS CostGroupNumbers
	|	
	|	INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS WareFromOrder
	|	ON WareFromOrder.Ref = CostGroupNumbers.ReferenceOrder
	|
	|	//&CompoundUnitGoodsInUnitOfMeasure
	|
	|WHERE
	|	CostGroupNumbers.Ref = &SubcontractOrder
	|	AND NOT WareFromOrder.Canceled
	|	AND &FilterText1
	|";
	QueryTexts.Add(QueryText);
	QueryText = StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin());
	
	ApplyingParameters = ProductionServer.ParametersOfApplicationOfPieceProductInDimensionalUnit();
	ApplyingParameters.UnitGoodsInUnitsOfMeasure = False;
	ProductionServer.ApplyUnitItemSettingsInUnitOfMeasure(QueryText, "WareFromOrder", ApplyingParameters);	
	
	QueryText = QueryText + Chars.LF +
	"INDEX BY
	|	RowCode
	|";
	
	FilterText1 = TMCommonUse.SelectionTextBySelectionCollection(Filter);
	QueryText = StrReplace(QueryText, "&FilterText1", FilterText1);
	
	Return QueryText;
	
EndFunction

Function RequestTextAndDocumentItems(Filter = Undefined) Export
	
	QueryTexts = New Array;
	QueryText =
	"SELECT
	|	WareFromOrder.CostGroupNumber        AS CostGroupNumber,
	|	VALUE(Document.ProductionStage2_2.EmptyRef) AS ProductionStage,
	|	WareFromOrder.RowCode                AS RowCode,
	|	TRUE                                 AS ThisIsAProductionIssueStage,
	|	WareFromOrder.Products             AS Products,
	|	WareFromOrder.Characteristic           AS Characteristic,
	|	WareFromOrder.Purpose               AS Purpose,
	|	WareFromOrder.Recipient               AS Recipient,
	|	WareFromOrder.ToExpenseAs         AS ToExpenseAs,
	|	WareFromOrder.ExpenseItem           AS ExpenseItem,
	|	WareFromOrder.DimensionOfExpenses        AS DimensionOfExpenses,
	|	WareFromOrder.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	UNDEFINED                           AS GLAccountSettings,
	|	WareFromOrder.Package                 AS Package,
	|	WareFromOrder.ProductCostElement        AS ProductCostElement,
	|	WareFromOrder.Price                     AS Price,
	|	WareFromOrder.Count               AS Count
	|INTO SideAndIntermediateRelease
	|FROM
	|	Document.SubcontractOrder2_5.SideAndIntermediateRelease AS WareFromOrder
	|	
	|	//&CompoundUnitGoodsInUnitOfMeasure
	|
	|WHERE
	|	WareFromOrder.Ref = &SubcontractOrder
	|	AND NOT WareFromOrder.Canceled
	|	AND &FilterText1
	|";
	QueryTexts.Add(QueryText);
	QueryText =
	"SELECT
	|	CostGroupNumbers.CostGroupNumber    AS CostGroupNumber,
	|	CostGroupNumbers.ReferenceOrder         AS ProductionStage,
	|	WareFromOrder.RowCode                AS RowCode,
	|	WareFromOrder.Ref.NextStageNo = 0 AS ThisIsAProductionIssueStage,
	|	WareFromOrder.Products             AS Products,
	|	WareFromOrder.Characteristic           AS Characteristic,
	|	WareFromOrder.Purpose               AS Purpose,
	|	WareFromOrder.Recipient               AS Recipient,
	|	WareFromOrder.ToExpenseAs         AS ToExpenseAs,
	|	WareFromOrder.ExpenseItem           AS ExpenseItem,
	|	WareFromOrder.DimensionOfExpenses        AS DimensionOfExpenses,
	|	WareFromOrder.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	WareFromOrder.GLAccountSettings     AS GLAccountSettings,
	|	WareFromOrder.Package                 AS Package,
	|	WareFromOrder.ProductCostElement        AS ProductCostElement,
	|	WareFromOrder.Price                     AS Price,
	|	WareFromOrder.Count               AS Count
	|FROM
	|	Document.SubcontractOrder2_5.References AS CostGroupNumbers
	|	
	|	INNER JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS WareFromOrder
	|	ON WareFromOrder.Ref = CostGroupNumbers.ReferenceOrder
	|
	|	//&CompoundUnitGoodsInUnitOfMeasure
	|
	|WHERE
	|	CostGroupNumbers.Ref = &SubcontractOrder
	|	AND NOT WareFromOrder.Canceled
	|	AND &FilterText1
	|";
	QueryTexts.Add(QueryText);
	QueryText = StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin());
	
	ApplyingParameters = ProductionServer.ParametersOfApplicationOfPieceProductInDimensionalUnit();
	ApplyingParameters.UnitGoodsInUnitsOfMeasure = False;
	ProductionServer.ApplyUnitItemSettingsInUnitOfMeasure(QueryText, "WareFromOrder", ApplyingParameters);	
	
	QueryText = QueryText + "
	|INDEX BY
	|	RowCode
	|";
	
	FilterText1 = TMCommonUse.SelectionTextBySelectionCollection(Filter);
	QueryText = StrReplace(QueryText, "&FilterText1", FilterText1);
	
	Return QueryText;
	
EndFunction

Function RequestTextProvisionOfMaterialsAndWorksOfDocument(Filter = Undefined) Export
	
	QueryTexts = New Array;
	QueryText =
	"SELECT
	|	SupplyWithMaterialsAndWorks.CostGroupNumber   AS CostGroupNumber,
	|	VALUE(Document.ProductionStage2_2.EmptyRef) AS ProductionStage,
	|	SupplyWithMaterialsAndWorks.Products        AS Products,
	|	SupplyWithMaterialsAndWorks.Characteristic      AS Characteristic,
	|	CASE
	|		WHEN SupplyWithMaterialsAndWorks.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		WHEN NOT SupplyWithMaterialsAndWorks.SupplyOption = VALUE(Enum.SupplyOptions.TransferedEarlier)
	|			AND NOT SupplyWithMaterialsAndWorks.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND SupplyWithMaterialsAndWorks.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Giveaway2_5)
	|			THEN SupplyWithMaterialsAndWorks.Purpose
	|		WHEN SupplyWithMaterialsAndWorks.Ref.TransferToSubcontractorForOrderPurpose
	|			AND NOT SupplyWithMaterialsAndWorks.SupplyOption = VALUE(Enum.SupplyOptions.TransferedEarlier)
	|			AND NOT SupplyWithMaterialsAndWorks.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN SupplyWithMaterialsAndWorks.Ref.TransferPurpose
	|		WHEN SupplyWithMaterialsAndWorks.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			OR SupplyWithMaterialsAndWorks.SupplyOption = VALUE(Enum.SupplyOptions.TransferedEarlier)
	|				AND SupplyWithMaterialsAndWorks.WithAssignment
	|			THEN SupplyWithMaterialsAndWorks.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                               AS Purpose,
	|	SupplyWithMaterialsAndWorks.Series               AS Series,
	|	SupplyWithMaterialsAndWorks.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	SupplyWithMaterialsAndWorks.Package            AS Package,
	|	SupplyWithMaterialsAndWorks.ProductCostElement   AS ProductCostElement,
	|	SupplyWithMaterialsAndWorks.SupplyOption  AS SupplyOption,
	|	SupplyWithMaterialsAndWorks.Count          AS Count
	|INTO MaterialsAndWorks
	|FROM
	|	Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks AS SupplyWithMaterialsAndWorks
	|	
	|	//&CompoundUnitGoodsInUnitOfMeasure
	|	
	|WHERE
	|	SupplyWithMaterialsAndWorks.Ref = &SubcontractOrder
	|	AND NOT SupplyWithMaterialsAndWorks.Canceled
	|	AND &FilterText1
	|";
	QueryTexts.Add(QueryText);
	QueryText =
	"SELECT
	|	CostGroupNumbers.CostGroupNumber                 AS CostGroupNumber,
	|	CostGroupNumbers.ReferenceOrder                      AS ProductionStage,
	|	SupplyWithMaterialsAndWorks.Products        AS Products,
	|	SupplyWithMaterialsAndWorks.Characteristic      AS Characteristic,
	|	CASE
	|		WHEN SupplyWithMaterialsAndWorks.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		WHEN NOT SupplyWithMaterialsAndWorks.SupplyOption = VALUE(Enum.SupplyOptions.TransferedEarlier)
	|			AND NOT SupplyWithMaterialsAndWorks.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND SupplyWithMaterialsAndWorks.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Giveaway2_5)
	|			THEN SupplyWithMaterialsAndWorks.Purpose
	|		WHEN CostGroupNumbers.Ref.TransferToSubcontractorForOrderPurpose
	|			AND NOT SupplyWithMaterialsAndWorks.SupplyOption = VALUE(Enum.SupplyOptions.TransferedEarlier)
	|			AND NOT SupplyWithMaterialsAndWorks.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN CostGroupNumbers.Ref.TransferPurpose
	|		WHEN SupplyWithMaterialsAndWorks.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND SupplyWithMaterialsAndWorks.WithAssignment
	|			THEN SupplyWithMaterialsAndWorks.Ref.Purpose
	|		WHEN SupplyWithMaterialsAndWorks.SupplyOption = VALUE(Enum.SupplyOptions.TransferedEarlier)
	|			AND SupplyWithMaterialsAndWorks.WithAssignment
	|			THEN SupplyWithMaterialsAndWorks.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                               AS Purpose,
	|	SupplyWithMaterialsAndWorks.Series               AS Series,
	|	SupplyWithMaterialsAndWorks.BatchesIndicationStatusRecipient AS BatchesIndicationStatus,
	|	SupplyWithMaterialsAndWorks.Package            AS Package,
	|	SupplyWithMaterialsAndWorks.ProductCostElement   AS ProductCostElement,
	|	SupplyWithMaterialsAndWorks.SupplyOption  AS SupplyOption,
	|	SupplyWithMaterialsAndWorks.Count          AS Count
	|FROM
	|	Document.SubcontractOrder2_5.References AS CostGroupNumbers
	|	
	|	INNER JOIN Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS SupplyWithMaterialsAndWorks
	|	ON SupplyWithMaterialsAndWorks.Ref = CostGroupNumbers.ReferenceOrder
	|	
	|	//&CompoundUnitGoodsInUnitOfMeasure
	|	
	|WHERE
	|	CostGroupNumbers.Ref = &SubcontractOrder
	|	AND NOT SupplyWithMaterialsAndWorks.Canceled
	|	AND &FilterText1
	|";
	QueryTexts.Add(QueryText);
	QueryText = StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin());
	
	ApplyingParameters = ProductionServer.ParametersOfApplicationOfPieceProductInDimensionalUnit();
	ApplyingParameters.UnitGoodsInUnitsOfMeasure = False;
	ProductionServer.ApplyUnitItemSettingsInUnitOfMeasure(QueryText, "SupplyWithMaterialsAndWorks", ApplyingParameters);	
	
	FilterText1 = TMCommonUse.SelectionTextBySelectionCollection(Filter);
	QueryText = StrReplace(QueryText, "&FilterText1", FilterText1);
	
	Return QueryText;
	
EndFunction

Function QueryTextDocumentServices(Filter = Undefined) Export
	
	QueryText =
	"SELECT
	|	Services.CostGroupNumber  AS CostGroupNumber,
	|	Services.RowCode          AS RowCode,
	|	ISNULL(References.ReferenceOrder, VALUE(Document.ProductionStage2_2.EmptyRef)) AS ProductionStage,
	|	Services.Products       AS Products,
	|	Services.Characteristic     AS Characteristic,
	|	Services.Count         AS Count,
	|	Services.VendorPriceKind  AS VendorPriceKind,
	|	Services.VATRate          AS VATRate,
	|	Services.Price               AS Price,
	|	Services.ProductCostElement  AS ProductCostElement
	|INTO OrderingServices
	|FROM
	|	Document.SubcontractOrder2_5.Services AS Services
	|	
	|	LEFT JOIN Document.SubcontractOrder2_5.References AS References
	|	ON References.Ref = Services.Ref
	|	AND References.CostGroupNumber = Services.CostGroupNumber
	|	
	|WHERE
	|	Services.Ref = &SubcontractOrder
	|	AND NOT Services.Canceled
	|	AND &FilterText1
	|
	|INDEX BY
	|	RowCode
	|";
	
	FilterText1 = TMCommonUse.SelectionTextBySelectionCollection(Filter);
	QueryText = StrReplace(QueryText, "&FilterText1", FilterText1);
	
	Return QueryText;
	
EndFunction

#Region Supply

// The function of embedding in the provision mechanism. It is necessary to add this function to the manager module
// to embed the commands for setting the order actions of the form "Reserve in stock", "To ensure"
// , etc. in the list of documents. If the list of documents (orders) of the same type needs to use different
// embedding parameters, depending on the values of the Attributes of a particular document.
// In this case
// , the Client documentation method is used in processing commands.Perform action on a list of different types of orders.
// 
// Parameters:
//  AllOrders - Array of DocumentRef.SubcontractOrder2_5
//  ActionCode - String - the conditional designation of the executed command: "ACTION_LOAD", "ACTION_RESERVATION", etc.
// Returns:
//  See ProvisionInDocumentsServer.NewParametersForExecutingCommandsAndSettingActions
Function ParametersForExecutingCommandsAndActions(AllOrders, ActionCode) Export
	
	Query = New Query();
	Query.SetParameter("Orders", AllOrders);
	Query.SetParameter("ThisIsPassedEarlier", ActionCode = "ACTION_TRANSMITTED");
	Query.SetParameter("ReserveItAsItComesIn",
		ActionCode = "ACTION_RESERVATION_REFERENCES");
	Query.Text =
		"SELECT
		|	Orders.Ref AS Ref
		|FROM
		|	Document.SubcontractOrder2_5 AS Orders
		|WHERE
		|	Orders.Ref IN(&Orders)
		|		AND NOT Orders.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
		|;
		|SELECT
		|	Orders.Ref AS Ref,
		|	Orders.SubcontractOrder AS SubcontractOrder
		|FROM
		|	Document.ProductionStage2_2 AS Orders
		|WHERE
		|	Orders.SubcontractOrder IN(&Orders)
		|		AND Orders.Posted
		|		AND NOT &ThisIsPassedEarlier
		|		AND (NOT Orders.DynamicStructure OR NOT &ReserveItAsItComesIn)
		|
		|ORDER BY
		|	SubcontractOrder
		|";
	
	QueryResult = Query.ExecuteBatch();
	Results = New Array();
	
	Result = ProvisionInDocumentsServer.StructureOrdersAndEmbeddingParameters();
	Result.Orders = QueryResult[0].Unload().UnloadColumn("Ref");
	Result.EmbeddingParameters = AvailableRemainingEmbeddingOptions();
	Results.Add(Result);
	
	AdditionalParameters = New Structure("ReturnProductionParametersOnSide", True);
	
	Result = ProvisionInDocumentsServer.StructureOrdersAndEmbeddingParameters();
	Result.Orders = QueryResult[1].Unload().UnloadColumn("Ref");
	Result.EmbeddingParameters = Documents.ProductionStage2_2.AvailableRemainingEmbeddingOptions(
		Undefined, AdditionalParameters);
	Results.Add(Result);
	
	Result = ProvisionInDocumentsServer.NewParametersForExecutingCommandsAndSettingActions();
	Result.ActionCode = ActionCode;
	Result.ExecutionParameters = Results;
	
	// Clarification of parameters related to the need to ask a question about shipment by one date.
	NeedQuestion = False;
	DateWhenTheNewLinesWereShipped = BegOfDay(CurrentSessionDate());
	Query = New Query();
	Query.SetParameter("DateWhenTheNewLinesWereShipped", DateWhenTheNewLinesWereShipped);
	
	If ActionCode = "ACTION_LOAD" Then
		
		Orders = Results[0].Orders;
		EmbeddingParameters = Results[0].EmbeddingParameters;
		If Not NeedQuestion And Orders.Count() > 0 Then
			
			Text =
				"SELECT
				|	Table.Ref AS Ref
				|FROM
				|	&TableOverridable AS Table
				|WHERE
				|	Table.Ref IN(&Orders)
				|	AND Table.Posted
				|	AND &ConditionOverridable <> UNDEFINED
				|	AND &ConditionOverridable < &DateWhenTheNewLinesWereShipped";
				
			Text = StrReplace(Text, "&TableOverridable", EmbeddingParameters.ObjectName);
			Text = StrReplace(Text, "&ConditionOverridable",
				EmbeddingParameters.ExpressionForQuestionWhenPerformingActionInOrderList);
			Query.Text = Text;
			Query.SetParameter("Orders", Orders);
			OrdersToCheckNeed = Query.Execute().Unload().UnloadColumn("Ref");
			NeedQuestion = ProvisionInDocumentsServer.ThereAreNeedsForOrders(OrdersToCheckNeed);
			
		EndIf;
		
		Orders = Results[1].Orders;
		EmbeddingParameters = Results[0].EmbeddingParameters;
		If Not NeedQuestion And Orders.Count() > 0 Then
			
			Text =
				"SELECT
				|	Table.SubcontractOrder AS Ref
				|FROM
				|	&TableOverridable AS Table
				|WHERE
				|	Table.Ref IN(&Orders)
				|	AND Table.Posted
				|	AND &ConditionOverridable <> UNDEFINED
				|	AND &ConditionOverridable < &DateWhenTheNewLinesWereShipped";
				
			Text = StrReplace(Text, "&TableOverridable", EmbeddingParameters.ObjectName);
			Text = StrReplace(Text, "&ConditionOverridable",
				EmbeddingParameters.ExpressionForQuestionWhenPerformingActionInOrderList);
			Query.Text = Text;
			Query.SetParameter("Orders", Orders);
			OrdersToCheckNeed = Query.Execute().Unload().UnloadColumn("Ref");
			NeedQuestion = ProvisionInDocumentsServer.ThereAreNeedsForOrders(OrdersToCheckNeed);
			
		EndIf;
		
		If NeedQuestion Then
			
			Result.NeedQuestion = True;
			Result.DateWhenTheNewLinesWereShipped = DateWhenTheNewLinesWereShipped;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a table for the goods of the document for the creation mechanism based on the securing order.
//
// Parameters:
//  Ref - DocumentRef.SubcontractOrder2_5 - the document for which you need to get the goods
//  CreationParameters - See ProvisionInDocumentsServer.ProductSelectionParametersForCreatingSecuringOrder
//  TempTablesManager - TempTablesManager - temporary table manager where a table with columns will be created:
//   * LineNumber - Number - Line number
//   * Products - CatalogRef.Products - Products
//   * Characteristic - CatalogRef.ItemsCharacteristics - Characteristic
//   * Package - CatalogRef.PackagesAndUnitsOfMeasure - Package
//   * Warehouse - CatalogRef.Warehouses - Warehouse
//   * Department - CatalogRef.BusinessStructure - Department
//   * Purpose - CatalogRef.Assignments - Purpose
//   * SupplyOption - EnumRef.SupplyOptions - security option
//   * WithAssignment - Boolean - WithAssignment
//   * QuantityOfUnits - Number - number of units
//   * CountByDocument - Number - Number of packages
Procedure GoodsOfDocumentForCreatingSecuringOrder(Ref, CreationParameters, TempTablesManager) Export
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("ItemsTypes", CreationParameters.ItemsTypes);
	Query.SetParameter("Ref", Ref);
	Query.Text =
		"SELECT
		|	Goods.LineNumber AS LineNumber,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Package AS Package,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Ref.Department AS Department,
		|	CASE
		|		WHEN Goods.WithAssignment
		|			THEN
		|				Goods.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	Goods.SupplyOption AS SupplyOption,
		|	Goods.WithAssignment AS WithAssignment,
		|	Goods.DateOfShipment AS DateOfShipment,
		|	Goods.Count AS NumberOfUnitsPerDocument,
		|	Goods.NumberOfPackages AS CountByDocument
		|INTO DocumentGoods
		|FROM
		|	Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks AS Goods
		|WHERE
		|	Goods.Ref = &Ref
		|		AND NOT Goods.Canceled
		|		AND Goods.Products.ItemsType IN(&ItemsTypes)
		|
		|UNION ALL
		|
		|SELECT
		|	Goods.LineNumber AS LineNumber,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Package AS Package,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Ref.Department AS Department,
		|	CASE
		|		WHEN Goods.WithAssignment
		|			THEN
		|				Goods.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	Goods.SupplyOption AS SupplyOption,
		|	Goods.WithAssignment AS WithAssignment,
		|	Goods.DateOfShipment AS DateOfShipment,
		|	Goods.Count AS NumberOfUnitsPerDocument,
		|	Goods.NumberOfPackages AS CountByDocument
		|FROM
		|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS Goods
		|WHERE
		|	Goods.Ref.SubcontractOrder = &Ref
		|		AND NOT Goods.Canceled
		|		AND NOT Goods.Produced
		|		AND Goods.Products.ItemsType IN(&ItemsTypes)
		|";
	
	Query.Execute();
	
EndProcedure

// Performs additional actions related to filling out the security in the document.
// Parameters:
//  Object - FormDataStructure, DocumentObject.SubcontractOrder2_5 - The document in which the security was filled in.
//  Changes - ValueTable - Table of changes to the document after filling in the security.
//  Mode - String - The mode that defines the context of the software filling.
//  FillParameters - Structure - Fill-in parameters.
//
Procedure AfterFillingOutCollateral(Object, Changes, Mode, FillParameters) Export
	
	// Filling the warehouse if it was transferred earlier and became something else.
	StructureOfActions = New Structure();
	If Object.GroupCosts =
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages") Then
		ActionParameters = New Structure("Department, WarehouseFieldName", Object.Department, "Warehouse");
		StructureOfActions.Insert("CheckFillProductionWarehouse" , ActionParameters);
	Else
		WarehouseMaterialsGroup = Catalogs.Warehouses.IsFolder(Object.MaterialsWarehouse);
		ActionParameters =
			BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(
				Object,
				WarehouseMaterialsGroup,
				"MaterialsWarehouse",
				"Warehouse");
		
		If Not GetFunctionalOption("UseSeveralWarehouses") Then
			ActionParameters.DefaultWarehouse = TMCommonUse.GetCheckWarehouseByDefault();
		EndIf;
		
		StructureOfActions.Insert("CheckFillWarehouse" , ActionParameters);
		
	EndIf;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	For Each Update In Changes Do
		
		String = Update.String;
		If String.SupplyOption <> Enums.SupplyOptions.TransferedEarlier Then
			If Not ValueIsFilled(String.Warehouse) Then
				RowsToProcess.Add(String);
			EndIf;
		EndIf;
		
	EndDo;
				
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.SupplyWithMaterialsAndWorks,
		CachedValues);
	
	// Clearing the warehouse if it has become earlier.
	If ProvisionInDocumentsClientServer.ThisIsSoftwareChangeMode(Mode) Then
		ProvisionInDocumentsServer.FillInWarehouseAndShipmentDateWhenChangeWasPassedEarlier(Changes);
	EndIf;
	
	ProvisionInDocumentsServer.UpdateShipmentDate(
		FillParameters,
		Object.NotShipInInstallments,
		Object.DateOfShipment,
		Object.SupplyWithMaterialsAndWorks,
		"DateOfShipment",
		True);
	
	If ProvisionInDocumentsClientServer.YouNeedToCheckFillInShipmentDateForShipLines(Mode) Then
		
		ProvisionInDocumentsServer.CheckFillInShipmentDateForShipLines(
			Changes.UnloadColumn("String"),
			"DateOfShipment",
			Object.NotShipInInstallments,
			Object.DateOfShipment);
			
	EndIf;
	
	ProvisionInDocumentsServer.RecalculateNumberOfUnits(Changes, Object.SupplyWithMaterialsAndWorks);
	Attributes = "Sum";
	OrdersServer.RecalculateDependentPropsAfterSplittingRows(Changes, Attributes);
	SeriesSpecificationParameters = SeriesSpecificationParameters(Object);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
	
	ThereIsShip = False;
	ShippingOrders_ = New Array;
	If ProvisionInDocumentsClientServer.ThisIsSoftwareChangeMode(Mode) Then
		For Each CurrentData In Changes Do
			If CurrentData.SupplyOption = Enums.SupplyOptions.Ship Then
				ThereIsShip = True;
				If TypeOf(Object) = Type("FormDataStructure") Then
					ShippingOrders_.Add(
						Object.SupplyWithMaterialsAndWorks.FindByID(CurrentData.Id).ReferenceOrder);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	For Each ReferenceOrder In ShippingOrders_ Do
		TheStructureOfTheSearch = New Structure("ReferenceOrder", ReferenceOrder);
		FoundRows = Object.References.FindRows(TheStructureOfTheSearch);
		If Not FoundRows.Count() = 0
			And (FoundRows[0].Status = Enums.StatusesOfProductionStages2_2.BeingGenerated
				Or FoundRows[0].Status = Enums.StatusesOfProductionStages2_2.Generated1
				Or FoundRows[0].Status = Enums.StatusesOfProductionStages2_2.ForCompletion) Then
			FoundRows[0].Status = Enums.StatusesOfProductionStages2_2.Initiated;
		EndIf;
	EndDo;
	If ThereIsShip
		And Object.Status = Enums.TollingOrderStatuses.NotApproved Then
		Object.Status = Enums.TollingOrderStatuses.ForFulfillment;
	EndIf;
	
EndProcedure

#EndRegion

#Region LinesOfBusiness

// See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.FillInAssignmentInHeader = True;
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "ManufacturedProducts,SideAndIntermediateRelease";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("ManufacturedProducts", TableOfConditions);
	DocumentProcessingProcedure.StringProcessingConditions.Insert("SideAndIntermediateRelease", TableOfConditions);
	
	Return DocumentProcessingProcedure;
	
EndFunction

#EndRegion

// Saves the interactive editing attribute to a secure repository.
// It is necessary for the filling check to work correctly.
// 
// Parameters:
// 	Object - FormDataStructure, DocumentObject.SubcontractOrder2_5 - Object
//
Procedure SetInteractiveEditingMark(Object) Export
	
	SetPrivilegedMode(True);
	
	DataKey =
		?(ValueIsFilled(Object.Ref),
			"_" + StrReplace(String(Object.Ref.UUID()), "-", "_"),
			"SubcontractOrder2_5");
	
	Common.WriteDataToSecureStorage(
		Users.AuthorizedUser(),
		Object.Ref,
		DataKey);
	
	SetPrivilegedMode(False);
	
EndProcedure


// Gets the attribute of interactive object editing
// 
// Parameters:
// 	Object - FormDataStructure, DocumentObject.SubcontractOrder2_5 - Object
// Returns:
// 	Boolean - LongDesc
//
Function InteractiveEditing(Object) Export
	
	SetPrivilegedMode(True);
	
	AuthorizedUser = Users.AuthorizedUser();
	
	DataKey =
		?(ValueIsFilled(Object.Ref),
			"_" + StrReplace(String(Object.Ref.UUID()), "-", "_"),
			"SubcontractOrder2_5");
	
	InteractiveEditing =
		Not Common.ReadDataFromSecureStorage(AuthorizedUser, DataKey) = Undefined;
	
	SetPrivilegedMode(False);
	
	Return InteractiveEditing;
	
EndFunction

// Removes the flag for interactive item editing
// 
// Parameters:
// 	Object - FormDataStructure, DocumentObject.SubcontractOrder2_5 - Object
//
Procedure UncheckInteractiveEditing(Object) Export
	
	SetPrivilegedMode(True);
	
	AuthorizedUser = Users.AuthorizedUser();
	
	DataKey =
		?(ValueIsFilled(Object.Ref),
			"_" + StrReplace(String(Object.Ref.UUID()), "-", "_"),
			"SubcontractOrder2_5");
	
	Common.DeleteDataFromSecureStorage(AuthorizedUser, DataKey);
	
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#Region Private

#Region Posting

#Region InitializationOfEvent

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	SubcontractOrder.Ref                           AS SubcontractOrder,
	|	SubcontractOrder.Date                             AS Period,
	|	SubcontractOrder.Currency                           AS Currency,
	|	SubcontractOrder.PriceIncludesVAT                  AS PriceIncludesVAT,
	|	SubcontractOrder.Status                           AS Status,
	|	SubcontractOrder.Partner                          AS Partner,
	|	SubcontractOrder.Counterparty                       AS Counterparty,
	|	SubcontractOrder.Organization                      AS Organization,
	|	SubcontractOrder.Department                    AS Department,
	|	SubcontractOrder.BusinessOperation            AS BusinessOperation,
	|	SubcontractOrder.Contract                          AS Contract,
	|	PRESENTATION(SubcontractOrder.Contract)           AS ContractPresentation,
	|	SubcontractOrder.GroupCosts                AS GroupCosts,
	|	SubcontractOrder.LeaveProductsAtSubcontractor AS LeaveProductsAtSubcontractor,
	|	SubcontractOrder.Purpose                       AS Purpose,
	|	SubcontractOrder.Priority                        AS Priority,
	|	SubcontractOrder.ProcessingByOrder              AS ProcessingByOrder,
	|	SubcontractOrder.Manager                         AS Manager,
	|	SubcontractOrder.Author                            AS Author,
	|	SubcontractOrder.Number                            AS Number,
	|	SubcontractOrder.Comment                      AS Comment,
	|	SubcontractOrder.DocumentAmount                   AS DocumentAmount,
	|	SubcontractOrder.Posted                         AS Posted,
	|	SubcontractOrder.DeletionMark                  AS DeletionMark,
	|	SubcontractOrder.DateAccordingToInformationFromPartner             AS DateAccordingToInformationFromPartner,
	|	SubcontractOrder.NumberAccordingToPartnerData            AS NumberAccordingToPartnerData,
	|	
	|	CASE
	|		WHEN SubcontractOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                               AS ContractSettlements,
	|	
	|	CASE
	|		WHEN SubcontractOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                               AS CalculationsOnInvoices,
	|	SubcontractOrder.LineOfBusiness          AS LineOfBusiness,
	|
	|	ISNULL(SubcontractOrder.Contract.ExecutionScheduleIsSpecified, FALSE) AS ExecutionScheduleInContract,
	|	SubcontractOrder.GoodsReceiptOption            AS GoodsReceiptOption
	|FROM
	|	Document.SubcontractOrder2_5 AS SubcontractOrder
	|WHERE
	|	SubcontractOrder.Ref = &Ref
	|";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	InvoiceIsOrder = PurchasesServer.OrderForAcceptanceOfGoodsConsignmentNote(Attributes.GoodsReceiptOption);
	
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID(TypeOf(DocumentRef)));
	Query.SetParameter("InvoiceIsOrder", InvoiceIsOrder);
	
	If ValueIsFilled(Attributes.Contract) Then
		StringPattern = "vi = 'Theo hợp đồng ""%1""';
						|ru = 'По договору ""%1""';
						|en = 'Under the ""%1"" contract';
						|it = 'In base al contratto ""%1""';
						|pl = 'Wg kontraktu ""%1""';
						|tr = '""%1"" sözleşmesi kapsamında'"; // @NStr
		ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.ContractPresentation);
	EndIf;
	Query.SetParameter("ContractInformation", ContractInformation);
	
EndProcedure

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName           = FullObjectName();
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	TemporaryTableQueryTexts = New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("ContractInformation", """""");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentTable";
		
		TemporaryTableQueryTexts.Insert(
			"TTDocumentRegistryEntries",
			QueryTextTTDocumentRegistryEntries(Undefined, QueryTexts));
		
	Else
		
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydına göre hareketlerin düzenlenmesi talebinin metin uyarlaması uygulanmadı.'");
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
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
		
	Else
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

#Region TextsOfRequestsForHolding

#Region TemporaryTable

Function QueryTextTTDateOfReceiptOfProducts(Query, QueryTexts)
	
	RegisterName = "TTDateOfReceiptOfProducts";
	
	QueryText =
	"SELECT
	|	DatesOfReceipt.Ref AS Ref,
	|	DatesOfReceipt.CostGroupNumber AS CostGroupNumber,
	|	MAX(DatesOfReceipt.DateOfReceipt) AS DateOfReceipt
	|INTO TTDateOfReceiptOfProducts
	|FROM
	|	Document.SubcontractOrder2_5.ManufacturedProducts AS DatesOfReceipt
	|WHERE
	|	DatesOfReceipt.Ref IN (&Ref)
	|
	|GROUP BY
	|	DatesOfReceipt.Ref,
	|	DatesOfReceipt.CostGroupNumber
	|
	|UNION ALL
	|
	|SELECT
	|	DatesOfReceipt.Ref AS Ref,
	|	DatesOfReceipt.CostGroupNumber AS CostGroupNumber,
	|	MAX(DatesOfReceipt.DateOfReceipt) AS DateOfReceipt
	|FROM
	|	(SELECT
	|		TableOfOrders.Ref AS Ref,
	|		TableOfOrders.CostGroupNumber AS CostGroupNumber,
	|		DatesOfReceipt.ProductionDate AS DateOfReceipt
	|	FROM
	|		Document.SubcontractOrder2_5.References AS TableOfOrders
	|	
	|		INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS DatesOfReceipt
	|		ON DatesOfReceipt.Ref = TableOfOrders.ReferenceOrder
	|
	|	WHERE
	|		TableOfOrders.Ref IN (&Ref)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableOfOrders.Ref AS Ref,
	|		TableOfOrders.CostGroupNumber AS CostGroupNumber,
	|		DatesOfReceipt.ProductionDate AS DateOfReceipt
	|	FROM
	|		Document.SubcontractOrder2_5.References AS TableOfOrders
	|	
	|		INNER JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS DatesOfReceipt
	|		ON DatesOfReceipt.Ref = TableOfOrders.ReferenceOrder
	|
	|	WHERE
	|		TableOfOrders.Ref IN (&Ref)
	|	) AS DatesOfReceipt
	|GROUP BY
	|	DatesOfReceipt.Ref,
	|	DatesOfReceipt.CostGroupNumber
	|	";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTemporaryTableCurrencyExchangeRates(Query, QueryTexts)
	
	RegisterName = "TemporaryTableCurrencyExchangeRates";
	
	QueryText = "
	|SELECT
	|	RelativeExchangeRatesSliceLast.Currency AS Currency,
	|	RelativeExchangeRatesSliceLast.CourseNumerator AS CourseNumerator,
	|	RelativeExchangeRatesSliceLast.CourseDenominator AS CourseDenominator
	|INTO TemporaryTableCurrencyExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(
	|			&Period,
	|			BaseCurrency IN
	|				(SELECT
	|					DefaultBaseCurrency.Value AS Value
	|				FROM
	|					Constant.DefaultBaseCurrency AS DefaultBaseCurrency)
	|		) AS RelativeExchangeRatesSliceLast
	|
	|INDEX BY
	|	Currency
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTDocumentRegistryEntries(Query, QueryTexts)
	
	RegisterName = "TTDocumentRegistryEntries";
	
	QueryText = "
	|SELECT
	|	NestedQuery.Ref                        AS Ref,
	|	NestedQuery.BusinessOperation         AS BusinessOperation,
	|	NestedQuery.StorageLocation                 AS StorageLocation,
	|	MIN(NestedQuery.AdditionalRecord) AS AdditionalRecord
	|INTO TTDocumentRegistryEntries
	|FROM
	|	(SELECT DISTINCT
	|		DocumentTable.Ref AS Ref,
	|		DocumentTable.BusinessOperation AS BusinessOperation,
	|		UNDEFINED            AS StorageLocation,
	|		FALSE                    AS AdditionalRecord
	|	FROM
	|		Document.SubcontractOrder2_5 AS DocumentTable
	|	WHERE
	|		DocumentTable.Ref = &Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentTable.Ref     AS Ref,
	|		VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5) AS BusinessOperation,
	|		DocumentTable.Recipient AS StorageLocation,
	|		TRUE                      AS AdditionalRecord
	|	FROM
	|		Document.SubcontractOrder2_5.ManufacturedProducts AS DocumentTable
	|	WHERE
	|		DocumentTable.Ref = &Ref
	|		AND NOT DocumentTable.Canceled
	|		AND NOT DocumentTable.ToExpenseAs
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentTable.Ref     AS Ref,
	|		VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5) AS BusinessOperation,
	|		DocumentTable.Recipient AS StorageLocation,
	|		TRUE                      AS AdditionalRecord
	|	FROM
	|		Document.SubcontractOrder2_5.SideAndIntermediateRelease AS DocumentTable
	|	WHERE
	|		DocumentTable.Ref = &Ref
	|		AND NOT DocumentTable.Canceled
	|		AND NOT DocumentTable.ToExpenseAs
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentTable.Ref AS Ref,
	|		VALUE(Enum.BusinessTransactions.TransferToToller2_5) AS BusinessOperation,
	|		CASE
	|			WHEN DocumentTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|				THEN DocumentTable.Ref.Department
	|			ELSE DocumentTable.Warehouse
	|		END                   AS StorageLocation,
	|		TRUE                  AS AdditionalRecord
	|	FROM
	|		Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks AS DocumentTable
	|	WHERE
	|		DocumentTable.Ref = &Ref
	|		AND NOT DocumentTable.Canceled
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentTable.Ref           AS Ref,
	|		VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5) AS BusinessOperation,
	|		TableOfDocumentStages.Recipient AS StorageLocation,
	|		TRUE                            AS AdditionalRecord
	|	FROM
	|		Document.SubcontractOrder2_5 AS DocumentTable
	|		
	|		INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS TableOfDocumentStages
	|		ON TableOfDocumentStages.Ref.SubcontractOrder = DocumentTable.Ref
	|	WHERE
	|		DocumentTable.Ref = &Ref
	|		AND NOT TableOfDocumentStages.Canceled
	|		AND NOT TableOfDocumentStages.ToExpenseAs
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentTable.Ref           AS Ref,
	|		VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5) AS BusinessOperation,
	|		TableOfDocumentStages.Recipient AS StorageLocation,
	|		TRUE                            AS AdditionalRecord
	|	FROM
	|		Document.SubcontractOrder2_5 AS DocumentTable
	|		
	|		INNER JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS TableOfDocumentStages
	|		ON TableOfDocumentStages.Ref.SubcontractOrder = DocumentTable.Ref
	|	WHERE
	|		DocumentTable.Ref = &Ref
	|		AND NOT TableOfDocumentStages.Canceled
	|		AND NOT TableOfDocumentStages.ToExpenseAs
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentTable.Ref      AS Ref,
	|		VALUE(Enum.BusinessTransactions.TransferToToller2_5) AS BusinessOperation,
	|		CASE
	|			WHEN TableOfDocumentStages.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|				THEN DocumentTable.Department
	|			ELSE TableOfDocumentStages.Warehouse
	|		END                        AS StorageLocation,
	|		TRUE                       AS AdditionalRecord
	|	FROM
	|		Document.SubcontractOrder2_5 AS DocumentTable
	|		
	|		INNER JOIN Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS TableOfDocumentStages
	|		ON TableOfDocumentStages.Ref.SubcontractOrder = DocumentTable.Ref
	|	WHERE
	|		DocumentTable.Ref = &Ref
	|		AND NOT TableOfDocumentStages.Canceled
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Ref,
	|	NestedQuery.BusinessOperation,
	|	NestedQuery.StorageLocation
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

Function QueryTextTablePurchaseOrders(Query, QueryTexts, Registers)
	
	RegisterName = "PurchaseOrders";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText =
	"
	// Output products (ordered, ready for registration)
	|SELECT
	|	GoodsTable.LineNumber              AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Ref                   AS PurchaseOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.RowCode                AS RowCode,
	|	UNDEFINED                           AS Warehouse,
	|	CASE
	|		WHEN &Status IN (
	|				VALUE(Enum.TollingOrderStatuses.ForFulfillment),
	|				VALUE(Enum.TollingOrderStatuses.Closed))
	|			AND NOT GoodsTable.Canceled
	|			THEN GoodsTable.Count
	|		ELSE 0
	|	END                                  AS ToRegister,
	|	0                                      AS ToReceive,
	|	GoodsTable.Count               AS Ordered,
	|	0                                      AS Sum,
	|	UNDEFINED                           AS CancellationReason
	|FROM
	|	Document.SubcontractOrder2_5.ManufacturedProducts AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|
	|UNION ALL
	|
	// Output items (ordered, cancelled)
	|SELECT
	|	GoodsTable.LineNumber              AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Ref                   AS PurchaseOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.RowCode                AS RowCode,
	|	UNDEFINED                           AS Warehouse,
	|	0                                      AS ToRegister,
	|	0                                      AS ToReceive,
	|	-GoodsTable.Count              AS Ordered,
	|	0                                      AS Sum,
	|	GoodsTable.CancellationReason            AS CancellationReason
	|FROM
	|	Document.SubcontractOrder2_5.ManufacturedProducts AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Canceled
	|
	|UNION ALL
	|
	// Output products (to be received)
	|SELECT
	|	GoodsTable.LineNumber              AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Ref                   AS PurchaseOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.RowCode                AS RowCode,
	|	GoodsTable.Recipient               AS Warehouse,
	|	0                                      AS ToRegister,
	|	GoodsTable.Count               AS ToReceive,
	|	0                                      AS Ordered,
	|	0                                      AS Sum,
	|	UNDEFINED                           AS CancellationReason
	|FROM
	|	Document.SubcontractOrder2_5.ManufacturedProducts AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND NOT GoodsTable.Canceled
	|	AND NOT GoodsTable.ToExpenseAs
	|	AND GoodsTable.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND &Status IN (
	|		VALUE(Enum.TollingOrderStatuses.ForFulfillment),
	|		VALUE(Enum.TollingOrderStatuses.Closed))
	|	AND NOT &LeaveProductsAtSubcontractor
	|
	|UNION ALL
	|
	// By-products (ordered, ready for registration)
	|SELECT
	|	GoodsTable.LineNumber              AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Ref                   AS PurchaseOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.RowCode                AS RowCode,
	|	UNDEFINED                           AS Warehouse,
	|	CASE
	|		WHEN &Status IN (
	|				VALUE(Enum.TollingOrderStatuses.ForFulfillment),
	|				VALUE(Enum.TollingOrderStatuses.Closed))
	|			AND NOT GoodsTable.Canceled
	|			THEN GoodsTable.Count
	|		ELSE 0
	|	END                                  AS ToRegister,
	|	0                                      AS ToReceive,
	|	GoodsTable.Count               AS Ordered,
	|	0                                      AS Sum,
	|	UNDEFINED                           AS CancellationReason
	|FROM
	|	Document.SubcontractOrder2_5.SideAndIntermediateRelease AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|
	|UNION ALL
	|
	// By-products (ordered, cancelled)
	|SELECT
	|	GoodsTable.LineNumber              AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Ref                   AS PurchaseOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.RowCode                AS RowCode,
	|	UNDEFINED                           AS Warehouse,
	|	0                                      AS ToRegister,
	|	0                                      AS ToReceive,
	|	-GoodsTable.Count              AS Ordered,
	|	0                                      AS Sum,
	|	GoodsTable.CancellationReason            AS CancellationReason
	|FROM
	|	Document.SubcontractOrder2_5.SideAndIntermediateRelease AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Canceled
	|
	|UNION ALL
	|
	// By-products (to be received)
	|SELECT
	|	GoodsTable.LineNumber              AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Ref                   AS PurchaseOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.RowCode                AS RowCode,
	|	GoodsTable.Recipient               AS Warehouse,
	|	0                                      AS ToRegister,
	|	GoodsTable.Count               AS ToReceive,
	|	0                                      AS Ordered,
	|	0                                      AS Sum,
	|	UNDEFINED                           AS CancellationReason
	|FROM
	|	Document.SubcontractOrder2_5.SideAndIntermediateRelease AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND NOT GoodsTable.Canceled
	|	AND NOT GoodsTable.ToExpenseAs
	|	AND GoodsTable.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND &Status IN (
	|		VALUE(Enum.TollingOrderStatuses.ForFulfillment),
	|		VALUE(Enum.TollingOrderStatuses.Closed))
	|	AND NOT &LeaveProductsAtSubcontractor
	|
	|UNION ALL
	|
	// Services (for registration)
	|SELECT
	|	GoodsTable.LineNumber              AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Ref                   AS PurchaseOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.RowCode                AS RowCode,
	|	UNDEFINED                           AS Warehouse,
	|	GoodsTable.Count               AS ToRegister,
	|	0                                      AS ToReceive,
	|	0                                      AS Ordered,
	|	GoodsTable.Sum                    AS Sum,
	|	UNDEFINED                           AS CancellationReason
	|FROM
	|	Document.SubcontractOrder2_5.Services AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &Status IN (
	|		VALUE(Enum.TollingOrderStatuses.ForFulfillment),
	|		VALUE(Enum.TollingOrderStatuses.Closed))
	|
	|UNION ALL
	|
	// Services (cancelled)
	|SELECT
	|	GoodsTable.LineNumber              AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Ref                   AS PurchaseOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.RowCode                AS RowCode,
	|	UNDEFINED                           AS Warehouse,
	|	-GoodsTable.Count              AS ToRegister,
	|	0                                      AS ToReceive,
	|	0                                      AS Ordered,
	|	-GoodsTable.Sum                   AS Sum,
	|	GoodsTable.CancellationReason            AS CancellationReason
	|FROM
	|	Document.SubcontractOrder2_5.Services AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &Status IN (
	|		VALUE(Enum.TollingOrderStatuses.ForFulfillment),
	|		VALUE(Enum.TollingOrderStatuses.Closed))
	|	AND GoodsTable.Canceled
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
	|	BEGINOFPERIOD(&Period, DAY) AS Period,
	|	GoodsTable.Ref AS ReferenceOrder,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.RowCode AS RowCode,
	|	GoodsTable.Warehouse AS Warehouse,
	|	CASE
	|		WHEN GoodsTable.Canceled
	|			THEN VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Canceled)
	|		ELSE VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Ordered)
	|	END AS Factor,
	|	GoodsTable.Count AS Count,
	|	0 AS Sum
	|FROM
	|	Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND NOT GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT GoodsTable.SupplyOption = VALUE(Enum.SupplyOptions.TransferedEarlier)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.DateOfShipment AS Period,
	|	GoodsTable.Ref AS ReferenceOrder,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.RowCode AS RowCode,
	|	GoodsTable.Warehouse AS Warehouse,
	|	TableOfIndicators.Ref AS Factor,
	|	GoodsTable.Count AS Count,
	|	0 AS Sum
	|FROM
	|	Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks AS GoodsTable
	|		INNER JOIN Enum.IndicatorsOfShipmentAndReturnReferences AS TableOfIndicators
	|		ON TableOfIndicators.Ref IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip))
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &Status IN
	|	(VALUE(Enum.TollingOrderStatuses.ForFulfillment),
	|		VALUE(Enum.TollingOrderStatuses.Closed))
	|	AND NOT GoodsTable.Canceled
	|	AND NOT GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND GoodsTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|
	|ORDER BY
	|	LineNumber,
	|	Factor";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDocumentRegistryEntries", QueryTexts) Then
		QueryTextTTDocumentRegistryEntries(Query, QueryTexts);
	EndIf; 
	
	QueryText = 
	"SELECT
	|	&Ref                  AS Ref,
	|	&Period                  AS IBDocumentDate,
	|	&Number                   AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	&Organization             AS Organization,
	|	DocumentRegistryEntries.BusinessOperation AS BusinessOperation,
	|	&Partner                 AS Partner,
	|	&Counterparty              AS Counterparty,
	|	&Contract                 AS Contract,
	|	DocumentRegistryEntries.StorageLocation AS StorageLocation,
	|	&LineOfBusiness AS LineOfBusiness,
	|	&Department           AS Department,
	|	&Manager                AS EmployeeResponsible,
	|	&Author                   AS Author,
	|	&Comment             AS Comment,
	|	&Currency                  AS Currency,
	|	&DocumentAmount          AS Sum,
	|	&Status                  AS Status,
	|	&Posted                AS Posted,
	|	&DeletionMark         AS DeletionMark,
	|	DocumentRegistryEntries.AdditionalRecord AS AdditionalRecord,
	|	&ContractInformation    AS More,
	|	&DateAccordingToInformationFromPartner    AS SourceDocumentDate,
	|	&NumberAccordingToPartnerData   AS SourceDocumentNumber,
	|	&Period                  AS RecordingInAccountingDate,
	|	&Priority               AS Priority
	|FROM
	|	Document.SubcontractOrder2_5 AS DocumentTable
	|	
	|	INNER JOIN TTDocumentRegistryEntries AS DocumentRegistryEntries
	|	ON DocumentRegistryEntries.Ref = DocumentTable.Ref
	|
	|WHERE
	|	DocumentTable.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableItemsPricesOfVendor(Query, QueryTexts, Registers)
	
	RegisterName = "ItemsPricesOfVendor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TemporaryTableCurrencyExchangeRates", QueryTexts) Then
		QueryTextTemporaryTableCurrencyExchangeRates(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	&Period                         AS Period,
	|	Services.Products             AS Products,
	|	Services.Characteristic           AS Characteristic,
	|	Services.VendorPriceKind        AS VendorPriceKind,
	|	Services.VendorPriceKind.Currency AS Currency,
	|	&Partner                        AS Partner,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|	CAST(
	|		AVG(
	|			Services.Price
	|				* CASE
	|					WHEN
	|						&Currency <> Services.VendorPriceKind.Currency
	|					THEN
	|						CASE
	|							WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|								AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|								AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|								AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|							THEN 
	|								(Currency_Rates.CourseNumerator * CurrencyRatesPrices.CourseDenominator)
	|								/ (CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator)
	|							ELSE
	|								0
	|						END
	|					ELSE 
	|						1
	|				END
	|		) AS NUMBER(31,2))          AS Price
	|FROM
	|	Document.SubcontractOrder2_5.Services AS Services
	|
	|	LEFT JOIN TemporaryTableCurrencyExchangeRates AS Currency_Rates
	|	ON Currency_Rates.Currency = &Currency
	|	
	|	LEFT JOIN TemporaryTableCurrencyExchangeRates AS CurrencyRatesPrices
	|	ON CurrencyRatesPrices.Currency = Services.VendorPriceKind.Currency
	|
	|WHERE
	|	Services.Ref = &Ref
	|	AND NOT Services.VendorPriceKind = VALUE(Catalog.VendorPriceTypes.EmptyRef)
	|	AND Services.Ref.RegisterVendorPrices
	|	AND NOT Services.Canceled
	|
	|GROUP BY
	|	Services.Products,
	|	Services.Characteristic,
	|	Services.VendorPriceKind
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers)
	
	#Region LinesOfBusiness
	
	RegisterName = "TemporaryTableOfLinesOfBusiness";
	
	QueryTextLinesOfBusiness = 
		"SELECT
		|	DocumentDataHeader.ARAPObject AS ARAPObject
		|FROM
		|	Document.SubcontractOrder2_5 AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)";
		
	QueryTextLinesOfBusiness = ARAPAccountingPosting.GetTableOfLinesOfBusiness(QueryTextLinesOfBusiness);

	QueryTexts.Add(QueryTextLinesOfBusiness, RegisterName);
	
	#EndRegion
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDateOfReceiptOfProducts", QueryTexts) Then
		QueryTextTTDateOfReceiptOfProducts(Query, QueryTexts);
	EndIf; 
	
	TextPaymentPlans =
		"SELECT
		|	Table.Ref                 AS Ref,
		|	Table.Ref.Organization     AS Organization,
		|	Table.Ref.Partner         AS Partner,
		|
		|	Table.Ref.ARAPObject  AS ARAPObject,
		|	Table.Ref.Date            AS RecorderDate,
		|	Table.Ref.Number           AS RecorderNumber,
		|	Table.Ref.ARAPObjectSettings AS ARAPObjectSettings,
		|	Table.Ref.Currency          AS ARAPCurrency,
		|	Table.Ref.Currency          AS DocumentCurrency,
		|	VALUE(Enum.BusinessTransactions.SchedulingOfPurchaseOrder) AS BusinessOperation,
		|	Table.Ref.PaymentMethod     AS PaymentMethod,
		|	
		|	Table.PaymentDate            AS PaymentDate,
		|	Table.DateOfShipment           AS DateOfShipment,
		|	Table.PaymentOption          AS PaymentOption,
		|	Table.PaymentAmount           AS AmountDue
		|	
		|FROM
		|	Document.SubcontractOrder2_5.PaymentScheduleSteps AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.Ref.Status IN (
		|		VALUE(Enum.TollingOrderStatuses.ForFulfillment),
		|		VALUE(Enum.TollingOrderStatuses.Closed))
		|";
	
	TextDeliveryPlans = 
		"SELECT
		|	Table.Ref                  AS Ref,
		|	Table.Ref.Organization      AS Organization,
		|	Table.Ref.Partner          AS Partner,
		|	
		|	Table.Ref.ARAPObject   AS ARAPObject,
		|	Table.Ref.Date             AS RecorderDate,
		|	Table.Ref.Number            AS RecorderNumber,
		|	Table.Ref.ARAPObjectSettings  AS ARAPObjectSettings,
		|	Table.Ref.Currency           AS ARAPCurrency,
		|	Table.Ref.Currency           AS DocumentCurrency,
		|	VALUE(Enum.BusinessTransactions.SchedulingOfPurchaseOrder) AS BusinessOperation,
		|	
		|	DatesOfReceipt.DateOfReceipt AS DateOfReceipt,
		|	Table.AmountIncludingVAT               AS IncreaseToAdmission
		|FROM
		|	Document.SubcontractOrder2_5.Services AS Table
		|
		|	LEFT JOIN TTDateOfReceiptOfProducts AS DatesOfReceipt
		|	ON DatesOfReceipt.Ref = Table.Ref
		|	AND DatesOfReceipt.CostGroupNumber = Table.CostGroupNumber
		|
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.Ref.Status IN (
		|		VALUE(Enum.TollingOrderStatuses.ForFulfillment),
		|		VALUE(Enum.TollingOrderStatuses.Closed))
		|	AND NOT Table.Canceled
		|";
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.ExecutionOfOrderToSupplier(Query, QueryTexts, Registers, TextPaymentPlans, TextDeliveryPlans);
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.ConductingSettlementsWithSuppliersPaymentPlan(Query, QueryTexts, Registers, TextPaymentPlans);
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.ConductingSettlementsWithSuppliersDeliveryPlan(Query, QueryTexts, Registers, TextDeliveryPlans);
	
EndProcedure

Procedure ScheduleGoodsReceipt(Query, QueryTexts, Registers)
	
	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref						AS Ref,
	|	UNDEFINED								AS Invoice,
	|	FALSE										AS Patch,
	|	UNDEFINED								AS CorrectedDocument,
	|	CASE
	|		WHEN DataSource.Ref.ProcessingByOrder
	|			THEN DisposalTable.ReferenceOrder
	|		WHEN TRUE
	|			THEN DataSource.Ref
	|	END										AS OrderDocument,
	|	DataSource.Ref.Contract				AS Contract,
	|	UNDEFINED								AS Terms,
	|	DataSource.Ref.GoodsReceiptOption	AS GoodsReceiptOption,
	|	DataSource.DateOfReceipt				AS Date,
	|	DataSource.Products					AS Products,
	|	DataSource.Characteristic				AS Characteristic,
	|	DataSource.Purpose					AS Purpose,
	|	DataSource.ToControlQuality    AS ToControlQuality,
	|	FALSE                                        AS RecordOfAPreviouslyReceivedLot,
	|	UNDEFINED                                AS ControlledLotReference,
	|	0											AS BatchesIndicationStatus,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	FALSE										AS ExceedingOrder,
	|	DataSource.Recipient					AS Warehouse,
	|	DataSource.Ref.Partner				AS Sender,
	|	VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5) AS BusinessOperation,
	|	DataSource.Count					AS Count,
	|	FALSE										AS ThisIsAnInvoice,
	|	FALSE										AS ReceiptUnderOrders
	|FROM
	|	Document.SubcontractOrder2_5.ManufacturedProducts AS DataSource
	|
	|	LEFT JOIN Document.SubcontractOrder2_5.References AS DisposalTable
	|	ON DisposalTable.Ref = DataSource.Ref
	|	AND DisposalTable.CostGroupNumber = DataSource.CostGroupNumber
	|
	|WHERE
	|	DataSource.Ref IN (&Ref)
	|	AND NOT DataSource.Canceled
	|	AND NOT DataSource.ToExpenseAs
	|	AND NOT DataSource.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND DataSource.Ref.Status IN (
	|		VALUE(Enum.TollingOrderStatuses.ForFulfillment),
	|		VALUE(Enum.TollingOrderStatuses.Closed))
	|	AND NOT DataSource.Ref.LeaveProductsAtSubcontractor
	|
	|UNION ALL
	|
	|SELECT
	|	DataSource.Ref						AS Ref,
	|	UNDEFINED								AS Invoice,
	|	FALSE										AS Patch,
	|	UNDEFINED								AS CorrectedDocument,
	|	CASE
	|		WHEN DataSource.Ref.ProcessingByOrder
	|			THEN DisposalTable.ReferenceOrder
	|		WHEN TRUE
	|			THEN DataSource.Ref
	|	END										AS OrderDocument,
	|	DataSource.Ref.Contract				AS Contract,
	|	UNDEFINED								AS Terms,
	|	DataSource.Ref.GoodsReceiptOption	AS GoodsReceiptOption,
	|	DataSource.DateOfReceipt				AS Date,
	|	DataSource.Products					AS Products,
	|	DataSource.Characteristic				AS Characteristic,
	|	DataSource.Purpose					AS Purpose,
	|	DataSource.ToControlQuality    AS ToControlQuality,
	|	FALSE                                        AS RecordOfAPreviouslyReceivedLot,
	|	UNDEFINED                                AS ControlledLotReference,
	|	0											AS BatchesIndicationStatus,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	FALSE										AS ExceedingOrder,
	|	DataSource.Recipient					AS Warehouse,
	|	DataSource.Ref.Partner				AS Sender,
	|	VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5) AS BusinessOperation,
	|	DataSource.Count					AS Count,
	|	FALSE										AS ThisIsAnInvoice,
	|	FALSE										AS ReceiptUnderOrders
	|FROM
	|	Document.SubcontractOrder2_5.SideAndIntermediateRelease AS DataSource
	|
	|	LEFT JOIN Document.SubcontractOrder2_5.References AS DisposalTable
	|	ON DisposalTable.Ref = DataSource.Ref
	|	AND DisposalTable.CostGroupNumber = DataSource.CostGroupNumber
	|
	|WHERE
	|	DataSource.Ref IN (&Ref)
	|	AND NOT DataSource.Canceled
	|	AND NOT DataSource.ToExpenseAs
	|	AND NOT DataSource.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND DataSource.Ref.Status IN (
	|		VALUE(Enum.TollingOrderStatuses.ForFulfillment),
	|		VALUE(Enum.TollingOrderStatuses.Closed))
	|	AND NOT DataSource.Ref.LeaveProductsAtSubcontractor
	|";
	
	WarehousesServer.ScheduleGoodsReceipt(Query, QueryTexts, Registers, QueryTextDocument_);
	
EndProcedure

Procedure ScheduleShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	SourceData.Ref				AS Ref,
	|	SourceData.DateOfShipment		AS Period,
	|	SourceData.Ref				AS OrderDocument,
	|	UNDEFINED						AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
	|	SourceData.Ref.Partner		AS Recipient,
	|	SourceData.Warehouse				AS Warehouse,
	|	SourceData.Products		AS Products,
	|	SourceData.Characteristic		AS Characteristic,
	|	CASE
	|		WHEN SourceData.WithAssignment
	|			THEN SourceData.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END								AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	SourceData.Series				AS Series,
	|	SourceData.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	SourceData.Count			AS Count,
	|	FALSE								AS ExceedingOrder,
	|	SourceData.Canceled			AS Canceled,
	|	FALSE								AS ThisIsAnInvoice,
	|	TRUE								AS ShipmentByOrder
	|FROM
	|	Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks AS SourceData
	|
	|WHERE
	|	SourceData.Ref IN(&Ref)
	|	AND NOT SourceData.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND SourceData.Ref.Status IN (
	|		VALUE(Enum.TollingOrderStatuses.ForFulfillment),
	|		VALUE(Enum.TollingOrderStatuses.Closed))
	|	AND NOT SourceData.Canceled
	|	AND SourceData.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|";
	
	WarehousesServer.ScheduleShipmentOfGoods(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Procedure ReflectReserve(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	SourceData.Ref                       AS Ref,
	|	CASE
	|		WHEN SourceData.DateOfShipment <> DATETIME(1, 1, 1)
	|			THEN SourceData.DateOfShipment
	|		ELSE SourceData.Ref.Date
	|	END                                        AS Period,
	|	SourceData.Ref                       AS OrderDocument,
	|	UNDEFINED                                 AS Invoice,
	|	FALSE                                         AS Patch,
	|	UNDEFINED                                 AS CorrectedDocument,
	|	SourceData.Ref.Partner               AS Recipient,
	|	SourceData.Warehouse                        AS Warehouse,
	|	SourceData.Products                 AS Products,
	|	SourceData.Characteristic               AS Characteristic,
	|	CASE
	|		WHEN SourceData.WithAssignment
	|			THEN SourceData.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                        AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	SourceData.Series                        AS Series,
	|	SourceData.BatchesIndicationStatus          AS BatchesIndicationStatus,
	|	SourceData.Count                   AS Count,
	|	FALSE                                         AS ExceedingOrder,
	|	SourceData.Canceled                     AS Canceled,
	|	FALSE                                         AS ThisIsAnInvoice,
	|	TRUE                                       AS ShipmentByOrder
	|FROM
	|	Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks AS SourceData
	|WHERE
	|	SourceData.Ref IN(&Ref)
	|	AND NOT SourceData.Canceled
	|	AND NOT SourceData.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND (SourceData.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
	|		OR SourceData.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|			AND SourceData.Ref.Status = VALUE(Enum.TollingOrderStatuses.NotApproved))
	|";
	
	WarehousesServer.ReflectReserve(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	#Region SupplyWithMaterialsAndWorks
	
	QueryTextTabPart =
	"SELECT
	|	TabPart.Ref AS Ref,
	|	TabPart.Ref.Date AS Period,
	|	TabPart.Products AS Products,
	|	TabPart.Characteristic AS Characteristic,
	|	CASE
	|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN TabPart.Ref.Department
	|		ELSE TabPart.Warehouse
	|	END AS Warehouse,
	|	CASE
	|		WHEN TabPart.WithAssignment
	|			THEN TabPart.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	TabPart.Count AS Count,
	|	CASE
	|		WHEN DisposalTable.ReferenceOrder IS NOT NULL
	|			THEN DisposalTable.ReferenceOrder
	|		WHEN TRUE
	|			THEN TabPart.Ref
	|	END AS PlannedConsumptionOfDistributedStock,
	|	TRUE AS ControlOfFreeResidue
	|FROM
	|	Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks AS TabPart
	|		LEFT JOIN Document.SubcontractOrder2_5.References AS DisposalTable
	|		ON DisposalTable.CostGroupNumber = TabPart.CostGroupNumber
	|		AND DisposalTable.Ref = TabPart.Ref
	|WHERE
	|	NOT TabPart.Canceled
	|	AND TabPart.Ref.Status IN(
	|		VALUE(Enum.TollingOrderStatuses.ForFulfillment),
	|		VALUE(Enum.TollingOrderStatuses.Closed))
	|	AND TabPart.SupplyOption = VALUE(Enum.SupplyOptions.Ship)";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
	QueryTextTabPart =
	"SELECT
	|	TabPart.Ref             AS Ref,
	|	TabPart.Ref.Date        AS Period,
	|	TabPart.Products       AS Products,
	|	TabPart.Characteristic     AS Characteristic,
	|	CASE
	|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN TabPart.Ref.Department
	|		ELSE TabPart.Warehouse
	|	END                       AS Warehouse,
	|	
	|	CASE
	|		WHEN TabPart.WithAssignment
	|			THEN TabPart.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                       AS Purpose,
	|	
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	TabPart.Count         AS Count,
	|	TabPart.SupplyOption AS SupplyOption,
	|	
	|	CASE
	|		WHEN DisposalTable.ReferenceOrder IS NOT NULL
	|			THEN DisposalTable.ReferenceOrder
	|		WHEN TRUE
	|			THEN TabPart.Ref
	|	END                       AS OrderDocument,
	|	
	|	CASE
	|		WHEN TabPart.Ref.NotShipInInstallments
	|			THEN TabPart.Ref.DateOfShipment
	|		ELSE TabPart.DateOfShipment
	|	END                       AS RequestShipmentOn,
	|	FALSE                        AS OnSchedule,
	|	UNDEFINED                AS OrderInSchedule,
	|	0                           AS QuantityInGraph
	|FROM
	|	Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks AS TabPart
	|	
	|	LEFT JOIN Document.SubcontractOrder2_5.References AS DisposalTable
	|	ON DisposalTable.CostGroupNumber = TabPart.CostGroupNumber
	|	AND DisposalTable.Ref = TabPart.Ref
	|WHERE
	|	NOT TabPart.Canceled
	|	AND NOT TabPart.Ref.Status = VALUE(Enum.TollingOrderStatuses.NotApproved)
	|	AND NOT TabPart.SupplyOption IN
	|			(VALUE(Enum.SupplyOptions.Ship),
	|			VALUE(Enum.SupplyOptions.TransferedEarlier))
	|";
		
	StockAllocationRecords.PlanStockConsumption(
		Query,
		QueryTexts,
		Registers,
		QueryTextTabPart,
		False);
	
	// Shipment is not available.
	QueryTextTabPart =
	"SELECT
	|	TabPart.Ref AS Ref,
	|	TabPart.Ref.Date AS Period,
	|	TabPart.Products AS Products,
	|	TabPart.Characteristic AS Characteristic,
	|	CASE
	|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN TabPart.Ref.Department
	|		ELSE TabPart.Warehouse
	|	END AS Warehouse,
	|	CASE
	|		WHEN TabPart.WithAssignment
	|			THEN TabPart.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	TabPart.Count AS Count,
	|	CASE
	|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND TabPart.WithAssignment
	|			THEN VALUE(Enum.SupplyOptions.ToSupply)
	|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND NOT TabPart.WithAssignment
	|			THEN VALUE(Enum.SupplyOptions.NotRequired)
	|		ELSE VALUE(Enum.SupplyOptions.FromWarehouse)
	|	END AS SupplyOption,
	|	CASE
	|		WHEN DisposalTable.ReferenceOrder IS NOT NULL
	|			THEN DisposalTable.ReferenceOrder
	|		WHEN TRUE
	|			THEN TabPart.Ref
	|	END AS OrderDocument,
	|	CASE
	|		WHEN TabPart.Ref.NotShipInInstallments
	|			THEN TabPart.Ref.DateOfShipment
	|		ELSE TabPart.DateOfShipment
	|	END AS RequestShipmentOn,
	|	FALSE AS OnSchedule,
	|	UNDEFINED AS OrderInSchedule,
	|	0 AS QuantityInGraph
	|FROM
	|	Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks AS TabPart
	|		LEFT JOIN Document.SubcontractOrder2_5.References AS DisposalTable
	|		ON DisposalTable.CostGroupNumber = TabPart.CostGroupNumber
	|		AND DisposalTable.Ref = TabPart.Ref
	|WHERE
	|	NOT TabPart.Canceled
	|	AND TabPart.Ref.Status = VALUE(Enum.TollingOrderStatuses.NotApproved)
	|	AND TabPart.SupplyOption = VALUE(Enum.SupplyOptions.Ship)";
		
	StockAllocationRecords.PlanStockConsumption(
		Query,
		QueryTexts,
		Registers,
		QueryTextTabPart,
		False);
	
	#EndRegion
	
	#Region ManufacturedProducts
	
	QueryTextTabPart =
	"SELECT
	|	TabPart.Ref AS Ref,
	|	TabPart.Ref.Date AS Period,
	|	TabPart.Products AS Products,
	|	TabPart.Characteristic AS Characteristic,
	|	TabPart.Recipient AS Warehouse,
	|	TabPart.Purpose AS Purpose,
	|	TabPart.ToControlQuality AS ToControlQuality,
	|	TabPart.ToControlQuality AS SubjectToUnlocking,
	|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
	|	TabPart.Count AS Count,
	|	CASE
	|		WHEN DisposalTable.ReferenceOrder IS NOT NULL
	|			THEN DisposalTable.ReferenceOrder
	|		WHEN TRUE
	|			THEN TabPart.Ref
	|	END AS OrderDocument,
	|	TabPart.DateOfReceipt AS DateOfReceipt,
	|	TabPart.Ref.Status IN(
	|		VALUE(Enum.TollingOrderStatuses.ForFulfillment),
	|		VALUE(Enum.TollingOrderStatuses.Closed)) AS AvailableForConsumption,
	|	FALSE AS OnSchedule,
	|	UNDEFINED AS OrderInSchedule,
	|	0 AS QuantityInGraph
	|FROM
	|	Document.SubcontractOrder2_5.ManufacturedProducts AS TabPart
	|		LEFT JOIN Document.SubcontractOrder2_5.References AS DisposalTable
	|		ON DisposalTable.CostGroupNumber = TabPart.CostGroupNumber
	|		AND DisposalTable.Ref = TabPart.Ref
	|WHERE
	|	NOT TabPart.ToExpenseAs
	|	AND NOT TabPart.Canceled
	|	AND (NOT TabPart.Ref.LeaveProductsAtSubcontractor
	|		OR TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5))";
	
	StockAllocationRecords.ScheduleStockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
	#EndRegion
	
	#Region SideAndIntermediateRelease
	
	QueryTextTabPart =
	"SELECT
	|	TabPart.Ref AS Ref,
	|	TabPart.Ref.Date AS Period,
	|	TabPart.Products AS Products,
	|	TabPart.Characteristic AS Characteristic,
	|	TabPart.Recipient AS Warehouse,
	|	TabPart.Purpose AS Purpose,
	|	TabPart.ToControlQuality AS ToControlQuality,
	|	TabPart.ToControlQuality AS SubjectToUnlocking,
	|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
	|	TabPart.Count AS Count,
	|	CASE
	|		WHEN DisposalTable.ReferenceOrder IS NOT NULL
	|			THEN DisposalTable.ReferenceOrder
	|		WHEN TRUE
	|			THEN TabPart.Ref
	|	END AS OrderDocument,
	|	TabPart.DateOfReceipt AS DateOfReceipt,
	|	TabPart.Ref.Status IN(
	|		VALUE(Enum.TollingOrderStatuses.ForFulfillment),
	|		VALUE(Enum.TollingOrderStatuses.Closed)) AS AvailableForConsumption,
	|	FALSE AS OnSchedule,
	|	UNDEFINED AS OrderInSchedule,
	|	0 AS QuantityInGraph
	|FROM
	|	Document.SubcontractOrder2_5.SideAndIntermediateRelease AS TabPart
	|		LEFT JOIN Document.SubcontractOrder2_5.References AS DisposalTable
	|		ON DisposalTable.CostGroupNumber = TabPart.CostGroupNumber
	|		AND DisposalTable.Ref = TabPart.Ref
	|WHERE
	|	NOT TabPart.ToExpenseAs
	|	AND NOT TabPart.Canceled
	|	AND (NOT TabPart.Ref.LeaveProductsAtSubcontractor
	|		OR TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5))";
	
	StockAllocationRecords.ScheduleStockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
	#EndRegion
	
EndProcedure

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	 
	QueryTextdata_ = 
	"SELECT
	|	""Services"" AS DataSource,
	|	FALSE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	UNDEFINED AS ARAPCurrency,
	|	DATETIME(1,1,1) AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	0 AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|	
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.Ref.ARAPObject AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.SubcontractOrder2_5.Services AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.Ref.ProcessingServices =
	|		VALUE(Enum.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder)
	|"; 	
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(Query, QueryTexts, Registers, QueryTextdata_);
	
EndProcedure

#EndRegion

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	If AccessRight("Update", Metadata.Documents.SubcontractOrder2_5) Then
		
		// Order to the processor for products
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintOrderForGoodsServices";
		PrintCommand.Id = "SubcontractServicesOrder2_5";
		PrintCommand.Presentation = NStr("vi = 'Đơn hàng gia công dịch vụ xuất xưởng thành phẩm';
										|ru = 'Заказ переработчику на услуги по выпуску продукции';
										|en = 'Subcontracting purchase order for product release services'; fa = 'Subcontracting purchase order for product release services';
										|it = 'Ordine al subfornitore per i servizi di emissione prodotti';
										|pl = 'Zamów procesor dla usług produkcyjnych';
										|tr = 'İmal edilen ürünün üretim hizmetlerine ilişkin verilen fason satın alma siparişi'");
		PrintCommand.CheckPostingBeforePrint = True;
		
		// Processor's order for raw materials
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintOrderForGoodsServices";
		PrintCommand.Id = "ProcessorSOrderForRawMaterials2_5";
		PrintCommand.Presentation = NStr("vi = 'Đơn hàng gia công nguyên vật liệu và công việc';
										|ru = 'Заказ переработчика на материалы и работы';
										|en = 'Subcontractor order for materials and works'; fa = 'Subcontractor order for materials and works';
										|it = 'Ordine elaboratore per materiali e lavori';
										|pl = 'Zamówienie przetwórcy na materiały i prace';
										|tr = 'Fason üretici malzeme ve iş satın alma siparişi'");
		PrintCommand.CheckPostingBeforePrint = True;
		
	EndIf;

EndProcedure

Function GetDataForPrintedOrderFormForRawMaterials(ObjectsArray, PrintParameters, LanguageCode = Undefined) Export
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	Documents.Ref										AS Ref,
	|	Documents.Number											AS Number,
	|	Documents.Date											AS Date,
	|	Documents.Organization									AS Organization,
	|	Documents.Organization									AS Performer,
	|
	|	FALSE													AS ConsiderVAT,
	|	Documents.PriceIncludesVAT								AS PriceIncludesVAT,
	|	FALSE													AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|
	|	Documents.Organization.Prefix							AS Prefix,
	|	Documents.Counterparty									AS Counterparty,
	|	Documents.Counterparty									AS Customer_,
	|	Documents.BankAccount								AS BankAccount,
	|	Documents.BankAccount.CorrespondentText			AS CorrespondentTextBankAccount,
	|	Documents.Currency										AS Currency,
	|	Documents.Manager.Individual.Description			AS Manager,
	|	Documents.AdditionalInformation						AS AdditionalInformation,
	|
	|	Documents.DeliveryAddress									AS DeliveryAddress,
	|	UNDEFINED											AS Shipper,
	|	UNDEFINED											AS GoodsRecipient,
	// Parameters for selecting report layout areas
	|	FALSE													AS ShowNDSInRows,
	|	FALSE													AS UseAutoDiscounts,
	|	""""													AS Type,
	|	&PresentationOfDocument									AS PresentationOfDocument,
	|	&PresentationInError									AS PresentationInError
	|
	|FROM
	|	Document.SubcontractOrder2_5 AS Documents
	|
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Documents.PointInTime
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UNDEFINED AS Ref,
	|	UNDEFINED AS LineNumber,
	|	UNDEFINED AS PaymentDate,
	|	UNDEFINED AS PaymentOption,
	|	UNDEFINED AS PaymentPercentage,
	|	UNDEFINED AS PaymentAmount
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentOrderDocument.Ref									AS Ref,
	|	DocumentOrderDocument.Date                                      AS Date,
	|	DocumentOrderDocument.Currency                                    AS Currency,
	|	DocumentOrderDocument.PriceKind                                   AS PriceKind,
	|	Goods.LineNumber										AS LineNumber,
	|	Goods.Products										AS Products,
	|	Goods.DateOfShipment										AS DateOfShipment,
	|	Goods.Characteristic				                    AS Characteristic,
	|	""""													AS Content,
	|
	|	Goods.Count								        AS Count,
	|	Goods.NumberOfPackages								AS NumberOfPackages,
	|	Goods.Package								            AS Package,
	|
	|	UNDEFINED											AS VATRate,
	|	0														AS VATAmount,
	|
	|	FALSE													AS ThisIsReusablePackage
	|
	|INTO StageMaterials_
	|FROM
	|	Document.SubcontractOrder2_5 AS DocumentOrderDocument
	|		INNER JOIN Document.ProductionStage2_2 OneStageTable
	|		ON OneStageTable.SubcontractOrder = DocumentOrderDocument.Ref
	|		INNER JOIN Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS Goods
	|		ON Goods.Ref = OneStageTable.Ref
	|
	|WHERE
	|	DocumentOrderDocument.Ref IN(&ObjectsArray)
	|	AND NOT Goods.Canceled
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductPricePeriods.Ref,
	|	ProductPricePeriods.LineNumber,
	|	ProductPricePeriods.Date,
	|	ItemsPrices.Currency,
	|	ItemsPrices.Price,
	|	ItemsPrices.Package
	|INTO Prices
	|FROM
	|	(SELECT
	|		Goods.Ref AS Ref,
	|		Goods.LineNumber AS LineNumber,
	|		Goods.Date AS Date,
	|		ItemsPrices.PriceKind AS PriceKind,
	|		ItemsPrices.Currency AS Currency,
	|		ItemsPrices.Products AS Products,
	|		ItemsPrices.Characteristic AS Characteristic,
	|		MAX(ItemsPrices.Period) AS Period
	|	FROM
	|		StageMaterials_ AS Goods
	|			INNER JOIN InformationRegister.ItemsPrices AS ItemsPrices
	|			ON Goods.PriceKind = ItemsPrices.PriceKind
	|				AND Goods.Products = ItemsPrices.Products
	|				AND Goods.Characteristic = ItemsPrices.Characteristic
	|				AND Goods.Date >= ItemsPrices.Period
	|	
	|	GROUP BY
	|		Goods.Ref,
	|		Goods.LineNumber,
	|		Goods.Date,
	|		ItemsPrices.PriceKind,
	|		ItemsPrices.Currency,
	|		ItemsPrices.Products,
	|		ItemsPrices.Characteristic
	|	) AS ProductPricePeriods
	|
	|		INNER JOIN InformationRegister.ItemsPrices AS ItemsPrices
	|		ON ProductPricePeriods.Period = ItemsPrices.Period
	|			AND ProductPricePeriods.PriceKind = ItemsPrices.PriceKind
	|			AND ProductPricePeriods.Products = ItemsPrices.Products
	|			AND ProductPricePeriods.Characteristic = ItemsPrices.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PeriodsExchangeRates.Ref,
	|	ExchangeRates.Currency,
	|	ExchangeRates.CourseDenominator,
	|	ExchangeRates.CourseNumerator
	|INTO CurrencyRatesPrices
	|FROM
	|	(SELECT
	|		Prices.Ref AS Ref,
	|		Prices.Currency AS Currency,
	|		Prices.Ref.Organization.LocalAccountingCurrency AS BaseCurrency,
	|		MAX(ExchangeRates.Period) AS Period
	|	FROM
	|		Prices AS Prices
	|			INNER JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|			ON Prices.Currency = ExchangeRates.Currency
	|				AND Prices.Ref.Organization.LocalAccountingCurrency = ExchangeRates.BaseCurrency
	|				AND Prices.Date >= ExchangeRates.Period
	|	
	|	GROUP BY
	|		Prices.Ref,
	|		Prices.Currency,
	|		Prices.Ref.Organization.LocalAccountingCurrency
	|	) AS PeriodsExchangeRates
	|
	|		INNER JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|		ON PeriodsExchangeRates.Period = ExchangeRates.Period
	|			AND PeriodsExchangeRates.Currency = ExchangeRates.Currency
	|			AND PeriodsExchangeRates.BaseCurrency = ExchangeRates.BaseCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PeriodsExchangeRates.Ref,
	|	ExchangeRates.CourseDenominator,
	|	ExchangeRates.CourseNumerator
	|INTO Currency_Rates
	|FROM
	|	(SELECT
	|		StageMaterials_.Ref AS Ref,
	|		StageMaterials_.Currency AS Currency,
	|		StageMaterials_.Ref.Organization.LocalAccountingCurrency AS BaseCurrency,
	|		MAX(ExchangeRates.Period) AS Period
	|	FROM
	|		StageMaterials_ AS StageMaterials_
	|			INNER JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|			ON StageMaterials_.Currency = ExchangeRates.Currency
	|				AND StageMaterials_.Ref.Organization.LocalAccountingCurrency = ExchangeRates.BaseCurrency
	|				AND StageMaterials_.Date >= ExchangeRates.Period
	|	
	|	GROUP BY
	|		StageMaterials_.Ref,
	|		StageMaterials_.Currency,
	|		StageMaterials_.Ref.Organization.LocalAccountingCurrency
	|	) AS PeriodsExchangeRates
	|
	|		INNER JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|		ON PeriodsExchangeRates.Period = ExchangeRates.Period
	|			AND PeriodsExchangeRates.Currency = ExchangeRates.Currency
	|			AND PeriodsExchangeRates.BaseCurrency = ExchangeRates.BaseCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref											AS Ref,
	|	Goods.LineNumber										AS LineNumber,
	|	UNDEFINED											AS TypeOfContractorSPrice,
	|	Goods.Products										AS Products,
	|	Goods.Products.Code									AS Code,
	|	Goods.Products.SKU								AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, Goods.Products.DescriptionFull) AS DescriptionFull,
	|	Goods.DateOfShipment										AS DateOfShipment,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Goods.Characteristic.DescriptionFull, """")) AS Characteristic,
	|	""""													AS Content,
	|
	|	Goods.NumberOfPackages								AS Count,
	|
	|	Goods.Price												AS Price,
	|	0														AS DiscountAmount,
	|	Goods.Sum											AS AmountWithoutADiscount,
	|	Goods.Sum											AS Sum,
	|	UNDEFINED											AS VATRate,
	|	0														AS VATAmount,
	|
	|	CASE
	|		WHEN Goods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 
	|				CASE 
	|					WHEN &ThisIsMainLanguageOfSystem THEN
	|						PRESENTATION(Goods.Products.UnitOfMeasure)
	|					ELSE Goods.Products.UnitOfMeasure.InternationalAbbreviation
	|				END
	|		ELSE 
	|				CASE 
	|					WHEN &ThisIsMainLanguageOfSystem THEN
	|						PRESENTATION(Goods.Package)
	|					ELSE Goods.Package.InternationalAbbreviation
	|				END
	|	END AS UnitOfMeasure,
	|
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1 THEN
	|		UNDEFINED
	|	ELSE
	|		Goods.Package.Description
	|	END													AS Package,
	|	FALSE													AS ThisIsReusablePackage
	|
	|FROM
	|	Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks AS Goods
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON (Goods.Products = ProductsPresentations.Ref
	|			AND ProductsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON (Goods.Characteristic = ItemsCharacteristicsPresentations.Ref
	|			AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode)
	|
	|WHERE
	|	Goods.Ref IN(&ObjectsArray)
	|	AND Goods.Canceled = FALSE
	|
	|UNION ALL
	|
	|SELECT
	|	Goods.Ref									        AS Ref,
	|	Goods.LineNumber										AS LineNumber,
	|	UNDEFINED											AS TypeOfContractorSPrice,
	|	Goods.Products										AS Products,
	|	Goods.Products.Code									AS Code,
	|	Goods.Products.SKU								AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, Goods.Products.DescriptionFull) AS DescriptionFull,
	|	Goods.DateOfShipment										AS DateOfShipment,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Goods.Characteristic.DescriptionFull, """")) AS Characteristic,
	|	""""													AS Content,
	|
	|	Goods.NumberOfPackages                               AS Count,
	|
	|	CASE
	|		WHEN Goods.Currency <> Prices.Currency
	|			THEN CASE
	|					WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|						AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|						AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|						AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|					THEN 
	|						(CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator)
	|						/ (Currency_Rates.CourseNumerator * CurrencyRatesPrices.CourseDenominator)
	|					ELSE 0
	|				END
	|		ELSE 1
	|	END * ISNULL(Prices.Price,0)                           AS Price,
	|	0														AS DiscountAmount,
	|	0														AS AmountWithoutADiscount,
	|	CASE
	|		WHEN Goods.Currency <> Prices.Currency
	|			THEN CASE
	|					WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|						AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|						AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|						AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|					THEN 
	|						(CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator)
	|						/ (Currency_Rates.CourseNumerator * CurrencyRatesPrices.CourseDenominator)
	|					ELSE 0
	|				END
	|		ELSE 1
	|	END * Goods.Count * ISNULL(Prices.Price,0)       AS Sum,
	|	UNDEFINED											AS VATRate,
	|	0														AS VATAmount,
	|
	|	CASE
	|		WHEN Goods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 
	|				CASE 
	|					WHEN &ThisIsMainLanguageOfSystem THEN
	|						PRESENTATION(Goods.Products.UnitOfMeasure)
	|					ELSE Goods.Products.UnitOfMeasure.InternationalAbbreviation
	|				END
	|		ELSE 
	|				CASE 
	|					WHEN &ThisIsMainLanguageOfSystem THEN
	|						PRESENTATION(Goods.Package)
	|					ELSE Goods.Package.InternationalAbbreviation
	|				END
	|	END AS UnitOfMeasure,
	|
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1 THEN
	|		UNDEFINED
	|	ELSE
	|		Goods.Package.Description
	|	END													AS Package,
	|
	|	Goods.ThisIsReusablePackage								AS ThisIsReusablePackage
	|
	|FROM
	|	StageMaterials_ AS Goods
	|		LEFT JOIN Prices AS Prices
	|		ON Goods.Ref = Prices.Ref
	|			AND Goods.LineNumber = Prices.LineNumber
	|		LEFT JOIN CurrencyRatesPrices AS CurrencyRatesPrices
	|		ON CurrencyRatesPrices.Ref = Prices.Ref
	|		LEFT JOIN Currency_Rates AS Currency_Rates
	|		ON Goods.Ref = Currency_Rates.Ref
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON (Goods.Products = ProductsPresentations.Ref
	|			AND ProductsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON (Goods.Characteristic = ItemsCharacteristicsPresentations.Ref
	|			AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode)
	|
	|
	|ORDER BY
	|	LineNumber";
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"Goods.Package",
		"Goods.Products"));
		
	Query.SetParameter("ObjectsArray",			ObjectsArray);
	Query.SetParameter("PresentationOfDocument",	NStr("vi = 'Đơn đặt hàng gia công nguyên vật liệu';
														|ru = 'Заказ переработчика на сырье и материалы';
														|en = 'Subcontract order for raw and consumable materials'; fa = 'Subcontract order for raw and consumable materials';
														|it = 'Ordine del subfornitore per le materie prime e i materiali';
														|pl = 'Zamówienie od przetwórcy na materiały';
														|tr = 'Fason üretici hammadde ve malzeme satın alma siparişi'", Common.DefaultLanguageCode()));
	Query.SetParameter("PresentationInError",	NStr("vi = 'đơn hàng của người nhận gia công';
														|ru = 'заказа переработчика';
														|en = 'subcontract order'; fa = 'subcontract order';
														|it = 'dell''ordine di subfornitore';
														|pl = 'zamówienie od przetwórcy';
														|tr = 'fason üretici satın alma siparişi'", Common.DefaultLanguageCode()));
	Query.SetParameter("LanguageCode", LanguageCode);
	Query.SetParameter("ThisIsMainLanguageOfSystem", LanguageCode = Common.DefaultLanguageCode() Or LanguageCode = Undefined);
	
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults",			RequestResultsPackage[0]);
	DataStructureForPrinting.Insert("ResultsByPaymentStages",	RequestResultsPackage[1]);
	DataStructureForPrinting.Insert("ResultForTabularPart",	RequestResultsPackage[RequestResultsPackage.UBound()]);
	
	Return DataStructureForPrinting;
	
EndFunction

Function GetDataForPrintedServiceOrderForm(ObjectsArray, PrintParameters, LanguageCode = Undefined) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Documents.Ref										AS Ref,
	|	Documents.Number											AS Number,
	|	Documents.Date											AS Date,
	|	Documents.Organization									AS Organization,
	|	Documents.Organization									AS Customer_,
	|
	|	FALSE													AS ConsiderVAT,
	|	Documents.PriceIncludesVAT								AS PriceIncludesVAT,
	|	FALSE													AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|
	|	Documents.Organization.Prefix							AS Prefix,
	|	Documents.Counterparty									AS Counterparty,
	|	Documents.Counterparty									AS Performer,
	|	Documents.BankAccount								AS BankAccount,
	|	Documents.BankAccount.CorrespondentText			AS CorrespondentTextBankAccount,
	|	Documents.Currency										AS Currency,
	|	Documents.Manager.Individual.Description			AS Manager,
	|	Documents.AdditionalInformation						AS AdditionalInformation,
	|
	|	""""													AS DeliveryAddress,
	|	UNDEFINED											AS Shipper,
	|	UNDEFINED											AS GoodsRecipient,
	// Parameters for selecting report layout areas
	|	FALSE													AS ShowNDSInRows,
	|	FALSE													AS UseAutoDiscounts,
	|	""SubcontractServicesOrder""							AS Type,
	|	&PresentationOfDocument									AS PresentationOfDocument,
	|	&PresentationInError									AS PresentationInError
	|
	|FROM
	|	Document.SubcontractOrder2_5 AS Documents
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Documents.PointInTime
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UNDEFINED AS Ref,
	|	UNDEFINED AS LineNumber,
	|	UNDEFINED AS PaymentDate,
	|	UNDEFINED AS PaymentOption,
	|	UNDEFINED AS PaymentPercentage,
	|	UNDEFINED AS PaymentAmount
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref											AS Ref,
	|	Goods.LineNumber										AS LineNumber,
	|	Goods.Products										AS Products,
	|	Goods.Products.Code									AS Code,
	|	Goods.Products.SKU								AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, Goods.Products.DescriptionFull) AS DescriptionFull,
	|	Goods.DateOfReceipt									AS DateOfReceipt,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Goods.Characteristic.DescriptionFull, """")) AS Characteristic,
	|	""""													AS Content,
	|
	|	UNDEFINED											AS TypeOfContractorSPrice,
	|
	|	CASE
	|		WHEN Goods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 
	|				CASE 
	|					WHEN &ThisIsMainLanguageOfSystem THEN
	|						PRESENTATION(Goods.Products.UnitOfMeasure)
	|					ELSE Goods.Products.UnitOfMeasure.InternationalAbbreviation
	|				END
	|		ELSE 
	|				CASE 
	|					WHEN &ThisIsMainLanguageOfSystem THEN
	|						PRESENTATION(Goods.Package)
	|					ELSE Goods.Package.InternationalAbbreviation
	|				END
	|	END AS UnitOfMeasure,
	|
	|	Goods.NumberOfPackages								AS Count,
	|
	|	0														AS Price,
	|	0														AS Sum,
	|	0														AS VATAmount,
	|	0														AS DiscountAmount,
	|	0														AS AmountWithoutADiscount,
	|
	|	UNDEFINED											AS VATRate,
	|
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1 THEN
	|		UNDEFINED
	|	ELSE
	|		Goods.Package.Description
	|	END													AS Package,
	|
	|	FALSE													AS ThisIsReusablePackage
	|
	|FROM
	|	Document.SubcontractOrder2_5 AS OrderDocument
	|
	|	INNER JOIN
	|		Document.SubcontractOrder2_5.ManufacturedProducts AS Goods
	|	ON
	|		OrderDocument.Ref IN(&ObjectsArray)
	|		AND OrderDocument.Ref = Goods.Ref
	|		AND Goods.Canceled = FALSE
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON (Goods.Products = ProductsPresentations.Ref
	|			AND ProductsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON (Goods.Characteristic = ItemsCharacteristicsPresentations.Ref
	|			AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode)
	|
	|UNION ALL
	|
	|	SELECT
	|	Goods.Ref											AS Ref,
	|	Goods.LineNumber										AS LineNumber,
	|	Goods.Products										AS Products,
	|	Goods.Products.Code									AS Code,
	|	Goods.Products.SKU								AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, Goods.Products.DescriptionFull) AS DescriptionFull,
	|	Goods.DateOfReceipt									AS DateOfReceipt,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Goods.Characteristic.DescriptionFull, """")) AS Characteristic,
	|	""""													AS Content,
	|
	|	UNDEFINED											AS TypeOfContractorSPrice,
	|
	|	CASE
	|		WHEN Goods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 
	|				CASE 
	|					WHEN &ThisIsMainLanguageOfSystem THEN
	|						PRESENTATION(Goods.Products.UnitOfMeasure)
	|					ELSE Goods.Products.UnitOfMeasure.InternationalAbbreviation
	|				END
	|		ELSE 
	|				CASE 
	|					WHEN &ThisIsMainLanguageOfSystem THEN
	|						PRESENTATION(Goods.Package)
	|					ELSE Goods.Package.InternationalAbbreviation
	|				END
	|	END AS UnitOfMeasure,
	|
	|	Goods.NumberOfPackages								AS Count,
	|
	|	Goods.Price												AS Price,
	|	Goods.Sum											AS Sum,
	|	0														AS VATAmount,
	|	0														AS DiscountAmount,
	|	Goods.Sum											AS AmountWithoutADiscount,
	|
	|	UNDEFINED											AS VATRate,
	|
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1 THEN
	|		UNDEFINED
	|	ELSE
	|		Goods.Package.Description
	|	END													AS Package,
	|
	|	FALSE													AS ThisIsReusablePackage
	|
	|FROM
	|	Document.SubcontractOrder2_5 AS OrderDocument
	|
	|	INNER JOIN
	|		Document.SubcontractOrder2_5.SideAndIntermediateRelease AS Goods
	|	ON
	|		OrderDocument.Ref IN(&ObjectsArray)
	|		AND OrderDocument.Ref = Goods.Ref
	|		AND Goods.Canceled = FALSE
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON (Goods.Products = ProductsPresentations.Ref
	|			AND ProductsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON (Goods.Characteristic = ItemsCharacteristicsPresentations.Ref
	|			AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode)
	|
	|UNION ALL
	|
	|SELECT
	|	StageDetails.SubcontractOrder						AS Ref,
	|	Goods.LineNumber										AS LineNumber,
	|	Goods.Products										AS Products,
	|	Goods.Products.Code									AS Code,
	|	Goods.Products.SKU								AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, Goods.Products.DescriptionFull) AS DescriptionFull,
	|	Goods.ProductionDate									AS DateOfReceipt,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Goods.Characteristic.DescriptionFull, """")) AS Characteristic,
	|	""""													AS Content,
	|
	|	UNDEFINED											AS TypeOfContractorSPrice,
	|
	|	CASE
	|		WHEN Goods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 
	|				CASE 
	|					WHEN &ThisIsMainLanguageOfSystem THEN
	|						PRESENTATION(Goods.Products.UnitOfMeasure)
	|					ELSE Goods.Products.UnitOfMeasure.InternationalAbbreviation
	|				END
	|		ELSE 
	|				CASE 
	|					WHEN &ThisIsMainLanguageOfSystem THEN
	|						PRESENTATION(Goods.Package)
	|					ELSE Goods.Package.InternationalAbbreviation
	|				END
	|	END AS UnitOfMeasure,
	|
	|	Goods.NumberOfPackages								AS Count,
	|
	|	0														AS Price,
	|	0														AS Sum,
	|	0														AS VATAmount,
	|	0														AS DiscountAmount,
	|	0														AS AmountWithoutADiscount,
	|
	|	UNDEFINED											AS VATRate,
	|
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1 THEN
	|		UNDEFINED
	|	ELSE
	|		Goods.Package.Description
	|	END													AS Package,
	|
	|	FALSE													AS ThisIsReusablePackage
	|
	|FROM
	|	Document.ProductionStage2_2 AS StageDetails
	|
	|	INNER JOIN
	|		Document.ProductionStage2_2.ManufacturedProducts AS Goods
	|	ON
	|		StageDetails.Ref = Goods.Ref
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON (Goods.Products = ProductsPresentations.Ref
	|			AND ProductsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON (Goods.Characteristic = ItemsCharacteristicsPresentations.Ref
	|			AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode)
	|WHERE
	|	StageDetails.SubcontractOrder IN(&ObjectsArray)
	|	AND NOT Goods.Canceled
	|
	|UNION ALL
	|
	|	SELECT
	|	StageDetails.SubcontractOrder						AS Ref,
	|	Goods.LineNumber										AS LineNumber,
	|	Goods.Products										AS Products,
	|	Goods.Products.Code									AS Code,
	|	Goods.Products.SKU								AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, Goods.Products.DescriptionFull) AS DescriptionFull,
	|	Goods.ProductionDate									AS DateOfReceipt,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Goods.Characteristic.DescriptionFull, """")) AS Characteristic,
	|	""""													AS Content,
	|
	|	UNDEFINED											AS TypeOfContractorSPrice,
	|
	|	CASE
	|		WHEN Goods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 
	|				CASE 
	|					WHEN &ThisIsMainLanguageOfSystem THEN
	|						PRESENTATION(Goods.Products.UnitOfMeasure)
	|					ELSE Goods.Products.UnitOfMeasure.InternationalAbbreviation
	|				END
	|		ELSE 
	|				CASE 
	|					WHEN &ThisIsMainLanguageOfSystem THEN
	|						PRESENTATION(Goods.Package)
	|					ELSE Goods.Package.InternationalAbbreviation
	|				END
	|	END AS UnitOfMeasure,
	|
	|	Goods.NumberOfPackages								AS Count,
	|
	|	0												        AS Price,
	|	0											            AS Sum,
	|	0														AS VATAmount,
	|	0														AS DiscountAmount,
	|	0											            AS AmountWithoutADiscount,
	|
	|	UNDEFINED											AS VATRate,
	|
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1 THEN
	|		UNDEFINED
	|	ELSE
	|		Goods.Package.Description
	|	END													AS Package,
	|
	|	FALSE													AS ThisIsReusablePackage
	|
	|FROM
	|	Document.ProductionStage2_2 AS StageDetails
	|	INNER JOIN
	|		Document.ProductionStage2_2.SideAndIntermediateRelease AS Goods
	|	ON
	|		StageDetails.Ref = Goods.Ref
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON (Goods.Products = ProductsPresentations.Ref
	|			AND ProductsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON (Goods.Characteristic = ItemsCharacteristicsPresentations.Ref
	|			AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode)
	|WHERE
	|	StageDetails.SubcontractOrder IN(&ObjectsArray)
	|	AND NOT Goods.Canceled
	|
	|ORDER BY
	|	LineNumber";
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"Goods.Package",
		"Goods.Products"));
		
	Query.SetParameter("ObjectsArray",			ObjectsArray);
	Query.SetParameter("PresentationOfDocument",	NStr("vi = 'Đơn hàng gia công dịch vụ xuất xưởng thành phẩm';
														|ru = 'Заказ переработчику на услуги по выпуску продукции';
														|en = 'Subcontracting purchase order for product release services'; fa = 'Subcontracting purchase order for product release services';
														|it = 'Ordine al subfornitore per i servizi di emissione prodotti';
														|pl = 'Zamów procesor dla usług produkcyjnych';
														|tr = 'İmal edilen ürünün üretim hizmetlerine ilişkin verilen fason satın alma siparişi'"));
	Query.SetParameter("PresentationInError",	NStr("vi = 'đơn hàng đặt gia công';
														|ru = 'заказа переработчику';
														|en = 'Subcontracting purchase order'; fa = 'سفارش خرید پیمانکاری فرعی';
														|it = 'dell''ordine al subfornitore';
														|pl = 'zamówienie do przetwórcy';
														|tr = 'verilen fason üretici siparişi'"));
	Query.SetParameter("LanguageCode", LanguageCode);
	Query.SetParameter("ThisIsMainLanguageOfSystem", LanguageCode = Common.DefaultLanguageCode() Or LanguageCode = Undefined);
	
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults", RequestResultsPackage[0]);
	DataStructureForPrinting.Insert("ResultsByPaymentStages", RequestResultsPackage[1]);
	DataStructureForPrinting.Insert("ResultForTabularPart", RequestResultsPackage[2]);
	
	Return DataStructureForPrinting;
	
EndFunction

// Fills in the structure with data about recipients of printed forms.
// Parameters:
// 	PrintObjectDataStructure - See PrintFormGeneration.FillInRecipientStructureDataByObjectType.PrintObjectDataStructure
// 
Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	PrintObjectDataStructure.PrimaryRecipient = "Partner";
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Partner");
	If GetFunctionalOption("UsePartnersAndCounterparties") Then 
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Counterparty");
	EndIf;
	
EndProcedure

#EndRegion

#Region CostGroups

Procedure UpdateCostGroup(CostGroups, CostGroupDescription)
	
	FilterStructure1 = New Structure("CostGroupNumber", CostGroupDescription.CostGroupNumber);
	FoundRows = CostGroups.FindRows(FilterStructure1);
	If Not FoundRows.Count() = 0 Then
		FillPropertyValues(FoundRows[0], CostGroupDescription);
	EndIf;
	
EndProcedure

Function AllCostGroupProductLinesAreCanceled(Object, CostGroupDescription)
	
	FilterStructure1 = New Structure("CostGroupNumber, Canceled", CostGroupDescription.CostGroupNumber, False);
	
	If TypeOf(Object) = Type("Structure") Then
		Return Object[CostGroupDescription.ProductTableName].Unload().FindRows(FilterStructure1).Count() = 0;
	Else
		Return Object[CostGroupDescription.ProductTableName].FindRows(FilterStructure1).Count() = 0;
	EndIf;
	
EndFunction

Function OrderDataByCostGroupNumber(Object, CurrentGroupNumber)
	
	DescriptionOfOrder = DescriptionOfOrder(Object);
	
	FilterStructure1 = New Structure("CostGroupNumber", CurrentGroupNumber);
	
	If TypeOf(Object) = Type("FormDataStructure") Then
		FoundRows = Object.References.FindRows(FilterStructure1);
	Else
		FoundRows = Object.References.Unload().FindRows(FilterStructure1);
	EndIf;
	
	If Not FoundRows.Count() = 0 Then
		
		// If the function is called non-interactively, it is necessary to get the order data
		If Not TypeOf(Object) = Type("FormDataStructure") Then
			
			DetailsOfOrder =
				Common.ObjectAttributesValues(
					FoundRows[0].ReferenceOrder,
					"MethodOfAllocatingFinishedProductCosts,
					|DataVersion,
					|Status,
					|NextStageNo,
					|LineOfBusiness,
					|BillOfMaterials,
					|ReferenceOrder,
					|Stage,
					|ProductionLot,
					|Purpose,
					|AssignmentProducts,
					|DynamicStructure,
					|WorkPlanning");
			
			FillPropertyValues(DescriptionOfOrder, DetailsOfOrder);
			DescriptionOfOrder.OrderDocument = DetailsOfOrder.ReferenceOrder;
			
			DescriptionOfOrder.ParametersForFillingAssignments = 
				ProductionSupply.ActionParametersFillInPurposeOfProvisionInProductionPhase(
					DetailsOfOrder, Undefined);
			
			ProductionSupply.FillInListOfSelectedAssignmentsInProductionPhase(
				DetailsOfOrder, Undefined, DescriptionOfOrder.AppointmentSelectionList);
		EndIf;
		
		FillPropertyValues(DescriptionOfOrder, FoundRows[0]);
		
	EndIf;
	
	Return DescriptionOfOrder;
	
EndFunction

// Parameters:
// 	Object - DocumentObject.SubcontractOrder2_5, Structure, FormDataStructure - object data
// Returns:
// 	Structure
Function DescriptionOfOrder(Object)
	
	DescriptionOfOrder = New Structure;
	
	DescriptionOfOrder.Insert("LineNumber", 0);
	DescriptionOfOrder.Insert("ReferenceOrder", Documents.ProductionStage2_2.EmptyRef());
	DescriptionOfOrder.Insert("CostGroupNumber", "");
	DescriptionOfOrder.Insert("DataVersion", "");
	DescriptionOfOrder.Insert("ExpenseGroup", "");
	DescriptionOfOrder.Insert("NextStageNo", 0);
	DescriptionOfOrder.Insert("LineOfBusiness", Catalogs.LinesOfBusiness.EmptyRef());
	DescriptionOfOrder.Insert("BillOfMaterials", Catalogs.BillsOfMaterials.EmptyRef());
	DescriptionOfOrder.Insert("OrderDocument", Documents.ProductionOrder2_2.EmptyRef());
	DescriptionOfOrder.Insert("Stage", Catalogs.ProductionStages.EmptyRef());
	DescriptionOfOrder.Insert("Status", Enums.StatusesOfProductionStages2_2.EmptyRef());
	
	DescriptionOfOrder.Insert(
		"MethodOfAllocatingFinishedProductCosts",
		Enums.MethodsOfCostAllocatingOnProductCosts.EmptyRef());
	
	DescriptionOfOrder.Insert("ParametersForFillingAssignments", Undefined);
	DescriptionOfOrder.Insert("AppointmentSelectionList", New ValueList());
	
	Return DescriptionOfOrder;
	
EndFunction

#EndRegion

#Region Other

Function QueryTextTTGoodsOrdersArrivalOrder()
	
	QueryText = "
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	PurchaseOrders.DocumentInflow AS Ref,
	|	PurchaseOrders.Products        AS Products,
	|	PurchaseOrders.Characteristic      AS Characteristic,
	|	PurchaseOrders.Warehouse               AS Warehouse,
	|	PurchaseOrders.ToRegisterInvoicesByReferenceReceipt AS Count,
	|	0                                     AS AmountIncludingVAT
	|INTO TTGoodsNewArrival
	|FROM
	|	AccumulationRegister.GoodsToReceive.Turnovers(,,, DocumentInflow IN
	|		(SELECT
	|			TTDocuments.DocumentRef AS DocumentRef
	|		FROM
	|			TTDocuments AS TTDocuments)) AS PurchaseOrders
	|
	|INDEX BY
	|	Ref,
	|	Products,
	|	Characteristic,
	|	Warehouse
	|;";

	Return QueryText;
	
EndFunction

Function QueryTextTableCanceledReceipt()

	QueryText =  "
	|SELECT ALLOWED
	|	TTDocuments.DocumentRef AS Document,
	|	DocumentGoods.LineNumber AS LineNumber,
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	DocumentGoods.NumberOfPackages AS Count,
	|	CASE 
	|		WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) 
	|	THEN
	|		DocumentGoods.Products.UnitOfMeasure
	|	ELSE
	|		DocumentGoods.Package
	|	END AS Package,
	|	DocumentGoods.CancellationReason AS CancellationReason,
	|	0 AS Sum
	|FROM
	|	Document.SubcontractOrder2_5.ManufacturedProducts AS DocumentGoods
	|	INNER JOIN TTDocuments AS TTDocuments
	|		ON TTDocuments.DocumentRef = DocumentGoods.Ref
	|WHERE
	|	DocumentGoods.Canceled
	|
	|UNION ALL
	|
	|SELECT
	|	TTDocuments.DocumentRef AS Document,
	|	DocumentGoods.LineNumber AS LineNumber,
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	DocumentGoods.NumberOfPackages AS Count,
	|	CASE 
	|		WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) 
	|	THEN
	|		DocumentGoods.Products.UnitOfMeasure
	|	ELSE
	|		DocumentGoods.Package
	|	END AS Package,
	|	DocumentGoods.CancellationReason AS CancellationReason,
	|	0 AS Sum
	|FROM
	|	Document.SubcontractOrder2_5.SideAndIntermediateRelease AS DocumentGoods
	|	INNER JOIN TTDocuments AS TTDocuments
	|		ON TTDocuments.DocumentRef = DocumentGoods.Ref
	|WHERE
	|	DocumentGoods.Canceled
	|
	|UNION ALL
	|
	|SELECT
	|	TTDocuments.DocumentRef AS Document,
	|	DocumentGoods.LineNumber AS LineNumber,
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	DocumentGoods.NumberOfPackages AS Count,
	|	CASE 
	|		WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) 
	|	THEN
	|		DocumentGoods.Products.UnitOfMeasure
	|	ELSE
	|		DocumentGoods.Package
	|	END AS Package,
	|	DocumentGoods.CancellationReason AS CancellationReason,
	|	0 AS Sum
	|FROM
	|	Document.ProductionStage2_2.ManufacturedProducts AS DocumentGoods
	|	
	|	INNER JOIN TTDocuments AS TTDocuments
	|	ON TTDocuments.DocumentRef = DocumentGoods.Ref.SubcontractOrder
	|
	|WHERE
	|	DocumentGoods.Canceled
	|
	|UNION ALL
	|
	|SELECT
	|	TTDocuments.DocumentRef AS Document,
	|	DocumentGoods.LineNumber AS LineNumber,
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	DocumentGoods.NumberOfPackages AS Count,
	|	CASE 
	|		WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) 
	|	THEN
	|		DocumentGoods.Products.UnitOfMeasure
	|	ELSE
	|		DocumentGoods.Package
	|	END AS Package,
	|	DocumentGoods.CancellationReason AS CancellationReason,
	|	0 AS Sum
	|FROM
	|	Document.ProductionStage2_2.SideAndIntermediateRelease AS DocumentGoods
	|	
	|	INNER JOIN TTDocuments AS TTDocuments
	|	ON TTDocuments.DocumentRef = DocumentGoods.Ref.SubcontractOrder
	|
	|WHERE
	|	DocumentGoods.Canceled
	|
	|TOTALS BY
	|	Document
	|;";
	
	Return QueryText;

EndFunction

Function QueryTextTableProductsToBeProcessedInReportToProcessor()
	
	QueryText =
	"SELECT
	|	PurchaseOrdersBalanceAndTurnovers.PurchaseOrder              AS Document,
	|	PurchaseOrdersBalanceAndTurnovers.Products.Presentation   AS ProductsPresentation,
	|	PurchaseOrdersBalanceAndTurnovers.Characteristic.Presentation AS CharacteristicPresentation,
	|	""""                                                          AS SeriesPresentation,
	|	PurchaseOrdersBalanceAndTurnovers.ToRegisterReceipt            AS ToRegister,
	|	PurchaseOrdersBalanceAndTurnovers.ToRegisterClosingBalance   AS ApplyAppearance,
	|	PurchaseOrdersBalanceAndTurnovers.ToRegisterExpense            AS Issued_1
	|FROM
	|	AccumulationRegister.PurchaseOrders.BalanceAndTurnovers(,,,, PurchaseOrder IN
	|		(SELECT
	|			TTDocuments.DocumentRef AS DocumentRef
	|		FROM
	|			TTDocuments AS TTDocuments)
	|	AND Warehouse = VALUE(Catalog.Warehouses.EmptyRef)) AS PurchaseOrdersBalanceAndTurnovers
	|TOTALS BY
	|	Document
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	Return QueryText;
	
EndFunction

Function TableRawMaterialsAtProcessor()
	
	QueryText =
	"SELECT
	|	TurnoversByOrders.ReferenceOrder AS Document,
	|	TurnoversByOrders.Products AS Products,
	|	TurnoversByOrders.Characteristic AS Characteristic,
	|	TurnoversByOrders.Products.UnitOfMeasure AS Package,
	|	TurnoversByOrders.Products.Presentation AS ProductsPresentation,
	|	TurnoversByOrders.Characteristic.Presentation AS CharacteristicPresentation,
	|	TurnoversByOrders.ForRegistrationQuantityTurnover AS ToTransfer,
	|	(TurnoversByOrders.ForRegistrationQuantityTurnover -
	|		TurnoversByOrders.IssuedQuantityTurnover) AS Send,
	|	TurnoversByOrders.IssuedQuantityTurnover AS Passed
	|FROM
	|	#ShipmentOrdersTurnoverExpanded AS TurnoversByOrders
	|WHERE
	|	TurnoversByOrders.ForRegistrationQuantityTurnover <> 0
	|	OR (TurnoversByOrders.ForRegistrationQuantityTurnover -
	|		TurnoversByOrders.IssuedQuantityTurnover) <> 0
	|	OR TurnoversByOrders.IssuedQuantityTurnover <> 0
	|TOTALS
	|BY
	|	Document
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN
		|		(SELECT
		|			TTDocuments.DocumentRef AS DocumentRef
		|		FROM
		|			TTDocuments AS TTDocuments)";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic";
	TableFormationParameters.Indicators = "ToRegister, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#ShipmentOrdersTurnoverExpanded",
		ShipmentOrdersTurnoverExpanded);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableSupplyState()
	
	QueryText = 
	"SELECT ALLOWED
	|	TTDocuments.DocumentRef AS Document,
	|	DocumentGoods.LineNumber AS LineNumber,
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	DocumentGoods.Series AS Series,
	|	DocumentGoods.NumberOfPackages AS Count,
	|	CASE 
	|		WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) 
	|	THEN
	|		DocumentGoods.Products.UnitOfMeasure
	|	ELSE
	|		DocumentGoods.Package
	|	END AS Package,
	|	DocumentGoods.DateOfShipment AS DateOfShipment,
	|	DocumentGoods.SupplyOption AS Action,
	|	0 AS Sum
	|FROM
	|	Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks AS DocumentGoods
	|
	|	INNER JOIN TTDocuments AS TTDocuments
	|	ON TTDocuments.DocumentRef = DocumentGoods.Ref
	|
	|WHERE
	|	(DocumentGoods.SupplyOption IN(
	|		VALUE(Enum.SupplyOptions.ToSupply),
	|		VALUE(Enum.SupplyOptions.ReserveAsReceived),
	|		VALUE(Enum.SupplyOptions.FromWarehouse))
	|	OR CASE WHEN DocumentGoods.Ref.Status IN (&ArrayOfStatusesWithoutShipment) THEN
	|		DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	END)
	|	AND NOT DocumentGoods.Canceled
	|
	|UNION ALL
	|
	|SELECT
	|	TTDocuments.DocumentRef AS Document,
	|	DocumentGoods.LineNumber AS LineNumber,
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	DocumentGoods.Series AS Series,
	|	DocumentGoods.NumberOfPackages AS Count,
	|	CASE 
	|		WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) 
	|	THEN
	|		DocumentGoods.Products.UnitOfMeasure
	|	ELSE
	|		DocumentGoods.Package
	|	END AS Package,
	|	DocumentGoods.DateOfShipment AS DateOfShipment,
	|	DocumentGoods.SupplyOption AS Action,
	|	0 AS Sum
	|FROM
	|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS DocumentGoods
	|
	|	INNER JOIN Document.ProductionStage2_2 AS ProductionStages
	|	ON ProductionStages.Ref = DocumentGoods.Ref
	|
	|	INNER JOIN TTDocuments AS TTDocuments
	|	ON TTDocuments.DocumentRef = ProductionStages.SubcontractOrder
	|
	|WHERE
	|	(DocumentGoods.SupplyOption IN(
	|		VALUE(Enum.SupplyOptions.ToSupply),
	|		VALUE(Enum.SupplyOptions.ReserveAsReceived),
	|		VALUE(Enum.SupplyOptions.FromWarehouse))
	|	OR CASE WHEN ProductionStages.SubcontractOrder.Status IN (&ArrayOfStatusesWithoutShipment) THEN
	|		DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	END)
	|	AND NOT DocumentGoods.Canceled
	|
	|TOTALS BY
	|	Document;
	|";
	
	Return QueryText;
	
EndFunction

// Fills in the table of the object according to the standards
// 
// Parameters:
// 	DocumentTable - TabularSection
// 	Standards - ValueTable
// 	CostGroupNumber - Number
// 	StructureOfActions - Structure
// 	OperationDateParameters - Structure
//
Procedure FillInStandards_(DocumentTable, Standards, CostGroupNumber, StructureOfActions, OperationDateParameters = Undefined) Export
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	For Each CurRow In Standards Do
		
		NewRow = DocumentTable.Add();
		FillPropertyValues(NewRow, CurRow);
		NewRow.CostGroupNumber = CostGroupNumber;
		
		If Not OperationDateParameters = Undefined Then
			NewRow[OperationDateParameters.FieldName]= OperationDateParameters.Date;
		EndIf;
		
		RowsToProcess.Add(NewRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		DocumentTable,
		CachedValues);
	
EndProcedure 

Procedure ExcludeByProductsFromWeekends(Object, ProductList_, SpecificationsData)
	
	MatchingAssignments = New Map;
	
	If (Object.SeparationOfMaterialsByProductPurpose
			Or GetFunctionalOption("UseTollManufacturing2_5")
			Or False)
		And (Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductsAndAssignments
			Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductBOMAndAssignments) Then
		
		For Each String In Object.ManufacturedProducts Do
			If ValueIsFilled(String.Purpose) Then
				MatchingAssignments.Insert(String.CostGroupNumber, String.Purpose);
			EndIf;
		EndDo;
		
	EndIf;
	
	Filters = New Structure("CostGroupNumber, Products, Characteristic");
	
	For Each CurStructure In SpecificationsData Do
		
		If CurStructure = Undefined Then
			Continue;
		EndIf;
		
		Filters.CostGroupNumber = CurStructure.CostGroupNumber;
		
		RecyclableWaste = CurStructure.RecyclableWaste.CopyColumns();
		RecyclableWaste.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
		
		For Each CurrentWaste In CurStructure.RecyclableWaste Do
			
			FillPropertyValues(Filters, CurrentWaste, "Products, Characteristic");
			
			ProductionLines = ProductList_.FindRows(Filters);
			For Each CurrentManufacturedProducts In ProductionLines Do
				
				If CurrentManufacturedProducts.Count = 0 Then
					Continue;
				EndIf;
				
				Count = Min(CurrentManufacturedProducts.Count, CurrentWaste.Count);
				
				NewRow = RecyclableWaste.Add();
				FillPropertyValues(NewRow, CurrentWaste);
				NewRow.Purpose         = CurrentManufacturedProducts.Purpose;
				NewRow.Count         = Count;
				NewRow.NumberOfPackages =
					NewRow.Count
					* NewRow.PackageData.Denominator
					/ NewRow.PackageData.Numerator;
				
				CurrentManufacturedProducts.Count = CurrentManufacturedProducts.Count - Count;
				CurrentWaste.Count     = CurrentWaste.Count - Count;
				
			EndDo;
			
			If Not CurrentWaste.Count = 0 Then
				
				NewRow = RecyclableWaste.Add();
				FillPropertyValues(NewRow, CurrentWaste);
				
				NewRow.Purpose = MatchingAssignments.Get(CurStructure.CostGroupNumber);
				NewRow.NumberOfPackages =
					NewRow.Count
					* NewRow.PackageData.Denominator
					/ NewRow.PackageData.Numerator;
				
			EndIf;
			
		EndDo;
		
		CurStructure.RecyclableWaste = RecyclableWaste;
		
	EndDo;
	
	For Each TableRow In ProductList_.FindRows(New Structure("Count", 0)) Do
		ProductList_.Delete(TableRow);
	EndDo;
	
EndProcedure

Procedure SetConditionalListAppearance(List) Export

	// Conditional design of the dynamic list "List"
	ListOfConditionalAppearance = List.SettingsComposer.Settings.ConditionalAppearance; // DataCompositionConditionalAppearance
	ListOfConditionalAppearance.Items.Clear();
	
	// The document has a high priority
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Chứng từ có mức ưu tiên cao';
							|ru = 'Документ имеет высокий приоритет';
							|en = 'High priority document'; fa = 'سند با اولویت بالا';
							|it = 'Il documento ha priorità alta';
							|pl = 'Dokument ma wysoki priorytet';
							|tr = 'Belge yüksek önceliğe sahiptir'");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Priority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.Priorities.GetTopPriority();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeletionMark");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.HighPriorityDocument);
	
	// The document has a low priority
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Chứng từ có mức ưu tiên thấp';
							|ru = 'Документ имеет низкий приоритет';
							|en = 'Low priority document'; fa = 'Low priority document';
							|it = 'Il documento ha priorità bassa';
							|pl = 'Dokument ma niski priorytet';
							|tr = 'Belge düşük önceliğe sahiptir'");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Priority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.Priorities.GetLowerPriority();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeletionMark");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.LowDocumentPriority);

EndProcedure

Function FullObjectName()
	Return "Document.SubcontractOrder2_5";
EndFunction

// Initializes the calculation state structure
//
Function StructureOfStateOfCalculations()
	
	StructureOfStateOfCalculations = New Structure;
	StructureOfStateOfCalculations.Insert("State",               Enums.StatesOfTollingOrders.EmptyRef());
	StructureOfStateOfCalculations.Insert("StateOverdue",     False);
	StructureOfStateOfCalculations.Insert("PayAmount",             0);
	StructureOfStateOfCalculations.Insert("PayPercentage",           0);
	StructureOfStateOfCalculations.Insert("OrderReceiptAmount",        0);
	StructureOfStateOfCalculations.Insert("PercentageOfOrderReceipt",      0);
	StructureOfStateOfCalculations.Insert("LatePaymentAmount", 0);
	StructureOfStateOfCalculations.Insert("AmountOfDebt",              0);
	StructureOfStateOfCalculations.Insert("DebtPercentage",            0);
	StructureOfStateOfCalculations.Insert("AmountToPay",            0);
	
	Return StructureOfStateOfCalculations
	
EndFunction

Procedure FillInLineCodeInTableSection(TabularSection, InAllLines, MaximumRowCode) Export

	For Each RowData In TabularSection Do
		If InAllLines
			Or RowData.RowCode = 0 Then
			MaximumRowCode = MaximumRowCode + 1;
			RowData.RowCode = MaximumRowCode;
		EndIf;
	EndDo;
	
EndProcedure

// Returns a table of settlement amounts broken down by container/non-container and broken down by order.
// 
// Parameters:
//  ObjectReference_ - DocumentRef.SubcontractOrder2_5 - The document for which you want to get the data.
//  AttributesValues - Structure
// 
// Returns:
//  ValueTable - ValueTable:
// 		* OrderDocument - DocumentRef - OrderDocument
// 		* Date - Date - Document date
// 		* ApprovalDate - Date - Approval date (for orders)
// 		* DateOfShipment - Date - Scheduled shipment date
// 		* AmountARAP - Number - Amount Of Settlements By Line
// 		* AmountARAPByPackage - Number - The amount of settlements by container by line
Function OrderAmounts(ObjectReference_, AttributesValues = Undefined) Export
	
	Query = New Query;
	
	Query.Text =
	"SELECT
	|	&ApprovalDate     AS ApprovalDate,
	|	Services.ExecutionDate AS DateOfShipment,
	|	Services.AmountIncludingVAT      AS PaymentAmount
	|INTO TTServices
	|FROM
	|	&ValueTable AS Services
	|WHERE
	|	NOT Services.Canceled
	|	AND &LinkCondition_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UNDEFINED               AS OrderDocument,
	|	&Date                      AS Date,
	|	Services.ApprovalDate    AS ApprovalDate,
	|	Services.DateOfShipment        AS DateOfShipment,
	|	FALSE                       AS ExceedingOrder,
	|	SUM(Services.PaymentAmount) AS PaymentAmount,
	|	0                          AS AmountARAP,
	|	0                          AS PackageDepositValue,
	|	0                          AS AmountARAPByPackage
	|FROM
	|	TTServices AS Services
	|
	|GROUP BY
	|	Services.ApprovalDate,
	|	Services.DateOfShipment
	|";
	
	If AttributesValues = Undefined Then
		Query.Text = StrReplace(Query.Text, "&ValueTable", "Document.SubcontractOrder2_5.Services");
		Query.Text = StrReplace(Query.Text, "&Date", "Services.Ref.Date");
		Query.Text = StrReplace(Query.Text, "&ApprovalDate", "Services.Ref.ApprovalDate");
		Query.Text = StrReplace(Query.Text, "&LinkCondition_", "Services.Ref = &Ref");
		Query.SetParameter("Ref",ObjectReference_);
	Else
		Query.Text = StrReplace(Query.Text, "&LinkCondition_", "TRUE");
		For Each KeyValue In AttributesValues Do
			Query.SetParameter(KeyValue.Key, KeyValue.Value);
		EndDo;
	EndIf;
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#Region ToDoList

// Fills in the user's to-do list.
// 
// Parameters:
// 	ToDoList - See ToDoListServer.ToDoList
//
Procedure OnFillToDoList(ToDoList) Export
	
EndProcedure

#EndRegion

#Region OrderAdjustment

// Returns a table of acceptable deviations of measured items from the list of orders.
//
//	Parameters:
//		ListOfOrders_ - ValueList, DocumentRef.InventoryConsumptionOrder - the list of orders to determine the allowable deviations
//		InventoryMovementType - EnumRef.InventoryMovementTypes -
//	Returns:
//		ValueTable - LongDesc:
//		* OrderDocument                - DocumentRef.InventoryConsumptionOrder
//		* Products         - CatalogRef.Products
//		* Characteristic       - CatalogRef.ItemsCharacteristics
//		* Series                - CatalogRef.ItemsBatches
//		* AllowableVariance - Number
//
Function PermissibleDeviationsOfMeasuredGoods(ListOfOrders_, InventoryMovementType) Export
	
	AllowableDeviationOfMeasuringGoodsShipmentAndReceiving = Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
	
	If Not ValueIsFilled(ListOfOrders_) Or AllowableDeviationOfMeasuringGoodsShipmentAndReceiving = 0 Then
		Table = New ValueTable;
		Table.Columns.Table = New ValueTable;
		Table.Columns.Add("OrderDocument");
		Table.Columns.Add("Products");
		Table.Columns.Add("Characteristic");
		If InventoryMovementType = Enums.InventoryMovementTypes.Shipment Then
			Table.Columns.Add("Warehouse");
			Table.Columns.Add("Series");
		EndIf;
		Table.Columns.Add("AllowableVariance");
		Return Table;
	EndIf;
	
	If TypeOf(ListOfOrders_) = Type("DocumentRef.SubcontractOrder2_5") Then
		ReferenceArray = New Array();
		ReferenceArray.Add(ListOfOrders_);
	Else
		ReferenceArray = ListOfOrders_;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ReferenceArray", ReferenceArray);
	
	If InventoryMovementType = Enums.InventoryMovementTypes.Inpayment Then
		
		Query.Text =
			"SELECT
			|	GoodsToReceive.PurchaseOrder AS OrderDocument,
			|	GoodsToReceive.Products    AS Products,
			|	GoodsToReceive.Characteristic  AS Characteristic,
			|	SUM(GoodsToReceive.ToRegisterReceipt
			|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
			|FROM
			|	AccumulationRegister.PurchaseOrders.Turnovers(&StartPeriod_, &ConPeriod,
			|		, PurchaseOrder IN (&ReferenceArray)) AS GoodsToReceive
			|WHERE
			|	GoodsToReceive.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
			|GROUP BY
			|	GoodsToReceive.Products,
			|	GoodsToReceive.Characteristic,
			|	GoodsToReceive.PurchaseOrder";
		
		SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("PurchaseOrders",
			"PurchaseOrder IN (&ReferenceArray)", Query.Parameters);
		
	Else
		
		Query.Text =
			"SELECT
			|	GoodsForIssue.ReferenceOrder AS OrderDocument,
			|	GoodsForIssue.Products AS Products,
			|	GoodsForIssue.Characteristic AS Characteristic,
			|	GoodsForIssue.Series AS Series,
			|	GoodsForIssue.Warehouse AS Warehouse,
			|	SUM(GoodsForIssue.ForRegistrationQuantityTurnover * (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS
			|		AllowableVariance
			|FROM
			|	#ShipmentOrdersTurnoverExpanded AS GoodsForIssue
			|GROUP BY
			|	GoodsForIssue.ReferenceOrder,
			|	GoodsForIssue.Products,
			|	GoodsForIssue.Characteristic,
			|	GoodsForIssue.Series,
			|	GoodsForIssue.Warehouse";
		
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.BeginOfPeriod = "&StartPeriod_";
		TableFormationParameters.EndOfPeriod = "&ConPeriod";
		TableFormationParameters.ConditionText =
			"ReferenceOrder IN (&ReferenceArray)
			|		AND Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)";
		TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, Warehouse, Series";
		TableFormationParameters.Indicators = "ToRegister";
		TableFormationParameters.Resources = "Count";
		
		ShipmentOrdersTurnoverExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		Query.Text = StrReplace(Query.Text,
			"#ShipmentOrdersTurnoverExpanded",
			ShipmentOrdersTurnoverExpanded);
		
		SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("ShipmentAndReturnReferences",
			"ReferenceOrder IN (&ReferenceArray)", Query.Parameters);
		
	EndIf;
	
	Query.SetParameter("DimensionalTypesOfUnits",
		Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving);
	
	Query.SetParameter("StartPeriod_", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriod", SpeedLimits.MaxDate);
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#Region CreatingHyperlinkInSalesDocumentsJournal

// Create a hyperlink "see also".
// 
// Parameters:
//  Parameters - Structure
// 
// Returns:
//  FormattedString - hyperlink see also
//
Function CreateHyperlinkSeeAlsoIn(Parameters) Export
	
	If Not (AccessRight("Update", Metadata.Documents.SubcontractOrder2_5)
			And GetFunctionalOption("UseProductionByThirdParty2_5")) Then
		Return Undefined;
	EndIf;
	
	HyperlinkText = NStr("vi = 'Đơn đặt hàng gia công';
						|ru = 'Заказы переработчикам';
						|en = 'Subcontracting purchase orders'; fa = 'سفارش‌های خرید پیمانکاری فرعی';
						|it = 'Ordini agli addetti alla lavorazione';
						|pl = 'Zamówienia do przetwórców';
						|tr = 'Fason üretici satın alma siparişleri'");
	
	Return New FormattedString(HyperlinkText,,,, FormNameWorkplace());
	
EndFunction

// The name of the workplace form.
// 
// Returns:
//  String - Form Name Workplace
Function FormNameWorkplace() Export
	
	Return "Document.SubcontractOrder2_5.Form.Workplace";
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
