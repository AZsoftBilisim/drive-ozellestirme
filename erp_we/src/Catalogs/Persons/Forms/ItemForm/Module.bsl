
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisForm);
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.ContactInformation
	ContactsManager.OnCreateAtServer(ThisForm, Object, "ContactInformationGroup");
	// End StandardSubsystems.ContactInformation

	// Consider the possibility of creating from interaction
	Interactions.PrepareNotifications(ThisForm,Parameters,False);
	
	// StandardSubsystems.AccessManagement
	If AccessRight("Update", Metadata.Catalogs.Persons) Then
		AccessManagement.OnCreateAccessValueForm(ThisForm);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	SetHyperlinkPropertiesForFullNameHistory(Object, Items, FullNameRecordSetIndividuals.Count());
	
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
	
	// StandardSubsystems.ContactInformation
	ContactsManager.OnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.ContactInformation
	
	ReadFullNameHistory();
	
	SetHyperlinkPropertiesForFullNameHistory(Object, Items, FullNameRecordSetIndividuals.Count());
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
		
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties

	// StandardSubsystems.ContactInformation
	ContactsManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.ContactInformation
	
	If FullNameRecordSetIndividuals.Count() = 0 Then
		FillInFullNameByName();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	Catalogs.Persons.FillCheckProcessingAtServer(ThisForm, Cancel, CheckedAttributes);
	
	// StandardSubsystems.ContactInformation
	ContactsManager.FillCheckProcessingAtServer(ThisForm, Object, Cancel);
	// End StandardSubsystems.ContactInformation
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, Object);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
	EndIf;
	// End StandardSubsystems.Properties
	
	If EventName = "EditedHistory" And Parameter.RegisterName = "FullNameOfPersons"
	 And Source = Object.Ref Then
		
		FullNameRecordSetIndividuals.Clear();
		For Each CurrRow In Parameter.RecordSet Do
			FillPropertyValues(FullNameRecordSetIndividuals.Add(), CurrRow);
		EndDo;
		
		If FullNameRecordSetIndividuals.Count() > 0 Then
			
			LatestRecord = FullNameRecordSetIndividuals[FullNameRecordSetIndividuals.Count() - 1];
			NewDescription = 
				LatestRecord.LastName 
				+ ?(ValueIsFilled(LatestRecord.Name), " ", "") + LatestRecord.Name 
				+ ?(ValueIsFilled(LatestRecord.MiddleName), " ", "") + LatestRecord.MiddleName;
			
			If Object.Description <> NewDescription Then
				Object.Description = NewDescription;
				Modified = True;
			EndIf;
			
		EndIf;
		
		SetHyperlinkPropertiesForFullNameHistory(Object, Items, FullNameRecordSetIndividuals.Count());
		
	ElsIf EventName = "PersonalDataChanged" And Parameter.RegisterName = "FullNameOfPersons"
	 And Source = Object.Ref Then
		
		Read();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	InteractionsClient.ContactAfterWrite(ThisForm,Object,WriteParameters,"Persons");
	
	RecordNameChanges();
	
	SetHyperlinkPropertiesForFullNameHistory(Object, Items, FullNameRecordSetIndividuals.Count());
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DescriptionOnChange(Item)
	
	If ValueIsFilled(Object.Ref) Then
		FillInFullNameByName();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

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

// StandardSubsystems.ContactInformation
&AtClient
Procedure Attachable_ContactInformationOnChange(Item)
	ContactsManagerClient.OnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationStartChoice(Item, ChoiceData, StandardProcessing)
	ContactsManagerClient.StartChoice(ThisObject, Item, , StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationOnClick(Item, StandardProcessing)
	ContactsManagerClient.StartChoice(ThisObject, Item,, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationClearing(Item, StandardProcessing)
	ContactsManagerClient.Clearing(ThisObject, Item.Name);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationExecuteCommand(Command)
	ContactsManagerClient.ExecuteCommand(ThisObject, Command.Name);
EndProcedure

&AtServer
Procedure Attachable_UpdateContactInformation(Result) Export
	ContactsManager.UpdateContactInformation(ThisObject, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_ContactInformationAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	ContactsManagerClient.AutoCompleteAddress(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing);
	
EndProcedure

&AtClient
Procedure Attachable_ContactInformationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ContactsManagerClient.ChoiceProcessing(ThisObject, ValueSelected, Item.Name, StandardProcessing);
	
EndProcedure

// End StandardSubsystems.ContactInformation

&AtClient
Procedure FullNameHistory(Command)
	
	FormParameters = New Structure("Individual, RecordSet", Object.Ref, FullNameRecordSetIndividuals);
	OpenForm("InformationRegister.FullNameOfPersons.Form.EditHistory", FormParameters, ThisForm);
	
EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm, FormAttributeToValue("Object"));
	
EndProcedure

// End StandardSubsystems.Properties

&AtServer
Procedure ReadFullNameHistory()
	
	Query = New Query;
	Query.SetParameter("Individual", Object.Ref);
	Query.Text =
	"SELECT
	|	FullNameOfPersons.Period AS Period,
	|	FullNameOfPersons.Individual,
	|	FullNameOfPersons.LastName,
	|	FullNameOfPersons.Name,
	|	FullNameOfPersons.MiddleName
	|FROM
	|	InformationRegister.FullNameOfPersons AS FullNameOfPersons
	|WHERE
	|	FullNameOfPersons.Individual = &Individual
	|
	|ORDER BY
	|	Period";
	
	FullNameRecordSetIndividuals.Load(Query.Execute().Unload());
	
EndProcedure

&AtServer
Procedure RecordNameChanges()
	
	RegisterRecordSet = FormAttributeToValue("FullNameRecordSetIndividuals");
	
	RegisterRecordSet.Filter.Individual.Set(Object.Ref);
	For Each CurrRow In RegisterRecordSet Do
		CurrRow.Individual = Object.Ref;
	EndDo;
	
	RegisterRecordSet.AdditionalProperties.Insert("DonTFormName");
	
	RegisterRecordSet.Write(True);
	
EndProcedure

&AtServer
Procedure FillInFullNameByName()
	Var LatestRecord;
	
	RecordDate = BegOfDay(CurrentSessionDate());
	LastFirstName = PersonsTM.FullName(Object.Description);
	
	If FullNameRecordSetIndividuals.Count() > 0 Then
		
		LatestRecord = FullNameRecordSetIndividuals[FullNameRecordSetIndividuals.Count() - 1];
		
		If BegOfDay(LatestRecord.Period) < RecordDate
		 And (LatestRecord.LastName <> LastFirstName.LastName
		 	Or LatestRecord.Name <> LastFirstName.Name
			Or LatestRecord.MiddleName <> LastFirstName.MiddleName) Then
			LatestRecord = Undefined; // create a new one
		EndIf;
		
	Else
		
		RecordDate = ?(ValueIsFilled(Object.BirthDate), Object.BirthDate, RecordDate);
		
	EndIf;
	
	If LatestRecord = Undefined Then
		
		LatestRecord = FullNameRecordSetIndividuals.Add();
		LatestRecord.Period = RecordDate;
		
		SetHyperlinkPropertiesForFullNameHistory(Object, Items, FullNameRecordSetIndividuals.Count());
		
	EndIf;
	
	FillPropertyValues(LatestRecord, LastFirstName);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetHyperlinkPropertiesForFullNameHistory(Object, Items, RecordsCount)
	
	If RecordsCount > 0 Then
		Title =	StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Lịch sử họ tên đầy đủ (%1)';
				|ru = 'История ФИО (%1)';
				|en = 'History full name (%1)'; fa = 'History full name (%1)';
				|it = 'Cronologia del cognome, nome, patronimico (%1)';
				|pl = 'Historia imię i nazwisko (%1)';
				|tr = 'Tam adı geçmişi (%1)'"),
			Format(RecordsCount, "NG="));
	Else
		Title = NStr("vi = 'Lịch sử họ tên';
					|ru = 'История ФИО';
					|en = 'Full name history'; fa = 'سابقه نام کامل';
					|it = 'Cronologia del cognome, nome, patronimico ';
					|pl = 'Historia imię i nazwisko';
					|tr = 'Tam adı geçmişi'")		
	EndIf;
	
	Items.FullNameHistory.Title   = Title;
	Items.FullNameHistory.Enabled = ValueIsFilled(Object.Ref);
	
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
