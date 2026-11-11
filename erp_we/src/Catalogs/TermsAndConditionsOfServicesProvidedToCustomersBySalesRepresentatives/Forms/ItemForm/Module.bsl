
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	If Not ValueIsFilled(Object.Ref) Then
		ReadServerVisitSchedule();
	EndIf;
	
	TimeList = TMCommonUseClientServer.TimeList();
	
	For Each ListItem In TimeList Do
		Items.BeginTime.ChoiceList.Add(ListItem.Value, ListItem.Presentation);
		Items.EndTime.ChoiceList.Add(ListItem.Value, ListItem.Presentation);
	EndDo;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	ReadServerVisitSchedule();

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	RecordServerVisitSchedule(CurrentObject);

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure  AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
	
	AgreementSelectionParameters.Item                     = Item;
	AgreementSelectionParameters.Partner                     = Object.Owner;
	AgreementSelectionParameters.Document                    = Object.Terms;
	AgreementSelectionParameters.DocumentDate               = CurrentServerDate();
	AgreementSelectionParameters.OnlyUsedBySalesRepresentative = True;;
	AgreementSelectionParameters.FormDataStructure        = Object;

	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectAllDaysOfTheWeek(Command)
	
	For Each CurrentRow In VisitSchedule Do
		
		If Not CurrentRow.Visit Then
			CurrentRow.Visit = True;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearAllDaysOfTheWeek(Command)
	
	For Each CurrentRow In VisitSchedule Do
		
		If CurrentRow.Visit Then
			CurrentRow.Visit = False;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure SetTimeForAllDaysOfTheWeek(Command)
	
	If Items.VisitSchedule.SelectedRows.Count() = 0 Then
		MessageText = NStr("vi = 'Chưa chọn ngày trong tuần để chỉ ra thời gian';
							|ru = 'Не выбраны дни недели для указания времени';
							|en = 'Week days for time specification are not selected'; fa = 'Week days for time specification are not selected';
							|it = 'Non sono selezionati i giorni della settimana per indicare il tempo';
							|pl = 'Nie wybrano dni tygodnia dla wskazania czasu';
							|tr = 'Zaman göstergesi için haftanın günleri seçilmemiş'");
		ShowMessageBox(Undefined, MessageText);
		Return;
	EndIf;
	
	OpenForm("Catalog.TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives.Form.SpecifyTime",,,,,, 
					New CallbackDescription("SetTimeForAllDaysOfTheWeekCompletion", ThisObject), 
					FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SetTimeForAllDaysOfTheWeekCompletion(Result, AdditionalParameters) Export
    
	If Result <> Undefined And TypeOf(Result) = Type("Structure") Then
		If Result.DialogReturnCode = DialogReturnCode.OK Then
			For Each RowID In Items.VisitSchedule.SelectedRows Do
				Items.VisitSchedule.RowData(RowID).BeginTime = Result.BeginTime;
				Items.VisitSchedule.RowData(RowID).EndTime = Result.EndTime;
			EndDo;
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ReadServerVisitSchedule()
	
	CatalogObject = FormAttributeToValue("Object");
	
	Schedule = CatalogObject.VisitSchedule;
	
	VisitSchedule.Clear();
	
	For Each WeekDay In Enums.WeekDays Do
		
		NewRow            = VisitSchedule.Add();
		NewRow.WeekDay = WeekDay;
		TSRow               = Schedule.Find(WeekDay, "WeekDay");
		
		If TSRow <> Undefined Then
			
			NewRow.Visit       = True;
			NewRow.BeginTime     = TSRow.BeginTime;
			NewRow.EndTime  = TSRow.EndTime;
			
		EndIf;
		
	EndDo;

EndProcedure

&AtServer
Procedure RecordServerVisitSchedule(CurrentObject)
	
	CurrentObject.VisitSchedule.Clear();
	
	For Each TSRow In VisitSchedule Do
		
		If TSRow.Visit Then
			
			NewRow                 = CurrentObject.VisitSchedule.Add();
			NewRow.WeekDay      = TSRow.WeekDay;
			NewRow.BeginTime     = TSRow.BeginTime;
			NewRow.EndTime  = TSRow.EndTime;
			
		EndIf;
		
	EndDo;
		
EndProcedure

&AtServerNoContext
Function CurrentServerDate()
	
	Return CurrentSessionDate();
	
EndFunction

#EndRegion
