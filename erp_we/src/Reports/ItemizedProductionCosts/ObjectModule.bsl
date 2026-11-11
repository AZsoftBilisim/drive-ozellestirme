
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

// Called before loading new settings. Used to change the layout scheme.
//
// Parameters:
//	Context							- Arbitrary								- parameters of the context in which the report is used.
//	SchemaKey							- String									- ID of the current configuration Builder schema.
//	VariantKey						- String									- name of the predefined or unique ID of the custom
//																						version of the report.
//										- Undefined 								- a call for a decryption option or without context.
//	NewDCSettings					- DataCompositionSettings					- report variant settings that will be loaded
//																						into the settings Builder after it is initialized.
//										- Undefined 								- the option settings do not need to be downloaded (already downloaded earlier).
//	NewDCUserSettings	- DataCompositionUserSettings - custom settings that will be loaded into
//																						the settings Builder after it is initialized.
//										- Undefined 								- user settings do not need to be downloaded (already downloaded earlier).
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If TypeOf(Context) = Type("ClientApplicationForm") Then
		
		If NewDCUserSettings = Undefined Then
			UserSettings = Context.Report.SettingsComposer.UserSettings; // DataCompositionUserSettings -
			ConfigureReportParametersByReportVariant(Context.ReportSettings, NewDCSettings, UserSettings);
		Else
			ConfigureReportParametersByReportVariant(Context.ReportSettings, NewDCSettings, NewDCUserSettings);
		EndIf;
		
		ConfigureSelectionParametersByFunctionalOptions(NewDCSettings);
		
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
		
		FormSettingsComposer = Context.Report.SettingsComposer;
		Parameters = Context.Parameters;
		
		If Parameters.Property("UserParameters") Then
			DataCompositionClientServer.AddParametersToUserSettings(FormSettingsComposer, Parameters.UserParameters);
			NewDCUserSettings = FormSettingsComposer.UserSettings;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionProcessor = New DataCompositionProcessor;
	
	ConfigureUserSettingsByFunctionalOptions(SettingsComposer);
	
	ReportSettings = SettingsComposer.GetSettings();
	
	ReportSettings.DataParameters.SetParameterValue("Itemized",
		NStr("vi = 'Mục hàng';
			|ru = 'Постатейные';
			|en = 'Itemized'; fa = 'تفکیک‌شده';
			|it = 'Dettagliati per voce';
			|pl = 'Itemized';
			|tr = 'Ayrıntılı'"));
	ReportSettings.DataParameters.SetParameterValue("OpeningBalance",
		NStr("vi = 'Dư đầu';
			|ru = 'Начальный остаток';
			|en = 'Opening balance'; fa = 'مانده ابتدای دوره';
			|it = 'Saldo iniziale';
			|pl = 'Saldo początkowe';
			|tr = 'Açılış bakiyesi'"));
	ReportSettings.DataParameters.SetParameterValue("Registration",
		NStr("vi = 'Mua dịch vụ, đăng ký, phản ánh tiền lương';
			|ru = 'Закупка услуг, регистрация, отражение зарплаты';
			|en = 'Service purchase, registration, payroll'; fa = 'Service purchase, registration, payroll';
			|it = 'Acquisto servizi, registrazione, visualizzazione stipendio';
			|pl = 'Zakup usług, rejestracja, wyświetlenie wynagrodzenia';
			|tr = 'Hizmet satın alımı, kayıt, bordro yansıması'"));
	ReportSettings.DataParameters.SetParameterValue("DistributionToProduction",
		NStr("vi = 'Phân bổ cho sản xuất';
			|ru = 'Распределение на производство';
			|en = 'Allocation to production'; fa = 'تسهیم به تولید';
			|it = 'Distribuzione in produzione';
			|pl = 'Przydzielenie do produkcji';
			|tr = 'Üretime dağıtım'"));
	ReportSettings.DataParameters.SetParameterValue("Disposal",
		NStr("vi = 'Ghi giảm vào chi phí khác, thanh lý';
			|ru = 'Списание на другие статьи, выбытие';
			|en = 'Write off to other items, retirement'; fa = 'Write off to other items, retirement';
			|it = 'Cancellazione in altre voci, uscita';
			|pl = 'Rozchód na inne pozycje, wyksięgowanie';
			|tr = 'Diğer kalemlere gider yazma, çekilme'"));
	ReportSettings.DataParameters.SetParameterValue("Transfer",
		NStr("vi = 'Chuyển sang đối tượng phát sinh chi phí khác';
			|ru = 'Перенос на другой объект возникновения затрат';
			|en = 'Allocate to another cost center'; fa = 'Allocate to another cost center';
			|it = 'Trasferimento a un altro oggetto di costo';
			|pl = 'Przeniesienie na inny obiekt tworzenia się rozchodów';
			|tr = 'Başka bir gider oluşumun nesnesine aktarım'"));
	ReportSettings.DataParameters.SetParameterValue("ClosingBalance",
		NStr("vi = 'Dư cuối';
			|ru = 'Конечный остаток';
			|en = 'Closing balance'; fa = 'مانده پایان دوره';
			|it = 'Saldo finale';
			|pl = 'Saldo końcowe';
			|tr = 'Kapanış bakiyesi'"));
	
	ReportPeriodParameter = DataCompositionClientServer.GetParameter(ReportSettings, "Period");
	ReportPeriodParameterValue = ReportPeriodParameter.Value; //StandardPeriod
	WithoutFilterByPeriod = Not ReportPeriodParameter.Use;
	NoSelectionByStartPeriod = WithoutFilterByPeriod Or Not ValueIsFilled(ReportPeriodParameterValue.StartDate);
	DataCompositionClientServer.SetParameter(ReportSettings, "WithoutFilterByPeriod", WithoutFilterByPeriod);
	DataCompositionClientServer.SetParameter(ReportSettings, "NoSelectionByStartPeriod", NoSelectionByStartPeriod);
	
	QueryText = CostsServer.QueryTextItemizedProductionCosts();
	
	DataCompositionSchema.DataSets.Main.Query = QueryText.QueryText;
	
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CostsServer.AddSelectionForSelectedResources(QueryText.Resources, CompositionTemplate.DataSets.Main);
	
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True, False);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	SpreadsheetDocument = OutputProcessor.EndOutput();
	
	// delete the service texts
	
	ReplacementTextExtended = "%ServiceFilter% And
						|";
	ReplacementTextWithoutExtension = "%ServiceFilter%";
	
	ExtendedArea = SpreadsheetDocument.FindText(ReplacementTextExtended);
	AreaWithoutExtension = SpreadsheetDocument.FindText(ReplacementTextWithoutExtension);
	If ExtendedArea <> Undefined Then
		ExtendedArea.Text = StrReplace(ExtendedArea.Text, ReplacementTextExtended, "");
	ElsIf AreaWithoutExtension <> Undefined Then
		AreaWithoutExtension.Text = StrReplace(AreaWithoutExtension.Text, ReplacementTextWithoutExtension, "");
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Adjusts the available values for the "cost Data" data layout parameter, depending on the option.
// 
// Parameters:
//	Document - Document Link.Distribution of labor costs - a decoding document.
//	NewDCSettings - DataCompositionSettings - overriding the report settings.
//	NewDCUserSettings - DataCompositionUserSettings - data layout scheme settings.
Procedure ConfigureReportParametersByReportVariant(ReportSettings, NewDCSettings, NewDCUserSettings)
		
	OptionsKeys = KeysOfPredefinedOptions();
	PredefinedOption = GetPredefinedOption(ReportSettings.OptionRef);
	PredefinedOptionKey = Common.ObjectAttributeValue(PredefinedOption, "VariantKey");
	If Not ValueIsFilled(PredefinedOption) 
		Or OptionsKeys.Find(PredefinedOptionKey) = Undefined Then
		Return;
	EndIf;
	
	ReportDataParameter = DataCompositionSchema.Parameters.Find("Cost_Data");
	EnterpriseParameter = DataCompositionSchema.Parameters.Find("ByEnterprise");
	
	ChoiceList = New ValueList;
	
	If PredefinedOptionKey = "MovementOfItemizedExpensesByEnterprise" Then
		
		ChoiceList.Add(1, NStr("vi = 'Theo tiền tệ kế toán quản trị gồm thuế GTGT';
								|ru = 'В валюте упр. учета с НДС';
								|en = 'In management accounting currency, including VAT'; fa = 'به ارز حسابداری مدیریت، با احتساب مالیات بر ارزش افزوده';
								|it = 'In valuta della contabilità gestionale con IVA';
								|pl = 'W walucie zarz. ewidencji z VAT';
								|tr = 'KDV dahil yönetim muhasebesi para birimi cinsinden'"));
		ChoiceList.Add(2, NStr("vi = 'Theo tiền tệ kế toán quản trị không gồm thuế GTGT';
								|ru = 'В валюте упр. учета без НДС';
								|en = 'In management accounting currency, excluding VAT'; fa = 'به ارز حسابداری مدیریت، بدون مالیات بر ارزش افزوده';
								|it = 'In valuta della contabilità gestionale senza IVA';
								|pl = 'W walucie zarz. ewidencji bez VAT';
								|tr = 'KDV hariç yönetim muhasebesi para birimi cinsinden'"));
		EnterpriseParameter.Value = True;
		
	Else
		
		If CalculationOfCostCached.CompanyManagementAccounting() Then
			ChoiceList.Add(3, NStr("vi = 'Theo tiền tệ kế toán quản trị';
									|ru = 'В валюте упр. учета';
									|en = 'In management accounting currency'; fa = 'به ارز حسابداری مدیریت';
									|it = 'In valuta della contabilità gestionale';
									|pl = 'W walucie ewidencji zarządczej';
									|tr = 'Yönetim muhasebesi para birimi cinsinden'"));
		EndIf;
		ChoiceList.Add(4, NStr("vi = 'Bằng tiền tệ kế toán pháp quy';
								|ru = 'В валюте регл. учета';
								|en = 'In local accounting currency'; fa = 'به ارز حسابداری محلی';
								|it = 'In valuta della contabilità regolamentata';
								|pl = 'W walucie ewidencji reglamentowanej';
								|tr = 'Yerel muhasebe para birimi cinsinden'"));
		EnterpriseParameter.Value = False;
		
	EndIf;
	
	ReportDataParameter.SetAvailableValues(ChoiceList);
	
	If NewDCSettings = Undefined
		Or NewDCUserSettings = Undefined Then
		Return;
	EndIf;
	
	ValueOfReportDataParameter = NewDCSettings.DataParameters.FindParameterValue(New DataCompositionParameter("Cost_Data"));
	ConfiguringReportData = NewDCUserSettings.Items.Find(ValueOfReportDataParameter.UserSettingID);
	
	If Not ConfiguringReportData = Undefined
		And ChoiceList.FindByValue(ConfiguringReportData.Value) = Undefined Then
		ConfiguringReportData.Value = ChoiceList[0].Value;
	EndIf;
	
EndProcedure

Function GetPredefinedOption(Val Variant)
	
	OptionsKeys = KeysOfPredefinedOptions();
	
	// If the option is not specified, then we will take the first one from the default list
	If Variant = Undefined Then
		Return New Structure("VariantKey", OptionsKeys[0]);
	EndIf;
	
	While OptionsKeys.Find(Variant.VariantKey) = Undefined
		And ValueIsFilled(Variant.Parent) Do
		Variant = Variant.Parent;
	EndDo;
	
	Return Variant;
	
EndFunction

Function KeysOfPredefinedOptions()
	
	OptionsKeys = New Array;
	OptionsKeys.Add("MovementOfItemizedExpenses");
	OptionsKeys.Add("MovementOfItemizedExpensesByEnterprise");
	
	Return OptionsKeys;
	
EndFunction

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If GetFunctionalOption("ComplexAutomation") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "ProductionOrder");
	EndIf;
	
EndProcedure

Procedure ConfigureUserSettingsByFunctionalOptions(FormSettingsComposer)
	
	UseAccountingByExpenseObjects = False;
	UseAccountingByExpenseObjects = GetFunctionalOption("UseAccountingByExpenseObjects");
	If Not UseAccountingByExpenseObjects Then
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(FormSettingsComposer,
			"TransitBetweenHIACost");
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(FormSettingsComposer,
			"TransitBetweenOVZPR");
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(FormSettingsComposer,
			"TransitBetweenHIA_");
	EndIf;
	
	CalculationOfPermanentAndTemporaryDifferencesIsKept = False; 
	If Not CalculationOfPermanentAndTemporaryDifferencesIsKept Then
		FieldsToDelete__ = New Array;
		FieldsToDelete__.Add("InitialBalanceIsTA");
		FieldsToDelete__.Add("InitialBalanceOfTD");
		FieldsToDelete__.Add("InitialBalanceOfPD");
		FieldsToDelete__.Add("ReceivedTA");
		FieldsToDelete__.Add("TDHasBeenReceived");
		FieldsToDelete__.Add("ReceivedPD");
		FieldsToDelete__.Add("SpentOnProductionOfTA");
		FieldsToDelete__.Add("SpentOnProductionOfTD");
		FieldsToDelete__.Add("SpentOnProductionOfPD");
		FieldsToDelete__.Add("OtherWriteOffsWELL");
		FieldsToDelete__.Add("OtherWriteOffsOfTD");
		FieldsToDelete__.Add("OtherWriteOffOfPD");
		FieldsToDelete__.Add("TransitBetweenOVZNU");
		FieldsToDelete__.Add("TransitBetweenHIA_");
		FieldsToDelete__.Add("TransitBetweenOVZPR");
		FieldsToDelete__.Add("FinalBalanceIsTA");
		FieldsToDelete__.Add("FinalBalanceOfTD");
		FieldsToDelete__.Add("FinalBalanceOfPD");
		
		CostCalculationAppliedAlgorithms.RestrictUseOfDCSFields(FieldsToDelete__, DataCompositionSchema,
			SettingsComposer, "", True);
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, FieldsToDelete__);
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(FormSettingsComposer, FieldsToDelete__, True);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf