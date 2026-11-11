
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
	
	#Region UniversalMechanisms
	
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

	#EndRegion
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
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
	
	Notify("Write_OBEntrySubAssetsAndComponentsOfDepreciation", WriteParameters, Object.Ref);
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
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfChangeOnServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
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
Procedure RecordInLocalAccountingOnChange(Item)
	
	ConfigureDependentFormElementsOnServer("RecordInLocalAccounting");

EndProcedure

&AtClient
Procedure RecordInManAccountingOnChange(Item)
	
	ConfigureDependentFormElementsOnServer("RecordInManAccounting");

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFA

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

#Region AttachableCommands

&AtClient
Procedure Attachable_OnExecuteCommand(Command)

	OBEntrySubAssetsAndComponentsOfDepreciationClientLocalization.FormFixedAssets_WhenExecutingCommand(Command, ThisObject);

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

// StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()

	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure InitializationDuringCreationOnServer()

	AttributesList = New Array;
	For Each AttributeMetadata In Metadata.Documents.OBEntrySubAssetsAndComponentsOfDepreciation.TabularSections.FA.Attributes Do
		AttributesList.Add(AttributeMetadata.Name);
	EndDo; 

	FAAttributes = StrConcat(AttributesList, ",");
		
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
	FormParameters.Insert("RecordInLocalAccounting", Object.RecordInLocalAccounting);
	FormParameters.Insert("RecordInManAccounting", Object.RecordInManAccounting);
	FormParameters.Insert("PostInAccounting", Object.RecordInLocalAccounting);
	FormParameters.Insert("RecordInTA", False);
	FormParameters.Insert("PostInFinancialAndTaxAccounting", Object.PostInFinancialAndTaxAccounting);
	FormParameters.Insert("RecordInOperationalAccounting", Object.RecordInOperationalAccounting);
	FormParameters.Insert("RecordInMA", Object.RecordInMA);
	FormParameters.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.OBEntrySubAssetsAndComponentsOfDepreciation"));
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
	OpenForm("Document.OBEntrySubAssetsAndComponentsOfDepreciation.Form.EditLine", FormParameters,,,,, CallbackDescription);

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
		
		Items.EnterBalanceBy.Visible = False;
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplianceCAAccountingIsKept",
			NonCurrentAssetsInternal.ComplianceCAAccountingIsKept(),
			FormServiceParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInOperationalAccounting")
		Or UpdateAll Then
			
		Items.PictureInformation.Visible = Object.RecordInOperationalAccounting;
		Items.InscriptionBasement.Visible = Object.RecordInOperationalAccounting;
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInOperationalAccounting")
		Or StructureOfChangedProps.Property("PostInFinancialAndTaxAccounting")
		Or StructureOfChangedProps.Property("RecordInMA")
		Or UpdateAll Then
		
		PropertyValue = 
			Not Object.RecordInOperationalAccounting
			And (Object.RecordInMA Or Object.PostInFinancialAndTaxAccounting);
			
		Items.RecordInLocalAccounting.ReadOnly = PropertyValue;
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
		
		FATypes = New Array;
		FATypes.Add(Enums.FATypes.DepreciationComponent);
		FATypes.Add(Enums.FATypes.Node);
		FASelectionOptions.Add(New ChoiceParameter("Filter.OSType", FATypes));
		
		Items.FAFixedAsset.ChoiceParameters = New FixedArray(FASelectionOptions);
		
	EndIf; 
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"FALocalAccountingIsConductedIndependently",
			AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()))),
			FormServiceParameters);
		
		//	
		Items.RecordInLocalAccounting.Visible = FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.RecordInManAccounting.Visible = FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.DecorationIsReflectionOption.Visible = Items.RecordInLocalAccounting.Visible Or Items.RecordInManAccounting.Visible;
	
		If Not FormServiceParameters.FALocalAccountingIsConductedIndependently 
			And Not UpdateAll Then

			Object.RecordInLocalAccounting = True;
			Object.RecordInManAccounting = True;
		EndIf;
		
		//
		ParentCompany = AccountingPoliciesTaxSettingsCached.ParentCompany(Object.Organization);
		SetFormFunctionalOptionParameters(New Structure("Organization", ParentCompany));
		
	EndIf;
	
	OBEntrySubAssetsAndComponentsOfDepreciationLocalization.FormAssets_ConfigureDependentFormElements(
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
			
			AttributesList.Add("RecordInLocalAccounting,RecordInManAccounting");

		ElsIf Not Object.RecordInOperationalAccounting
			And Object.PostInFinancialAndTaxAccounting
			And Not Object.RecordInMA Then
				
			Object.RecordInLocalAccounting = True;
			Object.RecordInManAccounting = False;
			
			AttributesList.Add("RecordInLocalAccounting,RecordInManAccounting");

		ElsIf Not Object.RecordInOperationalAccounting
			And Object.RecordInMA
			And Not Object.PostInFinancialAndTaxAccounting Then
				
			Object.RecordInLocalAccounting = False;
			Object.RecordInManAccounting = True;
			
			AttributesList.Add("RecordInLocalAccounting,RecordInManAccounting");

		ElsIf Not Object.RecordInOperationalAccounting
			And Object.RecordInMA
			And Object.PostInFinancialAndTaxAccounting Then
				
			Object.RecordInLocalAccounting = True;
			Object.RecordInManAccounting = True;
			
			AttributesList.Add("RecordInLocalAccounting,RecordInManAccounting");

		EndIf;
	
	EndIf; 
		
	If AttributesList.Find("Date") <> Undefined
		Or AttributesList.Find("Organization") <> Undefined
		Or AttributesList.Find("PostInFinancialAndTaxAccounting") <> Undefined
		Or AttributesList.Find("RecordInOperationalAccounting") <> Undefined
		Or AttributesList.Find("RecordInMA") <> Undefined
		Or AttributesList.Find("RecordInLocalAccounting") <> Undefined
		Or AttributesList.Find("RecordInManAccounting") <> Undefined Then
		
		FillInDetailsDependingOnProperties(Object.FA);
	EndIf; 
	
	ChangedBankingDetails = StrConcat(AttributesList, ",");

EndProcedure
 
&AtServer
Procedure SelectionOnServer(ValueSelected)

	AddedRows = NonCurrentAssetsClientServer.ProcessingElementSelection(Object.FA, "FixedAsset", ValueSelected);
	
	FillInDetailsDependingOnProperties(AddedRows);
	
EndProcedure

&AtServer
Procedure FillInDetailsDependingOnProperties(StringsList)

	AuxiliaryAttributes = Documents.OBEntrySubAssetsAndComponentsOfDepreciation.AuxiliaryAttributes(Object, False);
	
	For Each RowData In StringsList Do
		
		ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_OBEntry_NodesComponents(
										RowData, AuxiliaryAttributes, "");
										
		Documents.OBEntrySubAssetsAndComponentsOfDepreciation.FillInDetailsDependingOnProperties(
				RowData, AuxiliaryAttributes, ItemDetailsParameters);
				
		TMCommonUseClientServer.ClearUnusedProps(RowData, ItemDetailsParameters);
		
		Documents.OBEntrySubAssetsAndComponentsOfDepreciation.FillInDefaultValues(RowData, Object);
		
	EndDo; 

EndProcedure

&AtServer
Procedure DateOfChangeOnServer()

	ConfigureDependentFormElementsOnServer("Date");

EndProcedure
 
&AtServer
Procedure OrganizationWhenChangedOnServer()

	ConfigureDependentFormElementsOnServer("Organization");
	
EndProcedure

&AtClient
Procedure ContinueRunningLocalizationCommand(CommandName, NotificationParameters) Export
	
	If NotificationParameters.ServerCallRequired_ Then
		WhenExecutingEndCommandOnServer(CommandName, NotificationParameters.ProcessingParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenExecutingEndCommandOnServer(Val CommandName, Val AdditionalParameters)
	
	OBEntrySubAssetsAndComponentsOfDepreciationLocalization.FormFixedAssets_WhenExecutingCommand(CommandName, ThisObject);
	
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
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
