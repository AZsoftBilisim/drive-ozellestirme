///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Common.IsMobileClient() Then
		Cancel = True;
		Raise NStr("vi = 'Thao tác không hợp lệ trong mobile client, hãy sử dụng thin client.';
					|ru = 'Операция не доступна в мобильном клиенте, используйте тонкий клиент.';
					|en = 'The operation is not available in the mobile client. Use the thin client.'; fa = 'The operation is not available in the mobile client. Use the thin client.';
					|it = 'Operazione non disponibile nel client mobile, utilizzare thin client.';
					|pl = 'Operacje nie jest dostępna w kliencie mobilnym, używaj cienkiego klienta.';
					|tr = 'İşlem mobil istemcide kullanılamaz, ince istemciyi kullanın.'");
	EndIf;
	
	SpreadsheetDocumentsToCompare = GetFromTempStorage(Parameters.SpreadsheetDocumentsAddress);
	DeleteFromTempStorage(Parameters.SpreadsheetDocumentsAddress);
	SpreadsheetDocumentLeft = PrepareSpreadsheetDocument(SpreadsheetDocumentsToCompare.Left_1);
	SpreadsheetDocumentRight = PrepareSpreadsheetDocument(SpreadsheetDocumentsToCompare.Right);
	
	Items.LeftSpreadsheetDocumentGroup.Title = Parameters.TitleLeft;
	Items.RightSpreadsheetDocumentGroup.Title = Parameters.TitleRight;
	
	If Not IsBlankString(Parameters.Title) Then
		Title = Parameters.Title;
	EndIf;
	
	DisableOnActivateHandler = True;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("StartCompareAtClient", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSpreadsheetDocumentLeft

&AtClient
Procedure SpreadsheetDocumentLeftOnActivate(Item)
	
	If DisableOnActivateHandler = True Then
		Return;
	EndIf;
	
	Source = New Structure("Object, Item", SpreadsheetDocumentLeft, Items.SpreadsheetDocumentLeft);
	Receiver = New Structure("Object, Item", SpreadsheetDocumentRight, Items.SpreadsheetDocumentRight);
	
	MatchesSource = New Structure("Rows, Columns2", RowsMapLeft, ColumnsMapLeft);
	MatchesDestination = New Structure("Rows, Columns2", RowsMapRight, ColumnsMapRight);
	
	ProcessAreaActivation(Source, Receiver, MatchesSource, MatchesDestination);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSpreadsheetDocumentRight

&AtClient
Procedure SpreadsheetDocumentRightOnActivate(Item)
	
	If DisableOnActivateHandler = True Then
		Return;
	EndIf;
		
	Source = New Structure("Object, Item", SpreadsheetDocumentRight, Items.SpreadsheetDocumentRight);
	Receiver = New Structure("Object, Item", SpreadsheetDocumentLeft, Items.SpreadsheetDocumentLeft);
	
	MatchesSource = New Structure("Rows, Columns2", RowsMapRight, ColumnsMapRight);
	MatchesDestination = New Structure("Rows, Columns2", RowsMapLeft, ColumnsMapLeft);
	
	ProcessAreaActivation(Source, Receiver, MatchesSource, MatchesDestination);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PreviousChangeLeftCommand(Command)
	
	PreviousChange(Items.SpreadsheetDocumentLeft, SpreadsheetDocumentLeft, CellDifferencesLeft);
	
EndProcedure

&AtClient
Procedure PreviousChangeRightCommand(Command)
	
	PreviousChange(Items.SpreadsheetDocumentRight, SpreadsheetDocumentRight, CellDifferencesRight);
	
EndProcedure

&AtClient
Procedure NextChangeLeftCommand(Command)
	
	NextChange(Items.SpreadsheetDocumentLeft, SpreadsheetDocumentLeft, CellDifferencesLeft);
	
EndProcedure

&AtClient
Procedure NextChangeRightCommand(Command)
	
	NextChange(Items.SpreadsheetDocumentRight, SpreadsheetDocumentRight, CellDifferencesRight);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure StartCompareAtClient()
	
	DisableOnActivateHandler = True;
			
	RowsMapLeft = New ValueList;
	RowsMapRight = New ValueList;
	
	ColumnsMapLeft = New ValueList;
	ColumnsMapRight = New ValueList;
	
	CellDifferencesLeft.Clear();
	CellDifferencesRight.Clear();
	
	TimeConsumingOperation = StartCompareAtServer();
	CallbackOnCompletion = New CallbackDescription("OutputResultAtClient", ThisObject);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.MessageText = NStr("vi = 'Thực hiện so sánh chứng từ.';
										|ru = 'Выполняется сравнение документов.';
										|en = 'Comparing documents.'; fa = 'Comparing documents.';
										|it = 'Comparing documents.';
										|pl = 'Comparing documents.';
										|tr = 'Belge karşılaştırması yapılıyor.'");
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtServer
Function StartCompareAtServer()
	
	LeftDocumentTable = ReadSpreadsheetDocument(SpreadsheetDocumentLeft);
	RightDocumentTable = ReadSpreadsheetDocument(SpreadsheetDocumentRight);
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	Return TimeConsumingOperations.ExecuteFunction(ExecutionParameters, "StandardSubsystemsServer.CompareTables",
		LeftDocumentTable, RightDocumentTable);
		
EndFunction

&AtClient
Procedure OutputResultAtClient(Result, AdditionalParameters) Export
	
	DisableOnActivateHandler = False;
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	OutputResultAtServer(Result.ResultAddress);
	NextChange(Items.SpreadsheetDocumentLeft, SpreadsheetDocumentLeft, CellDifferencesLeft);
	
EndProcedure 

&AtServer
Procedure OutputResultAtServer(ResultAddress)
	
#Region Comparison
	
	ComparisonResult = GetFromTempStorage(ResultAddress);
	
	// Comparing the spreadsheet documents by lines and selecting the matching lines.
	Maps1 = ComparisonResult.RowMappings;
	RowsMapLeft = Maps1[0];
	RowsMapRight = Maps1[1];
	
	// Comparing the spreadsheet documents by columns and selecting the matching columns.
	Maps1 = ComparisonResult.ColumnMappings;
	ColumnsMapLeft = Maps1[0];
	ColumnsMapRight = Maps1[1];
	
	LeftDocumentTable = Undefined;
	RightDocumentTable = Undefined;
	
#EndRegion
	
#Region DifferencesView
	
	DeletedAreaColorBackground	= StyleColors.DeletedAttributeBackground;
	AddedAreaColorBackground	= StyleColors.AddedAttributeBackground;
	ChangedAreaColorBackground	= StyleColors.ModifiedAttributeValueBackground;
	ChangedAreaColorText	= StyleColors.ModifiedAttributeValueColor;
		
	
	LeftTableHeight = SpreadsheetDocumentLeft.TableHeight;
	LeftTableWidth = SpreadsheetDocumentLeft.TableWidth;
	
	RightTableHeight = SpreadsheetDocumentRight.TableHeight;
	RightTableWidth = SpreadsheetDocumentRight.TableWidth;

	// Lines that were deleted from the left spreadsheet document.
	For LineNumber = 1 To RowsMapLeft.Count()-1 Do
		
		If RowsMapLeft[LineNumber].Value = Undefined Then
			
			Area = SpreadsheetDocumentLeft.Area(LineNumber, 1, LineNumber, LeftTableWidth);
			Area.BackColor = DeletedAreaColorBackground;
			
			NewDifferenceRow = CellDifferencesLeft.Add();
			NewDifferenceRow.LineNumber = LineNumber;
			NewDifferenceRow.ColumnNumber = 0;
			
		EndIf;
		
	EndDo;
	
	// Columns that were deleted from the left spreadsheet document.
	For ColumnNumber = 1 To ColumnsMapLeft.Count()-1 Do
		
		If ColumnsMapLeft[ColumnNumber].Value = Undefined Then
			
			Area = SpreadsheetDocumentLeft.Area(1, ColumnNumber, LeftTableHeight, ColumnNumber);
			Area.BackColor = DeletedAreaColorBackground;
			
			NewDifferenceRow = CellDifferencesLeft.Add();
			NewDifferenceRow.LineNumber = 0;
			NewDifferenceRow.ColumnNumber = ColumnNumber;
			
		EndIf;
		
	EndDo;
	
	// Lines that were added to the right spreadsheet document.
	For LineNumber = 1 To RowsMapRight.Count()-1 Do
		
		If RowsMapRight[LineNumber].Value = Undefined Then
			
			Area = SpreadsheetDocumentRight.Area(LineNumber, 1, LineNumber, RightTableWidth);
			Area.BackColor = AddedAreaColorBackground;
			
			NewDifferenceRow = CellDifferencesRight.Add();
			NewDifferenceRow.LineNumber = LineNumber;
			NewDifferenceRow.ColumnNumber = 0;
			
		EndIf;
		
	EndDo;
	
	// Columns that were added to the right spreadsheet document.
	For ColumnNumber = 1 To ColumnsMapRight.Count()-1 Do
		
		If ColumnsMapRight[ColumnNumber].Value = Undefined Then
			
			Area = SpreadsheetDocumentRight.Area(1, ColumnNumber, RightTableHeight, ColumnNumber);
			Area.BackColor = AddedAreaColorBackground;
			
			NewDifferenceRow = CellDifferencesRight.Add();
			NewDifferenceRow.LineNumber = 0;
			NewDifferenceRow.ColumnNumber = ColumnNumber;
			
		EndIf;
		
	EndDo;
	
	// Modified cells.
	For LineNumber1 = 1 To RowsMapLeft.Count()-1 Do
		
		LineNumber2 = RowsMapLeft[LineNumber1].Value;
		If LineNumber2 = Undefined Then
			Continue;
		EndIf;
		
		For ColumnNumber1 = 1 To ColumnsMapLeft.Count()-1 Do
			
			ColumnNumber2 = ColumnsMapLeft[ColumnNumber1].Value;
			If ColumnNumber2 = Undefined Then
				Continue;
			EndIf;
			
			Area1 = SpreadsheetDocumentLeft.Area(LineNumber1, ColumnNumber1, LineNumber1, ColumnNumber1);
			Area2 = SpreadsheetDocumentRight.Area(LineNumber2, ColumnNumber2, LineNumber2, ColumnNumber2);
			
			If Not CompareAreas(Area1, Area2) Then
				
				Area1 = SpreadsheetDocumentLeft.Area(LineNumber1, ColumnNumber1);
				Area2 = SpreadsheetDocumentRight.Area(LineNumber2, ColumnNumber2);
				
				Area1.TextColor = ChangedAreaColorText;
				Area2.TextColor = ChangedAreaColorText;
				
				Area1.BackColor = ChangedAreaColorBackground;
				Area2.BackColor = ChangedAreaColorBackground;
				
				
				NewDifferenceRow = CellDifferencesLeft.Add();
				NewDifferenceRow.LineNumber = LineNumber1;
				NewDifferenceRow.ColumnNumber = ColumnNumber1;
				
				NewDifferenceRow = CellDifferencesRight.Add();
				NewDifferenceRow.LineNumber = LineNumber2;
				NewDifferenceRow.ColumnNumber = ColumnNumber2;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	CellDifferencesLeft.Sort("LineNumber, ColumnNumber");
	CellDifferencesRight.Sort("LineNumber, ColumnNumber");
	
#EndRegion
	
EndProcedure

&AtServer
Function CompareAreas(Area1, Area2)
	
	If Area1.Text <> Area2.Text Then
		Return False;
	EndIf;
	
	If Area1.Comment.Text <> Area2.Comment.Text Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Function ReadSpreadsheetDocument(SourceSpreadsheetDocument)
	
	ColumnCount = SourceSpreadsheetDocument.TableWidth;
	
	If ColumnCount = 0 Then
		Return New ValueTable;
	EndIf;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	For ColumnNumber = 1 To ColumnCount Do
		SpreadsheetDocument.Area(1, ColumnNumber, 1, ColumnNumber).Text = "Number_" + Format(ColumnNumber,"NG=0");
	EndDo;
	
	SpreadsheetDocument.Put(SourceSpreadsheetDocument);
	
	Builder = New QueryBuilder;
	
	Builder.DataSource = New DataSourceDescription(SpreadsheetDocument.Area());
	Builder.Execute();
	ValueTableResult = Builder.Result.Unload();
	
	Return ValueTableResult;
	
EndFunction

&AtClient
Procedure ProcessAreaActivation(SourceSpreadDoc, DestinationSpreadDoc, MatchesSource, MatchesDestination)
	
	DisableOnActivateHandler = True;
	
	CurArea = SourceSpreadDoc.Item.CurrentArea;
	
	If CurArea.AreaType = SpreadsheetDocumentCellAreaType.Table Then
		
		SelectedArea = DestinationSpreadDoc.Area();
		
	Else
	
		If CurArea.Bottom < MatchesSource.Rows.Count() Then
			LineNumber = MatchesSource.Rows[CurArea.Bottom].Value;
		Else
			LineNumber = CurArea.Bottom 
							- MatchesSource.Rows.Count()
								+ MatchesDestination.Rows.Count();
		EndIf;
		
		If CurArea.Left < MatchesSource.Columns2.Count() Then
			ColumnNumber = MatchesSource.Columns2[CurArea.Left].Value;
		Else
			ColumnNumber = CurArea.Left
							- MatchesSource.Columns2.Count()
								+ MatchesDestination.Columns2.Count();
		EndIf;
		
		
		SelectedArea = Undefined;
		
		If CurArea.AreaType = SpreadsheetDocumentCellAreaType.Rectangle Then
					
			If LineNumber <> Undefined And ColumnNumber <> Undefined Then
				SelectedArea = DestinationSpreadDoc.Object.Area(LineNumber, ColumnNumber);
			EndIf;
					
		ElsIf CurArea.AreaType = SpreadsheetDocumentCellAreaType.Rows Then
			
			If LineNumber <> Undefined Then
				SelectedArea = DestinationSpreadDoc.Object.Area(LineNumber, 0, LineNumber, 0);
			EndIf;
			
		ElsIf CurArea.AreaType = SpreadsheetDocumentCellAreaType.Columns Then
			
			If ColumnNumber <> Undefined Then
				SelectedArea = DestinationSpreadDoc.Object.Area(0, ColumnNumber, 0, ColumnNumber);
			EndIf;
			
		Else		
			
			Return;
			
		EndIf;
		
	EndIf;
	
	DestinationSpreadDoc.Item.CurrentArea = SelectedArea;
	
	DisableOnActivateHandler = False;
	
EndProcedure

&AtClient
Procedure PreviousChange(FormItem, FormAttribute, DifferenceTable)
	
	Var IndexOf;
	
	CurCell = FormItem.CurrentArea;
	LineNumber = CurCell.Top;
	ColumnNumber = CurCell.Left;
	For Each CurRow In DifferenceTable Do
		If CurRow.LineNumber < LineNumber 
			Or CurRow.LineNumber = LineNumber And CurRow.ColumnNumber < ColumnNumber Then
			IndexOf = DifferenceTable.IndexOf(CurRow);
		ElsIf CurRow.LineNumber >= LineNumber And CurRow.ColumnNumber > ColumnNumber Then
			Break;
		EndIf;
	EndDo;
	
	If IndexOf <> Undefined Then
		DifferenceRow = DifferenceTable[IndexOf];
		LineNumber = DifferenceRow.LineNumber;
		ColumnNumber = DifferenceRow.ColumnNumber;
		FormItem.CurrentArea = FormAttribute.Area(LineNumber, ColumnNumber, LineNumber, ColumnNumber);
	EndIf;
	
	
EndProcedure

&AtClient
Procedure NextChange(FormItem, FormAttribute, DifferenceTable)
	
	Var IndexOf;
	
	CurCell = FormItem.CurrentArea;
	LineNumber = CurCell.Top;
	ColumnNumber = CurCell.Left;
	For Each CurRow In DifferenceTable Do
		If CurRow.LineNumber = LineNumber And CurRow.ColumnNumber > ColumnNumber 
			Or CurRow.LineNumber > LineNumber Then
			IndexOf = DifferenceTable.IndexOf(CurRow);
			Break;
		EndIf;
	EndDo;
	
	If IndexOf <> Undefined Then
		DifferenceRow = DifferenceTable[IndexOf];
		LineNumber = DifferenceRow.LineNumber;
		ColumnNumber = DifferenceRow.ColumnNumber;
		FormItem.CurrentArea = FormAttribute.Area(LineNumber, ColumnNumber, LineNumber, ColumnNumber);
	EndIf;

EndProcedure

&AtServer
Function PrepareSpreadsheetDocument(SpreadsheetDocument)
	
	If TypeOf(SpreadsheetDocument) = Type("SpreadsheetDocument") Then
		Return SpreadsheetDocument;
	EndIf;
	
	BinaryData = GetFromTempStorage(SpreadsheetDocument); // BinaryData - 
	TempFileName = GetTempFileName("mxl");
	BinaryData.Write(TempFileName);
	
	Result = New SpreadsheetDocument;
	Result.Read(TempFileName);
	
	DeleteFiles(TempFileName);
	
	Return Result;

EndFunction

#EndRegion