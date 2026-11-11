
#Region Private

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Period = Parameters.Period;
	CompanyArray = New FixedArray(Parameters.CompanyArray);
	
	PeriodPresentation = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(Period);
	If GetFunctionalOption("UseMultipleCompanies") Then
		CreatePresentationOfOrganizations(Parameters, Undefined);
	Else
		Items.ForRecordOrganization.Visible = False;
		SetListSelectionParameters();
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject,
		Items.ForRecord.CommandBar);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure PeriodPresentationStartChoice(Item, ChoiceData, StandardProcessing)
		
	StandardProcessing = False;
	
	CloseHandler = New CallbackDescription("PeriodPresentationStartChoiceCompletion", ThisObject);
	FormParameters 	   = New Structure("Value, PeriodSelectionMode", Period, "MONTH");
	
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
Procedure PeriodPresentationTuning(Item, Direction, StandardProcessing)
	
	TMCommonUseClient.RegulationOfPresentationOfRegistrationPeriod(
		Direction,
		StandardProcessing,
		Period,
		PeriodPresentation);
		
	SetListSelectionParameters();
	
EndProcedure

&AtClient
Procedure PeriodPresentationClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure CalculatedCompaniesStartChoice(Item, ChoiceData, StandardProcessing)
	
	FormParameters = ParametersForOpeningOrganizationSelectionForm();
	
	CloseHandler = New CallbackDescription("CalculatedCompaniesStartChoiceCompletion", ThisObject, FormParameters.CompanyDescription);
	
	OpenForm("DataProcessor.MonthEndClosingOperations.Form.SelectCompanies",
		FormParameters,
		ThisObject, 
		UUID,
		,
		,
		CloseHandler,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CalculatedCompaniesClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If CompanyArray.Count() = 0 Then
		Return;
	EndIf;
	
	CompanyArray = New FixedArray(New Array);
	PresentationParameters = New Structure("CompanyArray, AllCompanies", Undefined, True);
	
	CreatePresentationOfOrganizations(PresentationParameters, Undefined);
	
EndProcedure

&AtClient
Procedure DocumentsListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#Region StandardSubsystems_Print

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.DocumentsList);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.DocumentsList, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.DocumentsList);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.DocumentsList);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region FormControl

&AtClient
Procedure PeriodPresentationStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export 
	
	If SelectedPeriod = Undefined Then
		Return;
	EndIf;
		
	PeriodPresentationStartChoiceCompletionServer(SelectedPeriod);
	
EndProcedure

&AtServer
Procedure PeriodPresentationStartChoiceCompletionServer(SelectedPeriod) 
	
	Period = SelectedPeriod;
	PeriodPresentation = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(Period);
	
	SetListSelectionParameters();
	
EndProcedure

&AtClient
Procedure CalculatedCompaniesStartChoiceCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	CreatePresentationOfOrganizations(Result, AdditionalParameters);
	
EndProcedure

&AtServer
Procedure CreatePresentationOfOrganizations(PresentationParameters, CompanyDescription)
	
	If PresentationParameters.CompanyArray <> Undefined Then
		CompanyArray = New FixedArray(PresentationParameters.CompanyArray);
	EndIf;
	
	If PresentationParameters.AllCompanies
	 Or (ValueIsFilled(CompanyDescription)
	   And TMCommonUseClientServer.ArraysAreEqual(CompanyArray, CompanyDescription.AvailableCompanies, False)) Then
	   
		If ValueIsFilled(CompanyDescription) And CompanyDescription.ThereAreAccessRestrictions Then
			CalculatedCompanies = NStr("vi = 'Đối với tất cả các doanh nghiệp có sẵn';
										|ru = 'По всем доступным организациям';
										|en = 'By all available companies'; fa = 'By all available companies';
										|it = 'Per tutte le società disponibili';
										|pl = 'Dla wshystkich dostępnych firm';
										|tr = 'Tüm mevcut iş yerleri için'");
		Else
			CalculatedCompanies = NStr("vi = 'Theo tất cả doanh nghiệp';
										|ru = 'По всем организациям';
										|en = 'By all companies'; fa = 'بر اساس همه شرکت‌ها';
										|it = 'Per tutte le aziende';
										|pl = 'Według wszystkich firm';
										|tr = 'Tüm iş yerlerine'");
		EndIf;
		
		Items.CalculatedCompanies.ClearButton = False;
		
	Else
		
		CalculatedCompanies = CostCalculationAppliedAlgorithms.CalculatedCompanies(CompanyArray, ", ");
		
		Items.CalculatedCompanies.ClearButton = True;
		
	EndIf;
	
	SetListSelectionParameters();
	
EndProcedure

&AtServer
Procedure SetListSelectionParameters()
	
	CommonClientServer.SetDynamicListParameter(ForRecord, "EndOfPeriod", EndOfMonth(Period));
	CommonClientServer.SetDynamicListParameter(ForRecord, "CompanyArray", CompanyArray);
	CommonClientServer.SetDynamicListParameter(ForRecord, "AllCompanies", CompanyArray.Count() = 0);
	
	CommonClientServer.SetDynamicListFilterItem(DocumentsList, "Date",  EndOfMonth(Period), DataCompositionComparisonType.LessOrEqual);
	CommonClientServer.SetDynamicListFilterItem(DocumentsList, "Date",  BegOfMonth(Period), DataCompositionComparisonType.GreaterOrEqual);
	CommonClientServer.SetDynamicListFilterItem(DocumentsList, "Organization",  CompanyArray, DataCompositionComparisonType.InList, , CompanyArray.Count());
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Function ParametersForOpeningOrganizationSelectionForm()
	
	// Let's form a structure with a description of the organizations.
	CompanyDescription = New Structure;
	
	AllCompanies = Catalogs.Companies.AvailableCompanies(, False);
	AvailableCompanies = Catalogs.Companies.AvailableCompanies(True, False);
	
	CompanyDescription.Insert("SingleOrganizations",  New FixedArray(AllCompanies));
	CompanyDescription.Insert("GroupsOfOrganizations", 	  New FixedArray(New Array));
	
	CompanyDescription.Insert("IntercampanyOrganizations", New FixedMap(New Map));
	CompanyDescription.Insert("OrganizationsAboutSiIa", 	  New FixedMap(New Map));
	CompanyDescription.Insert("AvailableCompanies", 	  New FixedArray(AvailableCompanies));
	
	CompanyDescription.Insert("ThereAreAccessRestrictions",  AvailableCompanies.Count() <> AllCompanies.Count());
	
	FormParameters = New Structure;
	FormParameters.Insert("RegistrationPeriod",   Period);
	FormParameters.Insert("CompanyArray",   CompanyArray);
	FormParameters.Insert("AllCompanies",      CompanyArray.Count() = 0);
	FormParameters.Insert("CompanyDescription", CompanyDescription);
	
	Return FormParameters;
	
EndFunction

&AtClient
Procedure CreateRecordDocument(Command)
	
	CurrentRow = Items.ForRecord.CurrentData;
	If CurrentRow = Undefined Then
		Raise NStr("vi = 'Chưa chọn ""Doanh nghiệp"" và ""Dạng dự phòng"" để tạo chứng từ';
					|ru = 'Не выбраны ""Организация"" и ""Вид резервов"" для создания документа';
					|en = '""Company"" and ""Reserve kind"" are not selected to create a document'; fa = '""Company"" and ""Reserve kind"" are not selected to create a document';
					|it = 'Per creare un documento non sono stati selezionati ""Azienda"" e ""Tipo di riserve""';
					|pl = 'Nie wybrano ""Firma"" i ""Rodzaj rezerw"" dla utworzenia dokumentu';
					|tr = 'Belge oluşturma için ""İş yeri"" ve ""Rezerv türü"" seçilmedi'");
	EndIf;
	
	FillingValues = New Structure;
	FillingValues.Insert("Organization", CurrentRow.Organization);
	FillingValues.Insert("ReserveKind", CurrentRow.ReserveKind);
	FillingValues.Insert("Date", Period);
	
	FormParameters = New Structure;
	FormParameters.Insert("FillingValues", FillingValues);
	
	OpenForm("Document.FutureExpenseCommitmentsAccrualWriteOff.ObjectForm", FormParameters, ThisForm);
	
EndProcedure

#EndRegion

#EndRegion
