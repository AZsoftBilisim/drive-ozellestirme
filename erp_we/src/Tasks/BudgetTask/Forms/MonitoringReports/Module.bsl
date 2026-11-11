#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Address = Parameters.Address;
	BudgetingModel = Parameters.BudgetingModel;
	Period = Parameters.Period;
	Periodicity = Parameters.Periodicity;
	
	OptionsParameters = New Structure("BudgetingModel", BudgetingModel);
	SetFormFunctionalOptionParameters(OptionsParameters);
	
	MonitoringReportSettings.Load(GetFromTempStorage(Address));
	For Each String In MonitoringReportSettings Do
		SelectionAvailabilityParameters = Reports.BudgetReport.SelectionAvailabilityParameters(String.BudgetProfile);
		FillPropertyValues(String, SelectionAvailabilityParameters);
	EndDo;
	SetConditionalAppearance();
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure MonitoringReportSettingsSelection(Item, RowSelected, Field, StandardProcessing)
	
	GenerateReport(RowSelected);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Generate(Command)
	
	GenerateReport(Items.MonitoringReportSettings.CurrentRow);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MonitoringReportSettingsRepresentationOfTheOrganization.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MonitoringReportSettings.RepresentationOfTheOrganization");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không lọc>';
													|ru = '<Без отбора>';
													|en = '<Without filter>'; fa = '<Without filter>';
													|it = '<Senza filtro>';
													|pl = '<bez doboru>';
													|tr = '<Filtresiz>'"));
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MonitoringReportSettingsDivisionRepresentation.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MonitoringReportSettings.DivisionRepresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không lọc>';
													|ru = '<Без отбора>';
													|en = '<Without filter>'; fa = '<Without filter>';
													|it = '<Senza filtro>';
													|pl = '<bez doboru>';
													|tr = '<Filtresiz>'"));
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MonitoringReportSettingsScenario.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MonitoringReportSettings.YouCanSelectScenario");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Đặt dạng ngân sách>';
													|ru = '<Установлен в виде бюджета>';
													|en = '<Set in the budget profile>'; fa = '<Set in the budget profile>';
													|it = '<Impostato come tipologia di budget>';
													|pl = '<Ustawiono w postaci budżetu>';
													|tr = '<Bütçe profiline kuruldu>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MonitoringReportSettingsRepresentationOfTheOrganization.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MonitoringReportSettings.CompanySelectionIsAvailable");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Đặt dạng ngân sách>';
													|ru = '<Установлен в виде бюджета>';
													|en = '<Set in the budget profile>'; fa = '<Set in the budget profile>';
													|it = '<Impostato come tipologia di budget>';
													|pl = '<Ustawiono w postaci budżetu>';
													|tr = '<Bütçe profiline kuruldu>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MonitoringReportSettingsDivisionRepresentation.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MonitoringReportSettings.YouCanSelectDepartment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Đặt dạng ngân sách>';
													|ru = '<Установлен в виде бюджета>';
													|en = '<Set in the budget profile>'; fa = '<Set in the budget profile>';
													|it = '<Impostato come tipologia di budget>';
													|pl = '<Ustawiono w postaci budżetu>';
													|tr = '<Bütçe profiline kuruldu>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);

EndProcedure

&AtClient
Procedure GenerateReport(RowID)
	
	CurrentRow = MonitoringReportSettings.FindByID(RowID);
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(CurrentRow.BudgetProfile) Then
		Raise NStr("vi = 'Không xác định dạng ngân sách để xây dựng báo cáo.';
					|ru = 'Не определен Вид бюджета для построения отчета.';
					|en = 'Budget profile to use for report generation is not determined.'; fa = 'Budget profile to use for report generation is not determined.';
					|it = 'Non è stata definita la Tipologia di budget per generare il report.';
					|pl = 'Nieokreślony Typ budżetu do budowania raportu.';
					|tr = 'Raporun inşası için Bütçe profili belirtilmemiş.'")
	EndIf;
	
	ReportParameters = New Structure();
	ReportParameters.Insert("BudgetingModel", BudgetingModel);
	ReportParameters.Insert("BudgetProfile", CurrentRow.BudgetProfile);
	ReportParameters.Insert("Scenario", CurrentRow.Scenario);
	ReportParameters.Insert("Department", CurrentRow.Departments);
	ReportParameters.Insert("Organization", CurrentRow.Companies);
	
	ReportParameters.Insert("DataForConfirmation", CurrentRow.DataForConfirmation);
	ReportParameters.Insert("DataUnderDevelopment", CurrentRow.DataUnderDevelopment);
	
	If ValueIsFilled(Period) Then
		BeginOfPeriod = WorkingWithClientServerPeriods.BeginningDateOfPeriod(Period, Periodicity);
		EndOfPeriod = WorkingWithClientServerPeriods.PeriodEndDate_(Period, Periodicity);
		ReportParameters.Insert("Period", New StandardPeriod(BeginOfPeriod, EndOfPeriod));
	Else
		ReportParameters.Insert("Periodicity", Periodicity);
		ReportParameters.Insert("CurDatePeriod", True);
	EndIf;
	
	ReportParameters.Insert("GenerateBudgetReportWhenOpening", True);
	ReportParameters.Insert("NotUseSavedSettings", True);
	ReportParameters.Insert("ShowSetupBar", False);
	
	OpenForm("Report.BudgetReport.ObjectForm", ReportParameters, , True); 
	
EndProcedure

#EndRegion
