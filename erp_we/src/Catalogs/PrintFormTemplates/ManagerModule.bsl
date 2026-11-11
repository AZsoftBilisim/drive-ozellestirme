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

// StandardSubsystems.BatchEditObjects

// Returns object attributes that can be edited using the bulk attribute modification data processor.
// 
//
// Returns:
//  Array of String
//
Function AttributesToEditInBatchProcessing() Export
	
	AttributesToEdit = New Array;
	AttributesToEdit.Add("Used");
	AttributesToEdit.Add("DefaultPrintForm");
	AttributesToEdit.Add("PrintFormDescription");
	
	Return AttributesToEdit;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// Registers the objects to be updated in the InfobaseUpdate exchange plan.
// 
//
// Parameters:
//  Parameters - Structure - Internal parameter to pass to the InfobaseUpdate.MarkForProcessing procedure.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	QueryText =
	"SELECT
	|	PrintFormTemplates.Ref
	|FROM
	|	Catalog.PrintFormTemplates AS PrintFormTemplates
	|WHERE
	|	PrintFormTemplates.DataSource <> UNDEFINED";
	
	Query = New Query(QueryText);
	Templates = Query.Execute().Unload().UnloadColumn("Ref");

	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	InfobaseUpdate.MarkForProcessing(Parameters, Templates, AdditionalParameters);
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Parameters:
//  Template - UUID
//  
// Returns:
//  Array of String
// 
Function LayoutLanguages(Template) Export 
	
	QueryText = 
	"SELECT
	|	PrintFormTemplates.Template AS Template,
	|	&DefaultLanguageCode AS LanguageCode
	|FROM
	|	Catalog.PrintFormTemplates AS PrintFormTemplates
	|WHERE
	|	PrintFormTemplates.Id = &Id
	|
	|UNION ALL
	|
	|SELECT
	|	PrintFormTemplatesPresentations.Template,
	|	PrintFormTemplatesPresentations.LanguageCode
	|FROM
	|	Catalog.PrintFormTemplates.Presentations AS PrintFormTemplatesPresentations
	|		LEFT JOIN Catalog.PrintFormTemplates AS PrintFormTemplates
	|		ON PrintFormTemplatesPresentations.Ref = PrintFormTemplates.Ref
	|WHERE
	|	PrintFormTemplates.Id = &Id";
	
	Query = New Query(QueryText);
	Query.SetParameter("Id", Template);
	Query.SetParameter("DefaultLanguageCode", Common.DefaultLanguageCode());
	
	Result = New Array;

	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Result.Add(Selection.LanguageCode);
	EndDo;
	
	Return Result;
	
EndFunction

// Parameters:
//  TemplatesNames - Array of String - Template name
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String - Template name
//   * Value - See NewTemplatesDataStructure
//
Function DataOfTemplates(Val TemplatesNames) Export
	
	TemplatesDataMap = New Map;
	
	If TypeOf(TemplatesNames) = Type("String") Then
		TemplatesNames = StrSplit(TemplatesNames, ",");
	Else
		TemplatesNames = Common.CopyRecursive(TemplatesNames);
	EndIf;
	
	TableOfTemplates = New ValueTable;
	TableOfTemplates.Columns.Add("TemplateName", New TypeDescription("String"));
	TableOfTemplates.Columns.Add("Id", New TypeDescription("UUID"));
	
	For Each TemplateName In TemplatesNames Do 
		
		NewRow = TableOfTemplates.Add();
		NewRow.TemplateName = TemplateName;
		
		Id = IdentifierOfTemplate(TemplateName);
		If Id <> Undefined Then
			NewRow.Id = Id;
		EndIf;
		
	EndDo;
	
	QueryText =
	"SELECT
	|	TableOfTemplates.TemplateName AS TemplateName,
	|	TableOfTemplates.Id AS Id
	|INTO TT_TableOfTemplates
	|FROM
	|	&TableOfTemplates AS TableOfTemplates
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(PrintFormTemplates.Description, """") AS Presentation,
	|	TT_TableOfTemplates.TemplateName AS TemplateName,
	|	TT_TableOfTemplates.Id AS Id,
	|	ISNULL(PrintFormTemplates.ObjectSaveFormat, VALUE(Enum.ObjectsExportFormats.EmptyRef)) AS ObjectSaveFormat,
	|	ISNULL(PrintFormTemplates.Ref, VALUE(Catalog.PrintFormTemplates.EmptyRef)) AS Ref
	|INTO TT_Templates
	|FROM
	|	TT_TableOfTemplates AS TT_TableOfTemplates
	|		LEFT JOIN Catalog.PrintFormTemplates AS PrintFormTemplates
	|		ON TT_TableOfTemplates.Id = PrintFormTemplates.Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_Templates.TemplateName AS TemplateName,
	|	TT_Templates.Presentation AS Presentation,
	|	TT_Templates.Id AS Id,
	|	TT_Templates.ObjectSaveFormat AS ObjectSaveFormat,
	|	CASE
	|		WHEN
	|			VALUETYPE(PrintFormTemplatesDataSources.DataSource) = TYPE(Catalog.MetadataObjectIDs)
	|			THEN VALUETYPE(CAST(PrintFormTemplatesDataSources.DataSource AS Catalog.MetadataObjectIDs).EmptyRefValue)
	|		WHEN
	|			VALUETYPE(PrintFormTemplatesDataSources.DataSource) = TYPE(Catalog.ExtensionObjectIDs)
	|			THEN VALUETYPE(CAST(PrintFormTemplatesDataSources.DataSource AS Catalog.ExtensionObjectIDs).EmptyRefValue)
	|		ELSE UNDEFINED
	|	END AS SourceType
	|FROM
	|	TT_Templates AS TT_Templates
	|		INNER JOIN Catalog.PrintFormTemplates.DataSources AS PrintFormTemplatesDataSources
	|		ON TT_Templates.Ref = PrintFormTemplatesDataSources.Ref";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("TableOfTemplates", TableOfTemplates);
	Selection = Query.Execute().Select();
	
	For Each TemplateName In TemplatesNames Do
		
		MetadataTypes = New Array;
		
		TemplatesDataStructure = NewTemplatesDataStructure();
		
		While Selection.FindNext(TemplateName, "TemplateName") Do
			
			TemplatesDataStructure.ObjectSaveFormat = Selection.ObjectSaveFormat;
			TemplatesDataStructure.Presentation = Selection.Presentation;
			MetadataTypes.Add(Selection.SourceType);
			
		EndDo;
		Selection.Reset();
		
		TemplatesDataStructure.SourcesTypes = MetadataTypes;
		TemplatesDataMap.Insert(TemplateName, TemplatesDataStructure);
		
	EndDo;
	
	Return TemplatesDataMap;
	
EndFunction

#EndRegion

#Region Private

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	
	Selection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.PrintFormTemplates");
	While Selection.Next() Do
		Block = New DataLock;
		LockItem = Block.Add("Catalog.PrintFormTemplates");
		LockItem.SetValue("Ref", Selection.Ref);
		
		RepresentationOfTheReference = String(Selection.Ref);
		
		BeginTransaction();
		Try
			Block.Lock();
			
			Template = Selection.Ref.GetObject(); // CatalogObject.PrintFormTemplates
			TableRow = Template.DataSources.Add();
			TableRow.DataSource = Template.DataSource;
			Template.DataSource = Undefined;
			InfobaseUpdate.WriteData(Template);
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
		Except
			RollbackTransaction();
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			InfobaseUpdate.WriteErrorToEventLog(
				Selection.Ref,
				RepresentationOfTheReference,
				ErrorInfo());
		EndTry;
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "InformationRegister.UserPrintTemplates");
	
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xử lý một số khuôn in (đã bỏ qua): %1';
				|ru = 'Не удалось обработать некоторые макеты печати (пропущены): %1';
				|en = 'Couldn''t process (skipped) some print templates: %1'; fa = 'Couldn''t process (skipped) some print templates: %1';
				|it = 'Не удалось обработать некоторые макеты печати (пропущены): %1';
				|pl = 'Couldn''t process (skipped) some print templates: %1';
				|tr = 'Bazı yazdırma şablonları işlenemedi (atlandı): %1'"),
			ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Information, Metadata.InformationRegisters.UserPrintTemplates,,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đã xử lý phần khuôn in khác: %1';
						|ru = 'Обработана очередная порция макетов печати: %1';
						|en = 'Another batch of print templates is processed: %1'; fa = 'Another batch of print templates is processed: %1';
						|it = 'Обработана очередная порция макетов печати: %1';
						|pl = 'Another batch of print templates is processed: %1';
						|tr = 'Başka bir takım yazdırma şablonları işlendi: %1'"),
			ObjectsProcessed));
	EndIf;
	
EndProcedure

Function WriteTemplate(TemplateDetails) Export
	
	Ref = TemplateDetails.Ref;
	If ValueIsFilled(Ref) Then
		Object = Ref.GetObject();
	Else
		Object = CreateItem();
		Object.TemplateType = TemplateDetails.TemplateType;
		Object.Id = New UUID;
	EndIf;
	
	Object.TemplateForObjectExport = TemplateDetails.TemplateForObjectExport;
	Object.ObjectSaveFormat = TemplateDetails.ExportSaveFormat;
	
	Object.DataSources.Clear();
	For Each DataSource In TemplateDetails.DataSources Do
		NewRow = Object.DataSources.Add();
		NewRow.DataSource = DataSource;
	EndDo;
	
	Description = TemplateDetails.Description;
	LanguageCode = TemplateDetails.LanguageCode;
	Template = New ValueStorage(GetFromTempStorage(TemplateDetails.TemplateAddressInTempStorage));
	PrintFormDescription = TemplateDetails.PrintFormDescription;

	Common.SetAttributeValue(Object, "Description", Description, LanguageCode);
	Common.SetAttributeValue(Object, "Template", Template, LanguageCode);
	Common.SetAttributeValue(Object, "PrintFormDescription", PrintFormDescription, LanguageCode);
	
	Object.DefaultPrintForm = TemplateDetails.DefaultPrintForm;
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.PrintFormTemplates");
	If ValueIsFilled(Ref) Then
		LockItem.SetValue("Ref", Ref);
	EndIf;
	
	BeginTransaction();
	Try
		Block.Lock();
		Object.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return "PF_" + String(Object.Id);
	
EndFunction

// Parameters:
//  Template - CatalogRef.PrintFormTemplates
//  Used - Boolean
//
Procedure SetUseLayout(Template, Used) Export
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.PrintFormTemplates");
	LockItem.SetValue("Ref", Template);
	
	BeginTransaction();
	Try
		Block.Lock();
		
		Object = Template.GetObject();
		Object.Used = Used;
		Object.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Function TemplateExists(Id) Export
	
	QueryText = 
	"SELECT
	|	Ref 
	|FROM
	|	Catalog.PrintFormTemplates AS PrintFormTemplates
	|WHERE
	|	PrintFormTemplates.Id = &Id";
	
	Query = New Query(QueryText);
	Query.SetParameter("Id", Id);

	Return Not Query.Execute().IsEmpty();

EndFunction

Function FindTemplate(TemplatePath, LanguageCode) Export
	
	Id = IdentifierOfTemplate(TemplatePath);
	If Id <> Undefined Then
		Return PrintableFormLayoutByID(Id, LanguageCode);
	EndIf;
	
	Return Undefined;
	
EndFunction

Function PrintableFormLayoutByID(Id, LanguageCode)
	
	QueryText =
	"SELECT
	|	PrintFormTemplatesPresentations.Template
	|FROM
	|	Catalog.PrintFormTemplates.Presentations AS PrintFormTemplatesPresentations
	|		LEFT JOIN Catalog.PrintFormTemplates AS PrintFormTemplates
	|		ON PrintFormTemplatesPresentations.Ref = PrintFormTemplates.Ref
	|WHERE
	|	PrintFormTemplates.Id = &Id
	|	AND PrintFormTemplatesPresentations.LanguageCode = &LanguageCode
	|
	|UNION ALL
	|
	|SELECT
	|	PrintFormTemplates.Template
	|FROM
	|	Catalog.PrintFormTemplates AS PrintFormTemplates
	|WHERE
	|	PrintFormTemplates.Id = &Id";
	
	Query = New Query(QueryText);
	Query.SetParameter("Id", Id);
	Query.SetParameter("LanguageCode", LanguageCode);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Template = Selection.Template.Get(); // ValueStorage
		If Template = Undefined Then
			Continue;
		EndIf;
		If TypeOf(Template) <> Type("BinaryData") Then
			Template.LanguageCode = Common.DefaultLanguageCode();
		EndIf;
		Return Template;
	EndDo;
	
	Return Undefined;
	
EndFunction

Function IdentifierOfTemplate(TemplatePath) Export
	
	PathParts = StrSplit(TemplatePath, ".", True);
	
	TemplateName = PathParts[PathParts.UBound()];
	If StrStartsWith(TemplateName, "PF_") Then
		Id = Mid(TemplateName, 4);
		If StringFunctionsClientServer.IsUUID(Id) Then
			Return New UUID(Id);
		EndIf;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Returns:
//  CatalogRef.PrintFormTemplates
//
Function RefTemplate(TemplatePath) Export
	
	Id = IdentifierOfTemplate(TemplatePath);
	If Id = Undefined Then
		Return Undefined;
	EndIf;
	
	QueryText =
	"SELECT
	|	PrintFormTemplates.Ref AS Ref
	|FROM
	|	Catalog.PrintFormTemplates AS PrintFormTemplates
	|WHERE
	|	PrintFormTemplates.Id = &Id";
	
	Query = New Query(QueryText);
	Query.SetParameter("Id", Id);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Ref;
	EndIf;
	
	Return Undefined;
	
EndFunction

Procedure DeleteTemplate(Ref, LanguageCode = Undefined) Export
	
	Object = Ref.GetObject();
	If LanguageCode = Undefined Or LanguageCode = Common.DefaultLanguageCode() Then
		Object.SetDeletionMark(True);
	Else
		TemplateLines = Object.Presentations.FindRows(New Structure("LanguageCode", LanguageCode));
		For Each TemplateString In TemplateLines Do
			Object.Presentations.Delete(TemplateString);
		EndDo;
	EndIf;

	Block = New DataLock;
	LockItem = Block.Add("Catalog.PrintFormTemplates");
	LockItem.SetValue("Ref", Ref);
	
	BeginTransaction();
	Try
		Block.Lock();
		Object.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

EndProcedure

Function TemplateDataSource(TemplatePath) Export

	Id = IdentifierOfTemplate(TemplatePath);
	If Id = Undefined Then
		Return Undefined;
	EndIf;
	
	QueryText =
	"SELECT
	|	PrintFormTemplatesDataSources.DataSource AS DataSource
	|FROM
	|	Catalog.PrintFormTemplates.DataSources AS PrintFormTemplatesDataSources
	|		LEFT JOIN Catalog.PrintFormTemplates AS PrintFormTemplates
	|		ON PrintFormTemplatesDataSources.Ref = PrintFormTemplates.Ref
	|WHERE
	|	PrintFormTemplates.Id = &Id";
	
	Query = New Query(QueryText);
	Query.SetParameter("Id", Id);

	TemplateDataSource = Query.Execute().Unload().UnloadColumn("DataSource");
	
	Return TemplateDataSource;

EndFunction

Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.PrintFormTemplates.ProcessDataForMigrationToNewVersion";
	Handler.Version = "3.1.8.48";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("959d09e5-1dc3-4f32-833a-05ff17365e30");
	Handler.UpdateDataFillingProcedure = "Catalogs.PrintFormTemplates.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Điền thông tin về các nguồn dữ liệu in đối với mẫu in tự tạo. Trước khi hoàn thành xử lý, một số mẫu in có thể không sử dụng được.';
							|ru = 'Заполняет сведения об источниках данных печати для пользовательских печатных форм. До завершения обработки некоторые печатные формы могут быть недоступны.';
							|en = 'Fills information about print data sources for custom print forms. Some print forms might be unavailable until processing is completed.'; fa = 'Fills information about print data sources for custom print forms. Some print forms might be unavailable until processing is completed.';
							|it = 'Заполняет сведения об источниках данных печати для пользовательских печатных форм. До завершения обработки некоторые печатные формы могут быть недоступны.';
							|pl = 'Fills information about print data sources for custom print forms. Some print forms might be unavailable until processing is completed.';
							|tr = 'Kullanıcı yazdırma formu için yazdırma veri kaynakları hakkında bilgi kaydeder. Bazı yazdırma formlarına, veri işlemesi bitene kadar erişilemeyebilir.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.PrintFormTemplates.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.PrintFormTemplates.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.PrintFormTemplates.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Template data structure.
// 
// Returns:
//  Structure - New template data structure.:
//   * ObjectSaveFormat - EnumRef.ObjectsExportFormats
//   * SourcesTypes - Array of TypeDescription
//   * Presentation - String
//
Function NewTemplatesDataStructure()
	
	TemplatesDataStructure = New Structure;
	TemplatesDataStructure.Insert("ObjectSaveFormat", Enums.ObjectsExportFormats.EmptyRef());
	TemplatesDataStructure.Insert("SourcesTypes", New Array);
	TemplatesDataStructure.Insert("Presentation", "");
	
	Return TemplatesDataStructure;
	
EndFunction

#EndRegion

#EndIf