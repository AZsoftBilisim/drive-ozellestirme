
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	HasRightToAddPartners = AccessRight("Insert", Metadata.FindByFullName("Catalog.Partners"));
	HasRightToAddAgreement = AccessRight("Insert", Metadata.FindByFullName("Catalog.TermsOfSale"));
	HasRightRightToAddTermsOfService = AccessRight("Insert", Metadata.FindByFullName("Catalog.TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives"));
	
	SetTaskListParameters();

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Supervisor_ = Settings.Get("Supervisor_");
	SalesRepresentative = Settings.Get("SalesRepresentative");
	JobPreparationPeriod = Settings.Get("JobPreparationPeriod");
	SetTaskListParameters();
	
	CommonClientServer.SetDynamicListFilterItem(JobsList, "SalesRepresentative", SalesRepresentative, DataCompositionComparisonType.Equal,, ValueIsFilled(SalesRepresentative));
	CommonClientServer.SetDynamicListFilterItem(JobsList, "Supervisor_", Supervisor_, DataCompositionComparisonType.Equal,, ValueIsFilled(Supervisor_));

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_JobForSalesRepresentative" Then
		Items.JobsList.Refresh();
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure JobPreparationPeriodOnChange(Item)
	
	JobsList.Parameters.SetParameterValue("StartDate_3",JobPreparationPeriod.StartDate);
	JobsList.Parameters.SetParameterValue("InitialPlanningDate", Max(BegOfDay(CurrentServerDate()), JobPreparationPeriod.StartDate));
	JobsList.Parameters.SetParameterValue("PlanningEndDate", JobPreparationPeriod.EndDate);
	
	Items.JobsList.Refresh();

EndProcedure

&AtClient
Procedure SalesRepresentativeOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(JobsList, "SalesRepresentative", SalesRepresentative, DataCompositionComparisonType.Equal,, ValueIsFilled(SalesRepresentative));

EndProcedure

&AtClient
Procedure Supervisor_OnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(JobsList, "Supervisor_", Supervisor_, DataCompositionComparisonType.Equal,, ValueIsFilled(Supervisor_));

EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure JobsListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Item.CurrentItem = Items.JobsListJobForSalesRepresentative Then
		
		FormParameters = New Structure();
		
		If Items.JobsList.CurrentData.JobForSalesRepresentative.IsEmpty() Then
			FillingValues = New Structure();
			FillingValues.Insert("Partner", Items.JobsList.CurrentData.Partner);
			FillingValues.Insert("ServiceTerms", Items.JobsList.CurrentData.ServiceTerms);
			
			FormParameters.Insert("FillingValues",FillingValues);
		Else	
			FormParameters.Insert("Key",Items.JobsList.CurrentData.JobForSalesRepresentative);
		EndIf;
		
		OpenTaskFormForSalesRepresentative(FormParameters);
		
	ElsIf Item.CurrentItem = Items.JobsListPartner Then
		
		FormParameters = New Structure();
		If ValueIsFilled(Items.JobsList.CurrentData.Partner) Then
			FormParameters.Insert("Key",Items.JobsList.CurrentData.Partner);
		EndIf;
			
		If HasRightToAddPartners Or ValueIsFilled(Items.JobsList.CurrentData.Partner) Then
			OpenForm("Catalog.Partners.ObjectForm", FormParameters, Items.JobsListPartner);
		EndIf;
		
	ElsIf Item.CurrentItem = Items.JobsListTerms Then
		
		FormParameters = New Structure();
		If ValueIsFilled(Items.JobsList.CurrentData.Terms) Then
			FormParameters.Insert("Key",Items.JobsList.CurrentData.Terms);
		EndIf;
			
		If HasRightToAddAgreement Or ValueIsFilled(Items.JobsList.CurrentData.Terms) Then
			OpenForm("Catalog.TermsOfSale.ObjectForm", FormParameters, Items.JobsListTerms);
		EndIf;
		
	ElsIf Item.CurrentItem = Items.JobsListServiceTerms Then
		
		FormParameters = New Structure();
		If ValueIsFilled(Items.JobsList.CurrentData.ServiceTerms) Then
			FormParameters.Insert("Key",Items.JobsList.CurrentData.ServiceTerms);
		EndIf;
			
		If HasRightRightToAddTermsOfService 
				Or ValueIsFilled(Items.JobsList.CurrentData.ServiceTerms) Then
			OpenForm("Catalog.TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives.ObjectForm", FormParameters, Items.JobsListServiceTerms);
		EndIf;
		
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AddJob(Command)

	FormParameters = New Structure();
	OpenTaskFormForSalesRepresentative(FormParameters);

EndProcedure

&AtClient
Procedure ConfigureJobTemplatePrinting(Command)

	OpenForm("Document.JobForSalesRepresentative.Form.ConfigureJobTemplatePrinting");

EndProcedure

&AtClient
Procedure PrintJobTemplate(Command)
	
	ObjectsArray = PrintJobs_();
	
	If ObjectsArray.Count() = 0 Then
		MessageText = NStr("vi = 'Chưa chọn nhiệm vụ để in';
							|ru = 'Не выбраны задания для печати';
							|en = 'Tasks to print are not selected'; fa = 'Tasks to print are not selected';
							|it = 'Nessun lavoro di stampa selezionato';
							|pl = 'Nie wybrano zadań do drukowania';
							|tr = 'Yazdırma için görev seçilmedi'");
		ShowMessageBox(Undefined, MessageText);
		Return;
	EndIf;
	
	PrintParameters = New Structure();
	PrintManagementClient.ExecutePrintCommand("Document.JobForSalesRepresentative",
													"JobTemplate,OrderTemplate",
													ObjectsArray,
													Undefined,
													PrintParameters);

EndProcedure

&AtClient
Procedure PrintSummaryJob(Command)
	
	ObjectsArray = PrintJobs_();
	
	If ObjectsArray.Count() = 0 Then
		MessageText = NStr("vi = 'Chưa chọn nhiệm vụ để in';
							|ru = 'Не выбраны задания для печати';
							|en = 'Tasks to print are not selected'; fa = 'Tasks to print are not selected';
							|it = 'Nessun lavoro di stampa selezionato';
							|pl = 'Nie wybrano zadań do drukowania';
							|tr = 'Yazdırma için görev seçilmedi'");
		ShowMessageBox(Undefined, MessageText);
		Return;
	EndIf;
	
	PrintParameters = New Structure();
	PrintManagementClient.ExecutePrintCommand("Document.JobForSalesRepresentative",
													"SummaryJob",
													ObjectsArray,
													Undefined,
													PrintParameters);

EndProcedure
												
&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.JobsListJobForSalesRepresentative.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("JobsList.JobForSalesRepresentative");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Tạo nhiệm vụ>';
													|ru = '<Создать задание>';
													|en = '<Create a job>'; fa = '<Create a job>';
													|it = '<Creare un task>';
													|pl = '<Utwórz zadanie>';
													|tr = '<görev oluştur>'"));

EndProcedure

&AtClient
Procedure OpenTaskFormForSalesRepresentative(FormParameters = Undefined)

	OpenForm("Document.JobForSalesRepresentative.ObjectForm", FormParameters, Items.JobsList);

EndProcedure

&AtClient
Function PrintJobs_()
	
	ObjectsArray = New Array();
	
	For Each RowID In Items.JobsList.SelectedRows Do
		Job = Items.JobsList.RowData(RowID).JobForSalesRepresentative;
		If ValueIsFilled(Job) Then
			ObjectsArray.Add(Job);
		EndIf;
	EndDo;
	
	Return ObjectsArray;

EndFunction

&AtServer
Procedure SetTaskListParameters()
	
	JobsList.Parameters.SetParameterValue("StartDate_3",JobPreparationPeriod.StartDate);
	JobsList.Parameters.SetParameterValue("InitialPlanningDate", Max(BegOfDay(CurrentSessionDate()), JobPreparationPeriod.StartDate));
	JobsList.Parameters.SetParameterValue("PlanningEndDate", JobPreparationPeriod.EndDate);
	JobsList.Parameters.SetParameterValue("DateEmpty",DateEmpty);
	
	JobsList.Parameters.SetParameterValue("Monday",Enums.WeekDays.Monday);
	JobsList.Parameters.SetParameterValue("Tuesday",Enums.WeekDays.Tuesday);
	JobsList.Parameters.SetParameterValue("Wednesday",Enums.WeekDays.Wednesday);
	JobsList.Parameters.SetParameterValue("Thursday",Enums.WeekDays.Thursday);
	JobsList.Parameters.SetParameterValue("Friday",Enums.WeekDays.Friday);
	JobsList.Parameters.SetParameterValue("Saturday",Enums.WeekDays.Saturday);
	JobsList.Parameters.SetParameterValue("Sunday",Enums.WeekDays.Sunday);

EndProcedure

&AtServerNoContext
Function CurrentServerDate()
	
	Return CurrentSessionDate();
	
EndFunction

#EndRegion
