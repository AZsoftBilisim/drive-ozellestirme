#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// For the General "report Form" form of the "report Options" subsystem.
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.OutputSelectedCellsTotal = False;
	Settings.Events.OnCreateAtServer = True;
	Settings.Insert("EditOptionsAllowed", False);
	
EndProcedure

#EndRegion 

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	ReportParameters = Undefined;
	ExternalDataSets = ReportingItems(ReportParameters);
	
	// We will prepare and output a report.
	TemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionSettings = SettingsComposer.GetSettings();
	CompositionTemplate = TemplateComposer.Execute(
		DataCompositionSchema, 
		DataCompositionSettings,
		DetailsData);
		
	CompositionProcessor = New DataCompositionProcessor;
	//External Data Intake = New Structure("Table of Elements", Table of Elements);
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.BeginOutput();
	OutputProcessor.Output(CompositionProcessor, True);
	OutputProcessor.EndOutput();
	
	FixingRowsOnTop = DataCompositionClientServer.GetParameter(SettingsComposer, "FixingRowsOnTop");
	If FixingRowsOnTop <> Undefined Then
		ResultDocument.FixedTop = FixingRowsOnTop.Value;
	EndIf;
	
	FixingRowsOnLeft = DataCompositionClientServer.GetParameter(SettingsComposer, "FixingRowsOnLeft");
	If FixingRowsOnTop <> Undefined Then
		ResultDocument.FixedLeft = FixingRowsOnLeft.Value;
	EndIf;
	
	For Each Parameter In ReportParameters Do
		If Not ValueIsFilled(Parameter.Value) Then
			ParameterArea = ResultDocument.FindText(Parameter.Presentation);
			If ParameterArea <> Undefined Then
				TemplateString = ResultDocument.Area(ParameterArea.Top,ParameterArea.Left,ParameterArea.Top);
				ResultDocument.DeleteArea(TemplateString, SpreadsheetDocumentShiftType.Vertical);
			EndIf;;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

Function ReportingItems(ReportParameters)
	
	Var Account,ExtDimensionType,ExtraDimensionValue;
	
	ReportParameters = New ValueList;
	
	Parameter = DataCompositionClientServer.GetParameter(SettingsComposer, "GLAccount_");
	If Parameter <> Undefined Then
		Account = Parameter.Value;
	EndIf;
	ReportParameters.Add(Account, NStr("vi = 'Tài khoản';
										|ru = 'Счет';
										|en = 'Account'; fa = 'حساب';
										|it = 'Conto';
										|pl = 'Account';
										|tr = 'Hesap'")+": ");
	
	Parameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ExtDimensionType");
	If Parameter <> Undefined Then
		ExtDimensionType = Parameter.Value;
	EndIf;
	ReportParameters.Add(ExtDimensionType, NStr("vi = 'Dạng khoản mục';
												|ru = 'Вид субконто';
												|en = 'Extra dimension type'; fa = 'نوع بُعد اضافی';
												|it = 'Tipo di sottoconto';
												|pl = 'Rodzaj subkonto';
												|tr = 'Ekstra boyut türü'")+": ");
	
	Parameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ExtraDimensionValue");
	If Parameter <> Undefined Then
		ExtraDimensionValue = Parameter.Value;
		DataCompositionClientServer.SetParameter(SettingsComposer,"ExtraDimensionValue",ExtraDimensionValue);
	EndIf;
	ReportParameters.Add(ExtraDimensionValue, NStr("vi = 'Khoản mục';
													|ru = 'Субконто';
													|en = 'Extra dimension'; fa = 'بُعد اضافی';
													|it = 'Sottoconto';
													|pl = 'Subkonto';
													|tr = 'Ekstra boyut'")+": ");
	
	// Let's check if anything is specified for the search
	If Not ValueIsFilled(Account)
		And Not ValueIsFilled(ExtDimensionType)
		And Not ValueIsFilled(ExtraDimensionValue) Then
		Raise NStr("vi = 'Báo cáo không được tạo. Bạn phải chọn một tài khoản, loại khoản mục hoặc giá trị khoản mục.';
					|ru = 'Отчет не сформирован. Необходимо выбрать счет, вид субконто или значение субконто.';
					|en = 'Report is not generated. Select an account, extra dimension type or extra dimension value.'; fa = 'Report is not generated. Select an account, extra dimension type or extra dimension value.';
					|it = 'Il report non è stato generato. È necessario selezionare un conto, un tipo di sottoconto o un valore del sottoconto.';
					|pl = 'Raport nie został wygenerowany. Musisz wybrać konto, typ subkonta lub wartość subkonta.';
					|tr = 'Rapor oluşturulmadı. Hesap, ekstra boyut türü veya ekstra boyut değeri seçmelisiniz.'") ;
	EndIf;
	
	Use = ?(ValueIsFilled(Account) And TypeOf(Account) = LocalAccntingClientServer.TypeChartOfAccounts(), False, True);
	SettingsComposer.Settings.Structure[1].Use = Use;
	
	Schema = GetTemplate("ReportsIndicators");
	Composer = FinancialReportingServer.SchemaComposer(Schema);
	If ValueIsFilled(Account) Then
		DataCompositionClientServer.SetParameter(Composer,"GLAccount_",Account);
	EndIf;
	If ValueIsFilled(ExtDimensionType) Then
		DataCompositionClientServer.SetParameter(Composer,"ExtDimensionType",ExtDimensionType);
	EndIf;
	If ValueIsFilled(ExtraDimensionValue) Then
		DataCompositionClientServer.SetParameter(Composer,"ExtraDimensionValue",ExtraDimensionValue);
	EndIf;
	ReportElements = FinancialReportingServer.UploadDCSResults(Schema, Composer);
	
	Schema = GetTemplate("PostingTemplates");
	Composer = FinancialReportingServer.SchemaComposer(Schema);
	If ValueIsFilled(Account) Then
		DataCompositionClientServer.SetParameter(Composer,"Account",Account);
	EndIf;
	If ValueIsFilled(ExtDimensionType) Then
		DataCompositionClientServer.SetParameter(Composer,"ExtDimensionType",ExtDimensionType);
	EndIf;
	If ValueIsFilled(ExtraDimensionValue) Then
		DataCompositionClientServer.SetParameter(Composer,"ExtraDimensionValue",ExtraDimensionValue);
	EndIf;
	TemplateTable_1 = FinancialReportingServer.UploadDCSResults(Schema, Composer);
	
	ExternalDataSets = New Structure("TableOfElements, TemplateTable_1", ReportElements, TemplateTable_1);
	
	Return ExternalDataSets;
	
EndFunction

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		
		ReportSettings = ReportSettings(Parameters.CommandParameter);
		
		Parameters.UserSettings = ReportSettings.UserSettings;
		Parameters.FixedSettings = ReportSettings.FixedSettings;
		ThisForm.ParametersForm.FixedSettings = ReportSettings.FixedSettings;
		
	EndIf;
	
EndProcedure

Function ReportSettings(Account)
	
	// Context Report Settings
	DataSettingsComposer = New DataCompositionSettingsComposer;
	SchemaName = Metadata.Reports.UseAccountsAndExtraDimensionInSettings.MainDataCompositionSchema.Name;
	ReportSchema = Reports.UseAccountsAndExtraDimensionInSettings.GetTemplate(SchemaName);
	OptionSettings = ReportSchema.SettingVariants.AccountUsageContext.Settings;
	DataSettingsComposer.LoadSettings(OptionSettings);
	UserSettings = DataSettingsComposer.UserSettings;
	UserSettings.AdditionalProperties.Insert("ItSInternational_", True);
	
	// Let's set the parameters of the contextual report
	DataCompositionClientServer.SetParameter(UserSettings, "GLAccount_", Account);
	
	Return DataSettingsComposer;
	
EndFunction

#EndRegion

#EndIf
