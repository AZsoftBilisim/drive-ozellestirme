#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a report in the specified table document
//
// Parameters:
// 		SpreadsheetDocument - SpreadsheetDocument - Table document for generating the report.
Procedure GenerateReport(SpreadsheetDocument) Export
	
	Template = ThisObject.GetTemplate("ReportTemplate");
	
	CheckParameters = Catalogs.Assets.FillVerificationParameters();
	CheckParameters.Report_Errors = False;
	
	HasErrors = False;
	
	Catalogs.Assets.CheckFillingOfObjectOfOperation(Asset, CheckParameters, HasErrors);
	
	Errors = CheckParameters.ErrorStream;
	NodeErrors = CheckParameters.NodeVerificationParameters.ErrorStream;
	
	OutputReportHeader(SpreadsheetDocument, Template);
	
	If HasErrors Then
		
		SpreadsheetDocument.StartRowAutoGrouping();
		
		PrintTableHeader(SpreadsheetDocument, Template);
		
		Area = Template.GetArea("String");
		Area.Parameters.ErrorObject = Asset;
		SpreadsheetDocument.Put(Area, 0, String(Asset), True);
		
		OutputErrors(SpreadsheetDocument, Asset, 0, Errors, Template);
		
		Query = New Query(
			"SELECT
			|	Nodes.Ref AS ErrorObject
			|FROM
			|	Catalog.SubAssets AS Nodes
			|WHERE
			|	Nodes.Parent = &Parent
			|	AND Nodes.Owner = &Owner
			|	AND Nodes.Status IN (VALUE(Enum.AssetStatuses.InOperation), VALUE(Enum.AssetStatuses.EmptyRef))");
		Query.SetParameter("Parent", Catalogs.SubAssets.EmptyRef());
		Query.SetParameter("Owner", Asset);
		
		Result = Query.Execute();
		If Not Result.IsEmpty() Then
			
			Selection = Result.Select();
			While Selection.Next() Do
				PrintErrorObject(SpreadsheetDocument, Selection.ErrorObject, 1, NodeErrors, Template);
			EndDo;
			
		EndIf;
		
		SpreadsheetDocument.EndRowAutoGrouping();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure OutputReportHeader(SpreadsheetDocument, Template)
	
	// Output of the report title
	ReportHeaderTemplate = NStr("vi = 'Kiểm tra tính chính xác của việc điền tài sản đang vận hành ""%Description%""';
								|ru = 'Контроль корректности заполнения объекта эксплуатации ""%Description%""';
								|en = 'Control the accuracy of population of the ""%Description%"" asset'; fa = 'Control the accuracy of population of the ""%Description%"" asset';
								|it = 'Controllo della correttezza della compilazione dell''oggetto di esercizio ""%Description%""';
								|pl = 'Kontrola poprawności wypełnienia obiektu operacji ""%Description%""';
								|tr = '""%Description%"" İşlem nesnelerinin dolumunun doğruluğunu kontrol etme'");
	TemplateArea = Template.GetArea("ReportHeader");
	TemplateArea.Parameters.Title = StrReplace(ReportHeaderTemplate, "%Description%", Asset);
	SpreadsheetDocument.Put(TemplateArea);
	
EndProcedure

Procedure PrintTableHeader(SpreadsheetDocument, Template)
	
	TemplateArea = Template.GetArea("TableHeading");
	SpreadsheetDocument.Put(TemplateArea);
	
EndProcedure

Procedure PrintErrorObject(SpreadsheetDocument, ErrorObject, Level, ErrorStream, Template)
	
	Area = Template.GetArea("String");
	Area.Parameters.ErrorObject = ErrorObject;
	SpreadsheetDocument.Put(Area, Level, String(ErrorObject), True);
	
	OutputErrors(SpreadsheetDocument, ErrorObject, Level, ErrorStream, Template);
	
	Query = New Query(
		"SELECT
		|	Nodes.Ref AS ErrorObject
		|FROM
		|	Catalog.SubAssets AS Nodes
		|WHERE
		|	Nodes.Parent = &Parent
		|	AND Nodes.Owner = &Owner
		|	AND Nodes.Status IN (VALUE(Enum.AssetStatuses.InOperation))");
	Query.SetParameter("Parent", ErrorObject);
	Query.SetParameter("Owner", Asset);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	While Selection.Next() Do
		PrintErrorObject(SpreadsheetDocument, Selection.ErrorObject, Level+1, ErrorStream, Template);
	EndDo;
	
EndProcedure

Procedure OutputErrors(SpreadsheetDocument, ErrorObject, Level, ErrorStream, Template)
	
	ErrorCounter = ErrorStream.ErrorCounter; // Map
	If ErrorCounter.Get(ErrorObject) = Undefined Then
		Return;
	EndIf;
	
	ErrorArea_ = Template.GetArea("Error");
	For Each Error In ErrorStream.ErrorList Do
		
		If Error.ErrorObject = ErrorObject Then
		
			ErrorArea_.Parameters.Fill(Error);
			SpreadsheetDocument.Put(ErrorArea_, Level+1, String(ErrorObject), True);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
