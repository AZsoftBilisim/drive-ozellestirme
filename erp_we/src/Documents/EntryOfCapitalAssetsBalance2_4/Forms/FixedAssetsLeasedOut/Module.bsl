
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	InitializationDuringCreationOnServer();
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	#Region StandardSubsystems
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	#EndRegion
	
	sh_ShamsiInit(); // sh_ShamsiInit
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

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting And Not DataOnTraceableGoodsIsCorrect() Then
		Cancel = True;	
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_EntryOfCapitalAssetsBalance2_4", WriteParameters, Object.Ref);
	Notify("Write_OBEntry", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	RefreshFormTitle();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	ConfigureDependentFormElementsOnServer(Item.Name);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ConfigureDependentFormElementsOnServer(Item.Name);
	
EndProcedure

&AtClient
Procedure RecordInOperationalAccountingOnChange(Item)
	
	ConfigureDependentFormElementsOnServer(Item.Name);
	
EndProcedure

&AtClient
Procedure PostInFinancialAndTaxAccountingOnChange(Item)
	
	ConfigureDependentFormElementsOnServer(Item.Name);
	
EndProcedure

&AtClient
Procedure RecordInMAOnChange(Item)
	
	ConfigureDependentFormElementsOnServer(Item.Name);
	
EndProcedure

&AtClient
Procedure PostInAccountingOnChange(Item)
	
	Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;

	ConfigureDependentFormElementsOnServer("RecordInLocalAccounting,PostInAccounting");

EndProcedure

&AtClient
Procedure RecordInTAOnChange(Item)
	
	Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;

	ConfigureDependentFormElementsOnServer("RecordInLocalAccounting,RecordInTA");

EndProcedure

&AtClient
Procedure RecordInManAccountingOnChange(Item)
	
	ConfigureDependentFormElementsOnServer("RecordInManAccounting");

EndProcedure

&AtClient
Procedure LeaseholderIntercompanyARAPOnChange(Item)
	
	ConfigureDependentFormElementsOnServer("LeaseholderIntercompanyARAP");
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	ConfigureDependentFormElementsOnServer(Item.Name);
	
EndProcedure

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
#EndRegion

#Region FormTableItemsEventHandlers

&AtClient
Procedure FASelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	ChangeFAString();
	
EndProcedure

&AtClient
Procedure FABeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	ChangeFAString(True, Copy);
	
EndProcedure

&AtClient
Procedure FABeforeRowChange(Item, Cancel)
	
	If Item.CurrentItem <> Items.StringBaseNumber Then
		Cancel = True;
		ChangeFAString();
	EndIf; 
	
EndProcedure

&AtClient
Procedure FAChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	SelectionOnServer(ValueSelected);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure ChangeInformation(Command)
	
	ChangeFAString();
	
EndProcedure

&AtClient
Procedure Pick(Command)
	
	FASelectionParameters = TMCommonUseClientServer.PickingParameters(Items.FAFixedAsset, ThisObject);
	
	OpenForm("Catalog.Assets.ChoiceForm", 
					FASelectionParameters, Items.FA,,,,, 
					FormWindowOpeningMode.LockOwnerWindow)
	
EndProcedure

&AtClient
Procedure Attachable_OnExecuteCommand(Command)

	EntryOfCapitalAssetsBalanceClientLocalization.FormLeasedFixedAssets_WhenExecutingCommand_(Command, ThisForm);

EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

#Region AttachableCommands

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

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()

	StartDateOfCapitalAssetsAccounting24 = NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24();
	
	RefreshFormTitle();
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure InitializationDuringCreationOnServer()

	If Parameters.Property("ActivateLine") Then
		ActivateLine = Parameters.ActivateLine;
		If ActivateLine <= Object.FA.Count() And ActivateLine > 0 Then
			Items.GroupPages.CurrentPage = Items.OSPage;
			Items.FA.CurrentRow = ActivateLine - 1;
		EndIf; 
	EndIf; 
	
	AttributesList = New Array;
	For Each AttributeMetadata In Metadata.Documents.EntryOfCapitalAssetsBalance2_4.TabularSections.FA.Attributes Do
		AttributesList.Add(AttributeMetadata.Name);
	EndDo; 

	FAAttributes = StrConcat(AttributesList, ",");
	
	If GetFunctionalOption("UseTraceableImportedGoodsAccounting") Then
		Items.TraceableGoodsFixedAsset.ChoiceList.LoadValues(AvailableFixedAssets());	
		AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, 
			Items.TraceableGoodsCCDNumber.Name, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure RefreshFormTitle()
	
	Title = NonCurrentAssetsServerCall.PresentationOfInputBalances(Object);

EndProcedure

&AtClient
Procedure ChangeFAString(NewRow = False, Copy = False)
	
	CurrentData = Items.FA.CurrentData;
	If CurrentData = Undefined And Not Copy And Not NewRow Then
		Return;
	EndIf; 

	FormParameters = New Structure;
	FormParameters.Insert("Ref", Object.Ref);
	FormParameters.Insert("Date", Object.Date);
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("FixedAssetsLocation", Object.FixedAssetsLocation);
	FormParameters.Insert("RentalContract", Object.RentalContract);
	FormParameters.Insert("RecordInLocalAccounting", Object.RecordInLocalAccounting);
	FormParameters.Insert("RecordInManAccounting", Object.RecordInManAccounting);
	FormParameters.Insert("PostInAccounting", Object.PostInAccounting);
	FormParameters.Insert("RecordInTA", Object.RecordInTA);
	FormParameters.Insert("PostInFinancialAndTaxAccounting", Object.PostInFinancialAndTaxAccounting);
	FormParameters.Insert("RecordInOperationalAccounting", Object.RecordInOperationalAccounting);
	FormParameters.Insert("RecordInMA", Object.RecordInMA);
	FormParameters.Insert("BusinessOperation", Object.BusinessOperation);
	FormParameters.Insert("LeaseholderIntercompanyARAP", Object.LeaseholderIntercompanyARAP);
	FormParameters.Insert("AttributesToSave", FAAttributes);
	FormParameters.Insert("NewRow", NewRow);
	FormParameters.Insert("Copy", Copy);
	FormParameters.Insert("ReadOnly", ReadOnly);
	
	RowID = Undefined;
	If CurrentData <> Undefined Then
		RowID = CurrentData.GetID();
		If Not NewRow Or Copy Then
			AttributesValues = New Structure(FAAttributes);
			FillPropertyValues(AttributesValues, CurrentData);
			FormParameters.Insert("AttributesValues", AttributesValues);
		EndIf; 
		If Copy Then
			AttributesValues.FixedAsset = Undefined;
		EndIf;
	EndIf;
	
	AddlParameters = New Structure("NewRow,RowID", NewRow, RowID);
	CallbackDescription = New CallbackDescription("ChangeFAStringCompletion", ThisObject, AddlParameters);
	OpenForm("Document.EntryOfCapitalAssetsBalance2_4.Form.InformationAboutFixedAsset", FormParameters,,,,,CallbackDescription);

EndProcedure

&AtClient
Procedure ChangeFAStringCompletion(ClosingResult, AdditionalParameters) Export

	If TypeOf(ClosingResult) = Type("Structure") Then
		ChangeFACompletionLineOnServer(ClosingResult, AdditionalParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure ChangeFACompletionLineOnServer(Val ClosingResult, Val AdditionalParameters)
	
	Modified = True;

	If AdditionalParameters.NewRow Then
		TableRow = Object.FA.Add();
	Else
		TableRow = Object.FA.FindByID(AdditionalParameters.RowID);
	EndIf;
	
	FillPropertyValues(TableRow, ClosingResult);
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(Val ChangedBankingDetails = "")

	OnChangeAttributes(ChangedBankingDetails);
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If UpdateAll Then
	
		Items.PictureDocumentOfMigrationTo24.Visible = False;
		Items.DecorationForSwitchingTo24.Visible = False;
		Items.EnterBalanceBy.Visible = False;
		
		Items.LeaseholderIntercompanyARAP.ReadOnly = Not GetFunctionalOption("UseMultipleCompanies");
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplianceCAAccountingIsKept",
			NonCurrentAssetsInternal.ComplianceCAAccountingIsKept(),
			FormServiceParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then

		AccountingForTraceableGoodsLocalization.SetVisibilityOfTraceableGoodsPage(ThisObject, Object.Date);

	EndIf;
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		NonCurrentAssets.SetParametersOfFunctionalOptionsOfObjectForm(
			ThisObject, Object.Organization, EndOfMonth(Object.Date) + 1);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"LeaseAccountingAccordingToFSB25_2018IsUsed",
			LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Object.Organization, Object.Date),
			FormServiceParameters);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"FALocalAccountingIsConductedIndependently",
			AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()))),
			FormServiceParameters);
			
		Items.LeaseholderIntercompanyARAP.Visible = Not FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed;
			
		//	
		Items.PostInAccounting.Visible = FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.RecordInTA.Visible = FormServiceParameters.ComplianceCAAccountingIsKept;
		Items.RecordInManAccounting.Visible = FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.DecorationIsReflectionOption.Visible = Items.PostInAccounting.Visible Or Items.RecordInManAccounting.Visible;
	
		If Not FormServiceParameters.FALocalAccountingIsConductedIndependently 
			And Not UpdateAll Then
			
			Object.RecordInLocalAccounting = True;
			Object.RecordInManAccounting = True;
			Object.PostInAccounting = True;
			Object.RecordInTA = False;
			
		EndIf;

	EndIf;
	
	If StructureOfChangedProps.Property("RecordInOperationalAccounting")
		Or StructureOfChangedProps.Property("PostInFinancialAndTaxAccounting")
		Or StructureOfChangedProps.Property("RecordInMA")
		Or UpdateAll Then
		
		PropertyValue = 
			Not Object.RecordInOperationalAccounting
			And (Object.RecordInMA Or Object.PostInFinancialAndTaxAccounting);
			
		Items.PostInAccounting.ReadOnly = PropertyValue;
		Items.RecordInTA.ReadOnly = PropertyValue;
		Items.RecordInManAccounting.ReadOnly = PropertyValue;
		
		//
		FASelectionOptions = New Array;
		
		FilterState = New Array;
		If Object.RecordInOperationalAccounting Then
			FilterState.Add(Enums.FixedAssetsStates.NotRecognized_);
			FilterState.Add(Enums.FixedAssetsStates.TakenOffBooks);
		Else
			FilterState.Add(Enums.FixedAssetsStates.Recognized_);
		EndIf; 
		FASelectionOptions.Add(New ChoiceParameter("Filter.State", FilterState));
		FASelectionOptions.Add(New ChoiceParameter("Context", "ACC,MA"));
		
		Items.FAFixedAsset.ChoiceParameters = New FixedArray(FASelectionOptions);
		
	EndIf; 
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"LeaseAccountingAccordingToFSB25_2018IsUsed",
			LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Object.Organization, Object.Date),
			FormServiceParameters);
			
		If FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed Then
			Object.LeaseholderIntercompanyARAP = False;
		EndIf;
		
	EndIf;
	
	If StructureOfChangedProps.Property("LeaseholderIntercompanyARAP") 
		Or UpdateAll Then
		
		SetUpTenantAgreement();
		
	EndIf;
	
	SetUpTenantAgreement();
	
	EntryOfCapitalAssetsBalanceLocalization.FormLeasedFixedAssets_ConfigureDependentElementsOfForm(
		ThisForm, StructureOfChangedProps);
	
EndProcedure

&AtServer
Procedure SetUpTenantAgreement()
	
	// Leasing to a tenant-organization is possible only if FSB 25/2018 is disabled in the accounting policy of the organization.
	
	Items.LeaseholderIntercompanyARAP.Visible = Not FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed;
	
	// Leasing of the OS between organizations.
	//   The visibility of the contract field depends on the functional option to use agreements between organizations.
	//   The type of the Tenant Organization field.
	//   The type of the Agreement field is the Agreement between organizations.
	If Object.LeaseholderIntercompanyARAP Then
		FunctionalOptionName = "UseIntercompanyContracts";
		TypeOfTenantField = New TypeDescription("CatalogRef.Companies");
		TypeOfContractField   = New TypeDescription("CatalogRef.IntercompanyContracts");
		CommunicationOrganization = New ChoiceParameterLink("Filter.Organization", "Object.Organization");
		ContactCounterparty  = New ChoiceParameterLink("Filter.CompanyRecipient", "Object.Counterparty");
		
	// Leasing between an organization and a counterparty.
	//   The visibility of the contract field depends on the functional option to use the contract by customers.
	//   The type of the Tenant Counterparty field.
	//   The type of the field is the Contract of the contractors.
	Else
		FunctionalOptionName = "UseCustomerContracts";
		TypeOfTenantField = New TypeDescription("CatalogRef.Counterparties");
		TypeOfContractField   = New TypeDescription("CatalogRef.CounterpartyContracts");
		CommunicationOrganization = New ChoiceParameterLink("Filter.Organization", "Object.Organization");
		ContactCounterparty  = New ChoiceParameterLink("Filter.Counterparty", "Object.Counterparty");
	EndIf;
	
	ContractSelectionParameters_ = New Array();
	ContractSelectionParameters_.Add(CommunicationOrganization);
	ContractSelectionParameters_.Add(ContactCounterparty);
	
	ContractParameters = New Array();
	ContractParameters.Add(New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid));
	ContractParameters.Add(New ChoiceParameter("Filter.DeletionMark",False));
	
	Items.Contract.Visible = GetFunctionalOption(FunctionalOptionName);
	
	Items.Leaseholder.TypeRestriction = TypeOfTenantField;
	Items.Contract.TypeRestriction   = TypeOfContractField;
	
	Items.Contract.ChoiceParameterLinks = New FixedArray(ContractSelectionParameters_);
	
	// Prohibition on leasing to the same organization.
	If Object.LeaseholderIntercompanyARAP Then
		TenantSelectionParameters = New Array();
		TenantSelectionParameters.Add(New ChoiceParameter("DoNotSelectOrganization", Object.Organization));
		Items.Leaseholder.ChoiceParameters = New FixedArray(TenantSelectionParameters);
	EndIf;
	
	
EndProcedure

&AtServer
Procedure OnChangeAttributes(ChangedBankingDetails)

	If Not ValueIsFilled(ChangedBankingDetails) Then
		Return; 
	EndIf; 
	
	AttributesList = StrSplit(ChangedBankingDetails, ",");
	
	If AttributesList.Find("RecordInOperationalAccounting") <> Undefined
		Or AttributesList.Find("PostInFinancialAndTaxAccounting") <> Undefined
		Or AttributesList.Find("RecordInMA") <> Undefined Then
		
		If Object.RecordInOperationalAccounting
			And Not Object.RecordInLocalAccounting
			And Not Object.RecordInManAccounting Then
				
			Object.RecordInLocalAccounting = True;
			Object.RecordInManAccounting = True;
			Object.PostInAccounting = True;
			Object.RecordInTA = FormServiceParameters.ComplianceCAAccountingIsKept;
			
			AttributesList.Add("RecordInLocalAccounting,PostInAccounting,RecordInTA,RecordInManAccounting");

		ElsIf Not Object.RecordInOperationalAccounting
			And Object.PostInFinancialAndTaxAccounting
			And Not Object.RecordInMA Then
				
			Object.RecordInLocalAccounting = True;
			Object.PostInAccounting = True;
			Object.RecordInTA = FormServiceParameters.ComplianceCAAccountingIsKept;
			Object.RecordInManAccounting = False;
			
			AttributesList.Add("RecordInLocalAccounting,PostInAccounting,RecordInTA,RecordInManAccounting");

		ElsIf Not Object.RecordInOperationalAccounting
			And Object.RecordInMA
			And Not Object.PostInFinancialAndTaxAccounting Then
				
			Object.RecordInLocalAccounting = False;
			Object.PostInAccounting = False;
			Object.RecordInTA = False;
			Object.RecordInManAccounting = True;
			
			AttributesList.Add("RecordInLocalAccounting,PostInAccounting,RecordInTA,RecordInManAccounting");

		ElsIf Not Object.RecordInOperationalAccounting
			And Object.RecordInMA
			And Object.PostInFinancialAndTaxAccounting Then
				
			Object.RecordInLocalAccounting = True;
			Object.PostInAccounting = True;
			Object.RecordInTA = True;
			Object.RecordInManAccounting = True;
			
			AttributesList.Add("RecordInLocalAccounting,PostInAccounting,RecordInTA,RecordInManAccounting");

		EndIf;
		
	EndIf; 
	
	If AttributesList.Find("Date") <> Undefined
		Or AttributesList.Find("Organization") <> Undefined
		Or AttributesList.Find("RentalContract") <> Undefined
		Or AttributesList.Find("PostInFinancialAndTaxAccounting") <> Undefined
		Or AttributesList.Find("RecordInOperationalAccounting") <> Undefined
		Or AttributesList.Find("RecordInMA") <> Undefined
		Or AttributesList.Find("RecordInLocalAccounting") <> Undefined
		Or AttributesList.Find("RecordInManAccounting") <> Undefined Then
		
		FillInDetailsDependingOnProperties(Object.FA);
	EndIf; 
	
	If AttributesList.Find("Organization") <> Undefined
		Or AttributesList.Find("Date") <> Undefined Then
		
		If Not FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed
			And Object.LeaseholderIntercompanyARAP Then
			Object.Counterparty = PredefinedValue("Catalog.Counterparties.EmptyRef");
			Object.LeaseholderIntercompanyARAP = False;
			AttributesList.Add("LeaseholderIntercompanyARAP");
		EndIf;
		
	EndIf;
	
	ChangedBankingDetails = StrConcat(AttributesList, ",");

EndProcedure

&AtServer
Procedure FillInDetailsDependingOnProperties(StringsList)

	AuxiliaryDetailsOfObject = Documents.EntryOfCapitalAssetsBalance2_4.AuxiliaryAttributes(Object, False);
	
	For Each RowData In StringsList Do
		
		AuxiliaryAttributes = Documents.EntryOfCapitalAssetsBalance2_4.AddAuxiliaryDetailsBasedOnLineData(
											Object, RowData, AuxiliaryDetailsOfObject);
		
		ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_EnteringBalances(
										RowData, AuxiliaryAttributes, "");
										
		Documents.EntryOfCapitalAssetsBalance2_4.FillInDetailsDependingOnProperties(
				RowData, AuxiliaryAttributes, ItemDetailsParameters);
				
		TMCommonUseClientServer.ClearUnusedProps(RowData, ItemDetailsParameters);
		
		Documents.EntryOfCapitalAssetsBalance2_4.FillInDefaultValues(RowData, Object);
		
	EndDo; 

EndProcedure

&AtServer
Procedure SelectionOnServer(ValueSelected)

	AddedRows = NonCurrentAssetsClientServer.ProcessingElementSelection(Object.FA, "FixedAsset", ValueSelected);

	AuxiliaryDetailsOfObject = Documents.EntryOfCapitalAssetsBalance2_4.AuxiliaryAttributes(Object, False);
	
	For Each RowData In AddedRows Do
		
		AuxiliaryAttributes = Documents.EntryOfCapitalAssetsBalance2_4.AddAuxiliaryDetailsBasedOnLineData(
										Object, RowData, AuxiliaryDetailsOfObject);
		
		ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_EnteringBalances(
										RowData, AuxiliaryAttributes, "");
										
		Documents.EntryOfCapitalAssetsBalance2_4.FillInDetailsDependingOnProperties(
				RowData, AuxiliaryAttributes, ItemDetailsParameters);
				
	EndDo; 
	
EndProcedure

&AtClient
Procedure ContinueRunningLocalizationCommand(CommandName, NotificationParameters) Export
	
	If NotificationParameters.ServerCallRequired_ Then
		WhenExecutingEndCommandOnServer(CommandName, NotificationParameters.ProcessingParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenExecutingEndCommandOnServer(Val CommandName, Val AdditionalParameters)
	
	EntryOfCapitalAssetsBalanceLocalization.FormLeasedFixedAssets_WhenExecutingCommand_(CommandName, ThisObject);
	
EndProcedure

&AtServer
Function AvailableFixedAssets()
	
	AvailableFixedAssets = Object.FA.Unload(,"FixedAsset").UnloadColumn("FixedAsset");
	
	Return AvailableFixedAssets;
	
EndFunction

&AtClient
Function DataOnTraceableGoodsIsCorrect()
	
	DataCorrect = True;
	FixedAssets = AvailableFixedAssets();
	For Each Page1 In Object.TraceableGoods Do
		If FixedAssets.Find(Page1.FixedAsset) = Undefined Then
			MessageString = NStr("vi = 'Dữ liệu phần bảng hàng hóa được truy xuất nguồn gốc không tương ứng với dữ liệu về tài sản cố định. 
			|Giá trị %1 không có trong phần bảng ""Tài sản cố định"".';
			|ru = 'Данные табличной части прослеживаемых товаров не соответствуют данным об основных средствах. 
			|Значение %1 отсутствует в табличной части ""Основные средства"".';
			|en = 'Data of the traceable goods table does not correspond to the data of fixed assets. 
			|The %1 value is missing in the ""Fixed assets"" table.'; fa = 'Data of the traceable goods table does not correspond to the data of fixed assets. 
			|The %1 value is missing in the ""Fixed assets"" table.';
			|it = 'I dati della parte tabellare degli articoli tracciabili non corrispondono ai dati sulle immobilizzazioni. 
			|Il valore %1 manca nella parte tabellare ""Immobilizzazioni"".';
			|pl = 'Dane sekcji tabelarycznej towarów identyfikowalnych nie są zgodne z danymi o środkach trwałych. 
			|Brak wartości %1 w sekcji tabelarycznej ""Środki trwałe"".';
			|tr = 'İzlenebilir mallar tablosundaki veriler sabit kıymetlerdeki verilerle uyuşmuyor. 
			|""Sabit kıymetler"" tablo bölümünde %1 değeri eksik.'"); 
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, Page1.FixedAsset);
			CommonClient.MessageToUser(MessageString,Object.Ref);
			DataCorrect = False;	
		EndIf;	
	EndDo;

	Return DataCorrect;

EndFunction

&AtServer
Procedure FAIsPrimaryMeansWhenChangingOnServer()
	If GetFunctionalOption("UseTraceableImportedGoodsAccounting") Then
		Items.TraceableGoodsFixedAsset.ChoiceList.LoadValues(AvailableFixedAssets());
	EndIf;
EndProcedure

&AtClient
Procedure FAFixedAssetOnChange(Item)
	FAIsPrimaryMeansWhenChangingOnServer();
EndProcedure

&AtClient
Procedure GenerateStatement(Command)
	
	AvailableFixedAssets = AvailableFixedAssets();
	Filter = New Structure;
    Filter.Insert("Organization", Object.Organization);   
	Filter.Insert("FixedAsset", AvailableFixedAssets);
	ReportPeriod = New StandardPeriod();
	ReportPeriod.StartDate = BegOfDay(Object.Date);
	ReportPeriod.EndDate = EndOfDay(Object.Date);
 	Filter.Insert("Period", ReportPeriod);		
	FormParameters = New Structure("Filter, GenerateOnOpen, VariantKey", Filter, True, "Main");	
	AccountingForTraceableGoodsClientLocalization.GenerateStatement(FormParameters);
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
		
	If CurrentPage = Items.GroupPages.ChildItems.TraceableProductsPage Then
		Items.TraceableGoodsFixedAsset.ChoiceList.LoadValues(AvailableFixedAssets());
	EndIf;
	
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
