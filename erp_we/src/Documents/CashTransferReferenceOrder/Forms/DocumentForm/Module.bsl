
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	SpecifyListOfBusinessOperations();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	ConfigureDependentFormElementsOnServer();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// Used for automatic updating of the payment calendar form
	Notify("Write_CashTransferReferenceOrder", WriteParameters, Object.Ref);
	
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
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	BusinessOperationOnChangeServer();
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	FillInDetailsOfDocumentOnEconomicOperation();
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure CashAccountOnChange(Item)
	
	AttributesStructure1 = GetCheckoutDetails(Object.CashAccount);
	
	If Not FinancesClient.CurrencyConversionRequired(Object, Object.Currency, AttributesStructure1.Currency) Then
		
		CashAccountOnChangeServer(AttributesStructure1, False);
	Else
		
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tính lại số tiền trong chứng từ theo tiền tệ %1?';
				|ru = 'Пересчитать суммы в документе в валюту %1?';
				|en = 'Convert amounts in the document in %1?'; fa = 'Convert amounts in the document in %1?';
				|it = 'Ricalcolare gli importi del documento in valuta %1?';
				|pl = 'Przeliczyć kwoty w dokumencie na walutę %1?';
				|tr = 'Belgedeki tutarlar %1 para birimine göre yeniden hesaplansın mı?'"),
			AttributesStructure1.Currency);
		
		QuestionDialogButtons = New ValueList;
		QuestionDialogButtons.Add(DialogReturnCode.Yes, NStr("vi = 'Tính lại';
															|ru = 'Пересчитать';
															|en = 'Recalculate'; fa = 'محاسبه مجدد';
															|it = 'Ricalcolare';
															|pl = 'Recalculate';
															|tr = 'Yeniden hesapla'"));
		QuestionDialogButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
																|ru = 'Отменить';
																|en = 'Cancel'; fa = 'انصراف';
																|it = 'Annullare';
																|pl = 'Cancel';
																|tr = 'İptal et'"));
		
		CallbackDescription = New CallbackDescription("ConversionToCashRegisterCurrencyIsAllowed", ThisObject, New Structure("AttributesStructure1", AttributesStructure1));
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogButtons);
	EndIf;
	
EndProcedure

&AtClient
Procedure ConversionToCashRegisterCurrencyIsAllowed(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		CurrentCurrency = Object.Currency;
		CashAccountOnChangeServer(AdditionalParameters.AttributesStructure1, True);
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(CurrentCurrency, Object.Currency);
	Else
		
		Object.CashAccount = CurrentCashAccount;
	EndIf;
	
EndProcedure

&AtServer
Procedure CashAccountOnChangeServer(AttributesStructure1, AmountsRecalculate)
	
	CurrentCashAccount = Object.CashAccount;
	
	If ValueIsFilled(Object.CashAccount) Then
		Object.Organization = AttributesStructure1.Organization;
	EndIf;
	
	CurrentCurrency = Object.Currency;
	Object.Currency = AttributesStructure1.Currency;
	
	If AmountsRecalculate Then
		ConversionOfDocumentAmountsIntoCurrency(CurrentCurrency);
	EndIf;
	
	Object.BankAccountBeneficiary = Catalogs.CompaniesBankAccounts.EmptyRef();
	Object.CashAccountRecipient          = Catalogs.CashAccounts.EmptyRef();
	
EndProcedure

&AtClient
Procedure BankAccountOnChange(Item)
	
	AttributesStructure1 = GetBankAccountDetails(Object.BankAccount);
	
	If Not FinancesClient.CurrencyConversionRequired(Object, Object.Currency, AttributesStructure1.Currency) Then
		
		BankAccountOnChangeServer(AttributesStructure1, False);
	Else
		
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tính lại số tiền trong chứng từ theo tiền tệ %1?';
				|ru = 'Пересчитать суммы в документе в валюту %1?';
				|en = 'Convert amounts in the document in %1?тировки'; fa = 'Convert amounts in the document in %1?тировки';
				|it = 'Ricalcolare gli importi del documento in valuta %1?';
				|pl = 'Przeliczyć kwoty w dokumencie na walutę %1?';
				|tr = 'Belgedeki tutarlar %1 para birimine göre yeniden hesaplansın mı?'"),
			AttributesStructure1.Currency);
		
		QuestionDialogButtons = New ValueList;
		QuestionDialogButtons.Add(DialogReturnCode.Yes, NStr("vi = 'Tính lại';
															|ru = 'Пересчитать';
															|en = 'Recalculate'; fa = 'محاسبه مجدد';
															|it = 'Ricalcolare';
															|pl = 'Recalculate';
															|tr = 'Yeniden hesapla'"));
		QuestionDialogButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
																|ru = 'Отменить';
																|en = 'Cancel'; fa = 'انصراف';
																|it = 'Annullare';
																|pl = 'Cancel';
																|tr = 'İptal et'"));
		
		CallbackDescription = New CallbackDescription("ConversionToAccountCurrencyIsAllowed", ThisObject, New Structure("AttributesStructure1", AttributesStructure1));
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogButtons);
	EndIf;
	
EndProcedure

&AtClient
Procedure ConversionToAccountCurrencyIsAllowed(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		CurrentCurrency = Object.Currency;
		BankAccountOnChangeServer(AdditionalParameters.AttributesStructure1, True);
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(CurrentCurrency, Object.Currency);
	Else
		
		Object.BankAccount = CurrentBankAccount;
	EndIf;
	
EndProcedure

&AtServer
Procedure BankAccountOnChangeServer(AttributesStructure1, AmountsRecalculate)
	
	CurrentBankAccount = Object.BankAccount;
	
	
	If ValueIsFilled(Object.BankAccount) Then
		Object.Organization = AttributesStructure1.Organization;
	EndIf;
	
	CurrentCurrency = Object.Currency;
	Object.Currency = AttributesStructure1.Currency;
	
	If AmountsRecalculate Then
		ConversionOfDocumentAmountsIntoCurrency(CurrentCurrency);
	EndIf;
	
	Object.BankAccountBeneficiary = Catalogs.CompaniesBankAccounts.EmptyRef();
	Object.CashAccountRecipient          = Catalogs.CashAccounts.EmptyRef();
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	ConfigureDependentFormElements("Status");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

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

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

#EndRegion

#Region Private

#Region FormItemsManagement

&AtServer
Procedure FormItemsManagement()
	
	ConfigureDependentFormElementsOnServer();
	
	
EndProcedure

&AtServer
Procedure SpecifyListOfBusinessOperations()
	
	UseMultipleBankAccounts = GetFunctionalOption("UseMultipleBankAccounts");
	UseMultipleCashAccounts            = GetFunctionalOption("UseMultipleCashAccounts");
	
	If Not UseMultipleBankAccounts Then
		ListOfSelectBusinessOperations = Items.BusinessOperation.ChoiceList;
		FoundItem = ListOfSelectBusinessOperations.FindByValue(
			Enums.BusinessTransactions.TransferCashToAnotherAccount);
		If FoundItem <> Undefined Then
			ListOfSelectBusinessOperations.Delete(FoundItem);
		EndIf;
	EndIf;
	
	If Not UseMultipleCashAccounts Then
		ListOfSelectBusinessOperations = Items.BusinessOperation.ChoiceList;
		FoundItem = ListOfSelectBusinessOperations.FindByValue(
			Enums.BusinessTransactions.CashIssueToAnotherCashAccount);
		If FoundItem <> Undefined Then
			ListOfSelectBusinessOperations.Delete(FoundItem);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	CashServer.ManagingFormElementsWhenReadingCreatingOnServer(ThisObject);
	
	CurrentCashAccount = Object.CashAccount;
	CurrentBankAccount = Object.BankAccount;
	FormItemsManagement();
	
EndProcedure

&AtServer
Procedure FillInDetailsOfDocumentOnEconomicOperation()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CashDepositToBankAccount
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashCollectionToBank Then
		
		ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
		ParametersStructure.Organization  = Object.Organization;
		ParametersStructure.CashAccount        = Object.CashAccount;
		
		Object.CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
		Object.Currency = Catalogs.CashAccounts.GetCheckoutDetails(Object.CashAccount).Currency;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromBank
		Or Object.BusinessOperation = Enums.BusinessTransactions.WithdrawalFromBankAccount Then
		
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
		Object.BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
			Object.BankAccount);
		Object.Currency = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(Object.BankAccount).Currency;
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromBank
		Or Object.BusinessOperation = Enums.BusinessTransactions.WithdrawalFromBankAccount Then
		
		CompanyRecipient = Object.Organization;
		
		CashAccountRecipient = Catalogs.CashAccounts.GetCheckoutByDefault(
			CompanyRecipient,
			Object.Currency);
		If ValueIsFilled(CashAccountRecipient) Then
			Object.CashAccountRecipient = CashAccountRecipient;
		EndIf;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.CashDepositToBankAccount
		Or Object.BusinessOperation = Enums.BusinessTransactions.CashCollectionToBank Then
		
		CompanyRecipient = Object.Organization;
		
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(CompanyRecipient);
		ParametersOfAccount.Currency = Object.Currency;
		BankAccountBeneficiary = Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(
			ParametersOfAccount);
		If ValueIsFilled(BankAccountBeneficiary) Then
			Object.BankAccountBeneficiary = BankAccountBeneficiary;
		EndIf;
	EndIf;
	
	
EndProcedure

&AtServerNoContext
Function GetCheckoutDetails(CashAccount)
	
	Return Catalogs.CashAccounts.GetCheckoutDetails(CashAccount);
	
EndFunction

&AtServerNoContext
Function GetBankAccountDetails(BankAccount)
	
	Return Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(BankAccount);
	
EndFunction

&AtServer
Procedure ConversionOfDocumentAmountsIntoCurrency(CurrentCurrency)
	
	CashServer.ConversionOfDocumentAmountsIntoCurrency(
		Object,
		CurrentCurrency,
		Object.Currency);
	
EndProcedure

&AtClient
Procedure ConfigureDependentFormElements(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisForm, ChangedProps, FormAttributes(ThisForm));
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisForm, ChangedProps, FormAttributes(ThisForm));
	
EndProcedure

&AtClientAtServerNoContext
Function FormAttributes(Form)
	
	FormAttributes = New Structure;
	FormAttributes.Insert("Modified");
	
	FillPropertyValues(FormAttributes, Form);
	
	Return FormAttributes;
	
EndFunction

#EndRegion

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure ReferenceDocumentsFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	Return;
	
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
