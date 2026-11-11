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

#If Not MobileStandaloneServer Then

// The procedure saves the generated report  to the ReportsSnapshots information register as an MXL spreadsheet.
//
// Parameters:
//  ReportResult - SpreadsheetDocument - Report snapshot in MXL format.
//  ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure SaveUserReportSnapshot(ReportResult, ReportSettings) Export

	SetPrivilegedMode(True);
	
	RecordManager = InformationRegisters.ReportsSnapshots.CreateRecordManager();
	
	RecordManager.User = Users.CurrentUser();
	RecordManager.Report = ReportSettings.ReportRef;
	RecordManager.Variant = ReportSettings.OptionRef;
	
	RecordManager.UserSettingsHash = Common.CheckSumString(
		ReportSettings.ResultProperties.SettingsComposer.UserSettings);
	RecordManager.UserSetting = New ValueStorage(
		ReportSettings.ResultProperties.SettingsComposer.UserSettings,
		New Deflation(9));

	RecordManager.ReportResult = New ValueStorage(ReportResult, New Deflation(9));
	RecordManager.UpdateDate = CurrentSessionDate();
	RecordManager.LastViewedDate = CurrentSessionDate();
	
	RecordManager.Write();

EndProcedure

// The procedure updates user's report snapshots.
//
// Parameters:
//  FillParameters - Structure:
//   * User - CatalogRef.Users - User who owns the snapshots to be updated.
//   * ReportsSnapshots - ValueTable:
//    ** User - CatalogRef.Users
//    ** Report - CatalogRef.MetadataObjectIDs
//    ** Variant - CatalogRef.ReportsOptions
//    ** UserSettingsHash - Number
//   * CatalogNameReportOptions - String - Name of the catalog that stores report options (unless this is the ReportsOptions catalog).
//  StorageAddress - String - Used for the background execution.
//
Procedure UpdateUserReportsSnapshots(FillParameters, StorageAddress) Export

	SetPrivilegedMode(True);
	
	ModulePerformanceMonitor = Undefined;
	If Common.SubsystemExists("StandardSubsystems.PerformanceMonitor") Then
		ModulePerformanceMonitor = Common.CommonModule("PerformanceMonitor");
		MeasurementDetails = ModulePerformanceMonitor.StartTimeConsumingOperationMeasurement(
			"UpdateUserReportsSnapshots");
	EndIf;
	
	CatalogNameReportOptions = "";
	FillParameters.Property("CatalogNameReportOptions", CatalogNameReportOptions);
	
	Query = New Query;
	Query.SetParameter("User", FillParameters.User);
	If FillParameters.Property("ReportsSnapshots") Then
		Query.SetParameter("ReportsSnapshots", FillParameters.ReportsSnapshots);
		Query.Text = 
		"SELECT
		|	ReportsSnapshots.User AS User,
		|	ReportsSnapshots.Report AS RefOfReport,
		|	ReportsSnapshots.Variant AS Variant,
		|	ReportsSnapshots.UserSettingsHash AS UserSettingsHash
		|INTO SavedReportsSnapshots
		|FROM
		|	&ReportsSnapshots AS ReportsSnapshots
		|
		|INDEX BY
		|	User,
		|	Report,
		|	Variant,
		|	UserSettingsHash
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReportsSnapshots.User AS User,
		|	ReportsSnapshots.Report AS RefOfReport,
		|	&ReportName AS ReportName,
		|	ReportsSnapshots.Variant AS Variant,
		|	ReportsSnapshots.Variant.VariantKey AS VariantKey,
		|	ReportsSnapshots.UserSettingsHash AS UserSettingsHash,
		|	ReportsSnapshots.UserSetting AS UserSetting
		|FROM
		|	InformationRegister.ReportsSnapshots AS ReportsSnapshots
		|		INNER JOIN SavedReportsSnapshots AS SavedReportsSnapshots
		|		ON ReportsSnapshots.User = SavedReportsSnapshots.User
		|			AND ReportsSnapshots.Report = SavedReportsSnapshots.RefOfReport
		|			AND ReportsSnapshots.Variant = SavedReportsSnapshots.Variant
		|			AND ReportsSnapshots.UserSettingsHash = SavedReportsSnapshots.UserSettingsHash
		|WHERE
		|	ReportsSnapshots.User = &User
		|	AND ReportsSnapshots.Variant REFS Catalog.ReportsOptions";
	Else	
		Query.Text = 
		"SELECT
		|	ReportsSnapshots.User AS User,
		|	ReportsSnapshots.Report AS RefOfReport,
		|	&ReportName AS ReportName,
		|	ReportsSnapshots.Variant AS Variant,
		|	ReportsSnapshots.Variant.VariantKey AS VariantKey,
		|	ReportsSnapshots.UserSettingsHash AS UserSettingsHash,
		|	ReportsSnapshots.UserSetting AS UserSetting
		|FROM
		|	InformationRegister.ReportsSnapshots AS ReportsSnapshots
		|WHERE
		|	ReportsSnapshots.User = &User
		|	AND ReportsSnapshots.Variant REFS Catalog.ReportsOptions";
	EndIf;
	If Not IsBlankString(CatalogNameReportOptions) Then
		Query.Text = StrReplace(Query.Text, "ReportsOptions", CatalogNameReportOptions);
	EndIf;
	
	ReportName = "CASE
	|		WHEN VALUETYPE(ReportsSnapshots.Report) = TYPE(Catalog.MetadataObjectIDs)
	|			THEN CAST(ReportsSnapshots.Report AS Catalog.MetadataObjectIDs).Name
	|		WHEN VALUETYPE(ReportsSnapshots.Report) = TYPE(Catalog.ExtensionObjectIDs)
	|			THEN CAST(ReportsSnapshots.Report AS Catalog.ExtensionObjectIDs).Name
	|		ELSE ReportsSnapshots.Report
	|	END";
	
	If Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then 
		ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
		AdditionalReportTableName = ModuleAdditionalReportsAndDataProcessors.AdditionalReportTableName();
		
		ReportName = StringFunctionsClientServer.SubstituteParametersToString("CASE
			|		WHEN VALUETYPE(ReportsSnapshots.Report) = TYPE(Catalog.MetadataObjectIDs)
			|			THEN CAST(ReportsSnapshots.Report AS Catalog.MetadataObjectIDs).Name
			|		WHEN VALUETYPE(ReportsSnapshots.Report) = TYPE(Catalog.ExtensionObjectIDs)
			|			THEN CAST(ReportsSnapshots.Report AS Catalog.ExtensionObjectIDs).Name
			|		WHEN VALUETYPE(ReportsSnapshots.Report) = TYPE(%1)
			|			THEN CAST(ReportsSnapshots.Report AS %1).ObjectName
			|		ELSE ReportsSnapshots.Report
			|	END", AdditionalReportTableName);
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&ReportName", ReportName);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
	
		RecordManager = InformationRegisters.ReportsSnapshots.CreateRecordManager();
		FillPropertyValues(RecordManager, Selection, "User, Variant, UserSettingsHash");
		RecordManager.Report = Selection.RefOfReport;
	
		ReportGenerationParameters = ReportsOptions.ReportGenerationParameters();
	
		ReportGenerationParameters.OptionRef1 = Selection.Variant;
		ReportGenerationParameters.RefOfReport = Selection.RefOfReport;
		ReportGenerationParameters.VariantKey = Selection.VariantKey;
		ReportGenerationParameters.DCUserSettings = Selection.UserSetting.Get();
		If Not IsBlankString(CatalogNameReportOptions) Then
			VariantKey = Selection.ReportName;
			ReportGenerationParameters.VariantKey = VariantKey;
			ReportGenerationParameters.OptionRef1 = ReportsOptions.ReportVariant(Selection.RefOfReport, VariantKey);
		EndIf;
		
		Generation1 = ReportsOptions.GenerateReport(ReportGenerationParameters, True, False);
		
		If Not Generation1.Success Then
			WriteLogEvent(NStr("vi = 'Cập nhật ảnh chụp báo cáo';
								|ru = 'Обновление снимков отчетов';
								|en = 'Update report snapshots'; fa = 'به‌روزرسانی نسخه‌های لحظه‌ای گزارش';
								|it = 'Обновление снимков отчетов';
								|pl = 'Update report snapshots';
								|tr = 'Raporların anlık görüntülerinin güncellenmesi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			Common.MetadataObjectByID(Selection.RefOfReport),
			Selection.Variant,
			Generation1.ErrorText);
		EndIf;
		
		RecordManager.ReportResult = New ValueStorage(Generation1.SpreadsheetDocument, New Deflation(9));
		RecordManager.UserSetting = Selection.UserSetting;
		RecordManager.UpdateDate = CurrentSessionDate();
		RecordManager.LastViewedDate = CurrentSessionDate();
		RecordManager.ReportUpdateError = Not Generation1.Success;
		RecordManager.Write();
	
	EndDo;
	
	If ModulePerformanceMonitor <> Undefined Then
		ModulePerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, Selection.Count());
	EndIf;

EndProcedure

#EndIf

// The function returns the list of user's report snapshots.
//
// Parameters:
//  User - CatalogRef.Users - User who owns the snapshot list to be generated.
//  CatalogNameReportOptions - String - Name of the catalog that stores report options (unless this is the ReportsOptions catalog).
// Returns:
//  ValueTable:
//   * User - CatalogRef.Users - User who owns the report snapshot.
//   * Report - CatalogRef.MetadataObjectIDs - Report ID.
//   * Variant - DefinedType.OptionOfReportToUpdate - Report option.
//   * OptionDescription - String - Report option description (applies to the standalone mode).
//   * UserSettingsHash - Number  - User setting hash.
//
Function UserReportsSnapshots(User, CatalogNameReportOptions) Export

	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("User", User);
	Query.Text =
	"SELECT
	|	ReportsSnapshots.User AS User,
	|	ReportsSnapshots.Report AS RefOfReport,
	|	ReportsSnapshots.Variant AS Variant,
	|	ReportsSnapshots.Variant.Description AS OptionDescription,
	|	ReportsSnapshots.UserSettingsHash AS UserSettingsHash,
	|	ReportsSnapshots.UpdateDate AS UpdateDate
	|FROM
	|	InformationRegister.ReportsSnapshots AS ReportsSnapshots
	|WHERE
	|	ReportsSnapshots.User = &User
	|	AND ReportsSnapshots.Variant REFS Catalog.ReportsOptions
	|	AND NOT ReportsSnapshots.Variant.Description IS NULL
	|
	|ORDER BY
	|	Report,
	|	Variant,
	|	UserSettingsHash";
	If User = Undefined Then
		Query.Text = StrReplace(Query.Text, "ReportsSnapshots.User = &User", "TRUE");
	EndIf;
	If Not IsBlankString(CatalogNameReportOptions) Then
		Query.Text = StrReplace(Query.Text, "ReportsOptions", CatalogNameReportOptions);
	EndIf;
	
	UserReportsSnapshots = Query.Execute().Unload();
	UserReportsSnapshots.Columns.RefOfReport.Name = "Report";

	Return UserReportsSnapshots;

EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	IsAuthorizedUser(User)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("UpdateUserReportsSnapshots", True);
	
EndProcedure

#EndRegion

#EndIf
