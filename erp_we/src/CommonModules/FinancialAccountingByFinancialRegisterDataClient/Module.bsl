#Region Public

// Handler for commands added dynamically.
//
// (See ReportsClientOverridable.HandlerCommands).
//
Procedure HandlerCommands(ThisForm, Command, Result) Export
	
	FullReportName = ThisForm.ReportSettings.FullName;

	// Calling connected report commands
	If FullReportName = "Report.AnalysisOfOperationalAccountingCorrespondence" Then
		If Command.Name = "CreateCorrespondenceReflectionSetting" Then
			CreateCorrespondenceReflectionSetting(ThisForm, Command, Result);
		ElsIf Command.Name = "ReturnDocumentsToReflection" Then
			ReturnDocumentsToReflection(ThisForm, Command, Result);
		EndIf;
	EndIf;
	
EndProcedure

// Handler for decoding a tabular document of the report form.
//
// (See ReportsClientOverridable.DetailProcessing).
//
Procedure DetailProcessing(ThisForm, Item, Details, StandardProcessing) Export
	
	FullReportName = ThisForm.ReportSettings.FullName;
	CurrentVariantKey = ThisForm.CurrentVariantKey;
	
	If FullReportName = "Report.AnalysisOfOperationalAccountingCorrespondence" Then
		If CurrentVariantKey = "CorrespondenceAnalysisChessBulletin" Then
			DecryptionList = FinancialAccountingServerCall.DecryptionFieldValues(
				Details, ThisForm.ReportDetailsData);
			
			DecryptionFields = New Structure("DecipherDocuments", False);
			
			For Each DetailsItem In DecryptionList Do
				If StrStartsWith(DetailsItem.Presentation, "SumMan")
				 Or StrStartsWith(DetailsItem.Presentation, "SumCompl") Then
					DecryptionFields.DecipherDocuments = True;
				ElsIf DetailsItem.Presentation = "AccountingObjectDr" Then
					DecryptionFields.Insert("AccountingObjectDr", DetailsItem.Value);
				ElsIf DetailsItem.Presentation = "AccountingObjectCr" Then
					DecryptionFields.Insert("AccountingObjectCr", DetailsItem.Value);
				EndIf;
			EndDo;
			
			If DecryptionFields.DecipherDocuments Then
				StandardProcessing = False;
			
				SelectionParameter = New Structure();
				SettingsComposer = ThisForm.Report.SettingsComposer; // DataCompositionSettingsComposer -
				SelectionElementOrganization = Undefined;
				
				For Each FilterElement In SettingsComposer.Settings.Filter.Items Do
					If FilterElement.Use Then
						SelectionParameter.Insert(String(FilterElement.LeftValue), FilterElement.RightValue);
					EndIf;
					If String(FilterElement.LeftValue) = "Organization" Then
						SelectionElementOrganization = FilterElement;
					EndIf;
				EndDo;
				
				UserSettingsValues = New Structure();
				ReportPeriodParameter = SettingsComposer.Settings.DataParameters.Items.Find("ReportPeriod");
				
				If ReportPeriodParameter.Use Then
					UserPeriodOfReport = SettingsComposer.UserSettings.Items.Find(ReportPeriodParameter.UserSettingID);
					If UserPeriodOfReport.Use Then
						UserSettingsValues.Insert("ReportPeriod", UserPeriodOfReport.Value);
					EndIf;
				EndIf;
				If SelectionElementOrganization <> Undefined Then
					UserSelectionOrganization = SettingsComposer.UserSettings.Items.Find(SelectionElementOrganization.UserSettingID);
					If UserSelectionOrganization.Use Then
						UserSettingsValues.Insert("Organization", UserSelectionOrganization.RightValue);
					EndIf;
				EndIf;
				If DecryptionFields.Property("AccountingObjectDr") Then
					UserSettingsValues.Insert("AccountingObjectDr", DecryptionFields.AccountingObjectDr);
				EndIf;
				If DecryptionFields.Property("AccountingObjectCr") Then
					UserSettingsValues.Insert("AccountingObjectCr", DecryptionFields.AccountingObjectCr);
				EndIf;
				
				FormParameters = New Structure;
				FormParameters.Insert("VariantKey", "AnalysisOfCorrespondenceOnDocuments");
				FormParameters.Insert("GenerateOnOpen", True);
				FormParameters.Insert("Filter", SelectionParameter);
				FormParameters.Insert("UserSettings",
					FinancialAccountingByFinancialRegisterDataServerCall.CustomSettingsForAnalysisOfOperationalAccounting(
						"AnalysisOfOperationalAccountingCorrespondence", UserSettingsValues));
				
				OpenForm("Report.AnalysisOfOperationalAccountingCorrespondence.ObjectForm", FormParameters, ThisForm);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// Opens the form for setting up accounts by accounting objects.
// 
// Parameters:
// 	FormParameters - See FinancialAccountingClient.ParametersForOpeningTransactionConfigurationForms
// 	OwnerForm - ClientApplicationForm - Owner of the configuration form.
// 	AccountingObject - ChartOfCharacteristicTypesRef.AssetLiabilityItems - The accounting object to be configured for
// 	SettingObject1 - Arbitrary - Configuration Object
//
Procedure OpenInvoiceSettingsForAccountingObjects(FormParameters, OwnerForm, AccountingObject = Undefined, SettingObject1 = Undefined) Export
	
	If AccountingObject <> Undefined Then
		FormParameters.Insert("AccountingObject", AccountingObject);
	EndIf;
	If SettingObject1 <> Undefined Then
		FormParameters.Insert("SettingObject1", SettingObject1);
	EndIf;
	OpenForm("DataProcessor.SettingUpFinancialAccountingAccounts.Form.Form", 
		FormParameters, OwnerForm);
	
EndProcedure

#EndRegion

#Region Private

#Region ReportCommandHandlersAnalysisOfOperationalAccountingCorrespondence

Procedure CreateCorrespondenceReflectionSetting(ThisForm, Command, Result)
	
	DecryptionList = FinancialAccountingServerCall.DecryptionFieldValues(
		ThisForm.ReportSpreadsheetDocument.CurrentArea.Details,
		ThisForm.ReportDetailsData);
	
	FillingValues  = New Structure();
	SettingsComposer = ThisForm.Report.SettingsComposer; // DataCompositionSettingsComposer -
	
	For Each FilterElement In SettingsComposer.Settings.Filter.Items Do
		If FilterElement.LeftValue = New DataCompositionField("ChartOfAccounts") Then
			FillingValues.Insert("ChartOfAccounts", FilterElement.RightValue);
		ElsIf FilterElement.LeftValue = New DataCompositionField("PostingGenerationSetting") Then
			FillingValues.Insert("PostingGenerationSetting", FilterElement.RightValue);
		ElsIf FilterElement.LeftValue = New DataCompositionField("AccountingObjectDr") Then
			FillingValues.Insert("AccountingObjectDr", FilterElement.RightValue);
		ElsIf FilterElement.LeftValue = New DataCompositionField("AccountingObjectCr") Then
			FillingValues.Insert("AccountingObjectCr", FilterElement.RightValue);
		EndIf;
	EndDo;
	
	For Each DetailsItem In DecryptionList Do
		If DetailsItem.Presentation = "AccountingObjectDr" Then
			FillingValues.Insert("AccountingObjectDr", DetailsItem.Value);
		ElsIf DetailsItem.Presentation = "AccountingObjectCr" Then
			FillingValues.Insert("AccountingObjectCr", DetailsItem.Value);
		EndIf;
	EndDo;
	
	FormParameters = New Structure();
	FormParameters.Insert("FillingValues", FillingValues);
	
	OpenForm("InformationRegister.SettingsForReflectingCorrespondenceInFinancialAccounting.RecordForm", FormParameters);
	
EndProcedure

Procedure ReturnDocumentsToReflection(ThisForm, Command, Result)
	
	ReflectionParameters = New Array();
	
	For Each SelectedArea1 In ThisForm.ReportSpreadsheetDocument.SelectedAreas Do
		For ColumnNumber = SelectedArea1.Left To SelectedArea1.Right Do
			For LineNumber = SelectedArea1.Top To SelectedArea1.Bottom Do
				DecryptionList = FinancialAccountingServerCall.DecryptionFieldValues(
					ThisForm.ReportSpreadsheetDocument.Area(LineNumber, ColumnNumber).Details,
					ThisForm.ReportDetailsData);
				
				DocumentParameters = New Structure();
				
				For Each DetailsItem In DecryptionList Do
					If DetailsItem.Presentation = "Period" Then
						DocumentParameters.Insert("Period", DetailsItem.Value);
					ElsIf DetailsItem.Presentation = "Recorder" Then
						DocumentParameters.Insert("Document", DetailsItem.Value);
					ElsIf DetailsItem.Presentation = "Organization" Then
						DocumentParameters.Insert("Organization", DetailsItem.Value);
					ElsIf DetailsItem.Presentation = "ReflectionStatus" Then
						DocumentParameters.Insert("Status", DetailsItem.Value);
					EndIf;
				EndDo;
				
				If DocumentParameters.Count() = 4 Then
					If DocumentParameters.Status <> PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting") Then
						ReflectionParameters.Add(DocumentParameters);
					EndIf;
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	If ReflectionParameters.Count() > 0 Then
		FinancialAccountingServerCall.ReturnDocumentsToReflection(ReflectionParameters);
		ThisForm.ComposeResult();
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

