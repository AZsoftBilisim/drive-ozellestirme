#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns names of blocked details for the BSP details blocking mechanism
//
// Returns:
//	Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	
	Result.Add("WorkCenterType;Department");
	Result.Add("ProductionArea");
	
	Return Result;
	
EndFunction

// Returns the names of attributes, which should not appear in the list of details of the processing Gruposeincentivos.
//
//	Returns:
//		Array - an array of the names of the details.
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array;
	NotAttributesToEdit.Add("WorkCenterType");
	
	Return NotAttributesToEdit;
	
EndFunction

#Region Commands

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "WorkingCenterLabelElement";
	PrintCommand.Presentation = NStr("vi = 'Nhãn tem nguồn lực sản xuất';
									|ru = 'Этикетка рабочего центра';
									|en = 'Work center label'; fa = 'برچسب مرکز کاری';
									|it = 'Etichetta del centro operativo';
									|pl = 'Etykieta centrum pracy';
									|tr = 'İş merkezi etiketi'");
	PrintCommand.FormsList = "ItemForm";
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.Handler = "PrintManagementERPClient.PrintWorkCenterLabel";
	
	//
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "WorkCenterLabelList";
	PrintCommand.Presentation = NStr("vi = 'Nhãn tem nguồn lực sản xuất';
									|ru = 'Этикетка рабочего центра';
									|en = 'Work center label'; fa = 'برچسب مرکز کاری';
									|it = 'Etichetta del centro operativo';
									|pl = 'Etykieta centrum pracy';
									|tr = 'İş merkezi etiketi'");
	PrintCommand.FormsList = "WorkCenterStructure,ListForm";
	PrintCommand.CheckPostingBeforePrint = True;
	
EndProcedure

#EndRegion

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

#Region Private

#Region Print

// Generates a printable form.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "WorkingCenterLabelElement") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"WorkingCenterLabelElement",
			NStr("vi = 'Nhãn tem nguồn lực sản xuất';
				|ru = 'Этикетка рабочего центра';
				|en = 'Work center label'; fa = 'برچسب مرکز کاری';
				|it = 'Etichetta del centro operativo';
				|pl = 'Etykieta centrum pracy';
				|tr = 'İş merkezi etiketi'"),
			FormPrintedFormLabelWorkingCenter(ObjectsArray, PrintObjects, PrintParameters));
			
	ElsIf PrintManagement.TemplatePrintRequired(PrintFormsCollection, "WorkCenterLabelList") Then 
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"WorkCenterLabelList",
			NStr("vi = 'Nhãn tem nguồn lực sản xuất';
				|ru = 'Этикетка рабочего центра';
				|en = 'Work center label'; fa = 'برچسب مرکز کاری';
				|it = 'Etichetta del centro operativo';
				|pl = 'Etykieta centrum pracy';
				|tr = 'İş merkezi etiketi'"),
			FormPrintedFormLabelWorkingCenter(ObjectsArray, PrintObjects, PrintParameters));
		
	EndIf;
	
	PrintFormGeneration.FillInSendingParameters(
		OutputParameters.SendOptions,
		ObjectsArray,
		PrintFormsCollection);
	
EndProcedure

Function FormPrintedFormLabelWorkingCenter(ObjectsArray, PrintObjects, PrintParameters)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PageOrientation = PageOrientation.Portrait;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_RC_Person";
	
	Template = PrintManagement.PrintFormTemplate("Catalog.WorkCenters.PF_MXL_WorkCenterLabel");
	Selection = DataForPrintingWorkCenterLabel(ObjectsArray);
	
	While Selection.Next() Do
	
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		Area = Template.GetArea("Label_");
		
		Area.Parameters.Fill(Selection);
			
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(
			SpreadsheetDocument,
			Template,
			Area,
			Selection.Ref);
		
		SpreadsheetDocument.Put(Area);
		
	EndDo;
	
	If PrintParameters.Property("PrintIndividuals") And PrintParameters.PrintIndividuals Then
		
		Template = PrintManagement.PrintFormTemplate("Catalog.WorkCenters.PF_MXL_PersonLabel");
		Selection = DataForPrintingIndividual(ObjectsArray);
		
		While Selection.Next() Do
		
			RowNumberStart = SpreadsheetDocument.TableHeight + 1;
			
			Area = Template.GetArea("Label_");
			
			Area.Parameters.Fill(Selection);
				
			BarcodingOfPrintForms.OutputBarcodeToTabularDocument(
				SpreadsheetDocument,
				Template,
				Area,
				Selection.Ref);
			
			SpreadsheetDocument.Put(Area);
			
		EndDo;
	EndIf;
	
	Return SpreadsheetDocument;
EndFunction

Function DataForPrintingWorkCenterLabel(References)
	
	Query = New Query(
		"SELECT
		|	WorkCenters.Ref                           AS Ref,
		|	PRESENTATION(WorkCenters.Ref)            AS RCPresentation,
		|	PRESENTATION(WorkCenters.WorkCenterType) AS VRCPresentation
		|FROM
		|	Catalog.WorkCenters AS WorkCenters
		|WHERE
		|	WorkCenters.Ref IN (&References)");
	
	Query.SetParameter("References", References);
	
	SetPrivilegedMode(True);
	Return Query.Execute().Select();
	
EndFunction

Function DataForPrintingIndividual(References)
	
	Query = New Query(
		"SELECT
		|	Persons.Ref AS Ref,
		|	Persons.LastFirstName AS LastFirstName,
		|	WorkCenters.WorkCenterType.Department AS Department
		|FROM
		|	Catalog.Persons AS Persons,
		|	Catalog.WorkCenters AS WorkCenters
		|WHERE
		|	Persons.Ref IN (&Individuals)
		|	AND WorkCenters.Ref IN (&WorkCenter)
		|");
	
	Query.SetParameter("WorkCenter", References);
	
	Query.SetParameter("Individuals", References);
	
	
	SetPrivilegedMode(True);
	Return Query.Execute().Select();
	
EndFunction

#EndRegion

#EndRegion

#EndIf