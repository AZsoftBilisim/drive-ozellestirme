#Region Variables

&AtClient
Var CachedValues;

&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Return of the form for analysis
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	DetailsOfEnteringFine = Documents.ElectronicTicketTransaction.DetailsOfEnteringFine();
	
	Items.Operations.RowFilter =
		New FixedStructure(New Structure("OperationType", Enums.TypesOfTicketOperations.Purchase));
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	ItemsAndDimensionsSelectionParameters = Documents.ElectronicTicketTransaction.ParametersForSelectingArticlesAndAnalyticsForDirectWriteOff();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	SetupParameters = Documents.ElectronicTicketTransaction.AccountSettingsForDirectWriteOffMethod();
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	InitializeOperations();
	
	CallbackOnCompletion = New CallbackDescription("EndOfTaskProcessing", ThisObject);
	ClientNotifications.AttachHandler("UpdateETicketForm", CallbackOnCompletion);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	If PeriodClosingDates.DataChangesDenied(CurrentObject)
		Or ModificationOfAdvanceReportIsProhibited(Object.ExpenseReport, "") Then
		LockAttributes();
	EndIf;
	
	OnReadCreateAtServer();
	
	UpdateTicketOperations();
	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);

	ItemsAndDimensionsSelectionParameters = Documents.ElectronicTicketTransaction.ParametersForSelectingArticlesAndAnalyticsForDirectWriteOff();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	SetupParameters = Documents.ElectronicTicketTransaction.AccountSettingsForDirectWriteOffMethod();
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	PurchaseLines_ = Object.Operations.FindRows(
		New Structure("OperationType", PredefinedValue("Enum.TypesOfTicketOperations.Purchase")));
		
	If Not PurchaseLines_.Count() Then
		ErrorText = NStr("vi = 'Chứng từ không có giao dịch mua hàng.';
						|ru = 'Документ не содержит операций покупки.';
						|en = 'The document does not contain purchase transactions.'; fa = 'The document does not contain purchase transactions.';
						|it = 'Документ не содержит операций покупки.';
						|pl = 'The document does not contain purchase transactions.';
						|tr = 'Belge satış işlemini içermemektedir.'");
		Common.MessageToUser(
					ErrorText,, "Items.Operations",, Cancel);
	EndIf;
	
	If PurchaseLines_.Count() And Not ValueIsFilled(PurchaseLines_[0].Sum) Then
		ErrorText = NStr("vi = 'Chưa điền trường ""Số tiền""';
						|ru = 'Поле ""Сумма"" не заполнено';
						|en = '""Amount"" is required'; fa = '""Amount"" is required';
						|it = 'Il campo ""Importo"" non è compilato.';
						|pl = 'Nie wypełniono pola ""Wartość""';
						|tr = '""Tutar"" alanı doldurulmadı'");
		Common.MessageToUser(
			ErrorText,, "Items.Operations.CurrentData.Sum",, Cancel);
	EndIf;
	
	ProcessingVerificationOfCompositionOfOperations(Cancel);
	
	If Object.AcceptVATForDeduction
		 And ListOfTransactionKindCodes.FindByValue(Object.TransactionKindCode) = Undefined Then
		ErrorText = NStr("vi = 'Đã chỉ định sai mã dạng giao dịch.';
						|ru = 'Указан некорректный код вида операции.';
						|en = 'An incorrect code of transaction kind is specified.'; fa = 'An incorrect code of transaction kind is specified.';
						|it = 'An incorrect code of transaction kind is specified.';
						|pl = 'An incorrect code of transaction kind is specified.';
						|tr = 'İşlem türü kodu yanlış belirtilmiş.'");
		Common.MessageToUser(
					ErrorText,, "TransactionKindCode", "Object", Cancel);
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure ProcessingVerificationOfCompositionOfOperations(Cancel)
	
	VATRates        = New Map;
	Returns         = New Map;
	ReturnsAreOrdered = New Map;
	LineNumber = 1;
	
	CompositionLines = Object.Operations.FindRows(New Structure("OperationType", Enums.TypesOfTicketOperations.Purchase));
	For Each CompositionRow In CompositionLines Do
		LineAmount = CompositionRow.Sum;
		BalanceOfBet = VATRates.Get(CompositionRow.VATRate);
		If BalanceOfBet = Undefined Then
			VATRates.Insert(CompositionRow.VATRate, LineAmount);
			BalanceOfBet = LineAmount;
		Else
			BalanceOfBet = BalanceOfBet + LineAmount;
			VATRates.Insert(CompositionRow.VATRate, BalanceOfBet);
		EndIf;
	EndDo;
	
	RowsOfActiveOperations = Ticket_Operations.FindRows(New Structure("DeletionMark", False));
	For Each OperationString In RowsOfActiveOperations Do
		
		ThisIsSurcharge = OperationString.OperationType = Enums.TypesOfTicketOperations.ExtraPay;
		ThisIsReturn = OperationString.OperationType = Enums.TypesOfTicketOperations.Return;
		OperationString.LineNumber = LineNumber;
		
		Field = CommonClientServer.PathToTabularSection("Ticket_Operations", OperationString.LineNumber, "Date");
		
		If BegOfDay(OperationString.Date) < BegOfDay(Object.Date) Then
			If ThisIsSurcharge Then
				ErrorText = NStr("vi = 'Không thể nhập trả trước sớm hơn ngày mua hàng.';
								|ru = 'Нельзя ввести доплату раньше даты покупки.';
								|en = 'Cannot enter the extra pay earlier than the purchase date.'; fa = 'Cannot enter the extra pay earlier than the purchase date.';
								|it = 'Нельзя ввести доплату раньше даты покупки.';
								|pl = 'Cannot enter the extra pay earlier than the purchase date.';
								|tr = 'Satın alma tarihinden önce ek ödeme girilemez.'");
			ElsIf ThisIsReturn Then
				ErrorText = NStr("vi = 'Không thể nhập trả lại trước ngày mua hàng.';
								|ru = 'Нельзя ввести возврат раньше даты покупки.';
								|en = 'Cannot enter the return earlier than the purchase date.'; fa = 'Cannot enter the return earlier than the purchase date.';
								|it = 'Нельзя ввести возврат раньше даты покупки.';
								|pl = 'Cannot enter the return earlier than the purchase date.';
								|tr = 'Satın alma tarihinden önce iade girilemez.'");
			EndIf;
			Common.MessageToUser(ErrorText,, Field,, Cancel);
		EndIf;
		
		LineAmount = ?(ThisIsReturn, -OperationString.Sum, OperationString.Sum);
		BalanceOfBet = VATRates.Get(OperationString.VATRate);
		
		If BalanceOfBet = Undefined Then
			VATRates.Insert(OperationString.VATRate, LineAmount);
			BalanceOfBet = LineAmount;
		Else
			BalanceOfBet = BalanceOfBet + LineAmount;
			VATRates.Insert(OperationString.VATRate, BalanceOfBet);
		EndIf;
		
		If ThisIsReturn Then
			If BalanceOfBet < 0 Then
				Returns.Insert(OperationString, BalanceOfBet);
			EndIf;
		EndIf;
		
		LineNumber = LineNumber + 1;
		
	EndDo;
	
	For Each DescriptionOfReturn In Returns Do
		ReturnsAreOrdered.Insert(DescriptionOfReturn.Key, DescriptionOfReturn.Value);
	EndDo;
	
	For Each DescriptionOfReturn In ReturnsAreOrdered Do
		
		Field = CommonClientServer.PathToTabularSection("Ticket_Operations", DescriptionOfReturn.Key.LineNumber, "Sum");
			
		MessageText = StrTemplate(NStr("vi = 'Số tiền hoàn trả từ %1 theo thuế suất thuế GTGT ""%2""
				                   |vượt quá số tiền các giao dịch mua trước đó là %3 %4';
				                   |ru = 'Сумма возврата от %1 по ставке НДС ""%2""
				                   |превышает сумму ранее совершенных покупок на %3 %4';
				                   |en = 'The refund amount from %1 at the ""%2"" VAT rate
				                   |exceeds the amount of previously made purchases by %3 %4'; fa = 'The refund amount from %1 at the ""%2"" VAT rate
				                   |exceeds the amount of previously made purchases by %3 %4';
				                   |it = 'The refund amount from %1 at the ""%2"" VAT rate
				                   |exceeds the amount of previously made purchases by %3 %4';
				                   |pl = 'The refund amount from %1 at the ""%2"" VAT rate
				                   |exceeds the amount of previously made purchases by %3 %4';
				                   |tr = 'KDV oranı, ""%2"" 
				                   |üzerinden %1 değerinden yapılan iade tutarı, daha önceki alımların tutarlarını %3 %4 oranında aşmaktadır'"),
				                   Format(DescriptionOfReturn.Key.Date, "DLF=D"),
				                   DescriptionOfReturn.Key.VATRate,
				                   -DescriptionOfReturn.Value,
				                   Object.Currency);
				      
		Common.MessageToUser(MessageText, Object.Ref, Field,, Cancel);
			
	EndDo;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	Else
		
		If Object.PostingDate < BegOfDay(Object.Date) Then
			CommonClient.MessageToUser(NStr("vi = 'Ngày gửi không thể sớm hơn ngày mua vé.';
											|ru = 'Дата отправления не может быть раньше даты покупки билета.';
											|en = 'The departure date cannot be earlier than the ticket purchase date.'; fa = 'The departure date cannot be earlier than the ticket purchase date.';
											|it = 'Дата отправления не может быть раньше даты покупки билета.';
											|pl = 'The departure date cannot be earlier than the ticket purchase date.';
											|tr = 'Hareket tarihi, bilet satın alma tarihinden önce olamaz.'"), Object.Ref, "Object.PostingDate",,Cancel);
		EndIf;
		
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	RefreshFormTitle();
	
	ConfigureDependentFormElementsOnServer();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	UpdateTicketOperations();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
		
	Notify("Record_TicketsAndReservations", WriteParameters, Object.Ref);
	NotifyChanged(Type("DocumentRef.ElectronicTicketTransaction"));
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	If EventName = "Write_ElectronicTicketOperation" And Parameter.ElectronicTicket = Object.Ref Then
		UpdateTicketOperations(CommonClientServer.ValueInArray(Source));
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BusinessOperationOnChange(Item)
	BusinessOperationWhenChangingOnServer();
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	UpdateTextAdvanceReport();
	
EndProcedure

&AtClient
Procedure DateOfPurchaseOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	CompositionLines =
		Object.Operations.FindRows(New Structure("OperationType", PredefinedValue("Enum.TypesOfTicketOperations.Purchase")));
	For Each CompositionRow In CompositionLines Do
		CompositionRow.Date = Object.Date;
	EndDo;
	
	DateOfPurchaseWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure CarrierOnChange(Item)
	CarrierWhenChangedOnServer();
EndProcedure

&AtClient
Procedure AgentOnChange(Item)
	AgentWhenChangingOnServer();
EndProcedure

&AtClient
Procedure AdvanceHolderOnChange(Item)
	AccountablePersonForChangesOnServer();
EndProcedure

&AtClient
Procedure TextExpenseReportURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "ClearAdvanceReport"
			Or FormattedStringURL = "ToIncludeInExpenseReport" Then
			
		StandardProcessing = False;
		TicketEntryIsRequired = Not ValueIsFilled(Object.Ref) Or Modified;
		
		NotificationParameters = New Structure;
		NotificationParameters.Insert("TicketEntryIsRequired", TicketEntryIsRequired);
		NotificationParameters.Insert("FormattedStringURL", FormattedStringURL);
		CallbackDescription = New CallbackDescription("TextExpenseReportURLProcessingContinued", ThisObject, NotificationParameters);
		
		If TicketEntryIsRequired Then
			ShowQueryBox(CallbackDescription,
				NStr("vi = 'Vé điện tử chưa được lưu hoặc đã bị thay đổi. Có thực hiện lưu không?';
					|ru = 'Электронный билет не записан или изменен. Выполнить запись?';
					|en = 'The electronic ticket is not saved or has been changed. Save it?'; fa = 'The electronic ticket is not saved or has been changed. Save it?';
					|it = 'The electronic ticket is not saved or has been changed. Save it?';
					|pl = 'The electronic ticket is not saved or has been changed. Save it?';
					|tr = 'Elektronik bilet kaydedilmemiş veya değiştirilmiş. Kaydedilsin mi?'"), QuestionDialogMode.YesNo);
		Else
			RunCallback(CallbackDescription, DialogReturnCode.Yes);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PostingDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	Object.PostingDate = Object.PostingDate - Second(Object.PostingDate);
EndProcedure

&AtClient
Procedure ArrivalDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	Object.ArrivalDate = Object.ArrivalDate - Second(Object.ArrivalDate);
	ArrivalDateOnChangeAtServer();
EndProcedure

&AtClient
Procedure DirectWriteOffMethodOnChange(Item)
	
	Object.Employee = Undefined;
	MethodOfWriteOffDirectlyOnChangeATServer();
	
EndProcedure

&AtClient
Procedure PurchaseForActivityClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure PurchaseForActivityOnChange(Item)
	PurchasingForActivitiesOnChangeATServer();
EndProcedure

&AtClient
Procedure EmployeeOnChange(Item)
	
	DescriptionOfNotificationONChange = New CallbackDescription("EmployeeOnChangeContinued", ThisObject);
	If ValueIsFilled(Object.PassengerSFullName) Then
		ShowQueryBox(DescriptionOfNotificationONChange,
		               NStr("vi = 'Điền đầy đủ họ tên của hành khách?';
							|ru = 'Перезаполнить ФИО пассажира?';
							|en = 'Refill the passenger''s full name?'; fa = 'Refill the passenger''s full name?';
							|it = 'Refill the passenger''s full name?';
							|pl = 'Refill the passenger''s full name?';
							|tr = 'Yolcunun Adı Soyadı yeniden doldurulsun mu?'"),
		               QuestionDialogMode.YesNo);
	Else
		RunCallback(DescriptionOfNotificationONChange, DialogReturnCode.Yes);
	EndIf;
	
EndProcedure

&AtClient
Procedure PassengerSFullNameOnChange(Item)
	Items.Employee.AutoMarkIncomplete = Not ValueIsFilled(Object.PassengerSFullName);
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpenseItemStartListChoice(Item, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesOnChange(Item)
	IncomeAndExpensesClientServer.DimensionOfExpensesOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure AssetsLiabilitiesDimensionOnChange(Item)
	IncomeAndExpensesClientServer.AssetsLiabilitiesDimensionOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure PresentationOfRecordingInComplAccountingClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	Return;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOperations

&AtClient
Procedure OperationsBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	If Not Copy Then
	
		Cancel = True;
		NewOperation = Object.Operations.Add();
		NewOperation.Date = Object.Date;
		NewOperation.OperationType = PredefinedValue("Enum.TypesOfTicketOperations.Purchase");
		NewOperation.VATRate = PredefinedValue("Catalog.VATRates.EXCLUDINGVAT");
	
	EndIf;
	
EndProcedure

&AtClient
Procedure OperationsSumOnChange(Item)
	CalculateVAT(Items.Operations.CurrentData);
EndProcedure

&AtClient
Procedure OperationsVATRateOnChange(Item)
	CalculateVAT(Items.Operations.CurrentData);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTicket_Operations

&AtClient
Procedure Ticket_OperationsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Ticket_Operations.FindByID(RowSelected);
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.ThisIsCurrentETicket Then
		If Field = Items.Ticket_OperationsPenaltyAmount
			And CurrentData.OperationType = PredefinedValue("Enum.TypesOfTicketOperations.Return") Then
			EditAdjustment(CurrentData);
		EndIf;
		Return;
	EndIf;
	
	OpeningParameters = New Structure("Key", CurrentData.Ref);
	OpenForm("Document.ElectronicTicketTransaction.Form.ElectronicTicketTransactionForm", OpeningParameters);
	
EndProcedure

&AtClient
Procedure Ticket_OperationsSumOnChange(Item)
	CurrentData = Items.Ticket_Operations.CurrentData;
	CalculateVAT(CurrentData);
	UpdateLineOfOperations(CurrentData, "Sum,VATAmount");
EndProcedure

&AtClient
Procedure Ticket_OperationsVATRateOnChange(Item)
	CurrentData = Items.Ticket_Operations.CurrentData;
	CalculateVAT(CurrentData);
	UpdateLineOfOperations(CurrentData, "VATRate,VATAmount");
EndProcedure

&AtClient
Procedure Ticket_OperationsDateOnChange(Item)
	UpdateLineOfOperations(Items.Ticket_Operations.CurrentData, "Date");
EndProcedure

&AtClient
Procedure Ticket_OperationsVATAmountOnChange(Item)
	UpdateLineOfOperations(Items.Ticket_Operations.CurrentData, "VATAmount");
EndProcedure

&AtClient
Procedure Ticket_OperationsCommentOnChange(Item)
	UpdateLineOfOperations(Items.Ticket_Operations.CurrentData, "Comment");
EndProcedure

&AtClient
Procedure Ticket_OperationsBeforeDeleteRow(Item, Cancel)
	
	CurrentData = Ticket_Operations.FindByID(Item.CurrentRow);
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.ThisIsCurrentETicket Then
		Return;
	EndIf;
	
	Cancel = True;
	AdditionalProperties = New Structure;
	AdditionalProperties.Insert("Operation", CurrentData.Ref);
	CallbackDescription = New CallbackDescription("TicketOperationsAfterSettingTagForDeletion", ThisObject, AdditionalProperties);
	TMCommonUseClient.SetDeletionMark(Items.Ticket_Operations, Title, CallbackDescription);
	
EndProcedure

&AtClient
Procedure Ticket_OperationsOnActivateRow(Item)
	
	If Item.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Ticket_Operations.FindByID(Item.CurrentRow);
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.ThisIsCurrentETicket Then
		HeaderOfDeleteCommand = NStr("vi = 'Xóa bỏ';
									|ru = 'Удалить';
									|en = 'Delete'; fa = 'حذف';
									|it = 'Delete';
									|pl = 'Delete';
									|tr = 'Sil'");
	Else
		HeaderOfDeleteCommand = NStr("vi = 'Đặt dấu xóa / Bỏ dấu xóa';
									|ru = 'Пометить на удаление / Снять пометку';
									|en = 'Toggle deletion mark'; fa = 'تغییر علامت حذف';
									|it = 'Contrassegnare per l''eliminazione/ Togliere il contrassegno';
									|pl = 'Zaznacz do usunięcia / Usuń zaznaczenie';
									|tr = 'Silmek için işaretle / İşareti kaldır'");
	EndIf;
	
	Items.Ticket_OperationsContextMenuDelete.Title = HeaderOfDeleteCommand;
	Items.Ticket_OperationsDelete.Title = HeaderOfDeleteCommand;
	
EndProcedure
#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateSurcharge(Command)
	
	CreateOperationOfOperationWithElectronicTicket(PredefinedValue("Enum.TypesOfTicketOperations.ExtraPay"));
	
EndProcedure

&AtClient
Procedure CreateRefund(Command)
	
	CreateOperationOfOperationWithElectronicTicket(PredefinedValue("Enum.TypesOfTicketOperations.Return"));
	
EndProcedure

&AtClient
Procedure FullReturn(Command)
	
	CreateOperationOfOperationWithElectronicTicket(PredefinedValue("Enum.TypesOfTicketOperations.Return"), True);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject, True);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject, True);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
//End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure EndOfTaskProcessing(MessageData, AdditionalParameters = Undefined) Export
	
	If MessageData.ProcessedDocument = Object.Ref Then
		Read();
	EndIf;
	
EndProcedure

&AtClient
Procedure TicketOperationsAfterSettingTagForDeletion(Result, AdditionalProperties) Export
	
	UpdateTicketOperations(CommonClientServer.ValueInArray(AdditionalProperties.Operation));
	
EndProcedure

&AtClient
Procedure UpdateLineOfOperations(Source, SourceFields)
	
	MutableStrings =
		Object.Operations.FindRows(New Structure("RowID", Source.RowID));
	If MutableStrings.Count() Then
		FillPropertyValues(MutableStrings[0], Source, SourceFields);
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateOperationOfOperationWithElectronicTicket(OperationType, ThisIsFullReturn = False)
	
	OperationDescription = New Structure;
	OperationDescription.Insert("OperationType", OperationType);
	OperationDescription.Insert("ThisIsFullReturn", ThisIsFullReturn);
	
	DataForCreatingTicketOperation = New Structure;
	DataForCreatingTicketOperation.Insert("ETicketData", Object);
	DataForCreatingTicketOperation.Insert("OperationDescription", OperationDescription);
	DataForCreatingTicketOperation.Insert("ThisIsTicketSplit", False);
	
	BasisParameters = New Structure();
	BasisParameters.Insert("ElectronicTicket", Object.Ref);
	BasisParameters.Insert("DataForCreatingTicketOperation", DataForCreatingTicketOperation);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("BasisParameters", BasisParameters);
	AdditionalParameters.Insert("TicketEntryIsRequired", False);
	CallbackDescription = New CallbackDescription("CreateOperationOfOperationWithElectronicTicketContinued", ThisObject, AdditionalParameters);
	
	If Not ValueIsFilled(Object.Ref) Or Modified Then
		CallbackDescription.AdditionalParameters.TicketEntryIsRequired = True;
		ShowQueryBox(CallbackDescription,
			NStr("vi = 'Trước khi tạo giao dịch, cần ghi lại vé điện tử. Thực hiện ghi lại?';
				|ru = 'Перед созданием операции необходимо записать электронный билет. Выполнить запись?';
				|en = 'Before creating a transaction, save the electronic ticket. Save it?'; fa = 'Before creating a transaction, save the electronic ticket. Save it?';
				|it = 'Before creating a transaction, save the electronic ticket. Save it?';
				|pl = 'Before creating a transaction, save the electronic ticket. Save it?';
				|tr = 'İşlem oluşturmadan önce elektronik biletin kaydedilmesi gerekir. Kaydedilsin mi?'"), QuestionDialogMode.YesNo);
	Else
		RunCallback(CallbackDescription, DialogReturnCode.Yes);
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateOperationOfOperationWithElectronicTicketContinued(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		If AdditionalParameters.TicketEntryIsRequired Then
			TicketIsRecorded = Write();
		Else
			TicketIsRecorded = True;
		EndIf;
		
		If TicketIsRecorded Then
			AdditionalParameters.BasisParameters.ElectronicTicket = Object.Ref;
			OpenForm(
				"Document.ElectronicTicketTransaction.Form.ElectronicTicketTransactionForm",
				New Structure("Basis", AdditionalParameters.BasisParameters));
		EndIf;
			
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateTicketOperations(ReferencesOfOperations = Undefined)
	
	TransactionTable = Documents.ElectronicTicketTransaction.ElectronicTicketOperations(Object.Ref, ReferencesOfOperations);
	
	If Not ValueIsFilled(ReferencesOfOperations) Then
		Ticket_Operations.Load(TransactionTable);
	Else
		
		LinesToDelete = New Array;
		For Each ElectronicTicketOperation In ReferencesOfOperations Do
			OperationLines = Ticket_Operations.FindRows(New Structure("Ref", ElectronicTicketOperation));
			For Each OperationString In OperationLines Do
				LinesToDelete.Add(OperationString);
			EndDo;
		EndDo;
		
		For Each RowToDelete In LinesToDelete Do
			Ticket_Operations.Delete(RowToDelete);
		EndDo;
		
		For Each NewLineOfOperations In TransactionTable Do
			FillPropertyValues(Ticket_Operations.Add(), NewLineOfOperations);
		EndDo;
		
	EndIf;
	
	Ticket_Operations.Sort("Date,OperationProcedure");
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.BookingViaAdvanceHolder Then
		Return;
	EndIf;
	
	AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
	AddlParameters.ARAPCurrency = Object.Currency;
	AddlParameters.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts;
	
	ContractParameters = New Structure;
	ContractParameters.Insert("Organization", Object.Organization);
	ContractParameters.Insert("Contract",     Object.Contract);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.BookingFromVendor Then
		ContractParameters.Insert("Partner",     Object.Carrier);
		ContractParameters.Insert("Counterparty",  Object.CounterpartyCarrier);
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.BookingViaAgent Then
		ContractParameters.Insert("Partner",     Object.Agent);
		ContractParameters.Insert("Counterparty",  Object.CounterpartyAgent);
	EndIf;
		
	Object.Contract = PurchasesServer.GetDefaultContract(
		ContractParameters, Enums.BusinessTransactions.PurchaseFromSupplier, AddlParameters);
	
EndProcedure

&AtClient
Function PurchaseIsFullyRefunded()
	
	AmountOfPurchases = 0;
	AmountOfReturns = 0;
		
	ReturnOperation = PredefinedValue("Enum.TypesOfTicketOperations.Return");
	PurchaseOperation = PredefinedValue("Enum.TypesOfTicketOperations.Purchase");
		
	For Each OperationString In Object.Operations Do
		If OperationString.OperationType = PurchaseOperation Then
			AmountOfPurchases = AmountOfPurchases + OperationString.Sum;
		EndIf;
	EndDo;
		
	RowsOfActiveOperations = Ticket_Operations.FindRows(New Structure("DeletionMark", False));
	For Each OperationString In RowsOfActiveOperations Do
		
		If OperationString.OperationType = ReturnOperation Then
			AmountOfReturns = AmountOfReturns + OperationString.Sum;
		Else
			AmountOfPurchases = AmountOfPurchases + OperationString.Sum;
		EndIf;
		
	EndDo;
		
	Return AmountOfReturns >= AmountOfPurchases;
	
EndFunction

&AtClient
Procedure CalculateVAT(ProcessedString)
	
	If Not ValueIsFilled(ProcessedString.VATRate) Then
		ProcessedString.VATRate = PredefinedValue("Catalog.VATRates.EXCLUDINGVAT");
	EndIf;
	
	RowData = New Structure;
	RowData.Insert("VATRate", ProcessedString.VATRate);
	RowData.Insert("VATAmount", ProcessedString.VATAmount);
	RowData.Insert("Sum", ProcessedString.Sum);
	
	VATConversionParameters = New Structure("PriceIncludesVAT", True);
	StructureOfActions = New Structure("RecalculateVATAmount", VATConversionParameters);
	BatchProcessingOfTablePartClient.ProcessTSString(RowData, StructureOfActions, CachedValues);
	
	ProcessedString.VATAmount = RowData.VATAmount;
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure TextExpenseReportURLProcessingContinued(Result, AdditionalParameters) Export
	
	If Not Result = DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Result = DialogReturnCode.Yes Then
		If AdditionalParameters.TicketEntryIsRequired Then
			TicketIsRecorded = Write();
		Else
			TicketIsRecorded = True;
		EndIf;
	EndIf;
	
	If Not TicketIsRecorded Then
		Return;
	EndIf;
	
	If AdditionalParameters.FormattedStringURL = "ClearAdvanceReport" Then
		
		ErrorMessage = "";
		If ModificationOfAdvanceReportIsProhibited(Object.ExpenseReport, ErrorMessage) Then
			CommonClient.MessageToUser(ErrorMessage, , , "TextExpenseReport");
		Else
			Object.ExpenseReport = Undefined;
			Modified = True;
			TextExpenseReport = New FormattedString(NStr("vi = 'Đưa vào giấy thanh toán tạm ứng';
														|ru = 'Включить в авансовый отчет';
														|en = 'To include in expense report'; fa = 'To include in expense report';
														|it = 'Includere nel rapporto spese';
														|pl = 'Dołączyć do raportu rozchodów';
														|tr = 'Gider raporuna ekle'"),,,, "ToIncludeInExpenseReport");
		EndIf;
		
	ElsIf AdditionalParameters.FormattedStringURL = "ToIncludeInExpenseReport" Then
		
		If PurchaseIsFullyRefunded() Then
			ClearMessages();
			CommonClient.MessageToUser(NStr("vi = 'Đã hoàn trả toàn bộ việc mua hàng. Không cần giấy thanh toán tạm ứng.';
											|ru = 'Покупка полностью возвращена. Авансовый отчет не требуется.';
											|en = 'The purchase is fully refunded. No expense report is required.'; fa = 'The purchase is fully refunded. No expense report is required.';
											|it = 'The purchase is fully refunded. No expense report is required.';
											|pl = 'The purchase is fully refunded. No expense report is required.';
											|tr = 'Satın alma tam olarak tamamlandı. Gider raporu gerekmemektedir.'"));
			Return;
		EndIf;
		
		Filter = New Structure;
		Filter.Insert("Organization", Object.Organization);
		Filter.Insert("Department", Object.AccountablePersonDepartment);
		Filter.Insert("AdvanceHolder", Object.AdvanceHolder);
		
		FormParameters = New Structure("Filter", Filter);
		FormParameters.Insert("Date", Object.Date);
		FormParameters.Insert("DocumentPurchases", Object.Ref);
		FormParameters.Insert("Currency", Object.Currency);
		
		Notification = New CallbackDescription("AfterSelectingAdvanceReport", ThisObject);
		
		OpenForm("Document.ExpenseReport.Form.SelectionFormOfCreation", FormParameters, ThisObject,,,, Notification);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterSelectingAdvanceReport(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		ErrorMessage = "";
		If ModificationOfAdvanceReportIsProhibited(Result, ErrorMessage) Then
			CommonClient.MessageToUser(ErrorMessage, , , "TextExpenseReport");
		Else
			Object.ExpenseReport = Result;
			Modified = True;
			UpdateTextAdvanceReport();
		EndIf;
	Else
		ThisObject.Read();
	EndIf;
	
EndProcedure

&AtServer
Procedure AccountablePersonForChangesOnServer()
	Object.AccountablePersonDepartment = PersonsTM.DivisionOfIndividual(Object.AdvanceHolder);
EndProcedure

&AtServer
Procedure CarrierWhenChangedOnServer()
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Carrier, Object.CounterpartyCarrier);
	FillInDefaultContract();
	
EndProcedure

&AtServer
Procedure DateOfPurchaseWhenChangedOnServer()
	
	TopUpVATRate();
	DefinePrintingSingleAdvanceReport();
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure ArrivalDateOnChangeAtServer()
	UpdatePurchaseForActivity(True);
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	If Not ValueIsFilled(Object.Currency) Then
		Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	EndIf;
	
	Object.ExpenseReport = Undefined;
	
	TopUpVATRate();
	FillInSubordinatePropertiesForStatistics("Organization");
	UpdatePurchaseForActivity(True);
	FillInDefaultContract();
	
EndProcedure

&AtServer
Procedure AgentWhenChangingOnServer()
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Agent, Object.CounterpartyAgent);
	FillInDefaultContract();
	
EndProcedure

&AtServer
Procedure BusinessOperationWhenChangingOnServer()
	
	Object.Contract = Undefined;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.BookingViaAgent
		Or Object.BusinessOperation = Enums.BusinessTransactions.BookingFromVendor Then
		If Not GetFunctionalOption("UseContractsWithVendors") Then
			MessageText = NStr("vi = 'Để phản ánh mua vé thông qua đại lý hoặc người vận chuyển 
				|cần chỉ ra hợp đồng - bật sử dụng hợp đồng với nhà cung cấp trong phân hệ ""Mua hàng"".';
				|ru = 'Для отражения покупки билета через агента или у перевозчика 
				|необходимо указать договор - включить использование договоров с поставщиками в разделе ""Закупки"".';
				|en = 'Specify a contract to record the ticket purchase via agent or carrier: 
				|enable using vendor contracts in ""Purchasing"" section.'; fa = 'Specify a contract to record the ticket purchase via agent or carrier: 
				|enable using vendor contracts in ""Purchasing"" section.';
				|it = 'Per registrare l''acquisto del biglietto presso agente o vettore 
				|è necessario indicare il contratto - abilitare utilizzo di contratti con fornitori nella sezione ""Acquisti"".';
				|pl = 'Do wyświetlenia zakupu biletu poprzez agenta lub u przewoźnika 
				|należy wskazać kontrakt - włączyć używanie umów z dostawcami w rozdziale ""Zakupy"".';
				|tr = 'Bir acente veya taşıyıcı aracılığıyla satın alınan bileti yansıtmak için 
				|sözleşme belirtmeniz gerekir - ""Satın almalar"" bölümünde tedarikçilerle yapılan sözleşmelerin kullanımını etkinleştir.'");
			Common.MessageToUser(MessageText);
			Object.BusinessOperation = Enums.BusinessTransactions.BookingViaAdvanceHolder;
		EndIf;
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("BusinessOperation");
	FillInDefaultContract();
	
	FormItemsManagement();
	ConfigureDependentFormElementsOnServer("BusinessOperation");
	
EndProcedure

#Region Properties

// StandardSubsystems.Properties
&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure
// End StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

#EndRegion

#Region FormItemsManagement

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// VATAmount
	Item = ConditionalAppearance.Items.Add();
	
	Fields = Item.Fields.Items;
	ItemField = Fields.Add();
	ItemField.Field = New DataCompositionField(Items.OperationsVATAmount.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Operations.VATRate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	
	RatesWithoutVAT = VATAccountingERPInternalClientServerCached.ListOfInsignificantBets();
	RatesWithoutVAT.Add(Catalogs.VATRates.EmptyRef());
	
	ItemFilter.RightValue = RatesWithoutVAT;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
		
	// The amount of the penalty in the table of operations
	Item = ConditionalAppearance.Items.Add();
	
	Fields              = Item.Fields.Items;
	ItemField      = Fields.Add();
	ItemField.Field = New DataCompositionField(Items.Ticket_OperationsPenaltyAmount.Name);
	
	ItemFilter                = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Ticket_Operations.OperationType");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfTicketOperations.Return;
	
	ItemFilter                = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Ticket_Operations.PenaltyAmount");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
		
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không có tiền phạt';
													|ru = 'Нет штрафа';
													|en = 'No fine'; fa = 'No fine';
													|it = 'Нет штрафа';
													|pl = 'No fine';
													|tr = 'Ceza yok'"));
	
	// Only view for documents-of operations
	Item = ConditionalAppearance.Items.Add();
	
	Fields              = Item.Fields.Items;
	ItemField      = Fields.Add();
	
	ItemField.Field = New DataCompositionField(Items.Ticket_Operations.Name);
	
	ItemFilter                = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Ticket_Operations.ThisIsCurrentETicket");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Presentation of operations of the current document (before separation)
	AllowedTypes = New Array;
	AllowedTypes.Add(Enums.TypesOfTicketOperations.ExtraPay);
	AllowedTypes.Add(Enums.TypesOfTicketOperations.Return);
	
	For Each ValidType_ In AllowedTypes Do
	
		Item = ConditionalAppearance.Items.Add();
		
		Fields              = Item.Fields.Items;
		ItemField      = Fields.Add();
		
		ItemField.Field = New DataCompositionField(Items.TicketOperationsOfOperation.Name);
		
		ItemFilter                = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue  = New DataCompositionField("Ticket_Operations.Ref");
		ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Object.Ref;
		
		ItemFilter                = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue  = New DataCompositionField("Ticket_Operations.OperationType");
		ItemFilter.ComparisonType   =  DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = ValidType_;
		
		Item.Appearance.SetParameterValue("Text",
			StrTemplate(NStr("vi = '%1 theo vé điện tử %2 %3 ngày %4';
							|ru = '%1 по электронному билету %2 %3 от %4';
							|en = '%1 by electronic ticket %2 %3 dated %4'; fa = '%1 by electronic ticket %2 %3 dated %4';
							|it = '%1 by electronic ticket %2 %3 dated %4';
							|pl = '%1 by electronic ticket %2 %3 dated %4';
							|tr = '%4 tarihli,  %2 %3numaralı elektronik bilet için %1'"),
						String(ValidType_),
						Object.ServiceType,
						Object.TicketNumber,
						Object.Date));
	
	EndDo;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	StartDateOfPrintingSingleExpenseReport = Constants.StartDateOfPrintingSingleExpenseReport.Get();
	SingleExpenseReportUnconditionally = Not Constants.VisibilityOfStartDateOfPrintingSingleExpenseReport.Get();
	DefinePrintingSingleAdvanceReport();
	CashServer.ManagingFormElementsWhenReadingCreatingOnServer(ThisObject);
	
	If Object.Operations.Count() > 1 Then
		MultipleOperations = 1;
	EndIf;
	
	RefreshFormTitle();
	
	UpdateTextAdvanceReport();
	FormItemsManagement();
	
	ConfigureDependentFormElementsOnServer();
	
	UpdatePurchaseForActivity();
	
EndProcedure

&AtServer
Procedure UpdatePurchaseForActivity(Fill = False)
	
	If Not Object.DirectWriteOffMethod Then
		Object.PurchaseForActivity = Undefined;
		Object.AcceptVATForDeduction = False;
		Object.TransactionKindCode = "";
		Return;
	EndIf;
	
	FillParameters = Documents.ElectronicTicketTransaction.ParametersForFillingInVATActivityType(Object);
	
	If Not ValueIsFilled(Object.PurchaseForActivity) Or Fill Then
		VATAccountingERP.FillInTypeOfActivityVAT(
			Object.PurchaseForActivity,
			FillParameters,
			VATAccountingCachedParameterValues);
			
			PurchasingForActivitiesOnChangeATServer();
			
	EndIf;
	
	VATAccountingERP.FillInActivitySelectionList(
		Items.PurchaseForActivity,
		Object.PurchaseForActivity,
		FillParameters,
		VATAccountingCachedParameterValues);
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisObject, ChangedProps, FormAttributes(ThisObject));
	
EndProcedure

&AtClientAtServerNoContext
Function FormAttributes(Form)
	
	FormAttributes = New Structure;
	FormAttributes.Insert("PrintASingleExpenseReport");
	FillPropertyValues(FormAttributes, Form);
	
	Return FormAttributes;
	
EndFunction

&AtServer
Procedure FormItemsManagement()
	
	ServiceTypeSelectionList = Items.ServiceType.ChoiceList;
	ServiceTypeSelectionList.Clear();
	
	ServiceTypeSelectionList.Add(Enums.BookingServiceTypes.AirlineTicket);
	ServiceTypeSelectionList.Add(Enums.BookingServiceTypes.RailwayTicket);
	ServiceTypeSelectionList.Add(Enums.BookingServiceTypes.BusTicket);
	ServiceTypeSelectionList.Add(Enums.BookingServiceTypes.TransferService);
	ServiceTypeSelectionList.Add(Enums.BookingServiceTypes.Other);
	
	Links = New Array;
	Links.Add(New ChoiceParameterLink("Filter.Organization", "Object.Organization"));
	Links.Add(New ChoiceParameterLink("Filter.ARAPCurrency", "Object.Currency"));
	If Object.BusinessOperation = Enums.BusinessTransactions.BookingViaAgent Then
		Links.Add(New ChoiceParameterLink("Filter.Counterparty", "Object.CounterpartyAgent"));
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.BookingFromVendor Then
		Links.Add(New ChoiceParameterLink("Filter.Counterparty", "Object.CounterpartyCarrier"));
	EndIf;
	Items.Contract.ChoiceParameterLinks = New FixedArray(Links);
	
	Items.Ticket_OperationsPenaltyAmount.Visible =
		Documents.ElectronicTicketTransaction.ElectronicTicketContainsOfOperationsLines(Object);
	
EndProcedure

&AtServer
Procedure RefreshFormTitle()
	
	If ValueIsFilled(Object.Ref) Then
		Template = NStr("vi = '%1 %2 ngày %3';
						|ru = '%1 %2 от %3';
						|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
						|it = '%1 %2 del %3';
						|pl = '%1 %2 z dnia %3';
						|tr = '%3 tarihli %1 %2'");
		Title = StrTemplate(Template, Object.ServiceType, Object.TicketNumber, Object.Date);
	Else
		Title = NStr("vi = 'Vé điện tử (tạo mới)';
					|ru = 'Электронный билет (создание)';
					|en = 'Electronic ticket (Create)'; fa = 'Electronic ticket (Create)';
					|it = 'Electronic ticket (Create)';
					|pl = 'Electronic ticket (Create)';
					|tr = 'Elektronik bilet (oluşturma)'");
	EndIf;
	
EndProcedure

&AtClient
Procedure InitializeOperations()
	
	TypeOfOperationOfPurchase = PredefinedValue("Enum.TypesOfTicketOperations.Purchase");
	PurchaseLines_ = Object.Operations.FindRows(New Structure("OperationType", TypeOfOperationOfPurchase));
	
	If Not PurchaseLines_.Count() Then
		NewRow = Object.Operations.Add();
		NewRow.OperationType = TypeOfOperationOfPurchase;
		NewRow.Date = Object.Date;
		Items.Operations.CurrentRow = NewRow.GetID();
		CurRate_ = NewRow.VATRate;
	Else
		Items.Operations.CurrentRow = PurchaseLines_[0].GetID();
		CurRate_ = PurchaseLines_[0].VATRate;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateTextAdvanceReport()
	
	TextExpenseReport = ExpenseReportLocalization.TextExpenseReport(Object.ExpenseReport);
	
EndProcedure

&AtServer
Procedure DefinePrintingSingleAdvanceReport()
	
	If ValueIsFilled(StartDateOfPrintingSingleExpenseReport) Then
		If ValueIsFilled(Object.Date) Then
			PrintASingleExpenseReport = (Object.Date >= StartDateOfPrintingSingleExpenseReport);
		Else
			PrintASingleExpenseReport = (CurrentSessionDate() >= StartDateOfPrintingSingleExpenseReport);
		EndIf;
	Else
		PrintASingleExpenseReport = SingleExpenseReportUnconditionally;
	EndIf;
	
EndProcedure

&AtServer
Procedure LockAttributes()

	Items.HeaderGroup.ReadOnly = True;
	Items.AttributesGroup.ReadOnly = True;
	Items.GroupAdditionalAttributes.ReadOnly = True;
	Items.FooterGroup.ReadOnly = True;

EndProcedure

#EndRegion

&AtClient
Procedure EditAdjustment(ListLineData)
	
	LineID = ListLineData.RowID;
	FoundRows = Object.Operations.FindRows(New Structure("RowID", LineID));
	If Not FoundRows.Count() Then
		Return;
	EndIf;
	
	AttributesValues = New Structure(DetailsOfEnteringFine);
	AdjustmentLine = FoundRows[0];
	FillPropertyValues(AttributesValues, AdjustmentLine);
	AttributesValues.Insert("Organization", Object.Organization);
	AddlParameters = New Structure("LineID", LineID);
	
	OpenForm("Document.ElectronicTicketTransaction.Form.AdjustmentEntry",
		New Structure("AttributesValues, AttributesOfAdjustingEntries", AttributesValues, DetailsOfEnteringFine),
		,,,,
		New CallbackDescription("AfterEnteringAdjustment", ThisObject, AddlParameters),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AfterEnteringAdjustment(Result, AdditionalParameters) Export
	
	If Result = Undefined
		Or Result = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	TablesReceivers = New Map;
	TablesReceivers.Insert(Object.Operations, DetailsOfEnteringFine);
	TablesReceivers.Insert(Ticket_Operations, "PenaltyAmount");
	
	For Each TableDetails In TablesReceivers Do
		DestinationTable = TableDetails.Key;
		FoundRows = DestinationTable.FindRows(New Structure("RowID", AdditionalParameters.LineID));
		If FoundRows.Count() Then
			FillPropertyValues(FoundRows[0], Result, TableDetails.Value);
		EndIf;
	EndDo;
	
	Modified = True;
	
EndProcedure

&AtServer
Procedure TopUpVATRate()
	
	// Fill in the bid taking into account the current date of the document. We recalculate the related details of the tabular part.
	VATConversionParameters = New Structure("PriceIncludesVAT", True);
	
	StructureOfActions = New Structure;
	If Not ValueIsFilled(Object.Ref) Then
		StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	EndIf;
	StructureOfActions.Insert("RecalculateVATAmount", VATConversionParameters);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Operations, StructureOfActions, Undefined);
	
EndProcedure

&AtServer
Function FillInSubordinatePropertiesForStatistics(ParentPropsName)
	Return ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndFunction

&AtServerNoContext
Function ModificationOfAdvanceReportIsProhibited(Ref, ErrorMessage)
	Return PeriodClosingDates.DataChangesDenied(Metadata.Documents.ExpenseReport.FullName(), Ref, ErrorMessage);
EndFunction

&AtServer
Procedure MethodOfWriteOffDirectlyOnChangeATServer()
	
	UpdatePurchaseForActivity();
	ConfigureDependentFormElementsOnServer("DirectWriteOffMethod");
	
EndProcedure

&AtServer
Procedure PurchasingForActivitiesOnChangeATServer()
	
	If Not Object.PurchaseForActivity = Enums.VATTaxationTypes.SaleIsSubjectToVAT Then
		Object.AcceptVATForDeduction = False;
	EndIf;
	ConfigureDependentFormElementsOnServer("PurchaseForActivity");
	
EndProcedure

&AtClient
Procedure EmployeeOnChangeContinued(Result, AdditionalParameters) Export
	EmployeeOnChangeATServer(Result = DialogReturnCode.Yes);
EndProcedure

&AtServer
Procedure EmployeeOnChangeATServer(ToFillInPassengerSFullName)
	
	If ToFillInPassengerSFullName Then
		Object.PassengerSFullName = Common.ObjectAttributeValue(Object.Employee, "Description");
	EndIf;
	ConfigureDependentFormElementsOnServer("Employee");
	
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
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOfPurchaseOnChange(Items.DateOfPurchase);
	ElsIf Item.Name = "sh_ShamsiInput_PostingDate" Then
		PostingDateOnChange(Items.PostingDate);
	ElsIf Item.Name = "sh_ShamsiInput_ArrivalDate" Then
		ArrivalDateOnChange(Items.ArrivalDate);
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
