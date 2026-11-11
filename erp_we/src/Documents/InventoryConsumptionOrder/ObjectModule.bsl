#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Sets the status for the document object
//
// Parameters:
//	NewStatus - String - Name of the status that will be set for orders
//	AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//										Structure constructor: Order a server.Structurecorrectionslist of orders().
//
// Returns:
//	Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.InternalOrderStatuses[NewStatus];
	
	If MeaningOfNewStatus = Enums.InternalOrderStatuses.AwaitingApproval Then
		
		If Approved Then
			Approved = False;
		EndIf;
		
	EndIf;
	
	If AdditionalParameters <> Undefined Then
		
		OrdersServer.AdjustOrderLines(ThisObject, AdditionalParameters);
		
	EndIf;
	
	Status = MeaningOfNewStatus;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventoryConsumptionOrder);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
	Return CheckFilling();
	
EndFunction

// Corrects lines for which no write-off or shipment was issued, or there are discrepancies for measured items.
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
	FillParameters.RegisterManager  = AccumulationRegisters.InventoryConsumptionOrders;
	FillParameters.TabularSectionName = "Goods";
	FillParameters.DataPaths.Insert("Warehouse", "Warehouse");
	FillParameters.DataPaths.Insert("Purpose", "Purpose");
	
	CancellationOptions = OrdersServer.OptionsForCancelingOrderLines();
	CancellationOptions.CancelOnlyMeasuredGoods = Not ParametersStructure.CancelUnprocessedLines
		And ParametersStructure.CorrectMeasuringGoods;
	CancellationOptions.CorrectMeasuringGoods = ParametersStructure.CorrectMeasuringGoods;
	
	CancellationResult = OrdersServer.UndoUnprocessedShippingLines(ThisObject, FillParameters, CancellationOptions);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventoryConsumptionOrder));
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
	Return CancellationResult;
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") And FillingData.Property("Goods") Then
		
		If FillingData.Property("HeaderAttributes") Then
			FillPropertyValues(ThisObject, FillingData.HeaderAttributes);
		EndIf;
		
		For Each CollectionItem In FillingData.Goods Do
			RowData = Goods.Add();
			FillPropertyValues(RowData, CollectionItem);
		EndDo;
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ApplicationForCollateral") Then
		FillInDocumentBasedOnSupplyRequest(FillingData);
	EndIf;
	
	InventoryConsumptionOrderLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.InventoryConsumptionOrder.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	InitializeDocument(FillingData);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.InventoryConsumptionOrder.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation, 
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
	
	NotCheckedAttributeArray = New Array;
	
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		ArrayOfAllProps,
		ArrayOfOperationDetails,
		NotCheckedAttributeArray);
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	// The date of shipment in the header must be at least the date of the document
	If NotShipInInstallments
		And ValueIsFilled(DateOfShipment)
		And DateOfShipment < BegOfDay(Date) Then
		
		ErrorText = NStr("vi = 'Ngày giao hàng không được nhỏ hơn ngày chứng từ %Date%';
						|ru = 'Дата отгрузки должна быть не меньше даты документа %Date%';
						|en = 'Shipment date cannot be less than document date%Date%'; fa = 'Shipment date cannot be less than document date%Date%';
						|it = 'La data della spedizione non deve essere inferiore alla data del documento %Date%';
						|pl = 'Data wysyłki powinna być nie mniejsza niż data dokumentu %Date%';
						|tr = 'Sevkiyat tarihi, belgenin %Date%tarihinden daha önce olmamalıdır'");
		ErrorText = StrReplace(ErrorText, "%Date%", Format(Date,"DLF=DD"));
		
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			"DateOfShipment",
			,
			Cancel);
		
	EndIf;
	
	NotCheckedAttributeArray.Add("DateOfShipment");
	NotCheckedAttributeArray.Add("Goods.DateOfShipment");
	
	DepartmentMandatory = False;
	ItemsTypes = New Map;
	
	For Each TSRow In Goods Do
		
		ErrorAddress = " " + NStr("vi = 'trong dòng %LineNumber% của danh sách ""Hàng hóa""';
									|ru = 'в строке %LineNumber% списка ""Товары""';
									|en = 'in line %LineNumber% of the ""Goods"" list'; fa = 'in line %LineNumber% of the ""Goods"" list';
									|it = 'nella riga %LineNumber% dell''elenco ""Merci""';
									|pl = 'w wierszu %LineNumber% listy ""Towary""';
									|tr = '""Ürünler"" listesinin %LineNumber% satırında'");
		ErrorAddress = StrReplace(ErrorAddress,"%LineNumber%", TSRow.LineNumber);
		
		// The date of shipment in pm Goods must be at least the date of the document
		If Not NotShipInInstallments And ValueIsFilled(TSRow.DateOfShipment) And TSRow.DateOfShipment < BegOfDay(Date) Then
			
			ErrorText = NStr("vi = 'Ngày giao hàng không được nhỏ hơn ngày chứng từ ""%Date%""';
							|ru = 'Дата отгрузки должна быть не меньше даты документа ""%Date%""';
							|en = 'Shipment date cannot be less than document date ""%Date%""'; fa = 'Shipment date cannot be less than document date ""%Date%""';
							|it = 'La data della spedizione non deve essere inferiore alla data del documento ""%Date%""';
							|pl = 'Data wysyłki powinna być nie mniejsza niż data dokumentu ""%Date%""';
							|tr = 'Sevkiyat tarihi, belgenin ""%Date%""tarihinden daha önce olmamalıdır'");
			ErrorText = StrReplace(ErrorText,"%Date%", Format(Date, "DLF=DD"));
			
			Common.MessageToUser(
				ErrorText + ErrorAddress,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", TSRow.LineNumber, "DateOfShipment"),
				,
				Cancel);
			
		EndIf;
		
		// A subdivision is required if the work is specified in the document.
		If BusinessOperation = Enums.BusinessTransactions.GoodsConsumptionOnDemand
			And Not DepartmentMandatory Then
			
			ItemsType = ItemsTypes.Get(TSRow.Products);
			If ItemsType = Undefined Then
				ItemsType = Common.ObjectAttributeValue(TSRow.Products, "ItemsType");
				ItemsTypes.Insert(TSRow.Products, ItemsType);
			EndIf;
			
			If ItemsType = Enums.ItemsTypes.Work_5 Then
				DepartmentMandatory = True;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	EmbeddingParameters = Documents.InventoryConsumptionOrder.AvailableRemainingEmbeddingOptions();
	ErrorsTable = ProvisionInDocumentsServer.TableOfFillingErrors(ThisObject, EmbeddingParameters);

	DateOfShipmentRequired_  = False;
	WarehouseIsRequired          = False;
	TextTemplateShipmentDate = NStr("vi = 'Chưa điền cột ""Ngày giao hàng"" tại dòng %LineNumber% trong danh sách ""Hàng hóa""';
									|ru = 'Не заполнена колонка ""Дата отгрузки"" в строке %LineNumber% списка ""Товары""';
									|en = 'Column ""Shipment date"" in line %LineNumber% of the Item list is not filled in'; fa = 'Column ""Shipment date"" in line %LineNumber% of the Item list is not filled in';
									|it = 'Non è compilata la colonna ""Data di spedizione"" nella riga %LineNumber% dell''elenco ""Merci""';
									|pl = 'Nie wypełniono kolumny ""Data wysyłki"" w wierszu %LineNumber% listy ""Товары""';
									|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Sevkiyat tarihi"" sütunu eksik'");
	
	For CurIndex__ = 0 To ErrorsTable.Count() - 1 Do
		
		ErrorString = ErrorsTable[CurIndex__];
		
		If ErrorString.DateOfShipmentRequired_ And Not NotShipInInstallments And ErrorString.ShipmentDateNotFilledIn Then
			
			ErrorText   = StrReplace(TextTemplateShipmentDate, "%LineNumber%", ErrorString.LineNumber);
			PathToTop = CommonClientServer.PathToTabularSection("Goods", ErrorString.LineNumber, "DateOfShipment");
			Common.MessageToUser(ErrorText, ThisObject, PathToTop, , Cancel);
			
		EndIf;
		
		WarehouseIsRequired = WarehouseIsRequired Or ErrorString.WarehouseIsRequired;
		DateOfShipmentRequired_ = DateOfShipmentRequired_ Or ErrorString.DateOfShipmentRequired_;
		
	EndDo;
	
	If DateOfShipmentRequired_ And NotShipInInstallments And Not ValueIsFilled(DateOfShipment) Then
		
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
						|tr = '""Ambar"" alanı doldurulmamış'");
		Common.MessageToUser(ErrorText, ThisObject, "Warehouse", , Cancel);
	EndIf;
	
	If DepartmentMandatory
		And Not ValueIsFilled(Department) Then
		ErrorText = NStr("vi = 'Chưa điền trường ""Bộ phận""';
						|ru = 'Поле ""Подразделение"" не заполнено';
						|en = '""Business unit"" is required'; fa = '""Business unit"" is required';
						|it = 'Il campo ""Reparto"" non è compilato';
						|pl = 'Nie wypełniono pola ""Dział""';
						|tr = '""Departman"" alanı doldurulmadı'");
		Common.MessageToUser(ErrorText, ThisObject, "Department", , Cancel);
	EndIf;
	
	// Let's check the availability of roles
	If GetFunctionalOption("UseApprovalOfInventoryConsumptionOrders")
		And Status <> Enums.InternalOrderStatuses.AwaitingApproval
		And Not Approved
		And Not UserRightsCached.InventoryConsumptionOrderWithoutApproval() Then
		
		ErrorText = NStr("vi = 'Không có quyền kết chuyển Đơn hàng tiêu dùng nội bộ mà chưa có sự thống nhất';
						|ru = 'Нет прав на проведение Заказа на внутреннее потребление без согласования';
						|en = 'You do not have the rights to post Inventory consumption order without approval'; fa = 'You do not have the rights to post Inventory consumption order without approval';
						|it = 'Нет прав на проведение Заказа на внутреннее потребление без согласования';
						|pl = 'You do not have the rights to post Inventory consumption order without approval';
						|tr = 'Onay olmadan stok tüketimi için bir Sipariş kaydetme hakkı yoktur'");
		
		Common.MessageToUser(
			ErrorText,
			Ref,
			,
			,
			Cancel);
			
	EndIf;
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel);
	ProductsServer.CheckSeriesCompletion(
		ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventoryConsumptionOrder),
		Cancel,
		NotCheckedAttributeArray);
		
	// Selection of articles and analytics.
	CheckArticlesAndAnalytics = True;
	CheckArticlesAndAnalytics = (BusinessOperation <> Enums.BusinessTransactions.TransferToOperation);
	If CheckArticlesAndAnalytics Then
		ItemsAndDimensionsSelectionParameters = Documents.InventoryConsumptionOrder.ItemsAndDimensionsSelectionParameters(BusinessOperation);
		IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	EndIf;
	
	CheckParameters = VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity();
	CheckParameters.TabularSectionName = "Goods";
	CheckParameters.BankingDetailsNameExpenseItem = "ExpenseItem";
	CheckParameters.ExpenseAnalystDetailsName = "DimensionOfExpenses";
	CheckParameters.DetailsNameItemOfAssetsLiabilities = "ExpenseItem";
	CheckParameters.NameOfAssetLiabilityAnalystDetails = "AssetsLiabilitiesDimension";
	
	VATAccountingERP.CheckCompletionOfDocumentByTypeOfVATActivity(
		ThisObject,
		ConsumptionForActivity,
		CheckParameters,
		Cancel);
	InventoryInOperationServer.CheckOrderForCommissioning(ThisObject, NotCheckedAttributeArray, Cancel);
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	If BusinessOperation = Enums.BusinessTransactions.TransferToProduction And Not DeletionMark Then
		MessageText = NStr("vi = 'Cấm ghi lại chứng từ, bởi vì giao dịch ""Chuyển giao vào sản xuất"" vẫn chưa được sử dụng.
								|Đang lập đơn đặt hàng nguyên vật liệu trong biểu mẫu ""Sản xuất - Nhận và trả lại nguyên vật liệu"".';
								|ru = 'Запись документа запрещена, т.к. операция ""Передача в производство"" больше не используется.
								|Заказ материалов оформляется в форме ""Производство - Получение и возврат материалов"".';
								|en = 'It is prohibited to save the document because operation ""Transfer to production"" is not used.
								|Material order is registered in form ""Production — Receipt and return of materials"".'; fa = 'It is prohibited to save the document because operation ""Transfer to production"" is not used.
								|Material order is registered in form ""Production — Receipt and return of materials"".';
								|it = 'La scrittura di un documento è vietata, perché l''operazione ""Trasferimento in produzione"" non viene più utilizzata.
								|L''ordine dei materiali viene formalizzato nel modello ""Produzione - Ricevimento e reso dei materiali"".';
								|pl = 'Zapisywanie dokumentu jest zabronione, ponieważ operacja ""Передача в производство"" więcej nie jest używana. 
								|Zamówienie materiałów jest sporządzane w formularzu ""Производство - Получение и возврат материалов"".';
								|tr = '""Üretime aktar"" işlemi artık kullanılmadığından belgenin kaydedilmesi yasaktır.
								| Malzeme siparişi ""Üretim - Malzemelerin teslim alınması ve iadesi"" şeklinde gerçekleştirilir.'");
		Common.MessageToUser(MessageText, Ref,,, Cancel);	
	EndIf;
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	OrdersServer.SetKeyInRowsOfTablePart(ThisObject, "Goods");
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	If Not NotShipInInstallments Then
		
		NewShipmentDate = Date(1, 1, 1);
		
		If Goods.Count() > 0 Then
			
			RequirementsForProvision = Goods.FindRows(New Structure("Canceled", False));
			
			If RequirementsForProvision.Count() > 0 Then
				
				TableOfRowsToProvide = Goods.Unload(RequirementsForProvision, "DateOfShipment");
				TableOfRowsToProvide.Sort("DateOfShipment Asc");
				NewShipmentDate = TableOfRowsToProvide[0].DateOfShipment;
				
			EndIf;
				
		EndIf;
		
		DateOfShipment = NewShipmentDate;
	Else
		ProvisionInDocumentsServer.FillInShippingDatesInTable(DateOfShipment, Goods, "DateOfShipment");
	EndIf;
	
	TMCommonUse.ChangeDocumentConsistencyAttribute(
		ThisObject,
		WriteMode,
		Enums.InternalOrderStatuses.AwaitingApproval);
		
	ClearUnusedProps();
	
	DestinationPattern = Documents.InventoryConsumptionOrder.DestinationPattern(ThisObject);
	Catalogs.Assignments.CheckFillBeforeRecording(Purpose, DestinationPattern, ThisObject, "LineOfBusiness", Cancel);
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.InventoryConsumptionOrder.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	InventoryInOperationServer.BeforeRecordingOrderForCommissioning(ThisObject, Cancel);
	InventoryConsumptionOrderLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	DestinationPattern = Documents.InventoryConsumptionOrder.DestinationPattern(ThisObject);
	Catalogs.Assignments.OnWriteDocument(Purpose, DestinationPattern, ThisObject, Department, ConsumptionForActivity);
	
	InventoryConsumptionOrderLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentBasis       = Undefined;
	If GetFunctionalOption("UseStatusesOfInventoryConsumptionOrders") Then
		Status = Metadata().Attributes.Status.FillValue;
	Else
		Status = Enums.InternalOrderStatuses.Closed;
	EndIf;
	MaximumRowCode = 0;
	Purpose            = Undefined;
	Approved            = False;
	ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.EmptyRef();
	
	For Each LineProducts_ In Goods Do
	
		LineProducts_.DateOfShipment       = Date(1, 1, 1);
		LineProducts_.Canceled           = False;
		LineProducts_.RowCode          = 0;
		
	EndDo;
	
	InitializeDocument();
	
	InventoryConsumptionOrderLocalization.OnCopy(ThisObject, CopiedObject);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	PerformOrderControlAfterConducting(Cancel);
	
	InventoryConsumptionOrderLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	InventoryConsumptionOrderLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)

	Author         = Users.CurrentUser();
	EmployeeResponsible = Users.CurrentUser();
	Organization   = SettingsValueCached.GetDefaultOrganization(Organization);
	Warehouse         = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If Not GetFunctionalOption("UseStatusesOfInventoryConsumptionOrders") Then
		
		Status = Enums.InternalOrderStatuses.Closed;
		
	Else

		If GetFunctionalOption("UseApprovalOfInventoryConsumptionOrders") Then
			Status = Enums.InternalOrderStatuses.AwaitingApproval;
		Else
			Status = Enums.InternalOrderStatuses.ForCompletion;
		EndIf;

	EndIf;
		
	ProvisionInDocumentsServer.FillInDefaultSecurityOption(Goods);
	Priority = SettingsValueCached.GetDefaultPriority(Priority);
	FillParameters = Documents.InventoryConsumptionOrder.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(ConsumptionForActivity, FillParameters);
	
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
	HeaderProperties.Insert("Warehouse");
	HeaderProperties.Insert("Department");
	HeaderProperties.Insert("LineOfBusiness");
	FillPropertyValues(HeaderProperties, FillingData.Header);
	FillPropertyValues(ThisObject, HeaderProperties);
	
	DocumentBasis = ApplicationForCollateral;
	
	// Filling PM:
	Goods.Load(FillingData.Goods);
	
EndProcedure

#EndRegion

#Region Other

// Checks whether the document can be held in the "Closed" status.
//
// Parameters:
//  Cancel	 - Boolean - the "Failure" parameter for processing data.
//
Procedure PerformOrderControlAfterConducting(Cancel)

	MonitorShipment = GetFunctionalOption("DoNotCloseInventoryConsumptionOrdersWithoutCompleteShipment");
	
	If Status = Enums.InternalOrderStatuses.Closed
		And MonitorShipment Then
		Array = CommonClientServer.ValueInArray(Ref);
		AdditionalParameters = New Structure("OrderFulfillmentControl", True);
		
		Query = Documents.InventoryConsumptionOrder.GenerateVerificationRequestWhenStatusChanges(Array, "Closed", AdditionalParameters);
		
		Result = Query.Execute();
		
		SampleShipment = Result.Select();
		
		While SampleShipment.Next() Do
			
			CheckPassed = Documents.InventoryConsumptionOrder.CheckingBeforeChangingStatus(SampleShipment, Status, AdditionalParameters); 
			If Not CheckPassed Then
				Cancel = True;
			EndIf;
			
		EndDo;
		
	EndIf;

EndProcedure

Procedure ClearUnusedProps()
	
	// We will clear the details of the document that are not used for the business operation.
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	
	Documents.InventoryConsumptionOrder.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	CashServer.ClearUnusedProps(
		ThisObject,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	ProductsServer.ClearUnusedSeries(
		ThisObject, ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventoryConsumptionOrder));
	
	If Not ExpenseLineOfBusinessIsSpecifiedInList Then
		
		For Each RowData In Goods Do
			
			If ValueIsFilled(RowData.LineOfBusiness) Then
				RowData.LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
			EndIf;
			
		EndDo;
	
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf
