///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region ObsoleteProceduresAndFunctions

// Deprecated. Instead, use "PrintManagement.TemplatesAndObjectsDataToPrint" and 
// the generation of print forms from office document templates. 
// Gets all data required for printing within a single call: object template data, binary
// template data, and template area description.
// Used for calling print forms based on office document templates from client modules.
//
// Parameters:
//   PrintManagerName - String - Name used for accessing the object manager. For example, "Document.<Document name>".
//   TemplatesNames       - String - Names of templates used for print form generation.
//   DocumentsComposition   - Array - References to infobase objects (all references must be of the same type).
//
// Returns:
//  Map of KeyAndValue - Collection of references to objects and their data.:
//   * Key - AnyRef - Reference to an infobase object.
//   * Value - Structure:
//       ** Key - String - Template name.
//       ** Value - Structure - Object data.
//
Function TemplatesAndObjectsDataToPrint(Val PrintManagerName, Val TemplatesNames, Val DocumentsComposition) Export
	
	Return PrintManagement.TemplatesAndObjectsDataToPrint(PrintManagerName, TemplatesNames, DocumentsComposition);
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Generates print forms for direct output to a printer.
//
// Detailed - See PrintManagement.GeneratePrintFormsForQuickPrint().
//
Function GeneratePrintFormsForQuickPrint(PrintManagerName, TemplatesNames, ObjectsArray,	PrintParameters) Export
	
	Return PrintManagement.GeneratePrintFormsForQuickPrint(PrintManagerName, TemplatesNames,
		ObjectsArray,	PrintParameters);
	
EndFunction

// Generates print forms for direct output to a printer in an ordinary application.
//
// Detailed - See PrintManagement.GeneratePrintFormsForQuickPrintOrdinaryApplication().
//
Function GeneratePrintFormsForQuickPrintOrdinaryApplication(PrintManagerName, TemplatesNames, ObjectsArray, PrintParameters) Export
	
	Return PrintManagement.GeneratePrintFormsForQuickPrintOrdinaryApplication(PrintManagerName, TemplatesNames,
		ObjectsArray,	PrintParameters);
	
EndFunction

// Generates print forms according to the run print command.
//
// For details, see "PrintManagement.GeneratePrintForms".
//
Function GeneratePrintForms(ObjectsArray, Commands) Export
	
	Result = New Structure;
	Result.Insert("PrintObjects");
	Result.Insert("PrintFormsCollection");
	Result.Insert("OutputParameters");
	
	PrintFormsCollection = New ValueTable;
	For Each ColumnName In PrintManagementClientServer.PrintFormsCollectionFieldsNames() Do
		PrintFormsCollection.Columns.Add(ColumnName);
	EndDo;
	
	PrintObjects = New ValueList;
	
	For Each PrintCommand In Commands Do
		ThisIsExternalPrintingForm = (PrintCommand.PrintManager = "StandardSubsystems.AdditionalReportsAndDataProcessors");
		
		If ThisIsExternalPrintingForm Then
			Source = PrintCommand.AdditionalParameters.Ref;
			PrintForms = PrintManagement.GenerateExternalPrintForm(Source, PrintCommand.Id, ObjectsArray, PrintObjects);
		Else
			PrintForms = PrintManagement.GeneratePrintForms(
				PrintCommand.PrintManager,
				PrintCommand.Id,
				ObjectsArray,
				PrintCommand.AdditionalParameters,
				,
				,
				PrintObjects);
		EndIf;
		
		PrintObjects = PrintForms.PrintObjects;
		CommonClientServer.SupplementTable(PrintForms.PrintFormsCollection, PrintFormsCollection);
		If Not ThisIsExternalPrintingForm Then
			PrintManagement.OnExecutePrintCommand(ObjectsArray, PrintCommand, PrintFormsCollection);
		EndIf;
	EndDo;
	
	Result.PrintObjects = PrintObjects;
	Result.PrintFormsCollection = Common.ValueTableToArray(PrintFormsCollection);
	
	OutputParameters = PrintManagement.PrepareOutputParametersStructure();
	SendOptions = OutputParameters.SendOptions;
	SendOptions.Recipient = PrintForms.OutputParameters.SendOptions.Recipient;
	
	If PrintFormsCollection.Count() = 1 Then
		SendOptions.Subject = PrintFormsCollection[0].TemplateSynonym;
	Else 
		SendOptions.Subject = NStr("vi = 'Chứng từ';
									|ru = 'Документы';
									|en = 'Documents'; fa = 'اسناد';
									|it = 'Documents';
									|pl = 'Documents';
									|tr = 'Belgeler'");
	EndIf;
	
	Result.OutputParameters = OutputParameters;
	
	Return Result;
	
EndFunction

// Generates print forms in the given format and saves them to files.
//
// For details, see "PrintManagement.PrintToFile".
//
Function PrintToFile(PrintCommands, ListOfObjects, SettingsForSaving) Export
	
	Result = PrintManagement.PrintToFile(PrintCommands, ListOfObjects, SettingsForSaving);
	Return Common.ValueTableToArray(Result);
	
EndFunction

// See PrintManagement.DocumentsPackage.
Function DocumentsPackage(SpreadsheetDocuments, PrintObjects, PrintInSets, Copies = 1) Export
	
	Return PrintManagement.DocumentsPackage(SpreadsheetDocuments, PrintObjects,
		PrintInSets, Copies);
	
EndFunction

Function DefaultPrintExecutionParameters(Val References) Export
	Return PrintManagement.DefaultPrintExecutionParameters(References);
EndFunction

Function SavedDescriptions(Val Objects) Export
	Return InformationRegisters.DefaultObjectPrintForms.SavedDescriptions(Objects);
EndFunction

Function DefaultPrintFormInSet(Val ObjectsArray, Val PrintCommand) Export
	Return PrintManagement.DefaultPrintFormInSet(ObjectsArray, PrintCommand);
EndFunction

Function CreatePrintCommand() Export
	CollectionOfPrintCommands = PrintManagement.CreatePrintCommandsCollection();
	Return Common.ValueTableRowToStructure(CollectionOfPrintCommands.Add());
EndFunction

#Region PrintingInBackgroundJob

Function StartGeneratingPrintForms(ParametersForOpeningIncoming) Export
	
	OpeningParameters = Common.CopyRecursive(ParametersForOpeningIncoming);
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(OpeningParameters.StorageUUID);
	ExecutionParameters.ResultAddress = PutToTempStorage(Undefined, OpeningParameters.StorageUUID);
	StoragesContents = Undefined;
	ExtractFromRepositories(OpeningParameters.PrintParameters, StoragesContents);
	OpeningParameters.Insert("StoragesContents", StoragesContents);
	If Not ValueIsFilled(OpeningParameters.DataSource) Then 
		CommonClientServer.Validate(TypeOf(OpeningParameters.CommandParameter) = Type("Array") Or Common.RefTypeValue(OpeningParameters.CommandParameter),
			StringFunctionsClientServer.SubstituteParametersToString(NStr(
				"vi = 'Sai giá trị tham số %1 khi gọi ra phương thức %2.
				|Dự kiến: %3, %4.
				|Đã chuyển: %5';
				|ru = 'Недопустимое значение параметра %1 при вызове метода %2.
				|Ожидалось: %3, %4.
				|Передано: %5';
				|en = 'Invalid parameter value. %1 parameter, %2 method.
				|Expected value: %3, %4.
				|Passed value: %5.'; fa = 'Invalid parameter value. %1 parameter, %2 method.
				|Expected value: %3, %4.
				|Passed value: %5.';
				|it = 'Valore del parametro %1 durante la chiamata del metodo %2 non è valido.
				|Valore previsto: %3, %4.
				|Valore trasmesso: %5';
				|pl = 'Niedopuszczalna wartość parametru %1 podczas wywołania metody %2.
				|Oczekiwało się: %3, %4.
				|Przekazano: %5';
				|tr = '%2yöntemin çağrısında geçersiz parametre%1 değeri.
				|Beklenen: %3, %4.
				|Aktarılan: %5 '"),
				"CommandParameter",
				"PrintManagementClient.ExecutePrintCommand",
				"Array",
				"AnyRef",
				 TypeOf(OpeningParameters.CommandParameter)));
	EndIf;

	// Support of backward compatibility with version 2.1.3.
	PrintParameters = OpeningParameters.PrintParameters;
	If OpeningParameters.PrintParameters = Undefined Then
		PrintParameters = New Structure;
	EndIf;
	If Not PrintParameters.Property("AdditionalParameters") Then
		OpeningParameters.PrintParameters = New Structure("AdditionalParameters", PrintParameters);
		For Each PrintParameter In PrintParameters Do
			OpeningParameters.PrintParameters.Insert(PrintParameter.Key, PrintParameter.Value);
		EndDo;
	EndIf;
			
	Return TimeConsumingOperations.ExecuteFunction(ExecutionParameters, "PrintManagement.GeneratePrintFormsInBackground", OpeningParameters);
EndFunction 

Procedure ExtractFromRepositories(ParametersStructure, StoragesContents)
	If StoragesContents = Undefined Then
		StoragesContents = New Map;
	EndIf;
	
	ParametersType = TypeOf(ParametersStructure);
	If ParametersType = Type("String") And IsTempStorageURL(ParametersStructure) Then
		StoragesContents.Insert(ParametersStructure, GetFromTempStorage(ParametersStructure));
	ElsIf ParametersType = Type("Array") Or ParametersType = Type("ValueTable") 
		Or ParametersType = Type("ValueTableRow") Or ParametersType = Type("ValueTreeRow") Then
		
		For Each Item In ParametersStructure Do
			ExtractFromRepositories(Item, StoragesContents);
		EndDo;
	ElsIf ParametersType = Type("Structure") Or ParametersType = Type("Map") Then
		
		For Each Item In ParametersStructure Do
			ExtractFromRepositories(Item.Value, StoragesContents);
		EndDo;
		
		If ParametersType = Type("Map") Then
			For Each Item In ParametersStructure Do
				ExtractFromRepositories(Item.Key, StoragesContents);
			EndDo;
		EndIf;

	ElsIf  ParametersType = Type("ValueTree") Then
		For Each Item In ParametersStructure.Rows Do
			ExtractFromRepositories(Item, StoragesContents);
		EndDo;
	EndIf;
	
EndProcedure
#EndRegion

#EndRegion
