///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Exports objects in the specified format and writes them to a file.
//
// Parameters:
//  ExportCommands  - Structure
//                   - Array - One or more export commands.
//                            See PrintManagement.FormPrintCommands.
//  ListOfObjects - Array of CatalogRef, DocumentRef - References to the objects being saved.
//  SettingsForSaving - See PrintManagement.SettingsForSaving.
//
// Returns:
//  ValueTable:
//   * FileName - String - Filename.
//   * BinaryData - BinaryData - Print form file.
//
Function SaveByFormatToFile(ExportCommands, ListOfObjects, SettingsForSaving) Export
	
	TypesArray = New Array; // Array of TypeDescription
	
	For Each UploadObject In ListOfObjects Do
		
		Current_Type = TypeOf(UploadObject);
		If TypesArray.Find(Current_Type) = Undefined Then
			
			 TypesArray.Add(Current_Type);
			
		EndIf;
		
	EndDo;
	
	Result = New ValueTable;
	Result.Columns.Add("FileName", New TypeDescription("String"));
	Result.Columns.Add("BinaryData", New TypeDescription("BinaryData"));
	Result.Columns.Add("UploadObject", New TypeDescription(TypesArray));
	
	ListOfCommands = ExportCommands;
	If TypeOf(ExportCommands) <> Type("Array") Then
		ListOfCommands = CommonClientServer.ValueInArray(ExportCommands);
	EndIf;
	
	For Each ExportCommand In ListOfCommands Do
		
		//@skip-check query-in-loop - the request is used inside exception handling for previously unknown data.
		ExecuteExportToFile(ExportCommand, SettingsForSaving, ListOfObjects, Result);
		
	EndDo;
	
	If ValueIsFilled(Result) And SettingsForSaving.PackToArchive Then
		
		BinaryData = PrintManagement.PackToArchive(Result);
		Result.Clear();
		File = Result.Add();
		FileName = PrintManagement.FileName(GetTempFileName("zip"));
		File.FileName = FileName;
		File.BinaryData = BinaryData;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Internal

// See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject
Procedure OnDefineCommandsAttachedToObject(FormSettings, Sources, AttachedReportsAndDataProcessors, Commands) Export
	
	ListOfObjects = New Array;
	For Each Source In Sources.Rows Do
		ListOfObjects.Add(Source.Metadata);
	EndDo;
	
	IsDocumentJournal = Common.IsDocumentJournal(Sources.Rows[0].Metadata);
	
	If Sources.Rows.Count() = 1
	   And IsDocumentJournal Then
		ListOfObjects = Undefined;
	EndIf;
	
	FormName = FormSettings.FormName;
	ExportCommands = FormExportCommands(FormName, ListOfObjects);
	
	HandlerParametersKeys = "Handler, PrintManager, FormCaption, SaveFormat,
		|ShouldRunInBackgroundJob, IdentifierOfTemplate, SourceType";
	
	For Each ExportCommand In ExportCommands Do
		
		If ExportCommand.TurnedOff Then
			Continue;
		EndIf;
		
		Command = Commands.Add();
		FillPropertyValues(Command, ExportCommand,, "Handler");
		Command.Kind = "ExportObjectData";
		Command.MultipleChoice = True;
		Command.VisibilityInForms = ExportCommand.FormsList;
		Command.WriteMode = "WriteNewOnly";
		If ExportCommand.PrintObjectsTypes.Count() > 0 Then
			Command.ParameterType = New TypeDescription(ExportCommand.PrintObjectsTypes);
		EndIf;
		Command.Handler = "ExportObjectsToFilesInternalClient.ExecuteExportCommandHandler";
		Command.AdditionalParameters = New Structure(HandlerParametersKeys);
		FillPropertyValues(Command.AdditionalParameters, ExportCommand);
		
		ArrayOfSaveFormats = New Array;
		If ValueIsFilled(ExportCommand.SaveFormat) Then
			ArrayOfSaveFormats.Add(ExportCommand.SaveFormat);
		EndIf;
		
		Command.AdditionalParameters.SaveFormat = ArrayOfSaveFormats;
		If Command.Order = 0 Then
			Command.Order = 50;
		EndIf;
		
	EndDo;
	
	If ExportCommands.Count() > 0
	   And Not IsDocumentJournal
	   And Sources.Rows.Count() = 1
	   And AccessRight("Update", Metadata.InformationRegisters.UserPrintTemplates) Then
		
		MetadataObject = Sources.Rows[0].Metadata;
		ParameterType = New Array; // Array of Type
		ObjectType = Type(StrReplace(MetadataObject.FullName(), ".", "Ref."));
		ParameterType.Add(ObjectType);
		
		Command = Commands.Add();
		Command.Kind = "ExportObjectData";
		Command.Presentation = NStr("vi = 'Chuyển đến khuôn in tệp kết xuất';
									|ru = 'Перейти к макетам файлов выгрузки';
									|en = 'Go to export template files'; fa = 'Go to export template files';
									|it = 'Go to export template files';
									|pl = 'Go to export template files';
									|tr = 'Dosya yükleme şablonuna git'");
		Command.MultipleChoice = False;
		Command.Handler = "ExportObjectsToFilesInternalClient.OpenExportTemplatesForm";
		Command.ParameterType = New TypeDescription(ParameterType);
		Command.Importance = "SeeAlso";
		AdditionalParameters = Command.AdditionalParameters;
		AdditionalParameters.Insert("Owner", MetadataObject.FullName());
		
		Command.Order = 50;
		
	EndIf;
	
EndProcedure

// See AttachableCommandsOverridable.OnDefineAttachableCommandsKinds
Procedure OnDefineAttachableCommandsKinds(AttachableCommandsKinds) Export
	
	Kind = AttachableCommandsKinds.Add();
	Kind.Name = "ExportObjectData";
	Kind.SubmenuName = "SubmenuExportObjectData";
	Kind.Title = NStr("vi = 'Kết xuất vào tệp';
						|ru = 'Выгрузить в файл';
						|en = 'Export to file'; fa = 'خروج اطلاعات به فایل';
						|it = 'Caricare nel file';
						|pl = 'Eksportuj do pliku';
						|tr = 'Dosyaya aktar'");
	Kind.Order = 40;
	Kind.Picture = PictureLib.SaveFileAs;
	Kind.Representation = ButtonRepresentation.PictureAndText;
	
EndProcedure

// Returns a list of print commands for the specified print form.
//
// Parameters:
//  Form - ClientApplicationForm
//        - String - Form or the full name of the form that is the destination for
//                   the export commands.
//  ListOfObjects - Array - Collection of metadata objects whose print commands are to be used when generating
//                            a list of print commands for the given form.
// Returns:
//   See PrintManagement.CreatePrintCommandsCollection
//
Function FormExportCommands(Form, ListOfObjects = Undefined) Export
	
	If TypeOf(Form) = Type("ClientApplicationForm") Then
		FormName = Form.FormName;
	Else
		FormName = Form;
	EndIf;
	
	MetadataObject = Metadata.FindByFullName(FormName);
	If MetadataObject <> Undefined And Not Metadata.CommonForms.Contains(MetadataObject) Then
		MetadataObject = MetadataObject.Parent();
	Else
		MetadataObject = Undefined;
	EndIf;
	
	If MetadataObject <> Undefined Then
		MORef = Common.MetadataObjectID(MetadataObject);
	EndIf;
	
	ExportCommands = PrintManagement.CreatePrintCommandsCollection();
	
	If ListOfObjects = Undefined
	   And MetadataObject = Undefined Then
		Return ExportCommands;
	EndIf;
	
	If ListOfObjects <> Undefined Then
		
		FillExportCommandsForObjectList(ListOfObjects, ExportCommands);
		
	Else
		
		IsDocumentJournal = Common.IsDocumentJournal(MetadataObject);
		If IsDocumentJournal Then
			
			FillExportCommandsForObjectList(MetadataObject.RegisteredDocuments, ExportCommands);
			
		Else
			
			ExportCommandsToAdd = ObjectExportCommands(MetadataObject);
			For Each ExportCommand In ExportCommandsToAdd Do
				FillPropertyValues(ExportCommands.Add(), ExportCommand);
			EndDo;
			
		EndIf;
		
	EndIf;
	
	For Each ExportCommand In ExportCommands Do
		
		If ExportCommand.Order = 0 Then
			ExportCommand.Order = 50;
		EndIf;
		
	EndDo;
	
	ExportCommands.Sort("Order Asc, Presentation Asc");
	
	NameParts = StrSplit(FormName, ".");
	ShortFormName = NameParts[NameParts.Count() - 1];
	
	// Filter by form names
	CommandsCount = ExportCommands.Count();
	For LineNumber = 1 To CommandsCount Do
		
		RowIndex = CommandsCount - LineNumber;
		ExportCommand = ExportCommands[RowIndex];
		FormsList = StrSplit(ExportCommand.FormsList, ",", False);
		If FormsList.Count() > 0 And FormsList.Find(ShortFormName) = Undefined Then
			ExportCommands.Delete(ExportCommand);
		EndIf;
		
	EndDo;
	
	PrintManagement.DefinePrintCommandsVisibilityByFunctionalOptions(ExportCommands, Form);
	
	Return ExportCommands;
	
EndFunction

// Generates an export object structure based on the given export template.
// 
// Parameters:
//  Template - SpreadsheetDocument - Export template
//  SaveFormat - EnumRef.ObjectsExportFormats
//  ObjectsArray - Array of CatalogRef, DocumentRef - References to the objects being saved.
//  LanguageCode - String - Language code
// 
// Returns:
//  Map of KeyAndValue:
//  * Key - AnyRef
//  * Value - See NewDataStructure
//
Function GenerateStructureForExport(Template, SaveFormat, ObjectsArray, LanguageCode) Export
	
	If TypeOf(SaveFormat) <> Type("EnumRef.ObjectsExportFormats") Then
		Return Undefined;
	EndIf;
	
	Result = New Map;
	
	FieldsLayout = PrintManagement.FieldsLayout(Template);
	PrintData = PrintManagement.PrintData(ObjectsArray, FieldsLayout, LanguageCode);
	FieldFormatSettings = PrintData["FieldFormatSettings"];
	ParameterFieldTypes = PrintData["ParameterFieldTypes"];
	TemplateAreas = PrintManagement.TemplateAreas(Template, PrintData);
	AreasTables = TemplateAreas.AreasTables;
	
	TemplateTables = TemplateTables(Template, AreasTables);
	TableOfAreas = TableOfAreas(Template); 
	SupplementAreasTableWithTableData(Template, TableOfAreas, TemplateTables);
	
	Additional_Data = New Structure;
	Additional_Data.Insert("Template", Template);
	Additional_Data.Insert("FieldFormatSettings", FieldFormatSettings);
	Additional_Data.Insert("ParameterFieldTypes", ParameterFieldTypes);
	Additional_Data.Insert("TableOfAreas", TableOfAreas);
	Additional_Data.Insert("TemplateTables", TemplateTables);
	Additional_Data.Insert("LanguageCode", LanguageCode);
	Additional_Data.Insert("SaveFormat", SaveFormat);
	
	If SaveFormat = Enums.ObjectsExportFormats.DBF Then
		
		Result = GenerateExportDataForDBF(
			ObjectsArray,
			PrintData,
			Additional_Data);
		
	Else
		
		Result = GenerateExportData(
			ObjectsArray,
			PrintData,
			Additional_Data);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//  Template - SpreadsheetDocument
//  AreasTables -  Map of KeyAndValue:
//   * Key - String - Table address
//   * Value - String - Table name
// 
// Returns:
//  ValueTable:
// * Name - String
// * Top - Number 
// * Bottom - Number
// * DetailsParameter - String
// 
Function TemplateTables(Template, AreasTables) Export
	
	TemplateTable = New ValueTable;
	TemplateTable.Columns.Add("Name", New TypeDescription("String"));
	TemplateTable.Columns.Add("Top", New TypeDescription("Number"));
	TemplateTable.Columns.Add("Bottom", New TypeDescription("Number"));
	TemplateTable.Columns.Add("DetailsParameter", New TypeDescription("String"));
	
	For Each CrntMap In AreasTables Do
		
		AreaID = CrntMap.Key;
		TableName = CrntMap.Value;
		
		AddressArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(AreaID, ":");
		RowNumberTop = Number(StrReplace(AddressArray[0], "R", ""));
		RowNumberBottom = Number(StrReplace(AddressArray[1], "R", ""));
		
		NewRow = TemplateTable.Add();
		NewRow.Name = TableName;
		NewRow.Top = RowNumberTop;
		NewRow.Bottom = RowNumberBottom;
		
		TableCellArea = Template.Area("R" + XMLString(RowNumberTop) + "C2:" + "R" + XMLString(RowNumberTop) + "C2");
		NewRow.DetailsParameter = TableCellArea.DetailsParameter;
		
	EndDo;
	TemplateTable.Sort("Top, Bottom");
	
	Return TemplateTable;

EndFunction

// Returns:
//  Array of EnumRef.ObjectsExportFormats - Export formats without using the spreadsheet.
//
Function ExportFormatsWithoutUsingSpreadsheet() Export
	
	FormatArray = New Array; // Array of EnumRef.ObjectsExportFormats
	FormatArray.Add(Enums.ObjectsExportFormats.DBF);
	FormatArray.Add(Enums.ObjectsExportFormats.JSON);
	FormatArray.Add(Enums.ObjectsExportFormats.XML);
	
	Return FormatArray;
	
EndFunction

// Parameters:
//  StructureWithData - Structure
//  FullFileName - String - Full filename
//  ExportPresentation - String - Export presentation
//
Procedure ExecuteExportToXML(StructureWithData, FullFileName, ExportPresentation) Export
	
	BodyName = NStr("vi = 'Chứng từ';
					|ru = 'Документ';
					|en = 'Document'; fa = 'سند';
					|it = 'Document';
					|pl = 'Document';
					|tr = 'Belge'");
	XMLWriter = New XMLWriter; 
	If Not IsBlankString(FullFileName) Then
		XMLWriter.OpenFile(FullFileName, "UTF-8"); // Open the file for writing and specify the encoding
	Else
		XMLWriter.SetString();
	EndIf;
	XMLWriter.WriteXMLDeclaration(); // Write the XML declaration
	XMLWriter.WriteStartElement(BodyName);
	
	DataVolume = StructureWithData.DataVolume;
	
	For DataNumber = 1 To DataVolume Do
		
		DataNumberAsString = Format(DataNumber, "NFD=0; NG=");
		Data = StructureWithData["Data_" + DataNumberAsString];
		ProcessDataXMLArea(XMLWriter, Data);
		
	EndDo;
	
	XMLWriter.WriteEndElement();
	ExportPresentation = XMLWriter.Close();
	
EndProcedure

// Parameters:
//  StructureWithData - Structure
//  FullFileName - String - Full filename
//  ExportPresentation - String - Export presentation
//
Procedure ExecuteExportToJSON(StructureWithData, FullFileName, ExportPresentation) Export
	
	JSONWriterSettings = New JSONWriterSettings(, Chars.Tab);
		
	JSONWriter = New JSONWriter;
	If Not IsBlankString(FullFileName) Then
		JSONWriter.OpenFile(FullFileName,,, JSONWriterSettings);
	Else
		JSONWriter.SetString(JSONWriterSettings);
	EndIf;
	DataIntoJSON = New Structure;
	ProcessDataJSONArea(StructureWithData, DataIntoJSON);
	
	WriteJSON(JSONWriter, DataIntoJSON);
	ExportPresentation = JSONWriter.Close();
	
EndProcedure

// Check if the export format matches the saving format.
// 
// Returns:
//  Map of KeyAndValue:
//  * Key - EnumRef.ObjectsExportFormats
//  * Value - String
// 
Function ExportFormatSaveFormatMap() Export
	
	MapFormatExtension = New Map;
	MapFormatExtension.Insert(Enums.ObjectsExportFormats.DBF, "DBF");
	MapFormatExtension.Insert(Enums.ObjectsExportFormats.JSON, "json");
	MapFormatExtension.Insert(Enums.ObjectsExportFormats.XML, "xml");
	MapFormatExtension.Insert(Enums.ObjectsExportFormats.ANSITXT, "txt");
	MapFormatExtension.Insert(Enums.ObjectsExportFormats.TXT, "txt");
	MapFormatExtension.Insert(Enums.ObjectsExportFormats.HTML5, "html");
	MapFormatExtension.Insert(Enums.ObjectsExportFormats.XLS, "xls");
	MapFormatExtension.Insert(Enums.ObjectsExportFormats.XLSX, "xlsx");
	MapFormatExtension.Insert(Enums.ObjectsExportFormats.MXL, "mxl");
	
	Return MapFormatExtension;
	
EndFunction

// Parameters:
//  MetadataObject - CatalogRef, DocumentRef - References to the objects being saved.
// 
// Returns:
//  ValueTable - See PrintManagement.FormPrintCommands
// 
Function ObjectExportCommandsAvailableForAttachments(MetadataObject) Export
	
	PrintCommandsSources = PrintManagement.PrintCommandsSources();
	If PrintCommandsSources.Find(MetadataObject) <> Undefined Then
		
		ExportCommands = ObjectExportCommands(MetadataObject);
		
	Else
		
		ExportCommands = PrintManagement.CreatePrintCommandsCollection();
		
	EndIf;
	
	Return ExportCommands;
	
EndFunction

#EndRegion

#Region Private

#Region ExportStructureGenerationProcedures

// Parameters:
//  MetadataObject - CatalogRef, DocumentRef - References to the objects being saved.
// 
// Returns:
//  See PrintManagement.FormPrintCommands
// 
Function ObjectExportCommands(MetadataObject)
	
	ExportCommands = PrintManagement.CreatePrintCommandsCollection();
	If TypeOf(MetadataObject) <> Type("MetadataObject") Then
		Return ExportCommands;
	EndIf;
	
	Sources = AttachableCommands.CommandsSourcesTree();
	APISettings = AttachableCommands.AttachableObjectsInterfaceSettings();
	AttachedReportsAndDataProcessors = AttachableCommands.AttachableObjectsTable(APISettings);
	Source = AttachableCommands.RegisterSource(
		MetadataObject,
		Sources,
		AttachedReportsAndDataProcessors,
		APISettings);
	
	If Source.Manager = Undefined Then
		Return ExportCommands;
	EndIf;
	
	AddObjectExportCommands(ExportCommands, MetadataObject);
	
	ExportCommands.Sort("Order Asc, Presentation Asc");
	PrintManagement.FixTagCheckingHandlingBeforePrinting(ExportCommands, MetadataObject);
	PrintManagement.DefinePrintCommandsVisibilityByFunctionalOptions(ExportCommands);
	
	ExportCommands.Indexes.Add("UUID");
	
	Return ExportCommands;
	
EndFunction

// Generates a value table with export command details
// 
// Parameters:
//  ExportCommands - ValueTable:
// * Id - String
// * Presentation - String 
// * PrintManager - String
// * PrintObjectsTypes - Array of AnyRef
// * Handler - String 
// * Order - Number 
// * Picture - Picture 
// * FormsList - String 
// * PlacingLocation - String
// * FormCaption - String 
// * FunctionalOptions - String 
// * VisibilityConditions - Array of Structure:
//     ** ComparisonType - DataCompositionComparisonType
//     ** Value - AnyRef
//     ** Attribute - String 
// * CheckPostingBeforePrint - Boolean
// * SkipPreview - Boolean 
// * SaveFormat - EnumRef.ObjectsExportFormats
// * OverrideCopiesUserSetting - Boolean
// * AddExternalPrintFormsToSet - Boolean 
// * FixedSet - Boolean 
// * AdditionalParameters - Structure 
// * DontWriteToForm - Boolean 
// * FileSystemExtensionIsRequired - Boolean
// * HiddenByFunctionalOptions - Boolean 
// * UUID - String 
// * TurnedOff - Boolean 
// * FormCommandName - String
// * VisibilityConditionsByObjectTypes - Map of KeyAndValue:
//     ** Key - TypeDescription - Object type
//     ** Value - Structure 
// * ShouldRunInBackgroundJob - Boolean
// * IdentifierOfTemplate - String
// * SourceType - Type 
//  MetadataObject - MetadataObject - Metadata object
//
Procedure AddObjectExportCommands(ExportCommands, MetadataObject)
	
	Owner = Common.MetadataObjectID(MetadataObject, False);
	If Owner = Undefined Then
		Return;
	EndIf;
	
	If ExportCommands.Columns.Find("IdentifierOfTemplate") = Undefined Then
		ExportCommands.Columns.Add("IdentifierOfTemplate", New TypeDescription("String"));
	EndIf;
	If ExportCommands.Columns.Find("SourceType") = Undefined Then
		ExportCommands.Columns.Add("SourceType", New TypeDescription("Type"));
	EndIf;
	
	QueryText =
	"SELECT
	|	PrintFormTemplates.Id AS Id,
	|	CASE
	|		WHEN VALUETYPE(PrintFormTemplatesDataSources.DataSource) = TYPE(Catalog.MetadataObjectIDs)
	|			THEN VALUETYPE(CAST(PrintFormTemplatesDataSources.DataSource AS Catalog.MetadataObjectIDs).EmptyRefValue)
	|		WHEN VALUETYPE(PrintFormTemplatesDataSources.DataSource) = TYPE(Catalog.ExtensionObjectIDs)
	|			THEN VALUETYPE(CAST(PrintFormTemplatesDataSources.DataSource AS Catalog.ExtensionObjectIDs).EmptyRefValue)
	|		ELSE UNDEFINED
	|	END AS SourceType,
	|	PrintFormTemplates.Presentation AS Presentation,
	|	PrintFormTemplates.VisibilityCondition AS VisibilityConditions,
	|	PrintFormTemplates.Ref AS Ref,
	|	PrintFormTemplates.ObjectSaveFormat AS SaveFormat
	|FROM
	|	Catalog.PrintFormTemplates.DataSources AS PrintFormTemplatesDataSources
	|		INNER JOIN Catalog.PrintFormTemplates AS PrintFormTemplates
	|		ON PrintFormTemplatesDataSources.Ref = PrintFormTemplates.Ref
	|WHERE
	|	PrintFormTemplatesDataSources.DataSource = &Owner
	|	AND PrintFormTemplates.Used
	|	AND PrintFormTemplates.TemplateForObjectExport
	|	AND NOT PrintFormTemplates.DeletionMark
	|	AND PrintFormTemplates.ObjectSaveFormat <> VALUE(Enum.ObjectsExportFormats.EmptyRef)";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Owner", Owner);
	Result = Query.Execute();
	Selection = Result.Select();
	
	HandlerParametersKeys = "IdentifierOfTemplate,SourceType,SaveFormat";
	
	While Selection.Next() Do
		
		ExportCommand = ExportCommands.Add();
		FillPropertyValues(ExportCommand, Selection);
		ExportCommand.Id = "PF_" + String(ExportCommand.Id);
		ExportCommand.PrintManager = "PrintManagement";
		ExportCommand.IdentifierOfTemplate = String(Selection.Id);
		ExportCommand.UUID = String(Selection.Id);
		ExportCommand.ShouldRunInBackgroundJob = False;
		
		ExportCommand.AdditionalParameters = New Structure(HandlerParametersKeys);
		ExportCommand.AdditionalParameters.IdentifierOfTemplate = String(Selection.Id);
		ExportCommand.AdditionalParameters.SourceType = Selection.SourceType;
		ExportCommand.AdditionalParameters.SaveFormat = Selection.SaveFormat;
		
		VisibilityConditionsStorage = Selection.VisibilityConditions; // ValueStorage
		VisibilityConditions = VisibilityConditionsStorage.Get();
		
		If ValueIsFilled(VisibilityConditions) Then
			
			For Each Condition In VisibilityConditions Do
				
				AttachableCommands.AddCommandVisibilityCondition(
					ExportCommand,
					Condition.Attribute,
					Condition.Value,
					Condition.ComparisonType);
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function GenerateDataForExport(Val PrintManagerName, ObjectsTableByTemplates, Val LanguageCode = Undefined)
	
	PrintFormsCollection = PrintManagement.PreparePrintFormsCollection(New Array);
	PrintFormsCollection.Columns.Add(
		"SaveFormat",
		New TypeDescription("EnumRef.ObjectsExportFormats"));
	PrintFormsCollection.Columns.Add("UnloadingStructure");
	
	OutputParameters = PrintManagement.PrepareOutputParametersStructure();
	If ValueIsFilled(LanguageCode) Then
		OutputParameters.LanguageCode = LanguageCode;
	EndIf;
	
	TemplatesNames = ObjectsTableByTemplates.UnloadColumn("TemplateName");
	DataOfTemplates = Catalogs.PrintFormTemplates.DataOfTemplates(TemplatesNames);
	ArrayOfFormatsNotUsingSpreadsheet = ExportFormatsWithoutUsingSpreadsheet();
	
	ObjectsToExport = New ValueList;
	
	For Each TableRow In ObjectsTableByTemplates Do
		
		TemplateName = TableRow.TemplateName;
		ObjectsArray = TableRow.ObjectsArray;
		
		SaveFormat = DataOfTemplates[TemplateName].ObjectSaveFormat;
		AllowedTypesOfExportObjects = DataOfTemplates[TemplateName].SourcesTypes;
		TemplatePresentation = DataOfTemplates[TemplateName].Presentation;
		
		Id = TemplateName;
		
		ObjectsMatchingExportTemplate = CheckIfObjectsMatchExportTemplate(
			ObjectsArray,
			AllowedTypesOfExportObjects);
		
		TempCollectionForSinglePrintForm = PrintManagement.PreparePrintFormsCollection(Id);
		IsExportWithoutUsingSpreadsheet = (ArrayOfFormatsNotUsingSpreadsheet.Find(SaveFormat) <> Undefined);
		
		SaveFormatType = New TypeDescription("EnumRef.ObjectsExportFormats");
		TempCollectionForSinglePrintForm.Columns.Add("SaveFormat", SaveFormatType);
		TempCollectionForSinglePrintForm.Columns.Add("UnloadingStructure");
		
		If ObjectsMatchingExportTemplate <> Undefined Then
			
			If IsExportWithoutUsingSpreadsheet Then
				
				InternalParameters = New Structure;
				InternalParameters.Insert("OutputParameters", OutputParameters);
				InternalParameters.Insert("SaveFormat", SaveFormat);
				
				// @skip-check query-in-loop - Small cycle
				StartPreparationForExport(
					ObjectsMatchingExportTemplate,
					TempCollectionForSinglePrintForm,
					InternalParameters);
			Else
				
				PrintParameters = New Structure;
				// @skip-check query-in-loop - Small cycle
				PrintManagement.Print(
					ObjectsMatchingExportTemplate,
					PrintParameters,
					TempCollectionForSinglePrintForm,
					ObjectsToExport,
					OutputParameters);
					
			EndIf;
			
		EndIf;
		
		// Update the collection.
		Cancel = TempCollectionForSinglePrintForm.Count() = 0;
		UpdateCollection(
			PrintFormsCollection,
			TempCollectionForSinglePrintForm,
			TemplateName,
			SaveFormat,
			Cancel);
		
		// Raise an exception based on the error.
		If Cancel Then
			
			MessageTemplate = NStr("vi = 'Không thể thực hiện kết xuất theo khuôn in ""%1"" (""%2""). Hãy liên hệ với người quản trị.';
									|ru = 'Не удалось выполнить выгрузку по шаблону ""%1"" (""%2""). Обратитесь к администратору.';
									|en = 'Failed to export using the template ""%1"" (""%2""). Contact the administrator.'; fa = 'Failed to export using the template ""%1"" (""%2""). Contact the administrator.';
									|it = 'Failed to export using the template ""%1"" (""%2""). Contact the administrator.';
									|pl = 'Failed to export using the template ""%1"" (""%2""). Contact the administrator.';
									|tr = '""%1"" şablonu üzerinde yükleme başarısız oldu (""%2""). Yöneticiye başvurun.'");
			ErrorMessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate,
				TemplatePresentation,
				TemplateName);
			Raise ErrorMessageText;
			
		EndIf;
		
	EndDo;
	
	Result = New Structure;
	Result.Insert("PrintFormsCollection", PrintFormsCollection);
	Result.Insert("ObjectsToExport", ObjectsToExport);
	Result.Insert("OutputParameters", OutputParameters);
	
	Return Result;
	
EndFunction

Function CheckIfObjectsMatchExportTemplate(ObjectsArray, AllowedTypesOfExportObjects)
	
	// Validate exported objects against the selected export template.
	ObjectsMatchingExportTemplate = ObjectsArray;
	If AllowedTypesOfExportObjects <> Undefined And AllowedTypesOfExportObjects.Count() > 0 Then
		
		If TypeOf(ObjectsArray) = Type("Array") Then
			
			ObjectsMatchingExportTemplate = New Array;
			For Each Object In ObjectsArray Do
				
				If AllowedTypesOfExportObjects.Find(TypeOf(Object)) = Undefined Then
					NotifyExportUnavailable(Object);
				Else
					ObjectsMatchingExportTemplate.Add(Object);
				EndIf;
				
			EndDo;
			
			If ObjectsMatchingExportTemplate.Count() = 0 Then
				ObjectsMatchingExportTemplate = Undefined;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return ObjectsMatchingExportTemplate;
	
EndFunction

Procedure UpdateCollection(PrintFormsCollection, TemporaryCollection, TemplateName, SaveFormat, Cancel)
	
	For Each TempPrintForm In TemporaryCollection Do
		
		If Not TempPrintForm.OfficeDocuments = Undefined Then
			TempPrintForm.SpreadsheetDocument = New SpreadsheetDocument;
		EndIf;
		
		If Not PrintManagement.TemplateExists(TempPrintForm.FullTemplatePath) Then
			TempPrintForm.FullTemplatePath = "";
		EndIf;
		
		If TempPrintForm.SpreadsheetDocument <> Undefined
		 Or TempPrintForm.UnloadingStructure <> Undefined Then
			
			NewCollection = PrintFormsCollection.Add();
			FillPropertyValues(NewCollection, TempPrintForm);
			If TemporaryCollection.Count() = 1 Then
				
				NewCollection.TemplateName = TemplateName;
				NewCollection.UpperCaseName = Upper(TemplateName);
				
			EndIf;
			
			If TempPrintForm.SpreadsheetDocument <> Undefined Then
				
				NewCollection.Protection = TempPrintForm.SpreadsheetDocument.Protection;
				
			EndIf;
			
			NewCollection.SaveFormat = SaveFormat;
			
		Else
			Cancel = True;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure StartPreparationForExport(ObjectsArray, PrintFormsCollection, InternalParameters)
	
	OutputParameters = InternalParameters.OutputParameters;
	SaveFormat = InternalParameters.SaveFormat;
	
	If PrintFormsCollection.Columns.Find("UnloadingStructure") = Undefined Then
		PrintFormsCollection.Columns.Add("UnloadingStructure");
	EndIf;
	
	If PrintFormsCollection.Columns.Find("SaveFormat") = Undefined Then
		
		SaveFormatType = New TypeDescription("EnumRef.ObjectsExportFormats");
		PrintFormsCollection.Columns.Add("SaveFormat", SaveFormatType);
		
	EndIf;
	
	LanguageCode = OutputParameters.LanguageCode;
	
	ObjectManager = Common.ObjectManagerByRef(ObjectsArray[0]);
	If PrintManagement.ObjectPrintingSettings(ObjectManager).OnSpecifyingRecipients Then
		
		ObjectManager.OnSpecifyingRecipients(
			OutputParameters.SendOptions,
			ObjectsArray,
			PrintFormsCollection);
			
	EndIf;
	
	For Each PrintForm In PrintFormsCollection Do
		
		PrintForm.OutputInOtherLanguagesAvailable = True;
		PrintForm.FullTemplatePath = PrintForm.TemplateName;
		PrintForm.TemplateSynonym = PrintManagement.TemplatePresentation(PrintForm.FullTemplatePath, LanguageCode);
		// @skip-check query-in-loop - A small number of iterations of the loop with a query to the register table.Custom Printout 
		// @skip-check query-in-loop - A few loop iterations that query the table
// "InformationRegister.UserPrintTemplates", which contains just a handful of records.
		Template = PrintManagement.PrintFormTemplate(PrintForm.FullTemplatePath, LanguageCode);
		Result = GenerateStructureForExport(
			Template,
			SaveFormat,
			ObjectsArray,
			LanguageCode);
		
		If TypeOf(Result) = Type("Map") Then
			PrintForm.UnloadingStructure = Result;
		Else
			PrintForm.UnloadingStructure = Undefined;
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns:
//  Structure :
// * ThisIsTable - Boolean
// * IsTableRow - Boolean
// * IsArea - Boolean
// * TableName - String
// * ColumnsNames - Structure
// * AreaName - String
// * TableRowPresentation - String
// * DataVolume - Number
// * ColumnTypes_ - Map of KeyAndValue:
// ** Key - String
// ** Value - TypeDescription
// 
Function NewDataStructure()
	
	Structure = New Structure;
	Structure.Insert("ThisIsTable", False);
	Structure.Insert("IsTableRow", False);
	Structure.Insert("IsArea", False);
	Structure.Insert("IsParameter", False);
	Structure.Insert("TableName", "");
	Structure.Insert("ColumnsNames", New Structure);
	Structure.Insert("AreaName", "");
	Structure.Insert("TableRowPresentation", "");
	Structure.Insert("DataVolume", 0);
	Structure.Insert("ColumnTypes_", New Map);
	
	Return Structure;
	
EndFunction

Function ParseAreaName(FullAreaName, Separator)
	
	Result = New Structure;
	Result.Insert("AreaName", FullAreaName);
	Result.Insert("NestedAreaName", NStr("vi = 'СтрокаТаблицы';
										|ru = 'СтрокаТаблицы';
										|en = 'TableRow'; fa = 'TableRow';
										|it = 'TableRow';
										|pl = 'TableRow';
										|tr = 'StringTables'"));
	
	If StrFind(FullAreaName, Separator,, 2) = 0 Then
		Return Result;
	EndIf;
	
	NamesArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(FullAreaName, Separator, True);
	If NamesArray.Count() > 1 Then
		
		PositionNumber = StrFind(FullAreaName, NamesArray[0]);
		AreaName = Left(FullAreaName, PositionNumber - 1) + NamesArray[0];
		NestedAreaName = Right(FullAreaName, StrLen(FullAreaName) - StrLen(AreaName) - 1);
		
		Result.AreaName = AreaName;
		Result.NestedAreaName = NestedAreaName;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Returns:
//  Structure - New parameter structure.:
// * IsArea - Boolean
// * FullPath - String
// * Value - Arbitrary
// * ConditionalAppearance - String
// * ParameterName - String
// * Output - Boolean
// 
Function ParameterNewStructure()
	
	Structure = New Structure;
	Structure.Insert("IsParameter", True);
	Structure.Insert("IsArea", False);
	Structure.Insert("FullPath", "");
	Structure.Insert("Value");
	Structure.Insert("ConditionalAppearance", "");
	Structure.Insert("ParameterName", "");
	Structure.Insert("FieldType", "");
	Structure.Insert("Output", True);
	Structure.Insert("LanguageCode", "");
	
	Return Structure;
	
EndFunction

// Returns:
//  Structure - New structure for parameter calculation.:
// * FieldFormatSettings - Map of KeyAndValue:
//   ** Key - String
//   ** Value - String
// * ParameterFieldTypes - Map of KeyAndValue:
//   ** Key - String
//   ** Value - TypeDescription
// * LanguageCode - String
// * Template - SpreadsheetDocument
// * TabularSectionRowNumber - Number
// * ParameterNameRowNumber - Number
// * ParameterLineNumber - Number
// * ParameterNameColumnNumber - Number
// * ParameterColumnNumber - Number
//
Function NewStructureForParameterCalculation()
	
	Structure = New Structure;
	Structure.Insert("FieldFormatSettings", New Map);
	Structure.Insert("ParameterFieldTypes", New Map);
	Structure.Insert("LanguageCode", "");
	Structure.Insert("Template", New SpreadsheetDocument);
	Structure.Insert("TableName", "");
	Structure.Insert("TabularSectionRowNumber", 0);
	Structure.Insert("ParameterNameRowNumber", 0);
	Structure.Insert("ParameterLineNumber", 0);
	Structure.Insert("ParameterNameColumnNumber", 1);
	Structure.Insert("ParameterColumnNumber", 2);
	
	Return Structure;
	
EndFunction

Function CellBelongsToArea(TableOfAreas, ArrayOfProcessedOnes, LineNumber)
	
	Result = New Structure;
	Result.Insert("CellBelongsToArea", False);
	Result.Insert("ProcessedAreaRow", Undefined);
	
	For Each ProcessedAreaRow In TableOfAreas Do
		
		Result.ProcessedAreaRow = ProcessedAreaRow;
		If ArrayOfProcessedOnes.Find(ProcessedAreaRow.Name) <> Undefined
		   Or ProcessedAreaRow.IsOutputConditionArea Then
			Continue;
		EndIf;
		
		If ProcessedAreaRow.Top <= LineNumber
		   And ProcessedAreaRow.Bottom >= LineNumber Then
			
			Result.CellBelongsToArea = True;
			Break;
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function CellBelongsToTable(TemplateTables, LineNumber)
	
	Result = New Structure;
	Result.Insert("ThisIsTable", False);
	Result.Insert("TemplateTableCurRow", Undefined);
	
	For Each TemplateTableCurRow In TemplateTables Do
		
		If TemplateTableCurRow.Top <= LineNumber
		   And TemplateTableCurRow.Bottom >= LineNumber Then
			
			Result.ThisIsTable = True;
			Result.TemplateTableCurRow = TemplateTableCurRow;
			Break;
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function StructureOfCurrentData(ProcessedAreaRow, ArrayOfProcessedOnes, OwnerTableName = Undefined, OwnerRowNumber = Undefined)
	
	CurrentData = New Structure;
	CurrentData.Insert("TableRow", ProcessedAreaRow);
	CurrentData.Insert("ArrayOfProcessedOnes", ArrayOfProcessedOnes);
	CurrentData.Insert("OwnerTableName", OwnerTableName);
	CurrentData.Insert("OwnerRowNumber", OwnerRowNumber);
	
	Return CurrentData;
	
EndFunction

Function GenerateExportData(ObjectsArray, PrintData, Additional_Data)
	
	Result = New Map;
	
	For Each Ref In ObjectsArray Do
		
		ObjectData = PrintData[Ref];
		DataSource = New Map;
		CommonClientServer.SupplementMap(DataSource, ObjectData);
		
		SourceData = New Structure;
		SourceData.Insert("ObjectData", ObjectData);
		SourceData.Insert("DataSourcePassed", DataSource);
		
		ArrayOfProcessedOnes = New Array;
		DataCnt = 0;
		AreaName = NStr("vi = 'Chứng từ';
						|ru = 'Документ';
						|en = 'Document'; fa = 'سند';
						|it = 'Document';
						|pl = 'Document';
						|tr = 'Belge'");
		
		StructureWithData = NewDataStructure();
		StructureWithData.AreaName = AreaName;
		ObjectToStructure(StructureWithData, SourceData, Additional_Data, ArrayOfProcessedOnes, DataCnt);
		
		Result.Insert(Ref, StructureWithData);
		
	EndDo;
	
	Return Result;
	
EndFunction

Procedure ObjectToStructure(StructureWithData, SourceData, Additional_Data, ArrayOfProcessedOnes, DataCnt)
	
	Template = Additional_Data.Template;
	TableOfAreas = Additional_Data.TableOfAreas;
	
	For LineNumber = 1 To Template.TableHeight Do
		
		Area = Template.Area(LineNumber, 1);
		CellText = Area.Text;
		
		If IsBlankString(CellText) Then
			Continue;
		EndIf;
		
		CheckResult = CellBelongsToArea(TableOfAreas, ArrayOfProcessedOnes, LineNumber);
		CellBelongsToArea = CheckResult.CellBelongsToArea;
		ProcessedAreaRow = CheckResult.ProcessedAreaRow;
		
		If Not CellBelongsToArea Then
			
			TemplateRowToStructure(
				StructureWithData,
				SourceData,
				Additional_Data,
				ArrayOfProcessedOnes,
				LineNumber,
				ProcessedAreaRow,
				DataCnt);
			
		Else
			
			CurrentData = StructureOfCurrentData(ProcessedAreaRow, ArrayOfProcessedOnes);
			AreaStructure = TemplateAreaToStructure(SourceData, Additional_Data, CurrentData);
			
			If AreaStructure <> Undefined
			   And AreaStructure.DataVolume > 0 Then
				
				DataCnt = DataCnt + 1;
				DataCntAsString = XMLString(DataCnt);
				StructureWithData.Insert("Data_" + DataCntAsString, AreaStructure);
				StructureWithData.DataVolume = DataCnt;
				
			EndIf;
			
			LineNumber = ProcessedAreaRow.Bottom;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure TemplateRowToStructure(StructureWithData, SourceData, Additional_Data, ArrayOfProcessedOnes, LineNumber, ProcessedAreaRow, DataCnt)
	
	TemplateTables = Additional_Data.TemplateTables;
	TableOfAreas = Additional_Data.TableOfAreas;
	TableName = "";
	TabularSectionRowNumber = 0;
	
	CheckResult = CellBelongsToTable(TemplateTables, LineNumber);
	ThisIsTable = CheckResult.ThisIsTable;
	TemplateTableCurRow = CheckResult.TemplateTableCurRow;
	
	If ThisIsTable Then
		
		RowsAreasTable = TableOfAreas.Copy();
		RowsAreasTable.Clear();
		ProcessedAreaRow = RowsAreasTable.Add();
		FillPropertyValues(ProcessedAreaRow, TemplateTableCurRow);
		ProcessedAreaRow.TableName = ProcessedAreaRow.Name;
		ProcessedAreaRow.ThisIsTable = True;
		IsOutputCondition = Not IsBlankString(ProcessedAreaRow.DetailsParameter);
		ProcessedAreaRow.IsOutputConditionArea = IsOutputCondition;
		
		CurrentData = StructureOfCurrentData(ProcessedAreaRow, ArrayOfProcessedOnes);
		AreaStructure = TemplateAreaToStructure(SourceData, Additional_Data, CurrentData);
		
		If AreaStructure <> Undefined
		   And AreaStructure.DataVolume > 0 Then
			
			DataCnt = DataCnt + 1;
			DataCntAsString = XMLString(DataCnt);
			StructureWithData.Insert("Data_" + DataCntAsString, AreaStructure);
			StructureWithData.DataVolume = DataCnt;
			
		EndIf;
		
		LineNumber = ProcessedAreaRow.Bottom;
		
	Else
		
		DataForParameterCalculation = NewStructureForParameterCalculation();
		FillPropertyValues(DataForParameterCalculation, Additional_Data);
		DataForParameterCalculation.TableName = TableName;
		DataForParameterCalculation.TabularSectionRowNumber = TabularSectionRowNumber;
		DataForParameterCalculation.ParameterNameRowNumber = LineNumber;
		DataForParameterCalculation.ParameterLineNumber = LineNumber;
		
		ParameterDataStructure = DataOfParameter(SourceData, DataForParameterCalculation);
		
		AddToStructure = (ParameterDataStructure <> Undefined
			And ParameterDataStructure.Output);
		
		If AddToStructure Then
			
			DataCnt = DataCnt + 1;
			DataCntAsString = XMLString(DataCnt);
			StructureWithData.Insert("Data_" + DataCntAsString, ParameterDataStructure);
			StructureWithData.DataVolume = DataCnt;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Function GenerateExportDataForDBF(Val ObjectsArray, Val PrintData, Val Additional_Data)
	
	Result = New Map;
	
	For Each Ref In ObjectsArray Do
		
		ObjectData = PrintData[Ref];
		DataSource = New Map;
		CommonClientServer.SupplementMap(DataSource, ObjectData);
		
		SourceData = New Structure;
		SourceData.Insert("ObjectData", ObjectData);
		SourceData.Insert("DataSourcePassed", DataSource);
		
		StructureWithData = TemplateAreaToStructureForDBF(SourceData, Additional_Data);
		Result.Insert(Ref, StructureWithData);
		
	EndDo;
	
	Return Result;
	
EndFunction

Function AreasTableRowContainsTable(TableRow, OwnerTableName)
	
	ThisIsTable = TableRow.ThisIsTable;
	If ThisIsTable Then
		
		TableName = TrimAll(TableRow.TableName);
		ThisIsTable = (TableName <> OwnerTableName); // If "ThisIsTable" is set to "False", then this is a nested table area. Handle it as an area.
		
	Else
		TableName = OwnerTableName;
	EndIf;
	
	Result = New Structure;
	Result.Insert("ThisIsTable", ThisIsTable);
	Result.Insert("TableName", TableName);
	
	Return Result;
	
EndFunction

Procedure SupplementDataSourceWithTableData(Val TableName, Val ParametersTabularSectionRowData, DataSourceForArea)
	
	For Each KeyAndValue In ParametersTabularSectionRowData Do
		DataSourceForArea[TableName + "." + KeyAndValue.Key] = KeyAndValue.Value;
	EndDo;
	
EndProcedure

Function TemplateAreaToStructure(SourceDataPassed, Additional_Data, CurrentDataPassed)
	
	ObjectData = SourceDataPassed.ObjectData;
	DataSourcePassed = SourceDataPassed.DataSourcePassed;
	
	Template = Additional_Data.Template;
	TableRow = CurrentDataPassed.TableRow;
	ArrayOfProcessedOnes = CurrentDataPassed.ArrayOfProcessedOnes;
	OwnerTableName = CurrentDataPassed.OwnerTableName;
	OwnerRowNumber = CurrentDataPassed.OwnerRowNumber;
	FullAreaName = TrimAll(TableRow.Name);
	
	CheckResult = AreasTableRowContainsTable(TableRow, OwnerTableName);
	ThisIsTable = CheckResult.ThisIsTable;
	TableName = CheckResult.TableName;
	
	ArrayOfProcessedOnes.Add(FullAreaName);
	NumberofReps = 1;
	TableRowPresentation = "";
	AreaName = FullAreaName;
	ArrayOfNestedOnes = New Array;
	
	DataSourceForArea = New Map;
	If DataSourcePassed <> Undefined Then
		CommonClientServer.SupplementMap(DataSourceForArea, DataSourcePassed);
	EndIf;
	
	FirstRowNumber = 1;
	
	If ThisIsTable Then
		
		NumberofReps = ObjectData[TableName].Count();
		
		If Additional_Data.SaveFormat = Enums.ObjectsExportFormats.XML Then
			
			SplittingResult = ParseAreaName(FullAreaName, "_");
			AreaName = SplittingResult.AreaName;
			TableRowPresentation = SplittingResult.NestedAreaName;
			
		EndIf;
		
		StructureOfTable = NewDataStructure();
		FillPropertyValues(StructureOfTable, TableRow);
		StructureOfTable.IsTableRow = False;
		StructureOfTable.IsArea = False;
		StructureOfTable.TableRowPresentation = TableRowPresentation;
		StructureOfTable.AreaName = AreaName;
		
		If OwnerTableName = TableName Then
			
			NumberofReps = OwnerRowNumber;
			FirstRowNumber = OwnerRowNumber;
			
		EndIf;
		
	EndIf;
	
	DataRowsCnt = 0;
	For TabularSectionRowNumber = FirstRowNumber To NumberofReps Do
		
		DataCnt = 0;
		
		StructureWithData = NewDataStructure();
		FillPropertyValues(StructureWithData, TableRow);
		StructureWithData.IsTableRow = ThisIsTable;
		StructureWithData.ThisIsTable = ThisIsTable;
		StructureWithData.IsArea = Not ThisIsTable;
		StructureWithData.TableRowPresentation = TableRowPresentation;
		StructureWithData.AreaName = AreaName;
		
		If ThisIsTable Then
			
			ParametersTabularSectionRowData = ObjectData[TableName][TabularSectionRowNumber];
			SupplementDataSourceWithTableData(
				TableName,
				ParametersTabularSectionRowData,
				DataSourceForArea);
			
		EndIf;
		
		TabularSectionCurrentData = New Structure;
		TabularSectionCurrentData.Insert("TableRow", TableRow);
		TabularSectionCurrentData.Insert("TabularSectionRowNumber", TabularSectionRowNumber);
		TabularSectionCurrentData.Insert("TableName", TableName);
		
		SourceData = New Structure;
		SourceData.Insert("ObjectData", ObjectData);
		SourceData.Insert("DataSourcePassed", DataSourceForArea);
		
		FillStructureWithData(
			StructureWithData,
			ArrayOfNestedOnes,
			ArrayOfProcessedOnes,
			SourceData,
			Additional_Data,
			DataCnt,
			TabularSectionCurrentData);
		
		DataForAnalysis = New Structure;
		DataForAnalysis.Insert("TabularSectionRowNumber", TabularSectionRowNumber);
		DataForAnalysis.Insert("NumberofReps", NumberofReps);
		DataForAnalysis.Insert("ArrayOfNestedOnes", ArrayOfNestedOnes);
		DataForAnalysis.Insert("Template", Template);
		DataForAnalysis.Insert("AreaName", FullAreaName);
		
		UpdateProcessedAreas(ArrayOfProcessedOnes, DataForAnalysis);
		
		If ThisIsTable
		   And StructureWithData.DataVolume > 0 Then
			
			DataRowsCnt = DataRowsCnt + 1;
			DataRowsCntAsString = XMLString(DataRowsCnt);
			StructureOfTable.Insert("Data_" + DataRowsCntAsString, StructureWithData);
			StructureOfTable.DataVolume = DataRowsCnt;
			
		EndIf;
		
	EndDo;
	
	If ThisIsTable Then
		Return StructureOfTable;
	Else
		Return StructureWithData;
	EndIf;
	
EndFunction

Procedure FillStructureWithData(StructureWithData, ArrayOfNestedOnes, ArrayOfProcessedOnes, SourceData, Additional_Data, DataCnt, TabularSectionCurrentData)
	
	TableRow = TabularSectionCurrentData.TableRow;
	TableName = TabularSectionCurrentData.TableName;
	TabularSectionRowNumber = TabularSectionCurrentData.TabularSectionRowNumber;
	
	Top = TableRow.Top;
	Bottom = TableRow.Bottom;
	TableOfAreas = Additional_Data.TableOfAreas;
	
	For LineNumber = Top To Bottom Do
		
		IsCurrentAreaRow = True;
		Filter = New Structure;
		Filter.Insert("Top", LineNumber);
		FoundAreas = TableOfAreas.FindRows(Filter);
		Output = True;
		
		If FoundAreas.Count() > 0 Then
			
			EndOfNestedArea = 0;
			DataForAnalysisAndFilling = New Structure;
			DataForAnalysisAndFilling.Insert("SourceData", SourceData);
			DataForAnalysisAndFilling.Insert("Additional_Data", Additional_Data);
			DataForAnalysisAndFilling.Insert("TabularSectionCurrentData", TabularSectionCurrentData);
			DataForAnalysisAndFilling.Insert("FoundAreas", FoundAreas);
			DataForAnalysisAndFilling.Insert("LineNumber", LineNumber);
			
			SupplementStructureWithFoundAreasData(
				StructureWithData,
				ArrayOfNestedOnes,
				ArrayOfProcessedOnes,
				DataCnt,
				DataForAnalysisAndFilling);
			Output = DataForAnalysisAndFilling.Output;
			IsCurrentAreaRow = DataForAnalysisAndFilling.IsCurrentAreaRow;
			EndOfNestedArea = DataForAnalysisAndFilling.EndOfNestedArea;
			
			LineNumber = Max(LineNumber, EndOfNestedArea);
			
		EndIf;
		
		If IsCurrentAreaRow
		   And Output Then
			
			DataForParameterCalculation = NewStructureForParameterCalculation();
			FillPropertyValues(DataForParameterCalculation, Additional_Data);
			DataForParameterCalculation.TableName = TableName;
			DataForParameterCalculation.TabularSectionRowNumber = TabularSectionRowNumber;
			DataForParameterCalculation.ParameterNameRowNumber = LineNumber;
			DataForParameterCalculation.ParameterLineNumber = LineNumber;
			
			ParameterDataStructure = DataOfParameter(SourceData, DataForParameterCalculation);
			
			If ParameterDataStructure = Undefined
			 Or Not ParameterDataStructure.Output Then
				Continue;
			EndIf;
			
			DataCnt = DataCnt + 1;
			DataCntAsString = XMLString(DataCnt);
			StructureWithData.Insert("Data_" + DataCntAsString, ParameterDataStructure);
			StructureWithData.DataVolume = DataCnt;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure SupplementStructureWithFoundAreasData(StructureWithData, ArrayOfNestedOnes, ArrayOfProcessedOnes, DataCnt, Val DataForAnalysisAndFilling)
	
	SourceData = DataForAnalysisAndFilling.SourceData;
	Additional_Data = DataForAnalysisAndFilling.Additional_Data;
	TabularSectionCurrentData = DataForAnalysisAndFilling.TabularSectionCurrentData;
	FoundAreas = DataForAnalysisAndFilling.FoundAreas;
	LineNumber = DataForAnalysisAndFilling.LineNumber;
	
	TableRow = TabularSectionCurrentData.TableRow;
	TableName = TabularSectionCurrentData.TableName;
	TabularSectionRowNumber = TabularSectionCurrentData.TabularSectionRowNumber;
	Top = TableRow.Top;
	ThisIsTable = TableRow.ThisIsTable;
	
	EndOfNestedArea = 0;
	Output = True;
	IsCurrentAreaRow = True;
	
	For Each CurFoundRow In FoundAreas Do
		
		If ArrayOfProcessedOnes.Find(CurFoundRow.Name) <> Undefined
		   And LineNumber = Top Then
			Continue;
		ElsIf CurFoundRow.IsOutputConditionArea Then
			
			If ThisIsTable
			   And TableName <> CurFoundRow.TableName Then
				Continue;
			EndIf;
			
			CheckAreaOutputCondition(
				SourceData,
				Additional_Data,
				CurFoundRow,
				EndOfNestedArea,
				Output);
			
		Else
			
			IsCurrentAreaRow = False;
			EndOfNestedArea = Max(EndOfNestedArea, CurFoundRow.Bottom);
			
			CurrentData = StructureOfCurrentData(
				CurFoundRow,
				ArrayOfProcessedOnes,
				TableName,
				TabularSectionRowNumber);
			RowData = TemplateAreaToStructure(SourceData, Additional_Data, CurrentData);
			
			NestedAreaName = CurFoundRow.Name;
			ArrayOfNestedOnes.Add(NestedAreaName);
			
			If RowData <> Undefined
			   And RowData.DataVolume > 0 Then
				
				DataCnt = DataCnt + 1;
				DataCntAsString = XMLString(DataCnt);
				StructureWithData.Insert("Data_" + DataCntAsString, RowData);
				StructureWithData.DataVolume = DataCnt;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	DataForAnalysisAndFilling.Insert("Output", Output);
	DataForAnalysisAndFilling.Insert("EndOfNestedArea", EndOfNestedArea);
	DataForAnalysisAndFilling.Insert("IsCurrentAreaRow", IsCurrentAreaRow);
	
EndProcedure

Procedure CheckAreaOutputCondition(SourceData, Additional_Data, AreasTableRow, EndOfNestedArea, Output)
	
	DataSourceForArea = SourceData.DataSourcePassed;
	FieldFormatSettings = Additional_Data.FieldFormatSettings;
	LanguageCode = Additional_Data.LanguageCode;
	DetailsParameter = AreasTableRow.DetailsParameter;
	EndRegion = AreasTableRow.Bottom;
	
	If Not IsBlankString(DetailsParameter) Then
		
		Output = PrintManagement.EvalExpression(
			"[" + DetailsParameter + "]",
			DataSourceForArea,
			FieldFormatSettings,
			LanguageCode);
		
	EndIf;
	
	If TypeOf(Output) = Type("Boolean")
	   And Not Output Then
		
		EndOfNestedArea = Max(EndOfNestedArea, EndRegion);
		
	EndIf;
	
EndProcedure

Function FirstFilledRowColumnNumber(Val Template)
	
	FirstFilledRowNumber = 0;
	FirstFilledColumnNumber = 0;
	IsBeginningFound = False;
	
	For LineNumber = 1 To Template.TableHeight Do
		
		For ColumnNumber = 1 To Template.TableWidth Do
			
			Area = Template.Area(LineNumber, ColumnNumber);
			
			If Not IsBlankString(Area.Text) Then
				
				FirstFilledRowNumber = LineNumber;
				FirstFilledColumnNumber = ColumnNumber;
				IsBeginningFound = True;
				Break;
				
			EndIf;
			
		EndDo;
		
		If IsBeginningFound Then
			
			Break;
			
		EndIf;
		
	EndDo;
	
	FillingStartData = New Structure;
	FillingStartData.Insert("FirstFilledRowNumber", FirstFilledRowNumber);
	FillingStartData.Insert("FirstFilledColumnNumber", FirstFilledColumnNumber);
	
	Return FillingStartData;
	
EndFunction

Function TemplateAreaToStructureForDBF(SourceDataPassed, Additional_Data)
	
	ObjectData = SourceDataPassed.ObjectData;
	ParameterFieldTypes = Additional_Data.ParameterFieldTypes;
	Template = Additional_Data.Template;
	TemplateTables = Additional_Data.TemplateTables;
	
	StructureWithData = NewDataStructure();
	NumberofReps = 1;
	TableName = "";
	
	If TemplateTables.Count() > 0 Then
		
		TableRow = TemplateTables[0];
		Top = TableRow.Top;
		TableName = TrimAll(TableRow.Name);
		NumberofReps = ObjectData[TableName].Count();
		StructureWithData.ThisIsTable = True;
		
	Else
		
		FillingStartData = FirstFilledRowColumnNumber(Template);
		Top = FillingStartData.FirstFilledRowNumber + 1;
		StructureWithData.ThisIsTable = False;
		
	EndIf;
	
	StructureWithData.TableName = TableName;
	
	TableWidth = Template.TableWidth;
	ArrayOfColumnFields = New Array;
	ColumnTypes_ = New Map;
	ColumnsNames = New Structure;
	
	TemplateData1 = New Structure;
	TemplateData1.Insert("Template", Template);
	TemplateData1.Insert("TableWidth", TableWidth);
	TemplateData1.Insert("Top", Top);
	TemplateData1.Insert("LineNumber", 0);
	CurrentRowNumber1 = 0;
	
	For LineNumber = 1 To Top - 1 Do
		
		CurrentRowNumber1 = LineNumber;
		TemplateData1.LineNumber = CurrentRowNumber1;
		TableColumnsAndFields(ColumnsNames, ArrayOfColumnFields, ColumnTypes_, ParameterFieldTypes, TemplateData1);
		
		If ArrayOfColumnFields.Count() > 0 Then
			Break;
		EndIf;
		
	EndDo;
	
	If ArrayOfColumnFields.Count() > 0 Then
		
		TableData = New Structure;
		TableData.Insert("ArrayOfColumnFields", ArrayOfColumnFields);
		TableData.Insert("ColumnsNames", ColumnsNames);
		TableData.Insert("NumberofReps", NumberofReps);
		TableData.Insert("ColumnTypes_", ColumnTypes_);
		
		TableStructureDBF(
			StructureWithData,
			SourceDataPassed,
			Additional_Data,
			TableData,
			Top,
			CurrentRowNumber1);
		
	EndIf;
	
	StructureWithData.ColumnTypes_ = ColumnTypes_;
	Return StructureWithData;
	
EndFunction

Procedure TableStructureDBF(StructureWithData, SourceDataPassed, Additional_Data, TableData, Top, CurrentRowNumber1)
	
	ArrayOfColumnFields = TableData.ArrayOfColumnFields;
	ColumnsNames = TableData.ColumnsNames;
	NumberofReps = TableData.NumberofReps;
	ColumnTypes_ = TableData.ColumnTypes_;
	
	ObjectData = SourceDataPassed.ObjectData;
	DataSource = SourceDataPassed.DataSourcePassed;
	
	FieldFormatSettings = Additional_Data.FieldFormatSettings;
	Template = Additional_Data.Template;
	LanguageCode = Additional_Data.LanguageCode;
	TemplateTables = Additional_Data.TemplateTables;
	
	TableName = StructureWithData.TableName;
	ColumnNumber = ArrayOfColumnFields[0];
	DetailsParameter = Template.Area(Top, ColumnNumber, Top, ColumnNumber).DetailsParameter;
	
	StructureWithData.ColumnsNames = ColumnsNames;
	
	DataCnt = 0;
	For TabularSectionRowNumber = 1 To NumberofReps Do
		
		If TemplateTables.Count() > 0 Then
			
			ParametersTabularSectionRowData = ObjectData[TableName][TabularSectionRowNumber];
			SupplementDataSourceWithTableData(
				TableName,
				ParametersTabularSectionRowData,
				DataSource);
			
		EndIf;
		
		ServiceData = New Structure;
		ServiceData.Insert("TableName", TableName);
		ServiceData.Insert("TabularSectionRowNumber", TabularSectionRowNumber);
		ServiceData.Insert("Top", Top);
		ServiceData.Insert("LineNumber", CurrentRowNumber1);
		ServiceData.Insert("ArrayOfColumnFields", ArrayOfColumnFields);
		ServiceData.Insert("Additional_Data", Additional_Data);
		ServiceData.Insert("DataSource", DataSource);
		ServiceData.Insert("ObjectData", ObjectData);
		
		StringStructure = NewDataStructure();
		RowStructureDBF(StringStructure, ColumnTypes_, ServiceData);
		
		Output = True;
		If Not IsBlankString(DetailsParameter) Then
			
			Output = PrintManagement.EvalExpression(
				"[" + DetailsParameter + "]",
				DataSource,
				FieldFormatSettings,
				LanguageCode);
				
		EndIf;
		
		If TypeOf(Output) = Type("Boolean")
		   And Not Output Then
			Continue;
		EndIf;
		
		DataCnt = DataCnt + 1;
		DataCntAsString = XMLString(DataCnt);
		
		StructureWithData.Insert("Data_" + DataCntAsString, StringStructure);
		StructureWithData.DataVolume = DataCnt;
		
	EndDo;
	
EndProcedure

Procedure RowStructureDBF(StringStructure, ColumnTypes_, ServiceData)
	
	TableName = ServiceData.TableName;
	TabularSectionRowNumber = ServiceData.TabularSectionRowNumber;
	Top = ServiceData.Top;
	LineNumber = ServiceData.LineNumber;
	ArrayOfColumnFields = ServiceData.ArrayOfColumnFields;
	Additional_Data = ServiceData.Additional_Data;
	DataSource = ServiceData.DataSource;
	ObjectData = ServiceData.ObjectData;
	
	DataForParameterCalculation = NewStructureForParameterCalculation();
	FillPropertyValues(DataForParameterCalculation, Additional_Data);
	DataForParameterCalculation.TableName = TableName;
	DataForParameterCalculation.TabularSectionRowNumber = TabularSectionRowNumber;
	DataForParameterCalculation.ParameterNameRowNumber = LineNumber;
	DataForParameterCalculation.ParameterLineNumber = Top;
	
	ColumnsCounter = 0;
	For Each ColumnNumber In ArrayOfColumnFields Do
		
		ColumnsCounter = ColumnsCounter + 1;
		ColumnsCounterAsString = XMLString(ColumnsCounter);
		ColumnNumberAsString = XMLString(ColumnNumber);
		
		DataForParameterCalculation.ParameterNameColumnNumber = ColumnNumber;
		DataForParameterCalculation.ParameterColumnNumber = ColumnNumber;
		
		SourceData = New Structure;
		SourceData.Insert("ObjectData", ObjectData);
		SourceData.Insert("DataSourcePassed", DataSource);
		
		ParameterDataStructure = DataOfParameter(SourceData, DataForParameterCalculation);
		StringStructure.Insert("Data_" + ColumnsCounterAsString, ParameterDataStructure);
		StringStructure.DataVolume = ColumnsCounter;
		If ColumnTypes_["ColumnNumber_" + ColumnNumberAsString] = Undefined Then
			ColumnTypes_.Insert("ColumnNumber_" + ColumnNumberAsString, ParameterDataStructure.FieldType);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure TableColumnsAndFields(ColumnsNames, ArrayOfColumnFields, ColumnTypes_, ParameterFieldTypes, TemplateData1)
	
	ColumnName = "";
	
	Template = TemplateData1.Template;
	TableWidth = TemplateData1.TableWidth;
	Top = TemplateData1.Top;
	LineNumber = TemplateData1.LineNumber;
	
	For ColumnNumber = 1 To TableWidth Do
		
		ColumnNumAsString = XMLString(ColumnNumber);
		ColumnName = Template.Area(LineNumber, ColumnNumber, LineNumber, ColumnNumber).Text;
		
		If Not IsBlankString(ColumnName) Then
			
			ColumnsNames.Insert("ColumnNumber_" + ColumnNumAsString, ColumnName);
			ArrayOfColumnFields.Add(ColumnNumber);
			
		EndIf;
		
	EndDo;
	
	For Each Var_311_ColumnNumber In ArrayOfColumnFields Do
		
		ColumnNumberAsString = XMLString(Var_311_ColumnNumber);
		FullPath = Template.Area(Top, Var_311_ColumnNumber, Top, Var_311_ColumnNumber).Text;
		FullPath = TrimAll(FullPath);
		FieldName = PrintManagement.ClearSquareBrackets(FullPath);
		FieldType = ParameterFieldTypes[StrReplace(FieldName, ".", "_")];
		ColumnTypes_["ColumnNumber_" + ColumnNumberAsString] = FieldType;
		
	EndDo;
	
EndProcedure

Procedure UpdateProcessedAreas(ArrayOfProcessedOnes, Val DataForAnalysis)
	
	TabularSectionRowNumber = DataForAnalysis.TabularSectionRowNumber;
	NumberofReps = DataForAnalysis.NumberofReps;
	ArrayOfNestedOnes = DataForAnalysis.ArrayOfNestedOnes;
	Template = DataForAnalysis.Template;
	AreaName = DataForAnalysis.AreaName;
	
	If TabularSectionRowNumber < NumberofReps Then
		
		RemoveNestedAreasFromArray(ArrayOfProcessedOnes, ArrayOfNestedOnes);
		
	Else
		
		SupplementProcessedAreasArrayWithNestedAreas(ArrayOfProcessedOnes, Template, AreaName);
		
	EndIf;
	
EndProcedure

Procedure RemoveNestedAreasFromArray(ArrayOfProcessedOnes, Val ArrayOfNestedOnes)
	
	For Each AreaCrntName In ArrayOfNestedOnes Do
		
		Area = ArrayOfProcessedOnes.Find(AreaCrntName);
		If Area <> Undefined Then
			ArrayOfProcessedOnes.Delete(Area);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure SupplementProcessedAreasArrayWithNestedAreas(ArrayOfProcessedOnes, Val Template, Val AreaName)
	
	For Each CurrentArea In Template.Areas Do
		
		If CurrentArea.Name = AreaName Then
			
			NestedAreas = Template.GetArea(AreaName).Areas;
			For Each CurNestedArea In NestedAreas Do
				
				CurScopeName = CurNestedArea.Name;
				If ArrayOfProcessedOnes.Find(CurScopeName) = Undefined Then
					ArrayOfProcessedOnes.Add(CurScopeName);
				EndIf;
				
			EndDo;
			
			Break;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function DataOfParameter(SourceData, DataForParameterCalculation)
	
	ValueDataSource = SourceData.DataSourcePassed;
	
	FieldFormatSettings = DataForParameterCalculation.FieldFormatSettings;
	ParameterFieldTypes = DataForParameterCalculation.ParameterFieldTypes;
	LanguageCode = DataForParameterCalculation.LanguageCode;
	Template = DataForParameterCalculation.Template;
	TabularSectionRowNumber = DataForParameterCalculation.TabularSectionRowNumber;
	ParameterNameRowNumber = DataForParameterCalculation.ParameterNameRowNumber;
	ParameterNameColumnNumber = DataForParameterCalculation.ParameterNameColumnNumber;
	ParameterLineNumber = DataForParameterCalculation.ParameterLineNumber;
	ParameterColumnNumber = DataForParameterCalculation.ParameterColumnNumber;
	
	ParameterName = TrimAll(Template.Area(
		ParameterNameRowNumber,
		ParameterNameColumnNumber,
		ParameterNameRowNumber,
		ParameterNameColumnNumber).Text);
	
	If IsBlankString(ParameterName) Then
		Return Undefined;
	EndIf; 
	
	FullPath = TrimAll(Template.Area(
		ParameterLineNumber,
		ParameterColumnNumber,
		ParameterLineNumber,
		ParameterColumnNumber).Text);
	DetailsParameter = TrimAll(Template.Area(
		ParameterLineNumber,
		ParameterColumnNumber,
		ParameterLineNumber,
		ParameterColumnNumber).DetailsParameter);
	
	FieldName = PrintManagement.ClearSquareBrackets(FullPath);
	FieldType = ParameterFieldTypes[StrReplace(FieldName, ".", "_")];
	
	ParameterStructure = ParameterNewStructure();
	ParameterStructure.FullPath = FullPath;
	ParameterStructure.ConditionalAppearance = FieldFormatSettings[FieldName];
	ParameterStructure.ParameterName = StrReplace(ParameterName, " ", "");
	ParameterStructure.LanguageCode = LanguageCode;
	
	If StrFind(FullPath, "[") = 0 Then
		
		Simple = FullPath;
		FieldType = Common.StringTypeDetails(StrLen(String(Simple)));
		
	Else
		
		Result = SourceFieldValue(
			SourceData,
			DataForParameterCalculation,
			FieldName,
			FullPath,
			TabularSectionRowNumber);
		Simple = Result.Simple;
		
		If Simple <> Undefined
		   And Result.IsResultCalculated Then
			
			FieldType = FieldTypeByValue(Simple);
			
		EndIf;
		
	EndIf;
	
	Output = True;
	If Not IsBlankString(DetailsParameter) Then
		
		Output = PrintManagement.EvalExpression(
			"[" + DetailsParameter + "]",
			ValueDataSource,
			FieldFormatSettings,
			LanguageCode);
			
	EndIf;
	
	ParameterStructure.FieldType = FieldType;
	ParameterStructure.Value = Simple;
	
	If TypeOf(Output) = Type("Boolean")
	   And Not Output Then
		ParameterStructure.Output = False;
	Else
		ParameterStructure.Output = True;
	EndIf;
	
	Return ParameterStructure;
	
EndFunction

Function SourceFieldValue(SourceData, DataForParameterCalculation, FieldName, FullPath, TabularSectionRowNumber)
	
	ObjectData = SourceData.ObjectData;
	ValueDataSource = SourceData.DataSourcePassed;
	
	FieldFormatSettings = DataForParameterCalculation.FieldFormatSettings;
	TableName = DataForParameterCalculation.TableName;
	LanguageCode = DataForParameterCalculation.LanguageCode;
	
	ResultingStructure = New Structure;
	ResultingStructure.Insert("Simple");
	ResultingStructure.Insert("IsResultCalculated", False);
	
	Result = Undefined;
	
	If Not IsBlankString(TableName) Then
		
		TableParameterName = PrintManagement.FieldNameToTable(FieldName, TableName);
		Result = ObjectData[TableName][TabularSectionRowNumber][TableParameterName];
		
	EndIf;
	
	If Result = Undefined Then
		Result = ObjectData[FieldName];
	EndIf;
	
	If Result = Undefined Then
		
		TextParameters = PrintManagement.FindParametersInText(FullPath);
		ParameterValues = PrintManagement.ParameterValues(
			TextParameters,
			ValueDataSource,
			FieldFormatSettings,
			LanguageCode);
		
		If ParameterValues.Count() = 1 Then
			
			Result = ParameterValues[TextParameters[0]];
			
		Else
			
			If TypeOf(FullPath) = Type("FormattedString") Then
				Result = PrintManagement.ReplaceInFormattedString(FullPath, ParameterValues);
			Else
				Result = PrintManagement.ReplaceInline(FullPath, ParameterValues);
			EndIf;
			
		EndIf;
		
		ResultingStructure.IsResultCalculated = True;
		
	EndIf;
	
	ResultingStructure.Simple = Result;
	
	Return ResultingStructure;
	
EndFunction

// Parameters:
//  Simple - String, Arbitrary - Field value
// 
// Returns:
//  TypeDescription - Default field type
//
Function FieldTypeByValue(Simple)
	
	If TypeOf(Simple) = Type("Boolean") Then
		
		FieldType = New TypeDescription("Boolean");
		
	ElsIf TypeOf(Simple) = Type("Date") Then
		
		FieldType = Common.DateTypeDetails(Simple);
		
	ElsIf TypeOf(Simple) = Type("Number") Then
		
		MinDigits = 2;
		Digits = StrLen(Simple - Int(Simple)) - MinDigits;
		If Digits < MinDigits Then
			Digits = MinDigits;
		EndIf;
		FieldType =  Common.TypeDescriptionNumber(15, Digits);
		
	Else
		
		FieldType = Common.StringTypeDetails(StrLen(String(Simple)));
		
	EndIf;
	
	Return FieldType;
	
EndFunction

Function TableOfAreas(Template)
	
	TypesDetailsString = New TypeDescription("String");
	TypesDetailsNumber = New TypeDescription("Number");
	TypesDetailsBoolean = New TypeDescription("Boolean");
	
	TableOfAreas = New ValueTable;
	TableOfAreas.Columns.Add("Name", TypesDetailsString);
	TableOfAreas.Columns.Add("Top", TypesDetailsNumber);
	TableOfAreas.Columns.Add("Bottom", TypesDetailsNumber);
	TableOfAreas.Columns.Add("DetailsParameter", TypesDetailsString);
	TableOfAreas.Columns.Add("TableName", TypesDetailsString);
	TableOfAreas.Columns.Add("ThisIsTable", TypesDetailsBoolean);
	TableOfAreas.Columns.Add("Priority", TypesDetailsNumber);
	TableOfAreas.Columns.Add("IsOutputConditionArea", TypesDetailsBoolean);
	
	For Each Area In Template.Areas Do
		
		If TypeOf(Area) = Type("SpreadsheetDocumentRange")
		   And Area.AreaType = SpreadsheetDocumentCellAreaType.Rows Then
			
			NewRow = TableOfAreas.Add();
			FillPropertyValues(NewRow, Area);
			If ValueIsFilled(Area.DetailsParameter) > 0 Then
				
				NewRow.IsOutputConditionArea = True;
				NewRow.Priority = 100;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	UpdateConditionsAreas(TableOfAreas);
	TableOfAreas.Sort("Top, Bottom Desc, Priority");
	
	Return TableOfAreas;
	
EndFunction

Procedure UpdateConditionsAreas(TableOfAreas)
	
	TableOfAreas.Sort("Top, Bottom Desc, Priority");
	
	For Each Area In TableOfAreas Do
		
		If Not Area.IsOutputConditionArea Then
			Continue;
		EndIf;
		
		Filter = New Structure;
		Filter.Insert("IsOutputConditionArea", True);
		Filter.Insert("DetailsParameter", Area.DetailsParameter);
		FoundRows = TableOfAreas.FindRows(Filter);
		For Each CurrentRow In FoundRows Do
			
			If Area.Bottom <= CurrentRow.Bottom
			   And Area.Top > CurrentRow.Top Then
				
				Area.IsOutputConditionArea = False;
				Area.Priority = 0;
				Break;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure SupplementAreasTableWithTableData(Template, TableOfAreas, TemplateTables)
	
	ArrayOfProcessedOnes = New Array;
	For Each AreaCurRow In TableOfAreas Do
		
		Area = Template.Areas[AreaCurRow.Name];
		Top = Area.Top;
		Bottom = Area.Bottom;
		AreaName = Area.Name;
		ArrayOfProcessedOnes.Add(AreaName);
		
		For LineNumber = Top To Bottom Do
			
			TablesRow = TemplateTables.Find(LineNumber, "Top");
			IsCurrentAreaRow = True;
			Filter = New Structure;
			Filter.Insert("Top", LineNumber);
			FoundAreas = TableOfAreas.FindRows(Filter);
			
			If FoundAreas.Count() > 0 Then
				
				Result = EndRegion(ArrayOfProcessedOnes, IsCurrentAreaRow, FoundAreas);
				EndOfNestedArea = Result.EndOfNestedArea;
				IsCurrentAreaRow = Result.IsCurrentAreaRow;
				LineNumber = Max(LineNumber, EndOfNestedArea);
				
			EndIf;
			
			If TablesRow <> Undefined
			   And IsCurrentAreaRow Then
				
				AreaCurRow.TableName = TablesRow.Name;
				AreaCurRow.ThisIsTable = True;
				Break;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	TableOfAreas.Sort("Top, Bottom Desc, Priority");
	
EndProcedure

Function EndRegion(Val ArrayOfProcessedOnes, Val IsCurrentAreaRowPassed, Val FoundAreas)
	
	EndOfNestedArea = 0;
	IsCurrentAreaRow = IsCurrentAreaRowPassed;
	
	For Each CurFoundRow In FoundAreas Do
			
		If ArrayOfProcessedOnes.Find(CurFoundRow.Name) <> Undefined
		 Or CurFoundRow.IsOutputConditionArea Then
			Continue;
		Else
			
			IsCurrentAreaRow = False;
			EndOfNestedArea = Max(EndOfNestedArea, CurFoundRow.Bottom);
			
		EndIf;
		
	EndDo;
	
	Result = New Structure;
	Result.Insert("IsCurrentAreaRow", IsCurrentAreaRow);
	Result.Insert("EndOfNestedArea", EndOfNestedArea);
	Return Result;
	
EndFunction

Procedure NotifyExportUnavailable(Object)
	
	Template = NStr("vi = 'Chưa thực hiện kết xuất %1: khuôn in được chọn không khả dụng.';
					|ru = 'Выгрузка %1 не выполнена: выбранный макет недоступен.';
					|en = 'Export ""%1"" failed: Selected template is unavailable.'; fa = 'Export ""%1"" failed: Selected template is unavailable.';
					|it = 'Export ""%1"" failed: Selected template is unavailable.';
					|pl = 'Export ""%1"" failed: Selected template is unavailable.';
					|tr = '%1 aktarımı tamamlanmadı: Seçili şablon kullanılamıyor.'");
	ObjectAsString = String(Object);
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(Template, ObjectAsString);
	Common.MessageToUser(MessageText, Object);
	
EndProcedure

// Parameters:
//  PrintCommand - See PrintManagement.CreatePrintCommandsCollection
//  SettingsForSaving - See PrintManagement.SettingsForSaving
//  ListOfObjects - Array of CatalogRef, DocumentRef
//  Result - ValueTable:
//   * FileName - String
//   * BinaryData - BinaryData
//
Procedure ExecuteExportToFile(PrintCommand, SettingsForSaving, ListOfObjects, Result)
	
	ObjectsTableByTemplates = New ValueTable;
	ObjectsTableByTemplates.Columns.Add("TemplateName", New TypeDescription("String"));
	ObjectsTableByTemplates.Columns.Add("ObjectsArray", New TypeDescription("Array"));
	
	NewRow = ObjectsTableByTemplates.Add();
	NewRow.TemplateName = PrintCommand.Id;
	NewRow.ObjectsArray = ListOfObjects;
	
	UploadData_0 = GenerateDataForExport(PrintCommand.PrintManager, ObjectsTableByTemplates);
	
	PrintFormsCollection = UploadData_0.PrintFormsCollection;
	ObjectsToExport = UploadData_0.ObjectsToExport;
	
	TempDirectoryName = FileSystem.CreateTemporaryDirectory();
	
	AreasSignaturesAndSeals = Undefined;
	If SettingsForSaving.SignatureAndSeal Then
		AreasSignaturesAndSeals = PrintManagement.AreasSignaturesAndSeals(ObjectsToExport);
	EndIf;
	
	For Each CurCollection In PrintFormsCollection Do
		
		SpreadsheetDocument = CurCollection.SpreadsheetDocument;
		
		If SpreadsheetDocument <> Undefined Then
			
			ProcessSaveSettingsSignatureAndSeal(
				SettingsForSaving,
				SpreadsheetDocument,
				ObjectsToExport,
				AreasSignaturesAndSeals);
			
			ExportsByObjects = PrintManagement.PrintFormsByObjects(SpreadsheetDocument, ObjectsToExport);
			
		Else
			
			ExportsByObjects = CurCollection.UnloadingStructure;
			
		EndIf;
		
		IterateThroughObjects(ExportsByObjects, CurCollection, SettingsForSaving, Result);
		
	EndDo;
	
	FileSystem.DeleteTemporaryDirectory(TempDirectoryName);
	
EndProcedure

Procedure ProcessSaveSettingsSignatureAndSeal(SettingsForSaving, SpreadsheetDocument, ObjectsToExport, Val AreasSignaturesAndSeals)
	
	If SettingsForSaving.SignatureAndSeal Then
		
		DataPrintPatternPatternDocument = PrintManagement.SpreadsheetDocumentSignaturesAndSeals(
			ObjectsToExport,
			SpreadsheetDocument,
			Common.DefaultLanguageCode());
			
		For Each SignaturePrintRegion In AreasSignaturesAndSeals Do
			
			AreaName = SignaturePrintRegion.Key;
			If DataPrintPatternPatternDocument[AreaName] = Undefined Then
				DataPrintPatternPatternDocument[AreaName] = New Map();
			EndIf;
			For Each Item In SignaturePrintRegion.Value Do
				DataPrintPatternPatternDocument[AreaName][Item.Key] = Item.Value;
			EndDo;
			
		EndDo;
		
		PrintManagement.AddSignatureAndSeal(SpreadsheetDocument, DataPrintPatternPatternDocument);
		
	Else
		PrintManagement.RemoveSignatureAndSeal(SpreadsheetDocument);
	EndIf;
	
EndProcedure

Procedure IterateThroughObjects(ExportsByObjects, CurCollection, SettingsForSaving, Result)
	
	ExportFormatExtensionMap = ExportFormatSaveFormatMap();
	FormatMatching = ExportFormatsSpreadsheetFileTypeMap();
	FormatsTable = PrintManagement.SpreadsheetDocumentSaveFormatsSettings();
	TempDirectoryName = FileSystem.CreateTemporaryDirectory();
	
	DataForExtension = New Structure;
	DataForExtension.Insert("ExportFormatExtensionMap", ExportFormatExtensionMap);
	DataForExtension.Insert("FormatMatching", FormatMatching);
	DataForExtension.Insert("FormatsTable", FormatsTable);
	
	TransliterateFilesNames = SettingsForSaving.TransliterateFilesNames;
	SelectedFormat = CurCollection.SaveFormat; // EnumRef.ObjectsExportFormats
	
	Counter = 0;
	
	For Each ObjectExportMap In ExportsByObjects Do
		
		Counter = Counter + 1;
		
		UploadObject = ObjectExportMap.Key;
		ExportResult = ObjectExportMap.Value;
		
		FileName = PrintManagement.ObjectPrintFormFileName(UploadObject, "", CurCollection.TemplateSynonym);
		FileName = CommonClientServer.ReplaceProhibitedCharsInFileName(FileName);
		
		If TransliterateFilesNames Then
			FileName = StringFunctions.LatinString(FileName);
		EndIf;
		
		DataForExtension.Insert("FileName", FileName);
		DataForExtension.Insert("SelectedFormat", SelectedFormat);
		
		ExtensionData = FileExtensionData(ExportResult, DataForExtension, Counter);
		FileExtention = ExtensionData.FileExtention;
		FileType = ExtensionData.FileType;
		FileNameWithExtensionPresentation = ExtensionData.FileNameWithExtensionPresentation;
		FileName = ExtensionData.FileName;
		
		TemplateNameOfFile = "%1.%2";
		TemplateFullFileName = "%1%2.%3";
		
		FileNameWithExtension = StringFunctionsClientServer.SubstituteParametersToString(
			TemplateNameOfFile,
			FileName,
			FileExtention);
		FullFileName = StringFunctionsClientServer.SubstituteParametersToString(
			TemplateFullFileName,
			TempDirectoryName,
			FileName,
			FileExtention);
			
		FullFileName = FileSystem.UniqueFileName(FullFileName);
		
		If TypeOf(ExportResult) = Type("Structure") Then
			GenerateStructureExportFile(ExportResult, SelectedFormat, FullFileName);
		Else
			WriteSpreadsheetDocument(ExportResult, FullFileName, FileType);
		EndIf;
		
		If FileType = SpreadsheetDocumentFileType.HTML Then
			PrintManagement.InsertPicturesToHTML(FullFileName);
		EndIf;
		
		BinaryData = New BinaryData(FullFileName);
		DeleteFiles(FullFileName);
		
		File = Result.Add();
		File.FileName = FileNameByFormat(FileNameWithExtension, FileNameWithExtensionPresentation, SelectedFormat);
		File.BinaryData = BinaryData;
		File.UploadObject = UploadObject;
		
	EndDo;
	
EndProcedure

Function FileNameByFormat(Val FileNameWithExtension, Val FileNameWithExtensionPresentation, Val SelectedFormat)
	
	If SelectedFormat = Enums.ObjectsExportFormats.DBF Then
		Return FileNameWithExtensionPresentation;
	Else
		Return FileNameWithExtension;
	EndIf;
	
EndFunction

Procedure WriteSpreadsheetDocument(PrintForm, FullFileName, FileType)
	
	PrintForm.Write(FullFileName, FileType); // SpreadsheetDocument
	
	If FileType = SpreadsheetDocumentFileType.ANSITXT
	 Or FileType = SpreadsheetDocumentFileType.TXT Then
		
		TextReader = New TextReader(FullFileName);
		SourceText = TextReader.Read();
		NewText = StrReplace(SourceText, Chars.Tab, "");
		TextReader.Close();
		TextDocument = New TextDocument;
		TextDocument.AddLine(NewText);
		If FileType = SpreadsheetDocumentFileType.ANSITXT Then
			TextDocument.Write(FullFileName, TextEncoding.ANSI);
		Else
			TextDocument.Write(FullFileName, TextEncoding.UTF8);
		EndIf;
		
	EndIf;
	
EndProcedure

Function FileExtensionData(ExportResult, DataForExtension, Counter)
	
	ExportFormatExtensionMap = DataForExtension.ExportFormatExtensionMap;
	FormatMatching = DataForExtension.FormatMatching;
	FormatsTable = DataForExtension.FormatsTable;
	SelectedFormat = DataForExtension.SelectedFormat;
	FileName = DataForExtension.FileName;
	
	FileNameWithExtensionPresentation = "";
	FileExtention = "";
	FileType = "";
	
	If TypeOf(ExportResult) = Type("Structure") Then
		
		FileExtention = ExportFormatExtensionMap[SelectedFormat];
		
		If SelectedFormat = Enums.ObjectsExportFormats.DBF Then
			
			FileNameWithExtensionPresentation = FileName + "." + FileExtention;
			
			MaxLength = 3;
			FileName = TrimAll(StrReplace(FileName, " ", ""));
			If StrLen(FileName) > MaxLength Then
				FileName = Left(FileName, MaxLength) + Counter;
			EndIf;
			
		EndIf;
		
	Else
		
		If TypeOf(SelectedFormat) = Type("EnumRef.ObjectsExportFormats") Then
			
			FileType = FormatMatching[SelectedFormat];
			
		Else
			
			FileType = SpreadsheetDocumentFileType[SelectedFormat];
			
		EndIf;
		
		Filter = New Structure("SpreadsheetDocumentFileType", FileType);
		FormatSettings = FormatsTable.FindRows(Filter)[0];
		FileExtention = FormatSettings.Extension;
		
	EndIf;
	
	ExtensionData = New Structure;
	ExtensionData.Insert("FileExtention", FileExtention);
	ExtensionData.Insert("FileNameWithExtensionPresentation", FileNameWithExtensionPresentation);
	ExtensionData.Insert("FileType", FileType);
	ExtensionData.Insert("FileName", FileName);
	
	Return ExtensionData;
	
EndFunction

// Parameters:
//  StructureWithData - Structure
//  SelectedFormat - EnumRef.ObjectsExportFormats
//  FullFileName - String - Full filename
//
Procedure GenerateStructureExportFile(StructureWithData, SelectedFormat, FullFileName)
	
	ExportPresentation = "";
	If SelectedFormat = Enums.ObjectsExportFormats.XML Then
		ExecuteExportToXML(StructureWithData, FullFileName, ExportPresentation);
	ElsIf SelectedFormat = Enums.ObjectsExportFormats.JSON Then
		ExecuteExportToJSON(StructureWithData, FullFileName, ExportPresentation);
	ElsIf SelectedFormat = Enums.ObjectsExportFormats.DBF Then
		ExecuteExportToDBF(StructureWithData, FullFileName);
	EndIf;
	
EndProcedure

Procedure ProcessDataXMLArea(XMLWriter, StructureWithData)
	
	If StructureWithData.IsParameter Then
		
		StructureItem = StructureWithData;
		ParameterName = TrimAll(StructureItem.ParameterName); // String
		ParameterName = CommonClientServer.DeleteDisallowedXMLCharacters(ParameterName);
		Value = StructureItem.Value; // AnyRef
		ValueToFile = ValueIntoXMLJSON(Value);
		
		XMLWriter.WriteStartElement(ParameterName);
		XMLWriter.WriteText(ValueToFile);
		XMLWriter.WriteEndElement();
		
	Else
		
		If StructureWithData.IsTableRow Then
			AreaName = StructureWithData.TableRowPresentation;
		Else
			AreaName = StructureWithData.AreaName;
		EndIf;
		AreaName = CommonClientServer.DeleteDisallowedXMLCharacters(AreaName);
		
		XMLWriter.WriteStartElement(AreaName);
		DataVolume = StructureWithData.DataVolume;
		
		For DataNumber = 1 To DataVolume Do
			
			DataNumberAsString = Format(DataNumber, "NFD=0; NG=");
			StructureItem = StructureWithData["Data_" + DataNumberAsString];
			If StructureItem.IsParameter Then
				
				ParameterName = TrimAll(StructureItem.ParameterName); // String
				ParameterName = CommonClientServer.DeleteDisallowedXMLCharacters(ParameterName);
				Value = StructureItem.Value; // AnyRef
				ValueToFile = ValueIntoXMLJSON(Value);
				
				XMLWriter.WriteStartElement(ParameterName);
				XMLWriter.WriteText(ValueToFile);
				XMLWriter.WriteEndElement();
				
			Else
				ProcessDataXMLArea(XMLWriter, StructureItem);
			EndIf;
			
		EndDo;
		
		XMLWriter.WriteEndElement();
		
	EndIf;
	
EndProcedure

Function ValueIntoXMLJSON(Value, IsXML = True)
	
	DataByValue = ValueTypePrimitive(Value);
	PrimitiveType = DataByValue.PrimitiveType;
	
	If PrimitiveType
	   And IsXML Then
		
		Result = XMLString(Value);
		
	ElsIf PrimitiveType Then
		
		Result = Value;
		
	Else
		
		Result = TrimAll(String(Value));
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure ProcessDataJSONArea(StructureWithData, DataIntoJSON)
	
	If StructureWithData.IsParameter Then
		Return;
	EndIf;
	
	DataVolume = StructureWithData.DataVolume;
	
	For DataNumber = 1 To DataVolume Do
		
		DataNumberAsString = Format(DataNumber, "NFD=0; NG=");
		StructureItem = StructureWithData["Data_" + DataNumberAsString];
		
		If StructureItem.IsParameter Then
			
			ParameterName = StructureItem.ParameterName; // String
			Value = StructureItem.Value; // AnyRef
			ValueToFile = ValueIntoXMLJSON(Value, False);
			DataIntoJSON.Insert(ParameterName, ValueToFile);
			
		ElsIf StructureItem.ThisIsTable Then
			
			RowsArray = ProcessJSONTable(StructureItem);
			DataIntoJSON.Insert(StructureItem.AreaName, RowsArray);
			
		Else
			
			NestedDataInJSON = New Structure;
			ProcessDataJSONArea(StructureItem, NestedDataInJSON);
			DataIntoJSON.Insert(StructureItem.AreaName, NestedDataInJSON);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function ProcessJSONTable(StructureItem)
	
	RowsArray = New Array;
	DataVolume = StructureItem.DataVolume;
	
	For DataNumber = 1 To DataVolume Do
		
		DataNumberAsString = Format(DataNumber, "NFD=0; NG=");
		RowData = New Structure;
		RowDataStructure = StructureItem["Data_" + DataNumberAsString];
		ProcessDataJSONArea(RowDataStructure, RowData);
		RowsArray.Add(RowData);
		
	EndDo;
	
	Return RowsArray;
	
EndFunction

Procedure ExecuteExportToDBF(StructureWithData, FullFileName)
	
	DataVolume = StructureWithData.DataVolume;
	ColumnTypes_ = StructureWithData.ColumnTypes_;
	ColumnsNames = StructureWithData.ColumnsNames;
	DataTable = New XBase;
	
	For Each Column In ColumnsNames Do
		
		FieldName = Column.Value; // String
		ColumnType = ColumnTypes_[Column.Key]; // TypeDescription
		ColumnDetails = ColumnDetailsForDBF(ColumnType);
		
		FieldType = ColumnDetails.FieldType;
		Length = ColumnDetails.Length;
		Accuracy = ColumnDetails.Accuracy;
		If FieldType = "Boolean" Then
			DataTable.Fields.Add(FieldName, "L");
		ElsIf FieldType = "Date" Then
			DataTable.Fields.Add(FieldName, "D");
		ElsIf FieldType = "String" Then
			DataTable.Fields.Add(FieldName, "S", Length);
		Else
			DataTable.Fields.Add(FieldName, "N", Length, Accuracy);
		EndIf;
		
	EndDo;
	
	DataTable.CreateFile(FullFileName);
	
	For LineNumber = 1 To DataVolume Do
		
		RowNumberAsString = XMLString(LineNumber);
		Data = StructureWithData["Data_" + RowNumberAsString];
		ColumnsCount = Data.DataVolume;
		
		DataTable.Add();
		
		For FieldNumber = 1 To ColumnsCount Do
			
			FieldNumberAsString = XMLString(FieldNumber);
			ColumnData = Data["Data_" + FieldNumberAsString];
			Value = ColumnData.Value;
			FieldName = ColumnData.ParameterName;
			DataTable[FieldName] = Value;
			
		EndDo;
		
		DataTable.Save();
		
	EndDo;
	
	DataTable.CloseFile();
	
EndProcedure

// Returns a structure describing columns for a DBF file.
// 
// Parameters:
//  TypeDetails - TypeDescription 
// 
// Returns:
//  Structure -  Column details for DBF:
// * FieldType - String
// * Length - Number
// * Accuracy - Number
//
Function ColumnDetailsForDBF(TypeDetails)
	
	Result = New Structure;
	Result.Insert("FieldType", "");
	Result.Insert("Length", 0);
	Result.Insert("Accuracy", 0);
	
	StringFieldType = "String";
	
	If TypeOf(TypeDetails) = Type("TypeDescription") Then
		
		StringQualifiers = TypeDetails.StringQualifiers;
		NumberQualifiers = TypeDetails.NumberQualifiers;
		
		If TypeDetails.ContainsType(Type("Date")) Then
			Result.FieldType = "Date";
		ElsIf TypeDetails.ContainsType(Type("Boolean"))  Then
			Result.FieldType = "Boolean";
		ElsIf NumberQualifiers.Digits <> 0 Then
			
			Result.FieldType = "Number";
			Result.Length = NumberQualifiers.Digits;
			Result.Accuracy = NumberQualifiers.FractionDigits;
			
		ElsIf StringQualifiers.Length <> 0 Then
			
			Result.FieldType = StringFieldType;
			Result.Length = StringQualifiers.Length;
			
		Else
			
			Result.FieldType = StringFieldType;
			Result.Length = 150;
			
		EndIf;
		
	Else
		
		Result.FieldType = StringFieldType;
		Result.Length = 150;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Returns details (structure) for the passed value.
// 
// Parameters:
//  Value - AnyRef - Value
// 
// Returns:
//  Structure - This is a primitive data type.:
// * ValueType - Type
// * PrimitiveType - Boolean
//
Function ValueTypePrimitive(Value)
	
	ValueType = TypeOf(Value);
	
	PrimitiveTypesArray = New Array; // Array of Type
	PrimitiveTypesArray.Add(Type("String"));
	PrimitiveTypesArray.Add(Type("Boolean"));
	PrimitiveTypesArray.Add(Type("Number"));
	PrimitiveTypesArray.Add(Type("Date"));
	
	Result = (PrimitiveTypesArray.Find(ValueType) <> Undefined);
	
	Structure = New Structure;
	Structure.Insert("ValueType", ValueType);
	Structure.Insert("PrimitiveType", Result);
	
	Return Structure;
	
EndFunction

Function ExportFormatsSpreadsheetFileTypeMap()
	
	FormatMatching = New Map;
	FormatMatching.Insert(Enums.ObjectsExportFormats.ANSITXT, SpreadsheetDocumentFileType.ANSITXT);
	FormatMatching.Insert(Enums.ObjectsExportFormats.TXT, SpreadsheetDocumentFileType.TXT);
	FormatMatching.Insert(Enums.ObjectsExportFormats.XLS, SpreadsheetDocumentFileType.XLS);
	FormatMatching.Insert(Enums.ObjectsExportFormats.XLSX, SpreadsheetDocumentFileType.XLSX);
	FormatMatching.Insert(Enums.ObjectsExportFormats.HTML5, SpreadsheetDocumentFileType.HTML5);
	FormatMatching.Insert(Enums.ObjectsExportFormats.MXL, SpreadsheetDocumentFileType.MXL);
	
	Return FormatMatching;
	
EndFunction

// Generates a list of print commands collected from several objects.
Procedure FillExportCommandsForObjectList(ListOfObjects, ExportCommands)
	
	SourcesOfExportCommands = New Map;
	For Each PrintCommandsSource In PrintManagement.PrintCommandsSources() Do
		SourcesOfExportCommands.Insert(PrintCommandsSource, True);
	EndDo;
	
	For Each MetadataObject In ListOfObjects Do
		
		If SourcesOfExportCommands[MetadataObject] = Undefined Then
			Continue;
		EndIf;
		
		FormExportCommands = ObjectExportCommands(MetadataObject); // @skip-check query-in-loop - Small cycle
		
		For Each ExportCommandToAdd In FormExportCommands Do
			
			If ExportCommandToAdd.TurnedOff Then
				Continue;
			EndIf;
			
			Filter = New Structure("UUID", ExportCommandToAdd.UUID);
			FoundCommands = ExportCommands.FindRows(Filter);
			
			If FoundCommands.Count() > 0 Then
				Continue;
			EndIf;
			
			If ExportCommandToAdd.PrintObjectsTypes.Count() = 0 Then
				
				AdditionalParameters = ExportCommandToAdd.AdditionalParameters;
				If ValueIsFilled(AdditionalParameters.SourceType) Then
					
					ExportCommandToAdd.PrintObjectsTypes.Add(AdditionalParameters.SourceType);
					
				Else
					
					ObjectType = Type(StrReplace(MetadataObject.FullName(), ".", "Ref."));
					ExportCommandToAdd.PrintObjectsTypes.Add(ObjectType);
					
				EndIf;
				
			EndIf;
			
			FillPropertyValues(ExportCommands.Add(), ExportCommandToAdd);
			
		EndDo;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion
