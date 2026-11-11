#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Sets the status for the document object
//
// Parameters:
//	NewStatus - String - Name of the status that will be set for orders
//	AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//
// Returns:
//	Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.StatusesOfOrdersForMaterialsForProduction[NewStatus];
	
	If AdditionalParameters <> Undefined Then
		
		OrdersServer.AdjustOrderLines(ThisObject, AdditionalParameters);
		
	EndIf;
	
	Status = MeaningOfNewStatus;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.OrderOfMaterialsForProduction);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
	Return CheckFilling();
	
EndFunction

// Corrects lines that had not been issued a receipt or warehouse warrant or there are differences in the measured products.
// 
// Parameters:
// 	ParametersStructure - See OrdersServer.OrderLineAdjustmentStructure
// Returns:
// 	Structure - LongDesc:
// * Notification - String - notification text
// * RowsCount - Number - Number of canceled / adjusted rows
//
Function AdjustOrderLines(ParametersStructure) Export
	
	If Not ParametersStructure.CancelUnprocessedLines And Not ParametersStructure.CorrectMeasuringGoods Then
		Return OrdersServer.ResultOfUndoingUnprocessedRows(Undefined)
	EndIf;
	
	NumberOfAdjustedRows = 0;
	
	If Not ParametersStructure.CheckBalance Then
		
		PropertiesOfCanceledRow = New Structure;
		PropertiesOfCanceledRow.Insert("Canceled", True);
		PropertiesOfCanceledRow.Insert("BatchesIndicationStatus", 0);
		// Quality control
		PropertiesOfCanceledRow.Insert("ToControlQuality", False);
		PropertiesOfCanceledRow.Insert("QualityConfirmationDate", Undefined);
		
		For Each LineProducts_ In Goods Do
			If Not LineProducts_.Canceled Then
				
				FillPropertyValues(LineProducts_, PropertiesOfCanceledRow);
				NumberOfAdjustedRows = NumberOfAdjustedRows + 1;
				
			EndIf;
		EndDo;
		
		Return OrdersServer.ResultOfUndoingUnprocessedRows(NumberOfAdjustedRows);
	EndIf;
	
	FillParameters = OrdersServer.FillOptionsForCancelingRows();
	FillParameters.RegisterManager  = AccumulationRegisters.OrdersOfMaterialsForProduction;
	FillParameters.TabularSectionName = "Goods";
	FillParameters.DataPaths.Insert("Warehouse", "Warehouse");
	If AssignByOrderAssignment Then
		FillParameters.ReplacementTable = Goods.Unload(,"LineNumber, Purpose");
		Catalogs.Assignments.FillInSecurityAssignment(FillParameters.ReplacementTable, Purpose, "Purpose");
	EndIf;
	
	CancellationOptions = OrdersServer.OptionsForCancelingOrderLines();
	CancellationOptions.CancelOnlyMeasuredGoods = Not ParametersStructure.CancelUnprocessedLines
		And ParametersStructure.CorrectMeasuringGoods;
	CancellationOptions.CorrectMeasuringGoods = ParametersStructure.CorrectMeasuringGoods;
	
	CancellationResult = OrdersServer.UndoUnprocessedShippingLines(ThisObject, FillParameters, CancellationOptions);
	
	If Not CancellationResult.RowsCount = 0 Then
		For Each LineProducts_ In Goods Do
			If LineProducts_.Canceled Then
				LineProducts_.ToControlQuality = False;
				LineProducts_.QualityConfirmationDate = Undefined;
			EndIf;
		EndDo;
	EndIf;
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.OrderOfMaterialsForProduction));
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
	Return CancellationResult;
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocumentBeforeFillingItOut();
	
	If TypeOf(FillingData) = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	EndIf;
	
	TableOfGoods = Undefined;
	If TypeOf(FillingData) = Type("Structure")
			And FillingData.Property("Goods")
			And TypeOf(FillingData.Goods) = Type("ValueTable") Then
			TableOfGoods = FillingData.Goods; // ValueTable
	EndIf;
	
	ThereIsProvisionOption =
		Not TableOfGoods = Undefined
			And TableOfGoods.Columns.Find("SupplyOption") <> Undefined
		Or TypeOf(FillingData) = Type("Structure")
			And FillingData.Property("HeaderAttributes")
			And FillingData.HeaderAttributes.Property("DonTFillOutDefaultCollateralOption");
	
	InitializeDocument(FillingData, Not ThereIsProvisionOption);
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	NotCheckedAttributeArray.Add("Goods.ShipmentStart");
	NotCheckedAttributeArray.Add("Goods.ReceiptEnd");
	NotCheckedAttributeArray.Add("Warehouse");
	NotCheckedAttributeArray.Add("DateOfShipment");
	
	If ProductionManagement2_2 Then
		NotCheckedAttributeArray.Add("Department");
	Else
		NotCheckedAttributeArray.Add("ShopFloorStockroom");
	EndIf;
	
	CheckHeaderDetails_(Cancel);
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	// The date of shipment in the header must be at least the date of the document
	If Not ProductionManagement2_2
		And NotShipInInstallments And 
		ValueIsFilled(DateOfShipment) And 
		DateOfShipment < BegOfDay(Date) Then
		
		ErrorText = NStr("vi = 'Ngày giao hàng không được nhỏ hơn ngày chứng từ %Date%';
						|ru = 'Дата отгрузки должна быть не меньше даты документа %Date%';
						|en = 'Shipment date cannot be less than document date%Date%'; fa = 'Shipment date cannot be less than document date%Date%';
						|it = 'La data della spedizione non deve essere inferiore alla data del documento %Date%';
						|pl = 'Data wysyłki powinna być nie mniejsza niż data dokumentu %Date%';
						|tr = 'Sevkiyat tarihi, belgenin %Date% tarihinden önce olmamalıdır'");
		ErrorText = StrReplace(ErrorText, "%Date%", Format(Date,"DLF=DD"));
		
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			"DateOfShipment",
			,
			Cancel);
		
	EndIf;
	
	EmbeddingParameters = Documents.OrderOfMaterialsForProduction.AvailableRemainingEmbeddingOptions();
	ErrorsTable = ProvisionInDocumentsServer.TableOfFillingErrors(ThisObject, EmbeddingParameters);
	
	DateOfShipmentRequired_  = False;
	WarehouseIsRequired          = False;
	
	TextTemplate1 = ?(UseTransferDuration,
		NStr("vi = 'Chưa điền cột ""Bắt đầu giao hàng"" tại dòng %LineNumber% trong danh sách ""Nguyên vật liệu""';
			|ru = 'Не заполнена колонка ""Начало отгрузки"" в строке %LineNumber% списка ""Материалы""';
			|en = 'Column ""Shipment start"" in line %LineNumber% of the ""Materials"" list is not filled in'; fa = 'Column ""Shipment start"" in line %LineNumber% of the ""Materials"" list is not filled in';
			|it = 'Non è compilata la colonna ""Spedizione iniziata"" nella riga %LineNumber% dell''elenco ""Materiali""';
			|pl = 'Nie wypełniono kolumny ""Początek wysyłki"" w wierszu %LineNumber% listy ""Materiały""';
			|tr = '""Malzemeler"" listesinin %LineNumber% satırında ""Sevkiyat başlangıcı"" sütunu doldurulmadı'"),
		NStr("vi = 'Chưa điền cột ""Ngày giao hàng"" tại dòng %LineNumber% trong danh sách ""Nguyên vật liệu""';
			|ru = 'Не заполнена колонка ""Дата отгрузки"" в строке %LineNumber% списка ""Материалы""';
			|en = 'Column ""Shipment date"" in line %LineNumber% of the ""Materials"" list is not filled in'; fa = 'Column ""Shipment date"" in line %LineNumber% of the ""Materials"" list is not filled in';
			|it = 'Non è compilata la colonna ""Data di spedizione"" nella riga %LineNumber% dell''elenco ""Materiali""';
			|pl = 'Nie wypełniono kolumny ""Data wysyłki"" w wierszu %LineNumber% listy ""Materiały""';
			|tr = '""Malzemeler"" listesinin %LineNumber% satırında ""Sevkiyat tarihi"" sütunu doldurulmadı'"));
		
	For CurIndex__ = 0 To ErrorsTable.Count() - 1 Do
		
		ErrorString = ErrorsTable[CurIndex__];
		
		If ErrorString.DateOfShipmentRequired_ And Not NotShipInInstallments And ErrorString.ShipmentDateNotFilledIn Then
			
			ErrorText   = StrReplace(TextTemplate1, "%LineNumber%", ErrorString.LineNumber);
			PathToTop = CommonClientServer.PathToTabularSection("Goods", ErrorString.LineNumber, "ShipmentStart");
			Common.MessageToUser(ErrorText, ThisObject, PathToTop, , Cancel);
			
		EndIf;
		
		WarehouseIsRequired = WarehouseIsRequired Or ErrorString.WarehouseIsRequired;
		DateOfShipmentRequired_ = DateOfShipmentRequired_ Or ErrorString.DateOfShipmentRequired_;
		
	EndDo;
	
	If NotShipInInstallments And DateOfShipmentRequired_ And Not ValueIsFilled(DateOfShipment) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Ngày giao hàng""';
						|ru = 'Поле ""Дата отгрузки"" не заполнено';
						|en = '""Shipment date"" is not filled in'; fa = '""Shipment date"" is not filled in';
						|it = 'Il campo ""Data di spedizione"" non è compilato';
						|pl = 'Nie wypełniono pole ""Data отгрузки""';
						|tr = '""Sevkiyat tarihi"" alanı doldurulmadı'");
		Common.MessageToUser(ErrorText, ThisObject, "DateOfShipment", , Cancel);
		
	EndIf;
	
	If WarehouseIsRequired And Not ValueIsFilled(Warehouse) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Kho bãi""';
						|ru = 'Поле ""Склад"" не заполнено';
						|en = '""Warehouse"" is required'; fa = '""Warehouse"" is required';
						|it = 'Il campo ""Magazzino"" non è compilato';
						|pl = 'Nie wypełniono pola ""Magazyn""';
						|tr = '""Ambar"" alanı doldurulmadı'");
		Common.MessageToUser(ErrorText, ThisObject, "Warehouse", , Cancel);
		
	EndIf;
	
	For Each TSRow In Goods Do
		
		ErrorAddress = " " + NStr("vi = 'trong dòng %LineNumber% của danh sách ""Hàng hóa""';
									|ru = 'в строке %LineNumber% списка ""Товары""';
									|en = 'in line %LineNumber% of the ""Goods"" list'; fa = 'in line %LineNumber% of the ""Goods"" list';
									|it = 'nella riga %LineNumber% dell''elenco ""Merci""';
									|pl = 'w wierszu %LineNumber% listy ""Towary""';
									|tr = '""Ürünler"" listesinin %LineNumber% satırında'");
		ErrorAddress = StrReplace(ErrorAddress,"%LineNumber%", TSRow.LineNumber);
		
		// The date of shipment in pm Goods must be at least the date of the document
		If (Not NotShipInInstallments Or ProductionManagement2_2)
			And ValueIsFilled(TSRow.ShipmentStart)
			And TSRow.ShipmentStart < BegOfDay(Date) Then
			
			ErrorText = NStr("vi = 'Ngày giao hàng phải có ít nhất là ngày của chứng từ ""%Date%"" trong dòng %LineNumber% của danh sách ""Hàng hóa""';
							|ru = 'Дата отгрузки должна быть не меньше даты документа ""%Date%"" в строке %LineNumber% списка ""Товары""';
							|en = 'Shipment date cannot be less than document date ""%Date%"" in line %LineNumber% of the Item list'; fa = 'Shipment date cannot be less than document date ""%Date%"" in line %LineNumber% of the Item list';
							|it = 'La data della spedizione non deve essere inferiore alla data del documento ""%Date%"" nella riga %LineNumber% dell''elenco ""Merci""';
							|pl = 'Data wysyłki powinna być nie mniejsza niż data dokumentu ""%Date%"" w wierszu %LineNumber% listy ""Товары""';
							|tr = 'Sevkiyat tarihi, ""Ürünler"" listesinin %LineNumber% satırında belgenin ""%Date%"" tarihinden önce olmamalıdır'");
			ErrorText = StrReplace(ErrorText,"%Date%", Format(Date, "DLF=DD"));
			ErrorText = StrReplace(ErrorText,"%LineNumber%", TSRow.LineNumber);
			
			Common.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", TSRow.LineNumber, "ShipmentStart"),
				,
				Cancel);
			
		EndIf;
		
		If ProductionManagement2_2
				And UseTransferDuration
				And Not TSRow.Canceled
				And Not ValueIsFilled(TSRow.ReceiptEnd)
				And TSRow.SupplyOption = Enums.SupplyOptions.Ship Then
				
			ErrorText = NStr("vi = 'Chưa điền cột ""Kết thúc tiếp nhận""';
							|ru = 'Не заполнена колонка ""Окончание поступления""';
							|en = 'Column ""Receipt end"" is not filled in'; fa = 'Column ""Receipt end"" is not filled in';
							|it = 'La colonna ""Termine dell''arrivo"" non è compilata';
							|pl = 'Nie wypełniono kolumny ""Окончание поступления""';
							|tr = '""Giriş Bitişi"" sütunu doldurulmadı'");
			
			Common.MessageToUser(
				ErrorText + ErrorAddress,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", TSRow.LineNumber, "ReceiptEnd"),
				,
				Cancel);
			
		EndIf;
		
		If ProductionManagement2_2 And UseTransferDuration And ValueIsFilled(TSRow.ShipmentStart) And ValueIsFilled(TSRow.ReceiptEnd) And TSRow.ShipmentStart > TSRow.ReceiptEnd Then
			
			ErrorText = NStr("vi = 'Ngày kết thúc tiếp nhận nhỏ hơn ngày bắt đầu giao hàng';
							|ru = 'Дата окончания поступления меньше даты начала отгрузки';
							|en = 'Receipt end date is less than the shipment start date'; fa = 'Receipt end date is less than the shipment start date';
							|it = 'La data del termine di arrivo è inferiore alla data dell''inizio di spedizione';
							|pl = 'Data zakończenia wpłaty jest mniejsza niż data początku wysyki';
							|tr = 'Girişin bitiş tarihi, sevkiyat başlangıcı tarihinden daha önce'");
			
			Common.MessageToUser(
				ErrorText + ErrorAddress,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", TSRow.LineNumber, "ReceiptEnd"),
				,
				Cancel);
			
		EndIf;
		
		If ProductionManagement2_2 And UseTransferDuration And ValueIsFilled(TSRow.ReceiptEnd) And TSRow.ReceiptEnd < BegOfDay(Date) Then
			
			ErrorText = NStr("vi = 'Ngày kết thúc tiếp nhận không được nhỏ hơn ngày chứng từ ""%Date%""';
							|ru = 'Дата окончания поступления должна быть не меньше даты документа ""%Date%""';
							|en = 'Receipt end date should not be less than document date ""%Date%""'; fa = 'Receipt end date should not be less than document date ""%Date%""';
							|it = 'La data del termine di arrivo non deve essere inferiore alla data del documento %Date%';
							|pl = 'Data zakończenia wpłaty powinna być nie mniejsza niż data dokumentu ""%Date%""';
							|tr = 'Girişin bitiş tarihi, belgenin ""%Date%"" tarihinden önce olmamalıdır.'");
			ErrorText = StrReplace(ErrorText,"%Date%", Format(Date, "DLF=DD"));
			
			Common.MessageToUser(
				ErrorText + ErrorAddress,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", TSRow.LineNumber, "ReceiptEnd"),
				,
				Cancel);
			
		EndIf;
		
	EndDo;
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel);
	ProductsServer.CheckSeriesCompletion(
		ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.OrderOfMaterialsForProduction),
		Cancel,
		NotCheckedAttributeArray);
		
	If BusinessOperation <> Enums.BusinessTransactions.TransferToProduction Then
		NotCheckedAttributeArray.Add("Department");
	EndIf;
	
	QualityControl.ProcessingVerificationOfFillingInReceiptDocument(
		ThisObject,
		NotCheckedAttributeArray,
		Cancel,
		"Goods",
		NStr("vi = 'Nguyên vật liệu';
			|ru = 'Материалы';
			|en = 'Materials'; fa = 'مواد';
			|it = 'Materials';
			|pl = 'Materials';
			|tr = 'Malzemeler'"),
		".ReceiptEnd",
		ProductionManagement2_2);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	OrdersServer.SetKeyInRowsOfTablePart(ThisObject, "Goods");
	
	If ProductionManagement2_2 And Not UseTransferDuration Then
		Goods.LoadColumn(Goods.UnloadColumn("ShipmentStart"), "ReceiptEnd");
	EndIf;
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	If ProductionManagement2_2 And ValueIsFilled(ShopFloorStockroom) Then
		Department = Common.ObjectAttributeValue(ShopFloorStockroom, "Department");
	EndIf;
	
	If ProductionManagement2_2 Then
		NotShipInInstallments = False;
	Else
		If Not NotShipInInstallments Then
			
			NewShipmentDate = Date(1, 1, 1);
			
			If Goods.Count() > 0 Then
				
				RequirementsForProvision = Goods.FindRows(New Structure("Canceled", False));
				
				If RequirementsForProvision.Count() > 0 Then
					
					TableOfRowsToProvide = Goods.Unload(RequirementsForProvision, "ShipmentStart");
					TableOfRowsToProvide.Sort("ShipmentStart Asc");
					NewShipmentDate = TableOfRowsToProvide[0].ShipmentStart;
					
				EndIf;
				
			EndIf;
			
			DateOfShipment = NewShipmentDate;
		Else
			ProvisionInDocumentsServer.FillInShippingDatesInTable(DateOfShipment, Goods, "ShipmentStart");
		EndIf;
	EndIf;
	
	DestinationPattern = Documents.OrderOfMaterialsForProduction.DestinationPattern(ThisObject);
	DestinationDegeneration = Catalogs.Assignments.CheckFillBeforeRecording(Purpose, DestinationPattern,
		ThisObject, "LineOfBusiness", Cancel);
	
	If DestinationDegeneration Then
		AssignByOrderAssignment = Constants.OptionOfMaterialAssignmentWhenTransferringToProduction.Get()
			<> Enums.OptionsOfMaterialAssignmentWhenTransferringToProduction.AssignmentRecipient;
	EndIf;
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	DestinationPattern = Documents.OrderOfMaterialsForProduction.DestinationPattern(ThisObject);
	Catalogs.Assignments.OnWriteDocument(Purpose, DestinationPattern, ThisObject, Department, ConsumptionForActivity);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	RequestedDeliveryDate = Date(1, 1, 1);
	
	Status = Enums.StatusesOfOrdersForMaterialsForProduction.ForCompletion;
	MaximumRowCode = 0;
	Purpose = Undefined;
	DocumentBasis = Undefined;
	ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.EmptyRef();
	
	For Each LineProducts_ In Goods Do
		LineProducts_.ShipmentStart = Date(1, 1, 1);
		LineProducts_.Canceled = False;
		LineProducts_.RowCode = 0;
		LineProducts_.Purpose = Undefined;
		LineProducts_.ReceiptEnd = Date(1, 1, 1);
		LineProducts_.ToControlQuality = Undefined;
		LineProducts_.QualityConfirmationDate = Date(1, 1, 1);
	EndDo;
	
	InitializeDocument();
	
	Author = Users.CurrentUser();
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocumentBeforeFillingItOut()
	
	Author = Users.CurrentUser();
	EmployeeResponsible = Users.CurrentUser();
	
	AssignByOrderAssignment =
		Not Constants.OptionOfMaterialAssignmentWhenTransferringToProduction.Get() =
			Enums.OptionsOfMaterialAssignmentWhenTransferringToProduction.AssignmentRecipient;
	
	ProductionManagement2_2 = GetFunctionalOption("UseProductionManagement2_2");
	
	If ProductionManagement2_2 Then
		BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom;
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined, FillingOutCollateralOption = True)

	EmployeeResponsible = Users.CurrentUser();
	
	If TypeOf(FillingData) = Type("Structure") And Not FillingData.Property("Organization") Then	
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf; 
	
	If TypeOf(FillingData) = Type("Structure") And Not FillingData.Property("Warehouse") Then	
		Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	EndIf; 
	
	If TypeOf(FillingData) = Type("Structure") And Not FillingData.Property("Department") Then	
		Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	EndIf; 
	
	If FillingOutCollateralOption Then
		ProvisionInDocumentsServer.FillInDefaultSecurityOption(Goods);
	EndIf;
	
	AssignByOrderAssignment = Constants.OptionOfMaterialAssignmentWhenTransferringToProduction.Get()
		<> Enums.OptionsOfMaterialAssignmentWhenTransferringToProduction.AssignmentRecipient;
	
	If ProductionManagement2_2 Then
		ShopFloorStockroom = SettingsValueCached.GetDefaultShopPantry(Department, ShopFloorStockroom);
	EndIf;
	
	FillParameters = Documents.OrderOfMaterialsForProduction.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(ConsumptionForActivity, FillParameters);
	Priority = SettingsValueCached.GetDefaultPriority(Priority);
	
	If ProductionManagement2_2 Then
		StructureOfActions = New Structure;
		CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

Procedure FillInSelectionDocument(Val FillingData)
	
	FillPropertyValues(ThisObject, FillingData);
	
	If FillingData.Property("HeaderAttributes") Then
		FillPropertyValues(ThisObject, FillingData.HeaderAttributes);
	EndIf;
	
	If FillingData.Property("Goods") Then
		FillInProductsOnTable(FillingData.Goods);
	EndIf;
	
EndProcedure

Procedure FillInProductsOnTable(FillingData)
	
	If FillingData.Count() = 0 Then
		Return;
	EndIf;
	
	FirstRow = True;
	
	ShipmentStart = Date(1, 1, 1, 0, 0, 0);
	ReceiptEnd = Date(1, 1, 1, 0, 0, 0);
	Duration = 0;
	TotalDuration = True;
	ShipmentAndReceiptByOneDate = True;
	
	For Each FillingDataString In FillingData Do
		
		String = Goods.Add();
		FillPropertyValues(String, FillingDataString);
		
		If FirstRow Then
			
			FirstRow = False;
			
			ShipmentStart = BegOfDay(String.ShipmentStart);
			ReceiptEnd = BegOfDay(String.ReceiptEnd);
			Duration = Int((ReceiptEnd - ShipmentStart) / 86400);
			TotalDuration = True;
			ShipmentAndReceiptByOneDate = (ShipmentStart = ReceiptEnd);
			
		Else
			
			If ShipmentAndReceiptByOneDate
				And (BegOfDay(String.ShipmentStart) <> BegOfDay(String.ReceiptEnd)) Then
				
				ShipmentAndReceiptByOneDate = False;
				
			EndIf;
			
			If TotalDuration
				And Duration <> Int((BegOfDay(String.ReceiptEnd) - BegOfDay(String.ShipmentStart)) / 86400) Then
				
				TotalDuration = False;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	UseTransferDuration = Not ShipmentAndReceiptByOneDate;
	If UseTransferDuration And TotalDuration Then
		TransferDurationDays = Duration;
	Else
		TransferDurationDays = 0;
	EndIf;
	
EndProcedure

Procedure CheckHeaderDetails_(Cancel)
	
	If ProductionManagement2_2 Then
		
		If Warehouse = ShopFloorStockroom And ValueIsFilled(Warehouse) Then
			
			MessageText = NStr("vi = 'Kho bãi và kho ở xưởng nên khác nhau';
								|ru = 'Склад и цеховая кладовая должны быть разными';
								|en = 'Warehouse and shop floor stockroom must be different'; fa = 'Warehouse and shop floor stockroom must be different';
								|it = 'Il magazzino e il deposito del reparto devono differire';
								|pl = 'Magazyn i magazyn spiżarni powinni różnić się';
								|tr = 'Ambar ve atölye deposu farklı olmalıdır'");
			Common.MessageToUser(MessageText, ThisObject, "Warehouse",, Cancel); 
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf
