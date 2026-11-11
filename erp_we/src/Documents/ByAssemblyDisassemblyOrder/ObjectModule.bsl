#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Sets the status for the document object
//
// Parameters:
//	NewStatus - String - Name of the status that will be set for orders.
//	AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//								Structure constructor: Order a server.Structurecorrectionslist of orders().
//
// Returns:
//	Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.InternalOrderStatuses[NewStatus];
	
	If AdditionalParameters <> Undefined Then
		
		OrdersServer.AdjustOrderLines(ThisObject, AdditionalParameters);
		
	EndIf;
	
	Status = MeaningOfNewStatus;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ByAssemblyDisassemblyOrder);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters.Header);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters.TS);
	
	Return CheckFilling();
	
EndFunction

// Corrects lines for which no Assembly or warehouse orders were issued, or there are discrepancies for measured items.
//
// Parameters:
// 		ParametersStructure - Structure - Structure of adjustment parameters, constructor: order Server.Structurecorrectionslist of orders().
//
// Returns:
// 		Structure
// 		* Number of rows - the Number of canceled / adjusted rows
// 		* Adoration amount - The amount of increase in the order due to excess shipment of measured goods.
//
Function AdjustOrderLines(ParametersStructure) Export
	
	If Not ParametersStructure.CancelUnprocessedLines And Not ParametersStructure.CorrectMeasuringGoods Then
		Return OrdersServer.ResultOfUndoingUnprocessedRows(Undefined)
	EndIf;
	
	NumberOfAdjustedRows = 0;
	
	If Not ParametersStructure.CheckBalance Then
		
		PropertiesOfCanceledRow = New Structure("Canceled, BatchesIndicationStatus", True, 0);
		
		CountCanceled         = CountCanceled + Count;
		NumberOfPackagesCanceled = NumberOfPackagesCanceled + NumberOfPackages;
		Count          = 0;
		NumberOfPackages  = 0;
		BatchesIndicationStatus = 0;
		NumberOfAdjustedRows = NumberOfAdjustedRows + 1;
		
		For Each LineProducts_ In Goods Do
			If Not LineProducts_.Canceled Then
				
				FillPropertyValues(LineProducts_, PropertiesOfCanceledRow);
				NumberOfAdjustedRows = NumberOfAdjustedRows + 1;
				
			EndIf;
		EndDo;
		
		Return OrdersServer.ResultOfUndoingUnprocessedRows(NumberOfAdjustedRows);
	EndIf;
	
	SetAdjusted = Documents.ByAssemblyDisassemblyOrder.AdjustYourServer(ThisObject,
		ParametersStructure.CancelUnprocessedLines, ParametersStructure.CorrectMeasuringGoods);
	
	CancellationOptions = OrdersServer.OptionsForCancelingOrderLines();
	
	If BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		
		FillParameters = OrdersServer.FillOptionsForCancelingRows();
		FillParameters.RegisterManager  = AccumulationRegisters.AssemblyOrders;
		FillParameters.FilterByDimensions.Insert("AssemblyType", Enums.InventoryMovementTypes.Shipment);
		FillParameters.TabularSectionName = "Goods";
		FillParameters.DataPaths.Insert("Warehouse", "Warehouse");
		FillParameters.DataPaths.Insert("Purpose",
			?(Not ValueIsFilled(Purpose) And AssignByOrderAssignment, "AssignmentGoods", "Purpose"));
		
		CancellationOptions.CancelOnlyMeasuredGoods = Not ParametersStructure.CancelUnprocessedLines
			And ParametersStructure.CorrectMeasuringGoods;
		CancellationOptions.CorrectMeasuringGoods = ParametersStructure.CorrectMeasuringGoods;
		
		CancellationResult = OrdersServer.UndoUnprocessedShippingLines(ThisObject, FillParameters, CancellationOptions);
		
	Else
		
		FillParameters = OrdersServer.FillOptionsForCancelingRows();
		FillParameters.RegisterManager  = AccumulationRegisters.AssemblyOrders;
		FillParameters.FilterByDimensions.Insert("AssemblyType", Enums.InventoryMovementTypes.Inpayment);
		FillParameters.TabularSectionName = "Goods";
		FillParameters.DataPaths.Insert("Warehouse", "Warehouse");
		
		CancellationOptions.CancelOnlyMeasuredGoods = Not ParametersStructure.CancelUnprocessedLines
			And ParametersStructure.AdjustTheMeasuredGoodsUponAcceptance;
		CancellationOptions.CorrectMeasuringGoods = ParametersStructure.AdjustTheMeasuredGoodsUponAcceptance;
		
		CancellationResult = OrdersServer.CancelUnprocessedAcceptanceLines(ThisObject, FillParameters, CancellationOptions);
		
		Documents.ByAssemblyDisassemblyOrder.CancelUnprocessedSeriesOfSets(ThisObject);
		
	EndIf;
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ByAssemblyDisassemblyOrder));
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters.TS);
	
	CancelledRows = Goods.FindRows(New Structure("Canceled", True));
	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation",
		QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"));
	BatchProcessingOfTablePartServer.ProcessTSStrings(CancelledRows, StructureOfActions, Goods);
	
	Return OrdersServer.ResultOfUndoingUnprocessedRows(CancellationResult.RowsCount + Number(SetAdjusted));
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	Author = Users.CurrentUser();
	
	If TypeOf(FillingData) = Type("Structure") Then
		FillInSelectionDocument(FillingData);
		If FillingData.Property("Basis") Then
			If TypeOf(FillingData.Basis) = Type("DocumentRef.SalesOrder") Then
				FillInOnTheCustomerSOrder(FillingData);
			EndIf;
		EndIf;
	EndIf;
	
	ByAssemblyDisassemblyOrderLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	InitializeDocument(FillingData);
	
	WarehouseValue_ = Warehouse;
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	// When creating from a common domain.The creation of the basis and the definition of the assignable quantity may deliberately be empty
	// if data is transferred to the document for several warehouses. Filling in statistics can fill in this empty value,
	// you need to clear it
	If TypeOf(FillingData) = Type("Structure") And FillingData.Property("Basis") Then
		Warehouse = WarehouseValue_;
	EndIf;
	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation",
		QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"));
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, Undefined);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation",
		QualityControlClientServer.CacheByKey(CacheQualityControl, "Header"));
	Header = New Structure(
		"Products,
		|ToControlQuality,
		|QualityConfirmationDate");
	FillPropertyValues(Header, ThisObject);
	BatchProcessingOfTablePartServer.ProcessTSString(Header, StructureOfActions, Undefined);
	FillPropertyValues(ThisObject, Header);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;

	If CountCanceled = 0 Then
		
		CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
		CheckParameters.TSName = "Object";
		ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
		
	Else
		
		NotCheckedAttributeArray.Add("Count");
		NotCheckedAttributeArray.Add("NumberOfPackages");
		
	EndIf;
	
	// Checking the quantity including the goods
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	If AssemblyDisassemblyStart > AssemblyDisassemblyEnd Then

		Common.MessageToUser(
			NStr("vi = 'Ngày kết thúc đóng bộ/tách bộ nhỏ hơn ngày bắt đầu đóng bộ/tách bộ';
				|ru = 'Дата окончания сборки/разборки меньше даты начала сборки/разборки';
				|en = 'Kitting end date is less than the kitting start date'; fa = 'Kitting end date is less than the kitting start date';
				|it = 'La data di fine assemblaggio/disassemblaggio è precedente alla data di inizio di assemblaggio/disassemblaggio';
				|pl = 'Data zakończenia montażu/demontażu jest mniejsza niż data początku montażu/demontażu';
				|tr = 'Montaj/demontaj bitiş tarihi, montaj/demontaj başlangıç ​​tarihinden daha az'"),
			ThisObject,
			"AssemblyDisassemblyEnd",
			,
			Cancel);

	EndIf;

	If ValueIsFilled(RequestedDeliveryDate) And RequestedDeliveryDate < BegOfDay(Date) Then

		ErrorText = NStr("vi = 'Ngày tiếp nhận mong muốn không được nhỏ hơn ngày của chứng từ %Date%';
						|ru = 'Желаемая дата поступления должна быть не меньше даты документа %Date%';
						|en = 'Requested delivery date should not be less than document date %Date%'; fa = 'Requested delivery date should not be less than document date %Date%';
						|it = 'La data preferibile dell''arrivo non deve essere precedente alla data del documento %Date%';
						|pl = 'Planowana data wpaty powinna być nie mniejsza niż data dokumentu %Date%';
						|tr = 'İstenen kabul tarihi, belgenin %Date%tarihinden daha önce olmamalıdır'");
		ErrorText = StrReplace(ErrorText, "%Date%", Format(Date,"DLF=DD"));
		
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			"RequestedDeliveryDate",
			,
			Cancel);

	EndIf;

	If ValueIsFilled(AssemblyDisassemblyEnd) 
		And AssemblyDisassemblyEnd < BegOfDay(Date) Then

		ErrorText = NStr("vi = 'Ngày kết thúc đóng bộ/tách bộ không được nhỏ hơn ngày chứng từ %Date%';
						|ru = 'Дата окончания сборки/разборки должна быть не меньше даты документа %Date%';
						|en = 'Kitting end date should not be less than document date ""%Date%""'; fa = 'Kitting end date should not be less than document date ""%Date%""';
						|it = 'La data del termine di assemblaggio/disassemblaggio non deve essere inferiore alla data del documento %Date%';
						|pl = 'Data zakończenia montażu/demontażu powinna być nie mniejsza niż data dokumentu %Date%';
						|tr = 'Montaj/demontaj bitiş tarihi en az belge tarihi olmalıdır%Date%'");
		ErrorText = StrReplace(ErrorText, "%Date%", Format(Date,"DLF=DD"));
		
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			"AssemblyDisassemblyEnd",
			,
			Cancel);

	EndIf;

	If ValueIsFilled(AssemblyDisassemblyStart) 
		And AssemblyDisassemblyStart < BegOfDay(Date) Then

		ErrorText = NStr("vi = 'Ngày bắt đầu đóng bộ/tách bộ không được nhỏ hơn ngày chứng từ %Date%';
						|ru = 'Дата начала сборки/разборки должна быть не меньше даты документа %Date%';
						|en = 'Kitting start date cannot be less than document date ""%Date%""'; fa = 'Kitting start date cannot be less than document date ""%Date%""';
						|it = 'La data d''inizio di assemblaggio/disassemblaggio non deve essere inferiore alla data del documento ""%Date%""';
						|pl = 'Data początku montażu/demontażu powinna być nie mniejsza niż data dokumentu %Date%';
						|tr = 'Montaj/demontaj başlangıç ​​tarihi en az belge tarihi olmalıdır %Date%'");
		ErrorText = StrReplace(ErrorText, "%Date%", Format(Date,"DLF=DD"));
		
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			"AssemblyDisassemblyStart",
			,
			Cancel);

	EndIf;
	
	// Checking the characteristics in the header.
	If GetFunctionalOption("UseItemVariants")
		And Not Catalogs.Products.ItemVariantsAreUsed(Products) Then

		NotCheckedAttributeArray.Add("Characteristic");

	EndIf;
		
	// Checking the characteristics, including goods.
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Products", Products);
	TheStructureOfTheSearch.Insert("Characteristic", Characteristic);
	
	FoundRows = Goods.FindRows(TheStructureOfTheSearch);
	
	For Each TSRow In FoundRows Do
		
		MessageText = NStr("vi = 'Trong dòng %LineNumber% đã chỉ định hàng hóa ""%ProductName_%"".
		|Một hàng hóa không thể đồng thời là bộ và thành phần chi tiết.';
		|ru = 'В строке %LineNumber% указан товар ""%ProductName_%"".
		|Один и тот же товар не может являться и комплектом, и комплектующей одновременно.';
		|en = 'You have specified ""%ProductName_%"" in line %LineNumber%.
		|The same product cannot be both a set and a component.'; fa = 'You have specified ""%ProductName_%"" in line %LineNumber%.
		|The same product cannot be both a set and a component.';
		|it = 'La riga %LineNumber% contiene il prodotto ""%ProductName_%"".
		|Il prodotto non può essere un insieme e un componente allo stesso tempo.';
		|pl = 'W wierszu %LineNumber% jest podany towar ""%ProductName_%"".
		|Jeden i ten sam towar nie może być jednocześnie kompletem i komponentem.';
		|tr = '%LineNumber% satırında ürün belirtildi ""%ProductName_%"". 
		|Aynı ürün aynı anda hem set hem de bileşen olamaz.'");
		
		MessageText = StrReplace(MessageText, "%ProductName_%",	ProductsClientServer.ProductPresentation(Products, Characteristic));
		MessageText = StrReplace(MessageText, "%LineNumber%", TSRow.LineNumber);
	
		Field = CommonClientServer.PathToTabularSection("Goods",TSRow.LineNumber,"Products");
		Common.MessageToUser(MessageText,,Field,"Object",Cancel);
		
	EndDo;
	
	If BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents Then
		NotCheckedAttributeArray.Add("Goods.SupplyOption");
	EndIf;
	
	SeriesSpecificationParameters =  ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ByAssemblyDisassemblyOrder);
	ParametersArray = New Array;
	ParametersArray.Add(SeriesSpecificationParameters.TS);
	ParametersArray.Add(SeriesSpecificationParameters.Header);
	ProductsServer.CheckSeriesCompletion(ThisObject,
		ParametersArray,
		Cancel,
		NotCheckedAttributeArray);
	
	If BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		
		QualityControl.ProcessingVerificationOfFillingInReceiptDocument(
			ThisObject,
			NotCheckedAttributeArray,
			Cancel,
			Undefined,
			Undefined,
			"AssemblyDisassemblyEnd");
			
		NotCheckedAttributeArray.Add("Goods.QualityConfirmationDate");
		
	Else
	
		QualityControl.ProcessingVerificationOfFillingInReceiptDocument(
			ThisObject,
			NotCheckedAttributeArray,
			Cancel,
			"Goods",
			NStr("vi = 'Hàng hóa';
				|ru = 'Товары';
				|en = 'Items'; fa = 'اقلام';
				|it = 'Merci';
				|pl = 'Wiersze pozycji';
				|tr = 'Ürünler'"),
			"AssemblyDisassemblyEnd");
			
		NotCheckedAttributeArray.Add("QualityConfirmationDate");
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	CheckParameters = VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity();
	CheckParameters.TabularSectionName = "Goods";
	VATAccountingERP.CheckCompletionOfDocumentByTypeOfVATActivity(ThisObject, AssemblyForActivity, CheckParameters, Cancel);
	
	ByAssemblyDisassemblyOrderLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	OrdersServer.SetKeyInRowsOfTablePart(ThisObject, "Goods");
	
	SeriesParameters_ = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ByAssemblyDisassemblyOrder);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesParameters_);
	
	RoundingParameters = ProductsServer.ParametersForRoundingNumberOfUnitProducts();
	RoundingParameters.TSName = "Object";
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode, RoundingParameters);
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	DestinationPattern = Documents.ByAssemblyDisassemblyOrder.DestinationPattern(ThisObject);
	DestinationDegeneration = Catalogs.Assignments.CheckFillBeforeRecording(
		?(BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents, AssignmentGoods, Purpose),
		DestinationPattern, ThisObject, "LineOfBusiness", Cancel);
	
	If DestinationDegeneration Then
		AssignByOrderAssignment = Constants.OptionOfGoodsAssignmentInAssembly.Get()
			<> Enums.OptionsOfGoodsAssignmentInAssembly.AssignmentOfAssembledKit;
	EndIf;
	
	ByAssemblyDisassemblyOrderLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	DestinationPattern = Documents.ByAssemblyDisassemblyOrder.DestinationPattern(ThisObject);
	Catalogs.Assignments.OnWriteDocument(
		?(BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents, AssignmentGoods, Purpose),
		DestinationPattern, ThisObject, Warehouse, AssemblyForActivity);
	
	ByAssemblyDisassemblyOrderLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)

	If GetFunctionalOption("UseStatusesOfAssemblyOrders") Then
		Status = Metadata().Attributes.Status.FillValue;
	Else
		Status = Enums.InternalOrderStatuses.Closed;
	EndIf;
	
	DocumentBasis       = Undefined;
	AssemblyDisassemblyStart    = Date(1, 1, 1);
	AssemblyDisassemblyEnd = Date(1, 1, 1);
	RequestedDeliveryDate = Date(1, 1, 1);
	MaximumRowCode   = 0;
	NumberOfPackagesCanceled = 0;
	CountCanceled = 0;
	
	For Each LineProducts_ In Goods Do
		
		LineProducts_.Canceled = False;
		LineProducts_.RowCode = 0;
		LineProducts_.Purpose = Catalogs.Assignments.EmptyRef();
		
	EndDo;
	
	Purpose       = Undefined;
	AssignmentGoods = Undefined;
	
	SetOfSeries.Clear();

	InitializeDocument();
	
	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation",
		QualityControlClientServer.CacheByKey(CacheQualityControl, "Goods"));
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation",
		QualityControlClientServer.CacheByKey(CacheQualityControl, "Header"));
	Header = New Structure(
		"Products,
		|ToControlQuality,
		|QualityConfirmationDate");
	FillPropertyValues(Header, ThisObject);
	BatchProcessingOfTablePartServer.ProcessTSString(Header, StructureOfActions, Undefined);
	FillPropertyValues(ThisObject, Header);
	
	ByAssemblyDisassemblyOrderLocalization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	PerformOrderControlAfterConducting(Cancel);
	
	ByAssemblyDisassemblyOrderLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	ByAssemblyDisassemblyOrderLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInSelectionDocument(Val FillingData)
	
	FillPropertyValues(ThisObject, FillingData);
	
	If Not ValueIsFilled(ProductKit) Then
		
		ProductKit = Catalogs.ProductKitConfigurations.GetBasicEquipment(
			Products, Characteristic);
		
	EndIf;
	
	If FillingData.Property("Goods") Then
		If TypeOf(FillingData.Goods) = Type("Array") Then
			UploadProducts(FillingData.Goods);
		Else
			Goods.Load(FillingData.Goods);
		EndIf;
	EndIf;
	
	If ValueIsFilled(ProductKit) Then
		
		Attributes = "";
		If Not ValueIsFilled(AssemblyDisassemblyDurationDays) Then
			Attributes = Attributes + ?(ValueIsFilled(Attributes), ", ", "") + "AssemblyDisassemblyDurationDays";
		EndIf;
		
		If Not ValueIsFilled(Count) And Not ValueIsFilled(NumberOfPackages) Then
			Attributes = Attributes + ?(ValueIsFilled(Attributes), ", ", "") + "Count, NumberOfPackages, Package";
		EndIf;
		
		If ValueIsFilled(Attributes) Then
		
			ConfigurationOptionsParameters = Common.ObjectAttributesValues(ProductKit, Attributes);
			FillPropertyValues(ThisObject, ConfigurationOptionsParameters);
		
		EndIf;
		
	EndIf;
	
	// The beginning of the assembly and the end of the assembly are calculated only if they are not filled.
	// When forming orders for assembly (disassembly) from the workplace of forming orders according to assembly (disassembly) plans
	// The beginning of the assembly and the end of the assembly are calculated according to the calendar.
	If ValueIsFilled(AssemblyDisassemblyDurationDays)
		And (Not ValueIsFilled(AssemblyDisassemblyStart)
		Or Not ValueIsFilled(AssemblyDisassemblyEnd))Then
		
		If ValueIsFilled(AssemblyDisassemblyStart) Then
			
			AssemblyDisassemblyEnd = AssemblyDisassemblyStart + AssemblyDisassemblyDurationDays * 86400;
			
		ElsIf ValueIsFilled(AssemblyDisassemblyEnd) Then
			
			AssemblyDisassemblyStart = AssemblyDisassemblyEnd - AssemblyDisassemblyDurationDays * 86400;
			
		EndIf;
		
	ElsIf ValueIsFilled(AssemblyDisassemblyStart) And ValueIsFilled(AssemblyDisassemblyEnd) Then
		
		AssemblyDisassemblyDurationDays = (AssemblyDisassemblyEnd - AssemblyDisassemblyStart) / 86400;
		
	EndIf;
	
	If Not FillingData.Property("Goods") Then
	
		FillInProductsByConfigurationOption();
	
	EndIf;
	
EndProcedure

Procedure FillInOnTheCustomerSOrder(FillingData)
	
	SalesOrder = FillingData.Basis;
	Query = New Query(
		"SELECT
		|	SalesOrder.Priority AS Priority,
		|	SalesOrder.Organization AS Organization,
		|	SalesOrder.SalesOpportunity AS SalesOpportunity,
		|	SalesOrder.Department AS Department,
		|	CASE
		|		WHEN SalesOrder.LineOfBusiness.CostAccounting
		|			THEN SalesOrder.LineOfBusiness
		|	END AS LineOfBusiness
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|WHERE
		|	SalesOrder.Ref = &SalesOrder");
	
	Query.SetParameter("SalesOrder", SalesOrder);
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	// Filling in the header
	Organization             = Attributes.Organization;
	SalesOpportunity                  = Attributes.SalesOpportunity;
	Priority               = Attributes.Priority;
	DocumentBasis       = SalesOrder;
	Department           = Attributes.Department;
	LineOfBusiness = Attributes.LineOfBusiness;
	
	// Filling in the tabular part.
	GoodsTable = GetFromTempStorage(FillingData.AddressGoods);
	DeleteFromTempStorage(FillingData.AddressGoods);
	
	If GoodsTable.Count() > 0 Then
		
		FillPropertyValues(ThisObject, GoodsTable[0]);
		
		ThisObject.ProductKit = Catalogs.ProductKitConfigurations.GetBasicEquipment(
			Products, Characteristic);
		
		If ValueIsFilled(ThisObject.ProductKit) Then
			ThisObject.AssemblyDisassemblyDurationDays = 
				Common.ObjectAttributeValue(ThisObject.ProductKit, "AssemblyDisassemblyDurationDays");
		EndIf;
		
		ThisObject.FillInProductsByConfigurationOption();
		
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)

	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	
	If Not GetFunctionalOption("UseStatusesOfAssemblyOrders") Then
		Status = Enums.InternalOrderStatuses.Closed;
	EndIf;
	
	ProvisionInDocumentsServer.FillInDefaultSecurityOption(Goods);
	
	// Filling out the option of providing the disassembled kit.
	TableFromObject = New ValueTable();
	TableFromObject.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	TableFromObject.Columns.Add("SupplyOption");
	TableFromObject.Columns.Add("WithAssignment");
	FillPropertyValues(TableFromObject.Add(), ThisObject);
	
	ProvisionInDocumentsServer.FillInDefaultSecurityOption(TableFromObject);
	
	SupplyOption = TableFromObject[0].SupplyOption;
	WithAssignment        = TableFromObject[0].WithAssignment;
	
	AssignByOrderAssignment = Constants.OptionOfGoodsAssignmentInAssembly.Get()
		<> Enums.OptionsOfGoodsAssignmentInAssembly.AssignmentOfAssembledKit;
	
	GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption();
	
	FillParameters = Documents.ByAssemblyDisassemblyOrder.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(AssemblyForActivity, FillParameters);
	Priority = SettingsValueCached.GetDefaultPriority(Priority);
	
EndProcedure

// The procedure fills in the table part "Products" with components
// received for the main configuration option.
//
Procedure FillInProductsByConfigurationOption() Export
	
	Goods.Load(Catalogs.ProductKitConfigurations.GetProductComponents(ProductKit, , Count));

EndProcedure

Procedure UploadProducts(Source)
	
	Goods.Clear();
	For Each String In Source Do
		FillPropertyValues(Goods.Add(), String);
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

// Checks whether the document can be held in the "Closed" status.
//
// Parameters:
//  Cancel	 - Boolean - the "Failure" parameter for processing data.
//
Procedure PerformOrderControlAfterConducting(Cancel)

	MonitorShipment = GetFunctionalOption("DoNotCloseAssemblyOrdersWithoutCompleteShipment");
	
	If Status = Enums.InternalOrderStatuses.Closed
		And MonitorShipment Then
		Array = CommonClientServer.ValueInArray(Ref);
		AdditionalParameters = New Structure("OrderFulfillmentControl", True);
		
		Query = Documents.ByAssemblyDisassemblyOrder.GenerateVerificationRequestWhenStatusChanges(Array, "Closed", AdditionalParameters);
		
		Result = Query.Execute();
		
		SampleShipment = Result.Select();
		
		While SampleShipment.Next() Do
			
			CheckPassed = Documents.ByAssemblyDisassemblyOrder.CheckingBeforeChangingStatus(SampleShipment, Status, AdditionalParameters);
			If Not CheckPassed Then
				Cancel = True;
			EndIf;
			
		EndDo;
		
	EndIf;

EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf
