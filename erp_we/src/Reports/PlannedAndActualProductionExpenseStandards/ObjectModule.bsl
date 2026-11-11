#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.OnCreateAtServer = True;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	If Parameters.Property("CommandParameter")
			And Parameters.Property("ParametersReport")
			And Parameters.ParametersReport.Property("AdditionalParameters") Then 
		
	EndIf;
	
EndProcedure

#EndRegion

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	DataSet = DataCompositionSchema.DataSets.Find("DataSet");
	
	CompositionSettings = SettingsComposer.GetSettings();
	
	DataSet.Query = StrReplace(DataSet.Query, "&VolumeM3", Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("SN.UnitOfMeasure", "SN"));
	DataSet.Query = StrReplace(DataSet.Query, "&Weight", Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("SN.UnitOfMeasure", "SN"));
	
	Period = CompositionSettings.DataParameters.FindParameterValue(
		New DataCompositionParameter("StandardPeriod")).Value; // StandardPeriod
	BeginOfPeriod = Period.StartDate;
	EndOfPeriod = Period.EndDate;
	
	TextOfPeriods = "";
	
	Period = EndOfMonth(BeginOfPeriod) + 1;
	UnionTemplate = "
		|UNION ALL
		|SELECT
		|	&Period
		|";
	
	While BegOfMonth(EndOfPeriod) >= Period Do
		
		TextOfPeriods = TextOfPeriods + StrReplace(UnionTemplate, "&Period", 
			Format(Period, "DF='""DateTime(""yyyy"",""M"",""d"")""'"));
		Period = EndOfMonth(Period) + 1;
		
	EndDo;
	
	// extensions if the period is longer than one month
	DataSet.Query = StrReplace(DataSet.Query,
		"INTO PeriodsByMonth",
		"INTO PeriodsByMonth"
			+ Chars.LF
			+ TextOfPeriods);
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "TextFixedExpenses", NStr("vi = 'Chi phí cố định';
																						|ru = 'Постоянные расходы';
																						|en = 'Fixed costs'; fa = 'هزینه‌های ثابت';
																						|it = 'Costi fissi';
																						|pl = 'Stałe rozchody';
																						|tr = 'Sabit giderler'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "TextVariableExpenses", NStr("vi = 'Chi phí biến đổi';
																							|ru = 'Переменные расходы';
																							|en = 'Variable costs'; fa = 'هزینه‌های متغیر';
																							|it = 'Costi variabili';
																							|pl = 'Rozchody zmienne';
																							|tr = 'Değişken giderler'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "NormativeStandard", NStr("vi = 'Tiêu chuẩn';
																						|ru = 'Норматив';
																						|en = 'Standard'; fa = 'استاندارد';
																						|it = 'Normativa';
																						|pl = 'Standard';
																						|tr = 'Standart'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "BaseSize", NStr("vi = 'Giá trị cơ sở phân bổ';
																				|ru = 'Величина базы распределения';
																				|en = 'Allocation base volume'; fa = 'Allocation base volume';
																				|it = 'Valore base di distribuzione';
																				|pl = 'Wartość bazy podziału';
																				|tr = 'Tahsisat tabanının değeri'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "Amount_Expense", NStr("vi = 'Số tiền chi phí';
																						|ru = 'Сумма расхода';
																						|en = 'Expense amount'; fa = 'مبلغ هزینه';
																						|it = 'Importo uscita';
																						|pl = 'Wartość wydatku';
																						|tr = 'Gider tutarı'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "BaseIsNotSpecified", NStr("vi = 'Cơ sở không được đặt';
																							|ru = 'База не задана';
																							|en = 'Base is not specified'; fa = 'مبنا مشخص نشده است';
																							|it = 'Il database non è stato impostato';
																							|pl = 'Baza nie została określona';
																							|tr = 'Taban tanımlanmadı'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "PresentationPieces", NStr("vi = 'Dấu';
																							|ru = 'шт.';
																							|en = 'pcs.'; fa = 'عدد';
																							|it = 'pz.';
																							|pl = 'pcs.';
																							|tr = 'parça'"));
	
	DataCompositionClientServer.SetParameter(SettingsComposer,
		"UsePriceManagementSystem25",
		PriceManagementSystemServerCall.UsePriceManagementSystem25());
	
	DataCompositionClientServer.SetParameter(SettingsComposer,
		"DateOfTransitionToPricingVersion25",
		PriceManagementSystemServerCall.DateOfTransitionToPricingVersion25());
	
EndProcedure

#EndIf