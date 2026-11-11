
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
	
	ReportSettings = SettingsComposer.GetSettings();
	
	ReportSettings.DataParameters.SetParameterValue("UsedMaterials",
		NStr("vi = 'Nguyên vật liệu';
			|ru = 'Материалы';
			|en = 'Materials'; fa = 'مواد';
			|it = 'Materiali';
			|pl = 'Materials';
			|tr = 'Malzemeler'"));
	ReportSettings.DataParameters.SetParameterValue("OpeningBalance",
		NStr("vi = 'Dư đầu';
			|ru = 'Начальный остаток';
			|en = 'Opening balance'; fa = 'مانده ابتدای دوره';
			|it = 'Saldo iniziale';
			|pl = 'Saldo początkowe';
			|tr = 'Açılış bakiyesi'"));
	ReportSettings.DataParameters.SetParameterValue("ReceivedFromWarehouse",
		NStr("vi = 'Đã tiếp nhận từ kho hoặc các phân xưởng khác và nhập thông qua điều chuyển';
			|ru = 'Поступило со склада или кладовых других цехов и приходы по перемещениям';
			|en = 'Received from warehouse or other shop floor storerooms and transfer receipts'; fa = 'Received from warehouse or other shop floor storerooms and transfer receipts';
			|it = 'Ricevuto dal magazzino o da magazzini di altre imprese ed entrate per spostamento';
			|pl = 'Wpłynęło z magazynu lub spiżarni innych wytwórni i przychody według przeniesień';
			|tr = 'Diğer atölye depolarından veya ambarlarından ve hareketlere göre alındı'"));
	ReportSettings.DataParameters.SetParameterValue("ReceivedGNZP",
		NStr("vi = 'Đã tiếp nhận từ kho vào sản xuất dở dang';
			|ru = 'Поступило со склада в незавершенное производство';
			|en = 'Received from warehouse to work-in-progress'; fa = 'Received from warehouse to work-in-progress';
			|it = 'Ricevuto dal magazzino per la produzione non ultimata';
			|pl = 'Wpłynęło z magazynu do niezakończonej produkcji';
			|tr = 'Devam eden imalat ambarından alındı'"));
	ReportSettings.DataParameters.SetParameterValue("Expenses",
		NStr("vi = 'Xuất thông qua điều chuyển, chuyển giao sang kho, các phân xưởng khác, vào sản xuất';
			|ru = 'Расходы по перемещениям, передачи на склад, в другие кладовые, в производство';
			|en = 'Expenses for transfers, transfers to a warehouse, other storerooms, production'; fa = 'Expenses for transfers, transfers to a warehouse, other storerooms, production';
			|it = 'Spese per spostamenti, trasferimenti a magazzini, in altri magazzini, alla produzione';
			|pl = 'Rozchody według przemieszczeń, przeniesienia do magazynu. do innych spiżarni, do produkcji';
			|tr = 'Ambara, diğer depolara, üretime yapılan transferlerin nakil giderleri'"));
	ReportSettings.DataParameters.SetParameterValue("WriteOffsForExpenses",
		NStr("vi = 'Ghi giảm vào chi phí';
			|ru = 'Списания на расходы';
			|en = 'Written off as expenses'; fa = 'اسقاط‌شده به‌عنوان هزینه';
			|it = 'Storno per le spese';
			|pl = 'Spisanie na rozchody';
			|tr = 'Giderlere yazılması'"));
	ReportSettings.DataParameters.SetParameterValue("ParishesFromPostashchikov",
		NStr("vi = 'Nhập từ nhà cung cấp và xuất xưởng thành phẩm';
			|ru = 'Приходы от поставщика и выпуски продукции';
			|en = 'Receipts from vendor and product releases'; fa = 'Receipts from vendor and product releases';
			|it = 'Entrate dal fornitore e avvio di produzione';
			|pl = 'Przychody od dostawców i wydania produkcji';
			|tr = 'Satıcıdan gelenler ve imal edilen ürün çıkışları'"));
	ReportSettings.DataParameters.SetParameterValue("ClosingBalance",
		NStr("vi = 'Dư cuối';
			|ru = 'Конечный остаток';
			|en = 'Closing balance'; fa = 'مانده پایان دوره';
			|it = 'Saldo finale';
			|pl = 'Saldo końcowe';
			|tr = 'Kapanış bakiyesi'"));
	ReportSettings.DataParameters.SetParameterValue("InclusionExclusionOfVAT",
		NStr("vi = 'Gồm/không gồm thuế GTGT';
			|ru = 'Вкл./искл. НДС';
			|en = 'Include/exclude VAT'; fa = 'شامل/بدون VAT';
			|it = 'IVA incl./escl.';
			|pl = 'Brutto/netto';
			|tr = 'KDV dahil/hariç'"));
	
	ReportPeriodParameter = DataCompositionClientServer.GetParameter(ReportSettings, "Period");
	WithoutFilterByPeriod = Not ReportPeriodParameter.Use;
	DataCompositionClientServer.SetParameter(ReportSettings, "WithoutFilterByPeriod", WithoutFilterByPeriod);
	
	QueryText = CostsServer.QueryTextProductionMaterialCost();
	
	DataCompositionSchema.DataSets.Main.Query = QueryText.QueryText;
	
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CostsServer.AddSelectionForSelectedResources(QueryText.Resources, CompositionTemplate.DataSets.Main);
	
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True, False);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	SpreadsheetDocument = OutputProcessor.EndOutput();
	
	// delete the service texts
	
	ArrayOfTexts = New Array;
	ArrayOfTexts.Add("%ServiceFilter% And
	|Table Equal ""ManufacturedProduct"" And
	|");
	ArrayOfTexts.Add("%ServiceFilter% And
	|Table Equal ""ManufacturedProduct""");
	ArrayOfTexts.Add("%ServiceFilter% And
	|Table Equal ""UsedMaterials"" And
	|");
	ArrayOfTexts.Add("%ServiceFilter% And
	|Table Equal ""UsedMaterials""");
	ArrayOfTexts.Add("Table Equal ""UsedMaterials"" And
	|");
	ArrayOfTexts.Add("Table Equal ""UsedMaterials""");
	ArrayOfTexts.Add("Table Equal ""ManufacturedProduct"" And
	|");
	ArrayOfTexts.Add("Table Equal ""ManufacturedProduct""");
	
	For Each Text In ArrayOfTexts Do
		Area = SpreadsheetDocument.FindText(Text);
		If Area <> Undefined Then
			Area.Text = StrReplace(Area.Text, Text, "");
		EndIf;
	EndDo;
	
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
	
	If Not GetFunctionalOption("CalculationOfPermanentAndTemporaryDifferencesIsKeptCommon") Then
		FieldsToDelete__ = GetDeletedFields();
		CostCalculationAppliedAlgorithms.RestrictUseOfDCSFields(FieldsToDelete__, DataCompositionSchema,
			SettingsComposer, "", True);
	EndIf;
	
	ReportDataParameter = DataCompositionSchema.Parameters.Find("Cost_Data");
	EnterpriseParameter = DataCompositionSchema.Parameters.Find("ByEnterprise");
	
	ChoiceList = New ValueList;
	
	If PredefinedOptionKey = "MovementOfMaterialsProductsWorksOnEnterprise" Then
		
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
	OptionsKeys.Add("MovementOfMaterialsProductsWorks");
	OptionsKeys.Add("MovementOfMaterialsProductsWorksOnEnterprise");
	
	Return OptionsKeys;
	
EndFunction

Function GetDeletedFields()
	
	FieldsToDelete__ = New Array;
	FieldsToDelete__.Add("InitialBalanceIsTA");
	FieldsToDelete__.Add("InitialBalanceOfTD");
	FieldsToDelete__.Add("InitialBalanceOfPD");
	FieldsToDelete__.Add("PurchasedWELL");
	FieldsToDelete__.Add("AcquiredByTD");
	FieldsToDelete__.Add("PurchasedPD");
	FieldsToDelete__.Add("ReceivedTA");
	FieldsToDelete__.Add("TDHasBeenReceived");
	FieldsToDelete__.Add("ReceivedPD");
	FieldsToDelete__.Add("MovingTA");
	FieldsToDelete__.Add("TDMovements");
	FieldsToDelete__.Add("PDMovements");
	FieldsToDelete__.Add("PassedTA");
	FieldsToDelete__.Add("SubmittedByTD");
	FieldsToDelete__.Add("SubmittedByPD");
	FieldsToDelete__.Add("WrittenOffTA");
	FieldsToDelete__.Add("TDWasWrittenOff");
	FieldsToDelete__.Add("WrittenOffPD");
	FieldsToDelete__.Add("SpentOnProductionOfTA");
	FieldsToDelete__.Add("SpentOnProductionOfTD");
	FieldsToDelete__.Add("SpentOnProductionOfPD");
	FieldsToDelete__.Add("ProducedByTA");
	FieldsToDelete__.Add("ProducedByTD");
	FieldsToDelete__.Add("ProducedByPD");
	FieldsToDelete__.Add("FinalBalanceIsTA");
	FieldsToDelete__.Add("FinalBalanceOfTD");
	FieldsToDelete__.Add("FinalBalanceOfPD");
	
	Return FieldsToDelete__;
	
EndFunction

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If GetFunctionalOption("ComplexAutomation") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "ProductionOrder");
	EndIf;
	
	CalculationOfPermanentAndTemporaryDifferencesIsKept = False; 
	If Not CalculationOfPermanentAndTemporaryDifferencesIsKept Then
		FieldsToDelete__ = GetDeletedFields();
		CostCalculationAppliedAlgorithms.RestrictUseOfDCSFields(FieldsToDelete__, DataCompositionSchema,
			SettingsComposer, "", True);
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, FieldsToDelete__);
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(FormSettingsComposer, FieldsToDelete__, True);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf