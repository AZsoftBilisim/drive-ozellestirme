#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
		
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	If Not ValueIsFilled(Object.ParentCompany) Then
		Object.ParentCompany = 
					SettingsValueCached.GetDefaultOrganization(Object.ParentCompany);
	EndIf;				
	
	CatalogsSalaryAndPersonnelServer.EmployeesWhenCreatingAtServerElementForm(ThisObject, Cancel, StandardProcessing);
	
	Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.ParentCompany);
		
	VisibilityManagement();   
	
	If Object.Ref.IsEmpty() Then
		
		InitializeElement();
		
	EndIf;	
	
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
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ReadFullNameHistory();
	
	SetHyperlinkPropertiesForFullNameHistory(Object, Items, FullNameRecordSetIndividuals.Count());
	
	CatalogsSalaryAndPersonnelServer.EmployeesWhenReadingATServer(ThisObject, CurrentObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	If EventName = "EditedHistory" And Parameter.RegisterName = "FullNameOfPersons"
	 And Source = Object.Individual Then
		
		FullNameRecordSetIndividuals.Clear();
		If Parameters.Property("RecordsArray") Then
			For Each CurrRow In Parameter.RecordsArray Do
				FillPropertyValues(FullNameRecordSetIndividuals.Add(), CurrRow);
			EndDo;
		Else
			For Each CurrRow In Parameter.RecordSet Do
				FillPropertyValues(FullNameRecordSetIndividuals.Add(), CurrRow);
			EndDo;
		EndIf;	
		
		If FullNameRecordSetIndividuals.Count() > 0 Then
			
			LatestRecord = FullNameRecordSetIndividuals[FullNameRecordSetIndividuals.Count() - 1];
			NewDescription = 
				LatestRecord.LastName 
				+ ?(ValueIsFilled(LatestRecord.Name), " ", "") + LatestRecord.Name 
				+ ?(ValueIsFilled(LatestRecord.MiddleName), " ", "") + LatestRecord.MiddleName;
				
			Individual.LastFirstName = NewDescription;
			FillPropertyValues(Individual, LatestRecord);
			If Object.Description <> NewDescription Then
				Modified = True; 

				CatalogsSalaryAndPersonnelClient.OnChangingEmployeeSFullName(ThisObject);  
                ItIsNecessaryToRecordDataOfPerson = True;
			EndIf;
			
		EndIf;
		
		SetHyperlinkPropertiesForFullNameHistory(Object, Items, FullNameRecordSetIndividuals.Count());
		
	ElsIf EventName = "PersonalDataChanged" And Parameter.RegisterName = "FullNameOfPersons"
	 And Source = Object.Individual Then
		
		Read();
		
	EndIf;
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	CatalogsSalaryAndPersonnelClient.EmployeesBeforeWritingItemForm(ThisObject, Cancel);
	
	PerformanceMonitorClient.TimeMeasurement("EntryOfEmployeesDirectoryItem");
	
	If Not Cancel And ItIsNecessaryToRecordDataOfPerson
		And Not Object.Ref.IsEmpty()
		And CatalogsSalaryAndPersonnelClient.BlockPersonWhenEditing(ThisObject) Then 
		
		ToReFillInDataOfPerson();
		ItIsNecessaryToRecordDataOfPerson = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	RecordingNewEmployee = Object.Ref.IsEmpty();
	
	If RecordingNewEmployee Then    
			
			If Not Common.RefExists(Object.Individual) Then
				IndividualObject = Catalogs.Persons.CreateItem();
				FillPropertyValues(IndividualObject, Individual);
				IndividualObject.Write();                            
				
				CurrentObject.Individual = IndividualObject.Ref;
			EndIf;
			
	EndIf;
	
	CatalogsSalaryAndPersonnelServer.EmployeesBeforeWritingItemFormAtServer(ThisObject, Cancel);
	
	// Handler of the "Properties" subsystem.
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	RecordNameChanges();
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	SetHyperlinkPropertiesForFullNameHistory(Object, Items, FullNameRecordSetIndividuals.Count());
	
EndProcedure


&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PhysicalPersonDateOfBirthOnChange(Item)
	
	ItIsNecessaryToRecordDataOfPerson = True; 
	
EndProcedure

&AtClient
Procedure IndividualINNOnChange(Item)
	
	ItIsNecessaryToRecordDataOfPerson = True; 

EndProcedure

&AtClient
Procedure IndividualPersonGenderOnChange(Item)
	
	ItIsNecessaryToRecordDataOfPerson = True; 
	
EndProcedure

&AtClient
Procedure LastFirstNameOnChange(Item)
	
	CatalogsSalaryAndPersonnelClient.OnChangingEmployeeSFullName(ThisObject);
	If Not ValueIsFilled(Individual.LastFirstName) Then
		Individual.LastFirstName = Object.Description; 
		Individual.Description = Individual.LastFirstName;
	EndIf;	
	
	FillInFullNameByName();
	
EndProcedure

&AtClient
Procedure IndividualStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;

	AdditionalParameters = New Structure;
	
	Notification = New CallbackDescription(
		"IndividualStartChoiceCompletion",
		ThisObject,
		AdditionalParameters);
	
	FormParameters = New Structure;
	OpenForm("Catalog.Persons.ChoiceForm", FormParameters, Item,,,,Notification);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CommandSaveAndClose(Command)
	
	Write();
	Close();
	
EndProcedure

&AtClient
Procedure CommandWrite(Command)
	
	Write();
	
EndProcedure

&AtClient
Procedure PersonalData(Command)
	
	If Not ValueIsFilled(Object.Ref)
		Or Modified Then
		
		QueryText = NStr("vi = 'Chưa ghi lại nhân viên.
							|Ghi lại nhân viên?';
							|ru = 'Сотрудник еще не записан.
							|Записать сотрудника?';
							|en = 'The employee is not saved yet.
							|Save and continue?'; fa = 'The employee is not saved yet.
							|Save and continue?';
							|it = 'The employee is not saved yet.
							|Save and continue?';
							|pl = 'The employee is not saved yet.
							|Save and continue?';
							|tr = 'Çalışan henüz kaydedilmedi.
							|Çalışan kaydedilsin mi?'");
			
		ShowQueryBox(New CallbackDescription("EmployeesObjectIsNotRecordedEnd", ThisObject),
			QueryText,
			QuestionDialogMode.YesNo);
		
	Else
		
		OpenFormPersonalDataInternational();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FullNameOfPersonsHistory(Command)
	
	FormParameters = New Structure();
	FormParameters.Insert("LeadingObject", Object.Individual);		
	FormParameters.Insert("Individual", Object.Individual);		
	FormParameters.Insert("RecordsArray", FullNameRecordSetIndividuals);		
	FormParameters.Insert("RecordSet", FullNameRecordSetIndividuals);		
					
	OpenForm("InformationRegister.FullNameOfPersons.Form.EditHistory", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure Documents(Command)
			
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Person", Object.Individual);
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("Filter", FilterStructure1);
	FormOpenParameters.Insert("ReadOnly", ReadOnly);
	FormOpenParameters.Insert("FromThePersonalDataEditingForm", True);
	FormOpenParameters.Insert("CloseOnOwnerClose", True);
	
	OpenForm("InformationRegister.DocumentsPersons.Form.DocumentsPerson", FormOpenParameters, ThisObject);
			
EndProcedure

&AtClient
Procedure PersonnelDocuments(Command)
	FilterParameters = New Structure;
	FilterParameters.Insert("Employee", Object.Ref);
	FormParameters = New Structure("Filter", FilterParameters);
	OpenForm("DocumentJournal.PersonnelDocumentsHR.ListForm", FormParameters, , , , );
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure IndividualStartChoiceCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Object.Individual = Result; 
	ItIsNecessaryToRecordDataOfPerson = True;
	IndividualOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure InitializeElement()

	If Parameters.Property("ChoiceParameters")
		And Parameters.ChoiceParameters.Property("Organization")
		And ValueIsFilled(Parameters.ChoiceParameters.Organization) Then
			
		Object.ParentCompany = Parameters.ChoiceParameters.Organization;
		
	Else
		
		Object.ParentCompany = SettingsValueCached.GetDefaultOrganization(Object.ParentCompany);
		
	EndIf;
	
EndProcedure	
	
&AtServer
Procedure VisibilityManagement()
	
	Items.ParentCompany.Visible = GetFunctionalOption("UseMultipleCompanies");	
	
EndProcedure

&AtClient
Procedure AccrualsAndDeductions(Command)

	FormParameters = New Structure("Employee", Object.Ref);
	OpenForm("Catalog.EmployeesHR.Form.CompensationPlan", FormParameters, , , , );	
	
EndProcedure

&AtServer
Procedure RecordNameChanges()
	
	RegisterRecordSet = FormAttributeToValue("FullNameRecordSetIndividuals");
	
	RegisterRecordSet.Filter.Individual.Set(Object.Individual);
	For Each CurrRow In RegisterRecordSet Do
		CurrRow.Individual = Object.Individual;
	EndDo;
	
	// This flag indicates that you don't need to create a full name based on the case section
	RegisterRecordSet.AdditionalProperties.Insert("DonTFormName");
	
	RegisterRecordSet.Write(True);
	
EndProcedure

&AtServer
Procedure FillInFullNameByName()
	Var LatestRecord;
	
	RecordDate = BegOfDay(CurrentSessionDate());
	LastFirstName = PersonsTM.FullName(Individual.LastFirstName);
	
	If FullNameRecordSetIndividuals.Count() > 0 Then
		
		LatestRecord = FullNameRecordSetIndividuals[FullNameRecordSetIndividuals.Count() - 1];
		
		If BegOfDay(LatestRecord.Period) < RecordDate
		 And (LatestRecord.LastName <> LastFirstName.LastName
		 	Or LatestRecord.Name <> LastFirstName.Name
			Or LatestRecord.MiddleName <> LastFirstName.MiddleName) Then
			LatestRecord = Undefined; // create a new one
		EndIf;
		
	Else
		
		RecordDate = ?(ValueIsFilled(Individual.BirthDate), Individual.BirthDate, RecordDate);
		
	EndIf;
	
	If LatestRecord = Undefined Then
		
		LatestRecord = FullNameRecordSetIndividuals.Add();
		LatestRecord.Period = RecordDate;
		
		SetHyperlinkPropertiesForFullNameHistory(Object, Items, FullNameRecordSetIndividuals.Count());
		
	EndIf;
	
	FillPropertyValues(LatestRecord, LastFirstName);
	
EndProcedure

&AtServer
Procedure ReadFullNameHistory()
	
	Query = New Query;
	Query.SetParameter("Individual", Object.Individual);
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

 &AtClient
Procedure EmployeesObjectIsNotRecordedEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		Write();  

		If ValueIsFilled(Object.Ref) Then
			OpenFormPersonalDataInternational();    
		EndIf;	
	EndIf;
	
EndProcedure   

&AtClient
Procedure OpenFormPersonalDataInternational()
	
	FormParameters = New Structure("Individual", Object.Individual);
	OpenForm("Catalog.EmployeesHR.Form.PersonalDataInt", FormParameters, , 
			, , );
			
EndProcedure	

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context,  Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtServer
Procedure IndividualOnChangeAtServer() Export
	
	CatalogsSalaryAndPersonnelServer.EmployeesWhenCreatingAtServer(ThisObject, False, False);
	
EndProcedure

&AtServer
Function BlockObjectInOwnerForm() Export
	
	Return True;
	
EndFunction

&AtServer
Procedure ToReFillInDataOfPerson() Export
	
	IndividualObject = Object.Individual.GetObject();

	FillPropertyValues(IndividualObject, Individual, "BirthDate,TIN,Gender,Description,LASTFIRSTNAME,LastName,Name,MiddleName,Initials");
	IndividualObject.Write();
	
EndProcedure	

#Region Properties

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

#EndRegion

&AtClientAtServerNoContext
Procedure SetHyperlinkPropertiesForFullNameHistory(Object, Items, RecordsCount)
	
	If RecordsCount > 0 Then
		Title =	StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Lịch sử họ tên đầy đủ (%1)';
				|ru = 'История ФИО (%1)';
				|en = 'Full name history (%1)'; fa = 'Full name history (%1)';
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
	
	Items.FullNameOfPersonsHistory.Title = Title;
	Items.FullNameOfPersonsHistory.Enabled = ValueIsFilled(Object.Ref);
	
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
