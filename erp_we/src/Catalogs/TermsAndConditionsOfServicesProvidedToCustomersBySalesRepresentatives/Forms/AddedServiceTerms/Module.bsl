
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	FillInSchedule();
	
	If Parameters.Property("BusinessRegion") Then
		BusinessRegion = Parameters.BusinessRegion;
	EndIf;
	
	If Not ValueIsFilled(BusinessRegion) Then
		Items.PartnersPartner.ChoiceParameterLinks = New FixedArray(New Array);
	EndIf;
	
	TimeList = TMCommonUseClientServer.TimeList();
	
	For Each ListItem In TimeList Do
		Items.VisitScheduleBeginTime.ChoiceList.Add(ListItem.Value, ListItem.Presentation);
		Items.VisitScheduleEndTime.ChoiceList.Add(ListItem.Value, ListItem.Presentation);
	EndDo;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	For Each TableRow In Partners Do
		
		If Not ValueIsFilled(TableRow.Partner) Then
			MessageText = NStr("vi = 'Chưa điền trường Khách hàng';
								|ru = 'Не заполнено поле Клиент';
								|en = '""Customer"" is required'; fa = '""Customer"" is required';
								|it = 'Il campo Cliente non è compilato';
								|pl = 'Nie wypełniono pola Klient';
								|tr = '""Müşteri"" alanı doldurulmamış'");
			
			Field = "Partners[%IndexOf%].Partner";
			Field = StrReplace(Field, "%IndexOf%", Partners.IndexOf(TableRow));
			
			CommonClientServer.MessageToUser(MessageText,, Field);
			Cancel = True;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Partners.Count()>1 Then
		
		ParametersArray = New Array;
		For Each ChoiceParameter  In Items.Terms.ChoiceParameters Do
			ParametersArray.Add(ChoiceParameter);
		EndDo;
		
		ParametersArray.Add(New ChoiceParameter("Filter.Standard_", True));
		Items.Terms.ChoiceParameters = New FixedArray(ParametersArray);
		
	Else
		
		ParametersArray = New Array;
		For Each ChoiceParameter  In Items.Terms.ChoiceParameters Do
			If ChoiceParameter.Name <> "Filter.Standard_" Then
				ParametersArray.Add(ChoiceParameter);
			EndIf;
		EndDo;
		
		Items.Terms.ChoiceParameters = New FixedArray(ParametersArray);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPartners

&AtClient
Procedure PartnersChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	For Each Value In ValueSelected Do
		
		FilterStructure1 = New Structure("Partner", Value);
		
		If Partners.FindRows(FilterStructure1).Count()=0 Then
			NewRow = Partners.Add();
			NewRow.Partner = Value;
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	ArrayOfPartners = New Array;
	
	For Each TableRow In Partners Do
		If ArrayOfPartners.Find(TableRow.Partner) = Undefined Then
			ArrayOfPartners.Add(TableRow.Partner);
		EndIf;
	EndDo;
	
	StructureOfServiceParameters = New Structure;
	StructureOfServiceParameters.Insert("Description", Description);
	StructureOfServiceParameters.Insert("Supervisor_", Supervisor_);
	StructureOfServiceParameters.Insert("Terms", Terms);
	StructureOfServiceParameters.Insert("SalesRepresentative", SalesRepresentative);
	StructureOfServiceParameters.Insert("Comment", Comment);
	
	ArrayOfGraphLines = New Array;
	
	For Each PlotLine In VisitSchedule Do
		
		If PlotLine.Visit Then
			Structure = New Structure;
			
			Structure.Insert("WeekDay", PlotLine.WeekDay);
			Structure.Insert("BeginTime", PlotLine.BeginTime);
			Structure.Insert("EndTime", PlotLine.EndTime);
			
			ArrayOfGraphLines.Add(Structure);
		EndIf;
		
	EndDo;
	
	StructureOfServiceParameters.Insert("VisitSchedule", ArrayOfGraphLines);
	
	StructureOfData = New Structure;
	StructureOfData.Insert("Partners", ArrayOfPartners);
	StructureOfData.Insert("ServiceTerms", StructureOfServiceParameters);
	
	Close(StructureOfData);
	
EndProcedure

&AtClient
Procedure SelectPartners(Command)
	
	FormParameters = New Structure();
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("MultipleChoice", True);
	FormParameters.Insert("CloseOnChoice", False);
	
	FilterStructure1 = New Structure();
	FilterStructure1.Insert("DeletionMark", False);
	FilterStructure1.Insert("Client", True);
	FilterStructure1.Insert("Predefined", False);
	
	If ValueIsFilled(BusinessRegion) Then
		FilterStructure1.Insert("BusinessRegion", BusinessRegion);
	EndIf;
	
	FormParameters.Insert("Filter", FilterStructure1);
	
	OpenForm("Catalog.Partners.ChoiceForm", FormParameters, Items.Partners,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SetTimeForAllDaysOfTheWeek(Command)
	
	ClearMessages();
	
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
		New CallbackDescription("SetTimeForAllDaysOfTheWeekCompletion", ThisObject,), 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SetTimeForAllDaysOfTheWeekCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined And Result.DialogReturnCode = DialogReturnCode.OK Then
		For Each RowID In Items.VisitSchedule.SelectedRows Do
			Items.VisitSchedule.RowData(RowID).BeginTime = Result.BeginTime;
			Items.VisitSchedule.RowData(RowID).EndTime = Result.EndTime;
		EndDo;
	EndIf;
	
EndProcedure

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
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInSchedule()
	
	For Each WeekDay In Enums.WeekDays Do
		NewRow            = VisitSchedule.Add();
		NewRow.WeekDay = WeekDay;
	EndDo;
	
EndProcedure

#EndRegion
