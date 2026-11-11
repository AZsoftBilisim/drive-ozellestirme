#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	MainCircuitSettings = SettingsComposer.GetSettings();
	DataSelectionValues = GetDataSelectionValues(MainCircuitSettings);
	
	If Not DataSelectionValues.ShowACCalculation
		And Not DataSelectionValues.DisplayMACalculation Then
		MessageText = NStr("vi = 'Chọn những dữ liệu cần nhận: KTDN, KTQT.';
							|ru = 'Необходимо выбрать какие данные нужно получить: БУ, УУ.';
							|en = 'Select which data you need to get: LA, MA.'; fa = 'Select which data you need to get: LA, MA.';
							|it = 'È necessario selezionare i dati da ricevere: Contabilità, Contabilità Gestionale.';
							|pl = 'Należy wybrać jakie dane należy otrzymać: Ewidencja księgowa, Ewidencja zarządcza.';
							|tr = 'Hangi verilerin alınacağının seçilmesi gereklidir: GM, YM.'");
		Common.MessageToUser(MessageText,,,, Cancel); 
	EndIf;
	
EndProcedure

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	MainCircuitSettings = SettingsComposer.GetSettings();
	
	DataSelectionValues = GetDataSelectionValues(MainCircuitSettings);
	
	SetReportParameters(DataSelectionValues, MainCircuitSettings);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, MainCircuitSettings, DetailsData);	
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, Undefined, DetailsData, True);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);	
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
	AddInformationalMessageToHeader(ResultDocument, DataSelectionValues);
	
EndProcedure

#EndRegion

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.OnLoadVariantAtServer = True;
	
	Settings.EditStructureAllowed = False;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - Report form:
//   	* Parameters - Structure - may contain properties:
//				** CommandParameter - Arbitrary -
//				** CommandDetails - Structure - 
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter")
		And Parameters.Property("CommandDetails")
		And Parameters.CommandDetails.Property("AdditionalParameters") Then 
		
		ThisForm.ParametersForm.PurposeUseKey = Parameters.CommandDetails.AdditionalParameters.CommandName;
		Parameters.PurposeUseKey = Parameters.CommandDetails.AdditionalParameters.CommandName;
		
		If Parameters.CommandDetails.AdditionalParameters.CommandName = "HelpFACalculation" Then
			ThisForm.ParametersForm.Filter.Insert("FixedAsset", Parameters.CommandParameter);
			Parameters.VariantKey = "HelpFADepreciationCalculation";
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "ReferenceCalculationOfDocumentDepreciationFA" Then
			ThisForm.ParametersForm.Filter.Insert("DepreciationCalculationDocument", Parameters.CommandParameter);
		EndIf;
		
	EndIf;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   NewDCSettings - DataCompositionSettings - Settings to upload to the Settings Composer.
//
// See Syntax Assistant "Managed Form extension for the report.Prizagruzkevariantanaserver" in the syntax assistant.
//
Procedure OnLoadVariantAtServer(Form, NewDCSettings) Export
	
	Report = Form.Report;
	FormSettingsComposer = Report.SettingsComposer; // DataCompositionSettingsComposer -
	
	SetReportPeriod(Form, FormSettingsComposer);
	
	NewDCSettings = FormSettingsComposer.Settings;
	
EndProcedure

#EndRegion

#Region Private

Function GetDataSelectionValues(MainCircuitSettings)

	FilterItems1 = MainCircuitSettings.Filter.Items;
	
	DataSelectionValues = New Structure;
	
	DataSelectionValues.Insert("CompaniesList", TMReportsServer.FilterValue("Organization", FilterItems1));
	If DataSelectionValues.CompaniesList.Count() = 0 Then
		DataSelectionValues.CompaniesList = NonCurrentAssetsInternal.ListOfAllowedOrganizations();
	EndIf;
	
	DataSelectionValues.Insert("ListOfFA", TMReportsServer.FilterValue("FixedAsset", FilterItems1));
	DataSelectionValues.Insert("DepreciationCalculationDocument", TMReportsServer.FilterValue("DepreciationCalculationDocument", FilterItems1));
	
	TMReportsServer.ReportPeriod(MainCircuitSettings, DataSelectionValues);
	
	ShowACCalculation = TMReportsServer.ParameterValue(MainCircuitSettings, "ShowACCalculation", False);
	DisplayMACalculation = TMReportsServer.ParameterValue(MainCircuitSettings, "DisplayMACalculation", False);
	
	DataSelectionValues.Insert("ShowACCalculation", ShowACCalculation);
	DataSelectionValues.Insert("DisplayMACalculation", DisplayMACalculation);
	
	Return DataSelectionValues;
	
EndFunction

Procedure SetReportParameters(DataSelectionValues, MainCircuitSettings)

	If ValueIsFilled(DataSelectionValues.BeginOfPeriod) Then
		BegOfYear = BegOfYear(DataSelectionValues.BeginOfPeriod);
	Else
		BegOfYear = '000101010000';
	EndIf;
	DataCompositionClientServer.SetParameter(MainCircuitSettings, "BegOfYear", BegOfYear);
	
	If ValueIsFilled(DataSelectionValues.PeriodEnding) Then
		EndOfYear = EndOfYear(DataSelectionValues.PeriodEnding);
	Else
		EndOfYear = '000101010000';
	EndIf;
	DataCompositionClientServer.SetParameter(MainCircuitSettings, "EndOfYear", EndOfYear);
	
EndProcedure

Procedure SetReportPeriod(Form, FormSettingsComposer)

	PeriodParameter = DataCompositionClientServer.GetParameter(FormSettingsComposer, "ReportPeriod"); 
	PeriodParameter = PeriodParameter.Value; // StandardPeriod - 
	
	If Form.Parameters.PurposeUseKey = "ReferenceCalculationOfDocumentDepreciationFA" Then
		
		DepreciationCalculationDocument = TMReportsServer.FilterValue(
										"DepreciationCalculationDocument", 
										FormSettingsComposer.Settings.Filter.Items);
										
		If ValueIsFilled(DepreciationCalculationDocument) Then
			DocumentDate = Common.ObjectAttributeValue(DepreciationCalculationDocument[0], "Date");
			
			PeriodParameter.StartDate = BegOfMonth(DocumentDate);
			PeriodParameter.EndDate = EndOfMonth(DocumentDate);
		EndIf; 
		
	EndIf; 
	
EndProcedure

Procedure AddInformationalMessageToHeader(TabDoc, DataSelectionValues)

	IssuesList = New Array;
	
	CheckRelevanceOfDepreciationCalculation(DataSelectionValues, IssuesList);
	
	If IssuesList.Count() = 0 Then
		Return;
	EndIf; 
	
	IssuesList = TMCommonUse.DeleteDuplicateElementsFromArray(IssuesList);
	
	MessageText = StrConcat(IssuesList, Chars.LF);

	TabDoc.Area("R1C1").Text = MessageText;
	TabDoc.Area("R1C1").TextColor = Metadata.StyleItems.TextColorIssue.Value;
	TabDoc.Area(1, 1, 1, ).RowHeight = 0;
	
EndProcedure

Procedure CheckRelevanceOfDepreciationCalculation(DataSelectionValues, IssuesList)

	InformationRegisters.FixedAssetDepreciationPackages.CreateDepreciationPackages(DataSelectionValues.CompaniesList);
	
	QueryText = 
	"SELECT DISTINCT
	|	DocumentDepreciation.Organization.Presentation AS OrganizationPresentation
	|FROM
	|	Document.FixedAssetsDepreciationCharge2_4 AS DocumentDepreciation
	|		INNER JOIN InformationRegister.JobsForCalculatingFixedAssetDepreciation AS JobsForCalculating
	|		ON (JobsForCalculating.Organization = DocumentDepreciation.Organization)
	|			AND (JobsForCalculating.Month <= DocumentDepreciation.Date)
	|		LEFT JOIN InformationRegister.FixedAssetDepreciationPackages AS FixedAssetDepreciationPackages
	|		ON FixedAssetDepreciationPackages.Organization = JobsForCalculating.Organization
	|			AND FixedAssetDepreciationPackages.PackageNumber = JobsForCalculating.PackageNumber
	|			AND &FilterAccordingToListOfFA
	|WHERE
	|	DocumentDepreciation.Organization IN(&CompaniesList)
	|	AND (NOT &FilterAccordingToListOfFA OR FixedAssetDepreciationPackages.FixedAsset IN(&ListOfFA))
	|	AND (NOT &FilterByDocument OR DocumentDepreciation.Ref IN(&DepreciationCalculationDocument))
	|	AND DocumentDepreciation.Posted
	|	AND (DocumentDepreciation.Date >= &BeginOfPeriod
	|			OR &BeginOfPeriod = DATETIME(1, 1, 1))
	|	AND (DocumentDepreciation.Date <= &PeriodEnding
	|			OR &PeriodEnding = DATETIME(1, 1, 1))";
	
	Query = New Query(QueryText);
	Query.SetParameter("CompaniesList", DataSelectionValues.CompaniesList);
	Query.SetParameter("BeginOfPeriod", DataSelectionValues.BeginOfPeriod);
	Query.SetParameter("PeriodEnding", DataSelectionValues.PeriodEnding);
	Query.SetParameter("ListOfFA", DataSelectionValues.ListOfFA);
	Query.SetParameter("FilterAccordingToListOfFA", ValueIsFilled(DataSelectionValues.ListOfFA));
	Query.SetParameter("DepreciationCalculationDocument", DataSelectionValues.DepreciationCalculationDocument);
	Query.SetParameter("FilterByDocument", ValueIsFilled(DataSelectionValues.DepreciationCalculationDocument));
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return;
	EndIf; 
	
	IssuesList.Add(NStr("vi = 'Tính toán khấu hao không liên quan:';
						|ru = 'Расчет амортизации не актуален:';
						|en = 'Depreciation calculation is not relevant:'; fa = 'Depreciation calculation is not relevant:';
						|it = 'Il calcolo dell''ammortamento è obsoleto:';
						|pl = 'Obliczanie amortyzacji jest nieaktualne:';
						|tr = 'Amortisman hesabı alakasız:'"));
	
	Selection = Result.Select();
	While Selection.Next() Do
		MessageText = NStr("vi = '- đối với doanh nghiệp ""%1"" cần hoàn thành việc đóng tháng';
							|ru = '- для организации ""%1"" необходимо выполнить закрытие месяца';
							|en = '- for the company ""%1"" you must perform a month-end closing'; fa = '- for the company ""%1"" you must perform a month-end closing';
							|it = '- per l''azienda ""%1"" è necessario effettuare la chiusura di fine periodo';
							|pl = '- dla firmy ""%1"" należy wykonać zamknięcie miesiąca';
							|tr = '- ""%1"" iş yeri için ay sonu kapanışı işleminin gerçekleştirilmesi gerekmektedir'");
		MessageText = StrTemplate(MessageText, Selection.OrganizationPresentation);
		IssuesList.Add(MessageText); 
	EndDo;
	
EndProcedure

#EndRegion

#EndIf 