
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("Partner") Then
		Partner = Parameters.Partner;
	EndIf;
	
	SetAgreementSelectionParameters();

	FillInSchedule();
	SetFieldAvailability();
	
	TimeList = TMCommonUseClientServer.TimeList();
	
	For Each ListItem In TimeList Do
		Items.VisitScheduleBeginTime.ChoiceList.Add(ListItem.Value, ListItem.Presentation);
		Items.VisitScheduleEndTime.ChoiceList.Add(ListItem.Value, ListItem.Presentation);
	EndDo;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ChangeTheNameOnChange(Item)
	
	Items.Description.Enabled = ChangeTheName;
	
	If Not ChangeTheName And ValueIsFilled(Description) Then
		Description = "";
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeSupervisorOnChange(Item)
	
	Items.Supervisor_.Enabled = ChangeSupervisor;
	
	If Not ChangeSupervisor And ValueIsFilled(Supervisor_) Then
		Supervisor_ = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeAgreementOnChange(Item)
	
	Items.Terms.Enabled = ChangeAgreement;
	
	If Not ChangeAgreement And ValueIsFilled(Terms) Then
		Terms = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeSalesRepresentativeOnChange(Item)
	
	Items.SalesRepresentative.Enabled = ChangeSalesRepresentative;
	
	If Not ChangeSalesRepresentative And ValueIsFilled(SalesRepresentative) Then
		SalesRepresentative = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeCommentOnChange(Item)
	
	Items.Comment.Enabled = ChangeComment;
	
	If Not ChangeComment And ValueIsFilled(Comment) Then
		Comment = "";
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeVisitScheduleOnChange(Item)
	
	Items.VisitSchedule.Enabled = ChangeVisitSchedule;
	Items.CaptionVisitSchedule.Enabled = ChangeVisitSchedule;
	
	If Not ChangeVisitSchedule Then
		
		For Each PlotLine In VisitSchedule Do
			PlotLine.Visit = False;
			PlotLine.BeginTime = '00010101000000';
			PlotLine.EndTime = '00010101000000';
		EndDo;
		
	EndIf;
	
	Items.VisitSchedule.Refresh();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	
	StructureOfServiceParameters = New Structure;
	
	If ChangeTheName Then
		StructureOfServiceParameters.Insert("Description", Description);
	EndIf;
	
	If ChangeSupervisor Then
		StructureOfServiceParameters.Insert("Supervisor_", Supervisor_);
	EndIf;
	
	If ChangeAgreement Then
		StructureOfServiceParameters.Insert("Terms", Terms);
	EndIf;
	
	If ChangeSalesRepresentative Then
		StructureOfServiceParameters.Insert("SalesRepresentative", SalesRepresentative);
	EndIf;
	
	If ChangeComment Then
		StructureOfServiceParameters.Insert("Comment", Comment);
	EndIf;
	
	If ChangeVisitSchedule Then
		
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
		
	EndIf;
	
	If StructureOfServiceParameters.Count() = 0 Then
		MessageText = NStr("vi = 'Chưa chỉ ra các điều kiện phục vụ đã thay đổi';
							|ru = 'Не указаны изменяемые условия обслуживания';
							|en = 'Changed service conditions are not specified'; fa = 'Changed service conditions are not specified';
							|it = 'Non sono indicati i termine di servizio modificabili';
							|pl = 'Nie wskazano zmienianych warunków obsługi';
							|tr = 'Değiştirilmiş hizmet hüküm ve koşulları belirtilmemiş'");
		CommonClientServer.MessageToUser(MessageText);
		Return;
	EndIf;
	
	Close(StructureOfServiceParameters);
	
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
		CommonClientServer.MessageToUser(MessageText);
		Return;
	EndIf;
	
	OpenForm("Catalog.TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives.Form.SpecifyTime",,,,,, 
			New CallbackDescription("SetTimeForAllDaysOfTheWeekCompletion", ThisObject), 
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

&AtServer
Procedure SetFieldAvailability()
	
	Items.Description.Enabled = ChangeTheName;
	Items.Supervisor_.Enabled = ChangeSupervisor;
	Items.Terms.Enabled = ChangeAgreement;
	Items.SalesRepresentative.Enabled = ChangeSalesRepresentative;
	Items.Comment.Enabled = ChangeComment;
	Items.VisitSchedule.Enabled = ChangeVisitSchedule;
	Items.CaptionVisitSchedule.Enabled = ChangeVisitSchedule;
	
EndProcedure

&AtServer
Procedure SetAgreementSelectionParameters()
	
	Array = New Array();
	
	If ValueIsFilled(Partner) Then
		ChoiceParameter = New ChoiceParameter("Partner", Partner);
		Array.Add(ChoiceParameter);
	Else
		
		ChoiceParameter = New ChoiceParameter("OnlyStandard", True);
		Array.Add(ChoiceParameter);
	EndIf;
	
	ChoiceParameter = New ChoiceParameter("OnlyUsedBySalesRepresentative", True);
	Array.Add(ChoiceParameter);
	
	ChoiceParameter = 
		New ChoiceParameter("Filter.Status", PredefinedValue("Enum.StatusesOfTermsOfSales.Valid"));
	Array.Add(ChoiceParameter);
		
	SelectionParametersForField = New FixedArray(Array);
	Items.Terms.ChoiceParameters = SelectionParametersForField;
	
EndProcedure

#EndRegion
