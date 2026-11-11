#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Address = Parameters.Address;
	BudgetingStep = Parameters.BudgetingStep;
	BudgetingModel = Parameters.BudgetingModel;
	ActionType = Parameters.ActionType;
	
	OptionsParameters = New Structure("BudgetingModel", BudgetingModel);
	SetFormFunctionalOptionParameters(OptionsParameters);
	
	MonitoringReportSettings.Load(GetFromTempStorage(Address));
	For Each String In MonitoringReportSettings Do
		FillInSettingsSelectionFieldInLine(String.GetID());
		If TypeOf(String.BudgetProfile) = Type("CatalogRef.BudgetFlowItems") Then
			String.ReportKind = 1;
		ElsIf TypeOf(String.BudgetProfile) = Type("CatalogRef.BudgetBalanceItems") Then
			String.ReportKind = 2;
		EndIf;
	EndDo;
	SetConditionalAppearance();
	
	If ActionType = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules
		Or ActionType = Enums.TypesOfBudgetingStepActions.ApprovalOfGeneratedBudgetTurnover Then
		Items.MonitoringReportsBudgetProfile.Title = NStr("vi = 'Dạng ngân sách / Dạng / Chỉ tiêu';
															|ru = 'Вид бюджета / Статья / Показатель';
															|en = 'Budget profile / Item / Budget balance item'; fa = 'Budget profile / Item / Budget balance item';
															|it = 'Budget profile / Item / Budget balance item';
															|pl = 'Budget profile / Item / Budget balance item';
															|tr = 'Bütçe profili / Kalem / Gösterge'");
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	LineNumber = 0;
	For Each String In MonitoringReportSettings Do
		LineNumber = LineNumber + 1;
		If Not ValueIsFilled(String.BudgetProfile) Then
			MessageText = NStr("vi = 'Chưa chỉ ra Dạng ngân sách trong dòng %1';
								|ru = 'В строке %1 не указан Вид бюджета';
								|en = 'No budget profile is specified in line %1'; fa = 'No budget profile is specified in line %1';
								|it = 'Nella riga %1 non è indicato il Tipo di bilancio';
								|pl = 'W wierszu %1 nie określono Rodzaju budżetu';
								|tr = '%1 satırında Bütçe profili belirtilmemiş'");
			CommonClientServer.MessageToUser(
				StringFunctionsClientServer.SubstituteParametersToString(MessageText, LineNumber), , , , Cancel); 
		EndIf;
		If Not ValueIsFilled(String.Scenario) And String.YouCanSelectScenario Then
			MessageText = NStr("vi = 'Hàng %1 không được chỉ định Kịch bản';
								|ru = 'В строке %1 не указан Сценарий';
								|en = 'Scenario is not specified in line %1'; fa = 'Scenario is not specified in line %1';
								|it = 'Nella riga %1 non è indicato lo Script';
								|pl = 'W wierszu %1 nie określono Scenariusza';
								|tr = '%1 satırında Senaryo belirtilmemiş'");
			CommonClientServer.MessageToUser(
				StringFunctionsClientServer.SubstituteParametersToString(MessageText, LineNumber), , , , Cancel);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMonitoringReports

&AtClient
Procedure MonitoringReportsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If RowSelected <> Undefined Then
		
		CurrentRow = MonitoringReportSettings.FindByID(RowSelected);
		
		If Field.Name = "MonitoringReportsRepresentationOfTheOrganization" Then
			
			CallbackDescription = New CallbackDescription("ChangingSelectionByOrganization", ThisObject);
			FormParameters = New Structure;
			FormParameters.Insert("ValueType", New TypeDescription("CatalogRef.Companies"));
			FormParameters.Insert("Title", NStr("vi = 'Lọc theo doanh nghiệp';
												|ru = 'Отбор по организациям';
												|en = 'Filter by companies'; fa = 'فیلتر بر اساس شرکت‌ها';
												|it = 'Selezione per aziende';
												|pl = 'Filtr według firmy';
												|tr = 'İş yerlerine göre filtre'"));
			FormParameters.Insert("Values", CurrentRow.Companies.UnloadValues());
			OpenForm("CommonForm.EditValueList", FormParameters, , , , , CallbackDescription);
			                                                                          
		ElsIf Field.Name = "MonitoringReportsDivisionRepresentation" Then
			
			CallbackDescription = New CallbackDescription("ChangingSelectionByDivision", ThisObject);
			FormParameters = New Structure;
			FormParameters.Insert("ValueType", New TypeDescription("CatalogRef.BusinessStructure"));
			FormParameters.Insert("Title", NStr("vi = 'Lọc theo bộ phận';
												|ru = 'Отбор по подразделениям';
												|en = 'Filter by business units'; fa = 'فیلتر بر اساس واحدهای تجاری';
												|it = 'Selezione per unità';
												|pl = 'Filtr wg działów';
												|tr = 'Departmanlara göre filtre'"));
			FormParameters.Insert("Values", CurrentRow.Departments.UnloadValues());
			OpenForm("CommonForm.EditValueList", FormParameters, , , , , CallbackDescription);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MonitoringReportsOnStartEdit(Item, NewRow, Copy)
	
	SetBudgetProfileAccordingToReportType(Item.CurrentData);
	
	If NewRow Then
		Item.CurrentData.DataForConfirmation = True;
		Item.CurrentData.DataUnderDevelopment = True;
		If TypeOf(Item.CurrentData.BudgetProfile) = Type("CatalogRef.BudgetProfiles") Then
			FillInSettingsSelectionFieldInLine(Item.CurrentRow);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure MonitoringReportsReportKindOnChange(Item)
	
	SetBudgetProfileAccordingToReportType(Items.MonitoringReports.CurrentData);
	
EndProcedure

&AtClient
Procedure MonitoringReportsBudgetProfileOnChange(Item)
	
	CurrentData = Items.MonitoringReports.CurrentData;
	If TypeOf(CurrentData.BudgetProfile) = Type("CatalogRef.BudgetProfiles") Then
		CurrentRow = Items.MonitoringReports.CurrentRow;
		FillInSettingsSelectionFieldInLine(CurrentRow);
	Else
		SelectionAvailabilityParameters = New Structure("YouCanSelectScenario, CompanySelectionIsAvailable, YouCanSelectDepartment", True, True, True);
		FillPropertyValues(CurrentData, SelectionAvailabilityParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShouldSaveSettings(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Close(SaveSettingsAtServer());
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInSettingsSelectionFieldInLine(RowID) 
	
	String = MonitoringReportSettings.FindByID(RowID);
	If TypeOf(String.BudgetProfile) = Type("CatalogRef.BudgetProfiles") And ValueIsFilled(String.BudgetProfile) Then
		SelectionAvailabilityParameters = Reports.BudgetReport.SelectionAvailabilityParameters(String.BudgetProfile);
	Else
		SelectionAvailabilityParameters = New Structure("YouCanSelectScenario, CompanySelectionIsAvailable, YouCanSelectDepartment", True, True, True);
	EndIf;
	FillPropertyValues(String, SelectionAvailabilityParameters);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MonitoringReportsRepresentationOfTheOrganization.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MonitoringReportSettings.RepresentationOfTheOrganization");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tùy chỉnh';
													|ru = 'Настроить';
													|en = 'Customize'; fa = 'سفارشی‌سازی';
													|it = 'Impostare';
													|pl = 'Customize';
													|tr = 'Ayarla'"));
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MonitoringReportsDivisionRepresentation.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MonitoringReportSettings.DivisionRepresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tùy chỉnh';
													|ru = 'Настроить';
													|en = 'Customize'; fa = 'سفارشی‌سازی';
													|it = 'Impostare';
													|pl = 'Customize';
													|tr = 'Ayarla'"));
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MonitoringReportsScenario.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MonitoringReportSettings.YouCanSelectScenario");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Đặt làm ngân sách>';
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
	ItemField.Field = New DataCompositionField(Items.MonitoringReportsRepresentationOfTheOrganization.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MonitoringReportSettings.CompanySelectionIsAvailable");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Đặt làm ngân sách>';
													|ru = '<Установлен в виде бюджета>';
													|en = '<Set in the budget profile>'; fa = '<Set in the budget profile>';
													|it = '<Impostato come tipologia di budget>';
													|pl = '<Ustawiono w postaci budżetu>';
													|tr = '<Bütçe profiline kuruldu>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MonitoringReportsDivisionRepresentation.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MonitoringReportSettings.YouCanSelectDepartment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Đặt làm ngân sách>';
													|ru = '<Установлен в виде бюджета>';
													|en = '<Set in the budget profile>'; fa = '<Set in the budget profile>';
													|it = '<Impostato come tipologia di budget>';
													|pl = '<Ustawiono w postaci budżetu>';
													|tr = '<Bütçe profiline kuruldu>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MonitoringReportsReportKind.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ActionType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ListOfActions = New ValueList;
	ListOfActions.Add(Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules);
	ListOfActions.Add(Enums.TypesOfBudgetingStepActions.ApprovalOfGeneratedBudgetTurnover);
	ItemFilter.RightValue = ListOfActions;
	Item.Appearance.SetParameterValue("Visible", False);
	
	If ActionType = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules
		Or ActionType = Enums.TypesOfBudgetingStepActions.ApprovalOfGeneratedBudgetTurnover Then
		
		Item = ConditionalAppearance.Items.Add();
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.MonitoringReportsReportKind.Name);
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("MonitoringReportSettings.ReportKind");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = 0;
		Item.Appearance.SetParameterValue("Text", NStr("vi = 'Báo cáo ngân sách';
														|ru = 'Бюджетный отчет';
														|en = 'Budget report'; fa = 'گزارش بودجه';
														|it = 'Report sul bilancio';
														|pl = 'Raport budżetowy';
														|tr = 'Bütçe raporu'"));
		
		Item = ConditionalAppearance.Items.Add();
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.MonitoringReportsReportKind.Name);
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("MonitoringReportSettings.ReportKind");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = 1;
		Item.Appearance.SetParameterValue("Text", NStr("vi = 'Bảng cân đối số phát sinh';
														|ru = 'Оборотная ведомость';
														|en = 'Turnover balance report'; fa = 'گزارش گردش و مانده';
														|it = 'Bilancio fatturato';
														|pl = 'Lista obrotów';
														|tr = 'Mizan'"));
		
		Item = ConditionalAppearance.Items.Add();
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.MonitoringReportsReportKind.Name);
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("MonitoringReportSettings.ReportKind");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = 2;
		Item.Appearance.SetParameterValue("Text", NStr("vi = 'Bảng cân đối số phát sinh';
														|ru = 'Оборотно-сальдовая ведомость';
														|en = 'Trial balance'; fa = 'تراز آزمایشی';
														|it = 'Bilancio di verifica';
														|pl = 'Zestawienie obrotowo-saldowe';
														|tr = 'Geçici Mizan'"));
	
	EndIf;
	
EndProcedure

&AtServer
Function SaveSettingsAtServer()
	
	Return PutToTempStorage(MonitoringReportSettings.Unload(), Address);
	
EndFunction

&AtClient
Procedure ChangingSelectionByOrganization(Companies, AdditionalParameters) Export
	
	If TypeOf(Companies) <> Type("Array") Then
		Return;
	EndIf;
	
	CurrentRow = Items.MonitoringReports.CurrentData;
	CurrentRow.Companies.LoadValues(Companies);
	If CurrentRow.Companies.Count() > 0 Then
		CurrentRow.RepresentationOfTheOrganization = String(CurrentRow.Companies);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangingSelectionByDivision(Departments, AdditionalParameters) Export
	
	If TypeOf(Departments) <> Type("Array") Then
		Return;
	EndIf;
	
	CurrentRow = Items.MonitoringReports.CurrentData;
	CurrentRow.Departments.LoadValues(Departments);
	If CurrentRow.Departments.Count() > 0 Then
		CurrentRow.DivisionRepresentation = String(CurrentRow.Departments);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetBudgetProfileAccordingToReportType(CurrentRow)
	
	If CurrentRow.ReportKind = 1 Then
		Items.MonitoringReportsBudgetProfile.TypeRestriction = New TypeDescription("CatalogRef.BudgetFlowItems");
	ElsIf CurrentRow.ReportKind = 2 Then
		Items.MonitoringReportsBudgetProfile.TypeRestriction = New TypeDescription("CatalogRef.BudgetBalanceItems");
	Else
		Items.MonitoringReportsBudgetProfile.TypeRestriction = New TypeDescription("CatalogRef.BudgetProfiles");
	EndIf;
	CurrentRow.BudgetProfile = Items.MonitoringReportsBudgetProfile.TypeRestriction.AdjustValue(
		CurrentRow.BudgetProfile);
	
EndProcedure

#EndRegion