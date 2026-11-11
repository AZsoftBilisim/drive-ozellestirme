
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	Items.Organization.Visible = Object.Operation <> Enums.RegisterAdjustmentOperations.ManualAdjustment;
	Items.ToOpenTheLedgerSelection.Enabled = Object.Operation = Enums.RegisterAdjustmentOperations.ManualAdjustment;
	
	ShowRegisters();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

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
	
	CurrentObject.AdditionalProperties.Insert("WritingDocumentFromForm", True);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FoundRows = Object.RegistersTable.FindRows(
		New Structure("Name", "AccumulationRegister.InventoryAndDemands"));
	If FoundRows.Count() > 0 Then
		ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	EndIf;
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
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
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

#EndRegion

#Region EventHandlers

// A plug-in handler for the "first Edit" event for the form table.
//
&AtClient
Procedure Attachable_TableAtBeginningOfEditing(Item, NewRow, Copy)

	If NewRow Then
		Item.CurrentData.Period = Object.Date;
		FillPropertyValues(Item.CurrentData, New Structure("Organization", Organization));
	EndIf;

EndProcedure

#Region CommandHandlers

&AtClient
Procedure SelectRegisters(Command)

	ListOfUsedRegisters = New ValueList;

	For Each String In Object.RegistersTable Do
		ListOfUsedRegisters.Add(String.Name);
	EndDo;

	OpenForm("Document.RegisterAdjustment.Form.RegisterChoiceForm",
		New Structure("ListOfUsedRegisters", ListOfUsedRegisters),,,,, 
		New CallbackDescription("SelectRegistersCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure SelectRegistersCompletion(Result, AdditionalParameters) Export
    
    If TypeOf(Result) = Type("ValueList") Then
        
        HandleChangingRegisters(Result);
        
    EndIf;

EndProcedure

#EndRegion

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

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	TMCommonUseClient.WriteAndClose(ThisForm);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function CreatePage(PageName, Var_Title, Parent)

	NewItem = Items.Add(PageName, Type("FormGroup"), Parent);
	NewItem.Type                      = FormGroupType.Page;
	NewItem.Title                = Var_Title;
	NewItem.VerticalStretch   = True;
	NewItem.HorizontalStretch = True;

	Return NewItem;

EndFunction

&AtServer
Function GetRegisterPageName(RegisterName)

	Return "Page" + RegisterName;

EndFunction

&AtServer
Procedure DeleteRegisterPage(RegisterName)

	Items.Delete(Items.Find(GetRegisterPageName(RegisterName)));

EndProcedure

&AtServer
Function CreateSelectionParameterRelationships(SourceArray, DataPath)

	NewArray = New Array;
	For Each Item In SourceArray Do

		NewArray.Add(New ChoiceParameterLink(Item.Name, DataPath + "." + Item.DataPath, Item.ValueChange));

	EndDo;
	
	Return New FixedArray(NewArray);

EndFunction

&AtServer
// The procedure creates a form table.
//
Function CreateRegisterFormTable(RegisterName, TableColumns1, Parent)

	FormTable = Items.Add("RegisterRecordTable" + RegisterName, Type("FormTable"), Parent);
	FormTable.DataPath      = "Object.RegisterRecords." + RegisterName;
	Parent.TitleDataPath = FormTable.DataPath + ".RowsCount";

	ArrayOfAddedFields = New Array;
	For Each CurArrayElement In TableColumns1 Do

		Column = CurArrayElement; // FormField
	
		FormField = Items.Add(FormTable.Name + Column.Name, Type("FormField"), FormTable);
		FormField.DataPath           = FormTable.DataPath + "." + Column.Name;
		FormField.Title             = Column.Title;
		FormField.Type                   = FormFieldType.InputField;

		ArrayOfAddedFields.Add(FormField);

	EndDo;

	Counter = 0;
	For Each FormField In ArrayOfAddedFields Do

		If TableColumns1[Counter].ChoiceParameterLinks <> Undefined And  TableColumns1[Counter].ChoiceParameterLinks.Count() > 0 Then

			FormField.ChoiceParameterLinks = CreateSelectionParameterRelationships(TableColumns1[Counter].ChoiceParameterLinks,
									 "Items." + FormTable.Name + ".CurrentData");
		EndIf;

		Counter = Counter + 1;
	
	EndDo;

	Return FormTable;

EndFunction

&AtServer
// The function creates a table of values by case.
//
Function CreateArrayOfRegisterFields(RegisterManager, RegisterMetadata)

	RegisterTable = RegisterManager.CreateRecordSet().UnloadColumns(); // ValueTable
	RegisterTable.Columns.Delete("Recorder");
	If RegisterTable.Columns.Find("PointInTime") <> Undefined Then
		RegisterTable.Columns.Delete("PointInTime");
	EndIf;

	ColumnsArray1 = New Array;
	For Each Column In RegisterTable.Columns Do

		ColumnInformation = New Structure("Name, Title, ChoiceParameterLinks",
				Column.Name);

		ColumnsArray1.Add(ColumnInformation);

	EndDo;

	// Updating table column headers by synonyms of register fields.
	ArrayOfRegisterFields = New Array;
	ArrayOfRegisterFields.Add("Dimensions");
	ArrayOfRegisterFields.Add("Resources");
	ArrayOfRegisterFields.Add("Attributes");

	For Each FieldKind In ArrayOfRegisterFields Do
		For Each Field In RegisterMetadata[FieldKind] Do
			For Each CurArrayElement In ColumnsArray1 Do
				ArrayElement = CurArrayElement; // FormField

				If ArrayElement.Name = Field.Name Then

					ArrayElement.Title             = Field.Synonym;
					ArrayElement.ChoiceParameterLinks = Field.ChoiceParameterLinks;

				EndIf;

			EndDo;
		EndDo;
	EndDo;

	Return ColumnsArray1;

EndFunction

&AtServer
// The procedure controls the creation of a table on the form for the register.
//
Procedure ShowRegisterTableOnPage(Val TSRow)

	If Metadata.AccumulationRegisters.Find(TSRow.Name) <> Undefined Then

		RegisterPage      = Items.AccumulationRegistersSetting;
		RegisterManager      = AccumulationRegisters[TSRow.Name];
		RegisterMetadata    = Metadata.AccumulationRegisters[TSRow.Name];
		RegisterHasPeriodField= True;

	ElsIf Metadata.InformationRegisters.Find(TSRow.Name) <> Undefined Then

		RegisterPage      = Items.InformationRegistersSetting;
		RegisterManager      = InformationRegisters[TSRow.Name];
		RegisterMetadata    = Metadata.InformationRegisters[TSRow.Name];

		RegisterHasPeriodField = RegisterMetadata.InformationRegisterPeriodicity 
									<> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical;

	Else

		Return;

	EndIf;

	ColumnsArray1 = CreateArrayOfRegisterFields(RegisterManager, RegisterMetadata);

	PageForRegister = CreatePage(GetRegisterPageName(TSRow.Name),
				RegisterMetadata.Synonym,
				RegisterPage);

	FormTable = CreateRegisterFormTable(TSRow.Name, ColumnsArray1, PageForRegister);

	If RegisterHasPeriodField Then
		FormTable.SetAction("OnStartEdit", "Attachable_TableAtBeginningOfEditing");
	EndIf;

EndProcedure

&AtServer
Procedure ShowRegisters()

	For Each TabRow In Object.RegistersTable Do

		ShowRegisterTableOnPage(TabRow);

	EndDo;

EndProcedure

&AtServer
// The procedure is used to include/exclude registers from the list of editable ones.
//
Procedure HandleChangingRegisters(RegistersList)

	For Each Item In RegistersList Do

		// You need to add a new register.
		If Item.Check Then

			TSRow = Object.RegistersTable.Add();
			TSRow.Name = Item.Value;

			ShowRegisterTableOnPage(TSRow);

		Else

			For Each String In Object.RegistersTable.FindRows(New Structure("Name", Item.Value)) Do
				Object.RegistersTable.Delete(String);
			EndDo;

			Object.RegisterRecords[Item.Value].Clear();
			DeleteRegisterPage(Item.Value);

		EndIf;

	EndDo;

	Modified = True;

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
