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
	If VariantKey = "UserRightsToTable" Then
		Settings.EditStructureAllowed = False;
	EndIf;
	Settings.GenerateImmediately = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.OnDefineUsedTables = True;
	
EndProcedure

// See ReportsOverridable.OnCreateAtServer
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	If ValueIsFilled(Form.ReportSettings.OptionRef) Then
		Form.ReportSettings.Description = Form.ReportSettings.OptionRef;
	EndIf;
	
	If Form.OptionContext = Metadata.Catalogs.Users.FullName()
	   And Form.Parameters.VariantKey <> "UsersRightsByAllowedValue"
	   And Form.Parameters.Property("CommandParameter") Then
		If Form.Parameters.CommandParameter.Count() > 1 Then
			Form.CurrentVariantKey = "UsersRightsToTables";
			Form.Parameters.VariantKey = "UsersRightsToTables";
		Else
			Form.CurrentVariantKey = "UserRightsToTables";
			Form.Parameters.VariantKey = "UserRightsToTables";
		EndIf;
		Form.ContextOptions.Clear();
		Form.ContextOptions.Add(Form.CurrentVariantKey);
	EndIf;
	If ValueIsFilled(Form.OptionContext) Then
		Form.ParametersForm.InitialOptionKey = Form.CurrentVariantKey;
		Form.ParametersForm.Filter.Insert("InitialSelection");
	EndIf;
	
	If AccessManagementInternal.SimplifiedAccessRightsSetupInterface() Then
		Form.ReportSettings.SchemaModified = True;
		Schema = GetFromTempStorage(Form.ReportSettings.SchemaURL);
		Field = Schema.DataSets.UsersRights.Fields.Find("AccessGroup");
		Field.Title = NStr("vi = 'Hồ sơ của người sử dụng';
							|ru = 'Профиль пользователя';
							|en = 'User profile'; fa = 'User profile';
							|it = 'Profilo dell''utente';
							|pl = 'Profil użytkownika';
							|tr = 'Kullanıcı profili'");
		Field.ValueType = New TypeDescription("CatalogRef.AccessGroupProfiles");
		Form.ReportSettings.SchemaURL = PutToTempStorage(Schema, Form.UUID);
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
	
	Variant = ?(NewDCSettings = Undefined, "",
		NewDCSettings.AdditionalProperties.PredefinedOptionKey);
	
	If Variant = "AccessRightsAnalysis" Then
		ConfigureAccessRightsAnalysisOption(NewDCSettings, NewDCUserSettings);
		
	ElsIf Variant = "UsersRightsToObject" Then
		ConfigureUsersRightsToObjectOption(NewDCSettings, NewDCUserSettings);
		
	ElsIf Variant = "UsersRightsByAllowedValue" Then
		ConfigureUsersRightsByAllowedValueOption(NewDCSettings, NewDCUserSettings);
	EndIf;
	If NewDCSettings <> Undefined Then
		HideExcessDataFields(Variant, NewDCSettings, NewDCUserSettings);
		SetAvailableValuesForAccessKindField(Variant, NewDCSettings, NewDCUserSettings);
	EndIf;
	
	If SchemaKey <> "1" Then
		SchemaKey = "1";
		If TypeOf(Context) = Type("ClientApplicationForm") And NewDCSettings <> Undefined Then
			FormAttributes = New Structure("OptionContext");
			FillPropertyValues(FormAttributes, Context);
			If ValueIsFilled(FormAttributes.OptionContext) Then
				ConfigureContextOpeningParameters(Context,
					Variant, NewDCSettings, NewDCUserSettings);
			EndIf;
		EndIf;
	EndIf;
	
	If Not Users.IsFullUser() Then
		DataCompositionSchema.Parameters.User.UseRestriction = True;
		DataCompositionSchema.Parameters.UsersKind.UseRestriction = True;
	EndIf;
	
	If Not Constants.UseExternalUsers.Get() Then
		DataCompositionSchema.Parameters.UsersKind.UseRestriction = True;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		ModuleReportsServer = Common.CommonModule("ReportsServer");
		ModuleReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
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
	TablesToUse.Add(Metadata.Catalogs.AccessGroups.FullName());
	TablesToUse.Add(Metadata.InformationRegisters.UserGroupCompositions.FullName());
	
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
	
	If Not Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		ErrorText = NStr("vi = 'Để sử dụng báo cáo, cần triển khai phân hệ Phương án báo cáo.';
						|ru = 'Для использования отчета требуется внедрить подсистему Варианты отчетов.';
						|en = 'To use the report, deploy the Report options subsystem.'; fa = 'To use the report, deploy the Report options subsystem.';
						|it = 'Для использования отчета требуется внедрить подсистему Варианты отчетов.';
						|pl = 'To use the report, deploy the Report options subsystem.';
						|tr = 'Raporun kullanılması için Rapor Seçenekleri alt sistemini uygulamanız gerekmektedir.'");
		Raise ErrorText;
	EndIf;
	
	If ObjectRightsOption() And Not AccessManagement.ProductiveOption() Then
		ErrorText = NStr("vi = 'Phương án báo cáo ""Quyền của người sử dụng đối với đối tượng"" được hỗ trợ chỉ trong phương án tùy ý hạn chế truy cập ở mức độ bản ghi (RLS).';
						|ru = 'Вариант отчета ""Права пользователей на объект"" поддерживается только в производительном варианте ограничений доступа на уровне записей (RLS).';
						|en = 'The report option ""User rights to object"" is only supported for high-performance RLS mode.'; fa = 'The report option ""User rights to object"" is only supported for high-performance RLS mode.';
						|it = 'The report option ""User rights to object"" is only supported for high-performance RLS mode.';
						|pl = 'The report option ""User rights to object"" is only supported for high-performance RLS mode.';
						|tr = '""Nesne Üzerinde Kullanıcı Hakları"" rapor seçeneği yalnızca Kayıt Düzeyi Erişim Kısıtlamaları (RLS) üretici seçeneğinde desteklenir.'");
		Raise ErrorText;
	EndIf;
	
	ComposerSettings = SettingsComposer.GetSettings();
	
	ParameterUserType = ComposerSettings.DataParameters.Items.Find("UsersKind");
	ParameterUser     = ComposerSettings.DataParameters.Items.Find("User");
	
	If ParameterUser.Use
	   And Not ValueIsFilled(ParameterUser.Value) Then
		
		ParameterUser.Use = False;
	EndIf;
	
	If ParameterUser.Use Then
		ParameterUserType.Use = False;
	EndIf;
	
	SetPrivilegedMode(True);
	
	RightsSettings = RightsSettingsOnObjects();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ComposerSettings, DetailsData);
	
	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("UsersRights",      UsersRights());
	ExternalDataSets.Insert("RightsSettingsOnObjects", RightsSettings.RightsSettingsOnObjects);
	ExternalDataSets.Insert("SettingsRightsHierarchy",   RightsSettings.SettingsRightsHierarchy);
	ExternalDataSets.Insert("SettingsRightsLegend",    RightsSettings.SettingsRightsLegend);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
	FinishOutput(ResultDocument, DetailsData, RightsSettings);
	
EndProcedure

#EndRegion

#Region Private

Procedure FinishOutput(ResultDocument, DetailsData, RightsSettings)
	
	AccessGroupTitle = NStr("vi = 'Nhóm truy cập';
							|ru = 'Группа доступа';
							|en = 'Access group'; fa = 'گروه دسترسی';
							|it = 'Gruppo d''accesso';
							|pl = 'Grupa dostępu';
							|tr = 'Erişim grubu'");
	If AccessManagementInternal.SimplifiedAccessRightsSetupInterface() Then
		AccessGroupTitle = NStr("vi = 'Hồ sơ của người sử dụng';
								|ru = 'Профиль пользователя';
								|en = 'User profile'; fa = 'User profile';
								|it = 'Profilo dell''utente';
								|pl = 'Profil użytkownika';
								|tr = 'Kullanıcı profili'");
	EndIf;
	
	// ACC:163-off - #598.1. The use is permissible, as it affects the meaning.
	TextIsRestriction  = ?(ObjectRightsOption(), "", NStr("vi = 'Có hạn chế';
															|ru = 'Есть ограничение';
															|en = 'Has restriction'; fa = 'دارای محدودیت است';
															|it = 'Vi è una limitazione';
															|pl = 'Istnieje ograniczenie';
															|tr = 'Sınır var'"));
	// ACC:163-on
	TextRightNotAssigned = NStr("vi = '●';
								|ru = '●';
								|en = '●'; fa = '●';
								|it = '●';
								|pl = '●';
								|tr = '●'");
	TextRightAllowed   = NStr("vi = '✔';
								|ru = '✔';
								|en = '✔'; fa = '✔';
								|it = '✔';
								|pl = '✔';
								|tr = '✔'");
	TextRightForbidden   = NStr("vi = '✘';
								|ru = '✘';
								|en = '✘'; fa = '✘';
								|it = '✘';
								|pl = '✘';
								|tr = '✘'");
	FontRightNotAssigned = Undefined;
	FontRightAllowed   = Undefined;
	FontRightForbidden   = Undefined;
	ColorRightNotAssigned  = Metadata.StyleItems.UnassignedAccessRightColor.Value;
	ColorRightAllowed    = Metadata.StyleItems.AllowedAccessRightColor.Value;
	ColorRightForbidden    = Metadata.StyleItems.DeniedAccessRightColor.Value;
	ColorRightComputed  = Metadata.StyleItems.CalculatedAccessRightColor.Value;
	StringExplanations   = New Map;
	TranscribeColumns = New Map;
	SetRightForSubfolders = DescriptionColumnsForSubfolders().Title;
	None = New Line(SpreadsheetDocumentCellLineType.None);
	DataCompositionDecryptionIdentifierType = Type("DataCompositionDetailsID");
	TableHeight = ResultDocument.TableHeight;
	TableWidth = ResultDocument.TableWidth;
	
	For LineNumber = 1 To TableHeight Do
		For ColumnNumber = 1 To TableWidth Do
			Area = ResultDocument.Area(LineNumber, ColumnNumber);
			
			Details = Area.Details;
			If TypeOf(Details) <> DataCompositionDecryptionIdentifierType Then
				AreaText = Area.Text;
				
				If AreaText = "*" Then
					Area.Text = "";
					Area.Comment.Text = TextIsRestriction;
					
				ElsIf AreaText = "&AccessGroupTitle" Then
					Area.Text = AccessGroupTitle;
					
				ElsIf AreaText = "&OwnerSettingsHeader" Then
					Area.Text = RightsSettings.OwnerSettingsHeader;
				EndIf;
				
				Continue;
			EndIf;
			
			FieldValues = DetailsData.Items[Details].GetFields();
			
			If FieldValues.Find("Right") <> Undefined
			   And FieldValues.Find("Right").Value > 0
			   And FieldValues.Find("RightUnlimited") <> Undefined
			   And FieldValues.Find("Right").Value
			     > FieldValues.Find("RightUnlimited").Value
			 Or FieldValues.Find("ViewRight") <> Undefined
			   And FieldValues.Find("ViewRight").Value = True
			   And FieldValues.Find("UnrestrictedReadRight").Value = False
			 Or FieldValues.Find("EditRight") <> Undefined
			   And FieldValues.Find("EditRight").Value = True
			   And FieldValues.Find("UnrestrictedUpdateRight").Value = False
			 Or FieldValues.Find("InteractiveAddRight") <> Undefined
			   And FieldValues.Find("InteractiveAddRight").Value = True
			   And FieldValues.Find("UnrestrictedAddRight").Value = False Then
				
				Area.Comment.Text = TextIsRestriction;
				
			ElsIf FieldValues.Find("RightsValue") <> Undefined Then
				RightsValue = FieldValues.Find("RightsValue").Value;
				If RightsValue = Null Then
					RightsValue = 0;
					ThisSettingsOwner = StringExplanations.Get(LineNumber).Find("ThisSettingsOwner").Value;
					CustomizedRight = TranscribeColumns.Get(ColumnNumber).Find("CustomizedRight").Value;
				Else
					ThisSettingsOwner = FieldValues.Find("ThisSettingsOwner").Value;
					If RightsValue = 0 Then
						CustomizedRight = FieldValues.Find("CustomizedRight").Value;
					EndIf;
				EndIf;
				If RightsValue = 0 Then
					If ThisSettingsOwner And CustomizedRight <> SetRightForSubfolders Then
						RightsValue = 2;
					ElsIf CustomizedRight <> SetRightForSubfolders Then
						Area.Text      = TextRightNotAssigned;
						Area.Font      = FontRightNotAssigned;
						Area.TextColor = ColorRightNotAssigned;
					EndIf;
				EndIf;
				If RightsValue = 1 Then
					Area.Text      = TextRightAllowed;
					Area.Font      = FontRightAllowed;
					Area.TextColor = ?(ThisSettingsOwner, ColorRightComputed, ColorRightAllowed);
					
				ElsIf RightsValue = 2 Then
					Area.Text      = TextRightForbidden;
					Area.Font      = FontRightForbidden;
					Area.TextColor = ?(ThisSettingsOwner, ColorRightComputed, ColorRightForbidden);
				EndIf;
				
			ElsIf FieldValues.Find("OwnerOrUserSettings") <> Undefined Then
				StringExplanations.Insert(LineNumber, FieldValues);
				If FontRightNotAssigned = Undefined Then
					FontRightNotAssigned = Area.Font;
					// ACC:1345-off - The current font is used, enlarged to 120% and italicized to highlight the symbols "✔" and "✘", but not the symbol "●".
					FontRightAllowed   = New Font(FontRightNotAssigned,,, True,,,, 120);
					FontRightForbidden   = FontRightAllowed;
					// ACC:1345-on
				EndIf;
				Indent = (FieldValues.Find("Level").Value - 1) * 2;
				RowArea = ResultDocument.Area(LineNumber, , LineNumber);
				RowArea.CreateFormatOfRows();
				AreaOnRight = ResultDocument.Area(LineNumber, ColumnNumber);
				AreaLeft  = ResultDocument.Area(LineNumber, ColumnNumber - 1);
				AreaOnRight.LeftBorder = None;
				AreaLeft.RightBorder = None;
				AreaOnRight.ColumnWidth = Area.ColumnWidth + AreaLeft.ColumnWidth - Indent;
				AreaLeft.ColumnWidth = Indent;
				
			ElsIf FieldValues.Find("CustomizedRight") <> Undefined Then
				TranscribeColumns.Insert(ColumnNumber, FieldValues);
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

// Intended for procedure "BeforeImportSettingsToComposer".
Procedure HideExcessDataFields(Variant, DCSettings, DCUserSettings)
	
	UsersRights = New Array;
	
	If Variant = "UsersRightsToObject" Then
		UsersRights.Add("DataElement");
	Else
		UsersRights.Add("MetadataObject");
	EndIf;
	UsersRights.Add("User");
	UsersRights.Add("CanSignIn");
	UsersRights.Add("Right");
	UsersRights.Add("RightUnlimited");
	UsersRights.Add("InteractiveRight");
	
	If Variant = "AccessRightsAnalysis"
	   And ParameterValueFromSetting(DCUserSettings, "OutputGroup") = 1
	 Or Variant = "UsersRightsToReportTables"
	 Or Variant = "UserRightsToReportTables"
	 Or Variant = "UserRightsToReportsTables" Then
		
		UsersRights.Add("Report");
		UsersRights.Add("ReportRight");
	EndIf;
	
	If Variant = "UsersRightsToTable"
	 Or Variant = "UserRightsToTable"
	 Or Variant = "UsersRightsToObject" Then
		
		UsersRights.Add("ReadRight");
		UsersRights.Add("RightUpdate");
		If Variant <> "UsersRightsToObject" Then
			UsersRights.Add("AddRight");
		EndIf;
		UsersRights.Add("UnrestrictedReadRight");
		UsersRights.Add("UnrestrictedUpdateRight");
		If Variant <> "UsersRightsToObject" Then
			UsersRights.Add("UnrestrictedAddRight");
		EndIf;
		UsersRights.Add("ViewRight");
		UsersRights.Add("EditRight");
		If Variant <> "UsersRightsToObject" Then
			UsersRights.Add("InteractiveAddRight");
		EndIf;
	EndIf;
	
	If Variant = "UserRightsToTable" Then
		UsersRights.Add("AccessKindRight");
		UsersRights.Add("AccessKindUnrestrictedRight");
		UsersRights.Add("AccessKindInteractiveRight");
		UsersRights.Add("AccessKindReadRight");
		UsersRights.Add("AccessKindRightUpdate");
		UsersRights.Add("AccessKindInsertRight");
		UsersRights.Add("AccessTypeRightReadUnlimited");
		UsersRights.Add("AccessTypeRightChangeWithoutRestriction");
		UsersRights.Add("AccessTypeRightAdditionWithoutRestriction");
		UsersRights.Add("AccessTypeRightView");
		UsersRights.Add("AccessTypeRightEditing");
		UsersRights.Add("AccessTypeRightInteractiveAdd");
	EndIf;
	
	If Variant = "UserRightsToTables"
	 Or Variant = "UserRightsToTable"
	 Or Variant = "UserRightsToReportTables"
	 Or Variant = "UserRightsToReportsTables"
	 Or Variant = "UsersRightsByAllowedValue" Then
		
		UsersRights.Add("AccessGroup");
	EndIf;
	
	If Variant = "UserRightsToTable"
	 Or Variant = "UsersRightsByAllowedValue" Then
		
		UsersRights.Add("AccessKind");
		If Variant = "UserRightsToTable" Then
			UsersRights.Add("AllAllowed");
		EndIf;
		UsersRights.Add("AccessValue");
	EndIf;
	
	OriginalScheme = GetTemplate("Template");
	CurrentSchema = DataCompositionSchema;
	
	HideDataFieldsExceptSpecified("UsersRights", UsersRights, OriginalScheme, CurrentSchema);
	
	RightsSettings = New Array;
	
	If Variant = "UserRightsToTable" Then
		If Not VariantWithRestrictedAccess()
		 Or SettingsRightsByTableInselection(DCSettings, DCUserSettings) <> Undefined Then
			RightsSettings = "*";
		EndIf;
		Groups = New Map;
		Groups.Insert("RightsSettings",                  RightsSettings = "*");
		Groups.Insert("LegendSettingsRights",            RightsSettings = "*");
		Groups.Insert("OptionalTableTitle", RightsSettings = "*");
		SetGroupingsUsage(Groups, DCSettings, DCUserSettings);
	EndIf;
	
	HideDataFieldsExceptSpecified("RightsSettingsOnObjects", RightsSettings, OriginalScheme, CurrentSchema);
	HideDataFieldsExceptSpecified("SettingsRightsLegend",    RightsSettings, OriginalScheme, CurrentSchema);
	HideDataFieldsExceptSpecified("SettingsRightsHierarchy",   RightsSettings, OriginalScheme, CurrentSchema);
	
EndProcedure

// Intended for procedure "HideExcessDataFields".
Procedure HideDataFieldsExceptSpecified(DataSetName, DataPaths, OriginalScheme, CurrentSchema)
	
	Reports.AccessRightsAnalysis.HideDataFieldsExceptSpecified(DataSetName,
		DataPaths, OriginalScheme, CurrentSchema);
	
EndProcedure

// Intended for procedure "BeforeImportSettingsToComposer".
Procedure SetAvailableValuesForAccessKindField(Variant, DCSettings, DCUserSettings)
	
	DataField = DataCompositionSchema.DataSets.UsersRights.Fields.Find("AccessKind");
	ValueOfField = New ValueList;
	
	If Variant = "UserRightsToTable" Then
		AccessKindsPresentation = AccessManagementInternal.AccessKindsPresentation();
		For Each KeyAndValue In AccessKindsPresentation Do
			ValueOfField.Add(KeyAndValue.Key, KeyAndValue.Value);
		EndDo;
	Else
		ValueOfField.Add(Undefined);
	EndIf;
	
	DataField.SetAvailableValues(ValueOfField);
	
EndProcedure

// Intended for procedure "BeforeImportSettingsToComposer".
Procedure ConfigureAccessRightsAnalysisOption(DCSettings, DCUserSettings)
	
	ParameterOutput = DataCompositionSchema.Parameters.OutputGroup;
	ParameterOutput.UseRestriction = False;
	
	Values = New ValueList;
	Values.Add(0, NStr("vi = 'Bảng';
						|ru = 'Таблицы';
						|en = 'Tables'; fa = 'جدول‌ها';
						|it = 'Tables';
						|pl = 'Tables';
						|tr = 'Tablolar'"));
	Values.Add(1, NStr("vi = 'Báo cáo với bảng';
						|ru = 'Отчеты с таблицами';
						|en = 'Reports with tables'; fa = 'Reports with tables';
						|it = 'Reports with tables';
						|pl = 'Reports with tables';
						|tr = 'Tablo içeren raporlar'"));
	ParameterOutput.SetAvailableValues(Values);
	ParameterOutput.Value = 0;
	
	Value = ParameterValueFromSetting(DCUserSettings, ParameterOutput.Name);
	If Value <> Undefined Then
		Groups = New Map;
		Groups.Insert("GroupingByTables",        Value = 0);
		Groups.Insert("GroupingByReportTables", Value = 1);
		SetGroupingsUsage(Groups, DCSettings, DCUserSettings);
	EndIf;
	
EndProcedure

// Intended for procedure "BeforeImportSettingsToComposer".
Procedure ConfigureUsersRightsToObjectOption(DCSettings, DCUserSettings)
	
	DataField = DataCompositionSchema.DataSets.UsersRights.Fields.Find("Right");
	ValueOfField = New ValueList;
	ValueOfField.Add(1, NStr("vi = 'Đọc';
							|ru = 'Чтение';
							|en = 'Read'; fa = 'خوانده‌شده';
							|it = 'Lettura';
							|pl = 'Read';
							|tr = 'Okuma'"));
	ValueOfField.Add(2, NStr("vi = 'Thay đổi';
							|ru = 'Изменение';
							|en = 'Update'; fa = 'به‌روزرسانی';
							|it = 'Modifica';
							|pl = 'Update';
							|tr = 'Değiştir'"));
	DataField.SetAvailableValues(ValueOfField);
	
	DataField = DataCompositionSchema.DataSets.UsersRights.Fields.Find("InteractiveRight");
	ValueOfField = New ValueList;
	ValueOfField.Add(1, NStr("vi = 'Xem';
							|ru = 'Просмотр';
							|en = 'View'; fa = 'مشاهده';
							|it = 'Visualizzazione';
							|pl = 'Przegląd';
							|tr = 'Görüntüle'"));
	ValueOfField.Add(2, NStr("vi = 'Chỉnh sửa';
							|ru = 'Редактирование';
							|en = 'Edit'; fa = 'ویرایش';
							|it = 'Modifica';
							|pl = 'Edycja';
							|tr = 'Düzenle'"));
	DataField.SetAvailableValues(ValueOfField);
	
	Parameter = DataCompositionSchema.Parameters.DataElement;
	Parameter.UseRestriction = False;
	Parameter.Use = DataCompositionParameterUse.Always;
	Parameter.ValueType = AccessManagementInternalCached.DataElementsTypes();
	
	DataCompositionSchema.Parameters.Delete(Parameter);
	DataCompositionSchema.Parameters.Insert(0);
	FillPropertyValues(DataCompositionSchema.Parameters[0], Parameter);
	
EndProcedure

// Intended for procedure "BeforeImportSettingsToComposer".
Procedure ConfigureUsersRightsByAllowedValueOption(DCSettings, DCUserSettings)
	
	Parameter = DataCompositionSchema.Parameters.AccessValue;
	Parameter.UseRestriction = False;
	Parameter.Use = DataCompositionParameterUse.Always;
	Parameter.ValueType = Reports.AccessRightsAnalysis.DetailsOfAccessKindGroupAndValueTypes();
	
	DataCompositionSchema.Parameters.Delete(Parameter);
	DataCompositionSchema.Parameters.Insert(1);
	FillPropertyValues(DataCompositionSchema.Parameters[1], Parameter);
	
	ParameterOutput = DataCompositionSchema.Parameters.OutputGroup;
	ParameterOutput.UseRestriction = False;
	
	SimplifiedInterface = AccessManagementInternal.SimplifiedAccessRightsSetupInterface();
	
	Values = New ValueList;
	Values.Add(0, NStr("vi = 'Bảng với quyền của người sử dụng';
						|ru = 'Таблицы с правами пользователей';
						|en = 'Tables with user rights'; fa = 'Tables with user rights';
						|it = 'Tables with user rights';
						|pl = 'Tables with user rights';
						|tr = 'Kullanıcı haklarını içeren tablolar'"));
	Values.Add(1, NStr("vi = 'Người sử dụng';
						|ru = 'Пользователей';
						|en = 'Users'; fa = 'کاربران';
						|it = 'Users';
						|pl = 'Users';
						|tr = 'Kullanıcılar'"));
	Values.Add(2, ?(SimplifiedInterface,
		NStr("vi = 'Người sử dụng có hồ sơ';
			|ru = 'Пользователей с профилями';
			|en = 'User with profile count'; fa = 'User with profile count';
			|it = 'User with profile count';
			|pl = 'User with profile count';
			|tr = 'Profillerden kullanıcılar'"), NStr("vi = 'Người sử dụng với nhóm truy cập';
													|ru = 'Пользователей с группами доступа';
													|en = 'User with access group count'; fa = 'User with access group count';
													|it = 'User with access group count';
													|pl = 'User with access group count';
													|tr = 'Erişim gruplarından kullanıcılar'")));
	Values.Add(3, ?(SimplifiedInterface,
		NStr("vi = 'Hồ sơ có người sử dụng';
			|ru = 'Профили с пользователями';
			|en = 'Profiles with users'; fa = 'Profiles with users';
			|it = 'Profiles with users';
			|pl = 'Profiles with users';
			|tr = 'Kullanıcılar içeren profiller'"), NStr("vi = 'Nhóm truy cập có người sử dụng';
												|ru = 'Группы доступа с пользователями';
												|en = 'Access groups with users'; fa = 'Access groups with users';
												|it = 'Access groups with users';
												|pl = 'Access groups with users';
												|tr = 'Kullanıcılar içeren erişim grupları'")));
	Values.Add(4, ?(SimplifiedInterface,
		NStr("vi = 'Hồ sơ nhóm truy cập';
			|ru = 'Профили групп доступа';
			|en = 'Access group profiles'; fa = 'پروفایل‌های گروه دسترسی';
			|it = 'Profili dei gruppi di accesso';
			|pl = 'Profile grup dostępu';
			|tr = 'Erişim grubu profilleri'"), NStr("vi = 'Nhóm truy cập';
													|ru = 'Группы доступа';
													|en = 'Access groups'; fa = 'گروه‌های دسترسی';
													|it = 'Gruppi di accesso';
													|pl = 'Grupy dostępu';
													|tr = 'Erişim grupları'")));
	Values.Add(5, ?(SimplifiedInterface,
		NStr("vi = 'Bảng có quyền của hồ sơ';
			|ru = 'Таблицы с правами профилей';
			|en = 'Tables with profile rights'; fa = 'Tables with profile rights';
			|it = 'Tables with profile rights';
			|pl = 'Tables with profile rights';
			|tr = 'Profil haklarını içeren tablolar'"), NStr("vi = 'Bảng có quyền của nhóm truy cập';
														|ru = 'Таблицы с правами групп доступа';
														|en = 'Tables with access group rights'; fa = 'Tables with access group rights';
														|it = 'Tables with access group rights';
														|pl = 'Tables with access group rights';
														|tr = 'Erişim grubu haklarını içeren tablolar'")));
	ParameterOutput.SetAvailableValues(Values);
	ParameterOutput.Value = 0;
	
	Value = ParameterValueFromSetting(DCUserSettings, ParameterOutput.Name);
	If Value <> Undefined Then
		Groups = New Map;
		Groups.Insert("TablesWithUsersRights", Value = 0);
		Groups.Insert("Users",                 Value = 1);
		Groups.Insert("UsersWithAccessGroups", Value = 2);
		Groups.Insert("AccessGroupsWithUsers", Value = 3);
		Groups.Insert("AccessGroups",                Value = 4);
		Groups.Insert("TablesWithAccessGroupsRights",  Value = 5);
		Groups.Insert("Legend",                      Value = 0 Or Value = 5);
		SetGroupingsUsage(Groups, DCSettings, DCUserSettings);
	EndIf;
	
EndProcedure

// Intended for procedure "BeforeImportSettingsToComposer".
Procedure ConfigureContextOpeningParameters(Context, Variant, DCSettings, DCUserSettings)
	
	If Variant = "UsersRightsToTable"
	 Or Variant = "UserRightsToTable" Then
		
		MetadataObject = Common.MetadataObjectID(Context.OptionContext, False);
		If ValueIsFilled(MetadataObject) Then
			CommonClientServer.SetFilterItem(DCSettings.Filter, "MetadataObject", MetadataObject,
				DataCompositionComparisonType.Equal, , True);
		EndIf;
		
	ElsIf Variant = "UsersRightsToTables" Or Variant = "UserRightsToTables" Then
		If Context.Parameters.Property("CommandParameter") Then
			UsersList = New ValueList;
			UsersList.LoadValues(Context.Parameters.CommandParameter);
			UsersInternal.SetFilterOnParameter("User", UsersList,
				DCSettings, DCUserSettings);
		EndIf;
		
	ElsIf Variant = "UsersRightsToObject" Then
		If Context.Parameters.Property("CommandParameter") Then
			UsersInternal.SetFilterOnParameter("DataElement",
				Context.Parameters.CommandParameter,
				DCSettings,
				DCUserSettings);
		EndIf;
		
	ElsIf Variant = "UsersRightsByAllowedValue" Then
		If Context.Parameters.Property("CommandParameter") Then
			UsersInternal.SetFilterOnParameter("AccessValue",
				Context.Parameters.CommandParameter,
				DCSettings,
				DCUserSettings);
		EndIf;
	EndIf;
	
EndProcedure

Function ReportsTables()
	
	Result = BlankReportsTablesCollection();
	DescriptionOfIDTypes = DescriptionOfIDTypes();
	
	SelectedReport = SelectedReport();
	TablesToUse = Undefined;
	
	If ValueIsFilled(SelectedReport)
		And SettingsComposer.UserSettings.AdditionalProperties.Property("TablesToUse", TablesToUse)
		And TablesToUse <> Undefined Then 
		
		MetadataObjectIDs =
			Common.MetadataObjectIDs(TablesToUse, False);
		
		For Each Table In TablesToUse Do
			TableID = MetadataObjectIDs[Table];
			TableRow = Result.Add();
			TableRow.Report = SelectedReport;
			TableRow.MetadataObject = TableID;
		EndDo;
		
		If Not ValueIsFilled(Result) Then
			TableRow = Result.Add();
			TableRow.Report = SelectedReport;
			TableRow.MetadataObject = Undefined;
		EndIf;
		
		Return Result;
		
	EndIf;
	
	If ValueIsFilled(SelectedReport)
	   And DescriptionOfIDTypes.ContainsType(TypeOf(SelectedReport)) Then
		
		TheMetadataObjectOfTheSelectedReport =
			Common.MetadataObjectByID(SelectedReport, False);
	EndIf;
	
	ReportsTables = New ValueTable;
	ReportsTables.Columns.Add("Report");
	ReportsTables.Columns.Add("MetadataObject");
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		ModuleReportsOptions = Common.CommonModule("ReportsOptions");
		TablesOwners = New Map;
		For Each MetadataObjectReport In Metadata.Reports Do
			If TypeOf(TheMetadataObjectOfTheSelectedReport) = Type("MetadataObject")
			   And MetadataObjectReport <> TheMetadataObjectOfTheSelectedReport Then
				Continue;
			EndIf;
			If Not AccessRight("View", MetadataObjectReport) Then
				Continue;
			EndIf;
			TablesToUse = ModuleReportsOptions.UsedReportTables(MetadataObjectReport);
			
			For Each TableName In TablesToUse Do
				AssociatedTable = TablesOwners[TableName];
				If AssociatedTable = Undefined Then
					TableOwner = TableName;
					StringParts1 = StrSplit(TableOwner, ".", True);
					If StringParts1.Count() = 1 Then
						Continue;
					EndIf;
					If StringParts1.Count() > 2 Then
						TableOwner = StringParts1[0] + "." + StringParts1[1];
					EndIf;
					TablesOwners.Insert(TableName, TableOwner);
					AssociatedTable = TableOwner;
				EndIf;
				
				TableRow = ReportsTables.Add();
				TableRow.Report = MetadataObjectReport.FullName();
				TableRow.MetadataObject = AssociatedTable;
			EndDo;
		EndDo;
		ReportsTables.GroupBy("Report, MetadataObject");
	EndIf;
	
	MetadataObjectNames = ReportsTables.UnloadColumn("MetadataObject");
	ReportsWithTables = New Map;
	For Each MetadataObjectReport In Metadata.Reports Do
		If TypeOf(TheMetadataObjectOfTheSelectedReport) = Type("MetadataObject")
		   And MetadataObjectReport <> TheMetadataObjectOfTheSelectedReport Then
			Continue;
		EndIf;
		FullReportName = MetadataObjectReport.FullName();
		ReportsWithTables.Insert(FullReportName, False);
		MetadataObjectNames.Add(FullReportName);
	EndDo;
	
	MetadataObjectIDs =
		Common.MetadataObjectIDs(MetadataObjectNames, False);
	
	For Each TableRow In ReportsTables Do
		TableID = MetadataObjectIDs[TableRow.MetadataObject];
		If Not ValueIsFilled(TableID) Then
			Continue;
		EndIf;
		NewRow = Result.Add();
		NewRow.Report            = MetadataObjectIDs[TableRow.Report];
		NewRow.MetadataObject = TableID;
		ReportsWithTables.Insert(TableRow.Report, True);
	EndDo;
	
	For Each KeyAndValue In ReportsWithTables Do
		If KeyAndValue.Value Then
			Continue;
		EndIf;
		NewRow = Result.Add();
		NewRow.Report = MetadataObjectIDs[KeyAndValue.Key];
		NewRow.MetadataObject = Undefined;
	EndDo;
	
	Return Result;
	
EndFunction

Function DescriptionOfIDTypes()
	
	Return New TypeDescription("CatalogRef.MetadataObjectIDs,
		|CatalogRef.ExtensionObjectIDs");
	
EndFunction

Function BlankReportsTablesCollection()
	
	DescriptionOfIDTypes = DescriptionOfIDTypes();
	
	Result = New ValueTable;
	Result.Columns.Add("Report", DescriptionOfIDTypes);
	Result.Columns.Add("MetadataObject", DescriptionOfIDTypes);
	
	Return Result;
	
EndFunction

Function RolesRightsToReports()
	
	Result = EmptyCollectionOfRoleRightsToReports();
	DescriptionOfIDTypes = DescriptionOfIDTypes();
	
	SelectedReport = SelectedReport();
	
	If ValueIsFilled(SelectedReport)
	   And DescriptionOfIDTypes.ContainsType(TypeOf(SelectedReport)) Then
		
		TheMetadataObjectOfTheSelectedReport =
			Common.MetadataObjectByID(SelectedReport, False);
	EndIf;
	
	MetadataObjectNames = New Array;
	For Each MetadataObjectRole In Metadata.Roles Do
		MetadataObjectNames.Add(MetadataObjectRole.FullName());
	EndDo;
	For Each MetadataObjectReport In Metadata.Reports Do
		If TypeOf(TheMetadataObjectOfTheSelectedReport) = Type("MetadataObject")
		   And MetadataObjectReport <> TheMetadataObjectOfTheSelectedReport Then
			Continue;
		EndIf;
		MetadataObjectNames.Add(MetadataObjectReport.FullName());
	EndDo;
	
	MetadataObjectIDs =
		Common.MetadataObjectIDs(MetadataObjectNames, False);
	
	For Each MetadataObjectReport In Metadata.Reports Do
		If TypeOf(TheMetadataObjectOfTheSelectedReport) = Type("MetadataObject")
		   And MetadataObjectReport <> TheMetadataObjectOfTheSelectedReport Then
			Continue;
		EndIf;
		For Each MetadataObjectRole In Metadata.Roles Do
			If AccessRight("View", MetadataObjectReport, MetadataObjectRole) Then
				TableRow = Result.Add();
				TableRow.Report = MetadataObjectIDs[MetadataObjectReport.FullName()];
				TableRow.Role  = MetadataObjectIDs[MetadataObjectRole.FullName()];
			EndIf;
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

Function EmptyCollectionOfRoleRightsToReports()
	
	DescriptionOfIDTypes = DescriptionOfIDTypes();
	
	Result = New ValueTable;
	Result.Columns.Add("Report", DescriptionOfIDTypes);
	Result.Columns.Add("Role", DescriptionOfIDTypes);
	
	Return Result;
	
EndFunction

Function QueryTextShared()
	
	QueryText =
	"SELECT
	|	RolesRights.MetadataObject AS MetadataObject,
	|	RolesRights.Role AS Role,
	|	RolesRights.RightUpdate AS RightUpdate,
	|	RolesRights.AddRight AS AddRight,
	|	RolesRights.UnrestrictedReadRight AS UnrestrictedReadRight,
	|	RolesRights.UnrestrictedUpdateRight AS UnrestrictedUpdateRight,
	|	RolesRights.UnrestrictedAddRight AS UnrestrictedAddRight,
	|	RolesRights.ViewRight AS ViewRight,
	|	RolesRights.EditRight AS EditRight,
	|	RolesRights.InteractiveAddRight AS InteractiveAddRight,
	|	RolesRights.LineChangeType AS LineChangeType
	|INTO ExtensionsRolesRights
	|FROM
	|	&ExtensionsRolesRights AS RolesRights
	|WHERE
	|	&SelectingRightsByTables
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExtensionsRolesRights.MetadataObject AS MetadataObject,
	|	ExtensionsRolesRights.Role AS Role,
	|	TRUE AS ReadRight,
	|	ExtensionsRolesRights.RightUpdate AS RightUpdate,
	|	ExtensionsRolesRights.AddRight AS AddRight,
	|	ExtensionsRolesRights.UnrestrictedReadRight AS UnrestrictedReadRight,
	|	ExtensionsRolesRights.UnrestrictedUpdateRight AS UnrestrictedUpdateRight,
	|	ExtensionsRolesRights.UnrestrictedAddRight AS UnrestrictedAddRight,
	|	ExtensionsRolesRights.ViewRight AS ViewRight,
	|	ExtensionsRolesRights.EditRight AS EditRight,
	|	ExtensionsRolesRights.InteractiveAddRight AS InteractiveAddRight
	|INTO RolesRights
	|FROM
	|	ExtensionsRolesRights AS ExtensionsRolesRights
	|WHERE
	|	ExtensionsRolesRights.LineChangeType = 1
	|
	|UNION ALL
	|
	|SELECT
	|	RolesRights.MetadataObject,
	|	RolesRights.Role,
	|	TRUE,
	|	RolesRights.RightUpdate,
	|	RolesRights.AddRight,
	|	RolesRights.UnrestrictedReadRight,
	|	RolesRights.UnrestrictedUpdateRight,
	|	RolesRights.UnrestrictedAddRight,
	|	RolesRights.ViewRight,
	|	RolesRights.EditRight,
	|	RolesRights.InteractiveAddRight
	|FROM
	|	InformationRegister.RolesRights AS RolesRights
	|		LEFT JOIN ExtensionsRolesRights AS ExtensionsRolesRights
	|		ON RolesRights.MetadataObject = ExtensionsRolesRights.MetadataObject
	|			AND RolesRights.Role = ExtensionsRolesRights.Role
	|WHERE
	|	ExtensionsRolesRights.MetadataObject IS NULL
	|	AND &SelectingRightsByTables
	|
	|INDEX BY
	|	Role
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccessGroupProfilesRoles.Ref AS Profile,
	|	RolesRights.MetadataObject AS Table,
	|	MAX(RolesRights.ReadRight) AS ReadRight,
	|	MAX(RolesRights.RightUpdate) AS RightUpdate,
	|	MAX(RolesRights.AddRight) AS AddRight,
	|	MAX(RolesRights.UnrestrictedReadRight) AS UnrestrictedReadRight,
	|	MAX(RolesRights.UnrestrictedUpdateRight) AS UnrestrictedUpdateRight,
	|	MAX(RolesRights.UnrestrictedAddRight) AS UnrestrictedAddRight,
	|	MAX(RolesRights.ViewRight) AS ViewRight,
	|	MAX(RolesRights.EditRight) AS EditRight,
	|	MAX(RolesRights.InteractiveAddRight) AS InteractiveAddRight
	|INTO RightsOfProfilesToTables
	|FROM
	|	RolesRights AS RolesRights
	|		INNER JOIN Catalog.AccessGroupProfiles.Roles AS AccessGroupProfilesRoles
	|		ON RolesRights.Role = AccessGroupProfilesRoles.Role
	|			AND (NOT AccessGroupProfilesRoles.Ref.DeletionMark)
	|
	|GROUP BY
	|	AccessGroupProfilesRoles.Ref,
	|	RolesRights.MetadataObject
	|
	|INDEX BY
	|	Table";
	
	If AccessManagementInternal.IsRecordLevelRestrictionDisabled() Then
		QueryText = StrReplace(QueryText,
			"MAX(RolesRights.UnrestrictedReadRight)",     // @query-part-1
			"MAX(RolesRights.ReadRight)");                  // @query-part-1
		QueryText = StrReplace(QueryText,
			"MAX(RolesRights.UnrestrictedUpdateRight)",  // @query-part-1
			"MAX(RolesRights.RightUpdate)");               // @query-part-1
		QueryText = StrReplace(QueryText,
			"MAX(RolesRights.UnrestrictedAddRight)", // @query-part-1
			"MAX(RolesRights.AddRight)");              // @query-part-1
	EndIf;
	
	Return QueryText;
	
EndFunction

Function RequestTextWithoutGroupingByReports()
	
	Return
	"SELECT DISTINCT
	|	ProfilesRights.Table AS MetadataObject,
	|	CASE
	|		WHEN &SimplifiedAccessRightsSetupInterface
	|			THEN AccessGroups.Profile
	|		ELSE AccessGroups.Ref
	|	END AS AccessGroup,
	|	ProfilesRights.ReadRight AS ReadRight,
	|	ProfilesRights.RightUpdate AS RightUpdate,
	|	ProfilesRights.AddRight AS AddRight,
	|	CASE
	|		WHEN ProfilesRights.AddRight
	|			THEN 3
	|		WHEN ProfilesRights.RightUpdate
	|			THEN 2
	|		WHEN ProfilesRights.ReadRight
	|			THEN 1
	|		ELSE 0
	|	END AS Right,
	|	ProfilesRights.UnrestrictedReadRight AS UnrestrictedReadRight,
	|	ProfilesRights.UnrestrictedUpdateRight AS UnrestrictedUpdateRight,
	|	ProfilesRights.UnrestrictedAddRight AS UnrestrictedAddRight,
	|	CASE
	|		WHEN ProfilesRights.UnrestrictedAddRight
	|			THEN 3
	|		WHEN ProfilesRights.UnrestrictedUpdateRight
	|			THEN 2
	|		WHEN ProfilesRights.UnrestrictedReadRight
	|			THEN 1
	|		ELSE 0
	|	END AS RightUnlimited,
	|	ProfilesRights.ViewRight AS ViewRight,
	|	ProfilesRights.EditRight AS EditRight,
	|	ProfilesRights.InteractiveAddRight AS InteractiveAddRight,
	|	CASE
	|		WHEN ProfilesRights.InteractiveAddRight
	|			THEN 3
	|		WHEN ProfilesRights.EditRight
	|			THEN 2
	|		WHEN ProfilesRights.ViewRight
	|			THEN 1
	|		ELSE 0
	|	END AS InteractiveRight,
	|	UserGroupCompositions.User AS User,
	|	ISNULL(UsersInfo.CanSignIn, FALSE) AS CanSignIn
	|FROM
	|	RightsOfProfilesToTables AS ProfilesRights
	|		INNER JOIN Catalog.AccessGroups AS AccessGroups
	|		ON (AccessGroups.Profile = ProfilesRights.Profile)
	|			AND (NOT AccessGroups.DeletionMark)
	|		INNER JOIN Catalog.AccessGroups.Users AS AccessGroupsMembers
	|		ON (AccessGroupsMembers.Ref = AccessGroups.Ref)
	|		INNER JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|		ON (UserGroupCompositions.UsersGroup = AccessGroupsMembers.User)
	|			AND (ISNULL(UserGroupCompositions.User.IsInternal, FALSE) <> TRUE)
	|			AND (&SelectionCriteriaForUsers)
	|		LEFT JOIN InformationRegister.UsersInfo AS UsersInfo
	|		ON (UsersInfo.User = UserGroupCompositions.User)";
	
EndFunction

Function QueryTextForObjectRights()
	
	Return
	"SELECT
	|	RightsToDataElement.UserWithRight AS User,
	|	RightsToDataElement.RightUpdate AS RightUpdate
	|INTO RightsToDataElement
	|FROM
	|	&RightsToDataElement AS RightsToDataElement
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ProfilesRights.Table AS MetadataObject,
	|	VALUE(Catalog.AccessGroups.EmptyRef) AS AccessGroup,
	|	ProfilesRights.ReadRight AS ReadRight,
	|	ProfilesRights.RightUpdate
	|		AND RightsToDataElement.RightUpdate AS RightUpdate,
	|	FALSE AS AddRight,
	|	CASE
	|		WHEN ProfilesRights.RightUpdate AND RightsToDataElement.RightUpdate
	|			THEN 2
	|		WHEN ProfilesRights.ReadRight
	|			THEN 1
	|		ELSE 0
	|	END AS Right,
	|	ProfilesRights.UnrestrictedReadRight AS UnrestrictedReadRight,
	|	ProfilesRights.UnrestrictedUpdateRight AS UnrestrictedUpdateRight,
	|	FALSE AS UnrestrictedAddRight,
	|	CASE
	|		WHEN ProfilesRights.UnrestrictedUpdateRight
	|			THEN 2
	|		WHEN ProfilesRights.UnrestrictedReadRight
	|			THEN 1
	|		ELSE 0
	|	END AS RightUnlimited,
	|	ProfilesRights.ViewRight AS ViewRight,
	|	ProfilesRights.EditRight
	|		AND RightsToDataElement.RightUpdate AS EditRight,
	|	FALSE AS InteractiveAddRight,
	|	CASE
	|		WHEN ProfilesRights.EditRight
	|				AND RightsToDataElement.RightUpdate
	|			THEN 2
	|		WHEN ProfilesRights.ViewRight
	|			THEN 1
	|		ELSE 0
	|	END AS InteractiveRight,
	|	UserGroupCompositions.User AS User,
	|	ISNULL(UsersInfo.CanSignIn, FALSE) AS CanSignIn
	|FROM
	|	RightsOfProfilesToTables AS ProfilesRights
	|		INNER JOIN Catalog.AccessGroups AS AccessGroups
	|		ON (AccessGroups.Profile = ProfilesRights.Profile)
	|			AND (NOT AccessGroups.DeletionMark)
	|		INNER JOIN Catalog.AccessGroups.Users AS AccessGroupsMembers
	|		ON (AccessGroupsMembers.Ref = AccessGroups.Ref)
	|		INNER JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|		ON (UserGroupCompositions.UsersGroup = AccessGroupsMembers.User)
	|			AND (ISNULL(UserGroupCompositions.User.IsInternal, FALSE) <> TRUE)
	|			AND (&SelectionCriteriaForUsers)
	|		INNER JOIN RightsToDataElement AS RightsToDataElement
	|		ON (RightsToDataElement.User = UserGroupCompositions.User)
	|		LEFT JOIN InformationRegister.UsersInfo AS UsersInfo
	|		ON (UsersInfo.User = UserGroupCompositions.User)";
	
EndFunction

Function QueryTextWithoutGroupingByReportsWithAccessRestrictionsStart()
	
	Return
	"SELECT
	|	AccessGroups.Profile AS Profile,
	|	AccessGroups.Ref AS AccessGroup
	|INTO UserAccessGroups
	|FROM
	|	Catalog.AccessGroups AS AccessGroups
	|		INNER JOIN Catalog.AccessGroups.Users AS AccessGroupsMembers
	|		ON (AccessGroupsMembers.Ref = AccessGroups.Ref)
	|			AND (NOT AccessGroups.DeletionMark)
	|			AND (AccessGroups.Profile IN
	|				(SELECT DISTINCT
	|					ProfilesRights.Profile
	|				FROM
	|					RightsOfProfilesToTables AS ProfilesRights))
	|		INNER JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|		ON (UserGroupCompositions.UsersGroup = AccessGroupsMembers.User)
	|			AND (ISNULL(UserGroupCompositions.User.IsInternal, FALSE) <> TRUE)
	|			AND (&SelectionCriteriaForUsers)";
	
EndFunction

Function QueryTextWithoutGroupingByReportsWithAccessRestrictions()
	
	Return
	"SELECT
	|	AccessRestrictionKinds.Table AS Table,
	|	AccessRestrictionKinds.Right AS Right,
	|	AccessRestrictionKinds.AccessKind AS AccessKind,
	|	AccessRestrictionKinds.Presentation AS AccessKindPresentation,
	|	AccessRestrictionKinds.IsAuthorizedUser AS IsAuthorizedUser
	|INTO TypesRestrictionsRightsInitial
	|FROM
	|	&AccessRestrictionKinds AS AccessRestrictionKinds
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccessRestrictionKinds.Table AS Table,
	|	AccessRestrictionKinds.AccessKind AS AccessKind,
	|	AccessRestrictionKinds.AccessKindPresentation AS AccessKindPresentation,
	|	AccessRestrictionKinds.IsAuthorizedUser AS IsAuthorizedUser,
	|	MAX(AccessRestrictionKinds.Right = ""Read"") AS ReadRight,
	|	MAX(AccessRestrictionKinds.Right = ""Update"") AS RightUpdate
	|INTO RightsRestrictionTypesTransformed
	|FROM
	|	TypesRestrictionsRightsInitial AS AccessRestrictionKinds
	|
	|GROUP BY
	|	AccessRestrictionKinds.Table,
	|	AccessRestrictionKinds.AccessKind,
	|	AccessRestrictionKinds.AccessKindPresentation,
	|	AccessRestrictionKinds.IsAuthorizedUser
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FALSE AS ForExternalUsers,
	|	AccessRestrictionKinds.Table AS Table,
	|	AccessRestrictionKinds.AccessKind AS AccessKind,
	|	AccessRestrictionKinds.AccessKindPresentation AS AccessKindPresentation,
	|	AccessRestrictionKinds.IsAuthorizedUser AS IsAuthorizedUser,
	|	AccessRestrictionKinds.ReadRight AS ReadRight,
	|	AccessRestrictionKinds.RightUpdate AS RightUpdate
	|INTO AccessRestrictionKinds
	|FROM
	|	RightsRestrictionTypesTransformed AS AccessRestrictionKinds
	|WHERE
	|	VALUETYPE(AccessRestrictionKinds.AccessKind) <> TYPE(Catalog.ExternalUsers)
	|
	|UNION ALL
	|
	|SELECT
	|	TRUE,
	|	AccessRestrictionKinds.Table,
	|	AccessRestrictionKinds.AccessKind,
	|	AccessRestrictionKinds.AccessKindPresentation,
	|	AccessRestrictionKinds.IsAuthorizedUser,
	|	AccessRestrictionKinds.ReadRight,
	|	AccessRestrictionKinds.RightUpdate
	|FROM
	|	RightsRestrictionTypesTransformed AS AccessRestrictionKinds
	|WHERE
	|	VALUETYPE(AccessRestrictionKinds.AccessKind) <> TYPE(Catalog.Users)";
	
EndFunction

Function QueryTextWithoutGroupingByReportsWithAccessRestrictionsRestrictionTypesNew()
	
	Return
	"SELECT
	|	AccessRestrictionKinds.ForExternalUsers AS ForExternalUsers,
	|	AccessRestrictionKinds.Table AS Table,
	|	AccessRestrictionKinds.Right AS Right,
	|	AccessRestrictionKinds.AccessKind AS AccessKind,
	|	AccessRestrictionKinds.Presentation AS AccessKindPresentation,
	|	AccessRestrictionKinds.IsAuthorizedUser AS IsAuthorizedUser
	|INTO TypesRestrictionsRightsInitial
	|FROM
	|	&AccessRestrictionKinds AS AccessRestrictionKinds
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccessRestrictionKinds.ForExternalUsers AS ForExternalUsers,
	|	AccessRestrictionKinds.Table AS Table,
	|	AccessRestrictionKinds.AccessKind AS AccessKind,
	|	AccessRestrictionKinds.AccessKindPresentation AS AccessKindPresentation,
	|	AccessRestrictionKinds.IsAuthorizedUser AS IsAuthorizedUser,
	|	MAX(AccessRestrictionKinds.Right = ""Read"") AS ReadRight,
	|	MAX(AccessRestrictionKinds.Right = ""Update"") AS RightUpdate
	|INTO AccessRestrictionKinds
	|FROM
	|	TypesRestrictionsRightsInitial AS AccessRestrictionKinds
	|
	|GROUP BY
	|	AccessRestrictionKinds.ForExternalUsers,
	|	AccessRestrictionKinds.Table,
	|	AccessRestrictionKinds.AccessKind,
	|	AccessRestrictionKinds.IsAuthorizedUser,
	|	AccessRestrictionKinds.AccessKindPresentation";
	
EndFunction

Function QueryTextWithoutGroupingByReportsWithAccessRestrictionsEnd()
	
	Return
	"SELECT DISTINCT
	|	AccessKindsAndValues.AccessGroup AS AccessGroup,
	|	AccessKindsAndValues.AccessKind AS AccessKind,
	|	AccessKindsAndValues.AllAllowed AS AllAllowed,
	|	AccessKindsAndValues.AccessValue AS AccessValue
	|INTO AccessKindsAndValues
	|FROM
	|	(SELECT
	|		UserAccessGroups.AccessGroup AS AccessGroup,
	|		AccessGroupsAccessKinds.AccessKind AS AccessKind,
	|		AccessGroupsAccessKinds.AllAllowed AS AllAllowed,
	|		ISNULL(AccessGroupsAccessValues.AccessValue, UNDEFINED) AS AccessValue
	|	FROM
	|		UserAccessGroups AS UserAccessGroups
	|			INNER JOIN Catalog.AccessGroups.AccessKinds AS AccessGroupsAccessKinds
	|			ON (AccessGroupsAccessKinds.Ref = UserAccessGroups.AccessGroup)
	|			LEFT JOIN Catalog.AccessGroups.AccessValues AS AccessGroupsAccessValues
	|			ON (AccessGroupsAccessValues.Ref = AccessGroupsAccessKinds.Ref)
	|				AND (AccessGroupsAccessValues.AccessKind = AccessGroupsAccessKinds.AccessKind)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		UserAccessGroups.AccessGroup,
	|		AccessGroupProfilesAccessKinds.AccessKind,
	|		AccessGroupProfilesAccessKinds.AllAllowed,
	|		ISNULL(AccessGroupProfilesAccessValues.AccessValue, UNDEFINED)
	|	FROM
	|		UserAccessGroups AS UserAccessGroups
	|			INNER JOIN Catalog.AccessGroupProfiles.AccessKinds AS AccessGroupProfilesAccessKinds
	|			ON (AccessGroupProfilesAccessKinds.Ref = UserAccessGroups.Profile)
	|			LEFT JOIN Catalog.AccessGroupProfiles.AccessValues AS AccessGroupProfilesAccessValues
	|			ON (AccessGroupProfilesAccessValues.Ref = AccessGroupProfilesAccessKinds.Ref)
	|				AND (AccessGroupProfilesAccessValues.AccessKind = AccessGroupProfilesAccessKinds.AccessKind)
	|	WHERE
	|		AccessGroupProfilesAccessKinds.Predefined
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		UserAccessGroups.AccessGroup,
	|		VALUE(Enum.AdditionalAccessValues.UNDEFINED),
	|		NULL,
	|		NULL
	|	FROM
	|		UserAccessGroups AS UserAccessGroups) AS AccessKindsAndValues
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	EmptyAccessValueReferences.EmptyRef AS EmptyRef,
	|	EmptyAccessValueReferences.Presentation AS Presentation
	|INTO EmptyAccessValueReferences
	|FROM
	|	&EmptyAccessValueReferences AS EmptyAccessValueReferences
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ProfilesRights.Table AS MetadataObject,
	|	CASE
	|		WHEN &SimplifiedAccessRightsSetupInterface
	|			THEN AccessGroups.Profile
	|		ELSE AccessGroups.Ref
	|	END AS AccessGroup,
	|	ProfilesRights.ReadRight AS ReadRight,
	|	ProfilesRights.RightUpdate AS RightUpdate,
	|	ProfilesRights.AddRight AS AddRight,
	|	CASE
	|		WHEN ProfilesRights.AddRight
	|			THEN 3
	|		WHEN ProfilesRights.RightUpdate
	|			THEN 2
	|		WHEN ProfilesRights.ReadRight
	|			THEN 1
	|		ELSE 0
	|	END AS Right,
	|	ProfilesRights.UnrestrictedReadRight AS UnrestrictedReadRight,
	|	ProfilesRights.UnrestrictedUpdateRight AS UnrestrictedUpdateRight,
	|	ProfilesRights.UnrestrictedAddRight AS UnrestrictedAddRight,
	|	CASE
	|		WHEN ProfilesRights.UnrestrictedAddRight
	|			THEN 3
	|		WHEN ProfilesRights.UnrestrictedUpdateRight
	|			THEN 2
	|		WHEN ProfilesRights.UnrestrictedReadRight
	|			THEN 1
	|		ELSE 0
	|	END AS RightUnlimited,
	|	ProfilesRights.ViewRight AS ViewRight,
	|	ProfilesRights.EditRight AS EditRight,
	|	ProfilesRights.InteractiveAddRight AS InteractiveAddRight,
	|	CASE
	|		WHEN ProfilesRights.InteractiveAddRight
	|			THEN 3
	|		WHEN ProfilesRights.EditRight
	|			THEN 2
	|		WHEN ProfilesRights.ViewRight
	|			THEN 1
	|		ELSE 0
	|	END AS InteractiveRight,
	|	ProfilesRights.ReadRight
	|		AND NOT ProfilesRights.UnrestrictedReadRight
	|		AND (ISNULL(AccessRestrictionKinds.ReadRight, FALSE)
	|			OR ISNULL(TypesRestrictionsPermissionsUnconditional.ReadRight, FALSE)
	|			OR AccessRestrictionKinds.AccessKind IS NULL
	|				AND TypesRestrictionsPermissionsUnconditional.AccessKind IS NULL) AS AccessKindReadRight,
	|	ProfilesRights.RightUpdate
	|		AND NOT ProfilesRights.UnrestrictedUpdateRight
	|		AND (ISNULL(AccessRestrictionKinds.RightUpdate, FALSE)
	|			OR ISNULL(TypesRestrictionsPermissionsUnconditional.RightUpdate, FALSE)
	|			OR AccessRestrictionKinds.AccessKind IS NULL
	|				AND TypesRestrictionsPermissionsUnconditional.AccessKind IS NULL) AS AccessKindRightUpdate,
	|	ProfilesRights.AddRight
	|		AND NOT ProfilesRights.UnrestrictedAddRight
	|		AND (ISNULL(AccessRestrictionKinds.RightUpdate, FALSE)
	|			OR ISNULL(TypesRestrictionsPermissionsUnconditional.RightUpdate, FALSE)
	|			OR AccessRestrictionKinds.AccessKind IS NULL
	|				AND TypesRestrictionsPermissionsUnconditional.AccessKind IS NULL) AS AccessKindInsertRight,
	|	CASE
	|		WHEN ProfilesRights.AddRight
	|				AND NOT ProfilesRights.UnrestrictedAddRight
	|				AND (ISNULL(AccessRestrictionKinds.RightUpdate, FALSE)
	|					OR ISNULL(TypesRestrictionsPermissionsUnconditional.RightUpdate, FALSE)
	|					OR AccessRestrictionKinds.AccessKind IS NULL
	|						AND TypesRestrictionsPermissionsUnconditional.AccessKind IS NULL)
	|			THEN 3
	|		WHEN ProfilesRights.RightUpdate
	|				AND NOT ProfilesRights.UnrestrictedUpdateRight
	|				AND (ISNULL(AccessRestrictionKinds.RightUpdate, FALSE)
	|					OR ISNULL(TypesRestrictionsPermissionsUnconditional.RightUpdate, FALSE)
	|					OR AccessRestrictionKinds.AccessKind IS NULL
	|						AND TypesRestrictionsPermissionsUnconditional.AccessKind IS NULL)
	|			THEN 2
	|		WHEN ProfilesRights.ReadRight
	|				AND NOT ProfilesRights.UnrestrictedReadRight
	|				AND (ISNULL(AccessRestrictionKinds.ReadRight, FALSE)
	|					OR ISNULL(TypesRestrictionsPermissionsUnconditional.ReadRight, FALSE)
	|					OR AccessRestrictionKinds.AccessKind IS NULL
	|						AND TypesRestrictionsPermissionsUnconditional.AccessKind IS NULL)
	|			THEN 1
	|		ELSE 0
	|	END AS AccessKindRight,
	|	FALSE AS AccessTypeRightReadUnlimited,
	|	FALSE AS AccessTypeRightChangeWithoutRestriction,
	|	FALSE AS AccessTypeRightAdditionWithoutRestriction,
	|	0 AS AccessKindUnrestrictedRight,
	|	ProfilesRights.ViewRight
	|		AND NOT ProfilesRights.UnrestrictedReadRight
	|		AND (ISNULL(AccessRestrictionKinds.ReadRight, FALSE)
	|			OR ISNULL(TypesRestrictionsPermissionsUnconditional.ReadRight, FALSE)
	|			OR AccessRestrictionKinds.AccessKind IS NULL
	|				AND TypesRestrictionsPermissionsUnconditional.AccessKind IS NULL) AS AccessTypeRightView,
	|	ProfilesRights.EditRight
	|		AND NOT ProfilesRights.UnrestrictedUpdateRight
	|		AND (ISNULL(AccessRestrictionKinds.RightUpdate, FALSE)
	|			OR ISNULL(TypesRestrictionsPermissionsUnconditional.RightUpdate, FALSE)
	|			OR AccessRestrictionKinds.AccessKind IS NULL
	|				AND TypesRestrictionsPermissionsUnconditional.AccessKind IS NULL) AS AccessTypeRightEditing,
	|	ProfilesRights.InteractiveAddRight
	|		AND NOT ProfilesRights.UnrestrictedAddRight
	|		AND (ISNULL(AccessRestrictionKinds.RightUpdate, FALSE)
	|			OR ISNULL(TypesRestrictionsPermissionsUnconditional.RightUpdate, FALSE)
	|			OR AccessRestrictionKinds.AccessKind IS NULL
	|				AND TypesRestrictionsPermissionsUnconditional.AccessKind IS NULL) AS AccessTypeRightInteractiveAdd,
	|	CASE
	|		WHEN ProfilesRights.InteractiveAddRight
	|				AND NOT ProfilesRights.UnrestrictedAddRight
	|				AND (ISNULL(AccessRestrictionKinds.RightUpdate, FALSE)
	|					OR ISNULL(TypesRestrictionsPermissionsUnconditional.RightUpdate, FALSE)
	|					OR AccessRestrictionKinds.AccessKind IS NULL
	|						AND TypesRestrictionsPermissionsUnconditional.AccessKind IS NULL)
	|			THEN 3
	|		WHEN ProfilesRights.EditRight
	|				AND NOT ProfilesRights.UnrestrictedUpdateRight
	|				AND (ISNULL(AccessRestrictionKinds.RightUpdate, FALSE)
	|					OR ISNULL(TypesRestrictionsPermissionsUnconditional.RightUpdate, FALSE)
	|					OR AccessRestrictionKinds.AccessKind IS NULL
	|						AND TypesRestrictionsPermissionsUnconditional.AccessKind IS NULL)
	|			THEN 2
	|		WHEN ProfilesRights.ViewRight
	|				AND NOT ProfilesRights.UnrestrictedReadRight
	|				AND (ISNULL(AccessRestrictionKinds.ReadRight, FALSE)
	|					OR ISNULL(TypesRestrictionsPermissionsUnconditional.ReadRight, FALSE)
	|					OR AccessRestrictionKinds.AccessKind IS NULL
	|						AND TypesRestrictionsPermissionsUnconditional.AccessKind IS NULL)
	|			THEN 1
	|		ELSE 0
	|	END AS AccessKindInteractiveRight,
	|	CASE
	|		WHEN NOT AccessRestrictionKinds.AccessKind IS NULL
	|			THEN AccessRestrictionKinds.AccessKind
	|		WHEN NOT TypesRestrictionsPermissionsUnconditional.AccessKind IS NULL
	|			THEN TypesRestrictionsPermissionsUnconditional.AccessKind
	|		ELSE UNDEFINED
	|	END AS AccessKind,
	|	CASE
	|		WHEN NOT(ProfilesRights.ReadRight
	|						AND NOT ProfilesRights.UnrestrictedReadRight
	|					OR ProfilesRights.RightUpdate
	|						AND NOT ProfilesRights.UnrestrictedUpdateRight
	|					OR ProfilesRights.AddRight
	|						AND NOT ProfilesRights.UnrestrictedAddRight)
	|			THEN &TextUnlimited
	|		WHEN NOT AccessRestrictionKinds.AccessKind IS NULL
	|			THEN AccessRestrictionKinds.AccessKindPresentation + CASE
	|					WHEN AccessKindsAndValues.AllAllowed IS NULL
	|						THEN """"
	|					WHEN AccessKindsAndValues.AllAllowed = FALSE
	|						THEN CASE
	|								WHEN VALUETYPE(AccessRestrictionKinds.AccessKind) = TYPE(Catalog.Users)
	|										OR VALUETYPE(AccessRestrictionKinds.AccessKind) = TYPE(Catalog.ExternalUsers)
	|									THEN &TextAllowedUsers
	|								ELSE &TextAllowed
	|							END
	|					ELSE CASE
	|							WHEN VALUETYPE(AccessRestrictionKinds.AccessKind) = TYPE(Catalog.Users)
	|									OR VALUETYPE(AccessRestrictionKinds.AccessKind) = TYPE(Catalog.ExternalUsers)
	|								THEN &TextForbiddenUsers
	|							ELSE &TextForbidden
	|						END
	|				END
	|		WHEN NOT TypesRestrictionsPermissionsUnconditional.AccessKind IS NULL
	|			THEN TypesRestrictionsPermissionsUnconditional.AccessKindPresentation
	|		ELSE CASE
	|				WHEN ProfilesRights.Table IN (&AllTablesWithRestriction)
	|					THEN &RestrictionDisabled
	|				ELSE &NonStandardRestriction
	|			END
	|	END AS AccessKindPresentation,
	|	ISNULL(AccessKindsAndValues.AllAllowed, FALSE) AS AllAllowed,
	|	CASE
	|		WHEN AccessRestrictionKinds.AccessKind IS NULL
	|				OR VALUETYPE(AccessRestrictionKinds.AccessKind) = TYPE(Enum.AdditionalAccessValues)
	|			THEN """"
	|		WHEN NOT EmptyAccessValueReferences.Presentation IS NULL
	|			THEN EmptyAccessValueReferences.Presentation
	|		WHEN AccessKindsAndValues.AccessValue IS NULL
	|				OR AccessKindsAndValues.AccessValue = UNDEFINED
	|			THEN CASE
	|					WHEN AccessKindsAndValues.AllAllowed
	|						THEN &TextAllAllowed
	|					ELSE &TextAllForbidden
	|				END
	|		ELSE AccessKindsAndValues.AccessValue
	|	END AS AccessValue,
	|	UserGroupCompositions.User AS User,
	|	ISNULL(UsersInfo.CanSignIn, FALSE) AS CanSignIn
	|FROM
	|	RightsOfProfilesToTables AS ProfilesRights
	|		INNER JOIN Catalog.AccessGroups AS AccessGroups
	|		ON (AccessGroups.Profile = ProfilesRights.Profile)
	|			AND (NOT AccessGroups.DeletionMark)
	|		INNER JOIN Catalog.AccessGroups.Users AS AccessGroupsMembers
	|		ON (AccessGroupsMembers.Ref = AccessGroups.Ref)
	|		LEFT JOIN AccessRestrictionKinds AS AccessRestrictionKinds
	|			INNER JOIN AccessKindsAndValues AS AccessKindsAndValues
	|			ON (AccessKindsAndValues.AccessKind = AccessRestrictionKinds.AccessKind)
	|				AND (AccessRestrictionKinds.AccessKind <> VALUE(Enum.AdditionalAccessValues.AccessAllowed))
	|				AND (AccessRestrictionKinds.AccessKind <> VALUE(Enum.AdditionalAccessValues.AccessDenied))
	|		ON (AccessRestrictionKinds.Table = ProfilesRights.Table)
	|			AND (AccessKindsAndValues.AccessGroup = AccessGroups.Ref)
	|			AND (NOT AccessRestrictionKinds.ForExternalUsers
	|					AND (VALUETYPE(AccessGroupsMembers.User) = TYPE(Catalog.Users)
	|						OR VALUETYPE(AccessGroupsMembers.User) = TYPE(Catalog.UserGroups))
	|				OR AccessRestrictionKinds.ForExternalUsers
	|					AND (VALUETYPE(AccessGroupsMembers.User) = TYPE(Catalog.ExternalUsers)
	|						OR VALUETYPE(AccessGroupsMembers.User) = TYPE(Catalog.ExternalUsersGroups)))
	|			AND (ProfilesRights.ReadRight
	|					AND NOT ProfilesRights.UnrestrictedReadRight
	|					AND AccessRestrictionKinds.ReadRight
	|				OR ProfilesRights.RightUpdate
	|					AND NOT ProfilesRights.UnrestrictedUpdateRight
	|					AND AccessRestrictionKinds.RightUpdate
	|				OR ProfilesRights.AddRight
	|					AND NOT ProfilesRights.UnrestrictedAddRight
	|					AND AccessRestrictionKinds.RightUpdate)
	|		LEFT JOIN AccessRestrictionKinds AS TypesRestrictionsPermissionsUnconditional
	|		ON (TypesRestrictionsPermissionsUnconditional.Table = ProfilesRights.Table)
	|			AND (TypesRestrictionsPermissionsUnconditional.AccessKind = VALUE(Enum.AdditionalAccessValues.AccessAllowed)
	|				OR TypesRestrictionsPermissionsUnconditional.AccessKind = VALUE(Enum.AdditionalAccessValues.AccessDenied))
	|			AND (NOT TypesRestrictionsPermissionsUnconditional.ForExternalUsers
	|					AND (VALUETYPE(AccessGroupsMembers.User) = TYPE(Catalog.Users)
	|						OR VALUETYPE(AccessGroupsMembers.User) = TYPE(Catalog.UserGroups))
	|				OR TypesRestrictionsPermissionsUnconditional.ForExternalUsers
	|					AND (VALUETYPE(AccessGroupsMembers.User) = TYPE(Catalog.ExternalUsers)
	|						OR VALUETYPE(AccessGroupsMembers.User) = TYPE(Catalog.ExternalUsersGroups)))
	|		LEFT JOIN EmptyAccessValueReferences AS EmptyAccessValueReferences
	|		ON (EmptyAccessValueReferences.EmptyRef = AccessKindsAndValues.AccessValue)
	|		INNER JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|		ON (UserGroupCompositions.UsersGroup = AccessGroupsMembers.User)
	|			AND (ISNULL(UserGroupCompositions.User.IsInternal, FALSE) <> TRUE)
	|			AND (&SelectionCriteriaForUsers)
	|		LEFT JOIN InformationRegister.UsersInfo AS UsersInfo
	|		ON (UsersInfo.User = UserGroupCompositions.User)";
	
EndFunction

Function RequestTextWithGroupingByReportsSupplement()
	
	Return
	"SELECT
	|	RolesRightsToReports.Report AS ReportRef,
	|	RolesRightsToReports.Role AS Role
	|INTO RolesRightsToReports
	|FROM
	|	&RolesRightsToReports AS RolesRightsToReports
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AccessGroupProfilesRoles.Ref AS Profile,
	|	RolesRightsToReports.ReportRef AS ReportRef
	|INTO RightsOfProfilesToReports
	|FROM
	|	RolesRightsToReports AS RolesRightsToReports
	|		INNER JOIN Catalog.AccessGroupProfiles.Roles AS AccessGroupProfilesRoles
	|		ON RolesRightsToReports.Role = AccessGroupProfilesRoles.Role
	|			AND (NOT AccessGroupProfilesRoles.Ref.DeletionMark)
	|
	|INDEX BY
	|	ReportRef
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReportsTables.Report AS ReportRef,
	|	ReportsTables.MetadataObject AS Table
	|INTO ReportsTables
	|FROM
	|	&ReportsTables AS ReportsTables
	|WHERE
	|	&SelectingReportsByTables
	|
	|INDEX BY
	|	Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReportTablesWithPermissions.ReportRef AS ReportRef,
	|	ReportTablesWithPermissions.Table AS Table,
	|	ReportTablesWithPermissions.Profile AS Profile,
	|	MAX(ReportTablesWithPermissions.ReportRight) AS ReportRight,
	|	MAX(ReportTablesWithPermissions.ReadRight) AS ReadRight,
	|	MAX(ReportTablesWithPermissions.RightUpdate) AS RightUpdate,
	|	MAX(ReportTablesWithPermissions.AddRight) AS AddRight,
	|	MAX(ReportTablesWithPermissions.UnrestrictedReadRight) AS UnrestrictedReadRight,
	|	MAX(ReportTablesWithPermissions.UnrestrictedUpdateRight) AS UnrestrictedUpdateRight,
	|	MAX(ReportTablesWithPermissions.UnrestrictedAddRight) AS UnrestrictedAddRight,
	|	MAX(ReportTablesWithPermissions.ViewRight) AS ViewRight,
	|	MAX(ReportTablesWithPermissions.EditRight) AS EditRight,
	|	MAX(ReportTablesWithPermissions.InteractiveAddRight) AS InteractiveAddRight
	|INTO ProfilesRights
	|FROM
	|	(SELECT
	|		ReportsTables.ReportRef AS ReportRef,
	|		ReportsTables.Table AS Table,
	|		RightsOfProfilesToReports.Profile AS Profile,
	|		TRUE AS ReportRight,
	|		FALSE AS ReadRight,
	|		FALSE AS RightUpdate,
	|		FALSE AS AddRight,
	|		FALSE AS UnrestrictedReadRight,
	|		FALSE AS UnrestrictedUpdateRight,
	|		FALSE AS UnrestrictedAddRight,
	|		FALSE AS ViewRight,
	|		FALSE AS EditRight,
	|		FALSE AS InteractiveAddRight
	|	FROM
	|		ReportsTables AS ReportsTables
	|			INNER JOIN RightsOfProfilesToReports AS RightsOfProfilesToReports
	|			ON (RightsOfProfilesToReports.ReportRef = ReportsTables.ReportRef)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReportsTables.ReportRef,
	|		ReportsTables.Table,
	|		RightsOfProfilesToTables.Profile,
	|		FALSE,
	|		RightsOfProfilesToTables.ReadRight,
	|		RightsOfProfilesToTables.RightUpdate,
	|		RightsOfProfilesToTables.AddRight,
	|		RightsOfProfilesToTables.UnrestrictedReadRight,
	|		RightsOfProfilesToTables.UnrestrictedUpdateRight,
	|		RightsOfProfilesToTables.UnrestrictedAddRight,
	|		RightsOfProfilesToTables.ViewRight,
	|		RightsOfProfilesToTables.EditRight,
	|		RightsOfProfilesToTables.InteractiveAddRight
	|	FROM
	|		ReportsTables AS ReportsTables
	|			INNER JOIN RightsOfProfilesToTables AS RightsOfProfilesToTables
	|			ON (RightsOfProfilesToTables.Table = ReportsTables.Table)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ReportsTables.ReportRef,
	|		ReportsTables.Table,
	|		VALUE(Catalog.AccessGroupProfiles.EmptyRef),
	|		FALSE,
	|		FALSE,
	|		FALSE,
	|		FALSE,
	|		FALSE,
	|		FALSE,
	|		FALSE,
	|		FALSE,
	|		FALSE,
	|		FALSE
	|	FROM
	|		ReportsTables AS ReportsTables
	|	WHERE
	|		NOT TRUE IN
	|					(SELECT TOP 1
	|						TRUE
	|					FROM
	|						RightsOfProfilesToReports AS RightsOfProfilesToReports
	|					WHERE
	|						RightsOfProfilesToReports.ReportRef = ReportsTables.ReportRef)
	|		AND NOT TRUE IN
	|					(SELECT TOP 1
	|						TRUE
	|					FROM
	|						RightsOfProfilesToTables AS RightsOfProfilesToTables
	|					WHERE
	|						RightsOfProfilesToTables.Table = ReportsTables.Table)) AS ReportTablesWithPermissions
	|
	|GROUP BY
	|	ReportTablesWithPermissions.ReportRef,
	|	ReportTablesWithPermissions.Table,
	|	ReportTablesWithPermissions.Profile";
	
EndFunction

Function RequestTextWithGroupingByReports()
	
	Return
	"SELECT DISTINCT
	|	ProfilesRights.ReportRef AS ReportRef,
	|	CASE
	|		WHEN ProfilesRights.ReportRight
	|			THEN 1
	|		ELSE 0
	|	END AS ReportRight,
	|	ProfilesRights.Table AS MetadataObject,
	|	CASE
	|		WHEN &SimplifiedAccessRightsSetupInterface
	|			THEN AccessGroups.Profile
	|		ELSE AccessGroups.Ref
	|	END AS AccessGroup,
	|	ProfilesRights.ReadRight AS ReadRight,
	|	ProfilesRights.RightUpdate AS RightUpdate,
	|	ProfilesRights.AddRight AS AddRight,
	|	CASE
	|		WHEN ProfilesRights.AddRight
	|			THEN 3
	|		WHEN ProfilesRights.RightUpdate
	|			THEN 2
	|		WHEN ProfilesRights.ReadRight
	|			THEN 1
	|		ELSE 0
	|	END AS Right,
	|	ProfilesRights.UnrestrictedReadRight AS UnrestrictedReadRight,
	|	ProfilesRights.UnrestrictedUpdateRight AS UnrestrictedUpdateRight,
	|	ProfilesRights.UnrestrictedAddRight AS UnrestrictedAddRight,
	|	CASE
	|		WHEN ProfilesRights.UnrestrictedAddRight
	|			THEN 3
	|		WHEN ProfilesRights.UnrestrictedUpdateRight
	|			THEN 2
	|		WHEN ProfilesRights.UnrestrictedReadRight
	|			THEN 1
	|		ELSE 0
	|	END AS RightUnlimited,
	|	ProfilesRights.ViewRight AS ViewRight,
	|	ProfilesRights.EditRight AS EditRight,
	|	ProfilesRights.InteractiveAddRight AS InteractiveAddRight,
	|	CASE
	|		WHEN ProfilesRights.InteractiveAddRight
	|			THEN 3
	|		WHEN ProfilesRights.EditRight
	|			THEN 2
	|		WHEN ProfilesRights.ViewRight
	|			THEN 1
	|		ELSE 0
	|	END AS InteractiveRight,
	|	UserGroupCompositions.User AS User,
	|	ISNULL(UsersInfo.CanSignIn, FALSE) AS CanSignIn
	|INTO UsersRights
	|FROM
	|	ProfilesRights AS ProfilesRights
	|		INNER JOIN Catalog.AccessGroups AS AccessGroups
	|		ON (AccessGroups.Profile = ProfilesRights.Profile)
	|			AND (NOT AccessGroups.DeletionMark)
	|		INNER JOIN Catalog.AccessGroups.Users AS AccessGroupsMembers
	|		ON (AccessGroupsMembers.Ref = AccessGroups.Ref)
	|		INNER JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|		ON (UserGroupCompositions.UsersGroup = AccessGroupsMembers.User)
	|			AND (ISNULL(UserGroupCompositions.User.IsInternal, FALSE) <> TRUE)
	|			AND (&SelectionCriteriaForUsers)
	|		LEFT JOIN InformationRegister.UsersInfo AS UsersInfo
	|		ON (UsersInfo.User = UserGroupCompositions.User)";
	
EndFunction

Function TheTextOfTheRequestWithGroupingByReportsIsFinal()
	
	Return
	"SELECT DISTINCT
	|	UsersRights.User AS User,
	|	UsersRights.CanSignIn AS CanSignIn
	|INTO UsersWithRights
	|FROM
	|	UsersRights AS UsersRights
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UsersRights.ReportRef AS ReportRef,
	|	UsersRights.ReportRight AS ReportRight,
	|	UsersRights.MetadataObject AS MetadataObject,
	|	UsersRights.AccessGroup AS AccessGroup,
	|	UsersRights.ReadRight AS ReadRight,
	|	UsersRights.RightUpdate AS RightUpdate,
	|	UsersRights.AddRight AS AddRight,
	|	UsersRights.Right AS Right,
	|	UsersRights.UnrestrictedReadRight AS UnrestrictedReadRight,
	|	UsersRights.UnrestrictedUpdateRight AS UnrestrictedUpdateRight,
	|	UsersRights.UnrestrictedAddRight AS UnrestrictedAddRight,
	|	UsersRights.RightUnlimited AS RightUnlimited,
	|	UsersRights.ViewRight AS ViewRight,
	|	UsersRights.EditRight AS EditRight,
	|	UsersRights.InteractiveAddRight AS InteractiveAddRight,
	|	UsersRights.InteractiveRight AS InteractiveRight,
	|	UsersRights.User AS User,
	|	UsersRights.CanSignIn AS CanSignIn
	|FROM
	|	UsersRights AS UsersRights
	|
	|UNION ALL
	|
	|SELECT
	|	ReportsTables.ReportRef,
	|	0,
	|	ReportsTables.Table,
	|	CASE
	|		WHEN &SimplifiedAccessRightsSetupInterface
	|			THEN VALUE(Catalog.AccessGroupProfiles.EmptyRef)
	|		ELSE VALUE(Catalog.AccessGroups.EmptyRef)
	|	END,
	|	FALSE,
	|	FALSE,
	|	FALSE,
	|	FALSE,
	|	FALSE,
	|	FALSE,
	|	FALSE,
	|	FALSE,
	|	FALSE,
	|	FALSE,
	|	FALSE,
	|	0,
	|	UsersWithRights.User,
	|	UsersWithRights.CanSignIn
	|FROM
	|	ReportsTables AS ReportsTables
	|		INNER JOIN UsersWithRights AS UsersWithRights
	|		ON (NOT TRUE IN
	|					(SELECT TOP 1
	|						TRUE
	|					FROM
	|						UsersRights AS UsersRights
	|					WHERE
	|						UsersRights.ReportRef = ReportsTables.ReportRef
	|						AND UsersRights.MetadataObject = ReportsTables.Table
	|						AND UsersRights.User = UsersWithRights.User))";
	
EndFunction

Function QueryTextForAccessValueStart()
	
	Return
	"SELECT DISTINCT
	|	ProfilesRights.Profile AS Profile
	|INTO AllProfiles
	|FROM
	|	RightsOfProfilesToTables AS ProfilesRights
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccessGroups.Profile AS Profile,
	|	AccessGroups.Ref AS Ref
	|INTO AccessGroupsOfSelectedAccessValue
	|FROM
	|	AllProfiles AS AllProfiles
	|		INNER JOIN Catalog.AccessGroups AS AccessGroups
	|		ON (AccessGroups.Profile = AllProfiles.Profile)
	|WHERE
	|	NOT AccessGroups.DeletionMark
	|	AND CASE
	|			WHEN &IsAccessValuesGroup
	|					AND TRUE IN
	|						(SELECT TOP 1
	|							TRUE
	|						FROM
	|							InformationRegister.AccessGroupsValues AS Values
	|						WHERE
	|							Values.AccessGroup = AccessGroups.Ref
	|							AND Values.AccessValue = &AccessValue)
	|				THEN TRUE
	|			WHEN NOT &IsAccessValuesGroup
	|					AND TRUE IN
	|						(SELECT TOP 1
	|							TRUE
	|						FROM
	|							InformationRegister.AccessGroupsValues AS Values
	|								INNER JOIN InformationRegister.AccessValuesGroups AS ValueGroups
	|								ON
	|									Values.AccessGroup = AccessGroups.Ref
	|										AND Values.AccessValue = ValueGroups.AccessValuesGroup
	|										AND ValueGroups.AccessValue = &AccessValue)
	|				THEN TRUE
	|			ELSE FALSE
	|		END = CASE
	|			WHEN TRUE IN
	|					(SELECT TOP 1
	|						TRUE
	|					FROM
	|						InformationRegister.DefaultAccessGroupsValues AS DefaultValues
	|					WHERE
	|						DefaultValues.AccessGroup = AccessGroups.Ref
	|						AND VALUETYPE(DefaultValues.AccessValuesType) = VALUETYPE(&AccessKind)
	|						AND DefaultValues.AllAllowed = FALSE)
	|				THEN TRUE
	|			ELSE FALSE
	|		END";
	
EndFunction

Function QueryTextForAccessValueEnd()
	
	Return
	"SELECT DISTINCT
	|	ProfilesRights.Table AS MetadataObject,
	|	CASE
	|		WHEN &SimplifiedAccessRightsSetupInterface
	|			THEN AccessGroups.Profile
	|		ELSE AccessGroups.Ref
	|	END AS AccessGroup,
	|	ProfilesRights.ReadRight AS ReadRight,
	|	ProfilesRights.RightUpdate AS RightUpdate,
	|	ProfilesRights.AddRight AS AddRight,
	|	CASE
	|		WHEN ProfilesRights.AddRight
	|			THEN 3
	|		WHEN ProfilesRights.RightUpdate
	|			THEN 2
	|		WHEN ProfilesRights.ReadRight
	|			THEN 1
	|		ELSE 0
	|	END AS Right,
	|	CASE
	|		WHEN NOT ProfilesRights.ReadRight
	|			THEN FALSE
	|		WHEN ProfilesRights.UnrestrictedReadRight
	|			THEN TRUE
	|		ELSE NOT AccessRestrictionKinds.ReadRight
	|	END AS UnrestrictedReadRight,
	|	CASE
	|		WHEN NOT ProfilesRights.RightUpdate
	|			THEN FALSE
	|		WHEN ProfilesRights.UnrestrictedUpdateRight
	|			THEN TRUE
	|		ELSE NOT AccessRestrictionKinds.RightUpdate
	|	END AS UnrestrictedUpdateRight,
	|	CASE
	|		WHEN NOT ProfilesRights.AddRight
	|			THEN FALSE
	|		WHEN ProfilesRights.UnrestrictedAddRight
	|			THEN TRUE
	|		ELSE NOT AccessRestrictionKinds.RightUpdate
	|	END AS UnrestrictedAddRight,
	|	CASE
	|		WHEN CASE
	|				WHEN NOT ProfilesRights.AddRight
	|					THEN FALSE
	|				WHEN ProfilesRights.UnrestrictedAddRight
	|					THEN TRUE
	|				ELSE NOT AccessRestrictionKinds.RightUpdate
	|			END
	|			THEN 3
	|		WHEN CASE
	|				WHEN NOT ProfilesRights.RightUpdate
	|					THEN FALSE
	|				WHEN ProfilesRights.UnrestrictedUpdateRight
	|					THEN TRUE
	|				ELSE NOT AccessRestrictionKinds.RightUpdate
	|			END
	|			THEN 2
	|		WHEN CASE
	|				WHEN NOT ProfilesRights.ReadRight
	|					THEN FALSE
	|				WHEN ProfilesRights.UnrestrictedReadRight
	|					THEN TRUE
	|				ELSE NOT AccessRestrictionKinds.ReadRight
	|			END
	|			THEN 1
	|		ELSE 0
	|	END AS RightUnlimited,
	|	ProfilesRights.ViewRight AS ViewRight,
	|	ProfilesRights.EditRight AS EditRight,
	|	ProfilesRights.InteractiveAddRight AS InteractiveAddRight,
	|	CASE
	|		WHEN ProfilesRights.InteractiveAddRight
	|			THEN 3
	|		WHEN ProfilesRights.EditRight
	|			THEN 2
	|		WHEN ProfilesRights.ViewRight
	|			THEN 1
	|		ELSE 0
	|	END AS InteractiveRight,
	|	&AccessKind AS AccessKind,
	|	&AccessKindPresentation AS AccessKindPresentation,
	|	&AccessValuePresentation AS AccessValue,
	|	UserGroupCompositions.User AS User,
	|	ISNULL(UsersInfo.CanSignIn, FALSE) AS CanSignIn
	|FROM
	|	RightsOfProfilesToTables AS ProfilesRights
	|		INNER JOIN AccessGroupsOfSelectedAccessValue AS AccessGroups
	|		ON (AccessGroups.Profile = ProfilesRights.Profile)
	|		INNER JOIN Catalog.AccessGroups.Users AS AccessGroupsMembers
	|		ON (AccessGroupsMembers.Ref = AccessGroups.Ref)
	|		INNER JOIN AccessRestrictionKinds AS AccessRestrictionKinds
	|		ON (AccessRestrictionKinds.Table = ProfilesRights.Table)
	|			AND (NOT AccessRestrictionKinds.ForExternalUsers
	|					AND (VALUETYPE(AccessGroupsMembers.User) = TYPE(Catalog.Users)
	|						OR VALUETYPE(AccessGroupsMembers.User) = TYPE(Catalog.UserGroups))
	|				OR AccessRestrictionKinds.ForExternalUsers
	|					AND (VALUETYPE(AccessGroupsMembers.User) = TYPE(Catalog.ExternalUsers)
	|						OR VALUETYPE(AccessGroupsMembers.User) = TYPE(Catalog.ExternalUsersGroups)))
	|		INNER JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|		ON (UserGroupCompositions.UsersGroup = AccessGroupsMembers.User)
	|			AND (ISNULL(UserGroupCompositions.User.IsInternal, FALSE) <> TRUE)
	|			AND (&SelectionCriteriaForUsers)
	|		LEFT JOIN InformationRegister.UsersInfo AS UsersInfo
	|		ON (UsersInfo.User = UserGroupCompositions.User)";
	
EndFunction

Function QueryTextForTypeUserAccessValueEnd()
	
	Return
	"SELECT
	|	AccessGroups.Profile AS Profile,
	|	AccessGroups.Ref AS Ref,
	|	AccessGroups.User AS User,
	|	AccessGroups.IsAuthorizedUser AS IsAuthorizedUser
	|INTO AccessGroupsOfSelectedAccessValueWithMembers
	|FROM
	|	(SELECT DISTINCT
	|		AccessGroups.Profile AS Profile,
	|		AccessGroups.Ref AS Ref,
	|		UserGroupCompositions.User AS User,
	|		TRUE AS IsAuthorizedUser
	|	FROM
	|		AllProfiles AS AllProfiles
	|			INNER JOIN Catalog.AccessGroups AS AccessGroups
	|			ON (AccessGroups.Profile = AllProfiles.Profile)
	|			INNER JOIN Catalog.AccessGroups.Users AS AccessGroupsMembers
	|			ON (AccessGroupsMembers.Ref = AccessGroups.Ref)
	|			INNER JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|			ON (UserGroupCompositions.UsersGroup = AccessGroupsMembers.User)
	|				AND (ISNULL(UserGroupCompositions.User.IsInternal, FALSE) <> TRUE)
	|				AND (&SelectionCriteriaForUsers)
	|	WHERE
	|		NOT AccessGroups.DeletionMark
	|		AND TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					InformationRegister.AccessValuesGroups AS AccessValuesGroups
	|				WHERE
	|					AccessValuesGroups.AccessValue = &AccessValue
	|					AND AccessValuesGroups.AccessValuesGroup = UserGroupCompositions.User)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		AccessGroups.Profile,
	|		AccessGroups.Ref,
	|		AccessGroupsMembers.User,
	|		FALSE
	|	FROM
	|		AccessGroupsOfSelectedAccessValue AS AccessGroups
	|			INNER JOIN Catalog.AccessGroups.Users AS AccessGroupsMembers
	|			ON (AccessGroupsMembers.Ref = AccessGroups.Ref)) AS AccessGroups
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ProfilesRights.Table AS MetadataObject,
	|	CASE
	|		WHEN &SimplifiedAccessRightsSetupInterface
	|			THEN AccessGroupsWithMembers.Profile
	|		ELSE AccessGroupsWithMembers.Ref
	|	END AS AccessGroup,
	|	ProfilesRights.ReadRight
	|		AND (AccessRestrictionKinds.IsAuthorizedUser <= AccessGroupsWithMembers.IsAuthorizedUser
	|			OR ProfilesRights.UnrestrictedReadRight) AS ReadRight,
	|	ProfilesRights.RightUpdate
	|		AND (AccessRestrictionKinds.IsAuthorizedUser <= AccessGroupsWithMembers.IsAuthorizedUser
	|			OR ProfilesRights.UnrestrictedUpdateRight) AS RightUpdate,
	|	ProfilesRights.AddRight
	|		AND (AccessRestrictionKinds.IsAuthorizedUser <= AccessGroupsWithMembers.IsAuthorizedUser
	|			OR ProfilesRights.UnrestrictedAddRight) AS AddRight,
	|	CASE
	|		WHEN ProfilesRights.AddRight
	|				AND (AccessRestrictionKinds.IsAuthorizedUser <= AccessGroupsWithMembers.IsAuthorizedUser
	|					OR ProfilesRights.UnrestrictedAddRight)
	|			THEN 3
	|		WHEN ProfilesRights.RightUpdate
	|				AND (AccessRestrictionKinds.IsAuthorizedUser <= AccessGroupsWithMembers.IsAuthorizedUser
	|					OR ProfilesRights.UnrestrictedUpdateRight)
	|			THEN 2
	|		WHEN ProfilesRights.ReadRight
	|				AND (AccessRestrictionKinds.IsAuthorizedUser <= AccessGroupsWithMembers.IsAuthorizedUser
	|					OR ProfilesRights.UnrestrictedReadRight)
	|			THEN 1
	|		ELSE 0
	|	END AS Right,
	|	CASE
	|		WHEN NOT(ProfilesRights.ReadRight
	|					AND (AccessRestrictionKinds.IsAuthorizedUser <= AccessGroupsWithMembers.IsAuthorizedUser
	|						OR ProfilesRights.UnrestrictedReadRight))
	|			THEN FALSE
	|		WHEN ProfilesRights.UnrestrictedReadRight
	|			THEN TRUE
	|		ELSE NOT AccessRestrictionKinds.ReadRight
	|	END AS UnrestrictedReadRight,
	|	CASE
	|		WHEN NOT(ProfilesRights.RightUpdate
	|					AND (AccessRestrictionKinds.IsAuthorizedUser <= AccessGroupsWithMembers.IsAuthorizedUser
	|						OR ProfilesRights.UnrestrictedUpdateRight))
	|			THEN FALSE
	|		WHEN ProfilesRights.UnrestrictedUpdateRight
	|			THEN TRUE
	|		ELSE NOT AccessRestrictionKinds.RightUpdate
	|	END AS UnrestrictedUpdateRight,
	|	CASE
	|		WHEN NOT(ProfilesRights.AddRight
	|					AND (AccessRestrictionKinds.IsAuthorizedUser <= AccessGroupsWithMembers.IsAuthorizedUser
	|						OR ProfilesRights.UnrestrictedAddRight))
	|			THEN FALSE
	|		WHEN ProfilesRights.UnrestrictedAddRight
	|			THEN TRUE
	|		ELSE NOT AccessRestrictionKinds.RightUpdate
	|	END AS UnrestrictedAddRight,
	|	CASE
	|		WHEN CASE
	|				WHEN NOT(ProfilesRights.AddRight
	|							AND (AccessRestrictionKinds.IsAuthorizedUser <= AccessGroupsWithMembers.IsAuthorizedUser
	|								OR ProfilesRights.UnrestrictedAddRight))
	|					THEN FALSE
	|				WHEN ProfilesRights.UnrestrictedAddRight
	|					THEN TRUE
	|				ELSE NOT AccessRestrictionKinds.RightUpdate
	|			END
	|			THEN 3
	|		WHEN CASE
	|				WHEN NOT(ProfilesRights.RightUpdate
	|							AND (AccessRestrictionKinds.IsAuthorizedUser <= AccessGroupsWithMembers.IsAuthorizedUser
	|								OR ProfilesRights.UnrestrictedUpdateRight))
	|					THEN FALSE
	|				WHEN ProfilesRights.UnrestrictedUpdateRight
	|					THEN TRUE
	|				ELSE NOT AccessRestrictionKinds.RightUpdate
	|			END
	|			THEN 2
	|		WHEN CASE
	|				WHEN NOT(ProfilesRights.ReadRight
	|							AND (AccessRestrictionKinds.IsAuthorizedUser <= AccessGroupsWithMembers.IsAuthorizedUser
	|								OR ProfilesRights.UnrestrictedReadRight))
	|					THEN FALSE
	|				WHEN ProfilesRights.UnrestrictedReadRight
	|					THEN TRUE
	|				ELSE NOT AccessRestrictionKinds.ReadRight
	|			END
	|			THEN 1
	|		ELSE 0
	|	END AS RightUnlimited,
	|	ProfilesRights.ViewRight
	|		AND (AccessRestrictionKinds.IsAuthorizedUser <= AccessGroupsWithMembers.IsAuthorizedUser
	|			OR ProfilesRights.UnrestrictedReadRight) AS ViewRight,
	|	ProfilesRights.EditRight
	|		AND (AccessRestrictionKinds.IsAuthorizedUser <= AccessGroupsWithMembers.IsAuthorizedUser
	|			OR ProfilesRights.UnrestrictedUpdateRight) AS EditRight,
	|	ProfilesRights.InteractiveAddRight
	|		AND (AccessRestrictionKinds.IsAuthorizedUser <= AccessGroupsWithMembers.IsAuthorizedUser
	|			OR ProfilesRights.UnrestrictedAddRight) AS InteractiveAddRight,
	|	CASE
	|		WHEN ProfilesRights.InteractiveAddRight
	|				AND (AccessRestrictionKinds.IsAuthorizedUser <= AccessGroupsWithMembers.IsAuthorizedUser
	|					OR ProfilesRights.UnrestrictedAddRight)
	|			THEN 3
	|		WHEN ProfilesRights.EditRight
	|				AND (AccessRestrictionKinds.IsAuthorizedUser <= AccessGroupsWithMembers.IsAuthorizedUser
	|					OR ProfilesRights.UnrestrictedUpdateRight)
	|			THEN 2
	|		WHEN ProfilesRights.ViewRight
	|				AND (AccessRestrictionKinds.IsAuthorizedUser <= AccessGroupsWithMembers.IsAuthorizedUser
	|					OR ProfilesRights.UnrestrictedReadRight)
	|			THEN 1
	|		ELSE 0
	|	END AS InteractiveRight,
	|	&AccessKind AS AccessKind,
	|	&AccessKindPresentation AS AccessKindPresentation,
	|	&AccessValuePresentation AS AccessValue,
	|	UserGroupCompositions.User AS User,
	|	ISNULL(UsersInfo.CanSignIn, FALSE) AS CanSignIn
	|FROM
	|	RightsOfProfilesToTables AS ProfilesRights
	|		INNER JOIN AccessGroupsOfSelectedAccessValueWithMembers AS AccessGroupsWithMembers
	|		ON (AccessGroupsWithMembers.Profile = ProfilesRights.Profile)
	|		INNER JOIN AccessRestrictionKinds AS AccessRestrictionKinds
	|		ON (AccessRestrictionKinds.Table = ProfilesRights.Table)
	|			AND (AccessRestrictionKinds.IsAuthorizedUser <= AccessGroupsWithMembers.IsAuthorizedUser
	|				OR ProfilesRights.UnrestrictedReadRight
	|				OR ProfilesRights.UnrestrictedUpdateRight)
	|			AND (NOT AccessRestrictionKinds.ForExternalUsers
	|					AND (VALUETYPE(AccessGroupsWithMembers.User) = TYPE(Catalog.Users)
	|						OR VALUETYPE(AccessGroupsWithMembers.User) = TYPE(Catalog.UserGroups))
	|				OR AccessRestrictionKinds.ForExternalUsers
	|					AND (VALUETYPE(AccessGroupsWithMembers.User) = TYPE(Catalog.ExternalUsers)
	|						OR VALUETYPE(AccessGroupsWithMembers.User) = TYPE(Catalog.ExternalUsersGroups)))
	|		INNER JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|		ON (UserGroupCompositions.UsersGroup = AccessGroupsWithMembers.User)
	|			AND (ISNULL(UserGroupCompositions.User.IsInternal, FALSE) <> TRUE)
	|			AND (&SelectionCriteriaForUsers)
	|		LEFT JOIN InformationRegister.UsersInfo AS UsersInfo
	|		ON (UsersInfo.User = UserGroupCompositions.User)";
	
EndFunction

Function UsersRights()
	
	SelectionCriteriaForUsers = "";
	FilterConditionByCanSignIn = "";
	If SelectionByEnteringTheProgramIsAllowed() Then
		QueryTextWithoutGroupingByReportsWithAccessRestrictionsStart =
			QueryTextWithoutGroupingByReportsWithAccessRestrictionsStart() + "
			|		INNER JOIN InformationRegister.UsersInfo AS UsersInfo
			|		ON (UsersInfo.User = UserGroupCompositions.User)
			|			AND (UsersInfo.CanSignIn)";
		FilterConditionByCanSignIn = "
		|			AND (UsersInfo.CanSignIn)";
	Else
		QueryTextWithoutGroupingByReportsWithAccessRestrictionsStart =
			QueryTextWithoutGroupingByReportsWithAccessRestrictionsStart();
	EndIf;
	
	Query = New Query;
	
	SelectionByUserType = SelectionByUserType();
	FilterForSpecifiedUsers     = FilterForSpecifiedUsers();
	If ValueIsFilled(FilterForSpecifiedUsers.Value) And FilterForSpecifiedUsers.WithoutGroups Then
		Query.SetParameter("SelectedUsersWithoutGroups", FilterForSpecifiedUsers.Value);
		SelectionCriteriaForUsers = SelectionCriteriaForUsers + "
			|			AND (UserGroupCompositions.User IN (&SelectedUsersWithoutGroups))";
		
	ElsIf ValueIsFilled(FilterForSpecifiedUsers.Value) Then
		Query.SetParameter("SelectedUsersAndGroups", FilterForSpecifiedUsers.Value);
		SelectionCriteriaForUsers = SelectionCriteriaForUsers + "
			|		INNER JOIN InformationRegister.UserGroupCompositions AS FilterUsers
			|		ON (FilterUsers.User = UserGroupCompositions.User)
			|			AND (FilterUsers.UsersGroup IN (&SelectedUsersAndGroups))";
		
	ElsIf SelectionByUserType = "Users" Then
		SelectionCriteriaForUsers = SelectionCriteriaForUsers + "
			|			AND (VALUETYPE(UserGroupCompositions.User) = TYPE(Catalog.Users))";
		
	ElsIf SelectionByUserType = "ExternalUsers" Then
		SelectionCriteriaForUsers = SelectionCriteriaForUsers + "
			|			AND (VALUETYPE(UserGroupCompositions.User) = TYPE(Catalog.ExternalUsers))";
	EndIf;
	SelectionCriteriaForUsers = Mid(SelectionCriteriaForUsers, 4);
	
	GroupByReportsEnabled = GroupByReportsEnabled();
	VariantWithRestrictedAccess = VariantWithRestrictedAccess();
	ObjectRightsOption          = ObjectRightsOption();
	OptionForAccessValue    = OptionForAccessValue();
	UniversalRestriction =
		AccessManagementInternal.LimitAccessAtRecordLevelUniversally(True, True);
	
	If VariantWithRestrictedAccess Or OptionForAccessValue Then
		If UniversalRestriction Then
			QueryTextWithoutGroupingByReportsWithAccessRestrictionsRestrictionTypes
				= QueryTextWithoutGroupingByReportsWithAccessRestrictionsRestrictionTypesNew();
		Else
			QueryTextWithoutGroupingByReportsWithAccessRestrictionsRestrictionTypes
				= QueryTextWithoutGroupingByReportsWithAccessRestrictions();
		EndIf;
		EmptyAccessValueReferences = AccessManagementInternal.EmptyAccessValueReferences();
	EndIf;
	
	If GroupByReportsEnabled Then
		QueryTextMain = RequestTextWithGroupingByReports();
		Query.Text = QueryTextShared() + Common.QueryBatchSeparator()
			+ RequestTextWithGroupingByReportsSupplement();
		Query.SetParameter("RolesRightsToReports", RolesRightsToReports());
		Query.SetParameter("ReportsTables",     ReportsTables());
		
	ElsIf VariantWithRestrictedAccess Then
		QueryTextMain = QueryTextWithoutGroupingByReportsWithAccessRestrictionsStart
			+ Common.QueryBatchSeparator()
			+ QueryTextWithoutGroupingByReportsWithAccessRestrictionsRestrictionTypes
			+ Common.QueryBatchSeparator()
			+ QueryTextWithoutGroupingByReportsWithAccessRestrictionsEnd();
		Query.Text = QueryTextShared();
		Query.SetParameter("TextAllowed", " (" + NStr("vi = 'Được phép';
														|ru = 'Разрешенные';
														|en = 'Allowed'; fa = 'مجاز';
														|it = 'Autorizzati';
														|pl = 'Allowed';
														|tr = 'İzin verilen'")+ ")");
		Query.SetParameter("TextForbidden", " (" + NStr("vi = 'Cấm';
														|ru = 'Запрещенные';
														|en = 'Denied'; fa = 'رد شده';
														|it = 'Vietati';
														|pl = 'Denied';
														|tr = 'Yasak'") + ")");
		Query.SetParameter("TextAllowedUsers", " (" + NStr("vi = 'Được phép';
															|ru = 'Разрешенные';
															|en = 'Allowed'; fa = 'مجاز';
															|it = 'Autorizzati';
															|pl = 'Allowed';
															|tr = 'İzin verilen'") + ") - "
			+ NStr("vi = 'người sử dụng được ủy quyền và các nhóm của người đó luôn được phép';
					|ru = 'авторизованный пользователь и его группы всегда разрешены';
					|en = 'Authorized user and their groups are always allowed'; fa = 'Authorized user and their groups are always allowed';
					|it = 'авторизованный пользователь и его группы всегда разрешены';
					|pl = 'Authorized user and their groups are always allowed';
					|tr = 'yetkili kullanıcıya ve gruplarına her zaman izin verilir'"));
		Query.SetParameter("TextForbiddenUsers", " (" + NStr("vi = 'Cấm';
															|ru = 'Запрещенные';
															|en = 'Denied'; fa = 'رد شده';
															|it = 'Vietati';
															|pl = 'Denied';
															|tr = 'Yasak'") + ") - "
			+ NStr("vi = 'người sử dụng được ủy quyền và các nhóm của người đó luôn được phép';
					|ru = 'авторизованный пользователь и его группы всегда разрешены';
					|en = 'Authorized user and their groups are always allowed'; fa = 'Authorized user and their groups are always allowed';
					|it = 'авторизованный пользователь и его группы всегда разрешены';
					|pl = 'Authorized user and their groups are always allowed';
					|tr = 'yetkili kullanıcıya ve gruplarına her zaman izin verilir'"));
		Query.SetParameter("RestrictionDisabled", "<" + NStr("vi = 'Đã tắt hạn chế';
															|ru = 'Ограничение отключено';
															|en = 'Restriction disabled'; fa = 'Restriction disabled';
															|it = 'Limitazione disattivata';
															|pl = 'Ograniczenie zostało wyłączone';
															|tr = 'Kısıtlama devre dışı'")+ ">");
		Query.SetParameter("NonStandardRestriction",
			?(UniversalRestriction, "<" + NStr("vi = 'Hạn chế không chuẩn';
												|ru = 'Нестандартное ограничение';
												|en = 'Custom restriction'; fa = 'Custom restriction';
												|it = 'Custom restriction';
												|pl = 'Custom restriction';
												|tr = 'Standart dışı kısıtlamalar'") + ">",
				Reports.AccessRightsAnalysis.RestrictionPresentationWithoutAccessKinds()));
		Query.SetParameter("TextUnlimited", "<" + NStr("vi = 'Không hạn chế';
														|ru = 'Без ограничения';
														|en = 'No restriction'; fa = 'No restriction';
														|it = 'Senza restrizioni';
														|pl = 'Bez ograniczenia';
														|tr = 'Kısıtlamasız'") + ">");
		Query.SetParameter("TextAllAllowed", "<" + NStr("vi = 'Cho phép tất cả';
														|ru = 'Все разрешены';
														|en = 'All allowed'; fa = 'همه مجاز';
														|it = 'Tutti consentiti';
														|pl = 'Wszystkie są dozwolone';
														|tr = 'Hepsine izin verildi'") + ">");
		Query.SetParameter("TextAllForbidden", "<" + NStr("vi = 'Cấm tất cả';
															|ru = 'Все запрещены';
															|en = 'All denied'; fa = 'All denied';
															|it = 'Tutti vietati';
															|pl = 'Wszystkie są zabronione';
															|tr = 'Hepsi yasak'") + ">");
		Query.SetParameter("EmptyAccessValueReferences", EmptyAccessValueReferences);
		AllTablesWithRestriction = New Array;
		Query.SetParameter("AccessRestrictionKinds",
			Reports.AccessRightsAnalysis.AccessRestrictionKinds(,, AllTablesWithRestriction));
		Query.SetParameter("AllTablesWithRestriction", AllTablesWithRestriction);
		// Display of special restrictions:
		// 1. Access rights without restrictions are not displayed (information appears as unrestricted access in the access group profile):
		//    <No restriction>: The restriction is absent in one of the roles within the access group profile.
		// 2. Access rights with restrictions are displayed (similar to <All allowed>):
		//    <Restriction without access types>: A restriction exists without specific access types (special functions).
		//    <Access denied>: An absolute restriction based on the "WHERE FALSE" condition.
		//    <Restriction disabled in profile>: No access type settings exist in the profile, and there is no
		//        restriction without access types.
		//        <Restriction disabled>, <Read restriction disabled>: The restriction is:
		//        - Disabled in all access groups, or
		//            - Disabled by access types at the functional option level, or
		//            - Disabled at the restriction logic level based on "WHERE TRUE".
		//        
		
	ElsIf ObjectRightsOption Then
		DataElement = FilterByDataElements();
		RightsToDataElement = AccessManagement.AccessRightsToData(DataElement, Undefined);
		If Not ValueIsFilled(DataElement) Then
			RightsToDataElement.Clear();
		EndIf;
		Query.SetParameter("RightsToDataElement", RightsToDataElement);
		QueryTextMain = QueryTextForObjectRights();
		Query.Text = QueryTextShared();
		
	ElsIf OptionForAccessValue Then
		AccessValue = FilterByAccessValue();
		AccessKindsProperties = AccessManagementInternal.AccessKindsProperties();
		ByGroupsAndValuesTypes = AccessKindsProperties.ByGroupsAndValuesTypes;
		AccessKindProperties = ByGroupsAndValuesTypes.Get(TypeOf(AccessValue));
		AccessKind = ?(AccessKindProperties = Undefined, Null, AccessKindProperties.Ref);
		Filter = New Structure("AccessKind", AccessKind);
		AccessRestrictionKinds = Reports.AccessRightsAnalysis.AccessRestrictionKinds(, True);
		Query.SetParameter("AccessRestrictionKinds",
			AccessRestrictionKinds.Copy(AccessRestrictionKinds.FindRows(Filter)));
		GroupingOption = ParameterValueFromSetting(SettingsComposer.UserSettings,
			"GroupingOption", 0);
		TypeUser = New TypeDescription(
			"CatalogRef.Users, CatalogRef.UserGroups,
			|CatalogRef.ExternalUsers,CatalogRef.ExternalUsersGroups");
		QueryTextMain = QueryTextWithoutGroupingByReportsWithAccessRestrictionsRestrictionTypes
			+ Common.QueryBatchSeparator()
			+ QueryTextForAccessValueStart()
			+ Common.QueryBatchSeparator()
			+ ?(TypeUser.ContainsType(TypeOf(AccessKind)),
				QueryTextForTypeUserAccessValueEnd(),
				QueryTextForAccessValueEnd());
		Query.Text = QueryTextShared();
		Query.SetParameter("AccessKind", AccessKind);
		Query.SetParameter("AccessKindPresentation", ?(AccessKindProperties = Undefined, "",
			AccessManagementInternal.AccessKindPresentation(AccessKindProperties)));
		Query.SetParameter("AccessValue", AccessValue);
		FoundRow = EmptyAccessValueReferences.Find(AccessValue, "EmptyRef");
		Query.SetParameter("AccessValuePresentation", ?(FoundRow = Undefined,
			AccessValue, FoundRow.Presentation));
		Query.SetParameter("IsAccessValuesGroup", AccessKindProperties <> Undefined
			And AccessKindsProperties.ByValuesTypes.Get(TypeOf(AccessValue)) = Undefined);
	Else
		QueryTextMain = RequestTextWithoutGroupingByReports();
		Query.Text = QueryTextShared();
	EndIf;
	
	SimplifiedInterface = AccessManagementInternal.SimplifiedAccessRightsSetupInterface();
	Query.Text = Query.Text + Common.QueryBatchSeparator()
		+ QueryTextMain;
	
	Query.SetParameter("SimplifiedAccessRightsSetupInterface", SimplifiedInterface);
	Query.SetParameter("ExtensionsRolesRights", AccessManagementInternal.ExtensionsRolesRights());
	
	If ObjectRightsOption Then
		MetadataObject = Metadata.FindByType(TypeOf(DataElement));
		FilterByTables = Common.MetadataObjectID(MetadataObject);
	ElsIf OptionForAccessValue Then
		TablesWithRestriction = Query.Parameters.AccessRestrictionKinds.Copy(, "Table");
		TablesWithRestriction.GroupBy("Table");
		FilterByTables = ?(ValueIsFilled(TablesWithRestriction),
			FilterByTables(TablesWithRestriction.UnloadColumn("Table")),
			CommonClientServer.ValueInArray(Undefined));
	Else
		FilterByTables = FilterByTables();
	EndIf;
	If ValueIsFilled(FilterByTables) Then
		Query.SetParameter("SelectedTables", FilterByTables);
		Query.Text = StrReplace(Query.Text, "&SelectingRightsByTables",
			"RolesRights.MetadataObject IN (&SelectedTables)");
		Query.Text = StrReplace(Query.Text, "&SelectingReportsByTables",
			"ReportsTables.MetadataObject IN (&SelectedTables)");
	Else
		Query.Text = StrReplace(Query.Text, "&SelectingRightsByTables", "TRUE");
		Query.Text = StrReplace(Query.Text, "&SelectingReportsByTables", "TRUE");
	EndIf;
	
	Query.Text = StrReplace(Query.Text,
		"AND (&SelectionCriteriaForUsers)", SelectionCriteriaForUsers);
	
	If ValueIsFilled(FilterConditionByCanSignIn) Then
		Query.Text = Query.Text + FilterConditionByCanSignIn;
		Query.Text = StrReplace(Query.Text,
			"LEFT JOIN InformationRegister.UsersInfo AS UsersInfo",
			"INNER JOIN InformationRegister.UsersInfo AS UsersInfo");
	EndIf;
	
	If GroupByReportsEnabled Then
		Query.Text = Query.Text + "
		|
		|INDEX BY
		|	ReportRef,
		|	MetadataObject,
		|	User";
		Query.Text = Query.Text + Common.QueryBatchSeparator()
			+ TheTextOfTheRequestWithGroupingByReportsIsFinal();
	EndIf;
	
	Result = Query.Execute().Unload();
	
	If ObjectRightsOption Then
		Result.Columns.Add("DataElement");
		Result.Columns.Add("DataElementPresentation");
		Result.FillValues(Common.ValueToXMLString(DataElement), "DataElement");
		Result.FillValues(DataItemPresentation(DataElement), "DataElementPresentation");
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

Function GroupByReportsEnabled()
	
	FieldList = New Array;
	FillGroupsFieldsList(SettingsComposer.Settings.Structure,
		SettingsComposer.UserSettings, FieldList);
	
	Return FieldList.Find(New DataCompositionField("Report")) <> Undefined;
	
EndFunction

Function VariantWithRestrictedAccess()
	
	Variant = SettingsComposer.Settings.AdditionalProperties.PredefinedOptionKey;
	
	Return Variant = "UserRightsToTable";
	
EndFunction

Function ObjectRightsOption()
	
	Variant = SettingsComposer.Settings.AdditionalProperties.PredefinedOptionKey;
	
	Return Variant = "UsersRightsToObject";
	
EndFunction

Function OptionForAccessValue()
	
	Variant = SettingsComposer.Settings.AdditionalProperties.PredefinedOptionKey;
	
	Return Variant = "UsersRightsByAllowedValue";
	
EndFunction

// Returns:
//  Structure:
//    * HasHierarchy - Boolean
//    * RightsDetails - FixedArray of See InformationRegisters.ObjectsRightsSettings.AvailableRightProperties
//    * RefType    - Type
//    * EmptyRef - AnyRef
//
Function SettingsRightsByTableInselection(DCSettings = Undefined, DCUserSettings = Undefined)
	
	If Not AccessManagement.LimitAccessAtRecordLevel() Then
		Return Undefined;
	EndIf;
	
	Tables = FilterByTables(, DCSettings, DCUserSettings);
	If Not ValueIsFilled(Tables)
	 Or Tables.Count() <> 1
	 Or Not ValueIsFilled(Tables[0])
	 Or Not DescriptionOfIDTypes().ContainsType(TypeOf(Tables[0])) Then
		Return Undefined;
	EndIf;
	
	MetadataTables = Common.MetadataObjectByID(Tables[0], False);
	If MetadataTables = Undefined
	 Or Not Common.IsRefTypeObject(MetadataTables) Then
		Return Undefined;
	EndIf;
	
	ObjectManager = Common.ObjectManagerByFullName(MetadataTables.FullName());
	EmptyRef = ObjectManager.EmptyRef();
	RefType = TypeOf(EmptyRef);
	AvailableRights = AccessManagementInternal.RightsForObjectsRightsSettingsAvailable();
	
	RightsDetails = AvailableRights.ByRefsTypes.Get(RefType);
	If RightsDetails = Undefined Then
		Return Undefined;
	EndIf;
	
	Properties = New Structure("Hierarchical", False);
	FillPropertyValues(Properties, MetadataTables);
	
	Result = New Structure;
	Result.Insert("HasHierarchy", Properties.Hierarchical);
	Result.Insert("RightsDetails", RightsDetails);
	Result.Insert("RefType",    RefType);
	Result.Insert("EmptyRef", EmptyRef);
	
	Return Result;
	
EndFunction

// Parameters:
//  ItemsCollection - DataCompositionSettingStructureItemCollection
//  FieldList - Array
//
Procedure FillGroupsFieldsList(ItemsCollection, UserSettings, FieldList)
	
	For Each Item In ItemsCollection Do
		If TypeOf(Item) <> Type("DataCompositionGroup")
		   And TypeOf(Item) <> Type("DataCompositionTableGroup")
		   And TypeOf(Item) <> Type("DataCompositionTable") Then
			Continue;
		EndIf;
		CustomItem = UserSettings.Items.Find(
			Item.UserSettingID);
		If CustomItem <> Undefined
		   And Not CustomItem.Use
		 Or CustomItem = Undefined
		   And Not Item.Use Then
			Continue;
		EndIf;
		If TypeOf(Item) = Type("DataCompositionTable") Then
			FillGroupsFieldsList(Item.Rows, UserSettings, FieldList);
			FillGroupsFieldsList(Item.Columns, UserSettings, FieldList);
		Else
			For Each Field In Item.GroupFields.Items Do
				If TypeOf(Field) = Type("DataCompositionGroupField") Then
					If Field.Use Then
						FieldList.Add(Field.Field);
					EndIf;
				EndIf;
			EndDo;
			FillGroupsFieldsList(Item.Structure, UserSettings, FieldList);
		EndIf;
	EndDo;
	
EndProcedure

Function SelectedReport()
	
	SelectedReports = New Array;
	Filter = SettingsComposer.GetSettings().Filter;
	For Each Item In Filter.Items Do 
		If Item.Use And Item.LeftValue = New DataCompositionField("Report") Then
			If Item.ComparisonType = DataCompositionComparisonType.Equal Then
				SelectedReports.Add(Item.RightValue);
			Else
				Return Undefined;
			EndIf;
		EndIf;
	EndDo;
	
	If SelectedReports.Count() = 1 Then
		Return SelectedReports[0];
	EndIf;
	
	Return Undefined;
	
EndFunction

Function SelectionByUserType()
	
	If Not Constants.UseExternalUsers.Get() Then
		Return "Users";
	EndIf;
	
	FilterField = SettingsComposer.GetSettings().DataParameters.Items.Find("UsersKind");
	If Not FilterField.Use Then
		Return "";
	EndIf;
	
	If FilterField.Value = 0 Then
		Return "Users";
	EndIf;
	
	If FilterField.Value = 1 Then
		Return "ExternalUsers";
	EndIf;
	
	Return "";
	
EndFunction

Function FilterForSpecifiedUsers()
	
	Result = New Structure;
	Result.Insert("WithoutGroups", True);
	Result.Insert("Value", Undefined);
	
	If Not Users.IsFullUser(,, False) Then
		Result.Value = Users.AuthorizedUser();
		Return Result;
	EndIf;
	
	FilterField = SettingsComposer.GetSettings().DataParameters.Items.Find("User");
	FilterValue = FilterField.Value;
	If Not FilterField.Use Or Not ValueIsFilled(FilterValue) Then
		Return Result;
	EndIf;
	Result.Value = FilterValue;
	
	If TypeOf(FilterValue) <> Type("ValueList") Then
		FilterValue = New ValueList;
		FilterValue.Add(Result.Value);
	EndIf;
	
	For Each ListItem In FilterValue Do
		If TypeOf(ListItem.Value) = Type("CatalogRef.UserGroups")
		 Or TypeOf(ListItem.Value) = Type("CatalogRef.ExternalUsersGroups") Then
			Result.WithoutGroups = False;
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function FilterByTables(List = Undefined, DCSettings = Undefined, DCUserSettings = Undefined)
	
	If DCSettings = Undefined Then
		DCSettings = SettingsComposer.Settings;
	EndIf;
	If DCUserSettings = Undefined Then
		DCUserSettings = SettingsComposer.UserSettings;
	EndIf;
	
	FoundItem = Undefined;
	For Each Item In DCSettings.Filter.Items Do
		If Item.LeftValue = New DataCompositionField("MetadataObject") Then
			FoundItem = Item;
			Break;
		EndIf;
	EndDo;
	
	If FoundItem = Undefined Then
		Return Undefined;
	EndIf;
	
	Setting = DCUserSettings.Items.Find(
		FoundItem.UserSettingID);
	If Setting = Undefined Then
		Setting = FoundItem;
	EndIf;
	
	If Not Setting.Use Then
		Values = Undefined;
	ElsIf Setting.ComparisonType = DataCompositionComparisonType.Equal Then
		Values = CommonClientServer.ValueInArray(Setting.RightValue);
	ElsIf Setting.ComparisonType = DataCompositionComparisonType.InList Then
		Values = Setting.RightValue.UnloadValues();
	EndIf;
	
	If Values = Undefined Then
		Return List;
	EndIf;
	
	If List = Undefined Then
		Return Values;
	EndIf;
	
	Result = New Array;
	For Each Value In Values Do
		If List.Find(Value) <> Undefined Then
			Result.Add(Value);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function SelectionByEnteringTheProgramIsAllowed()
	
	Filter = SettingsComposer.GetSettings().Filter;
	
	For Each Item In Filter.Items Do 
		If Item.Use
		   And Item.LeftValue = New DataCompositionField("CanSignIn")
		   And Item.ComparisonType = DataCompositionComparisonType.Equal
		   And Item.RightValue = True Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function RightsSettingsOnObjects()
	
	Result = New Structure;
	Result.Insert("RightsSettingsOnObjects", New ValueTable);
	Result.Insert("SettingsRightsHierarchy",   New ValueTable);
	Result.Insert("SettingsRightsLegend",    New ValueTable);
	Result.Insert("OwnerSettingsHeader", "");
	
	If Not VariantWithRestrictedAccess() Then
		Return Result;
	EndIf;
	
	RightsSettings = SettingsRightsByTableInselection();
	If RightsSettings = Undefined Then
		Return Result;
	EndIf;
	Result.OwnerSettingsHeader = String(RightsSettings.RefType);
	
	UserDetails = FilterForSpecifiedUsers().Value;
	If TypeOf(UserDetails) = Type("ValueList") Then
		If UserDetails.Count() <> 1 Then
			Return Result;
		EndIf;
		User = UserDetails[0].Value;
	Else
		User = UserDetails;
	EndIf;
	If TypeOf(User) <> Type("CatalogRef.Users")
	   And TypeOf(User) <> Type("CatalogRef.ExternalUsers") Then
		Return Result;
	EndIf;
	
	If Users.IsFullUser(User,, False) Then
		Return Result;
	EndIf;
	
	SubfolderName = DescriptionColumnsForSubfolders().Name;
	TitlesRight = TitlesRight(RightsSettings, SubfolderName);
	
	Query = New Query;
	Query.SetParameter("ObjectType",    RightsSettings.RefType);
	Query.SetParameter("User",   User);
	Query.SetParameter("SubfolderName", SubfolderName);
	Query.SetParameter("HasHierarchy",   RightsSettings.HasHierarchy);
	Query.SetParameter("EmptyParent", RightsSettings.EmptyRef);
	Query.SetParameter("TitlesRight",  TitlesRight);
	Query.SetParameter("ViewPersonal",  NStr("vi = 'Cá nhân';
											|ru = 'Персонально';
											|en = 'Personal'; fa = 'شخصی';
											|it = 'Personale';
											|pl = 'Personal';
											|tr = 'Şahsen'"));
	Query.SetParameter("ViewUndefined", NStr("vi = 'Không xác định';
											|ru = 'Неопределено';
											|en = 'Undefined'; fa = 'تعریف‌نشده';
											|it = 'Indefinito';
											|pl = 'Undefined';
											|tr = 'Tanımsız'"));
	Query.SetParameter("ViewUserGroup",
		" (" + NStr("vi = 'Nhóm người sử dụng';
					|ru = 'Группа пользователей';
					|en = 'User group'; fa = 'گروه کاربران';
					|it = 'Gruppo di utenti';
					|pl = 'Grupa użytkowników';
					|tr = 'Kullanıcı grubu'") + ")");
	Query.SetParameter("ExternalUserGroupView",
		" (" + NStr("vi = 'Nhóm người sử dụng ngoài';
					|ru = 'Группа внешних пользователей';
					|en = 'External user group'; fa = 'گروه کاربران خارجی';
					|it = 'Gruppo di utenti esterni';
					|pl = 'Grupa zewnętrznych użytkowników';
					|tr = 'Harici kullanıcı grubu'") + ")");
	
	Query.Text =
	"SELECT
	|	RightsSettings.Object AS SettingsOwner,
	|	RightsSettings.User AS User_Settings,
	|	RightsSettings.Right AS CustomizedRight,
	|	CASE
	|		WHEN RightsSettings.RightIsProhibited
	|			THEN 2
	|		ELSE 1
	|	END AS RightsValue
	|INTO RightsSettingsByOwners
	|FROM
	|	InformationRegister.ObjectsRightsSettings AS RightsSettings
	|WHERE
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|			WHERE
	|				UserGroupCompositions.UsersGroup = RightsSettings.User
	|				AND UserGroupCompositions.User = &User)
	|	AND VALUETYPE(RightsSettings.Object) = &ObjectType
	|
	|UNION ALL
	|
	|SELECT
	|	RightsSettings.Object,
	|	RightsSettings.User,
	|	&SubfolderName,
	|	CASE
	|		WHEN MAX(RightsSettings.InheritanceIsAllowed) = FALSE
	|			THEN 2
	|		ELSE 1
	|	END
	|FROM
	|	InformationRegister.ObjectsRightsSettings AS RightsSettings
	|WHERE
	|	&HasHierarchy
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|			WHERE
	|				UserGroupCompositions.UsersGroup = RightsSettings.User
	|				AND UserGroupCompositions.User = &User)
	|	AND VALUETYPE(RightsSettings.Object) = &ObjectType
	|
	|GROUP BY
	|	RightsSettings.Object,
	|	RightsSettings.User
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculatedPermissions.SettingsOwner AS SettingsOwner,
	|	CalculatedPermissions.CustomizedRight AS CustomizedRight,
	|	MAX(CalculatedPermissions.RightsValue) AS RightsValue
	|INTO CalculatedPermissionsByOwners
	|FROM
	|	(SELECT DISTINCT
	|		SettingsInheritance.Object AS SettingsOwner,
	|		RightsSettings.Right AS CustomizedRight,
	|		1 AS RightsValue
	|	FROM
	|		InformationRegister.ObjectRightsSettingsInheritance AS SettingsInheritance
	|			INNER JOIN InformationRegister.ObjectsRightsSettings AS RightsSettings
	|			ON (VALUETYPE(SettingsInheritance.Object) = &ObjectType)
	|				AND (RightsSettings.Object = SettingsInheritance.Parent)
	|				AND SettingsInheritance.UsageLevel < RightsSettings.RightPermissionLevel
	|			INNER JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|			ON (UserGroupCompositions.User = &User)
	|				AND (UserGroupCompositions.UsersGroup = RightsSettings.User)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		SettingsInheritance.Object,
	|		RightsSettings.Right,
	|		2
	|	FROM
	|		InformationRegister.ObjectRightsSettingsInheritance AS SettingsInheritance
	|			INNER JOIN InformationRegister.ObjectsRightsSettings AS RightsSettings
	|			ON (VALUETYPE(SettingsInheritance.Object) = &ObjectType)
	|				AND (RightsSettings.Object = SettingsInheritance.Parent)
	|				AND SettingsInheritance.UsageLevel < RightsSettings.RightProhibitionLevel
	|			INNER JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
	|			ON (UserGroupCompositions.User = &User)
	|				AND (UserGroupCompositions.UsersGroup = RightsSettings.User)) AS CalculatedPermissions
	|
	|GROUP BY
	|	CalculatedPermissions.SettingsOwner,
	|	CalculatedPermissions.CustomizedRight
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SettingsInheritance.Object AS SettingsOwner,
	|	SettingsInheritance.Inherit AS SettingsInheritance
	|INTO InheritanceSettingsByOwners
	|FROM
	|	InformationRegister.ObjectRightsSettingsInheritance AS SettingsInheritance
	|WHERE
	|	SettingsInheritance.Object = SettingsInheritance.Parent
	|	AND VALUETYPE(SettingsInheritance.Object) = &ObjectType
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				CalculatedPermissionsByOwners AS CalculatedPermissionsByOwners
	|					INNER JOIN InformationRegister.ObjectRightsSettingsInheritance AS Parents
	|					ON
	|						Parents.Object = CalculatedPermissionsByOwners.SettingsOwner
	|							AND Parents.Parent = SettingsInheritance.Object)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TitlesRight.NameOfRight AS NameOfRight,
	|	TitlesRight.TitlePermissions AS TitlePermissions,
	|	TitlesRight.RightIndex AS RightIndex
	|INTO TitlesRight
	|FROM
	|	&TitlesRight AS TitlesRight
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	CalculatedPermissionsByOwners.SettingsOwner AS SettingsOwner,
	|	ISNULL(InheritanceSettingsByOwners.SettingsInheritance, FALSE) AS SettingsInheritance
	|INTO OneOwnerSettings
	|FROM
	|	CalculatedPermissionsByOwners AS CalculatedPermissionsByOwners
	|		LEFT JOIN InheritanceSettingsByOwners AS InheritanceSettingsByOwners
	|		ON (InheritanceSettingsByOwners.SettingsOwner = CalculatedPermissionsByOwners.SettingsOwner)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN InheritanceSettingsByOwners.SettingsOwner.Parent <> &EmptyParent
	|			THEN InheritanceSettingsByOwners.SettingsOwner.Parent
	|		ELSE UNDEFINED
	|	END AS ParentOwnerOrUserSettings,
	|	InheritanceSettingsByOwners.SettingsOwner AS OwnerOrUserSettings,
	|	PRESENTATION(InheritanceSettingsByOwners.SettingsOwner) AS OwnerOrUserSettingsPresentation,
	|	CASE
	|		WHEN InheritanceSettingsByOwners.SettingsOwner.Parent <> &EmptyParent
	|			THEN InheritanceSettingsByOwners.SettingsOwner.Parent
	|		ELSE UNDEFINED
	|	END AS SettingsOwner,
	|	TRUE AS ThisSettingsOwner
	|FROM
	|	InheritanceSettingsByOwners AS InheritanceSettingsByOwners
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	RightsSettingsByOwners.SettingsOwner,
	|	RightsSettingsByOwners.User_Settings,
	|	CASE
	|		WHEN VALUETYPE(RightsSettingsByOwners.User_Settings) = TYPE(Catalog.Users)
	|				OR VALUETYPE(RightsSettingsByOwners.User_Settings) = TYPE(Catalog.ExternalUsers)
	|			THEN &ViewPersonal
	|		WHEN VALUETYPE(RightsSettingsByOwners.User_Settings) = TYPE(Catalog.UserGroups)
	|			THEN CAST(RightsSettingsByOwners.User_Settings AS Catalog.UserGroups).Description + &ViewUserGroup
	|		WHEN VALUETYPE(RightsSettingsByOwners.User_Settings) = TYPE(Catalog.ExternalUsersGroups)
	|			THEN CAST(RightsSettingsByOwners.User_Settings AS Catalog.ExternalUsersGroups).Description + &ExternalUserGroupView
	|		ELSE &ViewUndefined
	|	END,
	|	RightsSettingsByOwners.SettingsOwner,
	|	FALSE
	|FROM
	|	RightsSettingsByOwners AS RightsSettingsByOwners
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN CalculatedPermissionsByOwners.SettingsOwner.Parent <> &EmptyParent
	|			THEN CalculatedPermissionsByOwners.SettingsOwner.Parent
	|		ELSE UNDEFINED
	|	END AS SettingsOwner,
	|	CalculatedPermissionsByOwners.SettingsOwner AS OwnerOrUserSettings,
	|	TRUE AS ThisSettingsOwner,
	|	ISNULL(InheritanceSettingsByOwners.SettingsInheritance, FALSE) AS InheritanceSettingsOwner,
	|	ISNULL(TitlesRight.TitlePermissions, CalculatedPermissionsByOwners.CustomizedRight) AS CustomizedRight,
	|	ISNULL(TitlesRight.RightIndex, 99) AS RightIndex,
	|	CalculatedPermissionsByOwners.RightsValue AS RightsValue
	|FROM
	|	CalculatedPermissionsByOwners AS CalculatedPermissionsByOwners
	|		LEFT JOIN TitlesRight AS TitlesRight
	|		ON (TitlesRight.NameOfRight = CalculatedPermissionsByOwners.CustomizedRight)
	|		LEFT JOIN InheritanceSettingsByOwners AS InheritanceSettingsByOwners
	|		ON (InheritanceSettingsByOwners.SettingsOwner = CalculatedPermissionsByOwners.SettingsOwner)
	|
	|UNION ALL
	|
	|SELECT
	|	RightsSettingsByOwners.SettingsOwner,
	|	RightsSettingsByOwners.User_Settings,
	|	FALSE,
	|	ISNULL(InheritanceSettingsByOwners.SettingsInheritance, FALSE),
	|	ISNULL(TitlesRight.TitlePermissions, RightsSettingsByOwners.CustomizedRight),
	|	ISNULL(TitlesRight.RightIndex, 99),
	|	RightsSettingsByOwners.RightsValue
	|FROM
	|	RightsSettingsByOwners AS RightsSettingsByOwners
	|		LEFT JOIN TitlesRight AS TitlesRight
	|		ON (TitlesRight.NameOfRight = RightsSettingsByOwners.CustomizedRight)
	|		LEFT JOIN InheritanceSettingsByOwners AS InheritanceSettingsByOwners
	|		ON (InheritanceSettingsByOwners.SettingsOwner = RightsSettingsByOwners.SettingsOwner)
	|
	|UNION ALL
	|
	|SELECT
	|	CASE
	|		WHEN OneOwnerSettings.SettingsOwner.Parent <> &EmptyParent
	|			THEN OneOwnerSettings.SettingsOwner.Parent
	|		ELSE UNDEFINED
	|	END,
	|	OneOwnerSettings.SettingsOwner,
	|	TRUE,
	|	OneOwnerSettings.SettingsInheritance,
	|	TitlesRight.TitlePermissions,
	|	TitlesRight.RightIndex,
	|	0
	|FROM
	|	TitlesRight AS TitlesRight
	|		INNER JOIN OneOwnerSettings AS OneOwnerSettings
	|		ON (NOT TRUE IN
	|					(SELECT TOP 1
	|						TRUE
	|					FROM
	|						CalculatedPermissionsByOwners AS CalculatedPermissions
	|					WHERE
	|						CalculatedPermissions.CustomizedRight = TitlesRight.NameOfRight))";
	
	QueryResults = Query.ExecuteBatch();
	
	Result.SettingsRightsHierarchy   = QueryResults[QueryResults.UBound()-1].Unload();
	Result.RightsSettingsOnObjects = QueryResults[QueryResults.UBound()].Unload();
	Result.SettingsRightsLegend    = SettingsRightsLegend(TitlesRight, RightsSettings.HasHierarchy);
	
	Return Result;
	
EndFunction

Function TitlesRight(RightsSettings, SubfolderName)
	
	Result = New ValueTable;
	Result.Columns.Add("NameOfRight",       StringType(60));
	Result.Columns.Add("RightIndex",    NumberType(2));
	Result.Columns.Add("TitlePermissions", StringType(60));
	Result.Columns.Add("HintPermissions", StringType(150));
	
	For Each RightDetails In RightsSettings.RightsDetails Do
		RightPresentations = InformationRegisters.ObjectsRightsSettings.AvailableRightPresentation(RightDetails);
		NewRow = Result.Add();
		NewRow.NameOfRight       = RightDetails.Name;
		NewRow.RightIndex    = RightDetails.RightIndex;
		NewRow.TitlePermissions = StrReplace(RightPresentations.Title, Chars.LF, " ");
		NewRow.HintPermissions = StrReplace(RightPresentations.ToolTip, Chars.LF, " ");
	EndDo;
	
	If RightsSettings.HasHierarchy Then
		ColumnDetails = DescriptionColumnsForSubfolders();
		NewRow = Result.Add();
		NewRow.NameOfRight       = ColumnDetails.Name;
		NewRow.RightIndex    = RightsSettings.RightsDetails.Count();
		NewRow.TitlePermissions = ColumnDetails.Title;
		NewRow.HintPermissions = ColumnDetails.ToolTip;
	EndIf;
	
	Return Result;
	
EndFunction

Function DescriptionColumnsForSubfolders()
	
	Result = New Structure;
	Result.Insert("Name", "ForSubfolders");
	Result.Insert("Title", NStr("vi = 'Đối với thư mục con';
								|ru = 'Для подпапок';
								|en = 'For subfolders'; fa = 'For subfolders';
								|it = 'Per le sottocartelle';
								|pl = 'Dla podfolderów';
								|tr = 'Alt klasörler için'"));
	Result.Insert("ToolTip",
		NStr("vi = 'Quyền không chỉ có hiệu lực đối với thư mục hiện tại, mà còn đối với các thư mục con lớp dưới';
			|ru = 'Права не только для текущей папки, но и для ее нижестоящих папок';
			|en = 'Rights both for the current folder and its subfolders'; fa = 'Rights both for the current folder and its subfolders';
			|it = 'Diritti non solo per la cartella corrente, ma anche per le sue cartelle downstream';
			|pl = 'Uprawnienia nie tylko dla bieżącego folderu, ale także dla folderów, które znajdują się niżej';
			|tr = 'Haklar sadece geçerli klasör için değil, aynı zamanda alt klasörler için de'"));
	
	Return Result;
	
EndFunction

Function SettingsRightsLegend(TitlesRight, HasHierarchy)
	
	Result = TitlesRight.Copy(, "TitlePermissions,HintPermissions");
	
	If HasHierarchy Then
		NewRow = Result.Insert(0);
		NewRow.TitlePermissions = "";
		NewRow.HintPermissions = NStr("vi = 'Kế thừa quyền từ thư mục lớp trên';
										|ru = 'Наследование прав от вышестоящих папок';
										|en = 'Right inheritance from parent folders'; fa = 'Right inheritance from parent folders';
										|it = 'Ereditarietà dei diritti dalle cartelle principali';
										|pl = 'Dziedziczenie uprawnień z folderów nadrzędnych';
										|tr = 'Giriş klasörlerinden hak devralma'");
	EndIf;
	
	For Each String In Result Do
		String.HintPermissions = "- " + String.HintPermissions;
	EndDo;
	
	Return Result;
	
EndFunction

Function FilterByDataElements()
	
	FilterField = SettingsComposer.GetSettings().DataParameters.Items.Find("DataElement");
	FilterValue = FilterField.Value;
	If Not FilterField.Use Or Not ValueIsFilled(FilterValue) Then
		Return Catalogs.Users.EmptyRef();
	EndIf;
	
	Return FilterValue;
	
EndFunction

Function DataItemPresentation(DataElement)
	
	MetadataObject = Metadata.FindByType(TypeOf(DataElement));
	
	If Not Common.IsRegister(MetadataObject) Then
		Return String(DataElement);
	EndIf;
	
	DataPresentation = MetadataObject.Presentation();
	FieldsDetails = StandardSubsystemsServer.RecordKeyDetails(
		MetadataObject.FullName()).FieldsDetails;
	
	FieldList = New Array;
	For Each FieldDetails In FieldsDetails Do
		FieldList.Add(StrTemplate("  %1 = ""%2""",
			FieldDetails.Presentation, String(DataElement[FieldDetails.Name])));
	EndDo;
	
	TemplateOfPresentation = ?(FieldsDetails.Count() = 1,
		NStr("vi = 'Bản ghi của biểu ghi ""%1"" với trường khóa:
		           |%2';
		           |ru = 'Запись регистра ""%1"" с ключевым полем:
		           |%2';
		           |en = 'Register record ""%1"" with a key field:
		           |%2'; fa = 'Register record ""%1"" with a key field:
		           |%2';
		           |it = 'Register record ""%1"" with a key field:
		           |%2';
		           |pl = 'Register record ""%1"" with a key field:
		           |%2';
		           |tr = 'Şu anahtar alanını içeren kayıt tablosu ""%1"": 
		           |%2'"),
		NStr("vi = 'Bản ghi của biểu ghi ""%1"" với trường khóa:
		           |%2';
		           |ru = 'Запись регистра ""%1"" с ключевыми полями:
		           |%2';
		           |en = 'Register record ""%1"" with key fields:
		           |%2'; fa = 'Register record ""%1"" with key fields:
		           |%2';
		           |it = 'Register record ""%1"" with key fields:
		           |%2';
		           |pl = 'Register record ""%1"" with key fields:
		           |%2';
		           |tr = 'Şu anahtar alanlarını içeren kayıt tablosu ""%1"": 
		           |%2'"));
	
	Return StringFunctionsClientServer.SubstituteParametersToString(TemplateOfPresentation,
		DataPresentation, StrConcat(FieldList, "," + Chars.LF));
	
EndFunction

Function FilterByAccessValue()
	
	FilterField = SettingsComposer.GetSettings().DataParameters.Items.Find("AccessValue");
	
	Return FilterField.Value;
	
EndFunction


Function ParameterValueFromSetting(DCUserSettings, ParameterName, DefaultValue = Undefined)
	
	Parameter = New DataCompositionParameter(ParameterName);
	Value = DefaultValue;
	If DCUserSettings = Undefined Then
		Return Value;
	EndIf;
	
	For Each UserSettingItem In DCUserSettings.Items Do
		
		If TypeOf(UserSettingItem) = Type("DataCompositionSettingsParameterValue")
		   And UserSettingItem.Parameter = Parameter Then
			
			If UserSettingItem.Use Then
				Value = UserSettingItem.Value;
			EndIf;
			Break;
		EndIf;
	EndDo;
	
	Return Value;
	
EndFunction

Procedure SetGroupingsUsage(Groups, DCSettings, DCUserSettings)
	
	For Each Group In Groups Do
		Reports.AccessRightsAnalysis.SetGroupingUsage(
			Group.Key, Group.Value, DCSettings, DCUserSettings);
	EndDo;
	
EndProcedure

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf