#Region Variables

&AtClient
Var IdleHandlerParameters;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	// Context-independent form setting.
	Query = New Query();
	Query.Text =
		"SELECT
		|	PRESENTATION(Constants.UnitOfMeasureForWeight)   AS UnitOfMeasureForWeight,
		|	PRESENTATION(Constants.UnitOfMeasureForVolume) AS UnitOfMeasureForVolume,
		|	Constants.OptionOfOrderingDemandsByOrdersForSupply
		|		= VALUE(Enum.OptionsOfOrderingDemandsByOrdersForSupply.PriorityAndShipmentDate) AS OrderingByShipmentDate
		|FROM
		|	Constants AS Constants";
	Selection = Query.Execute().Select();
	Selection.Next();
	OrderingByShipmentDate = Selection.OrderingByShipmentDate;
		
	TitleWeight   = StrTemplate(NStr("vi = 'Trọng lượng (%1)';
									|ru = 'Вес (%1)';
									|en = 'Weight (%1)'; fa = 'Weight (%1)';
									|it = 'Peso (%1)';
									|pl = 'Waga (%1)';
									|tr = 'Ağırlık (%1)'"), Selection.UnitOfMeasureForWeight);
	VolumeHeader = StrTemplate(NStr("vi = 'khối lượng (%1)';
									|ru = 'Объем (%1)';
									|en = 'Volume (%1)'; fa = 'Volume (%1)';
									|it = 'Volume (%1)';
									|pl = 'Objętość (%1)';
									|tr = 'Hacim (%1)'"), Selection.UnitOfMeasureForVolume);
	
	Items.WarehouseCartWeight.Title = TitleWeight;
	Items.WarehouseCartVolumeM3.Title = VolumeHeader;
	Items.GoodsWeight.Title   = TitleWeight;
	Items.GoodsVolumeM3.Title = VolumeHeader;
	
	// Setting up the access rights form.
	AccessStructure = DataProcessors.TransferOfAssignedGoods.AccessStructure();
	
	If Not AccessStructure.MoveOrderIsAvailable And Not AccessStructure.OrderingMaterialsIsAvailable Then
		DesiredElement = Items.RegistrationOption.ChoiceList.FindByValue(
			Enums.OptionsOfRegisteringTransferDocuments.TransferOrder);
		Items.RegistrationOption.ChoiceList.Delete(DesiredElement);
	EndIf;
	
	If Not AccessStructure.MovingIsAvailable And Not AccessStructure.TransferOfMaterialsIsAvailable Then
		DesiredElement = Items.RegistrationOption.ChoiceList.FindByValue(
			Enums.OptionsOfRegisteringTransferDocuments.InventoryTransfer);
		Items.RegistrationOption.ChoiceList.Delete(DesiredElement);
	EndIf;
	
	// Subscriptions of standard subsystems.
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// The context-sensitive configuration of the form has been moved to "Restore Settings".
	RestoreSettings();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	CheckedAttributes.Clear();
	
	If Not ValueIsFilled(Object.RegistrationOption) Then
		
		MessageText = NStr("vi = 'Chứng từ không có sẵn.';
							|ru = 'Оформление документов недоступно.';
							|en = 'Document registration is not available.'; fa = 'Document registration is not available.';
							|it = 'La formalizzazione dei documenti non è disponibile.';
							|pl = 'Sporządzenie dokumentów nie jest dostępne.';
							|tr = 'Belge düzenleme erişilebilir değil.'");
		Return;
		Cancel = True;
		
	EndIf;
	
	If Mode = Items.Mode.ChoiceList[0].Value Then // this is the distribution of residuals
		
		If Not ValueIsFilled(Object.SourceWarehouse) Then
			
			MessageText = NStr("vi = 'Chưa điền trường ""Kho gửi""';
								|ru = 'Поле ""Склад-отправитель"" не заполнено';
								|en = '""Origin warehouse"" is not filled in'; fa = '""Origin warehouse"" is not filled in';
								|it = 'Il campo ""Magazzino-mittente"" non è compilato';
								|pl = 'Nie wypełniono pola ""Magazyn wysyłki""';
								|tr = '""Çıkış ambarı"" alanı doldurulmadı'");
			CommonClientServer.MessageToUser(MessageText, Undefined, "SourceWarehouse", "Object.SourceWarehouse", Cancel);
			
		EndIf;
		
		If Not ValueIsFilled(Object.DateOfShipment) Then
			
			MessageText = NStr("vi = 'Chưa điền trường ""Ngày giao hàng""';
								|ru = 'Поле ""Дата отгрузки"" не заполнено';
								|en = '""Shipment date"" is not filled in'; fa = '""Shipment date"" is not filled in';
								|it = 'Il campo ""Data di spedizione"" non è compilato';
								|pl = 'Nie wypełniono pole ""Data отгрузки""';
								|tr = '""Sevkiyat tarihi"" alanı doldurulmadı'");
			CommonClientServer.MessageToUser(MessageText, Undefined, "DateOfShipment", "Object.DateOfShipment", Cancel);
			
		ElsIf Object.DateOfShipment < BegOfDay(CurrentSessionDate()) Then
			
			MessageText = NStr("vi = 'Trường ""Ngày giao hàng"" không thể điền vào ngày qua';
								|ru = 'Поле ""Дата отгрузки"" не может быть заполнено прошедшей датой';
								|en = 'The ""Shipment date"" field cannot be filled in with a date that has already passed'; fa = 'The ""Shipment date"" field cannot be filled in with a date that has already passed';
								|it = 'Il campo ""Data di spedizione"" non può essere compilato con la data antecedente';
								|pl = 'Pole ""Дата отгрузки"" nie może być wypełnione minioną datą';
								|tr = '""Sevkiyat tarihi"" alanı geçmiş bir tarih ile doldurulamaz'");
			CommonClientServer.MessageToUser(MessageText, Undefined, "DateOfShipment", "Object.DateOfShipment", Cancel);
			
		ElsIf Object.DateOfShipment > BegOfDay(CurrentSessionDate())
					And Object.RegistrationOption = Enums.OptionsOfRegisteringTransferDocuments.InventoryTransfer Then
			
			MessageText = NStr("vi = 'Đối với tùy chọn thiết kế ""Lưu chuyển của hàng hóa"", trường ""Ngày giao hàng"" không thể được điền vào một ngày trong tương lai';
								|ru = 'Для варианта оформления ""Перемещение товаров"" поле ""Дата отгрузки"" не может быть заполнено будущей датой';
								|en = 'The Shipment date field cannot be populated with a future date for the Goods transfer registration option'; fa = 'The Shipment date field cannot be populated with a future date for the Goods transfer registration option';
								|it = 'Per l''opzione della formalizzazione ""Trasferimento merci"", il campo ""Data di spedizione"" non può essere compilato con una data postuma';
								|pl = 'Dla wariantu sporządzenia ""Przemieszczenie towarów"" pole ""Data wysyłki"" nie może być wypełnione przyszłą datą';
								|tr = '""Mal transferi"" seçeneği için ""Sevkiyat tarihi"" alanı ileri bir tarihle doldurulamaz'");
			CommonClientServer.MessageToUser(MessageText, Undefined, "DateOfShipment", "Object.DateOfShipment", Cancel);
			
		ElsIf ValueIsFilled(Object.DateOfNextShipment) And Object.DateOfNextShipment < Object.DateOfShipment Then
			
			MessageText = NStr("vi = 'Trường ""Ngày gửi hàng tiếp theo"" không thể được điền bằng một ngày ít hơn trường ""Ngày gửi hàng""';
								|ru = 'Поле ""Дата следующей отгрузки"" не может быть заполнено датой меньшей чем поле ""Дата отгрузки""';
								|en = 'Next shipment date cannot be less than the Shipment date'; fa = 'Next shipment date cannot be less than the Shipment date';
								|it = 'Il campo ""Data della prossima spedizione"" non può essere compilato con una data inferiore a quella del campo ""Data di spedizione""';
								|pl = 'Pole ""Дата следующей отгрузки"" nie może być wypełnione datą mniejszą niż pole ""Дата отгрузки""';
								|tr = '""Bir sonraki sevkiyat tarihi"" alanı, ""Sevkiyat tarihi"" alanından daha küçük bir tarihle doldurulamaz.'");
			CommonClientServer.MessageToUser(MessageText, Undefined, "DateOfNextShipment", "Object.DateOfNextShipment", Cancel);
			
		EndIf;
		
	ElsIf Mode = Items.Mode.ChoiceList[1].Value Then
		
		If Not ValueIsFilled(Object.DestinationWarehouse) Then
			
			MessageText = NStr("vi = 'Trường ''''Kho người nhận'''' chưa điền';
								|ru = 'Поле ""Склад-получатель"" не заполнено';
								|en = '""Destination warehouse"" is not filled in'; fa = '""Destination warehouse"" is not filled in';
								|it = 'Il campo ""Magazzino-destinatario"" non è compilato';
								|pl = 'Nie wypełniono pola ""Magazyn-odbiorca""';
								|tr = '""Hedef ambar"" alanı doldurulmadı'");
			CommonClientServer.MessageToUser(MessageText, Undefined, "DestinationWarehouse", "Object.DestinationWarehouse", Cancel);
			
		EndIf;
		
		If Not ValueIsFilled(Object.DateOfShipment) Then
			
			MessageText = NStr("vi = 'Chưa điền trường ""Ngày giao hàng""';
								|ru = 'Поле ""Дата отгрузки"" не заполнено';
								|en = '""Shipment date"" is not filled in'; fa = '""Shipment date"" is not filled in';
								|it = 'Il campo ""Data di spedizione"" non è compilato';
								|pl = 'Nie wypełniono pole ""Data отгрузки""';
								|tr = '""Sevkiyat tarihi"" alanı doldurulmadı'");
			CommonClientServer.MessageToUser(MessageText, Undefined, "DateOfShipment", "Object.DateOfShipment", Cancel);
			
		ElsIf Object.DateOfShipment < BegOfDay(CurrentSessionDate()) Then
			
			MessageText = NStr("vi = 'Trường ""Ngày giao hàng"" không thể điền vào ngày qua';
								|ru = 'Поле ""Дата отгрузки"" не может быть заполнено прошедшей датой';
								|en = 'The ""Shipment date"" field cannot be filled in with a date that has already passed'; fa = 'The ""Shipment date"" field cannot be filled in with a date that has already passed';
								|it = 'Il campo ""Data di spedizione"" non può essere compilato con la data antecedente';
								|pl = 'Pole ""Дата отгрузки"" nie może być wypełnione minioną datą';
								|tr = '""Sevkiyat tarihi"" alanı geçmiş bir tarih ile doldurulamaz'");
			CommonClientServer.MessageToUser(MessageText, Undefined, "DateOfShipment", "Object.DateOfShipment", Cancel);
			
		ElsIf Object.DateOfShipment > BegOfDay(CurrentSessionDate())
					And Object.RegistrationOption = Enums.OptionsOfRegisteringTransferDocuments.InventoryTransfer Then
			
			MessageText = NStr("vi = 'Đối với tùy chọn thiết kế ""Lưu chuyển của hàng hóa"", trường ""Ngày giao hàng"" không thể được điền vào một ngày trong tương lai';
								|ru = 'Для варианта оформления ""Перемещение товаров"" поле ""Дата отгрузки"" не может быть заполнено будущей датой';
								|en = 'The Shipment date field cannot be populated with a future date for the Goods transfer registration option'; fa = 'The Shipment date field cannot be populated with a future date for the Goods transfer registration option';
								|it = 'Per l''opzione della formalizzazione ""Trasferimento merci"", il campo ""Data di spedizione"" non può essere compilato con una data postuma';
								|pl = 'Dla wariantu sporządzenia ""Przemieszczenie towarów"" pole ""Data wysyłki"" nie może być wypełnione przyszłą datą';
								|tr = '""Mal transferi"" seçeneği için ""Sevkiyat tarihi"" alanı ileri bir tarihle doldurulamaz'");
			CommonClientServer.MessageToUser(MessageText, Undefined, "DateOfShipment", "Object.DateOfShipment", Cancel);
			
		ElsIf ValueIsFilled(Object.DemandsBeforeDate) And Object.DemandsBeforeDate < Object.DateOfShipment Then
			
			MessageText = NStr("vi = 'Trường Yêu cầu cho đến Ngày không thể được điền bằng một ngày ít hơn trường Ngày gửi hàng';
								|ru = 'Поле ""Потребности до даты"" не может быть заполнено датой меньшей чем поле ""Дата отгрузки""';
								|en = 'Demands before date cannot be less than Shipment date'; fa = 'Demands before date cannot be less than Shipment date';
								|it = 'Il campo ""Fabbisogni entro la data"" non può essere compilato con una data inferiore a quella del campo ""Data di spedizione""';
								|pl = 'Pole ""Потребности до даты"" nie może być wypenione datą mniejszą niż pole ""Дата отгрузки""';
								|tr = '""Tarihten önceki gereksinimler"" alanı, ""Sevkiyat tarihi"" alanından daha küçük bir tarihle doldurulamaz.'");
			CommonClientServer.MessageToUser(MessageText, Undefined, "DemandsBeforeDate", "Object.DemandsBeforeDate", Cancel);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Items.Tabs.CurrentPage = Items.TheDocumentsTab
		And (EventName = "Write_TransferOrder"
			Or EventName = "Write_OrderOfMaterialsForProduction"
			Or EventName = "Write_MovementOfProductsAndMaterials"
			Or EventName = "Write_InventoryTransfer") Then
		
		Items.ListDocuments.Refresh();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure ModeOnChange(Item)
	
	OnChangeAttributes(Items.Mode.Name);
	
EndProcedure

&AtClient
Procedure ParametersWarehouseSenderOnChange(Item)
	
	ShouldSaveSettings();
	
EndProcedure

&AtClient
Procedure ShipDateModeOfDistributionOfTheResiduesOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ShouldSaveSettings();
	
EndProcedure

&AtClient
Procedure DateOfNextShipmentOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ShouldSaveSettings();
	
EndProcedure

&AtClient
Procedure ParametersWarehouseRecipientOnChange(Item)
	
	ShouldSaveSettings();
	
EndProcedure

&AtClient
Procedure DateOfShipmentOfTheModeProvidingRequirementsOnChange(Item)
	
	ShouldSaveSettings();
	
EndProcedure

&AtClient
Procedure DemandsBeforeDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ShouldSaveSettings();
	
EndProcedure

&AtClient
Procedure RegistrationOptionOnChange(Item)
	
	ShouldSaveSettings();
	
EndProcedure

&AtClient
Procedure PurposeOnChange(Item)
	
	OnChangeAttributes(Items.Purpose.Name);
	
EndProcedure

&AtClient
Procedure SourceWarehouseOnChange(Item)
	
	ShouldSaveSettings();
	
EndProcedure

&AtClient
Procedure DestinationWarehouseOnChange(Item)
	
	ShouldSaveSettings();
	
EndProcedure

&AtClient
Procedure OnlyCheckedOnChange(Item)
	
	OnlyMarkedWhenModifiedOnServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.Goods.CurrentData;
	
	MatchingReferenceFields = New Map();
	MatchingReferenceFields.Insert(Items.GoodsProducts,     "Products");
	MatchingReferenceFields.Insert(Items.GoodsPurpose,       "Purpose");
	MatchingReferenceFields.Insert(Items.GoodsDestinationWarehouse,  "DestinationWarehouse");
	MatchingReferenceFields.Insert(Items.GoodsSourceWarehouse, "SourceWarehouse");
	
	MatchingQuantityDecryptionFields = New Map();
	MatchingQuantityDecryptionFields.Insert(Items.GoodsSourceWarehouse, "SourceWarehouse");
	MatchingQuantityDecryptionFields.Insert(Items.GoodsDestinationWarehouse,  "DestinationWarehouse");
	MatchingQuantityDecryptionFields.Insert(Items.GoodsDemandDate,  "DemandDate");
	
	AttributeName = MatchingQuantityDecryptionFields.Get(Field);
	NameOfReferenceProps = MatchingReferenceFields.Get(Field);
	If Field = Items.ProductsQuantityHyperlink
			Or Field = Items.ProductsMarkViewOnly
			Or AttributeName <> Undefined And Not ValueIsFilled(CurrentData[AttributeName]) Then
		
		StandardProcessing = False;
		ShoppingCartWarehousesBeforeChangingProductsQuantity();
		OpenQuantityEntryForm();
		
	ElsIf NameOfReferenceProps <> Undefined Then
		
		StandardProcessing = False;
		ShowValue(Undefined, CurrentData[NameOfReferenceProps]);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsMarkOnChange(Item)
	
	ShoppingCartWarehousesBeforeChangingProductsQuantity();
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData.Mark Then
		
		FillParameters = New Structure();
		AddSelectionFields_(FillParameters);
		ArrayDetailedRecords = DetailedRecords(FillParameters, CurrentData.Count, CurrentData.Mark);
		
		Collection = CurrentData.DetailedRecords;
		Collection.Clear();
		For Each Item In ArrayDetailedRecords Do
			FillPropertyValues(Collection.Add(), Item);
		EndDo;
		
	Else
		
		Collection = CurrentData.DetailedRecords;
		Collection.Clear();
		
	EndIf;
	
	ShoppingCartWarehousesWhenChangingProductsQuantity();
	
EndProcedure

&AtClient
Procedure GoodsCountOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	FillParameters = New Structure();
	AddSelectionFields_(FillParameters);
	
	CurrentData.Mark = CurrentData.Count > 0;
	ArrayDetailedRecords = DetailedRecords(FillParameters, CurrentData.Count, CurrentData.Mark);
	
	Collection = CurrentData.DetailedRecords;
	Collection.Clear();
	For Each Item In ArrayDetailedRecords Do
		FillPropertyValues(Collection.Add(), Item);
	EndDo;
	
	ShoppingCartWarehousesWhenChangingProductsQuantity();
	
EndProcedure

&AtClient
Procedure GoodsCountClearing(Item, StandardProcessing)
	
	ShoppingCartWarehousesBeforeChangingProductsQuantity();
	
EndProcedure

&AtClient
Procedure GoodsCountEditTextChange(Item, Text, StandardProcessing)
	
	ShoppingCartWarehousesBeforeChangingProductsQuantity();
	
EndProcedure

&AtClient
Procedure GoodsCountStartChoice(Item, ChoiceData, StandardProcessing)
	
	ShoppingCartWarehousesBeforeChangingProductsQuantity();
	
EndProcedure

&AtClient
Procedure GoodsCountTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	ShoppingCartWarehousesBeforeChangingProductsQuantity();
	
EndProcedure

&AtClient
Procedure GoodsCountStartListChoice(Item, StandardProcessing)
	
	ShoppingCartWarehousesBeforeChangingProductsQuantity();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListDocuments

&AtClient
Procedure ListDocumentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	ShowValue(Undefined, Items.ListDocuments.CurrentData.Ref);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ThenGoToTheMovedItemsStep(Command)
	
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.TransferOfAssignedGoods.Form.Workplace.ThenGoToTheMovedItemsStep");
		
	ClearMessages();
	NextToMovedGoodsOnServerStep();
	
	If OpenTimeConsumingOperationForm Then
		
		OpenTimeConsumingOperationForm = False;
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		CallbackOnCompletion = New CallbackDescription("AfterExecutionAlertIsDisplayedInBackground", ThisObject);
	
		TimeConsumingOperationsClient.WaitCompletion(
			BackgroundExecutionResult, CallbackOnCompletion, IdleParameters);
			
	EndIf;
	
EndProcedure

&AtClient
Procedure Notice(Command)
	
	For Each IDOfProductsLine In Items.Goods.SelectedRows Do
		
		LineProducts_ = Object.Goods.FindByID(IDOfProductsLine);
		LineProducts_.Mark = LineProducts_.Count > 0;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearMark1(Command)
	
	For Each IDOfProductsLine In Items.Goods.SelectedRows Do
		
		LineProducts_ = Object.Goods.FindByID(IDOfProductsLine);
		LineProducts_.Mark = False;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure BackToStepSelections(Command)
	
	ClearMessages();
	Object.Goods.Clear();
	BackToServerSelectionsStep();
	
EndProcedure

&AtClient
Procedure ThenGoToTheGeneratedDocumentsStep(Command)
	
	ClearMessages();
	If Not NextToStepGeneratedDocumentsOnServer() Then
		
		MessageText = NStr("vi = 'Không di dời hàng hóa.';
							|ru = 'Не указаны перемещаемые товары.';
							|en = 'Goods to transfer are not specified.'; fa = 'Goods to transfer are not specified.';
							|it = 'Non sono specificati i prodotti in trasferimento.';
							|pl = 'Nie wskazano przemieszczanych towarów.';
							|tr = 'Transfer edilebilen ürünler belirtilmedi.'");
		CommonClientServer.MessageToUser(MessageText, , "Goods");
		Items.Tabs.CurrentPage = Items.TheItemsTab;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetTheStatusOfMoveToCompleteOrders(Command)
	
	SetStatus(Command.Name);
	
EndProcedure

&AtClient
Procedure SetTheStatusOfMaterialOrdersToBeCompleted(Command)
	
	SetStatus(Command.Name);
	
EndProcedure

&AtClient
Procedure SetTheStatusOfMaterialTransfersShipped(Command)
	
	SetStatus(Command.Name);
	
EndProcedure

&AtClient
Procedure SetTheStatusOfMaterialTransfersAccepted(Command)
	
	SetStatus(Command.Name);
	
EndProcedure

&AtClient
Procedure SetTheStatusOfProductMovementsShipped(Command)
	
	SetStatus(Command.Name);
	
EndProcedure

&AtClient
Procedure SetTheStatusOfProductMovementsAccepted(Command)
	
	SetStatus(Command.Name);
	
EndProcedure

&AtClient
Procedure UndoPosting(Command)
	
	WriteAtClient(Command);
	
EndProcedure

&AtClient
Procedure Post(Command)
	
	WriteAtClient(Command);
	
EndProcedure

&AtClient
Procedure MarkToDelete(Command)
	
	WriteAtClient(Command);
	
EndProcedure

&AtClient
Procedure BackToTheMovedItemsStep(Command)
	
	ClearMessages();
	ShowQuestionDeleteDocuments();

EndProcedure

&AtClient
Procedure GenerateAgain(Command)
	
	ClearMessages();
	Object.Goods.Clear();
	GenerateMoreOnServer();
	
EndProcedure

#EndRegion

#Region Private

#Region StepSelections

&AtServer
Procedure NextToMovedGoodsOnServerStep()
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	StartExecutionInBackground(Items.ThenGoToTheMovedItemsStep.Name, NStr("vi = 'Lấy dữ liệu về hàng hóa đang được di chuyển';
																			|ru = 'Получение данных о перемещаемых товарах';
																			|en = 'Receive data on moved goods'; fa = 'Receive data on moved goods';
																			|it = 'Acquisizione dei dati sui prodotti in trasferimento';
																			|pl = 'Pobieranie danych o przemieszczanych towarach';
																			|tr = 'Transfer edilen ürünler ile ilgili veri alımı'"));
	AfterStartingExecutionInBackground();
	
EndProcedure

&AtServer
Procedure ListOfDocumentsWhenChangingDesignOption()
	
	AccessStructure = DataProcessors.TransferOfAssignedGoods.AccessStructure();
	QueryText = "";
	
	CurDesign_ = Object.RegistrationOption;
	
	If CurDesign_ = Enums.OptionsOfRegisteringTransferDocuments.InventoryTransfer
			And AccessStructure.MovingIsAvailable Then
		
		AddJoinSection(QueryText);
		QueryText = QueryText +
			"SELECT
			|	CASE WHEN InventoryTransferOverridable.Posted THEN
			|				1
			|			WHEN InventoryTransferOverridable.DeletionMark THEN
			|				2
			|			ELSE
			|				0
			|		END                                                 AS RowPicture,
			|	InventoryTransferOverridable.Ref                 AS Ref,
			|	InventoryTransferOverridable.DeletionMark        AS DeletionMark,
			|	InventoryTransferOverridable.Number                  AS Number,
			|	InventoryTransferOverridable.Date                   AS Date,
			|	InventoryTransferOverridable.Posted               AS Posted,
			|	InventoryTransferOverridable.Organization            AS Organization,
			|	InventoryTransferOverridable.CompanyRecipient  AS CompanyRecipient,
			|	InventoryTransferOverridable.EmployeeResponsible          AS EmployeeResponsible,
			|	InventoryTransferOverridable.Department          AS Department,
			|	InventoryTransferOverridable.SourceWarehouse       AS SourceWarehouse,
			|	InventoryTransferOverridable.DestinationWarehouse        AS DestinationWarehouse,
			|	InventoryTransferOverridable.Status                 AS Status
			|FROM
			|	Document.InventoryTransfer AS InventoryTransferOverridable
			|WHERE
			|	InventoryTransferOverridable.Ref IN(&Documents)";
			
	EndIf;
	If CurDesign_ = Enums.OptionsOfRegisteringTransferDocuments.InventoryTransfer
			And AccessStructure.TransferOfMaterialsIsAvailable Then
		
		AddJoinSection(QueryText);
		QueryText = QueryText +
			"SELECT
			|	CASE WHEN MovementOfProductsAndMaterialsOverridable.Posted THEN
			|				1
			|			WHEN MovementOfProductsAndMaterialsOverridable.DeletionMark THEN
			|				2
			|			ELSE
			|				0
			|		END                                                           AS RowPicture,
			|	MovementOfProductsAndMaterialsOverridable.Ref                 AS Ref,
			|	MovementOfProductsAndMaterialsOverridable.DeletionMark        AS DeletionMark,
			|	MovementOfProductsAndMaterialsOverridable.Number                  AS Number,
			|	MovementOfProductsAndMaterialsOverridable.Date                   AS Date,
			|	MovementOfProductsAndMaterialsOverridable.Posted               AS Posted,
			|	MovementOfProductsAndMaterialsOverridable.Organization            AS Organization,
			|	MovementOfProductsAndMaterialsOverridable.Organization            AS CompanyRecipient,
			|	MovementOfProductsAndMaterialsOverridable.EmployeeResponsible          AS EmployeeResponsible,
			|	CAST(MovementOfProductsAndMaterialsOverridable.Recipient
			|		AS Catalog.Warehouses).Department                            AS Department,
			|	MovementOfProductsAndMaterialsOverridable.Sender            AS SourceWarehouse,
			|	MovementOfProductsAndMaterialsOverridable.Recipient             AS DestinationWarehouse,
			|	MovementOfProductsAndMaterialsOverridable.Status                 AS Status
			|FROM
			|	Document.MovementOfProductsAndMaterials AS MovementOfProductsAndMaterialsOverridable
			|WHERE
			|	MovementOfProductsAndMaterialsOverridable.Ref IN(&Documents)";
		
	EndIf;
	If CurDesign_ = Enums.OptionsOfRegisteringTransferDocuments.TransferOrder
			And AccessStructure.MoveOrderIsAvailable Then
		
		AddJoinSection(QueryText);
		QueryText = QueryText +
			"SELECT
			|	CASE WHEN TransferOrderOverridable.Posted THEN
			|				1
			|			WHEN TransferOrderOverridable.DeletionMark THEN
			|				2
			|			ELSE
			|				0
			|		END                                                 AS RowPicture,
			|	TransferOrderOverridable.Ref                 AS Ref,
			|	TransferOrderOverridable.DeletionMark        AS DeletionMark,
			|	TransferOrderOverridable.Number                  AS Number,
			|	TransferOrderOverridable.Date                   AS Date,
			|	TransferOrderOverridable.Posted               AS Posted,
			|	TransferOrderOverridable.Organization            AS Organization,
			|	TransferOrderOverridable.CompanyRecipient  AS CompanyRecipient,
			|	TransferOrderOverridable.EmployeeResponsible          AS EmployeeResponsible,
			|	TransferOrderOverridable.Department          AS Department,
			|	TransferOrderOverridable.SourceWarehouse       AS SourceWarehouse,
			|	TransferOrderOverridable.DestinationWarehouse        AS DestinationWarehouse,
			|	TransferOrderOverridable.Status                 AS Status
			|FROM
			|	Document.TransferOrder AS TransferOrderOverridable
			|WHERE
			|	TransferOrderOverridable.Ref IN(&Documents)";
		
	EndIf;
	If CurDesign_ = Enums.OptionsOfRegisteringTransferDocuments.TransferOrder
			And AccessStructure.OrderingMaterialsIsAvailable Then
		
		AddJoinSection(QueryText);
		QueryText = QueryText +
			"SELECT
			|	CASE WHEN OrderOfMaterialsOverridable.Posted THEN
			|				1
			|			WHEN OrderOfMaterialsOverridable.DeletionMark THEN
			|				2
			|			ELSE
			|				0
			|		END                                              AS RowPicture,
			|	OrderOfMaterialsOverridable.Ref                 AS Ref,
			|	OrderOfMaterialsOverridable.DeletionMark        AS DeletionMark,
			|	OrderOfMaterialsOverridable.Number                  AS Number,
			|	OrderOfMaterialsOverridable.Date                   AS Date,
			|	OrderOfMaterialsOverridable.Posted               AS Posted,
			|	OrderOfMaterialsOverridable.Organization            AS Organization,
			|	OrderOfMaterialsOverridable.Organization            AS CompanyRecipient,
			|	OrderOfMaterialsOverridable.EmployeeResponsible          AS EmployeeResponsible,
			|	OrderOfMaterialsOverridable.Department          AS Department,
			|	OrderOfMaterialsOverridable.Warehouse                  AS SourceWarehouse,
			|	OrderOfMaterialsOverridable.ShopFloorStockroom        AS DestinationWarehouse,
			|	OrderOfMaterialsOverridable.Status                 AS Status
			|FROM
			|	Document.OrderOfMaterialsForProduction AS OrderOfMaterialsOverridable
			|WHERE
			|	OrderOfMaterialsOverridable.Ref IN(&Documents)";
		
	EndIf;
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, ListDocuments);
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.ListDocuments, ListProperties);
	
EndProcedure

#EndRegion

#Region TabularPartProducts

&AtServer
Procedure BackToServerSelectionsStep()
	
	Items.Tabs.CurrentPage = Items.TabFilters;
	Items.ThenGoToTheMovedItemsStep.DefaultButton = True;
	
EndProcedure

&AtServer
Procedure OnlyMarkedWhenModifiedOnServer()
	
	SelectingRowsWhenChangingBankingDetails(Items.OnlyChecked);
	ShouldSaveSettings();
	
EndProcedure

&AtServer
Procedure SelectingRowsWhenChangingBankingDetails(Item)
	
	FilterStructure1 = New Structure();
	
	If Item = Undefined Or Item = Items.OnlyChecked Then
		
		If OnlyChecked Then
			FilterStructure1.Insert("Mark", True);
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(FilterStructure1) Then
		Items.Goods.RowFilter = New FixedStructure(FilterStructure1);
	Else
		Items.Goods.RowFilter = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Function NextToStepGeneratedDocumentsOnServer()
	
	Items.Tabs.CurrentPage = Items.TheDocumentsTab;
	Items.Done.DefaultButton = True;
	
	// The beginning of performance measurement.
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("DataProcessor.TransferOfAssignedGoods.Form.Workplace.ThenGoToTheGeneratedDocumentsStep.%1");
	
	NumberOfDocumentsCreated = CreateDocuments();
	
	// The end of the performance measurement.
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, NumberOfDocumentsCreated);
	
	If NumberOfDocumentsCreated = 0 Then
		Return False;
	EndIf;
	
	TypesArray = New Array();
	For Each TableRow In CompletedDocuments_4 Do
		
		DocumentType = TypeOf(TableRow.Document);
		If TypesArray.Find(DocumentType) = Undefined Then
			TypesArray.Add(DocumentType);
		EndIf;
		
	EndDo;
	
	For Each Item In Items.GroupSetStatus.ChildItems Do
		Item.Visible = False;
	EndDo;
	
	TotalTypes = 0;
	DocumentNames = New Array();
	
	DocumentNames.Add(NStr("vi = 'Điều chuyển hàng hóa:';
							|ru = 'Перемещение товаров:';
							|en = 'Goods transfer:'; fa = 'Goods transfer:';
							|it = 'Trasferimento prodotti:';
							|pl = 'Przemieszczanie towarów:';
							|tr = 'Mal transferi:'"));
	VisibilityOfStatuses = TypesArray.Find(Type("DocumentRef.InventoryTransfer")) <> Undefined
		And GetFunctionalOption("UseGoodsTransferStatuses");
	TotalTypes = TotalTypes + ?(VisibilityOfStatuses, 1, 0);
	
	Items.SetTheStatusOfProductMovementsShipped.Visible = VisibilityOfStatuses;
	Items.SetTheStatusOfProductMovementsAccepted.Visible   = VisibilityOfStatuses;
	
	DocumentNames.Add(NStr("vi = 'Lệnh chuyển:';
							|ru = 'Заказ на перемещение:';
							|en = 'Transfer order:'; fa = 'Transfer order:';
							|it = 'Ordine di trasferimento:';
							|pl = 'Zamówienie przemieszczenia:';
							|tr = 'Transfer emri:'"));
	VisibilityOfStatuses = TypesArray.Find(Type("DocumentRef.TransferOrder")) <> Undefined
		And GetFunctionalOption("UseStatusesOfTransferOrders");
	TotalTypes = TotalTypes + ?(VisibilityOfStatuses, 1, 0);
	
	Items.SetTheStatusOfMoveToCompleteOrders.Visible  = VisibilityOfStatuses;
	DocumentNames.Add(NStr("vi = 'Chuyển vật liệu:';
							|ru = 'Передача материалов:';
							|en = 'Material transfer:'; fa = 'Material transfer:';
							|it = 'Consegna dei materiali:';
							|pl = 'Przekazanie materiałów:';
							|tr = 'Malzemelerin transferi:'"));
	VisibilityOfStatuses = TypesArray.Find(Type("DocumentRef.MovementOfProductsAndMaterials")) <> Undefined
		And GetFunctionalOption("UseStatusesOfProductsAndMaterialsMovements");
	TotalTypes = TotalTypes + ?(VisibilityOfStatuses, 1, 0);
	
	Items.SetTheStatusOfMaterialTransfersShipped.Visible = VisibilityOfStatuses;
	Items.SetTheStatusOfMaterialTransfersAccepted.Visible   = VisibilityOfStatuses;
	
	DocumentNames.Add(NStr("vi = 'Đặt nguyên liệu:';
							|ru = 'Заказ материалов:';
							|en = 'Order materials:'; fa = 'Order materials:';
							|it = 'Ordini dei materiali:';
							|pl = 'Zamówienie materiałów:';
							|tr = 'Malzeme siparişi:'"));
	VisibilityOfStatuses = TypesArray.Find(Type("DocumentRef.OrderOfMaterialsForProduction")) <> Undefined;
	TotalTypes = TotalTypes + ?(VisibilityOfStatuses, 1, 0);
	
	Items.SetTheStatusOfMaterialOrdersToBeCompleted.Visible  = VisibilityOfStatuses;
	For Each FormItem In Items.GroupSetStatus.ChildItems Do
		
		FormCommand = Commands[FormItem.CommandName]; // FormCommand -
		CommandTitle = FormCommand.Title;
		
		If TotalTypes = 1 Then
			For Each DocumentName In DocumentNames Do
				CommandTitle = TrimAll(StrReplace(CommandTitle, DocumentName, ""));
			EndDo;
		EndIf;
		
		FormItem.Title = CommandTitle;
		
	EndDo;
	
	Items.ListDocumentsStatus.Visible = TotalTypes > 0;
	Return True;
	
EndFunction

&AtServer
Function CreateDocuments()
	
	UnloadedColumns = 
		"Products,
		|Characteristic,
		|SourceWarehouse,
		|DestinationWarehouse,
		|Count,
		|NumberOfPackages,
		|Package,
		|Purpose,
		|LineOfBusiness,
		|TransferDurationDays";
	
	UnloadedTable = Object.Goods.Unload(New Array, UnloadedColumns);
	
	TotalRows = Object.Goods.Count();
	
	For Each TableRow In Object.Goods Do
		
		If Not TableRow.Mark Or TableRow.Count = 0 Then
			Continue;
		EndIf;
		
		If ValueIsFilled(TableRow.SourceWarehouse) And ValueIsFilled(TableRow.DestinationWarehouse) Then
			
			NewRow = UnloadedTable.Add();
			FillPropertyValues(NewRow, TableRow);
			NewRow.NumberOfPackages = NewRow.Count;
			
		Else
			
			For Each RowOfDetailedRecords In TableRow.DetailedRecords Do
				
				NewRow = UnloadedTable.Add();
				FillPropertyValues(NewRow, TableRow);
				NewRow.Count         = RowOfDetailedRecords.ForTransfer;
				NewRow.NumberOfPackages = RowOfDetailedRecords.ForTransfer;
				
				If Mode = Items.Mode.ChoiceList[0].Value Then // Distribution of leftovers, you need to fill in the receiving warehouses
					
					NewRow.DestinationWarehouse = RowOfDetailedRecords.Warehouse;
					NewRow.SourceWarehouse = Object.SourceWarehouse;
					
				Else
					
					NewRow.SourceWarehouse = RowOfDetailedRecords.Warehouse;
					NewRow.DestinationWarehouse = Object.DestinationWarehouse;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	If UnloadedTable.Count() = 0 Then
		Return 0;
	EndIf;
	
	DesignResult_ = DataProcessors.TransferOfAssignedGoods.IssueDocuments(
		Object.DateOfShipment,
		UnloadedTable,
		Object.RegistrationOption);
		
	FillInCompletedDocuments(DesignResult_);
	
	CommonClientServer.SetDynamicListParameter(ListDocuments, "Documents", DesignResult_.Documents);
	For Each Error In DesignResult_.Messages Do
		CommonClientServer.MessageToUser(Error.Text, Error.DataKey, Error.Field, Error.DataPath);
	EndDo;
	
	Return DesignResult_.Count();
	
EndFunction

&AtServer
Procedure FillInCompletedDocuments(DesignResult_)
	
	CompletedDocuments_4.Clear();
	For Each Item In DesignResult_.Documents Do
		CompletedDocuments_4.Add().Document = Item;
	EndDo;
	CompletedDocuments_3 = CompletedDocuments_4.Count();
	
EndProcedure

&AtClient
Procedure ProductsQuantityWhenChangingNotificationProcessing(Result, AdditionalParameters) Export
	
	CurrentData = Items.Goods.CurrentData;
	
	If TypeOf(Result) = Type("Structure") Then
		
		CurrentData.Count = Result.ForTransfer;
		CurrentData.Mark = Result.ForTransfer > 0;
		
		GetDecryptionDataFromTemporaryStorage(Items.Goods.CurrentRow, Result.DetailsData);
		ShoppingCartWarehousesWhenChangingProductsQuantity();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure GetDecryptionDataFromTemporaryStorage(Id, AddressInStorage)
	
	DetailsData = GetFromTempStorage(AddressInStorage);
	CurrentData = Object.Goods.FindByID(Id);
	CurrentData.DetailedRecords.Load(DetailsData);
	
EndProcedure

&AtServer
Function PlaceDecryptionDataInTemporaryStorage(Id)
	
	CurrentData = Object.Goods.FindByID(Id);
	Table = CurrentData.DetailedRecords.Unload();
	Return PutToTempStorage(Table);
	
EndFunction

&AtClient
Procedure ShoppingCartWarehousesBeforeChangingProductsQuantity()
	
	ShoppingCartWarehousesFillInCachedValues();
	
EndProcedure

&AtClient
Procedure ShoppingCartWarehousesWhenChangingProductsQuantity()
	
	// The cached values were filled in in the "before change" procedure.
	ShoppingCartReflectChanges("-");
	ShoppingCartWarehousesFillInCachedValues();
	ShoppingCartReflectChanges("+");
	
	ForDeletion = WarehouseCart.FindRows(New Structure("FrequencyOfLines", 0));
	For Each String In ForDeletion Do
		WarehouseCart.Delete(String);
	EndDo;
	
EndProcedure

&AtClient
Procedure ShoppingCartWarehousesFillInCachedValues()
	
	DetailedRecords = Items.Goods.CurrentData.DetailedRecords;
	
	WarehouseCartCachedValues.Clear();
	For Each TableRow In DetailedRecords Do
		
		FillPropertyValues(WarehouseCartCachedValues.Add(), TableRow);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ShoppingCartReflectChanges(Character)
	
	NumberSign_ = ?(Character = "+", 1, -1);
	
	CurrentData = Items.Goods.CurrentData;
	FilterParameters = New Structure("Warehouse");
	For Each ArrayElement In WarehouseCartCachedValues Do
		
		FilterParameters.Warehouse = ArrayElement.Warehouse;
		
		FoundRows = WarehouseCart.FindRows(FilterParameters);
		
		If Character = "+" And FoundRows.Count() = 0 Then
			
			FoundRow = WarehouseCart.Add();
			FoundRow.Warehouse = ArrayElement.Warehouse;
			
		Else
			
			FoundRow = FoundRows[0];
			
		EndIf;
		
		FoundRow.Weight   = FoundRow.Weight   + NumberSign_ * CurrentData.UnitWeight   * ArrayElement.ForTransfer;
		FoundRow.VolumeM3 = FoundRow.VolumeM3 + NumberSign_ * CurrentData.UnitVolume * ArrayElement.ForTransfer;
		FoundRow.FrequencyOfLines = FoundRow.FrequencyOfLines + NumberSign_;
		
		FoundRow.FrequencyOfLinesWithZeroWeight = FoundRow.FrequencyOfLinesWithZeroWeight
			+ NumberSign_ * ?(CurrentData.UnitWeight = 0, 0, 1);
			
		FoundRow.FrequencyOfLinesWithZeroVolume = FoundRow.FrequencyOfLinesWithZeroVolume
			+ NumberSign_ * ?(CurrentData.UnitVolume = 0, 0, 1);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure OpenQuantityEntryForm()
	
	CurrentData = Items.Goods.CurrentData;
	
	CallbackDescription = New CallbackDescription("ProductsQuantityWhenChangingNotificationProcessing", ThisForm);
	FormParameters = New Structure();
	AddSelectionFields_(FormParameters);
	FormParameters.Insert("DetailsData",     PlaceDecryptionDataInTemporaryStorage(CurrentData.GetID()));
	
	OpenForm("DataProcessor.TransferOfAssignedGoods.Form.QuantityDetails",
		FormParameters, ThisForm,,,, CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region ListDocuments

&AtServer
Procedure AddJoinSection(QueryText)
	
	If QueryText <> "" Then
		QueryText = QueryText + "
		|
		|UNION ALL
		|
		|";
	EndIf;
	
EndProcedure

&AtClient
Procedure SetStatus(Command)
	
	DocumentType = Undefined;
	
	If Command = Commands.SetTheStatusOfMoveToCompleteOrders.Name Then
		
		DocumentType = Type("DocumentRef.TransferOrder");
		Status = PredefinedValue("Enum.InternalOrderStatuses.ForCompletion");
		
	ElsIf Command = Commands.SetTheStatusOfProductMovementsShipped.Name Then
		
		DocumentType = Type("DocumentRef.InventoryTransfer");
		Status = PredefinedValue("Enum.GoodsTransferStatuses.Shipped");
		
	ElsIf Command = Commands.SetTheStatusOfProductMovementsAccepted.Name Then
		
		DocumentType = Type("DocumentRef.InventoryTransfer");
		Status = PredefinedValue("Enum.GoodsTransferStatuses.Accepted");
	ElsIf Command = Commands.SetTheStatusOfMaterialOrdersToBeCompleted.Name Then
		
		DocumentType = Type("DocumentRef.OrderOfMaterialsForProduction");
		Status = PredefinedValue("Enum.StatusesOfOrdersForMaterialsForProduction.ForCompletion");
		
	ElsIf Command = Commands.SetTheStatusOfMaterialTransfersShipped.Name Then
		
		DocumentType = Type("DocumentRef.MovementOfProductsAndMaterials");
		Status = PredefinedValue("Enum.StatusesOfProductsAndMaterialMovement.Shipped");
		
	ElsIf Command = Commands.SetTheStatusOfMaterialTransfersAccepted.Name Then
		
		DocumentType = Type("DocumentRef.MovementOfProductsAndMaterials");
		Status = PredefinedValue("Enum.StatusesOfProductsAndMaterialMovement.Accepted");
	EndIf;
	
	ReferencesArrray = New Array();
	
	For Each String In Items.ListDocuments.SelectedRows Do
		
		DocumentReference = Items.ListDocuments.RowData(String).Ref;
		If TypeOf(DocumentReference) = DocumentType Then
			
			ReferencesArrray.Add(DocumentReference);
			
		EndIf;
		
	EndDo;
	SetStatusOnServer(ReferencesArrray, Status);
	Items.ListDocuments.Refresh();
	
EndProcedure

&AtServer
Procedure SetStatusOnServer(ReferencesArrray, Status)
	
	Status = Common.ObjectManagerByRef(Status).IndexOf(Status);
	TotalRefs = ReferencesArrray.Count();
	
	For Counter = 1 To TotalRefs Do
		
		CurArrayElement_ = ReferencesArrray[TotalRefs - Counter];
		If CompletedDocuments_4.FindRows(New Structure("Document", CurrentItem)) = 0 Then
			
			ReferencesArrray.Delete(CurArrayElement_);
			
		EndIf;
		
	EndDo;
	
	SetStatusByArrayOfLinks(ReferencesArrray, Status);
	
EndProcedure

&AtClient
Procedure WriteAtClient(Command)
	
	ReferencesArrray = New Array();
	
	For Each String In Items.ListDocuments.SelectedRows Do
		
		DocumentReference = Items.ListDocuments.RowData(String).Ref;
		ReferencesArrray.Add(DocumentReference);
		
	EndDo;
	WriteAtServer(ReferencesArrray, Command.Name);
	Items.ListDocuments.Refresh();
	
EndProcedure

&AtServer
Procedure WriteAtServer(ReferencesArrray, Action)
	
	TotalRefs = ReferencesArrray.Count();
	
	For Counter = 1 To TotalRefs Do
		
		CurArrayElement_ = ReferencesArrray[TotalRefs - Counter];
		If CompletedDocuments_4.FindRows(New Structure("Document", CurrentItem)) = 0 Then
			
			ReferencesArrray.Delete(CurArrayElement_);
			
		EndIf;
		
	EndDo;
	
	BlockErrorTemplate     = NStr("vi = 'Không thể khóa %Document%. %ErrorDescription%';
									|ru = 'Не удалось заблокировать %Document%. %ErrorDescription%';
									|en = 'Failed to lock %Document%. %ErrorDescription%'; fa = 'Failed to lock %Document%. %ErrorDescription%';
									|it = 'Non è stato possibile bloccare %Document%. %ErrorDescription%';
									|pl = 'Nie udało się zablokować %Document%, %ErrorDescription%';
									|tr = '%Document% engellenemedi. %ErrorDescription%'");
	WriteErrorTemplate          = NStr("vi = 'Không thể ghi %Document%. %ErrorDescription%';
										|ru = 'Не удалось записать %Document%. %ErrorDescription%';
										|en = 'Failed to save %Document%. %ErrorDescription%'; fa = 'Failed to save %Document%. %ErrorDescription%';
										|it = 'Non è stato possibile registrare %Document%. %ErrorDescription%';
										|pl = 'Nie udało się zapisać %Document%. %ErrorDescription%';
										|tr = '%Document% kaydedilemedi. %ErrorDescription%'");
	
	For Each Ref In ReferencesArrray Do
		
		// Capturing an object for editing
		Try
			LockDataForEdit(Ref);
		Except
			ErrorText = StrReplace(BlockErrorTemplate, "%Document%", Ref);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
			CommonClientServer.MessageToUser(ErrorText, Ref);
			Continue;
		EndTry;
		
		// Getting a Document object
		DocumentObject = Ref.GetObject();
		
		// Document recording
		Try
			
			If Action = "Post" Then
				DocumentObject.Write(DocumentWriteMode.Posting);
			ElsIf Action = "UndoPosting" Then
				DocumentObject.Write(DocumentWriteMode.UndoPosting);
			ElsIf Action = "MarkToDelete" Then
				DocumentObject.SetDeletionMark(Not DocumentObject.DeletionMark);
			EndIf;
			
		Except
			ErrorText = StrReplace(WriteErrorTemplate, "%Document%", Ref);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
			CommonClientServer.MessageToUser(ErrorText, Ref);
		EndTry;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ShowQuestionDeleteDocuments()
	
	If CompletedDocuments_3 > 0 Then
		
		Buttons = New ValueList();
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Đánh dấu xóa chứng từ đã tạo';
												|ru = 'Пометить на удаление сформированные документы';
												|en = 'Mark generated documents for deletion'; fa = 'Mark generated documents for deletion';
												|it = 'Contrassegnare per l''eliminazione i documenti generati';
												|pl = 'Zaznacz do usunięcia utworzone dokumenty';
												|tr = 'Oluşturulan belgeleri silmek için işaretle'"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		QueryText = NStr("vi = 'Khi quay trở lại, các chứng từ được tạo sẽ được đánh dấu để xóa.';
						|ru = 'При переходе назад сформированные документы будут помечены на удаление.';
						|en = 'Generated documents will be marked to deletion while going back.'; fa = 'Generated documents will be marked to deletion while going back.';
						|it = 'Tornando indietro i documenti generati verranno contrassegnati per l''eliminazione.';
						|pl = 'Podczas przejścia z powrotem utworzone dokumenty będą zaznaczone do usunięcia.';
						|tr = 'Geri döndüğünüzde, oluşturulan belgeler silinmek üzere işaretlenecektir.'");
		Response = Undefined;
		ShowQueryBox(New CallbackDescription("ProcessAnswerToDeleteDocuments", ThisObject), QueryText, Buttons);
		
	Else
		
		BackToMovableGoodsStepOnServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessAnswerToDeleteDocuments(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	BackToMovableGoodsStepOnServer();
	
EndProcedure

&AtServer
Procedure BackToMovableGoodsStepOnServer()
	
	DocumentsArray = CompletedDocuments_4.Unload().UnloadColumn("Document");
	ErrorList = TMCommonUse.SetMarkForDeletingDocuments(DocumentsArray);
	CommonClientServer.ReportErrorsToUser(ErrorList);

	Items.Tabs.CurrentPage = Items.TheItemsTab;
	Items.ThenGoToTheGeneratedDocumentsStep.DefaultButton = True;
	
EndProcedure

&AtServer
Procedure GenerateMoreOnServer()
	
	Items.Tabs.CurrentPage = Items.TabFilters;
	Items.ThenGoToTheMovedItemsStep.DefaultButton = True;
	
EndProcedure

&AtServer
Procedure SetStatusByArrayOfLinks(ReferencesArrray, Status)
	
	BlockErrorTemplate     = NStr("vi = 'Không thể khóa %Document%. %ErrorDescription%';
									|ru = 'Не удалось заблокировать %Document%. %ErrorDescription%';
									|en = 'Failed to lock %Document%. %ErrorDescription%'; fa = 'Failed to lock %Document%. %ErrorDescription%';
									|it = 'Non è stato possibile bloccare %Document%. %ErrorDescription%';
									|pl = 'Nie udało się zablokować %Document%, %ErrorDescription%';
									|tr = '%Document% engellenemedi. %ErrorDescription%'");
	WriteErrorTemplate          = NStr("vi = 'Không thể ghi %Document%. %ErrorDescription%';
										|ru = 'Не удалось записать %Document%. %ErrorDescription%';
										|en = 'Failed to save %Document%. %ErrorDescription%'; fa = 'Failed to save %Document%. %ErrorDescription%';
										|it = 'Non è stato possibile registrare %Document%. %ErrorDescription%';
										|pl = 'Nie udało się zapisać %Document%. %ErrorDescription%';
										|tr = '%Document% kaydedilemedi. %ErrorDescription%'");

	For Each Ref In ReferencesArrray Do
		
		// Capturing an object for editing
		Try
			LockDataForEdit(Ref);
		Except
			ErrorText = StrReplace(BlockErrorTemplate, "%Document%", Ref);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
			CommonClientServer.MessageToUser(ErrorText, Ref);
			Continue;
		EndTry;
		
		// Getting a Document object
		DocumentObject = Ref.GetObject();
		
		// Setting the document status
		If Not DocumentObject.SetStatus(Status, Undefined) Then
			Continue;
		EndIf;
			
		// Document recording
		Try
			
			DocumentObject.Write(?(DocumentObject.Posted, DocumentWriteMode.Posting, DocumentWriteMode.Write));
			
		Except
			ErrorText = StrReplace(WriteErrorTemplate, "%Document%", Ref);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
			CommonClientServer.MessageToUser(ErrorText, Ref);
		EndTry;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region ConfiguringVisibilityAndAppearance

&AtServer
Procedure OnChangeAttributes(TagName = Undefined)
	
	If TagName = Undefined Then
		
		Items.DateOfNextShipment.Visible = OrderingByShipmentDate;
		Items.DemandsBeforeDate.Visible = OrderingByShipmentDate;
		
	EndIf;
		
	If TagName = Undefined Or TagName = Items.Mode.Name Then
		
		If Mode = Items.Mode.ChoiceList[0].Value Then
			
			Title = NStr("vi = 'Di chuyển hàng hóa riêng biệt: Phân bổ tồn kho';
						|ru = 'Перемещение обособленных товаров: Распределение остатков';
						|en = 'Assigned goods transfer: Stock allocation'; fa = 'Assigned goods transfer: Stock allocation';
						|it = 'Assigned goods transfer: Stock allocation';
						|pl = 'Assigned goods transfer: Stock allocation';
						|tr = 'Ayrılmış ürünlerin transferi: Bakiyelerin dağıtımı'");
			Items.PagesMode.CurrentPage = Items.PagesMode.ChildItems.PageModeBalanceAllocation;
			Items.SourceWarehouse.Visible = False;
			Items.DestinationWarehouse.Visible  = True;
			Items.GoodsSourceWarehouse.Visible = False;
			Items.GoodsDestinationWarehouse.Visible  = True;
			
			// Rearranging columns in the "Goods" table in the following order:
			// Available -> To move -> Warehouse-recipient -> Date of need -> Need.
			Items.Move(Items.GoodsAvailable, Items.ColumnsBeforeForTransfer);
			Items.Move(Items.GoodsDestinationWarehouse, Items.ColumnsAfterForTransfer);
			Items.Move(Items.GoodsDemandDate, Items.ColumnsAfterForTransfer);
			Items.Move(Items.GoodsDemand,     Items.ColumnsAfterForTransfer);
			Items.GoodsDemandDate.Title = NStr("vi = 'Ngày yêu cầu';
												|ru = 'Дата потребности';
												|en = 'Demand date'; fa = 'تاریخ تقاضا';
												|it = 'Data del fabbisogno';
												|pl = 'Data zapotrzebowania';
												|tr = 'Gereksinim tarihi'");
			Items.WarehouseCartWarehouse.Title = NStr("vi = 'Kho nhận';
														|ru = 'Склад-получатель';
														|en = 'Destination warehouse'; fa = 'انبار مقصد';
														|it = 'Magazzino-destinatario';
														|pl = 'Destination warehouse';
														|tr = 'Hedef ambar'");
			
		ElsIf Mode = Items.Mode.ChoiceList[1].Value Then
			
			Title = NStr("vi = 'Di chuyển hàng hóa riêng biệt: Đáp ứng nhu cầu';
						|ru = 'Перемещение обособленных товаров: Обеспечение потребностей';
						|en = 'Assigned goods transfer: Demand fulfillment'; fa = 'Assigned goods transfer: Demand fulfillment';
						|it = 'Assigned goods transfer: Demand fulfillment';
						|pl = 'Assigned goods transfer: Demand fulfillment';
						|tr = 'Atanmış ürünlerin transferi: Talep karşılama'");
			Items.PagesMode.CurrentPage = Items.PagesMode.ChildItems.PageModeDemandFulfillment;
			Items.SourceWarehouse.Visible = True;
			Items.DestinationWarehouse.Visible  = False;
			Items.GoodsSourceWarehouse.Visible = True;
			Items.GoodsDestinationWarehouse.Visible  = False;
			
			// Rearranging columns in the "Products" table in the following order:
			// Date of need -> Need -> To be moved -> Available -> Warehouse-Sender.
			Items.Move(Items.GoodsDemandDate, Items.ColumnsBeforeForTransfer);
			Items.Move(Items.GoodsDemand,     Items.ColumnsBeforeForTransfer);
			Items.Move(Items.GoodsAvailable,   Items.ColumnsAfterForTransfer);
			Items.Move(Items.SourceWarehouse, Items.ColumnsAfterForTransfer);
			Items.GoodsDemandDate.Title = NStr("vi = 'Ngày yêu cầu (tối thiểu)';
												|ru = 'Дата потребности (минимальная)';
												|en = 'Demand date (minimal)'; fa = 'Demand date (minimal)';
												|it = 'Data di fabbisogno (minima)';
												|pl = 'Data zapotrzebowania (minimalna)';
												|tr = 'Gereksinim tarihi (minimum)'");
			Items.WarehouseCartWarehouse.Title = NStr("vi = 'Kho gửi';
														|ru = 'Склад-отправитель';
														|en = 'Origin warehouse'; fa = 'انبار مبدأ';
														|it = 'Magazzino-mittente';
														|pl = 'Origin warehouse';
														|tr = 'Çıkış ambarı'");
			
		EndIf;
		
	EndIf;
	
	If TagName = Undefined Or TagName = Items.Purpose.Name Then
		
		Items.GoodsPurpose.Visible = Not ValueIsFilled(Object.Purpose);
		
	EndIf;
	
	If TagName = Undefined Then
		
		NumberOfAvailableDesignOptions = Items.RegistrationOption.ChoiceList.Count();
		Items.RegistrationOption.Enabled = NumberOfAvailableDesignOptions > 1;
		Items.ThenGoToTheMovedItemsStep.Enabled = NumberOfAvailableDesignOptions > 0;
		
	EndIf;
	ShouldSaveSettings();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	// The standard design of the "Date" field.
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ListDocuments.Date", "ListDocumentsDate");
	
	// The inscription <not installed>, if the sending warehouse is not a source of security for the receiving warehouse.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsTransferDurationDays.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SuppliedByTransfer");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được thiết lập>';
													|ru = '<не установлен>';
													|en = '<not set>'; fa = '<تنظیم نشده>';
													|it = '<non impostato>';
													|pl = '<nie ustawiony>';
													|tr = '<ayarlanmadı>'"));
	
	// Registration of overdue dates of need.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDemandDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.WillGoToSchool");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);
	
	// Registration of an empty need date.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDemandDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SeveralDemandDates");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<vài ngày>';
													|ru = '<несколько дат>';
													|en = '<several dates>'; fa = '<several dates>';
													|it = '<alcune date>';
													|pl = '<kilka dat>';
													|tr = '<çoklu tarih>'"));
	
	// Registration of an empty sender warehouse.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSourceWarehouse.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SourceWarehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<nhiều kho>';
													|ru = '<несколько складов>';
													|en = '<several warehouses>'; fa = '<several warehouses>';
													|it = '<alcuni magazzini>';
													|pl = '<kilka magazynów>';
													|tr = '<birden fazla ambar>'"));
	
	// The design of the group "To move".
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsMark.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCount.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.DestinationWarehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsMark.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCount.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SourceWarehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// The design of the group "To move - hyperlink".
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsMarkViewOnly.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsQuantityHyperlink.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.DestinationWarehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SourceWarehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

#EndRegion

#Region SwitchingBetweenBookmarksInBackgroundJob

&AtServer
Procedure StartExecutionInBackground(ExecutionContext, JobDescription)
	
	ExecutionContextInTheBackground = ExecutionContext;
	
	JobParameters = New Structure;
	
	FillingData = DataProcessors.TransferOfAssignedGoods.StructureFillingData();
	FillPropertyValues(FillingData, Object);
	
	JobParameters.Insert("ThisIsDistributionOfResiduals", Mode = Items.Mode.ChoiceList[0].Value);
	JobParameters.Insert("FillingData",         FillingData);
	JobParameters.Insert("Goods",                   Object.Goods.Unload(New Array));
	JobParameters.Insert("WarehouseCart",           WarehouseCart.Unload(New Array));
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	
	If ExecutionContextInTheBackground = Items.ThenGoToTheMovedItemsStep.Name Then
		
		BackgroundExecutionResult = TimeConsumingOperations.ExecuteInBackground(
			"DataProcessors.TransferOfAssignedGoods.MovingItemsToTable",
			JobParameters,
			ExecutionParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterExecutionAlertIsDisplayedInBackground(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		AfterExecutionInBackground();
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterExecutionInBackground()
	
	If ExecutionContextInTheBackground = Items.ThenGoToTheMovedItemsStep.Name Then
		
		FillingData = GetFromTempStorage(BackgroundExecutionResult.ResultAddress);
		
		Object.Goods.Load(FillingData.Goods);
		For IndexOf = 0 To FillingData.Goods.Count() - 1 Do
			
			Object.Goods[IndexOf].DetailedRecords.Load(FillingData.Goods[IndexOf].DetailedRecords);
			
		EndDo;
		
		WarehouseCart.Load(FillingData.WarehouseCart);
		
		Items.Tabs.CurrentPage = Items.TheItemsTab;
		Items.ThenGoToTheMovedItemsStep.DefaultButton = True;
		
		// Setting the request text and the parameters of the list of issued documents.
		ListOfDocumentsWhenChangingDesignOption();
		ListDocuments.Parameters.SetParameterValue("Documents", Undefined);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterStartingExecutionInBackground()
	
	If BackgroundExecutionResult.Status = "Completed2" Then
		AfterExecutionInBackground();
	Else
		OpenTimeConsumingOperationForm = True;
	EndIf;
	
EndProcedure

#EndRegion

&AtServerNoContext
Function DetailedRecords(FillParameters, QuantityPerLine, Mark)
	
	Count = ?(Mark, QuantityPerLine, 0);
	ResultStructure1 = DataProcessors.TransferOfAssignedGoods.DetailedRecords(FillParameters);
	
	DetailedRecords = ResultStructure1.DetailedRecords;
	
	If FillParameters.Mode = "StockAllocation" Then
		
		QuantityIsAvailable = Min(ResultStructure1.QuantityIsAvailable, Count);
		For Each TableRow In DetailedRecords Do
			
			If TableRow.ThisIsOutsideThePeriodLimit = True Or QuantityIsAvailable <= 0 Then
				Break;
			EndIf;
			
			TableRow.ForTransfer = Min(TableRow.Demand, QuantityIsAvailable);
			QuantityIsAvailable = QuantityIsAvailable - TableRow.ForTransfer;
			
		EndDo;
		
		// Finishing the last line to the desired one.
		If Count > ResultStructure1.QuantityIsAvailable Then
			TableRow.ForTransfer = TableRow.ForTransfer + Count - ResultStructure1.QuantityIsAvailable;
		EndIf;
		
	ElsIf FillParameters.Mode = "Demand_fulfillment" Then
		
		QuantityNeed = Min(ResultStructure1.QuantityNeed, Count);
		For Each TableRow In DetailedRecords Do
			
			If TableRow.ThisIsOutsideThePeriodLimit = True Or QuantityNeed <= 0 Then
				Break;
			EndIf;
			
			TableRow.ForTransfer = Min(TableRow.Available, QuantityNeed);
			QuantityNeed = QuantityNeed - TableRow.ForTransfer;
			
		EndDo;
		
		// Finishing the last line to the desired one.
		If Count > ResultStructure1.QuantityNeed Then
			TableRow.ForTransfer = TableRow.ForTransfer + Count - ResultStructure1.QuantityNeed;
		EndIf;
		
	EndIf;
	
	Result = New Array();
	Columns = "Period,ForTransfer,Warehouse,WarehouseName,DemandDate";
	
	For Each TableRow In DetailedRecords Do
		
		If TableRow.ForTransfer > 0 Then
			
			Item = New Structure(Columns);
			FillPropertyValues(Item, TableRow);
			Result.Add(Item);
			
		EndIf;
		
	EndDo;
	Return Result;
	
EndFunction

&AtClient
Procedure AddSelectionFields_(ParametersStructure)
	
	CurrentData = Items.Goods.CurrentData;
	ParametersStructure.Insert("SourceWarehouse",      Object.SourceWarehouse);
	ParametersStructure.Insert("DestinationWarehouse",       Object.DestinationWarehouse);
	ParametersStructure.Insert("DateOfNextShipment", Object.DateOfNextShipment);
	ParametersStructure.Insert("DemandsBeforeDate",     Object.DemandsBeforeDate);
	ParametersStructure.Insert("DateOfShipment",          Object.DateOfShipment);
	ParametersStructure.Insert("Products",          CurrentData.Products);
	ParametersStructure.Insert("Characteristic",        CurrentData.Characteristic);
	ParametersStructure.Insert("Purpose",            CurrentData.Purpose);
	ParametersStructure.Insert("Mode",                 Mode);
	ParametersStructure.Insert("RegistrationOption",     Object.RegistrationOption);
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	If Parameters.TheDetailsOfTheContext <> Undefined Then
		
		PartOfSettingsNotSubjectToChange = CommonClientServer.CopyStructure(Parameters.TheDetailsOfTheContext);
		FillPropertyValues(PartOfSettingsNotSubjectToChange, SavedValues[Parameters.TheDetailsOfTheContext.Mode]);
		
		SettingValues = SavedValues[Parameters.TheDetailsOfTheContext.Mode];
		FillPropertyValues(SettingValues, Object);
		FillPropertyValues(SettingValues, PartOfSettingsNotSubjectToChange);
		
	Else
		
		SavedValues.Mode = Mode;
		SettingValues = SavedValues[SavedValues.Mode];
		FillPropertyValues(SettingValues, Object);
		
	EndIf;
	
	Common.CommonSettingsStorageSave("DataProcessor.TransferOfAssignedGoods", "Main", SavedValues);

EndProcedure

&AtServer
Procedure RestoreSettings()

	SavedValues = Common.CommonSettingsStorageLoad("DataProcessor.TransferOfAssignedGoods", "Main");
	If SavedValues = Undefined Then
		
		StructureDistributionOfResidue = New Structure();
		StructureProvisionOfNeeds = New Structure();
		
		SavedValues = New Structure();
		SavedValues.Insert(Items.Mode.ChoiceList[0].Value, StructureDistributionOfResidue);
		SavedValues.Insert(Items.Mode.ChoiceList[1].Value, StructureProvisionOfNeeds);
		SavedValues.Insert("Mode", Items.Mode.ChoiceList[0].Value);
		
		For Each MetadataProps In Metadata.DataProcessors.TransferOfAssignedGoods.Attributes Do
			
			StructureDistributionOfResidue.Insert(MetadataProps.Name);
			StructureProvisionOfNeeds.Insert(MetadataProps.Name);
			
		EndDo;
		
	EndIf;
	
	If Parameters.TheDetailsOfTheContext <> Undefined Then
		
		Mode = Parameters.TheDetailsOfTheContext.Mode;
		FillPropertyValues(Object, SavedValues[Mode]);
		FillPropertyValues(Object, Parameters.TheDetailsOfTheContext);
		
	Else
		
		Mode = SavedValues.Mode;
		FillPropertyValues(Object, SavedValues[Mode]);
		
	EndIf;
	
	If Object.DateOfShipment < BegOfDay(CurrentSessionDate()) Then
		
		Object.DateOfShipment          = CurrentSessionDate();
		Object.DateOfNextShipment = '00010101';
		Object.DemandsBeforeDate     = '00010101';
		
		If OrderingByShipmentDate Then
			Object.DateOfNextShipment = '00010101';
			Object.DemandsBeforeDate     = '00010101';
		EndIf;
		
	EndIf;
	
	// Bringing the design option to an acceptable value.
	AvailableDesignOptions = Items.RegistrationOption.ChoiceList.UnloadValues();
	If AvailableDesignOptions.Find(Object.RegistrationOption) = Undefined Then
		
		If AvailableDesignOptions.Count() > 0 Then
			Object.RegistrationOption = AvailableDesignOptions[0];
		Else
			Object.RegistrationOption = Enums.OptionsOfRegisteringTransferDocuments.EmptyRef();
		EndIf;
		
	EndIf;
	
	// Context-sensitive configuration of the form.
	OnChangeAttributes();

EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_DateOfShipment" Then
		ShipDateModeOfDistributionOfTheResiduesOnChange(Items.ShipDateModeOfDistributionOfTheResidues);
	ElsIf Item.Name = "sh_ShamsiInput_DateOfNextShipment" Then
		DateOfNextShipmentOnChange(Items.DateOfNextShipment);
	ElsIf Item.Name = "sh_ShamsiInput_DemandsBeforeDate" Then
		DemandsBeforeDateOnChange(Items.DemandsBeforeDate);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
