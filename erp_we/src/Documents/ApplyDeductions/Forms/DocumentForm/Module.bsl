
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
		
	FillInAdditionalDetailsOfForm();

	DocumentsPayrollAndHumanResourcesServer.SetBanOnEditingItems(ThisObject, True);
	
	DocumentsPayrollAndHumanResourcesServer.ShowHideBanner(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// Handler of the "Date-change" mechanism
	CurrentObject.AdditionalProperties.Insert("CheckingDateWhenChangesWereBanned", True);

	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	FillInAdditionalDetailsOfForm();
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	OnChangingCompanyATServer();
	
EndProcedure

&AtClient
Procedure MonthOfRegistrationByLineStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CloseHandler = New CallbackDescription("RegistrationPeriodPresentationStartChoiceCompletion", ThisObject);
	FormParameters 	   = New Structure("Value, PeriodSelectionMode", Object.RegistrationMonth, "MONTH");
	
	OpenForm("CommonForm.PeriodSelection",
		FormParameters, 
		ThisObject, 
		UUID,
		,
		, 
		CloseHandler,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure MonthOfRegistrationByLineTuning(Item, Direction, StandardProcessing)

	TMCommonUseClient.RegulationOfPresentationOfRegistrationPeriod(
		Direction,
		StandardProcessing,
		Object.RegistrationMonth,
		MonthOfRegistrationByLine);
	
	MonthOfRegistrationByLine = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(Object.RegistrationMonth);

EndProcedure

&AtClient
Procedure MonthOfRegistrationByLineClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure BannerTextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "OpenPayroll" Then
		
		FormParameters = New Structure();
		FormParameters.Insert("Organization", Object.Organization);
		FormParameters.Insert("Department", Object.Department);
		FormParameters.Insert("CalculationPeriod", Object.RegistrationMonth);
		
		OpenForm("DataProcessor.PayrollCalculationHR.Form.Form", FormParameters, ThisObject,,,,);
		
	EndIf;	
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersEmployeeDeductions

&AtClient
Procedure EmployeeDeductionsTaxKindOnChange(Item)
	
	CurrentData = Items.EmployeeDeductions.CurrentData;
	
	If CurrentData.DeductionEndMonth = Date(1,1,1) Then
		CurrentData.DeductionEndMonth = BegOfMonth(Object.Date);
		CurrentData.MonthOfEndOfDeductionByLine = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(
																				CurrentData.DeductionEndMonth);
	EndIf;	
	
EndProcedure

&AtClient
Procedure EmployeeDeductionsMonthOfEndOfDeductionByLineStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;

	CurrentData = Items.EmployeeDeductions.CurrentData;
	
	CloseHandler = New CallbackDescription("EmployeeDeductionsMonthOfEndOfDeductionByLineStartChoiceCompletion", ThisObject);
	FormParameters 	   = New Structure("Value, PeriodSelectionMode", CurrentData.DeductionEndMonth, "MONTH");
	
	OpenForm("CommonForm.PeriodSelection",
		FormParameters, 
		ThisObject, 
		UUID,
		,
		, 
		CloseHandler,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure EmployeeDeductionsMonthOfEndOfDeductionByLineTuning(Item, Direction, StandardProcessing)

	CurrentData = Items.EmployeeDeductions.CurrentData;

	TMCommonUseClient.RegulationOfPresentationOfRegistrationPeriod(
		Direction,
		StandardProcessing,
		CurrentData.DeductionEndMonth,
		CurrentData.MonthOfEndOfDeductionByLine);
	
	CurrentData.MonthOfEndOfDeductionByLine = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(
																				CurrentData.DeductionEndMonth);

EndProcedure

&AtClient
Procedure EmployeeDeductionsMonthOfEndOfDeductionByLineClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure EmployeeDeductionsTypeOfDeductionLineStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)

	CurrentData = Items.EmployeeDeductions.CurrentData;
	
	Items.EmployeeDeductionsDeductionKindHR.ChoiceList.Clear();
	Items.EmployeeDeductionsDeductionKindHR.ChoiceList.LoadValues(ListOfDeductions(CurrentData.TaxKind));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject, True);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject, True);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure EmployeeDeductionsMonthOfEndOfDeductionByLineStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export
	
	If SelectedPeriod <> Undefined Then
		
		CurrentData = Items.EmployeeDeductions.CurrentData;
		
		CurrentData.DeductionEndMonth = SelectedPeriod;
		CurrentData.MonthOfEndOfDeductionByLine = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(
																				CurrentData.DeductionEndMonth);
		
	EndIf;
	
EndProcedure

&AtServer
Function ListOfDeductions(CurrentTypeOfTax)

	ListOfTypesOfDeduction = New Array;
	
	If Not ValueIsFilled(Object.Organization) 
		Or Not ValueIsFilled(CurrentTypeOfTax) Then
		Return New Array();
	EndIf;	
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	TaxSettingsStandardDeductions.DeductionKindHR AS DeductionKindHR
	|FROM
	|	InformationRegister.Deductions_HR.SliceLast(&DateOfList, Organization = &Organization) AS Deductions_HRSliceLast
	|		LEFT JOIN Document.TaxSettings AS TaxSettings
	|			LEFT JOIN Document.TaxSettings.StandardDeductions AS TaxSettingsStandardDeductions
	|			ON TaxSettings.Ref = TaxSettingsStandardDeductions.Ref
	|		ON Deductions_HRSliceLast.DocumentRecorder = TaxSettings.Ref
	|WHERE
	|	TaxSettingsStandardDeductions.TaxKind = &TaxKind";
	
	Query.SetParameter("DateOfList",  Object.RegistrationMonth);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("TaxKind",   CurrentTypeOfTax);
	
	Result = Query.Execute().Select();
	
	While Result.Next() Do
		ListOfTypesOfDeduction.Add(Result.DeductionKindHR);
	EndDo;	 

	Return ListOfTypesOfDeduction;
	
EndFunction	

&AtClient
Procedure RegistrationPeriodPresentationStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export
	
	If SelectedPeriod <> Undefined Then
		
		Object.RegistrationMonth = SelectedPeriod;
		MonthOfRegistrationByLine = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(Object.RegistrationMonth);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAdditionalDetailsOfForm()
	
	MonthOfRegistrationByLine = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(Object.RegistrationMonth);
	
	For Each CurrentRow In Object.EmployeeDeductions Do
		
		CurrentRow.MonthOfEndOfDeductionByLine = MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(
																					CurrentRow.DeductionEndMonth);
		
	EndDo;	
	
EndProcedure	

&AtServer
Procedure OnChangingCompanyATServer()
	
	Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
EndProcedure	

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtClient
Procedure EmployeeStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	ParametersForOpeningSelection = New Structure();
	ParametersForOpeningSelection.Insert("Organization", Object.Organization);
	ParametersForOpeningSelection.Insert("Period", EndOfMonth(Object.RegistrationMonth));
	ParametersForOpeningSelection.Insert("ItWorks", True);
	ParametersForOpeningSelection.Insert("MultipleChoice", False);
	DocumentsPayrollAndHumanResourcesClient.EmployeeRecruitment(ThisObject, ParametersForOpeningSelection, Items.Employee);
	
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
