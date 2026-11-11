#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// Hotkey
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "KeyboardShortcuts";
	PrintCommand.Presentation = NStr("vi = 'Phím tắt';
									|ru = 'Горячие клавиши';
									|en = 'Keyboard shortcuts'; fa = 'میان‌برهای صفحه‌کلید';
									|it = 'Tasti di ricerca veloce';
									|pl = 'Skróty klawiszowe';
									|tr = 'Kısayollar'");

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "KeyboardShortcuts") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "KeyboardShortcuts", "KeyboardShortcuts", GeneratePrintForm(ObjectsArray, PrintObjects));
	EndIf;
	
EndProcedure

Function GeneratePrintForm(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	QueryResult = GetDataToPrint(ObjectsArray);
	Selection = QueryResult.Select();
	
	FirstDocument = True;
	
	While Selection.Next() Do
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		FillInTabularDocumentBasedOnObjectData(SpreadsheetDocument, GetObjectDataFromSelection(Selection));
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, Selection.Ref);
		
	EndDo;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

Function GetDataToPrint(ObjectsArray)
	
	Query = New Query();
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.Text = 
	"SELECT
	|	CatalogKeyboardShortcuts.Ref        AS Ref,
	|	CatalogKeyboardShortcuts.QuickGoods AS QuickGoods,
	|	CatalogKeyboardShortcuts.FormCommands  AS FormCommands
	|FROM
	|	Catalog.KeyboardShortcuts AS CatalogKeyboardShortcuts
	|WHERE
	|	CatalogKeyboardShortcuts.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	CatalogKeyboardShortcuts.Ref";
	
	Return Query.Execute();
	
EndFunction

Function GetObjectDataFromSelection(Selection)
	
	ObjectData = New Structure;
	
	ObjectData.Insert("Ref",        Selection.Ref);
	ObjectData.Insert("QuickGoods", Selection.QuickGoods);
	ObjectData.Insert("FormCommands",  Selection.FormCommands);
	
	Return ObjectData;
	
EndFunction

Procedure FillInTabularDocumentBasedOnObjectData(SpreadsheetDocument, ObjectData)
	
	Template = PrintManagement.PrintFormTemplate("Catalog.KeyboardShortcuts.PF_MXL_KeyboardShortcuts");
	
	Area = Template.GetArea("Title");
	FillPropertyValues(Area.Parameters, ObjectData);
	SpreadsheetDocument.Put(Area);
	
	Area = Template.GetArea("String");
	ObjectDataFastProducts = ObjectData.QuickGoods; // ValueStorage
	QuickGoods = ObjectDataFastProducts.Get(); // ValueTable - See Catalog.KeyboardShortcuts.Form.ItemForm.QuickGoods
	For Each TSRow In QuickGoods Do
		Parameters = New Structure("Description, Shortcut",
		TSRow.Title, TSRow.Shortcut);
		FillPropertyValues(Area.Parameters, Parameters);
		SpreadsheetDocument.Put(Area);
	EndDo;
	
	FormCommandObjectData = ObjectData.FormCommands; // ValueStorage
	FormCommands = FormCommandObjectData.Get(); // ValueTable - See Catalog.KeyboardShortcuts.Form.ItemForm.QuickGoods
	For Each TSRow In FormCommands Do
		Parameters = New Structure("Description, Shortcut",
		TSRow.Title, TSRow.Shortcut);
		FillPropertyValues(Area.Parameters, Parameters);
		SpreadsheetDocument.Put(Area);
	EndDo;
	
	Area = Template.GetArea("Footer");
	SpreadsheetDocument.Put(Area);
	
EndProcedure

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

// Parameters:
// 	Table - ValueTable - QuickGoods:
// 		* Products - CatalogRef.Products
// 		* Characteristic - CatalogRef.ItemsCharacteristics
// 		* Package - CatalogRef.PackagesAndUnitsOfMeasure
// 		* Title - String
// 		* Key - String
// 		* Alt - Boolean
// 		* Ctrl - Boolean
// 		* Shift - Boolean
// 		* Shortcut - String
// 		* ItemVariantsAreUsed - Boolean
// 	CommandData - ValueTableRow
// Returns:
// 		ValueTableRow
//
Function NewCommand(Table, CommandData) Export
	
	NewRow = Table.Add();
	NewRow.Command   = CommandData.CommandName;
	NewRow.Title = CommandData.Title;
	NewRow.Key   = CommandData.Shortcut.Key;
	NewRow.Alt       = CommandData.Shortcut.Alt;
	NewRow.Ctrl      = CommandData.Shortcut.Ctrl;
	NewRow.Shift     = CommandData.Shortcut.Shift;
	
	NewRow.Shortcut = KeyboardShortcutPresentation(CommandData.Shortcut);
	
	Return NewRow;
	
EndFunction

Function KeyboardShortcutPresentation(Combination) Export
	
	Return TMCommonUse.KeyboardShortcutPresentation(Combination, True);
	
EndFunction

#EndRegion

#EndIf