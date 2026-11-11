
#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	UseSeveralWarehouses = GetFunctionalOption("UseSeveralWarehouses");
	Attributes = Common.ObjectAttributesValues(Object.Purpose, "OrderDocument,Contract");
	Contract = Attributes.Contract;
	OrderDocument = Attributes.OrderDocument;
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	If Not Documents.InventoryAssignmentAdjustment.ChangeOptionAvailable(Object.Ref) Then
		ReadOnly = True;
		Items.OrderDocument.ReadOnly = True;
	EndIf;
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	SetDestinationSelectionParameters();
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)

	If ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then
		
		ProcessingSelectionServerGetStockTypes(ValueSelected, ChoiceSource.InventoryOwnerAttributesAreSpecifiedManually);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.AssignmentAdjustmentFilling.Form.ObjectForm" Then
		
		If Object.Goods.Count() > 0 Then
			
			DescriptionOfAlertForQuestion = New CallbackDescription(
				"AssignmentAdjustmentFillingCompletion",
				ThisObject,
				ValueSelected);
			
			ShowQueryBox(
				DescriptionOfAlertForQuestion,
				NStr("vi = 'Bảng hàng hóa sẽ bị xóa. Tiếp tục?';
					|ru = 'Таблица товаров будет очищена. Продолжить?';
					|en = 'The Goods tab will be cleared. Do you want to continue?'; fa = 'The Goods tab will be cleared. Do you want to continue?';
					|it = 'La tabella delle merci verrà cancellata. Continuare?';
					|pl = 'Tabela towarów będzie oczyszczona. Kontynuować?';
					|tr = 'Ürünler tablosu temizlenecektir. Devam edilsin mi?'"),
				QuestionDialogMode.YesNo);
			
			Return;
		Else
			FillingInDestinationAdjustmentCompletionOnServer(ValueSelected);
		EndIf;
		
	ElsIf ChoiceSource.FormName = "Document.InventoryAssignmentAdjustment.Form.SelectAssignment" Then
		
		PurposeOnChangeServer(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		HandlingSelectionSelectionOnClient(ValueSelected);
		
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInServiceDetails();
	FormEvents.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	FormEventsClient.AfterWrite(ThisObject, WriteParameters);
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)

	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)

	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	DateOnChangeServer();
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
		
	If ThisObject.PropertiesParameters.Property(CurrentPage.Name)
			And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
			
			PropertiesExecuteDeferredInitialization();
			PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure OperationKindChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If Object.OperationKind <> ValueSelected Then
		ShowQueryBox(New CallbackDescription("OperationKindChoiceProcessingCompletion", ThisObject, ValueSelected), NStr("vi = 'Bảng hàng hóa sẽ bị xóa. Tiếp tục?';
																														|ru = 'Таблица товаров будет очищена. Продолжить?';
																														|en = 'The Goods tab will be cleared. Do you want to continue?'; fa = 'The Goods tab will be cleared. Do you want to continue?';
																														|it = 'La tabella delle merci verrà cancellata. Continuare?';
																														|pl = 'Tabela towarów będzie oczyszczona. Kontynuować?';
																														|tr = 'Ürünler tablosu temizlenecektir. Devam edilsin mi?'"), QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

&AtClient
Procedure OrderDocumentStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = New Structure("Organization", Object.Organization);
	OpenForm("Document.InventoryAssignmentAdjustment.Form.SelectAssignment", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure OrderDocumentOnChange(Item)
	
	If Not ValueIsFilled(OrderDocument) Then
		Object.Purpose = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure OrderDocumentClearing(Item, StandardProcessing)
	
	Object.Purpose = Undefined;
	
EndProcedure

&AtClient
Procedure PurposeStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = New Structure("Organization", Object.Organization);
	OpenForm("Document.InventoryAssignmentAdjustment.Form.SelectAssignment", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure PurposeOnChange(Item)
	PurposeOnChangeServer(Object.Purpose);
EndProcedure

&AtClient
Procedure BaseLabelClick(Item)
	
	OpenListOfAppointments();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	UpdateOrderInformation();
EndProcedure

&AtClient
Procedure GoodsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	If Not CancelEdit Then
		FillInAssignmentForNewLine(Items.Goods.CurrentData, Object, OrderDocument);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	AttachIdleHandler("Attachable_UpdateOrderInformation", 1, True);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsNewAssignmentOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInDestinationAttribute", "NewAssignment");
	StructureOfActions.Insert("FillInTrafficFlagForWarehouseRegisters", "AssignmentOfNewRecordInWarehouseRegisters");
	
	ActionParameters = New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", ActionParameters);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value                   = Items.Goods.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.Goods.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);

EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	ProductsProductsWhenChangedOnServer(CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, False));
	
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsInitialAssignmentOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	ActionParameters = New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", ActionParameters);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentRowIndex = Items.Goods.CurrentRow;
	FillInServiceDetailsInLine(CurrentRowIndex);
	
EndProcedure

&AtClient
Procedure GoodsWarehouseOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	ActionParameters = New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", ActionParameters);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentRowIndex = Items.Goods.CurrentRow;
	FillInServiceDetailsInLine(CurrentRowIndex);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPremiseOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentRowIndex = Items.Goods.CurrentRow;
	FillInServiceDetailsInLine(CurrentRowIndex);
	
EndProcedure

&AtClient
Procedure ProductsDestinationMassWithdrawalOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.Goods.CurrentData;
	
	OpeningParameters = New Structure("Key, OpenLinkedObject", CurrentRow.InitialAssignment, True);
	OpenForm("Catalog.Assignments.ObjectForm", OpeningParameters, ThisForm,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure GoodsControlledLotReferenceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Goods.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	MessageText = "";
	GetLinesFromClipboard(MessageText);
	If MessageText <> "" Then
		ShowMessageBox(, MessageText);
	EndIf;
	
	NumberOfInserted = Object.Goods.Count() - NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	FilterByProductType = ProductsClientServer.SelectionByProductMultiTurnContainer();
	HeaderParameter_ = NStr("vi = 'Chọn hàng hóa vào chứng từ điều chỉnh mục đích';
							|ru = 'Подбор товаров в документ корректировки назначения';
							|en = 'Pick goods to the assignment adjustment document'; fa = 'Pick goods to the assignment adjustment document';
							|it = 'Selezione delle merci per il documento di rettifica dell''assegnazione';
							|pl = 'Wybór towarów do dokumentu korekty przeznaczenia';
							|tr = 'Atama düzeltme belgesi içindek ürünlerin seçimi'");
	
	FormParameters = New Structure;
	FormParameters.Insert("FilterByProductType", New FixedArray(FilterByProductType));
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
	FormParameters.Insert("SelectionModeWithoutAmountParameters", True);
	FormParameters.Insert("Title", HeaderParameter_);
	FormParameters.Insert("Document", Object.Ref);
	FormParameters.Insert("AllWarehouseBalance", True);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisObject, UUID);
	
EndProcedure

&AtClient
Procedure Fill(Command)
	
	If (Object.OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve")
		Or Object.OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.ToReserve_")
		Or Object.OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment")) Then
			
			If Not ValueIsFilled(Object.Purpose) Then
		
				TextReservationWithdrawal = ?(Object.OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve")
					, NStr("vi = 'Không thể rút dự phòng';
							|ru = 'Снятие резерва невозможно.';
							|en = 'Unable to remove from reserve.'; fa = 'Unable to remove from reserve.';
							|it = 'Rimozione della prenotazione non è possibile.';
							|pl = 'Usunięcie rezerwy jest niemożliwe.';
							|tr = 'Rezervasyonun kaldırılması mümkün değil.'"), NStr("vi = 'Lập dự phòng là không thể.';
																			|ru = 'Резервирование невозможно.';
																			|en = 'Assignment is impossible.'; fa = 'Assignment is impossible.';
																			|it = 'La prenotazione non è possibile.';
																			|pl = 'Rezerwowanie jest niemożliwe';
																			|tr = 'Rezervasyon mümkün değil.'"));
				
				TextAssignmentOrder = ?(ThereMayBeAppointmentsWithoutAnOrder, 
					NStr("vi = 'Cần thiết chọn một điểm đến.';
						|ru = 'Необходимо выбрать назначение.';
						|en = 'Select the assignment.'; fa = 'Select the assignment.';
						|it = 'È necessario selezionare una destinazione.';
						|pl = 'Należy wybrać przeznaczenia.';
						|tr = 'Atama seçilmeli.'"), NStr("vi = 'Cần thiết chọn một lệnh.';
																|ru = 'Необходимо выбрать заказ.';
																|en = 'Select the order.'; fa = 'Select the order.';
																|it = 'È necessario selezionare un ordine.';
																|pl = 'Należy wybrać zamówienie.';
																|tr = 'Sipariş seçilmeli.'"));
				
				RejectionText = TextReservationWithdrawal + " " + TextAssignmentOrder;
				
				ShowMessageBox(, RejectionText);
				Return;
				
			EndIf;
			
	EndIf;
	
	If Object.OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve") Then
		
		If Not ThereAreGoodsToWithdrawReserve() Then
			
			WarningText = NStr("vi = 'Theo mục đích này không có sẵn sàng hóa đặt riêng. Không thể thực hiện lệnh.';
								|ru = 'По данному назначению нет в наличии обособленных товаров. Команда не может быть выполнена.';
								|en = 'Assigned goods of this assignment are out of stock. Cannot execute the command.'; fa = 'Assigned goods of this assignment are out of stock. Cannot execute the command.';
								|it = 'Non ci sono merci separate disponibili per questa assegnazione. Impossibile eseguire il comando.';
								|pl = 'Wg tego przeznaczenia nie ma dostępnych oddzielnych towarów. Polecenie nie może być wykonane.';
								|tr = 'Bu hedef için ayrı bir ürün bulunmamaktadır. Komut yürütülemedi.'");
			ShowMessageBox(, WarningText);
			
			Return;
			
		EndIf;
		
	ElsIf Object.OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.ToReserve_")
		Or Object.OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment") Then
			
			If Not ThereAreGoodsToSeparateProvision() Then
				
				WarningText = NStr("vi = 'Theo mục đích này không có nhu cầu. Cần thêm thủ công các dòng vào chứng từ.';
									|ru = 'По данному назначению нет потребностей. Необходимо добавить строки в документ вручную.';
									|en = 'No demands for this assignment. Add lines to the document manually.'; fa = 'No demands for this assignment. Add lines to the document manually.';
									|it = 'Non ci sono fabbisogni per questa assegnazione. È necessario aggiungere manualmente le righe nel documento.';
									|pl = 'Wg tego przeznaczenia nie ma zapotrzebowania. Należy dodać wiersze do dokumentu ręcznie.';
									|tr = 'Bu görev için herhangi bir gereksinim yoktur. Belgeye manuel olarak satırlar eklenmeli.'");
				ShowMessageBox(, WarningText);
				
				Return;
				
			EndIf;
			
	EndIf;
	
	FormParameters = SupplyClient.ParametersOfFormForFillingInItemAssignmentAdjustment();
	FormParameters.Master_2 = False;
	FormParameters.OperationKind = Object.OperationKind;
	FormParameters.Purpose = Object.Purpose;
	FormParameters.Organization = Object.Organization;
	FormParameters.AssignmentAdjustment = Object.Ref;
	
	OpenForm("DataProcessor.AssignmentAdjustmentFilling.Form.ObjectForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure OpenInventoryKinds(Command)
	
	OptionsForEditingInventoryTypes = PutGoodsAndStockTypesInStorage();
	
	FinancesClient.OpenInventoryKinds(ThisObject, OptionsForEditingInventoryTypes);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure SpecifyDestinations(Command)
	
	CurrentData = Items.Goods.CurrentData;
	If CurrentData = Undefined Then
		WarningText = NStr("vi = 'Để chỉ ra mục đích, cần chọn dòng trong phần bảng ""Hàng hóa""';
							|ru = 'Для указания назначений необходимо выбрать строку табличной части ""Товары""';
							|en = 'To specify assignments, select the ""Goods"" table row'; fa = 'To specify assignments, select the ""Goods"" table row';
							|it = 'Selezionare la riga ""Merci"" nella tabella per indicare le assegnazioni';
							|pl = 'Aby podać przeznaczenia należy wybrać wiersz sekcji tabelarycznej ""Towary""';
							|tr = 'Atamaları belirtmek için, ""Ürünler"" tablo bölümünün satırını seç'");
		ShowMessageBox(Undefined, WarningText);
		Return;
	EndIf;
	If Not ValueIsFilled(CurrentData.Products)
			Or Not ValueIsFilled(CurrentData.Products)
			Or Not ValueIsFilled(CurrentData.Characteristic) And CurrentData.ItemVariantsAreUsed
			Or Not ValueIsFilled(CurrentData.Warehouse)
			Or Not ValueIsFilled(CurrentData.NumberOfPackages)
			Or Object.OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment")
					And Not ValueIsFilled(Object.Purpose) Then
				
				If UseSeveralWarehouses Then
					If CurrentData.ItemVariantsAreUsed Then
						WarningText = NStr("vi = 'Để chỉ ra mục đích, cần chọn mặt hàng, đặc tính, kho bãi, số lượng trong dòng của phần bảng ""Hàng hóa"" và chỉ ra mục đích trong chứng từ';
											|ru = 'Для указания назначений необходимо выбрать номенклатуру, характеристику, склад, количество в строке табличной части ""Товары"" и указать назначение в документе';
											|en = 'To specify assignments, select items, a variant, a warehouse, and quantity in the ""Goods"" table row and specify the assignment in the document'; fa = 'To specify assignments, select items, a variant, a warehouse, and quantity in the ""Goods"" table row and specify the assignment in the document';
											|it = 'Per indicare l''assegnazione è necessario selezionare l''articolo, la caratteristica, il magazzino, la quantità nella riga della tabella ""Merci"" e indicare l''assegnazione nel documento';
											|pl = 'Aby podać przeznaczenia należy wybrać wiersze pozycji, charakterystykę, magazyn, ilość w wierszu sekcji tabelarycznej ""Towary"" i podać przeznaczenie w dokumencie';
											|tr = 'Atamaları belirlemek için, ""Ürünler"" tablo bölümünün satırında ürün gamı, özellik, ambar, miktar seçmeli ve atama yeri belgede belirtilmeli'");
					Else
						WarningText = NStr("vi = 'Để chỉ ra mục đích, cần chọn mặt hàng, kho bãi, số lượng trong dòng của phần bảng ""Hàng hóa"" và chỉ ra mục đích trong chứng từ';
											|ru = 'Для указания назначений необходимо выбрать номенклатуру, склад, количество в строке табличной части ""Товары"" и указать назначение в документе';
											|en = 'To specify assignments, select items, a warehouse, and quantity in the ""Goods"" table row and specify the assignment in the document'; fa = 'To specify assignments, select items, a warehouse, and quantity in the ""Goods"" table row and specify the assignment in the document';
											|it = 'Per indicare l''assegnazione è necessario selezionare l''articolo, il magazzino, la quantità nella riga della tabella ""Merci"" e indicare l''assegnazione nel documento';
											|pl = 'Aby podać przeznaczenia należy wybrać wiersze pozycji, magazyn, ilość w wierszu sekcji tabelarycznej ""Towary"" i podać przeznaczenie w dokumencie';
											|tr = 'Atamaları belirtmek için, ""Ürünler"" tablo bölümünün satırında ürün gamı, ambarı, miktarı seçmeli ve atama belgede belirtilmeli'");
					EndIf;
				Else
					If CurrentData.ItemVariantsAreUsed Then
						WarningText = NStr("vi = 'Để chỉ ra mục đích, cần chọn mặt hàng, đặc tính, số lượng trong dòng của phần bảng ""Hàng hóa"" và chỉ ra mục đích trong chứng từ';
											|ru = 'Для указания назначений необходимо выбрать номенклатуру, характеристику, количество в строке табличной части ""Товары"" и указать назначение в документе';
											|en = 'To specify assignments, select items, a variant, and quantity in the ""Goods"" table row and specify the assignment in the document'; fa = 'To specify assignments, select items, a variant, and quantity in the ""Goods"" table row and specify the assignment in the document';
											|it = 'Per indicare l''assegnazione è necessario selezionare l''articolo, la caratteristica, la quantità nella riga della tabella ""Merci"" e indicare l''assegnazione nel documento';
											|pl = 'Aby podać przeznaczenia należy wybrać wiersze pozycji, charakterystykę, ilość w wierszu sekcji tabelarycznej ""Towary"" i podać przeznaczenie w dokumencie';
											|tr = 'Atamaları belirtmek için, ""Ürünler"" tablo bölümünün satırındaki ürün gamı, özelliği, miktarı seçmeli ve belgede atama belirtilmeli'");
					Else
						WarningText = NStr("vi = 'Để chỉ ra mục đích, cần chọn mặt hàng, số lượng trong dòng của phần bảng ""Hàng hóa"" và chỉ ra mục đích trong chứng từ';
											|ru = 'Для указания назначений необходимо выбрать номенклатуру, количество в строке табличной части ""Товары"" и указать назначение в документе';
											|en = 'To specify assignments, select items, and quantity in the ""Goods"" table row and specify the assignment in the document'; fa = 'To specify assignments, select items, and quantity in the ""Goods"" table row and specify the assignment in the document';
											|it = 'Per indicare l''assegnazione è necessario selezionare l''articolo, la quantità nella riga della tabella ""Merci"" e indicare l''assegnazione nel documento';
											|pl = 'Aby podać przeznaczenia należy wybrać wiersze pozycji, ilość w wierszu sekcji tabelarycznej ""Towary"" i podać przeznaczenie w dokumencie';
											|tr = 'Atamaları belirtmek için, ürün gamı, ""Ürünler"" tablo bölümünün satırındaki miktarı seçmeli ve atamalar belgede belirtilmeli'");
					EndIf;
				EndIf;
				
			ShowMessageBox(Undefined, WarningText);
		Return;
	EndIf;
	If Not ValueIsFilled(CurrentData.Products) Then
		WarningText = NStr("vi = 'Để chỉ ra mục đích, cần chọn mặt hàng trong dòng của phần bảng ""Hàng hóa""';
							|ru = 'Для указания назначений необходимо выбрать номенклатуру в строке табличной части ""Товары""';
							|en = 'To specify assignments, select items in the ""Goods"" table row'; fa = 'To specify assignments, select items in the ""Goods"" table row';
							|it = 'Per indicare l''assegnazione è necessario selezionare l''articolo nella riga della tabella ""Merci""';
							|pl = 'Aby podać przeznaczenia należy wybrać wiersz pozycji w wierszu sekcji tabelarycznej ""Towary""';
							|tr = 'Atamaları belirtmek için, ""Ürünler"" tablo bölümünün satırındaki ürün gamı seçilmeli.'");
		ShowMessageBox(Undefined, WarningText);
		Return;
	EndIf;
	ParametersOfAssignmentForm = New Structure();
	ParametersOfAssignmentForm.Insert("Products", CurrentData.Products);
	ParametersOfAssignmentForm.Insert("Characteristic", CurrentData.Characteristic);
	ParametersOfAssignmentForm.Insert("Warehouse", CurrentData.Warehouse);
	ParametersOfAssignmentForm.Insert("Package", CurrentData.Package);
	ParametersOfAssignmentForm.Insert("Pick", CurrentData.NumberOfPackages);
	ParametersOfAssignmentForm.Insert("Purpose", Object.Purpose);
	DescriptionAndIndicationOfAssignments = New CallbackDescription("AfterSpecifyingAssignments", ThisObject);
	OpenForm(
		"Document.InventoryAssignmentAdjustment.Form.SpecifyAssignmentsInTheTable",
		ParametersOfAssignmentForm,
		ThisObject,
		,
		,
		,
		DescriptionAndIndicationOfAssignments,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

// End StandardSubsystems.Properties

#EndRegion

#Region Private

#Region EditingProducts

&AtClient
Procedure Attachable_UpdateOrderInformation()
	UpdateOrderInformation();
EndProcedure

&AtClientAtServerNoContext
Procedure FillInAssignmentForNewLine(TableRow, Object, OrderDocument)
	
	If (Object.OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.ToReserve_")
				Or Object.OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment"))
			And Not ValueIsFilled(TableRow.NewAssignment) Then
		TableRow.NewAssignment = Object.Purpose;
		TableRow.NewOrder = OrderDocument;
	ElsIf Object.OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve")
		And Not ValueIsFilled(TableRow.InitialAssignment) Then
		TableRow.InitialAssignment = Object.Purpose;
		TableRow.SourceOrder = OrderDocument;
	EndIf;
	
EndProcedure

#EndRegion

#Region IndicationOfDestination

&AtClient
Procedure AfterSpecifyingAssignments(ClosingResult, AdditionalParameters) Export
	
	If Not ValueIsFilled(ClosingResult) Or Not ClosingResult.Property("SelectedGoods") Then
		Return;
	EndIf;
	AfterSpecifyingAssignmentsOnServer(ClosingResult.SelectedGoods);
	
EndProcedure

&AtServer
Procedure AfterSpecifyingAssignmentsOnServer(ClosingResult)
	
	CurrentData = Object.Goods.FindByID(Items.Goods.CurrentRow);
	AssignmentsTable = GetFromTempStorage(ClosingResult);
	If AssignmentsTable.Count() = 1 Then
		CurrentData.InitialAssignment = AssignmentsTable[0].Purpose;
		CurrentData.ControlledLotReference = AssignmentsTable[0].ControlledLotReference;
	Else
		RowsToProcess = New Array();
		RowIndex = Object.Goods.IndexOf(CurrentData);
		For Each String In AssignmentsTable Do
			NewRow = Object.Goods.Insert(RowIndex);
			FillPropertyValues(NewRow, CurrentData);
			NewRow.InitialAssignment = String.Purpose;
			NewRow.ControlledLotReference = String.ControlledLotReference;
			NewRow.NumberOfPackages = String.Selected;
			RowIndex = RowIndex + 1;
			RowsToProcess.Add(NewRow);
		EndDo;
		Object.Goods.Delete(CurrentData);
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("RecalculateNumberOfUnits");
		ActionParameters = New Structure(
			"Warehouse, SeriesSpecificationParameters, GoodsTable",
			PredefinedValue("Catalog.Warehouses.EmptyRef"),
			SeriesSpecificationParameters,
			Object.Goods);
			
		StructureOfActions.Insert("CheckSeriesCalculateStatus", ActionParameters);
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(RowsToProcess, StructureOfActions, Object.Goods);
		
	EndIf;
	UpdateOrderInformation();
	
EndProcedure

#EndRegion

#Region CopyAndPaste

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard(MessageText)
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer());
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,Warehouse,Premise,
		|Cell,InitialAssignment,NewAssignment,Purpose,ControlledLotReference,Series";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	If Object.OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.MutualAdjustment
			And (TableOfGoods.Columns.Find("InitialAssignment") = Undefined
				Or TableOfGoods.Columns.Find("NewAssignment") = Undefined) Then
		
		MessageText = NStr("vi = 'Команда не может быть выполнена. В документ с операцией ""Встречная корректировка"" могут быть вставлены только строки, содержащие назначение документа и встречное назначение.';
							|ru = 'Команда не может быть выполнена. В документ с операцией ""Встречная корректировка"" могут быть вставлены только строки, содержащие назначение документа и встречное назначение.';
							|en = 'Cannot run the command. You can only insert lines containing the document''s assignment and mutual assignment into a document with the ""Mutual adjustment"" transaction.'; fa = 'Cannot run the command. You can only insert lines containing the document''s assignment and mutual assignment into a document with the ""Mutual adjustment"" transaction.';
							|it = 'Команда не может быть выполнена. В документ с операцией ""Встречная корректировка"" могут быть вставлены только строки, содержащие назначение документа и встречное назначение.';
							|pl = 'Cannot run the command. You can only insert lines containing the document''s assignment and mutual assignment into a document with the ""Mutual adjustment"" transaction.';
							|tr = 'Komut çalıştırılamıyor. ""Karşılıklı düzeltme"" işlemiyle belgeye yalnızca belgenin atamasını ve karşılıklı atamasını içeren satırlar ekleyebilirsiniz.'");
		Return;
		
	EndIf;
	
	FillAssignmentFromSource = TableOfGoods.Columns.Find("Purpose") <> Undefined;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	
	RowsArray = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		YouCanInsert = True;
		
		If Object.OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.MutualAdjustment Then
			
			YouCanInsert = RowOfProduct.InitialAssignment = Object.Purpose And ValueIsFilled(RowOfProduct.NewAssignment)
				Or RowOfProduct.NewAssignment = Object.Purpose And ValueIsFilled(RowOfProduct.InitialAssignment);
			
			If Not YouCanInsert And MessageText = "" Then
				MessageText = NStr("vi = 'Не все строки удалось вставить. В документ с операцией ""Встречная корректировка"" могут быть вставлены только строки, содержащие назначение документа и встречное назначение.';
									|ru = 'Не все строки удалось вставить. В документ с операцией ""Встречная корректировка"" могут быть вставлены только строки, содержащие назначение документа и встречное назначение.';
									|en = 'Cannot add all lines. You can only insert lines containing the document''s assignment and mutual assignment into a document with the ""Mutual adjustment"" transaction.'; fa = 'Cannot add all lines. You can only insert lines containing the document''s assignment and mutual assignment into a document with the ""Mutual adjustment"" transaction.';
									|it = 'Не все строки удалось вставить. В документ с операцией ""Встречная корректировка"" могут быть вставлены только строки, содержащие назначение документа и встречное назначение.';
									|pl = 'Cannot add all lines. You can only insert lines containing the document''s assignment and mutual assignment into a document with the ""Mutual adjustment"" transaction.';
									|tr = 'Tüm satırlar eklenemiyor. ""Karşılıklı düzeltme"" işlemiyle belgeye yalnızca belgenin atamasını ve karşılıklı atamasını içeren satırlar ekleyebilirsiniz.'");
			EndIf;
		EndIf;
		
		If Not YouCanInsert Then
			Continue;
		EndIf;
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		
		If Object.OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ToReserve_ Then
			CurrentRow.InitialAssignment = Undefined;
			CurrentRow.SourceOrder = Undefined;
			CurrentRow.NewAssignment = Undefined;
			CurrentRow.NewOrder = Undefined;
		ElsIf Object.OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment Then
			CurrentRow.NewAssignment = Undefined;
			CurrentRow.NewOrder = Undefined;
		ElsIf Object.OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve Then
			CurrentRow.InitialAssignment = Undefined;
			CurrentRow.SourceOrder = Undefined;
			CurrentRow.NewAssignment = Undefined;
			CurrentRow.NewOrder = Undefined;
		ElsIf Object.OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserveForMultipleAssignments Then
			CurrentRow.InitialAssignment = Undefined;
			CurrentRow.SourceOrder = Undefined;
		EndIf;
		
		RowsArray.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsArray,
		StructureOfActions,
		Object.Goods);
		
	For Each RowOfProduct In TableOfGoods Do
		
		Documents.InventoryAssignmentAdjustment.FillInAssignmentByTypeOfOperation(
			Object.Purpose,
			OrderDocument,
			Object.OperationKind,
			CurrentRow,
			True);
			
		If FillAssignmentFromSource Then
			
			Documents.InventoryAssignmentAdjustment.FillInAssignmentByTypeOfOperation(
				RowOfProduct.Purpose,
				Undefined,
				Object.OperationKind,
				CurrentRow,
				False);
			
		EndIf;
		
	EndDo;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	Documents.InventoryAssignmentAdjustment.FillInOrderInProductsTabularSection(Object, RowsArray);
	
	FillInServiceDetails(RowsArray);
	UpdateOrderInformation();
	
EndProcedure

#EndRegion

#Region ServiceForm

&AtServer
Procedure OnReadCreateAtServer()
	
	ThereMayBeAppointmentsWithoutAnOrder = Documents.InventoryAssignmentAdjustment.AppointmentsWithoutOrderAreAllowed();
	
	FillInServiceDetails();
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(
		Object,
		Documents.InventoryAssignmentAdjustment));
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	Attributes = Common.ObjectAttributesValues(Object.Purpose, "OrderDocument,AssignmentType");
	OrderDocument = Attributes.OrderDocument;
	
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	
	FillInAvailableActions();
	UpdateOrderInformation();
	SetVisibilityAvailability();
	
EndProcedure

&AtServer
Procedure SetVisibilityAvailability()
	
	ThisIsArbitraryAdjustment = Object.OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.AdvancedAssignmentAdjustment;
	ThisIsReservation            = Object.OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ToReserve_;
	ThisIsAdjustment             = Object.OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment;
	ThisIsWithdrawalOfReserve             = Object.OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve;
	ThisIsMassWithdrawal            = Object.OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserveForMultipleAssignments;
	ThisIsCounterAdjustment    = Object.OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.MutualAdjustment;

	AssignmentType = Common.ObjectAttributeValue(Object.Purpose, "AssignmentType");
	Items.GoodsNewAssignment.Visible = ThisIsArbitraryAdjustment
		Or ThisIsWithdrawalOfReserve And AssignmentType = Enums.AssignmentTypes.ProvidedMaterialsForStage22;
	
	Items.GoodsInitialAssignment.Visible       = ThisIsArbitraryAdjustment Or ThisIsAdjustment;
	Items.ProductsDestinationMassWithdrawal.Visible = ThisIsMassWithdrawal And ThereMayBeAppointmentsWithoutAnOrder;
	Items.GoodsOrderDocument.Visible                    = ThisIsMassWithdrawal And Not ThereMayBeAppointmentsWithoutAnOrder;
	
	OperationKinds = Enums.KindsOfAssignmentAdjustmentOperations;
	FillInHeaderByTypeOfOperation = New Map();
	FillInHeaderByTypeOfOperation.Insert(OperationKinds.ToReserve_,                  NStr("vi = 'Chọn từ số dư tự do';
																							|ru = 'Подобрать из свободных остатков';
																							|en = 'Pick from available inventory'; fa = 'Pick from available inventory';
																							|it = 'Selezionare dalle rimanenze libere';
																							|pl = 'Dobierz z wolnych ostatków';
																							|tr = 'Boş bakiyelerden seç'"));
	FillInHeaderByTypeOfOperation.Insert(OperationKinds.ReservationAndAdjustment,   NStr("vi = 'Chọn từ số dư tự do và đơn hàng đặt riêng';
																						|ru = 'Подобрать из свободных и обособленных остатков';
																						|en = 'Pick from available and assigned inventory'; fa = 'Pick from available and assigned inventory';
																						|it = 'Selezionare dalle rimanenze libere e separate';
																						|pl = 'Dobierz z wolnych i oddzielnych ostatków';
																						|tr = 'Boş ve ayrı bakiyelerden seç'"));
	FillInHeaderByTypeOfOperation.Insert(OperationKinds.RemoveFromReserve,                    NStr("vi = 'Điền số dư đơn hàng đặt riêng';
																									|ru = 'Заполнить обособленными остатками';
																									|en = 'Fill in with assigned stock'; fa = 'Fill in with assigned stock';
																									|it = 'Compilare con le rimanenze separate';
																									|pl = 'Wypełnij oddzielnymi ostatkami';
																									|tr = 'Sabit bakiyelerle doldur'"));
	FillInHeaderByTypeOfOperation.Insert(OperationKinds.RemoveFromReserveForMultipleAssignments, NStr("vi = 'Điền số dư đơn hàng đặt riêng';
																										|ru = 'Заполнить обособленными остатками';
																										|en = 'Fill in with assigned stock'; fa = 'Fill in with assigned stock';
																										|it = 'Compilare con le rimanenze separate';
																										|pl = 'Wypełnij oddzielnymi ostatkami';
																										|tr = 'Sabit bakiyelerle doldur'"));
	FillInHeaderByTypeOfOperation.Insert(OperationKinds.AdvancedAssignmentAdjustment,      Undefined);
	
	TitleFillIn = FillInHeaderByTypeOfOperation.Get(Object.OperationKind);
	Items.GoodsFill.Title = TitleFillIn;
	Items.GoodsFill.Visible = TitleFillIn <> Undefined;
	Items.GoodsSpecifyDestinations.Visible = ThisIsMassWithdrawal Or ThisIsAdjustment;
	
	DisplayHeaderAssignment = (ThisIsReservation Or ThisIsWithdrawalOfReserve Or ThisIsAdjustment)
								 And ThereMayBeAppointmentsWithoutAnOrder Or ThisIsCounterAdjustment;
	
	Items.Purpose.Visible       = DisplayHeaderAssignment;
	Items.OrderDocument.Visible            = Not DisplayHeaderAssignment And Not ThisIsMassWithdrawal And Not ThisIsArbitraryAdjustment And Not ThisIsCounterAdjustment;
	Items.BaseLabel.Visible = ThisIsMassWithdrawal Or ThisIsArbitraryAdjustment;
	
	Items.GoodsPresentationPurpose2.Visible = ThisIsCounterAdjustment;
	Items.GoodsRowAttribute.Visible            = ThisIsCounterAdjustment;
	
	If ThisIsCounterAdjustment Then
		
		Items.OperationKind.ReadOnly           = True;
		
		Items.Purpose.ReadOnly            = True;
		Items.Purpose.ChoiceButton              = False;
		Items.Purpose.Title                 = NStr("vi = 'Ấn định 1';
													|ru = 'Назначение 1';
													|en = 'Assignment 1'; fa = 'Assignment 1';
													|it = 'Assegnazione 1';
													|pl = 'Przeznaczenie';
													|tr = 'Atama 1'");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.UseBinLocationWarehousing");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.MeasuredValueType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfMeasuredValues.NumberOfPieces;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNewAssignment.Name);

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.NewAssignment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	TextGoesToWarehouse = NStr("vi = 'Tiếp nhận tại kho bãi';
								|ru = 'Поступает на склад';
								|en = 'Delivered to warehouse'; fa = 'Delivered to warehouse';
								|it = 'Arriva nel magazzino';
								|pl = 'Wpływa do magazynu';
								|tr = 'Ambara giriş'");
	If TypeOf(OrderDocument) = Type("DocumentRef.MaterialProviderOrder2_5")
		Or False Then
		TextGoesToWarehouse = "";
	EndIf;
	Item.Appearance.SetParameterValue("Text", TextGoesToWarehouse);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCell.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.InitialAssignment.RecordsInWarehouseRegisters");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng ô hàng>';
													|ru = '<ячейки не используются>';
													|en = '<storage bins are not used>'; fa = '<storage bins are not used>';
													|it = '<le celle non vengono usate>';
													|pl = '<komórki nie są używane>';
													|tr = '<hücreler kullanılmıyor>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPremise.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.InitialAssignment.RecordsInWarehouseRegisters");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
		
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng ô hàng>';
													|ru = '<ячейки не используются>';
													|en = '<storage bins are not used>'; fa = '<storage bins are not used>';
													|it = '<le celle non vengono usate>';
													|pl = '<komórki nie są używane>';
													|tr = '<hücreler kullanılmıyor>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCell.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.UseBinLocationWarehousing");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
		
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng ô hàng>';
													|ru = '<ячейки не используются>';
													|en = '<storage bins are not used>'; fa = '<storage bins are not used>';
													|it = '<le celle non vengono usate>';
													|pl = '<komórki nie są używane>';
													|tr = '<hücreler kullanılmıyor>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPremise.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.UseWarerooms");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng nhà kho>';
													|ru = '<помещения не используются>';
													|en = '<premises are not used>'; fa = '<premises are not used>';
													|it = '<i locali non vengono usati>';
													|pl = '<pomieszczenie nie są używane>';
													|tr = '<alanlar kullanılmıyor>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNewAssignment.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReserveRemovalProhibition");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.NewAssignment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNewAssignment.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReserveRemovalProhibition");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.NewAssignment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowAttribute.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.OperationKind");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue =  Enums.KindsOfAssignmentAdjustmentOperations.MutualAdjustment;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.NewAssignment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.Purpose");
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '1<~2';
													|ru = '1<~2';
													|en = '1<~2'; fa = '1<~2';
													|it = '1<~2';
													|pl = '1<~2';
													|tr = '1<~2'"));
	Item.Appearance.SetParameterValue("Font", StyleFonts.ImportantLabelFont);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowAttribute.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.OperationKind");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue =  Enums.KindsOfAssignmentAdjustmentOperations.MutualAdjustment;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.InitialAssignment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.Purpose");
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '1~>2';
													|ru = '1~>2';
													|en = '1~>2'; fa = '1~>2';
													|it = '1~>2';
													|pl = '1~>2';
													|tr = '1~>2'"));
	Item.Appearance.SetParameterValue("Font", StyleFonts.ImportantLabelFont);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPresentationPurpose2.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.OperationKind");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue =  Enums.KindsOfAssignmentAdjustmentOperations.MutualAdjustment;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.NewAssignment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.Purpose");
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Object.Goods.InitialAssignment"));
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPresentationPurpose2.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.OperationKind");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue =  Enums.KindsOfAssignmentAdjustmentOperations.MutualAdjustment;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Goods.InitialAssignment");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.Purpose");
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Object.Goods.NewAssignment"));
	
	//
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm, "GoodsNewAssignment");

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.PathToFieldUseBinLocationSystem = "Object.Goods.UseBinLocationWarehousing";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesAlwaysWHGoods");
	
	// Conditional appearance of quality control Attributes.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsQualityConfirmationDate.Name);
	
	OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SubjectToUnlocking");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ControlledLotReference");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

#EndRegion

#Region HeaderAttributes

&AtServer
Procedure DateOnChangeServer()
	
	If QualityControl.UpdateActionParameters(
			Documents.InventoryAssignmentAdjustment,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetDestinationSelectionParameters()
	
	TypesArray = New Array();
	
	TypesArray.Add(Enums.AssignmentTypes.Own);
	
	If GetFunctionalOption("UseTollManufacturing2_5") Then
		TypesArray.Add(Enums.AssignmentTypes.ProvidedMaterialsForStage22);
		TypesArray.Add(Enums.AssignmentTypes.Giveaway2_5);
	EndIf;
	If GetFunctionalOption("ProvideAgentServicesOnPurchaseToPrincipals") Then
		TypesArray.Add(Enums.AssignmentTypes.DeliveryForPrincipal);
	EndIf;
	
	FixedArrayOfTypes = New FixedArray(TypesArray);
	NewParameter1 = New ChoiceParameter("Filter.AssignmentType", FixedArrayOfTypes);
	NewArray = New Array();
	NewArray.Add(NewParameter1);
	NewParameters = New FixedArray(NewArray);
	Items.Purpose.ChoiceParameters = NewParameters;
	
EndProcedure

&AtClient
Procedure OperationKindChoiceProcessingCompletion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	If UserAnswer = DialogReturnCode.No Then
		Return;
	EndIf;
	
	Object.OperationKind = AdditionalParameters;
	TypeOfOperationProcessingSelectionCompletionOnServer();
	
EndProcedure

&AtServer
Procedure TypeOfOperationProcessingSelectionCompletionOnServer()
	FillInUsingBaseDocument();
	SetVisibilityAvailability();
EndProcedure

&AtServer
Procedure FillInAvailableActions()
	
	CurViewOfOperation = Object.OperationKind;
	
	AvailableAction = Documents.InventoryAssignmentAdjustment.AvailableAction(Object.Purpose);
	
	// The type of operation already selected in the document remains. In the absence of access to it, the document opens for inspection only.
	If AvailableAction.Find(CurViewOfOperation) = Undefined Then
		AvailableAction.Add(CurViewOfOperation);
	EndIf;
	
	Items.OperationKind.ChoiceList.LoadValues(AvailableAction);
	
EndProcedure

&AtServer
Procedure FillInUsingBaseDocument()
	
	Object.Goods.Clear();
	PurposeList.Clear();
	
	If Object.OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve") Then
		
		If Not ReserveRemovalProhibition Then
			Documents.InventoryAssignmentAdjustment.FillInUsingBaseDocument(
				Object.Purpose, 
				Object.Organization, 
				Object.Ref, 
				Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve,
				Object.Goods);
			
			ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
			StructureOfActions = New Structure();
			StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
			BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
			
			FillInServiceDetails();
		EndIf;
		
	EndIf;
	UpdateOrderInformation();
	
EndProcedure

&AtServer
Procedure FillInServiceDetails(Rows = Undefined)
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInFeatureAttribute",
								New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",
								New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute",
								New Structure("Products", "MeasuredValueType"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions, Rows);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	CellRoomParameters = New Structure("Date", Object.Date);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInDestinationAttribute", "NewAssignment");
	StructureOfActions.Insert("FillInTrafficFlagForWarehouseRegisters", "AssignmentOfNewRecordInWarehouseRegisters");
	StructureOfActions.Insert("FillInSpaceUsageAttribute", CellRoomParameters);
	StructureOfActions.Insert("FillInAddressStorageAttribute", CellRoomParameters);
	
	If Rows = Undefined Then
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	Else
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			Rows,
			StructureOfActions,
			Object.Goods,
			CachedValues);
	EndIf;

	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInDestinationAttribute", "InitialAssignment");
	StructureOfActions.Insert("FillInTrafficFlagForWarehouseRegisters", "InitialAssignmentOfRecordInWarehouseRegisters");

	If Rows = Undefined Then
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	Else
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			Rows,
			StructureOfActions,
			Object.Goods,
			CachedValues);
	EndIf;

EndProcedure
// Fills in the service fields use address Storage and use warehouse Storage in the current line.
//
// Parameters:
//  CurrentRow	 - Number - index of the current row.
//
&AtServer
Procedure FillInServiceDetailsInLine(CurrentRow = Undefined)
	
	String = Object.Goods.FindByID(CurrentRow);
	CellRoomParameters = New Structure();
	CellRoomParameters.Insert("Warehouse", String.Warehouse);
	CellRoomParameters.Insert("Premise", String.Premise);
	CellRoomParameters.Insert("Date", Object.Date);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInSpaceUsageAttribute", CellRoomParameters);
	StructureOfActions.Insert("FillInAddressStorageAttribute", CellRoomParameters);
	StructureOfActions.Insert("FillInDestinationAttribute", "NewAssignment");
	StructureOfActions.Insert("FillInTrafficFlagForWarehouseRegisters", "AssignmentOfNewRecordInWarehouseRegisters");
	
	BatchProcessingOfTablePartServer.ProcessTSString(String, StructureOfActions, Undefined);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInDestinationAttribute", "InitialAssignment");
	StructureOfActions.Insert("FillInTrafficFlagForWarehouseRegisters", "InitialAssignmentOfRecordInWarehouseRegisters");
	
	BatchProcessingOfTablePartServer.ProcessTSString(String, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure OpenListOfAppointments()
	
	TitleOfViewForm = ?(ThereMayBeAppointmentsWithoutAnOrder, 
		NStr("vi = 'Ấn định (%DocumentsCount%)';
			|ru = 'Назначения (%DocumentsCount%)';
			|en = 'Assignments (%DocumentsCount%)'; fa = 'Assignments (%DocumentsCount%)';
			|it = 'Destinazioni (%DocumentsCount%)';
			|pl = 'Przeznaczenia (%DocumentsCount%)';
			|tr = 'Atama (%DocumentsCount%)'"),
		NStr("vi = 'Đơn hàng (%DocumentsCount%)';
			|ru = 'Заказы (%DocumentsCount%)';
			|en = 'Orders (%DocumentsCount%)'; fa = 'Orders (%DocumentsCount%)';
			|it = 'Ordini (%DocumentsCount%)';
			|pl = 'Zamówienia (%DocumentsCount%)';
			|tr = 'Siparişler (%DocumentsCount%)'"));
		
	ListOfOrdersAndActivities = ListOfOrdersAndActivities();
		
	OpenForm(
		"CommonForm.ViewingListOfDocuments",
		New Structure("DocumentsList, Title",
		ListOfOrdersAndActivities,
		TitleOfViewForm),
		ThisForm,
		,
		,
		,
		,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Function ListOfOrdersAndActivities()
	
	ReturnList_ = New ValueList();
	
	AssignmentDetailsValues = Common.ObjectsAttributesValues(PurposeList.UnloadValues(), "OrderDocument, LineOfBusiness");
	
	For Each KeyValue In AssignmentDetailsValues Do
		
		DetailsOfAppointment = KeyValue.Value;
		
		If ValueIsFilled(DetailsOfAppointment.OrderDocument) Then
			ReturnList_.Add(DetailsOfAppointment.OrderDocument);
		ElsIf ValueIsFilled(DetailsOfAppointment.LineOfBusiness) Then
			ReturnList_.Add(DetailsOfAppointment.LineOfBusiness);
		EndIf;
		
	EndDo;
	
	Return ReturnList_;
	
EndFunction

&AtServer
Procedure UpdateOrderInformation()
	
	If Items.Goods.CurrentRow <> Undefined Then
		CurrentRow = Object.Goods.FindByID(Items.Goods.CurrentRow);
		If CurrentRow <> Undefined Then
			FillInAssignmentForNewLine(CurrentRow, Object, OrderDocument);
		EndIf;
	EndIf;
	
	NameOfDestinationField = ?(Object.OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment
		Or Object.OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ToReserve_,
		"NewAssignment",
		"InitialAssignment");
	
	AssignmentsTable = Object.Goods.Unload(, NameOfDestinationField);
	AssignmentsTable.GroupBy(NameOfDestinationField);
	AllNanachenii = AssignmentsTable.UnloadColumn(NameOfDestinationField);
	CommonClientServer.DeleteAllValueOccurrencesFromArray(AllNanachenii, Catalogs.Assignments.EmptyRef());
	PurposeList.LoadValues(AllNanachenii);
	
	If Object.OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.AdvancedAssignmentAdjustment
		Or Object.OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserveForMultipleAssignments Then
		
		If PurposeList.Count() = 1 Then
			
			Object.Purpose = PurposeList[0].Value;
			OrderDocument      = Common.ObjectAttributeValue(Object.Purpose, "OrderDocument");
			
		Else
		
			Object.Purpose = Undefined;
			OrderDocument = Undefined;
			
		EndIf;
		
	EndIf;
	
	TotalAppointments = PurposeList.Count();
	
	Items.BaseLabel.Hyperlink = TotalAppointments > 0;
	Items.BaseLabel.TextColor = ?(Items.BaseLabel.Hyperlink, StyleColors.HyperlinkColor, StyleColors.NoteText);
	
	TotalAppointmentsTemplate = ?(ThereMayBeAppointmentsWithoutAnOrder, NStr("vi = 'Tổng số ấn định: %1';
																			|ru = 'Всего назначений: %1';
																			|en = 'Total assignments: %1'; fa = 'Total assignments: %1';
																			|it = 'Totale destinazioni: %1';
																			|pl = 'Lącznie przeznaczeń: %1';
																			|tr = 'Toplam atamalar: %1'"), NStr("vi = 'Tổng số đơn hàng: %1';
																													|ru = 'Всего заказов: %1';
																													|en = 'Total orders: %1'; fa = 'Total orders: %1';
																													|it = 'Totale ordini: %1';
																													|pl = 'Łącznie zamówień: %1';
																													|tr = 'Toplam siparişler: %1'"));
	If TotalAppointments > 1 Then
		Items.BaseLabel.Title = StrReplace(TotalAppointmentsTemplate, "%1", TotalAppointments);
	ElsIf TotalAppointments = 1 Then
		Items.BaseLabel.Title = ?(ThereMayBeAppointmentsWithoutAnOrder, Object.Purpose, OrderDocument);
	ElsIf Object.OperationKind <> Enums.KindsOfAssignmentAdjustmentOperations.AdvancedAssignmentAdjustment Then
		Items.BaseLabel.Title = NStr("vi = 'Cần phải điền vào một danh sách các sản phẩm.';
									|ru = 'Необходимо заполнить список товаров.';
									|en = 'Fill in the Item list.'; fa = 'فهرست اقلام را تکمیل کنید.';
									|it = 'È necessario compilare l''elenco delle merci.';
									|pl = 'Wypełnij listę towarów.';
									|tr = 'Ürün listesini doldurmak gereklidir.'");
	Else
		Items.BaseLabel.Title = "";
	EndIf;
	
EndProcedure

&AtServer
Procedure PurposeOnChangeServer(Purpose)
	
	Modified = True;
	Object.Purpose = Purpose;
	Attributes = Common.ObjectAttributesValues(Object.Purpose, "OrderDocument,AssignmentType,Contract");
	OrderDocument = Attributes.OrderDocument;
	Contract = Attributes.Contract;
	FillInAvailableActions();
	FillInUsingBaseDocument();
	SetVisibilityAvailability();
	
EndProcedure

#EndRegion

#Region DetailsOfTablePartProducts

&AtServer
Procedure ProductsProductsWhenChangedOnServer(CachedValues)
	
	StructureOfDocumentHeader = New Structure();
	StructureOfDocumentHeader.Insert("Warehouse", SettingsValueCached.GetDefaultWarehouse());
	
	CurrentRow = Object.Goods.FindByID(Items.Goods.CurrentRow);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(StructureOfDocumentHeader, False));
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute",
								New Structure("Products", "MeasuredValueType"));
	
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentRowIndex = Items.Goods.CurrentRow;
	FillInServiceDetailsInLine(CurrentRowIndex);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisObject,
		SeriesSpecificationParameters, Text, CurrentData) Then
		ExceptionText	= NStr("vi = 'Lỗi khi thử chỉ ra sê-ri - để chỉ ra sê-ri trong chứng từ này, không cần gọi ra Server.';
								|ru = 'Ошибка при попытке указать серии - в этом документе для указания серий не нужен серверный вызов.';
								|en = 'An error occurred when attempting to specify batch. No server call is required to specify batch in this document.'; fa = 'An error occurred when attempting to specify batch. No server call is required to specify batch in this document.';
								|it = 'Si è verificato un errore durante il tentativo di indicare le serie - in questo documento non è necessaria la chiamata al server per indicare le serie.';
								|pl = 'Błąd podczas próby określenia serii - w tym dokumencie nie jest wymagane wywołanie serwera, aby wskazać serię.';
								|tr = 'Bir parti belirtmeye çalışırken hata oluştu - bu belgede bir parti belirtmek için sunucu çağrısı gerekmez.'");
		Raise ExceptionText;
	EndIf;
	
EndProcedure

#EndRegion

#Region Filling_Products

&AtServer
Function ThereAreGoodsToSeparateProvision()
	
	Return Documents.InventoryAssignmentAdjustment.ThereAreGoodsToSeparateProvision(Object.Purpose);
	
EndFunction

&AtServer
Function ThereAreGoodsToWithdrawReserve()
	
	Return Documents.InventoryAssignmentAdjustment.ThereAreGoodsToWithdrawReserve(Object.Purpose);
	
EndFunction

&AtClient
Procedure AssignmentAdjustmentFillingCompletion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	If UserAnswer = DialogReturnCode.No Then
		Return;
	EndIf;
	
	FillingInDestinationAdjustmentCompletionOnServer(AdditionalParameters);
	
EndProcedure

&AtServer
Procedure FillingInDestinationAdjustmentCompletionOnServer(AdditionalParameters)
	
	If ValueIsFilled(AdditionalParameters.OperationKind)
			 And Object.OperationKind <> AdditionalParameters.OperationKind Then
		Object.OperationKind = AdditionalParameters.OperationKind;
		SetVisibilityAvailability();
	EndIf;
	
	FillInProductsFromStorageTable(AdditionalParameters.GoodsTable);
	
	Modified = True;
	
EndProcedure

&AtServer
Procedure FillInProductsFromStorageTable(AddressOfProductTableInVault)
	
	Object.Goods.Clear();
	
	ItemsFromStorage = GetFromTempStorage(AddressOfProductTableInVault).Goods;
	
	If ValueIsFilled(ItemsFromStorage) And ItemsFromStorage.Count() > 0 Then
		
		Object.Goods.Load(ItemsFromStorage);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert(
			"RecalculateNumberOfPackages",
			BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		FillInServiceDetails();
		
	EndIf;

	UpdateOrderInformation();
	
EndProcedure

#EndRegion

#Region FillingTypesOfInventory

&AtServer
Function PutGoodsAndStockTypesInStorage()
	
	OptionsForEditingInventoryTypes = InventoriesServer.OptionsForEditingInventoryTypes();
	OptionsForEditingInventoryTypes.ColumnNamePurpose = "InitialAssignment";
	
	Return InventoriesServer.PutGoodsAndStockTypesInStorage(ThisObject, OptionsForEditingInventoryTypes);
	
EndFunction

&AtServer
Procedure ProcessingSelectionServerGetStockTypes(ValueSelected, InventoryOwnerAttributesAreSpecifiedManually)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisObject);
	
EndProcedure

#EndRegion

#Region StandardSubsystems

// StandardSubsystems.Properties 

&AtServer
Procedure UpdateAdditionalAttributesItems()

	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);

EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

#EndRegion

#Region SelectGoods

&AtClient
Procedure HandlingSelectionSelectionOnClient(ValueSelected)
	
	If Not ValueIsFilled(ValueSelected) Then
		Return;
	EndIf;
	
	ProcessingSelectionOfSelectionOnServer(ValueSelected);
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	StructureOfActions = New Structure();
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	
	RowsArray = New Array();
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(
			CurrentRow,
			RowOfProduct,
			"Products,Characteristic,Package,Warehouse,NumberOfPackages");
			
		RowsArray.Add(CurrentRow);
		
		FillInAssignmentForNewLine(CurrentRow, Object, OrderDocument);
	
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsArray,
		StructureOfActions,
		Object.Goods);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	FillInServiceDetails(RowsArray);
	
EndProcedure

#EndRegion

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
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
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
