///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.ReportsOptions

// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	ReportSettings.DefineFormSettings = True;

	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, False);
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "Main");
	OptionSettings.LongDesc = NStr("vi = 'Báo cáo đa năng theo danh mục, chứng từ, biểu ghi.';
									|ru = 'Универсальный отчет по справочникам, документам, регистрам.';
									|en = 'Universal report on catalogs, documents, and registers.'; fa = 'Universal report on catalogs, documents, and registers.';
									|it = 'Report universale su directory, documenti, registri.';
									|pl = 'Uniwersalny raport dot. katalogów, dokumentów, rejestrów.';
									|tr = 'Kılavuzlar, belgeler, kayıtlar ile ilgili üniversal rapor'");
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region Private

Function ImportSettingsOnChangeParameters() Export 
	Parameters = New Array;
	Parameters.Add(New DataCompositionParameter("MetadataObjectType"));
	Parameters.Add(New DataCompositionParameter("MetadataObjectName"));
	Parameters.Add(New DataCompositionParameter("TableName"));
	
	Return Parameters;
EndFunction

// Returns values of special parameters of the Universal report.
//
// Parameters:
//  Settings - DataCompositionSettings
//  UserSettings - DataCompositionUserSettings
//  AvailableValues - Structure
//  Context - Arbitrary
//
// Returns:
//  Structure:
//    * Period - StandardPeriod
//    * MetadataObjectType - String
//    * MetadataObjectName - String
//    * TableName - String
//    * DataSource - CatalogRef.MetadataObjectIDs
// 
Function FixedParameters(Settings, UserSettings, AvailableValues, Context) Export 
	FixedParameters = New Structure("Period, DataSource, MetadataObjectType, MetadataObjectName, TableName, 
		| MetadataObjectTypeName, MetadataObjectTableName");
	AvailableValues = New Structure("MetadataObjectType, MetadataObjectName, TableName");
	
	SetFixedParameter("Period", FixedParameters, Settings, UserSettings);
	SetFixedParameter("DataSource", FixedParameters, Settings, UserSettings);
	
	AvailableValues.MetadataObjectType = AvailableMetadataObjectsTypes();
	SetFixedParameter(
		"MetadataObjectType",
		FixedParameters,
		Settings, UserSettings,
		AvailableValues.MetadataObjectType, Context);
		
	FixedParameters.MetadataObjectTypeName = FixedParameters.MetadataObjectType;
	
	AvailableValues.MetadataObjectName = AvailableMetadataObjects(
		FixedParameters.MetadataObjectType);
	SetFixedParameter(
		"MetadataObjectName",
		FixedParameters,
		Settings,
		UserSettings,
		AvailableValues.MetadataObjectName);
	
	AvailableValues.TableName = AvailableTables(
		FixedParameters.MetadataObjectType, FixedParameters.MetadataObjectName);
	SetFixedParameter(
		"TableName", FixedParameters, Settings, UserSettings, AvailableValues.TableName);
	
	FixedParameters.MetadataObjectTableName = FixedParameters.TableName;
	
	FixedParameters.DataSource = DataSource(
		FixedParameters.MetadataObjectType, FixedParameters.MetadataObjectName);
	
	IDs = StrSplit("MetadataObjectType, MetadataObjectName, TableName", ", ", False);
	DataParameters = Settings.DataParameters.Items;
	For Each Id In IDs Do 
		SettingItem = DataParameters.Find(Id);
		If SettingItem = Undefined
			Or SettingItem.Value = FixedParameters[Id] Then 
			Continue;
		EndIf;
		
		Settings.AdditionalProperties.Insert("ReportInitialized", False);
		Break;
	EndDo;
	
	Return FixedParameters;
EndFunction

Procedure SetFixedParameter(Id, Parameters, Settings, UserSettings, AvailableValues = Undefined, Context = Undefined)
	FixedParameter = Parameters[Id];
	
	If AvailableValues = Undefined Then 
		AvailableValues = New ValueList;
	EndIf;
	
	SettingItem = Settings.DataParameters.Items.Find(Id);
	If SettingItem = Undefined Then 
		If AvailableValues.Count() > 0 Then 
			Parameters[Id] = AvailableValues[0].Value;
		EndIf;
		Return;
	EndIf;
	
	UserSettingItem = Undefined;   
			
	If TypeOf(UserSettings) = Type("DataCompositionUserSettings")
		And (Settings.AdditionalProperties.Property("ReportInitialized")
		Or UserSettings.AdditionalProperties.Property("ReportInitialized")) Then 
		
		UserSettingItem = UserSettings.Items.Find(
		SettingItem.UserSettingID);
	EndIf;     
	
	If UserSettingItem <> Undefined
		And AvailableValues.FindByValue(UserSettingItem.Value) <> Undefined Then 
		FixedParameter = UserSettingItem.Value;
	ElsIf AvailableValues.FindByValue(SettingItem.Value) <> Undefined Then 
		FixedParameter = SettingItem.Value;
	ElsIf Id = "MetadataObjectName"
		And ValueIsFilled(Parameters.DataSource) Then 
		FixedParameter = Common.MetadataObjectByID(Parameters.DataSource).Name;
	ElsIf AvailableValues.Count() > 0 Then 
		FixedParameter = AvailableValues[0].Value;
	ElsIf UserSettingItem <> Undefined
		And ValueIsFilled(UserSettingItem.Value) Then 
		FixedParameter = UserSettingItem.Value;
	ElsIf ValueIsFilled(SettingItem.Value) Then 
		FixedParameter = SettingItem.Value;
	EndIf;
	
	If Id = "MetadataObjectType"
		And ValueIsFilled(Parameters.DataSource)
		And Parameters.DataSource.GetObject() <> Undefined Then 
		
		MetadataObject = DataSourceMetadata(Parameters.DataSource, Context);
		If MetadataObject <> Undefined Then
			MetadataObjectType = Common.BaseTypeNameByMetadataObject(MetadataObject);
			If MetadataObjectType <> FixedParameter Then 
				Parameters.DataSource = Undefined;
			EndIf;
		Else
			Parameters.DataSource = Undefined;
		EndIf;
	EndIf;
	
	Parameters[Id] = FixedParameter;
EndProcedure

// Sets values of special parameters of the Universal report.
//
// Parameters:
//  Report
//  FixedParameters - See FixedParameters
//  Settings - DataCompositionSettings
//  UserSettings - DataCompositionUserSettings
//
Procedure SetFixedParameters(Report, FixedParameters, Settings, UserSettings) Export 
	DataParameters = Settings.DataParameters;
	
	AvailableParameters = DataParameters.AvailableParameters;
	If AvailableParameters = Undefined Then 
		Return;
	EndIf;
	
	For Each Parameter In FixedParameters Do 
		If AvailableParameters.Items.Find(Parameter.Key) = Undefined Then 
			Continue;
		EndIf;
		
		SettingItem = DataParameters.Items.Find(Parameter.Key);
		If SettingItem = Undefined Then 
			SettingItem = DataParameters.Items.Add();
			SettingItem.Parameter = New DataCompositionParameter(Parameter.Key);
			SettingItem.Value = Parameter.Value;
			SettingItem.Use = True;
		Else
			DataParameters.SetParameterValue(Parameter.Key, Parameter.Value);
		EndIf;
		
		UserSettingItem = Undefined;
		If UserSettings <> Undefined Then 
			UserSettingItem = UserSettings.Items.Find(
				SettingItem.UserSettingID);
		EndIf;
		
		If UserSettingItem <> Undefined Then 
			FillPropertyValues(UserSettingItem, SettingItem, "Use, Value");
		EndIf;
	EndDo;
	
	If UserSettings <> Undefined Then 
		UserSettings.AdditionalProperties.Insert("ReportInitialized", True);
	EndIf;
EndProcedure

Function TextOfQueryByMetadata(ReportParameters)
	SourceMetadata = Metadata[ReportParameters.MetadataObjectType][ReportParameters.MetadataObjectName];
	
	SourceName = SourceMetadata.FullName();
	If ValueIsFilled(ReportParameters.TableName) Then 
		SourceName = SourceName + "." + ReportParameters.TableName;
	EndIf;
	
	FilterSource1 = "";
	If ReportParameters.TableName = "BalanceAndTurnovers" Then
		FilterSource1 = "({&BeginOfPeriod}, {&EndOfPeriod}, Auto, RegisterRecordsAndPeriodBoundaries)";
	ElsIf ReportParameters.TableName = "Turnovers" Then
		FilterSource1 = "({&BeginOfPeriod}, {&EndOfPeriod}, Auto)";
	ElsIf ReportParameters.TableName = "Balance"
		Or ReportParameters.TableName = "SliceLast" Then
		FilterSource1 = "({&EndOfPeriod},)";
	ElsIf ReportParameters.TableName = "SliceFirst" Then
		FilterSource1 = "({&BeginOfPeriod},)";
	ElsIf  ReportParameters.TableName = "RecordsWithExtDimensions" Then
		FilterSource1 = "({&BeginOfPeriod}, {&EndOfPeriod})";
	ElsIf ReportParameters.MetadataObjectType = "Documents" 
		Or ReportParameters.MetadataObjectType = "Tasks"
		Or ReportParameters.MetadataObjectType = "BusinessProcesses" Then
		
		If ValueIsFilled(ReportParameters.TableName)
			And CommonClientServer.HasAttributeOrObjectProperty(SourceMetadata, "TabularSections")
			And CommonClientServer.HasAttributeOrObjectProperty(SourceMetadata.TabularSections, ReportParameters.TableName) Then 
			FilterSource1 = "
				|{WHERE
				|	(Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod)}";
		Else
			FilterSource1 = "
				|{WHERE
				|	(DATE BETWEEN &BeginOfPeriod AND &EndOfPeriod)}";
		EndIf;
	ElsIf ReportParameters.MetadataObjectType = "InformationRegisters"
		And SourceMetadata.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
		FilterSource1 = "
			|{WHERE
			|	(Period BETWEEN &BeginOfPeriod AND &EndOfPeriod)}";
	ElsIf ReportParameters.MetadataObjectType = "AccumulationRegisters"
		Or ReportParameters.MetadataObjectType = "AccountingRegisters" Then
		FilterSource1 = "
			|{WHERE
			|	(Period BETWEEN &BeginOfPeriod AND &EndOfPeriod)}";
	ElsIf ReportParameters.MetadataObjectType = "CalculationRegisters" Then
		FilterSource1 = "
			|{WHERE
			|	RegistrationPeriod BETWEEN &BeginOfPeriod AND &EndOfPeriod}";
	EndIf;
	
	QueryText =
	"SELECT ALLOWED
	|	*
	|FROM
	|	&SourceName AS SpecifiedTableAlias";
	
	If StrStartsWith(FilterSource1, "({") Then
		SourceNameWithFilter = SourceName + " " + FilterSource1; 
		QueryText = StrReplace(QueryText, "&SourceName", SourceNameWithFilter);
	Else
		QueryText = StrReplace(QueryText, "&SourceName", SourceName);
		If ValueIsFilled(FilterSource1) Then 
			QueryText = QueryText + FilterSource1;
		EndIf;
	EndIf;
	
	Return QueryText;

EndFunction

Function AvailableMetadataObjectsTypes()
	AvailableValues = New ValueList;
	
	If HasMetadataTypeObjects(Metadata.Catalogs) Then
		AvailableValues.Add("Catalogs", NStr("vi = 'Danh mục';
											|ru = 'Справочник';
											|en = 'Catalog'; fa = 'فهرست';
											|it = 'Directory';
											|pl = 'Catalog';
											|tr = 'Katalog'"), , PictureLib.Catalog);
	EndIf;
	
	If HasMetadataTypeObjects(Metadata.Documents) Then
		AvailableValues.Add("Documents", NStr("vi = 'Chứng từ';
												|ru = 'Документ';
												|en = 'Document'; fa = 'سند';
												|it = 'Documento';
												|pl = 'Document';
												|tr = 'Belge'"), , PictureLib.Document);
	EndIf;
	
	If HasMetadataTypeObjects(Metadata.InformationRegisters) Then
		AvailableValues.Add("InformationRegisters", NStr("vi = 'Biểu ghi thông tin';
														|ru = 'Регистр сведений';
														|en = 'Information register'; fa = 'Information register';
														|it = 'Registro dati';
														|pl = 'Rejestr informacji';
														|tr = 'Bilgi kaydı'"), , PictureLib.InformationRegister);
	EndIf;
	
	If HasMetadataTypeObjects(Metadata.AccumulationRegisters) Then
		AvailableValues.Add("AccumulationRegisters", NStr("vi = 'Biểu ghi tích lũy';
															|ru = 'Регистр накопления';
															|en = 'Accumulation register'; fa = 'Accumulation register';
															|it = 'Registro di accumulo';
															|pl = 'Rejestr akumulacji';
															|tr = 'Birikim kaydı'"), , PictureLib.AccumulationRegister);
	EndIf;
	
	If HasMetadataTypeObjects(Metadata.AccountingRegisters) Then
		AvailableValues.Add("AccountingRegisters", NStr("vi = 'Biểu ghi kế toán';
														|ru = 'Регистр бухгалтерии';
														|en = 'Accounting register'; fa = 'Accounting register';
														|it = 'Registro contabilità';
														|pl = 'Rejestr księgowości';
														|tr = 'Muhasebe kaydı'"), , PictureLib.AccountingRegister);
	EndIf;
	
	If HasMetadataTypeObjects(Metadata.CalculationRegisters) Then
		AvailableValues.Add("CalculationRegisters", NStr("vi = 'Biểu ghi tính toán';
														|ru = 'Регистр расчета';
														|en = 'Calculation register'; fa = 'Calculation register';
														|it = 'Registro di calcolo';
														|pl = 'Rejestr rozliczenia';
														|tr = 'Hesaplama kaydı'"), , PictureLib.CalculationRegister);
	EndIf;
	
	If HasMetadataTypeObjects(Metadata.ChartsOfCalculationTypes) Then
		AvailableValues.Add("ChartsOfCalculationTypes", NStr("vi = 'Hệ thống dạng tính toán';
															|ru = 'Планы видов расчета';
															|en = 'Charts of calculation types'; fa = 'Charts of calculation types';
															|it = 'Piani dei tipi di calcolo';
															|pl = 'Plany rodzajów obliczeń';
															|tr = 'Hesaplama türü planları'"), , PictureLib.ChartOfCalculationTypes);
	EndIf;
	
	If HasMetadataTypeObjects(Metadata.Tasks) Then
		AvailableValues.Add("Tasks", NStr("vi = 'Nhiệm vụ';
											|ru = 'Задачи';
											|en = 'Tasks'; fa = 'وظایف';
											|it = 'Obiettivi';
											|pl = 'Tasks';
											|tr = 'Görevler'"), , PictureLib.Task);
	EndIf;
	
	If HasMetadataTypeObjects(Metadata.BusinessProcesses) Then
		AvailableValues.Add("BusinessProcesses", NStr("vi = 'Quy trình nghiệp vụ';
														|ru = 'Бизнес-процессы';
														|en = 'Business processes'; fa = 'فرایندهای تجاری';
														|it = 'Processi aziendali';
														|pl = 'Business processes';
														|tr = 'İş süreçleri'"), , PictureLib.BusinessProcess);
	EndIf;
	
	Return AvailableValues;
EndFunction

Function AvailableMetadataObjects(MetadataObjectType)
	AvailableValues = New ValueList;
	
	If Not ValueIsFilled(MetadataObjectType) Then
		Return AvailableValues;
	EndIf;
	
	ValuesToDelete = New ValueList;
	For Each Object In Metadata[MetadataObjectType] Do
		If Not Common.MetadataObjectAvailableByFunctionalOptions(Object)
			Or Not AccessRight("Read", Object) Then
			Continue;
		EndIf;
		
		If StrStartsWith(Upper(Object.Name), "DELETE") Then 
			ValuesToDelete.Add(Object.Name, Object.Synonym);
		Else
			AvailableValues.Add(Object.Name, Object.Synonym);
		EndIf;
	EndDo;
	AvailableValues.SortByPresentation(SortDirection.Asc);
	ValuesToDelete.SortByPresentation(SortDirection.Asc);
	
	For Each RemovableObject In ValuesToDelete Do
		AvailableValues.Add(RemovableObject.Value, RemovableObject.Presentation);
	EndDo;
	
	Return AvailableValues;
EndFunction

Function AvailableTables(MetadataObjectType, MetadataObjectName)
	AvailableValues = New ValueList;
	
	If Not ValueIsFilled(MetadataObjectType)
		Or Not ValueIsFilled(MetadataObjectName) Then 
		Return AvailableValues;
	EndIf;
	
	MetadataObject = Metadata[MetadataObjectType][MetadataObjectName];
	
	AvailableValues.Add("", MainDataTableNamePresentation());
	
	If MetadataObjectType = "Catalogs" 
		Or MetadataObjectType = "Documents" 
		Or MetadataObjectType = "BusinessProcesses"
		Or MetadataObjectType = "Tasks" Then
		
		For Each TabularSection In MetadataObject.TabularSections Do
			AvailableValues.Add(TabularSection.Name, TabularSection.Synonym);
		EndDo;
	ElsIf MetadataObjectType = "InformationRegisters" Then 
		If MetadataObject.InformationRegisterPeriodicity
			<> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
			
			AvailableValues.Add("SliceLast", NStr("vi = 'Mặt cắt cuối cùng';
													|ru = 'Срез последних';
													|en = 'Last values slice'; fa = 'Last values slice';
													|it = 'Sezione degli ultimi';
													|pl = 'Przekrój ostatnich';
													|tr = 'Son olanların kesiti'"));
			AvailableValues.Add("SliceFirst", NStr("vi = 'Mặt cắt đầu tiên';
													|ru = 'Срез первых';
													|en = 'First values slice'; fa = 'First values slice';
													|it = 'Sezione dei primi';
													|pl = 'Przekrój pierwszych';
													|tr = 'Birincilerin kesiti'"));
		EndIf;
	ElsIf MetadataObjectType = "AccumulationRegisters" Then
		If MetadataObject.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Balance Then
			AvailableValues.Add("BalanceAndTurnovers", NStr("vi = 'Số dư và phát sinh';
															|ru = 'Остатки и обороты';
															|en = 'Balances and turnovers'; fa = 'Balances and turnovers';
															|it = 'Saldo e fatturati';
															|pl = 'Zapasy i obroty';
															|tr = 'Bakiye ve cirolar'"));
			AvailableValues.Add("Balance", NStr("vi = 'Số dư';
												|ru = 'Остатки';
												|en = 'Balances'; fa = 'Balances';
												|it = 'Saldo';
												|pl = 'Salda';
												|tr = 'Bakiye'"));
			AvailableValues.Add("Turnovers", NStr("vi = 'Phát sinh';
													|ru = 'Обороты';
													|en = 'Turnovers'; fa = 'گردش‌ها';
													|it = 'Fatturati';
													|pl = 'Obroty';
													|tr = 'Cirolar'"));
		Else
			AvailableValues.Add("Turnovers", NStr("vi = 'Phát sinh';
													|ru = 'Обороты';
													|en = 'Turnovers'; fa = 'گردش‌ها';
													|it = 'Fatturati';
													|pl = 'Obroty';
													|tr = 'Cirolar'"));
		EndIf;
	ElsIf MetadataObjectType = "AccountingRegisters" Then
		AvailableValues.Add("BalanceAndTurnovers", NStr("vi = 'Số dư và phát sinh';
														|ru = 'Остатки и обороты';
														|en = 'Balances and turnovers'; fa = 'Balances and turnovers';
														|it = 'Saldo e fatturati';
														|pl = 'Zapasy i obroty';
														|tr = 'Bakiye ve cirolar'"));
		AvailableValues.Add("Balance", NStr("vi = 'Số dư';
											|ru = 'Остатки';
											|en = 'Balances'; fa = 'Balances';
											|it = 'Saldo';
											|pl = 'Salda';
											|tr = 'Bakiye'"));
		AvailableValues.Add("Turnovers", NStr("vi = 'Phát sinh';
												|ru = 'Обороты';
												|en = 'Turnovers'; fa = 'گردش‌ها';
												|it = 'Fatturati';
												|pl = 'Obroty';
												|tr = 'Cirolar'"));
		If MetadataObject.Correspondence Then
			AvailableValues.Add("DrCrTurnovers", NStr("vi = 'Phát sinh Nợ/Có';
														|ru = 'Обороты Дт/Кт';
														|en = 'Dr/Cr turnovers'; fa = 'Dr/Cr turnovers';
														|it = 'Turnover Accredito/Addebito';
														|pl = 'Obroty Wn/Ma';
														|tr = 'Borç/Alacak ciroları'"));
		EndIf;
		AvailableValues.Add("RecordsWithExtDimensions", NStr("vi = 'Bản ghi kết chuyển từ khoản mục';
															|ru = 'Движения с субконто';
															|en = 'Records with extra dimension'; fa = 'Records with extra dimension';
															|it = 'Movimenti di subconto';
															|pl = 'Ruch z subkonto';
															|tr = 'Eksta boyutla hareket'"));
	ElsIf MetadataObjectType = "CalculationRegisters" Then 
		If MetadataObject.ActionPeriod Then
			AvailableValues.Add("ScheduleData", NStr("vi = 'Dữ liệu trên lịch biểu';
													|ru = 'Данные графика';
													|en = 'Chart data'; fa = 'Chart data';
													|it = 'Dati del grafico';
													|pl = 'Dane harmonogramu';
													|tr = 'Grafik verileri'"));
			AvailableValues.Add("ActualActionPeriod", NStr("vi = 'Kỳ hiệu lực thực tế';
															|ru = 'Фактический период действия';
															|en = 'Actual validity period'; fa = 'Actual validity period';
															|it = 'Periodo di validità attuale';
															|pl = 'Rzeczywisty okres obowiązywania';
															|tr = 'Gerçek geçerlilik süresi'"));
		EndIf;
	ElsIf MetadataObjectType = "ChartsOfCalculationTypes" Then
		If MetadataObject.DependenceOnCalculationTypes
			<> Metadata.ObjectProperties.ChartOfCalculationTypesBaseUse.DontUse Then 
			
			AvailableValues.Add("BaseCalculationTypes", NStr("vi = 'Dạng tính toán cơ bản';
															|ru = 'Базовые виды расчета';
															|en = 'Baseline calculation types.'; fa = 'Baseline calculation types.';
															|it = 'Tipi di calcolo di base';
															|pl = 'Podstawowe rodzaje obliczeń';
															|tr = 'Temel hesaplama türleri'"));
		EndIf;
		
		AvailableValues.Add("LeadingCalculationTypes", NStr("vi = 'Dạng tính toán chính';
															|ru = 'Ведущие виды расчета';
															|en = 'Primary calculation types'; fa = 'Primary calculation types';
															|it = 'Tipi di calcolo principali';
															|pl = 'Czołowe rodzaje obliczeń';
															|tr = 'Önde gelen hesaplama türleri'"));
		
		If MetadataObject.ActionPeriodUse Then 
			AvailableValues.Add("DisplacingCalculationTypes", NStr("vi = 'Dạng tính toán thay thế';
																	|ru = 'Вытесняющие виды расчета';
																	|en = 'Overriding calculation types'; fa = 'Overriding calculation types';
																	|it = 'Tipi di calcolo di esclusione';
																	|pl = 'Wypierające rodzaje obliczeń';
																	|tr = 'Önleyici hesaplama türleri'"));
		EndIf;
	EndIf;
	
	Return AvailableValues;
EndFunction

Function HasMetadataTypeObjects(MetadataType)
	
	For Each Object In MetadataType Do
		If Common.MetadataObjectAvailableByFunctionalOptions(Object)
			And AccessRight("Read", Object) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Procedure AddTotals(ReportParameters, DataCompositionSchema)
	
	If ReportParameters.MetadataObjectType = "AccumulationRegisters" 
		Or ReportParameters.MetadataObjectType = "InformationRegisters" 
		Or ReportParameters.MetadataObjectType = "AccountingRegisters" 
		Or ReportParameters.MetadataObjectType = "CalculationRegisters" Then
		
		AddRegisterTotals(ReportParameters, DataCompositionSchema);
		
	ElsIf ReportParameters.MetadataObjectType = "Documents" 
		Or ReportParameters.MetadataObjectType = "Catalogs" 
		Or ReportParameters.MetadataObjectType = "BusinessProcesses"
		Or ReportParameters.MetadataObjectType = "Tasks" Then
		
		AddObjectTotals(ReportParameters, DataCompositionSchema);
	EndIf;
	
	AddSubordinateRecordsCountTotals(DataCompositionSchema);
	
EndProcedure

Procedure AddObjectTotals(Val ReportParameters, Val DataCompositionSchema)
	
	MetadataObject = Metadata[ReportParameters.MetadataObjectType][ReportParameters.MetadataObjectName];
	ObjectPresentation = MetadataObject.Presentation();
	
	ReferenceDetails = MetadataObject.StandardAttributes["Ref"];
	If ValueIsFilled(ReferenceDetails.Synonym) And ReferenceDetails.Synonym <> NStr("vi = 'Tham chiếu';
																					|ru = 'Ссылка';
																					|en = 'Reference'; fa = 'مرجع';
																					|it = 'Ссылка';
																					|pl = 'Reference';
																					|tr = 'Bağlantı'") Then // ACC:1391 - If the synonym of the "Ref" attribute differs from the standard "Ref", the column header displays the object presentation.
		ObjectPresentation = ReferenceDetails.Synonym;
	ElsIf ValueIsFilled(MetadataObject.ObjectPresentation) Then
		ObjectPresentation = Common.ObjectPresentation(MetadataObject);
	EndIf;
	
	AddDataSetField(DataCompositionSchema.DataSets[0], ReferenceDetails.Name, ObjectPresentation);
	
	If ReportParameters.TableName <> "" Then
		TabularSection = MetadataObject.TabularSections.Find(ReportParameters.TableName);
		If TabularSection <> Undefined Then 
			MetadataObject = TabularSection;
		EndIf;
	EndIf;
	
	// Add totals by numeric attributes
	For Each Attribute In MetadataObject.Attributes Do
		If Not Common.MetadataObjectAvailableByFunctionalOptions(Attribute) 
		   Or Attribute.Type.ContainsType(Type("ValueStorage")) Then
			Continue;
		EndIf;
		
		AddDataSetField(DataCompositionSchema.DataSets[0], Attribute.Name, Attribute.Synonym);
		If Attribute.Type.ContainsType(Type("Number")) Then
			AddTotalField(DataCompositionSchema, Attribute.Name);
		EndIf;
	EndDo;

EndProcedure

Procedure AddRegisterTotals(Val ReportParameters, Val DataCompositionSchema)
	
	MetadataObject = Metadata[ReportParameters.MetadataObjectType][ReportParameters.MetadataObjectName]; 
	
	// Add dimensions.
	For Each Dimension In MetadataObject.Dimensions Do
		If Common.MetadataObjectAvailableByFunctionalOptions(Dimension) Then 
			SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Dimension.Name, Dimension.Synonym);
			SetField.Role.Dimension = True;
		EndIf;
	EndDo;
	
	// Add attributes.
	If IsBlankString(ReportParameters.TableName) Then
		For Each Attribute In MetadataObject.Attributes Do
			If Common.MetadataObjectAvailableByFunctionalOptions(Attribute) Then 
				AddDataSetField(DataCompositionSchema.DataSets[0], Attribute.Name, Attribute.Synonym);
			EndIf;
		EndDo;
	EndIf;
	
	ThereIsFieldLogger = False;
	If ReportParameters.TableName = "BalanceAndTurnovers" Then
		
		DataSetField = DataCompositionSchema.DataSets[0].Fields.Add(Type("DataCompositionSchemaDataSetField"));
		DataSetField.Field = "Recorder";
		DataSetField.Title = NStr("vi = 'Nguồn ghi';
									|ru = 'Регистратор';
									|en = 'Recorder'; fa = 'ثبت‌کننده';
									|it = 'Регистратор';
									|pl = 'Recorder';
									|tr = 'Kaydedici'");
		DataSetField.DataPath = "Recorder";
		DataSetField.Role.PeriodType = DataCompositionPeriodType.Main;
		DataSetField.Role.IgnoreNULLValues = True;
		
		Order_Period = DataSetField.OrderExpressions.Add();
		Order_Period.Expression = "TimeIntervals.SecondPeriod";
		Order_Period.OrderType = DataCompositionSortDirection.Asc;
		
		OrderRegistrar = DataSetField.OrderExpressions.Add();
		OrderRegistrar.Expression = "Recorder";
		OrderRegistrar.OrderType = DataCompositionSortDirection.Asc;
		ThereIsFieldLogger = True;
	EndIf;
	
	// Add period fields.
	If ReportParameters.TableName = "BalanceAndTurnovers" 
		Or ReportParameters.TableName = "Turnovers" 
		Or ReportParameters.MetadataObjectType = "AccountingRegisters" And ReportParameters.TableName = "" Then
		AddPeriodFieldsInDataSet(DataCompositionSchema.DataSets[0], ThereIsFieldLogger);
	EndIf;
		
	// For accounting registers, setting up roles is important.
	If ReportParameters.MetadataObjectType = "AccountingRegisters" Then
		
		AccountField = AddDataSetField(DataCompositionSchema.DataSets[0], "Account", NStr("vi = 'Tài khoản';
																							|ru = 'Счет';
																							|en = 'Account'; fa = 'حساب';
																							|it = 'Conto';
																							|pl = 'Rachunek';
																							|tr = 'Hesap'"));
		AccountField.Role.AccountTypeExpression = "Account.Type";
		AccountField.Role.Account = True;
		
		ExtDimensionCount = 0;
		If MetadataObject.ChartOfAccounts <> Undefined Then 
			ExtDimensionCount = MetadataObject.ChartOfAccounts.MaxExtDimensionCount;
		EndIf;
		
		For ExtDimensionNumber = 1 To ExtDimensionCount Do
			ExtDimensionField = AddDataSetField(DataCompositionSchema.DataSets[0], "ExtDimension" + ExtDimensionNumber, NStr("vi = 'Khoản mục';
																															|ru = 'Субконто';
																															|en = 'Extra dimension'; fa = 'بُعد اضافی';
																															|it = 'Sottoconto';
																															|pl = 'Subkonto';
																															|tr = 'Ek boyutlar'") + " " + ExtDimensionNumber);
			ExtDimensionField.Role.Dimension = True;
			ExtDimensionField.Role.IgnoreNULLValues = False;
		EndDo;
		
	EndIf;
	
	// Add resources.
	For Each Resource In MetadataObject.Resources Do
		If Not Common.MetadataObjectAvailableByFunctionalOptions(Resource) Then 
			Continue;
		EndIf;
		
		If ReportParameters.TableName = "Turnovers" Then
			
			AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Turnover", Resource.Synonym);
			AddTotalField(DataCompositionSchema, Resource.Name + "Turnover");
			
			If ReportParameters.MetadataObjectType = "AccountingRegisters" Then
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "TurnoverDr", Resource.Synonym + " " + NStr("vi = 'phát sinh Nợ';
																																|ru = 'оборот Дт';
																																|en = 'Dr turnover'; fa = 'گردش بدهکار';
																																|it = 'Fatturato a debito';
																																|pl = 'Obrót Wn';
																																|tr = 'Borç ciro'"), Resource.Name + "TurnoverDr");
				AddTotalField(DataCompositionSchema, Resource.Name + "TurnoverDr");
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "TurnoverCr", Resource.Synonym + " " + NStr("vi = 'phát sinh Có';
																																|ru = 'оборот Кт';
																																|en = 'Cr turnover'; fa = 'گردش بستانکار';
																																|it = 'Fatturato a credito';
																																|pl = 'obrót Ma';
																																|tr = 'Alacak ciro'"), Resource.Name + "TurnoverCr");
				AddTotalField(DataCompositionSchema, Resource.Name + "TurnoverCr");
				
				If Not Resource.Balance Then
					AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "BalancedTurnover", Resource.Synonym + " " + NStr("vi = 'phát sinh đối ứng';
																																		|ru = 'кор. оборот';
																																		|en = 'corr. turnover'; fa = 'corr. turnover';
																																		|it = 'Fatturato aziendale';
																																		|pl = 'kor. obrót';
																																		|tr = 'muhabir hesap cirosu'"), Resource.Name + "BalancedTurnover");
					AddTotalField(DataCompositionSchema, Resource.Name + "BalancedTurnover");
					AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "BalancedTurnoverDr", Resource.Synonym + " " + NStr("vi = 'phát sinh đối ứng Nợ';
																																			|ru = 'кор. оборот Дт';
																																			|en = 'Dr corr. turnover'; fa = 'Dr corr. turnover';
																																			|it = 'Addebito fatturato aziendale';
																																			|pl = 'kor. obrót Wn';
																																			|tr = 'muhabir borç hesabı cirosu'"), Resource.Name + "BalancedTurnoverDr");
					AddTotalField(DataCompositionSchema, Resource.Name + "BalancedTurnoverDr");
					AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "BalancedTurnoverCr", Resource.Synonym + " " + NStr("vi = 'phát sinh đối ứng Có';
																																			|ru = 'кор. оборот Кт';
																																			|en = 'Cr corr. turnover'; fa = 'Cr corr. turnover';
																																			|it = 'Accredito fatturato aziendale';
																																			|pl = 'kor. obrót Ma';
																																			|tr = 'muhabir alacak hesabı cirosu'"), Resource.Name + "BalancedTurnoverCr");
					AddTotalField(DataCompositionSchema, Resource.Name + "BalancedTurnoverCr");
				EndIf;
			EndIf;
			
		ElsIf ReportParameters.TableName = "DrCrTurnovers" Then
			
			If Resource.Balance Then
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Turnover", Resource.Synonym);
				AddTotalField(DataCompositionSchema, Resource.Name + "Turnover");
			Else
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "TurnoverDr", Resource.Synonym + " " + NStr("vi = 'phát sinh Nợ';
																																|ru = 'оборот Дт';
																																|en = 'Dr turnover'; fa = 'گردش بدهکار';
																																|it = 'Fatturato a debito';
																																|pl = 'Obrót Wn';
																																|tr = 'Borç ciro'"), Resource.Name + "TurnoverDr");
				AddTotalField(DataCompositionSchema, Resource.Name + "TurnoverDr");
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "TurnoverCr", Resource.Synonym + " " + NStr("vi = 'phát sinh Có';
																																|ru = 'оборот Кт';
																																|en = 'Cr turnover'; fa = 'گردش بستانکار';
																																|it = 'Fatturato a credito';
																																|pl = 'obrót Ma';
																																|tr = 'Alacak ciro'"), Resource.Name + "TurnoverCr");
				AddTotalField(DataCompositionSchema, Resource.Name + "TurnoverCr");
			EndIf;
			
		ElsIf ReportParameters.TableName = "RecordsWithExtDimensions" Then
			
			If Resource.Balance Then
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name, Resource.Synonym);
				AddTotalField(DataCompositionSchema, Resource.Name);
			Else
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Dr", Resource.Synonym + " " + NStr("vi = 'Nợ';
																														|ru = 'Дт';
																														|en = 'Dr'; fa = 'بد';
																														|it = 'Debito';
																														|pl = 'Wn';
																														|tr = 'Borç'"), Resource.Name + "Dr");
				AddTotalField(DataCompositionSchema, Resource.Name + "Dr");
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Cr", Resource.Synonym + " " + NStr("vi = 'Có';
																														|ru = 'Кт';
																														|en = 'Cr'; fa = 'بس';
																														|it = 'Credito';
																														|pl = 'Ma';
																														|tr = 'Alacak'"), Resource.Name + "Cr");
				AddTotalField(DataCompositionSchema, Resource.Name + "Cr");
			EndIf;
			
		ElsIf ReportParameters.TableName = "BalanceAndTurnovers" Then
			
			SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "OpeningBalance", Resource.Synonym + " " + NStr("vi = 'dư đầu';
																																			|ru = 'нач. остаток';
																																			|en = 'open balance'; fa = 'open balance';
																																			|it = 'Saldo iniziale';
																																			|pl = 'saldo początkowe';
																																			|tr = 'açılış bakiyesi'"), Resource.Name + "OpeningBalance");
			AddTotalField(DataCompositionSchema, Resource.Name + "OpeningBalance");
			
			If ReportParameters.MetadataObjectType = "AccountingRegisters" Then
				
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.OpeningBalance;
				SetField.Role.BalanceGroup = "Bal" + Resource.Name;
				SetField.Role.AccountField = "Account";
				
				SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "OpeningBalanceDr", Resource.Synonym + " " + NStr("vi = 'dư đầu Nợ';
																																				|ru = 'нач. остаток Дт';
																																				|en = 'Dr open balance'; fa = 'Dr open balance';
																																				|it = 'Saldo iniziale addebito';
																																				|pl = 'pocz. zapasy Wn';
																																				|tr = 'Borç açılış bakiyesi'"), Resource.Name + "OpeningBalanceDr");
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.OpeningBalance;
				SetField.Role.AccountingBalanceType = DataCompositionAccountingBalanceType.Debit;
				SetField.Role.AccountField = "Account";
				SetField.Role.BalanceGroup = "Bal" + Resource.Name;
				AddTotalField(DataCompositionSchema, Resource.Name + "OpeningBalanceDr");
				
				SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "OpeningBalanceCr", Resource.Synonym + " " + NStr("vi = 'dư đầu Có';
																																				|ru = 'нач. остаток Кт';
																																				|en = 'Cr open balance'; fa = 'Cr open balance';
																																				|it = 'Saldo iniziale accredito';
																																				|pl = 'pocz. zapasy Ma';
																																				|tr = 'Alacak açılış bakiyesi'"), Resource.Name + "OpeningBalanceCr");
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.OpeningBalance;
				SetField.Role.AccountingBalanceType = DataCompositionAccountingBalanceType.Credit;
				SetField.Role.AccountField = "Account";
				SetField.Role.BalanceGroup = "Bal" + Resource.Name;
				AddTotalField(DataCompositionSchema, Resource.Name + "OpeningBalanceCr");
				
				SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "OpeningSplittedBalanceDr", Resource.Synonym + " " + NStr("vi = 'dư đầu chi tiết Nợ';
																																						|ru = 'нач. развернутый остаток Дт';
																																						|en = 'Dr open balance detailed'; fa = 'Dr open balance detailed';
																																						|it = 'Saldo iniziale dettagliato addebito';
																																						|pl = 'pocz. szczegół. zapasy Wn';
																																						|tr = 'ilk geniş bakiye Alacak'"), Resource.Name + "OpeningSplittedBalanceDr");
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.OpeningBalance;
				SetField.Role.AccountingBalanceType = DataCompositionAccountingBalanceType.None;
				SetField.Role.BalanceGroup = "DetldBal" + Resource.Name + "Dr";
				AddTotalField(DataCompositionSchema, Resource.Name + "OpeningSplittedBalanceDr");
				
				SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "OpeningSplittedBalanceCr", Resource.Synonym + " " + NStr("vi = 'dư đầu chi tiết Có';
																																						|ru = 'нач. развернутый остаток Кт';
																																						|en = 'Cr open balance detailed'; fa = 'Cr open balance detailed';
																																						|it = 'Saldo iniziale dettagliato accredito';
																																						|pl = 'pocz. szczegół. zapasy Ma';
																																						|tr = 'ilk geniş bakiye Borç'"), Resource.Name + "OpeningSplittedBalanceCr");
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.OpeningBalance;
				SetField.Role.AccountingBalanceType = DataCompositionAccountingBalanceType.None;
				SetField.Role.BalanceGroup = "DetldBal" + Resource.Name + "Cr";
				AddTotalField(DataCompositionSchema, Resource.Name + "OpeningSplittedBalanceCr");
				
			ElsIf ReportParameters.MetadataObjectType = "AccumulationRegisters" Then
				
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.OpeningBalance;
				SetField.Role.BalanceGroup = "Bal" + Resource.Name;

			EndIf;
			
			AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Turnover", Resource.Synonym + " " + NStr("vi = 'phát sinh';
																														|ru = 'оборот';
																														|en = 'turnover'; fa = 'turnover';
																														|it = 'fatturato';
																														|pl = 'turnover';
																														|tr = 'ciro'"), Resource.Name + "Turnover");
			AddTotalField(DataCompositionSchema, Resource.Name + "Turnover");
			
			If ReportParameters.MetadataObjectType = "AccumulationRegisters" Then
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Receipt", Resource.Synonym + " " + NStr("vi = 'nhập';
																															|ru = 'приход';
																															|en = 'income'; fa = 'income';
																															|it = 'entrata';
																															|pl = 'income';
																															|tr = 'gelir'"), Resource.Name + "Receipt");
				AddTotalField(DataCompositionSchema, Resource.Name + "Receipt");
				
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Expense", Resource.Synonym + " " + NStr("vi = 'xuất';
																															|ru = 'расход';
																															|en = 'expense'; fa = 'expense';
																															|it = 'uscita';
																															|pl = 'expense';
																															|tr = 'gider'"), Resource.Name + "Expense");
				AddTotalField(DataCompositionSchema, Resource.Name + "Expense");
			ElsIf ReportParameters.MetadataObjectType = "AccountingRegisters" Then
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "TurnoverDr", Resource.Synonym + " " + NStr("vi = 'phát sinh Nợ';
																																|ru = 'оборот Дт';
																																|en = 'Dr turnover'; fa = 'گردش بدهکار';
																																|it = 'Fatturato a debito';
																																|pl = 'Obrót Wn';
																																|tr = 'Borç ciro'"), Resource.Name + "TurnoverDr");
				AddTotalField(DataCompositionSchema, Resource.Name + "TurnoverDr");
				
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "TurnoverCr", Resource.Synonym + " " + NStr("vi = 'phát sinh Có';
																																|ru = 'оборот Кт';
																																|en = 'Cr turnover'; fa = 'گردش بستانکار';
																																|it = 'Fatturato a credito';
																																|pl = 'obrót Ma';
																																|tr = 'Alacak ciro'"), Resource.Name + "TurnoverCr");
				AddTotalField(DataCompositionSchema, Resource.Name + "TurnoverCr");
			EndIf;
			
			SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "ClosingBalance", Resource.Synonym + " " + NStr("vi = 'dư cuối';
																																			|ru = 'кон. остаток';
																																			|en = 'close balance'; fa = 'close balance';
																																			|it = 'saldo finale';
																																			|pl = 'saldo końcowe';
																																			|tr = 'kapanış bakiyesi'"), Resource.Name + "ClosingBalance");
			AddTotalField(DataCompositionSchema, Resource.Name + "ClosingBalance");
			
			If ReportParameters.MetadataObjectType = "AccountingRegisters" Then
				
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.ClosingBalance;
				SetField.Role.AccountField = "Account";
				SetField.Role.BalanceGroup = "Bal" + Resource.Name;
				
				SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "ClosingBalanceDr", Resource.Synonym + " " + NStr("vi = 'dư cuối Nợ';
																																				|ru = 'кон. остаток Дт';
																																				|en = 'Dr close balance'; fa = 'Dr close balance';
																																				|it = 'resto addebito';
																																				|pl = 'koń. zapasy Wn';
																																				|tr = 'Borç kapanış bakiyesi'"), Resource.Name + "ClosingBalanceDr");
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.ClosingBalance;
				SetField.Role.AccountingBalanceType = DataCompositionAccountingBalanceType.Debit;
				SetField.Role.AccountField = "Account";
				SetField.Role.BalanceGroup = "Bal" + Resource.Name;
				AddTotalField(DataCompositionSchema, Resource.Name + "ClosingBalanceDr");
				
				SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "ClosingBalanceCr", Resource.Synonym + " " + NStr("vi = 'dư cuối Có';
																																				|ru = 'кон. остаток Кт';
																																				|en = 'Cr close balance'; fa = 'Cr close balance';
																																				|it = 'resto accredito';
																																				|pl = 'koń. zapasy Ma';
																																				|tr = 'Alacak kapanış bakiyesi'"), Resource.Name + "ClosingBalanceCr");
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.ClosingBalance;
				SetField.Role.AccountingBalanceType = DataCompositionAccountingBalanceType.Credit;
				SetField.Role.AccountField = "Account";
				SetField.Role.BalanceGroup = "Bal" + Resource.Name;
				AddTotalField(DataCompositionSchema, Resource.Name + "ClosingBalanceCr");
				
				SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "ClosingSplittedBalanceDr", Resource.Synonym + " " + NStr("vi = 'dư cuối chi tiết Nợ';
																																						|ru = 'кон. развернутый остаток Дт';
																																						|en = 'Dr close balance detailed'; fa = 'Dr close balance detailed';
																																						|it = 'Saldo dettagliato addebito';
																																						|pl = 'kon. szczegół. zapasy Wn';
																																						|tr = 'son geniş bakiye Borç'"), Resource.Name + "ClosingSplittedBalanceDr");
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.ClosingBalance;
				SetField.Role.AccountingBalanceType = DataCompositionAccountingBalanceType.None;
				SetField.Role.BalanceGroup = "DetldBal" + Resource.Name + "Dr";
				AddTotalField(DataCompositionSchema, Resource.Name + "ClosingSplittedBalanceDr");
				
				SetField = AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "ClosingSplittedBalanceCr", Resource.Synonym + " " + NStr("vi = 'dư cuối chi tiết Có';
																																						|ru = 'кон. развернутый остаток Кт';
																																						|en = 'Cr close balance detailed'; fa = 'Cr close balance detailed';
																																						|it = 'Saldo dettagliato accredito';
																																						|pl = 'kon. szczegół. saldo Ma';
																																						|tr = 'son geniş bakiye Alacak'"), Resource.Name + "ClosingSplittedBalanceCr");
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.ClosingBalance;
				SetField.Role.AccountingBalanceType = DataCompositionAccountingBalanceType.None;
				SetField.Role.BalanceGroup = "DetldBal" + Resource.Name + "Cr";
				AddTotalField(DataCompositionSchema, Resource.Name + "ClosingSplittedBalanceCr");
				
			ElsIf ReportParameters.MetadataObjectType = "AccumulationRegisters" Then
				SetField.Role.Balance = True;
				SetField.Role.BalanceType = DataCompositionBalanceType.ClosingBalance;
				SetField.Role.BalanceGroup = "Bal" + Resource.Name;
			EndIf;
			
		ElsIf ReportParameters.TableName = "Balance" Then
			AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Balance", Resource.Synonym + " " + NStr("vi = 'số dư';
																														|ru = 'остаток';
																														|en = 'balance'; fa = 'balance';
																														|it = 'rimanenze';
																														|pl = 'balance';
																														|tr = 'Bakiye'"), Resource.Name + "Balance");
			AddTotalField(DataCompositionSchema, Resource.Name + "Balance");
			
			If ReportParameters.MetadataObjectType = "AccountingRegisters" Then
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "BalanceDr", Resource.Synonym + " " + NStr("vi = 'số dư Nợ';
																																|ru = 'остаток Дт';
																																|en = 'Dr balance'; fa = 'مانده بدهکار';
																																|it = 'Saldo addebito';
																																|pl = 'zapasy Wn';
																																|tr = 'Borç bakiyesi'"), Resource.Name + "BalanceDr");
				AddTotalField(DataCompositionSchema, Resource.Name + "BalanceDr");
				
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "BalanceCr", Resource.Synonym + " " + NStr("vi = 'số dư Có';
																																|ru = 'остаток Кт';
																																|en = 'Cr balance'; fa = 'Cr balance';
																																|it = 'Saldo accredito';
																																|pl = 'saldo Ma';
																																|tr = 'Alacak bakiyesi'"), Resource.Name + "BalanceCr");
				AddTotalField(DataCompositionSchema, Resource.Name + "BalanceCr");
				
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "SplittedBalanceDr", Resource.Synonym + " " + NStr("vi = 'dư Nợ chi tiết';
																																		|ru = 'развернутый остаток Дт';
																																		|en = 'Dr balance detailed'; fa = 'Dr balance detailed';
																																		|it = 'Saldo dettagliato accredito';
																																		|pl = 'saldo szczegółowe Wn';
																																		|tr = 'Borç genişletilmiş bakiye'"), Resource.Name + "SplittedBalanceDr");
				AddTotalField(DataCompositionSchema, Resource.Name + "SplittedBalanceDr");
				
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "SplittedBalanceCr", Resource.Synonym + " " + NStr("vi = 'dư Có chi tiết';
																																		|ru = 'развернутый остаток Кт';
																																		|en = 'Cr balance detailed'; fa = 'Cr balance detailed';
																																		|it = 'Saldo dettagliato addebito';
																																		|pl = 'szczegół. saldo Ma';
																																		|tr = 'Alacak genişletilmiş bakiye'"), Resource.Name + "SplittedBalanceCr");
				AddTotalField(DataCompositionSchema, Resource.Name + "SplittedBalanceCr");
			EndIf;
		ElsIf ReportParameters.MetadataObjectType = "InformationRegisters" Then
			AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name, Resource.Synonym);
			If Resource.Type.ContainsType(Type("Number")) Then
				AddTotalField(DataCompositionSchema, Resource.Name);
			EndIf;
		ElsIf ReportParameters.TableName = "" Then
			If ReportParameters.MetadataObjectType = "AccountingRegisters" Then
				If Resource.Balance Then
					AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name, Resource.Synonym);
					AddTotalField(DataCompositionSchema, Resource.Name);
				Else
					AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Dr", Resource.Synonym + " " + NStr("vi = 'Nợ';
																															|ru = 'Дт';
																															|en = 'Dr'; fa = 'بد';
																															|it = 'Debito';
																															|pl = 'Wn';
																															|tr = 'Borç'"), Resource.Name + "Dr");
					AddTotalField(DataCompositionSchema, Resource.Name + "Dr");
					AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name + "Cr", Resource.Synonym + " " + NStr("vi = 'Có';
																															|ru = 'Кт';
																															|en = 'Cr'; fa = 'بس';
																															|it = 'Credito';
																															|pl = 'Ma';
																															|tr = 'Alacak'"), Resource.Name + "Cr");
					AddTotalField(DataCompositionSchema, Resource.Name + "Cr");
				EndIf;
			Else
				AddDataSetField(DataCompositionSchema.DataSets[0], Resource.Name, Resource.Synonym);
				AddTotalField(DataCompositionSchema, Resource.Name);
			EndIf;
		EndIf;
	EndDo;

EndProcedure

Procedure AddSubordinateRecordsCountTotals(DataCompositionSchema)
	
	FieldToEval = DataCompositionSchema.CalculatedFields.Add();
	FieldToEval.DataPath = "SubordinateRecordsCount";
	FieldToEval.Title = NStr("vi = 'Số lượng bản ghi';
							|ru = 'Количество записей';
							|en = 'Number of records'; fa = 'تعداد ثبت‌ها';
							|it = 'Quantità registrazioni';
							|pl = 'Ilość wpisów';
							|tr = 'Kayıt sayısı'");
	FieldToEval.Expression = "1";
	FieldToEval.ValueType = New TypeDescription("Number");
	
	FieldAppearance = FieldToEval.Appearance.Items;
	ParametersIDs = StrSplit("MinimumWidth, MaximumWidth", ", ", False);
	
	For Each Id In ParametersIDs Do 
		Parameter = FieldAppearance.Find(Id);
		Parameter.Value = 12;
		Parameter.Use = True;
	EndDo;
	
	AddTotalField(DataCompositionSchema, "SubordinateRecordsCount");
	
EndProcedure

// Adds a period to data set fields.
// 
// Parameters:
//  DataSet - DataCompositionSchemaDataSetQuery
//  ThereIsFieldLogger - Boolean
//
// Returns:
//  ValueList
//
Function AddPeriodFieldsInDataSet(DataSet, ThereIsFieldLogger)
	
	PeriodsList = New ValueList;
	PeriodsList.Add("SecondPeriod",   NStr("vi = 'Kỳ giây';
											|ru = 'Период секунда';
											|en = 'Period second'; fa = 'دوره ثانیه';
											|it = 'Periodo secondo';
											|pl = 'Okres sekunda';
											|tr = 'Dönem saniye'"));
	PeriodsList.Add("MinutePeriod",    NStr("vi = 'Kỳ phút';
											|ru = 'Период минута';
											|en = 'Period minute'; fa = 'دقیقه دوره';
											|it = 'Periodo minuto';
											|pl = 'Okres minuta';
											|tr = 'Dönem dakika'"));
	PeriodsList.Add("HourPeriod",       NStr("vi = 'Kỳ giờ';
											|ru = 'Период час';
											|en = 'Period hour'; fa = 'ساعت دوره';
											|it = 'Periodo ora';
											|pl = 'Okres godzina';
											|tr = 'Dönem saat'"));
	PeriodsList.Add("DayPeriod",      NStr("vi = 'Kỳ ngày';
											|ru = 'Период день';
											|en = 'Period day'; fa = 'دوره روز';
											|it = 'Periodo giorno';
											|pl = 'Okres dzień';
											|tr = 'Dönem gün'"));
	PeriodsList.Add("WeekPeriod",    NStr("vi = 'Kỳ tuần';
											|ru = 'Период неделя';
											|en = 'Period week'; fa = 'دوره هفته';
											|it = 'Periodo settimana';
											|pl = 'Okres tydzień';
											|tr = 'Dönem hafta'"));
	PeriodsList.Add("TenDaysPeriod",    NStr("vi = 'Kỳ 10 ngày';
											|ru = 'Период декада';
											|en = 'Period ten-day'; fa = 'دوره دهه';
											|it = 'Periodo decade';
											|pl = 'Okres dekada';
											|tr = 'Dönem on yıllık'"));
	PeriodsList.Add("MonthPeriod",     NStr("vi = 'Kỳ tháng';
											|ru = 'Период месяц';
											|en = 'Period month'; fa = 'دوره ماه';
											|it = 'Periodo mese';
											|pl = 'Okres miesiąc';
											|tr = 'Dönem ay'"));
	PeriodsList.Add("QuarterPeriod",   NStr("vi = 'Kỳ quý';
											|ru = 'Период квартал';
											|en = 'Period quarter'; fa = 'دوره فصل';
											|it = 'Periodo trimestre';
											|pl = 'Okres kwartał';
											|tr = 'Dönem çeyrek'"));
	PeriodsList.Add("HalfYearPeriod", NStr("vi = 'Kỳ nửa năm';
											|ru = 'Период полугодие';
											|en = 'Period half-year'; fa = 'دوره نیم‌سال';
											|it = 'Periodo sei mesi';
											|pl = 'Okres półrocze';
											|tr = 'Dönem yarıyıl'"));
	PeriodsList.Add("YearPeriod",       NStr("vi = 'Kỳ năm';
											|ru = 'Период год';
											|en = 'Period year'; fa = 'دوره سال';
											|it = 'Periodo anno';
											|pl = 'Okres rok';
											|tr = 'Dönem yıl'"));
	
	FolderName = "TimeIntervals";
	DataSetFieldsList = New ValueList;
	DataSetFieldsFolder = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetFieldFolder"));
	DataSetFieldsFolder.Title   = NStr("vi = 'Kỳ';
										|ru = 'Периоды';
										|en = 'Periods'; fa = 'دوره‌ها';
										|it = 'Периоды';
										|pl = 'Periods';
										|tr = 'Dönemler'");
	DataSetFieldsFolder.DataPath = FolderName;
	
	PeriodType = DataCompositionPeriodType.Main;
	
	For Each Period In PeriodsList Do
		DataSetField = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
		DataSetField.Field        = Period.Value;
		DataSetField.Title   = Period.Presentation;
		DataSetField.DataPath = FolderName + "." + Period.Value;
		DataSetField.Role.PeriodType = PeriodType;
		DataSetField.Role.PeriodNumber = ?(ThereIsFieldLogger, PeriodsList.IndexOf(Period) + 2, PeriodsList.IndexOf(Period));
		DataSetFieldsList.Add(DataSetField);
		PeriodType = DataCompositionPeriodType.Additional;
		
		If Period.Value = "SecondPeriod" Then
			DataSetField.Role.PeriodType = DataCompositionPeriodType.Main;
			DataSetField.Role.IgnoreNULLValues = True;
		EndIf;
		
	EndDo;
	
	Return DataSetFieldsList;
	
EndFunction

// Add field to data set.
// 
// Parameters:
//  DataSet - DataCompositionSchemaDataSetQuery
//  Field - String
//  Title - String
//  DataPath - Undefined
//              - String
//
// Returns:
//  DataCompositionSchemaDataSetField
//
Function AddDataSetField(DataSet, Field, Title = "", DataPath = Undefined)
	
	If DataPath = Undefined Then
		DataPath = Field;
	EndIf;
	
	DataSetField = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
	DataSetField.Field        = Field;
	DataSetField.Title   = Title;
	DataSetField.DataPath = DataPath;
	Return DataSetField;
	
EndFunction

// Add total field to data composition schema. If the Expression parameter is not specified, Sum(PathToData) is used.
Function AddTotalField(DataCompositionSchema, DataPath, Expression = Undefined)
	
	If Expression = Undefined Then
		Expression = "Sum(" + DataPath + ")";
	EndIf;
	
	TotalField = DataCompositionSchema.TotalFields.Add();
	TotalField.DataPath = DataPath;
	TotalField.Expression = Expression;
	
	Return TotalField;
	
EndFunction

// Adds total fields.
// 
// Parameters:
//  ReportParameters - See FixedParameters
//  DCSettings - DataCompositionSettings
//
Procedure AddIndicators(ReportParameters, DCSettings)
	
	If ReportParameters.TableName = "BalanceAndTurnovers" Then
		SelectedFieldsOpeningBalance = DCSettings.Selection.Items.Add(Type("DataCompositionSelectedFieldGroup"));
		SelectedFieldsOpeningBalance.Title = NStr("vi = 'Dư đầu';
													|ru = 'Нач. остаток';
													|en = 'Open balance'; fa = 'مانده افتتاحیه';
													|it = 'Saldo iniziale';
													|pl = 'Saldo początkowe';
													|tr = 'Açılış bakiyesi'");
		SelectedFieldsOpeningBalance.Placement = DataCompositionFieldPlacement.Horizontally;
		If ReportParameters.MetadataObjectType = "AccumulationRegisters" Then
			SelectedFieldsReceipt = DCSettings.Selection.Items.Add(Type("DataCompositionSelectedFieldGroup"));
			SelectedFieldsReceipt.Title = NStr("vi = 'Nhập';
												|ru = 'Приход';
												|en = 'Income'; fa = 'درآمد';
												|it = 'Entrata';
												|pl = 'Wpłynięcie';
												|tr = 'Giriş'");
			SelectedFieldsReceipt.Placement = DataCompositionFieldPlacement.Horizontally;
			SelectedFieldsExpense = DCSettings.Selection.Items.Add(Type("DataCompositionSelectedFieldGroup"));
			SelectedFieldsExpense.Title = NStr("vi = 'Xuất';
												|ru = 'Расход';
												|en = 'Expense'; fa = 'هزینه';
												|it = 'Uscita';
												|pl = 'Rozchód';
												|tr = 'Çıkış'");
			SelectedFieldsExpense.Placement = DataCompositionFieldPlacement.Horizontally;
		ElsIf ReportParameters.MetadataObjectType = "AccountingRegisters" Then
			SelectedFieldsTurnovers = DCSettings.Selection.Items.Add(Type("DataCompositionSelectedFieldGroup"));
			SelectedFieldsTurnovers.Title = NStr("vi = 'Phát sinh';
												|ru = 'Обороты';
												|en = 'Turnovers'; fa = 'گردش‌ها';
												|it = 'Fatturati';
												|pl = 'Turnovers';
												|tr = 'Cirolar'");
			SelectedFieldsTurnovers.Placement = DataCompositionFieldPlacement.Horizontally;
		EndIf;
		SelectedFieldsClosingBalance = DCSettings.Selection.Items.Add(Type("DataCompositionSelectedFieldGroup"));
		SelectedFieldsClosingBalance.Title = NStr("vi = 'Dư cuối';
													|ru = 'Кон. остаток';
													|en = 'Close balance'; fa = 'مانده اختتامیه';
													|it = 'Saldo finale';
													|pl = 'Saldo końcowe';
													|tr = 'Kapanış bakiyesi'");
		SelectedFieldsClosingBalance.Placement = DataCompositionFieldPlacement.Horizontally;
	EndIf;
	
	MetadataObject = Metadata[ReportParameters.MetadataObjectType][ReportParameters.MetadataObjectName]; // MetadataObjectInformationRegister, MetadataObjectAccumulationRegister
	If ReportParameters.MetadataObjectType = "AccumulationRegisters" Then
		For Each Dimension In MetadataObject.Dimensions Do
			If Not Common.MetadataObjectAvailableByFunctionalOptions(Dimension) Then 
				Continue;
			EndIf;
			
			SelectedFields = DCSettings.Selection;
			ReportsServer.AddSelectedField(SelectedFields, Dimension.Name);
		EndDo;
		For Each Resource In MetadataObject.Resources Do
			If Not Common.MetadataObjectAvailableByFunctionalOptions(Resource) Then 
				Continue;
			EndIf;
			
			SelectedFields = DCSettings.Selection;
			If ReportParameters.TableName = "Turnovers" Then
				ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "Turnover", Resource.Synonym);
			ElsIf ReportParameters.TableName = "Balance" Then
				ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "Balance", Resource.Synonym);
			ElsIf ReportParameters.TableName = "BalanceAndTurnovers" Then
				ReportsServer.AddSelectedField(SelectedFieldsOpeningBalance, Resource.Name + "OpeningBalance", Resource.Synonym);
				ReportsServer.AddSelectedField(SelectedFieldsReceipt, Resource.Name + "Receipt", Resource.Synonym);
				ReportsServer.AddSelectedField(SelectedFieldsExpense, Resource.Name + "Expense", Resource.Synonym);
				ReportsServer.AddSelectedField(SelectedFieldsClosingBalance, Resource.Name + "ClosingBalance", Resource.Synonym);
			ElsIf ReportParameters.TableName = "" Then
				ReportsServer.AddSelectedField(SelectedFields, Resource.Name);
			EndIf;
		EndDo;
	ElsIf ReportParameters.MetadataObjectType = "InformationRegisters" Or ReportParameters.MetadataObjectType = "CalculationRegisters" Then
		For Each Dimension In MetadataObject.Dimensions Do
			If Not Common.MetadataObjectAvailableByFunctionalOptions(Dimension) Then
				Continue;
			EndIf;
			
			SelectedFields = DCSettings.Selection;
			ReportsServer.AddSelectedField(SelectedFields, Dimension.Name);
		EndDo;
		For Each Resource In MetadataObject.Resources Do
			If Not Common.MetadataObjectAvailableByFunctionalOptions(Resource) 
			   Or Resource.Type.ContainsType(Type("ValueStorage")) Then 
				Continue;
			EndIf;
			
			SelectedFields = DCSettings.Selection;
			ReportsServer.AddSelectedField(SelectedFields, Resource.Name);
		EndDo;
	ElsIf ReportParameters.MetadataObjectType = "AccountingRegisters" Then
		For Each Resource In MetadataObject.Resources Do
			If Not Common.MetadataObjectAvailableByFunctionalOptions(Resource) Then 
				Continue;
			EndIf;
			
			SelectedFields = DCSettings.Selection;
			If ReportParameters.TableName = "Turnovers" Then
				ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "TurnoverDr", Resource.Synonym + " " + NStr("vi = 'phát sinh Nợ';
																															|ru = 'оборот Дт';
																															|en = 'Dr turnover'; fa = 'گردش بدهکار';
																															|it = 'Fatturato a debito';
																															|pl = 'Obrót Wn';
																															|tr = 'Borç ciro'"));
				ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "TurnoverCr", Resource.Synonym + " " + NStr("vi = 'phát sinh Có';
																															|ru = 'оборот Кт';
																															|en = 'Cr turnover'; fa = 'گردش بستانکار';
																															|it = 'Fatturato a credito';
																															|pl = 'obrót Ma';
																															|tr = 'Alacak ciro'"));
			ElsIf ReportParameters.TableName = "DrCrTurnovers" Then
				If Resource.Balance Then
					ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "Turnover", Resource.Synonym + " " + NStr("vi = 'phát sinh';
																															|ru = 'оборот';
																															|en = 'turnover'; fa = 'turnover';
																															|it = 'fatturato';
																															|pl = 'turnover';
																															|tr = 'ciro'"));
				Else
					ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "TurnoverDr", Resource.Synonym + " " + NStr("vi = 'phát sinh Nợ';
																																|ru = 'оборот Дт';
																																|en = 'Dr turnover'; fa = 'گردش بدهکار';
																																|it = 'Fatturato a debito';
																																|pl = 'Obrót Wn';
																																|tr = 'Borç ciro'"));
					ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "TurnoverCr", Resource.Synonym + " " + NStr("vi = 'phát sinh Có';
																																|ru = 'оборот Кт';
																																|en = 'Cr turnover'; fa = 'گردش بستانکار';
																																|it = 'Fatturato a credito';
																																|pl = 'obrót Ma';
																																|tr = 'Alacak ciro'"));
				EndIf;
			ElsIf ReportParameters.TableName = "Balance" Then
				ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "BalanceDr", Resource.Synonym + " " + NStr("vi = 'dư Nợ';
																															|ru = 'ост. Дт';
																															|en = 'Dr balance'; fa = 'مانده بدهکار';
																															|it = 'Saldo addebito';
																															|pl = 'sald. Wn';
																															|tr = 'Borç bakiye'"));
				ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "BalanceCr", Resource.Synonym + " " + NStr("vi = 'dư Có';
																															|ru = 'ост. Кт';
																															|en = 'Cr balance'; fa = 'Cr balance';
																															|it = 'Saldo accredito';
																															|pl = 'zap. Ma';
																															|tr = 'Alacak bakiye'"));
			ElsIf ReportParameters.TableName = "BalanceAndTurnovers" Then
				ReportsServer.AddSelectedField(SelectedFieldsOpeningBalance, Resource.Name + "OpeningBalanceDr", Resource.Synonym + " " + NStr("vi = 'dư đầu Nợ';
																																				|ru = 'нач. ост. Дт';
																																				|en = 'Dr open balance'; fa = 'Dr open balance';
																																				|it = 'Saldo iniziale addebito';
																																				|pl = 'sald. pocz. Wn';
																																				|tr = 'Başlangıç borç bakiyesi'"));
				ReportsServer.AddSelectedField(SelectedFieldsOpeningBalance, Resource.Name + "OpeningBalanceCr", Resource.Synonym + " " + NStr("vi = 'dư đầu Có';
																																				|ru = 'нач. ост. Кт';
																																				|en = 'Cr open balance'; fa = 'Cr open balance';
																																				|it = 'Saldo iniziale accredito';
																																				|pl = 'pocz. zap. Ma';
																																				|tr = 'Başlangıç alacak bakiyesi'"));
				ReportsServer.AddSelectedField(SelectedFieldsTurnovers, Resource.Name + "TurnoverDr", Resource.Synonym + " " + NStr("vi = 'phát sinh Nợ';
																																	|ru = 'оборот Дт';
																																	|en = 'Dr turnover'; fa = 'گردش بدهکار';
																																	|it = 'Fatturato a debito';
																																	|pl = 'Obrót Wn';
																																	|tr = 'Borç ciro'"));
				ReportsServer.AddSelectedField(SelectedFieldsTurnovers, Resource.Name + "TurnoverCr", Resource.Synonym + " " + NStr("vi = 'phát sinh Có';
																																	|ru = 'оборот Кт';
																																	|en = 'Cr turnover'; fa = 'گردش بستانکار';
																																	|it = 'Fatturato a credito';
																																	|pl = 'obrót Ma';
																																	|tr = 'Alacak ciro'"));
				ReportsServer.AddSelectedField(SelectedFieldsClosingBalance, Resource.Name + "ClosingBalanceDr", " " + Resource.Synonym + NStr("vi = 'dư cuối Nợ';
																																				|ru = 'кон. ост. Дт';
																																				|en = 'Dr close balance'; fa = 'Dr close balance';
																																				|it = 'Saldo finale addebito';
																																				|pl = 'kon. zap. Wn';
																																				|tr = 'Son borç bakiyesi'"));
				ReportsServer.AddSelectedField(SelectedFieldsClosingBalance, Resource.Name + "ClosingBalanceCr", " " + Resource.Synonym + NStr("vi = 'dư cuối Có';
																																				|ru = 'кон. ост. Кт';
																																				|en = 'Cr close balance'; fa = 'Cr close balance';
																																				|it = 'Saldo finale accredito';
																																				|pl = 'kon. zap. Ma';
																																				|tr = 'Son alacak bakiyesi'"));
			ElsIf ReportParameters.TableName = "RecordsWithExtDimensions" Or ReportParameters.TableName = "" Then
				If Resource.Balance Then
					ReportsServer.AddSelectedField(SelectedFields, Resource.Name, Resource.Synonym);
				Else
					ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "Dr", Resource.Synonym + " " + NStr("vi = 'Nợ';
																														|ru = 'Дт';
																														|en = 'Dr'; fa = 'بد';
																														|it = 'Debito';
																														|pl = 'Wn';
																														|tr = 'Borç'"));
					ReportsServer.AddSelectedField(SelectedFields, Resource.Name + "Cr", Resource.Synonym + " " + NStr("vi = 'Có';
																														|ru = 'Кт';
																														|en = 'Cr'; fa = 'بس';
																														|it = 'Credito';
																														|pl = 'Ma';
																														|tr = 'Alacak'"));
				EndIf;
			EndIf;
		EndDo;
	ElsIf ReportParameters.MetadataObjectType = "Documents" 
		Or ReportParameters.MetadataObjectType = "Tasks"
		Or ReportParameters.MetadataObjectType = "BusinessProcesses"
		Or ReportParameters.MetadataObjectType = "Catalogs" Then
		If ReportParameters.TableName <> "" Then
			MetadataObject = MetadataObject.TabularSections[ReportParameters.TableName];
		EndIf;
		SelectedFields = DCSettings.Selection;
		ReportsServer.AddSelectedField(SelectedFields, "Ref");
		For Each Attribute In MetadataObject.Attributes Do
			If Attribute.Type.ContainsType(Type("ValueStorage")) Then
				Continue;
			EndIf;
			If Common.MetadataObjectAvailableByFunctionalOptions(Attribute) Then 
				ReportsServer.AddSelectedField(SelectedFields, Attribute.Name);
			EndIf;
		EndDo;
	ElsIf ReportParameters.MetadataObjectType = "ChartsOfCalculationTypes" Then
		If ReportParameters.TableName = "" Then
			For Each Attribute In MetadataObject.Attributes Do
				If Not Common.MetadataObjectAvailableByFunctionalOptions(Attribute) 
				   Or Attribute.Type.ContainsType(Type("ValueStorage")) Then 
					Continue;
				EndIf;
				
				SelectedFields = DCSettings.Selection;
				ReportsServer.AddSelectedField(SelectedFields, Attribute.Name);
			EndDo;
		Else
			For Each Attribute In MetadataObject.StandardAttributes Do
				SelectedFields = DCSettings.Selection;
				ReportsServer.AddSelectedField(SelectedFields, Attribute.Name);
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

// Generates the structure of data composition settings.
//
// Parameters:
//  ReportParameters - Structure - Description of a metadata object that is a data source
//  Schema - DataCompositionSchema - Main schema of the report data composition.
//  Settings - DataCompositionSettings - Settings whose structure is being generated.
//
Procedure GenerateStructure(ReportParameters, Schema, Settings)
	Settings.Structure.Clear();
	
	Structure = Settings.Structure.Add(Type("DataCompositionGroup"));
	
	FieldsTypes = StrSplit("Dimensions@Resources", "@", False);
	
	SourcesFieldsTypes = New Map();
	SourcesFieldsTypes.Insert("InformationRegisters", FieldsTypes);
	SourcesFieldsTypes.Insert("AccumulationRegisters", FieldsTypes);
	SourcesFieldsTypes.Insert("AccountingRegisters", FieldsTypes);
	SourcesFieldsTypes.Insert("CalculationRegisters", FieldsTypes);
	
	SourceFieldsTypes = SourcesFieldsTypes[ReportParameters.MetadataObjectType];
	If SourceFieldsTypes <> Undefined Then 
		SpecifyFieldsSuffixes = ReportParameters.MetadataObjectType = "AccountingRegisters"
			And (ReportParameters.TableName = ""
				Or ReportParameters.TableName = "DrCrTurnovers"
				Or ReportParameters.TableName = "RecordsWithExtDimensions");
		
		For Each SourceFieldsType In SourceFieldsTypes Do 
			GroupFields = Structure.GroupFields.Items;
			
			SourceMetadata = Metadata[ReportParameters.MetadataObjectType][ReportParameters.MetadataObjectName];
			For Each FieldMetadata In SourceMetadata[SourceFieldsType] Do
				If Not Common.MetadataObjectAvailableByFunctionalOptions(FieldMetadata) Then 
					Continue;
				EndIf;
				
				If ReportParameters.MetadataObjectType = "AccountingRegisters"
					And FieldMetadata.AccountingFlag <> Undefined Then 
					Continue;
				EndIf;
				
				If SourceFieldsType = "Resources"
					And FieldMetadata.Type.ContainsType(Type("Number")) Then 
					Continue;
				EndIf;
				
				If FieldMetadata.Type.ContainsType(Type("ValueStorage")) Then 
					Continue;
				EndIf;
				
				If SpecifyFieldsSuffixes Then
					If FieldMetadata.Balance Or (ReportParameters.MetadataObjectType = "AccountingRegisters"
						And Not SourceMetadata.Correspondence) Then
						FieldsSuffixes = StrSplit("", "@");
					Else
						FieldsSuffixes = StrSplit("Dr@Cr", "@", False);
					EndIf;
				Else
					FieldsSuffixes = StrSplit("", "@");
				EndIf;
				
				For Each Suffix In FieldsSuffixes Do 
					GroupingField = GroupFields.Add(Type("DataCompositionGroupField"));
					GroupingField.Field = New DataCompositionField(FieldMetadata.Name + Suffix);
					GroupingField.Use = True;
				EndDo;
			EndDo;
		EndDo;
	EndIf;
	
	Structure.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	Structure.Order.Items.Add(Type("DataCompositionAutoOrderItem"));
EndProcedure

#Region ManagingBasicSchemaConfiguredInUserSettings

Function DataCompositionSchema(FixedParameters) Export 
	DataCompositionSchema = GetTemplate("MainDataCompositionSchema");
	DataCompositionSchema.TotalFields.Clear();
	
	DataSource = DataCompositionSchema.DataSources.Add();
	DataSource.Name = "DataSource1";
	DataSource.DataSourceType = "Local";
	
	DataSet = DataCompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.Name = "DataSet1";
	DataSet.DataSource = DataSource.Name;
	DataSet.Query = TextOfQueryByMetadata(FixedParameters);
	DataSet.AutoFillAvailableFields = True;
	
	AddTotals(FixedParameters, DataCompositionSchema);
	
	If FixedParameters.MetadataObjectType = "Catalogs"
		Or FixedParameters.MetadataObjectType = "ChartsOfCalculationTypes" 
		Or (FixedParameters.MetadataObjectType = "InformationRegisters"
			And Metadata[FixedParameters.MetadataObjectType][FixedParameters.MetadataObjectName].InformationRegisterPeriodicity 
			= Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical) Then
		DataCompositionSchema.Parameters.Period.UseRestriction = True;
	EndIf;
	
	AvailableTables = AvailableTables(FixedParameters.MetadataObjectType, FixedParameters.MetadataObjectName);
	If AvailableTables.Count() < 2 Then
		DataCompositionSchema.Parameters.TableName.UseRestriction = True;
	EndIf;
	
	Return DataCompositionSchema;
EndFunction

// Sets the default settings.
//
// Parameters:
//  Report - ReportObject
//  FixedParameters - See FixedParameters
//  Settings - DataCompositionSettings
//  UserSettings - DataCompositionUserSettings
//
Procedure CustomizeStandardSettings(Report, FixedParameters, Settings, UserSettings) Export 
	ReportInitialized = CommonClientServer.StructureProperty(
		Settings.AdditionalProperties, "ReportInitialized", False);    
		
	If ReportInitialized Then 
		Return;
	EndIf;
	
	FixedParameterDisplayModes = FixedParameterDisplayModes(Settings);
	
	Report.SettingsComposer.LoadSettings(Report.DataCompositionSchema.DefaultSettings);
	
	Settings = Report.SettingsComposer.Settings;
	Settings.Selection.Items.Clear();
	Settings.Structure.Clear();
	
	SetTheDisplayModesOfFixedParameters(Settings, FixedParameterDisplayModes);
	
	AddIndicators(FixedParameters, Settings);
	GenerateStructure(FixedParameters, Report.DataCompositionSchema, Settings);
	
	SetFixedParameters(Report, FixedParameters, Settings, UserSettings);
	
	Settings.AdditionalProperties.Insert("ReportInitialized", True);
EndProcedure

#EndRegion

#Region ManagingArbitrarySchemaFromFile

// Returns the data composition schema being imported.
//
// Parameters:
//  ImportedSchema - BinaryData
//
// Returns:
//  DataCompositionSchema
//
Function ExtractSchemaFromBinaryData(ImportedSchema) Export
	
	FullFileName = GetTempFileName();
	ImportedSchema.Write(FullFileName);
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(FullFileName);
	
	DCSchema = XDTOSerializer.ReadXML(XMLReader, Type("DataCompositionSchema"));
	
	XMLReader.Close();
	XMLReader = Undefined;
	
	DeleteFiles(FullFileName);
	
	If DCSchema.DefaultSettings.AdditionalProperties.Property("DataCompositionSchema") Then
		DCSchema.DefaultSettings.AdditionalProperties.DataCompositionSchema = Undefined;
	EndIf;
	
	Return DCSchema;
	
EndFunction

Procedure SetStandardImportedSchemaSettings(Report, SchemaBinaryData, Settings, UserSettings) Export 
	If CommonClientServer.StructureProperty(Settings.AdditionalProperties, "ReportInitialized", False) Then 
		Return;
	EndIf;
	
	Settings = Report.DataCompositionSchema.DefaultSettings;
	Settings.AdditionalProperties.Insert("DataCompositionSchema", SchemaBinaryData);
	Settings.AdditionalProperties.Insert("ReportInitialized",  True);
EndProcedure

#EndRegion

#Region ReportOptionDataSourceManagement

// Returns the report option settings with the set DataSource parameter.
//
// Parameters:
//  Variant - CatalogObject.ReportsOptions - Report option settings storage.
//
// Returns:
//   DataCompositionSettings, Undefined - Updated settings. If the update failed, Undefined.
//                                            
//
Function OptionSettings(Variant) Export
	Try
		OptionSettings = Variant.Settings.Get(); // DataCompositionSettings
	Except
		// Couldn't deserialize the value storage:
		//  Perhaps, a reference to a non-existent type is found.
		Return Undefined;
	EndTry;
	
	If OptionSettings = Undefined Then 
		Return Undefined;
	EndIf;
	
	DataParameters = OptionSettings.DataParameters.Items;
	
	ParametersRequired = New Structure(
		"MetadataObjectType, FullMetadataObjectName, MetadataObjectName, DataSource");
	For Each Parameter In ParametersRequired Do 
		FoundParameter = DataParameters.Find(Parameter.Key);
		If FoundParameter <> Undefined Then 
			ParametersRequired[Parameter.Key] = FoundParameter.Value;
		EndIf;
	EndDo;
	
	// If option settings contain a parameter with a non-relevant name, the name will be updated.
	If ValueIsFilled(ParametersRequired.FullMetadataObjectName) Then 
		ParametersRequired.MetadataObjectName = ParametersRequired.FullMetadataObjectName;
	EndIf;
	ParametersRequired.Delete("FullMetadataObjectName");
	
	If Not ValueIsFilled(ParametersRequired.DataSource) Then 
		ParametersRequired.DataSource = DataSource(
			ParametersRequired.MetadataObjectType, ParametersRequired.MetadataObjectName);
		If ParametersRequired.DataSource = Undefined Then 
			Return Undefined;
		EndIf;
	EndIf;
	
	ParametersToSet = New Structure("DataSource, MetadataObjectName");
	FillPropertyValues(ParametersToSet, ParametersRequired);
	
	ObjectName = Common.ObjectAttributeValue(ParametersRequired.DataSource, "Name");
	If ObjectName <> ParametersToSet.MetadataObjectName Then 
		ParametersToSet.MetadataObjectName = ObjectName;
	EndIf;
	
	For Each Parameter In ParametersToSet Do 
		FoundParameter = DataParameters.Find(Parameter.Key);
		If FoundParameter = Undefined Then 
			DataParameter = DataParameters.Add();
			DataParameter.Parameter = New DataCompositionParameter(Parameter.Key);
			DataParameter.Value = Parameter.Value;
			DataParameter.Use = True;
		Else
			OptionSettings.DataParameters.SetParameterValue(Parameter.Key, Parameter.Value);
		EndIf;
	EndDo;
	
	Return OptionSettings;
EndFunction

// Returns report data source
//
// Parameters:
//  ManagerType - String - Metadata object manager presentation.
//                 For example, "Catalogs" or "InformationRegisters".
//  ObjectName  - String - Short name of the metadata object.
//                For example, "Currencies" or "ExchangeRates".
//
// Returns:
//   - CatalogRef.MetadataObjectIDs - Reference to the found catalog item.
//   - Undefined
//
Function DataSource(ManagerType, ObjectName)
	ObjectType = ObjectTypeByManagerType(ManagerType);
	FullObjectName = ObjectType + "." + ObjectName;
	If Common.MetadataObjectByFullName(FullObjectName) = Undefined Then 
		WriteLogEvent(NStr("vi = 'Phương án báo cáo: Cài đặt nguồn dữ liệu của báo cáo đa năng';
							|ru = 'Варианты отчетов.Установка источника данных универсального отчета';
							|en = 'Report options. Configure universal report data source'; fa = 'Report options. Configure universal report data source';
							|it = 'Varianti di report. Impostazione della fonte di dati del report universale';
							|pl = 'Opcje raportów.Instalacja źródła danych powszechnego raportu';
							|tr = 'Rapor seçenekleri. Evrensel rapor veri kaynağını ayarlama'", 
			Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			Metadata.Catalogs.ReportsOptions,,
			StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thiếu nguồn dữ liệu %1';
																			|ru = 'Источник данных %1 отсутствует';
																			|en = 'Cannot find data source for %1'; fa = 'Cannot find data source for %1';
																			|it = 'Nessuna fonte di dati %1';
																			|pl = 'Brakuje źródła danych %1';
																			|tr = 'Veriler kaynağı mevcut değil %1'"), 
				FullObjectName));
		Return Undefined;
	EndIf;
	
	Return Common.MetadataObjectID(FullObjectName);
EndFunction

Function DataSourceMetadata(DataSource, Context)
	
	Try
		MetadataObject = Common.MetadataObjectByID(DataSource);
	Except
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể tạo báo cáo theo nguyên nhân: %1 %2';
				|ru = 'Отчет не может быть сформирован по причине: %1 %2';
				|en = 'Cannot generate the report due to: %1%2'; fa = 'Cannot generate the report due to: %1%2';
				|it = 'Отчет не может быть сформирован по причине: %1 %2';
				|pl = 'Cannot generate the report due to: %1%2';
				|tr = 'Rapor şu nedenden dolayı oluşturulamaz: %1 %2'"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo()),
			NStr("vi = 'Hãy chọn danh mục hoặc chứng từ khác.';
				|ru = 'Выберите другой справочник или документ.';
				|en = 'Select another catalog or document.'; fa = 'Select another catalog or document.';
				|it = 'Выберите другой справочник или документ.';
				|pl = 'Select another catalog or document.';
				|tr = 'Başka bir katalog veya belge seçin.'"));
		WriteLogEvent(NStr("vi = 'Tạo phương án của báo cáo đa năng';
							|ru = 'Формирование варианта универсального отчета';
							|en = 'Generate a universal report option'; fa = 'Generate a universal report option';
							|it = 'Формирование варианта универсального отчета';
							|pl = 'Generate a universal report option';
							|tr = 'Evrensel rapor seçeneğinin oluşturulması'", Common.DefaultLanguageCode()),
			EventLogLevel.Warning, Metadata.Reports.UniversalReport,, MessageText);
		If TypeOf(Context) = Type("ClientApplicationForm") Then
			RecommendationText = NStr("vi = 'Không thể tạo báo cáo. Hãy chọn danh mục hoặc chứng từ khác.';
										|ru = 'Отчет не может быть сформирован. Выберите другой справочник или документ.';
										|en = 'Cannot generate the report. Select another catalog or document.'; fa = 'Cannot generate the report. Select another catalog or document.';
										|it = 'Отчет не может быть сформирован. Выберите другой справочник или документ.';
										|pl = 'Cannot generate the report. Select another catalog or document.';
										|tr = 'Rapor oluşturulamaz. Başka bir katalog veya belge seçin.'");
			ReportsClientServer.DisplayReportState(
				Context, RecommendationText);
			Common.MessageToUser(MessageText);
		Else
			Common.MessageToUser(MessageText);
		EndIf;
		Return Undefined;
	EndTry;
	
	Return MetadataObject;
	
EndFunction

// Returns the type of metadata object by the matching manager type
//
// Parameters:
//  ManagerType - String - Metadata object manager presentation.
//                 For example, "Catalogs" or "InformationRegisters".
//
// Returns:
//   String - Metadata object type. For example, "Catalog" or "InformationRegister".
//
Function ObjectTypeByManagerType(ManagerType)
	Types = New Map;
	Types.Insert("Catalogs", "Catalog");
	Types.Insert("Documents", "Document");
	Types.Insert("DataProcessors", "DataProcessor");
	Types.Insert("ChartsOfCharacteristicTypes", "ChartOfCharacteristicTypes");
	Types.Insert("AccountingRegisters", "AccountingRegister");
	Types.Insert("AccumulationRegisters", "AccumulationRegister");
	Types.Insert("CalculationRegisters", "CalculationRegister");
	Types.Insert("InformationRegisters", "InformationRegister");
	Types.Insert("BusinessProcesses", "BusinessProcess");
	Types.Insert("DocumentJournals", "DocumentJournal");
	Types.Insert("Tasks", "Task");
	Types.Insert("Reports", "Report");
	Types.Insert("Constants", "Constant");
	Types.Insert("Enums", "Enum");
	Types.Insert("ChartsOfCalculationTypes", "ChartOfCalculationTypes");
	Types.Insert("ExchangePlans", "ExchangePlan");
	Types.Insert("ChartsOfAccounts", "ChartOfAccounts");
	
	Return ?(Types[ManagerType] = Undefined, "", Types[ManagerType]);
EndFunction

#EndRegion

#Region StandardTitle

// Parameters:
//  Context - ClientApplicationForm
//           - Structure
//  Settings - DataCompositionSettings
//  FixedParameters - Structure
//  AvailableValues - ValueList
//
Procedure SetStandardReportHeader(Context, Settings, FixedParameters, AvailableValues) Export 
	
	If Not SettingTheStandardReportTitleIsAvailable(Context) Then 
		Return;
	EndIf;
	
	ParameterValues = StandardHeaderParametersValues(Context, FixedParameters, AvailableValues);
	
	PeriodPresentation = ReportPeriodView(ParameterValues.Period);
	
	If ParameterValues.MetadataObjectType = Undefined
		And ParameterValues.MetadataObjectName = Undefined
		And ParameterValues.TableName = Undefined Then 
		
		Title = Metadata.Reports.UniversalReport.Presentation();
		
	ElsIf ParameterValues.TableName = Undefined
		And Not ValueIsFilled(PeriodPresentation) Then 
		
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Báo cáo đa năng: %1 ""%2""';
				|ru = 'Универсальный отчет: %1 ""%2""';
				|en = 'Universal report: %1 ""%2""'; fa = 'Universal report: %1 ""%2""';
				|it = 'Report universale: %1 ""%2""';
				|pl = 'Raport uniwersalny: %1 ""%2""';
				|tr = 'Evrensel rapor: %1 ""%2""'"),
			ParameterValues.MetadataObjectType,
			ParameterValues.MetadataObjectName);
		
	ElsIf ParameterValues.TableName <> Undefined
		And Not ValueIsFilled(PeriodPresentation) Then 
		
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Báo cáo đa năng: %1 ""%2""- bảng ""%3""';
				|ru = 'Универсальный отчет: %1 ""%2"" - таблица ""%3""';
				|en = 'Universal report: %1 ""%2"" - table ""%3""'; fa = 'Universal report: %1 ""%2"" - table ""%3""';
				|it = 'Report universale: %1 ""%2"" - tabella ""%3""';
				|pl = 'Uniwersalny raport: %1 ""%2"" - tabela ""%3""';
				|tr = 'Evrensel rapor: %1 ""%2""-tablo ""%3""'"),
			ParameterValues.MetadataObjectType,
			ParameterValues.MetadataObjectName,
			ParameterValues.TableName);
		
	ElsIf ParameterValues.TableName = Undefined
		And ValueIsFilled(PeriodPresentation) Then 
		
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Báo cáo đa năng: %1 ""%2"" cho ""%3""';
				|ru = 'Универсальный отчет: %1 ""%2"" за %3';
				|en = 'Universal report: %1 ""%2"" for %3'; fa = 'Universal report: %1 ""%2"" for %3';
				|it = 'Report universale: %1 ""%2"" per %3';
				|pl = 'Raport uniwersalny: %1 ""%2"" za %3';
				|tr = 'Evrensel rapor: %1 ""%2 için %3'"),
			ParameterValues.MetadataObjectType,
			ParameterValues.MetadataObjectName,
			PeriodPresentation);
	Else
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Báo cáo đa năng: %1 ""%2""- bảng ""%3"" trong %4';
				|ru = 'Универсальный отчет: %1 ""%2"" - таблица ""%3"" за %4';
				|en = 'Universal report: %1 ""%2"" - table ""%3"" for %4'; fa = 'Universal report: %1 ""%2"" - table ""%3"" for %4';
				|it = 'Report universale: %1 ""%2""- tabella ""%3"" per %4';
				|pl = 'Uniwersalny raport: %1 ""%2"" - tabela ""%3"" za %4';
				|tr = 'Evrensel rapor: %1 ""%2-tablo  ""%3"" için%4'"),
			ParameterValues.MetadataObjectType,
			ParameterValues.MetadataObjectName,
			ParameterValues.TableName,
			PeriodPresentation);
	EndIf;
	
	TitleSetInteractively = CommonClientServer.StructureProperty(
		Settings.AdditionalProperties, "TitleSetInteractively", False);
	
	If Not TitleSetInteractively Then 
		HeaderParameter = Settings.OutputParameters.Items.Find("Title");
		HeaderParameter.Value = Title;
	EndIf;
	
	If TypeOf(Context) = Type("ClientApplicationForm")
		And Context.ReportFormType = ReportFormType.Main Then 
		
		Context.Title = Title;
		Context.ReportCurrentOptionDescription = Title;
	EndIf;
	
EndProcedure

Function SettingTheStandardReportTitleIsAvailable(Context)
	
	If TypeOf(Context) = Type("ClientApplicationForm") Then 
		ReportVariant = Context.ReportSettings.OptionRef;
	Else
		ReportVariant = Context.OptionRef1;
	EndIf;
	
	Return ReportsOptions.IsPredefinedReportOption(ReportVariant);
	
EndFunction

Function StandardHeaderParametersValues(Context, FixedParameters, AvailableValues)
	
	ParameterValues = New Structure("MetadataObjectType, MetadataObjectName, TableName, Period");
	
	If TypeOf(Context) = Type("ClientApplicationForm") Then 
		SchemaURL = CommonClientServer.StructureProperty(Context.ReportSettings, "SchemaURL");
	Else
		SchemaURL = CommonClientServer.StructureProperty(Context, "SchemaURL");
	EndIf;
	
	Schema = GetFromTempStorage(SchemaURL); // DataCompositionSchema
	
	For Each Item In ParameterValues Do 
		
		FoundParameter = Schema.Parameters.Find(Item.Key);
		If FoundParameter = Undefined
			Or FoundParameter.UseRestriction Then 
			
			Continue;
		EndIf;
		
		ParameterValue = FixedParameters[Item.Key];
		
		AvailableParameterValues = CommonClientServer.StructureProperty(
			AvailableValues, Item.Key);
		
		If  ValueIsFilled(ParameterValue)
			And TypeOf(AvailableParameterValues) = Type("ValueList") Then 
			
			ValueFound = AvailableParameterValues.FindByValue(ParameterValue);
			ParameterValues[Item.Key] = ValueFound.Presentation;
		Else
			ParameterValues[Item.Key] = ?(ValueIsFilled(ParameterValue), ParameterValue, Undefined);
		EndIf;
	EndDo;
	
	Return ParameterValues;
	
EndFunction

// Parameters:
//  Period - StandardPeriod
// 
// Returns:
//  String
//
Function ReportPeriodView(Period)
	
	PeriodPresentation = "";
	
	If Period = Undefined
		Or TypeOf(Period) <> Type("StandardPeriod") Then 
		
		Return PeriodPresentation;
	EndIf;
	
	Return StringFunctions.PeriodPresentationInText(Period.StartDate, Period.EndDate);
	
EndFunction

#EndRegion

#Region ChildRecordsCountInGroupings

Procedure OutputSubordinateRecordsCount(Settings, Schema, StandardProcessing) Export 
	
	If Schema.CalculatedFields.Find("SubordinateRecordsCount") = Undefined Then 
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	OutputRecordsCount = OutputRecordsCount(Settings);
	
	For Each StructureItem In Settings.Structure Do 
		
		If Not StructureItem.Use Then 
			Continue;
		EndIf;
		
		If TypeOf(StructureItem) = Type("DataCompositionGroup") Then 
			
			OutputSubordinateGroupRecordsCount(StructureItem, OutputRecordsCount);
			
		ElsIf TypeOf(StructureItem) = Type("DataCompositionTable") Then 
			
			OutputSubordinateTableRecordsCount(StructureItem, OutputRecordsCount);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
//  Settings - DataCompositionSettings
//
// Returns:
//  Boolean
//
Function OutputRecordsCount(Settings)
	
	OutputRecordsCount = Settings.DataParameters.Items.Find("OutputSubordinateRecordsCount1");
	
	Return OutputRecordsCount <> Undefined
		And OutputRecordsCount.Value;
	
EndFunction

Procedure OutputSubordinateGroupRecordsCount(Group, Output)
	
	GroupFields = Group.GroupFields.Items;
	
	If GroupFields.Count() > 0 Then 
		
		SelectedFields = Group.Selection;
		RecordsCountField = SubordinateRecordsCountField(SelectedFields, SelectedFields.Items);
		RecordsCountField.Use = Output;
		
	Else
		HideRecordsCountInDetailedRecords(Group);
	EndIf;
	
	For Each StructureItem In Group.Structure Do 
		
		If Not StructureItem.Use Then 
			Continue;
		EndIf;
		
		If TypeOf(StructureItem) = Type("DataCompositionGroup") Then 
			
			OutputSubordinateGroupRecordsCount(StructureItem, Output);
			
		ElsIf TypeOf(StructureItem) = Type("DataCompositionTable") Then 
			
			OutputSubordinateTableRecordsCount(StructureItem, Output);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure OutputSubordinateTableRecordsCount(Table, Output)
	
	RecordsCountColumn = Undefined;
	
	For Each Column In Table.Columns Do 
		
		GroupFields = Column.GroupFields.Items;
		
		If GroupFields.Count() = 0 Then 
			
			RecordsCountColumn = Column;
			Break;
		
		EndIf;
		
	EndDo;
	
	If RecordsCountColumn <> Undefined Then 
		Return;
	EndIf;
	
	RecordsCountColumn = Table.Columns.Add();
	
	SelectedFields = RecordsCountColumn.Selection;
	RecordsCountField = SubordinateRecordsCountField(SelectedFields, SelectedFields.Items);
	RecordsCountField.Use = Output;
	
	HideRecordsCountInDetailedTableRecords(Table.Rows);
	
EndProcedure

Function SubordinateRecordsCountField(SelectedFields, Items)
	
	RecordsCountField = Undefined;
	SoughtValue = New DataCompositionField("SubordinateRecordsCount");
	
	For Each Item In Items Do 
		
		If TypeOf(Item) = Type("DataCompositionSelectedField") Then 
			
			If Item.Field = SoughtValue Then 
				
				RecordsCountField = Item;
				Break;
				
			EndIf;
			
		ElsIf TypeOf(Item) = Type("DataCompositionSelectedFieldGroup") Then 
			
			If Item.Use Then 
				SubordinateRecordsCountField(SelectedFields, Item.Items);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If RecordsCountField = Undefined Then 
		
		RecordsCountField = SelectedFields.Items.Add(Type("DataCompositionSelectedField"));
		RecordsCountField.Field = SoughtValue;
		
	EndIf;
	
	Return RecordsCountField;
	
EndFunction

Procedure HideRecordsCountInDetailedTableRecords(Rows)
	
	For Each String In Rows Do 
		
		GroupFields = String.GroupFields.Items;
		
		If GroupFields.Count() = 0 Then 
			HideRecordsCountInDetailedRecords(String);
		Else
			HideRecordsCountInDetailedTableRecords(String.Structure);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure HideRecordsCountInDetailedRecords(DetailedRecords)
	
	Field = New DataCompositionField("SubordinateRecordsCount");
	
	RecordsCountAppearance = RecordsCountAppearance(DetailedRecords, Field);
	
	FormattedField = RecordsCountAppearance.Fields.Items.Add();
	FormattedField.Field = Field;
	
	AppearanceCondition = RecordsCountAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
	AppearanceCondition.LeftValue = Field;
	AppearanceCondition.ComparisonType = DataCompositionComparisonType.NotEqual;
	AppearanceCondition.RightValue = 0;
	AppearanceCondition.Use = True;
	
	RecordsCountAppearance.Appearance.SetParameterValue("Text", "");
	
	UsageOptions = UseCasesForTheDesign();
	For Each UseVariant In UsageOptions Do 
		RecordsCountAppearance[UseVariant] = DataCompositionConditionalAppearanceUse.DontUse;
	EndDo;
	
EndProcedure

// Returns:
//   Array of String - Collection of element property IDs for the conditional appearance 
//                      DataCompositionConditionalAppearanceUse.
//
Function UseCasesForTheDesign()
	
	UsageOptions = New Array;
	UsageOptions.Add("UseInHeader");
	UsageOptions.Add("UseInFieldsHeader");
	UsageOptions.Add("UseInHierarchicalGroup");
	UsageOptions.Add("UseInOverall");
	UsageOptions.Add("UseInFilter");
	UsageOptions.Add("UseInParameters");
	UsageOptions.Add("UseInOverallHeader");
	UsageOptions.Add("UseInResourceFieldsHeader");
	UsageOptions.Add("UseInOverallResourceFieldsHeader");
	
	Return UsageOptions;
	
EndFunction

Function RecordsCountAppearance(DetailedRecords, SoughtValue)
	
	RecordsCountAppearance = Undefined;
	
	AppearanceItems = DetailedRecords.ConditionalAppearance.Items;
	
	For Each AppearanceItem In AppearanceItems Do 
		
		AppearanceFields = AppearanceItem.Fields.Items;
		
		If AppearanceFields.Count() > 0
			And AppearanceFields[0].Field = SoughtValue Then 
			
			RecordsCountAppearance = AppearanceItem;
			Break;
			
		EndIf;
		
	EndDo;
	
	If RecordsCountAppearance = Undefined Then 
		RecordsCountAppearance = AppearanceItems.Add();
	EndIf;
	
	RecordsCountAppearance.Fields.Items.Clear();
	RecordsCountAppearance.Filter.Items.Clear();
	
	Return RecordsCountAppearance;
	
EndFunction

Function FixedParameterDisplayModes(Settings)
	
	ViewModes = New Structure();
	ViewModes.Insert("Period", DataCompositionSettingsItemViewMode.QuickAccess);
	ViewModes.Insert("MetadataObjectType", DataCompositionSettingsItemViewMode.QuickAccess);
	ViewModes.Insert("MetadataObjectName", DataCompositionSettingsItemViewMode.QuickAccess);
	ViewModes.Insert("TableName", DataCompositionSettingsItemViewMode.QuickAccess);
	ViewModes.Insert("OutputSubordinateRecordsCount1", DataCompositionSettingsItemViewMode.Normal);
	
	Parameters = Settings.DataParameters.Items;
	
	For Each ViewMode In ViewModes Do 
		
		FoundParameter = Parameters.Find(ViewMode.Key);
		
		If FoundParameter <> Undefined Then 
			ViewModes[ViewMode.Key] = FoundParameter.ViewMode;
		EndIf;
		
	EndDo;
	
	Return ViewModes;
	
EndFunction

Procedure SetTheDisplayModesOfFixedParameters(Settings, ViewModes)
	
	Parameters = Settings.DataParameters.Items;
	
	For Each ViewMode In ViewModes Do 
		
		FoundParameter = Parameters.Find(ViewMode.Key);
		
		If FoundParameter <> Undefined Then 
			FoundParameter.ViewMode = ViewModes[ViewMode.Key];
		EndIf;
		
	EndDo;
	
EndProcedure

Function PeriodEndDate_2(Period, MetadataObjectType, TableName) Export
	
	If Period = Undefined Then
		Return Date(1, 1, 1);
	EndIf;
	
	EndDate = ?(TypeOf(Period) = Type("StandardPeriod"), Period.EndDate, Period);
	
	If StrFind(Upper(MetadataObjectType), "REGISTER") = 0
	   Or StrCompare(TableName, "Balance") <> 0 Then
		Return EndDate;
	EndIf;
	
	Return New Boundary(EndDate, BoundaryType.Including);
	
EndFunction

Function MainDataTableNamePresentation()
	
	Return NStr("vi = 'Dữ liệu chính';
				|ru = 'Основные данные';
				|en = 'Main data'; fa = 'داده‌های اصلی';
				|it = 'Dati principali';
				|pl = 'Podstawowe dane';
				|tr = 'Ana veri'");
	
EndFunction

#EndRegion

#EndRegion

#EndIf