
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetConditionalAppearance();
	
	EstablishConnectionsOfBankAccountSelectionParameters();
	
	UseMultipleCompanies = GetFunctionalOption("UseMultipleCompanies");
	Items.CompanyFilter.Visible = UseMultipleCompanies;
	Items.CashInTransitOrganization.Visible = UseMultipleCompanies;
	
	UseMultipleBankAccounts = GetFunctionalOption("UseMultipleBankAccounts");
	Items.BankAccountSelection.Visible = UseMultipleBankAccounts;
	Items.CashInTransitBankAccount.Visible = UseMultipleBankAccounts;
	
	UseMultipleCashAccounts = GetFunctionalOption("UseMultipleCashAccounts");
	Items.CashInTransitCashAccount.Visible = UseMultipleBankAccounts;
	
	FillInFormDetailsWhenCreating();
	ConfigureDocumentManagementButtons();
	
	DocumentTypesUsed = New Array();
	DocumentTypesUsed.Add(Type("DocumentRef.CashDepositWithdrawalDiscrepancies"));
	DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.DiscrepanciesOnCashCollectionCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	URL = "e1cib/list/Document.CashDepositWithdrawalDiscrepancies";
	
	DiscrepanciesOnCashCollection.Parameters.SetParameterValue("RefType",
		Common.MetadataObjectID("Document.CashDepositWithdrawalDiscrepancies"));
		
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.DiscrepanciesOnCashCollection,
		BusinessTransactionsAndDocuments);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(
		ThisObject,
		Items.DiscrepanciesOnCashCollectionCommandBar);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_CashVoucher"
		Or EventName = "Write_BankAccountReceiptNote"
		Or EventName = "Write_CashDepositWithdrawalDiscrepancies" Then
		UpdateDynamicLists();
	EndIf;
	
	If EventName = "Conducting_Storno"
		Or EventName = "Write_ReversingEntry"
		Or EventName = "Write_CashDepositWithdrawalDiscrepancies" Then
			 Items.DiscrepanciesOnCashCollection.Refresh();
	EndIf;

EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Organization = Settings.Get("Organization");
	BankAccount = Settings.Get("BankAccount");
	Period = Settings.Get("Period");
	
	SetDynamicListSelection();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	UpdateDynamicLists();
	
EndProcedure

&AtClient
Procedure CompanyFilterOnChange(Item)
	
	OrganizingChangesWhenChangesAreMadeOnServer();
	
EndProcedure

&AtServer
Procedure OrganizingChangesWhenChangesAreMadeOnServer()
	
	EstablishConnectionsOfBankAccountSelectionParameters();
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure BankAccountSelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		DiscrepanciesOnCashCollection,
		"BankAccount",
		BankAccount,
		DataCompositionComparisonType.InHierarchy,
		,
		ValueIsFilled(BankAccount));
		
	CommonClientServer.SetDynamicListFilterItem(
		CashInTransit,
		"BankAccount",
		BankAccount,
		DataCompositionComparisonType.InHierarchy,
		,
		ValueIsFilled(BankAccount));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDiscrepanciesOnCashCollection

&AtClient
Procedure DiscrepanciesOnCashCollectionOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure DiscrepanciesOnCashCollectionBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	If Copy Then
		TMCommonUseClient.CopyItem(Item);
	Else
		OpenForm("Document.CashDepositWithdrawalDiscrepancies.ObjectForm", , Items.DiscrepanciesOnCashCollection);
	EndIf;
	Cancel = True;
	
EndProcedure

&AtClient
Procedure DiscrepanciesOnCashCollectionSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure DiscrepanciesOnCashCollectionBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure DiscrepanciesInTheCollectionOfCash(Command)
	
	TMCommonUseClient.PostDocuments(Items.DiscrepanciesOnCashCollection, Title);
	
EndProcedure

&AtClient
Procedure DiscrepanciesInTheCollectionCancellationOfTheEvent(Command)
	
	TMCommonUseClient.UndoPosting(Items.DiscrepanciesOnCashCollection, Title);
	
EndProcedure

&AtClient
Procedure DiscrepanciesInCashCollectionCopy(Command)
	
	TMCommonUseClient.CopyItem(Items.DiscrepanciesOnCashCollection);
	
EndProcedure

&AtClient
Procedure DiscrepanciesInTheCollectionSetRemoveTheDeletionMark(Command)
	
	TMCommonUseClient.SetDeletionMark(Items.DiscrepanciesOnCashCollection, Title);
EndProcedure

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
	SetSelectionByPeriod();
	
EndProcedure

&AtServer
Procedure SetSelectionByPeriod()
	
	DiscrepanciesOnCashCollection.Parameters.SetParameterValue("BeginOfPeriod",
		Period.StartDate);
	DiscrepanciesOnCashCollection.Parameters.SetParameterValue("EndOfPeriod", 
		Period.EndDate);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RecordDiscrepancy(Command)
	
	RowData = Items.CashInTransit.CurrentData;
	
	If RowData <> Undefined Then
		StructureBase = New Structure("Organization, BankAccount, CashAccount, Currency");
		FillPropertyValues(StructureBase, RowData);
		If RowData.AmountInTransit > 0 Then
			StructureBase.Insert("Sum", RowData.AmountInTransit);
			StructureBase.Insert("BusinessOperation",
				PredefinedValue("Enum.BusinessTransactions.RecordShortageOnCashCollection"));
		Else
			StructureBase.Insert("Sum", RowData.ExcessAmount);
			StructureBase.Insert("BusinessOperation",
				PredefinedValue("Enum.BusinessTransactions.RecordSurplusDuringCashCollection"));
		EndIf;
		
		ParametersStructure1 = New Structure("Basis", StructureBase);
		
		OpenForm("Document.CashDepositWithdrawalDiscrepancies.ObjectForm", ParametersStructure1, Items.DiscrepanciesOnCashCollection);
	EndIf;
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.DiscrepanciesOnCashCollection);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.DiscrepanciesOnCashCollection, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.DiscrepanciesOnCashCollection);
EndProcedure

// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Items.DiscrepanciesOnCashCollection);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure Attachable_CreateDocument(Command)
	
	StructureSelections = New Structure("Organization, BankAccount", Organization, BankAccount);
	TMCommonUseClient.CreateDocumentUsingCommand(Command.Name, StructureSelections);
	
EndProcedure

#EndRegion

#Region Private 

#Region DocumentJournal

&AtServer
Procedure FillInFormDetailsWhenCreating()
	
	TableOfValuesAvailable = Documents.CashDepositWithdrawalDiscrepancies.InitializeBusinessTransactionsAndDocuments(
		BusinessTransactionsAndDocuments.Unload());
	
	BusinessTransactionsAndDocuments.Load(TableOfValuesAvailable);
	
EndProcedure

&AtServer
Procedure ConfigureDocumentManagementButtons()
	
	ParametersStructure = TMCommonUse.StructureOfSettingsForDocumentManagementButtons();
	ParametersStructure.Form 												= ThisObject;
	ParametersStructure.NameOfCreateGroup 									="ListGroupCreateGenerated";
	ParametersStructure.GroupNameCreateContext							= "";
	ParametersStructure.NameOfCopyButton 								= "DiscrepanciesInCashCollectionCopy";
	ParametersStructure.NameOfCopyContextMenuButton 				= "ListContextMenuCopy";
	ParametersStructure.NameOfHoldContextMenuButton 					= "ListContextMenuPost";
	ParametersStructure.NameOfCancelButtonIsContextMenu 			= "ListContextMenuUndoPosting";
	ParametersStructure.ButtonNameMarkDeleteContextMenu 	= "ListContextMenuSetDeletionMark";
	
	TMCommonUse.ConfigureDocumentManagementButtons(ParametersStructure);

EndProcedure

#EndRegion

&AtServer
Procedure SetConditionalAppearance()
	
	// Conditional design of the dynamic list "List"
	ListOfConditionalAppearance = DiscrepanciesOnCashCollection.SettingsComposer.Settings.ConditionalAppearance;
	ListOfConditionalAppearance.Items.Clear();
	
	//
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField("BusinessOperation");
	Item.Presentation = NStr("vi = 'Phản ánh thiếu hụt / Chi';
							|ru = 'Отражение недостачи / Списание';
							|en = 'Cash shortage recognition / Write-off'; fa = 'شناسایی کسری نقد / اسقاط';
							|it = 'Registrazione carenza / Cancellazione';
							|pl = 'Odbicie niedoboru / Rozchód';
							|tr = 'Eksikliğin / Gider yazmanın yansıtılması'");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.RecordShortageOnCashCollection;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Phản ánh thiếu hụt / Chi';
													|ru = 'Отражение недостачи / Списание';
													|en = 'Cash shortage recognition / Write-off'; fa = 'شناسایی کسری نقد / اسقاط';
													|it = 'Registrazione carenza / Cancellazione';
													|pl = 'Odbicie niedoboru / Rozchód';
													|tr = 'Eksikliğin / Gider yazmanın yansıtılması'"));
	
	//
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField("BusinessOperation");
	Item.Presentation = NStr("vi = 'Phản ánh thừa';
							|ru = 'Отражение излишка';
							|en = 'Overage recognition'; fa = 'شناسایی مازاد';
							|it = 'Registrazione surplus';
							|pl = 'Odzwierciedlenie nadwyżki';
							|tr = 'Fazlalığın yansıtılması'");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.RecordSurplusDuringCashCollection;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Phản ánh thừa';
													|ru = 'Отражение излишка';
													|en = 'Overage recognition'; fa = 'شناسایی مازاد';
													|it = 'Registrazione surplus';
													|pl = 'Odzwierciedlenie nadwyżki';
													|tr = 'Fazlalığın yansıtılması'"));
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "DiscrepanciesOnCashCollection.Date", Items.Date.Name);
	
EndProcedure

&AtServer
Procedure EstablishConnectionsOfBankAccountSelectionParameters()
	
	ParametersArray = New Array;
	If ValueIsFilled(Organization) Then
		ParametersArray.Add(New ChoiceParameterLink("Filter.Owner", "Organization"));
	Else
		BankAccount = Undefined;
	EndIf;
	Items.BankAccountSelection.ChoiceParameterLinks = New FixedArray(ParametersArray);
	
EndProcedure

&AtServer
Procedure SetDynamicListSelection()
	
	CompaniesList = New ValueList;
	CompaniesList.Add(Organization);
	
	If ValueIsFilled(Organization)
		And GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
		
		Query = New Query("SELECT
		|	Companies.Ref
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	Companies.BranchOffice
		|	AND Companies.ParentCompany = &Organization
		|	AND Companies.TransactionsUsingParentCompanyAreAllowed");
		Query.SetParameter("Organization", Organization);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			CompaniesList.Add(Selection.Ref);
		EndDo;
	EndIf;
	
	For Each DynamicList In ArrayOfDynamicLists() Do
		CommonClientServer.SetDynamicListFilterItem(
			DynamicList,
			"Organization",
			CompaniesList,
			DataCompositionComparisonType.InList,
			,
			ValueIsFilled(Organization));
			
		CommonClientServer.SetDynamicListFilterItem(
			DynamicList,
			"BankAccount",
			BankAccount,
			DataCompositionComparisonType.InHierarchy,
			,
			ValueIsFilled(BankAccount));
	EndDo;
	
	SetSelectionByPeriod();
	
EndProcedure

&AtClient
Procedure UpdateDynamicLists()
	
	Items.CashInTransit.Refresh();
	
EndProcedure

&AtServer
Function ArrayOfDynamicLists()

	ArrayOfLists = New Array;
	ArrayOfLists.Add(DiscrepanciesOnCashCollection);
	ArrayOfLists.Add(CashInTransit);
	
	Return ArrayOfLists;

EndFunction

#EndRegion
