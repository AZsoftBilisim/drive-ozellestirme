
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	EstablishOrganization();
	
	If Parameters.Property("Filter") Then
		
		If Parameters.Filter.Property("LineOfBusiness") Then
			
			CommonClientServer.SetDynamicListFilterItem(
				List,
				"LineOfBusiness",
				Parameters.Filter.LineOfBusiness,
				DataCompositionComparisonType.Equal,
				,
				ValueIsFilled(Parameters.Filter.LineOfBusiness));
				
			Organization = ?(ValueIsFilled(Parameters.Filter.LineOfBusiness),
							Catalogs.Companies.EmptyRef(),
							Organization);
			CommonClientServer.SetDynamicListFilterItem(
				List,
				"Owner",
				Organization,
				DataCompositionComparisonType.Equal,
				,
				ValueIsFilled(Organization));
			
		EndIf;
		
	EndIf;
	
	Items.Organization.Visible = GetFunctionalOption("UseMultipleCompanies");
	OrganizationChangeIsAvailable = AccessRight("Update", Metadata.Catalogs.Companies);
	Items.SetPrimaryBankAccountList.Visible = OrganizationChangeIsAvailable;
	CommonClientServer.SetDynamicListParameter(List, "MainBankAccount", MainBankAccount);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	CashServerLocalization.AddBankAccountCreationCommands(ThisObject, Metadata.Catalogs.CompaniesBankAccounts);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	If EventName = "UpdateListOfBankAccounts" Then
		
		Items.List.Refresh();
		
	ElsIf EventName = "Write_Companies" Then
		
		If Source = Organization And MainBankAccount <> Undefined Then
			UpdateTheListOfAccounts(Undefined);
		Else
			Items.List.Refresh();
		EndIf;
		
	ElsIf EventName = "ChangingMainBankAccount" Then
		
		If TypeOf(FormOwner) = Type("ClientApplicationForm")
			And Source.UUID = FormOwner.UUID Then
			UpdateTheListOfAccounts(Parameter);
		EndIf;
		
	ElsIf EventName = "Write_CompaniesBankAccounts" Then
		
		AttachIdleHandler("SetCommandAvailabilityOfMainBankAccount", 0.1, True);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If Items.CompanyFilter.ReadOnly Then
		Settings.Delete("Organization");
	Else
		Organization = Settings.Get("Organization");
		CommonClientServer.SetDynamicListFilterItem(List, "Owner", Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
	EndIf;
	
	OnlyValidOnes = Settings.Get("OnlyValidOnes");
	Items.OnlyValidOnes.Check = OnlyValidOnes;
	OnlyValidWhenServerChanges();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If TypeOf(FormOwner) = Type("ClientApplicationForm")
		And TypeOf(FormOwner.Object.Ref) = Type("CatalogRef.Companies")
		And MainBankAccount <> FormOwner.Object.MainBankAccount Then
		UpdateTheListOfAccounts(FormOwner.Object.MainBankAccount);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompanyFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Owner", Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
	
EndProcedure

&AtClient
Procedure AddFromBankFeeds(Command)
	
	//++ WE
	FormParameters = New Structure("Organization,ConnectionFormCommand", 
									Organization, CommandOfConnectionFormOnServer().AddInvoice);
	NotificationAboutClosingFormOfListOfInvoicesReadInService = 
		New CallbackDescription("EndOfAddingInvoicesFromService", ThisObject, New Structure());
	
	OpenForm("InformationRegister.ConnectionsToBankFeedsBanks.Form.ConnectionForm",FormParameters, 
								ThisObject,,,,NotificationAboutClosingFormOfListOfInvoicesReadInService
								,FormWindowOpeningMode.LockOwnerWindow);
	//-- WE
	
	Return;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)

	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
	SetCommandAvailabilityOfMainBankAccount();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure MainBankAccount(Command)
	
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.ThisIsMainAccount Then
		MainBankAccount = PredefinedValue("Catalog.CompaniesBankAccounts.EmptyRef");
	Else
		MainBankAccount = CurrentData.Ref;
	EndIf;
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("Organization", CurrentData.Owner);
	ParametersStructure.Insert("MainBankAccount", MainBankAccount);
	
	If TypeOf(FormOwner) = Type("ClientApplicationForm")
		And TypeOf(FormOwner.Object.Ref) = Type("CatalogRef.Companies") Then
		SetMainBankAccountInForm(ParametersStructure);
	Else
		SetUpPrimaryBankAccount(ParametersStructure);
		UpdateTheListOfAccounts(Undefined);
	EndIf;
	
	SetCommandAvailabilityOfMainBankAccount();
	
EndProcedure

#EndRegion

#Region Private

//++ WE
#Region BankFeeds

 &AtClient
Procedure EndOfAddingInvoicesFromService(Result, AdditionalParameters) Export
	
	If Result = Undefined
		Or Result = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	ListOfAddedAccounts = Result.ListOfAddedAccounts;	
	
	NumberOfAccountsAdded = ListOfAddedAccounts.Count();
	
	If NumberOfAccountsAdded > 0 Then
	
		If NumberOfAccountsAdded = 1 Then
			MessageText = NStr("vi = 'Đã thêm tài khoản';
								|ru = 'Счет добавлен';
								|en = 'Account is added'; fa = 'Account is added';
								|it = 'Счет добавлен';
								|pl = 'Account is added';
								|tr = 'Hesap eklendi'");  
			
		Else
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã thêm %1 tài khoản';
					|ru = 'Добавлено %1 счета';
					|en = 'Account added: %1'; fa = 'Account added: %1';
					|it = 'Добавлено %1 счета';
					|pl = 'Account added: %1';
					|tr = '%1 hesap eklendi'"),
				NumberOfAccountsAdded);
			
		EndIf;

		ShowUserNotification(MessageText,,,,UserNotificationStatus.Important);
		
	EndIf;		
	
EndProcedure	

&AtClient
Procedure ClosingSaltEdgeAuthorizationForm(Result, AdditionalParameters) Export
	
	FillParameters = Result.FillParameters;
	
	ExchangeWithBankFeedsServiceClient.ReadCompanySInvoicesInService(FillParameters, ThisObject);	
	
EndProcedure	

&AtServerNoContext
Function CommandOfConnectionFormOnServer()
	
	Return BankFeedsDictionaryInternal.CommandsForOpeningActivationForm();
	
EndFunction

#EndRegion
//-- WE

#Region Other

&AtServer
Procedure EstablishOrganization()
	
	If Parameters.Property("Filter")
	   And Parameters.Filter.Property("Owner")
	Then
		Organization = Parameters.Filter.Owner;
		Items.CompanyFilter.ReadOnly = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnlyValidOnes(Command)
	
	Items.OnlyValidOnes.Check = Not Items.OnlyValidOnes.Check;
	
	OnlyValidOnes = Items.OnlyValidOnes.Check;
	OnlyValidWhenServerChanges();
	
EndProcedure

&AtServer
Procedure OnlyValidWhenServerChanges()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Closed",
		OnlyValidOnes,
		DataCompositionComparisonType.NotEqual,
		,
		OnlyValidOnes);
	
EndProcedure

#EndRegion

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_CreateBankAccount(Command)
	CashClientLocalization.OpenBankAccountCreation(List, Command);
EndProcedure

&AtClient
Procedure SetMainBankAccountInForm(ParametersStructure)
	
	Try
		FormOwner.LockFormDataForEdit();
	Except
		Return;
	EndTry;
	
	Notify("InstallationOfMainBankAccount", ParametersStructure);
	
EndProcedure

&AtServerNoContext
Procedure SetUpPrimaryBankAccount(Val ParametersStructure)
	
	Catalogs.Companies.SetUpPrimaryBankAccount(
		ParametersStructure.Organization, ParametersStructure.MainBankAccount);
	
EndProcedure

&AtClient
Procedure UpdateTheListOfAccounts(MainAccountBeingSetUp)
	
	MainBankAccount = MainAccountBeingSetUp;
	CommonClientServer.SetDynamicListParameter(
		List, "MainBankAccount", MainBankAccount);
	Items.List.Refresh();
	
EndProcedure

&AtClient
Procedure SetCommandAvailabilityOfMainBankAccount()
	
	CurrentData = Items.List.CurrentData;
	If CurrentData <> Undefined And OrganizationChangeIsAvailable Then
		Items.SetPrimaryBankAccountList.Check = CurrentData.ThisIsMainAccount;
		YouCanSetMainAccount = Not CurrentData.Closed;
		Items.SetPrimaryBankAccountList.Enabled = YouCanSetMainAccount;
	EndIf;
	
EndProcedure

#EndRegion
