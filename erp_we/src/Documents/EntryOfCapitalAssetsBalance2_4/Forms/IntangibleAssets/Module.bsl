
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
	NonCurrentAssetsClient.NotifyAboutEntryOfDocumentInJournalOfIA();
	
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
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ConfigureDependentFormElementsOnServer(Item.Name);
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
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

#Region FormTableItemsEventHandlersIA

&AtClient
Procedure IASelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	ChangeIAString();
	
EndProcedure

&AtClient
Procedure IABeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	ChangeIAString(True, Copy);
	
EndProcedure

&AtClient
Procedure IABeforeRowChange(Item, Cancel)
	
	If Item.CurrentItem <> Items.NmanumberOfTheString Then
		Cancel = True;
		ChangeIAString();
	EndIf;
	
EndProcedure

&AtClient
Procedure IAChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
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
	
	ChangeIAString();
	
EndProcedure

&AtClient
Procedure Pick(Command)
	
	IASelectionParameters_ = TMCommonUseClientServer.PickingParameters(Items.IAIntangibleAsset, ThisObject);
	
	OpenForm("Catalog.IntangibleAssets.ChoiceForm", 
					IASelectionParameters_, Items.IA,,,,, 
					FormWindowOpeningMode.LockOwnerWindow)
	
EndProcedure

&AtClient
Procedure Attachable_OnExecuteCommand(Command)

	EntryOfCapitalAssetsBalanceClientLocalization.FormIntangibleAssets_WhenExecutingCommand(Command, ThisForm);

EndProcedure

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

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()

	RefreshFormTitle();
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure InitializationDuringCreationOnServer()

	If Parameters.Property("ActivateLine") Then
		ActivateLine = Parameters.ActivateLine;
		If ActivateLine <= Object.IA.Count() And ActivateLine > 0 Then
			Items.GroupPages.CurrentPage = Items.NMAPage;
			Items.IA.CurrentRow = ActivateLine - 1;
		EndIf;
	EndIf; 
	
	AttributesList = New Array;
	For Each AttributeMetadata In Metadata.Documents.EntryOfCapitalAssetsBalance2_4.TabularSections.IA.Attributes Do
		AttributesList.Add(AttributeMetadata.Name);
	EndDo; 

	IAAttributes = StrConcat(AttributesList, ",");
	
EndProcedure

&AtServer
Procedure RefreshFormTitle()
	
	Title = NonCurrentAssetsServerCall.PresentationOfInputBalances(Object);

EndProcedure

&AtClient
Procedure ChangeIAString(NewRow = False, Copy = False)
	
	CurrentData = Items.IA.CurrentData;
	If CurrentData = Undefined And Not Copy And Not NewRow Then
		Return;
	EndIf; 

	FormParameters = New Structure;
	FormParameters.Insert("Ref", Object.Ref);
	FormParameters.Insert("Date", Object.Date);
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("FixedAssetsLocation", Object.FixedAssetsLocation);
	FormParameters.Insert("RecordInLocalAccounting", Object.RecordInLocalAccounting);
	FormParameters.Insert("RecordInManAccounting", Object.RecordInManAccounting);
	FormParameters.Insert("PostInFinancialAndTaxAccounting", Object.PostInFinancialAndTaxAccounting);
	FormParameters.Insert("RecordInOperationalAccounting", Object.RecordInOperationalAccounting);
	FormParameters.Insert("RecordInMA", Object.RecordInMA);
	FormParameters.Insert("PostInAccounting", Object.PostInAccounting);
	FormParameters.Insert("RecordInTA", Object.RecordInTA);
	FormParameters.Insert("BusinessOperation", Object.BusinessOperation);
	FormParameters.Insert("AttributesToSave", IAAttributes);
	FormParameters.Insert("NewRow", NewRow);
	FormParameters.Insert("Copy", Copy);
	FormParameters.Insert("ReadOnly", ReadOnly);
	
	RowID = Undefined;
	If CurrentData <> Undefined Then
		RowID = CurrentData.GetID();
		If Not NewRow Or Copy Then
			AttributesValues = New Structure(IAAttributes);
			FillPropertyValues(AttributesValues, CurrentData);
			FormParameters.Insert("AttributesValues", AttributesValues);
		EndIf; 
		If Copy Then
			AttributesValues.IntangibleAsset = Undefined;
		EndIf;
	EndIf;
	
	AddlParameters = New Structure("NewRow,RowID", NewRow, RowID);
	CallbackDescription = New CallbackDescription("ChangeIAStringCompletion", ThisObject, AddlParameters);
	OpenForm("Document.EntryOfCapitalAssetsBalance2_4.Form.InformationAboutIntangibleAsset", FormParameters,,,,,CallbackDescription);

EndProcedure

&AtClient
Procedure ChangeIAStringCompletion(ClosingResult, AdditionalParameters) Export

	If TypeOf(ClosingResult) <> Type("Structure") Then
		Return;
	EndIf;
	
	If AdditionalParameters.NewRow Then
		TableRow = Object.IA.Add();
	Else
		TableRow = Object.IA.FindByID(AdditionalParameters.RowID);
	EndIf;
	
	FillPropertyValues(TableRow, ClosingResult);
	Modified = True;
	
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
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplianceCAAccountingIsKept",
			NonCurrentAssetsInternal.ComplianceCAAccountingIsKept(),
			FormServiceParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"FALocalAccountingIsConductedIndependently",
			AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()))),
			FormServiceParameters);
		
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
		IASelectionParameters = New Array;
		
		FilterState = New Array;
		If Object.RecordInOperationalAccounting Then
			FilterState.Add(Enums.IntangibleAssetsStates.NotPostedInFinancialAccounting);
		Else
			FilterState.Add(Enums.IntangibleAssetsStates.PostedInFinancialAccounting);
		EndIf; 
		IASelectionParameters.Add(New ChoiceParameter("Filter.State", FilterState));
		IASelectionParameters.Add(New ChoiceParameter("Context", "ACC,MA"));
		
		Items.IAIntangibleAsset.ChoiceParameters = New FixedArray(IASelectionParameters);
		
		//
		ParentCompany = AccountingPoliciesTaxSettingsCached.ParentCompany(Object.Organization);
		SetFormFunctionalOptionParameters(New Structure("Organization", ParentCompany));
		
	EndIf; 
	
	EntryOfCapitalAssetsBalanceLocalization.FormIntangibleAssets__DependentFormElements(
		ThisObject, StructureOfChangedProps);
	
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
		Or AttributesList.Find("PostInFinancialAndTaxAccounting") <> Undefined
		Or AttributesList.Find("RecordInOperationalAccounting") <> Undefined
		Or AttributesList.Find("RecordInMA") <> Undefined
		Or AttributesList.Find("RecordInLocalAccounting") <> Undefined
		Or AttributesList.Find("RecordInManAccounting") <> Undefined Then
		
		FillInDetailsDependingOnProperties(Object.IA);
		
	EndIf;
	
	ChangedBankingDetails = StrConcat(AttributesList, ",");

EndProcedure
 
&AtServer
Procedure SelectionOnServer(ValueSelected)

	If ValueSelected.Count() = 0 Then
		Return;
	EndIf; 
	
	AddedRows = NonCurrentAssetsClientServer.ProcessingElementSelection(Object.IA, "IntangibleAsset", ValueSelected);

	TypesOfAccountingObjects = Common.ObjectsAttributeValue(ValueSelected, "KindOfAccountingObject");
	For Each RowData In AddedRows Do
		RowData.KindOfAccountingObject = TypesOfAccountingObjects.Get(RowData.IntangibleAsset);
	EndDo; 
	
	FillInDetailsDependingOnProperties(AddedRows);

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

&AtClient
Procedure ContinueRunningLocalizationCommand(CommandName, NotificationParameters) Export
	
	If NotificationParameters.ServerCallRequired_ Then
		WhenExecutingEndCommandOnServer(CommandName, NotificationParameters.ProcessingParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenExecutingEndCommandOnServer(Val CommandName, Val AdditionalParameters)
	
	EntryOfCapitalAssetsBalanceLocalization.FormIntangibleAssets_WhenExecutingCommand(CommandName, ThisObject);
	
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
