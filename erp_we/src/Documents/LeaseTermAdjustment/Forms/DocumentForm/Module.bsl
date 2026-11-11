#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	AddressOfTheContractSchedule = PutToTempStorage(Undefined, UUID);
	
	ItemsAndDimensionsSelectionParameters = Documents.LeaseTermAdjustment.ItemsAndDimensionsSelectionParameters(
			LeasedAssetAccounting.CreatedForSwitchingToFSB25_2018(Object.Date, Object.Organization));
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	AccountSettings_ = Documents.LeaseTermAdjustment.AccountingAccountSettings_();
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, AccountSettings_);
	
	#Region StandardSubsystems
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.FilesOperations

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	ItemsAndDimensionsSelectionParameters = Documents.LeaseTermAdjustment.ItemsAndDimensionsSelectionParameters(
				LeasedAssetAccounting.CreatedForSwitchingToFSB25_2018(CurrentObject.Date, CurrentObject.Organization));
				
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);

	SetupParameters = Documents.LeaseTermAdjustment.AccountingAccountSettings_();
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	FillInServiceDetailsOfTS();
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_LeaseTermAdjustment", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Catalog.BusinessStructure.Form.ChoiceForm" Then
		
		SelectedRows = Items.FA.SelectedRows;
		RequiredAction
			= CommonClient.PredefinedItem("Enum.ActionsWithRentalObjects.Rent");
		
		For Each SelectedRow In SelectedRows Do
			RowData = Object.FA.FindByID(SelectedRow);
			If RowData.ActionWithRentalObject = RequiredAction Then
				RowData.Department = ValueSelected;
			EndIf;
		EndDo;
		
	ElsIf ChoiceSource.FormName = "ChartOfCharacteristicTypes.ExpenseItems.Form.ChoiceForm" Then
		
		SelectedRows = Items.FA.SelectedRows;
		RequiredAction
			= CommonClient.PredefinedItem("Enum.ActionsWithRentalObjects.Rent");
		
		For Each SelectedRow In SelectedRows Do
			RowData = Object.FA.FindByID(SelectedRow);
			If RowData.ActionWithRentalObject = RequiredAction Then
				RowData.ExpenseItem = ValueSelected;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region PageGeneral

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	NonCurrentAssetsClient.SetCurrentTimeForLastDate(Object.Date);

	If ValueIsFilled(Object.Contract) Then
		QueryText = NStr("vi = 'Điền lại dữ liệu chứng từ theo điều kiện hợp đồng vào ngày đã chọn?';
						|ru = 'Перезаполнить данные документа по условиям договора на выбранную дату?';
						|en = 'Do you want to refill the document data based on the contract terms as of the selected date?'; fa = 'Do you want to refill the document data based on the contract terms as of the selected date?';
						|it = 'Перезаполнить данные документа по условиям договора на выбранную дату?';
						|pl = 'Do you want to refill the document data based on the contract terms as of the selected date?';
						|tr = 'Belge verileri, seçilen tarih için sözleşme şartlarına göre yeniden doldurulsun mu?'");
		CallbackDescription = New CallbackDescription("DateOnChangeCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	Else
		DateOfChangeOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerWhenChangesAreMadeOnServer();
	FillInTheContract();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyWhenChangesAreMadeOnServer();
	FillInTheContract();

EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	AgreementWhenModifiedOnServer();
	FillInTheContract();
	
EndProcedure

&AtClient
Procedure ContractStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Item = Items.Contract And ValueIsFilled(Object.NewContract) Then
		
		ContractSelectionParameters_ = New Array(Item.ChoiceParameters);
		
		NameOfStatusParameter = "Filter.Status";
		NameOfStateParameter = "Filter.State";
		StatusSelectionParameter = Undefined;
		StateSelectionParameter = Undefined;
		
		For Each ChoiceParameter In ContractSelectionParameters_ Do
			
			If ChoiceParameter.Name = NameOfStatusParameter Then
				StatusSelectionParameter = ChoiceParameter;
			ElsIf ChoiceParameter.Name = NameOfStateParameter Then
				StateSelectionParameter = ChoiceParameter;
			EndIf;
				
		EndDo;
		
		If StatusSelectionParameter <> Undefined Then
			ContractSelectionParameters_.Delete(ContractSelectionParameters_.Find(StatusSelectionParameter));
		EndIf;
		
		If StateSelectionParameter <> Undefined Then
			ContractSelectionParameters_.Delete(ContractSelectionParameters_.Find(StateSelectionParameter));
		EndIf;
		
		Item.ChoiceParameters = New FixedArray(ContractSelectionParameters_);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure IncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure IncomeItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
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
Procedure PresentationOfTheReflectionInTheReglAccountingExpensesClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure AdjustmentDueToChangeOfAccountingPolicyOnChange(Item)
		
	Object.PeriodAdjustment = ?(AdjustmentDueToChangeOfAccountingPolicy,
		LocalAccntingClientServer.MainValueOfClarifyingInterReportingPeriod(), 0);
	
	If Object.PeriodAdjustment <> 0 And Object.Date <> EndOfYear(Object.Date) Then
		 Object.Date = EndOfYear(Object.Date);
	EndIf;
	
EndProcedure

#EndRegion

#Region LeaseTermsPage

&AtClient
Procedure IndicatorPreviousConditionsAreIrrelevantClick(Item)
	
	If ValueIsFilled(CurrentPreviousTermsOfContract) Then
		ShowValue(, CurrentPreviousTermsOfContract);
	EndIf;
	
EndProcedure

&AtClient
Procedure SecurityDepositAmountOnChange(Item)
	
	RecalculateContractAmountAndVATAmount(Object);
	
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure DateOfFirstSecurityPaymentOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	ConfigureDependentFormElements(Item);
EndProcedure

&AtClient
Procedure LeaseServicesAmount(Item)
	
	AmountOfRentalServicesWhenChangedOnServer();

EndProcedure

&AtClient
Procedure DateOfFirstPaymentOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	ConfigureDependentFormElements(Item);
EndProcedure

&AtClient
Procedure AmountOfLeaseAssetsByuoutOnChange(Item)
	
	AmountOfRedemptionOfRentalItemsWhenChangingOnServer();

EndProcedure

&AtClient
Procedure VATAmountOnChange(Item)
	
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure VATRateOnChange(Item)
	
	LeasedAssetAccountingClientServer.RecalculateAmountOfRentalDocument(Object);
	RecalculateAmountOfVATRepurchaseOfRentalItems(Object);
	
	CurPercentVAT = VATAccountingERPClientServer.ValueOfVATRate(Object.VATRate);
	Object.VATAmount = VATAccountingERPClientServer.CalculateVATAmount(Object.LeaseServicesAmount, CurPercentVAT, True)
		+ VATAccountingERPClientServer.CalculateVATAmount(Object.SecurityDepositAmount, CurPercentVAT, True)
		+ Object.AmountOfVATRepurchaseOfRentalItems;
	
	ConfigureDependentFormElementsOnServer("VATRate");

EndProcedure

&AtClient
Procedure RentalPeriodURLProcessing(Item, FormattedStringURL, StandardProcessing)

	StandardProcessing = False;
	
	LeasedAssetAccountingClient.EnterLeaseTerm(
		ThisObject, 
		Object,
		New CallbackDescription("EnterLeaseTermCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure PaymentFrequencyOnChange(Item)
	
	If Not ValueIsFilled(Object.PaymentFrequency) Then
		Object.PaymentFrequency = PredefinedValue("Enum.ScheduleTimeFence.Month");
	EndIf;

	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure AccrualFrequencyOnChange(Item)
	
	If Not ValueIsFilled(Object.AccrualFrequency) Then
		Object.AccrualFrequency = PredefinedValue("Enum.ScheduleTimeFence.Month");
	EndIf;

	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure PaymentForLeaseServiceOnChange(Item)
	
	ChangedBankingDetails = Item.Name;
	
	If Object.PaymentFrequency = Object.AccrualFrequency
		And Object.PaymentFrequency <> PredefinedValue("Enum.ScheduleTimeFence.Custom")
		And Object.AccrualOfLeaseService = 0
		And Object.PaymentForLeaseService <> 0 Then
			
		Object.AccrualOfLeaseService = Object.PaymentForLeaseService;
		ChangedBankingDetails = ChangedBankingDetails + ",AccrualOfLeaseService";
	EndIf;
	
	ConfigureDependentFormElements(ChangedBankingDetails);

EndProcedure

&AtClient
Procedure AccrualOfLeaseServiceOnChange(Item)
	
	ChangedBankingDetails = Item.Name;
	
	If Object.PaymentFrequency = Object.AccrualFrequency
		And Object.PaymentFrequency <> PredefinedValue("Enum.ScheduleTimeFence.Custom")
		And Object.PaymentForLeaseService = 0
		And Object.AccrualOfLeaseService <> 0 Then
			
		Object.PaymentForLeaseService = Object.AccrualOfLeaseService;
		ChangedBankingDetails = ChangedBankingDetails + ",PaymentForLeaseService";
	EndIf;
	
	ConfigureDependentFormElements(ChangedBankingDetails);

EndProcedure

&AtClient
Procedure BasementInformationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "#FillInSchedule" Then
		FillInScheduleAccordingToCalculations();
		ElsIf FormattedStringURL = "#FillInCalculationsAccordingToSchedule" Then
		FillInCalculationsAccordingToSchedule();
	EndIf;
	
EndProcedure

&AtClient
Procedure NewCounterpartyOnChange(Item)
	
	ConfigureDependentFormElements("NewPartner");
	
EndProcedure

&AtClient
Procedure NewPartnerOnChange(Item)
	
	ConfigureDependentFormElements("NewCounterparty");
	
EndProcedure

&AtClient
Procedure NewContractOnChange(Item)

	ConfigureDependentFormElements("NewContract");

EndProcedure

#EndRegion

#Region StandardSubsystems

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)

	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);

EndProcedure
// End StandardSubsystems.FilesOperations


#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersFA

&AtClient
Procedure FASelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.FA.CurrentData;
	
	If CurrentData <> Undefined
		And Field = Items.FAFixedAsset
		And ValueIsFilled(CurrentData.FixedAsset)
		And (ReadOnly 
			Or ValueIsFilled(CurrentData.ActionWithRentalObject) And CurrentData.ActionWithRentalObject <> 
				PredefinedValue("Enum.ActionsWithRentalObjects.Rent")) Then
			
		StandardProcessing = False;
		ShowValue(, CurrentData.FixedAsset);
			
	EndIf;

EndProcedure

&AtClient
Procedure FAOnEditEnd(Item, NewRow, CancelEdit)
	
	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure FAFixedAssetOnChange(Item)
	
	MainRemedyWhenChangingOnServer();

EndProcedure

&AtClient
Procedure FAFairValueOnChange(Item)
	
	CalculateCostOfFA();
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure FANonGuaranteedFinalCostOnChange(Item)
	
	CalculateCostOfFA();
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure FAActionWithRentalObjectStartChoice(Item, ChoiceData, StandardProcessing)
	
	ContractDetails_ = FormServiceParameters.ContractDetails_;
	
	ChoiceList = Item.ChoiceList;
	
	CurrentData = Items.FA.CurrentData; 
	If CurrentData.ActionWithRentalObject = 
		CommonClient.PredefinedItem("Enum.ActionsWithRentalObjects.Rent") Then
		ChoiceList.Clear();
		ChoiceList.Add(CommonClient.PredefinedItem("Enum.ActionsWithRentalObjects.Rent"));
	Else
		ChoiceList.Clear();
		ChoiceList.Add(CommonClient.PredefinedItem("Enum.ActionsWithRentalObjects.RentalTermsAdjustment"));
		If ContractType = CommonClient.PredefinedItem("Enum.TypesOfLeaseContracts.Lease")
			And (ContractDetails_.MethodForDeterminingCostOfAssets =
				CommonClient.PredefinedItem("Enum.MethodsOfDeterminingLeasedAssetCost.Discounting")
			Or ContractDetails_.MethodForDeterminingCostOfAssets =
				CommonClient.PredefinedItem("Enum.MethodsOfDeterminingLeasedAssetCost.ByContractAmount"))
			Then
				ChoiceList.Add(CommonClient.PredefinedItem("Enum.ActionsWithRentalObjects.RentalTermination"));
		EndIf;
		If ContractDetails_.ThereIsBuyoutOfLeasedAssets Then
			ChoiceList.Add(CommonClient.PredefinedItem("Enum.ActionsWithRentalObjects.EarlyRedemption"));
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure FAOnStartEdit(Item, NewRow, Copy)
	
	If NewRow And Not Copy Then
		CurrentData = Items.FA.CurrentData;
		CurrentData.ActionWithRentalObject = CommonClient.PredefinedItem("Enum.ActionsWithRentalObjects.Rent");
	EndIf;
	
EndProcedure

&AtClient
Procedure FAOnChange(Item)
	
	FillInFAServiceDetails();
	
EndProcedure

&AtClient
Procedure FABeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.FA.CurrentData;
	If CurrentData <> Undefined
		And CurrentData.ActionWithRentalObject 
		<> CommonClient.PredefinedItem("Enum.ActionsWithRentalObjects.EmptyRef")
		And CurrentData.ActionWithRentalObject 
			<> CommonClient.PredefinedItem("Enum.ActionsWithRentalObjects.Rent") Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure FAFixedAssetStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Item = Items.FAFixedAsset
		And ValueIsFilled(Object.Contract)
		And FormServiceParameters.Property("ContractDetails_") Then
		
		FASelectionOptions = New Array(Item.ChoiceParameters);
		
		AccountingParametersForRentalItems = LeasedAssetAccountingClientServer.AccountingParametersForRentalItems(
			FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed,
			FormServiceParameters.ContractDetails_);
			
		MAParameterName = "Filter.RecordInManAccounting";
		ACParameterName = "Filter.RecordInLocalAccounting";
		MASelectionParameter = Undefined;
		ACSelectionParameter = Undefined;
		
		For Each ChoiceParameter In FASelectionOptions Do
			
			If ChoiceParameter.Name = MAParameterName Then
				MASelectionParameter = ChoiceParameter;
				NewMASelectionOption = New ChoiceParameter(MAParameterName, AccountingParametersForRentalItems.ThereIsMaAccount);
			ElsIf ChoiceParameter.Name = ACParameterName Then
				ACSelectionParameter = ChoiceParameter;
				NewACSelectionParameter = New ChoiceParameter(ACParameterName, AccountingParametersForRentalItems.ThereIsACAccounting);
			EndIf;
				
		EndDo;
		
		If MASelectionParameter <> Undefined Then
			FASelectionOptions.Delete(FASelectionOptions.Find(MASelectionParameter));
			FASelectionOptions.Add(NewMASelectionOption);
		EndIf;
		
		If ACSelectionParameter <> Undefined Then
			FASelectionOptions.Delete(FASelectionOptions.Find(ACSelectionParameter));
			FASelectionOptions.Add(NewACSelectionParameter);
		EndIf;
		
		Item.ChoiceParameters = New FixedArray(FASelectionOptions);
		
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure OpenPaymentSchedule(Command)
	
	OpenPaymentAndAccrualSchedule("ServicePaymentSchedule");
	
EndProcedure

&AtClient
Procedure OpenTheAccrualSchedule(Command)
	
	OpenPaymentAndAccrualSchedule("ServiceAccrualSchedule");

EndProcedure

&AtClient
Procedure OpenTheInterestAccrualSchedule(Command)
	
	OpenPaymentAndAccrualSchedule("InterestAccrualSchedule");

EndProcedure

&AtClient
Procedure CalculateTheBidOrCost(Command)
	
	If LeasedAssetAccountingClient.YouCanCalculateRateOrCost(
		Object, FormServiceParameters.ContractDetails_, "FA",, PreviousConditions) Then
		CalculateRateCostPercentagesOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheRentedOnes(Command)
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Contract) Then
		MessageText = NStr("vi = 'Cần chọn hợp đồng';
							|ru = 'Необходимо выбрать договор';
							|en = 'Select a contract'; fa = 'Select a contract';
							|it = 'È necessario selezionare l''accordo';
							|pl = 'Należy wybrać umowę';
							|tr = 'Bir sözleşme seçmek gereklidir'");
		CommonClient.MessageToUser(MessageText,, "Contract", "Object");
		Return;
	EndIf;

	If Object.FA.Count() <> 0 Then
		QueryText = NStr("vi = 'Điền danh sách đối tượng thuê theo hợp đồng?';
						|ru = 'Заполнить список предметов аренды по договору?';
						|en = 'Populate the list of rental objects under the contract?'; fa = 'Populate the list of rental objects under the contract?';
						|it = 'Compilare l''elenco degli elementi di affitto in base all''accordo?';
						|pl = 'Wypełnić listę przedmiotów dzierżawy zgodnie z umową?';
						|tr = 'Sözleşme kapsamında kiralanan eşyaların listesini doldurun?'");
		CallbackDescription = New CallbackDescription("FillInTheRentedOnesCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	Else
		FillWithRentedOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateByPreviousConditions(Command)
	
	QueryText = NStr("vi = 'Cập nhật dữ liệu chứng từ theo điều kiện trước đó của hợp đồng?';
					|ru = 'Обновить данные документа по предыдущим условиям договора?';
					|en = 'Do you want to update the document data based on the previous contract terms?'; fa = 'Do you want to update the document data based on the previous contract terms?';
					|it = 'Обновить данные документа по предыдущим условиям договора?';
					|pl = 'Do you want to update the document data based on the previous contract terms?';
					|tr = 'Belge verileri sözleşmenin önceki şartlarına göre güncellensin mi?'");
	CallbackDescription = New CallbackDescription("UpdateByPreviousConditionsCompletion", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure FillInTheDepartment(Command)
		
	SelectedRows = Items.FA.SelectedRows;
	
	RequiredAction
		= CommonClient.PredefinedItem("Enum.ActionsWithRentalObjects.Rent");
	ThereAreSuitableLines = False;
	For Each SelectedRow In SelectedRows Do
		RowData = Object.FA.FindByID(SelectedRow);
		If RowData.ActionWithRentalObject = RequiredAction Then
			ThereAreSuitableLines = True;
			Break;
		EndIf;
	EndDo;
	
	If Object.FA.Count() = 0 Then
		ShowMessageBox( , NStr("vi = 'Không có dòng nào được nhập vào danh sách ""Tài sản cố định hữu hình"".';
								|ru = 'В список ""ОС"" не введено ни одной строки.';
								|en = 'No lines are entered in the Fixed assets list.'; fa = 'No lines are entered in the Fixed assets list.';
								|it = 'В список ""ОС"" не введено ни одной строки.';
								|pl = 'No lines are entered in the Fixed assets list.';
								|tr = '""SV"" listesine herhangi bir satır girilmemiştir.'"));
		Return;
	ElsIf Not ThereAreSuitableLines Then
		ShowMessageBox( , NStr("vi = 'Trong danh sách ""Tài sản cố định hữu hình"" chưa chọn dòng nào với thao tác ""Lấy cho thuê"".';
								|ru = 'В списке ""ОС"" не выбрано ни одной строки с действием ""Взятие в аренду"".';
								|en = 'In the Fixed assets list, no line with the Rent action is selected.'; fa = 'In the Fixed assets list, no line with the Rent action is selected.';
								|it = 'В списке ""ОС"" не выбрано ни одной строки с действием ""Взятие в аренду"".';
								|pl = 'In the Fixed assets list, no line with the Rent action is selected.';
								|tr = '""SV"" listesinde ""Kiralama"" eylemini içeren herhangi bir satır seçilmedi.'"));
		Return;
	EndIf;
	
	OpenForm("Catalog.BusinessStructure.ChoiceForm",, ThisObject);
	
EndProcedure

&AtClient
Procedure FillInExpenseItem(Command)
	
	SelectedRows = Items.FA.SelectedRows;
	
	SuitableHighlightedLines = New Array;
	RequiredAction
		= CommonClient.PredefinedItem("Enum.ActionsWithRentalObjects.Rent");
	For Each SelectedRow In SelectedRows Do
		RowData = Object.FA.FindByID(SelectedRow);
		If RowData.ActionWithRentalObject = RequiredAction Then
			SuitableHighlightedLines.Add(SelectedRow);
		EndIf;
	EndDo;
	
	If Object.FA.Count() = 0 Then
		ShowMessageBox( , NStr("vi = 'Không có dòng nào được nhập vào danh sách ""Tài sản cố định hữu hình"".';
								|ru = 'В список ""ОС"" не введено ни одной строки.';
								|en = 'No lines are entered in the Fixed assets list.'; fa = 'No lines are entered in the Fixed assets list.';
								|it = 'В список ""ОС"" не введено ни одной строки.';
								|pl = 'No lines are entered in the Fixed assets list.';
								|tr = '""SV"" listesine herhangi bir satır girilmemiştir.'"));
		Return;
	ElsIf SuitableHighlightedLines.Count() = 0 Then
		ShowMessageBox( , NStr("vi = 'Trong danh sách ""Tài sản cố định hữu hình"" chưa chọn dòng nào với thao tác ""Lấy cho thuê"".';
								|ru = 'В списке ""ОС"" не выбрано ни одной строки с действием ""Взятие в аренду"".';
								|en = 'In the Fixed assets list, no line with the Rent action is selected.'; fa = 'In the Fixed assets list, no line with the Rent action is selected.';
								|it = 'В списке ""ОС"" не выбрано ни одной строки с действием ""Взятие в аренду"".';
								|pl = 'In the Fixed assets list, no line with the Rent action is selected.';
								|tr = '""SV"" listesinde ""Kiralama"" eylemini içeren herhangi bir satır seçilmedi.'"));
		Return;
	EndIf;
	
	ListFilter = New Structure;
	ListFilter.Insert("ExpensesOnAssets", True);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", ListFilter);
	OpenForm("ChartOfCharacteristicTypes.ExpenseItems.ChoiceForm", FormParameters, ThisObject);
	
EndProcedure

#Region StandardSubsystems

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.FilesOperations

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtClient
Procedure ConfigureDependentFormElements(Val ChangedDetailsOrElement = "")

	If TypeOf(ChangedDetailsOrElement) = Type("String") Then
		ChangedBankingDetails = ChangedDetailsOrElement;
	Else
		ChangedBankingDetails = ChangedDetailsOrElement.Name;
	EndIf;

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	If RequiresServerCallToConfigureFormElements(StructureOfChangedProps) Then
		ConfigureDependentFormElementsOnServer(ChangedBankingDetails)
	Else
		ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Val Form, Val ChangedBankingDetails = "")
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	Object = Form.Object;
	Items = Form.Items;
	FormServiceParameters = Form.FormServiceParameters;
	ContractDetails_ = FormServiceParameters.ContractDetails_;
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("VNAManagementIsUsed_2_4", FormServiceParameters.VNAManagementIsUsed_2_4);
	AuxiliaryAttributes.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed", FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed);
	AuxiliaryAttributes.Insert("StartOfLeaseAccountingUnderFSB25_2018", FormServiceParameters.StartOfLeaseAccountingUnderFSB25_2018);
	AuxiliaryAttributes.Insert("ContractDetails_", FormServiceParameters.ContractDetails_);
	AuxiliaryAttributes.Insert("InsignificantVATRate", FormServiceParameters.InsignificantVATRate);
	AuxiliaryAttributes.Insert("CurrencyOfMan", FormServiceParameters.CurrencyOfMan);
	AuxiliaryAttributes.Insert("ComplCurrency", FormServiceParameters.ComplCurrency);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", FormServiceParameters.CurrencyOfMan = FormServiceParameters.ComplCurrency);
	AuxiliaryAttributes.Insert("RecordInOperationalAccounting", True);
	AuxiliaryAttributes.Insert("DocumentVersion24", False);
	AuxiliaryAttributes.Insert("NameOfFATablePart", "FA");
	AuxiliaryAttributes.Insert("ChangingConditions", True);

	ItemDetailsParameters = LeasedAssetAccountingClientServer.PropertyValuesOfDependentDetails_ChangesInTermsOfLeaseAgreement(
									Object, AuxiliaryAttributes, ChangedBankingDetails);
									
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(Object, ItemDetailsParameters, "FA,ServicePaymentSchedule,ServiceAccrualSchedule,InterestAccrualSchedule");
	EndIf;
	
	AccountingForBalanceSheet = (FormServiceParameters.ContractDetails_.AssetHolder = PredefinedValue("Enum.LeasedAssetHolder.Lessor"));
	
	#Region PageGeneral
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then
		Items.Comment.MaxWidth = 
			?(FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed Or Not AccountingForBalanceSheet, 67, 75);
	EndIf;
	
	If StructureOfChangedProps.Property("NewPartner")
		Or StructureOfChangedProps.Property("NewCounterparty")
		Or StructureOfChangedProps.Property("NewContract")
		Or UpdateAll Then
		RequiredFilling_ = ValueIsFilled(Object.NewPartner)
							Or ValueIsFilled(Object.NewCounterparty)
							Or ValueIsFilled(Object.NewContract);
		Items.NewPartner.MarkIncomplete = RequiredFilling_ And Not(ValueIsFilled(Object.NewPartner));
		Items.NewCounterparty.MarkIncomplete = RequiredFilling_ And Not(ValueIsFilled(Object.NewCounterparty));
		Items.NewContract.MarkIncomplete = RequiredFilling_ And Not(ValueIsFilled(Object.NewContract));
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		Form.AdjustmentDueToChangeOfAccountingPolicy = Object.PeriodAdjustment <> 0;
		Items.AdjustmentDueToChangeOfAccountingPolicy.Visible = (EndOfDay(Object.Date) = EndOfYear(Object.Date));
	EndIf;

	#EndRegion

	#Region OSPage
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then
			
		Items.FABuyoutValue.Visible = ContractDetails_.ThereIsBuyoutOfLeasedAssets;
		
		PropertyValue = 
			(Items.FAFairValue.Visible
			+ Items.FANonGuaranteedFinalCost.Visible
			+ Items.FABuyoutValue.Visible
			+ Items.FACost.Visible) > 1;
			
		Items.OsgroupCost.ShowTitle = PropertyValue;
		Items.OsgroupCost.ShowInHeader = PropertyValue;
		
	EndIf;

	#EndRegion
			
	#Region FooterGroup
	
	If StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then
		
		PurchaseIsSubjectToVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfProcurementDocument(ContractDetails_.VATTaxation);
		
		If PurchaseIsSubjectToVAT Then
			Items.VATPageGroup.CurrentPage   = Items.PageVAT;
			Items.PagesTotalGroup.CurrentPage = Items.TotalSNDSPage;
		Else
			Items.VATPageGroup.CurrentPage   = Items.PageExcludingVAT;
			Items.PagesTotalGroup.CurrentPage = Items.PageTotalWithoutVAT;
		EndIf;
	
	EndIf;
	
	#EndRegion
	
	LeasedAssetAccountingClientServer.ConfigureDependentFormElements__(Form, AuxiliaryAttributes, ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure FAActionWithRentalObjectOnChange(Item)
	
	ConfigureDependentFormElements(Item);

EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(Val ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	#Region Other
	
	If UpdateAll Then
		
		If Not FormServiceParameters.UseVATAccounting Then
			Items.AmountOfPersonalIncomeTax.Visible = False;
		EndIf;
		
	EndIf;

	If StructureOfChangedProps.Property("Organization") 
		Or UpdateAll Then
		ParentCompany = AccountingPoliciesTaxSettingsCached.ParentCompany(Object.Organization);
		SetFormFunctionalOptionParameters(New Structure("Organization", ParentCompany));
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"StartOfLeaseAccountingUnderFSB25_2018",
			LeasedAssetAccounting.StartOfLeaseAccountingUnderFSB25_2018(Object.Organization),
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplCurrency",
			LocalAccountingCurrency,
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplCurrencyPresentation",
			String(LocalAccountingCurrency),
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"CurrenciesDoNotMatch",
			FormServiceParameters.CurrencyOfMan = LocalAccountingCurrency,
			FormServiceParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("Date") Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"VNAManagementIsUsed_2_4",
			NonCurrentAssets.VNAManagementIsUsed_2_4(Object.Date),
			FormServiceParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization") Then
		
		ParameterValue = 
			LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Object.Organization, Object.Date)
			Or LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Object.Organization, EndOfMonth(Object.Date)+1);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"LeaseAccountingAccordingToFSB25_2018IsUsed",
			ParameterValue,
			FormServiceParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("VATRate") Or StructureOfChangedProps.Property("Contract") Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"InsignificantVATRate",
			VATAccountingERP.InsignificantRate(Object.VATRate),
			FormServiceParameters);
		
	EndIf;
	
	#EndRegion

	#Region ItemsTitles
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then
		
		CreatedForTransition = LeasedAssetAccounting.CreatedForSwitchingToFSB25_2018(Object.Date, Object.Organization);
		
		ParametersPresentationOfAttributesOfFA = 
			LeasedAssetAccounting.ParametersPresentationOfAttributesOfFA(Object, FormServiceParameters, CreatedForTransition);
		PresentationOfDetails = LeasedAssetAccounting.PresentationOfFAAttributes(ParametersPresentationOfAttributesOfFA);
		
		Items.FACost.Title = PresentationOfDetails.Get("FA.Cost_Header");
		Items.FACost.ToolTip = PresentationOfDetails.Get("FA.Cost_Hint");
		Items.FAFairValue.Title = PresentationOfDetails.Get("FA.FairCost_Title");
		Items.FAFairValue.ToolTip = PresentationOfDetails.Get("FA.FairCost_Hint");
		Items.OsgroupCost.Title = PresentationOfDetails.Get("FA.CostGroup_Title");
		DocumentCurrencyPresentation = ParametersPresentationOfAttributesOfFA.DocumentCurrencyPresentation;
		
		PreviousConditionsAreIrrelevant = Object.PreviousContractTerms <> CurrentPreviousTermsOfContract;
		Items.IndicatorPreviousConditionsAreIrrelevant.Visible = PreviousConditionsAreIrrelevant;
		ThereIsLinkToPreviousCurrentTerms = PreviousConditionsAreIrrelevant 
			And ValueIsFilled(CurrentPreviousTermsOfContract);
		Items.UpdateByPreviousConditions.Visible = ThereIsLinkToPreviousCurrentTerms;
		
		If PreviousConditionsAreIrrelevant And ThereIsLinkToPreviousCurrentTerms Then
			IndicatorHintText = StrTemplate(NStr("vi = 'Các điều khoản thuê trước đó không còn hiệu lực. Điều kiện hiện tại: %1';
												|ru = 'Предыдущие условия аренды неактуальны. Актуальные условия: %1';
												|en = 'The previous rental terms are no longer effective. Effective terms: %1'; fa = 'The previous rental terms are no longer effective. Effective terms: %1';
												|it = 'Предыдущие условия аренды неактуальны. Актуальные условия: %1';
												|pl = 'The previous rental terms are no longer effective. Effective terms: %1';
												|tr = 'Önceki kira koşulları geçerli değildir. Güncel koşullar: %1'"),
				CurrentPreviousTermsOfContract); 
		ElsIf PreviousConditionsAreIrrelevant Then
			IndicatorHintText = NStr("vi = 'Các điều khoản thuê trước đó không còn hiệu lực. Không có hợp đồng còn hiệu lực vào ngày chứng từ';
									|ru = 'Предыдущие условия аренды неактуальны. Нет действующего договора на дату документа';
									|en = 'The previous rental terms are no longer effective. There is no valid contract as of the document date'; fa = 'The previous rental terms are no longer effective. There is no valid contract as of the document date';
									|it = 'Предыдущие условия аренды неактуальны. Нет действующего договора на дату документа';
									|pl = 'The previous rental terms are no longer effective. There is no valid contract as of the document date';
									|tr = 'Önceki kira koşulları geçerli değildir. Belge tarihinde geçerli bir sözleşme yoktur'");
		Else
			IndicatorHintText  = "";
		EndIf;
		Items.IndicatorPreviousConditionsAreIrrelevant.ToolTip = IndicatorHintText;
		
	EndIf;
	
	#EndRegion
	
	#Region NewContract
	If ValueIsFilled(Object.NewContract)
		Or ValueIsFilled(Object.NewCounterparty)
		Or ValueIsFilled(Object.NewPartner) Then
		Items.GroupChangeOfLessorContract.Show();
	EndIf;
	#EndRegion
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtClient
Function RequiresServerCallToConfigureFormElements(StructureOfChangedProps)

	Return StructureOfChangedProps.Count() = 0
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract");

EndFunction

&AtServer
Procedure DateOfChangeOnServer(Refill = False)
	
	Update_VATRate();
	
	FillInServiceDetailsOfTS();
	
	If ValueIsFilled(Object.Contract) Then
		Documents.LeaseTermAdjustment.CheckRelevanceOfLeaseContract(
			Object.Ref, Object.Contract, Object.NewContract, Object.Date);
		SetCurrentTermsOfContract();
		Documents.LeaseTermAdjustment.FillInChartsForPreviousConditionsTakingIntoAccountChanges(Object);
		If Refill And ValueIsFilled(CurrentPreviousTermsOfContract) Then
			If CurrentPreviousTermsOfContract = Object.PreviousContractTerms Then
				UpdateByPreviousConditionsOnServer();
			Else
				Documents.LeaseTermAdjustment.FillInBasedOnLeaseAgreement(Object, False); 
				FillInServiceDetailsOfTS();
				ConfigureDependentFormElementsOnServer("Contract");
			EndIf;
		EndIf;
		FillInPreviousTerms();
	EndIf;
	
	ConfigureDependentFormElementsOnServer("Date");
	
	ItemsAndDimensionsSelectionParameters = Documents.LeaseTermAdjustment.ItemsAndDimensionsSelectionParameters(
				LeasedAssetAccounting.CreatedForSwitchingToFSB25_2018(Object.Date, Object.Organization));
				
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);

	SetupParameters = Documents.LeaseTermAdjustment.AccountingAccountSettings_();
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	Update_VATRate();
	
	FillInServiceDetailsOfTS();
	
	ConfigureDependentFormElementsOnServer("Organization,Contract");
	
	ItemsAndDimensionsSelectionParameters = Documents.LeaseTermAdjustment.ItemsAndDimensionsSelectionParameters(
				LeasedAssetAccounting.CreatedForSwitchingToFSB25_2018(Object.Date, Object.Organization));
				
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);

	SetupParameters = Documents.LeaseTermAdjustment.AccountingAccountSettings_();
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	
EndProcedure

&AtServer
Procedure PartnerWhenChangesAreMadeOnServer()
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	
	CounterpartyWhenChangesAreMadeOnServer();
	
EndProcedure

&AtServer
Procedure CounterpartyWhenChangesAreMadeOnServer()
	
	Contract = Catalogs.LeaseContract.DefaultContract(
				Object.Organization, Object.Partner, Object.Counterparty, Object.Contract);
	
	If Contract <> Object.Contract Then
		Object.Contract = Contract;
		AgreementWhenModifiedOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure AgreementWhenModifiedOnServer()
	
	AddContractDetailsToServiceParametersOfForm();
	
	If Not ValueIsFilled(Object.Contract) Then
		Object.ARAPCurrency = Undefined;
		Object.Currency = Undefined;
	EndIf;
	
	If Object.FA.Count() = 0 
		And Object.AmountIncludingVAT = 0 
		And ValueIsFilled(Object.Contract) Then
		
		Documents.LeaseTermAdjustment.FillInBasedOnLeaseAgreement(Object);
		CurrentPreviousTermsOfContract = Object.PreviousContractTerms;
	Else
		FillInTheContract = True;
	EndIf;
	
	ContractDetails_ = FormServiceParameters.ContractDetails_;
	
	Object.ARAPCurrency = ContractDetails_.ARAPCurrency;
	Object.Currency = ContractDetails_.ARAPCurrency;
	DocumentCurrency = Object.Currency;
	FillInPreviousTerms();
	
	If Not FillInTheContract Then
		
		FillInServiceDetailsOfTS();
		ConfigureDependentFormElementsOnServer("Contract");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheContract()

	If Not FillInTheContract Or Not ValueIsFilled(Object.Contract) Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Điền chứng từ theo hợp đồng?';
					|ru = 'Заполнить документ по договору?';
					|en = 'Fill in the document under the contract?'; fa = 'Fill in the document under the contract?';
					|it = 'Compilare il documento in base all''accordo?';
					|pl = 'Wypełnij dokument zgodnie z umową?';
					|tr = 'Bir sözleşme belgesi mi dolduruyorsunuz?'");
	CallbackDescription = New CallbackDescription("FillInTheContractCompletion", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
	FillInTheContract = False;
	
EndProcedure

&AtClient
Procedure FillInTheContractCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInByAgreementOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInByAgreementOnServer()
		
	Documents.LeaseTermAdjustment.FillInBasedOnLeaseAgreement(Object);
	CurrentPreviousTermsOfContract = Object.PreviousContractTerms;
	
	FillInServiceDetailsOfTS();
	ConfigureDependentFormElementsOnServer("Contract");
	
EndProcedure

&AtServer
Procedure AddContractDetailsToServiceParametersOfForm()
	
	ContractDetails_ = LeasedAssetAccounting.DetailsOfLeaseAgreement(Object.Contract);
	
	ContractType = ContractDetails_.ContractType;
	
	NonCurrentAssetsInternal.SetStructureProperty(
		"ContractDetails_",
		ContractDetails_,
		FormServiceParameters);
	
EndProcedure

&AtServer
Procedure AmountOfRentalServicesWhenChangedOnServer()
	
	RecalculateContractAmountAndVATAmount(Object);
	ConfigureDependentFormElementsOnServer("LeaseServicesAmount");
	
EndProcedure

&AtServer
Procedure AmountOfRedemptionOfRentalItemsWhenChangingOnServer()

	RecalculateContractAmountAndVATAmount(Object);
	RecalculateAmountOfVATRepurchaseOfRentalItems(Object);

	ConfigureDependentFormElementsOnServer("AmountOfLeaseAssetsByuout");
	
EndProcedure

&AtServer
Procedure VATRateForChangesOnServer()
	
	RecalculateContractAmountAndVATAmount(Object);
	RecalculateAmountOfVATRepurchaseOfRentalItems(Object);

	ConfigureDependentFormElementsOnServer("VATRate");
	
EndProcedure

&AtClient
Procedure CalculateCostOfFA()

	ContractDetails_ = FormServiceParameters.ContractDetails_;
	If ContractDetails_.MethodForDeterminingCostOfAssets = 
		CommonClient.PredefinedItem
			("Enum.MethodsOfDeterminingLeasedAssetCost.Manually") Then
		CurrentData = Items.FA.CurrentData;
		CurrentData.Cost = CurrentData.FairValue - CurrentData.NonGuaranteedFinalCost;
	EndIf;
	
EndProcedure

&AtServer
Procedure MainRemedyWhenChangingOnServer()

	FillInServiceDetailsOfTS();
	
EndProcedure

#EndRegion

#Region RecalculationOfAmounts

&AtClientAtServerNoContext
Procedure RecalculateContractAmountAndVATAmount(Object)
	
	LeasedAssetAccountingClientServer.RecalculateAmountOfRentalDocument(Object);
	LeasedAssetAccountingClientServer.RecalculateAmountOfNDSInLeaseDocument(Object);
	
EndProcedure

&AtClientAtServerNoContext
Procedure RecalculateAmountOfVATRepurchaseOfRentalItems(Object)
	
	CurPercentVAT = VATAccountingERPClientServer.ValueOfVATRate(Object.VATRate);
	Object.AmountOfVATRepurchaseOfRentalItems = VATAccountingERPClientServer.CalculateVATAmount(Object.AmountOfLeaseAssetsByuout, CurPercentVAT, True);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	LeaseTermAdjustmentLocalization.SetConditionalAppearance(ThisObject);
	
	#Region FACost_Text
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FACost.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TheCostIsCalculatedAutomatically");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.Cost");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<được tính tự động>';
													|ru = '<рассчитывается автоматически>';
													|en = '<calculated automatically>'; fa = '<calculated automatically>';
													|it = '<viene calcolato automaticamente>';
													|pl = '<oblicza się automatycznie>';
													|tr = '<otomatik olarak hesaplanır>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
	#Region AvailabilityOfMa
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAUsefulLifeManagementAccounting.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.AcceptedForRegistrationOfTheUU");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được chấp nhận cho kế toán>';
													|ru = '<не принято к учету>';
													|en = '<not recognized>'; fa = '<not recognized>';
													|it = '<non considerato in contabilità>';
													|pl = '<nie przyjęto do ewidencji>';
													|tr = '<dikkate alınmaz>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
	#Region AvailabilityOfActionWithRentalItem
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAActionWithRentalObject.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.ActionWithRentalObject");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Common.PredefinedItem("Enum.ActionsWithRentalObjects.Rent");
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
	#Region FAAvailability
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAFixedAsset.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.ActionWithRentalObject");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Common.PredefinedItem("Enum.ActionsWithRentalObjects.Rent");

	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
	
	#Region AvailabilityOfExpenseItemDivision
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FADepartment.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAExpenseItem.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.ActionWithRentalObject");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Common.PredefinedItem("Enum.ActionsWithRentalObjects.Rent");
	
	OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.Sublease");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = True;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.ActionWithRentalObject");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Common.PredefinedItem("Enum.ActionsWithRentalObjects.RentalTermsAdjustment");
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ContractType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Common.PredefinedItem("Enum.TypesOfLeaseContracts.Leasing");

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion 
	
	#Region TextUsageFairCost
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FACost.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.ActionWithRentalObject");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Common.PredefinedItem("Enum.ActionsWithRentalObjects.RentalTermination");

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
	#Region TextUsageRedemptionCost
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FABuyoutValue.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.ActionWithRentalObject");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Common.PredefinedItem("Enum.ActionsWithRentalObjects.EarlyRedemption");

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
EndProcedure

&AtServer
Procedure InitializeServiceParametersOfForm()

	NewServiceParametersOfForm = New Structure;
	NewServiceParametersOfForm.Insert("AssetHolder", Undefined);

	ParameterValue = NonCurrentAssets.VNAManagementIsUsed_2_4(Object.Date);
	NewServiceParametersOfForm.Insert("VNAManagementIsUsed_2_4", ParameterValue);

	ParameterValue = LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Object.Organization, Object.Date, True);
	NewServiceParametersOfForm.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed", ParameterValue);

	ParameterValue = LeasedAssetAccounting.StartOfLeaseAccountingUnderFSB25_2018(Object.Organization);
	NewServiceParametersOfForm.Insert("StartOfLeaseAccountingUnderFSB25_2018", ParameterValue);

	ParameterValue = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	NewServiceParametersOfForm.Insert("ComplianceCAAccountingIsKept", ParameterValue);
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	NewServiceParametersOfForm.Insert("CurrencyOfMan", CurrencyOfMan);
	NewServiceParametersOfForm.Insert("ComplCurrency", ComplCurrency);
	NewServiceParametersOfForm.Insert("CurrencyOfManPresentation", String(CurrencyOfMan));
	NewServiceParametersOfForm.Insert("ComplCurrencyPresentation", String(ComplCurrency));
	NewServiceParametersOfForm.Insert("CurrenciesDoNotMatch", CurrencyOfMan = ComplCurrency);
	
	NewServiceParametersOfForm.Insert("UseVATAccounting", GetFunctionalOption("UseVATAccounting"));
	NewServiceParametersOfForm.Insert("InsignificantVATRate", VATAccountingERP.InsignificantRate(Object.VATRate));
	
	FormServiceParameters = New FixedStructure(NewServiceParametersOfForm);

	AddContractDetailsToServiceParametersOfForm();
	
EndProcedure

&AtServer
Procedure InitializingFormWhenCreatingItOnServer()

	InitializeServiceParametersOfForm();
	FillInServiceDetailsOfTS();
	SetCurrentTermsOfContract();
	FillInPreviousTerms();
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	InitializingFormWhenCreatingItOnServer();
	
	DocumentCurrency = Object.Currency;
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure OpenPaymentAndAccrualSchedule(ChartName)
	
	LeasedAssetAccountingClient.OpenPaymentAndAccrualSchedule(
		Object, 
		ThisObject, 
		PutGraphsInTemporaryStorage(), 
		New CallbackDescription("OpenPaymentAndAccrualScheduleCompletion", ThisObject), 
		ChartName);
	
EndProcedure

&AtServer
Function PutGraphsInTemporaryStorage()

	ContractSchedules = New Structure;
	ContractSchedules.Insert("ServiceAccrualSchedule", Object.ServiceAccrualSchedule.Unload());
	ContractSchedules.Insert("ServicePaymentSchedule", Object.ServicePaymentSchedule.Unload());
	ContractSchedules.Insert("InterestAccrualSchedule", Object.InterestAccrualSchedule.Unload());

	Address = PutToTempStorage(ContractSchedules, AddressOfTheContractSchedule);
		
	Return Address;
	
EndFunction

&AtClient
Procedure OpenPaymentAndAccrualScheduleCompletion(ClosingResult, AddlParameters) Export

	If Not IsTempStorageURL(ClosingResult) Then
		Return
	EndIf;

	OpenPaymentAndAccrualScheduleDirectlyOnServer(ClosingResult);
	AttachableCommandsClient.StartCommandUpdate(ThisObject);

EndProcedure

&AtServer
Procedure OpenPaymentAndAccrualScheduleDirectlyOnServer(Val ClosingResult)
	
	Modified = True;

	ContractSchedules = GetFromTempStorage(ClosingResult);

	Object.TheInterestAccrualScheduleIsEnteredManually = ContractSchedules.TheInterestAccrualScheduleIsEnteredManually;
	Object.InterestAmount = ContractSchedules.InterestAmount;
	Object.ServicePaymentSchedule.Load(ContractSchedules.ServicePaymentSchedule);
	Object.ServiceAccrualSchedule.Load(ContractSchedules.ServiceAccrualSchedule);
	Object.InterestAccrualSchedule.Load(ContractSchedules.InterestAccrualSchedule);
	
	LeasedAssetAccountingClientServer.RecalculateAmountOfNDSInLeaseDocument(Object);

	Object.PresentValue = PresentValue(
		Object, 
		FormServiceParameters.ContractDetails_,
		PreviousConditions);

	ConfigureDependentFormElementsOnServer(
		"ServicePaymentSchedule,ServiceAccrualSchedule,InterestAccrualSchedule,TheInterestAccrualScheduleIsEnteredManually");
	
EndProcedure

&AtServer
Procedure CalculateRateCostPercentagesOnServer()

	Documents.LeaseTermAdjustment.CalculateRateCostInterest(Object, FormServiceParameters.ContractDetails_);
	
	ConfigureDependentFormElementsOnServer("FAFairValue");
	
EndProcedure

&AtClient
Procedure FillInTheRentedOnesCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		ClearMessages();
		FillWithRentedOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillWithRentedOnServer()

	If Not ValueIsFilled(Object.Contract) Then
		Return;
	EndIf;
	
	Object.FA.Clear();
	
	QueryPackageTexts = New Array;

	QueryText = 
	"SELECT
	|	LeasedAsset.FixedAsset AS FixedAsset,
	|	LeasedAsset.Cost AS Cost,
	|	LeasedAsset.ParValue AS ParValue,
	|	VALUE(Enum.ActionsWithRentalObjects.RentalTermsAdjustment) AS Action,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem
	|INTO TTLeasedOS_Preliminary
	|FROM
	|	InformationRegister.LeasedAsset.SliceLast(
	|			&PeriodLimit,
	|			Contract = &Contract
	|				AND Recorder <> &Ref) AS LeasedAsset
	|WHERE
	|	LeasedAsset.State IN (VALUE(Enum.FixedAssetsStates.LeaseContractsSigned),
	|								VALUE(Enum.FixedAssetsStates.InLease))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RentedOut.FixedAsset AS FixedAsset
	|INTO TTLeased
	|FROM
	|	InformationRegister.AssetsLeasedOut.SliceLast(
	|			&PeriodLimit,
	|			FixedAsset IN
	|				(SELECT
	|					T.FixedAsset
	|				FROM
	|					TTLeasedOS_Preliminary AS T)) AS RentedOut
	|WHERE
	|	RentedOut.Contract.ContractType IN(&TypesOfContractsUnderFSB25)
	|	AND RentedOut.State = VALUE(Enum.FixedAssetsStates.LeasedOut)
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeasedAsset.FixedAsset AS FixedAsset,
	|	LeasedAsset.Cost AS Cost,
	|	LeasedAsset.ParValue AS ParValue,
	|	LeasedAsset.Action AS Action,
	|	LeasedAsset.Department AS Department,
	|	LeasedAsset.ExpenseItem AS ExpenseItem,
	|	NOT RentedOut.FixedAsset IS NULL AS Sublease
	|INTO TTLeasedFA
	|FROM
	|	TTLeasedOS_Preliminary AS LeasedAsset
	|		LEFT JOIN TTLeased AS RentedOut
	|		ON RentedOut.FixedAsset = LeasedAsset.FixedAsset
	|
	|INDEX BY
	|	FixedAsset
	|";
	QueryPackageTexts.Add(QueryText);
	
	QueryText = LeaseTermAdjustmentLocalization.RequestTextFillingInTSByAgreement();
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	LeasedAsset.FixedAsset AS FixedAsset,
		|	LeasedAsset.Sublease AS Sublease,
		|	CASE
		|		WHEN &CalculationOfActualCost
		|			THEN LeasedAsset.Cost
		|		ELSE LeasedAsset.ParValue
		|	END AS FairValue,
		|	CASE
		|		WHEN &CalculationOfActualCost
		|			THEN LeasedAsset.Cost
		|		ELSE 0
		|	END AS Cost,
		|	LeasedAsset.Action AS ActionWithRentalObject,
		|	LeasedAsset.Department AS Department,
		|	LeasedAsset.ExpenseItem AS ExpenseItem,
		|	ISNULL(FACost.CostBalance, 0) AS CostInManagementAccounting,
		|	ISNULL(FACost.LocalCostBalance, 0) AS CostInAccounting,
		|	ISNULL(FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths, 0) AS UsefulLifeManagementAccounting
		|FROM
		|	TTLeasedFA AS LeasedAsset
		|		LEFT JOIN AccumulationRegister.FACost.Balance(&PeriodLimit, Organization = &Organization
		|		AND FixedAsset IN
		|			(SELECT
		|				TTLeasedFA.FixedAsset
		|			FROM
		|				TTLeasedFA AS TTLeasedFA)) AS FACost
		|		ON FACost.FixedAsset = LeasedAsset.FixedAsset
		|		LEFT JOIN InformationRegister.FixedAssetDepreciationParametersManagementAccounting.SliceLast(&Date, Recorder <> &Ref
		|		AND Organization = &Organization
		|		AND CorrectionDate = DATETIME(1, 1, 1)
		|		AND FixedAsset IN
		|			(SELECT
		|				TTLeasedFA.FixedAsset
		|			FROM
		|				TTLeasedFA AS TTLeasedFA)) AS FixedAssetDepreciationParametersManagementAccounting
		|		ON FixedAssetDepreciationParametersManagementAccounting.FixedAsset = LeasedAsset.FixedAsset
		|
		|ORDER BY
		|	LeasedAsset.FixedAsset.Description,
		|	LeasedAsset.FixedAsset.AssetID";
		
	EndIf;
	
	QueryPackageTexts.Add(QueryText);
	
	QueryText = StrConcat(QueryPackageTexts, Common.QueryBatchSeparator());

	DocDate = ?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate());
	
	CalculationOfActualCost = FormServiceParameters.ContractDetails_.MethodForDeterminingCostOfAssets
			= Enums.MethodsOfDeterminingLeasedAssetCost.Manually;
			
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Contract", Object.Contract);
	Query.SetParameter("Date", DocDate);
	Query.SetParameter("PeriodLimit", New Boundary(New PointInTime(DocDate, Object.Ref), BoundaryType.Excluding));
	Query.SetParameter("CalculationOfActualCost", CalculationOfActualCost);
	Query.SetParameter("TypesOfContractsUnderFSB25", LeasedAssetAccountingClientServer.TypesOfProfitableLeaseContracts());
	
	Result = Query.ExecuteBatch();
	If Result[0].IsEmpty() Then
		Return;
	EndIf;
	
	Object.FA.Load(Result[Result.UBound()].Unload());
	
	FillInServiceDetailsOfTS();
	
EndProcedure

&AtClient
Procedure FillInScheduleAccordingToCalculations()
	
	If (Object.PaymentFrequency = PredefinedValue("Enum.ScheduleTimeFence.Custom")
			Or Not ValueIsFilled(Object.PaymentFrequency))
		And (Object.AccrualFrequency = PredefinedValue("Enum.ScheduleTimeFence.Custom")
			Or Not ValueIsFilled(Object.AccrualFrequency)) Then
				
		Return;
	EndIf;
	
	If LeasedAssetAccountingClient.CheckAbilityToFillInScheduleByCalculations(Object, FormServiceParameters.ContractDetails_) Then
		
		CalculateTheBidOrCost = LeasedAssetAccountingClient.YouCanCalculateRateOrCost(
			Object, FormServiceParameters.ContractDetails_, "FA", False, PreviousConditions);
		
		FillInScheduleForCalculationsOnServer(CalculateTheBidOrCost);
		
	EndIf;
	
EndProcedure

// Fill in the schedule according to the calculations on the server.
// The method of filling in the graphs depends on the mode of transition to FSB 25.
// 
// Parameters:
//  CalculateTheBidOrCost - Boolean - Calculate the bid or cost
&AtServer
Procedure FillInScheduleForCalculationsOnServer(Val CalculateTheBidOrCost)
	
	Modified = True;
	
	CreatedForTransition = LeasedAssetAccounting.CreatedForSwitchingToFSB25_2018(Object.Date, Object.Organization);
	
	If CreatedForTransition Then
		// Schedules from the beginning of the rental period.
		LeasedAssetAccounting.FillInScheduleOfPaymentsAndChargesForSettlements(Object, FormServiceParameters.ContractDetails_);
	Else
		// Schedules up to the date of change for the old conditions, from the date of change - for the new.
		LeasedAssetAccounting.FillInScheduleOfPaymentsAndAccrualsForCalculationsChangeOfConditions(Object, FormServiceParameters.ContractDetails_);
	EndIf;
	
	Object.PresentValue = PresentValue(
		Object, 
		FormServiceParameters.ContractDetails_,
		PreviousConditions);

	If CalculateTheBidOrCost Then
		CalculateRateCostPercentagesOnServer();
	EndIf;
	
	LeaseTermHasBeenChanged = False;
	
	ConfigureDependentFormElementsOnServer("ServicePaymentSchedule,ServiceAccrualSchedule");
	
EndProcedure

&AtServer
Procedure FillInCalculationsAccordingToSchedule()
	
	Modified = True;

	LeasedAssetAccounting.FillInCalculationsAccordingToScheduleOfPaymentsAndAccruals(Object, FormServiceParameters.ContractDetails_);
	
	ChangedBankingDetails = 
	"SecurityDepositAmount,DateOfFirstSecurityPayment,
	|LeaseServicesAmount,DateOfFirstPayment,
	|AmountOfLeaseAssetsByuout,AmountOfVATRepurchaseOfRentalItems,
	|VATAmount,
	|PaymentFrequency,PaymentForLeaseService,
	|AccrualFrequency,AccrualOfLeaseService";

	ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure EnterLeaseTermCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined 
		Or TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;

	ConfigureDependentFormElements("LeaseStartDate,TermYears,TermMonths,TermDays");
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTS()
	
	ListOfFA = New Array;
	For Each RowData In Object.FA Do
		
		If ValueIsFilled(RowData.FixedAsset) Then
			ListOfFA.Add(RowData.FixedAsset);
		EndIf;
		
		RowData.AcceptedForRegistrationOfTheUU = False;
		RowData.AcceptedForAccountingBU = False;
		RowData.AcceptedForRegistrationWELL = False;
		
	EndDo;
	
	If ListOfFA.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = LeaseTermAdjustmentLocalization.TextOfRequestForFillingInServiceDetailsOfTS();
	
	If QueryText = Undefined Then
		QueryText = 
		"SELECT
		|	CatAssets.Ref,
		|	ISNULL(AccountingProcedureForOSBU.BUState, UNDEFINED) = VALUE(Enum.FixedAssetsStates.Recognized_) AS AcceptedForAccountingBU,
		|	ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, UNDEFINED) = VALUE(Enum.FixedAssetsStates.Recognized_) AS AcceptedForRegistrationOfTheUU
		|FROM
		|	Catalog.Assets AS CatAssets
		|
		|		LEFT JOIN InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
		|				&Date,
		|				CorrectionDate = DATETIME(1,1,1) 
		|					AND Organization = &Organization 
		|					AND FixedAsset IN (&ListOfFA)) AS FixedAssetsAccountingProcedureManagementAccounting
		|		ON FixedAssetsAccountingProcedureManagementAccounting.FixedAsset = CatAssets.Ref
		|	
		|		LEFT JOIN InformationRegister.AccountingProcedureForOSBU.SliceLast(
		|			&Date, 
		|			CorrectionDate = DATETIME(1,1,1)
		|				AND Organization = &Organization 
		|				AND FixedAsset IN (&ListOfFA)) AS AccountingProcedureForOSBU
		|		ON AccountingProcedureForOSBU.FixedAsset = CatAssets.Ref
		|WHERE
		|	CatAssets.Ref IN (&ListOfFA)";
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("Date", Object.Date);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Contract", Object.Contract);
	Query.SetParameter("ListOfFA", ListOfFA);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	AttributesList = "AcceptedForRegistrationOfTheUU";
	For Each Column In Result.Columns Do
		If Column.Name <> "Ref" And Column.Name <> "AcceptedForRegistrationOfTheUU" Then
			AttributesList = AttributesList + "," + Column.Name;
		EndIf;
	EndDo;
	
	FixedAssetsStates = New Map();
	While Selection.Next() Do
		DataState = New Structure(AttributesList);
		FillPropertyValues(DataState, Selection);
		FixedAssetsStates.Insert(Selection.Ref, DataState);
	EndDo;
	
	For Each RowData In Object.FA Do
		
		DataState = FixedAssetsStates.Get(RowData.FixedAsset);
		
		If DataState = Undefined Then
			Continue;
		EndIf;
		
		FillPropertyValues(RowData, DataState);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure Update_VATRate()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.FillInVATRate.Insert("VATTaxation", FormServiceParameters.ContractDetails_.VATTaxation);
	BatchProcessingOfTablePartServer.ProcessTSString(Object, StructureOfActions, Undefined);
	
	ConfigureDependentFormElementsOnServer("VATTaxation");
	
	VATRateForChangesOnServer();
	
EndProcedure

&AtClientAtServerNoContext
Function PresentValue(Object, ContractDetails_, PreviousConditions)

	DistributionCoefficient = LeasedAssetAccountingClientServer.CostSharingRatio(Object.FA, ContractDetails_);
	
	CostOfAddedRentalItems = LeasedAssetAccountingClientServer.CostOfAddedRentalItems(Object.FA);
			
	PresentValue = 
		PreviousConditions.PresentValue
		* DistributionCoefficient
		+ CostOfAddedRentalItems;
				
	Return PresentValue;
	
EndFunction

&AtClient
Procedure UpdateByPreviousConditionsCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		UpdateByPreviousConditionsOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateByPreviousConditionsOnServer()
	
	Documents.LeaseTermAdjustment.FillInBasedOnLeaseAgreement(Object, True); 
	FillInServiceDetailsOfTS();
	ConfigureDependentFormElementsOnServer("Contract");
	Modified = True;

EndProcedure

&AtServer
Procedure FillInFAServiceDetails()
	
	ThereAreFAAddOns = False;
	ThereAreExcludableFA = False;
	ThereAreRedeemableFA = False;
	
	If ContractType = Enums.TypesOfLeaseContracts.Leasing Then
		ThereAreRedeemableFA = Object.FA.FindRows(New Structure("ActionWithRentalObject",
			Enums.ActionsWithRentalObjects.EarlyRedemption)).Count() > 0;
	ElsIf ContractType = Enums.TypesOfLeaseContracts.Lease Then
		ThereAreFAAddOns = Object.FA.FindRows(New Structure("ActionWithRentalObject",
			Enums.ActionsWithRentalObjects.Rent)).Count() > 0;
		ThereAreExcludableFA = Object.FA.FindRows(New Structure("ActionWithRentalObject",
			Enums.ActionsWithRentalObjects.RentalTermination)).Count() > 0;
	EndIf;
		
EndProcedure

&AtServer
Procedure SetCurrentTermsOfContract()
	
	CurrentPreviousTermsOfContract
		= Documents.LeaseTermAdjustment.PreviousTermsOfLeaseContract(Object.Ref, Object.Contract, Object.Date);

EndProcedure

&AtClient
Procedure DateOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		Refill = True;
	Else
		Refill = False;
	EndIf;
	DateOfChangeOnServer(Refill);
	
EndProcedure

&AtServer
Procedure FillInPreviousTerms()
	
	PreviousConditions = LeasedAssetAccounting.CostAccordingToPreviousConditions(Object);
	
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
	ElsIf Item.Name = "sh_ShamsiInput_DateOfFirstSecurityPayment" Then
		DateOfFirstSecurityPaymentOnChange(Items.DateOfFirstSecurityPayment);
	ElsIf Item.Name = "sh_ShamsiInput_DateOfFirstPayment" Then
		DateOfFirstPaymentOnChange(Items.DateOfFirstPayment);
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
