
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Parameters.Property("Department", OriginalDepartment);
	Parameters.Property("Organization",   Organization);
	Parameters.Property("Performer",   PerformerOriginal);
	
	DateOfWork = Parameters.Date;
	
	OnlyEmployees = False;
	Parameters.Property("OnlyEmployees", OnlyEmployees);
	
	If Not ValueIsFilled(DateOfWork) Then
		DateOfWork = CurrentSessionDate();
	EndIf;
	
	DocumentSelectionMode = Undefined;
	If ValueIsFilled(PerformerOriginal) Then
		If TypeOf(PerformerOriginal) = Type("CatalogRef.Teams") And Not OnlyEmployees Then
			Items.Teams.CurrentRow = PerformerOriginal;
			DocumentSelectionMode = "Teams";
			UseTeamWorkOrders = True;
		Else
			Items.Employees.CurrentRow = PerformerOriginal;
			DocumentSelectionMode = "Employees";
			UsePersonalWorkOrders = True;
		EndIf;
	EndIf;
	
	DivisionSelectionMode = Undefined;
	If ValueIsFilled(OriginalDepartment) Then
		
		DivisionParameters = ProductionServer.ProductionBusinessUnitDescription(OriginalDepartment);
		
		If DivisionParameters.UseTeamWorkOrders And Not OnlyEmployees Then
			DivisionSelectionMode = "Teams";
			UseTeamWorkOrders = True;
		EndIf;
		
		If DivisionParameters.UsePersonalWorkOrders Then
			DivisionSelectionMode = "Employees";
			UsePersonalWorkOrders = True;
		EndIf;
		
	Else
		UseTeamWorkOrders =  Not OnlyEmployees;
		UsePersonalWorkOrders = True;
		DivisionSelectionMode = "Employees";
	EndIf;
	
	If ValueIsFilled(DocumentSelectionMode) Then
		ChoiceMode = DocumentSelectionMode;
	Else
		ChoiceMode = DivisionSelectionMode;
	EndIf;
	
	Department = OriginalDepartment;
	
	UsePayroll = GetFunctionalOption("UsePayroll");
	
	Items.GroupIsWorkingOnly.Visible = UsePayroll;
	Items.GroupWorkingOnDate.Visible = False;
	Items.CompanyGroup.Visible = False;
	
	
	ProductionAccountingLocalization.AddDataForEmployeeRecruitment(ThisObject, DateOfWork);
	
	//++ WE
	If GetFunctionalOption("PayrollAndHumanResourcesWE") Then
		OperationalAccountingOfManufacturingPayrollAndHumanResources.AddDataForEmployeeRecruitment(ThisObject, DateOfWork);
	EndIf;
	//-- WE
	
	SetSelectionByDivision();
	
	SetVisibility1(ThisForm);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)

	If UsePayroll Or ProductionServer.AccountingOfLaborCostsInContextOfEmployeesIsUsed(DateOfWork) Then
		
		CommonClientServer.SetDynamicListParameter(
			Employees,
			"OnlyWorking",
			OnlyWorking);
		
		CommonClientServer.SetDynamicListParameter(
			Employees,
			"WorkingOnDate",
			Boolean(WorkingOnDate));
		
		CommonClientServer.SetDynamicListParameter(
			Employees,
			"DateOfWork",
			?(ValueIsFilled(DateOfWork), DateOfWork, CurrentSessionDate()));
	EndIf;
	
	Items.DateOfWork.Enabled = Boolean(WorkingOnDate);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DepartmentOnChange(Item)
	
	SetSelectionByDivision();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	SetSelectionByOrganization();
EndProcedure

&AtClient
Procedure ChoiceModeOnChange(Item)
	SetVisibility1(ThisForm);
EndProcedure

&AtClient
Procedure WorkingOnDateOnChange(Item)
	CommonClientServer.SetDynamicListParameter(
		Employees,
		"WorkingOnDate",
		Boolean(WorkingOnDate));
	
	CommonClientServer.SetDynamicListParameter(
		Employees,
		"DateOfWork",
		?(ValueIsFilled(DateOfWork), DateOfWork, CommonClient.SessionDate()));
	
	Items.DateOfWork.Enabled = Boolean(WorkingOnDate);
EndProcedure

&AtClient
Procedure DateOfWorkOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	CommonClientServer.SetDynamicListParameter(Employees, "DateOfWork", ?(ValueIsFilled(DateOfWork), DateOfWork, CommonClient.SessionDate()));
EndProcedure

&AtClient
Procedure OnlyWorkingOnChange(Item)
	CommonClientServer.SetDynamicListParameter(Employees, "OnlyWorking", OnlyWorking);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTeams

&AtClient
Procedure TeamsValueChoice(Item, Value, StandardProcessing)
	NotifyChoice(Items.Teams.CurrentRow);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersEmployees

&AtClient
Procedure EmployeesValueChoice(Item, Value, StandardProcessing)
	
	Result = Items.Employees.CurrentRow;

	If TypeOf(Value) = Type("Number") Then
		Result = Item.CurrentData.Employee;
	EndIf;
	
	NotifyChoice(Result);
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure SetVisibility1(Form)
	
	Form.Items.ChoiceMode.Visible = Form.UseTeamWorkOrders And Form.UsePersonalWorkOrders;
	
	If Form.ChoiceMode = "Teams" Then
		Form.Items.GroupPages.CurrentPage = Form.Items.BrigadeGroup;
		Form.Items.TeamsChoose.DefaultButton = True;
		Form.Items.OnlyWorking.Visible = False;
		Form.Items.WorkingOnDate.Visible = False;
		Form.Items.DateOfWork.Visible = False;
		Form.Items.Organization.Visible = False;
	Else
		Form.Items.GroupPages.CurrentPage = Form.Items.GroupEmployees_2;
		Form.Items.EmployeesChoose.DefaultButton = True;
		Form.Items.OnlyWorking.Visible = True;
		Form.Items.WorkingOnDate.Visible = True;
		Form.Items.DateOfWork.Visible = True;
		Form.Items.Organization.Visible = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetSelectionByDivision()
	
	CommonClientServer.SetDynamicListFilterItem(
		Teams, 
		"Department", 
		Department, 
		DataCompositionComparisonType.Equal,
		, // Presentation - automatically
		ValueIsFilled(Department));
	
	
EndProcedure

&AtServer
Procedure SetSelectionByOrganization()
	
	CommonClientServer.SetDynamicListFilterItem(
		Teams, 
		"Organization", 
		Organization, 
		DataCompositionComparisonType.Equal,
		, // Presentation - automatically
		ValueIsFilled(Organization));
	
	If UsePersonalWorkOrders Then
		
		CommonClientServer.SetDynamicListFilterItem(
			Employees, 
			"Organization", 
			Organization,
			DataCompositionComparisonType.Equal,
			, // Presentation - automatically
			ValueIsFilled(Organization));
		
	EndIf;
	
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
	If Item.Name = "sh_ShamsiInput_F_DateOfWork" Then
		DateOfWorkOnChange(Items.DateOfWork);
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
