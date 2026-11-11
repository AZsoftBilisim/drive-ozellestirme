#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Sets the status for the document object
//
// Parameters:
//	NewStatus - String - Name of the status that will be set for orders
//	AdditionalParameters - Structure - Structure of additional parameters for setting the status
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
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.TransferOrder);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
	Return CheckFilling();
	
EndFunction

// Corrects lines for which no movement or warehouse orders were issued, or there are discrepancies for measured
// items.
//
// Parameters:
// 		ParametersStructure - Structure - Structure of adjustment parameters, constructor: order Server.Structurecorrectionslist of orders().
//
// Returns:
// 		Structure
// 		* Number of rows - the Number of canceled / adjusted rows.
//
Function AdjustOrderLines(ParametersStructure) Export
	
	If Not ParametersStructure.CancelUnprocessedLines And Not ParametersStructure.CorrectMeasuringGoods Then
		Return OrdersServer.ResultOfUndoingUnprocessedRows(Undefined)
	EndIf;
	
	NumberOfAdjustedRows = 0;
	
	If Not ParametersStructure.CheckBalance Then
		
		PropertiesOfCanceledRow = New Structure("Canceled, BatchesIndicationStatus", True, 0);
		
		For Each LineProducts_ In Goods Do
			If Not LineProducts_.Canceled Then
				
				FillPropertyValues(LineProducts_, PropertiesOfCanceledRow);
				NumberOfAdjustedRows = NumberOfAdjustedRows + 1;
				
			EndIf;
		EndDo;
		
		Return OrdersServer.ResultOfUndoingUnprocessedRows(NumberOfAdjustedRows);
	EndIf;
	
	FillParameters = OrdersServer.FillOptionsForCancelingRows();
	FillParameters.RegisterManager  = AccumulationRegisters.TransferOrders;
	FillParameters.TabularSectionName = "Goods";
	FillParameters.DataPaths.Insert("Warehouse", "SourceWarehouse");
	If AssignByOrderAssignment Then
		FillParameters.ReplacementTable = Goods.Unload(,"LineNumber, Purpose");
		Catalogs.Assignments.FillInSecurityAssignment(FillParameters.ReplacementTable, Purpose, "Purpose");
	EndIf;
	
	CancellationOptions = OrdersServer.OptionsForCancelingOrderLines();
	CancellationOptions.CancelOnlyMeasuredGoods = Not ParametersStructure.CancelUnprocessedLines
		And ParametersStructure.CorrectMeasuringGoods;
	CancellationOptions.CorrectMeasuringGoods = ParametersStructure.CorrectMeasuringGoods;
	
	CancellationResult = OrdersServer.UndoUnprocessedShippingLines(ThisObject, FillParameters, CancellationOptions);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.TransferOrder));
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
	Return CancellationResult;
	
EndFunction

#EndRegion

#Region EventHandlers

// Parameters:
//  FillingData - Structure - data for filling out the document:
//    * Goods - ValueTable - the table to use for filling in the table part of the document.
//    * StandardProcessing - Boolean - You need to set false if you don't need to perform standard event processing.
Procedure Filling(FillingData, StandardProcessing)
	
	If Not GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
		BusinessOperation = Enums.BusinessTransactions.InventoryTransfer;
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure") And FillingData.Property("Basis") Then
		
		If TypeOf(FillingData.Basis) = Type("DocumentRef.SalesOrder") Then
			FillInOnTheCustomerSOrder(FillingData);
		ElsIf TypeOf(FillingData.Basis) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
			FillInRequestForReturnOfGoodsFromClient(FillingData);
		ElsIf TypeOf(FillingData.Basis) = Type("DocumentRef.InventoryConsumptionOrder") Then
			FillOnOrderForDomesticConsumption(FillingData);
		ElsIf TypeOf(FillingData.Basis) = Type("DocumentRef.ByAssemblyDisassemblyOrder") Then
			FillInByOrderForAssembly(FillingData);
		ElsIf TypeOf(FillingData.Basis) = Type("DocumentRef.OrderOfMaterialsForProduction") Then
			FillInOrderOfMaterialsInProduction(FillingData);
		ElsIf TypeOf(FillingData.Basis) = Type("DocumentRef.VendorInvoice") Then
			
			InstructionsForPurchasingGoods(FillingData);
		ElsIf TypeOf(FillingData.Basis) = Type("DocumentRef.ProductionStage2_2") Then
			FillInByProductionStage2_2(FillingData);
		ElsIf TypeOf(FillingData.Basis) = Type("DocumentRef.GoodsReceiptForStorage") Then
			
			InstructionsForAcceptanceOfGoodsForStorage(FillingData);
			
		Else
			Raise NStr("vi = 'Tùy chọn tạo chứng từ không hợp lệ trên cơ sở';
						|ru = 'Неверные параметры создания документа на основании';
						|en = 'Incorrect document generation parameters'; fa = 'Incorrect document generation parameters';
						|it = 'I parametri della creazione del documento in base alla causale sono scorretti';
						|pl = 'Nieprawidłowe parametry utworzenia dokumentu na podstawie';
						|tr = 'Dayalı bir belge oluşturmak için yanlış parametreler'");
		EndIf;
		
	ElsIf TypeOf(FillingData) = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ApplicationForCollateral") Then
		FillInDocumentBasedOnSupplyRequest(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ReceiptOfGoodsToWarehouse") Then
		InformationOnReceiptOfGoods(FillingData);
	EndIf;
	
	ThereIsProvisionOption = TypeOf(FillingData) = Type("DocumentRef.VendorInvoice")
		Or TypeOf(FillingData) = Type("Structure")
			And FillingData.Property("Goods")
			And TypeOf(FillingData.Goods) = Type("ValueTable")
			And FillingData.Goods.Columns.Find("SupplyOption") <> Undefined;
	
	InitializeDocument(FillingData, Not ThereIsProvisionOption);
	
	TransferOrderLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	
	Documents.TransferOrder.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation, 
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
	
	NotCheckedAttributeArray = New Array;
	If Not LockedGoodsTransfer Then
		NotCheckedAttributeArray.Add("ControlledLotOfTheSender");
	EndIf;
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	// The recipient warehouse and the sender warehouse should be different
	If ValueIsFilled(SourceWarehouse) And SourceWarehouse = DestinationWarehouse Then
		
		Common.MessageToUser(
			NStr("vi = 'Một kho không thể vừa là nơi gửi vừa là nơi nhận. Hãy thay đổi một trong các kho.';
				|ru = 'Один склад не может быть как отправителем, так и получателем. Измените один из складов.';
				|en = 'The same warehouse cannot be both shipping and receiving. Change one of the warehouses.'; fa = 'The same warehouse cannot be both shipping and receiving. Change one of the warehouses.';
				|it = 'Un magazzino non può essere sia mittente che destinatario. Modificare uno dei magazzini.';
				|pl = 'Jeden magazyn nie może być zarówno nadawcą, jak i odbiorcą. Zmień jeden z magazynów.';
				|tr = 'Bir ambar hem gönderici hem de alıcı olamaz. Ambarlardan birini değiştir.'"),
			ThisObject,
			"SourceWarehouse",
			,
			Cancel);
		
	EndIf;
	
	// The desired date of receipt in the header must be at least the date of the document
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
	
	// The receiving organization must be interconnected with the sending organization by organizational structure.
	If BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices
		And ValueIsFilled(Organization)
		And ValueIsFilled(CompanyRecipient)
		And Not Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(Organization, CompanyRecipient) Then
		
		ErrorText = NStr("vi = 'Doanh nghiệp nhận hàng phải có quan hệ với doanh nghiệp gửi hàng theo cơ cấu tổ chức.';
						|ru = 'Организация-получатель должна быть взаимосвязана с организацией-отправителем по организационной структуре.';
						|en = 'Receiving company should be connected with a shipping company by the organizational structure.'; fa = 'Receiving company should be connected with a shipping company by the organizational structure.';
						|it = 'La società-destinatario deve essere interconnessa con la società-mittente per la struttura organizzativa.';
						|pl = 'Firma odbiorca powinna być wzajemnie powiązana z firmą nadawcą według struktury organizacyjnej.';
						|tr = 'Alıcı-iş yeri, organizasyon yapısı bakımından gönderen-iş yeri ile bağlantılı olmalıdır.'");
		
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			"CompanyRecipient",
			,
			Cancel);
		
	EndIf;
	
	NotCheckedAttributeArray.Add("SourceWarehouse");
	NotCheckedAttributeArray.Add("Goods.ShipmentStart");
	NotCheckedAttributeArray.Add("Goods.ReceiptEnd");
	
	EmbeddingParameters = Documents.TransferOrder.AvailableRemainingEmbeddingOptions();
	ErrorsTable = ProvisionInDocumentsServer.TableOfFillingErrors(ThisObject, EmbeddingParameters);
	
	WarehouseSenderRequired = False;
	
	TextTemplate1 = ?(UseTransferDuration,
		NStr("vi = 'Chưa điền cột ""Bắt đầu giao hàng"" tại dòng %LineNumber% trong danh sách ""Hàng hóa""';
			|ru = 'Не заполнена колонка ""Начало отгрузки"" в строке %LineNumber% списка ""Товары""';
			|en = 'Column ""Shipment start"" in line %LineNumber% of the ""Goods"" list is not filled in'; fa = 'Column ""Shipment start"" in line %LineNumber% of the ""Goods"" list is not filled in';
			|it = 'Non è compilata la colonna ""Spedizione iniziata"" nella riga %LineNumber% dell''elenco ""Merci""';
			|pl = 'Nie wypełniono kolumny ""Data wysyłki"" w wierszu %LineNumber% listy ""Wiersze pozycji""';
			|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Sevkiyat başlangıcı"" sütunu doldurulmadı'"),
		NStr("vi = 'Chưa điền cột ""Ngày giao hàng"" tại dòng %LineNumber% trong danh sách ""Hàng hóa""';
			|ru = 'Не заполнена колонка ""Дата отгрузки"" в строке %LineNumber% списка ""Товары""';
			|en = 'Column ""Shipment date"" in line %LineNumber% of the Item list is not filled in'; fa = 'Column ""Shipment date"" in line %LineNumber% of the Item list is not filled in';
			|it = 'Non è compilata la colonna ""Data di spedizione"" nella riga %LineNumber% dell''elenco ""Merci""';
			|pl = 'Nie wypełniono kolumny ""Data wysyłki"" w wierszu %LineNumber% listy ""Товары""';
			|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Sevkiyat tarihi"" sütunu doldurulmadı'"));
		
	For CurIndex__ = 0 To ErrorsTable.Count() - 1 Do
		
		ErrorString = ErrorsTable[CurIndex__];
		
		If ErrorString.DateOfShipmentRequired_ And ErrorString.ShipmentDateNotFilledIn Then
			
			ErrorText   = StrReplace(TextTemplate1, "%LineNumber%", ErrorString.LineNumber);
			PathToTop = CommonClientServer.PathToTabularSection("Goods", ErrorString.LineNumber, "ShipmentStart");
			Common.MessageToUser(ErrorText, ThisObject, PathToTop, , Cancel);
			
		EndIf;
		
		WarehouseSenderRequired = WarehouseSenderRequired Or ErrorString.WarehouseIsRequired;
		
	EndDo;
	
	If WarehouseSenderRequired And Not ValueIsFilled(SourceWarehouse) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Kho gửi""';
						|ru = 'Поле ""Склад-отправитель"" не заполнено';
						|en = '""Origin warehouse"" is not filled in'; fa = '""Origin warehouse"" is not filled in';
						|it = 'Il campo ""Magazzino-mittente"" non è compilato';
						|pl = 'Nie wypełniono pola ""Magazyn wysyłki""';
						|tr = '""Çıkış ambarı"" alanı doldurulmadı'");
		Common.MessageToUser(ErrorText, ThisObject, "SourceWarehouse", , Cancel);
		
	EndIf;
	
	For Each TSRow In Goods Do
		
		ErrorAddress = " " + NStr("vi = 'trong dòng %LineNumber% của danh sách ""Hàng hóa""';
									|ru = 'в строке %LineNumber% списка ""Товары""';
									|en = 'in line %LineNumber% of the ""Goods"" list'; fa = 'in line %LineNumber% of the ""Goods"" list';
									|it = 'nella riga %LineNumber% dell''elenco ""Merci""';
									|pl = 'w wierszu %LineNumber% listy ""Towary""';
									|tr = '""Ürünler"" listesinin %LineNumber% satırında'");
		ErrorAddress = StrReplace(ErrorAddress,"%LineNumber%", TSRow.LineNumber);
		
		If UseTransferDuration
			And Not TSRow.Canceled
			And Not ValueIsFilled(TSRow.ReceiptEnd)
			And TSRow.SupplyOption = Enums.SupplyOptions.Ship Then
			
			ErrorText = NStr("vi = 'Chưa điền cột ""Kết thúc tiếp nhận""';
							|ru = 'Не заполнена колонка ""Окончание поступления""';
							|en = 'Column ""Receipt end"" is not filled in'; fa = 'Column ""Receipt end"" is not filled in';
							|it = 'La colonna ""Termine dell''arrivo"" non è compilata';
							|pl = 'Nie wypełniono kolumny ""Окончание поступления""';
							|tr = '""Giriş sonu"" sütunu doldurulmadı'");
			
			Common.MessageToUser(
				ErrorText + ErrorAddress,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", TSRow.LineNumber, "ReceiptEnd"),
				,
				Cancel);
			
		EndIf;
		
		If UseTransferDuration And ValueIsFilled(TSRow.ShipmentStart) And ValueIsFilled(TSRow.ReceiptEnd) And TSRow.ShipmentStart > TSRow.ReceiptEnd Then
			
			ErrorText = NStr("vi = 'Ngày kết thúc tiếp nhận nhỏ hơn ngày bắt đầu giao hàng';
							|ru = 'Дата окончания поступления меньше даты начала отгрузки';
							|en = 'Receipt end date is less than the shipment start date'; fa = 'Receipt end date is less than the shipment start date';
							|it = 'La data del termine di arrivo è inferiore alla data dell''inizio di spedizione';
							|pl = 'Data zakończenia wpłaty jest mniejsza niż data początku wysyki';
							|tr = 'Giriş bitiş tarihi, sevkiyatın başlama tarihinden daha az'");
			
			Common.MessageToUser(
				ErrorText + ErrorAddress,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", TSRow.LineNumber, "ReceiptEnd"),
				,
				Cancel);
			
		EndIf;
		
		If ValueIsFilled(TSRow.ShipmentStart) And TSRow.ShipmentStart < BegOfDay(Date) Then
			
			ErrorText = NStr("vi = 'Ngày bắt đầu giao hàng không được nhỏ hơn ngày chứng từ ""%Date%""';
							|ru = 'Дата начала отгрузки должна быть не меньше даты документа ""%Date%""';
							|en = 'Shipment start date cannot be less than document date ""%Date%""'; fa = 'Shipment start date cannot be less than document date ""%Date%""';
							|it = 'La data dell''inizio di spedizione non deve essere inferiore alla data del documento ""%Date%""';
							|pl = 'Data początku wysyłki powinna być nie mniejsza niż data dokumentu ""%Date%""';
							|tr = 'Sevkiyatın başlangıç ​​tarihi en az belgenin tarihi olmalıdır ""%Date%""'");
			ErrorText = StrReplace(ErrorText,"%Date%", Format(Date, "DLF=DD"));
			
			Common.MessageToUser(
				ErrorText + ErrorAddress,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", TSRow.LineNumber, "ShipmentStart"),
				,
				Cancel);
			
		EndIf;
		
		If UseTransferDuration And ValueIsFilled(TSRow.ReceiptEnd) And TSRow.ReceiptEnd < BegOfDay(Date) Then
			
			ErrorText = NStr("vi = 'Ngày kết thúc tiếp nhận không được nhỏ hơn ngày chứng từ ""%Date%""';
							|ru = 'Дата окончания поступления должна быть не меньше даты документа ""%Date%""';
							|en = 'Receipt end date should not be less than document date ""%Date%""'; fa = 'Receipt end date should not be less than document date ""%Date%""';
							|it = 'La data del termine di arrivo non deve essere inferiore alla data del documento %Date%';
							|pl = 'Data zakończenia wpłaty powinna być nie mniejsza niż data dokumentu ""%Date%""';
							|tr = 'Giriş bitiş tarihi en az ""%Date%"" belgenin tarihi olmalıdır.'");
			ErrorText = StrReplace(ErrorText,"%Date%", Format(Date, "DLF=DD"));
			
			Common.MessageToUser(
				ErrorText + ErrorAddress,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", TSRow.LineNumber, "ReceiptEnd"),
				,
				Cancel);
			
		EndIf;
		
	EndDo;
	
	GoodsDelivery.CheckDeliveryDetails(ThisObject, NotCheckedAttributeArray, Cancel);
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	ProductsServer.CheckSeriesCompletion(
		ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.TransferOrder),
		Cancel,
		NotCheckedAttributeArray);
	
	CheckParameters = VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity();
	CheckParameters.TabularSectionName = "Goods";
	VATAccountingERP.CheckCompletionOfDocumentByTypeOfVATActivity(
		ThisObject, 
		TransferForActivity, 
		CheckParameters, 
		Cancel);
	
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		ArrayOfAllProps,
		ArrayOfOperationDetails,
		NotCheckedAttributeArray);
	
	If LockedGoodsTransfer Then
		
		QualityControl.ProcessingVerificationOfFillingInSurplusDocument(
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
			".ReceiptEnd");
			
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
			".ReceiptEnd");
			
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	TransferOrderLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	OrdersServer.SetKeyInRowsOfTablePart(ThisObject, "Goods");
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	ProductsServer.ClearUnusedSeries(
		ThisObject,
		ProductsServer.SeriesSpecificationParameters(
			ThisObject,
			Documents.TransferOrder));
	
	// We will clear the details of the document that are not used for the business operation.
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	Documents.TransferOrder.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	CashServer.ClearUnusedProps(
		ThisObject,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	DestinationPattern = Documents.TransferOrder.DestinationPattern(ThisObject);
	DestinationDegeneration = Catalogs.Assignments.CheckFillBeforeRecording(Purpose, DestinationPattern,
		ThisObject, "LineOfBusiness", Cancel);
	
	If DestinationDegeneration Then
		AssignByOrderAssignment = Constants.OptionOfGoodslAssignmentInTransfer.Get()
			<> Enums.OptionsOfGoodslAssignmentInTransfer.AssignmentRecipient;
	EndIf;
	
	TransferOrderLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	DestinationPattern = Documents.TransferOrder.DestinationPattern(ThisObject);
	Catalogs.Assignments.OnWriteDocument(Purpose, DestinationPattern, ThisObject, DestinationWarehouse, TransferForActivity);
	
	TransferOrderLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentBasis       = Undefined;
	RequestedDeliveryDate = Date(1, 1, 1);
	If GetFunctionalOption("UseStatusesOfTransferOrders") Then
		Status = Metadata().Attributes.Status.FillValue;
	Else
		Status = Enums.InternalOrderStatuses.Closed;
	EndIf;
	MaximumRowCode   = 0;
	Purpose              = Catalogs.Assignments.EmptyRef();
	ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.EmptyRef();
	
	For Each LineProducts_ In Goods Do
	
		LineProducts_.ShipmentStart = Date(1, 1, 1);
		LineProducts_.ReceiptEnd = Date(1, 1, 1);
		LineProducts_.Canceled             = False;
		LineProducts_.RowCode            = 0;
		LineProducts_.Purpose = Catalogs.Assignments.EmptyRef();
		
	EndDo;
	
	InitializeDocument();
	
	TransferOrderLocalization.OnCopy(ThisObject, CopiedObject);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel);
	
	PerformOrderControlAfterConducting(Cancel);
	
	TransferOrderLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel, True);
	TransferOrderLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined, FillingOutCollateralOption = True)

	Author = Users.CurrentUser();
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	If Not LockedGoodsTransfer Then
		ControlledLotOfTheSender = Catalogs.ControlledLots.EmptyRef();
	EndIf;
	If Not GetFunctionalOption("UseStatusesOfTransferOrders") Then
		
		Status = Enums.InternalOrderStatuses.Closed;
		
	Else
	
		Status = Enums.InternalOrderStatuses.ForCompletion;
		
	EndIf;
	
	If FillingOutCollateralOption Then
		
		StructureOfActions = New Structure();
		DocumentParameters = Documents.TransferOrder.DocumentParametersForSoftwareActions(ThisObject);
		StringFields_ = "SupplyOption";
		ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters);
		BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, Undefined);
		
	EndIf;
	
	AssignByOrderAssignment = Constants.OptionOfGoodslAssignmentInTransfer.Get()
		<> Enums.OptionsOfGoodslAssignmentInTransfer.AssignmentRecipient;
	
	GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption();
	Priority = SettingsValueCached.GetDefaultPriority(Priority);
	
	WarehouseValue_ = DestinationWarehouse;
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	// When creating from a common domain.The creation of the basis and the definition of the assignable quantity may deliberately be empty
	// if data is transferred to the document for several warehouses. Filling in statistics can fill in this empty value,
	// you need to clear it
	If TypeOf(FillingData) = Type("Structure") And FillingData.Property("Basis") Then
		DestinationWarehouse = WarehouseValue_;
	EndIf;

	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
	Documents.TransferOrder.CheckAndClearOrganization(ThisObject, CompanyRecipient);
	Documents.TransferOrder.CheckAndClearOrganization(ThisObject, Organization);
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Organization = Organization;
	FillParameters.Date = ?(ValueIsFilled(Date), Date, CurrentSessionDate());
	FillParameters.Warehouse = DestinationWarehouse;
	FillParameters.MovementOfGoodsInWarehouses = True;
	VATAccountingERP.FillInTypeOfActivityVAT(TransferForActivity, FillParameters);
	
EndProcedure

Procedure FillInSelectionDocument(Val FillingData)
	
	FillPropertyValues(ThisObject, FillingData);
	
	If FillingData.Property("Goods") Then
		FillInProductsOnTable(FillingData.Goods);
	EndIf;
	
EndProcedure

Procedure FillInRequestForReturnOfGoodsFromClient(FillingData)
	
	ReturnRequest = FillingData.Basis;
	Query = New Query(
		"SELECT
		|	SalesOrder.Priority AS Priority,
		|	SalesOrder.Organization AS Organization,
		|	CASE
		|		WHEN SalesOrder.SalesOpportunity.EnabledGoodsAssignmentInSalesOpportunity
		|			THEN SalesOrder.SalesOpportunity
		|	END AS SalesOpportunity,
		|	SalesOrder.Department AS Department,
		|	SalesOrder.LineOfBusiness AS LineOfBusiness
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS SalesOrder
		|WHERE
		|	SalesOrder.Ref = &ReturnRequest");
	
	Query.SetParameter("ReturnRequest", ReturnRequest);
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	// Filling in the header
	Organization             = Attributes.Organization;
	Priority               = Attributes.Priority;
	SalesOpportunity                  = Attributes.SalesOpportunity;
	DocumentBasis       = ReturnRequest;
	Department           = Attributes.Department;
	LineOfBusiness = Attributes.LineOfBusiness;
	
	DestinationWarehouse = FillingData.Warehouse;
	
	// Filling in the tabular part.
	Goods.Load(GetFromTempStorage(FillingData.AddressGoods));
	DeleteFromTempStorage(FillingData.AddressGoods);
	
EndProcedure

Procedure FillInOnTheCustomerSOrder(FillingData)
	
	SalesOrder = FillingData.Basis;
	Query = New Query(
		"SELECT
		|	SalesOrder.Priority AS Priority,
		|	SalesOrder.Organization AS Organization,
		|	CASE
		|		WHEN SalesOrder.SalesOpportunity.EnabledGoodsAssignmentInSalesOpportunity
		|			THEN SalesOrder.SalesOpportunity
		|	END AS SalesOpportunity,
		|	SalesOrder.Department AS Department,
		|	SalesOrder.LineOfBusiness AS LineOfBusiness
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|WHERE
		|	SalesOrder.Ref = &SalesOrder");
	
	Query.SetParameter("SalesOrder", SalesOrder);
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	// Filling in the header
	Organization             = Attributes.Organization;
	Priority               = Attributes.Priority;
	SalesOpportunity                  = Attributes.SalesOpportunity;
	DocumentBasis       = SalesOrder;
	Department           = Attributes.Department;
	LineOfBusiness = Attributes.LineOfBusiness;
	
	DestinationWarehouse = FillingData.Warehouse;
	
	// Filling in the tabular part.
	Goods.Load(GetFromTempStorage(FillingData.AddressGoods));
	DeleteFromTempStorage(FillingData.AddressGoods);
	
EndProcedure

Procedure FillOnOrderForDomesticConsumption(FillingData)
	
	ConsumptionOrder = FillingData.Basis;
	Query = New Query(
		"SELECT
		|	OrderDocument.Priority AS Priority,
		|	OrderDocument.Organization AS Organization,
		|	OrderDocument.SalesOpportunity AS SalesOpportunity,
		|	OrderDocument.Department AS Department,
		|	OrderDocument.LineOfBusiness AS LineOfBusiness
		|FROM
		|	Document.InventoryConsumptionOrder AS OrderDocument
		|WHERE
		|	OrderDocument.Ref = &ConsumptionOrder");
	
	Query.SetParameter("ConsumptionOrder", ConsumptionOrder);
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	// Filling in the header
	Organization             = Attributes.Organization;
	Priority               = Attributes.Priority;
	SalesOpportunity                  = Attributes.SalesOpportunity;
	DocumentBasis       = ConsumptionOrder;
	Department           = Attributes.Department;
	LineOfBusiness = Attributes.LineOfBusiness;
	
	DestinationWarehouse = FillingData.Warehouse;
	
	// Filling in the tabular part.
	Goods.Load(GetFromTempStorage(FillingData.AddressGoods));
	DeleteFromTempStorage(FillingData.AddressGoods);
	
EndProcedure

Procedure FillInDocumentBasedOnSupplyRequest(ApplicationForCollateral)
	
	ReceivingParameters = Documents.ApplicationForCollateral.ParametersForReceivingFillInDataBasedOn();
	ReceivingParameters.ItemsType = ProductsServer.SupportedDocumentItemTypes(Ref);
	FillingData = Documents.ApplicationForCollateral.FillingDataBasedOn(
		ApplicationForCollateral,
		ReceivingParameters);
	
	// Safe filling of the header:
	HeaderProperties = New Structure;
	HeaderProperties.Insert("Organization");
	HeaderProperties.Insert("Department");
	HeaderProperties.Insert("Warehouse");
	HeaderProperties.Insert("LineOfBusiness");
	FillPropertyValues(HeaderProperties, FillingData.Header);
	FillPropertyValues(ThisObject, HeaderProperties);
	
	DocumentBasis = ApplicationForCollateral;
	DestinationWarehouse = HeaderProperties.Warehouse;
	
	// Filling PM:
	Goods.Load(FillingData.Goods);
	
EndProcedure

Procedure FillInByOrderForAssembly(FillingData)
	
	ByAssemblyDisassemblyOrder = FillingData.Basis;
	Query = New Query(
		"SELECT
		|	OrderDocument.Priority AS Priority,
		|	OrderDocument.Organization AS Organization,
		|	OrderDocument.SalesOpportunity AS SalesOpportunity,
		|	OrderDocument.Department AS Department,
		|	OrderDocument.LineOfBusiness AS LineOfBusiness
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS OrderDocument
		|WHERE
		|	OrderDocument.Ref = &ByAssemblyDisassemblyOrder");
	
	Query.SetParameter("ByAssemblyDisassemblyOrder", ByAssemblyDisassemblyOrder);
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	// Filling in the header
	Organization             = Attributes.Organization;
	SalesOpportunity                  = Attributes.SalesOpportunity;
	Priority               = Attributes.Priority;
	DocumentBasis       = ByAssemblyDisassemblyOrder;
	Department           = Attributes.Department;
	LineOfBusiness = Attributes.LineOfBusiness;
	
	DestinationWarehouse = FillingData.Warehouse;
	
	// Filling in the tabular part.
	Goods.Load(GetFromTempStorage(FillingData.AddressGoods));
	DeleteFromTempStorage(FillingData.AddressGoods);
	
EndProcedure

Procedure FillInOrderOfMaterialsInProduction(FillingData)
	
	OrderOfMaterials = FillingData.Basis;
	Query = New Query(
		"SELECT
		|	OrderDocument.Priority AS Priority,
		|	OrderDocument.Organization AS Organization,
		|	OrderDocument.Department AS Department,
		|	OrderDocument.LineOfBusiness AS LineOfBusiness
		|FROM
		|	Document.OrderOfMaterialsForProduction AS OrderDocument
		|WHERE
		|	OrderDocument.Ref = &OrderOfMaterials");
	
	Query.SetParameter("OrderOfMaterials", OrderOfMaterials);
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	// Filling in the header
	Organization             = Attributes.Organization;
	Priority               = Attributes.Priority;
	DocumentBasis       = OrderOfMaterials;
	Department           = Attributes.Department;
	LineOfBusiness = Attributes.LineOfBusiness;
	
	DestinationWarehouse = FillingData.Warehouse;
	
	// Filling in the tabular part.
	Goods.Load(GetFromTempStorage(FillingData.AddressGoods));
	DeleteFromTempStorage(FillingData.AddressGoods);
	
EndProcedure

Procedure FillInByProductionStage2_2(FillingData)
	
	Stage = FillingData.Basis;
	
	Query = New Query(
		"SELECT
		|	ProductionStage2_2.Organization AS Organization,
		|	ProductionStage2_2.Department AS Department,
		|	CASE
		|		WHEN ProductionStage2_2.LineOfBusiness.CostAccounting
		|			THEN ProductionStage2_2.LineOfBusiness
		|	END AS LineOfBusiness
		|FROM
		|	Document.ProductionStage2_2 AS ProductionStage2_2
		|WHERE
		|	ProductionStage2_2.Ref = &Stage");
	
	Query.SetParameter("Stage", Stage);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	DocumentBasis       = Stage;
	Organization             = Selection.Organization;
	Department           = Selection.Department;
	LineOfBusiness = Selection.LineOfBusiness;
	
	DestinationWarehouse = FillingData.Warehouse;
	
	// Filling in the tabular part.
	Goods.Load(GetFromTempStorage(FillingData.AddressGoods));
	DeleteFromTempStorage(FillingData.AddressGoods);
	
EndProcedure

Procedure InstructionsForPurchasingGoods(FillingData)
	
	QueryText = 
	"SELECT
	|	Header.Ref                  AS Ref,
	|	Header.Organization             AS Organization,
	|	Header.SalesOpportunity                  AS SalesOpportunity,
	|	Header.Warehouse                   AS SourceWarehouse,
	|	Header.LineOfBusiness AS LineOfBusiness,
	|	NOT Header.Posted             AS ThereAreErrorsPosted
	|FROM
	|	Document.VendorInvoice AS Header
	|WHERE
	|	Header.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////
	|SELECT
	|	Goods.Products        AS Products,
	|	Goods.Characteristic      AS Characteristic,
	|	Goods.Purpose          AS Purpose,
	|	Goods.Warehouse               AS Warehouse,
	|	Goods.Series               AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.Count          AS Count,
	|	Goods.NumberOfPackages  AS NumberOfPackages,
	|	Goods.Package            AS Package,
	|	
	|	VALUE(Enum.SupplyOptions.Ship) AS SupplyOption,
	|	CASE
	|		WHEN Goods.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS WithAssignment
	|
	|FROM
	|	Document.VendorInvoice.Goods AS Goods
	|WHERE
	|	Goods.Ref = &DocumentBasis
	|	AND Goods.Products.ItemsType IN(
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND Goods.Warehouse = &Warehouse
	|	AND NOT Goods.ToExpenseAs
	|;
	|
	|////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products   AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.Purpose     AS Purpose,
	|	SetOfSeries.Warehouse          AS Warehouse,
	|	SetOfSeries.Series          AS Series,
	|	SetOfSeries.Count     AS Count
	|FROM
	|	Document.VendorInvoice.SetOfSeries AS SetOfSeries
	|WHERE
	|	SetOfSeries.Ref = &DocumentBasis
	|	AND SetOfSeries.Warehouse = &Warehouse";
	
	Query       = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("DocumentBasis", FillingData.Basis);
	Query.SetParameter("Warehouse",             FillingData.Warehouse);
	
	ResultsPackage = Query.ExecuteBatch();
	BaseGoods  = ResultsPackage[1].Unload();
	
	If BaseGoods.Count() = 0 Then
		ErrorText = NStr("vi = 'Chứng từ %Document% không có hàng hóa. Cấm nhập trên cơ sở chứng từ này.';
						|ru = 'Документ %Document% не содержит товаров. Ввод на основании документа запрещен.';
						|en = 'Document %Document% does not have any goods. Generation from such base documents is not allowed.'; fa = 'Document %Document% does not have any goods. Generation from such base documents is not allowed.';
						|it = 'Il documento %Document% non contiene merci. L''immissione in base al documento non è consentita.';
						|pl = 'Dokument %Document% nie zawiera towarów. Wprowadzenie na podstawie dokumentu jest zakazane.';
						|tr = '%Document% belgesi hiçbir ürün içermemektedir. Belgeye dayalı giriş yapılmasına izin verilmez.'");
		ErrorText = StrReplace(ErrorText, "%Document%", FillingData.Basis);
		
		Raise ErrorText;
	EndIf;
	
	Header = ResultsPackage[0].Select();
	Header.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(Header.Ref, Undefined, Header.ThereAreErrorsPosted);
	
	// Filling in the header.
	FillPropertyValues(ThisObject, Header);
	DocumentBasis = FillingData.Basis;
	SourceWarehouse  = FillingData.Warehouse;
	
	// Splitting lines, filling in series with status 10.
	RowIndexes    = New Array();
	
	For Each LineProducts_ In BaseGoods Do
		If LineProducts_.BatchesIndicationStatus = 10 Then
			RowIndexes.Insert(0, BaseGoods.IndexOf(LineProducts_));
		EndIf;
	EndDo;
	
	If RowIndexes.Count() > 0 Then
		BaseSeries = ResultsPackage[2].Unload();
		SeriesKey      = "Products, Characteristic, Warehouse, Purpose";
		
		InvoicesServer.MoveSeriesFromTableToRows(BaseGoods, RowIndexes, BaseSeries, SeriesKey);
	EndIf;
	
	Goods.Load(BaseGoods);
	
	// Filling in the series indication statuses
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.TransferOrder);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
EndProcedure

Procedure InstructionsForAcceptanceOfGoodsForStorage(FillingData)
	
	QueryText = 
	"SELECT
	|	Header.Ref                  AS Ref,
	|	Header.Organization             AS Organization,
	|	Header.SalesOpportunity                  AS SalesOpportunity,
	|	Header.Warehouse                   AS SourceWarehouse,
	|	Header.LineOfBusiness AS LineOfBusiness,
	|	NOT Header.Posted             AS ThereAreErrorsPosted
	|FROM
	|	Document.GoodsReceiptForStorage AS Header
	|WHERE
	|	Header.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////
	|SELECT
	|	Goods.Products        AS Products,
	|	Goods.Characteristic      AS Characteristic,
	|	Goods.Purpose          AS Purpose,
	|	Goods.Warehouse               AS Warehouse,
	|	Goods.Series               AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.Count          AS Count,
	|	Goods.NumberOfPackages  AS NumberOfPackages,
	|	Goods.Package            AS Package,
	|	
	|	VALUE(Enum.SupplyOptions.Ship) AS SupplyOption,
	|	CASE
	|		WHEN Goods.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS WithAssignment
	|
	|FROM
	|	Document.GoodsReceiptForStorage.Goods AS Goods
	|WHERE
	|	Goods.Ref = &DocumentBasis
	|	AND Goods.Products.ItemsType IN(
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND Goods.Warehouse = &Warehouse
	|;
	|
	|////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products   AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.Purpose     AS Purpose,
	|	SetOfSeries.Warehouse          AS Warehouse,
	|	SetOfSeries.Series          AS Series,
	|	SetOfSeries.Count     AS Count
	|FROM
	|	Document.GoodsReceiptForStorage.SetOfSeries AS SetOfSeries
	|WHERE
	|	SetOfSeries.Ref = &DocumentBasis
	|	AND SetOfSeries.Warehouse = &Warehouse";
	
	Query       = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("DocumentBasis", FillingData.Basis);
	Query.SetParameter("Warehouse",             FillingData.Warehouse);
	
	ResultsPackage = Query.ExecuteBatch();
	BaseGoods  = ResultsPackage[1].Unload();
	
	If BaseGoods.Count() = 0 Then
		ErrorText = NStr("vi = 'Chứng từ %Document% không có hàng hóa. Cấm nhập trên cơ sở chứng từ này.';
						|ru = 'Документ %Document% не содержит товаров. Ввод на основании документа запрещен.';
						|en = 'Document %Document% does not have any goods. Generation from such base documents is not allowed.'; fa = 'Document %Document% does not have any goods. Generation from such base documents is not allowed.';
						|it = 'Il documento %Document% non contiene merci. L''immissione in base al documento non è consentita.';
						|pl = 'Dokument %Document% nie zawiera towarów. Wprowadzenie na podstawie dokumentu jest zakazane.';
						|tr = '%Document% belgesi hiçbir ürün içermemektedir. Belgeye dayalı giriş yapılmasına izin verilmez.'");
		ErrorText = StrReplace(ErrorText, "%Document%", FillingData.Basis);
		
		Raise ErrorText;
	EndIf;
	
	Header = ResultsPackage[0].Select();
	Header.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(Header.Ref, Undefined, Header.ThereAreErrorsPosted);
	
	// Filling in the header.
	FillPropertyValues(ThisObject, Header);
	DocumentBasis = FillingData.Basis;
	SourceWarehouse  = FillingData.Warehouse;
	
	// Splitting lines, filling in series with status 10.
	RowIndexes    = New Array();
	
	For Each LineProducts_ In BaseGoods Do
		If LineProducts_.BatchesIndicationStatus = 10 Then
			RowIndexes.Insert(0, BaseGoods.IndexOf(LineProducts_));
		EndIf;
	EndDo;
	
	If RowIndexes.Count() > 0 Then
		BaseSeries = ResultsPackage[2].Unload();
		SeriesKey      = "Products, Characteristic, Warehouse, Purpose";
		
		InvoicesServer.MoveSeriesFromTableToRows(BaseGoods, RowIndexes, BaseSeries, SeriesKey);
	EndIf;
	
	Goods.Load(BaseGoods);
	
	// Filling in the series indication statuses
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.TransferOrder);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
EndProcedure

Procedure InformationOnReceiptOfGoods(DocumentInflow)
	
	QueryText =
	"SELECT
	|	Header.Ref                  AS Ref,
	|	Header.Organization             AS Organization,
	|	Header.SalesOpportunity                  AS SalesOpportunity,
	|	Header.Warehouse                   AS SourceWarehouse,
	|	Header.Department           AS Department,
	|	Header.LineOfBusiness AS LineOfBusiness,
	|	NOT Header.Posted             AS ThereAreErrorsPosted
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse AS Header
	|WHERE
	|	Header.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Purpose AS Purpose,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.Count AS Count,
	|	Goods.NumberOfPackages AS NumberOfPackages,
	|	Goods.Package AS Package,
	|	VALUE(Enum.SupplyOptions.Ship) AS SupplyOption,
	|	CASE
	|		WHEN Goods.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS WithAssignment
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.Goods AS Goods
	|WHERE
	|	Goods.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.Purpose AS Purpose,
	|	SetOfSeries.Series AS Series,
	|	SetOfSeries.Count AS Count
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.SetOfSeries AS SetOfSeries
	|WHERE
	|	SetOfSeries.Ref = &DocumentBasis";
	
	Query = New Query(QueryText);
	Query.SetParameter("DocumentBasis", DocumentInflow);
	ResultsPackage = Query.ExecuteBatch();
	
	BaseGoods = ResultsPackage[1].Unload();
	If BaseGoods.Count() = 0 Then

		ErrorText = NStr("vi = 'Chứng từ %Document% không có hàng hóa. Cấm nhập trên cơ sở chứng từ này.';
						|ru = 'Документ %Document% не содержит товаров. Ввод на основании документа запрещен.';
						|en = 'Document %Document% does not have any goods. Generation from such base documents is not allowed.'; fa = 'Document %Document% does not have any goods. Generation from such base documents is not allowed.';
						|it = 'Il documento %Document% non contiene merci. L''immissione in base al documento non è consentita.';
						|pl = 'Dokument %Document% nie zawiera towarów. Wprowadzenie na podstawie dokumentu jest zakazane.';
						|tr = '%Document% belgesi hiçbir ürün içermemektedir. Belgeye dayalı giriş yapılmasına izin verilmez.'");
		ErrorText = StrReplace(ErrorText, "%Document%", DocumentInflow);
	
		Raise ErrorText;
		
	EndIf;
	
	Header = ResultsPackage[0].Select();
	Header.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Header.Ref,
		,
		Header.ThereAreErrorsPosted,);
	
	// Filling in the header.
	FillPropertyValues(ThisObject, Header);
	DocumentBasis = DocumentInflow;
	
	// Splitting lines, filling in series with status 10.
	RowIndexes = New Array();
	For Each LineProducts_ In BaseGoods Do
		
		If LineProducts_.BatchesIndicationStatus = 10 Then
			RowIndexes.Insert(0, BaseGoods.IndexOf(LineProducts_));
		EndIf;
		
	EndDo;
	
	If RowIndexes.Count() > 0 Then
		
		BaseSeries = ResultsPackage[2].Unload();
		SeriesKey = "Products, Characteristic, Warehouse, Purpose";
		InvoicesServer.MoveSeriesFromTableToRows(BaseGoods, RowIndexes, BaseSeries, SeriesKey);
		
	EndIf;
	
	// Filling in the tabular part of the goods.
	Goods.Load(BaseGoods);
	
	SourceWarehouse = Common.ObjectAttributeValue(DocumentInflow, "Warehouse");

	// Filling in the series indication statuses
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.TransferOrder);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
EndProcedure

#EndRegion

#Region Other

Procedure FillInProductsOnTable(FillingData)
	
	If FillingData.Count() = 0 Then
		Return;
	EndIf;
	
	ShipmentStart = BegOfDay(FillingData[0].ShipmentStart);
	ReceiptEnd = BegOfDay(FillingData[0].ReceiptEnd);
	Duration = Int((ReceiptEnd - ShipmentStart) / 86400);
	TotalDuration = True;
	ShipmentAndReceiptByOneDate = (ShipmentStart = ReceiptEnd);
	
	For Each FillingDataString In FillingData Do
		
		String = Goods.Add();
		FillPropertyValues(String, FillingDataString);
		
		If ShipmentAndReceiptByOneDate
			And (BegOfDay(String.ShipmentStart) <> BegOfDay(String.ReceiptEnd)) Then
			
			ShipmentAndReceiptByOneDate = False;
			
		EndIf;
		
		If TotalDuration
			And Duration <> Int((BegOfDay(String.ReceiptEnd) - BegOfDay(String.ShipmentStart)) / 86400) Then
			
			TotalDuration = False;
			
		EndIf;
		
	EndDo;
	
	UseTransferDuration = Not ShipmentAndReceiptByOneDate;
	If UseTransferDuration And TotalDuration Then
		TransferDurationDays = Duration;
	Else
		TransferDurationDays = 0;
	EndIf;
	
EndProcedure

// Checks whether the document can be held in the "Closed" status.
//
// Parameters:
//  Cancel	 - Boolean - the "Failure" parameter for processing data.
//
Procedure PerformOrderControlAfterConducting(Cancel)

	MonitorShipment = GetFunctionalOption("DoNotCloseTransferOrdersWithoutCompleteShipment");
	
	If Status = Enums.InternalOrderStatuses.Closed
		And MonitorShipment Then
		Array = CommonClientServer.ValueInArray(Ref);
		AdditionalParameters = New Structure("OrderFulfillmentControl", True);
		
		Query = Documents.TransferOrder.GenerateVerificationRequestWhenStatusChanges(Array, "Closed", AdditionalParameters);
		
		Result = Query.Execute();
		
		SampleShipment = Result.Select();
		
		While SampleShipment.Next() Do
			
			CheckPassed = Documents.TransferOrder.CheckingBeforeChangingStatus(SampleShipment, Status, AdditionalParameters);
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
