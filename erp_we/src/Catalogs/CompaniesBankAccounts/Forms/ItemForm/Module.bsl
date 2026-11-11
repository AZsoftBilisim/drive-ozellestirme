#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	ObjectAttributesLock.LockAttributes(ThisObject);

	Items.GroupErrorInAccountNumber.Visible = False;
	Items.BankDetailsPages.PagesRepresentation = FormPagesRepresentation.None;
	Items.PagesOfBankDetailsForSettlements.PagesRepresentation = FormPagesRepresentation.None;

	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	MainCountry = Constants.MainCountry.Get();
	
	SetFormatVersion();
	
	OrganizationChangeIsAvailable = AccessRight("Update", Metadata.Catalogs.Companies);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// Handler of the "Properties" mechanism
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
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
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	OnReadCreateAtServer();
	DisplayHintForMainInvoice();
	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel)
	
	If Object.ManualBankDetailsChange Then
		FillPropertyValues(Object, ThisObject, CashClientServer.BankingDetails(True));
	EndIf;
	
	Object.BankNameInt = BankNameInt;
	
	If Object.TransferBankDetailsManualEdit Then
		FillPropertyValues(Object, ThisObject, CashClientServer.BankingDetails(True, True));
	EndIf;
	
	Object.BankNameForPaymentsInt = BankNameForPaymentsInt;
	
	If UseCorrespondentText Then
		Object.CorrespondentText = CorrespondentText;
	Else
		Object.CorrespondentText = "";
	EndIf;
	
	If UseCorrespondentSBudgetText Then
		Object.CorrespondentTextBudget = CorrespondentTextBudget;
	Else
		Object.CorrespondentTextBudget = "";
	EndIf;
	
	If IsBlankString(Object.Description) Then
		Object.Description = GenerateAutoName(ThisObject);
	EndIf;
	
	If Not SettlementBankUsed Then
		Object.TransferBankDetailsManualEdit = False;
	EndIf;
	
	If Modified Then
		
		DuplicateBankAccount = FindBankAccountDuplicate(Object.Ref, Object.AccountNumber, Object.Owner, Object.CashCurrency, Object.Bank);
		If DuplicateBankAccount <> Undefined Then
			
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã tìm thấy tài khoản ngân hàng ""%1"", với số tương ứng tại ngân hàng đã chọn.
					|Tiếp tục ghi lại phần tử hiện tại?';
					|ru = 'Найден банковский счет ""%1"", с аналогичным номером в указанном банке.
					|Продолжить запись текущего элемента?';
					|en = 'Bank account ""%1"" with this number is found in the specified bank. 
					|Continue saving the current item?'; fa = 'Bank account ""%1"" with this number is found in the specified bank. 
					|Continue saving the current item?';
					|it = 'Trovato un conto bancario ""%1"" con un numero analogo nella banca specificata.
					| Continuare la scrittura dell''elemento corrente?';
					|pl = 'Znaleziono rachunek bankowy ""%1"", z analogicznym numerem w określonym banku.
					|Kontynuować zapisywanie bieżącego elementu?';
					|tr = 'Belirtilen bankada aynı numaraya sahip ""%1"" banka hesabı bulundu.
					|Geçerli öğeyi kaydetmeye devam edilsin mi?'"),
				DuplicateBankAccount);
				
			CallbackDescription = New CallbackDescription("CheckingDuplicatesCompletion", ThisObject);
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
			
			Cancel = True;
		EndIf;
	EndIf;
	
	If ValueIsFilled(Object.Ref) And Not Cancel Then
		AskAboutClosingMainAccount(Cancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckingDuplicatesCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		Modified = False;
		Write();
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_CompaniesBankAccounts", WriteParameters, Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	//++ WE
	If EventName = "UpdateBankFeedsPage" Then
		InstallBankFeedsPage();
	EndIf;	
	//-- WE
	If EventName = "Write_Companies" And Source = Object.Owner Then
		DisplayHintForMainInvoice();
	EndIf;
	
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

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DecorationBankFeedsConnectionClick(Item)
	
	//++ WE
	NotifyingFormWhenClosing = 
		New CallbackDescription("CompleteConnectionToBanksFeedsWhenClosingInformationRegisterForm", ThisObject);
		
	If Object.ManualBankDetailsChange Then
		CurBank = Object.Ref;
	Else
		CurBank = Object.Bank;
	EndIf;
		
	FormParameters = New Structure("CompanyLink,BankLink", Object.Owner, CurBank);
	OpenForm(
		"InformationRegister.ConnectionsToBankFeedsBanks.RecordForm", 
		FormParameters,ThisObject,,,,NotifyingFormWhenClosing, 
		FormWindowOpeningMode.LockOwnerWindow);
	//-- WE
	
	Return;
	
EndProcedure

&AtClient
Procedure DecorationAddConnectionBankFeedsClick(Item)
	
	//++ WE
	If Not ValueIsFilled(Object.Ref)
		Or Modified Then
		
		QueryText = NStr("vi = 'Còn chưa ghi lại dữ liệu.
							|Ghi lại phần tử?';
							|ru = 'Данные еще не записаны.
							|Записать элемент?';
							|en = 'Data is not saved yet.
							|Do you want to save the item?'; fa = 'Data is not saved yet.
							|Do you want to save the item?';
							|it = 'Данные еще не записаны.
							|Записать элемент?';
							|pl = 'Data is not saved yet.
							|Do you want to save the item?';
							|tr = 'Veriler henüz kaydedilmedi.
							|Öğe kaydedilsin mi?'");
			
		ShowQueryBox(New CallbackDescription("BankAccountsItemNotRecordedEnd", ThisObject),
			QueryText,
			QuestionDialogMode.YesNo);
		
	Else
		
		OpenBankFeedsActivationForm();
		
	EndIf;
	
	//-- WE
		
	Return;
		
EndProcedure

&AtClient
Procedure OwnerOnChange(Item)
	
	OwnerWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure AccountNumberOnChange(Item)
	
	AccountNumberOnChangeServer();
	CashClientServer.FillInMainBankDetails(ThisObject);
	
	//++ WE
	ExchangeWithBankFeedsServiceClient.DisableConnectionToService(ThisObject);
	//-- WE
	
EndProcedure

&AtClient
Procedure ThisIsAnIBANOnChange(Item)
	
	Items.GroupErrorInAccountNumber.Visible = False;
	
	ItSForeignBank = True;
	
	
	If Object.ThisIsAnIBAN Then
		CheckIBAN(ThisObject)
	EndIf;
	
	If ItSForeignBank <> Object.ForeignBank Then
		Object.ForeignBank = ItSForeignBank;
		ForeignBankInCaseOfChange();
	EndIf;

	CustomizeFormElements(ThisObject, , FormAttributes(ThisObject));
	CashClientServer.FillInMainBankDetails(ThisObject);

	FillInListOfAccountTypeSelection(Items.AccountType.ChoiceList);
	

	//++ WE
	ExchangeWithBankFeedsServiceClient.DisableConnectionToService(ThisObject);
	//-- WE

EndProcedure

&AtClient
Procedure BankOnChange(Item)
	
	WhenChangingBank();
	
EndProcedure

&AtClient
Procedure BankIndicationMethodOnChange(Item)
	
	Object.ManualBankDetailsChange = BankIndicationMethod = "ManualFillingInOfBankingDetails";
	WhenChangingManuallyChangeBankDetails()
	
EndProcedure

&AtClient
Procedure BankInGroupOnChange(Item)
	
	WhenChangingBank();
	
EndProcedure

&AtClient
Procedure BankBICOnChange(Item)
	
	CashClientServer.FillInMainBankDetails(ThisObject)

EndProcedure

&AtClient
Procedure BankCorrAccountOnChange(Item)
	
	CashClientServer.FillInMainBankDetails(ThisObject)

EndProcedure

&AtClient
Procedure BankAccountForPaymentsOnChange(Item)

	CashClientServer.FillInMainBankDetails(ThisObject)

EndProcedure

&AtClient
Procedure BankDescriptionOnChange(Item)
	
	CashClientServer.FillInMainBankDetails(ThisObject);
	GenerateAutoName(ThisObject);
	
EndProcedure

&AtClient
Procedure BankSWIFTCodeOnChange(Item)
	
	CashClientServer.FillInMainBankDetails(ThisObject)

EndProcedure

&AtClient
Procedure BankNameIntOnChange(Item)

	CashClientServer.FillInMainBankDetails(ThisObject);

EndProcedure

&AtClient
Procedure CashCurrencyOnChange(Item)
	
	CashCurrencyOnChangeClient();
	CashCurrencyOnChangeServer();
	
	//++ WE
	ExchangeWithBankFeedsServiceClient.DisableConnectionToService(ThisObject);
	//-- WE
	
EndProcedure

&AtClient
Procedure SettlementBankUsedOnChange(Item)
	
	If SettlementBankUsed Then
		TitleBankPageForSettlements = NStr("vi = 'Nhập thông tin ngân hàng thủ công...';
											|ru = 'Ввести реквизиты банка вручную...';
											|en = 'Enter the bank details manually...'; fa = 'Enter the bank details manually...';
											|it = 'Inserire i requisiti bancari manualmente...';
											|pl = 'Wpisz dane banku ręcznie...';
											|tr = 'Banka bilgilerini manuel olarak gir…'");
	Else
		Object.TransferBank = Undefined;
		AttributesList = CashClientServer.BankingDetails(True, True);
		CashClientServer.ClearBankDetailsOnForm(ThisObject, AttributesList);
		FillPropertyValues(Object, ThisObject, AttributesList);
		MethodOfSpecifyingBankForSettlements = "ManualFillingInOfBankingDetails";
		Object.TransferBankDetailsManualEdit = True;
	EndIf;
	
	ConfigureDependentFormElements();
	CashClientServer.FillInMainBankDetails(ThisObject);
	
EndProcedure

&AtClient
Procedure TransferBankOnChange(Item)
	
	WhenChangingBankForSettlements();
	
EndProcedure

&AtClient
Procedure MethodOfSpecifyingBankForSettlementsOnChange(Item)
	
	Object.TransferBankDetailsManualEdit = MethodOfSpecifyingBankForSettlements = "ManualFillingInOfBankingDetails";
	WhenChangingManuallyChangingBankDetailsForSettlements();
	
	//++ WE
	ExchangeWithBankFeedsServiceClient.DisableConnectionToService(ThisObject);
	//-- WE
	
EndProcedure

&AtClient
Procedure BankForSettlementsInGroupOnChange(Item)
	
	WhenChangingBankForSettlements();
	
EndProcedure

&AtClient
Procedure TransferBankBICOnChange(Item)

	CashClientServer.FillInMainBankDetailsForSettlements(ThisObject)

EndProcedure

&AtClient
Procedure TransferBankDescriptionOnChange(Item)
	
	CashClientServer.FillInMainBankDetailsForSettlements(ThisObject)

EndProcedure

&AtClient
Procedure BankSWIFTCodeForPaymentsOnChange(Item)
	
	CashClientServer.FillInMainBankDetailsForSettlements(ThisObject)

EndProcedure

&AtClient
Procedure BankNameForPaymentsIntOnChange(Item)
	
	CashClientServer.FillInMainBankDetailsForSettlements(ThisObject)

EndProcedure

&AtClient
Procedure AccountTypeOnChange(Item)
	
	FillInExchangeFormatSelectionList(Object.AccountType, Items.ExchangeFormat.ChoiceList);
	GenerateAutoName(ThisObject);
	ConfigureDependentFormElements();
	
EndProcedure

&AtClient
Procedure UseCorrespondentTextOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure ImportFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectingFile(Item);
	
EndProcedure

&AtClient
Procedure ExportFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectingFile(Item, False);
	
EndProcedure

&AtClient
Procedure ImportFileOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenFileForViewing(Item, NStr("vi = 'Tệp kết nhập';
									|ru = 'Файл загрузки';
									|en = 'Import file'; fa = 'فایل ورود';
									|it = 'File di caricamento';
									|pl = 'Plik pobierania';
									|tr = 'İçe aktarma dosyası'"));
	
EndProcedure

&AtClient
Procedure ExportFileOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenFileForViewing(Item, NStr("vi = 'Tệp kết xuất';
									|ru = 'Файл выгрузки';
									|en = 'Export file'; fa = 'فایل خروج';
									|it = 'File di upload';
									|pl = 'Plik przesyłania';
									|tr = 'Dışa aktarma dosyası'"));
	
EndProcedure

&AtClient
Procedure ExchangeModeIsEnabledWhenChanging(Item)
	
	LineBankExchangeIsEnabled = ?(Object.BankEDIEnabled, NStr("vi = 'bật';
																|ru = 'включен';
																|en = 'enabled'; fa = 'enabled';
																|it = 'inclusa';
																|pl = 'włączono';
																|tr = 'Etkin'"), NStr("vi = 'không bật';
																						|ru = 'не включен';
																						|en = 'disabled'; fa = 'disabled';
																						|it = 'non inclusa';
																						|pl = 'nie włączono';
																						|tr = 'etkinleştirilmedi'"));
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure ExchangeFormatOnChange(Item)
	
	If Object.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.ClientBankExchange1c")
		Or Object.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.MT940") Then
		Object.Encoding = "Windows"
	Else
		Object.Encoding = "UTF-8"
	EndIf;
	CashClientServer.CustomizeFormElements(ThisObject, "ExchangeFormat", FormAttributes(ThisObject));

EndProcedure

&AtClient
Procedure DecorationAddAgreementEDClick(Item)
	
	Return;
	
EndProcedure

&AtClient
Procedure DecorationAgreementEDClick(Item)
	
	Return;
	
EndProcedure

&AtClient
Procedure EnterATransitInvoiceClick(Item)
	
	Return;
	
EndProcedure

&AtClient
Procedure ModeOfTheExchangeTheDirectExchangeOfOnChange(Item)
	
	
	//++ WE
	ExchangeModeWhenChangingBankFeeds("UseBankFeedsBankExchange");
	//-- WE
	
	Return;
	
EndProcedure

&AtClient
Procedure BankFeedsExchangeModeOnChange(Item)

	//++ WE
	ExchangeModeWhenChangingBankFeeds("UseBankFeedsBankExchange");
	//-- WE

	Return;
	
EndProcedure

&AtClient
Procedure SeparateSDOAccountOnChange(Item)
	
	Return;
	
EndProcedure

&AtClient
Procedure StateContractOnChange(Item)
	
	Return;
	
EndProcedure

&AtClient
Procedure TextDirectBankHorizontallyURLProcessing(Item, FormattedStringURL, StandardProcessing)
	

	Return;
	
EndProcedure

&AtClient
Procedure TheModeOfExchangeOfTheBankSCustomerOnChange(Item)
	
	
	//++ WE
	ExchangeModeWhenChangingBankFeeds("UseBankFeedsBankExchange");
	//-- WE
	
	Return;
	
EndProcedure

&AtClient
Procedure CountryOfBankOnChange(Item)
	
	Object.CountryOfBank = CountryOfBank;
	
	
	CashClientServer.FillInMainBankDetails(ThisObject);
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure UseUploadDirectoryOnChange(Item)
	
	Object.ExportFile = "";
	
EndProcedure

&AtClient
Procedure UseDownloadDirectoryOnChange(Item)
	
	Object.ImportFile = "";
	
EndProcedure

&AtClient
Procedure DirectionOfActivityOfTreasuryAccountStartChoice(Item, ChoiceData, StandardProcessing)
	
	Return;
	
EndProcedure

&AtClient
Procedure AccountUnderStateContractOnChange(Item)

	Return;
	
EndProcedure

&AtClient
Procedure PersonalAccountNumberOnChange(Item)
	
	Return;
	
EndProcedure

#Region SettingUpAccountingAccounts_EventHandlersForFormHeaderElements

&AtClient
Procedure Attachable_OnChange_SettingUpAccountingAccounts(Item)
	GLAccountSettingsClient.OnChange(Item, ThisObject);
	Return; // The UT handler is empty
	
EndProcedure

&AtClient
Procedure Attachable_StartOfSelection_SettingUpAccountingAccounts(Item, ChoiceData, StandardProcessing)
	GLAccountSettingsClient.StartChoice(ThisObject, Item, ChoiceData, StandardProcessing);
	Return; // The UT handler is empty
	
EndProcedure

&AtClient
Procedure Attachable_Regulation_SettingUpAccountingAccounts(Item, Direction, StandardProcessing)
	GLAccountSettingsClient.Tuning(ThisObject, Item, Direction, StandardProcessing);
	Return; // The UT handler is empty
	
EndProcedure

&AtClient
Procedure Attachable_Cleaning_SettingUpAccountingAccounts(Item, StandardProcessing)
	GLAccountSettingsClient.Clearing(ThisObject, Item, StandardProcessing);
	Return; // The UT handler is empty
	
EndProcedure

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(
	ItemOrCommand,
	Var_URL = Undefined,
	StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

#EndRegion

#Region Private

//++ WE
#Region BankFeeds

&AtServer
Procedure InstallBankFeedsPage()
	
	If Not Object.UseBankFeedsBankExchange
		 Or Not GetFunctionalOption("UseBankFeedsExchange") Then

		Items.BankFeedsDisplayGroup.CurrentPage = Items.PageIsConnectedToBankFeeds;
		Items.DecorationBankFeedsConnection.Title = "";
		Items.DecorationBankFeedsConnection.Hyperlink = False;
		
	ElsIf Object.BankFeedsAccountID <> "" Then
		
		Items.BankFeedsDisplayGroup.CurrentPage = Items.PageIsConnectedToBankFeeds;
		
		If Object.ManualBankDetailsChange Then
			
			CurBank = Object.Ref;
		Else
			
			CurBank = Object.Bank;
			
		EndIf;	
		
		Items.DecorationBankFeedsConnection.Title = ExchangeWithBankFeedsServiceClientServer.HeaderOfExchangeSettingsWithBank(
			Object.Owner, CurBank, Object.BankFeedsAccountID);
			
		Items.DecorationBankFeedsConnection.Hyperlink = True;
		
	ElsIf AccessRight("Update", Metadata.InformationRegisters.ConnectionsToBankFeedsBanks) Then
		
		Items.BankFeedsDisplayGroup.CurrentPage = Items.NoConnectionToBankFeedsPageAdding;
	Else
		
		Items.BankFeedsDisplayGroup.CurrentPage = Items.PageNoBankFeedsRights;
	EndIf;
	
EndProcedure

&AtClient
Procedure CompleteConnectionToBanksFeedsWhenClosingInformationRegisterForm(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) 
			And Result.Property("DisableBankFeeds") Then
		
		Object.BankFeedsAccountID = "";	
		Modified = True;
		
	EndIf;	

	InstallBankFeedsPage();
	
EndProcedure	

&AtClient
Procedure BankAccountsItemNotRecordedEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		Write();  

		If ValueIsFilled(Object.Ref) Then
			OpenBankFeedsActivationForm();    
		EndIf;	
	EndIf;
	
EndProcedure   

&AtClient
Procedure OpenBankFeedsActivationForm()
	
	DontAdd = False;

	If Not ValueIsFilled(Object.Ref) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa ghi lại phần tử';
				|ru = 'Не записан элемент';
				|en = 'Item is not saved'; fa = 'Item is not saved';
				|it = 'Не записан элемент';
				|pl = 'Item is not saved';
				|tr = 'Öğe kaydedilmedi'"), , , "Object", DontAdd); 
	EndIf;

	If Not ValueIsFilled(Object.AccountNumber) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa chỉ ra số tài khoản';
				|ru = 'Не указан номер счета';
				|en = 'Account number is not specified'; fa = 'Account number is not specified';
				|it = 'Не указан номер счета';
				|pl = 'Account number is not specified';
				|tr = 'Hesap numarası belirtilmedi'"), , "AccountNumber", "Object", DontAdd); 
	EndIf;
	
	If Not ValueIsFilled(Object.Owner) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa chỉ ra doanh nghiệp';
				|ru = 'Не указана организация';
				|en = 'Company is not specified'; fa = 'Company is not specified';
				|it = 'Не указана организация';
				|pl = 'Nie podano firmy';
				|tr = 'İş yeri belirtilmedi'"), , "Owner", "Object", DontAdd); 
	EndIf;
	
	If Not ValueIsFilled(Object.Bank)
		And Not Object.ManualBankDetailsChange Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa chọn ngân hàng từ danh mục';
				|ru = 'Не выбран банк из справочника';
				|en = 'Bank is not selected from the catalog'; fa = 'Bank is not selected from the catalog';
				|it = 'Не выбран банк из справочника';
				|pl = 'Bank is not selected from the catalog';
				|tr = 'Katalog üzerinden banka seçilmedi'"), , "Bank", "Object", DontAdd); 
	EndIf;
	
	If Object.ManualBankDetailsChange
		And Not ValueIsFilled(Object.BankNameInt) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa chọn ngân hàng hoặc chưa điền tên ngân hàng trong các mục tin thủ công của ngân hàng';
				|ru = 'Не выбран банк или не заполнено наименование банка в ручных реквизитах банка';
				|en = 'Bank is not selected or the bank name is not filled in the manual bank details'; fa = 'Bank is not selected or the bank name is not filled in the manual bank details';
				|it = 'Не выбран банк или не заполнено наименование банка в ручных реквизитах банка';
				|pl = 'Bank is not selected or the bank name is not filled in the manual bank details';
				|tr = 'Manuel banka bilgilerinde banka seçilmedi veya banka adı doldurulmadı'"), , "Bank", "Object", DontAdd); 
	ElsIf Object.ManualBankDetailsChange
		And ValueIsFilled(Object.BankNameInt) 
		And Not ValueIsFilled(Object.CountryOfBank) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền quốc gia của ngân hàng trong các mục tin thủ công của ngân hàng';
				|ru = 'Не заполнена страна банка в ручных реквизитах банка';
				|en = 'Bank country is not filled in the manual bank details'; fa = 'Bank country is not filled in the manual bank details';
				|it = 'Не заполнена страна банка в ручных реквизитах банка';
				|pl = 'Bank country is not filled in the manual bank details';
				|tr = 'Manuel banka bilgilerinde banka ülkesi doldurulmadı'"), , "Bank", "Object", DontAdd); 
	EndIf;
	
	If DontAdd Then
		Return;
	EndIf;
	
	HandlerNotifications = New CallbackDescription("AfterCreatingExchangeSettingsBankFeeds", ThisObject);
	
	If Object.ManualBankDetailsChange Then
		
		CurBank = Object.Ref;
		
	Else
		
		CurBank = Object.Bank;	
		
	EndIf;	
	
	FormParameters = New Structure;
	FormParameters.Insert("Organization", Object.Owner);
	FormParameters.Insert("Bank", CurBank);
	FormParameters.Insert("BankAccount", Object.Ref);
	
	OpenForm("InformationRegister.ConnectionsToBankFeedsBanks.Form.ConnectionForm", FormParameters, , , , ,
		HandlerNotifications);

EndProcedure

&AtClient
Procedure AfterCreatingExchangeSettingsBankFeeds(ConfigureExchange, Var_Parameters) Export
	
	If ValueIsFilled(ConfigureExchange)	
		And ConfigureExchange <> DialogReturnCode.Cancel Then
			
		Object.BankFeedsAccountID = ConfigureExchange.AccountNumber;	
		Modified = True;
			
	EndIf;	
	
	Items.DecorationAddConnectionBankFeeds.Title =
		ExchangeWithBankFeedsServiceClientServer.HeaderOfExchangeSettingsWithBank(
			Object.Owner, Object.Bank, Object.BankFeedsAccountID); 
			
	InstallBankFeedsPage();
			
EndProcedure

#EndRegion
//-- WE


//++ WE
&AtClient
Procedure ExchangeModeWhenChangingBankFeeds(TagName)
	
	Object.UseBankFeedsBankExchange = (ExchangeMode = 3); 
	Object.BankFeedsAccountID = "";
	
	ExchangeModeWhenChangingOnBankFeedsServer(TagName);
	
EndProcedure

&AtServer
Procedure ExchangeModeWhenChangingOnBankFeedsServer(TagName)
	
	InstallBankFeedsPage();
	
EndProcedure
//-- WE

&AtServer
Procedure SetFormatVersion()
	
	If Not ValueIsFilled(Object.Ref) And Not ValueIsFilled(Parameters.CopyingValue) Then
		Object.ExchangeFormat = Enums.ExchangeFormatWithBank.ISO20022;
		Object.Encoding = "UTF-8"
	EndIf;
	
	ExchangeFormats = New Array;
	EDIWithBanksLocalization.WhenFillingExchangeFormats(ExchangeFormats);
	For Each Item In ExchangeFormats Do
		Items.ExchangeFormat.ChoiceList.Add(Item)
	EndDo
	
EndProcedure

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

// StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

// End StandardSubsystems.AttachableCommands

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CorrespondentText.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseCorrespondentText");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.FormBackColor);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.BorderColor);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CorrespondentTextBudget.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseCorrespondentSBudgetText");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.FormBackColor);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.BorderColor);
	
EndProcedure

#Region OnChangeAttributes

&AtClient
Procedure CashCurrencyOnChangeClient()
	
	CurrencyAccount = (ValueIsFilled(Object.CashCurrency) And Object.CashCurrency <> CurrencyOfComplianceAccounting);
	
EndProcedure

&AtServer
Procedure CashCurrencyOnChangeServer()
	
	GenerateAutoName(ThisObject);
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure OwnerWhenChangedOnServer()
	
	GenerateAutoName(ThisObject);
	
EndProcedure

&AtClient
Procedure ForeignBankInCaseOfChange()
	
	ForeignBankWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure ForeignBankWhenChangingOnServer()
	
	If Object.ForeignBank
		And Not ValueIsFilled(Object.Ref)
		And Not ValueIsFilled(Object.MainBankAccount) Then
		Object.AccountType = Undefined;
		//Object.Main Bank Account = Undetermined;
	EndIf;
	
	FillInListOfAccountTypeSelection(Items.AccountType.ChoiceList);
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure WhenChangingBank()
	
	Items.Bank.InputHint = "";
	If ValueIsFilled(Object.Bank) Then
		DisplayWarningAboutTerminationOfBankSActivities();
		Object.ManualBankDetailsChange = False;
		BankIndicationMethod = "SelectionFromCatalog";
		FillInBankDetailsByBank("Bank", Object.Bank, True);
	Else
		Object.ManualBankDetailsChange = True;
		BankIndicationMethod = "ManualFillingInOfBankingDetails";
		FillInBankDetailsByBank("Bank", PredefinedValue("Catalog.BankClassifier.EmptyRef"), True);
	EndIf;
	
	
	If Object.ThisIsAnIBAN Then
		CheckIBAN(ThisObject)
	EndIf;
		
	CustomizeFormElements(ThisObject, , FormAttributes(ThisObject));
	
	If ValueIsFilled(Object.Bank) Then
		CashClientServer.FillInMainBankDetails(ThisObject);
	Else
		TitlePageBank = NStr("vi = 'Nhập thông tin ngân hàng thủ công...';
							|ru = 'Ввести реквизиты банка вручную...';
							|en = 'Enter the bank details manually...'; fa = 'Enter the bank details manually...';
							|it = 'Inserire i requisiti bancari manualmente...';
							|pl = 'Wpisz dane banku ręcznie...';
							|tr = 'Banka bilgilerini manuel olarak gir…'");
	EndIf;
	
	//++ WE
	ExchangeWithBankFeedsServiceClient.DisableConnectionToService(ThisObject);
	//-- WE
	
EndProcedure

&AtClient
Procedure WhenChangingBankForSettlements()
	
	Items.TransferBank.InputHint = "";
	If ValueIsFilled(Object.TransferBank) Then
		Object.TransferBankDetailsManualEdit = False;
		MethodOfSpecifyingBankForSettlements = "SelectionFromCatalog";
		FillInBankDetailsByBank("TransferBank", Object.TransferBank, True);
		CashClientServer.FillInMainBankDetailsForSettlements(ThisObject);
	Else
		TitleBankPageForSettlements = NStr("vi = 'Nhập thông tin ngân hàng thủ công...';
											|ru = 'Ввести реквизиты банка вручную...';
											|en = 'Enter the bank details manually...'; fa = 'Enter the bank details manually...';
											|it = 'Inserire i requisiti bancari manualmente...';
											|pl = 'Wpisz dane banku ręcznie...';
											|tr = 'Banka bilgilerini manuel olarak gir…'")
	EndIf;
	
	CustomizeFormElements(ThisObject, , FormAttributes(ThisObject));
	
EndProcedure

&AtClient
Procedure WhenChangingManuallyChangeBankDetails()
	
	FormAttributes = FormAttributes(ThisObject);
	If Object.ManualBankDetailsChange Then
		Items.Bank.InputHint = NStr("vi = '<nhập thủ công thông tin ngân hàng>';
									|ru = '<реквизиты банка введены вручную>';
									|en = '<the bank details are entered manually>'; fa = '<the bank details are entered manually>';
									|it = '<requisiti bancari inseriti manualmente>';
									|pl = '<dane banku zostały wprowadzone ręcznie>';
									|tr = '<banka bilgileri manuel olarak girildi>'");
		Object.Bank = Undefined;
	Else
		Items.Bank.InputHint = "";
	EndIf;

	ManualChangeOfBankDetailsWhenChangingOnServer();
	
	CustomizeFormElements(ThisObject, , FormAttributes);
	
EndProcedure

&AtClient
Procedure WhenChangingManuallyChangingBankDetailsForSettlements()
	
	FormAttributes = FormAttributes(ThisObject);
	If Object.TransferBankDetailsManualEdit Then
		Items.TransferBank.InputHint = NStr("vi = '<nhập thủ công thông tin ngân hàng>';
											|ru = '<реквизиты банка введены вручную>';
											|en = '<the bank details are entered manually>'; fa = '<the bank details are entered manually>';
											|it = '<requisiti bancari inseriti manualmente>';
											|pl = '<dane banku zostały wprowadzone ręcznie>';
											|tr = '<banka bilgileri manuel olarak girildi>'");
		Object.TransferBank = Undefined;
	Else
		Items.TransferBank.InputHint = "";
	EndIf;

	ManualChangeOfBankDetailsForSettlementsWhenChangingOnServer();
	
	CustomizeFormElements(ThisObject, , FormAttributes);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CustomizeFormElements(Form, ChangedProps = "", AdditionalAttributes = Undefined)
	
	CashClientServer.CustomizeFormElements(Form, ChangedProps, AdditionalAttributes);
	
	If Not ValueIsFilled(ChangedProps) Then
		CommonClientServer.SetFormItemProperty(Form.Items,
			"CorrespondentBankAccountInternational", "Visible",
			Not Form.Items.BankGroup1.Visible And Form.Items.BankCorrAccount.Visible);
		CommonClientServer.SetFormItemProperty(Form.Items,
			"CorrespondentAccountOfBankInternationalByReference", "Visible",
			Not Form.Items.BankGroupByLink.Visible And Form.Items.CorrespondentBankAccountAtLink.Visible);
		CommonClientServer.SetFormItemProperty(Form.Items,
			"BankAccountForSettlementsInternational", "Visible",
			Not Form.Items.BankGroup1.Visible And Form.Items.BankAccountForPayments.Visible);
	EndIf;

	If Form.Object.ManualBankDetailsChange Then
		Form.Items.BankDetailsPages.CurrentPage = Form.Items.ManualBankDetails;
	Else
		Form.Items.BankDetailsPages.CurrentPage = Form.Items.BankDetailsByLink;
	EndIf;
	
	If Form.Object.TransferBankDetailsManualEdit Then
		Form.Items.PagesOfBankDetailsForSettlements.CurrentPage = Form.Items.ManualBankDetailsForSettlements;
	Else
		Form.Items.PagesOfBankDetailsForSettlements.CurrentPage = Form.Items.BankDetailsForPaymentsViaLink;
	EndIf;
	
EndProcedure

&AtServer
Procedure ManualChangeOfBankDetailsWhenChangingOnServer()
	
	If Object.ManualBankDetailsChange Then
		FillInBankDetailsByBank("Bank", Catalogs.BankClassifier.EmptyRef(), True);
	EndIf;
	
	ConfigureDependentFormElementsOnServer();
	
	If Not Object.ManualBankDetailsChange Then
		FillInBankDetailsForBIC("Bank", BankBIC, True)
	EndIf;
	BankWhenChangedOnServer();
	CashClientServer.FillInMainBankDetails(ThisObject);
	
EndProcedure

&AtServer
Procedure ManualChangeOfBankDetailsForSettlementsWhenChangingOnServer()
	
	If Not Object.TransferBankDetailsManualEdit Then
		FillInBankDetailsForBIC("TransferBank", TransferBankBIC, True)
	EndIf;
	
	If Not Object.TransferBank.IsEmpty() Then
		FillInBankDetailsByBank("TransferBank", Object.TransferBank);
	EndIf;
	
	ConfigureDependentFormElementsOnServer();
	CashClientServer.FillInMainBankDetailsForSettlements(ThisObject);
	
EndProcedure

&AtServer
Procedure AccountNumberOnChangeServer()
	
	Items.GroupErrorInAccountNumber.Visible = False;
	AccountNumber = Upper(StrReplace(StrReplace(TrimAll(AccountNumber), " ", ""), ".", ""));
	Object.AccountNumber = AccountNumber;
	
	ChangedForeignBank = False;
	
	If InternationalBankAccountDetails Then
		ChangedForeignBank = Object.ForeignBank = False;
		Object.ForeignBank = True;
		If Mid(AccountNumber, 1, 4) = "IBAN" Then
			AccountNumber = Mid(AccountNumber, 5);
			Object.AccountNumber = AccountNumber;
		EndIf;
		If CashClientServer.CorrectIBANLength(Object.AccountNumber) Then
			Object.ThisIsAnIBAN = True;
			IdentifyCountryAndBankByIBAN();
		EndIf;
		If Object.ThisIsAnIBAN Then
			CheckIBAN(ThisObject)
		EndIf;
	EndIf;
	If ChangedForeignBank Then
		ForeignBankWhenChangingOnServer();
	EndIf;
	GenerateAutoName(ThisObject);
	CustomizeFormElements(ThisObject, , FormAttributes(ThisObject));

	FillInListOfAccountTypeSelection(Items.AccountType.ChoiceList);
	
EndProcedure

&AtServer
Procedure IdentifyCountryAndBankByIBAN()
	
	AlphabeticCountryCode = CashClientServer.CountryCodeIBAN(Object.AccountNumber);
	Country = CashServer.Country(AlphabeticCountryCode);
	If ValueIsFilled(Country) Then
		CountryOfBank = Country;
		Object.CountryOfBank = Country;
		NationalBankCode = CashServer.NationalBankCode(Object.AccountNumber);
		FoundBank = CashServer.Bank(Country, NationalBankCode);
		If ValueIsFilled(FoundBank) Then
			Object.Bank = FoundBank;
			Object.ManualBankDetailsChange = False;
			BankIndicationMethod = "SelectionFromCatalog";
			FillInBankDetailsByBank("Bank", Object.Bank);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenFileForViewing(Item, Var_Title)
	
	If ValueIsFilled(Item.EditText) Then
		
		FileOnHardDrive = New File;
		
		CallbackDescription = New CallbackDescription(
			"OpenFileForViewingStartInitialization",
			ThisObject,
			New Structure("Item, Title", Item, Var_Title));
			
		FileOnHardDrive.BeginInitialization(CallbackDescription, Item.EditText);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenFileForViewingStartInitialization(File, AdditionalParameters) Export
	
	CallbackDescription = New CallbackDescription(
		"OpenFileToViewFileExists",
		ThisObject,
		AdditionalParameters);
		
	File.BeginCheckingExistence(CallbackDescription);
	
EndProcedure

&AtClient
Procedure OpenFileToViewFileExists(Exists, AdditionalParameters) Export
	
	If Not Exists Then
		ShowMessageBox(Undefined, NStr("vi = 'Không tìm thấy tệp!';
										|ru = 'Не найден файл!';
										|en = 'File is not found.'; fa = 'File is not found.';
										|it = 'File non trovato!';
										|pl = 'Nie znaleziono pliku!';
										|tr = 'Dosya bulunamadı!'"));
		Return;
	EndIf;
	
	Files = New Array;
	Files.Add(New TransferableFileDescription(AdditionalParameters["Item"].EditText));
	PlacingFilesCompletion = New CallbackDescription("OpenFileToViewRoomCompletion", ThisObject, AdditionalParameters);
	BeginPuttingFiles(PlacingFilesCompletion, Files,, False, UUID);
	
EndProcedure

&AtClient
Procedure OpenFileToViewRoomCompletion(PlacedFiles, AdditionalParameters) Export
	
	If PlacedFiles <> Undefined
		And PlacedFiles.Count() > 0 Then
		
		FilesDetails = PlacedFiles.Get(0);
		FileAddress     = FilesDetails.Location;
		
		If FileAddress = Undefined Then
			Return;
		EndIf;
		
		Text = RetrieveTextDocumentFromTemporaryFileStorage(FileAddress, Object.Encoding);
		Text.Show(AdditionalParameters["Title"], AdditionalParameters["Item"].SelectedText);
	EndIf;
	
EndProcedure

&AtClient
Function RetrieveTextDocumentFromTemporaryFileStorage(FileAddress, Encoding)
	
	#If WebClient Or MobileClient Then
		Return "";
	#Else
		If Object.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.ISO20022") Then
			TempFileName = GetTempFileName("xml");
		ElsIf Object.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.ClientBankExchange1c") Then
			TempFileName = GetTempFileName("txt");
		Else
			TempFileName = GetTempFileName();
		EndIf;
		FileBinaryData = GetFromTempStorage(FileAddress); // BinaryData
		FileBinaryData.Write(TempFileName);
		Text = New TextDocument();
		If Encoding = "DOS" Then
			Kodir = "cp866";
		ElsIf Encoding = "Windows" Then
			Kodir = "windows-1251";
		Else
			Kodir = "UTF-8";
		EndIf;
		
		Text.Read(TempFileName, Kodir);
		BeginDeletingFiles(New CallbackDescription("AfterDeletingFiles", ThisObject), TempFileName);
		
		Return Text;
	#EndIf
	
EndFunction

&AtClient
Procedure AfterDeletingFiles(AdditionalParameters) Export
	
	Return;
	
EndProcedure

&AtClient
Procedure SelectingFile(Item, Load = True);
	
	AddlParameters = New Structure;
	AddlParameters.Insert("Item", Item);
	AddlParameters.Insert("Load", Load);
	
	FileSystemClient.AttachFileOperationsExtension(
		New CallbackDescription("SelectingFileContinued", ThisObject, AddlParameters),, False);
	
EndProcedure

&AtClient
Procedure SelectingFileContinued(ExtensionAttached, AdditionalParameters) Export
	
	If ExtensionAttached Then
	
		Item = AdditionalParameters["Item"];
		Load = AdditionalParameters.Load;
		
		UseDirectory = ?(Load, Object.UseDownloadDirectory, Object.UseUploadDirectory);
		DialogMode = ?(UseDirectory, FileDialogMode.ChooseDirectory, FileDialogMode.Open);
		
		FileDialog = New FileDialog(DialogMode);
		
		If Not UseDirectory Then
		
			If Object.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.ISO20022") Then
				FileDialog.Filter = NStr("vi = 'Tệp XML (*.xml)|*.xml';
										|ru = 'XML файл (*.xml)|*.xml';
										|en = 'XML file (*.xml)|*.xml'; fa = 'XML file (*.xml)|*.xml';
										|it = 'File XML (*.xml)|*.xml';
										|pl = 'Plik XML (*.xml)|*.xml';
										|tr = 'XML dosya (*.xml)|*.xml'");
				FileDialog.DefaultExt = "xml";
				ImportFileName = "camt.xml"
			ElsIf Object.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.ClientBankExchange1c") Then
				FileDialog.Filter = NStr("vi = 'Tệp văn bản (*.txt)|*.txt';
										|ru = 'Текстовый файл (*.txt)|*.txt';
										|en = 'Text file (*.txt)|*.txt'; fa = 'Text file (*.txt)|*.txt';
										|it = 'File di testo (*.txt)|*.txt';
										|pl = 'Plik tekstowy (*.txt)|*.txt';
										|tr = 'Metin dosyası (*.txt)|*.txt'");
				FileDialog.DefaultExt = "txt";
				ImportFileName = "kl_to_1c.txt"
			Else
				FileDialog.Filter = NStr("vi = 'Tệp bất kỳ (*.*)|*.*';
										|ru = 'Любой файл (*.*)|*.*';
										|en = 'Any file (*.*)|*.*'; fa = 'Any file (*.*)|*.*';
										|it = 'Tutti i file (*.*)|*.*';
										|pl = 'Dowolny plik (*.*)|*.*';
										|tr = 'İstenilen dosya (*.*)|*.*'");
			EndIf;
			FileDialog.Preview = False;
			FileDialog.FilterIndex = 0;
			FileDialog.CheckFileExistence = False;
			
		EndIf;
		
		If Load Then
			FileDialog.Title = StrTemplate(NStr("vi = 'Hãy chọn %1 để kết nhập dữ liệu từ chương trình của ngân hàng';
												|ru = 'Выберите %1 для загрузки данных из программы банка';
												|en = 'Select %1 to import data from the bank application'; fa = 'Select %1 to import data from the bank application';
												|it = 'Selezionare %1 per il download dei dati dal programma della banca';
												|pl = 'Wybierz %1 do importu danych z programu banku';
												|tr = 'Banka programından veri indirimi için %1 seç'"),
											?(UseDirectory, NStr("vi = 'thư mục';
																|ru = 'каталог';
																|en = 'directory'; fa = 'directory';
																|it = 'catalogo';
																|pl = 'directory';
																|tr = 'klasör'"), NStr("vi = 'tệp';
																							|ru = 'файл';
																							|en = 'file'; fa = 'file';
																							|it = 'file';
																							|pl = 'file';
																							|tr = 'dosya'")));
			If Not UseDirectory Then
				FileDialog.FullFileName =
					?(IsBlankString(Item.EditText), ImportFileName, Item.EditText);
			EndIf;
		Else
			FileDialog.Title = StrTemplate(NStr("vi = 'Hãy chọn %1 để kết xuất dữ liệu vào chương trình của ngân hàng';
												|ru = 'Выберите %1 для выгрузки данных в программу банка';
												|en = 'Select %1 to export data to the bank application'; fa = 'Select %1 to export data to the bank application';
												|it = 'Selezionare %1 per l''upload dati nel programma della banca';
												|pl = 'Wybierz %1 do eksportu danych do programu banku';
												|tr = 'Banka programına veri yüklemek için %1 seç'"),
											?(UseDirectory, NStr("vi = 'thư mục';
																|ru = 'каталог';
																|en = 'directory'; fa = 'directory';
																|it = 'catalogo';
																|pl = 'directory';
																|tr = 'klasör'"), NStr("vi = 'tệp';
																							|ru = 'файл';
																							|en = 'file'; fa = 'file';
																							|it = 'file';
																							|pl = 'file';
																							|tr = 'dosya'")));
			If Not UseDirectory Then
				FileName_1 = StrReplace(String(New UUID), "-", "");
				FileDialog.FullFileName = ?(IsBlankString(Item.EditText), FileName_1
					+ ?(ValueIsFilled(FileDialog.DefaultExt), "." + FileDialog.DefaultExt, ""),
					Item.EditText);
			EndIf;
		EndIf;
		
		CallbackDescription = New CallbackDescription(
			"SelectingFileCompletion",
			ThisObject,
			New Structure("Load", Load));
		
		FileDialog.Show(CallbackDescription);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectingFileCompletion(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	Modified = True;
	
	If AdditionalParameters.Load Then
		Object.ImportFile = SelectedFiles[0];
	Else
		Object.ExportFile = SelectedFiles[0];
	EndIf;
	
EndProcedure

&AtServer
Function FillInBankDetailsForBIC(BankType, Val BIC = "", TransferBankingDetailsValues = False)
	
	FoundByBIC   = False;
	RecordAboutBank = Undefined;
	
	AttributesNames = CashClientServer.BankingDetails(True, BankType <> "Bank");
	CashClientServer.ClearBankDetailsOnForm(ThisObject, AttributesNames);
	
	If ValueIsFilled(BIC) Then
		
		BankManager.GetClassifierData(BIC,, RecordAboutBank);
		
		If ValueIsFilled(RecordAboutBank) Then
			FillInBankDetailsByBank(BankType, RecordAboutBank, TransferBankingDetailsValues);
			Object[BankType] = RecordAboutBank;
			FoundByBIC = True;
		EndIf;
	EndIf;
	
	Return FoundByBIC;
	
EndFunction

&AtServer
Procedure FillInBankDetailsByBank(BankType, Bank = "", TransferBankingDetailsValues = False)
	
	ComplianceWithBankDetails = CashServer.AccountDetailsByBankClassifier();
	
	If BankType = "Bank" Then
		
		AttributesStructure1 = New Structure;
		AttributesNames = StrSplit(CashClientServer.BankingDetails(), ",", False);
		For Each AttributeName In AttributesNames Do
			AttributesStructure1.Insert(AttributeName, ComplianceWithBankDetails[TrimAll(AttributeName)]);
		EndDo;
		AttributesStructure1.Insert("BankBIC", "Code");
		AttributesStructure1.Insert("BankSWIFTCode", "SWIFTBIC");
		AttributesStructure1.Insert("BankNameInt", "InternationalDescription");
		
		BankingDetails = CashServer.BankAttributes(Bank, AttributesStructure1);
		
		FillPropertyValues(ThisObject, BankingDetails);
		
		CountryOfBank = CashServer.BankCountryByCode(BankingDetails.CountryCode);
		
		If TransferBankingDetailsValues Then
			FillPropertyValues(Object, BankingDetails);
			Object.CountryOfBank = CountryOfBank;
			Object.Bank = Undefined;
		EndIf;
		
		Object.BankAccountForPayments = BankingDetails.BankCorrAccount;
		
	ElsIf BankType = "TransferBank" Then
		
		AttributesStructure1 = New Structure;
		AttributesNames = StrSplit(CashClientServer.BankingDetails(, True), ",", False);
		For Each AttributeName In AttributesNames Do
			AttributesStructure1.Insert(AttributeName, ComplianceWithBankDetails[TrimAll(AttributeName)]);
		EndDo;
		AttributesStructure1.Insert("TransferBankBIC", "Code");
		AttributesStructure1.Insert("BankSWIFTCodeForPayments", "SWIFTBIC");
		AttributesStructure1.Insert("BankNameForPaymentsInt", "InternationalDescription");
		
		BankingDetails = CashServer.BankAttributes(Bank, AttributesStructure1);
		
		FillPropertyValues(ThisObject, BankingDetails);
		
		CountryOfBankForPayments = CashServer.BankCountryByCode(BankingDetails.CountryCode);
		
		If TransferBankingDetailsValues Then
			FillPropertyValues(Object, BankingDetails);
			Object.CountryOfBankForPayments = CountryOfBankForPayments;
			Object.TransferBank = Undefined;
		EndIf;
		
		CashClientServer.FillInMainBankDetailsForSettlements(ThisObject);
		
	EndIf;
	
	GenerateAutoName(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CheckIBAN(Form)

	If IsBlankString(Form.Object.AccountNumber) Then
		Return;
	EndIf;
	
	If CashClientServer.CorrectIBANLength(Form.Object.AccountNumber) Then
		If CashClientServer.ValidIBANControlKey(Form.Object.AccountNumber) Then
			If Form.Object.ManualBankDetailsChange Then
				SWIFT = Form.Object.BankSWIFTCode;
			ElsIf ValueIsFilled(Form.Object.Bank) Then
				SWIFT = CashServerCall.SWIFT(Form.Object.Bank);
			EndIf;
			
			If ValueIsFilled(SWIFT) Then
				If CashClientServer.AccountNumberCorrespondsToBank(Form.Object.AccountNumber, SWIFT) Then
					Form.Items.GroupErrorInAccountNumber.Visible = False;
				Else
					Form.Items.ErrorInAccountNumber.Title = NStr("vi = 'IBAN không phù hợp với ngân hàng';
																|ru = 'IBAN не соответствует банку';
																|en = 'IBAN does not match the bank'; fa = 'IBAN does not match the bank';
																|it = 'L''IBAN non corrisponde alla banca';
																|pl = 'IBAN nie jest zgodny z bankiem';
																|tr = 'IBAN bankayla eşleşmiyor'");
					Form.Items.GroupErrorInAccountNumber.Visible = True;
				EndIf;
			EndIf;
		Else
			Form.Items.ErrorInAccountNumber.Title = NStr("vi = 'Số tài khoản không chính xác';
														|ru = 'Номер счета введен некорректно';
														|en = 'Incorrect account number'; fa = 'Incorrect account number';
														|it = 'Numero di conto inserito errato';
														|pl = 'Numer rachunku został wprowadzony niepoprawnie';
														|tr = 'Hesap numarası yanlış girildi'");
			Form.Items.GroupErrorInAccountNumber.Visible = True;
		EndIf
	Else
		Form.Items.ErrorInAccountNumber.Title = NStr("vi = 'Số tài khoản không khớp với định dạng IBAN';
													|ru = 'Номер счета не соответствует формату IBAN';
													|en = 'The account number does not match the IBAN format'; fa = 'شماره حساب با قالب IBAN مطابقت ندارد';
													|it = 'Il numero di conto non corrisponde al formato IBAN';
													|pl = 'Numer rachunku nie jest zgodny z formatem IBAN';
													|tr = 'Hesap numarası, IBAN formatı ile uyumlu değildir'");
		Form.Items.GroupErrorInAccountNumber.Visible = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	FormFieldSettings = Catalogs.CompaniesBankAccounts.FormFieldSettings();
	ValueToFormAttribute(FormFieldSettings, "FieldSettings");
	DependenciesOfFormFields = CashServer.DependenciesOfFormFields(FormFieldSettings);
	ValueToFormAttribute(DependenciesOfFormFields, "FieldDependencies");
	
	UseMultipleCompanies       = GetFunctionalOption("UseMultipleCompanies");
	UseMultipleCurrencies             = GetFunctionalOption("UseMultipleCurrencies");
	InternationalBankAccountDetails = GetFunctionalOption("InternationalBankAccountDetails");
	NationalBankAccountDetails  = GetFunctionalOption("NationalBankAccountDetails");
	UseEDIWithBanksBankFeeds   =   GetFunctionalOption("UseBankFeedsExchange");
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Owner);
	CurrencyAccount = (ValueIsFilled(Object.CashCurrency) And Object.CashCurrency <> CurrencyOfComplianceAccounting);
	
	AccountNumber = Object.AccountNumber;
	
	If ValueIsFilled(Object.Ref) Or ValueIsFilled(Parameters.CopyingValue) Then
		If InternationalBankAccountDetails And Object.ThisIsAnIBAN Then
			CheckIBAN(ThisObject);
		EndIf;
		If Object.ManualBankDetailsChange Then
			Items.Bank.InputHint = NStr("vi = '<thông tin ngân hàng được nhập thủ công>';
										|ru = '<реквизиты банка введены вручную>';
										|en = '<the bank details are entered manually>'; fa = '<the bank details are entered manually>';
										|it = '<requisiti bancari inseriti manualmente>';
										|pl = '<dane banku zostały wprowadzone ręcznie>';
										|tr = '<banka bilgileri manuel olarak girildi>'");
		EndIf;
		If Object.TransferBankDetailsManualEdit Then
			Items.TransferBank.InputHint = NStr("vi = '<thông tin ngân hàng được nhập thủ công>';
												|ru = '<реквизиты банка введены вручную>';
												|en = '<the bank details are entered manually>'; fa = '<the bank details are entered manually>';
												|it = '<requisiti bancari inseriti manualmente>';
												|pl = '<dane banku zostały wprowadzone ręcznie>';
												|tr = '<banka bilgileri manuel olarak girildi>'");
		EndIf;
	Else
		If InternationalBankAccountDetails Then
			Object.ForeignBank = True;
		Else
			Object.CountryOfBank = MainCountry;
		EndIf;
		If Not ValueIsFilled(Object.Bank) Then
			Object.ManualBankDetailsChange = True;
		EndIf;
		If Not ValueIsFilled(Object.TransferBankAddress) Then
			Object.TransferBankDetailsManualEdit = True;
		EndIf;
	EndIf;
	
	If Object.DirectEDIWithBankIsUsed Then
		ExchangeMode = 1;
	ElsIf Object.UseBankClientDataExchange Then
		ExchangeMode = 2;   
	ElsIf Object.UseBankFeedsBankExchange Then
		ExchangeMode = 3;
	Else
		ExchangeMode = 0;
	EndIf;
	
	LineBankExchangeIsEnabled = ?(Object.BankEDIEnabled, NStr("vi = 'bật';
																|ru = 'включен';
																|en = 'enabled'; fa = 'enabled';
																|it = 'inclusa';
																|pl = 'włączono';
																|tr = 'Etkin'"), NStr("vi = 'không bật';
																						|ru = 'не включен';
																						|en = 'disabled'; fa = 'disabled';
																						|it = 'non inclusa';
																						|pl = 'nie włączono';
																						|tr = 'etkinleştirilmedi'"));
	BankIndicationMethod = ?(Object.ManualBankDetailsChange, "ManualFillingInOfBankingDetails", "SelectionFromCatalog");
	MethodOfSpecifyingBankForSettlements = ?(Object.TransferBankDetailsManualEdit, "ManualFillingInOfBankingDetails",
										"SelectionFromCatalog");
	
	FillInBankDetails();
	
	FormItemsManagement();

	ConfigureDependentFormElementsOnServer();
	
	//++ WE
	InstallBankFeedsPage();
	//-- WE
	
	CashClientServer.FillInMainBankDetails(ThisObject);
	CashClientServer.FillInMainBankDetailsForSettlements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInListOfAccountTypeSelection(AccountTypeSelectionList)
	
	AccountTypeSelectionList.Clear();
	AccountTypeSelectionList.Add(PredefinedValue("Enum.BankAccountTypes.Estimated_"));
	AccountTypeSelectionList.Add(PredefinedValue("Enum.BankAccountTypes.Deposit_"));
	AccountTypeSelectionList.Add(PredefinedValue("Enum.BankAccountTypes.Other_"));
	
EndProcedure

&AtServer
Procedure FillInBankDetails()
	
	If Object.ManualBankDetailsChange Then
		FillPropertyValues(ThisObject, Object, CashClientServer.BankingDetails(True));
	Else
		If Not Object.Bank.IsEmpty() Then
			FillInBankDetailsByBank("Bank", Object.Bank, False);
		EndIf;
	EndIf;
	
	If ValueIsFilled(Object.Ref) Then
		If ValueIsFilled(Object.TransferBank)
			Or ValueIsFilled(Object.TransferBankBIC)
			Or ValueIsFilled(Object.BankSWIFTCodeForPayments) Then
			SettlementBankUsed = True;
		Else
			SettlementBankUsed = False;
		EndIf;
	EndIf;
	
	If Object.TransferBankDetailsManualEdit Then
		FillPropertyValues(ThisObject, Object, CashClientServer.BankingDetails(True, True));
	Else
		If Not Object.TransferBank.IsEmpty() Then
			FillInBankDetailsByBank("TransferBank", Object.TransferBank, False);
		EndIf;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function GenerateAutoName(Form)
	
	Form.Items.Description.ChoiceList.Clear();
	
	If Form.Object.ManualBankDetailsChange Then
		
		If ValueIsFilled(Form.BankDescription) Then
			DescriptionTemplate = NStr("vi = '%1 trong %2, %3';
										|ru = '%1 в %2, %3';
										|en = '%1 in %2, %3'; fa = '%1 in %2, %3';
										|it = '%1 in %2 %3';
										|pl = '%1 w %2 %3';
										|tr = '%2''de %1, %3'");
			NameString_ = StrTemplate(DescriptionTemplate, Right(TrimAll(Form.Object.AccountNumber), 4),
				String(Form.BankDescription), TrimAll(Form.Object.Owner));
		Else
			DescriptionTemplate = NStr("vi = '%1, %2';
										|ru = '%1, %2';
										|en = '%1, %2'; fa = '%1, %2';
										|it = '%1, %2';
										|pl = '%1, %2';
										|tr = '%1, %2'");
			NameString_ = StrTemplate(
				DescriptionTemplate, Right(TrimAll(Form.Object.AccountNumber), 4), TrimAll(Form.Object.Owner));
		EndIf;
		
		NameString_ = Left(NameString_, 150);
		
		If Form.Object.AccountType = PredefinedValue("Enum.BankAccountTypes.Transit") Then
			NameString_ = NStr("vi = 'Đang chuyển';
								|ru = 'Транзитный';
								|en = 'Transit'; fa = 'انتقالی';
								|it = 'Transitorio';
								|pl = 'Tranzytowy';
								|tr = 'Transit'") + " " + NameString_;
		EndIf;
		Form.Items.Description.ChoiceList.Add(NameString_);
		
		NameString_ = ?(ValueIsFilled(Form.BankDescription), String(Form.BankDescription), "")
			+ ", " + TrimAll(Form.Object.Owner) + " (" + String(Form.Object.CashCurrency) + ")";
		NameString_ = Left(NameString_, 150);
		
		If Form.Object.AccountType = PredefinedValue("Enum.BankAccountTypes.Transit") Then
			NameString_ = NStr("vi = 'Đang chuyển';
								|ru = 'Транзитный';
								|en = 'Transit'; fa = 'انتقالی';
								|it = 'Transitorio';
								|pl = 'Tranzytowy';
								|tr = 'Transit'") + " " + NameString_;
		EndIf;
		Form.Items.Description.ChoiceList.Add(NameString_);
	Else
		
		If ValueIsFilled(Form.Object.Bank) Then
			DescriptionTemplate = NStr("vi = '%1 trong %2, %3';
										|ru = '%1 в %2, %3';
										|en = '%1 in %2, %3'; fa = '%1 in %2, %3';
										|it = '%1 in %2 %3';
										|pl = '%1 w %2 %3';
										|tr = '%2''de %1, %3'");
			NameString_ = StrTemplate(DescriptionTemplate, Right(TrimAll(Form.Object.AccountNumber), 4),
				String(Form.Object.Bank), TrimAll(Form.Object.Owner));
		Else
			DescriptionTemplate = NStr("vi = '%1, %2';
										|ru = '%1, %2';
										|en = '%1, %2'; fa = '%1, %2';
										|it = '%1, %2';
										|pl = '%1, %2';
										|tr = '%1, %2'");
			NameString_ = StrTemplate(
				DescriptionTemplate, Right(TrimAll(Form.Object.AccountNumber), 4), TrimAll(Form.Object.Owner));
		EndIf;

		NameString_ = Left(NameString_, 150);
		
		If Form.Object.AccountType = PredefinedValue("Enum.BankAccountTypes.Transit") Then
			NameString_ = NStr("vi = 'Đang chuyển';
								|ru = 'Транзитный';
								|en = 'Transit'; fa = 'انتقالی';
								|it = 'Transitorio';
								|pl = 'Tranzytowy';
								|tr = 'Transit'") + " " + NameString_;
		EndIf;
		Form.Items.Description.ChoiceList.Add(NameString_);
		
		NameString_ = ?(ValueIsFilled(Form.Object.Bank), String(Form.Object.Bank), "")
			+ ", " + TrimAll(Form.Object.Owner) + " (" + String(Form.Object.CashCurrency) + ")";
		NameString_ = Left(NameString_, 150);
		
		If Form.Object.AccountType = PredefinedValue("Enum.BankAccountTypes.Transit") Then
			NameString_ = NStr("vi = 'Đang chuyển';
								|ru = 'Транзитный';
								|en = 'Transit'; fa = 'انتقالی';
								|it = 'Transitorio';
								|pl = 'Tranzytowy';
								|tr = 'Transit'") + " " + NameString_;
		EndIf;
		Form.Items.Description.ChoiceList.Add(NameString_);
	EndIf;
	
	Return NameString_;
	
EndFunction

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

&AtServerNoContext
Function FindBankAccountDuplicate(Ref, AccountNumber, Organization, Currency, Bank)
	
	SetPrivilegedMode(True);
	
	Query = New Query("
	|SELECT TOP 1
	|	BankAccounts.Ref AS Ref
	|FROM
	|	Catalog.CompaniesBankAccounts AS BankAccounts
	|WHERE
	|	NOT BankAccounts.DeletionMark
	|	AND BankAccounts.Ref <> &Ref
	|	AND BankAccounts.AccountNumber = &AccountNumber
	|	AND BankAccounts.Owner = &Organization
	|	AND BankAccounts.CashCurrency = &Currency
	|	AND BankAccounts.Bank = &Bank
	|");
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("AccountNumber", AccountNumber);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Currency", Currency);
	Query.SetParameter("Bank", Bank);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return Undefined;
	Else
		Selection = QueryResult.Select();
		Selection.Next();
		Return Selection.Ref;
	EndIf;
	
EndFunction

&AtServer
Procedure BankWhenChangedOnServer()
	
	Object.ExportFile = Catalogs.CompaniesBankAccounts.DefaultUploadFile(Object.Bank);
	Object.ImportFile = Catalogs.CompaniesBankAccounts.DefaultDownloadFile(Object.Bank);
	
EndProcedure

&AtClient
Procedure ConfigureDependentFormElements(ChangedProps = "")
	
	CustomizeFormElements(ThisObject, ChangedProps, FormAttributes(ThisObject));
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedProps = "")
	
	CustomizeFormElements(ThisObject, ChangedProps, FormAttributes(ThisObject));
	
EndProcedure

&AtClientAtServerNoContext
Function FormAttributes(Form)
	
	FormAttributes = New Structure;
	FormAttributes.Insert("PaymentSupport275FZ");
	FormAttributes.Insert("UseExchangesWithBanks");
	FormAttributes.Insert("UseEDIWithBanksBankFeeds");	
	FormAttributes.Insert("UseCurrencyPayments");
	FormAttributes.Insert("UseMultipleCurrencies");
	FormAttributes.Insert("UseMultipleCompanies");
	FormAttributes.Insert("UseCorrespondentText");
	FormAttributes.Insert("UseCorrespondentSBudgetText");
	FormAttributes.Insert("SettlementBankUsed");
	FormAttributes.Insert("DirectBankIsConfigured");
	FormAttributes.Insert("CurrencyAccount");
	FormAttributes.Insert("TransitAccountIsSpecified");
	FormAttributes.Insert("InternationalBankAccountDetails");
	FormAttributes.Insert("NationalBankAccountDetails");
	FormAttributes.Insert("DataSeparationEnabled");
	
	FillPropertyValues(FormAttributes, Form);
	
	Return FormAttributes;
	
EndFunction

&AtClient
Procedure DisplayWarningAboutTerminationOfBankSActivities()

	InfoText = InformationAboutSuspensionOfBankSActivities(Object.Bank);
	
	If InfoText <> "" Then
		ShowMessageBox(, InfoText);
	EndIf;

EndProcedure

// Returns information about the completion of the bank's activities
//
// Parameters:
//  Bank - CatalogRef.BankClassifier - the bank for which you need to output the information
// 
// Returns:
//  String
//
&AtServer
Function InformationAboutSuspensionOfBankSActivities(Bank)

	InformationLine = "";
	CurrentBank = Not Common.ObjectAttributeValue(Bank, "OutOfBusiness");
	
	If Not CurrentBank Then
		InformationLine = BankManager.InvalidBankNote(Bank);
	EndIf;
	
	Return InformationLine;

EndFunction

&AtServer
Procedure FormItemsManagement()

	GenerateAutoName(ThisObject);
	FillInListOfAccountTypeSelection(Items.AccountType.ChoiceList);
	FillInExchangeFormatSelectionList(Object.AccountType, Items.ExchangeFormat.ChoiceList);
	
	Items.BankIndicationMethod.ReadOnly = ReadOnly;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInExchangeFormatSelectionList(Var_AccountType, ChoiceList)

	ChoiceList.Clear();
	
	ChoiceList.Add(PredefinedValue("Enum.ExchangeFormatWithBank.ClientBankExchange1c"));
	ChoiceList.Add(PredefinedValue("Enum.ExchangeFormatWithBank.ISO20022"));
	ChoiceList.Add(PredefinedValue("Enum.ExchangeFormatWithBank.MT940"));
	
	If Var_AccountType = PredefinedValue("Enum.BankAccountTypes.Treasury") Then
		ChoiceList.Add(PredefinedValue("Enum.ExchangeFormatWithBank.FederalTreasuryOfTheRussianFederation"));
	EndIf;

EndProcedure

&AtServer
Procedure DisplayHintForMainInvoice()
	
	If Catalogs.Companies.GetPrimaryBankAccount(Object.Owner) = Object.Ref Then
		Items.Description.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
	Else
		Items.Description.ToolTipRepresentation = ToolTipRepresentation.None;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ClosingMainAccount(Val BankAccount, Val Organization)
	
	If Catalogs.Companies.GetPrimaryBankAccount(Organization) = BankAccount
		And Not Common.ObjectAttributeValue(BankAccount, "Closed") Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

&AtClient
Procedure AskAboutClosingMainAccount(Cancel)
	
	If Not Object.Closed Or QuestionAboutClosingAccountHasBeenAsked Then
		Return;
	EndIf;
	
	If ClosingMainAccount(Object.Ref, Object.Owner) Then
		
		Cancel = True;
		QuestionAboutClosingAccountHasBeenAsked = True;
		
		If OrganizationChangeIsAvailable Then
			Notification = New CallbackDescription("AfterQuestionOfClosingMainAccount", ThisObject);
			FormParameters = New Structure;
			FormParameters.Insert("BankAccount", Object.Ref);
			FormParameters.Insert("Organization", Object.Owner);
			OpenForm("Catalog.CompaniesBankAccounts.Form.ClosingMainAccount", FormParameters,
				ThisObject, , , , Notification);
		Else
			WarningTitle = NStr("vi = 'Đóng tài khoản ngân hàng chính';
								|ru = 'Закрытие основного банковского счета';
								|en = 'Close main bank account'; fa = 'بستن حساب بانکی اصلی';
								|it = 'Close main bank account';
								|pl = 'Close main bank account';
								|tr = 'Ana banka hesabının kapatılması'");
			WarningText =
				NStr("vi = 'Tài khoản ngân hàng là tài khoản chính của doanh nghiệp.
				|Khi đóng tài khoản trong các chứng từ mới, hệ thống không thể điền tự động tài khoản của doanh nghiệp.
				|Nên ấn định tài khoản khác là chính trước khi đóng tài khoản này.';
				|ru = 'Банковский счет является основным для организации.
				|При закрытии счета в новых документах счет организации может не заполниться автоматически.
				|Рекомендуется перед закрытием назначить другой счет основным.';
				|en = 'The bank account is the main one for the company.
				|If you close the account, the company account may not be filled in automatically in new documents.
				|We recommend that you set another account as the main account before closing.'; fa = 'The bank account is the main one for the company.
				|If you close the account, the company account may not be filled in automatically in new documents.
				|We recommend that you set another account as the main account before closing.';
				|it = 'The bank account is the main one for the company.
				|If you close the account, the company account may not be filled in automatically in new documents.
				|We recommend that you set another account as the main account before closing.';
				|pl = 'The bank account is the main one for the company.
				|If you close the account, the company account may not be filled in automatically in new documents.
				|We recommend that you set another account as the main account before closing.';
				|tr = 'Banka hesabı iş yeri için ana hesaptır. 
				|Hesap kapatıldığında yeni belgelerde iş yeri hesabı otomatik olarak doldurulmayabilir.
				|Kapatmadan önce başka bir hesabın ana hesap olarak atanması önerilir.'");
			ShowMessageBox( , WarningText, , WarningTitle);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterQuestionOfClosingMainAccount(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.OK Then
		QuestionAboutClosingAccountHasBeenAsked = False;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

