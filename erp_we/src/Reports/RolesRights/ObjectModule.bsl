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

// Set report form settings.
//
// Parameters:
//   Form - ClientApplicationForm
//         - Undefined
//   VariantKey - String
//                - Undefined
//   Settings - See ReportsClientServer.DefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.DisableStandardContextMenu = True;
	Settings.EditStructureAllowed = False;
	Settings.GenerateImmediately = True;
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.OnDefineUsedTables = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
	Settings.Events.AfterLoadSettingsInLinker = True;
	Settings.Events.BeforeFormationReport = True;
	Settings.Events.OnDefineSelectionParameters = True;
	
EndProcedure

// See ReportsOverridable.OnCreateAtServer
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	FormAttributes = New Structure("OptionContext");
	FillPropertyValues(FormAttributes, Form);
	
	If ValueIsFilled(FormAttributes.OptionContext) Then
		Variant             = Form.CurrentVariantKey;
		FormParametersSelection = Form.ParametersForm.Filter;
		
		If Variant = "RightsOfRolesAndProfilesToMetadataObject" Then
			FormParametersSelection.Insert("MetadataObject", FormAttributes.OptionContext);
			
		ElsIf Form.Parameters.Property("CommandParameter") Then
			ParameterName = "";
			If Variant = "RightsOfRoleAndProfilesToMetadataObjects" Then
				ParameterName = "Profile";
				ParameterValue = ProfileListWithoutGroups(Form.Parameters.CommandParameter);
				
			ElsIf Variant = "RolesRights" Then
				ParameterName = "Role";
				ParameterValue = ListRoleNamesProfiles(Form.Parameters.CommandParameter);
			EndIf;
			If ValueIsFilled(ParameterName) Then
				If FormParametersSelection.Property("InitialSelection") Then
					InitialSelection = FormParametersSelection.InitialSelection;
				Else
					InitialSelection = New Structure;
					FormParametersSelection.Insert("InitialSelection", InitialSelection);
				EndIf;
				InitialSelection.Insert(ParameterName, ParameterValue);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// Called before importing new settings. Used for modifying DCS reports.
//
// Parameters:
//   Context - Arbitrary
//   SchemaKey - String
//   VariantKey - String
//                - Undefined
//   NewDCSettings - DataCompositionSettings
//                    - Undefined
//   NewDCUserSettings - DataCompositionUserSettings
//                                    - Undefined
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If TypeOf(Context) <> Type("ClientApplicationForm")
	 Or TypeOf(NewDCUserSettings) <> Type("DataCompositionUserSettings") Then
		Return;
	EndIf;
	
	DataCompositionSchema.Parameters.Role.SetAvailableValues(
		UsersInternal.AllRoles().List.Get());
	
	DataCompositionSchema.Parameters.MetadataObject.SetAvailableValues(
		AccessManagementInternalCached.ListOfMetadataObjectsWithRights().Get());
	
	AdditionalProperties = SettingsComposer.Settings.AdditionalProperties;
	Variant = AdditionalProperties.PredefinedOptionKey;
	Form = Context;
	FormParametersSelection = AdditionalProperties.FormParametersSelection;
	
	If NewDCSettings <> Undefined Then
		HideExcessDataFields(Variant, FormParametersSelection, NewDCSettings, NewDCUserSettings);
	EndIf;
	
	UnavailableOptions = New Structure;
	
	If Variant = "RolesRights"
	   And Not FormParametersSelection.Property("InitialSelection") Then
		
		If Not ParameterUsed(NewDCUserSettings, "MetadataObject")
		   And Not ParameterUsed(NewDCUserSettings, "Role") Then
			
			Form.ReportSettings.GenerateImmediately = False;
		EndIf;
		UnavailableOptions = New Structure("Right,Profile");
	Else
		If Not FormParametersSelection.Property("InitialSelection") Then
			FormParametersSelection.Insert("InitialSelection", New Structure);
		EndIf;
		If TypeOf(FormParametersSelection.InitialSelection) <> Type("Structure") Then
			FormParametersSelection.InitialSelection = New Structure;
		EndIf;
		If Not FormParametersSelection.InitialSelection.Property("InitialSelectionSet") Then
			FormParametersSelection.InitialSelection.Insert("InitialSelectionSet",
				Not ValueIsFilled(FormParametersSelection.InitialSelection)
				And FormParametersSelection.Count() = 1);
		EndIf;
		
		If Variant = "DetailedRolesRightsToMetadataObject" Then
			UnavailableOptions = New Structure("AccessLevel,
				|RightsOnDetails, ShowPermissionsofNonInterfaceSubsystems,
				|DontWarnAboutLargeReportSize");
			If SetSelectionByProfile(FormParametersSelection, SettingsComposer.Settings) Then
				UnavailableOptions.Insert("Role");
				UnavailableOptions.Insert("ShowObjectsAndRolesWithoutPermissions");
				If TypeOf(NewDCSettings) = Type("DataCompositionSettings") Then
					NewDCSettings.AdditionalProperties.Insert("SetSelectionByProfile");
				EndIf;
			Else
				UnavailableOptions.Insert("Profile");
			EndIf;
			
		ElsIf Variant = "RightsOfRolesAndProfilesToMetadataObject" Then
			UnavailableOptions = New Structure("RightsOnDetails,Right,
				|DontWarnAboutLargeReportSize");
			
		ElsIf Variant = "RightsOfRoleAndProfilesToMetadataObjects" Then
			If SetSelectionByProfile(FormParametersSelection, SettingsComposer.Settings) Then
				UnavailableOptions.Insert("Role");
			EndIf;
			UnavailableOptions.Insert("Right");
		EndIf;
	EndIf;
	
	If FormParametersSelection.Property("InitialSelection")
	   And Not FormParametersSelection.InitialSelection.InitialSelectionSet Then
		
		AllParameters = New Structure("MetadataObject, Role, RightsOnDetails, Profile,
			|AccessLevel, Right, ShowObjectsAndRolesWithoutPermissions, NameFormat,
			|ShowPermissionsofNonInterfaceSubsystems, DontWarnAboutLargeReportSize");
	Else
		AllParameters = UnavailableOptions;
	EndIf;
	
	For Each ParameterDetails In AllParameters Do
		If Not FormParametersSelection.Property(ParameterDetails.Key) Then
			DisableOption(ParameterDetails.Key, UnavailableOptions,
				NewDCSettings, NewDCUserSettings);
		EndIf;
	EndDo;
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		ModuleReportsServer = Common.CommonModule("ReportsServer");
		ModuleReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
	EndIf;
	
	If Not FormParametersSelection.Property("InitialSelection")
	 Or FormParametersSelection.InitialSelection.InitialSelectionSet Then
		Return;
	EndIf;
	FormParametersSelection.InitialSelection.InitialSelectionSet = True;
	
	If Variant = "RightsOfRoleAndProfilesToMetadataObjects"
	   And FormParametersSelection.InitialSelection.Property("Profile") Then
		
		SetDisplayMode("Profile", DataCompositionSettingsItemViewMode.QuickAccess,
			NewDCSettings, NewDCUserSettings);
		
		SetDisplayMode("Role", DataCompositionSettingsItemViewMode.Normal,
			NewDCSettings, NewDCUserSettings);
	EndIf;
	
	If TypeOf(FormParametersSelection.InitialSelection) = Type("Structure") Then
		For Each KeyAndValue In FormParametersSelection.InitialSelection Do
			If KeyAndValue.Key = "InitialSelectionSet" Then
				Continue;
			EndIf;
			EnableParameter(NewDCUserSettings,
				KeyAndValue.Key, KeyAndValue.Value,
				Form.ReportSettings.GenerateImmediately);
		EndDo;
	EndIf;
	
EndProcedure

//  Parameters:
//    AdditionalParameters - Structure
//
Procedure AfterLoadSettingsInLinker(AdditionalParameters) Export
	
	AdditionalProperties = SettingsComposer.Settings.AdditionalProperties;
	Variant             = AdditionalProperties.PredefinedOptionKey;
	FormParametersSelection = AdditionalProperties.FormParametersSelection;
	
	ConfigureParameterAccessLevel(SettingsComposer.Settings);
	ConfigureParameterRight(Variant, SettingsComposer.Settings);
	
	If Variant = "RolesRights" Then
		DescriptionOption = NStr("vi = 'Quyền của vai trò';
								|ru = 'Права ролей';
								|en = 'Role rights'; fa = 'حقوق نقش';
								|it = 'Diritti dei ruoli';
								|pl = 'Prawa ról';
								|tr = 'Rol yetkileri'");
		
	ElsIf Variant = "RightsOfRoleAndProfilesToMetadataObjects" Then
		If SetSelectionByProfile(FormParametersSelection, SettingsComposer.Settings)
		 Or Not ParameterUsed(SettingsComposer.UserSettings, "Role") Then
			DescriptionOption = NStr("vi = 'Quyền của hồ sơ đến đối tượng metadata';
									|ru = 'Права профилей на объекты метаданных';
									|en = 'Profile rights that apply to metadata objects'; fa = 'Profile rights that apply to metadata objects';
									|it = 'Regole dei profili agli oggetti di metadati';
									|pl = 'Prawa profili do obiektów metadanych';
									|tr = 'Meta veri nesnelerine profil yetkisi'");
		Else
			DescriptionOption = NStr("vi = 'Quyền của vai trò và hồ sơ đến đối tượng metadata';
									|ru = 'Права роли и профилей на объекты метаданных';
									|en = 'Role and profile rights that apply to metadata object'; fa = 'حقوق نقش و پروفایل که بر شیء فراداده اعمال می‌شود';
									|it = 'Role and profile rights that apply to metadata object';
									|pl = 'Role and profile rights that apply to metadata object';
									|tr = 'Meta veri nesnelerinde rol ve profil yetkileri'");
		EndIf;
		
	ElsIf Variant = "RightsOfRolesAndProfilesToMetadataObject" Then
		DescriptionOption = NStr("vi = 'Quyền của vai trò và hồ sơ đến đối tượng metadata';
								|ru = 'Права роли и профилей на объекты метаданных';
								|en = 'Role and profile rights that apply to metadata object'; fa = 'حقوق نقش و پروفایل که بر شیء فراداده اعمال می‌شود';
								|it = 'Role and profile rights that apply to metadata object';
								|pl = 'Role and profile rights that apply to metadata object';
								|tr = 'Meta veri nesnelerinde rol ve profil yetkileri'");
	
	ElsIf Variant = "DetailedRolesRightsToMetadataObject" Then
		If SetSelectionByProfile(FormParametersSelection, SettingsComposer.Settings) Then
			DescriptionOption = NStr("vi = 'Quyền chi tiết của hồ sơ đến đối tượng metadata';
									|ru = 'Подробные права профилей на объект метаданных';
									|en = 'Detailed profile rights that apply to metadata object'; fa = 'Detailed profile rights that apply to metadata object';
									|it = 'Diritti dettagliati dei profili sugli oggetti di metadati';
									|pl = 'Szczegółowe prawa profili do obiektu metadanych';
									|tr = 'Meta veri nesnesine detaylı profil yetkisi'");
		Else
			DescriptionOption = NStr("vi = 'Quyền chi tiết của vai trò đến đối tượng metadata';
									|ru = 'Подробные права ролей на объект метаданных';
									|en = 'Detailed role rights that apply to metadata object'; fa = 'حقوق تفصیلی نقش که بر شیء فراداده اعمال می‌شود';
									|it = 'Detailed role rights that apply to metadata object';
									|pl = 'Detailed role rights that apply to metadata object';
									|tr = 'Meta veri nesnesindeki detaylı rol ve profil izinleri'");
		EndIf;
	EndIf;
	
	If ValueIsFilled(DescriptionOption) Then
		AdditionalProperties.Insert("DescriptionOption", DescriptionOption);
	EndIf;
	
EndProcedure

// Parameters:
//   VariantKey - String
//                - Undefined
//   TablesToUse - Array of String
//
Procedure OnDefineUsedTables(VariantKey, TablesToUse) Export
	
	TablesToUse.Add(Metadata.InformationRegisters.RolesRights.FullName());
	TablesToUse.Add(Metadata.Catalogs.AccessGroupProfiles.FullName());
	
EndProcedure

// Parameters:
//   ReportForm - ClientApplicationForm
//   AdditionalParameters - Structure:
//     * WarningText - String
//     * StorageParameterNameWarningDisclaimer - String
//
Procedure BeforeFormationReport(ReportForm, AdditionalParameters) Export
	
	Variant = SettingsComposer.Settings.AdditionalProperties.PredefinedOptionKey;
	
	If Variant <> "RolesRights"
	   And Variant <> "RightsOfRoleAndProfilesToMetadataObjects" Then
		Return;
	EndIf;
	
	Values = ValuesofSelectedParameter("DontWarnAboutLargeReportSize", True);
	If TypeOf(Values) = Type("ValueList")
	   And Values[0].Value = True Then
		Return;
	EndIf;
	
	Result = RolesRights(True, Variant = "RightsOfRoleAndProfilesToMetadataObjects", True);
	
	RowsCount   = Result.Hierarchy.Count();
	ColumnsCount = Result.Roles.Count();
	
	NumberOfBins = RowsCount * ColumnsCount;
	
	If NumberOfBins < 1000000 Then
		Return;
	EndIf;
	
	GigabyteTo = Round(NumberOfBins / 1500000 + RowsCount / 6000, 1) + 0.4;
	
	AdditionalParameters.StorageParameterNameWarningDisclaimer =
		"DontWarnAboutLargeReportSize";
	AdditionalParameters.WarningText =
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Với các bộ lọc hiện tại, báo cáo có thể rất lớn
			           |đến %1 dòng và %2 cột (%3 ô).
			           |
			           |Có thể mất nhiều thời gian để lập báo cáo.
			           |Có thể không đủ bộ nhớ (cần ~ đến %4 Gb).
			           |
			           |Nên cải thiện bộ lọc.';
			           |ru = 'При текущих отборах отчет может быть очень большим
			           |до %1 строк и %2 столбцов (%3 ячеек).
			           |
			           |Может долго формироваться.
			           |Может не хватить памяти (нужно ~ до %4 Гб).
			           |
			           |Рекомендуется усилить отборы.';
			           |en = 'With the current filters, the report might be too large:
			           |up to %1 rows and %2 columns (%3 cells).
			           |
			           |Its generation might take a long time.
			           |It might require up to %4 GB.
			           |
			           |Consider narrowing down the filter.'; fa = 'With the current filters, the report might be too large:
			           |up to %1 rows and %2 columns (%3 cells).
			           |
			           |Its generation might take a long time.
			           |It might require up to %4 GB.
			           |
			           |Consider narrowing down the filter.';
			           |it = 'Nei filtri correnti il report può risultare molto grande 
			           | fino a %1 righe e %2colonne (%3 celle).
			           |
			           |Può richiedere molto tempo per la creazione.
			           |Potrebbe non essere sufficiente la memoria (richiesto %4 Gb).
			           |
			           |Si consiglia di rafforzare i filtri.';
			           |pl = 'Przy bieżących filtrach filtrów raport może być bardzo duży
			           |do %1 wierszy i %2 kolumn (%3 komórek).
			           |
			           |Może być długo generowane.
			           |Może nie wystarczyć pamięci (potrzebne ~ do %4 GB).
			           |
			           |Zalecane jest wzmocnienie filtrów.';
			           |tr = 'Geçerli filtreler olduğunda rapor çok büyük olabilir
			           |%1 satıra ve %2 sütuna (%3 hücre) kadar.
			           |
			           |Oluşturulması uzun sürebilir.
			           |Bellek yetersiz gelebilir (~%4 Gb kadar gerekebilir).
			           |
			           |Filtreleri güçlendirmeniz önerilir.'"),
			Format(RowsCount, ""),
			Format(ColumnsCount, ""),
			Format(NumberOfBins, ""),
			Format(GigabyteTo, "NFD=1"));
	
EndProcedure

// See ReportsOverridable.OnDefineSelectionParameters.
Procedure OnDefineSelectionParameters(Form, SettingProperties) Export
	
	If SettingProperties.DCField = New DataCompositionField("DataParameters.Role") Then
		If TypeOf(SettingProperties.DCUserSetting.Value) = Type("ValueList") Then
			For Each Item In SettingProperties.DCUserSetting.Value Do
				MetadataObject = Metadata.Roles.Find(Item.Value);
				If MetadataObject = Undefined Then
					Continue;
				EndIf;
				Item.Presentation = MetadataObject.Presentation();
			EndDo;
		ElsIf TypeOf(SettingProperties.DCUserSetting.Value) = Type("String") Then
			MetadataObject = Metadata.Roles.Find(SettingProperties.DCUserSetting.Value);
			If MetadataObject = Undefined Then
				Return;
			EndIf;
			ValueList = New ValueList;
			ValueList.Add(SettingProperties.DCUserSetting.Value, MetadataObject.Presentation());
			SettingProperties.DCUserSetting.Value = ValueList;
		EndIf;
	EndIf;

	If SettingProperties.DCField = New DataCompositionField("DataParameters.MetadataObject") Then
		If TypeOf(SettingProperties.DCUserSetting.Value) = Type("ValueList") Then
			For Each Item In SettingProperties.DCUserSetting.Value Do
				MetadataObject = Common.MetadataObjectByFullName(Item.Value);
				If MetadataObject = Undefined Then
					Continue;
				EndIf;
				Item.Presentation = MetadataObject.Presentation();
			EndDo;
		ElsIf TypeOf(SettingProperties.DCUserSetting.Value) = Type("String") Then
			MetadataObject = Common.MetadataObjectByFullName(SettingProperties.DCUserSetting.Value);
			If MetadataObject = Undefined Then
				Return;
			EndIf;
			ValueList = New ValueList;
			ValueList.Add(SettingProperties.DCUserSetting.Value, MetadataObject.Presentation());
			SettingProperties.DCUserSetting.Value = ValueList;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region EventHandlers

// Parameters:
//  ResultDocument - SpreadsheetDocument
//  DetailsData - DataCompositionDetailsData
//  StandardProcessing - Boolean
//
Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	ComposerSettings = SettingsComposer.GetSettings();
	
	ParameterFormatName          = ComposerSettings.DataParameters.Items.Find("NameFormat");
	ParameterFormatNameSelected = ComposerSettings.DataParameters.Items.Find("NameFormatSelected");
	If ParameterFormatName.Use Then
		ParameterFormatNameSelected.Value = ParameterFormatName.Value;
	Else
		ParameterFormatNameSelected.Value = 0;
	EndIf;
	ParameterHeightCaps = ComposerSettings.DataParameters.Items.Find("HeaderHeight");
	HeaderHeight = 0;
	If ParameterHeightCaps.Use Then
		HeaderHeight = ParameterHeightCaps.Value;
		If TypeOf(HeaderHeight) = Type("Number") Then
			If HeaderHeight < 30 Then
				HeaderHeight = 30;
			ElsIf HeaderHeight > 350 Then
				HeaderHeight = 250;
			EndIf;
		EndIf;
	EndIf;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ComposerSettings, DetailsData);
	
	ExternalDataSets = New Structure;
	Variant = ComposerSettings.AdditionalProperties.PredefinedOptionKey;
	
	RolesRights = RolesRights(Variant = "RolesRights" Or Variant = "RightsOfRoleAndProfilesToMetadataObjects",
		Variant = "RightsOfRoleAndProfilesToMetadataObjects");
	ExternalDataSets.Insert("Hierarchy", RolesRights.Hierarchy);
	ExternalDataSets.Insert("Rights",    RolesRights.Rights);
	ExternalDataSets.Insert("Roles",     RolesRights.Roles);
	
	ProfilesInsteadofRoles = ComposerSettings.AdditionalProperties.Property("SetSelectionByProfile");
	ExternalDataSets.Insert("DetailedObjectPermissions", DetailedObjectPermissions(
		Variant = "DetailedRolesRightsToMetadataObject",
		ProfilesInsteadofRoles));
	
	ExternalDataSets.Insert("RightsRolesOnObject", RightsRolesOnObject(
		Variant = "RightsOfRolesAndProfilesToMetadataObject"));
	
	ExternalDataSets.Insert("FilterRoles", FilterRoles(
		Variant = "RightsOfRoleAndProfilesToMetadataObjects"));
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets , DetailsData);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
	FinishOutput(ResultDocument, DetailsData, Variant, ProfilesInsteadofRoles, HeaderHeight);
	
EndProcedure

#EndRegion

#Region Private

// Intended for procedure "OnComposeResult".
Procedure FinishOutput(ResultDocument, DetailsData, Variant, ProfilesInsteadofRoles, HeaderHeight)
	
	Images = Images();
	None = New Line(SpreadsheetDocumentCellLineType.None);
	// ACC:163-off - #598.1. The use is acceptable, as it affects the meaning.
	TextIsRestriction = NStr("vi = 'Có hạn chế';
							|ru = 'Есть ограничение';
							|en = 'Has restriction'; fa = 'دارای محدودیت است';
							|it = 'Vi è una limitazione';
							|pl = 'Istnieje ograniczenie';
							|tr = 'Sınır var'");
	// ACC:163-on
	
	If Variant = "RolesRights"
	 Or Variant = "RightsOfRoleAndProfilesToMetadataObjects" Then
		FirstTableHeader = NStr("vi = 'Dạng đối tượng metadata';
								|ru = 'Вид объектов метаданных';
								|en = 'Metadata object kind'; fa = 'Metadata object kind';
								|it = 'Tipo di oggetti di metadati';
								|pl = 'Rodzaj obiektów metadanych';
								|tr = 'Metaveri nesne türü'");
		
	ElsIf Variant = "DetailedRolesRightsToMetadataObject" Then
		FirstTableHeader = ?(ProfilesInsteadofRoles, NStr("vi = 'Hồ sơ';
															|ru = 'Профиль';
															|en = 'Profile'; fa = 'پروفایل';
															|it = 'Profilo';
															|pl = 'Profil';
															|tr = 'Profil'"), NStr("vi = 'Vai trò';
																					|ru = 'Роль';
																					|en = 'Role'; fa = 'نقش';
																					|it = 'Ruolo';
																					|pl = 'Rola';
																					|tr = 'Rol'"));
	Else
		FirstTableHeader = NStr("vi = 'Vai trò';
								|ru = 'Роль';
								|en = 'Role'; fa = 'نقش';
								|it = 'Ruolo';
								|pl = 'Rola';
								|tr = 'Rol'");
	EndIf;
	
	TableHeight = ResultDocument.TableHeight;
	TableWidth = ResultDocument.TableWidth;
	DataCompositionDecryptionIdentifierType = Type("DataCompositionDetailsID");
	InitialValueIsRightWithRestriction =
		Variant = "DetailedRolesRightsToMetadataObject";
	TextRightAllowed = NStr("vi = '✔';
							|ru = '✔';
							|en = '✔'; fa = '✔';
							|it = '✔';
							|pl = '✔';
							|tr = '✔'");
	
	For LineNumber = 1 To TableHeight Do
		YesRightWithRestriction = InitialValueIsRightWithRestriction;
		For ColumnNumber = 1 To TableWidth Do
			Area = ResultDocument.Area(LineNumber, ColumnNumber);
			
			Details = Area.Details;
			If TypeOf(Details) <> DataCompositionDecryptionIdentifierType Then
				If Area.Text = "*" Then
					Area.Text = "";
					Area.Comment.Text = TextIsRestriction;
				ElsIf Area.Text = "+" Then
					Area.Text = TextRightAllowed;
					Area.Comment.Text = TextIsRestriction;
				ElsIf Area.Text = "***" Then
					Area.Text = FirstTableHeader;
					If ValueIsFilled(HeaderHeight) Then
						If Variant = "RolesRights"
						 Or Variant = "RightsOfRoleAndProfilesToMetadataObjects" Then
							RegionLower = ResultDocument.Area(LineNumber + 1, ColumnNumber);
							If ValueIsFilled(Area.RowHeight)
							   And ValueIsFilled(RegionLower.RowHeight) Then
								CurrentHeight = Area.RowHeight + RegionLower.RowHeight;
								Area.RowHeight     = HeaderHeight * (Area.RowHeight     / CurrentHeight);
								RegionLower.RowHeight = HeaderHeight * (RegionLower.RowHeight / CurrentHeight);
								If Area.RowHeight < 13 Then
									Area.RowHeight = 13;
									RegionLower.RowHeight = HeaderHeight - Area.RowHeight;
								EndIf;
							EndIf;
						Else
							Area.RowHeight = HeaderHeight;
						EndIf;
					EndIf;
				EndIf;
				If Not YesRightWithRestriction And ColumnNumber >= 2 Then
					Break;
				EndIf;
				Continue;
			EndIf;
			
			FieldValues = DetailsData.Items[Details].GetFields();
			FieldIsRestriction = FieldValues.Find("HasLimit");
			
			If FieldIsRestriction <> Undefined Then
				If FieldIsRestriction.Value = True Then
					Area.Comment.Text = TextIsRestriction;
				EndIf;
				Continue;
				
			ElsIf FieldValues.Find("PictureIndex") <> Undefined Then
				Indent = (FieldValues.Find("Level").Value - 1) * 2;
				RowArea = ResultDocument.Area(LineNumber, , LineNumber);
				RowArea.CreateFormatOfRows();
				AreaOnRight = ResultDocument.Area(LineNumber, ColumnNumber);
				AreaLeft  = ResultDocument.Area(LineNumber, ColumnNumber - 1);
				AreaOnRight.LeftBorder = None;
				AreaLeft.RightBorder = None;
				AreaOnRight.ColumnWidth = Area.ColumnWidth + AreaLeft.ColumnWidth - Indent;
				AreaLeft.ColumnWidth = Indent;
				AreaOnRight.Picture = Images.Get(FieldValues.Find("PictureIndex").Value).Picture;
				If FieldValues.Find("YesRightWithRestriction").Value = True Then
					YesRightWithRestriction = True;
				EndIf;
			EndIf;
			
			If Not YesRightWithRestriction And ColumnNumber >= 2 Then
				Break;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

// Intended for procedure "BeforeImportSettingsToComposer".
Procedure HideExcessDataFields(Variant, FormParametersSelection, DCSettings, DCUserSettings)
	
	Hierarchy  = New Array;
	Rights     = New Array;
	Roles      = New Array;
	FilterRoles = New Array;
	
	DetailedObjectPermissions = New Array;
	RightsRolesOnObject    = New Array;
	
	If Variant = "DetailedRolesRightsToMetadataObject" Then
		DetailedObjectPermissions = "*";
		FieldRoleName           = DataCompositionSchema.DataSets.DetailedObjectPermissions.Fields.Find("NameOfRole2");
		FieldRolePresentation = DataCompositionSchema.DataSets.DetailedObjectPermissions.Fields.Find("RolePresentation2");
		FieldProfile           = DataCompositionSchema.DataSets.DetailedObjectPermissions.Fields.Find("Profile2");
		If SetSelectionByProfile(FormParametersSelection, SettingsComposer.Settings) Then
			FieldRoleName.Title           = NStr("vi = 'Tên hồ sơ';
												|ru = 'Имя профиля';
												|en = 'Profile name'; fa = 'Profile name';
												|it = 'Profile name';
												|pl = 'Profile name';
												|tr = 'Profil adı'");
			FieldRolePresentation.Title = NStr("vi = 'Trình bày hồ sơ';
												|ru = 'Представление профиля';
												|en = 'Profile presentation'; fa = 'نمایش پروفایل';
												|it = 'Profile presentation';
												|pl = 'Profile presentation';
												|tr = 'Profil sunumu'");
			FieldProfile.Title           = NStr("vi = 'Hồ sơ';
												|ru = 'Профиль';
												|en = 'Profile'; fa = 'پروفایل';
												|it = 'Profile';
												|pl = 'Profile';
												|tr = 'Profil'");
		Else
			FieldRoleName.Title           = NStr("vi = 'Tên vai trò';
												|ru = 'Имя роли';
												|en = 'Role name'; fa = 'نام نقش';
												|it = 'Nome ruolo';
												|pl = 'Nazwa roli';
												|tr = 'Roller adı'");
			FieldRolePresentation.Title = NStr("vi = 'Trình bày vai trò';
												|ru = 'Представление роли';
												|en = 'Role presentation'; fa = 'نمایش نقش';
												|it = 'Presentazione ruolo';
												|pl = 'Prezentacja roli';
												|tr = 'Rol sunumu (Nesne Üzerindeki Rol yetkileri)'");
			FieldProfile.Title           = NStr("vi = 'Hồ sơ (không sử dụng)';
												|ru = 'Профиль (не используется)';
												|en = 'Profile (not used)'; fa = 'Profile (not used)';
												|it = 'Profile (not used)';
												|pl = 'Profile (not used)';
												|tr = 'Profil (kullanılmıyor)'");
		EndIf;
		
	ElsIf Variant = "RightsOfRolesAndProfilesToMetadataObject" Then
		RightsRolesOnObject = "*";
	Else
		Hierarchy = "*";
		Rights = "*";
		Roles = New Map;
		FieldHasRoleRights = DataCompositionSchema.DataSets.Roles.Fields.Find("HavePermissionsRoles");
		FieldRoleCode       = DataCompositionSchema.DataSets.Rights.Fields.Find("RoleCode");
		If Variant = "RightsOfRoleAndProfilesToMetadataObjects" Then
			Roles.Insert("NameOfRole", False);
			Roles.Insert("RolePresentation", False);
			FieldRoleCode.Title       = NStr("vi = 'Mã hồ sơ';
											|ru = 'Код профиля';
											|en = 'Profile code'; fa = 'Profile code';
											|it = 'Profile code';
											|pl = 'Profile code';
											|tr = 'Profil kodu'");
			FieldHasRoleRights.Title = NStr("vi = 'Có quyền của hồ sơ';
											|ru = 'Есть права профиля';
											|en = 'Has profile rights'; fa = 'Has profile rights';
											|it = 'Has profile rights';
											|pl = 'Has profile rights';
											|tr = 'Profil izni mevcut'");
			If Not SetSelectionByProfile(FormParametersSelection, SettingsComposer.Settings) Then
				FilterRoles = "*";
			EndIf;
		Else
			Roles.Insert("Profile4", False);
			FieldRoleCode.Title       = NStr("vi = 'Mã vai trò';
											|ru = 'Код роли';
											|en = 'Role code'; fa = 'کد نقش';
											|it = 'Codice ruolo';
											|pl = 'Kod roli';
											|tr = 'Roller kodu'");
			FieldHasRoleRights.Title = NStr("vi = 'Có quyền của vai trò';
											|ru = 'Есть права роли';
											|en = 'Has role rights'; fa = 'دارای حقوق نقش است';
											|it = 'Vi sono diritti dei ruoli';
											|pl = 'Istnieją prawa roli';
											|tr = 'Rol yetkilerine sahip'");
		EndIf;
	EndIf;
	
	OriginalScheme = GetTemplate("Template");
	CurrentSchema = DataCompositionSchema;
	
	HideDataFieldsExceptSpecified("Hierarchy",  Hierarchy,  OriginalScheme, CurrentSchema);
	HideDataFieldsExceptSpecified("Rights",     Rights,     OriginalScheme, CurrentSchema);
	HideDataFieldsExceptSpecified("Roles",      Roles,      OriginalScheme, CurrentSchema);
	HideDataFieldsExceptSpecified("FilterRoles", FilterRoles, OriginalScheme, CurrentSchema);
	
	HideDataFieldsExceptSpecified("DetailedObjectPermissions", DetailedObjectPermissions, OriginalScheme, CurrentSchema);
	HideDataFieldsExceptSpecified("RightsRolesOnObject",    RightsRolesOnObject,    OriginalScheme, CurrentSchema);
	
EndProcedure

// Intended for procedure "HideExcessDataFields".
Procedure HideDataFieldsExceptSpecified(DataSetName, DataPaths, OriginalScheme, CurrentSchema)
	
	Reports.AccessRightsAnalysis.HideDataFieldsExceptSpecified(DataSetName,
		DataPaths, OriginalScheme, CurrentSchema);
	
EndProcedure

// For procedure AfterImportSettingsToComposer.
Procedure ConfigureParameterAccessLevel(Settings)
	
	Parameter = New DataCompositionParameter("AccessLevel");
	AvailableParameter = Settings.DataParameters.AvailableParameters.FindParameter(Parameter);
	If AvailableParameter = Undefined Then
		Return;
	EndIf;
	
	List = New ValueList;
	List.Add(01, NStr("vi = 'Có quyền';
						|ru = 'Есть право';
						|en = 'Right exists'; fa = 'Right exists';
						|it = 'Vi è il diritto';
						|pl = 'Istnieje prawo';
						|tr = 'Yetki var'"));
	List.Add(02, NStr("vi = 'Sử dụng';
						|ru = 'Использование';
						|en = 'Use'; fa = 'استفاده';
						|it = 'Utilizzo';
						|pl = 'Use';
						|tr = 'Kullanım'"));
	List.Add(03, NStr("vi = 'Đọc';
						|ru = 'Чтение';
						|en = 'Read'; fa = 'خوانده‌شده';
						|it = 'Lettura';
						|pl = 'Read';
						|tr = 'Oku'"));
	List.Add(04, NStr("vi = 'Thay đổi';
						|ru = 'Изменение';
						|en = 'Update'; fa = 'به‌روزرسانی';
						|it = 'Modifica';
						|pl = 'Update';
						|tr = 'Değiştir'"));
	List.Add(05, NStr("vi = 'Thêm';
						|ru = 'Добавление';
						|en = 'Add'; fa = 'افزودن';
						|it = 'Aggiungere';
						|pl = 'Add';
						|tr = 'Ekle'"));
	List.Add(06, NStr("vi = 'Xem';
						|ru = 'Просмотр';
						|en = 'View'; fa = 'مشاهده';
						|it = 'Visualizzazione';
						|pl = 'View';
						|tr = 'Görüntüle'"));
	List.Add(07, NStr("vi = 'Xem và Thay đổi';
						|ru = 'Просмотр и Изменение';
						|en = 'View and Update'; fa = 'View and Update';
						|it = 'View and Update';
						|pl = 'View and Update';
						|tr = 'Görünüm ve Değiştirme'"));
	List.Add(08, NStr("vi = 'Xem và Thêm';
						|ru = 'Просмотр и Добавление';
						|en = 'View and Add'; fa = 'View and Add';
						|it = 'View and Add';
						|pl = 'View and Add';
						|tr = 'Görünüm ve Ekleme'"));
	List.Add(09, NStr("vi = 'Chỉnh sửa';
						|ru = 'Редактирование';
						|en = 'Edit'; fa = 'ویرایش';
						|it = 'Modifica';
						|pl = 'Edit';
						|tr = 'Düzenleme'"));
	List.Add(10, NStr("vi = 'Soạn và Thêm';
						|ru = 'Редактирование и Добавление';
						|en = 'Edit and Add'; fa = 'Edit and Add';
						|it = 'Edit and Add';
						|pl = 'Edit and Add';
						|tr = 'Düzenleme ve Ekleme'"));
	List.Add(11, NStr("vi = 'Tạo mới';
						|ru = 'Создание';
						|en = 'Create'; fa = 'ایجاد';
						|it = 'Create';
						|pl = 'Create';
						|tr = 'Oluşturma'"));
	List.Add(12, NStr("vi = 'Nhận';
						|ru = 'Получение';
						|en = 'Get'; fa = 'دریافت';
						|it = 'Ricezione';
						|pl = 'Get';
						|tr = 'Al'"));
	List.Add(13, NStr("vi = 'Cài đặt';
						|ru = 'Установка';
						|en = 'Set'; fa = 'مجموعه';
						|it = 'Installazione';
						|pl = 'Set';
						|tr = 'Kurulum'"));
	List.Add(14, NStr("vi = 'Nhận và Cài đặt';
						|ru = 'Получение и Установка';
						|en = 'Get and Set'; fa = 'Get and Set';
						|it = 'Ricezione e installazione';
						|pl = 'Pobieranie i Instalacja';
						|tr = 'Alım ve kurulum'"));
	List.Add(15, NStr("vi = 'Nguồn dữ liệu ngoài: Sử dụng';
						|ru = 'Внешний источник данных: Использование';
						|en = 'External data source: Use'; fa = 'External data source: Use';
						|it = 'Fonte esterna dati: Utilizzo';
						|pl = 'Zewnętrzne źródło danych: Użycie';
						|tr = 'Harici veri kaynağı: Kullanım'"));
	List.Add(16, NStr("vi = 'Nguồn dữ liệu ngoài: Quản trị';
						|ru = 'Внешний источник данных: Администрирование';
						|en = 'External data source: Administration'; fa = 'External data source: Administration';
						|it = 'Fonte esterna dati: Amministrazione';
						|pl = 'Zewnętrzne źródło danych: Administrowanie';
						|tr = 'Harici veri kaynağı: Yönetim'"));
	List.Add(17, NStr("vi = 'Nguồn dữ liệu ngoài: Sử dụng và Quản trị';
						|ru = 'Внешний источник данных: Использование и Администрирование';
						|en = 'External data source: Use and Administration'; fa = 'External data source: Use and Administration';
						|it = 'Fonte esterna dati: Utilizzo e Amministrazione';
						|pl = 'Zewnętrzne źródło danych: Użycie i Administrowanie';
						|tr = 'Harici veri kaynağı: Kullanım ve Yönetim'"));
	
	AvailableParameter.AvailableValues = List;
	
EndProcedure

// For procedure AfterImportSettingsToComposer.
Procedure ConfigureParameterRight(Variant, Settings)
	
	If Variant <> "DetailedRolesRightsToMetadataObject" Then
		Return;
	EndIf;
	
	Parameter = New DataCompositionParameter("Right");
	AvailableParameter = Settings.DataParameters.AvailableParameters.FindParameter(Parameter);
	If AvailableParameter = Undefined Then
		Return;
	EndIf;
	
	Context = ReportContextByObject(True);
	If Context = Undefined Then
		Return;
	EndIf;
	
	AvailableParameter.AvailableValues = Context.RightsDetails.RightsList;
	
EndProcedure

// For procedure BeforeImportSettingsToComposer.
Procedure EnableParameter(UserSettings, ParameterName, Value, GenerateImmediately)
	
	SettingItem = ParameterSetting(UserSettings, ParameterName);
	If SettingItem = Undefined Then
		GenerateImmediately = False;
	Else
		SettingItem.Value = Value;
		SettingItem.Use = ParameterName <> "Profile" Or ValueIsFilled(Value);
	EndIf;
	
EndProcedure

// For procedure BeforeImportSettingsToComposer.
Procedure DisableOption(ParameterName, UnavailableOptions, DCSettings, DCUserSettings)
	
	If DCSettings = Undefined Then
		Return;
	EndIf;
	
	If UnavailableOptions.Property(ParameterName) Then
		Parameter = DataCompositionSchema.Parameters.Find(ParameterName);
		Parameter.UseRestriction = True;
		Parameter.IncludeInAvailableFields = False;
	EndIf;
	
	SettingItem = ParameterSetting(DCUserSettings, ParameterName);
	If SettingItem = Undefined Then
		SettingItem = ParameterSetting(DCSettings.DataParameters, ParameterName);
		If SettingItem = Undefined Then
			Return;
		EndIf;
	EndIf;
	
	If SettingItem.Use Then
		SettingItem.Use = False;
	EndIf;
	
	If SettingItem.Value = True Then
		SettingItem.Value = False;
	EndIf;
	
EndProcedure

Procedure SetDisplayMode(ParameterName, Mode, DCSettings, DCUserSettings)
	
	If DCSettings = Undefined Then
		Return;
	EndIf;
	
	SettingItem = ParameterSetting(DCSettings.DataParameters, ParameterName);
	
	If SettingItem <> Undefined Then
		SettingItem.ViewMode = Mode;
	EndIf;
	
	SettingItem = ParameterSetting(DCUserSettings, ParameterName);
	
	If SettingItem <> Undefined Then
		SettingItem.ViewMode = Mode;
	EndIf;
	
EndProcedure

// For procedure AfterImportSettingsToComposer.
Function ParameterSetting(DCUserSettings, ParameterName)
	
	Parameter = New DataCompositionParameter(ParameterName);
	
	For Each SettingItem In DCUserSettings.Items Do
		Properties = New Structure("Parameter");
		FillPropertyValues(Properties, SettingItem);
		If Properties.Parameter = Parameter Then
			Return SettingItem;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

// For procedure BeforeImportSettingsToComposer.
Function ParameterUsed(UserSettings, ParameterName)
	
	LayoutParameter = New DataCompositionParameter(ParameterName);
	
	For Each SettingItem In UserSettings.Items Do
		Properties = New Structure("Parameter");
		FillPropertyValues(Properties, SettingItem);
		If Properties.Parameter = LayoutParameter Then
			Return SettingItem.Use
				And ValueIsFilled(SettingItem.Value);
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function SetSelectionByProfile(FormParametersSelection, Settings)
	
	Return FormParametersSelection.Property("InitialSelection")
	      And FormParametersSelection.InitialSelection.Property("Profile")
	    Or Settings.AdditionalProperties.Property("SetSelectionByProfile");
	
EndFunction

Function DetailedObjectPermissions(Fill, ProfilesInsteadofRoles)
	
	Rights = New ValueTable;
	Rights.Columns.Add("ObjectName",           StringType(430));
	Rights.Columns.Add("ObjectPresentation", StringType(1000));
	Rights.Columns.Add("NameOfRole",              StringType(255));
	Rights.Columns.Add("RolePresentation",    StringType(255));
	Rights.Columns.Add("NameOfRight",             StringType(255));
	Rights.Columns.Add("RightPresentation",   StringType(255));
	Rights.Columns.Add("OrderRight",         NumberType(2));
	Rights.Columns.Add("RightsValue",        New TypeDescription("Boolean"));
	Rights.Columns.Add("YesRestrictionPermission", New TypeDescription("Boolean"));
	Rights.Columns.Add("Profile",              New TypeDescription("CatalogRef.AccessGroupProfiles"));
	
	If Not Fill Then
		Return Rights;
	EndIf;
	
	Context = ReportContextByObject();
	If Context = Undefined Then
		Return Rights;
	EndIf;
	FullObjectName         = Context.FullObjectName;
	ObjectPresentation     = Context.ObjectPresentation;
	RightsList               = Context.RightsDetails.RightsList;
	MetadataObject         = Context.MetadataObject;
	StandardAttributeName = Context.StandardAttributeName;
	
	FoundPermissions = New Map;
	SelectedPermissions = ValuesofSelectedParameter("Right");
	
	If ProfilesInsteadofRoles Then
		RoleProfiles = RoleProfiles();
	EndIf;
	
	RolesDetails = RolesDetails(, ProfilesInsteadofRoles);
	ObjectsFields = New Map;
	For Each RightDetails In RightsList Do
		If ProfilesInsteadofRoles Then
			ProfileRightsStrings = New Map;
		EndIf;
		For Each RoleDetails In RolesDetails Do
			HasRight = AccessRight(RightDetails.Value, MetadataObject, RoleDetails.Metadata, StandardAttributeName);
			If Not HasRight Then
				Continue;
			EndIf;
			If SelectedPermissions <> Undefined
			   And SelectedPermissions.FindByValue(RightDetails.Value) = Undefined Then
				Continue;
			EndIf;
			FoundPermissions.Insert(RightDetails, True);
			RoleDetails.HavePermissionsRoles = True;
			HasLimit = False;
			If RightDetails.Check Then
				HasLimit = HasLimit(RightDetails.Value,
					MetadataObject, ObjectsFields, RoleDetails.Metadata);
			EndIf;
			If ProfilesInsteadofRoles Then
				IsProfilesRoles = RoleProfiles.Get(RoleDetails.Ref);
				If Not ValueIsFilled(IsProfilesRoles) Then
					Continue;
				EndIf;
				For Each Profile In IsProfilesRoles Do
					StringRight = ProfileRightsStrings.Get(Profile);
					If StringRight = Undefined Then
						Filter = New Structure("Profile", Profile);
						StringRight = Rights.Add();
						StringRight.ObjectName           = FullObjectName;
						StringRight.ObjectPresentation = ObjectPresentation;
						StringRight.NameOfRole              = String(Profile);
						StringRight.RolePresentation    = StringRight.NameOfRole;
						StringRight.Profile              = Profile;
						StringRight.NameOfRight             = RightDetails.Value;
						StringRight.RightPresentation   = RightDetails.Presentation;
						StringRight.OrderRight         = RightsList.IndexOf(RightDetails) + 1;
						StringRight.RightsValue        = True;
						StringRight.YesRestrictionPermission = HasLimit;
						ProfileRightsStrings.Insert(Profile, StringRight);
					Else
						If Not HasLimit And StringRight.YesRestrictionPermission Then
							StringRight.YesRestrictionPermission = False;
						EndIf;
					EndIf;
				EndDo;
			Else
				StringRight = Rights.Add();
				StringRight.ObjectName           = FullObjectName;
				StringRight.ObjectPresentation = ObjectPresentation;
				StringRight.NameOfRole              = RoleDetails.NameOfRole;
				StringRight.RolePresentation    = RoleDetails.RolePresentation;
				StringRight.NameOfRight             = RightDetails.Value;
				StringRight.RightPresentation   = RightDetails.Presentation;
				StringRight.OrderRight         = RightsList.IndexOf(RightDetails) + 1;
				StringRight.RightsValue        = True;
				StringRight.YesRestrictionPermission = HasLimit;
			EndIf;
		EndDo;
	EndDo;
	
	If ShowObjectsAndRolesWithoutPermissions() And Not ProfilesInsteadofRoles Then
		Filter = New Structure("HavePermissionsRoles", False);
		DescriptionRolesWithoutPermissions = RolesDetails.FindRows(Filter);
		If Rights.Count() = 0 Then
			NameOfRight = "";
			RightPresentation = "";
			OrderRight = 0;
			If RightsList.Count() > 0 Then
				FirstRight = Undefined;
				For Each RightDetails In RightsList Do
					If SelectedPermissions = Undefined
					 Or SelectedPermissions.FindByValue(FirstRight.Value) <> Undefined Then
						FirstRight = RightDetails;
						Break;
					EndIf;
				EndDo;
				If FirstRight <> Undefined Then
					NameOfRight           = FirstRight.Value;
					RightPresentation = FirstRight.Presentation;
					FoundPermissions.Insert(FirstRight, True);
					OrderRight = 1;
				EndIf;
			EndIf;
		Else
			NameOfRight           = Rights[0].NameOfRight;
			RightPresentation = Rights[0].RightPresentation;
			OrderRight       = Rights[0].OrderRight;
		EndIf;
		For Each RoleDetails In DescriptionRolesWithoutPermissions Do
			NewRow = Rights.Add();
			NewRow.ObjectName           = FullObjectName;
			NewRow.ObjectPresentation = ObjectPresentation;
			NewRow.NameOfRole              = RoleDetails.NameOfRole;
			NewRow.RolePresentation    = RoleDetails.RolePresentation;
			NewRow.NameOfRight             = NameOfRight;
			NewRow.RightPresentation   = RightPresentation;
			NewRow.OrderRight         = OrderRight;
		EndDo;
	EndIf;
	
	If Rights.Count() = 0 Then
		NameOfRole = "";
		RolePresentation = "";
		Profile = Undefined;
	Else
		NameOfRole           = Rights[0].NameOfRole;
		RolePresentation = Rights[0].RolePresentation;
		Profile           = Rights[0].Profile;
	EndIf;
	
	For Each RightDetails In RightsList Do
		If FoundPermissions.Get(RightDetails) <> Undefined
		 Or SelectedPermissions <> Undefined
		   And SelectedPermissions.FindByValue(RightDetails.Value) = Undefined Then
			Continue;
		EndIf;
		NewRow = Rights.Add();
		NewRow.ObjectName           = FullObjectName;
		NewRow.ObjectPresentation = ObjectPresentation;
		NewRow.NameOfRole              = NameOfRole;
		NewRow.RolePresentation    = RolePresentation;
		NewRow.Profile              = Profile;
		NewRow.NameOfRight             = RightDetails.Value;
		NewRow.RightPresentation   = RightDetails.Presentation;
		NewRow.OrderRight         = RightsList.IndexOf(RightDetails) + 1;
	EndDo;
	
	Return Rights;
	
EndFunction

// Parameters:
//  FillOnlyDescriptionPermissions - Boolean
//
// Returns:
//  Structure:
//    * FullObjectName         - String
//    * RightsDetails             - See RightsDetails
//    * MetadataObject         - MetadataObject
//    * StandardAttributeName - String
//    * ObjectPresentation     - String
//  Undefined.
//
Function ReportContextByObject(FillOnlyDescriptionPermissions = False)
	
	SelectedObjects = ValuesofSelectedParameter("MetadataObject");
	If Not ValueIsFilled(SelectedObjects)
	 Or SelectedObjects.Count() <> 1 Then
		Return Undefined;
	EndIf;
	FullObjectName = SelectedObjects[0].Value;
	
	Context = New Structure;
	Context.Insert("FullObjectName", FullObjectName);
	
	If FullObjectName = "Configuration" Then
		MetadataObject = Metadata;
		PathToObject = "Configuration";
	Else
		PartsPathToObject = StrSplit(FullObjectName, ".");
		If PartsPathToObject[0] = "Subsystem" Then
			PathToObject = "Subsystem.*";
		Else
			ThisPartPath = True;
			For IndexOf = 0 To PartsPathToObject.UBound() Do
				If Not ThisPartPath Then
					PartsPathToObject[IndexOf] = "*";
				EndIf;
				ThisPartPath = Not ThisPartPath;
			EndDo;
			PathToObject = StrConcat(PartsPathToObject, ".");
		EndIf;
	EndIf;
	
	Tree = MetadataTree(True);
	TreeRow = Tree.Rows.Find(PathToObject, "PathToObject", True);
	If TreeRow = Undefined
	 Or TreeRow.RightsDetails = Undefined Then
		Return Undefined;
	EndIf;
	Context.Insert("RightsDetails", TreeRow.RightsDetails);
	
	If FillOnlyDescriptionPermissions Then
		Return Context;
	EndIf;
	
	If FullObjectName = "Configuration" Then
		ObjectPresentation = TreeRow.ObjectPresentation;
	Else
		StandardAttributeName = Undefined;
		ObjectPresentation      = "";
		ObjectsKindPresentation = "";
		NameParts = StrSplit(FullObjectName, ".");
		NumberofNames = Int(NameParts.Count() / 2);
		If NameParts.Count() <> NumberofNames * 2 Then
			Return Undefined;
		EndIf;
		CurrentFullName    = "";
		CurrentPathToObject = "";
		StandardTabularSection = Undefined;
		For NameNumber = 1 To NumberofNames Do
			IndexOf = (NameNumber - 1) * 2;
			If NameParts[IndexOf] = "StandardTabularSection" Then
				StandardAttributeName = NameParts[IndexOf + 1];
				StandardTabularSection = StandardTabularSection(MetadataObject, NameParts[IndexOf + 1]);
				If StandardTabularSection = Undefined Then
					Return Undefined;
				EndIf;
				CurrentObjectRepresentation = StandardTabularSection.Presentation();
				
			ElsIf NameParts[IndexOf] = "StandardAttribute" Then
				StandardAttributeName = ?(ValueIsFilled(StandardAttributeName),
					StandardAttributeName + ".", "") + NameParts[IndexOf + 1];
				StandardAttribute = StandardAttribute(?(StandardTabularSection = Undefined,
					MetadataObject, StandardTabularSection), NameParts[IndexOf + 1]);
				If StandardAttribute = Undefined Then
					Return Undefined;
				EndIf;
				CurrentObjectRepresentation = StandardAttribute.Presentation();
			Else
				CurrentFullName = ?(ValueIsFilled(CurrentFullName), CurrentFullName + ".", "")
					+ NameParts[IndexOf] + "." + NameParts[IndexOf + 1];
				MetadataObject = Common.MetadataObjectByFullName(CurrentFullName);
				If MetadataObject = Undefined Then
					Return Undefined;
				EndIf;
				CurrentObjectRepresentation = MetadataObject.Presentation();
			EndIf;
			ObjectPresentation = ?(ValueIsFilled(ObjectPresentation),
				ObjectPresentation + ".", "") + CurrentObjectRepresentation;
			If PartsPathToObject[0] = "Subsystem" Then
				CurrentTreeRow = TreeRow;
			Else
				CurrentPathToObject = ?(ValueIsFilled(CurrentPathToObject), CurrentPathToObject + ".", "")
					+ PartsPathToObject[IndexOf] + "." + PartsPathToObject[IndexOf + 1];
				CurrentTreeRow = Tree.Rows.Find(CurrentPathToObject, "PathToObject", True);
				If CurrentTreeRow = Undefined Then
					Return Undefined;
				EndIf;
			EndIf;
			ObjectsKindPresentation = ?(ValueIsFilled(ObjectsKindPresentation),
				ObjectsKindPresentation + ".", "") + CurrentTreeRow.ObjectPresentation;
		EndDo;
		ObjectPresentation = ObjectPresentation + " (" + ObjectsKindPresentation + ")";
	EndIf;
	
	Context.Insert("MetadataObject",         MetadataObject);
	Context.Insert("StandardAttributeName", StandardAttributeName);
	Context.Insert("ObjectPresentation",     ObjectPresentation);

	Return Context;
	
EndFunction

Function StandardTabularSection(MetadataObject, StandardTabularSectionName)
	
	ObjectProperties = New Structure("StandardTabularSections");
	FillPropertyValues(ObjectProperties, MetadataObject);
	
	If TypeOf(ObjectProperties.StandardTabularSections) <> Type("StandardTabularSectionDescriptions") Then
		Return Undefined;
	EndIf;
	
	For Each StandardTabularSection In ObjectProperties.StandardTabularSections Do
		StandardTabularSection = StandardTabularSection; // StandardTabularSectionDescription
		If StandardTabularSection.Name = StandardTabularSectionName Then
			Return StandardTabularSection;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

Function StandardAttribute(MetadataObject, StandardAttributeName)
	
	ObjectProperties = New Structure("StandardAttributes");
	FillPropertyValues(ObjectProperties, MetadataObject);
	
	If TypeOf(ObjectProperties.StandardAttributes) <> Type("StandardAttributeDescriptions") Then
		Return Undefined;
	EndIf;
	
	For Each StandardAttribute In ObjectProperties.StandardAttributes Do
		StandardAttribute = StandardAttribute; // StandardAttributeDescription
		If StandardAttribute.Name = StandardAttributeName Then
			Return StandardAttribute;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

Function FilterRoles(Fill)
	
	FilterRoles = New ValueTable;
	FilterRoles.Columns.Add("NameOfRole",              StringType(255));
	FilterRoles.Columns.Add("RolePresentation",    StringType(255));
	
	If Not Fill Then
		Return FilterRoles;
	EndIf;
	
	SelectedRoles = ValuesofSelectedParameter("Role");
	If Not ValueIsFilled(SelectedRoles)
	 Or SelectedRoles.Count() <> 1 Then
		Return FilterRoles;
	EndIf;
	
	NameOfRole = SelectedRoles[0].Value;
	RoleMetadata = Metadata.Roles.Find(NameOfRole);
	If RoleMetadata = Undefined Then
		Return FilterRoles;
	EndIf;
	
	NewRow = FilterRoles.Add();
	NewRow.NameOfRole = RoleMetadata.Name;
	NewRow.RolePresentation = RoleMetadata.Presentation();
	
	Return FilterRoles;
	
EndFunction

Function RightsRolesOnObject(Fill)
	
	Rights = New ValueTable;
	Rights.Columns.Add("ObjectName",           StringType(430));
	Rights.Columns.Add("ObjectPresentation", StringType(1000));
	Rights.Columns.Add("NameOfRole",              StringType(255));
	Rights.Columns.Add("RolePresentation",    StringType(255));
	Rights.Columns.Add("WithoutProfile",           New TypeDescription("Boolean"));
	Rights.Columns.Add("Profile",              New TypeDescription("CatalogRef.AccessGroupProfiles"));
	Rights.Columns.Add("AccessLevel",       NumberType(2));
	Rights.Columns.Add("HasLimit",      New TypeDescription("Boolean"));
	
	If Not Fill Then
		Return Rights;
	EndIf;
	
	ShowObjectsAndRolesWithoutPermissions = ShowObjectsAndRolesWithoutPermissions();
	
	Context = ReportContextByObject();
	If Context = Undefined Then
		Return Rights;
	EndIf;
	AccessLevels            = Context.RightsDetails.AccessLevels;
	MetadataObject         = Context.MetadataObject;
	StandardAttributeName = Context.StandardAttributeName;
	
	Context.Insert("Rights", Rights);
	Context.Insert("RoleProfiles", RoleProfiles());
	
	SelectedLevels = ValuesofSelectedParameter("AccessLevel");
	RolesDetails = RolesDetails(, True);
	
	ObjectsFields = New Map;
	For Each RoleDetails In RolesDetails Do
		For Each LevelDescription In AccessLevels Do
			If LevelDescription.ThisPermissionSet Then
				HasRight = ValueIsFilled(LevelDescription.Right);
				RightsSet = StrSplit(LevelDescription.Right, ",", False);
				For Each Right In RightsSet Do
					If Not AccessRight(Right, MetadataObject, RoleDetails.Metadata) Then
						HasRight = False;
						Break;
					EndIf;
				EndDo;
			Else
				HasRight = AccessRight(LevelDescription.Right, MetadataObject, RoleDetails.Metadata, StandardAttributeName);
			EndIf;
			If Not HasRight Then
				Continue;
			EndIf;
			If SelectedLevels <> Undefined
			   And SelectedLevels.FindByValue(LevelDescription.Level) = Undefined Then
				Break;
			EndIf;
			RoleDetails.HavePermissionsRoles = True;
			HasLimit = False;
			If ValueIsFilled(LevelDescription.RightWithRestriction) Then
				HasLimit = HasLimit(LevelDescription.RightWithRestriction,
					MetadataObject, ObjectsFields, RoleDetails.Metadata);
			EndIf;
			AddPermissionsProfileRoles(Context, RoleDetails, LevelDescription.Level, HasLimit);
			Break;
		EndDo;
		If Not RoleDetails.HavePermissionsRoles And ShowObjectsAndRolesWithoutPermissions Then
			AddPermissionsProfileRoles(Context, RoleDetails, 0, False);
		EndIf;
	EndDo;
	
	Return Rights;
	
EndFunction

// Returns:
//  Map of KeyAndValue:
//   * Key - CatalogRef.MetadataObjectIDs,
//          - CatalogRef.ExtensionObjectIDs
//   * Value - Array of CatalogRef.AccessGroupProfiles
//
Function RoleProfiles()
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	ProfilesRoles.Role AS Role,
	|	ProfilesRoles.Ref AS Profile
	|FROM
	|	Catalog.AccessGroupProfiles.Roles AS ProfilesRoles
	|WHERE
	|	&ProfileSelection
	|TOTALS BY
	|	Role";
	
	SelectedProfiles = ValuesofSelectedParameter("Profile");
	If SelectedProfiles = Undefined Then
		Query.Text = StrReplace(Query.Text, "&ProfileSelection", "TRUE");
	Else
		Query.Text = StrReplace(Query.Text, "&ProfileSelection",
			"ProfilesRoles.Ref IN(&Profiles)");
		Query.SetParameter("Profiles", SelectedProfiles.UnloadValues());
	EndIf;
	
	Selection = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	RoleProfiles = New Map;
	While Selection.Next() Do
		ProfileSelectionig = Selection.Select();
		Profiles = New Array;
		RoleProfiles.Insert(Selection.Role, Profiles);
		While ProfileSelectionig.Next() Do
			Profiles.Add(ProfileSelectionig.Profile);
		EndDo;
	EndDo;
	
	Return RoleProfiles;
	
EndFunction

// Parameters:
//  Profiles - Array of CatalogRef.AccessGroupProfiles
//
// Returns:
//  Array of String - Role names.
//
Function ListRoleNamesProfiles(Profiles)
	
	Query = New Query;
	Query.SetParameter("Profiles", Profiles);
	Query.Text =
	"SELECT DISTINCT
	|	ProfilesRoles.Role AS Role
	|FROM
	|	Catalog.AccessGroupProfiles.Roles AS ProfilesRoles
	|WHERE
	|	ProfilesRoles.Ref.IsFolder = FALSE
	|	AND ProfilesRoles.Ref IN(&Profiles)";
	
	RoleIDs = Query.Execute().Unload().UnloadColumn("Role");
	
	RoleMetadataObjects = Common.MetadataObjectsByIDs(
		RoleIDs, False);
	
	RolesList = New ValueList;
	For Each KeyAndValue In RoleMetadataObjects Do
		MetadataObjectRole = KeyAndValue.Value;
		If TypeOf(MetadataObjectRole) <> Type("MetadataObject") Then
			Continue;
		EndIf;
		RolesList.Add(MetadataObjectRole.Name, MetadataObjectRole.Synonym);
	EndDo;
	
	RolesList.SortByPresentation();
	
	Return RolesList;
	
EndFunction

// Parameters:
//  Profiles - Array of CatalogRef.AccessGroupProfiles
//
// Returns:
//  Array of CatalogRef.AccessGroupProfiles - Profiles without a group.
//
Function ProfileListWithoutGroups(Profiles)
	
	Query = New Query;
	Query.SetParameter("Profiles", Profiles);
	Query.Text =
	"SELECT
	|	Profiles.Ref AS Profile
	|FROM
	|	Catalog.AccessGroupProfiles AS Profiles
	|WHERE
	|	Profiles.IsFolder = FALSE
	|	AND Profiles.Ref IN(&Profiles)
	|
	|ORDER BY
	|	Profiles.Description";
	
	Profiles = Query.Execute().Unload().UnloadColumn("Profile");
	
	ProfileList = New ValueList;
	ProfileList.LoadValues(Profiles);
	
	Return ProfileList;
	
EndFunction


Function DescriptionProfiles()
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	Profiles.Ref AS Ref,
	|	Profiles.Description AS Description
	|FROM
	|	Catalog.AccessGroupProfiles AS Profiles
	|
	|ORDER BY
	|	Description";
	
	DescriptionProfiles = RolesDetails(False).Copy(New Array,
			"RoleCode, NameOfRole, RolePresentation, HavePermissionsRoles");
	DescriptionProfiles.Columns.Add("Profile",
		New TypeDescription("CatalogRef.AccessGroupProfiles"));
	
	CurrentNumber = 1;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		NewRow = DescriptionProfiles.Add();
		NewRow.RoleCode           = CurrentNumber;
		NewRow.NameOfRole           = Selection.Description;
		NewRow.RolePresentation = NewRow.NameOfRole;
		NewRow.Profile           = Selection.Ref;
		CurrentNumber = CurrentNumber + 1;
	EndDo;
	
	NewRow = DescriptionProfiles.Add();
	NewRow.RoleCode           = CurrentNumber;
	NewRow.NameOfRole           = NStr("vi = '<Không có hồ sơ>';
										|ru = '<Без профиля>';
										|en = '<Without a profile>'; fa = '<Without a profile>';
										|it = '<senza profilo>';
										|pl = '<Bez profilu>';
										|tr = '<Profil Yok>'");
	NewRow.RolePresentation = NewRow.NameOfRole;
	NewRow.Profile           = Catalogs.AccessGroupProfiles.EmptyRef();
	
	DescriptionProfiles.Indexes.Add("Profile");
	
	Return DescriptionProfiles;
	
EndFunction

Procedure AddPermissionsProfileRoles(Context, RoleDetails, AccessLevel, HasLimit)
	
	IsProfilesRoles = Context.RoleProfiles.Get(RoleDetails.Ref);
	EmptyProfile = Catalogs.AccessGroupProfiles.EmptyRef();
	
	If Not ValueIsFilled(IsProfilesRoles) Then
		IsProfilesRoles = CommonClientServer.ValueInArray(EmptyProfile);
	EndIf;
	
	For Each Profile In IsProfilesRoles Do
		NewRow = Context.Rights.Add();
		NewRow.ObjectName           = Context.FullObjectName;
		NewRow.ObjectPresentation = Context.ObjectPresentation;
		NewRow.NameOfRole              = RoleDetails.NameOfRole;
		NewRow.RolePresentation    = RoleDetails.RolePresentation;
		NewRow.WithoutProfile           = Profile = EmptyProfile;
		NewRow.Profile              = Profile;
		NewRow.AccessLevel       = AccessLevel;
		NewRow.HasLimit      = HasLimit;
	EndDo;
	
EndProcedure

Function ShowPermissionsOnDetails()
	
	FilterField = SettingsComposer.GetSettings().DataParameters.Items.Find("RightsOnDetails");
	
	Return FilterField.Value = True;
	
EndFunction

Function ShowObjectsAndRolesWithoutPermissions()
	
	FilterField = SettingsComposer.GetSettings().DataParameters.Items.Find("ShowObjectsAndRolesWithoutPermissions");
	
	Return FilterField.Value = True;
	
EndFunction

Function ShowPermissionsofNonInterfaceSubsystems()
	
	FilterField = SettingsComposer.GetSettings().DataParameters.Items.Find("ShowPermissionsofNonInterfaceSubsystems");
	
	Return FilterField.Value = True;
	
EndFunction

Function ValuesofSelectedParameter(ParameterName, UsedAlways = False)
	
	Settings = SettingsComposer.GetSettings();
	FilterField = Settings.DataParameters.Items.Find(ParameterName);
	
	If Not FilterField.Use And Not UsedAlways Then
		Return Undefined;
	EndIf;
	
	If TypeOf(FilterField.Value) = Type("ValueList") Then
		Return FilterField.Value;
	EndIf;
	
	List = New ValueList;
	List.Add(FilterField.Value);
	
	Return List;
	
EndFunction

Function RolesRights(Fill, ProfilesInsteadofRoles, HierarchyOnly = False)
	
	Hierarchy = New ValueTable;
	Hierarchy.Columns.Add("ParentCode",            StringType(50));
	Hierarchy.Columns.Add("ElementCode",            StringType(50));
	Hierarchy.Columns.Add("PictureIndex",         NumberType(2));
	Hierarchy.Columns.Add("TagName",            StringType(255));
	Hierarchy.Columns.Add("ItemPresentation",  StringType(1000));
	Hierarchy.Columns.Add("HaveElementRights",      New TypeDescription("Boolean"));
	Hierarchy.Columns.Add("YesRightWithRestriction", New TypeDescription("Boolean"));
	Hierarchy.Columns.Add("FullObjectName",       StringType(430));
	
	Rights = New ValueTable;
	Rights.Columns.Add("ElementCode",     StringType(50));
	Rights.Columns.Add("RoleCode",         NumberType(4));
	Rights.Columns.Add("AccessLevel",  NumberType(2));
	Rights.Columns.Add("HasLimit", New TypeDescription("Boolean"));
	
	RolesDetails = RolesDetails(Fill, ProfilesInsteadofRoles);
	
	Result = New Structure;
	Result.Insert("Hierarchy", Hierarchy);
	Result.Insert("Rights",    Rights);
	Result.Insert("Roles",     RolesDetails);
	
	If Not Fill Then
		Return Result;
	EndIf;

	Context = New Structure;
	Context.Insert("ProfilesInsteadofRoles", ProfilesInsteadofRoles);
	Context.Insert("RolesDetails",      RolesDetails);
	Context.Insert("RolesMetadata",    RolesDetails.UnloadColumn("Metadata"));
	Context.Insert("Hierarchy",           Hierarchy);
	Context.Insert("Rights",              Rights);
	Context.Insert("Images",           Images());
	Context.Insert("ObjectsFields",       New Map);
	Context.Insert("ObjectsWithoutRights",     ShowObjectsAndRolesWithoutPermissions() Or HierarchyOnly);
	Context.Insert("SelectedOMD",       ValuesofSelectedParameter("MetadataObject"));
	Context.Insert("SelectedLevels",    ValuesofSelectedParameter("AccessLevel"));
	Context.Insert("AllSubsystems",      ShowPermissionsofNonInterfaceSubsystems());
	
	If ProfilesInsteadofRoles Then
		Context.Insert("DescriptionProfiles", DescriptionProfiles());
		Context.Insert("RoleProfiles",     RoleProfiles());
		Result.Roles = Context.DescriptionProfiles;
	EndIf;
	
	Tree = MetadataTree(ShowPermissionsOnDetails());
	If HierarchyOnly Then
		ClearDescriptionRights(Tree.Rows);
	EndIf;
	ProcessTreeRows(Context, Tree.Rows, "", False);
	
	If HierarchyOnly Then
		Return Result;
	EndIf;
	
	If Context.ObjectsWithoutRights Then
		Filter = New Structure("HavePermissionsRoles", False);
		Rows = Result.Roles.FindRows(Filter);
		ItemCodeConfig = Hierarchy[0].ElementCode;
		For Each RoleDetails In Rows Do
			StringRight = Rights.Add();
			StringRight.ElementCode = ItemCodeConfig;
			StringRight.RoleCode     = RoleDetails.RoleCode;
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

Function StringType(StringLength)
	
	Return New TypeDescription("String",,,, New StringQualifiers(StringLength))
	
EndFunction

Function NumberType(NumberOfDigits)
	
	Return New TypeDescription("Number",,,
		New NumberQualifiers(NumberOfDigits, 0, AllowedSign.Nonnegative));
	
EndFunction

Function TypeMetadataObjectId()
	
	Return New TypeDescription("CatalogRef.MetadataObjectIDs,
		|CatalogRef.ExtensionObjectIDs");
	
EndFunction

Function RolesDetails(Fill = True, withidentifiers = False)
	
	RolesDetails = New ValueTable;
	RolesDetails.Columns.Add("Metadata",        New TypeDescription("MetadataObject"));
	RolesDetails.Columns.Add("RoleCode",           NumberType(4));
	RolesDetails.Columns.Add("NameOfRole",           StringType(255));
	RolesDetails.Columns.Add("RolePresentation", StringType(255));
	RolesDetails.Columns.Add("HavePermissionsRoles",     New TypeDescription("Boolean"));
	RolesDetails.Columns.Add("Ref",            TypeMetadataObjectId());
	
	If Not Fill Then
		Return RolesDetails;
	EndIf;
	
	SelectedRoles = ValuesofSelectedParameter("Role");
	
	CurrentNumber = 1;
	For Each Role In Metadata.Roles Do
		If SelectedRoles <> Undefined
		   And SelectedRoles.FindByValue(Role.Name) = Undefined Then
			Continue;
		EndIf;
		NewRow = RolesDetails.Add();
		NewRow.RoleCode           = CurrentNumber;
		NewRow.Metadata        = Role;
		NewRow.NameOfRole           = Role.Name;
		NewRow.RolePresentation = Role.Presentation();
		CurrentNumber = CurrentNumber + 1;
	EndDo;
	
	If withidentifiers Then
		RolesofSelectedProfiles = RolesofSelectedProfiles();
		IDs = Common.MetadataObjectIDs(
			RolesDetails.UnloadColumn("Metadata"));
		IndexOf = RolesDetails.Count() - 1;
		While IndexOf >= 0 Do
			RoleDetails = RolesDetails[IndexOf];
			RoleRef = IDs.Get(RoleDetails.Metadata.FullName());
			If RolesofSelectedProfiles <> Undefined
			   And RolesofSelectedProfiles.Get(RoleRef) = Undefined Then
				RolesDetails.Delete(RoleDetails);
			Else
				RoleDetails.Ref = RoleRef;
			EndIf;
			IndexOf = IndexOf - 1;
		EndDo;
	EndIf;
	
	RolesDetails.Indexes.Add("Metadata");
	
	Return RolesDetails;
	
EndFunction

Function RolesofSelectedProfiles()
	
	SelectedProfiles = ValuesofSelectedParameter("Profile");
	If SelectedProfiles = Undefined Then
		Return Undefined;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Profiles", SelectedProfiles.UnloadValues());
	Query.Text =
	"SELECT DISTINCT
	|	ProfilesRoles.Role AS Role
	|FROM
	|	Catalog.AccessGroupProfiles.Roles AS ProfilesRoles
	|WHERE
	|	ProfilesRoles.Ref IN(&Profiles)";
	
	Selection = Query.Execute().Select();
	
	Roles = New Map;
	While Selection.Next() Do
		Roles.Insert(Selection.Role, True);
	EndDo;
	
	Return Roles;
	
EndFunction

Procedure ProcessTreeRows(Context, TreeRows, ParentCode, RowsIsPermissions)
	
	Counter = 0;
	PropertyIncludeInCommandInterface = New Structure("IncludeInCommandInterface", True);
	
	Count = TreeRows.Count();
	For Each TreeRow In TreeRows Do
		If TreeRow.NoGroup Then
			Count = Count - 1 + ItemCount(TreeRow.Metadata);
		EndIf;
	EndDo;
	NumberDigits = StrLen(Count);
	
	For Each TreeRow In TreeRows Do
		Counter = Counter + 1;
		PictureIndex = PictureIndex(Context, TreeRow.Name);
		StringHierarchyIsRights = False;
		If TreeRow.NoGroup Then
			RowCode = ParentCode;
		Else
			RowCode = ParentCode + Right("00000000" + Format(Counter, "NG="), NumberDigits);
			HierarchyLine = Context.Hierarchy.Add();
			HierarchyLine.ParentCode           = ParentCode;
			HierarchyLine.ElementCode           = RowCode;
			HierarchyLine.PictureIndex        = PictureIndex;
			HierarchyLine.TagName           = TreeRow.Presentation;
			HierarchyLine.ItemPresentation = TreeRow.Presentation;
		EndIf;
		
		StringsAttachments = Undefined;
		If TypeOf(TreeRow.Metadata) = Type("MetadataObjectCollection")
		 Or TypeOf(TreeRow.Metadata) = Type("StandardAttributeDescriptions")
		 Or TypeOf(TreeRow.Metadata) = Type("StandardTabularSectionDescriptions") Then
			
			ObjectNumber = ?(TreeRow.NoGroup, Counter, 0);
			If TreeRow.Rows.Count() > 0 Then
				StringsAttachments = TreeRow.Rows;
			EndIf;
			If TypeOf(TreeRow.Metadata) = Type("MetadataObjectCollection") Then
				SelectedMetadataObjects = Context.SelectedOMD;
				If SelectedMetadataObjects <> Undefined
				   And SelectedMetadataObjects.FindByValue(TreeRow.Name) <> Undefined Then
					SelectedMetadataObjects = Undefined;
				EndIf;
			Else
				SelectedMetadataObjects = Undefined;
			EndIf;
			NumberDigitsForObjects = ?(TreeRow.NoGroup, NumberDigits,
				StrLen(ItemCount(TreeRow.Metadata)));
			For Each MetadataObject In TreeRow.Metadata Do
				HierarchyOnly = False;
				If SelectedMetadataObjects <> Undefined Then
					FullName = MetadataObject.FullName();
					If SelectedMetadataObjects.FindByValue(FullName) = Undefined
					   And (TreeRow.Name <> "Subsystems"
					        And StrSplit(FullName, ".", False).Count() < 3
					      Or TreeRow.Name = "Subsystems"
					        And Not ThisParentSubsystem(SelectedMetadataObjects, FullName, HierarchyOnly)) Then
						Continue;
					EndIf;
				EndIf;
				If Not Context.AllSubsystems Then
					PropertyIncludeInCommandInterface.IncludeInCommandInterface = True;
					FillPropertyValues(PropertyIncludeInCommandInterface, MetadataObject);
					If Not PropertyIncludeInCommandInterface.IncludeInCommandInterface Then
						HierarchyOnly = True;
					EndIf;
				EndIf;
				ObjectNumber = ObjectNumber + 1;
				ElementCode = RowCode + Right("00000000" + Format(ObjectNumber, "NG="), NumberDigitsForObjects);
				ExtraStringHierarchy = Context.Hierarchy.Add();
				ExtraStringHierarchy.ParentCode           = RowCode;
				ExtraStringHierarchy.ElementCode           = ElementCode;
				ExtraStringHierarchy.PictureIndex        = PictureIndex;
				ExtraStringHierarchy.TagName           = MetadataObject.Name;
				ExtraStringHierarchy.ItemPresentation = MetadataObject.Presentation();
				HasRights = False;
				If Not HierarchyOnly Then
					If Not TreeRow.WithoutDecryption Then
						If TypeOf(MetadataObject) = Type("StandardTabularSectionDescription") Then
							ExtraStringHierarchy.FullObjectName = TreeRow.ParentMetadataAttachments.FullName()
								+ ".StandardTabularSection." + MetadataObject.Name;
						ElsIf TypeOf(MetadataObject) = Type("StandardAttributeDescription") Then
							If TypeOf(TreeRow.ParentMetadataAttachments) = Type("StandardTabularSectionDescription") Then
								ExtraStringHierarchy.FullObjectName = TreeRow.Parent.ParentMetadataAttachments.FullName()
									+ ".StandardTabularSection." + TreeRow.ParentMetadataAttachments.Name
									+ ".StandardAttribute." + MetadataObject.Name;
							Else
								ExtraStringHierarchy.FullObjectName = TreeRow.ParentMetadataAttachments.FullName()
									+ ".StandardAttribute." + MetadataObject.Name;
							EndIf;
						Else
							ExtraStringHierarchy.FullObjectName = MetadataObject.FullName();
						EndIf;
					EndIf;
					withlimit = False;
					If TypeOf(TreeRow.Metadata) = Type("MetadataObjectCollection") Then
						AddRights(Context, MetadataObject, TreeRow, ElementCode, HasRights, withlimit);
					ElsIf TypeOf(TreeRow.ParentMetadataAttachments) = Type("StandardTabularSectionDescription") Then
						AddRights(Context, TreeRow.Parent.ParentMetadataAttachments, TreeRow, ElementCode,
							HasRights, withlimit, TreeRow.ParentMetadataAttachments.Name + "." + MetadataObject.Name);
					Else
						AddRights(Context, TreeRow.ParentMetadataAttachments, TreeRow, ElementCode,
							HasRights, withlimit, MetadataObject.Name);
					EndIf;
					ExtraStringHierarchy.YesRightWithRestriction = withlimit;
				EndIf;
				If StringsAttachments <> Undefined Then
					For Each StringAttachments In StringsAttachments Do
						StringAttachments.ParentMetadataAttachments = MetadataObject;
						StringAttachments.Metadata = MetadataObject[StringAttachments.AttachmentName];
					EndDo;
					ProcessTreeRows(Context, TreeRow.Rows, ElementCode, HasRights);
				ElsIf TreeRow.HasHierarchy Then
					RowDescription = New Structure("Rows, Name,Metadata,RightsDetails,Presentation,
						|AttachmentName,NoGroup,WithoutDecryption,HasHierarchy");
					FillPropertyValues(RowDescription, TreeRow);
					RowDescription.Metadata = MetadataObject[TreeRow.AttachmentName];
					DescriptionStrings = New Array;
					DescriptionStrings.Add(RowDescription);
					ProcessTreeRows(Context, DescriptionStrings, ElementCode, HasRights);
				EndIf;
				If HasRights Then
					StringHierarchyIsRights = True;
					ExtraStringHierarchy.HaveElementRights = True;
				ElsIf Not Context.ObjectsWithoutRights Then
					ObjectNumber = ObjectNumber - 1;
					Context.Hierarchy.Delete(ExtraStringHierarchy);
				EndIf;
			EndDo;
			If TreeRow.NoGroup Then
				Counter = ObjectNumber;
			EndIf;
		ElsIf TypeOf(TreeRow.Metadata) = Type("ConfigurationMetadataObject") Then
			If Context.SelectedOMD = Undefined
			 Or Context.SelectedOMD.FindByValue("Configuration") <> Undefined Then
				AddRights(Context, TreeRow.Metadata, TreeRow, RowCode, StringHierarchyIsRights);
			EndIf;
			HierarchyLine.FullObjectName = "Configuration";
		EndIf;
		If StringsAttachments = Undefined Then
			ProcessTreeRows(Context, TreeRow.Rows, RowCode, StringHierarchyIsRights);
		EndIf;
		If StringHierarchyIsRights Then
			RowsIsPermissions = True;
			If Not TreeRow.NoGroup Then
				HierarchyLine.HaveElementRights = True;
			EndIf;
		ElsIf Not Context.ObjectsWithoutRights And Not TreeRow.NoGroup Then
			Counter = Counter - 1;
			Context.Hierarchy.Delete(HierarchyLine);
		EndIf;
	EndDo;
	
EndProcedure

Function ItemCount(Collection)
	
	If TypeOf(Collection) = Type("MetadataObjectCollection")
	 Or TypeOf(Collection) = Type("StandardAttributeDescriptions") Then
		Return Collection.Count();
		
	ElsIf TypeOf(Collection) = Type("StandardTabularSectionDescriptions") Then
		Count = 0;
		//@skip-check module-unused-local-variable
		For Each CollectionItem In Collection Do
			Count = Count + 1;
		EndDo;
		Return Count;
	EndIf;
	
	Return 1;
	
EndFunction

Function ThisParentSubsystem(SelectedMetadataObjects, FullSubsystemName, AddWIerarchy)
	
	For Each ListItem In SelectedMetadataObjects Do
		If StrStartsWith(ListItem.Value, FullSubsystemName) Then
			AddWIerarchy = True;
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Procedure AddRights(Context, MetadataObject, TreeRow, ElementCode, HasRights,
			withlimit = False, StandardAttributeName = Undefined)
	
	If Not ValueIsFilled(TreeRow.RightsDetails) Then
		Return;
	EndIf;
	
	SelectedLevels = Context.SelectedLevels;
	If SelectedLevels <> Undefined Then
		HaveAccessLevel = False;
		For Each LevelDescription In TreeRow.RightsDetails.AccessLevels Do
			If SelectedLevels.FindByValue(LevelDescription.Level) <> Undefined Then
				HaveAccessLevel = True;
				Break;
			EndIf;
		EndDo;
		If Not HaveAccessLevel Then
			Return;
		EndIf;
	EndIf;
	
	HaveRightSet = False;
	RightsLevels = New Array;
	For Each LevelDescription In TreeRow.RightsDetails.AccessLevels Do
		RightsLevels.Add(LevelDescription.Right);
		If LevelDescription.ThisPermissionSet Then
			HaveRightSet = True;
		EndIf;
	EndDo;
	
	If Context.ProfilesInsteadofRoles Then
		Context.Insert("EmptyProfile", Catalogs.AccessGroupProfiles.EmptyRef());
		Context.Insert("ProfileRightsStrings", New Map);
	EndIf;
	Context.Insert("ElementCode", ElementCode);
	RolesMetadata = Context.RolesMetadata;
	AccessLevels   = TreeRow.RightsDetails.AccessLevels;
	
	If HaveRightSet Then
		For Each Role In RolesMetadata Do
			For Each LevelDescription In AccessLevels Do
				If LevelDescription.ThisPermissionSet Then
					HasRight = ValueIsFilled(LevelDescription.Right);
					RightsSet = StrSplit(LevelDescription.Right, ",", False);
					For Each Right In RightsSet Do
						If Not AccessRight(Right, MetadataObject, Role) Then
							HasRight = False;
							Break;
						EndIf;
					EndDo;
				Else
					HasRight = AccessRight(LevelDescription.Right, MetadataObject, Role, StandardAttributeName);
				EndIf;
				If Not HasRight Then
					Continue;
				EndIf;
				HasRights = True;
				If ValueIsFilled(LevelDescription.RightWithRestriction) Then
					withlimit = True;
				EndIf;
				SetRight(Context, LevelDescription, MetadataObject, Role);
			EndDo;
		EndDo;
	Else
		For Each Role In RolesMetadata Do
			For Each Right In RightsLevels Do
				If AccessRight(Right, MetadataObject, Role, StandardAttributeName) Then
					LevelDescription = AccessLevels[RightsLevels.Find(Right)];
					HasRights = True;
					If ValueIsFilled(LevelDescription.RightWithRestriction) Then
						withlimit = True;
					EndIf;
					SetRight(Context, LevelDescription, MetadataObject, Role);
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
EndProcedure

Procedure SetRight(Context, LevelDescription, MetadataObject, Role)
	
	If Context.SelectedLevels <> Undefined
	   And Context.SelectedLevels.FindByValue(LevelDescription.Level) = Undefined Then
		Return;
	EndIf;
	RoleDetails = Context.RolesDetails.Find(Role, "Metadata");
	RoleDetails.HavePermissionsRoles = True;
	HasLimit = False;
	If ValueIsFilled(LevelDescription.RightWithRestriction) Then
		HasLimit = HasLimit(LevelDescription.RightWithRestriction,
			MetadataObject, Context.ObjectsFields, RoleDetails.Metadata);
	EndIf;
	If Context.ProfilesInsteadofRoles Then
		DescriptionProfiles   = Context.DescriptionProfiles;
		ProfileRightsStrings = Context.ProfileRightsStrings;
		IsProfilesRoles = Context.RoleProfiles.Get(RoleDetails.Ref);
		If Not ValueIsFilled(IsProfilesRoles) Then
			IsProfilesRoles = CommonClientServer.ValueInArray(Context.EmptyProfile);
		EndIf;
		For Each Profile In IsProfilesRoles Do
			StringRight = ProfileRightsStrings.Get(Profile);
			If StringRight = Undefined Then
				Filter = New Structure("Profile", Profile);
				FoundRows = DescriptionProfiles.FindRows(Filter);
				If FoundRows.Count() <> 1 Then
					Continue;
				EndIf;
				ProfileDetails = FoundRows[0];
				ProfileDetails.HavePermissionsRoles = True;
				StringRight = Context.Rights.Add();
				StringRight.ElementCode     = Context.ElementCode;
				StringRight.RoleCode         = ProfileDetails.RoleCode;
				StringRight.AccessLevel  = LevelDescription.Level;
				StringRight.HasLimit = HasLimit;
				ProfileRightsStrings.Insert(Profile, StringRight);
			Else
				If StringRight.AccessLevel < LevelDescription.Level Then
					StringRight.AccessLevel = LevelDescription.Level;
				EndIf;
				If Not HasLimit And StringRight.HasLimit Then
					StringRight.HasLimit = False;
				EndIf;
			EndIf;
		EndDo;
	Else
		StringRight = Context.Rights.Add();
		StringRight.ElementCode     = Context.ElementCode;
		StringRight.RoleCode         = RoleDetails.RoleCode;
		StringRight.AccessLevel  = LevelDescription.Level;
		StringRight.HasLimit = HasLimit;
	EndIf;
	
EndProcedure

Function HasLimit(NameOfRight, MetadataObject, ObjectsFields, Role);
	
	Fields = ObjectsFields.Get(MetadataObject);
	
	If Fields = Undefined Then
		Fields = InformationRegisters.RolesRights.AllFieldsOfMetadataObjectAccessRestriction(
			MetadataObject, MetadataObject.FullName());
		ObjectsFields.Insert(MetadataObject, Fields);
	EndIf;
	
	Return AccessParameters(NameOfRight, MetadataObject, Fields, Role).RestrictionByCondition;
	
EndFunction

Procedure ClearDescriptionRights(TreeRows)
	
	For Each String In TreeRows Do
		String.RightsDetails = Undefined;
		ClearDescriptionRights(String.Rows);
	EndDo;
	
EndProcedure

// Returns:
//  ValueTree:
//   * Name                  - String
//   * Metadata           - MetadataObject
//                          - Undefined
//   * RightsDetails         - See RightsDetails
//   * Presentation        - String
//   * ObjectPresentation - String
//   * AttachmentName          - String
//   * NoGroup            - Boolean
//   * HasHierarchy         - Boolean
//   * WithoutDecryption       - Boolean
//   * PathToObject         - String
//   * ParentMetadataAttachments - MetadataObject
//                                - Undefined
//
Function MetadataTree(WithFields)
	
	Tree = New ValueTree;
	Tree.Columns.Add("Name",                  StringType(150));
	Tree.Columns.Add("Metadata");
	Tree.Columns.Add("RightsDetails",         New TypeDescription("Structure"));
	Tree.Columns.Add("Presentation",        StringType(150));
	Tree.Columns.Add("ObjectPresentation", StringType(150));
	Tree.Columns.Add("AttachmentName",          StringType(100));
	Tree.Columns.Add("NoGroup",            New TypeDescription("Boolean"));
	Tree.Columns.Add("HasHierarchy",         New TypeDescription("Boolean"));
	Tree.Columns.Add("WithoutDecryption",       New TypeDescription("Boolean"));
	Tree.Columns.Add("PathToObject",         StringType(255));
	Tree.Columns.Add("ParentMetadataAttachments"); // Populated automatically.
	
	// Configuration
	ConfigurationString = Tree.Rows.Add();
	ConfigurationString.Name                  = "Configuration";
	ConfigurationString.Metadata           = Metadata;
	ConfigurationString.RightsDetails         = ConfigRights();
	ConfigurationString.PathToObject         = "Configuration";
	ConfigurationString.Presentation        = NStr("vi = 'Cấu hình';
													|ru = 'Конфигурация';
													|en = 'Configuration'; fa = 'پیکربندی';
													|it = 'Configurazione';
													|pl = 'Configuration';
													|tr = 'Yapılandırma'");
	ConfigurationString.ObjectPresentation = NStr("vi = 'Cấu hình';
													|ru = 'Конфигурация';
													|en = 'Configuration'; fa = 'پیکربندی';
													|it = 'Configurazione';
													|pl = 'Configuration';
													|tr = 'Yapılandırma'");
	
	// Configuration.Common
	StringGeneral = ConfigurationString.Rows.Add();
	StringGeneral.Name           = "Overall";
	StringGeneral.Presentation = NStr("vi = 'Chung';
										|ru = 'Общие';
										|en = 'Common'; fa = 'مشترک';
										|it = 'Generali';
										|pl = 'Common';
										|tr = 'Ortak'");
	
	// Configuration.Common.FilterCriteria.Subsystems
	SubsystemRow = StringGeneral.Rows.Add();
	SubsystemRow.Name                  = "Subsystems";
	SubsystemRow.Metadata           = Metadata.Subsystems;
	SubsystemRow.RightsDetails         = ViewRight();
	SubsystemRow.PathToObject         = "Subsystem.*";
	SubsystemRow.Presentation        = NStr("vi = 'Phân hệ';
											|ru = 'Подсистемы';
											|en = 'Subsystems'; fa = 'Subsystems';
											|it = 'Sottosistemi';
											|pl = 'Subsystems';
											|tr = 'Alt sistemler'");
	SubsystemRow.ObjectPresentation = NStr("vi = 'Phân hệ';
											|ru = 'Подсистема';
											|en = 'Subsystem'; fa = 'زیرسیستم';
											|it = 'Sottosistema';
											|pl = 'Subsystem';
											|tr = 'Alt sistem'");
	
	// Configuration.Common.FilterCriteria.Subsystems.Subsystems.*
	StringNestedSubsystems = SubsystemRow.Rows.Add();
	StringNestedSubsystems.Name                  = "Subsystems";
	StringNestedSubsystems.Metadata           = "Subsystems";
	StringNestedSubsystems.PathToObject         = "Subsystem.*.Subsystem.*";
	StringNestedSubsystems.RightsDetails         = ViewRight();
	StringNestedSubsystems.Presentation        = NStr("vi = 'Phân hệ';
														|ru = 'Подсистемы';
														|en = 'Subsystems'; fa = 'Subsystems';
														|it = 'Sottosistemi';
														|pl = 'Subsystems';
														|tr = 'Alt sistemler'");
	StringNestedSubsystems.ObjectPresentation = NStr("vi = 'Phân hệ';
													|ru = 'Подсистема';
													|en = 'Subsystem'; fa = 'زیرسیستم';
													|it = 'Sottosistema';
													|pl = 'Subsystem';
													|tr = 'Alt sistem'");
	StringNestedSubsystems.AttachmentName          = "Subsystems";
	StringNestedSubsystems.NoGroup            = True;
	StringNestedSubsystems.HasHierarchy         = True;
	
	// Configuration.Common.FilterCriteria.SessionParameters
	StringSessionParameters = StringGeneral.Rows.Add();
	StringSessionParameters.Name                  = "SessionParameters";
	StringSessionParameters.Metadata           = Metadata.SessionParameters;
	StringSessionParameters.PathToObject         = "SessionParameter.*";
	StringSessionParameters.RightsDetails         = SessionSettingRights();
	StringSessionParameters.Presentation        = NStr("vi = 'Tham số phiên làm việc';
														|ru = 'Параметры сеанса';
														|en = 'Session parameters'; fa = 'Session parameters';
														|it = 'Parametri della sessione';
														|pl = 'Parametry sesji';
														|tr = 'Oturum parametreleri'");
	StringSessionParameters.ObjectPresentation = NStr("vi = 'Tham số phiên làm việc';
														|ru = 'Параметр сеанса';
														|en = 'Session parameter'; fa = 'Session parameter';
														|it = 'Parametro della sessione';
														|pl = 'Parametry sesji';
														|tr = 'Oturum parametresi'");
	
	// Configuration.Common.FilterCriteria.CommonAttributes
	StringGeneralRequisites = StringGeneral.Rows.Add();
	StringGeneralRequisites.Name                  = "CommonAttributes";
	StringGeneralRequisites.Metadata           = Metadata.CommonAttributes;
	StringGeneralRequisites.PathToObject         = "CommonAttribute.*";
	StringGeneralRequisites.RightsDetails         = RightsAttributes();
	StringGeneralRequisites.Presentation        = NStr("vi = 'Mục tin chung';
														|ru = 'Общие реквизиты';
														|en = 'Common attributes'; fa = 'Common attributes';
														|it = 'Requisiti generali';
														|pl = 'Informacje ogólne';
														|tr = 'Ortak öznitelikler'");
	StringGeneralRequisites.ObjectPresentation = NStr("vi = 'Mục tin chung';
														|ru = 'Общий реквизит';
														|en = 'Common attribute'; fa = 'Common attribute';
														|it = 'Requisito generale';
														|pl = 'Wspólny rekwizyt';
														|tr = 'Ortak öznitelik'");
	
	// Configuration.Common.FilterCriteria.ExchangePlans
	StringExchangePlans = StringGeneral.Rows.Add();
	StringExchangePlans.Name                  = "ExchangePlans";
	StringExchangePlans.Metadata           = Metadata.ExchangePlans;
	StringExchangePlans.PathToObject         = "ExchangePlan.*";
	StringExchangePlans.RightsDetails         = ExchangePlanRights();
	StringExchangePlans.Presentation        = NStr("vi = 'Sơ đồ trao đổi';
													|ru = 'Планы обмена';
													|en = 'Exchange plans'; fa = 'Exchange plans';
													|it = 'Piani di scambio';
													|pl = 'Plany wymiany';
													|tr = 'Değiştirme planları'");
	StringExchangePlans.ObjectPresentation = NStr("vi = 'Sơ đồ trao đổi';
													|ru = 'План обмена';
													|en = 'Exchange plan'; fa = 'طرح تبادل';
													|it = 'Piano di scambio';
													|pl = 'Plan wymiany';
													|tr = 'Değiştirme planı'");
	AddCommandsFields(WithFields, StringExchangePlans);
	
	// Configuration.Common.FilterCriteria
	StringSelectionCriteria = StringGeneral.Rows.Add();
	StringSelectionCriteria.Name                  = "FilterCriteria";
	StringSelectionCriteria.Metadata           = Metadata.FilterCriteria;
	StringSelectionCriteria.PathToObject         = "FilterCriterion.*";
	StringSelectionCriteria.RightsDetails         = ViewRight();
	StringSelectionCriteria.Presentation        = NStr("vi = 'Tiêu chí lọc';
														|ru = 'Критерии отбора';
														|en = 'Filter criteria'; fa = 'معیارهای فیلتر';
														|it = 'Criteri di selezione';
														|pl = 'Kryteria wyboru';
														|tr = 'Filtre kriteri'");
	StringSelectionCriteria.ObjectPresentation = NStr("vi = 'Tiêu chí lọc';
														|ru = 'Критерий отбора';
														|en = 'Filter criterion'; fa = 'Filter criterion';
														|it = 'Criterio di selezione';
														|pl = 'Kryterium wyboru';
														|tr = 'Filtre koşulları'");
	AddCommandsFields(False, StringSelectionCriteria);
	
	// Configuration.Common.FilterCriteria.CommonForms
	StringGeneralForms = StringGeneral.Rows.Add();
	StringGeneralForms.Name                  = "CommonForms";
	StringGeneralForms.Metadata           = Metadata.CommonForms;
	StringGeneralForms.PathToObject         = "CommonForm.*";
	StringGeneralForms.RightsDetails         = ViewRight();
	StringGeneralForms.Presentation        = NStr("vi = 'Biểu mẫu chung';
													|ru = 'Общие формы';
													|en = 'Common forms'; fa = 'Common forms';
													|it = 'Form comuni';
													|pl = 'Wspólne formularze';
													|tr = 'Ortak formlar'");
	StringGeneralForms.ObjectPresentation = NStr("vi = 'Biểu mẫu chung';
												|ru = 'Общая форма';
												|en = 'Common form'; fa = 'Common form';
												|it = 'Modulo generale';
												|pl = 'Formularz wspólny';
												|tr = 'Genel form'");
	
	// Configuration.Common.FilterCriteria.CommonCommands
	StringCommonCommands = StringGeneral.Rows.Add();
	StringCommonCommands.Name                  = "CommonCommands";
	StringCommonCommands.Metadata           = Metadata.CommonCommands;
	StringCommonCommands.PathToObject         = "CommonCommand.*";
	StringCommonCommands.RightsDetails         = ViewRight();
	StringCommonCommands.Presentation        = NStr("vi = 'Lệnh chung';
													|ru = 'Общие команды';
													|en = 'Common commands'; fa = 'فرمان‌های مشترک';
													|it = 'Comandi comuni';
													|pl = 'Polecenia wspólne';
													|tr = 'Ortak komutlar'");
	StringCommonCommands.ObjectPresentation = NStr("vi = 'Lệnh chung';
													|ru = 'Общая команда';
													|en = 'Common command'; fa = 'Common command';
													|it = 'Comando generale';
													|pl = 'Polecenie wspólne';
													|tr = 'Genel komut'");
	
	// Configuration.Common.WebServices
	StringWebServices = StringGeneral.Rows.Add();
	StringWebServices.Name                  = "WebServices";
	StringWebServices.Metadata           = Metadata.WebServices;
	StringWebServices.PathToObject         = "WebService.*";
	StringWebServices.Presentation        = NStr("vi = 'Web-service';
												|ru = 'Web-сервисы';
												|en = 'Web services'; fa = 'Web services';
												|it = 'Servizi web';
												|pl = 'Web services';
												|tr = 'Web servisleri'");
	StringWebServices.ObjectPresentation = NStr("vi = 'Web-service';
												|ru = 'Web-сервис';
												|en = 'Web service'; fa = 'Web service';
												|it = 'Servizio web';
												|pl = 'Web service';
												|tr = 'Web servisi'");
	
	// Configuration.Common.WebServices.Operations
	OperationString = StringWebServices.Rows.Add();
	OperationString.Name                  = "Operations";
	OperationString.AttachmentName          = "Operations";
	OperationString.PathToObject         = "WebService.*.Operation.*";
	OperationString.RightsDetails         = RightUse();
	OperationString.NoGroup            = True;
	OperationString.ObjectPresentation = NStr("vi = 'Giao dịch';
												|ru = 'Операция';
												|en = 'Operation'; fa = 'عملیات';
												|it = 'Operazione';
												|pl = 'Operation';
												|tr = 'İşlem'");
	
	// Configuration.Common.HTTPServices
	StringHTTPServices = StringGeneral.Rows.Add();
	StringHTTPServices.Name                  = "HTTPServices";
	StringHTTPServices.Metadata           = Metadata.HTTPServices;
	StringHTTPServices.PathToObject         = "HTTPService.*";
	StringHTTPServices.Presentation        = NStr("vi = 'Dịch vụ HTTP';
													|ru = 'HTTP-сервисы';
													|en = 'HTTP services'; fa = 'HTTP services';
													|it = 'Servizi HTTP';
													|pl = 'HTTP services';
													|tr = 'HTTP servisleri'");
	StringHTTPServices.ObjectPresentation = NStr("vi = 'Dịch vụ HTTP';
												|ru = 'HTTP-сервис';
												|en = 'HTTP service'; fa = 'HTTP service';
												|it = 'Servizio HTTP';
												|pl = 'HTTP service';
												|tr = 'HTTP servisi'");
	
	// Configuration.Common.HTTPServices.URLTemplates
	StringTemplatesURL = StringHTTPServices.Rows.Add();
	StringTemplatesURL.Name                  = "URLTemplates";
	StringTemplatesURL.AttachmentName          = "URLTemplates";
	StringTemplatesURL.PathToObject         = "HTTPService.*.URLTemplate.*";
	StringTemplatesURL.NoGroup            = True;
	StringTemplatesURL.ObjectPresentation = NStr("vi = 'Mẫu URL';
												|ru = 'URL-шаблон';
												|en = 'URL template'; fa = 'URL template';
												|it = 'Modello URL';
												|pl = 'URL template';
												|tr = 'URL modeli'");
	
	// Configuration.Common.HTTPService.URLTemplates.Methods
	StringMethods = StringTemplatesURL.Rows.Add();
	StringMethods.Name                  = "Methods";
	StringMethods.AttachmentName          = "Methods";
	StringMethods.PathToObject         = "HTTPService.*.URLTemplate.*.Method.*";
	StringMethods.RightsDetails         = RightUse();
	StringMethods.NoGroup            = True;
	StringMethods.ObjectPresentation = NStr("vi = 'Phương pháp';
											|ru = 'Метод';
											|en = 'Method'; fa = 'روش';
											|it = 'Metodo';
											|pl = 'Method';
											|tr = 'Yöntem'");
	
	// Configuration.Constants
	StringConsts = ConfigurationString.Rows.Add();
	StringConsts.Name                  = "Constants";
	StringConsts.Metadata           = Metadata.Constants;
	StringConsts.PathToObject         = "Constant.*";
	StringConsts.RightsDetails         = RightsConsts();
	StringConsts.Presentation        = NStr("vi = 'Hằng';
											|ru = 'Константы';
											|en = 'Constants'; fa = 'ثابت‌ها';
											|it = 'Costanti';
											|pl = 'Constants';
											|tr = 'Sabitler'");
	StringConsts.ObjectPresentation = NStr("vi = 'Hằng';
											|ru = 'Константа';
											|en = 'Constant'; fa = 'ثابت';
											|it = 'Costante';
											|pl = 'Constant';
											|tr = 'Sabit'");
	
	// Configuration.Catalogs
	StringCatalogs = ConfigurationString.Rows.Add();
	StringCatalogs.Name                  = "Catalogs";
	StringCatalogs.Metadata           = Metadata.Catalogs;
	StringCatalogs.PathToObject         = "Catalog.*";
	StringCatalogs.RightsDetails         = RightsofDirectoryandPlans();
	StringCatalogs.Presentation        = NStr("vi = 'Danh mục';
												|ru = 'Справочники';
												|en = 'Catalogs'; fa = 'فهرست‌ها';
												|it = 'Directory';
												|pl = 'Catalogs';
												|tr = 'Kataloglar'");
	StringCatalogs.ObjectPresentation = NStr("vi = 'Danh mục';
											|ru = 'Справочник';
											|en = 'Catalog'; fa = 'فهرست';
											|it = 'Directory';
											|pl = 'Catalog';
											|tr = 'Katalog'");
	AddCommandsFields(WithFields, StringCatalogs);
	
	// Configuration.Documents (group)
	StringGroupDocuments = ConfigurationString.Rows.Add();
	StringGroupDocuments.Name           = "Documents";
	StringGroupDocuments.Presentation = NStr("vi = 'Chứng từ';
											|ru = 'Документы';
											|en = 'Documents'; fa = 'اسناد';
											|it = 'Documenti';
											|pl = 'Dokumenty';
											|tr = 'Belgeler'");
	
	// Configuration.Documents.Sequence
	StringSequence = StringGroupDocuments.Rows.Add();
	StringSequence.Name                  = "Sequences";
	StringSequence.Metadata           = Metadata.Sequences;
	StringSequence.PathToObject         = "Sequence.*";
	StringSequence.RightsDetails         = SequenceAndRecalculationRights();
	StringSequence.Presentation        = NStr("vi = 'Chuỗi nối tiếp';
												|ru = 'Последовательности';
												|en = 'Sequences'; fa = 'Sequences';
												|it = 'Sequenze';
												|pl = 'Sequences';
												|tr = 'Sıralar'");
	StringSequence.ObjectPresentation = NStr("vi = 'Chuỗi nối tiếp';
											|ru = 'Последовательность';
											|en = 'Sequence'; fa = 'توالی';
											|it = 'Sequenza';
											|pl = 'Sequence';
											|tr = 'Sıralama'");
	
	// Configuration.Documents (elements)
	StringDocuments = StringGroupDocuments.Rows.Add();
	StringDocuments.Name                  = "Documents";
	StringDocuments.Metadata           = Metadata.Documents;
	StringDocuments.PathToObject         = "Document.*";
	StringDocuments.RightsDetails         = DocumentPermissions();
	StringDocuments.NoGroup            = True;
	StringDocuments.ObjectPresentation = NStr("vi = 'Chứng từ';
												|ru = 'Документ';
												|en = 'Document'; fa = 'سند';
												|it = 'Documento';
												|pl = 'Dokument';
												|tr = 'Belge'");
	AddCommandsFields(WithFields, StringDocuments);
	
	// Configuration.DocumentJournals
	StringDocumentLogs = ConfigurationString.Rows.Add();
	StringDocumentLogs.Name                  = "DocumentJournals";
	StringDocumentLogs.Metadata           = Metadata.DocumentJournals;
	StringDocumentLogs.PathToObject         = "DocumentJournal.*";
	StringDocumentLogs.RightsDetails         = PermissionsJournalDocuments();
	StringDocumentLogs.Presentation        = NStr("vi = 'Nhật ký chứng từ';
													|ru = 'Журналы документов';
													|en = 'Document journals'; fa = 'Document journals';
													|it = 'Registri dei documenti';
													|pl = 'Dzienniki dokumentów';
													|tr = 'Belge günlükleri'");
	StringDocumentLogs.ObjectPresentation = NStr("vi = 'Nhật ký chứng từ';
												|ru = 'Журнал документов';
												|en = 'Document journal'; fa = 'دفتر اسناد';
												|it = 'File log';
												|pl = 'Dziennik dokumentów';
												|tr = 'Belge günlüğü'");
	AddCommandsFields(WithFields, StringDocumentLogs, "StandardAttributes", True);
	
	// Configuration.Enumerations
	EnumString = ConfigurationString.Rows.Add();
	EnumString.Name                  = "Enums";
	EnumString.Metadata           = Metadata.Enums;
	EnumString.PathToObject         = "Enum.*";
	EnumString.Presentation        = NStr("vi = 'Liệt kê';
											|ru = 'Перечисления';
											|en = 'Enumerations'; fa = 'Enumerations';
											|it = 'Enumerazioni';
											|pl = 'Enumerations';
											|tr = 'Transferler'");
	EnumString.ObjectPresentation = NStr("vi = 'Liệt kê';
										|ru = 'Перечисление';
										|en = 'Enumeration'; fa = 'Enumeration';
										|it = 'Enumerazione';
										|pl = 'Enumeration';
										|tr = 'Transfer'");
	EnumString.WithoutDecryption       = True;
	AddCommandsFields(False, EnumString);
	
	// Configuration.Reports
	ReportsRow = ConfigurationString.Rows.Add();
	ReportsRow.Name                  = "Reports";
	ReportsRow.Metadata           = Metadata.Reports;
	ReportsRow.PathToObject         = "Report.*";
	ReportsRow.RightsDetails         = RightsReportProcessingFunctions();
	ReportsRow.Presentation        = NStr("vi = 'Báo cáo';
											|ru = 'Отчеты';
											|en = 'Reports'; fa = 'گزارش‌ها';
											|it = 'Report';
											|pl = 'Reports';
											|tr = 'Raporlar'");
	ReportsRow.ObjectPresentation = NStr("vi = 'Báo cáo';
										|ru = 'Отчет';
										|en = 'Report'; fa = 'گزارش';
										|it = 'Report';
										|pl = 'Report';
										|tr = 'Rapor'");
	AddCommandsFields(WithFields, ReportsRow, "Attributes, TabularSections");
	
	// Configuration.DataProcessors
	ProcessingString = ConfigurationString.Rows.Add();
	ProcessingString.Name                  = "DataProcessors";
	ProcessingString.Metadata           = Metadata.DataProcessors;
	ProcessingString.PathToObject         = "DataProcessor.*";
	ProcessingString.RightsDetails         = RightsReportProcessingFunctions();
	ProcessingString.Presentation        = NStr("vi = 'Bộ xử lý';
												|ru = 'Обработки';
												|en = 'Data processors'; fa = 'Data processors';
												|it = 'Elaborazioni';
												|pl = 'Data processors';
												|tr = 'Veri işlemcileri'");
	ProcessingString.ObjectPresentation = NStr("vi = 'Bộ xử lý';
												|ru = 'Обработка';
												|en = 'Data processor'; fa = 'پردازشگر داده';
												|it = 'Elaborazione';
												|pl = 'Data processor';
												|tr = 'Veri işlemcisi'");
	AddCommandsFields(WithFields, ProcessingString, "Attributes, TabularSections");
	
	// Configuration.ChartsOfCharacteristicTypes
	StringPlansViewsCharacteristics = ConfigurationString.Rows.Add();
	StringPlansViewsCharacteristics.Name                  = "ChartsOfCharacteristicTypes";
	StringPlansViewsCharacteristics.Metadata           = Metadata.ChartsOfCharacteristicTypes;
	StringPlansViewsCharacteristics.PathToObject         = "ChartOfCharacteristicTypes.*";
	StringPlansViewsCharacteristics.RightsDetails         = RightsofDirectoryandPlans();
	StringPlansViewsCharacteristics.Presentation        = NStr("vi = 'Hệ thống dạng đặc tính';
																|ru = 'Планы видов характеристик';
																|en = 'Charts of characteristic types'; fa = 'Charts of characteristic types';
																|it = 'Piani dei tipi di caratteristiche';
																|pl = 'Plany rodzajów charakterystyk';
																|tr = 'Özellik türü listeleri'");
	StringPlansViewsCharacteristics.ObjectPresentation = NStr("vi = 'Hệ thống dạng đặc tính';
																|ru = 'План видов характеристик';
																|en = 'Chart of characteristic types'; fa = 'Chart of characteristic types';
																|it = 'Piano dei tipi di caratteristiche';
																|pl = 'Plan rodzajów charakterystyk';
																|tr = 'Özellik türü listesi'");
	AddCommandsFields(WithFields, StringPlansViewsCharacteristics);
	
	// Configuration.ChartsOfAccounts
	LineOfAccountPlans = ConfigurationString.Rows.Add();
	LineOfAccountPlans.Name                  = "ChartsOfAccounts";
	LineOfAccountPlans.Metadata           = Metadata.ChartsOfAccounts;
	LineOfAccountPlans.PathToObject         = "ChartOfAccounts.*";
	LineOfAccountPlans.RightsDetails         = RightsofDirectoryandPlans();
	LineOfAccountPlans.Presentation        = NStr("vi = 'Hệ thống tài khoản';
													|ru = 'Планы счетов';
													|en = 'Charts of accounts'; fa = 'سرفصل‌های حساب';
													|it = 'Piani dei conti';
													|pl = 'Plany rachunków';
													|tr = 'Hesap planları'");
	LineOfAccountPlans.ObjectPresentation = NStr("vi = 'Hệ thống tài khoản';
												|ru = 'План счетов';
												|en = 'Chart of accounts'; fa = 'سرفصل حساب‌ها';
												|it = 'Piano dei conti';
												|pl = 'Plan rachunków';
												|tr = 'Hesap planı'");
	AddCommandsFields(WithFields, LineOfAccountPlans, "Attributes, AccountingFlags,
	|ExtDimensionAccountingFlags, TabularSections, StandardAttributes, StandardTabularSections");
	
	// Configuration.ChartsOfCalculationTypes
	StringPlansViewsCalculation = ConfigurationString.Rows.Add();
	StringPlansViewsCalculation.Name                  = "ChartsOfCalculationTypes";
	StringPlansViewsCalculation.Metadata           = Metadata.ChartsOfCalculationTypes;
	StringPlansViewsCalculation.PathToObject         = "ChartOfCalculationTypes.*";
	StringPlansViewsCalculation.RightsDetails         = RightsofDirectoryandPlans();
	StringPlansViewsCalculation.Presentation        = NStr("vi = 'Hệ thống dạng tính toán';
															|ru = 'Планы видов расчета';
															|en = 'Charts of calculation types'; fa = 'Charts of calculation types';
															|it = 'Piani dei tipi di calcolo';
															|pl = 'Plany rodzajów obliczeń';
															|tr = 'Hesaplama türü planları'");
	StringPlansViewsCalculation.ObjectPresentation = NStr("vi = 'Hệ thống dạng tính toán';
															|ru = 'План видов расчета';
															|en = 'Chart of calculation types'; fa = 'Chart of calculation types';
															|it = 'Piano dei tipi di calcolo';
															|pl = 'Plan rodzajów rozliczenia';
															|tr = 'Hesaplama plan türü'");
	AddCommandsFields(WithFields, StringPlansViewsCalculation, "Attributes, TabularSections,
	|StandardAttributes, StandardTabularSections");
	
	// Configuration.InformationRegisters
	StringRegistersDetails = ConfigurationString.Rows.Add();
	StringRegistersDetails.Name                  = "InformationRegisters";
	StringRegistersDetails.Metadata           = Metadata.InformationRegisters;
	StringRegistersDetails.PathToObject         = "InformationRegister.*";
	StringRegistersDetails.RightsDetails         = RightsRegisterInformation();
	StringRegistersDetails.Presentation        = NStr("vi = 'Biểu ghi thông tin';
														|ru = 'Регистры сведений';
														|en = 'Information registers'; fa = 'ثبت‌های اطلاعاتی';
														|it = 'Registri delle informazioni';
														|pl = 'Rejestry informacji';
														|tr = 'Bilgi kayıtları'");
	StringRegistersDetails.ObjectPresentation = NStr("vi = 'Biểu ghi thông tin';
													|ru = 'Регистр сведений';
													|en = 'Information register'; fa = 'Information register';
													|it = 'Registro dati';
													|pl = 'Rejestr informacji';
													|tr = 'Bilgi kaydı'");
	AddCommandsFields(WithFields, StringRegistersDetails, "Dimensions, Resources,
	|Attributes, StandardAttributes");
	
	// Configuration.AccumulationRegisters
	StringRegistersAccumulation = ConfigurationString.Rows.Add();
	StringRegistersAccumulation.Name                  = "AccumulationRegisters";
	StringRegistersAccumulation.Metadata           = Metadata.AccumulationRegisters;
	StringRegistersAccumulation.PathToObject         = "AccumulationRegister.*";
	StringRegistersAccumulation.RightsDetails         = RightsRegisterAccumulationAndAccounting();
	StringRegistersAccumulation.Presentation        = NStr("vi = 'Biểu ghi tích lũy';
															|ru = 'Регистры накопления';
															|en = 'Accumulation registers'; fa = 'ثبت‌های انباشتی';
															|it = 'Registri di accumulo';
															|pl = 'Rejestry kumulacji';
															|tr = 'Birikim kayıtları'");
	StringRegistersAccumulation.ObjectPresentation = NStr("vi = 'Biểu ghi tích lũy';
															|ru = 'Регистр накопления';
															|en = 'Accumulation register'; fa = 'Accumulation register';
															|it = 'Registro di accumulo';
															|pl = 'Rejestr akumulacji';
															|tr = 'Birikim kaydı'");
	AddCommandsFields(WithFields, StringRegistersAccumulation, "Dimensions, Resources,
	|Attributes, StandardAttributes");
	
	// Configuration.AccountingRegisters
	StringRegistersAccounting = ConfigurationString.Rows.Add();
	StringRegistersAccounting.Name                  = "AccountingRegisters";
	StringRegistersAccounting.Metadata           = Metadata.AccountingRegisters;
	StringRegistersAccounting.PathToObject         = "AccountingRegister.*";
	StringRegistersAccounting.RightsDetails         = RightsRegisterAccumulationAndAccounting();
	StringRegistersAccounting.Presentation        = NStr("vi = 'Biểu ghi kế toán';
														|ru = 'Регистры бухгалтерии';
														|en = 'Accounting registers'; fa = 'Accounting registers';
														|it = 'Registri contabilità';
														|pl = 'Rejestry księgowości';
														|tr = 'Muhasebe kayıtları'");
	StringRegistersAccounting.ObjectPresentation = NStr("vi = 'Biểu ghi kế toán';
														|ru = 'Регистр бухгалтерии';
														|en = 'Accounting register'; fa = 'Accounting register';
														|it = 'Registro contabilità';
														|pl = 'Rejestr księgowości';
														|tr = 'Muhasebe kaydı'");
	AddCommandsFields(WithFields, StringRegistersAccounting, "Dimensions, Resources,
	|Attributes, StandardAttributes");
	
	// Configuration.CalculationRegisters
	StringRegistersCalculation = ConfigurationString.Rows.Add();
	StringRegistersCalculation.Name                  = "CalculationRegisters";
	StringRegistersCalculation.Metadata           = Metadata.CalculationRegisters;
	StringRegistersCalculation.PathToObject         = "CalculationRegister.*";
	StringRegistersCalculation.RightsDetails         = RightsRegisterCalculation();
	StringRegistersCalculation.Presentation        = NStr("vi = 'Biểu ghi tính toán';
															|ru = 'Регистры расчета';
															|en = 'Calculation registers'; fa = 'Calculation registers';
															|it = 'Registri di calcolo';
															|pl = 'Rejestry rozliczenia';
															|tr = 'Mutabakat işlemleri kayıtları'");
	StringRegistersCalculation.ObjectPresentation = NStr("vi = 'Biểu ghi tính toán';
														|ru = 'Регистр расчета';
														|en = 'Calculation register'; fa = 'Calculation register';
														|it = 'Registro di calcolo';
														|pl = 'Rejestr rozliczenia';
														|tr = 'Hesaplama kaydı'");
	AddCommandsFields(WithFields, StringRegistersCalculation, "Dimensions, Resources,
	|Attributes, StandardAttributes, Recalculations");
	
	// Configuration.BusinessProcesses
	StringBusinessProcesses = ConfigurationString.Rows.Add();
	StringBusinessProcesses.Name                  = "BusinessProcesses";
	StringBusinessProcesses.Metadata           = Metadata.BusinessProcesses;
	StringBusinessProcesses.PathToObject         = "BusinessProcess.*";
	StringBusinessProcesses.RightsDetails         = RightsBusinessProcess();
	StringBusinessProcesses.Presentation        = NStr("vi = 'Quy trình nghiệp vụ';
														|ru = 'Бизнес процессы';
														|en = 'Business processes'; fa = 'فرایندهای تجاری';
														|it = 'Processi aziendali';
														|pl = 'Procesy biznesowe';
														|tr = 'İş süreçleri'");
	StringBusinessProcesses.ObjectPresentation = NStr("vi = 'Quy trình nghiệp vụ';
														|ru = 'Бизнес процесс';
														|en = 'Business process'; fa = 'فرایند کسب‌وکار';
														|it = 'Processo aziendale';
														|pl = 'Proces biznesowy';
														|tr = 'İş süreci'");
	AddCommandsFields(WithFields, StringBusinessProcesses);
	
	// Configuration.Tasks
	TaskLine = ConfigurationString.Rows.Add();
	TaskLine.Name                  = "Tasks";
	TaskLine.Metadata           = Metadata.Tasks;
	TaskLine.PathToObject         = "Task.*";
	TaskLine.RightsDetails         = RightsTasks();
	TaskLine.Presentation        = NStr("vi = 'Nhiệm vụ';
										|ru = 'Задачи';
										|en = 'Tasks'; fa = 'وظایف';
										|it = 'Compiti';
										|pl = 'Tasks';
										|tr = 'Görevler'");
	TaskLine.ObjectPresentation = NStr("vi = 'Nhiệm vụ';
										|ru = 'Задача';
										|en = 'Task'; fa = 'وظیفه';
										|it = 'Compito';
										|pl = 'Task';
										|tr = 'Görev'");
	AddCommandsFields(WithFields, TaskLine, "AddressingAttributes,
	|Attributes, TabularSections, StandardAttributes");
	
	// Configuration.ExternalDataSources
	StringExternalDataSources = ConfigurationString.Rows.Add();
	StringExternalDataSources.Name                  = "ExternalDataSources";
	StringExternalDataSources.Metadata           = Metadata.ExternalDataSources;
	StringExternalDataSources.PathToObject         = "ExternalDataSource.*";
	StringExternalDataSources.RightsDetails         = RightsExternalDataSource();
	StringExternalDataSources.Presentation        = NStr("vi = 'Nguồn dữ liệu ngoài';
														|ru = 'Внешние источники данных';
														|en = 'External data sources'; fa = 'External data sources';
														|it = 'Fonti dati esterne';
														|pl = 'Zewnętrzne źródła danych';
														|tr = 'Harici veri kaynakları'");
	StringExternalDataSources.ObjectPresentation = NStr("vi = 'Nguồn dữ liệu ngoài';
														|ru = 'Внешний источник данных';
														|en = 'External data source'; fa = 'منبع داده خارجی';
														|it = 'Origine dati esterna';
														|pl = 'Zewnętrzne źródło danych';
														|tr = 'Harici veri kaynağı'");
	
	// Configuration.ExternalDataSources.Tables
	TableRow = StringExternalDataSources.Rows.Add();
	TableRow.Name                  = "Tables";
	TableRow.AttachmentName          = "Tables";
	TableRow.PathToObject         = "ExternalDataSource.*.Table.*";
	TableRow.RightsDetails         = RightsTableExternalDataSource();
	TableRow.Presentation        = NStr("vi = 'Bảng';
										|ru = 'Таблицы';
										|en = 'Tables'; fa = 'جدول‌ها';
										|it = 'Tabelle';
										|pl = 'Tables';
										|tr = 'Tablolar'");
	TableRow.ObjectPresentation = NStr("vi = 'Bảng';
										|ru = 'Таблица';
										|en = 'Table'; fa = 'جدول';
										|it = 'Tabella';
										|pl = 'Table';
										|tr = 'Tablo'");
	AddCommandsFields(WithFields, TableRow, "Fields");
	
	// Configuration.ExternalDataSources.Cubes
	StringCube = StringExternalDataSources.Rows.Add();
	StringCube.Name                  = "Cubes";
	StringCube.AttachmentName          = "Cubes";
	StringCube.PathToObject         = "ExternalDataSource.*.Cube.*";
	StringCube.RightsDetails         = PermissionsCubeAndDimensionTables();
	StringCube.Presentation        = NStr("vi = 'Khối';
											|ru = 'Кубы';
											|en = 'Cubes'; fa = 'Cubes';
											|it = 'Cubi';
											|pl = 'Cubes';
											|tr = 'Küpler'");
	StringCube.ObjectPresentation = NStr("vi = 'Khối';
										|ru = 'Куб';
										|en = 'Cube'; fa = 'Cube';
										|it = 'Cubo';
										|pl = 'Cube';
										|tr = 'Küp'");
	
	// Configuration.ExternalDataSources.Cubes.DimensionTables
	RowTableDimensions = StringCube.Rows.Add();
	RowTableDimensions.Name                  = "DimensionTables";
	RowTableDimensions.AttachmentName          = "DimensionTables";
	RowTableDimensions.PathToObject         = "ExternalDataSource.*.Cube.*.DimensionTable.*";
	RowTableDimensions.RightsDetails         = PermissionsCubeAndDimensionTables();
	RowTableDimensions.Presentation        = NStr("vi = 'Bảng chiều đo';
													|ru = 'Таблицы измерений';
													|en = 'Dimension tables'; fa = 'Dimension tables';
													|it = 'Tabelle misurazioni';
													|pl = 'Tabele wymiarów';
													|tr = 'Boyut tabloları'");
	RowTableDimensions.ObjectPresentation = NStr("vi = 'Bảng chiều đo';
												|ru = 'Таблица измерений';
												|en = 'Dimension table'; fa = 'Dimension table';
												|it = 'Tabella misurazioni';
												|pl = 'Tabela wymiarów';
												|tr = 'Boyut tablosu'");
	AddCommandsFields(WithFields, RowTableDimensions, "Fields");
	AddCommandsFields(WithFields, StringCube, "Dimensions, Resources", True);
	
	// Configuration.ExternalDataSources.Functions
	FunctionString = StringExternalDataSources.Rows.Add();
	FunctionString.Name                  = "Functions";
	FunctionString.AttachmentName          = "Functions";
	FunctionString.PathToObject         = "ExternalDataSource.*.Function.*";
	FunctionString.RightsDetails         = RightsReportProcessingFunctions();
	FunctionString.Presentation        = NStr("vi = 'Hàm';
												|ru = 'Функции';
												|en = 'Functions'; fa = 'توابع';
												|it = 'Funzioni';
												|pl = 'Functions';
												|tr = 'İşlevler'");
	FunctionString.ObjectPresentation = NStr("vi = 'Hàm';
											|ru = 'Функция';
											|en = 'Function'; fa = 'تابع';
											|it = 'Funzione';
											|pl = 'Function';
											|tr = 'Fonksiyon'");
	
	Return Tree;
	
EndFunction

Procedure AddCommandsFields(WithFields, TreeRow, Fields = "Attributes, TabularSections, StandardAttributes", NoEdit = False)
	
	FieldsStructure = New Structure(Fields);
	
	If WithFields And FieldsStructure.Property("Dimensions") Then
		// Dimensions
		MeasurementString_ = TreeRow.Rows.Add();
		MeasurementString_.Name                  = "Dimensions";
		MeasurementString_.AttachmentName          = "Dimensions";
		MeasurementString_.PathToObject         = TreeRow.PathToObject + ".Dimension.*";
		MeasurementString_.RightsDetails         = RightsAttributes(NoEdit);
		MeasurementString_.Presentation        = NStr("vi = 'Chiều đo';
														|ru = 'Измерения';
														|en = 'Dimensions'; fa = 'ابعاد';
														|it = 'Dimensioni';
														|pl = 'Dimensions';
														|tr = 'Boyutlar'");
		MeasurementString_.ObjectPresentation = NStr("vi = 'Chiều đo';
													|ru = 'Измерение';
													|en = 'Dimension'; fa = 'بُعد';
													|it = 'Dimensione';
													|pl = 'Dimension';
													|tr = 'Boyut'");
	EndIf;
	
	If WithFields And FieldsStructure.Property("Resources") Then
		// Resources
		LineResources = TreeRow.Rows.Add();
		LineResources.Name                  = "Resources";
		LineResources.AttachmentName          = "Resources";
		LineResources.PathToObject         = TreeRow.PathToObject + ".Resource.*";
		LineResources.RightsDetails         = RightsAttributes(NoEdit);
		LineResources.Presentation        = NStr("vi = 'Số đo';
												|ru = 'Ресурсы';
												|en = 'Resources'; fa = 'منابع';
												|it = 'Risorse';
												|pl = 'Resources';
												|tr = 'Kaynaklar'");
		LineResources.ObjectPresentation = NStr("vi = 'Số đo';
												|ru = 'Ресурс';
												|en = 'Resource'; fa = 'منبع';
												|it = 'Risorsa';
												|pl = 'Resource';
												|tr = 'Kaynak'");
	EndIf;
	
	If WithFields And FieldsStructure.Property("AddressingAttributes") Then
		// AddressingAttributes
		StringRequisitesAddresses = TreeRow.Rows.Add();
		StringRequisitesAddresses.Name                  = "AddressingAttributes";
		StringRequisitesAddresses.AttachmentName          = "AddressingAttributes";
		StringRequisitesAddresses.PathToObject         = TreeRow.PathToObject + ".AddressingAttribute.*";
		StringRequisitesAddresses.RightsDetails         = RightsAttributes(NoEdit);
		StringRequisitesAddresses.Presentation        = NStr("vi = 'Mục tin đánh địa chỉ';
															|ru = 'Реквизиты адресации';
															|en = 'Addressing attributes'; fa = 'Addressing attributes';
															|it = 'Requisiti di indirizzo';
															|pl = 'Atrybuty adresacji';
															|tr = 'Adresleme öznitelikleri'");
		StringRequisitesAddresses.ObjectPresentation = NStr("vi = 'Mục tin đánh địa chỉ';
															|ru = 'Реквизит адресации';
															|en = 'Addressing attribute'; fa = 'Addressing attribute';
															|it = 'Requisito di indirizzo';
															|pl = 'Atrybut adresacji';
															|tr = 'Adresleme özniteliği'");
	EndIf;
	
	If WithFields And FieldsStructure.Property("Attributes") Then
		// Attributes
		AttributesString = TreeRow.Rows.Add();
		AttributesString.Name                  = "Attributes";
		AttributesString.AttachmentName          = "Attributes";
		AttributesString.PathToObject         = TreeRow.PathToObject + ".Attribute.*";
		AttributesString.RightsDetails         = RightsAttributes(NoEdit);
		AttributesString.Presentation        = NStr("vi = 'Mục tin';
													|ru = 'Реквизиты';
													|en = 'Attributes'; fa = 'ویژگی‌ها';
													|it = 'Requisiti';
													|pl = 'Attributes';
													|tr = 'Öznitelikler'");
		AttributesString.ObjectPresentation = NStr("vi = 'Mục tin';
													|ru = 'Реквизит';
													|en = 'Attribute'; fa = 'ویژگی';
													|it = 'Requisito';
													|pl = 'Attribute';
													|tr = 'Öznitelik'");
	EndIf;
	
	If WithFields And FieldsStructure.Property("Fields") Then
		// Fields
		FieldString = TreeRow.Rows.Add();
		FieldString.Name                  = "Fields";
		FieldString.AttachmentName          = "Fields";
		FieldString.PathToObject         = TreeRow.PathToObject + ".Field.*";
		FieldString.RightsDetails         = RightsAttributes(NoEdit);
		FieldString.Presentation        = NStr("vi = 'Trường';
												|ru = 'Поля';
												|en = 'Fields'; fa = 'فیلدها';
												|it = 'Campi';
												|pl = 'Fields';
												|tr = 'Alanlar'");
		FieldString.ObjectPresentation = NStr("vi = 'Trường';
												|ru = 'Поле';
												|en = 'Field'; fa = 'فیلد';
												|it = 'Campo';
												|pl = 'Field';
												|tr = 'Alan'");
	EndIf;
	
	If WithFields And FieldsStructure.Property("AccountingFlags") Then
		// AccountingFlags
		StringAccountingAttributes = TreeRow.Rows.Add();
		StringAccountingAttributes.Name                  = "AccountingFlags";
		StringAccountingAttributes.AttachmentName          = "AccountingFlags";
		StringAccountingAttributes.PathToObject         = TreeRow.PathToObject + ".AccountingFlag.*";
		StringAccountingAttributes.RightsDetails         = RightsAttributes(NoEdit);
		StringAccountingAttributes.Presentation        = NStr("vi = 'Dấu hiệu kế toán';
																|ru = 'Признаки учета';
																|en = 'Accounting flags'; fa = 'Accounting flags';
																|it = 'Segni contabilità';
																|pl = 'Oznaki ewidencji';
																|tr = 'Muhasebe işaretleri'");
		StringAccountingAttributes.ObjectPresentation = NStr("vi = 'Dấu hiệu kế toán';
															|ru = 'Признак учета';
															|en = 'Accounting flag'; fa = 'Accounting flag';
															|it = 'Segno contabilità';
															|pl = 'Oznaka ewidencji';
															|tr = 'Muhasebe işareti'");
	EndIf;
	
	If WithFields And FieldsStructure.Property("ExtDimensionAccountingFlags") Then
		// ExtDimensionAccountingFlags
		LineAccountingAttributesSubconto = TreeRow.Rows.Add();
		LineAccountingAttributesSubconto.Name                  = "ExtDimensionAccountingFlags";
		LineAccountingAttributesSubconto.AttachmentName          = "ExtDimensionAccountingFlags";
		LineAccountingAttributesSubconto.PathToObject         = TreeRow.PathToObject + ".ExtDimensionAccountingFlag.*";
		LineAccountingAttributesSubconto.RightsDetails         = RightsAttributes(NoEdit);
		LineAccountingAttributesSubconto.Presentation        = NStr("vi = 'Dấu hiệu kế toán khoản mục';
																	|ru = 'Признаки учета субконто';
																	|en = 'Extra dimension accounting flags'; fa = 'Extra dimension accounting flags';
																	|it = 'Segni contabilità subconto';
																	|pl = 'Oznaki ewidencji subkonto';
																	|tr = 'Ekstra boyut muhasebe işaretleri'");
		LineAccountingAttributesSubconto.ObjectPresentation = NStr("vi = 'Dấu hiệu kế toán khoản mục';
																	|ru = 'Признак учета субконто';
																	|en = 'Extra dimension accounting flag'; fa = 'Extra dimension accounting flag';
																	|it = 'Segno contabilità subconto';
																	|pl = 'Oznaka ewidencji subkonto';
																	|tr = 'Ekstra boyut işareti'");
	EndIf;
	
	If WithFields And FieldsStructure.Property("TabularSections") Then
		// TabularSections
		RowTableParts = TreeRow.Rows.Add();
		RowTableParts.Name                  = "TabularSections";
		RowTableParts.AttachmentName          = "TabularSections";
		RowTableParts.PathToObject         = TreeRow.PathToObject + ".TabularSection.*";
		RowTableParts.RightsDetails         = RightsAttributes(NoEdit);
		RowTableParts.Presentation        = NStr("vi = 'Phần bảng';
												|ru = 'Табличные части';
												|en = 'Tables'; fa = 'جدول‌ها';
												|it = 'Tabelle';
												|pl = 'Tabelaryczne części';
												|tr = 'Tablo bölümler'");
		RowTableParts.ObjectPresentation = NStr("vi = 'Phần bảng';
												|ru = 'Табличная часть';
												|en = 'Table'; fa = 'جدول';
												|it = 'Parte di tabella';
												|pl = 'Sekcja tabelaryczna';
												|tr = 'Tablo bölümü'");
		
		// TabularSections.Attributes
		RowTablePartsAttributes = RowTableParts.Rows.Add();
		RowTablePartsAttributes.Name                  = "Attributes";
		RowTablePartsAttributes.AttachmentName          = "Attributes";
		RowTablePartsAttributes.PathToObject         = RowTableParts.PathToObject + ".Attribute.*";
		RowTablePartsAttributes.RightsDetails         = RightsAttributes(NoEdit);
		RowTablePartsAttributes.Presentation        = NStr("vi = 'Mục tin';
															|ru = 'Реквизиты';
															|en = 'Attributes'; fa = 'ویژگی‌ها';
															|it = 'Requisiti';
															|pl = 'Attributes';
															|tr = 'Öznitelikler'");
		RowTablePartsAttributes.ObjectPresentation = NStr("vi = 'Mục tin';
															|ru = 'Реквизит';
															|en = 'Attribute'; fa = 'ویژگی';
															|it = 'Requisito';
															|pl = 'Attribute';
															|tr = 'Öznitelik'");
		RowTablePartsAttributes.NoGroup            = True;
	EndIf;
	
	If WithFields And FieldsStructure.Property("StandardAttributes") Then
		// StandardAttributes
		StringStandardAttributes = TreeRow.Rows.Add();
		StringStandardAttributes.Name                  = "StandardAttributes";
		StringStandardAttributes.AttachmentName          = "StandardAttributes";
		StringStandardAttributes.PathToObject         = TreeRow.PathToObject + ".StandardAttribute.*";
		StringStandardAttributes.RightsDetails         = RightsAttributes(NoEdit);
		StringStandardAttributes.Presentation        = NStr("vi = 'Mục tin chuẩn';
															|ru = 'Стандартные реквизиты';
															|en = 'Standard attributes'; fa = 'Standard attributes';
															|it = 'Requisiti standard';
															|pl = 'Standardowe atrybuty';
															|tr = 'Standart öznitelikler'");
		StringStandardAttributes.ObjectPresentation = NStr("vi = 'Mục tin chuẩn';
															|ru = 'Стандартный реквизит';
															|en = 'Standard attribute'; fa = 'Standard attribute';
															|it = 'Requisito standard';
															|pl = 'Atrybut standardowy';
															|tr = 'Standart öznitelik'");
	EndIf;
	
	If WithFields And FieldsStructure.Property("StandardTabularSections") Then
		// StandardTabularSections
		RowStandardTableParts = TreeRow.Rows.Add();
		RowStandardTableParts.Name                  = "StandardTabularSections";
		RowStandardTableParts.AttachmentName          = "StandardTabularSections";
		RowStandardTableParts.PathToObject         = TreeRow.PathToObject + ".StandardTabularSection.*";
		RowStandardTableParts.RightsDetails         = RightsAttributes(NoEdit);
		RowStandardTableParts.Presentation        = NStr("vi = 'Phần bảng chuẩn';
														|ru = 'Стандартные табличные части';
														|en = 'Standard tables'; fa = 'Standard tables';
														|it = 'Parti tabellari standard';
														|pl = 'Standardowe sekcje tabelaryczne';
														|tr = 'Standart tablo bölümleri'");
		RowStandardTableParts.ObjectPresentation = NStr("vi = 'Phần bảng chuẩn';
														|ru = 'Стандартная табличная часть';
														|en = 'Standard table'; fa = 'Standard table';
														|it = 'Parti tabellari standard';
														|pl = 'Standardowa sekcja tabelaryczna';
														|tr = 'Standart tablo bölümü'");
		
		// StandardTabularSections.StandardAttributes
		RowStandardTablePartsStandardAttributes = RowStandardTableParts.Rows.Add();
		RowStandardTablePartsStandardAttributes.Name                  = "StandardAttributes";
		RowStandardTablePartsStandardAttributes.AttachmentName          = "StandardAttributes";
		RowStandardTablePartsStandardAttributes.PathToObject         = RowStandardTableParts.PathToObject + ".StandardAttribute.*";
		RowStandardTablePartsStandardAttributes.RightsDetails         = RightsAttributes(NoEdit);
		RowStandardTablePartsStandardAttributes.Presentation        = NStr("vi = 'Mục tin chuẩn';
																			|ru = 'Стандартные реквизиты';
																			|en = 'Standard attributes'; fa = 'Standard attributes';
																			|it = 'Requisiti standard';
																			|pl = 'Standardowe atrybuty';
																			|tr = 'Standart öznitelikler'");
		RowStandardTablePartsStandardAttributes.ObjectPresentation = NStr("vi = 'Mục tin chuẩn';
																			|ru = 'Стандартный реквизит';
																			|en = 'Standard attribute'; fa = 'Standard attribute';
																			|it = 'Requisito standard';
																			|pl = 'Atrybut standardowy';
																			|tr = 'Standart öznitelik'");
		RowStandardTablePartsStandardAttributes.NoGroup            = True;
	EndIf;
	
	If FieldsStructure.Property("Recalculations") Then
		// Recalculations
		StringRecalculations = TreeRow.Rows.Add();
		StringRecalculations.Name                  = "Recalculations";
		StringRecalculations.AttachmentName          = "Recalculations";
		StringRecalculations.PathToObject         = TreeRow.PathToObject + ".Recalculation.*";
		StringRecalculations.RightsDetails         = SequenceAndRecalculationRights();
		StringRecalculations.Presentation        = NStr("vi = 'Tính lại';
														|ru = 'Перерасчеты';
														|en = 'Recalculations'; fa = 'Recalculations';
														|it = 'Ricalcoli';
														|pl = 'Recalculations';
														|tr = 'Yeniden hesaplamalar'");
		StringRecalculations.ObjectPresentation = NStr("vi = 'Tính lại';
														|ru = 'Перерасчет';
														|en = 'Recalculation'; fa = 'Recalculation';
														|it = 'Ricalcolo';
														|pl = 'Recalculation';
														|tr = 'Yeniden hesaplama'");
	EndIf;
	
	// Commands
	CommandString = TreeRow.Rows.Add();
	CommandString.Name                  = "Commands";
	CommandString.AttachmentName          = "Commands";
	CommandString.PathToObject         = TreeRow.PathToObject + ".Command.*";
	CommandString.RightsDetails         = ViewRight();
	CommandString.Presentation        = NStr("vi = 'Lệnh';
											|ru = 'Команды';
											|en = 'Commands'; fa = 'فرمان‌ها';
											|it = 'Comandi';
											|pl = 'Commands';
											|tr = 'Komutlar'");
	CommandString.ObjectPresentation = NStr("vi = 'Lệnh';
											|ru = 'Команда';
											|en = 'Command'; fa = 'فرمان';
											|it = 'Comando';
											|pl = 'Command';
											|tr = 'Komut'");
	
EndProcedure

// Returns:
//  Structure:
//   * RightsList - ValueList
//   * AccessLevels - ValueTable:
//      ** Right              - String
//      ** ThisPermissionSet       - Boolean
//      ** Level            - Number
//      ** RightWithRestriction - String
//
Function RightsDetails()
	
	AccessLevels = New ValueTable;
	AccessLevels.Columns.Add("Right",              StringType(1000));
	AccessLevels.Columns.Add("ThisPermissionSet",       New TypeDescription("Boolean"));
	AccessLevels.Columns.Add("Level",            NumberType(2));
	AccessLevels.Columns.Add("RightWithRestriction", StringType(1000));
	
	RightsDetails = New Structure;
	RightsDetails.Insert("RightsList",    New ValueList);
	RightsDetails.Insert("AccessLevels", AccessLevels);
	
	Return RightsDetails;
	
EndFunction

Function ConfigRights()
	
	RightsDetails = RightsDetails();
	RightsList = RightsDetails.RightsList;
	
	RightsList.Add("Administration",
		NStr("vi = 'Quản trị';
			|ru = 'Администрирование';
			|en = 'Administration'; fa = 'مدیریت سیستم';
			|it = 'Amministrazione';
			|pl = 'Administration';
			|tr = 'Yönetim'"));
	
	RightsList.Add("DataAdministration",
		NStr("vi = 'Quản trị dữ liệu';
			|ru = 'Администрирование данных';
			|en = 'Data administration'; fa = 'Data administration';
			|it = 'Amministrazione dati';
			|pl = 'Administrowanie danych';
			|tr = 'Veri yönetimi'"));
	
	RightsList.Add("UpdateDataBaseConfiguration",
		NStr("vi = 'Cập nhật cấu hình cơ sở dữ liệu';
			|ru = 'Обновление конфигурации базы данных';
			|en = 'Update database configuration'; fa = 'به‌روزرسانی پیکربندی پایگاه داده';
			|it = 'Aggiornamento della configurazione del database';
			|pl = 'Aktualizacja konfiguracji bazy danych';
			|tr = 'Veritabanı yapılandırmayı güncelle'"));
	
	RightsList.Add("ExclusiveMode",
		NStr("vi = 'Chế độ độc quyền';
			|ru = 'Монопольный режим';
			|en = 'Exclusive mode'; fa = 'حالت انحصاری';
			|it = 'Regime Multithread';
			|pl = 'Tryb wyłączności';
			|tr = 'Tekel mod'"));
	
	RightsList.Add("ActiveUsers",
		NStr("vi = 'Người sử dụng đang làm việc';
			|ru = 'Активные пользователи';
			|en = 'Active users'; fa = 'کاربران فعال';
			|it = 'Utenti attivi';
			|pl = 'Aktywni użytkownicy';
			|tr = 'Aktif kullanıcılar'"));
	
	RightsList.Add("EventLog",
		NStr("vi = 'Nhật ký sự kiện';
			|ru = 'Журнал регистрации';
			|en = 'Event log'; fa = 'گزارش رویدادها';
			|it = 'Log di registrazione';
			|pl = 'Informacja techniczna o rezultatach przetwarzania danych';
			|tr = 'Olay günlüğü'"));
	
	RightsList.Add("ThinClient",
		NStr("vi = 'Thin client';
			|ru = 'Тонкий клиент';
			|en = 'Thin client'; fa = 'Thin client';
			|it = 'Thin client';
			|pl = 'Cienki klient';
			|tr = 'İnce istemci'"));
	
	RightsList.Add("WebClient",
		NStr("vi = 'Web-client';
			|ru = 'Веб-клиент';
			|en = 'Web client'; fa = 'Web client';
			|it = 'Web-client';
			|pl = 'Web client';
			|tr = 'Web istemcisi'"));
	
	RightsList.Add("MobileClient",
		NStr("vi = 'Mobile client';
			|ru = 'Мобильный клиент';
			|en = 'Mobile client'; fa = 'Mobile client';
			|it = 'Client mobile';
			|pl = 'Klient mobilny';
			|tr = 'Mobil istemci'"));
	
	RightsList.Add("ThickClient",
		NStr("vi = 'Thick client';
			|ru = 'Толстый клиент';
			|en = 'Thick client'; fa = 'Thick client';
			|it = 'Thick client';
			|pl = 'Gruby klient';
			|tr = 'Donatımlı istemci'"));
	
	RightsList.Add("ExternalConnection",
		NStr("vi = 'Kết nối ngoài';
			|ru = 'Внешнее соединение';
			|en = 'External connection'; fa = 'External connection';
			|it = 'Connessione esterna';
			|pl = 'Połączenie zewnętrzne';
			|tr = 'Harici bağlantı'"));
	
	RightsList.Add("Automation",
		NStr("vi = 'Automation';
			|ru = 'Automation';
			|en = 'Automation'; fa = 'Automation';
			|it = 'Automation';
			|pl = 'Automation';
			|tr = 'Automation'"));
	
	RightsList.Add("AllFunctionsMode",
		NStr("vi = 'Chế độ ""Tất cả tính năng""';
			|ru = 'Режим ""Все функции""';
			|en = '""All functions"" mode'; fa = '""All functions"" mode';
			|it = 'Modalità ""Tutte le funzioni""';
			|pl = 'Tryb ""Wszystkie funkcje""';
			|tr = '""Tüm işlevler"" modu'"));
	
	RightsList.Add("CollaborationSystemInfoBaseRegistration",
		NStr("vi = 'Ghi nhận hệ thống giao tiếp';
			|ru = 'Регистрация системы взаимодействия';
			|en = 'Collaboration system registration'; fa = 'Collaboration system registration';
			|it = 'Registrazione del sistema di interazione';
			|pl = 'Rejestracja systemu interakcji';
			|tr = 'Etkileşim sisteminin kaydı'"));
	
	RightsList.Add("MainWindowModeNormal",
		NStr("vi = 'Chế độ cửa sổ chính ""Thường""';
			|ru = 'Режим основного окна ""Обычный""';
			|en = 'Main window ""Standard"" mode'; fa = 'Main window ""Standard"" mode';
			|it = 'Modalità finestra principale ""Regolare""';
			|pl = 'Tryb podstawowego okna ""Zwykły""';
			|tr = '""Sıradan"" ana penceresi modu'"));
	
	RightsList.Add("MainWindowModeWorkplace",
		NStr("vi = 'Chế độ cửa sổ chính ""Chỗ làm việc""';
			|ru = 'Режим основного окна ""Рабочее место""';
			|en = 'Main window ""Workspace"" mode'; fa = 'Main window ""Workspace"" mode';
			|it = 'Modalità finestra principale ""Postazione di lavoro""';
			|pl = 'Tryb podstawowego okna ""Miejsce pracy""';
			|tr = '""Çalışma alanı"" ana pencere modu'"));
	
	RightsList.Add("MainWindowModeEmbeddedWorkplace",
		NStr("vi = 'Chế độ cửa sổ chính ""Chỗ làm việc hệ thống""';
			|ru = 'Режим основного окна ""Встроенное рабочее место""';
			|en = 'Main window ""Embedded workspace"" mode'; fa = 'Main window ""Embedded workspace"" mode';
			|it = 'Modalità finestra principale ""Postazione di lavoro integrata""';
			|pl = 'Tryb podstawowego ""Wbudowane miejsce pracy""';
			|tr = '""Dahili çalışma alanı"" ana penceresi modu'"));
	
	RightsList.Add("MainWindowModeFullscreenWorkplace",
		NStr("vi = 'Chế độ cửa sổ chính ""Chỗ làm việc toàn màn hình""';
			|ru = 'Режим основного окна ""Полноэкранное рабочее место""';
			|en = 'Main window ""Fullscreen workspace"" mode'; fa = 'Main window ""Fullscreen workspace"" mode';
			|it = 'Modalità finestra principale ""Postazione di lavoro a schermo intero""';
			|pl = 'Tryb podstawowego okna ""Pełnoekranowe miejsce pracy""';
			|tr = '""Tam ekranlı çalışma alanı"" ana penceresi modu'"));
	
	RightsList.Add("MainWindowModeKiosk",
		NStr("vi = 'Chế độ cửa sổ chính ""Kiosk""';
			|ru = 'Режим основного окна ""Киоск""';
			|en = 'Main window ""Kiosk"" mode'; fa = 'Main window ""Kiosk"" mode';
			|it = 'Modalità finestra principale ""Chiosco""';
			|pl = 'Tryb podstawowego okna ""Kiosk""';
			|tr = '""Köşk"" ana penceresi modu'"));
	
	RightsList.Add("SaveUserData",
		NStr("vi = 'Lưu dữ liệu của người sử dụng';
			|ru = 'Сохранение данных пользователя';
			|en = 'Save user data'; fa = 'ذخیره داده‌های کاربر';
			|it = 'Archiviazione dei dati dell''utente';
			|pl = 'Zapis danych użytkownika';
			|tr = 'Kullanıcı verilerini kaydet'"));
	
	RightsList.Add("ConfigurationExtensionsAdministration",
		NStr("vi = 'Quản trị phần mở rộng cấu hình';
			|ru = 'Администрирование расширений конфигурации';
			|en = 'Administer configuration extensions'; fa = 'Administer configuration extensions';
			|it = 'Amministrazione estensioni di configurazione';
			|pl = 'Administrowanie rozszerzeń konfiguracji';
			|tr = 'Yapılandırma uzantılarının yönetimi'"));
	
	RightsList.Add("InteractiveOpenExtDataProcessors",
		NStr("vi = 'Mở trực tác bộ xử lý ngoài';
			|ru = 'Интерактивное открытие внешних обработок';
			|en = 'Open external data processors interactively'; fa = 'Open external data processors interactively';
			|it = 'Apertura interattiva delle elaborazioni esterne';
			|pl = 'Interaktywne otwarcie zewnętrznych procesorów danych';
			|tr = 'Dış işlenenlerin interaktif açılması'"));
	
	RightsList.Add("InteractiveOpenExtReports",
		NStr("vi = 'Mở trực tác báo cáo ngoài';
			|ru = 'Интерактивное открытие внешних отчетов';
			|en = 'Open external reports interactively'; fa = 'Open external reports interactively';
			|it = 'Apertura interattiva report esterni';
			|pl = 'Otwarcie interaktywne zewnętrznych raportów zewnętrznych';
			|tr = 'Harici raporların interaktif açılması'"));
	
	RightsList.Add("Output",
		NStr("vi = 'Hiển thị';
			|ru = 'Вывод';
			|en = 'Output'; fa = 'خروجی';
			|it = 'Visualizzazione';
			|pl = 'Output';
			|tr = 'Sonuç'"));
	
	AccessLevels = RightsDetails.AccessLevels;
	For Each ListItem In RightsList Do
		NewRow = AccessLevels.Add();
		NewRow.Right   = ListItem.Value;
		NewRow.Level = 1;
	EndDo;
	
	Return RightsDetails;
	
EndFunction

Function ViewRight()
	
	RightsDetails = RightsDetails();
	RightsList = RightsDetails.RightsList;
	
	RightsList.Add("View",
		NStr("vi = 'Xem';
			|ru = 'Просмотр';
			|en = 'View'; fa = 'مشاهده';
			|it = 'Visualizzazione';
			|pl = 'View';
			|tr = 'Görüntüle'"));
	
	NewRow = RightsDetails.AccessLevels.Add();
	NewRow.Right   = "View";
	NewRow.Level = 6;
	
	Return RightsDetails;
	
EndFunction

Function RightUse()
	
	RightsDetails = RightsDetails();
	RightsList = RightsDetails.RightsList;
	
	RightsList.Add("Use",
		NStr("vi = 'Sử dụng';
			|ru = 'Использование';
			|en = 'Use'; fa = 'استفاده';
			|it = 'Utilizzo';
			|pl = 'Use';
			|tr = 'Kullanım'"));
	
	NewRow = RightsDetails.AccessLevels.Add();
	NewRow.Right   = "Use";
	NewRow.Level = 2;
	
	Return RightsDetails;
	
EndFunction

Function SessionSettingRights()
	
	RightsDetails = RightsDetails();
	RightsList = RightsDetails.RightsList;
	
	// @Access-right-1
	RightsList.Add("Get",
		NStr("vi = 'Nhận';
			|ru = 'Получение';
			|en = 'Get'; fa = 'دریافت';
			|it = 'Ricezione';
			|pl = 'Get';
			|tr = 'Giriş'"));
	
	// @Access-right-1
	RightsList.Add("Set",
		NStr("vi = 'Cài đặt';
			|ru = 'Установка';
			|en = 'Install'; fa = 'نصب';
			|it = 'Installazione';
			|pl = 'Install';
			|tr = 'Kurulum'"));
	
	NewRow = RightsDetails.AccessLevels.Add();
	NewRow.Right   = "Get" + "," + "Set"; // @Access-right-1, @Access-right-3
	NewRow.Level = 14;
	NewRow.ThisPermissionSet = True;
	
	NewRow = RightsDetails.AccessLevels.Add();
	NewRow.Right   = "Set"; // @Access-right-1
	NewRow.Level = 13;
	
	NewRow = RightsDetails.AccessLevels.Add();
	NewRow.Right   = "Get"; // @Access-right-1
	NewRow.Level = 12;
	
	Return RightsDetails;
	
EndFunction

Function RightsAttributes(NoEdit = False)
	
	RightsDetails = RightsDetails();
	RightsList = RightsDetails.RightsList;
	
	RightsList.Add("View",
		NStr("vi = 'Xem';
			|ru = 'Просмотр';
			|en = 'View'; fa = 'مشاهده';
			|it = 'Visualizzazione';
			|pl = 'Przegląd';
			|tr = 'Görüntüle'"));
	
	If Not NoEdit Then
		RightsList.Add("Edit",
			NStr("vi = 'Chỉnh sửa';
				|ru = 'Редактирование';
				|en = 'Edit'; fa = 'ویرایش';
				|it = 'Modifica';
				|pl = 'Edycja';
				|tr = 'Düzenleme'"));
		
		NewRow = RightsDetails.AccessLevels.Add();
		NewRow.Right   = "Edit";
		NewRow.Level = 9;
	EndIf;
	
	NewRow = RightsDetails.AccessLevels.Add();
	NewRow.Right   = "View";
	NewRow.Level = 6;
	
	Return RightsDetails;
	
EndFunction

Function ExchangePlanRights()
	
	RightsDetails = RightsDetails();
	RightsList = RightsDetails.RightsList;
	
	AddPermissionsProgrammingWorkWithObjects(RightsList);
	AddPermissionsInteractiveWorkWithObjects(RightsList);
	
	RightsList.Add("InputByString",
		NStr("vi = 'Nhập theo xâu ký tự';
			|ru = 'Ввод по строке';
			|en = 'Input by string'; fa = 'Input by string';
			|it = 'Inserimento per riga';
			|pl = 'Wprowadzenie według wiersza';
			|tr = 'Satır girdisi'"));
	
	AddJobPermissionsWithHistory(RightsList);
	
	FillAccessLevels(RightsDetails);
	
	Return RightsDetails;
	
EndFunction

Function RightsConsts()
	
	RightsDetails = RightsDetails();
	RightsList = RightsDetails.RightsList;
	
	AddPermissionsProgrammingWorkWithObjects(RightsList, , False, False);
	AddPermissionsInteractiveWorkWithObjects(RightsList, , False);
	AddJobPermissionsWithHistory(RightsList, False);
	
	FillAccessLevels(RightsDetails, , False, False);
	
	Return RightsDetails;
	
EndFunction

Function RightsofDirectoryandPlans()
	
	RightsDetails = RightsDetails();
	RightsList = RightsDetails.RightsList;
	
	AddPermissionsProgrammingWorkWithObjects(RightsList);
	AddPermissionsInteractiveWorkWithObjects(RightsList);
	AddJobPermissionsWithPredefinedData(RightsList);
	
	RightsList.Add("InputByString",
		NStr("vi = 'Nhập theo xâu ký tự';
			|ru = 'Ввод по строке';
			|en = 'Input by string'; fa = 'Input by string';
			|it = 'Inserimento per riga';
			|pl = 'Wprowadzenie według wiersza';
			|tr = 'Satır girdisi'"));
	
	AddJobPermissionsWithHistory(RightsList);
	
	FillAccessLevels(RightsDetails);
	
	Return RightsDetails;
	
EndFunction

Function SequenceAndRecalculationRights()
	
	RightsDetails = RightsDetails();
	RightsList = RightsDetails.RightsList;
	
	AddPermissionsProgrammingWorkWithObjects(RightsList,, False);
	
	NewRow = RightsDetails.AccessLevels.Add();
	NewRow.Right   = "Update";
	NewRow.Level = 4;
	NewRow.RightWithRestriction = "Update";
	
	NewRow = RightsDetails.AccessLevels.Add();
	NewRow.Right   = "Read";
	NewRow.Level = 3;
	NewRow.RightWithRestriction = "Read";
	
	Return RightsDetails;
	
EndFunction

Function DocumentPermissions()
	
	RightsDetails = RightsDetails();
	RightsList = RightsDetails.RightsList;
	
	AddPermissionsProgrammingWorkWithObjects(RightsList);
	
	RightsList.Add("Posting",
		NStr("vi = 'Kết chuyển';
			|ru = 'Проведение';
			|en = 'Post'; fa = 'ثبت';
			|it = 'Svolgimento';
			|pl = 'Post';
			|tr = 'Kaydedildi'"));
	
	RightsList.Add("UndoPosting",
		NStr("vi = 'Hủy kết chuyển';
			|ru = 'Отмена проведения';
			|en = 'Unpost'; fa = 'لغو ثبت';
			|it = 'Annullamento della registrazione';
			|pl = 'Anuluj księgowanie';
			|tr = 'Gönderim iptali'"));
	
	AddPermissionsInteractiveWorkWithObjects(RightsList);
	
	RightsList.Add("InteractivePosting",
		NStr("vi = 'Kết chuyển trực tác';
			|ru = 'Интерактивное проведение';
			|en = 'Post interactively'; fa = 'Post interactively';
			|it = 'Svolgimento interattivo';
			|pl = 'Interaktywne zatwierdzenie ';
			|tr = 'İnteraktif geçirme'"));
	
	RightsList.Add("InteractivePostingRegular",
		NStr("vi = 'Kết chuyển trực tác không theo thời gian thực';
			|ru = 'Интерактивное проведение неоперативное';
			|en = 'Backdate post interactively'; fa = 'Backdate post interactively';
			|it = 'Svolgimento interattivo non operativo';
			|pl = 'Interaktywne zatwierdzenie nieoperacyjne';
			|tr = 'Operasyonel olmayan interaktiv geçirme'"));
	
	RightsList.Add("InteractiveUndoPosting",
		NStr("vi = 'Hủy kết chuyển trực tác';
			|ru = 'Интерактивная отмена проведения';
			|en = 'Unpost interactively'; fa = 'Unpost interactively';
			|it = 'Annullamento interattivo di svolgimento';
			|pl = 'Interaktywne anulowanie zatwierdzenia';
			|tr = 'İnteraktif geçirme iptali'"));
	
	RightsList.Add("InteractiveChangeOfPosted",
		NStr("vi = 'Thay đổi trực tác các chứng từ đã kết chuyển';
			|ru = 'Интерактивное изменение проведенных';
			|en = 'Modify posted items interactively'; fa = 'Modify posted items interactively';
			|it = 'Modifica interattiva svolti';
			|pl = 'Interaktywna zmiana zatwierdzonych';
			|tr = 'İnteraktif geçirilenlerin değiştirilmesi'"));
	
	RightsList.Add("InputByString",
		NStr("vi = 'Nhập theo xâu ký tự';
			|ru = 'Ввод по строке';
			|en = 'Input by string'; fa = 'Input by string';
			|it = 'Inserimento per riga';
			|pl = 'Wprowadzenie według wiersza';
			|tr = 'Satır girdisi'"));
	
	AddJobPermissionsWithHistory(RightsList);
	
	FillAccessLevels(RightsDetails);
	
	Return RightsDetails;
	
EndFunction

Function PermissionsJournalDocuments()
	
	RightsDetails = RightsDetails();
	RightsList = RightsDetails.RightsList;
	
	AddPermissionsProgrammingWorkWithObjects(RightsList, True);
	AddPermissionsInteractiveWorkWithObjects(RightsList, True);
	
	FillAccessLevels(RightsDetails, True);
	
	Return RightsDetails;
	
EndFunction

Function RightsReportProcessingFunctions()
	
	RightsDetails = RightsDetails();
	RightsList = RightsDetails.RightsList;
	
	RightsList.Add("Use",
		NStr("vi = 'Sử dụng';
			|ru = 'Использование';
			|en = 'Use'; fa = 'استفاده';
			|it = 'Utilizzo';
			|pl = 'Use';
			|tr = 'Kullanım'"));
	
	RightsList.Add("View",
		NStr("vi = 'Xem';
			|ru = 'Просмотр';
			|en = 'View'; fa = 'مشاهده';
			|it = 'Visualizzazione';
			|pl = 'View';
			|tr = 'Görüntüle'"));
	
	NewRow = RightsDetails.AccessLevels.Add();
	NewRow.Right   = "View";
	NewRow.Level = 6;
	
	NewRow = RightsDetails.AccessLevels.Add();
	NewRow.Right   = "Use";
	NewRow.Level = 2;
	
	Return RightsDetails;
	
EndFunction

Function RightsRegisterInformation()
	
	RightsDetails = RightsDetails();
	RightsList = RightsDetails.RightsList;
	
	AddPermissionsProgrammingWorkWithObjects(RightsList,, False);
	AddPermissionsInteractiveWorkWithObjects(RightsList,, False);
	
	RightsList.Add("TotalsControl",
		NStr("vi = 'Quản lý tổng số';
			|ru = 'Управление итогами';
			|en = 'Totals management'; fa = 'مدیریت جمع‌ها';
			|it = 'Gestione totali';
			|pl = 'Zarządzanie wynikami';
			|tr = 'Sonuç yönetimi'"));
	
	AddJobPermissionsWithHistory(RightsList);
	
	FillAccessLevels(RightsDetails,, False);
	
	Return RightsDetails;
	
EndFunction

Function RightsRegisterAccumulationAndAccounting()
	
	RightsDetails = RightsDetails();
	RightsList = RightsDetails.RightsList;
	
	AddPermissionsProgrammingWorkWithObjects(RightsList,, False);
	AddPermissionsInteractiveWorkWithObjects(RightsList,, False);
	
	RightsList.Add("TotalsControl",
		NStr("vi = 'Quản lý tổng số';
			|ru = 'Управление итогами';
			|en = 'Totals management'; fa = 'مدیریت جمع‌ها';
			|it = 'Gestione totali';
			|pl = 'Zarządzanie wynikami';
			|tr = 'Sonuç yönetimi'"));
	
	FillAccessLevels(RightsDetails,, False);
	
	Return RightsDetails;
	
EndFunction

Function RightsRegisterCalculation()
	
	RightsDetails = RightsDetails();
	RightsList = RightsDetails.RightsList;
	
	AddPermissionsProgrammingWorkWithObjects(RightsList,, False);
	AddPermissionsInteractiveWorkWithObjects(RightsList,, False);
	
	FillAccessLevels(RightsDetails,, False);
	
	Return RightsDetails;
	
EndFunction

Function RightsBusinessProcess()
	
	RightsDetails = RightsDetails();
	RightsList = RightsDetails.RightsList;
	
	AddPermissionsProgrammingWorkWithObjects(RightsList);
	
	RightsList.Add("Start",
		NStr("vi = 'Khởi động';
			|ru = 'Старт';
			|en = 'Start'; fa = 'شروع';
			|it = 'Avvio';
			|pl = 'Start';
			|tr = 'Başlat'"));
	
	AddPermissionsInteractiveWorkWithObjects(RightsList);
	
	RightsList.Add("InteractiveStart",
		NStr("vi = 'Khởi động trực tác';
			|ru = 'Интерактивный старт';
			|en = 'Start interactively'; fa = 'Start interactively';
			|it = 'Avvio interattivo';
			|pl = 'Interaktywny start';
			|tr = 'İnteraktif başlatma'"));
	
	RightsList.Add("InteractiveActivate",
		NStr("vi = 'Kích hoạt trực tác';
			|ru = 'Интерактивная активация';
			|en = 'Activate interactively'; fa = 'Activate interactively';
			|it = 'Attivazione interazione';
			|pl = 'Interaktywna aktywacja';
			|tr = 'İnteraktif etkinleştirme'"));
	
	RightsList.Add("InputByString",
		NStr("vi = 'Nhập theo xâu ký tự';
			|ru = 'Ввод по строке';
			|en = 'Input by string'; fa = 'Input by string';
			|it = 'Inserimento per riga';
			|pl = 'Wprowadzenie według wiersza';
			|tr = 'Satır girdisi'"));
	
	AddJobPermissionsWithHistory(RightsList);
	
	FillAccessLevels(RightsDetails);
	
	Return RightsDetails;
	
EndFunction

Function RightsTasks()
	
	RightsDetails = RightsDetails();
	RightsList = RightsDetails.RightsList;
	
	AddPermissionsProgrammingWorkWithObjects(RightsList);
	
	// @Access-right-1
	RightsList.Add("Execute",
		NStr("vi = 'Thực hiện';
			|ru = 'Выполнение';
			|en = 'Execute'; fa = 'اجرا';
			|it = 'Esecuzione';
			|pl = 'Execute';
			|tr = 'Yürütme'"));
	
	AddPermissionsInteractiveWorkWithObjects(RightsList);
	
	RightsList.Add("InteractiveExecute",
		NStr("vi = 'Thực hiện trực tác';
			|ru = 'Интерактивный выполнение';
			|en = 'Execution interactively'; fa = 'Execution interactively';
			|it = 'Esecuzione interattiva';
			|pl = 'Interaktywne wykonanie';
			|tr = 'İnteraktif tamamlama'"));
	
	RightsList.Add("InteractiveActivate",
		NStr("vi = 'Kích hoạt trực tác';
			|ru = 'Интерактивная активация';
			|en = 'Activate interactively'; fa = 'Activate interactively';
			|it = 'Attivazione interazione';
			|pl = 'Interaktywna aktywacja';
			|tr = 'İnteraktif etkinleştirme'"));
	
	RightsList.Add("InputByString",
		NStr("vi = 'Nhập theo xâu ký tự';
			|ru = 'Ввод по строке';
			|en = 'Input by string'; fa = 'Input by string';
			|it = 'Inserimento per riga';
			|pl = 'Wprowadzenie według wiersza';
			|tr = 'Satır girdisi'"));
	
	AddJobPermissionsWithHistory(RightsList);
	
	FillAccessLevels(RightsDetails);
	
	Return RightsDetails;
	
EndFunction

Function RightsExternalDataSource()
	
	RightsDetails = RightsDetails();
	RightsList = RightsDetails.RightsList;
	
	// @Access-right-1
	RightsList.Add("Use",
		NStr("vi = 'Sử dụng';
			|ru = 'Использование';
			|en = 'Use'; fa = 'استفاده';
			|it = 'Utilizzo';
			|pl = 'Use';
			|tr = 'Kullanım'"));
	
	// @Access-right-1
	RightsList.Add("Administration",
		NStr("vi = 'Quản trị';
			|ru = 'Администрирование';
			|en = 'Administration'; fa = 'مدیریت سیستم';
			|it = 'Amministrazione';
			|pl = 'Administration';
			|tr = 'Yönetim'"));
	
	RightsList.Add("StandardAuthenticationChange",
		NStr("vi = 'Thay đổi đăng nhập chuẩn của người sử dụng hiện tại';
			|ru = 'Изменение стандартной аутентификации текущего пользователя';
			|en = 'Change standard authentication for current user'; fa = 'Change standard authentication for current user';
			|it = 'Modifica dell''autenticazione standard dell''utente corrente';
			|pl = 'Zmiana standardowego uwierzytelniania bieżącego użytkownika';
			|tr = 'Geçerli kullanıcının standart doğrulamasının değiştirilmesi'"));
	
	RightsList.Add("SessionStandardAuthenticationChange",
		NStr("vi = 'Thay đổi đăng nhập chuẩn của phiên làm việc';
			|ru = 'Изменение стандартной аутентификации сеанса';
			|en = 'Change standard authentication for current session'; fa = 'Change standard authentication for current session';
			|it = 'Modifica dell''autenticazione standard della sessione';
			|pl = 'Zmiana standardowego uwierzytelniania sesji';
			|tr = 'Standart oturum doğrulamasının değiştirilmesi'"));
	
	RightsList.Add("SessionOSAuthenticationChange",
		NStr("vi = 'Thay đổi đăng nhập hệ điều hành phiên làm việc';
			|ru = 'Изменение аутентификации операционной системы сеанса';
			|en = 'Change standard authentication for current session OS'; fa = 'Change standard authentication for current session OS';
			|it = 'Modifica dell''autenticazione del sistema operativo di sessione';
			|pl = 'Zmiana uwierzytelniania systemu operacyjnego sesji';
			|tr = 'Oturumun işletim sistemi kimlik doğrulamasını değiştir'"));
	
	NewRow = RightsDetails.AccessLevels.Add();
	NewRow.Right   = "Use" + "," + "Administration"; // @Access-right-1, @Access-right-3
	NewRow.Level = 17;
	NewRow.ThisPermissionSet = True;
	
	NewRow = RightsDetails.AccessLevels.Add();
	NewRow.Right   = "Administration"; // @Access-right-1
	NewRow.Level = 16;
	
	NewRow = RightsDetails.AccessLevels.Add();
	NewRow.Right   = "Use"; // @Access-right-1
	NewRow.Level = 15;
	
	NewRow = RightsDetails.AccessLevels.Add();
	NewRow.Right   = "StandardAuthenticationChange";
	NewRow.Level = 1;
	
	NewRow = RightsDetails.AccessLevels.Add();
	NewRow.Right   = "SessionStandardAuthenticationChange";
	NewRow.Level = 1;
	
	NewRow = RightsDetails.AccessLevels.Add();
	NewRow.Right   = "SessionOSAuthenticationChange";
	NewRow.Level = 1;
	
	Return RightsDetails;
	
EndFunction

Function RightsTableExternalDataSource()
	
	RightsDetails = RightsDetails();
	RightsList = RightsDetails.RightsList;
	
	AddPermissionsProgrammingWorkWithObjects(RightsList);
	AddPermissionsInteractiveWorkWithObjects(RightsList,,, False);
	
	RightsList.Add("InputByString",
		NStr("vi = 'Nhập theo xâu ký tự';
			|ru = 'Ввод по строке';
			|en = 'Input by string'; fa = 'Input by string';
			|it = 'Inserimento per riga';
			|pl = 'Wprowadzenie według wiersza';
			|tr = 'Satır girdisi'"));
	
	FillAccessLevels(RightsDetails);
	
	Return RightsDetails;
	
EndFunction

Function PermissionsCubeAndDimensionTables()
	
	RightsDetails = RightsDetails();
	RightsList = RightsDetails.RightsList;
	
	AddPermissionsProgrammingWorkWithObjects(RightsList, True,, False);
	AddPermissionsInteractiveWorkWithObjects(RightsList, True);
	
	FillAccessLevels(RightsDetails, True,, False);
	
	Return RightsDetails;
	
EndFunction

Procedure AddPermissionsProgrammingWorkWithObjects(RightsList, Un_changed = False, ReferenceItems = True, withlimit = True)
	
	// @Access-right-1
	RightsList.Add("Read",
		NStr("vi = 'Đọc';
			|ru = 'Чтение';
			|en = 'Read'; fa = 'خوانده‌شده';
			|it = 'Lettura';
			|pl = 'Read';
			|tr = 'Okuma'"), withlimit);
	
	If Un_changed Then
		Return;
	EndIf;
	
	// @Access-right-1
	RightsList.Add("Update",
		NStr("vi = 'Thay đổi';
			|ru = 'Изменение';
			|en = 'Update'; fa = 'به‌روزرسانی';
			|it = 'Modifica';
			|pl = 'Update';
			|tr = 'Değiştir'"), withlimit);
	
	If Not ReferenceItems Then
		Return;
	EndIf;
	
	// @Access-right-1
	RightsList.Add("Insert",
		NStr("vi = 'Thêm';
			|ru = 'Добавление';
			|en = 'Add'; fa = 'افزودن';
			|it = 'Aggiungere';
			|pl = 'Add';
			|tr = 'Ekle'"), withlimit);
	
	// @Access-right-1
	RightsList.Add("Delete",
		NStr("vi = 'Xóa';
			|ru = 'Удаление';
			|en = 'Delete'; fa = 'حذف';
			|it = 'Eliminazione';
			|pl = 'Delete';
			|tr = 'Sil'"), withlimit);
	
EndProcedure

Procedure AddPermissionsInteractiveWorkWithObjects(RightsList, Un_changed = False, ReferenceItems = True, WithDeletionTagged = True)
	
	// @Access-right-1
	RightsList.Add("View",
		NStr("vi = 'Xem';
			|ru = 'Просмотр';
			|en = 'View'; fa = 'مشاهده';
			|it = 'Visualizzazione';
			|pl = 'Przegląd';
			|tr = 'Görüntüle'"));
	
	If Un_changed Then
		Return;
	EndIf;
	
	// @Access-right-1
	RightsList.Add("Edit",
		NStr("vi = 'Chỉnh sửa';
			|ru = 'Редактирование';
			|en = 'Edit'; fa = 'ویرایش';
			|it = 'Modifica';
			|pl = 'Edycja';
			|tr = 'Düzenle'"));
	
	If Not ReferenceItems Then
		Return;
	EndIf;
	
	RightsList.Add("InteractiveInsert",
		NStr("vi = 'Thêm trực tác';
			|ru = 'Интерактивное добавление';
			|en = 'Add interactively'; fa = 'Add interactively';
			|it = 'Aggiunta interattiva';
			|pl = 'Interaktywne dodawanie';
			|tr = 'İnteraktif yerleştirme'"));
	
	RightsList.Add("InteractiveDelete",
		NStr("vi = 'Xóa trực tác';
			|ru = 'Интерактивное удаление';
			|en = 'Delete interactively'; fa = 'Delete interactively';
			|it = 'Eliminazione interattiva';
			|pl = 'Interaktywne usunięcie';
			|tr = 'İnteraktif kaldırma'"));
	
	If Not WithDeletionTagged Then
		Return;
	EndIf;
	
	RightsList.Add("InteractiveDeletionMark",
		NStr("vi = 'Đặt dấu xóa trực tác';
			|ru = 'Интерактивная пометка на удаление';
			|en = 'Mark for deletion interactively'; fa = 'Mark for deletion interactively';
			|it = 'Contrassegno per l''eliminazione interattivo';
			|pl = 'Interaktywne zaznaczenie do usunięcia';
			|tr = 'İnteraktif kaldırma işaretlenmesi'"));
	
	RightsList.Add("InteractiveClearDeletionMark",
		NStr("vi = 'Bỏ dấu xóa trực tác';
			|ru = 'Интерактивное снятие пометки удаления';
			|en = 'Unmark for deletion interactively'; fa = 'Unmark for deletion interactively';
			|it = 'Rimozione contrassegno per l''eliminazione interattivo';
			|pl = 'Interaktywne usunięcie zaznaczenia do usunięcia';
			|tr = 'İnteraktif kaldırma işaretlenmesinin iptali'"));
	
	RightsList.Add("InteractiveDeleteMarked",
		NStr("vi = 'Xóa trực tác các đối tượng có đặt dấu';
			|ru = 'Интерактивное удаление помеченных';
			|en = 'Delete items marked for deletion interactively'; fa = 'Delete items marked for deletion interactively';
			|it = 'Eliminazione interattiva contrassegnati';
			|pl = 'Interaktywne usunięcie zaznaczonych';
			|tr = 'İşaretlenenlerin interaktif kaldırılması'"));
	
EndProcedure

Procedure AddJobPermissionsWithPredefinedData(RightsList)
	
	RightsList.Add("InteractiveDeletePredefinedData",
		NStr("vi = 'Xóa trực tác các đối tượng định trước';
			|ru = 'Интерактивное удаление предопределенных';
			|en = 'Delete predefined items interactively'; fa = 'Delete predefined items interactively';
			|it = 'Eliminazione interattiva indefiniti';
			|pl = 'Interaktywne usunięcie predefiniowanych';
			|tr = 'Önceden seçilenlerin interaktif kaldırılması'"));
	
	RightsList.Add("InteractiveSetDeletionMarkPredefinedData",
		NStr("vi = 'Đặt dấu xóa trực tác các đối tượng định trước';
			|ru = 'Интерактивная пометка на удаление предопределенных';
			|en = 'Mark predefined items for deletion interactively'; fa = 'Mark predefined items for deletion interactively';
			|it = 'Contrassegno per l''eliminazione interattivo indefiniti';
			|pl = 'Interaktywne zaznaczenie do usunięcia predefiniowanych';
			|tr = 'Önceden seçilenlerin interaktif kaldırılması işareti'"));
	
	RightsList.Add("InteractiveClearDeletionMarkPredefinedData",
		NStr("vi = 'Bỏ dấu xóa trực tác các đối tượng định trước';
			|ru = 'Интерактивное снятие пометки удаления предопределенных';
			|en = 'Unmark predefined items for deletion interactively'; fa = 'Unmark predefined items for deletion interactively';
			|it = 'Rimozione contrassegno per l''eliminazione interattivo indefiniti';
			|pl = 'Interaktywne usunięcie zaznaczenia do usunięcia predefiniowanych';
			|tr = 'Önceden seçilenlerin interaktif kaldırılması işaretinin iptali'"));
	
	RightsList.Add("InteractiveDeleteMarkedPredefinedData",
		NStr("vi = 'Xóa trực tác các đối tượng định trước đã đặt dấu';
			|ru = 'Интерактивное удаление помеченных предопределенных';
			|en = 'Delete predefined items marked for deletion interactively'; fa = 'Delete predefined items marked for deletion interactively';
			|it = 'Eliminazione interattiva contrassegnati predefiniti';
			|pl = 'Interaktywne usunięcie zaznaczonych predefiniowanych';
			|tr = 'Önceden seçilmiş işaretlenenlerin interaktif kaldırılması'"));
	
EndProcedure

Procedure AddJobPermissionsWithHistory(RightsList, RightsOnMissingData = True)
	
	RightsList.Add("ReadDataHistory",
		NStr("vi = 'Đọc lịch sử dữ liệu';
			|ru = 'Чтение истории данных';
			|en = 'Read data history'; fa = 'Read data history';
			|it = 'Lettura cronologia dati';
			|pl = 'Odczyt historii danych';
			|tr = 'Veri geçmişinin okunması'"));
	
	If RightsOnMissingData Then
		RightsList.Add("ReadDataHistoryOfMissingData",
			NStr("vi = 'Đọc lịch sử dữ liệu của dữ liệu bị thiếu';
				|ru = 'Чтение истории данных отсутствующих данных';
				|en = 'Read data history of missing data'; fa = 'Read data history of missing data';
				|it = 'Lettura cronologia dati dei dati assenti';
				|pl = 'Odczyt historii danych brakujących danych';
				|tr = 'Var olmayan verilerin veri geçmişinin okunması'"));
	EndIf;
	
	RightsList.Add("UpdateDataHistory",
		NStr("vi = 'Thay đổi lịch sử dữ liệu';
			|ru = 'Изменение истории данных';
			|en = 'Modify data history'; fa = 'Modify data history';
			|it = 'Modifica cronologia dati';
			|pl = 'Zmiana historii danych';
			|tr = 'Veri geçmişinin değiştirilmesi'"));
	
	If RightsOnMissingData Then
		RightsList.Add("UpdateDataHistoryOfMissingData",
			NStr("vi = 'Thay đổi lịch sử dữ liệu của dữ liệu bị thiếu';
				|ru = 'Изменение истории данных отсутствующих данных';
				|en = 'Modify data history of missing data'; fa = 'Modify data history of missing data';
				|it = 'Modifica cronologia dati dei dati assenti';
				|pl = 'Zmiana historii danych brakujących danych';
				|tr = 'Var olmayan verilerin veri geçmişinin değiştirilmesi'"));
	EndIf;
	
	RightsList.Add("UpdateDataHistorySettings",
		NStr("vi = 'Thay đổi tùy chỉnh lịch sử dữ liệu';
			|ru = 'Изменение настроек истории данных';
			|en = 'Change data history settings'; fa = 'Change data history settings';
			|it = 'Modifica impostazioni cronologia dati';
			|pl = 'Zmiana ustawień historii danych';
			|tr = 'Veri geçmişi ayarlarının değiştirilmesi'"));
	
	RightsList.Add("UpdateDataHistoryVersionComment",
		NStr("vi = 'Thay đổi ghi chú phiên bản lịch sử dữ liệu';
			|ru = 'Изменение комментария версии истории данных';
			|en = 'Change data history version comment'; fa = 'Change data history version comment';
			|it = 'Modifica commento versione cronologia dati';
			|pl = 'Zmiana uwagi wersji historii danych';
			|tr = 'Veri geçmişi versiyonu yorumunun değiştirilmesi'"));
	
	RightsList.Add("ViewDataHistory",
		NStr("vi = 'Xem lịch sử dữ liệu';
			|ru = 'Просмотр истории данных';
			|en = 'View data history'; fa = 'View data history';
			|it = 'Visualizzazione cronologia dati';
			|pl = 'Przegląd historii danych';
			|tr = 'Veri geçmişini görüntüleme'"));
	
	RightsList.Add("EditDataHistoryVersionComment",
		NStr("vi = 'Soạn ghi chú phiên bản lịch sử dữ liệu';
			|ru = 'Редактирование комментария версии истории данных';
			|en = 'Edit data history version comment'; fa = 'Edit data history version comment';
			|it = 'Modifica commento versione cronologia dati';
			|pl = 'Edycje uwag wersji historii danych';
			|tr = 'Veri geçmişi versiyonu yorumunun düzenlenmesi'"));
	
	RightsList.Add("SwitchToDataHistoryVersion",
		NStr("vi = 'Chuyển đến phiên bản lịch sử dữ liệu';
			|ru = 'Переход на версию истории данных';
			|en = 'Rollback to data history version'; fa = 'Rollback to data history version';
			|it = 'Passaggio alla versione cronologia dati';
			|pl = 'Przejście do wersji historii danych';
			|tr = 'Veri geçmişi versiyonuna geçiş'"));

EndProcedure

Procedure FillAccessLevels(RightsDetails, Un_changed = False, Referential = True, withlimit = True)
	
	AccessLevels = RightsDetails.AccessLevels;
	
	If Referential And Not Un_changed Then
		NewRow = AccessLevels.Add();
		NewRow.Right   = "InteractiveInsert"; // @Access-right-1
		NewRow.Level = 11;
		If withlimit Then
			NewRow.RightWithRestriction = "Insert"; // @Access-right-1
		EndIf;
		
		NewRow = AccessLevels.Add();
		NewRow.Right   = "Edit" + "," + "Insert"; // @Access-right-1, @Access-right-3
		NewRow.Level = 10;
		NewRow.ThisPermissionSet = True;
		If withlimit Then
			NewRow.RightWithRestriction = "Insert"; // @Access-right-1
		EndIf;
	EndIf;
	
	If Not Un_changed Then
		NewRow = AccessLevels.Add();
		NewRow.Right   = "Edit"; // @Access-right-1
		NewRow.Level = 9;
		If withlimit Then
			NewRow.RightWithRestriction = "Update"; // @Access-right-1
		EndIf;
		
		If Referential Then
			NewRow = AccessLevels.Add();
			NewRow.Right   = "View" + "," + "Insert"; // @Access-right-1, @Access-right-3
			NewRow.Level = 8;
			NewRow.ThisPermissionSet = True;
			If withlimit Then
				NewRow.RightWithRestriction = "Insert"; // @Access-right-1
			EndIf;
		EndIf;
		
		NewRow = AccessLevels.Add();
		NewRow.Right   = "View" + "," + "Update"; // @Access-right-1, @Access-right-3
		NewRow.Level = 7;
		NewRow.ThisPermissionSet = True;
		If withlimit Then
			NewRow.RightWithRestriction = "Update"; // @Access-right-1
		EndIf;
	EndIf;
	
	NewRow = AccessLevels.Add();
	NewRow.Right   = "View"; // @Access-right-1
	NewRow.Level = 6;
	If withlimit Then
		NewRow.RightWithRestriction = "Read"; // @Access-right-1
	EndIf;
	
	If Referential And Not Un_changed Then
		NewRow = AccessLevels.Add();
		NewRow.Right   = "Insert"; // @Access-right-1
		NewRow.Level = 5;
		If withlimit Then
			NewRow.RightWithRestriction = "Insert"; // @Access-right-1
		EndIf;
	EndIf;
	
	If Not Un_changed Then
		NewRow = AccessLevels.Add();
		NewRow.Right   = "Update"; // @Access-right-1
		NewRow.Level = 4;
		If withlimit Then
			NewRow.RightWithRestriction = "Update"; // @Access-right-1
		EndIf;
	EndIf;
	
	NewRow = AccessLevels.Add();
	NewRow.Right   = "Read"; // @Access-right-1
	NewRow.Level = 3;
	If withlimit Then
		NewRow.RightWithRestriction = "Read"; // @Access-right-1
	EndIf;
	
EndProcedure

Function Images()
	
	Images = New ValueList;
	Images.Add(""); // No picture.
	Images.Add("Configuration",,,              PictureLib.MetadataConfiguration);
	Images.Add("Overall",,,                     PictureLib.MetadataCommon);
	Images.Add("Subsystems",,,                PictureLib.MetadataSubsystems);
	Images.Add("SessionParameters",,,           PictureLib.MetadataSessionParameters);
	Images.Add("CommonAttributes",,,            PictureLib.MetadataCommonAttributes);
	Images.Add("ExchangePlans",,,               PictureLib.MetadataExchangePlans);
	Images.Add("Attributes",,,                 PictureLib.MetadataAttributes);
	Images.Add("TabularSections",,,            PictureLib.MetadataTabularSections);
	Images.Add("StandardAttributes",,,      PictureLib.MetadataStandardAttributes);
	Images.Add("Commands",,,                   PictureLib.MetadataCommands);
	Images.Add("FilterCriteria",,,            PictureLib.MetadataFilterCriteria);
	Images.Add("CommonForms",,,                PictureLib.MetadataCommonForms);
	Images.Add("CommonCommands",,,              PictureLib.MetadataCommonCommands);
	Images.Add("WebServices",,,                PictureLib.MetadataWebServices);
	Images.Add("Operations",,,                  PictureLib.MetadataWebServicesOperations);
	Images.Add("HTTPServices",,,               PictureLib.MetadataHTTPServices);
	Images.Add("URLTemplates",,,                PictureLib.MetadataHTTPServicesURLTemplates);
	Images.Add("Methods",,,                    PictureLib.MetadataHTTPServicesURLTemplatesMethods);
	Images.Add("Constants",,,                 PictureLib.MetadataConstants);
	Images.Add("Catalogs",,,               PictureLib.MetadataCatalogs);
	Images.Add("Documents",,,                 PictureLib.MetadataDocuments);
	Images.Add("Sequences",,,        PictureLib.MetadataSequences);
	Images.Add("DocumentJournals",,,         PictureLib.MetadataDocumentJournals);
	Images.Add("Enums",,,              PictureLib.EnumerationMetadata);
	Images.Add("Reports",,,                    PictureLib.MetadataReports);
	Images.Add("DataProcessors",,,                 PictureLib.MetadataDataProcessors);
	Images.Add("ChartsOfCharacteristicTypes",,,   PictureLib.MetadataChartsOfCharacteristicTypes);
	Images.Add("ChartsOfAccounts",,,               PictureLib.MetadataChartsOfAccounts);
	Images.Add("AccountingFlags",,,             PictureLib.MetadataAccountingFlags);
	Images.Add("ExtDimensionAccountingFlags",,,     PictureLib.MetadataAccountingFlagsExtraDimension);
	Images.Add("StandardTabularSections",,, PictureLib.MetadataStandardTabularSections);
	Images.Add("ChartsOfCalculationTypes",,,         PictureLib.MetadataChartsOfCalculationTypes);
	Images.Add("InformationRegisters",,,          PictureLib.MetadataInformationRegisters);
	Images.Add("Dimensions",,,                 PictureLib.MetadataDimensions);
	Images.Add("Resources",,,                   PictureLib.MetadataResources);
	Images.Add("AccumulationRegisters",,,        PictureLib.MetadataAccumulationRegisters);
	Images.Add("AccountingRegisters",,,       PictureLib.MetadataAccountingRegisters);
	Images.Add("CalculationRegisters",,,           PictureLib.MetadataCalculationRegisters);
	Images.Add("Recalculations",,,               PictureLib.MetadataRecalculations);
	Images.Add("BusinessProcesses",,,            PictureLib.MetadataBusinessProcesses);
	Images.Add("Tasks",,,                    PictureLib.MetadataTasks);
	Images.Add("AddressingAttributes",,,        PictureLib.MetadataAddressingAttributes);
	Images.Add("ExternalDataSources",,,    PictureLib.MetadataExternalDataSources);
	Images.Add("Tables",,,                   PictureLib.MetadataExternalSourcesTables);
	Images.Add("Fields",,,                      PictureLib.MetadataAttributes);
	Images.Add("Cubes",,,                      PictureLib.MetadataExternalSourcesCubes);
	Images.Add("DimensionTables",,,          PictureLib.MetadataExternalSourcesDimensionTables);
	Images.Add("Functions",,,                   PictureLib.MetadataExternalSourcesFunctions);
	
	Return Images;
	
EndFunction

Function PictureIndex(Context, Name)
	
	ListItem = Context.Images.FindByValue(Name);
	If ListItem = Undefined Then
		Return 0;
	EndIf;
	
	Return Context.Images.IndexOf(ListItem);
	
EndFunction

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf