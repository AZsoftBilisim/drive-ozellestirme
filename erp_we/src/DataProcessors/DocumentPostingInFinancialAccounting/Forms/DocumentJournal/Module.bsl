#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	UseFinancialDocumentVerification = GetFunctionalOption("UseFinancialDocumentVerification");
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	URL = "e1cib/app/" + ThisObject.FormName;
	
	Items.TeamGroupDocumentVerification.Visible = AccessRight("Edit", Metadata.InformationRegisters.StatusOfDocumentVerification);
	
	UpdateFormData();
	
	UpdateSelectionByDocumentType();
	
	#Region InitialFillingByParameters
	
	If Parameters.Property("EndingDateOfPeriod") And Not Parameters.EndingDateOfPeriod = '39991231' Then
		Period.EndDate = Parameters.EndingDateOfPeriod;
		SetSelectionByPeriod(List, Period);
	EndIf;
	
	Parameters.Filter.Property("Organization", Organization);
	CommonClientServer.SetDynamicListFilterItem(List, "Organization", Organization, , , ValueIsFilled(Organization));
	
	Parameters.Filter.Property("ReflectionStatus", ReflectionStatus);
	CommonClientServer.SetDynamicListFilterItem(List, "ReflectionStatus", ReflectionStatus, , , Not ReflectionStatus.IsEmpty());
	
	Parameters.Filter.Property("ChartOfAccounts", ChartOfAccounts);
	CommonClientServer.SetDynamicListFilterItem(List, "ChartOfAccounts", ChartOfAccounts, DataCompositionComparisonType.Equal, , Not ChartOfAccounts.IsEmpty());
	
	#EndRegion
	
	#Region SettingAvailabilityOfCommandsBasedOnTransmittedSelections
	
	SetAvailabilityOfElementsByReflectionStatus();
	
	#EndRegion
	
	Items.Organization.Visible = GetFunctionalOption("UseMultipleCompanies");
	Items.CheckStatus.Visible = UseFinancialDocumentVerification;
	Items.SelectionGroupTop.United = UseFinancialDocumentVerification;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_DocumentPostingInFinancialAccounting"
		Or EventName = "Record_DocumentVerificationStatus" Then
		
		Items.List.Refresh();
		
	EndIf;
	
	If EventName = "Write_ConstantsSet" Then
		If Source = "UseFinancialDocumentVerification" Then
			UpdateFormData();
		EndIf;
	EndIf;
		
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Not Exit Then
		Notify("DocumentListFormIsClosed");
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompanyFilterOnChange(Item)
	CommonClientServer.SetDynamicListFilterItem(List, "Organization", Organization, , , ValueIsFilled(Organization));
	
	AttachIdleHandler("GetComment", 0.2, True);
	AttachIdleHandler("ConfigureAccessibilityOfListButtons", 0.2, True);
	
EndProcedure

&AtClient
Procedure ReflectionStatusSelectionOnChange(Item)
	
	TypeOfReflectionStatusComparison = ?(TypeOf(ReflectionStatus) = Type("ValueList"),
		DataCompositionComparisonType.InList, DataCompositionComparisonType.Equal);
	
	CommonClientServer.SetDynamicListFilterItem(List, "ReflectionStatus", ReflectionStatus,
		TypeOfReflectionStatusComparison, , Not ReflectionStatus.IsEmpty());
		
	SetAvailabilityOfElementsByReflectionStatus();
	AttachIdleHandler("ConfigureAccessibilityOfListButtons", 0.2, True);
	
EndProcedure

&AtClient
Procedure ChartOfAccountsOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "ChartOfAccounts", ChartOfAccounts,
		DataCompositionComparisonType.Equal, , Not ChartOfAccounts.IsEmpty());
	
	AttachIdleHandler("GetComment", 0.2, True);
	AttachIdleHandler("ConfigureAccessibilityOfListButtons", 0.2, True);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	ListLine = Items.List.CurrentData;
	ShowValue(Undefined, ListLine.Document);
	
EndProcedure // Listselection()

&AtClient
Procedure ListOnActivateRow(Item)
	
	AttachIdleHandler("GetComment", 0.2, True);
	AttachIdleHandler("ConfigureAccessibilityOfListButtons", 0.2, True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RecordInAccounting(Command)
	
	DocumentsArray = New Array;
	For Each Page1 In Items.List.SelectedRows Do
		Data = Items.List.RowData(Page1);
		
		If Not Data.ReflectionStatus = PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.PostedToAccounting")
			And Not Data.ReflectionStatus = PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting") Then
			
			DocumentsArray.Add(Data.Document);
			
		EndIf;
		
	EndDo;
	
	TimeConsumingOperation = StartReflectingDocumentsInInternationalAccounting(DocumentsArray, UUID);
	
	NotificationParameters = New Structure();
	NotificationParameters.Insert("Documents", DocumentsArray);
	
	CallbackOnCompletion = New CallbackDescription("ProcessResultOfDocumentsReflection", ThisObject, NotificationParameters);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.Title = NStr("vi = 'Phản ánh các chứng từ vào kế toán quốc tế';
								|ru = 'Отражение документов в международном учете';
								|en = 'Record documents in financial accounting'; fa = 'Record documents in financial accounting';
								|it = 'Visualizzazione dei documenti in contabilità internazionale';
								|pl = 'Odzwierciedlenie dokumentów w ewidencji międzynarodowej';
								|tr = 'Finansal muhasebede belge kaydı'");
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtClient
Procedure CancelVerification(Command)
	
	DocumentsArray = New Array;
	For Each ListLine In Items.List.SelectedRows Do
		Data = Items.List.RowData(ListLine);
		If Not Data.CheckStatus.IsEmpty() Then
			DocumentsArray.Add(Data.Document);
		EndIf;
	EndDo;
	
	MessageAboutErrors = SetCheckStatusOnServerAndReturnErrors(DocumentsArray, False);
	
	If DocumentsArray.Count() > 0 Then
		Notify("Record_DocumentVerificationStatus", DocumentsArray, ThisObject);
	EndIf;
	
	If ValueIsFilled(MessageAboutErrors) Then
		CommonClient.MessageToUser(MessageAboutErrors);
	EndIf;
	ConfigureAccessibilityOfListButtons();
EndProcedure

&AtClient
Procedure RemoveReflectionInAccounting(Command)
	
	DocumentsArray = New Array;
	For Each Page1 In Items.List.SelectedRows Do
		
		Data = Items.List.RowData(Page1);
		If Data.ReflectionStatus = PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.PostedToAccounting") Then
			
			DocumentsArray.Add(Data.Document);
			
		EndIf;
			
	EndDo;
	
	CancelReflectionOfDocumentsInAccountingOnServer(DocumentsArray);
	Notify("Write_DocumentPostingInFinancialAccounting", DocumentsArray, ThisObject);
	
	Items.List.Refresh();
	ConfigureAccessibilityOfListButtons();
	
EndProcedure

&AtClient
Procedure Validate(Command)
	
	DocumentsArray = New Array;
	For Each ListLine In Items.List.SelectedRows Do
		Data = Items.List.RowData(ListLine);
		If DocumentsTypesToBeChecked.ContainsType(TypeOf(Data.Document)) Then
			DocumentsArray.Add(Data.Document);
		EndIf;
	EndDo;
	
	MessageAboutErrors = SetCheckStatusOnServerAndReturnErrors(DocumentsArray, True);
	
	If DocumentsArray.Count() > 0 Then
		Notify("Record_DocumentVerificationStatus", DocumentsArray, ThisObject);
	EndIf;
	
	If ValueIsFilled(MessageAboutErrors) Then
		CommonClient.MessageToUser(MessageAboutErrors);
	EndIf;
	ConfigureAccessibilityOfListButtons();
EndProcedure

&AtClient
Procedure CreateAdjustmentBasedOn(Command)
	
	DocumentsArray = New Array;
	CurrentCompany = Organization;
	For Each Page1 In Items.List.SelectedRows Do
		RowData = Items.List.RowData(Page1);
		If Not TypeOf(RowData.Document) = Type("DocumentRef.TransactionFinancialAccounting") Then
			DocumentsArray.Add(RowData.Document);
		EndIf;
		If CurrentCompany.IsEmpty() Then
			CurrentCompany = RowData.Organization;
		ElsIf Not CurrentCompany = RowData.Organization Then
			ErrorText = NStr("vi = 'Chỉ có thể nhập chứng từ điều chỉnh đối với các chứng từ theo một doanh nghiệp';
							|ru = 'Документ корректировки можно ввести только для документов по одной организации';
							|en = 'You can enter the adjustment document only for the same company documents'; fa = 'You can enter the adjustment document only for the same company documents';
							|it = 'Documento di correzione inseribile solo per i documenti per una azienda';
							|pl = 'Dokument korekty można wprowadzić tylko dla dokumentów według jednej firmy';
							|tr = 'Sadece aynı iş yerine ait belgeler için düzeltme belgesi girilebilir.'");
			CommonClient.MessageToUser(ErrorText);
			Return;
		EndIf;
	EndDo;
	
	If DocumentsArray.Count() Then
		OperationParametersList = New Structure("Basis", DocumentsArray);
		OpenForm("Document.TransactionFinancialAccounting.ObjectForm", OperationParametersList);
	Else
		CommonClient.MessageToUser(NStr("vi = 'Không thể thực hiện lệnh này đối với giao dịch của kế toán quốc tế.';
										|ru = 'Данную команду нельзя выполнить для операции международного учета.';
										|en = 'Cannot execute this command for the financial accounting transaction.'; fa = 'Cannot execute this command for the financial accounting transaction.';
										|it = 'Questo comando non deve essere eseguito per le operazioni di contabilità internazionale.';
										|pl = 'To polecenie nie można wykonać dla operacji ewidencji międzynarodowej.';
										|tr = 'Bu komut finansal muhasebe işlemi için çalıştırılamaz.'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure DocumentTransactions(Command)
	
	CurrentRow = Items.List.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	Document = CurrentRow.Document;
	
	If TypeOf(Document) = Type("DocumentRef.TransactionFinancialAccounting") Then
		ShowValue(, Document);
	Else
		Filter = New Structure("Recorder", Document);
		FormParameters = New Structure("Filter", Filter);
		OpenForm("DataProcessor.DocumentPostingInFinancialAccounting.Form.FinancialAccountingPostings",
			FormParameters,
			Command,
			Document);
	EndIf;
		
EndProcedure

&AtClient
Procedure SetUpAccountingAccounts(Command)
	
	CurrentRow = Items.List.CurrentData;
	If CurrentRow = Undefined Then
		
		Return;
		
	EndIf;
	
	AddressValidationResult = "";
	
	CheckParameters = New Structure;
	
	CheckParameters.Insert("ChartOfAccounts", CurrentRow.ChartOfAccounts);
	CheckParameters.Insert("Document", CurrentRow.Document);
	
	FormParameters = CommonClient.CopyRecursive(CheckParameters);
	
	CheckParameters.Insert("Organization");
	
	YouNeedToConfigureRules = CheckConfigurationOfReflectionRulesInServerAccounting(AddressValidationResult, CheckParameters);
	
	FormParameters.Insert("AddressValidationResult", AddressValidationResult);
	
	OpenForm("DataProcessor.DocumentPostingInFinancialAccounting.Form.RequiredRecordingRules", FormParameters);
	
EndProcedure

&AtServer
Function CheckConfigurationOfReflectionRulesInServerAccounting(AddressInTempStorage, CheckParameters)
	
	CheckResult = DataProcessors.DocumentPostingInFinancialAccounting.CheckAccountingRulesSettings(CheckParameters);
	
	AddressInTempStorage = PutToTempStorage(CheckResult, UUID);
	
	YouNeedToConfigureRules = 
		CheckResult.BusinessTransactionsWithoutRecordingRules.Count() 
		Or CheckResult.AccountsWithoutRecordingRules.Count()
		Or CheckResult.AccountingObjectsThatRequireConfiguration.Count();
		
	Return YouNeedToConfigureRules;
	
EndFunction

&AtClient
Procedure SetDateInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(Period, , Notification);
	
EndProcedure

&AtClient
Procedure SetDateIntervalCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	Period = ValueSelected;
	SetSelectionByPeriod(List, Period);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();

	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CheckStatus.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.CheckStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không kiểm tra>';
													|ru = '<не проверяется>';
													|en = '<not under check>'; fa = '<not under check>';
													|it = '<non verificato>';
													|pl = '<nie jest sprawdzany>';
													|tr = '<denetlenmiyor>'"));
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentAuthor.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Author");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có>';
													|ru = '<отсутствует>';
													|en = '<missing>'; fa = '<missing>';
													|it = '<assente>';
													|pl = '<missing>';
													|tr = '<yok>'"));
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Number.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Number");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có>';
													|ru = '<отсутствует>';
													|en = '<missing>'; fa = '<missing>';
													|it = '<assente>';
													|pl = '<missing>';
													|tr = '<yok>'"));
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentContract.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Contract");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có>';
													|ru = '<отсутствует>';
													|en = '<missing>'; fa = '<missing>';
													|it = '<assente>';
													|pl = '<missing>';
													|tr = '<yok>'"));
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentCashAccount.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.CashAccount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có>';
													|ru = '<отсутствует>';
													|en = '<missing>'; fa = '<missing>';
													|it = '<assente>';
													|pl = '<missing>';
													|tr = '<yok>'"));
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentCounterparty.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Counterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có>';
													|ru = '<отсутствует>';
													|en = '<missing>'; fa = '<missing>';
													|it = '<assente>';
													|pl = '<missing>';
													|tr = '<yok>'"));
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentPartner.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Partner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có>';
													|ru = '<отсутствует>';
													|en = '<missing>'; fa = '<missing>';
													|it = '<assente>';
													|pl = '<missing>';
													|tr = '<yok>'"));
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentWarehouse.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có>';
													|ru = '<отсутствует>';
													|en = '<missing>'; fa = '<missing>';
													|it = '<assente>';
													|pl = '<missing>';
													|tr = '<yok>'"));
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentBusinessOperation.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có>';
													|ru = '<отсутствует>';
													|en = '<missing>'; fa = '<missing>';
													|it = '<assente>';
													|pl = '<missing>';
													|tr = '<yok>'"));
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentCurrency.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Currency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có>';
													|ru = '<отсутствует>';
													|en = '<missing>'; fa = '<missing>';
													|it = '<assente>';
													|pl = '<missing>';
													|tr = '<yok>'"));
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DocumentDocumentAmount.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.DocumentAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có>';
													|ru = '<отсутствует>';
													|en = '<missing>'; fa = '<missing>';
													|it = '<assente>';
													|pl = '<missing>';
													|tr = '<yok>'"));
	
EndProcedure

&AtServer
Procedure UpdateFormData()
	
	If GetFunctionalOption("UseFinancialDocumentVerification") Then
		
		DocumentsTypesToBeChecked = Metadata.InformationRegisters["StatusOfDocumentVerification"].Dimensions.Document.Type;
		CommonClientServer.SetDynamicListParameter(List, "ListOfTypesToBeChecked", DocumentVerificationServer.TypesOfDocumentsToBeChecked());
		
		ThereIsLock = Not GetFunctionalOption("AllowModificationOfAuditedFinancialDocuments");
		CommonClientServer.SetDynamicListParameter(List, "ThereIsLock", ThereIsLock);
	
	Else
		
		CommonClientServer.SetDynamicListParameter(List, "ListOfTypesToBeChecked", New Array);
		CommonClientServer.SetDynamicListParameter(List, "ThereIsLock", False);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByPeriod(List, Period)
	
	CommonClientServer.SetDynamicListParameter(
		List, "BeginOfPeriod", Period.StartDate, ValueIsFilled(Period.StartDate)); 
	
	CommonClientServer.SetDynamicListParameter(
		List, "EndOfPeriod", Period.EndDate, ValueIsFilled(Period.EndDate)); 
		
EndProcedure

&AtServerNoContext
Function SetCheckStatusOnServerAndReturnErrors(DocumentsArray, CheckStatus)
	
	ErrorsString = "";
	ErrorsData = New Map;
	
	InformationRegisters.StatusOfDocumentVerification.SetStatusOfDocumentVerification(DocumentsArray, ErrorsData, CheckStatus);
	
	If ErrorsData.Count() Then
		
		For Each Error In ErrorsData Do
			ErrorsString = ErrorsString + Error.Value + ";" + Chars.LF;
			IndexOfErroneousDocumentInArray = DocumentsArray.Find(Error.Key);
			If Not IndexOfErroneousDocumentInArray = Undefined Then
				DocumentsArray.Delete(IndexOfErroneousDocumentInArray);
			EndIf;
		EndDo;
		
	EndIf;
	
	Return ErrorsString;
	
EndFunction

&AtServerNoContext
Function StartReflectingDocumentsInInternationalAccounting(DocumentsArray, FormIdentifier)
	
	ReflectionParameters = FinancialAccountingPostingServer.ReflectionParametersInInternationalAccounting();
	ReflectionParameters.Documents = DocumentsArray;
	ReflectionParameters.CheckREFLECTIONStatus = False;
	
	Return FinancialAccountingPostingServer.StartReflectionInInternationalAccounting(ReflectionParameters, FormIdentifier);
	
EndFunction

&AtClient
Procedure ProcessResultOfDocumentsReflection(Result, AdditionalParameters) Export
	
	If Result = Undefined Or Result.Status = "Error" Then
		MessageText = NStr("vi = 'Khi phản ánh vào kế toán quốc tế, đã xảy ra lỗi:
			|%1';
			|ru = 'При отражении в международном учете произошла ошибка:
			|%1';
			|en = 'An error occurred when recording documents in financial accounting:
			|%1'; fa = 'An error occurred when recording documents in financial accounting:
			|%1';
			|it = 'При отражении в международном учете произошла ошибка:
			|%1';
			|pl = 'An error occurred when recording documents in financial accounting:
			|%1';
			|tr = 'Uluslararası muhasebeye yansıtılırken bir hata oluştu:
			|%1'");
		
		If Result = Undefined Then
			DecryptionText = NStr("vi = 'Không tìm thấy nhiệm vụ đang thực hiện.';
									|ru = 'Не найдено выполняемое задание.';
									|en = 'Job in progress is not found.'; fa = 'Job in progress is not found.';
									|it = 'Не найдено выполняемое задание.';
									|pl = 'Job in progress is not found.';
									|tr = 'Yürütülmekte olan görev bulunamadı.'");
		ElsIf ValueIsFilled(Result.BriefErrorDescription) Then
			DecryptionText = Result.BriefErrorDescription;
		Else
			DecryptionText = NStr("vi = 'Chi tiết xem trong Nhật ký sự kiện.';
									|ru = 'Подробности см. в Журнале регистрации.';
									|en = 'For more information, see the event log.'; fa = 'For more information, see the event log.';
									|it = 'Подробности см. в Журнале регистрации.';
									|pl = 'For more information, see the event log.';
									|tr = 'Ayrıntılar için Olay günlüğüne bakın.'");
		EndIf;
		
		MessageText = StrTemplate(MessageText, DecryptionText);

		Raise MessageText;
	EndIf;
	
	ProcessResultOfDocumentReflectionOnServer(AdditionalParameters.Documents);
	
	Notify("Write_DocumentPostingInFinancialAccounting", AdditionalParameters.Documents, ThisObject);
	
	Items.List.Refresh();
	ConfigureAccessibilityOfListButtons();
	
EndProcedure

&AtServerNoContext
Procedure ProcessResultOfDocumentReflectionOnServer(DocumentsArray)
	
	ReflectionStatuses = Enums.StatusesOfPostingsInFinancialAccounting;
	SelectionStatus = CommonClientServer.ValueInArray(ReflectionStatuses.ForManualPostingInAccounting);
	
	FinancialAccountingPostingServer.RecordNewReflectionStatus(DocumentsArray, ReflectionStatuses.ManuallyPostedToAccounting, SelectionStatus);
	
EndProcedure

&AtServerNoContext
Procedure CancelReflectionOfDocumentsInAccountingOnServer(DocumentsArray)
	
	FinancialAccountingPostingServer.CancelReflectionOfDocumentsInAccounting(DocumentsArray);
	
EndProcedure

#Region Formationquery

&AtServer
Procedure SetAvailabilityOfElementsByReflectionStatus()
	
	Items.GroupComment.Visible = (ReflectionStatus = Enums.StatusesOfPostingsInFinancialAccounting.RulesOfRecordingInAccountingAreNotdefined);
	
EndProcedure

&AtClient
Procedure ConfigureAccessibilityOfListButtons()
	
	ReflectAvailabilityInAccounting = False;
	RemoveReflectionInAvailabilityAccount = False;
	
	CheckAvailability = False;
	CancelAvailabilityCheck = False;
	
	If Items.List.SelectedRows.Count() > 0 Then
		
		For Each ListLine In Items.List.SelectedRows Do
			
			If Items.List.RowData(ListLine) = Undefined Then
				Continue;
			EndIf;
			
			StatusOfReflectionInLine = Items.List.RowData(ListLine).ReflectionStatus;
			If Not ReflectAvailabilityInAccounting Then
				ReflectAvailabilityInAccounting = 
					Not StatusOfReflectionInLine = PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.PostedToAccounting")
					And Not StatusOfReflectionInLine = PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting")
			EndIf;
			If Not RemoveReflectionInAvailabilityAccount Then
				RemoveReflectionInAvailabilityAccount = StatusOfReflectionInLine = PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.PostedToAccounting");
			EndIf;
			AvailabilityOfReflectionStatusCommandsIsDefined = ReflectAvailabilityInAccounting And RemoveReflectionInAvailabilityAccount;
			
			If UseFinancialDocumentVerification Then
				VerificationStatusInLine = Items.List.RowData(ListLine).CheckStatus;
				If Not CheckAvailability Then
					CheckAvailability = 
						Not VerificationStatusInLine = PredefinedValue("Enum.StatusOfFinancialDocumentVerification.Verified")
						And Not VerificationStatusInLine = PredefinedValue("Enum.StatusOfFinancialDocumentVerification.EmptyRef");
				EndIf;
				If Not CancelAvailabilityCheck Then
					CancelAvailabilityCheck = 
						Not VerificationStatusInLine = PredefinedValue("Enum.StatusOfFinancialDocumentVerification.ToReCheck")
						And Not VerificationStatusInLine = PredefinedValue("Enum.StatusOfFinancialDocumentVerification.NotVerified")
						And Not VerificationStatusInLine = PredefinedValue("Enum.StatusOfFinancialDocumentVerification.EmptyRef");
				EndIf;
				AvailabilityOfVerificationStatusCommandsIsDetermined = ReflectAvailabilityInAccounting And RemoveReflectionInAvailabilityAccount;
			Else
				AvailabilityOfVerificationStatusCommandsIsDetermined = True;
			EndIf;
			
			If AvailabilityOfReflectionStatusCommandsIsDefined And AvailabilityOfVerificationStatusCommandsIsDetermined Then
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Items.ListRecordInAccounting.Enabled = ReflectAvailabilityInAccounting;
	Items.ListRemoveReflectionInAccounting.Enabled = RemoveReflectionInAvailabilityAccount;
	
	If UseFinancialDocumentVerification Then
		Items.ListValidate.Enabled = CheckAvailability;
		Items.ListCancelVerification.Enabled = CancelAvailabilityCheck;
	EndIf;
	
EndProcedure

&AtClient
Procedure GetComment()
	
	If Not Items.GroupComment.Visible Then
		Return;
	EndIf;
	
	CurrentRow = Items.List.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	GetCommentServer(CurrentRow.Document, CurrentRow.Organization);
	
EndProcedure

&AtServer
Procedure GetCommentServer(Document, Organization)
	
	Comment = FinancialAccountingPostingServer.SummaryCommentOnDocument(Document, Organization);
	
EndProcedure

#EndRegion

&AtClient
Procedure HelpTextFilterURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "UpdateSelection_" Then
		
		UpdateSelectionByDocumentType();
		
	ElsIf FormattedStringURL = "ConfigureFilter" Then
		
		FormParameters = New Structure();
		FormParameters.Insert("AvailableBusinessTransactionsAndDocuments", PlaceBusinessTransactionsAndDocumentsInTemporaryStorage());
		FormParameters.Insert("SettingsKey", PurposeUseKey);
		FormParameters.Insert("OnlyByDocumentTypes", True);
		FormParameters.Insert("FormKey", DefaultFormAssignmentKey());
		
		OpenForm("Catalog.BusinessTransactionsSettings.Form.FormOfFilterSetting",
			FormParameters,,,,,
			New CallbackDescription("EstablishSelectionsForBusinessTransactionsAndDocuments", 
			ThisObject));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure EstablishSelectionsForBusinessTransactionsAndDocuments(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(ValueSelected) = Type("String") Then
		
		AddressOfAvailableBusinessTransactionsAndDocuments = ValueSelected;
		
		SelectionOperationTypeSelectionProcessingServer(AddressOfAvailableBusinessTransactionsAndDocuments);
		ConnectHyperlinkWaitingHandlerToLayout();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ConnectHyperlinkWaitingHandlerToLayout()
	
	If ValueIsFilled(JobID) Then
		AttachIdleHandler("Attachable_CheckTaskCompletion", 1, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure SelectionOperationTypeSelectionProcessingServer(AddressOfBusinessTransactionsAndDocuments)
	
	VTBusinessTransactionsAndDocumentTypes = GetFromTempStorage(AddressOfBusinessTransactionsAndDocuments);
	BusinessTransactionsAndDocuments.Load(VTBusinessTransactionsAndDocumentTypes);
	
	TKTypesOfDocuments = VTBusinessTransactionsAndDocumentTypes.Copy(New Structure("Filter", True), "DocumentType");
	TKTypesOfDocuments.GroupBy("DocumentType");
	
	FilterDocumentTypes.LoadValues(TKTypesOfDocuments.UnloadColumn("DocumentType"));
	
	ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes);
	
EndProcedure

&AtServer
Procedure ConfigureFormForSelectedOperationsAndDocuments(VTBusinessTransactionsAndDocumentTypes)
	
	WorkplaceData = TMCommonUse.WorkplaceData(VTBusinessTransactionsAndDocumentTypes,
		DefaultFormAssignmentKey(), NStr("vi = 'Nhật ký chứng từ kế toán quốc tế';
										|ru = 'Журнал документов международного учета';
										|en = 'Financial accounting document journal'; fa = 'دفتر اسناد حسابداری مالی';
										|it = 'Registro dei documenti di contabilità internazionale';
										|pl = 'Dziennik dokumentów ewidencji międzynarodowej';
										|tr = 'Finansal muhasebe belge günlüğü'"));
	
	Title   = WorkplaceData.WorkplaceTitle;
	CurrentKey = WorkplaceData.PurposeUseKey;
	
	SetDynamicListSelection_();
	
	HelpTextFilter = "";
	
	If VTBusinessTransactionsAndDocumentTypes.Count() = 0 Then
		
		HelpTextFilter = StringFunctions.FormattedString(
											NStr("vi = 'Không có chứng từ để hiển thị trong nhật ký <a href=""%1"">Cập nhật</a>';
												|ru = 'Нет документов для отображения в журнале <a href=""%1"">Обновить</a>';
												|en = 'No documents to record in journal <a href=""%1"">Update</a>'; fa = 'No documents to record in journal <a href=""%1"">Update</a>';
												|it = 'Нет документов для отображения в журнале <a href=""%1"">Обновить</a>';
												|pl = 'No documents to record in journal <a href=""%1"">Update</a>';
												|tr = '<a href=""%1"">Yenile</a> günlüğünde görüntülenecek belge yok'"),
											"UpdateSelection_");
	Else
		
		ThereAreSelections = BusinessTransactionsAndDocuments.FindRows(New Structure("Filter",False)).Count() > 0;
		If ThereAreSelections Then
			
			NumberOfDocumentTypes = StringFunctionsClientServer.StringWithNumberForAnyLanguage(NStr("vi = ';%1 chứng từ;;%1 chứng từ;%1 chứng từ;%1 chứng từ';
																									|ru = ';%1 документ;;%1 документа;%1 документов;%1 документа';
																									|en = ';%1 document;;%1 documents;%1 documents;%1 documents'; fa = ';%1 document;;%1 documents;%1 documents;%1 documents';
																									|it = ';%1 documento;;%1 documenti;%1 documenti;%1 documento';
																									|pl = ';%1 dokument;;%1 dokumenty;%1 dokumentów;%1 dokumenty';
																									|tr = ';%1 belge;;%1 belgenin;%1 belgelerin;%1 belgenin'"), FilterDocumentTypes.Count());
			
			HelpTextFilter = StringFunctions.FormattedString(
												NStr("vi = 'Hiển thị %1 <a href=""%2"">Tùy chỉnh</a>';
													|ru = 'Показаны %1 <a href=""%2"">Настроить</a>';
													|en = 'Shown %1 <a href=""%2"">Set up</a>'; fa = 'Shown %1 <a href=""%2"">Set up</a>';
													|it = 'Показаны %1 <a href=""%2"">Настроить</a>';
													|pl = 'Shown %1 <a href=""%2"">Set up</a>';
													|tr = '%1 <a href=""%2"">Ayarla</a> gösterildi'"),
												NumberOfDocumentTypes, "ConfigureFilter");
			
		Else
			
			HelpTextFilter = StringFunctions.FormattedString(
											NStr("vi = 'Hiển thị tất cả chứng từ trong nhật ký <a href=""%1"">Tùy chỉnh</a>';
												|ru = 'Показаны все документы журнала <a href=""%1"">Настроить</a>';
												|en = 'All journal documents are shown <a href=""%1"">Set up</a>'; fa = 'All journal documents are shown <a href=""%1"">Set up</a>';
												|it = 'Показаны все документы журнала <a href=""%1"">Настроить</a>';
												|pl = 'All journal documents are shown <a href=""%1"">Set up</a>';
												|tr = '<a href=""%1"">Ayarla</a> günlüğünün tüm belgeleri gösterildi'"),
											"ConfigureFilter");
			
		EndIf;
	
	EndIf;
	
	Items.HelpTextFilter.Title = HelpTextFilter;
	
EndProcedure

&AtServer
Function PlaceBusinessTransactionsAndDocumentsInTemporaryStorage()
	Return PutToTempStorage(BusinessTransactionsAndDocuments.Unload(), UUID);
EndFunction

&AtClientAtServerNoContext
Function DefaultFormAssignmentKey()
	
	Return "JournalOfInternationalAccountingDocuments";
	
EndFunction

&AtServer
Procedure SetDynamicListSelection_()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"DocumentType",
		FilterDocumentTypes,
		DataCompositionComparisonType.InList,
		,
		True);
	
EndProcedure

&AtServer
Procedure UpdateSelectionByDocumentType()

	FilterDocumentTypes.Clear();
	
	MetadataReflectionOfDocumentsInInternationalAccounting = Metadata.InformationRegisters.DocumentPostingInFinancialAccounting;
	ArrayOfDocumentNames = New Array;
	For Each MetadataObject In Metadata.Documents Do
		If Not MetadataObject.RegisterRecords.Contains(MetadataReflectionOfDocumentsInInternationalAccounting) Then
			Continue;
		EndIf;
		If Not Common.MetadataObjectAvailableByFunctionalOptions(MetadataObject) Then
			Continue;
		EndIf;
		NewRow = BusinessTransactionsAndDocuments.Add();
		NewRow.FullDocumentName = MetadataObject.FullName();
		NewRow.Filter = True;
		NewRow.DocumentType = Type("DocumentRef." + MetadataObject.Name);
		NewRow.DocumentPresentation = MetadataObject.Synonym;
		
		FilterDocumentTypes.Add(NewRow.DocumentType);
		ArrayOfDocumentNames.Add(NewRow.FullDocumentName);
	EndDo;
	
	MetadataObjectIDs = Common.MetadataObjectIDs(ArrayOfDocumentNames);
	For Each TableRow In BusinessTransactionsAndDocuments Do
		TableRow.MetadataObjectID = MetadataObjectIDs[TableRow.FullDocumentName];
	EndDo;
	
	ConfigureFormForSelectedOperationsAndDocuments(BusinessTransactionsAndDocuments.Unload());
	
EndProcedure

#EndRegion
