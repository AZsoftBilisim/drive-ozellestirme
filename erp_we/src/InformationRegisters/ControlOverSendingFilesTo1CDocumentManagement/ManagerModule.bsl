#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// adds the sum of the Cur version of the printed form to the hash register.
//
// Parameters:
//   Object - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - reference to the IP object.
//   FileName - String - the name of the printed form.
//   SpreadsheetDocument - SpreadsheetDocument - the formed printed form.
//
Procedure SaveHashSumOfFileVersion(Object, FileName, SpreadsheetDocument) Export
	
	Manager = InformationRegisters.ControlOverSendingFilesTo1CDocumentManagement.CreateRecordManager();
	
	Manager.Period = CurrentSessionDate();
	Manager.Object = Object;
	Manager.FileName = FileName;
	Manager.HashSum = HashSum(SpreadsheetDocument);
	
	Manager.Write();
	
EndProcedure

// checks whether there are changes in the Cur version of the printed form compared to the previous
// version sent to the workflow.
//
// Parameters:
//   Object - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - reference to the IP object.
//   FileName - String - the name of the printed form.
//   SpreadsheetDocument - SpreadsheetDocument - the formed printed form.
//
// Returns:
//   Boolean - True if the printed form has already been sent to the Workflow earlier.
//
Function FileHasAlreadyBeenSent(Object, FileName, SpreadsheetDocument) Export
	
	Query = New Query(
		"SELECT TOP 1
		|	ControlOverSendingFilesTo1CDocumentManagementSliceLast.HashSum AS HashSum
		|FROM
		|	InformationRegister.ControlOverSendingFilesTo1CDocumentManagement.SliceLast(
		|			,
		|			Object = &Object
		|				AND FileName = &FileName) AS ControlOverSendingFilesTo1CDocumentManagementSliceLast
		|WHERE
		|	ControlOverSendingFilesTo1CDocumentManagementSliceLast.HashSum = &HashSum");
	Query.SetParameter("Object", Object);
	Query.SetParameter("FileName", FileName);
	Query.SetParameter("HashSum", HashSum(SpreadsheetDocument));
	
	QueryResult = Query.Execute();
	
	Return Not QueryResult.IsEmpty();
	
EndFunction

#EndRegion

#Region Private

Function HashSum(SpreadsheetDocument)
	
	TextOfTabularDocument = New Array;
	For LineNumber = 1 To SpreadsheetDocument.TableHeight Do
		For ColumnNumber = 1 To SpreadsheetDocument.TableWidth Do
			CurrentArea = SpreadsheetDocument.Area(
				StrTemplate("R%1C%2",
					Format(LineNumber, "NZ=0; NG=0"),
					Format(ColumnNumber, "NZ=0; NG=0")));
			TextOfTabularDocument.Add(BorderPresentation(CurrentArea.TopBorder));
			TextOfTabularDocument.Add(BorderPresentation(CurrentArea.LeftBorder));
			TextOfTabularDocument.Add(BorderPresentation(CurrentArea.BottomBorder));
			TextOfTabularDocument.Add(BorderPresentation(CurrentArea.RightBorder));
			TextOfTabularDocument.Add(CurrentArea.Text);
			TextOfTabularDocument.Add(String(CurrentArea.Font));
		EndDo;
	EndDo;
	For Each Drawing In SpreadsheetDocument.Drawings Do
		TextOfTabularDocument.Add(PictureRepresentation(Drawing));
	EndDo;
	Hash = New DataHashing(HashFunction.MD5);
	Hash.Append(StrConcat(TextOfTabularDocument, ""));
	
	Return Base64String(Hash.HashSum);
	
EndFunction

Function BorderPresentation(Boundary)
	
	Return StrTemplate("%1%2%3", Boundary.Gap, Boundary.LineType, Boundary.Width);
	
EndFunction

Function PictureRepresentation(Drawing)
	
	Return StrTemplate("%1%2%3%4%5", Drawing.Top, Drawing.Left, Drawing.Height, Drawing.Width, Drawing.Name);
	
EndFunction

#EndRegion

#EndIf